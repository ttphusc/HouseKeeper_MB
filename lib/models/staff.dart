class Staff {
  final int id;
  final String name;
  final String age;
  final String experience;
  final int rating;
  final String imageUrl;

  Staff({
    required this.id,
    required this.name,
    required this.age,
    required this.experience,
    required this.rating,
    required this.imageUrl,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    // Convert rating to int with default value 5
    int ratingValue = 5;
    if (json['tong_so_sao'] != null) {
      ratingValue = int.tryParse(json['tong_so_sao'].toString()) ?? 5;
      if (ratingValue <= 0) ratingValue = 5;
    }

    return Staff(
      id: json['id'] ?? 0,
      name: json['ho_va_ten'] ?? 'Tên nhân viên',
      age: json['tuoi_nhan_vien']?.toString() ?? '25',
      experience: json['kinh_nghiem'] ?? '1 năm',
      rating: ratingValue,
      imageUrl: json['hinh_anh'] ?? '',
    );
  }
}
