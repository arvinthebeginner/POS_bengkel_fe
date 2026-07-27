import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _baseUrl = 'https://vms-api-973733869418.asia-southeast2.run.app/';

class ApiService {
  final http.Client _client = http.Client();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Future<String?> _readToken() => _storage.read(key: 'access_token');

  Future<Map<String, String>> _authHeaders() async {
    final token = await _readToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 401) {
      throw UnauthorizedException(body['message'] as String? ?? 'Unauthorized');
    }
    if (response.statusCode == 403) {
      throw ForbiddenException(body['message'] as String? ?? 'Forbidden');
    }
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        body['success'] == false) {
      throw ApiException(body['message'] as String? ?? 'Terjadi kesalahan');
    }

    return body;
  }

  // ---------------- Auth ----------------

  Future<String> login(String username, String password) async {
    final response = await _client.post(
      _uri('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    final body = _decode(response);
    final token = body['data']['access_token'] as String;
    await _storage.write(key: 'access_token', value: token);
    return token;
  }

  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String alamat,
    required String notelp,
    required String branch,
  }) async {
    final response = await _client.post(
      _uri('/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'email': email,
        'alamat': alamat,
        'notelp': notelp,
        'branch': branch,
      }),
    );
    _decode(response);
  }

  Future<List<dynamic>> getBranches() async {
    final response = await _client.get(
      _uri('/branches'),
      headers: {'Content-Type': 'application/json'},
    );
    final body = _decode(response);
    return body['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _client.get(
      _uri('/auth/me'),
      headers: await _authHeaders(),
    );
    final body = _decode(response);
    return body['data'] as Map<String, dynamic>;
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  // ---------------- Stok ----------------

  Future<List<dynamic>> getStok() async {
    final response = await _client.get(
      _uri('/stok'),
      headers: await _authHeaders(),
    );
    final body = _decode(response);
    return body['data'] as List<dynamic>;
  }

  Future<Map<String, dynamic>> getStokDetail(String stokId) async {
    final response = await _client.get(
      _uri('/stok/$stokId'),
      headers: await _authHeaders(),
    );
    final body = _decode(response);
    return body['data'] as Map<String, dynamic>;
  }

  Future<void> createStok({
    required String nama,
    required String kategori,
    required num harga,
    required int stok,
  }) async {
    final response = await _client.post(
      _uri('/stok'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'nama': nama,
        'kategori': kategori,
        'harga': harga,
        'stok': stok,
      }),
    );
    _decode(response);
  }

  Future<void> updateStok({
    required String stokId,
    required String nama,
    required String kategori,
    required num harga,
    required int stok,
  }) async {
    final response = await _client.put(
      _uri('/stok/$stokId'),
      headers: await _authHeaders(),
      body: jsonEncode({
        'nama': nama,
        'kategori': kategori,
        'harga': harga,
        'stok': stok,
      }),
    );
    _decode(response);
  }

  Future<void> deleteStok(String stokId) async {
    final response = await _client.delete(
      _uri('/stok/$stokId'),
      headers: await _authHeaders(),
    );
    _decode(response);
  }

  // ---------------- Kasir / Transaksi ----------------

  Future<List<dynamic>> getKasirStok() async {
    final response = await _client.get(
      _uri('/kasir/stok'),
      headers: await _authHeaders(),
    );
    final body = _decode(response);
    return body['data'] as List<dynamic>;
  }

  Future<num> createTransaksi({
    required List<Map<String, dynamic>> barang,
  }) async {
    final response = await _client.post(
      _uri('/transaksi'),
      headers: await _authHeaders(),
      body: jsonEncode({'barang': barang}),
    );
    final body = _decode(response);
    return (body['data']?['total'] as num?) ?? 0;
  }

  Future<List<dynamic>> getTransaksi() async {
    final response = await _client.get(
      _uri('/transaksi'),
      headers: await _authHeaders(),
    );
    final body = _decode(response);
    return body['data'] as List<dynamic>;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(super.message);
}
