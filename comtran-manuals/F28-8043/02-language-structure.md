# Chapter 2: The Structure of the Language

<!-- page 11 | PDF 17 -->
**[page 11]**

## Underlying Principles

The structure of the Commercial Translator language is very much like that of English. It has, first of all, a basic vocabulary, consisting of words and symbols. Next, it has a set of basic rules of "grammar" or "syntax" by which the words and symbols may be combined to express meanings. Finally, it has punctuation symbols to clarify the groupings of words and symbols so that their meanings will be unmistakably clear.

The Commercial Translator language is much simpler than English, for its requirements are more limited and more precise. Since it is a programming language, it must have the capacity to state facts and give instructions. It must be clear and specific; it does not require the ability to express delicate shades of meaning. The Commercial Translator is a language of action—a language for getting things done—and it therefore consists largely of verbs and nouns. The verbs direct the system to take action of various kinds; the nouns name the data and the procedures on which action is to be taken.

As in English, verbs and nouns may be combined into clauses and sentences so that meanings may be clearly defined. A number of typical Commercial Translator sentences have been examined in Chapter 1 of this manual. The reader will thus have discovered that he can usually tell what a Commercial Translator sentence means merely by reading it, although at this point he may not know the rules for writing such a sentence or the ways in which a sentence can be used in a program. It is the purpose of this chapter to describe the basic components of the language and to show the rules for combining them to express meanings.

<!-- page 12 | PDF 18 -->
**[page 12]**

## Character Set

The words and symbols of the Commercial Translator language are the basic units with which the programmer will work, but he should understand that they in turn are composed of individual letters, numbers, and special characters—in short the basic character set. This set consists of the 26 letters of the alphabet, the ten numerals from 0 to 9, and the special characters shown in the table below.

**Special Characters Used in the Commercial Translator Source Language**

| Name | Character (Set H*) | Card Code |
|---|---|---|
| blank | | (blank) |
| plus sign | + | 12 |
| minus sign | - | 11 |
| multiplication sign | * | 11-4-8 |
| division sign | / | 0-1 |
| left parenthesis | ( | 0-4-8 |
| right parenthesis | ) | 12-4-8 |
| comma | , | 0-3-8 |
| period / decimal point | . | 12-3-8 |
| dollar sign | $ | 11-3-8 |
| equal sign | = | 3-8 |
| quotation mark | ' | 4-8 |

Notes —

1. Set H is one of several character sets available for IBM equipment. All sets use the same card codes, but in the case of special characters, one code may represent one character in one set and another character in another set. For example a "12" punch indicates a plus sign in Set H, while in certain other sets it represents an ampersand. The Commercial Translator system employs the codes of Set H, shown above.

The uses of these characters will be explained subsequently in this manual. The reader should note that the blank is treated as a character, but that a series of blanks will be regarded as a single blank, except in alphameric literals or other constants.

## Verbs

In the Commercial Translator language, a verb is a word that prescribes an action. Verbs are not used in a declarative sense in the language, and the programmer should recognize from the start that everything he writes will produce some kind of effect.

The prescribed action may not take place at the time the object program is run. In fact, a number of verbs give instructions which the processor will carry out at the time the object program is assembled. For example, as the programmer analyzes a data processing problem he may recognize that it contains elements which he has already handled in solving previous problems. If so, he may have written program "routines" that can now be used again. If such a routine has been stored in a "library," the programmer may be able to call for it by using the verb INCLUDE, as explained in Chapter 3 of this manual. This verb, therefore, may be used in building the object program, but it will not be used as a part of the object program itself. Verbs which act on the processor when the source program is translated are called *processor verbs.*

However, most of the verbs the programmer will write will cause some action at "object time"—i.e., at the time the object program is run.

<!-- page 13 | PDF 19 -->
**[page 13]**

Thus, the verb ADD will cause two or more items of data to be added together, the verb DISPLAY will cause specified information to be printed or otherwise displayed, and the verb STOP will cause the machine to halt. Verbs which act at object time are known as *program verbs.*

### Operators

Not all words that cause action are verbs. For instance, the reader will learn later in this chapter how to order that a given action be carried out only if a certain condition is met. Consider the sentence IF A = B THEN MOVE A TO OUTPUT. This sentence contains only one verb, the word MOVE, yet it implies two separate operations. The MOVE operation, of course, is one of them; the other is a test to determine if the condition A = B has been met. However, the programmer does not have to write a verb directing the program to test for this condition, for the word IF serves the purpose. The Commercial Translator language contains several words and symbols (such as the arithmetic symbols) which are not verbs but which cause operations. They are called *operators.*

It is necessary to distinguish between verbs and operators, since they are used in different ways. Commercial Translator verbs may be easily recognized by the fact that all of them are words which serve also as verbs in the English language.

For a general indication of how verbs are used, the reader may refer to any of the examples used in Chapter 1. The specific rules governing each verb will be found in Chapter 3.

## Names

Most of the words in a typical Commercial Translator program will be nouns. A noun, in the strictest sense, is a *name,* and the programmer will find it very useful to accept that definition and all of its implications. He will write procedures for handling data, but he will refer to the procedures and the data by name. He will rarely work with actual data, and he will never write actual machine instructions.

This is an important concept. As will be seen in Chapter 4, an electronic system has no way of recognizing data and procedures simply by looking at them. They can be identified only by their location within storage, and in the Commercial Translator system these storage locations are referred to by name. For this reason, Commercial Translator nouns will be spoken of hereafter as names.

### Kinds of Names

Most of the names the programmer will use will fall into one of three general categories: *data-names, procedure-names,* and *condition-names.*

#### Data-Names

Data-names are names given to the data used in a program. As the programmer will see, data-names are assigned to *kinds* of data, not (except in the case of constants) to specific values. Thus, such a name as INTEREST.RATE would not refer to a specific interest rate, but to a class of data known as interest rates. Technically (although this need not concern the programmer), it would name an area in storage in which any of several specific interest rates might be placed for some purpose, such as computation.

Data-names may be assigned to single classes of data or to groups of data items. For example, the name PAYROLL.RECORD would probably refer to a group of individual items having such names as EMPLOYEE.NAME, EMPLOYEE.NUMBER, HOURLY.RATE, and so on. It is important to recognize that, in general, the name refers not to any specific value, but only to the kind of data.

<!-- page 14 | PDF 20 -->
**[page 14]**

Data-names are invented and assigned to data at the discretion of the programmer, following the rules given below which govern the formation of names. All data referred to in the program must be named, but this does not mean that all subdivisions of data must be named. For example, if the programmer wishes to refer to a date, he will have to give it a name, but he does not have to name the component parts, such as the day, the month, or the year, unless he wishes to refer to them individually.

The general category of data-names may be broken down, for convenience, into record-names, field-names, function-names, parameter-names, named constants, and so on. The meanings of these names will be explained later in this manual.

#### Procedure-Names

Procedure-names are names assigned to individual portions of the program so that one procedure can refer to another. Suppose, for instance, that the programmer has written a routine for computing a discount and that he wishes to use this routine at various times in the program. He could actually copy the routine into the program each time it is required, but this may be inefficient. An alternative method would be to give the routine a name, such as DISCOUNT, or DISCOUNT.CALCULATION; then, when the programmer wished to use this routine he could write such an instruction as DO DISCOUNT.CALCULATION. As the reader will discover, there are many reasons why the programmer may wish to refer from one part of the program to another. Procedure-names provide him with the means of doing this.

Like data-names, procedure-names are invented and assigned by the programmer as he needs them, following the rules for name formation given below. They are placed at the beginning of the portion of the program to which they apply.

Procedure-names may be assigned to any sentence or section of the program. (A section consists of one or more successive sentences.) The reader will find further details of how to use procedure-names in Chapter 3 in the discussion of the commands DO, GO TO, INCLUDE, OVERLAP, BEGIN SECTION, and END. Procedure-names may also be referred to as sentence-names or section-names, as appropriate.

#### Condition-Names

The concept of condition-names will be more clearly understood after the reader has studied the discussion of conditional expressions beginning on page 21 of this manual. In general, however, a condition-name defines a condition which can be used to control an operation.

