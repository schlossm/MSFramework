//
//  MSSQL.swift
//  MSFramework
//
//  Created by Michael Schloss on 12/25/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

//MARK: - enums

public enum MSSQLError : Error
{
    case whereConditionCountsNotEquivelent, whereConditionsCannotBeEmpty, conditionAlreadyExists, cannotUseWildcardSpecifier, cannotUseEmptyValue, attributeLengthTooLong, conditionsMustBeEqual, unexpectedValueFound
}

public enum MSSQLConjunction : String
{
    case and = " AND", or = " OR", none = " NONE"
}

public enum MSSQLJoin : String
{
    case full = " FULL OUTER", natural = " NATURAL", left = " LEFT OUTER", right = " RIGHT OUTER", cross = " CROSS", inner = " INNER"
}

public enum MSSQLEquivalence : String
{
    case equals = "=", notEquals = "!=", lessThan = "<", greaterThan = ">", lessThanOrEqual = "<=", greaterThanOrEqual = ">="
}

public enum MSSQLOrderBy : String
{
    case ascending = " ASC", descending = " DESC"
}

//MARK: - Helper structs

public struct MSSQLClause
{
    let leftHandSide    : String
    let rightHandSide   : String
}

public struct Join
{
    let table           : String
    let leftHandSide    : String
    let rightHandSide   : String
}

fileprivate struct InternalJoin
{
    let joinType    : MSSQLJoin
    let table       : String
    let clause      : MSSQLClause
}

public struct OrderBy
{
    var attribute   : String
    var orderBy     : MSSQLOrderBy
}

public struct Where
{
    let conjunction : MSSQLConjunction
    let equivalence : MSSQLEquivalence
    let clause      : MSSQLClause
}

//MARK: - SQL class

public final class MSSQL
{
    private     var selectRows          = [String]()
    internal    var fromTables          = [String]()
    private     var joinStatements      = [InternalJoin]()
    private     var whereStatements     = [Where]()
    
    private     var insertRows          = [String]()
    private     var insertValues        = [String]()
    
    private     var updateStatements    = [MSSQLClause]()
    internal    var appendedSQL         = [MSSQL]()
    
    private     var orderByStatements   = [OrderBy]()
    
    private     var distinctSELECT      = false
    
    var formattedStatement : String
    {
        return formatted()
    }
    
    public init() { }
    
    public func append(_ sqlStatement : MSSQL)
    {
        guard appendedSQL.contains(where: { (sql) -> Bool in
            return sql.formattedStatement == sqlStatement.formattedStatement
        }) == false else { return }
        appendedSQL.append(sqlStatement)
    }
    
