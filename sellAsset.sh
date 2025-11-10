#!/bin/bash

# Binance API credentials
API_KEY="$(sed -n '2p' binanceApikey)"
API_SECRET="$(sed -n '4p' binanceApikey)"
BASE_URL="https://api.binance.com"

# Function to calculate HMAC SHA256 signature
calculate_signature() {
  local query_string=$1
  echo -n "$query_string" | openssl dgst -sha256 -hmac "$API_SECRET" | awk '{print $2}'
}

# Fetch the current balance for a specific symbol
get_balance() {
  local asset=$1
  local timestamp=$(date +%s%3N)
  local query_string="timestamp=$timestamp"
  local signature=$(calculate_signature "$query_string")
  curl -s -H "X-MBX-APIKEY: $API_KEY" "$BASE_URL/api/v3/account?${query_string}&signature=$signature" | \
    jq -r --arg asset "$asset" '.balances[] | select(.asset==$asset) | .free'
}

# Fetch LOT_SIZE info and NOTIONAL info
get_exchange_info() {
  curl -s -H "X-MBX-APIKEY: $API_KEY" "$BASE_URL/api/v3/exchangeInfo" | \
    jq -r --arg symbol "$SYMBOL" '.symbols[] | select(.symbol==$symbol) | .filters'
}

# Place a sell order
place_sell_order() {
  local quantity=$1
  local timestamp=$(date +%s%3N)
  local query_string="symbol=$SYMBOL&side=SELL&type=MARKET&quantity=$quantity&timestamp=$timestamp"
  local signature=$(calculate_signature "$query_string")
  curl -s -H "X-MBX-APIKEY: $API_KEY" -X POST "$BASE_URL/api/v3/order" -d "$query_string&signature=$signature"
}

# Main Script
if [ $# -lt 2  ] || [[ "$1" != *"/"* ]]; then
  echo "Usage: $0 BTC/USDC PERCENTAGE_OF_BALANCE" >&2
  exit 1
fi

# Extract the base asset from the symbol
BASE_ASSET="$(echo "$1" | cut -d '/' -f1)"

SYMBOL="$BASE_ASSET""$(echo "$1" | cut -d '/' -f2)"
PERCENTAGE=$2

# Extract the base asset from the symbol
# BASE_ASSET=$(echo "$SYMBOL" | sed 's/USDT//')

# Get the asset balance
ASSET_BALANCE=$(get_balance "$BASE_ASSET")
if [ -z "$ASSET_BALANCE" ]; then
  echo "Error: Unable to fetch balance for $BASE_ASSET." >&2
  exit 1
fi

echo "Current $BASE_ASSET Balance: $ASSET_BALANCE" >&2

# Calculate the quantity to sell
AMOUNT_TO_SELL=$(echo "$ASSET_BALANCE $PERCENTAGE" | awk '{printf "%.8f", $1 * $2 / 100}')
if (( $(echo "$AMOUNT_TO_SELL <= 0" | bc -l) )); then
  echo "Error: Calculated amount to sell is invalid." >&2
  exit 1
fi

# Get exchange info to fetch LOT_SIZE and MIN_NOTIONAL
EXCHANGE_INFO=$(get_exchange_info)
if [ -z "$EXCHANGE_INFO" ]; then
  echo "Error: Unable to fetch exchange info for $SYMBOL." >&2
  exit 1
fi

# Extract the minimum notional value (MIN_NOTIONAL) and LOT_SIZE
MIN_NOTIONAL=$(echo "$EXCHANGE_INFO" | jq -r '.[] | select(.filterType=="NOTIONAL") | .minNotional' | awk '{printf "%.8f", $1}')

LOT_SIZE=$(echo "$EXCHANGE_INFO" | jq -r '.[] | select(.filterType=="LOT_SIZE") | .minQty' | awk '{printf "%.8f", $1}')

# Check if the calculated value exceeds MIN_NOTIONAL
# Get the current market price
MARKET_PRICE=$(curl -s "$BASE_URL/api/v3/ticker/price?symbol=$SYMBOL" | jq -r '.price')
TOTAL_VALUE=$(echo "$AMOUNT_TO_SELL $MARKET_PRICE" | awk '{printf "%.8f", $1 * $2}')

if (( $(echo "$TOTAL_VALUE < $MIN_NOTIONAL" | bc -l) )); then
  echo "Error: Total value ($TOTAL_VALUE) is less than the minimum notional value ($MIN_NOTIONAL)." >&2
  exit 1
fi

# Adjust quantity to meet LOT_SIZE rules
quantity=$(echo "$AMOUNT_TO_SELL" | \
  awk -v stepSize="$LOT_SIZE" '{ 
    adjQty = (int($1 / stepSize) * stepSize); 
    printf "%.8f", adjQty
  }')

# Validate quantity
if (( $(echo "$quantity < $LOT_SIZE" | bc -l) )); then
  echo "Error: Calculated quantity ($quantity) is less than the minimum required ($LOT_SIZE)." >&2
  exit 1
fi

echo "Calculated Quantity to Sell: $quantity" >&2

# Place the sell order
RESPONSE=$(place_sell_order "$quantity")
echo "$RESPONSE"

status=$(echo "$RESPONSE" | jq -r '.status')

if [ "$status" == "FILLED" ]; then
    exit 0
else
    exit 1
fi
