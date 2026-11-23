import Foundation
import SwiftData

/// 여행/경로 점 저장소. SwiftData를 감춰 테스트에서 in-memory 컨테이너로 대체 가능.
protocol TrackRepository {
    /// 진행 중(종료되지 않은) 여행 중 가장 최근 것. 없으면 nil.
    func activeTrip() throws -> Trip?
    /// 종료 여부와 무관하게 가장 최근 시작된 여행. 지도 표시용.
    func latestTrip() throws -> Trip?
    /// 새 여행 시작. 시작점(집) 정보를 기록하고, 좌표를 알면 첫 점으로 seed.
    @discardableResult
    func startTrip(name: String, startDate: Date, home: HomeLocation) throws -> Trip
    /// 샘플 1개를 경로 점으로 저장.
    func append(_ sample: LocationSample, to trip: Trip) throws
    /// 여행의 점들을 시간순으로.
    func points(for trip: Trip) throws -> [TrackPoint]
    /// 여행 종료.
    func endTrip(_ trip: Trip, endDate: Date) throws
}

final class SwiftDataTrackRepository: TrackRepository {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func activeTrip() throws -> Trip? {
        var descriptor = FetchDescriptor<Trip>(
            predicate: #Predicate { $0.endDate == nil },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    func latestTrip() throws -> Trip? {
        var descriptor = FetchDescriptor<Trip>(
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    @discardableResult
    func startTrip(name: String, startDate: Date, home: HomeLocation) throws -> Trip {
        let trip = Trip(
            name: name,
            startDate: startDate,
            startAddress: home.address,
            startLatitude: home.latitude,
            startLongitude: home.longitude
        )
        context.insert(trip)

        // 집 좌표를 알면 경로가 집에서 시작하도록 첫 점을 seed.
        if let lat = home.latitude, let lon = home.longitude {
            let seed = TrackPoint(
                latitude: lat,
                longitude: lon,
                altitude: 0,
                horizontalAccuracy: 0,
                speed: -1,
                timestamp: startDate,
                trip: trip
            )
            context.insert(seed)
            Log.repo.info("여행 생성 + 집 시작점 seed (\(lat, privacy: .public),\(lon, privacy: .public))")
        } else {
            Log.repo.info("여행 생성(집 좌표 없음, seed 생략)")
        }

        try context.save()
        return trip
    }

    func append(_ sample: LocationSample, to trip: Trip) throws {
        let point = TrackPoint(sample: sample, trip: trip)
        context.insert(point)
        try context.save()
    }

    func points(for trip: Trip) throws -> [TrackPoint] {
        let tripID = trip.id
        let descriptor = FetchDescriptor<TrackPoint>(
            predicate: #Predicate { $0.trip?.id == tripID },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    func endTrip(_ trip: Trip, endDate: Date) throws {
        trip.endDate = endDate
        try context.save()
    }
}
