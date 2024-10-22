//
//  ActiveCalorieWidget.swift
//  Simple Mind
//
//  Created by Eli on 10/18/24.
//
import WidgetKit
import SwiftUI
import HealthKit


struct ActiveCaloriesWidgetEntryView: View {
    var entry: HealthEntry
    private let goal = 750.0
    

    var body: some View {
        ZStack {
            // Calculate the percentage of steps taken
            let percentage = min(Double(entry.activeCalories) / goal, 1.0) // Cap at 1.0

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
                Text("Active Calories")
                    .font(.headline)
                    .foregroundColor(.white)
                    .containerBackground(for: .widget) {
                        gradient
                    }
                Text("\(entry.activeCalories)")
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


struct ActiveCaloriesWidget: Widget {
    let kind: String = "ActiveCaloriesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthProvider()) { entry in
            ActiveCaloriesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Active Calories Tracker")
        .description("Track your active calories burned.")
        .supportedFamilies([.systemSmall])
    }
}

