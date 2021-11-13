# Infrastructure

## Howto setup a new host

- ensure SSH login with root and public key to the host is possible
- add docker host to /etc/ansible/hosts, once with VPN and once without
- ansible-playbook playbooks/dockerhost-setup.yaml
- switch to a docker context for the server
- make data-init
- on docker host: systemctl start infrastructure-network
- configure and start VPN on local machine
- make deploy-update