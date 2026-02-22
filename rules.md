# Organote — Comprehensive Project Documentation

> **Purpose**: This document enables any AI coding agent to understand, replicate, maintain, and extend the Organote Flutter application. It covers architecture, data models, storage, screens, workflows, nuances, and all issues encountered with their resolutions.

---

## 1. Project Overview

**Organote** is a cross-platform **Structured Markdown Notes** application built with Flutter. It allows users to create **templates** that define data schemas, then create **notes** based on those templates with structured records. All data is stored as Markdown files with YAML frontmatter and YAML code blocks.

### Key Concepts

| Concept | Description |
|---------|-------------|
| **Template** | Defines the schema for notes — field types, layout, display, actions |
| **Note** | A collection of structured records that follow a template's schema |
| **Record** | A single data entry within a note (one row of field values) |
| **Category** | A virtual folder for organizing notes (e.g., `personal`, `work`) |
| **Field** | A typed data definition within a template (text, number, date, etc.) |

### Technology Stack

- **Framework**: Flutter (Dart SDK ^3.10.7)
- **Routing**: `go_router` ^17.1.0
- **Data Parsing**: `yaml` ^3.1.3 for YAML frontmatter/data blocks
- **Storage**: `shared_preferences` ^2.5.4 (localStorage), File System Access API (FSA), Origin Private File System (OPFS)
- **Calendar**: `hijri` ^3.0.0 for dual Gregorian/Hijri calendar support
- **Fonts**: `google_fonts` ^8.0.1 (Inter font family)
- **Export/Import**: `archive` ^4.0.6, `file_saver` ^0.2.14, `file_picker` ^10.1.13
- **Misc**: `intl` ^0.20.2, `flutter_markdown` ^0.7.7+1

---

## 2. Architecture

### Directory Structure

```
lib/
├── main.dart                          # App entry point, initialization, splash screen
├── core/
│   ├── app_state.dart                 # Singleton global state + dependency container
│   ├── router.dart                    # go_router route definitions
│   ├── compliance_checker.dart        # Template compliance checking
│   ├── export_import_service.dart     # Zip export/import functionality
│   ├── theme/
│   │   ├── app_theme.dart             # Light/dark theme definitions
│   │   └── app_animations.dart        # Shared animation constants
│   ├── utils/
│   │   ├── markdown_parser.dart       # YAML frontmatter + code block extraction
│   │   ├── date_utils.dart            # Gregorian/Hijri date formatting
│   │   └── sanitizers.dart            # Filename sanitization
│   └── constants/                     # App-wide constants
├── data/
│   ├── models/
│   │   ├── field.dart                 # FieldType enum, Field class, FieldOptions
│   │   ├── note.dart                  # Note model
│   │   └── template.dart              # Template model, TemplateLayout, DisplaySettings
│   ├── repositories/
│   │   ├── note_repository.dart       # Note CRUD, search, category management
│   │   └── template_repository.dart   # Template CRUD with caching
│   └── services/
│       ├── storage_service.dart        # localStorage backend (SharedPreferences)
│       ├── file_system_storage_service.dart  # FSA/OPFS backend
│       └── fs_interop.dart            # JS interop for File System Access APIs
└── presentation/
    ├── screens/
    │   ├── setup/
    │   │   └── setup_screen.dart       # First-run storage selection
    │   ├── dashboard/
    │   │   └── dashboard_screen.dart   # Home screen with categories + recent notes
    │   ├── templates/
    │   │   ├── template_list_screen.dart    # Template management list
    │   │   └── template_builder_screen.dart # Template creation/editing
    │   ├── notes/
    │   │   ├── notes_list_screen.dart  # Notes browser by category
    │   │   └── note_view_screen.dart   # Note viewer (cards/table/grid layouts)
    │   ├── editor/
    │   │   ├── note_editor_screen.dart    # Structured note editor
    │   │   └── markdown_editor_screen.dart # Raw markdown source editor
    │   └── settings/
    │       └── settings_screen.dart    # App settings
    └── widgets/
        ├── common/
        │   ├── note_card.dart          # Reusable note card widget
        │   ├── emoji_picker_dialog.dart # Emoji selection dialog
        │   └── search_bar.dart         # Search input widget
        ├── field_inputs/
        │   ├── field_input_widget.dart  # Field type router widget
        │   ├── text_field_input.dart    # Text/number/digits input
        │   ├── date_field_input.dart    # Gregorian/Hijri date picker
        │   ├── dropdown_field_input.dart# Dropdown select input
        │   ├── password_field_input.dart# Password with visibility toggle
        │   ├── ip_field_input.dart      # IP address input with validation
        │   ├── regex_field_input.dart   # Regex-validated input
        │   └── custom_label_field_input.dart # Dynamic label+value pair
        └── layout/
            └── app_scaffold.dart       # Shared scaffold with navigation
```

