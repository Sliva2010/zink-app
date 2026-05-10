import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Узел Mind Map.
class MindMapNode {
  MindMapNode({
    String? id,
    required this.label,
    this.children = const [],
  }) : id = id ?? _uuid.v4();

  final String id;
  final String label;
  final List<MindMapNode> children;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'children': children.map((c) => c.toJson()).toList(),
      };

  factory MindMapNode.fromJson(Map<dynamic, dynamic> json) {
    return MindMapNode(
      id: json['id'] as String?,
      label: json['label'] as String? ?? '',
      children: (json['children'] as List? ?? [])
          .map((c) => MindMapNode.fromJson(c as Map))
          .toList(),
    );
  }

  int get nodeCount =>
      1 + children.fold<int>(0, (sum, child) => sum + child.nodeCount);
}

class MindMap {
  MindMap({
    String? id,
    required this.title,
    required this.root,
    DateTime? createdAt,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  final String title;
  final MindMapNode root;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'root': root.toJson(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory MindMap.fromJson(Map<dynamic, dynamic> json) {
    return MindMap(
      id: json['id'] as String?,
      title: json['title'] as String? ?? '',
      root: MindMapNode.fromJson(json['root'] as Map),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
