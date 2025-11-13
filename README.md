HOW TO USE
==========

Purpose: There is symbols that lack a direct pairing with EUR or USDC and this complicates running say a LIMIT buy as there is no listed
symbol. For example ZEC could only be traded with ETH and BTC for a while. The only way to get around this was to buy ETH first. The ideal
way to do it is only do the USDC->ETH ETH->ZEC at the triggure point. This isn' t possible with the default orders on binance. The script solves this.

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
