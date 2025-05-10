#!/bin/sh

#update dnf
sudo dnf update -y

#install podman
sudo dnf install -y container-tools

#install oci CLI
sudo dnf -y install oraclelinux-developer-release-el9
sudo dnf -y install python39-oci-cli


#allow 443 and 80
sudo firewall-cmd --zone=public --add-port=443/tcp --permanent
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --reload 

