import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/app_router.dart';
import 'theme/workforce_theme.dart';

class WorkforceApp extends ConsumerWidget {
  const WorkforceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'OG Workforce AI',
      theme: WorkforceTheme.light(), darkTheme: WorkforceTheme.dark(), routerConfig: router,
    );
  }
}
