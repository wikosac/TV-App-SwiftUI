//
//  TV_AppApp.swift
//  TV App
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import SwiftUI

@main
struct TV_AppApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ShowListView()
            }
        }
    }
}
