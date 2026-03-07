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

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Organote'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Manage your structured data'**
  String get appTagline;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @templates.
  ///
  /// In en, this message translates to:
  /// **'Templates'**
  String get templates;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notes, tags, or content...'**
  String get searchHint;

  /// No description provided for @recentNotes.
  ///
  /// In en, this message translates to:
  /// **'Recent Notes'**
  String get recentNotes;

  /// No description provided for @allNotes.
  ///
  /// In en, this message translates to:
  /// **'All Notes'**
  String get allNotes;

  /// No description provided for @noNotesYet.
  ///
  /// In en, this message translates to:
  /// **'No notes yet'**
  String get noNotesYet;

  /// No description provided for @createFirstNote.
  ///
  /// In en, this message translates to:
  /// **'Create your first note from a template'**
  String get createFirstNote;

  /// No description provided for @createNewNote.
  ///
  /// In en, this message translates to:
  /// **'Create New Note'**
  String get createNewNote;

  /// No description provided for @noTemplatesYet.
  ///
  /// In en, this message translates to:
  /// **'No templates yet'**
  String get noTemplatesYet;

  /// No description provided for @createTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create Template'**
  String get createTemplate;

  /// No description provided for @editCategories.
  ///
  /// In en, this message translates to:
  /// **'Edit Categories'**
  String get editCategories;

  /// No description provided for @addCategory.
  ///
  /// In en, this message translates to:
  /// **'Add Category'**
  String get addCategory;

  /// No description provided for @categoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get categoryName;

  /// No description provided for @renameCategory.
  ///
  /// In en, this message translates to:
  /// **'Rename Category'**
  String get renameCategory;

  /// No description provided for @newName.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get newName;

  /// No description provided for @deleteCategory.
  ///
  /// In en, this message translates to:
  /// **'Delete Category?'**
  String get deleteCategory;

  /// No description provided for @deleteCategoryConfirm.
  ///
  /// In en, this message translates to:
  /// **'All notes in \"{name}\" will be deleted. This cannot be undone.'**
  String deleteCategoryConfirm(String name);

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories'**
  String get noCategories;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @customizeExperience.
  ///
  /// In en, this message translates to:
  /// **'Customize your experience'**
  String get customizeExperience;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @auto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @oled.
  ///
  /// In en, this message translates to:
  /// **'OLED'**
  String get oled;

  /// No description provided for @data.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get data;

  /// No description provided for @templatesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} created'**
  String templatesCount(int count);

  /// No description provided for @notesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} saved'**
  String notesCount(int count);

  /// No description provided for @recycleBin.
  ///
  /// In en, this message translates to:
  /// **'Recycle Bin'**
  String get recycleBin;

  /// No description provided for @noDeletedNotes.
  ///
  /// In en, this message translates to:
  /// **'No deleted notes'**
  String get noDeletedNotes;

  /// No description provided for @deletedNotesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} deleted note(s)'**
  String deletedNotesCount(int count);

  /// No description provided for @autoPurged.
  ///
  /// In en, this message translates to:
  /// **'Auto-purged after 7 days'**
  String get autoPurged;

  /// No description provided for @recycleBinEmpty.
  ///
  /// In en, this message translates to:
  /// **'Recycle bin is empty'**
  String get recycleBinEmpty;

  /// No description provided for @emptyAll.
  ///
  /// In en, this message translates to:
  /// **'Empty All'**
  String get emptyAll;

  /// No description provided for @deletePermanently.
  ///
  /// In en, this message translates to:
  /// **'Delete permanently'**
  String get deletePermanently;

  /// No description provided for @daysLeft.
  ///
  /// In en, this message translates to:
  /// **'{days}d left'**
  String daysLeft(int days);

  /// No description provided for @storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storage;

  /// No description provided for @storageType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get storageType;

  /// No description provided for @storagePath.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get storagePath;

  /// No description provided for @changeDirectory.
  ///
  /// In en, this message translates to:
  /// **'Change Directory'**
  String get changeDirectory;

  /// No description provided for @localFilesystem.
  ///
  /// In en, this message translates to:
  /// **'Local Filesystem'**
  String get localFilesystem;

  /// No description provided for @browserStorage.
  ///
  /// In en, this message translates to:
  /// **'Browser Storage'**
  String get browserStorage;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @syncDescription.
  ///
  /// In en, this message translates to:
  /// **'Sync your notes and templates across devices using your Google Drive account. Files are stored in an \"Organote\" folder.'**
  String get syncDescription;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing with Google Drive...'**
  String get syncing;

  /// No description provided for @syncConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected to Google Drive!'**
  String get syncConnected;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed'**
  String get syncFailed;

  /// No description provided for @syncCancelled.
  ///
  /// In en, this message translates to:
  /// **'Sync cancelled.'**
  String get syncCancelled;

  /// No description provided for @pushAll.
  ///
  /// In en, this message translates to:
  /// **'Push All'**
  String get pushAll;

  /// No description provided for @pullAll.
  ///
  /// In en, this message translates to:
  /// **'Pull All'**
  String get pullAll;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @builtWith.
  ///
  /// In en, this message translates to:
  /// **'Built with Flutter'**
  String get builtWith;

  /// No description provided for @exportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get exportData;

  /// No description provided for @importData.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get importData;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @deleteNote.
  ///
  /// In en, this message translates to:
  /// **'Delete Note?'**
  String get deleteNote;

  /// No description provided for @deleteNoteConfirm.
  ///
  /// In en, this message translates to:
  /// **'The note will be moved to the recycle bin and permanently deleted after 7 days.'**
  String get deleteNoteConfirm;

  /// No description provided for @noteNotFound.
  ///
  /// In en, this message translates to:
  /// **'Note not found'**
  String get noteNotFound;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @noRecords.
  ///
  /// In en, this message translates to:
  /// **'No records'**
  String get noRecords;

  /// No description provided for @recordCount.
  ///
  /// In en, this message translates to:
  /// **'{count} record(s)'**
  String recordCount(int count);

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @viewSource.
  ///
  /// In en, this message translates to:
  /// **'View Source'**
  String get viewSource;

  /// No description provided for @noteCopied.
  ///
  /// In en, this message translates to:
  /// **'Note copied to clipboard for sharing'**
  String get noteCopied;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'{label} copied to clipboard'**
  String copiedToClipboard(String label);

  /// No description provided for @expandAll.
  ///
  /// In en, this message translates to:
  /// **'Expand All'**
  String get expandAll;

  /// No description provided for @collapseAll.
  ///
  /// In en, this message translates to:
  /// **'Collapse All'**
  String get collapseAll;

  /// No description provided for @newTemplate.
  ///
  /// In en, this message translates to:
  /// **'New Template'**
  String get newTemplate;

  /// No description provided for @editTemplate.
  ///
  /// In en, this message translates to:
  /// **'Edit Template'**
  String get editTemplate;

  /// No description provided for @templateName.
  ///
  /// In en, this message translates to:
  /// **'Template name'**
  String get templateName;

  /// No description provided for @templateId.
  ///
  /// In en, this message translates to:
  /// **'Template ID'**
  String get templateId;

  /// No description provided for @noTemplatesCreated.
  ///
  /// In en, this message translates to:
  /// **'No templates created yet'**
  String get noTemplatesCreated;

  /// No description provided for @createFirstTemplate.
  ///
  /// In en, this message translates to:
  /// **'Create your first template to start organizing your data'**
  String get createFirstTemplate;

  /// No description provided for @fields.
  ///
  /// In en, this message translates to:
  /// **'fields'**
  String get fields;

  /// No description provided for @layout.
  ///
  /// In en, this message translates to:
  /// **'Layout'**
  String get layout;

  /// No description provided for @deleteTemplate.
  ///
  /// In en, this message translates to:
  /// **'Delete Template?'**
  String get deleteTemplate;

  /// No description provided for @deleteTemplateConfirm.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete this template.'**
  String get deleteTemplateConfirm;

  /// No description provided for @templateBuilder.
  ///
  /// In en, this message translates to:
  /// **'Template Builder'**
  String get templateBuilder;

  /// No description provided for @basic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get basic;

  /// No description provided for @fieldsTab.
  ///
  /// In en, this message translates to:
  /// **'Fields'**
  String get fieldsTab;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @addField.
  ///
  /// In en, this message translates to:
  /// **'Add Field'**
  String get addField;

  /// No description provided for @fieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Field label'**
  String get fieldLabel;

  /// No description provided for @fieldType.
  ///
  /// In en, this message translates to:
  /// **'Field type'**
  String get fieldType;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @multilineTextbox.
  ///
  /// In en, this message translates to:
  /// **'Multiline Textbox'**
  String get multilineTextbox;

  /// No description provided for @customEmojiIcon.
  ///
  /// In en, this message translates to:
  /// **'Custom Emoji Icon'**
  String get customEmojiIcon;

  /// No description provided for @selectEmoji.
  ///
  /// In en, this message translates to:
  /// **'Select Emoji'**
  String get selectEmoji;

  /// No description provided for @noEmoji.
  ///
  /// In en, this message translates to:
  /// **'No emoji'**
  String get noEmoji;

  /// No description provided for @clearEmoji.
  ///
  /// In en, this message translates to:
  /// **'Clear Emoji'**
  String get clearEmoji;

  /// No description provided for @editEmoji.
  ///
  /// In en, this message translates to:
  /// **'Edit Emoji'**
  String get editEmoji;

  /// No description provided for @defaultValue.
  ///
  /// In en, this message translates to:
  /// **'Default value'**
  String get defaultValue;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options (comma-separated)'**
  String get options;

  /// No description provided for @pageNotFound.
  ///
  /// In en, this message translates to:
  /// **'Page not found'**
  String get pageNotFound;

  /// No description provided for @goHome.
  ///
  /// In en, this message translates to:
  /// **'Go Home'**
  String get goHome;

  /// No description provided for @failedToLoadPage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load page'**
  String get failedToLoadPage;

  /// No description provided for @gettingReady.
  ///
  /// In en, this message translates to:
  /// **'Getting ready'**
  String get gettingReady;
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
