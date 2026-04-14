import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bill.dart';

class PdfInvoiceService {
  static final List<String> _ones = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten", "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"];
  static final List<String> _tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"];

  static String _convertToWords(int number) {
    if (number == 0) return "Zero";
    if (number < 20) return _ones[number];
    if (number < 100) return _tens[number ~/ 10] + (number % 10 != 0 ? " ${_ones[number % 10]}" : "");
    if (number < 1000) return "${_ones[number ~/ 100]} Hundred" + (number % 100 != 0 ? " and ${_convertToWords(number % 100)}" : "");
    if (number < 100000) return "${_convertToWords(number ~/ 1000)} Thousand" + (number % 1000 != 0 ? " ${_convertToWords(number % 1000)}" : "");
    if (number < 10000000) return "${_convertToWords(number ~/ 100000)} Lakh" + (number % 100000 != 0 ? " ${_convertToWords(number % 100000)}" : "");
    return "${_convertToWords(number ~/ 10000000)} Crore" + (number % 10000000 != 0 ? " ${_convertToWords(number % 10000000)}" : "");
  }

  static String numberToWords(double amount) {
    int rupees = amount.floor();
    int paise = ((amount - rupees) * 100).round();
    String words = "INR ${_convertToWords(rupees).trim()}";
    if (paise > 0) {
      words += " and ${_convertToWords(paise).trim()} paise";
    }
    return "$words Only";
  }

  static Future<Uint8List> generatePdfBinary(Bill bill) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd-MMM-yy');
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final hasIgst = bill.items.any((i) => i.igst > 0);
    double totalQty = bill.items.fold(0, (sum, item) => sum + item.quantity);
    double totalTaxableAmount = bill.items.fold(0, (sum, item) => sum + item.total);
    double totalTaxAmount = bill.items.fold(0, (sum, item) => sum + item.cgst + item.sgst + item.igst);

    final Uint8List logoBytes = (await rootBundle.load('assets/images/logo.jpg')).buffer.asUint8List();
    final logoImage = pw.MemoryImage(logoBytes);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            // TOP HEADER - TAX INVOICE
            pw.Center(
              child: pw.Text('Tax Invoice', style: pw.TextStyle(font: fontBold, fontSize: 16, decoration: pw.TextDecoration.underline))
            ),
            pw.SizedBox(height: 10),

