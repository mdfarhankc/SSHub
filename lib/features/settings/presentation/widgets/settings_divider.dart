import 'package:flutter/material.dart';

// Divider inset to line up with the 20px horizontal padding used by the rows.
class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 20, endIndent: 20);
}