For example, suppose that a manufacturer has agreed to pay shipping charges for goods shipped to customers within 50 miles of the factory, but that charges for shipment out of this 50-mile zone will be billed to the customer. Obviously, two different routines are called for in the program, and the decision as to which will be used will depend on the shipping distance.

Suppose that a code is used in the input records to indicate whether the customer is located within the 50-mile zone or not. The programmer will need to refer to this code, and it will usually be convenient to be able to give it a name which can be written in a procedure statement.

In this case, the programmer might wish to use the name OUT.OF.ZONE to indicate that a customer is located more than 50 miles from the factory. He can place this name in the program by writing an entry that instructs the system that the name is to be treated as an equivalent for the code it represents. (The actual method of doing this is explained in Chapter 4.)

<!-- page 15 | PDF 21 -->
**[page 15]**

Once the condition-name has been defined, the programmer may use it in the procedure statements. For example, he might write such a sentence as IF OUT.OF.ZONE THEN DO BILLING.ROUTINE.A OTHERWISE DO BILLING.ROUTINE.B. The expression IF OUT.OF.ZONE will cause the system to examine the data to determine if the indicated condition has been met. When the reader has studied the discussion of conditional expressions, he will realize that a condition-name of this kind is actually a short way of writing an expression that shows a relationship between two items. Thus, if the "out-of-zone" code were 2, and if the field containing that code were called DISTANCE.CODE, the condition-name OUT.OF.ZONE would actually be equivalent in every way to the expression DISTANCE.CODE = 2.

Condition-names are subject to the general rules for the formation of names, which are given below. They may be assigned by the programmer at his discretion.

### Formation of Names

Names may be formed by combining any of the characters from the basic list of alphabetic characters, numerals, and the period, subject to the following rules:

1. Names must not contain blanks.
2. Names must always begin with an alphabetic character.
3. They may contain from 1 to 30 characters.
4. They may neither begin nor end with a period. However, "imbedded" periods may be used within the name for the sake of readability.
5. They may be "qualified" (to make them unique within the program) by the use of other names. This is explained below under the heading "Compound Names."

### Compound Names

In many cases a program will contain duplicate names. This often happens when an input file is "updated" to produce an output file, since each file will usually contain the same kinds of records.

Suppose that an input record is named INPUT.MASTER and an output record is called OUTPUT.MASTER. Suppose, further, that each record contains two dates, one called ORDER.DATE, the other called SHIPMENT.DATE.

If the program involves both kinds of records, it would not be possible to distinguish readily between the two ORDER.DATE names and the two SHIPMENT.DATE names. All four names would be defined in the data description (see Chapter 4), which gives the system the information it needs to locate individual items of data. To indicate which of the ORDER.DATE (or SHIPMENT.DATE) names is meant, however, each such name can be "qualified," or "compounded," when used in a procedure statement. That is, the name of a larger data item of which it is a part can be added to the name to identify it. Thus, INPUT.MASTER ORDER.DATE would be clearly distinguishable from OUTPUT.MASTER ORDER.DATE. Names qualified in this manner are referred to as *compound names.*

Compounding of names is not limited to two levels. For example, the various dates mentioned in this example may each have an element called MONTH to which the programmer may wish to refer individually. If, at the time of reference, the program is working with only one record which contains an element called MONTH, there is no ambiguity. But should ambiguity exist, the name of a data item at a higher level may be used as a qualifier. Thus, the programmer may specify, in this case, ORDER.DATE MONTH or SHIPMENT.DATE MONTH. If, as is likely, both input and output records are in use at the same time, three levels of names may be used in a single compound name—for example, INPUT.MASTER ORDER.DATE MONTH.

When names are to be compounded, the following rules apply:

1. Each name must be separated from the next by at least one blank space. (This distinguishes between compound and simple names, since simple names may not contain blanks.)

<!-- page 16 | PDF 22 -->
**[page 16]**

2. The names must be written in increasing order from the general to the specific. (If the reader is familiar with the concept of level numbers, as discussed in Chapter 4 of this manual, he will note that this means that the names must be listed in order from the lowest to the highest level number.)
3. No qualifying names are required that do not contribute to the uniqueness of the compound name. Thus, in the example given, if there were only one date named in each of the input and output files—e.g., an ORDER.DATE, but no SHIPMENT.DATE—it would not be necessary to use the name ORDER.DATE in forming the compound name; the names INPUT.MASTER MONTH and OUTPUT.MASTER MONTH would suffice.

The organization and structure of data for use in a data processing system is further discussed in Chapter 4, entitled "Data Description." The reader is referred, in particular, to the discussion of level numbers beginning on page 68.

The reader has seen that the Commercial Translator system uses names as a convenient—in fact, indispensable—means of identifying data, procedures, and conditions. It is now necessary to indicate how each name is placed in the program in a way that permits the system to connect it with the item to which it refers.

### Placing Names in the Program

A Commercial Translator program consists primarily of *procedure description* and *data description.* The first of these is made up of procedure statements—the actual instructions which govern both the processor and the object program. The second consists of data description statements—entries which instruct the system to reserve a specified amount of storage space for each kind of data and which show the organization and nature of the data so that it can be located and used when needed. These two sections are discussed in Chapters 3 and 4.

All statements for a Commercial Translator program must be written in a specified format, and, as a guide to the programmer, two columnar forms have been prepared for this purpose. One is used for procedure statements, the other for data description statements. The first is described in Chapter 3, the second in Chapter 4.

Procedure-names differ from other names in one important respect. They are used as names for *sentences* and *sections* (which themselves usually contain names of various kinds), whereas data-names and condition-names identify *kinds of information.* A procedure-name identifies a fixed set of procedure statements. A data-name usually identifies a storage area that may contain different values at different times.

Procedure-names are identified in the procedure description. This is a simple matter. It consists merely of writing the procedure-name before the statement or statements to which it refers, in accordance with the rules given in Chapter 3. Once the name has been written, the program will be able to interpret any reference to the name as a reference to the associated procedure statement.

Data-names and condition-names, however, require amplification. As will be seen in Chapter 4, the system must know whether the data is numeric or whether it contains alphabetic characters. It must know where decimal points, if any, are to be placed, where to print dollar signs, and so on. There are a number of such details which must be specified. It would have been possible to set up rules for describing the data in the procedure description, but this would have been inefficient, since the description of each item would have had to be repeated each time its name appeared. Since the description is placed in a separate section, however, each name need be described only once, regardless of the number of times it is used in the program.

It follows that each data-name and each condition-name used in the procedure description must be properly accounted for in the data description, following the rules given in Chapter 4. Once this has been done, the programmer is free to refer to the name repeatedly throughout the procedure description.

<!-- page 17 | PDF 23 -->
**[page 17]**

## Constants

It has been emphasized that data-names used in the Commercial Translator system generally refer to kinds of data, not to specific values. The actual values represented by most data-names are assumed to be variable, and they will either be entered into the system as parts of input files when the object program is run or they will be computed at some point in the program.

However, the programmer will often find it useful to be able to place a specific fixed value into the program instead of having to read it in as data. For example, if a firm allows a discount on its bills, the discount will usually be figured as a fixed percentage. The routine for computing the discount, therefore, does not require any provisions for inserting varying percentage rates. Thus, it would be convenient to be able to write this rate directly into the program.

Any value—or any group of symbols—which is to be used in the program without alteration is called a *constant.* The programmer will find many uses for numeric constants, such as the discount rate mentioned, for alphabetic constants, such as names and titles to be printed out on final reports, and for alphameric constants, which may serve any number of purposes.

In some circumstances, it will be convenient to write the constant directly in a procedure statement. In this case it will be called a *literal.* In other cases, it will be more convenient to give the constant a name and store it within the system so that it can be called for by name when required. In this case it will be called a *named constant.*

As an aid to the programmer, certain standard constants, such as the value 0 and the blank, have been "pre-named." These values are defined in the processor itself, and they have already been given names. Thus, the programmer can write these names in the procedure statements without having to define them in the data description. These special constants, called *figurative constants,* will be discussed later in this section.

