import ArgumentParser
import Foundation
import CSV

enum AnalyticsProcessorError: Error {
    case dateParsing
    case failedToCreateCSVReader
    case failedToOpenInputStream
    case preconditionNotMet
}

@main
struct AnalyticsProcessor: ParsableCommand {
    @Argument(help: "The CSV file exported from App Store Connect analytics.")
    var input: String

    mutating func run() throws {
        guard let stream = InputStream(fileAtPath: input) else {
            throw AnalyticsProcessorError.failedToOpenInputStream
        }

        let csv = try CSVReader(stream: stream)

        var rowNumber = 0
        var headers: [String]?
        var appName = "?"
        var reportDate = "?"

        ///
        /// The parsed results.
        ///
        var processed = [String: [String: Int]]()

        // MARK: - Parse

        while let row = csv.next() {
            switch rowNumber {
                case 0:
                    appName = row[1]
                case 1:
                    reportDate = row[1]
                case 2:
                    break
                case 3:
                    headers = row
                default:
                    var columnNumber = 0
                    var date: String?
                    var totalForDate = 0

                    for value in row {
                        switch columnNumber {
                            case 0:
                                if processed.keys.contains(value) == false {
                                    date = value
                                    processed[value] = [:]
                                }
                            default:
                                guard let date else {
                                    throw AnalyticsProcessorError.preconditionNotMet
                                }

                                guard let headers else {
                                    throw AnalyticsProcessorError.preconditionNotMet
                                }

                                let header = headers[columnNumber]
                                let mappedMajorVersion = String(header.split(separator: ".").first!)

                                guard mappedMajorVersion.hasPrefix("iOS") else {
                                    break
                                }

                                var total = value == "-" ? 0 : Int(Double(value)!)

                                if let existingTotal = processed[date]?[mappedMajorVersion] {
                                    total = existingTotal + total
                                }

                                guard total > 0 else {
                                    break
                                }

                                processed[date]?[mappedMajorVersion] = total
                        }

                        columnNumber += 1
                    }
            }

            rowNumber += 1
        }

        // MARK: - Output

        print("# Major Platform Version Distribution\n")

        print("Report for \(appName) on \(reportDate).\n")

        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        let percentageFormatter = NumberFormatter()
        percentageFormatter.minimumFractionDigits = 1
        percentageFormatter.maximumFractionDigits = 1

        for date in processed.keys.sorted() {
            let total = processed[date]!.values.reduce(0, +)

            print("## \(date)\n")
            print("\(numberFormatter.string(from: NSNumber(value: total))!) in Total.\n")

            print("| **Release** | **Total** | **Percentage** |")
            print("| - | - | - |")

            for majorVersion in processed[date]!.keys.sorted(by: { $0.localizedStandardCompare($1) == .orderedDescending }) {
                let value = processed[date]![majorVersion]!
                let number = NSNumber(value: value)
                let formattedCount = numberFormatter.string(from: number)!
                let percentage = NSNumber(value: Double(value) / Double(total) * 100.0)
                let formattedPercentage = percentageFormatter.string(from: percentage)!
                print("| \(majorVersion) | \(formattedCount) | \(formattedPercentage) % |")
            }

            print("")
        }
    }
}
