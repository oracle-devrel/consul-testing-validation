
data "oci_identity_region_subscriptions" "home_region_subscriptions" {
  tenancy_id = var.tenancy_ocid
  
  filter {
    name   = "is_home_region"
    values = [true]
  }
}

data "oci_core_images" "this" {
  # compartment_id = var.tenancy_ocid
  compartment_id = var.compartment_ocid
  filter {
    name = "state"
    values = ["AVAILABLE"]
  }
}

data "oci_identity_availability_domains" "rgn1_ads" {
  provider = oci.rgn1
  compartment_id = var.tenancy_ocid
}

data "oci_core_services" "rgn1" {
  provider = oci.rgn1
}

