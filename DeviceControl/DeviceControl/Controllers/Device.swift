//
//  Device.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 05/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import Foundation
import UIKit

class Device : NSObject, NSCoding {
	init(id: Int, type: String, name: String, host: Host, on: Bool, brightness: Int, color: String) {
		self.name = name
		self.type = DeviceType.typeFromString(string: type)
		self.host = host
		self.on = on
		self.id = id
		self.brightness = brightness
		self.color = color
	}
	
	convenience init?(dict: [String: Any], service: NetService) {
		guard let typestring = dict["type"] as? String,
			let id = dict["id"] as? Int,
			let name = dict["name"] as? String,
			let on = dict["on"] as? Bool,
			let brightness = dict["brightness"] as? Int,
			let color = dict["color"] as? String,
			let hostname = service.hostName else {
				print("Not all values present")
				return nil
		}
		let host: Host = Host(port: service.port, hostName: hostname)
		self.init(id: id, type: typestring, name: name, host: host, on: on, brightness: brightness, color: color)
	}
	
	init(device: Device) {
		self.id = device.id
		self.host = device.host
		self.name = device.name
		self.type = device.type
		self.on = device.on
		self.color = device.color
		self.brightness = device.brightness
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
		self.init(id: id, type: typestring, name: name, host: host, on: false, brightness: 0, color: "")
	}
	let id: Int
	let host: Host
	let type: DeviceType
	var name: String
	var on: Bool = false
	var isConnected: Bool = false
	var color: String = ""
	var brightness: Int = 100
	
	func getIcon() -> UIImage {
		switch self.type {
		case .Light, .IKEA:
			if self.on {
				return #imageLiteral(resourceName: "light")
			} else {
				return #imageLiteral(resourceName: "light-off")
			}

		default:
			return #imageLiteral(resourceName: "other")
		}
	}
	
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
	case IKEA
	case Other
	static func typeFromString(string: String) -> DeviceType {
		switch string {
		case "light":
			return self.Light
		case "tradfri":
			return self.IKEA
		default:
			return self.Other
		}
	}
	
	func stringRepresentation() -> String {
		switch self {
		case .Light:
			return "light"
		case .IKEA:
			return "tradfri"
		default:
			return "other"
		}
	}
	
}
