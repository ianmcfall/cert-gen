#!/bin/bash
APP_SYMBOL="$1"
if [[ -z "$APP_SYMBOL" ]]; then
    echo "Error: \$1 APP_SYMBOL is required"
    exit 1
fi
echo "Setting up app $APP_SYMBOL"

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
services=(convey logistics onli-cloud-tray transfer-agent treasury bill-breaker oracle)
for service in "${services[@]}"; do
    echo Cloning $service
    if [ -d $service ]; then
        cd $service
        git pull
    else
        git clone --quiet --depth 1 git@github.com:onlicorp/$service.git
        cd $service
    fi
    if [ "$service" != "convey" ]; then
        sed -i 's/"app_symbol":.*/"app_symbol": "'$APP_SYMBOL'",/' config.json
        cp -r ../convey/app-ssl/* cert
    fi
    cd $HOME/onlicorp

done

# Start byobu session
byobu new-session -d -s os
# logistics
byobu rename-window "logstc"
byobu send-keys -t os:0 "cd logistics" Enter
byobu send-keys -t os:0 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:0 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:0 "docker logs logistics -f" Enter
# onli-cloud-tray
byobu new-window -t os:1 -n "oct"
byobu send-keys -t os:1 "cd onli-cloud-tray" Enter
byobu send-keys -t os:1 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:1 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:1 "docker logs onli-cloud-tray -f" Enter
# transfer-agent
byobu new-window -t os:2 -n "ta"
byobu send-keys -t os:2 "cd transfer-agent" Enter
byobu send-keys -t os:2 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:2 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:2 "docker logs transfer-agent -f" Enter
# treasury
byobu new-window -t os:3 -n "tr"
byobu send-keys -t os:3 "cd treasury" Enter
byobu send-keys -t os:3 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:3 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:3 "docker logs treasury -f" Enter
# bill-breaker
byobu new-window -t os:4 -n "bb"
byobu send-keys -t os:4 "cd bill-breaker" Enter
byobu send-keys -t os:4 "docker compose -f docker-compose-multi-server.yml pull" Enter
byobu send-keys -t os:4 "docker compose -f docker-compose-multi-server.yml up -d" Enter
byobu send-keys -t os:4 "docker logs bill-breaker -f" Enter
# genome-oracle
byobu new-window -t os:5 -n "oracle"
byobu send-keys -t os:5 "cd oracle" Enter
byobu send-keys -t os:5 "docker compose pull" Enter
byobu send-keys -t os:5 "docker compose up -d" Enter
byobu send-keys -t os:5 "docker logs oracle -f" Enter

# convey
byobu new-window -t os:6 -n "convey"
byobu send-keys -t os:6 "cd convey" Enter
byobu send-keys -t os:6 "docker compose -f docker-compose-app.yml pull" Enter
byobu send-keys -t os:6 "docker compose -f docker-compose-app.yml up -d" Enter
byobu send-keys -t os:6 "docker logs onli-app-proxy -f" Enter
byobu attach-session -t os