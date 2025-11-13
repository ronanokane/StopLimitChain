HOW TO USE
==========

Purpose: Binance doesn’t support limit or stop orders for unlisted fiat/stablecoin pairs. This project automates indirect two-step orders to fill that gap.

Dependencies: websocat

Create a file named "binanceApikey" in the same folder as the scripts, with the following structure:

API Key<br>
<API_KEY><br>
Secret Key<br>
<SECRET_KEY><br>

Replace lines two and four with your API key and secret key.

Usage: ./orderTriggerTwoStep.sh \<OPERATION\> \<SYMBOL\> <BOUNDARY_PRICE> <STEP1_SYMBOL> <STEP2_SYMBOL> <PERCENTAGE_TO_BUY_OR_SELL>

There is four operations

  LIMITBUY<br>
  LIMITSELL<br>
  STOPBUY<br>
  STOPSELL<br>

An example usage would be:

./orderTriggerTwoStep.sh LIMITBUY ZECUSDC 400 ETHUSDC ZECETH 50

This will run a LIMIT buy for ZEC with trigger at 400 dollar. When trigger is hit 50 percent of your wallet USDC balance will purchase ETH and subsequently ZEC.
