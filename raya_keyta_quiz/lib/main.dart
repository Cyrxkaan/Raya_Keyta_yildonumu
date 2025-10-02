// lib/main.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

void main() {
  runApp(const LoveQuizApp());
}

class LoveQuizApp extends StatelessWidget {
  const LoveQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RAYA & KEYTA Quiz',
      debugShowCheckedModeBanner: false,
      home: const PuzzlePage(),
    );
  }
}

class PuzzlePage extends StatefulWidget {
  const PuzzlePage({super.key});
  @override
  _PuzzlePageState createState() => _PuzzlePageState();
}

class _PuzzlePageState extends State<PuzzlePage> with TickerProviderStateMixin {
  // Controllers and state
  final TextEditingController _controller = TextEditingController();
  int _currentQuestion = 0;
  int _score = 0;
  int _timeLeft = 15;
  Timer? _timer;
  bool _finished = false;
  bool _wrongAnswer = false;
  String _wrongMessage = "";

  // Anim & confetti
  late final ConfettiController _confettiCorrect;
  late final ConfettiController _confettiWrong;
  late final ConfettiController _confettiFinal;

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  late final AnimationController _bgController; // background gradient shift
  late final AnimationController _heartsController; // hearts motion

  late final AnimationController _finalController;
  late final Animation<double> _scaleFinal;
  late final Animation<double> _fadeFinal;

  // Heart x positions (fractions of width)
  final List<double> _heartX = [0.08, 0.22, 0.38, 0.56, 0.72, 0.88];

  // Questions + accepted answer substrings
  final List<Map<String, dynamic>> _questions = [
    {
      "q": "İlk buluşma yerimiz neresiydi?",
      "a": ["kadıköy", "kadikoy", "iskele"]
    },
    {
      "q": "Favori ortak yemeğimiz nedir?",
      "a": ["balık dürüm", "balik durum", "balık", "durum"]
    },
    {
      "q": "Yıldönümümüz hangi tarihtir?",
      "a": ["6 ekim", "06 ekim", "6.ekim", "6/10", "6-10"]
    },
  ];

  @override
  void initState() {
    super.initState();

    _confettiCorrect = ConfettiController(duration: const Duration(seconds: 1));
    _confettiWrong = ConfettiController(duration: const Duration(seconds: 1));
    _confettiFinal = ConfettiController(duration: const Duration(seconds: 4));

    // subtle shake for wrong answers
    _shakeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _shakeAnimation = Tween<double>(begin: 0, end: 14)
        .animate(CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));

    // background gradient cycle
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();

    // hearts rising cycle
    _heartsController = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();

