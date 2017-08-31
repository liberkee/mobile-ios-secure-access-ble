//
//  BoundedQueueTests.swift
//  SecureAccessBLE
//
//  Copyright © 2017 Huf Secure Mobile GmbH. All rights reserved.
//

import XCTest
@testable import SecureAccessBLE

class BoundedQueueTests: XCTestCase {

    var queue = BoundedQueue<String>(maximumElements: 1)

    func test_init_succeeds() {
        let queue = BoundedQueue<String>()
        XCTAssertNotNil(queue)
    }

    func test_initWithMaximumElements_succeeds() {
        XCTAssertNotNil(queue)
    }

    func test_enqueue_ifMaximumElementsAreNotReached_itDoesNotThrow() throws {
        try queue.enqueue("element1")
    }

    func test_enqueue_ifMaximumElementsAreReached_throwsMaximumElementsReached() throws {
        do {
            try queue.enqueue("element1")
            try queue.enqueue("element2")
            XCTFail("It did not throw.")
        } catch BoundedQueue<String>.Error.maximumElementsReached {
        } catch {
            XCTFail("Did not throw the correct error.")
        }
    }

    func test_enqueueDequeue_ifElementWasEnqueued_itCanBeDequeued() throws {
        try queue.enqueue("element1")
        XCTAssertEqual(queue.dequeue(), "element1")
    }

    func test_enqueueDequeue_itFollowsFirstInFirstOutPrinciple() throws {

        // Given
        var queue = BoundedQueue<String>(maximumElements: 2)

        // When Then
        try queue.enqueue("element1")
        try queue.enqueue("element2")
        XCTAssertEqual(queue.dequeue(), "element1")
        try queue.enqueue("element3")
        XCTAssertEqual(queue.dequeue(), "element2")
        XCTAssertEqual(queue.dequeue(), "element3")
    }

    func test_dequeue_ifQueueIsEmpty_returnsNil() {
        XCTAssertNil(queue.dequeue())
    }

    func test_isEmpty_ifQueueIsCreated_itIsEmpty() {
        XCTAssertTrue(queue.isEmpty)
    }

    func test_isEmpty_ifElementIsEnqueuedAndNotDequeued_itIsNotEmpty() throws {
        try queue.enqueue("element1")
        XCTAssertFalse(queue.isEmpty)
    }

    func test_isEmpty_ifEveryElementWasDequeuedThatWasEnqueuedBefore_itIsEmpty() throws {

        // Given
        var queue = BoundedQueue<String>(maximumElements: 2)

        // When
        try queue.enqueue("element1")
        try queue.enqueue("element2")
        _ = queue.dequeue()
        _ = queue.dequeue()

        // Then
        XCTAssertTrue(queue.isEmpty)
    }
}
