# Use a smaller base image
FROM alpine:3.18

# Install necessary packages, including supervisor
RUN apk add --no-cache supervisor bash

# Create supervisord configuration directory
RUN mkdir -p /daemon/
RUN mkdir -p /etc/supervisor/conf.d

# Download and install KCP server and shadowsocks binaries
RUN \
    ARCH=$(arch) ; \
    if [ "${ARCH}" = "x86_64" ] ; then \
        KCP_BINARY="server_linux_amd64"; \
        SS_BINARY="ssserver"; \
        wget -q -O kcptun.tar.gz https://github.com/xtaci/kcptun/releases/download/v20250427/kcptun-linux-amd64-20250427.tar.gz ; \
        wget -q -O shadowsocks.tar.xz https://github.com/shadowsocks/shadowsocks-rust/releases/download/v1.23.4/shadowsocks-v1.23.4.x86_64-unknown-linux-musl.tar.xz ; \
    elif [ "${ARCH}" = "arm64" ] ; then \
        KCP_BINARY="server_linux_arm64"; \
        SS_BINARY="ssserver"; \
        wget -q -O kcptun.tar.gz https://github.com/xtaci/kcptun/releases/download/v20250427/kcptun-linux-arm64-20250427.tar.gz ; \
        wget -q -O shadowsocks.tar.xz https://github.com/shadowsocks/shadowsocks-rust/releases/download/v1.23.4/shadowsocks-v1.23.4.aarch64-unknown-linux-musl.tar.xz ; \
    else \
        echo "Unsupported architecture: ${ARCH}" && exit 1; \
    fi && \
    tar -xzf kcptun.tar.gz -C /daemon/ && \
    tar -xf shadowsocks.tar.xz -C /daemon/ && \
    rm kcptun.tar.gz shadowsocks.tar.xz && \
    chmod +x /daemon/${KCP_BINARY} && \
    mv /daemon/${KCP_BINARY} /daemon/kcp-server && \
    chmod +x /daemon/${SS_BINARY} && \
    mv /daemon/${SS_BINARY} /daemon/sss-server

# Copy supervisord configuration file
COPY supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY etc/supervisor/conf.d/* /etc/supervisor/conf.d/
COPY daemon/* /daemon/
ARG BUILD_PORT=5940
ENV KCP_SERVER_PORT=${BUILD_PORT}
# Expose necessary ports
EXPOSE ${BUILD_PORT}/udp

# Set supervisord as the entry point
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]