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
}
