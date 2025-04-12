import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'package:in_app_review/in_app_review.dart';
import 'settings_provider.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Consumer<SettingsProvider>(
          builder: (context, settings, child) {
            return AlertDialog(
              title: const Text('Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    title: const Text('Music'),
                    value: settings.isMusicEnabled,
                    onChanged: (value) => settings.toggleMusic(value),
                  ),
                  SwitchListTile(
                    title: const Text('Sound Effects'),
                    value: settings.isSoundEnabled,
                    onChanged: (value) => settings.toggleSound(value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Fungsi untuk memanggil review prompt
  Future<void> _requestReview() async {
    final InAppReview inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      inAppReview.requestReview();
    } else {
      // Jika review tidak tersedia, Anda bisa mengarahkan ke Play Store/App Store
      // Contoh: inAppReview.openStoreListing(appStoreId: 'YOUR_APP_STORE_ID', microsoftStoreId: 'YOUR_MICROSOFT_STORE_ID');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/logo.png',
                  width: 200,
                ),
                const SizedBox(height: 50),
                _buildGameButton(
                  text: 'Play Game',
                  onPressed: () {
                    settings.playClickSound();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HomePage()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildGameButton(
                  text: 'Settings',
                  onPressed: () {
                    settings.playClickSound();
                    _showSettingsDialog(context);
                  },
                ),
                const SizedBox(height: 20),
                // Tombol Rate Game yang memicu In-App Review
                SizedBox(
                  width: 300,
                  height: 60,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C5D95),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: const BorderSide(
                          color: Color(0xFFAAB39D),
                          width: 2,
                        ),
                      ),
                    ),
                    onPressed: () {
                      settings.playClickSound();
                      _requestReview();
                    },
                    child: const Text(
                      'Rate Game',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 300,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4C5D95),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(
              color: Color(0xFFAAB39D),
              width: 2,
            ),
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
