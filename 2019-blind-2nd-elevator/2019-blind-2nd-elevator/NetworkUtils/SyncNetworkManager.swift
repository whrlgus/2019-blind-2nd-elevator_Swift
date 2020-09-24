//
//  SyncNetworkManager.swift
//
//  Created by 조기현 on 2020/09/24.
//

import Foundation

final class SyncNetworkManager: NetworkManager {
	static let shared = SyncNetworkManager()
	let queue = OperationQueue()
	
	private init() {
		super.init(baseURLString: "http://localhost:8000")
		queue.maxConcurrentOperationCount = 1
	}
	
	@discardableResult
	func request(_ request: URLRequest) -> Response {
		var response: Response?
		queue.addOperation(
			NetworkOperation(request: request) { data in
				let json = try? JSONSerialization.jsonObject(with: data, options: [])
//				print(json)
				
				response = try? JSONDecoder().decode(Response.self, from: data)
			}
		)
		queue.waitUntilAllOperationsAreFinished()
		guard let ret = response else { fatalError() }
		return ret
	}
}
