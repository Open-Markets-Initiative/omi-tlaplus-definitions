-------------- MODULE TseEquities_IssueBasicInformation_v19_5 --------------
(***************************************************************************)
(* Japan Exchange Group IssueBasicInformation v19.5                        *)
(*                                                                         *)
(* Generated from the binary model. A field is the bytes it occupies; an   *)
(* integer is read only where a rule depends on one - a length, a count, a *)
(* message type - which are the dependencies the parse rules run on.       *)
(*                                                                         *)
(* TLC checks that every record decodes back to what was encoded, that a   *)
(* dispatch selects the message its type names, and that a derived length  *)
(* or count is written from what it describes.                             *)
(*                                                                         *)
(* Note: TLC evaluates integers in 32 bits, so a field wider than that has *)
(* no range it can enumerate; every field is checked as its bytes, which   *)
(* is exact at any width.                                                  *)
(*                                                                         *)
(* License: MIT No Attribution                                             *)
(*                                                                         *)
(* Note: a Issue Classification Large Classification of any value but      *)
(* 12337 or 12338 reads Blank Issue Code.                                  *)
(*                                                                         *)
(* Note: Tag Information is of no one width: each is read by its own       *)
(* fields, and since every reading of it takes at least 13 bytes off the   *)
(* reader the run ends where the data does.                                *)
(***************************************************************************)
EXTENDS Integers, Sequences

(***************************************************************************)
(* Wire primitives                                                         *)
(***************************************************************************)

Byte == 0 .. 255

