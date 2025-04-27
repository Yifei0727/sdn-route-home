# Use a smaller base image
FROM alpine:3.18

# Install necessary packages, including supervisor
RUN apk add --no-cache supervisor bash

# Create supervisord configuration directory
RUN mkdir -p /daemon/
RUN mkdir -p /etc/supervisor/conf.d

# Copy supervisord configuration file
COPY etc/supervisor/supervisord.conf /etc/supervisor/supervisord.conf
COPY daemon/* /daemon/

ENV ENV_KCP_SERVER_PORT=5940
# Expose necessary ports
EXPOSE 5940/udp

# Set supervisord as the entry point
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]