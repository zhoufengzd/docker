#!/usr/bin/env bash

function __install_docker {
    # To allow Docker to use the aufs storage drivers
    apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual

    #
    apt-get -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        software-properties-common

    #
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    #
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && apt-get update &&

    #
    apt-get -y install docker-ce

    # Test
    service docker start
    docker run hello-world
    docker rmi -f hello-world:latest

    groupadd docker
    gpasswd -a $USER docker
    service docker restart
}

os=${OSTYPE//[0-9.]/}

docker_status=$(docker --version)
if [ -z "$docker_status" ]; then
    if [[ $os == "darwin" ]]; then
        echo "Please install docker engine manually."
    else
        __install_docker
    fi
else
    echo "docker is already installed."
fi
