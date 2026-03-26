{ config, lib, pkgs, ... }:
let
  cfg = config.cameraRouter;
  cameraManifest = pkgs.writeText "camera-router-manifest" (
    lib.concatStringsSep "\n" (
      map (camera: "${camera.name}|${camera.ip}|${lib.optionalString (camera.rtspUrl != null) camera.rtspUrl}") cfg.cameras
    )
  );

  checkScript = pkgs.writeShellApplication {
    name = "camera-router-check";
    runtimeInputs = [ pkgs.coreutils pkgs.ffmpeg pkgs.iputils ];
    text = ''
      set -u

      manifest=${lib.escapeShellArg (toString cameraManifest)}
      failed=0

      if [ ! -s "$manifest" ]; then
        echo "camera router: no cameras configured"
        exit 0
      fi

      while IFS='|' read -r name ip rtsp; do
        [ -n "''${name:-}" ] || continue

        if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
          echo "camera router: $name ($ip) reachable"
        else
          echo "camera router: $name ($ip) unreachable"
          failed=1
          continue
        fi

        if [ -n "''${rtsp:-}" ]; then
          if timeout 10 ffprobe -v error -rtsp_transport tcp "$rtsp" >/dev/null 2>&1; then
            echo "camera router: $name RTSP ok"
          else
            echo "camera router: $name RTSP failed"
            failed=1
          fi
        fi
      done < "$manifest"

      exit "$failed"
    '';
  };

  diagScript = pkgs.writeShellApplication {
    name = "camera-router-diag";
    runtimeInputs = [ pkgs.networkmanager pkgs.coreutils pkgs.iproute2 pkgs.iptables ];
    text = ''
      set -eu

      echo "=== Camera Router Diagnostic ==="
      echo ""

      echo "--- Uplink Connection Status ---"
      if nmcli connection show camera-uplink >/dev/null 2>&1; then
        nmcli connection show camera-uplink | grep -E "GENERAL.STATE|IP4.ADDRESS|IP4.GATEWAY|IP4.DNS"
      else
        echo "camera-uplink connection not found"
      fi
      echo ""

      echo "--- Uplink Interface ---"
      ip addr show ${cfg.uplinkInterface} 2>/dev/null || echo "${cfg.uplinkInterface} not found"
      echo ""

      echo "--- AP Interface ---"
      ip addr show ${cfg.apInterface} 2>/dev/null || echo "${cfg.apInterface} not found"
      echo ""

      echo "--- hostapd Status ---"
      if pgrep -x hostapd >/dev/null; then
        echo "hostapd is running"
      else
        echo "hostapd is NOT running"
      fi
      echo ""

      echo "--- dnsmasq Leases ---"
      if [ -f /var/lib/misc/dnsmasq.leases ]; then
        cat /var/lib/misc/dnsmasq.leases
      else
        echo "No leases file found"
      fi
      echo ""

      echo "--- NAT Rules ---"
      if command -v nft >/dev/null; then
        nft list ruleset 2>/dev/null | grep -A 20 "table ip nat" || echo "No NAT rules found"
      fi
      echo ""

      echo "--- IP Forwarding ---"
      sysctl net.ipv4.ip_forward 2>/dev/null || echo "Cannot read ip_forward"
      echo ""

      echo "--- Connectivity Test ---"
      if ping -c 2 -I ${cfg.uplinkInterface} 8.8.8.8 >/dev/null 2>&1; then
        echo "Uplink has internet connectivity: OK"
      else
        echo "Uplink has internet connectivity: FAILED"
      fi
    '';
  };
in
with lib; {
  config = mkIf cfg.enable {
    systemd.services.camera-router-check = {
      description = "Probe Tuya camera connectivity and RTSP";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${checkScript}/bin/camera-router-check";
      };
    };

    systemd.timers.camera-router-check = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "2m";
        OnUnitActiveSec = "5m";
        Unit = "camera-router-check.service";
      };
    };

    environment.systemPackages = [ diagScript ];
  };
}
