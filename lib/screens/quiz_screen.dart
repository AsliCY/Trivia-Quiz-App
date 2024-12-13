import 'dart:async';
import 'package:flutter/material.dart';

class QuizScreen extends StatefulWidget {
  final List<dynamic> questions;

  const QuizScreen({super.key, required this.questions});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen>
    with SingleTickerProviderStateMixin {
  int currentQuestionIndex = 0;
  int score = 0;
  String? selectedAnswer;
  bool showCorrectAnswer = false;
  late List<List<String>> answersOrder;
  int timeLeft = 10;
  Timer? timer;
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();

    // Animasyon kontrolcüsü
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    // Cevap sıralamasını sabitle
    answersOrder = widget.questions.map((question) {
      final List<String> answers = [
        ...(question['incorrect_answers'] as List<dynamic>).cast<String>(),
        question['correct_answer'] as String,
      ]..shuffle();
      return answers;
    }).toList();

    // İlk soruya zamanlayıcı başlat
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel(); // Timer'ı temizle
    _animationController?.dispose(); // Animasyonu temizle
    super.dispose();
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          timer.cancel(); // Timer'ı durdur
          moveToNextQuestion(); // Süre dolduğunda sonraki soruya geç
        }
      });
    });
  }

  void moveToNextQuestion() {
    setState(() {
      showCorrectAnswer = true; // Doğru cevabı göster
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (currentQuestionIndex + 1 < widget.questions.length) {
        setState(() {
          currentQuestionIndex++;
          selectedAnswer = null;
          showCorrectAnswer = false;
          timeLeft = 10; // Süreyi sıfırla
        });
        startTimer(); // Yeni soru için zamanlayıcı başlat
      } else {
        // Quiz tamamlandı
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuizCompletedScreen(
                score: score, total: widget.questions.length),
          ),
        );
      }
    });
  }

  void checkAnswer(String answer) {
    final correctAnswer =
        widget.questions[currentQuestionIndex]['correct_answer'];

    timer?.cancel(); // Kullanıcı yanıt verdiğinde zamanlayıcıyı durdur

    setState(() {
      selectedAnswer = answer;
      showCorrectAnswer = true; // Doğru cevabı göster
      if (answer == correctAnswer) {
        score++;
      } else {
        // Yanlış cevap için titreşim animasyonu başlat
        _animationController?.forward().then((value) {
          _animationController?.reset();
        });
      }
    });

    // Yanıt verildikten sonra sonraki soruya geç
    moveToNextQuestion();
  }

  Color getButtonColor(String answer) {
    final correctAnswer =
        widget.questions[currentQuestionIndex]['correct_answer'];

    if (!showCorrectAnswer) {
      return Colors.blue.shade100; // Varsayılan renk: açık mavi
    }
    if (answer == correctAnswer) {
      return Colors.green.shade200; // Doğru cevap: açık yeşil
    }
    if (answer == selectedAnswer) {
      return Colors.red.shade200; // Yanlış cevap: açık kırmızı
    }
    return Colors.grey.shade300; // Diğer seçenekler: açık gri
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[currentQuestionIndex];
    final answers = answersOrder[currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Question ${currentQuestionIndex + 1}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Zaman göstergesini üstte konumlandırma
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: timeLeft / 10,
                      strokeWidth: 8.0,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation(
                        timeLeft <= 5 ? Colors.red : Colors.green,
                      ),
                    ),
                  ),
                  Text(
                    '$timeLeft',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: timeLeft <= 5 ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Soru metnini daha estetik hale getirmek için Card widget'ı kullanıyoruz
            Card(
              elevation: 2.0,
              color: Colors.blue.shade50, // Pastel ton
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  question['question'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Şıklar
            Expanded(
              child: ListView(
                children: answers.map((answer) {
                  return AnimatedBuilder(
                    animation: _animationController!,
                    builder: (context, child) {
                      double offset = _animationController!.value * 20;
                      return Transform.translate(
                        offset: Offset(
                          selectedAnswer == answer &&
                                  answer !=
                                      widget.questions[currentQuestionIndex]
                                          ['correct_answer']
                              ? offset % 2 == 0
                                  ? -offset
                                  : offset
                              : 0,
                          0,
                        ),
                        child: child,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: showCorrectAnswer
                            ? null
                            : () => checkAnswer(answer),
                        style: ButtonStyle(
                          backgroundColor:
                              WidgetStateProperty.resolveWith((states) {
                            return getButtonColor(answer);
                          }),
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          padding: WidgetStateProperty.all(
                            const EdgeInsets.symmetric(vertical: 16.0),
                          ),
                        ),
                        child: Text(
                          answer,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizCompletedScreen extends StatelessWidget {
  final int score;
  final int total;

  const QuizCompletedScreen({super.key, required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Completed'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your Score: $score/$total',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }
}
