# riot agitator


# ビルド/開発環境設定
## SDK導入

1. flutter SDKの設置
  https://flutter.dev/docs/get-started/install  
  DartSDKも含まれるようだ  
  pathを設定
  
2. flutterのターゲットにwebを追加し Web(beta)を有効に
```
flutter config --enable-web  (*1)
flutter channel beta
flutter upgrade  
flutter devices
```                   
*1: この設定は ~/.flutter_settings に格納される


## Intelli-J設定(使うなら)
1. Flutter plugin導入
2. Flutter SDK pathを設定
3. Module にライブラリ`Fluuter plugin`、`Dart SDK` を追加

Intellijのモジュール定義ファイルは `*.iml` 

# テスト実行
- CLI
> flutter run -d chrome

- [intelliJ]デバッグ実行  
Deviceを選択し、(Chromeまたはその他)
実行ボタンクリック

# 開発履歴
## Flutterプロジェクトのテンプレ準備
> flutter create --project-name=riotagitator .

Flutterのプロジェクトファイルは `pubspec.yaml`

## Cloud Firestore
(参考)https://pub.dev/packages/cloud_firestore
- pubspec.yaml
  - 依存関係をdependancesに追記
- index.html
  - ライブラリのロード追加
  - Firestore API-Key情報追加

## Cloud Firestore Realtime
サンプルアプリ作成 - main_test1.dart

## ユーザ認証
 - サンプルコード: https://github.com/firebase/firebaseui-web
 - ガイド: https://www.flutter-study.dev/firebase/authentication/
   - pubspec.yaml: dependanciesに
     - firebase_auth: 0.18.0+1 追加
   - indxe.html:　追加
     - <script src="https://www.gstatic.com/firebasejs/7.15.5/firebase-auth.js"></script>

 
## Cloud firestore 備考
- アクセスルール初期設定では、期限が制限30日に制限されている(すぐ開発できるよう)
  - 久しぶりに使う場合はルールを見直すこと

- API Keyは公開しても構わない。
  - ただし、デフォルトのアクセス管理はすべて許可になっている
  - なので、公開前にはかならずユーザ認証で制限すること
  
