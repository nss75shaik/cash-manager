import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  // Stream of auth state changes
  Stream<User?> get authStateChanges {
    final auth = _auth;
    if (auth == null) return Stream.value(null);
    return auth.authStateChanges();
  }

  // Current logged in user
  User? get currentUser => _auth?.currentUser;

  // Sign up with Email and Password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is not initialized. Please configure Firebase.');
    }
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (displayName != null && displayName.trim().isNotEmpty) {
        await credential.user?.updateDisplayName(displayName.trim());
        await credential.user?.reload();
      }

      return credential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Sign in with Email and Password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is not initialized. Please configure Firebase.');
    }
    try {
      return await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Sign in Anonymously / Guest Mode (100% Free, No Billing Required)
  Future<UserCredential> signInAnonymously() async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is not initialized. Please configure Firebase.');
    }
    try {
      return await auth.signInAnonymously();
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth?.signOut();
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is not initialized. Please configure Firebase.');
    }
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // -------------------------------------------------------------
  // Phone OTP Authentication
  // -------------------------------------------------------------
  Future<void> sendPhoneOtp({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException exception) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    Duration timeout = const Duration(seconds: 60),
    int? forceResendingToken,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is not initialized. Please configure Firebase.');
    }

    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      timeout: timeout,
      forceResendingToken: forceResendingToken,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase is not initialized. Please configure Firebase.');
    }

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      return await auth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  // Friendly error message converter
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email. Please register first.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Invalid email, phone number, or password. Please try again.';
        case 'email-already-in-use':
          return 'An account already exists with this email address.';
        case 'invalid-email':
          return 'The email address is formatted incorrectly.';
        case 'weak-password':
          return 'Password is too weak. Please use at least 6 characters.';
        case 'user-disabled':
          return 'This user account has been disabled.';
        case 'invalid-phone-number':
          return 'The phone number entered is invalid. Include country code (e.g., +91).';
        case 'invalid-verification-code':
          return 'The OTP entered is incorrect. Please check and try again.';
        case 'invalid-verification-id':
          return 'Verification session has expired. Please request a new OTP.';
        case 'session-expired':
          return 'The OTP code has expired. Please request a new code.';
        case 'quota-exceeded':
          return 'SMS quota exceeded. Please use a Test Phone Number in Firebase Console or upgrade Firebase plan.';
        case 'billing-not-enabled':
          return 'Billing is not enabled in Firebase. Please add a Test Phone Number in Firebase Console or upgrade to Blaze plan.';
        case 'too-many-requests':
          return 'Too many attempts. Please wait a moment and try again.';
        case 'network-request-failed':
          return 'Network error. Please check your internet connection.';
        case 'operation-not-allowed':
          return 'Phone sign-in is not enabled in Firebase Console.';
        default:
          final msg = error.message ?? '';
          if (msg.toLowerCase().contains('billing')) {
            return 'Billing not enabled: Please add a Test Phone Number in Firebase Console or upgrade to Firebase Blaze plan.';
          }
          return msg.isNotEmpty ? msg : 'An unexpected authentication error occurred.';
      }
    }
    final errStr = error?.toString() ?? '';
    if (errStr.toLowerCase().contains('billing')) {
      return 'Billing not enabled: Please add a Test Phone Number in Firebase Console or upgrade to Firebase Blaze plan.';
    }
    return errStr.isNotEmpty ? errStr : 'An unknown error occurred.';
  }
}
