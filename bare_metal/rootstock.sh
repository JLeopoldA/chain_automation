# !/bin/bash

############################################################
###   ================================================   ###   
######    <( *.* <) Rootstock Bare Metal (> *.* )>    ###### 
####  ================================================  ####
############################################################

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

##############################
# Set Firewall Configuration #
##############################
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 4444 && sudo ufw allow 4445
sudo ufw allow 30303/tcp && sudo ufw allow 30303/udp
sudo ufw enable

#############################################
# Remove Previous Java Version and Packages #
#############################################
sudo apt purge openjdk-* && sudo apt autoremove
sudo apt install openjdk-8-jdk -y

######################
# Create Directories #
######################
mkdir -p /root/rootstock/config
mkdir -p /root/rootstock/database/mainnet
cd /root/rootstock/config

#############################
# Create Configuration File #
#############################
echo "blockchain.config.name = "main"

database.dir = /root/rootstock/database/mainnet
rpc {
    providers: {
        web: {
            cors = "*"
                http: {
                    enabled = true
                    bind_address = 0.0.0.0
                    port = 4444
                    hosts = ["*"]
                }
                ws: {
                    enabled = true
                    bind_address = 0.0.0.0
                    port = 4445
                }
        }
    }
    modules = {
        eth { version: "1.0", enabled: "true"},
        net { version: "1.0", enabled: "true"},
        rpc { version: "1.0", enabled: "true"},
        web3 { version: "1.0", enabled: "true"},
        evm { version: "1.0", enabled: "true"},
        sco { version: "1.0", enabled: "false"},
        txpool { version: "1.0", enabled: "true"},
        debug { version:"1.0", enabled: "true"},
        personal { version: "1.0", enabled: "false"}
    }
}" > node.conf

cd /root/rootstock

######################
# Download Rootstock #
######################
git clone --recursive https://github.com/rsksmart/rskj.git
cd rskj
git checkout tags/ARROWHEAD-6.3.1 -b ARROWHEAD-6.3.1

################################################
# Set External Dependencies and Node Compiling #
################################################
./configure.sh
./gradlew build -x test

#######################################
# Create System Service for Rootstock #
#######################################
sudo echo "[Unit]
Description=Rootstock Node
After=network.target
StartLimitIntervalSec=200
StartLimitBurst=5

[Service]
Type=simple
Restart=on-failure
RestartSec=5
TimeoutSec=900
User=root
Nice=0
LimitNOFILE=200000
WorkingDirectory=/root/rootstock/rskj/rskj-core/build/libs/
ExecStart=/usr/bin/java -Drsk.conf.file=/root/rootstock/config/node.conf -jar /root/rootstock/rskj/rskj-core/build/libs/rskj-core-6.3.1-ARROWHEAD-all.jar co.rsk.Start

KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/rootstock.service

###################
# Start Rootstock #
###################
sudo systemctl daemon-reload
sudo systemctl enable rootstock.service
sudo systemctl start rootstock.service

###########################
# View Logs for Debugging #
###########################
echo "================================================================="
echo "To view logs for debugging: journalctl -fu rootstock.service -xe"
echo "To stop Rootstock: systemctl stop rootstock.service"
echo "To restart Rootstock: systemctl restart rootstock.service"
echo "To start Rootstock: systemctl start rootstock.service"
echo "================================================================="
echo ""
echo "To query your node: "
echo "curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:4444"
