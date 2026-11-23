import SwiftUI
import MapKit

/// 지도에서 위치를 고르는 화면. 지도를 움직여 중앙 핀을 원하는 곳에 맞추고 "선택".
struct LocationPickerView: View {
    let initial: CLLocationCoordinate2D?
    let onPick: (CLLocationCoordinate2D) -> Void

    @Environment(\.dismiss) private var dismiss
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

                // 중앙 고정 핀
                Image(systemName: "mappin")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                    .offset(y: -14)
                    .allowsHitTesting(false)

                VStack {
                    Spacer()
                    Text(String(format: "%.5f, %.5f", center.latitude, center.longitude))
                        .font(.caption.monospaced())
                        .padding(8)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 12)
                }
            }
            .navigationTitle("위치 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("선택") { onPick(center); dismiss() }
                }
            }
        }
    }
}
