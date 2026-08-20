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
    LocalConfig::set_option(K_DEVICE.to_owned(), "".to_owned());
    LocalConfig::set_option(K_SECRET.to_owned(), "".to_owned());
    LocalConfig::set_option(K_EMAIL.to_owned(), "".to_owned());
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
    let sig = sign::sign_detached(&canonical("POST", path, &ts, b""), &sk);
    let signature = b64e(sig.as_ref());
    let url = format!("{}{}", base_url.trim_end_matches('/'), path);
    let resp = http()
        .post(&url)
        .header("X-LTT-Device", did)
        .header("X-LTT-Timestamp", ts)
        .header("X-LTT-Signature", signature)
        .send()?;
    Ok(resp.text()?)
}

#[cfg(test)]
mod tests {
    use super::*;

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
    fn ky_roi_tu_kiem_lai_dung() {
        let (pk, sk) = sign::gen_keypair();
        let msg = canonical("POST", "/nexus-agent/status", "1000", b"");
        let sig = sign::sign_detached(&msg, &sk);
        assert!(sign::verify_detached(&sig, &msg, &pk));
    }
}
