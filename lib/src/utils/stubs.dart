// Web専用のAPIをモバイル/デスクトップでビルド可能にするためのスタブファイル

class Window {
  final OnBeforeUnload onBeforeUnload = OnBeforeUnload();
}

class OnBeforeUnload {
  void listen(dynamic callback) {}
}

class BeforeUnloadEvent {
  String? returnValue;
}

final window = Window();
