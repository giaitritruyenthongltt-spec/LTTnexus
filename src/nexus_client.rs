// LTT Nexus (Model B — Q101 / D-P7): client đăng nhập tài khoản LTT bằng
// email+mật khẩu, đăng ký MÁY này, và hỏi trạng thái thuê bao (Q98).
//
// Đây là mã của FORK (AGPL) — KHÔNG phải Agent độc quyền. Nó chỉ nói chuyện với
// control plane LTT bằng đúng lược đồ ký Ed25519 của `platform_core.nexus.
// agent_auth`: khoá riêng sinh tại chỗ, không bao giờ rời máy; mỗi request được
// ký `METHOD\npath\ntimestamp\nsha256_hex(body)`; khoá công khai mã hoá
// `ltt_dev_` + base64url(32 byte).

use hbb_common::{
    anyhow::bail,
    config::LocalConfig,
    sha2::{Digest, Sha256},
    sodiumoxide::{base64, crypto::sign},
    ResultType,
};

const PREFIX: &str = "ltt_dev_";
const K_DEVICE: &str = "ltt-nexus-device-id";
const K_SECRET: &str = "ltt-nexus-secret";
const K_EMAIL: &str = "ltt-nexus-email";
const K_BASE: &str = "ltt-nexus-base"; // server đã dùng lúc đăng nhập
const K_PAID: &str = "ltt-nexus-paid"; // cache trạng thái thuê bao ("1"/"0")
const K_PAID_AT: &str = "ltt-nexus-paid-at";
const PAID_TTL_S: u64 = 300; // cache 5 phút — tránh gọi mạng mỗi kết nối vào

fn now_secs() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0)
}

fn b64e(raw: &[u8]) -> String {
    base64::encode(raw, base64::Variant::UrlSafeNoPadding)
}

fn b64d(s: &str) -> ResultType<Vec<u8>> {
    base64::decode(s.trim().trim_end_matches('='), base64::Variant::UrlSafeNoPadding)
        .map_err(|_| hbb_common::anyhow::anyhow!("base64 khong hop le"))
}

fn hex_lower(bytes: &[u8]) -> String {
    let mut s = String::with_capacity(bytes.len() * 2);
    for b in bytes {
        s.push_str(&format!("{:02x}", b));
    }
    s
}

// Cùng một hàm canonical với agent_auth.canonical — lệch một dấu xuống dòng là
// mọi chữ ký bị từ chối, triệu chứng trông y hệt "sai khoá".
fn canonical(method: &str, path: &str, ts: &str, body: &[u8]) -> Vec<u8> {
    let mut h = Sha256::new();
    h.update(body);
    let dau = hex_lower(&h.finalize());
    format!("{}\n{}\n{}\n{}", method.to_uppercase(), path, ts, dau).into_bytes()
}

fn now_ts() -> String {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|d| d.as_secs().to_string())
        .unwrap_or_default()
}

fn http() -> reqwest::blocking::Client {
    reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(20))
        .build()
        .unwrap_or_default()
}

pub fn device_id() -> String {
    LocalConfig::get_option(K_DEVICE)
}

pub fn email() -> String {
    LocalConfig::get_option(K_EMAIL)
}

pub fn is_logged_in() -> bool {
    !device_id().is_empty() && !LocalConfig::get_option(K_SECRET).is_empty()
}

pub fn logout() {
    for k in [K_DEVICE, K_SECRET, K_EMAIL, K_BASE, K_PAID, K_PAID_AT] {
        LocalConfig::set_option(k.to_owned(), "".to_owned());
    }
}

/// Đăng nhập tài khoản LTT và đăng ký máy này. Trả `device_id`, hoặc lỗi (một câu
/// cho mọi lý do: sai mật khẩu, email không có, mạng…). Sinh khoá TRƯỚC khi gọi;
/// chỉ lưu khi server nhận.
pub fn register(
    base_url: &str,
    email: &str,
    password: &str,
    display_name: &str,
    platform: &str,
) -> ResultType<String> {
    let (pk, sk) = sign::gen_keypair();
    let public_key = format!("{}{}", PREFIX, b64e(&pk.0));
    let url = format!(
        "{}/nexus-agent/client-register",
        base_url.trim_end_matches('/')
    );
    let body = serde_json::json!({
        "email": email,
        "password": password,
        "public_key": public_key,
        "display_name": display_name,
        "platform": platform,
    });
    let resp = http().post(&url).json(&body).send()?;
    let ok = resp.status().is_success();
    let j: serde_json::Value = resp.json().unwrap_or_default();
    if !ok {
        let msg = j
            .get("error")
            .and_then(|e| e.get("message"))
            .and_then(|m| m.as_str())
            .unwrap_or("dang nhap that bai");
        bail!("{}", msg);
    }
    let did = j
        .get("device_id")
        .and_then(|d| d.as_str())
        .unwrap_or("")
        .to_owned();
    if did.is_empty() {
        bail!("server khong tra device_id");
    }
    LocalConfig::set_option(K_DEVICE.to_owned(), did.clone());
    LocalConfig::set_option(K_SECRET.to_owned(), b64e(&sk.0));
    LocalConfig::set_option(K_EMAIL.to_owned(), email.to_owned());
    LocalConfig::set_option(K_BASE.to_owned(), base_url.trim_end_matches('/').to_owned());
    Ok(did)
}

