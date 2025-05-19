//
//  ResultsView.swift
//  Minigolf
//
//  Created by William Gyrulf on 2025-05-04.
//

import SwiftUI

struct ResultsView: View {
    @State private var saveConfirmation = false
    @State private var saveError = false
    @State private var fileToShare: URL?
    @State private var isSharing = false
    @State private var showExporter = false
    @State private var exportFile: TextFile?
    @State private var exportFileName = "MinigolfResultat"


    let playerNames: [String]
    let scores: [[[String]]] // [player][hole][round]
    let roundCount: Int

    var body: some View {
        VStack(spacing: 20) {
            Text("Resultat")
                .font(.largeTitle)
                .bold()
                .padding(.top)
            Button(action: {
                let csv = generateCSVText()
                exportFile = TextFile(initialText: csv)
                showExporter = true
            }) {
                Text("Spara resultat")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }

            ForEach(playerNames.indices, id: \.self) { playerIndex in
                let playerName = playerNames[playerIndex]
                let backgroundColor: Color = {
                    switch playerName {
                    case "W": return .blue .opacity(0.4)
                    case "A": return .green .opacity(0.4)
                    case "D": return .red .opacity(0.4)
                    default: return .gray.opacity(0.2) // fallback
                    }
                }()

                VStack(spacing: 10) {
                    Text(playerName)
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(.center)

                    // Round scores row
                    HStack(spacing: 12) {
                        ForEach(0..<roundCount, id: \.self) { roundIndex in
                            let total = scores[playerIndex].compactMap { Int($0[roundIndex]) }.reduce(0, +)
                            let relative = total - 36

                            VStack {
                                Text("\(total)")
                                Text(relative == 0 ? "(0)" : (relative > 0 ? "+\(relative)" : "\(relative)"))
                                    .foregroundColor(relative == 0 ? .white : (relative > 0 ? .red : .green))
                                    .font(.subheadline)
                            }
                            .multilineTextAlignment(.center)
                        }
                    }

                    // Average
                    let totals = (0..<roundCount).map { roundIndex in
                        scores[playerIndex].compactMap { Int($0[roundIndex]) }.reduce(0, +)
                    }

                    if !totals.isEmpty {
                        let average = Double(totals.reduce(0, +)) / Double(totals.count)
                        Text(String(format: "Snitt: %.1f", average))
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Count of 1s, 2s, 3s
                    let flattenedScores = scores[playerIndex].flatMap { $0 }
                    let ones = flattenedScores.filter { $0 == "1" }.count
                    let twos = flattenedScores.filter { $0 == "2" }.count
                    let threes = flattenedScores.filter { $0 == "3" }.count

                    HStack(spacing: 5) {
                        Text("\(ones)")
                        Text("/ \(twos)")
                        Text("/ \(threes)")
                    }
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                }
                .padding()
                .background(backgroundColor.gradient.opacity(0.9))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
            }

            

            Spacer()
        }
        .padding()
        .fileExporter(
            isPresented: $showExporter,
            document: exportFile,
            contentType: .plainText,
            defaultFilename: exportFileName
        ) { result in
            switch result {
            case .success:
                print("✅ File saved successfully.")
            case .failure(let error):
                print("❌ Error saving file: \(error.localizedDescription)")
            }
        }

        .alert("Resultat sparat!", isPresented: $saveConfirmation) {
            Button("OK", role: .cancel) { }
        }
        .alert("Det gick inte att spara filen", isPresented: $saveError) {
            Button("OK", role: .cancel) { }
        }
        .frame(maxWidth: .infinity) // Center the outer VStack in parent
    }
    func generateCSVText() -> String {
        var csv = ""

        for playerIndex in playerNames.indices {
            for roundIndex in 0..<roundCount {
                var row = "\(playerNames[playerIndex]),\(roundIndex + 1)"
                for holeIndex in 0..<scores[playerIndex].count {
                    let score = scores[playerIndex][holeIndex][roundIndex]
                    row += ",\(score.isEmpty ? "-" : score)"
                }
                csv += row + "\n"
            }
        }

        return csv
    }




}
import UniformTypeIdentifiers

struct TextFile: FileDocument {
    static var readableContentTypes = [UTType.plainText]
    var text = ""

    init(initialText: String = "") {
        text = initialText
    }

    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            text = String(decoding: data, as: UTF8.self)
        }
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = Data(text.utf8)
        return FileWrapper(regularFileWithContents: data)
    }
}

// Preview
#Preview {
    GameView(
        playerNames: ["W", "A", "D"],
        roundCount: 4
    )
}
