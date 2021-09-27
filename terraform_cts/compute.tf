# Copyright (c) 2021 Oracle and/or its affiliates.

resource "oci_core_instance" "bastion_rgn1" {
  availability_domain = data.oci_identity_availability_domains.rgn1_ads.availability_domains[0].name # lookup(data.oci_identity_availability_domains.rgn2_ads.availability_domains[0],"name")
  compartment_id = oci_identity_compartment.consul.id
  display_name = "bastion"
  shape = "VM.Standard2.1"
  
  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled = false
    is_monitoring_disabled = false
    plugins_config {
      desired_state = "ENABLED"
      name = "Bastion"
    }
  }
  create_vnic_details {
    assign_private_dns_record = true
    assign_public_ip = true
    display_name = "bastion"
    hostname_label = "bastion"
    nsg_ids = [
      oci_core_network_security_group.bastion_rgn1.id
    ]
    # private_ip = 
    skip_source_dest_check = false
    subnet_id = oci_core_subnet.lb_rgn1.id
  }
  # shape_config {
  #   baseline_ocpu_utilization = var.instance_shape_config_baseline_ocpu_utilization
  #   memory_in_gbs = var.instance_shape_config_memory_in_gbs
  #   ocpus = var.instance_shape_config_ocpus
  # }
  metadata = {
    ssh_authorized_keys = local.ssh_pub_keys
  }
  source_details {
    source_id = local.list_images[var.compute_image_name].id
    source_type = "image"
    
    boot_volume_size_in_gbs = 50
  }
  preserve_boot_volume = false
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
}

resource "oci_core_instance" "consul_1_rgn1" {
  availability_domain = data.oci_identity_availability_domains.rgn1_ads.availability_domains[0].name # lookup(data.oci_identity_availability_domains.rgn2_ads.availability_domains[0],"name")
  compartment_id = oci_identity_compartment.consul.id
  display_name = "consul-1"
  shape = "VM.Standard2.1"
  
  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled = false
    is_monitoring_disabled = false
    plugins_config {
      desired_state = "ENABLED"
      name = "Bastion"
    }
  }
  create_vnic_details {
    assign_private_dns_record = true
    assign_public_ip = false
    display_name = "consul-1"
    hostname_label = "consul-1"
    nsg_ids = [
      oci_core_network_security_group.consul_rgn1.id
    ]
    private_ip = local.region1_consul_ips[0]
    skip_source_dest_check = false
    subnet_id = oci_core_subnet.mgmt_rgn1.id
  }
  # shape_config {
  #   baseline_ocpu_utilization = var.instance_shape_config_baseline_ocpu_utilization
  #   memory_in_gbs = var.instance_shape_config_memory_in_gbs
  #   ocpus = var.instance_shape_config_ocpus
  # }
  metadata = {
    ssh_authorized_keys = local.ssh_pub_keys
  }
  source_details {
    source_id = local.list_images[var.compute_image_name].id
    source_type = "image"
    
    boot_volume_size_in_gbs = 50
    # kms_key_id = oci_kms_key.test_key.id
  }
  preserve_boot_volume = false
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
  
  # give the instance time to boot-up before proceeding
  provisioner "local-exec" {
    command = "echo \"Waiting for the instance to boot-up...\" && sleep 60"
  }
  
  provisioner "file" {
    content     = tls_private_key.node_to_node.private_key_pem
    destination = "/home/opc/consul.key"
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = oci_core_instance.consul_1_rgn1.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod 0600 /home/opc/consul.key"
    ]
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = oci_core_instance.consul_1_rgn1.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "file" {
    content     = templatefile("${path.module}/scripts/consul_install_main.sh", {
      ssh_priv_key  = tls_private_key.node_to_node.private_key_pem
      consul_nodes  = local.region1_consul_ips
      consul_region = "region1",
      lb_ip         = oci_load_balancer_load_balancer.pub_rgn1.ip_addresses[0]
    })
    destination = "/tmp/install_consul.sh"
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = oci_core_instance.consul_1_rgn1.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_consul.sh",
      "/tmp/install_consul.sh",
    ]
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = oci_core_instance.consul_1_rgn1.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
}

