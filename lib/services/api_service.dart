import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/service.dart';
import '../models/staff.dart';

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
            // Log the timeout error
            print('Timeout error: ${e.message}');
          }
          return handler.next(e);
        },
      ),
    );
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
      // Return mock data in case of error
      return _getMockServices();
    }
  }

  // Get featured staff with mock data fallback
  Future<List<Staff>> getFeaturedStaff() async {
    try {
      final response = await _dio.get(
        "$baseUrl/nguoi-dung/get-Data-Nhan-Vien-Noi-Bat",
      );
      if (response.statusCode == 200) {
        List<dynamic> data = response.data['data'];
        return data.map((item) => Staff.fromJson(item)).toList();
      } else {
        throw Exception("Failed to load featured staff");
      }
    } catch (e) {
      print("Error loading featured staff: $e");
      // Return mock data in case of error
      return _getMockStaff();
    }
  }

  // Get flash sale staff
  Future<List<Staff>> getFlashSaleStaff() async {
    try {
      final response = await _dio.get(
        "$baseUrl/nguoi-dung/get-Data-NhanVien-Flash-Sale",
      );
      if (response.statusCode == 200) {
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
      final response = await _dio.get(
        "$baseUrl/nguoi-dung/get-chi-tiet-nhan-vien/$id",
      );
      if (response.statusCode == 200) {
        Map<String, dynamic> data = response.data['data'];
        return Staff.fromJson(data);
      } else {
        throw Exception("Failed to load staff details");
      }
    } catch (e) {
      print("Error loading staff details: $e");
      // Return mock staff in case of error
      return _getMockStaff().first;
    }
  }

  // Mock data for services in case API fails
  List<Service> _getMockServices() {
    return [
      Service(
        id: 1,
        name: 'Thuê giúp việc theo giờ',
        slug: 'thue-giup-viec-theo-gio',
        description: 'Dịch vụ giúp việc theo giờ linh hoạt',
      ),
      Service(
        id: 2,
        name: 'Thuê giúp việc định kỳ',
        slug: 'thue-giup-viec-dinh-ky',
        description: 'Dịch vụ giúp việc định kỳ tiện lợi',
      ),
      Service(
        id: 3,
        name: 'Tổng vệ sinh',
        slug: 'tong-ve-sinh',
        description: 'Dịch vụ tổng vệ sinh chuyên nghiệp',
      ),
    ];
  }

  // Mock data for staff in case API fails
  List<Staff> _getMockStaff() {
    return [
      Staff(
        id: 1,
        name: 'Trần Minh Ngọc',
        age: '25',
        experience: '2 năm',
        rating: 5,
        imageUrl: '',
      ),
      Staff(
        id: 2,
        name: 'Nguyễn Thị Linh',
        age: '30',
        experience: '3 năm',
        rating: 5,
        imageUrl: '',
      ),
      Staff(
        id: 3,
        name: 'Lê Văn Đức',
        age: '28',
        experience: '4 năm',
        rating: 4,
        imageUrl: '',
      ),
    ];
  }
}
