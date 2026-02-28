import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/exceptions/api_exception.dart';

class OrderDetailsPage extends StatefulWidget {
  final int orderId;

  const OrderDetailsPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  Map<String, dynamic>? _orderData;
  Map<String, dynamic>? _cartData;
  List<dynamic>? _payments;
  Map<String, dynamic>? _responseData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
  }

  Future<void> _fetchOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiClient.get(
        endpoint: '${ApiEndpoints.getOrderDetails}/${widget.orderId}',
        requireAuth: true,
      );

      setState(() {
        _responseData = response;
        _orderData = response['order'] is Map<String, dynamic>
            ? response['order'] as Map<String, dynamic>
            : null;
        _cartData = response['cart'] is Map<String, dynamic>
            ? response['cart'] as Map<String, dynamic>
            : null;
        _payments = response['payments'] is List ? response['payments'] as List<dynamic> : null;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load order details. Please try again.';
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateString);
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = _getMonthName(dateTime.month);
      final year = dateTime.year.toString();
      return '$day-$month-$year';
    } catch (e) {
      return dateString;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    if (month >= 1 && month <= 12) {
      return months[month - 1];
    }
    return 'Jan';
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '\$0.00';
    try {
      final numValue = _safeNum(amount);
      return '\$${numValue.toStringAsFixed(2)}';
    } catch (e) {
      return '\$0.00';
    }
  }

  // Safe parse: handles String with commas (e.g. "2,372.18") and num
  double _safeParseAmount(dynamic value) {
    if (value == null) return 0.0;
    final cleaned = value.toString().replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  // Safe num: handles String or num
  double _safeNum(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().replaceAll(',', '').trim()) ?? 0.0;
  }

  // Safe int: handles String or int
  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.orange;
      case 'partial':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Color(0xFF1A365D),
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A365D)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchOrderDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _orderData == null
                  ? const Center(child: Text('No order data found'))
                  : SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Info Card
                            _buildOrderInfoCard(),
                            const SizedBox(height: 16),

                            // Customer Info Card
                            _buildCustomerInfoCard(),
                            const SizedBox(height: 16),

                            // Shipping Info Card
                            if (_orderData!['shipping'] == 'shipto')
                              _buildShippingInfoCard(),
                            if (_orderData!['shipping'] == 'shipto')
                              const SizedBox(height: 16),

                            // Cart Items Card
                            if (_cartData != null && _cartData!.isNotEmpty)
                              _buildCartItemsCard(),
                            if (_cartData != null && _cartData!.isNotEmpty)
                              const SizedBox(height: 16),

                            // Payment Info Card
                            _buildPaymentInfoCard(),
                            const SizedBox(height: 16),

                            // Order Summary Card
                            _buildOrderSummaryCard(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildOrderInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Order Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A365D),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(_orderData!['payment_status'])
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getStatusColor(_orderData!['payment_status'])
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _orderData!['payment_status'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getStatusColor(_orderData!['payment_status']),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Order ID', _orderData!['id'].toString()),
          _buildInfoRow('Order Number', _orderData!['order_number'] ?? 'N/A'),
          _buildInfoRow('Invoice Number', _orderData!['invoice_number'] ?? 'N/A'),
          if (_orderData!['quotation_number'] != null)
            _buildInfoRow('Quotation Number', _orderData!['quotation_number']),
          _buildInfoRow('Order Date', _formatDate(_orderData!['created_at'])),
          _buildInfoRow('Payment Method', _orderData!['method'] ?? 'N/A'),
          _buildInfoRow('Shipping Type', _orderData!['shipping'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildCustomerInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A365D),
            ),
          ),
          const Divider(height: 24),
          _buildInfoRow('Name', _orderData!['customer_name'] ?? 'N/A'),
          _buildInfoRow('Email', _orderData!['customer_email'] ?? 'N/A'),
          if (_orderData!['customer_phone'] != null &&
              _orderData!['customer_phone'].toString().isNotEmpty)
            _buildInfoRow('Phone', _orderData!['customer_phone']),
          _buildInfoRow('Company', _orderData!['customer_company'] ?? 'N/A'),
          _buildInfoRow('Address', _orderData!['customer_address'] ?? 'N/A'),
          _buildInfoRow('City', _orderData!['customer_city'] ?? 'N/A'),
          _buildInfoRow('State', _orderData!['customer_state'] ?? 'N/A'),
          _buildInfoRow('Zip', _orderData!['customer_zip'] ?? 'N/A'),
          _buildInfoRow('Country', _orderData!['customer_country'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildShippingInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Shipping Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A365D),
            ),
          ),
          const Divider(height: 24),
          if (_orderData!['shipping_name'] != null)
            _buildInfoRow('Name', _orderData!['shipping_name']),
          if (_orderData!['shipping_address'] != null)
            _buildInfoRow('Address', _orderData!['shipping_address']),
          if (_orderData!['shipping_city'] != null)
            _buildInfoRow('City', _orderData!['shipping_city']),
          if (_orderData!['shipping_state'] != null)
            _buildInfoRow('State', _orderData!['shipping_state']),
          if (_orderData!['shipping_zip'] != null)
            _buildInfoRow('Zip', _orderData!['shipping_zip']),
          if (_orderData!['shipping_country'] != null)
            _buildInfoRow('Country', _orderData!['shipping_country']),
          if (_orderData!['pickup_location'] != null)
            _buildInfoRow('Pickup Location', _orderData!['pickup_location']),
        ],
      ),
    );
  }

  Widget _buildCartItemsCard() {
    final cartItems = _cartData!.values.toList();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Items',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A365D),
            ),
          ),
          const SizedBox(height: 16),
          ...cartItems.map((item) => _buildCartItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(Map<String, dynamic> item) {
    final product = item['item'] is Map<String, dynamic>
        ? item['item'] as Map<String, dynamic>
        : null;
    final qty = _safeInt(item['qty'] ?? 1);
    final price = _safeNum(item['price']);
    final total = price * qty;
    final productName = product?['name'] ?? 'Unknown Product';
    final productSku = product?['sku'] ?? '';
    final productPhoto = product?['photo'] ?? '';
    final isKit = item['isKIT'] == 'yes' || item['isKIT'] == true;
    final kitDetails = item['kitCustomiseDetails'] is Map<String, dynamic>
        ? item['kitCustomiseDetails'] as Map<String, dynamic>
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: productPhoto.isNotEmpty
                      ? Image.network(
                          'https://www.gurgaonit.com/apc_production_dev/assets/images/products/$productPhoto',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image, color: Colors.grey[400]);
                          },
                        )
                      : Icon(Icons.image, color: Colors.grey[400]),
                ),
              ),
              const SizedBox(width: 12),
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      productName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (productSku.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'SKU: $productSku',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Qty: $qty',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Unit: ${_formatAmount(price)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatAmount(total),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A365D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Kit Details
          if (isKit && kitDetails != null && kitDetails.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              'Kit Includes:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A365D),
              ),
            ),
            const SizedBox(height: 8),
            ...kitDetails.values.map((kit) {
              final kitName = kit['productName'] ?? '';
              final kitSku = kit['productSku'] ?? '';
              final kitQty = kit['productBaseQuantity'] ?? 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${kitDetails.values.toList().indexOf(kit) + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kitName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (kitSku.isNotEmpty)
                            Text(
                              'SKU: $kitSku',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      'Qty: $kitQty',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A365D),
            ),
          ),
          const Divider(height: 24),
          _buildInfoRow('Payment Status', _orderData!['payment_status'] ?? 'N/A'),
          if (_responseData?['order_status'] != null)
            _buildInfoRow('Order Status', _responseData!['order_status']),
          if (_payments != null && _payments!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Payment History:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            ..._payments!.map((payment) {
              final pAmount = _safeNum(payment['payment_amount']);
              final pDate = _formatDate(payment['payment_date']?.toString());
              final pMethod = payment['payment_method']?.toString() ?? '';
              final pDesc = payment['payment_description']?.toString() ?? '';
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pDate,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        Text(
                          '\$${pAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    if (pMethod.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Method: $pMethod',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                    if (pDesc.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        pDesc,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard() {
    final subtotal = _safeParseAmount(_responseData?['subtotal_excluding_gst']);
    final tax = _safeParseAmount(_responseData?['tax']);
    final discount = _safeParseAmount(_responseData?['discount']);
    final shipping = _safeParseAmount(_responseData?['shipping_cost_including_gst']);
    final grandTotal = _safeNum(_responseData?['grand_total']);
    final amountPaid = _safeNum(_responseData?['amount_paid']);
    final amountDue = _safeNum(_responseData?['amount_due']);
    final currencySign = _responseData?['currency_sign']?.toString() ?? '\$';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A365D),
            ),
          ),
          const Divider(height: 24),
          if (subtotal > 0)
            _buildSummaryRow('Subtotal (Excl. GST)', '$currencySign${subtotal.toStringAsFixed(2)}'),
          if (tax > 0)
            _buildSummaryRow('GST (10%)', '$currencySign${tax.toStringAsFixed(2)}'),
          if (discount > 0)
            _buildSummaryRow('Total Discount', '-$currencySign${discount.toStringAsFixed(2)}',
                valueColor: Colors.red),
          if (shipping > 0)
            _buildSummaryRow('Shipping & Handling', '$currencySign${shipping.toStringAsFixed(2)}'),
          const Divider(height: 16),
          _buildSummaryRow(
            'Grand Total',
            '$currencySign${grandTotal.toStringAsFixed(2)}',
            isTotal: true,
          ),
          if (amountPaid > 0) ...[
            const SizedBox(height: 4),
            _buildSummaryRow(
              'Amount Paid',
              '$currencySign${amountPaid.toStringAsFixed(2)}',
              valueColor: Colors.green,
            ),
          ],
          if (amountDue > 0) ...[
            const SizedBox(height: 4),
            _buildSummaryRow(
              'Amount Due',
              '$currencySign${amountDue.toStringAsFixed(2)}',
              valueColor: Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isTotal = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: valueColor ??
                  (isTotal ? const Color(0xFF1A365D) : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

