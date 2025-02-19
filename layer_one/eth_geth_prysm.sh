#####################################################################
###   =========================================================   ###   
######    <( *.* <) Ethereum L1 [Geth && Prysm]  (> *.* )>     ###### 
####  =========================================================  ####
#####################################################################

#############################################
############ !! IMPORTANT !! ################
#                                           #
# THIS SCRIPT ASSUMES YOU HAVE ROOT ACCESS. #
# IF YOU DO NOT HAVE ROOT ACCESS...         #
# MODIFYYYY........                         #
# Sets up Geth & Prysm as                   #
# seperate system services                  #
#############################################

#################
# Update System #
#################
apt update -y && apt upgrade -y && apt autoremove -y

################
# Install Geth #
################
if ! command -v geth &>/dev/null; then
    add-apt-repository -y ppa:ethereum/ethereum
    apt-get update -y
    apt-get install ethereum -y
    apt-get upgrade geth -y
fi

###########################
# Create Folder Structure #
###########################
mkdir -p /root/ethereum/consensus
mkdir -p /root/ethereum/execution

#################
# Install Prysm #
#################
cd /root/ethereum/consensus
curl https://raw.githubusercontent.com/prysmaticlabs/prysm/master/prysm.sh \
--output prysm.sh && chmod +x prysm.sh

./prysm.sh beacon-chain generate-auth-secret
mv jwt.hex ../

###############
# Set up Geth #
###############
cd /root/ethereum/execution
current_directory=$(pwd)
geth_location=$(whereis -b geth | awk '{print $2}')
mv "$geth_location" "geth"

##################################
# Create System Service for Geth #
##################################
echo "[Unit]
Description=Geth
After=network.target
StartLimitIntervalSec=200

[Service]
RestartSec=5
TimeoutSec=900
User=root
Nice=0
Restart=on-failure
LimitNOFILE=1000000
StandardOutput=journal
StandardError=journal
WorkingDirectory=/root/ethereum/execution
ExecStart=/root/ethereum/execution/geth \
    --mainnet --http --http.api eth,net,engine,admin
    --http.port 8546 --authrpc.jwtsecret=../jwt.hex \
    --ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api eth,net,web3
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/geth.service

###################################
# Create System Service for Prysm #
################################### 
echo "[Unit]
Description=Prysm
After=network.target
StartLimitIntervalSec=200

[Service]
RestartSec=5
TimeoutSec=900
User=root
Nice=0
Restart=on-failure
LimitNOFILE=1000000
StandardOutput=journal
StandardError=journal
WorkingDirectory=/root/ethereum/consensus
ExecStart=/root/ethereum/consensus/prysm \
    beacon-chain --execution-endpoint=http://localhost:8551 --mainnet \
    --jwt-secret=../jwt.hex --checkpoint-sync-url=https://beaconstate.info \
    --genesis-beacon-api-url=https://beaconstate.info
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/prysm.service

################################
# Enable and Start Ethereum L1 #
################################
systemctl daemon-reload
systemctl enable geth.service && systemctl enable prysm.service
systemctl start geth.service && systemctl start prysm.service

echo "=========================================="
echo "To check status of Prysm: "
echo "journalctl -fu prysm.service -xe | journalctl -fu prysm.service -o cat"
echo ""
echo "To check status of Geth: "
echo "journalctl -fu geth.service -xe | journalctl -fu geth.service -o cat"
echo ""
echo "=========================================="
echo "To stop Geth or stop Prysm: "
echo "systemctl stop geth.service | systemctl stop prysm.service"
echo ""
echo "=========================================="
echo "To start Geth or start Prysm (BOTH NEED TO BE RUN SIMULTANEOUSLY): "
echo "systemctl start geth.service | systemctl start prysm.service"