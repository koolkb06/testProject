import Foundation

extension TodoItem: TodoOrderable {
    var orderDate: Date { dueDate ?? createdAt }
}
