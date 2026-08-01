# Chapter 4: Data Description

## What a Data Description Is

<!-- page 61 | PDF 67 -->
**[page 61]**

The preceding chapter has shown how to write instructions that direct the computer to perform various kinds of operations. Up to this point, the discussion has been limited to operations that act directly on the actual data of the problem being solved. It has been assumed that the various items of data had already been placed in the system for this purpose.

In actual practice, however, the programmer must make the arrangements for placing the data into the system in a manner which permits it to be used efficiently. Although this is not difficult, it requires thoughtful planning. It assumes that the data is arranged according to a well defined plan, and it consists of furnishing the system with information about that plan. If the data is not suitably organized, the programmer must work out an appropriate plan and arrange the data accordingly. The principles involved are not unlike those the programmer would follow if he were designing a set of business forms for handling the data manually.

The need for doing this should quickly become apparent. Suppose, for example, that a clerk has jotted down on a scrap of paper the figures "46.30." These figures presumably represent a value that means something to him. But could anyone else tell what kind of a value this is? Is it, for example, a unit selling price? The number of hours worked by an employee? A discount? The percentage of water in a chemical product? Obviously, the number, standing alone, has very little practical significance.

In normal business operations, of course, there are several means of identifying values of this kind. In some cases the number will actually be labeled. In many other cases its identity will be seen at once from the fact that it appears in a particular position on a particular form, or that it is written in a certain column in a certain ledger.

When data is entered into a data processing system, it is rarely feasible to label each number. If "46.30" is a rate of pay, for example, the programmer would not write "$46.30 per 40-hour week." Neither would he write "46.30 lbs. per cu. ft." if it were a measure of weight. The value would be entered simply as a number, and the programmer would have to find some other way to show what the number represented. The method of doing this is explained in this chapter.

### The Purpose of a Data Description

It can be said, therefore, that a major purpose of writing a "data description" is to furnish the processing system with a means of identifying each item of data which has been named in the procedure statements. This description must include all items on which the system is to operate.

Actually, the system needs more than a means of merely identifying the data. If the data is numeric, for instance, there must be a means of showing where the decimal point is located. If the system is to print out monetary values, it must have information on where to place the dollar sign, and whether or not to print leading zeros. Details of this sort are usually referred to as "editing." Some of them are handled automatically by the processor, so that the programmer need not concern himself with them. In other cases, the programmer can specify one of several methods for handling a particular situation; in such a case, the data description allows him to give the required instructions.

Writing a data description is not difficult, once a few basic principles are understood, and these are explained in the following pages.

<!-- page 62 | PDF 68 -->
**[page 62]**

The reader should realize, moreover, that this method of describing data in a separate section of the program has a number of important advantages.

In the first place, the typical program will deal repeatedly with data of the same kind. Use of a separate data description permits the programmer to describe each kind of data once, instead of having to describe each individual item as it occurs.

A second consideration is that, once a given set of data has been described, the same description can be used again as part of a new program that works with the same data, or the same kinds of data. This would be a considerable advantage even if it were necessary to copy the data description into the new program by punching new cards. In practice, however, the data description can actually be stored in the library, on tape or in cards, so that it can be called for when needed.

Finally, the Commercial Translator data description is so designed that a program developed for use on one data processing system can be run on a different kind of system (within limits) with relatively few changes in the data description. A basic reason why this is possible is that the data description is tailored to the logical structure of the data files, which do not alter materially from machine to machine, while most of the details that relate to actual equipment are handled by the processors furnished for the various machine systems. The programmer is thus spared many of the problems that can arise when it is necessary to run a program on a system other than the one for which it was originally designed.

A data description for a data processing system contains a number of elements which are already familiar to those who have worked with punched card equipment. As most readers will recognize at once, punched card operations require that data be arranged in the cards in accordance with a definite pattern. In essence, each item of data is identified by its physical position in the card. Thus, if the first six columns of a deck of payroll cards are reserved for employee numbers, the system will treat all values in those columns as employee numbers, unless special coding is used to indicate exceptions. But any such exceptions must be indicated by codes which are themselves identifiable by their positions in the card. In short, the key to identifying a value in a punched card is its position in the card.

The same basic rule applies to electronic systems, but the number of possible positions is greatly increased. Moreover, data can be shifted from one position to another. Yet it is always the position of the data that identifies it, and it is one of the functions of a Commercial Translator processor to keep track of the position of each item.

For this reason, a major part of a data description consists of the details necessary to determine the position of each item. Among other things, it is necessary to give the length of each kind of item (that is, the space it will require) and its relative position in the file. The processor will use this information to assign an initial location in storage for each kind of data. At the same time, it will note the name which the programmer has assigned to the item. By relating this name to the location, the program will be able to find the item when it is referred to by name. Furthermore, it will keep track of all changes in the position of the item; this saves the programmer from having to deal with internal addresses in the system and permits him to refer to data by name.

It follows, of course, that the efficiency of the program will depend in part on the arrangement of the data. The data description provides for describing a data organization already in existence. If the arrangement of the data does not take full advantage of the capacities of the system, the programmer may wish to reorganize the original input data before writing the data description.

## Files, Records, and Fields

<!-- page 63 | PDF 69 -->
**[page 63]**

Before proceeding with the details of the data description it is only necessary to define three terms as they are used in the Commercial Translator system: "file," "record," and "field." The exact implication of these terms varies from person to person and company to company. In this manual they are used to distinguish between kinds of data that can be operated on by different Commercial Translator instructions. Thus, the verbs OPEN and CLOSE can operate only on files, and a file must therefore be regarded as a body of data organized for use within the scope of those commands. Similarly, the verbs GET and FILE can operate only on records, so that a record can be defined as a body of data which can be governed by those commands. Fields, on the other hand, are subordinate units of data and are not readily definable in terms of the commands that affect them. While these definitions may seem somewhat arbitrary, it will be found that in practice they correlate with normal principles of data organization.

### Files

A file is a body of data stored in some external medium which can be made accessible to the system by the use of the verb OPEN. In this sense, an external medium is any medium which provides input to the system from without. Data in such a medium cannot be used by the system until it has been brought into it, which is the basic purpose of an OPEN command. The usual external medium of electronic data processing systems, of course, is magnetic tape.

The concept of a file as "external" to the system carries certain implications which should be considered. These arise, not from the definition of a file, but rather from certain practical considerations.

For example, a file is usually a relatively large body of data, although there is no implied relationship between the length of a file and the storage capacity of a tape. Thus, there may be more than one file on a tape, and, on the other hand, a file may extend over a number of tapes.

A file is commonly understood to consist of a number of individual records, the records being generally similar to each other in size, content, and format. (Sometimes a series of differing records may be grouped together in a file; in such a case, the programmer must make provisions for distinguishing among them.) The file itself may be unique, or it may closely resemble other files. Thus, a file of actuarial data might be the only one of its kind in a library, while a file of insurance policy data might differ from another chiefly because it covers a different area or a different period of time. In this sense, a file serves a function like that of a ledger, or a filing cabinet containing a series of similar papers. It is usually a rather large body of related information. Thus it is convenient in most cases to treat such large bodies of data as complete and separate units which can be identified externally by direct reference to the physical media in which they are stored. Such media may be controlled only by the OPEN and CLOSE instructions, and this fact accounts for the definition of a file used in the Commercial Translator system.

Many files contain special records which are used primarily to identify the file and its contents. These records are called "labels." If labels are used, one is normally placed at the beginning of the file, and another is placed at the end. These labels correspond in many ways to the labels on file drawers, except that certain technical information is required because of the nature of an electronic system. Many of the details of labeling are handled automatically by the "input-output package" provided for each system. Most labeling procedures are prescribed in the environment description for each machine system, and will be discussed, therefore, in the publication covering the Commercial Translator processor for each particular system.

<!-- page 64 | PDF 70 -->
**[page 64]**

However, the programmer has the option of prescribing certain details of a label by the use of the LABEL type code, which is discussed later in this chapter.

### Records

A record is a portion of a file which can be made accessible to the system by the verb GET, assuming the file has previously been "opened." The size and position of a record in storage are determined by the specifications given in the data description. Its contents are referred to by their location in storage, whereas a file, as such, is never actually brought into storage. In other words, a record, unlike a file, is conceived as an "internal" body of data, even though it may be stored externally for long periods of time as part of a file.