resource "oci_core_instance" "consul_2_rgn1" {
  depends_on = [
    oci_core_instance.consul_1_rgn1
  ]
  availability_domain = data.oci_identity_availability_domains.rgn1_ads.availability_domains[0].name
  compartment_id = oci_identity_compartment.consul.id
  display_name = "consul-2"
  shape = "VM.Standard2.1"
  
  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled = false
    is_monitoring_disabled = false
    plugins_config {
      desired_state = "ENABLED"
      name = "Bastion"
    }
  }
  create_vnic_details {
    assign_private_dns_record = true
    assign_public_ip = false
    display_name = "consul-2"
    hostname_label = "consul-2"
    nsg_ids = [
      oci_core_network_security_group.consul_rgn1.id
    ]
    private_ip = local.region1_consul_ips[1]
    skip_source_dest_check = false
    subnet_id = oci_core_subnet.mgmt_rgn1.id
  }
  # shape_config {
  #   baseline_ocpu_utilization = var.instance_shape_config_baseline_ocpu_utilization
  #   memory_in_gbs = var.instance_shape_config_memory_in_gbs
  #   ocpus = var.instance_shape_config_ocpus
  # }
  metadata = {
    ssh_authorized_keys = local.ssh_pub_keys
  }
  source_details {
    source_id = local.list_images[var.compute_image_name].id
    source_type = "image"
    
    boot_volume_size_in_gbs = 50
    # kms_key_id = oci_kms_key.test_key.id
  }
  preserve_boot_volume = false
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
  
  # give the instance time to boot-up before proceeding
  provisioner "local-exec" {
    command = "echo \"Waiting for the instance to boot-up...\" && sleep 60"
  }
  
  provisioner "file" {
    content     = tls_private_key.node_to_node.private_key_pem
    destination = "/home/opc/consul.key"
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = oci_core_instance.consul_2_rgn1.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod 0600 /home/opc/consul.key",
      # credit to: https://serverfault.com/questions/132970/can-i-automatically-add-a-new-host-to-known-hosts#316100
      "ssh-keyscan -H ${local.region1_consul_ips[0]} >> ~/.ssh/known_hosts"
    ]
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = oci_core_instance.consul_2_rgn1.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "file" {
    content     = templatefile("${path.module}/scripts/consul_install_secondary.sh", {
      ssh_priv_key = tls_private_key.node_to_node.private_key_pem
      consul_nodes = local.region1_consul_ips
      consul_region = "region1"
    })
    destination = "/tmp/install_consul.sh"
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = oci_core_instance.consul_2_rgn1.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_consul.sh",
      "/tmp/install_consul.sh",
    ]
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = oci_core_instance.consul_2_rgn1.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
}

resource "oci_core_instance" "consul_3_rgn1" {
  depends_on = [
    oci_core_instance.consul_1_rgn1
  ]
  availability_domain = data.oci_identity_availability_domains.rgn1_ads.availability_domains[0].name
  compartment_id = oci_identity_compartment.consul.id
  display_name = "consul-3"
  shape = "VM.Standard2.1"
  
  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled = false
    is_monitoring_disabled = false
    plugins_config {
      desired_state = "ENABLED"
      name = "Bastion"
    }
  }
  create_vnic_details {
    assign_private_dns_record = true
    assign_public_ip = false
    display_name = "consul-3"
    hostname_label = "consul-3"
    nsg_ids = [
      oci_core_network_security_group.consul_rgn1.id
    ]
    private_ip = local.region1_consul_ips[2]
    skip_source_dest_check = false
    subnet_id = oci_core_subnet.mgmt_rgn1.id
  }
  # shape_config {
  #   baseline_ocpu_utilization = var.instance_shape_config_baseline_ocpu_utilization
  #   memory_in_gbs = var.instance_shape_config_memory_in_gbs
  #   ocpus = var.instance_shape_config_ocpus
  # }
  metadata = {
    ssh_authorized_keys = local.ssh_pub_keys
  }
  source_details {
    source_id = local.list_images[var.compute_image_name].id
    source_type = "image"
    
    boot_volume_size_in_gbs = 50
  }
  preserve_boot_volume = false
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
  
  # give the instance time to boot-up before proceeding
  provisioner "local-exec" {
    command = "echo \"Waiting for the instance to boot-up...\" && sleep 60"
  }
  
  provisioner "file" {
    content     = tls_private_key.node_to_node.private_key_pem
    destination = "/home/opc/consul.key"
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = oci_core_instance.consul_3_rgn1.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod 0600 /home/opc/consul.key",
      # credit to: https://serverfault.com/questions/132970/can-i-automatically-add-a-new-host-to-known-hosts#316100
      "ssh-keyscan -H ${local.region1_consul_ips[0]} >> ~/.ssh/known_hosts"
    ]
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = oci_core_instance.consul_3_rgn1.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "file" {
    content     = templatefile("${path.module}/scripts/consul_install_secondary.sh", {
      ssh_priv_key = tls_private_key.node_to_node.private_key_pem
      consul_nodes = local.region1_consul_ips
      consul_region = "region1"
    })
    destination = "/tmp/install_consul.sh"
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = oci_core_instance.consul_3_rgn1.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_consul.sh",
      "/tmp/install_consul.sh",
    ]
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = oci_core_instance.consul_3_rgn1.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
}