### Layered Architecture

```
┌───────────────────────────────────────┐
│           Presentation Layer          │
│    (Screens, Widgets, Routing)        │
├───────────────────────────────────────┤
│             Core Layer                │
│  (AppState, Utils, Theme, Constants)  │
├───────────────────────────────────────┤
│              Data Layer               │
│   (Models, Repositories, Services)    │
└───────────────────────────────────────┘
```

- **AppState** is a singleton `ChangeNotifier` that owns the `StorageService`, `TemplateRepository`, and `NoteRepository`.
- **Repositories** provide parsed model objects with caching.
- **StorageService** handles raw string persistence (markdown content stored as JSON-encoded maps in SharedPreferences keys).

---

## 3. Data Format — Structured Markdown

### Template File Format

Templates use YAML frontmatter + a `` ```schema `` code block:

```markdown
---
template_id: family_login
name: Family Login
version: 1
layout: cards
default_folder: personal
---

```schema
display:
  preset: credentials
  primary: service
fields:
  - id: owner
    type: dropdown
    label: Owner
    required: true
    options:
      - Dad
      - Mom
      - Kids
  - id: service
    type: text
    label: Service
    required: true
  - id: password
    type: password
    label: Password
    required: true
  - id: created_on
    type: date
    label: Created On
    calendar: dual
  - id: mac_addr
    type: regex
    label: MAC Address
    regex_pattern: "^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$"
    regex_hint: "Format: XX:XX:XX:XX:XX:XX"
actions:
  - label: Copy Password
    field: password
    type: copy
```
```

### Note File Format

Notes use YAML frontmatter + a `` ```data `` code block:

```markdown
---
template_id: family_login
template_version: 1
id: gmail_accounts
title: Gmail
icon: 📧
tags:
  - email
  - google
---

```data
- owner: Dad
  service: Gmail
  username: dad@gmail.com
  password: MySecurePass123
  created_on: 2024-01-15|gregorian
- owner: Mom
  service: Gmail
  username: mom@gmail.com
  password: AnotherPass456
  created_on: 1445-06-21|hijri
```
```

### Storage Keys (SharedPreferences)

| Key | Value Type | Description |
|-----|-----------|-------------|
| `organote_templates` | JSON map `{templateId: markdownString}` | All templates |
| `organote_notes` | JSON map `{category/filename: markdownString}` | All notes |
| `organote_categories` | JSON list `[string]` | Category names |
| `organote_settings` | JSON map | App settings |
| `organote_search_index` | JSON map | Search index |

---

## 4. Data Models

### FieldType Enum

```dart
enum FieldType {
  text,        // Free-text input
  number,      // Numeric with optional min/max
  digits,      // Exact-length digit string (e.g., PIN)
  date,        // Date with calendar mode (gregorian/hijri/dual)
  dropdown,    // Select from predefined options
  boolean,     // Yes/No toggle
  url,         // URL with validation
  ip,          // IP address with segment validation
  password,    // Hidden text with copy/toggle
  regex,       // Text validated against a regex pattern
  customLabel, // Dynamic label+value pair
}
```

### FieldOptions

