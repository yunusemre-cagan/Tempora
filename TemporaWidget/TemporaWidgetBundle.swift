import SwiftUI
import WidgetKit

@main
struct TemporaWidgetBundle: WidgetBundle {
    var body: some Widget {
        TemporaWidget()
        UpcomingWidget()
    }
}
