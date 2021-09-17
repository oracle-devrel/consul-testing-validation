# Copyright (c) 2021 Oracle and/or its affiliates.

output "bastion_pub_ip" {
  value = oci_core_instance.bastion_rgn1.public_ip
}

output "rgn1_lb_pub_ip" {
  value = oci_load_balancer_load_balancer.pub_rgn1.ip_addresses[0]
}
