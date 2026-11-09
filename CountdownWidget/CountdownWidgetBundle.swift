import SwiftUI
import WidgetKit

@main
struct CountdownWidgetBundle: WidgetBundle {
    var body: some Widget {
        CountdownWidget()
        UpcomingWidget()
    }
}
