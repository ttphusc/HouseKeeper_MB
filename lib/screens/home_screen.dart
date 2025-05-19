import 'package:flutter/material.dart';
import '../models/service.dart';
import '../models/staff.dart';
import '../services/api_service.dart';
import '../widgets/image_carousel.dart';
import 'staff_detail_screen.dart';
import 'hourly_service_screen.dart';
import 'recurring_service_screen.dart';
import 'cleaning_service_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();

  List<Service> services = [];
  List<Staff> featuredStaff = [];
  int _currentBannerIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
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
        services = serviceList;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF46DFB1),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.chat_outlined, color: Colors.white),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundImage:
                  AssetImage('lib/assets/images/avatars/avatar-1.png'),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(top: 50, bottom: 20),
                color: Color(0xFF46DFB1),
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
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.home,
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Text(
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
                        // TODO: Navigate to profile page
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.history,
                      title: 'Lịch sử đơn dịch vụ',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to order history page
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.notifications,
                      title: 'Thông báo',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to notifications page
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.help_outline,
                      title: 'Hỗ trợ',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to support page
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.account_balance_wallet,
                      title: 'Ví điện tử',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to wallet page
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: _errorMessage != null
          ? _buildErrorView()
          : RefreshIndicator(
              onRefresh: _loadData,
              color: Color(0xFF46DFB1),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with wave background
                    _buildHeader(),

                    // Our services
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
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

                    SizedBox(height: 30),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF46DFB1),
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 10,
        currentIndex: _selectedNavIndex,
        onTap: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
        },
        items: [
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
            label: 'Tin nhắn',
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
          Icon(Icons.error_outline, color: Colors.red, size: 60),
          SizedBox(height: 16),
          Text(
            _errorMessage ?? "Đã xảy ra lỗi",
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            child: Text("Thử lại"),
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
            color: Color(0xFF46DFB1),
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
                SizedBox(height: 8),
                Text(
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
      return SizedBox(
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
      padding: EdgeInsets.symmetric(horizontal: 16),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: serviceItems.length,
      itemBuilder: (context, index) {
        final service = serviceItems[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: Offset(0, 2),
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
                            color: Color(0xFF46DFB1),
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
                                HourlyServiceScreen(serviceId: 1),
                          ),
                        );
                      } else if (service['name'] == 'Thuê giúp việc định kỳ') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                RecurringServiceScreen(serviceId: 2),
                          ),
                        );
                      } else if (service['name'] == 'Tổng vệ sinh') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                CleaningServiceScreen(serviceId: 3),
                          ),
                        );
                      }
                      // Can add other service types here
                    },
                    child: Container(
                      decoration: BoxDecoration(
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            service['description'],
                            style: TextStyle(
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
      return SizedBox(
        height: 160,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF46DFB1)),
        ),
      );
    }

    return Container(
      height: 160,
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: featuredStaff.isEmpty
          ? Center(child: Text("Không có nhân viên nổi bật"))
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: featuredStaff.length,
              itemBuilder: (context, index) {
                final staff = featuredStaff[index];
                return StaffCard(staff: staff);
              },
            ),
    );
  }

  Widget _buildViewAllButton() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
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
              Icons.keyboard_arrow_down,
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
        'bgColor': Color(0xFF003366),
      },
      {
        'title': 'Giá cả minh bạch',
        'description':
            'Giá dịch vụ rõ ràng, được hiển thị minh bạch trên ứng dụng. Bạn không cần lo lắng về bất kỳ khoản phí ẩn nào.',
        'icon': Icons.monetization_on,
        'color': Color(0xFFFFD700),
        'bgColor': Color(0xFF003366),
      },
      {
        'title': 'Đa dạng dịch vụ',
        'description':
            'Chúng tôi cung cấp nhiều loại hình dịch vụ từ dọn dẹp nhà cửa, giặt giũ, đáp ứng mọi nhu cầu của gia đình bạn.',
        'icon': Icons.cleaning_services,
        'color': Colors.orange,
        'bgColor': Color(0xFF003366),
      },
      {
        'title': 'An toàn và đáng tin cậy',
        'description':
            'Người giúp việc được duyệt kỹ càng với hồ sơ lý lịch rõ ràng. Đội ngũ giám sát đảm bảo quá trình làm việc diễn ra an toàn và hiệu quả.',
        'icon': Icons.verified_user,
        'color': Colors.green,
        'bgColor': Color(0xFF003366),
      },
    ];

    return ListView.builder(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemCount: benefits.length,
      itemBuilder: (context, index) {
        final benefit = benefits[index];
        return Container(
          margin: EdgeInsets.only(bottom: 16),
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
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        benefit['title'],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
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
              return Icon(
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
              return Icon(
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
              return Icon(
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
              return Icon(
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
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF46DFB1),
                ),
                margin: EdgeInsets.only(top: 16, bottom: 12),
                alignment: Alignment.center,
                child: Text(
                  '${step['number']}',
                  style: TextStyle(
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
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: step['iconWidget'],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                child: Text(
                  step['title'],
                  textAlign: TextAlign.center,
                  style: TextStyle(
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

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? Color(0xFF46DFB1).withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Color(0xFF46DFB1) : Colors.grey.shade700,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Color(0xFF46DFB1) : Colors.black87,
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

class ServiceCard extends StatelessWidget {
  final Service service;

  const ServiceCard({
    Key? key,
    required this.service,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 220,
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              service.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Navigate to service details
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF46DFB1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Đặt dịch vụ ngay'),
            ),
          ],
        ),
      ),
    );
  }
}

class StaffCard extends StatelessWidget {
  final Staff staff;

  const StaffCard({
    Key? key,
    required this.staff,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Color(0xFFE3F6F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: Icon(
                      Icons.pets,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.cake, size: 12, color: Colors.black54),
                          SizedBox(width: 4),
                          Text(
                            'Tuổi: ${staff.age}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.work, size: 12, color: Colors.black54),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Kinh nghiệm: ${staff.experience}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < staff.rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 18,
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 6),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          StaffDetailScreen(staffId: staff.id),
                    ),
                  );
                },
                child: Text(
                  'XEM CHI TIẾT',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
