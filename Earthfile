# Earthfile reference: https://docs.earthly.dev/docs/earthfile

VERSION 0.7

deps:
    FROM DOCKERFILE -f dockerfiles/rust.Dockerfile .
    RUN apk add --no-cache musl-dev curl wget openssl-dev npm
    WORKDIR /root
    RUN rustup target add wasm32-unknown-unknown
    RUN rustup component add rustfmt
    RUN cargo install trunk
    RUN cargo install cargo-chef
    RUN npm install -g sass
    RUN curl -sSLf "$(curl -sSLf https://api.github.com/repos/tomwright/dasel/releases/latest | grep browser_download_url | grep linux_amd64 | grep -v .gz | cut -d\" -f 4)" -L -o dasel
    RUN chmod +x dasel
    RUN mv ./dasel /usr/local/bin/dasel

all:
    BUILD +build

build:
    BUILD +docs
    BUILD +build-site
    BUILD +publish

docs:
    FROM +deps
    COPY Cargo.toml .
    ARG VERSION=$(dasel --file=Cargo.toml '.package.version' | sed "s/'//g")
    RUN dasel put -f Cargo.toml -v $VERSION "package.version"
    SAVE ARTIFACT Cargo.toml AS LOCAL Cargo.toml

    COPY --dir src Cargo.toml .
    RUN cargo fmt
    SAVE ARTIFACT src AS LOCAL src

builder:
    FROM +deps
    COPY package.json package-lock.json .
    RUN npm ci
    COPY --dir src Cargo.lock Cargo.toml .
    RUN cargo build
    COPY index.html .
    RUN trunk build --release
    SAVE ARTIFACT ./dist

build-site:
    FROM DOCKERFILE -f dockerfiles/static-web-server.Dockerfile .
    COPY +builder/dist /public

    SAVE IMAGE vyas-n:local

publish:
    FROM DOCKERFILE -f dockerfiles/node.Dockerfile .
    RUN apk add --no-cache git
    WORKDIR /root
    COPY package-lock.json package.json .
    RUN npm ci
    COPY +builder/dist ./dist
    COPY --dir .git .
    RUN --push --secret CLOUDFLARE_API_TOKEN --secret CLOUDFLARE_ACCOUNT_ID npx wrangler pages publish --project-name vyas-n --branch "$(git branch --show-current)" ./dist
