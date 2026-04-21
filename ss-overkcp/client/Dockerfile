# Use a smaller base image
FROM alpine:3.18

LABEL org.opencontainers.image.source=https://github.com/Yifei0727/sdn-route-home
LABEL org.opencontainers.image.description="A KCP Tunnel for Shadowsocks server Docker image"
LABEL org.opencontainers.image.licenses=MIT

# Install necessary packages
RUN apk add --no-cache bash

# Create daemon directory
RUN mkdir -p /daemon/

# Download and install KCP client, shadowsocks, and Horust binaries
RUN \
    ARCH=$(arch) ; \
    if [ "${ARCH}" = "x86_64" ] ; then \
        KCP_BINARY="client_linux_amd64"; \
        SS_BINARY="sslocal"; \
        wget -q -O kcptun.tar.gz https://github.com/Yifei0727/kcptun/releases/download/v20260129/kcptun_linux_amd64.tar.gz ; \
        wget -q -O shadowsocks.tar.xz https://github.com/shadowsocks/shadowsocks-rust/releases/download/v1.23.4/shadowsocks-v1.23.4.x86_64-unknown-linux-musl.tar.xz ; \
        wget -q -O horust.tar.gz https://github.com/FedericoPonzi/Horust/releases/download/v0.1.13/horust-x86_64-unknown-linux-musl.tar.gz ; \
    elif [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] ; then \
        KCP_BINARY="client_linux_arm64"; \
        SS_BINARY="sslocal"; \
        wget -q -O kcptun.tar.gz https://github.com/Yifei0727/kcptun/releases/download/v20260129/kcptun_linux_arm64.tar.gz ; \
        wget -q -O shadowsocks.tar.xz https://github.com/shadowsocks/shadowsocks-rust/releases/download/v1.23.4/shadowsocks-v1.23.4.aarch64-unknown-linux-musl.tar.xz ; \
        wget -q -O horust.tar.gz https://github.com/FedericoPonzi/Horust/releases/download/v0.1.13/horust-aarch64-unknown-linux-gnu.tar.gz ; \
        apk add --no-cache gcompat ; \
    else \
        echo "Unsupported architecture: ${ARCH}" && exit 1; \
    fi && \
    mkdir /tmp/build && \
    tar -xzf kcptun.tar.gz -C /tmp/build && \
    tar -xf shadowsocks.tar.xz -C /tmp/build && \
    mkdir /tmp/horust-build && \
    tar -xzf horust.tar.gz -C /tmp/horust-build && \
    mv /tmp/build/${KCP_BINARY} /daemon/kcp-local && \
    mv /tmp/build/${SS_BINARY} /daemon/sss-local && \
    mv /tmp/horust-build/horust /usr/bin/horust && \
    rm kcptun.tar.gz shadowsocks.tar.xz horust.tar.gz && \
    rm -rf /tmp/build /tmp/horust-build && \
    chmod +x /daemon/* /usr/bin/horust

# Copy startup script
COPY start.sh /daemon/start.sh
RUN chmod +x /daemon/start.sh

ARG BUILD_PORT=1080
ENV LOCAL_PORT=${BUILD_PORT}
# Expose necessary ports
EXPOSE ${BUILD_PORT}/tcp
EXPOSE ${BUILD_PORT}/udp

# Use start.sh as the entry point to dynamically configure Horust services
CMD ["/daemon/start.sh"]
