import 'package:currensee/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_service.dart'; // Import your Firebase service

class UserNotifier extends StateNotifier<UserModel?> {
  final FirebaseService _firebaseService;

  UserNotifier(this._firebaseService) : super(null);

  // Fetch user data from Firestore after login
  Future<void> loadUser(String uid) async {
    try {
      final userData = await _firebaseService.fetchUserData(uid);
      state = UserModel.fromMap(uid, userData);
    } catch (e) {
      throw Exception("Error loading user data: $e");
    }
  }

  // Clear user data on logout
  void clearUser() {
    state = null;
  }
}

// Riverpod provider for user state
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>(
      (ref) => UserNotifier(FirebaseService()),
);
