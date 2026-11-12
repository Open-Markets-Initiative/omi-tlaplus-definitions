----------------- MODULE TseEquities_IndexStatistics_v19_5 -----------------
(***************************************************************************)
(* Japan Exchange Group IndexStatistics v19.5                              *)
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
(* Note: Top Rank By Trading Volume is written as 30 slots, however many   *)
(* of them the count beside it says are in use.                            *)
(*                                                                         *)
(* Note: Top Rank By Turnover is written as 30 slots, however many of them *)
(* the count beside it says are in use.                                    *)
(*                                                                         *)
(* Note: Top Rank By Net Change is written as 30 slots, however many of    *)
(* them the count beside it says are in use.                               *)
(*                                                                         *)
(* Note: Top Rank By Net Change Rate is written as 30 slots, however many  *)
(* of them the count beside it says are in use.                            *)
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
(* Total Market Value: 15 bytes                                            *)
(***************************************************************************)

TotalMarketValue ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      totalMarketValueC14           : Sample(14) ]

EncodeTotalMarketValue(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.totalMarketValueC14

DecodeTotalMarketValue(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET totalMarketValueC14 == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~totalMarketValueC14.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         totalMarketValueC14           |-> totalMarketValueC14.value ], totalMarketValueC14.rest)

ZeroTotalMarketValue ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      totalMarketValueC14           |-> [i \in 1 .. 14 |-> 0] ]

(* Total Market Value at zero, then each field in turn at the values it is checked at *)
CheckedTotalMarketValue ==
    { ZeroTotalMarketValue }
        \cup { [ZeroTotalMarketValue EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTotalMarketValue EXCEPT !.totalMarketValueC14 = one] : one \in Sample(14) }

(***************************************************************************)
(* Market Value Day On Day Comparison: 16 bytes                            *)
(***************************************************************************)

MarketValueDayOnDayComparison ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      dayOnDayComparisonC14         : Sample(14),
      sign                          : Sample(1) ]

