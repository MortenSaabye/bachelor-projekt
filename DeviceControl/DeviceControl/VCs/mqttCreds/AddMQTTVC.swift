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
	@IBOutlet weak var submitButton: UIButton!
	@IBOutlet weak var spinner: UIActivityIndicatorView!
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
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
	}
	@IBAction func submitAction(_ sender: Any) {
		self.submitButton.isEnabled = false
		self.spinner.startAnimating()
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
			MQTTManager.shared.delegate = self
			MQTTManager.shared.loadServerInfo()
		} else if success && !done {
			print("Added one")
		} else {
			let alertVC = UIAlertController(title: "Error", message: "Could not contact the gatewat", preferredStyle: .alert)
			let okaction = UIAlertAction(title: "OK", style: .default, handler: nil)
			let tryagainAction = UIAlertAction(title: "Try again", style: .default) { (action) in
				self.submitAction(action)
			}
			alertVC.addAction(okaction)
			alertVC.addAction(tryagainAction)
			self.present(alertVC, animated: true)
			self.submitButton.isEnabled = true
			self.spinner.stopAnimating()
		}
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		textField.resignFirstResponder()
		return true
	}
}

extension AddMQTTVC: MessageManagerDelegate {
	func didReceiveMessage(message: [String : Any], sender: MessageManager) {
		print("messages should not received here.")
	}
	
	func clientDidConnect(sender: MessageManager) {
		self.dismissView()
	}
}