(* An unsigned integer, least significant byte first. Read only where a rule *)
(* depends on the value: a length, a count, a message type. *)
RECURSIVE DecodeUIntLE(_)
DecodeUIntLE(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE Head(bytes) + 256 * DecodeUIntLE(Tail(bytes))

RECURSIVE EncodeUIntLE(_, _)
EncodeUIntLE(value, width) ==
    IF width = 0
    THEN << >>
    ELSE <<value % 256>> \o EncodeUIntLE(value \div 256, width - 1)

(* The same, most significant byte first, which is how a big endian protocol writes it *)
RECURSIVE DecodeUIntBE(_)
DecodeUIntBE(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeUIntBE(SubSeq(bytes, 1, Len(bytes) - 1)) * 256 + bytes[Len(bytes)]

RECURSIVE EncodeUIntBE(_, _)
EncodeUIntBE(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeUIntBE(value \div 256, width - 1) \o <<value % 256>>

(***************************************************************************)
(* A decoder yields the value it read and the bytes left, or fails         *)
(***************************************************************************)

Fail == [ok |-> FALSE]
Ok(value, rest) == [ok |-> TRUE, value |-> value, rest |-> rest]

(* The bytes a field of this width occupies, kept as they lie *)
ReadBytes(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(SubSeq(bytes, 1, width), SubSeq(bytes, width + 1, Len(bytes)))

(* The integer a rule depends on, in the byte order the field states *)
ReadUIntLE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntLE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

ReadUIntBE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntBE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

(* The integer a text protocol writes as the characters of itself: a count of one is *)
(* the character "1", which is the byte 49. Read by its digits, and written back *)
(* zero filled to the width the field states, which is how such a field is filled. *)
Digit == 48 .. 57

RECURSIVE DecodeDigits(_)
DecodeDigits(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeDigits(SubSeq(bytes, 1, Len(bytes) - 1)) * 10 + (bytes[Len(bytes)] - 48)

RECURSIVE EncodeDigits(_, _)
EncodeDigits(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeDigits(value \div 10, width - 1) \o <<48 + (value % 10)>>

(* A field written as digits that holds anything else is no number, so it is not read: *)
(* the value would not be what the bytes say, and would not write back as them. *)
ReadDigits(bytes, width) ==
    IF Len(bytes) < width \/ \E i \in 1 .. width : bytes[i] \notin Digit
    THEN Fail
    ELSE Ok(DecodeDigits(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

(***************************************************************************)
(* The values a field is checked at: zero, the spaces a text field is      *)
(* padded with, and                                                        *)
(* every bit set, which is where an encoding goes wrong if it goes wrong   *)
(***************************************************************************)

Sample(width) ==
    { [i \in 1 .. width |-> 0],
      [i \in 1 .. width |-> 32],
      [i \in 1 .. width |-> 255] }

(* The bytes a field of no width of its own is checked at: none, one, and a short run *)
SampleBytes == { << >>, <<0>>, <<32, 255>> }

(* The lists a record is checked over: none, one, and a run of two. What a run has *)
(* to get right is reading one entry after another, which two of a kind already say. *)
SampleLists(entries) ==
    { << >> }
        \cup { <<one>> : one \in entries }
        \cup { <<one, one>> : one \in entries }

(***************************************************************************)
(* Message Serial No: 11 bytes                                             *)
(***************************************************************************)

MessageSerialNo ==
    [ multicastGroupNumber : Sample(3),
      sequenceNumber       : Sample(8) ]

EncodeMessageSerialNo(message) ==
    message.multicastGroupNumber
        \o message.sequenceNumber

DecodeMessageSerialNo(bytes) ==
    LET multicastGroupNumber == ReadBytes(bytes, 3) IN IF ~multicastGroupNumber.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(multicastGroupNumber.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ multicastGroupNumber |-> multicastGroupNumber.value,
         sequenceNumber       |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroMessageSerialNo ==
    [ multicastGroupNumber |-> [i \in 1 .. 3 |-> 0],
      sequenceNumber       |-> [i \in 1 .. 8 |-> 0] ]

(* Message Serial No at zero, then each field in turn at the values it is checked at *)
CheckedMessageSerialNo ==
    { ZeroMessageSerialNo }
        \cup { [ZeroMessageSerialNo EXCEPT !.multicastGroupNumber = one] : one \in Sample(3) }
        \cup { [ZeroMessageSerialNo EXCEPT !.sequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Message Type: 3 bytes                                                   *)
(***************************************************************************)

MessageType ==
    [ messageTypeLargeClassification  : 0 .. 255,
      messageTypeMediumClassification : Sample(2) ]

EncodeMessageType(message) ==
    EncodeUIntBE(message.messageTypeLargeClassification, 1)
        \o message.messageTypeMediumClassification

DecodeMessageType(bytes) ==
    LET messageTypeLargeClassification == ReadUIntBE(bytes, 1) IN IF ~messageTypeLargeClassification.ok THEN Fail ELSE
    LET messageTypeMediumClassification == ReadBytes(messageTypeLargeClassification.rest, 2) IN IF ~messageTypeMediumClassification.ok THEN Fail ELSE
    Ok([ messageTypeLargeClassification  |-> messageTypeLargeClassification.value,
         messageTypeMediumClassification |-> messageTypeMediumClassification.value ], messageTypeMediumClassification.rest)

ZeroMessageType ==
    [ messageTypeLargeClassification  |-> 0,
      messageTypeMediumClassification |-> [i \in 1 .. 2 |-> 0] ]

(* Message Type at zero, then each field in turn at the values it is checked at *)
CheckedMessageType ==
    { ZeroMessageType }
        \cup { [ZeroMessageType EXCEPT !.messageTypeLargeClassification = one] : one \in {0, 1, 255} }
        \cup { [ZeroMessageType EXCEPT !.messageTypeMediumClassification = one] : one \in Sample(2) }

(***************************************************************************)
(* Stock Issue Code: 12 bytes                                              *)
(***************************************************************************)

StockIssueCode ==
    [ stockSpace          : Sample(7),
      stockProperNameCode : Sample(4),
      stockReservedCode   : Sample(1) ]

EncodeStockIssueCode(message) ==
    message.stockSpace
        \o message.stockProperNameCode
        \o message.stockReservedCode

DecodeStockIssueCode(bytes) ==
    LET stockSpace == ReadBytes(bytes, 7) IN IF ~stockSpace.ok THEN Fail ELSE
    LET stockProperNameCode == ReadBytes(stockSpace.rest, 4) IN IF ~stockProperNameCode.ok THEN Fail ELSE
    LET stockReservedCode == ReadBytes(stockProperNameCode.rest, 1) IN IF ~stockReservedCode.ok THEN Fail ELSE
    Ok([ stockSpace          |-> stockSpace.value,
         stockProperNameCode |-> stockProperNameCode.value,
         stockReservedCode   |-> stockReservedCode.value ], stockReservedCode.rest)

ZeroStockIssueCode ==
    [ stockSpace          |-> [i \in 1 .. 7 |-> 0],
      stockProperNameCode |-> [i \in 1 .. 4 |-> 0],
      stockReservedCode   |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Issue Code at zero, then each field in turn at the values it is checked at *)
CheckedStockIssueCode ==
    { ZeroStockIssueCode }
        \cup { [ZeroStockIssueCode EXCEPT !.stockSpace = one] : one \in Sample(7) }
        \cup { [ZeroStockIssueCode EXCEPT !.stockProperNameCode = one] : one \in Sample(4) }
        \cup { [ZeroStockIssueCode EXCEPT !.stockReservedCode = one] : one \in Sample(1) }

(***************************************************************************)
(* CB Issue Code: 12 bytes                                                 *)
(***************************************************************************)

CbIssueCode ==
    [ cbSpace          : Sample(3),
      cbReservedCode   : Sample(1),
      timeSymbol       : Sample(4),
      cbProperNameCode : Sample(4) ]

EncodeCbIssueCode(message) ==
    message.cbSpace
        \o message.cbReservedCode
        \o message.timeSymbol
        \o message.cbProperNameCode

DecodeCbIssueCode(bytes) ==
    LET cbSpace == ReadBytes(bytes, 3) IN IF ~cbSpace.ok THEN Fail ELSE
    LET cbReservedCode == ReadBytes(cbSpace.rest, 1) IN IF ~cbReservedCode.ok THEN Fail ELSE
    LET timeSymbol == ReadBytes(cbReservedCode.rest, 4) IN IF ~timeSymbol.ok THEN Fail ELSE
    LET cbProperNameCode == ReadBytes(timeSymbol.rest, 4) IN IF ~cbProperNameCode.ok THEN Fail ELSE
    Ok([ cbSpace          |-> cbSpace.value,
         cbReservedCode   |-> cbReservedCode.value,
         timeSymbol       |-> timeSymbol.value,
         cbProperNameCode |-> cbProperNameCode.value ], cbProperNameCode.rest)

ZeroCbIssueCode ==
    [ cbSpace          |-> [i \in 1 .. 3 |-> 0],
      cbReservedCode   |-> [i \in 1 .. 1 |-> 0],
      timeSymbol       |-> [i \in 1 .. 4 |-> 0],
      cbProperNameCode |-> [i \in 1 .. 4 |-> 0] ]

(* CB Issue Code at zero, then each field in turn at the values it is checked at *)
CheckedCbIssueCode ==
    { ZeroCbIssueCode }
        \cup { [ZeroCbIssueCode EXCEPT !.cbSpace = one] : one \in Sample(3) }
        \cup { [ZeroCbIssueCode EXCEPT !.cbReservedCode = one] : one \in Sample(1) }
        \cup { [ZeroCbIssueCode EXCEPT !.timeSymbol = one] : one \in Sample(4) }
        \cup { [ZeroCbIssueCode EXCEPT !.cbProperNameCode = one] : one \in Sample(4) }

(***************************************************************************)
(* Blank Issue Code: 12 bytes                                              *)
(***************************************************************************)

BlankIssueCode ==
    [ blankIssueCode : Sample(12) ]

EncodeBlankIssueCode(message) ==
    message.blankIssueCode

DecodeBlankIssueCode(bytes) ==
    LET blankIssueCode == ReadBytes(bytes, 12) IN IF ~blankIssueCode.ok THEN Fail ELSE
    Ok([ blankIssueCode |-> blankIssueCode.value ], blankIssueCode.rest)

ZeroBlankIssueCode ==
    [ blankIssueCode |-> [i \in 1 .. 12 |-> 0] ]

(* Blank Issue Code at zero, then each field in turn at the values it is checked at *)
CheckedBlankIssueCode ==
    { ZeroBlankIssueCode }
        \cup { [ZeroBlankIssueCode EXCEPT !.blankIssueCode = one] : one \in Sample(12) }

(***************************************************************************)
(* Issue Code, selected by Issue Classification Large Classification       *)
(***************************************************************************)

StockIssueCodeCode == 12337  \* "01"
CbIssueCodeCode == 12338  \* "02"
BlankIssueCodeCode == 0  \* stands for every value no other case names

IssueCode ==
    [ tag : {StockIssueCodeCode}, body : StockIssueCode ]
        \cup [ tag : {CbIssueCodeCode}, body : CbIssueCode ]
        \cup [ tag : (0 .. 255) \ {StockIssueCodeCode, CbIssueCodeCode}, body : BlankIssueCode ]

EncodeIssueCode(message) ==
    CASE message.tag = StockIssueCodeCode -> EncodeStockIssueCode(message.body)
      [] message.tag = CbIssueCodeCode -> EncodeCbIssueCode(message.body)
      [] OTHER -> EncodeBlankIssueCode(message.body)

DecodeIssueCode(tag, bytes) ==
    LET read ==
            CASE tag = StockIssueCodeCode -> DecodeStockIssueCode(bytes)
              [] tag = CbIssueCodeCode -> DecodeCbIssueCode(bytes)
              [] OTHER -> DecodeBlankIssueCode(bytes)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroIssueCode == [tag |-> StockIssueCodeCode, body |-> ZeroStockIssueCode]

(* Each Issue Code in turn, at the values the message it names is checked at *)
CheckedIssueCode ==
    { [tag |-> StockIssueCodeCode, body |-> one] : one \in CheckedStockIssueCode }
        \cup { [tag |-> CbIssueCodeCode, body |-> one] : one \in CheckedCbIssueCode }
        \cup [ tag : {0, 1, 255} \ {StockIssueCodeCode, CbIssueCodeCode}, body : CheckedBlankIssueCode ]

(***************************************************************************)
(* Service Header                                                          *)
(***************************************************************************)

ServiceHeader ==
    [ messageLength                           : Sample(6),
      messageSerialNo                         : MessageSerialNo,
      messageType                             : MessageType,
      exchangeCode                            : Sample(1),
      sessionDistinction                      : Sample(2),
      issueClassificationMediumClassification : Sample(2),
      issueCode                               : IssueCode ]

EncodeServiceHeader(message) ==
    message.messageLength
        \o EncodeMessageSerialNo(message.messageSerialNo)
        \o EncodeMessageType(message.messageType)
        \o message.exchangeCode
        \o message.sessionDistinction
        \o EncodeUIntBE(message.issueCode.tag, 2)
        \o message.issueClassificationMediumClassification
        \o EncodeIssueCode(message.issueCode)

DecodeServiceHeader(bytes) ==
    LET messageLength == ReadBytes(bytes, 6) IN IF ~messageLength.ok THEN Fail ELSE
    LET messageSerialNo == DecodeMessageSerialNo(messageLength.rest) IN IF ~messageSerialNo.ok THEN Fail ELSE
    LET messageType == DecodeMessageType(messageSerialNo.rest) IN IF ~messageType.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(messageType.rest, 1) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET sessionDistinction == ReadBytes(exchangeCode.rest, 2) IN IF ~sessionDistinction.ok THEN Fail ELSE
    LET issueClassificationLargeClassification == ReadUIntBE(sessionDistinction.rest, 2) IN IF ~issueClassificationLargeClassification.ok THEN Fail ELSE
    LET issueClassificationMediumClassification == ReadBytes(issueClassificationLargeClassification.rest, 2) IN IF ~issueClassificationMediumClassification.ok THEN Fail ELSE
    LET issueCode == DecodeIssueCode(issueClassificationLargeClassification.value, issueClassificationMediumClassification.rest) IN IF ~issueCode.ok THEN Fail ELSE
    Ok([ messageLength                           |-> messageLength.value,
         messageSerialNo                         |-> messageSerialNo.value,
         messageType                             |-> messageType.value,
         exchangeCode                            |-> exchangeCode.value,
         sessionDistinction                      |-> sessionDistinction.value,
         issueClassificationMediumClassification |-> issueClassificationMediumClassification.value,
         issueCode                               |-> issueCode.value ], issueCode.rest)

ZeroServiceHeader ==
    [ messageLength                           |-> [i \in 1 .. 6 |-> 0],
      messageSerialNo                         |-> ZeroMessageSerialNo,
      messageType                             |-> ZeroMessageType,
      exchangeCode                            |-> [i \in 1 .. 1 |-> 0],
      sessionDistinction                      |-> [i \in 1 .. 2 |-> 0],
      issueClassificationMediumClassification |-> [i \in 1 .. 2 |-> 0],
      issueCode                               |-> ZeroIssueCode ]

(* Service Header at zero, then each field in turn at the values it is checked at *)
CheckedServiceHeader ==
    { ZeroServiceHeader }
        \cup { [ZeroServiceHeader EXCEPT !.messageLength = one] : one \in Sample(6) }
        \cup { [ZeroServiceHeader EXCEPT !.messageSerialNo = one] : one \in CheckedMessageSerialNo }
        \cup { [ZeroServiceHeader EXCEPT !.messageType = one] : one \in CheckedMessageType }
        \cup { [ZeroServiceHeader EXCEPT !.exchangeCode = one] : one \in Sample(1) }
        \cup { [ZeroServiceHeader EXCEPT !.sessionDistinction = one] : one \in Sample(2) }
        \cup { [ZeroServiceHeader EXCEPT !.issueClassificationMediumClassification = one] : one \in Sample(2) }
        \cup { [ZeroServiceHeader EXCEPT !.issueCode = one] : one \in CheckedIssueCode }

(***************************************************************************)
(* Index Constituent Issue: 20 bytes                                       *)
(***************************************************************************)

IndexConstituentIssue ==
    [ arbitrary1      : Sample(1),
      arbitrary2      : Sample(1),
      arbitrary3      : Sample(1),
      arbitrary4      : Sample(1),
      arbitrary5      : Sample(1),
      arbitrary6      : Sample(1),
      arbitrary7      : Sample(1),
      arbitrary8To10  : Sample(3),
      arbitrary11     : Sample(1),
      arbitrary12To15 : Sample(4),
      arbitrary16     : Sample(1),
      arbitrary17To19 : Sample(3),
      arbitrary20     : Sample(1) ]

EncodeIndexConstituentIssue(message) ==
    message.arbitrary1
        \o message.arbitrary2
        \o message.arbitrary3
        \o message.arbitrary4
        \o message.arbitrary5
        \o message.arbitrary6
        \o message.arbitrary7
        \o message.arbitrary8To10
        \o message.arbitrary11
        \o message.arbitrary12To15
        \o message.arbitrary16
        \o message.arbitrary17To19
        \o message.arbitrary20

DecodeIndexConstituentIssue(bytes) ==
    LET arbitrary1 == ReadBytes(bytes, 1) IN IF ~arbitrary1.ok THEN Fail ELSE
    LET arbitrary2 == ReadBytes(arbitrary1.rest, 1) IN IF ~arbitrary2.ok THEN Fail ELSE
    LET arbitrary3 == ReadBytes(arbitrary2.rest, 1) IN IF ~arbitrary3.ok THEN Fail ELSE
    LET arbitrary4 == ReadBytes(arbitrary3.rest, 1) IN IF ~arbitrary4.ok THEN Fail ELSE
    LET arbitrary5 == ReadBytes(arbitrary4.rest, 1) IN IF ~arbitrary5.ok THEN Fail ELSE
    LET arbitrary6 == ReadBytes(arbitrary5.rest, 1) IN IF ~arbitrary6.ok THEN Fail ELSE
    LET arbitrary7 == ReadBytes(arbitrary6.rest, 1) IN IF ~arbitrary7.ok THEN Fail ELSE
    LET arbitrary8To10 == ReadBytes(arbitrary7.rest, 3) IN IF ~arbitrary8To10.ok THEN Fail ELSE
    LET arbitrary11 == ReadBytes(arbitrary8To10.rest, 1) IN IF ~arbitrary11.ok THEN Fail ELSE
    LET arbitrary12To15 == ReadBytes(arbitrary11.rest, 4) IN IF ~arbitrary12To15.ok THEN Fail ELSE
    LET arbitrary16 == ReadBytes(arbitrary12To15.rest, 1) IN IF ~arbitrary16.ok THEN Fail ELSE
    LET arbitrary17To19 == ReadBytes(arbitrary16.rest, 3) IN IF ~arbitrary17To19.ok THEN Fail ELSE
    LET arbitrary20 == ReadBytes(arbitrary17To19.rest, 1) IN IF ~arbitrary20.ok THEN Fail ELSE
    Ok([ arbitrary1      |-> arbitrary1.value,
         arbitrary2      |-> arbitrary2.value,
         arbitrary3      |-> arbitrary3.value,
         arbitrary4      |-> arbitrary4.value,
         arbitrary5      |-> arbitrary5.value,
         arbitrary6      |-> arbitrary6.value,
         arbitrary7      |-> arbitrary7.value,
         arbitrary8To10  |-> arbitrary8To10.value,
         arbitrary11     |-> arbitrary11.value,
         arbitrary12To15 |-> arbitrary12To15.value,
         arbitrary16     |-> arbitrary16.value,
         arbitrary17To19 |-> arbitrary17To19.value,
         arbitrary20     |-> arbitrary20.value ], arbitrary20.rest)

ZeroIndexConstituentIssue ==
    [ arbitrary1      |-> [i \in 1 .. 1 |-> 0],
      arbitrary2      |-> [i \in 1 .. 1 |-> 0],
      arbitrary3      |-> [i \in 1 .. 1 |-> 0],
      arbitrary4      |-> [i \in 1 .. 1 |-> 0],
      arbitrary5      |-> [i \in 1 .. 1 |-> 0],
      arbitrary6      |-> [i \in 1 .. 1 |-> 0],
      arbitrary7      |-> [i \in 1 .. 1 |-> 0],
      arbitrary8To10  |-> [i \in 1 .. 3 |-> 0],
      arbitrary11     |-> [i \in 1 .. 1 |-> 0],
      arbitrary12To15 |-> [i \in 1 .. 4 |-> 0],
      arbitrary16     |-> [i \in 1 .. 1 |-> 0],
      arbitrary17To19 |-> [i \in 1 .. 3 |-> 0],
      arbitrary20     |-> [i \in 1 .. 1 |-> 0] ]

(* Index Constituent Issue at zero, then each field in turn at the values it is checked at *)
CheckedIndexConstituentIssue ==
    { ZeroIndexConstituentIssue }
        \cup { [ZeroIndexConstituentIssue EXCEPT !.arbitrary1 = one] : one \in Sample(1) }
        \cup { [ZeroIndexConstituentIssue EXCEPT !.arbitrary2 = one] : one \in Sample(1) }
        \cup { [ZeroIndexConstituentIssue EXCEPT !.arbitrary3 = one] : one \in Sample(1) }
        \cup { [ZeroIndexConstituentIssue EXCEPT !.arbitrary4 = one] : one \in Sample(1) }
        \cup { [ZeroIndexConstituentIssue EXCEPT !.arbitrary5 = one] : one \in Sample(1) }
        \cup { [ZeroIndexConstituentIssue EXCEPT !.arbitrary6 = one] : one \in Sample(1) }
        \cup { [ZeroIndexConstituentIssue EXCEPT !.arbitrary7 = one] : one \in Sample(1) }
        \cup { [ZeroIndexConstituentIssue EXCEPT !.arbitrary8To10 = one] : one \in Sample(3) }
        \cup { [ZeroIndexConstituentIssue EXCEPT !.arbitrary11 = one] : one \in Sample(1) }
        \cup { [ZeroIndexConstituentIssue EXCEPT !.arbitrary12To15 = one] : one \in Sample(4) }
        \cup { [ZeroIndexConstituentIssue EXCEPT !.arbitrary16 = one] : one \in Sample(1) }
        \cup { [ZeroIndexConstituentIssue EXCEPT !.arbitrary17To19 = one] : one \in Sample(3) }
        \cup { [ZeroIndexConstituentIssue EXCEPT !.arbitrary20 = one] : one \in Sample(1) }

(***************************************************************************)
(* New Orders Prohibition: 4 bytes                                         *)
(***************************************************************************)

NewOrdersProhibition ==
    [ marketLimitOrders    : Sample(1),
      side                 : Sample(1),
      proprietaryBrokerage : Sample(1),
      reserved1            : Sample(1) ]

EncodeNewOrdersProhibition(message) ==
    message.marketLimitOrders
        \o message.side
        \o message.proprietaryBrokerage
        \o message.reserved1

DecodeNewOrdersProhibition(bytes) ==
    LET marketLimitOrders == ReadBytes(bytes, 1) IN IF ~marketLimitOrders.ok THEN Fail ELSE
    LET side == ReadBytes(marketLimitOrders.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET proprietaryBrokerage == ReadBytes(side.rest, 1) IN IF ~proprietaryBrokerage.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(proprietaryBrokerage.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ marketLimitOrders    |-> marketLimitOrders.value,
         side                 |-> side.value,
         proprietaryBrokerage |-> proprietaryBrokerage.value,
         reserved1            |-> reserved1.value ], reserved1.rest)

ZeroNewOrdersProhibition ==
    [ marketLimitOrders    |-> [i \in 1 .. 1 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      proprietaryBrokerage |-> [i \in 1 .. 1 |-> 0],
      reserved1            |-> [i \in 1 .. 1 |-> 0] ]

(* New Orders Prohibition at zero, then each field in turn at the values it is checked at *)
CheckedNewOrdersProhibition ==
    { ZeroNewOrdersProhibition }
        \cup { [ZeroNewOrdersProhibition EXCEPT !.marketLimitOrders = one] : one \in Sample(1) }
        \cup { [ZeroNewOrdersProhibition EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrdersProhibition EXCEPT !.proprietaryBrokerage = one] : one \in Sample(1) }
        \cup { [ZeroNewOrdersProhibition EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Margin Transactions Prohibition: 3 bytes                                *)
(***************************************************************************)

MarginTransactionsProhibition ==
    [ side                 : Sample(1),
      proprietaryBrokerage : Sample(1),
      reserved1            : Sample(1) ]

EncodeMarginTransactionsProhibition(message) ==
    message.side
        \o message.proprietaryBrokerage
        \o message.reserved1

DecodeMarginTransactionsProhibition(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET proprietaryBrokerage == ReadBytes(side.rest, 1) IN IF ~proprietaryBrokerage.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(proprietaryBrokerage.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ side                 |-> side.value,
         proprietaryBrokerage |-> proprietaryBrokerage.value,
         reserved1            |-> reserved1.value ], reserved1.rest)

ZeroMarginTransactionsProhibition ==
    [ side                 |-> [i \in 1 .. 1 |-> 0],
      proprietaryBrokerage |-> [i \in 1 .. 1 |-> 0],
      reserved1            |-> [i \in 1 .. 1 |-> 0] ]

(* Margin Transactions Prohibition at zero, then each field in turn at the values it is checked at *)
CheckedMarginTransactionsProhibition ==
    { ZeroMarginTransactionsProhibition }
        \cup { [ZeroMarginTransactionsProhibition EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMarginTransactionsProhibition EXCEPT !.proprietaryBrokerage = one] : one \in Sample(1) }
        \cup { [ZeroMarginTransactionsProhibition EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Short Selling Prohibition: 2 bytes                                      *)
(***************************************************************************)

ShortSellingProhibition ==
    [ proprietaryBrokerage : Sample(1),
      reserved1            : Sample(1) ]

EncodeShortSellingProhibition(message) ==
    message.proprietaryBrokerage
        \o message.reserved1

DecodeShortSellingProhibition(bytes) ==
    LET proprietaryBrokerage == ReadBytes(bytes, 1) IN IF ~proprietaryBrokerage.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(proprietaryBrokerage.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ proprietaryBrokerage |-> proprietaryBrokerage.value,
         reserved1            |-> reserved1.value ], reserved1.rest)

ZeroShortSellingProhibition ==
    [ proprietaryBrokerage |-> [i \in 1 .. 1 |-> 0],
      reserved1            |-> [i \in 1 .. 1 |-> 0] ]

(* Short Selling Prohibition at zero, then each field in turn at the values it is checked at *)
CheckedShortSellingProhibition ==
    { ZeroShortSellingProhibition }
        \cup { [ZeroShortSellingProhibition EXCEPT !.proprietaryBrokerage = one] : one \in Sample(1) }
        \cup { [ZeroShortSellingProhibition EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Prohibition Status At The Regular Distribution: 10 bytes          *)
(***************************************************************************)

OrderProhibitionStatusAtTheRegularDistribution ==
    [ newOrdersProhibition          : NewOrdersProhibition,
      marginTransactionsProhibition : MarginTransactionsProhibition,
      shortSellingProhibition       : ShortSellingProhibition,
      allOrdersProhibition          : Sample(1) ]

EncodeOrderProhibitionStatusAtTheRegularDistribution(message) ==
    EncodeNewOrdersProhibition(message.newOrdersProhibition)
        \o EncodeMarginTransactionsProhibition(message.marginTransactionsProhibition)
        \o EncodeShortSellingProhibition(message.shortSellingProhibition)
        \o message.allOrdersProhibition

DecodeOrderProhibitionStatusAtTheRegularDistribution(bytes) ==
    LET newOrdersProhibition == DecodeNewOrdersProhibition(bytes) IN IF ~newOrdersProhibition.ok THEN Fail ELSE
    LET marginTransactionsProhibition == DecodeMarginTransactionsProhibition(newOrdersProhibition.rest) IN IF ~marginTransactionsProhibition.ok THEN Fail ELSE
    LET shortSellingProhibition == DecodeShortSellingProhibition(marginTransactionsProhibition.rest) IN IF ~shortSellingProhibition.ok THEN Fail ELSE
    LET allOrdersProhibition == ReadBytes(shortSellingProhibition.rest, 1) IN IF ~allOrdersProhibition.ok THEN Fail ELSE
    Ok([ newOrdersProhibition          |-> newOrdersProhibition.value,
         marginTransactionsProhibition |-> marginTransactionsProhibition.value,
         shortSellingProhibition       |-> shortSellingProhibition.value,
         allOrdersProhibition          |-> allOrdersProhibition.value ], allOrdersProhibition.rest)

ZeroOrderProhibitionStatusAtTheRegularDistribution ==
    [ newOrdersProhibition          |-> ZeroNewOrdersProhibition,
      marginTransactionsProhibition |-> ZeroMarginTransactionsProhibition,
      shortSellingProhibition       |-> ZeroShortSellingProhibition,
      allOrdersProhibition          |-> [i \in 1 .. 1 |-> 0] ]

(* Order Prohibition Status At The Regular Distribution at zero, then each field in turn at the values it is checked at *)
CheckedOrderProhibitionStatusAtTheRegularDistribution ==
    { ZeroOrderProhibitionStatusAtTheRegularDistribution }
        \cup { [ZeroOrderProhibitionStatusAtTheRegularDistribution EXCEPT !.newOrdersProhibition = one] : one \in CheckedNewOrdersProhibition }
        \cup { [ZeroOrderProhibitionStatusAtTheRegularDistribution EXCEPT !.marginTransactionsProhibition = one] : one \in CheckedMarginTransactionsProhibition }
        \cup { [ZeroOrderProhibitionStatusAtTheRegularDistribution EXCEPT !.shortSellingProhibition = one] : one \in CheckedShortSellingProhibition }
        \cup { [ZeroOrderProhibitionStatusAtTheRegularDistribution EXCEPT !.allOrdersProhibition = one] : one \in Sample(1) }

(***************************************************************************)
(* Issue Information Message: 123 bytes                                    *)
(***************************************************************************)

IssueInformationMessage ==
    [ reserved2                                                       : Sample(2),
      serialNo                                                        : Sample(6),
      applicableBusinessDay                                           : Sample(8),
      reserved1                                                       : Sample(1),
      issueName                                                       : Sample(20),
      securityTypeEtcIdentificationCode                               : Sample(2),
      isinFlag                                                        : Sample(1),
      newSecurityCode                                                 : Sample(12),
      industryCode                                                    : Sample(4),
      newListingFlag                                                  : Sample(1),
      whenIssuedTransactionFlag                                       : Sample(1),
      shortSellingPriceRestrictionAppliedFlagAtTheRegularDistribution : Sample(1),
      loanMarginFlag                                                  : Sample(1),
      exDividendExRightFlag                                           : Sample(2),
      securitiesToBeDelistedUnderSupervisionClassification            : Sample(1),
      reserved5                                                       : Sample(5),
      unitOfTrading                                                   : Sample(14),
      indexConstituentIssue                                           : IndexConstituentIssue,
      orderProhibitionStatusAtTheRegularDistribution                  : OrderProhibitionStatusAtTheRegularDistribution,
      reserved11                                                      : Sample(11) ]

EncodeIssueInformationMessage(message) ==
    message.reserved2
        \o message.serialNo
        \o message.applicableBusinessDay
        \o message.reserved1
        \o message.issueName
        \o message.securityTypeEtcIdentificationCode
        \o message.isinFlag
        \o message.newSecurityCode
        \o message.industryCode
        \o message.newListingFlag
        \o message.whenIssuedTransactionFlag
        \o message.shortSellingPriceRestrictionAppliedFlagAtTheRegularDistribution
        \o message.loanMarginFlag
        \o message.exDividendExRightFlag
        \o message.securitiesToBeDelistedUnderSupervisionClassification
        \o message.reserved5
        \o message.unitOfTrading
        \o EncodeIndexConstituentIssue(message.indexConstituentIssue)
        \o EncodeOrderProhibitionStatusAtTheRegularDistribution(message.orderProhibitionStatusAtTheRegularDistribution)
        \o message.reserved11

DecodeIssueInformationMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET serialNo == ReadBytes(reserved2.rest, 6) IN IF ~serialNo.ok THEN Fail ELSE
    LET applicableBusinessDay == ReadBytes(serialNo.rest, 8) IN IF ~applicableBusinessDay.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(applicableBusinessDay.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET issueName == ReadBytes(reserved1.rest, 20) IN IF ~issueName.ok THEN Fail ELSE
    LET securityTypeEtcIdentificationCode == ReadBytes(issueName.rest, 2) IN IF ~securityTypeEtcIdentificationCode.ok THEN Fail ELSE
    LET isinFlag == ReadBytes(securityTypeEtcIdentificationCode.rest, 1) IN IF ~isinFlag.ok THEN Fail ELSE
    LET newSecurityCode == ReadBytes(isinFlag.rest, 12) IN IF ~newSecurityCode.ok THEN Fail ELSE
    LET industryCode == ReadBytes(newSecurityCode.rest, 4) IN IF ~industryCode.ok THEN Fail ELSE
    LET newListingFlag == ReadBytes(industryCode.rest, 1) IN IF ~newListingFlag.ok THEN Fail ELSE
    LET whenIssuedTransactionFlag == ReadBytes(newListingFlag.rest, 1) IN IF ~whenIssuedTransactionFlag.ok THEN Fail ELSE
    LET shortSellingPriceRestrictionAppliedFlagAtTheRegularDistribution == ReadBytes(whenIssuedTransactionFlag.rest, 1) IN IF ~shortSellingPriceRestrictionAppliedFlagAtTheRegularDistribution.ok THEN Fail ELSE
    LET loanMarginFlag == ReadBytes(shortSellingPriceRestrictionAppliedFlagAtTheRegularDistribution.rest, 1) IN IF ~loanMarginFlag.ok THEN Fail ELSE
    LET exDividendExRightFlag == ReadBytes(loanMarginFlag.rest, 2) IN IF ~exDividendExRightFlag.ok THEN Fail ELSE
    LET securitiesToBeDelistedUnderSupervisionClassification == ReadBytes(exDividendExRightFlag.rest, 1) IN IF ~securitiesToBeDelistedUnderSupervisionClassification.ok THEN Fail ELSE
    LET reserved5 == ReadBytes(securitiesToBeDelistedUnderSupervisionClassification.rest, 5) IN IF ~reserved5.ok THEN Fail ELSE
    LET unitOfTrading == ReadBytes(reserved5.rest, 14) IN IF ~unitOfTrading.ok THEN Fail ELSE
    LET indexConstituentIssue == DecodeIndexConstituentIssue(unitOfTrading.rest) IN IF ~indexConstituentIssue.ok THEN Fail ELSE
    LET orderProhibitionStatusAtTheRegularDistribution == DecodeOrderProhibitionStatusAtTheRegularDistribution(indexConstituentIssue.rest) IN IF ~orderProhibitionStatusAtTheRegularDistribution.ok THEN Fail ELSE
    LET reserved11 == ReadBytes(orderProhibitionStatusAtTheRegularDistribution.rest, 11) IN IF ~reserved11.ok THEN Fail ELSE
    Ok([ reserved2                                                       |-> reserved2.value,
         serialNo                                                        |-> serialNo.value,
         applicableBusinessDay                                           |-> applicableBusinessDay.value,
         reserved1                                                       |-> reserved1.value,
         issueName                                                       |-> issueName.value,
         securityTypeEtcIdentificationCode                               |-> securityTypeEtcIdentificationCode.value,
         isinFlag                                                        |-> isinFlag.value,
         newSecurityCode                                                 |-> newSecurityCode.value,
         industryCode                                                    |-> industryCode.value,
         newListingFlag                                                  |-> newListingFlag.value,
         whenIssuedTransactionFlag                                       |-> whenIssuedTransactionFlag.value,
         shortSellingPriceRestrictionAppliedFlagAtTheRegularDistribution |-> shortSellingPriceRestrictionAppliedFlagAtTheRegularDistribution.value,
         loanMarginFlag                                                  |-> loanMarginFlag.value,
         exDividendExRightFlag                                           |-> exDividendExRightFlag.value,
         securitiesToBeDelistedUnderSupervisionClassification            |-> securitiesToBeDelistedUnderSupervisionClassification.value,
         reserved5                                                       |-> reserved5.value,
         unitOfTrading                                                   |-> unitOfTrading.value,
         indexConstituentIssue                                           |-> indexConstituentIssue.value,
         orderProhibitionStatusAtTheRegularDistribution                  |-> orderProhibitionStatusAtTheRegularDistribution.value,
         reserved11                                                      |-> reserved11.value ], reserved11.rest)

ZeroIssueInformationMessage ==
    [ reserved2                                                       |-> [i \in 1 .. 2 |-> 0],
      serialNo                                                        |-> [i \in 1 .. 6 |-> 0],
      applicableBusinessDay                                           |-> [i \in 1 .. 8 |-> 0],
      reserved1                                                       |-> [i \in 1 .. 1 |-> 0],
      issueName                                                       |-> [i \in 1 .. 20 |-> 0],
      securityTypeEtcIdentificationCode                               |-> [i \in 1 .. 2 |-> 0],
      isinFlag                                                        |-> [i \in 1 .. 1 |-> 0],
      newSecurityCode                                                 |-> [i \in 1 .. 12 |-> 0],
      industryCode                                                    |-> [i \in 1 .. 4 |-> 0],
      newListingFlag                                                  |-> [i \in 1 .. 1 |-> 0],
      whenIssuedTransactionFlag                                       |-> [i \in 1 .. 1 |-> 0],
      shortSellingPriceRestrictionAppliedFlagAtTheRegularDistribution |-> [i \in 1 .. 1 |-> 0],
      loanMarginFlag                                                  |-> [i \in 1 .. 1 |-> 0],
      exDividendExRightFlag                                           |-> [i \in 1 .. 2 |-> 0],
      securitiesToBeDelistedUnderSupervisionClassification            |-> [i \in 1 .. 1 |-> 0],
      reserved5                                                       |-> [i \in 1 .. 5 |-> 0],
      unitOfTrading                                                   |-> [i \in 1 .. 14 |-> 0],
      indexConstituentIssue                                           |-> ZeroIndexConstituentIssue,
      orderProhibitionStatusAtTheRegularDistribution                  |-> ZeroOrderProhibitionStatusAtTheRegularDistribution,
      reserved11                                                      |-> [i \in 1 .. 11 |-> 0] ]

(* Issue Information Message at zero, then each field in turn at the values it is checked at *)
CheckedIssueInformationMessage ==
    { ZeroIssueInformationMessage }
        \cup { [ZeroIssueInformationMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.serialNo = one] : one \in Sample(6) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.applicableBusinessDay = one] : one \in Sample(8) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.issueName = one] : one \in Sample(20) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.securityTypeEtcIdentificationCode = one] : one \in Sample(2) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.isinFlag = one] : one \in Sample(1) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.newSecurityCode = one] : one \in Sample(12) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.industryCode = one] : one \in Sample(4) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.newListingFlag = one] : one \in Sample(1) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.whenIssuedTransactionFlag = one] : one \in Sample(1) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.shortSellingPriceRestrictionAppliedFlagAtTheRegularDistribution = one] : one \in Sample(1) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.loanMarginFlag = one] : one \in Sample(1) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.exDividendExRightFlag = one] : one \in Sample(2) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.securitiesToBeDelistedUnderSupervisionClassification = one] : one \in Sample(1) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.reserved5 = one] : one \in Sample(5) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.unitOfTrading = one] : one \in Sample(14) }
        \cup { [ZeroIssueInformationMessage EXCEPT !.indexConstituentIssue = one] : one \in CheckedIndexConstituentIssue }
        \cup { [ZeroIssueInformationMessage EXCEPT !.orderProhibitionStatusAtTheRegularDistribution = one] : one \in CheckedOrderProhibitionStatusAtTheRegularDistribution }
        \cup { [ZeroIssueInformationMessage EXCEPT !.reserved11 = one] : one \in Sample(11) }

