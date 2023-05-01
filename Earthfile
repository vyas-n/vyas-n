# Earthfile reference: https://docs.earthly.dev/docs/earthfile

VERSION 0.6

deps:
    FROM docker.io/library/rust:alpine
    RUN apk add --no-cache musl-dev
    WORKDIR /root
    RUN rustup target add wasm32-unknown-unknown
    RUN rustup component add rustfmt
    RUN cargo install trunk

all:
    BUILD +build

docs:
    FROM +deps
    RUN curl -sSLf "$(curl -sSLf https://api.github.com/repos/tomwright/dasel/releases/latest | grep browser_download_url | grep linux_amd64 | grep -v .gz | cut -d\" -f 4)" -L -o dasel
    RUN chmod +x dasel
    RUN mv ./dasel /usr/local/bin/dasel

build:
    FROM +deps
    COPY --dir src Cargo.lock Cargo.toml .
    RUN cargo build
    COPY index.html .
    RUN trunk build --release
    SAVE ARTIFACT ./dist

fmt:
    FROM +deps
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
    RUN --push --secret CLOUDFLARE_API_TOKEN --secret CLOUDFLARE_ACCOUNT_ID npx wrangler pages publish --project-name vyas-n --branch "$(git branch --show-current)" ./dist
