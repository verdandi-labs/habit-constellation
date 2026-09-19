import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _GoogleLogo(),
            const SizedBox(width: 12),
            Text('Sign in with Google',
              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500,
                fontSize: 14, color: const Color(0xFF18182E), letterSpacing: 0.01)),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18, height: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 18;
    void draw(Color c, Path p) => canvas.drawPath(p, Paint()..color = c..style = PaintingStyle.fill);
    draw(const Color(0xFF4285F4), Path()..moveTo(16.51*s,8*s)..lineTo(8.98*s,8*s)..lineTo(8.98*s,11*s)..lineTo(13.28*s,11*s)..cubicTo(13.1*s,12*s,12.54*s,12.48*s,11.68*s,13.04*s)..lineTo(11.68*s,15.05*s)..lineTo(14.28*s,15.05*s)..cubicTo(15.86*s,13.67*s,16.66*s,11.6*s,16.66*s,9.17*s)..cubicTo(16.66*s,8.6*s,16.61*s,8.51*s,16.51*s,8*s)..close());
    draw(const Color(0xFF34A853), Path()..moveTo(8.98*s,17*s)..cubicTo(11.14*s,17*s,12.95*s,16.28*s,14.28*s,15.06*s)..lineTo(11.68*s,13.04*s)..cubicTo(10.72*s,13.68*s,9.44*s,14*s,8.98*s,14*s)..cubicTo(6.82*s,14*s,4.99*s,12.6*s,4.5*s,10.52*s)..lineTo(1.83*s,10.52*s)..lineTo(1.83*s,12.59*s)..cubicTo(2.88*s,15.26*s,5.73*s,17*s,8.98*s,17*s)..close());
    draw(const Color(0xFFFBBC05), Path()..moveTo(4.5*s,10.52*s)..cubicTo(4.26*s,9.84*s,4.14*s,9.12*s,4.14*s,8.38*s)..cubicTo(4.14*s,7.64*s,4.26*s,6.92*s,4.5*s,6.24*s)..lineTo(4.5*s,5.41*s)..lineTo(1.83*s,5.41*s)..cubicTo(1.06*s,6.94*s,0.62*s,8.62*s,0.62*s,10.38*s)..cubicTo(0.62*s,12.14*s,1.06*s,13.82*s,1.83*s,15.35*s)..lineTo(4.5*s,13.28*s)..close()..moveTo(4.5*s,10.52*s));
    draw(const Color(0xFFEA4335), Path()..moveTo(8.98*s,4.18*s)..cubicTo(10.15*s,4.18*s,11.21*s,4.58*s,12.04*s,5.38*s)..lineTo(14.34*s,3.08*s)..cubicTo(12.91*s,1.74*s,11.1*s,0.96*s,8.98*s,0.96*s)..cubicTo(5.73*s,0.96*s,2.88*s,2.7*s,1.83*s,5.41*s)..lineTo(4.5*s,7.48*s)..cubicTo(4.99*s,5.4*s,6.82*s,4.18*s,8.98*s,4.18*s)..close());
  }
  @override bool shouldRepaint(_) => false;
}
