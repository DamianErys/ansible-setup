ansible-vault view group_vars/vault.yml --vault-password-file vault-pass.txt | sed 's/:.*/: <VALUE>/' > group_vars/vault.yml.example
