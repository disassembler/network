{---
title = "Icinga2 and you";
tags = [ "content" ];
uid = "icinga2-and-you";
---}

Icinga2 is a rewrite of icinga, a fork of nagios. This will guide you in installation
>>>

You got that fancy new Drupal website ready to go live! Now what? Well, if this
is a production site, it's probably time to start planning how your going to
monitor it. In this post, we're going to talk about the complete rewrite to
icinga (a nagios fork), icinga2! This blog post will assume systemd is already
your init daemon.

Lets get started. First your going to need to install icinga2 on your
monitoring server. This is pretty straight forward if your using debian or
ubuntu. We're going to assume your using debian wheezy in this example:

    wget -O - http://debmon.org/debmon/repo.key 2>/dev/null | sudo apt-key add -
    echo 'deb http://debmon.org/debmon debmon-wheezy main' > /etc/apt/sources.list.d/debmon.list
    apt-get update
    apt-get install icinga2

This step will be done on all your clients and your server. We need to install
some more dependencies on the server to setup the database:

    sudo apt-get -y install python-software-properties
    sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
    sudo add-apt-repository 'deb http://mirror.jmu.edu/pub/mariadb/repo/10.1/debian wheezy main'
    sudo apt-get update
    sudo apt-get install mariadb-server
    sudo apt-get install icinga2-ido-mysql

The above will prompt you to setup root credentials and credentials for
icinga2 to the IDO MySQL database. Next step is to enable the feature and
restart the service:

    sudo icinga2 feature enable ido-mysql
    sudo systemctl restart icinga2.service

At this point, the server is setup and able to do checks and store results in
the database, but you probably are going to want a web interface to interact
with icinga2, so lets set it up:

    sudo apt-get install icingaweb2 apache2 php5 php5-cli

Make sure your password and username for connecting to the icinga_ido db is the
same as the one you setup prior in `/etc/icingaweb2/resources.ini`.

The rest of the configuration for icingaweb2 is in the browser, but we need
a token, so run:

    sudo icingacli setup token create

Copy that token for later setup steps.

At this point we have an icinga2 server monitoring itself, but we still need to
setup notifications and setup other servers to be monitored by it.

