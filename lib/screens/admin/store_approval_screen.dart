import 'package:flutter/material.dart';
import '../../models/store.dart';
import '../../services/store_repository.dart';

/// 未承認の店舗を一覧表示し、承認できるシンプルなAdmin画面。
class StoreApprovalScreen extends StatefulWidget {
  const StoreApprovalScreen({super.key});

  @override
  State<StoreApprovalScreen> createState() => _StoreApprovalScreenState();
}

class _StoreApprovalScreenState extends State<StoreApprovalScreen> {
  List<Store> _pendingStores = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final stores = await StoreRepository.instance.fetchPendingStores();
    if (!mounted) return;
    setState(() {
      _pendingStores = stores;
      _loading = false;
    });
  }

  Future<void> _approve(Store store) async {
    await StoreRepository.instance.approveStore(store.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${store.name}を承認しました')),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('店舗承認（Admin）')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pendingStores.isEmpty
              ? const Center(child: Text('未承認の店舗はありません'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingStores.length,
                  itemBuilder: (context, index) {
                    final store = _pendingStores[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(store.name),
                        subtitle: Text('${store.category} / ${store.address}'),
                        trailing: FilledButton(
                          onPressed: () => _approve(store),
                          child: const Text('承認'),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}