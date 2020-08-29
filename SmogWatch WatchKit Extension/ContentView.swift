//
//  ContentView.swift
//  WeatherWatch WatchKit Extension
//
//  Created by Kuba Suder on 26.08.2020.
//  Copyright © 2020 Kuba Suder. All rights reserved.
//

import SwiftUI

let shortDateformatter: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .short
    f.timeStyle = .short
    return f
}()

struct ContentView: View {
    @State var sheetDisplayed = false

    var body: some View {
        List {
            NavigationLink(destination: LogList()) {
                Text("Show Logs")
            }

            Button(action: { self.sheetDisplayed = true }) {
                Text("Send Logs")
            }
        }
        .padding(.top, 5)
        .actionSheet(isPresented: $sheetDisplayed) {
            ActionSheet(
                title: Text("Send logs?"),
                message: nil,
                buttons: [
                    .default(Text("Send"), action: self.sendLogs),
                    .cancel({ self.sheetDisplayed = false })
                ]
            )
        }
    }

    func sendLogs() {
        let string = "logs=" + logStore.logs.map { log in
            "\(shortDateformatter.string(from: log.date)) \(log.message)\n"
        }.joined().addingPercentEncoding(withAllowedCharacters: .alphanumerics)!

        var request = URLRequest(url: URL(string: "https://mackuba.eu/watchlogs")!)
        request.httpMethod = "POST"
        request.httpBody = string.data(using: .utf8)!

        let task = URLSession.shared.dataTask(with: request)
        task.resume()
    }
}

struct LogList: View {
    @ObservedObject var store = logStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(store.logs.reversed(), id: \.date) { log in
                    VStack(alignment: .leading) {
                        Text("\(log.date, formatter: shortDateformatter)")
                            .font(.caption).bold()
                            .padding(.bottom, 2)
                        Text(log.message)
                            .font(.footnote)
                            .lineLimit(5)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.bottom, 4)
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ContentView()
            LogList()
        }
    }
}
