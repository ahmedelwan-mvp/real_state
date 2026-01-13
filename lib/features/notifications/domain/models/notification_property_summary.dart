class NotificationPropertySummary {
  final String title;
  final String? areaName;
  final String? purposeKey;
  final String? coverImageUrl;
  final double? price;
  final bool isMissing;

  const NotificationPropertySummary({
    required this.title,
    this.areaName,
    this.purposeKey,
    this.coverImageUrl,
    this.price,
    this.isMissing = false,
  });

  NotificationPropertySummary copyWith({
    String? title,
    String? areaName,
    String? purposeKey,
    String? coverImageUrl,
    double? price,
    bool? isMissing,
  }) {
    return NotificationPropertySummary(
      title: title ?? this.title,
      areaName: areaName ?? this.areaName,
      purposeKey: purposeKey ?? this.purposeKey,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      price: price ?? this.price,
      isMissing: isMissing ?? this.isMissing,
    );
  }
}
