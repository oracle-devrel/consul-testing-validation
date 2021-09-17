# Copyright (c) 2021 Oracle and/or its affiliates.

resource "oci_load_balancer_backend" "rgn1" {
    count = var.num_web_svrs
    backendset_name = oci_load_balancer_backend_set.web_rgn1.name
    ip_address = oci_core_instance.web_rgn1[count.index].private_ip
    load_balancer_id = oci_load_balancer_load_balancer.pub_rgn1.id
    port = 80
    
    backup = false
    drain = false
    offline = false
    weight = 5
}

resource "oci_load_balancer_backend_set" "web_rgn1" {
  health_checker {
    protocol = "HTTP"
    
    interval_ms = 1000
    port = 80
    response_body_regex = ".*"
    # retries = 
    return_code = 200
    timeout_in_millis = 300
    url_path = "/"
  }
  load_balancer_id = oci_load_balancer_load_balancer.pub_rgn1.id
  name = "web"
  policy = "LEAST_CONNECTIONS"
}

resource "oci_load_balancer_listener" "web_rgn1" {
  default_backend_set_name = oci_load_balancer_backend_set.web_rgn1.name
  load_balancer_id = oci_load_balancer_load_balancer.pub_rgn1.id
  name = "web_rgn1"
  port = 80
  protocol = "HTTP"
}

resource "oci_load_balancer_load_balancer" "pub_rgn1" {
  compartment_id = oci_identity_compartment.consul.id
  display_name = "pub"
  shape = "flexible"
  subnet_ids = [ oci_core_subnet.lb_rgn1.id ]
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
  
  ip_mode = "IPV4"
  is_private = false
  network_security_group_ids = [
    oci_core_network_security_group.lb_rgn1.id
  ]
  shape_details {
      maximum_bandwidth_in_mbps = 10
      minimum_bandwidth_in_mbps = 10
  }
}
