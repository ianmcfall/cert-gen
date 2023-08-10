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
services=(user-tray appliance-tray security-tray proof-engine vault-oracle oracle convey logistics onli-cloud-tray transfer-agent treasury bill-breaker cloud-vault-tray)
for service in "${services[@]}"; do
    echo Cloning $service
    if [ -d $service ]; then
        cd $service
        git pull
    else 
        git clone --quiet --depth 1 git@github.com:onlicorp/$service.git
        cd $service
    fi
    cd $HOME/onlicorp
done

# Start byobu session
byobu new-session -d -s os
# user-tray
byobu rename-window "user-tray"
byobu send-keys -t os:0 "cd user-tray" Enter 
byobu send-keys -t os:0 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:0 "docker compose -f docker-compose-multi-server.yml up -d" Enter
# appliance-tray
byobu new-window -t os:1 -n "app-tray"
byobu send-keys -t os:1 "cd appliance-tray" Enter
byobu send-keys -t os:1 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:1 "docker compose -f docker-compose-multi-server.yml up -d" Enter
# security-tray
byobu new-window -t os:2 -n "sec-tray"
byobu send-keys -t os:2 "cd security-tray" Enter
byobu send-keys -t os:2 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:2 "docker compose -f docker-compose-multi-server.yml up -d" Enter
# proof-engine
byobu new-window -t os:3 -n "proof"
byobu send-keys -t os:3 "cd proof-engine" Enter
byobu send-keys -t os:3 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:3 "docker compose -f docker-compose-multi-server.yml up -d" Enter
# vault-oracle
byobu new-window -t os:4 -n "voracle"
byobu send-keys -t os:4 "cd vault-oracle" Enter
byobu send-keys -t os:4 "docker compose pull" Enter
byobu send-keys -t os:4 "docker compose up -d" Enter
# genome-oracle
byobu new-window -t os:5 -n "oracle"
byobu send-keys -t os:5 "cd oracle" Enter
byobu send-keys -t os:5 "docker compose pull" Enter
byobu send-keys -t os:5 "docker compose up -d" Enter
# convey
byobu new-window -t os:6 -n "convey"
byobu send-keys -t os:6 "cd convey" Enter
byobu send-keys -t os:6 "docker compose pull" Enter
byobu send-keys -t os:6 "docker compose up -d" Enter
# logistics
byobu new-window -t os:7 -n "logstc"
byobu send-keys -t os:7 "cd logistics" Enter
byobu send-keys -t os:7 "docker compose pull" Enter
byobu send-keys -t os:7 "docker compose up -d" Enter
# onli-cloud-tray
byobu new-window -t os:8 -n "oct"
byobu send-keys -t os:8 "cd onli-cloud-tray" Enter
byobu send-keys -t os:8 "docker compose pull" Enter
byobu send-keys -t os:8 "docker compose up -d" Enter
# transfer-agent
byobu new-window -t os:9 -n "ta"
byobu send-keys -t os:9 "cd transfer-agent" Enter
byobu send-keys -t os:9 "docker compose pull" Enter
byobu send-keys -t os:9 "docker compose up -d" Enter
# treasury
byobu new-window -t os:10 -n "tr"
byobu send-keys -t os:10 "cd treasury" Enter
byobu send-keys -t os:10 "docker compose pull" Enter
byobu send-keys -t os:10 "sleep 10" Enter # wait for oracle to start
byobu send-keys -t os:10 "docker compose up -d" Enter
# bill-breaker
byobu new-window -t os:11 -n "bb"
byobu send-keys -t os:11 "cd bill-breaker" Enter
byobu send-keys -t os:11 "docker compose pull" Enter
byobu send-keys -t os:11 "sleep 60" Enter # wait for treasury to start
byobu send-keys -t os:11 "docker compose up -d" Enter
# cloud-vault-tray
byobu new-window -t os:12 -n "cvt"
byobu send-keys -t os:12 "cd cloud-vault-tray" Enter
byobu send-keys -t os:12 "docker compose pull" Enter
byobu send-keys -t os:12 "docker compose up -d" Enter

byobu attach-session -t os