| Property | Used By | Description |
|----------|---------|-------------|
| `min`, `max` | `number` | Numeric range |
| `length` | `digits` | Exact digit count |
| `dropdownOptions` | `dropdown` | List of selectable strings |
| `calendarMode` | `date` | `gregorian`, `hijri`, or `dual` |
| `regexPattern` | `regex` | Validation regex string |
| `regexHint` | `regex` | Human-readable format hint |

### TemplateLayout Enum

```dart
enum TemplateLayout {
  cards,  // Vertical list of expandable cards
  table,  // DataTable with columns = fields
  grid,   // Adaptive grid layout (LayoutBuilder + Wrap)
}
```

> **IMPORTANT**: The `list` layout was removed. Any references to `TemplateLayout.list` must be excluded from switch statements and UI selectors.

### Template Model

Key properties: `templateId`, `name`, `version`, `layout`, `defaultFolder`, `display` (DisplaySettings), `fields` (List<Field>), `actions` (List<TemplateAction>).

### Note Model

Key properties: `id`, `templateId`, `templateVersion`, `category`, `filename`, `title`, `icon`, `tags`, `records` (List<Map<String, dynamic>>), `createdAt`, `updatedAt`.

---

## 5. Screens & Navigation

### Route Map (go_router)

| Route | Screen | Description |
|-------|--------|-------------|
| `/` | `DashboardScreen` | Home with search, categories, recent notes |
| `/templates` | `TemplateListScreen` | List all templates |
| `/templates/new` | `TemplateBuilderScreen` | Create new template |
| `/templates/:templateId` | `TemplateBuilderScreen` | Edit existing template |
| `/notes` | `NotesListScreen` | Browse notes by category |
| `/notes/:category/:filename` | `NoteViewScreen` | View a note |
| `/notes/:category/:filename/edit` | `NoteEditorScreen` | Edit a note |
| `/notes/:category/:filename/source` | `MarkdownEditorScreen` | Raw markdown editor |
| `/new-note/:templateId` | `NoteEditorScreen` | Create new note from template |
| `/settings` | `SettingsScreen` | App settings |

### Screen Details

#### SetupScreen (First Run)
- Presents storage options: File System Access (FSA), Origin Private File System (OPFS), or App Storage (localStorage)
- FSA shows a native folder picker; OPFS uses browser-internal storage; App Storage uses SharedPreferences
- After selection, calls `AppState.instance.completeStorageSetup(type)`

#### DashboardScreen
- Category chips with horizontal scroll + "Edit" pill to manage categories
- Recent notes list with `NoteCard` widgets
- FAB to create new notes (shows template selection dialog)
- Category editor dialog: rename, delete, **add** categories

#### TemplateBuilderScreen
- Form with: template name, layout selector, default folder, display settings
- Dynamic field list: add/remove/reorder fields with type-specific options
- Action buttons configuration (copy, open)
- Saves as structured markdown via `Template.toMarkdown()`

#### NoteEditorScreen
- Loads template schema to render form fields
- `_RecordForm` renders each record's fields using `FieldInputWidget`
- Add/remove records
- Title, icon (emoji picker), tags, category selection

#### NoteViewScreen
- **AppBar**: shows emoji icon + note title, with category and template type badges in `bottom` area
- **Body**: tags + record count, then records in cards/table/grid layout
- **Cards layout**: vertical list with animated fade/slide per record
- **Table layout**: `DataTable` with field-based columns (no row number column)
- **Grid layout**: `LayoutBuilder` + `Wrap` with adaptive column count (~300px per column, 1–4 columns)
- Card titles: show value of the first field, fallback to "Record N"
- Actions: edit, view source, delete, share

#### NotesListScreen
- Lists notes with `NoteCard` widgets, filterable by category
- `_openNote` is `async` — awaits `context.push()` and reloads (`_loadData()`) on return to reflect edits/deletions

---

## 6. Widget Details

### FieldInputWidget (Router)

`FieldInputWidget` acts as a type router — it inspects `field.type` and renders the appropriate specialized widget:

