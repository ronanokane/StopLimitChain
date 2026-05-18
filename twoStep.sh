#!/bin/bash

operation=$1
firstStepSymbol=$2
secondStepSymbol=$3
percentage=$4

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
action="$SCRIPT_DIR/sellAsset.sh"

if [ "$operation" = "BUY" ]; then
    action="$SCRIPT_DIR/buyAsset.sh"
elif [ "$operation" = "SELL" ]; then
    action="$SCRIPT_DIR/sellAsset.sh"
fi

if [ "$#" -ne 4 ] || [ -z "$action" ] || [[ "$firstStepSymbol" != *"/"* ]] || [[ "$secondStepSymbol" != *"/"* ]]; then
    echo "Usage: ./${0##*/} <OPERATION> <STEP1_SYMBOL> <STEP2_SYMBOL> <PERCENTAGE_TO_BUY_OR_SELL>" >&2
    echo >&2
    echo "Examples:" >&2
    echo "  ./${0##*/} BUY ETH/USDC ETH/ZEC 100" >&2
    echo "  ./${0##*/} SELL ETH/USDC ETH/ZEC 100" >&2#!/bin/bash
    echo >&2
    exit 1
fi

amountField=$([[ "$action" == "$SCRIPT_DIR/buyAsset.sh" ]] && echo ".executedQty" || echo ".cummulativeQuoteQty")
json=$("$action" "$firstStepSymbol" "$percentage" 2>/dev/null)

if [ $? -eq 0 ] && [ -n "$json" ]; then
    local amount=$(echo "$json" | jq -r "$amountField")

    if [ $? -eq 0 ] && "$action" "$secondStepSymbol" -a "$amount"; then
        exit 0
    fi
fi

echo "Error executing one or more of orders..." 2>/dev/null
exit 1
