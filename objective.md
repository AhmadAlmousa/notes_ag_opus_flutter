## 1. Application Overview

### 1.1 What is Organote?
**Organote** is a template-based note-taking application that:
- Stores all data as **human-readable markdown files**
- Uses **templates** to define structured data schemas
- Supports **multiple records per note** (like a mini-database)
- Features **dual calendar** (Gregorian/Hijri) date input
- Provides both **structured forms** and **raw markdown editing**

### 1.2 Core Philosophy
| Principle | Description |
|-----------|-------------|
| **Filesystem is Truth** | Markdown files are the primary data source. Database is only for indexing/search. |
| **Template-Driven** | Every note follows a template that defines its structure and fields. |
| **Human-Readable** | All data stored in markdown format that users can manually edit. |
| **Offline-First** | App works completely offline with local file storage. |
| **No Lock-In** | Data is portable - just markdown files in folders. |

---

## 2. Data Architecture

### 2.1 Storage Model
```
app_data/
├── templates/                    # Template definitions
│   ├── family_login.md
│   ├── gov_id.md
│   └── databases.md
├── notes/                        # Notes organized by category
│   ├── personal/
│   │   ├── gmail_accounts.md
│   │   └── banking_info.md
│   ├── work/
│   │   └── server_credentials.md
│   └── family/
│       └── family_members.md
└── smn_index.db                  # SQLite index (for search)
```

### 2.2 Template Entity
A template defines the structure for a type of note.


### 2.4 Field Types Reference
| Type | Input Widget | Validation | Storage Format |
|------|--------------|------------|----------------|
| [text] | TextField | Max length | String |
| [number] | NumberField | Min/max range | Number |
| [digits] | TextField | Digits only, exact length | String (preserves leading zeros) |
| [date] | DatePicker | Valid date | `YYYY-MM-DD\|format` (see Dual Calendar) |
| [dropdown] | DropdownButton | Must be in options list | String |
| [boolean] | Switch/Checkbox | - | Boolean |
| [url] | TextField | Valid URL format | String |
| [ip] | TextField | Valid IPv4/IPv6 | String |
| [password] | TextField (obscured) | Non-empty | String |

---

## 3. Markdown File Formats

### 3.1 Template File Format
```markdown
---
template_id: family_login
name: Family Login
version: 3
layout: cards
default_folder: family
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
      - Son
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
actions:
  - label: Copy Password
    field: password
    type: copy
```


