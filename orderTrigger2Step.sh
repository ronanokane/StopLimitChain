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
    local action=""

    # Determine comparison operator
    case "$operation" in
        LIMITBUY|STOPSELL)
            condition=$(echo "$price <= $priceBoundary" | bc)
            ;;
        LIMITSELL|STOPBUY)
            condition=$(echo "$price >= $priceBoundary" | bc)
            ;;
    esac

    # Determine buy/sell action
    if [[ "$operation" == *BUY ]]; then
        # Disallow 100percent quote buy. Can cause buy failure due to volatility.
        if (( $(echo "$percentage > 99" | bc -l) )); then
            percentage=99
        fi
        action="./buyAsset.sh"
    else
        action="./sellAsset.sh"
    fi

    if [ "$condition" -eq 1 ]; then
        echo "Operation: $operation"
        echo "Price: $price"
        echo "Stop/Limit price: $priceBoundary"
        echo "Condition met → Executing $action at $percentage% of balance"

        amountField=$([[ "$action" == "./buyAsset.sh" ]] && echo ".executedQty" || echo ".cummulativeQuoteQty")

        if amount=$("$action" "$firstStepSymbol" "$percentage" | tee /dev/tty | jq -r "$amountField"); then

            if "$action" "$secondStepSymbol" -a "$amount"; then
                echo "2 steps executed successfully..."
                return $?
            fi
        fi

        echo "Error executing one or more of orders..."
        exit 1
    fi

    return 1
}

if [ "$#" -ne 6 ] || [[ "$ticker_symbol" != *"/"* ]] || [[ "$firstStepSymbol" != *"/"* ]] || [[ "$secondStepSymbol" != *"/"* ]]; then
    echo "Usage: ./${0##*/} <OPERATION> <SYMBOL> <BOUNDARY_PRICE> <STEP1_SYMBOL> <STEP2_SYMBOL> <PERCENTAGE_TO_BUY_OR_SELL>"
    echo
    echo "Examples:"
    echo "  ./${0##*/} LIMITBUY ZEC/USDC 200 ETH/USDC ETH/ZEC 100"
    echo "  ./${0##*/} LIMITSELL BTC/USDC 65000 ETH/USDC ETH/BTC 50"
    echo "  ./${0##*/} STOPBUY AVAX/USDC 40 ETH/USDC ETH/AVAX 75"
    echo "  ./${0##*/} STOPSELL SOL/USDC 180 ETH/USDC ETH/SOL 25"
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

tradeAblePair(){
    symbol=$(echo $1 | tr -d /)
    response=$(curl -s "https://api.binance.com/api/v3/exchangeInfo")
    binance_symbols=$(echo "$response" | jq -r '.symbols[].symbol')
    echo "$binance_symbols" | grep -q "^${symbol}$" &> /dev/null
}

! tradeAblePair "$firstStepSymbol" && echo "$firstStepSymbol is not tradeable... select another" && exit 1
! tradeAblePair "$secondStepSymbol" && echo "$secondStepSymbol is not tradeable... select another" && exit 1

ticker_symbol="$(echo $ticker_symbol | tr -d /)"

# Sync clock first.
./updatehwclock.sh

. ./tickerHook.sh "$ticker_symbol" callBack