# Network deployment constitution

1. Use declarative NixOS configuration and pinned flake inputs. Use Nix for tools.
2. Preserve unrelated local changes and existing host services.
3. Keep persistent application data outside the Nix store; expose family web apps through HTTPS with backend ports restricted to loopback.
4. Specify, plan, and task feature work before implementation. Verify affected NixOS configuration and packages, and document deployment checks.
5. Do not enumerate /nix/store. Stop and ask before changing approach after a failed check.

Version: 1.0.0. Ratified: 2026-10-23.