/// Hỏi trạng thái thuê bao (có ký). Trả JSON thô của server (paid, price_per_
/// month, credit_balance, paid_until). Client đọc `paid` để khoá/mở điều khiển.
pub fn status(base_url: &str) -> ResultType<String> {
    let did = device_id();
    let sec_b64 = LocalConfig::get_option(K_SECRET);
    if did.is_empty() || sec_b64.is_empty() {
        bail!("chua dang nhap");
    }
    let sk = sign::SecretKey::from_slice(&b64d(&sec_b64)?)
        .ok_or_else(|| hbb_common::anyhow::anyhow!("khoa rieng hong"))?;
    let path = "/nexus-agent/status";
    let ts = now_ts();
    // Báo kèm ID RustDesk (Model B) để relay ánh xạ ID→tài khoản và cưỡng chế
    // billing ở tầng rendezvous (hbbs). ID không bí mật.
    let body = serde_json::json!({
        "rustdesk_id": hbb_common::config::Config::get_id(),
    })
    .to_string()
    .into_bytes();
    let sig = sign::sign_detached(&canonical("POST", path, &ts, &body), &sk);
    let signature = b64e(sig.as_ref());
    let url = format!("{}{}", base_url.trim_end_matches('/'), path);
    let resp = http()
        .post(&url)
        .header("X-LTT-Device", did)
        .header("X-LTT-Timestamp", ts)
        .header("X-LTT-Signature", signature)
        .header("Content-Type", "application/json")
        .body(body)
        .send()?;
    let text = resp.text()?;
    // Cache trạng thái trả phí cho `may_control` (Q98) — không phải gọi mạng
    // trên mỗi kết nối vào.
    if let Ok(j) = serde_json::from_str::<serde_json::Value>(&text) {
        let paid = j.get("paid").and_then(|p| p.as_bool()).unwrap_or(true);
        LocalConfig::set_option(K_PAID.to_owned(), if paid { "1" } else { "0" }.to_owned());
        LocalConfig::set_option(K_PAID_AT.to_owned(), now_secs().to_string());
    }
    Ok(text)
}

/// Onboarding 1-chạm: danh sách máy CÙNG TÀI KHOẢN (có ký). Trả JSON thô của
/// server: `{"devices":[{device_id,rustdesk_id,name,online,paid,is_self}]}`.
/// Client hiện panel "Máy của tôi" sau đăng nhập → bấm là điền ID + kết nối,
/// khỏi nhập tay. GỌI TỪ LUỒNG BLOCKING (nó gọi HTTP).
pub fn my_devices(base_url: &str) -> ResultType<String> {
    let did = device_id();
    let sec_b64 = LocalConfig::get_option(K_SECRET);
    if did.is_empty() || sec_b64.is_empty() {
        bail!("chua dang nhap");
    }
    let sk = sign::SecretKey::from_slice(&b64d(&sec_b64)?)
        .ok_or_else(|| hbb_common::anyhow::anyhow!("khoa rieng hong"))?;
    let path = "/nexus-agent/my-devices";
    let ts = now_ts();
    let body: &[u8] = b"";
    let sig = sign::sign_detached(&canonical("POST", path, &ts, body), &sk);
    let signature = b64e(sig.as_ref());
    let url = format!("{}{}", base_url.trim_end_matches('/'), path);
    let resp = http()
        .post(&url)
        .header("X-LTT-Device", did)
        .header("X-LTT-Timestamp", ts)
        .header("X-LTT-Signature", signature)
        .header("Content-Type", "application/json")
        .body(body.to_vec())
        .send()?;
    Ok(resp.text()?)
}

