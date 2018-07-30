FROM alpine:latest

RUN apk add squid
COPY squid.conf /etc/squid/squid.conf

ENTRYPOINT ["squid", "-NYCd 1"]
