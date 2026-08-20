# LTT Nexus — modified fork of RustDesk

**LTT Nexus** is a remote-desktop client/engine that Giải Trí Truyền Thông LTT
distributes to its users as part of the LTT platform. It is a **modified fork of
[RustDesk](https://github.com/rustdesk/rustdesk)** and is therefore licensed
under the **GNU Affero General Public License v3.0** (AGPL-3.0), the same license
as upstream. See [`LICENCE`](LICENCE).

Because users interact with this modified program over a network, AGPL-3.0 §13
requires the **Corresponding Source of the modified version** to be offered to
those users. **This repository is that Corresponding Source.**

## Base

| Component | Upstream | Pinned commit |
|---|---|---|
| rustdesk/rustdesk | https://github.com/rustdesk/rustdesk | `6c578292e8ebbbec708b76986ba8c4bc7c509747` (tag `1.4.9`) |
| rustdesk/hbb_common | https://github.com/rustdesk/hbb_common | `7e1c392c62d39c364127307cd408421dd5f8cfb0` |

The `hbb_common` submodule has been **absorbed into this tree** at its pinned
commit so the published source is self-contained. Every LTT change after that is
a separate, reviewable commit on top of `1.4.9`.

## What LTT changed (and why)

Each item below is a distinct commit; run `git log 1.4.9..ltt-nexus` for the
authoritative list.

- **Config → LTT infrastructure.** Default rendezvous server and public key point
  at LTT's own relay instead of RustDesk's public servers.
- **Branding.** Product name `RustDesk` → `LTTNexus` (RustDesk's built-in
  white-label substitution carries it through the UI; `is_rustdesk()`-gated
  rustdesk.com features switch off).
- *(in progress)* UI theme, session indicator, feature trimming, Vietnamese
  localization, and an LTT ticket-based auto-connect flow.

## Relationship to the LTT platform (license boundary)

The **LTT Nexus Agent** — the component that enrolls a machine, keeps presence,
and rotates this engine's password per session — is a **separate, independent
program**. It drives this engine only as an external process (subprocess +
command-line / on-disk config), never by linking or copying AGPL code into
itself. That process boundary is deliberate: it is both a security boundary and
the license boundary that keeps the Agent outside AGPL's copyleft while this
fork remains fully AGPL and fully published here.

## Building

See RustDesk's upstream build instructions (`build.py`, `.github/workflows`).
The LTT changes do not alter the build procedure.