/// Máy này có được NHẬN điều khiển vào không (Q98 — răng của thu phí)?
///
/// * Chưa đăng nhập LTT → **true**: máy không do LTT quản, giữ nguyên hành vi
///   RustDesk gốc, không tự dưng khoá ai.
/// * Đã đăng nhập → theo thuê bao, cache 5 phút. Miễn phí (giá 0) → server trả
///   `paid=true` nên luôn cho qua.
/// * Lỗi mạng → **fail-open** (trừ khi có cache "chưa trả" rõ ràng): không khoá
///   người đang trả tiền chỉ vì mạng chớp. Đây là chọn lựa có ý thức; siết chặt
///   (fail-closed ở rendezvous) là việc hardening sau.
///
/// GỌI TỪ LUỒNG BLOCKING (spawn_blocking) — nó có thể gọi HTTP.
pub fn may_control() -> bool {
    if !is_logged_in() {
        return true;
    }
    let at: u64 = LocalConfig::get_option(K_PAID_AT).parse().unwrap_or(0);
    let cached = LocalConfig::get_option(K_PAID);
    if !cached.is_empty() && now_secs().saturating_sub(at) < PAID_TTL_S {
        return cached == "1";
    }
    let base = LocalConfig::get_option(K_BASE);
    let base = if base.is_empty() {
        "https://app.lttstudios.com".to_owned()
    } else {
        base
    };
    match status(&base) {
        Ok(_) => LocalConfig::get_option(K_PAID) == "1", // status() vừa cache
        Err(_) => cached != "0", // fail-open trừ khi cache nói rõ "chưa trả"
    }
}

/// Phiên bản LTT của bản build này (khác version RustDesk gốc 1.4.9). So với
/// `manifest.version` ở `/nexus/version.json` để biết có bản mới không.
pub const LTT_VERSION: &str = "1.1.0";

fn version_gt(a: &str, b: &str) -> bool {
    // a > b theo semver đơn giản (x.y.z; phần thiếu coi như 0).
    let pa: Vec<u64> = a.split('.').map(|s| s.trim().parse().unwrap_or(0)).collect();
    let pb: Vec<u64> = b.split('.').map(|s| s.trim().parse().unwrap_or(0)).collect();
    for i in 0..pa.len().max(pb.len()) {
        let x = pa.get(i).copied().unwrap_or(0);
        let y = pb.get(i).copied().unwrap_or(0);
        if x != y {
            return x > y;
        }
    }
    false
}

/// Có bản mới không? Trả URL trang tải nếu `manifest.version` > bản hiện tại,
/// ngược lại "". Không cần đăng nhập (version.json công khai). Fail-open: lỗi
/// mạng → "" (không quấy khách). GỌI TỪ LUỒNG BLOCKING.
pub fn check_update(base_url: &str) -> String {
    let base = base_url.trim_end_matches('/');
    let url = format!("{}/nexus/version.json", base);
    let client = match reqwest::blocking::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
    {
        Ok(c) => c,
        Err(_) => return String::new(),
    };
    let body = match client.get(&url).send().and_then(|r| r.text()) {
        Ok(t) => t,
        Err(_) => return String::new(),
    };
    let j: serde_json::Value = match serde_json::from_str(&body) {
        Ok(v) => v,
        Err(_) => return String::new(),
    };
    let latest = j.get("version").and_then(|v| v.as_str()).unwrap_or("");
    if version_gt(latest, LTT_VERSION) {
        format!("{}/tai-xuong", base)
    } else {
        String::new()
    }
}

