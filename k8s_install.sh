#!/bin/bash

# master node 안에 /root/hosts이 있다는 가정하에 가능!! hosts.sh 참고

node_ip=$(cat /root/hosts | gawk '{print $1}' | tail -n+3)
node_name=$(cat /root/hosts | gawk '{print $2}' | tail -n+3)
node_hosts=$(cat /root/hosts | tail -n+3)

echo "root ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

cat /dev/null > /etc/hosts
cat /root/hosts > /etc/hosts
cat /root/hosts | gawk '{print $1}' | tail -n+3 >> /etc/ansible/hosts

# ssh 키 생성 및 설정
ssh-keygen -q -f /root/.ssh/id_rsa -N ""
chmod 600 /root/.ssh/id_rsa
echo "HOST 172.16.1.*" >> /etc/ssh/ssh_config
echo "        User root" >> /etc/ssh/ssh_config
echo "        IdentityFile /root/.ssh/id_rsa" >> /etc/ssh/ssh_config

# ssh authorized_keys 설정
cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys
for worker_ip_num in $(cat /root/hosts | grep worker | gawk '{print $1}')
do
    ssh root@${worker_ip_num} mkdir /root/.ssh ; touch /root/.ssh/authorized_keys
    scp /root/.ssh/authorized_keys root@${worker_ip_num}:/root/.ssh/authorized_keys
done

# ssh-keyscan 설정
for all_ip_num in $node_ip
do
    ssh-keyscan ${all_ip_num} >> /root/.ssh/known_hosts
done

cd /usr/local/src
git clone https://github.com/kubernetes-sigs/kubespray.git
cd /usr/local/src/kubespray
pip3 install -r requirements.txt
cp -rfp inventory/sample inventory/first_cluster
cat /dev/null > /usr/local/src/kubespray/inventory/first_cluster/inventory.ini

echo [all] >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini
for list in ${node_name}
do
echo "${list}    ansible_host=$(cat /root/hosts | grep ${list} | gawk '{print $1}')    ip=$(cat /root/hosts | grep ${list} | gawk '{print $1}')" >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini
done
echo "" >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini

echo [kube_control_plane] >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini
cat /root/hosts | grep master | gawk '{print $2}' >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini
echo "" >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini

echo [etcd] >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini
cat /root/hosts | grep master | gawk '{print $2}' >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini
echo "" >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini

echo [kube_node] >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini
cat /root/hosts | grep worker | gawk '{print $2}' >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini
echo "" >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini

echo [k8s_cluster:children] >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini
echo kube_control_plane >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini
echo kube_node >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini
echo calico_rr >> /usr/local/src/kubespray/inventory/first_cluster/inventory.ini


ansible-playbook -i /usr/local/src/kubespray/inventory/first_cluster/inventory.ini -become --become-user=root /usr/local/src/kubespray/cluster.yml --private-key /root/.ssh/id_rsa
