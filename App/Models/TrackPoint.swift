import Foundation
import SwiftData

/// 저장된 경로 점 하나.
@Model
final class TrackPoint {
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var horizontalAccuracy: Double
    var speed: Double
    var timestamp: Date

    var trip: Trip?

    init(
        latitude: Double,
        longitude: Double,
        altitude: Double,
        horizontalAccuracy: Double,
        speed: Double,
        timestamp: Date,
        trip: Trip? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.speed = speed
        self.timestamp = timestamp
        self.trip = trip
    }

    convenience init(sample: LocationSample, trip: Trip? = nil) {
        self.init(
            latitude: sample.latitude,
            longitude: sample.longitude,
            altitude: sample.altitude,
            horizontalAccuracy: sample.horizontalAccuracy,
            speed: sample.speed,
            timestamp: sample.timestamp,
            trip: trip
        )
    }
}
