import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/ui/screens/Home/home_screen_controller.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final homeScreenController = Get.find<HomeScreenController>();
    return Obx(() {
      final selectedIndex = homeScreenController.tabIndex.toInt();
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).padding.bottom > 0
              ? MediaQuery.of(context).padding.bottom + 4
              : 20,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: const Color(0xFF131313).withOpacity(0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDDB7FF).withOpacity(0.05),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(context, 0, Icons.home_rounded, Icons.home_outlined, 'home'.tr, selectedIndex, homeScreenController),
                  _buildNavItem(context, 1, Icons.search_rounded, Icons.search_rounded, 'search'.tr, selectedIndex, homeScreenController),
                  _buildNavItem(context, 2, Icons.library_music_rounded, Icons.library_music_outlined, 'library'.tr, selectedIndex, homeScreenController),
                  _buildNavItem(context, 3, Icons.settings_rounded, Icons.settings_outlined, 'settings'.tr, selectedIndex, homeScreenController),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData activeIcon,
    IconData inactiveIcon,
    String label,
    int selectedIndex,
    HomeScreenController controller,
  ) {
    final isSelected = selectedIndex == index;
    final activeColor = const Color(0xFFDDB7FF); // Electric Purple
    final inactiveColor = Colors.white.withOpacity(0.4);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => controller.onBottonBarTabSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isSelected
                    ? const Color(0xFFFFB0CD).withOpacity(0.12) // Neon Pink accent glow background
                    : Colors.transparent,
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              modifyNgetlabel(label),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String modifyNgetlabel(String label) {
    if (label.length > 9) {
      return "${label.substring(0, 8)}..";
    }
    return label;
  }
}
