variable "proxmox" {
  type = object({
    endpoint  = string
    user      = string
    pass      = string
    api_token = string
  })
  sensitive = true
}

variable "userdata" {
  type = object({
    user_name       = string
    hashed_password = string # mkpasswd --method=yescrypt (via whois)
    ssh_pub_key     = string
    ssh_pub_key1    = string
  })
  sensitive = true
}

locals {
  k3s = {
    vmid                 = 115
    template_vmid        = 9000
    memory               = 40960
    cores                = 4
    onboot               = true
    proxmox_node         = "pve"
    proxmox_address      = "172.16.50.2"
    hostname             = "isec-k3s"
    ipv4_address         = "172.16.50.15"
    ipv4_prefix          = "24"
    ipv4_default_gateway = "172.16.50.1"
  }
}
