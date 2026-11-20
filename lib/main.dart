import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/role_router.dart';
import 'core/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ouqwblxtzofevrlspkfs.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im91cXdibHh0em9mZXZybHNwa2ZzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTQ0NDI0MzcsImV4cCI6MjExMDAxODQzN30.vNtIA3wfnMSq9PuyZCZC0TmCaG3EvkJXAm2YiJTpqEY',
  );

  runApp(const LoomApp());
}

class LoomApp extends StatelessWidget {
  const LoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loom',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RoleRouter(),
    );
  }
}
