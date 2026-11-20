import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/role_router.dart';
import '../modules/auth/login_screen.dart';

class AuthService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // Get Current User ID
  static String? get userId => _supabase.auth.currentUser?.id;

  // Login Logic
  static Future<void> login({
    required BuildContext context,
    required String email,
    required String password,
    required Function(bool) setLoading,
  }) async {
    if (email.isEmpty || password.isEmpty) {
      _showSnackBar(
        context,
        'Please enter both email and password',
        isError: true,
      );
      return;
    }

    setLoading(true);

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null && context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const RoleRouter()),
        );
      }
    } on AuthException catch (e) {
      if (context.mounted) {
        _showSnackBar(context, e.message, isError: true);
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'An unexpected error occurred', isError: true);
      }
    } finally {
      setLoading(false);
    }
  }

  // Logout Logic
  static Future<void> logout(BuildContext context) async {
    try {
      await _supabase.auth.signOut();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Logout Error: ${e.toString()}', isError: true);
      }
    }
  }

  // Helper function for showing SnackBar
  static void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}
