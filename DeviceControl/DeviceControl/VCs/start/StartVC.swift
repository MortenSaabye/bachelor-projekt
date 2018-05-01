//
//  StartVC.swift
//  Device Control
//
//  Created by Morten Saabye on 4/23/18.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit

class StartVC: UIViewController  {
	var devices = [Device]()
	@IBOutlet weak var deviceCollectionView: UICollectionView!
	let LOCALDEVICES_FILENAME: String = "local-devices"
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
		self.loadDevices()
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
	
//	MARK: Read and write devices
	func loadDevices() {
		guard let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
			print("Could not get path")
			return
		}
		let fileURL = dir.appendingPathComponent(self.LOCALDEVICES_FILENAME)

		guard let devices = NSKeyedUnarchiver.unarchiveObject(withFile: fileURL.absoluteString) as? [Device] else {
			print("Could not find local devices")
			return
		}
		self.devices = devices
	}
}

extension StartVC: UICollectionViewDataSource, UICollectionViewDelegate {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.devices.count
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		return collectionView.dequeueReusableCell(withReuseIdentifier: DEVICE_CELL_IDENTIFIER, for: indexPath)
	}
	
}




class Device : NSObject, NSCoding {
	init(type: String, resourcePath: String, name: String) {
		self.name = name
		self.resourcePath = resourcePath
		self.type = DeviceType.typeFromString(string: type)
	}
	
	convenience init?(dict: [String: Any]) {
		guard let typestring = dict["type"] as? String,
			let name = dict["name"] as? String,
			let resourcePath = dict["path"] as? String else {
				print("Not all values present")
				return nil
		}
		self.init(type: typestring, resourcePath: resourcePath, name: name)
	}
	
	func encode(with aCoder: NSCoder) {
		aCoder.encode(self.type.stringRepresentation(), forKey: "type")
		aCoder.encode(self.resourcePath, forKey: "path")
		aCoder.encode(self.name, forKey: "name")
	}
	
	required convenience init?(coder aDecoder: NSCoder) {
		guard let typestring = aDecoder.decodeObject(forKey: "type") as? String,
			let resourcePath = aDecoder.decodeObject(forKey: "path") as? String,
			let name = aDecoder.decodeObject(forKey: "name") as? String else {
				return nil
		}
		self.init(type: typestring, resourcePath: resourcePath, name: name)
	}
	
	let type: DeviceType
	let resourcePath: String
	var name: String
}

enum DeviceType {
	case Light
	case Screen
	case Other
	
	static func typeFromString(string: String) -> DeviceType {
		switch string {
		case "light":
			return self.Light
		case "screen":
			return self.Screen
		default:
			return self.Other
		}
	}
	
	func getIcon() -> UIImage {
		switch self {
		case .Light:
			return #imageLiteral(resourceName: "light")
		case .Screen:
			return #imageLiteral(resourceName: "screen")
		default:
			return #imageLiteral(resourceName: "other")
		}
	}
	
	func stringRepresentation() -> String {
		switch self {
		case .Light:
			return "light"
		case .Screen:
			return "screen"
		default:
			return "other"
		}
	}
	
}

