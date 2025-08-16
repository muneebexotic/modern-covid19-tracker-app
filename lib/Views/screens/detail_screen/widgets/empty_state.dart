import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final String message;

  const EmptyState({Key? key, this.message = 'No data'}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message, style: const TextStyle(fontSize: 16, color: Color(0xFF64748B))));
  }
}
