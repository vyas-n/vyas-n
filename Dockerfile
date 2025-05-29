
FROM docker.io/nixos/nix:2.29.0 AS builder
RUN mkdir -p /root/src /root/src/.home /root/src/.cache /root/src/.cargo-home
WORKDIR /root/src
COPY . ./
RUN nix --extra-experimental-features "nix-command flakes" build

FROM ghcr.io/static-web-server/static-web-server:2.36.1
COPY --from=builder /root/result /public
