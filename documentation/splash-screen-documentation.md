# Splash Screen Documentation

## Overview
The splash screen is the initial screen that appears when the app launches. It handles first-time user detection and intelligent routing based on the user's authentication state and visit history.

## File Location
`lib/features/auth/presentation/pages/splash_screen.dart`

## Purpose
1. Display the app logo with animations while loading
2. Detect if the user is visiting for the first time
3. Check if the user is already logged in
4. Route the user to the appropriate screen based on their state

## User Flow Logic

### Navigation Decision Tree
```
App Launch
    ├─> Check Authentication Token
    │   ├─> Token exists? → Navigate to Home Screen
    │   │
    │   └─> No token → Check Visit History
    │       ├─> First visit (has_visited = null)?
    │       │   ├─> Set has_visited = true
    │       │   └─> Navigate to Registration Selection Screen
    │       │
    │       └─> Returning user (has_visited = true)?
    │           └─> Navigate to Sign In Screen
```

## Implementation Details

### Dependencies
```dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/router_config.dart';
```

### Key Components

#### 1. State Variables
```dart
late AnimationController _animationController;
late Animation<double> _fadeAnimation;
late Animation<double> _scaleAnimation;
final _storage = const FlutterSecureStorage();
```

#### 2. Animations
- **Duration**: 1500ms (1.5 seconds)
- **Fade Animation**: Opacity from 0.0 to 1.0 (0-60% of animation)
- **Scale Animation**: Scale from 0.5 to 1.0 with elastic bounce effect

#### 3. Storage Keys
- `has_visited` - Stores whether the user has visited the app before
- `auth_token` - Stores the user's authentication token

### Navigation Flow

#### Scenario 1: Logged In User
```dart
if (token != null && token.isNotEmpty) {
  // User is logged in, go to home
  context.go(AppRoutes.home);
}
```
**Route**: `/home`

#### Scenario 2: First-Time User
```dart
else if (hasVisited == null) {
  // First-time user, show registration options
  await _storage.write(key: 'has_visited', value: 'true');
  context.go(AppRoutes.registrationSelection);
}
```
**Route**: `/registration-selection`

**What happens:**
- Marks the device as visited
- Shows registration options screen where users can choose:
  - Register with CV
  - Register with LinkedIn
  - Register with Email

#### Scenario 3: Returning User (Not Logged In)
```dart
else {
  // Returning user, show login
  context.go(AppRoutes.signIn);
}
```
**Route**: `/sign-in`

### Timing
- **Animation Duration**: 1.5 seconds
- **Total Display Time**: 3 seconds
- **Navigation Delay**: 3 seconds after `initState`

### Error Handling
```dart
catch (e) {
  print('Error checking first-time user: $e');
  // Default to login on error
  context.go(AppRoutes.signIn);
}
```
On any error, the app defaults to showing the login screen.

## Routes Used

| Route Name | Path | Screen |
|------------|------|--------|
| `AppRoutes.home` | `/home` | Home Dashboard |
| `AppRoutes.registrationSelection` | `/registration-selection` | Registration Options |
| `AppRoutes.signIn` | `/sign-in` | Sign In Screen |

## UI Components

### Logo Display
- Centered logo with white background
- Rounded corners (20px border radius)
- Shadow effect for depth
- Logo size: 100x100px
- Logo path: `assets/images/logo.png`

### Background
- Uses app theme's primary color gradient
- Provides branded appearance during loading

## User Experience Flow

### First Launch Experience
1. User opens app for first time
2. Sees animated Brightwin logo (3 seconds)
3. Automatically redirected to Registration Selection screen
4. Can choose registration method or navigate to login

### Returning User Experience
1. User opens app
2. Sees animated Brightwin logo (3 seconds)
3. Automatically redirected to:
   - **Home screen** if already logged in
   - **Login screen** if session expired

## Security Considerations

### Secure Storage
Uses `flutter_secure_storage` package for:
- Storing authentication tokens securely
- Storing visit history
- All data is encrypted on device

