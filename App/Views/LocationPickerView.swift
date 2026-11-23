import SwiftUI
import MapKit

/// 지도에서 위치를 고르는 화면. 주소/장소 검색 또는 지도를 움직여 중앙 핀으로 지정. (사용자 요청)
struct LocationPickerView: View {
    let initial: CLLocationCoordinate2D?
    let onPick: (CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss
    @StateObject private var search = AddressSearch()
    @FocusState private var searchFocused: Bool
    @State private var camera: MapCameraPosition
    @State private var center: CLLocationCoordinate2D

    init(initial: CLLocationCoordinate2D?, onPick: @escaping (CLLocationCoordinate2D) -> Void) {
        self.initial = initial
        self.onPick = onPick
        let start = initial ?? CLLocationCoordinate2D(
            latitude: HomeLocation.current.latitude ?? 37.3324,
            longitude: HomeLocation.current.longitude ?? 127.1122
        )
        _center = State(initialValue: start)
        _camera = State(initialValue: .region(MKCoordinateRegion(
            center: start,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Map(position: $camera)
                    .onMapCameraChange(frequency: .continuous) { ctx in
                        center = ctx.region.center
                    }
                    .ignoresSafeArea(edges: .bottom)

                Image(systemName: "mappin")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                    .offset(y: -14)
                    .allowsHitTesting(false)

                VStack(spacing: 0) {
                    searchBar
                    if !search.results.isEmpty { resultsList }
                    Spacer()
                    coordinateLabel
                }
            }
            .navigationTitle("위치 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("취소") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("선택") { onPick(center); dismiss() }
                }
            }
            .onAppear { search.setRegion(center: center) }
        }
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("주소·장소 검색 (예: 도쿄역, 센소지)", text: $search.query)
                .textFieldStyle(.plain)
                .focused($searchFocused)
                .autocorrectionDisabled()
            if !search.query.isEmpty {
                Button { search.clear() } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(.thinMaterial, in: Capsule())
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var resultsList: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(search.results.indices, id: \.self) { i in
                    let r = search.results[i]
                    Button {
                        select(r)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(r.title).foregroundStyle(.primary)
                            if !r.subtitle.isEmpty {
                                Text(r.subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10).padding(.horizontal, 14)
                    }
                    Divider()
                }
            }
        }
        .frame(maxHeight: 260)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.top, 6)
    }

    private var coordinateLabel: some View {
        Text(String(format: "%.5f, %.5f", center.latitude, center.longitude))
            .font(.caption.monospaced())
            .padding(8)
            .background(.ultraThinMaterial, in: Capsule())
            .padding(.bottom, 12)
    }

    private func select(_ completion: MKLocalSearchCompletion) {
        searchFocused = false
        search.resolve(completion) { coord in
            guard let coord else { return }
            center = coord
            withAnimation {
                camera = .region(MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)))
            }
            search.clear()
        }
    }
}
