import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;          // ID do documento da review
  final String userId;      // ID do utilizador que fez a review
  final String userName;    // Nome do utilizador (para exibição)
  final double rating;      // Nota em estrelas (ex: 4.5)
  final String? comment;    // Comentário em texto (opcional)
  final DateTime timestamp; // Data e hora da review

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    this.comment,
    required this.timestamp,
  });

  // Converte para JSON para salvar no Firestore
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'rating': rating,
    'comment': comment,
    'timestamp': Timestamp.fromDate(timestamp), // Converte DateTime para Timestamp
  };

  // Cria a partir do JSON lido do Firestore
  factory Review.fromJson(String id, Map<String, dynamic> json) {
    DateTime reviewTime;
    if (json['timestamp'] is Timestamp) {
      reviewTime = (json['timestamp'] as Timestamp).toDate();
    } else if (json['timestamp'] is String) {
      reviewTime = DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now();
    } else {
      reviewTime = DateTime.now(); // Fallback
    }

    return Review(
      id: id,
      userId: json['userId']?.toString() ?? 'unknown_user',
      userName: json['userName']?.toString() ?? 'Anónimo',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment']?.toString(),
      timestamp: reviewTime,
    );
  }

  // copyWith para facilitar atualizações
   Review copyWith({
    String? id,
    String? userId,
    String? userName,
    double? rating,
    String? comment, // Nullable para permitir remoção de comentário
    DateTime? timestamp,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}