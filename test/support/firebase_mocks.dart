// テストから Firebase の実ネイティブ層を使わずに
// `Firebase.initializeApp()` を通すための最小限のセットアップ。
// firebase_core_platform_interface が標準で用意しているテストヘルパーに委譲する。
export 'package:firebase_core_platform_interface/test.dart'
    show setupFirebaseCoreMocks;
