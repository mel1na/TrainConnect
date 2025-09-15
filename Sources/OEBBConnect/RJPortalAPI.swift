//
//  RailnetAPI.swift
//  DBConnect
//
//  Created by Melina on 15.09.25.
//

import Foundation
import Moya

//URL: https://railnet.oebb.at/assets/media/fis/combined.json

public enum RJPortalAPI {
    case combined
    case gps
    case speed
    case train_info
}

extension RJPortalAPI: TargetType {
    public var baseURL: URL {
        URL(string: "https://railnet.oebb.at")!
    }
    
    public var path: String {
        switch self {
        case .combined:
            return "/assets/media/fis/combined.json"
        case .gps:
            return "/api/gps"
        case .speed:
            return "/api/speed"
        case .train_info:
            return "/api/v1/admin/train-carriage-services"
        }
    }
    
    public var method: Moya.Method {
        return .get
    }
    
    public var sampleData: Data {
        switch self {
        case .combined:
            return self.data(for: "rj-sbg-vie")
        case .gps:
            return self.data(for: "gps")
        case .speed:
            return self.data(for: "speed")
        case .train_info:
            return self.data(for: "rj-sbg-vie-tcs")
        }
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
    
    public var task: Task {
        .requestPlain
    }
    
    public var headers: [String : String]? {
        return [:]
    }
}

