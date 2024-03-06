VAULT_DIR := $(CURDIR)/../vault

SSH_KEY := `sed -n -r "s/.*ansible_ssh_private_key_file: (.*)/\1/p" inventory.yml`

TARGET_VM_IP_ADDR := `sed -n -r "s/.*ansible_host: (.*)/\1/p" inventory.yml`

.PHONY: clean
clean:
	rm -rf $(CURDIR)/host_vars/k3s/vault.yml
	rm -rf $(CURDIR)/.ssh
	mkdir -p $(CURDIR)/.ssh

.PHONY: credential
credential: clean
	PASSWORD_STORE_DIR=$(VAULT_DIR) pass infra/ansible/vault.yml > $(CURDIR)/host_vars/k3s/vault.yml
	PASSWORD_STORE_DIR=$(VAULT_DIR) pass keys/ssh/isec.pub > $(CURDIR)/.ssh/isec.pub

.PHONY: cluster
cluster: clean credential
	cd $(CURDIR) ; \
	ansible-playbook setup-cluster.yml

.PHONY: app
app:
	cd $(CURDIR) ; \
	cat manifests/application.yml | ssh isec@$(TARGET_VM_IP_ADDR) -i $(SSH_KEY) kubectl apply -f -

.PHONY: delete-app
delete-app:
	cd $(CURDIR) ; \
	cat manifests/application.yml | ssh isec@$(TARGET_VM_IP_ADDR) -i $(SSH_KEY) kubectl delete -f -
