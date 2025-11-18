# Settings API Implementation Guide

## Overview
The settings API is automatically called when the user lands on the home page after login. All settings data is parsed (with HTML tags removed from text fields) and saved to SharedPreferences.

## How It Works

### 1. **Automatic API Call**
- When the home screen loads, it automatically fetches settings from `/api/settings`
- The API is called with Bearer token authentication
- Settings are cached in SharedPreferences for offline access

### 2. **HTML Content Parsing**
All HTML fields are automatically stripped of HTML tags to extract clean text:
- `contact_title`: HTML tags removed, extracts "Contact Us" from HTML
- `contact_text`: Extracts plain text
- `side_title`: Extracts plain text
- `side_text`: Extracts plain text

### 3. **Data Storage**
Settings are stored in SharedPreferences under the key `settings_data`.

## Accessing Settings Data

### From Home Screen
```dart
// Get settings from home screen
final homeState = (_HomeScreenState) homeScreenKey.currentState;
final settings = homeState.settings;

// Access specific settings
final contactPhone = settings?.pageSettings.phone ?? '';
final streetAddress = settings?.pageSettings.street ?? '';
final email = settings?.pageSettings.email ?? '';
```

### From Anywhere in the App
```dart
// Get cached settings from SharedPreferences
final settings = await StorageService.getSettings();

if (settings != null) {
  // Access general settings
  final logo = settings.generalSettings.logo;
  final favicon = settings.generalSettings.favicon;
  final title = settings.generalSettings.title;
  final headerPhone = settings.generalSettings.headerPhone;
final defaultImage = settings.generalSettings.defaultImage;
  
  // Access page settings
  final contactEmail = settings.pageSettings.contactEmail;
  final contactSuccess = settings.pageSettings.contactSuccess;
  final street = settings.pageSettings.street;
  final phone = settings.pageSettings.phone;
  final email = settings.pageSettings.email;
  
  // Access pickup locations
  for (var location in settings.pickupLocations) {
    print('Location: ${location.location}');
    print('Phone: ${location.displayPhone}');
    print('Email: ${location.salesEmail}');
  }
}
```

## Settings Model Structure

```dart
class SettingsModel {
  GeneralSettings generalSettings;
  PageSettings pageSettings;
  List<PickupLocation> pickupLocations;
}

class GeneralSettings {
  String logo;
  String favicon;
  String title;
  String copyright;
  String headerPhone;
  String defaultImage;
}

class PageSettings {
  int id;
  String contactSuccess;
  String contactEmail;
  String contactTitle;      // HTML stripped
  String contactText;          // HTML stripped
  String sideTitle;            // HTML stripped
  String sideText;             // HTML stripped
  String street;
  String phone;
  String? fax;
  String email;
  String site;
  String bestSellerBanner;
  String bestSellerBannerLink;
  String bigSaveBanner;
  String bigSaveBannerLink;
  // ... more fields
}

class PickupLocation {
  int id;
  String location;
  String warehouseCode;
  String warehouseShortCode;
  String phone;
  String displayPhone;
  String salesEmail;
  String supportEmail;
  String googleMap;
  int status;
  int timeDifference;
}
```

## API Endpoint
- **Endpoint**: `/api/settings`
- **Method**: GET
- **Authentication**: Bearer token (automatically added)
- **Base URL**: https://www.gurgaonit.com/apc_production_dev/api

## Example Usage

### Display Settings in UI
```dart
// In your widget
FutureBuilder<SettingsModel?>(
  future: StorageService.getSettings(),
  builder: (context, snapshot) {
    if (snapshot.hasData && snapshot.data != null) {
      final settings = snapshot.data!;
      return Column(
        children: [
          Text('Phone: ${settings.generalSettings.headerPhone}'),
          Text('Street: ${settings.pageSettings.street}'),
          Text('Email: ${settings.pageSettings.email}'),
        ],
      );
    }
    return CircularProgressIndicator();
  },
)
```

### Refresh Settings
```dart
// Force refresh settings from API
final settingsService = SettingsService();
final settings = await settingsService.getSettings();
await StorageService.saveSettings(settings);
```

### Check if Settings are Cached
```dart
final settings = await StorageService.getSettings();
if (settings != null) {
  // Settings are available
} else {
  // Settings need to be fetched
}
```

### Clear Settings
```dart
// Clear settings data
await StorageService.clearSettings();
```

## Error Handling
- If the API call fails, a toast message is shown
- Cached settings are used if available
- If no cached settings exist and API fails, the app continues to work without settings

## Notes
- Settings are automatically fetched on home screen load
- HTML content is stripped from text fields automatically
- Settings persist across app restarts via SharedPreferences
- The Bearer token is automatically included in API requests

