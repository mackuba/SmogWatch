//
//  StationListController.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 13.06.2020.
//  Copyright © 2020 Kuba Suder. Licensed under WTFPL license.
//

import WatchKit

struct StationListContext {
    let items: [Station]
    let selectedId: Int?
    let userLocation: CLLocation?
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

        let rowType = (context.userLocation == nil) ? "BasicListRow" : "ListRowWithDistance"
        table.setNumberOfRows(items.count, withRowType: rowType)

        for i in 0..<items.count {
            let row = listRowController(at: i)
            row.setTitle(items[i].name)

            if let location = context.userLocation {
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

    func listRowController(at index: Int) -> StationListRow {
        return table.rowController(at: index) as! StationListRow
    }
}
