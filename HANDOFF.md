# HANDOFF — 여행 경로 기록 앱

> 설계 원본: `docs/DESIGN.md`. 이 파일은 "지금 무엇이 어떻게 만들어져 있나"를 담는다.

## 목표

일본 여행(출국 2026-12-04)용 iPhone 앱. 세 가지를 한 앱에서:
1. **기록** — 이동 경로 자동 기록, 지도에서 경로·사진 다시 보기
2. **계획(타임라인)** — 날짜·시간별 여행 일정 작성/편집
3. **투두** — 여행 준비 체크리스트

화면은 **TabView(지도 / 타임라인 / 투두)**. 설정은 지도 좌상단 버튼으로 진입.

## 기술 스택

- Swift + SwiftUI, iOS 17+
- CoreLocation(위치), MapKit(지도), SwiftData(기기 내 저장), UIImagePickerController(카메라)
- 테스트: XCTest (iOS 시뮬레이터)
- 프로젝트 생성: **XcodeGen** (`project.yml` → `TravelTracker.xcodeproj`)

## 프로젝트 구조

```
project.yml                 XcodeGen 스펙 (프로젝트의 소스 오브 트루스)
App/
 ├ TravelTrackerApp.swift    @main, SwiftData ModelContainer 구성
 ├ Core/
 │   └ Geo.swift             Haversine 거리 (CoreLocation 비의존, 순수 함수)
 ├ Models/
 │   ├ LocationSample.swift  위치 1회 측정값 (순수 value type)
 │   ├ Trip.swift            @Model (집 시작점 필드 포함)
 │   ├ TrackPoint.swift      @Model
 │   ├ Photo.swift           @Model (촬영 사진)
 │   ├ Profile.swift         @Model (프로필, 추후)
 │   ├ PlanItem.swift        @Model (타임라인 일정)
 │   ├ TodoItem.swift        @Model (투두) + TodoItem+Ordering.swift
 ├ Logic/
 │   ├ GeoTimed.swift          위경도+시각 공통 프로토콜(LocationSample/TrackPoint)
 │   ├ TrackPointFilter.swift  정확도/최소거리 필터 (순수)
 │   ├ SegmentSplitter.swift   시간 간격으로 segment 분리 (순수, 제네릭)
 │   ├ TripStats.swift         거리·시간 통계 (순수)
 │   ├ DayGrouping.swift       GeoTimed 날짜별 그룹핑 (순수)
 │   ├ CalendarGrouping.swift  범용 날짜 그룹핑(클로저) — PlanItem용 (순수)
 │   ├ TodoOrdering.swift      투두 정렬 규칙 (순수)
 │   ├ RoutePlayback.swift     재생 보간·부분 폴리라인 (순수)
 │   ├ RegionCalculator.swift  지도 표시 영역 계산 (순수, MapKit 비의존)
 │   └ TripExporter.swift      GPX/KML 생성 + 임시파일 쓰기 (순수)
 ├ Services/
 │   ├ LocationService.swift   LocationServing 프로토콜 + CLLocationService(실제)
 │   ├ ImageProcessing.swift   200px 썸네일 생성 (순수)
 │   └ PhotoService.swift      원본+썸네일 Documents 저장
 ├ Repositories/
 │   ├ TrackRepository.swift   프로토콜 + SwiftDataTrackRepository
 │   ├ PhotoRepository.swift   프로토콜 + SwiftDataPhotoRepository
 │   ├ PlanRepository.swift    프로토콜 + SwiftDataPlanRepository
 │   └ TodoRepository.swift    프로토콜 + SwiftDataTodoRepository
 ├ ViewModels/
 │   ├ TrackRecorder.swift     샘플 수신→필터→저장 오케스트레이터
 │   ├ MapViewModel.swift      여행 로드→날짜 조회→재생→사진
 │   ├ TimelineViewModel.swift 계획 항목 CRUD, 날짜별 그룹핑
 │   └ TodoViewModel.swift     투두 CRUD, 정렬
 └ Views/
     ├ RootTabView.swift       탭 루트(지도/타임라인/투두). START_TAB 환경변수로 초기 탭 지정(테스트용)
     ├ ContentView.swift       지도 탭 루트 + 권한 요청 배너
     ├ MapScreen.swift         다크 지도/경로/마커/날짜/재생/사진 썸네일/카메라
     ├ CameraPicker.swift      UIImagePickerController 래퍼(시뮬레이터는 보관함 대체)
     ├ PhotoDetailView.swift   원본 + 촬영 시각
     ├ TimelineView.swift      계획 목록(날짜별) + 추가/편집/삭제/완료
     ├ PlanItemEditView.swift  일정 추가·편집 폼
     ├ TodoView.swift          투두 목록 + 입력바
     ├ ShareSheet.swift        UIActivityViewController 래퍼(파일 공유)
     └ SettingsView.swift      프로필·설정 골격
Tests/
 ├ GeoTests.swift
 ├ TrackPointFilterTests.swift
 ├ SegmentSplitterTests.swift
 ├ StatsCalculatorTests.swift
 ├ DayGroupingTests.swift
 ├ RoutePlaybackTests.swift
 ├ RegionCalculatorTests.swift
 ├ TrackRepositoryTests.swift   (in-memory SwiftData)
 ├ TrackRecorderTests.swift     (MockLocationService 주입)
 └ MockLocationService.swift
```

## 핵심 설계 원칙

- **순수 로직 분리**: 거리 계산·필터·segment 분리는 CoreLocation/SwiftData에 의존하지 않는 순수 코드로 두어 GPS 없이 빠르게 단위 테스트한다.
- **`LocationServing` 프로토콜 + 주입**: 실제 GPS(`CLLocationService`) 대신 `MockLocationService`를 주입해 기록 파이프라인 전체를 테스트한다.
- 위치 측정값은 `LocationSample`(순수 struct)로 흐르고, 저장 시점에만 `TrackPoint`(@Model)로 변환한다.

## 빌드 / 테스트 방법

```bash
# 프로젝트(.xcodeproj) 생성 — project.yml 수정 시마다 실행
xcodegen generate

# 빌드
xcodebuild build -scheme TravelTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17'

# 테스트
xcodebuild test -scheme TravelTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

새 파일을 추가하면 `xcodegen generate`를 다시 돌려야 프로젝트에 반영된다.

## 진행 단계 (docs/DESIGN.md §8)

1. ~~프로젝트 골격 + 위치 기록 + 저장 + 테스트~~ ✅
2. ~~지도 경로 표시 + 날짜별 조회 + 경로 재생~~ ✅
3. ~~카메라 + 썸네일 annotation~~ ✅
3.5. ~~타임라인(여행 계획) + 투두 (탭 구조)~~ ✅  (사용자 추가 요청)
4. ~~GPX/KML 내보내기~~ ✅  ← 현재까지 완료. 집 좌표 확정(37.332388, 127.112209)
5. 실기기 필드 테스트 (출국 2026-12-04 전)

후속 후보: 계획 방문 경로 그리기(타임라인 좌표 → 지도에 계획 경로), 투두 마감일 입력 UI,
설정에서 집 위치 지도 핀으로 수정

빌드/테스트 명령은 위 "빌드 / 테스트 방법"과 동일.
헤드리스 캡처: `SIMCTL_CHILD_START_TAB=timeline|todo xcrun simctl launch ...`
