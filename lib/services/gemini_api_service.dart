// lib/services/gemini_api_service.dart
import 'dart:convert';
import 'dart:typed_data';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // 더 이상 필요하지 않습니다.
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:roomstyler/core/models/scene.dart'; // Scene 모델 임포트
import 'package:roomstyler/config.dart'; // Config 임포트

class GeminiApiService {
  // Config에서 API 키를 가져옵니다.
  // static final String? _apiKey = dotenv.env['GEMINI_API_KEY']; // 기존 코드 주석 처리
  static final String _apiKey = Config.geminiApiKey; // 새 코드

  /// AI 자동 배치 기능
  /// 
  /// [imageBytes] 방의 배경 이미지 (Uint8List)
  /// [scene] 현재 씬 정보. 여기서 배치할 가구 목록(addedFurnitureIds)을 가져옵니다.
  /// 
  /// Returns: 성공 시 배치된 아이템 목록을 포함한 Map, 실패 시 null.
  static Future<List<SceneLayoutItem>?> getFurniturePlacement({
    required Uint8List imageBytes,
    required Scene scene, // 전체 Scene 객체를 전달하여 더 많은 정보 활용 가능
  }) async {
    // if (_apiKey == null) { // 기존 조건문 수정
    if (_apiKey.isEmpty) { // 새 조건문
      print('GEMINI_API_KEY가 설정되지 않았습니다.');
      return null;
    }

    // Gemini 모델 초기화
    final model = GenerativeModel(
      model: 'gemini-1.5-flash-latest', // 최신이고 가벼운 모델
      apiKey: _apiKey,
    );

    // 배치할 가구 ID 목록 가져오기 (예시)
    final itemsToPlace = scene.addedFurnitureIds;
    if (itemsToPlace.isEmpty) {
      print('배치할 가구가 없습니다.');
      return []; // 빈 리스트 반환
    }

    // Firestore에서 가구 이름 등을 가져오는 로직이 필요할 수 있음.
    // 여기서는 단순화 위해 ID만 사용. 실제 구현 시 가구 이름 목록을 만드는 것이 좋음.
    // 예: final furnitureNames = await _getFurnitureNames(itemsToPlace);

    // Gemini에게 보낼 프롬프트 (요청) 구성
    final prompt = [
      Content.multi([
        TextPart("""
          당신은 인테리어 디자이너 AI입니다.
          이 비어있는 방 사진을 보고, 사용자가 요청한 가구 목록을 가장 이상적으로 배치할 위치를 추천해주세요.
          방의 가로, 세로 크기를 각각 1.0이라고 가정하고, 각 가구의 위치(x, y), 크기(scale), 회전값(rotation)을 JSON 형식으로 반환해주세요.
          x, y 좌표는 이미지의 좌측 상단을 (0,0), 우측 하단을 (1,1) 기준으로 합니다.
          반드시 아래 JSON 형식만 반환하고, 다른 설명은 절대 추가하지 마세요.

          요청 가구 ID 목록: ${itemsToPlace.join(', ')}
          
          JSON 형식 (반드시 이 형식을 지켜주세요):
          {
            "arranged_items": [
              { "furniture_id": "furniture_id_string", "x": 0.5, "y": 0.5, "scale": 1.0, "rotation": 0.0 }
            ]
          }
        """),
        // 이미지 데이터를 함께 첨부
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    try {
      print('Gemini API 호출 시작...');
      final response = await model.generateContent(prompt);
      print('Gemini API 응답: ${response.text}');

      // 응답 텍스트에서 JSON 부분만 추출 (설명이 섞여 있을 수 있으므로)
      // 간단한 방법: '{'와 '}' 사이의 내용을 찾아 파싱
      final jsonString = _extractJson(response.text ?? '');
      if (jsonString.isEmpty) {
        print('응답에서 유효한 JSON을 찾을 수 없습니다: ${response.text}');
        return null;
      }

      // 모델의 응답 텍스트를 JSON으로 파싱
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      if (jsonData['arranged_items'] is List) {
        final items = jsonData['arranged_items'] as List;
        return items.map((item) {
          final map = item as Map<String, dynamic>;
          return SceneLayoutItem(
            furnitureId: map['furniture_id'] as String? ?? '',
            // name과 imageUrl은 나중에 Firestore에서 가져와야 함. 임시로 ID 사용.
            name: map['furniture_id'] as String? ?? 'Unknown',
            imageUrl: '', // 임시
            x: (map['x'] as num?)?.toDouble() ?? 0.5,
            y: (map['y'] as num?)?.toDouble() ?? 0.5,
            scale: (map['scale'] as num?)?.toDouble() ?? 1.0,
            rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();
      } else {
        print('arranged_items가 리스트가 아닙니다.');
        return null;
      }
    } catch (e) {
      print('Gemini API 호출 중 에러 발생: $e');
      return null;
    }
  }

  // 응답 텍스트에서 JSON 객체 부분만 추출하는 헬퍼 함수
  static String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return '';
  }

  /// (선택적) 가구 ID 목록을 받아 이름 목록을 반환하는 함수 예시
  /// 실제 구현 시 Firestore에서 가구 정보를 조회해야 함.
  /*
  static Future<List<String>> _getFurnitureNames(List<String> furnitureIds) async {
    // 예시: Firestore에서 furnitureIds에 해당하는 문서들을 한 번에 가져오기
    // final docs = await FirebaseFirestore.instance
    //     .collection('furnitures')
    //     .where(FieldPath.documentId, whereIn: furnitureIds)
    //     .get();
    // return docs.docs.map((doc) => doc.data().name).toList();
    
    // 임시: ID를 그대로 이름으로 사용
    return furnitureIds;
  }
  */
}