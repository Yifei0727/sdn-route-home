#!/bin/bash
# Startup script for the ss-overkcp client.
# Dynamically generates Horust service files based on SSS_SERVER (comma-separated list).
# Each server entry gets its own kcp-client process; sss-local connects to all of them.
set -euo pipefail

SERVICES_DIR=/etc/horust/services
mkdir -p "$SERVICES_DIR"

# Parse SSS_SERVER (comma-separated list of host:port)
IFS=',' read -ra SERVERS <<< "${SSS_SERVER}"

KCP_PORT_BASE=12948
SERVER_JSON_ENTRIES=""
DEPS=""

for i in "${!SERVERS[@]}"; do
    SERVER=$(echo "${SERVERS[$i]}" | tr -d '[:space:]')
    KCP_PORT=$((KCP_PORT_BASE + i))
    SVC_NAME="kcp-client-${i}"

    # Create Horust service file for this kcp-client instance
    cat > "$SERVICES_DIR/${SVC_NAME}.toml" << TOML
command = "/daemon/kcp-client -r ${SERVER} -l :${KCP_PORT}"

[restart]
strategy = "always"
TOML

    # Append server entry for the shadowsocks JSON config
    if [ -n "$SERVER_JSON_ENTRIES" ]; then
        SERVER_JSON_ENTRIES="${SERVER_JSON_ENTRIES},"
    fi
    SERVER_JSON_ENTRIES="${SERVER_JSON_ENTRIES}
        {\"server\":\"127.0.0.1\",\"server_port\":${KCP_PORT},\"password\":\"${SSS_PASSWORD}\",\"method\":\"aes-256-gcm\"}"

    # Build start-after dependency list for sss-local
    if [ -n "$DEPS" ]; then
        DEPS="${DEPS}, "
    fi
    DEPS="${DEPS}\"${SVC_NAME}.toml\""
done

# Write shadowsocks local config referencing all kcp-client local ports
cat > /tmp/sss-local.json << JSON
{
    "local_address": "0.0.0.0",
    "local_port": ${LOCAL_PORT},
    "servers": [${SERVER_JSON_ENTRIES}
    ]
}
JSON

# Create Horust service file for sss-local (starts after all kcp-clients are running)
cat > "$SERVICES_DIR/sss-local.toml" << TOML
command = "/daemon/sss-local -c /tmp/sss-local.json -U -vvv --tcp-no-delay"
start-after = [${DEPS}]

[restart]
strategy = "always"
TOML

exec /usr/bin/horust
