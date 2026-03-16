variable "worker_count" {
  type    = number
  default = 3
}

variable "base_image_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}