    private func formatted() -> String
    {
        var returnString = ""
        
        
        //WHERE statements
        func insertWhereAndOrderByStatements()
        {
            guard whereStatements.isEmpty == false else { return }
            
            returnString += " WHERE"
            for whereStatement in whereStatements
            {
                let left = whereStatement.clause.leftHandSide
                var right = whereStatement.clause.rightHandSide
                
                if right.contains(" ") || Int(right) == nil
                {
                    right = "'" + right + "'"
                }
                
                returnString += " " + left + whereStatement.equivalence.rawValue + right
                
                if whereStatement.conjunction != .none
                {
                    returnString += whereStatement.conjunction.rawValue
                }
            }
            
            guard orderByStatements.isEmpty == false else { return }
            if orderByStatements.count == 1
            {
            for orderByStatement in orderByStatements
            {
                let attribute = orderByStatement.attribute
                let direction = orderByStatement.orderBy.rawValue
                
                returnString += " " + attribute + direction
            }
            }
            else
            {
                for index in 0..<orderByStatements.count - 1
                {
                    let orderByStatement = orderByStatements[index]
                    let attribute = orderByStatement.attribute
                    let direction = orderByStatement.orderBy.rawValue
                    
                    returnString += " " + attribute + direction + ","
                }
                let orderByStatement = orderByStatements[orderByStatements.count - 1]
                let attribute = orderByStatement.attribute
                let direction = orderByStatement.orderBy.rawValue
                
                returnString += " " + attribute + direction
            }
        }
        
        
        //APPENDED statements
        func insertAppendedStatements()
        {
            guard appendedSQL.isEmpty == false else { return }
            
            for statement in appendedSQL
            {
                returnString += " " + statement.formatted()
            }
        }
        
        
        //UPDATE statements
        if updateStatements.isEmpty == false
        {
            guard fromTables.isEmpty == false && fromTables.count == 1 else { return returnString }
            
            returnString = "UPDATE `" + fromTables.first! + "` SET "
            
            for clause in updateStatements
            {
                let left = clause.leftHandSide
                var right = clause.rightHandSide
                
                if right.contains(" ") || Int(right) == nil
                {
                    right = "'" + right + "'"
                }
                
                returnString += left + "=" + right + ", "
            }
            
            returnString = (returnString as NSString).substring(to: returnString.characters.count - 2)
            
            insertWhereAndOrderByStatements()
            
            returnString += ";"
            
            insertAppendedStatements()
            
            return returnString
        }
        
        //INSERT STATEMENTS
        if insertRows.isEmpty == false
        {
            guard fromTables.isEmpty == false && fromTables.count == 1 else { return returnString }
            
            returnString = "INSERT INTO `" + fromTables.first! + "`("
            for row in insertRows
            {
                returnString += "`" + row + "`,"
            }
            
            returnString = (returnString as NSString).substring(to: returnString.characters.count - 1) + ") VALUES ("
            
            for value in insertValues
            {
                if value.contains(" ") || Int(value) == nil
                {
                    returnString += "'" + value + "',"
                }
                else
                {
                    returnString += value + ","
                }
            }
            
            returnString = (returnString as NSString).substring(to: returnString.characters.count - 1) + ");"
            
            insertAppendedStatements()
            
            return returnString
        }
        
        
        //REST OF THE STUFF
        guard selectRows.isEmpty == false else { return returnString }
        
        returnString = "SELECT "
        if distinctSELECT == true
        {
            returnString += "DISTINCT "
        }
        for row in selectRows
        {
            returnString += "`" + row + "`,"
        }
        
        returnString = (returnString as NSString).substring(to: returnString.characters.count - 1) + " FROM "
        
        for table in fromTables
        {
            returnString += "`" + table + "`,"
        }
        
        returnString = (returnString as NSString).substring(to: returnString.characters.count - 1)
        
        if joinStatements.isEmpty == false
        {
            for join in joinStatements
            {
                let left = join.clause.leftHandSide
                var right = join.clause.rightHandSide
                
                if right.contains(" ") || Int(right) == nil
                {
                    right = "'" + right + "'"
                }
                
                returnString += join.joinType.rawValue + " JOIN `" + join.table + (join.joinType != .natural ? ("` ON `" + left + "=" + right) : "`")
            }
        }
        
        insertWhereAndOrderByStatements()
        
        returnString += ";"
        
        insertAppendedStatements()
        
        return returnString
    }
    
    private func check(attribute: String) throws
    {
        if attribute.contains("*")          { throw MSSQLError.cannotUseWildcardSpecifier }
        if attribute == ""                  { throw MSSQLError.cannotUseEmptyValue }
        
        switch attribute.contains(".")
        {
        case false:
            if attribute.characters.count > 64  { throw MSSQLError.attributeLengthTooLong }
            
        case true:
            let components = attribute.components(separatedBy: ".")
            let table = components[0]
            let row = components[1]
            
            if table.contains("`")
            {
                if table.characters.count > 66  { throw MSSQLError.attributeLengthTooLong }
            }
            else
            {
                if table.characters.count > 64  { throw MSSQLError.attributeLengthTooLong }
            }
            
            if row.characters.count > 64  { throw MSSQLError.attributeLengthTooLong }
        }
    }
    
    private func check(value: String) throws
    {
        if value == "" { throw MSSQLError.cannotUseEmptyValue }
    }
    
    //MARK: SELECT Constructors
    
    /**
     SELECT statement with 1 row
     - Parameter attribute: the attribute to request
     - Parameter distinct: if the query should return only distinct rows or not.  Defaults to `false`
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError`: If no attribute specified, `*` is used, is empty, or is greater than 64 characters in length
     */
    public func select(_ attribute: String, distinct: Bool = false) throws -> MSSQL
    {
        guard selectRows.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        try check(attribute: attribute)
        
        distinctSELECT = distinct
        selectRows = [attribute]
        return self
    }
    
    /**
     SELECT statement with multiple rows
     - Parameter attributes: the attributes to request
     - Parameter distinct: if the query should return only distinct rows or not.  Defaults to `false`
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError`: If no attributes specified, `*` is used, is empty, or any attribute is greater than 64 characters in length
     */
    public func select(_ attributes: [String], distinct: Bool = false) throws -> MSSQL
    {
        guard selectRows.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        for attribute in attributes
        {
            try check(attribute: attribute)
        }
        
        distinctSELECT = distinct
        selectRows = attributes
        return self
    }
    
