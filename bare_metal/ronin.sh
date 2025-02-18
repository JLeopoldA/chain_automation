# !/bin/bash

###############################################
###   ===================================   ###   
######    <( *.* <) Ronin  (> *.* )>     ###### 
####  ===================================  ####
###############################################

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

##########################
# Firewall Configuration #
##########################
sudo ufw default deny incoming && sudo ufw default allow outgoing
sudo ufw allow 22/tcp && sudo ufw allow 8545 && sudo ufw allow 8546
sudo ufw allow 30303/tcp && sudo ufw allow 30303/udp
sudo ufw enable

##############
# Install GO #
##############
wget https://go.dev/dl/go1.24.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.24.0.linux-amd64.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
source ~/.bashrc

#################
# Install Ronin #
#################
cd /root
git clone https://github.com/axieinfinity/ronin
cd /ronin/cmd/ronin && go build -o ronin
./ronin init --datadir /opt/ronin /root/ronin/genesis/mainnet.json

#########################
# Create System Service #
#########################
sudo echo "[Unit]
Description=Ronin Node
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
WorkingDirectory=/root/ronin/
ExecStart=/root/ronin/cmd/ronin/ronin \
	--gcmode archive --syncmode full \
	--http --http.addr 0.0.0.0 --http.api eth,net,web3 --http.port 8545 \
	--ws --ws.addr 0.0.0.0 --ws.port 8546 --ws.api eth,net,web3 \
	--datadir /opt/ronin \
        --port 30303 --networkid 2020 \
	--discovery.dns enrtree://AIGOFYDZH6BGVVALVJLRPHSOYJ434MPFVVQFXJDXHW5ZYORPTGKUI@nodes.roninchain.com
Restart=on-failure
LimitNOFILE=1000000
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/ronin.service

#############
# Run Ronin #
#############
sudo systemctl daemon-reload && sudo systemctl enable ronin.service
sudo systemctl start ronin.service

###########################
# View Logs for Debugging #
###########################
echo "============================================================="
echo "To view logs for debugging: journalctl -fu ronin.service -xe"
echo "To stop Ronin: systemctl stop ronin.service"
echo "To restart Ronin: systemctl restart ronin.service"
echo "To start Ronin: systemctl start ronin.service"
echo "============================================================="
echo ""
echo "To query your node: "
echo "curl -H "Content-Type: application/json" -X POST --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' http://localhost:8545"