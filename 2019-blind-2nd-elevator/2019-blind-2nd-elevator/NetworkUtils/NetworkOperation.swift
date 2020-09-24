//
//  NetworkOperation.swift
//
//  Created by 조기현 on 2020/09/24.
//  Copyright © 2020 gicho. All rights reserved.
//

import Foundation

final class NetworkOperation: Operation {
	enum OperationState { case ready, executing, finished }
	var state: OperationState = .ready {
		willSet {
			willChangeValue(forKey: "isExecuting")
			willChangeValue(forKey: "isFinished")
		}
		didSet {
			didChangeValue(forKey: "isExecuting")
			didChangeValue(forKey: "isFinished")
		}
	}
	
	let manager = SyncNetworkManager.shared
	private var task: URLSessionDataTask!
	
	init(request: URLRequest, completionHandler: @escaping (Data) -> ()) {
		super.init()
		task = manager.dataTask(request, completion: { [weak self] data in
			completionHandler(data)
			self?.state = .finished
		})
	}
	
	override var isReady: Bool { return state == .ready }
	override var isExecuting: Bool { return state == .executing }
	override var isFinished: Bool { return state == .finished }
	
	override func start() {
		if self.isCancelled {
			state = .finished
			return
		}
		state = .executing
		task.resume()
	}
	
	override func cancel() {
		super.cancel()
		task.cancel()
	}
}
