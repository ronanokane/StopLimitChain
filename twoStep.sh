#!/bin/bash

# Two-step buy/sell script for Binance

operation=$1
firstStepSymbol=$2
secondStepSymbol=$3
percentage=$4

PERCENT_MODE=false

cryptoPrice() {
    local symbol=$1

    if [[ -z "$symbol" ]]; then
        echo "Please provide a cryptocurrency symbol (e.g., BTCUSDT)"
        return 1
    fi
    local response=$(curl -s "https://api.binance.com/api/v3/ticker/price?symbol=${symbol}")
    local price=$(echo "$response" | jq '.price | tonumber')

    if [[ -z "$price" ]]; then
        echo "Invalid symbol or unable to fetch price. Please check the symbol and try again."
        return 1
    fi
    echo "$price"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
action="$SCRIPT_DIR/sellAsset.sh"

if [ "$operation" = "BUY" ]; then
    action="$SCRIPT_DIR/buyAsset.sh"
elif [ "$operation" = "SELL" ]; then
    action="$SCRIPT_DIR/sellAsset.sh"
fi

if [ "$#" -ne 5 ] || ! [[ $5 =~ ^-(a|p)$ ]] || [ -z "$action" ] || [[ "$firstStepSymbol" != *"/"* ]] || [[ "$secondStepSymbol" != *"/"* ]]; then
    echo "Usage: ./${0##*/} <OPERATION> <STEP1_SYMBOL> <STEP2_SYMBOL> <percentage> -p" >&2
    echo "       ./${0##*/} <OPERATION> <STEP1_SYMBOL> <STEP2_SYMBOL> <actual amount> -a" >&2
    echo >&2
    echo "Examples:" >&2
    echo "  ./${0##*/} BUY ETH/USDC ZEC/ETH 0.5 -a" >&2
    echo "  ./${0##*/} SELL ZEC/ETH ETH/USDC 100 -p" >&2
    echo >&2
    exit 1
fi

if [ "$5" = "-p" ]; then
    PERCENT_MODE=true
fi

amountField=$([[ "$action" == "$SCRIPT_DIR/buyAsset.sh" ]] && echo ".executedQty" || echo ".cummulativeQuoteQty")
amountRequired=$4

IFS='/' read -r SYMBOL1_BASE SYMBOL1_QUOTE <<< "$firstStepSymbol"
IFS='/' read -r SYMBOL2_BASE SYMBOL2_QUOTE <<< "$secondStepSymbol"

# ZEC/USDC buy (NONE PERCENT MODE)
# ETH/USDC -> ZEC/ETH
# ZEC/ETH * amount = sum ETH needed

if [ "$operation" = "BUY" ]; then

    # the order of the trade pairs is important and must be validated
    if [ "$SYMBOL1_BASE" != "$SYMBOL2_QUOTE" ]; then
        echo "XX/Y X/XX BUY requires XX to match in both STEP1 and STEP2 symbols" >&2
        exit 1
    fi
   # amountRequired="0"$(echo "$(cryptoPrice $SYMBOL2_BASE$SYMBOL1_BASE) * $4" | bc)
   amountRequired=$(echo "$(cryptoPrice $SYMBOL2_BASE$SYMBOL1_QUOTE) * $4" | bc)
   amountRequired="${amountRequired/#./0.}"
   # echo "Amount required: $amountRequired"
   # exit 1
    
elif [ "$SYMBOL1_QUOTE" != "$SYMBOL2_BASE" ]; then
    echo "X/XX XX/Y SELL requires XX to match in both STEP1 and STEP2 symbols" >&2
    exit 1
fi

if $PERCENT_MODE; then
    json=$("$action" "$firstStepSymbol" "$percentage" 2>/dev/null)
else
    json=$("$action" "$firstStepSymbol" -a "$amountRequired" 2>/dev/null)
fi

echo "$action $firstStepSymbol $amountRequired"

if [ $? -eq 0 ] && [ -n "$json" ]; then
    amount=$(echo "$json" | jq -r "$amountField")

    if [ $? -eq 0 ] && "$action" "$secondStepSymbol" -a "$amount"; then
        exit 0
    fi
fi

echo "Error completing one or more of orders..." >&2
exit 1