| FieldType | Widget | Notes |
|-----------|--------|-------|
| `text`, `number`, `digits`, `url` | `TextFieldInput` | With appropriate keyboard types and validation |
| `date` | `DateFieldInput` | Gregorian/Hijri/Dual calendar support |
| `dropdown` | `DropdownFieldInput` | Renders dropdown with predefined options |
| `boolean` | Built-in `SwitchListTile` | Toggle with label |
| `password` | `PasswordFieldInput` | Visibility toggle + copy button |
| `ip` | `IpFieldInput` | 4-segment input with per-segment validation |
| `regex` | `RegexFieldInput` | TextField with regex validation + hint display |
| `customLabel` | `CustomLabelFieldInput` | Two TextFields: label + value |

### NoteCard
- Shows note icon, title, category, template type badge, tags
- Tappable to open `NoteViewScreen`

### AppScaffold
- Shared scaffold with bottom navigation bar (Dashboard, Notes, Templates, Settings)
- Handles navigation between main sections

---

## 7. Critical Nuances & Gotchas

### 7.1 Custom Label Field — Flat Key Storage

> **This is the single most important nuance in the codebase.**

Custom label fields (`FieldType.customLabel`) allow users to type both a label name and a value. Internally, the `CustomLabelFieldInput` widget works with a `Map<String, dynamic>` like `{'label': 'Phone', 'value': '555-1234'}`.

**PROBLEM**: Storing this Map directly in a record's data causes serialization failures — YAML round-tripping of nested Maps within a list of records produces malformed output.

**SOLUTION**: Use **flat keys** in the record map:

```
Record map:
{
  'fieldId_label': 'Phone',
  'fieldId_value': '555-1234',
  'otherField': 'some value',
}
```

**Where this is handled:**

1. **`note_editor_screen.dart` → `_RecordForm`**: When rendering, assembles a synthetic Map from flat keys to pass to `FieldInputWidget`. When receiving changes, splits the Map back into flat keys:

```dart
// Assembly (for widget rendering)
if (field.type == FieldType.customLabel) {
  fieldValue = {
    'label': record['${field.id}_label']?.toString() ?? '',
    'value': record['${field.id}_value']?.toString() ?? '',
  };
}

// Splitting (on change)
if (field.type == FieldType.customLabel && value is Map) {
  onFieldChanged('${field.id}_label', value['label'] ?? '');
  onFieldChanged('${field.id}_value', value['value'] ?? '');
}
```

2. **`note_view_screen.dart` → `_buildFieldRows`**: Iterates over **template fields** (not record entries) and reads flat keys:

```dart
if (fieldDef.type == FieldType.customLabel) {
  displayLabel = record['${fieldDef.id}_label']?.toString() ?? fieldDef.label;
  displayValue = record['${fieldDef.id}_value'];
} else {
  displayValue = record[fieldDef.id];
}
```

3. **`note_view_screen.dart` → `_buildTableLayout`**: Table column headers use the custom label from the first record:

```dart
if (field.type == FieldType.customLabel && _note!.records.isNotEmpty) {
  colLabel = _note!.records.first['${field.id}_label']?.toString() ?? field.label;
}
```

4. **`note_view_screen.dart` → `_getRecordTitle`**: Card titles check for custom label value:

```dart
if (firstField.type == FieldType.customLabel) {
  firstValue = record['${firstField.id}_value']?.toString();
} else {
  firstValue = record[firstField.id]?.toString();
}
```

### 7.2 Template Serialization — `toMarkdown()` Must Serialize All Options

**PROBLEM**: `Template.toMarkdown()` originally did not serialize `regexPattern`, `regexHint`, or the correct type name for `customLabel`.

**FIXES**:
- `customLabel` type must serialize as `custom_label` (snake_case) to match `FieldTypeExtension.fromString()` parsing:
  ```dart
  final typeName = field.type == FieldType.customLabel ? 'custom_label' : field.type.name;
  ```
- Regex options must be serialized:
  ```dart
  if (opts.regexPattern != null) buffer.writeln('    regex_pattern: ${opts.regexPattern}');
  if (opts.regexHint != null) buffer.writeln('    regex_hint: ${opts.regexHint}');
  ```

