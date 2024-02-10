{ masterUser, ... }:
let
  _commonDevices = [
    "/dev/fuse"
    "/dev/net/tun"
    "/run/udev/"
  ];
  _bindMountDevices = devices: map (hostPath: { inherit hostPath; }) devices;
  mkAllowedDevices = { devices ? []}: map (node: { inherit node; modifier = "rwm"; }) (_commonDevices ++ devices);
  mkBindMounts = { mountDevices ? [ ], devicesList ? [ ] }: builtins.listToAttrs (map
    ({ hostPath, ... } @ value:
      {
        name = hostPath;
        inherit value;
      }
    )
    ((_bindMountDevices devicesList) ++ mountDevices ++ (_bindMountDevices _commonDevices))
  );
  mkCreateNeededFolders = names: map
    (name:
      "d ${name} 0770 ${masterUser.name} users -"
    )
    names;
in
{
  inherit mkAllowedDevices mkBindMounts mkCreateNeededFolders;
}
