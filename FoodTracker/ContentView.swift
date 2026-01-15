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
    @Query(sort: \Meal.timestamp, order: .reverse) private var meals: [Meal]
    @State private var showingSettings = false
    @State private var showingPhotoCapture = false
    @State private var showingCamera = false
    @State private var showingTextEntry = false
    @State private var selectedTab = 0
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var cameraImageData: Data?


    var body: some View {
        VStack(spacing: 0) {
            // Content area
            Group {
                if selectedTab == 0 {
                    NavigationStack {
                        VStack(spacing: 0) {
                            FastingTimerView()
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
                                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                    Label("Gallery", systemImage: "photo.on.rectangle")
                                }
                            }
                        }
                        .navigationDestination(for: Meal.self) { meal in
                            MealDetailView(meal: meal)
                        }
                    }
                } else {
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
                }
            }

            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab) { option in
                switch option {
                case .camera:
                    showingCamera = true
                case .text:
                    showingTextEntry = true
                }
            }
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
        .sheet(isPresented: $showingTextEntry) {
            TextMealEntryView()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Meal.self, inMemory: true)
}
