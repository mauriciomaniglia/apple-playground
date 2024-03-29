import XCTest
import RickAndMortyAPI

class CharacterImageDataMapperTests: XCTestCase {

    func test_map_throwsErrorOnNonHTTPResponse() throws {
        let nonEmptyData = Data("non-empty data".utf8)

        XCTAssertThrowsError(
            try CharacterImageDataMapper.map(nonEmptyData, from: URLResponse())
        )
    }

    func test_map_throwsErrorOnNon200HTTPResponse() throws {
        let samples = [199, 201, 300, 400, 500]

        try samples.forEach { code in
            XCTAssertThrowsError(
                try CharacterImageDataMapper.map(anyData(), from: HTTPURLResponse(statusCode: code))
            )
        }
    }

    func test_map_deliversInvalidDataErrorOn200HTTPResponseWithEmptyData() {
        let emptyData = Data()

        XCTAssertThrowsError(
            try CharacterImageDataMapper.map(emptyData, from: HTTPURLResponse(statusCode: 200))
        )
    }

    func test_map_deliversReceivedNonEmptyDataOn200HTTPResponse() throws {
        let nonEmptyData = Data("non-empty data".utf8)

        let result = try CharacterImageDataMapper.map(nonEmptyData, from: HTTPURLResponse(statusCode: 200))

        XCTAssertEqual(result, nonEmptyData)
    }

}
