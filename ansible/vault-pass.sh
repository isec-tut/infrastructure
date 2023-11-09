#!/bin/bash

CURDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
VAULT_DIR=$CURDIR/../vault

PASSWORD_STORE_DIR=$VAULT_DIR pass infra/ansible/vault/passphrase
