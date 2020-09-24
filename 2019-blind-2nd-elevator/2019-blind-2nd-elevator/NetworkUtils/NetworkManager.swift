//
//  NetworkManager.swift
//
//  Created by 조기현 on 2020/09/22.
//  Copyright © 2020 gicho. All rights reserved.
//

import Foundation

class NetworkManager {
	let baseURLString: String// = "http://localhost:8000"
	
	init(baseURLString: String) {
		self.baseURLString = baseURLString
	}
	
	struct Header {
		let field: String
		let value: String
		init(_ field: String, _ value: String) {
			self.field = field
			self.value = value
		}
	}
	
	enum HTTPMethod: String {
		case GET, POST
	}
	
	func requestObject(_ pathComponents: [String],_ method: HTTPMethod,_ headers: [Header]? = nil,_ body: Data? = nil) -> URLRequest {
		guard var url = URL(string: baseURLString) else { fatalError() }
		
		pathComponents.forEach{ url.appendPathComponent($0) }
		
		var request = URLRequest(url: url)
		request.httpMethod = method.rawValue
		headers?.forEach{ request.setValue($0.value, forHTTPHeaderField: $0.field) }
		if let body = body {
			request.setValue("application/json", forHTTPHeaderField: "Content-Type")
			request.httpBody = body
		}
		
		return request
	}
	
	func dataTask(_ request: URLRequest, completion: @escaping (Data) -> ()) -> URLSessionDataTask {
		return URLSession.shared.dataTask(with: request) { (data, response, error) in
			if let error = error { fatalError("\(error)") }
			
			guard let httpResponse = response as? HTTPURLResponse,
				  (200...299).contains(httpResponse.statusCode) else {
//				fatalError(response?.description ?? "")
				let json = try? JSONSerialization.jsonObject(with: request.httpBody!, options: [])
				print(json)
				fatalError()
			}
			
			if let data = data {
				completion(data)
			}
		}
	}
	
	func request(_ pathComponents: [String],_ method: HTTPMethod,_ headers: [Header],_ body: Data? = nil, completion: @escaping (Data) -> ()) {
		dataTask(requestObject(pathComponents, method, headers, body), completion: completion).resume()
	}
}
