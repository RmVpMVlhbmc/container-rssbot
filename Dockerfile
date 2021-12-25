FROM alpine:latest AS builder

ARG LOCALE
ARG VERSION
ARG RUST_TOOLCHAIN_VERSION

COPY patches /patches

RUN set -ex && apk add build-base && cd / \
    && wget -O - https://sh.rustup.rs | sh -s -- --default-toolchain "$RUST_TOOLCHAIN_VERSION" --target x86_64-unknown-linux-musl -y \
    && wget -O - "https://github.com/iovxw/rssbot/archive/$VERSION.tar.gz" | tar xzf -
RUN set -ex && for i in $(find /patches -type f); do patch -s -p 0 < $i; done
RUN set -ex && cd /rssbot-*/ \
    && "$HOME/.cargo/bin/cargo" build --release --target x86_64-unknown-linux-musl \
    && mv target/x86_64-unknown-linux-musl/release/rssbot /usr/bin/rssbot


FROM alpine:latest

ENV MAX_INTERVAL 3600
ENV MIN_INTERVAL 300

LABEL org.opencontainers.image.authors "Fei Yang <projects@feiyang.moe>"
LABEL org.opencontainers.image.url https://dev.azure.com/fei1yang/containers
LABEL org.opencontainers.image.documentation https://dev.azure.com/fei1yang/containers/_git/rssbot?path=/README.md
LABEL org.opencontainers.image.source https://dev.azure.com/fei1yang/containers/_git/rssbot
LABEL org.opencontainers.image.vendor "FeiYang Labs"
LABEL org.opencontainers.image.licenses GPL-3.0-only
LABEL org.opencontainers.image.title RssBot
LABEL org.opencontainers.image.description "Minimalistic opinionated Telegram RSS bot container image based on Apline linux."

RUN set -ex && mkdir -p /data

COPY --from=builder /usr/bin/rssbot /usr/bin/rssbot

VOLUME ["/data"]

WORKDIR /data

CMD ["/bin/sh", "-c", "/usr/bin/rssbot --database /data/rssbot.json --max-interval \"$MAX_INTERVAL\" --min-interval \"$MIN_INTERVAL\" \"$BOT_TOKEN\""]
