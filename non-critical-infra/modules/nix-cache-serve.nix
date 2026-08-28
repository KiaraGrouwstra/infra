# Origin for the per-file `/serve/` endpoint on `cache.nixos.org`.
#
# It answers `GET /serve/<storehash>/<path>` by streaming the store path's NAR
# from the cache's public interface, decompressing forward to the wanted file
# and emitting only that file's bytes. It holds no credentials, needs no bucket
# access and has no write path, so it is exactly as trusted as the `.ls`
# listings it complements.
{ config, inputs, ... }:

{
  imports = [
    ./nginx.nix
    inputs.nix-cache-serve.nixosModules.default
  ];

  services.nix-cache-serve = {
    enable = true;
    # Decompressing the archive up to the wanted file is the entire server-side
    # cost of a request, so this is what bounds CPU use. This host runs other
    # services, so the endpoint does not get every core.
    maxConcurrency = 4;
  };

  services.nginx.virtualHosts."cache-serve.nixos.org" = {
    forceSSL = true;
    enableACME = true;

    locations."/" = {
      proxyPass = "http://${config.services.nix-cache-serve.listen}";
    };
  };
}
