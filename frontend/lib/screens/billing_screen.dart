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

class _BillingScreenState extends State<BillingScreen>
    with SingleTickerProviderStateMixin {
  final _customerNameCtrl = TextEditingController();
  final _customerPhoneCtrl = TextEditingController();
  final _customerAddressCtrl = TextEditingController();
  final _searchQueryCtrl = TextEditingController();

  final List<BillItem> _cart = [];
  double _globalDiscountPercent = 0.0;
  bool _isProcessing = false;
  String _searchQuery = '';
  String _customerState = 'Tamil Nadu';

  // Tab controller for mobile: switch between Products and Cart
  late TabController _tabController;

  final List<String> _states = [
    'Tamil Nadu',
    'Kerala',
    'Karnataka',
    'Andhra Pradesh',
    'Telangana',
    'Maharashtra',
    'Delhi',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customerNameCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _customerAddressCtrl.dispose();
    _searchQueryCtrl.dispose();
    super.dispose();
  }

  // ── Calculations ──────────────────────────────────────────────────────────

  double get _subTotal {
    return _cart.fold(0, (sum, item) {
      double baseRate = item.price / (1 + (item.taxRate / 100));
      return sum + (baseRate * item.quantity);
    });
  }

  double get _totalDiscountAmount => _subTotal * (_globalDiscountPercent / 100);

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
      item.total = itemTaxableAmt;
    }
    return totalTax;
  }

  double get _rawTotal => (_subTotal - _totalDiscountAmount) + _totalTaxAmount;
  double get _grandTotal => _rawTotal.roundToDouble();
  double get _roundOff => _grandTotal - _rawTotal;

  // ── Cart Operations ────────────────────────────────────────────────────────

  void _addToCart(Product product) {
    setState(() {
      final existingIndex = _cart.indexWhere(
        (item) => item.product?.id == product.id,
      );
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
          total: 0,
        );
      } else {
        _cart.add(
          BillItem(
            product: product,
            productName: product.name,
            quantity: 1,
            price: product.price,
            discountPercentage: _globalDiscountPercent,
            hsnCode: product.hsnCode,
            taxRate: product.taxRate,
            total: 0,
          ),
        );
      }
    });
    // On mobile, switch to cart tab to show item was added
    if (!_isTablet(context)) {
      _tabController.animateTo(1);
    }
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
          decoration: const InputDecoration(labelText: 'Quantity'),
          onFieldSubmitted: (val) {
            final newQty = double.tryParse(val) ?? 0;
            _updateCartItemQty(index, newQty);
            Navigator.pop(ctx);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = double.tryParse(qtyCtrl.text) ?? 0;
              _updateCartItemQty(index, newQty);
              Navigator.pop(ctx);
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  bool _isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600;

  // ── Checkout ───────────────────────────────────────────────────────────────

  void _checkout() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Trigger tax calculation
      final _ = _totalTaxAmount;

      final bill = Bill(
        id: '',
        billNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
        date: DateTime.now(),
        customerName: _customerNameCtrl.text.isEmpty
            ? 'Walk-in Customer'
            : _customerNameCtrl.text,
        customerPhone: _customerPhoneCtrl.text,
        customerAddress: _customerAddressCtrl.text.isNotEmpty
            ? '${_customerAddressCtrl.text}, $_customerState'
            : _customerState,
        items: List.from(_cart),
        subTotal: _subTotal,
        taxRate: 0.0,
        taxAmount: _totalTaxAmount,
        discount: _totalDiscountAmount,
        roundOff: _roundOff,
        grandTotal: _grandTotal,
        isSynced: false,
      );

      await Provider.of<BillProvider>(context, listen: false).addBill(bill);
      if (mounted) {
        Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      }

      setState(() {
        _cart.clear();
        _customerNameCtrl.clear();
        _customerPhoneCtrl.clear();
        _customerAddressCtrl.clear();
        _globalDiscountPercent = 0.0;
        _customerState = 'Tamil Nadu';
      });

      if (!mounted) return;

      final bytes = await PdfInvoiceService.generatePdfBinary(bill);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Invoice Generated ✓'),
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
              label: const Text('WhatsApp'),
              onPressed: () async {
                Navigator.pop(ctx);
                await PdfInvoiceService.shareToWhatsApp(bill, bytes);
              },
            ),
            TextButton.icon(
              icon: const Icon(Icons.close),
              label: const Text('Close'),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ── Widgets ────────────────────────────────────────────────────────────────

  Widget _buildCustomerForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Billing Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _customerNameCtrl,
            decoration: InputDecoration(
              labelText: 'Customer Name',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _customerPhoneCtrl,
            decoration: InputDecoration(
              labelText: 'Phone Number',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _customerAddressCtrl,
            decoration: InputDecoration(
              labelText: 'Address (optional)',
              prefixIcon: const Icon(Icons.location_on_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _customerState,
            decoration: InputDecoration(
              labelText: 'State (For GST)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
            items: _states
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _customerState = val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCartList() {
    if (_cart.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.black26),
            SizedBox(height: 12),
            Text(
              'Cart is empty',
              style: TextStyle(fontSize: 16, color: Colors.black45),
            ),
            SizedBox(height: 4),
            Text(
              'Go to Products tab to add items',
              style: TextStyle(fontSize: 13, color: Colors.black38),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _cart.length,
      itemBuilder: (ctx, i) {
        final item = _cart[i];
        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => setState(() => _cart.removeAt(i)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${item.price.toStringAsFixed(2)} incl. tax  •  HSN: ${item.hsnCode}  •  GST: ${item.taxRate}%',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Qty controls
                    IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.orange,
                      ),
                      onPressed: () => _updateCartItemQty(i, item.quantity - 1),
                    ),
                    GestureDetector(
                      onTap: () => _showEditQtyDialog(i, item.quantity),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.quantity.toInt().toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.green,
                      ),
                      onPressed: () => _updateCartItemQty(i, item.quantity + 1),
                    ),
                    const Spacer(),
                    Text(
                      '₹${(item.quantity * item.price).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Discount row
          Row(
            children: [
              const Text(
                'Discount (%): ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              SizedBox(
                width: 70,
                child: TextFormField(
                  initialValue: _globalDiscountPercent.toString(),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => setState(
                    () => _globalDiscountPercent = double.tryParse(val) ?? 0,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Totals
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Taxable Amount:',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Text(
                '₹${(_subTotal - _totalDiscountAmount).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total GST:',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Text(
                '₹${_totalTaxAmount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Round Off:',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Text(
                _roundOff.toStringAsFixed(2),
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '₹${_grandTotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _checkout,
            icon: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.shopping_cart_checkout, color: Colors.white),
            label: Text(
              _isProcessing ? 'Processing...' : 'Checkout & Bill',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E3A8A),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Product> products) {
    final filtered = _searchQuery.isEmpty
        ? products
        : products
              .where(
                (p) =>
                    p.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.white,
          child: TextFormField(
            controller: _searchQueryCtrl,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchQueryCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              isDense: true,
            ),
          ),
        ),
        // Grid
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No products found'))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount:
                        2, // 2 columns on mobile (3 on tablet handled below)
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final p = filtered[i];
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
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Spacer(),
                              Text(
                                '₹${p.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(ctx).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Stock: ${p.stock}',
                                    style: TextStyle(
                                      color: p.stock > 10
                                          ? Colors.green
                                          : Colors.red,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.add_shopping_cart,
                                    size: 14,
                                    color: Colors.blueGrey,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final products = Provider.of<ProductProvider>(context).products;
    final isTablet = _isTablet(context);

    if (isTablet) {
      // ── TABLET / WIDE layout (original side-by-side) ──
      return Scaffold(
        backgroundColor: const Color(0xFFF3F4F6),
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  _buildCustomerForm(),
                  Expanded(child: _buildCartList()),
                  _buildSummaryBar(),
                ],
              ),
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
            Expanded(flex: 4, child: _buildProductGrid(products)),
          ],
        ),
      );
    }

    // ── MOBILE layout (tabbed) ──
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFF1E3A8A),
        title: const Text(
          'Billing',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            const Tab(icon: Icon(Icons.grid_view), text: 'Products'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  const SizedBox(width: 4),
                  const Text('Cart'),
                  if (_cart.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_cart.length}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Products
          _buildProductGrid(products),

          // Tab 2: Customer info + Cart + Summary
          Column(
            children: [
              _buildCustomerForm(),
              Expanded(child: _buildCartList()),
              _buildSummaryBar(),
            ],
          ),
        ],
      ),
    );
  }
}
