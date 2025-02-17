# !/bin/bash

################################################################
###   ====================================================   ###   
######    <( *.* <) Arbitrum Sepolia Docker  (> *.* )>    ###### 
####  ====================================================  ####
################################################################

#############################################
############ !! IMPORTANT !! ################
#                                           #
# THIS SCRIPT ASSUMES YOU HAVE ROOT ACCESS. #
# IF YOU DO NOT HAVE ROOT ACCESS...         #
# MODIFYYYY........                         #
#############################################

#################
# Update System #
#################
sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y

###########################################
# Install Docker & Docker-Compose #
###########################################
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

######################
# Set Firewall Rules #
######################
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 8547 && sudo ufw allow 9642
sudo ufw enable

####################
# Create Directory #
####################
mkdir -p /root/arbitrum
cd /root/arbitrum

#############################
# Create docker-compose.yml #
#############################
# From within /root/arbitrum run the below.
echo "services:
  arbitrum:
    image: offchainlabs/nitro-node:v3.4.0-d896e9c
    container_name: arbitrum
    restart: unless-stopped
    volumes:
      -  /root/arbitrum:/root/arbitrum/.arbitrum
    ports:
      -  "8547:8547"
      -  "9642:9642"
      -  "8548:8548"
    command:
      -  --init.latest=archive
      -  --parent-chain.connection.url=https://rpc-sepolia.rockx.com
      -  --parent-chain.blob-client.beacon-url=https://lodestar-sepolia.chainsafe.io
      -  --chain.id=421614
      -  --http.api=net,web3,eth
      -  --http.corsdomain=*
      -  --http.addr=0.0.0.0
      -  --http.vhosts=*
" > docker-compose.yml

####################
# Run Archive Node #
####################
docker compose up -d