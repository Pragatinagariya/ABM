import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class MiniCalendar extends StatefulWidget {
  final String apiDate; // Date from API (e.g., "01-04-2024")
  final List<String> highlightedDates; // Highlighted Dates from API

  MiniCalendar({required this.apiDate, required this.highlightedDates});

  @override
  _MiniCalendarState createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<MiniCalendar> {
  late DateTime selectedMonth;

  @override
  void initState() {
    super.initState();

    // ✅ Convert "dd-MM-yyyy" to "yyyy-MM-dd"
    selectedMonth = _convertDate(widget.apiDate);
  }

  DateTime _convertDate(String dateString) {
    try {
      // Convert "01-04-2024" → "2024-04-01"
      DateFormat inputFormat = DateFormat("dd-MM-yyyy");
      DateFormat outputFormat = DateFormat("yyyy-MM-dd");

      String formattedDate = outputFormat.format(inputFormat.parse(dateString));
      return DateTime.parse(formattedDate);
    } catch (e) {
      print("Invalid date format: $dateString");
      return DateTime.now(); // Fallback to current date if parsing fails
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 📌 Month & Year Header with Mini Icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.blue), // Mini Icon
            SizedBox(width: 5),
            Text(
              DateFormat.yMMMM().format(selectedMonth), // Example: April 2024
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        SizedBox(height: 5),

        // 📌 Calendar UI
        Container(
          width: 160, // Small calendar size
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300, width: 1),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
          child: TableCalendar(
            firstDay: DateTime(selectedMonth.year, selectedMonth.month, 1),
            lastDay: DateTime(selectedMonth.year, selectedMonth.month + 1, 0),
            focusedDay: selectedMonth,
            headerVisible: false, // Hide default header
            daysOfWeekVisible: false, // Hide day names
            rowHeight: 25, // Compact height

            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(5),
              ),
              markerDecoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(5), // Highlight API dates
              ),
              defaultTextStyle: TextStyle(fontSize: 12),
              weekendTextStyle: TextStyle(fontSize: 12, color: Colors.black54),
            ),

            // Highlight API Dates
            eventLoader: (day) {
              String formattedDate = DateFormat("yyyy-MM-dd").format(day);
              return widget.highlightedDates.contains(formattedDate) ? [1] : [];
            },
          ),
        ),
      ],
    );
  }
}
