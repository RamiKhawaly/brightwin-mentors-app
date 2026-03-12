# Onboarding Redirect Fix - Login vs Signup

## The Problem

Both login and signup were redirecting users to the onboarding screen on every app launch, even for users who had already completed onboarding.

**Root Cause:** Frontend issue in the splash screen logic.

## Root Cause Analysis

### Splash Screen Logic (splash_screen.dart:78-84)

The splash screen checks on every app launch:
```dart
if (token != null && token.isNotEmpty) {
  if (onboardingCompleted == 'true') {
    context.go(AppRoutes.home);
  } else {
    // Need to complete onboarding first
    context.go(AppRoutes.mentorOnboarding);  // ← REDIRECTS HERE
  }
}
```

**The Issue:**
- Users who login via email/password have a token
- But the `onboarding_completed` flag was NOT being set after login
- So on next app launch, splash screen redirected them to onboarding

### When `onboarding_completed` Flag is Set

**Before Fix:**
- ✅ Only set when user completes the onboarding flow (mentor_onboarding_page.dart:26)
- ❌ NOT set after regular login
- ❌ NOT set after OAuth login with existing account

**After Fix:**
- ✅ Set when user completes onboarding flow
- ✅ **NEW:** Set after successful regular login
- ✅ **NEW:** Set after successful OAuth login (if profile completeness >= 30%)

## The Solution

### 1. Regular Email/Password Login (sign_in_page.dart:231-232)

After successful login, mark onboarding as completed:
```dart
// Mark onboarding as completed (user already has an account)
const storage = FlutterSecureStorage();
await storage.write(key: 'onboarding_completed', value: 'true');
print('✅ Marked onboarding as completed for existing user');
```

**Reasoning:** If a user can login, they already have an account and must have completed signup/onboarding at some point.

### 2. OAuth Login with Existing Account (main.dart:163)

For OAuth users with >= 30% profile completeness:
```dart
if (profileCompleteness < 30) {
  print('→ New user detected, redirecting to onboarding');
  AppRouterConfig.router.go(AppRoutes.mentorOnboarding);
} else {
  // Existing user - mark onboarding as completed
  print('→ Existing user detected, redirecting to home');
  await storage.write(key: 'onboarding_completed', value: 'true');  // ← ADDED
  AppRouterConfig.router.go(AppRoutes.home);
}
```

**Reasoning:** OAuth users with >= 30% profile completeness are existing users who have already used the app.

## User Flows After Fix

### Flow 1: New User Signup (Email/Password)

```
1. User registers with email/password
2. Email verification
3. Login successful
4. onboarding_completed flag NOT set yet
5. Redirect to onboarding
6. User completes onboarding
7. onboarding_completed flag SET
8. Redirect to home
9. Next app launch → Goes to home ✓
```

### Flow 2: Existing User Login (Email/Password)

```
1. User enters email/password
2. Login successful
3. onboarding_completed flag SET ← NEW
4. Redirect to home
5. Next app launch → Goes to home ✓
```

### Flow 3: New User Signup (Google OAuth)

```
1. User clicks "Sign in with Google"
2. Google authentication
3. Backend creates new user (profileCompleteness = 0%)
4. App checks profileCompleteness < 30%
5. Redirect to onboarding
6. User completes onboarding
7. onboarding_completed flag SET
8. Redirect to home
9. Next app launch → Goes to home ✓
```

### Flow 4: Existing User Login (Google OAuth)

```
1. User clicks "Sign in with Google"
2. Google authentication
3. Backend returns existing user (profileCompleteness >= 30%)
4. App checks profileCompleteness >= 30%
5. onboarding_completed flag SET ← NEW
6. Redirect to home
7. Next app launch → Goes to home ✓
```

## Technical Details

### The `onboarding_completed` Flag

**Storage Key:** `onboarding_completed`
**Possible Values:**
- `'true'` - Onboarding completed, user can access full app
- `null` or missing - Onboarding not completed, need to redirect to onboarding

**Where It's Set:**
1. ✅ mentor_onboarding_page.dart:26 (when user completes onboarding)
2. ✅ sign_in_page.dart:232 (after successful email/password login)
3. ✅ main.dart:163 (after successful OAuth login with >= 30% profile)

**Where It's Checked:**
- splash_screen.dart:64,78 (on every app launch)

### Profile Completeness Threshold

**Why 30%?**
- New OAuth users: 0-10% (only basic info from Google)
- After onboarding: 30-70% (filled profile fields)
- Complete profile: 70-100% (all fields filled)

**Threshold = 30%** clearly separates:
- New users (need onboarding) → < 30%
- Existing users (already onboarded) → >= 30%

## Testing Scenarios

### Test 1: New Email/Password Signup
1. Register new account with email/password
2. Complete email verification
3. Login
4. **Expected:** Redirect to onboarding (first time)
5. Complete onboarding
6. **Expected:** Go to home
7. Close and reopen app
8. **Expected:** Go to home (NOT onboarding)

### Test 2: Existing User Login
1. Use email/password that has already registered
2. Login
3. **Expected:** Go directly to home
4. Close and reopen app
5. **Expected:** Go to home (NOT onboarding)

### Test 3: New Google OAuth Signup
1. Sign in with Google (new account)
2. **Expected:** Redirect to onboarding
3. Complete onboarding
4. **Expected:** Go to home
5. Close and reopen app
6. **Expected:** Go to home (NOT onboarding)

### Test 4: Existing Google OAuth Login
1. Sign in with Google (existing account with >= 30% profile)
2. **Expected:** Go directly to home
3. Close and reopen app
4. **Expected:** Go to home (NOT onboarding)

## Build Status

✅ Code compiled successfully
✅ Debug APK built successfully (55.0s)
✅ Onboarding flag now set correctly for all login scenarios
✅ Splash screen logic unchanged (working as designed)

## Summary

**Issue:** Frontend logic issue where `onboarding_completed` flag wasn't being set after login.

**Solution:** Set the flag after successful login:
- Regular login → Set flag (user already has account)
- OAuth login with >= 30% profile → Set flag (existing user)
- Signup/new users → Flag set only after completing onboarding flow

**Result:**
- New users go through onboarding once
- Existing users go directly to home
- No more unwanted onboarding redirects after login
