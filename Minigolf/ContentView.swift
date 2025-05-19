import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var playerCount = 2
    @State private var roundCount = 1
    @State private var playerNames: [String] = [""]
    @State private var isPressed = false
    @State private var navigateToGame = false
    let availableNames = ["W", "A", "D"]


    var body: some View {
        NavigationStack{
            VStack(spacing: 20) {
                Text("Minigolf Scorecard")
                    .font(.system(size: 30))
                    .padding(.top, 40)
                
                Stepper("Spelare: \(playerCount)", value: $playerCount, in: 1...3)
                    .font(.title2)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                    .onChange(of: playerCount) { newValue in
                        adjustPlayerNames(to: newValue)
                    }
                
                ForEach(0..<playerNames.count, id: \.self) { index in
                    TextField("Namn på spelare \(index + 1)", text: $playerNames[index])
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                }
                
                Stepper("Rundor: \(roundCount)", value: $roundCount, in: 1...4)
                    .font(.title2)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                
                NavigationLink(destination: GameView(playerNames: playerNames, roundCount: roundCount), isActive: $navigateToGame) {
                    EmptyView()
                }
                
                Button(action: {
                    navigateToGame = true
                }) {
                    Text("Start")
                        .font(.system(size: 30))
                        .bold()
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(isPressed ? Color.blue.opacity(0.7) : Color.blue)
                        .cornerRadius(12)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .shadow(color: .gray.opacity(0.5), radius: 4, x: 0, y: 4)
                }
                .onLongPressGesture(minimumDuration: 0.01, pressing: { pressing in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = pressing
                    }
                }, perform: {})
                .offset(y: 20)
                
                Spacer()
            }
            .padding()
            .onAppear {
                adjustPlayerNames(to: playerCount)
            }
        }
    }

    func adjustPlayerNames(to count: Int) {
        if playerNames.count < count {
            playerNames.append(contentsOf: Array(repeating: "", count: count - playerNames.count))
        } else if playerNames.count > count {
            playerNames.removeLast(playerNames.count - count)
        }
    }
}

#Preview {
    ContentView()
}
