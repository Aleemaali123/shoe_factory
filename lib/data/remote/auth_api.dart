import 'shop_mapper.dart';
import 'remote_shop.dart';

class AuthApi {
  AuthApi(this._api);

  final ShopApi _api;

  Future<Map<String, dynamic>> requestOtp(String phone) async {
    return asMap(await _api.post('/api/auth/otp/request', {'phone': phone}));
  }

  Future<Map<String, dynamic>> verifyOtp(
      {required String phone, required String code}) async {
    return asMap(await _api.post('/api/auth/otp/verify', {
      'phone': phone,
      'code': code,
    }));
  }

  Future<Map<String, dynamic>> registerWithOtp({
    required String name,
    required String email,
    required String phone,
    required String code,
  }) async {
    return asMap(await _api.post('/api/auth/otp/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'code': code,
    }));
  }

  Future<Map<String, dynamic>> login(
      {required String email, required String password}) async {
    return asMap(await _api.post('/api/auth/login', {
      'email': email,
      'password': password,
    }));
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String confirmPassword,
  }) async {
    return asMap(await _api.post('/api/auth/register', {
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'confirmPassword': confirmPassword,
    }));
  }

  Future<void> resetPassword({
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    await _api.post('/api/auth/password/reset', {
      'email': email,
      'password': password,
      'confirmPassword': confirmPassword,
    });
  }

  Future<void> logout() => _api.post('/api/auth/logout');
}
