# Copyright (c) 2021 Oracle and/or its affiliates.

sudo yum install -y httpd
sudo systemctl enable --now httpd.service
sudo systemctl start httpd.service
sudo firewall-cmd --zone=public --add-port=80/tcp
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent

sudo sh -c "cat >> /var/www/html/index.html <<'EOF'
<html>
  <head>
    <title>`hostname`</title>
  </head>
  <body>
    <h1>Welcome!</h1>
    <h5>You're talking to node `hostname`.</h5>
  </body>
</html>
EOF"

# register the service with Consul
sudo sh -c "cat >> /etc/consul.d/web.json <<'EOF'
{
  \"service\": {
    \"id\": \"web\",
    \"name\": \"web\",
    \"tags\": [\"apache\"],
    \"port\": 80
  }
}
EOF"
sudo chown consul:consul /etc/consul.d/web.json
sudo systemctl restart consul
