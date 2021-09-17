# Copyright (c) 2021 Oracle and/or its affiliates.

resource "oci_core_dhcp_options" "rgn1" {
  provider = oci.rgn1
  compartment_id = oci_identity_compartment.consul.id
  display_name = "rgn1"
  
  vcn_id = oci_core_vcn.rgn1.id
  
  options {
    type = "DomainNameServer"
    server_type = "VcnLocalPlusInternet"
  }
  
  options {
    type = "SearchDomain"
    search_domain_names = [ "rgn1.oraclevcn.com" ]
  }
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}