# Appendix 3: Glossary

<!-- page 111 | PDF 116 -->
**[page 111]**

Following is a list of important terms which are used frequently in this manual, including a number which have certain specialized meanings when used with respect to the Commercial Translator system. The definitions given in this glossary are not exhaustive, and the reader is referred to the text of the manual for amplification when required.

**ABSOLUTE VALUE**

The value, or magnitude, of a number, regardless of sign. When used arithmetically, the absolute value is treated as having a plus sign.

**ADDRESS**

In data processing, a specific location within storage, or a specific item or feature of data processing equipment. In the Commercial Translator language, addresses are represented by names. *Actual address, absolute address, or machine address*—an address defined in terms of the operating specifications of a data processing system; such addresses are not used by the programmer in writing Commercial Translator programs.

**ALPHABETIC**

With respect to data, consisting of one or more non-numeric characters, including the blank. As used in the Commercial Translator system, the term is not limited to the letters of the alphabet.

**ALPHAMERIC**

In the Commercial Translator system, consisting of any of the characters of a machine's character set, except that an alphameric literal may not contain a quotation mark. (See the rules governing literals in Chapter 2.)

**ARITHMETIC EXPRESSION**

An expression containing any combination of data-names, literals, constants, and truth functions, joined together by one or more arithmetic operators in such a way that the expression as a whole can be reduced to a single numeric value. (See the discussion of arithmetic expressions in Chapter 2 and the commands SET and ADD in Chapter 3.)

**CHARACTER**

One of a set of elementary symbols which may be arranged in ordered groups to express information. These symbols may include the decimal digits 0 through 9, the letters A through Z, punctuation symbols, special input and output symbols, and any other symbols which may be accepted by a data processing system.

**CLAUSE**

In the Commercial Translator language, a group of words (including symbols where appropriate) which either expresses a complete command or defines a condition to be tested. (See also IMPERATIVE CLAUSE and CONDITIONAL CLAUSE.)

**CLOSED SUBROUTINE**

In the Commercial Translator system, a section of procedure which is executed by means of a DO command. Also called a linked subroutine. (See also OPEN SUBROUTINE.)

**COMMAND**

In the Commercial Translator language, a verb and its associated operand(s).

**COMPOUND NAME**

In the Commercial Translator language, a name consisting of two or more simple names combined for the purpose of making the right-most one unique, in accordance with the rules given in Chapter 2 of this manual.

**CONDITION**

In the Commercial Translator language, the presence of a specified value in a variable field. (See CONDITIONAL EXPRESSION.)

**CONDITIONAL CLAUSE**

A clause containing a conditional expression introduced by the word IF and terminated by the word THEN.

<!-- page 112 | PDF 117 -->
**[page 112]**

**CONDITIONAL EXPRESSION**

In the Commercial Translator language, an expression which has the particular characteristic that, taken as a whole, it may be either true or false, in accordance with the rules given in Chapter 2 of this manual.

**CONDITION-NAME**

A name assigned by the programmer to a value, representing one of several conditions, which may be present in a data field, in accordance with the rules given in Chapter 2 of this manual.

**CONSTANT**

A value which is to be used in a program without alteration, in accordance with the rules given in Chapter 2 of this manual. While a literal may be thought of as a special form of constant, most constants have names which are specified by data description entries, as explained in Chapter 4.

**DATA DESCRIPTION**

That portion of a Commercial Translator program which consists of entries defining the nature and characteristics of the data to be used in the program. The data description is one of the three main divisions of a Commercial Translator program, the others being the procedure description and the environment description. (See Chapter 4.)

**DATA-NAME**

A name assigned by the programmer to an item of data for use in a Commercial Translator program, in accordance with the rules given in Chapter 2 of this manual.

**DIVISION HEADER**

One of three special words used to identify the beginning of a main portion of a Commercial Translator source program. The three words are *DATA, *ENVIRONMENT, and *PROCEDURE, identifying, respectively, portions of the data description, environment description, and procedure description divisions.

