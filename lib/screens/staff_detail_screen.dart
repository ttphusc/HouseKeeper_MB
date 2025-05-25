import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/staff.dart';
import 'package:intl/intl.dart';
import 'booking_screen.dart';

class StaffDetailScreen extends StatefulWidget {
  final int staffId;

  const StaffDetailScreen({super.key, required this.staffId});

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  final Dio _dio = Dio();
  bool _isLoading = true;
  bool _isFavorite = false;
  Staff? staffDetail;
  List<dynamic> availableDates = [];
  int reviewCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStaffDetails();
    _loadStaffAvailability();
    _loadReviewCount();
  }

  Future<void> _loadStaffDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.get(
        'http://127.0.0.1:8000/api/nguoi-dung/get-Data-Chi-Tiet-Nhan-Vien/${widget.staffId}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        setState(() {
          staffDetail = Staff.fromJson(response.data['data']);
          _isLoading = false;
        });
        print('Loaded staff details: $staffDetail'); // Debug print
      }
    } catch (e) {
      print('Error loading staff details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStaffAvailability() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.get(
        'http://127.0.0.1:8000/api/nguoi-dung/lay-lich-lam-ranh-nv/${widget.staffId}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          availableDates = response.data['data'];
        });
      }
    } catch (e) {
      print('Error loading staff availability: $e');
    }
  }

  Future<void> _loadReviewCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      final response = await _dio.get(
        'http://127.0.0.1:8000/api/nguoi-dung/dem-danh-gia/${widget.staffId}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          reviewCount = response.data['data'];
        });
      }
    } catch (e) {
      print('Error loading review count: $e');
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF46DFB1),
        title: const Text('Chi tiết nhân viên'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : staffDetail == null
              ? const Center(child: Text('Không tìm thấy thông tin nhân viên'))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildStaffProfile(),
                      const SizedBox(height: 20),
                      _buildAvailabilityCalendar(),
                      const SizedBox(height: 20),
                      _buildBookButton(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStaffProfile() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: const Color(0xFF46DFB1),
                    child: CircleAvatar(
                      radius: 47,
                      backgroundImage: staffDetail?.avatarUrl != null
                          ? NetworkImage(staffDetail!.avatarUrl!)
                          : null,
                      child: staffDetail?.avatarUrl == null
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.grey,
                    ),
                    onPressed: _toggleFavorite,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              staffDetail?.name ?? '',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              staffDetail?.address ?? '',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  Icons.star_rate_rounded,
                  color: index < (staffDetail?.rating ?? 0)
                      ? const Color(0xFFFFC107)
                      : const Color(0xFFFFE082),
                  size: 24,
                );
              }),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem(
                  Icons.cake,
                  'Tuổi: ${staffDetail?.age ?? 0}',
                ),
                _buildInfoItem(
                  Icons.work,
                  'KN: ${staffDetail?.experience ?? ""}',
                ),
                _buildInfoItem(
                  Icons.star,
                  '$reviewCount đánh giá',
                  isLink: true,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text, {bool isLink = false}) {
    return Column(
      children: [
        Icon(icon, size: 24, color: isLink ? Colors.blue : Colors.grey),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: isLink ? Colors.blue : Colors.black87,
            fontWeight: isLink ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityCalendar() {
    final now = DateTime.now();
    final dates = List.generate(6, (index) {
      return now.add(Duration(days: index));
    });

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lịch làm việc',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final date = dates[index];
                final dateStr = DateFormat('dd/MM').format(date);
                final availability = availableDates.firstWhere(
                  (element) =>
                      element['ngayRanh'] ==
                      DateFormat('yyyy-MM-dd').format(date),
                  orElse: () => {'thoiGianRanh': []},
                );
                final timeSlots = (availability['thoiGianRanh'] as List?) ?? [];

                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF46DFB1).withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          dateStr,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: timeSlots.isEmpty
                              ? Text(
                                  'Không có lịch',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                )
                              : const Text(
                                  '08:00 - 21:00',
                                  style: TextStyle(
                                    color: Color(0xFF46DFB1),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingScreen(staffId: widget.staffId),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Đặt lịch với nhân viên',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
