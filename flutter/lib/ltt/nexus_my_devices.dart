// LTT Nexus (Model B) — onboarding 1-chạm: panel "Máy của tôi".
//
// Sau khi đăng nhập tài khoản LTT, hiện danh sách máy CÙNG TÀI KHOẢN (lấy từ
// `/nexus-agent/my-devices`, có ký) với chỉ báo online + nút Kết nối. Bấm một
// máy online là điền ID + kết nối luôn — khỏi nhập tay như TeamViewer. Bỏ qua
// chính máy này; chỉ hiện máy đã có rustdesk_id (mới kết nối được).
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/ltt/nexus_login.dart';

/// Lọc + sắp xếp danh sách máy từ JSON thô của `/nexus-agent/my-devices`.
///
/// Tách khỏi widget để **test được không cần FFI**: đây là chỗ dễ sai nhất
/// (bỏ sót máy chính mình, hiện máy chưa kết nối được, sai thứ tự) và cũng là
/// chỗ người dùng nhìn thấy đầu tiên sau khi đăng nhập.
///
/// Quy tắc: bỏ chính máy này (`is_self`), bỏ máy chưa có `rustdesk_id` (chưa
/// kết nối tới được), máy đang bật xếp lên trước. JSON hỏng → danh sách rỗng
/// (không ném: panel chỉ việc ẩn đi, không làm vỡ trang chủ).
List<Map<String, dynamic>> locSapXepMay(String jsonTho) {
  try {
    final j = jsonDecode(jsonTho);
    if (j is! Map) return [];
    final ds = j['devices'];
    if (ds is! List) return [];
    final ra = <Map<String, dynamic>>[];
    for (final d in ds) {
      if (d is! Map) continue;
      final m = Map<String, dynamic>.from(d);
      if (m['is_self'] == true) continue;
      if ('${m['rustdesk_id'] ?? ''}'.isEmpty) continue;
      ra.add(m);
    }
    ra.sort((a, b) =>
        (b['online'] == true ? 1 : 0) - (a['online'] == true ? 1 : 0));
    return ra;
  } catch (_) {
    return [];
  }
}

class NexusMyDevices extends StatefulWidget {
  const NexusMyDevices({Key? key}) : super(key: key);

  @override
  State<NexusMyDevices> createState() => _NexusMyDevicesState();
}

class _NexusMyDevicesState extends State<NexusMyDevices> {
  List<Map<String, dynamic>> _devices = [];
  bool _loading = false;
  bool _loaded = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!bind.nexusClientIsLoggedIn()) return;
    if (mounted) setState(() => _loading = true);
    try {
      final res = await bind.nexusClientMyDevices(baseUrl: nexusServer());
      final others = locSapXepMay(res);
      if (!mounted) return;
      setState(() {
        _devices = others;
        _loaded = true;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _connect(String id) {
    if (id.isEmpty) return;
    connect(context, id);
  }

  @override
  Widget build(BuildContext context) {
    // Chưa đăng nhập: trên DESKTOP không bao giờ tới đây (đã có cổng đăng nhập
    // ở trang chủ), nhưng trên MOBILE thì đây là **đường đăng nhập duy nhất** —
    // thiếu nó thì người dùng iPhone/Android không có cách nào vào tài khoản
    // LTT, và mọi thứ gắn với tài khoản (máy của tôi, thuê bao) thành vô hình.
    if (!bind.nexusClientIsLoggedIn()) return _moiDangNhap();
    // Chưa tải xong thì chưa vẽ gì (tránh nhấp nháy).
    if (!_loaded) return const Offstage();
    // Chưa có máy nào khác: KHÔNG ẩn hẳn. Ẩn thì người mới không bao giờ biết
    // tính năng này tồn tại và cứ gõ ID bằng tay — mất đúng khoảnh khắc "à,
    // hoá ra máy của mình tự hiện ra". Một dòng gợi ý là đủ để dạy.
    if (_devices.isEmpty) return _goiY();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.devices, size: 15, color: MyTheme.accent),
              const SizedBox(width: 5),
              Expanded(
                child: Text('Máy của tôi',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: MyTheme.accent)),
              ),
              InkWell(
                onTap: _loading ? null : _refresh,
                child: _loading
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 1.6))
                    : Icon(Icons.refresh, size: 14, color: MyTheme.darkGray),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ..._devices.map(_deviceTile),
          const Divider(height: 12),
        ],
      ),
    );
  }

  /// Chưa đăng nhập (mobile): mời đăng nhập tài khoản LTT.
  Widget _moiDangNhap() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MyTheme.accent.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.account_circle, size: 20, color: MyTheme.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tài khoản LTT',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text('Đăng nhập để thấy máy của bạn và kết nối bằng một chạm.',
                    style: TextStyle(fontSize: 11, color: MyTheme.darkGray)),
              ],
            ),
          ),
          TextButton(
            onPressed: _moTrangDangNhap,
            child: Text('Đăng nhập',
                style: TextStyle(color: MyTheme.accent, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _moTrangDangNhap() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Đăng nhập LTT Nexus')),
        body: NexusLoginPage(onLoggedIn: () {
          Navigator.of(context).pop();
          _loaded = false;
          _refresh();
        }),
      ),
    ));
  }

  /// Trạng thái rỗng: dạy người dùng cách làm cho máy khác hiện ra ở đây.
  Widget _goiY() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.devices, size: 15, color: MyTheme.accent),
              const SizedBox(width: 5),
              Text('Máy của tôi',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: MyTheme.accent)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Cài LTT Nexus trên máy khác rồi đăng nhập cùng tài khoản này — '
            'máy đó sẽ hiện ở đây, bấm một cái là kết nối.',
            style: TextStyle(fontSize: 11, color: MyTheme.darkGray, height: 1.4),
          ),
          const Divider(height: 14),
        ],
      ),
    );
  }

  Widget _deviceTile(Map<String, dynamic> d) {
    final id = '${d['rustdesk_id'] ?? ''}';
    final rawName = '${d['name'] ?? ''}';
    final name = rawName.isNotEmpty ? rawName : id;
    final online = d['online'] == true;
    final paid = d['paid'] != false;
    return InkWell(
      onTap: online ? () => _connect(id) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: online ? Colors.green : Colors.grey.withOpacity(0.5)),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12)),
                  Text(id,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: MyTheme.darkGray)),
                ],
              ),
            ),
            if (!paid)
              Tooltip(
                message: 'Máy chưa trả phí',
                child: Icon(Icons.warning_amber, size: 13, color: Colors.orange),
              ),
            if (online)
              Icon(Icons.play_circle_fill, size: 16, color: MyTheme.accent),
          ],
        ),
      ),
    );
  }
}
