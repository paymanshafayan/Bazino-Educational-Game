import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';

/// Session — توکن، کد(های) خانواده → فرزند(ها). ChangeNotifier ساده (بدون وابستگی اضافی).
class Session extends ChangeNotifier {
  Session._();
  static final Session I = Session._();

  final api = ApiClient();
  String? token;
  int? parentId;
  String displayName = '';
  List<int> childIds = [];

  bool get loggedIn => token != null;

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    token = sp.getString('token');
    api.token = token;
    parentId = sp.getInt('parent_id');
    displayName = sp.getString('display_name') ?? '';
    childIds = (sp.getStringList('child_ids') ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .toList();
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    final ok = await api.login(email, password);
    if (!ok) return false;
    token = api.token;
    parentId = api.parentId;
    displayName = api.displayName;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('token', token!);
    if (parentId != null) await sp.setInt('parent_id', parentId!);
    await sp.setString('display_name', displayName);
    await refreshLinks();
    return true;
  }

  Future<void> refreshLinks() async {
    final links = await api.myLinks();
    childIds = links
        .where((l) => l.active && l.childId != null)
        .map((l) => l.childId!)
        .toSet()
        .toList();
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(
        'child_ids', childIds.map((e) => e.toString()).toList());
    notifyListeners();
  }

  Future<void> logout() async {
    token = null;
    parentId = null;
    childIds = [];
    api.token = null;
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
    notifyListeners();
  }
}
