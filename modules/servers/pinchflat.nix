
{ }:

{
   virtualisation.oci-containers.containers = {
     pinchflat = {
       image = "ghcr.io/kieraneglin/pinchflat:latest";
       extraOptions = [
         "--network=host"
       ];
       volumes = [
         "/home/lluz/.pinchflat/config:/config"
         "/home/lluz/.pinchflat:/downloads"
       ];
       environment = {
         TZ = "America/Recife";
         EXPOSE_FEED_ENDPOINTS = "yes";
       };
       ports = [
         "8945:8945"
       ];
     };
   };
}

# -p 8945:8945 \
#         -v $HOME/Downloads/config:/config \
#         -v $HOME/Downloads:/downloads \
#         -e EXPOSE_FEED_ENDPOINTS=yes \
#         ghcr.io/kieraneglin/pinchflat:latest
