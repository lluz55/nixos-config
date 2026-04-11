# Twingate Client for Thinkpad Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable Twingate Client on `thinkpad` host to allow remote access to `n100`.

**Architecture:** Use NixOS native `services.twingate` module and install the `twingate` CLI package. Override global disabled state using `lib.mkForce`.

**Tech Stack:** NixOS, Twingate Client.

---

### Task 1: Enable Twingate Service and Install Package

**Files:**
- Modify: `hosts/thinkpad/default.nix`

- [ ] **Step 1: Locate `environment.systemPackages` in `hosts/thinkpad/default.nix`**

- [ ] **Step 2: Add `twingate` to the `systemPackages` list and enable the service**

```nix
  services.twingate.enable = lib.mkForce true;

  environment = {
      systemPackages = with unstable;
        [
          # ... existing packages ...
          twingate
        ];
    };
```

- [ ] **Step 3: Verify the configuration with a dry-build**

Run: `nix develop -c nixos-rebuild build --flake .#thinkpad`
Expected: SUCCESS (build completes without evaluation errors)

- [ ] **Step 4: Commit the changes**

```bash
git add hosts/thinkpad/default.nix
git commit -m "feat(thinkpad): enable twingate client"
```

---

### Task 2: Verification and User Handoff

- [ ] **Step 1: Check if `twingated.service` is defined in the output**

Run: `grep -r "twingated.service" result/etc/systemd/system/`
Expected: Match found (service file exists in the built system)

- [ ] **Step 2: Provide instructions for interactive setup**

The user needs to run:
1. `twingate auth login <slug>`
2. Follow browser instructions.
3. `twingate status` to verify.

- [ ] **Step 3: Final Commit of documentation (if any)**
