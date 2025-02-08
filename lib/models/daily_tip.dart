class DailyTip {
  final String type;
  final String content;
  final String icon;

  DailyTip({
    required this.type,
    required this.content,
    required this.icon,
  });

  factory DailyTip.fromJson(Map<String, dynamic> json) {
    return DailyTip(
      type: json['type'] as String,
      content: json['content'] as String,
      icon: json['icon'] as String,
    );
  }
}

class DailyTipsData {
  final List<DailyTip> tips;

  DailyTipsData({required this.tips});

  factory DailyTipsData.fromJson(Map<String, dynamic> json) {
    return DailyTipsData(
      tips: (json['tips'] as List)
          .map((tip) => DailyTip.fromJson(tip as Map<String, dynamic>))
          .toList(),
    );
  }
}
