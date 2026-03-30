import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/bill.dart';
import '../models/product.dart';
import '../providers/bill_provider.dart';
import '../providers/product_provider.dart';
import '../services/pdf_service.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _customerAddressCtrl = TextEditingController();
  final _searchQueryCtrl = TextEditingController();
  
  final List<BillItem> _cart = [];
  double _globalDiscountPercent = 0.0;
  bool _isProcessing = false;
  String _searchQuery = '';
  String _customerState = 'Tamil Nadu';

  final List<String> _states = [
    'Tamil Nadu', 'Kerala', 'Karnataka', 'Andhra Pradesh', 'Telangana', 'Maharashtra', 'Delhi', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  double get _subTotal {
    return _cart.fold(0, (sum, item) {
       double baseRate = item.price / (1 + (item.taxRate / 100));
       return sum + (baseRate * item.quantity);
    });
  }

  double get _totalDiscountAmount {
    return _subTotal * (_globalDiscountPercent / 100);
  }

  double get _totalTaxAmount {
    double totalTax = 0;
    bool isInterState = _customerState != 'Tamil Nadu';
    for (var item in _cart) {
      double baseRate = item.price / (1 + (item.taxRate / 100));
      double itemBaseAmt = baseRate * item.quantity;
      double itemDiscount = itemBaseAmt * (_globalDiscountPercent / 100);
      double itemTaxableAmt = itemBaseAmt - itemDiscount;
      double taxAmt = itemTaxableAmt * (item.taxRate / 100);
      totalTax += taxAmt;

      // Update item logic silently
      item.discountPercentage = _globalDiscountPercent;
      item.discount = itemDiscount;
      if (isInterState) {
        item.igst = taxAmt;
        item.cgst = 0;
        item.sgst = 0;
      } else {
        item.igst = 0;
        item.cgst = taxAmt / 2;
        item.sgst = taxAmt / 2;
      }
      item.total = itemTaxableAmt; // Store taxable amount as per the invoice format
    }
    return totalTax;
  }

  double get _rawTotal => (_subTotal - _totalDiscountAmount) + _totalTaxAmount;
  double get _grandTotal => _rawTotal.roundToDouble();
  double get _roundOff => _grandTotal - _rawTotal;

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere((item) => item.product?.id == product.id);
      if (existingIndex >= 0) {
        final item = _cart[existingIndex];
        _cart[existingIndex] = BillItem(
          product: item.product,
          productName: item.productName,
          quantity: item.quantity + 1,
          price: item.price,
          discountPercentage: _globalDiscountPercent,
          hsnCode: item.hsnCode,
          taxRate: item.taxRate,
          total: 0, // Recalculated on demand
        );
      } else {
        _cart.add(BillItem(
          product: product,
          productName: product.name,
          quantity: 1,
          price: product.price,
          discountPercentage: _globalDiscountPercent,
          hsnCode: product.hsnCode,
          taxRate: product.taxRate,
          total: 0, // Recalculated on demand
        ));
      }
    });
  }

  void _updateCartItemQty(int index, double newQty) {
    if (newQty <= 0) {
      setState(() => _cart.removeAt(index));
    } else {
      setState(() {
        final item = _cart[index];
        _cart[index] = BillItem(
          product: item.product,
          productName: item.productName,
          quantity: newQty,
          price: item.price,
          discountPercentage: _globalDiscountPercent,
          hsnCode: item.hsnCode,
          taxRate: item.taxRate,
          total: 0,
        );
      });
    }
  }

  void _showEditQtyDialog(int index, double currentQty) {
    final qtyCtrl = TextEditingController(text: currentQty.toInt().toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Quantity'),
        content: TextFormField(
          controller: qtyCtrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Bulk Quantity'),
          onFieldSubmitted: (val) {
             final newQty = double.tryParse(val) ?? 0;
             _updateCartItemQty(index, newQty);
             Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newQty = double.tryParse(qtyCtrl.text) ?? 0;
              _updateCartItemQty(index, newQty);
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          )
        ],
      ),
    );
  }

  void _checkout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final bill = Bill(
        id: '',
        billNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        customerName: _customerNameCtrl.text.isEmpty ? 'Walk-in Customer' : _customerNameCtrl.text,
        customerPhone: _customerPhoneCtrl.text,
        customerAddress: _customerAddressCtrl.text.isNotEmpty ? '${_customerAddressCtrl.text}, $_customerState' : _customerState,
        items: List.from(_cart),
        subTotal: _subTotal,
        taxRate: 0.0, // Used at item level now
        taxAmount: _totalTaxAmount,
        discount: _totalDiscountAmount,
        roundOff: _roundOff,
        grandTotal: _grandTotal,
        isSynced: false,
      );

      await Provider.of<BillProvider>(context, listen: false).addBill(bill);
      if (mounted) Provider.of<ProductProvider>(context, listen: false).fetchProducts();

      // Clear the Form Data
      setState(() {
        _cart.clear();
        _customerNameCtrl.clear();
        _customerPhoneCtrl.clear();
        _customerAddressCtrl.clear();
        _globalDiscountPercent = 0.0;
        _customerState = 'Tamil Nadu';
      });

      if (!mounted) return;
      
      // Generate Binary
      final bytes = await PdfInvoiceService.generatePdfBinary(bill);

      // Show Post-Checkout Options Dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Invoice Generated Successfully'),
          content: const Text('What would you like to do next?'),
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.print),
              label: const Text('View/Print'),
              onPressed: () {
                 Navigator.pop(ctx);
                 PdfInvoiceService.generateAndPrintPdf(bill); 
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Save PDF'),
              onPressed: () async {
                 Navigator.pop(ctx);
                 await PdfInvoiceService.savePdfLocally(bill, bytes);
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.message),
              label: const Text('Share WhatsApp'),
              onPressed: () async {
                 Navigator.pop(ctx);
                 await PdfInvoiceService.shareToWhatsApp(bill, bytes);
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              onPressed: () {
                 Navigator.pop(ctx);
              },
            ),
          ],
        )
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Checkout failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final products = Provider.of<ProductProvider>(context).products;
    final filteredProducts = _searchQuery.isEmpty 
        ? products 
        : products.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT SIDE: Customer & Cart
          Expanded(
            flex: 5,
            child: Column(
              children: [
                // 1) Customer Details
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Billing Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _customerNameCtrl,
                              decoration: InputDecoration(
                                labelText: 'Customer Name',
                                prefixIcon: const Icon(Icons.person_outline),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _customerPhoneCtrl,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                prefixIcon: const Icon(Icons.phone_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _customerAddressCtrl,
                              decoration: InputDecoration(
                                labelText: 'Billing Address (optional)',
                                prefixIcon: const Icon(Icons.location_on_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: _customerState,
                              decoration: InputDecoration(
                                labelText: 'State (For GST)',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                isDense: true,
                              ),
                              items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _customerState = val);
                              },
                            ),
                          ),
                        ]
                      ),
                    ],
                  ),
                ),
                
                // 2) Cart Items Table / List
                Expanded(
                  child: _cart.isEmpty
                      ? const Center(child: Text('Cart is empty.\nTap items from the right to add.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.black54)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _cart.length,
                          itemBuilder: (ctx, i) {
                            final item = _cart[i];
                            return Card(
                              elevation: 1,
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              child: ListTile(
                                leading: InkWell(
                                  onTap: () => _showEditQtyDialog(i, item.quantity),
                                  child: CircleAvatar(
                                    backgroundColor: Colors.blue.shade50,
                                    child: Text('${item.quantity.toInt()}'),
                                  ),
                                ),
                                title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Incl. Tax: ₹${item.price.toStringAsFixed(2)}  •  HSN: ${item.hsnCode}\nBase: ₹${(item.price / (1 + item.taxRate/100)).toStringAsFixed(2)}  •  Tax: ${item.taxRate}%'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('₹${(item.quantity * item.price).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                      onPressed: () => _updateCartItemQty(i, item.quantity - 1),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                      onPressed: () => _updateCartItemQty(i, item.quantity + 1),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => setState(() => _cart.removeAt(i)),
                                    )
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),

                // 3) Checkout Summary at the bottom
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                       Expanded(
                         child: Column(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Row(
                                 children: [
                                   const Text('Disc (%): ', style: TextStyle(fontSize: 16)),
                                   SizedBox(
                                     width: 80,
                                     child: TextFormField(
                                       initialValue: _globalDiscountPercent.toString(),
                                       keyboardType: TextInputType.number,
                                       onChanged: (val) => setState(() => _globalDiscountPercent = double.tryParse(val) ?? 0),
                                       decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8), border: OutlineInputBorder()),
                                     ),
                                   ),
                                 ]
                               ),
                               const SizedBox(height: 8),
                               Text('Taxable Total: ₹${(_subTotal - _totalDiscountAmount).toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54)),
                               const SizedBox(height: 4),
                               Text('Total GST: ₹${_totalTaxAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54)),
                               const SizedBox(height: 4),
                               Text('Round Off: ${_roundOff.toStringAsFixed(2)}', style: const TextStyle(color: Colors.black54)),
                             ],
                           )
                         ),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.end,
                             children: [
                                const Text('Grand Total', style: TextStyle(fontSize: 16, color: Colors.black54)),
                                Text('₹${_grandTotal.toStringAsFixed(2)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: _isProcessing ? null : _checkout,
                                icon: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.shopping_cart_checkout, color: Colors.white),
                                label: Text(_isProcessing ? 'Processing...' : 'Checkout & Bill', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                           ],
                         )
                       )
                    ]
                  ),
                ),
              ],
            ),
          ),
          
          const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),

          // RIGHT SIDE: Product Grid & Search
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: TextFormField(
                    controller: _searchQueryCtrl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search products to add...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty 
                        ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                            _searchQueryCtrl.clear();
                            setState(() => _searchQuery = '');
                          }) 
                        : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                Expanded(
                  child: filteredProducts.isEmpty 
                    ? const Center(child: Text('No products found'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3, 
                          childAspectRatio: 1.2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (ctx, i) {
                          final p = filteredProducts[i];
                          return Card(
                            elevation: 2,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              onTap: () => _addToCart(p),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.white, Colors.blue.shade50],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name, 
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Spacer(),
                                      Text(
                                        '₹${p.price.toStringAsFixed(2)}', 
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          fontSize: 18, 
                                          color: Theme.of(context).colorScheme.primary
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('Stock: ${p.stock}', style: TextStyle(color: p.stock > 10 ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                                          const Icon(Icons.add_shopping_cart, size: 16, color: Colors.blueGrey),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

