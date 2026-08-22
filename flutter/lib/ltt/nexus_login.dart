// LTT Nexus (Model B — Q101 / D-P7): màn đăng nhập tài khoản LTT trong client.
//
// Khách đăng nhập bằng email+mật khẩu LTT; client gọi `nexus_client_register`
// (Rust) để đăng ký MÁY này dưới tài khoản (cho tính phí Q98). Kết nối tới máy
// khác vẫn nhập tay ID+mật khẩu (v1) — màn này chỉ lo tài khoản/thuê bao.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:url_launcher/url_launcher.dart';

/// Máy chủ tài khoản/thuê bao LTT. Có thể trỏ nơi khác khi thử bằng local option
/// `ltt-nexus-server`; mặc định là nền tảng LTT thật.
String nexusServer() {
  try {
    final s = bind.mainGetLocalOption(key: 'ltt-nexus-server');
    if (s.trim().isNotEmpty) return s.trim();
  } catch (_) {}
  return 'https://app.lttstudios.com';
}

/// Thanh tài khoản trên trang chủ (sau khi đăng nhập): email · credit · nút
/// "Nạp credit" (mở trình duyệt, Q98) · đăng xuất. Hỏi `/status` định kỳ và cảnh
/// báo khi hết credit (hết credit → không điều khiển được, Q98).
class NexusAccountBar extends StatefulWidget {
  final VoidCallback onChanged;
  const NexusAccountBar({Key? key, required this.onChanged}) : super(key: key);

  @override
  State<NexusAccountBar> createState() => _NexusAccountBarState();
}

