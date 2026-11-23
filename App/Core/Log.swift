import Foundation
import os

/// 통합 로깅(os.Logger). 카테고리별로 분리해 Console.app / `log` 명령에서 필터링하기 쉽게.
///
/// 실기기에서 실시간 보기:
///   log stream --predicate 'subsystem == "com.example.TravelTracker"' --level debug
/// 사후 수집:
///   log collect --device --start "YYYY-MM-DD HH:MM:SS" --output tt.logarchive
enum Log {
    static let subsystem = "com.example.TravelTracker"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let location = Logger(subsystem: subsystem, category: "location")
    static let recording = Logger(subsystem: subsystem, category: "recording")
    static let repo = Logger(subsystem: subsystem, category: "repository")
    static let photo = Logger(subsystem: subsystem, category: "photo")
    static let export = Logger(subsystem: subsystem, category: "export")
    static let plan = Logger(subsystem: subsystem, category: "plan")
    static let todo = Logger(subsystem: subsystem, category: "todo")
    static let map = Logger(subsystem: subsystem, category: "map")
}
