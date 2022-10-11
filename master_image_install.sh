#!/bin/bash

# 기본
echo "centos ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "root ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
yum clean all
yum -y update
sudo yum -y install vim curl wget
swapoff -a
echo 1 > /proc/sys/net/ipv4/ip_forward
sudo yum -y update

#kubepry + ansible
sudo yum -y install git
cd /usr/src ; git clone https://github.com/kubernetes-sigs/kubespray.git ; cd /usr/src/kubespray ;  git checkout v2.16.0
sudo yum install python3-pip -y
sudo pip3 install -r /usr/src/kubespray/requirements.txt
