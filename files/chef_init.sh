#!/bin/bash

# LOG OUTPUT TO A FILE
exec 3>&1 4>&2
trap 'exec 2>&4 1>&3' 0 1 2 3
exec 1>/root/.chef_automate/log.out 2>&1

if [[ ! -f "/root/.chef_automate/init.cfg" ]]
then
  # copy chef server.crt
  cp /root/.chef_automate/server.crt /etc/chef/trusted_certs
  # copy chef server.pem
  cp /root/.chef_automate/server.pem /etc/chef/
  # install chef client
  cd /etc/chef/
  curl -L https://omnitruck.chef.io/install.sh | bash || error_exit 'could not install chef'
  # Create first-boot.json
  cat > "/etc/chef/first-boot.json" << EOF
{
   "run_list" :[
   "role[base]"
   ]
}
EOF

  NODE_NAME=$( hostname )
  # Create client.rb
  /bin/echo 'log_location     STDOUT' >> /etc/chef/client.rb
  /bin/echo -e "chef_server_url  \"https://chefsrv000.management.skyfall.io/organizations/ORGNAME\"" >> /etc/chef/client.rb
  /bin/echo -e "chef_license \"accept\"" >> /etc/chef/client.rb
  /bin/echo -e "validation_client_name \"ORGNAME-validator\"" >> /etc/chef/client.rb
  /bin/echo -e "validation_key \"/etc/chef/server.pem\"" >> /etc/chef/client.rb
  /bin/echo -e "node_name  \"${NODE_NAME}\"" >> /etc/chef/client.rb
  # bootstrap chef client
  chef-client -j /etc/chef/first-boot.json --environment $( hostname |cut -d. -f2 )
  # Idempotentcy
  touch /root/.chef_automate/init.cfg
fi
