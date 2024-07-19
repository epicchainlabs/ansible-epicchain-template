#!/bin/sh

virtualenv --prompt='neofs' tmp/venv

. ./activate

pip install -Ur requirements.txt

ansible-galaxy install -r requirements.yml --force
