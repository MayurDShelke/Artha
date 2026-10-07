import 'dart:async';
import 'package:flutter/material.dart';
import '../state/auth_scope.dart';
import 'auth_screen.dart';
import 'main_scaffold.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  Timer? _timer;
  bool _minTimeElapsed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    );

    _scaleAnimation = Tween<double>(begin: 0.90, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    // Minimum splash screen display time for a smooth, premium brand introduction
    _timer = Timer(const Duration(milliseconds: 2100), () {
      if (mounted) {
        _minTimeElapsed = true;
        _checkAndNavigate();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndNavigate();
  }

  void _checkAndNavigate() {
    if (!mounted || _navigated || !_minTimeElapsed) return;

    final auth = AuthScope.of(context);
    if (!auth.isInitialized) return;

    _navigated = true;

    final Widget targetScreen = (auth.isAuthenticated || auth.isGuestMode)
        ? const MainScaffold()
        : AuthScreen(authState: auth);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, __) => targetScreen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141414), // Matches the exact dark shade of the artha brand logo
      body: Stack(
        children: [
          // Ambient soft glow in the center
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withAlpha(12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Animated Brand Logo + Subtitle
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 230,
                      child: Image.asset(
                        'asset/images/image.png',
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return Image.asset(
                            'android/app/asset/images/image.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) {
                              return const Text(
                                'artha',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -1.5,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'for Imrealty',
                      style: TextStyle(
                        color: Colors.white.withAlpha(150),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Tagline & Minimal Progress Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 48,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sleek minimal loader
                  SizedBox(
                    width: 36,
                    height: 2,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: const LinearProgressIndicator(
                        backgroundColor: Color(0xFF282828),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'PERSONAL EXPENSE JOURNAL',
                    style: TextStyle(
                      color: Colors.white.withAlpha(90),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
