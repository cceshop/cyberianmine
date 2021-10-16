#!/usr/bin/env bash
#

readonly CB_TS="`date '+%s'`"
readonly CB_VER="2021-10-16"

readonly CB_API="https://api.coinbase.com"

function getBTCWalletId() {
  local CB_EP="/v2/accounts"
  local CB_EP_METHOD="GET"
  local CB_EP_BODY=""

  local CB_EP_MSG="${CB_TS}${CB_EP_METHOD}${CB_EP}${CB_EP_BODY}"
  local CB_EP_SIGN=`echo -n ${CB_EP_MSG} | openssl dgst -sha256 -hmac "${CB_SEC}" | cut -f 2 -d '='`

  curl -sk "${CB_API}${CB_EP}" \
    --header "CB-ACCESS-KEY: ${CB_KEY}" \
    --header "CB-ACCESS-SIGN: ${CB_EP_SIGN}" \
    --header "CB-ACCESS-TIMESTAMP: ${CB_TS}" \
    --header "CB-VERSION: ${CB_VER}" \
  | jq -r '.data[] | select (.name == "BTC Wallet") | .id'

  return
}

function getBTCWalletBalance() {
  local CB_EP="/v2/accounts"
  local CB_EP_METHOD="GET"
  local CB_EP_BODY=""

  local CB_EP_MSG="${CB_TS}${CB_EP_METHOD}${CB_EP}${CB_EP_BODY}"
  local CB_EP_SIGN=`echo -n ${CB_EP_MSG} | openssl dgst -sha256 -hmac "${CB_SEC}" | cut -f 2 -d '='`

  curl -sk "${CB_API}${CB_EP}" \
    --header "CB-ACCESS-KEY: ${CB_KEY}" \
    --header "CB-ACCESS-SIGN: ${CB_EP_SIGN}" \
    --header "CB-ACCESS-TIMESTAMP: ${CB_TS}" \
    --header "CB-VERSION: ${CB_VER}" \
  | jq -r '.data[] | select (.name == "BTC Wallet") | .balance.amount'

  return
}

function getRatesBTCEUR() {
  curl -sk https://api.coinbase.com/v2/exchange-rates?currency=BTC | jq -r '.data.rates.EUR'

  return
}

id=`getBTCWalletId`
bal=`getBTCWalletBalance`
rate=`getRatesBTCEUR`

eur=`echo "scale=10; (${bal} * ${rate})" | bc | cut -f 1 -d '.'`

echo "Wallet info"
echo "ID:       ${id}"
echo "Balance:  ${bal} BTC"
echo "Balance:  ${eur} EUR"

exit 0
