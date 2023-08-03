import SwiftUI

struct StreamView: View {
    @ObservedObject var viewModel: AppViewModel
    var body: some View {
        VStack {
            Form {
                CheckBoxItem(title: "Stream Started", isChecked: viewModel.started)
                CheckBoxItem(title: "VideoView Ready", isChecked: viewModel.remoteVideoTrack != nil)
                VideoView(remoteVideoTrack: viewModel.remoteVideoTrack)
                    .frame(height: 200)
            }
        }
        .navigationBarTitle(viewModel.selectedStream?.description ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: viewModel.watch)
        .onDisappear(perform: viewModel.endWatch)
    }
}
