HOW TO USE
==========

Purpose: Binance doesn’t support limit or stop orders for unlisted fiat/stablecoin pairs. This project automates indirect two-step orders to fill that gap. Originally wrote to get around the removal of ZEC/USDC pair listing. You could only buy it with ETH and BTC.

Dependencies: websocat, jq

Create a file named "binanceApikey" in the same folder as the scripts, with the following structure:

API Key<br>
<API_KEY><br>
Secret Key<br>
<SECRET_KEY><br>

Replace lines two and four with your API key and secret key.

Run "./updatehwclock.sh" to ensure your clock is properly in sync.

Usage: ./orderTrigger2Step.sh \<OPERATION\> \<TICKER_SYMBOL\> <TRIGGER_PRICE> <STEP1_SYMBOL> <STEP2_SYMBOL> <PERCENTAGE_WALLET_USDC>

There is four operations

  LIMITBUY<br>
  LIMITSELL<br>
  STOPBUY<br>
  STOPSELL<br>

An example usage would be:

./orderTrigger2Step.sh LIMITBUY ZEC/USDT 400 ETH/USDC ZEC/ETH 50

This will run a LIMIT buy for ZEC with trigger at 400 dollar. When trigger is hit 50 percent of your wallet USDC balance will purchase ETH and subsequently ZEC.

Tip: Use USDT as default in ticker symbol. It isn' t tradeable here in (Europe) but it still functions as most widespread ticker and is still valid even if symbol is unlisted for trading by region. Just adjust step1 and step1 accordingly. 

Step2 can optionally be set to "-" to skip step2, making it behave like a regular order.
