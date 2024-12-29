import 'dart:convert';
import '../utils/constants.dart';

enum GameType { math, memory }
enum GameDifficulty { easy, medium, hard }

class GameSettings {
  final GameType gameType;
  GameDifficulty difficulty;
  int problemCount;
  int timeLimit; // en segundos
  bool isTimeLimited;
  Map<String, dynamic> specificSettings;
  
  // Constructor
  GameSettings({
    required this.gameType,
    this.difficulty = GameDifficulty.easy,
    this.problemCount = 3,
    this.timeLimit = 60,
    this.isTimeLimited = false,
    Map<String, dynamic>? specificSettings,
  }) : specificSettings = specificSettings ?? _getDefaultSpecificSettings(gameType);

  // Configuraciones específicas por defecto según el tipo de juego
  static Map<String, dynamic> _getDefaultSpecificSettings(GameType type) {
    switch (type) {
      case GameType.math:
        return {
          'operationTypes': ['addition', 'subtraction'], // multiplication, division
          'maxNumber': 10,
          'allowNegatives': false,
          'requireWholeNumbers': true,
        };
      case GameType.memory:
        return {
          'useTriples': false,
          'showTimer': true,
          'cardTheme': 'numbers', // numbers, symbols, colors
          'matchTime': 1000, // tiempo en ms para mostrar las cartas al hacer match
        };
    }
  }

  // Obtener cantidad de problemas según dificultad
  int getProblemCount() {
    switch (gameType) {
      case GameType.math:
        switch (difficulty) {
          case GameDifficulty.easy:
            return AppConstants.mathGameEasyProblems;
          case GameDifficulty.medium:
            return AppConstants.mathGameMediumProblems;
          case GameDifficulty.hard:
            return AppConstants.mathGameHardProblems;
        }
      case GameType.memory:
        switch (difficulty) {
          case GameDifficulty.easy:
            return AppConstants.memoryGameEasyPairs;
          case GameDifficulty.medium:
            return AppConstants.memoryGameMediumPairs;
          case GameDifficulty.hard:
            return AppConstants.memoryGameHardPairs;
        }
    }
  }

  // Obtener tiempo límite según dificultad (en segundos)
  int getTimeLimit() {
    if (!isTimeLimited) return 0;
    
    switch (difficulty) {
      case GameDifficulty.easy:
        return 120; // 2 minutos
      case GameDifficulty.medium:
        return 90; // 1.5 minutos
      case GameDifficulty.hard:
        return 60; // 1 minuto
    }
  }

  // Métodos específicos para juego matemático
  int getMathMaxNumber() {
    if (gameType != GameType.math) return 0;
    
    switch (difficulty) {
      case GameDifficulty.easy:
        return 10;
      case GameDifficulty.medium:
        return 25;
      case GameDifficulty.hard:
        return 100;
    }
  }

  List<String> getMathOperations() {
    if (gameType != GameType.math) return [];
    
    switch (difficulty) {
      case GameDifficulty.easy:
        return ['addition', 'subtraction'];
      case GameDifficulty.medium:
        return ['addition', 'subtraction', 'multiplication'];
      case GameDifficulty.hard:
        return ['addition', 'subtraction', 'multiplication', 'division'];
    }
  }

  // Métodos específicos para juego de memoria
  int getMemoryPairCount() {
    if (gameType != GameType.memory) return 0;
    
    return getProblemCount();
  }

  bool useTriples() {
    if (gameType != GameType.memory) return false;
    return difficulty == GameDifficulty.hard && specificSettings['useTriples'] as bool;
  }

  // Serialización
  Map<String, dynamic> toJson() {
    return {
      'gameType': gameType.toString(),
      'difficulty': difficulty.toString(),
      'problemCount': problemCount,
      'timeLimit': timeLimit,
      'isTimeLimited': isTimeLimited,
      'specificSettings': specificSettings,
    };
  }

  // Deserialización
  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      gameType: GameType.values.firstWhere(
        (e) => e.toString() == json['gameType'],
      ),
      difficulty: GameDifficulty.values.firstWhere(
        (e) => e.toString() == json['difficulty'],
      ),
      problemCount: json['problemCount'],
      timeLimit: json['timeLimit'],
      isTimeLimited: json['isTimeLimited'],
      specificSettings: Map<String, dynamic>.from(json['specificSettings']),
    );
  }

  // Convertir a String
  String toJsonString() => jsonEncode(toJson());

  // Crear desde String
  factory GameSettings.fromJsonString(String jsonString) {
    return GameSettings.fromJson(jsonDecode(jsonString));
  }

  // Copiar con modificaciones
  GameSettings copyWith({
    GameDifficulty? difficulty,
    int? problemCount,
    int? timeLimit,
    bool? isTimeLimited,
    Map<String, dynamic>? specificSettings,
  }) {
    return GameSettings(
      gameType: gameType,
      difficulty: difficulty ?? this.difficulty,
      problemCount: problemCount ?? this.problemCount,
      timeLimit: timeLimit ?? this.timeLimit,
      isTimeLimited: isTimeLimited ?? this.isTimeLimited,
      specificSettings: specificSettings ?? Map.from(this.specificSettings),
    );
  }

  // Validar configuración
  bool isValid() {
    if (problemCount <= 0) return false;
    if (isTimeLimited && timeLimit <= 0) return false;
    
    switch (gameType) {
      case GameType.math:
        return specificSettings.containsKey('operationTypes') &&
               (specificSettings['operationTypes'] as List).isNotEmpty &&
               specificSettings.containsKey('maxNumber') &&
               (specificSettings['maxNumber'] as int) > 0;
      
      case GameType.memory:
        return specificSettings.containsKey('cardTheme') &&
               specificSettings.containsKey('matchTime') &&
               (specificSettings['matchTime'] as int) > 0;
    }
  }

  // Crear configuración predeterminada para un tipo de juego
  factory GameSettings.createDefault(GameType type) {
    return GameSettings(
      gameType: type,
      difficulty: GameDifficulty.easy,
      specificSettings: _getDefaultSpecificSettings(type),
    );
  }
}