# Copyright (c) 2021 Oracle and/or its affiliates.

resource "oci_core_security_list" "rgn1_mgmt" {
  provider = oci.rgn1
  compartment_id = oci_identity_compartment.consul.id
  vcn_id = oci_core_vcn.rgn1.id
  display_name = "mgmt"
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
  
  egress_security_rules {
    description = "Permit SSH access from bastion"
    protocol = "6"
    destination = "172.16.0.0/28"
    destination_type = local.nsg_types["cidr"]
    stateless = true
    tcp_options {
      max = "22"
      min = "22"
    }
  }
  ingress_security_rules {
    description = "Permit SSH from bastion"
    protocol = "6"
    source = "172.16.0.0/28"
    source_type = local.nsg_types["cidr"]
    stateless = true
    tcp_options {
      max = "22"
      min = "22"
    }
  }
}
