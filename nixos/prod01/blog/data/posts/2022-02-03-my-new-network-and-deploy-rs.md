{---
title = "My New Network (and deploying it with deploy-rs)";
tags = [ "content" ];
uid = "my-new-network";
---}

This past week has been a major refactor of my entire NixOS deployment setup.
This post explains the decisions I made and why.
>>>

Those of you that follow my [Network Repository](https://github.com/disassembler/network)
have likely realized the lack of updates this past year. That mainly was caused by
lack of good secrets management when I switched to flakes, which since I embedded
secrets all over my configuration, I didn't push changes to GitHub as a result.

The major refactor began with trying to solve secrets management. I'll have
a follow-up post next week talking more in detail about how I manage secrets now using
`sops`, but this post isn't about that.

Like all good technology enthusiasts, I go off on a lot of tangents when I dive into
an issue. This story is one of those tangents.

This particular tangent starts with [Mic92 dotfiles](https://github.com/Mic92/dotfiles).
My previous structure in my repository had a distinction between `nixops` deployments
and systems cloning the repository to `/etc/nixos` to be used with `nixos-rebuild`. My
`nixops` deployments were fairly clean, with a `system/default.nix` and `system/hardware.nix`.
My local systems had a `nixconfigs/system.nix` and `hardware-configurations/system.nix`. To
complicate things further, on every local system, I symlinked `configuration.nix` to root of
repository and added it to `.gitignore`. Each `configuration.nix` referenced a mix of committed
and uncommitted files which meant you could never deploy a system without having some state
copied from the previous system that deployed this. As every good DevOps enthusiast knows, local
state is the bane of all existence. With flakes, imported files that weren't committed resulted
in errors. As a quick hack, I just added those secrets to git locally without pushing any changes.
I know, really, really bad, but I had plenty of other priorities at the time.

Enter `Mic92` dotfiles. His repository organizes systems in a `nixos` directory, and deployed systems
vs. local systems have no distinction. He also standardizes on the normal NixOS names, `configuration.nix`
and `hardware-configuration.nix` in each systems directory. When combined with a flake that lists all
systems as `nixosConfigurations`, this makes it super easy to test build any NixOS system, and if it's
a remote system, be able to deploy it.

So lets look briefly at how the glue for this works, ignoring secrets management for the time being.

A top level `flake.nix` is very minimal containing only the inputs and an import of another file for the
outputs. Here's an [example](https://github.com/disassembler/network/blob/18e4d34b3d09826f1239772dc3c2e8c6376d5df6/flake.nix).

The next layer is the flake [outputs](https://github.com/disassembler/network/blob/18e4d34b3d09826f1239772dc3c2e8c6376d5df6/outputs.nix).
I had never thought of putting the outputs in a file of it's own until I saw Mic92 do it,
but it really does make the flake a lot more legible! The outputs is fairly minimal as well. It takes advantage of nix attr sets
as functions using the `...` arg as the last one to not have to list every input, and then names all inputs `@ inputs`.

It then uses [flake-utils](https://github.com/numtide/flake-utils) to build a standard flake that can support multiple architectures
and provides a `devShell` that contains utilities needed to do the deployment and manage the repository, a list of all `nixosConfigurations`
and `deploy-rs` deployments, and some additional jobs and checks for a CI system.

Next we have the [devShell](https://github.com/disassembler/network/blob/18e4d34b3d09826f1239772dc3c2e8c6376d5df6/shell.nix).
This lists the inputs it needs, sets some env vars and packages we want available when working on the repository inside an `mkShell`.

At the top-level, that's essentially all we need! All our `nixosConfigurations` are listed in
[nixos/configurations.nix](https://github.com/disassembler/network/blob/18e4d34b3d09826f1239772dc3c2e8c6376d5df6/nixos/configurations.nix)
This file lists our baseModules (as well as global [customModules](https://github.com/disassembler/network/tree/18e4d34b3d09826f1239772dc3c2e8c6376d5df6/modules)
provided by this repository). and a list of machines that each are an attribute with a key of the machine name and value of `nixosSystem`
from `nixpkgs/nixos`. Each of these machines defines the architecture as `system` and a list of modules, including the `configuration.nix`
for the machine. We also have two custom NixOS installers that can be built as ISO images to install new systems!

Finally we have the [deployments](https://github.com/disassembler/network/blob/18e4d34b3d09826f1239772dc3c2e8c6376d5df6/nixos/deploy.nix).
This file takes some information of how to login to the system being deployed and the nixosConfigurations defined in the `nixosConfigurations`.
Each machine can be deployed with `deploy -s .#machine`.

That's essentially the general structure. To test it out we can run `nix develop` (or use `direnv` to run that automatically when we enter
the directory). We can build systems with `nix build .#nixosConfigurations.sarov.config.system.build.toplevel`. We can build a vm with the same
configuration using `nix build .#nixosConfigurations.prod03.config.system.build.vm`. We can deploy a system using `deploy -s .#system`. We
can build ISO images from systems providing that attribute using `nix build .#nixosConfigurations.installer.config.system.build.isoImage`.

Using this new structure and unifying all my nixops deployments and normal nix configurations has simplified maintenance across all my
systems I maintain. `deploy-rs` has been a breeze to work with for deploying systems. Systems I used to maintain the configurations locally,
I deploy from my main laptop now because of how simple it was to add a `deploy` attribute.

If you have a mess of NixOS configurations spread across multiple repositories, I highly recommend looking at this architecture
to simplify your setup.

Next weeks blog post will be on `sops` to store all your secrets.
