import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/service.dart';
import '../models/staff.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final Dio _dio = Dio();
  final String baseUrl = "http://127.0.0.1:8000/api";

  ApiService() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Chỉ cấu hình sendTimeout khi không phải web
    if (!kIsWeb) {
      _dio.options.sendTimeout = const Duration(seconds: 30);
    }

    // Add interceptor for retry logic and better error handling
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (e, handler) async {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout) {
            print('Timeout error: ${e.message}');
          }
          return handler.next(e);
        },
      ),
    );
  }

  // Get auth token
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token_nguoi_dung');
  }

  // Get services with mock data fallback
  Future<List<Service>> getServices() async {
    try {
      final response = await _dio.get("$baseUrl/nguoi-dung/get-Data-Dich-Vu");
      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        return data.map((item) => Service.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load services");
      }
    } catch (e) {
      print("Error loading services: $e");
      return _getMockServices();
    }
  }

  // Get featured staff with mock data fallback
  Future<List<Staff>> getFeaturedStaff() async {
    try {
      final token = await _getAuthToken();
      final response = await _dio.get(
        "$baseUrl/nguoi-dung/get-Data-Nhan-Vien-Noi-Bat",
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        List<dynamic> data = response.data['data'];
        return data.map((item) => Staff.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load featured staff");
      }
    } catch (e) {
      print("Error loading featured staff: $e");
      return _getMockStaff();
    }
  }

  // Get flash sale staff
  Future<List<Staff>> getFlashSaleStaff() async {
    try {
      final token = await _getAuthToken();
      final response = await _dio.get(
        "$baseUrl/nguoi-dung/get-Data-NhanVien-Flash-Sale",
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        List<dynamic> data = response.data['data'];
        return data.map((item) => Staff.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load flash sale staff");
      }
    } catch (e) {
      print("Error loading flash sale staff: $e");
      return _getMockStaff();
    }
  }

  // Get staff detail
  Future<Staff> getStaffDetail(int id) async {
    try {
      final token = await _getAuthToken();
      final response = await _dio.get(
        "$baseUrl/nguoi-dung/get-Data-Chi-Tiet-Nhan-Vien/$id",
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.statusCode == 200 && response.data['data'] != null) {
        Map<String, dynamic> data = response.data['data'];
        return Staff.fromJson(data);
      } else {
        throw Exception("Failed to load staff details");
      }
    } catch (e) {
      print("Error loading staff details: $e");
      return _getMockStaff().first;
    }
  }

  // Mock data for services in case API fails
  List<Service> _getMockServices() {
    return [
      Service(
        id: 1,
        name: 'Thuê giúp việc theo giờ',
        description: '→ Đặt dịch vụ ngay',
        imageUrl: 'assets/images/Dichvu1.png',
        icon: Icons.cleaning_services,
      ),
      Service(
        id: 2,
        name: 'Thuê giúp việc định kỳ',
        description: '→ Đặt dịch vụ ngay',
        imageUrl: 'assets/images/Dichvu2.png',
        icon: Icons.schedule,
      ),
      Service(
        id: 3,
        name: 'Tổng vệ sinh',
        description: '→ Đặt dịch vụ ngay',
        imageUrl: 'assets/images/Dichvu3.png',
        icon: Icons.home,
      ),
    ];
  }

  // Mock data for staff in case API fails
  List<Staff> _getMockStaff() {
    return [
      Staff(
        id: 1,
        name: 'Trần Minh Ngọc',
        age: 25,
        experience: '3 năm',
        rating: 5,
        avatarUrl: 'assets/images/staff1.jpg',
        address: '459 Hai Bà Trưng, Hòa Minh, Kiến An, Hải Phòng',
      ),
      Staff(
        id: 2,
        name: 'Nguyễn Thị Hoa',
        age: 30,
        experience: '5 năm',
        rating: 4,
        avatarUrl: 'assets/images/staff2.jpg',
        address: '123 Lê Lợi, Ngô Quyền, Hải Phòng',
      ),
      Staff(
        id: 3,
        name: 'Lê Văn Đức',
        age: 28,
        experience: '4 năm',
        rating: 5,
        avatarUrl: 'assets/images/staff3.jpg',
        address: '45 Trần Phú, Hồng Bàng, Hải Phòng',
      ),
    ];
  }
}