            // SELLER / BUYER HEADER BLOCK
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  top: pw.BorderSide(width: 0.5),
                  left: pw.BorderSide(width: 0.5),
                  right: pw.BorderSide(width: 0.5),
                )
              ),
              child: pw.Row(
                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                     children: [
                       // LEFT SIDE: Seller, Consignee, Buyer
                       pw.Expanded(
                         flex: 5,
                         child: pw.Column(
                           crossAxisAlignment: pw.CrossAxisAlignment.start,
                           children: [
                             // Seller
                             pw.Padding(
                               padding: const pw.EdgeInsets.all(6),
                               child: pw.Row(
                                 children: [
                                   pw.Image(logoImage, width: 50, height: 50),
                                   pw.SizedBox(width: 8),
                                   pw.Column(
                                     crossAxisAlignment: pw.CrossAxisAlignment.start,
                                     children: [
                                       pw.Text('ATHIBAN TRADERS', style: pw.TextStyle(font: fontBold, fontSize: 14)),
                                       pw.Text('RTO Office, Surandai Road', style: pw.TextStyle(font: font, fontSize: 10)),
                                       pw.Text('Sankaran Kovil', style: pw.TextStyle(font: font, fontSize: 10)),
                                       pw.Text('GSTIN/UIN : 33FBPPS2490D2ZD', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                                       pw.Text('State Name : Tamil Nadu, Code : 33', style: pw.TextStyle(font: font, fontSize: 10)),
                                       pw.Text('E-Mail : athibantraders@gmail.com', style: pw.TextStyle(font: font, fontSize: 10)),
                                     ]
                                   )
                                 ]
                               )
                             ),
                             pw.Divider(thickness: 0.5, height: 0),
                             // Consignee
                             pw.Padding(
                               padding: const pw.EdgeInsets.all(6),
                               child: pw.Column(
                                 crossAxisAlignment: pw.CrossAxisAlignment.start,
                                 children: [
                                   pw.Text('Consignee (Ship to)', style: pw.TextStyle(font: font, fontSize: 9)),
                                   pw.Text(bill.customerName?.isNotEmpty == true ? bill.customerName! : 'Walk-in', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                                   if (bill.customerAddress?.isNotEmpty == true) pw.Text(bill.customerAddress!, style: pw.TextStyle(font: font, fontSize: 10)),
                                   if (bill.customerPhone?.isNotEmpty == true) pw.Text('Phone: ${bill.customerPhone}', style: pw.TextStyle(font: font, fontSize: 10)),
                                 ]
                               )
                             ),
                             pw.Divider(thickness: 0.5, height: 0),
                             // Buyer
                             pw.Padding(
                               padding: const pw.EdgeInsets.all(6),
                               child: pw.Column(
                                 crossAxisAlignment: pw.CrossAxisAlignment.start,
                                 children: [
                                   pw.Text('Buyer (Bill to)', style: pw.TextStyle(font: font, fontSize: 9)),
                                   pw.Text(bill.customerName?.isNotEmpty == true ? bill.customerName! : 'Walk-in', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                                   if (bill.customerAddress?.isNotEmpty == true) pw.Text(bill.customerAddress!, style: pw.TextStyle(font: font, fontSize: 10)),
                                   if (bill.customerPhone?.isNotEmpty == true) pw.Text('Phone: ${bill.customerPhone}', style: pw.TextStyle(font: font, fontSize: 10)),
                                 ]
                               )
                             ),
                           ]
                         )
                       ),
                       // RIGHT SIDE: Invoice Refs
                       pw.Container(width: 0.5, height: 260, color: PdfColors.black),
                       pw.Expanded(
                         flex: 5,
                         child: pw.Column(
                           crossAxisAlignment: pw.CrossAxisAlignment.start,
                           children: [
                             pw.Row(
                               children: [
                                 pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                   pw.Text('Invoice No.', style: pw.TextStyle(font: font, fontSize: 9)),
                                   pw.Text(bill.billNumber, style: pw.TextStyle(font: fontBold, fontSize: 10)),
                                 ]))),
                                 pw.Container(width: 0.5, height: 40, color: PdfColors.black),
                                 pw.Expanded(child: pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                                   pw.Text('Dated', style: pw.TextStyle(font: font, fontSize: 9)),
                                   pw.Text(dateFormat.format(bill.date), style: pw.TextStyle(font: fontBold, fontSize: 10)),
                                 ]))),
                               ]
                             ),
                             pw.Divider(thickness: 0.5, height: 0),
                             pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.SizedBox(height: 20, child: pw.Text('Delivery Note', style: pw.TextStyle(font: font, fontSize: 9)))),
                             pw.Divider(thickness: 0.5, height: 0),
                             pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.SizedBox(height: 20, child: pw.Text('Reference No. & Date.', style: pw.TextStyle(font: font, fontSize: 9)))),
                             pw.Divider(thickness: 0.5, height: 0),
                             pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.SizedBox(height: 20, child: pw.Text('Buyer\'s Order No.', style: pw.TextStyle(font: font, fontSize: 9)))),
                             pw.Divider(thickness: 0.5, height: 0),
                             pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.SizedBox(height: 20, child: pw.Text('Dispatch Doc No.', style: pw.TextStyle(font: font, fontSize: 9)))),
                             pw.Divider(thickness: 0.5, height: 0),
                             pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.SizedBox(height: 20, child: pw.Text('Dispatched through', style: pw.TextStyle(font: font, fontSize: 9)))),
                           ]
                         ),
                       )
                     ]
                   ),
            ),
            
            // ITEMS TABLE
            pw.TableHelper.fromTextArray(
              border: const pw.TableBorder(
                left: pw.BorderSide(width: 0.5),
                right: pw.BorderSide(width: 0.5),
                verticalInside: pw.BorderSide(width: 0.5),
                top: pw.BorderSide(width: 0.5),
                bottom: pw.BorderSide(width: 0.5),
              ),
              headerStyle: pw.TextStyle(font: font, fontSize: 9),
                      cellStyle: pw.TextStyle(font: font, fontSize: 10),
                      cellAlignment: pw.Alignment.centerRight,
                      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      headers: ['Sl\nNo.', 'Description of Goods', 'HSN/SAC', 'Quantity', 'Rate\n(Incl. Tax)', 'Rate', 'per', 'Disc. %', 'Amount'],
                      columnWidths: {
                        0: const pw.FlexColumnWidth(1),
                        1: const pw.FlexColumnWidth(5),
                        2: const pw.FlexColumnWidth(2),
                        3: const pw.FlexColumnWidth(2),
                        4: const pw.FlexColumnWidth(2),
                        5: const pw.FlexColumnWidth(2),
                        6: const pw.FlexColumnWidth(1),
                        7: const pw.FlexColumnWidth(1.5),
                        8: const pw.FlexColumnWidth(2.5),
                      },
                      cellAlignments: {
                        0: pw.Alignment.topCenter,
                        1: pw.Alignment.topLeft,
                        2: pw.Alignment.topCenter,
                      },
                      data: List.generate(bill.items.length, (i) {
                        final item = bill.items[i];
                        double rateInclTax = item.price;
                        double baseRate = item.price / (1 + (item.taxRate / 100));
                        return [
                          '${i + 1}',
                          item.productName,
                          item.hsnCode,
                          '${item.quantity.toInt()}',
                          rateInclTax.toStringAsFixed(2),
                          baseRate.toStringAsFixed(2),
                          'nos',
                          item.discountPercentage > 0 ? '${item.discountPercentage}%' : '',
                          item.total.toStringAsFixed(2),
                        ];
                      }),
                   ),
            
            // TOTALS AND FOOTER BLOCK
            pw.Container(
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  left: pw.BorderSide(width: 0.5),
                  right: pw.BorderSide(width: 0.5),
                  bottom: pw.BorderSide(width: 0.5),
                )
              ),
              child: pw.Column(
                children: [
                   // IF IGST/CGST space
                   if (hasIgst) 
                    pw.Padding(padding: const pw.EdgeInsets.only(right: 6, bottom: 4, top: 4), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('IGST\n${totalTaxAmount.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 10))))
                   else
                    pw.Padding(padding: const pw.EdgeInsets.only(right: 6, bottom: 4, top: 4), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('CGST\n${(totalTaxAmount/2).toStringAsFixed(2)}\nSGST\n${(totalTaxAmount/2).toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 10)))),
                   
                   pw.Padding(padding: const pw.EdgeInsets.only(right: 6, bottom: 4), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Round Off \n${bill.roundOff.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: pw.TextStyle(font: fontBold, fontSize: 10)))),

                   pw.Divider(thickness: 0.5, height: 0),
                   // Sub Total Row
                   pw.Row(
                     children: [
                       pw.Expanded(flex: 15, child: pw.Padding(padding: const pw.EdgeInsets.only(right: 8, top: 4, bottom: 4), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Total', style: pw.TextStyle(font: fontBold, fontSize: 10))))),
                       pw.Expanded(flex: 3, child: pw.Center(child: pw.Text(totalQty.toStringAsFixed(2), style: pw.TextStyle(font: fontBold, fontSize: 10)))),
                       pw.Expanded(flex: 16, child: pw.Padding(padding: const pw.EdgeInsets.only(right: 6), child: pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('Rs. ${bill.grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(font: fontBold, fontSize: 12))))),
                     ]
                   ),
                   pw.Divider(thickness: 0.5, height: 0),

                   // Amount in words
                   pw.Padding(
                     padding: const pw.EdgeInsets.all(6),
                     child: pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Text('Amount Chargeable (in words)\n${numberToWords(bill.grandTotal)}', style: pw.TextStyle(font: fontBold, fontSize: 10)))
                   ),
                   pw.Divider(thickness: 0.5, height: 0),

                   // TAX SUMMARY TABLE
                   pw.TableHelper.fromTextArray(
                      border: pw.TableBorder.all(width: 0.5),
                      headerStyle: pw.TextStyle(font: fontBold, fontSize: 9),
                      cellStyle: pw.TextStyle(font: font, fontSize: 9),
                      cellAlignment: pw.Alignment.centerRight,
                      headers: hasIgst 
                          ? ['HSN/SAC', 'Taxable Value', 'IGST Rate', 'IGST Amount', 'Total Tax Amount']
                          : ['HSN/SAC', 'Taxable Value', 'CGST Rate', 'CGST Amount', 'SGST Rate', 'SGST Amount', 'Total Tax Amount'],
                      data: [
                        if (hasIgst)
                          ['', totalTaxableAmount.toStringAsFixed(2), '18%', totalTaxAmount.toStringAsFixed(2), totalTaxAmount.toStringAsFixed(2)]
                        else
                          ['', totalTaxableAmount.toStringAsFixed(2), '9%', (totalTaxAmount/2).toStringAsFixed(2), '9%', (totalTaxAmount/2).toStringAsFixed(2), totalTaxAmount.toStringAsFixed(2)],
                        if (hasIgst)
                          ['Total', totalTaxableAmount.toStringAsFixed(2), '', totalTaxAmount.toStringAsFixed(2), totalTaxAmount.toStringAsFixed(2)]
                        else
                          ['Total', totalTaxableAmount.toStringAsFixed(2), '', (totalTaxAmount/2).toStringAsFixed(2), '', (totalTaxAmount/2).toStringAsFixed(2), totalTaxAmount.toStringAsFixed(2)],
                      ]
                   ),
                   
                   // Tax in words
                   pw.Padding(
                     padding: const pw.EdgeInsets.all(6),
                     child: pw.Align(alignment: pw.Alignment.centerLeft, child: pw.Text('Tax Amount (in words) : ${numberToWords(totalTaxAmount)}', style: pw.TextStyle(font: fontBold, fontSize: 10)))
                   ),
                   pw.Divider(thickness: 0.5, height: 0),

                   // FOOTER: Declaration & Signature
                   pw.Row(
                     crossAxisAlignment: pw.CrossAxisAlignment.end,
                     children: [
                       pw.Expanded(
                         flex: 1,
                         child: pw.Padding(
                           padding: const pw.EdgeInsets.all(6),
                           child: pw.Column(
                             crossAxisAlignment: pw.CrossAxisAlignment.start,
                             children: [
                               pw.Text('Declaration', style: pw.TextStyle(font: fontBold, fontSize: 10)),
                               pw.Text('We declare that this invoice shows the actual price of the goods described and that all particulars are true and correct.', style: pw.TextStyle(font: font, fontSize: 9)),
                               pw.SizedBox(height: 20),
                               pw.Center(child: pw.Text('SUBJECT TO SANKARAN KOVIL JURISDICTION', style: pw.TextStyle(font: fontBold, fontSize: 10))),
                             ]
                           )
                         )
                       ),
                       pw.Container(width: 0.5, height: 100, color: PdfColors.black),
                       pw.Expanded(
                         flex: 1,
                         child: pw.Padding(
                           padding: const pw.EdgeInsets.all(6),
                           child: pw.Column(
                             crossAxisAlignment: pw.CrossAxisAlignment.end,
                             mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                             children: [
                               pw.Text('for ATHIBAN TRADERS', style: pw.TextStyle(font: fontBold, fontSize: 11)),
                               pw.SizedBox(height: 50), // Signature gap
                               pw.Text('Authorised Signatory', style: pw.TextStyle(font: font, fontSize: 10)),
                             ]
                           )
                         )
                       )
                     ]
                   )
                ]
              )
            ),
            pw.SizedBox(height: 10),
            pw.Center(child: pw.Text('This is a Computer Generated Invoice', style: pw.TextStyle(font: font, fontSize: 10)))
          ];
        },
      ),
    );

    return pdf.save();
  }

  static Future<void> savePdfLocally(Bill bill, Uint8List bytes) async {
    final fileName = 'Invoice_${bill.billNumber}.pdf';
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  static Future<void> shareToWhatsApp(Bill bill, Uint8List bytes) async {
    final phoneNumber = bill.customerPhone?.replaceAll(RegExp(r'\D'), '');
    
    if (kIsWeb) {
      final text = "Dear Customer,\n\nHere are the details for your Invoice No: ${bill.billNumber}\n"
          "Amount: Rs. ${bill.grandTotal.toStringAsFixed(2)}\n"
          "Date: ${DateFormat('dd-MM-yyyy').format(bill.date)}\n\n"
          "Thank you for doing business with ATHIBAN TRADERS.";
      final encodedText = Uri.encodeComponent(text);
      final whatsappUrl = (phoneNumber != null && phoneNumber.isNotEmpty)
          ? "https://wa.me/91$phoneNumber?text=$encodedText"
          : "https://wa.me/?text=$encodedText";
      
      final url = Uri.parse(whatsappUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // Fallback or handle error if needed
      }
    } else {
      final fileName = 'Invoice_${bill.billNumber}.pdf';
      final file = XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf');
      final text = "Invoice No: ${bill.billNumber}\nAmount: Rs. ${bill.grandTotal.toStringAsFixed(2)}";
      await Share.shareXFiles([file], text: text, subject: 'Invoice from ATHIBAN TRADERS');
    }
  }

  static Future<void> generateAndPrintPdf(Bill bill) async {
    final bytes = await generatePdfBinary(bill);
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => bytes,
        name: 'Invoice_${bill.billNumber}',
    );
  }
}
