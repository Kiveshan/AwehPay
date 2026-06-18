import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  // Initializes animations and starts auto-navigation to sign-in screen
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Fade away animation during the last 0.5 seconds (from 66.7% to 100%)
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.667, 1.0, curve: Curves.easeInOut),
      ),
    );

    // Navigate to sign in screen after 5 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _animationController.forward().then((_) {
          if (mounted) {
            context.go(AppRoutes.adminSignIn);
          }
        });
      }
    });
  }

  // Cleans up animation controller to prevent memory leaks
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Builds the launch screen with animated logo and loading indicator
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: Listenable.merge([_scaleAnimation, _opacityAnimation]),
            builder: (context, child) {
              return Opacity(
                opacity: _opacityAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                ),
              );
            },
            child: SizedBox(
              width: double.infinity,
              height: double.infinity,
              child: Image.asset(
                'assets/images/LaunchScreen.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
