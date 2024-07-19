# Bootstrap Morph Storage

## Prepare

### get tools
TODO: neofs-adm, neogo, neofs-contract

### set addresses in:
```
inventory/hosts
inventory/configuration/config.yaml
```

### prepare repo, activate env
```
make
source activate
```

### speedup
- remove `serial: 1` from playbooks (`plays/service/neofs.yml`, `plays/service/neofs_s3_gw.yml`)


## CN/IR

### generate wallets

Edit config.yaml or generate a new one with neofs-adm:
```
#neofs-adm config init --path inventory/configuration/config.yaml
```

```
mkdir inventory/configuration/alphabet
neofs-adm -c inventory/configuration/config.yaml morph generate-alphabet --size 4
```

### configure addresses
```
for a in inventory/configuration/wallets/alphabet/node*.json; do
	echo "  - $(neogo wallet dump-keys -w $a | head -2 | tail -1)" >> inventory/group_vars/neofs_ir/morph.yml
done
```


### install cn
```
ansible-playbook -D playbooks/neofs_ir.yml
```

### deploy contracts
```
neofs-adm morph -c inventory/configuration/config.yaml init --contracts tmp/neofs-contract-v0.17.0
```
Optional, check it:
```
neofs-adm morph -c inventory/configuration/config.yaml dump-hashes
```

### set fee
```
neofs-adm morph -c inventory/configuration/config.yaml set-policy ExecFeeFactor=1 StoragePrice=1 FeePerByte=1
```

Optional, check it:
```
RPC=http://node1:40332

hash=`curl -sd '{ "jsonrpc": "2.0", "id": 1, "method": "getcontractstate", "params": [-7] }' $RPC | jq -r '.result.hash'`

for a in getExecFeeFactor getStoragePrice getFeePerByte; do
	neogo contract testinvokefunction -r $RPC $hash $a | jq '.stack[0].value'
done
```
Three `1` should be returned.


## Storage

### transfer gas to storage-node wallets
```
for a in node{1..4}; do
neofs-adm morph -c inventory/configuration/config.yaml generate-storage-wallet --storage-wallet inventory/configuration/wallets/storage/${a}.json --initial-gas 5.0 --alphabet-wallets inventory/configuration/alphabet --label empty
done
```

### install storage node
```
ansible-playbook -D playbooks/neofs_storage.yml
```

#### check it
```
RPC=node1:8080
neogo wallet init -a -w inventory/configuration/client-wallet.json
neofs-cli --rpc-endpoint $RPC -w inventory/configuration/client-wallet.json container create --policy 'REP 1 CBF 1 SELECT 1 FROM *' --basic-acl 0x0FFFFFFF --await
neofs-cli --rpc-endpoint $RPC -w inventory/configuration/client-wallet.json container create --policy 'REP 2 CBF 2 SELECT 4 FROM *' --basic-acl 0x0FFFFFFF --await
neofs-cli --rpc-endpoint $RPC -w inventory/configuration/client-wallet.json object put --cid <CID> --file /etc/issue
neofs-cli --rpc-endpoint $RPC -w inventory/configuration/client-wallet.json object get --cid <CID> --oid <OID>
```


## Gateways

### HTTP
```
for a in inventory/configuration/wallets/http/node{1..4}.json; do neogo wallet init -a -w $a; done
ansible-playbook -D plays/service/neofs_http_gw.yml
```

### S3
```
for a in inventory/configuration/wallets/s3/node{1..4}.json; do neogo wallet init -a -w $a; done
```

```
for a in inventory/configuration/wallets/s3/node{1..4}.json; do
	neogo wallet dump-keys -w $a | head -2 | tail -1
done
```
fill `neofs_s3__public_key` in `inventory/host_vars/*/neofs_s3_gate.yml` with output values

```
ansible-playbook -D plays/service/neofs_s3_gw.yml
```

## Finish
### undo speedup
```
git restore plays/service/neofs.yml plays/service/neofs_s3_gw.yml
```

### run siteplay
```
ansible-playbook -D plays/site_neofs.yml
```
no changes should be logged



## Epoch force tick
```
neofs-adm morph force-new-epoch -c inventory/configuration/config.yaml
```
