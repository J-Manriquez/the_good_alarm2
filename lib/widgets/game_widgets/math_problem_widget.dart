import 'package:flutter/material.dart';
import '../../screens/games/math_game_screen.dart';

class MathProblemWidget extends StatelessWidget {
  final MathProblem problem;
  final double fontSize;

  const MathProblemWidget({
    super.key,
    required this.problem,
    this.fontSize = 48,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            problem.num1.toString(),
            style: TextStyle(fontSize: fontSize),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _getOperationSymbol(problem.operation),
              style: TextStyle(fontSize: fontSize),
            ),
          ),
          Text(
            problem.num2.toString(),
            style: TextStyle(fontSize: fontSize),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '=',
              style: TextStyle(fontSize: fontSize),
            ),
          ),
          Text(
            '?',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  String _getOperationSymbol(String operation) {
    switch (operation) {
      case '+':
        return '+';
      case '-':
        return '−';
      case '*':
        return '×';
      case '/':
        return '÷';
      default:
        return operation;
    }
  }
}