(***************************************************************************)
(* Base Price: 16 bytes                                                    *)
(***************************************************************************)

BasePrice ==
    [ unitFlag : Sample(1),
      price    : Sample(14),
      sign     : Sample(1) ]

EncodeBasePrice(message) ==
    message.unitFlag
        \o message.price
        \o message.sign

DecodeBasePrice(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET price == ReadBytes(unitFlag.rest, 14) IN IF ~price.ok THEN Fail ELSE
    LET sign == ReadBytes(price.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         price    |-> price.value,
         sign     |-> sign.value ], sign.rest)

ZeroBasePrice ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      price    |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Base Price at zero, then each field in turn at the values it is checked at *)
CheckedBasePrice ==
    { ZeroBasePrice }
        \cup { [ZeroBasePrice EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroBasePrice EXCEPT !.price = one] : one \in Sample(14) }
        \cup { [ZeroBasePrice EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Limit Price Maximum: 16 bytes                                           *)
(***************************************************************************)

LimitPriceMaximum ==
    [ unitFlag : Sample(1),
      price    : Sample(14),
      sign     : Sample(1) ]

EncodeLimitPriceMaximum(message) ==
    message.unitFlag
        \o message.price
        \o message.sign

DecodeLimitPriceMaximum(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET price == ReadBytes(unitFlag.rest, 14) IN IF ~price.ok THEN Fail ELSE
    LET sign == ReadBytes(price.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         price    |-> price.value,
         sign     |-> sign.value ], sign.rest)

ZeroLimitPriceMaximum ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      price    |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Limit Price Maximum at zero, then each field in turn at the values it is checked at *)
CheckedLimitPriceMaximum ==
    { ZeroLimitPriceMaximum }
        \cup { [ZeroLimitPriceMaximum EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroLimitPriceMaximum EXCEPT !.price = one] : one \in Sample(14) }
        \cup { [ZeroLimitPriceMaximum EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Limit Price Minimum: 16 bytes                                           *)
(***************************************************************************)

LimitPriceMinimum ==
    [ unitFlag : Sample(1),
      price    : Sample(14),
      sign     : Sample(1) ]

EncodeLimitPriceMinimum(message) ==
    message.unitFlag
        \o message.price
        \o message.sign

DecodeLimitPriceMinimum(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET price == ReadBytes(unitFlag.rest, 14) IN IF ~price.ok THEN Fail ELSE
    LET sign == ReadBytes(price.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         price    |-> price.value,
         sign     |-> sign.value ], sign.rest)

ZeroLimitPriceMinimum ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      price    |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Limit Price Minimum at zero, then each field in turn at the values it is checked at *)
CheckedLimitPriceMinimum ==
    { ZeroLimitPriceMinimum }
        \cup { [ZeroLimitPriceMinimum EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroLimitPriceMinimum EXCEPT !.price = one] : one \in Sample(14) }
        \cup { [ZeroLimitPriceMinimum EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Base Price Information Message: 66 bytes                                *)
(***************************************************************************)

BasePriceInformationMessage ==
    [ reserved2                          : Sample(2),
      basedBusinessDay                   : Sample(8),
      basePrice                          : BasePrice,
      limitPriceMaximum                  : LimitPriceMaximum,
      limitPriceMinimum                  : LimitPriceMinimum,
      basePricePriceOfTheMiddleOfTheBook : Sample(1),
      numberOfTickSizeTable              : Sample(2),
      reserved1                          : Sample(1),
      reserved4                          : Sample(4) ]

EncodeBasePriceInformationMessage(message) ==
    message.reserved2
        \o message.basedBusinessDay
        \o EncodeBasePrice(message.basePrice)
        \o EncodeLimitPriceMaximum(message.limitPriceMaximum)
        \o EncodeLimitPriceMinimum(message.limitPriceMinimum)
        \o message.basePricePriceOfTheMiddleOfTheBook
        \o message.numberOfTickSizeTable
        \o message.reserved1
        \o message.reserved4

DecodeBasePriceInformationMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET basedBusinessDay == ReadBytes(reserved2.rest, 8) IN IF ~basedBusinessDay.ok THEN Fail ELSE
    LET basePrice == DecodeBasePrice(basedBusinessDay.rest) IN IF ~basePrice.ok THEN Fail ELSE
    LET limitPriceMaximum == DecodeLimitPriceMaximum(basePrice.rest) IN IF ~limitPriceMaximum.ok THEN Fail ELSE
    LET limitPriceMinimum == DecodeLimitPriceMinimum(limitPriceMaximum.rest) IN IF ~limitPriceMinimum.ok THEN Fail ELSE
    LET basePricePriceOfTheMiddleOfTheBook == ReadBytes(limitPriceMinimum.rest, 1) IN IF ~basePricePriceOfTheMiddleOfTheBook.ok THEN Fail ELSE
    LET numberOfTickSizeTable == ReadBytes(basePricePriceOfTheMiddleOfTheBook.rest, 2) IN IF ~numberOfTickSizeTable.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(numberOfTickSizeTable.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reserved1.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ reserved2                          |-> reserved2.value,
         basedBusinessDay                   |-> basedBusinessDay.value,
         basePrice                          |-> basePrice.value,
         limitPriceMaximum                  |-> limitPriceMaximum.value,
         limitPriceMinimum                  |-> limitPriceMinimum.value,
         basePricePriceOfTheMiddleOfTheBook |-> basePricePriceOfTheMiddleOfTheBook.value,
         numberOfTickSizeTable              |-> numberOfTickSizeTable.value,
         reserved1                          |-> reserved1.value,
         reserved4                          |-> reserved4.value ], reserved4.rest)

