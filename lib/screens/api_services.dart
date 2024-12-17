import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = 'http://10.0.2.2:5000';

  // Login API
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({"email": email, "password": password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Invalid credentials. Please try again.');
      }
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  // Fetch Deliveries API
  Future<Map<String, dynamic>> getDeliveries(String token, String role, {String? userId}) async {
    final url = Uri.parse('$baseUrl/deliveries');
    try {
      final response = await http.get(
        url.replace(queryParameters: {"role": role, "user_id": userId}),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch deliveries');
      }
    } catch (e) {
      throw Exception('Error fetching deliveries: $e');
    }
  }

  // Mark Delivery as Complete API (Placeholder for Future Use)
  Future<void> completeDelivery(String token, int deliveryId, List<String> images) async {
    final url = Uri.parse('$baseUrl/deliveries/complete');
    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: json.encode({
          "delivery_id": deliveryId,
          "delivery_images": images,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark delivery as complete');
      }
    } catch (e) {
      throw Exception('Error completing delivery: $e');
    }
  }
}
