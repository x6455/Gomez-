import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:url_launcher/url_launcher.dart';

class ReceiptServer {
  static HttpServer? _server;
  static String? _fullImagePath;
  static String? _croppedImagePath;

  static const VIEWPORT_WIDTH = 1000;
  static const VIEWPORT_HEIGHT = 1800;
  static const CROP_HEIGHT = 1150;

  static Future<void> start({
    required String txID,
    required String time,
    required String amountSent,
    required String serviceCharge,
    required String vat,
    required String totalDeducted,
    required String bankName,
    required String accountName,
    required String accountNumber,
  }) async {
    final dir = await getTemporaryDirectory();
    _fullImagePath = '${dir.path}/receipt_full_$txID.png';
    _croppedImagePath = '${dir.path}/receipt_cropped_$txID.png';

    // Start HTTP server
    final handler = _createHandler(txID);
    _server = await io.serve(handler, '127.0.0.1', 3000);

    // Open browser
    await launchUrl(
      Uri.parse('http://127.0.0.1:3000'),
      mode: LaunchMode.externalApplication,
    );
  }

  static Handler _createHandler(String txID) {
    return (Request request) async {
      final path = request.url.path;

      if (path == '/' || path == '') {
        return Response.ok(
          _buildHtml(txID),
          headers: {'Content-Type': 'text/html; charset=utf-8'},
        );
      }

      if (path == '/full.png') {
        final bytes = await File(_fullImagePath!).readAsBytes();
        return Response.ok(bytes, headers: {'Content-Type': 'image/png'});
      }

      if (path == '/cropped.png') {
        final bytes = await File(_croppedImagePath!).readAsBytes();
        return Response.ok(bytes, headers: {'Content-Type': 'image/png'});
      }

      return Response.notFound('Not found');
    };
  }

  static String _buildHtml(String txID) {
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Receipt Preview</title>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/jspdf/2.5.1/jspdf.umd.min.js"></script>
    <style>
        body { margin:0; background:#2c2c2c; display:flex; flex-direction:column; align-items:center; font-family:-apple-system,sans-serif; }
        .container { position:relative; margin:40px 0; background:white; box-shadow:0 10px 30px rgba(0,0,0,0.5); }
        #preview-img { display:block; width:${VIEWPORT_WIDTH}px; height:auto; }
        .download-btn {
            position:fixed; top:20px; right:20px;
            background:#667eea; color:white; border:none;
            padding:15px 30px; font-size:16px; border-radius:8px;
            cursor:pointer; z-index:1000; font-weight:600;
        }
    </style>
</head>
<body>
    <button class="download-btn" onclick="downloadPDF()">📥 Download PDF</button>
    <div class="container">
        <img id="preview-img" src="/full.png" />
    </div>
    <script>
        async function downloadPDF() {
            const { jsPDF } = window.jspdf;
            const pdf = new jsPDF({ orientation:'portrait', unit:'px', format:[${VIEWPORT_WIDTH}, ${CROP_HEIGHT}] });
            pdf.addImage('/cropped.png', 'PNG', 0, 0, ${VIEWPORT_WIDTH}, ${CROP_HEIGHT});
            pdf.save("Receipt_${txID}.pdf");
        }
    </script>
</body>
</html>
    ''';
  }

  static void stop() {
    _server?.close();
    _server = null;
  }
}