/// Báo một sự kiện phiên (P8, ràng buộc 6) — "ai đã vào máy tôi". Fire-and-forget:
/// nhật ký KHÔNG được làm hỏng phiên nếu mạng lỗi. `event` = "start" | "end".
/// GỌI TỪ LUỒNG BLOCKING (spawn_blocking).
pub fn report_session_event(session_key: &str, event: &str, peer_id: &str, controller_ip: &str) {
    if !is_logged_in() {
        return;
    }
    let sk = match sign::SecretKey::from_slice(
        &b64d(&LocalConfig::get_option(K_SECRET)).unwrap_or_default(),
    ) {
        Some(k) => k,
        None => return,
    };
    let base = {
        let b = LocalConfig::get_option(K_BASE);
        if b.is_empty() {
            "https://app.lttstudios.com".to_owned()
        } else {
            b
        }
    };
    let path = "/nexus-agent/session-event";
    let body = serde_json::json!({
        "session_key": session_key,
        "event": event,
        "peer_id": peer_id,
        "controller_ip": controller_ip,
    })
    .to_string()
    .into_bytes();
    let ts = now_ts();
    let sig = sign::sign_detached(&canonical("POST", path, &ts, &body), &sk);
    let url = format!("{}{}", base.trim_end_matches('/'), path);
    let _ = http()
        .post(&url)
        .header("X-LTT-Device", device_id())
        .header("X-LTT-Timestamp", ts)
        .header("X-LTT-Signature", b64e(sig.as_ref()))
        .header("Content-Type", "application/json")
        .body(body)
        .send();
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn canonical_doi_theo_body_va_thoi_gian() {
        // Một byte khác trong body -> chuỗi ký khác. Nếu không, chữ ký không
        // ràng buộc nội dung và ai chặn được request đều sửa được body.
        let a = canonical("POST", "/p", "1", b"{}");
        let b = canonical("POST", "/p", "1", b"{ }");
        assert_ne!(a, b);
        // Cùng body nhưng khác dấu thời gian -> khác (chống phát lại).
        let c = canonical("POST", "/p", "2", b"{}");
        assert_ne!(a, c);
    }

    #[test]
    fn canonical_khong_lan_giua_cac_truong() {
        // "/a" + ts "11" phải khác "/a1" + ts "1": nếu nối chuỗi không có dấu
        // ngăn thì hai request khác nhau lại ký ra cùng một chuỗi.
        assert_ne!(canonical("GET", "/a", "11", b""), canonical("GET", "/a1", "1", b""));
    }

    #[test]
    fn b64_di_ve_khong_mat_du_lieu() {
        let goc: Vec<u8> = (0u8..=255).collect();
        let lai = b64d(&b64e(&goc)).expect("giai ma duoc");
        assert_eq!(goc, lai);
    }

    #[test]
    fn b64_hong_thi_bao_loi_chu_khong_hoang_loan() {
        assert!(b64d("khong-phai-base64!!!").is_err());
    }

    #[test]
    fn version_gt_bat_duoc_moi_truong_hop_thuong_gap() {
        assert!(version_gt("1.0.1", "1.0.0"));
        assert!(version_gt("1.1.0", "1.0.9"));
        assert!(version_gt("2.0", "1.9.9"));
        assert!(!version_gt("1.0.0", "1.0.0"));
        assert!(!version_gt("1.0.0", "1.0.1"));
        // Phần thiếu coi như 0 -> "1.0" không mới hơn "1.0.0".
        assert!(!version_gt("1.0", "1.0.0"));
        // Rác không được coi là bản mới (fail-open: không quấy khách).
        assert!(!version_gt("khong-phai-so", "1.0.0"));
    }

    #[test]
    fn hex_lower_dung_dinh_dang() {
        assert_eq!(hex_lower(&[0x00, 0x0f, 0xff]), "000fff");
    }

    #[test]
    fn public_key_encoding_khop_dang_agent_auth() {
        let (pk, _sk) = sign::gen_keypair();
        let enc = format!("{}{}", PREFIX, b64e(&pk.0));
        assert!(enc.starts_with("ltt_dev_"));
        // 32 byte -> base64url không đệm = 43 ký tự.
        assert_eq!(enc.len(), PREFIX.len() + 43);
    }

    #[test]
    fn canonical_dung_dinh_dang_bon_dong() {
        let c = canonical("post", "/x", "123", b"");
        let s = String::from_utf8(c).unwrap();
        let dong: Vec<&str> = s.split('\n').collect();
        assert_eq!(dong.len(), 4);
        assert_eq!(dong[0], "POST"); // method viết hoa
        assert_eq!(dong[1], "/x");
        assert_eq!(dong[2], "123");
        // sha256 của chuỗi rỗng, hex thường.
        assert_eq!(
            dong[3],
            "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        );
    }

    #[test]
    fn so_sanh_phien_ban() {
        assert!(version_gt("1.0.1", "1.0.0"));
        assert!(version_gt("1.1.0", "1.0.9"));
        assert!(version_gt("2.0", "1.9.9"));
        assert!(!version_gt("1.0.0", "1.0.0"));
        assert!(!version_gt("1.0.0", "1.0.1"));
    }

    #[test]
    fn ky_roi_tu_kiem_lai_dung() {
        let (pk, sk) = sign::gen_keypair();
        let msg = canonical("POST", "/nexus-agent/status", "1000", b"");
        let sig = sign::sign_detached(&msg, &sk);
        assert!(sign::verify_detached(&sig, &msg, &pk));
    }
}
