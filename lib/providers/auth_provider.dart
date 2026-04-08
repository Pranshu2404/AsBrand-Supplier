import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../core/constants.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  User? _user;
  bool _isLoading = false;
  String? _token;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  bool get isLoggedIn => isAuthenticated;
  bool get isSupplier => _user?.isSupplier ?? false;
  String? get token => _token;

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConstants.login, {
        'email': email,
        'password': password,
      });

      if (response['success'] == true) {
        _token = response['data']['token'];
        if (response['data']['user'] != null) {
          _user = User.fromJson(response['data']['user']);
          // Load local profile image if it exists
          await _loadLocalProfileImage();
        }
        await _storage.write(key: 'auth_token', value: _token);
        _isLoading = false;
        notifyListeners();
        return true;
      }
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Send OTP to phone number
  Future<String?> sendOtp(String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConstants.sendOtp, {
        'phone': phone,
      });

      _isLoading = false;
      notifyListeners();

      if (response['success'] == true) {
        // DEV: Return the OTP from response for testing
        return response['dev_otp']?.toString();
      }
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Verify OTP and login
  Future<bool> verifyOtp(String phone, String otp) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConstants.verifyOtp, {
        'phone': phone,
        'otp': otp,
      });

      if (response['success'] == true) {
        _token = response['data']['token'];
        _user = User.fromJson(response['data']['user']);
        // Load local profile image if it exists
        await _loadLocalProfileImage();
        await _storage.write(key: 'auth_token', value: _token);
      }

      _isLoading = false;
      notifyListeners();
      return response['success'] == true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Register (returns phone number for OTP verification)
  Future<String?> register(String name, String email, String phone, String password, {String? referrerCode}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.post(ApiConstants.register, {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        if (referrerCode != null && referrerCode.isNotEmpty) 'referrerCode': referrerCode,
      });
      
      _isLoading = false;
      notifyListeners();

      if (response['success'] == true) {
        // Registration now requires OTP verification — return the phone
        return response['data']?['phone'] ?? phone;
      }
      return null;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Update Profile (Local & Remote)
  Future<bool> updateProfile(String name, String phone, {String? profileImage}) async {
    if (_user == null) return false;

    String? finalImagePath = profileImage;

    // IF NEW IMAGE PATH PROVIDED, COPY IT TO PERMANENT APP STORAGE
    if (profileImage != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${_user!.id}.jpg';
      final permanentPath = '${appDir.path}/$fileName';

      // Check if image is from a temporary directory and needs moving
      if (profileImage != permanentPath) {
        try {
          final tempFile = File(profileImage);
          if (await tempFile.exists()) {
             final savedFile = await tempFile.copy(permanentPath);
             finalImagePath = savedFile.path;
          }
        } catch (e) {
          debugPrint('Error saving profile image: $e');
        }
      }
    }

    _user = _user!.copyWith(name: name, phone: phone, profileImage: finalImagePath);
    
    // PERSIST PROFILE IMAGE PATH LOCALLY
    final prefs = await SharedPreferences.getInstance();
    if (finalImagePath != null) {
      await prefs.setString('local_profile_image_${_user!.id}', finalImagePath);
    } else {
      await prefs.remove('local_profile_image_${_user!.id}');
    }

    notifyListeners();
    return true;
  }

  /// Replace stored JWT with a new one (e.g. after role change)
  Future<void> updateToken(String newToken) async {
    _token = newToken;
    await _storage.write(key: 'auth_token', value: newToken);
  }

  // Logout
  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.delete(key: 'auth_token');
    notifyListeners();
  }

  // Load profile image from shared preferences
  Future<void> _loadLocalProfileImage() async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    final localImage = prefs.getString('local_profile_image_${_user!.id}');
    
    if (localImage != null) {
      // Check if the file still exists at the path
      if (await File(localImage).exists()) {
        _user = _user!.copyWith(profileImage: localImage);
      }
    }
  }

  // Check Auth Status (Run on App Start)
  Future<void> checkAuth() async {
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      _token = token;
      try {
         final response = await _apiService.get(ApiConstants.profile);
         if (response['success'] == true) {
           _user = User.fromJson(response['data']);
           
           // LOAD LOCAL PROFILE IMAGE AFTER FETCHING PROFILE
           await _loadLocalProfileImage();

           // Save refreshed token (role may have changed)
           final newToken = response['token'];
           if (newToken != null && newToken != _token) {
             _token = newToken;
             await _storage.write(key: 'auth_token', value: newToken);
           }
         }
      } catch (_) {
        // Token might be invalid
        logout();
      }
    }
    notifyListeners();
  }
}
