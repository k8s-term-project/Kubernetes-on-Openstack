#!/bin/bash
scp root@211.183.3.99:/root/hosts /etc/hosts
# master node 안에 /etc/hosts이 있다는 가정하에 가능!! hosts.sh 참고

node_ip=$(cat /etc/hosts | gawk '{print $1}' | tail -n+3)
node_name=$(cat /etc/hosts | gawk '{print $2}' | tail -n+3)
node_hosts=$(cat /etc/hosts | tail -n+3)

cat /etc/hosts | gawk '{print $1}' | tail -n+3 >> /etc/ansible/hosts

# ssh 키 생성 및 설정
ssh-keygen -q -f /root/.ssh/id_rsa -N ""
chmod 600 /root/.ssh/id_rsa
echo "HOST 172.16.1.*" >> /etc/ssh/ssh_config
echo "        User root" >> /etc/ssh/ssh_config
echo "        IdentityFile /root/.ssh/id_rsa" >> /etc/ssh/ssh_config

# ssh authorized_keys 설정
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
for worker_ip_num in $(cat /etc/hosts | grep worker | gawk '{print $1}')
do
    ssh root@${worker_ip_num} mkdir /root/.ssh ; touch /root/.ssh/authorized_keys
    scp /root/.ssh/id_rsa.pub root@${worker_ip_num}:/root/.ssh/authorized_keys
done

# ssh-keyscan 설정
for all_ip_num in $node_ip
do
    ssh-keyscan ${all_ip_num} >> /root/.ssh/known_hosts
done

cp -rfp /usr/src/kubespray/inventory/sample /usr/src/kubespray/inventory/first_cluster
cat /dev/null > /usr/src/kubespray/inventory/first_cluster/inventory.ini

echo [all] >> /usr/src/kubespray/inventory/first_cluster/inventory.ini
for list in ${node_name}
do
echo "${list}    ansible_host=$(cat /etc/hosts | grep ${list} | gawk '{print $1}')    ip=$(cat /etc/hosts | grep ${list} | gawk '{print $1}')" >> /usr/src/kubespray/inventory/first_cluster/inventory.ini
done
echo "" >> /usr/src/kubespray/inventory/first_cluster/inventory.ini

echo [kube_control_plane] >> /usr/src/kubespray/inventory/first_cluster/inventory.ini
cat /etc/hosts | grep master | gawk '{print $2}' >> /usr/src/kubespray/inventory/first_cluster/inventory.ini
echo "" >> /usr/src/kubespray/inventory/first_cluster/inventory.ini

echo [etcd] >> /usr/src/kubespray/inventory/first_cluster/inventory.ini
cat /etc/hosts | grep master | gawk '{print $2}' >> /usr/src/kubespray/inventory/first_cluster/inventory.ini
echo "" >> /usr/src/kubespray/inventory/first_cluster/inventory.ini

echo [kube_node] >> /usr/src/kubespray/inventory/first_cluster/inventory.ini
cat /etc/hosts | grep worker | gawk '{print $2}' >> /usr/src/kubespray/inventory/first_cluster/inventory.ini
echo "" >> /usr/src/kubespray/inventory/first_cluster/inventory.ini

echo [k8s_cluster:children] >> /usr/src/kubespray/inventory/first_cluster/inventory.ini
echo kube_control_plane >> /usr/src/kubespray/inventory/first_cluster/inventory.ini
echo kube_node >> /usr/src/kubespray/inventory/first_cluster/inventory.ini
echo calico_rr >> /usr/src/kubespray/inventory/first_cluster/inventory.ini


ansible-playbook -i /usr/src/kubespray/inventory/first_cluster/inventory.ini 
-become --become-user=root /usr/src/kubespray/cluster.yml 
--private-key /root/.ssh/id_rsa
