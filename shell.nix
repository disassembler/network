{ mkShell
, sops-import-keys-hook
, ssh-to-pgp
, sops-init-gpg-key
, sops
, deploy-rs
, nixpkgs-fmt
, knot-dns
, lefthook
, python3
}:

mkShell {
  sopsPGPKeyDirs = [ "./nixos/secrets/keys" ];
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