    //MARK: FROM Constructors
    
    /**
     FROM statement with one table
     - Parameter table: the table to request
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If no table specified, `*` is used, is empty, or table is greater than 64 characters in length
     */
    public func from(_ table: String) throws -> MSSQL
    {
        guard fromTables.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        try check(attribute: table)
        
        fromTables = [table]
        return self
    }
    
    /**
     FROM statement with multiple tables
     - Parameter tables: the tables to request
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If no tables specified, `*` is used, is empty, or if any table is greater than 64 characters in length
     */
    public func from(_ tables: [String]) throws -> MSSQL
    {
        guard fromTables.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        
        for table in tables
        {
            try check(attribute: table)
        }
        
        fromTables = tables
        return self
    }
    
    //MARK: UPDATE SET Constructors
    
    /**
     UPDATE statement with one clause
     - Parameter table: The table to request
     - Parameter leftHandSide: The left hand side of the clause
     - Parameter rightHandSide: The right hand side of the clause
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is nil, already exists, `*` is used, is empty, or the `table` | `leftHandSide` is greater than 64 characters in length
     */
    public func update(_ table: String, leftHandSide: String, rightHandSide: String) throws -> MSSQL
    {
        guard fromTables.isEmpty && updateStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        
        try check(attribute: table)
        try check(attribute: leftHandSide)
        try check(value: rightHandSide)
        
        fromTables = [table]
        
        updateStatements = [MSSQLClause(leftHandSide: leftHandSide, rightHandSide: rightHandSide)]
        
        return self
    }
    
    /**
     UPDATE statements with multiple clauses
     - Parameter table: The table to request
     - Parameter clauses: The clauses
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is nil, already exists, `*` is used, is empty, or the `table` | `leftHandSide` of any clause is greater than 64 characters in length
     */
    public func update(_ table: String, set clauses: [MSSQLClause]) throws -> MSSQL
    {
        
        guard fromTables.isEmpty && updateStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        
        try check(attribute: table)
        for clause in clauses
        {
            try check(attribute: clause.leftHandSide)
            try check(value: clause.rightHandSide)
        }
        
        fromTables = [table]
        updateStatements = clauses
        
        return self
    }
    
    //MARK: INSERT INTO Constructor
    
    /**
     INSERT INTO statement
     - Parameter table: the table to insert the new row into
     - Parameter values: the values for entry
     - Parameter attributes: the attributes to set
     - Returns: An instance of `MSSQL`
     - Throws `MSSQLError` If a parameter is null, already exists, values and attributes do not match in size, `*` is used, is empty, or any attribute | table is greater than 64 characters in length
     */
    public func insert(_ table: String, values: [String], attributes: [String]) throws -> MSSQL
    {
        guard fromTables.isEmpty && insertRows.isEmpty && insertValues.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        
        try check(attribute: table)
        for attribute in attributes
        {
            try check(attribute: attribute)
        }
        
        for value in values
        {
            try check(value: value)
        }
        
        fromTables = [table]
        insertRows = attributes
        insertValues = values
        
        return self
    }
    
    //MARK: JOIN Constructors
    
    /**
     JOIN statement convenience method
     - Parameter table: the table to join on
     - Parameter leftHandSide: the left hand side of the clause
     - Parameter rightHandSide: the right hand side of the clause
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is null, already exists, `*` is used, is empty, or if the `table` | `leftHandSide` is greater than 64 characters in length
     */
    public func join(_ join: MSSQLJoin, table: String, leftHandSide: String, rightHandSide: String) throws -> MSSQL
    {
        guard joinStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        
        try check(attribute: table)
        try check(attribute: leftHandSide)
        try check(value: rightHandSide)
        
        joinStatements = [InternalJoin(joinType: join, table: table, clause: MSSQLClause(leftHandSide: leftHandSide, rightHandSide: rightHandSide))]
        
        return self
    }
    
    /**
     JOIN statement convenience method
     - Parameter joins: The joins to make
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is null, already exists, `*` is used, is empty, or if the `table` | `leftHandSide` of any `Join` is greater than 64 characters in length
     */
    public func join(_ join: MSSQLJoin, joins: [Join]) throws -> MSSQL
    {
        guard joinStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        
        for join in joins
        {
            try check(attribute: join.table)
            try check(attribute: join.leftHandSide)
            try check(value: join.rightHandSide)
        }
        
        for joinn in joins
        {
            joinStatements.append(InternalJoin(joinType: join, table: joinn.table, clause: MSSQLClause(leftHandSide: joinn.leftHandSide, rightHandSide: joinn.rightHandSide)))
        }
        
        return self
    }
    