Usually, but not necessarily, the records within a file are similar to each other in content, size, and format. For example, there might be a file called PAYROLL RECORD—EASTERN REGION, which would contain hundreds, or thousands, of individual payroll records. Each individual record would normally contain data relating to a particular employee, such as his name, employee number, job title or class, pay rate, dependency classification, deductions, and so on. The separate parts of a record might be quite dissimilar, but they would all relate to a single subject (in this case, an employee), and other records in the same file would carry similar information about other employees. Furthermore, each item would occupy the same relative position in one record that it does in another; it would also have the same format and be of the same size. This makes it possible to describe each kind of data instead of each individual item of data.

A record may be obtained for use by the verb GET, and, when processing has been completed, it may be placed in an output file by the verb FILE.

### Fields

A field is a block of data which can be operated on as a unit by the arithmetic commands and by the commands that control the movement of data within the system (other than the verbs GET and FILE). In many cases, a field will be a subordinate part of a record (such as a PAY.RATE field within a record called PAY.RECORD). However, this relationship does not necessarily hold. A record may contain only one field, for example, and, in fact, several records, or parts of several different records, may be regrouped within storage to form a new block of data which can then be treated as a field. Fields must always be defined in the data description.

In most cases, a field is considered to deal with only one element of data, at least for the purposes of the operation being performed. In a payroll record, for instance, such items of data as employee name, pay rate, employee number, and so on, would each be treated as a field. In practice, a field may be further subdivided. The classic example is the representation of a date. According to one view, the complete date, consisting of day, month, and year, is a single field, and the smaller components are regarded as "subfields." Another view holds that day, month, and year are each fields, and that the complete date is a group of fields.

As far as the Commercial Translator language is concerned, however, distinctions between subfields, fields, and groups of fields are handled by assigning "level" numbers to the various components. This is explained later in this chapter. It is felt that this method eliminates confusion that could result from trying to show relationships among the smaller units of data by the use of only three terms (i.e., field, subfield, and group of fields), and it allows, through the use of level numbers, a greater degree of flexibility in organizing the data. In general, it should be understood that a field is any element of data which can be operated upon by arithmetic and/or data transmission verbs.

## Data Description Format

<!-- page 65 | PDF 71 -->
**[page 65]**

The detailed information which must be supplied in order to describe the data fully can be entered into the system easily by the use of punched cards. A separate card is used for each kind of data item. The format of the card is reflected in the data description form, which is illustrated in Figure 1.

The spaces on this form correspond exactly to the columns of the cards, so that the information written on each line of the form can be punched directly in a card without editing. Since the form provides a field for each of the various kinds of information required, it will serve in this chapter as a convenient check-off list by which to list and discuss each of the items required in the data description.

A "division header" must be placed immediately before the first entry of each consecutive group of data description cards. The name `*DATA`, placed so that the asterisk is in Column 7, should be the only entry on the line (i.e., card), except for the serial number and identification entries in Columns 1-6 and 73-80.

### General

As will be seen from the illustration, the form provides spaces for each column in the card. The spaces representing Columns 1 through 3 and 73 through 80 are shown only once, since the information they will contain is assumed to be repeated for each line of the form. The information to be written in Columns 4 through 72, however, will vary from card to card, and spaces corresponding to these columns are therefore provided on each line.

The programmer should follow these space marks exactly, so that each item of information will be punched in the columns reserved for it. It will be noted that the data description format differs from the procedure description format in several ways. In particular, the former is more rigid; it does not allow "free form" description.

The columnar format of the card is summarized in the following table:

| Columns | Number of Columns | Use |
|---|---|---|
| 1-6 | 6 | Card Serial Number |
| 7-22 | 16 | Name |
| 23-24 | 2 | Level Indication |
| 25-30 | 6 | Type |
| 31-35 | 5 | Quantity |
| 36 | 1 | Mode |
| 37 | 1 | Justification |
| 38-71 | 34 | Description |
| 72 | 1 | Continuation Indication |
| 73-80 | 8 | Identification |

### Ctl. and Serial (Col. 1-6)

It is essential that each item of the data description be entered into the system in proper sequence, since the sequence controls the internal position of the data. The first six columns are reserved for a serial number, which is used to indicate the sequence of the cards. This number is normally numeric. Its first three digits are written in the box marked "CTL" (for "control"), which corresponds to Columns 1 through 3. It is assumed that the first three digits will be common to all serial numbers written on the same page. Although these digits must be punched in each card, it is sufficient to write them once in the CTL box, instead of repeating them on each line.

The remaining digits are written in the box labeled "SERIAL," which corresponds to Columns 4 through 6. In normal practice, only Columns 4 and 5 are used initially,

<!-- page 66 | PDF 72 -->
**[page 66]**

![Blank IBM Commercial Translator Data Description coding form, ruled with columns for CTL., Program, System, Page, Programmer, Date, Ident., Serial, Data Name, Level, Type, Quantity, Mode, Justify, Description, and Cont.](images/page-072.png)
*Figure 1. Commercial Translator Data Description form (page 66).*

The form itself carries no punched entries; the following transcription reproduces only the printed headings and column-number guides.

```
IBM                       COMMERCIAL TRANSLATOR DATA DESCRIPTION

CTL.    PROGRAM                                                        SYSTEM            PAGE      OF
1   3
        PROGRAMMER                                                     DATE              IDENT.  73      80

SERIAL  DATA NAME                                    LEVEL  TYPE     QUANTITY  MODE JUST  DESCRIPTION                                            CONT.
4    6  7                                          22 23  24 25   30 31    35   36   37   38                                                  71  72

[all entry lines on this form are blank]
```

<!-- page 67 | PDF 73 -->
**[page 67]**

and Column 6 is left blank. This makes it possible to insert correction cards later if necessary. The blank is the first character in the collating sequence and will therefore be placed in sequence before any other character in the same column. Thus, if the numbers 23 and 24 have been punched in Columns 4 and 5, each will be read as a three-digit number with a blank in the third position, and a correction card with the number 235 would be collated between them.

When the cards are read into the data processing system, their serial numbers will be checked for correctness of sequence. In all IBM machines the numeric collating sequence is, first, the blank, then the numerals from 0 to 9. Alphabetic characters, if any, will be checked for sequence in accordance with the collating sequence of the particular machine system.

### Data Name (Col. 7-22)

Columns 7 through 22 are reserved for any name which the programmer may have assigned to the data described in the card. The rules for forming names (see page 15) state that a name may contain as many as 30 characters. The card format provides only 16 columns, however, so that any name having more than 16 characters must be carried over to the "Data Name" columns in a succeeding line. In order for the processor to recognize this situation, the programmer must place a character in the continuation indication column (Column 72). Any non-blank character will serve the purpose. The processor will then be able to combine the two parts of the name into a single name. The programmer need not worry about the point at which the break between lines occurs; the processor will close up any blanks occurring in the "Data Name" columns. This provision allows the programmer to indent the carryover if he wishes.

Names are usually written with an assumed left margin immediately to the left of Column 7. They may be indented from this assumed margin if the programmer wishes, but the processor will ignore any indentation. If no name is assigned, Columns 7 through 22 should be left blank.

Names may be assigned to any item of data, or to any group of data items stored consecutively within the system. Thus, names may be given not only to groups of items in the input files, but also to groups formed within storage as a result of operations performed by the system. Any name so assigned may be used as an operand in a procedure statement.

All data-names used in the program must be defined in the data description. In actual operation, the system will convert these names to actual machine addresses when the object program is assembled and will use those addresses as the actual means of locating the data. The purpose of writing the names in the data description is to furnish the processor with the information it needs to do this.

Data-names must not overlap. Each field within a record can be given a name, and any group of consecutive fields can also be given a name. Thus, a single field may be operated on individually by reference to its name, or collectively as part of a group called by the group name. However, the same field may not be included as a part of each of two overlapping named groups of fields.

