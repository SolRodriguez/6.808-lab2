//
//  SensorModel.swift
//  Anteater
//
//  Created by Justin Anderson on 8/1/16.
//  Copyright © 2016 MIT. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth
import MapKit

protocol SensorModelDelegate {
    func sensorModel(_ model: SensorModel, didChangeActiveHill hill: Hill?)
    func sensorModel(_ model: SensorModel, didReceiveReadings readings: [Reading], forHill hill: Hill?)
}

extension Notification.Name {
    public static let SensorModelActiveHillChanged = Notification.Name(rawValue: "SensorModelActiveHillChangedNotification")
    public static let SensorModelReadingsChanged = Notification.Name(rawValue: "SensorModelHillReadingsChangedNotification")
}

enum ReadingType: Int {
    case Unknown = -1
    case Humidity = 2
    case Temperature = 1
    case Error = 0
}

struct Reading {
    let type: ReadingType
    let value: Double
    let date: Date = Date()
    let sensorId: String?
    
    func toJson() -> [String: Any] {
        return [
            "value": self.value,
            "type": self.type.rawValue,
            "timestamp": self.date.timeIntervalSince1970,
            "userid": UIDevice.current.identifierForVendor?.uuidString ?? "NONE",
            "sensorid": sensorId ?? "NONE"
        ]
    }
}

extension Reading: CustomStringConvertible {
    var description: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        guard let numberString = formatter.string(from: NSNumber(value: self.value)) else {
            print("Double \"\(value)\" couldn't be formatted by NumberFormatter")
            return "NaN"
        }
        switch type {
        case .Temperature:
            return "\(numberString)°F"
        case .Humidity:
            return "\(numberString)%"
        default:
            return "\(type)"
        }
    }
}

struct Hill {
    var readings: [Reading]
    var name: String
    
    init(name: String) {
        readings = []
        self.name = name
    }
}

extension Hill: CustomStringConvertible, Hashable, Equatable {
    var description: String {
        return name
    }
    
    var hashValue: Int {
        return name.hashValue
    }
}

func ==(lhs: Hill, rhs: Hill) -> Bool {
    return lhs.name == rhs.name
}

class SensorModel: BLEDelegate {
    func ble(didUpdateState state: BLEState) {
        NSLog("called didUpdate")
        NSLog(state.description)
        if (state == BLEState.poweredOn) {
            NSLog("Start scanning for anthills...")
            ble.startScanning(timeout: 100) //TODO: Review timeout
        }
    }
    
    func ble(didDiscoverPeripheral peripheral: CBPeripheral) {
        NSLog("Discovered Peripheral")
        let connected = ble.connectToPeripheral(peripheral)
        if (connected) {
            NSLog("Connecting to Peripheral")
        }
    }
    
    func ble(didConnectToPeripheral peripheral: CBPeripheral) {
        NSLog("Connected to Peripheral")
        activeHill = Hill(name: peripheral.name!)
        cbPeripheral = peripheral
        delegate?.sensorModel(self, didChangeActiveHill: activeHill)
    }
    
    func ble(didDisconnectFromPeripheral peripheral: CBPeripheral) {
        NSLog("Did Receive Data called")
        activeHill = nil
        delegate?.sensorModel(self, didChangeActiveHill: activeHill)
        ble.startScanning(timeout: 100) //TODO: Review timeout
    }
    
    func ble(_ peripheral: CBPeripheral, didReceiveData data: Data?) {
        NSLog("called did receive data")
        // convert a non-nil Data optional into a String
        let str = String(data: data!, encoding: String.Encoding.ascii)!

        // get a substring that excludes the first and last characters
        let substring = str[str.index(after: str.startIndex)..<str.index(before: str.endIndex)]

        // convert a Substring to a Double
        let value = Double(substring)!
        
        
        let i = str.index(str.startIndex, offsetBy:0)
        NSLog(String(str[i]))
        
        if (str[i] == "H") {
            activeHill?.readings.append(Reading(type: ReadingType.Humidity, value: value, sensorId: peripheral.name))
        } else if (str[i] == "T") {
            let temp = (value * 1.8) + 32
            activeHill?.readings.append(Reading(type: ReadingType.Temperature, value: temp, sensorId: peripheral.name))
        }
        
        delegate?.sensorModel(self, didReceiveReadings: (activeHill?.readings)!, forHill: activeHill)
        
    }
    
    static let kBLE_SCAN_TIMEOUT = 10000.0
    
    static let shared = SensorModel()
    
    var ble = BLE()
    var delegate: SensorModelDelegate?
    var sensorReadings: [ReadingType: [Reading]] = [.Humidity: [], .Temperature: []]
    var activeHill: Hill?
    var cbPeripheral : CBPeripheral?
    
    init() {
        ble.delegate = self
        NSLog("called init")
        
    }
}
