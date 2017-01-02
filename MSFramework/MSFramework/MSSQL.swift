//
//  MSSQL.swift
//  MSFramework
//
//  Created by Michael Schloss on 12/25/16.
//  Copyright © 2016 Michael Schloss. All rights reserved.
//

//MARK: - Constants

/**
 Use this constant **only** when the `WHERE` statement's comparator is `MSSQLEquivalence.isNull` or `MSSQLEquivalence.isNotNull`
 */
let WhereStatementComparesNullString = "Where Statement is comparing a null statement."

//MARK: - enums

/**
 Possible errors `MSSQL` could throw back at you
 */
public enum MSSQLError : Error
{
    /**
     This error is thrown when attribute == value
     */
    case whereConditionsCannotBeEqual
    
    /**
     This error is thrown when '*' is used
     */
    case cannotUseWildcardSpecifier
    
    /**
     This error is thrown when "" is used anywhere
     */
    case cannotUseEmptyValue
    
    /**
     This error is thrown when attribute or table character count exceeds 64 characters
     */
    case attributeLengthTooLong
    
    /**
     This error is thrown when the attributes count does not match the values count
     */
    case conditionsMustBeEqual
    
    /**
     This error is thrown when an SQL statement is attempting to be overwritten
     */
    case conditionAlreadyExists
    
    /**
     This error is thrown when MSSQL encounters a value it wasn't expecting.  This error is exclusively thrown during sanitization of malicious injections
     */
    case unexpectedValueFound
}

/**
 The possible conjunctions for `WHERE` statements
 
 - Note: `.none` does not insert " NONE" into the SQL Statement, it is used as a placeholder
 */
public enum MSSQLConjunction : String
{
    case and = " AND", or = " OR", none = " NONE", andNot = " AND NOT", orNot = " OR NOT"
}

/**
 The possible joins in SQL
 */
public enum MSSQLJoin : String
{
    /**
     Returns all rows from the left table and from the right table
     
     [Further Discussion](http://www.w3schools.com/Sql/sql_join_full.asp)
     */
    case full = " FULL OUTER"
    
    /**
     Returns all rows from both tables as long as there is a match between the columns in both tables.  Automatically determines the equivalent columns from each table
     
     [Further Discussion](http://www.w3resource.com/sql/joins/natural-join.php)
     */
    case natural = " NATURAL"
    
    /**
     Returns all rows from the left table, with the matching rows in the right table. The result is NULL in the right side when there is no match
     
     [Further Discussion](http://www.w3schools.com/Sql/sql_join_left.asp)
     */
    case left = " LEFT OUTER"
    
    /**
     Returns all rows from the right table, with the matching rows in the left table. The result is NULL in the left side when there is no match
     
     [Further Discussion](http://www.w3schools.com/Sql/sql_join_right.asp)
     */
    case right = " RIGHT OUTER"
    
    /**
     If no `WHERE` statement **is not** specified, this join returns all rows in the first table multiplied by all rows in the second table.  If a `WHERE` statement **is** specified, this join is synonymous with `.inner`
     
     [Further Discussion](http://www.w3resource.com/sql/joins/cross-join.php)
     */
    case cross = " CROSS"
    
    /**
     Returns all rows from both tables as long as there is a match between the columns in both tables.  The columns from each table to match must be specified
     
     [Further Discussion](http://www.w3schools.com/Sql/sql_join_inner.asp)
     */
    case inner = " INNER"
}

/**
 The possible comparators for `WHERE` statements
 */
public enum MSSQLEquivalence : String
{
    /**
     Single number comparator
     */
    case equals = "=", notEquals = "!=", lessThan = "<", greaterThan = ">", lessThanOrEqual = "<=", greaterThanOrEqual = ">="
    /**
     String comparator
     */
    case like = " LIKE ", notLike = " NOT LIKE "
    /**
     Number array comparator
     */
    case between = " BETWEEN ", notBetween = " NOT BETWEEN ", `in` = " IN ", notIn = " NOT IN "
    
    /**
     Value existence
     */
    case isNull = " IS NULL", isNotNull = " IS NOT NULL"
}

/**
 The possible directions an attribute can be ordered
 */
public enum MSSQLOrderBy : String
{
    /**
     Order direction
     */
    case ascending = " ASC", descending = " DESC"
}

//MARK: - Helper structs

/**
 A helper struct to combine an attribute-value pair
 */
public struct MSSQLClause
{
    /**
     The database table's attribute name
     */
    let attribute   : String
    
