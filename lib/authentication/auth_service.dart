import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Current logged in user
  User? get currentUser => _auth.currentUser;

  /// Authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// --------------------------------------------------------
  /// Register User
  /// --------------------------------------------------------
  Future<UserCredential> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      print("Step 1: Creating Firebase user...");

      UserCredential credential =
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print("Step 2: User created");

      User? user = credential.user;

      if (user != null) {
        print("Step 3: Updating display name");

        await user.updateDisplayName(name);

        print("Step 4: Saving Firestore");

        await _firestore.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "name": name,
          "email": email.trim(),
          "createdAt": FieldValue.serverTimestamp(),
          "lastLogin": FieldValue.serverTimestamp(),
          "emailVerified": false,
          "totalGenerated": 0,
          "totalScanned": 0,
        });

        print("Step 5: Sending verification email");

        await user.sendEmailVerification();

        print("Step 6: Verification email sent");
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      print("Firebase Error: ${e.code}");
      print("Firebase Message: ${e.message}");
      rethrow;
    } catch (e) {
      print("Unknown Error: $e");
      rethrow;
    }
  }

  /// --------------------------------------------------------
  /// Login
  /// --------------------------------------------------------
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential =
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = credential.user;

      if (user != null) {
        await _firestore.collection("users").doc(user.uid).update({
          "lastLogin": FieldValue.serverTimestamp(),
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseError(e));
    }
  }

  /// --------------------------------------------------------
  /// Send Verification Email
  /// --------------------------------------------------------
  Future<void> sendVerificationEmail() async {
    User? user = _auth.currentUser;

    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// --------------------------------------------------------
  /// Reload User
  /// --------------------------------------------------------
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// --------------------------------------------------------
  /// Email Verified?
  /// --------------------------------------------------------
  bool get isEmailVerified {
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// --------------------------------------------------------
  /// Forgot Password
  /// --------------------------------------------------------
  Future<void> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseError(e));
    }
  }

  /// --------------------------------------------------------
  /// Logout
  /// --------------------------------------------------------
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// --------------------------------------------------------
  /// Delete Account
  /// --------------------------------------------------------
  Future<void> deleteAccount() async {
    User? user = _auth.currentUser;

    if (user == null) return;

    await _firestore.collection("users").doc(user.uid).delete();

    await user.delete();
  }

  /// --------------------------------------------------------
  /// Refresh Firestore Email Verification Status
  /// --------------------------------------------------------
  Future<void> updateVerificationStatus() async {
    User? user = _auth.currentUser;

    if (user == null) return;

    await user.reload();

    if (user.emailVerified) {
      await _firestore.collection("users").doc(user.uid).update({
        "emailVerified": true,
      });
    }
  }

  /// --------------------------------------------------------
  /// Firebase Error Messages
  /// --------------------------------------------------------
  String _getFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';

      case 'invalid-email':
        return 'Invalid email address.';

      case 'weak-password':
        return 'Password should be at least 6 characters.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
        return 'Incorrect password.';

      case 'invalid-credential':
        return 'Invalid email or password.';

      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';

      case 'network-request-failed':
        return 'Check your internet connection.';

      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}