# RoomStyler Test Plan

## Overview
This document outlines the testing strategy for the RoomStyler Flutter application. The tests are organized to ensure code quality, prevent regressions, and maintain a high level of confidence in the application's functionality.

## Test Structure
```
test/
├── widget_test.dart                    # Basic smoke test
├── app_test.dart                      # App-level integration tests
├── router_test.dart                   # Router tests
├── features/                          # Feature-specific tests
│   ├── auth_test.dart                # Authentication screens tests
│   ├── catalog_screen_test.dart      # Catalog screen tests
│   ├── editor_screen_test.dart       # Editor screen tests
│   ├── home_screen_test.dart         # Home screen tests
│   ├── my_page_test.dart             # My page tests
│   ├── preview_share_screen_test.dart # Preview/share screen tests
│   └── room_upload_screen_test.dart   # Room upload screen tests
├── models/                            # Data model tests
│   └── model_test.dart               # Model tests
├── state/                             # State management tests
│   ├── scene_provider_test.dart      # Scene provider tests
│   ├── theme_provider_test.dart      # Theme provider tests
│   └── wishlist_provider_test.dart   # Wishlist provider tests
└── utils/                             # Utility function tests
    └── utils_test.dart               # Utility tests
```

## Test Categories

### 1. Widget Tests
These tests verify the UI components render correctly and respond to user interactions.

**Files:**
- `widget_test.dart`: Basic smoke test to ensure the app can run
- `home_screen_test.dart`: Tests for the home screen UI elements
- `auth_test.dart`: Tests for sign in and sign up screens
- `my_page_test.dart`: Tests for the my page menu items

### 2. Integration Tests
These tests verify that different parts of the application work together correctly.

**Files:**
- `app_test.dart`: High-level integration tests for the entire app

### 3. Unit Tests
These tests verify the business logic and state management.

**Files:**
- `theme_provider_test.dart`: Tests for the theme provider logic

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test Files
```bash
# Run home screen tests
flutter test test/features/home_screen_test.dart

# Run auth tests
flutter test test/features/auth_test.dart

# Run my page tests
flutter test test/features/my_page_test.dart

# Run theme provider tests
flutter test test/state/theme_provider_test.dart
```

## Adding New Tests

### 1. Create a new test file
When adding new features, create a corresponding test file in the appropriate directory:
- For new screens: `test/features/feature_name_test.dart`
- For new state management: `test/state/provider_name_test.dart`

### 2. Follow the existing pattern
Use the `group` and `testWidgets` functions to organize tests:
```dart
void main() {
  group('Feature Name Tests', () {
    testWidgets('Test description', (WidgetTester tester) async {
      // Test implementation
    });
  });
}
```

### 3. Test key interactions
For widget tests, focus on:
- Verifying UI elements are present
- Testing user interactions (taps, scrolls, etc.)
- Checking state changes after interactions

## Best Practices

1. **Keep tests isolated**: Each test should be independent and not rely on the state from other tests.

2. **Use descriptive test names**: Test names should clearly describe what is being tested and what the expected outcome is.

3. **Test edge cases**: In addition to happy path scenarios, test error conditions and edge cases.

4. **Mock external dependencies**: When testing components that depend on external services (Firebase, APIs), use mocks to isolate the component under test.

5. **Run tests regularly**: Run tests frequently during development to catch regressions early.

## Continuous Integration
The test suite should be run automatically in your CI/CD pipeline to ensure that all changes pass tests before being merged.