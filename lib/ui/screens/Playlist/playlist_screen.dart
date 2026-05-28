import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:widget_marquee/widget_marquee.dart';

import '/models/playling_from.dart';
import '/models/thumbnail.dart';
import '/ui/widgets/playlist_album_scroll_behaviour.dart';
import '../../../services/downloader.dart';
import '../../navigator.dart';
import '../../player/player_controller.dart';
import '../../widgets/create_playlist_dialog.dart';
import '../../widgets/loader.dart';
import '../../widgets/playlist_export_dialog.dart';
import '../../widgets/snackbar.dart';
import '../../widgets/song_list_tile.dart';
import '../../widgets/songinfo_bottom_sheet.dart';
import '../../widgets/sort_widget.dart';
import '../Library/library_controller.dart';
import 'playlist_screen_controller.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tag = key.hashCode.toString();
    final playlistController =
        (Get.isRegistered<PlaylistScreenController>(tag: tag))
            ? Get.find<PlaylistScreenController>(tag: tag)
            : Get.put(PlaylistScreenController(), tag: tag);
    final size = MediaQuery.of(context).size;
    final playerController = Get.find<PlayerController>();
    final landscape = size.width > size.height;
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          final scrollOffset = scrollInfo.metrics.pixels;

          if (landscape) {
            playlistController.scrollOffset.value = 0;
          } else {
            playlistController.scrollOffset.value = scrollOffset;
          }
          if (scrollOffset > 270 || (landscape && scrollOffset > 215)) {
            playlistController.appBarTitleVisible.value = true;
          } else {
            playlistController.appBarTitleVisible.value = false;
          }
          return true;
        },
        child: Stack(
          children: [
            Obx(
              () => playlistController.isContentFetched.isTrue
                  ? Positioned(
                      top: landscape
                          ? 0
                          : -.25 * playlistController.scrollOffset.value,
                      right: landscape ? 0 : null,
                      child: Obx(() {
                        final opacityValue = 1 -
                            playlistController.scrollOffset.value /
                                (size.width - 100);
                        return Opacity(
                          opacity: opacityValue < 0 ||
                                  playlistController.isSearchingOn.isTrue && !landscape
                              ? 0
                              : opacityValue,
                          child: DecoratedBox(
                            position: DecorationPosition.foreground,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).canvasColor,
                                  spreadRadius: 200,
                                  blurRadius: 100,
                                  offset: Offset(-size.height, 0),
                                ),
                                BoxShadow(
                                  color: Theme.of(context).canvasColor,
                                  spreadRadius: 200,
                                  blurRadius: 100,
                                  offset: Offset(
                                      0,
                                      landscape
                                          ? size.height
                                          : size.width + 80),
                                )
                              ],
                            ),
                            child: CachedNetworkImage(
                              imageUrl: Thumbnail(playlistController
                                      .playlist.value.thumbnailUrl)
                                  .extraHigh,
                              fit: landscape ? BoxFit.fitHeight : BoxFit.cover,
                              width: landscape ? null : size.width,
                              height: landscape ? size.height : size.width,
                            ),
                          ),
                        );
                      }))
                  : SizedBox(
                      height: size.width,
                      width: size.width,
                    ),
            ),
            Column(
              children: [
                Container(
                  padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 10,
                      right: 10),
                  height: 80,
                  child: Center(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: IconButton(
                            tooltip: "back".tr,
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              icon: const Icon(Icons.arrow_back_ios)),
                        ),
                        Expanded(
                          child: Obx(
                            () => Marquee(
                              delay: const Duration(milliseconds: 300),
                              duration: const Duration(seconds: 5),
                              id: "${playlistController.playlist.value.title.hashCode.toString()}_appbar",
                              child: Text(
                                playlistController.appBarTitleVisible.isTrue
                                    ? playlistController.playlist.value.title
                                    : "",
                                maxLines: 1,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ),
                        ),
                        if (!playlistController
                                .playlist.value.isCloudPlaylist &&
                            playlistController.isDefaultPlaylist.isFalse)
                          SizedBox(
                            width: 50,
                            child: IconButton(
                                onPressed: () {
                                  showModalBottomSheet(
                                    constraints:
                                        const BoxConstraints(maxWidth: 500),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(10.0)),
                                    ),
                                    context: Get.find<PlayerController>()
                                        .homeScaffoldkey
                                        .currentState!
                                        .context,
                                    barrierColor:
                                        Colors.transparent.withAlpha(100),
                                    builder: (context) => SizedBox(
                                      height: 140,
                                      child: Column(
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.edit),
                                            title: Text("renamePlaylist".tr),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    CreateNRenamePlaylistPopup(
                                                        renamePlaylist: true,
                                                        playlist:
                                                            playlistController
                                                                .playlist
                                                                .value),
                                              );
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.delete),
                                            title: Text("removePlaylist".tr),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              playlistController
                                                  .addNremoveFromLibrary(
                                                      playlistController
                                                          .playlist.value,
                                                      add: false)
                                                  .then((value) {
                                                Get.nestedKey(
                                                        ScreenNavigationSetup
                                                            .id)!
                                                    .currentState!
                                                    .pop();
                                                ScaffoldMessenger.of(
                                                        Get.context!)
                                                    .showSnackBar(snackbar(
                                                        Get.context!,
                                                        value
                                                            ? "playlistRemovedAlert"
                                                                .tr
                                                            : "operationFailed"
                                                                .tr,
                                                        size: SanckBarSize
                                                            .MEDIUM));
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.more_vert)),
                          )
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 800,
                      ),
                      child: Obx(
                        () => ScrollConfiguration(
                          behavior: PlaylistAlbumScrollBehaviour(),
                          child: ListView.builder(
                            addRepaintBoundaries: false,
                            padding: EdgeInsets.only(
                              top: playlistController.isSearchingOn.isTrue
                                  ? 0
                                  : landscape
                                      ? 150
                                      : 200,
                              bottom: 200,
                            ),
                            itemCount: playlistController.songList.isEmpty ||
                                    playlistController.isContentFetched.isFalse
                                ? 4
                                : playlistController.songList.length + 3,
                            itemBuilder: (_, index) {
                              if (index == 0) {
                                return Padding(
                                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 8.0),
                                  child: SizedBox(
                                    height: 48,
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      physics: const BouncingScrollPhysics(),
                                      child: Row(
                                        children: [
                                          // 1. Premium Play Pill
                                          GestureDetector(
                                            onTap: () {
                                              if (playlistController.songList.isNotEmpty) {
                                                playerController.playPlayListSong(
                                                    List<MediaItem>.from(
                                                        playlistController.songList),
                                                    0,
                                                    playfrom: PlaylingFrom(
                                                        name: playlistController
                                                            .playlist.value.title,
                                                        type: PlaylingFromType.PLAYLIST));
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [Color(0xFFDDB7FF), Color(0xFFFFB0CD)],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius: BorderRadius.circular(9999),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(0xFFDDB7FF).withOpacity(0.3),
                                                    blurRadius: 12,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.play_arrow_rounded, color: Color(0xFF131313), size: 20),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "play".tr,
                                                    style: const TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: Color(0xFF131313),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          // 2. Premium Shuffle Pill
                                          GestureDetector(
                                            onTap: () {
                                              if (playlistController.songList.isNotEmpty) {
                                                final songsToplay = List<MediaItem>.from(playlistController.songList);
                                                songsToplay.shuffle();
                                                songsToplay.shuffle();
                                                playerController.playPlayListSong(
                                                    songsToplay, 0,
                                                    playfrom: PlaylingFrom(
                                                        name: playlistController.playlist.value.title,
                                                        type: PlaylingFromType.PLAYLIST));
                                              }
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(0.04),
                                                border: Border.all(
                                                  color: const Color(0xFFDDB7FF).withOpacity(0.15),
                                                  width: 1,
                                                ),
                                                borderRadius: BorderRadius.circular(9999),
                                              ),
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.shuffle, color: Color(0xFFDDB7FF), size: 16),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    "shuffle".tr,
                                                    style: const TextStyle(
                                                      fontFamily: 'Inter',
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 13,
                                                      color: Color(0xFFDDB7FF),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          // Vertical separator
                                          Container(
                                            width: 1,
                                            height: 24,
                                            color: Colors.white.withOpacity(0.1),
                                          ),
                                          const SizedBox(width: 12),
                                          // 3. Bookmark Button
                                          Obx(() {
                                            final isPiped = playlistController.playlist.value.isPipedPlaylist;
                                            final isCloud = playlistController.playlist.value.isCloudPlaylist;
                                            if (isPiped || !isCloud) return const SizedBox.shrink();
                                            final isAdded = playlistController.isAddedToLibrary.isTrue;
                                            return _buildGlassCircleButton(
                                              context: context,
                                              icon: isAdded ? Icons.bookmark_added : Icons.bookmark_add,
                                              tooltip: isAdded ? "removeFromLibrary".tr : "addToLibrary".tr,
                                              iconColor: isAdded ? const Color(0xFFFFB0CD) : Colors.white,
                                              onTap: () {
                                                final add = !isAdded;
                                                playlistController.addNremoveFromLibrary(
                                                    playlistController.playlist.value,
                                                    add: add)
                                                .then((value) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(snackbar(
                                                      context,
                                                      value
                                                          ? add
                                                              ? "playlistBookmarkAddAlert".tr
                                                              : "listBookmarkRemoveAlert".tr
                                                          : "operationFailed".tr,
                                                      size: SanckBarSize.MEDIUM));
                                                });
                                              },
                                            );
                                          }),
                                          // 4. Enqueue Button
                                          _buildGlassCircleButton(
                                            context: context,
                                            icon: Icons.merge,
                                            tooltip: "enqueueSongs".tr,
                                            onTap: () {
                                              Get.find<PlayerController>().enqueueSongList(
                                                  playlistController.songList.toList())
                                              .whenComplete(() {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(snackbar(
                                                      context, "songEnqueueAlert".tr,
                                                      size: SanckBarSize.MEDIUM));
                                                }
                                              });
                                            },
                                          ),
                                          // 5. Download Button
                                          GetX<Downloader>(builder: (controller) {
                                            final id = playlistController.playlist.value.playlistId;
                                            final isDownloaded = playlistController.isDownloaded.isTrue;
                                            final isDownloading = controller.playlistQueue.containsKey(id) &&
                                                controller.currentPlaylistId.toString() == id;
                                            final isQueued = controller.playlistQueue.containsKey(id);

                                            return _buildGlassCircleButton(
                                              context: context,
                                              icon: isDownloaded ? Icons.download_done : (isQueued ? Icons.hourglass_bottom : Icons.download),
                                              tooltip: "downloadPlaylist".tr,
                                              iconColor: isDownloaded ? const Color(0xFFFFB0CD) : Colors.white,
                                              customWidget: isDownloading
                                                  ? Stack(
                                                      alignment: Alignment.center,
                                                      children: [
                                                        Text(
                                                          "${controller.playlistDownloadingProgress.value}",
                                                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFFFB0CD)),
                                                        ),
                                                        const SizedBox(
                                                          height: 24,
                                                          width: 24,
                                                          child: CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            valueColor: AlwaysStoppedAnimation(Color(0xFFFFB0CD)),
                                                          ),
                                                        )
                                                      ],
                                                    )
                                                  : null,
                                              onTap: () {
                                                if (!isDownloaded) {
                                                  controller.downloadPlaylist(
                                                      id,
                                                      playlistController.songList.toList());
                                                }
                                              },
                                            );
                                          }),
                                          // 6. Sync Button
                                          if (playlistController.isAddedToLibrary.isTrue)
                                            _buildGlassCircleButton(
                                              context: context,
                                              icon: Icons.cloud_sync,
                                              tooltip: "syncPlaylistSongs".tr,
                                              onTap: () {
                                                playlistController.syncPlaylistSongs();
                                              },
                                            ),
                                          // 7. Blacklist button
                                          if (playlistController.playlist.value.isPipedPlaylist)
                                            _buildGlassCircleButton(
                                              context: context,
                                              icon: Icons.block,
                                              tooltip: "blacklistPipedPlaylist".tr,
                                              onTap: () {
                                                Get.nestedKey(ScreenNavigationSetup.id)!.currentState!.pop();
                                                Get.find<LibraryPlaylistsController>().blacklistPipedPlaylist(
                                                    playlistController.playlist.value);
                                                ScaffoldMessenger.of(Get.context!).showSnackBar(snackbar(
                                                    Get.context!, "playlistBlacklistAlert".tr,
                                                    size: SanckBarSize.MEDIUM));
                                              },
                                            ),
                                          // 8. Share Button
                                          if (playlistController.playlist.value.isCloudPlaylist)
                                            _buildGlassCircleButton(
                                              context: context,
                                              icon: Icons.share,
                                              tooltip: "sharePlaylist".tr,
                                              onTap: () {
                                                final content = playlistController.playlist.value;
                                                if (content.isPipedPlaylist) {
                                                  Share.share("https://piped.video/playlist?list=${content.playlistId}");
                                                } else {
                                                  final isPlaylistIdPrefixAvlbl = content.playlistId.substring(0, 2) == "VL";
                                                  String url = "https://youtube.com/playlist?list=";
                                                  url = isPlaylistIdPrefixAvlbl
                                                      ? url + content.playlistId.substring(2)
                                                      : url + content.playlistId;
                                                  Share.share(url);
                                                }
                                              },
                                            ),
                                          // 9. Export Button
                                          _buildGlassCircleButton(
                                            context: context,
                                            icon: Icons.file_upload,
                                            tooltip: "exportPlaylist".tr,
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (dialogContext) => PlaylistExportDialog(
                                                  controller: playlistController,
                                                  parentContext: context,
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              } else if (index == 1) {
                                final title =
                                    playlistController.playlist.value.title;
                                final description = playlistController
                                    .playlist.value.description;

                                return AnimatedBuilder(
                                  animation:
                                      playlistController.animationController,
                                  builder: (context, child) {
                                    return SizedBox(
                                      height: playlistController
                                          .heightAnimation.value,
                                      child: Transform.scale(
                                        scale: playlistController
                                            .scaleAnimation.value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 25.0, bottom: 10, right: 30),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Marquee(
                                          delay:
                                              const Duration(milliseconds: 300),
                                          duration: const Duration(seconds: 5),
                                          id: title.hashCode.toString(),
                                          child: Text(
                                            title.length > 50
                                                ? title.substring(0, 50)
                                                : title,
                                            maxLines: 1,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleLarge!
                                                .copyWith(fontSize: 30),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8.0),
                                          child: Marquee(
                                            delay: const Duration(
                                                milliseconds: 300),
                                            duration:
                                                const Duration(seconds: 5),
                                            id: description.hashCode.toString(),
                                            child: Text(
                                              description ?? "playlist".tr,
                                              maxLines: 1,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              } else if (index == 2) {
                                return SizedBox(
                                    height:
                                        playlistController.isSearchingOn.isTrue
                                            ? 60
                                            : 40,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 15.0, right: 10),
                                      child: Obx(
                                        () => SortWidget(
                                          tag: playlistController
                                              .playlist.value.playlistId,
                                          screenController: playlistController,
                                          isSearchFeatureRequired: true,
                                          isPlaylistRearrageFeatureRequired: !playlistController
                                                  .playlist
                                                  .value
                                                  .isCloudPlaylist &&
                                              playlistController.playlist.value
                                                      .playlistId !=
                                                  "LIBRP" &&
                                              playlistController.playlist.value
                                                      .playlistId !=
                                                  "SongDownloads" &&
                                              playlistController.playlist.value
                                                      .playlistId !=
                                                  "SongsCache",
                                          isSongDeletetioFeatureRequired:
                                              !playlistController.playlist.value
                                                  .isCloudPlaylist,
                                          itemCountTitle:
                                              "${playlistController.songList.length}",
                                          itemIcon: Icons.music_note,
                                          titleLeftPadding: 9,
                                          requiredSortTypes:
                                              buildSortTypeSet(false, true),
                                          onSort: playlistController.onSort,
                                          onSearch: playlistController.onSearch,
                                          onSearchClose:
                                              playlistController.onSearchClose,
                                          onSearchStart:
                                              playlistController.onSearchStart,
                                          startAdditionalOperation:
                                              playlistController
                                                  .startAdditionalOperation,
                                          selectAll:
                                              playlistController.selectAll,
                                          performAdditionalOperation:
                                              playlistController
                                                  .performAdditionalOperation,
                                          cancelAdditionalOperation:
                                              playlistController
                                                  .cancelAdditionalOperation,
                                        ),
                                      ),
                                    ));
                              } else if (playlistController
                                      .isContentFetched.isFalse ||
                                  playlistController.songList.isEmpty) {
                                return SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: playlistController
                                            .isContentFetched.isFalse
                                        ? const LoadingIndicator()
                                        : Text(
                                            "emptyPlaylist".tr,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                          ),
                                  ),
                                );
                              }

                              return Padding(
                                padding:
                                    const EdgeInsets.only(left: 20.0, right: 5),
                                child: SongListTile(
                                  onTap: () {
                                    playerController.playPlayListSong(
                                        List<MediaItem>.from(
                                            playlistController.songList),
                                        index - 3,
                                        playfrom: PlaylingFrom(
                                            name: playlistController
                                                .playlist.value.title,
                                            type: PlaylingFromType.PLAYLIST));
                                  },
                                  song: playlistController.songList[index - 3],
                                  isPlaylistOrAlbum: true,
                                  playlist: playlistController.playlist.value,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future openBottomSheet(BuildContext context, MediaItem song) {
    return showModalBottomSheet(
      constraints: const BoxConstraints(maxWidth: 500),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      isScrollControlled: true,
      context: context,
      barrierColor: Colors.transparent.withAlpha(100),
      builder: (context) => SongInfoBottomSheet(song),
    ).whenComplete(() => Get.delete<SongInfoController>());
  }

  Widget _buildGlassCircleButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? iconColor,
    Widget? customWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.04),
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: customWidget ?? Center(
              child: Icon(
                icon,
                color: iconColor ?? Colors.white.withOpacity(0.8),
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