ZeroBasePriceInformationMessage ==
    [ reserved2                          |-> [i \in 1 .. 2 |-> 0],
      basedBusinessDay                   |-> [i \in 1 .. 8 |-> 0],
      basePrice                          |-> ZeroBasePrice,
      limitPriceMaximum                  |-> ZeroLimitPriceMaximum,
      limitPriceMinimum                  |-> ZeroLimitPriceMinimum,
      basePricePriceOfTheMiddleOfTheBook |-> [i \in 1 .. 1 |-> 0],
      numberOfTickSizeTable              |-> [i \in 1 .. 2 |-> 0],
      reserved1                          |-> [i \in 1 .. 1 |-> 0],
      reserved4                          |-> [i \in 1 .. 4 |-> 0] ]

(* Base Price Information Message at zero, then each field in turn at the values it is checked at *)
CheckedBasePriceInformationMessage ==
    { ZeroBasePriceInformationMessage }
        \cup { [ZeroBasePriceInformationMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroBasePriceInformationMessage EXCEPT !.basedBusinessDay = one] : one \in Sample(8) }
        \cup { [ZeroBasePriceInformationMessage EXCEPT !.basePrice = one] : one \in CheckedBasePrice }
        \cup { [ZeroBasePriceInformationMessage EXCEPT !.limitPriceMaximum = one] : one \in CheckedLimitPriceMaximum }
        \cup { [ZeroBasePriceInformationMessage EXCEPT !.limitPriceMinimum = one] : one \in CheckedLimitPriceMinimum }
        \cup { [ZeroBasePriceInformationMessage EXCEPT !.basePricePriceOfTheMiddleOfTheBook = one] : one \in Sample(1) }
        \cup { [ZeroBasePriceInformationMessage EXCEPT !.numberOfTickSizeTable = one] : one \in Sample(2) }
        \cup { [ZeroBasePriceInformationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroBasePriceInformationMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Multicast Group Number Information Message: 14 bytes                    *)
(***************************************************************************)

MulticastGroupNumberInformationMessage ==
    [ reserved2                 : Sample(2),
      applicableBusinessDay     : Sample(8),
      issueMulticastGroupNumber : Sample(3),
      reserved1                 : Sample(1) ]

EncodeMulticastGroupNumberInformationMessage(message) ==
    message.reserved2
        \o message.applicableBusinessDay
        \o message.issueMulticastGroupNumber
        \o message.reserved1

DecodeMulticastGroupNumberInformationMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET applicableBusinessDay == ReadBytes(reserved2.rest, 8) IN IF ~applicableBusinessDay.ok THEN Fail ELSE
    LET issueMulticastGroupNumber == ReadBytes(applicableBusinessDay.rest, 3) IN IF ~issueMulticastGroupNumber.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(issueMulticastGroupNumber.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ reserved2                 |-> reserved2.value,
         applicableBusinessDay     |-> applicableBusinessDay.value,
         issueMulticastGroupNumber |-> issueMulticastGroupNumber.value,
         reserved1                 |-> reserved1.value ], reserved1.rest)

