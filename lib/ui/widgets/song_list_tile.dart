import 'package:audio_service/audio_service.dart' show MediaItem;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:widget_marquee/widget_marquee.dart';

import '../../models/playlist.dart';
import '../player/player_controller.dart';
import '../screens/Settings/settings_screen_controller.dart';
import 'add_to_playlist.dart';
import 'image_widget.dart';
import 'snackbar.dart';
import 'songinfo_bottom_sheet.dart';

class SongListTile extends StatelessWidget with RemoveSongFromPlaylistMixin {
  const SongListTile(
      {super.key,
      this.onTap,
      required this.song,
      this.playlist,
      this.isPlaylistOrAlbum = false,
      this.thumbReplacementWithIndex = false,
      this.index});
  final Playlist? playlist;
  final MediaItem song;
  final VoidCallback? onTap;
  final bool isPlaylistOrAlbum;

  /// Valid for Album songs
  final bool thumbReplacementWithIndex;
  final int? index;

  @override
  Widget build(BuildContext context) {
    final playerController = Get.find<PlayerController>();
    return Obx(() {
      final isActive = playerController.currentSong.value?.id == song.id;
      final isPlaying = isActive && playerController.buttonState.value == PlayButtonState.playing;

      return Listener(
          onPointerDown: (PointerDownEvent event) {
            if (event.buttons == kSecondaryMouseButton) {
              showModalBottomSheet(
                constraints: const BoxConstraints(maxWidth: 500),
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
                ),
                isScrollControlled: true,
                context: playerController.homeScaffoldkey.currentState!.context,
                barrierColor: Colors.transparent.withAlpha(100),
                builder: (context) => SongInfoBottomSheet(
                  song,
                  playlist: playlist,
                ),
              ).whenComplete(() => Get.delete<SongInfoController>());
            }
          },
          child: Slidable(
            enabled:
                Get.find<SettingsScreenController>().slidableActionEnabled.isTrue,
            startActionPane: ActionPane(motion: const DrawerMotion(), children: [
              SlidableAction(
                onPressed: (context) {
                  showDialog(
                    context: context,
                    builder: (context) => AddToPlaylist([song]),
                  ).whenComplete(() => Get.delete<AddToPlaylistController>());
                },
                backgroundColor: const Color(0xFF201F1F),
                foregroundColor: Colors.white,
                icon: Icons.playlist_add,
              ),
              if (playlist != null && !playlist!.isCloudPlaylist)
                SlidableAction(
                  onPressed: (context) {
                    removeSongFromPlaylist(song, playlist!);
                  },
                  backgroundColor: const Color(0xFF201F1F),
                  foregroundColor: const Color(0xFFFFB0CD),
                  icon: Icons.delete,
                ),
            ]),
            endActionPane: ActionPane(motion: const DrawerMotion(), children: [
              SlidableAction(
                onPressed: (context) {
                  playerController.enqueueSong(song).whenComplete(() {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(snackbar(
                        context, "songEnqueueAlert".tr,
                        size: SanckBarSize.MEDIUM));
                  });
                },
                backgroundColor: const Color(0xFF201F1F),
                foregroundColor: Colors.white,
                icon: Icons.merge,
              ),
              SlidableAction(
                onPressed: (context) {
                  playerController.playNext(song);
                  ScaffoldMessenger.of(context).showSnackBar(snackbar(
                      context, "${"playnextMsg".tr} ${(song).title}",
                      size: SanckBarSize.BIG));
                },
                backgroundColor: const Color(0xFF201F1F),
                foregroundColor: Colors.white,
                icon: Icons.next_plan_outlined,
              ),
            ]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isActive
                    ? const Color(0xFFDDB7FF).withOpacity(0.08)
                    : Colors.white.withOpacity(0.015),
                border: Border(
                  left: BorderSide(
                    color: isActive ? const Color(0xFFDDB7FF) : Colors.transparent,
                    width: isActive ? 3 : 0,
                  ),
                ),
              ),
              child: ListTile(
                onTap: onTap,
                onLongPress: () async {
                  showModalBottomSheet(
                    constraints: const BoxConstraints(maxWidth: 500),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24.0)),
                    ),
                    isScrollControlled: true,
                    context: playerController.homeScaffoldkey.currentState!.context,
                    barrierColor: Colors.transparent.withAlpha(100),
                    builder: (context) => SongInfoBottomSheet(
                      song,
                      playlist: playlist,
                    ),
                  ).whenComplete(() => Get.delete<SongInfoController>());
                },
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                leading: thumbReplacementWithIndex
                    ? SizedBox(
                        width: 40,
                        height: 55,
                        child: Center(
                          child: Text(
                            "$index.",
                            style: TextStyle(
                              fontFamily: 'Sora',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isActive ? const Color(0xFFDDB7FF) : const Color(0xFFCFC2D6),
                            ),
                          ),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: ImageWidget(
                          size: 50,
                          song: song,
                        ),
                      ),
                title: Marquee(
                  delay: const Duration(milliseconds: 300),
                  duration: const Duration(seconds: 5),
                  id: song.title.hashCode.toString(),
                  child: Text(
                    song.title.length > 50
                        ? song.title.substring(0, 50)
                        : song.title,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w600,
                      color: isActive ? const Color(0xFFDDB7FF) : Colors.white,
                    ),
                  ),
                ),
                subtitle: Text(
                  "${song.artist}",
                  maxLines: 1,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: isActive
                        ? const Color(0xFFDDB7FF).withOpacity(0.7)
                        : const Color(0xFFCFC2D6),
                  ),
                ),
                trailing: SizedBox(
                  width: Get.size.width > 800 ? 100 : 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (isPlaylistOrAlbum && isActive)
                            const Icon(
                              Icons.equalizer,
                              color: Color(0xFFFFB0CD),
                              size: 18,
                            ),
                          const SizedBox(height: 2),
                          Text(
                            song.extras!['length'] ?? "",
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: isActive
                                  ? const Color(0xFFFFB0CD)
                                  : const Color(0xFFCFC2D6),
                            ),
                          ),
                        ],
                      ),
                      if (GetPlatform.isDesktop) ...[
                        const SizedBox(width: 8),
                        IconButton(
                            splashRadius: 20,
                            onPressed: () {
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
                                builder: (context) => SongInfoBottomSheet(
                                  song,
                                  playlist: playlist,
                                ),
                              ).whenComplete(
                                  () => Get.delete<SongInfoController>());
                            },
                            icon: const Icon(Icons.more_vert))
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ));
    });
  }
}

