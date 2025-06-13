import 'package:equatable/equatable.dart';

class GameCard extends Equatable {
  final int number;
  final String id;
  final bool isRevealed;
  final bool isInHand;

  const GameCard({
    required this.number,
    required this.id,
    this.isRevealed = false,
    this.isInHand = false,
  });

  GameCard copyWith({
    int? number,
    String? id,
    bool? isRevealed,
    bool? isInHand,
  }) {
    return GameCard(
      number: number ?? this.number,
      id: id ?? this.id,
      isRevealed: isRevealed ?? this.isRevealed,
      isInHand: isInHand ?? this.isInHand,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'id': id,
      'isRevealed': isRevealed,
      'isInHand': isInHand,
    };
  }

  factory GameCard.fromJson(Map<String, dynamic> json) {
    return GameCard(
      number: json['number'] as int,
      id: json['id'] as String,
      isRevealed: json['isRevealed'] as bool? ?? false,
      isInHand: json['isInHand'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [number, id, isRevealed, isInHand];
}

class Trio extends Equatable {
  final List<GameCard> cards;
  final String playerId;

  const Trio({
    required this.cards,
    required this.playerId,
  });

  bool get isValid => cards.length == 3 && cards.every((card) => card.number == cards.first.number);
  bool get isSevenTrio => isValid && cards.first.number == 7;
  int get number => cards.first.number;

  Map<String, dynamic> toJson() {
    return {
      'cards': cards.map((card) => card.toJson()).toList(),
      'playerId': playerId,
    };
  }

  factory Trio.fromJson(Map<String, dynamic> json) {
    return Trio(
      cards: (json['cards'] as List)
          .map((cardJson) => GameCard.fromJson(cardJson))
          .toList(),
      playerId: json['playerId'] as String,
    );
  }

  @override
  List<Object?> get props => [cards, playerId];
} 