    // final message pulse
    _finalController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _scaleFinal = Tween<double>(begin: 0.8, end: 1.08)
        .animate(CurvedAnimation(parent: _finalController, curve: Curves.easeInOut));
    _fadeFinal = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _finalController, curve: Curves.easeIn));
    _finalController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _finalController.repeat(reverse: true);
      }
    });

    // start timer for first question
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _timeLeft = 15);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) {
          t.cancel();
          _handleTimeout();
        }
      });
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    if (!_finished) _startTimer();
  }

  void _handleTimeout() {
    // treat as wrong attempt: light shake, red confetti, message
    _confettiWrong.play();
    _shakeController.forward(from: 0);
    setState(() {
      _wrongMessage = "Süre doldu — biraz daha hızlı olalım :)";
      _wrongAnswer = true;
    });
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _wrongAnswer = false;
      });
      // allow retry same question (do not auto-skip) — or skip: change if you wish
      _resetTimer();
    });
  }

  void _checkAnswer() {
    final String answer = _controller.text.toLowerCase().trim();
    final List<String> valid = (_questions[_currentQuestion]['a'] as List).cast<String>();
    final bool ok = valid.any((ans) => answer.contains(ans));

    if (ok) {
      _confettiCorrect.play();
      _confettiCorrect.play(); // a bit more visible
      setState(() {
        _wrongMessage = "";
        _wrongAnswer = false;
        _score++;
      });

      // show small success, move next after short delay
      _timer?.cancel();
      Future.delayed(const Duration(milliseconds: 700), () {
        if (_currentQuestion < _questions.length - 1) {
          setState(() {
            _currentQuestion++;
            _controller.clear();
          });
          _resetTimer();
        } else {
          // finished
          setState(() {
            _finished = true;
          });
          _confettiFinal.play();
          _finalController.forward(from: 0);
          _timer?.cancel();
        }
      });
    } else {
      // wrong
      _confettiWrong.play();
      _shakeController.forward(from: 0);
      setState(() {
        _wrongMessage = "Biraz daha düşün istersen balım 💕";
        _wrongAnswer = true;
      });
      Future.delayed(const Duration(milliseconds: 900), () {
        setState(() => _wrongAnswer = false);
        _resetTimer();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    _confettiCorrect.dispose();
    _confettiWrong.dispose();
    _confettiFinal.dispose();
    _shakeController.dispose();
    _bgController.dispose();
    _heartsController.dispose();
    _finalController.dispose();
    super.dispose();
  }

  // helper: animated background gradient using bg controller value
  LinearGradient _animatedGradient(double t) {
    // two color palettes to lerp between
    final List<Color> a = [const Color(0xFF3A0CA3), const Color(0xFF7209B7), const Color(0xFFEC4899)];
    final List<Color> b = [const Color(0xFF5E60CE), const Color(0xFFFB7185), const Color(0xFFFFB86B)];

    Color lerpColor(Color c1, Color c2, double f) => Color.lerp(c1, c2, f)!;

    return LinearGradient(
      begin: Alignment(-1 + 2 * t, -1),
      end: Alignment(1 - 2 * t, 1),
      colors: [
        lerpColor(a[0], b[0], (sin(2 * pi * t) + 1) / 2),
        lerpColor(a[1], b[1], (cos(2 * pi * t) + 1) / 2),
        lerpColor(a[2], b[2], (sin(2 * pi * (t + 0.25)) + 1) / 2),
      ],
    );
  }

  // hearts that slowly rise in background
  List<Widget> _buildRisingHearts(double width, double height) {
    final List<Widget> hearts = [];
    final double base = _heartsController.value; // 0..1
    for (int i = 0; i < _heartX.length; i++) {
      final double phase = (base + i * 0.17) % 1.0;
      final double top = height * (1.0 - phase) * 0.95; // from near bottom to top
      final double opacity = (1.0 - phase).clamp(0.0, 1.0);
      final double scale = 0.6 + (1 - phase) * 0.8;
      hearts.add(Positioned(
        left: width * _heartX[i] - 12,
        top: top,
        child: Opacity(
          opacity: opacity * 0.9,
          child: Transform.scale(
            scale: scale,
            child: Icon(
              Icons.favorite,
              size: 24,
              color: Colors.pinkAccent.withOpacity(0.9),
            ),
          ),
        ),
      ));
    }
    return hearts;
  }

  // small badge showing emoji or small image for each question after correct
  Widget _questionBadgeForIndex(int idx) {
    switch (idx) {
      case 0:
        return const Text("⛴️", style: TextStyle(fontSize: 36));
      case 1:
        return const Text("🐟🌯", style: TextStyle(fontSize: 36));
      case 2:
        return const Text("🎉🎂", style: TextStyle(fontSize: 36));
      default:
        return const SizedBox.shrink();
    }
  }

  // final surprise dialog
  void _openSurpriseDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.pink.shade50,
          title: Text("Sürpriz 🎁", style: GoogleFonts.pacifico()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Sana özel bir mesaj: \n\n\"Seni tanımak benim için en güzel hediye. İyi ki varsın Ballışım.\"",
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 12),
              // placeholder decorative image (emoji)
              Text("🌅🌸", style: const TextStyle(fontSize: 36)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(), //https://github.com/Cyrxkaan/RayaKeytaQuiz.git
              child: const Text("Kapat"),
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([_bgController, _heartsController]),
      builder: (context, child) {
        final double t = _bgController.value;
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: _animatedGradient(t),
            ),
            child: SafeArea(
              child: Stack(
                children: [
                  // rising hearts in background
                  ..._buildRisingHearts(size.width, size.height),

                  // main column content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 18),
                      // header - big, stroked (black outline) + colored fill
                      Center(
                        child: Stack(
                          children: [
                            // stroke
                            Text(
                              "RAYA & KEYTA\nYıldönümü Quizi",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.bangers(
                                fontSize: 48,
                                foreground: Paint()
                                  ..style = PaintingStyle.stroke
                                  ..strokeWidth = 6
                                  ..color = Colors.black,
                              ),
                            ),
                            // colored
                            ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [Colors.pinkAccent, Colors.orangeAccent, Colors.purpleAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                "RAYA & KEYTA\nYıldönümü Quizi",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.bangers(
                                  fontSize: 48,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // top row: score + timer bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Score (stars)
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.yellowAccent, size: 28),
                                const SizedBox(width: 6),
                                Text("$_score / ${_questions.length}",
                                    style: GoogleFonts.poppins(
                                        fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            // Timer
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text("Süre: $_timeLeft s",
                                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white)),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 140,
                                  child: LinearProgressIndicator(
                                    value: (_timeLeft.clamp(0, 15)) / 15,
                                    color: _timeLeft > 5 ? Colors.greenAccent : Colors.redAccent,
                                    backgroundColor: Colors.white24,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),

                      // central card area
                      Expanded(
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (w, anim) =>
                                FadeTransition(opacity: anim, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(anim), child: w)),
                            child: _finished
                                ? _buildFinalScreen(size)
                                : _buildQuestionCard(size),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // small footer hint
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Text(
                          "Cevabı yazıp Enter'a bas — küçük sürprizler için dikkatli ol 💖",
                          style: GoogleFonts.poppins(color: Colors.white70),
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // QUESTION CARD
  Widget _buildQuestionCard(Size size) {
    return SizedBox(
      key: ValueKey<int>(_currentQuestion),
      width: min(760.0, size.width * 0.88),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // question text + badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _questions[_currentQuestion]['q'] as String,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ).animate().fadeIn(duration: 450.ms).slideY(),
              const SizedBox(width: 10),
              // small emoji badge (delayed visibility)
              (_score > _currentQuestion)
                  ? _questionBadgeForIndex(_currentQuestion)
                  : const SizedBox(width: 1),
            ],
          ),
          const SizedBox(height: 18),

          // TextField + confetti behind + elevated white box
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              final double dx = _shakeAnimation.value * ( _wrongAnswer ? (sin(DateTime.now().millisecond * 0.05) >= 0 ? 1 : -1) : 0);
              return Transform.translate(
                offset: Offset(dx, 0),
                child: child,
              );
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Confetti container behind TextField, centered and same size as TextField
                SizedBox(
                  width: 380,
                  height: 68,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // correct confetti
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 380,
                          height: 68,
                          child: ConfettiWidget(
                            confettiController: _confettiCorrect,
                            blastDirectionality: BlastDirectionality.explosive,
                            emissionFrequency: 0.4,
                            numberOfParticles: 18,
                            maxBlastForce: 20,
                            minBlastForce: 6,
                            gravity: 0.45,
                            shouldLoop: false,
                          ),
                        ),
                      ),
                      // wrong confetti
                      Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 380,
                          height: 68,
                          child: ConfettiWidget(
                            confettiController: _confettiWrong,
                            blastDirectionality: BlastDirectionality.explosive,
                            emissionFrequency: 0.4,
                            numberOfParticles: 18,
                            maxBlastForce: 20,
                            minBlastForce: 6,
                            gravity: 0.45,
                            colors: const [Colors.red, Colors.deepOrange, Colors.pink],
                            shouldLoop: false,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Foreground: elevated white text box
                Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 380,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: _wrongAnswer ? Colors.redAccent : Colors.white,
                        width: 2,
                      ),
                    ),
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.done,
                      style: const TextStyle(color: Colors.black87, fontSize: 18),
                      onSubmitted: (_) => _checkAnswer(),
                      decoration: InputDecoration(
                        hintText: "Cevabını yaz ve Enter'a bas...",
                        hintStyle: GoogleFonts.robotoMono(fontSize: 15, color: Colors.grey.shade600),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          // wrong message
          AnimatedOpacity(
            duration: const Duration(milliseconds: 350),
            opacity: _wrongMessage.isNotEmpty ? 1.0 : 0.0,
            child: Text(
              _wrongMessage,
              style: GoogleFonts.poppins(
                color: Colors.yellowAccent,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(height: 16),
          // quick helpers: progress bar and mini buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // small skip / hint button (optional)
                ElevatedButton.icon(
                  onPressed: () {
                    // reveal hint or skip (optional behaviour)
                    final hint = (_questions[_currentQuestion]['a'] as List).first;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("İpucu: $hint")));
                  },
                  icon: const Icon(Icons.lightbulb),
                  label: const Text("İpucu"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
                ),
                const SizedBox(width: 16),
                // time bar (small)
                Expanded(
                  child: LinearProgressIndicator(
                    value: _timeLeft / 15,
                    minHeight: 8,
                    backgroundColor: Colors.white24,
                    color: _timeLeft > 5 ? Colors.greenAccent : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // FINAL SCREEN
  Widget _buildFinalScreen(Size size) {
    return SizedBox(
      key: const ValueKey('final'),
      width: min(820.0, size.width * 0.9),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // big animated message with stroke (outline)
          FadeTransition(
            opacity: _fadeFinal,
            child: ScaleTransition(
              scale: _scaleFinal,
              child: Stack(
                children: [
                  // stroke
                  Text(
                    "İyi ki varsın\nBallışım 💖",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pacifico(
                      fontSize: 68,
                      foreground: Paint()
                        ..style = PaintingStyle.stroke
                        ..strokeWidth = 6
                        ..color = Colors.black,
                    ),
                  ),
                  // gradient fill + shadow
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.pinkAccent, Colors.orangeAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: Text(
                      "İyi ki varsın\nBallışım 💖",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.pacifico(
                        fontSize: 68,
                        color: Colors.white,
                        shadows: const [
                          Shadow(blurRadius: 16, color: Colors.black45, offset: Offset(4, 4))
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // score and small subtitle
          Text(
            "Tebrikler! ${_score}/${_questions.length} doğru bildin 💫",
            style: GoogleFonts.poppins(fontSize: 20, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          Text(
            "Bunların hepsini bildiğine göre… beni gerçekten çok iyi tanıyorsun 💕",
            style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _openSurpriseDialog,
                icon: const Icon(Icons.card_giftcard),
                label: const Text("Bir sürpriz daha 🎁"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // restart
                  setState(() {
                    _finished = false;
                    _score = 0;
                    _currentQuestion = 0;
                    _controller.clear();
                    _wrongMessage = "";
                    _wrongAnswer = false;
                  });
                  _startTimer();
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Tekrarla"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
              ),
            ],
          )
        ],
      ),
    );
  }
}
