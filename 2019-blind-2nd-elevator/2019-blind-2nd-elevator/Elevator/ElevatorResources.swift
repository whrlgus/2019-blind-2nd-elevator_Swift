//
//  ElevatorResources.swift
//
//  Created by 조기현 on 2020/09/24.
//

import Foundation

struct Response: Codable {
	let token: String
	let timestamp: Int
	let elevators: [Elevator]
	let calls: [Call]?
	let is_end: Bool
}

struct Commands: Codable {
	let commands: [Command]
}


struct Elevator: Codable {
	let id: Int
	let floor: Int
	let passengers: [Call]
	let status: Status
	
	var isFull: Bool {
		passengers.count == 8
	}
	
	enum Status: String, Codable {
		case STOPPED, OPENED, UPWARD, DOWNWARD
	}
}


struct Call: Codable {
	let id: Int
	let timestamp: Int
	let start: Int
	let end: Int
}

struct Command: Codable {
	let elevator_id: Int
	let command: CommandType
	let call_ids: [Int]?
	
	enum CommandType: String, Codable {
		case STOP, UP, DOWN, OPEN, CLOSE, ENTER, EXIT
	}
}


