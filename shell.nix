{ mkShell
, sops-import-keys-hook
, ssh-to-pgp
, sops-init-gpg-key
, sops
, deploy-rs
, nixpkgs-fmt
, knot-dns
, lefthook
, qemu
, iproute2
, python3
, libguestfs-with-appliance
}:

mkShell {
  sopsPGPKeyDirs = [ "./nixos/secrets/keys" ];
  # for OSX-KVM
  buildInputs = [
    qemu
    python3
    iproute2
    # If you want to regenerate the OpenCore image you'll need the below:
    #libguestfs-with-appliance
  ];
  nativeBuildInputs = [
    python3.pkgs.invoke
    ssh-to-pgp
    sops-import-keys-hook
    sops-init-gpg-key
    sops
    deploy-rs
    nixpkgs-fmt
    lefthook
    knot-dns
  ];
}
