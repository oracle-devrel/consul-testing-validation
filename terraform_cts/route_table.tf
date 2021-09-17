# Copyright (c) 2021 Oracle and/or its affiliates.

resource "oci_core_route_table" "public_rgn1" {
  provider = oci.rgn1
  compartment_id = oci_identity_compartment.consul.id
  vcn_id = oci_core_vcn.rgn1.id
  display_name = "public"
  
  route_rules {
    network_entity_id = oci_core_internet_gateway.rgn1.id
    description = "Default route"
    destination = "0.0.0.0/0"
    destination_type = local.dest_types["cidr"]
  }
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}

resource "oci_core_route_table" "private_rgn1" {
  provider = oci.rgn1
  compartment_id = oci_identity_compartment.consul.id
  vcn_id = oci_core_vcn.rgn1.id
  display_name = "private"
  
  route_rules {
    network_entity_id = oci_core_nat_gateway.rgn1.id
    description = "Default route"
    destination = "0.0.0.0/0"
    destination_type = local.dest_types["cidr"]
  }
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}