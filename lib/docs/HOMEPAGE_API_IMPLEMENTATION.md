# Homepage API Implementation

## Overview
This document describes the implementation of the `/homepage-settings` API endpoint integration for displaying dynamic homepage content.

## API Endpoint
- **URL**: `/homepage-settings`
- **Method**: GET
- **Requires Auth**: No

## Response Structure
The API returns an object containing the following arrays:

### Response Format
```json
{
  "partners": [],
  "services": [],
  "sliders": [],
  "all_banners": [],
  "categories": []
}
```

## Data Models

### Partner Object
- `id` (int)
- `photo` (string): Partner logo URL
- `link` (string): Partner link
- `p_title` (string, nullable): Partner title

### Service Object
- `id` (int)
- `user_id` (int)
- `title` (string)
- `details` (string)
- `photo` (string): Service image URL
- `s_title` (string, nullable)

### Slider Object
- `id` (int)
- `photo` (string): Slider image URL
- `link` (string, nullable)
- `title` (string, nullable)

### Banner Object
- `id` (int)
- `photo` (string): Banner image URL
- `link` (string, nullable)
- `title` (string, nullable)

### Category Object
- `id` (int)
- `name` (string)
- `displayOrder` (string)
- `slug` (string)
- `status` (int)
- `photo` (string): Category icon URL
- `is_featured` (int)
- `image` (string, nullable): Category image URL

## Implementation Details

### Files Created
1. **lib/data/models/homepage_model.dart**
   - Contains data models for all homepage entities
   - Includes Partner, Service, Slider, Banner, and Category classes
   - Includes HomepageModel wrapper class

2. **lib/data/services/homepage_service.dart**
   - Service class for fetching homepage data
   - Implements error handling and logging

### Files Modified
1. **lib/core/network/api_endpoints.dart**
   - Added `homepageSettings` endpoint constant

2. **lib/ui/screens/home_view/home.dart**
   - Integrated homepage API data
   - Displays dynamic categories from API
   - Shows only 5 categories initially
   - Added "See All" button that navigates to full categories page
   - Implemented loading state while fetching data

3. **pubspec.yaml**
   - Added `cached_network_image` package dependency

## Categories Display Logic

### Initial Display
- Shows only the first 5 categories from the API
- Displays category image using the `image` field from the API
- Shows category name
- Uses `CachedNetworkImage` for efficient image loading

### "See All" Button
- Added as the 6th item in the grid
- Navigates to `CategoriesGridScreen` when tapped
- Displays an add icon and "See all categories" text

### Loading State
- Shows loading indicators while data is being fetched
- Displays error toast if API call fails

## Usage

### Fetching Homepage Data
```dart
final homepageService = HomepageService();
final homepageData = await homepageService.getHomepageData();
```

### Accessing Categories
```dart
final categories = homepageData.categories;
```

### Accessing Other Data
```dart
final partners = homepageData.partners;
final services = homepageData.services;
final sliders = homepageData.sliders;
final banners = homepageData.allBanners;
```

## Future Enhancements
- Implement full category grid page using API data
- Add slider/banner display logic
- Display partners and services sections
- Add pull-to-refresh functionality

