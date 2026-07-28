import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/features/farm/farm_controller.dart';
import 'package:agro_comercial/locator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ADICIONADO: Importação do banco de dados
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
  final _currentUser = FirebaseAuth.instance.currentUser;

  // Variável de estado para guardar o CPF na tela
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

  // Busca o CPF lá no documento do usuário no Firestore
  Future<void> _loadUserCpf() async {
    if (_currentUser == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users') // Verifica se a sua coleção chama 'users' mesmo
          .doc(_currentUser!.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        String cpfSalvo = doc.data()!['cpf'] ?? "CPF não cadastrado";

        if (mounted) {
          setState(() {
            _userCpf = _formatarCpf(cpfSalvo);
          });
        }
      } else {
        if (mounted) setState(() => _userCpf = "Documento não encontrado");
      }
    } catch (e) {
      if (mounted) setState(() => _userCpf = "Erro ao buscar CPF");
    }
  }

  // Devolve a máscara (pontos e traço) que havíamos tirado no SignUp
  String _formatarCpf(String cpf) {
    String numeros = cpf.replaceAll(RegExp(r'[^0-9]'), '');
    if (numeros.length == 11) {
      return "${numeros.substring(0, 3)}.${numeros.substring(3, 6)}.${numeros.substring(6, 9)}-${numeros.substring(9, 11)}";
    }
    return cpf;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Identificação do Contribuinte",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _farmController,
        builder: (context, child) {
          final farms = _farmController.farms;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- 1. DADOS DO CONTRIBUINTE (NOME E CPF) ---
                _buildSectionTitle("Dados do Produtor Rural", Icons.person),
                const SizedBox(height: 12),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          "Nome Completo",
                          _currentUser?.displayName ?? "Nome não informado",
                        ),
                        const Divider(height: 24),
                        // O CPF AGORA É PUXADO DA NOSSA VARIÁVEL DINÂMICA
                        _buildInfoRow("CPF", _userCpf),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // --- 2. DADOS DOS IMÓVEIS RURAIS ---
                _buildSectionTitle(
                  "Imóveis Rurais Explorados",
                  Icons.landscape,
                ),
                const SizedBox(height: 12),

                if (farms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      "Nenhuma propriedade rural cadastrada.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.inputText.copyWith(
                        color: AppColors.lightkGrey,
                      ),
                    ),
                  )
                else
                  ...List.generate(farms.length, (index) {
                    final farm = farms[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            color: AppColors.greenlightOne,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Fazenda ${index + 1}",
                                style: AppTextStyles.smallText.copyWith(
                                  color: AppColors.greenlightOne,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildInfoRow("Nome da Propriedade", farm.name),
                              const Divider(height: 16),
                              _buildInfoRow(
                                "Inscrição Estadual (CAD/PRO)",
                                farm.cadPro,
                              ),
                              const Divider(height: 16),
                              _buildInfoRow("Endereço", farm.address),
                              const Divider(height: 16),
                              _buildInfoRow(
                                "Área Total",
                                "${farm.totalArea} (Alqueires/Hectares)",
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.greenlightOne),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.midText20.copyWith(
            color: AppColors.greenlightOne,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.smallText.copyWith(
            color: AppColors.lightkGrey,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isNotEmpty ? value : "Não preenchido",
          style: AppTextStyles.inputText.copyWith(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
