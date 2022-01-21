{---
title = "systemd - A new init daemon for Linux";
tags = [ "content" ];
uid = "systemd-primer";
---}

systemd is replacing all linux init systems (sysv, upstart, etc...)

>>>

If you use Linux and you haven't heard of `systemd` yet, it won't be long. With
most of the major distributions having adopted systemd already or planning to
adopt it within the next year ( RedHat, Debian, Ubuntu, Archlinux, etc...). So
since you can't ignore and avoid it anymore, this blog post is going to discuss
what it is, why it's an improvement on System V init, and how to interact with
it using `systemctl`.

`systemd` is a replacement init daemon for linux. The init daemon is the process
that the kernel launches on startup that manages starting everything else. At
it's heart, it mainly is used for stopping/starting services and getting the
current status of a service.

It supports some awesome new kernel features, such as cgroups where every process
started by systemd gets it's own `cgroup`, so it's easy to identify all the
processes associated with a service. It also allows `systemd` to assign
a cgroup a max amount of memory, a higher CPU priority, Block I/O read/write
bandwidth and even some really nitty gritty values such as swappiness.

One of the things systemd excels at over System V init scripts is service
dependencies. If you aren't familiar with how
`/sbin/init` works, when it starts, it sets the `runlevel` and first executes
all the K scripts in `/etc/rcN.d/` (where N is the runlevel) with the stop
argument, followed by all the S scripts with the start argument. Everything is
done numerically, so if process foo needs to start before process bar, it would
be S02foo and S03bar. You can see how this could get unruly when you need to
insert process baz between foo and bar and there isn't a number available. Now
you have to go about and renumber foo and bar, which means altering the RPM of
foo and bar to get baz to start at the right time. With systemd, we can specify
a service to require or even want (like require but if service doesn't exist is
ignored) another service in the unit file. So when baz and bar 2.0 are
released, baz can require foo, and bar 2.0 can want baz.

Starting and stopping services with systemd is pretty simple. We use the
`systemctl` command to interact with services. A service unit ends in .service
to distinguish between different types of systemd units. For this example,
we'll stop/start/restart the httpd.service unit. To start our service, we run
`systemctl start httpd.service`. Similarly, to stop the servce we run
`systemctl stop httpd.service`. To restart, the command is:
`systemctl restart httpd.service`.

Another benefit to systemd is monitoring of services. With System V, to get the
status of a service, the init script needed to be written to support it. We get
this "Out of the box" with systemd with all services. Here's an example output
of a stopped service:

    sam@myvm:~$ sudo systemctl status -n 50 apache2.service
    apache2.service - LSB: Start/stop apache2 web server
        Loaded: loaded (/etc/init.d/apache2)
        Active: inactive (dead)
        CGroup: name=systemd:/system/apache2.service

And of a started service:

    sam@myvm:~$ sudo systemctl status ssh.service
    ssh.service - LSB: OpenBSD Secure Shell server
        Loaded: loaded (/etc/init.d/ssh)
        Active: active (running) since Fri, 13 Mar 2015 14:23:33 -0400; 3 days ago
        CGroup: name=systemd:/system/ssh.service
          └ 1183 /usr/sbin/sshd
    
    Mar 16 22:04:52 myvm sshd[12496]: Accepted publickey for sam from 10.211.55.2 port 53061 ssh2
    Mar 16 22:04:52 myvm sshd[12496]: pam_unix(sshd:session): session opened for user sam by (uid=0)
    Mar 16 22:55:27 myvm sshd[12577]: Accepted publickey for sam from 10.211.55.2 port 53362 ssh2
    Mar 16 22:55:27 myvm sshd[12577]: pam_unix(sshd:session): session opened for user sam by (uid=0)
    Mar 16 23:18:48 myvm sshd[12593]: Accepted publickey for sam from 10.211.55.2 port 53766 ssh2
    Mar 16 23:18:48 myvm sshd[12593]: pam_unix(sshd:session): session opened for user sam by (uid=0)
    Mar 17 10:17:07 myvm sshd[18117]: Accepted publickey for sam from 10.211.55.2 port 52378 ssh2
    Mar 17 10:17:07 myvm sshd[18117]: pam_unix(sshd:session): session opened for user sam by (uid=0)
    Mar 17 10:45:42 myvm sshd[30694]: Accepted publickey for sam from 10.211.55.2 port 52716 ssh2
    Mar 17 10:45:42 myvm sshd[30694]: pam_unix(sshd:session): session opened for user sam by (uid=0)

There's a hidden gem in the status command above. Because systemd by
default sends all stdout/stderr output to journalctl, we can get the most
recent logs via the status command. If we want more, we can use the -n
parameter to specify the number of lines of logs we want to see. In this case,
we haven't even created a systemd unit file. systemd is starting the old LSB
init script without any new systemd features being setup in unit files.

This is the basic usage of systemd. In future blog posts we'll look at some
more advanced features like writing your own unit script (to see an example of
how easy it is, see my blog post on Advanced Docker Networking with Pipework),
integrating with dbus, using other unit types like timers and taking advantage of
cgroups to control your processes resource usage. Until next time, enjoy
playing with `systemd`.
