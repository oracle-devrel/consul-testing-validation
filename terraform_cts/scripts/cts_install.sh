# Copyright (c) 2021 Oracle and/or its affiliates.

# install binary
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install consul-terraform-sync terraform git

# /etc/consul.d/consul.hcl
cat >> /home/opc/cts.hcl <<'EOF'
port = 8558

syslog {}

buffer_period {
  enabled = true
  min = "5s"
  max = "20s"
}

consul {
  address = "localhost:8500"
}

driver "terraform" {
  # version = "0.14.0"
  # path = ""
  log = false
  persist_log = false

  backend "consul" {
    gzip = true
  }
}

working_dir = ""

task {
  name        = "web"
  description = "CTS on OCI example"
  source      = "oracle-devrel/cts-example/oci"
  version     = "0.1.1"
  services    = ["web"]
  variable_files = [
    "/home/opc/web.tfvars"
  ]
}

EOF

cat >> /home/opc/web.tfvars <<'EOF'
region = "${region}"
lb_id = "${lb_id}"
be_set_name = "${be_set_name}"
EOF

consul-terraform-sync -config-file cts.hcl &