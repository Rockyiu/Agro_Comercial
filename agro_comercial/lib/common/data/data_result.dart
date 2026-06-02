// lib/common/models/data_result.dart

import 'package:agro_comercial/common/models/app_exception.dart';

class DataResult<T> {
  final T? _data;
  final AppException? _error;

  DataResult.success(this._data) : _error = null;
  DataResult.failure(this._error) : _data = null;

  // Método que decide se vai retornar os Dados (Home) ou o Erro (BottomSheet)
  void fold(
    Function(AppException error) onFailure,
    Function(T data) onSuccess,
  ) {
    if (_error != null) {
      onFailure(_error!);
    } else if (_data != null) {
      onSuccess(_data as T);
    }
  }
}
