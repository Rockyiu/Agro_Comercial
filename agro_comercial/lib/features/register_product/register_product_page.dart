import 'dart:io';
import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/product_model.dart';
import 'package:agro_comercial/common/models/warehouse_model.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:agro_comercial/common/widgets/primary_button.dart';
import 'package:agro_comercial/features/warehouse/warehouse_controller.dart';
import 'package:agro_comercial/features/warehouse/warehouse_state.dart';
import 'package:agro_comercial/services/product_service/product_service.dart';
import 'package:agro_comercial/locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class RegisterProductPage extends StatefulWidget {
  final WarehouseModel? initialWarehouse;
  const RegisterProductPage({super.key, this.initialWarehouse});

  @override
  State<RegisterProductPage> createState() => _RegisterProductPageState();
}

class _RegisterProductPageState extends State<RegisterProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _quantityController = TextEditingController();
  final _measureController = TextEditingController(); // ADICIONADO

  final _extra1Controller = TextEditingController();
  final _extra2Controller = TextEditingController();

  WarehouseModel? _selectedWarehouse;
  String? _selectedCategory;
  String _selectedUnit = 'un';
  File? _selectedImage;

  final List<String> _categories = [
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

  final List<String> _units = [
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
    _nameController.dispose();
    _brandController.dispose();
    _quantityController.dispose();
    _measureController.dispose();
    _extra1Controller.dispose();
    _extra2Controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tirar Foto (Câmera)'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? photo = await picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 70,
                );
                if (photo != null)
                  setState(() => _selectedImage = File(photo.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Escolher da Galeria'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 70,
                );
                if (image != null)
                  setState(() => _selectedImage = File(image.path));
              },
            ),
          ],
        ),
      ),
    );
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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.warehouse_outlined,
                      size: 80,
                      color: AppColors.lightkGrey,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Crie um armazém antes de cadastrar um produto!",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.midText20.copyWith(
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
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
                        color: AppColors.greenlightOne.withOpacity(0.1),
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
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextFormField(
                            controller: _measureController,
                            labelText: "MEDIDA",
                            hintText: "Ex: 1 ou 1000",
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.isEmpty ? "Obrigatório" : null,
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

                    if (_selectedCategory != null)
                      ..._buildCategorySpecificFields(),

                    const SizedBox(height: 32),
                    PrimaryButton(
                      text: "Salvar Produto",
                      onPressed: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          Map<String, dynamic> extraAttributes = {};

                          if (_extra1Controller.text.isNotEmpty) {
                            extraAttributes['campo_extra_1'] = _extra1Controller
                                .text
                                .trim();
                          }
                          if (_extra2Controller.text.isNotEmpty) {
                            extraAttributes['campo_extra_2'] = _extra2Controller
                                .text
                                .trim();
                          }

                          final newProduct = ProductModel(
                            name: _nameController.text.trim(),
                            brand: _brandController.text.trim(),
                            quantity:
                                double.tryParse(_quantityController.text) ??
                                0.0,
                            measure:
                                double.tryParse(_measureController.text) ??
                                1.0, // ADICIONADO
                            unit: _selectedUnit,
                            category: _selectedCategory!,
                            warehouseId: _selectedWarehouse!.id!,
                            farmId: FirebaseAuth.instance.currentUser!.uid,
                            attributes: extraAttributes,
                          );

                          await locator.get<ProductService>().createProduct(
                            newProduct,
                            _selectedImage,
                          );

                          if (!mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Produto estocado com sucesso!"),
                              backgroundColor: AppColors.greenlightOne,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
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
