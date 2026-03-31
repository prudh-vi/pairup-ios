import SwiftUI

struct HomeView: View {
    @State private var isSearching = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                
                // Logo
                VStack(spacing: 8) {
                    Text("PairUp")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Meet someone new")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Button
                Button(action: {
                    isSearching = true
                }) {
                    Text("Find Someone")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 40)
            }
        }
        .navigationDestination(isPresented: $isSearching) {
            MatchmakingView()
        }
    }
}
