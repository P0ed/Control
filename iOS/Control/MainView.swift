import SwiftUI
import Combine

struct MainView: View {
	@ObservedObject var model: Model

	var body: some View {
		Text(model.clockBPM == 0 ? "||" : "\(String(format: "%.2f", model.clockBPM))")
	}
}
