import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'play.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> puzzles = [];
  int currentPage = 0;
  final int pageSize = 12;
  Set<int> unlockedLevels = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _initUnlockedLevels();
    await _fetchPuzzles();
  }

  Future<void> _initUnlockedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedList = prefs.getStringList('unlockedLevels') ?? ['1'];
    final unlocked = unlockedList.map((e) => int.tryParse(e) ?? 1).toSet();

    // Hanya update currentPage saat pertama kali load
    if (puzzles.isEmpty) {
      final maxLevel = unlocked.reduce((a, b) => a > b ? a : b);
      setState(() {
        currentPage = (maxLevel - 1) ~/ pageSize;
      });
    }
    setState(() {
      unlockedLevels = unlocked;
    });
  }

  Future<void> _saveUnlockedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedList = unlockedLevels.map((e) => e.toString()).toList();
    await prefs.setStringList('unlockedLevels', unlockedList);
  }

  Future<void> _fetchPuzzles() async {
    setState(() => isLoading = true);
    final start = currentPage * pageSize;
    final end = start + pageSize - 1;

    final response = await supabase
        .from('puzzles')
        .select()
        .order('level', ascending: true)
        .range(start, end);
    final data = List<Map<String, dynamic>>.from(response as List);

    setState(() {
      puzzles = data;
      isLoading = false;
    });
  }

  void _nextPage() {
    setState(() => currentPage++);
    _fetchPuzzles();
  }

  void _previousPage() {
    if (currentPage > 0) {
      setState(() => currentPage--);
      _fetchPuzzles();
    }
  }

  Future<void> _onLevelTap(Map<String, dynamic> puzzle, int index) async {
    final puzzleId = puzzle['level'] as int;

    if (!unlockedLevels.contains(puzzleId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This level is still locked!')),
      );
      return;
    }

    // Simpan level yang ditekan sebelum navigasi
    final int lastPlayedLevel = (index + 1) + (currentPage * pageSize);

    // Saat kembali, kita terima nilai level terakhir yang dimainkan dari PlayPage.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayPage(
          initialPuzzleIndex: index,
          puzzles: puzzles,
        ),
      ),
    );

    // Jika PlayPage mengembalikan index level terakhir, update currentPage sesuai level tersebut.
    if (result != null && result is int) {
      setState(() {
        currentPage =
            (result + 1 - 1) ~/ pageSize; // (lastPlayedLevel - 1) ~/ pageSize
      });
      _fetchPuzzles();
    }

    // Update unlockedLevels tanpa mengubah currentPage lagi.
    await _updateUnlockedLevels();
  }

  Future<void> _updateUnlockedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    final unlockedList = prefs.getStringList('unlockedLevels') ?? ['1'];
    setState(() {
      unlockedLevels = unlockedList.map((e) => int.tryParse(e) ?? 1).toSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Play Game'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : puzzles.isEmpty
                ? const Center(
                    child: Text(
                      'Tidak ada level tersedia',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
                : Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 30,
                            runSpacing: 30,
                            children: puzzles.map((puzzle) {
                              final puzzleId = puzzle['level'] as int;
                              final isUnlocked =
                                  unlockedLevels.contains(puzzleId);
                              // levelNumber menyesuaikan dengan halaman
                              final levelNumber = (puzzles.indexOf(puzzle) +
                                  1 +
                                  (currentPage * pageSize));

                              return GestureDetector(
                                onTap: () => _onLevelTap(
                                    puzzle, puzzles.indexOf(puzzle)),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: isUnlocked
                                        ? Colors.green.withOpacity(0.9)
                                        : Colors.grey.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 6,
                                        offset: Offset(2, 3),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      FaIcon(
                                        isUnlocked
                                            ? FontAwesomeIcons.unlock
                                            : FontAwesomeIcons.lock,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(height: 28),
                                      Positioned(
                                        bottom: 12,
                                        child: Text(
                                          levelNumber.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton(
                              onPressed: currentPage > 0 ? _previousPage : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.withOpacity(0.8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                child: Text(
                                  'Prev',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              onPressed:
                                  puzzles.length == pageSize ? _nextPage : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.withOpacity(0.8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12),
                                child: Text(
                                  'Next',
                                  style: TextStyle(color: Colors.white),
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
