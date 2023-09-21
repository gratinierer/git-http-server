# syntax=docker/dockerfile:1

FROM rust:alpine AS builder
WORKDIR /usr/src/

RUN <<END
    set -eux
    apk --no-cache add \
        musl-dev \
        openssl-dev
END

RUN --mount=type=bind,target=/usr/src/git-http-server,source=.,rw \
    --mount=type=cache,target=/usr/src/git-http-server/target \
    --mount=type=cache,target=/usr/local/cargo/registry \


FROM nginx:alpine

RUN apk --no-cache --update upgrade && \
    apk --no-cache add \
    fcgiwrap \
    highlight \
    git \
    git-daemon \
    git-gitweb \
    perl-cgi \
    spawn-fcgi \
    sudo \
    && \
    adduser git -h /var/lib/git -D && \
    adduser nginx git && \
    git config --system http.receivepack true && \
    git config --system http.uploadpack true && \
    git config --system user.email "gitserver@git.com" && \
    git config --system user.name "Git Server"

COPY ./scripts/entrypoint.sh /git-http-server-entrypoint.sh
COPY ./etc/gitweb.conf /etc/gitweb.conf
COPY ./etc/nginx/conf.d/* /etc/nginx/conf.d/
COPY --from=builder /usr/local/cargo/bin/repomng /usr/local/bin/repomng

ENTRYPOINT ["/git-http-server-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
