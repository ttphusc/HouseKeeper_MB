class Service {
  final int id;
  final String name;
  final String slug;
  final String? icon;
  final String? description;

  Service({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.description,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] ?? 0,
      name: json['ten_lua_chon'] ?? 'Dịch vụ',
      slug: json['slug_dich_vu'] ?? '',
      icon: json['icon_dich_vu'],
      description: json['mo_ta'],
    );
  }
}
