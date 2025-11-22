class Schedule {
  final String playlistRepeat;
  final List<ScheduleItem> playlist;

  Schedule({required this.playlistRepeat, required this.playlist});

  factory Schedule.fromJson(Map<String, dynamic> json) {
    var playlistList = json['playlist'] as List;
    List<ScheduleItem> playlist = playlistList
        .map((item) => ScheduleItem.fromJson(item as Map<String, dynamic>))
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

class ScheduleItem {
  final String folder;
  final List<String> files;
  final int adId;
  final int repeat;
  final int sequence;

  ScheduleItem({
    required this.folder,
    required this.files,
    required this.adId,
    required this.repeat,
    required this.sequence,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    var filesList = json['files'] as List;
    List<String> files = filesList.map((file) => file as String).toList();

    return ScheduleItem(
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