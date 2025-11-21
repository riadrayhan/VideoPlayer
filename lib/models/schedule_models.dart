class Schedule {
  final String playlistRepeat;
  final List<PlaylistItem> playlist;

  Schedule({required this.playlistRepeat, required this.playlist});

  factory Schedule.fromJson(Map<String, dynamic> json) {
    var playlistList = json['playlist'] as List;
    List<PlaylistItem> playlist = playlistList
        .map((item) => PlaylistItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return Schedule(
      playlistRepeat: json['playlist_repeat'] as String,
      playlist: playlist,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playlist_repeat': playlistRepeat,
      'playlist': playlist.map((item) => item.toJson()).toList(),
    };
  }
}

class PlaylistItem {
  final String folder;
  final List<String> files;
  final int adId;
  final int repeat;
  final int sequence;

  PlaylistItem({
    required this.folder,
    required this.files,
    required this.adId,
    required this.repeat,
    required this.sequence,
  });

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    var filesList = json['files'] as List;
    List<String> files = filesList.map((file) => file as String).toList();

    return PlaylistItem(
      folder: json['folder'] as String,
      files: files,
      adId: json['ad_id'] as int,
      repeat: json['repeat'] as int,
      sequence: json['sequence'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'folder': folder,
      'files': files,
      'ad_id': adId,
      'repeat': repeat,
      'sequence': sequence,
    };
  }
}