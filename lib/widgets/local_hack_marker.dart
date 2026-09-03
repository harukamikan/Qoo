import 'package:flutter/material.dart';
import '../models/local_hack.dart';
import 'local_hack_dialog.dart';

class LocalHackMarker extends StatelessWidget {
  final LocalHack hack;

  const LocalHackMarker({super.key, required this.hack});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => LocalHackDialog.show(context, hack),
      child: const Text('💡', style: TextStyle(fontSize: 30)),
    );
  }
}