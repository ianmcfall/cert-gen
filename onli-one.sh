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

echo Stopping docker containers
docker stop $(docker ps -q)
docker rm $(docker ps -aq)
docker network create deployment
cd 
mkdir -p onlicorp
cd $HOME/onlicorp

# add creds_update script 
echo 'docker run --network=deployment -v ./config.json:/config.json -v ${PWD}/../.onli.env:/root/.onli.env onlicorp/base-image bash -c "creds verify || creds"' | sudo tee /bin/creds_update > /dev/null
sudo chmod +x /bin/creds_update

# Clone/Update repos
services=(convey user-tray appliance-tray security-tray proof-engine vault-oracle cloud-vault-tray)
for service in "${services[@]}"; do
    echo Cloning $service
    if [ -d $service ]; then
        cd $service
        git pull
    else 
        git clone --quiet --depth 1 git@github.com:onlicorp/$service.git
    fi
    cd $HOME/onlicorp
    if [ "$service" != "convey" ]; then
        cp -r convey/ssl/* $service/cert
    fi
done

# Start byobu session
byobu new-session -d -s os
# user-tray
byobu rename-window "user-tray"
byobu send-keys -t os:0 "cd user-tray" Enter 
byobu send-keys -t os:0 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:0 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:0 "docker logs user-tray -f" Enter
# appliance-tray
byobu new-window -t os:1 -n "app-tray"
byobu send-keys -t os:1 "cd appliance-tray" Enter
byobu send-keys -t os:1 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:1 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:1 "creds_update" Enter 
byobu send-keys -t os:1 "docker compose -f docker-compose-multi-server.yml down" Enter
byobu send-keys -t os:1 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:1 "docker logs appliance-tray -f" Enter
# security-tray
byobu new-window -t os:2 -n "sec-tray"
byobu send-keys -t os:2 "cd security-tray" Enter
byobu send-keys -t os:2 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:2 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:2 "creds_update" Enter 
byobu send-keys -t os:2 "docker compose -f docker-compose-multi-server.yml down" Enter
byobu send-keys -t os:2 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:2 "docker logs security-tray -f" Enter
# proof-engine
byobu new-window -t os:3 -n "proof"
byobu send-keys -t os:3 "cd proof-engine" Enter
byobu send-keys -t os:3 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:3 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:3 "docker logs proof-engine -f" Enter
# vault-oracle
byobu new-window -t os:4 -n "voracle"
byobu send-keys -t os:4 "cd vault-oracle" Enter
byobu send-keys -t os:4 "docker compose pull" Enter
byobu send-keys -t os:4 "docker compose up -d" Enter
byobu send-keys -t os:4 "creds_update" Enter 
byobu send-keys -t os:4 "docker compose down" Enter
byobu send-keys -t os:4 "docker compose up -d" Enter
byobu send-keys -t os:4 "docker logs vault-oracle -f" Enter
# convey
byobu new-window -t os:5 -n "convey"
byobu send-keys -t os:5 "cd convey" Enter
byobu send-keys -t os:5 "docker compose pull" Enter
byobu send-keys -t os:5 "docker compose up -d" Enter
byobu send-keys -t os:5 "docker logs onli-proxy -f" Enter
# cloud-vault-tray
byobu new-window -t os:6 -n "cvt"
byobu send-keys -t os:6 "cd cloud-vault-tray" Enter
byobu send-keys -t os:6 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:6 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:6 "docker logs cloud-vault-tray -f" Enter

byobu attach-session -t os
