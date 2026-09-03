import 'package:flutter/material.dart';

import '../models/friend_request.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/friend_service.dart';
import '../services/ui_translations.dart';
import '../theme/app_colors.dart';

class FriendManagementPanel extends StatefulWidget {
  final UserProfile profile;

  const FriendManagementPanel({super.key, required this.profile});

  @override
  State<FriendManagementPanel> createState() => _FriendManagementPanelState();
}

class _FriendManagementPanelState extends State<FriendManagementPanel> {
  late final TextEditingController _friendCodeController;
  final _searchController = TextEditingController();
  bool _savingCode = false;
  bool _sendingRequest = false;

  @override
  void initState() {
    super.initState();
    _friendCodeController = TextEditingController(text: widget.profile.friendCode);
  }

  @override
  void didUpdateWidget(covariant FriendManagementPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.friendCode != widget.profile.friendCode) {
      _friendCodeController.text = widget.profile.friendCode;
    }
  }

  @override
  void dispose() {
    _friendCodeController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _saveFriendCode() async {
    final uid = AuthService.instance.uid;
    if (uid == null) return;

    setState(() => _savingCode = true);
    try {
      await FriendService.instance.updateFriendCode(
        uid,
        _friendCodeController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UiTranslations.t('友達IDを更新しました'))),
      );
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _savingCode = false);
      }
    }
  }

  Future<void> _sendRequest() async {
    final uid = AuthService.instance.uid;
    if (uid == null) return;

    final code = _searchController.text.trim();
    if (code.isEmpty) return;

    setState(() => _sendingRequest = true);
    try {
      await FriendService.instance.sendFriendRequest(
        fromUid: uid,
        friendCode: code,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(UiTranslations.t('友達申請を送りました'))),
      );
      _searchController.clear();
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() => _sendingRequest = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = AuthService.instance.uid;
    if (uid == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        _SectionCard(
          title: UiTranslations.t('友達ID'),
          children: [
            TextField(
              controller: _friendCodeController,
              decoration: InputDecoration(
                labelText: UiTranslations.t('公開ID'),
                helperText: UiTranslations.t('このIDで検索されます'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _savingCode ? null : _saveFriendCode,
              child: Text(_savingCode
                  ? UiTranslations.t('保存中...')
                  : UiTranslations.t('IDを保存')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: UiTranslations.t('ID検索して申請'),
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: UiTranslations.t('友達IDを入力'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _sendingRequest ? null : _sendRequest,
              icon: const Icon(Icons.person_add),
              label: Text(_sendingRequest
                  ? UiTranslations.t('送信中...')
                  : UiTranslations.t('友達申請')),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<FriendRequest>>(
          future: FriendService.instance.fetchIncomingRequests(uid),
          builder: (context, snapshot) {
            final requests = snapshot.data ?? const [];
            return _SectionCard(
              title: UiTranslations.t('友達申請'),
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                if (requests.isEmpty && snapshot.connectionState != ConnectionState.waiting)
                  Text(UiTranslations.t('今は申請がありません')),
                for (final request in requests)
                  _RequestTile(
                    request: request,
                    onAccept: () async {
                      await FriendService.instance.acceptFriendRequest(request);
                      if (!context.mounted) return;
                      setState(() {});
                    },
                    onDecline: () async {
                      await FriendService.instance.declineFriendRequest(request);
                      if (!context.mounted) return;
                      setState(() {});
                    },
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<UserProfile>>(
          future: FriendService.instance.fetchFriendProfiles(uid),
          builder: (context, snapshot) {
            final friends = snapshot.data ?? const [];
            return _SectionCard(
              title: UiTranslations.t('友達一覧'),
              children: [
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: LinearProgressIndicator(),
                  ),
                if (friends.isEmpty && snapshot.connectionState != ConnectionState.waiting)
                  Text(UiTranslations.t('まだ友達がいません')),
                for (final friend in friends)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(friend.name),
                    subtitle: Text(friend.friendCode),
                    trailing: TextButton(
                      onPressed: () async {
                        await FriendService.instance.deleteFriend(
                          uid: uid,
                          friendUid: friend.userId,
                        );
                        if (!context.mounted) return;
                        setState(() {});
                      },
                      child: Text(UiTranslations.t('削除')),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _RequestTile extends StatelessWidget {
  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _RequestTile({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(request.fromName.isEmpty ? request.fromFriendCode : request.fromName),
      subtitle: Text(request.fromFriendCode),
      trailing: Wrap(
        spacing: 8,
        children: [
          OutlinedButton(
            onPressed: onDecline,
            child: Text(UiTranslations.t('拒否')),
          ),
          ElevatedButton(
            onPressed: onAccept,
            child: Text(UiTranslations.t('承認')),
          ),
        ],
      ),
    );
  }
}