**ENVIRONMENT DESCRIPTION**

That portion of a Commercial Translator program in which the programmer specifies the equipment and equipment features to be used in a program, such as the nature of the input and output equipment, the size and nature of the storage area available, and so on. This subject is discussed in the manuals covering the processors for the various data processing systems.

**FIELD**

In the Commercial Translator system, an item of data which can be operated upon by the arithmetic and/or data transmission verbs. It is usually thought of as a small unit or element of data, as opposed to a *record*, which is usually composed of a number of fields.

**FIELD PICTORIAL**

The representation of the nature and length of an item of data by means of the Commercial Translator format characters, in accordance with the rules given in Chapter 4 of this manual.

**FIGURATIVE CONSTANT**

One of several constants which have been "pre-named" and "pre-defined" in a Commercial Translator processor so that they can be written in the procedure statements without data description entries. The figurative constants are BLANK(S), ZERO(S), HIGH.VALUE(S), and LOW.VALUE(S).

**FILE (noun)**

In the Commercial Translator system, a body of data, stored in some external medium, which can be made accessible to the system by the verb OPEN.

**FIXED WORD**

One of a selected list of words having special meanings in the Commercial Translator system and not available to the programmer except in accordance with the rules specified in this manual. A list of fixed words appears in Appendix 2 of this manual.

**FLOATING POINT**

A form of representing a number x by a pair of numbers Y and z in the form x = Y × Bᶻ, where B is the number base used. In the decimal system, B = 10; in the binary system, B = 2. The decimal system is used in the Commercial Translator source language. To illustrate: the number 127.6 would normally be represented as .1276 × 10³ (or, in Commercial Translator notation, .1276F3). The quantity Y is called the fraction or mantissa, and in the best notation lies between 0 and 1. The quantity z is called the exponent or

<!-- page 113 | PDF 118 -->
**[page 113]**

power. This form is used mainly in scientific calculation where the size of computed quantities is difficult to predict and allow for.

**FORMAT CHARACTER**

One of the characters specified in the table of format characters in Chapter 4 of this manual for indicating the characteristics of data in the data description portion of a Commercial Translator program.

**FUNCTION**

In the Commercial Translator system, a result obtained as a consequence of a procedure; specifically, a result named in the GIVING clause of a BEGIN SECTION command. (See the discussion of functions in Chapter 2 of this manual, and the BEGIN SECTION command in Chapter 3.)

**FUNCTION-NAME**

A name assigned to a function by the programmer. (See FUNCTION.)

**HEADER**

(See DIVISION HEADER.)

**IMBEDDED PERIOD**

A period contained within a Commercial Translator name in such a way that it is not adjacent to a blank.

**IMPERATIVE CLAUSE**

A clause expressing a complete command; it consists of a verb and its operand(s).

**INSTRUCTION**

A code, symbol, or group of symbols, which causes a data processing system to perform an operation of some kind. An instruction usually consists of a code specifying a kind of operation, and an address which indicates the data and/or item of equipment on which the operation is to be performed.

**INTEGER**

A whole number. E.g., 54 is an integer, while 54.6 is not.

**JUSTIFICATION**

1. In printing or listing, the alignment of a margin. 2. In the internal storage of data within a processing system, the alignment of data with respect to the left or right boundaries of machine words, as explained in Chapter 4 of this manual.

**LEVEL**

In the Commercial Translator system, the status of one item of data relative to another, showing whether one is to be treated as a part of the other or whether they are unrelated, as specified in the rules governing level numbers in Chapter 4 of this manual.

**LITERAL**

A value expressed literally in a procedure statement, as opposed to a value represented by a name. Thus, 2 is a literal, whereas the name TWO could be one of a number of possible names used to represent the value 2. (See the rules governing literals in Chapter 2 of this manual.)

