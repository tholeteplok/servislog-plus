import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/sale.dart';
import 'package:intl/intl.dart';

class DocumentService {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Share WhatsApp Receipt (Text based)
  static Future<void> shareWhatsApp({
    required String phone,
    Transaction? transaction,
    List<Sale>? sales,
    required String bengkelName,
  }) async {
    final String message = _buildWhatsAppMessage(
      transaction: transaction,
      sales: sales,
      bengkelName: bengkelName,
    );

    final String url =
        "whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      // Fallback for web or if app is not installed
      final String webUrl =
          "https://wa.me/$phone?text=${Uri.encodeComponent(message)}";
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    }
  }

  /// Send WhatsApp Service Reminder
  static Future<void> sendReminderWhatsApp({
    required String phone,
    required Transaction transaction,
    required String bengkelName,
  }) async {
    final nextDate = transaction.nextServiceDate;
    final dateStr = nextDate != null
        ? DateFormat('dd MMM yyyy').format(nextDate)
        : '-';
    final targetKm = transaction.targetServiceKm;
    final kmStr = targetKm != null ? " atau saat KM mencapai $targetKm" : "";

    final String message =
        "Halo kak *${transaction.customerName}*, kami dari *$bengkelName*. 🛠️\n\n"
        "Ingin mengingatkan bahwa kendaraan *${transaction.vehicleModel}* (${transaction.vehiclePlate}) sudah memasuki waktu servis berkala berikutnya (estimasi sekitar tanggal $dateStr$kmStr).\n\n"
        "Yuk kak, jadwalkan servisnya agar kendaraan tetap prima dan nyaman dikendarai! Kami tunggu kedatangannya ya. 😊";

    // Basic phone cleaning
    String cleanedPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanedPhone.startsWith('0')) {
      cleanedPhone = '62${cleanedPhone.substring(1)}';
    }

    final String url =
        "whatsapp://send?phone=$cleanedPhone&text=${Uri.encodeComponent(message)}";
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      final String webUrl =
          "https://wa.me/$cleanedPhone?text=${Uri.encodeComponent(message)}";
      await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
    }
  }

  static String _buildWhatsAppMessage({
    Transaction? transaction,
    List<Sale>? sales,
    required String bengkelName,
  }) {
    final sb = StringBuffer();
    sb.writeln("*NOTA PEMBAYARAN - $bengkelName*");
    sb.writeln("-----------------------------------------");

    if (transaction != null) {
      sb.writeln("No. Transaksi: ${transaction.trxNumber}");
      sb.writeln(
        "Kendaraan: ${transaction.vehicleModel} (${transaction.vehiclePlate})",
      );
      sb.writeln("Pelanggan: ${transaction.customerName}");
      sb.writeln("");
      sb.writeln("*Detail:*");
      for (var item in transaction.items) {
        sb.writeln(
          "- ${item.name} x${item.quantity}: ${_currencyFormat.format(item.price * item.quantity)}",
        );
      }
      sb.writeln("-----------------------------------------");
      sb.writeln("*TOTAL: ${_currencyFormat.format(transaction.totalAmount)}*");
    } else if (sales != null && sales.isNotEmpty) {
      sb.writeln("Jenis: Penjualan Barang");
      sb.writeln("Customer: ${sales.first.customerName ?? 'Umum'}");
      sb.writeln("");
      sb.writeln("*Detail:*");
      for (var s in sales) {
        sb.writeln(
          "- ${s.itemName} x${s.quantity}: ${_currencyFormat.format(s.totalPrice)}",
        );
      }
      sb.writeln("-----------------------------------------");
      final total = sales.fold(0, (sum, item) => sum + item.totalPrice);
      sb.writeln("*TOTAL: ${_currencyFormat.format(total)}*");
    }
    if (transaction != null) {
      final notes = transaction.mechanicNotes ?? "Servis selesai.";
      sb.writeln("");
      sb.writeln("*Catatan Teknisi:*");
      sb.writeln(notes);

      final recKm = transaction.recommendationKm;
      final recTime = transaction.recommendationTimeMonth;
      if (recKm != null || recTime != null) {
        sb.writeln("");
        sb.writeln("*Rekomendasi Servis Kembali:*");
        if (recKm != null) sb.writeln("- Setelah +$recKm KM");
        if (recTime != null) sb.writeln("- Setelah +$recTime Bulan");
      } else {
        sb.writeln("");
        sb.writeln("*Rekomendasi Servis Kembali:*");
        sb.writeln("Cek kembali 1 bulan/1000 KM.");
      }
    }

    sb.writeln("");
    sb.writeln("Terima kasih telah mempercayakan kendaraan Anda kepada kami!");
    return sb.toString();
  }

  /// Generate and Print/Share PDF Receipt
  static Future<void> generateAndPrint({
    Transaction? transaction,
    List<Sale>? sales,
    required String bengkelName,
    String? address,
    bool isThermal = true,
    bool isShare = false,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

    pdf.addPage(
      pw.Page(
        pageFormat: isThermal
            ? const PdfPageFormat(58 * PdfPageFormat.mm, double.infinity)
            : PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text(
                  bengkelName,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: isThermal ? 12 : 20,
                  ),
                ),
              ),
              if (address != null)
                pw.Center(
                  child: pw.Text(
                    address,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              pw.Divider(),
              pw.Text(
                "Tanggal: $dateStr",
                style: const pw.TextStyle(fontSize: 9),
              ),
              if (transaction != null) ...[
                pw.Text(
                  "No: ${transaction.trxNumber}",
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  "Unit: ${transaction.vehicleModel} (${transaction.vehiclePlate})",
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Divider(),
                ...transaction.items.map(
                  (item) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "${item.name} x${item.quantity}",
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        _currencyFormat.format(item.price * item.quantity),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "TOTAL",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      _currencyFormat.format(transaction.totalAmount),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  "LAPORAN TEKNISI:",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
                pw.Text(
                  transaction.mechanicNotes ?? "Servis selesai.",
                  style: const pw.TextStyle(fontSize: 8),
                ),

                pw.SizedBox(height: 8),
                pw.Text(
                  "REKOMENDASI SERVIS:",
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
                if (transaction.recommendationKm == null &&
                    transaction.recommendationTimeMonth == null)
                  pw.Text(
                    "Cek kembali 1 bulan/1000 KM.",
                    style: const pw.TextStyle(fontSize: 8),
                  )
                else ...[
                  if (transaction.recommendationKm != null)
                    pw.Text(
                      "- +${transaction.recommendationKm} KM",
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  if (transaction.recommendationTimeMonth != null)
                    pw.Text(
                      "- +${transaction.recommendationTimeMonth} Bulan",
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                ],
              ] else if (sales != null && sales.isNotEmpty) ...[
                pw.Text(
                  "Penjualan Barang",
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Divider(),
                ...sales.map(
                  (s) => pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        "${s.itemName} x${s.quantity}",
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                      pw.Text(
                        _currencyFormat.format(s.totalPrice),
                        style: const pw.TextStyle(fontSize: 9),
                      ),
                    ],
                  ),
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      "TOTAL",
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    pw.Text(
                      _currencyFormat.format(
                        sales.fold(0, (sum, item) => sum + item.totalPrice),
                      ),
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.Text(
                  "TERIMA KASIH",
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (isShare) {
      final bytes = await pdf.save();
      await Share.shareXFiles([
        XFile.fromData(
          bytes,
          name: 'Nota-$dateStr.pdf',
          mimeType: 'application/pdf',
        ),
      ]);
    } else {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
  }
}
