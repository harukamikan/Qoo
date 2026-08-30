import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Authentication と Google Sign-In をまとめて扱うサービス。
///
/// 認証方式は「Googleアカウントでのサインインのみ」。メール/パスワードは使わない。
/// アプリ内の他のクラスは、このクラスを経由してのみ認証操作を行う。
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// google-services.json / GoogleService-Info.plist に OAuth クライアントが
  /// 含まれていれば空のままでよい。含まれていない場合のみ、Firebase コンソールの
  /// 「ウェブ クライアント ID」（client_type 3）をここに入れる。
  static const String? _serverClientId = null;

  bool _initialized = false;

  /// プロフィール登録の完了など、認証状態ストリーム以外の理由で
  /// [AuthGate] を再評価させたいときに使う通知。
  final ValueNotifier<int> refresh = ValueNotifier<int>(0);

  void notifyProfileChanged() => refresh.value++;

  /// アプリ起動時に一度だけ呼ぶ。GoogleSignIn v7 は initialize() が必須。
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(serverClientId: _serverClientId);
    _initialized = true;
  }

  /// ログイン状態の変化を通知するストリーム（未ログイン時は null）。
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  String? get uid => _auth.currentUser?.uid;

  /// Google アカウントでサインインする。
  /// ユーザーがキャンセルした場合は [GoogleSignInException]（code: canceled）を投げる。
  Future<UserCredential> signInWithGoogle() async {
    await ensureInitialized();

    final GoogleSignInAccount account =
        await GoogleSignIn.instance.authenticate();
    final GoogleSignInAuthentication auth = account.authentication;

    final credential = GoogleAuthProvider.credential(idToken: auth.idToken);
    return _auth.signInWithCredential(credential);
  }

  /// サインアウト（Firebase と Google の両方）。
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('GoogleSignIn.signOut failed: $e');
    }
    await _auth.signOut();
  }
}
