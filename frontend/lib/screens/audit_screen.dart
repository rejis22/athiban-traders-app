import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

import '../models/bill.dart';
import '../providers/bill_provider.dart';
import '../services/pdf_service.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<BillProvider>(context, listen: false).fetchBills());
  }

  void _downloadInvoicePdf(Bill bill) async {
    try {
      await PdfInvoiceService.generateAndPrintPdf(bill);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _exportCsv(List<Bill> bills) async {
    if (bills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No bills to export.'), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      List<List<dynamic>> rows = [];
      // CSV Header
      rows.add([
        'Invoice Number',
        'Date',
        'Customer Name',
        'Phone',
        'Subtotal (₹)',
        'Tax (₹)',
        'Discount (₹)',
        'Grand Total (₹)',
        'Synced'
      ]);

      for (var bill in bills) {
        rows.add([
          bill.billNumber,
          bill.date.toIso8601String().split('T')[0],
          bill.customerName ?? bill.customer?.name ?? 'Walk-in',
          bill.customerPhone ?? bill.customer?.phone ?? '',
          bill.subTotal,
          bill.taxAmount,
          bill.discount,
          bill.grandTotal,
          bill.isSynced ? 'Yes' : 'No'
        ]);
      }

      String csvData = const ListToCsvConverter().convert(rows);
      final bytes = utf8.encode(csvData);

      if (kIsWeb) {
        final blob = web.Blob([bytes.toJS].toJS, web.BlobPropertyBag(type: 'text/csv'));
        final url = web.URL.createObjectURL(blob);
        final anchor = web.document.createElement('a') as web.HTMLAnchorElement
          ..href = url
          ..download = 'Audit_Report_${DateTime.now().millisecondsSinceEpoch}.csv';
        
        web.document.body?.append(anchor);
        anchor.click();
        anchor.remove();
        web.URL.revokeObjectURL(url);
      } else {
        await Share.shareXFiles([
          XFile.fromData(Uint8List.fromList(bytes), mimeType: 'text/csv', name: 'Audit_Report.csv')
        ]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final initialDate = isFromDate ? (_fromDate ?? DateTime.now()) : (_toDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Consumer<BillProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Apply Date Filter locally
          List<Bill> filteredBills = provider.bills.where((bill) {
            if (_fromDate != null && bill.date.isBefore(_fromDate!)) return false;
            // Add 1 day to toDate to make it inclusive of the selected day
            if (_toDate != null && bill.date.isAfter(_toDate!.add(const Duration(days: 1)))) return false;
            return true;
          }).toList();

          return Column(
            children: [
              // Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_fromDate == null ? 'From Date' : _fromDate!.toIso8601String().split('T')[0]),
                        onPressed: () => _selectDate(context, true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_toDate == null ? 'To Date' : _toDate!.toIso8601String().split('T')[0]),
                        onPressed: () => _selectDate(context, false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        tooltip: 'Clear Filters',
                        onPressed: () => setState(() {
                           _fromDate = null;
                           _toDate = null;
                        }),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _exportCsv(filteredBills),
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: const Text('Export Excel (CSV)', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                      )
                    )
                  ],
                ),
              ),

              // Bills List
              Expanded(
                child: filteredBills.isEmpty
                    ? const Center(
                        child: Text(
                          'No invoices found matching your criteria.',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredBills.length,
                        itemBuilder: (ctx, i) {
                          final bill = filteredBills[i];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        bill.billNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: bill.isSynced ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          bill.isSynced ? 'Synced' : 'Offline',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: bill.isSynced ? Colors.green : Colors.orange,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('Date: ${bill.date.toLocal().toString().split(' ')[0]}'),
                                  Text('Customer: ${bill.customerName ?? bill.customer?.name ?? 'Walk-in'}'),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '₹${bill.grandTotal.toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context).colorScheme.primary),
                                      ),
                                      OutlinedButton.icon(
                                        onPressed: () => _downloadInvoicePdf(bill),
                                        icon: const Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
                                        label: const Text('View PDF', style: TextStyle(color: Colors.red)),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
