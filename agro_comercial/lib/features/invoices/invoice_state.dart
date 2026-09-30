import 'package:agro_comercial/common/models/invoice_model.dart';

abstract class InvoiceState {}

class InvoiceInitialState extends InvoiceState {}

class InvoiceLoadingState extends InvoiceState {
  final String message;
  InvoiceLoadingState([this.message = "Carregando..."]);
}

class InvoiceSuccessState extends InvoiceState {
  final List<InvoiceModel> invoices;
  InvoiceSuccessState(this.invoices);
}

class InvoiceErrorState extends InvoiceState {
  final String message;
  InvoiceErrorState(this.message);
}
