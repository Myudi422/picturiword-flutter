import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'settings_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'coin_provider.dart';
import 'ad_provider.dart';
import 'package:auto_size_text/auto_size_text.dart';

class Puzzle {
  final int id;
  final String answer;
  final List<String> images;
  final int showCharacter;

  Puzzle({
    required this.id,
    required this.answer,
    required this.images,
    required this.showCharacter,
  });
}

class PlayPage extends StatefulWidget {
  final int initialPuzzleIndex;
  final List<Map<String, dynamic>> puzzles;

  const PlayPage({
    Key? key,
    required this.initialPuzzleIndex,
    required this.puzzles,
  }) : super(key: key);

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  static const double _buttonSize = 56.0;
  static const double _buttonFontSize = 24.0;

  late List<Puzzle> puzzles;
  late int currentPuzzleIndex;
  List<String> shuffledLetters = [];
  Set<int> solvedLevels = {};
  List<String> typedLetters = [];
  List<bool> usedLetter = [];
  late List<bool> revealedIndices;
  final Random _random = Random();
  Set<int> unlockedLevels = {};

  @override
  void initState() {
    super.initState();
    puzzles = widget.puzzles.map((map) {
      return Puzzle(
        id: map['level'],
        answer: map['answer'],
        images: [
          map['image_url_1'],
          map['image_url_2'],
          map['image_url_3'],
          map['image_url_4'],
        ],
        showCharacter: map['show_karakter'] ?? 0,
      );
    }).toList();
    currentPuzzleIndex = widget.initialPuzzleIndex;
    _initUnlockedLevels();
    _initSolvedLevels(); // Inisialisasi solvedLevels
    _initPuzzle(currentPuzzleIndex);
    // Load rewarded ad saat inisialisasi
    Provider.of<AdProvider>(context, listen: false).loadRewardedAd();
  }

