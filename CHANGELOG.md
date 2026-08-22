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

## 1.4.0 — 2026-08-22

**Một tài khoản, không gõ mật khẩu hai lần.** Bấm **Nạp credit** trước đây mở
trình duyệt tới `/nap` rồi bắt đăng nhập lại — cùng một tài khoản mà phải nhập
mật khẩu lần thứ hai. Nay ứng dụng tự xin một **vé đăng nhập một lần** bằng khoá
thiết bị đã có, nên trình duyệt mở ra là đã đăng nhập sẵn. Vé sống 90 giây và
dùng đúng một lần; xin vé hỏng thì vẫn mở trang như cũ để đăng nhập tay.

**Bấm đúp file cài giờ mới thật sự cài.** File phát hành đổi tên thành
`LTTNexus-<ver>-win-x64-install.exe`. Bộ đóng gói của RustDesk chỉ mở trình cài
khi **tên file kết thúc bằng `install.exe`** (`libs/portable/src/main.rs`); bản
1.2.0/1.3.0 tên `…-setup.exe` nên bấm đúp chỉ chạy một bản tạm trong
`%LOCALAPPDATA%` — chạy bình thường, nên không ai biết là đã không cài.

> **Đang ở 1.0.0 hoặc 1.1.0?** Hai bản đó ra đời trước tính năng tự cập nhật, nên
> nút *Cập nhật* của chúng chỉ biết mở trang web — không có cách nào để chúng tự
> nâng cấp. Cài tay **một lần** bằng file `…-install.exe` ở
> `app.lttstudios.com/tai-xuong`, từ đó về sau mỗi bản mới chỉ cần một cú bấm.

**Không còn danh sách máy ngoài tài khoản.** Tab *Đã tìm thấy* đã **bỏ hẳn**. Nó
liệt kê bất cứ máy nào trả lời broadcast trong mạng nội bộ — kể cả máy chưa từng
đăng nhập tài khoản của bạn. Sản phẩm này lấy **tài khoản** làm ranh giới: máy
thuộc tài khoản nằm ở *Máy của tôi*, và không có danh sách thứ hai bên cạnh chứa
máy không thuộc tài khoản. Các tab còn lại (Gần đây, Yêu thích) nay có một dòng
nói rõ chúng là dữ liệu **lưu trên máy này**, không phải danh sách tài khoản.

**Máy thôi tự khai mình ra mạng nội bộ.** Trước đây mỗi khi có ai trong cùng mạng
phát broadcast dò tìm, máy bạn trả lời kèm `id`, tên máy, **tên người đang đăng
nhập** và địa chỉ MAC. RustDesk gốc mặc định bật. Với phần mềm điều khiển từ xa
thì `id` đúng là thứ người khác cần để bắt đầu — ở mạng công ty, quán cà phê hay
khách sạn đó là tự khai. Nay **mặc định tắt**; vẫn bật lại được trong Cài đặt,
nhưng phải là một lựa chọn có ý thức.

**Một máy chỉ hiện một thẻ.** Ba máy trong mạng từng hiện thành năm thẻ vì phép so
"cùng máy hay không" so cả tên người đăng nhập — cùng một máy trả lời ở hai tình
trạng đăng nhập khác nhau thành hai máy. Nay so theo `id`.

**macOS: có bản build, có tên đúng, và tự cập nhật được.** Trước đây macOS chưa
từng ra được file nào. Nay có workflow riêng `ltt-macos.yml` (2 job thay vì 14 job
của "Flutter Nightly") dựng `.dmg` cho cả Apple Silicon lẫn Intel, và gói ứng dụng
đã đổi tên `RustDesk.app` → **`LTTNexus.app`** cùng định danh `com.lttstudios.nexus`
(khớp với bản iOS). Tự cập nhật trên macOS: tải `.dmg` → đối chiếu SHA-256 → gắn
ảnh đĩa → `ditto` gói `.app` đè lên bản cũ → mở lại. Việc tráo do một kịch bản rời
làm sau khi app thoát, vì thứ phải thay chính là gói đang chạy.

**macOS có hai bản, và bản kê nay có hai ô riêng.** CI dựng ra hai file `.dmg` —
Apple Silicon và Intel — mà chúng **không thay thế nhau được**. Bản kê trước chỉ có
một ô cho macOS, nghĩa là phát hành đồng nghĩa với chọn một kiến trúc và bỏ mặc
kiến trúc kia. Nay chúng là hai khoá nền tảng (`macos`, `macos_intel`); client tự
chọn theo kiến trúc đang chạy, trang tải hiện đủ hai.

> ⚠️ Bản macOS **chưa ký**. Lần mở đầu tiên macOS sẽ chặn; bấm chuột phải → *Open*,
> hoặc chạy `xattr -dr com.apple.quarantine /Applications/LTTNexus.app`. Ký và
> notarize cần tài khoản Apple Developer 99 USD/năm.

**Android/iOS: nút cập nhật mở đúng file, không mở trang tải.** Hai hệ này không
cho cài im lặng — Android bắt người dùng xác nhận ở màn hình cài đặt của chính nó,
iOS không có API cài. Trước đây nút *Cập nhật* mở trang tải rồi để người dùng tự
tìm; trên điện thoại đó là chỗ người ta bỏ cuộc. Nay nó mở **thẳng** file `.apk`
(hoặc `.ipa`) của đúng nền tảng đang chạy.

**Nhật ký truy cập** (trên web): trang *Máy của tôi* nay có bảng "ai đã điều
khiển máy của bạn, lúc nào, từ IP nào". Bản ghi không sửa được và không mất khi
thu hồi máy.

**`/nexus` trên web** nay là trang giới thiệu thật — sản phẩm là gì, bảng tải 4
nền tảng, 4 bước dùng, giá, câu hỏi thường gặp — thay cho bảng điều khiển
web-broker đã đóng băng theo Q101.

## 1.3.0 — 2026-08-22

**Ghi công đúng luật, chữ đúng dấu.** Mục *Về LTT Nexus* trước đây in
"Dựa trên LTTNexus 1.4.9" — phép đổi thương hiệu quét cả dòng ghi công AGPL nên
xoá mất chính cái tên mà giấy phép bắt phải giữ. Nay đúng: **"Dựa trên RustDesk
1.4.9"**. Dòng bản quyền cũng hết chữ không dấu ("dua tren RustDesk cua…") và
khẩu hiệu của RustDesk được thay bằng câu của LTT.

> Đây là bản đầu tiên bạn có thể nâng cấp **ngay trong app**: bấm *Cập nhật ngay*
> ở khung thông báo, app tự tải, đối chiếu SHA-256 rồi cài đè.

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

> Nâng cấp: mở app, bấm **Cập nhật ngay** ở khung thông báo.
>
> ⚠️ **Đính chính (23/08):** câu ở đây trước viết "tải file cài mới rồi chạy — nó
> tự đè lên bản cũ". **Sai.** File phát hành ở 1.2.0/1.3.0 tên là `…-setup.exe`,
> mà bộ đóng gói chỉ mở trình cài khi tên file kết thúc bằng `install.exe`; đặt
> tên khác thì bấm đúp **chỉ chạy bản tạm**, không cài. Từ 1.4.0 file đã đổi tên
> đúng. Ai đang ở 1.0.0/1.1.0 xem hướng dẫn ở mục 1.4.0.

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
