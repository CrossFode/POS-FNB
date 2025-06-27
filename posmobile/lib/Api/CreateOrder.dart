import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:posmobile/Model/Model.dart';

final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

Future<OutletResponseById> fetchOutletById(token, outletId) async {
  final url = Uri.parse('$baseUrl/api/outlet/$outletId');

  try {
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);

      print('Outlet Response: $responseBody');

      if (responseBody == null) {
        throw Exception('Received null response from server');
      }

      return OutletResponseById.fromJson(responseBody);
    } else {
      final errorResponse = jsonDecode(response.body);
      final errorMessage = errorResponse['message'] ?? 'Failed to load outlet';
      throw Exception('$errorMessage (Status: ${response.statusCode})');
    }
  } on http.ClientException catch (e) {
    throw Exception('Network error: ${e.message}');
  } on FormatException catch (e) {
    throw Exception('Data parsing error: ${e.message}');
  } catch (e) {
    throw Exception('Unexpected error: $e');
  }
}

Future<CategoryResponse> fetchCategoryinOutlet(token, outletId) async {
  final url = Uri.parse('$baseUrl/api/category/outlet/$outletId');

  try {
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      return CategoryResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load Payment Method: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to load Category: $e');
  }
}

Future<PaymentMethodResponse> fetchPaymentMethod(token, outletId) async {
  final url = Uri.parse('$baseUrl/api/payment');
  try {
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      return PaymentMethodResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load Payment Method: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to load Payment Method: $e');
  }
}

Future<ProductResponse> fetchAllProduct(token, outletId) async {
  final url = Uri.parse('$baseUrl/api/product/ext/outlet/${outletId}');
  try {
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      return ProductResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load outlet: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to load product: $e');
  }
}

Future<DiskonResponse> fetchDiskonByOutlet(token, outletId) async {
  final url = Uri.parse('$baseUrl/api/discount/outlet');
  try {
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    if (response.statusCode == 200) {
      return DiskonResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load discount: ${response.statusCode}');
    }
  } catch (e) {
    throw Exception('Failed to load discount: $e');
  }
}

Future<ReferralCodeResponse> fetchReferralCodes(
    String token, String code) async {
  final url = Uri.parse('$baseUrl/api/referralcode/verified');

  try {
    final request = http.Request('GET', url);
    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    request.body = jsonEncode({'code': code});

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      print('Sukses menggunakan referral');
      return ReferralCodeResponse.fromJson(jsonData);
    } else {
      final errorResponse = jsonDecode(response.body);
      throw Exception(
          errorResponse['message'] ?? 'Failed to verify referral code');
    }
  } catch (e) {
    print('Error verifying referral code: $e');
    throw Exception('Failed to verify referral code: ${e.toString()}');
  }
}

Future<Map<String, dynamic>> makeOrder(
    {required String token, required Order order}) async {
  final url = Uri.parse('$baseUrl/api/order');
  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(order.toJson()),
    );

    print('Request data: ${jsonEncode(order.toJson())}');
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return {
        'success': true,
        'data': responseBody,
        'message': responseBody['message'] ?? 'Order created successfully'
      };
    } else {
      final errorResponse = jsonDecode(response.body);
      return {
        'success': false,
        'message': errorResponse['message'] ?? 'Failed to create order'
      };
    }
  } catch (e) {
    print('Error making order: $e');
    return {'success': false, 'message': 'Connection error: ${e.toString()}'};
  }
}
