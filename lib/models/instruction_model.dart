import 'schedule_models.dart' show ScheduleItem;

class InstructionModel {
  final List<Instruction> instructions;

  InstructionModel({required this.instructions});

  factory InstructionModel.fromJson(Map<String, dynamic> json) {
    var instructionsList = json['instructions'] as List;
    List<Instruction> instructions = instructionsList
        .map((instruction) => Instruction.fromJson(instruction as Map<String, dynamic>))
        .toList();

    return InstructionModel(instructions: instructions);
  }

  Map<String, dynamic> toJson() {
    return {
      'instructions': instructions.map((instruction) => instruction.toJson()).toList(),
    };
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
}

class InstructionData {
  final String playlistRepeat;
  final List<ScheduleItem> playlist;

  InstructionData({required this.playlistRepeat, required this.playlist});

  factory InstructionData.fromJson(Map<String, dynamic> json) {
    var playlistList = json['playlist'] as List;
    List<ScheduleItem> playlist = playlistList
        .map((item) => ScheduleItem.fromJson(item as Map<String, dynamic>))
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
}