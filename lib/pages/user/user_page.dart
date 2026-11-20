import 'package:flutter/material.dart';

void openUserPage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

/// Shared scrollable layout for the checkpoint 1 account screens.
class UserPage extends StatelessWidget {
  const UserPage({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Pratinjau modul User · Checkpoint 1\n'
                    'Belum terhubung ke akun. Data tidak dikirim atau disimpan.',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
    if (title == null) return content;
    return Scaffold(
      appBar: AppBar(title: Text(title!)),
      body: content,
    );
  }
}

class AccountField extends StatelessWidget {
  const AccountField(
    this.label, {
    super.key,
    this.secret = false,
    this.keyboardType,
    this.enabled = true,
  });

  final String label;
  final bool secret;
  final TextInputType? keyboardType;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      enabled: enabled,
      obscureText: secret,
      autocorrect: !secret,
      enableSuggestions: !secret,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
