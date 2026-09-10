//
//  ViewState.swift
//  TVApp
//
//  Created by Dwiko Indrawansyah on 10/09/26.
//

import Foundation

enum ViewState<T> {
    case loading
    case error(String)
    case success(T)
}
