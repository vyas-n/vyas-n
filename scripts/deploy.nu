#! /usr/bin/env NIXPKGS_ALLOW_UNFREE=1 nix-shell
#! nix-shell -i nu --pure --packages nushell nix git

def main [cloudflare_api_token: string, cloudflare_account_id: string] {
    print "check if this works?"

    nix build

    env CLOUDFLARE_API_TOKEN=($cloudflare_api_token) CLOUDFLARE_ACCOUNT_ID=($cloudflare_account_id) nix run .#wrangler -- pages publish --project-name vyas-n --branch $"(git branch --show-current)" ./result
}
