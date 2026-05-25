#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

API_KEY="$(sed -n '2p' $SCRIPT_DIR/binanceApikey)"
API_SECRET="$(sed -n '4p' $SCRIPT_DIR/binanceApikey)"
SYMBOL=$1  
ORDER_ID=$2

if [ $# -ne 2 ]; then
  echo "Usage: $0 BTC/USDC OrderId" >&2
  exit 1
fi

# check for / in pair for consistency, so it is accepted
[[ "$1" == *"/"* ]] && SYMBOL="$(echo "$1" | cut -d '/' -f1)""$(echo "$1" | cut -d '/' -f2)" 

BASE_URL="https://api.binance.com"
CANCEL_ORDER_ENDPOINT="/api/v3/order"

TIMESTAMP=$(date +%s%3N)
QUERY_STRING="symbol=$SYMBOL&orderId=$ORDER_ID&timestamp=$TIMESTAMP"
SIGNATURE=$(echo -n "$QUERY_STRING" | openssl dgst -sha256 -hmac "$API_SECRET" | awk '{print $2}')

RESPONSE=$(curl -s -X DELETE "${BASE_URL}${CANCEL_ORDER_ENDPOINT}" \
    -H "X-MBX-APIKEY: $API_KEY" \
    -d "$QUERY_STRING&signature=$SIGNATURE")

if [[ "$RESPONSE" == *"code"* && "$RESPONSE" == *"msg"* ]]; then
    echo "$RESPONSE"    
    exit 1
fi

echo "$RESPONSE"