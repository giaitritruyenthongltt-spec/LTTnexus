# Building LTT Nexus on Windows (reproducible recipe)

This is the exact toolchain that produced a working `LTTNexus` client from this
fork of RustDesk 1.4.9. Versions are pinned to RustDesk's own CI
(`.github/workflows/flutter-build.yml`); the two starred items are where a naive
setup silently fails.

## Toolchain (pinned)

| Tool | Version | Notes |
|---|---|---|
| Rust | stable, `x86_64-pc-windows-msvc` host | via rustup |
| VS 2022 Build Tools | VCTools workload + Windows 11 SDK (10.0.26100) | provides `cl.exe`, linker |
| **libclang** ★ | **15.0.6** | bindgen 0.65 mis-parses aom structs with newer libclang |
| Flutter | **3.24.5** | Windows desktop stays on this in CI |
| vcpkg | commit `120deac3062162151622ca4860575a33844ba10b` | baseline in `vcpkg.json` |
| frb codegen | **1.80.1**, feature `uuid` | matches `flutter_rust_bridge = "=1.80"` |

## ★ libclang must be ~15, not latest

bindgen 0.65 (used by `scrap`) with a modern libclang (18/19/22) emits aom's
`aom_codec_enc_cfg` / `aom_codec_dec_cfg` as **opaque stubs** (`pub _address: u8`),
so the build dies with dozens of `no field 'g_w' on aom_codec_enc_cfg`. Get a
15.x libclang without admin via the bundled pip wheel:

```
pip install --target=<dir> libclang==15.0.6.1
# libclang.dll lands at <dir>/clang/native/libclang.dll
export LIBCLANG_PATH="<dir>\clang\native"
```

After changing `LIBCLANG_PATH`, force the bindgen crate to regenerate — an env
change alone does not invalidate cargo's cache: `cargo clean -p scrap`.

## vcpkg dependencies (static, with RustDesk's overlay ports)

RustDesk patches its codec ports (`res/vcpkg`), so the overlay is mandatory.
Built without `--hwcodec`, so ffmpeg/mfx-dispatch are omitted (software codecs):

```
export VCPKG_ROOT="D:\vcpkg"
vcpkg install --overlay-ports=<repo>/res/vcpkg \
  aom:x64-windows-static libvpx:x64-windows-static libyuv:x64-windows-static \
  opus:x64-windows-static libjpeg-turbo:x64-windows-static
```

`build.rs` reads `VCPKG_ROOT` (panics if unset). `.cargo/config.toml` already
sets `+crt-static`, matching the `-static` triplet.

## Build steps (order matters)

```
# 1. Pre-fetch all deps ONCE online. frb codegen runs `cargo metadata`, which
#    fetches git-submodule deps (freetype2/libpng/zlib); doing it first avoids
#    a mid-codegen network flake.
cargo fetch

# 2. flutter pub get BEFORE codegen (frb's ffigen needs resolved dart deps)
cd flutter && flutter pub get && cd ..

# 3. generate the dart<->rust bridge
flutter_rust_bridge_codegen \
  --rust-input ./src/flutter_ffi.rs \
  --dart-output ./flutter/lib/generated_bridge.dart \
  --c-output ./flutter/macos/Runner/bridge_generated.h

# 4. build the rust lib, then the flutter app
cargo build --locked --features flutter --lib --release
cd flutter && flutter build windows --release
```

## Output

`flutter/build/windows/x64/runner/Release/` — `rustdesk.exe` (launcher) +
`librustdesk.dll` (30 MB, all logic) + flutter plugin DLLs. Ship the whole
folder. Verified: `rustdesk.exe --version` → `1.4.9`; `--get-id` returns an ID
under `%APPDATA%\LTTNexus`; the DLL contains the baked LTT server/key/app-name.

The launcher exe is still named `rustdesk.exe` (flutter runner target name, in
`flutter/windows/runner/CMakeLists.txt` + `Runner.rc`) — renaming it is a
pending branding item, separate from `APP_NAME`.

---

## Đóng gói file cài MỘT-FILE (cho tự cập nhật)

Bản zip không tự cập nhật được: không ghi đè được exe đang chạy, và không biết
người dùng để thư mục ở đâu. RustDesk đã có sẵn trình đóng gói tự-giải-nén —
dùng lại nó thay vì thêm Inno Setup.

```bash
# 1. build ứng dụng như bình thường (xem phần trên) -> flutter/build/windows/...
# 2. sinh dữ liệu nhúng
cd libs/portable
pip install -r requirements.txt          # brotli
python generate.py \
  -f ../../flutter/build/windows/x64/runner/Release/ \
  -o . \
  -e ../../flutter/build/windows/x64/runner/Release/LTTNexus.exe

# 3. build gói tự-giải-nén (ra ~22MB, nhỏ hơn zip)
cargo build --release
# -> target/release/rustdesk-portable-packer.exe
mv ../../target/release/rustdesk-portable-packer.exe \
   ../../dist/LTTNexus-<ver>-win-x64-setup.exe
```

**Vì sao dùng được cho tự cập nhật:** gói tự-giải-nén **chuyển tiếp tham số**
xuống exe bên trong, nên `LTTNexus-<ver>-win-x64-setup.exe --silent-install`
chạy đúng đường cài sẵn có của bản gốc (`core_main.rs`), tự đè lên bản đang cài.

**Phát hành:** thả file vào `data/nexus_dist/` trên máy chủ rồi khai trong
`data/nexus_versions.json`:

```json
"windows": {
  "url": "/nexus/dl/LTTNexus-<ver>-win-x64.zip",
  "sha256": "...",
  "setup_url": "/nexus/dl/LTTNexus-<ver>-win-x64-setup.exe",
  "setup_sha256": "..."
}
```

Thiếu `setup_url` thì client **không** rơi về zip — nó báo "bản này chưa có file
cài tự động". Đoán bừa là hỏng ngầm.
