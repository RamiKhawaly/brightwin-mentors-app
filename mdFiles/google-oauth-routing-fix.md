# Google OAuth Routing Fix - New vs Existing Users

## The Problem

After Google OAuth login, all users were being redirected to the same screen, regardless of whether they were:
- **New users** (just signed up via Google) → Should go to onboarding
- **Existing users** (logging in again) → Should go to dashboard/home

## The Solution

Check the user's profile completeness after OAuth authentication to determine routing:
- **profileCompleteness < 30%** → New user → Redirect to onboarding
- **profileCompleteness >= 30%** → Existing user → Redirect to home

## Implementation

### Flow After OAuth Callback

```
OAuth callback received
        ↓
Extract & store JWT tokens
        ↓
Register FCM token
        ↓
Fetch user profile: GET /api/profile
        ↓
Check profileCompleteness field
        ↓
    ┌───────────┴───────────┐
    ↓                       ↓
< 30%                   >= 30%
New User              Existing User
    ↓                       ↓
Onboarding              Dashboard
```

### Code Changes (main.dart:130-151)

```dart
// Fetch user profile to check completeness
try {
  print('📊 Fetching user profile to check completeness...');
  final profileResponse = await dioClient.dio.get('/api/profile');
  final profileCompleteness = profileResponse.data['profileCompleteness'] as int? ?? 0;

  print('Profile completeness: $profileCompleteness%');

  // If profile is incomplete (< 30%), redirect to onboarding
  // Otherwise, go to home
  if (profileCompleteness < 30) {
    print('→ New user detected, redirecting to onboarding');
    AppRouterConfig.router.go(AppRoutes.mentorOnboarding);
  } else {
    print('→ Existing user detected, redirecting to home');
    AppRouterConfig.router.go(AppRoutes.home);
  }
} catch (e) {
  print('⚠️ Error fetching profile: $e');
  // Default to home if profile fetch fails
  AppRouterConfig.router.go(AppRoutes.home);
}
```

## Profile Completeness Values (Backend)

The `profileCompleteness` field is calculated by the backend based on filled profile fields:

### New OAuth User (Google)
- **Initial value**: 0-10%
- **Has**: firstName, lastName, email, imageUrl (from Google)
- **Missing**: All other profile fields

### Partially Complete Profile
- **Value**: 30-70%
- **Has**: Basic info + some additional fields (bio, location, etc.)

### Complete Profile
- **Value**: 70-100%
- **Has**: Most or all profile fields filled

## User Experience

### New User (First Time with Google)

1. User clicks "Sign in with Google"
2. Browser opens, user authenticates with Google
3. App receives OAuth callback
4. Backend creates new user account (profileCompleteness = 0%)
5. App detects profileCompleteness < 30%
6. **→ Redirects to onboarding** (mentor_onboarding_page.dart)
7. User completes onboarding process
8. Profile completeness increases
9. User can now access full app

### Existing User (Logging In Again)

1. User clicks "Sign in with Google"
2. Browser opens, user authenticates with Google
3. App receives OAuth callback
4. Backend finds existing user (profileCompleteness >= 30%)
5. App detects profileCompleteness >= 30%
6. **→ Redirects to home** (home_page.dart)
7. User immediately sees dashboard

## Why 30% Threshold?

- **New users** from OAuth have 0-10% completeness (only basic info from Google)
- **Users who completed onboarding** have at least 30% completeness
- **30% threshold** clearly differentiates new vs returning users
- **Fail-safe**: If profile fetch fails, default to home (better UX than blocking access)

## Endpoints Used

### 1. OAuth Callback Handler
```
Deep Link: brightwin://oauth2/redirect?token=...&refreshToken=...
```

### 2. Get User Profile
```
GET /api/profile
Authorization: Bearer {token}

Response:
{
  "id": 123,
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "profileCompleteness": 0,  // or 50, or 100, etc.
  ...
}
```

## Testing

### Test as New User

1. Use a Google account that hasn't signed up before
2. Click "Sign in with Google"
3. Complete Google authentication
4. **Expected**: App redirects to onboarding page
5. Complete onboarding
6. **Expected**: Profile completeness increases, can access app

### Test as Existing User

1. Use a Google account that has already completed onboarding
2. Click "Sign in with Google"
3. Complete Google authentication
4. **Expected**: App redirects directly to home/dashboard

### Test Profile Fetch Failure

1. Turn off backend server
2. Complete OAuth login
3. **Expected**: App defaults to home page (fail-safe behavior)

## Regular Email/Password Login

**Note**: Regular email/password login already goes directly to home. This routing logic is **only for OAuth login** because:
- OAuth can create new users on-the-fly
- Regular login requires existing account (created via registration)
- Registration flow already includes onboarding

## Build Status

✅ Code compiled successfully
✅ Debug APK built successfully (56.8s)
✅ Profile completeness check added
✅ Smart routing implemented

## Summary

The OAuth callback handler now:
1. ✅ Authenticates user
2. ✅ Stores JWT tokens
3. ✅ Registers FCM token
4. ✅ **Fetches user profile**
5. ✅ **Checks profile completeness**
6. ✅ **Routes based on completeness**:
   - New user → Onboarding
   - Existing user → Home
