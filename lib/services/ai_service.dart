import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AiService {
  final Duration timeoutDuration = const Duration(seconds: 30);

  /// Tests connection to the Flask backend.
  Future<String> pingServer() async {
    try {
      final response = await http.get(Uri.parse(ServerConfig.baseUrl)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return 'Backend Connected ✅';
      }
      return 'Backend Offline ❌: HTTP ${response.statusCode}';
    } on TimeoutException {
      return 'Backend Offline ❌: Timeout';
    } on SocketException {
      return 'Backend Offline ❌: Socket Exception';
    } catch (e) {
      return 'Backend Offline ❌: $e';
    }
  }

  /// Analyzes a medical report image via the Flask backend.
  Future<Map<String, dynamic>?> analyzeReport({required File imageFile, required String panelType}) async {
    String formattedPanel = '';
    
    // 1. Determine correct endpoint based on panel type
    String lowerPanel = panelType.toLowerCase();
    if (lowerPanel.contains('cbc')) {
      formattedPanel = 'cbc';
    } else if (lowerPanel.contains('lft')) {
      formattedPanel = 'lft';
    } else if (lowerPanel.contains('metabolic') || lowerPanel.contains('diabetes') || lowerPanel.contains('diabete')) {
      formattedPanel = 'diabetes';
    } else {
      throw Exception('Unsupported panel type: $panelType');
    }

    try {
      // 2. Prepare the multipart request
      String base = ServerConfig.baseUrl;
      if (base.endsWith('/')) {
        base = base.substring(0, base.length - 1);
      }
      final String fullUrl = '$base/scan/$formattedPanel';
      print('Connecting to AI Backend: $fullUrl');
      var request = http.MultipartRequest('POST', Uri.parse(fullUrl));
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
      
      // 3. Send request with timeout
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw Exception('The AI server took too long to process the image. Please try a clearer or smaller photo.');
        },
      );
      var response = await http.Response.fromStream(streamedResponse);

      // 4. Handle response
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse;
        } else {
          throw Exception(jsonResponse['error'] ?? 'Server returned an error');
        }
      } else {
        try {
          final errorJson = json.decode(response.body);
          throw Exception(errorJson['error'] ?? 'Failed to connect to AI server');
        } catch (_) {
          throw Exception('Failed to connect to AI server. Status: ${response.statusCode}');
        }
      }
    } on SocketException {
      throw Exception('Network error: Unable to connect to the AI server. Please check if the Flask server is running at ${ServerConfig.baseUrl}.');
    } on TimeoutException {
      throw Exception('Timeout error: The AI server took too long to respond (exceeded 30 seconds).');
    } catch (e) {
      throw Exception('An unexpected error occurred during AI analysis: $e');
    }
  }
}
