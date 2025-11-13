#!/bin/bash

operation=$1
symbol=$2
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
        action="./buyAsset.sh"
    else
        action="./sellAsset.sh"
    fi

    if [ "$condition" -eq 1 ]; then
        echo "Operation: $operation"
        echo "Price: $price"
        echo "Boundary: $priceBoundary"
        echo "Condition met → Executing $action with $percentage%"

        # Execute appropriate scripts
       # $action "$firstStepSymbol" "$percentage" && $action "$secondStepSymbol" "$percentage"
    fi
}

if [ "$#" -ne 6 ] && [ $OPERATION == ] ; then
    echo "Usage: ./${0##*/} <OPERATION> <SYMBOL> <BOUNDARY_PRICE> <STEP1_SYMBOL> <STEP2_SYMBOL> <PERCENTAGE_TO_BUY_OR_SELL>"
    echo
    echo "Examples:"
    echo "  ./${0##*/} LIMITBUY ZECUSDC 200 ETHUSDC ETHZEC 100"
    echo "  ./${0##*/} LIMITSELL BTCUSDC 65000 ETHUSDC ETHBTC 50"
    echo "  ./${0##*/} STOPBUY AVAXUSDC 40 ETHUSDC ETHAVAX 75"
    echo "  ./${0##*/} STOPSELL SOLUSDC 180 ETHUSDC ETHSOL 25"
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

./updatehwclock.sh
. ./tickerHook.sh "$symbol" callBack