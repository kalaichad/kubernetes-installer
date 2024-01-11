#!/usr/bin/bash
current_path=$(pwd)
echo -e "\n This script must be excute on Master node only\n" | tee -a info.log
function input_check {
read -p "Press Enter to continue ? "
if [ ! -z ${REPLY} ]
then
	echo "press ENTER continue the script."
	input_check
fi
}
input_check
if [ ! -s ${current_path}/kubeadm-config.yaml ]
then
	echo "kubeadm-config.yaml not avilable in current path." | tee -a info.log
	exit 1
else
	cp ${current_path}/kubeadm-config.yaml /etc/kubernetes/kubeadm-config.yaml | tee -a info.log
fi
echo -e "INITIALIZE the cluster on master node (this could take some time)" | tee -a info.log
kubeadm init --config /etc/kubernetes/kubeadm-config.yaml >> cluster_initialized.log
if [ ${?} -ne 0 ]
then
	echo "kubeadm initialize issue occured. Please check logs" | tee -a info.log
else
	mkdir $HOME/.kube | tee -a info.log
	cp /etc/kubernetes/admin.conf $HOME/.kube/
fi
echo "Install pod network" | tee -a info.log
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml >> pod_network_setup.log
if [ ${?} -eq 0 ]
then
	echo -e "POD network successfully deployed.\n" | tee -a info.log
	kubeadm token create --print-join-command 
	echo -e "\n above mentioned output of kubeadm token only execute on worker nodes only.\n
Join the worker node to master node"
fi

echo "IF there is any issue on the script. Please drop the issue on github page"
