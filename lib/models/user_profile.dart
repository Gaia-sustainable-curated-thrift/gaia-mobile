class UserProfile {
  const UserProfile(this.data);
  final Map<String, dynamic> data;
  String text(String field) => data[field]?.toString() ?? '';
  bool get emailVerified => data['email_verified'] == true;
  bool get hasPassword => data['has_password'] == true;
  String get displayName =>
      text('full_name').isEmpty ? text('username') : text('full_name');
}
