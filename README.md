HOW TO USE
==========

Purpose: Binance doesn’t support limit or stop orders for unlisted fiat/stablecoin pairs. This project combines a ticker (3400+ symbols) and indirect two-step orders to fill that gap. Originally wrote to get around the removal of ZEC/USDC pair listing. You could only buy it with ETH and BTC.

Dependencies: websocat, jq

Create a file named "binanceApikey" in the same folder as the scripts, with the following structure:

API Key<br>
<API_KEY><br>
Secret Key<br>
<SECRET_KEY><br>

Replace lines two and four with your API key and secret key.

Run "sudo ./updatehwclock.sh" to ensure your clock is properly in sync.

Followed by unlistedTradeOrder.sh 

Usage: ./unlistedTradeOrder.sh \<OPERATION\> \<TICKER_SYMBOL\> <TRIGGER_PRICE> <STEP1_SYMBOL> <STEP2_SYMBOL> <PERCENTAGE_WALLET_USDC>

There is four operations

  LIMITBUY<br>
  LIMITSELL<br>
  STOPBUY<br>
  STOPSELL<br>

An example usage would be:

./unlistedTradeOrder.sh LIMITBUY ZEC/USDT 400 ETH/USDC ZEC/ETH 50

This will run a LIMIT buy for ZEC with trigger at 400 dollar. When trigger is hit 50 percent of your wallet USDC balance will purchase ETH and subsequently ZEC.

Tip: Use USDT as default in ticker symbol. It isn' t tradeable here in (Europe) but it still functions as a widespread ticker and is still valid even if symbol is unlisted for trading by region. Just adjust step1 and step1 accordingly

curl -s "https://api.binance.com/api/v3/exchangeInfo" | jq -r '.symbols[].symbol | select(test("USDT$"))'

Should give you a list of useable USDT ticker symbols.

Step2 can optionally be set to "-" to skip step2, making it behave like a regular order.