  Future<void> _saveSolvedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final solvedList = solvedLevels.map((e) => e.toString()).toList();
    await prefs.setStringList('solvedLevels', solvedList);
  }

  Future<void> _initSolvedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final solvedList = prefs.getStringList('solvedLevels') ?? [];
    setState(() {
      solvedLevels = solvedList.map((e) => int.tryParse(e) ?? 0).toSet();
    });
  }

  Future<void> _initUnlockedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedList = prefs.getStringList('unlockedLevels') ?? ['1'];
    setState(() {
      unlockedLevels = unlockedList.map((e) => int.tryParse(e) ?? 1).toSet();
    });
  }

  Future<void> _saveUnlockedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedList = unlockedLevels.map((e) => e.toString()).toList();
    await prefs.setStringList('unlockedLevels', unlockedList);
  }

  void _initPuzzle(int index) {
    final puzzle = puzzles[index];
    final answer = puzzle.answer.toUpperCase().split('');

    revealedIndices = List.filled(answer.length, false);

    if (puzzle.showCharacter > 0 && puzzle.showCharacter <= answer.length) {
      int start = ((answer.length - puzzle.showCharacter) / 2).floor();
      for (int i = start; i < start + puzzle.showCharacter; i++) {
        revealedIndices[i] = true;
      }
    }

    typedLetters = List.generate(answer.length, (i) {
      return revealedIndices[i] ? answer[i] : '';
    });

    shuffledLetters = _generateShuffledLetters(answer);
    usedLetter = List.filled(shuffledLetters.length, false);
  }

  List<String> _generateShuffledLetters(List<String> answer) {
    const totalLetters = 12;
    const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

    List<String> hiddenChars = [];
    for (int i = 0; i < answer.length; i++) {
      if (!revealedIndices[i]) {
        hiddenChars.add(answer[i]);
      }
    }

    while (hiddenChars.length < totalLetters) {
      hiddenChars.add(alphabet[_random.nextInt(alphabet.length)]);
    }

    hiddenChars.shuffle(_random);
    return hiddenChars;
  }

  void _onLetterTap(int index) {
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    try {
      if (settings.isSoundEnabled) {
        settings.playKeyboardSound();
      }
    } catch (e) {
      debugPrint("Error playing keyboard sound: $e");
    }

    for (int i = 0; i < typedLetters.length; i++) {
      if (!revealedIndices[i] && typedLetters[i].isEmpty) {
        setState(() {
          typedLetters[i] = shuffledLetters[index];
          usedLetter[index] = true;
        });
        break;
      }
    }

    // Jika semua kotak sudah terisi, cek jawaban
    if (!typedLetters.any((letter) => letter.isEmpty)) {
      _checkAnswer();
    }
  }

  void _undoLetter() {
    for (int i = typedLetters.length - 1; i >= 0; i--) {
      if (!revealedIndices[i] && typedLetters[i].isNotEmpty) {
        final letter = typedLetters[i];
        for (int j = 0; j < shuffledLetters.length; j++) {
          if (shuffledLetters[j] == letter && usedLetter[j]) {
            setState(() {
              typedLetters[i] = '';
              usedLetter[j] = false;
            });
            break;
          }
        }
        break;
      }
    }
  }

  void _checkAnswer() async {
    final puzzle = puzzles[currentPuzzleIndex];
    final userAnswer = typedLetters.join('');
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final coinProvider = Provider.of<CoinProvider>(context, listen: false);

    if (userAnswer == puzzle.answer.toUpperCase()) {
      try {
        if (settings.isSoundEnabled) {
          await settings.playBenarSound();
        }
      } catch (e) {
        debugPrint("Error playing benar sound: $e");
      }

      if (!solvedLevels.contains(puzzle.id)) {
        coinProvider.addCoins(2);
        solvedLevels.add(puzzle.id);
        await _saveSolvedLevels();
      }

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Success'),
          content: const Text('Your answer is correct!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      final nextLevelId = puzzle.id + 1;
      if (!unlockedLevels.contains(nextLevelId)) {
        unlockedLevels.add(nextLevelId);
        await _saveUnlockedLevels();
      }

      if (currentPuzzleIndex < puzzles.length - 1) {
        setState(() {
          currentPuzzleIndex++;
          _initPuzzle(currentPuzzleIndex);
        });
      } else {
        // Jika level terakhir pada halaman selesai (misalnya level 12)
        // kembalikan ke homepage agar dapat menampilkan page selanjutnya
        Navigator.pop(context, currentPuzzleIndex);
      }
    } else {
      try {
        if (settings.isSoundEnabled) {
          await settings.playSalahSound();
        }
      } catch (e) {
        debugPrint("Error playing salah sound: $e");
      }
      _showResultSnackbar('Wrong! Try again', Colors.red);
    }
  }

  void _showResultSnackbar(String message, Color color, {bool isLast = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: isLast ? 3 : 2),
      ),
    );
  }

  void _goToPreviousLevel() {
    if (currentPuzzleIndex > 0) {
      setState(() {
        currentPuzzleIndex--;
        _initPuzzle(currentPuzzleIndex);
      });
    }
  }

  void _goToNextLevel() {
    if (currentPuzzleIndex < puzzles.length - 1) {
      final nextPuzzleId = puzzles[currentPuzzleIndex + 1].id;
      if (unlockedLevels.contains(nextPuzzleId)) {
        setState(() {
          currentPuzzleIndex++;
          _initPuzzle(currentPuzzleIndex);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The next level is still locked!')),
        );
      }
    }
  }

  // Fitur bantuan: Jika coin mencukupi (>=4), langsung deduksi coin dan buka satu huruf.
// Jika tidak, tampilkan dialog untuk menonton iklan agar mendapatkan 4 coin.
  void _useHelp() {
    final coinProvider = Provider.of<CoinProvider>(context, listen: false);
    if (coinProvider.coins >= 4) {
      // Coin cukup: langsung kurangi 4 coin dan buka satu huruf
      coinProvider.spendCoins(4);
      _revealLetterHelp();
    } else {
      // Coin tidak cukup: tampilkan dialog untuk menonton iklan
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('HELP ME'),
          content: const Text(
              'Coins are not enough. Watch an ad to get 4 coins and help?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                final adProvider =
                    Provider.of<AdProvider>(context, listen: false);
                adProvider.showRewardedAd(() {
                  // Setelah iklan, tambahkan 4 coin, lalu jika coin sudah cukup, kurangi dan buka huruf
                  coinProvider.addCoins(4);
                  if (coinProvider.coins >= 4) {
                    coinProvider.spendCoins(4);
                    _revealLetterHelp();
                  }
                });
              },
              child: const Text('View Ads'),
            ),
          ],
        ),
      );
    }
  }

