// lib/utils/image_loader.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 이미지 로딩 유틸리티 클래스
/// 로컬 파일 경로와 Firebase Storage URL 모두를 처리할 수 있음
class ImageLoader {
  /// 이미지 소스가 로컬 파일 경로인지 URL인지 판단하여 적절한 Image 위젯을 반환합니다.
  /// 
  /// [imageSource] 로컬 파일 경로 또는 네트워크 URL
  /// [fit] 이미지 표시 방식
  /// [placeholder] 로딩 중 표시할 위젯
  /// [errorWidget] 에러 발생 시 표시할 위젯
  static Widget loadImage({
    required String? imageSource,
    BoxFit fit = BoxFit.cover,
    Widget Function(BuildContext, String)? placeholder,
    Widget Function(BuildContext, String, Object)? errorWidget,
  }) {
    // 이미지 소스가 없을 경우 빈 컨테이너 반환
    if (imageSource == null || imageSource.isEmpty) {
      return const SizedBox.shrink();
    }

    // URL 형식인지 확인 (간단한 체크)
    bool isUrl = imageSource.startsWith('http://') || imageSource.startsWith('https://');

    if (isUrl) {
      // 네트워크 이미지인 경우 CachedNetworkImage 사용
      return CachedNetworkImage(
        imageUrl: imageSource,
        fit: fit,
        placeholder: placeholder ?? (_, __) => const Center(child: CircularProgressIndicator()),
        errorWidget: errorWidget ?? (_, __, ___) => const Icon(Icons.error),
      );
    } else {
      // 로컬 파일 경로인 경우 FileImage 사용
      try {
        final file = File(imageSource);
        return Image.file(
          file,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget?.call(context, imageSource, error) ?? const Icon(Icons.error);
          },
        );
      } catch (e) {
        // 파일 경로가 유효하지 않은 경우 기본 에러 위젯 반환
        return const Icon(Icons.error);
      }
    }
  }
}