import SwiftUI
import MapKit

extension RoutePlayback.Coord {
    var cl: CLLocationCoordinate2D { .init(latitude: latitude, longitude: longitude) }
}

extension RegionBox {
    var mkRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: .init(latitude: centerLatitude, longitude: centerLongitude),
            span: .init(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        )
    }
}

/// 메인 지도 화면. 다크 톤, 파란 경로, 출발(집) 마커, 프로필 마커, 날짜 조회, 경로 재생. (설계 §3)
struct MapScreen: View {
    @EnvironmentObject private var vm: MapViewModel
    @EnvironmentObject private var recorder: TrackRecorder

    @State private var camera: MapCameraPosition = .automatic
    @State private var showCamera = false
    @State private var exportFile: ExportFile?
    @State private var showLocationSettingsAlert = false

    var body: some View {
        Map(position: $camera) {
            // 실시간 현재 위치(파란 점). 기록 중이 아니어도 표시된다.
            UserAnnotation()

            if let start = vm.startCoordinate {
                Annotation("집", coordinate: start.cl) { startMarker }
            }

            // 계획 방문 경로: 모드별 실제 경로(있으면 실선) 또는 직선 점선 대체 + 도착지 번호 핀
            ForEach(vm.plannedRoute.legs, id: \.order) { leg in
                let road = vm.legGeometry[leg.order]
                let hasRoad = (road?.count ?? 0) > 1
                let coords = hasRoad ? road!.map(\.cl) : [leg.from.cl, leg.to.cl]
                // 실제 경로 실선, 대체/비행기는 점선
                MapPolyline(coordinates: coords)
                    .stroke(.orange, style: (hasRoad && leg.transport != .flight)
                            ? StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round)
                            : StrokeStyle(lineWidth: 4, lineCap: .round, dash: [2, 9]))
            }
            ForEach(vm.plannedRoute.stops, id: \.order) { stop in
                Annotation(stop.title, coordinate: stop.coord.cl) {
                    PlanStopMarker(number: stop.order, done: stop.isDone)
                }
            }

            // 계획 경로 재생 중: 경로를 따라가는 네비 마커
            if vm.isPlayingPlanned, let head = vm.plannedHead {
                Annotation("", coordinate: head.cl) { navMarker }
            }

            if vm.drawnCoordinates.count > 1 {
                MapPolyline(coordinates: vm.drawnCoordinates.map(\.cl))
                    .stroke(.blue, style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
            }

            ForEach(vm.dayPhotos) { photo in
                Annotation("", coordinate: CLLocationCoordinate2D(
                    latitude: photo.latitude, longitude: photo.longitude)
                ) {
                    PhotoThumbnailMarker(image: vm.image(atRelativePath: photo.thumbPath))
                        .onTapGesture { vm.selectedPhoto = photo }
                }
            }

            if let head = vm.headCoordinate {
                Annotation("", coordinate: head.cl) { profileMarker }
            }
        }
        .mapStyle(.standard(emphasis: .muted, pointsOfInterest: .excludingAll))
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .overlay(alignment: .top) { topBar }
        .overlay(alignment: .bottom) { bottomBar }
        .onAppear {
            vm.reload()
            fitFullRoute()
        }
        .onChange(of: recorder.pointCount) { _, _ in
            vm.reload()
            // "내 위치"로 따라가는 중이면 화면을 전체 경로로 되돌리지 않는다.
            if !vm.isPlaying && !camera.followsUserLocation { fitFullRoute() }
        }
        .onChange(of: vm.selectedDay) { _, _ in fitFullRoute() }
        .onChange(of: vm.playbackProgress) { _, _ in
            if vm.isPlaying, let head = vm.headCoordinate {
                withAnimation(.linear(duration: 1.0 / 60.0)) {
                    camera = .region(MKCoordinateRegion(
                        center: head.cl,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            }
        }
        .onChange(of: vm.plannedProgress) { _, progress in
            if vm.isPlayingPlanned, let head = vm.plannedHead {
                withAnimation(.linear(duration: 1.0 / 60.0)) {
                    camera = .region(MKCoordinateRegion(
                        center: head.cl,
                        span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
                    ))
                }
            }
            if progress >= 1 { fitFullRoute() }   // 재생 완료 시에만 전체 경로로 줌아웃
        }
        .onChange(of: vm.isPlaying) { _, playing in
            if !playing { fitFullRoute() }   // 재생 끝나면 전체 경로로 줌아웃
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { image in
                vm.capturePhoto(
                    image: image,
                    latitude: recorder.lastSample?.latitude,
                    longitude: recorder.lastSample?.longitude
                )
            }
            .ignoresSafeArea()
        }
        .sheet(item: $vm.selectedPhoto) { photo in
            PhotoDetailView(photo: photo, image: vm.image(atRelativePath: photo.filePath))
        }
        .sheet(item: $exportFile) { file in
            ShareSheet(items: [file.url])
        }
        .alert("사진", isPresented: Binding(
            get: { vm.captureError != nil },
            set: { if !$0 { vm.captureError = nil } }
        )) {
            Button("확인", role: .cancel) { vm.captureError = nil }
        } message: {
            Text(vm.captureError ?? "")
        }
        .alert("위치 권한 필요", isPresented: $showLocationSettingsAlert) {
            Button("설정 열기") { openAppSettings() }
            Button("취소", role: .cancel) {}
        } message: {
            Text("현재 위치를 보려면 설정 앱에서 위치 접근을 허용해 주세요.")
        }
    }

    // MARK: - 내 위치

    private var myLocationButton: some View {
        Button(action: goToMyLocation) {
            Image(systemName: camera.followsUserLocation ? "location.fill" : "location")
                .font(.title3)
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
        }
        .accessibilityLabel("내 위치")
    }

    private func goToMyLocation() {
        switch MyLocation.action(for: recorder.authorizationStatus) {
        case .follow:
            vm.stopAllPlayback()
            // GPS 수신 전이면 마지막 기록 위치 → 집 순서로 대신 보여준다.
            let fallback = MyLocation.fallbackRegion(lastSample: recorder.lastSample, home: .current)
            let fallbackPosition: MapCameraPosition = fallback.map { .region($0.mkRegion) } ?? .automatic
            Log.map.info("내 위치로 이동 (대체 영역 \(fallback == nil ? "없음" : "있음", privacy: .public))")
            withAnimation(.easeInOut) {
                camera = .userLocation(followsHeading: false, fallback: fallbackPosition)
            }
        case .requestPermission:
            Log.map.info("내 위치: 권한 미결정 → 권한 요청")
            recorder.requestAuthorization()
        case .openSettings:
            Log.map.notice("내 위치: 권한 거부/제한 → 설정 안내")
            showLocationSettingsAlert = true
        }
    }

    private func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            Log.map.error("설정 앱 URL 생성 실패")
            return
        }
        UIApplication.shared.open(url)
    }

    // MARK: - 마커

    private var startMarker: some View {
        Rectangle()
            .fill(.white)
            .frame(width: 16, height: 16)
            .overlay(Rectangle().stroke(.black, lineWidth: 2))
            .shadow(radius: 2)
    }

    private var profileMarker: some View {
        Circle()
            .fill(.blue)
            .frame(width: 28, height: 28)
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .overlay(Image(systemName: "person.fill").font(.system(size: 13)).foregroundStyle(.white))
            .shadow(radius: 3)
    }

    /// 계획 경로를 따라가는 네비 마커.
    private var navMarker: some View {
        Circle()
            .fill(.orange)
            .frame(width: 26, height: 26)
            .overlay(Circle().stroke(.white, lineWidth: 3))
            .overlay(Image(systemName: "location.north.fill").font(.system(size: 12)).foregroundStyle(.white))
            .shadow(radius: 3)
    }

    // MARK: - 상단 바 (좌: 설정, 우: 날짜)

    private var topBar: some View {
        HStack {
            NavigationLink { SettingsView() } label: {
                Image(systemName: "person.crop.circle")
                    .font(.title2)
                    .padding(10)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Spacer()
            if !vm.availableDays.isEmpty { dayMenu }
            exportMenu
            myLocationButton
        }
        .padding()
    }

    private var exportMenu: some View {
        Menu {
            Button { export(.gpx) } label: { Label("GPX 내보내기", systemImage: "point.topleft.down.curvedto.point.bottomright.up") }
            Button { export(.kml) } label: { Label("KML 내보내기", systemImage: "globe") }
        } label: {
            Image(systemName: "square.and.arrow.up")
                .font(.title3)
                .padding(10)
                .background(.ultraThinMaterial, in: Circle())
        }
    }

    private func export(_ format: ExportFormat) {
        if let url = vm.exportURL(format: format) {
            exportFile = ExportFile(url: url)
        }
    }

    private var dayMenu: some View {
        Menu {
            ForEach(vm.availableDays, id: \.self) { day in
                Button(Self.dayFormatter.string(from: day)) { vm.selectedDay = day }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                Text(vm.selectedDay.map(Self.dayFormatter.string(from:)) ?? "날짜")
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
        }
    }

    // MARK: - 하단 바 (정보 pill + 재생/기록)

    private var bottomBar: some View {
        VStack(spacing: 12) {
            infoPill
            HStack(spacing: 16) {
                if vm.canPlayPlanned {
                    Button {
                        vm.togglePlannedPlayback()
                    } label: {
                        Label(vm.isPlayingPlanned ? "일시정지" : "계획 따라가기",
                              systemImage: vm.isPlayingPlanned ? "pause.fill" : "location.north.line.fill")
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(.orange, in: Capsule())
                            .foregroundStyle(.white)
                    }
                } else {
                    Button {
                        vm.togglePlayback()
                    } label: {
                        Label(vm.isPlaying ? "일시정지" : "경로 재생",
                              systemImage: vm.isPlaying ? "pause.fill" : "play.fill")
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(.ultraThinMaterial, in: Capsule())
                    }
                    .disabled(vm.dayPoints.count < 2)
                }

                Button {
                    showCamera = true
                } label: {
                    Image(systemName: "camera.fill")
                        .padding(12)
                        .background(.ultraThinMaterial, in: Circle())
                }

                Button {
                    recorder.isRecording ? recorder.stop() : recorder.start()
                } label: {
                    Label(recorder.isRecording ? "기록 정지" : "기록 시작",
                          systemImage: recorder.isRecording ? "stop.fill" : "record.circle")
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(recorder.isRecording ? Color.red : Color.blue,
                                    in: Capsule())
                        .foregroundStyle(.white)
                }
            }
        }
        .padding()
    }

    private var infoPill: some View {
        HStack(spacing: 16) {
            label("지역", vm.regionName ?? "–")
            Divider().frame(height: 20)
            label("거리", Self.distanceText(vm.stats.distanceMeters))
            Divider().frame(height: 20)
            label("시간", Self.durationText(vm.stats.duration))
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(.ultraThinMaterial, in: Capsule())
    }

    private func label(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.subheadline).fontWeight(.semibold)
        }
    }

    private func fitFullRoute() {
        guard let region = vm.fullRegion else { return }
        withAnimation(.easeInOut) { camera = .region(region.mkRegion) }
    }

    // MARK: - 포맷터

    static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "M월 d일 (E)"
        return f
    }()

    static func distanceText(_ meters: Double) -> String {
        meters >= 1000
            ? String(format: "%.1fkm", meters / 1000)
            : String(format: "%.0fm", meters)
    }

    static func durationText(_ seconds: TimeInterval) -> String {
        let total = Int(seconds)
        let h = total / 3600, m = (total % 3600) / 60
        return h > 0 ? "\(h)시간 \(m)분" : "\(m)분"
    }
}

/// 계획 방문 지점 마커(주황 번호 핀). 실제 기록 마커와 구분.
struct PlanStopMarker: View {
    let number: Int
    let done: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(done ? Color.green : Color.orange)
                .frame(width: 26, height: 26)
                .overlay(Circle().stroke(.white, lineWidth: 2))
            if done {
                Image(systemName: "checkmark").font(.caption2.bold()).foregroundStyle(.white)
            } else {
                Text("\(number)").font(.caption2.bold()).foregroundStyle(.white)
            }
        }
        .shadow(radius: 2)
    }
}

/// 지도 위 둥근 모서리 썸네일 마커. (설계 §3)
struct PhotoThumbnailMarker: View {
    let image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(.white, lineWidth: 2))
        .shadow(radius: 3)
    }
}
