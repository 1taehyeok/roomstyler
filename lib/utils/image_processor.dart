// lib/utils/image_processor.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// 이미지 처리 유틸리티 클래스
class ImageProcessor {
  /// 이미지를 리사이징하고 JPEG로 압축합니다.
  /// 
  /// [imageFile] 원본 이미지 파일
  /// [maxWidth] 리사이징할 최대 너비 (기본값: 1920px)
  /// [quality] JPEG 압축 품질 (0-100, 기본값: 80)
  /// 
  /// Returns: 압축된 이미지의 Uint8List
  static Future<Uint8List> resizeAndCompressImage(
    File imageFile, {
    int maxWidth = 1920,
    int quality = 80,
  }) async {
    try {
      // 파일에서 바이트 데이터 읽기
      final imageBytes = await imageFile.readAsBytes();
      
      // 이미지 디코딩
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('이미지 디코딩에 실패했습니다.');
      }
      
      // 이미지 리사이징
      final resizedImage = img.copyResize(
        image,
        width: maxWidth,
        maintainAspect: true,
      );
      
      // JPEG로 압축
      final compressedImage = img.encodeJpg(resizedImage, quality: quality);
      
      return compressedImage;
    } catch (e) {
      // 압축 실패 시 원본 반환
      print('이미지 압축 중 오류 발생: $e');
      return await imageFile.readAsBytes();
    }
  }

  /// Uint8List 형식의 이미지를 리사이징하고 JPEG로 압축합니다.
  /// 
  /// [imageBytes] 원본 이미지 바이트 데이터
  /// [maxWidth] 리사이징할 최대 너비 (기본값: 1920px)
  /// [quality] JPEG 압축 품질 (0-100, 기본값: 80)
  /// 
  /// Returns: 압축된 이미지의 Uint8List
  static Future<Uint8List> resizeAndCompressImageBytes(
    Uint8List imageBytes, {
    int maxWidth = 1920,
    int quality = 80,
  }) async {
    try {
      // 이미지 디코딩
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('이미지 디코딩에 실패했습니다.');
      }
      
      // 이미지 리사이징
      final resizedImage = img.copyResize(
        image,
        width: maxWidth,
        maintainAspect: true,
      );
      
      // JPEG로 압축
      final compressedImage = img.encodeJpg(resizedImage, quality: quality);
      
      return compressedImage;
    } catch (e) {
      // 압축 실패 시 원본 반환
      print('이미지 압축 중 오류 발생: $e');
      return imageBytes;
    }
  }

  /// 이미지 파일을 임시 파일로 저장합니다.
  /// 
  /// [imageBytes] 이미지 바이트 데이터
  /// [fileName] 저장할 파일 이름 (확장자 제외)
  /// 
  /// Returns: 임시 파일 경로
  static Future<String> saveToTempFile(Uint8List imageBytes, String fileName) async {
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/${fileName}_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(imageBytes);
    return tempFile.path;
  }
}