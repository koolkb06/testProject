import Foundation

/// 여행 계획(타임라인) 화면 상태. 최신 여행의 계획 항목을 날짜별로 묶어 관리.
@MainActor
final class TimelineViewModel: ObservableObject {
    @Published private(set) var buckets: [DayBucket<PlanItem>] = []

    private let tripRepository: TrackRepository
    private let planRepository: PlanRepository
    private let calendar: Calendar

    init(
        tripRepository: TrackRepository,
        planRepository: PlanRepository,
        calendar: Calendar = .current
    ) {
        self.tripRepository = tripRepository
        self.planRepository = planRepository
        self.calendar = calendar
    }

    func reload() {
        guard let trip = try? tripRepository.latestTrip() else {
            buckets = []
            return
        }
        let items = (try? planRepository.items(for: trip)) ?? []
        buckets = CalendarGrouping.byDay(items, calendar: calendar) { $0.plannedAt }
    }

    func add(title: String, plannedAt: Date, placeName: String?, memo: String) {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            let trip = try ensureTrip()
            let item = PlanItem(
                title: title, plannedAt: plannedAt,
                placeName: placeName?.isEmpty == true ? nil : placeName,
                memo: memo
            )
            try planRepository.add(item, to: trip)
            reload()
        } catch {
            print("TimelineViewModel.add 실패: \(error)")
        }
    }

    func update(_ item: PlanItem, title: String, plannedAt: Date, placeName: String?, memo: String) {
        item.title = title
        item.plannedAt = plannedAt
        item.placeName = (placeName?.isEmpty == true) ? nil : placeName
        item.memo = memo
        try? planRepository.save()
        reload()
    }

    func toggleDone(_ item: PlanItem) {
        item.isDone.toggle()
        try? planRepository.save()
        reload()
    }

    func delete(_ item: PlanItem) {
        try? planRepository.delete(item)
        reload()
    }

    /// 계획을 붙일 여행이 없으면 하나 만든다(기록 시작 전에도 계획 가능).
    private func ensureTrip() throws -> Trip {
        if let trip = try tripRepository.latestTrip() { return trip }
        return try tripRepository.startTrip(name: "일본 여행", startDate: Date(), home: .default)
    }
}
