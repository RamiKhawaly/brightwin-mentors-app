# Google OAuth Troubleshooting Guide

## Error: "Redirecting to error URL: brightwin://oauth2/redirect"

### What This Means

The backend OAuth authentication failed and is redirecting to the error URL. The app will now show better error details in the logs.

### Common Causes & Solutions

### 1. Provider Mismatch (Most Common)

**Error Message:** "Looks like you're signed up with LOCAL account. Please use your LOCAL account to login."

**Cause:**
- You previously registered with **email/password** (AuthProvider.LOCAL)
- Now trying to login with **Google** (AuthProvider.GOOGLE)
- Backend only allows one authentication method per email address

**Solution:**
- Use the original sign-in method (email/password)
- OR use a different Google account that hasn't been registered yet
- OR delete the existing account and re-register with Google

**Code Location (Backend):**
```java
// CustomOAuth2UserService.java:89-95
if (!user.getProvider().equals(AuthProvider.valueOf(registrationId.toUpperCase()))) {
    throw new BadRequestException("Looks like you're signed up with " +
            user.getProvider() + " account. Please use your " + user.getProvider() +
            " account to login.");
}
```

---

### 2. Email Not Found from OAuth2 Provider

**Error Message:** "Email not found from OAuth2 provider"

**Cause:**
- Google didn't return an email address in the OAuth response
- OAuth scopes might not include email
- User denied email permission during Google consent

**Solution:**
- Check Google OAuth2 configuration includes `email` scope
- Backend configuration (OAuth2Config.java:82):
  ```java
  .scope("openid", "profile", "email")  // email scope is required
  ```
- Ensure user grants email permission during Google sign-in
- Try with a different Google account

**Code Location (Backend):**
```java
// CustomOAuth2UserService.java:75-78
if (!StringUtils.hasText(oAuth2UserInfo.getEmail())) {
    throw new BadRequestException("Email not found from OAuth2 provider");
}
```

---

### 3. Google OAuth Credentials Not Configured

**Error:** OAuth fails to start or shows "Client not found"

**Cause:**
- Backend environment variables not set:
  - `GOOGLE_CLIENT_ID`
  - `GOOGLE_CLIENT_SECRET`

**Solution:**
- Check backend environment variables are set
- Verify Google OAuth2 credentials are correct
- Check backend logs for: "OAuth2 Provider ENABLED: Google"

**Backend Startup Log:**
```
OAuth2 Provider ENABLED: Google
OAuth2 login is ENABLED - GitHub and Google authentication available
```

---

### 4. Redirect URI Mismatch

**Error:** Google shows "redirect_uri_mismatch"

**Cause:**
- Redirect URI in Google Cloud Console doesn't match backend configuration

**Solution:**
- Google Cloud Console redirect URI must be:
  - Development: `http://localhost:8080/login/oauth2/code/google`
  - Production: `https://brightwin-server.bright-way.ac/login/oauth2/code/google`
- Check backend logs show correct base URL

---

## Debugging Steps

### 1. Check Backend Logs

The backend logs will show the exact error. Look for:

```
=== OAuth2: Authentication exception ===
```

Or:

```
=== LinkedIn OAuth2: Authentication FAILURE ===
Error message: [exact error here]
```

### 2. Check Flutter App Logs

After the error, check the Flutter logs:

```
❌ OAuth Error: [error message]
❌ Description: [error description]
```

### 3. Check Deep Link

The error deep link will contain the error parameter:

```
brightwin://oauth2/redirect?error=[error message]
```

---

## Testing Different Scenarios

### Test 1: New User with Google

1. Use a Google account that has NEVER been used before
2. Click "Sign in with Google"
3. Complete Google authentication
4. **Expected**: Success, redirected to onboarding

### Test 2: Existing User with Google

1. Use a Google account that has already completed onboarding
2. Click "Sign in with Google"
3. Complete Google authentication
4. **Expected**: Success, redirected to home

### Test 3: Provider Mismatch (Will Fail)

1. Register with email/password first
2. Try to login with Google using the SAME email
3. **Expected**: Error "Looks like you're signed up with LOCAL account"

### Test 4: Check Email Permissions

1. During Google sign-in, check permissions screen
2. Ensure "email" is included in requested permissions
3. Grant all permissions
4. **Expected**: Success

---

## Backend OAuth Configuration Checklist

- [ ] `GOOGLE_CLIENT_ID` environment variable set
- [ ] `GOOGLE_CLIENT_SECRET` environment variable set
- [ ] Google Cloud Console OAuth2 credentials created
- [ ] Redirect URI configured in Google Cloud Console
- [ ] Backend shows "OAuth2 Provider ENABLED: Google" on startup
- [ ] Backend accessible at the configured base URL

---

## Error Messages Reference

| Error Message | Cause | Solution |
|--------------|-------|----------|
| "Email not found from OAuth2 provider" | Google didn't return email | Check OAuth scopes, grant email permission |
| "Looks like you're signed up with LOCAL account" | Provider mismatch | Use original sign-in method |
| "redirect_uri_mismatch" | Wrong redirect URI | Update Google Cloud Console |
| "Client not found" | Missing OAuth credentials | Set GOOGLE_CLIENT_ID and GOOGLE_CLIENT_SECRET |
| "Access blocked: Use secure browsers policy" | Using WebView | This is fixed - we use external browser now |

---

## Backend Error Handling

### OAuth2AuthenticationFailureHandler.java

When OAuth fails, the backend:

1. Logs the full error details
2. Redirects to: `brightwin://oauth2/redirect?error=[message]`
3. App receives the deep link with error parameter
4. App shows error in logs and navigates back to sign-in

```java
// Backend error handling
String targetUrl = UriComponentsBuilder.fromUriString(redirectUri)
        .queryParam("error", exception.getLocalizedMessage())
        .build().toUriString();

getRedirectStrategy().sendRedirect(request, response, targetUrl);
```

---

## App Error Handling

### main.dart:92-105

When the app receives an error deep link:

```dart
if (uri.queryParameters.containsKey('error')) {
  final error = uri.queryParameters['error'];
  final errorDescription = uri.queryParameters['error_description'] ?? 'Unknown error';
  print('❌ OAuth Error: $error');
  print('❌ Description: $errorDescription');

  // Navigate back to sign-in
  AppRouterConfig.router.go(AppRoutes.signIn);
}
```

---

## Quick Fixes

### Fix 1: Clear Existing Account

If you have provider mismatch:

```sql
-- Backend database
DELETE FROM users WHERE email = 'your-email@example.com';
```

Then re-register with Google.

### Fix 2: Check Backend Environment

```bash
# Backend .env or environment variables
echo $GOOGLE_CLIENT_ID      # Should show your client ID
echo $GOOGLE_CLIENT_SECRET  # Should show your client secret
```

### Fix 3: Restart Backend

After changing environment variables:

```bash
# Restart backend to pick up new environment variables
mvn spring-boot:run
```

---

## Still Having Issues?

1. Check backend logs for the exact error message
2. Check Flutter logs for the deep link parameters
3. Verify Google Cloud Console configuration
4. Test with a fresh Google account (never used before)
5. Check backend environment variables are set correctly

## Next Steps

After seeing the exact error message in the logs:
1. Match it to one of the causes above
2. Apply the corresponding solution
3. Test again with the same or different Google account
4. If still failing, share the exact error message for more help
