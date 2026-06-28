#!/bin/bash
set -e

OPTIONS="/data/options.json"
CONFIG="/data/config.json"

# Ensure persistent data dir exists (HAOS maps /data as the add-on's
# persistent volume; certs and state go here so they survive restarts).
mkdir -p /data/state

HOSTNAME=$(jq -r '.hostname' "$OPTIONS")

# Write config on every start so option changes are picked up.
cat > "$CONFIG" <<EOF
{
  "hostname": "${HOSTNAME}",
  "homeassistant": {
    "mqtt_url": "mqtt://rethink:changeme@localhost:1883",
    "discovery_prefix": "homeassistant",
    "rethink_prefix": "rethink",
    "mqtt_user": "",
    "mqtt_pass": ""
  },
  "ca_key_file": "/data/ca.key",
  "ca_cert_file": "/data/ca.cert",
  "https_port": 443,
  "mqtts_port": 8885,
  "mqtt_port": 1885,
  "thinq1_https_port": 46030,
  "thinq1_port": 47878,
  "management_port": 44401,
  "bridge": {
    "storage_path": "/data/state"
  },
  "log": ["status", "incoming", "HTTPS", "publish", "MGMT"]
}
EOF

echo "[rethink] Starting with hostname=${HOSTNAME}"
exec node /app/dist/rethink-cloud.js "$CONFIG"
