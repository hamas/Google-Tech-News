import 'package:flutter/material.dart';

enum ShareTheme {
  dark('Dark', Icons.dark_mode, Colors.black),
  glass('Glass', Icons.blur_on, Colors.blueGrey),
  colorful('Colorful', Icons.palette, Colors.purple),
  minimal('Minimal', Icons.check_box_outline_blank, Colors.white);

  final String label;
  final IconData icon;
  final Color primaryColor;

  const ShareTheme(this.label, this.icon, this.primaryColor);
}
