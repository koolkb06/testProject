# DECISIONS — 여행 경로 기록 앱

날짜별로 "결정 / 이유 / 버린 대안"을 짧게 기록한다.

## 2026-11-23

### 프로젝트 생성에 XcodeGen 사용
- **결정**: `.xcodeproj`를 직접 손으로 만들지 않고 `project.yml` → `xcodegen generate`로 생성.
- **이유**: `.pbxproj`는 손으로 올바르게 작성/병합하기 매우 어렵다. YAML 스펙은 사람이 읽고 diff 하기 쉽고 CLI 빌드/테스트와 잘 맞는다.
- **버린 대안**: (a) Xcode GUI로 생성 — 이 환경은 CLI 중심이라 부적합. (b) Swift Package — SwiftUI/CoreLocation/MapKit의 iOS 전용 부분을 CLI에서 시뮬레이터로 빌드하기 번거로움.

### 순수 로직과 플랫폼 코드 분리
- **결정**: 거리 계산(Haversine), 필터, segment 분리를 CoreLocation/SwiftData 비의존 순수 코드로 분리. 위치는 `LocationServing` 프로토콜로 추상화하고 `MockLocationService` 주입.
- **이유**: GPS/시뮬레이터 없이 핵심 로직을 빠르고 결정적으로 단위 테스트 (설계 §7 요구).
- **버린 대안**: CoreLocation `CLLocation`을 파이프라인 전체에 그대로 흘리기 — 테스트에서 목킹이 번거롭고 로직이 프레임워크에 묶임.

### Swift 언어 모드 5.0
- **결정**: `SWIFT_VERSION = 5.0` (Swift 5 language mode)로 빌드.
- **이유**: 1단계에서 Swift 6 strict concurrency의 data-race 안전성 오류로 시간을 쓰지 않기 위함. 컴파일러는 6.4지만 언어 모드만 5.0.
- **버린 대안**: Swift 6 모드 — 추후 단계에서 점진 전환 가능.

### 위치 필터 파라미터 기본값
- **결정**: 최대 허용 정확도 100m(초과 시 버림), 최소 이동 거리 20m, segment 분리 시간 간격 180초(3분).
- **이유**: 설계 §2의 "오차 100m 초과 버림", "20~30m마다 1점", "시간 간격 크면 segment 분리"를 수치화. 20m/180s는 보수적 초기값이며 실기기 테스트(5단계)에서 조정.
- **버린 대안**: distanceFilter만으로 처리 — 정확도 필터와 segment 분리를 코드에서 못 함.

### (2단계) 순수 로직은 MapKit/SwiftData 비의존, 좌표는 값 타입으로 노출
- **결정**: `MapViewModel`과 재생/영역 로직은 MapKit에 의존하지 않고 `RoutePlayback.Coord`/`RegionBox` 같은 값으로 좌표를 노출. 뷰(`MapScreen`)에서만 `CLLocationCoordinate2D`/`MKCoordinateRegion`으로 변환.
- **이유**: GPS/지도 없이 보간·영역 로직을 단위 테스트(결정적). 공통 `GeoTimed` 프로토콜로 LocationSample·TrackPoint 양쪽에서 재사용.
- **버린 대안**: 뷰모델에서 MapKit 타입 직접 사용 — 테스트에서 시뮬레이터 의존·비결정적.

### (2단계) 경로 재생은 거리 기준 보간, 고정 길이(8초)
- **결정**: 진행도 0~1을 누적 거리 비율로 좌표에 매핑(`RoutePlayback`). 재생은 경로 길이와 무관하게 8초. 정지/로드 상태는 progress=1(전체 경로 표시).
- **이유**: 시간 기준 재생은 지하철 등 긴 공백에서 멈춰 보임. 거리 기준이 매끄럽다. 고정 길이로 긴 경로도 지루하지 않게.
- **버린 대안**: 실제 타임스탬프 비율 재생 — 공백 구간 체감 나쁨.

### 여행 시작점 = 집 (탄천상로 6)  *(사용자 요청, 턴 중 추가)*
- **결정**: `Trip`에 `startAddress`/`startLatitude`/`startLongitude`(옵셔널) 추가. 기본 집 주소를 `HomeLocation`("탄천상로 6")로 두고, 여행 시작 시 시작점으로 기록. 좌표를 알면 첫 `TrackPoint`로 seed 하여 경로가 집에서 시작.
- **이유**: 사용자가 "여행의 시작을 우리 집부터" 요청. 설계 §3의 "출발 지점: 흰색 네모 마커"와 연결.
- **좌표 처리**: 탄천상로 6의 정확한 위/경도는 임의로 지정하지 않는다. 실기기에서 `CLGeocoder`로 주소를 좌표로 변환하거나 사용자 확인 후 확정. → **미결**(PROGRESS 참조).
- **버린 대안**: 좌표를 추측해 하드코딩 — 틀린 시작점 마커 위험.
