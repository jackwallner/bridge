import XCTest
@testable import Bridge

final class ExtractDumpTests: XCTestCase {
    func testDump() throws {
        _ = DrillLibrary.rooms.count
        _ = HowToPlayContent.pages.count
        _ = WhatsNew.releases.count
        let keys = ContentKeyRecorder.shared.all
        let data = try JSONSerialization.data(withJSONObject: keys, options: [.prettyPrinted, .sortedKeys])
        let a = XCTAttachment(data: data, uniformTypeIdentifier: "public.json")
        a.name = "content-keys.json"
        a.lifetime = .keepAlways
        add(a)
        let resources = Bundle.main.resourcePath ?? ""
        for name in ["synced.xcstrings", "stringsdata-list.txt"] {
            let url = URL(fileURLWithPath: resources).appendingPathComponent(name)
            let d = (try? Data(contentsOf: url)) ?? Data("missing \(url.path)".utf8)
            let b = XCTAttachment(data: d, uniformTypeIdentifier: "public.data")
            b.name = name
            b.lifetime = .keepAlways
            add(b)
        }
    }
}
