# Copyright (c) 2021 Oracle and/or its affiliates.

resource "oci_identity_dynamic_group" "cts" {
  compartment_id = var.tenancy_ocid
  description = "CTS example"
  matching_rule = "All {instance.id = '${oci_core_instance.cts_rgn1.id}'}"
  name = "cts_example"
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}

resource "oci_identity_policy" "cts" {
  depends_on = [
    oci_identity_dynamic_group.cts
  ]
  compartment_id = oci_identity_compartment.consul.id
  description = "Policies related to CTS example"
  name = "cts"
  statements = [
    "allow dynamic-group cts_example to use load-balancers in compartment ${oci_identity_compartment.consul.name}"
  ]
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}
