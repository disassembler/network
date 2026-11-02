# Network

Use the installed `speckit` skill for new projects and features. Follow [.specify/memory/constitution.md](.specify/memory/constitution.md).

Use `nix develop` for tools, `nix fmt` for formatting, and `nix build .#nixosConfigurations.<host>.config.system.build.toplevel` to build a host. Deploy with `nix develop -c just apply <host>` after inspecting the full host changes.
