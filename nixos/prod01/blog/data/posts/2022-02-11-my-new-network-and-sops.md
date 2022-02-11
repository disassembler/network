{---
title = "My New Network (and encrypting secrets with sops)";
tags = [ "content" ];
uid = "my-new-network-sops";
---}

This is part of the My New Network series.
This post explains how to transfer secrets to remote (and local) nodes with sops.
>>>

This post is part of the My New Network series. If you haven't yet, please read
the previous [post](https://samleathers.com/posts/2022-02-03-my-new-network-and-deploy-rs.html)
on organization and setting up a repository to deploy with `deploy-rs`.

Those of you that follow my [Network Repository](https://github.com/disassembler/network)
are probably familiar with my old solution for secret storage. It was home-grown,
required state, used dummy secrets in a committed `load-secrets.nix` file that
referenced the real secrets in an uncommitted `secrets.nix` file. This has many
problems, but is exacerbated by `nix flakes` which wants all nix files committed!

How do we solve this problem? Well, lets start with all the bad ways we can handle secrets!

Starting at the worst thing you can do, just embed them in plaintext and let them enter the
nix store. This has lots of security problems, as well as not being able to publish your
repository to share with others at all.

Next up, you have the previous option, but writing them to the nix store as well. With this
approach, you import a file that isn't committed and have to keep track of that state outside
of the repository. If you deploy from multiple systems, that means that you have to worry about
synchronizing that state across those systems. These secrets then end up in your local nix store
and the remote one as well, globally readable!

The previous approach can be improved slightly if the service is written to support it by having
the systemd service pull in the secrets (not as nix code) at runtime from a location on the server
you manually copy. This is the approach many `nixops` secrets are deployed with the `send-keys` command.

Then, we get to cryptography. This isn't new. It's something many non-NixOS deployment tools have
had for a while. For example, at a previous company where we used puppet, we stored all secrets in
a separate GPG file that was decrypted (and later updated that to use `hiera-gpg`).

This last option is where we're going with NixOS now. I initially chose `sops-nix` because a coworker
was using it and shared a snippet. I didn't quite like the structure, so went to the
[sops-nix repository](https://github.com/Mic92/sops-nix). From there, I also found Mic92's
[dotfiles](https://github.com/Mic92/dotfiles) that we referenced in the previous post.

The general idea is you have each host have a `secrets.yaml` file that's edited with the `sops` utility.
A `.sops.yaml` file tells sops what secrets get encrypted with what keys. One of these keys is your
`gpg` key that lets you edit the file, and the other keys are `ssh host keys` that are converted to GPG
so your machine can decrypt the secrets it needs. Full caveat, my current setup isn't as securely isolated
as it should be. It's a risk I've taken being a home playground environment, but in production environments
you probably want to lock things down further.

Before we look at these files, lets start by getting the public keys we need in the repository and their
fingerprints.

To start with, we have our GPG key. Mine's on a yubikey, yours may or may not be, but it doesn't matter. GPG
itself will take care of that.

To export our key, we run (change your e-mail and key name to match what you have):

```
gpg --armor --export samuel.leathers@iohk.io > nixos/secrets/keys/disasm.asc
```

You need to get the fingerprint of this key:
```
gpg --fingerprint samuel.leathers@iohk.io
pub   rsa4096 2020-01-22 [C]
      754C 09A6 72D8 3CAF 4995  42D9 F919 BF40 EACE F923
...
```
In my case, my fingerprint is: `754C09A672D83CAF499542D9F919BF40EACEF923`

Now we need to do the same thing for the host we're deploying. `sops-nix` has a tool
for that, and my
[devShell](https://github.com/disassembler/network/blob/9f7a4607d97b84ce175c47da7fa73fbbe2d9cbfd/shell.nix#L17) includes it.

```
sudo cat /etc/ssh/ssh_host_rsa_key|ssh-to-pgp -o nixos/secrets/keys/hostname
```

This will extract the GPG public key from the SSH host key and store it in the repository.
It also very helpfully prints the fingerprint. If you need to get a remote host key that
you have root ssh access to, run:

```
ssh hostname "cat /etc/ssh/ssh_host_rsa_key"|ssh-to-pgp -o nixos/secrets/keys/hostname
```

Now we have everything we need to make our
[.sops.yaml](https://github.com/disassembler/network/blob/9f7a4607d97b84ce175c47da7fa73fbbe2d9cbfd/.sops.yaml) in the repository!

In my case `admin_disasm` is my GPG key and the rest are the machines I'm deploying.

So, lets create some secrets! To do this we run `sops`. This will create some dummy
YAML by default that you can delete and replace with your actual secrets.

```
sops nixos/pskov/secrets.yaml
```

This results in a [file](https://github.com/disassembler/network/blob/9f7a4607d97b84ce175c47da7fa73fbbe2d9cbfd/nixos/pskov/secrets.yaml)
that includes all your secrets encrypted in addition to some sops metadata that says what keys it's encrypted with and when it was
created.

Now we need to add sops to our `flake.nix` and pass it on to our machines `configuration.nix`.

To do this, we want to add this line to our `inputs` in
[flake.nix](https://github.com/disassembler/network/blob/9f7a4607d97b84ce175c47da7fa73fbbe2d9cbfd/flake.nix#L16)

I find it useful to add to my [baseModules](https://github.com/disassembler/network/blob/9f7a4607d97b84ce175c47da7fa73fbbe2d9cbfd/nixos/configurations.nix#L33)
that is shared across all machine configurations.

In the machine [configuration.nix](https://github.com/disassembler/network/blob/9f7a4607d97b84ce175c47da7fa73fbbe2d9cbfd/nixos/pskov/configuration.nix#L10-L17)
we need to define where our secrets are coming from (`secrets.yaml` in current directory in my case) and then list what secrets
we expect to be in this file. We can also tweak things like permissions and ownership instead of an empty attribute set like
[here](https://github.com/disassembler/network/blob/9f7a4607d97b84ce175c47da7fa73fbbe2d9cbfd/nixos/prod01/modules/knot/default.nix#L21)

At this point we can build a machine configuration:

```
nix build '.#nixosConfigurations.pskov.config.system.build.toplevel'
```

If it's a local system, we can also just run `nixos-rebuild`, or in the case of a deploy-rs defined system run `deploy .#host`.

One thing of note is that not all `NixOS` services support proper secrets management. For this to work, the `NixOS` service
needs to pull the secrets from the file at runtime, either with an `environmentFile` or `passwordFile` option. If you come
across a service that only allows secrets embedded in the configuration file, please contribute to improve it so it will work
with `sops` and other secure secrets management systems for nix. You can also sometimes if the upstream service supports it,
write the configuration manually and give it a file path instead of an embedded string.

To use the secret, all that's left to do is reference the `path` of the `sops` secret:
[example OpenVPN key](https://github.com/disassembler/network/blob/c341a3af27611390f13f86d966767ea30c726a92/nixos/pskov/configuration.nix#L535)

This post hopefully helped you take a mess of secrets stored in all sorts of bad places and consolidated them in GPG encrypted
`secrets.yaml` files.

Next blog post will be on `knot` as an authoritative DNS server!