ZeroMulticastGroupNumberInformationMessage ==
    [ reserved2                 |-> [i \in 1 .. 2 |-> 0],
      applicableBusinessDay     |-> [i \in 1 .. 8 |-> 0],
      issueMulticastGroupNumber |-> [i \in 1 .. 3 |-> 0],
      reserved1                 |-> [i \in 1 .. 1 |-> 0] ]

(* Multicast Group Number Information Message at zero, then each field in turn at the values it is checked at *)
CheckedMulticastGroupNumberInformationMessage ==
    { ZeroMulticastGroupNumberInformationMessage }
        \cup { [ZeroMulticastGroupNumberInformationMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroMulticastGroupNumberInformationMessage EXCEPT !.applicableBusinessDay = one] : one \in Sample(8) }
        \cup { [ZeroMulticastGroupNumberInformationMessage EXCEPT !.issueMulticastGroupNumber = one] : one \in Sample(3) }
        \cup { [ZeroMulticastGroupNumberInformationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Control Message: 10 bytes                                               *)
(***************************************************************************)

ControlMessage ==
    [ reserved2    : Sample(2),
      testModeFlag : Sample(1),
      startEndFlag : Sample(1),
      time         : Sample(6) ]

EncodeControlMessage(message) ==
    message.reserved2
        \o message.testModeFlag
        \o message.startEndFlag
        \o message.time

DecodeControlMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET testModeFlag == ReadBytes(reserved2.rest, 1) IN IF ~testModeFlag.ok THEN Fail ELSE
    LET startEndFlag == ReadBytes(testModeFlag.rest, 1) IN IF ~startEndFlag.ok THEN Fail ELSE
    LET time == ReadBytes(startEndFlag.rest, 6) IN IF ~time.ok THEN Fail ELSE
    Ok([ reserved2    |-> reserved2.value,
         testModeFlag |-> testModeFlag.value,
         startEndFlag |-> startEndFlag.value,
         time         |-> time.value ], time.rest)

ZeroControlMessage ==
    [ reserved2    |-> [i \in 1 .. 2 |-> 0],
      testModeFlag |-> [i \in 1 .. 1 |-> 0],
      startEndFlag |-> [i \in 1 .. 1 |-> 0],
      time         |-> [i \in 1 .. 6 |-> 0] ]

(* Control Message at zero, then each field in turn at the values it is checked at *)
CheckedControlMessage ==
    { ZeroControlMessage }
        \cup { [ZeroControlMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroControlMessage EXCEPT !.testModeFlag = one] : one \in Sample(1) }
        \cup { [ZeroControlMessage EXCEPT !.startEndFlag = one] : one \in Sample(1) }
        \cup { [ZeroControlMessage EXCEPT !.time = one] : one \in Sample(6) }

(***************************************************************************)
(* Payload, selected by Tag ID                                             *)
(***************************************************************************)

IssueInformationMessageCode == 18761  \* "II"
BasePriceInformationMessageCode == 16976  \* "BP"
MulticastGroupNumberInformationMessageCode == 19783  \* "MG"
ControlMessageCode == 19523  \* "LC"

Payload ==
    [ tag : {IssueInformationMessageCode}, body : IssueInformationMessage ]
        \cup [ tag : {BasePriceInformationMessageCode}, body : BasePriceInformationMessage ]
        \cup [ tag : {MulticastGroupNumberInformationMessageCode}, body : MulticastGroupNumberInformationMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]

EncodePayload(message) ==
    CASE message.tag = IssueInformationMessageCode -> EncodeIssueInformationMessage(message.body)
      [] message.tag = BasePriceInformationMessageCode -> EncodeBasePriceInformationMessage(message.body)
      [] message.tag = MulticastGroupNumberInformationMessageCode -> EncodeMulticastGroupNumberInformationMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = IssueInformationMessageCode -> DecodeIssueInformationMessage(bytes)
              [] tag = BasePriceInformationMessageCode -> DecodeBasePriceInformationMessage(bytes)
              [] tag = MulticastGroupNumberInformationMessageCode -> DecodeMulticastGroupNumberInformationMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> IssueInformationMessageCode, body |-> ZeroIssueInformationMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> IssueInformationMessageCode, body |-> one] : one \in CheckedIssueInformationMessage }
        \cup { [tag |-> BasePriceInformationMessageCode, body |-> one] : one \in CheckedBasePriceInformationMessage }
        \cup { [tag |-> MulticastGroupNumberInformationMessageCode, body |-> one] : one \in CheckedMulticastGroupNumberInformationMessage }
        \cup { [tag |-> ControlMessageCode, body |-> one] : one \in CheckedControlMessage }

