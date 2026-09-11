FROM debian:trixie-slim AS builder

ENV LANG=C.UTF-8

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ghc \
        libghc-hakyll-dev \
    && rm -rf /var/lib/apt/lists/*

COPY site.hs ./
RUN ghc -O -threaded -rtsopts -with-rtsopts=-N -package hakyll site.hs -o /usr/local/bin/site

COPY . .
RUN site rebuild

FROM nginxinc/nginx-unprivileged:1.27-alpine

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /app/_site /usr/share/nginx/html

EXPOSE 8080