resource "oci_core_instance" "cts_rgn1" {
  depends_on = [
    oci_core_instance.consul_1_rgn1,
    oci_core_instance.consul_2_rgn1,
    oci_core_instance.consul_3_rgn1,
    oci_load_balancer_backend_set.web_rgn1
  ]
  availability_domain = data.oci_identity_availability_domains.rgn1_ads.availability_domains[0].name
  compartment_id = oci_identity_compartment.consul.id
  display_name = "cts"
  shape = "VM.Standard2.1"
  
  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled = false
    is_monitoring_disabled = false
    plugins_config {
      desired_state = "ENABLED"
      name = "Bastion"
    }
  }
  create_vnic_details {
    assign_private_dns_record = true
    assign_public_ip = false
    display_name = "cts"
    hostname_label = "cts"
    nsg_ids = [
      oci_core_network_security_group.consul_rgn1.id,
      oci_core_network_security_group.web_rgn1.id
    ]
    # private_ip = ??
    skip_source_dest_check = false
    subnet_id = oci_core_subnet.mgmt_rgn1.id
  }
  # shape_config {
  #   baseline_ocpu_utilization = var.instance_shape_config_baseline_ocpu_utilization
  #   memory_in_gbs = var.instance_shape_config_memory_in_gbs
  #   ocpus = var.instance_shape_config_ocpus
  # }
  metadata = {
    ssh_authorized_keys = local.ssh_pub_keys
  }
  source_details {
    source_id = local.list_images[var.compute_image_name].id
    source_type = "image"
    
    boot_volume_size_in_gbs = 50
  }
  preserve_boot_volume = false
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
  
  # give the instance time to boot-up before proceeding
  provisioner "local-exec" {
    command = "echo \"Waiting for the instance to boot-up...\" && sleep 60"
  }
  
  provisioner "file" {
    content     = tls_private_key.node_to_node.private_key_pem
    destination = "/home/opc/consul.key"
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = self.private_ip # oci_core_instance.client_1_rgn1.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod 0600 /home/opc/consul.key",
      # credit to: https://serverfault.com/questions/132970/can-i-automatically-add-a-new-host-to-known-hosts#316100
      "ssh-keyscan -H ${local.region1_consul_ips[0]} >> ~/.ssh/known_hosts"
    ]
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = self.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "file" {
    content     = templatefile("${path.module}/scripts/consul_client_install.sh", {
      ssh_priv_key = tls_private_key.node_to_node.private_key_pem
      consul_nodes = local.region1_consul_ips
      consul_region = "region1"
    })
    destination = "/tmp/install_consul.sh"
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = self.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "file" {
    content     = templatefile("${path.module}/scripts/cts_install.sh", {
      region = var.region_1
      lb_id = oci_load_balancer_load_balancer.pub_rgn1.id
      be_set_name = oci_load_balancer_backend_set.web_rgn1.name
      consul_nodes = local.region1_consul_ips
    })
    destination = "/tmp/install_cts.sh"
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = self.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_consul.sh",
      "/tmp/install_consul.sh",
      "chmod +x /tmp/install_cts.sh",
      "/tmp/install_cts.sh"
    ]
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = self.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
}


