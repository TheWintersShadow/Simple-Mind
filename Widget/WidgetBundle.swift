//
//  WidgetBundle.swift
//  Widget
//
//  Created by Eli on 10/18/24.
//

import WidgetKit
import SwiftUI

@main
struct HealthWidgets: WidgetBundle {
    var body: some Widget {
        StepsWidget()
        ActiveCaloriesWidget()
        DietaryCaloriesWidget()
        QuoteWidget()
    }
}
