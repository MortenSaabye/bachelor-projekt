//
//  AddMQTTVC.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 03/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit

class AddMQTTVC: UIViewController, MqttCredDelegate, UITextFieldDelegate {
	@IBOutlet weak var serverTextField: UITextField!
	@IBOutlet weak var userTextfield: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	@IBOutlet weak var portTextField: UITextField!
	override func viewDidLoad() {
        super.viewDidLoad()
		self.title = "Add MQTT credentials"
        // Do any additional setup after loading the view.
		let closeBtn = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(self.dismissView))
		self.navigationItem.rightBarButtonItem = closeBtn
		self.serverTextField.delegate = self
		self.userTextfield.delegate = self
		self.passwordTextField.delegate = self
		self.portTextField.delegate = self
		
		if let mqttserver = MQTTManager.shared.server {
			self.serverTextField.text = mqttserver.server
			self.userTextfield.text = mqttserver.user
			self.passwordTextField.text = mqttserver.password
			self.portTextField.text = String(mqttserver.port)
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@IBAction func submitAction(_ sender: Any) {
		guard let server = serverTextField.text, let user = userTextfield.text, let password = passwordTextField.text, let portString = portTextField.text, let port = Int(portString) else {
			print("Not all values present")
			return
		}
		MQTTManager.shared.delegate = self
		let serverInfo = MQTTServer(server: server, user: user, password: password, port: Int(port))
		MQTTManager.shared.sendMQTTCreds(server: serverInfo)
		MQTTManager.shared.saveMQTTInfo(server: serverInfo)
	}
	
	@objc func dismissView() {
		self.dismiss(animated: true, completion: nil)
	}
	
	func addedMQTTCreds(sender: MQTTManager, success: Bool, done: Bool) {
		if success && done {
			self.dismissView()
		} else if success && !done {
			print("Added one")
		} else {
			print("Somthing went wrong")
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}
