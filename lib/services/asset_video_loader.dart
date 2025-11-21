import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/instruction_model.dart';

class JsonParserService {
  static Future<InstructionModel?> parseInstructionsFromAssets(String path) async {
    try {
      print('JSON ফাইল লোড করা হচ্ছে: $path');
      final String jsonString = await rootBundle.loadString(path);
      print('JSON স্ট্রিং লোড করা হয়েছে: ${jsonString.length} characters');

      final InstructionModel instructionModel = InstructionParser.parseFromJsonString(jsonString);

      if (InstructionParser.isValidInstructionModel(instructionModel)) {
        print('JSON সফলভাবে পার্স করা হয়েছে');
        print('পাওয়া গেছে ${instructionModel.instructions.length}টি নির্দেশনা');
        return instructionModel;
      } else {
        print('JSON ভ্যালিডেশন失败');
        return null;
      }
    } catch (e) {
      print('JSON পার্স করতে সমস্যা: $e');
      return null;
    }
  }

  static Future<InstructionModel?> parseInstructionsFromString(String jsonString) async {
    try {
      print('JSON স্ট্রিং পার্স করা হচ্ছে: ${jsonString.length} characters');

      final InstructionModel instructionModel = InstructionParser.parseFromJsonString(jsonString);

      if (InstructionParser.isValidInstructionModel(instructionModel)) {
        print('JSON স্ট্রিং সফলভাবে পার্স করা হয়েছে');
        return instructionModel;
      } else {
        print('JSON স্ট্রিং ভ্যালিডেশন失败');
        return null;
      }
    } catch (e) {
      print('JSON স্ট্রিং পার্স করতে সমস্যা: $e');
      return null;
    }
  }

  static String convertToJsonString(InstructionModel instructionModel) {
    try {
      return InstructionParser.convertToJsonString(instructionModel);
    } catch (e) {
      print('মডেল থেকে JSON এ কনভার্ট করতে সমস্যা: $e');
      return '{}';
    }
  }

  static InstructionModel getDefaultInstructions() {
    print('ডিফল্ট নির্দেশনা তৈরি করা হচ্ছে');
    return InstructionParser.createDefaultInstructionModel();
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
}