Literals and named constants may be used in procedure statements for the same purposes for which data-names are used—that is, as "operands" (i.e., "objects") of Commercial Translator verbs. The essential difference between them is that a literal expresses an actual value—a value to be read "literally" at the point where it is written—whereas a named constant is the *name* of such a value, and it cannot be used, or interpreted, in a procedure statement until it has been defined in the data description.

The following example will show the difference between literals and named constants:

Assume that a discount is to be computed by multiplying the amount of an order by a discount percentage of two per cent. The programmer might write such a statement as

```
SET DISCOUNT = ORDER.AMOUNT * .02.
```

This command would instruct the system to take whatever value was in the field called ORDER.AMOUNT, multiply it by the value .02, and place the result in the field called DISCOUNT.

On the other hand, the programmer could place the value .02 in storage, giving it a name such as DISCOUNT.PERCENTAGE, and then write such a statement as

<!-- page 18 | PDF 24 -->
**[page 18]**

```
SET DISCOUNT = ORDER.AMOUNT * DISCOUNT.PERCENTAGE.
```

In this case, the system would take the value in the ORDER.AMOUNT field, look up the value in the field called DISCOUNT.PERCENTAGE, multiply the two values together, and store the result, as before, in the DISCOUNT field.

The same result is obtained in either case, and it may appear at first sight that it is more efficient to write literals than named constants. This may or may not be so. If the constant is short, as in this example, it will usually be more convenient to write it as a literal. If it is long, and if it can be given a short name, it may be more efficient to treat it as a named constant. Furthermore, the technique of naming a constant makes it possible to store large quantities of reference material, such as lists and tables, within the system, and to make use of selected items from such a list or table as required. The reader will see later how this may be done.

It should be noted, however, that in certain special cases the name of a named constant is implied, rather than actually written. In such a case, the constant will be a part of a data item which *is* named, and it will always be possible to identify it by making an appropriate reference to the named item. The reader will see, in the discussion of tables, that each individual item in a table need not be named, but the table itself (and, often, specific kinds of data within the table) will be named. The programmer can then refer to subordinate elements in the table by a kind of indexing known as "subscripting." This is explained later in this chapter.

### Literals

Although a literal may be written and used in a procedure statement as if it were a data-name, it differs from data-names (including named constants) in that its value is the value literally stated—it is not used as a name for some other value.

#### Rules for Forming Literals

Literals may be numeric, alphabetic, or alphameric. Some of the rules for forming numeric literals differ slightly from the rules for alphabetic and alphameric literals. For convenience of reference, the rules governing each type are listed separately.

##### NUMERIC LITERALS

1. All literals are limited to 50 characters in length, and, when written on the columnar form used for writing procedure statements, they may not be carried over from one line to the next.
2. Numeric literals may contain only numerals, not more than one decimal point, and a plus or minus sign to indicate whether the value of the number is positive or negative. "Floating point" numbers also contain the letter F, as explained in Rule 4 below, and may contain more than one plus or minus sign. The decimal point is required except where it would be the last character of the literal; in that case it must *not* be used. The decimal point will be noted by the system in order to align the number properly for use, but it will not occupy an actual place in storage, and it is not counted in determining the length of the literal.
3. If the literal is to be operated on arithmetically, it must contain not more than 20 digits.
4. Numeric values may be entered as "floating point" numbers by writing the "fraction" (i.e., the number or decimal fraction), then the symbol F, and then the exponent. The fraction and the exponent may each have a plus or minus sign. The symbol F will not occupy a space in storage, and it is not counted in determining the length of the literal. The system will accept floating point numbers using a base of 10 only. (A floating point number is a number expressed as a decimal number or decimal fraction multiplied by some power of 10. For example, the number 1500 might be written as `1.5F3`, which is equivalent to 1.5 times 10³; the same number might also be written as `15F2`, `.15F4`, or in any other similar way that is convenient. The number .002, which is equivalent to 2 times 10⁻³, might be written `2F-3`.)
5. Numeric literals must not be enclosed in quotation marks.

<!-- page 19 | PDF 25 -->
**[page 19]**

##### ALPHABETIC AND ALPHAMERIC LITERALS

1. An alphabetic or alphameric literal may contain any of the characters from the basic character set except the quotation mark. A blank is treated as a character and may be included in an alphameric literal.
2. Like numeric literals, alphabetic and alphameric literals are limited to 50 characters in length and may not be carried over from one line to another when written on the columnar form used for writing procedure statements.
3. All non-numeric literals must be enclosed in quotation marks to distinguish them from names. This rule applies even should the literal contain symbols (such as the arithmetic symbols and the blank) which may not be used in names.

### Named Constants

Named constants are placed in the system by specifying them in the data description in accordance with the rules given in Chapter 4. Each named constant will usually have its own individual name, but in certain cases it may be part of a group of constants having a group name. As the reader will note from the discussion of tables and lists, individual items in a list are often in this category. However, even when the individual item does not have a name, it is always referred to by a name of some kind, and it may thus be treated in the general category of named constants.

A named constant may be referred to in procedure statements by writing its name as if it were any other data-name (although, of course, it should not be used in a way which will change its value).

#### Rules for Forming Named Constants

Named constants, like literals, may be wholly numeric, wholly alphabetic, or alphameric. All of the rules specified above for forming literals apply to constants, except as follows:

1. Named constants are not limited as to length, and when written on the columnar form used for data description entries, they may be carried over from one line to the next. In this case they are subdivided and written as a series of complete constants, one on each line, but at a level lower than that of the name given to the total constant. After these parts have been read into the system, the processor will reassemble them to form the original constant.
2. All named constants, including those which are wholly numeric, must be enclosed in quotation marks.
3. Named constants may include any of the characters in the machine's character set, including the quotation mark and the blank. (The presence of a blank in an otherwise numeric constant makes it alphameric.)

### Figurative Constants

The figurative constants resemble named constants except that their names are already assigned in the processor itself, so that the programmer need not write data description entries for them.

Figurative constants are names for certain constant quantities which are used frequently in data processing programs. The list includes names which represent zeros, blanks, and the lowest and highest characters in the collating sequence of the machine system being used. Following is a list of the figurative constants:

```
ZERO or ZEROS
BLANK or BLANKS
LOW.VALUE or LOW.VALUES
HIGH.VALUE or HIGH.VALUES
```

In general, a figurative constant is used to place the value it names in a given storage area, although it is not limited to this usage.

<!-- page 20 | PDF 26 -->
**[page 20]**

For example, if the programmer wishes to reduce the value of a data item called COUNTER to zero, he can do so by writing the instruction MOVE ZEROS TO COUNTER. This procedure will replace all previous data in COUNTER by zeros. Similarly, if he wished to erase all data in an area called AMOUNT, he could write MOVE BLANKS TO AMOUNT. In each case, the specified area will be completely filled with characters of the value named.

The names LOW.VALUE and HIGH.VALUE refer, respectively, to the lowest and highest characters in the collating sequence of the system for which the program is written.

## Expressions

The words and symbols of the Commercial Translator language are combined into clauses and sentences in order to give instructions to the processor and the object program. Before considering the formation of these larger units of the language, however, it is important to examine two specialized forms of expression: arithmetic expressions and conditional expressions.

### Arithmetic Expressions

An arithmetic expression is a combination of data-names, conditional expressions, and/or literals, joined together by one or more arithmetic operators in such a way that the entire expression can be reduced to a single numeric value. (An arithmetic operator is a symbol representing addition, subtraction, etc.; a list of operators is given below.) Both simple and compound names may be used in an arithmetic expression.

Consider the following examples:

```
A + B
GROSS.PAY - DEDUCTIONS
GROSS.SALES * COMMISSION
BEGINNING.ON.HAND + RECEIPTS - SHIPMENTS
A * (B + C) - (D / E)
TOTAL.SALES * .3
```

In these expressions, the symbols `+`, `-`, `*`, and `/` are arithmetic operators used to express addition, subtraction, multiplication, and division, respectively. They link together a variety of terms, including the values represented by the data-names A, B, C, GROSS.PAY, DEDUCTIONS, and the literal `.3`. All of these will represent specific values at object time. If the data-name GROSS.PAY, for example, should be 125.50, and if DEDUCTIONS should turn out to be 31.20, the expression GROSS.PAY - DEDUCTIONS would reduce to a value of 94.30. Similarly, if TOTAL.SALES should have a value of 12,000, the expression TOTAL.SALES * .3 would reduce to a value of 3,600.

