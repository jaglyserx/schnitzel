FROM haskell:9.10.3-slim-bookworm AS builder

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        g++ \
        gcc \
        libc6-dev \
        libffi-dev \
        libgmp-dev \
        make \
        pkg-config \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

COPY schnitzel.cabal ./
RUN cabal update \
    && cabal build site --only-dependencies

COPY . .
RUN cabal run site rebuild

FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/_site /usr/share/nginx/html

EXPOSE 8080
