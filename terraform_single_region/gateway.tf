# Copyright (c) 2021 Oracle and/or its affiliates.


resource "oci_core_nat_gateway" "rgn1" {
  provider = oci.rgn1
  compartment_id = oci_identity_compartment.consul.id
  display_name = "rgn1"
  vcn_id = oci_core_vcn.rgn1.id
  
  block_traffic = false
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}

resource "oci_core_internet_gateway" "rgn1" {
  provider = oci.rgn1
  compartment_id = oci_identity_compartment.consul.id
  display_name = "rgn1"
  vcn_id = oci_core_vcn.rgn1.id
  
  enabled = true
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}