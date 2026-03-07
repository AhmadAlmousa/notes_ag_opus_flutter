// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'أورغانوت';

  @override
  String get appTagline => 'إدارة بياناتك المُنظّمة';

  @override
  String get home => 'الرئيسية';

  @override
  String get templates => 'القوالب';

  @override
  String get settings => 'الإعدادات';

  @override
  String get searchHint => 'ابحث في الملاحظات أو الوسوم أو المحتوى...';

  @override
  String get recentNotes => 'الملاحظات الأخيرة';

  @override
  String get allNotes => 'جميع الملاحظات';

  @override
  String get noNotesYet => 'لا توجد ملاحظات بعد';

  @override
  String get createFirstNote => 'أنشئ أول ملاحظة من أحد القوالب';

  @override
  String get createNewNote => 'إنشاء ملاحظة جديدة';

  @override
  String get noTemplatesYet => 'لا توجد قوالب بعد';

  @override
  String get createTemplate => 'إنشاء قالب';

  @override
  String get editCategories => 'تعديل الفئات';

  @override
  String get addCategory => 'إضافة فئة';

  @override
  String get categoryName => 'اسم الفئة';

  @override
  String get renameCategory => 'إعادة تسمية الفئة';

  @override
  String get newName => 'الاسم الجديد';

  @override
  String get deleteCategory => 'حذف الفئة؟';

  @override
  String deleteCategoryConfirm(String name) {
    return 'سيتم حذف جميع الملاحظات في \"$name\". لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get noCategories => 'لا توجد فئات';

  @override
  String get edit => 'تعديل';

  @override
  String get add => 'إضافة';

  @override
  String get close => 'إغلاق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get save => 'حفظ';

  @override
  String get restore => 'استعادة';

  @override
  String get view => 'عرض';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get customizeExperience => 'خصّص تجربتك';

  @override
  String get appearance => 'المظهر';

  @override
  String get auto => 'تلقائي';

  @override
  String get light => 'فاتح';

  @override
  String get dark => 'داكن';

  @override
  String get oled => 'OLED';

  @override
  String get data => 'البيانات';

  @override
  String templatesCount(int count) {
    return '$count قالب';
  }

  @override
  String notesCount(int count) {
    return '$count ملاحظة';
  }

  @override
  String get recycleBin => 'سلة المحذوفات';

  @override
  String get noDeletedNotes => 'لا توجد ملاحظات محذوفة';

  @override
  String deletedNotesCount(int count) {
    return '$count ملاحظة محذوفة';
  }

  @override
  String get autoPurged => 'تُحذف تلقائياً بعد ٧ أيام';

  @override
  String get recycleBinEmpty => 'سلة المحذوفات فارغة';

  @override
  String get emptyAll => 'إفراغ الكل';

  @override
  String get deletePermanently => 'حذف نهائي';

  @override
  String daysLeft(int days) {
    return '$days يوم متبقي';
  }

  @override
  String get storage => 'التخزين';

  @override
  String get storageType => 'النوع';

  @override
  String get storagePath => 'المسار';

  @override
  String get changeDirectory => 'تغيير المجلد';

  @override
  String get localFilesystem => 'التخزين المحلي';

  @override
  String get browserStorage => 'تخزين المتصفح';

  @override
  String get sync => 'المزامنة';

  @override
  String get syncDescription =>
      'زامن ملاحظاتك وقوالبك عبر الأجهزة باستخدام حساب جوجل درايف. تُخزّن الملفات في مجلد \"Organote\".';

  @override
  String get connected => 'متصل';

  @override
  String get notConnected => 'غير متصل';

  @override
  String get signInWithGoogle => 'تسجيل الدخول بحساب جوجل';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get syncing => 'جارٍ المزامنة مع جوجل درايف...';

  @override
  String get syncConnected => 'تم الاتصال بجوجل درايف!';

  @override
  String get syncFailed => 'فشل تسجيل الدخول';

  @override
  String get syncCancelled => 'تم إلغاء المزامنة.';

  @override
  String get pushAll => 'رفع الكل';

  @override
  String get pullAll => 'سحب الكل';

  @override
  String get about => 'حول التطبيق';

  @override
  String get version => 'الإصدار';

  @override
  String get builtWith => 'مبني بـ Flutter';

  @override
  String get exportData => 'تصدير البيانات';

  @override
  String get importData => 'استيراد البيانات';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get deleteNote => 'حذف الملاحظة؟';

  @override
  String get deleteNoteConfirm =>
      'ستنتقل الملاحظة إلى سلة المحذوفات وستُحذف نهائياً بعد ٧ أيام.';

  @override
  String get noteNotFound => 'الملاحظة غير موجودة';

  @override
  String get note => 'ملاحظة';

  @override
  String get noRecords => 'لا توجد سجلات';

  @override
  String recordCount(int count) {
    return '$count سجل';
  }

  @override
  String get share => 'مشاركة';

  @override
  String get viewSource => 'عرض المصدر';

  @override
  String get noteCopied => 'تم نسخ الملاحظة للمشاركة';

  @override
  String copiedToClipboard(String label) {
    return 'تم نسخ $label إلى الحافظة';
  }

  @override
  String get expandAll => 'توسيع الكل';

  @override
  String get collapseAll => 'طي الكل';

  @override
  String get newTemplate => 'قالب جديد';

  @override
  String get editTemplate => 'تعديل القالب';

  @override
  String get templateName => 'اسم القالب';

  @override
  String get templateId => 'معرّف القالب';

  @override
  String get noTemplatesCreated => 'لم يتم إنشاء قوالب بعد';

  @override
  String get createFirstTemplate => 'أنشئ أول قالب لبدء تنظيم بياناتك';

  @override
  String get fields => 'الحقول';

  @override
  String get layout => 'التخطيط';

  @override
  String get deleteTemplate => 'حذف القالب؟';

  @override
  String get deleteTemplateConfirm => 'سيتم حذف هذا القالب نهائياً.';

  @override
  String get templateBuilder => 'مصمم القوالب';

  @override
  String get basic => 'أساسي';

  @override
  String get fieldsTab => 'الحقول';

  @override
  String get display => 'العرض';

  @override
  String get actions => 'الإجراءات';

  @override
  String get addField => 'إضافة حقل';

  @override
  String get fieldLabel => 'عنوان الحقل';

  @override
  String get fieldType => 'نوع الحقل';

  @override
  String get required => 'مطلوب';

  @override
  String get multilineTextbox => 'مربع نص متعدد الأسطر';

  @override
  String get customEmojiIcon => 'أيقونة إيموجي مخصصة';

  @override
  String get selectEmoji => 'اختيار إيموجي';

  @override
  String get noEmoji => 'بدون إيموجي';

  @override
  String get clearEmoji => 'مسح الإيموجي';

  @override
  String get editEmoji => 'تعديل الإيموجي';

  @override
  String get defaultValue => 'القيمة الافتراضية';

  @override
  String get options => 'الخيارات (مفصولة بفواصل)';

  @override
  String get pageNotFound => 'الصفحة غير موجودة';

  @override
  String get goHome => 'العودة للرئيسية';

  @override
  String get failedToLoadPage => 'فشل تحميل الصفحة';

  @override
  String get gettingReady => 'جارٍ التحضير';
}
