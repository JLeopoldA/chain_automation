# !/bin/bash

#############################################
###   =================================   ###   
######    <( *.* <) Fuse  (> *.* )>    ###### 
####  =================================  ####
#############################################

#############################################
############ !! IMPORTANT !! ################
#                                           #
# THIS SCRIPT ASSUMES YOU HAVE ROOT ACCESS. #
# IF YOU DO NOT HAVE ROOT ACCESS...         #
# MODIFYYYY........                         #
#############################################

###########################################################
# !!!!!THIS SCRIPT EXPECTS A NAME FOR YOUR NODE KEY !!!!! #
#             >> PASS ONE IN AS A PARAMETER <<            #
###########################################################
node_key="$1"
if [ -n "$node_key" ]; then
    echo "This script requires you to name your node key. Supply one as a parameter"
    echo "Example: "
    echo "./fuse_docker.sh <node_key>"
    exit 1
fi

#################
# Update System #
#################
apt update -y && apt upgrade -y && apt autoremove -y

###################################
# Install Docker & Docker-Compose #
###################################
sudo apt-get update
sudo apt-get install ca-certificates curl 
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update​ 
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

##########################
# Firewall Configuration #
##########################
sudo ufw default deny incoming && sudo ufw default deny outgoing
sudo ufw allow 22/tcp && sudo ufw allow 8545

####################
# Clone Repository #
####################
git clone https://github.com/fuseio/fuse-network.git /root/fuse-network
cd /root/fuse-network

#######################
# Download Quickstart #
#######################
wget -O quickstart.sh https://raw.githubusercontent.com/fuseio/fuse-network/master/nethermind/quickstart.sh
chmod 755 quickstart.sh
./quickstart.sh -r explorer -n fuse -k "$node_key"

###########################
# View Logs for Debugging #
###########################
echo "================================================================="
echo "To query your node: "
echo "curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545"
