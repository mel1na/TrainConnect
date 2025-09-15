//
//  RJModel.swift
//  DBConnect
//
//  Created by Melina on 15.09.25.
//

import Foundation
import TrainConnect
import CoreLocation
#if os(macOS)
import AppKit
#else
import UIKit
import SwiftUI
#endif

// MARK: CombinedResponse

public struct CombinedResponse: Codable, TrainTrip {
    public var train: String {
        self.trainType
    }
    
    public var vzn: String {
        self.tripNumber
    }
    
    public let lineNumber: String
    public let tripNumber: String
    public let trainType: String
    public let startStation: String
    
    public let destination: JourneyStationName
    public let stations: [JourneyStop]
    
    public var trainStops: [TrainStop] {
        self.stations
    }
    
    public let latestStatus: LatestStatus
    public let currentStation, nextStation: JourneyStop
    public let nextStationProgress: Numeric
    
    var endPassed = false
    for i in 0..<stations.count {
        if (currentStation.id != stations[i].id && latestStatus.speed != 0) {
            stations[i].hasPassed = true
        } else if (currentStation.id == stations[i].id || endPassed) {
            //stations[i].hasPassed = false
            endPassed = true
        }
    }
}

// MARK: Stop
public struct JourneyStop: Codable, TrainStop {
    public let arrival, departure: JourneyStopTime
    public let track: Track
    public let name: JourneyStationName
    public let station: Station
    
    public var id: Numeric //evaNr
    
    public var scheduledArrival: Date? {
        self.arrival.scheduled
    }
    
    public var actualArrival: Date? {
        self.arrival.forecast
    }
    
    public var scheduledDeparture: Date? {
        self.departure.scheduled
    }
    
    public var actualDeparture: Date? {
        self.departure.forecast
    }
    
    public var trainStation: TrainStation {
        return Station(evaNr: id, name: name)
    }
    
    public var hasPassed: Bool = false
    // latestStatus.speed == 0 && nextStationProgress == 0 &&
    // false if lateststatus.speed == 0 and nextstationprogress == 0 and currentstation id matches
    // and also all stations after that
    
    public var trainTrack: TrainTrack? {
        if let track = track {
            return Track(scheduled: track.de, actual: track.de)
        }
        return nil
    }
    
    public var exitSide: String?
    public var distanceFromPrevious: Numeric?
}

public struct Track: Decodable, TrainTrack {
    public let de: String
}

public struct JourneyStopTime: Decodable {
    public let scheduled: String?
    public let forecast: String?
}

public struct JourneyStationName: Codable {
    public let all: String?
    public let de: String
    
    // Custom initializer to directly return the "de" value
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Directly decode the "de" value into the struct
        self.de = try container.decode(String.self, forKey: .de)
    }
    
    // The coding key for "de"
    private enum CodingKeys: String, CodingKey {
        case de
    }
}

public struct LatestStatus: Decodable {
    public let dateTime: Date
    public let situation: Situation
    public let gpsPosition: GPSPosition
    public let speed: Numeric
    public let distance: Distance
    public let totalDelay: Numeric //in seconds?
    public let comment: String?
}

public struct Situation: Decodable {
    public let type: String
    public let station: String
}

public struct GPSPosition: Decodable {
    public let latitude: Double
    public let longitude: Double
    public let orientation: Double?
}

public struct Distance: Decodable {
    public let meters: Numeric
    public let fromStation: String
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

public struct Status: Decodable {
    public let latitude: Double
    public let longitude: Double
    public let speed: Numeric
    
    public var currentConnectivity: String? {
        return "Unknown"
    }
    
    public var connectedDevices: Int? {
        nil
    }
    
    public var trainType: TrainType {
        return TrainType(trainModel: "Railjet")
    }
    
    public var currentSpeed: Measurement<UnitSpeed> {
        Measurement<UnitSpeed>(value: self.speed, unit: .kilometersPerHour)
    }
}
