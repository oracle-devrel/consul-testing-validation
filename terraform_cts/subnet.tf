# Copyright (c) 2021 Oracle and/or its affiliates.

resource "oci_core_subnet" "mgmt_rgn1" {
  provider = oci.rgn1
  compartment_id = oci_identity_compartment.consul.id
  
  display_name = "mgmt"
  dns_label = "mgmt"
  cidr_block = "172.16.0.0/28"
  vcn_id = oci_core_vcn.rgn1.id
  
  dhcp_options_id = oci_core_dhcp_options.rgn1.id
  # ipv6cidr_block = var.subnet_ipv6cidr_block
  prohibit_internet_ingress = true
  # prohibit_public_ip_on_vnic = false
  route_table_id = oci_core_route_table.private_rgn1.id
  security_list_ids = [
    oci_core_vcn.rgn1.default_security_list_id,
    oci_core_security_list.rgn1_mgmt.id
  ]
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}

resource "oci_core_subnet" "app_rgn1" {
  provider = oci.rgn1
  compartment_id = oci_identity_compartment.consul.id
  
  display_name = "app"
  dns_label = "app"
  cidr_block = "172.16.0.16/28"
  vcn_id = oci_core_vcn.rgn1.id
  
  dhcp_options_id = oci_core_dhcp_options.rgn1.id
  # ipv6cidr_block = var.subnet_ipv6cidr_block
  prohibit_internet_ingress = true
  # prohibit_public_ip_on_vnic = false
  route_table_id = oci_core_route_table.private_rgn1.id
  # security_list_ids = var.subnet_security_list_ids
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}

resource "oci_core_subnet" "lb_rgn1" {
  provider = oci.rgn1
  compartment_id = oci_identity_compartment.consul.id
  
  display_name = "lb"
  dns_label = "lb"
  cidr_block = "172.16.0.240/28"
  vcn_id = oci_core_vcn.rgn1.id
  
  dhcp_options_id = oci_core_dhcp_options.rgn1.id
  # ipv6cidr_block = var.subnet_ipv6cidr_block
  prohibit_internet_ingress = false
  # prohibit_public_ip_on_vnic = false
  route_table_id = oci_core_route_table.public_rgn1.id
  # security_list_ids = var.subnet_security_list_ids
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}