// Membuka salah satu kotak yang belum terungkap sebagai bantuan.
// Jika seluruh jawaban sudah terisi setelah bantuan, langsung cek jawaban untuk memicu next level.
  void _revealLetterHelp() {
    final puzzle = puzzles[currentPuzzleIndex];
    final answer = puzzle.answer.toUpperCase().split('');

    bool revealed = false;
    for (int i = 0; i < answer.length; i++) {
      if (!revealedIndices[i]) {
        setState(() {
          revealedIndices[i] = true;
          typedLetters[i] = answer[i];
        });
        revealed = true;
        break;
      }
    }
    // Jika seluruh kotak sudah terisi (jawaban lengkap), langsung cek jawaban
    if (!typedLetters.contains('')) {
      _checkAnswer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final puzzle = puzzles[currentPuzzleIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Lv ${puzzle.id}'),
        actions: [
          // Tampilkan jumlah coin di AppBar
          Consumer<CoinProvider>(
            builder: (context, coinProvider, child) {
              return Row(
                children: [
                  const Icon(Icons.monetization_on),
                  const SizedBox(width: 4),
                  Text('${coinProvider.coins}'),
                  const SizedBox(width: 16),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: currentPuzzleIndex > 0 ? _goToPreviousLevel : null,
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => Navigator.pop(context, currentPuzzleIndex),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed:
                currentPuzzleIndex < puzzles.length - 1 ? _goToNextLevel : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: puzzle.images.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: puzzle.images[index],
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 40),
                  ),
                ),
              ),
            ),
            // Answer Boxes
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double totalMargin = (puzzle.answer.length - 1) * 8;
                  double boxWidth = (constraints.maxWidth - totalMargin) /
                      puzzle.answer.length;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      puzzle.answer.length,
                      (index) => Container(
                        width: boxWidth,
                        height: _buttonSize,
                        margin: EdgeInsets.only(
                            right: index == puzzle.answer.length - 1 ? 0 : 8),
                        decoration: BoxDecoration(
                          color: revealedIndices[index]
                              ? Colors.blue[50]
                              : Colors.white,
                          border: Border.all(
                            color: revealedIndices[index]
                                ? Colors.blue
                                : Colors.grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: AutoSizeText(
                            typedLetters[index],
                            style: TextStyle(
                              fontSize: _buttonFontSize,
                              fontWeight: FontWeight.bold,
                              color: revealedIndices[index]
                                  ? Colors.blue
                                  : Colors.black,
                            ),
                            maxLines: 1,
                            minFontSize: 8, // atur sesuai kebutuhan
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // Keyboard
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
              children: List.generate(shuffledLetters.length, (index) {
                return ElevatedButton(
                  onPressed:
                      usedLetter[index] ? null : () => _onLetterTap(index),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor:
                        usedLetter[index] ? Colors.grey[300] : Colors.blue[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    shuffledLetters[index],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Action Buttons: UNDO dan BANTUAN AJA
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.undo, size: 20),
                      label: const Text('UNDO'),
                      onPressed: _undoLetter,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.help_outline, size: 20),
                      label: const Text('HELP ME'),
                      onPressed: _useHelp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
