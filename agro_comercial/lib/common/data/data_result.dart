// lib/common/data/data_result.dart

import 'package:agro_comercial/common/models/app_exception.dart';

class DataResult<T> {
  final T? _data;
  final AppException? _error;

  DataResult.success(T data) : _data = data, _error = null;
  DataResult.failure(AppException error) : _data = null, _error = error;

  // Decide se segue com os Dados (ex: Home) ou com o Erro (ex: BottomSheet).
  // Devolve o que o callback retornar, então também pode ser aguardado:
  // await result.fold((e) async {...}, (data) async {...});
  R fold<R>(
    R Function(AppException error) onFailure,
    R Function(T data) onSuccess,
  ) {
    final error = _error;
    if (error != null) return onFailure(error);
    return onSuccess(_data as T);
  }
}
