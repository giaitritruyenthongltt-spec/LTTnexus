# Cài đặt LTT Nexus (Windows)

## 1. Tải & kiểm tra bản tải

Tải `LTTNexus-1.0.0-win-x64.zip`. **Kiểm tra SHA-256** trước khi mở (dán vào
PowerShell, so với `LTTNexus-1.0.0-win-x64.zip.sha256`):

```powershell
Get-FileHash .\LTTNexus-1.0.0-win-x64.zip -Algorithm SHA256
```

Hai chuỗi phải khớp nhau. Không khớp → **đừng chạy**, tải lại.

## 2. Giải nén & chạy

Giải nén ra một thư mục, chạy `LTTNexus.exe`.

> ⚠️ Bản này **chưa ký chứng thư số** (quyết định phát hành sớm — Q95), nên
> Windows SmartScreen sẽ hiện cảnh báo "Windows protected your PC". Bấm
> **More info → Run anyway**. Chỉ làm điều này với bản tải **đúng SHA-256** ở
> trên — đây chính là lý do phải kiểm hash trước.

## 3. Đăng nhập tài khoản LTT

Lần đầu mở, LTT Nexus yêu cầu **đăng nhập bằng tài khoản LTT** (email + mật khẩu).
Chưa có tài khoản thì bấm "Đăng ký" (mở trang `app.lttstudios.com`). Máy này sẽ
được gắn vào tài khoản của bạn để tính phí (theo máy, mỗi tháng).

## 4. Điều khiển máy khác

Nhập **ID + mật khẩu** của máy đích (giống cách dùng quen thuộc) rồi bấm "Kết nối".
Kết nối đi thẳng máy-tới-máy qua relay của LTT, **không** qua web.

## 5. Cho phép điều khiển máy này khi không có ai (unattended)

Muốn điều khiển máy này từ xa lúc không có người ngồi: bấm **Install** trong app
(cần nâng quyền **một lần** — Windows sẽ hỏi UAC). Sau đó máy chạy nền như một
dịch vụ và điều khiển được bất cứ lúc nào, không hỏi UAC lại.

## 6. Nạp credit

Thanh tài khoản trong app hiện số credit còn lại. Hết credit → máy tạm ngừng nhận
điều khiển cho tới khi nạp. Bấm **Nạp credit** để mở trình duyệt (mọi thanh toán
diễn ra trên web, app không xử lý tiền).

---

*LTT Nexus là bản tuỳ biến (fork) của [RustDesk](https://github.com/rustdesk/rustdesk),
giấy phép AGPL-3.0. Mã nguồn bản sửa: xem `LTT_NEXUS_FORK.md`.*