For example, if three successive fields are named A, B, and C, the group name X might be assigned to the pair A and B. If this were done, the name Y could not be assigned to the pair B and C, since field B is already part of a named group of fields. If the programmer needs to be able to refer to fields B and C by a single name, however, he can rename the entire group of three fields, using the REDEF type code described later in this chapter. This procedure would not delete the original names; the new names and the names originally assigned would all be available for use thereafter.

### Level (Col. 23-24)

<!-- page 68 | PDF 74 -->
**[page 68]**

Level numbers are used to describe the way in which a body of data is organized. Basically, level numbers are assigned to items of data to show their relationship to other items of data—or, in other words, to show the structure of a record. Any number from 1 to 99 can be used. All data description entries must be assigned level numbers.

In general, each item is considered to be a subdivision of the last item preceding it which has a lower number. Figure 2 shows how a typical series of files, records, and fields might be organized, using the familiar method called outlining. The file structure is shown by the use of indentation, each item being considered a part of the last item above it which is indented to a lesser degree.

The technique of indentation, in other words, is a visual way of showing level. It may be used in the "Data Name" columns, but it will have no effect on the processor itself. However, since it helps to identify the various levels visually, indentation may be useful in clarifying the file structure when the program is listed.

For comparison, two additional columns have been provided at the right in Figure 2. These show the data classification of each item, together with hypothetical level numbers such as might be assigned to a file structure of this kind. It should be pointed out that entries for files and groups of files are not actually used in the data description.

It is obvious from the outline that each item from EMPLOYEE NUMBER through LOCATION is a part of PAY RECORD, and that each item from FICA through HOSPITALIZATION is a part of DEDUCTIONS, YEAR TO DATE. Had the principle of indentation not been used, the reader might still determine these relationships by examining the level numbers in the right hand column, following the rule that each item is part of the next item above with a lower number. The processor, of course, will ignore any indentation and will store the data in accordance with the level numbers.

It is not necessary that level numbers be assigned in consecutive order, although it is done that way in Figure 2. The items at level 02, for example, might have been assigned level 04, or any other convenient number, as long as it was greater than 01. Similarly, the items at level 03 could have been given any other number as long as it was greater than the number of the next higher classification. In fact, it is often useful to skip numbers when they are initially assigned, to allow for possible regroupings or insertions at a later time.

The reader will also note that each item at the record level and below represents a kind of data, not a specific item of information. Thus, although there will be only one file called EASTERN REGION SALES FORCE, within that file there will be many individual units called PAY RECORD, and each of these will contain information of the same general character and format, as specified by the names of the fields within it. The purpose of the data description is to give information about each of these kinds of data. The data description should be thought of as a "pattern" which the files will follow.

It may be helpful to consider a second method of showing how data may be organized. Figure 3 shows how the same payroll file might be represented in the form of an organization chart.

This chart demonstrates one important fact: Each item of data is, or may be, related to other items above and below it. In other words, the data is organized "vertically"—no item is related directly to any other item at the same level, except through an item at a higher level. One result of this is that if a particular item is of the same kind as other items in the file, it may be identified by reference to the item above it in the organization structure. Thus, the name PAY RECORD does not single out any

<!-- page 69 | PDF 75 -->
**[page 69]**

![Figure 2 table titled "Organization of Payroll Files", listing a standard outline of files, records, and fields for a payroll system alongside the Commercial Translator data classification and level number for each item.](images/page-075.png)
*Figure 2. Typical File Structure (theoretical) (page 69).*

```
Organization of Payroll Files

                                                Equivalent in Commercial Translator
Standard Outline                               Data Classification   Level Number

*EASTERN REGION                                group of files

  *SALES FORCE                                 file
    PAY RECORD                                 record                 01
      EMPLOYEE NUMBER                          field                  02
      EMPLOYEE NAME                            field                  02
        LAST NAME                              field                  03
        FIRST NAME                             field                  03
      JOB TITLE                                field                  02
      COMMISSION RATE                          field                  02
      GROSS PAY, YEAR TO DATE                  field                  02
      DEDUCTIONS, YEAR TO DATE                 field                  02
        FICA                                   field                  03
        FEDERAL INCOME TAX                     field                  03
        STATE INCOME TAX                       field                  03
        SAVINGS BONDS                          field                  03
        HOSPITALIZATION                        field                  03
      NET PAY, YEAR TO DATE                    field                  02
      LOCATION                                 field                  02

  *PRODUCTION FORCE                            file
    PAY RECORD                                 record                 01
      EMPLOYEE NUMBER                          field                  02
      EMPLOYEE NAME                            field                  02
        LAST NAME                              field                  03
        FIRST NAME                             field                  03
      JOB TITLE                                field                  02
      HOURLY RATE                              field                  02
      GROSS PAY, YEAR TO DATE                  field                  02
      DEDUCTIONS, YEAR TO DATE                 field                  02
        FICA                                   field                  03
        FEDERAL INCOME TAX                     field                  03
        STATE INCOME TAX                       field                  03
        SAVINGS BONDS                          field                  03
        HOSPITALIZATION                        field                  03
      NET PAY, YEAR TO DATE                    field                  02
      LOCATION                                 field                  02

*WESTERN REGION                                group of files

  *SALES FORCE                                 file
    PAY RECORD                                 record                 01
      EMPLOYEE NUMBER                          field                  02
        :
        :
      LOCATION                                 field                  02

  *PRODUCTION FORCE                            file
    PAY RECORD                                 record                 01
      EMPLOYEE NUMBER                          field                  02
        :
        :
      LOCATION                                 field                  02

*Files and groups of files are not actually entered as such in a Commercial Translator data
description. Also, none of the names is in Commercial Translator format.
```

<!-- page 70 | PDF 76 -->
**[page 70]**

![Figure 3, an organization chart titled "Organization of Payroll Files", showing a tree diagram from PAYROLL down through Eastern/Western Region, Sales/Production Force, Pay Record, to the individual fields of a pay record.](images/page-076.png)
*Figure 3. Typical File Organization (page 70).*

```
                        ORGANIZATION OF PAYROLL FILES

                                 PAYROLL
                                    |
              +---------------------+---------------------+
              |                                            |
        EASTERN REGION                               WESTERN REGION
              |                                            |
      +-------+-------+                            +-------+-------+
      |               |                             |               |
  SALES FORCE   PRODUCTION FORCE                SALES FORCE   PRODUCTION FORCE
      |               |                             |               |
  +---+---+       +---+---+                     +---+---+       +---+---+
  |       |       |       |                      |       |       |       |
PAY     [PAY    PAY     [PAY                    PAY     [PAY    PAY     [PAY
RECORD  RECORD] RECORD  RECORD]                RECORD  RECORD] RECORD  RECORD]
                                        (01 Level; bracketed boxes are dashed/additional records)

                                PAY RECORD  (01 Level)
                                    |
  +----------+----------+--------+---------+------------------+-----------------+----------+----------+
  |          |          |        |         |                  |                 |          |
EMPLOYEE  EMPLOYEE     JOB   COMMISSION  GROSS PAY        DEDUCTIONS         NET PAY     LOCATION
NUMBER    NAME        TITLE    RATE     YEAR TO DATE      YEAR TO DATE      YEAR TO DATE  (02 Level)
            |
        +---+---+
        |       |
      LAST     FIRST
      NAME     NAME  (03 Level)

                                DEDUCTIONS YEAR TO DATE
                                    |
              +----------+---------+----------+---------------+
              |          |         |           |               |
            FICA     FEDERAL   STATE       SAVINGS       HOSPITALIZATION
                      INCOME   INCOME       BONDS          (03 Level)
                      TAX      TAX
```

<!-- page 71 | PDF 77 -->
**[page 71]**

one unique kind of item, but SALES FORCE PAY RECORD distinguishes one kind of item from any item designated PRODUCTION FORCE PAY RECORD. Similarly, since in this illustration there are two SALES FORCE files, each can be identified by reference to the next higher level. Thus, a particular kind of item might be known as EASTERN REGION SALES FORCE PAY RECORD.

The use of a higher name to identify a lower one is known as "name qualification," and a name so qualified is known as a "compound name." This is an important method of identifying individual items which do not have names unique in the program. It is true that in this illustration the qualifying names are those of files. However, the principle is applicable internally, within files, whenever it is necessary to distinguish between fields having the same name. (See the discussion of compound names beginning on page 15.)

