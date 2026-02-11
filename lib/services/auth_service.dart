import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/profile.dart';

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  User? get currentUser => _client.auth.currentUser;
  String? get userId => currentUser?.id;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );
    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<AuthResponse> signInWithGoogle() async {
    const webClientId =
        ''; // TODO: Add your Google Web Client ID
    const iosClientId =
        ''; // TODO: Add your Google iOS Client ID

    final googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('No ID token found');
    }

    final response = await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Profile?> getProfile() async {
    final uid = userId;
    if (uid == null) return null;

    try {
      final data =
          await _client.from('profiles').select().eq('id', uid).single();
      return Profile.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  Future<void> updateProfile({required String fullName}) async {
    final uid = userId;
    if (uid == null) return;

    await _client.from('profiles').update({
      'full_name': fullName,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', uid);
  }

  Future<int?> claimFoundingSpot() async {
    try {
      final result = await _client.rpc('claim_founding_spot');
      return result as int?;
    } catch (e) {
      debugPrint('Error claiming founding spot: $e');
      return null;
    }
  }
}
