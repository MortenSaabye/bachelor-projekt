//
//  AddDevicesTVC.swift
//  DeviceControl
//
//  Created by Morten Saabye Kristensen on 01/05/2018.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit

class AddDevicesTVC: UITableViewController, CoAPManagerDelegate {
	var service: NetService?
	let LOCALDEVICES_FILENAME: String = "local-devices"
	let CELL_HEIGHT: CGFloat = 80
	var devices = [Device]() {
		didSet {
			self.tableView.reloadData()
		}
	}
	let ADD_DEVICE_CELL_IDENTIFIER: String = "ADD_DEVICE_CELL"
    override func viewDidLoad() {
        super.viewDidLoad()
		self.title = "Add devices"
		self.tableView.register(UINib(nibName: "AddDeviceCell", bundle: nil), forCellReuseIdentifier: ADD_DEVICE_CELL_IDENTIFIER)
		CoAPManager.shared.delegate = self
		CoAPManager.shared.fetchDevicesFromService()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return devices.count
    }
	
	override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
		
		let moreRowAction = UITableViewRowAction(style: .default, title: "Add to start", handler:{action, indexpath in
			let alert = UIAlertController(title: "Add \(self.devices[indexPath.row].name) to start?", message: "Provide a meaningful name to remember it by", preferredStyle: .alert)
			alert.addTextField(configurationHandler: { (textField) in
				textField.placeholder = "Name of device"
			})
			let addAction = UIAlertAction(title: "Add", style: .default, handler: { (action) in
				if let name = alert.textFields?.first?.text {
					let device = self.devices[indexPath.row]
					device.name = name
					self.saveDevice(device: device)
				}
			})
			
			let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
			
			alert.addAction(cancelAction)
			alert.addAction(addAction)
			
			
			self.present(alert, animated: true)
		})
		moreRowAction.backgroundColor = UIColor(red: 0.298, green: 0.851, blue: 0.3922, alpha: 1.0);
		
		return [moreRowAction]
	}
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: ADD_DEVICE_CELL_IDENTIFIER, for: indexPath) as? AddDeviceCell else {
			return UITableViewCell()
		}
		
		cell.device = devices[indexPath.row]
		
        return cell
    }
	override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return self.CELL_HEIGHT
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		return "Devices available on \(self.service?.hostName ?? "unknown hostname")"
	}
	
	func didReceiveResponse(message: SCMessage) {
		var jsonDict: [String: Any]?
		if let pay = message.payload {
			do {
				jsonDict = try JSONSerialization.jsonObject(with: pay, options: .allowFragments) as? [String : Any]
			} catch {
				print(String(data: pay, encoding: .utf8) ?? error.localizedDescription)
			}
		}
		if let obj = jsonDict, let arr = obj["devices"] as? [[String : Any]] {
			for obj in arr {
				if let device = Device(dict: obj) {
					self.devices.append(device)
				}
			}
		}
	}
	
	func saveDevice(device: Device) {
		if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
			let fileURL = dir.appendingPathComponent("\(self.LOCALDEVICES_FILENAME)/\(device.name)")
			NSKeyedArchiver.archiveRootObject(self.devices, toFile: fileURL.absoluteString)
		}
	}
	
}

