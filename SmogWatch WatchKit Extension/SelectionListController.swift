//
//  SelectionListController.swift
//  SmogWatch WatchKit Extension
//
//  Created by Kuba Suder on 13.06.2020.
//  Copyright © 2020 Kuba Suder. Licensed under WTFPL license.
//

import WatchKit

struct SelectionListContext {
    let items: [SelectableItem]
    let selectedId: Int?
    let title: String
    let onSelect: ((Int) -> ())
}

class SelectionListController: WKInterfaceController {
    @IBOutlet weak var table: WKInterfaceTable!

    var selectedRowIndex: Int? = nil
    var items: [SelectableItem] = []
    var selectionHandler: ((Int) -> ())?

    override func awake(withContext context: Any?) {
        super.awake(withContext: context)

        let context = context as! SelectionListContext
        items = context.items
        setTitle(context.title)
        selectionHandler = context.onSelect

        table.setNumberOfRows(items.count, withRowType: "SelectionListRow")

        for i in 0..<items.count {
            let row = table.rowController(at: i) as! SelectionListRow
            row.setTitle(items[i].name)
        }

        if context.selectedId != nil, let index = items.firstIndex(where: { $0.id == context.selectedId }) {
            selectedRowIndex = index
            listRowController(at: index).setCheckmarkVisible(true)
        }
    }

    override func table(_ table: WKInterfaceTable, didSelectRowAt rowIndex: Int) {
        if let previous = selectedRowIndex, previous != rowIndex {
            listRowController(at: previous).setCheckmarkVisible(false)
        }

        listRowController(at: rowIndex).setCheckmarkVisible(true)
        selectedRowIndex = rowIndex

        selectionHandler?(items[rowIndex].id)
    }

    func listRowController(at index: Int) -> SelectionListRow {
        return table.rowController(at: index) as! SelectionListRow
    }
}