(***************************************************************************)
(* Tag Information                                                         *)
(***************************************************************************)

TagInformation ==
    [ payload         : Payload,
      separationOfTag : Sample(1) ]

EncodeTagInformation(message) ==
    EncodeUIntBE(message.payload.tag, 2)
        \o EncodePayload(message.payload)
        \o message.separationOfTag

DecodeTagInformation(bytes) ==
    LET tagId == ReadUIntBE(bytes, 2) IN IF ~tagId.ok THEN Fail ELSE
    LET payload == DecodePayload(tagId.value, tagId.rest) IN IF ~payload.ok THEN Fail ELSE
    LET separationOfTag == ReadBytes(payload.rest, 1) IN IF ~separationOfTag.ok THEN Fail ELSE
    Ok([ payload         |-> payload.value,
         separationOfTag |-> separationOfTag.value ], separationOfTag.rest)

ZeroTagInformation ==
    [ payload         |-> ZeroPayload,
      separationOfTag |-> [i \in 1 .. 1 |-> 0] ]

(* Tag Information at zero, then each field in turn at the values it is checked at *)
CheckedTagInformation ==
    { ZeroTagInformation }
        \cup { [ZeroTagInformation EXCEPT !.payload = one] : one \in CheckedPayload }
        \cup { [ZeroTagInformation EXCEPT !.separationOfTag = one] : one \in Sample(1) }

