import 'dart:io';
import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/services/product_service/product_service.dart';
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
  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _quantityController;
  late TextEditingController _extra1Controller;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _brandController = TextEditingController(text: widget.product.brand);
    _quantityController = TextEditingController(
      text: widget.product.quantity.toString(),
    );

    // Recupera o valor salvo no mapa dinâmico se houver
    final extraVal =
        widget.product.attributes['campo_extra_1'] ??
        widget.product.attributes['campo_extra_2'] ??
        '';
    _extra1Controller = TextEditingController(text: extraVal);
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
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Excluir Item"),
                  content: const Text(
                    "Deseja realmente apagar este produto do seu estoque?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancelar"),
                    ),
                    TextButton(
                      onPressed: () async {
                        await locator.get<ProductService>().deleteProduct(
                          widget.product.id!,
                        );
                        Navigator.pop(context); // Fecha o modal
                        Navigator.pop(context); // Volta da tela de edição
                      },
                      child: const Text(
                        "Excluir",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: Icon(
                  Icons.inventory_2,
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
              const SizedBox(height: 24),
              CustomTextFormField(
                controller: _nameController,
                labelText: "NOME DO PRODUTO",
                validator: (v) => v!.isEmpty ? "Obrigatório" : null,
              ),
              CustomTextFormField(
                controller: _brandController,
                labelText: "MARCA / FABRICANTE",
                validator: (v) => v!.isEmpty ? "Obrigatório" : null,
              ),
              CustomTextFormField(
                controller: _quantityController,
                labelText: "QUANTIDADE EM ESTOQUE",
                keyboardType: TextInputType.number,
                validator: (v) => v!.isEmpty ? "Obrigatório" : null,
              ),

              if (widget.product.attributes.isNotEmpty)
                CustomTextFormField(
                  controller: _extra1Controller,
                  labelText: "ESPECIFICAÇÕES TÉCNICAS",
                ),

              const SizedBox(height: 32),
              PrimaryButton(
                text: "Salvar Alterações",
                onPressed: () async {
                  if (_formKey.currentState?.validate() ?? false) {
                    Map<String, dynamic> updatedAttrs = Map.from(
                      widget.product.attributes,
                    );
                    if (updatedAttrs.containsKey('campo_extra_1'))
                      updatedAttrs['campo_extra_1'] = _extra1Controller.text;

                    final updatedProduct = ProductModel(
                      id: widget.product.id,
                      name: _nameController.text.trim(),
                      brand: _brandController.text.trim(),
                      quantity:
                          double.tryParse(_quantityController.text) ?? 0.0,
                      unit: widget.product.unit,
                      category: widget.product.category,
                      warehouseId: widget.product.warehouseId,
                      farmId: widget.product.farmId,
                      attributes: updatedAttrs,
                    );

                    await locator.get<ProductService>().updateProduct(
                      updatedProduct,
                      null,
                    );
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
