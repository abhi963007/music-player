import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:harmonymusic/models/playling_from.dart';
import 'package:harmonymusic/models/thumbnail.dart';
import 'package:harmonymusic/ui/widgets/playlist_album_scroll_behaviour.dart';
import 'package:share_plus/share_plus.dart';
import 'package:widget_marquee/widget_marquee.dart';

import '../../../services/downloader.dart';
import '../../player/player_controller.dart';
import '../../widgets/loader.dart';
import '../../widgets/snackbar.dart';
import '../../widgets/song_list_tile.dart';
import '../../widgets/songinfo_bottom_sheet.dart';
import '../../widgets/sort_widget.dart';
import 'album_screen_controller.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tag = key.hashCode.toString();
    final albumController = (Get.isRegistered<AlbumScreenController>(tag: tag))
        ? Get.find<AlbumScreenController>(tag: tag)
        : Get.put(AlbumScreenController(), tag: tag);
    final size = MediaQuery.of(context).size;
    final playerController = Get.find<PlayerController>();
    final landscape = size.width > size.height;
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          final scrollOffset = scrollInfo.metrics.pixels;

          if (landscape) {
            albumController.scrollOffset.value = 0;
          } else {
            albumController.scrollOffset.value = scrollOffset;
          }
          if (scrollOffset > 270 || (landscape && scrollOffset > 225)) {
            albumController.appBarTitleVisible.value = true;
          } else {
            albumController.appBarTitleVisible.value = false;
          }
          return true;
        },
        child: Stack(
          children: [
            Obx(
              () => albumController.isContentFetched.isTrue
                  ? Positioned(
                      top: landscape
                          ? 0
                          : -.25 * albumController.scrollOffset.value,
                      right: landscape ? 0 : null,
                      child: Obx(() {
                        final opacityValue = 1 -
                            albumController.scrollOffset.value /
                                (size.width - 100);
                        return Opacity(
                            opacity: opacityValue < 0 ||
                                    albumController.isSearchingOn.isTrue
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
                                  imageUrl: Thumbnail(albumController
                                          .album.value.thumbnailUrl)
                                      .extraHigh,
                                  fit: landscape
                                      ? BoxFit.fitHeight
                                      : BoxFit.fitWidth,
                                  width: landscape ? null : size.width,
                                  height: landscape ? size.height : null,
                                  // placeholder: (context, n) => Align(
                                  //   alignment:landscape?Alignment.centerLeft: Alignment.topCenter,
                                  //   child: SizedBox(
                                  //     width: landscape ? size.height : size.width,
                                  //     height: landscape ? size.height : size.width,
                                  //     child: Center(
                                  //       child: Icon(Icons.album,
                                  //           size: 150,
                                  //           color: Theme.of(context)
                                  //               .textTheme.titleSmall!.color
                                  //         ),
                                  //     ),
                                  //   ),
                                  // ),
                                )));
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
                              id: "${albumController.album.value.title.hashCode.toString()}_appbar",
                              child: Text(
                                albumController.appBarTitleVisible.isTrue
                                    ? albumController.album.value.title
                                    : "",
                                maxLines: 1,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ),
                        ),
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
                            padding: EdgeInsets.only(
                              top: albumController.isSearchingOn.isTrue
                                  ? 0
                                  : landscape
                                      ? 150
                                      : 200,
                              bottom: 200,
                            ),
                            itemCount: albumController.songList.isEmpty
                                ? 4
                                : albumController.songList.length + 3,
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
                                              if (albumController.songList.isNotEmpty) {
                                                playerController.playPlayListSong(
                                                    List<MediaItem>.from(
                                                        albumController.songList),
                                                    0,
                                                    playfrom: PlaylingFrom(
                                                        name: albumController
                                                            .album.value.title,
                                                        type: PlaylingFromType.ALBUM));
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
                                              if (albumController.songList.isNotEmpty) {
                                                final songsToplay = List<MediaItem>.from(albumController.songList);
                                                songsToplay.shuffle();
                                                songsToplay.shuffle();
                                                playerController.playPlayListSong(
                                                    songsToplay, 0,
                                                    playfrom: PlaylingFrom(
                                                        name: albumController.album.value.title,
                                                        type: PlaylingFromType.ALBUM));
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
                                            final isAdded = albumController.isAddedToLibrary.isTrue;
                                            return _buildGlassCircleButton(
                                              context: context,
                                              icon: isAdded ? Icons.bookmark_added : Icons.bookmark_add,
                                              tooltip: isAdded ? "removeFromLibrary".tr : "addToLibrary".tr,
                                              iconColor: isAdded ? const Color(0xFFFFB0CD) : Colors.white,
                                              onTap: () {
                                                final add = !isAdded;
                                                albumController.addNremoveFromLibrary(
                                                    albumController.album.value,
                                                    add: add)
                                                .then((value) {
                                                  if (!context.mounted) return;
                                                  ScaffoldMessenger.of(context).showSnackBar(snackbar(
                                                      context,
                                                      value
                                                          ? add
                                                              ? "albumBookmarkAddAlert".tr
                                                              : "albumBookmarkRemoveAlert".tr
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
                                            tooltip: "enqueueAlbumSongs".tr,
                                            onTap: () {
                                              Get.find<PlayerController>().enqueueSongList(
                                                  albumController.songList.toList())
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
                                            final id = albumController.album.value.browseId;
                                            final isDownloaded = albumController.isDownloaded.isTrue;
                                            final isDownloading = controller.playlistQueue.containsKey(id) &&
                                                controller.currentPlaylistId.toString() == id;
                                            final isQueued = controller.playlistQueue.containsKey(id);

                                            return _buildGlassCircleButton(
                                              context: context,
                                              icon: isDownloaded ? Icons.download_done : (isQueued ? Icons.hourglass_bottom : Icons.download),
                                              tooltip: "downloadAlbumSongs".tr,
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
                                                      albumController.songList.toList());
                                                }
                                              },
                                            );
                                          }),
                                          // 6. Share Button
                                          _buildGlassCircleButton(
                                            context: context,
                                            icon: Icons.share,
                                            tooltip: "shareAlbum".tr,
                                            onTap: () {
                                              Share.share(
                                                  "https://youtube.com/playlist?list=${albumController.album.value.audioPlaylistId}");
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              } else if (index == 1) {
                                return buildTitleSubTitle(
                                    context, albumController);
                              } else if (index == 2) {
                                return SizedBox(
                                    height: albumController.isSearchingOn.isTrue
                                        ? 60
                                        : 40,
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          left: 15.0, right: 10),
                                      child: Obx(
                                        () => SortWidget(
                                          tag: albumController
                                              .album.value.browseId,
                                          screenController: albumController,
                                          isSearchFeatureRequired: true,
                                          itemCountTitle:
                                              "${albumController.songList.length}",
                                          itemIcon: Icons.music_note,
                                          titleLeftPadding: 9,
                                          requiredSortTypes:
                                              buildSortTypeSet(false, true),
                                          onSort: albumController.onSort,
                                          onSearch: albumController.onSearch,
                                          onSearchClose:
                                              albumController.onSearchClose,
                                          onSearchStart:
                                              albumController.onSearchStart,
                                          startAdditionalOperation:
                                              albumController
                                                  .startAdditionalOperation,
                                          selectAll: albumController.selectAll,
                                          performAdditionalOperation:
                                              albumController
                                                  .performAdditionalOperation,
                                          cancelAdditionalOperation:
                                              albumController
                                                  .cancelAdditionalOperation,
                                        ),
                                      ),
                                    ));
                              } else if (albumController
                                      .isContentFetched.isFalse ||
                                  albumController.songList.isEmpty) {
                                return SizedBox(
                                  height: 300,
                                  child: Center(
                                    child:
                                        albumController.isContentFetched.isFalse
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
                                              albumController.songList),
                                          index - 3,
                                          playfrom: PlaylingFrom(
                                              name: albumController
                                                  .album.value.title,
                                              type: PlaylingFromType.ALBUM));
                                    },
                                    song: albumController.songList[index - 3],
                                    isPlaylistOrAlbum: true,
                                    thumbReplacementWithIndex: true,
                                    index: index - 2),
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

  Widget buildTitleSubTitle(
      BuildContext context, AlbumScreenController albumController) {
    final title = albumController.album.value.title;
    final description = albumController.album.value.description;
    final artists =
        albumController.album.value.artists?.map((e) => e['name']).join(", ") ??
            "";
    return AnimatedBuilder(
      animation: albumController.animationController,
      builder: (context, child) {
        return SizedBox(
          height: albumController.heightAnimation.value,
          child: Transform.scale(
              scale: albumController.scaleAnimation.value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 25.0, bottom: 10, right: 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Marquee(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(seconds: 5),
              id: title.hashCode.toString(),
              child: Text(
                title.length > 50 ? title.substring(0, 50) : title,
                maxLines: 1,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge!
                    .copyWith(fontSize: 30),
              ),
            ),
            Text(
              description ?? "",
              maxLines: 1,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Marquee(
                delay: const Duration(milliseconds: 300),
                duration: const Duration(seconds: 5),
                id: artists.hashCode.toString(),
                child: Text(
                  artists,
                  maxLines: 1,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
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
