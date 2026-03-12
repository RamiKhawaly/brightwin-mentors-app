import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/sign_in_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/auth/presentation/pages/registration_selection_page.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/mentor_onboarding_page.dart';
import '../../features/auth/presentation/pages/google_login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/jobs/presentation/pages/create_job_page.dart';
import '../../features/jobs/presentation/pages/my_jobs_page.dart';
import '../../features/jobs/presentation/pages/import_job_page.dart';
import '../../features/jobs/presentation/pages/review_job_page.dart';
import '../../features/jobs/presentation/pages/review_extracted_job_page.dart';
import '../../features/jobs/presentation/pages/job_details_page.dart';
import '../../features/jobs/data/models/job_import_response.dart';
import '../../features/jobs/data/models/job_response_model.dart';
import '../../features/badges/presentation/pages/badges_page.dart';
import '../../features/feedback/presentation/pages/give_feedback_page.dart';
import '../../features/sessions/presentation/pages/upcoming_sessions_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/cv_auth/presentation/pages/cv_upload_page.dart';
import '../../features/cv_auth/presentation/pages/cv_approval_page.dart';
import '../../features/cv_auth/presentation/pages/cv_otp_verification_page.dart';
import '../../features/cv_auth/presentation/pages/cv_login_page.dart';
import '../../features/cv_auth/data/models/cv_extraction_response.dart';
import '../../features/sessions/presentation/pages/session_details_page.dart';
import '../../features/sessions/presentation/pages/pending_requests_page.dart';
import '../../features/sessions/presentation/pages/negotiating_sessions_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/applications/presentation/pages/applications_page.dart';
import '../../features/applications/presentation/pages/application_detail_page.dart';
import '../../features/applications/data/models/application_model.dart';
import '../../features/settings/presentation/pages/mentor_settings_page.dart';
import '../../features/suggestions/presentation/pages/suggestions_page.dart';

class AppRoutes {
  // Auth routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String mentorOnboarding = '/mentor-onboarding';
  static const String registrationSelection = '/registration-selection';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String googleLogin = '/google-login';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String newPassword = '/new-password';
  static const String completeProfile = '/complete-profile';

  // CV Auth routes
  static const String cvUpload = '/cv-auth/upload';
  static const String cvApprove = '/cv-auth/approve';
  static const String cvOtpVerify = '/cv-auth/otp-verify';
  static const String cvLogin = '/cv-auth/login';

  // Main routes
  static const String home = '/home';
  static const String jobPosting = '/job-posting';
  static const String jobDetail = '/job-detail';
  static const String badges = '/badges';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String mentorSettings = '/mentor-settings';
  static const String inbox = '/inbox';
  static const String notifications = '/notifications';
  static const String upcomingSessions = '/upcoming-sessions';
  static const String applications = '/applications';
  static const String applicationDetail = '/applications/:id';
  static const String suggestions = '/suggestions';
}

class AppRouterConfig {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Onboarding Screen')),
        ),
      ),
      GoRoute(
        path: AppRoutes.mentorOnboarding,
        builder: (context, state) => const MentorOnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.registrationSelection,
        builder: (context, state) => const RegistrationSelectionPage(),
      ),
      GoRoute(
        path: AppRoutes.signIn,
        builder: (context, state) => const SignInPage(),
      ),
      GoRoute(
        path: AppRoutes.signUp,
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.googleLogin,
        builder: (context, state) => const GoogleLoginPage(),
      ),
      GoRoute(
        path: '/otp-verify',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final password = state.uri.queryParameters['password'] ?? '';
          return OtpVerificationPage(
            email: email,
            password: password,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.jobPosting,
        builder: (context, state) => const CreateJobPage(),
      ),
      GoRoute(
        path: '${AppRoutes.jobPosting}/my-jobs',
        builder: (context, state) => const MyJobsPage(),
      ),
      GoRoute(
        path: '${AppRoutes.jobPosting}/import',
        builder: (context, state) => const ImportJobPage(),
      ),
      GoRoute(
        path: '/job-review',
        builder: (context, state) {
          final jobData = state.extra as JobImportResponse;
          return ReviewJobPage(jobData: jobData);
        },
      ),
      GoRoute(
        path: '/job-review-extracted',
        builder: (context, state) {
          final jobData = state.extra as JobResponseModel;
          return ReviewExtractedJobPage(jobData: jobData);
        },
      ),
      GoRoute(
        path: AppRoutes.jobDetail,
        builder: (context, state) {
          final job = state.extra as JobResponseModel;
          return JobDetailsPage(job: job);
        },
      ),
      GoRoute(
        path: AppRoutes.badges,
        builder: (context, state) => const BadgesPage(),
      ),
      GoRoute(
        path: '${AppRoutes.home}/feedback/:sessionId/:jobSeekerId/:jobSeekerName',
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId'] ?? '';
          final jobSeekerId = state.pathParameters['jobSeekerId'] ?? '';
          final jobSeekerName = state.pathParameters['jobSeekerName'] ?? '';
          return GiveFeedbackPage(
            sessionId: sessionId,
            jobSeekerId: jobSeekerId,
            jobSeekerName: jobSeekerName,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.upcomingSessions,
        builder: (context, state) => const UpcomingSessionsPage(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.mentorSettings,
        builder: (context, state) => const MentorSettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.cvUpload,
        builder: (context, state) => const CVUploadPage(),
      ),
      GoRoute(
        path: AppRoutes.cvApprove,
        builder: (context, state) {
          final extractedData = state.extra as CVExtractionResponse;
          return CVApprovalPage(extractedData: extractedData);
        },
      ),
      GoRoute(
        path: AppRoutes.cvOtpVerify,
        builder: (context, state) {
          final data = state.extra as Map<String, String>;
          return CVOtpVerificationPage(
            sessionId: data['sessionId']!,
            email: data['email']!,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cvLogin,
        builder: (context, state) => const CVLoginPage(),
      ),
      GoRoute(
        path: '/sessions/:id',
        builder: (context, state) {
          final sessionId = state.pathParameters['id']!;
          return SessionDetailsPage(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/sessions/pending',
        builder: (context, state) => const PendingRequestsPage(),
      ),
      GoRoute(
        path: '/sessions/negotiating',
        builder: (context, state) => const NegotiatingSessionsPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.applications,
        builder: (context, state) {
          // Check if extra data was passed (jobId and jobTitle for filtering)
          if (state.extra != null && state.extra is Map<String, dynamic>) {
            final params = state.extra as Map<String, dynamic>;
            return ApplicationsPage(
              jobId: params['jobId'] as int?,
              jobTitle: params['jobTitle'] as String?,
            );
          }
          return const ApplicationsPage();
        },
      ),
      GoRoute(
        path: '/applications/:id',
        builder: (context, state) {
          final application = state.extra as ApplicationModel;
          return ApplicationDetailPage(application: application);
        },
      ),
      GoRoute(
        path: AppRoutes.suggestions,
        builder: (context, state) => const SuggestionsPage(),
      ),
      // OAuth2 redirect route - shows loading while deep link handler processes the callback
      GoRoute(
        path: '/redirect',
        builder: (context, state) => const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
}
