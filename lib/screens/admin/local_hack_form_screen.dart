import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../../theme/app_colors.dart';
import '../../widgets/location_picker_sheet.dart';

/// 運営がローカルルール（LocalHack）を投稿するフォーム。
/// 投稿すると Firestore の local_hacks コレクションに保存され、
/// 地図の💡トグルで既存データと合わせて表示される。
class LocalHackFormScreen extends StatefulWidget {
  const LocalHackFormScreen({super.key});

  @override
  State<LocalHackFormScreen> createState() => _LocalHackFormScreenState();
}

class _LocalHackFormScreenState extends State<LocalHackFormScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _category = '神社';
  final _categories = ['神社', '寺', '交通', '温泉・銭湯', 'グルメ・屋台', 'グルメ・ラーメン', 'その他'];
  ll.LatLng? _position;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _pickLocation() {
    showLocationPickerSheet(
      context,
      initialPosition: _position ?? const ll.LatLng(33.5902, 130.4017),
      onLocationSelected: (position, placeName) {
        setState(() => _position = position);
      },
    );
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      _showError('タイトルと内容を入力してください');
      return;
    }
    if (_position == null) {
      _showError('地図から場所を指定してください');
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance.collection('local_hacks').add({
        'place_name': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _category,
        'latitude': _position!.latitude,
        'longitude': _position!.longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ローカルルールを登録しました')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showError('登録に失敗しました');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ローカルルール投稿（運営）')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'カテゴリ',
                  border: OutlineInputBorder(),
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _contentController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: '内容（マナーガイド本文）',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickLocation,
                icon: const Icon(Icons.map_outlined),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(_position == null
                      ? '地図から場所を指定'
                      : '緯度: ${_position!.latitude.toStringAsFixed(4)} '
                          '経度: ${_position!.longitude.toStringAsFixed(4)}'),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size.fromHeight(52),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('登録する'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}