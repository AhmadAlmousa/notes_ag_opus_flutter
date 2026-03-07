// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Organote';

  @override
  String get appTagline => 'Manage your structured data';

  @override
  String get home => 'Home';

  @override
  String get templates => 'Templates';

  @override
  String get settings => 'Settings';

  @override
  String get searchHint => 'Search notes, tags, or content...';

  @override
  String get recentNotes => 'Recent Notes';

  @override
  String get allNotes => 'All Notes';

  @override
  String get noNotesYet => 'No notes yet';

  @override
  String get createFirstNote => 'Create your first note from a template';

  @override
  String get createNewNote => 'Create New Note';

  @override
  String get noTemplatesYet => 'No templates yet';

  @override
  String get createTemplate => 'Create Template';

  @override
  String get editCategories => 'Edit Categories';

  @override
  String get addCategory => 'Add Category';

  @override
  String get categoryName => 'Category name';

  @override
  String get renameCategory => 'Rename Category';

  @override
  String get newName => 'New name';

  @override
  String get deleteCategory => 'Delete Category?';

  @override
  String deleteCategoryConfirm(String name) {
    return 'All notes in \"$name\" will be deleted. This cannot be undone.';
  }

  @override
  String get noCategories => 'No categories';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get save => 'Save';

  @override
  String get restore => 'Restore';

  @override
  String get view => 'View';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get customizeExperience => 'Customize your experience';

  @override
  String get appearance => 'Appearance';

  @override
  String get auto => 'Auto';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get oled => 'OLED';

  @override
  String get data => 'Data';

  @override
  String templatesCount(int count) {
    return '$count created';
  }

  @override
  String notesCount(int count) {
    return '$count saved';
  }

  @override
  String get recycleBin => 'Recycle Bin';

  @override
  String get noDeletedNotes => 'No deleted notes';

  @override
  String deletedNotesCount(int count) {
    return '$count deleted note(s)';
  }

  @override
  String get autoPurged => 'Auto-purged after 7 days';

  @override
  String get recycleBinEmpty => 'Recycle bin is empty';

  @override
  String get emptyAll => 'Empty All';

  @override
  String get deletePermanently => 'Delete permanently';

  @override
  String daysLeft(int days) {
    return '${days}d left';
  }

  @override
  String get storage => 'Storage';

  @override
  String get storageType => 'Type';

  @override
  String get storagePath => 'Path';

  @override
  String get changeDirectory => 'Change Directory';

  @override
  String get localFilesystem => 'Local Filesystem';

  @override
  String get browserStorage => 'Browser Storage';

  @override
  String get sync => 'Sync';

  @override
  String get syncDescription =>
      'Sync your notes and templates across devices using your Google Drive account. Files are stored in an \"Organote\" folder.';

  @override
  String get connected => 'Connected';

  @override
  String get notConnected => 'Not connected';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signOut => 'Sign Out';

  @override
  String get syncNow => 'Sync Now';

  @override
  String get syncing => 'Syncing with Google Drive...';

  @override
  String get syncConnected => 'Connected to Google Drive!';

  @override
  String get syncFailed => 'Sign-in failed';

  @override
  String get syncCancelled => 'Sync cancelled.';

  @override
  String get pushAll => 'Push All';

  @override
  String get pullAll => 'Pull All';

  @override
  String get about => 'About';

  @override
  String get version => 'Version';

  @override
  String get builtWith => 'Built with Flutter';

  @override
  String get exportData => 'Export Data';

  @override
  String get importData => 'Import Data';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get deleteNote => 'Delete Note?';

  @override
  String get deleteNoteConfirm =>
      'The note will be moved to the recycle bin and permanently deleted after 7 days.';

  @override
  String get noteNotFound => 'Note not found';

  @override
  String get note => 'Note';

  @override
  String get noRecords => 'No records';

  @override
  String recordCount(int count) {
    return '$count record(s)';
  }

  @override
  String get share => 'Share';

  @override
  String get viewSource => 'View Source';

  @override
  String get noteCopied => 'Note copied to clipboard for sharing';

  @override
  String copiedToClipboard(String label) {
    return '$label copied to clipboard';
  }

  @override
  String get expandAll => 'Expand All';

  @override
  String get collapseAll => 'Collapse All';

  @override
  String get newTemplate => 'New Template';

  @override
  String get editTemplate => 'Edit Template';

  @override
  String get templateName => 'Template name';

  @override
  String get templateId => 'Template ID';

  @override
  String get noTemplatesCreated => 'No templates created yet';

  @override
  String get createFirstTemplate =>
      'Create your first template to start organizing your data';

  @override
  String get fields => 'fields';

  @override
  String get layout => 'Layout';

  @override
  String get deleteTemplate => 'Delete Template?';

  @override
  String get deleteTemplateConfirm =>
      'This will permanently delete this template.';

  @override
  String get templateBuilder => 'Template Builder';

  @override
  String get basic => 'Basic';

  @override
  String get fieldsTab => 'Fields';

  @override
  String get display => 'Display';

  @override
  String get actions => 'Actions';

  @override
  String get addField => 'Add Field';

  @override
  String get fieldLabel => 'Field label';

  @override
  String get fieldType => 'Field type';

  @override
  String get required => 'Required';

  @override
  String get multilineTextbox => 'Multiline Textbox';

  @override
  String get customEmojiIcon => 'Custom Emoji Icon';

  @override
  String get selectEmoji => 'Select Emoji';

  @override
  String get noEmoji => 'No emoji';

  @override
  String get clearEmoji => 'Clear Emoji';

  @override
  String get editEmoji => 'Edit Emoji';

  @override
  String get defaultValue => 'Default value';

  @override
  String get options => 'Options (comma-separated)';

  @override
  String get pageNotFound => 'Page not found';

  @override
  String get goHome => 'Go Home';

  @override
  String get failedToLoadPage => 'Failed to load page';

  @override
  String get gettingReady => 'Getting ready';
}
