import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sense_ai/views/widgets/custom_icon.dart';
import 'package:sense_ai/views/widgets/custom_popup_menu_button.dart';

/// Button for image-related actions in the chat input
class ImageButton extends StatefulWidget {
  final Future<void> Function(String) onPickFile;
  final Future<void> Function()? onImageAction;

  const ImageButton({super.key, required this.onPickFile, this.onImageAction});

  @override
  State<ImageButton> createState() => _ImageButtonState();
}

class _ImageButtonState extends State<ImageButton> {
  final GlobalKey _buttonKey = GlobalKey();
  bool _isHandlingAction = false;

  void _handleMenuItemTap(String value) async {
    // Prevent duplicate actions
    if (_isHandlingAction) return;

    setState(() => _isHandlingAction = true);

    try {
      switch (value) {
        case "take_picture":
          if (widget.onImageAction != null) await widget.onImageAction!();
          break;
        case "gallery":
          await widget.onPickFile("image");
          break;
      }
    } finally {
      if (mounted) {
        setState(() => _isHandlingAction = false);
      }
    }
  }

  void _showPopupMenu() {
    if (_isHandlingAction) {
      debugPrint('ImageButton: Menu blocked, action already in progress');
      return;
    }

    List<CustomPopupMenuItem> menuItems = [
      CustomPopupMenuItem(
        icon: Icons.folder,
        text: "Select Gallery Image",
        value: "gallery",
        onTap: _handleMenuItemTap,
      ),
      CustomPopupMenuItem(
        icon: Icons.camera_alt,
        text: "Take a Picture",
        value: "take_picture",
        onTap: _handleMenuItemTap,
      ),
    ];

    CustomPopupMenu(
      context: context,
      buttonKey: _buttonKey,
      menuItems: menuItems,
      menuWidth: 200.w,
      backgroundColor: Colors.white,
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return customImageButton(
      key: _buttonKey,
      imageColor:
          _isHandlingAction
              ? const Color(0xff7A8B9A) // Dimmed color when handling action
              : const Color(0xffA5B8C7),
      imageSize: 20.sp,
      imagePath: "assets/image.png",
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
      onPressed: _isHandlingAction ? () {} : _showPopupMenu,
    );
  }
}
