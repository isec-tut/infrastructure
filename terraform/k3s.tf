# Source the Cloud Init userdata Config file
data "template_file" "cloud_init_k3s_userdata" {
  template = file("${path.module}/cloud-inits/userdata.yml.tftpl")

  vars = {
    hostname        = local.k3s.hostname
    user_name       = var.userdata.user_name
    hashed_password = var.userdata.hashed_password
    ssh_pub_key     = var.userdata.ssh_pub_key
    ssh_pub_key1    = var.userdata.ssh_pub_key1
  }
}

# Source the Cloud Init network Config file
data "template_file" "cloud_init_k3s_network" {
  template = file("${path.module}/cloud-inits/network.yml.tftpl")

  vars = {
    ipv4_address         = local.k3s.ipv4_address
    ipv4_prefix          = local.k3s.ipv4_prefix
    ipv4_default_gateway = local.k3s.ipv4_default_gateway
  }
}

# Create a local copy of the file, to transfer to Proxmox
resource "local_file" "cloud_init_k3s_userdata" {
  content  = data.template_file.cloud_init_k3s_userdata.rendered
  filename = "${path.module}/.tmp/cloud_init_k3s_userdata.yml"
}

# Create a local copy of the file, to transfer to Proxmox
resource "local_file" "cloud_init_k3s_network" {
  content  = data.template_file.cloud_init_k3s_network.rendered
  filename = "${path.module}/.tmp/cloud_init_k3s_network.yml"
}

# Transfer the file to the Proxmox Host
resource "null_resource" "cloud_init_k3s_userdata" {
  connection {
    type  = "ssh"
    user  = "root"
    agent = true
    host  = local.k3s.proxmox_address
  }

  provisioner "file" {
    source      = local_file.cloud_init_k3s_userdata.filename
    destination = "/var/lib/vz/snippets/cloud_init_k3s_userdata.yml"
  }
}

# Transfer the file to the Proxmox Host
resource "null_resource" "cloud_init_k3s_network" {
  connection {
    type  = "ssh"
    user  = "root"
    agent = true
    host  = local.k3s.proxmox_address
  }

  provisioner "file" {
    source      = local_file.cloud_init_k3s_network.filename
    destination = "/var/lib/vz/snippets/cloud_init_k3s_network.yml"
  }
}

# Create k3s vm on the Proxmox
resource "proxmox_vm_qemu" "vm_k3s" {
  # Wait for the cloud-config file to exist
  depends_on = [
    null_resource.cloud_init_k3s_userdata,
    null_resource.cloud_init_k3s_network
  ]

  vmid        = local.k3s.vmid
  name        = local.k3s.hostname
  target_node = local.k3s.proxmox_node

  clone      = "ubuntu2204-server-template"
  full_clone = true
  os_type    = "cloud-init"

  cicustom = "user=local:snippets/cloud_init_k3s_userdata.yml,network=local:snippets/cloud_init_k3s_network.yml"

  memory  = 40960
  cores   = 4
  qemu_os = "l26"
  agent   = 1
  onboot  = true

  boot   = "order=scsi0"
  scsihw = "virtio-scsi-pci"

  disk {
    size    = "128G"
    type    = "scsi"
    storage = "local-zfs"
    ssd     = 1
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Ignore changes to the network
  ## MAC address is generated on every apply, causing
  ## TF to think this needs to be rebuilt on every apply
  lifecycle {
    ignore_changes = [
      network
    ]
  }
}

# Wait for cloud-init completed, reboot vm
resource "null_resource" "vm_k3s_reboot" {
  depends_on = [proxmox_vm_qemu.vm_k3s]

  provisioner "remote-exec" {
    connection {
      type  = "ssh"
      user  = var.userdata.user_name
      agent = true
      host  = local.k3s.ipv4_address
    }
    inline = [
      "sudo cloud-init status --wait",
      "sudo shutdown -r +0"
    ]
  }
}
