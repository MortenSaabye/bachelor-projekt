//
//  StartVC.swift
//  Device Control
//
//  Created by Morten Saabye on 4/23/18.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit

class StartVC: UIViewController  {
	@IBOutlet weak var deviceCollectionView: UICollectionView!
	let DEVICE_CELL_IDENTIFIER: String = "DEVICE_CELL"
	let FOOTER_VIEW_IDENTIFIER: String = "FooterView"
	override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Device Control"
        // Do any additional setup after loading the view.
        let setupBtn: UIBarButtonItem = UIBarButtonItem(title: "Setup", style: .plain, target: self, action: #selector(self.launchSetup))
        self.navigationItem.rightBarButtonItem = setupBtn
        let allServiceBtn: UIBarButtonItem = UIBarButtonItem(title: "Add device", style: .plain, target: self, action: #selector(self.addDevice))
        self.navigationItem.leftBarButtonItem = allServiceBtn
		self.deviceCollectionView.register(UINib(nibName: "DeviceCell", bundle: nil), forCellWithReuseIdentifier: DEVICE_CELL_IDENTIFIER)
		self.deviceCollectionView.register(UINib(nibName: "FooterView", bundle: nil), forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: FOOTER_VIEW_IDENTIFIER)
		self.deviceCollectionView.delegate = self
		self.deviceCollectionView.dataSource = self
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		DeviceManager.shared.delegate = self
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
}

extension StartVC: DeviceManagerDelegate {
	func didUpdateDevice(device: Device, index: Int, sender: DeviceManager) {
		let indexPath = IndexPath(item: index, section: 0)
		self.deviceCollectionView.reloadItems(at: [indexPath])
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
		let device = DeviceManager.shared.devices[indexPath.row]
		let width = self.view.frame.width - 30
		let height: CGFloat
		if device.type == .Screen {
			height = 200
		} else {
			height = 150
		}
		return CGSize(width: width, height: height)
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let device = DeviceManager.shared.devices[indexPath.row]
		DeviceManager.shared.updateStateFor(device: device)
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


