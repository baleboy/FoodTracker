//
//  AppState.swift
//  FoodTracker
//

import Foundation

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var isDirectCaptureMode = false

    private init() {}
}
