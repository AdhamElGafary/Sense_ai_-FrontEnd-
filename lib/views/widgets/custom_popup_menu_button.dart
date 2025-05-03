import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// Simple debounce mechanism
DateTime _lastPopupTime = DateTime.now().subtract(const Duration(seconds: 1));
const _popupDebounceMillis = 500;
bool _isPopupMenuOpen = false;

class CustomPopupMenu {
  final BuildContext context;
  final GlobalKey buttonKey;
  final Color backgroundColor;
  final List<CustomPopupMenuItem> menuItems;
  final double menuWidth;
  final double horizontalOffset;
  final double topOffset;
  final double bottomOffset;

  CustomPopupMenu({
    required this.context,
    required this.buttonKey,
    this.backgroundColor = Colors.white,
    required this.menuItems,
    this.menuWidth = 200,
    this.horizontalOffset = 0,
    this.topOffset = 10,
    this.bottomOffset = 10,
  });

  void show() {
    // Debounce to prevent multiple calls
    final now = DateTime.now();
    if (_isPopupMenuOpen ||
        now.difference(_lastPopupTime).inMilliseconds < _popupDebounceMillis) {
      return;
    }
    _lastPopupTime = now;
    _isPopupMenuOpen = true;

    // Get the current keyboard status and focus
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final currentFocus = FocusScope.of(context);
    final focusedChild = currentFocus.focusedChild;

    // Get the position of the button to position the menu near it
    final RenderBox? renderBox =
        buttonKey.currentContext?.findRenderObject() as RenderBox?;
    final position = renderBox?.localToGlobal(Offset.zero);
    final screenSize = MediaQuery.of(context).size;

    // Default position for the menu is centered
    double leftPosition = (screenSize.width - menuWidth) / 2;

    // If we have a valid button position, align the menu with it
    if (position != null) {
      // Try to align the menu with the button horizontally
      leftPosition = position.dx;

      // Keep the menu within screen bounds
      if (leftPosition + menuWidth > screenSize.width - 16.w) {
        leftPosition = screenSize.width - menuWidth - 16.w;
      }
      if (leftPosition < 16.w) {
        leftPosition = 16.w;
      }
    }

    // Show a compact popup dialog that keeps the keyboard visible
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Stack(
          children: [
            // Invisible barrier for tapping outside to dismiss
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(color: Colors.transparent),
              ),
            ),

            // Actual menu positioned near the bottom
            Positioned(
              left: leftPosition,
              bottom:
                  isKeyboardVisible
                      ? MediaQuery.of(context).viewInsets.bottom + 12.h
                      : 80.h, // Position it above the keyboard or near bottom
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12.r),
                color: backgroundColor,
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: menuWidth.w,
                  constraints: BoxConstraints(
                    maxHeight: 300.h, // Maximum height
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        menuItems.map((item) {
                          return InkWell(
                            onTap: () {
                              Navigator.pop(context);

                              // Execute the action after a short delay
                              Future.delayed(
                                const Duration(milliseconds: 100),
                                () {
                                  // Restore focus if needed
                                  if (isKeyboardVisible &&
                                      focusedChild != null &&
                                      focusedChild.canRequestFocus) {
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(focusedChild);
                                  }

                                  // Execute the callback
                                  item.onTap(item.value);
                                },
                              );
                            },
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 12.h,
                                horizontal: 16.w,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    color: Colors.black87,
                                    size: 24.sp,
                                  ),
                                  SizedBox(width: 16.w),
                                  Expanded(
                                    child: Text(
                                      item.text,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      _isPopupMenuOpen = false;

      // Restore focus if keyboard was visible
      if (isKeyboardVisible &&
          focusedChild != null &&
          focusedChild.canRequestFocus) {
        Future.delayed(const Duration(milliseconds: 50), () {
          FocusScope.of(context).requestFocus(focusedChild);
        });
      }
    });
  }
}

class CustomPopupMenuItem {
  final IconData icon;
  final String text;
  final String value;
  final Function(String) onTap;

  CustomPopupMenuItem({
    required this.icon,
    required this.text,
    required this.value,
    required this.onTap,
  });
}
