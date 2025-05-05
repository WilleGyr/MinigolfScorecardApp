import SwiftUI

struct GameView: View {
    var playerNames: [String]
    var roundCount: Int
    let holeCount = 18

    @State private var scores: [[[String]]]
    @State private var showResults = false
    @State private var keyboardHeight: CGFloat = 0
    
    // Focus state for tracking the currently focused field
    @FocusState private var focusedField: FocusedField?
    @State private var selectedTab: Int = 0
    
    private enum FocusedField: Hashable {
        case field(player: Int, hole: Int, round: Int)
    }

    init(playerNames: [String], roundCount: Int) {
        self.playerNames = playerNames
        self.roundCount = roundCount
        _scores = State(initialValue:
            Array(repeating:
                Array(repeating:
                    Array(repeating: "", count: roundCount),
                    count: holeCount
                ),
                count: playerNames.count
            )
        )
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .topTrailing) {
                TabView(selection: $selectedTab) {
                    ForEach(playerNames.indices, id: \.self) { playerIndex in
                        VStack {
                            Text(playerNames[playerIndex])
                                .font(.title)
                                .padding(.top)

                            ScrollView(.horizontal) {
                                ScrollView(.vertical) {
                                    VStack(spacing: 1) {
                                        // Header row
                                        HStack(spacing: 1) {
                                            Text("Hål")
                                                .frame(width: 40)
                                                .bold()
                                            ForEach(0..<roundCount, id: \.self) { roundIndex in
                                                Text("Runda \(roundIndex + 1)")
                                                    .frame(width: 80)
                                                    .bold()
                                            }
                                        }

                                        Divider()

                                        // Hole rows
                                        ForEach(0..<holeCount, id: \.self) { holeIndex in
                                            HStack(spacing: 1) {
                                                Text("\(holeIndex + 1)")
                                                    .frame(width: 40)

                                                ForEach(0..<roundCount, id: \.self) { roundIndex in
                                                    TextField("-", text: $scores[playerIndex][holeIndex][roundIndex])
                                                        .keyboardType(.numberPad)
                                                        .frame(width: 80)
                                                        .multilineTextAlignment(.center)
                                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                                        .focused($focusedField, equals: .field(player: playerIndex, hole: holeIndex, round: roundIndex))
                                                        .submitLabel(.next)
                                                        .onSubmit {
                                                            moveToNextField()
                                                        }
                                                }
                                            }
                                        }

                                        Divider()
                                        Text("Score")
                                            .font(.headline)
                                            .padding(.top)

                                        HStack(spacing: 1) {
                                            Text(" ")
                                                .frame(width: 40)

                                            ForEach(0..<roundCount, id: \.self) { roundIndex in
                                                let total = scores[playerIndex].compactMap { Int($0[roundIndex]) }.reduce(0, +)
                                                let relative = total - 36

                                                VStack {
                                                    Text("\(total)")
                                                        .frame(width: 80)
                                                        .multilineTextAlignment(.center)
                                                    Text(relative >= 0 ? "+\(relative)" : "\(relative)")
                                                        .foregroundColor(relative == 0 ? .black : (relative > 0 ? .red : .green))
                                                        .font(.subheadline)
                                                }
                                            }
                                        }
                                        .padding(.top)
                                    }
                                    .padding()
                                }
                            }

                            Spacer()
                        }
                        .tabItem {
                            Text(playerNames[playerIndex])
                        }
                        .tag(playerIndex)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button("Nästa") {
                            moveToNextField()
                        }
                    }
                }

                NavigationLink(
                    destination: ResultsView(playerNames: playerNames, scores: scores, roundCount: roundCount),
                    isActive: $showResults
                ) {
                    EmptyView()
                }

                Button(action: {
                    showResults = true
                }) {
                    Text("Avsluta")
                        .font(.headline)
                        .foregroundColor(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(8)
                        .contentShape(Rectangle())
                }
                .padding(.trailing, 20)
            }
        }
        .onAppear {
            // Set initial focus
            focusedField = .field(player: 0, hole: 0, round: 0)
        }
    }
    
    private func moveToNextField() {
        guard let currentField = focusedField else { return }
        
        switch currentField {
        case .field(let player, let hole, let round):
            // Try to move to next round first
            if round < roundCount - 1 {
                focusedField = .field(player: player, hole: hole, round: round + 1)
            }
            // Then try to move to next player
            else if player < playerNames.count - 1 {
                let newPlayer = player + 1
                focusedField = .field(player: newPlayer, hole: hole, round: 0)
                selectedTab = newPlayer // Update the tab selection
            }
            // Then try to move to next hole
            else if hole < holeCount - 1 {
                focusedField = .field(player: 0, hole: hole + 1, round: 0)
                selectedTab = 0 // Reset to first player
            }
            // If we're at the last field, just stay there
        }
    }
}

#Preview {
    GameView(playerNames: ["Player 1", "Player 2"], roundCount: 2)
}
