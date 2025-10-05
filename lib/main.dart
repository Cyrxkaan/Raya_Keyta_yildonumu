  // lib/main.dart
  import 'dart:async';
  import 'dart:math';
  import 'package:flutter/material.dart';
  import 'package:flutter_animate/flutter_animate.dart';
  import 'package:google_fonts/google_fonts.dart';
  import 'package:confetti/confetti.dart';
  import 'package:audioplayers/audioplayers.dart';

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
    final TextEditingController _controller = TextEditingController();
    final FocusNode _answerFocus = FocusNode();
    int _currentQuestion = 0;
    int _score = 0;
    int _timeLeft = 20;
    Timer? _timer;
    bool _finished = false;
    bool _wrongAnswer = false;
    String _wrongMessage = "";

    late final ConfettiController _confettiCorrect;
    late final ConfettiController _confettiWrong;
    late final ConfettiController _confettiFinal;

    late final AnimationController _shakeController;
    late final Animation<double> _shakeAnimation;

    late final AnimationController _bgController;
    late final AnimationController _heartsController;

    late final AnimationController _finalController;
    late final Animation<double> _scaleFinal;
    late final Animation<double> _fadeFinal;

    final List<double> _heartX = [0.08, 0.22, 0.38, 0.56, 0.72, 0.88];

    final List<String> _stickerPaths = [
      'assets/stickers/sticker1 (1).png',
      'assets/stickers/sticker2 (1).png',
      'assets/stickers/sticker5-200px.png',
      'assets/stickers/sticker3100px.png',
      'assets/stickers/stiker4.png',
    ];

    late final List<double> _stickerX = List.generate(5, (i) => 0.05 + 0.18 * i);

    final List<Map<String, dynamic>> _questions = [
      {
        "q": "İlk buluşma yerimiz neresiydi?",
        "a": ["kadıköy", "kadikoy", "iskele","kadıköy iskelesi"],
        "hint": "İstanbul'un en güzel semtlerinden biri..."
      },
      {
        "q": "Bana en yakıştırdığın renk nedu?",
        "a": ["gri", "Gri", "Grı","grı",],
        "hint": "Bazen bulutların rengi gibi..."
      },
      {
        "q": "Bu emojiler sana hangi ismi hatırlatıyor 🐹👨🏿?",
        "a": ["ginenigı", "gine nigı", "Ginenigı","ginenıgi"],
        "hint": "Küçük bir hayvan ve büyük bir adam 😏"
      },
      {
        "q": "Birlikte yemekten en keyif aldığımız tatlı?",
        "a": ["Hasan efendi kruvasanı", "hasan efendi", "çikolatalı kruvasan","çikolatali kruvasan","çilekli muzlu kruvasan","kruvasan","hasanefendi kruvasani"],
        "hint": "Sabah kahvesiyle çok yakışır ☕🥐"
      },
      {
        "q": "Ayak numaram nedir?",
        "a": ["44", "44.5", "44 veya 44.5","45"],
        "hint": "Büyük bir ayak numarası 😉"
      },
      {
        "q": "En sevdiğin özelliğim?",
        "a": ["bir şeyleri çözmen", "Bir şeyleri halletmen", "bir şeyleri çozmen", "çalışkanlığın","çalışkan olman","birşeyleri çözmen","birşeyleri halletmen","zeki olman","zekan","zekiliğin","zekan seviyen","caliskanliğin","birseyleri  cozmen","bir seyleri cozmen"],
        "hint": "Zekân ve çözüm yeteneğin 💡"
      },
      {
        "q": "En sevdiğimiz instagram maskotları ?",
        "a": ["milk mocha", "milk-mocha", "milk and mocha","milkmocha","mocha ve milk","mocha milk","mochamilk","mılkmocha","mılk mocha"],
        "hint": "Tatlı ve sevimli bir ikili 🐶🐱"
      },
      {
        "q": "En sevmediğin özelliğim?",
        "a": ["susman", "Susman", "Konuşmaman","susmam", "Susmam", "Konuşmamam"],
        "hint": "Bazen sessizlik iyidir 😶"
      },
      {
        "q": "Bir hayvan olsaydım ne olurdum?",
        "a": ["su samuru", "Su samuru", "gri kedi","susamuru","Susamuru","öküz","Öküz"],
        "hint": "Suda ve karada yaşayan sevimli 🦦"
      },
      {
        "q": "Favori ortak yemeğimiz ne aşkuş?",
        "a": ["balık dürüm", "balik durum", "balık", "durum","balık ekmek","balik ekmek","balikekmek","balıkekmek","dürüm"],
        "hint": "Deniz kenarında yemeyi severiz 🐟🌯"
      },
      {
        "q": "Yıldönümümüz ne zamandır :D ?",
        "a": ["6 ekim", "06 ekim", "6.ekim", "6/10", "6-10","6ekim","6ekım","6 ekım","6:10","6 ekim 2024","06.10.2024","6ekim"],
        "hint": "Güzel bir sonbahar günü 🍂"
      },
      {
        "q": "En çok istediğimiz şey?",
        "a": ["Evlenmek", "evli olmak", "aile olmak","birlikte gezmek","evlilik","evli olmamız","evli olmamiz","evli olmamız","yuva kurmak","evimizde olmak","evlenmek"],
        "hint": "Hayallerimizdeki büyük adım 💍"
      },
    ];

    final List<Map<String, dynamic>> _scoreMessages = [
      {"min": 0, "max": 3, "msg": "Hmm… Biraz daha dikkat gerek 💖"},
      {"min": 4, "max": 7, "msg": "Güzel! İyi iş çıkardın kuzu 💕"},
      {"min": 8, "max": 12, "msg": "Mükemmel Ballışım! 🌸💖"},
    ];

    late final AudioPlayer _audioPlayer;

    @override
    void initState() {
      super.initState();

      _confettiCorrect = ConfettiController(duration: const Duration(seconds: 1));
      _confettiWrong = ConfettiController(duration: const Duration(seconds: 1));
      _confettiFinal = ConfettiController(duration: const Duration(seconds: 4));

      _shakeController =
          AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
      _shakeAnimation = Tween<double>(begin: 0, end: 7)
          .animate(CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));

      _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 10))
        ..repeat();

      _heartsController = AnimationController(vsync: this, duration: const Duration(seconds: 6))
        ..repeat();

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

      _startTimer();
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_answerFocus);
      });

      // Müzik çalma
      _audioPlayer = AudioPlayer();

      _audioPlayer.setReleaseMode(ReleaseMode.loop);
      _audioPlayer.play(AssetSource('audio/KlavdiiaPetrivna.mp3'));
    }

    void _startTimer() {
      _timer?.cancel();
      setState(() => _timeLeft = 20);
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
      Future.delayed(const Duration(milliseconds: 100), () {
        FocusScope.of(context).requestFocus(_answerFocus);
      });
    }

    void _handleTimeout() {
      _confettiWrong.play();
      _shakeController.forward(from: 0);
      setState(() {
        _wrongMessage = "Süre doldu — soru geçildi :)";
        _wrongAnswer = true;
      });
      Future.delayed(const Duration(seconds: 1), () {
        setState(() {
          _wrongAnswer = false;
          _nextQuestion();
        });
      });
    }

    void _checkAnswer() {
      final String answer = _controller.text.toLowerCase().trim();
      final List<String> valid = (_questions[_currentQuestion]['a'] as List).cast<String>();
      final bool ok = valid.any((ans) => answer.contains(ans));

      if (ok) {
        _confettiCorrect.play();
        _score++;
        Future.delayed(const Duration(milliseconds: 700), () => _nextQuestion());
      } else {
        _confettiWrong.play();
        _shakeController.forward(from: 0);
        setState(() {
          _wrongMessage = "Yanlış cevap — soru geçiliyor 💕";
          _wrongAnswer = true;
        });
        Future.delayed(const Duration(milliseconds: 900), () {
          setState(() {
            _wrongAnswer = false;
            _nextQuestion();
          });
        });
      }
    }

    void _nextQuestion() {
      if (_currentQuestion < _questions.length - 1) {
        setState(() {
          _currentQuestion++;
          _controller.clear();
        });
        _resetTimer();
      } else {
        _finished = true;
        _confettiFinal.play();
        _finalController.forward(from: 0);
        _timer?.cancel();
      }
    }

    void _restartGame() {
      setState(() {
        _currentQuestion = 0;
        _score = 0;
        _finished = false;
        _controller.clear();
      });
      _resetTimer();
    }

    @override
    void dispose() {
      _controller.dispose();
      _answerFocus.dispose();
      _timer?.cancel();
      _confettiCorrect.dispose();
      _confettiWrong.dispose();
      _confettiFinal.dispose();
      _shakeController.dispose();
      _bgController.dispose();
      _heartsController.dispose();
      _finalController.dispose();
      _audioPlayer.dispose();
      super.dispose();
    }

    LinearGradient _animatedGradient(double t) {
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

    String _getScoreMessage() {
      for (var sm in _scoreMessages) {
        if (_score >= sm['min'] && _score <= sm['max']) return sm['msg'];
      }
      return "Harikasın Bal!";
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
                    ..._buildRisingHearts(size.width, size.height),
                    ..._buildRisingStickers(size.width, size.height),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 18),
                        Center(
                          child: Stack(
                            children: [
                              Text(
                                "RAYA & KEYTA\nYıldönümü Quizi",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.bangers(
                                  fontSize: 55,
                                  foreground: Paint()
                                    ..style = PaintingStyle.stroke
                                    ..strokeWidth = 6
                                    ..color = Colors.black,
                                ),
                              ),
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
                                    fontSize: 55,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 22.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.yellowAccent, size: 28),
                                  const SizedBox(width: 6),
                                  Text("$_score / ${_questions.length}",
                                      style: GoogleFonts.poppins(
                                          fontSize: 18, color: Colors.white, fontWeight: FontWeight.w600)),
                                ],
                              ),
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

    Widget _buildQuestionCard(Size size) {
      return SizedBox(
        key: ValueKey<int>(_currentQuestion),
        width: min(760.0, size.width * 0.88),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                (_score > _currentQuestion)
                    ? _questionBadgeForIndex(_currentQuestion)
                    : const SizedBox(width: 1),
              ],
            ),
            const SizedBox(height: 18),
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final double dx = _shakeAnimation.value * (_wrongAnswer ? (sin(DateTime.now().millisecond * 0.05) >= 0 ? 1 : -1) : 0);
                return Transform.translate(
                  offset: Offset(dx, 0),
                  child: child,
                );
              },
              child: SizedBox(
                width: 380,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
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
                    SizedBox(
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
                    TextField(
                      focusNode: _answerFocus,
                      controller: _controller,
                      onSubmitted: (_) => _checkAnswer(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 22, color: Colors.white, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white24,
                        hintText: 'Cevabını buraya yaz kuzu…',
                        hintStyle: GoogleFonts.poppins(color: Colors.white70),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.lightbulb, color: Colors.yellowAccent),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("İpucu 💡"),
                                content: Text(_questions[_currentQuestion]['hint'] ?? "İpucu yok"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Kapat"),
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_wrongAnswer)
              Text(
                _wrongMessage,
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.yellowAccent),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      );
    }

    List<Widget> _buildRisingHearts(double width, double height) {
      final List<Widget> hearts = [];
      final double base = _heartsController.value;
      for (int i = 0; i < _heartX.length; i++) {
        final double phase = (base + i * 0.15) % 1.0;
        final double top = height * (1.0 - phase) * 0.95;
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

    List<Widget> _buildRisingStickers(double width, double height) {
      final List<Widget> stickers = [];
      final double base = _heartsController.value;

      final List<Size> stickerSizes = [
        const Size(120, 101),
        const Size(200, 200),
        const Size(200, 173),
        const Size(120, 100),
        const Size(200, 170),
      ];

      for (int i = 0; i < _stickerPaths.length; i++) {
        final double phase = (base + i * 0.19) % 1.0;
        final double top = height * (1.0 - phase) * 0.95;
        final double opacity = (1.0 - phase).clamp(0.0, 1.0);

        stickers.add(Positioned(
          left: width * _stickerX[i] - stickerSizes[i].width / 2,
          top: top,
          child: Opacity(
            opacity: opacity,
            child: Image.asset(
              _stickerPaths[i],
              width: stickerSizes[i].width,
              height: stickerSizes[i].height,
            ),
          ),
        ));
      }
      return stickers;
    }

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
                  "Sana özel bir mesaj: \n\n\"Birlikte geçirdiğimiz ilk yılımız kutlu olsun aşkım 💖\n Bir yıl önce hayatıma girdin ve her şey bir anda daha anlamlı, daha güzel, daha sıcak oldu.\n Seninle gülmek, seninle dertleşmek, seninle susmak bile başka bir huzur.\n Her anında var olmak, her sabah seninle bir geleceği hayal etmek benim için en güzel his.\n Bu bir yıl sadece başlangıçtı. Bundan sonrası, birlikte kuracağımız hayaller, gideceğimiz yollar, aynı yastığa baş koyacağımız günler… hepsi bizi bekliyor.\n Seni her geçen gün daha çok seviyorum ve iyi ki varsın, iyi ki benimlesin.\n 💫❤Seni tanımak benim için en güzel hediye.\"",
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 12),
                Text("🌅🌸", style: const TextStyle(fontSize: 36)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text("Kapat"),
              )
            ],
          );
        },
      );
    }

    Widget _buildFinalScreen(Size size) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleFinal,
            child: FadeTransition(
              opacity: _fadeFinal,
              child: Text(
                "Tebrikler Ballışım! 💖",
                textAlign: TextAlign.center,
                style: GoogleFonts.pacifico(
                  fontSize: 48,
                  color: Colors.yellowAccent,
                  shadows: [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.black26,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            "Tüm soruları tamamladın.\n${_getScoreMessage()}",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 20, color: Colors.white70),
          ),
          const SizedBox(height: 22),
          ElevatedButton(
            onPressed: _openSurpriseDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pinkAccent,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text("Sürprizi Gör 🌸", style: GoogleFonts.poppins(fontSize: 20)),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _restartGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text("Yeniden Başlat 🔄", style: GoogleFonts.poppins(fontSize: 20)),
          ),
        ],
      );
    }
  }
