#!/bin/bash

# Install Docker
if ! command -v docker &>/dev/null; then
    echo Installing Docker
    sudo apt-get update
    sudo apt-get install ca-certificates curl wget gnupg byobu git make -y
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
fi

# Login to Docker
docker_login=$(docker info 2>&1 | grep -i 'Username:')
if ! [[ -n "$docker_login" ]]; then
    docker login
fi

# Add SSH key to github
if ! [[ -f "$HOME/.ssh/id_rsa" ]]; then
    ssh-keygen -q -t rsa -N "" -f $HOME/.ssh/id_rsa
fi
cat $HOME/.ssh/id_rsa.pub
echo Please add this ssh public key to github
echo "Press Enter to continue..."
read

if ! command -v go &>/dev/null; then 
    wget https://go.dev/dl/go1.20.6.linux-amd64.tar.gz
    sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.20.6.linux-amd64.tar.gz
    rm go1.20.6.linux-amd64.tar.gz
    echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bashrc
    source $HOME/.bashrc

    desired_config="https://github.com/"

    # set gitconfig
    current_config=$(git config --global --get url.git@github.com:.insteadOf)
    if ! [ "$current_config" == "$desired_config" ]; then
        git config --global url.git@github.com:.insteadOf "https://github.com/"
        echo "Git configuration set to the desired value."
    fi
    export GOPRIVATE="github.com"
    go install github.com/onlicorp/dev-tools/creds@latest
fi

echo Stopping docker containers
docker stop $(docker ps -q)
docker rm $(docker ps -aq)
docker network create deployment
cd 
mkdir -p onlicorp
cd $HOME/onlicorp

# Clone/Update repos
services=(logistics onli-cloud-tray transfer-agent treasury bill-breaker cloud-vault-tray)
for service in "${services[@]}"; do
    echo Cloning $service
    if [ -d $service ]; then
        cd $service
        git pull
    else 
        git clone --quiet --depth 1 git@github.com:onlicorp/$service.git
    fi
    cd $service
    echo 'LocalEnv="true"
LogisticsClientAddr="logistics-logistics-1:8083"
TransferAgentAddr="transfer-agent-transfer-agent-1:8085"
BillBreakerClientAddr="bill-breaker-bill-breaker-1:8084"
OnliCloudAddr="onli-cloud-tray-onli-cloud-tray-1:8086"
TreasuryAddr="treasury-treasury-1:8087"

VaultOracleClientAddr="100.114.48.132:8082"
OracleAddr="100.114.48.132:8088"
SecurityTrayAddr="100.114.48.132:8091"
UserTrayAddr="100.114.48.132:8092"
RabbitMQAddr="amqp://guest:guest@100.114.48.132:5672/"' > .env
    cd $HOME/onlicorp
done

# Start byobu session
byobu new-session -d -s os
# logistics
byobu rename-window "logstc"
byobu send-keys -t os:0 "cd logistics" Enter
byobu send-keys -t os:0 "sed -i 's/vault_oracle_db/100.114.48.132/' docker-compose-multi-server.yml"
byobu send-keys -t os:0 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:0 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:0 "docker logs logistics-logistics-1 -f" Enter
# onli-cloud-tray
byobu new-window -t os:1 -n "oct"
byobu send-keys -t os:1 "cd onli-cloud-tray" Enter
byobu send-keys -t os:1 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:1 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:1 "docker logs onli-cloud-tray-onli-cloud-tray-1 -f" Enter
# transfer-agent
byobu new-window -t os:2 -n "ta"
byobu send-keys -t os:2 "cd transfer-agent" Enter
byobu send-keys -t os:2 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:2 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:2 "docker logs transfer-agent-transfer-agent-1 -f" Enter
# treasury
byobu new-window -t os:3 -n "tr"
byobu send-keys -t os:3 "cd treasury" Enter
byobu send-keys -t os:3 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:3 "sleep 10" Enter # wait for oracle to start
byobu send-keys -t os:3 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:3 "docker logs treasury-treasury-1 -f" Enter
# bill-breaker
byobu new-window -t os:4 -n "bb"
byobu send-keys -t os:4 "cd bill-breaker" Enter
byobu send-keys -t os:4 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:4 "sleep 60" Enter # wait for treasury to start
byobu send-keys -t os:4 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:4 "docker logs bill-breaker-bill-breaker-1 -f" Enter
# cloud-vault-tray
byobu new-window -t os:5 -n "cvt"
byobu send-keys -t os:5 "cd cloud-vault-tray" Enter
byobu send-keys -t os:5 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:5 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:5 "docker logs cloud-vault-tray-cloud-vault-tray-1 -f" Enter

byobu attach-session -t os