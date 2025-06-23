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

  // Diubah menjadi publik (menghapus '_')
  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange.shade700;
      case 'processing':
        return Colors.blue.shade700;
      case 'packing':
        return Colors.purple.shade700;
      case 'delivering':
        return Colors.teal.shade700;
      case 'completed':
        return Colors.green.shade700;
      case 'cancelled':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  // Diubah menjadi publik (menghapus '_')
  String getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'processing':
        return 'Sedang Diproses';
      case 'packing':
        return 'Sedang Dikemas';
      case 'delivering':
        return 'Sedang Diantar';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');

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
                      getStatusText(order.status), // Sekarang memanggil metode publik
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: getStatusColor(order.status), // Sekarang memanggil metode publik
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(dateFormat.format(order.createdAt)),
              const SizedBox(height: 8),
              Text('Rp ${order.harga.toStringAsFixed(0)}'),
              Text('Payment: ${order.metodePembayaran}'),
              if (isAdmin && onStatusChanged != null) ...[
                const Divider(height: 20),
                const Text('Update Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ChoiceChip(
                      label: const Text('Diproses'),
                      selected: order.status == 'processing',
                      onSelected: (selected) {
                        if (selected) onStatusChanged!('processing');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Dikemas'),
                      selected: order.status == 'packing',
                      onSelected: (selected) {
                        if (selected) onStatusChanged!('packing');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Diantar'),
                      selected: order.status == 'delivering',
                      onSelected: (selected) {
                        if (selected) onStatusChanged!('delivering');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Selesai'),
                      selected: order.status == 'completed',
                      onSelected: (selected) {
                        if (selected) onStatusChanged!('completed');
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Batal'),
                      selected: order.status == 'cancelled',
                      backgroundColor: Colors.red[50],
                      selectedColor: Colors.red,
                      labelStyle: TextStyle(color: order.status == 'cancelled' ? Colors.white : Colors.red),
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