**LOOP**

A coding technique whereby a group of instructions is repeated, usually with modification of at least one of the instructions in the group and/or with modification of the data being operated upon.

**MACHINE LANGUAGE**

The system of codes by which instructions and data are represented internally within a particular data processing system.

**MACHINE WORD**

(See WORD.)

**MACHINE-INDEPENDENT**

An adjective used to indicate that an instruction or a program is conceived, organized, or oriented without specific reference to the technical characteristics of any one data processing system. Use of this adjective usually implies that the instruction or program is oriented or organized in terms of the logical nature of a problem, rather than in terms of the technical means of solving it.

<!-- page 114 | PDF 119 -->
**[page 114]**

**MEMORY**

Main storage. (See STORAGE.)

**MODE**

A system of data representation used within the storage section of a data processing system.

**NUMERIC**

1. With respect to data, having a numeric value. 2. With respect to literals, consisting wholly of numerals and their included decimal points, plus and minus signs, and floating point symbols, if any.

**OBJECT PROGRAM**

A program in machine language resulting from the translation of a source program by a processor.

**OBJECT TIME**

The time at which an object program is executed.

**OPEN SUBROUTINE**

In the Commercial Translator system, a section of procedure which is executed by a means other than the DO command. Also called an "in-line" subroutine. (See also CLOSED SUBROUTINE.)

**OPERAND**

In the Commercial Translator language, the "object" of a verb—i.e., the data or equipment governed, or operated on, by a verb.

**OPERATOR**

In the Commercial Translator language, a word or symbol, other than a verb, which directs the data processing system to take some action. E.g., the arithmetic operator + instructs the system to perform an addition, and the conditional operator IF directs it to test a conditional expression.

**PARAMETER**

In the Commercial Translator system, a value used in a procedure to obtain a result; specifically, an item of data named in the USING clause of a BEGIN SECTION command. (See the discussion of functions in Chapter 2 of this manual, and the BEGIN SECTION command in Chapter 3.)

**PARAMETER-NAME**

A name assigned to a parameter by the programmer. (See PARAMETER.)

**PROCEDURE**

In the Commercial Translator system, a sequence of one or more instructions used to perform some operation. A routine or subroutine.

**PROCEDURE DESCRIPTION**

That portion of a Commercial Translator program which consists of instructions directing the data processing system to take specified actions. The procedure description is one of the three main divisions of a Commercial Translator program, the others being the data description and the environment description.

**PROCEDURE-NAME**

A name assigned by the programmer to a procedure for use in a Commercial Translator program, in accordance with the rules given in Chapter 2 of this manual.

**PROCESS TIME**

The time at which a source program is translated into an object program.

**PROCESSOR**

A specialized program used to translate a source program into an object program.

**PROCESSOR VERBS**

Verbs which give instructions to the processor to be acted upon at the time the source program is being translated into the object program. Such verbs do not act at object time.

**PROGRAM**

A complete sequence of instructions directing a data processing system to perform an operation. The term implies an extended sequence incorporating all of the detailed steps and subroutines required to complete a job. (See also OBJECT PROGRAM and SOURCE PROGRAM.)

<!-- page 115 | PDF 120 -->
**[page 115]**

**PROGRAM VERBS**

Verbs which cause the processor to generate machine instructions which will be part of the object program.

**QUALIFICATION**

With reference to Commercial Translator names, the technique of modifying a name by the addition of another name in order to make it unique, in accordance with the rules given in Chapter 2 of this manual. A qualified name is generally known as a *compound name*.

**RECORD**

In the Commercial Translator system, a sequence of data which can be made accessible to the system by the verb GET. A record usually consists of a number of fields.

**RELATIONAL EXPRESSION**

In the Commercial Translator language, an expression that describes a relationship between two terms. E.g., A IS GREATER THAN B, or X IS EQUAL TO 10.

**ROUND**

