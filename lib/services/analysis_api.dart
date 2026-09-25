import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/analysis_result.dart';

class AnalysisApiException implements Exception {
  const AnalysisApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

class AnalysisApi {
  AnalysisApi({http.Client? client}) : _client = client ?? http.Client();

  static const String baseUrl = String.fromEnvironment(
    'SHELFSIGHT_API_URL',
    defaultValue: 'https://shelfsight-api-lqqn.onrender.com',
  );

  final http.Client _client;

  Future<AnalysisResult> analyze(List<String> imagePaths) async {
    if (imagePaths.isEmpty) {
      throw const AnalysisApiException('At least one shelf photo is required.');
    }

    try {
      // Render free services can be asleep when an audit starts. Wake the
      // service first so cold-start time does not consume the analysis window.
      final health = await _client
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 90));
      if (health.statusCode < 200 || health.statusCode >= 300) {
        throw AnalysisApiException(
          'AI service is unavailable (${health.statusCode}). Please retry.',
        );
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/v1/analyze'),
      )..fields['audit_id'] = 'audit-${DateTime.now().millisecondsSinceEpoch}';

      for (final path in imagePaths) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images',
            path,
            contentType: _imageMediaType(path),
          ),
        );
      }

      final streamed = await _client
          .send(request)
          .timeout(const Duration(minutes: 5));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        var message = 'Analysis failed (${response.statusCode}).';
        try {
          final body = jsonDecode(response.body) as Map<String, dynamic>;
          message = body['detail'] as String? ?? message;
        } catch (_) {}
        throw AnalysisApiException(message);
      }
      return AnalysisResult.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } on SocketException {
      throw const AnalysisApiException(
        'Cannot reach the AI service. Check that the server is running.',
      );
    } on TimeoutException {
      throw const AnalysisApiException(
        'The AI service is taking longer than expected. Please retry in a moment.',
      );
    } on HttpException catch (error) {
      throw AnalysisApiException(error.message);
    } on FormatException {
      throw const AnalysisApiException('The AI service returned invalid data.');
    }
  }

  MediaType _imageMediaType(String path) {
    final extension = path.toLowerCase().split('.').last;
    return switch (extension) {
      'png' => MediaType('image', 'png'),
      'webp' => MediaType('image', 'webp'),
      _ => MediaType('image', 'jpeg'),
    };
  }

  String artifactUrl(String artifact) {
    if (artifact.startsWith('http://') || artifact.startsWith('https://')) {
      return artifact;
    }
    final filename = artifact.split('/').last.split('\\').last;
    return '$baseUrl/artifacts/$filename';
  }
}