Arithmetic expressions may be used as components of conditional expressions, clauses, and sentences, as will be shown later in this chapter. Use of an arithmetic expression will cause a computation to be performed in order to obtain the single result to which the expression can be reduced.

It was stated above that conditional expressions can also be used in arithmetic expressions. This is a specialized usage in which a test is made to determine whether or not a particular condition is met. The "truth operator" TR is used to indicate this test. It is generally used to multiply one or more terms in an arithmetic expression. Since it takes on a value of 1 if the conditions of the test are met, and a value of 0 if they are not met, it can be used to cancel a term in an arithmetic expression if a condition exists in which the term is not wanted. The method for doing this will be explained later, in the discussion of "truth functions."

<!-- page 21 | PDF 27 -->
**[page 21]**

The complete list of arithmetic operators and their meanings is given in the following table:

| Operator | Meaning |
|---|---|
| + | Addition |
| - | Subtraction or Negation |
| * | Multiplication |
| / | Division |
| ** | Exponentiation |
| ABS | Absolute Value (i.e., the value of a number treated as if the sign were positive) |
| TR | Truth Value (see the discussion of truth functions) |

### Conditional Expressions

A conditional expression is an expression which, taken as a whole, may be either true or false, depending on conditions existing when the expression is examined. Generally, a conditional expression contains at least one variable quantity, and the truth or falsity of the expression will depend on the particular value assumed by the variable or variables. For example, the expression A IS GREATER THAN 10 is conditional, since it may or may not be true, depending on the value of the quantity A. Obviously, if A had a value of 12, the expression would be true; if the value were 7, the expression would be false.

A conditional expression may contain data-names, condition-names, arithmetic expressions, and expressions which show relationships between values (such as the expression IS GREATER THAN). Conditional expressions may be joined together by the words AND and OR to form compound conditional expressions.

Conditional expressions may be of either of two principal types: (1) relations, and (2) condition-names.

#### Relations

A conditional expression may contain an expression that shows a relationship between values. The example given above, A IS GREATER THAN 10, illustrates the general concept. Six basic relational expressions may be used in conditional expressions, each of which may be written in a full form or in an abbreviated form. They are as follows:

| Relational expression | Abbreviated form |
|---|---|
| IS GREATER THAN | GT |
| IS NOT GREATER THAN | NOT GT |
| IS EQUAL TO | = |
| IS NOT EQUAL TO | NOT = |
| IS LESS THAN | LT |
| IS NOT LESS THAN | NOT LT |

These expressions may be used to connect data-names, literals, and arithmetic expressions. The following examples indicate typical uses of the relational expressions:

```
BEGINNING.ON.HAND + RECEIPTS - SHIPMENTS IS
  LESS THAN REORDER.POINT
AGE GT 21
A * (B + C) - (D / E) = 500
DEPENDENTS NOT = 0
A GT B OR A = C
```

<!-- page 22 | PDF 28 -->
**[page 22]**

#### Condition-Names

In many cases, a record can be processed in one of several ways, depending on certain characteristics of the record or the existence of a particular condition at the time it is processed. For example, assume that a company is using a file of personnel records to prepare a report on employees' dependency status. The records of single employees will probably be processed in a different manner from those of married employees. It might also be essential to distinguish between married and divorced employees. Thus, each record must be examined individually to determine marital status. Marital status would normally be indicated by a code of some kind, and, for the purposes of this illustration, it will be supposed that the initials M, S, and D indicate the classifications (i.e., the "conditions") "married," "single," and "divorced," respectively.

One of these initials will appear in each record, and the programmer must reserve a place in storage for this code by giving a general name to the area in which the code is to be placed. This is done by writing an entry in the data description, as explained in Chapter 4. (See, in particular, the discussion beginning on page 71, in which the reader is shown how a data description for this example may be written.) Assume that the general name used is MARITAL.STATUS. This is a data-name, and it may be used in procedure statements in any of the ways in which data-names may be used. However, in this case, it is desired to name, in addition, the specific values which this data-name represents. Specifically, the programmer will wish to be able to refer to the initials M, S, and D.

If he wishes, he may write a relational expression such as has been shown above. Thus, MARITAL.STATUS = 'M' is a relational expression, and it may be used in such an instruction as IF MARITAL.STATUS = 'M' THEN DO TABULATION.ROUTINE.A. (Note, incidentally, that the initial M is placed in quotation marks to show that it is a literal, for this code will appear literally in the record.)

However, it is often simpler to treat the appearance of a particular code in the assigned area as a *condition*; this condition can then be given a *condition-name* which signifies that the condition is present. The condition-name MARRIED, for example, could then be used to indicate the presence of the initial M. Condition-names are assigned in the data description, and the reader is referred again to Chapter 4 to see how this may be done.

Once a condition-name has been defined, it may be used directly in procedure statements. The condition-name actually serves as an abbreviation of a relational expression. In this example, the condition-name MARRIED is exactly equivalent to MARITAL.STATUS = 'M' and it may be substituted for it wherever the programmer wishes. The instruction mentioned above (IF MARITAL.STATUS = 'M' THEN DO TABULATION.ROUTINE.A) can then be reduced to IF MARRIED THEN DO TABULATION.ROUTINE.A.

Similarly, all of the other conditions which the field MARITAL.STATUS can assume are defined in the data description and given condition-names, assuming the programmer has need of them. (If the programmer needs to refer only to the condition MARRIED, he need not assign condition-names to the other conditions.)

The reader should note that the condition-name itself is a conditional expression in the full meaning of that term. It may be used in clauses and sentences in the same manner as any other conditional expression. The most general use of a condition-name is in a clause of the IF . . . THEN type, such as IF MARRIED THEN, or IF SINGLE THEN. This construction will be explained in the discussion of conditional clauses later in this chapter.