EncodeMarketValueDayOnDayComparison(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.dayOnDayComparisonC14
        \o message.sign

DecodeMarketValueDayOnDayComparison(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET dayOnDayComparisonC14 == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~dayOnDayComparisonC14.ok THEN Fail ELSE
    LET sign == ReadBytes(dayOnDayComparisonC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         dayOnDayComparisonC14         |-> dayOnDayComparisonC14.value,
         sign                          |-> sign.value ], sign.rest)

ZeroMarketValueDayOnDayComparison ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      dayOnDayComparisonC14         |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Market Value Day On Day Comparison at zero, then each field in turn at the values it is checked at *)
CheckedMarketValueDayOnDayComparison ==
    { ZeroMarketValueDayOnDayComparison }
        \cup { [ZeroMarketValueDayOnDayComparison EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroMarketValueDayOnDayComparison EXCEPT !.dayOnDayComparisonC14 = one] : one \in Sample(14) }
        \cup { [ZeroMarketValueDayOnDayComparison EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Value Message: 43 bytes                                          *)
(***************************************************************************)

MarketValueMessage ==
    [ reserved2                     : Sample(2),
      timeC6Hhmm                    : Sample(6),
      issueClassificationCode       : Sample(4),
      totalMarketValue              : TotalMarketValue,
      marketValueDayOnDayComparison : MarketValueDayOnDayComparison ]

EncodeMarketValueMessage(message) ==
    message.reserved2
        \o message.timeC6Hhmm
        \o message.issueClassificationCode
        \o EncodeTotalMarketValue(message.totalMarketValue)
        \o EncodeMarketValueDayOnDayComparison(message.marketValueDayOnDayComparison)

DecodeMarketValueMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET timeC6Hhmm == ReadBytes(reserved2.rest, 6) IN IF ~timeC6Hhmm.ok THEN Fail ELSE
    LET issueClassificationCode == ReadBytes(timeC6Hhmm.rest, 4) IN IF ~issueClassificationCode.ok THEN Fail ELSE
    LET totalMarketValue == DecodeTotalMarketValue(issueClassificationCode.rest) IN IF ~totalMarketValue.ok THEN Fail ELSE
    LET marketValueDayOnDayComparison == DecodeMarketValueDayOnDayComparison(totalMarketValue.rest) IN IF ~marketValueDayOnDayComparison.ok THEN Fail ELSE
    Ok([ reserved2                     |-> reserved2.value,
         timeC6Hhmm                    |-> timeC6Hhmm.value,
         issueClassificationCode       |-> issueClassificationCode.value,
         totalMarketValue              |-> totalMarketValue.value,
         marketValueDayOnDayComparison |-> marketValueDayOnDayComparison.value ], marketValueDayOnDayComparison.rest)

ZeroMarketValueMessage ==
    [ reserved2                     |-> [i \in 1 .. 2 |-> 0],
      timeC6Hhmm                    |-> [i \in 1 .. 6 |-> 0],
      issueClassificationCode       |-> [i \in 1 .. 4 |-> 0],
      totalMarketValue              |-> ZeroTotalMarketValue,
      marketValueDayOnDayComparison |-> ZeroMarketValueDayOnDayComparison ]

(* Market Value Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketValueMessage ==
    { ZeroMarketValueMessage }
        \cup { [ZeroMarketValueMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroMarketValueMessage EXCEPT !.timeC6Hhmm = one] : one \in Sample(6) }
        \cup { [ZeroMarketValueMessage EXCEPT !.issueClassificationCode = one] : one \in Sample(4) }
        \cup { [ZeroMarketValueMessage EXCEPT !.totalMarketValue = one] : one \in CheckedTotalMarketValue }
        \cup { [ZeroMarketValueMessage EXCEPT !.marketValueDayOnDayComparison = one] : one \in CheckedMarketValueDayOnDayComparison }

(***************************************************************************)
(* Simple Yield: 9 bytes                                                   *)
(***************************************************************************)

SimpleYield ==
    [ simpleYieldC8 : Sample(8),
      sign          : Sample(1) ]

EncodeSimpleYield(message) ==
    message.simpleYieldC8
        \o message.sign

DecodeSimpleYield(bytes) ==
    LET simpleYieldC8 == ReadBytes(bytes, 8) IN IF ~simpleYieldC8.ok THEN Fail ELSE
    LET sign == ReadBytes(simpleYieldC8.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ simpleYieldC8 |-> simpleYieldC8.value,
         sign          |-> sign.value ], sign.rest)

ZeroSimpleYield ==
    [ simpleYieldC8 |-> [i \in 1 .. 8 |-> 0],
      sign          |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Yield at zero, then each field in turn at the values it is checked at *)
CheckedSimpleYield ==
    { ZeroSimpleYield }
        \cup { [ZeroSimpleYield EXCEPT !.simpleYieldC8 = one] : one \in Sample(8) }
        \cup { [ZeroSimpleYield EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Yield Day On Day Comparison: 9 bytes                                    *)
(***************************************************************************)

YieldDayOnDayComparison ==
    [ dayOnDayComparisonC8 : Sample(8),
      sign                 : Sample(1) ]

EncodeYieldDayOnDayComparison(message) ==
    message.dayOnDayComparisonC8
        \o message.sign

DecodeYieldDayOnDayComparison(bytes) ==
    LET dayOnDayComparisonC8 == ReadBytes(bytes, 8) IN IF ~dayOnDayComparisonC8.ok THEN Fail ELSE
    LET sign == ReadBytes(dayOnDayComparisonC8.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ dayOnDayComparisonC8 |-> dayOnDayComparisonC8.value,
         sign                 |-> sign.value ], sign.rest)

ZeroYieldDayOnDayComparison ==
    [ dayOnDayComparisonC8 |-> [i \in 1 .. 8 |-> 0],
      sign                 |-> [i \in 1 .. 1 |-> 0] ]

(* Yield Day On Day Comparison at zero, then each field in turn at the values it is checked at *)
CheckedYieldDayOnDayComparison ==
    { ZeroYieldDayOnDayComparison }
        \cup { [ZeroYieldDayOnDayComparison EXCEPT !.dayOnDayComparisonC8 = one] : one \in Sample(8) }
        \cup { [ZeroYieldDayOnDayComparison EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Yield Message: 30 bytes                                          *)
(***************************************************************************)

SimpleYieldMessage ==
    [ reserved2               : Sample(2),
      timeC6Hhmm              : Sample(6),
      issueClassificationCode : Sample(4),
      simpleYield             : SimpleYield,
      yieldDayOnDayComparison : YieldDayOnDayComparison ]

EncodeSimpleYieldMessage(message) ==
    message.reserved2
        \o message.timeC6Hhmm
        \o message.issueClassificationCode
        \o EncodeSimpleYield(message.simpleYield)
        \o EncodeYieldDayOnDayComparison(message.yieldDayOnDayComparison)

DecodeSimpleYieldMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET timeC6Hhmm == ReadBytes(reserved2.rest, 6) IN IF ~timeC6Hhmm.ok THEN Fail ELSE
    LET issueClassificationCode == ReadBytes(timeC6Hhmm.rest, 4) IN IF ~issueClassificationCode.ok THEN Fail ELSE
    LET simpleYield == DecodeSimpleYield(issueClassificationCode.rest) IN IF ~simpleYield.ok THEN Fail ELSE
    LET yieldDayOnDayComparison == DecodeYieldDayOnDayComparison(simpleYield.rest) IN IF ~yieldDayOnDayComparison.ok THEN Fail ELSE
    Ok([ reserved2               |-> reserved2.value,
         timeC6Hhmm              |-> timeC6Hhmm.value,
         issueClassificationCode |-> issueClassificationCode.value,
         simpleYield             |-> simpleYield.value,
         yieldDayOnDayComparison |-> yieldDayOnDayComparison.value ], yieldDayOnDayComparison.rest)

ZeroSimpleYieldMessage ==
    [ reserved2               |-> [i \in 1 .. 2 |-> 0],
      timeC6Hhmm              |-> [i \in 1 .. 6 |-> 0],
      issueClassificationCode |-> [i \in 1 .. 4 |-> 0],
      simpleYield             |-> ZeroSimpleYield,
      yieldDayOnDayComparison |-> ZeroYieldDayOnDayComparison ]

(* Simple Yield Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleYieldMessage ==
    { ZeroSimpleYieldMessage }
        \cup { [ZeroSimpleYieldMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleYieldMessage EXCEPT !.timeC6Hhmm = one] : one \in Sample(6) }
        \cup { [ZeroSimpleYieldMessage EXCEPT !.issueClassificationCode = one] : one \in Sample(4) }
        \cup { [ZeroSimpleYieldMessage EXCEPT !.simpleYield = one] : one \in CheckedSimpleYield }
        \cup { [ZeroSimpleYieldMessage EXCEPT !.yieldDayOnDayComparison = one] : one \in CheckedYieldDayOnDayComparison }

(***************************************************************************)
(* Weighted Yield: 9 bytes                                                 *)
(***************************************************************************)

WeightedYield ==
    [ weightedYieldC8 : Sample(8),
      sign            : Sample(1) ]

EncodeWeightedYield(message) ==
    message.weightedYieldC8
        \o message.sign

DecodeWeightedYield(bytes) ==
    LET weightedYieldC8 == ReadBytes(bytes, 8) IN IF ~weightedYieldC8.ok THEN Fail ELSE
    LET sign == ReadBytes(weightedYieldC8.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ weightedYieldC8 |-> weightedYieldC8.value,
         sign            |-> sign.value ], sign.rest)

ZeroWeightedYield ==
    [ weightedYieldC8 |-> [i \in 1 .. 8 |-> 0],
      sign            |-> [i \in 1 .. 1 |-> 0] ]

(* Weighted Yield at zero, then each field in turn at the values it is checked at *)
CheckedWeightedYield ==
    { ZeroWeightedYield }
        \cup { [ZeroWeightedYield EXCEPT !.weightedYieldC8 = one] : one \in Sample(8) }
        \cup { [ZeroWeightedYield EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Yield Day On Day Comparison: 9 bytes                                    *)
(***************************************************************************)

YieldDayOnDayComparison2 ==
    [ dayOnDayComparisonC8 : Sample(8),
      sign                 : Sample(1) ]

EncodeYieldDayOnDayComparison2(message) ==
    message.dayOnDayComparisonC8
        \o message.sign

DecodeYieldDayOnDayComparison2(bytes) ==
    LET dayOnDayComparisonC8 == ReadBytes(bytes, 8) IN IF ~dayOnDayComparisonC8.ok THEN Fail ELSE
    LET sign == ReadBytes(dayOnDayComparisonC8.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ dayOnDayComparisonC8 |-> dayOnDayComparisonC8.value,
         sign                 |-> sign.value ], sign.rest)

ZeroYieldDayOnDayComparison2 ==
    [ dayOnDayComparisonC8 |-> [i \in 1 .. 8 |-> 0],
      sign                 |-> [i \in 1 .. 1 |-> 0] ]

(* Yield Day On Day Comparison at zero, then each field in turn at the values it is checked at *)
CheckedYieldDayOnDayComparison2 ==
    { ZeroYieldDayOnDayComparison2 }
        \cup { [ZeroYieldDayOnDayComparison2 EXCEPT !.dayOnDayComparisonC8 = one] : one \in Sample(8) }
        \cup { [ZeroYieldDayOnDayComparison2 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Weighted Yield Message: 30 bytes                                        *)
(***************************************************************************)

WeightedYieldMessage ==
    [ reserved2               : Sample(2),
      timeC6Hhmm              : Sample(6),
      issueClassificationCode : Sample(4),
      weightedYield           : WeightedYield,
      yieldDayOnDayComparison : YieldDayOnDayComparison2 ]

EncodeWeightedYieldMessage(message) ==
    message.reserved2
        \o message.timeC6Hhmm
        \o message.issueClassificationCode
        \o EncodeWeightedYield(message.weightedYield)
        \o EncodeYieldDayOnDayComparison2(message.yieldDayOnDayComparison)

DecodeWeightedYieldMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET timeC6Hhmm == ReadBytes(reserved2.rest, 6) IN IF ~timeC6Hhmm.ok THEN Fail ELSE
    LET issueClassificationCode == ReadBytes(timeC6Hhmm.rest, 4) IN IF ~issueClassificationCode.ok THEN Fail ELSE
    LET weightedYield == DecodeWeightedYield(issueClassificationCode.rest) IN IF ~weightedYield.ok THEN Fail ELSE
    LET yieldDayOnDayComparison == DecodeYieldDayOnDayComparison2(weightedYield.rest) IN IF ~yieldDayOnDayComparison.ok THEN Fail ELSE
    Ok([ reserved2               |-> reserved2.value,
         timeC6Hhmm              |-> timeC6Hhmm.value,
         issueClassificationCode |-> issueClassificationCode.value,
         weightedYield           |-> weightedYield.value,
         yieldDayOnDayComparison |-> yieldDayOnDayComparison.value ], yieldDayOnDayComparison.rest)

ZeroWeightedYieldMessage ==
    [ reserved2               |-> [i \in 1 .. 2 |-> 0],
      timeC6Hhmm              |-> [i \in 1 .. 6 |-> 0],
      issueClassificationCode |-> [i \in 1 .. 4 |-> 0],
      weightedYield           |-> ZeroWeightedYield,
      yieldDayOnDayComparison |-> ZeroYieldDayOnDayComparison2 ]

(* Weighted Yield Message at zero, then each field in turn at the values it is checked at *)
CheckedWeightedYieldMessage ==
    { ZeroWeightedYieldMessage }
        \cup { [ZeroWeightedYieldMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroWeightedYieldMessage EXCEPT !.timeC6Hhmm = one] : one \in Sample(6) }
        \cup { [ZeroWeightedYieldMessage EXCEPT !.issueClassificationCode = one] : one \in Sample(4) }
        \cup { [ZeroWeightedYieldMessage EXCEPT !.weightedYield = one] : one \in CheckedWeightedYield }
        \cup { [ZeroWeightedYieldMessage EXCEPT !.yieldDayOnDayComparison = one] : one \in CheckedYieldDayOnDayComparison2 }

(***************************************************************************)
(* Simple Stock Price Average: 16 bytes                                    *)
(***************************************************************************)

SimpleStockPriceAverage ==
    [ unitFlag                   : Sample(1),
      simpleStockPriceAverageC14 : Sample(14),
      sign                       : Sample(1) ]

EncodeSimpleStockPriceAverage(message) ==
    message.unitFlag
        \o message.simpleStockPriceAverageC14
        \o message.sign

DecodeSimpleStockPriceAverage(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET simpleStockPriceAverageC14 == ReadBytes(unitFlag.rest, 14) IN IF ~simpleStockPriceAverageC14.ok THEN Fail ELSE
    LET sign == ReadBytes(simpleStockPriceAverageC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag                   |-> unitFlag.value,
         simpleStockPriceAverageC14 |-> simpleStockPriceAverageC14.value,
         sign                       |-> sign.value ], sign.rest)

ZeroSimpleStockPriceAverage ==
    [ unitFlag                   |-> [i \in 1 .. 1 |-> 0],
      simpleStockPriceAverageC14 |-> [i \in 1 .. 14 |-> 0],
      sign                       |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Stock Price Average at zero, then each field in turn at the values it is checked at *)
CheckedSimpleStockPriceAverage ==
    { ZeroSimpleStockPriceAverage }
        \cup { [ZeroSimpleStockPriceAverage EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroSimpleStockPriceAverage EXCEPT !.simpleStockPriceAverageC14 = one] : one \in Sample(14) }
        \cup { [ZeroSimpleStockPriceAverage EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Price Average Day On Day Comparison: 16 bytes                     *)
(***************************************************************************)

StockPriceAverageDayOnDayComparison ==
    [ unitFlag              : Sample(1),
      dayOnDayComparisonC14 : Sample(14),
      sign                  : Sample(1) ]

EncodeStockPriceAverageDayOnDayComparison(message) ==
    message.unitFlag
        \o message.dayOnDayComparisonC14
        \o message.sign

DecodeStockPriceAverageDayOnDayComparison(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET dayOnDayComparisonC14 == ReadBytes(unitFlag.rest, 14) IN IF ~dayOnDayComparisonC14.ok THEN Fail ELSE
    LET sign == ReadBytes(dayOnDayComparisonC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag              |-> unitFlag.value,
         dayOnDayComparisonC14 |-> dayOnDayComparisonC14.value,
         sign                  |-> sign.value ], sign.rest)

ZeroStockPriceAverageDayOnDayComparison ==
    [ unitFlag              |-> [i \in 1 .. 1 |-> 0],
      dayOnDayComparisonC14 |-> [i \in 1 .. 14 |-> 0],
      sign                  |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Price Average Day On Day Comparison at zero, then each field in turn at the values it is checked at *)
CheckedStockPriceAverageDayOnDayComparison ==
    { ZeroStockPriceAverageDayOnDayComparison }
        \cup { [ZeroStockPriceAverageDayOnDayComparison EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroStockPriceAverageDayOnDayComparison EXCEPT !.dayOnDayComparisonC14 = one] : one \in Sample(14) }
        \cup { [ZeroStockPriceAverageDayOnDayComparison EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Stock Price Average Message: 44 bytes                            *)
(***************************************************************************)

SimpleStockPriceAverageMessage ==
    [ reserved2                           : Sample(2),
      outputTime                          : Sample(6),
      issueClassificationCode             : Sample(4),
      simpleStockPriceAverage             : SimpleStockPriceAverage,
      stockPriceAverageDayOnDayComparison : StockPriceAverageDayOnDayComparison ]

EncodeSimpleStockPriceAverageMessage(message) ==
    message.reserved2
        \o message.outputTime
        \o message.issueClassificationCode
        \o EncodeSimpleStockPriceAverage(message.simpleStockPriceAverage)
        \o EncodeStockPriceAverageDayOnDayComparison(message.stockPriceAverageDayOnDayComparison)

DecodeSimpleStockPriceAverageMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET outputTime == ReadBytes(reserved2.rest, 6) IN IF ~outputTime.ok THEN Fail ELSE
    LET issueClassificationCode == ReadBytes(outputTime.rest, 4) IN IF ~issueClassificationCode.ok THEN Fail ELSE
    LET simpleStockPriceAverage == DecodeSimpleStockPriceAverage(issueClassificationCode.rest) IN IF ~simpleStockPriceAverage.ok THEN Fail ELSE
    LET stockPriceAverageDayOnDayComparison == DecodeStockPriceAverageDayOnDayComparison(simpleStockPriceAverage.rest) IN IF ~stockPriceAverageDayOnDayComparison.ok THEN Fail ELSE
    Ok([ reserved2                           |-> reserved2.value,
         outputTime                          |-> outputTime.value,
         issueClassificationCode             |-> issueClassificationCode.value,
         simpleStockPriceAverage             |-> simpleStockPriceAverage.value,
         stockPriceAverageDayOnDayComparison |-> stockPriceAverageDayOnDayComparison.value ], stockPriceAverageDayOnDayComparison.rest)

ZeroSimpleStockPriceAverageMessage ==
    [ reserved2                           |-> [i \in 1 .. 2 |-> 0],
      outputTime                          |-> [i \in 1 .. 6 |-> 0],
      issueClassificationCode             |-> [i \in 1 .. 4 |-> 0],
      simpleStockPriceAverage             |-> ZeroSimpleStockPriceAverage,
      stockPriceAverageDayOnDayComparison |-> ZeroStockPriceAverageDayOnDayComparison ]

(* Simple Stock Price Average Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleStockPriceAverageMessage ==
    { ZeroSimpleStockPriceAverageMessage }
        \cup { [ZeroSimpleStockPriceAverageMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleStockPriceAverageMessage EXCEPT !.outputTime = one] : one \in Sample(6) }
        \cup { [ZeroSimpleStockPriceAverageMessage EXCEPT !.issueClassificationCode = one] : one \in Sample(4) }
        \cup { [ZeroSimpleStockPriceAverageMessage EXCEPT !.simpleStockPriceAverage = one] : one \in CheckedSimpleStockPriceAverage }
        \cup { [ZeroSimpleStockPriceAverageMessage EXCEPT !.stockPriceAverageDayOnDayComparison = one] : one \in CheckedStockPriceAverageDayOnDayComparison }

(***************************************************************************)
(* Weighted Stock Price Average: 16 bytes                                  *)
(***************************************************************************)

WeightedStockPriceAverage ==
    [ unitFlag                     : Sample(1),
      weightedStockPriceAverageC14 : Sample(14),
      sign                         : Sample(1) ]

EncodeWeightedStockPriceAverage(message) ==
    message.unitFlag
        \o message.weightedStockPriceAverageC14
        \o message.sign

DecodeWeightedStockPriceAverage(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET weightedStockPriceAverageC14 == ReadBytes(unitFlag.rest, 14) IN IF ~weightedStockPriceAverageC14.ok THEN Fail ELSE
    LET sign == ReadBytes(weightedStockPriceAverageC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag                     |-> unitFlag.value,
         weightedStockPriceAverageC14 |-> weightedStockPriceAverageC14.value,
         sign                         |-> sign.value ], sign.rest)

ZeroWeightedStockPriceAverage ==
    [ unitFlag                     |-> [i \in 1 .. 1 |-> 0],
      weightedStockPriceAverageC14 |-> [i \in 1 .. 14 |-> 0],
      sign                         |-> [i \in 1 .. 1 |-> 0] ]

(* Weighted Stock Price Average at zero, then each field in turn at the values it is checked at *)
CheckedWeightedStockPriceAverage ==
    { ZeroWeightedStockPriceAverage }
        \cup { [ZeroWeightedStockPriceAverage EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroWeightedStockPriceAverage EXCEPT !.weightedStockPriceAverageC14 = one] : one \in Sample(14) }
        \cup { [ZeroWeightedStockPriceAverage EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Price Average Day On Day Comparison: 16 bytes                     *)
(***************************************************************************)

StockPriceAverageDayOnDayComparison2 ==
    [ unitFlag              : Sample(1),
      dayOnDayComparisonC14 : Sample(14),
      sign                  : Sample(1) ]

EncodeStockPriceAverageDayOnDayComparison2(message) ==
    message.unitFlag
        \o message.dayOnDayComparisonC14
        \o message.sign

DecodeStockPriceAverageDayOnDayComparison2(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET dayOnDayComparisonC14 == ReadBytes(unitFlag.rest, 14) IN IF ~dayOnDayComparisonC14.ok THEN Fail ELSE
    LET sign == ReadBytes(dayOnDayComparisonC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag              |-> unitFlag.value,
         dayOnDayComparisonC14 |-> dayOnDayComparisonC14.value,
         sign                  |-> sign.value ], sign.rest)

ZeroStockPriceAverageDayOnDayComparison2 ==
    [ unitFlag              |-> [i \in 1 .. 1 |-> 0],
      dayOnDayComparisonC14 |-> [i \in 1 .. 14 |-> 0],
      sign                  |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Price Average Day On Day Comparison at zero, then each field in turn at the values it is checked at *)
CheckedStockPriceAverageDayOnDayComparison2 ==
    { ZeroStockPriceAverageDayOnDayComparison2 }
        \cup { [ZeroStockPriceAverageDayOnDayComparison2 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroStockPriceAverageDayOnDayComparison2 EXCEPT !.dayOnDayComparisonC14 = one] : one \in Sample(14) }
        \cup { [ZeroStockPriceAverageDayOnDayComparison2 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Weighted Stock Price Average Message: 44 bytes                          *)
(***************************************************************************)

WeightedStockPriceAverageMessage ==
    [ reserved2                           : Sample(2),
      outputTime                          : Sample(6),
      issueClassificationCode             : Sample(4),
      weightedStockPriceAverage           : WeightedStockPriceAverage,
      stockPriceAverageDayOnDayComparison : StockPriceAverageDayOnDayComparison2 ]

EncodeWeightedStockPriceAverageMessage(message) ==
    message.reserved2
        \o message.outputTime
        \o message.issueClassificationCode
        \o EncodeWeightedStockPriceAverage(message.weightedStockPriceAverage)
        \o EncodeStockPriceAverageDayOnDayComparison2(message.stockPriceAverageDayOnDayComparison)

DecodeWeightedStockPriceAverageMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET outputTime == ReadBytes(reserved2.rest, 6) IN IF ~outputTime.ok THEN Fail ELSE
    LET issueClassificationCode == ReadBytes(outputTime.rest, 4) IN IF ~issueClassificationCode.ok THEN Fail ELSE
    LET weightedStockPriceAverage == DecodeWeightedStockPriceAverage(issueClassificationCode.rest) IN IF ~weightedStockPriceAverage.ok THEN Fail ELSE
    LET stockPriceAverageDayOnDayComparison == DecodeStockPriceAverageDayOnDayComparison2(weightedStockPriceAverage.rest) IN IF ~stockPriceAverageDayOnDayComparison.ok THEN Fail ELSE
    Ok([ reserved2                           |-> reserved2.value,
         outputTime                          |-> outputTime.value,
         issueClassificationCode             |-> issueClassificationCode.value,
         weightedStockPriceAverage           |-> weightedStockPriceAverage.value,
         stockPriceAverageDayOnDayComparison |-> stockPriceAverageDayOnDayComparison.value ], stockPriceAverageDayOnDayComparison.rest)

ZeroWeightedStockPriceAverageMessage ==
    [ reserved2                           |-> [i \in 1 .. 2 |-> 0],
      outputTime                          |-> [i \in 1 .. 6 |-> 0],
      issueClassificationCode             |-> [i \in 1 .. 4 |-> 0],
      weightedStockPriceAverage           |-> ZeroWeightedStockPriceAverage,
      stockPriceAverageDayOnDayComparison |-> ZeroStockPriceAverageDayOnDayComparison2 ]

(* Weighted Stock Price Average Message at zero, then each field in turn at the values it is checked at *)
CheckedWeightedStockPriceAverageMessage ==
    { ZeroWeightedStockPriceAverageMessage }
        \cup { [ZeroWeightedStockPriceAverageMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroWeightedStockPriceAverageMessage EXCEPT !.outputTime = one] : one \in Sample(6) }
        \cup { [ZeroWeightedStockPriceAverageMessage EXCEPT !.issueClassificationCode = one] : one \in Sample(4) }
        \cup { [ZeroWeightedStockPriceAverageMessage EXCEPT !.weightedStockPriceAverage = one] : one \in CheckedWeightedStockPriceAverage }
        \cup { [ZeroWeightedStockPriceAverageMessage EXCEPT !.stockPriceAverageDayOnDayComparison = one] : one \in CheckedStockPriceAverageDayOnDayComparison2 }

(***************************************************************************)
(* Simple Stock Price Average: 16 bytes                                    *)
(***************************************************************************)

SimpleStockPriceAverage2 ==
    [ unitFlag                   : Sample(1),
      simpleStockPriceAverageC14 : Sample(14),
      sign                       : Sample(1) ]

EncodeSimpleStockPriceAverage2(message) ==
    message.unitFlag
        \o message.simpleStockPriceAverageC14
        \o message.sign

DecodeSimpleStockPriceAverage2(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET simpleStockPriceAverageC14 == ReadBytes(unitFlag.rest, 14) IN IF ~simpleStockPriceAverageC14.ok THEN Fail ELSE
    LET sign == ReadBytes(simpleStockPriceAverageC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag                   |-> unitFlag.value,
         simpleStockPriceAverageC14 |-> simpleStockPriceAverageC14.value,
         sign                       |-> sign.value ], sign.rest)

ZeroSimpleStockPriceAverage2 ==
    [ unitFlag                   |-> [i \in 1 .. 1 |-> 0],
      simpleStockPriceAverageC14 |-> [i \in 1 .. 14 |-> 0],
      sign                       |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Stock Price Average at zero, then each field in turn at the values it is checked at *)
CheckedSimpleStockPriceAverage2 ==
    { ZeroSimpleStockPriceAverage2 }
        \cup { [ZeroSimpleStockPriceAverage2 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroSimpleStockPriceAverage2 EXCEPT !.simpleStockPriceAverageC14 = one] : one \in Sample(14) }
        \cup { [ZeroSimpleStockPriceAverage2 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Price Average Day On Day Comparison: 16 bytes                     *)
(***************************************************************************)

StockPriceAverageDayOnDayComparison3 ==
    [ unitFlag              : Sample(1),
      dayOnDayComparisonC14 : Sample(14),
      sign                  : Sample(1) ]

EncodeStockPriceAverageDayOnDayComparison3(message) ==
    message.unitFlag
        \o message.dayOnDayComparisonC14
        \o message.sign

DecodeStockPriceAverageDayOnDayComparison3(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET dayOnDayComparisonC14 == ReadBytes(unitFlag.rest, 14) IN IF ~dayOnDayComparisonC14.ok THEN Fail ELSE
    LET sign == ReadBytes(dayOnDayComparisonC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag              |-> unitFlag.value,
         dayOnDayComparisonC14 |-> dayOnDayComparisonC14.value,
         sign                  |-> sign.value ], sign.rest)

ZeroStockPriceAverageDayOnDayComparison3 ==
    [ unitFlag              |-> [i \in 1 .. 1 |-> 0],
      dayOnDayComparisonC14 |-> [i \in 1 .. 14 |-> 0],
      sign                  |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Price Average Day On Day Comparison at zero, then each field in turn at the values it is checked at *)
CheckedStockPriceAverageDayOnDayComparison3 ==
    { ZeroStockPriceAverageDayOnDayComparison3 }
        \cup { [ZeroStockPriceAverageDayOnDayComparison3 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroStockPriceAverageDayOnDayComparison3 EXCEPT !.dayOnDayComparisonC14 = one] : one \in Sample(14) }
        \cup { [ZeroStockPriceAverageDayOnDayComparison3 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Stock Price Average By Industry Message: 44 bytes                *)
(***************************************************************************)

SimpleStockPriceAverageByIndustryMessage ==
    [ reserved2                           : Sample(2),
      outputTime                          : Sample(6),
      industryCode                        : Sample(4),
      simpleStockPriceAverage             : SimpleStockPriceAverage2,
      stockPriceAverageDayOnDayComparison : StockPriceAverageDayOnDayComparison3 ]

EncodeSimpleStockPriceAverageByIndustryMessage(message) ==
    message.reserved2
        \o message.outputTime
        \o message.industryCode
        \o EncodeSimpleStockPriceAverage2(message.simpleStockPriceAverage)
        \o EncodeStockPriceAverageDayOnDayComparison3(message.stockPriceAverageDayOnDayComparison)

DecodeSimpleStockPriceAverageByIndustryMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET outputTime == ReadBytes(reserved2.rest, 6) IN IF ~outputTime.ok THEN Fail ELSE
    LET industryCode == ReadBytes(outputTime.rest, 4) IN IF ~industryCode.ok THEN Fail ELSE
    LET simpleStockPriceAverage == DecodeSimpleStockPriceAverage2(industryCode.rest) IN IF ~simpleStockPriceAverage.ok THEN Fail ELSE
    LET stockPriceAverageDayOnDayComparison == DecodeStockPriceAverageDayOnDayComparison3(simpleStockPriceAverage.rest) IN IF ~stockPriceAverageDayOnDayComparison.ok THEN Fail ELSE
    Ok([ reserved2                           |-> reserved2.value,
         outputTime                          |-> outputTime.value,
         industryCode                        |-> industryCode.value,
         simpleStockPriceAverage             |-> simpleStockPriceAverage.value,
         stockPriceAverageDayOnDayComparison |-> stockPriceAverageDayOnDayComparison.value ], stockPriceAverageDayOnDayComparison.rest)

ZeroSimpleStockPriceAverageByIndustryMessage ==
    [ reserved2                           |-> [i \in 1 .. 2 |-> 0],
      outputTime                          |-> [i \in 1 .. 6 |-> 0],
      industryCode                        |-> [i \in 1 .. 4 |-> 0],
      simpleStockPriceAverage             |-> ZeroSimpleStockPriceAverage2,
      stockPriceAverageDayOnDayComparison |-> ZeroStockPriceAverageDayOnDayComparison3 ]

(* Simple Stock Price Average By Industry Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleStockPriceAverageByIndustryMessage ==
    { ZeroSimpleStockPriceAverageByIndustryMessage }
        \cup { [ZeroSimpleStockPriceAverageByIndustryMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleStockPriceAverageByIndustryMessage EXCEPT !.outputTime = one] : one \in Sample(6) }
        \cup { [ZeroSimpleStockPriceAverageByIndustryMessage EXCEPT !.industryCode = one] : one \in Sample(4) }
        \cup { [ZeroSimpleStockPriceAverageByIndustryMessage EXCEPT !.simpleStockPriceAverage = one] : one \in CheckedSimpleStockPriceAverage2 }
        \cup { [ZeroSimpleStockPriceAverageByIndustryMessage EXCEPT !.stockPriceAverageDayOnDayComparison = one] : one \in CheckedStockPriceAverageDayOnDayComparison3 }

(***************************************************************************)
(* Overall Simple Average: 32 bytes                                        *)
(***************************************************************************)

OverallSimpleAverage ==
    [ unitFlag              : Sample(1),
      simpleAverageC14      : Sample(14),
      sign                  : Sample(1),
      secondUnitFlag        : Sample(1),
      dayOnDayComparisonC14 : Sample(14),
      secondSign            : Sample(1) ]

EncodeOverallSimpleAverage(message) ==
    message.unitFlag
        \o message.simpleAverageC14
        \o message.sign
        \o message.secondUnitFlag
        \o message.dayOnDayComparisonC14
        \o message.secondSign

DecodeOverallSimpleAverage(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET simpleAverageC14 == ReadBytes(unitFlag.rest, 14) IN IF ~simpleAverageC14.ok THEN Fail ELSE
    LET sign == ReadBytes(simpleAverageC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET secondUnitFlag == ReadBytes(sign.rest, 1) IN IF ~secondUnitFlag.ok THEN Fail ELSE
    LET dayOnDayComparisonC14 == ReadBytes(secondUnitFlag.rest, 14) IN IF ~dayOnDayComparisonC14.ok THEN Fail ELSE
    LET secondSign == ReadBytes(dayOnDayComparisonC14.rest, 1) IN IF ~secondSign.ok THEN Fail ELSE
    Ok([ unitFlag              |-> unitFlag.value,
         simpleAverageC14      |-> simpleAverageC14.value,
         sign                  |-> sign.value,
         secondUnitFlag        |-> secondUnitFlag.value,
         dayOnDayComparisonC14 |-> dayOnDayComparisonC14.value,
         secondSign            |-> secondSign.value ], secondSign.rest)

ZeroOverallSimpleAverage ==
    [ unitFlag              |-> [i \in 1 .. 1 |-> 0],
      simpleAverageC14      |-> [i \in 1 .. 14 |-> 0],
      sign                  |-> [i \in 1 .. 1 |-> 0],
      secondUnitFlag        |-> [i \in 1 .. 1 |-> 0],
      dayOnDayComparisonC14 |-> [i \in 1 .. 14 |-> 0],
      secondSign            |-> [i \in 1 .. 1 |-> 0] ]

(* Overall Simple Average at zero, then each field in turn at the values it is checked at *)
CheckedOverallSimpleAverage ==
    { ZeroOverallSimpleAverage }
        \cup { [ZeroOverallSimpleAverage EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroOverallSimpleAverage EXCEPT !.simpleAverageC14 = one] : one \in Sample(14) }
        \cup { [ZeroOverallSimpleAverage EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroOverallSimpleAverage EXCEPT !.secondUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroOverallSimpleAverage EXCEPT !.dayOnDayComparisonC14 = one] : one \in Sample(14) }
        \cup { [ZeroOverallSimpleAverage EXCEPT !.secondSign = one] : one \in Sample(1) }

(***************************************************************************)
(* Overall Divergence Average: 18 bytes                                    *)
(***************************************************************************)

OverallDivergenceAverage ==
    [ divergenceAverageC8  : Sample(8),
      sign                 : Sample(1),
      dayOnDayComparisonC8 : Sample(8),
      secondSign           : Sample(1) ]

EncodeOverallDivergenceAverage(message) ==
    message.divergenceAverageC8
        \o message.sign
        \o message.dayOnDayComparisonC8
        \o message.secondSign

DecodeOverallDivergenceAverage(bytes) ==
    LET divergenceAverageC8 == ReadBytes(bytes, 8) IN IF ~divergenceAverageC8.ok THEN Fail ELSE
    LET sign == ReadBytes(divergenceAverageC8.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET dayOnDayComparisonC8 == ReadBytes(sign.rest, 8) IN IF ~dayOnDayComparisonC8.ok THEN Fail ELSE
    LET secondSign == ReadBytes(dayOnDayComparisonC8.rest, 1) IN IF ~secondSign.ok THEN Fail ELSE
    Ok([ divergenceAverageC8  |-> divergenceAverageC8.value,
         sign                 |-> sign.value,
         dayOnDayComparisonC8 |-> dayOnDayComparisonC8.value,
         secondSign           |-> secondSign.value ], secondSign.rest)

ZeroOverallDivergenceAverage ==
    [ divergenceAverageC8  |-> [i \in 1 .. 8 |-> 0],
      sign                 |-> [i \in 1 .. 1 |-> 0],
      dayOnDayComparisonC8 |-> [i \in 1 .. 8 |-> 0],
      secondSign           |-> [i \in 1 .. 1 |-> 0] ]

(* Overall Divergence Average at zero, then each field in turn at the values it is checked at *)
CheckedOverallDivergenceAverage ==
    { ZeroOverallDivergenceAverage }
        \cup { [ZeroOverallDivergenceAverage EXCEPT !.divergenceAverageC8 = one] : one \in Sample(8) }
        \cup { [ZeroOverallDivergenceAverage EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroOverallDivergenceAverage EXCEPT !.dayOnDayComparisonC8 = one] : one \in Sample(8) }
        \cup { [ZeroOverallDivergenceAverage EXCEPT !.secondSign = one] : one \in Sample(1) }

(***************************************************************************)
(* Overall Parity Average: 32 bytes                                        *)
(***************************************************************************)

OverallParityAverage ==
    [ unitFlag              : Sample(1),
      parityAverageC14      : Sample(14),
      sign                  : Sample(1),
      secondUnitFlag        : Sample(1),
      dayOnDayComparisonC14 : Sample(14),
      secondSign            : Sample(1) ]

EncodeOverallParityAverage(message) ==
    message.unitFlag
        \o message.parityAverageC14
        \o message.sign
        \o message.secondUnitFlag
        \o message.dayOnDayComparisonC14
        \o message.secondSign

DecodeOverallParityAverage(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET parityAverageC14 == ReadBytes(unitFlag.rest, 14) IN IF ~parityAverageC14.ok THEN Fail ELSE
    LET sign == ReadBytes(parityAverageC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET secondUnitFlag == ReadBytes(sign.rest, 1) IN IF ~secondUnitFlag.ok THEN Fail ELSE
    LET dayOnDayComparisonC14 == ReadBytes(secondUnitFlag.rest, 14) IN IF ~dayOnDayComparisonC14.ok THEN Fail ELSE
    LET secondSign == ReadBytes(dayOnDayComparisonC14.rest, 1) IN IF ~secondSign.ok THEN Fail ELSE
    Ok([ unitFlag              |-> unitFlag.value,
         parityAverageC14      |-> parityAverageC14.value,
         sign                  |-> sign.value,
         secondUnitFlag        |-> secondUnitFlag.value,
         dayOnDayComparisonC14 |-> dayOnDayComparisonC14.value,
         secondSign            |-> secondSign.value ], secondSign.rest)

ZeroOverallParityAverage ==
    [ unitFlag              |-> [i \in 1 .. 1 |-> 0],
      parityAverageC14      |-> [i \in 1 .. 14 |-> 0],
      sign                  |-> [i \in 1 .. 1 |-> 0],
      secondUnitFlag        |-> [i \in 1 .. 1 |-> 0],
      dayOnDayComparisonC14 |-> [i \in 1 .. 14 |-> 0],
      secondSign            |-> [i \in 1 .. 1 |-> 0] ]

(* Overall Parity Average at zero, then each field in turn at the values it is checked at *)
CheckedOverallParityAverage ==
    { ZeroOverallParityAverage }
        \cup { [ZeroOverallParityAverage EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroOverallParityAverage EXCEPT !.parityAverageC14 = one] : one \in Sample(14) }
        \cup { [ZeroOverallParityAverage EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroOverallParityAverage EXCEPT !.secondUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroOverallParityAverage EXCEPT !.dayOnDayComparisonC14 = one] : one \in Sample(14) }
        \cup { [ZeroOverallParityAverage EXCEPT !.secondSign = one] : one \in Sample(1) }

(***************************************************************************)
(* Overall Direct Yield Average: 18 bytes                                  *)
(***************************************************************************)

OverallDirectYieldAverage ==
    [ directYieldAverageC8 : Sample(8),
      sign                 : Sample(1),
      dayOnDayComparisonC8 : Sample(8),
      secondSign           : Sample(1) ]

EncodeOverallDirectYieldAverage(message) ==
    message.directYieldAverageC8
        \o message.sign
        \o message.dayOnDayComparisonC8
        \o message.secondSign

DecodeOverallDirectYieldAverage(bytes) ==
    LET directYieldAverageC8 == ReadBytes(bytes, 8) IN IF ~directYieldAverageC8.ok THEN Fail ELSE
    LET sign == ReadBytes(directYieldAverageC8.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET dayOnDayComparisonC8 == ReadBytes(sign.rest, 8) IN IF ~dayOnDayComparisonC8.ok THEN Fail ELSE
    LET secondSign == ReadBytes(dayOnDayComparisonC8.rest, 1) IN IF ~secondSign.ok THEN Fail ELSE
    Ok([ directYieldAverageC8 |-> directYieldAverageC8.value,
         sign                 |-> sign.value,
         dayOnDayComparisonC8 |-> dayOnDayComparisonC8.value,
         secondSign           |-> secondSign.value ], secondSign.rest)

ZeroOverallDirectYieldAverage ==
    [ directYieldAverageC8 |-> [i \in 1 .. 8 |-> 0],
      sign                 |-> [i \in 1 .. 1 |-> 0],
      dayOnDayComparisonC8 |-> [i \in 1 .. 8 |-> 0],
      secondSign           |-> [i \in 1 .. 1 |-> 0] ]

(* Overall Direct Yield Average at zero, then each field in turn at the values it is checked at *)
CheckedOverallDirectYieldAverage ==
    { ZeroOverallDirectYieldAverage }
        \cup { [ZeroOverallDirectYieldAverage EXCEPT !.directYieldAverageC8 = one] : one \in Sample(8) }
        \cup { [ZeroOverallDirectYieldAverage EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroOverallDirectYieldAverage EXCEPT !.dayOnDayComparisonC8 = one] : one \in Sample(8) }
        \cup { [ZeroOverallDirectYieldAverage EXCEPT !.secondSign = one] : one \in Sample(1) }

(***************************************************************************)
(* Overall: 100 bytes                                                      *)
(***************************************************************************)

Overall ==
    [ overallSimpleAverage      : OverallSimpleAverage,
      overallDivergenceAverage  : OverallDivergenceAverage,
      overallParityAverage      : OverallParityAverage,
      overallDirectYieldAverage : OverallDirectYieldAverage ]

EncodeOverall(message) ==
    EncodeOverallSimpleAverage(message.overallSimpleAverage)
        \o EncodeOverallDivergenceAverage(message.overallDivergenceAverage)
        \o EncodeOverallParityAverage(message.overallParityAverage)
        \o EncodeOverallDirectYieldAverage(message.overallDirectYieldAverage)

DecodeOverall(bytes) ==
    LET overallSimpleAverage == DecodeOverallSimpleAverage(bytes) IN IF ~overallSimpleAverage.ok THEN Fail ELSE
    LET overallDivergenceAverage == DecodeOverallDivergenceAverage(overallSimpleAverage.rest) IN IF ~overallDivergenceAverage.ok THEN Fail ELSE
    LET overallParityAverage == DecodeOverallParityAverage(overallDivergenceAverage.rest) IN IF ~overallParityAverage.ok THEN Fail ELSE
    LET overallDirectYieldAverage == DecodeOverallDirectYieldAverage(overallParityAverage.rest) IN IF ~overallDirectYieldAverage.ok THEN Fail ELSE
    Ok([ overallSimpleAverage      |-> overallSimpleAverage.value,
         overallDivergenceAverage  |-> overallDivergenceAverage.value,
         overallParityAverage      |-> overallParityAverage.value,
         overallDirectYieldAverage |-> overallDirectYieldAverage.value ], overallDirectYieldAverage.rest)

ZeroOverall ==
    [ overallSimpleAverage      |-> ZeroOverallSimpleAverage,
      overallDivergenceAverage  |-> ZeroOverallDivergenceAverage,
      overallParityAverage      |-> ZeroOverallParityAverage,
      overallDirectYieldAverage |-> ZeroOverallDirectYieldAverage ]

(* Overall at zero, then each field in turn at the values it is checked at *)
CheckedOverall ==
    { ZeroOverall }
        \cup { [ZeroOverall EXCEPT !.overallSimpleAverage = one] : one \in CheckedOverallSimpleAverage }
        \cup { [ZeroOverall EXCEPT !.overallDivergenceAverage = one] : one \in CheckedOverallDivergenceAverage }
        \cup { [ZeroOverall EXCEPT !.overallParityAverage = one] : one \in CheckedOverallParityAverage }
        \cup { [ZeroOverall EXCEPT !.overallDirectYieldAverage = one] : one \in CheckedOverallDirectYieldAverage }

(***************************************************************************)
(* Simple Average: 16 bytes                                                *)
(***************************************************************************)

SimpleAverage ==
    [ unitFlag         : Sample(1),
      simpleAverageC14 : Sample(14),
      sign             : Sample(1) ]

EncodeSimpleAverage(message) ==
    message.unitFlag
        \o message.simpleAverageC14
        \o message.sign

DecodeSimpleAverage(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET simpleAverageC14 == ReadBytes(unitFlag.rest, 14) IN IF ~simpleAverageC14.ok THEN Fail ELSE
    LET sign == ReadBytes(simpleAverageC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag         |-> unitFlag.value,
         simpleAverageC14 |-> simpleAverageC14.value,
         sign             |-> sign.value ], sign.rest)

ZeroSimpleAverage ==
    [ unitFlag         |-> [i \in 1 .. 1 |-> 0],
      simpleAverageC14 |-> [i \in 1 .. 14 |-> 0],
      sign             |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Average at zero, then each field in turn at the values it is checked at *)
CheckedSimpleAverage ==
    { ZeroSimpleAverage }
        \cup { [ZeroSimpleAverage EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroSimpleAverage EXCEPT !.simpleAverageC14 = one] : one \in Sample(14) }
        \cup { [ZeroSimpleAverage EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Divergence Average: 9 bytes                                             *)
(***************************************************************************)

DivergenceAverage ==
    [ divergenceAverageC8 : Sample(8),
      sign                : Sample(1) ]

EncodeDivergenceAverage(message) ==
    message.divergenceAverageC8
        \o message.sign

DecodeDivergenceAverage(bytes) ==
    LET divergenceAverageC8 == ReadBytes(bytes, 8) IN IF ~divergenceAverageC8.ok THEN Fail ELSE
    LET sign == ReadBytes(divergenceAverageC8.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ divergenceAverageC8 |-> divergenceAverageC8.value,
         sign                |-> sign.value ], sign.rest)

ZeroDivergenceAverage ==
    [ divergenceAverageC8 |-> [i \in 1 .. 8 |-> 0],
      sign                |-> [i \in 1 .. 1 |-> 0] ]

(* Divergence Average at zero, then each field in turn at the values it is checked at *)
CheckedDivergenceAverage ==
    { ZeroDivergenceAverage }
        \cup { [ZeroDivergenceAverage EXCEPT !.divergenceAverageC8 = one] : one \in Sample(8) }
        \cup { [ZeroDivergenceAverage EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Parity Average: 16 bytes                                                *)
(***************************************************************************)

ParityAverage ==
    [ unitFlag         : Sample(1),
      parityAverageC14 : Sample(14),
      sign             : Sample(1) ]

EncodeParityAverage(message) ==
    message.unitFlag
        \o message.parityAverageC14
        \o message.sign

DecodeParityAverage(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET parityAverageC14 == ReadBytes(unitFlag.rest, 14) IN IF ~parityAverageC14.ok THEN Fail ELSE
    LET sign == ReadBytes(parityAverageC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag         |-> unitFlag.value,
         parityAverageC14 |-> parityAverageC14.value,
         sign             |-> sign.value ], sign.rest)

ZeroParityAverage ==
    [ unitFlag         |-> [i \in 1 .. 1 |-> 0],
      parityAverageC14 |-> [i \in 1 .. 14 |-> 0],
      sign             |-> [i \in 1 .. 1 |-> 0] ]

(* Parity Average at zero, then each field in turn at the values it is checked at *)
CheckedParityAverage ==
    { ZeroParityAverage }
        \cup { [ZeroParityAverage EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroParityAverage EXCEPT !.parityAverageC14 = one] : one \in Sample(14) }
        \cup { [ZeroParityAverage EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Direct Yield Average: 9 bytes                                           *)
(***************************************************************************)

DirectYieldAverage ==
    [ directYieldAverageC8 : Sample(8),
      sign                 : Sample(1) ]

EncodeDirectYieldAverage(message) ==
    message.directYieldAverageC8
        \o message.sign

DecodeDirectYieldAverage(bytes) ==
    LET directYieldAverageC8 == ReadBytes(bytes, 8) IN IF ~directYieldAverageC8.ok THEN Fail ELSE
    LET sign == ReadBytes(directYieldAverageC8.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ directYieldAverageC8 |-> directYieldAverageC8.value,
         sign                 |-> sign.value ], sign.rest)

ZeroDirectYieldAverage ==
    [ directYieldAverageC8 |-> [i \in 1 .. 8 |-> 0],
      sign                 |-> [i \in 1 .. 1 |-> 0] ]

(* Direct Yield Average at zero, then each field in turn at the values it is checked at *)
CheckedDirectYieldAverage ==
    { ZeroDirectYieldAverage }
        \cup { [ZeroDirectYieldAverage EXCEPT !.directYieldAverageC8 = one] : one \in Sample(8) }
        \cup { [ZeroDirectYieldAverage EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Parity 100 Or Higher: 50 bytes                                          *)
(***************************************************************************)

Parity100OrHigher ==
    [ simpleAverage      : SimpleAverage,
      divergenceAverage  : DivergenceAverage,
      parityAverage      : ParityAverage,
      directYieldAverage : DirectYieldAverage ]

EncodeParity100OrHigher(message) ==
    EncodeSimpleAverage(message.simpleAverage)
        \o EncodeDivergenceAverage(message.divergenceAverage)
        \o EncodeParityAverage(message.parityAverage)
        \o EncodeDirectYieldAverage(message.directYieldAverage)

DecodeParity100OrHigher(bytes) ==
    LET simpleAverage == DecodeSimpleAverage(bytes) IN IF ~simpleAverage.ok THEN Fail ELSE
    LET divergenceAverage == DecodeDivergenceAverage(simpleAverage.rest) IN IF ~divergenceAverage.ok THEN Fail ELSE
    LET parityAverage == DecodeParityAverage(divergenceAverage.rest) IN IF ~parityAverage.ok THEN Fail ELSE
    LET directYieldAverage == DecodeDirectYieldAverage(parityAverage.rest) IN IF ~directYieldAverage.ok THEN Fail ELSE
    Ok([ simpleAverage      |-> simpleAverage.value,
         divergenceAverage  |-> divergenceAverage.value,
         parityAverage      |-> parityAverage.value,
         directYieldAverage |-> directYieldAverage.value ], directYieldAverage.rest)

ZeroParity100OrHigher ==
    [ simpleAverage      |-> ZeroSimpleAverage,
      divergenceAverage  |-> ZeroDivergenceAverage,
      parityAverage      |-> ZeroParityAverage,
      directYieldAverage |-> ZeroDirectYieldAverage ]

(* Parity 100 Or Higher at zero, then each field in turn at the values it is checked at *)
CheckedParity100OrHigher ==
    { ZeroParity100OrHigher }
        \cup { [ZeroParity100OrHigher EXCEPT !.simpleAverage = one] : one \in CheckedSimpleAverage }
        \cup { [ZeroParity100OrHigher EXCEPT !.divergenceAverage = one] : one \in CheckedDivergenceAverage }
        \cup { [ZeroParity100OrHigher EXCEPT !.parityAverage = one] : one \in CheckedParityAverage }
        \cup { [ZeroParity100OrHigher EXCEPT !.directYieldAverage = one] : one \in CheckedDirectYieldAverage }

(***************************************************************************)
(* Simple Average: 16 bytes                                                *)
(***************************************************************************)

SimpleAverage2 ==
    [ unitFlag         : Sample(1),
      simpleAverageC14 : Sample(14),
      sign             : Sample(1) ]

EncodeSimpleAverage2(message) ==
    message.unitFlag
        \o message.simpleAverageC14
        \o message.sign

DecodeSimpleAverage2(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET simpleAverageC14 == ReadBytes(unitFlag.rest, 14) IN IF ~simpleAverageC14.ok THEN Fail ELSE
    LET sign == ReadBytes(simpleAverageC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag         |-> unitFlag.value,
         simpleAverageC14 |-> simpleAverageC14.value,
         sign             |-> sign.value ], sign.rest)

ZeroSimpleAverage2 ==
    [ unitFlag         |-> [i \in 1 .. 1 |-> 0],
      simpleAverageC14 |-> [i \in 1 .. 14 |-> 0],
      sign             |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Average at zero, then each field in turn at the values it is checked at *)
CheckedSimpleAverage2 ==
    { ZeroSimpleAverage2 }
        \cup { [ZeroSimpleAverage2 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroSimpleAverage2 EXCEPT !.simpleAverageC14 = one] : one \in Sample(14) }
        \cup { [ZeroSimpleAverage2 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Divergence Average: 9 bytes                                             *)
(***************************************************************************)

DivergenceAverage2 ==
    [ divergenceAverageC8 : Sample(8),
      sign                : Sample(1) ]

EncodeDivergenceAverage2(message) ==
    message.divergenceAverageC8
        \o message.sign

DecodeDivergenceAverage2(bytes) ==
    LET divergenceAverageC8 == ReadBytes(bytes, 8) IN IF ~divergenceAverageC8.ok THEN Fail ELSE
    LET sign == ReadBytes(divergenceAverageC8.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ divergenceAverageC8 |-> divergenceAverageC8.value,
         sign                |-> sign.value ], sign.rest)

ZeroDivergenceAverage2 ==
    [ divergenceAverageC8 |-> [i \in 1 .. 8 |-> 0],
      sign                |-> [i \in 1 .. 1 |-> 0] ]

(* Divergence Average at zero, then each field in turn at the values it is checked at *)
CheckedDivergenceAverage2 ==
    { ZeroDivergenceAverage2 }
        \cup { [ZeroDivergenceAverage2 EXCEPT !.divergenceAverageC8 = one] : one \in Sample(8) }
        \cup { [ZeroDivergenceAverage2 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Parity Average: 16 bytes                                                *)
(***************************************************************************)

ParityAverage2 ==
    [ unitFlag         : Sample(1),
      parityAverageC14 : Sample(14),
      sign             : Sample(1) ]

EncodeParityAverage2(message) ==
    message.unitFlag
        \o message.parityAverageC14
        \o message.sign

DecodeParityAverage2(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET parityAverageC14 == ReadBytes(unitFlag.rest, 14) IN IF ~parityAverageC14.ok THEN Fail ELSE
    LET sign == ReadBytes(parityAverageC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag         |-> unitFlag.value,
         parityAverageC14 |-> parityAverageC14.value,
         sign             |-> sign.value ], sign.rest)

ZeroParityAverage2 ==
    [ unitFlag         |-> [i \in 1 .. 1 |-> 0],
      parityAverageC14 |-> [i \in 1 .. 14 |-> 0],
      sign             |-> [i \in 1 .. 1 |-> 0] ]

(* Parity Average at zero, then each field in turn at the values it is checked at *)
CheckedParityAverage2 ==
    { ZeroParityAverage2 }
        \cup { [ZeroParityAverage2 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroParityAverage2 EXCEPT !.parityAverageC14 = one] : one \in Sample(14) }
        \cup { [ZeroParityAverage2 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Direct Yield Average: 9 bytes                                           *)
(***************************************************************************)

DirectYieldAverage2 ==
    [ directYieldAverageC8 : Sample(8),
      sign                 : Sample(1) ]

EncodeDirectYieldAverage2(message) ==
    message.directYieldAverageC8
        \o message.sign

DecodeDirectYieldAverage2(bytes) ==
    LET directYieldAverageC8 == ReadBytes(bytes, 8) IN IF ~directYieldAverageC8.ok THEN Fail ELSE
    LET sign == ReadBytes(directYieldAverageC8.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ directYieldAverageC8 |-> directYieldAverageC8.value,
         sign                 |-> sign.value ], sign.rest)

ZeroDirectYieldAverage2 ==
    [ directYieldAverageC8 |-> [i \in 1 .. 8 |-> 0],
      sign                 |-> [i \in 1 .. 1 |-> 0] ]

(* Direct Yield Average at zero, then each field in turn at the values it is checked at *)
CheckedDirectYieldAverage2 ==
    { ZeroDirectYieldAverage2 }
        \cup { [ZeroDirectYieldAverage2 EXCEPT !.directYieldAverageC8 = one] : one \in Sample(8) }
        \cup { [ZeroDirectYieldAverage2 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Parity Less Than 100: 50 bytes                                          *)
(***************************************************************************)

ParityLessThan100 ==
    [ simpleAverage      : SimpleAverage2,
      divergenceAverage  : DivergenceAverage2,
      parityAverage      : ParityAverage2,
      directYieldAverage : DirectYieldAverage2 ]

EncodeParityLessThan100(message) ==
    EncodeSimpleAverage2(message.simpleAverage)
        \o EncodeDivergenceAverage2(message.divergenceAverage)
        \o EncodeParityAverage2(message.parityAverage)
        \o EncodeDirectYieldAverage2(message.directYieldAverage)

DecodeParityLessThan100(bytes) ==
    LET simpleAverage == DecodeSimpleAverage2(bytes) IN IF ~simpleAverage.ok THEN Fail ELSE
    LET divergenceAverage == DecodeDivergenceAverage2(simpleAverage.rest) IN IF ~divergenceAverage.ok THEN Fail ELSE
    LET parityAverage == DecodeParityAverage2(divergenceAverage.rest) IN IF ~parityAverage.ok THEN Fail ELSE
    LET directYieldAverage == DecodeDirectYieldAverage2(parityAverage.rest) IN IF ~directYieldAverage.ok THEN Fail ELSE
    Ok([ simpleAverage      |-> simpleAverage.value,
         divergenceAverage  |-> divergenceAverage.value,
         parityAverage      |-> parityAverage.value,
         directYieldAverage |-> directYieldAverage.value ], directYieldAverage.rest)

ZeroParityLessThan100 ==
    [ simpleAverage      |-> ZeroSimpleAverage2,
      divergenceAverage  |-> ZeroDivergenceAverage2,
      parityAverage      |-> ZeroParityAverage2,
      directYieldAverage |-> ZeroDirectYieldAverage2 ]

(* Parity Less Than 100 at zero, then each field in turn at the values it is checked at *)
CheckedParityLessThan100 ==
    { ZeroParityLessThan100 }
        \cup { [ZeroParityLessThan100 EXCEPT !.simpleAverage = one] : one \in CheckedSimpleAverage2 }
        \cup { [ZeroParityLessThan100 EXCEPT !.divergenceAverage = one] : one \in CheckedDivergenceAverage2 }
        \cup { [ZeroParityLessThan100 EXCEPT !.parityAverage = one] : one \in CheckedParityAverage2 }
        \cup { [ZeroParityLessThan100 EXCEPT !.directYieldAverage = one] : one \in CheckedDirectYieldAverage2 }

(***************************************************************************)
(* Japanese Yen Cb Indicator Message: 208 bytes                            *)
(***************************************************************************)

JapaneseYenCbIndicatorMessage ==
    [ reserved2         : Sample(2),
      outputTime        : Sample(6),
      overall           : Overall,
      parity100OrHigher : Parity100OrHigher,
      parityLessThan100 : ParityLessThan100 ]

EncodeJapaneseYenCbIndicatorMessage(message) ==
    message.reserved2
        \o message.outputTime
        \o EncodeOverall(message.overall)
        \o EncodeParity100OrHigher(message.parity100OrHigher)
        \o EncodeParityLessThan100(message.parityLessThan100)

DecodeJapaneseYenCbIndicatorMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET outputTime == ReadBytes(reserved2.rest, 6) IN IF ~outputTime.ok THEN Fail ELSE
    LET overall == DecodeOverall(outputTime.rest) IN IF ~overall.ok THEN Fail ELSE
    LET parity100OrHigher == DecodeParity100OrHigher(overall.rest) IN IF ~parity100OrHigher.ok THEN Fail ELSE
    LET parityLessThan100 == DecodeParityLessThan100(parity100OrHigher.rest) IN IF ~parityLessThan100.ok THEN Fail ELSE
    Ok([ reserved2         |-> reserved2.value,
         outputTime        |-> outputTime.value,
         overall           |-> overall.value,
         parity100OrHigher |-> parity100OrHigher.value,
         parityLessThan100 |-> parityLessThan100.value ], parityLessThan100.rest)

ZeroJapaneseYenCbIndicatorMessage ==
    [ reserved2         |-> [i \in 1 .. 2 |-> 0],
      outputTime        |-> [i \in 1 .. 6 |-> 0],
      overall           |-> ZeroOverall,
      parity100OrHigher |-> ZeroParity100OrHigher,
      parityLessThan100 |-> ZeroParityLessThan100 ]

(* Japanese Yen Cb Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedJapaneseYenCbIndicatorMessage ==
    { ZeroJapaneseYenCbIndicatorMessage }
        \cup { [ZeroJapaneseYenCbIndicatorMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroJapaneseYenCbIndicatorMessage EXCEPT !.outputTime = one] : one \in Sample(6) }
        \cup { [ZeroJapaneseYenCbIndicatorMessage EXCEPT !.overall = one] : one \in CheckedOverall }
        \cup { [ZeroJapaneseYenCbIndicatorMessage EXCEPT !.parity100OrHigher = one] : one \in CheckedParity100OrHigher }
        \cup { [ZeroJapaneseYenCbIndicatorMessage EXCEPT !.parityLessThan100 = one] : one \in CheckedParityLessThan100 }

(***************************************************************************)
(* Number Of Active Issues: 10 bytes                                       *)
(***************************************************************************)

NumberOfActiveIssues ==
    [ numberOfIssues : Sample(5),
      ratio          : Sample(5) ]

EncodeNumberOfActiveIssues(message) ==
    message.numberOfIssues
        \o message.ratio

DecodeNumberOfActiveIssues(bytes) ==
    LET numberOfIssues == ReadBytes(bytes, 5) IN IF ~numberOfIssues.ok THEN Fail ELSE
    LET ratio == ReadBytes(numberOfIssues.rest, 5) IN IF ~ratio.ok THEN Fail ELSE
    Ok([ numberOfIssues |-> numberOfIssues.value,
         ratio          |-> ratio.value ], ratio.rest)

ZeroNumberOfActiveIssues ==
    [ numberOfIssues |-> [i \in 1 .. 5 |-> 0],
      ratio          |-> [i \in 1 .. 5 |-> 0] ]

(* Number Of Active Issues at zero, then each field in turn at the values it is checked at *)
CheckedNumberOfActiveIssues ==
    { ZeroNumberOfActiveIssues }
        \cup { [ZeroNumberOfActiveIssues EXCEPT !.numberOfIssues = one] : one \in Sample(5) }
        \cup { [ZeroNumberOfActiveIssues EXCEPT !.ratio = one] : one \in Sample(5) }

(***************************************************************************)
(* Number Of Gainers: 10 bytes                                             *)
(***************************************************************************)

NumberOfGainers ==
    [ numberOfIssues : Sample(5),
      ratio          : Sample(5) ]

EncodeNumberOfGainers(message) ==
    message.numberOfIssues
        \o message.ratio

DecodeNumberOfGainers(bytes) ==
    LET numberOfIssues == ReadBytes(bytes, 5) IN IF ~numberOfIssues.ok THEN Fail ELSE
    LET ratio == ReadBytes(numberOfIssues.rest, 5) IN IF ~ratio.ok THEN Fail ELSE
    Ok([ numberOfIssues |-> numberOfIssues.value,
         ratio          |-> ratio.value ], ratio.rest)

ZeroNumberOfGainers ==
    [ numberOfIssues |-> [i \in 1 .. 5 |-> 0],
      ratio          |-> [i \in 1 .. 5 |-> 0] ]

(* Number Of Gainers at zero, then each field in turn at the values it is checked at *)
CheckedNumberOfGainers ==
    { ZeroNumberOfGainers }
        \cup { [ZeroNumberOfGainers EXCEPT !.numberOfIssues = one] : one \in Sample(5) }
        \cup { [ZeroNumberOfGainers EXCEPT !.ratio = one] : one \in Sample(5) }

(***************************************************************************)
(* Number Of Decliners: 10 bytes                                           *)
(***************************************************************************)

NumberOfDecliners ==
    [ numberOfIssues : Sample(5),
      ratio          : Sample(5) ]

EncodeNumberOfDecliners(message) ==
    message.numberOfIssues
        \o message.ratio

DecodeNumberOfDecliners(bytes) ==
    LET numberOfIssues == ReadBytes(bytes, 5) IN IF ~numberOfIssues.ok THEN Fail ELSE
    LET ratio == ReadBytes(numberOfIssues.rest, 5) IN IF ~ratio.ok THEN Fail ELSE
    Ok([ numberOfIssues |-> numberOfIssues.value,
         ratio          |-> ratio.value ], ratio.rest)

ZeroNumberOfDecliners ==
    [ numberOfIssues |-> [i \in 1 .. 5 |-> 0],
      ratio          |-> [i \in 1 .. 5 |-> 0] ]

(* Number Of Decliners at zero, then each field in turn at the values it is checked at *)
CheckedNumberOfDecliners ==
    { ZeroNumberOfDecliners }
        \cup { [ZeroNumberOfDecliners EXCEPT !.numberOfIssues = one] : one \in Sample(5) }
        \cup { [ZeroNumberOfDecliners EXCEPT !.ratio = one] : one \in Sample(5) }

(***************************************************************************)
(* Number Of Issues With No Change: 10 bytes                               *)
(***************************************************************************)

NumberOfIssuesWithNoChange ==
    [ numberOfIssues : Sample(5),
      ratio          : Sample(5) ]

EncodeNumberOfIssuesWithNoChange(message) ==
    message.numberOfIssues
        \o message.ratio

DecodeNumberOfIssuesWithNoChange(bytes) ==
    LET numberOfIssues == ReadBytes(bytes, 5) IN IF ~numberOfIssues.ok THEN Fail ELSE
    LET ratio == ReadBytes(numberOfIssues.rest, 5) IN IF ~ratio.ok THEN Fail ELSE
    Ok([ numberOfIssues |-> numberOfIssues.value,
         ratio          |-> ratio.value ], ratio.rest)

ZeroNumberOfIssuesWithNoChange ==
    [ numberOfIssues |-> [i \in 1 .. 5 |-> 0],
      ratio          |-> [i \in 1 .. 5 |-> 0] ]

(* Number Of Issues With No Change at zero, then each field in turn at the values it is checked at *)
CheckedNumberOfIssuesWithNoChange ==
    { ZeroNumberOfIssuesWithNoChange }
        \cup { [ZeroNumberOfIssuesWithNoChange EXCEPT !.numberOfIssues = one] : one \in Sample(5) }
        \cup { [ZeroNumberOfIssuesWithNoChange EXCEPT !.ratio = one] : one \in Sample(5) }

(***************************************************************************)
(* Number Of Issues With No Comparison: 10 bytes                           *)
(***************************************************************************)

NumberOfIssuesWithNoComparison ==
    [ numberOfIssues : Sample(5),
      ratio          : Sample(5) ]

EncodeNumberOfIssuesWithNoComparison(message) ==
    message.numberOfIssues
        \o message.ratio

DecodeNumberOfIssuesWithNoComparison(bytes) ==
    LET numberOfIssues == ReadBytes(bytes, 5) IN IF ~numberOfIssues.ok THEN Fail ELSE
    LET ratio == ReadBytes(numberOfIssues.rest, 5) IN IF ~ratio.ok THEN Fail ELSE
    Ok([ numberOfIssues |-> numberOfIssues.value,
         ratio          |-> ratio.value ], ratio.rest)

ZeroNumberOfIssuesWithNoComparison ==
    [ numberOfIssues |-> [i \in 1 .. 5 |-> 0],
      ratio          |-> [i \in 1 .. 5 |-> 0] ]

(* Number Of Issues With No Comparison at zero, then each field in turn at the values it is checked at *)
CheckedNumberOfIssuesWithNoComparison ==
    { ZeroNumberOfIssuesWithNoComparison }
        \cup { [ZeroNumberOfIssuesWithNoComparison EXCEPT !.numberOfIssues = one] : one \in Sample(5) }
        \cup { [ZeroNumberOfIssuesWithNoComparison EXCEPT !.ratio = one] : one \in Sample(5) }

(***************************************************************************)
(* Number Of Inactive Issues: 10 bytes                                     *)
(***************************************************************************)

NumberOfInactiveIssues ==
    [ numberOfIssues : Sample(5),
      ratio          : Sample(5) ]

EncodeNumberOfInactiveIssues(message) ==
    message.numberOfIssues
        \o message.ratio

DecodeNumberOfInactiveIssues(bytes) ==
    LET numberOfIssues == ReadBytes(bytes, 5) IN IF ~numberOfIssues.ok THEN Fail ELSE
    LET ratio == ReadBytes(numberOfIssues.rest, 5) IN IF ~ratio.ok THEN Fail ELSE
    Ok([ numberOfIssues |-> numberOfIssues.value,
         ratio          |-> ratio.value ], ratio.rest)

ZeroNumberOfInactiveIssues ==
    [ numberOfIssues |-> [i \in 1 .. 5 |-> 0],
      ratio          |-> [i \in 1 .. 5 |-> 0] ]

(* Number Of Inactive Issues at zero, then each field in turn at the values it is checked at *)
CheckedNumberOfInactiveIssues ==
    { ZeroNumberOfInactiveIssues }
        \cup { [ZeroNumberOfInactiveIssues EXCEPT !.numberOfIssues = one] : one \in Sample(5) }
        \cup { [ZeroNumberOfInactiveIssues EXCEPT !.ratio = one] : one \in Sample(5) }

(***************************************************************************)
(* Number Of Gainers Decliners Message: 82 bytes                           *)
(***************************************************************************)

NumberOfGainersDeclinersMessage ==
    [ reserved2                      : Sample(2),
      outputTime                     : Sample(6),
      issueClassificationCode        : Sample(4),
      numberOfListedCompanies        : Sample(5),
      numberOfListedIssues           : Sample(5),
      numberOfActiveIssues           : NumberOfActiveIssues,
      numberOfGainers                : NumberOfGainers,
      numberOfDecliners              : NumberOfDecliners,
      numberOfIssuesWithNoChange     : NumberOfIssuesWithNoChange,
      numberOfIssuesWithNoComparison : NumberOfIssuesWithNoComparison,
      numberOfInactiveIssues         : NumberOfInactiveIssues ]

EncodeNumberOfGainersDeclinersMessage(message) ==
    message.reserved2
        \o message.outputTime
        \o message.issueClassificationCode
        \o message.numberOfListedCompanies
        \o message.numberOfListedIssues
        \o EncodeNumberOfActiveIssues(message.numberOfActiveIssues)
        \o EncodeNumberOfGainers(message.numberOfGainers)
        \o EncodeNumberOfDecliners(message.numberOfDecliners)
        \o EncodeNumberOfIssuesWithNoChange(message.numberOfIssuesWithNoChange)
        \o EncodeNumberOfIssuesWithNoComparison(message.numberOfIssuesWithNoComparison)
        \o EncodeNumberOfInactiveIssues(message.numberOfInactiveIssues)

DecodeNumberOfGainersDeclinersMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET outputTime == ReadBytes(reserved2.rest, 6) IN IF ~outputTime.ok THEN Fail ELSE
    LET issueClassificationCode == ReadBytes(outputTime.rest, 4) IN IF ~issueClassificationCode.ok THEN Fail ELSE
    LET numberOfListedCompanies == ReadBytes(issueClassificationCode.rest, 5) IN IF ~numberOfListedCompanies.ok THEN Fail ELSE
    LET numberOfListedIssues == ReadBytes(numberOfListedCompanies.rest, 5) IN IF ~numberOfListedIssues.ok THEN Fail ELSE
    LET numberOfActiveIssues == DecodeNumberOfActiveIssues(numberOfListedIssues.rest) IN IF ~numberOfActiveIssues.ok THEN Fail ELSE
    LET numberOfGainers == DecodeNumberOfGainers(numberOfActiveIssues.rest) IN IF ~numberOfGainers.ok THEN Fail ELSE
    LET numberOfDecliners == DecodeNumberOfDecliners(numberOfGainers.rest) IN IF ~numberOfDecliners.ok THEN Fail ELSE
    LET numberOfIssuesWithNoChange == DecodeNumberOfIssuesWithNoChange(numberOfDecliners.rest) IN IF ~numberOfIssuesWithNoChange.ok THEN Fail ELSE
    LET numberOfIssuesWithNoComparison == DecodeNumberOfIssuesWithNoComparison(numberOfIssuesWithNoChange.rest) IN IF ~numberOfIssuesWithNoComparison.ok THEN Fail ELSE
    LET numberOfInactiveIssues == DecodeNumberOfInactiveIssues(numberOfIssuesWithNoComparison.rest) IN IF ~numberOfInactiveIssues.ok THEN Fail ELSE
    Ok([ reserved2                      |-> reserved2.value,
         outputTime                     |-> outputTime.value,
         issueClassificationCode        |-> issueClassificationCode.value,
         numberOfListedCompanies        |-> numberOfListedCompanies.value,
         numberOfListedIssues           |-> numberOfListedIssues.value,
         numberOfActiveIssues           |-> numberOfActiveIssues.value,
         numberOfGainers                |-> numberOfGainers.value,
         numberOfDecliners              |-> numberOfDecliners.value,
         numberOfIssuesWithNoChange     |-> numberOfIssuesWithNoChange.value,
         numberOfIssuesWithNoComparison |-> numberOfIssuesWithNoComparison.value,
         numberOfInactiveIssues         |-> numberOfInactiveIssues.value ], numberOfInactiveIssues.rest)

ZeroNumberOfGainersDeclinersMessage ==
    [ reserved2                      |-> [i \in 1 .. 2 |-> 0],
      outputTime                     |-> [i \in 1 .. 6 |-> 0],
      issueClassificationCode        |-> [i \in 1 .. 4 |-> 0],
      numberOfListedCompanies        |-> [i \in 1 .. 5 |-> 0],
      numberOfListedIssues           |-> [i \in 1 .. 5 |-> 0],
      numberOfActiveIssues           |-> ZeroNumberOfActiveIssues,
      numberOfGainers                |-> ZeroNumberOfGainers,
      numberOfDecliners              |-> ZeroNumberOfDecliners,
      numberOfIssuesWithNoChange     |-> ZeroNumberOfIssuesWithNoChange,
      numberOfIssuesWithNoComparison |-> ZeroNumberOfIssuesWithNoComparison,
      numberOfInactiveIssues         |-> ZeroNumberOfInactiveIssues ]

(* Number Of Gainers Decliners Message at zero, then each field in turn at the values it is checked at *)
CheckedNumberOfGainersDeclinersMessage ==
    { ZeroNumberOfGainersDeclinersMessage }
        \cup { [ZeroNumberOfGainersDeclinersMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroNumberOfGainersDeclinersMessage EXCEPT !.outputTime = one] : one \in Sample(6) }
        \cup { [ZeroNumberOfGainersDeclinersMessage EXCEPT !.issueClassificationCode = one] : one \in Sample(4) }
        \cup { [ZeroNumberOfGainersDeclinersMessage EXCEPT !.numberOfListedCompanies = one] : one \in Sample(5) }
        \cup { [ZeroNumberOfGainersDeclinersMessage EXCEPT !.numberOfListedIssues = one] : one \in Sample(5) }
        \cup { [ZeroNumberOfGainersDeclinersMessage EXCEPT !.numberOfActiveIssues = one] : one \in CheckedNumberOfActiveIssues }
        \cup { [ZeroNumberOfGainersDeclinersMessage EXCEPT !.numberOfGainers = one] : one \in CheckedNumberOfGainers }
        \cup { [ZeroNumberOfGainersDeclinersMessage EXCEPT !.numberOfDecliners = one] : one \in CheckedNumberOfDecliners }
        \cup { [ZeroNumberOfGainersDeclinersMessage EXCEPT !.numberOfIssuesWithNoChange = one] : one \in CheckedNumberOfIssuesWithNoChange }
        \cup { [ZeroNumberOfGainersDeclinersMessage EXCEPT !.numberOfIssuesWithNoComparison = one] : one \in CheckedNumberOfIssuesWithNoComparison }
        \cup { [ZeroNumberOfGainersDeclinersMessage EXCEPT !.numberOfInactiveIssues = one] : one \in CheckedNumberOfInactiveIssues }

(***************************************************************************)
(* Estimated Total Trading Volume: 15 bytes                                *)
(***************************************************************************)

EstimatedTotalTradingVolume ==
    [ tradingVolumeTurnoverUnitFlag  : Sample(1),
      estimatedTotalTradingVolumeC14 : Sample(14) ]

EncodeEstimatedTotalTradingVolume(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.estimatedTotalTradingVolumeC14

DecodeEstimatedTotalTradingVolume(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET estimatedTotalTradingVolumeC14 == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~estimatedTotalTradingVolumeC14.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag  |-> tradingVolumeTurnoverUnitFlag.value,
         estimatedTotalTradingVolumeC14 |-> estimatedTotalTradingVolumeC14.value ], estimatedTotalTradingVolumeC14.rest)

ZeroEstimatedTotalTradingVolume ==
    [ tradingVolumeTurnoverUnitFlag  |-> [i \in 1 .. 1 |-> 0],
      estimatedTotalTradingVolumeC14 |-> [i \in 1 .. 14 |-> 0] ]

(* Estimated Total Trading Volume at zero, then each field in turn at the values it is checked at *)
CheckedEstimatedTotalTradingVolume ==
    { ZeroEstimatedTotalTradingVolume }
        \cup { [ZeroEstimatedTotalTradingVolume EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroEstimatedTotalTradingVolume EXCEPT !.estimatedTotalTradingVolumeC14 = one] : one \in Sample(14) }

(***************************************************************************)
(* Estimated Total Trading Volume Message: 29 bytes                        *)
(***************************************************************************)

EstimatedTotalTradingVolumeMessage ==
    [ reserved2                   : Sample(2),
      outputTime                  : Sample(6),
      issueClassificationCode     : Sample(4),
      otherClassificationCode     : Sample(2),
      estimatedTotalTradingVolume : EstimatedTotalTradingVolume ]

EncodeEstimatedTotalTradingVolumeMessage(message) ==
    message.reserved2
        \o message.outputTime
        \o message.issueClassificationCode
        \o message.otherClassificationCode
        \o EncodeEstimatedTotalTradingVolume(message.estimatedTotalTradingVolume)

DecodeEstimatedTotalTradingVolumeMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET outputTime == ReadBytes(reserved2.rest, 6) IN IF ~outputTime.ok THEN Fail ELSE
    LET issueClassificationCode == ReadBytes(outputTime.rest, 4) IN IF ~issueClassificationCode.ok THEN Fail ELSE
    LET otherClassificationCode == ReadBytes(issueClassificationCode.rest, 2) IN IF ~otherClassificationCode.ok THEN Fail ELSE
    LET estimatedTotalTradingVolume == DecodeEstimatedTotalTradingVolume(otherClassificationCode.rest) IN IF ~estimatedTotalTradingVolume.ok THEN Fail ELSE
    Ok([ reserved2                   |-> reserved2.value,
         outputTime                  |-> outputTime.value,
         issueClassificationCode     |-> issueClassificationCode.value,
         otherClassificationCode     |-> otherClassificationCode.value,
         estimatedTotalTradingVolume |-> estimatedTotalTradingVolume.value ], estimatedTotalTradingVolume.rest)

ZeroEstimatedTotalTradingVolumeMessage ==
    [ reserved2                   |-> [i \in 1 .. 2 |-> 0],
      outputTime                  |-> [i \in 1 .. 6 |-> 0],
      issueClassificationCode     |-> [i \in 1 .. 4 |-> 0],
      otherClassificationCode     |-> [i \in 1 .. 2 |-> 0],
      estimatedTotalTradingVolume |-> ZeroEstimatedTotalTradingVolume ]

(* Estimated Total Trading Volume Message at zero, then each field in turn at the values it is checked at *)
CheckedEstimatedTotalTradingVolumeMessage ==
    { ZeroEstimatedTotalTradingVolumeMessage }
        \cup { [ZeroEstimatedTotalTradingVolumeMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroEstimatedTotalTradingVolumeMessage EXCEPT !.outputTime = one] : one \in Sample(6) }
        \cup { [ZeroEstimatedTotalTradingVolumeMessage EXCEPT !.issueClassificationCode = one] : one \in Sample(4) }
        \cup { [ZeroEstimatedTotalTradingVolumeMessage EXCEPT !.otherClassificationCode = one] : one \in Sample(2) }
        \cup { [ZeroEstimatedTotalTradingVolumeMessage EXCEPT !.estimatedTotalTradingVolume = one] : one \in CheckedEstimatedTotalTradingVolume }

(***************************************************************************)
(* Estimated Total Turnover: 16 bytes                                      *)
(***************************************************************************)

EstimatedTotalTurnover ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      estimatedTotalTurnoverC14     : Sample(14),
      reserved1                     : Sample(1) ]

EncodeEstimatedTotalTurnover(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.estimatedTotalTurnoverC14
        \o message.reserved1

DecodeEstimatedTotalTurnover(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET estimatedTotalTurnoverC14 == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~estimatedTotalTurnoverC14.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(estimatedTotalTurnoverC14.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         estimatedTotalTurnoverC14     |-> estimatedTotalTurnoverC14.value,
         reserved1                     |-> reserved1.value ], reserved1.rest)

ZeroEstimatedTotalTurnover ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      estimatedTotalTurnoverC14     |-> [i \in 1 .. 14 |-> 0],
      reserved1                     |-> [i \in 1 .. 1 |-> 0] ]

(* Estimated Total Turnover at zero, then each field in turn at the values it is checked at *)
CheckedEstimatedTotalTurnover ==
    { ZeroEstimatedTotalTurnover }
        \cup { [ZeroEstimatedTotalTurnover EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroEstimatedTotalTurnover EXCEPT !.estimatedTotalTurnoverC14 = one] : one \in Sample(14) }
        \cup { [ZeroEstimatedTotalTurnover EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Estimated Total Turnover Message: 30 bytes                              *)
(***************************************************************************)

EstimatedTotalTurnoverMessage ==
    [ reserved2               : Sample(2),
      outputTime              : Sample(6),
      issueClassificationCode : Sample(4),
      otherClassificationFlag : Sample(2),
      estimatedTotalTurnover  : EstimatedTotalTurnover ]

EncodeEstimatedTotalTurnoverMessage(message) ==
    message.reserved2
        \o message.outputTime
        \o message.issueClassificationCode
        \o message.otherClassificationFlag
        \o EncodeEstimatedTotalTurnover(message.estimatedTotalTurnover)

DecodeEstimatedTotalTurnoverMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET outputTime == ReadBytes(reserved2.rest, 6) IN IF ~outputTime.ok THEN Fail ELSE
    LET issueClassificationCode == ReadBytes(outputTime.rest, 4) IN IF ~issueClassificationCode.ok THEN Fail ELSE
    LET otherClassificationFlag == ReadBytes(issueClassificationCode.rest, 2) IN IF ~otherClassificationFlag.ok THEN Fail ELSE
    LET estimatedTotalTurnover == DecodeEstimatedTotalTurnover(otherClassificationFlag.rest) IN IF ~estimatedTotalTurnover.ok THEN Fail ELSE
    Ok([ reserved2               |-> reserved2.value,
         outputTime              |-> outputTime.value,
         issueClassificationCode |-> issueClassificationCode.value,
         otherClassificationFlag |-> otherClassificationFlag.value,
         estimatedTotalTurnover  |-> estimatedTotalTurnover.value ], estimatedTotalTurnover.rest)

ZeroEstimatedTotalTurnoverMessage ==
    [ reserved2               |-> [i \in 1 .. 2 |-> 0],
      outputTime              |-> [i \in 1 .. 6 |-> 0],
      issueClassificationCode |-> [i \in 1 .. 4 |-> 0],
      otherClassificationFlag |-> [i \in 1 .. 2 |-> 0],
      estimatedTotalTurnover  |-> ZeroEstimatedTotalTurnover ]

(* Estimated Total Turnover Message at zero, then each field in turn at the values it is checked at *)
CheckedEstimatedTotalTurnoverMessage ==
    { ZeroEstimatedTotalTurnoverMessage }
        \cup { [ZeroEstimatedTotalTurnoverMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroEstimatedTotalTurnoverMessage EXCEPT !.outputTime = one] : one \in Sample(6) }
        \cup { [ZeroEstimatedTotalTurnoverMessage EXCEPT !.issueClassificationCode = one] : one \in Sample(4) }
        \cup { [ZeroEstimatedTotalTurnoverMessage EXCEPT !.otherClassificationFlag = one] : one \in Sample(2) }
        \cup { [ZeroEstimatedTotalTurnoverMessage EXCEPT !.estimatedTotalTurnover = one] : one \in CheckedEstimatedTotalTurnover }

(***************************************************************************)
(* Vwap By Market: 33 bytes                                                *)
(***************************************************************************)

VwapByMarket ==
    [ unitFlag              : Sample(1),
      vwapByMarketC14       : Sample(14),
      sign                  : Sample(1),
      reserved1             : Sample(1),
      secondUnitFlag        : Sample(1),
      dayOnDayComparisonC14 : Sample(14),
      secondSign            : Sample(1) ]

EncodeVwapByMarket(message) ==
    message.unitFlag
        \o message.vwapByMarketC14
        \o message.sign
        \o message.reserved1
        \o message.secondUnitFlag
        \o message.dayOnDayComparisonC14
        \o message.secondSign

DecodeVwapByMarket(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET vwapByMarketC14 == ReadBytes(unitFlag.rest, 14) IN IF ~vwapByMarketC14.ok THEN Fail ELSE
    LET sign == ReadBytes(vwapByMarketC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(sign.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET secondUnitFlag == ReadBytes(reserved1.rest, 1) IN IF ~secondUnitFlag.ok THEN Fail ELSE
    LET dayOnDayComparisonC14 == ReadBytes(secondUnitFlag.rest, 14) IN IF ~dayOnDayComparisonC14.ok THEN Fail ELSE
    LET secondSign == ReadBytes(dayOnDayComparisonC14.rest, 1) IN IF ~secondSign.ok THEN Fail ELSE
    Ok([ unitFlag              |-> unitFlag.value,
         vwapByMarketC14       |-> vwapByMarketC14.value,
         sign                  |-> sign.value,
         reserved1             |-> reserved1.value,
         secondUnitFlag        |-> secondUnitFlag.value,
         dayOnDayComparisonC14 |-> dayOnDayComparisonC14.value,
         secondSign            |-> secondSign.value ], secondSign.rest)

ZeroVwapByMarket ==
    [ unitFlag              |-> [i \in 1 .. 1 |-> 0],
      vwapByMarketC14       |-> [i \in 1 .. 14 |-> 0],
      sign                  |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      secondUnitFlag        |-> [i \in 1 .. 1 |-> 0],
      dayOnDayComparisonC14 |-> [i \in 1 .. 14 |-> 0],
      secondSign            |-> [i \in 1 .. 1 |-> 0] ]

(* Vwap By Market at zero, then each field in turn at the values it is checked at *)
CheckedVwapByMarket ==
    { ZeroVwapByMarket }
        \cup { [ZeroVwapByMarket EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroVwapByMarket EXCEPT !.vwapByMarketC14 = one] : one \in Sample(14) }
        \cup { [ZeroVwapByMarket EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroVwapByMarket EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroVwapByMarket EXCEPT !.secondUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroVwapByMarket EXCEPT !.dayOnDayComparisonC14 = one] : one \in Sample(14) }
        \cup { [ZeroVwapByMarket EXCEPT !.secondSign = one] : one \in Sample(1) }

(***************************************************************************)
(* Vwap By Market Message: 45 bytes                                        *)
(***************************************************************************)

VwapByMarketMessage ==
    [ reserved2               : Sample(2),
      outputTime              : Sample(6),
      issueClassificationCode : Sample(4),
      vwapByMarket            : VwapByMarket ]

EncodeVwapByMarketMessage(message) ==
    message.reserved2
        \o message.outputTime
        \o message.issueClassificationCode
        \o EncodeVwapByMarket(message.vwapByMarket)

DecodeVwapByMarketMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET outputTime == ReadBytes(reserved2.rest, 6) IN IF ~outputTime.ok THEN Fail ELSE
    LET issueClassificationCode == ReadBytes(outputTime.rest, 4) IN IF ~issueClassificationCode.ok THEN Fail ELSE
    LET vwapByMarket == DecodeVwapByMarket(issueClassificationCode.rest) IN IF ~vwapByMarket.ok THEN Fail ELSE
    Ok([ reserved2               |-> reserved2.value,
         outputTime              |-> outputTime.value,
         issueClassificationCode |-> issueClassificationCode.value,
         vwapByMarket            |-> vwapByMarket.value ], vwapByMarket.rest)

ZeroVwapByMarketMessage ==
    [ reserved2               |-> [i \in 1 .. 2 |-> 0],
      outputTime              |-> [i \in 1 .. 6 |-> 0],
      issueClassificationCode |-> [i \in 1 .. 4 |-> 0],
      vwapByMarket            |-> ZeroVwapByMarket ]

(* Vwap By Market Message at zero, then each field in turn at the values it is checked at *)
CheckedVwapByMarketMessage ==
    { ZeroVwapByMarketMessage }
        \cup { [ZeroVwapByMarketMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroVwapByMarketMessage EXCEPT !.outputTime = one] : one \in Sample(6) }
        \cup { [ZeroVwapByMarketMessage EXCEPT !.issueClassificationCode = one] : one \in Sample(4) }
        \cup { [ZeroVwapByMarketMessage EXCEPT !.vwapByMarket = one] : one \in CheckedVwapByMarket }

(***************************************************************************)
(* Top Rank By Trading Volume: 30 bytes                                    *)
(***************************************************************************)

TopRankByTradingVolume ==
    [ rank                          : Sample(2),
      rankedIssueCode               : Sample(12),
      reserved1                     : Sample(1),
      tradingVolumeTurnoverUnitFlag : Sample(1),
      tradingVolumeC14              : Sample(14) ]

EncodeTopRankByTradingVolume(message) ==
    message.rank
        \o message.rankedIssueCode
        \o message.reserved1
        \o message.tradingVolumeTurnoverUnitFlag
        \o message.tradingVolumeC14

DecodeTopRankByTradingVolume(bytes) ==
    LET rank == ReadBytes(bytes, 2) IN IF ~rank.ok THEN Fail ELSE
    LET rankedIssueCode == ReadBytes(rank.rest, 12) IN IF ~rankedIssueCode.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(rankedIssueCode.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(reserved1.rest, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET tradingVolumeC14 == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~tradingVolumeC14.ok THEN Fail ELSE
    Ok([ rank                          |-> rank.value,
         rankedIssueCode               |-> rankedIssueCode.value,
         reserved1                     |-> reserved1.value,
         tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         tradingVolumeC14              |-> tradingVolumeC14.value ], tradingVolumeC14.rest)

ZeroTopRankByTradingVolume ==
    [ rank                          |-> [i \in 1 .. 2 |-> 0],
      rankedIssueCode               |-> [i \in 1 .. 12 |-> 0],
      reserved1                     |-> [i \in 1 .. 1 |-> 0],
      tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      tradingVolumeC14              |-> [i \in 1 .. 14 |-> 0] ]

(* Top Rank By Trading Volume at zero, then each field in turn at the values it is checked at *)
CheckedTopRankByTradingVolume ==
    { ZeroTopRankByTradingVolume }
        \cup { [ZeroTopRankByTradingVolume EXCEPT !.rank = one] : one \in Sample(2) }
        \cup { [ZeroTopRankByTradingVolume EXCEPT !.rankedIssueCode = one] : one \in Sample(12) }
        \cup { [ZeroTopRankByTradingVolume EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTopRankByTradingVolume EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTopRankByTradingVolume EXCEPT !.tradingVolumeC14 = one] : one \in Sample(14) }

(* A run of Top Rank By Trading Volume, written one after another *)
RECURSIVE EncodeTopRankByTradingVolumeList(_)
EncodeTopRankByTradingVolumeList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTopRankByTradingVolume(Head(messages)) \o EncodeTopRankByTradingVolumeList(Tail(messages))

(* As many Top Rank By Trading Volume as the field that counts them says *)
RECURSIVE ReadTopRankByTradingVolumeList(_, _)
ReadTopRankByTradingVolumeList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTopRankByTradingVolume(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTopRankByTradingVolumeList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Top Rank By Trading Volume of each kind, for the lists that carry them *)
OneTopRankByTradingVolume == { ZeroTopRankByTradingVolume }

(* The 30 slots a run of Top Rank By Trading Volume is written as, whatever the field beside it says are in use *)
SlotsTopRankByTradingVolume == { [i \in 1 .. 30 |-> one] : one \in OneTopRankByTradingVolume }

(***************************************************************************)
(* Ranking By Trading Volume Message                                       *)
(***************************************************************************)

RankingByTradingVolumeMessage ==
    [ reserved2               : Sample(2),
      outputTime              : Sample(6),
      issueClassificationCode : Sample(4),
      topRankByTradingVolume  : SlotsTopRankByTradingVolume ]

EncodeRankingByTradingVolumeMessage(message) ==
    message.reserved2
        \o message.outputTime
        \o message.issueClassificationCode
        \o EncodeTopRankByTradingVolumeList(message.topRankByTradingVolume)

DecodeRankingByTradingVolumeMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET outputTime == ReadBytes(reserved2.rest, 6) IN IF ~outputTime.ok THEN Fail ELSE
    LET issueClassificationCode == ReadBytes(outputTime.rest, 4) IN IF ~issueClassificationCode.ok THEN Fail ELSE
    LET topRankByTradingVolume == ReadTopRankByTradingVolumeList(issueClassificationCode.rest, 30) IN IF ~topRankByTradingVolume.ok THEN Fail ELSE
    Ok([ reserved2               |-> reserved2.value,
         outputTime              |-> outputTime.value,
         issueClassificationCode |-> issueClassificationCode.value,
         topRankByTradingVolume  |-> topRankByTradingVolume.value ], topRankByTradingVolume.rest)

ZeroRankingByTradingVolumeMessage ==
    [ reserved2               |-> [i \in 1 .. 2 |-> 0],
      outputTime              |-> [i \in 1 .. 6 |-> 0],
      issueClassificationCode |-> [i \in 1 .. 4 |-> 0],
      topRankByTradingVolume  |-> [i \in 1 .. 30 |-> ZeroTopRankByTradingVolume] ]

(* Ranking By Trading Volume Message at zero, then each field in turn at the values it is checked at *)
CheckedRankingByTradingVolumeMessage ==
    { ZeroRankingByTradingVolumeMessage }
        \cup { [ZeroRankingByTradingVolumeMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroRankingByTradingVolumeMessage EXCEPT !.outputTime = one] : one \in Sample(6) }
        \cup { [ZeroRankingByTradingVolumeMessage EXCEPT !.issueClassificationCode = one] : one \in Sample(4) }
        \cup { [ZeroRankingByTradingVolumeMessage EXCEPT !.topRankByTradingVolume = one] : one \in SlotsTopRankByTradingVolume }

(***************************************************************************)
(* Top Rank By Turnover: 30 bytes                                          *)
(***************************************************************************)

TopRankByTurnover ==
    [ rank                          : Sample(2),
      rankedIssueCode               : Sample(12),
      reserved1                     : Sample(1),
      tradingVolumeTurnoverUnitFlag : Sample(1),
      turnoverC14                   : Sample(14) ]

EncodeTopRankByTurnover(message) ==
    message.rank
        \o message.rankedIssueCode
        \o message.reserved1
        \o message.tradingVolumeTurnoverUnitFlag
        \o message.turnoverC14

DecodeTopRankByTurnover(bytes) ==
    LET rank == ReadBytes(bytes, 2) IN IF ~rank.ok THEN Fail ELSE
    LET rankedIssueCode == ReadBytes(rank.rest, 12) IN IF ~rankedIssueCode.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(rankedIssueCode.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(reserved1.rest, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET turnoverC14 == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~turnoverC14.ok THEN Fail ELSE
    Ok([ rank                          |-> rank.value,
         rankedIssueCode               |-> rankedIssueCode.value,
         reserved1                     |-> reserved1.value,
         tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         turnoverC14                   |-> turnoverC14.value ], turnoverC14.rest)

ZeroTopRankByTurnover ==
    [ rank                          |-> [i \in 1 .. 2 |-> 0],
      rankedIssueCode               |-> [i \in 1 .. 12 |-> 0],
      reserved1                     |-> [i \in 1 .. 1 |-> 0],
      tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      turnoverC14                   |-> [i \in 1 .. 14 |-> 0] ]

(* Top Rank By Turnover at zero, then each field in turn at the values it is checked at *)
CheckedTopRankByTurnover ==
    { ZeroTopRankByTurnover }
        \cup { [ZeroTopRankByTurnover EXCEPT !.rank = one] : one \in Sample(2) }
        \cup { [ZeroTopRankByTurnover EXCEPT !.rankedIssueCode = one] : one \in Sample(12) }
        \cup { [ZeroTopRankByTurnover EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTopRankByTurnover EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTopRankByTurnover EXCEPT !.turnoverC14 = one] : one \in Sample(14) }

(* A run of Top Rank By Turnover, written one after another *)
RECURSIVE EncodeTopRankByTurnoverList(_)
EncodeTopRankByTurnoverList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTopRankByTurnover(Head(messages)) \o EncodeTopRankByTurnoverList(Tail(messages))

(* As many Top Rank By Turnover as the field that counts them says *)
RECURSIVE ReadTopRankByTurnoverList(_, _)
ReadTopRankByTurnoverList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTopRankByTurnover(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTopRankByTurnoverList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Top Rank By Turnover of each kind, for the lists that carry them *)
OneTopRankByTurnover == { ZeroTopRankByTurnover }

(* The 30 slots a run of Top Rank By Turnover is written as, whatever the field beside it says are in use *)
SlotsTopRankByTurnover == { [i \in 1 .. 30 |-> one] : one \in OneTopRankByTurnover }

(***************************************************************************)
(* Ranking By Turnover Message                                             *)
(***************************************************************************)

RankingByTurnoverMessage ==
    [ reserved2               : Sample(2),
      outputTime              : Sample(6),
      issueClassificationCode : Sample(4),
      topRankByTurnover       : SlotsTopRankByTurnover ]

EncodeRankingByTurnoverMessage(message) ==
    message.reserved2
        \o message.outputTime
        \o message.issueClassificationCode
        \o EncodeTopRankByTurnoverList(message.topRankByTurnover)

DecodeRankingByTurnoverMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET outputTime == ReadBytes(reserved2.rest, 6) IN IF ~outputTime.ok THEN Fail ELSE
    LET issueClassificationCode == ReadBytes(outputTime.rest, 4) IN IF ~issueClassificationCode.ok THEN Fail ELSE
    LET topRankByTurnover == ReadTopRankByTurnoverList(issueClassificationCode.rest, 30) IN IF ~topRankByTurnover.ok THEN Fail ELSE
    Ok([ reserved2               |-> reserved2.value,
         outputTime              |-> outputTime.value,
         issueClassificationCode |-> issueClassificationCode.value,
         topRankByTurnover       |-> topRankByTurnover.value ], topRankByTurnover.rest)

ZeroRankingByTurnoverMessage ==
    [ reserved2               |-> [i \in 1 .. 2 |-> 0],
      outputTime              |-> [i \in 1 .. 6 |-> 0],
      issueClassificationCode |-> [i \in 1 .. 4 |-> 0],
      topRankByTurnover       |-> [i \in 1 .. 30 |-> ZeroTopRankByTurnover] ]

(* Ranking By Turnover Message at zero, then each field in turn at the values it is checked at *)
CheckedRankingByTurnoverMessage ==
    { ZeroRankingByTurnoverMessage }
        \cup { [ZeroRankingByTurnoverMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroRankingByTurnoverMessage EXCEPT !.outputTime = one] : one \in Sample(6) }
        \cup { [ZeroRankingByTurnoverMessage EXCEPT !.issueClassificationCode = one] : one \in Sample(4) }
        \cup { [ZeroRankingByTurnoverMessage EXCEPT !.topRankByTurnover = one] : one \in SlotsTopRankByTurnover }

(***************************************************************************)
(* Top Rank By Net Change: 48 bytes                                        *)
(***************************************************************************)

TopRankByNetChange ==
    [ rank            : Sample(2),
      rankedIssueCode : Sample(12),
      stateSign       : Sample(1),
      unitFlag        : Sample(1),
      currentPriceC14 : Sample(14),
      sign            : Sample(1),
      comparisonType  : Sample(1),
      secondUnitFlag  : Sample(1),
      netChange       : Sample(14),
      secondSign      : Sample(1) ]

EncodeTopRankByNetChange(message) ==
    message.rank
        \o message.rankedIssueCode
        \o message.stateSign
        \o message.unitFlag
        \o message.currentPriceC14
        \o message.sign
        \o message.comparisonType
        \o message.secondUnitFlag
        \o message.netChange
        \o message.secondSign

DecodeTopRankByNetChange(bytes) ==
    LET rank == ReadBytes(bytes, 2) IN IF ~rank.ok THEN Fail ELSE
    LET rankedIssueCode == ReadBytes(rank.rest, 12) IN IF ~rankedIssueCode.ok THEN Fail ELSE
    LET stateSign == ReadBytes(rankedIssueCode.rest, 1) IN IF ~stateSign.ok THEN Fail ELSE
    LET unitFlag == ReadBytes(stateSign.rest, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET currentPriceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~currentPriceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(currentPriceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET comparisonType == ReadBytes(sign.rest, 1) IN IF ~comparisonType.ok THEN Fail ELSE
    LET secondUnitFlag == ReadBytes(comparisonType.rest, 1) IN IF ~secondUnitFlag.ok THEN Fail ELSE
    LET netChange == ReadBytes(secondUnitFlag.rest, 14) IN IF ~netChange.ok THEN Fail ELSE
    LET secondSign == ReadBytes(netChange.rest, 1) IN IF ~secondSign.ok THEN Fail ELSE
    Ok([ rank            |-> rank.value,
         rankedIssueCode |-> rankedIssueCode.value,
         stateSign       |-> stateSign.value,
         unitFlag        |-> unitFlag.value,
         currentPriceC14 |-> currentPriceC14.value,
         sign            |-> sign.value,
         comparisonType  |-> comparisonType.value,
         secondUnitFlag  |-> secondUnitFlag.value,
         netChange       |-> netChange.value,
         secondSign      |-> secondSign.value ], secondSign.rest)

ZeroTopRankByNetChange ==
    [ rank            |-> [i \in 1 .. 2 |-> 0],
      rankedIssueCode |-> [i \in 1 .. 12 |-> 0],
      stateSign       |-> [i \in 1 .. 1 |-> 0],
      unitFlag        |-> [i \in 1 .. 1 |-> 0],
      currentPriceC14 |-> [i \in 1 .. 14 |-> 0],
      sign            |-> [i \in 1 .. 1 |-> 0],
      comparisonType  |-> [i \in 1 .. 1 |-> 0],
      secondUnitFlag  |-> [i \in 1 .. 1 |-> 0],
      netChange       |-> [i \in 1 .. 14 |-> 0],
      secondSign      |-> [i \in 1 .. 1 |-> 0] ]

(* Top Rank By Net Change at zero, then each field in turn at the values it is checked at *)
CheckedTopRankByNetChange ==
    { ZeroTopRankByNetChange }
        \cup { [ZeroTopRankByNetChange EXCEPT !.rank = one] : one \in Sample(2) }
        \cup { [ZeroTopRankByNetChange EXCEPT !.rankedIssueCode = one] : one \in Sample(12) }
        \cup { [ZeroTopRankByNetChange EXCEPT !.stateSign = one] : one \in Sample(1) }
        \cup { [ZeroTopRankByNetChange EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTopRankByNetChange EXCEPT !.currentPriceC14 = one] : one \in Sample(14) }
        \cup { [ZeroTopRankByNetChange EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroTopRankByNetChange EXCEPT !.comparisonType = one] : one \in Sample(1) }
        \cup { [ZeroTopRankByNetChange EXCEPT !.secondUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTopRankByNetChange EXCEPT !.netChange = one] : one \in Sample(14) }
        \cup { [ZeroTopRankByNetChange EXCEPT !.secondSign = one] : one \in Sample(1) }

(* A run of Top Rank By Net Change, written one after another *)
RECURSIVE EncodeTopRankByNetChangeList(_)
EncodeTopRankByNetChangeList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTopRankByNetChange(Head(messages)) \o EncodeTopRankByNetChangeList(Tail(messages))

(* As many Top Rank By Net Change as the field that counts them says *)
RECURSIVE ReadTopRankByNetChangeList(_, _)
ReadTopRankByNetChangeList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTopRankByNetChange(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTopRankByNetChangeList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Top Rank By Net Change of each kind, for the lists that carry them *)
OneTopRankByNetChange == { ZeroTopRankByNetChange }

(* The 30 slots a run of Top Rank By Net Change is written as, whatever the field beside it says are in use *)
SlotsTopRankByNetChange == { [i \in 1 .. 30 |-> one] : one \in OneTopRankByNetChange }

(***************************************************************************)
(* Ranking By Net Change Message                                           *)
(***************************************************************************)

RankingByNetChangeMessage ==
    [ reserved2               : Sample(2),
      outputTime              : Sample(6),
      issueClassificationCode : Sample(4),
      netChangeDistinction    : Sample(1),
      topRankByNetChange      : SlotsTopRankByNetChange ]

EncodeRankingByNetChangeMessage(message) ==
    message.reserved2
        \o message.outputTime
        \o message.issueClassificationCode
        \o message.netChangeDistinction
        \o EncodeTopRankByNetChangeList(message.topRankByNetChange)

DecodeRankingByNetChangeMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET outputTime == ReadBytes(reserved2.rest, 6) IN IF ~outputTime.ok THEN Fail ELSE
    LET issueClassificationCode == ReadBytes(outputTime.rest, 4) IN IF ~issueClassificationCode.ok THEN Fail ELSE
    LET netChangeDistinction == ReadBytes(issueClassificationCode.rest, 1) IN IF ~netChangeDistinction.ok THEN Fail ELSE
    LET topRankByNetChange == ReadTopRankByNetChangeList(netChangeDistinction.rest, 30) IN IF ~topRankByNetChange.ok THEN Fail ELSE
    Ok([ reserved2               |-> reserved2.value,
         outputTime              |-> outputTime.value,
         issueClassificationCode |-> issueClassificationCode.value,
         netChangeDistinction    |-> netChangeDistinction.value,
         topRankByNetChange      |-> topRankByNetChange.value ], topRankByNetChange.rest)

ZeroRankingByNetChangeMessage ==
    [ reserved2               |-> [i \in 1 .. 2 |-> 0],
      outputTime              |-> [i \in 1 .. 6 |-> 0],
      issueClassificationCode |-> [i \in 1 .. 4 |-> 0],
      netChangeDistinction    |-> [i \in 1 .. 1 |-> 0],
      topRankByNetChange      |-> [i \in 1 .. 30 |-> ZeroTopRankByNetChange] ]

(* Ranking By Net Change Message at zero, then each field in turn at the values it is checked at *)
CheckedRankingByNetChangeMessage ==
    { ZeroRankingByNetChangeMessage }
        \cup { [ZeroRankingByNetChangeMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroRankingByNetChangeMessage EXCEPT !.outputTime = one] : one \in Sample(6) }
        \cup { [ZeroRankingByNetChangeMessage EXCEPT !.issueClassificationCode = one] : one \in Sample(4) }
        \cup { [ZeroRankingByNetChangeMessage EXCEPT !.netChangeDistinction = one] : one \in Sample(1) }
        \cup { [ZeroRankingByNetChangeMessage EXCEPT !.topRankByNetChange = one] : one \in SlotsTopRankByNetChange }

(***************************************************************************)
(* Top Rank By Net Change Rate: 41 bytes                                   *)
(***************************************************************************)

TopRankByNetChangeRate ==
    [ rank            : Sample(2),
      rankedIssueCode : Sample(12),
      stateSign       : Sample(1),
      unitFlag        : Sample(1),
      currentPriceC14 : Sample(14),
      sign            : Sample(1),
      comparisonType  : Sample(1),
      netChangeRate   : Sample(8),
      secondSign      : Sample(1) ]

EncodeTopRankByNetChangeRate(message) ==
    message.rank
        \o message.rankedIssueCode
        \o message.stateSign
        \o message.unitFlag
        \o message.currentPriceC14
        \o message.sign
        \o message.comparisonType
        \o message.netChangeRate
        \o message.secondSign

DecodeTopRankByNetChangeRate(bytes) ==
    LET rank == ReadBytes(bytes, 2) IN IF ~rank.ok THEN Fail ELSE
    LET rankedIssueCode == ReadBytes(rank.rest, 12) IN IF ~rankedIssueCode.ok THEN Fail ELSE
    LET stateSign == ReadBytes(rankedIssueCode.rest, 1) IN IF ~stateSign.ok THEN Fail ELSE
    LET unitFlag == ReadBytes(stateSign.rest, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET currentPriceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~currentPriceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(currentPriceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET comparisonType == ReadBytes(sign.rest, 1) IN IF ~comparisonType.ok THEN Fail ELSE
    LET netChangeRate == ReadBytes(comparisonType.rest, 8) IN IF ~netChangeRate.ok THEN Fail ELSE
    LET secondSign == ReadBytes(netChangeRate.rest, 1) IN IF ~secondSign.ok THEN Fail ELSE
    Ok([ rank            |-> rank.value,
         rankedIssueCode |-> rankedIssueCode.value,
         stateSign       |-> stateSign.value,
         unitFlag        |-> unitFlag.value,
         currentPriceC14 |-> currentPriceC14.value,
         sign            |-> sign.value,
         comparisonType  |-> comparisonType.value,
         netChangeRate   |-> netChangeRate.value,
         secondSign      |-> secondSign.value ], secondSign.rest)

ZeroTopRankByNetChangeRate ==
    [ rank            |-> [i \in 1 .. 2 |-> 0],
      rankedIssueCode |-> [i \in 1 .. 12 |-> 0],
      stateSign       |-> [i \in 1 .. 1 |-> 0],
      unitFlag        |-> [i \in 1 .. 1 |-> 0],
      currentPriceC14 |-> [i \in 1 .. 14 |-> 0],
      sign            |-> [i \in 1 .. 1 |-> 0],
      comparisonType  |-> [i \in 1 .. 1 |-> 0],
      netChangeRate   |-> [i \in 1 .. 8 |-> 0],
      secondSign      |-> [i \in 1 .. 1 |-> 0] ]

(* Top Rank By Net Change Rate at zero, then each field in turn at the values it is checked at *)
CheckedTopRankByNetChangeRate ==
    { ZeroTopRankByNetChangeRate }
        \cup { [ZeroTopRankByNetChangeRate EXCEPT !.rank = one] : one \in Sample(2) }
        \cup { [ZeroTopRankByNetChangeRate EXCEPT !.rankedIssueCode = one] : one \in Sample(12) }
        \cup { [ZeroTopRankByNetChangeRate EXCEPT !.stateSign = one] : one \in Sample(1) }
        \cup { [ZeroTopRankByNetChangeRate EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTopRankByNetChangeRate EXCEPT !.currentPriceC14 = one] : one \in Sample(14) }
        \cup { [ZeroTopRankByNetChangeRate EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroTopRankByNetChangeRate EXCEPT !.comparisonType = one] : one \in Sample(1) }
        \cup { [ZeroTopRankByNetChangeRate EXCEPT !.netChangeRate = one] : one \in Sample(8) }
        \cup { [ZeroTopRankByNetChangeRate EXCEPT !.secondSign = one] : one \in Sample(1) }

(* A run of Top Rank By Net Change Rate, written one after another *)
RECURSIVE EncodeTopRankByNetChangeRateList(_)
EncodeTopRankByNetChangeRateList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTopRankByNetChangeRate(Head(messages)) \o EncodeTopRankByNetChangeRateList(Tail(messages))

(* As many Top Rank By Net Change Rate as the field that counts them says *)
RECURSIVE ReadTopRankByNetChangeRateList(_, _)
ReadTopRankByNetChangeRateList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTopRankByNetChangeRate(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTopRankByNetChangeRateList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Top Rank By Net Change Rate of each kind, for the lists that carry them *)
OneTopRankByNetChangeRate == { ZeroTopRankByNetChangeRate }

(* The 30 slots a run of Top Rank By Net Change Rate is written as, whatever the field beside it says are in use *)
SlotsTopRankByNetChangeRate == { [i \in 1 .. 30 |-> one] : one \in OneTopRankByNetChangeRate }

(***************************************************************************)
(* Ranking By Net Change Rate Message                                      *)
(***************************************************************************)

RankingByNetChangeRateMessage ==
    [ reserved2               : Sample(2),
      outputTime              : Sample(6),
      issueClassificationCode : Sample(4),
      netChangeDistinction    : Sample(1),
      topRankByNetChangeRate  : SlotsTopRankByNetChangeRate ]

EncodeRankingByNetChangeRateMessage(message) ==
    message.reserved2
        \o message.outputTime
        \o message.issueClassificationCode
        \o message.netChangeDistinction
        \o EncodeTopRankByNetChangeRateList(message.topRankByNetChangeRate)

DecodeRankingByNetChangeRateMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET outputTime == ReadBytes(reserved2.rest, 6) IN IF ~outputTime.ok THEN Fail ELSE
    LET issueClassificationCode == ReadBytes(outputTime.rest, 4) IN IF ~issueClassificationCode.ok THEN Fail ELSE
    LET netChangeDistinction == ReadBytes(issueClassificationCode.rest, 1) IN IF ~netChangeDistinction.ok THEN Fail ELSE
    LET topRankByNetChangeRate == ReadTopRankByNetChangeRateList(netChangeDistinction.rest, 30) IN IF ~topRankByNetChangeRate.ok THEN Fail ELSE
    Ok([ reserved2               |-> reserved2.value,
         outputTime              |-> outputTime.value,
         issueClassificationCode |-> issueClassificationCode.value,
         netChangeDistinction    |-> netChangeDistinction.value,
         topRankByNetChangeRate  |-> topRankByNetChangeRate.value ], topRankByNetChangeRate.rest)

ZeroRankingByNetChangeRateMessage ==
    [ reserved2               |-> [i \in 1 .. 2 |-> 0],
      outputTime              |-> [i \in 1 .. 6 |-> 0],
      issueClassificationCode |-> [i \in 1 .. 4 |-> 0],
      netChangeDistinction    |-> [i \in 1 .. 1 |-> 0],
      topRankByNetChangeRate  |-> [i \in 1 .. 30 |-> ZeroTopRankByNetChangeRate] ]

(* Ranking By Net Change Rate Message at zero, then each field in turn at the values it is checked at *)
CheckedRankingByNetChangeRateMessage ==
    { ZeroRankingByNetChangeRateMessage }
        \cup { [ZeroRankingByNetChangeRateMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroRankingByNetChangeRateMessage EXCEPT !.outputTime = one] : one \in Sample(6) }
        \cup { [ZeroRankingByNetChangeRateMessage EXCEPT !.issueClassificationCode = one] : one \in Sample(4) }
        \cup { [ZeroRankingByNetChangeRateMessage EXCEPT !.netChangeDistinction = one] : one \in Sample(1) }
        \cup { [ZeroRankingByNetChangeRateMessage EXCEPT !.topRankByNetChangeRate = one] : one \in SlotsTopRankByNetChangeRate }

(***************************************************************************)
(* Trading Volume: 60 bytes                                                *)
(***************************************************************************)

TradingVolume ==
    [ tradingVolumeTurnoverUnitFlag       : Sample(1),
      singleIssueTransactionC14           : Sample(14),
      secondTradingVolumeturnoverUnitFlag : Sample(1),
      closingPriceTransaction             : Sample(14),
      thirdTradingVolumeturnoverUnitFlag  : Sample(1),
      basketTransactionC14                : Sample(14),
      fourthTradingVolumeturnoverUnitFlag : Sample(1),
      aggregateTradingVolume              : Sample(14) ]

EncodeTradingVolume(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.singleIssueTransactionC14
        \o message.secondTradingVolumeturnoverUnitFlag
        \o message.closingPriceTransaction
        \o message.thirdTradingVolumeturnoverUnitFlag
        \o message.basketTransactionC14
        \o message.fourthTradingVolumeturnoverUnitFlag
        \o message.aggregateTradingVolume

DecodeTradingVolume(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET singleIssueTransactionC14 == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~singleIssueTransactionC14.ok THEN Fail ELSE
    LET secondTradingVolumeturnoverUnitFlag == ReadBytes(singleIssueTransactionC14.rest, 1) IN IF ~secondTradingVolumeturnoverUnitFlag.ok THEN Fail ELSE
    LET closingPriceTransaction == ReadBytes(secondTradingVolumeturnoverUnitFlag.rest, 14) IN IF ~closingPriceTransaction.ok THEN Fail ELSE
    LET thirdTradingVolumeturnoverUnitFlag == ReadBytes(closingPriceTransaction.rest, 1) IN IF ~thirdTradingVolumeturnoverUnitFlag.ok THEN Fail ELSE
    LET basketTransactionC14 == ReadBytes(thirdTradingVolumeturnoverUnitFlag.rest, 14) IN IF ~basketTransactionC14.ok THEN Fail ELSE
    LET fourthTradingVolumeturnoverUnitFlag == ReadBytes(basketTransactionC14.rest, 1) IN IF ~fourthTradingVolumeturnoverUnitFlag.ok THEN Fail ELSE
    LET aggregateTradingVolume == ReadBytes(fourthTradingVolumeturnoverUnitFlag.rest, 14) IN IF ~aggregateTradingVolume.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag       |-> tradingVolumeTurnoverUnitFlag.value,
         singleIssueTransactionC14           |-> singleIssueTransactionC14.value,
         secondTradingVolumeturnoverUnitFlag |-> secondTradingVolumeturnoverUnitFlag.value,
         closingPriceTransaction             |-> closingPriceTransaction.value,
         thirdTradingVolumeturnoverUnitFlag  |-> thirdTradingVolumeturnoverUnitFlag.value,
         basketTransactionC14                |-> basketTransactionC14.value,
         fourthTradingVolumeturnoverUnitFlag |-> fourthTradingVolumeturnoverUnitFlag.value,
         aggregateTradingVolume              |-> aggregateTradingVolume.value ], aggregateTradingVolume.rest)

ZeroTradingVolume ==
    [ tradingVolumeTurnoverUnitFlag       |-> [i \in 1 .. 1 |-> 0],
      singleIssueTransactionC14           |-> [i \in 1 .. 14 |-> 0],
      secondTradingVolumeturnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      closingPriceTransaction             |-> [i \in 1 .. 14 |-> 0],
      thirdTradingVolumeturnoverUnitFlag  |-> [i \in 1 .. 1 |-> 0],
      basketTransactionC14                |-> [i \in 1 .. 14 |-> 0],
      fourthTradingVolumeturnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      aggregateTradingVolume              |-> [i \in 1 .. 14 |-> 0] ]

(* Trading Volume at zero, then each field in turn at the values it is checked at *)
CheckedTradingVolume ==
    { ZeroTradingVolume }
        \cup { [ZeroTradingVolume EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradingVolume EXCEPT !.singleIssueTransactionC14 = one] : one \in Sample(14) }
        \cup { [ZeroTradingVolume EXCEPT !.secondTradingVolumeturnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradingVolume EXCEPT !.closingPriceTransaction = one] : one \in Sample(14) }
        \cup { [ZeroTradingVolume EXCEPT !.thirdTradingVolumeturnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradingVolume EXCEPT !.basketTransactionC14 = one] : one \in Sample(14) }
        \cup { [ZeroTradingVolume EXCEPT !.fourthTradingVolumeturnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradingVolume EXCEPT !.aggregateTradingVolume = one] : one \in Sample(14) }

(***************************************************************************)
(* Turnover: 60 bytes                                                      *)
(***************************************************************************)

Turnover ==
    [ tradingVolumeTurnoverUnitFlag       : Sample(1),
      singleIssueTransactionC14           : Sample(14),
      secondTradingVolumeturnoverUnitFlag : Sample(1),
      closingPriceTransaction             : Sample(14),
      thirdTradingVolumeturnoverUnitFlag  : Sample(1),
      basketTransactionC14                : Sample(14),
      fourthTradingVolumeturnoverUnitFlag : Sample(1),
      aggregateTurnover                   : Sample(14) ]

EncodeTurnover(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.singleIssueTransactionC14
        \o message.secondTradingVolumeturnoverUnitFlag
        \o message.closingPriceTransaction
        \o message.thirdTradingVolumeturnoverUnitFlag
        \o message.basketTransactionC14
        \o message.fourthTradingVolumeturnoverUnitFlag
        \o message.aggregateTurnover

DecodeTurnover(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET singleIssueTransactionC14 == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~singleIssueTransactionC14.ok THEN Fail ELSE
    LET secondTradingVolumeturnoverUnitFlag == ReadBytes(singleIssueTransactionC14.rest, 1) IN IF ~secondTradingVolumeturnoverUnitFlag.ok THEN Fail ELSE
    LET closingPriceTransaction == ReadBytes(secondTradingVolumeturnoverUnitFlag.rest, 14) IN IF ~closingPriceTransaction.ok THEN Fail ELSE
    LET thirdTradingVolumeturnoverUnitFlag == ReadBytes(closingPriceTransaction.rest, 1) IN IF ~thirdTradingVolumeturnoverUnitFlag.ok THEN Fail ELSE
    LET basketTransactionC14 == ReadBytes(thirdTradingVolumeturnoverUnitFlag.rest, 14) IN IF ~basketTransactionC14.ok THEN Fail ELSE
    LET fourthTradingVolumeturnoverUnitFlag == ReadBytes(basketTransactionC14.rest, 1) IN IF ~fourthTradingVolumeturnoverUnitFlag.ok THEN Fail ELSE
    LET aggregateTurnover == ReadBytes(fourthTradingVolumeturnoverUnitFlag.rest, 14) IN IF ~aggregateTurnover.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag       |-> tradingVolumeTurnoverUnitFlag.value,
         singleIssueTransactionC14           |-> singleIssueTransactionC14.value,
         secondTradingVolumeturnoverUnitFlag |-> secondTradingVolumeturnoverUnitFlag.value,
         closingPriceTransaction             |-> closingPriceTransaction.value,
         thirdTradingVolumeturnoverUnitFlag  |-> thirdTradingVolumeturnoverUnitFlag.value,
         basketTransactionC14                |-> basketTransactionC14.value,
         fourthTradingVolumeturnoverUnitFlag |-> fourthTradingVolumeturnoverUnitFlag.value,
         aggregateTurnover                   |-> aggregateTurnover.value ], aggregateTurnover.rest)

ZeroTurnover ==
    [ tradingVolumeTurnoverUnitFlag       |-> [i \in 1 .. 1 |-> 0],
      singleIssueTransactionC14           |-> [i \in 1 .. 14 |-> 0],
      secondTradingVolumeturnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      closingPriceTransaction             |-> [i \in 1 .. 14 |-> 0],
      thirdTradingVolumeturnoverUnitFlag  |-> [i \in 1 .. 1 |-> 0],
      basketTransactionC14                |-> [i \in 1 .. 14 |-> 0],
      fourthTradingVolumeturnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      aggregateTurnover                   |-> [i \in 1 .. 14 |-> 0] ]

(* Turnover at zero, then each field in turn at the values it is checked at *)
CheckedTurnover ==
    { ZeroTurnover }
        \cup { [ZeroTurnover EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTurnover EXCEPT !.singleIssueTransactionC14 = one] : one \in Sample(14) }
        \cup { [ZeroTurnover EXCEPT !.secondTradingVolumeturnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTurnover EXCEPT !.closingPriceTransaction = one] : one \in Sample(14) }
        \cup { [ZeroTurnover EXCEPT !.thirdTradingVolumeturnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTurnover EXCEPT !.basketTransactionC14 = one] : one \in Sample(14) }
        \cup { [ZeroTurnover EXCEPT !.fourthTradingVolumeturnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTurnover EXCEPT !.aggregateTurnover = one] : one \in Sample(14) }

(***************************************************************************)
(* Number Of Transactions: 16 bytes                                        *)
(***************************************************************************)

NumberOfTransactions ==
    [ singleIssueTransactionC8 : Sample(8),
      basketTransactionC8      : Sample(8) ]

EncodeNumberOfTransactions(message) ==
    message.singleIssueTransactionC8
        \o message.basketTransactionC8

DecodeNumberOfTransactions(bytes) ==
    LET singleIssueTransactionC8 == ReadBytes(bytes, 8) IN IF ~singleIssueTransactionC8.ok THEN Fail ELSE
    LET basketTransactionC8 == ReadBytes(singleIssueTransactionC8.rest, 8) IN IF ~basketTransactionC8.ok THEN Fail ELSE
    Ok([ singleIssueTransactionC8 |-> singleIssueTransactionC8.value,
         basketTransactionC8      |-> basketTransactionC8.value ], basketTransactionC8.rest)

ZeroNumberOfTransactions ==
    [ singleIssueTransactionC8 |-> [i \in 1 .. 8 |-> 0],
      basketTransactionC8      |-> [i \in 1 .. 8 |-> 0] ]

(* Number Of Transactions at zero, then each field in turn at the values it is checked at *)
CheckedNumberOfTransactions ==
    { ZeroNumberOfTransactions }
        \cup { [ZeroNumberOfTransactions EXCEPT !.singleIssueTransactionC8 = one] : one \in Sample(8) }
        \cup { [ZeroNumberOfTransactions EXCEPT !.basketTransactionC8 = one] : one \in Sample(8) }

(***************************************************************************)
(* ToSTNeT Statistics Message: 146 bytes                                   *)
(***************************************************************************)

TostnetStatisticsMessage ==
    [ reserved2               : Sample(2),
      outputTime              : Sample(6),
      otherClassificationFlag : Sample(2),
      tradingVolume           : TradingVolume,
      turnover                : Turnover,
      numberOfTransactions    : NumberOfTransactions ]

EncodeTostnetStatisticsMessage(message) ==
    message.reserved2
        \o message.outputTime
        \o message.otherClassificationFlag
        \o EncodeTradingVolume(message.tradingVolume)
        \o EncodeTurnover(message.turnover)
        \o EncodeNumberOfTransactions(message.numberOfTransactions)

DecodeTostnetStatisticsMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET outputTime == ReadBytes(reserved2.rest, 6) IN IF ~outputTime.ok THEN Fail ELSE
    LET otherClassificationFlag == ReadBytes(outputTime.rest, 2) IN IF ~otherClassificationFlag.ok THEN Fail ELSE
    LET tradingVolume == DecodeTradingVolume(otherClassificationFlag.rest) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET turnover == DecodeTurnover(tradingVolume.rest) IN IF ~turnover.ok THEN Fail ELSE
    LET numberOfTransactions == DecodeNumberOfTransactions(turnover.rest) IN IF ~numberOfTransactions.ok THEN Fail ELSE
    Ok([ reserved2               |-> reserved2.value,
         outputTime              |-> outputTime.value,
         otherClassificationFlag |-> otherClassificationFlag.value,
         tradingVolume           |-> tradingVolume.value,
         turnover                |-> turnover.value,
         numberOfTransactions    |-> numberOfTransactions.value ], numberOfTransactions.rest)

ZeroTostnetStatisticsMessage ==
    [ reserved2               |-> [i \in 1 .. 2 |-> 0],
      outputTime              |-> [i \in 1 .. 6 |-> 0],
      otherClassificationFlag |-> [i \in 1 .. 2 |-> 0],
      tradingVolume           |-> ZeroTradingVolume,
      turnover                |-> ZeroTurnover,
      numberOfTransactions    |-> ZeroNumberOfTransactions ]

(* ToSTNeT Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedTostnetStatisticsMessage ==
    { ZeroTostnetStatisticsMessage }
        \cup { [ZeroTostnetStatisticsMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTostnetStatisticsMessage EXCEPT !.outputTime = one] : one \in Sample(6) }
        \cup { [ZeroTostnetStatisticsMessage EXCEPT !.otherClassificationFlag = one] : one \in Sample(2) }
        \cup { [ZeroTostnetStatisticsMessage EXCEPT !.tradingVolume = one] : one \in CheckedTradingVolume }
        \cup { [ZeroTostnetStatisticsMessage EXCEPT !.turnover = one] : one \in CheckedTurnover }
        \cup { [ZeroTostnetStatisticsMessage EXCEPT !.numberOfTransactions = one] : one \in CheckedNumberOfTransactions }

(***************************************************************************)
(* Open: 23 bytes                                                          *)
(***************************************************************************)

Open ==
    [ unitFlag     : Sample(1),
      indexValue   : Sample(14),
      sign         : Sample(1),
      timeC6Hhmmss : Sample(6),
      flag         : Sample(1) ]

EncodeOpen(message) ==
    message.unitFlag
        \o message.indexValue
        \o message.sign
        \o message.timeC6Hhmmss
        \o message.flag

DecodeOpen(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET indexValue == ReadBytes(unitFlag.rest, 14) IN IF ~indexValue.ok THEN Fail ELSE
    LET sign == ReadBytes(indexValue.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET timeC6Hhmmss == ReadBytes(sign.rest, 6) IN IF ~timeC6Hhmmss.ok THEN Fail ELSE
    LET flag == ReadBytes(timeC6Hhmmss.rest, 1) IN IF ~flag.ok THEN Fail ELSE
    Ok([ unitFlag     |-> unitFlag.value,
         indexValue   |-> indexValue.value,
         sign         |-> sign.value,
         timeC6Hhmmss |-> timeC6Hhmmss.value,
         flag         |-> flag.value ], flag.rest)

ZeroOpen ==
    [ unitFlag     |-> [i \in 1 .. 1 |-> 0],
      indexValue   |-> [i \in 1 .. 14 |-> 0],
      sign         |-> [i \in 1 .. 1 |-> 0],
      timeC6Hhmmss |-> [i \in 1 .. 6 |-> 0],
      flag         |-> [i \in 1 .. 1 |-> 0] ]

(* Open at zero, then each field in turn at the values it is checked at *)
CheckedOpen ==
    { ZeroOpen }
        \cup { [ZeroOpen EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroOpen EXCEPT !.indexValue = one] : one \in Sample(14) }
        \cup { [ZeroOpen EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroOpen EXCEPT !.timeC6Hhmmss = one] : one \in Sample(6) }
        \cup { [ZeroOpen EXCEPT !.flag = one] : one \in Sample(1) }

(***************************************************************************)
(* Highest: 23 bytes                                                       *)
(***************************************************************************)

Highest ==
    [ unitFlag     : Sample(1),
      indexValue   : Sample(14),
      sign         : Sample(1),
      timeC6Hhmmss : Sample(6),
      flag         : Sample(1) ]

EncodeHighest(message) ==
    message.unitFlag
        \o message.indexValue
        \o message.sign
        \o message.timeC6Hhmmss
        \o message.flag

DecodeHighest(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET indexValue == ReadBytes(unitFlag.rest, 14) IN IF ~indexValue.ok THEN Fail ELSE
    LET sign == ReadBytes(indexValue.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET timeC6Hhmmss == ReadBytes(sign.rest, 6) IN IF ~timeC6Hhmmss.ok THEN Fail ELSE
    LET flag == ReadBytes(timeC6Hhmmss.rest, 1) IN IF ~flag.ok THEN Fail ELSE
    Ok([ unitFlag     |-> unitFlag.value,
         indexValue   |-> indexValue.value,
         sign         |-> sign.value,
         timeC6Hhmmss |-> timeC6Hhmmss.value,
         flag         |-> flag.value ], flag.rest)

ZeroHighest ==
    [ unitFlag     |-> [i \in 1 .. 1 |-> 0],
      indexValue   |-> [i \in 1 .. 14 |-> 0],
      sign         |-> [i \in 1 .. 1 |-> 0],
      timeC6Hhmmss |-> [i \in 1 .. 6 |-> 0],
      flag         |-> [i \in 1 .. 1 |-> 0] ]

(* Highest at zero, then each field in turn at the values it is checked at *)
CheckedHighest ==
    { ZeroHighest }
        \cup { [ZeroHighest EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroHighest EXCEPT !.indexValue = one] : one \in Sample(14) }
        \cup { [ZeroHighest EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroHighest EXCEPT !.timeC6Hhmmss = one] : one \in Sample(6) }
        \cup { [ZeroHighest EXCEPT !.flag = one] : one \in Sample(1) }

(***************************************************************************)
(* Lowest: 23 bytes                                                        *)
(***************************************************************************)

Lowest ==
    [ unitFlag     : Sample(1),
      indexValue   : Sample(14),
      sign         : Sample(1),
      timeC6Hhmmss : Sample(6),
      flag         : Sample(1) ]

EncodeLowest(message) ==
    message.unitFlag
        \o message.indexValue
        \o message.sign
        \o message.timeC6Hhmmss
        \o message.flag

DecodeLowest(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET indexValue == ReadBytes(unitFlag.rest, 14) IN IF ~indexValue.ok THEN Fail ELSE
    LET sign == ReadBytes(indexValue.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET timeC6Hhmmss == ReadBytes(sign.rest, 6) IN IF ~timeC6Hhmmss.ok THEN Fail ELSE
    LET flag == ReadBytes(timeC6Hhmmss.rest, 1) IN IF ~flag.ok THEN Fail ELSE
    Ok([ unitFlag     |-> unitFlag.value,
         indexValue   |-> indexValue.value,
         sign         |-> sign.value,
         timeC6Hhmmss |-> timeC6Hhmmss.value,
         flag         |-> flag.value ], flag.rest)

ZeroLowest ==
    [ unitFlag     |-> [i \in 1 .. 1 |-> 0],
      indexValue   |-> [i \in 1 .. 14 |-> 0],
      sign         |-> [i \in 1 .. 1 |-> 0],
      timeC6Hhmmss |-> [i \in 1 .. 6 |-> 0],
      flag         |-> [i \in 1 .. 1 |-> 0] ]

(* Lowest at zero, then each field in turn at the values it is checked at *)
CheckedLowest ==
    { ZeroLowest }
        \cup { [ZeroLowest EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroLowest EXCEPT !.indexValue = one] : one \in Sample(14) }
        \cup { [ZeroLowest EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroLowest EXCEPT !.timeC6Hhmmss = one] : one \in Sample(6) }
        \cup { [ZeroLowest EXCEPT !.flag = one] : one \in Sample(1) }

(***************************************************************************)
(* Current Price: 23 bytes                                                 *)
(***************************************************************************)

CurrentPrice ==
    [ unitFlag     : Sample(1),
      indexValue   : Sample(14),
      sign         : Sample(1),
      timeC6Hhmmss : Sample(6),
      flag         : Sample(1) ]

EncodeCurrentPrice(message) ==
    message.unitFlag
        \o message.indexValue
        \o message.sign
        \o message.timeC6Hhmmss
        \o message.flag

DecodeCurrentPrice(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET indexValue == ReadBytes(unitFlag.rest, 14) IN IF ~indexValue.ok THEN Fail ELSE
    LET sign == ReadBytes(indexValue.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET timeC6Hhmmss == ReadBytes(sign.rest, 6) IN IF ~timeC6Hhmmss.ok THEN Fail ELSE
    LET flag == ReadBytes(timeC6Hhmmss.rest, 1) IN IF ~flag.ok THEN Fail ELSE
    Ok([ unitFlag     |-> unitFlag.value,
         indexValue   |-> indexValue.value,
         sign         |-> sign.value,
         timeC6Hhmmss |-> timeC6Hhmmss.value,
         flag         |-> flag.value ], flag.rest)

ZeroCurrentPrice ==
    [ unitFlag     |-> [i \in 1 .. 1 |-> 0],
      indexValue   |-> [i \in 1 .. 14 |-> 0],
      sign         |-> [i \in 1 .. 1 |-> 0],
      timeC6Hhmmss |-> [i \in 1 .. 6 |-> 0],
      flag         |-> [i \in 1 .. 1 |-> 0] ]

(* Current Price at zero, then each field in turn at the values it is checked at *)
CheckedCurrentPrice ==
    { ZeroCurrentPrice }
        \cup { [ZeroCurrentPrice EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroCurrentPrice EXCEPT !.indexValue = one] : one \in Sample(14) }
        \cup { [ZeroCurrentPrice EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroCurrentPrice EXCEPT !.timeC6Hhmmss = one] : one \in Sample(6) }
        \cup { [ZeroCurrentPrice EXCEPT !.flag = one] : one \in Sample(1) }

(***************************************************************************)
(* Index Day On Day Comparison: 25 bytes                                   *)
(***************************************************************************)

IndexDayOnDayComparison ==
    [ netChangeRate : Sample(8),
      sign          : Sample(1),
      unitFlag      : Sample(1),
      netChange     : Sample(14),
      secondSign    : Sample(1) ]

EncodeIndexDayOnDayComparison(message) ==
    message.netChangeRate
        \o message.sign
        \o message.unitFlag
        \o message.netChange
        \o message.secondSign

DecodeIndexDayOnDayComparison(bytes) ==
    LET netChangeRate == ReadBytes(bytes, 8) IN IF ~netChangeRate.ok THEN Fail ELSE
    LET sign == ReadBytes(netChangeRate.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET unitFlag == ReadBytes(sign.rest, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET netChange == ReadBytes(unitFlag.rest, 14) IN IF ~netChange.ok THEN Fail ELSE
    LET secondSign == ReadBytes(netChange.rest, 1) IN IF ~secondSign.ok THEN Fail ELSE
    Ok([ netChangeRate |-> netChangeRate.value,
         sign          |-> sign.value,
         unitFlag      |-> unitFlag.value,
         netChange     |-> netChange.value,
         secondSign    |-> secondSign.value ], secondSign.rest)

ZeroIndexDayOnDayComparison ==
    [ netChangeRate |-> [i \in 1 .. 8 |-> 0],
      sign          |-> [i \in 1 .. 1 |-> 0],
      unitFlag      |-> [i \in 1 .. 1 |-> 0],
      netChange     |-> [i \in 1 .. 14 |-> 0],
      secondSign    |-> [i \in 1 .. 1 |-> 0] ]

(* Index Day On Day Comparison at zero, then each field in turn at the values it is checked at *)
CheckedIndexDayOnDayComparison ==
    { ZeroIndexDayOnDayComparison }
        \cup { [ZeroIndexDayOnDayComparison EXCEPT !.netChangeRate = one] : one \in Sample(8) }
        \cup { [ZeroIndexDayOnDayComparison EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroIndexDayOnDayComparison EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroIndexDayOnDayComparison EXCEPT !.netChange = one] : one \in Sample(14) }
        \cup { [ZeroIndexDayOnDayComparison EXCEPT !.secondSign = one] : one \in Sample(1) }

(***************************************************************************)
(* Index Open High Low And Closing Prices Message: 123 bytes               *)
(***************************************************************************)

IndexOpenHighLowAndClosingPricesMessage ==
    [ reserved2               : Sample(2),
      indexType               : Sample(4),
      open                    : Open,
      highest                 : Highest,
      lowest                  : Lowest,
      currentPrice            : CurrentPrice,
      indexDayOnDayComparison : IndexDayOnDayComparison ]

EncodeIndexOpenHighLowAndClosingPricesMessage(message) ==
    message.reserved2
        \o message.indexType
        \o EncodeOpen(message.open)
        \o EncodeHighest(message.highest)
        \o EncodeLowest(message.lowest)
        \o EncodeCurrentPrice(message.currentPrice)
        \o EncodeIndexDayOnDayComparison(message.indexDayOnDayComparison)

DecodeIndexOpenHighLowAndClosingPricesMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET indexType == ReadBytes(reserved2.rest, 4) IN IF ~indexType.ok THEN Fail ELSE
    LET open == DecodeOpen(indexType.rest) IN IF ~open.ok THEN Fail ELSE
    LET highest == DecodeHighest(open.rest) IN IF ~highest.ok THEN Fail ELSE
    LET lowest == DecodeLowest(highest.rest) IN IF ~lowest.ok THEN Fail ELSE
    LET currentPrice == DecodeCurrentPrice(lowest.rest) IN IF ~currentPrice.ok THEN Fail ELSE
    LET indexDayOnDayComparison == DecodeIndexDayOnDayComparison(currentPrice.rest) IN IF ~indexDayOnDayComparison.ok THEN Fail ELSE
    Ok([ reserved2               |-> reserved2.value,
         indexType               |-> indexType.value,
         open                    |-> open.value,
         highest                 |-> highest.value,
         lowest                  |-> lowest.value,
         currentPrice            |-> currentPrice.value,
         indexDayOnDayComparison |-> indexDayOnDayComparison.value ], indexDayOnDayComparison.rest)

ZeroIndexOpenHighLowAndClosingPricesMessage ==
    [ reserved2               |-> [i \in 1 .. 2 |-> 0],
      indexType               |-> [i \in 1 .. 4 |-> 0],
      open                    |-> ZeroOpen,
      highest                 |-> ZeroHighest,
      lowest                  |-> ZeroLowest,
      currentPrice            |-> ZeroCurrentPrice,
      indexDayOnDayComparison |-> ZeroIndexDayOnDayComparison ]

(* Index Open High Low And Closing Prices Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexOpenHighLowAndClosingPricesMessage ==
    { ZeroIndexOpenHighLowAndClosingPricesMessage }
        \cup { [ZeroIndexOpenHighLowAndClosingPricesMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroIndexOpenHighLowAndClosingPricesMessage EXCEPT !.indexType = one] : one \in Sample(4) }
        \cup { [ZeroIndexOpenHighLowAndClosingPricesMessage EXCEPT !.open = one] : one \in CheckedOpen }
        \cup { [ZeroIndexOpenHighLowAndClosingPricesMessage EXCEPT !.highest = one] : one \in CheckedHighest }
        \cup { [ZeroIndexOpenHighLowAndClosingPricesMessage EXCEPT !.lowest = one] : one \in CheckedLowest }
        \cup { [ZeroIndexOpenHighLowAndClosingPricesMessage EXCEPT !.currentPrice = one] : one \in CheckedCurrentPrice }
        \cup { [ZeroIndexOpenHighLowAndClosingPricesMessage EXCEPT !.indexDayOnDayComparison = one] : one \in CheckedIndexDayOnDayComparison }

(***************************************************************************)
(* Index: 22 bytes                                                         *)
(***************************************************************************)

Index ==
    [ unitFlag     : Sample(1),
      indexValue   : Sample(14),
      sign         : Sample(1),
      timeC6Hhmmss : Sample(6) ]

EncodeIndex(message) ==
    message.unitFlag
        \o message.indexValue
        \o message.sign
        \o message.timeC6Hhmmss

DecodeIndex(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET indexValue == ReadBytes(unitFlag.rest, 14) IN IF ~indexValue.ok THEN Fail ELSE
    LET sign == ReadBytes(indexValue.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET timeC6Hhmmss == ReadBytes(sign.rest, 6) IN IF ~timeC6Hhmmss.ok THEN Fail ELSE
    Ok([ unitFlag     |-> unitFlag.value,
         indexValue   |-> indexValue.value,
         sign         |-> sign.value,
         timeC6Hhmmss |-> timeC6Hhmmss.value ], timeC6Hhmmss.rest)

ZeroIndex ==
    [ unitFlag     |-> [i \in 1 .. 1 |-> 0],
      indexValue   |-> [i \in 1 .. 14 |-> 0],
      sign         |-> [i \in 1 .. 1 |-> 0],
      timeC6Hhmmss |-> [i \in 1 .. 6 |-> 0] ]

(* Index at zero, then each field in turn at the values it is checked at *)
CheckedIndex ==
    { ZeroIndex }
        \cup { [ZeroIndex EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroIndex EXCEPT !.indexValue = one] : one \in Sample(14) }
        \cup { [ZeroIndex EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroIndex EXCEPT !.timeC6Hhmmss = one] : one \in Sample(6) }

(***************************************************************************)
(* Special Quotation Message: 29 bytes                                     *)
(***************************************************************************)

SpecialQuotationMessage ==
    [ reserved2 : Sample(2),
      sqType    : Sample(4),
      index     : Index,
      reserved1 : Sample(1) ]

EncodeSpecialQuotationMessage(message) ==
    message.reserved2
        \o message.sqType
        \o EncodeIndex(message.index)
        \o message.reserved1

DecodeSpecialQuotationMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET sqType == ReadBytes(reserved2.rest, 4) IN IF ~sqType.ok THEN Fail ELSE
    LET index == DecodeIndex(sqType.rest) IN IF ~index.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(index.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         sqType    |-> sqType.value,
         index     |-> index.value,
         reserved1 |-> reserved1.value ], reserved1.rest)

ZeroSpecialQuotationMessage ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      sqType    |-> [i \in 1 .. 4 |-> 0],
      index     |-> ZeroIndex,
      reserved1 |-> [i \in 1 .. 1 |-> 0] ]

(* Special Quotation Message at zero, then each field in turn at the values it is checked at *)
CheckedSpecialQuotationMessage ==
    { ZeroSpecialQuotationMessage }
        \cup { [ZeroSpecialQuotationMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSpecialQuotationMessage EXCEPT !.sqType = one] : one \in Sample(4) }
        \cup { [ZeroSpecialQuotationMessage EXCEPT !.index = one] : one \in CheckedIndex }
        \cup { [ZeroSpecialQuotationMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Control Message: 10 bytes                                               *)
(***************************************************************************)

ControlMessage ==
    [ reserved2    : Sample(2),
      testModeFlag : Sample(1),
      startendFlag : Sample(1),
      timeC6Hhmm   : Sample(6) ]

EncodeControlMessage(message) ==
    message.reserved2
        \o message.testModeFlag
        \o message.startendFlag
        \o message.timeC6Hhmm

DecodeControlMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET testModeFlag == ReadBytes(reserved2.rest, 1) IN IF ~testModeFlag.ok THEN Fail ELSE
    LET startendFlag == ReadBytes(testModeFlag.rest, 1) IN IF ~startendFlag.ok THEN Fail ELSE
    LET timeC6Hhmm == ReadBytes(startendFlag.rest, 6) IN IF ~timeC6Hhmm.ok THEN Fail ELSE
    Ok([ reserved2    |-> reserved2.value,
         testModeFlag |-> testModeFlag.value,
         startendFlag |-> startendFlag.value,
         timeC6Hhmm   |-> timeC6Hhmm.value ], timeC6Hhmm.rest)

ZeroControlMessage ==
    [ reserved2    |-> [i \in 1 .. 2 |-> 0],
      testModeFlag |-> [i \in 1 .. 1 |-> 0],
      startendFlag |-> [i \in 1 .. 1 |-> 0],
      timeC6Hhmm   |-> [i \in 1 .. 6 |-> 0] ]

(* Control Message at zero, then each field in turn at the values it is checked at *)
CheckedControlMessage ==
    { ZeroControlMessage }
        \cup { [ZeroControlMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroControlMessage EXCEPT !.testModeFlag = one] : one \in Sample(1) }
        \cup { [ZeroControlMessage EXCEPT !.startendFlag = one] : one \in Sample(1) }
        \cup { [ZeroControlMessage EXCEPT !.timeC6Hhmm = one] : one \in Sample(6) }

(***************************************************************************)
(* Payload, selected by Tag ID                                             *)
(***************************************************************************)

MarketValueMessageCode == 19798  \* "MV"
SimpleYieldMessageCode == 22867  \* "YS"
WeightedYieldMessageCode == 22871  \* "YW"
SimpleStockPriceAverageMessageCode == 16720  \* "AP"
WeightedStockPriceAverageMessageCode == 16727  \* "AW"
SimpleStockPriceAverageByIndustryMessageCode == 16724  \* "AT"
JapaneseYenCbIndicatorMessageCode == 18777  \* "IY"
NumberOfGainersDeclinersMessageCode == 20035  \* "NC"
EstimatedTotalTradingVolumeMessageCode == 21590  \* "TV"
EstimatedTotalTurnoverMessageCode == 21569  \* "TA"
VwapByMarketMessageCode == 22099  \* "VS"
RankingByTradingVolumeMessageCode == 21071  \* "RO"
RankingByTurnoverMessageCode == 21057  \* "RA"
RankingByNetChangeMessageCode == 21059  \* "RC"
RankingByNetChangeRateMessageCode == 21072  \* "RP"
TostnetStatisticsMessageCode == 21587  \* "TS"
IndexOpenHighLowAndClosingPricesMessageCode == 13385  \* "4I"
SpecialQuotationMessageCode == 21329  \* "SQ"
ControlMessageCode == 19523  \* "LC"

Payload ==
    [ tag : {MarketValueMessageCode}, body : MarketValueMessage ]
        \cup [ tag : {SimpleYieldMessageCode}, body : SimpleYieldMessage ]
        \cup [ tag : {WeightedYieldMessageCode}, body : WeightedYieldMessage ]
        \cup [ tag : {SimpleStockPriceAverageMessageCode}, body : SimpleStockPriceAverageMessage ]
        \cup [ tag : {WeightedStockPriceAverageMessageCode}, body : WeightedStockPriceAverageMessage ]
        \cup [ tag : {SimpleStockPriceAverageByIndustryMessageCode}, body : SimpleStockPriceAverageByIndustryMessage ]
        \cup [ tag : {JapaneseYenCbIndicatorMessageCode}, body : JapaneseYenCbIndicatorMessage ]
        \cup [ tag : {NumberOfGainersDeclinersMessageCode}, body : NumberOfGainersDeclinersMessage ]
        \cup [ tag : {EstimatedTotalTradingVolumeMessageCode}, body : EstimatedTotalTradingVolumeMessage ]
        \cup [ tag : {EstimatedTotalTurnoverMessageCode}, body : EstimatedTotalTurnoverMessage ]
        \cup [ tag : {VwapByMarketMessageCode}, body : VwapByMarketMessage ]
        \cup [ tag : {RankingByTradingVolumeMessageCode}, body : RankingByTradingVolumeMessage ]
        \cup [ tag : {RankingByTurnoverMessageCode}, body : RankingByTurnoverMessage ]
        \cup [ tag : {RankingByNetChangeMessageCode}, body : RankingByNetChangeMessage ]
        \cup [ tag : {RankingByNetChangeRateMessageCode}, body : RankingByNetChangeRateMessage ]
        \cup [ tag : {TostnetStatisticsMessageCode}, body : TostnetStatisticsMessage ]
        \cup [ tag : {IndexOpenHighLowAndClosingPricesMessageCode}, body : IndexOpenHighLowAndClosingPricesMessage ]
        \cup [ tag : {SpecialQuotationMessageCode}, body : SpecialQuotationMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]

EncodePayload(message) ==
    CASE message.tag = MarketValueMessageCode -> EncodeMarketValueMessage(message.body)
      [] message.tag = SimpleYieldMessageCode -> EncodeSimpleYieldMessage(message.body)
      [] message.tag = WeightedYieldMessageCode -> EncodeWeightedYieldMessage(message.body)
      [] message.tag = SimpleStockPriceAverageMessageCode -> EncodeSimpleStockPriceAverageMessage(message.body)
      [] message.tag = WeightedStockPriceAverageMessageCode -> EncodeWeightedStockPriceAverageMessage(message.body)
      [] message.tag = SimpleStockPriceAverageByIndustryMessageCode -> EncodeSimpleStockPriceAverageByIndustryMessage(message.body)
      [] message.tag = JapaneseYenCbIndicatorMessageCode -> EncodeJapaneseYenCbIndicatorMessage(message.body)
      [] message.tag = NumberOfGainersDeclinersMessageCode -> EncodeNumberOfGainersDeclinersMessage(message.body)
      [] message.tag = EstimatedTotalTradingVolumeMessageCode -> EncodeEstimatedTotalTradingVolumeMessage(message.body)
      [] message.tag = EstimatedTotalTurnoverMessageCode -> EncodeEstimatedTotalTurnoverMessage(message.body)
      [] message.tag = VwapByMarketMessageCode -> EncodeVwapByMarketMessage(message.body)
      [] message.tag = RankingByTradingVolumeMessageCode -> EncodeRankingByTradingVolumeMessage(message.body)
      [] message.tag = RankingByTurnoverMessageCode -> EncodeRankingByTurnoverMessage(message.body)
      [] message.tag = RankingByNetChangeMessageCode -> EncodeRankingByNetChangeMessage(message.body)
      [] message.tag = RankingByNetChangeRateMessageCode -> EncodeRankingByNetChangeRateMessage(message.body)
      [] message.tag = TostnetStatisticsMessageCode -> EncodeTostnetStatisticsMessage(message.body)
      [] message.tag = IndexOpenHighLowAndClosingPricesMessageCode -> EncodeIndexOpenHighLowAndClosingPricesMessage(message.body)
      [] message.tag = SpecialQuotationMessageCode -> EncodeSpecialQuotationMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = MarketValueMessageCode -> DecodeMarketValueMessage(bytes)
              [] tag = SimpleYieldMessageCode -> DecodeSimpleYieldMessage(bytes)
              [] tag = WeightedYieldMessageCode -> DecodeWeightedYieldMessage(bytes)
              [] tag = SimpleStockPriceAverageMessageCode -> DecodeSimpleStockPriceAverageMessage(bytes)
              [] tag = WeightedStockPriceAverageMessageCode -> DecodeWeightedStockPriceAverageMessage(bytes)
              [] tag = SimpleStockPriceAverageByIndustryMessageCode -> DecodeSimpleStockPriceAverageByIndustryMessage(bytes)
              [] tag = JapaneseYenCbIndicatorMessageCode -> DecodeJapaneseYenCbIndicatorMessage(bytes)
              [] tag = NumberOfGainersDeclinersMessageCode -> DecodeNumberOfGainersDeclinersMessage(bytes)
              [] tag = EstimatedTotalTradingVolumeMessageCode -> DecodeEstimatedTotalTradingVolumeMessage(bytes)
              [] tag = EstimatedTotalTurnoverMessageCode -> DecodeEstimatedTotalTurnoverMessage(bytes)
              [] tag = VwapByMarketMessageCode -> DecodeVwapByMarketMessage(bytes)
              [] tag = RankingByTradingVolumeMessageCode -> DecodeRankingByTradingVolumeMessage(bytes)
              [] tag = RankingByTurnoverMessageCode -> DecodeRankingByTurnoverMessage(bytes)
              [] tag = RankingByNetChangeMessageCode -> DecodeRankingByNetChangeMessage(bytes)
              [] tag = RankingByNetChangeRateMessageCode -> DecodeRankingByNetChangeRateMessage(bytes)
              [] tag = TostnetStatisticsMessageCode -> DecodeTostnetStatisticsMessage(bytes)
              [] tag = IndexOpenHighLowAndClosingPricesMessageCode -> DecodeIndexOpenHighLowAndClosingPricesMessage(bytes)
              [] tag = SpecialQuotationMessageCode -> DecodeSpecialQuotationMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> MarketValueMessageCode, body |-> ZeroMarketValueMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> MarketValueMessageCode, body |-> one] : one \in CheckedMarketValueMessage }
        \cup { [tag |-> SimpleYieldMessageCode, body |-> one] : one \in CheckedSimpleYieldMessage }
        \cup { [tag |-> WeightedYieldMessageCode, body |-> one] : one \in CheckedWeightedYieldMessage }
        \cup { [tag |-> SimpleStockPriceAverageMessageCode, body |-> one] : one \in CheckedSimpleStockPriceAverageMessage }
        \cup { [tag |-> WeightedStockPriceAverageMessageCode, body |-> one] : one \in CheckedWeightedStockPriceAverageMessage }
        \cup { [tag |-> SimpleStockPriceAverageByIndustryMessageCode, body |-> one] : one \in CheckedSimpleStockPriceAverageByIndustryMessage }
        \cup { [tag |-> JapaneseYenCbIndicatorMessageCode, body |-> one] : one \in CheckedJapaneseYenCbIndicatorMessage }
        \cup { [tag |-> NumberOfGainersDeclinersMessageCode, body |-> one] : one \in CheckedNumberOfGainersDeclinersMessage }
        \cup { [tag |-> EstimatedTotalTradingVolumeMessageCode, body |-> one] : one \in CheckedEstimatedTotalTradingVolumeMessage }
        \cup { [tag |-> EstimatedTotalTurnoverMessageCode, body |-> one] : one \in CheckedEstimatedTotalTurnoverMessage }
        \cup { [tag |-> VwapByMarketMessageCode, body |-> one] : one \in CheckedVwapByMarketMessage }
        \cup { [tag |-> RankingByTradingVolumeMessageCode, body |-> one] : one \in CheckedRankingByTradingVolumeMessage }
        \cup { [tag |-> RankingByTurnoverMessageCode, body |-> one] : one \in CheckedRankingByTurnoverMessage }
        \cup { [tag |-> RankingByNetChangeMessageCode, body |-> one] : one \in CheckedRankingByNetChangeMessage }
        \cup { [tag |-> RankingByNetChangeRateMessageCode, body |-> one] : one \in CheckedRankingByNetChangeRateMessage }
        \cup { [tag |-> TostnetStatisticsMessageCode, body |-> one] : one \in CheckedTostnetStatisticsMessage }
        \cup { [tag |-> IndexOpenHighLowAndClosingPricesMessageCode, body |-> one] : one \in CheckedIndexOpenHighLowAndClosingPricesMessage }
        \cup { [tag |-> SpecialQuotationMessageCode, body |-> one] : one \in CheckedSpecialQuotationMessage }
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
    { [ZeroTagInformation EXCEPT !.payload = [tag |-> MarketValueMessageCode, body |-> ZeroMarketValueMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> SimpleYieldMessageCode, body |-> ZeroSimpleYieldMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> WeightedYieldMessageCode, body |-> ZeroWeightedYieldMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> SimpleStockPriceAverageMessageCode, body |-> ZeroSimpleStockPriceAverageMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> WeightedStockPriceAverageMessageCode, body |-> ZeroWeightedStockPriceAverageMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> SimpleStockPriceAverageByIndustryMessageCode, body |-> ZeroSimpleStockPriceAverageByIndustryMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> JapaneseYenCbIndicatorMessageCode, body |-> ZeroJapaneseYenCbIndicatorMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> NumberOfGainersDeclinersMessageCode, body |-> ZeroNumberOfGainersDeclinersMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> EstimatedTotalTradingVolumeMessageCode, body |-> ZeroEstimatedTotalTradingVolumeMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> EstimatedTotalTurnoverMessageCode, body |-> ZeroEstimatedTotalTurnoverMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> VwapByMarketMessageCode, body |-> ZeroVwapByMarketMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> RankingByTradingVolumeMessageCode, body |-> ZeroRankingByTradingVolumeMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> RankingByTurnoverMessageCode, body |-> ZeroRankingByTurnoverMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> RankingByNetChangeMessageCode, body |-> ZeroRankingByNetChangeMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> RankingByNetChangeRateMessageCode, body |-> ZeroRankingByNetChangeRateMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> TostnetStatisticsMessageCode, body |-> ZeroTostnetStatisticsMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> IndexOpenHighLowAndClosingPricesMessageCode, body |-> ZeroIndexOpenHighLowAndClosingPricesMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> SpecialQuotationMessageCode, body |-> ZeroSpecialQuotationMessage]],
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

(* Every Total Market Value decodes back to what was encoded, and leaves nothing over *)
RoundTripTotalMarketValue ==
    \A message \in CheckedTotalMarketValue :
        LET read == DecodeTotalMarketValue(EncodeTotalMarketValue(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Value Day On Day Comparison decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketValueDayOnDayComparison ==
    \A message \in CheckedMarketValueDayOnDayComparison :
        LET read == DecodeMarketValueDayOnDayComparison(EncodeMarketValueDayOnDayComparison(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Value Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketValueMessage ==
    \A message \in CheckedMarketValueMessage :
        LET read == DecodeMarketValueMessage(EncodeMarketValueMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Yield decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleYield ==
    \A message \in CheckedSimpleYield :
        LET read == DecodeSimpleYield(EncodeSimpleYield(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Yield Day On Day Comparison decodes back to what was encoded, and leaves nothing over *)
RoundTripYieldDayOnDayComparison ==
    \A message \in CheckedYieldDayOnDayComparison :
        LET read == DecodeYieldDayOnDayComparison(EncodeYieldDayOnDayComparison(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Yield Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleYieldMessage ==
    \A message \in CheckedSimpleYieldMessage :
        LET read == DecodeSimpleYieldMessage(EncodeSimpleYieldMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Weighted Yield decodes back to what was encoded, and leaves nothing over *)
RoundTripWeightedYield ==
    \A message \in CheckedWeightedYield :
        LET read == DecodeWeightedYield(EncodeWeightedYield(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Yield Day On Day Comparison decodes back to what was encoded, and leaves nothing over *)
RoundTripYieldDayOnDayComparison2 ==
    \A message \in CheckedYieldDayOnDayComparison2 :
        LET read == DecodeYieldDayOnDayComparison2(EncodeYieldDayOnDayComparison2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Weighted Yield Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWeightedYieldMessage ==
    \A message \in CheckedWeightedYieldMessage :
        LET read == DecodeWeightedYieldMessage(EncodeWeightedYieldMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Stock Price Average decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleStockPriceAverage ==
    \A message \in CheckedSimpleStockPriceAverage :
        LET read == DecodeSimpleStockPriceAverage(EncodeSimpleStockPriceAverage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Price Average Day On Day Comparison decodes back to what was encoded, and leaves nothing over *)
RoundTripStockPriceAverageDayOnDayComparison ==
    \A message \in CheckedStockPriceAverageDayOnDayComparison :
        LET read == DecodeStockPriceAverageDayOnDayComparison(EncodeStockPriceAverageDayOnDayComparison(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Stock Price Average Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleStockPriceAverageMessage ==
    \A message \in CheckedSimpleStockPriceAverageMessage :
        LET read == DecodeSimpleStockPriceAverageMessage(EncodeSimpleStockPriceAverageMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Weighted Stock Price Average decodes back to what was encoded, and leaves nothing over *)
RoundTripWeightedStockPriceAverage ==
    \A message \in CheckedWeightedStockPriceAverage :
        LET read == DecodeWeightedStockPriceAverage(EncodeWeightedStockPriceAverage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Price Average Day On Day Comparison decodes back to what was encoded, and leaves nothing over *)
RoundTripStockPriceAverageDayOnDayComparison2 ==
    \A message \in CheckedStockPriceAverageDayOnDayComparison2 :
        LET read == DecodeStockPriceAverageDayOnDayComparison2(EncodeStockPriceAverageDayOnDayComparison2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Weighted Stock Price Average Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWeightedStockPriceAverageMessage ==
    \A message \in CheckedWeightedStockPriceAverageMessage :
        LET read == DecodeWeightedStockPriceAverageMessage(EncodeWeightedStockPriceAverageMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Stock Price Average decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleStockPriceAverage2 ==
    \A message \in CheckedSimpleStockPriceAverage2 :
        LET read == DecodeSimpleStockPriceAverage2(EncodeSimpleStockPriceAverage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Price Average Day On Day Comparison decodes back to what was encoded, and leaves nothing over *)
RoundTripStockPriceAverageDayOnDayComparison3 ==
    \A message \in CheckedStockPriceAverageDayOnDayComparison3 :
        LET read == DecodeStockPriceAverageDayOnDayComparison3(EncodeStockPriceAverageDayOnDayComparison3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Stock Price Average By Industry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleStockPriceAverageByIndustryMessage ==
    \A message \in CheckedSimpleStockPriceAverageByIndustryMessage :
        LET read == DecodeSimpleStockPriceAverageByIndustryMessage(EncodeSimpleStockPriceAverageByIndustryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Overall Simple Average decodes back to what was encoded, and leaves nothing over *)
RoundTripOverallSimpleAverage ==
    \A message \in CheckedOverallSimpleAverage :
        LET read == DecodeOverallSimpleAverage(EncodeOverallSimpleAverage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Overall Divergence Average decodes back to what was encoded, and leaves nothing over *)
RoundTripOverallDivergenceAverage ==
    \A message \in CheckedOverallDivergenceAverage :
        LET read == DecodeOverallDivergenceAverage(EncodeOverallDivergenceAverage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Overall Parity Average decodes back to what was encoded, and leaves nothing over *)
RoundTripOverallParityAverage ==
    \A message \in CheckedOverallParityAverage :
        LET read == DecodeOverallParityAverage(EncodeOverallParityAverage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Overall Direct Yield Average decodes back to what was encoded, and leaves nothing over *)
RoundTripOverallDirectYieldAverage ==
    \A message \in CheckedOverallDirectYieldAverage :
        LET read == DecodeOverallDirectYieldAverage(EncodeOverallDirectYieldAverage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Overall decodes back to what was encoded, and leaves nothing over *)
RoundTripOverall ==
    \A message \in CheckedOverall :
        LET read == DecodeOverall(EncodeOverall(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Average decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleAverage ==
    \A message \in CheckedSimpleAverage :
        LET read == DecodeSimpleAverage(EncodeSimpleAverage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Divergence Average decodes back to what was encoded, and leaves nothing over *)
RoundTripDivergenceAverage ==
    \A message \in CheckedDivergenceAverage :
        LET read == DecodeDivergenceAverage(EncodeDivergenceAverage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parity Average decodes back to what was encoded, and leaves nothing over *)
RoundTripParityAverage ==
    \A message \in CheckedParityAverage :
        LET read == DecodeParityAverage(EncodeParityAverage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Direct Yield Average decodes back to what was encoded, and leaves nothing over *)
RoundTripDirectYieldAverage ==
    \A message \in CheckedDirectYieldAverage :
        LET read == DecodeDirectYieldAverage(EncodeDirectYieldAverage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parity 100 Or Higher decodes back to what was encoded, and leaves nothing over *)
RoundTripParity100OrHigher ==
    \A message \in CheckedParity100OrHigher :
        LET read == DecodeParity100OrHigher(EncodeParity100OrHigher(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Average decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleAverage2 ==
    \A message \in CheckedSimpleAverage2 :
        LET read == DecodeSimpleAverage2(EncodeSimpleAverage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Divergence Average decodes back to what was encoded, and leaves nothing over *)
RoundTripDivergenceAverage2 ==
    \A message \in CheckedDivergenceAverage2 :
        LET read == DecodeDivergenceAverage2(EncodeDivergenceAverage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parity Average decodes back to what was encoded, and leaves nothing over *)
RoundTripParityAverage2 ==
    \A message \in CheckedParityAverage2 :
        LET read == DecodeParityAverage2(EncodeParityAverage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Direct Yield Average decodes back to what was encoded, and leaves nothing over *)
RoundTripDirectYieldAverage2 ==
    \A message \in CheckedDirectYieldAverage2 :
        LET read == DecodeDirectYieldAverage2(EncodeDirectYieldAverage2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parity Less Than 100 decodes back to what was encoded, and leaves nothing over *)
RoundTripParityLessThan100 ==
    \A message \in CheckedParityLessThan100 :
        LET read == DecodeParityLessThan100(EncodeParityLessThan100(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Japanese Yen Cb Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripJapaneseYenCbIndicatorMessage ==
    \A message \in CheckedJapaneseYenCbIndicatorMessage :
        LET read == DecodeJapaneseYenCbIndicatorMessage(EncodeJapaneseYenCbIndicatorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Number Of Active Issues decodes back to what was encoded, and leaves nothing over *)
RoundTripNumberOfActiveIssues ==
    \A message \in CheckedNumberOfActiveIssues :
        LET read == DecodeNumberOfActiveIssues(EncodeNumberOfActiveIssues(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Number Of Gainers decodes back to what was encoded, and leaves nothing over *)
RoundTripNumberOfGainers ==
    \A message \in CheckedNumberOfGainers :
        LET read == DecodeNumberOfGainers(EncodeNumberOfGainers(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Number Of Decliners decodes back to what was encoded, and leaves nothing over *)
RoundTripNumberOfDecliners ==
    \A message \in CheckedNumberOfDecliners :
        LET read == DecodeNumberOfDecliners(EncodeNumberOfDecliners(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Number Of Issues With No Change decodes back to what was encoded, and leaves nothing over *)
RoundTripNumberOfIssuesWithNoChange ==
    \A message \in CheckedNumberOfIssuesWithNoChange :
        LET read == DecodeNumberOfIssuesWithNoChange(EncodeNumberOfIssuesWithNoChange(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Number Of Issues With No Comparison decodes back to what was encoded, and leaves nothing over *)
RoundTripNumberOfIssuesWithNoComparison ==
    \A message \in CheckedNumberOfIssuesWithNoComparison :
        LET read == DecodeNumberOfIssuesWithNoComparison(EncodeNumberOfIssuesWithNoComparison(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Number Of Inactive Issues decodes back to what was encoded, and leaves nothing over *)
RoundTripNumberOfInactiveIssues ==
    \A message \in CheckedNumberOfInactiveIssues :
        LET read == DecodeNumberOfInactiveIssues(EncodeNumberOfInactiveIssues(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Number Of Gainers Decliners Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNumberOfGainersDeclinersMessage ==
    \A message \in CheckedNumberOfGainersDeclinersMessage :
        LET read == DecodeNumberOfGainersDeclinersMessage(EncodeNumberOfGainersDeclinersMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Estimated Total Trading Volume decodes back to what was encoded, and leaves nothing over *)
RoundTripEstimatedTotalTradingVolume ==
    \A message \in CheckedEstimatedTotalTradingVolume :
        LET read == DecodeEstimatedTotalTradingVolume(EncodeEstimatedTotalTradingVolume(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Estimated Total Trading Volume Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEstimatedTotalTradingVolumeMessage ==
    \A message \in CheckedEstimatedTotalTradingVolumeMessage :
        LET read == DecodeEstimatedTotalTradingVolumeMessage(EncodeEstimatedTotalTradingVolumeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Estimated Total Turnover decodes back to what was encoded, and leaves nothing over *)
RoundTripEstimatedTotalTurnover ==
    \A message \in CheckedEstimatedTotalTurnover :
        LET read == DecodeEstimatedTotalTurnover(EncodeEstimatedTotalTurnover(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Estimated Total Turnover Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEstimatedTotalTurnoverMessage ==
    \A message \in CheckedEstimatedTotalTurnoverMessage :
        LET read == DecodeEstimatedTotalTurnoverMessage(EncodeEstimatedTotalTurnoverMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Vwap By Market decodes back to what was encoded, and leaves nothing over *)
RoundTripVwapByMarket ==
    \A message \in CheckedVwapByMarket :
        LET read == DecodeVwapByMarket(EncodeVwapByMarket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Vwap By Market Message decodes back to what was encoded, and leaves nothing over *)
RoundTripVwapByMarketMessage ==
    \A message \in CheckedVwapByMarketMessage :
        LET read == DecodeVwapByMarketMessage(EncodeVwapByMarketMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Rank By Trading Volume decodes back to what was encoded, and leaves nothing over *)
RoundTripTopRankByTradingVolume ==
    \A message \in CheckedTopRankByTradingVolume :
        LET read == DecodeTopRankByTradingVolume(EncodeTopRankByTradingVolume(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ranking By Trading Volume Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRankingByTradingVolumeMessage ==
    \A message \in CheckedRankingByTradingVolumeMessage :
        LET read == DecodeRankingByTradingVolumeMessage(EncodeRankingByTradingVolumeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Rank By Turnover decodes back to what was encoded, and leaves nothing over *)
RoundTripTopRankByTurnover ==
    \A message \in CheckedTopRankByTurnover :
        LET read == DecodeTopRankByTurnover(EncodeTopRankByTurnover(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ranking By Turnover Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRankingByTurnoverMessage ==
    \A message \in CheckedRankingByTurnoverMessage :
        LET read == DecodeRankingByTurnoverMessage(EncodeRankingByTurnoverMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Rank By Net Change decodes back to what was encoded, and leaves nothing over *)
RoundTripTopRankByNetChange ==
    \A message \in CheckedTopRankByNetChange :
        LET read == DecodeTopRankByNetChange(EncodeTopRankByNetChange(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ranking By Net Change Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRankingByNetChangeMessage ==
    \A message \in CheckedRankingByNetChangeMessage :
        LET read == DecodeRankingByNetChangeMessage(EncodeRankingByNetChangeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Rank By Net Change Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripTopRankByNetChangeRate ==
    \A message \in CheckedTopRankByNetChangeRate :
        LET read == DecodeTopRankByNetChangeRate(EncodeTopRankByNetChangeRate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ranking By Net Change Rate Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRankingByNetChangeRateMessage ==
    \A message \in CheckedRankingByNetChangeRateMessage :
        LET read == DecodeRankingByNetChangeRateMessage(EncodeRankingByNetChangeRateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Volume decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingVolume ==
    \A message \in CheckedTradingVolume :
        LET read == DecodeTradingVolume(EncodeTradingVolume(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Turnover decodes back to what was encoded, and leaves nothing over *)
RoundTripTurnover ==
    \A message \in CheckedTurnover :
        LET read == DecodeTurnover(EncodeTurnover(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Number Of Transactions decodes back to what was encoded, and leaves nothing over *)
RoundTripNumberOfTransactions ==
    \A message \in CheckedNumberOfTransactions :
        LET read == DecodeNumberOfTransactions(EncodeNumberOfTransactions(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every ToSTNeT Statistics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTostnetStatisticsMessage ==
    \A message \in CheckedTostnetStatisticsMessage :
        LET read == DecodeTostnetStatisticsMessage(EncodeTostnetStatisticsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open decodes back to what was encoded, and leaves nothing over *)
RoundTripOpen ==
    \A message \in CheckedOpen :
        LET read == DecodeOpen(EncodeOpen(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Highest decodes back to what was encoded, and leaves nothing over *)
RoundTripHighest ==
    \A message \in CheckedHighest :
        LET read == DecodeHighest(EncodeHighest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lowest decodes back to what was encoded, and leaves nothing over *)
RoundTripLowest ==
    \A message \in CheckedLowest :
        LET read == DecodeLowest(EncodeLowest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Current Price decodes back to what was encoded, and leaves nothing over *)
RoundTripCurrentPrice ==
    \A message \in CheckedCurrentPrice :
        LET read == DecodeCurrentPrice(EncodeCurrentPrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Day On Day Comparison decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexDayOnDayComparison ==
    \A message \in CheckedIndexDayOnDayComparison :
        LET read == DecodeIndexDayOnDayComparison(EncodeIndexDayOnDayComparison(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Open High Low And Closing Prices Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexOpenHighLowAndClosingPricesMessage ==
    \A message \in CheckedIndexOpenHighLowAndClosingPricesMessage :
        LET read == DecodeIndexOpenHighLowAndClosingPricesMessage(EncodeIndexOpenHighLowAndClosingPricesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index decodes back to what was encoded, and leaves nothing over *)
RoundTripIndex ==
    \A message \in CheckedIndex :
        LET read == DecodeIndex(EncodeIndex(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Special Quotation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpecialQuotationMessage ==
    \A message \in CheckedSpecialQuotationMessage :
        LET read == DecodeSpecialQuotationMessage(EncodeSpecialQuotationMessage(message))
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
