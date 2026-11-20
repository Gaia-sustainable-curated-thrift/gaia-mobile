import 'package:flutter/material.dart';

import 'account_forms.dart';
import 'user_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => UserPage(
    title: 'Profil saya',
    children: [
      const CircleAvatar(
        radius: 36,
        child: Icon(Icons.person_outline, size: 40),
      ),
      const SizedBox(height: 16),
      const Text('Belum ada profil terhubung'),
      const SizedBox(height: 16),
      for (final field in [
        'Nama lengkap',
        'Username',
        'Email',
        'Nomor telepon',
        'Kota',
        'Negara',
      ])
        ListTile(title: Text(field), subtitle: const Text('Belum tersedia')),
      const SizedBox(height: 16),
      OutlinedButton.icon(
        onPressed: () => openUserPage(context, const EditProfilePage()),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit profil'),
      ),
    ],
  );
}

class WishlistPage extends StatelessWidget {
  const WishlistPage({super.key});

  @override
  Widget build(BuildContext context) => const UserPage(
    title: 'Wishlist',
    children: [
      Icon(Icons.favorite_border, size: 64, color: Colors.green),
      SizedBox(height: 20),
      Text(
        'Produk favoritmu punya tempat di sini',
        textAlign: TextAlign.center,
      ),
      SizedBox(height: 8),
      Text(
        'Wishlist akun akan ditampilkan setelah layanan akun terhubung.',
        textAlign: TextAlign.center,
      ),
    ],
  );
}

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => UserPage(
    title: 'Pengaturan akun',
    children: [
      const ListTile(
        leading: Icon(Icons.mark_email_unread_outlined),
        title: Text('Verifikasi email'),
        subtitle: Text('Status email belum tersedia'),
      ),
      const OutlinedButton(
        onPressed: null,
        child: Text('Kirim ulang verifikasi'),
      ),
      ListTile(
        leading: const Icon(Icons.lock_outline),
        title: const Text('Ganti password'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => openUserPage(context, const ChangePasswordPage()),
      ),
      const Divider(height: 32),
      const OutlinedButton(onPressed: null, child: Text('Keluar')),
      const SizedBox(height: 16),
      const Text('Penghapusan akun'),
      const SizedBox(height: 8),
      const Text(
        'Penghapusan memerlukan konfirmasi dan pemeriksaan pesanan aktif. Fitur ini belum tersedia pada pratinjau.',
      ),
      const TextButton(onPressed: null, child: Text('Hapus akun')),
    ],
  );
}
