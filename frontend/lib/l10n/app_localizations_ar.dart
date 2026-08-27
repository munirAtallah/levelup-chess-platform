// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get loginEmailRequired => 'البريد الإلكتروني مطلوب';

  @override
  String loginPasswordResetSentMsg(String email) {
    return 'تم إرسال إعادة تعيين كلمة المرور إلى $email';
  }

  @override
  String get emailHint => 'البريد الإلكتروني';

  @override
  String get passwordHint => 'كلمة المرور';

  @override
  String get usernameHint => 'اسم المستخدم';

  @override
  String get pinHint => 'رمز PIN';

  @override
  String get signInButton => 'تسجيل الدخول';

  @override
  String get loginToggleStudent => 'طالب';

  @override
  String get loginToggleStaff => 'موظف';

  @override
  String get loginEmailAddressLabel => 'البريد الإلكتروني';

  @override
  String get loginPasswordLabel => 'كلمة المرور';

  @override
  String get loginForgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get loginUsernameLabel => 'اسم المستخدم';

  @override
  String get loginPinCodeLabel => 'رمز PIN';

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navCurriculum => 'المنهج';

  @override
  String get navUsers => 'المستخدمون';

  @override
  String get navGroups => 'المجموعات';

  @override
  String get navLogs => 'السجلات';

  @override
  String get navMaterials => 'المواد';

  @override
  String get navTasks => 'المهام';

  @override
  String get navActivity => 'النشاط';

  @override
  String get navLearn => 'التعلم';

  @override
  String get navAlerts => 'التنبيهات';

  @override
  String get navProfile => 'الملف الشخصي';

  @override
  String get welcomeBack => 'مرحباً بعودتك،';

  @override
  String get roleAdministrator => 'المشرف';

  @override
  String get loggingOut => 'جارٍ تسجيل الخروج...';

  @override
  String get platformOverview => 'نظرة عامة على المنصة';

  @override
  String get platformStatistics => 'إحصائيات المنصة';

  @override
  String get statisticsTitle => 'الإحصائيات';

  @override
  String get statStudents => 'الطلاب';

  @override
  String get statInstructors => 'المحاضرون';

  @override
  String get statLevels => 'المستويات';

  @override
  String get statActiveTasks => 'المهام النشطة';

  @override
  String get statLessons => 'الدروس';

  @override
  String get statGroups => 'المجموعات';

  @override
  String get recentActivity => 'النشاط الأخير';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get noRecentActivity => 'لا يوجد نشاط حديث';

  @override
  String get levelNameLabel => 'اسم المستوى';

  @override
  String get weekNameLabel => 'اسم الأسبوع';

  @override
  String get materialTitleLabel => 'عنوان المادة';

  @override
  String get contentLabel => 'المحتوى';

  @override
  String get assignmentTitleLabel => 'عنوان المهمة';

  @override
  String get searchLessonsTags => 'ابحث في الدروس والوسوم...';

  @override
  String get noLevelsYet => 'لا توجد مستويات بعد';

  @override
  String get addFirstLevel => 'أضف أول مستوى دراسي للبدء';

  @override
  String get noGroupsFound => 'لم يتم العثور على مجموعات';

  @override
  String get tryDifferentSearch => 'جرّب مصطلح بحث مختلف';

  @override
  String get allRoles => 'جميع الأدوار';

  @override
  String get allTime => 'كل الأوقات';

  @override
  String get roleInstructor => 'المحاضر';

  @override
  String get phoneNumberLabel => 'رقم الهاتف';

  @override
  String get homeAddressLabel => 'العنوان';

  @override
  String get emailAddressLabel => 'البريد الإلكتروني';

  @override
  String editProfileTitle(String name) {
    return 'تعديل الملف – $name';
  }

  @override
  String editLevelsTitle(String name) {
    return 'تعديل المستويات – $name';
  }

  @override
  String get levelBeginner => 'المستوى 1 – مبتدئ';

  @override
  String get levelIntermediate => 'المستوى 2 – متوسط';

  @override
  String get levelAdvanced => 'المستوى 3 – متقدم';

  @override
  String get noLevelsAssigned => 'لم يتم تعيين مستويات';

  @override
  String get gradeSubmission => 'تقييم التسليم';

  @override
  String get reviseGrade => 'مراجعة التقييم';

  @override
  String get statusCorrect => 'صحيح';

  @override
  String get statusIncorrect => 'خاطئ';

  @override
  String get statusPartial => 'جزئي';

  @override
  String get statusPending => 'في الانتظار';

  @override
  String get statusActive => 'نشط';

  @override
  String get statusInactive => 'غير نشط';

  @override
  String get noGroupAssigned => 'لم يتم تعيين مجموعة';

  @override
  String get noStudentSubmissions => 'لم يقدم الطلاب إجاباتهم بعد';

  @override
  String get gradeButton => 'تقييم';

  @override
  String get shareCredentialsMsg => 'شارك بيانات تسجيل الدخول مع الطالب';

  @override
  String get credFullName => 'الاسم الكامل';

  @override
  String get credUsername => 'اسم المستخدم';

  @override
  String get credPinCode => 'رمز PIN';

  @override
  String get credStudentNumber => 'رقم الطالب';

  @override
  String get noStudentsInGroup => 'لا يوجد طلاب';

  @override
  String get addStudentsOrSearch => 'أضف طلاباً أو عدّل البحث';

  @override
  String get yourAnswer => 'إجابتك';

  @override
  String get gradedCorrect => 'التقييم: صحيح';

  @override
  String get gradedIncorrect => 'التقييم: خاطئ';

  @override
  String get updateAssignment => 'تحديث المهمة';

  @override
  String get submitAssignment => 'تسليم المهمة';

  @override
  String get statSubmissionsLabel => 'التسليمات';

  @override
  String get statGradedLabel => 'المُقيَّم';

  @override
  String get statCorrectLabel => 'الصحيح';

  @override
  String get createAssignment => 'إنشاء مهمة';

  @override
  String get chooseCreationMethod => 'اختر طريقة إنشاء مهمتك';

  @override
  String get fromCurriculumPool => 'من مجموعة المنهج';

  @override
  String get fromCurriculumPoolDesc => 'عيّن مهمة من المنهج الأسبوعي للمشرف';

  @override
  String get createFromScratch => 'إنشاء من الصفر';

  @override
  String get createFromScratchDesc => 'اكتب مهمة نصية جديدة';

  @override
  String get curriculumPoolTitle => 'مجموعة المنهج';

  @override
  String get assignmentsTitle => 'المهام';

  @override
  String get textAnswerType => 'إجابة نصية';

  @override
  String get multipleChoiceType => 'اختيار متعدد';

  @override
  String get selectDeadline => 'اختر الموعد النهائي *';

  @override
  String get titleAndDeadlineRequired => 'العنوان والموعد النهائي مطلوبان';

  @override
  String get atLeast2Options => 'يرجى توفير خيارين على الأقل';

  @override
  String get tabActive => 'نشط';

  @override
  String get tabPast => 'متأخرة';

  @override
  String get filterAll => 'الكل';

  @override
  String get filterOverdue => 'متأخرة';

  @override
  String get filterCentral => 'مركزية';

  @override
  String get filterCustom => 'مخصصة';

  @override
  String get noAssignments => 'لا توجد مهام';

  @override
  String get noAssignmentsSubtitle => 'أنشئ مهمة أو غيّر الفلاتر';

  @override
  String get editContent => 'تعديل المحتوى';

  @override
  String get editDeadlineMenu => 'تعديل الموعد النهائي';

  @override
  String get deleteAssignment => 'حذف المهمة';

  @override
  String deadlineUpdated(String title) {
    return 'تم تحديث الموعد النهائي لـ \"$title\".';
  }

  @override
  String get titleRequired => 'العنوان مطلوب';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get deleteAssignmentConfirm =>
      'هل أنت متأكد من حذف هذه المهمة نهائياً؟';

  @override
  String assignmentDeleted(String title) {
    return 'تم حذف \"$title\".';
  }

  @override
  String levelsAndBrowse(String count) {
    return '$count مستوى · تصفح وعيّن';
  }

  @override
  String get noResults => 'لا توجد نتائج';

  @override
  String get tryDifferentKeyword => 'جرّب كلمة بحث مختلفة';

  @override
  String get noCurriculum => 'لا يوجد منهج';

  @override
  String get adminNotAddedCurriculum => 'لم يضف المشرف المنهج بعد';

  @override
  String get myGroupsTitle => 'مجموعاتي';

  @override
  String groupsAssignedCount(String count) {
    return 'تم تعيين $count مجموعة';
  }

  @override
  String get roleInstructorLabel => 'المحاضر';

  @override
  String get activeBadge => 'نشط الآن';

  @override
  String get dashboardAssignments => 'المهام';

  @override
  String get dashboardMyGroups => 'مجموعاتي';

  @override
  String get myOverview => 'نظرتي العامة';

  @override
  String get statMyGroups => 'مجموعاتي';

  @override
  String get statPendingReview => 'بانتظار المراجعة';

  @override
  String get navigatingToStudents => 'جارٍ الانتقال إلى قائمة الطلاب...';

  @override
  String get activeAssignmentsHeader => 'المهام النشطة';

  @override
  String get categoryAll => 'الكل';

  @override
  String get categoryGrading => 'التقييم';

  @override
  String get categoryStudents => 'الطلاب';

  @override
  String get categoryAssignments => 'المهام';

  @override
  String get categoryCurriculum => 'المنهج';

  @override
  String countTotalShown(String total, String shown) {
    return '$total إجمالي · $shown معروض';
  }

  @override
  String get noActivityFound => 'لا يوجد نشاط';

  @override
  String get tryAdjustingSearch => 'جرّب تعديل البحث أو الفلتر';

  @override
  String pendingTabCount(String count) {
    return 'في الانتظار ($count)';
  }

  @override
  String submittedTabCount(String count) {
    return 'تم التسليم ($count)';
  }

  @override
  String get noPendingTasks => 'لا توجد مهام معلقة';

  @override
  String get allCaughtUp => 'أنجزت جميع مهامك!';

  @override
  String get noSubmittedTasks => 'لا توجد مهام مسلّمة';

  @override
  String get submitFirstAssignment => 'سلّم مهمتك الأولى';

  @override
  String get alertsTitle => 'التنبيهات';

  @override
  String notificationsCount(String count) {
    return '$count إشعار';
  }

  @override
  String newNotificationsCount(String count) {
    return '$count جديد';
  }

  @override
  String get noNotifications => 'لا توجد إشعارات';

  @override
  String get allCaughtUpNotif => 'أنجزت جميع مهامك!';

  @override
  String helloGreeting(String name) {
    return 'مرحباً، $name';
  }

  @override
  String get lessonsSection => 'الدروس';

  @override
  String tasksDueCount(String count) {
    return '$count مهام مستحقة';
  }

  @override
  String newNotifCount(String count) {
    return '$count جديد';
  }

  @override
  String get lessonLibrary => 'مكتبة الدروس';

  @override
  String lessonsCountLabel(String count) {
    return '$count درس';
  }

  @override
  String get searchLessonsTopics => 'ابحث في الدروس والمواضيع...';

  @override
  String get notFound => 'غير موجود';

  @override
  String get assignmentNotFound => 'المهمة غير موجودة.';

  @override
  String get statusLabel => 'الحالة';

  @override
  String get feedbackLabel => 'التغذية الراجعة';

  @override
  String get writeFeedbackHint => 'اكتب ملاحظاتك هنا...';

  @override
  String get saveGrade => 'حفظ التقييم';

  @override
  String get gradeSaved => 'تم حفظ التقييم بنجاح';

  @override
  String get assignmentDetails => 'تفاصيل المهمة';

  @override
  String get instructionsLabel => 'التعليمات';

  @override
  String get createdByLabel => 'بواسطة';

  @override
  String get optionsLabel => 'الخيارات';

  @override
  String get submissionsLabel => 'التسليمات';

  @override
  String get noSubmissionsYet => 'لا توجد تسليمات بعد';

  @override
  String get selectedChoice => 'الخيار المحدد';

  @override
  String get instructorFeedback => 'ملاحظات المحاضر';

  @override
  String get addInstructor => 'إضافة محاضر';

  @override
  String get noInstructorsFound => 'لم يتم العثور على محاضرين';

  @override
  String get addButton => 'إضافة';

  @override
  String get closeButton => 'إغلاق';

  @override
  String get addStudent => 'إضافة طالب';

  @override
  String get createNewStudent => 'إنشاء طالب جديد';

  @override
  String get generateCredentialsAuto => 'إنشاء بيانات الاعتماد تلقائياً';

  @override
  String get noStudentsFound => 'لم يتم العثور على طلاب';

  @override
  String get createStudent => 'إنشاء طالب';

  @override
  String get fullNameLabel => 'الاسم الكامل';

  @override
  String get assignToLevel => 'تعيين إلى مستوى';

  @override
  String get cancelButton => 'إلغاء';

  @override
  String get createButton => 'إنشاء';

  @override
  String get studentAdded => 'تمت إضافة الطالب';

  @override
  String get doneButton => 'تم';

  @override
  String get pinResetTitle => 'إعادة تعيين PIN';

  @override
  String get searchByNameEmail => 'البحث بالاسم أو البريد الإلكتروني...';

  @override
  String get groupDetails => 'تفاصيل المجموعة';

  @override
  String get deleteGroup => 'حذف المجموعة';

  @override
  String get totalMembersLabel => 'إجمالي الأعضاء';

  @override
  String deleteGroupConfirm(String group) {
    return 'حذف $group؟';
  }

  @override
  String get deleteButton => 'حذف';

  @override
  String get delete => 'حذف';

  @override
  String groupDeleted(String group) {
    return 'تم حذف $group';
  }

  @override
  String get noInstructorsAssigned => 'لم يتم تعيين محاضرين';

  @override
  String get searchByNameUsername => 'البحث بالاسم أو اسم المستخدم...';

  @override
  String get allLevels => 'جميع المستويات';

  @override
  String get resetPin => 'إعادة تعيين PIN';

  @override
  String get removeFromGroup => 'إزالة من المجموعة';

  @override
  String get deletePermanently => 'حذف نهائي';

  @override
  String get deleteStudent => 'حذف الطالب';

  @override
  String deleteStudentConfirm(String student) {
    return 'حذف $student؟';
  }

  @override
  String studentDeleted(String student) {
    return 'تم حذف $student';
  }

  @override
  String get lessonLabel => 'الدرس';

  @override
  String get viewAsPdfTooltip => 'عرض كـ PDF';

  @override
  String get level1Label => 'المستوى 1';

  @override
  String get week1Foundations => 'الأسبوع 1: الأساسيات';

  @override
  String get studentDetails => 'تفاصيل الطالب';

  @override
  String get accountDetails => 'تفاصيل الحساب';

  @override
  String get recentSubmissions => 'التسليمات الأخيرة';

  @override
  String get reactFundamentalsQuiz => 'اختبار أساسيات React';

  @override
  String get reactLibraryDesc => 'وصف مكتبة React';

  @override
  String get submittedLabel => 'تم التسليم';

  @override
  String get editAnswer => 'تعديل الإجابة';

  @override
  String get changeAnswer => 'تغيير الإجابة';

  @override
  String get assignmentSaved => 'تم حفظ المهمة';

  @override
  String get addLevelTitle => 'إضافة مستوى';

  @override
  String get cancel => 'إلغاء';

  @override
  String get add => 'إضافة';

  @override
  String get addWeekTitle => 'إضافة أسبوع';

  @override
  String get addMaterialTitle => 'إضافة مادة';

  @override
  String get addAssignmentTitle => 'إضافة مهمة';

  @override
  String get curriculumTitle => 'المنهج';

  @override
  String levelsCount(String count) {
    return '$count مستويات';
  }

  @override
  String weeksCount(String count) {
    return '$count أسابيع';
  }

  @override
  String itemsCount(String count) {
    return '$count عناصر';
  }

  @override
  String get noItemsYet => 'لا توجد عناصر بعد';

  @override
  String get addMaterial => 'إضافة مادة';

  @override
  String get addAssignment => 'إضافة مهمة';

  @override
  String get deleteGroupTitle => 'حذف المجموعة';

  @override
  String deleteGroupConfirmation(String group) {
    return 'حذف $group؟';
  }

  @override
  String groupDeletedSuccess(String group) {
    return 'تم حذف $group';
  }

  @override
  String get groupsTitle => 'المجموعات';

  @override
  String groupsCount(String count) {
    return '$count مجموعات';
  }

  @override
  String get searchGroups => 'البحث في المجموعات...';

  @override
  String get addInstructorTitle => 'إضافة محاضر';

  @override
  String get assignLevels => 'تعيين المستويات';

  @override
  String levelLabel(String level) {
    return 'المستوى $level';
  }

  @override
  String get instructorAddedSuccess =>
      'تمت إضافة المحاضر. تم إرسال بريد إلكتروني ترحيبي مع تفاصيل تسجيل الدخول.';

  @override
  String get save => 'حفظ';

  @override
  String profileUpdated(String name) {
    return 'تم تحديث ملف $name';
  }

  @override
  String get selectLevelsSubtitle => 'اختر المستويات';

  @override
  String levelsUpdated(String name) {
    return 'تم تحديث مستويات $name';
  }

  @override
  String get staffInstructorsTitle => 'المحاضرون';

  @override
  String instructorsCount(String count) {
    return '$count محاضر';
  }

  @override
  String get deleteUserTitle => 'حذف المستخدم';

  @override
  String deleteUserConfirmation(String name) {
    return 'حذف $name؟';
  }

  @override
  String userDeletedSuccess(String name) {
    return 'تم حذف $name';
  }

  @override
  String get auditLogsTitle => 'سجلات المراجعة';

  @override
  String entriesCount(String count) {
    return '$count إدخال';
  }

  @override
  String get searchActionsUsers => 'البحث في الإجراءات أو المستخدمين...';

  @override
  String get newGroup => 'مجموعة جديدة';

  @override
  String get createNewGroupDesc => 'إنشاء مجموعة جديدة';

  @override
  String get groupNameHint => 'اسم المجموعة';

  @override
  String groupCreated(String name) {
    return 'تم إنشاء $name';
  }

  @override
  String get assignMaterial => 'تعيين مادة';

  @override
  String get selectGroupStep => 'اختر المجموعة';

  @override
  String get chooseGroupHint => 'اختر مجموعة';

  @override
  String get selectLevelHint => 'اختر مستوى';

  @override
  String get targetLevelsStep => 'المستويات المستهدفة';

  @override
  String get deadlineStep => 'الموعد النهائي';

  @override
  String get materialsLabel => 'المواد';

  @override
  String get searchMaterials => 'البحث في المواد...';

  @override
  String get assignToLevelTooltip => 'تعيين إلى مستوى';

  @override
  String get activityLabel => 'النشاط';

  @override
  String get searchByActionName => 'البحث باسم الإجراء...';

  @override
  String get myTasks => 'مهامي';

  @override
  String get searchAssignments => 'البحث في المهام...';

  @override
  String get myProfile => 'ملفي الشخصي';

  @override
  String get studentRoleLabel => 'طالب';

  @override
  String get accountInfo => 'معلومات الحساب';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get imageNotLoaded => 'تعذر تحميل الصورة';

  @override
  String get secureModeEnabled => 'تم تفعيل الوضع الآمن';

  @override
  String get studentIdLabel => 'رقم الطالب';

  @override
  String get profileLevelLabel => 'المستوى';

  @override
  String get profileGroupLabel => 'المجموعة';

  @override
  String get instructorsSectionTitle => 'المحاضرون';

  @override
  String get studentsSectionTitle => 'الطلاب';

  @override
  String studentsCount(String count) {
    return '$count طالب';
  }

  @override
  String createdOnLabel(String date) {
    return 'تاريخ الإنشاء: $date';
  }

  @override
  String get levelOneLabel => 'المستوى 1';

  @override
  String get levelTwoLabel => 'المستوى 2';

  @override
  String get levelThreeLabel => 'المستوى 3';

  @override
  String submittedTimeAgo(String time) {
    return 'تم التسليم $time';
  }

  @override
  String timeAgoMinutes(String count) {
    return 'منذ $count د';
  }

  @override
  String timeAgoHours(String count) {
    return 'منذ $count س';
  }

  @override
  String timeAgoDays(String count) {
    return 'منذ $count ي';
  }

  @override
  String get timeNever => 'أبداً';

  @override
  String get timeOnline => 'متصل';

  @override
  String dueDeadlineLabel(String deadline) {
    return 'الموعد: $deadline';
  }

  @override
  String get typeAnswerHint => 'اكتب إجابتك هنا...';

  @override
  String get submissionLocked => 'المهمة مغلقة.';

  @override
  String get deadlinePassedLocked =>
      'انتهى الموعد النهائي! تم قفل تقديم الإجابات.';

  @override
  String get noAnswerProvided => 'لم تُقدَّم إجابة.';

  @override
  String submissionsWaitingReview(String count) {
    return '$count تسليم بانتظار مراجعتك';
  }

  @override
  String get centralBadgeLabel => 'مركزية';

  @override
  String get customBadgeLabel => 'مخصصة';

  @override
  String get closedBadgeLabel => 'مغلق';

  @override
  String pendingCountLabel(String count) {
    return 'في الانتظار $count';
  }

  @override
  String gradedCountLabel(String count) {
    return 'مُقيَّم $count';
  }

  @override
  String get filterRoleAdmin => 'مشرف';

  @override
  String get filterTimeToday => 'اليوم';

  @override
  String get filterTime7Days => '7 أيام';

  @override
  String get filterTime30Days => '30 يوماً';

  @override
  String newPinForStudent(String name) {
    return 'رمز PIN الجديد لـ $name:';
  }

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeAgoWeeks(String count) {
    return 'منذ $count أ';
  }

  @override
  String get actionCreatedLevel => 'أنشأ مستوى جديد';

  @override
  String get actionAddedInstructor => 'أضاف مدرساً';

  @override
  String get actionCreatedAssignment => 'أنشأ واجباً';

  @override
  String get actionGradedSubmission => 'صحّح التسليم';

  @override
  String get actionSubmittedAssignment => 'سلّم الواجب';

  @override
  String get actionRevisedGrade => 'راجع الدرجة';

  @override
  String get actionAddedStudent => 'أضاف طالباً جديداً';

  @override
  String get actionResetPin => 'أعاد تعيين رمز الطالب';

  @override
  String get actionJoinedGroup => 'انضم للمجموعة';

  @override
  String get pinLabel => 'الرمز السري';

  @override
  String get noContentProvided => 'لا يوجد محتوى.';

  @override
  String get pdfDocumentLabel => 'مستند PDF';

  @override
  String get viewLabel => 'عرض';

  @override
  String get hintAssignmentInstructions => 'تعليمات الواجب...';

  @override
  String get hintEnterQuestion => 'أدخل سؤالك هنا...';

  @override
  String hintOptionN(String n) {
    return 'الخيار $n';
  }

  @override
  String get addOptionButton => 'إضافة خيار';

  @override
  String assignmentAssignedSuccess(String title) {
    return 'تم تعيين \"$title\"!';
  }

  @override
  String nSelected(String count) {
    return '$count محدد';
  }

  @override
  String get bulkCreateTitle => 'إنشاء طلاب';

  @override
  String get addAnotherStudent => 'إضافة آخر';

  @override
  String addNStudents(String count) {
    return 'إضافة $count طلاب';
  }

  @override
  String createNStudents(String count) {
    return 'إنشاء $count طلاب';
  }

  @override
  String studentsCreatedBulk(String count) {
    return 'تم إنشاء $count طلاب';
  }

  @override
  String get enterNamesPerLine =>
      'أدخل أسماء الطلاب أو الصقها (اسم في كل سطر):';

  @override
  String get assignSelectedToLevel => 'إضافة المحددين إلى:';

  @override
  String addNStudentsToLevel(String count, String level) {
    return 'إضافة $count إلى $level';
  }

  @override
  String get fromAdminTemplate => 'من قالب المشرف';

  @override
  String get fromAdminTemplateDesc => 'تعيين عنصر منهج ثابت من المشرف لمجموعتك';

  @override
  String get adminTemplates => 'قوالب المشرف';

  @override
  String get noTemplatesAvailable => 'لا توجد قوالب متاحة.';

  @override
  String get centralTemplate => 'مركزي · قالب';

  @override
  String assignTemplateTitle(String title) {
    return 'تعيين \"$title\"';
  }

  @override
  String assignmentAssignedToGroup(String title, String group) {
    return 'تم تعيين \"$title\" للمجموعة $group';
  }

  @override
  String assignmentAssignedToGroupLevel(
    String title,
    String group,
    String level,
  ) {
    return 'تم تعيين \"$title\" للمجموعة $group ($level)';
  }

  @override
  String assignmentAlreadyAssignedGroupLevel(
    String title,
    String group,
    String level,
  ) {
    return '\"$title\" معين بالفعل للمجموعة $group في $level!';
  }

  @override
  String totalCount(String count) {
    return 'الإجمالي $count';
  }

  @override
  String activeCount(String count) {
    return 'النشطة $count';
  }

  @override
  String pastCount(String count) {
    return 'متأخرة $count';
  }

  @override
  String get editGroupName => 'تعديل اسم المجموعة';

  @override
  String get groupName => 'اسم المجموعة';

  @override
  String deleteGroupConfirmDesc(String studentCount, String instructorCount) {
    return 'هل أنت متأكد من حذف هذه المجموعة؟\nعدد الطلاب: $studentCount\nعدد المحاضرين: $instructorCount';
  }

  @override
  String get deleteGroupWarning =>
      'يمكن استعادة المجموعة بواسطة المشرف من الأرشيف.';

  @override
  String get editName => 'تعديل الاسم';

  @override
  String get archive => 'أرشفة';

  @override
  String get addAnotherStudentLabel => '+ إضافة طالب آخر';

  @override
  String get requiredFieldError => 'مطلوب';

  @override
  String get usernameFormatError => 'أحرف صغيرة، بدون مسافات';

  @override
  String get insertImageUrlTooltip => 'إدراج رابط صورة';

  @override
  String get insertImageTitle => 'إدراج صورة';

  @override
  String get insertButton => 'إدراج';

  @override
  String get assign => 'تعيين';

  @override
  String get usernameAlreadyTaken => 'اسم المستخدم مستخدم بالفعل';

  @override
  String failedToCreateStudent(String error) {
    return 'فشل إنشاء الطالب: $error';
  }

  @override
  String get pinCopiedToClipboard => 'تم نسخ الرمز السري إلى الحافظة';

  @override
  String get iHaveSavedPin => 'لقد قمت بحفظ الرمز السري';

  @override
  String get resetPinConfirm => 'إعادة تعيين الرمز السري؟';

  @override
  String resetPinConfirmDesc(String name) {
    return 'هل أنت متأكد من إعادة تعيين الرمز السري لـ $name؟ سيؤدي هذا إلى إنشاء رمز سري عشوائي جديد مكون من 6 أرقام.';
  }

  @override
  String failedToResetPin(String error) {
    return 'فشل إعادة تعيين الرمز السري: $error';
  }

  @override
  String failedToDeleteStudent(String name, String error) {
    return 'فشل حذف $name: $error';
  }

  @override
  String groupRenamed(String name) {
    return 'تم تغيير اسم المجموعة إلى \"$name\"';
  }

  @override
  String failedToRenameGroup(String error) {
    return 'فشل تغيير اسم المجموعة: $error';
  }

  @override
  String groupMovedToArchive(String name) {
    return 'تم نقل \"$name\" إلى الأرشيف';
  }

  @override
  String failedToArchiveGroup(String error) {
    return 'فشل أرشفة المجموعة: $error';
  }

  @override
  String failedToCreateGroup(String error) {
    return 'فشل إنشاء المجموعة: $error';
  }

  @override
  String assignMaterialTitle(String title) {
    return 'تعيين المادة \"$title\"';
  }

  @override
  String get currentAssignments => 'المجموعات المعينة';

  @override
  String get noGroupAssignmentsYet => 'لم يتم التعيين لأي مجموعات بعد.';

  @override
  String get alreadyAssignedToGroupLevel =>
      'المادة معينة بالفعل لهذه المجموعة والمستوى!';

  @override
  String get levelLowerError => 'لا يمكن تعيين المادة لمستوى مجموعة أقل!';

  @override
  String get materialAssignedSuccess => 'تم تعيين المادة بنجاح!';

  @override
  String materialLevelLabel(String level) {
    return 'مستوى المادة: $level';
  }

  @override
  String get peopleAndUsers => 'الأشخاص والمستخدمون';

  @override
  String get curriculumContent => 'المنهج والمحتوى';

  @override
  String get activeToday => 'نشط اليوم';

  @override
  String get statTotal => 'المجموع';

  @override
  String get gradingOverview => 'نظرة عامة على التصحيح';

  @override
  String get totalSubmissions => 'إجمالي التسليمات';

  @override
  String get gradedCorrectIndicator => 'صحيح';

  @override
  String get gradedIncorrectIndicator => 'خطأ';

  @override
  String get adminDashboard => 'لوحة تحكم المشرف';

  @override
  String get overviewDashboard => 'لوحة النظرة العامة';

  @override
  String get adminUserName => 'مستخدم المشرف';

  @override
  String get adminAuthorityLevel => 'صلاحية المستوى 1';

  @override
  String get searchHint => 'بحث...';

  @override
  String get notificationsTooltip => 'الإشعارات';

  @override
  String get settingsTooltip => 'الإعدادات';

  @override
  String get logoutButton => 'تسجيل الخروج';

  @override
  String get languageButton => 'اللغة';

  @override
  String get superAdmin => 'مشرف عام';

  @override
  String get statusOnline => 'متصل';

  @override
  String get globalSearchHint => 'البحث عن طلاب، محاضرين، مجموعات…';

  @override
  String get darkModeComingSoon => 'الوضع الداكن قريباً';

  @override
  String get fromLastMonth => 'عن الشهر الماضي';

  @override
  String get badgeAssignment => 'مهمة';

  @override
  String get badgeGroup => 'مجموعة';

  @override
  String get badgeLesson => 'درس';

  @override
  String get badgeUser => 'مستخدم';

  @override
  String get badgeSubmission => 'تسليم';
}
