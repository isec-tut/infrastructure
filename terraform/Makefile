VAULT_DIR := $(CURDIR)/../vault

PROXMOX_NODE := pve
PROXMOX_ADDRESS := 172.16.50.2
TEMPLATE_VMID := 9000

TARGET_VM_ID := 115
TARGET_VM_NAME := isec-k3s
TARGET_VM_IP_ADDR := 172.16.50.15

.PHONY: clean
clean:
	rm -rf $(CURDIR)/.tmp
	rm -f $(CURDIR)/*.tfvars*
	rm -f $(CURDIR)/*.tfstate*

.PHONY: credential
credential:
	PASSWORD_STORE_DIR=$(VAULT_DIR) pass infra/terraform/tfvars > $(CURDIR)/terraform.tfvars

.PHONY: cleanup-cloudimg
cleanup-cloudimg:
	ssh root@$(PROXMOX_ADDRESS) rm -f jammy-server-cloudimg-amd64.img

.PHONY: download-cloudimg
download-cloudimg:
	ssh root@$(PROXMOX_ADDRESS) wget -q https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img -O jammy-server-cloudimg-amd64.img

.PHONY: destroy-template
destroy-template:
	ssh root@$(PROXMOX_ADDRESS) qm destroy $(TEMPLATE_VMID) --destroy-unreferenced-disks=1 --purge=1 || true

.PHONY: create-template
create-template:
	ssh root@$(PROXMOX_ADDRESS) qm create $(TEMPLATE_VMID) --name ubuntu2204-server-template \
			--agent 1 --ostype l26 --memory 2048 --cpu host --cores 4 --net0 virtio,bridge=vmbr0 && \
	ssh root@$(PROXMOX_ADDRESS) qm importdisk $(TEMPLATE_VMID) jammy-server-cloudimg-amd64.img local-zfs && \
	ssh root@$(PROXMOX_ADDRESS) qm set $(TEMPLATE_VMID) --scsihw virtio-scsi-pci --scsi0 local-zfs:vm-$(TEMPLATE_VMID)-disk-0,ssd=1 && \
	ssh root@$(PROXMOX_ADDRESS) qm set $(TEMPLATE_VMID) --ide2 local-zfs:cloudinit && \
	ssh root@$(PROXMOX_ADDRESS) qm set $(TEMPLATE_VMID) --boot c --bootdisk scsi0 && \
	ssh root@$(PROXMOX_ADDRESS) qm template $(TEMPLATE_VMID)

.PHONY: template
template: download-cloudimg create-template

.PHONY: update-template
update-template: cleanup-cloudimg download-cloudimg destroy-template create-template

.PHONY: destroy-vm
destroy-vm:
	ssh root@$(PROXMOX_ADDRESS) qm destroy $(TARGET_VM_ID) --destroy-unreferenced-disks=1 --purge=1 || true

.PHONY: vm
vm: clean credential
	cd $(CURDIR) ; \
	sed -i -r -e 's/(.*vmid.*= ).*/\1$(TARGET_VM_ID)/g' variable.tf && \
	sed -i -r -e 's/(.*hostname.*= ").*"/\1$(TARGET_VM_NAME)"/g' variable.tf && \
	sed -i -r -e 's/(.*ipv4_address.*= ").*"/\1$(TARGET_VM_IP_ADDR)"/g' variable.tf && \
	terraform plan && \
	terraform apply
