#!/bin/bash

operation=$1
ticker_symbol=$2
priceBoundary=$3
firstStepSymbol=$4
secondStepSymbol=$5
percentage=$6

callBack() {
    local price=$1
    local condition=0
    local action="./sellAsset.sh"

    case "$operation" in
        LIMITBUY|STOPSELL)
            condition=$(echo "$price <= $priceBoundary" | bc)
            ;;
        LIMITSELL|STOPBUY)
            condition=$(echo "$price >= $priceBoundary" | bc)
            ;;
    esac

    [[ "$operation" == *BUY ]] && action="./buyAsset.sh"

    if [ "$condition" -eq 1 ]; then
        [ "$firstStepSymbol" = "-" ] && return 0
    
        local amountField=$([[ "$action" == "./buyAsset.sh" ]] && echo ".executedQty" || echo ".cummulativeQuoteQty")
        local json=$("$action" "$firstStepSymbol" "$percentage" 2>/dev/null)

        if [ $? -eq 0 ] && [ -n "$json" ]; then
            if [ "$secondStepSymbol" = "-" ]; then
                echo "order executed successfully..."
                return 0
            fi
            local amount=$(echo "$json" | jq -r "$amountField")

            if [ $? -eq 0 ] && "$action" "$secondStepSymbol" -a "$amount" >/dev/null; then
                echo "2 steps executed successfully..."
                return 0
            fi
        fi
        echo "Error executing one or more of orders..."
        exit 1
    fi
    return 1
}

if [ "$#" -ne 6 ] || [[ "$ticker_symbol" != *"/"* ]] || [[ "$firstStepSymbol" != *"/"* ]] || [[ "$secondStepSymbol" != *"/"* ]] && [ "$secondStepSymbol" != "-" ]; then
    echo "Usage: ./${0##*/} <OPERATION> <SYMBOL> <BOUNDARY_PRICE> <STEP1_SYMBOL> <STEP2_SYMBOL> <PERCENTAGE_TO_BUY_OR_SELL>"
    echo
    echo "Examples:"
    echo "  ./${0##*/} LIMITBUY ZEC/USDC 200 ETH/USDC ETH/ZEC 100"
    echo "  ./${0##*/} LIMITSELL BTC/USDC 65000 ETH/USDC ETH/BTC 50"
    echo "  ./${0##*/} STOPBUY AVAX/USDC 40 ETH/USDC ETH/AVAX 75"
    echo "  ./${0##*/} STOPSELL SOL/USDC 180 ETH/USDC ETH/SOL 25"
    echo "  ./${0##*/} STOPSELL SOL/USDC 180 ETH/USDC - 25"
    echo "  ./${0##*/} STOPSELL SOL/USDC 180 ETH/USDC - - 100"    
    echo 
    echo "  \"-\" in <STEP2_SYMBOL> skip step2"
    echo "  \"-\" in <STEP1_SYMBOL> skip step1 & step2"    
    echo
    echo "Supported operations:"
    echo "  LIMITBUY"
    echo "  LIMITSELL"
    echo "  STOPBUY"
    echo "  STOPSELL"
    exit 1
fi

# Validate operation keyword
case "$operation" in
    LIMITBUY|LIMITSELL|STOPBUY|STOPSELL)
        ;;
    *)
        echo "Operation \"$operation\" unrecognised"
        echo "Valid operations: LIMITBUY, LIMITSELL, STOPBUY, STOPSELL"
        exit 1
        ;;
esac

validSymbol(){
    local symbol=$(echo $1 | tr -d /)
    echo "$binance_symbols" | grep -q "^${symbol}$"
}

binance_symbols=$(curl -s "https://api.binance.com/api/v3/exchangeInfo" | jq -r '.symbols[].symbol')

! validSymbol "$ticker_symbol" && echo "$ticker_symbol is invalid... select another" && exit 1
[ "$secondStepSymbol" != "-" ] && ! validSymbol "$secondStepSymbol" && echo "$secondStepSymbol is invalid.. select another" && exit 1;
[ "$firstStepSymbol" != "-" ] && ! validSymbol "$firstStepSymbol" && echo "$fistStepSymbol is invalid.. select another" && exit 1;

ticker_symbol="$(echo $ticker_symbol | tr -d /)"

. ./tickerHook.sh "$ticker_symbol" callBack
