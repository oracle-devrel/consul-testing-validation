# Copyright (c) 2021 Oracle and/or its affiliates.

resource "oci_identity_compartment" "consul" {
  provider = oci.home
  compartment_id = var.compartment_ocid
  description = "Consul testing and validation"
  name = "consul"

  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}