//
//  MQTTManager.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 03/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import Foundation
import Alamofire
import CocoaMQTT

protocol MqttCredDelegate {
	func addedMQTTCreds(sender: MQTTManager, success: Bool, done: Bool)
}

class MQTTManager {
	var delegate: MqttCredDelegate?
	static let shared: MQTTManager = MQTTManager()
	let MQTT_INFO_PATH: String = "MQTTserver"
	var server: MQTTServer?
	var client: CocoaMQTT?
	
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
		if !WiFiManager.shared.isAtHome {
			if let mqttServer = self.server {
				let clientID = "CocoaMQTT-" + String(ProcessInfo().processIdentifier)
				self.client = CocoaMQTT(clientID: clientID, host: mqttServer.server, port: UInt16(mqttServer.port))
				self.client?.delegate = self
				self.client?.username = mqttServer.user
				self.client?.password = mqttServer.password
				self.client?.keepAlive = 60
				self.client?.allowUntrustCACertificate = true
				self.client?.enableSSL = true
				self.client?.connect()
			}

		}
	}
	
	func subscribeToLocalDevices() {
		for device in DeviceManager.shared.devices {
			self.client?.subscribe(String(device.id))
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
	
	func sendMessage(device: Device) {
		var payload = [String: Any]()
		var newState = [String: Any]()
		newState["isOn"] = !device.isOn
		newState["state"] = device.state
		payload["\(device.id)"] = newState
		self.client?.publish(String(device.id), withString: "\(payload)", qos: .qos2)
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

extension MQTTManager : CocoaMQTTDelegate {
	func mqtt(_ mqtt: CocoaMQTT, didConnect host: String, port: Int) {
		print("mqtt did connect")
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
		print("mqtt did connect")
		self.subscribeToLocalDevices()
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
		print("mqtt did publish message")
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
		print("mqtt did publish ack")

	}
	
	func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
		print("mqtt did receive message")

	}
	
	func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
		completionHandler(true)
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
		print("mqtt did subscribe")

	}
	
	func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
		print("mqtt did unsubscribe ")
	}
	
	func mqttDidPing(_ mqtt: CocoaMQTT) {
		print("mqtt did ping")
	}
	
	func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
		print("mqtt did receive ping")

	}
	
	func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
		print("mqtt did disconnect \(err)")
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
