class Review {
  final String id;
  final String productId;
  final int rating;
  final String? title;
  final String? comment;

  Review({required this.id, required this.productId, required this.rating, this.title, this.comment});

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? json['id'] ?? '',
      productId: json['productID'] ?? '',
      rating: json['rating'] ?? 0,
      title: json['title'],
      comment: json['comment'],
    );
  }
}

class ReviewStats {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution;

  ReviewStats({
    this.averageRating = 0,
    this.totalReviews = 0,
    this.distribution = const {},
  });

  factory ReviewStats.fromJson(Map<String, dynamic> json) {
    return ReviewStats(
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      totalReviews: json['totalReviews'] ?? 0,
    );
  }
}
