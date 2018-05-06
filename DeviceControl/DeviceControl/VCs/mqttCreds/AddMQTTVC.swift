//
//  AddMQTTVC.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 03/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit

class AddMQTTVC: UIViewController, MqttCredDelegate, UITextFieldDelegate {
	@IBOutlet weak var userTextfield: UITextField!
	@IBOutlet weak var passwordTextField: UITextField!
	override func viewDidLoad() {
        super.viewDidLoad()
		self.title = "Add MQTT credentials"
        // Do any additional setup after loading the view.
		let closeBtn = UIBarButtonItem(title: "Close", style: .done, target: self, action: #selector(self.dismissView))
		self.navigationItem.rightBarButtonItem = closeBtn
		self.userTextfield.delegate = self
		self.passwordTextField.delegate = self
		
		if let mqttserver = MQTTManager.shared.server {
			self.userTextfield.text = mqttserver.user
			self.passwordTextField.text = mqttserver.password
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
	@IBAction func submitAction(_ sender: Any) {
		guard let user = userTextfield.text, let password = passwordTextField.text else {
			print("Not all values present")
			return
		}
		MQTTManager.shared.credDelegate = self
		MQTTManager.shared.sendMQTTCreds(user: user, password: password)
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