class _NexusAccountBarState extends State<NexusAccountBar> {
  bool _paid = true;
  int _credit = 0;
  int _price = 0;
  String _updateUrl = ''; // != '' → có bản mới
  bool _dangKiem = false;      // đang kiểm bản mới (bấm tay)
  String _ketQuaKiem = '';     // thông báo sau khi bấm kiểm
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final res = await bind.nexusClientStatus(baseUrl: nexusServer());
      final j = jsonDecode(res) as Map<String, dynamic>;
      if (!mounted) return;
      // Lỗi mạng KHÔNG phải là "hết credit": chỉ đổi trạng thái khi server thật
      // sự trả về trường `paid`, còn lại giữ nguyên cái đã biết.
      //
      // KHÔNG `return` ở đây: nó thoát cả hàm và bỏ luôn phần kiểm bản mới bên
      // dưới — tức là một lần chớp mạng làm người dùng ngừng được báo cập nhật.
      if (j['paid'] is bool) {
        setState(() {
          _paid = j['paid'] == true;
          _credit = (j['credit_balance'] ?? 0) is int
              ? (j['credit_balance'] ?? 0) as int
              : int.tryParse('${j['credit_balance']}') ?? 0;
          _price = (j['price_per_month'] ?? 0) is int
              ? (j['price_per_month'] ?? 0) as int
              : int.tryParse('${j['price_per_month']}') ?? 0;
        });
      }
    } catch (_) {}
    // Kiểm bản mới (không cần đăng nhập; fail-open → '' nếu lỗi/không có bản).
    try {
      final u = await bind.nexusClientCheckUpdate(baseUrl: nexusServer());
      if (mounted) setState(() => _updateUrl = u);
    } catch (_) {}
  }

  /// Kiểm bản mới NGAY khi người dùng bấm.
  ///
  /// Vì sao cần dù đã tự kiểm mỗi phút: người dùng cần một chỗ **hỏi được** và
  /// nhận **câu trả lời rõ ràng**. Không có nó thì "im lặng" vừa có nghĩa là
  /// đang dùng bản mới nhất, vừa có nghĩa là việc kiểm đang hỏng — không phân
  /// biệt được.
  Future<void> _kiemCapNhat() async {
    if (_dangKiem) return;
    setState(() {
      _dangKiem = true;
      _ketQuaKiem = '';
    });
    String u = '';
    try {
      u = await bind.nexusClientCheckUpdate(baseUrl: nexusServer());
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _dangKiem = false;
      _updateUrl = u;
      _ketQuaKiem = u.isEmpty ? 'Đang dùng bản mới nhất.' : '';
    });
  }

  void _logout() {
    try {
      bind.nexusClientLogout();
    } catch (_) {}
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final email = () {
      try {
        return bind.nexusClientEmail();
      } catch (_) {
        return '';
      }
    }();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            children: [
              Icon(Icons.account_circle, size: 18, color: MyTheme.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12)),
              ),
              if (_price > 0)
                Text('$_credit cr',
                    style: TextStyle(fontSize: 12, color: MyTheme.darkGray)),
              IconButton(
                tooltip: 'Nạp credit',
                icon: Icon(Icons.add_card, size: 18, color: MyTheme.accent),
                onPressed: () => launchUrl(Uri.parse('${nexusServer()}/nap')),
              ),
              IconButton(
                tooltip: 'Kiểm bản cập nhật',
                icon: _dangKiem
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.8))
                    : const Icon(Icons.system_update_alt, size: 17),
                onPressed: _dangKiem ? null : _kiemCapNhat,
              ),
              IconButton(
                tooltip: 'Đăng xuất',
                icon: const Icon(Icons.logout, size: 16),
                onPressed: _logout,
              ),
            ],
          ),
        ),
        if (_price > 0 && !_paid)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF421511),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Hết credit — nạp thêm để điều khiển máy.',
                      style: TextStyle(color: Color(0xFFFFD0CC), fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => launchUrl(Uri.parse('${nexusServer()}/nap')),
                  child: Text('Nạp credit',
                      style: TextStyle(color: MyTheme.accent, fontSize: 12)),
                ),
              ],
            ),
          ),
        if (_ketQuaKiem.isNotEmpty && _updateUrl.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(_ketQuaKiem,
                style: TextStyle(fontSize: 11.5, color: MyTheme.darkGray)),
          ),
        if (_updateUrl.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            color: const Color(0xFF1A1412),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Đã có bản LTT Nexus mới.',
                      style: TextStyle(fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => launchUrl(Uri.parse(_updateUrl)),
                  child: Text('Cập nhật',
                      style: TextStyle(color: MyTheme.accent, fontSize: 12)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class NexusLoginPage extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const NexusLoginPage({Key? key, required this.onLoggedIn}) : super(key: key);

  @override
  State<NexusLoginPage> createState() => _NexusLoginPageState();
}

class _NexusLoginPageState extends State<NexusLoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _busy = false;
  String _error = '';
  String _updateUrl = '';

  @override
  void initState() {
    super.initState();
    // Kiểm bản mới NGAY Ở MÀN ĐĂNG NHẬP. Trước đây banner cập nhật chỉ nằm
    // trong thanh tài khoản, mà thanh đó chỉ hiện SAU khi đăng nhập — nên người
    // chưa đăng nhập (hoặc vừa đăng xuất) không bao giờ biết có bản mới, kể cả
    // khi bản họ đang chạy đã cũ hàng tháng. Việc kiểm không cần tài khoản.
    () async {
      try {
        final u = await bind.nexusClientCheckUpdate(baseUrl: nexusServer());
        if (mounted) setState(() => _updateUrl = u);
      } catch (_) {}
    }();
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_busy) return;
    final email = _email.text.trim();
    if (email.isEmpty || _pass.text.isEmpty) {
      setState(() => _error = 'Nhập email và mật khẩu.');
      return;
    }
    setState(() {
      _busy = true;
      _error = '';
    });
    String hostname = 'PC';
    try {
      hostname = Platform.localHostname;
    } catch (_) {}
    try {
      final res = await bind.nexusClientRegister(
        baseUrl: nexusServer(),
        email: email,
        password: _pass.text,
        displayName: hostname,
        platform: 'windows',
      );
      final j = jsonDecode(res) as Map<String, dynamic>;
      if (j['ok'] == true) {
        widget.onLoggedIn();
        return;
      }
      setState(() => _error = (j['error'] ?? 'Đăng nhập thất bại').toString());
    } catch (_) {
      setState(() => _error = 'Không kết nối được máy chủ LTT.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 56, child: Center(child: loadLogo())),
                const SizedBox(height: 14),
                const Text('LTT Nexus',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text('Đăng nhập bằng tài khoản LTT',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: MyTheme.darkGray)),
                if (_updateUrl.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () => launchUrl(Uri.parse(_updateUrl)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1412),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: MyTheme.accent.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.system_update_alt,
                              size: 16, color: MyTheme.accent),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text('Đã có bản LTT Nexus mới',
                                style: TextStyle(fontSize: 12)),
                          ),
                          Text('Cập nhật',
                              style: TextStyle(
                                  fontSize: 12, color: MyTheme.accent)),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                TextField(
                  controller: _email,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  obscureText: true,
                  onSubmitted: (_) => _login(),
                  decoration: const InputDecoration(
                    labelText: 'Mật khẩu',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(_error,
                      style:
                          const TextStyle(color: Color(0xFFEF3731), fontSize: 13)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _login,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Đăng nhập'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () =>
                        launchUrl(Uri.parse('${nexusServer()}/register')),
                    child: Text('Chưa có tài khoản? Đăng ký',
                        style: TextStyle(fontSize: 12, color: MyTheme.accent)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
