import 'package:flutter/material.dart';

import '../../core/session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  bool _registerMode = false;
  bool _busy = false;
  String _error = '';

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _error = '';
    });
    var ok = true;
    if (_registerMode) {
      ok = await Session.I.api
          .register(_email.text.trim(), _pass.text, _name.text.trim());
    }
    if (ok) {
      // پس از ثبت‌نام، ورود کامل برای ذخیرهٔ پایدار نشست
      ok = await Session.I.login(_email.text.trim(), _pass.text);
    }
    setState(() => _busy = false);
    if (!ok && mounted) setState(() => _error = 'ورود ناموفق — اطلاعات را ببینید');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                const Text('★ BAZİNO ★',
                    style: TextStyle(fontSize: 44, color: Color(0xFF57D6FF))),
                const SizedBox(height: 8),
                const Text('اپ پیگیری پیشرفت درسی فرزند شما',
                    style: TextStyle(fontSize: 16)),
                const SizedBox(height: 28),
                if (_registerMode)
                  TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                          labelText: 'نمایش نام', border: OutlineInputBorder())),
                if (_registerMode) const SizedBox(height: 12),
                TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                        labelText: 'ایمیل', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(
                    controller: _pass,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'رمز', border: OutlineInputBorder())),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _go,
                    child: Text(_busy
                        ? '…'
                        : _registerMode
                            ? 'ثبت‌نام والد'
                            : 'ورود'),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _registerMode = !_registerMode),
                  child: Text(_registerMode
                      ? 'حساب دارید؟ ورود'
                      : 'حساب ندارید؟ ثبت‌نام'),
                ),
                if (_error.isNotEmpty)
                  Text(_error, style: const TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
