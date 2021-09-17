# Copyright (c) 2021 Oracle and/or its affiliates.

output "bastion_pub_ip" {
  value = oci_core_instance.bastion_rgn1.public_ip
}

output "rgn1_lb_pub_ip" {
  value = oci_load_balancer_load_balancer.pub_rgn1.ip_addresses[0]
}

output "lb_id" {
  value = oci_load_balancer_load_balancer.pub_rgn1.id
}

output "be_set_name" {
  value = oci_load_balancer_backend_set.web_rgn1.name
}