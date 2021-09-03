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
readonly url_machines_used="https://my.cyberianmine.de/my_miners"

declare -a l_urls=(${url_machines_used})
for url in ${l_urls[@]}
do
  curl -s \
       -k \
       -XGET \
       -b ${f_cookie} \
       ${url} >> ${f_shop}
done

IFS=$'\n'
declare -a l_miners_rawdata=(`grep -A 10 'class="card-title">' ${f_shop} \
	| grep -iE '(card-title)|(Revenue)|(Hosting)|(Profit)'`)

## MAP DATA
s_miners_data=""
declare -a l_miners_data=()
for miner in ${l_miners_rawdata[@]}
do
  rec=$(echo ${miner} | grep -E 'card-title' | cut -f 2 -d '>' | cut -f 1 -d '<')
  if [[ ! -z ${rec} ]]; then s_miners_data="${rec}"; continue; fi
  rec=$(echo ${miner} | grep -E 'Revenue' | cut -f 4 -d '>' | cut -f 1 -d '<' | grep -oP '\d+\.\d+' | head -n 1)
  if [[ ! -z ${rec} ]]; then s_miners_data="${s_miners_data}#${rec}"; continue; fi
  rec=$(echo ${miner} | grep -E 'Hosting' | cut -f 4 -d '>' | cut -f 1 -d '<' | grep -oP '\d+\.\d+' | head -n 1)
  if [[ ! -z ${rec} ]]; then s_miners_data="${s_miners_data}#${rec}"; continue; fi
  rec=$(echo ${miner} | grep -E 'Profit' | cut -f 4 -d '>' | cut -f 1 -d '<' | grep -oP '\d+\.\d+' | head -n 1)
  if [[ ! -z ${rec} ]]; then s_miners_data="${s_miners_data}#${rec}"; fi

  l_miners_data+=(${s_miners_data})
done

for miner in ${l_miners_data[@]}
do
  miner_name=$(echo ${miner} | cut -f 1 -d '#')
  miner_revenue=$(echo ${miner} | cut -f 2 -d '#')
  miner_hosting=$(echo ${miner} | cut -f 3 -d '#')
  miner_profit=$(echo ${miner} | cut -f 4 -d '#')

  miner_buy_index=$(echo "scale=2; ${miner_revenue}/${miner_hosting}" | bc | tr -d '.')
  miner_sell_price=$(echo "scale=2; ${miner_profit} * 20 + 0.5" | bc | cut -f 1 -d '.')

  ### DEBUG
  #echo "miner_name:       ${miner_name}"
  #echo "miner_revenue:    ${miner_revenue}"
  #echo "miner_hosting:    ${miner_hosting}"
  #echo "miner_buy_index:  ${miner_buy_index}"
  #echo "miner_sell_price: ${miner_sell_price}"

  if [[ ${miner_buy_index} -lt 300 ]]; then
    echo -e "=============================================\nname:\t\t${miner_name}\ntype:\t\tsell\nprice:\t\t${miner_sell_price}"
  fi
done

unset IFS

exit 0
