#!/bin/bash

#########
# Usage #
#########
# feather --chain <chain_name> --username <user_email> --password <password>

####################
# Check Parameters #
####################
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 --chain <chain_name> --username <username> --password <password>"
    exit 1
fi

###################
# Parse Arguments #
###################
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --chain) chain_name="$2"; shift 2;;  
        --username) username="$2"; shift 2;;  
        --password) password="$2"; shift 2;;  
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
done

#############################
###### >> RUN CHAIN << ######
#############################

###############
# System Role #
###############
system_role="""
        You are an expert indexer for a crypto company. 
        The company you are employed for assigns you a job, your job within this company
        is to set up archive nodes for specific crypto chains. You never fail
        and have established yourself within the company as someone who consistently
        provides accurate instructions for setting up an archive node using docker compose.
        The following roles you utilize for your job are listed below.
            1. You are an expert in finding Docker images based off information related to a crypto chain
                This role includes -    
                    A: Having the ability to recognize the Docker image of a Crypto Chain.
                    B: Returning the Docker configuration of a docker-compose.yml - including the Docker image.
            2. You are an expert at providing instructions at setting up an Archive Node for a chain 
                using the following structure -
                    A: A list of System Requirements to run the Archive Node.
                        This list includes CPU, OS, RAM, and DISK SPACE.
                        An example is -
                            CPU: 4 Core
                            OS: Ubuntu 22.04.4
                            RAM: 16GB 
                            DISK: 1.5TB
                    B: A list of Firewall rules that are needed to successfully run the chain
                        Port 22 should always be included.
                        An example is -
                            sudo ufw default deny incoming
                            sudo ufw default allow outgoing
                            sudo ufw allow 22/tcp
                            sudo ufw allow 80
                            sudo ufw allow 443
                    C: Provide the proper configuration needed to run the chain successfully.
                        This configuration should include all necessary configs to control an Archive Node.
                    D: Provide the Docker-Compose file. With all proper values
                            It should include the following -
                            Services,
                            Chain name,
                            Image, 
                            Container_name
                            restart: unless-stopped
                            volumes,
                            ports,
                            command
                    E: If a chain uses a snapshot - respond with "true" - otherwise reply with "false."
                    F: If a chain uses an L1 where the URL must be supplied - reply with "true" unless
                        you are able to find an L1 URL - if so, supply the URL inside of the docker file where 
                        an L1 is requested.
                    G: If beginning a directory do not use ~ ALWAYS use /root
                    H: DockerCompose Location is the file path that we are storing our docker-compose.yml in.
                    I: If a chain can be run in archive mode WITHOUT a snapshot, then provide commands to do so.
                        Only use a snapshot if a chain cannot be run in archive mode without it. 
                        Be sure to check all parameters and see if any can indicate that a chain syncs from genesis
                        without an archive node.
                    J: Ensure that the Docker image has the correct tag and that the tag exists. Ensure that the docker image exists
                        and is accessible. If you are unable to verify the correct Docker image - cross-reference the documentation portion of the chain's website 
                        and GitHub until you are able to do so.                        
                    K: Ensure that all directory paths are correctly named.
                    L: Ensure that all flags used are valid flags - double-check.
                    M: The USER running the code will always be ROOT.
                    N: "port_to_access_rpc" in the below template - is the port that the user will use to access the RPC of their chain.
                    O: If a snapshot MUST BE USED - PROVIDE the URL that the historical snapshot is located.
                    If you cannot find a snapshot URL then assume the chain can run without one. Be sure to check the documentation on parameters and values needed to sync from genesis.
                    P: Return your response as JSON.
                    Q: PREFERABLY DO NOT USE SNAPSHOT UNLESS ABSOLUTELY NEEDED

        A reference point for structure can be found at the below website links.
            - https://docs.infradao.com/archive-nodes-101/ethereum-sepolia/docker
            - https://docs.infradao.com/archive-nodes-101/rootstock/baremetal
            - https://docs.infradao.com/archive-nodes-101/ronin/docker
        Return this information using the following object, assign each response into the provided class. Do not provide anything else.

        chain = {
            "chain_details": {
                "chain_name": "",
                "chain_description":"",
                "chain_needs_local_l1":"",
                "system_requirements": [],
                "system_requirements_description": "",
                "port_to_access_rpc": ""    
            },
            "chain_configuration": {
                "firewall_rules": {
                    "rules": [],
                    "firewall_description": ""
                },
                "installation": {
                    "is_install": "",
                    "installation_commands": [],
                    "installation_description":""
                },
                "directory": {
                    "is_directory": "",
                    "create_directory_commands": [],
                    "directory_description":""
                },
                "snapshot": {
                    "is_snapshot": "",
                    "download_snapshot_commands": [],
                    "snapshot_location": "",
                    "snapshot_description": ""
                }
            },
            "chain_docker_file": {
                "docker_location": "",
                "docker_compose_file": ""
            },
            "chain_init": {
                "docker_compose_location": "", 
                "docker_compose_start": ""
            }
        }
"""