### 7.3 Layout Constraints — No `Expanded` in Unconstrained Rows

**PROBLEM**: Using `Expanded` inside an inner `Row` that is itself a child of another `Row` causes `RenderBox` assertion failures ("Cannot hit test a render box that has never been laid out").

**PATTERN TO AVOID**:
```dart
Row(
  children: [
    Row(  // UNCONSTRAINED inner Row
      children: [
        Expanded(child: Text('...')),  // CRASH!
      ],
    ),
  ],
)
```

**CORRECT PATTERN**:
```dart
Row(
  children: [
    Container(...),
    Expanded(child: Text('...')),  // Directly in outer Row
    Row(mainAxisSize: MainAxisSize.min, children: [...]),  // Actions
  ],
)
```

### 7.4 Note List Refresh After Navigation

**PROBLEM**: After editing or deleting a note and returning to the list, the list showed stale data.

**SOLUTION**: Make navigation `async` and reload on return:
```dart
Future<void> _openNote(Note note) async {
  await context.push('/notes/${note.category}/${note.filename}');
  _loadData();  // Reload when returning
}
```

Same pattern is used in `NoteViewScreen` for the edit button — after returning from the editor, the view reloads.

### 7.5 Date Format with Calendar Mode

Dates are stored with a pipe-separated calendar mode suffix:
```
2024-01-15|gregorian
1445-06-21|hijri
```

The `DateFieldInput` widget handles dual calendar mode by showing both Gregorian and Hijri pickers and formatting the selected date accordingly.

### 7.6 String Escaping in `Note.toMarkdown()`

Values containing `:`, `"`, newlines, or leading/trailing spaces are quoted:
```dart
if (value.contains(':') || value.contains('"') || value.contains('\n') ...) {
  return '"${value.replaceAll('"', '\\"')}"';
}
```

### 7.7 Categories Are Virtual Folders

Categories are stored as a separate list in SharedPreferences, not as actual file system directories. When a note is saved under a category, the key format is `category/filename`. Categories can be:
- **Auto-created**: When a note is saved to a new category, `_updateCategories()` adds it
- **Manually created**: Via the "Add" button in the category editor dialog
- Default categories: `['personal', 'work', 'family']` if none are stored

### 7.8 Field ID Generation in Template Builder

When adding fields in the template builder, IDs are auto-generated from the label by lowercasing and replacing spaces with underscores (via `sanitizers.dart`). This ID is used as the key in record maps.

### 7.9 AppBar `bottom` for Metadata Badges

The `NoteViewScreen` AppBar uses `PreferredSize` in the `bottom` property to display category and template type badges:
```dart
appBar: AppBar(
  title: _buildAppBarTitle(),  // Icon + title
  bottom: PreferredSize(
    preferredSize: const Size.fromHeight(28),
    child: Row(children: [categoryBadge, templateBadge]),
  ),
)
```

---

## 8. Storage Architecture

### Three Storage Backends

1. **App Storage (localStorage)** — `StorageService` using `SharedPreferences`. Simple key-value JSON. Default fallback.

2. **File System Access (FSA)** — `FileSystemStorageService` using the browser's File System Access API. User picks a directory; files are stored as actual `.md` files on disk. Requires JS interop via `fs_interop.dart`.

3. **Origin Private File System (OPFS)** — Also via `FileSystemStorageService`, but uses the browser's sandboxed origin-private file system. No user prompt needed.

### Storage Selection Flow

```
main.dart → AppState.initialize()
  ├── Try FileSystemStorageService.tryReconnect()
  │     ├── Success → Use file system storage
  │     └── Fail → Check configuredStorageType
  │           ├── 'local' → Use StorageService (localStorage)
  │           ├── Other → Fallback to StorageService
  │           └── 'none' → Show SetupScreen
  └── SetupScreen → AppState.completeStorageSetup(type)
```

### File System Storage Structure

