import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/utils/parsers.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/confirm_dialog.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/loading_overlay.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/features/register_product/product_controller.dart';
import 'package:agro_comercial/features/register_product/product_state.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

class EditProductPage extends StatefulWidget {
  final ProductModel product;
  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = locator.get<ProductController>();
  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late final TextEditingController _extraController;

  // Campo de especificação que está sendo exibido/editado
  // (produtos antigos podem ter só o 'campo_extra_2')
  late final String _extraKey;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _nameController = TextEditingController(text: product.name);
    _brandController = TextEditingController(text: product.brand);
    _quantityController = TextEditingController(
      text: product.quantity.toString(),
    );
    _priceController = TextEditingController(
      text: product.unitPrice == null
          ? ''
          : Formatters.editable(product.unitPrice!),
    );

    _extraKey = product.attributes.containsKey('campo_extra_1')
        ? 'campo_extra_1'
        : 'campo_extra_2';
    _extraController = TextEditingController(
      text: product.attributes[_extraKey]?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _extraController.dispose();
    super.dispose();
  }

  // Executa a ação no controller; se der certo, fecha a tela
  Future<void> _runAndClose(Future<void> Function() action) async {
    await action();
    if (!mounted) return;
    final state = _controller.state;
    if (state is ProductErrorState) {
      context.showErrorSnackBar(state.message);
      return;
    }
    Navigator.pop(context);
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Excluir Item",
      message: "Deseja realmente apagar este produto do seu estoque?",
    );
    if (!confirmed) return;
    await _runAndClose(() => _controller.deleteProduct(widget.product.id!));
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final attributes = Map<String, dynamic>.from(widget.product.attributes);
    if (attributes.containsKey(_extraKey)) {
      attributes[_extraKey] = _extraController.text.trim();
    }

    // Construído sem copyWith para permitir apagar o preço (null)
    final product = widget.product;
    final updatedProduct = ProductModel(
      id: product.id,
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      quantity: Parsers.decimal(_quantityController.text) ?? 0.0,
      measure: product.measure,
      unit: product.unit,
      category: product.category,
      warehouseId: product.warehouseId,
      farmId: product.farmId,
      imageUrl: product.imageUrl,
      attributes: attributes,
      unitPrice: Parsers.decimal(_priceController.text),
    );
    await _runAndClose(() => _controller.updateProduct(updatedProduct));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Detalhes do Produto",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_rounded, color: AppColors.danger),
            onPressed: _delete,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) => LoadingOverlay(
          isLoading: _controller.state is ProductLoadingState,
          child: child!,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Icon(
                    Icons.inventory_2_rounded,
                    size: 70,
                    color: AppColors.greenlightOne,
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    widget.product.category,
                    style: AppTextStyles.smallText.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Texto informativo exibindo a medida da embalagem
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.greenlightOne.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "Medida por Embalagem: ${widget.product.measure} ${widget.product.unit}",
                      style: AppTextStyles.smallText.copyWith(
                        color: AppColors.greenlightOne,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextFormField(
                  controller: _nameController,
                  labelText: "Nome do produto",
                  validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                ),
                CustomTextFormField(
                  controller: _brandController,
                  labelText: "Marca / fabricante",
                  validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                ),
                CustomTextFormField(
                  controller: _quantityController,
                  labelText: "Quantidade em estoque (Embalagens)",
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                ),
                CustomTextFormField(
                  controller: _priceController,
                  labelText: "Preço por ${widget.product.unit} (R\$)",
                  hintText: "Usado no custo por talhão",
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: Validator.validateOptionalDecimal,
                ),

                if (widget.product.attributes.isNotEmpty)
                  CustomTextFormField(
                    controller: _extraController,
                    labelText: "Especificações técnicas",
                  ),

                const SizedBox(height: 32),
                PrimaryButton(text: "Salvar Alterações", onPressed: _save),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
