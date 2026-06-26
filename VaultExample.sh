ansible-vault view vault.yml --vault-password-file vault-pass.txt | sed 's/:.*/: <VALUE>/' > vault.yml.example
