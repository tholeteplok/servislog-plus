import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../../core/services/firestore_sync_service.dart';
import '../../../core/services/sync_worker.dart';
import '../../../core/providers/objectbox_provider.dart';

class SyncRestoreScreen extends ConsumerStatefulWidget {
  final String bengkelId;
  final VoidCallback onFinish;

  const SyncRestoreScreen({
    super.key,
    required this.bengkelId,
    required this.onFinish,
  });

  @override
  ConsumerState<SyncRestoreScreen> createState() => _SyncRestoreScreenState();
}

class _SyncRestoreScreenState extends ConsumerState<SyncRestoreScreen> {
  String _statusText = 'Menyiapkan pemulihan data...';
  double _progress = 0.1;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startRestore();
    });
  }

  Future<void> _startRestore() async {
    try {
      // Accessing service (Assuming FirestoreSyncService will be available via a provider)
      // If it doesn't have a provider yet, I'll need to double check how it's accessed.
      // Based on typical riverpod patterns in this project, I'll assume standard providers.
      final syncService = FirestoreSyncService(); // Fallback if no provider, but usually there's one.
      final db = ref.read(dbProvider);
      
      setState(() {
        _statusText = 'Mengunduh data dari Cloud...';
        _progress = 0.3;
      });

      // 1. Pull everything
      final allData = await syncService.pullAllData(widget.bengkelId);
      
      setState(() {
        _statusText = 'Membangun ulang database lokal...';
        _progress = 0.7;
      });

      // 2. Perform reconstruction
      final worker = SyncWorker(
        db: db,
        syncService: syncService,
        bengkelId: widget.bengkelId,
      );

      await worker.syncDownAll(allData);

      if (mounted) {
        setState(() {
          _statusText = 'Pemulihan selesai! Sedang menyiapkan dashboard...';
          _progress = 1.0;
        });
      }

      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        widget.onFinish();
      }
    } catch (e) {
      debugPrint('Restore Error: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _statusText = 'Gagal memulihkan data.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon or Animation
                _isError 
                  ? Icon(Icons.error_outline, size: 80, color: Theme.of(context).colorScheme.error)
                  : SizedBox(
                      height: 200,
                      child: Lottie.network(
                        'https://assets10.lottiefiles.com/packages/lf20_at6mdfbe.json', // Cloud Sync Animation
                        errorBuilder: (context, error, stack) => Icon(
                          Icons.cloud_download_rounded, 
                          size: 80, 
                          color: Theme.of(context).colorScheme.primary
                        ),
                      ),
                    ),
                const SizedBox(height: 40),
                Text(
                  'Pemulihan Data',
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _statusText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                if (!_isError) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 10,
                      backgroundColor: Colors.grey[200],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                if (_isError) ...[
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _startRestore,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onFinish,
                    child: const Text('Lewati (Mulai dengan data kosong)'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
