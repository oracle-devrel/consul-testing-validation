# Copyright (c) 2021 Oracle and/or its affiliates.

scp -i ~/consul.key opc@${consul_nodes[0]}:/tmp/consul_bootstrap /tmp/consul_bootstrap
export CONSUL_MGMT_TOKEN="`awk '/^SecretID:.*$/{print $2}' /tmp/consul_bootstrap`"

# install binary
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install consul-terraform-sync terraform git

sudo mkdir /etc/consul-cts.d
sudo chown opc:opc /etc/consul-cts.d/

# /etc/consul.d/consul.hcl
cat >> /etc/consul-cts.d/cts.hcl <<'EOF'
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
  path = "/etc/consul-cts.d/"
  log = false
  persist_log = false

  backend "consul" {
    gzip = true
  }
  # backend "local" {}
}

working_dir = "/etc/consul-cts.d/"

task {
  name        = "web"
  description = "CTS on OCI example"
  source      = "oracle-devrel/cts-example/oci"
  version     = "0.1.2"
  services    = ["web"]
  variable_files = [
    "/etc/consul-cts.d/web.tfvars"
  ]
}

EOF

cat >> /etc/consul-cts.d/web.tfvars <<'EOF'
region = "${region}"
lb_id = "${lb_id}"
be_set_name = "${be_set_name}"
EOF

cat > /etc/consul-cts.d/cts-policy.hcl <<EOF
// Consul KV backend default prefix for state files
key_prefix "consul-terraform-sync/" {
  policy = "write"
}

session_prefix "" {
  policy = "write"
}
EOF

cd /etc/consul-cts.d
consul acl policy create \
  -token=$${CONSUL_MGMT_TOKEN} \
  -name cts-policy \
  -rules @cts-policy.hcl

touch /usr/lib/systemd/system/consul-cts.service
sudo sh -c "cat >> /usr/lib/systemd/system/consul-cts.service <<'EOF'
[Unit]
Description=\"Consul Terraform Sync\"
Documentation=https://www.consul.io/
Requires=network-online.target
After=network-online.target
ConditionFileNotEmpty=/etc/consul-cts.d/cts.hcl

[Service]
Type=exec
User=opc
Group=opc
ExecStart=/usr/bin/consul-terraform-sync -config-file /etc/consul-cts.d/cts.hcl
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
KillSignal=SIGTERM
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF"

sudo systemctl enable consul-cts.service
sudo systemctl start consul-cts
