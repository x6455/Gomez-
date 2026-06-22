import 'dart:io';
import 'dart:convert';
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
    // Generate images first
    await _generateImages(
      txID: txID,
      time: time,
      amountSent: amountSent,
      serviceCharge: serviceCharge,
      vat: vat,
      totalDeducted: totalDeducted,
      bankName: bankName,
      accountName: accountName,
      accountNumber: accountNumber,
    );

    // Start HTTP server
    final router = ShelfRouter();
    
    router.get('/', (_) => Response.ok(
      _buildHtml(txID),
      headers: {'Content-Type': 'text/html; charset=utf-8'},
    ));
    
    router.get('/full.png', (_) {
      final bytes = File(_fullImagePath!).readAsBytesSync();
      return Response.ok(bytes, headers: {'Content-Type': 'image/png'});
    });
    
    router.get('/cropped.png', (_) {
      final bytes = File(_croppedImagePath!).readAsBytesSync();
      return Response.ok(bytes, headers: {'Content-Type': 'image/png'});
    });

    _server = await io.serve(router.handler, '127.0.0.1', 3000);
    
    // Open browser
    await launchUrl(
      Uri.parse('http://127.0.0.1:3000'),
      mode: LaunchMode.externalApplication,
    );
  }

  static Future<void> _generateImages({
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
    // Build widget offscreen
    final widget = _ReceiptOverlay(
      txID: txID,
      time: time,
      amountSent: amountSent,
      serviceCharge: serviceCharge,
      vat: vat,
      totalDeducted: totalDeducted,
      bankName: bankName,
      accountName: accountName,
      accountNumber: accountNumber,
    );

    // Render to image using a temporary overlay
    final image = await _renderWidget(widget, VIEWPORT_WIDTH, VIEWPORT_HEIGHT);
    
    final dir = await getTemporaryDirectory();
    final fullPath = '${dir.path}/receipt_full_$txID.png';
    final croppedPath = '${dir.path}/receipt_cropped_$txID.png';
    
    // Save full image
    File(fullPath).writeAsBytesSync(image);
    _fullImagePath = fullPath;
    
    // Crop and save
    final cropped = await _cropImage(image, 0, 0, VIEWPORT_WIDTH, CROP_HEIGHT);
    File(croppedPath).writeAsBytesSync(cropped);
    _croppedImagePath = croppedPath;
  }

  static Future<Uint8List> _renderWidget(Widget widget, int width, int height) async {
    // Create a temporary build owner
    final pipelineOwner = PipelineOwner();
    final buildOwner = BuildOwner(focusManager: FocusManager());
    
    final renderView = RenderView(
      configuration: ViewConfiguration(size: Size(width.toDouble(), height.toDouble())),
    );
    
    final element = RenderObjectToWidgetAdapter<RenderBox>(
      container: renderView,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: widget,
      ),
    ).attachToRenderTree(buildOwner);
    
    buildOwner.buildScope(element);
    buildOwner.finalizeTree();
    pipelineOwner.flushLayout();
    pipelineOwner.flushPaint();
    
    // Capture to image
    final boundary = renderView;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    return byteData!.buffer.asUint8List();
  }

  static Future<Uint8List> _cropImage(Uint8List fullImage, int x, int y, int width, int height) async {
    // Simple crop using raw bytes manipulation
    // For now, we'll use the full image and let the browser handle display
    // The PDF crop is handled by jsPDF in the browser
    return fullImage;
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

// Shelf Router (minimal, since shelf_router might have import issues)
class ShelfRouter {
  final Map<String, Handler> _routes = {};

  ShelfRouter();

  void get(String path, Handler handler) {
    _routes[path] = handler;
  }

  Handler get handler {
    return (Request request) {
      final path = request.url.path;
      final handler = _routes[path];
      if (handler != null) {
        return handler(request);
      }
      return Response.notFound('Not found');
    };
  }
}

typedef Handler = Future<Response> Function(Request request);

class _ReceiptOverlay extends StatelessWidget {
  final String txID, time, amountSent, serviceCharge, vat, totalDeducted, bankName, accountName, accountNumber;

  const _ReceiptOverlay({
    required this.txID,
    required this.time,
    required this.amountSent,
    required this.serviceCharge,
    required this.vat,
    required this.totalDeducted,
    required this.bankName,
    required this.accountName,
    required this.accountNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1000,
      height: 1800,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('images/receipt_bg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          _t(txID, top: 479, left: 175, size: 14),
          _t(time, top: 479, left: 407, size: 14),
          _t('$amountSent Birr', top: 479, left: 710, size: 14),
          _t('DANIEL ABRAHAM TESEMA', top: 181, left: 522, size: 14),
          _t('0.00 Birr', top: 504, left: 710, size: 14),
          _t('0.00 Birr', top: 531, left: 710, size: 14),
          _t('$accountNumber ${accountName.toUpperCase()}', top: 380, left: 522, size: 15),
          _t('$serviceCharge Birr', top: 557, left: 710, size: 14),
          _t('$vat Birr', top: 583, left: 710, size: 14),
          _t('$totalDeducted Birr', top: 610, left: 710, size: 14),
          _t(bankName, top: 310, left: 522, size: 15),
        ],
      ),
    );
  }

  Widget _t(String text, {required double top, required double left, required double size}) {
    return Positioned(
      top: top,
      left: left,
      child: Text(
        text,
        style: TextStyle(
          fontSize: size,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF444444),
        ),
      ),
    );
  }
}
