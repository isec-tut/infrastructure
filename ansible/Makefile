VAULT_DIR := $(CURDIR)/../../vault

TARGET_VM_IP_ADDR := 172.16.50.16

.PHONY: clean
clean:
	rm -rf $(CURDIR)/host_vars/k3s/vault.yml

.PHONY: credential
credential:
	PASSWORD_STORE_DIR=$(VAULT_DIR) pass infra/ansible/vault > $(CURDIR)/host_vars/k3s/vault.yml

.PHONY: cluster
cluster: clean credential
	cd $(CURDIR) ; \
	sed -i -r -e 's/(.*ansible_host: ).*/\1$(TARGET_VM_IP_ADDR)/g' inventory.yml && \
	ansible-playbook setup-cluster.yml

.PHONY: app
app:
	cd $(CURDIR) ; \
	cat manifests/application.yml | ssh isec@$(TARGET_VM_IP_ADDR) -i ../.ssh/gpg.pub kubectl apply -f -