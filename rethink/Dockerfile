FROM node:20-alpine

RUN apk add --no-cache git openssl jq bash

# Clone rethink source and apply local patches pending upstream merge.
RUN git clone https://github.com/anszom/rethink /app && \
    cd /app && \
    # PR #82: add RAC_0B0001_WW as alias for RAC_056905_WW handler
    # https://github.com/anszom/rethink/pull/82
    sed -i "s/RAC_056905_WW,/RAC_056905_WW,\n    ['RAC_0B0001_WW']: RAC_056905_WW,/" cloud/ha_bridge.ts && \
    # PR #84: remove hardcoded pathname='/' so WebSocket and fetch calls use the
    # correct base path when served through a reverse proxy (e.g. HA ingress).
    # https://github.com/anszom/rethink/pull/84
    sed -i "/baseUrl\.pathname = '\//d" html/panel.js html/monitor.js && \
    sed -i "s|href=\"/monitor|href=\"monitor|g" html/panel.js && \
    npm install && \
    npm run build

COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
