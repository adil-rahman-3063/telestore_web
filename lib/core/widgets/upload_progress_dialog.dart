import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import '../../api_service.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import 'glass_container.dart';
import 'glass_snackbar.dart';

class UploadProgressDialog extends StatefulWidget {
  final List<PlatformFile> files;
  final String userId;
  final String folderId;
  final Function(bool hasError) onComplete;

  const UploadProgressDialog({
    Key? key, 
    required this.files, 
    required this.userId,
    required this.folderId,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<UploadProgressDialog> createState() => _UploadProgressDialogState();
}

class _UploadProgressDialogState extends State<UploadProgressDialog> {
  int _completedCount = 0;
  String _currentFileName = '';
  
  int _totalBytes = 0;
  int _uploadedBytes = 0;
  DateTime? _startTime;
  String _timeRemaining = 'Calculating time remaining...';
  
  List<PlatformFile> _queue = [];
  List<PlatformFile> _failedFiles = [];
  bool _showingErrors = false;
  
  double _displayProgress = 0.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _queue = List.from(widget.files);
    _calculateTotals();
    
    // Starts an asymptotic fake progress to prevent anxiety
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), _updateFakeProgress);
    
    _startUpload();
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _updateFakeProgress(Timer timer) {
    if (_queue.isEmpty || _showingErrors) return;

    final total = _queue.length;
    // Target is 95% of the way through the CURRENT file chunk
    final targetFauxProgress = (_completedCount + 0.95) / total;
    
    if (_displayProgress < targetFauxProgress) {
      setState(() {
        // Move 2% of the remaining distance to the target every 100ms
        _displayProgress += (targetFauxProgress - _displayProgress) * 0.02;
      });
    }
  }

  void _calculateTotals() {
    _totalBytes = 0;
    for (var file in _queue) {
      _totalBytes += file.size;
    }
    _startTime = DateTime.now();
  }

  void _updateTimeRemaining() {
    if (_uploadedBytes == 0 || _startTime == null) return;
    
    final elapsed = DateTime.now().difference(_startTime!);
    final bytesPerMs = _uploadedBytes / elapsed.inMilliseconds;
    
    if (bytesPerMs > 0) {
      final remainingBytes = _totalBytes - _uploadedBytes;
      final remainingMs = remainingBytes / bytesPerMs;
      final remainingSeconds = (remainingMs / 1000).ceil();
      
      if (remainingSeconds == 0) {
        _timeRemaining = 'Finishing up...';
      } else if (remainingSeconds < 60) {
        _timeRemaining = 'About ${remainingSeconds}s remaining';
      } else {
        final mins = remainingSeconds ~/ 60;
        _timeRemaining = 'About $mins min remaining';
      }
    }
  }

  Future<void> _startUpload() async {
    for (int i = 0; i < _queue.length; i++) {
      if (!mounted) return;
      
      setState(() {
        _currentFileName = _queue[i].name;
      });
      
      final file = _queue[i];
      final success = await ApiService.uploadFile(
        widget.userId,
        file.name,
        filePath: file.path,
        bytes: file.bytes,
        folderId: widget.folderId == 'root' ? null : widget.folderId,
      );
      
      if (!success) {
        _failedFiles.add(file);
      }
      
      _uploadedBytes += file.size;
      
      if (mounted) {
        setState(() {
          _completedCount = i + 1;
          _displayProgress = _completedCount / _queue.length; // Snap exactly to boundary
          _updateTimeRemaining();
        });
      }
    }
    
    if (mounted) {
      widget.onComplete(_failedFiles.isNotEmpty);
      if (_failedFiles.isNotEmpty) {
        setState(() {
          _showingErrors = true;
        });
      } else {
        Navigator.pop(context); // Close if fully successful
      }
    }
  }

  void _retryFailed() {
    setState(() {
      _queue = List.from(_failedFiles);
      _failedFiles.clear();
      _showingErrors = false;
      _completedCount = 0;
      _displayProgress = 0.0;
      _uploadedBytes = 0;
      _timeRemaining = 'Calculating time remaining...';
      _calculateTotals();
    });
    _startUpload();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_showingErrors) {
      return Dialog(
        backgroundColor: Colors.transparent,
        child: GlassContainer(
          padding: const EdgeInsets.all(24),
          borderRadius: 24,
          backgroundColor: isDark ? Colors.black.withAlpha(150) : Colors.white.withAlpha(200),
          borderColor: isDark ? Colors.white.withAlpha(30) : Colors.white.withAlpha(150),
          blur: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
                  const SizedBox(width: 12),
                  Text('Upload Errors', style: AppTypography.h3),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_failedFiles.length} file(s) failed to upload:',
                style: AppTypography.bodyMedium,
              ),
              const SizedBox(height: 16),
              Container(
                constraints: const BoxConstraints(maxHeight: 150),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withAlpha(50) : Colors.white.withAlpha(100),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: _failedFiles.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        _failedFiles[index].name,
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      final names = _failedFiles.map((f) => f.name).join('\n');
                      Clipboard.setData(ClipboardData(text: names));
                      GlassSnackBar.show(context, 'Copied to clipboard', type: GlassSnackBarType.success);
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copy'),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Close', style: TextStyle(color: isDark ? Colors.white70 : AppColors.grey500)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _retryFailed,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final percentage = (_displayProgress * 100).toInt();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassContainer(
        padding: const EdgeInsets.all(32),
        borderRadius: 24,
        backgroundColor: isDark ? Colors.black.withAlpha(150) : Colors.white.withAlpha(200),
        borderColor: isDark ? Colors.white.withAlpha(30) : Colors.white.withAlpha(150),
        blur: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Uploading ($percentage%)', style: AppTypography.h3.copyWith(color: isDark ? Colors.white : AppColors.primaryDark)),
            const SizedBox(height: 16),
            Text(_currentFileName, style: AppTypography.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _displayProgress,
                minHeight: 8,
                backgroundColor: isDark ? Colors.white24 : Colors.black12,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _timeRemaining,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
