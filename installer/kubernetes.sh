#!/bin/bash
echo -e "\n KUBERNETES INSTALLER \n" | tee -a info.log

echo -e "NOTE: This script is installing the kubernetes and dependency packages also installing.\n
if already installed the kubernertes or not properly installed means it will make conflicts.\n
So make install the script in freash machine."
sleep 10

echo "Machine Type \n
master (or) worker" | tee -a info.log

function input_data {
read -p "Enter Machine TYPE " mtype
${mtype} == "master" || ${mtype} == "worker" || echo "Give the vaild input 'master' (or) 'worker'" | tee -a info.log || input_data
}
input_data
echo "Entered option ${mtype}" | tee -a info.log
echo "PREREQUEST CHECKING." | tee -a info.log
if ! ping -c 2 8.8.8.8 &> /dev/null
then
	echo "Please Connect the INTERNET.\
 After execute the script." | tee -a info.log 
	exit 1
fi
if [ "x86_64" != $(arch) ]
then
	echo "This $(arch) type is not supported."
	exit 1
fi
if [ $(grep -E 'NAME="Ubuntu"|VERSION_ID="22.04"' /etc/os-release -c) -ne 2 ]
then
        echo "OS must be Ubuntu and version 22.04\
only can able to install the latest kube." | tee -a info.log
        exit 1
fi
if [ $(whoami) != "root" ] || [ $(sudo whoami) != "root" ] || [ $(sudo id -u) -ne 0 ]
then
	echo "Need to run root privilage."
	exit 1
fi

apt update >> info.log 2>&1
apt install apt-transport-https &>> info.log
#disable SWAP in fstab (Kubeadm requirement)
swapoff -a >> info.log 2>&1
sed -i '/swap/s/^/#/' /etc/fstab &>> info.log
#configure modules for Containerd
contain="/etc/modules-load.d/containerd.conf"
touch ${contain} >> info.log 2>&1
if ! grep -i "overlay" ${contain} >> info.log 2>&1 &&  grep -i "br_netfilter" ${contain} >> info.log 2>&1
then
	echo -e "overlay\nbr_netfilter" >> ${contain}
fi

#configure sysctl params for Kubernetes
kube="/etc/sysctl.d/99-kubernetes-cri.conf"
touch ${kube}
echo -e "net.bridge.bridge-nf-call-iptables  = 1\n\
net.ipv4.ip_forward                 = 1\nnet.bridge.bridge-nf-call-ip6tables = 1" > ${kube}
#sysctl params without reboot
sysctl --system >> info.log

#add Docker apt-key
curl https://download.docker.com/linux/ubuntu/gpg > /etc/apt/keyrings/docker-apt-keyring.asc
#add Docker's APT repository
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker-apt-keyring.asc]\
 https://download.docker.com/linux/ubuntu jammy  stable" > /etc/apt/sources.list.d/docker.list

#kube repo key
curl https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key > /etc/apt/keyrings/kubernetes-apt-keyring.asc
#add Kubernetes' APT repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.asc]\
 https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" > /etc/apt/sources.list.d/kubernetes.list

echo "Install the container" >> info.log
apt install containerd.io -y &>> info.log
mkdir /etc/containerd &>> info.log
/usr/bin/containerd config default > /etc/containerd/config.toml 2> /dev/null
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
systemctl enable containerd
systemctl restart containerd &>> info.log
if [ ${?} -ne 0 ]
then
	echo "containerd service issue to restarting" | tee -a info.log
fi
systemctl daemon-reload >> info.log
apt install kubelet=1.29.* kubeadm=1.29.* -y &>> info.log
systemctl start --now kubelet &>> info.log
modprobe br_netfilter &>> info.log || echo "br_netfilter module can't load into kernel" | tee -a info.log

if [ ${mtype} == "master" ]
then
	apt install kubectl=1.29.* -y &>> info.log
	if [ -d /etc/kubernetes ]
	then
		touch /etc/kubernetes/kubeadm-config.yaml

	fi
fi
echo "IF there is any issue on the script. Please drop the issue on github page"