resource "oci_core_instance" "web_rgn1" {
  count = var.num_web_svrs
  depends_on = [
    oci_core_instance.consul_1_rgn1,
    oci_core_instance.consul_2_rgn1,
    oci_core_instance.consul_3_rgn1
  ]
  availability_domain = data.oci_identity_availability_domains.rgn1_ads.availability_domains[0].name
  compartment_id = oci_identity_compartment.consul.id
  display_name = "web-${count.index+1}"
  shape = "VM.Standard2.1"
  
  agent_config {
    are_all_plugins_disabled = false
    is_management_disabled = false
    is_monitoring_disabled = false
    plugins_config {
      desired_state = "ENABLED"
      name = "Bastion"
    }
  }
  create_vnic_details {
    assign_private_dns_record = true
    assign_public_ip = false
    display_name = "web-${count.index+1}"
    hostname_label = "web-${count.index+1}"
    nsg_ids = [
      oci_core_network_security_group.consul_rgn1.id,
      oci_core_network_security_group.web_rgn1.id
    ]
    # private_ip = ??
    skip_source_dest_check = false
    subnet_id = oci_core_subnet.app_rgn1.id
  }
  # shape_config {
  #   baseline_ocpu_utilization = var.instance_shape_config_baseline_ocpu_utilization
  #   memory_in_gbs = var.instance_shape_config_memory_in_gbs
  #   ocpus = var.instance_shape_config_ocpus
  # }
  metadata = {
    ssh_authorized_keys = local.ssh_pub_keys
  }
  source_details {
    source_id = local.list_images[var.compute_image_name].id
    source_type = "image"
    
    boot_volume_size_in_gbs = 50
    # kms_key_id = oci_kms_key.test_key.id
  }
  preserve_boot_volume = false
  
  lifecycle {
    ignore_changes = [ defined_tags["Oracle-Tags.CreatedBy"], defined_tags["Oracle-Tags.CreatedOn"] ]
  }
  defined_tags = {
    "${oci_identity_tag_namespace.devrel.name}.${oci_identity_tag.release.name}" = local.release
  }
  
  # give the instance time to boot-up before proceeding
  provisioner "local-exec" {
    command = "echo \"Waiting for the instance to boot-up...\" && sleep 60"
  }
  
  provisioner "file" {
    content     = tls_private_key.node_to_node.private_key_pem
    destination = "/home/opc/consul.key"
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = self.private_ip # oci_core_instance.client_1_rgn1.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod 0600 /home/opc/consul.key",
      # credit to: https://serverfault.com/questions/132970/can-i-automatically-add-a-new-host-to-known-hosts#316100
      "ssh-keyscan -H ${local.region1_consul_ips[0]} >> ~/.ssh/known_hosts"
    ]
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = self.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "file" {
    content     = templatefile("${path.module}/scripts/consul_client_install.sh", {
      ssh_priv_key = tls_private_key.node_to_node.private_key_pem
      consul_nodes = local.region1_consul_ips
      consul_region = "region1"
    })
    destination = "/tmp/install_consul.sh"
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = self.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "file" {
    content     = templatefile("${path.module}/scripts/apache_install.sh", {
      server_ip = self.private_ip
    })
    destination = "/tmp/apache_install.sh"
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = self.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_consul.sh",
      "/tmp/install_consul.sh",
      "chmod +x /tmp/apache_install.sh",
      "/tmp/apache_install.sh"
    ]
    
    connection {
      type     = "ssh"
      user     = "opc"
      private_key = local.ssh_priv_key
      host     = self.private_ip
      bastion_host = oci_core_instance.bastion_rgn1.public_ip
      bastion_port = 22
      bastion_user = "opc"
      bastion_private_key = local.ssh_priv_key
    }
  }
  
}

