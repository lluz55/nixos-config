#
# Servers
#
{ ... }: {

imports = [
  ./cloudflared-connector.nix
  ./nostr-sync-relay.nix
 ];

}
