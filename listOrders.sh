#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

API_KEY="$(sed -n '2p' $SCRIPT_DIR/binanceApikey)"
API_SECRET="$(sed -n '4p' $SCRIPT_DIR/binanceApikey)"
BASE_URL="https://api.binance.com/api/v3"

create_signature() {
    local query_string=$1
    echo -n "$query_string" | openssl dgst -sha256 -hmac "$API_SECRET" | sed 's/^.* //'
}

list_open_orders() {
    local symbol=$1
    local params="symbol=$symbol&timestamp=$(($(date +%s) * 1000))"
    local signature=$(create_signature "$params")

    if [ -z "$symbol" ]; then
        params="timestamp=$(($(date +%s) * 1000))"
        signature=$(create_signature "$params")
    fi

    local url="$BASE_URL/openOrders?$params&signature=$signature"      

    orders=$(curl -s -X GET "$url" -H "X-MBX-APIKEY: $API_KEY")

    if [[ "$(echo "$orders" | jq 'type')" == '"array"' ]]; then
        echo $(echo "$orders" | jq -r '.')
    fi
}

if [[ "$1" == "--help" ]]; then
    echo "Usage: ./listOrders.sh SYMBOL"
    echo "Usage: ./listOrders.sh SYMBOL TYPE SIDE"
    echo "Usage: ./listOrders.sh"    
    echo
    echo "./listOrders.sh"    
    echo "./listOrders.sh BTC/USDC"
    echo "./listOrders.sh BTC/USDC LIMIT SELL"             
    exit 1
fi

# strip / in symbol
[[ "$1" == *"/"* ]] && symbol="$(echo "$1" | cut -d '/' -f1)""$(echo "$1" | cut -d '/' -f2)"  || symbol=$1

if orders=$(list_open_orders "$symbol"); then

    if [ "$#" = "3" ]; then
        type=$2
        side=$3
        order_ids=$(echo "$orders" | jq -r "[.[] | select( .type == \"$type\" and .side == \"$side\")]")  
        echo "$order_ids"
    else
        echo "$orders"
    fi
fi