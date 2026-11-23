import Foundation
import SwiftData

/// 여행 계획(타임라인) 저장소.
protocol PlanRepository {
    func add(_ item: PlanItem, to trip: Trip) throws
    func items(for trip: Trip) throws -> [PlanItem]
    func save() throws
    func delete(_ item: PlanItem) throws
}

final class SwiftDataPlanRepository: PlanRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func add(_ item: PlanItem, to trip: Trip) throws {
        item.trip = trip
        context.insert(item)
        try context.save()
    }

    func items(for trip: Trip) throws -> [PlanItem] {
        let tripID = trip.id
        let descriptor = FetchDescriptor<PlanItem>(
            predicate: #Predicate { $0.trip?.id == tripID },
            sortBy: [SortDescriptor(\.plannedAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    /// 기존 항목 편집 후 저장.
    func save() throws {
        try context.save()
    }

    func delete(_ item: PlanItem) throws {
        context.delete(item)
        try context.save()
    }
}
