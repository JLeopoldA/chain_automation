# !/bin/bash

################################################################
###   ====================================================   ###   
######    <( *.* <) Ethereum Sepolia Docker  (> *.* )>    ###### 
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
apt update -y && apt upgrade -y && apt autoremove -y

################
# Set Firewall #
################
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow 22/tcp 
sudo ufw allow 8545 && sudo ufw allow 8546 
sudo ufw allow 30303/tcp && sudo ufw allow 30303/udp
sudo ufw allow 8551/tcp
sudo ufw allow 13000/tcp
sudo ufw allow 12000/udp
sudo ufw allow 4000
sudo ufw enable

###########################################
# Installation of Docker & Docker-Compose #
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

####################
# Create Directory #
####################
mkdir -p /root/sepolia

##################
# Create jwt.hex #
##################
openssl rand -hex 32 | tr -d "\n" > /root/sepolia/jwt.hex

#############################
# Create docker-compose.yml #
#############################
cd /root/sepolia
echo "services:
  beacon-node:
    image: gcr.io/prysmaticlabs/prysm/beacon-chain:stable
    container_name: beacon-node
    restart: unless-stopped
    volumes:
      - $HOME/.eth2:/data
      - /root/sepolia/jwt.hex:/root/sepolia/jwt.hex:ro
    ports:
      - "4000:4000"
      - "13000:13000"
      - "12000:12000/udp"
    command:
      - --datadir=/data
      - --jwt-secret=/root/sepolia/jwt.hex
      - --rpc-host=0.0.0.0
      - --http-host=0.0.0.0
      - --monitoring-host=0.0.0.0
      - --execution-endpoint=http://geth:8551
      - --sepolia
      - --checkpoint-sync-url=https://sepolia.beaconstate.info
      - --genesis-beacon-api-url=https://beaconstate.info
    networks:
      -  blockchain-network

  geth:
    image: ethereum/client-go:stable
    restart: unless-stopped
    volumes:
      - ./data:/root/.ethereum
      - /root/sepolia/jwt.hex:/root/sepolia/jwt.hex:ro
    ports:
      - "8545:8545"
      - "8546:8546"
      - "8551:8551"
      - "30303:30303"
    command: [
      "--sepolia",
      "--syncmode=full",
      "--gcmode=archive",
      "--authrpc.addr=0.0.0.0",
      "--authrpc.port=8551",
      "--authrpc.vhosts=*",
      "--authrpc.jwtsecret=/root/sepolia/jwt.hex",
      "--http",
      "--http.addr=0.0.0.0",
      "--http.port=8545",
      "--http.api=eth,net,engine,admin",
      "--ws",
      "--ws.addr=0.0.0.0",
      "--ws.port=8546",
      "--ws.api=eth,net,web3"
    ]
    networks:
      -  blockchain-network

networks:
  blockchain-network:
    driver: bridge" > docker.compose.yml

####################
# Run Archive Node #
####################
docker compoe up -d