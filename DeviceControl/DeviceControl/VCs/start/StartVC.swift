//
//  StartVC.swift
//  Device Control
//
//  Created by Morten Saabye on 4/23/18.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit

class StartVC: UIViewController, CoAPManagerDelegate  {
	@IBOutlet weak var deviceCollectionView: UICollectionView!
	let DEVICE_CELL_IDENTIFIER: String = "DEVICE_CELL"
	override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Device Control"
        // Do any additional setup after loading the view.
        let setupBtn: UIBarButtonItem = UIBarButtonItem(title: "Setup", style: .plain, target: self, action: #selector(self.launchSetup))
        self.navigationItem.rightBarButtonItem = setupBtn
        let allServiceBtn: UIBarButtonItem = UIBarButtonItem(title: "Add device", style: .plain, target: self, action: #selector(self.addDevice))
        self.navigationItem.leftBarButtonItem = allServiceBtn
		self.deviceCollectionView.register(UINib(nibName: "DeviceCell", bundle: nil), forCellWithReuseIdentifier: DEVICE_CELL_IDENTIFIER)
		self.deviceCollectionView.delegate = self
		self.deviceCollectionView.dataSource = self
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		CoAPManager.shared.delegate = self
		CoAPManager.shared.checkStateForLocalDevices()
	}

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
	
    @objc func launchSetup() {
        let setupVC = DeviceSetupVC()
        self.present(setupVC, animated: true)
    }
    
    @objc func addDevice() {
        let browseVC = ServiceBrowserTCV()
		browseVC.serviceTypes = "_devicecontrol._udp"
		let navVC = UINavigationController(rootViewController: browseVC)
        self.present(navVC, animated: true)
    }
	
//	MARK: CoAPManagerDelegate
	
	func didReceiveResponse(payload: [String : Any]?) {
		print("received message")
		guard let states = payload?["result"] as? [[String : Any]] else {
			print("could not get device from dict")
			return
		}
		var indexToReload: Int = 0
		for state in states {
			for device in DeviceManager.shared.devices {
				if device.id == state["id"] as? Int {
					guard let isOn = state["isOn"] as? Bool,
						let state = state["state"] as? String else {
							print("Could not find all properties in state")
							return
					}
					device.isOn = isOn
					device.state = state
					device.isConnected = true
					let indexPath = IndexPath(item: indexToReload, section: 0)
					self.deviceCollectionView.reloadItems(at: [indexPath])
				}
				indexToReload += 1
			}
		}
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
		let height = CGFloat(150)
		return CGSize(width: width, height: height)
	}
	
}


