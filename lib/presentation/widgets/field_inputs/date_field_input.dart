import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/field.dart';

/// Date field with dual calendar support.
class DateFieldInput extends StatefulWidget {
  const DateFieldInput({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.hasError = false,
  });

  final Field field;
  final String value;
  final ValueChanged<dynamic> onChanged;
  final bool hasError;

  @override
  State<DateFieldInput> createState() => _DateFieldInputState();
}

class _DateFieldInputState extends State<DateFieldInput> {
  DateTime? _selectedDate;
  String _calendarMode = 'gregorian';
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _parseInitialValue();
    _controller = TextEditingController(text: _getDisplayText());
  }

  void _parseInitialValue() {
    if (widget.value.isNotEmpty) {
      final (datePart, format) = AppDateUtils.parseFromStorage(widget.value);
      _calendarMode = format;
      _selectedDate = AppDateUtils.parseToDateTime(widget.value);
    }
  }

  String _getDisplayText() {
    if (_selectedDate == null) return '';

    if (_calendarMode == 'hijri') {
      return AppDateUtils.formatHijriDisplay(_selectedDate!);
    }
    return AppDateUtils.formatGregorianDisplay(_selectedDate!);
  }

  void _updateController() {
    _controller.text = _getDisplayText();
  }

  void _selectDate() async {
    final theme = Theme.of(context);

    if (_calendarMode == 'hijri') {
      _showHijriPicker();
    } else {
      final date = await showDatePicker(
        context: context,
        initialDate: _selectedDate ?? DateTime.now(),
        firstDate: DateTime(1900),
        lastDate: DateTime(2100),
        builder: (context, child) {
          return Theme(
            data: theme.copyWith(
              colorScheme: theme.colorScheme.copyWith(
                primary: AppTheme.primaryColor,
              ),
            ),
            child: child!,
          );
        },
      );

      if (date != null) {
        setState(() {
          _selectedDate = date;
          _updateController();
        });
        widget.onChanged(AppDateUtils.formatForStorage(date, _calendarMode));
      }
    }
  }

  void _showHijriPicker() {
    final hijriNow = HijriCalendar.now();

    showDialog(
      context: context,
      builder: (context) => _HijriDatePicker(
        initialDate: _selectedDate != null
            ? HijriCalendar.fromDate(_selectedDate!)
            : hijriNow,
        onSelected: (hijriDate) {
          final gregorianDate = AppDateUtils.hijriToGregorian(
            hijriDate.hYear,
            hijriDate.hMonth,
            hijriDate.hDay,
          );
          setState(() {
            _selectedDate = gregorianDate;
            _updateController();
          });
          widget.onChanged(AppDateUtils.formatForStorage(
            gregorianDate,
            _calendarMode,
          ));
        },
      ),
    );
  }

  void _toggleCalendarMode() {
    setState(() {
      _calendarMode = _calendarMode == 'gregorian' ? 'hijri' : 'gregorian';
      _updateController();
    });

    if (_selectedDate != null) {
      widget.onChanged(AppDateUtils.formatForStorage(
        _selectedDate!,
        _calendarMode,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calendarMode = widget.field.options?.calendarMode;
    final showToggle = calendarMode == CalendarMode.dual;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          readOnly: true,
          onTap: _selectDate,
          decoration: InputDecoration(
            labelText: widget.field.label,
            hintText: 'Select date',
            prefixIcon: const Icon(Icons.calendar_today),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showToggle)
                  IconButton(
                    icon: Icon(
                      _calendarMode == 'hijri'
                          ? Icons.bedtime
                          : Icons.wb_sunny,
                      size: 20,
                    ),
                    tooltip: _calendarMode == 'hijri'
                        ? 'Switch to Gregorian'
                        : 'Switch to Hijri',
                    onPressed: _toggleCalendarMode,
                  ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        if (_selectedDate != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              _calendarMode == 'hijri'
                  ? 'Gregorian: ${AppDateUtils.formatGregorianDisplay(_selectedDate!, short: true)}'
                  : 'Hijri: ${AppDateUtils.formatHijriDisplay(_selectedDate!, short: true)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Simple Hijri date picker dialog.
class _HijriDatePicker extends StatefulWidget {
  const _HijriDatePicker({
    required this.initialDate,
    required this.onSelected,
  });

  final HijriCalendar initialDate;
  final ValueChanged<HijriCalendar> onSelected;

  @override
  State<_HijriDatePicker> createState() => _HijriDatePickerState();
}

class _HijriDatePickerState extends State<_HijriDatePicker> {
  late int _year;
  late int _month;
  late int _day;

  final List<String> _months = [
    'Muharram',
    'Safar',
    "Rabi' al-Awwal",
    "Rabi' al-Thani",
    'Jumada al-Awwal',
    'Jumada al-Thani',
    'Rajab',
    "Sha'ban",
    'Ramadan',
    'Shawwal',
    "Dhu al-Qi'dah",
    'Dhu al-Hijjah',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.initialDate.hYear;
    _month = widget.initialDate.hMonth;
    _day = widget.initialDate.hDay;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Select Hijri Date'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Year
          Row(
            children: [
              const Text('Year: '),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: DropdownButton<int>(
                  value: _year,
                  isExpanded: true,
                  items: List.generate(100, (i) {
                    final year = HijriCalendar.now().hYear - 50 + i;
                    return DropdownMenuItem(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }),
                  onChanged: (v) => setState(() => _year = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Month
          Row(
            children: [
              const Text('Month: '),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButton<int>(
                  value: _month,
                  isExpanded: true,
                  items: List.generate(12, (i) {
                    return DropdownMenuItem(
                      value: i + 1,
                      child: Text(_months[i]),
                    );
                  }),
                  onChanged: (v) => setState(() => _month = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Day
          Row(
            children: [
              const Text('Day: '),
              const SizedBox(width: 8),
              SizedBox(
                width: 80,
                child: DropdownButton<int>(
                  value: _day.clamp(1, 30),
                  isExpanded: true,
                  items: List.generate(30, (i) {
                    return DropdownMenuItem(
                      value: i + 1,
                      child: Text((i + 1).toString()),
                    );
                  }),
                  onChanged: (v) => setState(() => _day = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Gregorian: ${AppDateUtils.getGregorianEquivalent(_year, _month, _day)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final hijri = HijriCalendar()
              ..hYear = _year
              ..hMonth = _month
              ..hDay = _day;
            widget.onSelected(hijri);
            Navigator.pop(context);
          },
          child: const Text('Select'),
        ),
      ],
    );
  }
}
