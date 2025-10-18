FROM ubuntu:22.04

LABEL org.opencontainers.image.source=https://github.com/Yifei0727/sdn-route-home
LABEL org.opencontainers.image.description="A Dnsmasq Server Docker image based on Ubuntu"
LABEL org.opencontainers.image.licenses=MIT

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends dnsmasq ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Export DNS port \
EXPOSE 53/udp 53/tcp

# Start dnsmasq
CMD ["dnsmasq", "-k"]