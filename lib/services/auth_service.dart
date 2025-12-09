import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  static const String _isGuestKey = 'is_guest';

  static Future<bool> isLoggedIn() async {
    // Check if user is signed in with Firebase or as guest
    final user = _auth.currentUser;
    if (user != null) return true;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isGuestKey) ?? false;
  }

  // Login with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  // Login with Email & Password
  static Future<UserCredential?> login(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error signing in: $e');
      return null;
    }
  }

  // Register with Email & Password
  static Future<UserCredential?> register(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Error registering: $e');
      return null;
    }
  }

  // Login as Guest (still using SharedPreferences for guest mode)
  static Future<void> loginAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, true);
  }

  // Logout
  static Future<void> logout() async {
    try {
      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.disconnect();
        await _googleSignIn.signOut();
      }
      
      // Sign out from Firebase
      await _auth.signOut();
      
      // Only clear guest flag; keep user-specific stored data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isGuestKey);
    } catch (e) {
      print('Error during logout: $e');
      // Still try to clear prefs even if sign out fails
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isGuestKey);
    }
  }

  // Get current user name
  static Future<String> getUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      return user.displayName ?? user.email?.split('@')[0] ?? 'User';
    }
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isGuestKey) == true ? 'Guest' : 'User';
  }

  // Get current user email
  static Future<String?> getUserEmail() async {
    final user = _auth.currentUser;
    return user?.email;
  }

  // Check if logged in as guest
  static Future<bool> isGuest() async {
    final user = _auth.currentUser;
    if (user != null) return false;
    
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isGuestKey) ?? false;
  }

  // Get current Firebase user
  static User? getCurrentUser() {
    return _auth.currentUser;
  }
}
