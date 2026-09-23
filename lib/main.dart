import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_constellation/screens/auth_screen.dart';
import 'package:habit_constellation/screens/main_navigation.dart';
import 'package:habit_constellation/providers/repository_provider.dart';
import 'package:habit_constellation/services/toast_service.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Constellation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF07091C),
      ),
      scaffoldMessengerKey: scaffoldMessengerKey,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  late final Future<bool> _silentSignIn;

  @override
  void initState() {
    super.initState();
    _silentSignIn = ref.read(repositoryProvider).silentSignIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _silentSignIn,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF7AB6E0))),
          );
        }
        if (snapshot.data == true) {
          return const MainNavigation();
        }
        return const AuthScreen();
      },
    );
  }
}
