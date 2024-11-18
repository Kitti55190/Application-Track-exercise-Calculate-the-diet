class AppConfig {
  static const bool isDevelopment = true;

  // Base URLs
  static const String devBaseUrl = 'http://192.168.159.195:3000';
  static const String prodBaseUrl = 'https://your-production-url.com';
  
  // Get current base URL based on environment
  static String get baseUrl => isDevelopment ? devBaseUrl : prodBaseUrl;

  // API Endpoints
  static String get loginUrl => '$baseUrl/api/auth/login';
  static String get registerSurveyUrl => '$baseUrl/api/register-survey';
  static String get mealsUrl => '$baseUrl/api/meals';
  
  // User specific endpoints
  static String getUserExercisesUrl(String userId) => '$baseUrl/api/users/$userId/exercises';
  static String getUserTdeeUrl(String userId) => '$baseUrl/api/tdee/user/$userId/tdee';
  
  // Meal endpoints
  static String getMealUrl(String mealId) => '$baseUrl/api/meals/$mealId';
  static String get addMealUrl => '$baseUrl/api/meals/add';
}