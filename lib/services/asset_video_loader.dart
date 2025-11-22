import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/instruction_model.dart';

class JsonParserService {
  static Future<InstructionModel?> parseInstructionsFromAssets(String path) async {
    try {
      print('Loading JSON file: $path');
      final String jsonString = await rootBundle.loadString(path);
      print('JSON string loaded: ${jsonString.length} characters');

      // Parse JSON directly without InstructionParser
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final InstructionModel instructionModel = InstructionModel.fromJson(jsonData);

      if (_isValidInstructionModel(instructionModel)) {
        print('JSON parsed successfully');
        print('Found ${instructionModel.instructions.length} instructions');
        return instructionModel;
      } else {
        print('JSON validation failed');
        return null;
      }
    } catch (e) {
      print('Error parsing JSON: $e');
      return null;
    }
  }

  static Future<InstructionModel?> parseInstructionsFromString(String jsonString) async {
    try {
      print('Parsing JSON string: ${jsonString.length} characters');

      final Map<String, dynamic> jsonData = json.decode(jsonString);
      final InstructionModel instructionModel = InstructionModel.fromJson(jsonData);

      if (_isValidInstructionModel(instructionModel)) {
        print('JSON string parsed successfully');
        return instructionModel;
      } else {
        print('JSON string validation failed');
        return null;
      }
    } catch (e) {
      print('Error parsing JSON string: $e');
      return null;
    }
  }

  static String convertToJsonString(InstructionModel instructionModel) {
    try {
      final Map<String, dynamic> jsonMap = instructionModel.toJson();
      return json.encode(jsonMap);
    } catch (e) {
      print('Error converting model to JSON: $e');
      return '{}';
    }
  }

  static InstructionModel getDefaultInstructions() {
    print('Creating default instructions');
    return _createDefaultInstructionModel();
  }

  // Validate instruction model
  static bool _isValidInstructionModel(InstructionModel model) {
    if (model.instructions.isEmpty) {
      print('No instructions found in model');
      return false;
    }

    for (var instruction in model.instructions) {
      if (instruction.type.isEmpty || instruction.name.isEmpty) {
        print('Instruction missing type or name');
        return false;
      }
      if (instruction.data.playlist.isEmpty) {
        print('Instruction has empty playlist');
        return false;
      }

      for (var item in instruction.data.playlist) {
        if (item.folder.isEmpty || item.files.isEmpty) {
          print('Playlist item missing folder or files');
          return false;
        }
        if (item.repeat <= 0) {
          print('Playlist item has invalid repeat value: ${item.repeat}');
          return false;
        }
      }
    }

    return true;
  }

  // Create default instruction model
  static InstructionModel _createDefaultInstructionModel() {
    return InstructionModel(
      instructions: [
        Instruction(
          type: 'update_schedule',
          name: 'default_schedule',
          data: InstructionData(
            playlistRepeat: 'always',
            playlist: [
              PlaylistItem(
                folder: 'videos/ads',
                files: ['sample1.mp4'],
                adId: 1,
                repeat: 1,
                sequence: 1,
              ),
              PlaylistItem(
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

  // Validate JSON string without parsing
  static bool isValidJsonString(String jsonString) {
    try {
      json.decode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Create instructions from video file list
  static InstructionModel createInstructionsFromVideoList(List<String> videoFiles, {String folder = 'videos/ads'}) {
    print('Creating instructions from video list: ${videoFiles.length} videos');

    final instructions = videoFiles.asMap().entries.map((entry) {
      final index = entry.key;
      final file = entry.value;

      return PlaylistItem(
        folder: folder,
        files: [file],
        adId: index + 1,
        repeat: 1,
        sequence: index + 1,
      );
    }).toList();

    return InstructionModel(
      instructions: [
        Instruction(
          type: 'update_schedule',
          name: 'video_schedule',
          data: InstructionData(
            playlistRepeat: 'always',
            playlist: instructions,
          ),
        ),
      ],
    );
  }

  // Generate sample instructions for testing
  static InstructionModel generateSampleInstructions() {
    print('Generating sample instructions');

    return InstructionModel(
      instructions: [
        Instruction(
          type: 'update_schedule',
          name: 'sample_schedule',
          data: InstructionData(
            playlistRepeat: 'always',
            playlist: [
              PlaylistItem(
                folder: 'videos/ads',
                files: ['sample1.mp4'],
                adId: 1,
                repeat: 1,
                sequence: 1,
              ),
              PlaylistItem(
                folder: 'videos/ads',
                files: ['sample2.mp4'],
                adId: 2,
                repeat: 1,
                sequence: 2,
              ),
              PlaylistItem(
                folder: 'videos/ads',
                files: ['sample3.mp4'],
                adId: 3,
                repeat: 1,
                sequence: 3,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Validate if JSON file exists and is accessible
  static Future<bool> validateJsonFile(String path) async {
    try {
      await rootBundle.loadString(path);
      print('JSON file is accessible: $path');
      return true;
    } catch (e) {
      print('JSON file not accessible: $path - $e');
      return false;
    }
  }

  // Get JSON file size
  static Future<int> getJsonFileSize(String path) async {
    try {
      final String jsonString = await rootBundle.loadString(path);
      final size = jsonString.length;
      print('JSON file size: $size characters');
      return size;
    } catch (e) {
      print('Error getting JSON file size: $e');
      return 0;
    }
  }

  // Load instructions from assets/instructions.json specifically
  static Future<InstructionModel?> loadInstructionsFromAssets() async {
    return await parseInstructionsFromAssets('assets/instructions.json');
  }

  // Get instructions with fallback to default if file not found
  static Future<InstructionModel> getInstructionsWithFallback() async {
    try {
      final instructions = await loadInstructionsFromAssets();
      if (instructions != null) {
        print('Instructions loaded from assets/instructions.json');
        return instructions;
      } else {
        print('Using default instructions (assets file not found or invalid)');
        return getDefaultInstructions();
      }
    } catch (e) {
      print('Error loading instructions, using default: $e');
      return getDefaultInstructions();
    }
  }
}