import 'package:flutter/material.dart';
import '../models/local_hack.dart';

class LocalHackDialog extends StatelessWidget {
  final LocalHack hack;

  const LocalHackDialog({super.key, required this.hack});

  static void show(BuildContext context, LocalHack hack) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LocalHackDialog(hack: hack),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '💡 Local Hack (${hack.category})',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hack.title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                hack.content,
                style: const TextStyle(fontSize: 15, height: 1.6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}