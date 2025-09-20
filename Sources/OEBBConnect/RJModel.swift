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

public var currentTrainDate: Date?

public struct CombinedResponse: Codable, TrainTrip {
    public var finalStopInfo: TrainFinalStopInfo? {
        nil
    }
    
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
    public var stations: [JourneyStop]
    
    public var trainStops: [TrainStop] {
        self.stations
    }
    
    public let latestStatus: LatestStatus
    public let currentStation, nextStation: JourneyStop
    public let nextStationProgress: Int
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
            
        self.stations = try container.decode([JourneyStop].self, forKey: .stations)
        self.latestStatus = try container.decode(LatestStatus.self, forKey: .latestStatus)
        self.currentStation = try container.decode(JourneyStop.self, forKey: .currentStation)
        self.nextStation = try container.decode(JourneyStop.self, forKey: .nextStation)
        self.lineNumber = try container.decode(String.self, forKey: .lineNumber)
        self.tripNumber = try container.decode(String.self, forKey: .tripNumber)
        self.trainType = try container.decode(String.self, forKey: .trainType)
        self.startStation = try container.decode(String.self, forKey: .startStation)
        self.destination = try container.decode(JourneyStationName.self, forKey: .destination)
        self.nextStationProgress = try container.decode(Int.self, forKey: .nextStationProgress)
        
        // check currentdate. if hh:ss of the first stop is higher than hh:ss of the current day (for example, the stop is on the next day at 00:01), assume it happened on the next day (12h diff?)
        
        // test cases:
        // hh:ss of first stop higher than current date (15:00 & 01:00) (next day)
        // hh:ss of first stop lower than current date (15:00 & 16:00) (normal)
        
        if currentTrainDate == nil {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            
            let firstStopDate = stations[0].departure.scheduled ?? "00:00"
            
            let parsed: Date = formatter.date(from: firstStopDate)!
            currentTrainDate = parsed
            /*if target <= from {
                target = calendar.date(byAdding: .day, value: 1, to: target)!
            }*/
        }
            
        if let nextIndex = stations.firstIndex(where: { $0.evaNr == nextStation.evaNr }) {
            for i in 0..<stations.count {
                stations[i].hasPassed = i < nextIndex
            }
        }
    }
    
    private enum CodingKeys: String, CodingKey {
            case stations, latestStatus, currentStation, nextStation, lineNumber, tripNumber, trainType, startStation, destination, nextStationProgress
        }
}

// MARK: Stop
public struct JourneyStop: Codable, TrainStop {
    public let delayReason: String?
    
    public let id: UUID
    public let arrival, departure: JourneyStopTime
    public let track: Track
    public let name: JourneyStationName
    
    public let evaNr: String

    public var scheduledArrival: Date? {
        if (self.arrival.scheduled != nil) {
            return nextOccurrence(of: self.arrival.scheduled!, from: currentTrainDate!)
        } else {
            return nil
        }
        //self.arrival.scheduled
    }
    
    public var actualArrival: Date? {
        if (self.arrival.forecast != nil) {
            return nextOccurrence(of: self.arrival.forecast!, from: currentTrainDate!)
        } else {
            return nil
        }
        //self.arrival.forecast
    }
    
    public var scheduledDeparture: Date? {
        if (self.departure.scheduled != nil) {
            return nextOccurrence(of: self.departure.scheduled!, from: currentTrainDate!)
        } else {
            return nil
        }
        //self.departure.scheduled
    }
    
    public var actualDeparture: Date? {
        if (self.departure.forecast != nil) {
            return nextOccurrence(of: self.departure.forecast!, from: currentTrainDate!)
        } else {
            return nil
        }
        //self.departure.forecast
    }
    
    public var trainStation: TrainStation {
        return Station(evaNr: evaNr, name: name.de, geocoordinates: nil)
    }
    
    public var hasPassed: Bool = false
    
    // latestStatus.speed == 0 && nextStationProgress == 0 &&
    // false if lateststatus.speed == 0 and nextstationprogress == 0 and currentstation id matches
    // and also all stations after that
    
    public var trainTrack: TrainTrack? {
            return Track(de: track.de)
    }
    
