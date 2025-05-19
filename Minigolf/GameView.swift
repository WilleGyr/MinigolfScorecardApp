import SwiftUI

struct GameView: View {
    var playerNames: [String]
    var roundCount: Int
    let holeCount = 18

    @State private var scores: [[[String]]]
    @State private var showResults = false
    @State private var keyboardHeight: CGFloat = 0

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
                        ZStack {
                            backgroundColor(for: playerNames[playerIndex])
                                .ignoresSafeArea()

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
                                                            .onChange(of: scores[playerIndex][holeIndex][roundIndex]) { newValue in
                                                                if !newValue.isEmpty {
                                                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                                                        moveToNextField()
                                                                    }
                                                                }
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
                                                    let validScores = scores[playerIndex].compactMap { Int($0[roundIndex]) }
                                                    let holesPlayed = validScores.count
                                                    let total = validScores.reduce(0, +)
                                                    let relative = total - (2 * holesPlayed)

                                                    VStack {
                                                        Text(relative == 0 ? "+0" : (relative > 0 ? "+\(relative)" : "\(relative)"))
                                                            .foregroundColor(relative == 0 ? .white : (relative > 0 ? .red : .green))
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
                        }
                        .tabItem {
                            Text(playerNames[playerIndex])
                        }
                        .tag(playerIndex)
                        .onChange(of: selectedTab) { newValue in
                            if newValue == playerIndex {
                                let currentHole = focusedHole
                                focusedField = .field(player: playerIndex, hole: currentHole, round: 0)
                            }
                        }
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Button("Tidigare") {
                            moveToPreviousField()
                        }
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
            focusedField = .field(player: 0, hole: 0, round: 0)
        }
    }

    private var focusedHole: Int {
        if case let .field(_, hole, _) = focusedField {
            return hole
        }
        return 0
    }

    private func moveToNextField() {
        guard let currentField = focusedField else { return }

        switch currentField {
        case .field(let player, let hole, let round):
            if round < roundCount - 1 {
                focusedField = .field(player: player, hole: hole, round: round + 1)
            } else if player < playerNames.count - 1 {
                let newPlayer = player + 1
                withAnimation {
                    selectedTab = newPlayer
                }
                focusedField = .field(player: newPlayer, hole: hole, round: 0)
            } else if hole < holeCount - 1 {
                withAnimation {
                    selectedTab = 0
                }
                focusedField = .field(player: 0, hole: hole + 1, round: 0)
            }
        }
    }

    private func moveToPreviousField() {
        guard let currentField = focusedField else { return }

        switch currentField {
        case .field(let player, let hole, let round):
            if round > 0 {
                focusedField = .field(player: player, hole: hole, round: round - 1)
            } else if player > 0 {
                let newPlayer = player - 1
                withAnimation {
                    selectedTab = newPlayer
                }
                focusedField = .field(player: newPlayer, hole: hole, round: roundCount - 1)
            } else if hole > 0 {
                withAnimation {
                    selectedTab = playerNames.count - 1
                }
                focusedField = .field(player: playerNames.count - 1, hole: hole - 1, round: roundCount - 1)
            }
        }
    }

    private func backgroundColor(for name: String) -> Color {
        switch name.uppercased() {
        case "W":
            return Color.blue.opacity(0.2)
        case "A":
            return Color.green.opacity(0.2)
        case "D":
            return Color.red.opacity(0.2)
        default:
            return Color.gray.opacity(0.05)
        }
    }
}

#Preview {
    GameView(
        playerNames: ["W", "A", "D"],
        roundCount: 2
    )
}
