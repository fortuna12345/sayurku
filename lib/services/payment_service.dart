class PaymentService {
  String generateQRISData(double amount, String merchantName) {
    return '''
00020101021126680014ID.CO.QRIS.WWW01189360091400001189980202UM15200001189980303UMI51440014ID.CO.QRIS.WWW0215ID1020014868680303UMI5204581253033605405${amount.toStringAsFixed(2)}5802ID5914${merchantName}6007JAKARTA610510140623305${DateTime.now().millisecondsSinceEpoch}6304
'''.replaceAll(RegExp(r'\s+'), ''); // Remove whitespace
  }
}