user_role="I need {$chain_name} as an archive node"

##################
# Check for curl #
##################
if ! command -v curl &>/dev/null; then
    apt install curl -y
fi

###################################
# Check for Username and Password #
###################################
# MIGHT DELETE

################
# Check for jq #
################
if ! command -v jq &>/dev/null; then
    apt install jq -y
fi

######################
# Post Chain Request #
######################
response=$(curl -s -X POST https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $OPEN_API_KEY" \
    -d "(jq -n --arg content "$system_role" '{
        model: "gpt-4o-mini",
        model: "gpt-4o-mini",
        messages: [
            {
                role: "system",
                content: $content
            },
            {
                role: "user",
                content: $user_role
            }
        ]
    }')"
    #-d "{\"role\":\"system\", \"username\":\"$username\", \"password\":\"$password\"}");

####################
# Check Valid Post #
####################
# is_post_valid=$(echo $response | jq -r '.is_valid')
# if [ "$is_post_valid" != 'true' ]; then
#     echo "Provided credentials are invalid. Check if username or password or correct."
#     echo "If you do not have an account - visit http://feather.com"
#     exit 1
# fi

#############
# Read JSON #
#############
echo "$response" | jq .
CONFIG=$(echo $response | jq -r '.chain')

##################
# Extract values #
##################

# CHAIN DETAILS
CHAIN_NAME=$(echo "$CONFIG" | jq -r '.chain_details.chain_name')
CHAIN_DESCRIPTION=$(echo "$CONFIG" | jq -r '.chain_details.chain_description')
CHAIN_PORT=$(echo "$CONFIG" | jq -r '.chain_details.port_to_access_rpc')
CHAIN_NEEDS_LOCAL_L1=$(echo "$CONFIG" | jq -r '.chain_details.chain_needs_local_l1')
CHAIN_SYSTEM_REQUIREMENTS=$(echo "$CONFIG" | jq -c '.chain_details.system_requirements')
CHAIN_SYSTEM_REQUIREMENTS_DESCRIPTION=$(echo "$CONFIG" | jq -r '.chain_details.system_requirements_description')

# CHAIN CONFIGURATION
CONFIGURATION_FIREWALL_RULES=$(echo "$CONFIG" | jq -c '.chain_configuration.firewall_rules.rules')
CONFIGURATION_FIREWALL_DESCRIPTION=$(echo "$CONFIG" | jq -r '.chain_configuration.firewall_description')
CONFIGURATION_DIRECTORY=$(echo "$CONFIG" | jq -r '.chain_configuration.directory.is_directory')
CONFIGURATION_CREATE_DIRECTORY_COMMANDS=$(echo "$CONFIG" | jq -c '.chain_configuration.directory.create_directory_commands')
CONFIGURATION_DIRECTORY_DESCRIPTION=$(echo "$CONFIG" | jq -r '.chain_configuration.directory_description')
CONFIGURATION_SNAPSHOT_IS_SNAPSHOT=$(echo "$CONFIG" | jq -r '.chain_configuration.snapshot.is_snapshot')
CONFIGURATION_SNAPSHOT_DOWNLOAD_SNAPSHOT_COMMANDS=$(echo "$CONFIG" | jq -c '.chain_configuration.snapshot.download_snapshot_commands')
CONFIGURATION_SNAPSHOT_DESCRIPTION=$(echo "$CONFIG" | jq -r '.chain_configuration.snapshot.snapshot_description')
CONFIGURATION_SNAPSHOT_LOCATION=$(echo "$CONFIG" | jq -r '.chain_configuration.snapshot.snapshot_location')
CONFIGURATION_INSTALLATION_IS_INSTALL=$(echo "$CONFIG" | jq -r '.chain_configuration.installation.is_install')
CONFIGURATION_INSTALLATION_COMMANDS=$(echo "$CONFIG" | jq -c '.chain_configuration.installation.installation_commands')
CONFIGURATION_INSTALLATION_DESCRIPTION=$(echo "$CONFIG" |jq -r '.chain_configuration.installation.installation_description')

# CHAIN DOCKER FILE
DOCKER_LOCATION=$(echo "$CONFIG" | jq -r '.chain_docker_file.docker_location')
DOCKER_COMPOSE_FILE=$(echo "$CONFIG" | jq -r '.chain_docker_file.docker_compose_file')
echo "$DOCKER_COMPOSE_FILE"

# CHAIN INITIALIZE
DOCKER_COMPOSE_FILE_LOCATION=$(echo "$CONFIG" | jq -r '.chain_init.docker_compose_location')
DOCKER_COMPOSE_FILE_START=$(echo "$CONFIG" | jq -r '.chain_init.docker_compose_start')
echo "$DOCKER_COMPOSE_FILE_LOCATION"

#############################
# Create Documentation File #
#############################
# This will create documentation for a chain involving all of the necessary steps.
# Documentation will be saved to /var/lib/feather/documentation
mkdir -p /var/lib/feather/documentation
file="/var/lib/feather/documentation/$CHAIN_NAME.txt"
#file="$CHAIN_NAME.txt"

################################
# Create Documentation Content #
################################
echo "<h1>Docker: Archive Node for $CHAIN_NAME<h1>" > "$file"
documentation_content=(
"<p>Author [ "$username" ]" 
""
"<h2>$CHAIN_NAME<h2>"
"<p>$CHAIN_DESCRIPTION<p>"
""
"<h3>System Requirements<h3>"
"<p>$CHAIN_SYSTEM_REQUIREMENTS_DESCRIPTION<p>" # System Requirements 6
""
"<h3>Required Installations<h3>"
"<p>$CONFIGURATION_INSTALLATION_DESCRIPTION<p>" # Installation Commands 9
""
"<h3>Firewall Configuration<h3>"
"<p>$CONFIGURATION_FIREWALL_DESCRIPTION<p>" # Firewall Commands 12
""
"<h3>Create Directories<h3>"
"<p>$CONFIGURATION_DIRECTORY_DESCRIPTION<p>" # Configuration 15
""
"<h3>Create Docker-Compose File<h3>"
"<p4>Create docker.compose.yml at $DOCKER_COMPOSE_FILE_LOCATION<p4>"
""
"<h3>Run $CHAIN_NAME<h3>"
"<p>cd $DOCKER_COMPOSE_FILE_LOCATION<p>"
"<p>$DOCKER_COMPOSE_FILE_START<p>"
""
"<h3>Query $CHAIN_NAME<h3>"
"<h4>To Check Sync Status of $CHAIN_NAME<h4>"
"curl -H 'Content-Type: application/json' \
-X POST --data '{"jsonrpc":"2.0", "method":"eth_syncing", "params":[], "id":1}' http://localhost/$CHAIN_PORT"
""
"<h4>To Get the Latest Block from $CHAIN_NAME<h4>"
"curl -H 'Content-Type: application/json' \
-X POST --data '{"jsonrpc":"2.0", "method":"eth_blockNumber", "params":[], "id":1}' http://localhost/$CHAIN_PORT"
)

counter=0
for line in "${documentation_content[@]}"; do
    ((counter++))
    echo "$line" >> "$file"

    if [ "$counter" == 7 ]; then
        echo "$CHAIN_SYSTEM_REQUIREMENTS" | jq -r '.[]' | while read -r requirement; do
            if [ -n "$requirement" ]; then
                echo "<p>$requirement<p>" >> "$file"
            fi
        done
    fi

    if [ "$counter" == 10 ]; then
        echo "$CONFIGURATION_INSTALLATION_COMMANDS" | jq -r '.[]' | while read -r install; do
            if [ -n "$install" ]; then
                echo "<p>$install<p>" >> "$file"
            fi
        done
    fi

    if [ "$counter" == 12 ]; then
        echo "$CONFIGURATION_FIREWALL_RULES" | jq -r '.[]' | while read -r wall; do
            if [ -n "$wall" ]; then
                echo "<p>$wall<p>" >> "$file"
            fi
        done
    fi

    if [ "$counter" == 15 ]; then
        echo "$CONFIGURATION_CREATE_DIRECTORY_COMMANDS" | jq -r '.[]' | while read -r config; do
            if [ -n "$config" ]; then
                echo "<p>$config<p>" >> "$file"
            fi
        done
    fi
done


######################
# Set Firewall Rules #
######################
for rule in $(echo "$CONFIGURATION_FIREWALL_RULES" | jq -c '.[]'); do
    eval $rule
done
ufw enable

###########################
# Install Necessary Files #
###########################
if [ "$CONFIGURATION_INSTALLATION_IS_INSTALL" == "true" ]; then
    echo "$CONFIGURATION_INSTALLATION_COMMANDS" | jq -r '.[]' | while read -r installation_command; do
        eval "$installation_command"
    done
fi

######################
# Create Directories #
######################
echo "$CONFIGURATION_CREATE_DIRECTORY_COMMANDS" | jq -r '.[]' | while read -r directory; do
    eval "$directory"
done


############################
# Check if Snapshot Exists #
############################
#if [ "$CONFIGURATION_SNAPSHOT_IS_SNAPSHOT" == "true" ]; then
    # Download Snapshot
#    for command in $(echo "$CONFIGURATION_SNAPSHOT_DOWNLOAD_SNAPSHOT_COMMANDS" | jq -c '.[]'); do
#        eval "$command"
#    done
#fi

###################################
# Save File to docker-compose.yml #
###################################
# echo "$DOCKER_COMPOSE_FILE"
# echo "$DOCKER_COMPOSE_FILE_LOCATION"
echo "$DOCKER_COMPOSE_FILE" > "$DOCKER_COMPOSE_FILE_LOCATION"

##################
# Check Snapshot #
##################
# If snapshot is required - create system service to check when file is done downloading.
# When it's done, we should initialize downloading and create system service.
# This system service will check if snapshot download is done
# When snapshot download is done, then we run docker compose within 
# So if statement below 
#if [ "$CONFIGURATION_SNAPSHOT_IS_SNAPSHOT" == "true" ]; then
    # PASS INTO CHECK_SNAPSHOT script AND exit program
#    exit 0
#fi

###############
# Start Chain #
###############
# Extract location minus docker file
DIR_LOCATION=${DOCKER_COMPOSE_FILE_LOCATION%/docker-compose.yml}
cd "$DIR_LOCATION" && docker compose up -d