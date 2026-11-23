# HANDOFF — 여행 경로 기록 앱

> 설계 원본: `docs/DESIGN.md`. 이 파일은 "지금 무엇이 어떻게 만들어져 있나"를 담는다.

## 목표

일본 여행(출국 2026-12-04) 중 이동 경로를 자동 기록하고, 지도에서 경로·사진을 다시 보는 iPhone 앱.

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
 │   ├ Trip.swift            @Model
 │   ├ TrackPoint.swift      @Model
 │   ├ Photo.swift           @Model (2단계+ 사용, 스키마만 등록)
 │   └ Profile.swift         @Model (2단계+ 사용, 스키마만 등록)
 ├ Logic/
 │   ├ GeoTimed.swift          위경도+시각 공통 프로토콜(LocationSample/TrackPoint)
 │   ├ TrackPointFilter.swift  정확도/최소거리 필터 (순수)
 │   ├ SegmentSplitter.swift   시간 간격으로 segment 분리 (순수, 제네릭)
 │   ├ TripStats.swift         거리·시간 통계 (순수)
 │   ├ DayGrouping.swift       날짜별 그룹핑 (순수, calendar 주입)
 │   ├ RoutePlayback.swift     재생 보간·부분 폴리라인 (순수)
 │   └ RegionCalculator.swift  지도 표시 영역 계산 (순수, MapKit 비의존)
 ├ Services/
 │   └ LocationService.swift   LocationServing 프로토콜 + CLLocationService(실제)
 ├ Repositories/
 │   └ TrackRepository.swift   프로토콜 + SwiftDataTrackRepository
 ├ ViewModels/
 │   ├ TrackRecorder.swift     샘플 수신→필터→저장 오케스트레이터
 │   └ MapViewModel.swift      여행 로드→날짜 조회→경로 재생
 └ Views/
     ├ ContentView.swift       루트(지도) + 권한 요청 배너
     ├ MapScreen.swift         다크 지도/경로/마커/날짜/재생/정보 pill
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
2. ~~지도 경로 표시 + 날짜별 조회 + 경로 재생~~ ✅  ← 현재까지 완료
3. 카메라 + 썸네일 annotation
4. GPX/KML 내보내기
5. 실기기 필드 테스트
