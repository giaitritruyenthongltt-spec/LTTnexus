# LTT Nexus — hbbs fork (relay-side billing enforcement)

This is a **modified fork of [rustdesk-server](https://github.com/rustdesk/rustdesk-server)**
(the `hbbs` rendezvous server), licensed **AGPL-3.0** like upstream. Because users
interact with the modified server over a network, AGPL §13 requires the
Corresponding Source of the modification to be available — **this tree is it.**

## Base

- Fork of `rustdesk/rustdesk-server` at tag **`1.1.16`** (the version LTT runs on
  its gateway relay, Q96).
- `hbb_common` submodule absorbed at its pinned commit for a self-contained tree.

## What LTT changed (one commit)

**`ltt_relay_allowed` gate in `handle_punch_hole_request`** (`src/rendezvous_server.rs`).
Before hbbs brokers a connection to a target ID, it asks the LTT platform whether
that ID's account is still paid (Q98 subscription). If not, it returns a
`PunchHoleResponse` with `other_failure` = "hết credit". This is the **real teeth**
of billing: a modified/patched client cannot bypass it, because the relay itself
refuses to broker.

Two deliberate safety layers:

- **Off by default** — with `LTT_NEXUS_RELAY_CHECK_URL` unset, the gate always
  allows, so the relay behaves exactly like stock until an operator enables it.
- **Fail-open** — any network/parse error allows the connection. hbbs only
  refuses when the platform explicitly answers `"allowed":false`. The relay never
  goes dark because the platform had a blip.

## Deploy (operator, on the gateway — production action)

1. Build: `cargo build --release --bin hbbs` (Rust + MSVC; no vcpkg/Flutter).
2. Stop the `hbbs` service, replace `hbbs.exe` with this build, keep the same
   `-k <key>` / data dir.
3. Set env for the `hbbs` service (via NSSM / service env):
   - `LTT_NEXUS_RELAY_CHECK_URL=https://app.lttstudios.com/nexus-agent/relay-check`
   - `LTT_NEXUS_RELAY_SECRET=<shared secret>` (same value as the platform's
     `LTT_NEXUS_RELAY_SECRET` in `secrets/app.env`)
4. Start `hbbs`. Verify a paid machine still connects; an unpaid one gets the
   "hết credit" message.

Leave the two env vars unset to run exactly like stock (enforcement off).

*The proprietary LTT platform and the LTT Nexus client are separate programs;
this fork only talks to the platform over HTTP.*
