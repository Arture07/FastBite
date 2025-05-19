// lib/model/review.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;          // ID do documento da review no Firestore (pode ser o userId)
  final String userId;      // ID do utilizador que fez a review
  final String userName;    // Nome do utilizador
  final String? userImagePath; // <<< CAMPO ADICIONADO/CONFIRMADO
  final double rating;      // Nota em estrelas (ex: 4.5)
  final String? comment;    // Comentário em texto (opcional)
  final DateTime timestamp; // Data e hora da review

  final String? replyText;
  final DateTime? replyTimestamp;

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    this.userImagePath, // <<< ADICIONADO AO CONSTRUTOR
    required this.rating,
    this.comment,
    required this.timestamp,
    this.replyText,
    this.replyTimestamp,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'userImagePath': userImagePath, // <<< ADICIONADO AO JSON
    'rating': rating,
    'comment': comment,
    'timestamp': Timestamp.fromDate(timestamp),
    'replyText': replyText,
    'replyTimestamp': replyTimestamp != null ? Timestamp.fromDate(replyTimestamp!) : null,
  };

  factory Review.fromJson(String docId, Map<String, dynamic> json) {
    DateTime reviewTime;
    if (json['timestamp'] is Timestamp) {
      reviewTime = (json['timestamp'] as Timestamp).toDate();
    } else if (json['timestamp'] is String) {
      reviewTime = DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now();
    } else {
      reviewTime = DateTime.now(); 
    }

    DateTime? replyTime;
    if (json['replyTimestamp'] is Timestamp) {
      replyTime = (json['replyTimestamp'] as Timestamp).toDate();
    } else if (json['replyTimestamp'] is String) {
      replyTime = DateTime.tryParse(json['replyTimestamp'] as String);
    }

    return Review(
      id: docId,
      userId: json['userId']?.toString() ?? 'unknown_user',
      userName: json['userName']?.toString() ?? 'Anónimo',
      userImagePath: json['userImagePath']?.toString(), // <<< LIDO DO JSON
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment']?.toString(),
      timestamp: reviewTime,
      replyText: json['replyText']?.toString(),
      replyTimestamp: replyTime,
    );
  }
}
