# kics-scan disable=b16e8501-ef3c-44e1-a543-a093238099c9
# Explaination, this rule is stupid. The `--platform` flag is a perfectly valid usecase.

FROM --platform=$BUILDPLATFORM docker.io/library/node:24.7.0-bookworm-slim AS npm-builder
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]
HEALTHCHECK NONE
RUN mkdir -p /root/src
WORKDIR /root/src
COPY package* ./
RUN npm install

# Note: the version of rust from the image doesn't matter,
#   I just use this image because it has rustup pre-installed.
#   Rustup will automatically pickup the version from rust-toolchain.toml.
FROM --platform=$BUILDPLATFORM docker.io/library/rust:1.89.0-slim-bookworm AS rust-builder
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
    echo "fn main() {}" > ./src/main.rs
    cargo bin --install
EOF

COPY Cargo.lock ./
# TODO: Add cargo chef steps here
COPY Trunk.toml index.html ./
COPY src ./src
COPY --from=npm-builder /root/src/node_modules ./node_modules
RUN cargo bin trunk build --verbose --release

FROM docker.io/joseluisq/static-web-server:2.38.1-debian
SHELL ["/bin/bash", "-euxo", "pipefail", "-c"]
HEALTHCHECK NONE
WORKDIR /

RUN <<EOF
    # Create group & user
    groupadd --gid=1001 static-web-server
    useradd --create-home --uid=1001 --gid=1001 --shell=/bin/sh static-web-server
EOF

USER static-web-server
COPY --from=rust-builder /root/src/dist /public
CMD ["static-web-server", "--health"]
