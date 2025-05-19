import SwiftUI

struct PlayerOrderView: View {
    let allPlayers = ["W", "A", "D"]
    
    @State private var selectedPlayers: [String] = []
    @State private var roundCount: Int = 1
    @State private var navigateToGame = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Välj spelare och ordning")
                    .font(.largeTitle)
                    .bold()
                    .padding(.top)

                // Spelarknappar
                HStack(spacing: 20) {
                    ForEach(allPlayers, id: \.self) { name in
                        Button(action: {
                            if !selectedPlayers.contains(name) {
                                selectedPlayers.append(name)
                            }
                        }) {
                            Text(name)
                                .font(.title)
                                .frame(width: 60, height: 60)
                                .background(selectedPlayers.contains(name) ? Color.gray.opacity(0.3) : Color.blue)
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .disabled(selectedPlayers.contains(name))
                    }
                }

                // Visa vald ordning
                VStack(spacing: 5) {
                    Text("Ordning:")
                        .font(.headline)
                    Text(selectedPlayers.isEmpty ? "-" : selectedPlayers.joined(separator: " → "))
                        .font(.title2)
                        .foregroundColor(.blue)
                }

                // Val av rundor
                VStack {
                    Stepper("Rundor: \(roundCount)", value: $roundCount, in: 1...4)
                        .font(.title3)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }

                // Startknapp när minst 2 spelare är valda
                if selectedPlayers.count >= 2 {
                    NavigationLink(
                        destination: GameView(playerNames: selectedPlayers, roundCount: roundCount),
                        isActive: $navigateToGame
                    ) {
                        EmptyView()
                    }

                    Button(action: {
                        navigateToGame = true
                    }) {
                        Text("Starta spel")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.horizontal, 40)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                    .padding(.top, 10)
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    PlayerOrderView()
}
