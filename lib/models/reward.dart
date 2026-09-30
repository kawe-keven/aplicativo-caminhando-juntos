enum RewardCategory { all, popular, vouchers }

class Reward {
  final String id;
  final String title;
  final String description;
  final int cost;
  final String imageUrl;
  final RewardCategory category;
  final String? tag;

  Reward({
    required this.id,
    required this.title,
    required this.description,
    required this.cost,
    required this.imageUrl,
    required this.category,
    this.tag,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'cost': cost,
        'imageUrl': imageUrl,
        'category': category.name,
        'tag': tag,
      };

  factory Reward.fromJson(Map<String, dynamic> json) {
    RewardCategory cat = RewardCategory.popular;
    final catStr = json['category'] as String?;
    if (catStr != null) {
      if (catStr == 'vouchers') cat = RewardCategory.vouchers;
      else if (catStr == 'all') cat = RewardCategory.all;
    }

    return Reward(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      cost: json['cost'] as int? ?? 0,
      imageUrl: json['imageUrl'] as String? ?? '',
      category: cat,
      tag: json['tag'] as String?,
    );
  }
}
