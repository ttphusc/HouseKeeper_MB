class Staff {
  final int id;
  final String name;
  final String? avatarUrl;
  final int age;
  final String experience;
  final int rating;
  final String address;

  Staff({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.age,
    required this.experience,
    required this.rating,
    required this.address,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] ?? 0,
      name: json['ho_va_ten'] ?? '',
      avatarUrl: json['hinh_anh'],
      age: int.tryParse(json['tuoi_nhan_vien']?.toString() ?? '0') ?? 0,
      experience: json['kinh_nghiem'] ?? '',
      rating: int.tryParse(json['tong_so_sao']?.toString() ?? '5') ?? 5,
      address: json['dia_chi'] ?? '',
    );
  }
}
