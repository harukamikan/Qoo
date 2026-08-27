import 'package:flutter/material.dart';

class HelpfulButton extends StatefulWidget {
  final String commentId;
  final int initialCount;

  const HelpfulButton({
    super.key,
    required this.commentId,
    this.initialCount = 0,
  });

  @override
  State<HelpfulButton> createState() => _HelpfulButtonState();
}

class _HelpfulButtonState extends State<HelpfulButton> {
  bool _isHelpful = false;
  late int _count;

  @override
  void initState() {
    super.initState();
    _count = widget.initialCount;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          _isHelpful = !_isHelpful;
          _count += _isHelpful ? 1 : -1;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _isHelpful ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isHelpful ? Colors.blue : Colors.grey.shade400,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isHelpful ? Icons.thumb_up : Icons.thumb_up_outlined,
              size: 18,
              color: _isHelpful ? Colors.blue : Colors.grey.shade700,
            ),
            const SizedBox(width: 6),
            Text(
              '参考になった $_count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: _isHelpful ? Colors.blue : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}