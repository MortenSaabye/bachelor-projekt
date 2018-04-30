//
//  DeviceSetupVC.swift
//  Device Control
//
//  Created by Morten Saabye on 4/23/18.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit
import SystemConfiguration.CaptiveNetwork
import NetworkExtension
import Alamofire

class DeviceSetupVC: UIViewController, UITableViewDelegate, UITableViewDataSource, WiFiDelegate  {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var networkTableView: UITableView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var reloadNetworksBtn: UIButton!
    @IBOutlet weak var SSIDLabel: UILabel!
    @IBOutlet weak var passwordTextField: UITextField!
    let WIFI_CELL_IDENTIFIER: String = "WIFI_CELL"
    let CELL_HEIGHT: CGFloat = 50
    var networks: [WiFiNetwork]?
    var selectedNetwork: WiFiNetwork?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        WiFiManager.shared.getAvailableWifi()
        networkTableView.delegate = self
        networkTableView.dataSource = self
        self.networkTableView.register(UINib(nibName: "AvailableWiFiCell", bundle: nil), forCellReuseIdentifier: WIFI_CELL_IDENTIFIER)
        self.addSpinner()
    }

	@IBAction func cancelAction(_ sender: Any) {
		self.dismiss(animated: true, completion: nil)
	}
	
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WiFiManager.shared.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        WiFiManager.shared.delegate = nil
    }
    
    //MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let networks = self.networks {
            return networks.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: WIFI_CELL_IDENTIFIER) as? AvailableWiFiCell,
            let networks = self.networks else {
                print("Could not cast cell to correct type, or no networks")
                return UITableViewCell()
        }
        if indexPath.row > networks.count {
            print("out of bounds")
            return UITableViewCell()
        }
        let network = networks[indexPath.row]
        cell.SSIDlabel.text = network.ssid
        cell.lockIcon.image = network.isSecured ? #imageLiteral(resourceName: "locked") : #imageLiteral(resourceName: "unlocked")
        cell.signalLabel.text = network.signalStrength
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.CELL_HEIGHT
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let networks = self.networks else {
            print("No network at index")
            return
        }
        if indexPath.row > networks.count {
            print("out of bounds")
            return
        }
        self.selectedNetwork = networks[indexPath.row]
        self.SSIDLabel.text = selectedNetwork?.ssid
        self.scrollToPage(pageNumber: 3)
    }
    
    //    MARK: WifiDelegate
    
    func didReceiveNetworkInfo(sender: WiFiManager, networks: [WiFiNetwork]) {
        self.networks = networks
        self.removeSpinner()
        self.reloadNetworksBtn.isHidden = false
        self.networkTableView.reloadData()
    }
    
    func didConnectToNetwork(sender: WiFiManager, success: Bool, error: String?) {
        let alertVC: UIAlertController
        self.removeSpinner()
        let action: UIAlertAction
        if success {
            alertVC = UIAlertController(title: "Success", message: "Your device connected to the WiFi", preferredStyle: .alert)

            action = UIAlertAction(title: "OK", style: .default) { (_) in
                self.dismiss(animated: true)
            }
        } else {
            alertVC = UIAlertController(title: "Error", message: error, preferredStyle: .alert)
            action = UIAlertAction(title: "Oops", style: .destructive, handler: { (_) in
                self.scrollToPage(pageNumber: 2)
            })
        }
        
        alertVC.addAction(action)
        self.present(alertVC, animated: true)
    }
    
    @IBAction func reloadNetworks(_ sender: Any) {
        self.addSpinner()
        WiFiManager.shared.getAvailableWifi()
    }
    @IBAction func connectToNetwork(_ sender: Any) {
        self.selectedNetwork?.passcode = self.passwordTextField.text
        self.passwordTextField.resignFirstResponder()
        self.addSpinner()
        if let network = self.selectedNetwork {
            WiFiManager.shared.connectToWiFi(network: network)
        }
    }
    
    func scrollToPage(pageNumber: Int) {
        var frame: CGRect = self.scrollView.frame
        frame.origin.x = frame.size.width * CGFloat(pageNumber - 1)
        self.scrollView.scrollRectToVisible(frame, animated: true)
    }
    
    func addSpinner() {
        self.spinner.isHidden = false
        self.spinner.startAnimating()
    }
    
    func removeSpinner() {
        self.spinner.stopAnimating()
        self.spinner.isHidden = true
    }
}


