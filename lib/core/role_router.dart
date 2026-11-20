import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../modules/auth/login_screen.dart';
import '../modules/auth/pending_approval_screen.dart';

import '../modules/admin/admin_dashboard.dart';
import '../modules/farmer/farmer_dashboard.dart';
import '../modules/customer/customer_dashboard.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  Future _getUserProfile(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    // 1. කෙනෙක් ලොග් වෙලා නැත්නම් Login Screen එකට යවයි
    if (session == null) {
      return const LoginScreen();
    }

    // 2. ඩේටාබේස් එකෙන් profiles ටේබල් එක චෙක් කිරීම
    return FutureBuilder(
      future: _getUserProfile(session.user.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final profile = snapshot.data;

        // ප්‍රොෆයිල් එකක් නැත්නම් හෝ ස්ටේටස් එක 'pending' නම් Pending Screen එකට යැවීම
        if (profile == null || profile['status'] == 'pending') {
          return const PendingApprovalScreen();
        }

        final role = profile['role']?.toString().toLowerCase() ?? 'customer';

        // 3. Role එක අනුව අදාළ Dashboard එකට යැවීම
        switch (role) {
          case 'admin':
            return const AdminDashboard();
          case 'farmer':
            return const FarmerDashboard();
          case 'customer':
            return const CustomerDashboard();
          default:
            return const CustomerDashboard();
        }
      },
    );
  }
}
