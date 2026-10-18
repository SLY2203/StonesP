import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:msu_dcs_alumni/providers/auth_provider.dart';
import 'package:msu_dcs_alumni/providers/alumni_provider.dart';
import 'package:msu_dcs_alumni/providers/career_provider.dart';
import 'package:msu_dcs_alumni/providers/communication_provider.dart';
import 'package:msu_dcs_alumni/providers/report_provider.dart';
import 'package:msu_dcs_alumni/screens/auth/login_screen.dart';
import 'package:msu_dcs_alumni/screens/auth/register_screen.dart';
import 'package:msu_dcs_alumni/screens/auth/pending_approval_screen.dart';
import 'package:msu_dcs_alumni/screens/alumni/alumni_home_screen.dart';
import 'package:msu_dcs_alumni/screens/alumni/career_timeline_screen.dart';
import 'package:msu_dcs_alumni/screens/alumni/profile_view_edit_screen.dart';
import 'package:msu_dcs_alumni/screens/alumni/add_edit_career_screen.dart';
import 'package:msu_dcs_alumni/screens/admin/admin_home_screen.dart';
import 'package:msu_dcs_alumni/screens/admin/alumni_directory_screen.dart';
import 'package:msu_dcs_alumni/screens/admin/broadcast_composer_screen.dart';
import 'package:msu_dcs_alumni/screens/admin/reports_dashboard_screen.dart';
import 'package:msu_dcs_alumni/widgets/custom_button.dart';

