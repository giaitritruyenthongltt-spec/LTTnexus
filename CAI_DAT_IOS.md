# Cài LTT Nexus lên iPhone — không qua App Store

Dành cho **dùng nội bộ**. Ba cách, xếp theo chi phí. Đọc bảng rồi chọn một.

| Cách | Tiền | App sống được | Phải làm gì khi hết hạn |
|---|---|---|---|
| **A. SideStore** | **0đ** | 7 ngày, **tự gia hạn** | Không phải làm gì (tự động) |
| **B. Sideloadly** | **0đ** | 7 ngày | Cắm máy tính ký lại (~1 phút) |
| **C. Ad Hoc** | $99/năm | **1 năm** | Cài lại 1 lần/năm |

> **Không có cách nào "vĩnh viễn" trên iOS.** iPhone kiểm chứng chỉ mỗi lần mở
> app. Những app ngoài store mà bạn thấy "không bao giờ hết hạn" thực ra được
> nhà cung cấp **ký lại và đẩy bản mới trước khi hết hạn** — bạn chỉ không thấy.
> Đó cũng là lý do đôi khi cả loạt app như vậy **chết cùng lúc**: Apple thu hồi
> chứng chỉ của họ.

---

## Bước chung: lấy file `.ipa`

**Cách nhanh nhất — tải thẳng từ web:**
mở `app.lttstudios.com/tai-xuong` → mục **iOS** → **Tải xuống**

> Tải bằng Safari trên iPhone cũng được: file vào app **Tệp**, rồi mở SideStore
> chọn nó. **Lưu ý:** bấm vào file trong Tệp thì iOS **không** cài — phải qua
> SideStore/Sideloadly, vì file chưa ký (xem phần cuối để hiểu vì sao).

*Hoặc* lấy bản mới nhất từ GitHub: **Actions → "LTT — Build iOS (IPA chưa ký)"
→ Run workflow** (nhánh `ltt-nexus`) → tải artifact `LTTNexus-ios-unsigned-ipa`.

File **chưa ký** là đúng thiết kế — công cụ ở bước sau ký lại bằng Apple ID của
chính bạn, và đó là thứ khiến nó miễn phí.

---

## Cách A - SideStore (0đ, tự gia hạn) ⭐ khuyên dùng

**Cần máy tính ĐÚNG MỘT LẦN** để ghép đôi. Sau đó iPhone tự ký lại mỗi 7 ngày,
vĩnh viễn không cần cắm máy tính nữa.

> Không có cách nào bỏ hẳn máy tính ở bước đầu: iOS chỉ cấp "pairing file" cho
> một máy tính đã được iPhone tin cậy qua USB. Đó là thiết kế của Apple.

### Chuẩn bị (một lần)

1. **iTunes** — tải từ **apple.com**, KHÔNG dùng bản Microsoft Store
   (bản Store thiếu driver USB, iLoader sẽ không thấy máy)
2. **iLoader** trên PC — công cụ chính thức được SideStore khuyên dùng
   (iloader.site). Nó thay cho jitterbugpair cũ
3. **LocalDevVPN** trên iPhone — tải từ App Store (miễn phí). SideStore cần một
   đường VPN nội bộ để tự làm mới; nó KHÔNG gửi dữ liệu đi đâu, chỉ vòng trong máy
4. **Apple ID phụ** — đừng dùng tài khoản chính. Đây là chứng chỉ development,
   nên dùng ID riêng cho an toàn

### Cài (một lần, ~15 phút)

1. Cắm iPhone vào PC bằng cáp, mở khoá, bấm **Tin cậy máy tính này**
2. Mở **iLoader** → đăng nhập **Apple ID phụ** → chọn iPhone → **Install SideStore**
3. Trên iPhone: **Cài đặt → Cài đặt chung → VPN & Quản lý thiết bị** → chọn
   Apple ID vừa dùng → **Tin cậy**
4. Mở **SideStore**, bật **LocalDevVPN** khi được hỏi
5. Bấm vào số **"7 DAYS"** bên cạnh SideStore để làm mới lần đầu — xong thiết lập

### Cài LTT Nexus (từ đây trở đi KHÔNG cần máy tính)

* **Cách nhanh:** mở Safari trên iPhone → vào `app.lttstudios.com/tai-xuong` →
  tải file `.ipa` (nó vào app **Tệp**) → mở **SideStore** → bấm **+** → chọn file
* **Hoặc** dán thẳng link `.ipa` vào SideStore nếu bản của bạn hỗ trợ nguồn URL

### Sau đó

* App tự ký lại mỗi 7 ngày qua VPN nội bộ — **không phải cắm máy tính nữa**
* Giới hạn 3 app của Apple ID miễn phí: SideStore lách được bằng cách tạm tắt/bật,
  giữ tới **10 app**
* Pairing file có thể hỏng sau khi **cập nhật iOS** — lúc đó cắm PC làm lại bước
  ghép đôi (vài phút), không mất dữ liệu

### Muốn bỏ HẲN máy tính?

Có công cụ như **ESign** cài được SideStore không cần PC, nhưng nó ký bằng
**chứng chỉ enterprise của bên thứ ba**. Nghĩa là app sống hay chết phụ thuộc
vào chứng chỉ của người lạ — Apple thu hồi là **chết cả loạt**, và bạn không
kiểm soát được. Với máy dùng chính thì **không nên**.

## Cách B — Sideloadly (0đ, đơn giản nhất để thử lần đầu)

Nhanh nhất để xem app chạy được không, trước khi đầu tư thời gian vào SideStore.

1. Máy tính: tải **Sideloadly** (sideloadly.io), cài iTunes nếu Windows hỏi
2. Cắm iPhone bằng cáp
3. Kéo file `.ipa` vào cửa sổ Sideloadly → nhập **Apple ID** → **Start**
4. iPhone: **Cài đặt → Cài đặt chung → VPN & Quản lý thiết bị** → **Tin cậy**

**Mỗi 7 ngày phải cắm máy tính ký lại.** Dùng để thử, không dùng lâu dài.

---

## Cách C — Ad Hoc ($99/năm, mượt nhất cho nhóm)

Chọn cách này khi có **nhiều người** dùng iPhone và việc sửa SideStore trở thành
gánh nặng. $99 là **tổng cho cả nhóm**, tối đa **100 máy**.

1. Đăng ký **Apple Developer Program** ($99/năm)
2. Lấy **UDID** của từng iPhone → thêm vào Devices trong tài khoản
3. Tạo **Ad Hoc provisioning profile** + certificate
4. Ký `.ipa` bằng profile đó, đưa lên web, cài qua link
5. App chạy **trọn 1 năm**, không phải đụng tới

---

## Giới hạn của Apple ID miễn phí (cách A và B)

* App sống **7 ngày** mỗi lần ký
* Tối đa **3 app** tự ký cùng lúc trên một Apple ID
* Nên dùng **Apple ID phụ**, không dùng tài khoản chính

## Sau khi cài xong

1. Mở app → mục **Tài khoản LTT** → **Đăng nhập** bằng email/mật khẩu LTT
2. Máy của bạn hiện ra ở **"Máy của tôi"** → bấm một cái là kết nối
3. Nạp credit tại `app.lttstudios.com/nap` (thuê bao tính theo máy/tháng)

## Về khả năng của bản iOS

iPhone **điều khiển máy tính** rất tốt — đây là hướng dùng chính. Chiều ngược
lại (điều khiển *vào* iPhone) bị iOS giới hạn nặng; đó là giới hạn của Apple,
không phải của LTT Nexus.
