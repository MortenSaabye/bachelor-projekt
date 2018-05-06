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

class MQTTManager : MessageManager {
	var credDelegate: MqttCredDelegate?
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
				self.client?.willMessage = CocoaMQTTWill(topic: "/will", message: "dieout")
				self.client?.connect()
			}

		}
	}
	
	func subscribeToLocalDevices() {
		for device in DeviceManager.shared.devices {
			self.client?.subscribe("\(String(device.id))/listen")
		}
	}
	
	func sendMQTTCreds(user: String, password: String){
		let parameters: Parameters = [
			"username" : user,
			"password" : password
		]
		let hosts = DeviceManager.shared.getListOfHosts()
		var success: Bool = false
		var done: Bool = false
		var hostCount = 0
		for host in hosts {
			Alamofire.request("http://\(host.hostName):3000/addmqtt", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { (response) in
				guard let jsonString = response.result.value as? String,
				let JSONValue = self.convertToDictionary(text: jsonString),
				let reqSuccess = JSONValue["success"] as? Bool,
				let serverDict = JSONValue["server"] as? [String : Any] else {
					print("Could not get JSON")
					return
				}
				if reqSuccess {
					success = true
				}
				
				if let serverInfo = MQTTServer(dict: serverDict) {
					self.saveMQTTInfo(server: serverInfo)
				}
				
				hostCount += 1
				if hostCount >= hosts.count {
					done = true
				}
				self.credDelegate?.addedMQTTCreds(sender: self, success: success, done: done)
			}
		}
	}
	
	func convertToDictionary(text: String) -> [String: Any]? {
		if let data = text.data(using: .utf8) {
			do {
				return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
			} catch {
				print(error.localizedDescription)
			}
		}
		return nil
	}
	
	override func sendMessage(with payload: [String : Any], to host: Host, path pathComponent: String) {
		guard let data = self.getJSONDataFrom(dict: payload) else {
			print("Could not get data MQTT")
			return
		}
		let message = CocoaMQTTMessage(topic: pathComponent, payload: [UInt8](data))
		self.client?.publish(message)
	}
	
	override func sendMessage(with payload: Any, to host: Host, path pathComponent: String) {
		if let data = "\(payload)".data(using: .utf8) {
			let message = CocoaMQTTMessage(topic: pathComponent, payload: [UInt8](data))
			self.client?.publish(message)
		}
	}
	
	override func sendMessage(to host: Host, path pathComponent: String) {
		let message = CocoaMQTTMessage(topic: pathComponent, string: "")
		self.client?.publish(message)
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
		print("mqtt did connect ack")
		if ack == .accept {
			self.subscribeToLocalDevices()
			self.client?.subscribe("state/listen")
			self.delegate?.clientDidConnect(sender: self)
		}
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
		print("mqtt did publish message \(message.topic) \(message.payload)")
		
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
		print("mqtt did publish ack \(id)")

	}
	
	func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16) {
		print("mqtt did receive message")
		self.parseDataAndNotifyDelegate(payload: Data(message.payload))
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
		print("mqtt did subscribe")

	}
	
	func mqtt(_ mqtt: CocoaMQTT, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
		completionHandler(true)
	}
	
	func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
		print("mqtt did unsubscribe ")
	}
	
	func mqttDidPing(_ mqtt: CocoaMQTT) {
		print("mqtt did ping")
	}
	
	func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
		print("mqtt did receive pong")

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
	
	convenience init?(dict: [String : Any]) {
		guard let server = dict["server"] as? String,
		let port = dict["port"] as? Int,
		let user = dict["user"] as? String,
		let password = dict["password"] as? String else {
			print("Not all values present for MQTTServer")
			return nil
		}
		self.init(server: server, user: user, password: password, port: port)

	}
	
	let server: String
	let user: String
	let password: String
	let port: Int
}
