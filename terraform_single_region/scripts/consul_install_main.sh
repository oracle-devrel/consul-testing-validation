# Copyright (c) 2021 Oracle and/or its affiliates.

# install binary
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum -y install consul

# key should be generated and provided to TF script
consul keygen > /tmp/consul_keygen

# crypto keys
consul tls ca create
consul tls cert create -server -dc region1
consul tls cert create -client -dc region1
sudo cp *.pem /etc/consul.d
sudo chown consul:consul /etc/consul.d/*.pem
# scp consul-agent-ca.pem region1-<server/client>-consul-<cert-number>.pem <dc-name>-<server/client>-consul-<cert-number>-key.pem <USER>@<PUBLIC_IP>:/etc/consul.d/

# /etc/consul.d/consul.hcl
sudo sh -c "cat >> /etc/consul.d/consul.hcl <<'EOF'
bootstrap_expect = 1
client_addr = \"0.0.0.0\"
datacenter = \"${consul_region}\"
domain = \"consul\"
enable_script_checks = true
enable_syslog = true
encrypt = \"`cat /tmp/consul_keygen`\"
leave_on_terminate = true
log_level = \"INFO\"
rejoin_after_leave = true
server = true
start_join = [
  %{ for ip in consul_nodes ~}
  \"${ip}\",
  %{ endfor ~}
]
ui = true
ca_file = \"/etc/consul.d/consul-agent-ca.pem\"
cert_file = \"/etc/consul.d/region1-server-consul-0.pem\"
key_file = \"/etc/consul.d/region1-server-consul-0-key.pem\"
retry_join = [
  %{ for ip in consul_nodes ~}
  \"${ip}\",
  %{ endfor ~}
]
performance {
  raft_multiplier = 1
}
acl = {
  enabled = true
  default_policy = \"allow\"
  enable_token_persistence = true
}
verify_incoming = true
verify_outgoing = true
verify_server_hostname = true
EOF"

sudo systemctl start consul

sleep 30

export CONSUL_CACERT=/etc/consul.d/consul-agent-ca.pem
export CONSUL_CLIENT_CERT=/etc/consul.d/region1-client-consul-0.pem
export CONSUL_CLIENT_KEY=/etc/consul.d/region1-client-consul-0-key.pem

# note that until the cluster is up, the bootstrap_expect must be set to 1 (otherwise it'll fail)
consul acl bootstrap > /tmp/consul_bootstrap

export CONSUL_HTTP_TOKEN="`awk '/^SecretID:.*$/{print $2}' /tmp/consul_bootstrap`"
export CONSUL_MGMT_TOKEN="`awk '/^SecretID:.*$/{print $2}' /tmp/consul_bootstrap`"

# node-policy.hcl
cat > node-policy.hcl <<EOF
agent_prefix "" {
  policy = "write"
}
node_prefix "" {
  policy = "write"
}
service_prefix "" {
  policy = "read"
}
session_prefix "" {
  policy = "read"
}
EOF

consul acl policy create \
  -token=$${CONSUL_MGMT_TOKEN} \
  -name node-policy \
  -rules @node-policy.hcl

consul acl token create \
  -token=$${CONSUL_MGMT_TOKEN} \
  -description "node token" \
  -policy-name node-policy > /tmp/consul_acl_token

consul acl set-agent-token \
  -token="`awk '/^SecretID:.*$/{print $2}' /tmp/consul_bootstrap`" \
  agent "`awk '/^SecretID:.*$/{print $2}' /tmp/consul_acl_token`"

# setup the host-based firewall
sudo firewall-cmd --zone=public --add-port=8300/tcp
sudo firewall-cmd --zone=public --add-port=8300/tcp --permanent
sudo firewall-cmd --zone=public --add-port=8301/tcp
sudo firewall-cmd --zone=public --add-port=8301/tcp --permanent
sudo firewall-cmd --zone=public --add-port=8301/udp
sudo firewall-cmd --zone=public --add-port=8301/udp --permanent
sudo firewall-cmd --zone=public --add-port=8302/tcp
sudo firewall-cmd --zone=public --add-port=8302/tcp --permanent
sudo firewall-cmd --zone=public --add-port=8302/udp
sudo firewall-cmd --zone=public --add-port=8302/udp --permanent
sudo firewall-cmd --zone=public --add-port=8500/tcp
sudo firewall-cmd --zone=public --add-port=8500/tcp --permanent
sudo firewall-cmd --zone=public --add-port=8600/udp
sudo firewall-cmd --zone=public --add-port=8600/udp --permanent

# register the LB version of the service with Consul
sudo sh -c "cat >> /etc/consul.d/lb.json <<'EOF'
{
  \"service\": {
    \"id\": \"lb\",
    \"name\": \"lb\",
    \"tags\": [\"lb-apache\"],
    \"address\": \"${lb_ip}\",
    \"port\": 80,
    \"weights\": {
      \"passing\": 5,
      \"warning\": 1
    }
  }
}
EOF"
sudo chown consul:consul /etc/consul.d/lb.json
sudo systemctl restart consul
