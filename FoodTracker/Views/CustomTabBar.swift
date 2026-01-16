//
//  CustomTabBar.swift
//  FoodTracker
//
//  Created by Francesco Balestrieri on 11.1.2026.
//

import SwiftUI

enum MealEntryOption {
    case camera
    case voice
    case text
}

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let onMealEntry: (MealEntryOption) -> Void

    @State private var showingEntryOptions = false

    var body: some View {
        HStack {
            // Meals tab
            TabBarButton(
                icon: "fork.knife",
                label: "Meals",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }

            Spacer()

            // Center add button
            Button(action: { showingEntryOptions = true }) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 4, y: 2)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -16)
            .confirmationDialog("Log a meal", isPresented: $showingEntryOptions) {
                Button("Take Photo") {
                    onMealEntry(.camera)
                }
                Button("Voice") {
                    onMealEntry(.voice)
                }
                Button("Type") {
                    onMealEntry(.text)
                }
                Button("Cancel", role: .cancel) {}
            }

            Spacer()

            // Stats tab
            TabBarButton(
                icon: "chart.bar",
                label: "Stats",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
        }
        .padding(.horizontal, 32)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Rectangle()
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                Text(label)
                    .font(.caption2)
            }
            .foregroundColor(isSelected ? .accentColor : .gray)
            .frame(minWidth: 60)
        }
    }
}

#Preview {
    VStack {
        Spacer()
        CustomTabBar(selectedTab: .constant(0), onMealEntry: { _ in })
    }
}
