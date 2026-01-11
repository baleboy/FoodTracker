//
//  CustomTabBar.swift
//  FoodTracker
//
//  Created by Francesco Balestrieri on 11.1.2026.
//

import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let onCameraTap: () -> Void

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

            // Center camera button
            Button(action: onCameraTap) {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 56, height: 56)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 4, y: 2)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -16)

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
        CustomTabBar(selectedTab: .constant(0), onCameraTap: {})
    }
}
