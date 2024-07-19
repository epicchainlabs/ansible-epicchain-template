# Bootstrap Morph Storage

## Prepare

### get tools
TODO: neofs-adm, neogo, neofs-contract, neofs-s3-authmate

```
mkdir tmp/bin
cd tmp
wget -O bin/neofs-adm https://github.com/nspcc-dev/neofs-node/releases/download/v0.37.0/neofs-adm-amd64
wget -O bin/neogo https://github.com/nspcc-dev/neo-go/releases/download/v0.101.3/neo-go-linux-amd64
wget -O bin/neofs-s3-authmate https://github.com/nspcc-dev/neofs-s3-gw/releases/download/v0.27.1/neofs-s3-authmate-linux-amd64
chmod +x bin/*
wget -O - https://github.com/nspcc-dev/neofs-contract/releases/download/v0.17.0/neofs-contract-v0.17.0.tar.gz | tar xz
cd ..
PATH="`pwd`/tmp/bin:$PATH"
```

### set addresses in:
```
inventory/hosts
inventory/configuration/config.yaml
```

### prepare repo, activate env
```
./init.sh
source activate
```


## CN/IR

### create config
Edit config.yaml or generate a new one with neofs-adm:
```
#neofs-adm config init --path inventory/configuration/config.yaml
```

### generate wallets
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
ansible-playbook -D nspcc.neofs.ir
```

### deploy contracts
```
neofs-adm morph -c inventory/configuration/config.yaml init --contracts tmp/neofs-contract-v0.17.0
```

### set fee
```
neofs-adm morph -c inventory/configuration/config.yaml set-policy ExecFeeFactor=1 StoragePrice=1 FeePerByte=1
```


## Storage

### install storage node
```
ansible-playbook -D nspcc.neofs.storage
```

## Epoch force tick
```
neofs-adm morph force-new-epoch -c inventory/configuration/config.yaml
```


## Gateways

### HTTP
```
for a in inventory/configuration/wallets/http/node0{1..4}.json; do neogo wallet init -a -w $a; done
ansible-playbook -D nspcc.neofs.http_gw
```

### S3
```
ansible-playbook -D nspcc.neofs.s3_gw
```

```
S3_AUTH_WALLET='inventory/configuration/wallets/s3-auth.json'

neofs-adm morph -c inventory/configuration/config.yaml generate-storage-wallet --storage-wallet $S3_AUTH_WALLET --initial-gas 10 --alphabet-wallets inventory/configuration/alphabet

RPC=max0-0391.mb.nebiuscore.net:8080
s3-auth/init.sh $S3_AUTH_WALLET $RPC 'inventory/configuration/wallets/s3/*.json'
```
