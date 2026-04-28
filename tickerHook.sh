#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: ./${0##*/} <cryptoSymbol> <function>"
    exit 1
fi

CRYPTO_SYMBOL=$(echo "$1" | tr '[:upper:]' '[:lower:]')
CALLBACK=$2

WEBSOCKET_URL="wss://stream.binance.com:9443/ws/${CRYPTO_SYMBOL}@trade"

last_price=""

# Tick handler function
handle_tick() {
    local data="$1"
    local price=$(echo "$data" | jq -r '.p // empty')
    local symbol=$(echo "$data" | jq -r '.s // empty')

    if [ "$price" != "$last_price" ]; then
        last_price="$price"
        "$CALLBACK" "$price" "$symbol" && exit 0
    fi
}

#echo "Connecting to $WEBSOCKET_URL..."
#websocat --exit-on-eof "$WEBSOCKET_URL" | while read -r line; do
websocat -n "$WEBSOCKET_URL" 2>/dev/null | while read -r line; do
    handle_tick "$line"
done