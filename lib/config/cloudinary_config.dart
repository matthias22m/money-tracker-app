/// Cloudinary Configuration
///
/// IMPORTANT: Replace these placeholder values with your actual Cloudinary credentials
/// You can find these in your Cloudinary Dashboard: https://cloudinary.com/console
class CloudinaryConfig {
  // Replace 'your_cloud_name' with your actual Cloudinary cloud name
  static const String cloudName = 'dap7k9vho';

  // Replace 'your_api_key' with your actual Cloudinary API key
  static const String apiKey = '778382445893842';

  // Replace 'your_api_secret' with your actual Cloudinary API secret
  static const String apiSecret = 'ujq858I6ClAvQ2hDfC5DqD_ejVg';

  static const String uploadPreset = 'flutter_upload';

  // Default folder for profile images
  static const String defaultFolder = 'profile_images';

  /// Check if configuration is properly set up
  static bool get isConfigured {
    return cloudName.isNotEmpty &&
        apiKey.isNotEmpty &&
        apiSecret.isNotEmpty &&
        cloudName != 'your_cloud_name' &&
        apiKey != 'your_api_key' &&
        apiSecret != 'your_api_secret';
  }

  /// Get configuration status for debugging
  static Map<String, bool> get configStatus {
    return {
      'cloudName': cloudName.isNotEmpty && cloudName != 'your_cloud_name',
      'apiKey': apiKey.isNotEmpty && apiKey != 'your_api_key',
      'apiSecret': apiSecret.isNotEmpty && apiSecret != 'your_api_secret',
      'uploadPreset': uploadPreset.isNotEmpty,
    };
  }

  /// Get Cloudinary upload URL
  static String get uploadUrl {
    return 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  }
}
