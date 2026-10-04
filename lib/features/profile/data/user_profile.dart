class UserProfile {
  const UserProfile({
    required this.name,
    required this.email,
    this.photoUrl,
    this.photoStoragePath,
  });

  final String name;
  final String email;
  final String? photoUrl;
  final String? photoStoragePath;
}
