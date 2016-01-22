//
//  MSSQL.swift
//  NicholsApp
//
//  Created by Michael Schloss on 6/27/15.
//  Copyright © 2015 Michael Schloss. All rights reserved.
//

import UIKit

enum MSSQLError : ErrorType
{
    case WhereConditionCountsNotEquivelent, WhereConditionsCannotBeEmpty, ConditionAlreadyExists
}

///Class for building an SQL formatted statement.
public class MSSQL
{
    private var selectStatement : String!
    private var fromStatement: String!
    private var whereStatement : String!
    private var joinStatement : String!
    
    private var rawSQLStatement: String!
    
    var prettySQLStatement : String
        {
        get
        {
            if rawSQLStatement != nil
            {
                return rawSQLStatement
            }
            
            var returnStatement = "SELECT \(selectStatement) FROM `\(fromStatement)`"
            
            if joinStatement != nil
            {
                returnStatement += " \(joinStatement)"
            }
            
            if whereStatement != nil
            {
                returnStatement += " WHERE \(whereStatement)"
            }
            
            return returnStatement
        }
    }
    
    init()
    {
        
    }
    
    ///Takes a raw SQL statment and disables appending statements
    init(rawSQL: String)
    {
        rawSQLStatement = rawSQL
        
        selectStatement = "N/A"
        fromStatement = "N/A"
        whereStatement = "N/A"
        joinStatement = "N/A"
    }
    
