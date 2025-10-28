# Login API Implementation

## Overview
Complete login API integration for Flutter using Provider state management, Repository Pattern, and http package.

## Architecture

### Layers
1. **Network Layer** (`lib/core/network/`)
   - `api_client.dart` - HTTP client with timeout and error handling
   - `api_endpoints.dart` - API endpoints configuration
   - `network_checker.dart` - Internet connectivity checker

2. **Exception Layer** (`lib/core/exceptions/`)
   - `api_exception.dart` - Custom API exception handling

3. **Data Layer** (`lib/data/`)
   - **Models** (`models/user_model.dart`)
     - `UserModel` - User data model
     - `LoginResponse` - Login response model
   
   - **Services** (`services/auth_service.dart`)
     - `AuthService` - API service for authentication
   
   - **Repositories** (`repositories/auth_repository.dart`)
     - `AuthRepository` - Repository pattern for data operations

4. **Provider Layer** (`lib/providers/`)
   - `auth_provider.dart` - Provider for authentication state management

5. **UI Layer** (`lib/ui/screens/`)
   - `signin_view/signin.dart` - Sign in screen with provider integration

## API Configuration

### Base URL
```
https://www.gurgaonit.com/apc_production_dev/api/
```

### Login Endpoint
- **Method**: POST
- **Endpoint**: `/login`
- **Content-Type**: `application/x-www-form-urlencoded`

### Request Body
```dart
{
  'email': 'user@example.com',
  'password': 'password123'
}
```

### Response Format
```json
{
  "access_token": "6|SdinBF3jBZAKH6AxNRlptKwPJQaDYd7tAaEhFY3r1079d4f5",
  "token_type": "Bearer",
  "user": {
    "id": 2302,
    "name": "Vikram Soni",
    "email": "vikram@vmail.in",
    "phone": "0400000000",
    "area_code": "02",
    "landline": "11111111",
    "unit_apartmentno": "1",
    "address": "India",
    "city": "India",
    "state": "ACT",
    "country": "AU",
    "zip": "3001",
    "is_trade_user": 0,
    "special_user": 0
  }
}
```

## Usage

### 1. Provider Setup
Already configured in `lib/main.dart`:
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
  ],
  child: MaterialApp(...),
)
```

### 2. Using AuthProvider
```dart
// Get provider instance
final authProvider = Provider.of<AuthProvider>(context, listen: false);

// Login
final success = await authProvider.login(
  email: 'user@example.com',
  password: 'password123',
);

if (success) {
  // Navigate to main screen
} else {
  // Show error message
  print(authProvider.errorMessage);
}
```

### 3. Access User Data
```dart
final authProvider = Provider.of<AuthProvider>(context);

// Check if logged in
if (authProvider.isLoggedIn) {
  // Get user data
  final user = authProvider.currentUser;
  final token = authProvider.accessToken;
  
  // Check user type
  final isTradeUser = authProvider.isTradeUser;
  final isSpecialUser = authProvider.isSpecialUser;
}
```

### 4. Logout
```dart
authProvider.logout();
```

## State Management

### States
- `isLoading` - Loading state during API call
- `errorMessage` - Error message if API call fails
- `currentUser` - Current user data
- `accessToken` - Access token for authenticated requests

### Getters
- `isLoggedIn` - Check if user is logged in
- `isTradeUser` - Check if user is trade user
- `isSpecialUser` - Check if user is special user

## Error Handling

The implementation includes comprehensive error handling:

1. **Network Errors**: Handled with timeout and connection checks
2. **API Errors**: Custom exceptions with status codes
3. **User-Friendly Messages**: Displayed via SnackBar

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.5.0
  provider: ^6.1.2
```

## Features

✅ Clean Architecture with Repository Pattern
✅ Provider State Management
✅ Loading State Indicator
✅ Error Handling & Display
✅ Form Validation
✅ Null-Safe Code
✅ Production-Ready Implementation
✅ Easy to Extend for More APIs

## Next Steps

To add more API endpoints:

1. **Add endpoint** in `lib/core/network/api_endpoints.dart`:
```dart
static const String newEndpoint = '/new-endpoint';
```

2. **Create service method** in `lib/data/services/auth_service.dart`:
```dart
Future<ResponseModel> newMethod(params) async {
  final response = await ApiClient.post(
    endpoint: ApiEndpoints.newEndpoint,
    body: params,
  );
  return ResponseModel.fromJson(response);
}
```

3. **Add repository method** in `lib/data/repositories/auth_repository.dart`
4. **Add provider method** in `lib/providers/auth_provider.dart`
5. **Use in UI** with Provider

## Files Created/Modified

### Created
- `lib/core/exceptions/api_exception.dart`
- `lib/core/network/api_client.dart`
- `lib/core/network/api_endpoints.dart`
- `lib/core/network/network_checker.dart`
- `lib/core/utils/logger.dart`
- `lib/data/models/user_model.dart`
- `lib/data/services/auth_service.dart`
- `lib/data/repositories/auth_repository.dart`
- `lib/providers/auth_provider.dart`

### Modified
- `pubspec.yaml` - Added http and provider dependencies
- `lib/main.dart` - Added MultiProvider
- `lib/ui/screens/signin_view/signin.dart` - Integrated login functionality

