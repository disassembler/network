{---
title = "Nix - a package manager that doesn't suck";
tags = [ "content" ];
uid = "nix-package-manager";
---}

Nix is a package manager like yum, apt-get and pacman. Find out what makes it
better than any one you've used before
>>>

If you're reading this post, you're probably familiar with the shortcomings of many
linux package managers, whether that be rpm's on redhat, deb's on debian, or
source/binary tarballs on gentoo or even bottles and source using homebrew on
OSX, it never fails that you eventually get to
a point where you need a package with a different library version than your
system provides, and you end up building something from source.

But what if there was a better way? Enter nix. Nix package manager came about
as a university research project to handle many of the shortcomings of typical
package managers. Theoretically, every package on your system could use
a different set of dependencies, because every package (even a new version of
an already existing package) exists as hash in a directory. Even if the default
libc version on the system is 2.3, if your package needs 2.2, all you need to
do is point to the libc 2.2 directory. This allows for the following features:

1) Test package upgrades on a system while leaving the existing package in place
2) Rollback a package upgrade without affecting any other package on the system
3) Different versions used by different users on the same system

Lets talk about how this works at a low level. When we install a package in nix
using `nix-env some command`, that package is placed into a directory in the
nix store named by a hash that is generated using the package name, version and
dependency tree. When another package depends on a package, it is built against
that packages directory instead of /usr/lib or /usr/local/lib. When a package
is upgraded, the other package remains, and a new directory hash is generated
for the upgraded package. To free up disk space on the system, a garbage
collector is ran that only removes packages that are not depended by any active
existing packages. When a package is rolled back, all that is changed is the
symlinks in `the nix store directory` to the hash of the old package. Also,
since the hash is based on the dependency tree, this also means the same
version of a package can be installed on the system depending on a different
version of a package. This means even if the dependency is upgraded, this
package will continue to rely on the older version until the package is rebuilt
against the new dependency version.

So, this is great on a single user system, but what if you have multiple users
on the system? Do you have to give write access to the nix store to all users
on that system? Absolutely not! Nix provides the nix daemon for multi-user
systems. What this does is instead of having the user running the command to
install the package, it tells the daemon to fire off a job to install the
package which keeps the entire nix store owned by the user the daemon is
running as. Each user has a profile directory in the nix store they source to
get their own personal set of packages they are using in the nix store. In this
way some packages can be shared across users, and other ones can be
specifically installed for that specific user.

So, now that we understand what nix is, lets setup our own nix store. We'll
work with the simpler nix store owned by a single user for this example:

    curl nix|bash

    ln -s /nix/profile ~/.profile-nix

That's it, you now have your own nix store. Lets install some packages:

    nix-env -i blah...

now lets install a specific version of X:

    nix-env -i X
    ls -hal /nix/foo

now lets install the latest one:

    nix-env -i X
    ls -hal /nix/foo
    ls -hal /nix/store/4wjx372kx9djqqlywqscp21z8b17v7bl-X

You can see that X is now the latest, but the old version of X still exists

That's pretty much the basics of nix. Stay tuned for another blog post on an OS
built completely around nix, nixos!