Level numbers are not actually attached to the data in the sense that an employee number is part of a pay record. They are used to instruct the processor to perform certain technical functions which need not concern the programmer. Essentially, they are used *before* the actual data is read into the system, as a means of preparing the system to receive it. Once the data description has been written, the programmer need no longer concern himself with level numbers unless, owing to changes in the data or the program, a new data description should become necessary.

### Type (Col. 25-30)

Columns 25 through 30 are used, when necessary, to show that the data being described is of a certain special type. If these columns are left blank, it will be assumed that the remainder of the particular entry describes a data field or group of fields. The type codes which may be used in these columns are the following:

```
RECORD
COND
FUNCT
PARAM
REDEF
COPY
LABEL
```

Each of these is discussed in the following pages.

#### RECORD

This type code shows that the data being described is a record and is therefore accessible by GET and FILE instructions. This is equivalent to identifying an item of data as an input/output record. Each record named in the data description must also be named in the environment description, as specified in the publication covering the processor for each particular system.

#### COND

The type code COND is used to show that the data referred to is one of the possible conditions which a conditional variable may assume. In the discussion of conditional expressions in Chapter 2, it was pointed out that a conditional variable is the name of a field which will contain, at different times, any of a number of different values, depending on conditions existing in the data. Each of the values that may be placed in the field is a "condition."

In an example used in Chapter 2, the name MARITAL.STATUS was given as the name of a conditional variable. This name refers to a specific field reserved in storage into which values representing conditions will be entered. Typical conditions for this

<!-- page 72 | PDF 78 -->
**[page 72]**

field would be "single," "married," and "divorced." While these words could actually be placed in the MARITAL.STATUS field, it is more economical of space, and generally more efficient, to use codes. The initial letters M, S, and D were used as codes in this example. Thus, the field MARITAL.STATUS might contain any one of these letters at a given time.

However, so that the programmer can refer to these codes by their names, he must specify in the data description which code corresponds to each name. This may be done in the following manner:

Suppose that the field MARITAL.STATUS has been given the level number 06. The names of the conditions which may be entered into the field must then be assigned a lower level (i.e., a higher number) and entered in the data description immediately following the name of the field. This means that they will be treated as if they were each a subdivision of the field, in accordance with the rules for assigning level numbers, although, in practice, only one condition will be considered at a time. A portion of the data description might then appear as follows:

![Excerpt of a Commercial Translator Data Description coding form showing example entries for the field MARITAL.STATUS and its conditions SINGLE, MARRIED, and DIVORCED.](images/page-078.png)
*Data description entries for the MARITAL.STATUS conditional variable (page 72).*

```
SERIAL  DATA NAME                    LEVEL  TYPE     QUANTITY  MODE JUST  DESCRIPTION
 4   6  7                         22 23  24 25    30 31    35   36   37  38

        MARITAL.STATUS               0  6                                 A
        SINGLE                       0  7  COND                           'S'
        MARRIED                      0  7  COND                           'M'
        DIVORCED                     0  7  COND                           'D'
```

The entries under "Description" will be explained later in this chapter, but, in summary, the "A" indicates that the field will contain one non-numeric character, while the initials S, M, and D are enclosed in quotation marks to show that they are the actual values to be used in the program.

In this example, the fact that the names SINGLE, MARRIED, and DIVORCED are the names of conditions is shown by the use of the type code COND. The relationship of these conditions to the field MARITAL.STATUS is shown by the fact that the condition-names have a higher level number and follow the name of the conditional variable immediately.

It should always be remembered that the condition-name is the name of the value which can be placed in a field; it is not the name of the field itself. As was pointed out in Chapter 2, the condition-name MARRIED, in this case, would be equivalent to MARITAL.STATUS = 'M'; it follows that such expressions as SET MARRIED or IF MARRIED will be interpreted to mean SET MARITAL.STATUS='M' and IF MARITAL.STATUS='M' respectively. The condition-name, in other words, is a short way of writing an expression that shows the value in the field.

It is not always necessary to list condition-names in the data description in the manner shown above. If the programmer, when he writes the source program, limits himself to the full form of conditional expressions (such as IF MARITAL.STATUS = 'M' THEN ...), he need not assign names to the conditions. However, if he wishes to use the shorter and more convenient method of referring to conditions by name, he must write a data description entry for each.

#### FUNCT

<!-- page 73 | PDF 79 -->
**[page 73]**

A function has been defined in Chapter 2 as a result obtained by following a procedure. In the Commercial Translator system, the term is used only in connection with procedures specified in the BEGIN SECTION command. Any data-name specified in the GIVING clause of the BEGIN SECTION command is a function in this sense, and it must be identified as such in the data description. The function-name is identified by the type code FUNCT, and the function must be fully described in accordance with the provisions of this chapter. The parameters written in the USING clause of the BEGIN SECTION command must be identified in the data description by the type code PARAM, as explained immediately below. (See the discussion of functions in Chapter 2 and the BEGIN SECTION command in Chapter 3.)

#### PARAM

The type code PARAM is an abbreviation of the term "parameter." It is required, if appropriate, to show that the item of data being described is a parameter for use in a routine used to obtain a function. (See the discussion of functions in Chapter 2, the command BEGIN SECTION in Chapter 3, and the type code FUNCT above.)

Specifically, when the program contains a section introduced by a BEGIN SECTION command, each data-name listed in the USING clause of that command is a parameter, and it must be described as such in the data description.

#### REDEF

The code REDEF is used whenever it is necessary to redefine an area or an item of data that has previously been defined in some other way. This is usually necessary whenever a portion of the program "overlaps" another—i.e., when it calls for the use, on a "time-sharing" basis, of data or storage space which has previously been defined for some other purpose. It is also used in setting up tables in the system.

For example, it may be necessary to call existing data by a new set of names, or to reorganize it by altering the groupings and/or the subordinate level numbers. Frequently it is necessary to wipe out data to make room for other data. In any such case, a new data description is required for the new items or the new names. However, the name or names of the areas being redefined must first be listed, using the type code REDEF to show that the accompanying data description may also be used to refer to the same area. The REDEF entry must have the same level number as the entry being redefined. An illustration will be found later in this section, in the discussion of tables, on page 75.

Use of the REDEF code does not erase data in storage, unless an attempt is made to place two or more different constants in the same area; however, it does superimpose a new format upon the data already present. If the programmer wishes to change an item in storage, such as a value in a table, he may do so by using a MOVE instruction that specifies the new data and the position in storage where it is to be placed.

Redefinition does not cancel the previous definition. It merely makes it possible to refer to the same area by different names and for different uses. Once an area has been defined, all names associated with the definition may be used at any time, regardless of subsequent redefinitions.

<!-- conversion notes:
- Pages processed: PDF 67-79 (printed pages 61-73), all present, none blank.
- Page 66 (PDF 72, Figure 1) and page 70 (PDF 76, Figure 3) are entirely full-page figures with no running body text; both were image-only source pages, embedded as images with a best-effort structural/ASCII-tree transcription. Figure 1's coding form carries no punched entries (blank template).
- Page 69 (PDF 75, Figure 2) is a full-page outline table; embedded as an image with a best-effort fenced-block transcription preserving indentation.
- Page 72 (PDF 78) contains a small coding-form excerpt (MARITAL.STATUS/SINGLE/MARRIED/DIVORCED example) embedded within body text; embedded as an image plus fenced-block transcription of the entries.
- OCR errors corrected against page images: "13M machines" -> "IBM machines" (p.67/PDF73); "ee erronic en" -> "electronic systems" (p.62/PDF68); "docs not" -> "does not" (p.64/PDF70); "Q3" -> "03" level number in Figure 2 (p.69/PDF75). Two apparent OCR noise fragments with no corresponding printed text ("TT Ancsracra thin walatinnach Ag +" on PDF70 and "a0 +h tha h f th th" on PDF74) were omitted as scanning artifacts not present on the page image.
- Per the page-break rule, two sentences that were split mid-clause across a page turn were shifted so the marker falls at the nearest sentence boundary: "The reader should realize, moreover..." (PDF67/68) and "However, the programmer has the option..." (PDF69/70). Other page breaks that fall mid-sentence (e.g. PDF71/73 across Figure 1, PDF74/77 across Figures 2-3, PDF77/78) were left at the physical break point, since shifting would displace more than a few words.
- No overpunched/overbar digits appeared in this chunk.
- Sub-headings such as "Files", "Records", "Fields" (under "Files, Records, and Fields") and "RECORD", "COND", "FUNCT", "PARAM", "REDEF" (under "Type (Col. 25-30)") are rendered as italic in-body headings in the source; reproduced here as ### / #### headings per the heading hierarchy of the section they belong to.
- This part ends mid-list of Type codes; COPY and LABEL type codes are covered in the next part (pages 80+), outside this chunk's range.
-->

