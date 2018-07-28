FROM alpine:latest

RUN apk add squid openssl
COPY squid.conf /etc/squid/squid.conf

RUN mkdir /etc/squid/ssl
WORKDIR /etc/squid/ssl
RUN openssl genrsa -out squid.key 2048
RUN openssl req -new -key squid.key -out squid.csr -subj "/C=XX/ST=XX/L=squid/O=squid/CN=squid"
RUN openssl x509 -req -days 3650 -in squid.csr -signkey squid.key -out squid.crt
RUN cat squid.key squid.crt | tee squid.pem

ENTRYPOINT ["squid", "-NYCd 1"]
