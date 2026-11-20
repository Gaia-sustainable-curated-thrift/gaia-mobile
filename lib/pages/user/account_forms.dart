import 'package:flutter/material.dart';

import 'user_page.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => UserPage(
    title: 'Masuk',
    children: [
      const AccountField('Email atau username'),
      const AccountField('Password', secret: true),
      const FilledButton(onPressed: null, child: Text('Masuk')),
      TextButton(
        onPressed: () => openUserPage(context, const ResetPasswordPage()),
        child: const Text('Lupa password?'),
      ),
      TextButton(
        onPressed: () => openUserPage(context, const RegisterPage()),
        child: const Text('Belum punya akun? Daftar'),
      ),
    ],
  );
}

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) => const UserPage(
    title: 'Buat akun',
    children: [
      AccountField('Nama lengkap'),
      AccountField('Email', keyboardType: TextInputType.emailAddress),
      AccountField('Password', secret: true),
      AccountField('Konfirmasi password', secret: true),
      FilledButton(onPressed: null, child: Text('Daftar')),
    ],
  );
}

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) => const UserPage(
    title: 'Edit profil',
    children: [
      CircleAvatar(radius: 36, child: Icon(Icons.person_outline, size: 40)),
      TextButton(onPressed: null, child: Text('Ubah foto profil')),
      Text('Foto JPG, PNG, atau WebP, maksimal 2 MB.'),
      SizedBox(height: 20),
      AccountField('Nama lengkap'),
      AccountField('Username'),
      AccountField('Email (tidak dapat diubah)', enabled: false),
      AccountField('Nomor telepon', keyboardType: TextInputType.phone),
      AccountField('Kota'),
      AccountField('Negara'),
      FilledButton(onPressed: null, child: Text('Simpan perubahan')),
    ],
  );
}

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) => const UserPage(
    title: 'Reset password',
    children: [
      Text(
        'Tautan pemulihan akan dikirim ke email akun setelah layanan akun terhubung.',
      ),
      SizedBox(height: 20),
      AccountField('Email', keyboardType: TextInputType.emailAddress),
      FilledButton(onPressed: null, child: Text('Kirim tautan reset')),
    ],
  );
}

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) => const UserPage(
    title: 'Ganti password',
    children: [
      AccountField('Password saat ini', secret: true),
      AccountField('Password baru', secret: true),
      AccountField('Konfirmasi password baru', secret: true),
      FilledButton(onPressed: null, child: Text('Ganti password')),
    ],
  );
}
