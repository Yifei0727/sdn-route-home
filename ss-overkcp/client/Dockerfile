# Use a smaller base image
FROM alpine:3.18

LABEL org.opencontainers.image.source=https://github.com/Yifei0727/sdn-route-home
LABEL org.opencontainers.image.description="A KCP Tunnel for Shadowsocks server Docker image"
LABEL org.opencontainers.image.licenses=MIT

# Install necessary packages, including supervisor
RUN apk add --no-cache supervisor bash

# Create supervisord configuration directory
RUN mkdir -p /daemon/
RUN mkdir -p /etc/supervisor/conf.d
RUN mkdir -p /var/log/supervisor/

# Download and install KCP server and shadowsocks binaries
RUN \
    ARCH=$(arch) ; \
    if [ "${ARCH}" = "x86_64" ] ; then \
        KCP_BINARY="client_linux_amd64"; \
        SS_BINARY="sslocal"; \
        wget -q -O kcptun.tar.gz https://github.com/xtaci/kcptun/releases/download/v20250427/kcptun-linux-amd64-20250427.tar.gz ; \
        wget -q -O shadowsocks.tar.xz https://github.com/shadowsocks/shadowsocks-rust/releases/download/v1.23.4/shadowsocks-v1.23.4.x86_64-unknown-linux-musl.tar.xz ; \
    elif [ "${ARCH}" = "arm64" ] || [ "${ARCH}" = "aarch64" ] ; then \
        KCP_BINARY="client_linux_amd64"; \
        SS_BINARY="sslocal"; \
        wget -q -O kcptun.tar.gz https://github.com/xtaci/kcptun/releases/download/v20250427/kcptun-linux-arm64-20250427.tar.gz ; \
        wget -q -O shadowsocks.tar.xz https://github.com/shadowsocks/shadowsocks-rust/releases/download/v1.23.4/shadowsocks-v1.23.4.aarch64-unknown-linux-musl.tar.xz ; \
    else \
        echo "Unsupported architecture: ${ARCH}" && exit 1; \
    fi && \
    mkdir /tmp/build && \
    tar -xzf kcptun.tar.gz -C /tmp/build && \
    tar -xf shadowsocks.tar.xz -C /tmp/build && \
    mv /tmp/build${KCP_BINARY} /daemon/kcp-client && \
    mv /tmp/build${SS_BINARY} /daemon/sss-local && \
    rm kcptun.tar.gz shadowsocks.tar.xz && \
    rm -rf /tmp/build  && \
    chmod +x /daemon/${SS_BINARY} && \
    chmod +x /daemon/${KCP_BINARY}

# Copy supervisord configuration file
COPY supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY supervisor/conf.d/*         /etc/supervisor/conf.d/
ARG BUILD_PORT=1080
ENV LOCAL_PORT=${BUILD_PORT}
# Expose necessary ports
EXPOSE ${BUILD_PORT}/tcp
EXPOSE ${BUILD_PORT}/udp

# Set supervisord as the entry point
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]