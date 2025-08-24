import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName = 'GenImages';
  static const String apiBaseUrl = 'https://api.studio.nebius.com/v1/';
  static String apiKey = dotenv.env['API_KEY'] ?? '';
}
