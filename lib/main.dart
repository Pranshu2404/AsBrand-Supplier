import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/category_provider.dart';
import 'providers/brand_provider.dart';
import 'screens/supplier_login_screen.dart';
import 'screens/supplier_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
  ));

  runApp(const AsBrandSupplierApp());
}

class AsBrandSupplierApp extends StatelessWidget {
  const AsBrandSupplierApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => BrandProvider()),
      ],
      child: MaterialApp(
        title: 'AsBrand Supplier',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AppRoot(),
      ),
    );
  }
}

/// Root widget — checks auth state, routes to Login or Shell
class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await context.read<AuthProvider>().checkAuth();
    if (mounted) setState(() => _isCheckingAuth = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) return const _SplashScreen();

    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated || !auth.isSupplier) {
      return const SupplierLoginScreen();
    }

    // Authenticated supplier → main shell with bottom nav
    return const SupplierShell();
  }
}

/// Splash shown while verifying token
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.store_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            const Text(
              'AsBrand Supplier',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 50),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
                strokeWidth: 2.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
