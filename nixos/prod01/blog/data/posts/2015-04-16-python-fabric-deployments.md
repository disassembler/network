{---
title = "Fabric Deployments for fun and profit - Environments and a Web Application";
tags = [ "content" ];
uid = "fabric-deployments-for-fun-and-profit-2";
---}

Building on the last post, python fabric here is refined to use
environments defined in yaml and setup role definitions
>>>

If you haven't read the (first blog post) I highly recommend you start there.
In this post we'll be digging deeper into some more intermediate tasks with
fabric. We're going to start out talking about roles. From there we're going to
move environment specific configuration into a YAML config file. We're then
going to delve into building a deployment script for a simple python
application with a pip install for requirements into a virtualenv and
a deployment strategy that simplifies rollbacks.

# Server Roles

The basis of any fabric deployment script is defining what server's get what
tasks. We do this using the `@roles` decorator on a task. This then will run the
commands in that task on every server in the group. A list of servers getting
what roles is in the `env.roledefs` variable.

Here's a simple example:

    env.roledefs = {
        'application': [ 'web.example.com' ],
    }
    
    @roles('application')
    def deploy():
        sudo('echo deploying application to webserver')

To run a deploy to the webservers, all we do now is run `fab deploy`

# Environment Configuration files - Using YAML with fabric

You very well could specifiy all your roledefs in your fabfile.py for all your environments, but a trick I like to do is load this from a YAML file. In addition to roledefs, this pattern also allows you to have environment specific variables, such as environment name, some credentials, etc...

To do this, we create a task for loading our environment. This task then parses the yaml file with the configuration and then sets that configuration in a new variable, `env.config`. This config variable is then accessible in any other tasks. Finally, we set `env.roledefs` to `env.config['roledefs']`

Here's the code:

    def loadenv(environment = ''):
        """Loads an environment config file for role definitions"""
        with open(config_dir + environment + '.yaml', 'r') as f:
            env.config = yaml.load(f)
            env.roledefs = env.config['roledefs']

And the associated configuration file `staging.yaml`:

    roledefs:
        application:
          - 'web.example.com'

# Context managers

Context managers are useful concept. They run a command within a certain
context on the remote server. A simple example is the `cd()` context manager. This changes the directory before running a specific command. It's used as follows:

    with cd('/opt/myapp'):
        run('echo running from `pwd`')

Other context managers that we'll be using for this example is `lcd()` to cd on the system we're running fabric from and `exists()` to check if a file or directory exists on the remote host before running a command.

# Using Prefix for python virtualenv

With fabric, we can prefix any command with the `prefix()` context manager. We
can also create our own context managers buy decorating a function as
`@_contextmanager`. We aren't going to go into huge details on these commands right now (they're much more advanced usage), but we are going to use them to create a context manager for loading a python virtualenv using the following code:

    env.activate = 'source /opt/myapp/python/bin/activate'
    @_contextmanager
    def virtualenv():
        with prefix(env.activate):
            yield

This context manager can then be used in your tasks similar to the built-in
`cd()` context manager as follows:

    def deploy():
        with virtualenv():
            run('pip install -r requirements.txt')

# Running privileged commands

Sometimes you need to run a command as root, for example, to create an initial directory and chown it to the user. This can be done replacing `run()` with `sudo()`. Just remember, always follow the least privilege security pattern. It's always better to not use `sudo()` if you don't have to! In this example, `sudo()` is only used to create the initial directory for the application and the python virtualenv.

# Lets deploy an application!

Ok, so now that we have the basics, lets work on deploying an application from a git repository! We'll start with the code and staging/production config files and then explain what they're doing. You can find the fabric file at https://github.com/disassembler/fabric-example/fabfile.py and configuration for staging at https://github.com/disassembler/fabric-example/config/staging.yml.

To break down the deploy process, here are the steps we are trying to accomplish with the deploy task:

1. if this is the first run on this server, run the `setup()` process
2. remove previous local builds use git to clone the application locally
3. create a binary release tarball for the application
4. copy tarball to application server
5. on application server, extract to /opt/application/builds/<timestamp>
6. symlink above directory to /opt/application/current
7. run pip install to get any requirements that have changed for the app

And our initial setup is:

1. if virtualenv for application doesn't exist, create it
2. if /opt/application/builds doesn't exist, create it

Here is the output of our deployment:

    fab loadenv:environment=staging deploy
    [10.211.55.17] Executing task 'deploy'
    [10.211.55.17] sudo: mkdir -p /opt/virtualenvs/application
    [10.211.55.17] sudo: chown -R vagrant /opt/virtualenvs/application
    [10.211.55.17] run: virtualenv /opt/virtualenvs/application
    [10.211.55.17] out: New python executable in /opt/virtualenvs/application/bin/python
    [10.211.55.17] out: Installing distribute.............................................................................................................................................................................................done.
    [10.211.55.17] out: Installing pip...............done.
    [10.211.55.17] out:
    
    [10.211.55.17] sudo: mkdir -p /opt/application/builds
    [10.211.55.17] sudo: chown -R vagrant /opt/application
    [localhost] local: mkdir -p /tmp/work
    [localhost] local: rm -rf *.tar.gz fabric-example
    [localhost] local: /usr/bin/git clone https://github.com/disassembler/fabric-example.git fabric-example
    Cloning into 'fabric-example'...
    remote: Counting objects: 21, done.
    remote: Compressing objects: 100% (15/15), done.
    remote: Total 21 (delta 7), reused 18 (delta 4), pack-reused 0
    Unpacking objects: 100% (21/21), done.
    Checking connectivity... done.
    [localhost] local: git checkout master
    Already on 'master'
    Your branch is up-to-date with 'origin/master'.
    [localhost] local: git archive --format=tar master | gzip > ../application-20150416080436.tar.gz
    [10.211.55.17] put: /tmp/work/application-20150416080436.tar.gz -> /tmp/application-20150416080436.tar.gz
    [10.211.55.17] run: mkdir -p /opt/application/builds/20150416080436
    [10.211.55.17] run: tar -zxf /tmp/application-20150416080436.tar.gz
    [10.211.55.17] run: rm -f /opt/application/current
    [10.211.55.17] run: ln -sf /opt/application/builds/20150416080436 /opt/application/current
    [10.211.55.17] run: pip install -q -U -r requirements.txt
    
    Done.
    Disconnecting from 10.211.55.17... done.

I hope this blog post will help you get started with doing your own deployments
with fabric. One thing we didn't do in this case is create a production
environment, but that is as simple as creating a new production.yml file
containing the `roledefs` for production servers, and specifying
`environment=production` in the `loadenv` task. In a future post we'll discuss
adding new roles, using `execute` for ordering tasks across multiple servers,
as well as hiding the implementation details inside a class so our fabric file
can be nice and clean. I'll also be doing a separate blog post not related to
fabric on how we can take a flask python application and use supervisord to
launch it with a proxy behind nginx. Keep an eye on the OpsBot Blog for these
upcoming posts!
