#!/bin/bash
#

readonly C_CM_USERNAME="${CM_USERNAME}"
readonly C_CM_PASSWORD="${CM_PASSWORD}"

if [[ -z ${C_CM_USERNAME} ]] || [[ -z ${C_CM_PASSWORD} ]];then
  echo "FATAL: CM_USERNAME and CM_PASSWORD cannot be empty."
  exit 1
fi

## LOGIN
f_cookie=$(dirname ${0})/cookie.jar
f_shop=$(dirname ${0})/machine_lists.html

# clean-up
rm -f ${f_cookie} ${f_shop} 2>/dev/null

# get token
login_token=$(curl -sfk \
                   -c ${f_cookie} \
                   'https://my.cyberianmine.de/users/sign_in' \
              | grep -i 'csrf-token' \
              | grep -oE 'content=".*" />' \
              | cut -f 2 -d '"')
curl -s \
     -k \
     -XPOST \
     -b ${f_cookie} \
     -c ${f_cookie} \
     --data-urlencode 'authenticity_token='${login_token} \
     --data-urlencode 'user[email]='${C_CM_USERNAME} \
     --data-urlencode 'user[password]='${C_CM_PASSWORD} \
     'https://my.cyberianmine.de/users/sign_in' &>/dev/null


## GET_DATA
readonly url_machines_new="https://my.cyberianmine.de/shop_miners"
readonly url_machines_preorder="https://my.cyberianmine.de/shop_miners/preorder"

declare -a l_urls=(${url_machines_new} ${url_machines_preorder})
for url in ${l_urls[@]}
do
  curl -s \
       -k \
       -XGET \
       -b ${f_cookie} \
       ${url} >> ${f_shop}
done

IFS=$'\n'
declare -a l_miners_rawdata=(`grep -B 4 -A 9 'class="card-title">' ${f_shop} \
	| grep -iE '(card-title)|(Price, EUR)|(Revenue)|(Hosting)|(ROI)|(badge badge\-)'`)

## MAP DATA
s_miners_data=""
declare -a l_miners_data=()
for miner in ${l_miners_rawdata[@]}
do
  rec=$(echo ${miner} | grep -E '(badge badge\-)' | cut -f 2 -d '>' | cut -f 1 -d '<')
  if [[ ! -z ${rec} ]]; then s_miners_data="${rec}"; continue; fi
  rec=$(echo ${miner} | grep -E 'card-title' | cut -f 2 -d '>' | cut -f 1 -d '<')
  if [[ ! -z ${rec} ]]; then s_miners_data="${s_miners_data}#${rec}"; continue; fi
  rec=$(echo ${miner} | grep -E 'Price, EUR' | cut -f 4 -d '>' | cut -f 1 -d '<' | awk '{ print $1 }' | cut -f 1 -d '.')
  if [[ ! -z ${rec} ]]; then s_miners_data="${s_miners_data}#${rec}"; continue; fi
  rec=$(echo ${miner} | grep -E 'Revenue' | cut -f 4 -d '>' | cut -f 1 -d '<' | grep -oE '\d+\.\d+' | head -n 1)
  if [[ ! -z ${rec} ]]; then s_miners_data="${s_miners_data}#${rec}"; continue; fi
  rec=$(echo ${miner} | grep -E 'Hosting' | cut -f 4 -d '>' | cut -f 1 -d '<' | grep -oE '\d+\.\d+' | head -n 1)
  if [[ ! -z ${rec} ]]; then s_miners_data="${s_miners_data}#${rec}"; continue; fi
  rec=$(echo ${miner} | grep -E 'ROI' | cut -f 4 -d '>' | cut -f 1 -d '<' | awk '{ print $1 }')
  if [[ ! -z ${rec} ]]; then s_miners_data="${s_miners_data}#${rec}"; fi

  l_miners_data+=($(echo ${s_miners_data} | grep -i 'In Stock'))
done

halving_months=$($(dirname ${0})/../halving.sh)

for miner in ${l_miners_data[@]}
do
  miner_name=$(echo ${miner} | cut -f 2 -d '#')
  miner_price=$(echo ${miner} | cut -f 3 -d '#')
  miner_revenue=$(echo ${miner} | cut -f 4 -d '#')
  miner_hosting=$(echo ${miner} | cut -f 5 -d '#')
  miner_roi=$(echo ${miner} | cut -f 6 -d '#')

  miner_buy_index=$(echo "scale=2; ${miner_revenue}/${miner_hosting}" | bc | tr -d '.')

  if [[ ${miner_roi} -lt ${halving_months} ]] && [[ ${miner_buy_index} -ge 350 ]]; then
    echo -e "=============================================\nname:\t\t${miner_name}\ntype:\t\tnew\nprice:\t\t${miner_price}\nroi:\t\t${miner_roi}"
  fi
done

unset IFS

exit 0