    /**
     The value in a row
     */
    let value       : String
}

/**
 Defines a `JOIN` statement
 */
public struct Join
{
    /**
     The table to join on
     */
    let table       : String
    
    /**
     The first table's attribute to join on
     */
    let tableOneAttribute   : String
    
    /**
     `.table`'s attribute to join on
     */
    let tableTwoAttribute       : String
}

fileprivate struct InternalJoin
{
    let joinType    : MSSQLJoin
    let table       : String
    let clause      : MSSQLClause
}

/**
 Defines an `ORDERED BY` statement
 */
public struct OrderBy
{
    /**
     The attribute to sort along
     */
    var attribute   : String
    
    /**
     The direction in which to order the specified attribute
     */
    var orderBy     : MSSQLOrderBy
}

/**
 Defines a `WHERE` statement i.e. "`WHERE` ...X..."
 
 - Note: Please use `WhereStatementComparesNullString` as the value of `.clause` if you plan to use `.isNull` or `isNotNull` for the equivalence
 */
public struct Where
{
    /**
     The conjunction to join this `WHERE` statement to the next one
     */
    let conjunction : MSSQLConjunction
    
    /**
     The equivalence comparator to compare the attribute and value
     */
    let equivalence : MSSQLEquivalence
    
    /**
     The attribute and value.
     
     - Note: Please use `WhereStatementComparesNullString` as the value if you plan to use `.isNull` or `isNotNull` for the equivalence
     */
    let clause      : MSSQLClause
}

//MARK: - SQL class

public final class MSSQL
{
    private     var selectRows          = [String]()
    private     var distinctSelect      = false
    private     var intoTable           = ""
    private     var inDB                = ""
    
    internal    var fromTables          = [String]()
    private     var joinStatements      = [InternalJoin]()
    private     var whereStatements     = [Where]()
    private     var orderByStatements   = [OrderBy]()
    
    private     var limitNum            = -1
    
    private     var insertRows          = [String]()
    private     var insertValues        = [String]()
    private     var duplicateKeys       = [String]()
    private     var duplicateValues     = [String]()
    
    private     var updateStatements    = [MSSQLClause]()
    
    internal    var appendedSQL         = [MSSQL]()
    
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
                let left = whereStatement.clause.attribute
                var right = whereStatement.clause.value
                
                if whereStatement.equivalence != .isNull && whereStatement.equivalence != .isNotNull
                {
                    
                    if right.contains(" ") || Int(right) == nil
                    {
                        right = "'" + right + "'"
                    }
                    
                    returnString += " " + left + whereStatement.equivalence.rawValue + right
                }
                else
                {
                    returnString += " " + left + whereStatement.equivalence.rawValue
                }
                