<!-- page 74 | PDF 80 -->
**[page 74]**

#### TABLES

A valuable function of the REDEF code is to make it possible to set up tables in storage
and to define the methods of locating individual items in the tables. The following
example shows a method of doing this:

Suppose the programmer wishes to place in memory the table described in
Chapter 2 (see page 29), which shows passenger transportation rates to each of 30
different cities. Each line in this table lists a city, a one-way rate, a round trip rate,
and an excursion rate. If it were printed in a book of rate schedules, it would probably
contain four columns, headed "City," "One-Way," "Round Trip," and "Excursion."
A portion of this table might have the following form:

| City | One-Way | Round Trip | Excursion |
|---|---|---|---|
| ... | ... | ... | ... |
| Los Angeles | 153.42 | 285.16 | 212.87 |
| Miami | 78.60 | 141.63 | 118.92 |
| ... | ... | ... | ... |

To place such a table into a Commercial Translator program, the programmer
must first analyze it to determine the maximum size of each kind of item. He may
find, for example, that 14 character spaces will be required for the longest name in
the "City" list, and that each of the rate listings can be accommodated if space for five
digits is reserved for each rate value.

The actual data may then be entered by copying all of the individual items in sequence
, reading across each line and allowing blank spaces (or zeros) as filler in
those items that occupy less than the allowed space. Thus the initial data entry might
read, in part:

![Coding form: initial data entry for RATE.TABLE constants](images/page-080.png)
*Data description coding form — RATE.TABLE constant entries (page 74).*

```
SERIAL   DATA NAME                      LEVEL   DESCRIPTION

         RATE.TABLE                      01
                                          02     'LOS ANGELES        15342 28516 21287'
                                          02     'MIAMI              07860 14163 11892'
```

The entries at the 02 level, which could extend over as many lines as necessary to
accommodate all of the data, specify a series of constants. These are enclosed in
quotation marks in accordance with the rules for writing constants. Note that decimal
points are not normally required in constants of this kind, since the location of the
decimal point will be specified in a later entry.

The result of this entry is twofold: Space is reserved in memory for the entire
table, and the individual items are stored in a sequence which permits them to be
located after the table has been more fully described. At this point, however, no
means of identifying any single item of data has yet been established. This must be
accomplished by superimposing the format and structure of the table on the data
already placed in storage. It is done by redefining the format of the data, using a
series of entries such as the following:

<!-- page 75 | PDF 81 -->
**[page 75]**

![Coding form: REDEF entries for RATE.TABLE](images/page-081.png)
*Data description coding form — REDEF of RATE.TABLE into RATE, CITY, ONE.WAY, ROUND.TRIP, EXCURSION (page 75).*

```
SERIAL   DATA NAME              LEVEL   TYPE    QUANTITY   MODE  JUSTIFY  DESCRIPTION

                                  01     REDEF                                    RATE.TABLE
         RATE                     02                30
         CITY                     03                                             AAAAAAAAAAAAAA
         ONE.WAY                  03                                             999V99
         ROUND.TRIP               03                                             999V99
         EXCURSION                03                                             999V99
```

In the first of these entries, the data previously defined as RATE.TABLE is redefined
(by the type code REDEF) as a new body of data. In this case a name has not been
given to the redefined data, but the programmer could assign one if he wished. It will
be noted that the level of the new entry (01) is the same as that of the entry being
redefined.

The RATE entry and the four data-names which follow it (CITY, ONE.WAY,
ROUND.TRIP, and EXCURSION) are on lower levels (02 and 03); therefore, they will
be understood to be subordinate elements of the entry at the 01 level, and the code
REDEF will apply to them as well.

The number 30 in the "Quantity" columns, as will be explained later in this chapter
, shows that space is to be reserved for 30 entries at the 02 level. In other words,
there will be 30 items called RATE. It will be seen later that the programmer may
single out any one of these items by appending a subscript to the name RATE. This
subscript may be a literal, a data-name, or a limited arithmetic expression. The value
represented by the subscript must be a positive integer, since it will be used within
the system to count individual items until the required one is reached. (See the discussion
of lists, tables, and subscripts in Chapter 2.)

It has been noted that the name RATE includes all of the four items immediately
following it. Thus, each of the 30 RATE entries will contain one called CITY, one
called ONE.WAY, another called ROUND.TRIP, and a fourth called EXCURSION. Since
30 separate RATE entries were specified, the processor will lay out this entire sequence
30 times.

The characters in the "Description" columns show the length and type of data to
be expected in each field. This is explained more fully later in this chapter, but the
effect of the entries given in the example is as follows: The 14 A's following the name
CITY will reserve space in storage for names of up to 14 characters in length. The
symbols 999V99 will reserve space for five-digit numeric values, with an assumed
decimal point between the third and fourth digits.

Once the processor has this information, it can identify and use any single item of
data in the table. It will know, for example, that the first 14 character spaces of each
RATE listing contain the name of a destination city, that the next five show the corresponding
one-way rate, and so on. In other words, it now has the means of locating
any item by its position in storage, which, as has been noted already, is the way in
which the system locates all items of data in storage.

The programmer may then call for any individual item by its name, using a subscript
to specify which one of the 30 items having the same name is wanted. Thus,
ONE.WAY (17) would obtain the one-way rate for the 17th city in the table. Usually,
however, the subscript would be a variable, such as the name of a field containing a
number.

<!-- page 76 | PDF 82 -->
**[page 76]**

Suppose, for instance, that the input record contains a field called DESTINATION,
and that this field will contain, at object time, a numeric code representing one of the
cities listed in the table. If the programmer writes MOVE ONE.WAY (DESTINATION) TO
BILL.AMOUNT, the system will obtain whatever number has been placed in the DESTI-
NATION field and will use it to determine which item in the table is wanted. It will
then find that item and move it to the field called BILL.AMOUNT. The reader will have
noted that this number determines the position of data by the simple process of
counting lines; the code numbers used, therefore, must be assigned in a sequence
corresponding to the lines of the table.

### COPY

This type code is used to copy a data description previously defined in the program
so that it can be used again elsewhere. This makes it possible to use a data description
with new data-names and, if desired, new level numbers.

The COPY type code is used as follows: The new name of the data description
entry is written in the "Data Name" columns of the new entry. The code COPY is
placed in the "Type" columns. The data description to be copied is specified by
writing its original name in the "Description" columns. This description must already
have been read into the system for the COPY code to be able to operate on it.

The processor will then obtain the original data description and copy it in its entirety
, except for the following modifications: (1) The original name will be replaced
by the new name. (2) If a new level number has been specified for the new name,
the level numbers of the original data description will be adjusted so that they retain
their original relationship to the named entry. Thus, if the original sequence of level
numbers had been 01, 03, 04, and if the new name is assigned level 05, the other
items would now be placed at levels 07 and 08, respectively.

Suppose the programmer had previously written the following entries in the data
description:

![Coding form: PAY.RCD.MASTER data description](images/page-082.png)
*Data description coding form — PAY.RCD.MASTER and, below, the COPY entry for PAY.RCD.DETAIL (page 76).*

```
SERIAL   DATA NAME                    LEVEL  TYPE

         PAY.RCD.MASTER                 01
         EMPLOYEE.NAME                  02
         JOB.TITLE                      02
         HOURLY.RATE                    02
         GROSS.PAY                      02
         TAXES                          02
         FICA                           03
         FED.INCOME                     03
         STATE.INCOME                   03
         NET.PAY                        02
```

