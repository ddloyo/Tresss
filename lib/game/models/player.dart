import 'package:equatable/equatable.dart';
import 'package:tresss/game/models/card.dart';

class Player extends Equatable {
  final String id;
  final String name;
  final bool isHost;
  final bool isBot;
  final List<GameCard> hand;
  final List<Trio> trios;
  final int wins;
  final int losses;
  final int gamesPlayed;

  const Player({
    required this.id,
    required this.name,
    this.isHost = false,
    this.isBot = false,
    this.hand = const [],
    this.trios = const [],
    this.wins = 0,
    this.losses = 0,
    this.gamesPlayed = 0,
  });

  Player copyWith({
    String? id,
    String? name,
    bool? isHost,
    bool? isBot,
    List<GameCard>? hand,
    List<Trio>? trios,
    int? wins,
    int? losses,
    int? gamesPlayed,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      isHost: isHost ?? this.isHost,
      isBot: isBot ?? this.isBot,
      hand: hand ?? this.hand,
      trios: trios ?? this.trios,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
    );
  }

  // Game logic getters
  bool get hasWon => trios.length >= 3 || trios.any((trio) => trio.isSevenTrio);
  int get handSize => hand.length;
  int get trioCount => trios.length;
  bool get hasSevenTrio => trios.any((trio) => trio.isSevenTrio);
  
  GameCard? get highestCard {
    if (hand.isEmpty) return null;
    return hand.reduce((a, b) => a.number > b.number ? a : b);
  }
  
  GameCard? get lowestCard {
    if (hand.isEmpty) return null;
    return hand.reduce((a, b) => a.number < b.number ? a : b);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isHost': isHost,
      'isBot': isBot,
      'hand': hand.map((card) => card.toJson()).toList(),
      'trios': trios.map((trio) => trio.toJson()).toList(),
      'wins': wins,
      'losses': losses,
      'gamesPlayed': gamesPlayed,
    };
  }

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id'] as String,
      name: json['name'] as String,
      isHost: json['isHost'] as bool? ?? false,
      isBot: json['isBot'] as bool? ?? false,
      hand: (json['hand'] as List?)
          ?.map((cardJson) => GameCard.fromJson(cardJson))
          .toList() ?? [],
      trios: (json['trios'] as List?)
          ?.map((trioJson) => Trio.fromJson(trioJson))
          .toList() ?? [],
      wins: json['wins'] as int? ?? 0,
      losses: json['losses'] as int? ?? 0,
      gamesPlayed: json['gamesPlayed'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, name, isHost, isBot, hand, trios, wins, losses, gamesPlayed];
} 