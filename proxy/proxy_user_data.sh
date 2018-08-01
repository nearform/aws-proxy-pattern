#!/bin/bash
set -x

# Install latest Docker
apt update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
apt update
apt install -y docker-ce

# Create squid configuration
mkdir /etc/squid
cat | tee /etc/squid/squid.conf <<EOF
visible_hostname squid

#Handling HTTP requests
http_port 3129 intercept
acl allowed_http_sites dstdomain .amazonaws.com
acl allowed_http_sites dstdomain .security.ubuntu.com
http_access allow allowed_http_sites

#Handling HTTPS requests
https_port 3130 cert=/etc/squid/ssl/squid.pem ssl-bump intercept
acl SSL_port port 443
http_access allow SSL_port
acl allowed_https_sites ssl::server_name .amazonaws.com
acl allowed_https_sites ssl::server_name .badssl.com
acl allowed_https_sites ssl::server_name .security.ubuntu.com
acl step1 at_step SslBump1
acl step2 at_step SslBump2
acl step3 at_step SslBump3
ssl_bump peek step1 all
ssl_bump peek step2 allowed_https_sites
ssl_bump splice step3 allowed_https_sites
ssl_bump terminate step3 all

http_access deny all
EOF

# Create certificates for SSL peek
mkdir /etc/squid/ssl && cd /etc/squid/ssl
openssl genrsa -out squid.key 2048
openssl req -new -key squid.key -out squid.csr -subj "/C=XX/ST=XX/L=squid/O=squid/CN=squid"
openssl x509 -req -days 3650 -in squid.csr -signkey squid.key -out squid.crt
cat squid.key squid.crt | tee squid.pem

# Allow access to uid 31 (squid in container, unknown on host) to /var/log/squid/
mkdir /var/log/squid
chown 31:31 /var/log/squid/
chmod u+rwx /var/log/squid/

# Pull squid image and run using config and cert setup above
docker pull karlhopkinsonturrell/squid-alpine
docker run -it -d --net host \
    --mount type=bind,src=/etc/squid/squid.conf,dst=/etc/squid/squid.conf \
    --mount type=bind,src=/etc/squid/ssl,dst=/etc/squid/ssl \
    --mount type=bind,src=/var/log/squid/,dst=/var/log/squid/ \
    karlhopkinsonturrell/squid-alpine

# Route inbound traffic into squid
iptables -t nat -I PREROUTING 1 -s 10.0.2.0/24 -p tcp --dport 80 -j REDIRECT --to-port 3129
iptables -t nat -I PREROUTING 1 -s 10.0.2.0/24 -p tcp --dport 443 -j REDIRECT --to-port 3130

