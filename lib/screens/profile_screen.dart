import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final Dio _dio = Dio();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthdateController = TextEditingController();

  bool _isLoading = false;
  bool _isUploadingImage = false;
  String? _errorMessage;
  String? _successMessage;
  Map<String, dynamic> _userInfo = {};
  int _selectedGender = 0; // 0: Nữ, 1: Nam, 2: Khác
  DateTime? _selectedDate;
  bool _hasShownImageError = false;

  File? _imageFile;
  String? _imageUrl;
  Future<Uint8List>? _webImageBytes; // Dùng để lưu dữ liệu ảnh trên web
  String? _webImageName; // Lưu tên file ảnh trên web
  final ImagePicker _picker = ImagePicker();

  // URL API cấu hình cho các môi trường khác nhau
  late String _baseUrl;

  // Khởi tạo URL API dựa vào môi trường
  void _initApiUrl() {
    // Các URL cho các môi trường khác nhau
    const String localEmulatorUrl =
        "http://10.0.2.2:8000/api"; // Cho Android Emulator
    const String localDeviceUrl =
        "http://127.0.0.1:8000/api"; // Cho web hoặc localhost
    const String localNetworkUrl =
        "http://192.168.1.12:8000/api"; // Thay bằng IP máy tính của bạn
    const String productionUrl =
        "https://housekeeper.example.com/api"; // URL production

    // Tự động xác định URL API dựa vào môi trường
    if (kIsWeb) {
      // Đang chạy trên web
      _baseUrl = localDeviceUrl;
    } else if (Platform.isAndroid) {
      // Đang chạy trên Android
      // Thử dùng URL dành cho emulator trước
      _baseUrl = localEmulatorUrl;
    } else if (Platform.isIOS) {
      // Đang chạy trên iOS
      _baseUrl = localDeviceUrl;
    } else {
      // Môi trường khác
      _baseUrl = localDeviceUrl;
    }

    // Thử tải URL từ SharedPreferences nếu đã lưu trước đó
    _loadSavedApiUrl();

    // Hiển thị URL đang sử dụng
    print('🔗 Sử dụng API URL: $_baseUrl');
  }

  Future<void> _loadSavedApiUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('api_base_url');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _baseUrl = savedUrl;
        print('📂 Đã tải URL API từ bộ nhớ: $_baseUrl');
      }
    } catch (e) {
      print('❌ Lỗi khi tải URL API từ bộ nhớ: $e');
    }
  }

  Future<void> _saveApiUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('api_base_url', url);
      print('💾 Đã lưu URL API mới: $url');
    } catch (e) {
      print('❌ Lỗi khi lưu URL API: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _initApiUrl();
    _configureDio();
    if (kIsWeb) {
      _configureForWeb();
    }
    _checkConnectivityAndLoadProfile();
  }

  void _configureDio() {
    _dio.options.connectTimeout = const Duration(seconds: 15); // Tăng timeout
    _dio.options.receiveTimeout = const Duration(seconds: 15);
    _dio.options.sendTimeout = const Duration(seconds: 15);
    _dio.options.validateStatus = (status) {
      return status! < 500; // Chấp nhận status code < 500
    };

    // Thêm interceptor để log và xử lý lỗi
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          print('🌐 REQUEST[${options.method}] => PATH: ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          print(
              '✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          return handler.next(response);
        },
        onError: (DioException e, handler) {
          print(
              '❌ ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
          print('Error message: ${e.message}');

          // Xử lý lỗi cụ thể
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            setState(() {
              _errorMessage =
                  'Kết nối đến máy chủ quá chậm. Vui lòng thử lại sau.';
            });
          } else if (e.type == DioExceptionType.connectionError) {
            setState(() {
              _errorMessage =
                  'Không thể kết nối đến máy chủ. Kiểm tra kết nối internet của bạn.';
            });
          }
          return handler.next(e);
        },
      ),
    );
  }

  // Cấu hình đặc biệt cho web platform
  void _configureForWeb() {
    // Thiết lập URL API cho web
    _baseUrl = "http://localhost:8000/api"; // URL API cho localhost trong web

    print('🌐 Phát hiện môi trường Web, sử dụng URL API: $_baseUrl');

    // Vô hiệu hóa các tính năng không hoạt động trên web
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Thêm header CORS cho web
    _dio.options.headers = {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token',
    };
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthdateController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivityAndLoadProfile() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      setState(() {
        _errorMessage = 'Không có kết nối internet. Vui lòng kiểm tra lại.';
        _isLoading = false;
      });

      // Chỉ hiện thông báo nếu không phải lần đầu khởi động
      if (mounted && _userInfo.isNotEmpty) {
        _showErrorMessage(_errorMessage!);
      }
      return;
    }

    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      _hasShownImageError = false;
    });

    try {
      // Kiểm tra kết nối với máy chủ API trước
      bool serverReachable = false;

      // Cách 1: Thử ping API endpoint
      try {
        final pingResponse = await _dio
            .get('$_baseUrl/ping',
                options: Options(
                  sendTimeout: const Duration(seconds: 5),
                  receiveTimeout: const Duration(seconds: 5),
                ))
            .timeout(const Duration(seconds: 5));

        print('Ping response: ${pingResponse.statusCode}');
        serverReachable = true;
      } catch (e) {
        print('Ping failed: $e');

        // Cách 2: Thử dùng /sanctum/csrf-cookie để kiểm tra kết nối
        try {
          final csrfResponse = await _dio
              .get('$_baseUrl/../sanctum/csrf-cookie')
              .timeout(const Duration(seconds: 5));
          print('CSRF response: ${csrfResponse.statusCode}');
          serverReachable = true;
        } catch (csrfError) {
          print('CSRF check failed: $csrfError');
          // Vẫn tiếp tục và thử gọi API chính
        }
      }

      // Nếu không thể kết nối đến server, hiển thị lỗi
      if (!serverReachable) {
        print('Không thể kết nối đến máy chủ API');
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        });
        return;
      }

      print('Gọi API với URL: $_baseUrl/nguoi-dung/getDataProfile');
      if (token.length > 10) {
        print('Token: ${token.substring(0, 10)}...');
      } else {
        print('Token: $token');
      }

      final response = await _dio.get(
        '$_baseUrl/nguoi-dung/getDataProfile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Máy chủ trả về mã lỗi: ${response.statusCode}';
        });
        return;
      }

      setState(() {
        _isLoading = false;
        if (response.data['data'] != null) {
          _userInfo = response.data['data'];
          _nameController.text = _userInfo['ho_va_ten'] ?? '';
          _emailController.text = _userInfo['email'] ?? '';
          _phoneController.text = _userInfo['so_dien_thoai'] ?? '';

          if (_userInfo['ngay_sinh'] != null &&
              _userInfo['ngay_sinh'].toString().isNotEmpty) {
            _birthdateController.text = _userInfo['ngay_sinh'];
            try {
              _selectedDate = DateTime.parse(_userInfo['ngay_sinh']);
            } catch (e) {
              print('Lỗi chuyển đổi ngày: ${e.toString()}');
            }
          }

          if (_userInfo['gioi_tinh'] != null) {
            _selectedGender =
                int.tryParse(_userInfo['gioi_tinh'].toString()) ?? 0;
          }

          // Kiểm tra và xử lý URL hình ảnh
          _imageUrl = _fixImageUrl(_userInfo['hinh_anh']);

          print('Đã tải thông tin người dùng: ${_userInfo['ho_va_ten']}');
          print('Ảnh đại diện: $_imageUrl');
        } else {
          _errorMessage = 'Không nhận được dữ liệu người dùng từ máy chủ';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e is DioException) {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.receiveTimeout) {
            _errorMessage =
                'Kết nối đến máy chủ quá chậm. Vui lòng thử lại sau.';
          } else if (e.type == DioExceptionType.connectionError) {
            _errorMessage =
                'Không thể kết nối đến máy chủ. Kiểm tra kết nối internet của bạn.';
            if (mounted) {
              _showConnectionErrorDialog();
            }
          } else if (e.response != null) {
            _errorMessage =
                'Lỗi từ máy chủ: ${e.response?.statusCode} - ${e.response?.statusMessage}';
          } else {
            _errorMessage = 'Lỗi: ${e.message}';
          }
        } else {
          _errorMessage =
              'Không thể tải thông tin cá nhân. Lỗi: ${e.toString()}';
        }
      });
      print('Error loading profile: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _birthdateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        // Trên web, chúng ta cần sử dụng phương pháp khác
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          // Trên web, không thể truy cập đường dẫn tệp trực tiếp
          setState(() {
            _imageFile =
                File(pickedFile.path); // Giả tạo đối tượng File cho web
            _webImageBytes =
                pickedFile.readAsBytes(); // Đọc dữ liệu ảnh dưới dạng bytes
            _webImageName = pickedFile.name;
          });
          print('Đã chọn ảnh trên web, đường dẫn: ${pickedFile.path}');
          print('Tên file: ${pickedFile.name}');
        }
      } else {
        // Trên thiết bị di động
        final XFile? pickedFile = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
        );

        if (pickedFile != null) {
          setState(() {
            _imageFile = File(pickedFile.path);
          });
          print('Đã chọn ảnh trên thiết bị, đường dẫn: ${pickedFile.path}');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể chọn ảnh: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error picking image: $e');
    }
  }

  Future<void> _uploadAvatar() async {
    if (kIsWeb) {
      if (_webImageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ảnh trước khi tải lên'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else {
      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn ảnh trước khi tải lên'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      _isUploadingImage = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final token = await _getToken();

      if (token.isEmpty) {
        setState(() {
          _isUploadingImage = false;
          _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        });
        _showErrorMessage(_errorMessage!);
        return;
      }

      // Create form data
      final formData = FormData();

      if (kIsWeb) {
        // Xử lý cho web
        if (_webImageBytes != null) {
          final bytes = await _webImageBytes!;
          final filename = _webImageName ?? 'avatar.jpg';

          print(
              'Tải lên ảnh trên web: $filename, kích thước: ${bytes.length} bytes');

          formData.files.add(
            MapEntry(
              'hinh_anh',
              MultipartFile.fromBytes(
                bytes,
                filename: filename,
              ),
            ),
          );
        }
      } else {
        // Xử lý cho mobile
        if (_imageFile != null) {
          print('Tải lên file: ${_imageFile!.path}');
          print('Kích thước file: ${await _imageFile!.length()} bytes');
          print('Loại file: ${_imageFile!.path.split('.').last}');

          formData.files.add(
            MapEntry(
              'hinh_anh',
              await MultipartFile.fromFile(
                _imageFile!.path,
                filename: 'avatar.${_imageFile!.path.split('.').last}',
              ),
            ),
          );
        }
      }

      // Log request details
      print(
          'Gửi request đến: $_baseUrl/nguoi-dung/update-Anh-dai-dien-Profile');
      print(
          'Với headers: Authorization: Bearer ${token.substring(0, min(10, token.length))}...');

      final response = await _dio.post(
        '$_baseUrl/nguoi-dung/update-Anh-dai-dien-Profile',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
            'Accept': 'application/json',
          },
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      setState(() {
        _isUploadingImage = false;
      });

      if (response.data['status'] == true) {
        setState(() {
          _successMessage =
              response.data['message'] ?? 'Cập nhật ảnh đại diện thành công';
          _imageFile = null; // Reset image file after successful upload
          _webImageBytes = null; // Reset web image
          _webImageName = null;
        });
        _showSuccessMessage(_successMessage!);

        // Reload profile to get new image URL after a short delay
        Future.delayed(const Duration(milliseconds: 800), () {
          _loadUserProfile();
        });
      } else {
        setState(() {
          _errorMessage =
              response.data['message'] ?? 'Cập nhật ảnh đại diện thất bại';
        });
        _showErrorMessage(_errorMessage!);
      }
    } catch (e) {
      setState(() {
        _isUploadingImage = false;
        if (e is DioException) {
          if (e.response != null) {
            _errorMessage = 'Lỗi: ${e.response?.statusMessage ?? e.message}';
            print('Lỗi tải ảnh lên - status: ${e.response?.statusCode}');
            print('Lỗi response data: ${e.response?.data}');
          } else {
            _errorMessage = 'Có lỗi xảy ra khi tải ảnh lên: ${e.message}';
          }
        } else {
          _errorMessage = 'Có lỗi xảy ra khi tải ảnh lên. Vui lòng thử lại.';
        }
      });
      _showErrorMessage(_errorMessage!);
      print('Error uploading avatar: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        });
        _showErrorMessage(_errorMessage!);
        return;
      }

      final response = await _dio.post(
        '$_baseUrl/nguoi-dung/updateProfile',
        data: {
          'ho_va_ten': _nameController.text,
          'email': _emailController.text,
          'so_dien_thoai': _phoneController.text,
          'ngay_sinh': _birthdateController.text,
          'gioi_tinh': _selectedGender.toString(),
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.data['status'] == true) {
        setState(() {
          _successMessage =
              response.data['message'] ?? 'Cập nhật thông tin thành công';
        });
        _showSuccessMessage(_successMessage!);

        // Reload the profile to get updated information after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _loadUserProfile();
        });
      } else {
        setState(() {
          _errorMessage =
              response.data['message'] ?? 'Cập nhật thông tin thất bại';
        });
        _showErrorMessage(_errorMessage!);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (e is DioException && e.response != null) {
        String errorMsg = 'Đã có lỗi xảy ra';

        if (e.response!.data['errors'] != null) {
          final errorsMap = e.response!.data['errors'] as Map<String, dynamic>;
          if (errorsMap.isNotEmpty) {
            final firstError = errorsMap.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              errorMsg = firstError[0].toString();
            }
          }
        } else if (e.response!.data['message'] != null) {
          errorMsg = e.response!.data['message'];
        }

        setState(() {
          _errorMessage = errorMsg;
        });
        _showErrorMessage(errorMsg);
      } else {
        setState(() {
          _errorMessage =
              'Có lỗi xảy ra khi cập nhật thông tin. Vui lòng thử lại.';
        });
        _showErrorMessage(_errorMessage!);
      }

      print('Error updating profile: $e');
    }
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    // Sử dụng addPostFrameCallback để đảm bảo hiển thị sau khi build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    // Sử dụng addPostFrameCallback để đảm bảo hiển thị sau khi build xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    });
  }

  void _showConnectionErrorDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Lỗi kết nối'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Không thể kết nối đến máy chủ API. Vui lòng kiểm tra:'),
              SizedBox(height: 10),
              Text('1. Kết nối internet của bạn'),
              Text('2. URL API đã đúng chưa'),
              Text('3. Máy chủ API có đang chạy không'),
              SizedBox(height: 10),
              Text(
                  'Nếu đang sử dụng emulator, hãy dùng 10.0.2.2 thay vì localhost'),
              Text(
                  'Nếu đang sử dụng thiết bị thật, hãy dùng địa chỉ IP của máy chủ'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Thử URL khác'),
              onPressed: () {
                Navigator.of(context).pop();
                _showUrlSelectionDialog();
              },
            ),
            TextButton(
              child: const Text('Thử lại'),
              onPressed: () {
                Navigator.of(context).pop();
                _checkConnectivityAndLoadProfile();
              },
            ),
          ],
        );
      },
    );
  }

  void _showUrlSelectionDialog() {
    if (!mounted) return;

    // Danh sách các URL khác nhau để thử nghiệm
    final List<Map<String, dynamic>> urlOptions = [
      {'name': 'Android Emulator', 'url': 'http://10.0.2.2:8000/api'},
      {'name': 'Localhost', 'url': 'http://127.0.0.1:8000/api'},
      {'name': 'LAN (Thay đổi IP)', 'url': 'http://192.168.1.12:8000/api'},
      {'name': 'Custom URL...', 'url': ''},
    ];

    String selectedUrl = _baseUrl;
    final TextEditingController customUrlController = TextEditingController();
    bool isCustomUrl = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Chọn URL API'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Chọn URL API để kết nối:'),
                  const SizedBox(height: 10),
                  for (var option in urlOptions)
                    RadioListTile<String>(
                      title: Text(option['name']),
                      subtitle:
                          option['url'].isNotEmpty ? Text(option['url']) : null,
                      value: option['url'],
                      groupValue: isCustomUrl ? null : selectedUrl,
                      onChanged: (value) {
                        setState(() {
                          selectedUrl = value!;
                          isCustomUrl = false;
                          if (option['name'] == 'Custom URL...') {
                            isCustomUrl = true;
                            customUrlController.text = _baseUrl;
                          }
                        });
                      },
                    ),
                  if (isCustomUrl)
                    TextField(
                      controller: customUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Nhập URL tùy chỉnh',
                        hintText: 'http://your-api-url.com/api',
                      ),
                      onChanged: (value) {
                        selectedUrl = value;
                      },
                    ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Hủy'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Chọn & Thử lại'),
                  onPressed: () async {
                    Navigator.of(context).pop();

                    // Cập nhật URL API
                    final newUrl =
                        isCustomUrl ? customUrlController.text : selectedUrl;
                    _baseUrl = newUrl;

                    // Lưu URL API vào SharedPreferences
                    await _saveApiUrl(newUrl);

                    // Thử lại kết nối
                    _checkConnectivityAndLoadProfile();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Hàm trợ giúp để lấy độ dài tối thiểu
  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF46DFB1),
        title: const Text('Thông tin cá nhân'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Debug button - chỉ hiển thị trong môi trường dev
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _showDebugInfo,
              tooltip: 'Hiển thị thông tin debug',
            ),
        ],
      ),
      body: _isLoading && _userInfo.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF46DFB1)))
          : RefreshIndicator(
              onRefresh: _loadUserProfile,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _errorMessage != null
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.red),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.refresh,
                                        color: Colors.red),
                                    onPressed: _checkConnectivityAndLoadProfile,
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                      _buildProfileHeader(),
                      const SizedBox(height: 20),
                      _buildProfileForm(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile image and upload section
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Viền ngoài
                  Container(
                    width: 128,
                    height: 128,
                    decoration: const BoxDecoration(
                      color: Color(0xFF46DFB1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _buildProfileImage(),
                    ),
                  ),

                  // Edit button overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 5,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Color(0xFF46DFB1),
                        ),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // User name and role
            Text(
              _nameController.text.isEmpty
                  ? 'Chưa cập nhật'
                  : _nameController.text,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Người dùng',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 16),

            // Image upload section if there's a selected image
            if (_imageFile != null) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ảnh đại diện mới',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isUploadingImage ? null : _uploadAvatar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF46DFB1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: _isUploadingImage
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Lưu ảnh'),
                  ),
                ],
              ),
            ],

            const Divider(),

            // Contact information
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF46DFB1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone, color: Color(0xFF46DFB1)),
              ),
              title: const Text('Số điện thoại'),
              subtitle: Text(
                _phoneController.text.isNotEmpty
                    ? _phoneController.text
                    : 'Chưa cập nhật',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _phoneController.text.isEmpty
                      ? Colors.grey
                      : Colors.black87,
                ),
              ),
            ),

            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF46DFB1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.email, color: Color(0xFF46DFB1)),
              ),
              title: const Text('Email'),
              subtitle: Text(
                _emailController.text.isNotEmpty
                    ? _emailController.text
                    : 'Chưa cập nhật',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _emailController.text.isEmpty
                      ? Colors.grey
                      : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    if (_imageFile != null) {
      // Hiển thị ảnh đã chọn từ thiết bị
      return Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: kIsWeb
              ? FutureBuilder<Uint8List>(
                  future: _webImageBytes,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF46DFB1),
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return Container(
                        color: const Color(0xFF46DFB1),
                        child: const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.white,
                        ),
                      );
                    }

                    // Hiển thị ảnh từ bytes cho web
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    );
                  },
                )
              : Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                  width: 120,
                  height: 120,
                ),
        ),
      );
    } else if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      // Hiển thị ảnh từ server
      return FutureBuilder<String>(
          future: _getToken(),
          builder: (context, snapshot) {
            final token = snapshot.data ?? '';

            // Log URL ảnh để debug
            print('🔄 Đang tải ảnh từ URL: $_imageUrl');

            return Container(
              width: 120,
              height: 120,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: _imageUrl!,
                  fit: BoxFit.cover,
                  width: 120,
                  height: 120,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF46DFB1),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) {
                    print('❌ Lỗi tải ảnh đại diện: $error (URL: $url)');
                    // Không gọi _handleImageLoadError trực tiếp ở đây
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_hasShownImageError && mounted) {
                        _hasShownImageError = true;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Không thể tải ảnh đại diện'),
                            backgroundColor: Colors.orange,
                            action: SnackBarAction(
                              label: 'Thử lại',
                              onPressed: () {
                                _hasShownImageError = false;
                                _reloadProfileImage();
                              },
                            ),
                          ),
                        );
                      }
                    });
                    return Container(
                      color: const Color(0xFF46DFB1).withOpacity(0.5),
                      child: const Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.white,
                      ),
                    );
                  },
                  httpHeaders: token.isNotEmpty
                      ? {'Authorization': 'Bearer $token'}
                      : null,
                  cacheKey:
                      '$_imageUrl?token=${DateTime.now().millisecondsSinceEpoch}', // Tránh cache
                ),
              ),
            );
          });
    } else {
      // Hiển thị icon mặc định
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF46DFB1).withOpacity(0.7),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.person,
          size: 60,
          color: Colors.white,
        ),
      );
    }
  }

  Widget _buildProfileForm() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin chi tiết',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Name field
              _buildFormField(
                label: 'Họ và tên',
                controller: _nameController,
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập họ và tên';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email field
              _buildFormField(
                label: 'Email',
                controller: _emailController,
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập email';
                  }
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                      .hasMatch(value)) {
                    return 'Email không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone field
              _buildFormField(
                label: 'Số điện thoại',
                controller: _phoneController,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập số điện thoại';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Birthdate field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ngày sinh',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF46DFB1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF46DFB1).withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(7),
                                bottomLeft: Radius.circular(7),
                              ),
                            ),
                            child: const Icon(Icons.calendar_today,
                                color: Color(0xFF46DFB1)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _birthdateController.text.isNotEmpty
                                  ? _birthdateController.text
                                  : 'Chọn ngày sinh',
                              style: TextStyle(
                                fontSize: 16,
                                color: _birthdateController.text.isEmpty
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Gender selection
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Giới tính',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF46DFB1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF46DFB1).withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(7),
                              bottomLeft: Radius.circular(7),
                            ),
                          ),
                          child: const Icon(Icons.person,
                              color: Color(0xFF46DFB1)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: _selectedGender,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(value: 0, child: Text('Nữ')),
                                DropdownMenuItem(value: 1, child: Text('Nam')),
                                DropdownMenuItem(value: 2, child: Text('Khác')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value ?? 0;
                                });
                              },
                              icon: const Icon(Icons.arrow_drop_down),
                              iconSize: 24,
                              underline: null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Update button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF46DFB1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Cập nhật thông tin',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF46DFB1),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF46DFB1).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    bottomLeft: Radius.circular(7),
                  ),
                ),
                child: Icon(icon, color: const Color(0xFF46DFB1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  validator: validator,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Lấy token từ SharedPreferences
  Future<String> _getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('token_nguoi_dung') ?? '';
    } catch (e) {
      print('Lỗi khi lấy token: $e');
      return '';
    }
  }

  // Hàm kiểm tra và chuẩn hóa URL ảnh
  String _fixImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return '';
    }

    // Nếu đã là URL đầy đủ, giữ nguyên
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Xác định URL gốc của server
    String serverBaseUrl = 'http://127.0.0.1:8000';
    if (_baseUrl.startsWith('http://10.0.2.2')) {
      serverBaseUrl = 'http://10.0.2.2:8000';
    } else if (_baseUrl.contains('192.168.')) {
      // Trích xuất phần IP từ baseUrl
      final parts = _baseUrl.split('/');
      if (parts.length >= 3) {
        serverBaseUrl = '${parts[0]}//${parts[2].split(':')[0]}:8000';
      }
    }

    // Nối URL server với đường dẫn ảnh
    if (url.startsWith('/')) {
      return '$serverBaseUrl$url';
    } else {
      return '$serverBaseUrl/$url';
    }
  }

  // Tải lại thông tin ảnh đại diện
  Future<void> _reloadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_nguoi_dung');

      if (token == null || token.isEmpty) {
        return;
      }

      final response = await _dio.get(
        '$_baseUrl/nguoi-dung/getDataProfile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );

      if (response.data['data'] != null &&
          response.data['data']['hinh_anh'] != null) {
        setState(() {
          _imageUrl = _fixImageUrl(response.data['data']['hinh_anh']);
          print('📷 Đã tải lại URL ảnh đại diện: $_imageUrl');
        });
      }
    } catch (e) {
      print('❌ Lỗi khi tải lại ảnh đại diện: $e');
    }
  }

  // Hiển thị thông tin debug để giúp gỡ lỗi
  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin Debug'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nền tảng: ${kIsWeb ? 'Web' : Platform.operatingSystem}'),
              Text('API URL: $_baseUrl'),
              Text('Có ảnh đại diện: ${_imageUrl != null ? 'Có' : 'Không'}'),
              if (_imageUrl != null) Text('URL ảnh: $_imageUrl'),
              Text('Có file ảnh local: ${_imageFile != null ? 'Có' : 'Không'}'),
              if (_imageFile != null) Text('Đường dẫn: ${_imageFile!.path}'),
              const Divider(),
              Text(
                  'Thông tin người dùng: ${_userInfo.isEmpty ? 'Không có' : ''}'),
              if (_userInfo.isNotEmpty)
                ...[
                  'ho_va_ten',
                  'email',
                  'so_dien_thoai',
                  'gioi_tinh',
                  'ngay_sinh'
                ].map((key) => Text('$key: ${_userInfo[key] ?? 'Không có'}')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _loadUserProfile();
            },
            child: const Text('Tải lại dữ liệu'),
          ),
        ],
      ),
    );
  }
}
