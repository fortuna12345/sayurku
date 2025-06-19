import 'package:flutter/material.dart';
import 'package:sayurku/models/order_model.dart';
import 'package:intl/intl.dart';

class OrderCard extends StatelessWidget {
  final Order order;
  final bool isAdmin;
  final Function(String)? onStatusChanged;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.order,
    this.isAdmin = false,
    this.onStatusChanged,
    this.onTap,
  });

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Chip(
                    label: Text(
                      order.status.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    backgroundColor: _getStatusColor(order.status),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(dateFormat.format(order.createdAt)),
              const SizedBox(height: 8),
              Text('Rp ${order.harga.toStringAsFixed(0)}'),
              Text('Payment: ${order.metodePembayaran}'),
              if (isAdmin && onStatusChanged != null) ...[
                const SizedBox(height: 10),
                const Text('Update Status:'),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Processing'),
                      selected: order.status == 'processing',
                      onSelected: (selected) {
                        if (selected) onStatusChanged!('processing');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Completed'),
                      selected: order.status == 'completed',
                      onSelected: (selected) {
                        if (selected) onStatusChanged!('completed');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Cancelled'),
                      selected: order.status == 'cancelled',
                      onSelected: (selected) {
                        if (selected) onStatusChanged!('cancelled');
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
