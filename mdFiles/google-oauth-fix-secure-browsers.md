# Google OAuth "Use Secure Browsers" Policy Fix

## The Problem

When implementing Google OAuth in a Flutter app using WebView, you may encounter this error:

```
Access blocked: Brightwin's request does not comply with Google's policies
Brightwin's request doesn't comply with "Use secure browsers" policy
```

## Why This Happens

Google has security policies that **block OAuth authentication in embedded WebViews** to prevent phishing attacks. The "Use secure browsers" policy requires that OAuth flows happen in:

1. ✅ System browsers (Chrome, Safari, Firefox, etc.)
2. ✅ Custom Chrome Tabs (Android) or SFSafariViewController (iOS)
3. ❌ NOT in embedded WebViews

## The Solution

Instead of using WebView, we launch the OAuth flow in the **external system browser** and use **deep links** to capture the callback.

### Implementation Overview

1. **Launch External Browser**
   - Use `url_launcher` package to open the OAuth URL in the system browser
   - This complies with Google's security policy

2. **Deep Link Handling**
   - Use `app_links` package to listen for deep link callbacks
   - Backend redirects to: `brightwin://oauth2/redirect?token=...`
   - App receives the deep link and extracts the tokens

3. **User Experience**
   - User sees the actual google.com domain (more trustworthy)
   - Authentication happens in secure system browser
   - App automatically receives tokens and logs in

### Code Changes Made

#### 1. Updated pubspec.yaml
```yaml
dependencies:
  url_launcher: ^6.3.1  # Launch external browser
  app_links: ^6.3.2     # Handle deep links
```

#### 2. GoogleLoginPage - Launch External Browser
```dart
// Launch OAuth URL in external browser
final uri = Uri.parse(googleAuthUrl);
await launchUrl(
  uri,
  mode: LaunchMode.externalApplication, // Opens in system browser
);
```

#### 3. main.dart - Deep Link Handler
```dart
void _initDeepLinks() async {
  _appLinks = AppLinks();

  // Handle initial deep link if app was launched from a link
  final initialUri = await _appLinks.getInitialLink();
  if (initialUri != null) {
    _handleDeepLink(initialUri);
  }

  // Listen to deep links while app is running
  _appLinks.uriLinkStream.listen((uri) {
    _handleDeepLink(uri);
  });
}

void _handleDeepLink(Uri uri) {
  // Check if this is an OAuth2 callback
  if (uri.scheme == 'brightwin' && uri.host == 'oauth2' && uri.path == '/redirect') {
    _handleOAuth2Callback(uri);
  }
}

Future<void> _handleOAuth2Callback(Uri uri) async {
  // Extract tokens from URI
  final jwtResponse = await authRepository.authenticateWithGoogle(uri);

  // Register FCM token
  await FCMService().registerTokenWithBackend(dioClient);

  // Navigate to home
  AppRouterConfig.router.go(AppRoutes.home);
}
```

#### 4. AndroidManifest.xml - Already Configured
```xml
<activity android:name=".MainActivity">
    <!-- Deep Link for OAuth2 callback -->
    <intent-filter>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="brightwin"
            android:host="oauth2"
            android:pathPrefix="/redirect" />
    </intent-filter>
</activity>
```

### Authentication Flow

```
User taps "Sign in with Google"
        ↓
App launches system browser
        ↓
Browser navigates to: https://brightwin-server.bright-way.ac/oauth2/authorization/google
        ↓
Backend redirects to Google OAuth
        ↓
User authenticates with Google
        ↓
Google returns to backend with auth code
        ↓
Backend exchanges code for user info
        ↓
Backend generates JWT tokens
        ↓
Backend redirects to: brightwin://oauth2/redirect?token=...&refreshToken=...
        ↓
System opens app via deep link
        ↓
App receives deep link in main.dart
        ↓
App extracts and stores tokens
        ↓
App navigates to home page
```

### Benefits of This Approach

✅ **Complies with Google's security policies**
✅ **More secure** - Users see the actual Google domain
✅ **Better UX** - Users trust the system browser
✅ **No WebView issues** - Avoids all WebView-related problems
✅ **Standard OAuth2 flow** - Works with Spring Security OAuth2

### Testing

1. Click "Sign in with Google" in the app
2. External browser opens with Google login
3. Authenticate with Google account
4. Browser automatically returns to app
5. App logs in and navigates to home

### Troubleshooting

**Issue: Deep link not working**
- Check AndroidManifest.xml has correct intent-filter
- Verify deep link scheme matches: `brightwin://oauth2/redirect`
- Test deep link with: `adb shell am start -a android.intent.action.VIEW -d "brightwin://oauth2/redirect?token=test"`

**Issue: Browser doesn't redirect back to app**
- Ensure backend redirects to correct URI: `brightwin://oauth2/redirect`
- Check environment variable: `OAUTH2_REDIRECT_URI=brightwin://oauth2/redirect`

**Issue: "Access blocked" still appears**
- Make sure you're using external browser, not WebView
- Verify `LaunchMode.externalApplication` is set in url_launcher

## Alternative Solutions (Not Used)

### flutter_web_auth / flutter_web_auth_2
- ❌ Compilation errors with recent Flutter versions
- ❌ Platform-specific issues
- ✅ Would work but has stability issues

### google_sign_in package
- ❌ Requires Google ID token exchange endpoint
- ❌ Backend uses Spring Security OAuth2, not direct token exchange
- ✅ Good for apps with custom backend token exchange

### flutter_appauth
- ❌ Overkill for simple OAuth2 flow
- ❌ Requires additional configuration
- ✅ Good for complex OAuth2/OIDC requirements

## Final Solution

**url_launcher + app_links** is the simplest, most reliable solution that:
- Works with Spring Security OAuth2
- Complies with Google's policies
- Minimal dependencies
- Easy to understand and maintain
