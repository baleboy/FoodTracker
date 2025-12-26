//
//  ContentView.swift
//  FoodTracker
//
//  Created by Francesco Balestrieri on 21.12.2025.
//

import SwiftUI
import SwiftData
import PhotosUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @Query(sort: \Meal.timestamp, order: .reverse) private var meals: [Meal]
    @State private var showingSettings = false
    @State private var showingPhotoCapture = false
    @State private var showingCamera = false
    @State private var selectedTab = 0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var cameraImageData: Data?

    private var lastMealTimestamp: Date? {
        meals.first?.timestamp
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                VStack(spacing: 0) {
                    FastingTimerView(lastMealTimestamp: lastMealTimestamp)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGroupedBackground))

                    MealListView()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: { showingSettings = true }) {
                            Label("Settings", systemImage: "gear")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        HStack(spacing: 16) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Label("Gallery", systemImage: "photo.on.rectangle")
                            }

                            Button {
                                showingCamera = true
                            } label: {
                                Label("Camera", systemImage: "camera")
                            }
                        }
                    }
                }
                .navigationDestination(for: Meal.self) { meal in
                    MealDetailView(meal: meal)
                }
            }
            .tabItem {
                Label("Meals", systemImage: "fork.knife")
            }
            .tag(0)

            NavigationStack {
                StatsView()
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button(action: { showingSettings = true }) {
                                Label("Settings", systemImage: "gear")
                            }
                        }
                    }
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }
            .tag(1)
        }
        .sheet(isPresented: $showingPhotoCapture, onDismiss: {
            selectedPhotoData = nil
        }) {
            PhotoCaptureView(initialImageData: selectedPhotoData)
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(imageData: $cameraImageData)
                .ignoresSafeArea()
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self) {
                    selectedPhotoData = data
                    selectedPhotoItem = nil
                    showingPhotoCapture = true
                }
            }
        }
        .onChange(of: cameraImageData) { _, newData in
            if let data = newData {
                selectedPhotoData = data
                cameraImageData = nil
                showingPhotoCapture = true
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
            }
        }
        .onChange(of: appState.shouldOpenCameraDirectly) { _, shouldOpen in
            if shouldOpen {
                showingCamera = true
                appState.shouldOpenCameraDirectly = false
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
        .modelContainer(for: Meal.self, inMemory: true)
}
