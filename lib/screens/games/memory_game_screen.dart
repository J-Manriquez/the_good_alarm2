import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/game_widgets/memory_card_widget.dart';

class MemoryGameScreen extends StatefulWidget {
  final String difficulty;
  final VoidCallback onGameComplete;
  final VoidCallback onGameFailed;

  const MemoryGameScreen({
    super.key,
    required this.difficulty,
    required this.onGameComplete,
    required this.onGameFailed,
  });

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  late List<MemoryCard> _cards;
  late int _timeLeft;
  late bool _isTimerRunning;
  final List<int> _selectedIndices = [];
  int _matchedPairs = 0;
  bool _canFlipCards = true;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    _cards = _generateCards();
    _timeLeft = _getTimeLimit();
    _isTimerRunning = true;
    _matchedPairs = 0;
    _startTimer();
  }

  List<MemoryCard> _generateCards() {
    final int pairCount = _getPairCount();
    final List<MemoryCard> cards = [];
    final List<int> values = List.generate(pairCount, (index) => index);
    final random = Random();

    // Crear pares de cartas
    for (int value in values) {
      for (int i = 0; i < 2; i++) {
        cards.add(MemoryCard(
          value: value,
          isFlipped: false,
          isMatched: false,
        ));
      }
    }

    // Mezclar las cartas
    for (int i = cards.length - 1; i > 0; i--) {
      int randomIndex = random.nextInt(i + 1);
      MemoryCard temp = cards[i];
      cards[i] = cards[randomIndex];
      cards[randomIndex] = temp;
    }

    return cards;
  }

  int _getPairCount() {
    switch (widget.difficulty) {
      case 'easy':
        return 6;  // 12 cartas
      case 'medium':
        return 12; // 24 cartas
      case 'hard':
        return 18; // 36 cartas
      default:
        return 6;
    }
  }

  int _getTimeLimit() {
    switch (widget.difficulty) {
      case 'easy':
        return 60;  // 1 minuto
      case 'medium':
        return 120; // 2 minutos
      case 'hard':
        return 180; // 3 minutos
      default:
        return 60;
    }
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

  void _onCardTap(int index) {
    if (!_canFlipCards || 
        _cards[index].isFlipped || 
        _cards[index].isMatched ||
        _selectedIndices.contains(index)) {
      return;
    }

    setState(() {
      _cards[index].isFlipped = true;
      _selectedIndices.add(index);
    });

    if (_selectedIndices.length == 2) {
      _canFlipCards = false;
      _checkMatch();
    }
  }

  void _checkMatch() {
    final card1 = _cards[_selectedIndices[0]];
    final card2 = _cards[_selectedIndices[1]];

    if (card1.value == card2.value) {
      // Es un par
      setState(() {
        card1.isMatched = true;
        card2.isMatched = true;
        _matchedPairs++;
        _selectedIndices.clear();
        _canFlipCards = true;
      });

      if (_matchedPairs == _getPairCount()) {
        _isTimerRunning = false;
        widget.onGameComplete();
      }
    } else {
      // No es un par
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (!mounted) return;
        setState(() {
          card1.isFlipped = false;
          card2.isFlipped = false;
          _selectedIndices.clear();
          _canFlipCards = true;
        });
      });
    }
  }

  @override
  void dispose() {
    _isTimerRunning = false;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gridSize = _getGridSize();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Juego de Memoria'),
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
            value: _matchedPairs / _getPairCount(),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  childAspectRatio: 1,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  return MemoryCardWidget(
                    card: _cards[index],
                    onTap: () => _onCardTap(index),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Pares encontrados: $_matchedPairs/${_getPairCount()}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
    );
  }

  int _getGridSize() {
    switch (widget.difficulty) {
      case 'easy':
        return 3;  // 3x4 grid
      case 'medium':
        return 4;  // 4x6 grid
      case 'hard':
        return 6;  // 6x6 grid
      default:
        return 3;
    }
  }
}

class MemoryCard {
  final int value;
  bool isFlipped;
  bool isMatched;

  MemoryCard({
    required this.value,
    this.isFlipped = false,
    this.isMatched = false,
  });
}