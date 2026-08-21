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
      final j = jsonDecode(res) as Map<String, dynamic>;
      final list = (j['devices'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      // Bỏ chính máy này; chỉ giữ máy đã có rustdesk_id (mới kết nối được).
      final others = list
          .where((d) =>
              d['is_self'] != true && '${d['rustdesk_id'] ?? ''}'.isNotEmpty)
          .toList();
      // Online lên trước.
      others.sort((a, b) =>
          (b['online'] == true ? 1 : 0) - (a['online'] == true ? 1 : 0));
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
    if (!bind.nexusClientIsLoggedIn()) return const Offstage();
    // Chưa có máy nào khác trong tài khoản → ẩn hẳn, không chiếm chỗ.
    if (_loaded && _devices.isEmpty) return const Offstage();
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
