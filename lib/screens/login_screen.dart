import 'package:flutter/material.dart';
import 'home_screen.dart';
import '../services/auth_service.dart';
import 'email_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _continueWithGoogle() async {
    setState(() => _isLoading = true);
    
    try {
      final userCredential = await AuthService.signInWithGoogle();
      
      if (!mounted) return;
      
      if (userCredential != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // User cancelled or sign-in failed
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in cancelled')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    await AuthService.loginAsGuest();
    
    if (!mounted) return;
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => _continueAsGuest(), // Skip to guest mode
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(flex: 1),
              
              // Logo News Now
              _buildLogo(),
              
              const SizedBox(height: 48),
              
              // Title
              const Text(
                'Sign Up for Free',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'Join 50M news readers gaining smarter insights.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Continue with Google
              _buildSocialButton(
                onPressed: _continueWithGoogle,
                icon: Icons.g_mobiledata,
                label: 'Continue with Google',
                backgroundColor: Colors.white,
                textColor: Colors.black,
                iconColor: Colors.red,
              ),
              
              const SizedBox(height: 16),
              
              // Continue with Email
              _buildSocialButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmailLoginScreen(),
                    ),
                  );
                },
                icon: Icons.email_outlined,
                label: 'Continue with Email',
                backgroundColor: const Color(0xFF2C2C2E),
                textColor: Colors.white,
                iconColor: Colors.white,
              ),
              
              const SizedBox(height: 16),
              
              // Continue as Guest
              _buildSocialButton(
                onPressed: _continueAsGuest,
                icon: Icons.person_outline,
                label: 'Continue as Guest',
                backgroundColor: const Color(0xFF2C2C2E),
                textColor: Colors.white,
                iconColor: Colors.white,
              ),
              
              const SizedBox(height: 32),
              
              // ...existing code...
              
              const Spacer(flex: 2),
              
              // ...existing code...
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return SizedBox(
      height: 120,
      child: Column(
        children: [
          // Orange arc
          SizedBox(
            width: 80,
            height: 50,
            child: CustomPaint(
              painter: _MiniLogoPainter(),
            ),
          ),
          const SizedBox(height: 8),
          // Text News Now dengan N capital
          RichText(
            text: const TextSpan(
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
              children: [
                TextSpan(
                  text: 'News ',
                  style: TextStyle(color: Colors.white),
                ),
                TextSpan(
                  text: 'Now',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color textColor,
    required Color iconColor,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Mini logo painter - simple arc
class _MiniLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final arcPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE84118), Color(0xFFFF6B35), Color(0xFFF7931E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromLTWH(
      size.width * 0.15,
      0,
      size.width * 0.7,
      size.height * 1.4,
    );
    
    canvas.drawArc(arcRect, 3.14, 3.14, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
