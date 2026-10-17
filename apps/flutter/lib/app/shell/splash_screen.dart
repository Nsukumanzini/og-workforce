import 'package:flutter/material.dart';

import '../theme/workforce_theme.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(color: WorkforceTheme.forest, borderRadius: BorderRadius.circular(22)),
        child: const Icon(Icons.hub_rounded, color: Colors.white, size: 33),
      ),
      const SizedBox(height: 17),
      Text('OG Workforce', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 27),
      const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5)),
    ])),
  );
}
