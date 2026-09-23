import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shimmer/shimmer.dart';
import 'package:habit_constellation/repositories/http_repository.dart';
import 'package:habit_constellation/theme.dart';
import 'package:habit_constellation/providers/repository_provider.dart';
import 'package:habit_constellation/screens/main_navigation.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  static const _serverClientId =
      '412897576300-bpnnr222i7rdhjqmt35a2926fg2ir3da.apps.googleusercontent.com';

  final _googleSignIn = GoogleSignIn(
    scopes: ['openid', 'email', 'profile'],
    serverClientId: _serverClientId,
  );

  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        if (mounted) setState(() { _loading = false; });
        return;
      }
      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null) {
        debugPrint('Google sign-in: idToken is null');
        setState(() { _error = 'Sign in failed. Please try again.'; _loading = false; });
        return;
      }
      await ref.read(repositoryProvider).signInWithGoogle(idToken);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigation()),
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('Sign-in failed: $e\n$stackTrace');
      if (!mounted) return;
      setState(() { _error = _errorMessage(e); _loading = false; });
    }
  }

  String _errorMessage(Object e) {
    if (e is ApiException) {
      switch (e.code) {
        case 'invalid_google_token':
          return 'Google sign-in verification failed. Please try again.';
        case 'account_exists':
          return 'An account with this email already exists.';
        default:
          return e.message;
      }
    }
    if (e is AuthException) return e.message;
    if (e is PlatformException) {
      return e.message ?? 'Google sign-in failed. Please try again.';
    }
    return 'Sign in failed. Please try again.';
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
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: Text(
                      'Habit Constellation',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontWeight: FontWeight.w100,
                        fontSize: 45,
                        letterSpacing: 0.0,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Every habit you practice\nbecomes a star',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontWeight: FontWeight.w300,
                      fontSize: 16.5,
                      letterSpacing: 0.04,
                      color: const Color(0xFFF0F0F0),
                    )),
                  const SizedBox(height: 64),
                  if (_loading)
                    const CircularProgressIndicator(color: Color(0xFF7AB6E0))
                  else ...[
                    _GoogleSignInButton(onTap: _signIn),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(_error!, style: kInter(size: 12, color: const Color(0xFFB77DE3))),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _signIn,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text('Retry', style: kInter(size: 13, color: kBlueGlow)),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 80),
                  Image.asset('public/logo_2.png', width: 200, height: 200),
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: 9,
            child: FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 25),
          ),
          Align(
            alignment: Alignment(0.04, 0),
            child: Text(
              'Sign in',
              style: GoogleFonts.interTight(
                fontWeight: FontWeight.w200,
                fontSize: 19,
                color: Colors.white,
                letterSpacing: 0.0,
                height: 1,
              ),
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