    ///`SELECT` statement for multiple rows
    ///- Parameter rows: An array of table rows
    func select(rows: [String]) -> MSSQL
    {
        var rowsString = ""
        for row in rows
        {
            rowsString += "\(row),"
        }
        
        rowsString = rowsString.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: ", "))
        selectStatement = rowsString
        
        return self
    }
    
    ///Convenience `SELECT` statement for a single row
    ///- Parameter row: A single row to be selected
    func select(row: String) -> MSSQL
    {
        selectStatement = row
        return self
    }
    
    ///Convenience `SELECT` statement for all rows
    func select() -> MSSQL
    {
        selectStatement = "*"
        return self
    }
    
    ///`FROM` statement for a Table
    ///- Parameter table: The table to use to lookup row data
    func from(table: String) -> MSSQL
    {
        fromStatement = table
        
        return self
    }
    
    ///`WHERE` statement using `AND` as the joining operator
    ///- Throws: `WhereConditionsCannotBeEmpty:`    Thrown if any of the arrays are empty<br><br>
    ///`WhereConditionCountsNotEquivelent:`    Thrown if the arrays do not have the same number of entries<br><br>
    ///`ConditionAlreadyExists:`    Thrown if a `WHERE` statement is already constructed
    ///- Parameter lhs: The left hand conditions
    ///- Parameter rhs: The right hand contitions
    func whereAND(lhs: [String], _ rhs: [String]) throws -> MSSQL
    {
        guard self.whereStatement == nil else { throw MSSQLError.ConditionAlreadyExists }
        guard lhs.isEmpty == false && rhs.isEmpty == false else { throw MSSQLError.WhereConditionsCannotBeEmpty }
        guard lhs.count == rhs.count else { throw MSSQLError.WhereConditionCountsNotEquivelent }
        
        var whereStatement = "`\(lhs[0])`='\(rhs[0])' "
        
        if lhs.count > 1
        {
            for index in 1...(lhs.count - 1)
            {
                whereStatement += "AND `\(lhs[index])`='\(rhs[index])' "
            }
        }
        
        self.whereStatement = whereStatement
        
        return self
    }
    
    ///`WHERE` statement using `OR` as the joining operator
    ///- Throws: `WhereConditionsCannotBeEmpty:`    Thrown if any of the arrays are empty<br><br>
    ///`WhereConditionCountsNotEquivelent:`    Thrown if the arrays do not have the same number of entries<br><br>
    ///`ConditionAlreadyExists:`    Thrown if a `WHERE` statement is already constructed
    ///- Parameter lhs: The left hand conditions
    ///- Parameter rhs: The right hand contitions
    func whereOR(lhs: [String], _ rhs: [String]) throws -> MSSQL
    {
        guard self.whereStatement == nil else { throw MSSQLError.ConditionAlreadyExists }
        guard lhs.count == rhs.count else { throw MSSQLError.WhereConditionCountsNotEquivelent }
        guard lhs.isEmpty == false && rhs.isEmpty == false else { throw MSSQLError.WhereConditionsCannotBeEmpty }
        
        var whereStatement = "`\(lhs[0])`='\(rhs[0])' "
        
        if lhs.count > 1
        {
            for index in 1...(lhs.count - 1)
            {
                whereStatement += "OR `\(lhs[index])`='\(rhs[index])' "
            }
        }
        
        self.whereStatement = whereStatement
        
        return self
    }

    ///`WHERE` statement with single `=` comparator
    ///- Throws: `ConditionAlreadyExists:`    Thrown if a `WHERE` statement is already constructed
    ///- Parameter lhs: The left hand condition
    ///- Parameter rhs: The right hand contition
    func whereEquals(lhs: String, _ rhs: String) throws -> MSSQL
    {
        guard self.whereStatement == nil else { throw MSSQLError.ConditionAlreadyExists }
        whereStatement = "`\(lhs)`='\(rhs)'"
        
        return self
    }
    
    ///Convenience `JOIN` Statement for `INNER JOIN`
    ///- Throws: `ConditionAlreadyExists:`    Thrown if a `JOIN` statement is already constructed
    ///- Parameter table: The table to join on
    ///- Parameter firstCondition: The left hand contition
    ///- Parameter secondCondition: The right hand contition
    func joinON(table: String, onfirstCondition firstCondition: String, _ secondCondition: String) throws -> MSSQL
    {
        guard joinStatement == nil else { throw MSSQLError.ConditionAlreadyExists }
        
        joinStatement = "JOIN \(table) ON \(firstCondition)=\(secondCondition)"
        return self
    }
    
    ///`INNER JOIN` Statement
    ///- Throws: `ConditionAlreadyExists:`    Thrown if a `JOIN` statement is already constructed
    ///- Parameter table: The table to join on
    ///- Parameter firstCondition: The left hand contition
    ///- Parameter secondCondition: The right hand contition
    func innerJoin(table: String, onfirstCondition firstCondition: String, _ secondCondition: String) throws -> MSSQL
    {
        guard joinStatement == nil else { throw MSSQLError.ConditionAlreadyExists }
        
        joinStatement = "INNER JOIN \(table) ON \(firstCondition)=\(secondCondition)"
        return self
    }
    
    ///`LEFT JOIN` Statement
    ///- Throws: `ConditionAlreadyExists:`    Thrown if a `JOIN` statement is already constructed
    ///- Parameter table: The table to join on
    ///- Parameter firstCondition: The left hand contition
    ///- Parameter secondCondition: The right hand contition
    func leftJoin(table: String, onfirstCondition firstCondition: String, _ secondCondition: String) throws -> MSSQL
    {
        guard joinStatement == nil else { throw MSSQLError.ConditionAlreadyExists }
        
        joinStatement = "LEFT JOIN \(table) ON \(firstCondition)=\(secondCondition)"
        return self
    }
    
    ///`RIGHT JOIN` Statement
    ///- Throws: `ConditionAlreadyExists:`    Thrown if a `JOIN` statement is already constructed
    ///- Parameter table: The table to join on
    ///- Parameter firstCondition: The left hand contition
    ///- Parameter secondCondition: The right hand contition
    func rightJoin(table: String, onfirstCondition firstCondition: String, _ secondCondition: String) throws -> MSSQL
    {
        guard joinStatement == nil else { throw MSSQLError.ConditionAlreadyExists }
        
        joinStatement = "RIGHT JOIN \(table) ON \(firstCondition)=\(secondCondition)"
        return self
    }
    
    ///`FULL JOIN` Statement
    ///- Throws: `ConditionAlreadyExists:`    Thrown if a `JOIN` statement is already constructed
    ///- Parameter table: The table to join on
    ///- Parameter firstCondition: The left hand contition
    ///- Parameter secondCondition: The right hand contition
    func fullJoin(table: String, onfirstCondition firstCondition: String, _ secondCondition: String) throws -> MSSQL
    {
        guard joinStatement == nil else { throw MSSQLError.ConditionAlreadyExists }
        
        joinStatement = "FULL JOIN \(table) ON \(firstCondition)=\(secondCondition)"
        
        return self
    }
}

func += (inout lhs: MSSQL, rhs: MSSQL)
{
    if lhs.prettySQLStatement == "SELECT nil FROM `nil`"
    {
        lhs = MSSQL(rawSQL: "\(rhs.prettySQLStatement)")
    }
    else
    {
        lhs = MSSQL(rawSQL: "\(lhs.prettySQLStatement); \(rhs.prettySQLStatement)")
    }
}

func + (lhs: MSSQL, rhs: MSSQL) -> MSSQL
{
    return MSSQL(rawSQL: "\(lhs.prettySQLStatement); \(rhs.prettySQLStatement)")
}
