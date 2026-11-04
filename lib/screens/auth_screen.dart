import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/session.dart';
import '../theme.dart';
import '../widgets/common.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _register = false;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    for (final c in [_name, _username, _email, _login, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    final session = context.read<Session>();
    try {
      if (_register) {
        await session.register(
          name: _name.text.trim(),
          username: _username.text.trim(),
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        await session.login(_login.text.trim(), _password.text);
      }
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editServer() async {
    final session = context.read<Session>();
    final controller = TextEditingController(text: session.serverUrl);
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server manzili'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(hintText: 'http://192.168.1.10:3000'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Bekor')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Saqlash')),
        ],
      ),
    );
    controller.dispose();
    if (url != null && Uri.tryParse(url.trim())?.hasScheme == true) {
      await session.setServerUrl(url);
    } else if (url != null && mounted) {
      showInfo(context, 'Manzil http:// yoki https:// bilan boshlanishi kerak');
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? "To'ldiring" : null;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(tooltip: 'Server manzili', icon: const Icon(Icons.dns_outlined), onPressed: _editServer),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const NexLogo(size: 72),
                    const SizedBox(height: 12),
                    Text('Nex Map', textAlign: TextAlign.center, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(
                      "Xarita, do'stlar va mashg'ulotlar bir joyda",
                      textAlign: TextAlign.center,
                      style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.outline),
                    ),
                    const SizedBox(height: 32),
                    if (_register) ...[
                      TextFormField(
                        controller: _name,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Ism', prefixIcon: Icon(Icons.person_outline)),
                        validator: _required,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _username,
                        autocorrect: false,
                        decoration: const InputDecoration(labelText: 'Foydalanuvchi nomi', prefixIcon: Icon(Icons.alternate_email)),
                        validator: (v) {
                          if (v == null || !RegExp(r'^[a-zA-Z0-9_.]{3,30}$').hasMatch(v.trim())) {
                            return '3-30 belgi: harf, raqam, _ yoki .';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        autocorrect: false,
                        decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                        validator: (v) => (v == null || !v.contains('@')) ? "Email noto'g'ri" : null,
                      ),
                    ] else
                      TextFormField(
                        controller: _login,
                        autocorrect: false,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email yoki foydalanuvchi nomi',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: _required,
                      ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      obscureText: _hidePassword,
                      decoration: InputDecoration(
                        labelText: 'Parol',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "To'ldiring";
                        if (_register && v.length < 8) return 'Kamida 8 belgi';
                        return null;
                      },
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : Text(_register ? "Ro'yxatdan o'tish" : 'Kirish'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _busy ? null : () => setState(() => _register = !_register),
                      child: Text(_register ? 'Hisobingiz bormi? Kirish' : "Hisobingiz yo'qmi? Ro'yxatdan o'ting"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
