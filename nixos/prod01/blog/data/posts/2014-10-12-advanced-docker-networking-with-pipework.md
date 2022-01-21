{---
title = "Docker Networking with Pipework";
tags = [ "content" ];
uid = "docker-network-with-pipework";
---}

Pipework is a script that lets you add IP's to containers

>>>

# What is Pipework

Pipework is a script that adds an IP to LXC containers. It takes as arguments
the host interface, which is normally a bridge device, the name of the guest to
add the interface to, and an ip address. The guest name can either be an LXC
cgroup, a docker instance id, or a docker name. The ip address parameter can be
a bridge, or an IP address with a n optional netmask and gateway parameter.

# Why you should use it
Normailly with docker, the IP address given to a container is randomly
generated and not publically accessible. If you want to have a container
externally accessible, you setup the networking in the host system, and
"expose", or map the port from the container to the host system. This is
great in theory, but, say you want three separate web servers all
listening on 80. In this case, the docker host needs to have 3 separate
IP's configured, and docker needs to map the container to the correct IP.

With pipework, you can assign an IP on the network, and any ports
exposed in the dockerfile are available from that IP address. This allows
setting up docker instances much like you would a normal virtual machine, where
the docker instance can have a static IP that is directly accessible. Also, by
setting the gateway, you can enforce all traffic exits the docker instance
through that IP, and can create EGRESS firewall rules for that docker instance.
Whereas, when mapping ports to the host, it's impossible to know the IP ahead
of time of the instance that traffic will originate from.

# Installing pipework
Pipework is a single shell script and can be installed using the following command:
`sudo bash -c "curl https://raw.githubusercontent.com/jpetazzo/pipework/master/pipework > /usr/local/bin/pipework"`

The only required dependencies are bash and iproute2 utilities, docker
integration will require docker being installed and dhcp option requires a dhcp
client being available. You'll also need to setup your ethernet interface in
linux as a bridge (not discussed here).

# Using pipework with docker
If you are using named docker instances, adding the ip address 10.40.33.21 to
a docker instance bind is as simple as:
`pipework br0 bind 10.40.33.21/24`

If you want to route out of 10.40.33.1 change it to:
`pipework br0 bind 10.40.33.21/24@10.40.33.1`

If you aren't naming your docker containers, replace the name with the docker
instance id (can be found with `docker ps`)

Also, pipework can execute docker itself since docker returns the instance id
like so:
`pipework br0 $(/usr/bin/docker run -d bind) 10.40.33.21/24@10.40.33.1`

# Automating startup of your docker instance with pipework and systemd
If you're system uses systemd, it's really simple to setup docker instances to
start on boot with pipework. Here's a simple service file:

/etc/systemd/system/docker-bind.service:

    [Unit]
    Description=Docker BIND DNS Server
    After=docker.service
    Requires=docker.service
    
    [Service]
    ExecStartPre=/usr/bin/docker kill bind
    ExecStartPre=/usr/bin/docker rm bind
    ExecStart=/usr/bin/docker run --name bind bind
    ExecStartPost=/usr/bin/pipework br0 bind 10.40.33.21/24@10.40.33.1
    ExecStop=/usr/bin/docker stop bind
    
    [Install]
    WantedBy=multi-user.target

This service can then be started manually with
`systemctl start docker-bind.service`

It can also be configured to start on boot with:
`systemctl enable docker-bind.service`
