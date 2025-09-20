//
//  RJDataController.swift
//  DBConnect
//
//  Created by Melina on 15.09.25.
//

import Foundation
import Combine
import Moya
import TrainConnect

extension DateFormatter {
    static let rjFormatter: DateFormatter = {
        //2025-09-15T17:48:54+0200
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}

public class RJDataController: NSObject, TrainDataController {
    public static let shared = RJDataController()
    
    override init() {
        super.init()
    }
    
    public func getProvider(demoMode: Bool) -> MoyaProvider<RJPortalAPI> {
        if demoMode {
            return MoyaProvider<RJPortalAPI>(stubClosure: MoyaProvider.immediatelyStub)
        } else {
            return MoyaProvider<RJPortalAPI>(stubClosure: MoyaProvider.neverStub)
        }
    }
    
    public func loadTrip(demoMode: Bool, completionHandler: @escaping (TrainTrip?, Error?) -> ()){
        self.loadCombined(demoMode: demoMode, completionHandler: {
            completionHandler($0, $1)
        })
    }
    private func loadCombined(demoMode: Bool, completionHandler: @escaping (CombinedResponse?, Error?) -> ()){
        let provider = getProvider(demoMode: demoMode)
        provider.session.session.configuration.timeoutIntervalForRequest = 2
        provider.session.session.configuration.timeoutIntervalForResource = 2
        provider.request(.combined) { result in
            switch result {
            case .success(let response):
                do {
                    let response = try response.filterSuccessfulStatusCodes()
                    let decoder = JSONDecoder()
                    //decodes latestStatus.dateTime
                    decoder.dateDecodingStrategy = .formatted(DateFormatter.rjFormatter)
                    let trip = try decoder.decode(CombinedResponse.self, from: response.data)
                    completionHandler(trip, nil)
                } catch DecodingError.dataCorrupted(let context) {
                    if response.response?.allHeaderFields["Content-Type"] as! String != "application/octet-stream" {
                        completionHandler(nil, TrainConnectionError.notConnected)
                        break
                    }
                    print(context)
                } catch DecodingError.keyNotFound(let key, let context) {
                    print("Key '\(key)' not found:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch DecodingError.valueNotFound(let value, let context) {
                    print("Value '\(value)' not found:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch DecodingError.typeMismatch(let type, let context) {
                    print("Type '\(type)' mismatch:", context.debugDescription)
                    print("codingPath:", context.codingPath)
                } catch {
                    print(error.localizedDescription)
                    completionHandler(nil, error)
                }
                break
            case .failure(let error):
                print(error.localizedDescription)
                completionHandler(nil, error)
                break
            }
        }
    }
    
    public func loadTrainStatus(demoMode: Bool, completionHandler: @escaping (TrainStatus?, Error?) -> ()) {
        self.loadCombined(demoMode: demoMode) { combined, error in
            if let combined = combined {
                completionHandler(Status(latitude: combined.latestStatus.gpsPosition.latitude, longitude: combined.latestStatus.gpsPosition.longitude, speed: combined.latestStatus.speed), nil)
            }
        }
    }
}
