import 'package:flutter/material.dart';

class InvoiceEditScreen extends StatelessWidget { const InvoiceEditScreen({super.key, required this.id}); final String id; @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Edit invoice')), body: Center(child: Text('Invoice $id can be edited from its account workflow.'))); }
