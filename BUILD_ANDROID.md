# Build LTT Nexus cho Android (APK arm64)

Build Android của RustDesk **chỉ chạy trên Linux** (`flutter/build_android_deps.sh`
hardcode `HOST_TAG=linux-x86_64`; CI upstream chạy Ubuntu). Trên máy Windows này
ta build trong **WSL Ubuntu**.

Kết quả: `flutter/build/app/outputs/flutter-apk/app-release.apk` (~26 MB, arm64,
đã ký bằng keystore self-signed → cài được ngoài Play Store cho nội bộ).

> Cấu hình relay/khoá LTT (`RENDEZVOUS_SERVERS`, `RS_PUB_KEY`, `APP_NAME`) nằm ở
> `libs/hbb_common/src/config.rs` — **được biên dịch thẳng vào `.so`**, nên APK
> tự trỏ relay LTT. Nhãn/gói hiển thị vẫn là mặc định RustDesk
> (`com.carriez.flutter_hbb` / "RustDesk") — đổi thương hiệu Android là việc
> *tinh chỉnh sau*, không ảnh hưởng chức năng.

## Toolchain (pin theo `.github/workflows/flutter-build.yml`)

| Thành phần | Phiên bản | Ghi chú |
|---|---|---|
| Rust | **1.75** | RustDesk `rust-toolchain.toml` pin; mới hơn vỡ |
| Android NDK | **r28c** | `/opt/android-ndk-r28c` |
| cargo-ndk | **3.1.2** | `cargo install cargo-ndk --version 3.1.2` |
| Flutter | 3.24.5 (linux) | `/opt/flutter` |
| JDK | 17 | cho Gradle |
| Android SDK | platform-34, build-tools 34.0.0 | |
| libclang | **15.0.6** | bindgen 0.65 vỡ với bản mới (aom) |
| flutter_rust_bridge_codegen | 1.80.1 (feature `uuid`) | |
| vcpkg | `120deac3` triplet `arm64-android` | openssl cho android |

## Bẫy đã giải (mỗi cái từng chặn build)

1. **DNS WSL hỏng** → `/etc/wsl.conf`: `generateResolvConf=false` +
   `appendWindowsPath=false`; `/etc/resolv.conf` = `nameserver 8.8.8.8`;
   `wsl --shutdown` rồi mở lại. (`appendWindowsPath=false` cũng tránh PATH Windows
   có dấu cách/`(x86)` làm hỏng script.)
2. **rustfmt thiếu** (profile minimal) → `rustup component add rustfmt` (frb cần).
3. **openssl-sys không vendored** cho android (native-tls kéo qua hbb_common; kể cả
   Rust 1.75 vẫn không unify được feature vendored). Giải: build openssl android
   bằng vcpkg rồi trỏ **target-scoped**:
   ```
   vcpkg install openssl --triplet arm64-android --x-install-root=$VCPKG_ROOT/installed
   export AARCH64_LINUX_ANDROID_OPENSSL_DIR=$VCPKG_ROOT/installed/arm64-android
   export AARCH64_LINUX_ANDROID_OPENSSL_STATIC=1
   ```
   **KHÔNG** dùng `OPENSSL_DIR` global — nó áp cả build-script chạy trên host,
   link nhầm openssl arm64 vào binary x86_64 → *"Relocations in generic ELF
   EM:183, wrong format"*. Host cần openssl riêng: `apt install libssl-dev`.
4. **kcp-sys bindgen** dùng `/usr/include` của host (`__float128` không hỗ trợ) →
   thêm cờ `--bindgen` cho `cargo ndk` (đặt sysroot NDK cho bindgen).
5. **SDK `--licenses` treo** → ghi thẳng hash license vào
   `$ANDROID_HOME/licenses/android-sdk-license` rồi chạy `sdkmanager` FOREGROUND
   (nohup qua WSL interop hay rớt).
6. **Gradle thiếu signing "release"** → tạo keystore self-signed + `key.properties`
   (xem dưới). Nội bộ dùng self-signed là đủ; Play Store mới cần ký chính thức.

## Cách build (script gọn ở `flutter/../` — chạy trong WSL, user root)

```bash
# clone fork vào WSL (hoặc dùng /mnt/d/LTTnexus)
git clone -b ltt-nexus https://github.com/giaitritruyenthongltt-spec/LTTnexus /opt/LTTnexus
cd /opt/LTTnexus

export ANDROID_HOME=/opt/android-sdk ANDROID_SDK_ROOT=/opt/android-sdk
export ANDROID_NDK_HOME=/opt/android-ndk-r28c ANDROID_NDK=/opt/android-ndk-r28c
export VCPKG_ROOT=/opt/vcpkg
export LIBCLANG_PATH=/opt/llvm15/clang/native
export AARCH64_LINUX_ANDROID_OPENSSL_DIR=$VCPKG_ROOT/installed/arm64-android
export AARCH64_LINUX_ANDROID_OPENSSL_STATIC=1
export PATH="/opt/flutter/bin:$HOME/.cargo/bin:$ANDROID_HOME/platform-tools:$PATH"

( cd flutter && flutter pub get )
cargo fetch
# bridge (nếu chưa có flutter/lib/generated_bridge.dart)
CARGO_NET_OFFLINE=true flutter_rust_bridge_codegen \
  --rust-input ./src/flutter_ffi.rs \
  --dart-output ./flutter/lib/generated_bridge.dart \
  --c-output ./flutter/macos/Runner/bridge_generated.h

# lib native arm64 (LƯU Ý: --bindgen để dùng sysroot NDK)
cargo ndk --bindgen --platform 21 --target aarch64-linux-android build --locked --release --features flutter,hwcodec
mkdir -p flutter/android/app/src/main/jniLibs/arm64-v8a
cp target/aarch64-linux-android/release/liblibrustdesk.so \
   flutter/android/app/src/main/jniLibs/arm64-v8a/librustdesk.so

# APK
( cd flutter && flutter build apk --release --target-platform android-arm64 )
```

## Ký (self-signed, cho nội bộ)

`flutter/android/key.properties` (KHÔNG commit — chứa mật khẩu keystore):

```properties
storePassword=<mat-khau>
keyPassword=<mat-khau>
keyAlias=ltt-nexus
storeFile=/duong/dan/ltt-nexus.keystore
```

Tạo keystore:
```bash
keytool -genkeypair -v -keystore ltt-nexus.keystore -alias ltt-nexus \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -dname "CN=LTT Nexus, O=LTT Studios, C=VN" -storepass <mat-khau> -keypass <mat-khau>
```

`flutter/android/app/build.gradle` đã đọc `key.properties` cho `signingConfigs.release`.

## Việc tinh chỉnh sau (không chặn dùng nội bộ)

- Đổi thương hiệu Android: `applicationId`, `android:label`, icon → "LTT Nexus".
- Thêm ABI `armeabi-v7a` / `x86_64` nếu cần máy cũ / giả lập.
- Ký chính thức khi lên Play Store (self-signed không lên store được).
