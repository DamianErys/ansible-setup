chmod -x vault-pass.txt

ansible-vault edit vault.yml --vault-password-file vault-pass.txt
