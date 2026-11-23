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

        // 계획 방문 경로(주황 점선): 세 곳
        let plans: [(String, Double, Double, Int)] = [
            ("센소지", 35.7148, 139.7967, 2),
            ("도쿄 스카이트리", 35.7101, 139.8107, 4),
            ("우에노 공원", 35.7156, 139.7730, 6),
        ]
        for (title, lat, lon, hourOffset) in plans {
            context.insert(PlanItem(title: title, plannedAt: day.addingTimeInterval(Double(hourOffset) * 3600),
                                    placeName: title, latitude: lat, longitude: lon, trip: trip))
        }

        // 투두
        context.insert(TodoItem(title: "여권 챙기기", isDone: true, createdAt: day))
        context.insert(TodoItem(title: "포켓와이파이 수령", createdAt: day,
                                dueDate: c.date(from: DateComponents(year: 2026, month: 12, day: 3))!))

        try? context.save()
    }
}
