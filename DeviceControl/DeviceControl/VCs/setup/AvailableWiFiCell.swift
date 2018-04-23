//
//  AvailableWiFiCell.swift
//  Device Control
//
//  Created by Morten Saabye on 4/23/18.
//  Copyright © 2018 Morten Saabye. All rights reserved.
//

import UIKit

class AvailableWiFiCell: UITableViewCell {

    @IBOutlet weak var signalLabel: UILabel!
    @IBOutlet weak var SSIDlabel: UILabel!
    @IBOutlet weak var lockIcon: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
