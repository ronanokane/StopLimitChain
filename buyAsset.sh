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

# Fetch the current market price
get_market_price() {
  curl -s -H "X-MBX-APIKEY: $API_KEY" "$BASE_URL/api/v3/ticker/price?symbol=$SYMBOL" | jq -r '.price'
}

# Fetch LOT_SIZE info
get_lot_size() {
  curl -s -H "X-MBX-APIKEY: $API_KEY" "$BASE_URL/api/v3/exchangeInfo" | \
    jq -r --arg symbol "$SYMBOL" '.symbols[] | select(.symbol==$symbol) | .filters[] | select(.filterType=="LOT_SIZE")'
}

# Place a buy order
place_buy_order() {
  local quantity=$1
  local timestamp=$(date +%s%3N)
  local query_string="symbol=$SYMBOL&side=BUY&type=MARKET&quantity=$quantity&timestamp=$timestamp"
  local signature=$(calculate_signature "$query_string")
  curl -s -H "X-MBX-APIKEY: $API_KEY" -X POST "$BASE_URL/api/v3/order" -d "$query_string&signature=$signature"
}

SYMBOL=""
PERCENTAGE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -a)
      AMOUNT_TO_SPEND="$2"
      shift 2
      ;;
    *)
      if [[ -z "$SYMBOL" ]]; then
          if [[ "$1" != *"/"* ]]; then
              echo "Missing bracket in symbol" >&2
              exit 1
          fi
          QUOTE_ASSET="$(echo "$1" | cut -d '/' -f2)"          
          SYMBOL="$(echo "$1" | cut -d '/' -f1)""$QUOTE_ASSET"
          SYMBOL="${SYMBOL^^}"
      else
          PERCENTAGE="$1"
      fi
      shift
      ;;
  esac
done

if [[ -n "$AMOUNT_TO_SPEND" && -n "$PERCENTAGE" || -z "$SYMBOL" ]]; then
    echo "Usage: buyAsset.sh <symbol> <percentage>" >&2
    echo "Usage: buyAsset.sh <symbol> -a <actual_amount>" >&2    
    exit 1
fi

# if [[ -n "$AMOUNT_TO_SPEND" ]]; then
#     echo "Using actual amount: $AMOUNT_TO_SPEND $SYMBOL" >&2
# else
#     echo "Using percentage: $PERCENTAGE% of balance for $SYMBOL" >&2
# fi

#exit 1

# Get USDT balance
USDT_BALANCE=$(get_balance "$QUOTE_ASSET")
if [ -z "$USDT_BALANCE" ]; then
  echo "Error: Unable to fetch USDT balance." >&2
  exit 1
fi

#echo "Current USDT Balance: $USDT_BALANCE" >&2

if [[ -n "$PERCENTAGE" ]]; then
    AMOUNT_TO_SPEND=$(echo "$USDT_BALANCE $PERCENTAGE" | awk '{printf "%.8f", $1 * $2 / 100}')
fi

if (( $(echo "$AMOUNT_TO_SPEND <= 0" | bc -l) )); then
  echo "Error: Calculated USDC amount to spend is invalid." >&2
  exit 1
fi

echo "Amount to Spend: $AMOUNT_TO_SPEND" >&2

# Get market price
MARKET_PRICE=$(get_market_price)
if [ -z "$MARKET_PRICE" ]; then
  echo "Error: Unable to fetch market price for $SYMBOL." >&2
  exit 1
fi
#echo "Market Price for $SYMBOL: $MARKET_PRICE" >&2

# Get LOT_SIZE info
LOT_SIZE_INFO=$(get_lot_size)
if [ -z "$LOT_SIZE_INFO" ]; then
  echo "Error: Unable to fetch LOT_SIZE info for $SYMBOL." >&2
  exit 1
fi

minQty=$(echo "$LOT_SIZE_INFO" | jq -r '.minQty' | awk '{printf "%.8f", $1}')
stepSize=$(echo "$LOT_SIZE_INFO" | jq -r '.stepSize' | awk '{printf "%.8f", $1}')

# Calculate quantity
quantity=$(echo "$AMOUNT_TO_SPEND $MARKET_PRICE" | \
  awk -v stepSize="$stepSize" '{ 
    qty = $1 / $2; 
    adjQty = (int(qty / stepSize) * stepSize); 
    printf "%.8f", adjQty
  }')

# Validate quantity
if (( $(echo "$quantity < $minQty" | bc -l) )); then
  echo "Error: Calculated quantity ($quantity) is less than the minimum required ($minQty)." >&2
  exit 1
fi

#echo "Calculated Quantity: $quantity" >&2

# Place the buy order
RESPONSE=$(place_buy_order "$quantity")

echo "$RESPONSE"

# ensure a nice code returns at the end indicating buy success or not
echo $RESPONSE | jq '.status' | { read status; [ $status == "\"FILLED\"" ]; }
