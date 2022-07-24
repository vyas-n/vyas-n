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
    COPY index.html .
    RUN trunk build --release
    SAVE ARTIFACT ./dist

fmt:
    FROM +base
    COPY --dir src Cargo.toml .
    RUN cargo fmt
    SAVE ARTIFACT src AS LOCAL src

publish:
    FROM docker.io/library/node:alpine
    RUN apk add --no-cache git
    WORKDIR /root
    COPY package-lock.json package.json .
    RUN npm ci
    COPY +build/dist ./dist
    COPY --dir .git .
    RUN --push --secret CLOUDFLARE_API_TOKEN --secret CLOUDFLARE_ACCOUNT_ID npx wrangler pages publish --project-name vyas-n --branch $(git branch --show-current) ./dist
