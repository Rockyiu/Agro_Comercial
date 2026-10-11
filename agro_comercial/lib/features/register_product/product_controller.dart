import 'package:agro_comercial/common/utils/safe_change_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:agro_comercial/common/models/photo_change.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/services/product_service/product_service.dart';
import 'product_state.dart';

// Cadastro, edição e exclusão de produtos do estoque
class ProductController extends SafeChangeNotifier {
  final ProductService _productService;
  final FarmController _farmController;

  ProductController(this._productService, this._farmController);

  ProductState _state = ProductInitialState();
  ProductState get state => _state;

  void _changeState(ProductState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> createProduct(ProductModel product, {PhotoChange? photo}) async {
    _changeState(ProductLoadingState());
    try {
      final activeFarmId = _farmController.selectedFarm?.id;
      if (activeFarmId == null) {
        _changeState(ProductErrorState("Erro: Nenhuma fazenda selecionada!"));
        return;
      }
      final newProduct = product.copyWith(farmId: activeFarmId);
      if (await _isDuplicate(newProduct)) return;

      await _productService.createProduct(newProduct, photo: photo);
      _changeState(ProductSuccessState());
    } catch (e) {
      debugPrint("Erro ao salvar produto: $e");
      _changeState(ProductErrorState("Erro ao salvar o produto."));
    }
  }

  // [quantityChanged]: o estoque foi alterado no formulário (ver
  // ProductService.updateProduct)
  Future<void> updateProduct(
    ProductModel product, {
    required bool quantityChanged,
    PhotoChange? photo,
  }) async {
    _changeState(ProductLoadingState());
    try {
      if (await _isDuplicate(product)) return;

      await _productService.updateProduct(
        product,
        updateQuantity: quantityChanged,
        photo: photo,
      );
      _changeState(ProductSuccessState());
    } catch (e) {
      debugPrint("Erro ao atualizar produto: $e");
      _changeState(ProductErrorState("Erro ao atualizar o produto."));
    }
  }

  // Bloqueia dois produtos com o mesmo nome e marca no mesmo armazém.
  // Se for duplicado, já muda o estado para erro com a explicação.
  Future<bool> _isDuplicate(ProductModel product) async {
    final duplicate = await _productService.checkDuplicateProduct(
      product.name,
      product.brand,
      farmId: product.farmId,
      warehouseId: product.warehouseId,
      ignoreId: product.id,
    );
    if (duplicate) {
      _changeState(
        ProductErrorState(
          'Já existe o produto "${product.name}" da marca "${product.brand}" neste armazém. Edite o produto existente para alterar a quantidade.',
        ),
      );
    }
    return duplicate;
  }

  Future<void> deleteProduct(String productId) async {
    _changeState(ProductLoadingState());
    try {
      await _productService.deleteProduct(productId);
      _changeState(ProductSuccessState());
    } catch (e) {
      debugPrint("Erro ao excluir produto: $e");
      _changeState(ProductErrorState("Erro ao excluir o produto."));
    }
  }
}
