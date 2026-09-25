import 'package:flutter/material.dart';

/// Type scale. Reference these in widgets, e.g.
/// Text('Title', style: AppTypography.title)
/// or via Theme.of(context).textTheme once wired into AppTheme.
class AppTypography {
  AppTypography._();
  static const headline =
      TextStyle(fontSize: 24, fontWeight: FontWeight.w700);
  static const title = TextStyle(fontSize: 18, fontWeight: FontWeight.w600);
  static const body = TextStyle(fontSize: 16);
  static const caption = TextStyle(fontSize: 12);
}
