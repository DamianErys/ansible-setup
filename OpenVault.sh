chmod -x vault-pass.txt

ansible-vault edit group_vars/vault.yml --vault-password-file vault-pass.txt
