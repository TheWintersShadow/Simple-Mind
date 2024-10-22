//
//  QuoteWidget.swift
//  Simple Mind
//
//  Created by Eli on 10/18/24.
//

import Foundation
import WidgetKit
import SwiftUI

struct QuoteResponse: Decodable {
    let q: String
    let a: String
    let h: String
}

struct Quote: Codable { // Conform to both Decodable and Encodable
    let text: String
    let author: String
    
    init(response: QuoteResponse) {
        self.text = response.q
        self.author = response.a
    }
    
    // You can implement the encode function if needed
    enum CodingKeys: String, CodingKey {
        case text = "q"
        case author = "a"
    }
}

struct QuoteEntry: TimelineEntry {
    let date: Date
    let quote: Quote?
}

struct QuoteProvider: TimelineProvider {
    private let userDefaultsKey = "lastFetchedQuoteDate"

    func placeholder(in context: Context) -> QuoteEntry {
        QuoteEntry(date: Date(), quote: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuoteEntry) -> Void) {
        let entry = QuoteEntry(date: Date(), quote: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuoteEntry>) -> Void) {
        let lastFetchedDate = UserDefaults(suiteName: "group.com.thegeekforge.simple-mind")?.string(forKey: userDefaultsKey)
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Check if the quote has already been fetched today
        if let lastFetchedDate = lastFetchedDate, let lastFetched = ISO8601DateFormatter().date(from: lastFetchedDate), calendar.isDate(lastFetched, inSameDayAs: today) {
            // If the quote is already fetched today, load it from UserDefaults
            if let cachedQuoteData = UserDefaults(suiteName: "group.com.thegeekforge.simple-mind")?.data(forKey: "cachedQuote"),
               let cachedQuote = try? JSONDecoder().decode(Quote.self, from: cachedQuoteData) {
                let entry = QuoteEntry(date: Date(), quote: cachedQuote)
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                completion(timeline)
                return
            }
        }

        // Otherwise, fetch a new quote
        fetchQuote { quote in
            if let quote = quote {
                // Save the quote and current date to UserDefaults
                let quoteData = try? JSONEncoder().encode(quote)
                UserDefaults(suiteName: "group.com.thegeekforge.simple-mind")?.set(quoteData, forKey: "cachedQuote")
                UserDefaults(suiteName: "group.com.thegeekforge.simple-mind")?.set(ISO8601DateFormatter().string(from: Date()), forKey: userDefaultsKey)

                let entry = QuoteEntry(date: Date(), quote: quote)
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                completion(timeline)
            } else {
                let entry = QuoteEntry(date: Date(), quote: nil)
                let timeline = Timeline(entries: [entry], policy: .atEnd)
                completion(timeline)
            }
        }
    }

    private func fetchQuote(completion: @escaping (Quote?) -> Void) {
        let url = URL(string: "https://zenquotes.io/api/today")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let quotes = try JSONDecoder().decode([QuoteResponse].self, from: data)
                    let quote = quotes.first.map { Quote(response: $0) }
                    completion(quote)
                } catch {
                    print("Failed to decode quote: \(error)")
                    completion(nil)
                }
            } else {
                print("Error fetching quote: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
        task.resume()
    }
}


struct QuoteWidgetEntryView: View {
    var entry: QuoteEntry
    var body: some View {
        ZStack {
            VStack {
                if let quote = entry.quote {
                    Text("\"\(quote.text)\"")
                        .font(.body)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3) // Limit to 3 lines
                        .minimumScaleFactor(0.5) // Allow text to shrink to 50%
                        .padding(8) // Set a limited padding
                        .frame(maxWidth: .infinity) // Make the text take full width
                        .padding(.horizontal, 1) // Horizontal padding for spacing
                        .containerBackground(for: .widget) {
                            Color.blue
                        }
                    Text("- \(quote.author)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding(.bottom)
                        .containerBackground(for: .widget) {
                            Color.blue
                        }
                } else {
                    Text("Loading...")
                        .font(.headline)
                        .foregroundColor(.white)
                        .containerBackground(for: .widget) {
                            Color.gray
                        }
                }
            }
            .padding(0.25)
        }
    }
}

struct QuoteWidget: Widget {
    let kind: String = "QuoteWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuoteProvider()) { entry in
            QuoteWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quote of the Day")
        .description("Get inspired with a daily quote.")
        .supportedFamilies([.systemMedium]) // Supports medium widget
    }
}
