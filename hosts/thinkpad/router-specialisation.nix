{ config, lib, ... }:
with lib; {
  specialisation.camera-router = {
    inheritParentConfig = true;
    configuration = {
      cameraRouter = {
        enable = lib.mkForce true;
        mode = "provisioning";
        uplinkInterface = "wlp3s0";
        uplinkSsid = "vl-guests";
        uplinkPsk = "H1o6u1s5e4-guests";
        apInterface = "wlp4s0f3u2";
        ssid = "tuya-cameras";
        passphrase = "tuya-provisioning";
        cameras = [ ];
      };
    };
  };
}
