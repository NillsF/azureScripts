###
#This file contains a shell script to setup Ubuntu to install docker, kubectl and the azure cli
###

sudo apt-get update
#install docker
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io
#install kubectl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
#install az-cli
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
#install helm
curl -L https://git.io/get_helm.sh | bash
###
#To verify installation, do the following steps
###
###
#verify if docker works correctly
#sudo service docker start
#sudo docker run hello-world
###
#verify if kubectl works
#kubectl get nodes
#output should be:The connection to the server localhost:8080 was refused - did you specify the right host or port?
###
#verify if az-cli works
#az login
###
#helm cannot be verified, as you need a cluster first
