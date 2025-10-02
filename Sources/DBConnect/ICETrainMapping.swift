//
//  TrainMapping.swift
//  ICE Buddy
//
//  Created by Maximilian Seiferth on 04.02.22.
//

import Foundation
import SwiftUI
import TrainConnect
#if targetEnvironment(macCatalyst)
import AppKit
#endif

#if !os(macOS)
import UIKit
#endif

public struct ICETrainType: TrainType {
  
    enum Model: CaseIterable {
        case BR401, BR402, BR403, BR407, BR408, BR411_1, BR411_2, BR412, BR415, unknown
        
        var triebZugNummern: [Int] {
            switch self {
            case .BR401:
                return [Int](101...199)
            case .BR402:
                return [Int](201...299)
            case .BR403:
                return [Int](301...399)
            case .BR407:
                return [Int](701...799) + [Int](4701...4799)
            case .BR408:
                return [Int](8001...8079)
            case .BR411_1:
                return [Int](1101...1150)
            case .BR411_2:
                return [Int](1151...1199)
            case .BR412:
                return [Int](9001...9999)
            case .BR415:
                return [Int](1501...1599)
            case .unknown:
                return []
            }
        }
    }
    
    var triebZugNummer: String
    var model: Model
    
    init(tzn: String) {
        self.model = Model.allCases.first { trainType in
            trainType.triebZugNummern.contains(triebzugnummer: tzn)
        } ?? .unknown
        self.triebZugNummer = tzn
    }
    
  
    
    public var humanReadableTrainType: String {
        switch self.model {
        case .BR401:
            return "ICE 1"
        case .BR402:
            return "ICE 2"
        case .BR403, .BR407:
            return "ICE 3"
        case .BR408:
            return "ICE 3neo"
        case .BR411_1, .BR411_2, .BR415:
            return "ICE T"
        case .BR412:
            return "ICE 4"
        case .unknown:
            return "Unknown Train Type"
        }
    }
    
    public var trainModel: String {
        var formattedTrainType: String = self.humanReadableTrainType
        switch self.triebZugNummer.extractedNumber {
        case 304:
            formattedTrainType += " 🏳️‍🌈"
        case 8029:
            formattedTrainType += " 🇪🇺"
        case 9457:
            formattedTrainType += " 🇩🇪"
        case .none:
            break
        case .some(_):
            break
        }
        return "\(formattedTrainType) (TZN: \(self.triebZugNummer.extractedNumber ?? 99999))"
    }
    
    #if os(iOS)
    @available(iOS 13.0, *)
    public var trainIcon: Image? {
        switch self.triebZugNummer.extractedNumber {
        case 304:
            return Image("BR403-Regenbogen", bundle: Bundle.module)
        case 8029:
            return Image("BR408-Europa", bundle: Bundle.module)
        case 9457:
            return Image("BR412-Deutschland", bundle: Bundle.module)
        default:
            break
        }
        switch self.model {
        case .BR401:
            return Image("BR401", bundle: Bundle.module)
        case .BR402:
            return Image("BR402", bundle: Bundle.module)
        case .BR403:
            return Image("BR403", bundle: Bundle.module)
        case .BR407:
            return Image("BR407", bundle: Bundle.module)
        case .BR408:
            return Image("BR408", bundle: Bundle.module)
        case .BR411_1:
            return Image("BR411-1", bundle: Bundle.module)
        case .BR411_2:
            return Image("BR411-2", bundle: Bundle.module)
        case .BR412:
            return Image("BR412", bundle: Bundle.module)
        case .BR415:
            return Image("BR415", bundle: Bundle.module)
        case .unknown:
            return Image("BR401", bundle: Bundle.module)
        }
    }
    #endif
    
    #if os(macOS)
    public var trainIcon: NSImage? {
        switch self.triebZugNummer.extractedNumber {
        case 304:
            return Bundle.module.image(forResource: "BR403-Regenbogen")!
        case 8029:
            return Bundle.module.image(forResource: "BR408-Europa")!
        case 9457:
            return Bundle.module.image(forResource: "BR412-Deutschland")!
        default:
            break
        }
        switch self.model {
        case .BR401:
            return Bundle.module.image(forResource: "BR401")!
        case .BR402:
            return Bundle.module.image(forResource: "BR402")!
        case .BR403:
            return Bundle.module.image(forResource: "BR403")!
        case .BR407:
            return Bundle.module.image(forResource: "BR407")!
        case .BR408:
            return Bundle.module.image(forResource: "BR408")!
        case .BR411_1:
            return Bundle.module.image(forResource: "BR411-1")!
        case .BR411_2:
            return Bundle.module.image(forResource: "BR411-2")!
        case .BR412:
            return Bundle.module.image(forResource: "BR412")!
        case .BR415:
            return Bundle.module.image(forResource: "BR415")!
        case .unknown:
            return Bundle.module.image(forResource: "BR401")!
        }
    }
    #endif
    
}

private extension Array where Element == Int {
    func contains(triebzugnummer: String) -> Bool {
        guard let match = triebzugnummer.match(pattern: "^(tz|ice) ?(\\d+)?$"),
              let range = Range(match.range(at: 2), in: triebzugnummer),
              let digits = Int(triebzugnummer[range], radix: 10) else {
            return false
        }
        return contains(digits)
    }
}

private extension String {
    func match(pattern: String) -> NSTextCheckingResult? {
        // Replace with Swift regular expression matching once targeting macOS 13.0 or higher
        let range = NSRange(startIndex..<endIndex, in: self)
        return try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            .firstMatch(in: self, range: range)
    }
    
    var extractedNumber: Int? {
        guard let match = self.match(pattern: "^(tz|ice) ?(\\d+)?$"),
              let range = Range(match.range(at: 2), in: self),
              let number = Int(self[range]) else {
            return nil
        }

        return number
    }
}
