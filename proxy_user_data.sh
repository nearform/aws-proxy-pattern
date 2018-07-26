#!/bin/bash
set -x

# Install puppet5
wget https://apt.puppetlabs.com/puppet5-release-xenial.deb
dpkg -i puppet5-release-xenial.deb
apt update
apt install -y puppet-agent
export PATH=$PATH:/opt/puppetlabs/bin

# Install the squid proxy module
puppet module install puppet-squid --version 1.1.0

# Setup the site manifest with the correct proxy config
cat | tee /etc/puppetlabs/code/environments/production/manifests/site.pp <<EOF
node default {
   class { 'squid':
      acls => {
         'forwarded_ports' => {
            type => port,
            entries => ['80', '443']
         },
      },
      http_access => {
         'forwarded_ports' => { action => 'allow' }
      },
      http_ports => { '3129' => { options => 'intercept' } },
      https_ports => { '3130' => {} },
   }
}
EOF

# Apply puppet manifest to start squid proxy
/opt/puppetlabs/bin/puppet apply \
    /etc/puppetlabs/code/environments/production/manifests \
    --logdest syslog

# Send inbound traffic into the port the squid proxy is listening on
iptables -t nat -A PREROUTING -s 10.0.2.0/24 -p tcp --dport 80 -j REDIRECT --to-port 3129
