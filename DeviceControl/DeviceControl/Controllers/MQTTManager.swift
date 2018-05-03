//
//  MQTTManager.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 03/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import Foundation
import Alamofire

protocol MqttCredDelegate {
	func addedMQTTCreds(sender: MQTTManager, success: Bool, done: Bool)
}


class MQTTManager {
	var delegate: MqttCredDelegate?
	static let shared: MQTTManager = MQTTManager()
	let MQTT_INFO_PATH: String = "MQTTserver"
	var server: MQTTServer!
	
	func loadServerInfo() {
		do {
			let fileToGet = try self.getFileUrl()
			let deviceData = try Data(contentsOf: fileToGet)
			guard let server = NSKeyedUnarchiver.unarchiveObject(with: deviceData) as? MQTTServer else {
				print("Could not get MQTT server")
				return
			}
			self.server = server
		} catch {
			print(error)
		}
	}
	
	func sendMQTTCreds(server: MQTTServer){
		let parameters: Parameters = [
			"server" : server.server,
			"user" : server.user,
			"password" : server.password,
			"port" : server.port
		]
		let hosts = CoAPManager.shared.getListOfHosts()
		var success: Bool = false
		var done: Bool = false
		var hostCount = 0
		for host in hosts {
			Alamofire.request("http://\(host.hostName):3000/addmqtt", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { (response) in
				guard let JSONValue = response.result.value as? [String: Any], let reqSuccess = JSONValue["success"] as? Bool else {
					print("Could not get JSON")
					return
				}
				if reqSuccess {
					success = true
				}
				hostCount += 1
				if hostCount >= hosts.count {
					done = true
				}
				self.delegate?.addedMQTTCreds(sender: self, success: success, done: done)
			}
		}
	}
	
	func getFileUrl() throws -> URL {
		let fileManager = FileManager.default
		let documentDirectory = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
		return documentDirectory.appendingPathComponent(self.MQTT_INFO_PATH)
	}
	
	func saveMQTTInfo(server: MQTTServer) {
		do {
			let fileToSave = try self.getFileUrl()
			let deviceData = NSKeyedArchiver.archivedData(withRootObject: server)
			try deviceData.write(to: fileToSave)
		} catch {
			print(error)
		}
	}
}



class MQTTServer : NSObject, NSCoding {
	func encode(with aCoder: NSCoder) {
		aCoder.encode(self.server, forKey: "server")
		aCoder.encode(self.user, forKey: "user")
		aCoder.encode(self.password, forKey: "password")
		aCoder.encode(self.port, forKey: "port")
	}
	
	required convenience init?(coder aDecoder: NSCoder) {
		guard let server = aDecoder.decodeObject(forKey: "server") as? String,
			let user = aDecoder.decodeObject(forKey: "user") as? String,
			let password = aDecoder.decodeObject(forKey: "password") as? String else {
				print("Could not load mqtt info")
				return nil
		}
		let port = aDecoder.decodeInt32(forKey: "port")
		
		self.init(server: server, user: user, password: password, port: Int(port))
	}
	
	init(server: String, user: String, password: String, port: Int) {
		self.server = server
		self.user = user
		self.password = password
		self.port = port
	}
	
	let server: String
	let user: String
	let password: String
	let port: Int
}
