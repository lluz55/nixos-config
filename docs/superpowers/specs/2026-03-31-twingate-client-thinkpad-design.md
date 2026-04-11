# Design Spec: Twingate Client for Thinkpad

## Problem Statement
The user needs to access the `n100` host remotely from the `thinkpad` host. `n100` is already configured as a Twingate Connector, but `thinkpad` lacks the Twingate Client to establish the secure tunnel.

## Proposed Solution
Enable the native NixOS Twingate service on the `thinkpad` host and install the `twingate` CLI package. This will allow the `thinkpad` to authenticate with the Twingate network and route traffic to resources managed by the `n100` connector.

## Goals
- Enable `services.twingate` on `thinkpad`.
- Install the `twingate` CLI package on `thinkpad`.
- Ensure the configuration overrides the global `services.twingate.enable = false` set in `hosts/configuration.nix`.

## Non-Goals
- Configuring Twingate on `n100` (already done).
- Setting up a Twingate GUI (user requested CLI only).
- Automating the initial Twingate login (requires interactive authentication).

## Technical Design

### 1. Host Configuration Changes
Modify `hosts/thinkpad/default.nix` to include the following:

```nix
{
  # ... existing config ...
  services.twingate.enable = lib.mkForce true;
  
  environment.systemPackages = with unstable; [
    # ... existing packages ...
    twingate
  ];
}
```

**Note:** `hosts/configuration.nix` has `services.twingate.enable = false;`. By setting it to `lib.mkForce true` in `hosts/thinkpad/default.nix`, we override the global default for this specific host.

### 2. User Workflow (Post-Implementation)
After the configuration is applied (`nixos-rebuild switch`), the user must:
1. Run `twingate auth login <slug>` (where `<slug>` is their Twingate network name).
2. Follow the browser-based authentication flow.
3. Verify connection status with `twingate status`.

## Dependencies
- `twingate` package from `nixpkgs` (available in `unstable`).
- Active Twingate account and network slug.

## Verification Plan
1. **Build Check:** Run `nix develop -c nixos-rebuild build --flake .#thinkpad` to ensure the configuration is valid.
2. **Service Check:** Verify `twingated.service` is running on `thinkpad` after switch.
3. **CLI Check:** Ensure the `twingate` command is available in the shell.
4. **Connectivity Check:** Confirm internal resources on `n100` (e.g., `192.168.1.1`) are reachable via Twingate after login.
