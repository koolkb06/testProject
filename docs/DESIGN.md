# 여행 경로 기록 앱 설계

일본 여행(출국 2026-12-04) 중 이동 경로를 계속 기록하고, 나중에 지도에서 경로와 촬영 사진을 다시 보는 iPhone 앱.

## 1. 기술 스택

| 영역 | 선택 |
|---|---|
| 언어/UI | Swift + SwiftUI (iOS 17+) |
| 위치 | CoreLocation |
| 지도 | MapKit |
| 저장 | SwiftData (기기 내부, 서버 없음) |
| 카메라 | UIImagePickerController |
| 테스트 | XCTest |

## 2. 위치 기록

- 권한: "항상 허용" + Background Mode(location)
- 20~30m 이동마다 1점 저장
- 앱이 종료되면 Significant Location Change로 iOS가 앱을 다시 깨움
- 정확도가 나쁜 점(오차 100m 초과)은 버림
- 점 사이 시간 간격이 크면(지하철 등) segment를 분리해서 선을 끊어 그림
- 정지 상태에서는 자동 일시정지로 배터리 절약

## 3. 지도 화면

- 다크 톤 지도, POI 아이콘 숨김
  (`MapStyle.standard(emphasis: .muted, pointsOfInterest: .excludingAll)` + 다크 모드 고정)
- 이동 경로: 파란색 `MapPolyline`, 굵은 선 + 둥근 끝 처리
- 현재 위치: 원형 프로필 사진 + 정보 pill(현재 지역명, 오늘 이동 거리·시간)
- 출발 지점: 흰색 네모 마커
- 좌상단: 프로필/설정 진입 버튼
- 사진: 촬영 지점에 둥근 모서리 썸네일, 축소 시 clustering

### 애니메이션

- 경로 재생: 날짜 선택 시 선이 출발점부터 그려지고 프로필 마커가 따라 이동
- 사진 지점을 지날 때 썸네일 pop
- 실시간 위치 갱신 시 마커가 부드럽게 이동
- 재생 중 카메라가 마커를 따라가고, 끝나면 전체 경로로 줌아웃

## 4. 카메라

- 촬영 시점의 최신 위치를 사진에 붙여 저장
- 원본은 앱 Documents, 200px 썸네일 별도 생성
- 썸네일 탭 시 원본과 촬영 시각 표시
- (2차) 기본 카메라 앱 사진을 EXIF GPS로 가져오기

## 5. 외부 지도에서 보기

- GPX/KML 내보내기 → Google My Maps, Google Earth 등에서 import

## 6. 데이터 모델

```
Trip        id, name, startDate, endDate
TrackPoint  id, tripId, lat, lon, altitude, accuracy, speed, timestamp
Photo       id, tripId, filePath, thumbPath, lat, lon, takenAt
Profile     imagePath, displayName
```

## 7. 구조 (MVVM)

```
App/
 ├ Views/        MapView, TimelineView, CameraView, SettingsView
 ├ ViewModels/
 ├ Services/     LocationService, PhotoService, ExportService
 ├ Repositories/ TrackRepository, PhotoRepository
 └ Models/
Tests/           필터 로직, segment 분리, GPX/KML 생성, Repository
```

`LocationService`는 protocol로 분리하고 Mock을 주입해 GPS 없이 unit test한다.

## 8. 단계

1. 프로젝트 골격 + 위치 기록 + 저장 + 테스트
2. 지도에 경로 표시 + 날짜별 조회 + 경로 재생
3. 카메라 + 썸네일 annotation
4. GPX/KML 내보내기
5. 실기기 필드 테스트 (출국 전 하루 이상)

## 9. 미결 사항

- Apple Developer Program 가입 여부. 무료 계정은 설치 후 7일 뒤 앱이 만료되고,
  재설치에는 Mac이 필요하다.
