FROM alpine:latest

RUN apk add squid

ENTRYPOINT ["squid", "-NYCd 1"]
