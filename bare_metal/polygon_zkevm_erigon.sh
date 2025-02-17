# !/bin/bash

########################################################################
###   ============================================================   ###   
######    <( *.* <) Polygon Zkevm Erigon Bare Metal  (> *.* )>    ###### 
####  ============================================================  ####
########################################################################

#############################################
############ !! IMPORTANT !! ################
#                                           #
# THIS SCRIPT ASSUMES YOU HAVE ROOT ACCESS. #
# IF YOU DO NOT HAVE ROOT ACCESS...         #
# MODIFYYYY........                         #
#############################################

##############################################
# !!!!!THIS SCRIPT EXPECTS AN L1 RPC URL!!!!!#
#      >> PASS ONE IN AS A PARAMETER <<      #
##############################################
l1_rpc="$1"
if [ -n "$l1_rpc" ]; then
    echo "This script requires the url of an L1 RPC. Supply one as a parameter"
    echo "Example: "
    echo "./polygon_zkevm_erigon.sh <l1_RPC_URL>"
    exit 1
fi

#################
# Update System #
#################
sudo apt update -y && sudo apt upgrade -y && sudo apt autoremove -y

###################
# Set Up Firewall #
###################
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow 22/tcp && sudo ufw allow 8545
sudo ufw allow 30303/tcp && sudo ufw allow 30303/udp
sudo ufw enable

##############
# Install GO #
##############
wget https://go.dev/dl/go1.24.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.24.0.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc

################
# Build Erigon #
################
cd /root && git clone https://github.com/0xPolygonHermez/cdk-erigon
cd cdk-erigon/cmd/cdk-erigon
go build -o erigon

###########################
# Create Directory for DB #
###########################
mkdir -p /var/lib/zkevm/db/

##################################
# Create Configuration Directory #
##################################
mkdir -p /root/config/
cd /root/config
echo "datadir: /var/lib/zkevm/db/
chain: hermez-mainnet
http: true
private.api.addr: localhost:9091
zkevm.l2-chain-id: 1101
zkevm.l2-sequencer-rpc-url: https://zkevm-rpc.com
zkevm.l2-datastreamer-url: stream.zkevm-rpc.com:6900
zkevm.l1-chain-id: 1
zkevm.l1-rpc-url: $l1_rpc

zkevm.address-sequencer: "0x148Ee7dAF16574cD020aFa34CC658f8F3fbd2800"
zkevm.address-zkevm: "0x519E42c24163192Dca44CD3fBDCEBF6be9130987"
zkevm.address-rollup: "0x5132A183E9F3CB7C848b0AAC5Ae0c4f0491B7aB2"
zkevm.address-ger-manager: "0x580bda1e7A0CFAe92Fa7F6c20A3794F169CE3CFb"

zkevm.default-gas-price: 1000000000
zkevm.max-gas-price: 0
zkevm.gas-price-factor: 0.0375

zkevm.l1-rollup-id: 1
zkevm.l1-block-range: 20000
zkevm.l1-query-delay: 6000
zkevm.l1-first-block: 16896700
zkevm.datastream-version: 2

# debug.timers: true # Uncomment to enable timers

externalcl: true
http.port: 8545
http.api: [eth, debug, net, trace, web3, erigon, zkevm]
http.addr: 0.0.0.0
http.vhosts: any
http.corsdomain: any
ws: true" > config.yaml

#########################
# Create System Service #
#########################
sudo touch /etc/systemd/system/zkevm.service 
echo "[Unit]
Description=Zkevm Node
After=network.target
StartLimitIntervalSec=200
StartLimitBurst=5
​
[Service]
Type=simple
Restart=on-failure
RestartSec=5
TimeoutSec=900
User=root
Nice=0
LimitNOFILE=200000
WorkingDirectory=/root/cdk-erigon/
ExecStart=/root/cdk-erigon/cmd/cdk-erigon/erigon \
	--config="/root/config/config.yaml"
KillSignal=SIGTERM
StandardOutput=journal
StandardError=journal
​
[Install]
WantedBy=multi-user.target" > /etc/systemd/system/zkevm.service

#############################
# Run Zkevm With CDK-Erigon #
#############################
sudo systemctl daemon-reload
sudo systemctl enable zkevm.service
sudo systemctl start zkevm.service

echo "====================================================="
echo ""
echo "To view logs for debugging: journalctl -fu zkevm.service -xe"
echo "To query Poly Zkevm Node: "
echo "curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545"

