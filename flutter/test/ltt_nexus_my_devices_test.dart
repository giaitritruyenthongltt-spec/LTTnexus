// Test cho phần LỌC + SẮP XẾP danh sách "Máy của tôi" (onboarding 1-chạm).
//
// Đây là logic người dùng nhìn thấy đầu tiên sau khi đăng nhập, và là chỗ dễ
// sai nhất: hiện nhầm chính máy mình, hiện máy chưa kết nối tới được, sai thứ
// tự, hoặc vỡ vì JSON lạ. Tách khỏi widget nên test được không cần FFI.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_hbb/ltt/nexus_my_devices.dart';

String _js(List<Map<String, dynamic>> ds) => jsonEncode({'devices': ds});

void main() {
  test('bo chinh may nay (is_self)', () {
    final ra = locSapXepMay(_js([
      {'device_id': 'a', 'rustdesk_id': '111', 'is_self': true},
      {'device_id': 'b', 'rustdesk_id': '222', 'is_self': false},
    ]));
    expect(ra.length, 1);
    expect(ra.first['device_id'], 'b');
  });

  test('bo may chua co rustdesk_id (chua ket noi toi duoc)', () {
    final ra = locSapXepMay(_js([
      {'device_id': 'a', 'rustdesk_id': '', 'is_self': false},
      {'device_id': 'b', 'is_self': false},
      {'device_id': 'c', 'rustdesk_id': '333', 'is_self': false},
    ]));
    expect(ra.map((e) => e['device_id']), ['c']);
  });

  test('may dang bat xep len truoc', () {
    final ra = locSapXepMay(_js([
      {'device_id': 'tat', 'rustdesk_id': '1', 'online': false},
      {'device_id': 'bat', 'rustdesk_id': '2', 'online': true},
      {'device_id': 'tat2', 'rustdesk_id': '3', 'online': false},
    ]));
    expect(ra.first['device_id'], 'bat');
    expect(ra.length, 3);
  });

  test('JSON hong -> rong, khong nem', () {
    expect(locSapXepMay(''), isEmpty);
    expect(locSapXepMay('khong-phai-json'), isEmpty);
    expect(locSapXepMay('null'), isEmpty);
    expect(locSapXepMay('[]'), isEmpty);
    expect(locSapXepMay('{"devices":"khong-phai-list"}'), isEmpty);
    expect(locSapXepMay('{}'), isEmpty);
  });

  test('loi tu server (co truong error) -> rong, khong nem', () {
    expect(locSapXepMay('{"devices":[],"error":"chua dang nhap"}'), isEmpty);
  });

  test('phan tu la trong danh sach thi bo qua, khong lam hong ca danh sach', () {
    final ra = locSapXepMay('{"devices":[1,"x",null,{"rustdesk_id":"9"}]}');
    expect(ra.length, 1);
    expect(ra.first['rustdesk_id'], '9');
  });

  test('giu nguyen truong hien thi (ten, paid) de widget dung', () {
    final ra = locSapXepMay(_js([
      {'device_id': 'a', 'rustdesk_id': '1', 'name': 'May A', 'paid': false},
    ]));
    expect(ra.first['name'], 'May A');
    expect(ra.first['paid'], false);
  });
}