Suppose then that he wishes to set up an identical data description for a detail
record, except that the new description is to have the name PAY.RCD.DETAIL and it
will be placed at level 02. He could write the following entry:

```
SERIAL   DATA NAME              LEVEL  TYPE    QUANTITY   MODE  JUSTIFY  DESCRIPTION

         PAY.RCD.DETAIL           02   COPY                                      PAY.RCD.MASTER
```

<!-- page 77 | PDF 83 -->
**[page 77]**

The effect of this entry would be as though the programmer had written an entirely
new set of entries in the following form:

![Coding form: PAY.RCD.DETAIL expanded by COPY](images/page-083.png)
*Data description coding form — PAY.RCD.DETAIL as expanded by the COPY operation (page 77).*

```
SERIAL   DATA NAME                    LEVEL  TYPE

         PAY.RCD.DETAIL                 02
         EMPLOYEE.NAME                  03
         JOB.TITLE                      03
         HOURLY.RATE                    03
         GROSS.PAY                      03
         TAXES                          03
         FICA                           04
         FED.INCOME                     04
         STATE.INCOME                   04
         NET.PAY                        03
```

### LABEL

The type code LABEL identifies a data description as that of a label record. This will
cause a redefinition of the label area in the input-output control system. The actual
use of this code will be explained in the publications pertaining to the various Commercial
Translator processors as they apply to individual machine systems.

### Quantity (Col. 31-35)

If an item of data will be followed by one or more additional items having the same
data description, the programmer can avoid writing the additional data descriptions
simply by specifying in Columns 31 through 35 the total number of times the data
description is required. This number must refer to data items occurring in sequence.

The "Quantity" columns may be left blank, and, in fact, usually are. In that case,
it will be assumed that they contain a value of 1, and the specified data description
will be entered only once.

Since quantity numbers are used to specify sequences of data descriptions for use
in lists and tables, and since data in tables is referred to by the use of subscripted
names, quantity numbers should not be assigned to data items not having names,
unless these items include named items at a lower level.

An example of the use of a quantity entry was included in the discussion of the
REDEF type code when used to set up a table. (See page 75.) The reader will recall
that the field called RATE, together with its subordinate fields, was to be entered 30
times. Accordingly, the value 30 was placed in the "Quantity" columns opposite the
name RATE. Since each of the subordinate items (CITY, ONE.WAY, ROUND.TRIP, and
EXCURSION) was required only once for each RATE entry, no value was placed in the
corresponding "Quantity" columns. If, for some reason, one of the subordinate fields
had been needed more than once, a quantity could have been specified.

Quantity numbers may be specified for as many as three levels in a single "nested"
group. For example, assume that a program must deal with five items called STATE,
that within each of these are four fields named DISTRICT, and that each DISTRICT contains
seven smaller fields called CITY. The quantity 5 should then be written for
STATE, 4 for DISTRICT, and 7 for CITY. The processor will then reserve storage space
for a total of 5 STATE items, 20 DISTRICT items, and 140 CITY items (assuming, of
course, that the level numbers show the proper relationships among the three entries).

<!-- page 78 | PDF 84 -->
**[page 78]**

To call for any one item of data, the programmer must write as many subscripts as
are necessary to identify the particular level. Thus, STATE (3) would call for the
third item called STATE, DISTRICT (3,2) would call for the second DISTRICT field
within the third STATE item, and CITY (3,2,6) would obtain the sixth CITY field in
the second DISTRICT of the third STATE. Subscripts are always written in descending
order of level.

### Mode (Col. 36)

The term "mode" refers to the method by which data is represented, such as the
binary mode or the binary coded decimal mode. For the purposes of the Commercial
Translator, the mode used in the arithmetic units of the system is considered to be
the system's "internal" mode, although the system may be able to read data in other
modes.

Column 36 is used to show whether the data being described is prepared in the
internal mode for the system being used. In that case, the letter I is punched in this
column. Data punched in an "external" mode is represented by the letter E. Specific
information on the modes available for each system will be provided in the publications
covering the processors for the various machine systems.

Since a body of data may contain information in more than one mode, the mode
is specified at the lowest level of data organization—i.e., at the level where the "field
pictorial" is shown. (See the "Description" columns.) Thus, if a record at the 01
level contains two fields at the 02 level, one of them in the internal mode and one in
the external, there would be no point in specifying a mode for the record itself. The
mode (or modes) of a larger unit is therefore a consequence of the mode specified
for each of its components.

### Justify (Col. 37)

The term "justification" is used in printing and writing to mean the alignment of a
margin. Thus, the text of this manual is both "left justified" and "right justified." In
data processing, the term has a similar implication, since it is usually necessary to
specify that data be justified if the programmer wishes it to be printed out with an
aligned margin.

Actually, however, justification means a good deal more than this. Specifically, it
refers to the placement of the data in a unit of storage. In many systems, data is
stored in machine "words" of fixed length. Very often, therefore, a particular item
of data will be shorter than the space allowed for it, and it may be necessary, if alignment
is to be preserved, to provide a means of filling the unoccupied spaces with
non-significant characters, such as zeros or blanks, depending on the system. On the
other hand, it may be desirable to fill all available space with data, so that more than
one item—or parts of more than one item—may be stored in a given machine word.
This is known as "packing."

It is extremely important to recognize that justification specified for an input item
of data—i.e., an item to be entered into the system at object time—describes the
item as it already exists. It does not change the justification; it is used in informing
the system where to look for the incoming data. Justification specified for other
items, however, actually controls the placement of the data. It instructs the system
how to handle the data when it operates on it internally or prepares it for output.

The effect of specifying justification is as follows: If left justification is specified,
the data item is stored, or will be stored, so that its left-hand character is placed in
the left-hand position of the next available machine word. This may mean that the
right-hand portion of the preceding word is left unoccupied. If right justification is
stipulated, the data item is stored, or will be stored, to the right in the next available
machine word, leaving unoccupied whatever portion of that word is not required at

<!-- page 79 | PDF 85 -->
**[page 79]**

the left. If no justification is specified, the data is packed (if it is incoming data) or
will be packed—there will be no blank spaces between successive items.

Packing makes efficient use of storage space, but it may make it more difficult for
the program to obtain the items independently of each other, since the processor may
have to provide for "unpacking." However, packed items can usually be read or
written more rapidly, since the system will not have to process non-significant information.
In general, if the programmer must be economical of storage space, or if the
program calls extensively for reading or writing long sequences of data, it may be
more efficient to pack the data. If a great many of the items must be obtained individually
, however, and/or if scanning long sequences of data is not a common operation
, justification of data may be more efficient. The programmer should evaluate
each case on its particular merits.

Alignment of alphameric information, such as lists of names, cannot be specified
in the field pictorial. If alignment of such data is required, it can be accomplished by
the use of the "Justify" column.

The symbols L and R are used in Column 37 to indicate left and right justification
respectively. If neither symbol is used, the data will be packed, as has already been
noted.

### Description (Col. 38-71)

The "Description" columns are used to show the length of each field of data, together
with its format. They may also be used to specify constants and the names of data
and procedures, as explained below. Specifically, the following kinds of information
may appear in Columns 38 through 71:

1. Format characters. These are shown and described in the table below.
2. Constants.
3. Data names associated with the type codes REDEF and COPY.
4. The word LIBRARY, followed by the name of a data description stored in the
   library.
5. The words QUANTITY IN, followed by the name of a field which will contain a
   quantity when the object program is run.

In a number of cases, a complete data description entry will require that more than
one of these kinds of information be listed on the same line. For example, it is generally
necessary to show both the format and the value of a constant. In such a case,
the various items should be written in the order shown above, separated by one or
more blanks.

#### Format Characters

The format characters serve two functions: (1) They show the number of character
spaces to be occupied by a field. (2) They show the kind of character that will
occupy each space. The resulting data representation is known as a "field pictorial."

If the item of data being described is one which will be brought into the system at
object time, the format characters must reflect the format of the data as it already
exists; changes in input data cannot be effected by the field pictorial. However, if
the item is one produced as a result of the operation of the program—as in moving
the data or performing arithmetic on it, for example—the field pictorial has a direct
effect on the manner in which the data will be handled.

