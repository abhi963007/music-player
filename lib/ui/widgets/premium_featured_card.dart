import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audio_service/audio_service.dart';
import '../player/player_controller.dart';
import '../screens/Home/home_screen_controller.dart';
import '../../models/playling_from.dart';

class PremiumFeaturedCard extends StatelessWidget {
  const PremiumFeaturedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    final HomeScreenController homeScreenController = Get.find<HomeScreenController>();

    final timeOfDay = DateTime.now().hour;
    String greetingSub = "Ready for your morning drive?";
    if (timeOfDay >= 12 && timeOfDay < 17) {
      greetingSub = "Power through your afternoon focus!";
    } else if (timeOfDay >= 17 && timeOfDay < 22) {
      greetingSub = "Ready for your night rhythm?";
    } else {
      greetingSub = "Late night chill vibes...";
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      height: 180,
      width: double.infinity,
      child: Stack(
        children: [
          // Background Glow layer (Neon Violet/Pink)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFDDB7FF).withOpacity(0.15),
                    const Color(0xFFFFB0CD).withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Frosted Glass Layer
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.05),
                        Colors.transparent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      // Text Info Section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Curated Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDDB7FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(9999),
                                border: Border.all(
                                  color: const Color(0xFFDDB7FF).withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                "CURATED & TRENDING",
                                style: TextStyle(
                                  color: Color(0xFFDDB7FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Bold Title
                            const Text(
                              "Discover Weekly",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Sora',
                                letterSpacing: -0.5,
                                shadows: [
                                  Shadow(
                                    color: Color(0xFFDDB7FF),
                                    offset: Offset(0, 0),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            // Subtitle Description
                            Text(
                              greetingSub,
                              style: TextStyle(
                                color: const Color(0xFFE5E2E1).withOpacity(0.7),
                                fontSize: 13,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Glow Play Button Container
                      Obx(() {
                        final isPlayingThis = playerController.playinfrom.value.name == "Discover Weekly" &&
                            playerController.buttonState.value == PlayButtonState.playing;

                        return GestureDetector(
                          onTap: () {
                            final songs = homeScreenController.quickPicks.value.songList;
                            if (songs.isNotEmpty) {
                              if (isPlayingThis) {
                                playerController.pause();
                              } else {
                                playerController.playPlayListSong(
                                  List<MediaItem>.from(songs),
                                  0,
                                  playfrom: PlaylingFrom(
                                    type: PlaylingFromType.SELECTION,
                                    name: "Discover Weekly",
                                  ),
                                );
                              }
                            } else {
                              Get.snackbar(
                                "Loading",
                                "Fetching tracks, please wait.",
                                snackPosition: SnackPosition.BOTTOM,
                                backgroundColor: const Color(0xFF201F1F),
                                colorText: Colors.white,
                              );
                            }
                          },
                          child: Container(
                            height: 64,
                            width: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isPlayingThis ? const Color(0xFFFFB0CD) : const Color(0xFFDDB7FF),
                              boxShadow: [
                                BoxShadow(
                                  color: (isPlayingThis ? const Color(0xFFFFB0CD) : const Color(0xFFDDB7FF))
                                      .withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              isPlayingThis ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              color: const Color(0xFF131313),
                              size: 36,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
