import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/game_widgets/math_problem_widget.dart';

class MathGameScreen extends StatefulWidget {
  final String difficulty;
  final VoidCallback onGameComplete;
  final VoidCallback onGameFailed;

  const MathGameScreen({
    super.key,
    required this.difficulty,
    required this.onGameComplete,
    required this.onGameFailed,
  });

  @override
  State<MathGameScreen> createState() => _MathGameScreenState();
}

class _MathGameScreenState extends State<MathGameScreen> {
  late List<MathProblem> _problems;
  late int _currentProblemIndex;
  late int _timeLeft;
  late bool _isTimerRunning;
  
  final _answerController = TextEditingController();
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _problems = _generateProblems();
    _currentProblemIndex = 0;
    _timeLeft = _getTimeLimit();
    _isTimerRunning = true;
    _startTimer();
  }

  List<MathProblem> _generateProblems() {
    final int problemCount = _getProblemCount();
    final int maxNumber = _getMaxNumber();
    final List<String> operations = _getOperations();
    final List<MathProblem> problems = [];

    for (int i = 0; i < problemCount; i++) {
      final operation = operations[_random.nextInt(operations.length)];
      final problem = _generateProblem(operation, maxNumber);
      problems.add(problem);
    }

    return problems;
  }

  int _getProblemCount() {
    switch (widget.difficulty) {
      case 'easy':
        return 3;
      case 'medium':
        return 5;
      case 'hard':
        return 7;
      default:
        return 3;
    }
  }

  int _getTimeLimit() {
    switch (widget.difficulty) {
      case 'easy':
        return 120; // 2 minutos
      case 'medium':
        return 180; // 3 minutos
      case 'hard':
        return 240; // 4 minutos
      default:
        return 120;
    }
  }

  int _getMaxNumber() {
    switch (widget.difficulty) {
      case 'easy':
        return 10;
      case 'medium':
        return 25;
      case 'hard':
        return 100;
      default:
        return 10;
    }
  }

  List<String> _getOperations() {
    switch (widget.difficulty) {
      case 'easy':
        return ['+', '-'];
      case 'medium':
        return ['+', '-', '*'];
      case 'hard':
        return ['+', '-', '*', '/'];
      default:
        return ['+', '-'];
    }
  }

  MathProblem _generateProblem(String operation, int maxNumber) {
    late int num1, num2, answer;
    
    switch (operation) {
      case '+':
        num1 = _random.nextInt(maxNumber);
        num2 = _random.nextInt(maxNumber);
        answer = num1 + num2;
        break;
      case '-':
        num1 = _random.nextInt(maxNumber);
        num2 = _random.nextInt(num1 + 1); // Asegurar resultado positivo
        answer = num1 - num2;
        break;
      case '*':
        num1 = _random.nextInt((sqrt(maxNumber)).toInt());
        num2 = _random.nextInt((sqrt(maxNumber)).toInt());
        answer = num1 * num2;
        break;
      case '/':
        num2 = _random.nextInt((sqrt(maxNumber)).toInt()) + 1;
        answer = _random.nextInt(maxNumber ~/ num2);
        num1 = answer * num2;
        break;
      default:
        num1 = _random.nextInt(maxNumber);
        num2 = _random.nextInt(maxNumber);
        answer = num1 + num2;
        operation = '+';
    }

    return MathProblem(
      num1: num1,
      num2: num2,
      operation: operation,
      answer: answer,
    );
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        if (_isTimerRunning && _timeLeft > 0) {
          _timeLeft--;
          if (_timeLeft > 0) {
            _startTimer();
          } else {
            _handleTimeout();
          }
        }
      });
    });
  }

  void _handleTimeout() {
    _isTimerRunning = false;
    widget.onGameFailed();
  }

  void _checkAnswer() {
    final int? userAnswer = int.tryParse(_answerController.text);
    if (userAnswer == null) return;

    if (userAnswer == _problems[_currentProblemIndex].answer) {
      _answerController.clear();
      
      if (_currentProblemIndex < _problems.length - 1) {
        setState(() {
          _currentProblemIndex++;
        });
      } else {
        _isTimerRunning = false;
        widget.onGameComplete();
      }
    } else {
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Respuesta incorrecta, intenta de nuevo'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    _answerController.dispose();
    _isTimerRunning = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Juego de Matemáticas'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Tiempo: ${_timeLeft}s',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: (_currentProblemIndex + 1) / _problems.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Problema ${_currentProblemIndex + 1} de ${_problems.length}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 32),
                      MathProblemWidget(
                        problem: _problems[_currentProblemIndex],
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _answerController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 24),
                        decoration: const InputDecoration(
                          hintText: 'Tu respuesta',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _checkAnswer(),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _checkAnswer,
                        child: const Text('Verificar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MathProblem {
  final int num1;
  final int num2;
  final String operation;
  final int answer;

  MathProblem({
    required this.num1,
    required this.num2,
    required this.operation,
    required this.answer,
  });

  @override
  String toString() {
    return '$num1 $operation $num2 = ?';
  }
}