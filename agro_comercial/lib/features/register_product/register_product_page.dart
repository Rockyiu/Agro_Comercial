import 'dart:io';
import 'package:agro_comercial/common/widgets/image_source_picker.dart';
import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/common/utils/parsers.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:agro_comercial/common/widgets/loading_overlay.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/features/warehouse/warehouse_controller.dart';
import 'package:agro_comercial/features/warehouse/warehouse_state.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'product_controller.dart';
import 'product_state.dart';

class RegisterProductPage extends StatefulWidget {
  final WarehouseModel? initialWarehouse;
  const RegisterProductPage({super.key, this.initialWarehouse});

  @override
  State<RegisterProductPage> createState() => _RegisterProductPageState();
}

class _RegisterProductPageState extends State<RegisterProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _controller = locator.get<ProductController>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController();
  final _measureController = TextEditingController();
  final _priceController = TextEditingController();

  final _extra1Controller = TextEditingController();
  final _extra2Controller = TextEditingController();

  WarehouseModel? _selectedWarehouse;
  String? _selectedCategory;
  String _selectedUnit = 'un';
  File? _selectedImage;

  static const List<String> _categories = [
    'Adubo',
    'Bioestimulante',
    'Herbicida',
    'Inseticida',
    'Fungicida',
    'Ração',
    'Peças',
    'Lubrificante',
    'Combustível',
    'Ferramentas',
    'Implementos',
    'Remédios',
    'Vacinas',
    'Itens diversos',
  ];

  static const List<String> _units = [
    'un',
    'kg',
    'L',
    'ml',
    'mg',
    'm',
    'saco',
    'tambor',
  ];

  @override
  void initState() {
    super.initState();
    _selectedWarehouse = widget.initialWarehouse;
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _measureController.dispose();
    _priceController.dispose();
    _extra1Controller.dispose();
    _extra2Controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await showImageSourcePicker(
      context,
      cameraLabel: 'Tirar Foto (Câmera)',
      galleryLabel: 'Escolher da Galeria',
    );
    if (image != null && mounted) setState(() => _selectedImage = image);
  }

  @override
  Widget build(BuildContext context) {
    final warehouseState = locator.get<WarehouseController>().state;
    final List<WarehouseModel> availableWarehouses =
        warehouseState is WarehouseSuccessState
        ? warehouseState.warehouses
        : [];
    final bool noWarehousesAvailable =
        availableWarehouses.isEmpty && widget.initialWarehouse == null;

    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Cadastrar Produto",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: noWarehousesAvailable
          ? const Center(
              child: EmptyState(
                icon: Icons.warehouse_outlined,
                title: "Nenhum armazém",
                message: "Crie um armazém antes de cadastrar um produto!",
              ),
            )
          : ListenableBuilder(
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
                      Center(
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              height: 110,
                              width: 110,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.greenlightOne,
                                  width: 2,
                                ),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(55),
                                      child: Image.file(
                                        _selectedImage!,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.inventory_2_outlined,
                                      size: 50,
                                      color: AppColors.lightkGrey,
                                    ),
                            ),
                            CircleAvatar(
                              backgroundColor: AppColors.greenlightOne,
                              radius: 18,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                onPressed: _pickImage,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (widget.initialWarehouse == null)
                        DropdownButtonFormField<WarehouseModel>(
                          decoration: const InputDecoration(
                            labelText: "SELECIONE O ARMAZÉM",
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.greenlightOne,
                              ),
                            ),
                          ),
                          initialValue: _selectedWarehouse,
                          items: availableWarehouses
                              .map(
                                (w) => DropdownMenuItem(
                                  value: w,
                                  child: Text(w.name),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedWarehouse = v),
                          validator: (v) => v == null ? "Obrigatório" : null,
                        )
                      else
                        Card(
                          color: AppColors.greenlightOne.withValues(alpha: 0.1),
                          child: ListTile(
                            leading: const Icon(
                              Icons.warehouse,
                              color: AppColors.greenlightOne,
                            ),
                            title: Text(
                              "Armazenar em: ${widget.initialWarehouse!.name}",
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: "CATEGORIA DO INSUMO/PRODUTO",
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: AppColors.greenlightOne,
                            ),
                          ),
                        ),
                        initialValue: _selectedCategory,
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _selectedCategory = v;
                          _extra1Controller.clear();
                          _extra2Controller.clear();
                        }),
                        validator: (v) =>
                            v == null ? "Selecione uma categoria" : null,
                      ),
                      const SizedBox(height: 16),

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

                      // ATUALIZADO: Linha de 3 Colunas com Quantidade, Medida e Unidade
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextFormField(
                              controller: _quantityController,
                              labelText: "QUANTIDADE",
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) =>
                                  v!.isEmpty ? "Obrigatório" : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextFormField(
                              controller: _measureController,
                              labelText: "MEDIDA",
                              hintText: "Ex: 1 ou 1000",
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) =>
                                  v!.isEmpty ? "Obrigatório" : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "UNIDADE",
                                border: OutlineInputBorder(),
                              ),
                              initialValue: _selectedUnit,
                              items: _units
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedUnit = v!),
                            ),
                          ),
                        ],
                      ),

                      CustomTextFormField(
                        controller: _priceController,
                        labelText: "PREÇO POR $_selectedUnit (R\$) - opcional",
                        hintText: "Usado no custo por talhão",
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: Validator.validateOptionalDecimal,
                      ),

                      if (_selectedCategory != null)
                        ..._buildCategorySpecificFields(),

                      const SizedBox(height: 32),
                      PrimaryButton(text: "Salvar Produto", onPressed: _save),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final extraAttributes = <String, dynamic>{
      if (_extra1Controller.text.isNotEmpty)
        'campo_extra_1': _extra1Controller.text.trim(),
      if (_extra2Controller.text.isNotEmpty)
        'campo_extra_2': _extra2Controller.text.trim(),
    };

    // A fazenda ativa é definida pelo controller
    final newProduct = ProductModel(
      name: _nameController.text.trim(),
      brand: _brandController.text.trim(),
      quantity: Parsers.decimal(_quantityController.text) ?? 0.0,
      measure: Parsers.decimal(_measureController.text) ?? 1.0,
      unit: _selectedUnit,
      category: _selectedCategory!,
      warehouseId: _selectedWarehouse!.id!,
      farmId: '',
      attributes: extraAttributes,
      unitPrice: Parsers.decimal(_priceController.text),
    );

    await _controller.createProduct(newProduct, _selectedImage);
    if (!mounted) return;

    final state = _controller.state;
    if (state is ProductErrorState) {
      context.showErrorSnackBar(state.message);
      return;
    }
    // Mostra o aviso na tela anterior, depois de fechar esta
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text("Produto estocado com sucesso!"),
        backgroundColor: AppColors.greenlightOne,
      ),
    );
  }

  List<Widget> _buildCategorySpecificFields() {
    if ([
      'Herbicida',
      'Inseticida',
      'Fungicida',
      'Adubo',
      'Bioestimulante',
    ].contains(_selectedCategory)) {
      return [
        CustomTextFormField(
          controller: _extra1Controller,
          labelText: "PRINCÍPIO ATIVO / COMPOSIÇÃO",
          hintText: "Ex: Glifosato, NPK 04-14-08",
        ),
        CustomTextFormField(
          controller: _extra2Controller,
          labelText: "DOSAGEM RECOMENDADA (Opcional)",
          hintText: "Ex: 2L por Hectare",
        ),
      ];
    }
    if (['Remédios', 'Vacinas', 'Ração'].contains(_selectedCategory)) {
      return [
        CustomTextFormField(
          controller: _extra1Controller,
          labelText: "DATA DE VALIDADE",
          hintText: "Ex: 12/2027",
          keyboardType: TextInputType.datetime,
        ),
        CustomTextFormField(
          controller: _extra2Controller,
          labelText: "LOTE DE FABRICAÇÃO",
          hintText: "Ex: LOTE99X",
        ),
      ];
    }
    if (['Peças', 'Ferramentas', 'Implementos'].contains(_selectedCategory)) {
      return [
        CustomTextFormField(
          controller: _extra1Controller,
          labelText: "CÓDIGO DA PEÇA / N° SÉRIE",
          hintText: "Ex: REF-88391-JD",
        ),
      ];
    }
    if (['Combustível', 'Lubrificante'].contains(_selectedCategory)) {
      return [
        CustomTextFormField(
          controller: _extra1Controller,
          labelText: "ESPECIFICAÇÃO / TIPO",
          hintText: "Ex: Diesel S10, Óleo 15W40 SAE",
        ),
      ];
    }
    return [
      CustomTextFormField(
        controller: _extra1Controller,
        labelText: "OBSERVAÇÕES ADICIONAIS",
        hintText: "Qualquer detalhe extra sobre o lote",
      ),
    ];
  }
}
