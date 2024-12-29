import 'package:flutter/material.dart';

class GameSelectionScreen extends StatefulWidget {
  final String? selectedGame;
  final String? difficulty;

  const GameSelectionScreen({
    super.key,
    this.selectedGame,
    this.difficulty,
  });

  @override
  State<GameSelectionScreen> createState() => _GameSelectionScreenState();
}

class _GameSelectionScreenState extends State<GameSelectionScreen> {
  late String? _selectedGame;
  late String? _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _selectedGame = widget.selectedGame;
    _selectedDifficulty = widget.difficulty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar Juego'),
        actions: [
          TextButton(
            onPressed: _canSave()
                ? () => Navigator.pop(context, {
                      'game': _selectedGame,
                      'difficulty': _selectedDifficulty,
                    })
                : null,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Tipo de Juego',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildGameOptions(),
            if (_selectedGame != null) ...[
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Dificultad',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildDifficultyOptions(),
              const SizedBox(height: 16),
              _buildGamePreview(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGameOptions() {
    return Column(
      children: [
        _buildGameOption(
          'math',
          'Matemáticas',
          'Resuelve operaciones matemáticas',
          Icons.calculate,
        ),
        _buildGameOption(
          'memory',
          'Memoria',
          'Encuentra pares de cartas coincidentes',
          Icons.grid_view,
        ),
      ],
    );
  }

  Widget _buildGameOption(
    String gameId,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = _selectedGame == gameId;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedGame = gameId;
            _selectedDifficulty = null; // Resetear dificultad al cambiar de juego
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyOptions() {
    return Column(
      children: [
        _buildDifficultyOption(
          'easy',
          'Fácil',
          _getDifficultyDescription('easy'),
          Colors.green,
        ),
        _buildDifficultyOption(
          'medium',
          'Media',
          _getDifficultyDescription('medium'),
          Colors.orange,
        ),
        _buildDifficultyOption(
          'hard',
          'Difícil',
          _getDifficultyDescription('hard'),
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildDifficultyOption(
    String difficultyId,
    String title,
    String description,
    Color color,
  ) {
    final isSelected = _selectedDifficulty == difficultyId;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isSelected ? 4 : 1,
      color: isSelected ? theme.colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedDifficulty = difficultyId;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 16,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGamePreview() {
    if (_selectedGame == null || _selectedDifficulty == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vista Previa',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getGamePreviewTitle()),
                  const SizedBox(height: 8),
                  Text(_getGamePreviewDescription()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDifficultyDescription(String difficulty) {
    if (_selectedGame == 'math') {
      switch (difficulty) {
        case 'easy':
          return 'Sumas y restas simples (3 problemas)';
        case 'medium':
          return 'Multiplicaciones y divisiones (5 problemas)';
        case 'hard':
          return 'Operaciones combinadas (7 problemas)';
        default:
          return '';
      }
    } else if (_selectedGame == 'memory') {
      switch (difficulty) {
        case 'easy':
          return '6 pares de cartas';
        case 'medium':
          return '12 pares de cartas';
        case 'hard':
          return '18 pares de cartas';
        default:
          return '';
      }
    }
    return '';
  }

  String _getGamePreviewTitle() {
    if (_selectedGame == 'math') {
      return 'Juego de Matemáticas';
    } else {
      return 'Juego de Memoria';
    }
  }

  String _getGamePreviewDescription() {
    return _getDifficultyDescription(_selectedDifficulty!);
  }

  bool _canSave() {
    return _selectedGame != null && _selectedDifficulty != null;
  }
}