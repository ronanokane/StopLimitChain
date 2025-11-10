#!/bin/bash

symbol=$1
stopPrice=$2
firstSymbolSell=$3
secondSymbolSell=$4

callBack(){
    local price=$1

    if [ $(echo "$price > $stopPrice" | bc) == "1" ]; then
        # ./sellAsset.sh "$firstSymbolSell" 100 && ./sellAsset.sh "$secondSymbolSell" 100
        echo "Price: $price"
        echo stopLoss hit   
    fi
}

if [ "$#" -ne 4 ]; then
    echo "Usage: ./${0##*/} <ZECUSDC> <200> <ETHUSDC> <ETHZEC>"
    echo "./${0##*/} <SYMBOL_ONE> <SYMBOL_ONE_STOP_PRICE> <buyFirstSYMBOL> <buyFinalSYMBOL>"    
    exit 1
fi

. ./tickerHook.sh $symbol callBack