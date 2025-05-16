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
            Button("Spara resultat") {
                let csv = generateCSVText()
                exportFile = TextFile(initialText: csv)
                showExporter = true
            }

            .font(.headline)
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(8)
            ForEach(playerNames.indices, id: \.self) { playerIndex in
                VStack(spacing: 10) {
                    Text(playerNames[playerIndex])
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

                    // Average row
                    let totals = (0..<roundCount).map { roundIndex in
                        scores[playerIndex].compactMap { Int($0[roundIndex]) }.reduce(0, +)
                    }

                    if !totals.isEmpty {
                        let average = Double(totals.reduce(0, +)) / Double(totals.count)
                        Text(String(format: "Snitt: %.1f", average))
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                    // Räkna antal 1:or, 2:or, 3:or
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
                    .foregroundColor(.gray)

                }

                
                .padding()
                .frame(maxWidth: 300)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
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
    ContentView()
}
