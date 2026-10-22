import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependencies.dart';
import 'core/network/api_config.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/primary_button.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShopLauncher());
}

class ShopLauncher extends StatefulWidget {
  const ShopLauncher({super.key});

  @override
  State<ShopLauncher> createState() => _ShopLauncherState();
}

class _ShopLauncherState extends State<ShopLauncher> {
  late Future<AppDependencies> _loading = AppDependencies.connect();

  void _retry() {
    setState(() => _loading = AppDependencies.connect());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppDependencies>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ShoeFactoryApp(
              dependencies: snapshot.data!, showSplash: false);
        }
        if (snapshot.hasError) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: Scaffold(
              body: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Shoe Factory API is not reachable.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 12),
                      Text(
                        'Start the API, then retry.\n${defaultApiBaseUrl()}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      PrimaryButton(label: 'Retry', onPressed: _retry),
                      TextButton(
                        onPressed: () {
                          runApp(ShoeFactoryApp(
                              dependencies: AppDependencies.create(),
                              showSplash: false));
                        },
                        child: const Text('Continue offline'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: const SplashView(),
        );
      },
    );
  }
}
