import 'package:flutter/material.dart';

import 'user/account_forms.dart';
import 'user/account_sections.dart';
import 'user/user_page.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    return UserPage(
      children: [
        const CircleAvatar(
          radius: 36,
          child: Icon(Icons.person_outline, size: 40),
        ),
        const SizedBox(height: 16),
        Text(
          'Ruang preloved kamu',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Kelola profil dan simpan barang favoritmu di Gaia.'),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => openUserPage(context, const LoginPage()),
          child: const Text('Masuk'),
        ),
        OutlinedButton(
          onPressed: () => openUserPage(context, const RegisterPage()),
          child: const Text('Buat akun'),
        ),
        const SizedBox(height: 24),
        const Text('Jelajahi halaman akun'),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              _menu(
                context,
                Icons.person_outline,
                'Profil saya',
                'Identitas dan informasi kontak',
                const ProfilePage(),
              ),
              _menu(
                context,
                Icons.favorite_border,
                'Wishlist',
                'Koleksi produk favorit',
                const WishlistPage(),
              ),
              _menu(
                context,
                Icons.security_outlined,
                'Pengaturan akun',
                'Email, password, dan keamanan',
                const AccountSettingsPage(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _menu(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Widget page,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => openUserPage(context, page),
    );
  }
}
