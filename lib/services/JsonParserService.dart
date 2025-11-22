import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/instruction_model.dart';
import '../models/schedule_models.dart' show ScheduleItem;

class JsonParserService {
  static Future<InstructionModel?> parseInstructionsFromAssets(String path) async {
    try {
      final String jsonString = await rootBundle.loadString(path);
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final instructionModel = InstructionModel.fromJson(jsonData);

      if (_isValidInstructionModel(instructionModel)) {
        return instructionModel;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static Future<InstructionModel?> parseInstructionsFromString(String jsonString) async {
    try {
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final instructionModel = InstructionModel.fromJson(jsonData);

      if (_isValidInstructionModel(instructionModel)) {
        return instructionModel;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  static bool _isValidInstructionModel(InstructionModel model) {
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

  static InstructionModel getDefaultInstructions() {
    return InstructionModel(
      instructions: [
        Instruction(
          type: 'update_schedule',
          name: 'default_schedule',
          data: InstructionData(
            playlistRepeat: 'always',
            playlist: [
              ScheduleItem(
                folder: 'videos/ads',
                files: ['sample1.mp4'],
                adId: 1,
                repeat: 1,
                sequence: 1,
              ),
              ScheduleItem(
                folder: 'videos/ads',
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
}