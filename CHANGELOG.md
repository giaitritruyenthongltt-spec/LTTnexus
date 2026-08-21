# Nhật ký phát hành — LTT Nexus

Phiên bản ở đây là **phiên bản LTT** (`LTT_VERSION` trong `src/nexus_client.rs`),
khác với phiên bản RustDesk gốc (1.4.9). Client so số này với `manifest.version`
ở `https://app.lttstudios.com/nexus/version.json` để biết có bản mới.

## Quy tắc (đặt ra sau khi 1.0.0 bị ghi đè một lần)

Mỗi lần phát hành **phải** làm đủ bốn việc, theo thứ tự:

1. Tăng `LTT_VERSION` trong `src/nexus_client.rs` (semver: sửa lỗi → patch,
   thêm tính năng → minor).
2. Thêm một mục vào file này, viết theo *người dùng thấy gì*, không phải theo commit.
3. Build lại, đặt tên file kèm **đúng** số phiên bản đó
   (`LTTNexus-<ver>-win-x64.zip`, `LTTNexus-<ver>-android-arm64.apk`).
4. Cập nhật `data/nexus_versions.json` trên máy chủ (URL + SHA-256 + `version`),
   rồi kiểm `https://app.lttstudios.com/nexus/version.json`.

**Không bao giờ ghi đè một bản đã phát hành.** Tên file có version, và biên
Cloudflare cache `immutable` — ghi đè thì người tải sau vẫn nhận bản cũ, còn
client thì không thấy có bản mới nên không nhắc cập nhật.

---

## 1.1.0 — 2026-08-21

**Onboarding 1-chạm.** Đăng nhập xong là thấy ngay danh sách máy của tài khoản
với chỉ báo đang bật, bấm một cái là kết nối — không phải gõ tay ID nữa. Có trên
cả Windows và Android.

**Thương hiệu LTT Studios thật.** Icon mới cho mọi nền tảng (Windows/macOS/iOS/
Android). Trên Android app nay tên là **LTT Nexus** (trước hiện "RustDesk") và
danh tính cài đặt đổi thành `com.lttstudios.nexus`.

**Chắc chắn hơn.** Thêm test cho phần mã LTT: 10 test Rust (chữ ký, base64, so
sánh phiên bản), 7 test Dart (lọc/sắp xếp danh sách máy, chịu được JSON hỏng),
4 test cho phần cưỡng chế thu phí ở relay.

> Nâng cấp từ 1.0.0: Android đổi `applicationId` nên bản mới cài **cạnh** bản cũ
> chứ không đè lên. Gỡ bản cũ ("RustDesk") sau khi đăng nhập lại ở bản mới.

## 1.0.0 — 2026-08-21

Bản phát hành đầu tiên: fork RustDesk 1.4.9 mang thương hiệu LTT, dùng relay
riêng của LTT, đăng nhập tài khoản LTT ngay trong app, tính phí theo máy/tháng
(cưỡng chế ở cả client lẫn relay), nhật ký truy cập, và tự kiểm bản mới.
Windows + Android.
