import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @loginEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get loginEmailRequired;

  /// No description provided for @loginPasswordResetSentMsg.
  ///
  /// In en, this message translates to:
  /// **'Password reset sent to {email}'**
  String loginPasswordResetSentMsg(String email);

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailHint;

  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordHint;

  /// No description provided for @usernameHint.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameHint;

  /// No description provided for @pinHint.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pinHint;

  /// No description provided for @signInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInButton;

  /// No description provided for @loginToggleStudent.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get loginToggleStudent;

  /// No description provided for @loginToggleStaff.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get loginToggleStaff;

  /// No description provided for @loginEmailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get loginEmailAddressLabel;

  /// No description provided for @loginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get loginPasswordLabel;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get loginForgotPassword;

  /// No description provided for @loginUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get loginUsernameLabel;

  /// No description provided for @loginPinCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get loginPinCodeLabel;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navCurriculum.
  ///
  /// In en, this message translates to:
  /// **'Curriculum'**
  String get navCurriculum;

  /// No description provided for @navUsers.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get navUsers;

  /// No description provided for @navGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get navGroups;

  /// No description provided for @navLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get navLogs;

  /// No description provided for @navMaterials.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get navMaterials;

  /// No description provided for @navTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get navTasks;

  /// No description provided for @navActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navActivity;

  /// No description provided for @navLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get navLearn;

  /// No description provided for @navAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get navAlerts;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back,'**
  String get welcomeBack;

  /// No description provided for @roleAdministrator.
  ///
  /// In en, this message translates to:
  /// **'Administrator'**
  String get roleAdministrator;

  /// No description provided for @loggingOut.
  ///
  /// In en, this message translates to:
  /// **'Logging out...'**
  String get loggingOut;

  /// No description provided for @platformOverview.
  ///
  /// In en, this message translates to:
  /// **'PLATFORM OVERVIEW'**
  String get platformOverview;

  /// No description provided for @platformStatistics.
  ///
  /// In en, this message translates to:
  /// **'PLATFORM STATISTICS'**
  String get platformStatistics;

  /// No description provided for @statisticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTitle;

  /// No description provided for @statStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get statStudents;

  /// No description provided for @statInstructors.
  ///
  /// In en, this message translates to:
  /// **'Instructors'**
  String get statInstructors;

  /// No description provided for @statLevels.
  ///
  /// In en, this message translates to:
  /// **'Levels'**
  String get statLevels;

  /// No description provided for @statActiveTasks.
  ///
  /// In en, this message translates to:
  /// **'Active Tasks'**
  String get statActiveTasks;

  /// No description provided for @statLessons.
  ///
  /// In en, this message translates to:
  /// **'Lessons'**
  String get statLessons;

  /// No description provided for @statGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get statGroups;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'RECENT ACTIVITY'**
  String get recentActivity;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @noRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'No recent activity'**
  String get noRecentActivity;

  /// No description provided for @levelNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Level Name'**
  String get levelNameLabel;

  /// No description provided for @weekNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Week Name'**
  String get weekNameLabel;

  /// No description provided for @materialTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Material Title'**
  String get materialTitleLabel;

  /// No description provided for @contentLabel.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get contentLabel;

  /// No description provided for @assignmentTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Assignment Title'**
  String get assignmentTitleLabel;

  /// No description provided for @searchLessonsTags.
  ///
  /// In en, this message translates to:
  /// **'Search lessons & tags...'**
  String get searchLessonsTags;

  /// No description provided for @noLevelsYet.
  ///
  /// In en, this message translates to:
  /// **'No levels yet'**
  String get noLevelsYet;

  /// No description provided for @addFirstLevel.
  ///
  /// In en, this message translates to:
  /// **'Add your first study level to get started'**
  String get addFirstLevel;

  /// No description provided for @noGroupsFound.
  ///
  /// In en, this message translates to:
  /// **'No groups found'**
  String get noGroupsFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No description provided for @allRoles.
  ///
  /// In en, this message translates to:
  /// **'All Roles'**
  String get allRoles;

  /// No description provided for @allTime.
  ///
  /// In en, this message translates to:
  /// **'All Time'**
  String get allTime;

  /// No description provided for @roleInstructor.
  ///
  /// In en, this message translates to:
  /// **'Instructor'**
  String get roleInstructor;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumberLabel;

  /// No description provided for @homeAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Home Address'**
  String get homeAddressLabel;

  /// No description provided for @emailAddressLabel.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddressLabel;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile – {name}'**
  String editProfileTitle(String name);

  /// No description provided for @editLevelsTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Levels – {name}'**
  String editLevelsTitle(String name);

  /// No description provided for @levelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Level 1 – Beginner'**
  String get levelBeginner;

  /// No description provided for @levelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Level 2 – Intermediate'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Level 3 – Advanced'**
  String get levelAdvanced;

  /// No description provided for @noLevelsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No levels assigned'**
  String get noLevelsAssigned;

  /// No description provided for @gradeSubmission.
  ///
  /// In en, this message translates to:
  /// **'Grade Submission'**
  String get gradeSubmission;

  /// No description provided for @reviseGrade.
  ///
  /// In en, this message translates to:
  /// **'Revise Grade'**
  String get reviseGrade;

  /// No description provided for @statusCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get statusCorrect;

  /// No description provided for @statusIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get statusIncorrect;

  /// No description provided for @statusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get statusPartial;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @noGroupAssigned.
  ///
  /// In en, this message translates to:
  /// **'No Group Assigned'**
  String get noGroupAssigned;

  /// No description provided for @noStudentSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Students haven\'t submitted their answers'**
  String get noStudentSubmissions;

  /// No description provided for @gradeButton.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get gradeButton;

  /// No description provided for @shareCredentialsMsg.
  ///
  /// In en, this message translates to:
  /// **'Share these login credentials with the student'**
  String get shareCredentialsMsg;

  /// No description provided for @credFullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get credFullName;

  /// No description provided for @credUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get credUsername;

  /// No description provided for @credPinCode.
  ///
  /// In en, this message translates to:
  /// **'PIN Code'**
  String get credPinCode;

  /// No description provided for @credStudentNumber.
  ///
  /// In en, this message translates to:
  /// **'Student #'**
  String get credStudentNumber;

  /// No description provided for @noStudentsInGroup.
  ///
  /// In en, this message translates to:
  /// **'No students found'**
  String get noStudentsInGroup;

  /// No description provided for @addStudentsOrSearch.
  ///
  /// In en, this message translates to:
  /// **'Add students or adjust search'**
  String get addStudentsOrSearch;

  /// No description provided for @yourAnswer.
  ///
  /// In en, this message translates to:
  /// **'YOUR ANSWER'**
  String get yourAnswer;

  /// No description provided for @gradedCorrect.
  ///
  /// In en, this message translates to:
  /// **'Graded: Correct'**
  String get gradedCorrect;

  /// No description provided for @gradedIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Graded: Incorrect'**
  String get gradedIncorrect;

  /// No description provided for @updateAssignment.
  ///
  /// In en, this message translates to:
  /// **'Update Assignment'**
  String get updateAssignment;

  /// No description provided for @submitAssignment.
  ///
  /// In en, this message translates to:
  /// **'Submit Assignment'**
  String get submitAssignment;

  /// No description provided for @statSubmissionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get statSubmissionsLabel;

  /// No description provided for @statGradedLabel.
  ///
  /// In en, this message translates to:
  /// **'Graded'**
  String get statGradedLabel;

  /// No description provided for @statCorrectLabel.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get statCorrectLabel;

  /// No description provided for @createAssignment.
  ///
  /// In en, this message translates to:
  /// **'Create Assignment'**
  String get createAssignment;

  /// No description provided for @chooseCreationMethod.
  ///
  /// In en, this message translates to:
  /// **'Choose how to create your assignment'**
  String get chooseCreationMethod;

  /// No description provided for @fromCurriculumPool.
  ///
  /// In en, this message translates to:
  /// **'From Curriculum Pool'**
  String get fromCurriculumPool;

  /// No description provided for @fromCurriculumPoolDesc.
  ///
  /// In en, this message translates to:
  /// **'Assign a task from the admin\'s weekly curriculum'**
  String get fromCurriculumPoolDesc;

  /// No description provided for @createFromScratch.
  ///
  /// In en, this message translates to:
  /// **'Create From Scratch'**
  String get createFromScratch;

  /// No description provided for @createFromScratchDesc.
  ///
  /// In en, this message translates to:
  /// **'Write a new text-based assignment'**
  String get createFromScratchDesc;

  /// No description provided for @curriculumPoolTitle.
  ///
  /// In en, this message translates to:
  /// **'Curriculum Pool'**
  String get curriculumPoolTitle;

  /// No description provided for @assignmentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get assignmentsTitle;

  /// No description provided for @textAnswerType.
  ///
  /// In en, this message translates to:
  /// **'Text Answer'**
  String get textAnswerType;

  /// No description provided for @multipleChoiceType.
  ///
  /// In en, this message translates to:
  /// **'Multiple Choice'**
  String get multipleChoiceType;

  /// No description provided for @selectDeadline.
  ///
  /// In en, this message translates to:
  /// **'Select Deadline *'**
  String get selectDeadline;

  /// No description provided for @titleAndDeadlineRequired.
  ///
  /// In en, this message translates to:
  /// **'Title and deadline are required'**
  String get titleAndDeadlineRequired;

  /// No description provided for @atLeast2Options.
  ///
  /// In en, this message translates to:
  /// **'Please provide at least 2 options'**
  String get atLeast2Options;

  /// No description provided for @tabActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get tabActive;

  /// No description provided for @tabPast.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get tabPast;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get filterOverdue;

  /// No description provided for @filterCentral.
  ///
  /// In en, this message translates to:
  /// **'Central'**
  String get filterCentral;

  /// No description provided for @filterCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get filterCustom;

  /// No description provided for @noAssignments.
  ///
  /// In en, this message translates to:
  /// **'No assignments'**
  String get noAssignments;

  /// No description provided for @noAssignmentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create one or change filters'**
  String get noAssignmentsSubtitle;

  /// No description provided for @editContent.
  ///
  /// In en, this message translates to:
  /// **'Edit Content'**
  String get editContent;

  /// No description provided for @editDeadlineMenu.
  ///
  /// In en, this message translates to:
  /// **'Edit Deadline'**
  String get editDeadlineMenu;

  /// No description provided for @deleteAssignment.
  ///
  /// In en, this message translates to:
  /// **'Delete Assignment'**
  String get deleteAssignment;

  /// No description provided for @deadlineUpdated.
  ///
  /// In en, this message translates to:
  /// **'Deadline for \"{title}\" updated.'**
  String deadlineUpdated(String title);

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleRequired;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @deleteAssignmentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete this assignment?'**
  String get deleteAssignmentConfirm;

  /// No description provided for @assignmentDeleted.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" has been deleted.'**
  String assignmentDeleted(String title);

  /// No description provided for @levelsAndBrowse.
  ///
  /// In en, this message translates to:
  /// **'{count} levels · Browse & assign'**
  String levelsAndBrowse(String count);

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @tryDifferentKeyword.
  ///
  /// In en, this message translates to:
  /// **'Try a different keyword'**
  String get tryDifferentKeyword;

  /// No description provided for @noCurriculum.
  ///
  /// In en, this message translates to:
  /// **'No curriculum'**
  String get noCurriculum;

  /// No description provided for @adminNotAddedCurriculum.
  ///
  /// In en, this message translates to:
  /// **'The admin has not added curriculum yet'**
  String get adminNotAddedCurriculum;

  /// No description provided for @myGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get myGroupsTitle;

  /// No description provided for @groupsAssignedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} groups assigned'**
  String groupsAssignedCount(String count);

  /// No description provided for @roleInstructorLabel.
  ///
  /// In en, this message translates to:
  /// **'Instructor'**
  String get roleInstructorLabel;

  /// No description provided for @activeBadge.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE NOW'**
  String get activeBadge;

  /// No description provided for @dashboardAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get dashboardAssignments;

  /// No description provided for @dashboardMyGroups.
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get dashboardMyGroups;

  /// No description provided for @myOverview.
  ///
  /// In en, this message translates to:
  /// **'MY OVERVIEW'**
  String get myOverview;

  /// No description provided for @statMyGroups.
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get statMyGroups;

  /// No description provided for @statPendingReview.
  ///
  /// In en, this message translates to:
  /// **'Pending Review'**
  String get statPendingReview;

  /// No description provided for @navigatingToStudents.
  ///
  /// In en, this message translates to:
  /// **'Navigating to student roster...'**
  String get navigatingToStudents;

  /// No description provided for @activeAssignmentsHeader.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE ASSIGNMENTS'**
  String get activeAssignmentsHeader;

  /// No description provided for @categoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// No description provided for @categoryGrading.
  ///
  /// In en, this message translates to:
  /// **'Grading'**
  String get categoryGrading;

  /// No description provided for @categoryStudents.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get categoryStudents;

  /// No description provided for @categoryAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get categoryAssignments;

  /// No description provided for @categoryCurriculum.
  ///
  /// In en, this message translates to:
  /// **'Curriculum'**
  String get categoryCurriculum;

  /// No description provided for @countTotalShown.
  ///
  /// In en, this message translates to:
  /// **'{total} total · {shown} shown'**
  String countTotalShown(String total, String shown);

  /// No description provided for @noActivityFound.
  ///
  /// In en, this message translates to:
  /// **'No activity found'**
  String get noActivityFound;

  /// No description provided for @tryAdjustingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search or filter'**
  String get tryAdjustingSearch;

  /// No description provided for @pendingTabCount.
  ///
  /// In en, this message translates to:
  /// **'Pending ({count})'**
  String pendingTabCount(String count);

  /// No description provided for @submittedTabCount.
  ///
  /// In en, this message translates to:
  /// **'Submitted ({count})'**
  String submittedTabCount(String count);

  /// No description provided for @noPendingTasks.
  ///
  /// In en, this message translates to:
  /// **'No pending tasks'**
  String get noPendingTasks;

  /// No description provided for @allCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up!'**
  String get allCaughtUp;

  /// No description provided for @noSubmittedTasks.
  ///
  /// In en, this message translates to:
  /// **'No submitted tasks'**
  String get noSubmittedTasks;

  /// No description provided for @submitFirstAssignment.
  ///
  /// In en, this message translates to:
  /// **'Submit your first assignment'**
  String get submitFirstAssignment;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// No description provided for @notificationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} notifications'**
  String notificationsCount(String count);

  /// No description provided for @newNotificationsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String newNotificationsCount(String count);

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @allCaughtUpNotif.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up!'**
  String get allCaughtUpNotif;

  /// No description provided for @helloGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloGreeting(String name);

  /// No description provided for @lessonsSection.
  ///
  /// In en, this message translates to:
  /// **'LESSONS'**
  String get lessonsSection;

  /// No description provided for @tasksDueCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Tasks Due'**
  String tasksDueCount(String count);

  /// No description provided for @newNotifCount.
  ///
  /// In en, this message translates to:
  /// **'{count} New'**
  String newNotifCount(String count);

  /// No description provided for @lessonLibrary.
  ///
  /// In en, this message translates to:
  /// **'LESSON LIBRARY'**
  String get lessonLibrary;

  /// No description provided for @lessonsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} lessons'**
  String lessonsCountLabel(String count);

  /// No description provided for @searchLessonsTopics.
  ///
  /// In en, this message translates to:
  /// **'Search lessons & topics...'**
  String get searchLessonsTopics;

  /// No description provided for @notFound.
  ///
  /// In en, this message translates to:
  /// **'Not Found'**
  String get notFound;

  /// No description provided for @assignmentNotFound.
  ///
  /// In en, this message translates to:
  /// **'Assignment not found.'**
  String get assignmentNotFound;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @feedbackLabel.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedbackLabel;

  /// No description provided for @writeFeedbackHint.
  ///
  /// In en, this message translates to:
  /// **'Write your feedback here...'**
  String get writeFeedbackHint;

  /// No description provided for @saveGrade.
  ///
  /// In en, this message translates to:
  /// **'Save Grade'**
  String get saveGrade;

  /// No description provided for @gradeSaved.
  ///
  /// In en, this message translates to:
  /// **'Grade saved successfully'**
  String get gradeSaved;

  /// No description provided for @assignmentDetails.
  ///
  /// In en, this message translates to:
  /// **'Assignment Details'**
  String get assignmentDetails;

  /// No description provided for @instructionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get instructionsLabel;

  /// No description provided for @createdByLabel.
  ///
  /// In en, this message translates to:
  /// **'Created by'**
  String get createdByLabel;

  /// No description provided for @optionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get optionsLabel;

  /// No description provided for @submissionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Submissions'**
  String get submissionsLabel;

  /// No description provided for @noSubmissionsYet.
  ///
  /// In en, this message translates to:
  /// **'No submissions yet'**
  String get noSubmissionsYet;

  /// No description provided for @selectedChoice.
  ///
  /// In en, this message translates to:
  /// **'Selected Choice'**
  String get selectedChoice;

  /// No description provided for @instructorFeedback.
  ///
  /// In en, this message translates to:
  /// **'Instructor Feedback'**
  String get instructorFeedback;

  /// No description provided for @addInstructor.
  ///
  /// In en, this message translates to:
  /// **'Add Instructor'**
  String get addInstructor;

  /// No description provided for @noInstructorsFound.
  ///
  /// In en, this message translates to:
  /// **'No instructors found'**
  String get noInstructorsFound;

  /// No description provided for @addButton.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addButton;

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @addStudent.
  ///
  /// In en, this message translates to:
  /// **'Add Student'**
  String get addStudent;

  /// No description provided for @createNewStudent.
  ///
  /// In en, this message translates to:
  /// **'Create New Student'**
  String get createNewStudent;

  /// No description provided for @generateCredentialsAuto.
  ///
  /// In en, this message translates to:
  /// **'Generate credentials automatically'**
  String get generateCredentialsAuto;

  /// No description provided for @noStudentsFound.
  ///
  /// In en, this message translates to:
  /// **'No students found'**
  String get noStudentsFound;

  /// No description provided for @createStudent.
  ///
  /// In en, this message translates to:
  /// **'Create Student'**
  String get createStudent;

  /// No description provided for @fullNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullNameLabel;

  /// No description provided for @assignToLevel.
  ///
  /// In en, this message translates to:
  /// **'Assign to Level'**
  String get assignToLevel;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @createButton.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createButton;

  /// No description provided for @studentAdded.
  ///
  /// In en, this message translates to:
  /// **'Student Added'**
  String get studentAdded;

  /// No description provided for @doneButton.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get doneButton;

  /// No description provided for @pinResetTitle.
  ///
  /// In en, this message translates to:
  /// **'PIN Reset'**
  String get pinResetTitle;

  /// No description provided for @searchByNameEmail.
  ///
  /// In en, this message translates to:
  /// **'Search by name or email...'**
  String get searchByNameEmail;

  /// No description provided for @groupDetails.
  ///
  /// In en, this message translates to:
  /// **'Group Details'**
  String get groupDetails;

  /// No description provided for @deleteGroup.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroup;

  /// No description provided for @totalMembersLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Members'**
  String get totalMembersLabel;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {group}?'**
  String deleteGroupConfirm(String group);

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @groupDeleted.
  ///
  /// In en, this message translates to:
  /// **'{group} deleted'**
  String groupDeleted(String group);

  /// No description provided for @noInstructorsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No instructors assigned'**
  String get noInstructorsAssigned;

  /// No description provided for @searchByNameUsername.
  ///
  /// In en, this message translates to:
  /// **'Search by name or username...'**
  String get searchByNameUsername;

  /// No description provided for @allLevels.
  ///
  /// In en, this message translates to:
  /// **'All Levels'**
  String get allLevels;

  /// No description provided for @resetPin.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN'**
  String get resetPin;

  /// No description provided for @removeFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove from Group'**
  String get removeFromGroup;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete Permanently'**
  String get deletePermanently;

  /// No description provided for @deleteStudent.
  ///
  /// In en, this message translates to:
  /// **'Delete Student'**
  String get deleteStudent;

  /// No description provided for @deleteStudentConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete {student}?'**
  String deleteStudentConfirm(String student);

  /// No description provided for @studentDeleted.
  ///
  /// In en, this message translates to:
  /// **'{student} deleted'**
  String studentDeleted(String student);

  /// No description provided for @lessonLabel.
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get lessonLabel;

  /// No description provided for @viewAsPdfTooltip.
  ///
  /// In en, this message translates to:
  /// **'View as PDF'**
  String get viewAsPdfTooltip;

  /// No description provided for @level1Label.
  ///
  /// In en, this message translates to:
  /// **'Level 1'**
  String get level1Label;

  /// No description provided for @week1Foundations.
  ///
  /// In en, this message translates to:
  /// **'Week 1: Foundations'**
  String get week1Foundations;

  /// No description provided for @studentDetails.
  ///
  /// In en, this message translates to:
  /// **'Student Details'**
  String get studentDetails;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @recentSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Recent Submissions'**
  String get recentSubmissions;

  /// No description provided for @reactFundamentalsQuiz.
  ///
  /// In en, this message translates to:
  /// **'React Fundamentals Quiz'**
  String get reactFundamentalsQuiz;

  /// No description provided for @reactLibraryDesc.
  ///
  /// In en, this message translates to:
  /// **'React library description'**
  String get reactLibraryDesc;

  /// No description provided for @submittedLabel.
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get submittedLabel;

  /// No description provided for @editAnswer.
  ///
  /// In en, this message translates to:
  /// **'Edit Answer'**
  String get editAnswer;

  /// No description provided for @changeAnswer.
  ///
  /// In en, this message translates to:
  /// **'Change Answer'**
  String get changeAnswer;

  /// No description provided for @assignmentSaved.
  ///
  /// In en, this message translates to:
  /// **'Assignment saved'**
  String get assignmentSaved;

  /// No description provided for @addLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Level'**
  String get addLevelTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Week'**
  String get addWeekTitle;

  /// No description provided for @addMaterialTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Material'**
  String get addMaterialTitle;

  /// No description provided for @addAssignmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Assignment'**
  String get addAssignmentTitle;

  /// No description provided for @curriculumTitle.
  ///
  /// In en, this message translates to:
  /// **'Curriculum'**
  String get curriculumTitle;

  /// No description provided for @levelsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Levels'**
  String levelsCount(String count);

  /// No description provided for @weeksCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Weeks'**
  String weeksCount(String count);

  /// No description provided for @itemsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Items'**
  String itemsCount(String count);

  /// No description provided for @noItemsYet.
  ///
  /// In en, this message translates to:
  /// **'No items yet'**
  String get noItemsYet;

  /// No description provided for @addMaterial.
  ///
  /// In en, this message translates to:
  /// **'Add Material'**
  String get addMaterial;

  /// No description provided for @addAssignment.
  ///
  /// In en, this message translates to:
  /// **'Add Assignment'**
  String get addAssignment;

  /// No description provided for @deleteGroupTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Group'**
  String get deleteGroupTitle;

  /// No description provided for @deleteGroupConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete {group}?'**
  String deleteGroupConfirmation(String group);

  /// No description provided for @groupDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{group} deleted'**
  String groupDeletedSuccess(String group);

  /// No description provided for @groupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groupsTitle;

  /// No description provided for @groupsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Groups'**
  String groupsCount(String count);

  /// No description provided for @searchGroups.
  ///
  /// In en, this message translates to:
  /// **'Search groups...'**
  String get searchGroups;

  /// No description provided for @addInstructorTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Instructor'**
  String get addInstructorTitle;

  /// No description provided for @assignLevels.
  ///
  /// In en, this message translates to:
  /// **'Assign Levels'**
  String get assignLevels;

  /// No description provided for @levelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String levelLabel(String level);

  /// No description provided for @instructorAddedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Instructor added. Welcome email with login details sent.'**
  String get instructorAddedSuccess;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile for {name} updated'**
  String profileUpdated(String name);

  /// No description provided for @selectLevelsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select levels'**
  String get selectLevelsSubtitle;

  /// No description provided for @levelsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Levels for {name} updated'**
  String levelsUpdated(String name);

  /// No description provided for @staffInstructorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Staff Instructors'**
  String get staffInstructorsTitle;

  /// No description provided for @instructorsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Instructors'**
  String instructorsCount(String count);

  /// No description provided for @deleteUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUserTitle;

  /// No description provided for @deleteUserConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteUserConfirmation(String name);

  /// No description provided for @userDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String userDeletedSuccess(String name);

  /// No description provided for @auditLogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit Logs'**
  String get auditLogsTitle;

  /// No description provided for @entriesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} Entries'**
  String entriesCount(String count);

  /// No description provided for @searchActionsUsers.
  ///
  /// In en, this message translates to:
  /// **'Search actions or users...'**
  String get searchActionsUsers;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New Group'**
  String get newGroup;

  /// No description provided for @createNewGroupDesc.
  ///
  /// In en, this message translates to:
  /// **'Create a new group'**
  String get createNewGroupDesc;

  /// No description provided for @groupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupNameHint;

  /// No description provided for @groupCreated.
  ///
  /// In en, this message translates to:
  /// **'{name} created'**
  String groupCreated(String name);

  /// No description provided for @assignMaterial.
  ///
  /// In en, this message translates to:
  /// **'Assign Material'**
  String get assignMaterial;

  /// No description provided for @selectGroupStep.
  ///
  /// In en, this message translates to:
  /// **'Select Group'**
  String get selectGroupStep;

  /// No description provided for @chooseGroupHint.
  ///
  /// In en, this message translates to:
  /// **'Choose group'**
  String get chooseGroupHint;

  /// No description provided for @selectLevelHint.
  ///
  /// In en, this message translates to:
  /// **'Select level'**
  String get selectLevelHint;

  /// No description provided for @targetLevelsStep.
  ///
  /// In en, this message translates to:
  /// **'Target Levels'**
  String get targetLevelsStep;

  /// No description provided for @deadlineStep.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadlineStep;

  /// No description provided for @materialsLabel.
  ///
  /// In en, this message translates to:
  /// **'Materials'**
  String get materialsLabel;

  /// No description provided for @searchMaterials.
  ///
  /// In en, this message translates to:
  /// **'Search materials...'**
  String get searchMaterials;

  /// No description provided for @assignToLevelTooltip.
  ///
  /// In en, this message translates to:
  /// **'Assign to Level'**
  String get assignToLevelTooltip;

  /// No description provided for @activityLabel.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityLabel;

  /// No description provided for @searchByActionName.
  ///
  /// In en, this message translates to:
  /// **'Search by action name...'**
  String get searchByActionName;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get myTasks;

  /// No description provided for @searchAssignments.
  ///
  /// In en, this message translates to:
  /// **'Search assignments...'**
  String get searchAssignments;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// No description provided for @studentRoleLabel.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get studentRoleLabel;

  /// No description provided for @accountInfo.
  ///
  /// In en, this message translates to:
  /// **'Account Info'**
  String get accountInfo;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @imageNotLoaded.
  ///
  /// In en, this message translates to:
  /// **'Image not loaded'**
  String get imageNotLoaded;

  /// No description provided for @secureModeEnabled.
  ///
  /// In en, this message translates to:
  /// **'Secure mode enabled'**
  String get secureModeEnabled;

  /// No description provided for @studentIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Student ID'**
  String get studentIdLabel;

  /// No description provided for @profileLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get profileLevelLabel;

  /// No description provided for @profileGroupLabel.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get profileGroupLabel;

  /// No description provided for @instructorsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'INSTRUCTORS'**
  String get instructorsSectionTitle;

  /// No description provided for @studentsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'STUDENTS'**
  String get studentsSectionTitle;

  /// No description provided for @studentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} students'**
  String studentsCount(String count);

  /// No description provided for @createdOnLabel.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String createdOnLabel(String date);

  /// No description provided for @levelOneLabel.
  ///
  /// In en, this message translates to:
  /// **'Level 1'**
  String get levelOneLabel;

  /// No description provided for @levelTwoLabel.
  ///
  /// In en, this message translates to:
  /// **'Level 2'**
  String get levelTwoLabel;

  /// No description provided for @levelThreeLabel.
  ///
  /// In en, this message translates to:
  /// **'Level 3'**
  String get levelThreeLabel;

  /// No description provided for @submittedTimeAgo.
  ///
  /// In en, this message translates to:
  /// **'Submitted {time}'**
  String submittedTimeAgo(String time);

  /// No description provided for @timeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String timeAgoMinutes(String count);

  /// No description provided for @timeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String timeAgoHours(String count);

  /// No description provided for @timeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String timeAgoDays(String count);

  /// No description provided for @timeNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get timeNever;

  /// No description provided for @timeOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get timeOnline;

  /// No description provided for @dueDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Due {deadline}'**
  String dueDeadlineLabel(String deadline);

  /// No description provided for @typeAnswerHint.
  ///
  /// In en, this message translates to:
  /// **'Type your answer here...'**
  String get typeAnswerHint;

  /// No description provided for @submissionLocked.
  ///
  /// In en, this message translates to:
  /// **'Submission locked.'**
  String get submissionLocked;

  /// No description provided for @deadlinePassedLocked.
  ///
  /// In en, this message translates to:
  /// **'Deadline passed! Submissions are locked.'**
  String get deadlinePassedLocked;

  /// No description provided for @noAnswerProvided.
  ///
  /// In en, this message translates to:
  /// **'No answer provided.'**
  String get noAnswerProvided;

  /// No description provided for @submissionsWaitingReview.
  ///
  /// In en, this message translates to:
  /// **'{count} submissions waiting for your review'**
  String submissionsWaitingReview(String count);

  /// No description provided for @centralBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Central'**
  String get centralBadgeLabel;

  /// No description provided for @customBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get customBadgeLabel;

  /// No description provided for @closedBadgeLabel.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closedBadgeLabel;

  /// No description provided for @pendingCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingCountLabel(String count);

  /// No description provided for @gradedCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} graded'**
  String gradedCountLabel(String count);

  /// No description provided for @filterRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get filterRoleAdmin;

  /// No description provided for @filterTimeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterTimeToday;

  /// No description provided for @filterTime7Days.
  ///
  /// In en, this message translates to:
  /// **'7 Days'**
  String get filterTime7Days;

  /// No description provided for @filterTime30Days.
  ///
  /// In en, this message translates to:
  /// **'30 Days'**
  String get filterTime30Days;

  /// No description provided for @newPinForStudent.
  ///
  /// In en, this message translates to:
  /// **'New PIN for {name}:'**
  String newPinForStudent(String name);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get timeJustNow;

  /// No description provided for @timeAgoWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String timeAgoWeeks(String count);

  /// No description provided for @actionCreatedLevel.
  ///
  /// In en, this message translates to:
  /// **'Created new level'**
  String get actionCreatedLevel;

  /// No description provided for @actionAddedInstructor.
  ///
  /// In en, this message translates to:
  /// **'Added instructor'**
  String get actionAddedInstructor;

  /// No description provided for @actionCreatedAssignment.
  ///
  /// In en, this message translates to:
  /// **'Created assignment'**
  String get actionCreatedAssignment;

  /// No description provided for @actionGradedSubmission.
  ///
  /// In en, this message translates to:
  /// **'Graded submission'**
  String get actionGradedSubmission;

  /// No description provided for @actionSubmittedAssignment.
  ///
  /// In en, this message translates to:
  /// **'Submitted assignment'**
  String get actionSubmittedAssignment;

  /// No description provided for @actionRevisedGrade.
  ///
  /// In en, this message translates to:
  /// **'Revised grade'**
  String get actionRevisedGrade;

  /// No description provided for @actionAddedStudent.
  ///
  /// In en, this message translates to:
  /// **'Added new student'**
  String get actionAddedStudent;

  /// No description provided for @actionResetPin.
  ///
  /// In en, this message translates to:
  /// **'Reset student PIN'**
  String get actionResetPin;

  /// No description provided for @actionJoinedGroup.
  ///
  /// In en, this message translates to:
  /// **'Joined group'**
  String get actionJoinedGroup;

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'PIN'**
  String get pinLabel;

  /// No description provided for @noContentProvided.
  ///
  /// In en, this message translates to:
  /// **'No content provided.'**
  String get noContentProvided;

  /// No description provided for @pdfDocumentLabel.
  ///
  /// In en, this message translates to:
  /// **'PDF Document'**
  String get pdfDocumentLabel;

  /// No description provided for @viewLabel.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get viewLabel;

  /// No description provided for @hintAssignmentInstructions.
  ///
  /// In en, this message translates to:
  /// **'Assignment instructions...'**
  String get hintAssignmentInstructions;

  /// No description provided for @hintEnterQuestion.
  ///
  /// In en, this message translates to:
  /// **'Enter your question here...'**
  String get hintEnterQuestion;

  /// No description provided for @hintOptionN.
  ///
  /// In en, this message translates to:
  /// **'Option {n}'**
  String hintOptionN(String n);

  /// No description provided for @addOptionButton.
  ///
  /// In en, this message translates to:
  /// **'Add Option'**
  String get addOptionButton;

  /// No description provided for @assignmentAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" assigned!'**
  String assignmentAssignedSuccess(String title);

  /// No description provided for @nSelected.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String nSelected(String count);

  /// No description provided for @bulkCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Students'**
  String get bulkCreateTitle;

  /// No description provided for @addAnotherStudent.
  ///
  /// In en, this message translates to:
  /// **'Add Another'**
  String get addAnotherStudent;

  /// No description provided for @addNStudents.
  ///
  /// In en, this message translates to:
  /// **'Add {count} Students'**
  String addNStudents(String count);

  /// No description provided for @createNStudents.
  ///
  /// In en, this message translates to:
  /// **'Create {count} Students'**
  String createNStudents(String count);

  /// No description provided for @studentsCreatedBulk.
  ///
  /// In en, this message translates to:
  /// **'{count} Students Created'**
  String studentsCreatedBulk(String count);

  /// No description provided for @enterNamesPerLine.
  ///
  /// In en, this message translates to:
  /// **'Enter or paste student names (one per line):'**
  String get enterNamesPerLine;

  /// No description provided for @assignSelectedToLevel.
  ///
  /// In en, this message translates to:
  /// **'Assign selected to:'**
  String get assignSelectedToLevel;

  /// No description provided for @addNStudentsToLevel.
  ///
  /// In en, this message translates to:
  /// **'Add {count} to {level}'**
  String addNStudentsToLevel(String count, String level);

  /// No description provided for @fromAdminTemplate.
  ///
  /// In en, this message translates to:
  /// **'From Admin Template'**
  String get fromAdminTemplate;

  /// No description provided for @fromAdminTemplateDesc.
  ///
  /// In en, this message translates to:
  /// **'Assign a fixed admin curriculum item to your group'**
  String get fromAdminTemplateDesc;

  /// No description provided for @adminTemplates.
  ///
  /// In en, this message translates to:
  /// **'Admin Templates'**
  String get adminTemplates;

  /// No description provided for @noTemplatesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No templates available.'**
  String get noTemplatesAvailable;

  /// No description provided for @centralTemplate.
  ///
  /// In en, this message translates to:
  /// **'Central · Template'**
  String get centralTemplate;

  /// No description provided for @assignTemplateTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign \"{title}\"'**
  String assignTemplateTitle(String title);

  /// No description provided for @assignmentAssignedToGroup.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" assigned to {group}'**
  String assignmentAssignedToGroup(String title, String group);

  /// No description provided for @assignmentAssignedToGroupLevel.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" assigned to {group} ({level})'**
  String assignmentAssignedToGroupLevel(
    String title,
    String group,
    String level,
  );

  /// No description provided for @assignmentAlreadyAssignedGroupLevel.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" is already assigned to {group} for {level}!'**
  String assignmentAlreadyAssignedGroupLevel(
    String title,
    String group,
    String level,
  );

  /// No description provided for @totalCount.
  ///
  /// In en, this message translates to:
  /// **'{count} total'**
  String totalCount(String count);

  /// No description provided for @activeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} active'**
  String activeCount(String count);

  /// No description provided for @pastCount.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String pastCount(String count);

  /// No description provided for @editGroupName.
  ///
  /// In en, this message translates to:
  /// **'Edit Group Name'**
  String get editGroupName;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get groupName;

  /// No description provided for @deleteGroupConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this group?\nStudents count: {studentCount}\nInstructors count: {instructorCount}'**
  String deleteGroupConfirmDesc(String studentCount, String instructorCount);

  /// No description provided for @deleteGroupWarning.
  ///
  /// In en, this message translates to:
  /// **'The group can be restored by an admin from the Archive.'**
  String get deleteGroupWarning;

  /// No description provided for @editName.
  ///
  /// In en, this message translates to:
  /// **'Edit Name'**
  String get editName;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @addAnotherStudentLabel.
  ///
  /// In en, this message translates to:
  /// **'+ Add Another Student'**
  String get addAnotherStudentLabel;

  /// No description provided for @requiredFieldError.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get requiredFieldError;

  /// No description provided for @usernameFormatError.
  ///
  /// In en, this message translates to:
  /// **'Lowercase, no spaces'**
  String get usernameFormatError;

  /// No description provided for @insertImageUrlTooltip.
  ///
  /// In en, this message translates to:
  /// **'Insert Image URL'**
  String get insertImageUrlTooltip;

  /// No description provided for @insertImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Insert Image'**
  String get insertImageTitle;

  /// No description provided for @insertButton.
  ///
  /// In en, this message translates to:
  /// **'Insert'**
  String get insertButton;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @usernameAlreadyTaken.
  ///
  /// In en, this message translates to:
  /// **'Username already taken'**
  String get usernameAlreadyTaken;

  /// No description provided for @failedToCreateStudent.
  ///
  /// In en, this message translates to:
  /// **'Failed to create student: {error}'**
  String failedToCreateStudent(String error);

  /// No description provided for @pinCopiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'PIN copied to clipboard'**
  String get pinCopiedToClipboard;

  /// No description provided for @iHaveSavedPin.
  ///
  /// In en, this message translates to:
  /// **'I have saved the PIN'**
  String get iHaveSavedPin;

  /// No description provided for @resetPinConfirm.
  ///
  /// In en, this message translates to:
  /// **'Reset PIN?'**
  String get resetPinConfirm;

  /// No description provided for @resetPinConfirmDesc.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset the PIN for {name}? This will generate a new 6-digit random PIN.'**
  String resetPinConfirmDesc(String name);

  /// No description provided for @failedToResetPin.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset PIN: {error}'**
  String failedToResetPin(String error);

  /// No description provided for @failedToDeleteStudent.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete {name}: {error}'**
  String failedToDeleteStudent(String name, String error);

  /// No description provided for @groupRenamed.
  ///
  /// In en, this message translates to:
  /// **'Group renamed to \"{name}\"'**
  String groupRenamed(String name);

  /// No description provided for @failedToRenameGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to rename group: {error}'**
  String failedToRenameGroup(String error);

  /// No description provided for @groupMovedToArchive.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" moved to archive'**
  String groupMovedToArchive(String name);

  /// No description provided for @failedToArchiveGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to archive group: {error}'**
  String failedToArchiveGroup(String error);

  /// No description provided for @failedToCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Failed to create group: {error}'**
  String failedToCreateGroup(String error);

  /// No description provided for @assignMaterialTitle.
  ///
  /// In en, this message translates to:
  /// **'Assign Material \"{title}\"'**
  String assignMaterialTitle(String title);

  /// No description provided for @currentAssignments.
  ///
  /// In en, this message translates to:
  /// **'Assigned Groups'**
  String get currentAssignments;

  /// No description provided for @noGroupAssignmentsYet.
  ///
  /// In en, this message translates to:
  /// **'Not assigned to any groups yet.'**
  String get noGroupAssignmentsYet;

  /// No description provided for @alreadyAssignedToGroupLevel.
  ///
  /// In en, this message translates to:
  /// **'Material is already assigned to this group and level!'**
  String get alreadyAssignedToGroupLevel;

  /// No description provided for @levelLowerError.
  ///
  /// In en, this message translates to:
  /// **'Cannot assign material to a lower group level!'**
  String get levelLowerError;

  /// No description provided for @materialAssignedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Material assigned successfully!'**
  String get materialAssignedSuccess;

  /// No description provided for @materialLevelLabel.
  ///
  /// In en, this message translates to:
  /// **'Material Level: {level}'**
  String materialLevelLabel(String level);

  /// No description provided for @peopleAndUsers.
  ///
  /// In en, this message translates to:
  /// **'People & Users'**
  String get peopleAndUsers;

  /// No description provided for @curriculumContent.
  ///
  /// In en, this message translates to:
  /// **'Curriculum & Content'**
  String get curriculumContent;

  /// No description provided for @activeToday.
  ///
  /// In en, this message translates to:
  /// **'active today'**
  String get activeToday;

  /// No description provided for @statTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statTotal;

  /// No description provided for @gradingOverview.
  ///
  /// In en, this message translates to:
  /// **'Grading Overview'**
  String get gradingOverview;

  /// No description provided for @totalSubmissions.
  ///
  /// In en, this message translates to:
  /// **'Total Submissions'**
  String get totalSubmissions;

  /// No description provided for @gradedCorrectIndicator.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get gradedCorrectIndicator;

  /// No description provided for @gradedIncorrectIndicator.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get gradedIncorrectIndicator;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @overviewDashboard.
  ///
  /// In en, this message translates to:
  /// **'Overview Dashboard'**
  String get overviewDashboard;

  /// No description provided for @adminUserName.
  ///
  /// In en, this message translates to:
  /// **'Admin User'**
  String get adminUserName;

  /// No description provided for @adminAuthorityLevel.
  ///
  /// In en, this message translates to:
  /// **'Level 1 Authority'**
  String get adminAuthorityLevel;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @notificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTooltip;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @logoutButton.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutButton;

  /// No description provided for @languageButton.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageButton;

  /// No description provided for @superAdmin.
  ///
  /// In en, this message translates to:
  /// **'Super Admin'**
  String get superAdmin;

  /// No description provided for @statusOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get statusOnline;

  /// No description provided for @globalSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search students, instructors, groups…'**
  String get globalSearchHint;

  /// No description provided for @darkModeComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Dark mode coming soon'**
  String get darkModeComingSoon;

  /// No description provided for @fromLastMonth.
  ///
  /// In en, this message translates to:
  /// **'from last month'**
  String get fromLastMonth;

  /// No description provided for @badgeAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get badgeAssignment;

  /// No description provided for @badgeGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get badgeGroup;

  /// No description provided for @badgeLesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson'**
  String get badgeLesson;

  /// No description provided for @badgeUser.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get badgeUser;

  /// No description provided for @badgeSubmission.
  ///
  /// In en, this message translates to:
  /// **'Submission'**
  String get badgeSubmission;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
