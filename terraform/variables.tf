variable "worker_count" {
  type    = number
  default = 3
}

variable "base_image_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "ips" {
  default = {
    master          = "192.168.1.100"
    gitlab          = "192.168.1.101"
    worker_start_ip = 110
  }
}
