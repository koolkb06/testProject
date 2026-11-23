# PROGRESS — 여행 경로 기록 앱

## 1단계: 프로젝트 골격 + 위치 기록 + 저장 + 테스트  ← 완료 (2026-11-23)

### 완료
- XcodeGen 프로젝트 골격 (`project.yml` → `TravelTracker.xcodeproj`), Info.plist 권한/백그라운드 모드
- SwiftData 모델: Trip, TrackPoint, Photo, Profile (Trip에 집 시작점 필드 포함)
- 순수 로직: Geo(Haversine), TrackPointFilter(정확도/최소거리), SegmentSplitter(시간 간격)
- LocationServing 프로토콜 + CLLocationService(실제 GPS) + MockLocationService(테스트)
- SwiftDataTrackRepository (in-memory 테스트 가능), TrackRecorder 오케스트레이터
- 최소 UI: ContentView(권한/상태/점 개수/시작·정지)
- **테스트 23개 전부 통과**, iPhone 17 시뮬레이터 빌드 성공

### 현재 막힌 문제 / 미결
- **집(탄천상로 6) 정확한 좌표 미확정**: 주소만 저장 중. 실기기에서 `CLGeocoder`로 변환하거나 사용자 확인 필요. 좌표 확정 전까지는 시작점 마커를 좌표로 찍지 못함(첫 GPS fix가 사실상 집 근처).

## 2단계: 지도 경로 표시 + 날짜별 조회 + 경로 재생  ← 완료 (2026-11-23)

### 완료
- 순수 로직: `GeoTimed`(LocationSample/TrackPoint 공통 프로토콜), `StatsCalculator`(거리·시간),
  `DayGrouping`(날짜별), `RoutePlayback`(재생 보간·부분 그리기), `RegionCalculator`(지도 영역)
- `MapViewModel`: 최신 여행 로드 → 날짜별 조회 → 재생(진행도 애니메이션, 지역명 역지오코딩)
- `MapScreen`: 다크 톤 muted 지도 + POI 숨김, 파란 MapPolyline(굵게·둥근 끝), 집=흰 네모 마커,
  프로필(원형) 마커, 날짜 메뉴, 정보 pill(지역/거리/시간), 재생·기록 버튼, 좌상단 설정 진입
- `SettingsView` 골격, `ContentView`를 지도 루트로 재구성
- 테스트 **35개 전부 통과**, iPhone 17 시뮬레이터에서 실제 실행·렌더링 확인(크래시 없음)

### 미결 / 다음 단계로
- 집(탄천상로 6) 좌표 여전히 미확정 → 좌표 알면 흰 네모 시작 마커가 집에 고정됨(현재는 그날 첫 점)
- 경로 재생 실데이터 검증은 3단계 이후 실기기/모의 이동으로

## 3단계: 카메라 + 썸네일 annotation  ← 완료 (2026-11-23)

### 완료
- `ImageProcessing`(200px 썸네일, 순수), `PhotoService`(원본+썸네일 Documents 저장)
- `PhotoRepository`(SwiftData), `CameraPicker`(UIImagePickerController, 시뮬레이터는 보관함 대체)
- `MapScreen`에 촬영 버튼 + 둥근 썸네일 annotation + 탭 시 원본·시각 상세(`PhotoDetailView`)
- `MapViewModel`에 사진 저장/로드/일자 필터 추가
- 테스트: ImageProcessing/PhotoService/PhotoRepository 추가, UI 실행 확인(카메라 버튼)

## 3.5단계: 타임라인(여행 계획) + 투두  ← 완료 (2026-11-23, 사용자 추가 요청)

### 완료
- 모델 `PlanItem`, `TodoItem` 추가 + ModelContainer 등록
- 순수 로직 `CalendarGrouping`(범용 날짜 그룹핑), `TodoOrdering`(미완료 우선 정렬)
- `PlanRepository`/`TodoRepository`(SwiftData), `TimelineViewModel`/`TodoViewModel`
- `RootTabView`(지도/타임라인/투두 탭), `TimelineView`+`PlanItemEditView`, `TodoView`
- 테스트 **51개 전부 통과**, 세 탭 모두 시뮬레이터 렌더링 확인

### 미결
- PlanItem 좌표를 지도에 계획 핀으로 표시(후속 아이디어)
- 투두에 마감일 입력 UI(현재 모델엔 있으나 입력폼 미노출)

## 4단계: GPX/KML 내보내기  ← 완료 (2026-11-24)

### 완료
- 집(탄천상로 6) 좌표 **37.332388, 127.112209** 확정(Apple 지오코딩) → 시작 마커가 집에 고정
- `TripExporter`(순수 GPX/KML 생성 + 임시파일 쓰기), `ExportFormat`, `Waypoint`
- `MapViewModel.exportURL(format:)`: 여행 전체 경로를 segment로 끊어 생성 + 사진을 waypoint로
- 지도 우상단 **공유 버튼** → GPX/KML 메뉴 → `ShareSheet`(UIActivityViewController)
- 테스트 **59개 전부 통과**(GPX/KML 구조·좌표순서·XML이스케이프·파일쓰기 + VM 내보내기 E2E)

## 다음 단계 (미착수)
- (후속 요청) **계획 방문 경로 그리기**: 타임라인에서 좌표가 있는 일정들을 가는 순서대로
  지도에 "계획 경로"(실제 기록과 다른 스타일, 예: 주황 점선)로 표시. 직선 연결 또는 MKDirections.
  → PlanItem에 위치 선택 UI 추가 필요. 미착수.
- 4단계: GPX/KML 내보내기
- 5단계: 실기기 필드 테스트 (출국 2026-12-04 전)
