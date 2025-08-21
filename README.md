# RoomStyler

사진 한 장으로 내 방을 가상으로 꾸며볼 수 있는 AI 인테리어 시뮬레이션 앱입니다. Flutter를 사용하여 Android, iOS, Web, Desktop 등 크로스플랫폼을 지원합니다.

## 📸 주요 기능

| 기능 | 구현 상태 | 상세 설명 |
| --- | :---: | --- |
| **홈 화면** | ✅ 완료 | 최근 프로젝트, 스타일별 추천 등 앱의 메인 화면을 표시합니다. |
| **사용자 인증** | ✅ 완료 | Firebase Auth(App Check 포함)를 이용한 이메일/비밀번호 회원가입 및 로그인이 구현되었습니다. |
| **방 사진 업로드** | ✅ 완료 | 갤러리/카메라에서 사진을 가져오는 기능이 구현되었습니다. ClipDrop Reimagine API를 통해 방 사진에서 기존 가구를 제거하는 기능이 추가되었습니다. |
| **가구 카탈로그** | ✅ 완료 | Firestore와 연동하여 실제 가구 데이터를 실시간으로 불러옵니다. |
| **배치 편집기** | ✅ 완료 | 가구를 추가하고, 이동/크기조절/회전/삭제하는 핵심 기능이 구현되었습니다. 상태 관리는 Riverpod를 사용합니다. |
| **프로젝트 저장**| ✅ 완료 | 사용자가 꾸민 씬(Scene)을 Firestore에 사용자별로 저장하는 기능이 구현되었습니다. |
| **프로젝트 로드**| ✅ 완료 | 홈 화면에서 Firestore에 저장된 사용자의 프로젝트 목록을 불러와 표시하고, 선택 시 해당 씬을 편집기로 불러옵니다. |
| **AI 자동 배치** | ✅ 완료 | Gemini API를 이용하여 배경 이미지와 추가한 가구 목록을 기반으로 AI가 자동으로 배치해주는 기능이 구현되었습니다. |
| **결과 미리보기/공유**| 🟡 개발 중 | 최종 렌더링된 결과물은 샘플 이미지로 표시됩니다. `share_plus`를 이용한 공유 기능은 구현되었습니다. |
| **데이터 모델** | ✅ 완료 | `Room`, `Furniture`, `Scene` 등 Firestore와 연동될 데이터 모델이 정의되어 있습니다. |
| **상태 관리** | ✅ 완료 | `flutter_riverpod`를 사용하여 편집기의 `Scene` 상태를 관리하는 `SceneController`가 구현되어 있습니다. |

## 🛠️ 기술 스택

- **Framework:** [Flutter](https://flutter.dev)
- **State Management:** [Flutter Riverpod](https://riverpod.dev/)
- **Routing:** [go_router](https://pub.dev/packages/go_router)
- **Backend & DB:** [Firebase Auth](https://firebase.google.com/products/auth), [Cloud Firestore](https://firebase.google.com/products/firestore), [App Check](https://firebase.google.com/products/app-check)
- **Image:** [image_picker](https://pub.dev/packages/image_picker), [cached_network_image](https://pub.dev/packages/cached_network_image)
- **Sharing:** [share_plus](https://pub.dev/packages/share_plus)
- **HTTP Client:** [http](https://pub.dev/packages/http) (API 연동 시 사용)
- **AI API:** [Google Generative AI (Gemini)](https://pub.dev/packages/google_generative_ai), [ClipDrop](https://clipdrop.co/)
- **Utilities:** [uuid](https://pub.dev/packages/uuid), [intl](https://pub.dev/packages/intl)

## 🚀 시작하기

### 1. Firebase 프로젝트 설정
- Firebase Console에서 프로젝트를 생성합니다.
- **Authentication**: 이메일/비밀번호 제공업체를 활성화합니다.
- **Firestore**: 데이터베이스를 생성하고, `furnitures` 컬렉션을 만듭니다.
- **App Check**: 안드로이드 앱을 등록하고 Play Integrity 또는 reCAPTCHA v3를 활성화합니다.

### 2. API 키 설정
- `lib/config.dart` 파일을 생성하고, 아래와 같이 API 키를 설정합니다.
    ```dart
    class Config {
      static const String geminiApiKey = 'YOUR_GEMINI_API_KEY_HERE';
      static const String clipdropApiKey = 'YOUR_CLIPDROP_API_KEY_HERE';
    }
    ```
- 이 파일은 `.gitignore`에 포함되어 공유되지 않도록 합니다.

### 3. 로컬 설정

```bash
# 프로젝트 클론
git clone https://your-repository-url.git
cd roomstyler

# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트와 연결
flutterfire configure

# 안드로이드 SHA-1, SHA-256 키를 Firebase 콘솔에 등록
./android/gradlew -p android signingReport

# Flutter 패키지 설치
flutter pub get
```

### 4. 앱 실행
```bash
flutter run
```

## 📝 향후 과제 (Next Steps)

- [ ] **결과 미리보기/공유 기능 고도화**
  - 최종 결과물을 실제 편집 화면 캡처나 렌더링 방식으로 개선합니다.
  - SNS 공유 및 구매 링크 연결 기능을 추가합니다.
- [ ] **소셜 로그인 추가**
  - Google, Apple 등 소셜 로그인 기능을 추가하여 사용자 접근성을 높입니다.
- [ ] **테스트 코드 작성**
  - 각 기능에 대한 위젯 테스트 및 통합 테스트 코드를 작성하여 앱의 안정성을 높입니다.
- [ ] **추천 기능 구현**
  - 홈 화면의 "스타일별 추천" 영역에 추천 알고리즘을 적용하여 개인화된 가구를 추천합니다.