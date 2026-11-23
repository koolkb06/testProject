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

    func add(_ draft: PlanDraft) {
        guard !draft.title.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        do {
            let trip = try ensureTrip()
            let item = PlanItem(
                title: draft.title, plannedAt: draft.plannedAt,
                placeName: draft.placeName,
                latitude: draft.latitude, longitude: draft.longitude,
                memo: draft.memo
            )
            try planRepository.add(item, to: trip)
            reload()
            Log.plan.info("계획 추가 '\(item.title, privacy: .public)' 좌표=\(draft.latitude != nil ? "있음" : "없음", privacy: .public)")
        } catch {
            Log.plan.error("계획 추가 실패: \(error.localizedDescription, privacy: .public)")
        }
    }

    func update(_ item: PlanItem, draft: PlanDraft) {
        item.title = draft.title
        item.plannedAt = draft.plannedAt
        item.placeName = draft.placeName
        item.memo = draft.memo
        item.latitude = draft.latitude
        item.longitude = draft.longitude
        try? planRepository.save()
        reload()
        Log.plan.info("계획 편집 '\(item.title, privacy: .public)'")
    }

    func toggleDone(_ item: PlanItem) {
        item.isDone.toggle()
        try? planRepository.save()
        reload()
        Log.plan.debug("계획 완료 토글 '\(item.title, privacy: .public)' → \(item.isDone, privacy: .public)")
    }

    func delete(_ item: PlanItem) {
        Log.plan.info("계획 삭제 '\(item.title, privacy: .public)'")
        try? planRepository.delete(item)
        reload()
    }

    /// 계획을 붙일 여행이 없으면 하나 만든다(기록 시작 전에도 계획 가능).
    private func ensureTrip() throws -> Trip {
        if let trip = try tripRepository.latestTrip() { return trip }
        return try tripRepository.startTrip(name: "일본 여행", startDate: Date(), home: .current)
    }
}
