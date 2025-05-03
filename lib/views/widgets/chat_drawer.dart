import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/route_utils.dart';
import '../../views/realtime_emotion_detection_screen.dart';

class ChatDrawer extends ConsumerWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Drawer(
      backgroundColor: const Color(
        0xFF050133,
      ), // Fixed solid color for entire drawer
      child: SafeArea(
        child: Column(
          children: [
            // Header area
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
              decoration: const BoxDecoration(
                color: Color(0xFF050133), // Same as drawer background
              ),
              child: Row(
                children: [
                  // User Avatar with image
                  Container(
                    width: 60.w,
                    height: 60.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            red: 0,
                            green: 0,
                            blue: 0,
                            alpha: 0.2 * 255,
                          ),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset('assets/sense.png', fit: BoxFit.cover),
                    ),
                  ),

                  SizedBox(width: 16.w),

                  // User Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // User Name
                        Text(
                          user?.fullName ?? 'User',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),

                        SizedBox(height: 4.h),

                        // User Email
                        Text(
                          user?.email ?? 'user@example.com',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              color: Colors.white.withValues(
                red: 255,
                green: 255,
                blue: 255,
                alpha: 0.1 * 255,
              ),
              height: 1,
            ),

            // Drawer Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  _buildDrawerItem(
                    context,
                    icon: Icons.refresh_outlined,
                    title: 'New Chat',
                    onTap: () {
                      ref.read(chatProvider.notifier).clearMessages();
                      Navigator.pop(context);
                    },
                  ),

                  _buildDrawerItem(
                    context,
                    icon: Icons.face_outlined,
                    title: 'Realtime Emotion',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  const RealtimeEmotionDetectionScreen(),
                        ),
                      );
                    },
                  ),

                  _buildDrawerItem(
                    context,
                    icon: Icons.settings_outlined,
                    title: 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  _buildDrawerItem(
                    context,
                    icon: Icons.help_outline,
                    title: 'Help & Feedback',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),

                  Divider(
                    color: Colors.white.withValues(
                      red: 255,
                      green: 255,
                      blue: 255,
                      alpha: 0.1 * 255,
                    ),
                    thickness: 0.5,
                    height: 32,
                    indent: 16,
                    endIndent: 16,
                  ),

                  _buildDrawerItem(
                    context,
                    icon: Icons.logout_outlined,
                    title: 'Logout',
                    isDestructive: true,
                    onTap: () {
                      // Close drawer first
                      Navigator.pop(context);

                      // Use the comprehensive logout method from RouteUtils
                      RouteUtils.performLogout(context, ref);
                    },
                  ),
                ],
              ),
            ),

            // App Version
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build drawer items with consistent style
  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color iconColor = isDestructive ? Colors.red[300]! : Colors.white;
    final Color textColor = isDestructive ? Colors.red[300]! : Colors.white;

    return ListTile(
      leading: Icon(icon, color: iconColor, size: 24.w),
      title: Text(title, style: TextStyle(color: textColor, fontSize: 16.sp)),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.comfortable,
      contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
    );
  }
}
