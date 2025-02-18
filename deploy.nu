#!/usr/bin/env nix-shell
#! nix-shell -i nu
#! nix-shell -p nushell wrangler git cacert
#! nix-shell -I nixpkgs=https://github.com/NixOS/nixpkgs/archive/nixos-24.11.tar.gz

def main [cloudflare_account_id: string, cloudflare_api_token: string] {
    let current_git_branch: string = (git branch --show-current)

    print "::group::Here's all the files in current directory:"
    ls -alh ./
    print "::endgroup::"

    CLOUDFLARE_ACCOUNT_ID=$cloudflare_account_id CLOUDFLARE_API_TOKEN=$cloudflare_api_token wrangler pages deploy --project-name vyas-n --branch $current_git_branch ./result
}
