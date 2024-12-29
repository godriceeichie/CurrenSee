class UserModel {
  final String uid;
  final String email;
  final String name;
  final String defaultCurrency;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.defaultCurrency,
  });

  // Factory method for converting Firestore data to UserModel
  factory UserModel.fromMap(String uid, Map<String, dynamic> data) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      defaultCurrency: data['defaultCurrency'] ?? 'USD',
    );
  }
}
