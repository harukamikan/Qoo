import 'package:cloud_firestore/cloud_firestore.dart';

class FriendRequest {
  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String declined = 'declined';

  final String id;
  final String fromUid;
  final String fromFriendCode;
  final String fromName;
  final String toUid;
  final String toFriendCode;
  final String status;
  final DateTime? createdAt;

  FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromFriendCode,
    required this.fromName,
    required this.toUid,
    required this.toFriendCode,
    required this.status,
    required this.createdAt,
  });

  factory FriendRequest.fromMap(String id, Map<String, dynamic> map) {
    final createdAtRaw = map['createdAt'];
    return FriendRequest(
      id: id,
      fromUid: map['fromUid'] as String? ?? '',
      fromFriendCode: map['fromFriendCode'] as String? ?? '',
      fromName: map['fromName'] as String? ?? '',
      toUid: map['toUid'] as String? ?? '',
      toFriendCode: map['toFriendCode'] as String? ?? '',
      status: map['status'] as String? ?? pending,
        createdAt:
          createdAtRaw is Timestamp ? createdAtRaw.toDate() : createdAtRaw as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fromUid': fromUid,
      'fromFriendCode': fromFriendCode,
      'fromName': fromName,
      'toUid': toUid,
      'toFriendCode': toFriendCode,
      'status': status,
      'createdAt': createdAt,
    };
  }
}