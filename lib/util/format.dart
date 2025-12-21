import 'package:intl/intl.dart';

String titleCase(String str) =>
    "${str[0].toString().toUpperCase()}${str.toString().substring(1)}";

String getReadableDate(String date) {
  final DateTime parsedDate = DateTime.parse(date);
  return DateFormat('MMM d, yyyy').format(parsedDate);
}
