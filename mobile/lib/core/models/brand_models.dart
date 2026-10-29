class AssignedBrand {
  const AssignedBrand({
    required this.id,
    required this.code,
    required this.name,
  });

  final String id;
  final String code; // GC, AI, KK
  final String name;

  factory AssignedBrand.fromApiJson(Map<String, dynamic> json) {
    final id = json['brand_id'];
    final code = json['code'];
    final name = json['name'];
    if (id is! String || code is! String || name is! String) {
      throw const FormatException('Brand is missing required fields.');
    }
    return AssignedBrand(id: id, code: code.trim(), name: name.trim());
  }
}