                if whereStatement.conjunction != .none
                {
                    returnString += whereStatement.conjunction.rawValue
                }
            }
            
            guard orderByStatements.isEmpty == false else { return }
            returnString += " ORDERED BY"
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
        
        //LIMIT
        func insertLimit()
        {
            guard limitNum > 0 else { return }
            
            returnString += " LIMIT \(limitNum)"
        }
        
        defer
        {
            insertAppendedStatements()
        }
        
        //UPDATE statements
        if updateStatements.isEmpty == false
        {
            guard fromTables.isEmpty == false && fromTables.count == 1 else { return returnString }
            
            returnString = "UPDATE `" + fromTables.first! + "` SET "
            
            for clause in updateStatements
            {
                let left = clause.attribute
                var right = clause.value
                
                if right.contains(" ") || Int(right) == nil
                {
                    right = "'" + right + "'"
                }
                
                returnString += left + "=" + right + ", "
            }
            
            returnString = (returnString as NSString).substring(to: returnString.characters.count - 2)
            
            insertWhereAndOrderByStatements()
            
            returnString += ";"
            
            //insertAppendedStatements()
            
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
            
            returnString = (returnString as NSString).substring(to: returnString.characters.count - 1) + ")"
            
            if duplicateKeys.isEmpty == false
            {
                returnString += " ON DUPLICATE KEY UPDATE "
                for row in duplicateKeys
                {
                    returnString += "`" + row + "`='\(duplicateValues[duplicateKeys.index(of: row)!])',"
                }
                
                returnString = (returnString as NSString).substring(to: returnString.characters.count - 1)
            }
            
            returnString += ";"
            
            return returnString
        }
        
        
        //REST OF THE STUFF
        guard selectRows.isEmpty == false else { return returnString }
        
        returnString = "SELECT "
        if distinctSelect == true
        {
            returnString += "DISTINCT "
        }
        for row in selectRows
        {
            if row.contains("(") == false && row.contains(")") == false
            {
                returnString += "`" + row + "`,"
            }
            else
            {
                returnString += row + ","
            }
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
                let left = join.clause.attribute
                var right = join.clause.value
                
                if right.contains(" ") || Int(right) == nil
                {
                    right = "'" + right + "'"
                }
                
                returnString += join.joinType.rawValue + " JOIN `" + join.table + (join.joinType != .natural ? ("` ON `" + left + "=" + right) : "`")
            }
        }
        
        insertWhereAndOrderByStatements()
        insertLimit()
        
        returnString += ";"
        
        //insertAppendedStatements()
        
        return returnString
    }
    
    private func check(_ attribute: String) throws
    {
        if attribute.contains("*")          { throw MSSQLError.cannotUseWildcardSpecifier }
        if attribute == ""                  { throw MSSQLError.cannotUseEmptyValue }
        
        let specifiers = ["=", "!=", "<", ">", " NATURAL", " OUTER", " CROSS", " INNER", ",", "\"", "'", " LIKE", " NOT", " ASC", " DESC", "SELECT ", "FROM ", "JOIN ", "WHERE ", "ORDER BY", "IN ", "BETWEEN ", " AND", " OR"]
        for specifier in specifiers
        {
            if attribute.uppercased().contains(specifier) { throw MSSQLError.unexpectedValueFound }
        }
        
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
    
    private func check(value: String, equivalence: MSSQLEquivalence = .lessThan) throws
    {
        if value == "" { throw MSSQLError.cannotUseEmptyValue }
        
        let specifiers : [String]
        if equivalence != .between && equivalence != .notBetween
        {
            
            specifiers = ["=", "!=", "<", ">", " NATURAL", " OUTER", " CROSS", " INNER", ",", "\"", "'", " LIKE", " NOT", " ASC", " DESC", "SELECT ", "FROM ", "JOIN ", "WHERE ", "ORDER BY", "IN ", "BETWEEN ", " AND", " OR"]
        }
        else
        {
            specifiers = ["=", "!=", "<", ">", " NATURAL", " OUTER", " CROSS", " INNER", ",", "\"", "'", " LIKE", " NOT", " ASC", " DESC", "SELECT ", "FROM ", "JOIN ", "WHERE ", "ORDER BY", "IN ", "BETWEEN ", " OR"]
        }
        for specifier in specifiers
        {
            if value.uppercased().contains(specifier) { throw MSSQLError.unexpectedValueFound }
        }
    }
    
    //MARK: SELECT Constructors
    
    /**
     SELECT statement with 1 row
     - Parameter attribute: the attribute to request
     - Parameter distinct: if the query should return only distinct rows or not.  Defaults to `false`
     - Parameter into: A table, if any, to copy(insert) this data into.  Defaults to `nil`
     - Parameter in: An exterior database, if any, the `into` table resides.  A value of `nil` assumes the current working database.  Defaults to `nil`
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError`: If no attribute specified, `*` is used, is empty, or is greater than 64 characters in length
     */
    public func select(_ attribute: String, distinct: Bool = false, into: String? = nil, `in`:String? = nil) throws -> MSSQL
    {
        guard selectRows.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        try check(attribute)
        
        distinctSelect = distinct
        selectRows = [attribute]
        
        if let intoT = into
        {
            guard intoTable == "" else { throw MSSQLError.conditionAlreadyExists }
            try check(intoT)
            intoTable = intoT
            
            if let inDatabase = `in`
            {
                guard inDB == "" else { throw MSSQLError.conditionAlreadyExists }
                try check(inDatabase)
                inDB = inDatabase
            }
        }
        
        return self
    }
    
    /**
     SELECT statement with multiple rows
     - Parameter attributes: the attributes to request
     - Parameter distinct: if the query should return only distinct rows or not.  Defaults to `false`
     - Parameter into: A table, if any, to copy(insert) this data into.  Defaults to `nil`
     - Parameter in: An exterior database, if any, the `into` table resides.  A value of `nil` assumes the current working database.  Defaults to `nil`
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError`: If no attributes specified, `*` is used, is empty, or any attribute is greater than 64 characters in length
     */
    public func select(_ attributes: [String], distinct: Bool = false, into: String? = nil, `in`: String? = nil) throws -> MSSQL
    {
        guard selectRows.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        for attribute in attributes
        {
            try check(attribute)
        }
        
        distinctSelect = distinct
        selectRows = attributes
        
        if let intoT = into
        {
            guard intoTable == "" else { throw MSSQLError.conditionAlreadyExists }
            try check(intoT)
            intoTable = intoT
            
            if let inDatabase = `in`
            {
                guard inDB == "" else { throw MSSQLError.conditionAlreadyExists }
                try check(inDatabase)
                inDB = inDatabase
            }
        }
        
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
        try check(table)
        
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
            try check(table)
        }
        
        fromTables = tables
        return self
    }
    
    //MARK: UPDATE SET Constructors
    
    /**
     UPDATE statement with one clause
     - Parameter table: The table to request
     - Parameter attribute: The left hand side of the clause
     - Parameter value: The right hand side of the clause
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is nil, already exists, `*` is used, is empty, or the `table` | `attribute` is greater than 64 characters in length
     */
    public func update(_ table: String, attribute: String, value: String) throws -> MSSQL
    {
        guard fromTables.isEmpty && updateStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        
        try check(table)
        try check(attribute)
        try check(value: value)
        
        fromTables = [table]
        
        updateStatements = [MSSQLClause(attribute: attribute, value: value)]
        
        return self
    }
    
    /**
     UPDATE statements with multiple clauses
     - Parameter table: The table to request
     - Parameter clauses: The clauses
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is nil, already exists, `*` is used, is empty, or the `table` | `attribute` of any clause is greater than 64 characters in length
     */
    public func update(_ table: String, set clauses: [MSSQLClause]) throws -> MSSQL
    {
        
        guard fromTables.isEmpty && updateStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        
        try check(table)
        for clause in clauses
        {
            try check(clause.attribute)
            try check(value: clause.value)
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
        
        try check(table)
        for attribute in attributes
        {
            try check(attribute)
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
    
    /**
     INSERT ... ON DUPLICATE KEY UPDATE Constructor
     
     Use this statement in conjuction with WHERE and/or LIMIT to specify which row to update if not 100% unique.
     
     - Parameter attributes: The attributes to update
     - Parameter values: The values to update to
     - Returns: An instance of `MSSQL`
     - Throws `MSSQLError` If a parameter is null, already exists, values and attributes do not match in size, `*` is used, is empty, or any attribute is greater than 64 characters in length
     */
    public func onDuplicateKey(attributes: [String], values: [String]) throws -> MSSQL
    {
        guard !insertRows.isEmpty && !insertValues.isEmpty && duplicateKeys.isEmpty && duplicateValues.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        
        for attribute in attributes
        {
            try check(attribute)
        }
        for value in values
        {
            try check(value: value)
        }
        
        duplicateKeys = attributes
        duplicateValues = values
        
        return self
    }
    
    //MARK: JOIN Constructors
    
    /**
     JOIN statement convenience method
     - Parameter table: the table to join on
     - Parameter attribute: the left hand side of the clause
     - Parameter value: the right hand side of the clause
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is null, already exists, `*` is used, is empty, or if the `table` | `attribute` is greater than 64 characters in length
     */
    public func join(_ join: MSSQLJoin, table: String, attribute: String, value: String) throws -> MSSQL
    {
        guard joinStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        
        try check(table)
        try check(attribute)
        try check(value: value)
        
        joinStatements = [InternalJoin(joinType: join, table: table, clause: MSSQLClause(attribute: attribute, value: value))]
        
        return self
    }
    
    /**
     JOIN statement convenience method
     - Parameter joins: The joins to make
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is null, already exists, `*` is used, is empty, or if the `table` | `attribute` of any `Join` is greater than 64 characters in length
     */
    public func join(_ join: MSSQLJoin, joins: [Join]) throws -> MSSQL
    {
        guard joinStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        
        for join in joins
        {
            try check(join.table)
            try check(join.tableOneAttribute)
            try check(value: join.tableTwoAttribute)
        }
        
        for joinn in joins
        {
            joinStatements.append(InternalJoin(joinType: join, table: joinn.table, clause: MSSQLClause(attribute: joinn.tableOneAttribute, value: joinn.tableTwoAttribute)))
        }
        
        return self
    }
    
    //MARK: WHERE Constructors
    
    /**
     WHERE ...X... statement
     - Note: Please use `WhereStatementComparesNullString` as the value if you plan to use `.isNull` or `isNotNull` for the equivalence
     - Parameter equivalence: The equivalence of the statement
     - Parameter attribute: The left hand side of the clause
     - Parameter value: The right hand side of the clause
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is null, already exists, `*` is used in an attribute, is empty, or the `attribute` is greater than 64 characters in length
     */
    public func `where`(_ equivalence: MSSQLEquivalence, attribute: String, value: String) throws -> MSSQL
    {
        guard whereStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        guard attribute != value else { throw MSSQLError.whereConditionsCannotBeEqual }
        try check(attribute)
        if value != WhereStatementComparesNullString
        {
            try check(value: value, equivalence: equivalence)
        }
        
        whereStatements = [Where(conjunction: .none, equivalence: equivalence, clause: MSSQLClause(attribute: attribute, value: value))]
        
        return self
    }
    
    /**
     WHERE ...X...[, ...X...] statement
     - Note: Please use `WhereStatementComparesNullString` as the value if you plan to use `.isNull` or `isNotNull` for the equivalence
     - Parameter equivalence: The equivalence of each statement
     - Parameter attribute: The left hand side of the clause
     - Parameter value: The right hand side of the clause
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is null, already exists, `*` is used in an attribute, is empty, or any `attribute` is greater than 64 characters in length
     */
    public func `where`(_ `where`: MSSQLConjunction, equivalence: MSSQLEquivalence, attributes: [String], values: [String]) throws -> MSSQL
    {
        guard whereStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        guard attributes.count == values.count else { throw MSSQLError.conditionsMustBeEqual }
        
        for attribute in attributes
        {
            try check(attribute)
        }
        for value in values
        {
            if value != WhereStatementComparesNullString
            {
                try check(value: value, equivalence: equivalence)
            }
        }
        
        for index in 0..<attributes.count - 1
        {
            let attribute = attributes[index]
            let value = values[index]
            guard attribute != value else { throw MSSQLError.whereConditionsCannotBeEqual }
            
            whereStatements.append(Where(conjunction: `where`, equivalence: equivalence, clause: MSSQLClause(attribute: attribute, value: value)))
        }
        
        whereStatements.append(Where(conjunction: .none, equivalence: equivalence, clause: MSSQLClause(attribute: attributes[attributes.count - 1], value: values[attributes.count - 1])))
        
        return self
    }
    
    /**
     WHERE ...X...[, ...Y...] statement
     - Note: Please use `WhereStatementComparesNullString` as the value if you plan to use `.isNull` or `isNotNull` for the equivalence
     - Parameter custom: A collection of `Where` structs.  The last `Where` struct **MUST** have `.none` as the conjunction
     - Returns: An instance of `MSSQL`
     - Throws: `MSSQLError` If a parameter is null, already exists, `*` is used as the `table` or `attribute` parameter of any `Where`, is empty, any `attribute` is greater than 64 characters in length, or if the last `Where` struct does not have `.none` as its conjunction
     */
    public func `where`(_ custom: [Where]) throws -> MSSQL
    {
        guard custom.isEmpty == false else { throw MSSQLError.cannotUseEmptyValue }
        guard whereStatements.isEmpty else { throw MSSQLError.conditionAlreadyExists }
        
        for `where` in custom
        {
            try check(`where`.clause.attribute)
            if `where`.clause.value != WhereStatementComparesNullString
            {
                try check(value: `where`.clause.value, equivalence: `where`.equivalence)
            }
            guard `where`.clause.attribute != `where`.clause.value else { throw MSSQLError.whereConditionsCannotBeEqual }
        }
        
        guard custom[custom.count - 1].conjunction == .none else { throw MSSQLError.unexpectedValueFound }
        
        whereStatements = custom
        
        return self
    }
    
    //MARK: ORDER BY Constructors
    
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
        try check(attribute)
        
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
            try check(att.attribute)
        }
        
        orderByStatements = attributes
        return self
    }
    
    //MARK: LIMIT Constructor
    
    /**
     LIMIT X statement
     
     Can only be used with SELECT statements
     - Parameter num: the limit of rows to return for display.  Must be greater than 0
     - Throws: `MSSQLError` if `num` is less than 1
     - Returns: An instance of `MSSQL`
     */
    public func limit(_ num: Int) throws -> MSSQL
    {
        guard limitNum < 1  else { throw MSSQLError.conditionAlreadyExists }
        guard num > 0       else { throw MSSQLError.unexpectedValueFound }
        
        limitNum = num
        return self
    }
}