### 3.2 Note File Format
```markdown
---
template_id: family_login
template_version: 3
id: gmail_accounts
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


### 3.3 Parser Implementation Notes

> **CRITICAL LESSON LEARNED**: The parser must handle:
> 1. YAML frontmatter between `---` markers
> 2. Code blocks with ` ```schema ` or ` ```data ` language tags
> 3. Nested YAML within code blocks
> 4. Multiple records in the data block (array of maps)



---

## 4. Dual Calendar System

### 4.1 Overview
Date fields can support three calendar modes:
- **gregorian**: Standard Gregorian calendar only
- **hijri**: Islamic Hijri calendar only  
- **dual**: Toggle between both with automatic conversion

### 4.2 Storage Format
Dates are stored as: `{date_string}|{format_indicator}`

Examples:
- `2024-01-15|gregorian` - Gregorian date
- `1445-06-21|hijri` - Hijri date


---

## 5. Application Features & Screens

### 5.1 Dashboard
**Purpose**: Home screen with quick access to everything

**Content**:
- Template cards with "New Note" action
- Recent notes list (last 10)
- Compliance status indicator (notes using outdated templates)
- Quick search

### 5.2 Template List
**Purpose**: View and manage all templates

**Features**:
- Grid/list view of templates
- Each shows: name, field count, layout icon
- Long-press/menu for: Edit, Delete, Create Note

### 5.3 Template Builder
**Purpose**: Create/edit template schemas

**Sections**:
1. **Basic Info**: ID, name, version, layout, default folder
2. **Display Settings**: Preset, primary field
3. **Fields List**: Dynamic list with add/remove/reorder
4. **Actions List**: Define action buttons

**Field Editor** (per field):
- ID input (auto-format: lowercase, underscores)
- Label input
- Type dropdown
- Required toggle
- Type-specific options (conditionally shown):
  - Number: min, max inputs
  - Digits: length input
  - Dropdown: options list editor
  - Date: calendar selector (Gregorian/Hijri/Dual)
  - Relation: template picker

### 5.4 Notes List  
**Purpose**: Browse all notes by category

**Features**:
- Category tabs/sidebar
- Note cards showing: filename, template, record count, tags
- Search within category
- Filter by template

### 5.5 Note View
**Purpose**: Display note data in read-only mode

**Layouts**:
- **Table**: Records as table rows
- **Cards**: Records as styled cards

**Actions**:
- Edit button → Note Editor
- Source button → Markdown Editor
- Delete button
- Action buttons from template (copy, open link, etc.)

### 5.6 Note Editor
**Purpose**: Form-based structured data entry

**Sections**:
1. **Metadata**: Category picker, filename, tags
2. **Records**: One form per record
   - Add Record / Remove Record buttons
   - Field inputs based on type

**Validation**:
- Real-time validation as user types
- Show errors inline next to fields
- Block save if required fields empty

### 5.7 Markdown Source Editor
**Purpose**: Raw markdown editing with preview

**Layout**: Responsive.
- Raw markdown editor (monospace font, line numbers)
- Live rendered HTML-like preview. For mobile view, preview is accessed via button bar.

**Features**:
- Sync scroll between panes
- Keyboard shortcuts (Ctrl+S to save)
- Unsaved changes warning

---


## 7. indexing/search
Use Json to index and search. File system is always source of truth.

---

## 8. Validation System


> **IMPORTANT**: These are hard-won lessons from the Flask implementation. Following these will save significant debugging time.

### 9.1 Template Syntax in Dynamic UI Code

**NEVER mix template engine syntax with JavaScript/Dart in string templates.**

❌ **WRONG** (causes parsing errors):
```javascript
// This breaks because {{ looks like template syntax
const url = `/api/notes/${category}/${filename}`;
```

✅ **CORRECT** (use concatenation):
```javascript
const url = '/api/notes/' + category + '/' + filename;
```

For Flutter, this is less of an issue, but be careful with any code generation tools.

### 9.2 Object Formatting in Dynamic Code

**Maintain consistent indentation** - Mixed indentation in JSON/object literals is the #1 cause of parsing failures.

```dart
// Use consistent 2-space or 4-space indentation throughout
final data = {
  'template_id': templateId,
  'category': category,
  'records': records.map((r) => r.toJson()).toList(),
};
```

### 9.3 Date Field Storage

**Always include format indicator** - Without it, you can't know which calendar was used for input.

```dart
// Store as: "2024-01-15|gregorian" or "1445-06-21|hijri"
String formatDateForStorage(DateTime date, String inputMode) {
  if (inputMode == 'gregorian') {
    return '${formatGregorian(date)}|gregorian';
  } else {
    return '${formatHijri(date)}|hijri';
  }
}

(String date, String format) parseDateFromStorage(String stored) {
  final parts = stored.split('|');
  return (parts[0], parts.length > 1 ? parts[1] : 'gregorian');
}
```

### 9.4 YAML Parsing Edge Cases

**Handle these YAML parsing gotchas:**

1. **Strings that look like numbers**: YAML parses `007` as `7`. Quote strings in schema if they need leading zeros.

2. **Special characters in values**: Colons, quotes, and brackets need escaping.

3. **Empty values**: YAML `""` vs `null` vs missing key all behave differently.

```dart
// When serializing to YAML, quote values that could be misinterpreted
String quoteIfNeeded(dynamic value) {
  if (value is String) {
    if (value.isEmpty || 
        value.contains(':') || 
        value.contains('"') ||
        RegExp(r'^\d').hasMatch(value)) {
      return '"${value.replaceAll('"', '\\"')}"';
    }
  }
  return value.toString();
}
```

### 9.5 Category/Filename Sanitization

**Always sanitize user input for filesystem safety:**

```dart
String sanitizeForFilesystem(String input) {
  return input
    .toLowerCase()
    .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
    .replaceAll(RegExp(r'_+'), '_')
    .replaceAll(RegExp(r'^_|_$'), '');
}

String generateFilename(String templateId) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return '${templateId}_$timestamp.md';
}
```

### 9.6 Index Synchronization

**Update index AFTER successful file write, not before:**

```dart
Future<void> saveNote(Note note) async {
  // 1. Write to filesystem first
  await _writeNoteFile(note);
  
  // 2. Update index only after file write succeeds
  await _updateNoteIndex(note);
}

