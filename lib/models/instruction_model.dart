import 'dart:convert';

class InstructionModel {
  final List<Instruction> instructions;

  InstructionModel({required this.instructions});

  factory InstructionModel.fromJson(Map<String, dynamic> json) {
    var instructionsList = json['instructions'] as List;
    List<Instruction> instructions = instructionsList
        .map((instruction) => Instruction.fromJson(instruction))
        .toList();

    return InstructionModel(instructions: instructions);
  }

  Map<String, dynamic> toJson() {
    return {
      'instructions': instructions.map((instruction) => instruction.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return 'InstructionModel(instructions: $instructions)';
  }
}

class Instruction {
  final String type;
  final String name;
  final InstructionData data;

  Instruction({required this.type, required this.name, required this.data});

  factory Instruction.fromJson(Map<String, dynamic> json) {
    return Instruction(
      type: json['type'] as String,
      name: json['name'] as String,
      data: InstructionData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'name': name,
      'data': data.toJson(),
    };
  }

  @override
  String toString() {
    return 'Instruction(type: $type, name: $name, data: $data)';
  }
}

class InstructionData {
  final String playlistRepeat;
  final List<PlaylistItem> playlist;

  InstructionData({required this.playlistRepeat, required this.playlist});

  factory InstructionData.fromJson(Map<String, dynamic> json) {
    var playlistList = json['playlist'] as List;
    List<PlaylistItem> playlist = playlistList
        .map((item) => PlaylistItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return InstructionData(
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

  @override
  String toString() {
    return 'InstructionData(playlistRepeat: $playlistRepeat, playlist: $playlist)';
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

  @override
  String toString() {
    return 'PlaylistItem(folder: $folder, files: $files, adId: $adId, repeat: $repeat, sequence: $sequence)';
  }
}

// JSON parsing helper functions
class InstructionParser {
  static InstructionModel parseFromJsonString(String jsonString) {
    try {
      Map<String, dynamic> jsonData = json.decode(jsonString);
      return InstructionModel.fromJson(jsonData);
    } catch (e) {
      throw FormatException('JSON পার্স করতে সমস্যা: $e');
    }
  }

  static String convertToJsonString(InstructionModel instructionModel) {
    try {
      return json.encode(instructionModel.toJson());
    } catch (e) {
      throw FormatException('JSON এ কনভার্ট করতে সমস্যা: $e');
    }
  }

  static InstructionModel createDefaultInstructionModel() {
    return InstructionModel(
      instructions: [
        Instruction(
          type: 'update_schedule',
          name: 'default_schedule',
          data: InstructionData(
            playlistRepeat: 'always',
            playlist: [
              PlaylistItem(
                folder: 'assets/videos',
                files: ['sample1.mp4'],
                adId: 1,
                repeat: 2,
                sequence: 1,
              ),
              PlaylistItem(
                folder: 'assets/videos',
                files: ['sample2.mp4'],
                adId: 2,
                repeat: 1,
                sequence: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Validate instruction model
  static bool isValidInstructionModel(InstructionModel model) {
    if (model.instructions.isEmpty) return false;

    for (var instruction in model.instructions) {
      if (instruction.type.isEmpty || instruction.name.isEmpty) return false;
      if (instruction.data.playlist.isEmpty) return false;

      for (var item in instruction.data.playlist) {
        if (item.folder.isEmpty || item.files.isEmpty) return false;
        if (item.repeat <= 0) return false;
      }
    }

    return true;
  }
}