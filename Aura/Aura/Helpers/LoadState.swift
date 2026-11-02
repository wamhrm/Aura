//
//  LoadState.swift
//  Aura
//
//  Created by wamhrm on 03.11.2026.
//

import Foundation

enum LoadState: Equatable {
    case loading, loaded
    case failed(String)
}