When using FSA/OPFS, files are organized as:
```
root/
├── templates/
│   └── family_login.md
└── notes/
    ├── personal/
    │   └── gmail_accounts.md
    └── work/
        └── project_notes.md
```

---

## 9. Theme & Design

### Theme System

- **Dual themes**: `AppTheme.lightTheme` and `AppTheme.darkTheme`
- **Primary color**: Deep blue (`Color(0xFF1a73e8)` or similar)
- **Font**: Google Fonts Inter for clean, modern typography
- **Animations**: Custom page transitions via `AppRouter._buildPage()` — fade + subtle horizontal slide
- **Shadows**: `AppShadows.soft` and `AppShadows.card` for depth
- **Border radius**: 12px for cards, 8px for inner elements, 6px for badges

### Design Principles Applied

- Glassmorphism-inspired cards with subtle borders and shadows
- Micro-animations: `CurvedAnimation` with staggered intervals for record cards
- Color-coded field type icons
- Emoji icons for notes (selectable via `EmojiPickerDialog`)

---

## 10. Issues Encountered & Resolutions

### Issue 1: Regex Fields Not Saving
**Symptom**: Regex pattern and hint disappeared after saving a template.
**Cause**: `Template.toMarkdown()` didn't serialize `regexPattern` or `regexHint` in the schema block.
**Fix**: Added serialization in `toMarkdown()` under the field options section.

### Issue 2: Custom Label Values Disappearing Randomly
**Symptom**: Custom label field values lost after reopening a note.
**Cause**: Nested `Map` inside the record list didn't survive YAML serialization round-trip.
**Fix**: Changed to flat keys (`{fieldId}_label`, `{fieldId}_value`). Updated editor, viewer, table, and card title logic.

### Issue 3: Note View White Page
**Symptom**: Opening any note with cards or grid layout showed a blank white page.
**Cause**: `Expanded` widget wrapped in a `Text` was inside an inner `Row` that was itself a child of an outer `Row`. The inner `Row` had no width constraints, so `Expanded` couldn't resolve.
**Fix**: Flattened the widget tree — moved all children to a single `Row` with `Expanded` for the title and `MainAxisSize.min` for action buttons.

### Issue 4: Note List Not Refreshing
**Symptom**: After editing or deleting a note, the notes list showed stale data.
**Cause**: `context.push()` was fire-and-forget; no reload triggered on return.
**Fix**: Made `_openNote()` async — awaits `context.push()` then calls `_loadData()` on return.

### Issue 5: `TemplateLayout.list` References After Removal
**Symptom**: Analyzer errors in switch statements after removing the `list` layout.
**Cause**: Multiple files had exhaustive switch statements over `TemplateLayout` that still included `case TemplateLayout.list:`.
**Fix**: Removed all `case TemplateLayout.list:` from `template_builder_screen.dart`, `template_list_screen.dart`, and `note_view_screen.dart`.

### Issue 6: customLabel Type Serialization Mismatch
**Symptom**: After saving and reloading a template, `customLabel` fields became `text` fields.
**Cause**: `toMarkdown()` wrote `type: customLabel` but `fromString()` expected `custom_label` (snake_case).
**Fix**: Serialize as `custom_label` in `toMarkdown()`:
```dart
final typeName = field.type == FieldType.customLabel ? 'custom_label' : field.type.name;
```

### Issue 7: Missing Category Addition
**Symptom**: The category editor dialog only supported rename and delete — no way to add new categories.
**Fix**: Added `addCategory()` to `NoteRepository`, an `onAdd` callback to `_EditCategoriesDialog`, and an "Add Category" button with a text input dialog.

### Issue 8: Escaped `$` in String Interpolation
**Symptom**: Card titles showed literal `${index + 1}` text instead of the number.
**Cause**: When using the `multi_replace_file_content` tool, `\${...}` in replacement content was stored as a literal backslash-dollar, escaping the interpolation.
**Fix**: Replaced `\${index + 1}` with `${index + 1}` in the source file.

---

## 11. Testing & Verification

