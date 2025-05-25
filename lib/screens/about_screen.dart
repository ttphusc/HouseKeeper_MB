import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF46DFB1),
        title: const Text('Giới thiệu'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Company Logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              color: const Color(0xFF46DFB1).withOpacity(0.1),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 120,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.home_work,
                      size: 120,
                      color: Color(0xFF46DFB1),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'House Keeper',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF46DFB1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'DỊCH VỤ GIÚP VIỆC SỐ 1 VIỆT NAM',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

            // About Us Section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Về chúng tôi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextSection(
                    'House Keeper là dịch vụ giúp việc nhà hàng đầu Việt Nam, cung cấp các dịch vụ vệ sinh nhà cửa, giúp việc theo giờ và định kỳ với đội ngũ nhân viên chuyên nghiệp.',
                  ),
                  const SizedBox(height: 12),
                  _buildTextSection(
                    'Được thành lập từ năm 2018, chúng tôi đã phục vụ hàng ngàn khách hàng trên toàn quốc với tiêu chí "Sạch như mới - Nhanh như chớp".',
                  ),
                  const SizedBox(height: 12),
                  _buildTextSection(
                    'Đội ngũ nhân viên của chúng tôi được đào tạo bài bản, có kinh nghiệm và kỹ năng chuyên môn cao, đảm bảo mang đến cho khách hàng những trải nghiệm dịch vụ tốt nhất.',
                  ),

                  const SizedBox(height: 30),

                  // Mission and Vision
                  const Text(
                    'Sứ mệnh & Tầm nhìn',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildMissionVisionItem(
                    icon: Icons.visibility,
                    title: 'Tầm nhìn',
                    content:
                        'Trở thành thương hiệu dịch vụ giúp việc nhà hàng đầu Việt Nam, mang đến sự tiện nghi và sạch sẽ cho mọi gia đình.',
                  ),
                  const SizedBox(height: 20),
                  _buildMissionVisionItem(
                    icon: Icons.flag,
                    title: 'Sứ mệnh',
                    content:
                        'Cung cấp dịch vụ giúp việc chất lượng cao với giá cả phải chăng, giúp khách hàng tiết kiệm thời gian và tận hưởng cuộc sống thoải mái hơn.',
                  ),

                  const SizedBox(height: 30),

                  // Core Values
                  const Text(
                    'Giá trị cốt lõi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildCoreValuesList(),

                  const SizedBox(height: 30),

                  // Contact Information
                  const Text(
                    'Thông tin liên hệ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildContactInfo(
                    icon: Icons.location_on,
                    title: 'Địa chỉ:',
                    content: '123 Nguyễn Văn Linh, Quận 7, TP. Hồ Chí Minh',
                  ),
                  const SizedBox(height: 12),
                  _buildContactInfo(
                    icon: Icons.phone,
                    title: 'Điện thoại:',
                    content: '1900 1234',
                    isLink: true,
                    link: 'tel:19001234',
                  ),
                  const SizedBox(height: 12),
                  _buildContactInfo(
                    icon: Icons.email,
                    title: 'Email:',
                    content: 'info@housekeeper.vn',
                    isLink: true,
                    link: 'mailto:info@housekeeper.vn',
                  ),
                  const SizedBox(height: 12),
                  _buildContactInfo(
                    icon: Icons.language,
                    title: 'Website:',
                    content: 'www.housekeeper.vn',
                    isLink: true,
                    link: 'https://www.housekeeper.vn',
                  ),

                  const SizedBox(height: 30),

                  // Social Media Links
                  const Text(
                    'Kết nối với chúng tôi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSocialMediaLinks(),
                ],
              ),
            ),

            // Footer
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: const Color(0xFF46DFB1),
              child: const Center(
                child: Text(
                  '© 2024 House Keeper. All rights reserved.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextSection(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        height: 1.5,
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildMissionVisionItem({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF46DFB1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFF46DFB1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoreValuesList() {
    final List<Map<String, dynamic>> coreValues = [
      {
        'icon': Icons.verified_user,
        'title': 'Chất lượng',
        'description': 'Luôn đảm bảo chất lượng dịch vụ tốt nhất',
      },
      {
        'icon': Icons.handshake,
        'title': 'Uy tín',
        'description': 'Xây dựng niềm tin với khách hàng là ưu tiên hàng đầu',
      },
      {
        'icon': Icons.bolt,
        'title': 'Nhanh chóng',
        'description': 'Đáp ứng nhu cầu khách hàng một cách nhanh chóng',
      },
      {
        'icon': Icons.monetization_on,
        'title': 'Giá cả hợp lý',
        'description': 'Dịch vụ chất lượng với mức giá phải chăng',
      },
    ];

    return Column(
      children: coreValues.map((value) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF46DFB1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  value['icon'],
                  color: const Color(0xFF46DFB1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value['description'],
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String title,
    required String content,
    bool isLink = false,
    String? link,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF46DFB1),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              isLink && link != null
                  ? GestureDetector(
                      onTap: () => _launchURL(link),
                      child: Text(
                        content,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text(
                      content,
                      style: const TextStyle(
                        fontSize: 15,
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaLinks() {
    final List<Map<String, dynamic>> socialLinks = [
      {
        'icon': Icons.facebook,
        'name': 'Facebook',
        'color': Colors.blue.shade800,
        'link': 'https://www.facebook.com/housekeeper',
      },
      {
        'icon': Icons.chat_bubble,
        'name': 'Zalo',
        'color': Colors.blue,
        'link': 'https://zalo.me/housekeeper',
      },
      {
        'icon': Icons.insert_photo,
        'name': 'Instagram',
        'color': Colors.pink,
        'link': 'https://www.instagram.com/housekeeper',
      },
      {
        'icon': Icons.play_circle_fill,
        'name': 'YouTube',
        'color': Colors.red,
        'link': 'https://www.youtube.com/housekeeper',
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: socialLinks.map((social) {
        return InkWell(
          onTap: () => _launchURL(social['link']),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: social['color'].withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  social['icon'],
                  color: social['color'],
                  size: 28,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                social['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
