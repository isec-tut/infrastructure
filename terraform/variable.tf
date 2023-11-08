variable "proxmox" {
  type = object({
    api_url      = string
    token_id     = string
    token_secret = string
  })
  sensitive = true
}

variable "userdata" {
  type = object({
    user_name       = string
    hashed_password = string # mkpasswd --method=yescrypt (via whois)
    ssh_pub_key     = string
  })
  sensitive = true
}

locals {
  k3s = {
    vmid                 = 115
    proxmox_node         = "pve"
    proxmox_address      = "172.16.50.2"
    hostname             = "isec-k3s"
    ipv4_address         = "172.16.50.15"
    ipv4_prefix          = "24"
    ipv4_default_gateway = "172.16.50.1"
  }
}
