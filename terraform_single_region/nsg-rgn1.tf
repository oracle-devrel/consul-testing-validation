# Copyright (c) 2021 Oracle and/or its affiliates.

resource "oci_core_network_security_group" "consul_rgn1" {
  provider = oci.rgn1
  compartment_id = oci_identity_compartment.consul.id
  vcn_id = oci_core_vcn.rgn1.id
  display_name = "consul"
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}

resource "oci_core_network_security_group_security_rule" "e_to_consul_rgn1" {
  provider = oci.rgn1
  network_security_group_id = oci_core_network_security_group.consul_rgn1.id
  direction = "EGRESS"
  protocol = "all"
  stateless = false
  
  description = "Permit intra-cluster traffic"
  destination = oci_core_network_security_group.consul_rgn1.id
  destination_type = local.nsg_types["nsg"]
}

resource "oci_core_network_security_group_security_rule" "i_from_consul_rgn1" {
  provider = oci.rgn1
  network_security_group_id = oci_core_network_security_group.consul_rgn1.id
  direction = "INGRESS"
  protocol = "all"
  stateless = false
  
  description = "Permit intra-cluster traffic"
  source = oci_core_network_security_group.consul_rgn1.id
  source_type = local.nsg_types["nsg"]
}

resource "oci_core_network_security_group_security_rule" "i_from_bastion_compute_ssh" {
  provider = oci.rgn1
  network_security_group_id = oci_core_network_security_group.consul_rgn1.id
  direction = "INGRESS"
  protocol = "6"
  stateless = false
  tcp_options {
    destination_port_range {
      max = "22"
      min = "22"
    }
  }
  description = "Permit SSH from bastion compute"
  source = oci_core_network_security_group.bastion_rgn1.id
  source_type = local.nsg_types["nsg"]
}

resource "oci_core_network_security_group_security_rule" "i_from_bastion_compute_8500" {
  provider = oci.rgn1
  network_security_group_id = oci_core_network_security_group.consul_rgn1.id
  direction = "INGRESS"
  protocol = "6"
  stateless = false
  tcp_options {
    destination_port_range {
      max = "8500"
      min = "8500"
    }
  }
  description = "Permit tcp/8500 from bastion compute"
  source = oci_core_network_security_group.bastion_rgn1.id
  source_type = local.nsg_types["nsg"]
}

resource "oci_core_network_security_group" "bastion_rgn1" {
  provider = oci.rgn1
  compartment_id = oci_identity_compartment.consul.id
  vcn_id = oci_core_vcn.rgn1.id
  display_name = "bastion"
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}

resource "oci_core_network_security_group_security_rule" "e_to_consul_ssh" {
  provider = oci.rgn1
  network_security_group_id = oci_core_network_security_group.bastion_rgn1.id
  direction = "EGRESS"
  protocol = "6"
  stateless = false
  tcp_options {
    destination_port_range {
      max = "22"
      min = "22"
    }
  }
  description = "Permit SSH to Consul"
  destination = oci_core_network_security_group.consul_rgn1.id
  destination_type = local.nsg_types["nsg"]
}

resource "oci_core_network_security_group_security_rule" "e_to_consul_8500" {
  provider = oci.rgn1
  network_security_group_id = oci_core_network_security_group.bastion_rgn1.id
  direction = "EGRESS"
  protocol = "6"
  stateless = false
  tcp_options {
    destination_port_range {
      max = "8500"
      min = "8500"
    }
  }
  description = "Permit tcp/8500 to Consul"
  destination = oci_core_network_security_group.consul_rgn1.id
  destination_type = local.nsg_types["nsg"]
}

resource "oci_core_network_security_group" "web_rgn1" {
  provider = oci.rgn1
  compartment_id = oci_identity_compartment.consul.id
  vcn_id = oci_core_vcn.rgn1.id
  display_name = "web"
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}

resource "oci_core_network_security_group_security_rule" "i_to_web" {
  provider = oci.rgn1
  network_security_group_id = oci_core_network_security_group.web_rgn1.id
  direction = "INGRESS"
  protocol = "6"
  stateless = false
  
  description = "Permit HTTP (tcp/80) traffic"
  source = "172.16.0.0/24"
  source_type = local.nsg_types["cidr"]
  tcp_options {
    destination_port_range {
      max = "80"
      min = "80"
    }
  }
}


resource "oci_core_network_security_group" "lb_rgn1" {
  provider = oci.rgn1
  compartment_id = oci_identity_compartment.consul.id
  vcn_id = oci_core_vcn.rgn1.id
  display_name = "lb"
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}

resource "oci_core_network_security_group_security_rule" "i_to_lb" {
  provider = oci.rgn1
  network_security_group_id = oci_core_network_security_group.lb_rgn1.id
  direction = "INGRESS"
  protocol = "6"
  stateless = false
  
  description = "Permit HTTPS (tcp/443) traffic"
  source = var.my_public_ip # "0.0.0.0/0"
  source_type = local.nsg_types["cidr"]
  tcp_options {
    destination_port_range {
      max = "80"
      min = "80"
    }
  }
}
