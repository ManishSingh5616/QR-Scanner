import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:email_otp/email_otp.dart';

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
  /// 1. Send OTP to Email (Used for Profile Change Password & Sign Up)
  /// --------------------------------------------------------
  Future<bool> sendOtp({required String email}) async {
    try {
      bool result = await EmailOTP.sendOTP(email: email.trim());
      return result;
    } catch (e) {
      throw Exception("Failed to send OTP: $e");
    }
  }

  /// --------------------------------------------------------
  /// 2. Verify OTP Locally
  /// --------------------------------------------------------
  bool verifyOtp({required String otp}) {
    return EmailOTP.verifyOTP(otp: otp.trim());
  }

  /// --------------------------------------------------------
  /// 3. Send Firebase Password Reset Email (Used for Logged-out Forgot Password)
  /// --------------------------------------------------------
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseError(e));
    } catch (e) {
      throw Exception("Failed to send reset email: $e");
    }
  }

  /// --------------------------------------------------------
  /// 4. Complete Registration (Called AFTER OTP is successfully verified)
  /// --------------------------------------------------------
  Future<UserCredential> completeRegistrationAfterOtp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      User? user = credential.user;

      if (user != null) {
        await user.updateDisplayName(name);

        await _firestore.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "name": name,
          "email": email.trim(),
          "createdAt": FieldValue.serverTimestamp(),
          "lastLogin": FieldValue.serverTimestamp(),
          "emailVerified": true,
          "totalGenerated": 0,
          "totalScanned": 0,
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseError(e));
    } catch (e) {
      throw Exception("Unknown Error: $e");
    }
  }

  /// --------------------------------------------------------
  /// 5. Standard Email/Password Login (No OTP)
  /// --------------------------------------------------------
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
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
  /// 6. Re-authenticate User (Required for sensitive changes if needed)
  /// --------------------------------------------------------
  Future<void> reauthenticate(String currentPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null && user.email != null) {
        AuthCredential credential = EmailAuthProvider.credential(
          email: user.email!,
          password: currentPassword,
        );
        await user.reauthenticateWithCredential(credential);
      } else {
        throw Exception("No authenticated user found.");
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseError(e));
    } catch (e) {
      throw Exception("Re-authentication failed: $e");
    }
  }

  /// --------------------------------------------------------
  /// 7. Update Password (When Logged In via Profile)
  /// --------------------------------------------------------
  Future<void> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception("No authenticated user found.");
      }
    } on FirebaseAuthException catch (e) {
      throw Exception(_getFirebaseError(e));
    } catch (e) {
      throw Exception("Failed to update password: $e");
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
      case 'requires-recent-login':
        return 'Please re-login before performing this action.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Check your internet connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}