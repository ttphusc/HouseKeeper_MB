import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../services/api_service.dart';
import 'staff_detail_screen.dart';
import 'hourly_service_screen.dart';
import 'recurring_service_screen.dart';
import 'cleaning_service_screen.dart';
import 'notification_screen.dart';
import 'order_history_screen.dart';
import 'profile_screen.dart';
import '../models/staff.dart';
import 'support_screen.dart';
import 'wallet_screen.dart';
import 'chatbot_screen.dart';
import 'transaction_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Dio _dio = Dio();
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  String? _userName;
  int _unreadNotifications = 0;

  // Banner slider
  final List<String> _bannerImages = [
    'assets/images/banner1.jpg',
    'assets/images/banner2.jpg',
    'assets/images/banner3.jpg',
  ];
  int _currentBannerIndex = 0;

  // Featured staff
  List<Staff> featuredStaff = [];

  // Service categories
  final List<Map<String, dynamic>> _serviceCategories = [
    {
      'id': 1,
      'name': 'Giúp việc theo giờ',
      'icon': Icons.access_time,
      'description': 'Dịch vụ giúp việc theo giờ linh hoạt',
      'color': Colors.blue,
    },
    {
      'id': 2,
      'name': 'Giúp việc định kỳ',
      'icon': Icons.calendar_month,
      'description': 'Dịch vụ giúp việc theo lịch định kỳ',
      'color': Colors.orange,
    },
    {
      'id': 3,
      'name': 'Tổng vệ sinh',
      'icon': Icons.cleaning_services,
      'description': 'Dịch vụ vệ sinh toàn diện',
      'color': Colors.green,
    },
  ];

  // Testimonials
  final List<Map<String, dynamic>> _testimonials = [
    {
      'name': 'Nguyễn Văn A',
      'rating': 5,
      'comment': 'Dịch vụ rất tốt, nhân viên chuyên nghiệp và thân thiện.',
      'date': '2023-05-15',
    },
    {
      'name': 'Trần Thị B',
      'rating': 4,
      'comment': 'Tôi rất hài lòng với dịch vụ, nhà sạch sẽ và gọn gàng.',
      'date': '2023-06-20',
    },
    {
      'name': 'Lê Văn C',
      'rating': 5,
      'comment': 'Nhân viên làm việc rất tận tâm, sẽ tiếp tục sử dụng dịch vụ.',
      'date': '2023-07-10',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadData();
    _checkUnreadNotifications();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');
      final name = prefs.getString('ten_nguoi_dung');

      setState(() {
        _userName = name;
      });

      if (token == null) {
        // Handle not logged in state if needed
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final serviceList = await _apiService.getServices();
      final staffList = await _apiService.getFeaturedStaff();

      setState(() {
        featuredStaff = staffList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Không thể tải dữ liệu. Vui lòng thử lại sau.";
        _isLoading = false;
      });
      print("Error loading data: $e");
    }
  }

  Future<void> _checkUnreadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      if (token == null) return;

      final response = await _dio.get(
        'http://127.0.0.1:8000/api/nguoi-dung/thong-bao/dem-thong-bao-chua-doc',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['status'] == true) {
        setState(() {
          _unreadNotifications = response.data['data'] ?? 0;
        });
      }
    } catch (e) {
      print('Error checking unread notifications: $e');
    }
  }

  void _navigateToService(int serviceId) {
    switch (serviceId) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const HourlyServiceScreen(serviceId: 1)),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const RecurringServiceScreen(serviceId: 2)),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const CleaningServiceScreen(serviceId: 3)),
        );
        break;
    }
  }

  void _viewStaffDetails(int staffId) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => StaffDetailScreen(staffId: staffId)),
    );
  }

  void _navigateToNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    ).then((_) {
      // Refresh notification count when coming back
      _checkUnreadNotifications();
    });
  }

  void _navigateToOrderHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
    );
  }

  void _navigateToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    ).then((_) {
      // Refresh user data when coming back
      _loadUserData();
    });
  }

  void _navigateToSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupportScreen()),
    );
  }

  void _navigateToWallet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WalletScreen()),
    );
  }

  void _navigateToTransactionHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TransactionHistoryScreen()),
    );
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF46DFB1),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(
                Icons.menu,
                size: 32,
                color: Colors.white,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        title: const Text(''),
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications,
                  size: 32,
                  color: Colors.white,
                ),
                onPressed: _navigateToNotifications,
                padding: const EdgeInsets.all(8),
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      _unreadNotifications > 9
                          ? '9+'
                          : _unreadNotifications.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(),
      body: _errorMessage != null
          ? _buildErrorView()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF46DFB1),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with wave background
                    _buildHeader(),

                    // Our services
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF46DFB1), Color(0xFF2BB594)],
                        ).createShader(bounds),
                        child: const Text(
                          'Dịch vụ của chúng tôi',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    _buildServicesList(),

                    // Featured staff
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF46DFB1), Color(0xFF2BB594)],
                        ).createShader(bounds),
                        child: const Text(
                          'Nhân viên nổi bật',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    _buildFeaturedStaffList(),
                    _buildViewAllButton(),

                    // Benefits section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF46DFB1), Color(0xFF2BB594)],
                        ).createShader(bounds),
                        child: const Text(
                          'Tự tin với lựa chọn của bạn',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    _buildBenefitsList(),

                    // Service process
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF46DFB1), Color(0xFF2BB594)],
                        ).createShader(bounds),
                        child: const Text(
                          'Quy trình sử dụng dịch vụ',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    _buildServiceSteps(),

                    // Add the new introduction section at the bottom
                    _buildIntroductionSection(),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF46DFB1),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        currentIndex: _currentBannerIndex,
        onTap: (index) {
          setState(() {
            _currentBannerIndex = index;
          });

          // Handle navigation based on index
          switch (index) {
            case 0: // Home
              break;
            case 1: // Orders
              _navigateToOrderHistory();
              break;
            case 2: // Messages
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ChatbotScreen()),
              );
              break;
            case 3: // Profile
              _navigateToProfile();
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Đơn hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chatbot',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? "Đã xảy ra lỗi",
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: const Text("Thử lại"),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        ClipPath(
          clipper: WaveClipper(),
          child: Container(
            height: 180,
            color: const Color(0xFF46DFB1),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'House Keeper',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow[100],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'DỊCH VỤ GIÚP VIỆC SỐ 1 VIỆT NAM',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 20,
          child: Icon(
            Icons.star,
            color: Colors.white.withOpacity(0.3),
            size: 24,
          ),
        ),
        Positioned(
          bottom: 40,
          right: 20,
          child: Icon(
            Icons.star,
            color: Colors.white.withOpacity(0.3),
            size: 24,
          ),
        ),
        Positioned(
          top: 80,
          right: 40,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 60,
          left: 50,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesList() {
    if (_isLoading) {
      return const SizedBox(
        height: 340,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF46DFB1)),
        ),
      );
    }

    List<Map<String, dynamic>> serviceItems = [
      {
        'name': 'Thuê giúp việc theo giờ',
        'description': 'Linh hoạt theo nhu cầu của bạn',
        'image': 'assets/images/Dichvu1.png',
        'icon': Icons.access_time,
        'color': const Color(0xFF4A90E2),
        'route': const HourlyServiceScreen(serviceId: 1),
      },
      {
        'name': 'Thuê giúp việc định kỳ',
        'description': 'Dịch vụ ổn định, lâu dài',
        'image': 'assets/images/Dichvu2.png',
        'icon': Icons.calendar_today,
        'color': const Color(0xFFF5A623),
        'route': const RecurringServiceScreen(serviceId: 2),
      },
      {
        'name': 'Tổng vệ sinh',
        'description': 'Dọn dẹp toàn diện, chuyên nghiệp',
        'image': 'assets/images/Dichvu3.png',
        'icon': Icons.cleaning_services,
        'color': const Color(0xFF7ED321),
        'route': const CleaningServiceScreen(serviceId: 3),
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: serviceItems.length,
      itemBuilder: (context, index) {
        final service = serviceItems[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => service['route']),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    // Service Image/Icon Container
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: service['color'].withOpacity(0.1),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child: Image.asset(
                          service['image'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              service['icon'],
                              size: 40,
                              color: service['color'],
                            );
                          },
                        ),
                      ),
                    ),
                    // Service Details
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['name'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              service['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: service['color'],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_forward,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Đặt ngay',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Service Icon Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: service['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      service['icon'],
                      color: service['color'],
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedStaffList() {
    if (_isLoading) {
      return const SizedBox(
        height: 280,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF46DFB1)),
        ),
      );
    }

    return Container(
      height: 280,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: featuredStaff.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    "Chưa có nhân viên nổi bật",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: featuredStaff.length,
              itemBuilder: (context, index) {
                final staff = featuredStaff[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            StaffDetailScreen(staffId: staff.id),
                      ),
                    );
                  },
                  child: Container(
                    width: 200,
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Avatar Section with Gradient Background
                        Container(
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF46DFB1), Color(0xFF2BB594)],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 45,
                                backgroundColor: Colors.grey[200],
                                child: staff.avatarUrl != null &&
                                        staff.avatarUrl!.isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(45),
                                        child: Image.network(
                                          staff.avatarUrl!,
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) =>
                                                  const Icon(Icons.person,
                                                      size: 45,
                                                      color: Colors.grey),
                                        ),
                                      )
                                    : const Icon(Icons.person,
                                        size: 45, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                        // Staff Info Section
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Name and Rating
                                Column(
                                  children: [
                                    Text(
                                      staff.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(5, (index) {
                                        return Icon(
                                          index < staff.rating
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          color: index < staff.rating
                                              ? const Color(0xFFFFD700)
                                              : Colors.grey[300],
                                          size: 18,
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                // Info Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildInfoChip(
                                      Icons.person_outline_rounded,
                                      '${staff.age} tuổi',
                                    ),
                                    Container(
                                      width: 1,
                                      height: 20,
                                      color: Colors.grey[300],
                                    ),
                                    _buildInfoChip(
                                      Icons.work_outline_rounded,
                                      staff.experience,
                                    ),
                                  ],
                                ),
                                // View Details Button
                                Container(
                                  width: double.infinity,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF46DFB1),
                                        Color(0xFF2BB594)
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'XEM CHI TIẾT',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildViewAllButton() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Xem tất cả',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_right,
              color: Colors.black54,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsList() {
    List<Map<String, dynamic>> benefits = [
      {
        'title': 'Đặt lịch linh hoạt',
        'description':
            'Thao tác dễ dàng, chỉ cần vài phút trên ứng dụng, bạn có thể đặt người giúp việc theo nhu cầu với thời gian linh hoạt nhất.',
        'icon': Icons.access_time_filled,
        'color': const Color(0xFF4A90E2),
        'gradientColors': [Color(0xFF4A90E2), Color(0xFF357ABD)],
      },
      {
        'title': 'Giá cả minh bạch',
        'description':
            'Giá dịch vụ rõ ràng, được hiển thị minh bạch trên ứng dụng. Bạn không cần lo lắng về bất kỳ khoản phí ẩn nào.',
        'icon': Icons.payments_rounded,
        'color': const Color(0xFFFFB800),
        'gradientColors': [Color(0xFFFFB800), Color(0xFFFF9500)],
      },
      {
        'title': 'Đa dạng dịch vụ',
        'description':
            'Chúng tôi cung cấp nhiều loại hình dịch vụ từ dọn dẹp nhà cửa, giặt giũ, đáp ứng mọi nhu cầu của gia đình bạn.',
        'icon': Icons.cleaning_services_rounded,
        'color': const Color(0xFF46DFB1),
        'gradientColors': [Color(0xFF46DFB1), Color(0xFF2BB594)],
      },
      {
        'title': 'An toàn và đáng tin cậy',
        'description':
            'Người giúp việc được duyệt kỹ càng với hồ sơ lý lịch rõ ràng. Đội ngũ giám sát đảm bảo quá trình làm việc diễn ra an toàn và hiệu quả.',
        'icon': Icons.verified_user_rounded,
        'color': const Color(0xFF2ECC71),
        'gradientColors': [Color(0xFF2ECC71), Color(0xFF27AE60)],
      },
    ];

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: benefits.length,
      itemBuilder: (context, index) {
        final benefit = benefits[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: benefit['gradientColors'],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: benefit['color'].withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        benefit['icon'],
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            benefit['title'],
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            benefit['description'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceSteps() {
    List<Map<String, dynamic>> steps = [
      {
        'number': 1,
        'title': 'Chọn Dịch Vụ',
        'icon': Icons.home_repair_service,
        'iconWidget': ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/badge-service.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9966), Color(0xFFFF5E62)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.home_repair_service,
                  size: 40,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
        'color': const Color(0xFFFF9966),
      },
      {
        'number': 2,
        'title': 'Chọn Thời Gian Và Vị Trí',
        'icon': Icons.place,
        'iconWidget': ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/vitri.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF2BAF9A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.place,
                  size: 40,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
        'color': const Color(0xFF4ECDC4),
      },
      {
        'number': 3,
        'title': 'Lên Lịch Làm Việc',
        'icon': Icons.schedule,
        'iconWidget': ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/Qt02.jpg',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFC371), Color(0xFFFF5F6D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.schedule,
                  size: 40,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
        'color': const Color(0xFFFFC371),
      },
      {
        'number': 4,
        'title': 'Đánh Giá Và Xếp Hạng',
        'icon': Icons.star_rate,
        'iconWidget': ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/images/Qt04.png',
            width: 80,
            height: 80,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.star_rate,
                  size: 40,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
        'color': const Color(0xFF56CCF2),
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: step['color'].withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: step['color'],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${step['number']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 8),
                      step['iconWidget'],
                      const SizedBox(height: 16),
                      Text(
                        step['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntroductionSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      color: Colors.white,
      child: Column(
        children: [
          // About Us Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF46DFB1), Color(0xFF2BB594)],
                    ).createShader(bounds),
                    child: const Text(
                      'Về Chúng Tôi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF46DFB1), Color(0xFF2BB594)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Text(
                        'House Keeper',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Thành lập năm 2025, Dịch Vụ Giúp Việc HouseKeeper hoạt động trong lĩnh vực cung cấp dịch vụ hỗ trợ gia đình như giúp việc nhà, nấu ăn, chăm sóc trẻ nhỏ...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Core Values Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF46DFB1), Color(0xFF2BB594)],
                    ).createShader(bounds),
                    child: const Text(
                      'Giá Trị Cốt Lõi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildCoreValueCard(
                      Icons.favorite,
                      'Tận Tâm',
                      'Luôn đặt lợi ích của khách hàng lên hàng đầu',
                      const Color(0xFFFF6B6B),
                    ),
                    _buildCoreValueCard(
                      Icons.people,
                      'Tôn Trọng',
                      'Tôn trọng khách hàng, đồng nghiệp và chính mình',
                      const Color(0xFF4ECDC4),
                    ),
                    _buildCoreValueCard(
                      Icons.lightbulb,
                      'Đổi Mới',
                      'Không ngừng cải tiến để phục vụ tốt hơn mỗi ngày',
                      const Color(0xFFFFBE0B),
                    ),
                    _buildCoreValueCard(
                      Icons.shield,
                      'Trách Nhiệm',
                      'Cam kết với chất lượng dịch vụ và đạo đức nghề nghiệp',
                      const Color(0xFF3A86FF),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Contact Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF46DFB1).withOpacity(0.1),
            ),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF46DFB1), Color(0xFF2BB594)],
                    ).createShader(bounds),
                    child: const Text(
                      'Liên Hệ Với Chúng Tôi',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 32,
                  runSpacing: 16,
                  children: [
                    _buildContactInfo(
                      Icons.location_on,
                      '123 Đường Chính, Đà Nẵng',
                    ),
                    _buildContactInfo(
                      Icons.phone,
                      '+84 123 456 789',
                    ),
                    _buildContactInfo(
                      Icons.email,
                      'hotro@housekeeper.com',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreValueCard(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: color,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: const Color(0xFF46DFB1),
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20),
              color: const Color(0xFF46DFB1),
              width: double.infinity,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0),
                        child: Image.asset(
                          'assets/images/logo.png',
                          width: 50,
                          height: 50,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.home,
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'House Keeper',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    icon: Icons.home,
                    title: 'Trang chủ',
                    onTap: () {
                      Navigator.pop(context);
                    },
                    isSelected: true,
                  ),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'Thông tin cá nhân',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToProfile();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.history,
                    title: 'Lịch sử đơn dịch vụ',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToOrderHistory();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.payment,
                    title: 'Lịch sử giao dịch',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToTransactionHistory();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.notifications,
                    title: 'Thông báo',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToNotifications();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline,
                    title: 'Hỗ trợ',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToSupport();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.account_balance_wallet,
                    title: 'Ví điện tử',
                    onTap: () {
                      Navigator.pop(context);
                      _navigateToWallet();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF46DFB1).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF46DFB1) : Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? const Color(0xFF46DFB1) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

// Custom clipper for the wave effect
class WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);

    var firstControlPoint = Offset(size.width / 4, size.height);
    var firstEndPoint = Offset(size.width / 2, size.height - 20);
    path.quadraticBezierTo(firstControlPoint.dx, firstControlPoint.dy,
        firstEndPoint.dx, firstEndPoint.dy);

    var secondControlPoint = Offset(size.width * 3 / 4, size.height - 40);
    var secondEndPoint = Offset(size.width, size.height - 10);
    path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
        secondEndPoint.dx, secondEndPoint.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