Widget createTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => AlumniProvider()),
      ChangeNotifierProvider(create: (_) => CareerProvider()),
      ChangeNotifierProvider(create: (_) => CommunicationProvider()),
      ChangeNotifierProvider(create: (_) => ReportProvider()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void setLargeViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Login Screen Buttons', () {
    testWidgets('Quick demo login chips populate text fields properly', (WidgetTester tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      final adminChip = find.text('👑 Department Admin');
      final verifiedChip = find.text('🎓 Verified Alumni (Tinashe)');
      final pendingChip = find.text('⏳ Pending Verification (Blessing)');

      expect(adminChip, findsOneWidget);
      expect(verifiedChip, findsOneWidget);
      expect(pendingChip, findsOneWidget);

      // Tap Admin chip
      await tester.tap(adminChip);
      await tester.pumpAndSettle();
      expect(find.byWidgetPredicate((w) => w is EditableText && w.controller.text == 'admin@dcs.msu.ac.zw'), findsOneWidget);

      // Tap Verified chip
      await tester.tap(verifiedChip);
      await tester.pumpAndSettle();
      expect(find.byWidgetPredicate((w) => w is EditableText && w.controller.text == 'tinashe.moyo@alumni.msu.ac.zw'), findsOneWidget);

      // Tap Pending chip
      await tester.tap(pendingChip);
      await tester.pumpAndSettle();
      expect(find.byWidgetPredicate((w) => w is EditableText && w.controller.text == 'blessing.munemo@alumni.msu.ac.zw'), findsOneWidget);
    });

    testWidgets('Sign in button triggers validation on empty fields', (WidgetTester tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      final signInButton = find.widgetWithText(CustomButton, 'Sign In');
      expect(signInButton, findsOneWidget);

      // Tap Sign In without filling
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Validation errors should appear
      expect(find.text('Enter your email address'), findsOneWidget);
      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('Register here link navigates to RegisterScreen', (WidgetTester tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp(const LoginScreen()));
      await tester.pumpAndSettle();

      final registerLink = find.text('Register here');
      expect(registerLink, findsOneWidget);

      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text('Alumni Self-Registration'), findsOneWidget);
    });
  });

  group('2. Register Screen Buttons', () {
    testWidgets('Submit Registration button triggers validation', (WidgetTester tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp(const RegisterScreen()));
      await tester.pumpAndSettle();

      final submitBtn = find.widgetWithText(CustomButton, 'Submit Registration');
      expect(submitBtn, findsOneWidget);

      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Form validation errors
      expect(find.text('Required'), findsNWidgets(2)); // First name & Last name
      expect(find.text('Registration number is required'), findsOneWidget);
    });
  });

  group('3. Pending Approval Screen Buttons', () {
    testWidgets('Check status and Sign out buttons render and respond', (WidgetTester tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp(const PendingApprovalScreen()));
      await tester.pumpAndSettle();

      final checkStatusBtn = find.widgetWithText(CustomButton, 'Check Status Now');
      final signOutBtn = find.text('Sign Out');

      expect(checkStatusBtn, findsOneWidget);
      expect(signOutBtn, findsOneWidget);

      await tester.tap(signOutBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('4. Career Timeline & Add Milestone Buttons', () {
    testWidgets('Add Milestone FAB opens AddEditCareerScreen', (WidgetTester tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp(const CareerTimelineScreen()));
      await tester.pumpAndSettle();

      final addMilestoneBtn = find.byType(FloatingActionButton);
      expect(addMilestoneBtn, findsOneWidget);

      await tester.tap(addMilestoneBtn);
      await tester.pumpAndSettle();

      expect(find.byType(AddEditCareerScreen), findsOneWidget);
      expect(find.text('Add Career Milestone'), findsOneWidget);

      // Verify Add to Timeline submit button exists
      expect(find.widgetWithText(CustomButton, 'Add to Timeline'), findsOneWidget);
    });
  });

  group('5. Admin Home Dashboard & Tab Switching Buttons', () {
    testWidgets('Bottom navigation tabs switch between Admin sections', (WidgetTester tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp(const AdminHomeScreen()));
      await tester.pumpAndSettle();

      // Default tab: Overview
      expect(find.text('Administrative Control Hub'), findsOneWidget);

      // Click Directory tab
      await tester.tap(find.text('Directory'));
      await tester.pumpAndSettle();
      expect(find.byType(AlumniDirectoryScreen), findsOneWidget);

      // Click Broadcast tab
      await tester.tap(find.text('Broadcast'));
      await tester.pumpAndSettle();
      expect(find.byType(BroadcastComposerScreen), findsOneWidget);

      // Click Reports tab
      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();
      expect(find.byType(ReportsDashboardScreen), findsOneWidget);
    });

    testWidgets('New Broadcast and View Reports header buttons switch tabs', (WidgetTester tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp(const AdminHomeScreen()));
      await tester.pumpAndSettle();

      final newBroadcastBtn = find.widgetWithText(ElevatedButton, 'New Broadcast');
      expect(newBroadcastBtn, findsOneWidget);
      await tester.tap(newBroadcastBtn);
      await tester.pumpAndSettle();
      expect(find.byType(BroadcastComposerScreen), findsOneWidget);

      // Switch back to Overview
      await tester.tap(find.text('Overview'));
      await tester.pumpAndSettle();

      final viewReportsBtn = find.widgetWithText(OutlinedButton, 'View Reports');
      expect(viewReportsBtn, findsOneWidget);
      await tester.tap(viewReportsBtn);
      await tester.pumpAndSettle();
      expect(find.byType(ReportsDashboardScreen), findsOneWidget);
    });
  });

  group('6. Alumni Directory Screen Buttons & Filters', () {
    testWidgets('Status filter chips switch selection properly', (WidgetTester tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp(const AlumniDirectoryScreen()));
      await tester.pumpAndSettle();

      final pendingChip = find.text('⏳ Pending');
      final verifiedChip = find.text('✅ Verified');
      final allChip = find.text('All Alumni');

      expect(pendingChip, findsOneWidget);
      expect(verifiedChip, findsOneWidget);
      expect(allChip, findsOneWidget);

      await tester.tap(pendingChip);
      await tester.pumpAndSettle();

      await tester.tap(verifiedChip);
      await tester.pumpAndSettle();

      await tester.tap(allChip);
      await tester.pumpAndSettle();
    });
  });

  group('7. Broadcast Composer Screen Buttons', () {
    testWidgets('Category dropdown and Publish button exist and interact', (WidgetTester tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp(const BroadcastComposerScreen()));
      await tester.pumpAndSettle();

      // Find Category Dropdown
      final categoryDropdown = find.byType(DropdownButtonFormField<String>).first;
      expect(categoryDropdown, findsOneWidget);

      // Tap Publish button without fields to verify validation
      final publishBtn = find.widgetWithText(CustomButton, 'Publish & Dispatch Broadcast');
      expect(publishBtn, findsOneWidget);

      await tester.tap(publishBtn);
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('Content body is required'), findsOneWidget);
    });
  });

  group('8. Reports Dashboard Export Buttons', () {
    testWidgets('Export PDF and CSV buttons open export modal dialog', (WidgetTester tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp(const ReportsDashboardScreen()));
      await tester.pumpAndSettle();

      final pdfBtn = find.widgetWithText(ElevatedButton, 'Export PDF');
      final csvBtn = find.widgetWithText(OutlinedButton, 'Export CSV');

      expect(pdfBtn, findsOneWidget);
      expect(csvBtn, findsOneWidget);

      // Tap Export PDF
      await tester.tap(pdfBtn);
      await tester.pumpAndSettle();

      expect(find.text('Export PDF Report'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text('Download PDF'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // Tap Export CSV
      await tester.tap(csvBtn);
      await tester.pumpAndSettle();

      expect(find.text('Export CSV Report'), findsOneWidget);
      expect(find.text('Download CSV'), findsOneWidget);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });
  });

  group('9. Alumni Home Navigation Tabs', () {
    testWidgets('Alumni bottom navigation switches between Feed, Career, and Profile', (WidgetTester tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp(const AlumniHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Feed & Events'), findsOneWidget);
      expect(find.text('Career Tracker'), findsOneWidget);
      expect(find.text('My Profile'), findsOneWidget);

      // Switch to Career Tracker
      await tester.tap(find.text('Career Tracker'));
      await tester.pumpAndSettle();
      expect(find.byType(CareerTimelineScreen), findsOneWidget);

      // Switch to My Profile
      await tester.tap(find.text('My Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileViewEditScreen), findsOneWidget);
    });
  });

  group('10. Mentorship Hub & Directory Skills/Roster Actions', () {
    testWidgets('Alumni bottom navigation switches to Mentorship Hub', (WidgetTester tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp(const AlumniHomeScreen()));
      await tester.pumpAndSettle();

      final mentorshipTab = find.byIcon(Icons.school_outlined);
      expect(mentorshipTab, findsOneWidget);
      await tester.tap(mentorshipTab);
      await tester.pumpAndSettle();
      expect(find.text('Browse Mentors'), findsOneWidget);
      expect(find.text('My Connections'), findsOneWidget);
    });

    testWidgets('Admin directory shows Roster Match button and skill chips', (WidgetTester tester) async {
      setLargeViewport(tester);
      await tester.pumpWidget(createTestApp(const AlumniDirectoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Roster Match'), findsOneWidget);
      expect(find.text('Python'), findsOneWidget);
      expect(find.text('Flutter'), findsOneWidget);
    });
  });
}
