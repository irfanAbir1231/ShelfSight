import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/audit_flow.dart';
import '../models/demo_result.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/onboarding_widgets.dart';
import '../widgets/photo_image.dart';
import 'review_screen.dart';

/// Live camera. The preview starts as soon as the screen opens.
class CaptureScreen extends StatefulWidget {
  const CaptureScreen({
    super.key,
    required this.storeName,
    this.returnToReview = false,
  });
  final String storeName;

  /// When opened from Review ("Add another photo"), the Review button pops
  /// instead of pushing a second Review screen.
  final bool returnToReview;

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen>
    with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  late final AuditFlow _flow = AuditFlow.forShop(widget.storeName);
  CameraController? _camera;
  String? _cameraError;
  bool _initializing = false;
  bool _capturing = false;
  bool _flash = false;
  int _selected = -1;

  List<String> get _photos => _flow.photos.value;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _flow.photos.addListener(_onPhotos);
    _initCamera();
  }

  void _onPhotos() {
    if (!mounted) return;
    setState(() {
      if (_selected >= _photos.length) _selected = _photos.length - 1;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed && _camera == null) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (_initializing) return;
    _initializing = true;
    if (mounted) setState(() => _cameraError = null);
    try {
      final cameras = await availableCameras().timeout(
        const Duration(seconds: 6),
      );
      if (cameras.isEmpty) {
        throw CameraException('noCamera', 'No camera found');
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      await controller.setFlashMode(FlashMode.off);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _camera = controller;
        _flash = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraError = e.code == 'CameraAccessDenied'
            ? 'Camera permission is needed to capture the shelf.'
            : 'The camera could not start. Try again, or use the gallery.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'The camera could not start. Try again, or use the gallery.';
      });
    } finally {
      _initializing = false;
    }
  }

  Future<void> _disposeCamera() async {
    final c = _camera;
    _camera = null;
    if (c != null) await c.dispose();
  }

  Future<void> _toggleFlash() async {
    final c = _camera;
    if (c == null || !c.value.isInitialized) return;
    final on = !_flash;
    try {
      await c.setFlashMode(on ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _flash = on);
    } on CameraException {
      _toast('Flash is not available on this camera.');
    }
  }

  Future<void> _capture() async {
    final c = _camera;
    if (c == null ||
        !c.value.isInitialized ||
        c.value.isTakingPicture ||
        _capturing) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final shot = await c.takePicture();
      _flash = false;
      _flow.add([shot.path]);
      if (mounted) setState(() => _selected = _photos.length - 1);
    } on CameraException {
      _toast('The photo could not be captured. Try again.');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _gallery() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 88,
      maxWidth: 2400,
    );
    if (picked.isEmpty) return;
    _flow.add(picked.map((p) => p.path));
    if (mounted) setState(() => _selected = _photos.length - 1);
  }

  void _deleteSelected() {
    if (_selected < 0 || _selected >= _photos.length) return;
    _flow.removeAt(_selected);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _help() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => const SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(22, 0, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capture tips',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 10),
            Text(
              'Stand square to the shelf and keep every row inside the frame. '
              'Avoid glare and motion blur. Take several photos for wide '
              'shelves.',
              style: TextStyle(height: 1.45),
            ),
          ],
        ),
      ),
    ),
  );

  void _review() {
    if (widget.returnToReview) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewScreen(storeName: widget.storeName),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _flow.photos.removeListener(_onPhotos);
    _camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final count = _photos.length;
    return Scaffold(
      backgroundColor: const Color(0xFF05080F),
      body: Stack(
        fit: StackFit.expand,
        children: [
          _Preview(
            controller: _camera,
            error: _cameraError,
            onRetry: _initCamera,
            onGallery: _gallery,
            onDemo: () {
              _flow.add([demoPhotoPath]);
              setState(() => _selected = _photos.length - 1);
            },
          ),
          const IgnorePointer(child: CustomPaint(painter: _GridPainter())),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: GlassSurface(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(22),
              ),
              color: AppColors.navy.withValues(alpha: .62),
              borderColor: Colors.white12,
              blur: 20,
              child: Padding(
                padding: EdgeInsets.fromLTRB(4, top + 8, 4, 8),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const BrandMark(size: 40),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Soap shelf capture',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              widget.storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 12.5,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: _flash ? 'Turn flash off' : 'Turn flash on',
                        onPressed: _toggleFlash,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        icon: Icon(
                          _flash
                              ? Icons.flash_on_rounded
                              : Icons.flash_off_rounded,
                          color: _flash ? AppColors.emerald : Colors.white,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Help',
                        onPressed: _help,
                        style: IconButton.styleFrom(
                          minimumSize: const Size(48, 48),
                        ),
                        icon: const Icon(
                          Icons.help_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: top + 84,
            left: 0,
            right: 0,
            child: const Center(
              child: _Overlay(
                icon: Icons.crop_free_rounded,
                text: 'Keep the full shelf inside the frame',
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GlassSurface(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              color: AppColors.navy.withValues(alpha: .66),
              borderColor: Colors.white12,
              blur: 22,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, bottom + 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (count > 0) ...[
                      _Strip(
                        photos: _photos,
                        selected: _selected,
                        onSelect: (i) => setState(() => _selected = i),
                        onDelete: _deleteSelected,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _GalleryButton(
                          lastPhoto: count > 0 ? _photos.last : null,
                          onTap: _gallery,
                        ),
                        Semantics(
                          button: true,
                          label: 'Capture photo',
                          child: GestureDetector(
                            key: const Key('capture-button'),
                            onTap: _capture,
                            child: Container(
                              width: 84,
                              height: 84,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _capturing
                                      ? AppColors.emerald
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 64,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                count == 1 ? 'photo' : 'photos',
                                style: const TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (count > 0) ...[
                      const SizedBox(height: 14),
                      PrimaryButton(
                        label: count == 1
                            ? 'Review photo'
                            : 'Review $count photos',
                        icon: Icons.arrow_forward_rounded,
                        backgroundColor: AppColors.emerald,
                        foregroundColor: AppColors.navy,
                        onPressed: _review,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.controller,
    required this.error,
    required this.onRetry,
    required this.onGallery,
    required this.onDemo,
  });
  final CameraController? controller;
  final String? error;
  final VoidCallback onRetry;
  final VoidCallback onGallery;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c != null && c.value.isInitialized) {
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: c.value.previewSize?.height ?? 1,
            height: c.value.previewSize?.width ?? 1,
            child: CameraPreview(c),
          ),
        ),
      );
    }
    return ColoredBox(
      color: const Color(0xFF0B1426),
      child: Center(
        child: error == null
            ? const EmeraldLoader()
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.no_photography_outlined,
                      size: 44,
                      color: Colors.white70,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: AppColors.navy,
                        minimumSize: const Size(160, 48),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                    TextButton(
                      onPressed: onGallery,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Text('Choose from gallery'),
                    ),
                    TextButton(
                      onPressed: onDemo,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        minimumSize: const Size(48, 48),
                      ),
                      child: const Text('Use demo shelf photo · testing only'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Overlay extends StatelessWidget {
  const _Overlay({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.navy.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.emerald),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Strip extends StatelessWidget {
  const _Strip({
    required this.photos,
    required this.selected,
    required this.onSelect,
    required this.onDelete,
  });
  final List<String> photos;
  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final on = i == selected;
                return Semantics(
                  button: true,
                  selected: on,
                  label: 'Photo ${i + 1}',
                  child: GestureDetector(
                    onTap: () => onSelect(i),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: on ? AppColors.emerald : Colors.white30,
                          width: on ? 3 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image(
                          image: photoProvider(photos[i], cacheWidth: 160),
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: Colors.white12,
                            child: Icon(
                              Icons.image_outlined,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (selected >= 0)
            IconButton(
              tooltip: 'Delete photo ${selected + 1}',
              onPressed: onDelete,
              style: IconButton.styleFrom(
                minimumSize: const Size(52, 52),
                backgroundColor: Colors.white12,
              ),
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            ),
        ],
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.lastPhoto, required this.onTap});
  final String? lastPhoto;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Choose from gallery',
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white12,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white38),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: lastPhoto == null
              ? const Icon(Icons.photo_library_outlined, color: Colors.white)
              : Image(
                  image: photoProvider(lastPhoto!, cacheWidth: 140),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const Icon(
                    Icons.photo_library_outlined,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    ),
  );
}

class _GridPainter extends CustomPainter {
  const _GridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withValues(alpha: .22)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * i / 3, 0),
        Offset(size.width * i / 3, size.height),
        p,
      );
      canvas.drawLine(
        Offset(0, size.height * i / 3),
        Offset(size.width, size.height * i / 3),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
