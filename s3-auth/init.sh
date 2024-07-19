#!/bin/bash

wallet="$1"
neofs_peer="$2"
gate_wallets="$3"

authmate='neofs-s3-authmate'
rules="$(dirname $0)/rules.json"

gate_public_keys=($(jq -r '.accounts[0].contract.script' $gate_wallets | while read l; do
	echo $l | base64 -d | hexdump -e '72/1 "%02x"' | cut -b 5-70
done))

$authmate issue-secret \
	--wallet $wallet \
	--peer $neofs_peer \
	${gate_public_keys[@]/#/--gate-public-key } \
	--bearer-rules $rules |
	jq '{ACCESS_KEY: .access_key_id, SECRET_KEY: .secret_access_key}'
