#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: ./${0##*/} <cryptoSymbol> <function>"
    exit 1
fi

CRYPTO_SYMBOL="${1^^}"
CALLBACK="$2"

WEBSOCKET_URL="wss://stream.binance.com:9443/ws/${CRYPTO_SYMBOL}@trade"

last_price="$(curl -s https://api.binance.com/api/v3/ticker/price?symbol=$CRYPTO_SYMBOL | jq '.price | tonumber')"

"$CALLBACK" "$last_price" "$CRYPTO_SYMBOL" && exit 0

handle_tick() {
    local data="$1"
    local price=$(echo "$data" | jq -r '.p // empty')
    local symbol=$(echo "$data" | jq -r '.s // empty')

    if [ "$price" != "$last_price" ]; then
        last_price="$price"
        "$CALLBACK" "$price" "$symbol" && exit 0
    fi
}

while read -r line; do
    handle_tick "$line"
done < <(websocat -n "$WEBSOCKET_URL" 2>/dev/null)