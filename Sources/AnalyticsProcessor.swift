import ArgumentParser
import Foundation
import CSV
import os

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
        let logger = Logger()

        guard let stream = InputStream(fileAtPath: input) else {
            throw AnalyticsProcessorError.failedToOpenInputStream
        }

        let csv = try CSVReader(stream: stream)

        var rowNumber = 0

        ///
        /// Whether the file header section was completed.
        ///
        var completedFileHeaders = false

        ///
        /// The leading key-value lines at the beginning of the document which are not part of the actual table.
        ///
        var fileHeaders = [String: String]()

        var headers: [String]?
        var appName = "?"
        var reportDate = "?"

        ///
        /// The parsed results.
        ///
        /// The hierarchy is date → major platform release → count.
        ///
        var processed = [String: [String: Int]]()

        // MARK: - Parse

        while let row = csv.next() {
            logger.debug("Reading row \(rowNumber)...")

            defer {
                rowNumber += 1
            }

            guard row[0].isEmpty == false else {
                logger.debug("Row is empty! Assuming file header section is completed and skipping this one.")
                completedFileHeaders = true
                continue
            }

            if completedFileHeaders {
                if headers == nil {
                    logger.debug("Completed file header section and no table headers are defined yet, assuming current row is defining table headers.")
                    headers = row
                } else {
                    ///
                    /// Current column index of the row being iterated over.
                    ///
                    var columnNumber = 0

                    ///
                    /// The date for the current row.
                    ///
                    var date: String?

                    for value in row {
                        logger.debug("Reading column \(columnNumber): \(value)")

                        switch columnNumber {
                            case 0:
                                // Create new dictionary for the given date, if not existing yet.
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
            } else {
                logger.debug("Found file header \"\(row[0])\" with value \"\(row[1])\".")
                fileHeaders[row[0]] = row[1]
            }
        }

        // MARK: - Process File Headers

        if let name = fileHeaders["Name"] {
            appName = name
        }

        if let start = fileHeaders["Startdatum"], let end = fileHeaders["Enddatum"] {
            reportDate = "from \(start) to \(end)"
        } else if let date = fileHeaders["Datum"] {
            reportDate = "on \(date)"
        }

        // MARK: - Output

        print("# Major Platform Version Distribution\n")

        print("Report for \(appName) \(reportDate).\n")

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
