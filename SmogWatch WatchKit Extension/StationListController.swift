//
//  StationListController.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 09.09.2020.
//  Copyright © 2020 Kuba Suder. Licensed under WTFPL license.
//

import WatchKit
import Foundation

struct StationListContext {
    let items: [Station]
    let selectedId: Int?
    let onSelect: ((Station) -> ())
}

class StationListController: WKInterfaceController {

    @IBOutlet weak var table: WKInterfaceTable!

    var selectedRowIndex: Int? = nil
    var items: [Station] = []
    var selectionHandler: ((Station) -> ())?

    override func awake(withContext context: Any?) {
        let context = context as! StationListContext

        items = context.items
        selectionHandler = context.onSelect

        table.setNumberOfRows(items.count, withRowType: "BasicListRow")

        for i in 0..<items.count {
            listRowController(at: i).showStation(items[i])
        }

        if context.selectedId != nil {
            if let index = items.firstIndex(where: { $0.channelId == context.selectedId }) {
                listRowController(at: index).setCheckmarkVisible(true)
                selectedRowIndex = index
            }
        }
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if let previous = selectedRowIndex, previous != rowIndex {
            listRowController(at: previous).setCheckmarkVisible(false)
        }

        listRowController(at: rowIndex).setCheckmarkVisible(true)
        selectedRowIndex = rowIndex

        selectionHandler?(items[rowIndex])
    }

    func listRowController(at index: Int) -> StationListRow {
        return table.rowController(at: index) as! StationListRow
    }
}