    //MARK: WHERE Constructors
    
    /**
     WHERE ...X... statement
     - Parameter equivalence: The equivalence of the statement
     - Parameter leftHandSide: The left hand side of the clause
     - Parameter rightHandSide: The right hand side of the clause
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is null, already exists, `*` is used in an attribute, is empty, or the `leftHandSide` is greater than 64 characters in length
     */
    public func `where`(_ equivalence: MSSQLEquivalence, leftHandSide: String, rightHandSide: String) throws -> MSSQL
    {
        guard whereStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        try check(attribute: leftHandSide)
        try check(value: rightHandSide)
        
        whereStatements = [Where(conjunction: .none, equivalence: equivalence, clause: MSSQLClause(leftHandSide: leftHandSide, rightHandSide: rightHandSide))]
        
        return self
    }
    
    /**
     WHERE ...X...[, ...X...] statement
     - Parameter equivalence: The equivalence of each statement
     - Parameter leftHandSide: The left hand side of the clause
     - Parameter rightHandSide: The right hand side of the clause
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is null, already exists, `*` is used in an attribute, is empty, or any `leftHandSide` is greater than 64 characters in length
     */
    public func `where`(_ `where`: MSSQLConjunction, equivalence: MSSQLEquivalence, leftHandSides: [String], rightHandSides: [String]) throws -> MSSQL
    {
        guard whereStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        guard leftHandSides.count == rightHandSides.count else { throw MSSQLError.conditionsMustBeEqual }
        
        for leftHandSide in leftHandSides
        {
            try check(attribute: leftHandSide)
        }
        for rightHandSide in rightHandSides
        {
            try check(value: rightHandSide)
        }
        
        for index in 0..<leftHandSides.count - 1
        {
            let leftHandSide = leftHandSides[index]
            let rightHandSide = rightHandSides[index]
            
            whereStatements.append(Where(conjunction: `where`, equivalence: equivalence, clause: MSSQLClause(leftHandSide: leftHandSide, rightHandSide: rightHandSide)))
        }
        
        whereStatements.append(Where(conjunction: .none, equivalence: equivalence, clause: MSSQLClause(leftHandSide: leftHandSides[leftHandSides.count - 1], rightHandSide: rightHandSides[leftHandSides.count - 1])))
        
        return self
    }
    
    /**
     WHERE ...X...[, ...X...] statement
     - Parameter custom: A collection of `Where` structs.  The last `Where` struct **MUST** have `.none` as the conjunction
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is null, already exists, `*` is used as the `table` or `leftHandSide` parameter of any `Where`, is empty, any `leftHandSide` is greater than 64 characters in length, or if the last `Where` struct does not have `.none` as its conjunction
     */
    public func `where`(custom: [Where]) throws -> MSSQL
    {
        guard custom.isEmpty == false else { throw MSSQLError.cannotUseEmptyValue }
        guard whereStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        
        for `where` in custom
        {
            try check(attribute: `where`.clause.leftHandSide)
            try check(value: `where`.clause.rightHandSide)
        }
        
        guard custom[custom.count - 1].conjunction == .none else { throw MSSQLError.unexpectedValueFound }
        
        whereStatements = custom
        
        return self
    }
    
    /**
     ORDER BY ... ASC|DESC statement
     - Parameter attribute: The attribute to order by
     - Parameter direction: Order ascending or descending
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is null, already exists, `*` is used as the `attribute` parameter, is empty, the `attribute` is greater than 64 characters in length
     */
    public func orderBy(_ attribute: String, direction: MSSQLOrderBy) throws -> MSSQL
    {
        guard orderByStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        try check(attribute: attribute)
        
        orderByStatements = [OrderBy(attribute: attribute, orderBy: direction)]
        return self
    }
    
    /**
     ORDER BY ... ASC|DESC[, ... ASC|DESC] statement
     - Parameter attributes: The attributes and directions to order by
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is null, already exists, `*` is used as the `attribute` parameter of any `OrderBy`, is empty, the `attribute` of any `OrderBy` is greater than 64 characters in length
     */
    public func orderBy(_ attributes: [OrderBy]) throws -> MSSQL
    {
        guard orderByStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        for att in attributes
        {
            try check(attribute: att.attribute)
        }
        
        orderByStatements = attributes
        return self
    }
}
