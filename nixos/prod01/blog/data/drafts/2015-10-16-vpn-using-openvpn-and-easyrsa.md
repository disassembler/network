{---
title = "OpenVPN and easyrsa";
tags = [ "content" ];
uid = "openvpn-and-easyrsa";
isDraft = true;
---}

OpenVPN is an easy way to setup a VPN server. Find out how.
>>>

There are many different technologies for setting up a client-server VPN. Most
of them are proprietary that have the server running on a piece of hardware
(Cisco ASA, Dell SonicWall, Juniper Router, etc...) but if you have a linux
server, it's really easy to setup your own VPN using openvpn, and this post
will show you how!

The requirements to setup openvpn are:

1) A linux server
2) Access to your border router to setup port forwarding
3) A local CA to issue/sign certificates (we'll be using easy-rsa)

Additional assumptions you'll want to change to your settings are:

1) Server LAN is on 10.0.0.0/24 subnet
2) VPN is going to be configured to use 10.0.1.0/24 subnet
3) DNS server and default gateway is 10.0.0.1


Lets get started!

First, lets install the packages we need. This blog post assumes your using
debian:

sudo apt-get install openvpn
sudo apt-get install easy-rsa

Now, lets create a CA in /opt/easy-rsa:

sudo cp /path/to/easy-rsa /opt/easy-rsa

Now for the easy part of easy-rsa, lets generate a CA!

commands

Create key and cert for server and sign certificate using CA

commands

Create key and cert for client and sign certificate using CA

commands

Configure server.conf

Optionally, uncomment and set your IPV6 prefix to be able to reach IPV6 hosts
behind your VPN:

Configure client.ovpn

Copy keys to server

Generate client tblk for use with tunnelblick on OSX

If you need to revoke a client certificate
commands

That's all there is to it. This example shows a certificate only based
approach, but you can also setup openvpn to require a cert and user/pass coming
from LDAP or PAM. The possibilities for your own VPN are endless.