To shorten a number by applying some rule to adjust the least significant remaining digit. In the Commercial Translator system, this digit is increased by 1 when the part removed is greater than or equal to one-half. Thus, in the decimal system the number 126.5027 would be rounded to 127, because the last number removed is 5 or greater. Rounding need not occur just at decimal points. For a 6-position field the number would be rounded to 126.503; for a 2-position field it would be rounded to 13, which would be understood to be 130.

**ROUTINE**

In the Commercial Translator system, a sequence of one or more instructions used to perform some operation. A procedure or subroutine.

**SECTION**

In the Commercial Translator language, one or more consecutive sentences defined in accordance with the instructions governing the BEGIN SECTION and END commands, as explained in Chapter 3 of this manual.

**SENTENCE**

In the Commercial Translator language, a complete statement specifying one or more operations, in accordance with the rules given in Chapter 2 of this manual. It is always terminated by a period.

**SOURCE LANGUAGE**

As used in this manual, the Commercial Translator language.

**SOURCE PROGRAM**

As used in this manual, a program written in the Commercial Translator language.

**STATEMENT**

As used in this manual, a clause or a sentence.

**STORAGE**

A medium in which data may be retained. Storage may be internal or external. *Main storage*—the principal internal area in which data is retained for active use within a data processing system. *Auxiliary storage*—a supplementary storage medium, less active in use than main storage, in which data may be retained; data in auxiliary storage can be addressed directly by the system, but access is generally slower than to main storage.

**STORED PROGRAM**

A data processing program which is stored internally, within a data processing system. The program itself occupies storage in the same manner as the data used in the program and may be treated as if it were data.

**SUBROUTINE**

In the Commercial Translator system, a sequence of one or more instructions used to perform some operation. A procedure or routine.

**SUBSCRIPT**

An integer used to identify a particular item in a list or table, in accordance with the rules specified in Chapter 2 of this manual. It may be written in a Commercial Translator program as a numeric literal, a data-name, or a limited form of arithmetic expression.

<!-- page 116 | PDF 121 -->
**[page 116]**

**TRUNCATED**

Shortened by dropping the less significant digits of a number, as opposed to *rounded*. (See ROUND.) E.g., the number 2063.78 becomes 2063.7 when truncated, 2063.8 when rounded.

**TRUTH FUNCTION**

An expression consisting of the truth operator TR, followed by a conditional expression, in accordance with the rules given in Chapter 2 of this manual. A truth function acquires a value of 1 if the conditional expression is true, a value of 0 if the expression is false.

**UNARY OPERATOR**

An operator which refers to a single data-name or parenthetical expression; e.g., ABS is a unary operator.

**VARIABLE**

In the Commercial Translator system, a field in storage which may contain different values at different times during the running of the object program.

**VERB**

In the Commercial Translator language, one of a selected list of words that cause a data processing system to take an action. (See Chapter 3 of this manual.)

**WORD**

In the Commercial Translator language, a basic unit of the language, serving the same general purposes as words in other languages. *Machine word*—a subdivision of storage having a fixed size.

<!-- conversion notes: All pages (PDF 116-121 / printed 111-116) transcribed as plain text against the page images; no images embedded (no figures/tables on these pages). Corrected several OCR errors against the image: "SET and ADD" (OCR read "App"), "the name TWO" (OCR gave lowercase/mixed case "Two"), "lies between 0 and 1" (OCR misread "1" as "|"), "X IS EQUAL TO 10" (OCR gave "To"). Restored italics present in the source for defined/cross-referenced terms embedded in running text (Actual address/absolute address/machine address, Main storage/Auxiliary storage, Machine word, compound name, rounded) which the OCR layer did not mark. The FLOATING POINT entry's formula "x = Y × Bᶻ" uses Unicode superscript for the printed exponent z; ".1276F3" is COMTRAN literal notation as printed, not a superscript. No overpunched/overbar digits occur in this chunk. -->
