

import SwiftUI
let albumUrl = "https://jsonplaceholder.typicode.com/"
struct ContentView: View {
	@State var alertMessage = ""
	@State var isAlertShown = false
	@State var isLoading = true
	@State var todos: [Todo] = [
//		Todo(title: "Read Quran", isChecked: true, id: UUID()),
//		Todo(title: "Go shopping", isChecked: true, id: UUID()),
//		Todo(title: "Apple", isChecked: false, id: UUID()),
//		Todo(title: "Drink Milk", isChecked: false, id: UUID()),
//		Todo(title: "Do project", isChecked: false, id: UUID()),
//		Todo(title: "Make money", isChecked: false, id: UUID()),
	]
	
	var isCheckedTodos: [Todo] {
		return todos.filter({ todo in
			return todo.isChecked
		})
	}
	
	var isAppleTodos: [Todo] {
		return todos.filter({ todo in
			return todo.title.lowercased().contains("apple")
		})
	}
	
	func addNewTodo() async {
		let newTodo = Todo(title: "New todo", isChecked: false, id: UUID().uuidString)
		todos.append(newTodo)
		await upsertOneTodo(todo: newTodo)
	}
	
	func upsertOneTodo(todo: Todo) async {
		isLoading = true
		do {
			try await Task.sleep(nanoseconds: 1_000_000_000)
			let urlString = albumUrl + "/albums"
			let request = try urlString.toRequest(withBody: todo, method: "PUT")
			let result = try await callApi(request, to: DeleteTodoApiResponse.self)
			todos = result.newTodos
		} catch {
			print("Error: \(error)")
		}
		isLoading = false
	}
	
	
	func deleteOneTodo(todoId: String) async {
		isLoading = true
		do {
			try await Task.sleep(nanoseconds: 1_000_000_000)
			let urlString = albumUrl + "/albums" + todoId
			let request = try urlString.toDeleteRequest()
			let result = try await callApi(request, to: DeleteTodoApiResponse.self)
			todos = result.newTodos
			if !result.success {
				alertMessage = result.message
				isAlertShown = true
			}
			
		} catch {
			print("Error: \(error)")
		}
		isLoading = false
	}
 
	func fetchTodos() async {
		isLoading = true
		do {
			try await Task.sleep(nanoseconds: 1_000_000_000)
			let urlString = albumUrl + "/albums"
			let request = try urlString.toRequest()
			let apiTodos = try await callApi(request, to: [Todo].self)
			todos = apiTodos
		} catch {
			print("Error: \(error)")
		}
		isLoading = false
	}
	
    var body: some View {
		VStack {
			Text("Checked: \(isCheckedTodos.count)")
			Text("Apple: \(isAppleTodos.count)")
			Button("Add Todo") { Task { await addNewTodo() } }
			Button("Refresh") {
				Task {
					await fetchTodos()
				}
			}
			
			
			if (isLoading) {
				ProgressView()
			}
				
			
			List {
				ForEach(todos) { todo in
					TodoView(todo: todo, onTitleChange: { newTitle in
						guard let index = todos.firstIndex(where: { $0.id == todo.id }) else {
							return
						}
						
						let updatedTodo = Todo(title: newTitle, isChecked: todo.isChecked, id: todo.id)
						
						todos[index] = updatedTodo
						Task {
							await upsertOneTodo(todo: updatedTodo)
						}
					}, onIsCheckedChange: { newIsChecked in
						guard let index = todos.firstIndex(where: { $0.id == todo.id }) else {
							return
						}
						
						let updatedTodo = Todo(title: todo.title, isChecked: newIsChecked, id: todo.id)
						
						todos[index] = updatedTodo
						Task {
							await upsertOneTodo(todo: updatedTodo)
						}
					})
				}
				.onDelete { index in
					let deletedTodoId = index.map { todos[$0].id }.first ?? ""
					todos.remove(atOffsets: index)
					Task {
						await deleteOneTodo(todoId: deletedTodoId)
					}
				}
			}
			.alert(alertMessage, isPresented: $isAlertShown, actions: {})
		}
		
		.task {
			await fetchTodos()
		}
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Todo: Identifiable, Codable {
	let title: String
	let isChecked: Bool
	let id: String
}

struct DeleteTodoApiResponse: Codable {
	let success: Bool
	let newTodos: [Todo]
	let message: String
}

struct TodoView: View {
	let todo: Todo
	let onTitleChange: (String) -> Void
	let onIsCheckedChange: (Bool) -> Void
	@State var taskTitle = ""
	
	var body: some View  {
		HStack {
			TextField("", text: $taskTitle)
				.onChange(of: taskTitle) {
					onTitleChange($0)
				}
			
			Spacer()
			
			Image(systemName: todo.isChecked ? "checkmark.square" : "square")
				.foregroundColor(todo.isChecked ? .blue : .gray)
				.onTapGesture {
					onIsCheckedChange(!todo.isChecked)
				}
		}.onAppear {
			taskTitle = todo.title
		}
	}
}
