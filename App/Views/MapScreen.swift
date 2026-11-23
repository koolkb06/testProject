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

    var body: some View {
        Map(position: $camera) {
            if let start = vm.startCoordinate {
                Annotation("집", coordinate: start.cl) { startMarker }
            }

            // 계획 방문 경로: 각 일정 = 출발→도착 주황 점선 구간 + 도착지 번호 핀
            ForEach(vm.plannedRoute.legs, id: \.order) { leg in
                MapPolyline(coordinates: [leg.from.cl, leg.to.cl])
                    .stroke(.orange, style: StrokeStyle(lineWidth: 4, lineCap: .round, dash: [2, 9]))
            }
            ForEach(vm.plannedRoute.stops, id: \.order) { stop in
                Annotation(stop.title, coordinate: stop.coord.cl) {
                    PlanStopMarker(number: stop.order, done: stop.isDone)
                }
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
            if !vm.isPlaying { fitFullRoute() }
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
                Button {
                    vm.togglePlayback()
                } label: {
                    Label(vm.isPlaying ? "일시정지" : "경로 재생",
                          systemImage: vm.isPlaying ? "pause.fill" : "play.fill")
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                }
                .disabled(vm.dayPoints.count < 2)

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
