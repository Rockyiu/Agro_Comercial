import 'package:agro_comercial/common/models/photo_change.dart';
import 'package:agro_comercial/common/widgets/local_photo.dart';
import 'package:agro_comercial/services/local_media_service/local_media_service.dart';
import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/common/utils/parsers.dart';
import 'package:agro_comercial/common/utils/validator.dart';
import 'package:agro_comercial/common/widgets/app_snack_bar.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
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
  PhotoChange? _photo;
  final _warehouseController = locator.get<WarehouseController>();

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
    // A lista de armazéns vem da aba Armazém; se ela ainda não foi aberta,
    // carrega aqui
    if (widget.initialWarehouse == null &&
        _warehouseController.state is! WarehouseSuccessState) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _warehouseController.loadWarehouseData(),
      );
    }
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

  @override
  Widget build(BuildContext context) {
    // Reconstrói quando a lista de armazéns termina de carregar
    return ListenableBuilder(
      listenable: _warehouseController,
      builder: (context, _) => _buildPage(),
    );
  }

  Widget _buildPage() {
    final warehouseState = _warehouseController.state;
    final List<WarehouseModel> availableWarehouses =
        warehouseState is WarehouseSuccessState
        ? warehouseState.warehouses
        : [];
    final loadingWarehouses =
        widget.initialWarehouse == null &&
        (warehouseState is WarehouseLoadingState ||
            warehouseState is WarehouseInitialState);
    final bool noWarehousesAvailable =
        availableWarehouses.isEmpty && widget.initialWarehouse == null;

    return Scaffold(
      appBar: AppBar(title: const Text("Cadastrar Produto")),
      body: loadingWarehouses
          ? const CustomCircularProgressIndicator()
          : noWarehousesAvailable
          ? const Center(
              child: EmptyState(
                icon: Icons.warehouse_rounded,
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
                      PhotoEditor(
                        kind: MediaKind.product,
                        id: null,
                        change: _photo,
                        onChanged: (change) => setState(() => _photo = change),
                        icon: Icons.inventory_2_rounded,
                        circle: false,
                      ),
                      const SizedBox(height: 24),

                      if (widget.initialWarehouse == null)
                        DropdownButtonFormField<WarehouseModel>(
                          decoration: const InputDecoration(
                            labelText: "Selecione o armazém",
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
                              Icons.warehouse_rounded,
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
                          labelText: "Categoria do insumo/produto",
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
                        labelText: "Nome do produto",
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? "Obrigatório" : null,
                      ),
                      CustomTextFormField(
                        controller: _brandController,
                        labelText: "Marca / fabricante",
                        validator: (v) =>
                            (v ?? '').trim().isEmpty ? "Obrigatório" : null,
                      ),

                      // ATUALIZADO: Linha de 3 Colunas com Quantidade, Medida e Unidade
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextFormField(
                              controller: _quantityController,
                              labelText: "Quantidade",
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: Validator.validateNonNegativeDecimal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CustomTextFormField(
                              controller: _measureController,
                              labelText: "Medida",
                              hintText: "Ex: 1 ou 1000",
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: Validator.validatePositiveDecimal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: "Unidade",
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
                        labelText: "Preço por $_selectedUnit (R\$) - opcional",
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

    await _controller.createProduct(newProduct, photo: _photo);
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
          labelText: "Princípio ativo / composição",
          hintText: "Ex: Glifosato, NPK 04-14-08",
        ),
        CustomTextFormField(
          controller: _extra2Controller,
          labelText: "Dosagem recomendada (Opcional)",
          hintText: "Ex: 2L por Hectare",
        ),
      ];
    }
    if (['Remédios', 'Vacinas', 'Ração'].contains(_selectedCategory)) {
      return [
        CustomTextFormField(
          controller: _extra1Controller,
          labelText: "Data de validade",
          hintText: "Ex: 12/2027",
          keyboardType: TextInputType.datetime,
        ),
        CustomTextFormField(
          controller: _extra2Controller,
          labelText: "Lote de fabricação",
          hintText: "Ex: LOTE99X",
        ),
      ];
    }
    if (['Peças', 'Ferramentas', 'Implementos'].contains(_selectedCategory)) {
      return [
        CustomTextFormField(
          controller: _extra1Controller,
          labelText: "Código da peça / N° série",
          hintText: "Ex: REF-88391-JD",
        ),
      ];
    }
    if (['Combustível', 'Lubrificante'].contains(_selectedCategory)) {
      return [
        CustomTextFormField(
          controller: _extra1Controller,
          labelText: "Especificação / tipo",
          hintText: "Ex: Diesel S10, Óleo 15W40 SAE",
        ),
      ];
    }
    return [
      CustomTextFormField(
        controller: _extra1Controller,
        labelText: "Observações adicionais",
        hintText: "Qualquer detalhe extra sobre o lote",
      ),
    ];
  }
}
