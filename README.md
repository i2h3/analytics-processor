# Analytics Processor

The App Store Connect user interface and exported CSV documents are not straightforward in regards to knowing which major iOS versions users are on.
This quickly hacked together parser processes a CSV export and renders it as Markdown.

## How To Get Report

1. Go to App Store Connect.
2. Go to Analytics.
3. Select Metrics.
4. Select active devices.
5. Select by platform version.
6. Select grouping by months above the graph.
7. Export the CSV document from within the ellipsis menu.
8. Provide the report file as an argument.

## Build

To build a binary, navigate into the package directory and run:

```plaintext
$ swift build
```

## Usage

Then you can run the built binary like this:

```plaintext
$ swift run AnalyticsProcessor <input file>
```

## Development

It is convenient to define an argument in the generated Xcode scheme which specifies the absolute path to an input file for debugging.

## Example Output

The rendered markdown currently looks somewhat like this:

```markdown
# Major Platform Version Distribution

Report for Whatever on 01.02.25.

## 01.01.25

102.313 in Total.

| **Release** | **Total** | **Percentage** |
| - | - | - |
| iOS 18 | 88.474 | 86,5 % |
| iOS 17 | 10.176 | 9,9 % |
| iOS 16 | 2.253 | 2,2 % |
| iOS 15 | 1.276 | 1,2 % |
| iOS 14 | 63 | 0,1 % |
| iOS 13 | 12 | 0,0 % |
| iOS 12 | 51 | 0,0 % |
| iOS 10 | 2 | 0,0 % |
| iOS 9 | 6 | 0,0 % |

## 01.02.25

83.983 in Total.

| **Release** | **Total** | **Percentage** |
| - | - | - |
| iOS 18 | 74.692 | 88,9 % |
| iOS 17 | 6.771 | 8,1 % |
| iOS 16 | 1.530 | 1,8 % |
| iOS 15 | 890 | 1,1 % |
| iOS 14 | 47 | 0,1 % |
| iOS 13 | 13 | 0,0 % |
| iOS 12 | 33 | 0,0 % |
| iOS 10 | 3 | 0,0 % |
| iOS 9 | 4 | 0,0 % |
```

## Development

You can easily debug it by providing a file path as an argument through the Xcode scheme.

## License

See [LICENSE](LICENSE) file.
