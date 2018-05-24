//
//  StartVC.swift
//  Device Control
//
//  Created by Morten Saabye on 4/23/18.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit
import LocalAuthentication

class StartVC: UIViewController  {
	@IBOutlet weak var deviceCollectionView: UICollectionView!
	@IBOutlet weak var messageView: UIView!
	let DEVICE_CELL_IDENTIFIER: String = "DEVICE_CELL"
	let FOOTER_VIEW_IDENTIFIER: String = "FooterView"
	override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Device Control"
        let setupBtn: UIBarButtonItem = UIBarButtonItem(title: "Setup", style: .plain, target: self, action: #selector(self.launchSetup))
        self.navigationItem.rightBarButtonItem = setupBtn
		let addDevices: UIBarButtonItem = UIBarButtonItem(title: "Add device", style: .plain, target: self, action: #selector(self.addDevice))
		self.navigationItem.leftBarButtonItem = addDevices
		self.deviceCollectionView.register(UINib(nibName: "DeviceCell", bundle: nil), forCellWithReuseIdentifier: DEVICE_CELL_IDENTIFIER)
		self.deviceCollectionView.register(UINib(nibName: "FooterView", bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: FOOTER_VIEW_IDENTIFIER)
		self.deviceCollectionView.delegate = self
		self.deviceCollectionView.dataSource = self
		if !WiFiManager.shared.isAtHome {
			self.authenticate()
		} else {
			DeviceManager.shared.startPolling()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		DeviceManager.shared.delegate = self
		if DeviceManager.shared.devices.count <= 0 {
			self.deviceCollectionView.isHidden = true
			self.messageView.isHidden = false
		} else {
			self.deviceCollectionView.isHidden = false
			self.messageView.isHidden = true
		}
		self.deviceCollectionView.reloadData()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		DeviceManager.shared.delegate = nil
		DeviceManager.shared.stopPolling()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
    @objc func launchSetup() {
        let setupVC = DeviceSetupVC()
		let navVC = UINavigationController(rootViewController: setupVC)
        self.present(navVC, animated: true)
    }
    
    @objc func addDevice() {
        let browseVC = ServiceBrowserTCV()
		let navVC = UINavigationController(rootViewController: browseVC)
        self.present(navVC, animated: true)
    }
}

extension StartVC: DeviceManagerDelegate {
	func messageWasDenied(sender: DeviceManager) {
		self.authenticate()
	}
	
	func authenticate() {
		if MQTTManager.shared.server == nil {
			let alert = UIAlertController(title: "No user", message: "You need to create a user to use Device Control remotely. Tap 'Manage remote control' to set up", preferredStyle: .alert)
			let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
			alert.addAction(okAction)
			self.present(alert, animated: true)
			return
		}
		let myContext = LAContext()
		var authError: NSError?
		
		let myReasonString = "You need to log in to use Device Control remotely"
		
		if myContext.canEvaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
			[myContext.evaluatePolicy(LAPolicy.deviceOwnerAuthenticationWithBiometrics, localizedReason: myReasonString, reply: { (success: Bool, evalPolicyError: Error?) in
				if success {
					MQTTManager.shared.logIn()
					MQTTManager.shared.loadServerInfo()
				} else {
					self.showPasswordBox()
				}
			})]
		} else{
			print(authError as Any)
		}
	}
	
	func showPasswordBox() {
		let pwAlert = UIAlertController(title: "Type your password", message: "", preferredStyle: .alert)
		pwAlert.addTextField(configurationHandler: { (textField) in
			textField.placeholder = "Password"
			textField.isSecureTextEntry = true
		})

		let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
			guard let textField = pwAlert.textFields?.first else {
				return
			}
			MQTTManager.shared.logIn(password: textField.text, result: {(success) in
				if success {
					MQTTManager.shared.loadServerInfo()
				} else {
					self.showPasswordBox()
				}
			})
		}
		let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
		pwAlert.addAction(okAction)
		pwAlert.addAction(cancelAction)
		self.present(pwAlert, animated: true)
	}
	
	func didRemoveDevice(at index: Int, sender: DeviceManager) {
		let indexPath = IndexPath(item: index, section: 0)
		self.deviceCollectionView.deleteItems(at: [indexPath])
		DeviceManager.shared.saveDevices()
	}
	
	func didUpdateDevice(device: Device, index: Int, sender: DeviceManager) {
		let indexPath = IndexPath(item: index, section: 0)
		self.deviceCollectionView.reloadItems(at: [indexPath])
	}
	
	func pollingDidTimeout(sender: DeviceManager) {
		self.deviceCollectionView.reloadData()
		let alert = UIAlertController(title: "An error occured", message: "Could not find the devices", preferredStyle: .alert)
		let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
		let reconnectAction = UIAlertAction(title: "Reconnect", style: .default) { (action) in
			MessageManager.reconnect()
		}
		alert.addAction(okAction)
		alert.addAction(reconnectAction)
		self.present(alert, animated: true)
	}

}

extension StartVC: DeviceCellDelegate {
	func willUpdateCell(sender: DeviceCell) {
		
	}
}

extension StartVC: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return DeviceManager.shared.devices.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: DEVICE_CELL_IDENTIFIER, for: indexPath) as? DeviceCell else {
			return UICollectionViewCell()
		}
		cell.setupCell(device: DeviceManager.shared.devices[indexPath.row])
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let width = self.view.frame.width - 30
		let height: CGFloat = 150

		return CGSize(width: width, height: height)
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let device = DeviceManager.shared.devices[indexPath.row]
		device.isUpdating = true
		DeviceManager.shared.toggle(device: device)
		self.deviceCollectionView.reloadItems(at: [indexPath])
	}
	
	func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		guard let footerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FOOTER_VIEW_IDENTIFIER, for: indexPath) as? FooterView else {
			print("Could not cast to FooterView")
			return UICollectionReusableView()
		}
		footerView.delegate = self
		return footerView
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
		return CGSize(width: self.view.frame.width - 30, height: 120)
	}
}

extension StartVC: FooterDelegate {
	func presentMQTTView(sender: FooterView) {
		let mqttVC = AddMQTTVC()
		let navVC = UINavigationController(rootViewController: mqttVC)
		self.present(navVC, animated: true, completion: nil)
	}
}


