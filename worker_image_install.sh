#!/bin/bash

# 기본
echo "centos ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
yum clean all
yum -y update
sudo yum -y install vim curl wget
swapoff -a
echo 1 > /proc/sys/net/ipv4/ip_forward
sudo yum -y update
sudo yum -y install git
sudo yum install python3-pip -y
