#!/bin/bash

touch /root/hosts
echo "127.0.0.1   localhost" >> /root/hosts
echo "::1         localhost" >> /root/hosts

master_node_ip=$(openstack server list | grep master | grep project-network | gawk '{print $8}' | cut -d "=" -f2 | cut -d "," -f1)
worker_node_ip=$(openstack server list | grep node | grep project-network | gawk '{print $8}' | cut -d "=" -f2 | cut -d "," -f1)


for node_ip in $master_node_ip
do
    echo "$node_ip    $(openstack server list | grep $node_ip | gawk '{print $4}')" >> /root/hosts
done


for node_ip in $worker_node_ip
do
    echo "$node_ip    $(openstack server list | grep $node_ip | gawk '{print $4}')" >> /root/hosts
done

chmod 777 ~/hosts
