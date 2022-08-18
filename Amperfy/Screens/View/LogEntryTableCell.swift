//
//  LogEntryTableCell.swift
//  Amperfy
//
//  Created by Maximilian Bauer on 16.05.21.
//  Copyright (c) 2021 Maximilian Bauer. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit
import AmperfyKit

class LogEntryTableCell: BasicTableCell {
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    static let rowHeight: CGFloat = 48.0 + margin.bottom + margin.top
    
    func display(entry: LogEntry) {
        messageLabel.text = entry.message
        var typeLabelText = "\(entry.type.description)"
        if entry.type == .error {
            typeLabelText += " \(CommonString.oneMiddleDot) Status code \(entry.statusCode)"
        }
        typeLabel.text = typeLabelText
        dateLabel.text = "\(entry.creationDate)"
    }

}