<!-- conversion notes:
- Pages processed: PDF 17-28 (printed pages 11-22), all present, no blank pages in this range.
- Printed page numbers verified directly against the footer digit visible on each page image; all follow the PDF-6 rule with no discrepancies in this chunk.
- Page 23 (printed 17): the OCR draft contained a short run of nonsense/garbled tokens ("Wenn aveesceae / an artial valic / aw / "eqs / oY) / ' / '") between "...is called a literal.—" area; this is OCR noise with no counterpart in the page image and was omitted entirely.
- The single "quotation mark" character of the source character set (Set H, card code 4-8, used to delimit literals such as 'M') is rendered throughout as a straight apostrophe (').
- The minus/subtraction operator and arithmetic "-" are rendered as a plain hyphen-minus in code/formula/table contexts; the em dash (—) is retained for ordinary prose punctuation, matching the typographic distinction in the source.
- Floating-point exponents on page 24 (printed 18) rendered with Unicode superscripts (10³, 10⁻³) to match the printed superscript notation; no overpunched/overbar digits occur in this chunk.
- No page in this chunk required image embedding: the Special Characters table, the Arithmetic Operators table, and the Relational Expressions table are simple two/three-column tables fully reproducible in Markdown.
- Minor OCR corrections applied throughout (verified against page images), including: "18M equipment" -> "IBM equipment"; "DisPLay" -> "DISPLAY"; "dit ecting" -> "directing"; "(Jf the reader" -> "(If the reader"; item numbering ">." -> "2." on page 21 (printed 15); "bilis" -> "bills"; "COn-venient" -> "convenient"; "ORDER. DATE MONTH OF SHIPMENT.DATE MONTH" -> "ORDER.DATE MONTH or SHIPMENT.DATE MONTH".
-->

<!-- page 23 | PDF 29 -->
**[page 23]**

#### AND, OR, and NOT

The Commercial Translator system is fully capable of interpreting and processing “compound conditions”—i.e., conditional expressions which are themselves composed of two or more conditional expressions.

Suppose the following expressions are being used as conditions:

```
MARRIED
OVER.21
HOURLY.RATE IS GREATER THAN 3.50
HOURLY.RATE IS LESS THAN 5.00
```

These expressions may be joined in any combination the programmer might wish, using the words AND and/or OR. In some cases, it will also be necessary to enclose one or more pairs of conditions in parentheses. The negative form of a conditional expression may also be used; this is obtained by placing the word NOT before the expression.

The interpretation of conditional expressions is governed by four rules:

1. The word OR is interpreted as “either or both.” In other words, it is used in the “inclusive” sense employed in formal logic.
2. The word AND is interpreted as “both.” Simple conditions joined by AND must both be true in order for the compound condition to be true.
3. Each conditional expression must be completely stated. For example, the system would not accept such an expression as HOURLY.RATE IS GREATER THAN 3.50 AND LESS THAN 5.00. To convey the intended meaning, the full expression must be written as HOURLY.RATE IS GREATER THAN 3.50 AND HOURLY.RATE IS LESS THAN 5.00.
4. When a compound conditional expression contains both the word OR and the word AND, it will be interpreted as if the terms connected by AND were enclosed in parentheses. In other words, each pair of conditions joined by the word AND will be considered as a single condition which is true if both of the subordinate conditions have been met. If a contrary sense is intended, parentheses must be used to show it.

The following examples should clarify the interpretation of these rules:

| Compound Conditional Expression | Interpretation |
| --- | --- |
| MARRIED AND OVER.21 | Both of the conditions MARRIED and OVER.21 must be met. |
| MARRIED OR NOT OVER.21 | Either the condition MARRIED or the condition NOT OVER.21, or both, must be met. |
| NOT MARRIED AND HOURLY.RATE IS NOT LESS THAN 5.00 | Both of the conditions NOT MARRIED and HOURLY.RATE IS NOT LESS THAN 5.00 must be met. |
| MARRIED OR OVER.21 AND HOURLY.RATE IS GREATER THAN 3.50 | Either the condition MARRIED must be met or the combination OVER.21 AND HOURLY.RATE IS GREATER THAN 3.50 must be met, or both. |

<!-- page 24 | PDF 30 -->
**[page 24]**

| Compound Conditional Expression | Interpretation |
| --- | --- |
| (MARRIED OR OVER.21) AND HOURLY.RATE IS GREATER THAN 3.50 | Either the condition MARRIED or the condition OVER.21 must be met, or both, and, in addition, the condition HOURLY.RATE IS GREATER THAN 3.50 must also be met. |
| MARRIED AND OVER.21 AND HOURLY.RATE IS GREATER THAN 3.50 | All three conditions must be met. |
| MARRIED OR OVER.21 OR HOURLY.RATE IS GREATER THAN 3.50 | The compound condition will be met if any one of the three conditions, or any two, or all three conditions, are met. |

### Truth Functions

It has been pointed out that conditional expressions may be used in arithmetic expressions in connection with the “truth operator” TR. When the truth operator is used, as explained below, it converts the conditional expression into an arithmetic expression having a value of either 1 or 0. This value can then be used normally in the arithmetic expression.

The conditional expression is placed in parentheses and the operator TR is placed immediately in front of it. The resulting term is called a *truth function*. The truth operator signals to the system that it must make a test to determine the truth or falsity of the conditional expression. If the condition is found to be true, the truth function as a whole is automatically assigned a value of 1; if the condition is false, the truth function is given a value of 0.

Suppose that a manufacturer agrees to give a discount of five per cent on bills for purchases of more than one thousand dollars. If the amount of the purchase is to be found in a field called ORDER.AMOUNT, the programmer could write such a statement as:

```
SET DISCOUNT = ORDER.AMOUNT * .05 * TR
    (ORDER.AMOUNT IS GREATER THAN 1000).
```

The conditional expression ORDER.AMOUNT IS GREATER THAN 1000 will then be examined. If it is found to be true, the whole truth function will be replaced by a value of 1; in this case the discount would be computed as five per cent of the value in the ORDER.AMOUNT field. If the conditional expression is found to be false, the truth function will be given a value of 0, and the net effect would be to cause the discount to be computed as 0.

The truth operator may be used with relational expressions, as in the example given, or with condition-names.

## Clauses

The basic components of the Commercial Translator language have now been discussed. The remainder of this chapter will show how these components can be combined to express meanings.

The basic complete unit of meaning in the Commercial Translator language is the *sentence*. Sentences, however, are composed of one or more shorter units, known as *clauses*. There are two kinds of clauses: imperative and conditional.

<!-- page 25 | PDF 31 -->
**[page 25]**

### Imperative Clauses

An imperative clause is a group of words that expresses a complete command. The clause may or may not include symbols. It always begins with a verb and may contain one or more operands of the verb, as appropriate. The operands may include data-names, procedure-names, condition-names, literals, figurative constants, and arithmetic expressions. Following are several examples of imperative clauses:

```
OPEN INPUT.MASTER.FILE
GET PAY.RECORD
ADD 1 TO COUNTER
MOVE ZEROS TO AMOUNT.FIELD
GO TO TAX.CALCULATION
SET NET.PAY = GROSS.PAY - (GROSS.PAY
    - (EXEMPTIONS * 13)) * .18 - OTHER.DEDUCTIONS
```

### Conditional Clauses

A conditional clause consists of a conditional expression introduced by the word IF and terminated by the word THEN. The conditional expression may be simple or compound. The word IF is an operator which informs the system that the conditional expression which follows must be tested for truth or falsity. The word THEN defines the limit of the conditional expression to be tested; it will always be followed by an imperative clause.

Following are several examples of conditional clauses:

```
IF OUT.OF.ZONE THEN
IF AMOUNT GT 200 THEN
IF MARRIED AND OVER.21 THEN
IF A = B OR A = C AND A GT D THEN
```

## Sentences

A Commercial Translator sentence corresponds to a sentence in English—it expresses a complete and independent thought. It must contain at least one imperative clause and may contain, in addition, one conditional clause and one or more additional imperative clauses. It is terminated by a period, which must be followed by a blank to distinguish it from the “imbedded period” used in names and from the decimal point used in numeric literals. Imperative clauses within the same sentence must be separated by commas.

When a conditional clause is used in a sentence, it must begin the sentence, and it must be followed by one or more imperative clauses to be executed if the prescribed condition is met. If the programmer wishes to prescribe alternative action to be taken if the conditional expression proves false, he may specify it by writing next (without intervening punctuation) the word OTHERWISE, followed by one or more imperative clauses. If the conditional expression should prove false, and if the sentence does not contain the word OTHERWISE, the conditional sentence will cause no action and the system will proceed to the next sentence in the program.

The following examples show how Commercial Translator sentences may be constructed:

```
ADD 1 TO COUNTER.
GO TO TAX.CALCULATION.
STOP.
IF MARRIED THEN MOVE NAME TO MAILING.LIST.M,
    ADD 1 TO COUNTER.
IF GROSS.PAY LT NET.PAY THEN GO TO ERROR.ROUTINE.
IF OUT.OF.ZONE THEN DO BILLING.ROUTINE.A OTHERWISE
    DO BILLING.ROUTINE.B.
```

<!-- page 26 | PDF 32 -->
**[page 26]**

Sentences may be assigned procedure-names, so that the programmer can make reference to them in other parts of the program. It will be seen that this provision makes it possible to carry out any sequence in the program whenever it is desired, without having to rewrite it each time. Suppose, for instance, that the last sample sentence given above, which begins IF OUT.OF.ZONE . . ., had been given the name DISTANCE.CHECK. Whenever the programmer wishes to make this check and take appropriate action, he can instruct the program to “transfer” to this sentence by writing either DO DISTANCE.CHECK or GO TO DISTANCE.CHECK. (This will be explained more fully in Chapter 3.) The actual method of assigning names will be discussed in Chapter 3 under the description of the columnar form used in writing procedure statements.

## Sections

A section consists of one sentence, or a group of successive sentences, which has been given a name for reference purposes in accordance with the rules given below.

At first sight, it may appear that a Commercial Translator section corresponds closely to a paragraph of English. However, there are several distinctions. Sentences are *not* grouped into sections for the purpose of clarifying the logic or the structure of the program for the benefit of the system, whereas paragraphing in English does perform such a service for the reader. Sectioning, in the Commercial Translator, is used for the purpose of naming portions of procedure.

For example, suppose the programmer has written a sequence of sentences to calculate compound interest. Instead of having to write out this sequence each time the calculation is required, he can group the sentences into a section and give it a name by which it can be referred to elsewhere in the program. If this name were INTEREST.ROUTINE, for instance, he could write such a clause as DO INTEREST.ROUTINE at any point in the program, and this instruction would cause, first, a transfer to that routine and, second, a transfer back to the original point when the routine has been carried out. (Details will be found in the discussion of the DO command in Chapter 3.) Grouping of sentences into sections, then, is a device for identifying such a group for further reference.

The beginning of a section must be identified by a procedure-name, followed by a period. The name must then be followed by the words BEGIN SECTION, in accordance with the rules for using that verb, as given in Chapter 3. Following the last sentence in the routine, the programmer must write the word END, followed by the procedure-name used originally to identify the section.

Sections may be “nested,” that is, one or more sections may be contained within a larger section, but each such section must be wholly contained—it cannot overlap another section.

Where necessary, the names of sections can be used as parts of compound names.

## Divisions

All Commercial Translator programs are composed of three divisions, the *Procedure Description*, the *Data Description*, and the *Environment Description*. The first of these contains the procedure statements of which the program is composed. The second provides the processor with information about the data to be used in the object program. The third is used to make certain technical connections between the program and the machine system on which it will be run; these details are dependent on the particular system and are therefore discussed in the publications covering the processors for the various systems.

<!-- page 27 | PDF 33 -->
**[page 27]**

It is not necessary that these three divisions appear as separate entities. If appropriate, the programmer may write a portion of one, then a portion of another, and so on. However, each such portion must be properly labeled with a *division header*. Each header consists of the name of the division, preceded by an asterisk. The three division headers are:

```
*PROCEDURE
*DATA
*ENVIRONMENT
```

These names are written, where required, in the “name margin” of the form used for the procedure description, as explained in Chapter 3, or in the name columns of the form used for the data description, as explained in Chapter 4. In other words, the asterisk always appears in the left-most name column, followed immediately by the remainder of the header.

All entries following a division header are assumed to be a part of the specified division.

## Punctuation and Spacing

The punctuation of Commercial Translator sentences is reasonably simple and, for the most part, self-evident. It may be summarized in the following rules:

1. All words are separated by blanks, or by any character which cannot legally be used in a word, such as an arithmetic operator. (See the rules for forming names, beginning on page 15.)
2. Multiple blanks are treated as single blanks, except within alphameric literals, where each blank will be treated as a separate character. (Numeric literals cannot contain any blanks.)
3. Each sentence must be terminated by a period, followed by a blank. Should the blank be omitted, the period will be treated as an “imbedded period,” except where the period is found in Column 72 of the procedure description form.
4. The “imbedded period”—i.e., a period surrounded by non-blank characters—serves one of two functions, depending on the context: (1) If it appears in a “word” consisting wholly of numerals, or in a floating point number, it will be treated as a decimal point. (2) In any other context (except within a literal), it will serve as the equivalent of a hyphen—in other words, as the means of connecting separate parts of a simple name.
5. Successive imperative clauses in a sentence must be separated by single commas; for the sake of clarity, the programmer may use blanks in addition, but they will be ignored.
6. Arithmetic operators may be used with or without surrounding blanks. Blanks may be used for the sake of clarity, as in the expression A + B * C, but they will be ignored; this expression could therefore be written A+B*C. However, the programmer must not write two successive arithmetic operators unless the second of them is either the operator TR or the operator ABS. Where the effect of two successive operators is required, one term may be enclosed in parentheses; thus, while the expression A * -B is illegal, the same value may be written A * (-B). The minus sign in this case could have been followed by a blank, but the notation given is customary.

<!-- page 28 | PDF 34 -->
**[page 28]**

7. The rules of punctuation and spacing do not apply within literals, which may contain any character except the quotation mark, or within constants defined in the data description, which may contain any character. Alphabetic and alphameric literals, and all named constants, must be enclosed in quotation marks. (See the rules governing literals and named constants, beginning on page 18.)
8. Floating point numbers are written as numeric literals. (See the discussion of numeric literals, beginning on page 18, and also the rules for writing floating point numbers in the data description, on page 80.)
9. Parentheses must be used to group together two or more terms which are to be acted on by a single arithmetic operator, in accordance with the rule that all operators act on the next named item, or the next parenthetical expression, following the operator.
10. Subscripts must be enclosed in parentheses, and if more than one subscript is used within the same parentheses, they must be separated by single commas. (See the discussion of lists, tables, and subscripts beginning below.)
11. Parentheses may be used wherever needed in arithmetic expressions and in compound conditional expressions for the sake of clarity; where ambiguity would result from their omission, they *must* be used.
12. Division headers must begin with single asterisks.
13. Punctuation and spacing associated with any particular verb will be found in the general format prescribed for the verb in Chapter 3.
14. When it is necessary to carry over an item from one line to another on either the procedure description or data description forms, selection of the “break point” must follow the rules given for those forms. In general, it should also be understood that a blank is assumed to follow Column 72 of the procedure description form and Column 71 of the data description form.
15. When a function is named as an operand in a procedure statement, the names of the data to be substituted for the parameters must be placed in double parentheses immediately following the function-name. These data-names must be separated by single commas. (See the discussion of functions beginning on page 32.)

## Lists, Tables, and Subscripts

Just as a clerk may use a reference table to obtain data, the programmer can direct the program to look up data in a list or table stored within the data processing system. The programmer must therefore know how to place the table in storage initially and how to write instructions for locating data in it.

A list, or table, may be regarded as an ordered grouping of data. The actual data may be either fixed or variable, depending on the need. If it is fixed, it is usually entered into the system as a series of constants; if it is variable, it will be either placed in the system when the input records are read in or produced as a result of some operation performed within the system.

In either case, it is necessary to establish the format of the table in such a way that the system can locate individual items of data within it. Thus, placing a table in the system requires two steps: (1) establishing the structure and format of the table, and (2) making provisions to enter the required data in that structure. When this is done properly, the programmer may call for any item of data in the table as required.

<!-- page 29 | PDF 35 -->
**[page 29]**

The actual methods of storing a table for use are described in Chapter 4, since data description entries are required. To illustrate the general principles involved in preparing and using a table, however, the following example may be helpful:

Suppose that the programmer wishes to be able to refer to a table of passenger transportation rates and that the general form of this table can be represented by the following excerpt:

| City | One-Way | Round Trip | Excursion |
| --- | --- | --- | --- |
| . . . | . . . | . . . | . . . |
| Los Angeles | 153.42 | 285.16 | 212.87 |
| Miami | 78.60 | 141.63 | 118.92 |
| . . . | . . . | . . . | . . . |

When a table of this kind appears on a printed page, it is seen to have a grid-like structure, consisting of vertical columns intersected by horizontal lines. Such a structure cannot be placed in storage in this form, since data is fed into the system in a continuous stream. However, the table can be read line by line, one line succeeding another, until the entire table has been placed in the system in the form of a long list of data. In fact, several tables of the same type can be entered into the system in succession, as if they made up a single “three-dimensional” table. Thus, in the example given, there might be one rate table for the vacation season, another for the “off season,” and so on. The two- or three-dimensional structure of the table is preserved by the use of “level numbers,” as explained in Chapter 4, but the total mass of data would appear in storage as one long “string” of data.

It follows that a simple list of items may be thought of as a one-column table, or that a table, no matter how complex, may be thought of as a special form of list. In the example given, an essentially two-dimensional table has been reduced to a list, called RATE.TABLE, consisting of, say, 30 lines, each called RATE, and each containing the four items CITY, ONE.WAY, ROUND.TRIP, and EXCURSION; these data-names correspond to the column titles in the example.

In this form, the data is not usable until some means has been established for locating each individual item. This is done initially by arranging the data so that each line consists of exactly the same number of character spaces, with each item in the line occupying a position that corresponds exactly to the position of the corresponding item in each other line. Each item can then be located by its position in storage, which, as has been pointed out, is the basic principle by which all data in storage is located.

It is then necessary to find a way of identifying each position and each line so that any particular item can be located. A method for doing this is explained in Chapter 4, in connection with the sample table previously mentioned. The actual method used depends on the principle of counting. Continuing with the example given, suppose Miami is the 17th city listed in the table. If the programmer wished to obtain the one-way rate for Miami, he would have to find a way of indicating to the system that it must find the 17th line of the table and then locate the second entry on that line. Obviously, there must be some means of relating the name Miami to the number 17.

This may be done in several ways. In most data processing operations, the normal way would be to show the relation externally by writing a series of code numbers corresponding to the names. Only the code numbers themselves would enter the system. For the counting principle to operate correctly, the numbers would have to be assigned sequentially and in the same order as the corresponding lines of data in the table.

<!-- page 30 | PDF 36 -->
**[page 30]**

### Subscripts

These code numbers would then be used in the input records in lieu of the actual names. Naturally, they would have to be placed in a field reserved for them, so that they could be properly identified. Suppose that in this case the field were called DESTINATION. If the programmer then wrote a procedure statement containing the data-name DESTINATION, the system would look at that field to see what number it contained. This number could then be used as a means of referring to the table.

Numbers or names used to locate items in a list or a table are known as *subscripts*. In order to use them, the programmer must place them within parentheses following the data-name showing the kind of data being sought. Thus, since the table of this example contains a data sequence called RATE, the instruction MOVE RATE (DESTINATION) TO LIST.A would cause the system to obtain the number in the DESTINATION field, use this number to locate the corresponding line of the table, and move the entire contents of the line to the area called LIST.A. In this case, the data moved would include all items contained on that line, including CITY, ONE.WAY, ROUND.TRIP, and EXCURSION.

Often, however, only one of these items would be required. As will be seen in Chapter 4, the data description entries used to place the table in storage permit the programmer to locate individual items on each line. If these entries have been properly made, the programmer can write such a statement as MOVE ONE.WAY (DESTINATION) TO BILL.AMOUNT, and the system would then locate the line having the number indicated in the DESTINATION field, single out the particular part of the line called ONE.WAY, and move that one item to the area called BILL.AMOUNT.

It is conceivable that the programmer might wish to specify that the system obtain a rate for a particular city, rather than the rate for whatever city happened to be indicated in the DESTINATION field. Once again, correspondence between the name and the number would have to be established. This could be achieved by writing a data description entry in which the name of the city was specified as the name of a literal number. Thus, MIAMI might be specified as the name of the constant value ‘17’. Then, if the programmer wrote MOVE RATE (MIAMI) TO LIST.A or MOVE ONE.WAY (MIAMI) TO BILL.AMOUNT, the system would recognize that the name MIAMI was equivalent to the number 17 and would use that number as a means of referring to the table.

It has been shown how a single subscript may be used to identify an item in a table. Actually, as many as three subscripts may be used within the same pair of parentheses. To take a simple example, suppose that the contents of a book had been stored within the system and that the programmer wished to make reference to a particular word in a particular line on a particular page of the book. Suppose, further, that the data-names WORD, LINE, and PAGE had been properly entered in the data description in such a way that entries called WORD were subordinate to entries called LINE, which, in turn, were subordinate to entries called PAGE. (As Chapter 4 explains, level numbers are used for this purpose.)

To specify the 4th word in line 10 of page 150, the programmer could then write either PAGE (150) LINE (10) WORD (4) or PAGE LINE WORD (150, 10, 4). These two expressions are equivalent. In the first case, each data-name is subscripted individually. In the second case, it is the name WORD which is subscripted, but this name has been compounded by the use of the names of two higher levels, PAGE and LINE, to make it unique. If the name WORD had been unique in the program—i.e., had not been used outside of this particular sequence—the desired item could be indicated simply as WORD (150, 10, 4).

When more than one subscript is included within the same pair of parentheses, they must be separated by single commas. The number of subscripts used must cor-

<!-- page 31 | PDF 37 -->
**[page 31]**

respond to the number of subdivisions—i.e., the number of “levels”—of the table required to obtain the item. For example, if the programmer wished to obtain all of the words on line 10, it would be sufficient to write either PAGE (150) LINE (10) or PAGE LINE (150, 10). If the name LINE were unique, it would suffice to write LINE (150, 10).

A subscript may consist of a single name representing a variable quantity (such as a data-name), or a literal, or it may consist of an arithmetic expression of the form

```
a * VARIABLE ± b
```

in which the quantities a and b are literals and the name VARIABLE is the name of a field which may contain a variable quantity. This name may be a compound name, but, whether simple or compound, it must not have a subscript. Condition-names may not be used in subscripts. A name, literal, or arithmetic expression used as a subscript must represent a positive integral value.

Following are examples of subscripted names:

| Subscripted Name | Comment |
| --- | --- |
| `PAGE LINE WORD (150, 10, 4)` | The subscripts actually apply to the name WORD, but it is assumed that this name is not unique and has been compounded by the use of the names PAGE and LINE. |
| `WORD (150, 10, 4)` | The name WORD is assumed to be unique, but it is part of a larger structure having three levels which must be identified by subscripts. |
| `RATE.TABLE ONE.WAY (2, DESTINATION, 4)` | It is assumed that there are several different tables called RATE.TABLE, each having the same structure. The 2 indicates the second table of this series, the name DESTINATION is the name of a field in the table, and the code 4 is a literal code which identifies a further subdivision of the table—e.g., “family plan, 4 persons.” |
| `ITEM (BASE ± 1)` | This subscript obtains the value following the one obtained by the notation ITEM (BASE). This construction may be useful in such procedures as interpolating between successive items in a table. Usually (in this particular kind of procedure) both items would be obtained and both would be used as inputs to some interpolating procedure. |
| `ITEM (4 * AMOUNT)` | In this case, the value of AMOUNT would be obtained and it would then be multiplied by the factor 4 and used as the subscript. Such a subscript could be used to obtain every fourth value in a table, assuming the value in the AMOUNT field is increased by 1 on each repetition of the routine. |

<!-- page 32 | PDF 38 -->
**[page 32]**

## Functions

While the term “function” is often associated with mathematics, the concept has certain general applications that can greatly simplify the writing of programs. Accordingly, the Commercial Translator system has been designed to handle certain kinds of functions as an added convenience to the programmer.

The term *function* is used in the Commercial Translator to mean a *result* obtained as a consequence of some procedure. More precisely, it means a result obtained from a procedure specified by a BEGIN SECTION command, and, in particular, it is a result named in the GIVING clause of that command.

For example, in the command BEGIN SECTION USING A, B, C GIVING MINIMUM, the name MINIMUM is a *function-name*. This name refers to a field in storage which will contain the function after the procedure specified by this command has been carried out. (A hypothetical procedure of this type will be described and explained presently.)

The reader will note that this command also contains a clause beginning with the word USING and that three data-names (A, B, and C) have been specified in that clause. These names represent data which will be used in obtaining the function. The three items of data are called *parameters*, and the three names are *parameter-names*. The term “parameter” is limited, in the Commercial Translator system, to data named in the USING clause of the BEGIN SECTION command.

Each of these names—the function-name and the three parameter-names—identifies a field in storage. At object time the three parameter fields will contain data to be used in the procedure, and the rules governing the DO command (which causes the procedure to be executed) provide a means by which the data will be placed automatically in those fields.

To illustrate the use of functions and parameters, a sample procedure will be examined in detail. Suppose that the programmer wishes to determine which of three values is the lowest, so that he can use it elsewhere in the program. Suppose, further, that he wishes to be able to compare values of different kinds and therefore wishes to use a procedure that can be used with data from a variety of sources. For this purpose he has written a procedure called MINIMUM.ROUTINE, which consists of the following procedure statements:

```
MINIMUM.ROUTINE. BEGIN SECTION USING A, B, C GIVING MINIMUM.
IF A IS LESS THAN B THEN MOVE A TO MINIMUM OTHERWISE
    MOVE B TO MINIMUM.
IF C IS LESS THAN MINIMUM THEN MOVE C TO MINIMUM.
END MINIMUM.ROUTINE.
```

The name MINIMUM.ROUTINE identifies this procedure so that the programmer can refer to it elsewhere in the program. For purposes of illustration, it will be assumed that the programmer has written the following command later in the program:

```
DO MINIMUM.ROUTINE USING D, E, F GIVING MINIMUM.2.
```

It is important to see precisely what happens in this case. First of all, when the processor encounters the MINIMUM.ROUTINE section as it is originally written, it will note the three parameter-names (A, B and C) and the function-name (MINIMUM). It will examine the entries written for those names in the data description (which will be discussed in Chapter 4) and will obtain information about the amount of storage space to be reserved for each, together with certain other technical details.

<!-- page 33 | PDF 39 -->
**[page 33]**

The net effect will be that *space* in storage is reserved for the actual data to be used and the actual result to be obtained. The values themselves will be obtained at object time when the program encounters the DO MINIMUM.ROUTINE command.

The reader will have noted that this DO MINIMUM.ROUTINE command, like the BEGIN SECTION command, contains USING and GIVING clauses. These clauses name the values to be used in the MINIMUM.ROUTINE procedure and the result to be produced. When the system encounters this command at object time, it will act as follows:

First, it will examine the field specified by the first data-name (D). It will obtain the value found there and move it to the first field named in the BEGIN SECTION command—i.e., field A. It will then obtain the value in field E and move it to field B. Similarly, it will move the value found in field F to field C. This process of data substitution follows the rule that items of data named in a DO command will be placed in the parameter fields named in the BEGIN SECTION command in the order in which they are named.

Once the actual data has been placed in the parameter fields, the MINIMUM.ROUTINE procedure will be carried out, using the data which has now been placed in the parameter fields. If fields D, E, and F had originally contained values of 11, 7, and 8, respectively, field A will now have a value of 11, field B a value of 7, and field C a value of 8. The procedure will then operate as follows: (1) The system will examine fields A and B, obtain the values they contain, and compare them. Since in this case the value of B is smaller, it will be moved to the field called MINIMUM. (2) The system will then examine field C and the MINIMUM field, note the values contained in them, and compare them. In this case, the value in the MINIMUM field is the lower. Thus, since the condition IF C IS LESS THAN MINIMUM has *not* been met, the instruction MOVE C TO MINIMUM will be ignored. (The lowest of the three values, of course, is already stored in the MINIMUM field.) (3) The system will then note the name of any field specified in the GIVING clause of the DO command. In this case, there is such a name, and it is different from the function-name given in the BEGIN SECTION command. In such a case, the value in the latter will be moved to the former. Thus, the value 7 will now be placed in the MINIMUM.2 field. (4) The command END MINIMUM.ROUTINE defines the end of the procedure, and the system will then return to the command following the DO instruction.

The reader will see, thus, that the effect of the USING and GIVING clauses in the DO command is to cause a series of data movements. Prior to the execution of the procedure, data named in the USING clause of the DO command will be moved to the parameter fields named in the USING clause of the BEGIN SECTION command. After the procedure has been carried out, the results will be moved from the function fields named in the GIVING clause of the BEGIN SECTION command to the data fields named in the GIVING clause of the DO command.

It is not necessary to employ the USING clause each time a DO command is written, if the programmer wishes to use the values already placed in the parameter fields. However, since the procedure will operate with whatever values are found in the parameter fields, the programmer must be sure that no unintended values are left there. In some cases, it may be useful to place “high values,” “low values,” blanks, or zeros, in a field; the figurative constants, thus, can be used as data-names.

Similarly, the GIVING clause need not be written in a DO command if the programmer intends to refer to the result (or results) as placed in the function field (or fields) named originally in the BEGIN SECTION command.

As the reader has seen, the use of the BEGIN SECTION and DO commands makes it possible to set up basic procedures and to use them with many different kinds of

<!-- page 34 | PDF 40 -->
**[page 34]**

data. If the procedure is properly specified by the use of a BEGIN SECTION command, the programmer may use this procedure for any number of subsequent operations, using data from different fields. The MINIMUM.ROUTINE procedure used in this example might be used in such different ways as the following:

```
DO MINIMUM.ROUTINE USING CALCULATED.PRICE,
    MARKET.PRICE, HIGH.VALUES GIVING PRICE.
DO MINIMUM.ROUTINE USING RAIL.EXPRESS, AIR.FREIGHT,
    PARCEL.POST GIVING SHIPPING.RATE.
DO MINIMUM.ROUTINE USING FLAT.RATE, QUANTITY.RATE,
    HIGH.VALUES GIVING RATE.
```

Note the use of the figurative constant HIGH.VALUES as a data-name in two of these examples. In these cases the figurative constant would cause the highest values in the machine’s collating sequence to be placed in the indicated parameter field. Since the programmer is concerned with choosing the lower of two values, this procedure assures that no unwanted lower value is found in the third parameter field.

### Use of Functions in Procedure Statements

The reader has now seen how the same procedure may be used to obtain different results by processing different data obtained from different fields. The result (i.e., the function) will always be located in a specified field, and thus it may be obtained for use in other procedures. In other words, the function-names of the BEGIN SECTION command may be used like any other data-names, once the procedure has been performed.

However, a still shorter method is available. Instead of having to write a DO command which orders a procedure to be carried out, the programmer may write the name of a function directly in a procedure statement, together with the names of the data items to be substituted for the parameters, and the system will carry out the BEGIN SECTION procedure just as if the DO command had been written. In order to achieve this result, the programmer must specify the data to be used by placing the data-names in double parentheses immediately after the function-name. These names must be separated by single commas.

When this technique is used, the function-name itself must be specified. Since no DO command is used, there is no way of directing that the function be moved from the function field to another field; thus, it can be obtained only from the former.

Referring once again to the example of the MINIMUM.ROUTINE and to the three examples above, the programmer could write such statements as the following:

```
MOVE MINIMUM ((CALCULATED.PRICE, MARKET.PRICE.
    HIGH.VALUES)) TO PRICE.LIST.
SET SHIPPING.COST = MINIMUM ((RAIL.EXPRESS, AIR.FREIGHT,
    PARCEL.POST)) * QUANTITY.
SET RATE.FACTOR = MINIMUM ((FLAT.RATE, QUANTITY.RATE,
    HIGH.VALUES)) * 1.15.
```

All function-names and all parameter-names used in the program must be written in the data description, as explained in Chapter 4. In particular, they must be identified by the type codes FUNCT or PARAM, as appropriate, and they must be described in accordance with the rules governing data description entries.

<!-- conversion notes: All 12 pages (PDF 29-40 / printed 23-34) transcribed from the page images, no image-only fallbacks required. Heading levels for this chunk were inferred from the manual's visual convention (bold left-margin run-in heads = ##, italic/plain run-in sub-heads = ###) since no table of contents was available in this chunk to confirm exact hierarchy: "AND, OR, and NOT" (p.23) is treated as a ### continuing the ## in effect from the previous part; "Truth Functions," "Clauses," "Sentences," "Sections," "Divisions," "Punctuation and Spacing," "Lists, Tables, and Subscripts," and "Functions" are treated as ##; "Imperative Clauses," "Conditional Clauses," "Subscripts," and "Use of Functions in Procedure Statements" are treated as ### under the preceding ##. The character transcribed as "±" in "a * VARIABLE ± b" and "ITEM (BASE ± 1)" (p.31) is printed in the source as a plus-sign glyph with an extra tick above and below (distinct from the plain "+" used elsewhere, e.g. "A + B * C" on p.27), so it has been rendered as the Unicode plus-minus sign per the golden rule of fidelity to the printed source. On p.34, the source literally prints "MARKET.PRICE." with a period (not a comma) before "HIGH.VALUES" in the MOVE MINIMUM example, inconsistent with the parallel comma-separated lists in the surrounding examples; this apparent original printing inconsistency has been preserved as printed rather than silently corrected. No overpunched/overbar digits appeared in this page range. -->
