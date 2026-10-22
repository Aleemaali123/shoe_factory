import 'shop_mapper.dart';
import 'remote_shop.dart';

class ProfileApi {
  ProfileApi(this._api);

  final ShopApi _api;

  Future<Map<String, dynamic>> get() async {
    return asMap(await _api.get('/api/profile'));
  }

  Future<Map<String, dynamic>> update({
    required String name,
    required String email,
    required String phone,
  }) async {
    return asMap(await _api.patch('/api/profile', {
      'name': name,
      'email': email,
      'phone': phone,
    }));
  }

  Future<List<dynamic>> saveAddress({
    String? id,
    required String label,
    required String name,
    required String phone,
    required String line,
    required String city,
    required String pincode,
  }) async {
    final body = {
      'label': label,
      'name': name,
      'phone': phone,
      'line': line,
      'city': city,
      'pincode': pincode,
    };
    final data = id == null
        ? await _api.post('/api/profile/addresses', body)
        : await _api.patch('/api/profile/addresses/$id', body);
    return data as List;
  }

  Future<List<dynamic>> deleteAddress(String id) async {
    return await _api.delete('/api/profile/addresses/$id') as List;
  }

  Future<List<dynamic>> setDefault(String id) async {
    return await _api.post('/api/profile/addresses/$id/default') as List;
  }
}
