

import Foundation

enum CallApiError: Error {
	case responseIsNot200
	case stringIsNotGoodUrl
}


func callApi<T>(_ request: URLRequest, to: T.Type) async throws -> T where T : Decodable {
	
	let (data, response) = try await URLSession.shared.data(for: request)
	
	if !response.isOk {
		throw CallApiError.responseIsNot200
	}
	
	data.printAsString()
	
	return try data.decode(to: to)
}

extension String {
	func toRequest() throws -> URLRequest {
		guard let url = URL(string: self) else {
			throw CallApiError.stringIsNotGoodUrl
		}
		
		return URLRequest(url: url)
	}
	
	func toDeleteRequest() throws -> URLRequest {
		guard let url = URL(string: self) else {
			throw CallApiError.stringIsNotGoodUrl
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = "DELETE"
		return request
	}
	
	
	func toRequest<T>(withBody bodyObject: T, method: String) throws -> URLRequest where T : Encodable {
		guard let url = URL(string: self) else {
			throw CallApiError.stringIsNotGoodUrl
		}
		
		var request = URLRequest(url: url)
		request.httpMethod = method
		
		let data = try JSONEncoder().encode(bodyObject)
		request.httpBody = data
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		
		return request
	}
}

extension Data {
	func printAsString() {
		guard let dataAsString = String(data: self, encoding: .utf8) else {
			print("Can not convert data to string")
			return
		}
		
		print("Data as String: \(dataAsString)")
	}
	
	func decode<T>(to: T.Type) throws -> T where T : Decodable {
		return try JSONDecoder().decode(to, from: self)
	}
}

extension URLResponse {
	var statusCode: Int? {
//		if let statusCode = (self as! HTTPURLResponse).statusCode  {
//			return statusCode
//		}
		
		print("Can not get status code")
		return 200
	}
	
	var isOk: Bool {
		guard let statusCode = self.statusCode else {
			return false
		}
		
		if statusCode < 200 || statusCode > 299 {
			print("Status code: (statusCode), is not in 200s.")
			return false
		}
		
		return true
	}
}
