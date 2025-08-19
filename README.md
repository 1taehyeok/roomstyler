# RoomStyler

사진 한 장으로 내 방을 가상으로 꾸며볼 수 있는 AI 인테리어 시뮬레이션 앱입니다. Flutter를 사용하여 Android, iOS, Web, Desktop 등 크로스플랫폼을 지원합니다.

## 📸 주요 기능

| 기능 | 구현 상태 | 상세 설명 |
| --- | :---: | --- |
| **홈 화면** | ✅ 완료 | 최근 프로젝트, 스타일별 추천 등 앱의 메인 화면을 표시합니다. |
| **사용자 인증** | ❌ 미완료 | UI만 구현되어 있으며, Firebase Auth를 이용한 실제 소셜/이메일 로그인 기능은 연동되지 않았습니다. |
| **방 사진 업로드** | 🟡 개발 중 | 갤러리/카메라에서 사진을 가져오는 기능은 구현되었습니다. 하지만 AI를 이용한 기존 가구 제거 API 연동은 필요합니다. |
| **가구 카탈로그** | 🟡 개발 중 | 카테고리 필터링, 검색 UI가 구현되었습니다. 실제 가구 데이터는 Firestore 연동 전이며, 현재는 더미 데이터를 사용합니다. |
| **배치 편집기** | 🟡 개발 중 | 사용자가 가구를 직접 끌어서 옮기고, 크기/회전을 조절하는 핵심 기능의 프로토타입이 구현되었습니다. 상태 관리는 Riverpod를 사용합니다. |
| **AI 자동 배치** | ❌ 미완료 | UI 버튼만 있으며, 실제 AI 자동 배치 API 연동 로직은 구현되지 않았습니다. |
| **결과 미리보기/공유** | 🟡 개발 중 | 최종 렌더링된 결과물은 샘플 이미지로 표시됩니다. `share_plus`를 이용한 공유 기능은 구현되었습니다. |
| **데이터 모델** | ✅ 완료 | `Room`, `Furniture`, `Scene` 등 Firestore와 연동될 데이터 모델이 정의되어 있습니다. |
| **상태 관리** | ✅ 완료 | `flutter_riverpod`를 사용하여 편집기의 `Scene` 상태를 관리하는 `SceneController`가 구현되어 있습니다. |
| **테스트** | ❌ 미완료 | Flutter 기본 위젯 테스트 외에 기능별 테스트 코드가 없습니다. |

## 🛠️ 기술 스택

- **Framework:** [Flutter](https://flutter.dev)
- **State Management:** [Flutter Riverpod](https://riverpod.dev/)
- **Routing:** [go_router](https://pub.dev/packages/go_router)
- **Backend & DB:** [Firebase Auth](https://firebase.google.com/products/auth), [Cloud Firestore](https://firebase.google.com/products/firestore)
- **Image:** [image_picker](https://pub.dev/packages/image_picker), [cached_network_image](https://pub.dev/packages/cached_network_image)
- **Sharing:** [share_plus](https://pub.dev/packages/share_plus)
- **HTTP Client:** [Dio](https://pub.dev/packages/dio) (API 연동 시 사용 예정)
- **Utilities:** [uuid](https://pub.dev/packages/uuid), [intl](https://pub.dev/packages/intl)

## 📂 프로젝트 구조

```
lib/
├── core/
│   └── models/         # 데이터 모델 (Room, Furniture, Scene 등)
├── features/
│   ├── auth/           # 사용자 인증
│   ├── catalog/        # 가구 카탈로그
│   ├── editor/         # 배치 편집기
│   ├── home/           # 홈 화면
│   ├── preview_share/  # 미리보기 및 공유
│   └── room_upload/    # 방 사진 업로드
├── state/
│   └── scene_providers.dart # Riverpod 상태 관리 (Provider, Controller)
├── app.dart            # MaterialApp 설정
├── main.dart           # 앱 시작점
├── router.dart         # GoRouter 경로 설정
└── theme.dart          # 앱 전체 테마
```

## 🚀 시작하기

### 1. 프로젝트 클론
```bash
git clone https://your-repository-url.git
cd roomstyler
```

### 2. Flutter 패키지 설치
```bash
flutter pub get
```

### 3. (TODO) Firebase 설정
현재는 Firebase 연동이 완료되지 않았습니다. 향후 `firebase_options.dart` 파일을 설정해야 합니다.

### 4. 앱 실행
```bash
flutter run
```

## 📝 향후 과제 (TODO)

- [ ] Firebase Auth 연동하여 실제 로그인 기능 구현
- [ ] Cloud Firestore 연동하여 가구/프로젝트 데이터 관리
- [ ] AI 서버 API 연동 (기존 가구 제거, 자동 배치, 최종 렌더링)
- [ ] 편집기 기능 고도화 (가구 상세 조작, 스타일 변경 등)
- [ ] 각 기능에 대한 위젯/단위 테스트 코드 작성