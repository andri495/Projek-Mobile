import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'providers/app_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/control_screen.dart';
import 'screens/automation_screen.dart';
import 'screens/history_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const SmartGreenApp(),
    ),
  );
}

class SmartGreenApp extends StatelessWidget {
  const SmartGreenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartGreen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF059669),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const AppRoot(),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final provider = context.read<AppProvider>();
    await provider.initialize();

    // Restore saved session
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getInt('userId');
    if (savedUserId != null) {
      await provider.login(savedUserId);
    }

    if (mounted) setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco_rounded, size: 48, color: Color(0xFF059669)),
              SizedBox(height: 16),
              Text(
                'SmartGreen',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF059669),
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                color: Color(0xFF059669),
                strokeWidth: 2.5,
              ),
            ],
          ),
        ),
      );
    }

    return const _AppShell();
  }
}

class _AppShell extends StatelessWidget {
  const _AppShell();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    // Not logged in → show login
    if (provider.currentUserId == null) {
      return _LoginWrapper(
        onLogin: (id) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', id);
          await provider.login(id);
        },
      );
    }

    // Logged in → show main app
    return _MainApp(
      onLogout: () async {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('userId');
        provider.logout();
      },
    );
  }
}

class _LoginWrapper extends StatelessWidget {
  final Future<void> Function(int) onLogin;

  const _LoginWrapper({required this.onLogin});

  @override
  Widget build(BuildContext context) {
    // Override provider.login to also persist
    return const LoginScreen();
  }
}

class _MainApp extends StatelessWidget {
  final VoidCallback onLogout;
  const _MainApp({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final currentTab = provider.currentTab;

    Widget body;
    switch (currentTab) {
      case 'beranda':
        body = const DashboardScreen();
        break;
      case 'kendali':
        body = const ControlScreen();
        break;
      case 'aturan':
        body = const AutomationScreen();
        break;
      case 'riwayat':
        body = const HistoryScreen();
        break;
      case 'profil':
        body = const ProfileScreen();
        break;
      default:
        body = const DashboardScreen();
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: BottomNav(
        currentTab: currentTab,
        onChange: (tab) => provider.setTab(tab),
      ),
    );
  }
}
