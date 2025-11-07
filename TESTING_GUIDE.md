# Testing Guide - Hierarchical Categories

## 🧪 Test Mode Enabled

The app is now set to use **dummy data** for testing. You can test the complete navigation flow without needing the actual API.

## 📍 How to Test

### Test Scenario 1: Category with Subcategories
1. **Open the app** and navigate to Categories (from home page or categories grid)
2. **Tap on Category 1** (or any category with ID 1)
   - ✅ Should show **SubCategory pages** (2 subcategories)
3. **Tap on SubCategory 1** (SubCategory 11)
   - ✅ Should show **ChildCategory pages** (2 child categories)
4. **Tap on any ChildCategory**
   - ✅ Should show **Product Listing** with 8 dummy products

### Test Scenario 2: Category without Subcategories
1. **Tap on Category 3** (or any category with ID 3+)
   - ✅ Should directly show **Product Listing** (skips subcategories)

### Test Scenario 3: SubCategory without ChildCategories
1. **Navigate to Category 1 → SubCategory 2** (SubCategory 12)
   - ✅ Should directly show **Product Listing** (skips childcategories)

## 🔧 Test Data Structure

The dummy data creates:
- **Categories**: Category 1, Category 2 have subcategories; others don't
- **SubCategories**: For Category 1, SubCategory 11 has childcategories; SubCategory 12 doesn't
- **ChildCategories**: Always 2 childcategories per subcategory (when available)
- **Products**: 8 products per category/subcategory/childcategory

## 🎨 Test Features

✅ **Navigation Flow**:
- Category → SubCategory → ChildCategory → Products
- Automatic level skipping when no data exists

✅ **UI Design**:
- Uses existing design patterns
- Shows category images from assets folder
- Grid layout for categories
- Product cards for products

✅ **Loading States**:
- Shows loading indicators while fetching
- Handles errors gracefully

## 🔄 Switching to Real API

When ready to use real API:
1. Open `lib/data/services/homepage_service.dart`
2. Change `useDummyData` from `true` to `false`:
   ```dart
   static const bool useDummyData = false;
   ```

## 🐛 Troubleshooting

- **If categories don't show**: Check if homepage API is returning categories
- **If navigation doesn't work**: Check console logs for errors
- **If images don't load**: Make sure asset images exist in `assets/images/`

## 📝 What to Test

- [ ] Category grid displays correctly
- [ ] Category tap navigates to subcategories (when available)
- [ ] Category tap navigates to products (when no subcategories)
- [ ] SubCategory page displays correctly
- [ ] SubCategory tap navigates to childcategories (when available)
- [ ] SubCategory tap navigates to products (when no childcategories)
- [ ] ChildCategory page displays correctly
- [ ] ChildCategory tap navigates to products
- [ ] Product listing shows products correctly
- [ ] Loading states work
- [ ] Error handling works
- [ ] Back navigation works at all levels

## 🚀 Run the App

```bash
flutter run
```

Navigate through the categories and test all the flows!