Future<void> deleteNote(String category, String filename) async {
  // 1. Remove from index first
  await _removeFromIndex(category, filename);
  
  // 2. Then delete file
  await _deleteNoteFile(category, filename);
}
```

### 9.7 Multi-Record Form State

**Each record needs its own controller instances:**

```dart
class NoteEditorState {
  List<Map<String, TextEditingController>> recordControllers = [];
  
  void addRecord() {
    final controllers = <String, TextEditingController>{};
    for (final field in template.fields) {
      controllers[field.id] = TextEditingController();
    }
    recordControllers.add(controllers);
  }
  
  void removeRecord(int index) {
    // Dispose controllers before removing
    for (final controller in recordControllers[index].values) {
      controller.dispose();
    }
    recordControllers.removeAt(index);
  }
  
  @override
  void dispose() {
    for (final record in recordControllers) {
      for (final controller in record.values) {
        controller.dispose();
      }
    }
  }
}
```

### 9.8 Password Field Security

**Password fields need special handling:**

```dart
class PasswordField extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: !_showPassword,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _showPassword = !_showPassword),
        ),
      ),
    );
  }
}
```

### 9.9 Search Index Rebuild

**Provide ability to rebuild search index from files:**

```dart
Future<void> rebuildIndex() async {
  // Clear existing index
  await _db.delete('notes');
  await _db.delete('search_index');
  await _db.delete('templates');
  
  // Re-index all templates
  for (final file in await _listTemplateFiles()) {
    final template = await parseTemplateFile(file);
    await _indexTemplate(template);
  }
  
  // Re-index all notes
  for (final category in await _listCategories()) {
    for (final file in await _listNotesInCategory(category)) {
      final note = await parseNoteFile(file, category);
      await _indexNote(note);
    }
  }
}
```

---

## 10. Flutter Package Recommendations

| Purpose | Recommended Package |
|---------|---------------------|
| State Management | `riverpod` or `provider` |
| File System | `path_provider` + `dart:io` |
| YAML Parsing | `yaml` |
| Markdown Rendering | `flutter_markdown` |
| Hijri Calendar | `hijri` |
| Date Picker | `flutter_datetime_picker` or built-in |
| Form Validation | Built-in `Form` + `TextFormField` |
| Navigation | `go_router` |
| Icons | `lucide_icons` or `flutter_tabler_icons` |

---

## 11. UI/UX Design Guidelines



## 12. Testing Checklist

Before considering the app complete, verify:

- [ ] Create template with all field types
- [ ] Edit template (version should increment)
- [ ] Delete template
- [ ] Create note from template
- [ ] Add multiple records to note
- [ ] Remove record from note
- [ ] Edit note fields
- [ ] Delete note
- [ ] Dual calendar date entry (both directions)
- [ ] Password field show/hide toggle
- [ ] Dropdown field with options
- [ ] Required field validation
- [ ] Number min/max validation
- [ ] Digits length validation
- [ ] Source editor - edit and save
- [ ] Search finds notes by filename
- [ ] Search finds notes by field value
- [ ] Search finds notes by tag
- [ ] Category filtering works
- [ ] New category creation
- [ ] Action buttons (copy, open link)
- [ ] App restart - data persists
- [ ] Compliance status shows outdated notes

---

## 13. API Reference (for Backend Sync - Optional)

If implementing cloud sync later, use this REST API pattern:

```
GET    /api/templates              # List templates
POST   /api/templates              # Create template
GET    /api/templates/{id}         # Get template
PUT    /api/templates/{id}         # Update template
DELETE /api/templates/{id}         # Delete template

GET    /api/notes                  # List notes (?category=x)
POST   /api/notes                  # Create note
GET    /api/notes/{cat}/{file}     # Get note
PUT    /api/notes/{cat}/{file}     # Update note
DELETE /api/notes/{cat}/{file}     # Delete note
GET    /api/notes/{cat}/{file}/raw # Get raw markdown
PUT    /api/notes/{cat}/{file}/raw # Save raw markdown

GET    /api/categories             # List categories
GET    /api/search?q={query}       # Search notes
GET    /api/compliance             # Compliance status
```

---
