# Copyright (c) 2021 Oracle and/or its affiliates.

# used for SSH between Consul nodes
resource "tls_private_key" "node_to_node" {
  algorithm   = "RSA"
}
