import 'content_item.dart';

enum ListPrivacy { public, private, unlisted }

class ListModel {
  final String? id;
  final String title;
  final String description;
  final String category;
  final List<ContentItem> items;
  final ListPrivacy privacy;
  final bool allowComments;
  final bool allowCollaboration;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ListModel({
    this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.items,
    this.privacy = ListPrivacy.public,
    this.allowComments = true,
    this.allowCollaboration = false,
    this.createdAt,
    this.updatedAt,
  });

  ListModel copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    List<ContentItem>? items,
    ListPrivacy? privacy,
    bool? allowComments,
    bool? allowCollaboration,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ListModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      items: items ?? this.items,
      privacy: privacy ?? this.privacy,
      allowComments: allowComments ?? this.allowComments,
      allowCollaboration: allowCollaboration ?? this.allowCollaboration,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}