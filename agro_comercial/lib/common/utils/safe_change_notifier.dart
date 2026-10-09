import 'package:flutter/foundation.dart';

// ChangeNotifier que ignora avisos depois de ser descartado.
//
// Os controllers fazem operações assíncronas (Firebase). Se o usuário sair da
// tela no meio de uma delas, a tela descarta o controller e o notifyListeners()
// seguinte lançaria erro, interrompendo o restante da operação (ex: salvar).
class SafeChangeNotifier extends ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
