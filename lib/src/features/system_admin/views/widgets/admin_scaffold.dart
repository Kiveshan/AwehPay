import 'package:flutter/material.dart';

class AdminScaffold extends StatelessWidget {
  const AdminScaffold({
    required this.title,
    required this.child,
    this.showBackButton = false,
    super.key,
  });

  final String title;
  final Widget child;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.contain,
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF272A2F),
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 58,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEEAB8),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
