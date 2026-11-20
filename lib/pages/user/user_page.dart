import 'package:flutter/material.dart';

import '../../services/user_session.dart';

void openUserPage(BuildContext context, Widget page) {
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
}

/// Shared scrollable layout for connected account screens.
class UserPage extends StatelessWidget {
  const UserPage({
    super.key,
    this.title,
    required this.children,
    this.requiresLogin = false,
  });

  final String? title;
  final List<Widget> children;
  final bool requiresLogin;

  @override
  Widget build(BuildContext context) {
    final signedIn = UserScope.of(context).user != null;
    final content = SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (requiresLogin && !signedIn) ...[
                const Text(
                  'Sesi berakhir. Masuk melalui tab Akun untuk melanjutkan.',
                ),
                TextButton(
                  onPressed: () =>
                      Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('Kembali ke Akun'),
                ),
              ] else
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
    this.controller,
    this.validator,
  });

  final String label;
  final bool secret;
  final TextInputType? keyboardType;
  final bool enabled;
  final TextEditingController? controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      validator: validator,
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
