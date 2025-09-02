# RoomStyler

사진 한 장으로 내 방을 가상으로 꾸며볼 수 있는 AI 인테리어 시뮬레이션 앱입니다. Flutter를 사용하여 Android, iOS, Web, Desktop 등 크로스플랫폼을 지원합니다.

## 📸 주요 기능

| 기능 | 구현 상태 | 상세 설명 |
| --- | :---: | --- |
| **홈 화면** | ✅ 완료 | 최근 프로젝트, 스타일별 추천 등 앱의 메인 화면을 표시합니다. |
| **사용자 인증** | ✅ 완료 | Firebase Auth(App Check 포함)를 이용한 이메일/비밀번호 및 Google 소셜 로그인이 구현되었습니다. |
| **방 사진 업로드** | ✅ 완료 | 갤러리/카메라에서 사진을 가져오는 기능이 구현되었습니다. ClipDrop Reimagine API를 통해 방 사진에서 기존 가구를 제거하는 기능이 추가되었습니다. |
| **가구 카탈로그** | ✅ 완료 | Firestore와 연동하여 실제 가구 데이터를 실시간으로 불러옵니다. 카테고리 및 검색 기능이 포함되어 있습니다. |
| **배치 편집기** | ✅ 완료 | 가구를 추가하고, 이동/크기조절/회전/삭제하는 핵심 기능이 구현되었습니다. 상태 관리는 Riverpod를 사용합니다. |
| **프로젝트 저장**| ✅ 완료 | 사용자가 꾸민 씬(Scene)을 Firestore에 사용자별로 저장하는 기능이 구현되었습니다. |
| **프로젝트 로드**| ✅ 완료 | 홈 화면에서 Firestore에 저장된 사용자의 프로젝트 목록을 불러와 표시하고, 선택 시 해당 씬을 편집기로 불러옵니다. |
| **AI 자동 배치** | ✅ 완료 | Gemini API를 이용하여 배경 이미지와 추가한 가구 목록을 기반으로 AI가 자동으로 배치해주는 기능이 구현되었습니다. |
| **결과 미리보기/공유**| ✅ 완료 | 편집 결과물을 캡처하여 공유하는 기능이 구현되었습니다. |
| **마이 페이지** | ✅ 완료 | 사용자 프로필, 계정 설정(비밀번호 변경, 알림, 테마), 내 프로젝트 관리(삭제, 이름변경, 홈화면고정), 찜 목록, 앱 정보(버전, 도움말)를 관리할 수 있는 페이지입니다. |
| **데이터 모델** | ✅ 완료 | `Room`, `Furniture`, `Scene` 등 Firestore와 연동될 데이터 모델이 정의되어 있습니다. |
| **상태 관리** | ✅ 완료 | `flutter_riverpod`를 사용하여 편집기의 `Scene` 상태를 관리하는 `SceneController`가 구현되어 있습니다. |
| **Undo/Redo** | ✅ 완료 | 편집기에서 가구 추가/이동/삭제 등의 작업에 대해 실행 취소(Undo)와 다시 실행(Redo) 기능이 구현되었습니다. |

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
- **Authentication**: 이메일/비밀번호 및 Google 로그인 제공업체를 활성화합니다.
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

## 🧪 테스트

### 테스트 실행

```bash
# 모든 테스트 실행
flutter test

# 테스트 커버리지 확인
flutter test --coverage
```

### 테스트 구조

테스트는 다음과 같은 구조로 구성되어 있습니다:
- `widget_test.dart`: 기본 위젯 테스트
- `router_test.dart`: 라우터 테스트
- `features/`: 기능별 테스트 (홈 화면, 인증, 마이 페이지, 카탈로그, 편집기 등)
- `state/`: 상태 관리 테스트 (테마 제공자, 씬 제공자, 찜 목록 제공자 등)

자세한 테스트 계획은 [TEST_PLAN.md](TEST_PLAN.md) 파일을 참조하세요.

## 📝 향후 과제 (Next Steps)

- [x] **테스트 코드 작성**
  - 각 기능에 대한 위젯 테스트 및 통합 테스트 코드를 작성하여 앱의 안정성을 높입니다.
- [ ] **추천 기능 구현**
  - 홈 화면의 "스타일별 추천" 영역에 추천 알고리즘을 적용하여 개인화된 가구를 추천합니다.
- [ ] **편집기 기능 확장**
  - 가구의 크기, 색상, 재질 등을 조정할 수 있는 더 세부적인 편집 기능을 추가합니다.
  - Undo/Redo 기능을 구현하여 편집 경험을 향상시킵니다.
- [ ] **결과물 렌더링 고도화**
  - 현재는 편집기 화면을 캡처하여 공유하지만, 실제 3D 렌더링된 고품질 이미지를 생성하여 저장 및 공유하는 기능을 추가할 수 있습니다.
- [x] **방꾸미기 기능 고도화 (완료)**
  - Undo/Redo 기능 구현
  - 하단 UI로 이동 (Undo/Redo/찜 목록 버튼)
  - 찜 목록 패널 위치 변경
  - 찜 목록 휴지통 드래그 영역 조절
  - 배치된 가구 휴지통 드래그 삭제
  - 배경 이미지 영역 조절
- [x] **마이페이지 기능 고도화 (완료)**
  - 테마 설정 (라이트/다크/시스템)
  - 찜 목록 관리 (보기, 삭제)
  - 내 프로젝트 관리 (더보기, 홈화면고정, 선택삭제)
  - 계정 설정 (비밀번호변경)
  - UI 깜빡임 문제 해결
  - 프로젝트 카드 오버플로우 문제 해결
- [x] **가구 카탈로그 개선 (완료)**
  - 카탈로그 화면에서 불필요한 버튼 제거
  - 가구 카드 오버플로우 문제 해결
  - 가구 가격 표시 개선 (천 단위 구분자 추가)
- [ ] **방꾸미기 삭제(찜리스트, 배치된 가구) 버그 수정 필요**
  - 드래그 앤 드롭 삭제 기능의 정확한 동작 범위 수정
- [ ] **검색 기능 개선**
  - 현재 Firestore의 접두사 검색 방식에서 중간 단어 검색으로 개선 필요
  - Algolia나 Elasticsearch 같은 전용 검색 서비스 도입 검토
