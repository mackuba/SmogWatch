//
//  SelectionListController.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 13.06.2020.
//  Copyright © 2020 Kuba Suder. Licensed under WTFPL license.
//

import WatchKit

struct SelectionListContext {
    let items: [Station]
    let selectedId: Int?
    let userLocation: CLLocation?
    let onSelect: ((Station) -> ())
}

class SelectionListController: WKInterfaceController {
    @IBOutlet weak var table: WKInterfaceTable!

    var selectedRowIndex: Int? = nil
    var items: [Station] = []
    var selectionHandler: ((Station) -> ())?
    var userLocation: CLLocation?

    override func awake(withContext context: Any?) {
        let context = context as! SelectionListContext

        items = context.items
        selectionHandler = context.onSelect
        userLocation = context.userLocation

        let rowType = (userLocation == nil) ? "BasicListRow" : "ListRowWithDistance"
        table.setNumberOfRows(items.count, withRowType: rowType)

        for i in 0..<items.count {
            let row = table.rowController(at: i) as! SelectionListRow
            row.setTitle(items[i].name)

            if let location = userLocation {
                let itemLocation = CLLocation(latitude: items[i].lat, longitude: items[i].lng)
                row.setDistance(location.distance(from: itemLocation))
            }
        }

        if context.selectedId != nil {
            if let index = items.firstIndex(where: { $0.channelId == context.selectedId }) {
                selectedRowIndex = index
                listRowController(at: index).setCheckmarkVisible(true)
            }
        }
    }

    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if let previous = selectedRowIndex, previous != rowIndex {
            listRowController(at: previous).setCheckmarkVisible(false)
        }

        listRowController(at: rowIndex).setCheckmarkVisible(true)
        selectedRowIndex = rowIndex

        selectionHandler?(items[rowIndex])
    }

    func listRowController(at index: Int) -> SelectionListRow {
        return table.rowController(at: index) as! SelectionListRow
    }
}
