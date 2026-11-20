import 'package:flutter/material.dart';

import '../../services/user_session.dart';
import 'user_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  @override
  Widget build(BuildContext context) => const _AccountForm(_Mode.login);
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});
  @override
  Widget build(BuildContext context) => const _AccountForm(_Mode.register);
}

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});
  @override
  Widget build(BuildContext context) => const _AccountForm(_Mode.edit);
}

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});
  @override
  Widget build(BuildContext context) => const _AccountForm(_Mode.reset);
}

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});
  @override
  Widget build(BuildContext context) => const _AccountForm(_Mode.password);
}

class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({super.key});
  @override
  Widget build(BuildContext context) => const _AccountForm(_Mode.delete);
}

enum _Mode { login, register, edit, reset, password, delete }

typedef _Field = ({String key, String label, bool secret});
_Field _field(String key, String label, {bool secret = false}) =>
    (key: key, label: label, secret: secret);

class _AccountForm extends StatefulWidget {
  const _AccountForm(this.mode);
  final _Mode mode;
  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  final _form = GlobalKey<FormState>();
  late final List<_Field> _fields;
  late final Map<String, TextEditingController> _controllers;
  bool _initialized = false;
  bool _busy = false;
  bool _acknowledge = false;
  String? _error;
  String? _message;

  String get _title => switch (widget.mode) {
    _Mode.login => 'Masuk',
    _Mode.register => 'Buat akun',
    _Mode.edit => 'Edit profil',
    _Mode.reset => 'Reset password',
    _Mode.password => 'Ganti password',
    _Mode.delete => 'Hapus akun',
  };

  String get _submitLabel => switch (widget.mode) {
    _Mode.register => 'Daftar',
    _Mode.edit => 'Simpan perubahan',
    _Mode.reset => 'Kirim tautan reset',
    _ => _title,
  };

  @override
  void initState() {
    super.initState();
    _fields = switch (widget.mode) {
      _Mode.login => [
        _field('username', 'Email atau username'),
        _field('password', 'Password', secret: true),
      ],
      _Mode.register => [
        _field('full_name', 'Nama lengkap'),
        _field('email', 'Email'),
        _field('password1', 'Password', secret: true),
        _field('password2', 'Konfirmasi password', secret: true),
      ],
      _Mode.edit => [
        _field('full_name', 'Nama lengkap'),
        _field('username', 'Username'),
        _field('email', 'Email (tidak dapat diubah)'),
        _field('phone', 'Nomor telepon'),
        _field('city', 'Kota'),
        _field('country', 'Negara'),
      ],
      _Mode.reset => [_field('email', 'Email')],
      _Mode.password => [
        _field('old_password', 'Password saat ini', secret: true),
        _field('new_password1', 'Password baru', secret: true),
        _field('new_password2', 'Konfirmasi password baru', secret: true),
      ],
      _Mode.delete => [
        _field('password', 'Password saat ini', secret: true),
        _field('confirmation', 'Ketik DELETE'),
      ],
    };
    _controllers = {
      for (final field in _fields) field.key: TextEditingController(),
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      if (widget.mode == _Mode.edit) {
        final user = UserScope.of(context).user;
        for (final entry in _controllers.entries) {
          entry.value.text = user?.text(entry.key) ?? '';
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _validate(_Field field, String? value) {
    if (field.key == 'email' && widget.mode == _Mode.edit) return null;
    if (value == null || value.trim().isEmpty) {
      return '${field.label} wajib diisi.';
    }
    if (field.key == 'email' &&
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())) {
      return 'Masukkan alamat email yang valid.';
    }
    if (field.key == 'password2' && value != _controllers['password1']!.text ||
        field.key == 'new_password2' &&
            value != _controllers['new_password1']!.text) {
      return 'Konfirmasi password tidak sama.';
    }
    if (field.key == 'confirmation' && value != 'DELETE') {
      return 'Ketik DELETE persis.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (widget.mode == _Mode.delete && !_acknowledge) {
      setState(() => _error = 'Setujui penghapusan akun terlebih dahulu.');
      return;
    }
    final session = UserScope.of(context);
    final values = <String, dynamic>{
      for (final field in _fields)
        if (!(widget.mode == _Mode.edit && field.key == 'email'))
          field.key: field.secret
              ? _controllers[field.key]!.text
              : _controllers[field.key]!.text.trim(),
    };
    setState(() {
      _busy = true;
      _error = null;
      _message = null;
    });
    try {
      switch (widget.mode) {
        case _Mode.login:
        case _Mode.register:
          final warning = await session.authenticate(
            widget.mode == _Mode.login ? 'login' : 'register',
            values,
          );
          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
          if (warning != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(warning)));
          }
        case _Mode.edit:
          await session.saveProfile(values);
          if (!mounted) return;
          Navigator.of(context).pop();
        case _Mode.reset:
          final response = await session.api.request(
            'POST',
            'password/reset/',
            values,
          );
          if (!mounted) return;
          setState(() => _message = response['detail'] as String);
        case _Mode.password:
          await session.api.request('POST', 'password/change/', values);
          session.clear();
          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password diubah. Silakan masuk kembali.'),
            ),
          );
        case _Mode.delete:
          await session.api.request('DELETE', 'me/', {
            ...values,
            'acknowledge': _acknowledge,
          });
          session.clear();
          if (!mounted) return;
          Navigator.of(context).popUntil((route) => route.isFirst);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Akun berhasil dihapus.')),
          );
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return UserPage(
      title: _title,
      requiresLogin: [
        _Mode.edit,
        _Mode.password,
        _Mode.delete,
      ].contains(widget.mode),
      children: [
        if (widget.mode == _Mode.reset) ...[
          const Text(
            'Tautan pemulihan dikirim ke email akun. Buka tautan tersebut untuk memilih password baru.',
          ),
          const SizedBox(height: 20),
        ],
        if (widget.mode == _Mode.edit) ...[
          const Text(
            'Informasi profil tersimpan pada akun Gaia yang sama dengan web. Penggantian foto tersedia melalui web.',
          ),
          const SizedBox(height: 20),
        ],
        if (widget.mode == _Mode.delete) ...[
          const Text(
            'Penghapusan akun bersifat permanen. Selesaikan pesanan pembelian dan penjualan terlebih dahulu.',
          ),
          const SizedBox(height: 20),
        ],
        Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final field in _fields)
                AccountField(
                  field.label,
                  controller: _controllers[field.key],
                  secret: field.secret,
                  enabled:
                      !_busy &&
                      !(widget.mode == _Mode.edit && field.key == 'email'),
                  keyboardType: field.key == 'email'
                      ? TextInputType.emailAddress
                      : field.key == 'phone'
                      ? TextInputType.phone
                      : null,
                  validator: (value) => _validate(field, value),
                ),
              if (widget.mode == _Mode.delete)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Saya memahami akun dan data terkait akan dihapus permanen.',
                  ),
                  value: _acknowledge,
                  onChanged: _busy
                      ? null
                      : (value) =>
                            setState(() => _acknowledge = value ?? false),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_message!),
                ),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Memproses...' : _submitLabel),
              ),
            ],
          ),
        ),
        if (widget.mode == _Mode.login) ...[
          TextButton(
            onPressed: _busy
                ? null
                : () => openUserPage(context, const ResetPasswordPage()),
            child: const Text('Lupa password?'),
          ),
          TextButton(
            onPressed: _busy
                ? null
                : () => openUserPage(context, const RegisterPage()),
            child: const Text('Belum punya akun? Daftar'),
          ),
        ],
      ],
    );
  }
}
