import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/machine_cost_data.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/utils/parsers.dart';
import 'package:agro_comercial/common/widgets/custom_text_form_field.dart';
import 'package:flutter/material.dart';

// Campos de texto do bloco "Custo da hora-máquina". A tela que usa o bloco
// cria, lê ([toCostData]) e descarta ([dispose]) estes controllers.
class MachineCostControllers {
  final acquisitionValue = TextEditingController();
  final scrapPercent = TextEditingController();
  final usefulLifeHours = TextEditingController();
  final maintenancePercent = TextEditingController();
  final marketValue = TextEditingController();
  final insuranceRate = TextEditingController();
  final interestRate = TextEditingController();
  final fuelConsumption = TextEditingController();
  int? acquisitionDate;
  bool fullyDepreciated = false;

  MachineCostControllers([MachineCostData? data]) {
    if (data == null) return;
    String text(double? value) =>
        value == null ? '' : Formatters.editable(value);
    acquisitionValue.text = text(data.acquisitionValue);
    scrapPercent.text = text(data.scrapPercent);
    usefulLifeHours.text = text(data.usefulLifeHours);
    maintenancePercent.text = text(data.maintenancePercent);
    marketValue.text = text(data.marketValue);
    insuranceRate.text = text(data.insuranceRate);
    interestRate.text = text(data.interestRate);
    fuelConsumption.text = text(data.fuelConsumption);
    acquisitionDate = data.acquisitionDate;
    fullyDepreciated = data.fullyDepreciated;
  }

  List<TextEditingController> get _all => [
    acquisitionValue,
    scrapPercent,
    usefulLifeHours,
    maintenancePercent,
    marketValue,
    insuranceRate,
    interestRate,
    fuelConsumption,
  ];

  bool get isEmpty =>
      _all.every((c) => c.text.trim().isEmpty) && acquisitionDate == null;

  // Null quando nada foi preenchido (máquina sem dados de custo)
  MachineCostData? toCostData() {
    if (isEmpty && !fullyDepreciated) return null;
    return MachineCostData(
      acquisitionValue: Parsers.decimal(acquisitionValue.text),
      acquisitionDate: acquisitionDate,
      scrapPercent: Parsers.decimal(scrapPercent.text),
      usefulLifeHours: Parsers.decimal(usefulLifeHours.text),
      maintenancePercent: Parsers.decimal(maintenancePercent.text),
      marketValue: Parsers.decimal(marketValue.text),
      insuranceRate: Parsers.decimal(insuranceRate.text),
      interestRate: Parsers.decimal(interestRate.text),
      fuelConsumption: Parsers.decimal(fuelConsumption.text),
      fullyDepreciated: fullyDepreciated,
    );
  }

  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
  }
}

// Bloco recolhível com os dados da planilha de custo da hora-máquina
class MachineCostFields extends StatefulWidget {
  final MachineCostControllers controllers;
  final bool isMotorized;

  const MachineCostFields({
    super.key,
    required this.controllers,
    required this.isMotorized,
  });

  @override
  State<MachineCostFields> createState() => _MachineCostFieldsState();
}

class _MachineCostFieldsState extends State<MachineCostFields> {
  MachineCostControllers get _c => widget.controllers;

  @override
  void initState() {
    super.initState();
    for (final controller in _c._all) {
      controller.addListener(_refreshPreview);
    }
  }

  @override
  void dispose() {
    for (final controller in _c._all) {
      controller.removeListener(_refreshPreview);
    }
    super.dispose();
  }

  void _refreshPreview() => setState(() {});

  Future<void> _pickAcquisitionDate() async {
    final initial = _c.acquisitionDate != null
        ? DateTime.fromMillisecondsSinceEpoch(_c.acquisitionDate!)
        : DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1970),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _c.acquisitionDate = picked.millisecondsSinceEpoch);
    }
  }

  Widget _numberField(
    TextEditingController controller,
    String label, {
    String? hint,
  }) {
    return CustomTextFormField(
      controller: controller,
      labelText: label,
      hintText: hint,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.trim().isEmpty) return null;
        return Parsers.decimal(v) == null ? "Número inválido" : null;
      },
    );
  }

  Widget _row(Widget a, Widget b) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        Expanded(child: b),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _c.toCostData();
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.black12),
      ),
      child: ExpansionTile(
        initiallyExpanded: !_c.isEmpty,
        shape: const Border(),
        leading: const Icon(Icons.calculate, color: AppColors.greenlightOne),
        title: Text(
          "Custo da hora-máquina",
          style: AppTextStyles.inputText.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Usado nos relatórios de custo por talhão (opcional)",
          style: AppTextStyles.smallText.copyWith(fontSize: 12),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 12),
        children: [
          _row(
            _numberField(
              _c.acquisitionValue,
              "Valor de aquisição (R\$)",
              hint: "Ex: 650000",
            ),
            _numberField(_c.marketValue, "Valor atual (R\$)"),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton.icon(
              onPressed: _pickAcquisitionDate,
              icon: const Icon(Icons.event, color: AppColors.greenlightOne),
              label: Text(
                _c.acquisitionDate == null
                    ? "Data da aquisição (opcional)"
                    : "Aquisição: ${Formatters.date(_c.acquisitionDate!)}",
                style: const TextStyle(color: AppColors.greenlightOne),
              ),
            ),
          ),
          _row(
            _numberField(_c.scrapPercent, "Sucata (% V.I.)", hint: "Ex: 20"),
            _numberField(
              _c.usefulLifeHours,
              "Vida útil (horas)",
              hint: "Ex: 10000",
            ),
          ),
          _row(
            _numberField(
              _c.maintenancePercent,
              "Manutenção (% V.I.)",
              hint: "Ex: 100",
            ),
            _numberField(
              _c.fuelConsumption,
              "Diesel (L/hora)",
              hint: widget.isMotorized ? "Ex: 22" : "0 p/ implemento",
            ),
          ),
          _row(
            _numberField(_c.insuranceRate, "Seguro (% a.a.)", hint: "Ex: 1,2"),
            _numberField(_c.interestRate, "Juros (% a.a.)", hint: "Ex: 8"),
          ),
          CheckboxListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            activeColor: AppColors.greenlightOne,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text("Bem já totalmente depreciado"),
            subtitle: const Text("Zera a depreciação por hora"),
            value: _c.fullyDepreciated,
            onChanged: (v) => setState(() => _c.fullyDepreciated = v ?? false),
          ),
          if (data != null && data.isComplete) _buildPreview(data),
        ],
      ),
    );
  }

  // Mostra o resultado do cálculo enquanto o usuário digita
  Widget _buildPreview(MachineCostData data) {
    Widget line(String label, String value, {bool bold = false}) {
      final style = AppTextStyles.smallText.copyWith(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: bold ? AppColors.greenlightOne : AppColors.grey,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            Text(value, style: style),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.greenlightOne.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          line(
            "Depreciação por hora",
            Formatters.currency(data.depreciationPerHour),
          ),
          line(
            "Manutenção por hora",
            Formatters.currency(data.maintenancePerHour),
          ),
          line(
            "Total por hora (sem diesel)",
            Formatters.currency(data.fixedCostPerHour),
            bold: true,
          ),
          line(
            "Juros + seguro por ano",
            Formatters.currency(data.annualInterestAndInsurance),
          ),
        ],
      ),
    );
  }
}
