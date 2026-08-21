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

1. Mở **GitHub → repo LTTnexus → tab Actions**
2. Chọn workflow **"Flutter Nightly Build"** → **Run workflow** → nhánh `ltt-nexus`
3. Đợi build xong (~30–60 phút), mở lần chạy đó, kéo xuống mục **Artifacts**
4. Tải **`LTTNexus-ios-unsigned-ipa`** → giải nén được `LTTNexus-unsigned.ipa`

File này **chưa ký** — đó là bình thường. Công cụ ở bước sau sẽ ký lại bằng
Apple ID của chính bạn.

---

## Cách A — SideStore (0đ, tự gia hạn) ⭐ khuyên dùng

Ưu điểm lớn nhất: sau khi cài xong, **app tự ký lại ngay trên iPhone** mỗi 7
ngày, không cần cắm máy tính nữa.

1. Trên máy tính: tải **SideStore** (sidestore.io) và làm theo hướng dẫn tạo
   **pairing file** (ghép đôi iPhone với máy tính — chỉ làm **một lần**)
2. Cài SideStore lên iPhone, nạp pairing file
3. Trong SideStore bấm **+** → chọn file `.ipa` → đăng nhập **Apple ID thường**
   (miễn phí, nên dùng một Apple ID phụ)
4. Trên iPhone: **Cài đặt → Cài đặt chung → VPN & Quản lý thiết bị** → chọn
   Apple ID của bạn → **Tin cậy**
5. Bật **Background refresh** trong SideStore để nó tự gia hạn

**Điểm yếu thật:** pairing file thỉnh thoảng hỏng (sau khi cập nhật iOS), lúc đó
phải tạo lại. Không mất dữ liệu, chỉ mất vài phút.

---

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
