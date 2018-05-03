//
//  DeviceManager.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 02/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import Foundation
import UIKit

class DeviceManager {
	var devices = [Device]()
	let LOCALDEVICES_FILENAME: String = "local-devices"
	static let shared: DeviceManager = DeviceManager()

	func loadDevices() {
		do {
			let fileToGet = try self.getFileUrl()
			let deviceData = try Data(contentsOf: fileToGet)
			guard let devices = NSKeyedUnarchiver.unarchiveObject(with: deviceData) as? [Device] else {
				print("Could not get devices")
				return
			}
			print("loaded \(devices.count) devices")
			self.devices = devices
		} catch {
			print(error)
		}
	}
	
	
	func saveDevices() {
		do {
			let fileToSave = try self.getFileUrl()
			let deviceData = NSKeyedArchiver.archivedData(withRootObject: self.devices)
			try deviceData.write(to: fileToSave)
		} catch {
			print(error)
		}
	}
	
	func getFileUrl() throws -> URL {
		let fileManager = FileManager.default
		let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
		return documentDirectory.appendingPathComponent(self.LOCALDEVICES_FILENAME)
	}
	
	func deviceAdded(device: Device) -> Bool {
		for addedDevice in self.devices {
			if addedDevice.id == device.id{
				return true
			}
		}
		return false
	}
	
	func removeDevice(device: Device) {
		for addedDevice in self.devices {
			if addedDevice.id == device.id{
				if let index = self.devices.index(of: addedDevice) {
					self.devices.remove(at: index)
				}
			}
		}
	}
}


class Device : NSObject, NSCoding {
	init(id: Int, type: String, name: String, host: Host, isOn: Bool, state: String) {
		self.name = name
		self.type = DeviceType.typeFromString(string: type)
		self.host = host
		self.isOn = isOn
		self.state = state
		self.id = id
	}
	
	convenience init?(dict: [String: Any], service: NetService) {
		guard let typestring = dict["type"] as? String,
			let id = dict["id"] as? Int,
			let name = dict["name"] as? String,
			let isOn = dict["isOn"] as? Bool,
			let state = dict["state"] as? String,
			let hostname = service.hostName else {
				print("Not all values present")
				return nil
		}
		let host: Host = Host(port: service.port, hostName: hostname)
		self.init(id: id, type: typestring, name: name, host: host, isOn: isOn, state: state)
	}
	
	init(device: Device) {
		self.id = device.id
		self.host = device.host
		self.name = device.name
		self.type = device.type
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(self.type.stringRepresentation(), forKey: "type")
		aCoder.encode(self.name, forKey: "name")
		aCoder.encode(self.host.hostName, forKey: "hostname")
		aCoder.encode(self.host.port, forKey: "port")
		aCoder.encode(self.id, forKey: "id")
	}
	
	required convenience init?(coder aDecoder: NSCoder) {
		guard let typestring = aDecoder.decodeObject(forKey: "type") as? String,
			let name = aDecoder.decodeObject(forKey: "name") as? String,
			let hostname = aDecoder.decodeObject(forKey: "hostname") as? String else {
				return nil
		}
		let port = aDecoder.decodeInteger(forKey: "port")
		let id = aDecoder.decodeInteger(forKey: "id")
		let host = Host(port: port, hostName: hostname)
		self.init(id: id, type: typestring, name: name, host: host, isOn: false, state: "")
	}
	let id: Int
	let host: Host
	let type: DeviceType
	var name: String
	var state: String = ""
	var isOn: Bool = false
	var isConnected: Bool = false
}

struct Host: Equatable {
	let port: Int
	let hostName: String
	
	static func ==(lhs: Host, rhs: Host) -> Bool {
		return lhs.hostName == rhs.hostName && lhs.port == rhs.port
	}
}

enum DeviceType {
	case Light
	case Screen
	case Other
	static func typeFromString(string: String) -> DeviceType {
		switch string {
		case "light":
			return self.Light
		case "screen":
			return self.Screen
		default:
			return self.Other
		}
	}
	
	func getIcon() -> UIImage {
		switch self {
		case .Light:
			return #imageLiteral(resourceName: "light")
		case .Screen:
			return #imageLiteral(resourceName: "screen")
		default:
			return #imageLiteral(resourceName: "other")
		}
	}
	
	func stringRepresentation() -> String {
		switch self {
		case .Light:
			return "light"
		case .Screen:
			return "screen"
		default:
			return "other"
		}
	}
	
}
