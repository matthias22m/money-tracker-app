import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService {
  final Dio _dio = Dio();

  /// Upload image to Cloudinary
  Future<String?> uploadImage(File imageFile, {String? folder}) async {
    try {
      // Check if file exists
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      debugPrint('📤 Uploading image to Cloudinary...');
      debugPrint('📁 File size: ${await imageFile.length()} bytes');

      // Try with basic upload first (no transformations)
      return await _uploadBasic(imageFile, folder);
    } catch (e) {
      debugPrint('❌ Failed to upload image to Cloudinary: $e');

      // Provide more specific error messages
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          debugPrint('🔍 Connection timeout - check your internet connection');
        } else if (e.type == DioExceptionType.receiveTimeout) {
          debugPrint('🔍 Server response timeout');
        } else if (e.response?.statusCode == 400) {
          debugPrint('🔍 Bad request - check your upload parameters');
        } else if (e.response?.statusCode == 401) {
          debugPrint('🔍 Unauthorized - check your Cloudinary credentials');
        } else if (e.response?.statusCode == 500) {
          debugPrint(
            '🔍 Server error - check your upload preset configuration',
          );
          debugPrint(
            '💡 Tip: Create upload preset "ml_default" in Cloudinary dashboard',
          );
        }
      }

      rethrow;
    }
  }

  /// Basic upload without transformations
  Future<String?> _uploadBasic(File imageFile, String? folder) async {
    // Create a simpler FormData without optional parameters
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        imageFile.path,
        filename: imageFile.path.split('/').last,
      ),
      'upload_preset': CloudinaryConfig.uploadPreset,
    });

    // Add optional parameters only if they're not null/empty
    if (folder != null && folder.isNotEmpty) {
      formData.fields.add(MapEntry('folder', folder));
    }

    debugPrint('📋 Upload parameters:');
    debugPrint('  - upload_preset: ${CloudinaryConfig.uploadPreset}');
    debugPrint('  - folder: ${folder ?? CloudinaryConfig.defaultFolder}');
    debugPrint('  - file: ${imageFile.path}');

    final response = await _dio.post(
      CloudinaryConfig.uploadUrl,
      data: formData,
      options: Options(
        headers: {'Content-Type': 'multipart/form-data'},
        sendTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final imageUrl = data['secure_url'] as String?;

      debugPrint('✅ Image uploaded successfully to Cloudinary');
      debugPrint('🔗 Image URL: $imageUrl');

      return imageUrl;
    } else {
      debugPrint('❌ Upload failed with status: ${response.statusCode}');
      debugPrint('❌ Response data: ${response.data}');
      debugPrint('❌ Response headers: ${response.headers}');
      throw Exception('Upload failed with status: ${response.statusCode}');
    }
  }

  /// Delete image from Cloudinary (requires signed upload)
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) {
        debugPrint('⚠️ No image URL provided for deletion');
        return;
      }

      debugPrint('🗑️ Deleting image from Cloudinary: $imageUrl');

      // Extract public_id from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 3) {
        throw Exception('Invalid Cloudinary URL format');
      }

      final publicId = pathSegments[pathSegments.length - 1].split('.')[0];

      // Generate signature for deletion (for signed uploads)
      // For now, we'll just log the deletion attempt
      // In production, you'd want to implement proper signature generation
      debugPrint(
        '⚠️ Image deletion not implemented - Cloudinary images are typically permanent',
      );
      debugPrint('🔗 Public ID: $publicId');
    } catch (e) {
      debugPrint('❌ Failed to delete image from Cloudinary: $e');
      // Don't rethrow - deletion failures shouldn't break the app
    }
  }

  /// Get optimized image URL with transformations using the official SDK
  String getOptimizedUrl(
    String originalUrl, {
    int? width,
    int? height,
    String crop = 'fill',
    String quality = 'auto',
  }) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl; // Return original URL if not from Cloudinary
    }

    try {
      // Extract public_id from the URL
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 3) {
        return originalUrl;
      }

      final publicId = pathSegments[pathSegments.length - 1].split('.')[0];

      // Build optimized URL with transformations
      String transformation = '';
      if (width != null && height != null) {
        transformation += 'w_$width,h_$height,c_$crop/';
      }
      transformation += 'q_$quality/';

      return 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/$transformation$publicId';
    } catch (e) {
      debugPrint('⚠️ Failed to generate optimized URL: $e');
      return originalUrl; // Return original URL as fallback
    }
  }

  /// Generate a profile image URL with face detection and optimization
  String getProfileImageUrl(String originalUrl) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }

    try {
      final uri = Uri.parse(originalUrl);
      final pathSegments = uri.pathSegments;

      if (pathSegments.length < 3) {
        return originalUrl;
      }

      final publicId = pathSegments[pathSegments.length - 1].split('.')[0];

      // Build transformation string for profile image
      const transformation = 'w_400,h_400,c_fill,g_face,q_auto,f_auto/';

      return 'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/$transformation$publicId';
    } catch (e) {
      debugPrint('⚠️ Failed to generate profile image URL: $e');
      return originalUrl;
    }
  }

  /// Validate Cloudinary configuration
  static bool isConfigured() {
    return CloudinaryConfig.isConfigured;
  }

  /// Get configuration status for debugging
  static Map<String, bool> getConfigStatus() {
    return CloudinaryConfig.configStatus;
  }
}
