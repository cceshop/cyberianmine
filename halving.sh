#!/usr/bin/env bash
#

url_blockchain_info='https://blockchain.info/stats?format=json'

declare -a l_blockchain_info=(`curl -sfk ${url_blockchain_info} 2>/dev/null \
                               | jq -r '.n_blocks_total, .minutes_between_blocks'`)

if [[ ${#l_blockchain_info[*]} -ne 2 ]]; then
  echo "Could not get blockchain data"
  exit 1
fi

readonly C_BLOCK_HALVING=840000
V_BLOCK_CURRENT=${l_blockchain_info[0]}
V_BLOCK_MINUTES=${l_blockchain_info[1]}

next_halving_days=$(echo "scale=4; (${C_BLOCK_HALVING} - ${V_BLOCK_CURRENT}) * ${V_BLOCK_MINUTES} / 60 / 24 / 30 + .5" | bc | cut -f 1 -d '.')
echo ${next_halving_days}

exit 0
