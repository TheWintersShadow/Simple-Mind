//
//  DietaryCalorieWidget.swift
//  Simple Mind
//
//  Created by Eli on 10/18/24.
//
import WidgetKit
import SwiftUI
import HealthKit


struct DietaryCaloriesWidgetEntryView: View {
    var entry: HealthEntry
    private let goal = 2000.0

    var body: some View {
        ZStack {
            // Calculate the percentage of steps taken
            let percentage = min(Double(entry.dietaryCalories) / goal, 1.0) // Cap at 1.0

            // Create a gradient from red to green
            let gradient = LinearGradient(
                gradient: Gradient(stops: [
                    .init(color: .red, location: 0.0),    // Start with red
                    .init(color: .green, location: 1-percentage)   // End with green
                ]),
                startPoint: .top,
                endPoint: .bottom
            )

            VStack {
                Text("Dietary Calories")
                    .font(.headline)
                    .foregroundColor(.white)
                    .containerBackground(for: .widget) {
                        gradient
                    }
                Text("\(entry.dietaryCalories)")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .containerBackground(for: .widget) {
                        gradient
                    }
            }
            .padding(0)
        }
    }
}

struct DietaryCaloriesWidget: Widget {
    let kind: String = "DietaryCaloriesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthProvider()) { entry in
            DietaryCaloriesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Dietary Calories Tracker")
        .description("Track your dietary calories consumed.")
        .supportedFamilies([.systemSmall])
    }
}
