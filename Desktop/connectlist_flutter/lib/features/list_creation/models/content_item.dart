class ContentItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String category;
  final Map<String, dynamic>? metadata;
  final String source;

  ContentItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    required this.category,
    this.metadata,
    this.source = 'manual',
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContentItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}