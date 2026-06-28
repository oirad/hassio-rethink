# hassio-rethink

Home Assistant OS add-on for [rethink](https://github.com/anszom/rethink) — a fully local replacement for LG's ThinQ cloud. LG AC units are re-provisioned to connect to this add-on instead of LG's servers. Device state is published to Home Assistant via MQTT auto-discovery. No internet access required after initial setup.

Tested with LG wall-mount AC units using the `RTK_RTL8720cm` Wi-Fi module (`clip_ble_v1.9.223`, `protocolVer: 4.9`, `deviceType: 401`), models EZ09CSNCSJ1, EZ12CSUCA31, EZ12CSNNCSJ1.

## Installation

1. In Home Assistant, go to **Settings → Add-ons → Add-on Store → ⋮ → Repositories**
2. Add this repository URL:
   ```
   https://github.com/oirad/hassio-rethink
   ```
3. Install **rethink – LG ThinQ Local Server** from the store

## Documentation

See the [add-on documentation](rethink/DOCS.md) for full setup instructions, including DNS configuration, device provisioning, and troubleshooting.

## Patches applied to upstream

This add-on builds rethink from source and applies the following patches pending upstream merge:

- [PR #82](https://github.com/anszom/rethink/pull/82) — add `RAC_0B0001_WW` as alias for `RAC_056905_WW` handler
- [PR #84](https://github.com/anszom/rethink/pull/84) — make management UI path-independent for reverse proxy compatibility (HA ingress)

## License

GPL-2.0 — see [LICENSE](LICENSE). This add-on builds and runs rethink, which is also GPL-2.0.
