# riot agitator


# ビルド/開発環境設定
## SDK導入

1. flutter SDKの設置(略)  
  https://flutter.dev/docs/get-started/install  
  DartSDKも含まれるようだ  
  pathを設定
  
2. flutterのターゲットにwebを追加
    > flutter config --enable-web

    この設定は $HOME/.flutter_settings に格納される

## Intelli-J設定(使うなら)
1. Flutter plugin導入
2. Flutter SDK pathを設定
3. Module にライブラリ`Fluuter plugin`、`Dart SDK` を追加

Intellijのモジュール定義ファイルは `*.iml` 

# 開発履歴
# Flutterプロジェクトのテンプレ準備
> flutter create --project-name=riotagitator .

Flutterのプロジェクトファイルは `pubspec.yaml`