With certain exceptions, which are explained below, one format character is required
for each data character for which storage space is to be reserved. The particular
format character chosen for each space prepares the system to receive in that
space data of the type shown in the table on the following page.

<!-- page 80 | PDF 86 -->
**[page 80]**

| Format Character | Meaning and Use |
|---|---|
| `A` | Any non-numeric character, including the blank. |
| `X` | Alphameric character (any character in the machine's character set). |
| `9` | Any numeric character. |
| `8` | Numeric character, to be replaced automatically by a blank whenever it is a non-significant zero. |
| `*` | Numeric character, to be replaced automatically by an asterisk whenever it is a non-significant zero. |
| `V` | Assumed decimal point. This character informs the processor where the decimal point is located, for purposes of calculation and/or alignment of values. The symbol is not required for integers. The symbol V will not reserve an actual space in storage. |
| `.` | True decimal point. This character will reserve an actual space in storage. |
| `S` | Scale factor. This symbol is used as a "filler" or "spacer" when the input data does not show the position of the decimal point. E.g., a field containing percentages from 1 to 9 would be represented by the notation `VS9`; this would assure that the values 1 to 9 would be interpreted as .01 to .09. Similarly, if a field contains values that represent thousands, each unspecified digit must be represented by an S; thus, the notation `999SSS` would provide for values from 000,000 to 999,000, even though the three right-hand zeros would not appear as input. |
| `$` | Dollar sign. An actual dollar sign will be placed in the indicated position, provided it is not followed by the symbol 8. In the latter case, the dollar sign will "float"—i.e., it will be placed immediately to the left of the first significant digit remaining. |
| `,` | True comma. This symbol will reserve an actual space in storage, to be occupied by the comma. The comma itself may be replaced by a blank, asterisk, or dollar sign, if the operation of a preceding 8 or * has resulted in the elimination of non-significant zeros to the left. |
| `+` | Plus or minus sign, one of which will always be placed in the space reserved for it, depending on whether the value is positive or negative. (Compare with use of minus sign, described below.) This sign may be placed in a column by itself, in which case it will reserve an actual space in storage. Alternatively, it may be entered as an "overpunch" with either of the format characters 8 or 9, in either the units or high-order position of a field; in this case, a special space will not be reserved, and the sign of the field will be indicated in accordance with the operating characteristics of the particular system. |
| `-` | Minus sign, to be placed in the space reserved for it when the value is negative; when the value is positive, the space will be left blank. If punched in a space by itself, this symbol will reserve a space in memory; otherwise, it may be "overpunched" and will act as described in the rules for the symbol +. |
| `F` | Floating point number. This symbol does not reserve an actual space in storage; it informs the processor that the number being described is a floating point number. It is placed between the format characters representing the fraction and those representing the exponent. E.g., `+99V9F+99`. |
| `(n)` | A number placed in parentheses immediately following one of the other format characters instructs the processor to allow for that number of the character specified. E.g., `9(4)A(12)` is equivalent to `9999AAAAAAAAAAAA`. |

![Format Characters table, page 80](images/page-086.png)
*Format Characters table (page 80).*

<!-- page 81 | PDF 87 -->
**[page 81]**

##### EXAMPLES

The following examples indicate the range of characters for which provision is made
by the notation shown:

| Notation | Range of Characters Provided For |
|---|---|
| `AAA` | All characters in the machine's character set except numerals. |
| `88999` | All numeric values from 000 to 99999. |
| `****.99` | All numeric values from ****.00 to 9999.99. |
| `$888,888.99` | All numeric values from $.00 to $999,999.99. |

#### Constants

A constant is a value, or a group of symbols, placed in the program for use without
alteration, such as a fixed percentage rate or a fixed name. A constant may be placed
in the system by writing a data description entry for it which includes both a statement
of its format (using the format characters) and a statement of the actual value
or group of symbols. The format is specified by a standard field pictorial entry. The
actual value, or the actual symbols, must then be written on the same line, separated
from the field pictorial by at least one blank. This value (or this group of symbols)
must be enclosed in quotation marks.

While a literal may be thought of as a form of a constant, the reader should note
two distinctions: (1) Literals are written in procedure statements, whereas constants
are placed in the system by means of data description entries. (2) Constants, unlike
literals, must always be enclosed in quotation marks, even though they may be wholly
numeric.

To illustrate, if the programmer wished to place the percentage .05 into the data
description as a constant, it would be necessary to specify the nature of the constant
by a notation such as the following:

![Coding form: PERCENT.CONST constant entry](images/page-087.png)
*Data description coding form — PERCENT.CONST constant entry (page 81).*

```
SERIAL   DATA NAME              LEVEL  TYPE    QUANTITY   MODE  JUSTIFY  DESCRIPTION

         PERCENT.CONST                                                            V99 '05'
```

In this example, the notation V99 is, of course, the field pictorial, and it is followed
by a statement of the actual value of the constant.

#### Data Names Associated with REDEF and COPY

When the type codes REDEF and COPY are used, it is necessary to specify the name of
the data item or area to be redefined or copied. This name must be entered in the
"Description" columns. (See the discussion of those type codes earlier in this
chapter.)

#### Library Names

The word LIBRARY, followed by the name of a data description stored in the library,
designates a data description which is to be copied. Availability of this code enables
the programmer to store data descriptions which are frequently required, so that he
can save the effort of writing new ones when a previous one will serve his purpose.
When a library data description is prescribed, the type code COPY must be used.

<!-- page 82 | PDF 88 -->
**[page 82]**

#### Quantities Specified in Named Fields

It has been shown that if a value is placed in the "Quantity" columns, the processor
will reserve space for repeating the specified data description until it appears the
number of times indicated by that value. In certain special cases, the programmer
may wish to alter the use of such an area at the time the object program is run. The
storage area, of course, will already have been reserved by the action of the processor,
and at object time it is no longer possible to set aside new areas. However, for certain
specialized purposes, it is possible to regroup the components of an existing area by
using the QUANTITY IN option. In this case, a quantity value is placed in a named
field and the program is referred to this field by the words QUANTITY IN followed by
the name of the field.

This usage is not required in most programs. It represents an advanced programming
technique, providing additional facilities which can be used effectively by a
skilled programmer. While it is not the purpose of this manual to explain the many
refinements and uses of this technique, its general nature is indicated by the following
discussion:

Suppose that a certain data description having the field pictorial 999V99 is to be
repeated until it appears 100 consecutive times. Each iteration of the data description
will reserve 5 character spaces in storage, and therefore a total of 500 spaces
will be reserved altogether. Suppose that this area is referred to by the name TABLE.

Suppose, then, that the programmer wishes to set up a number of different tables
at different times during the running of the object program, using this same storage
area for each. Assume that the first, referred to in this text as Table 1, consists of
10 columns and 10 lines—i.e., there will be 10 data items on each of 10 lines, and
each item will have a field pictorial of 999V99. This table could have been set up by
the original data description for the area in a series of entries such as the following:

![Coding form: TABLE / COLUMN / ITEM with quantities 10, 10](images/page-088.png)
*Data description coding form — TABLE 01, COLUMN 02 (quantity 10), ITEM 03 (quantity 10) (page 82).*

```
SERIAL   DATA NAME              LEVEL  TYPE    QUANTITY   MODE  JUSTIFY  DESCRIPTION

         TABLE                    01
         COLUMN                   02                10
         ITEM                     03                10
```

Once the table is described, the programmer may refer to individual items in it by
the use of subscripts, the first subscript referring to the item at the higher level. Thus,
ITEM (4, 2) would refer to the second item of the fourth COLUMN group.

When the system is directed to obtain this item, it relies on a technique of counting.
Specifically, it would rely on the fact that ten items are specified for each column.
Thus, it would count off the first ten items, then the ten items of the second column,
the ten items of the third column, and it would then count to the second item following.
In other words, it would obtain the 32nd item in the string of data representing
the table.

However, it is supposed that at some other time in the program the programmer
wishes to set up another table (Table 2) which uses the same field pictorial for each
item but which requires a different grouping of columns and lines. Suppose Table 2
has 20 columns and 5 lines. The programmer could theoretically write the following
entries:

<!-- page 83 | PDF 89 -->
**[page 83]**

![Coding form: TABLE / COLUMN / ITEM with quantities 20, 5, and TABLE redefined with QUANTITY IN](images/page-089.png)
*Data description coding form — a second, additive TABLE entry (quantities 20, 5), and, below, the original TABLE entry rewritten using QUANTITY IN COLUMN.QTY / QUANTITY IN ITEM.QTY (page 83).*

```
SERIAL   DATA NAME              LEVEL  TYPE    QUANTITY   MODE  JUSTIFY  DESCRIPTION

         TABLE                    01
         COLUMN                   02                20
         ITEM                     03                 5
```

However, these entries would reserve space in addition to, not in place of, the
original table.

Suppose, however, that the programmer, in setting up Table 1, had written the
following entries:

```
SERIAL   DATA NAME              LEVEL  TYPE    QUANTITY   MODE  JUSTIFY  DESCRIPTION

         TABLE                    01
         COLUMN                   02                                              QUANTITY IN COLUMN.QTY
         ITEM                     03               100                            QUANTITY IN ITEM.QTY
```

Suppose, further, that the names COLUMN.QTY and ITEM.QTY are the names of
fields into which values may be placed. In this case, the processor would first note the
value of 100 in the "Quantity" column opposite the name ITEM and would reserve
space for a total of 100 items to be placed in the table. It would cause the object
program to look in the fields COLUMN.QTY and ITEM.QTY to determine the actual
quantities for the entries COLUMN and ITEM. These values would override any values
previously placed in the "Quantity" columns. If the programmer wished the first
table to have 10 columns of 10 items each, he would have to be sure that a value of
10 was placed in both the COLUMN.QTY and ITEM.QTY fields. Obviously, if Table 1
were never to be replaced by another table, it would be superfluous to use QUANTITY
IN entries, for the quantities could be specified directly in the data description.

However, since the QUANTITY IN entries have been made, it is now an easy matter
to construct Table 2. All that is necessary is to place the values 20 and 5 in COL-
UMN.QTY and ITEM.QTY respectively. If, then, the expression ITEM (4,2) is written,
the system will know that instead of counting ten items to the column it must count
five. Thus, instead of obtaining the 32nd item, it will obtain the 17th, which is the
one required.

If the programmer wished to set up a third table in the same area, with four columns
and 25 lines, he could place the values 04 and 25 in the corresponding fields,
and, once again, subscripts written in accordance with the new table structure would
be correctly calculated by the system for locating individual data items.

*General Note:* If the description of a data item overflows from the "Description"
columns, it may be continued on the next line, following the rules given for the continuation
indication column (Column 72). The break at the end of a line must
occur between words, since the processor will assume a blank at the end of each
line. Multiple blanks, however, are treated as single blanks. If a constant is to be
carried over onto a new line, the portion on each line must be treated as a complete
constant (i.e., enclosed in quotation marks); the continuation indication is not used
in this case, and no blanks will be assumed between successive lines. (Note the example
used on page 74 to show how a table of rates might be placed in storage.)

<!-- page 84 | PDF 90 -->
**[page 84]**

### Cont. (Col. 72)

If the description to be entered in either the "Data Name" or "Description" columns
(Columns 7 through 22 or Columns 38 through 71) is too large for the space allowed,
it may be continued on a following line. So that the processor will recognize
this situation, the programmer must enter a character of some sort in Column 72.
Any non-blank character will suffice. The processor will then interpret the entry in
the succeeding card as a consecutive part of the previous entry.

A continued name must, of course, be placed in the "Data Name" columns, and
an overflowing description must be continued in the "Description" columns. The
rules for determining where the text should break between lines are given in the
discussions of the entries to be made in those columns.

### Identification (Col. 73-80)

Columns 73 through 80 are provided for the optional use of the programmer should
he wish to place a code on the cards to identify the program of which they are a part.
Any characters from the basic character set may be used, since the characters in
these columns have no effect on either the processor or the object program.

## Storage Areas

It has been pointed out that the internal storage of an electronic data processing
system may be used to contain data of various kinds, including the program which
governs the processing. As a result, those who work regularly with the technical
aspects of programming are accustomed to thinking of different kinds of storage.

For example, when an input record is brought into storage, space must be reserved
for the original record before any processing is carried out. This may be thought of
as an input area.

Then, after processing begins, it is often necessary to move data from the input
area into an area where it can be worked on. This is like moving a ledger card from
a file to a writing desk where an entry will be made or a value computed. "Working
storage" is therefore required in many cases. Actually, the registers of the system
provide space of this kind in many operations, and since in these cases it is provided
automatically, it is not thought of as working storage. However, in other cases, it
may be necessary to reserve a specific amount of space as working storage. For
example, a computation will sometimes produce intermediate results which will be
needed later in the program but which are never needed as such in the output record.
It may therefore be necessary to reserve an area in which to store such results
temporarily.

Normally, as each phase of a program is completed, the results will be moved to an
output area until the complete record has been assembled. The various output fields
may differ in format, size, and sequence from those of the input record, and data
may have been added or deleted. Thus, an area of storage must usually be set aside
for assembling the output record.

Other storage areas may be used for reference data, such as constants, literals, and
tables.

The experienced programmer often finds it convenient to distinguish among these
various kinds of storage. Actually, of course, all storage areas are controlled by the
same basic techniques—data is always addressed by its location, and data in any
area may be governed by any of the system's basic operating instructions. Since the
Commercial Translator system eliminates the need for the programmer to keep track
of specific storage areas, it also eliminates, for the most part, the need to distinguish
between types of storage areas. Storage areas are automatically reserved when the

<!-- page 85 | PDF 91 -->
**[page 85]**

data description is written, regardless of how the area is to be used. Certain special
provisions, especially those governing input and output, are built into the processor
for each system, and these are described in the manuals for the various processors.

The programmer, however, must be sure that all data-names required for input
and output, as specified in the manual for the system he is using, are properly described
in the data description. He should also examine his program to be sure that
every item of data used in the program, whether as input, output, or for intermediate
operations, is properly described. The processor will then make all necessary provisions
for storage space and for identifying the data to be stored.

<!-- conversion notes:
- Coding-form (punched-card) illustrations on PDF pages 80, 81, 82, 83, 87, 88, 89 are
  handwritten-style facsimiles of the Data Description form; OCR for these regions was
  almost entirely unusable. Each was transcribed by reading the page image directly and
  cross-checked against the surrounding narrative text (e.g., the RATE.TABLE constant
  values on PDF 80 were verified against the dollar amounts given in the printed rate
  table earlier on the same page). The page image is embedded above each best-effort
  fenced-code transcription per the spec's rule for complex ruled/handwritten tables.
- The Format Characters table (PDF 86, printed page 80) and its worked EXAMPLES
  (PDF 87, printed page 81) are typeset text, not handwritten forms, and were
  transcribed directly with high confidence; the page image for PDF 86 is still embedded
  given the note flagging this table as critical.
- No overpunched/overbar digit notation appears as an actual printed character anywhere
  in this chunk (PDF 80-91) — the "+"/"-" overpunch behavior is only described in prose
  on PDF 86 — so no combining-overline transcription was needed.
- Heading levels for this continuation were inferred from typographic cues (bold
  left-margin captions for card-column sections vs. italic/small-caps inline headings for
  type-code and worked-example subsections) since part 1 of this chapter was not
  available to this agent for direct comparison. If part 1 used a different level for the
  "Data Name (Col. 7-22)"-style column captions, these should be reconciled at assembly
  time: this part uses "##" for Quantity (Col. 31-35), Mode (Col. 36), Justify (Col. 37),
  Description (Col. 38-71), Cont. (Col. 72), Identification (Col. 73-80), and Storage Areas;
  "###" for COPY, LABEL, Constants, Data Names Associated with REDEF and COPY,
  Library Names, and Quantities Specified in Named Fields; "####" for TABLES and
  EXAMPLES.
- Minor OCR corrections made against the page images (not flagged individually above):
  "the letter 1" -> "the letter I" (page 78/PDF 84, Mode discussion); "it instructs" ->
  "It instructs" (page 78/PDF 84, Justify discussion); assorted garbled lines in the
  coding-form regions replaced by direct image transcription.
-->
