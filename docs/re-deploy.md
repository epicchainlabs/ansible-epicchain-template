# Re-deploy

```
source activate

ansible -m shell -a "sudo systemctl stop neofs-s3" neofs_storage
ansible -m shell -a "sudo systemctl stop neofs-storage" neofs_storage
ansible -m shell -a "sudo systemctl stop neofs-ir" neofs_ir

// load
ansible -m shell -a "sudo rm -rf /srv/ir /srv/neofs" all

ansible-playbook -D nspcc.neofs.ir
ansible -m shell -a "sudo systemctl start neofs-ir" neofs_ir

PATH="`pwd`/tmp/bin:$PATH"
neofs-adm morph -c inventory/configuration/config.yaml init --contracts tmp/neofs-contract-v0.17.0
neofs-adm morph -c inventory/configuration/config.yaml set-policy ExecFeeFactor=1 StoragePrice=1 FeePerByte=1

rm -rf inventory/configuration/wallets/storage
ansible-playbook -D nspcc.neofs.storage

neofs-adm morph force-new-epoch -c inventory/configuration/config.yaml

ansible-playbook -D nspcc.neofs.s3_gw

S3_AUTH_WALLET='inventory/configuration/wallets/s3-auth.json'

neofs-adm morph -c inventory/configuration/config.yaml generate-storage-wallet --storage-wallet $S3_AUTH_WALLET --initial-gas 10 --alphabet-wallets inventory/configuration/alphabet

RPC=node01:8080
s3-auth/init.sh $S3_AUTH_WALLET $RPC 'inventory/configuration/wallets/s3/*.json'
```
