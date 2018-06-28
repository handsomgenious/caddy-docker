#
# Builder
#
FROM abiosoft/caddy:builder as builder

ARG version="0.11.0"
ARG plugins="cloudflare,reauth,datadog"

RUN go get -v github.com/abiosoft/parent

RUN VERSION=${version} PLUGINS=${plugins} ENABLE_TELEMETRY=false /bin/sh /usr/bin/builder.sh

#
# Final stage
#
FROM alpine:3.7
ARG BUILD_DATE="2018-06-27"
ARG VCS_REF="5552dcb"
LABEL org.label-schema.build-date=$BUILD_DATE \
          org.label-schema.name="caddy" \
          org.label-schema.url="https://caddyserver.com/" \
          org.label-schema.vcs-ref=$VCS_REF \
          org.label-schema.vcs-url="https://github.com/mholt/caddy" \
          org.label-schema.schema-version="1.0"

ARG version="0.11.0"
LABEL caddy_version="$version"

# Let's Encrypt Agreement
ENV ACME_AGREE="false"

RUN apk add --no-cache openssh-client git

# install caddy
COPY --from=builder /install/caddy /usr/bin/caddy

# validate install
RUN /usr/bin/caddy -version
RUN /usr/bin/caddy -plugins

EXPOSE 80 443 2015
VOLUME /root/.caddy /srv
WORKDIR /srv

COPY Caddyfile /etc/Caddyfile
COPY index.html /srv/index.html

COPY --from=builder /go/bin/parent /bin/parent

ENTRYPOINT ["/bin/parent", "caddy"]
CMD ["--conf", "/etc/Caddyfile", "--log", "stdout", "--agree=$ACME_AGREE"]
