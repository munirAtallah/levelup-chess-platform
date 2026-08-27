// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get loginEmailRequired => 'Email is required';

  @override
  String loginPasswordResetSentMsg(String email) {
    return 'Password reset sent to $email';
  }

  @override
  String get emailHint => 'Email';

  @override
  String get passwordHint => 'Password';

  @override
  String get usernameHint => 'Username';

  @override
  String get pinHint => 'PIN';

  @override
  String get signInButton => 'Sign In';

  @override
  String get loginToggleStudent => 'Student';

  @override
  String get loginToggleStaff => 'Staff';

  @override
  String get loginEmailAddressLabel => 'Email Address';

  @override
  String get loginPasswordLabel => 'Password';

  @override
  String get loginForgotPassword => 'Forgot Password?';

  @override
  String get loginUsernameLabel => 'Username';

  @override
  String get loginPinCodeLabel => 'PIN Code';

  @override
  String get navHome => 'Home';

  @override
  String get navCurriculum => 'Curriculum';

  @override
  String get navUsers => 'Users';

  @override
  String get navGroups => 'Groups';

  @override
  String get navLogs => 'Logs';

  @override
  String get navMaterials => 'Materials';

  @override
  String get navTasks => 'Tasks';

  @override
  String get navActivity => 'Activity';

  @override
  String get navLearn => 'Learn';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navProfile => 'Profile';

  @override
  String get welcomeBack => 'Welcome back,';

  @override
  String get roleAdministrator => 'Administrator';

  @override
  String get loggingOut => 'Logging out...';

  @override
  String get platformOverview => 'PLATFORM OVERVIEW';

  @override
  String get platformStatistics => 'PLATFORM STATISTICS';

  @override
  String get statisticsTitle => 'Statistics';

  @override
  String get statStudents => 'Students';

  @override
  String get statInstructors => 'Instructors';

  @override
  String get statLevels => 'Levels';

  @override
  String get statActiveTasks => 'Active Tasks';

  @override
  String get statLessons => 'Lessons';

  @override
  String get statGroups => 'Groups';

  @override
  String get recentActivity => 'RECENT ACTIVITY';

  @override
  String get seeAll => 'See all';

  @override
  String get noRecentActivity => 'No recent activity';

  @override
  String get levelNameLabel => 'Level Name';

  @override
  String get weekNameLabel => 'Week Name';

  @override
  String get materialTitleLabel => 'Material Title';

  @override
  String get contentLabel => 'Content';

  @override
  String get assignmentTitleLabel => 'Assignment Title';

  @override
  String get searchLessonsTags => 'Search lessons & tags...';

  @override
  String get noLevelsYet => 'No levels yet';

  @override
  String get addFirstLevel => 'Add your first study level to get started';

  @override
  String get noGroupsFound => 'No groups found';

  @override
  String get tryDifferentSearch => 'Try a different search term';

  @override
  String get allRoles => 'All Roles';

  @override
  String get allTime => 'All Time';

  @override
  String get roleInstructor => 'Instructor';

  @override
  String get phoneNumberLabel => 'Phone Number';

  @override
  String get homeAddressLabel => 'Home Address';

  @override
  String get emailAddressLabel => 'Email Address';

  @override
  String editProfileTitle(String name) {
    return 'Edit Profile – $name';
  }

  @override
  String editLevelsTitle(String name) {
    return 'Edit Levels – $name';
  }

  @override
  String get levelBeginner => 'Level 1 – Beginner';

  @override
  String get levelIntermediate => 'Level 2 – Intermediate';

  @override
  String get levelAdvanced => 'Level 3 – Advanced';

  @override
  String get noLevelsAssigned => 'No levels assigned';

  @override
  String get gradeSubmission => 'Grade Submission';

  @override
  String get reviseGrade => 'Revise Grade';

  @override
  String get statusCorrect => 'Correct';

  @override
  String get statusIncorrect => 'Incorrect';

  @override
  String get statusPartial => 'Partial';

  @override
  String get statusPending => 'Pending';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get noGroupAssigned => 'No Group Assigned';

  @override
  String get noStudentSubmissions =>
      'Students haven\'t submitted their answers';

  @override
  String get gradeButton => 'Grade';

  @override
  String get shareCredentialsMsg =>
      'Share these login credentials with the student';

  @override
  String get credFullName => 'Full Name';

  @override
  String get credUsername => 'Username';

  @override
  String get credPinCode => 'PIN Code';

  @override
  String get credStudentNumber => 'Student #';

  @override
  String get noStudentsInGroup => 'No students found';

  @override
  String get addStudentsOrSearch => 'Add students or adjust search';

  @override
  String get yourAnswer => 'YOUR ANSWER';

  @override
  String get gradedCorrect => 'Graded: Correct';

  @override
  String get gradedIncorrect => 'Graded: Incorrect';

  @override
  String get updateAssignment => 'Update Assignment';

  @override
  String get submitAssignment => 'Submit Assignment';

  @override
  String get statSubmissionsLabel => 'Submissions';

  @override
  String get statGradedLabel => 'Graded';

  @override
  String get statCorrectLabel => 'Correct';

  @override
  String get createAssignment => 'Create Assignment';

  @override
  String get chooseCreationMethod => 'Choose how to create your assignment';

  @override
  String get fromCurriculumPool => 'From Curriculum Pool';

  @override
  String get fromCurriculumPoolDesc =>
      'Assign a task from the admin\'s weekly curriculum';

  @override
  String get createFromScratch => 'Create From Scratch';

  @override
  String get createFromScratchDesc => 'Write a new text-based assignment';

  @override
  String get curriculumPoolTitle => 'Curriculum Pool';

  @override
  String get assignmentsTitle => 'Assignments';

  @override
  String get textAnswerType => 'Text Answer';

  @override
  String get multipleChoiceType => 'Multiple Choice';

  @override
  String get selectDeadline => 'Select Deadline *';

  @override
  String get titleAndDeadlineRequired => 'Title and deadline are required';

  @override
  String get atLeast2Options => 'Please provide at least 2 options';

  @override
  String get tabActive => 'Active';

  @override
  String get tabPast => 'Overdue';

  @override
  String get filterAll => 'All';

  @override
  String get filterOverdue => 'Overdue';

  @override
  String get filterCentral => 'Central';

  @override
  String get filterCustom => 'Custom';

  @override
  String get noAssignments => 'No assignments';

  @override
  String get noAssignmentsSubtitle => 'Create one or change filters';

  @override
  String get editContent => 'Edit Content';

  @override
  String get editDeadlineMenu => 'Edit Deadline';

  @override
  String get deleteAssignment => 'Delete Assignment';

  @override
  String deadlineUpdated(String title) {
    return 'Deadline for \"$title\" updated.';
  }

  @override
  String get titleRequired => 'Title is required';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get deleteAssignmentConfirm =>
      'Are you sure you want to permanently delete this assignment?';

  @override
  String assignmentDeleted(String title) {
    return '\"$title\" has been deleted.';
  }

  @override
  String levelsAndBrowse(String count) {
    return '$count levels · Browse & assign';
  }

  @override
  String get noResults => 'No results';

  @override
  String get tryDifferentKeyword => 'Try a different keyword';

  @override
  String get noCurriculum => 'No curriculum';

  @override
  String get adminNotAddedCurriculum =>
      'The admin has not added curriculum yet';

  @override
  String get myGroupsTitle => 'My Groups';

  @override
  String groupsAssignedCount(String count) {
    return '$count groups assigned';
  }

  @override
  String get roleInstructorLabel => 'Instructor';

  @override
  String get activeBadge => 'ACTIVE NOW';

  @override
  String get dashboardAssignments => 'Assignments';

  @override
  String get dashboardMyGroups => 'My Groups';

  @override
  String get myOverview => 'MY OVERVIEW';

  @override
  String get statMyGroups => 'My Groups';

  @override
  String get statPendingReview => 'Pending Review';

  @override
  String get navigatingToStudents => 'Navigating to student roster...';

  @override
  String get activeAssignmentsHeader => 'ACTIVE ASSIGNMENTS';

  @override
  String get categoryAll => 'All';

  @override
  String get categoryGrading => 'Grading';

  @override
  String get categoryStudents => 'Students';

  @override
  String get categoryAssignments => 'Assignments';

  @override
  String get categoryCurriculum => 'Curriculum';

  @override
  String countTotalShown(String total, String shown) {
    return '$total total · $shown shown';
  }

  @override
  String get noActivityFound => 'No activity found';

  @override
  String get tryAdjustingSearch => 'Try adjusting your search or filter';

  @override
  String pendingTabCount(String count) {
    return 'Pending ($count)';
  }

  @override
  String submittedTabCount(String count) {
    return 'Submitted ($count)';
  }

  @override
  String get noPendingTasks => 'No pending tasks';

  @override
  String get allCaughtUp => 'You are all caught up!';

  @override
  String get noSubmittedTasks => 'No submitted tasks';

  @override
  String get submitFirstAssignment => 'Submit your first assignment';

  @override
  String get alertsTitle => 'Alerts';

  @override
  String notificationsCount(String count) {
    return '$count notifications';
  }

  @override
  String newNotificationsCount(String count) {
    return '$count new';
  }

  @override
  String get noNotifications => 'No notifications';

  @override
  String get allCaughtUpNotif => 'You\'re all caught up!';

  @override
  String helloGreeting(String name) {
    return 'Hello, $name';
  }

  @override
  String get lessonsSection => 'LESSONS';

  @override
  String tasksDueCount(String count) {
    return '$count Tasks Due';
  }

  @override
  String newNotifCount(String count) {
    return '$count New';
  }

  @override
  String get lessonLibrary => 'LESSON LIBRARY';

  @override
  String lessonsCountLabel(String count) {
    return '$count lessons';
  }

  @override
  String get searchLessonsTopics => 'Search lessons & topics...';

  @override
  String get notFound => 'Not Found';

  @override
  String get assignmentNotFound => 'Assignment not found.';

  @override
  String get statusLabel => 'Status';

  @override
  String get feedbackLabel => 'Feedback';

  @override
  String get writeFeedbackHint => 'Write your feedback here...';

  @override
  String get saveGrade => 'Save Grade';

  @override
  String get gradeSaved => 'Grade saved successfully';

  @override
  String get assignmentDetails => 'Assignment Details';

  @override
  String get instructionsLabel => 'Instructions';

  @override
  String get createdByLabel => 'Created by';

  @override
  String get optionsLabel => 'Options';

  @override
  String get submissionsLabel => 'Submissions';

  @override
  String get noSubmissionsYet => 'No submissions yet';

  @override
  String get selectedChoice => 'Selected Choice';

  @override
  String get instructorFeedback => 'Instructor Feedback';

  @override
  String get addInstructor => 'Add Instructor';

  @override
  String get noInstructorsFound => 'No instructors found';

  @override
  String get addButton => 'Add';

  @override
  String get closeButton => 'Close';

  @override
  String get addStudent => 'Add Student';

  @override
  String get createNewStudent => 'Create New Student';

  @override
  String get generateCredentialsAuto => 'Generate credentials automatically';

  @override
  String get noStudentsFound => 'No students found';

  @override
  String get createStudent => 'Create Student';

  @override
  String get fullNameLabel => 'Full Name';

  @override
  String get assignToLevel => 'Assign to Level';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get createButton => 'Create';

  @override
  String get studentAdded => 'Student Added';

  @override
  String get doneButton => 'Done';

  @override
  String get pinResetTitle => 'PIN Reset';

  @override
  String get searchByNameEmail => 'Search by name or email...';

  @override
  String get groupDetails => 'Group Details';

  @override
  String get deleteGroup => 'Delete Group';

  @override
  String get totalMembersLabel => 'Total Members';

  @override
  String deleteGroupConfirm(String group) {
    return 'Delete $group?';
  }

  @override
  String get deleteButton => 'Delete';

  @override
  String get delete => 'Delete';

  @override
  String groupDeleted(String group) {
    return '$group deleted';
  }

  @override
  String get noInstructorsAssigned => 'No instructors assigned';

  @override
  String get searchByNameUsername => 'Search by name or username...';

  @override
  String get allLevels => 'All Levels';

  @override
  String get resetPin => 'Reset PIN';

  @override
  String get removeFromGroup => 'Remove from Group';

  @override
  String get deletePermanently => 'Delete Permanently';

  @override
  String get deleteStudent => 'Delete Student';

  @override
  String deleteStudentConfirm(String student) {
    return 'Delete $student?';
  }

  @override
  String studentDeleted(String student) {
    return '$student deleted';
  }

  @override
  String get lessonLabel => 'Lesson';

  @override
  String get viewAsPdfTooltip => 'View as PDF';

  @override
  String get level1Label => 'Level 1';

  @override
  String get week1Foundations => 'Week 1: Foundations';

  @override
  String get studentDetails => 'Student Details';

  @override
  String get accountDetails => 'Account Details';

  @override
  String get recentSubmissions => 'Recent Submissions';

  @override
  String get reactFundamentalsQuiz => 'React Fundamentals Quiz';

  @override
  String get reactLibraryDesc => 'React library description';

  @override
  String get submittedLabel => 'Submitted';

  @override
  String get editAnswer => 'Edit Answer';

  @override
  String get changeAnswer => 'Change Answer';

  @override
  String get assignmentSaved => 'Assignment saved';

  @override
  String get addLevelTitle => 'Add Level';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get addWeekTitle => 'Add Week';

  @override
  String get addMaterialTitle => 'Add Material';

  @override
  String get addAssignmentTitle => 'Add Assignment';

  @override
  String get curriculumTitle => 'Curriculum';

  @override
  String levelsCount(String count) {
    return '$count Levels';
  }

  @override
  String weeksCount(String count) {
    return '$count Weeks';
  }

  @override
  String itemsCount(String count) {
    return '$count Items';
  }

  @override
  String get noItemsYet => 'No items yet';

  @override
  String get addMaterial => 'Add Material';

  @override
  String get addAssignment => 'Add Assignment';

  @override
  String get deleteGroupTitle => 'Delete Group';

  @override
  String deleteGroupConfirmation(String group) {
    return 'Delete $group?';
  }

  @override
  String groupDeletedSuccess(String group) {
    return '$group deleted';
  }

  @override
  String get groupsTitle => 'Groups';

  @override
  String groupsCount(String count) {
    return '$count Groups';
  }

  @override
  String get searchGroups => 'Search groups...';

  @override
  String get addInstructorTitle => 'Add Instructor';

  @override
  String get assignLevels => 'Assign Levels';

  @override
  String levelLabel(String level) {
    return 'Level $level';
  }

  @override
  String get instructorAddedSuccess =>
      'Instructor added. Welcome email with login details sent.';

  @override
  String get save => 'Save';

  @override
  String profileUpdated(String name) {
    return 'Profile for $name updated';
  }

  @override
  String get selectLevelsSubtitle => 'Select levels';

  @override
  String levelsUpdated(String name) {
    return 'Levels for $name updated';
  }

  @override
  String get staffInstructorsTitle => 'Staff Instructors';

  @override
  String instructorsCount(String count) {
    return '$count Instructors';
  }

  @override
  String get deleteUserTitle => 'Delete User';

  @override
  String deleteUserConfirmation(String name) {
    return 'Delete $name?';
  }

  @override
  String userDeletedSuccess(String name) {
    return '$name deleted';
  }

  @override
  String get auditLogsTitle => 'Audit Logs';

  @override
  String entriesCount(String count) {
    return '$count Entries';
  }

  @override
  String get searchActionsUsers => 'Search actions or users...';

  @override
  String get newGroup => 'New Group';

  @override
  String get createNewGroupDesc => 'Create a new group';

  @override
  String get groupNameHint => 'Group Name';

  @override
  String groupCreated(String name) {
    return '$name created';
  }

  @override
  String get assignMaterial => 'Assign Material';

  @override
  String get selectGroupStep => 'Select Group';

  @override
  String get chooseGroupHint => 'Choose group';

  @override
  String get selectLevelHint => 'Select level';

  @override
  String get targetLevelsStep => 'Target Levels';

  @override
  String get deadlineStep => 'Deadline';

  @override
  String get materialsLabel => 'Materials';

  @override
  String get searchMaterials => 'Search materials...';

  @override
  String get assignToLevelTooltip => 'Assign to Level';

  @override
  String get activityLabel => 'Activity';

  @override
  String get searchByActionName => 'Search by action name...';

  @override
  String get myTasks => 'My Tasks';

  @override
  String get searchAssignments => 'Search assignments...';

  @override
  String get myProfile => 'My Profile';

  @override
  String get studentRoleLabel => 'Student';

  @override
  String get accountInfo => 'Account Info';

  @override
  String get signOut => 'Sign Out';

  @override
  String get imageNotLoaded => 'Image not loaded';

  @override
  String get secureModeEnabled => 'Secure mode enabled';

  @override
  String get studentIdLabel => 'Student ID';

  @override
  String get profileLevelLabel => 'Level';

  @override
  String get profileGroupLabel => 'Group';

  @override
  String get instructorsSectionTitle => 'INSTRUCTORS';

  @override
  String get studentsSectionTitle => 'STUDENTS';

  @override
  String studentsCount(String count) {
    return '$count students';
  }

  @override
  String createdOnLabel(String date) {
    return 'Created: $date';
  }

  @override
  String get levelOneLabel => 'Level 1';

  @override
  String get levelTwoLabel => 'Level 2';

  @override
  String get levelThreeLabel => 'Level 3';

  @override
  String submittedTimeAgo(String time) {
    return 'Submitted $time';
  }

  @override
  String timeAgoMinutes(String count) {
    return '${count}m ago';
  }

  @override
  String timeAgoHours(String count) {
    return '${count}h ago';
  }

  @override
  String timeAgoDays(String count) {
    return '${count}d ago';
  }

  @override
  String get timeNever => 'Never';

  @override
  String get timeOnline => 'Online';

  @override
  String dueDeadlineLabel(String deadline) {
    return 'Due $deadline';
  }

  @override
  String get typeAnswerHint => 'Type your answer here...';

  @override
  String get submissionLocked => 'Submission locked.';

  @override
  String get deadlinePassedLocked => 'Deadline passed! Submissions are locked.';

  @override
  String get noAnswerProvided => 'No answer provided.';

  @override
  String submissionsWaitingReview(String count) {
    return '$count submissions waiting for your review';
  }

  @override
  String get centralBadgeLabel => 'Central';

  @override
  String get customBadgeLabel => 'Custom';

  @override
  String get closedBadgeLabel => 'Closed';

  @override
  String pendingCountLabel(String count) {
    return '$count pending';
  }

  @override
  String gradedCountLabel(String count) {
    return '$count graded';
  }

  @override
  String get filterRoleAdmin => 'Admin';

  @override
  String get filterTimeToday => 'Today';

  @override
  String get filterTime7Days => '7 Days';

  @override
  String get filterTime30Days => '30 Days';

  @override
  String newPinForStudent(String name) {
    return 'New PIN for $name:';
  }

  @override
  String get timeJustNow => 'Just now';

  @override
  String timeAgoWeeks(String count) {
    return '${count}w ago';
  }

  @override
  String get actionCreatedLevel => 'Created new level';

  @override
  String get actionAddedInstructor => 'Added instructor';

  @override
  String get actionCreatedAssignment => 'Created assignment';

  @override
  String get actionGradedSubmission => 'Graded submission';

  @override
  String get actionSubmittedAssignment => 'Submitted assignment';

  @override
  String get actionRevisedGrade => 'Revised grade';

  @override
  String get actionAddedStudent => 'Added new student';

  @override
  String get actionResetPin => 'Reset student PIN';

  @override
  String get actionJoinedGroup => 'Joined group';

  @override
  String get pinLabel => 'PIN';

  @override
  String get noContentProvided => 'No content provided.';

  @override
  String get pdfDocumentLabel => 'PDF Document';

  @override
  String get viewLabel => 'View';

  @override
  String get hintAssignmentInstructions => 'Assignment instructions...';

  @override
  String get hintEnterQuestion => 'Enter your question here...';

  @override
  String hintOptionN(String n) {
    return 'Option $n';
  }

  @override
  String get addOptionButton => 'Add Option';

  @override
  String assignmentAssignedSuccess(String title) {
    return '\"$title\" assigned!';
  }

  @override
  String nSelected(String count) {
    return '$count selected';
  }

  @override
  String get bulkCreateTitle => 'Create Students';

  @override
  String get addAnotherStudent => 'Add Another';

  @override
  String addNStudents(String count) {
    return 'Add $count Students';
  }

  @override
  String createNStudents(String count) {
    return 'Create $count Students';
  }

  @override
  String studentsCreatedBulk(String count) {
    return '$count Students Created';
  }

  @override
  String get enterNamesPerLine =>
      'Enter or paste student names (one per line):';

  @override
  String get assignSelectedToLevel => 'Assign selected to:';

  @override
  String addNStudentsToLevel(String count, String level) {
    return 'Add $count to $level';
  }

  @override
  String get fromAdminTemplate => 'From Admin Template';

  @override
  String get fromAdminTemplateDesc =>
      'Assign a fixed admin curriculum item to your group';

  @override
  String get adminTemplates => 'Admin Templates';

  @override
  String get noTemplatesAvailable => 'No templates available.';

  @override
  String get centralTemplate => 'Central · Template';

  @override
  String assignTemplateTitle(String title) {
    return 'Assign \"$title\"';
  }

  @override
  String assignmentAssignedToGroup(String title, String group) {
    return '\"$title\" assigned to $group';
  }

  @override
  String assignmentAssignedToGroupLevel(
    String title,
    String group,
    String level,
  ) {
    return '\"$title\" assigned to $group ($level)';
  }

  @override
  String assignmentAlreadyAssignedGroupLevel(
    String title,
    String group,
    String level,
  ) {
    return '\"$title\" is already assigned to $group for $level!';
  }

  @override
  String totalCount(String count) {
    return '$count total';
  }

  @override
  String activeCount(String count) {
    return '$count active';
  }

  @override
  String pastCount(String count) {
    return '$count overdue';
  }

  @override
  String get editGroupName => 'Edit Group Name';

  @override
  String get groupName => 'Group Name';

  @override
  String deleteGroupConfirmDesc(String studentCount, String instructorCount) {
    return 'Are you sure you want to delete this group?\nStudents count: $studentCount\nInstructors count: $instructorCount';
  }

  @override
  String get deleteGroupWarning =>
      'The group can be restored by an admin from the Archive.';

  @override
  String get editName => 'Edit Name';

  @override
  String get archive => 'Archive';

  @override
  String get addAnotherStudentLabel => '+ Add Another Student';

  @override
  String get requiredFieldError => 'Required';

  @override
  String get usernameFormatError => 'Lowercase, no spaces';

  @override
  String get insertImageUrlTooltip => 'Insert Image URL';

  @override
  String get insertImageTitle => 'Insert Image';

  @override
  String get insertButton => 'Insert';

  @override
  String get assign => 'Assign';

  @override
  String get usernameAlreadyTaken => 'Username already taken';

  @override
  String failedToCreateStudent(String error) {
    return 'Failed to create student: $error';
  }

  @override
  String get pinCopiedToClipboard => 'PIN copied to clipboard';

  @override
  String get iHaveSavedPin => 'I have saved the PIN';

  @override
  String get resetPinConfirm => 'Reset PIN?';

  @override
  String resetPinConfirmDesc(String name) {
    return 'Are you sure you want to reset the PIN for $name? This will generate a new 6-digit random PIN.';
  }

  @override
  String failedToResetPin(String error) {
    return 'Failed to reset PIN: $error';
  }

  @override
  String failedToDeleteStudent(String name, String error) {
    return 'Failed to delete $name: $error';
  }

  @override
  String groupRenamed(String name) {
    return 'Group renamed to \"$name\"';
  }

  @override
  String failedToRenameGroup(String error) {
    return 'Failed to rename group: $error';
  }

  @override
  String groupMovedToArchive(String name) {
    return '\"$name\" moved to archive';
  }

  @override
  String failedToArchiveGroup(String error) {
    return 'Failed to archive group: $error';
  }

  @override
  String failedToCreateGroup(String error) {
    return 'Failed to create group: $error';
  }

  @override
  String assignMaterialTitle(String title) {
    return 'Assign Material \"$title\"';
  }

  @override
  String get currentAssignments => 'Assigned Groups';

  @override
  String get noGroupAssignmentsYet => 'Not assigned to any groups yet.';

  @override
  String get alreadyAssignedToGroupLevel =>
      'Material is already assigned to this group and level!';

  @override
  String get levelLowerError =>
      'Cannot assign material to a lower group level!';

  @override
  String get materialAssignedSuccess => 'Material assigned successfully!';

  @override
  String materialLevelLabel(String level) {
    return 'Material Level: $level';
  }

  @override
  String get peopleAndUsers => 'People & Users';

  @override
  String get curriculumContent => 'Curriculum & Content';

  @override
  String get activeToday => 'active today';

  @override
  String get statTotal => 'Total';

  @override
  String get gradingOverview => 'Grading Overview';

  @override
  String get totalSubmissions => 'Total Submissions';

  @override
  String get gradedCorrectIndicator => 'Correct';

  @override
  String get gradedIncorrectIndicator => 'Incorrect';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get overviewDashboard => 'Overview Dashboard';

  @override
  String get adminUserName => 'Admin User';

  @override
  String get adminAuthorityLevel => 'Level 1 Authority';

  @override
  String get searchHint => 'Search...';

  @override
  String get notificationsTooltip => 'Notifications';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get logoutButton => 'Logout';

  @override
  String get languageButton => 'Language';

  @override
  String get superAdmin => 'Super Admin';

  @override
  String get statusOnline => 'Online';

  @override
  String get globalSearchHint => 'Search students, instructors, groups…';

  @override
  String get darkModeComingSoon => 'Dark mode coming soon';

  @override
  String get fromLastMonth => 'from last month';

  @override
  String get badgeAssignment => 'Assignment';

  @override
  String get badgeGroup => 'Group';

  @override
  String get badgeLesson => 'Lesson';

  @override
  String get badgeUser => 'User';

  @override
  String get badgeSubmission => 'Submission';
}
