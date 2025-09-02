// lib/services/ai_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:roomstyler/core/models/scene.dart';
// import 'package:roomstyler/services/gemini_api_service.dart'; // 기존 Gemini 1.5 Flash 서비스 임포트 (주석 처리)
import 'package:roomstyler/services/gemini_api_service.dart'; // 새로운 Gemini Live 서비스 임포트 (같은 파일명이지만 내용이 변경됨)
import 'package:roomstyler/config.dart'; // Config 임포트 (API 키 사용을 위해)

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
    // --- 기존 Google Gemini 1.5 Flash API 호출 로직 (주석 처리) ---
    /*
    // 1. GeminiApiService 호출
    final arrangedItems = await GeminiApiService.getFurniturePlacement(
      imageBytes: imageBytes,
      scene: scene,
    );

    // 2. 응답 처리 (이미 GeminiApiService에서 처리됨)
    return arrangedItems;
    */
    // --- 기존 Google Gemini 1.5 Flash API 호출 로직 끝 ---

    // --- 새로운 Google Gemini Live 2.5 Flash Preview API 호출 로직 ---
    // 1. Config에서 API 키 가져오기
    final String geminiApiKey = Config.geminiApiKey;

    if (geminiApiKey.isEmpty) {
      print('AiService.autoArrange: GEMINI_API_KEY가 설정되지 않았습니다.');
      return null;
    }

    // 2. 배치할 가구 ID 목록 가져오기
    final itemsToPlace = scene.addedFurnitureIds;
    if (itemsToPlace.isEmpty) {
      print('AiService.autoArrange: 배치할 가구가 없습니다.');
      return []; // 빈 리스트 반환
    }

    try {
      // 3. Gemini Live API를 사용하여 가구 배치 요청
      final arrangedItemMaps = await GeminiLiveApiService.getFurniturePlacementFromLive(
        imageBytes: imageBytes,
        furnitureIds: itemsToPlace,
        apiKey: geminiApiKey,
      );

      if (arrangedItemMaps != null) {
        // 4. 응답 데이터를 SceneLayoutItem 객체로 변환
        final arrangedItems = arrangedItemMaps.map((itemMap) {
          return SceneLayoutItem(
            furnitureId: itemMap['furniture_id'] as String? ?? '',
            // name과 imageUrl은 나중에 Firestore에서 가져와야 함. 임시로 ID 사용.
            name: itemMap['furniture_id'] as String? ?? 'Unknown',
            imageUrl: '', // 임시
            x: (itemMap['x'] as num?)?.toDouble() ?? 0.5,
            y: (itemMap['y'] as num?)?.toDouble() ?? 0.5,
            scale: (itemMap['scale'] as num?)?.toDouble() ?? 1.0,
            rotation: (itemMap['rotation'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        return arrangedItems;
      } else {
        // 5. 처리 실패
        print('AiService.autoArrange: Gemini Live API 호출에 실패했습니다. 배치된 아이템 목록을 받지 못했습니다.');
        return null;
      }
    } catch (e) {
      print('AiService.autoArrange: Gemini Live API 호출 중 에러 발생: $e');
      return null;
    }
    // --- 새로운 Google Gemini Live 2.5 Flash Preview API 호출 로직 끝 ---
  }
}