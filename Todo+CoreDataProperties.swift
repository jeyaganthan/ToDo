//
//  Todo+CoreDataProperties.swift
//  EverydayTodo
//
//  Created by Jeyaganthan on 2021/01/14.
//
//

import Foundation
import CoreData


extension Todo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Todo> {
        return NSFetchRequest<Todo>(entityName: "Todo")
    }

    @NSManaged public var date: Date?
    @NSManaged public var detail: String?
    @NSManaged public var id: Int64
    @NSManaged public var isDone: Bool
    @NSManaged public var isAlarmOn: Bool

}

extension Todo : Identifiable {

}
