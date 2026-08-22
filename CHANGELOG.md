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

## 1.2.0 — 2026-08-22

**Tự cập nhật thật.** Trước đây bấm "Cập nhật" chỉ mở trang tải rồi bạn tự giải
nén đè — việc mà không làm sạch được khi app đang chạy. Nay app **tự tải bản
cài, đối chiếu SHA-256, rồi cài** trong một lần bấm. Kèm **file cài một-file**
(21 MB, nhỏ hơn bản zip) thay cho việc giải nén thủ công.

**Sạch thương hiệu RustDesk.** Mục "Về LTT Nexus" nay ghi đúng LTT Studios (vẫn
ghi nhận RustDesk theo AGPL) và hiện **số phiên bản LTT** thay vì số của
RustDesk. Bỏ dòng khuyên "hãy tự thiết lập máy chủ riêng" — relay LTT chính là
dịch vụ bạn đang dùng. Bỏ mục tài khoản thứ hai của RustDesk trong Cài đặt: chỉ
còn một tài khoản LTT duy nhất. Các link tải/giá/chính sách nay trỏ về LTT.

**Sửa lỗi**
* **Máy luôn hiện "tắt"** dù đang chạy — client chỉ gọi `/status` chứ không gọi
  `/heartbeat`, nên máy chủ không bao giờ ghi nhận nó còn sống.
* **Mạng chớp một cái là ngừng báo cập nhật** — một nhánh thoát sớm bỏ qua luôn
  việc kiểm bản mới.
* Thêm **nút kiểm bản cập nhật** và hiện thông báo **ngay ở màn đăng nhập**
  (trước đó chưa đăng nhập thì không bao giờ biết có bản mới).

> Nâng cấp: mở app, bấm **Cập nhật ngay** ở khung thông báo. Hoặc tải file cài
> mới ở `app.lttstudios.com/tai-xuong` và chạy — nó tự đè lên bản cũ.

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
