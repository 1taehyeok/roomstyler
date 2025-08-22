// lib/services/ai_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:roomstyler/core/models/scene.dart';
import 'package:roomstyler/services/gemini_api_service.dart';

/// AI와 관련된 비즈니스 로직을 처리하는 서비스 클래스입니다.
class AiService {
  /// 주어진 배경 이미지와 씬을 기반으로, AI를 사용하여 가구를 자동 배치합니다.
  ///
  /// [imageBytes]: 배경 이미지의 바이트 데이터
  /// [scene]: 현재 씬 객체
  ///
  /// Returns: 배치된 가구 아이템 목록. 실패 시 null.
  ///
  /// Throws: AI API 호출 중 발생한 예외
  static Future<List<SceneLayoutItem>?> autoArrange(Uint8List imageBytes, Scene scene) async {
    // 1. GeminiApiService 호출
    final arrangedItems = await GeminiApiService.getFurniturePlacement(
      imageBytes: imageBytes,
      scene: scene,
    );

    // 2. 응답 처리 (이미 GeminiApiService에서 처리됨)
    return arrangedItems;
  }
}