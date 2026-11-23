import Foundation
import SwiftData

/// 개발/스크린샷용 샘플 데이터. 환경변수 SEED_SAMPLE=1일 때만, 비어 있을 때 1회 주입.
enum SampleData {
    static func seedIfRequested(_ context: ModelContext) {
        guard ProcessInfo.processInfo.environment["SEED_SAMPLE"] == "1" else { return }
        guard (try? context.fetch(FetchDescriptor<Trip>()))?.isEmpty ?? false else { return }

        // 2026-12-04 (도쿄) 고정 날짜
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let day = c.date(from: DateComponents(year: 2026, month: 12, day: 4, hour: 10))!

        let trip = Trip(name: "일본 여행", startDate: day,
                        startAddress: "도쿄역", startLatitude: 35.681, startLongitude: 139.767)
        context.insert(trip)

        // 기록 경로(파란 실선): 도쿄역 → 긴자 방향
        let path: [(Double, Double)] = [
            (35.681, 139.767), (35.680, 139.770), (35.678, 139.773),
            (35.675, 139.774), (35.672, 139.766), (35.671, 139.763),
        ]
        for (i, p) in path.enumerated() {
            context.insert(TrackPoint(latitude: p.0, longitude: p.1, altitude: 0,
                                      horizontalAccuracy: 5, speed: 1.2,
                                      timestamp: day.addingTimeInterval(Double(i) * 300), trip: trip))
        }

        // 계획 이동 구간(주황 점선): 출발→도착. 둘째·셋째는 출발 비워 자동 체이닝.
        // 호텔 → 센소지 → 스카이트리 → 우에노
        let hotel = (35.6938, 139.7036)
        context.insert(PlanItem(title: "센소지 방문", plannedAt: day.addingTimeInterval(2 * 3600),
                                fromPlaceName: "호텔", fromLatitude: hotel.0, fromLongitude: hotel.1,
                                toPlaceName: "센소지", toLatitude: 35.7148, toLongitude: 139.7967, trip: trip))
        context.insert(PlanItem(title: "스카이트리 이동", plannedAt: day.addingTimeInterval(4 * 3600),
                                toPlaceName: "도쿄 스카이트리", toLatitude: 35.7101, toLongitude: 139.8107, trip: trip))
        context.insert(PlanItem(title: "우에노 공원", plannedAt: day.addingTimeInterval(6 * 3600),
                                toPlaceName: "우에노 공원", toLatitude: 35.7156, toLongitude: 139.7730, trip: trip))

        // 투두
        context.insert(TodoItem(title: "여권 챙기기", isDone: true, createdAt: day))
        context.insert(TodoItem(title: "포켓와이파이 수령", createdAt: day,
                                dueDate: c.date(from: DateComponents(year: 2026, month: 12, day: 3))!))

        try? context.save()
    }
}
