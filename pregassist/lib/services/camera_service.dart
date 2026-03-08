import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Service that manages background front-camera session and snapshot capture.
/// All methods are wrapped in try-catch to ensure failures don't disrupt the app.
class CameraService {
  CameraController? _controller;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  CameraController? get controller => _controller;

  /// Initialize the front camera. Returns true if successful.
  Future<bool> initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('CameraService: No cameras available');
        return false;
      }

      // Find front camera
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset
            .low, // Low resolution for snapshots to minimize resource usage
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      _isInitialized = true;
      debugPrint('CameraService: Front camera initialized successfully');
      return true;
    } catch (e) {
      debugPrint('CameraService: Failed to initialize camera: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Capture a snapshot and return it as a base64-encoded JPEG string.
  /// Returns null if capture fails. The temp file is deleted immediately.
  Future<String?> captureSnapshot() async {
    if (!_isInitialized || _controller == null) {
      debugPrint('CameraService: Cannot capture - camera not initialized');
      return null;
    }

    try {
      final XFile imageFile = await _controller!.takePicture();
      final bytes = await imageFile.readAsBytes();

      // Delete the temporary file immediately
      try {
        final file = File(imageFile.path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        debugPrint('CameraService: Failed to delete temp file: $e');
      }

      final base64Image = base64Encode(bytes);
      debugPrint(
        'CameraService: Snapshot captured (${bytes.length} bytes, '
        '${base64Image.length} chars base64)',
      );
      return base64Image;
    } catch (e) {
      debugPrint('CameraService: Failed to capture snapshot: $e');
      return null;
    }
  }

  /// Stop the camera and release all resources.
  Future<void> dispose() async {
    try {
      if (_controller != null) {
        if (_controller!.value.isInitialized) {
          await _controller!.dispose();
        }
        _controller = null;
      }
      _isInitialized = false;
      debugPrint('CameraService: Disposed');
    } catch (e) {
      debugPrint('CameraService: Error during dispose: $e');
      _controller = null;
      _isInitialized = false;
    }
  }
}
