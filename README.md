Purpose
=======

Binance doesn’t support limit or stop orders for unlisted fiat/stablecoin pairs. This project combines a ticker (3400+ symbols) and indirect two-step orders to fill that gap. 

Originally wrote to get around the removal of ZEC/USDC pair listing. You could only buy it with ETH and BTC. This script removes the need to have a tradeable pair first to place the order as the buy or sell action comes later and is a seperate script anyway.

Dependencies
------------
websocat, jq

How to use
----

Create a file named "binanceApikey" in the same folder as the scripts, with the following structure:
```
API Key
<API_KEY>
Secret Key
<SECRET_KEY>
```

Replace lines two and four with your API key and secret key.

Run the following (to ensure clock is synced).

```
sudo systemctl restart systemd-timesyncd
```
Execute StopLimitChain.sh

```
./StopLimitChain.sh <OPERATION> <TICKER_SYMBOL> <TRIGGER_PRICE> <STEP1_SYMBOL> <STEP2_SYMBOL> <PERCENTAGE_WALLET_USDC>
```
There is four operations

LIMITBUY<br>
LIMITSELL<br>
STOPBUY<br>
STOPSELL<br>

An example usage would be:

```
./StopLimitChain.sh LIMITBUY ZEC/USDT 400 ETH/USDC ZEC/ETH 50
```

This will run a LIMIT buy for ZEC with trigger at 400 dollar. When trigger is hit 50 percent of your wallet USDC balance will purchase ETH and subsequently ZEC.

Tip: Use USDT as default in ticker symbol. It isn' t tradeable here in (Europe) but it still functions as a widespread ticker and is still valid even if symbol is unlisted for trading by region. STEP1_SYMBOL and STEP2_SYMBOL must however be listed on the exchange.

```
curl -s "https://api.binance.com/api/v3/exchangeInfo" | jq -r '.symbols[].symbol | select(test("USDT$"))'
```
Should give you a list of useable USDT ticker symbols.

STEP2_SYMBOL can optionally be set to "-" to skip step2, making it behave like a regular order.<br>
STEP1_SYMBOL can also be set to "-" to skip both buy/sell actions providing an opportunity to override with your own external command/s scripts. This allows for interesting flexibility.

For example you can turn the STOP order into a STOP LIMIT order:

STOP LIMIT sell
```
./StopLimitChain.sh STOPSELL RENDER/USDC 1.695 - - 100 && ./StopLimitChain.sh LIMITSELL RENDER/USDC 1.685 RENDER/USDC - 100
```
STOP LIMIT buy
```
./StopLimitChain.sh STOPBUY RENDER/USDC 1.695 - - 100 && ./StopLimitChain.sh LIMITBUY RENDER/USDC 1.705 RENDER/USDC - 100
```
