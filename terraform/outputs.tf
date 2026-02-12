output "vm_ips" {
  description = "Список IP-адресов всех созданных ВМ"
  value = {
    for vm in libvirt_domain.my_first_vm :
    vm.name => vm.network_interface.0.addresses
  }
}
