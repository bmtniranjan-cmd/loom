import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/database_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/custom_text_field.dart';
import 'pending_approval_screen.dart';
import '../../models/user_model.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final DatabaseService _dbService = DatabaseService();

  String _selectedRole = 'customer';
  final List<String> _roles = ['customer', 'farmer'];

  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Supabase Auth හරහා Sign Up කිරීම
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        data: {
          'full_name': _nameController.text.trim(),
          'role': _selectedRole,
          'status': 'pending',
        },
      );

      final user = response.user;

      if (user != null) {
        // UserModel එක භාවිතයෙන් ඩේටා සැකසීම
        final newUser = UserModel(
          id: user.id,
          fullName: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          role: _selectedRole,
          status: 'pending',
          address: _addressController.text.trim(),
          city: _cityController.text.trim(),
        );

        // DatabaseService හරහා profiles ටේබල් එකට යැවීම
        await _dbService.insertData('profiles', newUser.toJson());

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PendingApprovalScreen(),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Create an Account',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Join Loom to manage your farm-to-table orders',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Role Selection Dropdown
                CustomDropdown<String>(
                  labelText: 'Select Role',
                  value: _selectedRole,
                  items: _roles,
                  itemLabelBuilder: (role) => role.toUpperCase(),
                  prefixIcon: Icons.badge_outlined,
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                ),

                // Full Name
                CustomTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter your name'
                      : null,
                ),

                // Phone Number
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: '07XXXXXXXX',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Enter a valid 10-digit phone number';
                    }
                    return null;
                  },
                ),

                // Address
                CustomTextField(
                  controller: _addressController,
                  label: 'Address',
                  hint: 'Enter your street address',
                  icon: Icons.home_outlined,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter your address'
                      : null,
                ),

                // City
                CustomTextField(
                  controller: _cityController,
                  label: 'City',
                  hint: 'Enter your city (e.g. Gampola, Kandy)',
                  icon: Icons.location_city_outlined,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please enter your city'
                      : null,
                ),

                // Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),

                // Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  bottomSpace: 24,
                  validator: (value) => (value == null || value.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                ),

                // Register Button
                CustomButton(
                  text: 'Register',
                  isLoading: _isLoading,
                  onPressed: _register,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
