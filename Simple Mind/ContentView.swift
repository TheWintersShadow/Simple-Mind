//
//  ContentView.swift
//  Simple Mind
//
//  Created by Eli on 10/17/24.
//
import SwiftUI
import HealthKit

struct ContentView: View {
    @State private var stepCount: Int = 0
    @State private var activeCalories: Double = 0.0
    @State private var dietaryCalories: Double = 0.0
    
    private let healthStore = HKHealthStore()

    var body: some View {
        VStack(spacing: 20) {
            bubbleView(title: "Steps", value: "\(stepCount)", color: .blue)
            bubbleView(title: "Burned Calories", value: String(format: "%.0f", activeCalories), color: .green)
            bubbleView(title: "Consumed Calories", value: String(format: "%.0f", dietaryCalories), color: .orange)
        }
        .padding()
        .onAppear {
            requestAuthorization()
            fetchData()
            startObservingHealthData()
        }
    }

    private func bubbleView(title: String, value: String, color: Color) -> some View {
        VStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Text(value)
                .font(.largeTitle)
                .foregroundColor(.white)
        }
        .frame(width: 200, height: 100)
        .background(color)
        .cornerRadius(20)
        .shadow(radius: 10)
    }
    
    private func requestAuthorization() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let activeCaloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let dietaryCaloriesType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        
        let typesToShare: Set<HKSampleType> = []
        let typesToRead: Set<HKObjectType> = [stepType, activeCaloriesType, dietaryCaloriesType]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if !success {
                print("Authorization failed: \(error?.localizedDescription ?? "Unknown error")")
            } else {
                // Fetch data immediately after authorization
                fetchData()
            }
        }
    }
    
    private func fetchData() {
        fetchSteps()
        fetchActiveCalories()
        fetchDietaryCalories()
    }

    private func startObservingHealthData() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let activeCaloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let dietaryCaloriesType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed)!
        
        startObserver(for: stepType)
        startObserver(for: activeCaloriesType)
        startObserver(for: dietaryCaloriesType)
    }

    private func startObserver(for quantityType: HKQuantityType) {
        let observerQuery = HKObserverQuery(sampleType: quantityType, predicate: nil) { _, completionHandler, error in
            if error != nil {
                print("Error observing \(quantityType): \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            // Fetch data again when an update occurs
            DispatchQueue.main.async {
                self.fetchData()
            }
            completionHandler() // Ensure the completion handler is called
        }

        healthStore.execute(observerQuery)
    }
    
    private func fetchSteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: stepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            guard let results = results as? [HKQuantitySample], error == nil else {
                print("Failed to fetch steps: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            let totalSteps = results.reduce(0) { $0 + $1.quantity.doubleValue(for: HKUnit.count()) }
            DispatchQueue.main.async {
                self.stepCount = Int(totalSteps)
            }
        }

        healthStore.execute(query)
    }
    
    private func fetchActiveCalories() {
        guard let activeCaloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: activeCaloriesType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            guard let results = results as? [HKQuantitySample], error == nil else {
                print("Failed to fetch active calories: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            let totalCalories = results.reduce(0) { $0 + $1.quantity.doubleValue(for: HKUnit.kilocalorie()) }
            DispatchQueue.main.async {
                self.activeCalories = totalCalories
            }
        }

        healthStore.execute(query)
    }

    private func fetchDietaryCalories() {
        guard let dietaryCaloriesType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else { return }
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: dietaryCaloriesType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, results, error in
            guard let results = results as? [HKQuantitySample], error == nil else {
                print("Failed to fetch dietary calories: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            let totalCalories = results.reduce(0) { $0 + $1.quantity.doubleValue(for: HKUnit.kilocalorie()) }
            DispatchQueue.main.async {
                self.dietaryCalories = totalCalories
            }
        }

        healthStore.execute(query)
    }
}
