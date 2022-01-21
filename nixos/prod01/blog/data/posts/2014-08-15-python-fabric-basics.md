{---
title = "Fabric Deployments for fun and profit - The Basics";
tags = [ "content" ];
uid = "fabric-deployments-for-fun-and-profit-1";
---}

Python fabric is a tool for automating tasks that use SSH

>>>

# What is Fabric

Fabric is an autmation tool that lets you orchestrate commands
ran on servers via ssh using python. It can be used to help
automate deployments, run a single or multiple commands on multiple
servers in parallel, or pretty much anything else you can think of that
involves remote logging into a server, copying files, etc...

Fabric uses the python paramiko library to ssh into a server and run a command.
Fabric core includes a number of functions for basic tasks like push, get, run,
local (run on server where your running fabric script), sudo, execute and in
contrib has more complex commands such as rsync_project and exists. We'll talk
more about these commands in this article and future parts.

# Why you should use it

Most sytem administrators have "cheat sheets" that they use to remember how to
do a task that is frequently repeated. Most of these tasks involve using ssh to
login to a server and run a series of commands. Fabric allows the "cheat
sheets" to be converted into code that can be ran. This prevents system
administrators from making typos in commands they are running, logging into
the wrong server accidentally or forgetting to do a critical step. It also
allows changes to processes to be peer reviewed when a version control tool
like git is being used.

Fabric also provides the configuration for setting up these logins via ssh with
minimal boilerplate code as will be seen below. To be able to do similar tasks
with bash scripts requires complex for loops, manual reading of password for
sudo commands/logins, and complex output printing to determine what host
a command is being ran on. With fabric, looping hosts is automated in the API,
passwords are cached for the entire script run, and it outputs
[host1.example.com] before every line of output in the script.

Another tool system administrators use for running a task on multiple servers
at once is clusterssh. This tool allows you to give a list of a bunch of
servers and run the exact same commands in real time across all servers. In
theory, this is great, but troubleshooting errors when one server doesn't
respond correctly can be really difficult because you need to look through
every servers output to find them. Also, clusterssh doesn't allow you to
orchestrate commands against different types of servers like would be used in
a deployment. With fabric, checking error codes is possible via the array
returned from the run command, and orchestrating is really simple as well which
we will revisit in a later post.

The tool that most resembles fabric is probably capistrano, written originally
for deploying ruby on rails. capistrano requires a decent amount of boilerplate
code to do simple tasks. With fabric, as will be shown below a small short file
can be created in minutes with very little learning curve. As you get familiar
with fabric, most of the features capistrano has can also be implemented.
Capistrano also makes a number of decisions for you on "how something should be
done", such as what version control system you need to use and your release
structure. With fabric, the tools are provided to do common tasks, such as run,
put, get, etc..., but deployment structure is up to the user to define.

An automation tool that works very well with fabric is jenkins. Jenkins allows
fabric, or any other script you want to be ran on triggers, whether that be
a specific day/time in cron fashion, a commit to a version control system,
a hook such as an e-mail or web, or a manual push of a button. Where jenkins
handles the when something is done, fabric shines at the how it's done. Jenkins
and fabric work very well, especially if you have non-technical people on your
team you want to delegate tasks to. In short, jenkins gives fabric a nice web
interface for automation.

# Installation

On most operating systems you can install fabric using the command
`pip install fabric`

Once fabric is installed, you can make sure it works by running `fab help`

Since a fabric file hasn't been written yet, you'll see an error message

    Fatal error: Couldn't find any fabfiles!
    Remember that -f can be used to specify fabfile path, and use -h for help.
    Aborting.

# Getting Started - Hello Server(s)

Now that fabric is installed, it's time to write your first fabric file!
(make sure to set your user name in env.user)

fabfile.py:

    from fabric.api import *
    env.user = 'john'
    def hello():
        run('echo "hello from `hostname`"')

To run this script on myhost.mydomain.com `fab -H myhost.mydomain.com hello`

If you have an ssh key setup to login to this host, it will run it without
prompting for a password. Otherwise, fabric will prompt for your password.

To run this script on mutliple hosts, separate them with a `,`
`fab -H host1.mydomain.com,host2.mydomain.com hello`

Expected Output:

    fab -H prod01.samleathers.com,prod02.samleathers.com hello
    [prod01.samleathers.com] Executing task 'hello'
    [prod01.samleathers.com] run: echo "hello from `hostname`"
    [prod01.samleathers.com] out: hello from prod01.samleathers.com
    [prod01.samleathers.com] out:
    [prod02.samleathers.com] Executing task 'hello'
    [prod02.samleathers.com] run: echo "hello from `hostname`"
    [prod02.samleathers.com] out: hello from prod02.samleathers.com
    [prod02.samleathers.com] out:

With this one example using the `run` function there are hundreds of things you
can start automating. Check back next month for Part 2: organizing your hosts
in your fabric files where you will learn how to use role definitions in fabric
to specify which hosts a command is ran on.
