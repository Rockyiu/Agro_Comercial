import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:agro_comercial/common/constants/app_colors.dart';
import 'package:agro_comercial/common/constants/app_text_styles.dart';
import 'package:agro_comercial/common/widgets/custom_circular_progress_indicator.dart';
import 'package:agro_comercial/locator.dart';

import 'invoice_controller.dart';
import 'invoice_state.dart';

class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  State<InvoicePage> createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final _invoiceController = locator.get<InvoiceController>();

  @override
  void initState() {
    super.initState();
    // Assim que a tela abre, busca as notas do banco local (SQLite)
    _invoiceController.loadInvoices();
  }

  // Formata a data para um padrão amigável do Brasil
  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.iceWhite,
      appBar: AppBar(
        title: Text(
          "Notas Fiscais",
          style: AppTextStyles.midText20.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.greenlightOne,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListenableBuilder(
        listenable: _invoiceController,
        builder: (context, child) {
          final state = _invoiceController.state;

          // Tela de Carregamento com mensagem dinâmica (ex: "Conectando à SEFAZ...")
          if (state is InvoiceLoadingState) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CustomCircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: AppTextStyles.inputText.copyWith(
                      color: AppColors.greenlightOne,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }

          // Tela de Erro
          if (state is InvoiceErrorState) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            );
          }

          // Tela de Lista Vazia
          if (_invoiceController.allInvoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: AppColors.grey.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Nenhuma nota fiscal baixada.",
                    style: AppTextStyles.smallText.copyWith(
                      color: AppColors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Clique no botão + para baixar",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            );
          }

          // Lista de Notas Fiscais Baixadas
          return RefreshIndicator(
            color: AppColors.greenlightOne,
            onRefresh: () => _invoiceController.loadInvoices(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _invoiceController.allInvoices.length,
              itemBuilder: (context, index) {
                final invoice = _invoiceController.allInvoices[index];

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.greenlightOne.withValues(
                        alpha: 0.1,
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf,
                        color: AppColors.greenlightOne,
                      ),
                    ),
                    title: Text(
                      "NFe: ${invoice.accessKey.substring(0, 20)}...",
                      style: AppTextStyles.smallText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        "Emitida em: ${_formatDate(invoice.issueDate)}",
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.open_in_new,
                      color: Colors.grey,
                      size: 20,
                    ),
                    onTap: () {
                      // Chama a função do controlador que abre o visualizador de PDF do celular
                      _invoiceController.openPdf(invoice.pdfFilePath);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.greenlightOne,
        tooltip: "Baixar Novas Notas",
        onPressed: () {
          // Inicia o processo: Escolher pasta -> Baixar novas -> Atualizar lista
          _invoiceController.downloadNewInvoices();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
