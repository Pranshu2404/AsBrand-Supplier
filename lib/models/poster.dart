class Poster {
  final String id;
  final String imageUrl;
  final String? link;

  Poster({required this.id, required this.imageUrl, this.link});

  factory Poster.fromJson(Map<String, dynamic> json) {
    return Poster(
      id: json['_id'] ?? json['id'] ?? '',
      imageUrl: json['imageUrl'] ?? json['image'] ?? '',
      link: json['link'],
    );
  }
}
