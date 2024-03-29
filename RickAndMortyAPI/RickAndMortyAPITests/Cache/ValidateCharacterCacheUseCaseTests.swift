import XCTest
import RickAndMortyAPI

class ValidateCharacterCacheUseCaseTests: XCTestCase {

    func test_init_doesNotMessageStoreCacheUponCreation() {
        let (_, store) = makeSUT()

        XCTAssertEqual(store.receivedMessages, [])
    }

    func test_validateCache_deletesCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        store.completeRetrieval(with: anyNSError())

        try? sut.validateCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheCharacter])
    }

    func test_validateCache_doesNotDeletesCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        store.completeRetrievalWithEmptyCache()

        try? sut.validateCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_validateCache_doesNotDeletesNonExpiredCache() {
        let character = uniqueCharacters()
        let fixCurrentDate = Date()
        let nonExpiredTimestamp = fixCurrentDate.minusCharacterCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixCurrentDate })
        store.completeRetrieval(with: character.local, timestamp: nonExpiredTimestamp)

        try? sut.validateCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve])
    }

    func test_validateCache_deletesCacheOnExpiration() {
        let character = uniqueCharacters()
        let fixCurrentDate = Date()
        let expirationTimestamp = fixCurrentDate.minusCharacterCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: { fixCurrentDate })
        store.completeRetrieval(with: character.local, timestamp: expirationTimestamp)

        try? sut.validateCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheCharacter])
    }

    func test_validateCache_deletesExpiredCache() {
        let character = uniqueCharacters()
        let fixCurrentDate = Date()
        let expiredTimestamp = fixCurrentDate.minusCharacterCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixCurrentDate })
        store.completeRetrieval(with: character.local, timestamp: expiredTimestamp)

        try? sut.validateCache()

        XCTAssertEqual(store.receivedMessages, [.retrieve, .deleteCacheCharacter])
    }

    func test_validateCache_failsOnDeletionErrorOfFailedRetrieval() {
        let (sut, store) = makeSUT()
        let deletionError = anyNSError()

        expect(sut, toCompleteWith: .failure(deletionError), when: {
            store.completeRetrieval(with: anyNSError())
            store.completeDeletion(with: deletionError)
        })
    }

    func test_validateCache_succeedsOnSuccessfulDeletionOfFailedRetrieval() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success(()), when: {
            store.completeRetrieval(with: anyNSError())
            store.completeDeletionSuccessfully()
        })
    }

    func test_validateCache_succeedsOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success(()), when: {
            store.completeRetrievalWithEmptyCache()
        })
    }

    func test_validateCache_succeedsOnNonExpiredCache() {
        let character = uniqueCharacters()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusCharacterCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .success(()), when: {
            store.completeRetrieval(with: character.local, timestamp: nonExpiredTimestamp)
        })
    }

    func test_validateCache_failsOnDeletionErrorOfExpiredCache() {
        let character = uniqueCharacters()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusCharacterCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })
        let deletionError = anyNSError()

        expect(sut, toCompleteWith: .failure(deletionError), when: {
            store.completeRetrieval(with: character.local, timestamp: expiredTimestamp)
            store.completeDeletion(with: deletionError)
        })
    }

    func test_validateCache_succeedsOnSuccessfulDeletionOfExpiredCache() {
        let character = uniqueCharacters()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusCharacterCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

        expect(sut, toCompleteWith: .success(()), when: {
            store.completeRetrieval(with: character.local, timestamp: expiredTimestamp)
            store.completeDeletionSuccessfully()
        })
    }

    // MARK: - Helpers

    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #file, line: UInt = #line) -> (sut: LocalCharacterLoader, store: CharacterStoreSpy) {
        let store = CharacterStoreSpy()
        let sut = LocalCharacterLoader(store: store, currentDate: currentDate)

        trackForMemoryLeak(sut, file: file, line: line)
        trackForMemoryLeak(store, file: file, line: line)

        return (sut, store)
    }

    private func expect(_ sut: LocalCharacterLoader, toCompleteWith expectedResult: Result<Void, Error>, when action: () -> Void, file: StaticString = #file, line: UInt = #line) {
        action()

        let receivedResult = Result { try sut.validateCache() }

        switch (receivedResult, expectedResult) {
        case (.success, .success):
            break
        case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
            XCTAssertEqual(receivedError, expectedError, file: file, line: line)
        default:
            XCTFail("Expected result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
        }
    }
}
