variable "host_ips" {
  type = map(string)
  default = {
    compute     = "192.168.1.22"
    workstation = "192.168.1.234"
  }
}

# Добавляем имена сетевух для каждого хоста
variable "host_ifaces" {
  type = map(string)
  default = {
    compute     = "enp12s0"
    workstation = "enp13s0"
  }
}

variable "vm_map" {
  type = map(object({
    cpu    = number
    ram    = number
    target = string
  }))
  default = {
    "ai-worker-01" = { cpu = 16, ram = 32768, target = "compute" }
    "ai-worker-02" = { cpu = 8,  ram = 16384, target = "compute" }
    "dev-node"     = { cpu = 4,  ram = 8192,  target = "compute" }
  }
}

variable "base_image_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}
