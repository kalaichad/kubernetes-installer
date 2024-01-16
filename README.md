# kubernetes-installer

kubernetes v1.29 installer on **Ubuntu22.04**
kubeadm-config yaml file need to mention the pod network range or you can leave it default.

![image](https://github.com/kalaichad/kubernetes-installer/assets/92660146/93c80669-7e23-4f1c-a1b4-bf467260dd9c)

if there is any issue on this script mention the issue in github.

Execute the **kubernetes.sh** script on master and worker nodes. 

Specify the which is master and worker in prompt.

Execute the **master.sh** script execute on master node and it will give worker join token. 
