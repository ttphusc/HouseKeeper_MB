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
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: Text(
                        'Dịch vụ của chúng tôi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    _buildServicesList(),

                    // Featured staff
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: Text(
                        'Nhân viên nổi bật',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    _buildFeaturedStaffList(),
                    _buildViewAllButton(),

                    // Benefits section
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: Text(
                        'Tự tin với lựa chọn của bạn',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    _buildBenefitsList(),

                    // Service process
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: Text(
                        'Quy trình sử dụng dịch vụ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    _buildServiceSteps(),

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

    // Hardcoded services based on the image
    List<Map<String, dynamic>> serviceItems = [
      {
        'name': 'Thuê giúp việc theo giờ',
        'description': '→ Đặt dịch vụ ngay',
        'image': 'assets/images/Dichvu1.png',
        'icon': Icons.cleaning_services,
      },
      {
        'name': 'Thuê giúp việc định kỳ',
        'description': '→ Đặt dịch vụ ngay',
        'image': 'assets/images/Dichvu2.png',
        'icon': Icons.schedule,
      },
      {
        'name': 'Tổng vệ sinh',
        'description': '→ Đặt dịch vụ ngay',
        'image': 'assets/images/Dichvu3.png',
        'icon': Icons.home,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: serviceItems.length,
      itemBuilder: (context, index) {
        final service = serviceItems[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Row(
              children: [
                // Phần biểu tượng thay cho hình ảnh
                Expanded(
                  flex: 1,
                  child: Container(
                    color: Colors.grey.shade200,
                    child: Image.asset(
                      service['image'],
                      fit: BoxFit.cover,
                      height: 100,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        print('Lỗi tải hình: $error');
                        return Center(
                          child: Icon(
                            service['icon'],
                            color: const Color(0xFF46DFB1),
                            size: 36,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Mô tả dịch vụ
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      // Handle service tap based on name
                      if (service['name'] == 'Thuê giúp việc theo giờ') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const HourlyServiceScreen(serviceId: 1),
                          ),
                        );
                      } else if (service['name'] == 'Thuê giúp việc định kỳ') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const RecurringServiceScreen(serviceId: 2),
                          ),
                        );
                      } else if (service['name'] == 'Tổng vệ sinh') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const CleaningServiceScreen(serviceId: 3),
                          ),
                        );
                      }
                      // Can add other service types here
                    },
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFFE3F5F8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            service['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            service['description'],
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
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
        height: 220, // Increased height
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF46DFB1)),
        ),
      );
    }

    return Container(
      height: 220, // Increased height
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: featuredStaff.isEmpty
          ? const Center(child: Text("Không có nhân viên nổi bật"))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: featuredStaff.length,
              itemBuilder: (context, index) {
                final staff = featuredStaff[index];
                return Container(
                  width: 180, // Increased width
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F6F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 35, // Increased avatar size
                        backgroundColor: Colors.grey.shade200,
                        child: staff.avatarUrl != null &&
                                staff.avatarUrl!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(35),
                                child: Image.network(
                                  staff.avatarUrl!,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, size: 35),
                                ),
                              )
                            : const Icon(Icons.person, size: 35),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        staff.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.cake,
                              size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text(
                            'Tuổi: ${staff.age}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.work,
                              size: 14, color: Colors.black54),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              'KN: ${staff.experience}',
                              style: const TextStyle(fontSize: 14),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < staff.rating
                                ? Icons.star_rate_rounded
                                : Icons.star_rate_rounded,
                            color: index < staff.rating
                                ? const Color(0xFFFFC107)
                                : const Color(0xFFFFE082),
                            size: 20,
                          );
                        }),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    StaffDetailScreen(staffId: staff.id),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            minimumSize: const Size(double.infinity, 32),
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: const Text(
                            'XEM CHI TIẾT',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
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
        'icon': Icons.access_time,
        'color': Colors.blue[800],
        'bgColor': const Color(0xFF003366),
      },
      {
        'title': 'Giá cả minh bạch',
        'description':
            'Giá dịch vụ rõ ràng, được hiển thị minh bạch trên ứng dụng. Bạn không cần lo lắng về bất kỳ khoản phí ẩn nào.',
        'icon': Icons.monetization_on,
        'color': const Color(0xFFFFD700),
        'bgColor': const Color(0xFF003366),
      },
      {
        'title': 'Đa dạng dịch vụ',
        'description':
            'Chúng tôi cung cấp nhiều loại hình dịch vụ từ dọn dẹp nhà cửa, giặt giũ, đáp ứng mọi nhu cầu của gia đình bạn.',
        'icon': Icons.cleaning_services,
        'color': Colors.orange,
        'bgColor': const Color(0xFF003366),
      },
      {
        'title': 'An toàn và đáng tin cậy',
        'description':
            'Người giúp việc được duyệt kỹ càng với hồ sơ lý lịch rõ ràng. Đội ngũ giám sát đảm bảo quá trình làm việc diễn ra an toàn và hiệu quả.',
        'icon': Icons.verified_user,
        'color': Colors.green,
        'bgColor': const Color(0xFF003366),
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
            color: benefit['bgColor'],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    benefit['icon'],
                    size: 24,
                    color: benefit['color'],
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        benefit['description'],
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/badge-service.png',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.home_repair_service,
                size: 40,
                color: Color(0xFF46DFB1),
              );
            },
          ),
        ),
        'description':
            'Chúng tôi có nhiều dịch vụ tiến hành hỗ trợ bạn và đồng hành với bạn',
      },
      {
        'number': 2,
        'title': 'Chọn Thời Gian Và Vị Trí',
        'icon': Icons.place,
        'iconWidget': ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/vitri.png',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.place,
                size: 40,
                color: Color(0xFF46DFB1),
              );
            },
          ),
        ),
        'description':
            'Chúng tôi có nhiều dịch vụ tiến hành hỗ trợ bạn và đồng hành với bạn',
      },
      {
        'number': 3,
        'title': 'Lên Lịch Làm Việc',
        'icon': Icons.schedule,
        'iconWidget': ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/Qt02.jpg',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.schedule,
                size: 40,
                color: Color(0xFF46DFB1),
              );
            },
          ),
        ),
        'description':
            'Chúng tôi có nhiều dịch vụ tiến hành hỗ trợ bạn và đồng hành với bạn',
      },
      {
        'number': 4,
        'title': 'Đánh Giá Và Xếp Hạng',
        'icon': Icons.star_rate,
        'iconWidget': ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            'assets/images/Qt04.png',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(
                Icons.star_rate,
                size: 40,
                color: Color(0xFF46DFB1),
              );
            },
          ),
        ),
        'description':
            'Chúng tôi có nhiều dịch vụ tiến hành hỗ trợ bạn và đồng hành với bạn',
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF46DFB1),
                ),
                margin: const EdgeInsets.only(top: 16, bottom: 12),
                alignment: Alignment.center,
                child: Text(
                  '${step['number']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: step['iconWidget'],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                child: Text(
                  step['title'],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
