//
//  ICEPortalAPI.swift
//  ICE Buddy
//
//  Created by Maximilian Seiferth on 28.01.22.
//

import Foundation
import Moya

// trip info: https://iceportal.de/api1/rs/tripInfo/trip
// trip status: https://iceportal.de/api1/rs/status
// bordbistro status: https://iceportal.de/bap/api/bap-service-status

public enum ICEPortalAPI {
    case trip
    case status
    case bap_status
    case bap_availabilities
    case bap_products
}

extension ICEPortalAPI: TargetType {
    public var baseURL: URL {
        URL(string: "https://iceportal.de")!
    }
    
    public var path: String {
        switch self {
        case .trip:
            return "/api1/rs/tripInfo/trip"
        case .status:
            return "/api1/rs/status"
        case .bap_status:
            return "/bap/api/bap-service-status"
        case .bap_availabilities:
            return "/bap/api/availabilities"
        case .bap_products:
            return "/bap/api/products"
        }
    }
    
    public var method: Moya.Method {
        return .get
    }
    
    private func data(for sample: String) -> Data {
        do {
            if let bundlePathURL = Bundle.module.path(forResource: sample, ofType: "json") {
                let data = try Data(contentsOf: URL(fileURLWithPath: bundlePathURL))
                return data
            } else {
                print("File could not be found")
            }
        } catch {
            print(error.localizedDescription)
        }
        return Data()
    }
    
    
    public var sampleData: Data {
        switch self {
        case .trip:
            return self.data(for: "tripInfo1")
        case .status:
            return self.data(for: "status")
        case .bap_status:
            return self.data(for: "bap-status")
        case .bap_availabilities:
            return self.data(for: "bap-availabilities")
        case .bap_products:
            return self.data(for: "bap-products")
        }
    }
    
    public var task: Task {
        .requestPlain
    }
    
    public var headers: [String : String]? {
        return [:]
    }
}
