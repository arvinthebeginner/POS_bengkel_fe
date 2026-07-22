class Branch {
  const Branch({required this.id, required this.name, required this.lokasi});

  final String id;
  final String name;
  final String lokasi;

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['_id'] as String,
      name: json['name'] as String? ?? '-',
      lokasi: json['lokasi'] as String? ?? '-',
    );
  }
}
