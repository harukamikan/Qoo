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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'HACK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.location_on,
            color: Colors.orange,
            size: 30,
          ),
        ],
      ),
    );
  }
}