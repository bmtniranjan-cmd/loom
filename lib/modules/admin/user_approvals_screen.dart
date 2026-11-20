import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:loom/models/user_model.dart'; // ඔබේ Model එක ඇති පාත් එක දෙන්න
import 'package:loom/widgets/custom_button.dart';

class UserApprovalsScreen extends StatefulWidget {
  const UserApprovalsScreen({super.key});

  @override
  State<UserApprovalsScreen> createState() => _UserApprovalsScreenState();
}

class _UserApprovalsScreenState extends State<UserApprovalsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<UserModel> pendingUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingUsers();
  }

  // 1. පෙන්ඩින් යූසර්වරුන් ලබා ගැනීම (Model හරහා)
  Future<void> _fetchPendingUsers() async {
    setState(() => isLoading = true);
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('status', 'pending');

      if (mounted) {
        setState(() {
          pendingUsers = (response as List)
              .map((userJson) => UserModel.fromJson(userJson))
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching pending users: $e");
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // 2. යූසර්ගේ ස්ටේටස් වෙනස් කිරීම (Approve / Reject)
  Future<void> _updateUserStatus(String userId, String status) async {
    try {
      await _supabase
          .from('profiles')
          .update({'status': status})
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${status == 'approved' ? 'approved' : 'rejected'} successfully!',
            ),
            backgroundColor: status == 'approved' ? Colors.green : Colors.red,
          ),
        );
        _fetchPendingUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 3. දුරකථන ඇමතුමක් ලබා ගැනීම
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    } catch (e) {
      debugPrint("Error launching call: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Pending User Approvals'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : pendingUsers.isEmpty
          ? const Center(
              child: Text(
                'No pending approvals found.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: pendingUsers.length,
              itemBuilder: (context, index) {
                final UserModel user = pendingUsers[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Phone: ${user.phone}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Email: ${user.email}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Role: ${user.role.toUpperCase()}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Address: ${user.address}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'City: ${user.city}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // බටන් තුනම එකම පේළියක
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: const BorderSide(color: Colors.blue),
                                    padding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed:
                                      (user.phone.isNotEmpty &&
                                          user.phone != 'N/A')
                                      ? () => _makePhoneCall(user.phone)
                                      : null,
                                  icon: const Icon(Icons.call, size: 14),
                                  label: const Text(
                                    'Call',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: CustomButton(
                                  text: 'Reject',
                                  color: Colors.red,
                                  onPressed: () =>
                                      _updateUserStatus(user.id, 'rejected'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: CustomButton(
                                  text: 'Approve',
                                  color: Colors.green,
                                  onPressed: () =>
                                      _updateUserStatus(user.id, 'approved'),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
