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
# Flutterプロジェクトのテンプレ準備
> flutter create --project-name=riotagitator .

Flutterのプロジェクトファイルは `pubspec.yaml`


