import 'package:flutter/material.dart';

import '../../services/user_session.dart';
import 'account_forms.dart';
import 'user_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void>? _request;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (UserScope.of(context).user != null) {
      _request ??= UserScope.of(context).refreshProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = UserScope.of(context);
    final user = session.user;
    return UserPage(
      title: 'Profil saya',
      requiresLogin: true,
      children: [
        FutureBuilder<void>(
          future: _request,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Column(
                children: [
                  Text(snapshot.error.toString()),
                  OutlinedButton(
                    onPressed: () =>
                        setState(() => _request = session.refreshProfile()),
                    child: const Text('Coba lagi'),
                  ),
                ],
              );
            }
            final avatar = user?.text('avatar_url') ?? '';
            return Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  child: avatar.isEmpty
                      ? const Icon(Icons.person_outline, size: 40)
                      : ClipOval(
                          child: Image.network(
                            avatar,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            errorBuilder: (_, error, stack) =>
                                const Icon(Icons.person_outline, size: 40),
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                for (final entry in const {
                  'full_name': 'Nama lengkap',
                  'username': 'Username',
                  'email': 'Email',
                  'phone': 'Nomor telepon',
                  'city': 'Kota',
                  'country': 'Negara',
                }.entries)
                  ListTile(
                    title: Text(entry.value),
                    subtitle: Text(
                      (user?.text(entry.key) ?? '').isEmpty
                          ? 'Belum diisi'
                          : user!.text(entry.key),
                    ),
                  ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () =>
                      openUserPage(context, const EditProfilePage()),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit profil'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});
  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  Future<Map<String, dynamic>>? _request;
  int _page = 1;
  bool _busy = false;
  String? _error;
  int? _undoId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (UserScope.of(context).user != null) {
      _request ??= UserScope.of(context).api
          .request('GET', 'wishlist/?page=$_page');
    }
  }

  void _load([int? page]) {
    final api = UserScope.of(context).api;
    setState(() {
      _page = page ?? _page;
      _request = api.request('GET', 'wishlist/?page=$_page');
    });
  }

  Future<void> _mutate(int id, {bool restore = false}) async {
    if (_busy) return;
    final api = UserScope.of(context).api;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await api.request(
        restore ? 'POST' : 'DELETE',
        'wishlist/$id/${restore ? 'restore/' : ''}',
      );
      if (!mounted) return;
      setState(() => _undoId = restore ? null : id);
      _load(1);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => UserPage(
    title: 'Wishlist',
    requiresLogin: true,
    children: [
      if (_error != null) Text(_error!),
      if (_undoId != null)
        OutlinedButton(
          onPressed: _busy ? null : () => _mutate(_undoId!, restore: true),
          child: const Text('Urungkan penghapusan terakhir'),
        ),
      FutureBuilder<Map<String, dynamic>>(
        future: _request,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Column(
              children: [
                Text(snapshot.error.toString()),
                OutlinedButton(
                  onPressed: () => _load(1),
                  child: const Text('Coba lagi'),
                ),
              ],
            );
          }
          final data = snapshot.data;
          final rows = (data?['results'] as List?) ?? [];
          return Column(
            children: [
              if (rows.isEmpty) ...[
                const Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Belum ada produk favorit. Simpan produk dari katalog Gaia.',
                ),
              ],
              for (final row in rows)
                Card(
                  child: ListTile(
                    title: Text(row['title'] as String),
                    subtitle: Text('Rp${row['price']} · ${row['condition']}'),
                    trailing: IconButton(
                      tooltip: 'Hapus ${row['title']}',
                      icon: const Icon(Icons.favorite),
                      onPressed: _busy ? null : () => _mutate(row['id'] as int),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  TextButton(
                    onPressed: !_busy && data?['previous'] != null
                        ? () => _load(_page - 1)
                        : null,
                    child: const Text('Sebelumnya'),
                  ),
                  Text('Halaman $_page'),
                  TextButton(
                    onPressed: !_busy && data?['next'] != null
                        ? () => _load(_page + 1)
                        : null,
                    child: const Text('Berikutnya'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    ],
  );
}

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});
  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _busy = false;
  String? _message;

  Future<void> _run(Future<void> Function(UserSession) action) async {
    final session = UserScope.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action(session);
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Gaia?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _run((session) async {
      await session.logout();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = UserScope.of(context).user;
    return UserPage(
      title: 'Pengaturan akun',
      requiresLogin: true,
      children: [
        ListTile(
          leading: const Icon(Icons.mark_email_unread_outlined),
          title: const Text('Verifikasi email'),
          subtitle: Text(
            user?.emailVerified == true
                ? 'Email terverifikasi'
                : 'Email belum terverifikasi',
          ),
        ),
        OutlinedButton(
          onPressed: _busy || user?.emailVerified == true
              ? null
              : () => _run((session) async {
                  final result = await session.api.request(
                    'POST',
                    'verify/resend/',
                  );
                  if (mounted) {
                    setState(() => _message = result['detail'] as String);
                  }
                }),
          child: const Text('Kirim ulang verifikasi'),
        ),
        OutlinedButton(
          onPressed: _busy
              ? null
              : () => _run((session) => session.refreshProfile()),
          child: const Text('Perbarui status email'),
        ),
        if (user?.hasPassword == true)
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Ganti password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy
                ? null
                : () => openUserPage(context, const ChangePasswordPage()),
          )
        else
          const Text(
            'Akun ini menggunakan login eksternal. Kelola akses dan penghapusan akun melalui situs Gaia.',
          ),
        const Divider(height: 32),
        if (_message != null) Text(_message!),
        if (_busy) const Center(child: CircularProgressIndicator()),
        OutlinedButton(
          onPressed: _busy ? null : _logout,
          child: const Text('Keluar'),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _busy || user?.hasPassword != true
              ? null
              : () => openUserPage(context, const DeleteAccountPage()),
          child: const Text('Hapus akun'),
        ),
      ],
    );
  }
}
