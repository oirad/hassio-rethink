# rethink – LG ThinQ Local Server

Runs [rethink](https://github.com/anszom/rethink) as a native Home Assistant add-on. Replaces LG's ThinQ cloud entirely: AC units connect to this add-on instead of LG's servers, and their state is published to Home Assistant via MQTT auto-discovery. No internet access required after initial setup.

Tested with LG wall-mount AC units using the `RTK_RTL8720cm` Wi-Fi module (`clip_ble_v1.9.223`, `protocolVer: 4.9`, `deviceType: 401`).

---

## Prerequisites

Before installing this add-on you need:

- **Mosquitto broker** add-on (handles MQTT between rethink and HA)
- **AdGuard Home** add-on _or_ a router capable of custom DNS rewrites (see [DNS setup](#dns-setup))
- A Wi-Fi capable laptop or desktop for the one-time provisioning step per device
- Node.js ≥ 20 on the provisioning machine (`brew install node` on macOS)

---

## Step 1 — Install and configure Mosquitto

Install the **Mosquitto broker** add-on from the HA Add-on Store.

In the Mosquitto **Configuration** tab, add a dedicated user for rethink:

```yaml
logins:
  - username: rethink
    password: changeme
```

Start Mosquitto. When prompted, accept the **auto-discovered MQTT integration** that HA offers.

> If rethink loses its MQTT connection after a HA update or restart, re-add the `logins` entry — it can be reset by the add-on.

---

## Step 2 — DNS setup

LG devices resolve `common.lgthinq.com` and `rethink.lgthinq.com` via DNS. Both must resolve to your HA machine's IP address. There are two ways to achieve this.

### Option A — AdGuard Home (recommended)

Install the **AdGuard Home** add-on from the HA Add-on Store. Open its web UI via the "Open Web UI" button (not port 3000 directly — HAOS proxies it).

1. Set admin credentials on first launch
2. Go to **Filters → DNS rewrites** and add:
   - `common.lgthinq.com` → `<your HA IP>`
   - `rethink.lgthinq.com` → `<your HA IP>`
3. Go to **Settings → DNS settings → Access settings** and set **Allowed clients** to `0.0.0.0/0` so devices on other VLANs can query it

Then configure your IoT network's DHCP to hand out your HA machine's IP as the primary DNS server. This is done in your router's DHCP settings for the relevant network or VLAN.

### Option B — Router DNS rewrites

If your router supports custom DNS host overrides or local DNS records (common in OpenWrt, pfSense, OPNsense, and similar), add two A records pointing both `common.lgthinq.com` and `rethink.lgthinq.com` to your HA machine's IP.

Make sure the IoT network's DHCP server hands out the router as the DNS server, and that the router forwards queries it cannot answer to an upstream resolver.

> **Note:** Some consumer routers only support custom DNS for their own domain suffix and cannot override public domains like `lgthinq.com`. If your router does not support this, use AdGuard Home.

---

## Step 3 — Install this add-on

Copy the `rethink` folder from this repository into `/addons/` on your HAOS machine (accessible via the Samba share add-on), then:

1. Run `ha supervisor reload` from the SSH terminal
2. Go to **Settings → Add-ons → Add-on Store → ⋮ → Check for updates**
3. Install **rethink – LG ThinQ Local Server** from the **Local** section

### Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `hostname` | `rethink.lgthinq.com` | DNS name used in TLS certificate generation. Must match what `common.lgthinq.com` and `rethink.lgthinq.com` resolve to. Must be a real DNS name — IP addresses do not work. |
| `direct_access` | `false` | When disabled, the management UI is only accessible via the HA sidebar. When enabled, it is also reachable directly at port 44401. |

Start the add-on after saving the configuration.

---

## Step 4 — Provision each AC unit

Provisioning is a one-time step per device performed from a Wi-Fi capable machine. You will need the [rethink-setup](https://github.com/anszom/rethink) script from the upstream repository.

```bash
git clone https://github.com/anszom/rethink ~/rethink-setup
cd ~/rethink-setup
npm install
```

**For each unit:**

1. Enter Wi-Fi setup mode on the indoor unit (hold the Wi-Fi button on the unit or use the remote — the LED blinks rapidly when ready)
2. On your laptop, connect to the open Wi-Fi network broadcast by the unit. It will be named `LGE_AC2_open` or similar — **not** the network that includes your unit's MAC address
3. Run the provisioning script:
   ```bash
   npx tsx rethink-setup.ts 192.168.120.254 YOUR_SSID 'YOUR_PASSWORD'
   ```
   > Use single quotes around the Wi-Fi password if it contains `!` or other shell-special characters
4. The unit beeps and reconnects to your Wi-Fi network
5. Confirm it appears in the rethink management UI (accessible from the HA sidebar)

The expected provisioning output ends with:

```
{ cmd: 'setDeviceInfo', data: { protocolVer: '4.9', ... encrypt_val: '...', ... } }
{ cmd: 'setCertInfo',   data: { result: '000', ... } }
{ cmd: 'setApInfo',     data: { result: '000', ... } }
{ cmd: 'releaseDev',    data: { result: '000', ... } }
Setup completed, the device will now connect to your Wi-Fi
ThinQ2 setup successful, see rethink-cloud logs for a follow-up
```

HA will auto-discover the device via MQTT shortly after. No restart required.

---

## Management UI

The rethink management panel is available directly from the HA sidebar. It shows connected devices, their model IDs, and live packet monitoring per device.

To also allow direct browser access at `http://<HA IP>:44401/`, enable the **Direct access** toggle in the add-on Configuration tab and restart.

---

## Troubleshooting

### Device does not appear in rethink after provisioning

Check DNS first. From the provisioning machine (connected to the IoT network), verify:

```bash
nslookup common.lgthinq.com
```

It must resolve to your HA machine's IP. If it resolves to an LG server, DNS rewrites are not reaching the device.

### Provisioning fails with `encrypt_val: ''` and `encryptRes:ffff`

The `RTK_RTL8720cm` firmware has a strict PEM parser that rejects indented base64 content in the `rethink-setup.ts` certificate template. Apply the fix from [PR #81](https://github.com/anszom/rethink/pull/81) to your local copy of `rethink-setup.ts`: remove the leading whitespace (tabs) from lines 76–83 inside the `publicKey` template literal.

### Device connects but no HA entities appear

Check the rethink logs in the add-on Log tab. If you see:

```
thinq2 device type XYZ unknown
```

The device model is not yet supported. Check whether it can be aliased to an existing handler in `cloud/ha_bridge.ts` — see [PR #82](https://github.com/anszom/rethink/pull/82) for an example.

### rethink loses MQTT connection to HA

Re-add the `rethink` user in the Mosquitto add-on Configuration tab. The `logins` field can be silently reset after add-on updates.

### Device connected but telemetry stops updating

Power-cycle the AC unit. It will re-fetch its certificates from port 443 and re-establish the MQTTS session on port 8885.