### Session Management
- Checks for valid auth token on every app launch
- If token exists, user bypasses login
- If token is invalid/expired, user must re-authenticate

## Configuration for Different Environments

### Development
The splash screen behavior is consistent across all environments. No special dev configuration needed.

### Production
Same logic applies. The `has_visited` flag is device-specific, so:
- Uninstalling and reinstalling the app resets the flag
- Users will see registration screen again on fresh install
- Auth tokens are also cleared on uninstall

## Testing Scenarios

### Test Case 1: Fresh Install
1. Install app on new device
2. Launch app
3. **Expected**: Navigate to Registration Selection screen
4. **Verify**: `has_visited` is set to 'true' in storage

### Test Case 2: Logged In User
1. User is logged in with valid token
2. Close and reopen app
3. **Expected**: Navigate directly to Home screen

### Test Case 3: Logged Out Returning User
1. User has visited before but is logged out
2. Launch app
3. **Expected**: Navigate to Sign In screen

### Test Case 4: Error Handling
1. Simulate storage error
2. Launch app
3. **Expected**: Default to Sign In screen

## Maintenance Notes

### Modifying Splash Duration
To change how long the splash screen displays:
```dart
await Future.delayed(const Duration(seconds: 3)); // Change this value
```

### Modifying Animation
To adjust animation timing or effects:
```dart
_animationController = AnimationController(
  duration: const Duration(milliseconds: 1500), // Change animation speed
  vsync: this,
);
```

### Adding New Navigation Logic
To add additional routing logic (e.g., onboarding flow):
1. Add storage check for new flag
2. Add new condition in `_checkFirstTimeUser()`
3. Navigate to appropriate route

### Clearing User Data (for Testing)
To reset the first-time user experience:
```dart
await _storage.delete(key: 'has_visited');
await _storage.delete(key: 'auth_token');
```

## Related Files

- **Router Configuration**: `lib/core/config/router_config.dart`
- **Registration Selection**: `lib/features/auth/presentation/pages/registration_selection_page.dart`
- **Sign In Page**: `lib/features/auth/presentation/pages/sign_in_page.dart`
- **Home Page**: `lib/features/home/presentation/pages/home_page.dart`

## Future Enhancements

### Potential Improvements
1. **Version Check**: Check for app updates on splash
2. **Onboarding**: Add multi-screen onboarding flow for first-time users
3. **Offline Detection**: Check internet connectivity and show appropriate message
4. **Dynamic Splash**: Load splash content from backend
5. **A/B Testing**: Different splash experiences for different user segments

## Common Issues & Solutions

### Issue: Stuck on Splash Screen
**Cause**: Navigation context not ready or routing error
**Solution**: Check console for error messages, verify routes are properly configured

### Issue: Always Shows Registration Screen
**Cause**: `has_visited` flag not being saved
**Solution**: Check secure storage permissions, verify write operation completes

### Issue: Animation Not Smooth
**Cause**: Device performance or animation configuration
**Solution**: Adjust animation duration or simplify animation effects

## Code Snippet for Reference

```dart
Future<void> _checkFirstTimeUser() async {
  await Future.delayed(const Duration(seconds: 3));

  if (!mounted) return;

  try {
    final hasVisited = await _storage.read(key: 'has_visited');
    final token = await _storage.read(key: 'auth_token');

    if (token != null && token.isNotEmpty) {
      context.go(AppRoutes.home);
    } else if (hasVisited == null) {
      await _storage.write(key: 'has_visited', value: 'true');
      context.go(AppRoutes.registrationSelection);
    } else {
      context.go(AppRoutes.signIn);
    }
  } catch (e) {
    print('Error checking first-time user: $e');
    context.go(AppRoutes.signIn);
  }
}
```

## Summary

The splash screen is a critical entry point that:
- ✅ Provides a branded first impression
- ✅ Intelligently routes users based on their state
- ✅ Remembers first-time vs. returning users
- ✅ Securely checks authentication status
- ✅ Handles errors gracefully
- ✅ Ensures smooth user onboarding experience
