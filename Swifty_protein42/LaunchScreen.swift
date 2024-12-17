import SwiftUI

struct LaunchScreen: View {
    @State private var isActive = false

    var body: some View {
        if isActive {
            LoginView()
        } else {
            VStack {
                Spacer()
                Text("PROTEIN EXPLORER")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .tracking(2.0)
                Spacer()
                Text("Made by Sasso Stark and Celiniya")
                    .padding(.bottom, 8)
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}

struct LaunchScreen_Previews: PreviewProvider {
    static var previews: some View {
        LaunchScreen()
    }
}
