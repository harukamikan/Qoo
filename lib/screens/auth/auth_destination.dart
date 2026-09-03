import '../../models/user_role.dart';

/// ログイン後、[AuthGate] がどの画面を出すべきかの判定結果。
enum AuthDestination {
  storeHome, // stores/{uid} 登録済み
  touristHome, // users/{uid} 登録済み
  storeRegistration, // 未登録・店舗ロール選択中
  onboarding, // 未登録・観光客ロール（またはロール不明）
}

/// [AuthGate] の振り分けロジック本体。Firestore の結果（bool）と
/// ログイン前に選んだ役割だけを受け取る純粋関数にして、
/// Firebase を初期化しなくてもロジックだけを単体テストできるようにしている。
///
/// 優先順位: 既にどちらかのプロフィールが存在する場合は、選んだ役割に
/// 関わらず実データを優先する（役割選択を間違えてログインしても事故らないため）。
AuthDestination resolveAuthDestination({
  required bool hasStore,
  required bool hasProfile,
  required UserRole? pendingRole,
}) {
  if (hasStore) return AuthDestination.storeHome;
  if (hasProfile) return AuthDestination.touristHome;
  return pendingRole == UserRole.store
      ? AuthDestination.storeRegistration
      : AuthDestination.onboarding;
}
