import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/widgets/animations.dart';
import 'package:agro_comercial/common/widgets/brand.dart';
import 'package:agro_comercial/common/widgets/empty_state.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/locator.dart';
import 'package:agro_comercial/common/utils/formatters.dart';
import 'package:agro_comercial/features/profile/profile_controller.dart';
import 'package:agro_comercial/features/profile/profile_state.dart';
import 'package:flutter/material.dart';

class TaxpayerIdentificationPage extends StatefulWidget {
  const TaxpayerIdentificationPage({super.key});

  @override
  State<TaxpayerIdentificationPage> createState() =>
      _TaxpayerIdentificationPageState();
}

class _TaxpayerIdentificationPageState
    extends State<TaxpayerIdentificationPage> {
  final _farmController = locator.get<FarmController>();
  final _profileController = locator.get<ProfileController>();

  // Variáveis de estado para guardar nome e CPF na tela
  String _userName = "Carregando...";
  String _userCpf = "Carregando...";

  @override
  void initState() {
    super.initState();
    // Garante que a lista de fazendas e o CPF sejam carregados ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _farmController.loadFarms();
      _loadUserCpf();
    });
  }

  @override
  void dispose() {
    _profileController.dispose();
    super.dispose();
  }

  // Busca nome e CPF do produtor logado
  Future<void> _loadUserCpf() async {
    await _profileController.loadProfile();
    if (!mounted) return;

    final state = _profileController.state;
    setState(() {
      if (state is ProfileSuccessState) {
        final name = state.profile.name;
        final cpf = state.profile.cpf;
        _userName = (name == null || name.isEmpty)
            ? "Nome não informado"
            : name;
        // Devolve a máscara (pontos e traço) que tiramos no cadastro
        _userCpf = (cpf == null || cpf.isEmpty)
            ? "CPF não cadastrado"
            : Formatters.cpf(cpf);
      } else {
        _userName = "Erro ao carregar";
        _userCpf = "Erro ao buscar CPF";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Identificação do Contribuinte")),
      body: ListenableBuilder(
        listenable: _farmController,
        builder: (context, child) {
          final farms = _farmController.farms;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // --- 1. DADOS DO CONTRIBUINTE (NOME E CPF) ---
              const SectionHeader(
                title: "Dados do Produtor Rural",
                subtitle: "Titular do Livro Caixa",
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                child: _InfoCard(
                  icon: Icons.badge_rounded,
                  color: AppColors.sky,
                  background: AppColors.skySoft,
                  rows: [("Nome Completo", _userName), ("CPF", _userCpf)],
                ),
              ),
              const SizedBox(height: 28),

              // --- 2. DADOS DOS IMÓVEIS RURAIS ---
              SectionHeader(
                title: "Imóveis Rurais Explorados",
                subtitle: farms.length == 1
                    ? "1 propriedade"
                    : "${farms.length} propriedades",
              ),
              const SizedBox(height: 12),

              if (farms.isEmpty)
                const EmptyState(
                  icon: Icons.landscape_rounded,
                  title: "Nenhuma propriedade",
                  message: "Nenhuma propriedade rural cadastrada.",
                )
              else
                for (var i = 0; i < farms.length; i++)
                  FadeSlideIn(
                    index: i + 1,
                    child: _InfoCard(
                      icon: Icons.landscape_rounded,
                      color: AppColors.primary,
                      background: AppColors.primarySoft,
                      label: "Fazenda ${i + 1}",
                      rows: [
                        ("Nome da Propriedade", farms[i].name),
                        ("Inscrição Estadual (CAD/PRO)", farms[i].cadPro),
                        ("Endereço", farms[i].address),
                        ("Área Total", farms[i].totalAreaLabel),
                      ],
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}

// Cartão com ícone e uma lista de "rótulo: valor"
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String? label;
  final List<(String, String)> rows;

  const _InfoCard({
    required this.icon,
    required this.color,
    required this.background,
    required this.rows,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color, background: background),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null) ...[
                  StatusChip(
                    label: label!,
                    color: color,
                    background: background,
                  ),
                  const SizedBox(height: 10),
                ],
                for (var i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 20),
                  Text(
                    rows[i].$1,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rows[i].$2.isNotEmpty ? rows[i].$2 : "Não preenchido",
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
