import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gaia_mobile/pages/account_page.dart';
import 'package:gaia_mobile/pages/user/account_forms.dart';
import 'package:gaia_mobile/pages/user/account_sections.dart';

Future<void> openAccount(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: AccountPage())),
  );
}

Future<void> tapText(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.scrollUntilVisible(
    target,
    160,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('account opens login, reset, registration and returns', (
    tester,
  ) async {
    await openAccount(tester);
    await tapText(tester, 'Masuk');
    expect(find.byType(LoginPage), findsOneWidget);
    final password = tester.widgetList<TextField>(find.byType(TextField)).last;
    expect(password.obscureText, isTrue);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tapText(tester, 'Lupa password?');
    expect(find.byType(ResetPasswordPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapText(tester, 'Belum punya akun? Daftar');
    expect(find.byType(RegisterPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AccountPage), findsOneWidget);
    await tapText(tester, 'Buat akun');
    expect(find.byType(RegisterPage), findsOneWidget);
  });

  testWidgets('profile and edit form fit a small phone with keyboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await openAccount(tester);
    await tapText(tester, 'Profil saya');
    expect(find.byType(ProfilePage), findsOneWidget);
    await tapText(tester, 'Edit profil');
    expect(find.byType(EditProfilePage), findsOneWidget);
    final name = find.widgetWithText(TextFormField, 'Nama lengkap');
    await tester.scrollUntilVisible(
      name,
      -160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(name, 'Nama pratinjau');
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Simpan perubahan'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });

  testWidgets('wishlist and security pages open without a fake session', (
    tester,
  ) async {
    await openAccount(tester);
    await tapText(tester, 'Wishlist');
    expect(find.byType(WishlistPage), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tapText(tester, 'Pengaturan akun');
    expect(find.byType(AccountSettingsPage), findsOneWidget);
    await tapText(tester, 'Ganti password');
    expect(find.byType(ChangePasswordPage), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
  });
}
