# OAuth Role Parameter Implementation

## Overview

The Google and LinkedIn OAuth login flows now include a `role` parameter to specify the user type during authentication. This allows the backend to properly assign roles to users during the OAuth registration/login process.

## Role Parameter Values

The OAuth2 endpoints support the following role values:
- `MENTOR` - For mentor users (mentors app)
- `JOB_SEEKER` - For job seeker users (users app)
- `ADMIN` - For admin users (admin dashboard)

## Implementation (Mentors App)

### Google OAuth URL

**Before:**
```
https://brightwin-server.bright-way.ac/oauth2/authorization/google
```

**After:**
```
https://brightwin-server.bright-way.ac/oauth2/authorization/google?role=MENTOR
```

### LinkedIn OAuth URL

**Before:**
```
https://brightwin-server.bright-way.ac/oauth2/authorization/linkedin
```

**After:**
```
https://brightwin-server.bright-way.ac/oauth2/authorization/linkedin?role=MENTOR
```

## Code Changes

### File: `lib/features/auth/data/repositories/auth_repository_impl.dart`

#### Google OAuth (Line 225-238)
```dart
@override
String getGoogleAuthUrl() {
  final baseUrl = _environmentService.baseUrl;
  // Spring OAuth2 authorization endpoint for Google with MENTOR role
  final authUrl = '$baseUrl/oauth2/authorization/google?role=MENTOR';

  print('========================================');
  print('🔗 GOOGLE AUTH URL GENERATED');
  print('URL: $authUrl');
  print('Role: MENTOR');
  print('Environment: ${_environmentService.environmentName}');
  print('========================================');

  return authUrl;
}
```

#### LinkedIn OAuth (Line 134-147)
```dart
@override
String getLinkedInAuthUrl() {
  final baseUrl = _environmentService.baseUrl;
  // Spring OAuth2 authorization endpoint for LinkedIn with MENTOR role
  final authUrl = '$baseUrl/oauth2/authorization/linkedin?role=MENTOR';

  print('========================================');
  print('🔗 LINKEDIN AUTH URL GENERATED');
  print('URL: $authUrl');
  print('Role: MENTOR');
  print('Environment: ${_environmentService.environmentName}');
  print('========================================');

  return authUrl;
}
```

## Backend Integration

The backend OAuth2 configuration expects the `role` parameter and uses it to:

1. **Assign User Role**: Set the appropriate role (MENTOR, JOB_SEEKER, or ADMIN) when creating new users via OAuth
2. **Validate Access**: Ensure users are accessing the correct application for their role
3. **Set Permissions**: Configure role-based permissions and access control

## User Flow

### New User Registration via OAuth (Google/LinkedIn)

1. User clicks "Sign in with Google" in mentors app
2. App generates OAuth URL: `/oauth2/authorization/google?role=MENTOR`
3. User authenticates with Google
4. Backend receives OAuth callback with role parameter
5. Backend creates new user with `MENTOR` role
6. User profile completeness = 0% (new user)
7. App redirects to onboarding
8. User completes mentor onboarding
9. Profile completeness increases to 30%+
10. User can now access full mentor app features

### Existing User Login via OAuth

1. User clicks "Sign in with Google" in mentors app
2. App generates OAuth URL: `/oauth2/authorization/google?role=MENTOR`
3. User authenticates with Google
4. Backend finds existing user with `MENTOR` role
5. Backend validates role matches
6. User profile completeness >= 30% (existing user)
7. App redirects directly to home/dashboard

## Testing

### Test URLs (Development)

**Google OAuth:**
```
http://localhost:8080/oauth2/authorization/google?role=MENTOR
```

**LinkedIn OAuth:**
```
http://localhost:8080/oauth2/authorization/linkedin?role=MENTOR
```

### Test URLs (Production)

**Google OAuth:**
```
https://brightwin-server.bright-way.ac/oauth2/authorization/google?role=MENTOR
```

**LinkedIn OAuth:**
```
https://brightwin-server.bright-way.ac/oauth2/authorization/linkedin?role=MENTOR
```

### Test Scenarios

#### Scenario 1: New Mentor Registration
1. Use Google account never registered before
2. Login via Google OAuth
3. **Expected**: User created with MENTOR role
4. **Expected**: Redirected to mentor onboarding

#### Scenario 2: Existing Mentor Login
1. Use Google account already registered as MENTOR
2. Login via Google OAuth
3. **Expected**: User found with MENTOR role
4. **Expected**: Redirected to home/dashboard

#### Scenario 3: Role Mismatch (if backend validates)
1. Register as JOB_SEEKER in users app
2. Try to login via Google OAuth in mentors app (role=MENTOR)
3. **Expected**: Backend may reject or handle role mismatch

## Build Status

✅ Code compiled successfully
✅ Debug APK built successfully (30.7s)
✅ OAuth URLs updated with role parameter
✅ Logging enhanced to show role in debug output

## Related Files

- `lib/features/auth/data/repositories/auth_repository_impl.dart` - OAuth URL generation
- `lib/features/auth/domain/repositories/auth_repository.dart` - Repository interface
- `lib/features/auth/presentation/pages/google_login_page.dart` - Google OAuth page
- `lib/main.dart` - OAuth callback handler

## Notes

- The role parameter is appended as a query parameter to the OAuth URL
- The backend is responsible for validating and using the role parameter
- Each app (mentors, users, admin) should use its appropriate role value
- The role is logged in debug output for troubleshooting

## Future Considerations

For the **users app** (job seekers), the same implementation should use:
```dart
final authUrl = '$baseUrl/oauth2/authorization/google?role=JOB_SEEKER';
```

For the **admin dashboard**, use:
```dart
final authUrl = '$baseUrl/oauth2/authorization/google?role=ADMIN';
```
