# Earthfile reference: https://docs.earthly.dev/docs/earthfile

VERSION 0.6

FROM docker.io/library/rust:alpine
RUN apk add --no-cache musl-dev
WORKDIR /root
RUN rustup target add wasm32-unknown-unknown
RUN rustup component add rustfmt
RUN cargo install trunk

all:
    BUILD +build

build:
    FROM +base
    COPY --dir src Cargo.lock Cargo.toml .
    RUN cargo build
    RUN trunk build

fmt:
    FROM +base
    COPY --dir src Cargo.toml .
    RUN cargo fmt
    SAVE ARTIFACT src AS LOCAL src