### Static Analysis
```bash
dart analyze lib/
```
Expected result: **0 errors**. Remaining warnings are pre-existing (unused imports, deprecated API usage like `value` on `DropdownButtonFormField`).

### Running the App
```bash
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
```

### Key Test Scenarios

1. **Template CRUD**: Create template → add all field types → save → reopen → verify all options preserved (especially `regex_pattern`, `regex_hint`, `custom_label` type)
2. **Note with Custom Label**: Create note with customLabel field → enter label + value → save → reopen → verify label and value persisted → view in table layout → verify column header uses custom label
3. **Note View Layouts**: Create notes → switch template layout between cards/table/grid → verify no white page, proper rendering
4. **Category Management**: Edit categories → Add → Rename → Delete → verify notes move correctly
5. **Note List Refresh**: Edit a note → save → go back → verify list reflects changes
6. **Date Fields**: Test dual calendar (Gregorian + Hijri) → verify stored as `yyyy-MM-dd|mode`
7. **Regex Validation**: Create template with regex field → create note → verify pattern validates input
8. **Export/Import**: Export notes as zip → clear data → import zip → verify all notes restored

---

## 12. Extension Guide

### Adding a New Field Type

1. Add value to `FieldType` enum in `field.dart`
2. Add `displayName` and `iconName` in `FieldTypeExtension`
3. Add parsing logic in `FieldTypeExtension.fromString()` (handle snake_case if needed)
4. Create a new widget in `presentation/widgets/field_inputs/`
5. Add case to `FieldInputWidget` type router
6. Handle serialization in `Template.toMarkdown()` if the type has special options
7. Handle display in `NoteViewScreen._buildFieldValue()`
8. Handle table display in `NoteViewScreen._buildTableLayout()`
9. If the field uses non-standard storage (like customLabel's flat keys), update:
   - `_RecordForm` in `note_editor_screen.dart`
   - `_buildFieldRows` in `note_view_screen.dart`
   - `_buildTableLayout` in `note_view_screen.dart`
   - `_getRecordTitle` in `note_view_screen.dart`

### Adding a New Layout Type

1. Add value to `TemplateLayout` enum in `template.dart`
2. Add `displayName` and `iconName` in `TemplateLayoutExtension`
3. Add layout icon in `_getLayoutIcon()` in both `template_builder_screen.dart` and `template_list_screen.dart`
4. Add rendering method in `NoteViewScreen` (e.g., `_buildNewLayout`)
5. Add routing in `NoteViewScreen._buildBody()`

### Adding a New Screen

1. Create the screen widget in `presentation/screens/`
2. Add a route in `core/router.dart` using `GoRoute`
3. If it's a main nav section, add to `AppScaffold` navigation

---

## 13. Common Pitfalls for AI Agents

1. **Never use `Expanded` inside an inner unconstrained `Row`** — always ensure `Expanded` is in a `Row`/`Column` with proper constraints from its parent.

2. **Always serialize `customLabel` as `custom_label`** in markdown output — the enum name is camelCase but the file format uses snake_case.

3. **Custom label fields use flat keys** — never store as nested Map in records. Use `{fieldId}_label` and `{fieldId}_value`.

4. **When iterating record fields for display**, iterate over **template fields** (not `record.entries`) — this avoids showing internal flat keys like `fieldId_label` as separate rows.

5. **After navigation with `context.push()`**, always reload data if the destination screen can modify data. Use `await` + `_loadData()`.

6. **Template `toMarkdown()` must serialize ALL field options** — any new option added to `FieldOptions` must also be written in `toMarkdown()` or it will be silently lost.

7. **The `list` layout type was intentionally removed** — do not re-add it to `TemplateLayout` enum or switch statements.

8. **Date values include calendar mode suffix** — `2024-01-15|gregorian` or `1445-06-21|hijri`. The pipe separator is important.

9. **SharedPreferences stores everything as JSON strings** inside a few top-level keys — not individual keys per note. This means all notes are loaded at once.

10. **`AppState` is a singleton accessed via `AppState.instance`** — it extends `ChangeNotifier` and is listened to by the root widget for theme changes and initialization state.