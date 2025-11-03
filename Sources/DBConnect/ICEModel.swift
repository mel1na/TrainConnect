//
//  File.swift
//  
//
//  Created by Max Seiferth on 09.06.22.
//

import Foundation
import TrainConnect
import CoreLocation

public struct TripResponse: Decodable {
    public let trip: Trip
}

public struct Trip: Decodable, TrainTrip {
    
    public let tripDate: Date
    public let trainType: String
    public let vzn: String
    public let stopInfo: JourneyStopInfo
    public let stops: [JourneyStop]
    
    public var trainStops: [TrainStop] {
        self.stops
    }
    
    public var train: String {
        self.trainType
    }
    
    public var finalStopInfo: TrainFinalStopInfo? {
        self.stopInfo
    }
}

public struct JourneyStopInfo: Decodable, TrainFinalStopInfo {
    public let finalStationName: String
    public let finalStationEvaNr: String
}

public struct JourneyStop: Decodable, Hashable, Identifiable, TrainStop {
    public let id = UUID()
    public let station: Station
    public let timetable: Timetable
    public let track: Track
    public let info: Info
    public let delayReasons: [DelayReasons]?
    
    public var scheduledArrival: Date? {
        self.timetable.scheduledArrivalTimeDate
    }
    
    public var actualArrival: Date? {
        self.timetable.actualArrivalTimeDate
    }
    
    
    public var scheduledDeparture: Date? {
        self.timetable.scheduledDepartureTimeDate
    }
    
    public var actualDeparture: Date? {
        self.timetable.actualDepartureTimeDate
    }
    
    public var trainStation: TrainStation {
        self.station
    }
    
    public var trainTrack: TrainTrack? {
        self.track
    }

    
    public var hasPassed: Bool {
        self.info.passed
    }
    
    public var delayReason: String? {
        self.delayReasons?.last?.text
    }

    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: JourneyStop, rhs: JourneyStop) -> Bool {
        return lhs.id == rhs.id
    }
}

public struct Station: Decodable, TrainStation {
    public let evaNr: String
    public let name: String
    public let geocoordinates: Coordinate?
    
    public var code: String {
        self.evaNr
    }
    
    public var coordinates: CLLocationCoordinate2D? {
        if let coordinates = geocoordinates {
            return CLLocationCoordinate2D(latitude: coordinates.latitude, longitude: coordinates.longitude)
        }
        return nil
    }
}

public struct Timetable: Decodable {
    public let scheduledArrivalTime: Double?
    public var scheduledArrivalTimeDate: Date? {
        if let scheduledArrivalTime = scheduledArrivalTime {
            return Date(timeIntervalSince1970: (scheduledArrivalTime / 1000))
        }
        return nil
    }

    
    public let actualArrivalTime: Double?
    public var actualArrivalTimeDate: Date? {
        if let actualArrivalTime = actualArrivalTime {
            return Date(timeIntervalSince1970: (actualArrivalTime / 1000))
        }
        return nil
    }
    
    public let showActualArrivalTime: Bool?
    public let arrivalDelay: String
    
    public let scheduledDepartureTime: Double?
    public var scheduledDepartureTimeDate: Date? {
        if let scheduledDepartureTime = scheduledDepartureTime {
            return Date(timeIntervalSince1970: (scheduledDepartureTime / 1000))
        }
        return nil
    }
    
    public let actualDepartureTime: Double?
    public var actualDepartureTimeDate: Date? {
        if let actualDepartureTime = actualDepartureTime {
            return Date(timeIntervalSince1970: (actualDepartureTime / 1000))
        }
        return nil
    }
    
    public let showActualDepartureTime: Bool?
    public let departureDelay: String
}

public struct Track: Decodable, TrainTrack {
    public let scheduled: String
    public let actual: String
}

public struct Info: Decodable {
    public let distance: Int
    public let passed: Bool
    public let status: Int
}

public struct DelayReasons: Decodable {
    public let code: String
    public let text: String
}

public struct Coordinate: Decodable {
    public let latitude: Double
    public let longitude: Double
}

public struct Status: TrainStatus {
    public let status: StatusResponse
    public let bap: BapStatusResponse
    public let availability: BapAvailabilityResponse
    
    public var latitude: Double {
        status.latitude
    }
    
    public var longitude: Double {
        status.longitude
    }
    
    public var currentSpeed: Measurement<UnitSpeed> {
        status.currentSpeed
    }
    
    public var currentConnectivity: String? {
        status.currentConnectivity
    }
    
    public var connectedDevices: Int? {
        status.connectedDevices
    }
    
    public var trainType: TrainType {
        status.trainType
    }
    
    public var restaurant: TrainRestaurantData? {
        ICERestaurantData(
            status: bap.bapServiceStatus.rawValue,
            installed: status.bapInstalled,
            availabilities: availability.availabilities
        )
    }
    
    public var wagonClass: String? {
        status.wagonClass
    }
    
}

public struct ICERestaurantData: TrainRestaurantData {
    public let status: String?
    public let installed: Bool?
    public let availabilities: [BapAvailability]?
    public var availableProducts: Int? {
        var count: Int = 0
        for availability in (self.availabilities ?? []) where availability.status.contains("AVAILABLE") {
            count += 1
        }
        return count
    }
    public var totalProducts: Int? {
        self.availabilities?.count
    }

    public init(status: String?, installed: Bool?, availabilities: [BapAvailability]?) {
        self.status = status
        self.installed = installed
        self.availabilities = availabilities
    }
}

public struct StatusResponse: Decodable {
    
    public let latitude: Double
    public let longitude: Double
    public let series: String
    public let speed: Double
    public let tzn: String
    public let wagonClass: String
    
    public let connectivity: Connectivity
    
    
    public var currentConnectivity: String? {
        self.connectivity.currentState
    }
    
    public var connectedDevices: Int? {
        nil
    }
    
    public var trainType: TrainType {
        ICETrainType(tzn: tzn)
    }
    
    public var currentSpeed: Measurement<UnitSpeed> {
        Measurement<UnitSpeed>(value: self.speed, unit: .kilometersPerHour)
    }
    
    public let bapInstalled: Bool
}

public struct Connectivity: Decodable {
    public let currentState: String?
    public let nextState: String?
    public let remainingTimeSeconds: Int?
}

public struct BapStatusResponse: Decodable {
    public let bapServiceStatus: BapServiceStatus //ACTIVE, PAUSED or INACTIVE
}

public enum BapServiceStatus: String, Decodable {
    case active = "ACTIVE"
    case paused = "PAUSED"
    case inactive = "INACTIVE"
}

public struct BapAvailability: Decodable {
    public let ecmId: String
    public let status: String
}

public struct BapAvailabilityResponse: Decodable {
    public let availabilities: [BapAvailability]
}
