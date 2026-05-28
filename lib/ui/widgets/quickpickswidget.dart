import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/models/quick_picks.dart';
import '../player/player_controller.dart';
import 'image_widget.dart';
import 'songinfo_bottom_sheet.dart';

class QuickPicksWidget extends StatelessWidget {
  const QuickPicksWidget(
      {super.key, required this.content, this.scrollController});
  final QuickPicks content;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final PlayerController playerController = Get.find<PlayerController>();
    return SizedBox(
      height: 380,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              content.title.toLowerCase().removeAllWhitespace.tr,
              style: const TextStyle(
                fontFamily: 'Sora',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Scrollbar(
              thickness: GetPlatform.isDesktop ? null : 0,
              controller: scrollController,
              child: GridView.builder(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: content.songList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.28,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (_, item) {
                    final song = content.songList[item];
                    return Obx(() {
                      final isActive = playerController.currentSong.value?.id == song.id;
                      final isPlaying = isActive && playerController.buttonState.value == PlayButtonState.playing;

                      return Listener(
                        onPointerDown: (PointerDownEvent event) {
                          if (event.buttons == kSecondaryMouseButton) {
                            showModalBottomSheet(
                              constraints: const BoxConstraints(maxWidth: 500),
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24.0)),
                              ),
                              isScrollControlled: true,
                              context: playerController
                                  .homeScaffoldkey.currentState!.context,
                              barrierColor: Colors.transparent.withAlpha(100),
                              builder: (context) => SongInfoBottomSheet(song),
                            ).whenComplete(
                                () => Get.delete<SongInfoController>());
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isActive
                                ? const Color(0xFFDDB7FF).withOpacity(0.08)
                                : Colors.white.withOpacity(0.02),
                            border: Border(
                              left: BorderSide(
                                color: isActive
                                    ? const Color(0xFFDDB7FF)
                                    : Colors.transparent,
                                width: isActive ? 3 : 0,
                              ),
                            ),
                          ),
                          child: Center(
                            child: ListTile(
                                visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                                contentPadding: const EdgeInsets.only(left: 8, right: 8),
                                leading: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: ImageWidget(
                                        song: song,
                                        size: 50,
                                      ),
                                    ),
                                    if (isPlaying)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.4),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Center(
                                            child: Icon(
                                              Icons.volume_up_rounded,
                                              color: Color(0xFFFFB0CD),
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  song.title,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isActive ? const Color(0xFFDDB7FF) : Colors.white,
                                  ),
                                ),
                                subtitle: Text(
                                  "${song.artist}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: isActive
                                        ? const Color(0xFFDDB7FF).withOpacity(0.7)
                                        : const Color(0xFFCFC2D6),
                                  ),
                                ),
                                onTap: () {
                                  playerController.pushSongToQueue(song);
                                },
                                onLongPress: () {
                                  showModalBottomSheet(
                                    constraints: const BoxConstraints(maxWidth: 500),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(24.0)),
                                    ),
                                    isScrollControlled: true,
                                    context: playerController
                                        .homeScaffoldkey.currentState!.context,
                                    barrierColor: Colors.transparent.withAlpha(100),
                                    builder: (context) => SongInfoBottomSheet(song),
                                  ).whenComplete(
                                      () => Get.delete<SongInfoController>());
                                },
                                trailing: (GetPlatform.isDesktop)
                                    ? IconButton(
                                        splashRadius: 20,
                                        onPressed: () {
                                          showModalBottomSheet(
                                            constraints:
                                                const BoxConstraints(maxWidth: 500),
                                            shape: const RoundedRectangleBorder(
                                              borderRadius: BorderRadius.vertical(
                                                  top: Radius.circular(24.0)),
                                            ),
                                            isScrollControlled: true,
                                            context: playerController.homeScaffoldkey
                                                .currentState!.context,
                                            barrierColor:
                                                Colors.transparent.withAlpha(100),
                                            builder: (context) => SongInfoBottomSheet(song),
                                          ).whenComplete(
                                              () => Get.delete<SongInfoController>());
                                        },
                                        icon: const Icon(Icons.more_vert))
                                    : null),
                          ),
                        ),
                      );
                    });
                  }),
            ),
          ),
          const SizedBox(height: 16)
        ],
      ),
    );
  }
}

