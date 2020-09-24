//
//  ElevatorSimulator.swift
//
//  Created by 조기현 on 2020/09/24.
//

import Foundation

class ElevatorSimulator {
	private let manager = SyncNetworkManager.shared

	private let user_key: String
	private let problem_id: Int
	private let number_of_elevator: Int
	
	private let number_of_floor: Int
	private var callsByFloor: [[Call]]

	private var token: String! = nil
	private lazy var tokenHeader: NetworkManager.Header = {
		NetworkManager.Header("X-Auth-Token", token)
	}()
	
	
	init(user_key: String, problem_id: Int, number_of_elevator: Int) {
		self.user_key = user_key
		self.problem_id = problem_id
		self.number_of_elevator = number_of_elevator
		
		if !(0...2).contains(problem_id) { fatalError() }
		switch problem_id {
		case 0: number_of_floor = 5
		default: number_of_floor = 25
		}
		callsByFloor = Array(repeating: [Call](), count: number_of_floor + 1)
	}
		
	private func start() -> Response {
		let pathComponents = ["start", user_key, "\(problem_id)", "\(number_of_elevator)"]
		let startRequest = manager.requestObject(pathComponents, .POST)
		return manager.request(startRequest)
	}
	
	private func onCalls() -> Response {
		let onCallsRequest = manager.requestObject(["oncalls"], .GET, [tokenHeader])
		return manager.request(onCallsRequest)
	}
	
	private func action(commands: Commands) {
		let body = try? JSONEncoder().encode(commands)
		if body == nil { fatalError() }
		let actionRequest = manager.requestObject(["action"], .POST, [tokenHeader], body)
		manager.request(actionRequest)
	}
	
	func simulate() {
		var response = start()
		token = response.token
		
		while true {
			response = onCalls()
			if response.is_end { break }

			response.calls?.forEach { call in
				if !callsByFloor[call.start].contains(where: {$0.id == call.id}){
					callsByFloor[call.start].append(call)
				}
			}
			
			var commands = [Command]()
			response.elevators.forEach { elevator in
				commands.append(makeAction(elevator: elevator))
			}
			action(commands: Commands(commands: commands))
		}
		
		print(response.timestamp)
	}
}

extension ElevatorSimulator {
	private func commandToStay(elevator: Elevator) -> Command.CommandType {
		switch elevator.status {
		case .DOWNWARD: return .DOWN
		case .OPENED: return .CLOSE
		case .STOPPED: return .STOP
		case .UPWARD: return .UP
		}
	}
	
	private func bestChoice(list: [Int], elevator: Elevator) -> Command.CommandType {
		if list.isEmpty { return commandToStay(elevator: elevator) }
		var minDist: Int = number_of_floor, val: Int = 0
		list.forEach { num in
			let dist = abs(num - elevator.floor)
			if minDist > dist {
				minDist = dist
				val = num
			}
		}
		if elevator.status == .OPENED { return .CLOSE }
		let best: Command.CommandType = elevator.floor > val ? .DOWN : .UP
		if elevator.status == .DOWNWARD && best == .UP || elevator.status == .UPWARD && best == .DOWN { return .STOP }
		return best
	}
	
	private func makeAction(elevator: Elevator) -> Command {
		// 현재 층에 승객 내리기
		let passengersToExitNow = elevator.passengers.filter{ $0.end == elevator.floor }
		if !passengersToExitNow.isEmpty {
			let command: Command.CommandType
			var call_ids: [Int]? = nil
			switch elevator.status {
			case .OPENED:
				command = .EXIT
				call_ids = passengersToExitNow.map { $0.id }
			case .STOPPED: command = .OPEN
			default: command = .STOP
			}
			return Command(elevator_id: elevator.id, command: command, call_ids: call_ids)
		}
		
		if elevator.isFull {
			let command: Command.CommandType
			switch elevator.status {
			case .OPENED: command = .CLOSE
			case .STOPPED: command = bestChoice(list: elevator.passengers.map{ $0.end }, elevator: elevator)
			case .DOWNWARD: command = .DOWN
			case .UPWARD: command = .UP
			}
			return Command(elevator_id: elevator.id, command: command, call_ids: nil)
		}
		
		// 현재 층에서 승객 태우기
		if !callsByFloor[elevator.floor].isEmpty {
			var passensersToEnter = callsByFloor[elevator.floor]
			let command: Command.CommandType
			var call_ids = [Int]()
			switch elevator.status {
			case .OPENED:
				command = .ENTER
				var space = 8 - elevator.passengers.count
				while space > 0 && !passensersToEnter.isEmpty {
					let id = passensersToEnter.removeLast().id
					call_ids.append(id)
					space -= 1
				}
				callsByFloor[elevator.floor] = passensersToEnter
			case .STOPPED: command = .OPEN
			default: command = .STOP
			}
			return Command(elevator_id: elevator.id, command: command, call_ids: call_ids)
		}
		
		if !elevator.passengers.isEmpty {
			let list = elevator.passengers.map{$0.end}
			return Command(elevator_id: elevator.id, command: bestChoice(list: list, elevator: elevator), call_ids: nil)
		}
		
		let list = Array(Set(callsByFloor.flatMap{$0}.map{$0.start}))
		return Command(elevator_id: elevator.id, command: bestChoice(list: list, elevator: elevator), call_ids: nil)
	}
}
