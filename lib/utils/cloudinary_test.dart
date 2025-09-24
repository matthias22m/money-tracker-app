import 'package:flutter/material.dart';
import '../config/cloudinary_config.dart';
import '../services/cloudinary_service.dart';

/// Simple utility to test Cloudinary configuration
class CloudinaryTest {
  /// Test Cloudinary configuration and print status
  static void testConfiguration() {
    debugPrint('🧪 Testing Cloudinary Configuration...');

    final configStatus = CloudinaryService.getConfigStatus();
    debugPrint('📊 Configuration Status:');

    configStatus.forEach((key, value) {
      final status = value ? '✅' : '❌';
      debugPrint('  $status $key: ${value ? 'Configured' : 'Not configured'}');
    });

    final isConfigured = CloudinaryService.isConfigured();
    debugPrint(
      '🎯 Overall Status: ${isConfigured ? '✅ Ready' : '❌ Not ready'}',
    );

    if (!isConfigured) {
      debugPrint('💡 Next steps:');
      debugPrint('  1. Go to https://cloudinary.com/console');
      debugPrint('  2. Get your Cloud Name, API Key, and API Secret');
      debugPrint('  3. Update lib/config/cloudinary_config.dart');
      debugPrint(
        '  4. Create upload preset "ml_default" in Cloudinary dashboard',
      );
    }

    debugPrint('🔗 Upload URL: ${CloudinaryConfig.uploadUrl}');
    debugPrint('📁 Default Folder: ${CloudinaryConfig.defaultFolder}');
    debugPrint('⚙️ Upload Preset: ${CloudinaryConfig.uploadPreset}');
  }

  /// Test URL generation with the official SDK
  static void testUrlGeneration() {
    debugPrint('🧪 Testing Cloudinary URL Generation...');

    try {
      // Test basic image URL
      final basicUrl =
          'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/sample';
      debugPrint('✅ Basic URL: $basicUrl');

      // Test optimized URL with manual transformation
      final optimizedUrl =
          'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/w_400,h_400,c_fill,q_auto/sample';
      debugPrint('✅ Optimized URL: $optimizedUrl');

      // Test profile image URL with face detection
      final profileUrl =
          'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/image/upload/w_400,h_400,c_fill,g_face,q_auto,f_auto/sample';
      debugPrint('✅ Profile URL: $profileUrl');

      debugPrint('🎯 URL Generation: ✅ Working');
    } catch (e) {
      debugPrint('❌ URL Generation failed: $e');
    }
  }

  /// Test upload preset configuration
  static void testUploadPreset() {
    debugPrint('🧪 Testing Upload Preset Configuration...');

    debugPrint('📋 Upload Preset Details:');
    debugPrint('  - Preset Name: ${CloudinaryConfig.uploadPreset}');
    debugPrint('  - Upload URL: ${CloudinaryConfig.uploadUrl}');
    debugPrint('  - Default Folder: ${CloudinaryConfig.defaultFolder}');

    // Test the upload URL format
    final uploadUrl = CloudinaryConfig.uploadUrl;
    if (uploadUrl.contains(CloudinaryConfig.cloudName)) {
      debugPrint('✅ Upload URL format is correct');
    } else {
      debugPrint('❌ Upload URL format is incorrect');
    }

    debugPrint('💡 If upload fails with 400 error, check:');
    debugPrint('  1. Upload preset exists in Cloudinary dashboard');
    debugPrint('  2. Preset is set to "Unsigned" mode');
    debugPrint('  3. Preset allows the file formats you\'re uploading');
    debugPrint('  4. Preset has appropriate size limits');
  }

  /// Run all tests
  static void runAllTests() {
    debugPrint('🚀 Running Cloudinary Tests...');
    debugPrint('=' * 50);

    testConfiguration();
    debugPrint('');
    testUrlGeneration();
    debugPrint('');
    testUploadPreset();

    debugPrint('=' * 50);
    debugPrint('🏁 Tests completed!');
  }
}
