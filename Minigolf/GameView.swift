import SwiftUI

struct GameView: View {
    var playerNames: [String]
    var roundCount: Int
    let holeCount = 18

    @State private var scores: [[[String]]] // [player][hole][round]

    init(playerNames: [String], roundCount: Int) {
        self.playerNames = playerNames
        self.roundCount = roundCount
        // Initialize with empty strings for all cells
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
        TabView {
            ForEach(playerNames.indices, id: \.self) { playerIndex in
                VStack {
                    Text(playerNames[playerIndex])
                        .font(.title)
                        .padding(.top)

                    // Scroll view for spreadsheet-style layout
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
                                        }
                                    }
                                    
                                }
                                Divider()
                                Text("Score")
                                    .font(.headline)
                                    .padding(.top)

                                HStack(spacing: 1) {
                                    Text(" ")
                                        .frame(width: 40) // Empty space under "Hål"

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
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
        
    }
}


#Preview {
    ContentView()
}
