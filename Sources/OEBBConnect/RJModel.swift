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

public var currentTrainDate: Date = Date()

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
    public let stations: [JourneyStop]
    
    public var trainStops: [TrainStop] {
        self.stations
    }
    
    public let latestStatus: LatestStatus
    public let currentStation, nextStation: JourneyStop
    public let nextStationProgress: Int
    
    init(lineNumber: String, tripNumber: String, trainType: String, startStation: String, destination: JourneyStationName, stations: [JourneyStop], latestStatus: LatestStatus, currentStation: JourneyStop, nextStation: JourneyStop, nextStationProgress: Int) {
        var hitPassed = false
        currentTrainDate = ISO8601DateFormatter().date(from: latestStatus.dateTime) ?? Date()
        
        self.lineNumber = lineNumber
        self.tripNumber = tripNumber
        self.trainType = trainType
        self.startStation = startStation
        self.destination = destination
        self.stations = stations.map { stop in
            var updatedStop = stop
            //if (latestStatus.situation.type == "drive-to")
            if (currentStation.id != stop.id && latestStatus.speed != 0) {
                updatedStop.hasPassed = true
            } else if (currentStation.id == stop.id && latestStatus.situation.type == "stop" || hitPassed) {
                hitPassed = true
            }
            return updatedStop
        }
        self.latestStatus = latestStatus
        self.currentStation = currentStation
        self.nextStation = nextStation
        self.nextStationProgress = nextStationProgress
    }
    
    /*var endPassed = false
    for i in 0..<stations.count {
        if (currentStation.id != stations[i].id && latestStatus.speed != 0) {
            stations[i].hasPassed = true
        } else if (currentStation.id == stations[i].id || endPassed) {
            //stations[i].hasPassed = false
            endPassed = true
        }
    }*/
}

// MARK: Stop
public struct JourneyStop: Codable, TrainStop {
    public var delayReason: String?
    
    public var id = UUID()
    public let arrival, departure: JourneyStopTime
    public let track: Track
    public let name: JourneyStationName
    public let station: Station
    
    public var evaNr: Int //evaNr
    
    public var scheduledArrival: Date? {
        if (self.arrival.scheduled != nil) {
            return nextOccurrence(of: self.arrival.scheduled!, from: currentTrainDate)
        } else {
            return nil
        }
        //self.arrival.scheduled
    }
    
    public var actualArrival: Date? {
        if (self.arrival.forecast != nil) {
            return nextOccurrence(of: self.arrival.forecast!, from: currentTrainDate)
        } else {
            return nil
        }
        //self.arrival.forecast
    }
    
    public var scheduledDeparture: Date? {
        if (self.departure.scheduled != nil) {
            return nextOccurrence(of: self.departure.scheduled!, from: currentTrainDate)
        } else {
            return nil
        }
        //self.departure.scheduled
    }
    
    public var actualDeparture: Date? {
        if (self.departure.forecast != nil) {
            return nextOccurrence(of: self.departure.forecast!, from: currentTrainDate)
        } else {
            return nil
        }
        //self.departure.forecast
    }
    
    public var trainStation: TrainStation {
        return Station(evaNr: station.evaNr, name: station.name, geocoordinates: nil)
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
    public let dateTime: String
    public let situation: Situation
    public let gpsPosition: GPSPosition
    public let speed: Int
    public let distance: Distance
    public let totalDelay: Int //in seconds?
    public let comment: String?
}

public struct Situation: Codable {
    public let type: String
    public let station: String
}

public struct GPSPosition: Codable {
    public let latitude: Double
    public let longitude: Double
    public let orientation: Double?
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
    
    var trainIcon: NSImage? {
        nil
    }
    
}

func getDate(timeString: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    formatter.calendar = Calendar(identifier: .iso8601)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    if let date = formatter.date(from: timeString) {
        return date
    } else {
        return nil
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
