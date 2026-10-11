import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import 'customer_photo_store.dart';

/// Opens the laptop camera only after Take Photo is pressed, then returns a JPEG.
Future<Uint8List?> captureCustomerPhoto(BuildContext context) {
  return showDialog<Uint8List>(
    context: context,
    builder: (context) => const _LaptopCameraDialog(),
  );
}

class _LaptopCameraDialog extends StatefulWidget {
  const _LaptopCameraDialog();

  @override
  State<_LaptopCameraDialog> createState() => _LaptopCameraDialogState();
}

class _LaptopCameraDialogState extends State<_LaptopCameraDialog> {
  web.MediaStream? _stream;
  web.HTMLVideoElement? _video;
  String? _error;
  bool _starting = true;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _closed = true;
    _stop();
    super.dispose();
  }

  Future<void> _start() async {
    try {
      final stream = await web.window.navigator.mediaDevices
          .getUserMedia(
            web.MediaStreamConstraints(
              audio: false.toJS,
              video: web.MediaTrackConstraints(facingMode: 'user'.toJS),
            ),
          )
          .toDart;
      if (!mounted || _closed) {
        _stopStream(stream);
        return;
      }
      setState(() {
        _stream = stream;
        _starting = false;
      });
      _attach(stream);
    } catch (error) {
      if (!mounted || _closed) return;
      setState(() {
        _starting = false;
        _error = _message(error);
      });
    }
  }

  void _attach(web.MediaStream stream) {
    final video = _video;
    if (video == null) return;
    video.srcObject = stream;
    video.play();
  }

  void _bindVideo(Object element) {
    final video = element as web.HTMLVideoElement;
    video.autoplay = true;
    video.muted = true;
    video.setAttribute('playsinline', 'true');
    video.style
      ..width = '100%'
      ..height = '100%'
      ..transform = 'scaleX(-1)'
      ..setProperty('object-fit', 'cover');
    _video = video;
    final stream = _stream;
    if (stream != null) _attach(stream);
  }

  void _capture() {
    final video = _video;
    final width = video?.videoWidth ?? 0;
    final height = video?.videoHeight ?? 0;
    if (video == null || width == 0 || height == 0) {
      setState(() => _error = 'The camera is still starting. Try again in a moment.');
      return;
    }

    final canvas = web.HTMLCanvasElement()
      ..width = width
      ..height = height;
    final canvasContext = canvas.getContext('2d') as web.CanvasRenderingContext2D;
    canvasContext.translate(width.toDouble(), 0);
    canvasContext.scale(-1, 1);
    canvasContext.drawImage(video, 0, 0, width, height);
    final dataUrl = canvas.toDataURL('image/jpeg', 0.9.toJS);
    final comma = dataUrl.indexOf(',');
    if (comma < 0) {
      setState(() => _error = 'The photo could not be captured.');
      return;
    }
    final bytes = base64Decode(dataUrl.substring(comma + 1));
    final invalid = validateCustomerPhoto(bytes);
    if (invalid != null) {
      setState(() => _error = invalid);
      return;
    }
    _stop();
    Navigator.of(context).pop(Uint8List.fromList(bytes));
  }

  void _stop() {
    final stream = _stream;
    _stream = null;
    _video?.srcObject = null;
    if (stream != null) _stopStream(stream);
  }

  void _stopStream(web.MediaStream stream) {
    for (final track in stream.getTracks().toDart) {
      track.stop();
    }
  }

  String _message(Object error) {
    final text = error.toString();
    if (text.contains('NotAllowed') || text.contains('Permission')) {
      return 'Camera access was denied. You can still choose a photo.';
    }
    if (text.contains('NotFound') || text.contains('NotReadable')) {
      return 'No camera could be started. You can still choose a photo.';
    }
    return 'The camera could not be started. You can still choose a photo.';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Take photo'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 320,
              child: ColoredBox(
                color: const Color(0xff111111),
                child: _starting
                    ? const Center(child: CircularProgressIndicator())
                    : _stream == null
                        ? const Center(
                            child: Icon(Icons.videocam_off_outlined, color: Colors.white70, size: 48),
                          )
                        : HtmlElementView.fromTagName(
                            tagName: 'video',
                            onElementCreated: _bindVideo,
                          ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _stop();
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _stream == null ? null : _capture,
          child: const Text('Capture'),
        ),
      ],
    );
  }
}
