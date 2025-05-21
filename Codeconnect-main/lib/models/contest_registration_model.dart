class ContestRegistration {
  final String userId;
  final String contestId;
  final DateTime registeredAt;

  ContestRegistration({
    required this.userId,
    required this.contestId,
    required this.registeredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'contestId': contestId,
      'registeredAt': registeredAt.toIso8601String(),
    };
  }
}
