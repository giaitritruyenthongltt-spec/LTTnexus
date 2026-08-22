# Cài iOS KHÔNG CẦN MÁY TÍNH — ký Ad Hoc

Mục tiêu: người dùng chỉ **mở Safari → bấm một cái → app cài vào máy**. Không
cắm cáp, không cài SideStore, không làm mới mỗi 7 ngày. App chạy **trọn 1 năm**.

Đây là cách duy nhất **hợp pháp và ổn định** để bỏ hẳn máy tính. Chi phí:
**$99/năm** (Apple Developer Program) — tổng cho tối đa **100 máy**, không phải
mỗi máy.

> **Vì sao không có cách $0:** iOS chỉ cài qua web khi IPA được ký bằng hồ sơ
> **Ad Hoc hoặc Enterprise**. Apple ID miễn phí chỉ cấp hồ sơ *development*, và
> iOS **từ chối** cài kiểu đó qua web. Mọi công cụ "miễn phí không cần máy tính"
> (ESign và tương tự) đều mượn chứng chỉ enterprise của bên thứ ba — Apple thu
> hồi lúc nào là app chết lúc đó, và mình không kiểm soát được.

---

## Phần đã làm sẵn (không phải đụng tới)

| Thành phần | Trạng thái |
|---|---|
| Máy chủ sinh `manifest.plist` (`/nexus/ios-manifest.plist`) | ✅ đã có, đã test |
| Nút **"Cài lên iPhone"** trên trang tải (`itms-services://`) | ✅ đã có, ẩn cho tới khi có chữ ký |
| HTTPS hợp lệ (Apple bắt buộc) | ✅ qua Cloudflare |
| Dây chuyền **ký Ad Hoc trong CI** | ✅ đã có, chờ 3 secret |

Nghĩa là sau khi mua $99, việc còn lại chỉ là **lấy 3 file và dán vào GitHub**.

---

## Bước 1 — Mua Apple Developer Program ($99/năm)

developer.apple.com/programs → Enroll. Đăng ký **cá nhân** thì nhanh (vài giờ tới
vài ngày); đăng ký **công ty** cần mã D-U-N-S và lâu hơn.

## Bước 2 — Lấy UDID của từng iPhone

Trên iPhone, mở Safari vào **udid.tech** (hoặc get.udid.io) → cài hồ sơ tạm →
nó hiện UDID. Hoặc cắm vào PC có iTunes: chọn máy → bấm vào dòng Serial Number
cho tới khi hiện UDID.

Vào **developer.apple.com → Certificates, Identifiers & Profiles → Devices** →
thêm từng UDID. Tối đa **100 máy/năm** cho mỗi loại thiết bị.

## Bước 3 — Tạo 3 thứ trên trang Apple Developer

Làm hoàn toàn trên trình duyệt, **không cần Mac**:

1. **Identifier**: Identifiers → **+** → App IDs → App → Bundle ID
   **`com.lttstudios.nexus`** (phải trùng đúng, không thì iOS từ chối cài)
2. **Certificate** (Apple Distribution):
   - Tạo CSR: trên Windows dùng OpenSSL
     ```
     openssl genrsa -out ios.key 2048
     openssl req -new -key ios.key -out ios.csr -subj "/emailAddress=EMAIL/CN=LTT Studios/C=VN"
     ```
   - Certificates → **+** → **Apple Distribution** → tải file `ios.csr` lên →
     tải về `distribution.cer`
   - Gộp thành `.p12` (đây là thứ CI cần):
     ```
     openssl x509 -in distribution.cer -inform DER -out ios.pem -outform PEM
     openssl pkcs12 -export -inkey ios.key -in ios.pem -out ios.p12
     ```
     (đặt mật khẩu khi được hỏi — nhớ lại, sẽ dùng ở bước 4)
3. **Provisioning Profile**: Profiles → **+** → **Ad Hoc** → chọn App ID vừa
   tạo → chọn certificate → **chọn hết các máy đã thêm** → tải về
   `LTTNexus_AdHoc.mobileprovision`

## Bước 4 — Dán 3 secret vào GitHub

Repo LTTnexus → **Settings → Secrets and variables → Actions → New repository
secret**. Tạo đúng ba cái, đúng tên:

| Tên secret | Nội dung |
|---|---|
| `IOS_P12_BASE64` | file `ios.p12` mã hoá base64 |
| `IOS_P12_PASSWORD` | mật khẩu đặt lúc tạo `.p12` |
| `IOS_MOBILEPROVISION_BASE64` | file `.mobileprovision` mã hoá base64 |

Mã hoá base64 trên Windows:
```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("ios.p12")) | Set-Clipboard
[Convert]::ToBase64String([IO.File]::ReadAllBytes("LTTNexus_AdHoc.mobileprovision")) | Set-Clipboard
```
(chạy từng dòng, dán vào ô secret tương ứng)

## Bước 5 — Build lại

Actions → **"LTT — Build iOS (IPA chưa ký)"** → Run workflow.

Có secret thì workflow tự ký và cho ra thêm artifact **`LTTNexus-ios-signed-ipa`**.
Không có secret thì vẫn ra bản chưa ký như cũ — không hỏng gì.

## Bước 6 — Phát hành

1. Chép `LTTNexus-signed.ipa` vào `C:\LTTPlatform\data\nexus_dist\`
2. Sửa `C:\LTTPlatform\data\nexus_versions.json`, mục `ios`:
   ```json
   "ios": {
     "label": "iOS (iPhone/iPad)",
     "available": true,
     "signed": true,
     "url": "/nexus/dl/LTTNexus-1.1.0-ios-signed.ipa",
     "sha256": "...",
     "kind": "ipa"
   }
   ```
3. Xong. Trang tải hiện nút **"Cài lên iPhone"** — mở bằng **Safari** trên
   iPhone, bấm, iOS cài thẳng.

---

## Điều phải nhớ

* **Chỉ máy có UDID đã đăng ký mới cài được.** Máy lạ bấm vào sẽ báo lỗi. Thêm
  máy mới = thêm UDID + tạo lại profile + build lại.
* **Link phải mở trong Safari.** Chrome, Zalo, Messenger… bấm vào **không có gì
  xảy ra** (không báo lỗi). Gửi link thì dặn "mở bằng Safari".
* **Hết 1 năm** thì profile hết hạn: gia hạn $99, tạo profile mới, build lại,
  người dùng cài đè một lần.
* **Giữ kỹ `ios.p12` và mật khẩu.** Mất là phải tạo lại chứng chỉ; lộ là người
  khác ký được app mạo danh LTT.
