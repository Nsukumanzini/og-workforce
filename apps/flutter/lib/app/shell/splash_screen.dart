import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.hub_outlined, size: 48), SizedBox(height: 16), Text('OG Workforce AI'), SizedBox(height: 20), CircularProgressIndicator(),
    ])),
  );
}
