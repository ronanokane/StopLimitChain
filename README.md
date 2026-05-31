Purpose
=======

Binance doesn’t support limit or stop orders for unlisted fiat/stablecoin pairs. This project combines a ticker (3,400+ symbols) with two‑step routing to place orders for pairs not listed on the exchange.

Originally created to work around removal of the ZEC/USDC pair, which left purchases only possible via ETH or BTC. Routing is specified up front. A separate, configurable action script handles buy/sell execution.

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
Also, another neat trick over native limit and stops is you can mix different symbols eg you can sell 10% of your btc for aave when aave hits x dollars.

```
./StopLimitChain.sh LIMITBUY AAVE/USDC 80 - - 100 && ./buyAsset.sh AAVE/BTC 10
```

Or reoute the buy via ETH/USDC if AAVE/BTC pair doesn't exist as tradeable.

```
./StopLimitChain.sh LIMITBUY AAVE/USDC 80 - - 100 && ./twoStep.sh ETH/USDC AAVE/ETH 10
```


