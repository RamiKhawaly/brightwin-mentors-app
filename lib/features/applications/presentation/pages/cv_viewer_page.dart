import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/network/dio_client.dart';

class CVViewerPage extends StatefulWidget {
  final int cvId;
  final String cvFileName;

  const CVViewerPage({
    super.key,
    required this.cvId,
    this.cvFileName = 'CV Document',
  });

  @override
  State<CVViewerPage> createState() => _CVViewerPageState();
}

class _CVViewerPageState extends State<CVViewerPage> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _localFilePath;
  late final DioClient _dioClient;

  @override
  void initState() {
    super.initState();
    _dioClient = DioClient(const FlutterSecureStorage());
    _downloadAndCacheCV();
  }

  Future<void> _downloadAndCacheCV() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('🔍 [CV VIEWER] Starting CV download');
      print('   CV ID: ${widget.cvId}');
      print('   CV FileName: ${widget.cvFileName}');

      // Construct the download URL using CV ID
      // Note: This endpoint is public by design (no auth required) so CVs can be shared
      final downloadUrl = '/api/cv/download/${widget.cvId}';

      print('   📡 Download URL: $downloadUrl');

      // Download the CV file using authenticated DioClient
      final response = await _dioClient.dio.get(
        downloadUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      print('   📦 Response status: ${response.statusCode}');
      print('   📦 Response data size: ${response.data?.length ?? 0} bytes');

      if (response.statusCode != 200) {
        throw Exception('Failed to download CV: HTTP ${response.statusCode}');
      }

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = widget.cvFileName.endsWith('.pdf')
          ? widget.cvFileName
          : '${widget.cvFileName}.pdf';
      final filePath = '${tempDir.path}/$fileName';

      print('   💾 Saving to: $filePath');

      // Save file to temporary storage
      final file = File(filePath);
      await file.writeAsBytes(response.data);

      print('   ✅ CV downloaded and cached successfully');

      if (mounted) {
        setState(() {
          _localFilePath = filePath;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('   ❌ Error downloading CV: $e');
      print('   Stack trace: $stackTrace');

      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load CV: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cvFileName),
        actions: [
          if (!_isLoading && _localFilePath != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _downloadAndCacheCV,
              tooltip: 'Reload CV',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading CV...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _downloadAndCacheCV,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_localFilePath != null) {
      return SfPdfViewer.file(
        File(_localFilePath!),
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        onDocumentLoadFailed: (details) {
          print('❌ PDF load failed: ${details.error}');
          print('   Description: ${details.description}');
          setState(() {
            _errorMessage = 'Failed to load PDF: ${details.description}';
            _localFilePath = null;
          });
        },
      );
    }

    return const Center(
      child: Text('No CV to display'),
    );
  }

  @override
  void dispose() {
    // Clean up temporary file if needed
    if (_localFilePath != null) {
      try {
        final file = File(_localFilePath!);
        if (file.existsSync()) {
          file.deleteSync();
        }
      } catch (e) {
        print('Failed to delete temp CV file: $e');
      }
    }
    super.dispose();
  }
}
