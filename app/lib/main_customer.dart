import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "core/routing/app_router.dart";
import "core/theme/app_theme.dart";

void main() {
  runApp(const ProviderScope(child: CustomerApp()));
}

class CustomerApp extends StatelessWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Ecommerce Platform",
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      routerConfig: customerRouter,
    );
  }
}
