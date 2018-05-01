//
//  CoAPManager.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 01/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import Foundation

protocol CoAPManagerDelegate {
	var service: NetService? { get }
	func didReceiveResponse(message: SCMessage)
}

class CoAPManager: SCClientDelegate {
	var delegate: CoAPManagerDelegate?
	var client: SCClient!

	func startClient() {
		self.client = SCClient(delegate: self)
	}
	static let shared: CoAPManager = CoAPManager()
	
	func swiftCoapClient(_ client: SCClient, didReceiveMessage message: SCMessage) {
		self.delegate?.didReceiveResponse(message: message)
	}
	
	func swiftCoapClient(_ client: SCClient, didFailWithError error: NSError) {
		print(error.localizedDescription)
	}
	
	func swiftCoapClient(_ client: SCClient, didSendMessage message: SCMessage, number: Int) {
		print("Message sent to: \(message.hostName ?? "no one")")
	}
	
	func fetchDevicesFromService() {
		guard let service = self.delegate?.service, let hostname = service.hostName else {
			print("No service or hostname")
			return
		}
		let message = SCMessage(code: .init(rawValue: 1), type: .confirmable, payload: nil)
		if let urlData = "devices".data(using: .utf8) {
			message.addOption(SCOption.uriPath.rawValue, data: urlData)
			client.sendCoAPMessage(message, hostName: hostname, port: UInt16(service.port))
		}
	}
	
	func testDevice(device: Device) {
		let message = SCMessage(code: .init(rawValue: 1), type: .confirmable, payload: nil)
		if let deviceUrl = device.resourcePath.data(using: .utf8),
			let testUrl = "test".data(using: .utf8),
			let service = self.delegate?.service,
			let hostname = service.hostName {
				message.addOption(SCOption.uriPath.rawValue, data: deviceUrl)
				message.addOption(SCOption.uriPath.rawValue, data: testUrl)
				client.sendCoAPMessage(message, hostName: hostname, port: UInt16(service.port))
		}
	}
	
}
