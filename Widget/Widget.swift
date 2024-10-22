//
//  Widget.swift
//  Widget
//
//  Created by Eli on 10/18/24.
//
import WidgetKit
import SwiftUI
import HealthKit

// MARK: - Timeline Entry

struct HealthEntry: TimelineEntry {
    let date: Date
    let steps: Int
    let activeCalories: Int
    let dietaryCalories: Int
}

// MARK: - Provider

struct HealthProvider: TimelineProvider {
    func placeholder(in context: Context) -> HealthEntry {
        HealthEntry(date: Date(), steps: 0, activeCalories: 0, dietaryCalories: 0)
    }

    func getSnapshot(in context: Context, completion: @escaping (HealthEntry) -> Void) {
        fetchHealthData { entry in
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HealthEntry>) -> Void) {
        fetchHealthData { entry in
            let timeline = Timeline(entries: [entry], policy: .after(entry.date.addingTimeInterval(60 * 5))) // Refresh every 5 minutes
            completion(timeline)
        }
        setupHealthKitObserver()
    }

    private func setupHealthKitObserver() {
        let healthStore = HKHealthStore()

        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount),
              let activeCaloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
              let dietaryCaloriesType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            return
        }

        // Set up observer queries for HealthKit
        let observerQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { _, completionHandler, error in
            if error == nil {
                WidgetCenter.shared.reloadAllTimelines()
            }
            completionHandler()
        }
        healthStore.execute(observerQuery)

        let activeCaloriesObserverQuery = HKObserverQuery(sampleType: activeCaloriesType, predicate: nil) { _, completionHandler, error in
            if error == nil {
                WidgetCenter.shared.reloadAllTimelines()
            }
            completionHandler()
        }
        healthStore.execute(activeCaloriesObserverQuery)

        let dietaryCaloriesObserverQuery = HKObserverQuery(sampleType: dietaryCaloriesType, predicate: nil) { _, completionHandler, error in
            if error == nil {
                WidgetCenter.shared.reloadAllTimelines()
            }
            completionHandler()
        }
        healthStore.execute(dietaryCaloriesObserverQuery)
    }

    private func fetchHealthData(completion: @escaping (HealthEntry) -> Void) {
        let healthStore = HKHealthStore()
        
        
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let activeCaloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let dietaryCaloriesType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let group = DispatchGroup()
        var steps: Int = 0
        var activeCalories: Int = 0
        var dietaryCalories: Int = 0

        // Fetch Steps
        group.enter()
        let stepsQuery = HKSampleQuery(sampleType: stepsType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            if let results = results as? [HKQuantitySample] {
                steps = Int(results.reduce(0) { $0 + $1.quantity.doubleValue(for: HKUnit.count()) })
            }
            group.leave()
        }
        healthStore.execute(stepsQuery)

        // Fetch Active Calories
        group.enter()
        let activeCaloriesQuery = HKSampleQuery(sampleType: activeCaloriesType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            if let results = results as? [HKQuantitySample] {
                activeCalories = Int(results.reduce(0) { $0 + $1.quantity.doubleValue(for: HKUnit.kilocalorie()) })
            }
            group.leave()
        }
        healthStore.execute(activeCaloriesQuery)

        // Fetch Dietary Calories
        group.enter()
        let dietaryCaloriesQuery = HKSampleQuery(sampleType: dietaryCaloriesType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            if let results = results as? [HKQuantitySample] {
                dietaryCalories = Int(results.reduce(0) { $0 + $1.quantity.doubleValue(for: HKUnit.kilocalorie()) })
            }
            group.leave()
        }
        healthStore.execute(dietaryCaloriesQuery)

        // Wait for all queries to complete
        group.notify(queue: .main) {
            let entry = HealthEntry(date: Date(), steps: Int(steps), activeCalories: Int(activeCalories), dietaryCalories: Int(dietaryCalories))
            completion(entry)
        }

        

        
    }
}
