# TODO: convert to using nix build system

FROM --platform=$BUILDPLATFORM docker.io/library/node:24.1.0-bookworm-slim AS npm-builder
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]
HEALTHCHECK NONE
RUN mkdir -p /root/src
WORKDIR /root/src
COPY package* ./
RUN npm install

# Note: the version of rust from the image doesn't matter,
#   I just use this image because it has rustup pre-installed.
#   Rustup will automatically pickup the version from rust-toolchain.toml.
FROM --platform=$BUILDPLATFORM docker.io/library/rust:1.86.0-slim-bookworm AS rust-builder
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]
HEALTHCHECK NONE
RUN mkdir -p /root/src
WORKDIR /root/src
COPY rust-toolchain.toml ./

RUN <<EOF
    cargo --version
    rustc --version
EOF

COPY Cargo.toml .cargo ./
COPY tools ./tools
COPY .cargo ./.cargo

RUN <<EOF
    mkdir -p ./src
    cat <<EOL > ./src/main.rs
    fn main() {}
    EOL
EOF

RUN cargo bin --install
COPY Cargo.lock ./
# TODO: Add cargo chef steps here
COPY Trunk.toml index.html ./
COPY src ./src
COPY --from=npm-builder /root/src/node_modules ./node_modules
RUN cargo bin trunk build --verbose --release

FROM ghcr.io/static-web-server/static-web-server:2.36.1
COPY --from=rust-builder /root/src/dist /public
