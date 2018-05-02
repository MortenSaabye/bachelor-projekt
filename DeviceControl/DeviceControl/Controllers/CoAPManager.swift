//
//  CoAPManager.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 01/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import Foundation

protocol CoAPManagerDelegate {
	func didReceiveResponse(payload: [String : Any]?)
}

class CoAPManager: SCClientDelegate {
	var delegate: CoAPManagerDelegate?
	var client: SCClient!

	func startClient() {
		self.client = SCClient(delegate: self)
	}
	static let shared: CoAPManager = CoAPManager()
	
	func swiftCoapClient(_ client: SCClient, didReceiveMessage message: SCMessage) {
		print("received message in manager")
		var jsonDict: [String: Any]?
		if let pay = message.payload {
			do {
				jsonDict = try JSONSerialization.jsonObject(with: pay, options: .allowFragments) as? [String : Any]
			} catch {
				print(String(data: pay, encoding: .utf8) ?? error.localizedDescription)
			}
		}
		self.delegate?.didReceiveResponse(payload: jsonDict)
	}
	
	func swiftCoapClient(_ client: SCClient, didFailWithError error: NSError) {
		print(error.localizedDescription)
	}
	
	func swiftCoapClient(_ client: SCClient, didSendMessage message: SCMessage, number: Int) {
		print("Message sent to: \(message.hostName ?? "no one")")
	}
	
	func fetchDevicesFromService(service: NetService) {
		guard let hostname = service.hostName else {
			print("No hostname")
			return
		}
		let message = SCMessage(code: .init(rawValue: 1), type: .confirmable, payload: nil)
		if let urlData = "devices".data(using: .utf8) {
			message.addOption(SCOption.uriPath.rawValue, data: urlData)
			client.sendCoAPMessage(message, hostName: hostname, port: UInt16(service.port))
		}
	}
	
	func checkStateForLocalDevices() {
		for device in DeviceManager.shared.devices {
			self.deviceGet(device: device, pathComponent: "state")
		}
	}
	
	func deviceGet(device: Device, pathComponent: String) {
		let message = SCMessage(code: SCCodeValue(classValue: 0, detailValue: 01)!, type: .confirmable, payload: nil)
		if let deviceUrl = String(device.id).data(using: .utf8),
			let pathData = pathComponent.data(using: .utf8) {
				let hostname = device.hostname
				message.addOption(SCOption.uriPath.rawValue, data: deviceUrl)
				message.addOption(SCOption.uriPath.rawValue, data: pathData)
				client.sendCoAPMessage(message, hostName: hostname, port: UInt16(device.port))
		}
	}
	
	func devicePut(device: Device, pathComponent: String, payload: Data) {
		let message = SCMessage(code: SCCodeValue(classValue: 0, detailValue: 03)!, type: .confirmable, payload: payload)
		if let deviceUrl = String(device.id).data(using: .utf8),
			let pathData = pathComponent.data(using: .utf8) {
			let hostname = device.hostname
			message.addOption(SCOption.uriPath.rawValue, data: deviceUrl)
			message.addOption(SCOption.uriPath.rawValue, data: pathData)
			client.sendCoAPMessage(message, hostName: hostname, port: UInt16(device.port))
		}
	}
	
}
