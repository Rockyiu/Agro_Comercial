import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/models/harvest_model.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:agro_comercial/locator.dart';
import 'package:flutter/material.dart';

import 'harvest_controller.dart';
import 'harvest_state.dart';
import 'register_harvest_page.dart';

// Lista da produção colhida na fazenda ativa
class HarvestPage extends StatefulWidget {
  // true para o colaborador: lista só o que ele registrou
  final bool onlyMine;

  const HarvestPage({super.key, this.onlyMine = false});

  @override
  State<HarvestPage> createState() => _HarvestPageState();
}

class _HarvestPageState extends State<HarvestPage> {
  late final _controller = locator.get<HarvestController>()
    ..onlyMine = widget.onlyMine;

  @override
  void initState() {
    super.initState();
    _controller.loadHarvests();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openForm([HarvestModel? harvest]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterHarvestPage(harvestToEdit: harvest),
      ),
    );
    _controller.loadHarvests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          widget.onlyMine ? "Minhas Colheitas" : "Produção / Colheita",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          final state = _controller.state;
          if (state is HarvestErrorState) {
            return Center(
              child: EmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Algo deu errado',
                message: state.message,
              ),
            );
          }
          if (state is! HarvestSuccessState) {
            return const Center(child: CustomCircularProgressIndicator());
          }
          if (state.harvests.isEmpty) {
            return const Center(
              child: EmptyState(
                icon: Icons.grass_rounded,
                title: 'Nenhuma colheita registrada',
                message:
                    'Registre a produção de cada talhão para calcular receita, margem e custo por saca nos relatórios.',
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.greenlightOne,
            onRefresh: _controller.loadHarvests,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: state.harvests.length,
              itemBuilder: (context, index) =>
                  _buildHarvestCard(state.harvests[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildHarvestCard(HarvestModel harvest) {
    final title = harvest.crop.isEmpty
        ? harvest.plotName
        : "${harvest.plotName} • ${harvest.crop}";
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        onTap: () => _openForm(harvest),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: AppColors.greenlightOne.withValues(alpha: 0.1),
          child: const Icon(
            Icons.grass_rounded,
            color: AppColors.greenlightOne,
          ),
        ),
        title: Text(
          title,
          style: AppTextStyles.smallText.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${Formatters.date(harvest.dateTimestamp)}\n"
          "${Formatters.decimal(harvest.quantity)} ${harvest.unit} x "
          "${Formatters.currency(harvest.unitPrice)}",
          style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
        ),
        isThreeLine: true,
        trailing: Text(
          Formatters.currency(harvest.revenue),
          style: AppTextStyles.smallText.copyWith(
            color: AppColors.greenlightOne,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