(* A run of Tag Information, written one after another *)
RECURSIVE EncodeTagInformationList(_)
EncodeTagInformationList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTagInformation(Head(messages)) \o EncodeTagInformationList(Tail(messages))

(* As many Tag Information as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadTagInformationAll(_)
ReadTagInformationAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeTagInformation(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTagInformationAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Tag Information of each kind, for the lists that carry them *)
OneTagInformation ==
    { [ZeroTagInformation EXCEPT !.payload = [tag |-> IssueInformationMessageCode, body |-> ZeroIssueInformationMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> BasePriceInformationMessageCode, body |-> ZeroBasePriceInformationMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> MulticastGroupNumberInformationMessageCode, body |-> ZeroMulticastGroupNumberInformationMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> ControlMessageCode, body |-> ZeroControlMessage]] }

(***************************************************************************)
(* Udp Packet                                                              *)
(***************************************************************************)

UdpPacket ==
    [ startOfMessage                               : Sample(1),
      serviceHeader                                : ServiceHeader,
      separationBetweenServiceHeaderAndDataSection : Sample(1),
      tagInformation                               : SampleLists(OneTagInformation) ]

EncodeUdpPacket(message) ==
    message.startOfMessage
        \o EncodeServiceHeader(message.serviceHeader)
        \o message.separationBetweenServiceHeaderAndDataSection
        \o EncodeTagInformationList(message.tagInformation)

DecodeUdpPacket(bytes) ==
    LET startOfMessage == ReadBytes(bytes, 1) IN IF ~startOfMessage.ok THEN Fail ELSE
    LET serviceHeader == DecodeServiceHeader(startOfMessage.rest) IN IF ~serviceHeader.ok THEN Fail ELSE
    LET separationBetweenServiceHeaderAndDataSection == ReadBytes(serviceHeader.rest, 1) IN IF ~separationBetweenServiceHeaderAndDataSection.ok THEN Fail ELSE
    LET tagInformation == ReadTagInformationAll(separationBetweenServiceHeaderAndDataSection.rest) IN IF ~tagInformation.ok THEN Fail ELSE
    Ok([ startOfMessage                               |-> startOfMessage.value,
         serviceHeader                                |-> serviceHeader.value,
         separationBetweenServiceHeaderAndDataSection |-> separationBetweenServiceHeaderAndDataSection.value,
         tagInformation                               |-> tagInformation.value ], tagInformation.rest)

ZeroUdpPacket ==
    [ startOfMessage                               |-> [i \in 1 .. 1 |-> 0],
      serviceHeader                                |-> ZeroServiceHeader,
      separationBetweenServiceHeaderAndDataSection |-> [i \in 1 .. 1 |-> 0],
      tagInformation                               |-> << >> ]

(* Udp Packet at zero, then each field in turn at the values it is checked at *)
CheckedUdpPacket ==
    { ZeroUdpPacket }
        \cup { [ZeroUdpPacket EXCEPT !.startOfMessage = one] : one \in Sample(1) }
        \cup { [ZeroUdpPacket EXCEPT !.serviceHeader = one] : one \in CheckedServiceHeader }
        \cup { [ZeroUdpPacket EXCEPT !.separationBetweenServiceHeaderAndDataSection = one] : one \in Sample(1) }
        \cup { [ZeroUdpPacket EXCEPT !.tagInformation = one] : one \in SampleLists(OneTagInformation) }

(***************************************************************************)
(* What TLC checks                                                         *)
(***************************************************************************)

(* An integer a rule depends on writes its width and reads back what was written *)
RoundTripUIntLE ==
    \A width \in 1 .. 3 :
        \A value \in {0, 1, 255, 256, 65535} :
            (value < 256 ^ width) =>
                /\ Len(EncodeUIntLE(value, width)) = width
                /\ DecodeUIntLE(EncodeUIntLE(value, width)) = value
                /\ Len(EncodeUIntBE(value, width)) = width
                /\ DecodeUIntBE(EncodeUIntBE(value, width)) = value
                /\ \A i \in 1 .. width : EncodeUIntLE(value, width)[i] \in Byte
                /\ \A i \in 1 .. width : EncodeUIntBE(value, width)[i] \in Byte

(* Every Message Serial No decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageSerialNo ==
    \A message \in CheckedMessageSerialNo :
        LET read == DecodeMessageSerialNo(EncodeMessageSerialNo(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Type decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageType ==
    \A message \in CheckedMessageType :
        LET read == DecodeMessageType(EncodeMessageType(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Issue Code decodes back to what was encoded, and leaves nothing over *)
RoundTripStockIssueCode ==
    \A message \in CheckedStockIssueCode :
        LET read == DecodeStockIssueCode(EncodeStockIssueCode(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every CB Issue Code decodes back to what was encoded, and leaves nothing over *)
RoundTripCbIssueCode ==
    \A message \in CheckedCbIssueCode :
        LET read == DecodeCbIssueCode(EncodeCbIssueCode(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Blank Issue Code decodes back to what was encoded, and leaves nothing over *)
RoundTripBlankIssueCode ==
    \A message \in CheckedBlankIssueCode :
        LET read == DecodeBlankIssueCode(EncodeBlankIssueCode(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Service Header decodes back to what was encoded, and leaves nothing over *)
RoundTripServiceHeader ==
    \A message \in CheckedServiceHeader :
        LET read == DecodeServiceHeader(EncodeServiceHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Constituent Issue decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexConstituentIssue ==
    \A message \in CheckedIndexConstituentIssue :
        LET read == DecodeIndexConstituentIssue(EncodeIndexConstituentIssue(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Orders Prohibition decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrdersProhibition ==
    \A message \in CheckedNewOrdersProhibition :
        LET read == DecodeNewOrdersProhibition(EncodeNewOrdersProhibition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Margin Transactions Prohibition decodes back to what was encoded, and leaves nothing over *)
RoundTripMarginTransactionsProhibition ==
    \A message \in CheckedMarginTransactionsProhibition :
        LET read == DecodeMarginTransactionsProhibition(EncodeMarginTransactionsProhibition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Selling Prohibition decodes back to what was encoded, and leaves nothing over *)
RoundTripShortSellingProhibition ==
    \A message \in CheckedShortSellingProhibition :
        LET read == DecodeShortSellingProhibition(EncodeShortSellingProhibition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Prohibition Status At The Regular Distribution decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderProhibitionStatusAtTheRegularDistribution ==
    \A message \in CheckedOrderProhibitionStatusAtTheRegularDistribution :
        LET read == DecodeOrderProhibitionStatusAtTheRegularDistribution(EncodeOrderProhibitionStatusAtTheRegularDistribution(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Issue Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIssueInformationMessage ==
    \A message \in CheckedIssueInformationMessage :
        LET read == DecodeIssueInformationMessage(EncodeIssueInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Base Price decodes back to what was encoded, and leaves nothing over *)
RoundTripBasePrice ==
    \A message \in CheckedBasePrice :
        LET read == DecodeBasePrice(EncodeBasePrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Limit Price Maximum decodes back to what was encoded, and leaves nothing over *)
RoundTripLimitPriceMaximum ==
    \A message \in CheckedLimitPriceMaximum :
        LET read == DecodeLimitPriceMaximum(EncodeLimitPriceMaximum(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Limit Price Minimum decodes back to what was encoded, and leaves nothing over *)
RoundTripLimitPriceMinimum ==
    \A message \in CheckedLimitPriceMinimum :
        LET read == DecodeLimitPriceMinimum(EncodeLimitPriceMinimum(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Base Price Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBasePriceInformationMessage ==
    \A message \in CheckedBasePriceInformationMessage :
        LET read == DecodeBasePriceInformationMessage(EncodeBasePriceInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Multicast Group Number Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMulticastGroupNumberInformationMessage ==
    \A message \in CheckedMulticastGroupNumberInformationMessage :
        LET read == DecodeMulticastGroupNumberInformationMessage(EncodeMulticastGroupNumberInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Control Message decodes back to what was encoded, and leaves nothing over *)
RoundTripControlMessage ==
    \A message \in CheckedControlMessage :
        LET read == DecodeControlMessage(EncodeControlMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tag Information decodes back to what was encoded, and leaves nothing over *)
RoundTripTagInformation ==
    \A message \in CheckedTagInformation :
        LET read == DecodeTagInformation(EncodeTagInformation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Udp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUdpPacket ==
    \A message \in CheckedUdpPacket :
        LET read == DecodeUdpPacket(EncodeUdpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Issue Code is selected by the Issue Classification Large Classification it is written under *)
SelectsIssueCode ==
    \A message \in CheckedIssueCode :
        LET sent == EncodeIssueCode(message)
            read == DecodeIssueCode(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Tag ID it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
