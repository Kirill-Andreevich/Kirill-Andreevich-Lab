variable "worker_count" {
  type    = number
  default = 3
  description = "Количество нод воркеров на 9950X"
}

variable "base_image_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "truenas_ip" {
  type    = string
  default = "192.168.1.30"
}

variable "iscsi_iqn" {
  type    = string
  default = "iqn.2005-10.org.freenas.ctl:k8s-shared-storage"
}
