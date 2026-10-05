import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================

  // Android Emulator ใช้ 10.0.2.2 แทน localhost ของเครื่องคอม
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  static String? token;

  // ============================================================
  // TOKEN
  // ============================================================

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
  }

  static Future<void> saveToken(String newToken) async {
    token = newToken;

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', newToken);
  }

  static Future<void> clearToken() async {
    token = null;

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
  }

  // ============================================================
  // HEADERS
  // ============================================================

  static Map<String, String> get headers {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',

      if (token != null && token!.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  static Map<String, String> get authHeaders {
    return {
      'Accept': 'application/json',

      if (token != null && token!.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  // ============================================================
  // RESPONSE
  // ============================================================

  static Map<String, dynamic> _decodeResponse(
    http.Response response,
  ) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        return data;
      }

      return {
        'success': false,
        'message': 'รูปแบบข้อมูลจาก Server ไม่ถูกต้อง',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'ไม่สามารถอ่านข้อมูลจาก Server ได้',
        'error': e.toString(),
        'status_code': response.statusCode,
      };
    }
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final result = _decodeResponse(response);

    if (result['success'] == true &&
        result['token'] != null) {
      await saveToken(
        result['token'].toString(),
      );
    }

    return result;
  }

  // ============================================================
  // REGISTER
  // ============================================================

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String studentCode,
    String? phone,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'student_code': studentCode,
        'phone': phone,
      }),
    );

    final result = _decodeResponse(response);

    if (result['success'] == true &&
        result['token'] != null) {
      await saveToken(
        result['token'].toString(),
      );
    }

    return result;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  static Future<Map<String, dynamic>> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: authHeaders,
      );

      final result = _decodeResponse(response);

      await clearToken();

      return result;
    } catch (e) {
      await clearToken();

      return {
        'success': false,
        'message': 'ออกจากระบบแล้ว',
      };
    }
  }

  // ============================================================
  // ME
  // ============================================================

  static Future<Map<String, dynamic>> me() async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // DASHBOARD
  // ============================================================

  static Future<Map<String, dynamic>> dashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // DORMITORIES - STUDENT
  // ============================================================

  static Future<Map<String, dynamic>> dormitories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dormitories'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> dormitoryDetail(
    int dormitoryId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/dormitories/$dormitoryId',
      ),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // ROOMS - STUDENT
  // ============================================================

  static Future<Map<String, dynamic>> rooms(
    int dormitoryId,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/dormitories/$dormitoryId/rooms',
      ),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> selectRoom({
    required int roomId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/select-room'),
      headers: headers,
      body: jsonEncode({
        'room_id': roomId,
        'start_date': startDate,
        'end_date': endDate,
      }),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>> changeRoom({
  required int roomId,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/change-room'),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token!.isNotEmpty)
        'Authorization': 'Bearer $token',
    },
    body: jsonEncode({
      'room_id': roomId,
    }),
  );

  return _decodeResponse(response);
}

// ============================================================
// CURRENT ROOM
// ============================================================

static Future<Map<String, dynamic>> currentRoom() async {
  final response = await http.get(
    Uri.parse('$baseUrl/current-room'),
    headers: authHeaders,
  );

  return _decodeResponse(response);
}

  // ============================================================
  // BILLS - STUDENT
  // ============================================================

  static Future<Map<String, dynamic>> bills() async {
    final response = await http.get(
      Uri.parse('$baseUrl/bills'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // PAYMENTS - STUDENT
  // ============================================================

  static Future<Map<String, dynamic>> payments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // PAYMENT DETAIL - STUDENT
  // ============================================================

  static Future<Map<String, dynamic>> paymentDetail(
    int paymentId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/$paymentId'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // CREATE PAYMENT - STUDENT
  // ============================================================

  static Future<Map<String, dynamic>> createPayment({
    required int billId,
    required double amount,
    required String paymentMethod,
    File? slipImage,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/payments'),
    );

    request.headers.addAll({
      'Accept': 'application/json',

      if (token != null && token!.isNotEmpty)
        'Authorization': 'Bearer $token',
    });

    request.fields['bill_id'] =
        billId.toString();

    request.fields['amount'] =
        amount.toString();

    request.fields['payment_method'] =
        paymentMethod;

    if (slipImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'slip_image',
          slipImage.path,
        ),
      );
    }

    final streamedResponse =
        await request.send();

    final response =
        await http.Response.fromStream(
      streamedResponse,
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // REPAIRS - STUDENT
  // ============================================================

  static Future<Map<String, dynamic>> repairs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/repairs'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // CREATE REPAIR - STUDENT
  // ============================================================

  static Future<Map<String, dynamic>> createRepair({
    required int roomId,
    required String title,
    required String description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/repairs'),
      headers: headers,
      body: jsonEncode({
        'room_id': roomId,
        'title': title,
        'description': description,
      }),
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // ======================= ADMIN =============================
  // ============================================================

  // ============================================================
  // ADMIN DASHBOARD STATS
  // ============================================================

  static Future<Map<String, dynamic>> adminStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // ADMIN DORMITORIES
  // ============================================================

  static Future<Map<String, dynamic>>
      adminDormitories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dormitories'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>>
      adminCreateDormitory(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/dormitories'),
      headers: headers,
      body: jsonEncode(data),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>>
      adminUpdateDormitory(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/admin/dormitories/$id',
      ),
      headers: headers,
      body: jsonEncode(data),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>>
      adminDeleteDormitory(
    int id,
  ) async {
    final response = await http.delete(
      Uri.parse(
        '$baseUrl/admin/dormitories/$id',
      ),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // ADMIN ROOMS
  // ============================================================

  static Future<Map<String, dynamic>> adminRooms({
    int? dormitoryId,
  }) async {
    final Uri uri;

    if (dormitoryId == null) {
      uri = Uri.parse(
        '$baseUrl/admin/rooms',
      );
    } else {
      uri = Uri.parse(
        '$baseUrl/admin/rooms?dormitory_id=$dormitoryId',
      );
    }

    final response = await http.get(
      uri,
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>>
      adminCreateRoom(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/rooms'),
      headers: headers,
      body: jsonEncode(data),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>>
      adminUpdateRoom(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/rooms/$id'),
      headers: headers,
      body: jsonEncode(data),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>>
      adminDeleteRoom(
    int id,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/rooms/$id'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // ADMIN CONTRACTS
  // ============================================================

  static Future<Map<String, dynamic>>
      adminContracts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/contracts'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // ADMIN BILLS
  // ============================================================

  static Future<Map<String, dynamic>>
      adminBills() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/bills'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>>
      adminCreateBill(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/bills'),
      headers: headers,
      body: jsonEncode(data),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>>
      adminUpdateBill(
    int id,
    Map<String, dynamic> data,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/admin/bills/$id'),
      headers: headers,
      body: jsonEncode(data),
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>>
      adminDeleteBill(
    int id,
  ) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/bills/$id'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // ADMIN PAYMENTS
  // ============================================================

  static Future<Map<String, dynamic>>
      adminPayments() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/payments'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>>
      adminUpdatePaymentStatus(
    int id,
    String status,
  ) async {
    final response = await http.patch(
      Uri.parse(
        '$baseUrl/admin/payments/$id/status',
      ),
      headers: headers,
      body: jsonEncode({
        'status': status,
      }),
    );

    return _decodeResponse(response);
  }

  // ============================================================
  // ADMIN REPAIRS
  // ============================================================

  static Future<Map<String, dynamic>>
      adminRepairs() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/repairs'),
      headers: authHeaders,
    );

    return _decodeResponse(response);
  }

  static Future<Map<String, dynamic>>
      adminUpdateRepairStatus(
    int id,
    String status, {
    String? note,
  }) async {
    final response = await http.patch(
      Uri.parse(
        '$baseUrl/admin/repairs/$id/status',
      ),
      headers: headers,
      body: jsonEncode({
        'status': status,
        'note': note,
      }),
    );

    return _decodeResponse(response);
  }
}