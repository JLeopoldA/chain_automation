# !/bin/bash

########################################################
###   ============================================   ###   
######    <( *.* <) Rootstock Docker (> *.* )>    ###### 
####  ============================================  ####
########################################################

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
apt update -y && apt upgrade -y && apt autoremove -y

##########################
# Firewall Configuration #
##########################
sudo ufw default deny incoming && sudo default allow outgoing
sudo ufw allow 80 && sudo ufw allow 443
sudo ufw allow 4444
sudo ufw enable

###################################
# Install Docker & Docker Compose #
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

####################
# Create Directory #
####################
mkdir -p /root/rootstock
cd /root/rootstock

#############################
# Create Configuration File #
#############################
echo "blockchain.config.name = "main"

database.dir = /var/lib/rsk/database/mainnet

rpc {
providers : {
    web: {
        cors: "localhost",
        http: {
            enabled: true,
            bind_address = "0.0.0.0",
            hosts = ["localhost"]
            port: 4444,
            }
        ws: {
            enabled: false,
            bind_address: "0.0.0.0",
            port: 4445,
            }
        }
    }

    modules = [
        {
            name: "eth",
            version: "1.0",
            enabled: "true",
        },
        {
            name: "net",
            version: "1.0",
            enabled: "true",
        },
        {
            name: "rpc",
            version: "1.0",
            enabled: "true",
        },
        {
            name: "web3",
            version: "1.0",
            enabled: "true",
        },
        {
            name: "evm",
            version: "1.0",
            enabled: "true"
        },
        {
            name: "sco",
            version: "1.0",
            enabled: "false",
        },
        {
            name: "txpool",
            version: "1.0",
            enabled: "true",
        },
        {
            name: "debug",
            version: "1.0",
            enabled: "false",
        },        
        {
            name: "personal",
            version: "1.0",
            enabled: "true"
        }
    ]
}" > node.conf

#############################
# Create docker-compose.yml #
#############################
echo "services:
  rsk-node:
    image: rsksmart/rskj:ARROWHEAD-6.3.1
    container_name: rsk-node
    ports:
      - 5050:5050
      - 4444:4444
    volumes:
      - rsk-data:/var/lib/rsk/.rsk
      - ./node.conf:/etc/rsk/node.conf
    restart: unless-stopped
volumes:
  rsk-data:  " > docker-compose.yml

#################
# Run Rootstock #
#################
docker compose up -d

###################
# Query Rootstock #
###################
echo "================================================================="
echo "To query your node for the most recent block: "
echo "curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:4444"
echo "================================================================="
echo "To check the sync status of your node: "
echo "curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0", "method":"eth_syncing", "params":[], "id":1}' http://localhost:4444"
