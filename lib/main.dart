import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:PicturiWord/ad_provider.dart';
import 'package:PicturiWord/coin_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_screen.dart';
import 'settings_provider.dart';
import 'package:audio_session/audio_session.dart'; // Tambahkan package ini
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://mudecnmfofdtjszomrfw.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im11ZGVjbm1mb2ZkdGpzem9tcmZ3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM1ODMwMTgsImV4cCI6MjA1OTE1OTAxOH0.3DVq_QJACt-7wBK1TZE69o8ycbPAT8xVxWj5KMLrAXk',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => CoinProvider()),
        ChangeNotifierProvider(create: (_) => AdProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Panggil inisialisasi musik jika diperlukan
    final settings = context.read<SettingsProvider>();
    settings.initializeMusic();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final settings = context.read<SettingsProvider>();
    if (state == AppLifecycleState.paused) {
      // Hentikan atau pause musik saat aplikasi masuk ke background
      settings.toggleMusic(false);
    } else if (state == AppLifecycleState.resumed) {
      // Melanjutkan musik saat kembali ke foreground
      settings.toggleMusic(true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supabase Flutter App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
    );
  }
}