    public var exitSide: String?
    public var distanceFromPrevious: Int?
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let stationCode = try c.decode(String.self, forKey: .id)
        self.evaNr = stationCode
        self.id = UUID()
        self.arrival = try c.decodeIfPresent(JourneyStopTime.self, forKey: .arrival) ?? JourneyStopTime(scheduled: nil, forecast: nil)
        self.departure = try c.decodeIfPresent(JourneyStopTime.self, forKey: .departure) ?? JourneyStopTime(scheduled: nil, forecast: nil)
        self.track = try c.decodeIfPresent(Track.self, forKey: .track) ?? Track(de: "?")
        self.name = try c.decode(JourneyStationName.self, forKey: .name)
        self.delayReason = nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(evaNr, forKey: .evaNr)
        try c.encode(arrival, forKey: .arrival)
        try c.encode(departure, forKey: .departure)
        try c.encode(track, forKey: .track)
        try c.encode(name, forKey: .name)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case evaNr
        case arrival, departure, track, name
    }
}

public struct Track: Codable, TrainTrack {
    public var scheduled: String {
        self.de
    }
    
    public var actual: String {
        self.de
    }
    
    public let de: String
}

public struct JourneyStopTime: Codable {
    public let scheduled: String?
    public let forecast: String?
}

public struct JourneyStationName: Codable {
    public let all: String?
    public let de: String
    
    // Custom initializer to directly return the "de" value
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Directly decode the "de" value into the struct
        self.de = try container.decode(String.self, forKey: .de)
        self.all = self.de
    }
    
    // The coding key for "de"
    private enum CodingKeys: String, CodingKey {
        case de
    }
}

public struct LatestStatus: Codable {
    public var dateTime: Date
    public let situation: Situation
    public let gpsPosition: GPSPosition
    public let speed: Int
    public let distance: Distance
    public let totalDelay: Int //in seconds?
    public let comment: String?
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.dateTime = try container.decode(Date.self, forKey: .dateTime)
        self.situation = try container.decode(Situation.self, forKey: .situation)
        self.gpsPosition = try container.decode(GPSPosition.self, forKey: .gpsPosition)
        self.speed = try container.decode(Int.self, forKey: .speed)
        self.distance = try container.decode(Distance.self, forKey: .distance)
        self.totalDelay = try container.decode(Int.self, forKey: .totalDelay)
        self.comment = try container.decodeIfPresent(String.self, forKey: .comment)
    }
}

public struct Situation: Codable {
    public let type: String
    public let station: String
}

public struct GPSPosition: Codable {
    public var latString: String
    public var lonString: String
    public var orientString: String?
    
    public let latitude: Double
    public let longitude: Double
    public var orientation: Double? {
        if let orientString {
            return Double(orientString)
        }
        return nil
    }
    
    enum CodingKeys: String, CodingKey {
        case latString = "latitude"
        case lonString = "longitude"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latString = try container.decode(String.self, forKey: .latString)
        lonString = try container.decode(String.self, forKey: .lonString)

        latitude = Double(latString)!
        longitude = Double(lonString)!
    }
}

public struct Distance: Codable {
    public let meters: Int
    public let fromStation: String
}

public struct Station: Codable, TrainStation {
    public let evaNr: String
    public let name: String
    public let geocoordinates: GPSPosition?
    
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

public struct Status: Codable, TrainStatus {
    public let latitude: Double
    public let longitude: Double
    public let speed: Int
    
    public var currentConnectivity: String? {
        return "Unknown"
    }
    
    public var connectedDevices: Int? {
        nil
    }
    
    public var trainType: TrainType {
        OEBBTrainType()
    }
    
    public var currentSpeed: Measurement<UnitSpeed> {
        Measurement<UnitSpeed>(value: Double(self.speed), unit: .kilometersPerHour)
    }
}

struct OEBBTrainType: TrainType {
    var trainModel: String {
        return "Railjet"
    }
    
    #if os(macOS)
    var trainIcon: NSImage? {
        Bundle.module.image(forResource: self.icon)!
    }
    #endif

    #if os(iOS)
    @available(iOS 13.0, *)
    var trainIcon: Image? {
    
        Image(self.icon, bundle: Bundle.module)
    }
    #endif
    
    private var icon: String {
        return "railjet-2"
    }
    
}

func nextOccurrence(of timeString: String, from: Date) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    
    guard let parsed = formatter.date(from: timeString) else { return nil }
    let calendar = Calendar.current
    
    let comps = calendar.dateComponents([.hour, .minute], from: parsed)
    guard let hour = comps.hour, let minute = comps.minute else { return nil }
    
    var target = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: from)!
    
    /*if target <= from {
        target = calendar.date(byAdding: .day, value: 1, to: target)!
    }*/
    return target
}
