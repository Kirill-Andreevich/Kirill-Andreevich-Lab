resource "local_file" "prometheus_targets" {
  filename = "./../prometheus/targets.json"
  content  = jsonencode([
    for vm in libvirt_domain.my_first_vm : {
      targets = ["${vm.network_interface.0.addresses.0}:9100"]
      labels  = {
        instance = "${vm.name}"
        env      = "terraform"
      }
    }
  ])
}
