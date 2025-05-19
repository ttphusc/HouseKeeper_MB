import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/staff.dart';
import 'package:intl/intl.dart';

class StaffDetailScreen extends StatefulWidget {
  final int staffId;

  const StaffDetailScreen({Key? key, required this.staffId}) : super(key: key);

  @override
  State<StaffDetailScreen> createState() => _StaffDetailScreenState();
}

class _StaffDetailScreenState extends State<StaffDetailScreen> {
  final Dio _dio = Dio();
  bool _isLoading = true;
  bool _isFavorite = false;
  Map<String, dynamic> staffDetail = {};
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

      if (response.statusCode == 200) {
        setState(() {
          staffDetail = response.data['data'];
          _isLoading = false;
        });
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
        _generateCalendar();
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

  void _generateCalendar() {
    // This function would implement the calendar generation logic
    // Similar to the Vue.js implementation
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
        backgroundColor: Color(0xFF46DFB1),
        title: Text('Nhân viên nổi bật'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildStaffProfile(),
                    SizedBox(height: 20),
                    _buildAvailabilityCalendar(),
                    SizedBox(height: 20),
                    _buildBookButton(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStaffProfile() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              children: [
                // Badge position
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#1',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                // Favorite icon
                Positioned(
                  top: 0,
                  right: 0,
                  child: InkWell(
                    onTap: _toggleFavorite,
                    child: Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.grey,
                    ),
                  ),
                ),

                // Staff image
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF46DFB1),
                    child: CircleAvatar(
                      radius: 47,
                      backgroundImage: NetworkImage(
                        staffDetail['hinh_anh'] ??
                            'https://via.placeholder.com/100',
                      ),
                      onBackgroundImageError: (e, s) {
                        print('Error loading image: $e');
                      },
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            Text(
              staffDetail['ho_va_ten'] ?? 'Trần Minh Ngọc',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            // Rating stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 24,
                );
              }),
            ),

            SizedBox(height: 16),

            // Staff info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoItem(
                  Icons.calendar_today,
                  'Tuổi: ${staffDetail['tuoi_nhan_vien'] ?? '25'}',
                ),
                _buildInfoItem(
                  Icons.work,
                  'Kinh nghiệm: ${staffDetail['kinh_nghiem'] ?? '14 năm 6 tháng'}',
                ),
                InkWell(
                  onTap: () {
                    // Navigate to reviews
                  },
                  child: _buildInfoItem(
                    Icons.rate_review,
                    '$reviewCount đánh giá',
                    isLink: true,
                  ),
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
        Icon(icon, size: 20),
        SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            color: isLink ? Colors.blue : Colors.black87,
            fontSize: 14,
            fontWeight: isLink ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAvailabilityCalendar() {
    // Get the current date and the next 6 days
    final now = DateTime.now();
    final dates = List.generate(6, (index) {
      final day = now.add(Duration(days: index));
      return day;
    });

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lịch làm việc',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 180,
              child: availableDates.isEmpty
                  ? Center(child: Text('Không có lịch trống'))
                  : GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: dates.length,
                      itemBuilder: (context, index) {
                        final date = dates[index];
                        final dateStr = DateFormat('dd/MM').format(date);

                        // Find if we have availability for this date
                        final availability = availableDates.firstWhere(
                            (element) =>
                                element['ngayRanh'] ==
                                DateFormat('yyyy-MM-dd').format(date),
                            orElse: () => {'thoiGianRanh': []});

                        final timeSlots =
                            (availability['thoiGianRanh'] as List?) ?? [];

                        return Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF46DFB1).withOpacity(0.1),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(8),
                                    topRight: Radius.circular(8),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    dateStr,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  alignment: Alignment.center,
                                  child: timeSlots.isEmpty
                                      ? Text(
                                          'Không có lịch',
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        )
                                      : Text(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          // Navigate to booking screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookingScreen(staffId: widget.staffId),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
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

// Placeholder for BookingScreen
class BookingScreen extends StatelessWidget {
  final int staffId;

  const BookingScreen({Key? key, required this.staffId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đặt lịch'),
      ),
      body: Center(
        child: Text('Màn hình đặt lịch với nhân viên ID: $staffId'),
      ),
    );
  }
}
