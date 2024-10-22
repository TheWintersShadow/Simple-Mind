//
//  StepsWidget.swift
//  Simple Mind
//
//  Created by Eli on 10/18/24.
//
import WidgetKit
import SwiftUI
import HealthKit


struct StepsWidgetEntryView: View {
    var entry: HealthEntry
    private let goal = 10000.0 // Goal for steps

    var body: some View {
        ZStack {
            // Calculate the percentage of steps taken
            let percentage = min(Double(entry.steps) / goal, 1.0) // Cap at 1.0

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
                Text("Steps")
                    .font(.headline)
                    .foregroundColor(.white)
                    .containerBackground(for: .widget) {
                        gradient
                    }
                Text("\(entry.steps)")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .containerBackground(for: .widget) {
                        gradient
                    }
            }
            .padding()
        }
    }
}

struct StepsWidget: Widget {
    let kind: String = "StepsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: HealthProvider()) { entry in
            StepsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Steps Tracker")
        .description("Track your steps.")
        .supportedFamilies([.systemSmall])
    }
}
