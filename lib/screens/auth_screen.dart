import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:habit_constellation/theme.dart';
import 'package:habit_constellation/providers/repository_provider.dart';
import 'package:habit_constellation/screens/main_navigation.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      await ref.read(repositoryProvider).signInWithGoogle('mock_token');
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    } catch (e) {
      setState(() { _error = 'Sign in failed. Please try again.'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: kBg,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Habit Constellation',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w100,
                      fontSize: 45,
                      letterSpacing: 0.0,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Every habit you practice becomes a star.',
                    textAlign: TextAlign.center,
                    style: kRaleway(size: 16.5, spacing: 0.04, color: const Color(0xFFF0F0F0))),
                  const SizedBox(height: 64),
                  if (_loading)
                    const CircularProgressIndicator(color: Color(0xFF7AB6E0))
                  else ...[
                    _GoogleSignInButton(onTap: _signIn),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: kInter(size: 12, color: const Color(0xFFE07070))),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatefulWidget {
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.onTap});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final button = Container(
      width: 150,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD6D6D6), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 24),
          const SizedBox(width: 6),
          Text(
            'Sign in',
            style: GoogleFonts.interTight(
              fontWeight: FontWeight.w200,
              fontSize: 16,
              color: Colors.white,
              letterSpacing: 0.0,
              height: 1,
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 120),
        opacity: _pressed ? 0.55 : 1.0,
        child: _pressed
            ? Shimmer.fromColors(
                baseColor: Colors.white.withValues(alpha: 0.15),
                highlightColor: Colors.white.withValues(alpha: 0.55),
                child: button,
              )
            : button,
      ),
    );
  }
}
