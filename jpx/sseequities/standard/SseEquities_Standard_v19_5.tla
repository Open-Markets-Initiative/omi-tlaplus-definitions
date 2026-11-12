-------------------- MODULE SseEquities_Standard_v19_5 ---------------------
(***************************************************************************)
(* Japan Exchange Group Standard v19.5                                     *)
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
(* fields, and since every reading of it takes at least 11 bytes off the   *)
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
(* Update No Message: 8 bytes                                              *)
(***************************************************************************)

UpdateNoMessage ==
    [ updateNo : Sample(8) ]

EncodeUpdateNoMessage(message) ==
    message.updateNo

DecodeUpdateNoMessage(bytes) ==
    LET updateNo == ReadBytes(bytes, 8) IN IF ~updateNo.ok THEN Fail ELSE
    Ok([ updateNo |-> updateNo.value ], updateNo.rest)

ZeroUpdateNoMessage ==
    [ updateNo |-> [i \in 1 .. 8 |-> 0] ]

(* Update No Message at zero, then each field in turn at the values it is checked at *)
CheckedUpdateNoMessage ==
    { ZeroUpdateNoMessage }
        \cup { [ZeroUpdateNoMessage EXCEPT !.updateNo = one] : one \in Sample(8) }

(***************************************************************************)
(* Status Information: 5 bytes                                             *)
(***************************************************************************)

StatusInformation ==
    [ issueStatus                : Sample(2),
      statusFlag                 : Sample(2),
      shortSellingRegulationFlag : Sample(1) ]

EncodeStatusInformation(message) ==
    message.issueStatus
        \o message.statusFlag
        \o message.shortSellingRegulationFlag

DecodeStatusInformation(bytes) ==
    LET issueStatus == ReadBytes(bytes, 2) IN IF ~issueStatus.ok THEN Fail ELSE
    LET statusFlag == ReadBytes(issueStatus.rest, 2) IN IF ~statusFlag.ok THEN Fail ELSE
    LET shortSellingRegulationFlag == ReadBytes(statusFlag.rest, 1) IN IF ~shortSellingRegulationFlag.ok THEN Fail ELSE
    Ok([ issueStatus                |-> issueStatus.value,
         statusFlag                 |-> statusFlag.value,
         shortSellingRegulationFlag |-> shortSellingRegulationFlag.value ], shortSellingRegulationFlag.rest)

ZeroStatusInformation ==
    [ issueStatus                |-> [i \in 1 .. 2 |-> 0],
      statusFlag                 |-> [i \in 1 .. 2 |-> 0],
      shortSellingRegulationFlag |-> [i \in 1 .. 1 |-> 0] ]

(* Status Information at zero, then each field in turn at the values it is checked at *)
CheckedStatusInformation ==
    { ZeroStatusInformation }
        \cup { [ZeroStatusInformation EXCEPT !.issueStatus = one] : one \in Sample(2) }
        \cup { [ZeroStatusInformation EXCEPT !.statusFlag = one] : one \in Sample(2) }
        \cup { [ZeroStatusInformation EXCEPT !.shortSellingRegulationFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Status Information Message: 24 bytes                                    *)
(***************************************************************************)

StatusInformationMessage ==
    [ reserved2         : Sample(2),
      changeFlag        : Sample(1),
      statusInformation : StatusInformation,
      timeC12           : Sample(12),
      reserved4         : Sample(4) ]

EncodeStatusInformationMessage(message) ==
    message.reserved2
        \o message.changeFlag
        \o EncodeStatusInformation(message.statusInformation)
        \o message.timeC12
        \o message.reserved4

DecodeStatusInformationMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET changeFlag == ReadBytes(reserved2.rest, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET statusInformation == DecodeStatusInformation(changeFlag.rest) IN IF ~statusInformation.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(statusInformation.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(timeC12.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    Ok([ reserved2         |-> reserved2.value,
         changeFlag        |-> changeFlag.value,
         statusInformation |-> statusInformation.value,
         timeC12           |-> timeC12.value,
         reserved4         |-> reserved4.value ], reserved4.rest)

ZeroStatusInformationMessage ==
    [ reserved2         |-> [i \in 1 .. 2 |-> 0],
      changeFlag        |-> [i \in 1 .. 1 |-> 0],
      statusInformation |-> ZeroStatusInformation,
      timeC12           |-> [i \in 1 .. 12 |-> 0],
      reserved4         |-> [i \in 1 .. 4 |-> 0] ]

(* Status Information Message at zero, then each field in turn at the values it is checked at *)
CheckedStatusInformationMessage ==
    { ZeroStatusInformationMessage }
        \cup { [ZeroStatusInformationMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroStatusInformationMessage EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroStatusInformationMessage EXCEPT !.statusInformation = one] : one \in CheckedStatusInformation }
        \cup { [ZeroStatusInformationMessage EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroStatusInformationMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice ==
    { ZeroPrice }
        \cup { [ZeroPrice EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Open: 23 bytes                                                          *)
(***************************************************************************)

Open ==
    [ price      : Price,
      timeC6     : Sample(6),
      changeFlag : Sample(1) ]

EncodeOpen(message) ==
    EncodePrice(message.price)
        \o message.timeC6
        \o message.changeFlag

DecodeOpen(bytes) ==
    LET price == DecodePrice(bytes) IN IF ~price.ok THEN Fail ELSE
    LET timeC6 == ReadBytes(price.rest, 6) IN IF ~timeC6.ok THEN Fail ELSE
    LET changeFlag == ReadBytes(timeC6.rest, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    Ok([ price      |-> price.value,
         timeC6     |-> timeC6.value,
         changeFlag |-> changeFlag.value ], changeFlag.rest)

ZeroOpen ==
    [ price      |-> ZeroPrice,
      timeC6     |-> [i \in 1 .. 6 |-> 0],
      changeFlag |-> [i \in 1 .. 1 |-> 0] ]

(* Open at zero, then each field in turn at the values it is checked at *)
CheckedOpen ==
    { ZeroOpen }
        \cup { [ZeroOpen EXCEPT !.price = one] : one \in CheckedPrice }
        \cup { [ZeroOpen EXCEPT !.timeC6 = one] : one \in Sample(6) }
        \cup { [ZeroOpen EXCEPT !.changeFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price2 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice2(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice2(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice2 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice2 ==
    { ZeroPrice2 }
        \cup { [ZeroPrice2 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice2 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice2 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* High: 24 bytes                                                          *)
(***************************************************************************)

High ==
    [ limitUpFlag : Sample(1),
      price       : Price2,
      timeC6      : Sample(6),
      changeFlag  : Sample(1) ]

EncodeHigh(message) ==
    message.limitUpFlag
        \o EncodePrice2(message.price)
        \o message.timeC6
        \o message.changeFlag

DecodeHigh(bytes) ==
    LET limitUpFlag == ReadBytes(bytes, 1) IN IF ~limitUpFlag.ok THEN Fail ELSE
    LET price == DecodePrice2(limitUpFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC6 == ReadBytes(price.rest, 6) IN IF ~timeC6.ok THEN Fail ELSE
    LET changeFlag == ReadBytes(timeC6.rest, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    Ok([ limitUpFlag |-> limitUpFlag.value,
         price       |-> price.value,
         timeC6      |-> timeC6.value,
         changeFlag  |-> changeFlag.value ], changeFlag.rest)

ZeroHigh ==
    [ limitUpFlag |-> [i \in 1 .. 1 |-> 0],
      price       |-> ZeroPrice2,
      timeC6      |-> [i \in 1 .. 6 |-> 0],
      changeFlag  |-> [i \in 1 .. 1 |-> 0] ]

(* High at zero, then each field in turn at the values it is checked at *)
CheckedHigh ==
    { ZeroHigh }
        \cup { [ZeroHigh EXCEPT !.limitUpFlag = one] : one \in Sample(1) }
        \cup { [ZeroHigh EXCEPT !.price = one] : one \in CheckedPrice2 }
        \cup { [ZeroHigh EXCEPT !.timeC6 = one] : one \in Sample(6) }
        \cup { [ZeroHigh EXCEPT !.changeFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price3 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice3(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice3(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice3 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice3 ==
    { ZeroPrice3 }
        \cup { [ZeroPrice3 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice3 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice3 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Low: 24 bytes                                                           *)
(***************************************************************************)

Low ==
    [ limitDownFlag : Sample(1),
      price         : Price3,
      timeC6        : Sample(6),
      changeFlag    : Sample(1) ]

EncodeLow(message) ==
    message.limitDownFlag
        \o EncodePrice3(message.price)
        \o message.timeC6
        \o message.changeFlag

DecodeLow(bytes) ==
    LET limitDownFlag == ReadBytes(bytes, 1) IN IF ~limitDownFlag.ok THEN Fail ELSE
    LET price == DecodePrice3(limitDownFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC6 == ReadBytes(price.rest, 6) IN IF ~timeC6.ok THEN Fail ELSE
    LET changeFlag == ReadBytes(timeC6.rest, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    Ok([ limitDownFlag |-> limitDownFlag.value,
         price         |-> price.value,
         timeC6        |-> timeC6.value,
         changeFlag    |-> changeFlag.value ], changeFlag.rest)

ZeroLow ==
    [ limitDownFlag |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice3,
      timeC6        |-> [i \in 1 .. 6 |-> 0],
      changeFlag    |-> [i \in 1 .. 1 |-> 0] ]

(* Low at zero, then each field in turn at the values it is checked at *)
CheckedLow ==
    { ZeroLow }
        \cup { [ZeroLow EXCEPT !.limitDownFlag = one] : one \in Sample(1) }
        \cup { [ZeroLow EXCEPT !.price = one] : one \in CheckedPrice3 }
        \cup { [ZeroLow EXCEPT !.timeC6 = one] : one \in Sample(6) }
        \cup { [ZeroLow EXCEPT !.changeFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price4 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice4(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice4(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice4 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice4 ==
    { ZeroPrice4 }
        \cup { [ZeroPrice4 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice4 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice4 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Current: 32 bytes                                                       *)
(***************************************************************************)

Current ==
    [ price                 : Price4,
      timeC12               : Sample(12),
      currentChangeFlag     : Sample(1),
      stqReferencePointFlag : Sample(1),
      reserved1             : Sample(1),
      closingPriceInputFlag : Sample(1) ]

EncodeCurrent(message) ==
    EncodePrice4(message.price)
        \o message.timeC12
        \o message.currentChangeFlag
        \o message.stqReferencePointFlag
        \o message.reserved1
        \o message.closingPriceInputFlag

DecodeCurrent(bytes) ==
    LET price == DecodePrice4(bytes) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET currentChangeFlag == ReadBytes(timeC12.rest, 1) IN IF ~currentChangeFlag.ok THEN Fail ELSE
    LET stqReferencePointFlag == ReadBytes(currentChangeFlag.rest, 1) IN IF ~stqReferencePointFlag.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(stqReferencePointFlag.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET closingPriceInputFlag == ReadBytes(reserved1.rest, 1) IN IF ~closingPriceInputFlag.ok THEN Fail ELSE
    Ok([ price                 |-> price.value,
         timeC12               |-> timeC12.value,
         currentChangeFlag     |-> currentChangeFlag.value,
         stqReferencePointFlag |-> stqReferencePointFlag.value,
         reserved1             |-> reserved1.value,
         closingPriceInputFlag |-> closingPriceInputFlag.value ], closingPriceInputFlag.rest)

ZeroCurrent ==
    [ price                 |-> ZeroPrice4,
      timeC12               |-> [i \in 1 .. 12 |-> 0],
      currentChangeFlag     |-> [i \in 1 .. 1 |-> 0],
      stqReferencePointFlag |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      closingPriceInputFlag |-> [i \in 1 .. 1 |-> 0] ]

(* Current at zero, then each field in turn at the values it is checked at *)
CheckedCurrent ==
    { ZeroCurrent }
        \cup { [ZeroCurrent EXCEPT !.price = one] : one \in CheckedPrice4 }
        \cup { [ZeroCurrent EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroCurrent EXCEPT !.currentChangeFlag = one] : one \in Sample(1) }
        \cup { [ZeroCurrent EXCEPT !.stqReferencePointFlag = one] : one \in Sample(1) }
        \cup { [ZeroCurrent EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroCurrent EXCEPT !.closingPriceInputFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Open High Low And Current Price Message: 105 bytes                      *)
(***************************************************************************)

OpenHighLowAndCurrentPriceMessage ==
    [ reserved2 : Sample(2),
      open      : Open,
      high      : High,
      low       : Low,
      current   : Current ]

EncodeOpenHighLowAndCurrentPriceMessage(message) ==
    message.reserved2
        \o EncodeOpen(message.open)
        \o EncodeHigh(message.high)
        \o EncodeLow(message.low)
        \o EncodeCurrent(message.current)

DecodeOpenHighLowAndCurrentPriceMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET open == DecodeOpen(reserved2.rest) IN IF ~open.ok THEN Fail ELSE
    LET high == DecodeHigh(open.rest) IN IF ~high.ok THEN Fail ELSE
    LET low == DecodeLow(high.rest) IN IF ~low.ok THEN Fail ELSE
    LET current == DecodeCurrent(low.rest) IN IF ~current.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         open      |-> open.value,
         high      |-> high.value,
         low       |-> low.value,
         current   |-> current.value ], current.rest)

ZeroOpenHighLowAndCurrentPriceMessage ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      open      |-> ZeroOpen,
      high      |-> ZeroHigh,
      low       |-> ZeroLow,
      current   |-> ZeroCurrent ]

(* Open High Low And Current Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenHighLowAndCurrentPriceMessage ==
    { ZeroOpenHighLowAndCurrentPriceMessage }
        \cup { [ZeroOpenHighLowAndCurrentPriceMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOpenHighLowAndCurrentPriceMessage EXCEPT !.open = one] : one \in CheckedOpen }
        \cup { [ZeroOpenHighLowAndCurrentPriceMessage EXCEPT !.high = one] : one \in CheckedHigh }
        \cup { [ZeroOpenHighLowAndCurrentPriceMessage EXCEPT !.low = one] : one \in CheckedLow }
        \cup { [ZeroOpenHighLowAndCurrentPriceMessage EXCEPT !.current = one] : one \in CheckedCurrent }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price5 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice5(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice5(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice5 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice5 ==
    { ZeroPrice5 }
        \cup { [ZeroPrice5 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice5 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice5 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity ==
    { ZeroQuoteQuantity }
        \cup { [ZeroQuoteQuantity EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Ask Quote: 46 bytes                                                     *)
(***************************************************************************)

AskQuote ==
    [ changeFlag    : Sample(1),
      price         : Price5,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity ]

EncodeAskQuote(message) ==
    message.changeFlag
        \o EncodePrice5(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity(message.quoteQuantity)

DecodeAskQuote(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice5(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroAskQuote ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice5,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity ]

(* Ask Quote at zero, then each field in turn at the values it is checked at *)
CheckedAskQuote ==
    { ZeroAskQuote }
        \cup { [ZeroAskQuote EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote EXCEPT !.price = one] : one \in CheckedPrice5 }
        \cup { [ZeroAskQuote EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroAskQuote EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price6 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice6(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice6(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice6 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice6 ==
    { ZeroPrice6 }
        \cup { [ZeroPrice6 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice6 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice6 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity2 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity2(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity2(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity2 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity2 ==
    { ZeroQuoteQuantity2 }
        \cup { [ZeroQuoteQuantity2 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity2 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity2 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Bid Quote: 46 bytes                                                     *)
(***************************************************************************)

BidQuote ==
    [ changeFlag    : Sample(1),
      price         : Price6,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity2 ]

EncodeBidQuote(message) ==
    message.changeFlag
        \o EncodePrice6(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity2(message.quoteQuantity)

DecodeBidQuote(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice6(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity2(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroBidQuote ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice6,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity2 ]

(* Bid Quote at zero, then each field in turn at the values it is checked at *)
CheckedBidQuote ==
    { ZeroBidQuote }
        \cup { [ZeroBidQuote EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote EXCEPT !.price = one] : one \in CheckedPrice6 }
        \cup { [ZeroBidQuote EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroBidQuote EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity2 }

(***************************************************************************)
(* Quote 1 Message: 94 bytes                                               *)
(***************************************************************************)

Quote1Message ==
    [ reserved2 : Sample(2),
      askQuote  : AskQuote,
      bidQuote  : BidQuote ]

EncodeQuote1Message(message) ==
    message.reserved2
        \o EncodeAskQuote(message.askQuote)
        \o EncodeBidQuote(message.bidQuote)

DecodeQuote1Message(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET askQuote == DecodeAskQuote(reserved2.rest) IN IF ~askQuote.ok THEN Fail ELSE
    LET bidQuote == DecodeBidQuote(askQuote.rest) IN IF ~bidQuote.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         askQuote  |-> askQuote.value,
         bidQuote  |-> bidQuote.value ], bidQuote.rest)

ZeroQuote1Message ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      askQuote  |-> ZeroAskQuote,
      bidQuote  |-> ZeroBidQuote ]

(* Quote 1 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuote1Message ==
    { ZeroQuote1Message }
        \cup { [ZeroQuote1Message EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroQuote1Message EXCEPT !.askQuote = one] : one \in CheckedAskQuote }
        \cup { [ZeroQuote1Message EXCEPT !.bidQuote = one] : one \in CheckedBidQuote }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price7 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice7(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice7(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice7 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice7 ==
    { ZeroPrice7 }
        \cup { [ZeroPrice7 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice7 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice7 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity3 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity3(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity3(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity3 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity3 ==
    { ZeroQuoteQuantity3 }
        \cup { [ZeroQuoteQuantity3 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity3 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity3 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Ask Quote: 46 bytes                                                     *)
(***************************************************************************)

AskQuote2 ==
    [ changeFlag    : Sample(1),
      price         : Price7,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity3 ]

EncodeAskQuote2(message) ==
    message.changeFlag
        \o EncodePrice7(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity3(message.quoteQuantity)

DecodeAskQuote2(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice7(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity3(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroAskQuote2 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice7,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity3 ]

(* Ask Quote at zero, then each field in turn at the values it is checked at *)
CheckedAskQuote2 ==
    { ZeroAskQuote2 }
        \cup { [ZeroAskQuote2 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote2 EXCEPT !.price = one] : one \in CheckedPrice7 }
        \cup { [ZeroAskQuote2 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroAskQuote2 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote2 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity3 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price8 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice8(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice8(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice8 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice8 ==
    { ZeroPrice8 }
        \cup { [ZeroPrice8 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice8 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice8 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity4 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity4(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity4(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity4 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity4 ==
    { ZeroQuoteQuantity4 }
        \cup { [ZeroQuoteQuantity4 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity4 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity4 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Bid Quote: 46 bytes                                                     *)
(***************************************************************************)

BidQuote2 ==
    [ changeFlag    : Sample(1),
      price         : Price8,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity4 ]

EncodeBidQuote2(message) ==
    message.changeFlag
        \o EncodePrice8(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity4(message.quoteQuantity)

DecodeBidQuote2(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice8(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity4(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroBidQuote2 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice8,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity4 ]

(* Bid Quote at zero, then each field in turn at the values it is checked at *)
CheckedBidQuote2 ==
    { ZeroBidQuote2 }
        \cup { [ZeroBidQuote2 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote2 EXCEPT !.price = one] : one \in CheckedPrice8 }
        \cup { [ZeroBidQuote2 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroBidQuote2 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote2 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity4 }

(***************************************************************************)
(* Quote 2 Message: 94 bytes                                               *)
(***************************************************************************)

Quote2Message ==
    [ reserved2 : Sample(2),
      askQuote  : AskQuote2,
      bidQuote  : BidQuote2 ]

EncodeQuote2Message(message) ==
    message.reserved2
        \o EncodeAskQuote2(message.askQuote)
        \o EncodeBidQuote2(message.bidQuote)

DecodeQuote2Message(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET askQuote == DecodeAskQuote2(reserved2.rest) IN IF ~askQuote.ok THEN Fail ELSE
    LET bidQuote == DecodeBidQuote2(askQuote.rest) IN IF ~bidQuote.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         askQuote  |-> askQuote.value,
         bidQuote  |-> bidQuote.value ], bidQuote.rest)

ZeroQuote2Message ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      askQuote  |-> ZeroAskQuote2,
      bidQuote  |-> ZeroBidQuote2 ]

(* Quote 2 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuote2Message ==
    { ZeroQuote2Message }
        \cup { [ZeroQuote2Message EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroQuote2Message EXCEPT !.askQuote = one] : one \in CheckedAskQuote2 }
        \cup { [ZeroQuote2Message EXCEPT !.bidQuote = one] : one \in CheckedBidQuote2 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price9 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice9(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice9(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice9 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice9 ==
    { ZeroPrice9 }
        \cup { [ZeroPrice9 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice9 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice9 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity5 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity5(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity5(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity5 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity5 ==
    { ZeroQuoteQuantity5 }
        \cup { [ZeroQuoteQuantity5 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity5 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity5 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Ask Quote: 46 bytes                                                     *)
(***************************************************************************)

AskQuote3 ==
    [ changeFlag    : Sample(1),
      price         : Price9,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity5 ]

EncodeAskQuote3(message) ==
    message.changeFlag
        \o EncodePrice9(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity5(message.quoteQuantity)

DecodeAskQuote3(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice9(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity5(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroAskQuote3 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice9,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity5 ]

(* Ask Quote at zero, then each field in turn at the values it is checked at *)
CheckedAskQuote3 ==
    { ZeroAskQuote3 }
        \cup { [ZeroAskQuote3 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote3 EXCEPT !.price = one] : one \in CheckedPrice9 }
        \cup { [ZeroAskQuote3 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroAskQuote3 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote3 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity5 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price10 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice10(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice10(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice10 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice10 ==
    { ZeroPrice10 }
        \cup { [ZeroPrice10 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice10 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice10 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity6 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity6(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity6(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity6 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity6 ==
    { ZeroQuoteQuantity6 }
        \cup { [ZeroQuoteQuantity6 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity6 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity6 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Bid Quote: 46 bytes                                                     *)
(***************************************************************************)

BidQuote3 ==
    [ changeFlag    : Sample(1),
      price         : Price10,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity6 ]

EncodeBidQuote3(message) ==
    message.changeFlag
        \o EncodePrice10(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity6(message.quoteQuantity)

DecodeBidQuote3(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice10(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity6(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroBidQuote3 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice10,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity6 ]

(* Bid Quote at zero, then each field in turn at the values it is checked at *)
CheckedBidQuote3 ==
    { ZeroBidQuote3 }
        \cup { [ZeroBidQuote3 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote3 EXCEPT !.price = one] : one \in CheckedPrice10 }
        \cup { [ZeroBidQuote3 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroBidQuote3 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote3 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity6 }

(***************************************************************************)
(* Quote 3 Message: 94 bytes                                               *)
(***************************************************************************)

Quote3Message ==
    [ reserved2 : Sample(2),
      askQuote  : AskQuote3,
      bidQuote  : BidQuote3 ]

EncodeQuote3Message(message) ==
    message.reserved2
        \o EncodeAskQuote3(message.askQuote)
        \o EncodeBidQuote3(message.bidQuote)

DecodeQuote3Message(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET askQuote == DecodeAskQuote3(reserved2.rest) IN IF ~askQuote.ok THEN Fail ELSE
    LET bidQuote == DecodeBidQuote3(askQuote.rest) IN IF ~bidQuote.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         askQuote  |-> askQuote.value,
         bidQuote  |-> bidQuote.value ], bidQuote.rest)

ZeroQuote3Message ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      askQuote  |-> ZeroAskQuote3,
      bidQuote  |-> ZeroBidQuote3 ]

(* Quote 3 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuote3Message ==
    { ZeroQuote3Message }
        \cup { [ZeroQuote3Message EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroQuote3Message EXCEPT !.askQuote = one] : one \in CheckedAskQuote3 }
        \cup { [ZeroQuote3Message EXCEPT !.bidQuote = one] : one \in CheckedBidQuote3 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price11 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice11(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice11(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice11 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice11 ==
    { ZeroPrice11 }
        \cup { [ZeroPrice11 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice11 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice11 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity7 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity7(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity7(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity7 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity7 ==
    { ZeroQuoteQuantity7 }
        \cup { [ZeroQuoteQuantity7 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity7 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity7 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Ask Quote: 46 bytes                                                     *)
(***************************************************************************)

AskQuote4 ==
    [ changeFlag    : Sample(1),
      price         : Price11,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity7 ]

EncodeAskQuote4(message) ==
    message.changeFlag
        \o EncodePrice11(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity7(message.quoteQuantity)

DecodeAskQuote4(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice11(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity7(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroAskQuote4 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice11,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity7 ]

(* Ask Quote at zero, then each field in turn at the values it is checked at *)
CheckedAskQuote4 ==
    { ZeroAskQuote4 }
        \cup { [ZeroAskQuote4 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote4 EXCEPT !.price = one] : one \in CheckedPrice11 }
        \cup { [ZeroAskQuote4 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroAskQuote4 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote4 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity7 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price12 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice12(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice12(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice12 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice12 ==
    { ZeroPrice12 }
        \cup { [ZeroPrice12 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice12 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice12 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity8 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity8(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity8(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity8 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity8 ==
    { ZeroQuoteQuantity8 }
        \cup { [ZeroQuoteQuantity8 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity8 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity8 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Bid Quote: 46 bytes                                                     *)
(***************************************************************************)

BidQuote4 ==
    [ changeFlag    : Sample(1),
      price         : Price12,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity8 ]

EncodeBidQuote4(message) ==
    message.changeFlag
        \o EncodePrice12(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity8(message.quoteQuantity)

DecodeBidQuote4(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice12(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity8(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroBidQuote4 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice12,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity8 ]

(* Bid Quote at zero, then each field in turn at the values it is checked at *)
CheckedBidQuote4 ==
    { ZeroBidQuote4 }
        \cup { [ZeroBidQuote4 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote4 EXCEPT !.price = one] : one \in CheckedPrice12 }
        \cup { [ZeroBidQuote4 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroBidQuote4 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote4 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity8 }

(***************************************************************************)
(* Quote 4 Message: 94 bytes                                               *)
(***************************************************************************)

Quote4Message ==
    [ reserved2 : Sample(2),
      askQuote  : AskQuote4,
      bidQuote  : BidQuote4 ]

EncodeQuote4Message(message) ==
    message.reserved2
        \o EncodeAskQuote4(message.askQuote)
        \o EncodeBidQuote4(message.bidQuote)

DecodeQuote4Message(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET askQuote == DecodeAskQuote4(reserved2.rest) IN IF ~askQuote.ok THEN Fail ELSE
    LET bidQuote == DecodeBidQuote4(askQuote.rest) IN IF ~bidQuote.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         askQuote  |-> askQuote.value,
         bidQuote  |-> bidQuote.value ], bidQuote.rest)

ZeroQuote4Message ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      askQuote  |-> ZeroAskQuote4,
      bidQuote  |-> ZeroBidQuote4 ]

(* Quote 4 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuote4Message ==
    { ZeroQuote4Message }
        \cup { [ZeroQuote4Message EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroQuote4Message EXCEPT !.askQuote = one] : one \in CheckedAskQuote4 }
        \cup { [ZeroQuote4Message EXCEPT !.bidQuote = one] : one \in CheckedBidQuote4 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price13 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice13(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice13(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice13 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice13 ==
    { ZeroPrice13 }
        \cup { [ZeroPrice13 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice13 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice13 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity9 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity9(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity9(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity9 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity9 ==
    { ZeroQuoteQuantity9 }
        \cup { [ZeroQuoteQuantity9 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity9 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity9 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Ask Quote: 46 bytes                                                     *)
(***************************************************************************)

AskQuote5 ==
    [ changeFlag    : Sample(1),
      price         : Price13,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity9 ]

EncodeAskQuote5(message) ==
    message.changeFlag
        \o EncodePrice13(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity9(message.quoteQuantity)

DecodeAskQuote5(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice13(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity9(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroAskQuote5 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice13,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity9 ]

(* Ask Quote at zero, then each field in turn at the values it is checked at *)
CheckedAskQuote5 ==
    { ZeroAskQuote5 }
        \cup { [ZeroAskQuote5 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote5 EXCEPT !.price = one] : one \in CheckedPrice13 }
        \cup { [ZeroAskQuote5 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroAskQuote5 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote5 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity9 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price14 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice14(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice14(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice14 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice14 ==
    { ZeroPrice14 }
        \cup { [ZeroPrice14 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice14 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice14 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity10 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity10(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity10(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity10 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity10 ==
    { ZeroQuoteQuantity10 }
        \cup { [ZeroQuoteQuantity10 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity10 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity10 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Bid Quote: 46 bytes                                                     *)
(***************************************************************************)

BidQuote5 ==
    [ changeFlag    : Sample(1),
      price         : Price14,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity10 ]

EncodeBidQuote5(message) ==
    message.changeFlag
        \o EncodePrice14(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity10(message.quoteQuantity)

DecodeBidQuote5(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice14(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity10(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroBidQuote5 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice14,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity10 ]

(* Bid Quote at zero, then each field in turn at the values it is checked at *)
CheckedBidQuote5 ==
    { ZeroBidQuote5 }
        \cup { [ZeroBidQuote5 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote5 EXCEPT !.price = one] : one \in CheckedPrice14 }
        \cup { [ZeroBidQuote5 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroBidQuote5 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote5 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity10 }

(***************************************************************************)
(* Quote 5 Message: 94 bytes                                               *)
(***************************************************************************)

Quote5Message ==
    [ reserved2 : Sample(2),
      askQuote  : AskQuote5,
      bidQuote  : BidQuote5 ]

EncodeQuote5Message(message) ==
    message.reserved2
        \o EncodeAskQuote5(message.askQuote)
        \o EncodeBidQuote5(message.bidQuote)

DecodeQuote5Message(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET askQuote == DecodeAskQuote5(reserved2.rest) IN IF ~askQuote.ok THEN Fail ELSE
    LET bidQuote == DecodeBidQuote5(askQuote.rest) IN IF ~bidQuote.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         askQuote  |-> askQuote.value,
         bidQuote  |-> bidQuote.value ], bidQuote.rest)

ZeroQuote5Message ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      askQuote  |-> ZeroAskQuote5,
      bidQuote  |-> ZeroBidQuote5 ]

(* Quote 5 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuote5Message ==
    { ZeroQuote5Message }
        \cup { [ZeroQuote5Message EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroQuote5Message EXCEPT !.askQuote = one] : one \in CheckedAskQuote5 }
        \cup { [ZeroQuote5Message EXCEPT !.bidQuote = one] : one \in CheckedBidQuote5 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price15 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice15(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice15(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice15 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice15 ==
    { ZeroPrice15 }
        \cup { [ZeroPrice15 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice15 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice15 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity11 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity11(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity11(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity11 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity11 ==
    { ZeroQuoteQuantity11 }
        \cup { [ZeroQuoteQuantity11 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity11 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity11 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Ask Quote: 46 bytes                                                     *)
(***************************************************************************)

AskQuote6 ==
    [ changeFlag    : Sample(1),
      price         : Price15,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity11 ]

EncodeAskQuote6(message) ==
    message.changeFlag
        \o EncodePrice15(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity11(message.quoteQuantity)

DecodeAskQuote6(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice15(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity11(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroAskQuote6 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice15,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity11 ]

(* Ask Quote at zero, then each field in turn at the values it is checked at *)
CheckedAskQuote6 ==
    { ZeroAskQuote6 }
        \cup { [ZeroAskQuote6 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote6 EXCEPT !.price = one] : one \in CheckedPrice15 }
        \cup { [ZeroAskQuote6 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroAskQuote6 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote6 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity11 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price16 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice16(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice16(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice16 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice16 ==
    { ZeroPrice16 }
        \cup { [ZeroPrice16 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice16 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice16 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity12 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity12(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity12(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity12 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity12 ==
    { ZeroQuoteQuantity12 }
        \cup { [ZeroQuoteQuantity12 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity12 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity12 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Bid Quote: 46 bytes                                                     *)
(***************************************************************************)

BidQuote6 ==
    [ changeFlag    : Sample(1),
      price         : Price16,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity12 ]

EncodeBidQuote6(message) ==
    message.changeFlag
        \o EncodePrice16(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity12(message.quoteQuantity)

DecodeBidQuote6(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice16(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity12(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroBidQuote6 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice16,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity12 ]

(* Bid Quote at zero, then each field in turn at the values it is checked at *)
CheckedBidQuote6 ==
    { ZeroBidQuote6 }
        \cup { [ZeroBidQuote6 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote6 EXCEPT !.price = one] : one \in CheckedPrice16 }
        \cup { [ZeroBidQuote6 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroBidQuote6 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote6 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity12 }

(***************************************************************************)
(* Quote 6 Message: 94 bytes                                               *)
(***************************************************************************)

Quote6Message ==
    [ reserved2 : Sample(2),
      askQuote  : AskQuote6,
      bidQuote  : BidQuote6 ]

EncodeQuote6Message(message) ==
    message.reserved2
        \o EncodeAskQuote6(message.askQuote)
        \o EncodeBidQuote6(message.bidQuote)

DecodeQuote6Message(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET askQuote == DecodeAskQuote6(reserved2.rest) IN IF ~askQuote.ok THEN Fail ELSE
    LET bidQuote == DecodeBidQuote6(askQuote.rest) IN IF ~bidQuote.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         askQuote  |-> askQuote.value,
         bidQuote  |-> bidQuote.value ], bidQuote.rest)

ZeroQuote6Message ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      askQuote  |-> ZeroAskQuote6,
      bidQuote  |-> ZeroBidQuote6 ]

(* Quote 6 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuote6Message ==
    { ZeroQuote6Message }
        \cup { [ZeroQuote6Message EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroQuote6Message EXCEPT !.askQuote = one] : one \in CheckedAskQuote6 }
        \cup { [ZeroQuote6Message EXCEPT !.bidQuote = one] : one \in CheckedBidQuote6 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price17 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice17(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice17(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice17 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice17 ==
    { ZeroPrice17 }
        \cup { [ZeroPrice17 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice17 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice17 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity13 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity13(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity13(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity13 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity13 ==
    { ZeroQuoteQuantity13 }
        \cup { [ZeroQuoteQuantity13 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity13 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity13 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Ask Quote: 46 bytes                                                     *)
(***************************************************************************)

AskQuote7 ==
    [ changeFlag    : Sample(1),
      price         : Price17,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity13 ]

EncodeAskQuote7(message) ==
    message.changeFlag
        \o EncodePrice17(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity13(message.quoteQuantity)

DecodeAskQuote7(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice17(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity13(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroAskQuote7 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice17,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity13 ]

(* Ask Quote at zero, then each field in turn at the values it is checked at *)
CheckedAskQuote7 ==
    { ZeroAskQuote7 }
        \cup { [ZeroAskQuote7 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote7 EXCEPT !.price = one] : one \in CheckedPrice17 }
        \cup { [ZeroAskQuote7 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroAskQuote7 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote7 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity13 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price18 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice18(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice18(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice18 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice18 ==
    { ZeroPrice18 }
        \cup { [ZeroPrice18 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice18 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice18 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity14 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity14(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity14(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity14 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity14 ==
    { ZeroQuoteQuantity14 }
        \cup { [ZeroQuoteQuantity14 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity14 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity14 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Bid Quote: 46 bytes                                                     *)
(***************************************************************************)

BidQuote7 ==
    [ changeFlag    : Sample(1),
      price         : Price18,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity14 ]

EncodeBidQuote7(message) ==
    message.changeFlag
        \o EncodePrice18(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity14(message.quoteQuantity)

DecodeBidQuote7(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice18(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity14(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroBidQuote7 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice18,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity14 ]

(* Bid Quote at zero, then each field in turn at the values it is checked at *)
CheckedBidQuote7 ==
    { ZeroBidQuote7 }
        \cup { [ZeroBidQuote7 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote7 EXCEPT !.price = one] : one \in CheckedPrice18 }
        \cup { [ZeroBidQuote7 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroBidQuote7 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote7 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity14 }

(***************************************************************************)
(* Quote 7 Message: 94 bytes                                               *)
(***************************************************************************)

Quote7Message ==
    [ reserved2 : Sample(2),
      askQuote  : AskQuote7,
      bidQuote  : BidQuote7 ]

EncodeQuote7Message(message) ==
    message.reserved2
        \o EncodeAskQuote7(message.askQuote)
        \o EncodeBidQuote7(message.bidQuote)

DecodeQuote7Message(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET askQuote == DecodeAskQuote7(reserved2.rest) IN IF ~askQuote.ok THEN Fail ELSE
    LET bidQuote == DecodeBidQuote7(askQuote.rest) IN IF ~bidQuote.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         askQuote  |-> askQuote.value,
         bidQuote  |-> bidQuote.value ], bidQuote.rest)

ZeroQuote7Message ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      askQuote  |-> ZeroAskQuote7,
      bidQuote  |-> ZeroBidQuote7 ]

(* Quote 7 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuote7Message ==
    { ZeroQuote7Message }
        \cup { [ZeroQuote7Message EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroQuote7Message EXCEPT !.askQuote = one] : one \in CheckedAskQuote7 }
        \cup { [ZeroQuote7Message EXCEPT !.bidQuote = one] : one \in CheckedBidQuote7 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price19 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice19(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice19(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice19 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice19 ==
    { ZeroPrice19 }
        \cup { [ZeroPrice19 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice19 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice19 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity15 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity15(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity15(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity15 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity15 ==
    { ZeroQuoteQuantity15 }
        \cup { [ZeroQuoteQuantity15 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity15 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity15 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Ask Quote: 46 bytes                                                     *)
(***************************************************************************)

AskQuote8 ==
    [ changeFlag    : Sample(1),
      price         : Price19,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity15 ]

EncodeAskQuote8(message) ==
    message.changeFlag
        \o EncodePrice19(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity15(message.quoteQuantity)

DecodeAskQuote8(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice19(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity15(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroAskQuote8 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice19,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity15 ]

(* Ask Quote at zero, then each field in turn at the values it is checked at *)
CheckedAskQuote8 ==
    { ZeroAskQuote8 }
        \cup { [ZeroAskQuote8 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote8 EXCEPT !.price = one] : one \in CheckedPrice19 }
        \cup { [ZeroAskQuote8 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroAskQuote8 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote8 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity15 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price20 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice20(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice20(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice20 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice20 ==
    { ZeroPrice20 }
        \cup { [ZeroPrice20 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice20 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice20 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity16 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity16(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity16(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity16 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity16 ==
    { ZeroQuoteQuantity16 }
        \cup { [ZeroQuoteQuantity16 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity16 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity16 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Bid Quote: 46 bytes                                                     *)
(***************************************************************************)

BidQuote8 ==
    [ changeFlag    : Sample(1),
      price         : Price20,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity16 ]

EncodeBidQuote8(message) ==
    message.changeFlag
        \o EncodePrice20(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity16(message.quoteQuantity)

DecodeBidQuote8(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice20(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity16(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroBidQuote8 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice20,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity16 ]

(* Bid Quote at zero, then each field in turn at the values it is checked at *)
CheckedBidQuote8 ==
    { ZeroBidQuote8 }
        \cup { [ZeroBidQuote8 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote8 EXCEPT !.price = one] : one \in CheckedPrice20 }
        \cup { [ZeroBidQuote8 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroBidQuote8 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote8 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity16 }

(***************************************************************************)
(* Quote 8 Message: 94 bytes                                               *)
(***************************************************************************)

Quote8Message ==
    [ reserved2 : Sample(2),
      askQuote  : AskQuote8,
      bidQuote  : BidQuote8 ]

EncodeQuote8Message(message) ==
    message.reserved2
        \o EncodeAskQuote8(message.askQuote)
        \o EncodeBidQuote8(message.bidQuote)

DecodeQuote8Message(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET askQuote == DecodeAskQuote8(reserved2.rest) IN IF ~askQuote.ok THEN Fail ELSE
    LET bidQuote == DecodeBidQuote8(askQuote.rest) IN IF ~bidQuote.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         askQuote  |-> askQuote.value,
         bidQuote  |-> bidQuote.value ], bidQuote.rest)

ZeroQuote8Message ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      askQuote  |-> ZeroAskQuote8,
      bidQuote  |-> ZeroBidQuote8 ]

(* Quote 8 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuote8Message ==
    { ZeroQuote8Message }
        \cup { [ZeroQuote8Message EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroQuote8Message EXCEPT !.askQuote = one] : one \in CheckedAskQuote8 }
        \cup { [ZeroQuote8Message EXCEPT !.bidQuote = one] : one \in CheckedBidQuote8 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price21 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice21(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice21(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice21 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice21 ==
    { ZeroPrice21 }
        \cup { [ZeroPrice21 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice21 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice21 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity17 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity17(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity17(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity17 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity17 ==
    { ZeroQuoteQuantity17 }
        \cup { [ZeroQuoteQuantity17 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity17 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity17 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Ask Quote: 46 bytes                                                     *)
(***************************************************************************)

AskQuote9 ==
    [ changeFlag    : Sample(1),
      price         : Price21,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity17 ]

EncodeAskQuote9(message) ==
    message.changeFlag
        \o EncodePrice21(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity17(message.quoteQuantity)

DecodeAskQuote9(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice21(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity17(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroAskQuote9 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice21,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity17 ]

(* Ask Quote at zero, then each field in turn at the values it is checked at *)
CheckedAskQuote9 ==
    { ZeroAskQuote9 }
        \cup { [ZeroAskQuote9 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote9 EXCEPT !.price = one] : one \in CheckedPrice21 }
        \cup { [ZeroAskQuote9 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroAskQuote9 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote9 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity17 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price22 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice22(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice22(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice22 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice22 ==
    { ZeroPrice22 }
        \cup { [ZeroPrice22 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice22 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice22 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity18 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity18(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity18(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity18 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity18 ==
    { ZeroQuoteQuantity18 }
        \cup { [ZeroQuoteQuantity18 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity18 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity18 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Bid Quote: 46 bytes                                                     *)
(***************************************************************************)

BidQuote9 ==
    [ changeFlag    : Sample(1),
      price         : Price22,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity18 ]

EncodeBidQuote9(message) ==
    message.changeFlag
        \o EncodePrice22(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity18(message.quoteQuantity)

DecodeBidQuote9(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice22(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity18(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroBidQuote9 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice22,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity18 ]

(* Bid Quote at zero, then each field in turn at the values it is checked at *)
CheckedBidQuote9 ==
    { ZeroBidQuote9 }
        \cup { [ZeroBidQuote9 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote9 EXCEPT !.price = one] : one \in CheckedPrice22 }
        \cup { [ZeroBidQuote9 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroBidQuote9 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote9 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity18 }

(***************************************************************************)
(* Quote 9 Message: 94 bytes                                               *)
(***************************************************************************)

Quote9Message ==
    [ reserved2 : Sample(2),
      askQuote  : AskQuote9,
      bidQuote  : BidQuote9 ]

EncodeQuote9Message(message) ==
    message.reserved2
        \o EncodeAskQuote9(message.askQuote)
        \o EncodeBidQuote9(message.bidQuote)

DecodeQuote9Message(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET askQuote == DecodeAskQuote9(reserved2.rest) IN IF ~askQuote.ok THEN Fail ELSE
    LET bidQuote == DecodeBidQuote9(askQuote.rest) IN IF ~bidQuote.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         askQuote  |-> askQuote.value,
         bidQuote  |-> bidQuote.value ], bidQuote.rest)

ZeroQuote9Message ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      askQuote  |-> ZeroAskQuote9,
      bidQuote  |-> ZeroBidQuote9 ]

(* Quote 9 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuote9Message ==
    { ZeroQuote9Message }
        \cup { [ZeroQuote9Message EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroQuote9Message EXCEPT !.askQuote = one] : one \in CheckedAskQuote9 }
        \cup { [ZeroQuote9Message EXCEPT !.bidQuote = one] : one \in CheckedBidQuote9 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price23 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice23(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice23(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice23 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice23 ==
    { ZeroPrice23 }
        \cup { [ZeroPrice23 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice23 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice23 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity19 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity19(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity19(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity19 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity19 ==
    { ZeroQuoteQuantity19 }
        \cup { [ZeroQuoteQuantity19 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity19 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity19 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Ask Quote: 46 bytes                                                     *)
(***************************************************************************)

AskQuote10 ==
    [ changeFlag    : Sample(1),
      price         : Price23,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity19 ]

EncodeAskQuote10(message) ==
    message.changeFlag
        \o EncodePrice23(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity19(message.quoteQuantity)

DecodeAskQuote10(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice23(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity19(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroAskQuote10 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice23,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity19 ]

(* Ask Quote at zero, then each field in turn at the values it is checked at *)
CheckedAskQuote10 ==
    { ZeroAskQuote10 }
        \cup { [ZeroAskQuote10 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote10 EXCEPT !.price = one] : one \in CheckedPrice23 }
        \cup { [ZeroAskQuote10 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroAskQuote10 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroAskQuote10 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity19 }

(***************************************************************************)
(* Price: 16 bytes                                                         *)
(***************************************************************************)

Price24 ==
    [ unitFlag : Sample(1),
      priceC14 : Sample(14),
      sign     : Sample(1) ]

EncodePrice24(message) ==
    message.unitFlag
        \o message.priceC14
        \o message.sign

DecodePrice24(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ unitFlag |-> unitFlag.value,
         priceC14 |-> priceC14.value,
         sign     |-> sign.value ], sign.rest)

ZeroPrice24 ==
    [ unitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14 |-> [i \in 1 .. 14 |-> 0],
      sign     |-> [i \in 1 .. 1 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice24 ==
    { ZeroPrice24 }
        \cup { [ZeroPrice24 EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice24 EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice24 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity20 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity20(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity20(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity20 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity20 ==
    { ZeroQuoteQuantity20 }
        \cup { [ZeroQuoteQuantity20 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity20 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity20 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Bid Quote: 46 bytes                                                     *)
(***************************************************************************)

BidQuote10 ==
    [ changeFlag    : Sample(1),
      price         : Price24,
      timeC12       : Sample(12),
      quoteFlag     : Sample(1),
      quoteQuantity : QuoteQuantity20 ]

EncodeBidQuote10(message) ==
    message.changeFlag
        \o EncodePrice24(message.price)
        \o message.timeC12
        \o message.quoteFlag
        \o EncodeQuoteQuantity20(message.quoteQuantity)

DecodeBidQuote10(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET price == DecodePrice24(changeFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(price.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteFlag == ReadBytes(timeC12.rest, 1) IN IF ~quoteFlag.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity20(quoteFlag.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         price         |-> price.value,
         timeC12       |-> timeC12.value,
         quoteFlag     |-> quoteFlag.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroBidQuote10 ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      price         |-> ZeroPrice24,
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteFlag     |-> [i \in 1 .. 1 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity20 ]

(* Bid Quote at zero, then each field in turn at the values it is checked at *)
CheckedBidQuote10 ==
    { ZeroBidQuote10 }
        \cup { [ZeroBidQuote10 EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote10 EXCEPT !.price = one] : one \in CheckedPrice24 }
        \cup { [ZeroBidQuote10 EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroBidQuote10 EXCEPT !.quoteFlag = one] : one \in Sample(1) }
        \cup { [ZeroBidQuote10 EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity20 }

(***************************************************************************)
(* Quote 10 Message: 94 bytes                                              *)
(***************************************************************************)

Quote10Message ==
    [ reserved2 : Sample(2),
      askQuote  : AskQuote10,
      bidQuote  : BidQuote10 ]

EncodeQuote10Message(message) ==
    message.reserved2
        \o EncodeAskQuote10(message.askQuote)
        \o EncodeBidQuote10(message.bidQuote)

DecodeQuote10Message(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET askQuote == DecodeAskQuote10(reserved2.rest) IN IF ~askQuote.ok THEN Fail ELSE
    LET bidQuote == DecodeBidQuote10(askQuote.rest) IN IF ~bidQuote.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         askQuote  |-> askQuote.value,
         bidQuote  |-> bidQuote.value ], bidQuote.rest)

ZeroQuote10Message ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      askQuote  |-> ZeroAskQuote10,
      bidQuote  |-> ZeroBidQuote10 ]

(* Quote 10 Message at zero, then each field in turn at the values it is checked at *)
CheckedQuote10Message ==
    { ZeroQuote10Message }
        \cup { [ZeroQuote10Message EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroQuote10Message EXCEPT !.askQuote = one] : one \in CheckedAskQuote10 }
        \cup { [ZeroQuote10Message EXCEPT !.bidQuote = one] : one \in CheckedBidQuote10 }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity21 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity21(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity21(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity21 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity21 ==
    { ZeroQuoteQuantity21 }
        \cup { [ZeroQuoteQuantity21 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity21 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity21 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Sell Order: 29 bytes                                                    *)
(***************************************************************************)

SellOrder ==
    [ changeFlag    : Sample(1),
      timeC12       : Sample(12),
      quoteQuantity : QuoteQuantity21 ]

EncodeSellOrder(message) ==
    message.changeFlag
        \o message.timeC12
        \o EncodeQuoteQuantity21(message.quoteQuantity)

DecodeSellOrder(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(changeFlag.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity21(timeC12.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         timeC12       |-> timeC12.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroSellOrder ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity21 ]

(* Sell Order at zero, then each field in turn at the values it is checked at *)
CheckedSellOrder ==
    { ZeroSellOrder }
        \cup { [ZeroSellOrder EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroSellOrder EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroSellOrder EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity21 }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity22 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity22(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity22(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity22 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity22 ==
    { ZeroQuoteQuantity22 }
        \cup { [ZeroQuoteQuantity22 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity22 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity22 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Buy Order: 29 bytes                                                     *)
(***************************************************************************)

BuyOrder ==
    [ changeFlag    : Sample(1),
      timeC12       : Sample(12),
      quoteQuantity : QuoteQuantity22 ]

EncodeBuyOrder(message) ==
    message.changeFlag
        \o message.timeC12
        \o EncodeQuoteQuantity22(message.quoteQuantity)

DecodeBuyOrder(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(changeFlag.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity22(timeC12.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         timeC12       |-> timeC12.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroBuyOrder ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity22 ]

(* Buy Order at zero, then each field in turn at the values it is checked at *)
CheckedBuyOrder ==
    { ZeroBuyOrder }
        \cup { [ZeroBuyOrder EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroBuyOrder EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroBuyOrder EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity22 }

(***************************************************************************)
(* Market Order Message: 60 bytes                                          *)
(***************************************************************************)

MarketOrderMessage ==
    [ reserved2 : Sample(2),
      sellOrder : SellOrder,
      buyOrder  : BuyOrder ]

EncodeMarketOrderMessage(message) ==
    message.reserved2
        \o EncodeSellOrder(message.sellOrder)
        \o EncodeBuyOrder(message.buyOrder)

DecodeMarketOrderMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET sellOrder == DecodeSellOrder(reserved2.rest) IN IF ~sellOrder.ok THEN Fail ELSE
    LET buyOrder == DecodeBuyOrder(sellOrder.rest) IN IF ~buyOrder.ok THEN Fail ELSE
    Ok([ reserved2 |-> reserved2.value,
         sellOrder |-> sellOrder.value,
         buyOrder  |-> buyOrder.value ], buyOrder.rest)

ZeroMarketOrderMessage ==
    [ reserved2 |-> [i \in 1 .. 2 |-> 0],
      sellOrder |-> ZeroSellOrder,
      buyOrder  |-> ZeroBuyOrder ]

(* Market Order Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketOrderMessage ==
    { ZeroMarketOrderMessage }
        \cup { [ZeroMarketOrderMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroMarketOrderMessage EXCEPT !.sellOrder = one] : one \in CheckedSellOrder }
        \cup { [ZeroMarketOrderMessage EXCEPT !.buyOrder = one] : one \in CheckedBuyOrder }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity23 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity23(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity23(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity23 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity23 ==
    { ZeroQuoteQuantity23 }
        \cup { [ZeroQuoteQuantity23 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity23 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity23 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Over Quote: 29 bytes                                                    *)
(***************************************************************************)

OverQuote ==
    [ changeFlag    : Sample(1),
      timeC12       : Sample(12),
      quoteQuantity : QuoteQuantity23 ]

EncodeOverQuote(message) ==
    message.changeFlag
        \o message.timeC12
        \o EncodeQuoteQuantity23(message.quoteQuantity)

DecodeOverQuote(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(changeFlag.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity23(timeC12.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         timeC12       |-> timeC12.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroOverQuote ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity23 ]

(* Over Quote at zero, then each field in turn at the values it is checked at *)
CheckedOverQuote ==
    { ZeroOverQuote }
        \cup { [ZeroOverQuote EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroOverQuote EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroOverQuote EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity23 }

(***************************************************************************)
(* Quote Quantity: 16 bytes                                                *)
(***************************************************************************)

QuoteQuantity24 ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      quantity                      : Sample(14),
      sign                          : Sample(1) ]

EncodeQuoteQuantity24(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.quantity
        \o message.sign

DecodeQuoteQuantity24(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~quantity.ok THEN Fail ELSE
    LET sign == ReadBytes(quantity.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         quantity                      |-> quantity.value,
         sign                          |-> sign.value ], sign.rest)

ZeroQuoteQuantity24 ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      quantity                      |-> [i \in 1 .. 14 |-> 0],
      sign                          |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Quantity at zero, then each field in turn at the values it is checked at *)
CheckedQuoteQuantity24 ==
    { ZeroQuoteQuantity24 }
        \cup { [ZeroQuoteQuantity24 EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteQuantity24 EXCEPT !.quantity = one] : one \in Sample(14) }
        \cup { [ZeroQuoteQuantity24 EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Under Quote: 29 bytes                                                   *)
(***************************************************************************)

UnderQuote ==
    [ changeFlag    : Sample(1),
      timeC12       : Sample(12),
      quoteQuantity : QuoteQuantity24 ]

EncodeUnderQuote(message) ==
    message.changeFlag
        \o message.timeC12
        \o EncodeQuoteQuantity24(message.quoteQuantity)

DecodeUnderQuote(bytes) ==
    LET changeFlag == ReadBytes(bytes, 1) IN IF ~changeFlag.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(changeFlag.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    LET quoteQuantity == DecodeQuoteQuantity24(timeC12.rest) IN IF ~quoteQuantity.ok THEN Fail ELSE
    Ok([ changeFlag    |-> changeFlag.value,
         timeC12       |-> timeC12.value,
         quoteQuantity |-> quoteQuantity.value ], quoteQuantity.rest)

ZeroUnderQuote ==
    [ changeFlag    |-> [i \in 1 .. 1 |-> 0],
      timeC12       |-> [i \in 1 .. 12 |-> 0],
      quoteQuantity |-> ZeroQuoteQuantity24 ]

(* Under Quote at zero, then each field in turn at the values it is checked at *)
CheckedUnderQuote ==
    { ZeroUnderQuote }
        \cup { [ZeroUnderQuote EXCEPT !.changeFlag = one] : one \in Sample(1) }
        \cup { [ZeroUnderQuote EXCEPT !.timeC12 = one] : one \in Sample(12) }
        \cup { [ZeroUnderQuote EXCEPT !.quoteQuantity = one] : one \in CheckedQuoteQuantity24 }

(***************************************************************************)
(* Over Under Message: 60 bytes                                            *)
(***************************************************************************)

OverUnderMessage ==
    [ reserved2  : Sample(2),
      overQuote  : OverQuote,
      underQuote : UnderQuote ]

EncodeOverUnderMessage(message) ==
    message.reserved2
        \o EncodeOverQuote(message.overQuote)
        \o EncodeUnderQuote(message.underQuote)

DecodeOverUnderMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET overQuote == DecodeOverQuote(reserved2.rest) IN IF ~overQuote.ok THEN Fail ELSE
    LET underQuote == DecodeUnderQuote(overQuote.rest) IN IF ~underQuote.ok THEN Fail ELSE
    Ok([ reserved2  |-> reserved2.value,
         overQuote  |-> overQuote.value,
         underQuote |-> underQuote.value ], underQuote.rest)

ZeroOverUnderMessage ==
    [ reserved2  |-> [i \in 1 .. 2 |-> 0],
      overQuote  |-> ZeroOverQuote,
      underQuote |-> ZeroUnderQuote ]

(* Over Under Message at zero, then each field in turn at the values it is checked at *)
CheckedOverUnderMessage ==
    { ZeroOverUnderMessage }
        \cup { [ZeroOverUnderMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOverUnderMessage EXCEPT !.overQuote = one] : one \in CheckedOverQuote }
        \cup { [ZeroOverUnderMessage EXCEPT !.underQuote = one] : one \in CheckedUnderQuote }

(***************************************************************************)
(* Trading Volume: 23 bytes                                                *)
(***************************************************************************)

TradingVolume ==
    [ reserved1                     : Sample(1),
      tradingVolumeTurnoverUnitFlag : Sample(1),
      tradingVolumeC14              : Sample(14),
      timeC6                        : Sample(6),
      secondReserved1               : Sample(1) ]

EncodeTradingVolume(message) ==
    message.reserved1
        \o message.tradingVolumeTurnoverUnitFlag
        \o message.tradingVolumeC14
        \o message.timeC6
        \o message.secondReserved1

DecodeTradingVolume(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(reserved1.rest, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET tradingVolumeC14 == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~tradingVolumeC14.ok THEN Fail ELSE
    LET timeC6 == ReadBytes(tradingVolumeC14.rest, 6) IN IF ~timeC6.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(timeC6.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    Ok([ reserved1                     |-> reserved1.value,
         tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         tradingVolumeC14              |-> tradingVolumeC14.value,
         timeC6                        |-> timeC6.value,
         secondReserved1               |-> secondReserved1.value ], secondReserved1.rest)

ZeroTradingVolume ==
    [ reserved1                     |-> [i \in 1 .. 1 |-> 0],
      tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      tradingVolumeC14              |-> [i \in 1 .. 14 |-> 0],
      timeC6                        |-> [i \in 1 .. 6 |-> 0],
      secondReserved1               |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Volume at zero, then each field in turn at the values it is checked at *)
CheckedTradingVolume ==
    { ZeroTradingVolume }
        \cup { [ZeroTradingVolume EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradingVolume EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradingVolume EXCEPT !.tradingVolumeC14 = one] : one \in Sample(14) }
        \cup { [ZeroTradingVolume EXCEPT !.timeC6 = one] : one \in Sample(6) }
        \cup { [ZeroTradingVolume EXCEPT !.secondReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Volume Message: 25 bytes                                        *)
(***************************************************************************)

TradingVolumeMessage ==
    [ reserved2     : Sample(2),
      tradingVolume : TradingVolume ]

EncodeTradingVolumeMessage(message) ==
    message.reserved2
        \o EncodeTradingVolume(message.tradingVolume)

DecodeTradingVolumeMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET tradingVolume == DecodeTradingVolume(reserved2.rest) IN IF ~tradingVolume.ok THEN Fail ELSE
    Ok([ reserved2     |-> reserved2.value,
         tradingVolume |-> tradingVolume.value ], tradingVolume.rest)

ZeroTradingVolumeMessage ==
    [ reserved2     |-> [i \in 1 .. 2 |-> 0],
      tradingVolume |-> ZeroTradingVolume ]

(* Trading Volume Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingVolumeMessage ==
    { ZeroTradingVolumeMessage }
        \cup { [ZeroTradingVolumeMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradingVolumeMessage EXCEPT !.tradingVolume = one] : one \in CheckedTradingVolume }

(***************************************************************************)
(* Turnover In Yen Value: 23 bytes                                         *)
(***************************************************************************)

TurnoverInYenValue ==
    [ reserved1                     : Sample(1),
      tradingVolumeTurnoverUnitFlag : Sample(1),
      turnoverValue                 : Sample(14),
      timeC6                        : Sample(6),
      secondReserved1               : Sample(1) ]

EncodeTurnoverInYenValue(message) ==
    message.reserved1
        \o message.tradingVolumeTurnoverUnitFlag
        \o message.turnoverValue
        \o message.timeC6
        \o message.secondReserved1

DecodeTurnoverInYenValue(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(reserved1.rest, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET turnoverValue == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~turnoverValue.ok THEN Fail ELSE
    LET timeC6 == ReadBytes(turnoverValue.rest, 6) IN IF ~timeC6.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(timeC6.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    Ok([ reserved1                     |-> reserved1.value,
         tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         turnoverValue                 |-> turnoverValue.value,
         timeC6                        |-> timeC6.value,
         secondReserved1               |-> secondReserved1.value ], secondReserved1.rest)

ZeroTurnoverInYenValue ==
    [ reserved1                     |-> [i \in 1 .. 1 |-> 0],
      tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      turnoverValue                 |-> [i \in 1 .. 14 |-> 0],
      timeC6                        |-> [i \in 1 .. 6 |-> 0],
      secondReserved1               |-> [i \in 1 .. 1 |-> 0] ]

(* Turnover In Yen Value at zero, then each field in turn at the values it is checked at *)
CheckedTurnoverInYenValue ==
    { ZeroTurnoverInYenValue }
        \cup { [ZeroTurnoverInYenValue EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTurnoverInYenValue EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTurnoverInYenValue EXCEPT !.turnoverValue = one] : one \in Sample(14) }
        \cup { [ZeroTurnoverInYenValue EXCEPT !.timeC6 = one] : one \in Sample(6) }
        \cup { [ZeroTurnoverInYenValue EXCEPT !.secondReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Turnover Message: 25 bytes                                              *)
(***************************************************************************)

TurnoverMessage ==
    [ reserved2          : Sample(2),
      turnoverInYenValue : TurnoverInYenValue ]

EncodeTurnoverMessage(message) ==
    message.reserved2
        \o EncodeTurnoverInYenValue(message.turnoverInYenValue)

DecodeTurnoverMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET turnoverInYenValue == DecodeTurnoverInYenValue(reserved2.rest) IN IF ~turnoverInYenValue.ok THEN Fail ELSE
    Ok([ reserved2          |-> reserved2.value,
         turnoverInYenValue |-> turnoverInYenValue.value ], turnoverInYenValue.rest)

ZeroTurnoverMessage ==
    [ reserved2          |-> [i \in 1 .. 2 |-> 0],
      turnoverInYenValue |-> ZeroTurnoverInYenValue ]

(* Turnover Message at zero, then each field in turn at the values it is checked at *)
CheckedTurnoverMessage ==
    { ZeroTurnoverMessage }
        \cup { [ZeroTurnoverMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTurnoverMessage EXCEPT !.turnoverInYenValue = one] : one \in CheckedTurnoverInYenValue }

(***************************************************************************)
(* All Day Vwap: 24 bytes                                                  *)
(***************************************************************************)

AllDayVwap ==
    [ reserved1       : Sample(1),
      lotSizeUnitFlag : Sample(1),
      allDayVwapC14   : Sample(14),
      sign            : Sample(1),
      timeC6          : Sample(6),
      secondReserved1 : Sample(1) ]

EncodeAllDayVwap(message) ==
    message.reserved1
        \o message.lotSizeUnitFlag
        \o message.allDayVwapC14
        \o message.sign
        \o message.timeC6
        \o message.secondReserved1

DecodeAllDayVwap(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET lotSizeUnitFlag == ReadBytes(reserved1.rest, 1) IN IF ~lotSizeUnitFlag.ok THEN Fail ELSE
    LET allDayVwapC14 == ReadBytes(lotSizeUnitFlag.rest, 14) IN IF ~allDayVwapC14.ok THEN Fail ELSE
    LET sign == ReadBytes(allDayVwapC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET timeC6 == ReadBytes(sign.rest, 6) IN IF ~timeC6.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(timeC6.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    Ok([ reserved1       |-> reserved1.value,
         lotSizeUnitFlag |-> lotSizeUnitFlag.value,
         allDayVwapC14   |-> allDayVwapC14.value,
         sign            |-> sign.value,
         timeC6          |-> timeC6.value,
         secondReserved1 |-> secondReserved1.value ], secondReserved1.rest)

ZeroAllDayVwap ==
    [ reserved1       |-> [i \in 1 .. 1 |-> 0],
      lotSizeUnitFlag |-> [i \in 1 .. 1 |-> 0],
      allDayVwapC14   |-> [i \in 1 .. 14 |-> 0],
      sign            |-> [i \in 1 .. 1 |-> 0],
      timeC6          |-> [i \in 1 .. 6 |-> 0],
      secondReserved1 |-> [i \in 1 .. 1 |-> 0] ]

(* All Day Vwap at zero, then each field in turn at the values it is checked at *)
CheckedAllDayVwap ==
    { ZeroAllDayVwap }
        \cup { [ZeroAllDayVwap EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroAllDayVwap EXCEPT !.lotSizeUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroAllDayVwap EXCEPT !.allDayVwapC14 = one] : one \in Sample(14) }
        \cup { [ZeroAllDayVwap EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroAllDayVwap EXCEPT !.timeC6 = one] : one \in Sample(6) }
        \cup { [ZeroAllDayVwap EXCEPT !.secondReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Current Session Vwap: 24 bytes                                          *)
(***************************************************************************)

CurrentSessionVwap ==
    [ reserved1             : Sample(1),
      lotSizeUnitFlag       : Sample(1),
      currentSessionVwapC14 : Sample(14),
      sign                  : Sample(1),
      timeC6                : Sample(6),
      secondReserved1       : Sample(1) ]

EncodeCurrentSessionVwap(message) ==
    message.reserved1
        \o message.lotSizeUnitFlag
        \o message.currentSessionVwapC14
        \o message.sign
        \o message.timeC6
        \o message.secondReserved1

DecodeCurrentSessionVwap(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET lotSizeUnitFlag == ReadBytes(reserved1.rest, 1) IN IF ~lotSizeUnitFlag.ok THEN Fail ELSE
    LET currentSessionVwapC14 == ReadBytes(lotSizeUnitFlag.rest, 14) IN IF ~currentSessionVwapC14.ok THEN Fail ELSE
    LET sign == ReadBytes(currentSessionVwapC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET timeC6 == ReadBytes(sign.rest, 6) IN IF ~timeC6.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(timeC6.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    Ok([ reserved1             |-> reserved1.value,
         lotSizeUnitFlag       |-> lotSizeUnitFlag.value,
         currentSessionVwapC14 |-> currentSessionVwapC14.value,
         sign                  |-> sign.value,
         timeC6                |-> timeC6.value,
         secondReserved1       |-> secondReserved1.value ], secondReserved1.rest)

ZeroCurrentSessionVwap ==
    [ reserved1             |-> [i \in 1 .. 1 |-> 0],
      lotSizeUnitFlag       |-> [i \in 1 .. 1 |-> 0],
      currentSessionVwapC14 |-> [i \in 1 .. 14 |-> 0],
      sign                  |-> [i \in 1 .. 1 |-> 0],
      timeC6                |-> [i \in 1 .. 6 |-> 0],
      secondReserved1       |-> [i \in 1 .. 1 |-> 0] ]

(* Current Session Vwap at zero, then each field in turn at the values it is checked at *)
CheckedCurrentSessionVwap ==
    { ZeroCurrentSessionVwap }
        \cup { [ZeroCurrentSessionVwap EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroCurrentSessionVwap EXCEPT !.lotSizeUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroCurrentSessionVwap EXCEPT !.currentSessionVwapC14 = one] : one \in Sample(14) }
        \cup { [ZeroCurrentSessionVwap EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroCurrentSessionVwap EXCEPT !.timeC6 = one] : one \in Sample(6) }
        \cup { [ZeroCurrentSessionVwap EXCEPT !.secondReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Vwap Message: 50 bytes                                                  *)
(***************************************************************************)

VwapMessage ==
    [ reserved2          : Sample(2),
      allDayVwap         : AllDayVwap,
      currentSessionVwap : CurrentSessionVwap ]

EncodeVwapMessage(message) ==
    message.reserved2
        \o EncodeAllDayVwap(message.allDayVwap)
        \o EncodeCurrentSessionVwap(message.currentSessionVwap)

DecodeVwapMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET allDayVwap == DecodeAllDayVwap(reserved2.rest) IN IF ~allDayVwap.ok THEN Fail ELSE
    LET currentSessionVwap == DecodeCurrentSessionVwap(allDayVwap.rest) IN IF ~currentSessionVwap.ok THEN Fail ELSE
    Ok([ reserved2          |-> reserved2.value,
         allDayVwap         |-> allDayVwap.value,
         currentSessionVwap |-> currentSessionVwap.value ], currentSessionVwap.rest)

ZeroVwapMessage ==
    [ reserved2          |-> [i \in 1 .. 2 |-> 0],
      allDayVwap         |-> ZeroAllDayVwap,
      currentSessionVwap |-> ZeroCurrentSessionVwap ]

(* Vwap Message at zero, then each field in turn at the values it is checked at *)
CheckedVwapMessage ==
    { ZeroVwapMessage }
        \cup { [ZeroVwapMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroVwapMessage EXCEPT !.allDayVwap = one] : one \in CheckedAllDayVwap }
        \cup { [ZeroVwapMessage EXCEPT !.currentSessionVwap = one] : one \in CheckedCurrentSessionVwap }

(***************************************************************************)
(* Parity Estimated Price: 23 bytes                                        *)
(***************************************************************************)

ParityEstimatedPrice ==
    [ unitFlag                : Sample(1),
      parityEstimatedPriceC14 : Sample(14),
      sign                    : Sample(1),
      timeC6                  : Sample(6),
      reserved1               : Sample(1) ]

EncodeParityEstimatedPrice(message) ==
    message.unitFlag
        \o message.parityEstimatedPriceC14
        \o message.sign
        \o message.timeC6
        \o message.reserved1

DecodeParityEstimatedPrice(bytes) ==
    LET unitFlag == ReadBytes(bytes, 1) IN IF ~unitFlag.ok THEN Fail ELSE
    LET parityEstimatedPriceC14 == ReadBytes(unitFlag.rest, 14) IN IF ~parityEstimatedPriceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(parityEstimatedPriceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET timeC6 == ReadBytes(sign.rest, 6) IN IF ~timeC6.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(timeC6.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ unitFlag                |-> unitFlag.value,
         parityEstimatedPriceC14 |-> parityEstimatedPriceC14.value,
         sign                    |-> sign.value,
         timeC6                  |-> timeC6.value,
         reserved1               |-> reserved1.value ], reserved1.rest)

ZeroParityEstimatedPrice ==
    [ unitFlag                |-> [i \in 1 .. 1 |-> 0],
      parityEstimatedPriceC14 |-> [i \in 1 .. 14 |-> 0],
      sign                    |-> [i \in 1 .. 1 |-> 0],
      timeC6                  |-> [i \in 1 .. 6 |-> 0],
      reserved1               |-> [i \in 1 .. 1 |-> 0] ]

(* Parity Estimated Price at zero, then each field in turn at the values it is checked at *)
CheckedParityEstimatedPrice ==
    { ZeroParityEstimatedPrice }
        \cup { [ZeroParityEstimatedPrice EXCEPT !.unitFlag = one] : one \in Sample(1) }
        \cup { [ZeroParityEstimatedPrice EXCEPT !.parityEstimatedPriceC14 = one] : one \in Sample(14) }
        \cup { [ZeroParityEstimatedPrice EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroParityEstimatedPrice EXCEPT !.timeC6 = one] : one \in Sample(6) }
        \cup { [ZeroParityEstimatedPrice EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Parity Message: 25 bytes                                                *)
(***************************************************************************)

ParityMessage ==
    [ reserved2            : Sample(2),
      parityEstimatedPrice : ParityEstimatedPrice ]

EncodeParityMessage(message) ==
    message.reserved2
        \o EncodeParityEstimatedPrice(message.parityEstimatedPrice)

DecodeParityMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET parityEstimatedPrice == DecodeParityEstimatedPrice(reserved2.rest) IN IF ~parityEstimatedPrice.ok THEN Fail ELSE
    Ok([ reserved2            |-> reserved2.value,
         parityEstimatedPrice |-> parityEstimatedPrice.value ], parityEstimatedPrice.rest)

ZeroParityMessage ==
    [ reserved2            |-> [i \in 1 .. 2 |-> 0],
      parityEstimatedPrice |-> ZeroParityEstimatedPrice ]

(* Parity Message at zero, then each field in turn at the values it is checked at *)
CheckedParityMessage ==
    { ZeroParityMessage }
        \cup { [ZeroParityMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroParityMessage EXCEPT !.parityEstimatedPrice = one] : one \in CheckedParityEstimatedPrice }

(***************************************************************************)
(* Direct Yield: 9 bytes                                                   *)
(***************************************************************************)

DirectYield ==
    [ directYieldC8 : Sample(8),
      sign          : Sample(1) ]

EncodeDirectYield(message) ==
    message.directYieldC8
        \o message.sign

DecodeDirectYield(bytes) ==
    LET directYieldC8 == ReadBytes(bytes, 8) IN IF ~directYieldC8.ok THEN Fail ELSE
    LET sign == ReadBytes(directYieldC8.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ directYieldC8 |-> directYieldC8.value,
         sign          |-> sign.value ], sign.rest)

ZeroDirectYield ==
    [ directYieldC8 |-> [i \in 1 .. 8 |-> 0],
      sign          |-> [i \in 1 .. 1 |-> 0] ]

(* Direct Yield at zero, then each field in turn at the values it is checked at *)
CheckedDirectYield ==
    { ZeroDirectYield }
        \cup { [ZeroDirectYield EXCEPT !.directYieldC8 = one] : one \in Sample(8) }
        \cup { [ZeroDirectYield EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Final Yield: 9 bytes                                                    *)
(***************************************************************************)

FinalYield ==
    [ finalYieldC8 : Sample(8),
      sign         : Sample(1) ]

EncodeFinalYield(message) ==
    message.finalYieldC8
        \o message.sign

DecodeFinalYield(bytes) ==
    LET finalYieldC8 == ReadBytes(bytes, 8) IN IF ~finalYieldC8.ok THEN Fail ELSE
    LET sign == ReadBytes(finalYieldC8.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    Ok([ finalYieldC8 |-> finalYieldC8.value,
         sign         |-> sign.value ], sign.rest)

ZeroFinalYield ==
    [ finalYieldC8 |-> [i \in 1 .. 8 |-> 0],
      sign         |-> [i \in 1 .. 1 |-> 0] ]

(* Final Yield at zero, then each field in turn at the values it is checked at *)
CheckedFinalYield ==
    { ZeroFinalYield }
        \cup { [ZeroFinalYield EXCEPT !.finalYieldC8 = one] : one \in Sample(8) }
        \cup { [ZeroFinalYield EXCEPT !.sign = one] : one \in Sample(1) }

(***************************************************************************)
(* Yield Message: 27 bytes                                                 *)
(***************************************************************************)

YieldMessage ==
    [ reserved2   : Sample(2),
      directYield : DirectYield,
      finalYield  : FinalYield,
      timeC6      : Sample(6),
      reserved1   : Sample(1) ]

EncodeYieldMessage(message) ==
    message.reserved2
        \o EncodeDirectYield(message.directYield)
        \o EncodeFinalYield(message.finalYield)
        \o message.timeC6
        \o message.reserved1

DecodeYieldMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET directYield == DecodeDirectYield(reserved2.rest) IN IF ~directYield.ok THEN Fail ELSE
    LET finalYield == DecodeFinalYield(directYield.rest) IN IF ~finalYield.ok THEN Fail ELSE
    LET timeC6 == ReadBytes(finalYield.rest, 6) IN IF ~timeC6.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(timeC6.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ reserved2   |-> reserved2.value,
         directYield |-> directYield.value,
         finalYield  |-> finalYield.value,
         timeC6      |-> timeC6.value,
         reserved1   |-> reserved1.value ], reserved1.rest)

ZeroYieldMessage ==
    [ reserved2   |-> [i \in 1 .. 2 |-> 0],
      directYield |-> ZeroDirectYield,
      finalYield  |-> ZeroFinalYield,
      timeC6      |-> [i \in 1 .. 6 |-> 0],
      reserved1   |-> [i \in 1 .. 1 |-> 0] ]

(* Yield Message at zero, then each field in turn at the values it is checked at *)
CheckedYieldMessage ==
    { ZeroYieldMessage }
        \cup { [ZeroYieldMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroYieldMessage EXCEPT !.directYield = one] : one \in CheckedDirectYield }
        \cup { [ZeroYieldMessage EXCEPT !.finalYield = one] : one \in CheckedFinalYield }
        \cup { [ZeroYieldMessage EXCEPT !.timeC6 = one] : one \in Sample(6) }
        \cup { [ZeroYieldMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Control Message: 10 bytes                                               *)
(***************************************************************************)

ControlMessage ==
    [ reserved2    : Sample(2),
      testModeFlag : Sample(1),
      startEndFlag : Sample(1),
      timeC6       : Sample(6) ]

EncodeControlMessage(message) ==
    message.reserved2
        \o message.testModeFlag
        \o message.startEndFlag
        \o message.timeC6

DecodeControlMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET testModeFlag == ReadBytes(reserved2.rest, 1) IN IF ~testModeFlag.ok THEN Fail ELSE
    LET startEndFlag == ReadBytes(testModeFlag.rest, 1) IN IF ~startEndFlag.ok THEN Fail ELSE
    LET timeC6 == ReadBytes(startEndFlag.rest, 6) IN IF ~timeC6.ok THEN Fail ELSE
    Ok([ reserved2    |-> reserved2.value,
         testModeFlag |-> testModeFlag.value,
         startEndFlag |-> startEndFlag.value,
         timeC6       |-> timeC6.value ], timeC6.rest)

ZeroControlMessage ==
    [ reserved2    |-> [i \in 1 .. 2 |-> 0],
      testModeFlag |-> [i \in 1 .. 1 |-> 0],
      startEndFlag |-> [i \in 1 .. 1 |-> 0],
      timeC6       |-> [i \in 1 .. 6 |-> 0] ]

(* Control Message at zero, then each field in turn at the values it is checked at *)
CheckedControlMessage ==
    { ZeroControlMessage }
        \cup { [ZeroControlMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroControlMessage EXCEPT !.testModeFlag = one] : one \in Sample(1) }
        \cup { [ZeroControlMessage EXCEPT !.startEndFlag = one] : one \in Sample(1) }
        \cup { [ZeroControlMessage EXCEPT !.timeC6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Payload, selected by Tag ID                                             *)
(***************************************************************************)

UpdateNoMessageCode == 20047  \* "NO"
StatusInformationMessageCode == 21332  \* "ST"
OpenHighLowAndCurrentPriceMessageCode == 13392  \* "4P"
Quote1MessageCode == 20785  \* "Q1"
Quote2MessageCode == 20786  \* "Q2"
Quote3MessageCode == 20787  \* "Q3"
Quote4MessageCode == 20788  \* "Q4"
Quote5MessageCode == 20789  \* "Q5"
Quote6MessageCode == 20790  \* "Q6"
Quote7MessageCode == 20791  \* "Q7"
Quote8MessageCode == 20792  \* "Q8"
Quote9MessageCode == 20793  \* "Q9"
Quote10MessageCode == 20801  \* "QA"
MarketOrderMessageCode == 20813  \* "QM"
OverUnderMessageCode == 20815  \* "QO"
TradingVolumeMessageCode == 22092  \* "VL"
TurnoverMessageCode == 22081  \* "VA"
VwapMessageCode == 22103  \* "VW"
ParityMessageCode == 20545  \* "PA"
YieldMessageCode == 22857  \* "YI"
ControlMessageCode == 19523  \* "LC"

Payload ==
    [ tag : {UpdateNoMessageCode}, body : UpdateNoMessage ]
        \cup [ tag : {StatusInformationMessageCode}, body : StatusInformationMessage ]
        \cup [ tag : {OpenHighLowAndCurrentPriceMessageCode}, body : OpenHighLowAndCurrentPriceMessage ]
        \cup [ tag : {Quote1MessageCode}, body : Quote1Message ]
        \cup [ tag : {Quote2MessageCode}, body : Quote2Message ]
        \cup [ tag : {Quote3MessageCode}, body : Quote3Message ]
        \cup [ tag : {Quote4MessageCode}, body : Quote4Message ]
        \cup [ tag : {Quote5MessageCode}, body : Quote5Message ]
        \cup [ tag : {Quote6MessageCode}, body : Quote6Message ]
        \cup [ tag : {Quote7MessageCode}, body : Quote7Message ]
        \cup [ tag : {Quote8MessageCode}, body : Quote8Message ]
        \cup [ tag : {Quote9MessageCode}, body : Quote9Message ]
        \cup [ tag : {Quote10MessageCode}, body : Quote10Message ]
        \cup [ tag : {MarketOrderMessageCode}, body : MarketOrderMessage ]
        \cup [ tag : {OverUnderMessageCode}, body : OverUnderMessage ]
        \cup [ tag : {TradingVolumeMessageCode}, body : TradingVolumeMessage ]
        \cup [ tag : {TurnoverMessageCode}, body : TurnoverMessage ]
        \cup [ tag : {VwapMessageCode}, body : VwapMessage ]
        \cup [ tag : {ParityMessageCode}, body : ParityMessage ]
        \cup [ tag : {YieldMessageCode}, body : YieldMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]

EncodePayload(message) ==
    CASE message.tag = UpdateNoMessageCode -> EncodeUpdateNoMessage(message.body)
      [] message.tag = StatusInformationMessageCode -> EncodeStatusInformationMessage(message.body)
      [] message.tag = OpenHighLowAndCurrentPriceMessageCode -> EncodeOpenHighLowAndCurrentPriceMessage(message.body)
      [] message.tag = Quote1MessageCode -> EncodeQuote1Message(message.body)
      [] message.tag = Quote2MessageCode -> EncodeQuote2Message(message.body)
      [] message.tag = Quote3MessageCode -> EncodeQuote3Message(message.body)
      [] message.tag = Quote4MessageCode -> EncodeQuote4Message(message.body)
      [] message.tag = Quote5MessageCode -> EncodeQuote5Message(message.body)
      [] message.tag = Quote6MessageCode -> EncodeQuote6Message(message.body)
      [] message.tag = Quote7MessageCode -> EncodeQuote7Message(message.body)
      [] message.tag = Quote8MessageCode -> EncodeQuote8Message(message.body)
      [] message.tag = Quote9MessageCode -> EncodeQuote9Message(message.body)
      [] message.tag = Quote10MessageCode -> EncodeQuote10Message(message.body)
      [] message.tag = MarketOrderMessageCode -> EncodeMarketOrderMessage(message.body)
      [] message.tag = OverUnderMessageCode -> EncodeOverUnderMessage(message.body)
      [] message.tag = TradingVolumeMessageCode -> EncodeTradingVolumeMessage(message.body)
      [] message.tag = TurnoverMessageCode -> EncodeTurnoverMessage(message.body)
      [] message.tag = VwapMessageCode -> EncodeVwapMessage(message.body)
      [] message.tag = ParityMessageCode -> EncodeParityMessage(message.body)
      [] message.tag = YieldMessageCode -> EncodeYieldMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = UpdateNoMessageCode -> DecodeUpdateNoMessage(bytes)
              [] tag = StatusInformationMessageCode -> DecodeStatusInformationMessage(bytes)
              [] tag = OpenHighLowAndCurrentPriceMessageCode -> DecodeOpenHighLowAndCurrentPriceMessage(bytes)
              [] tag = Quote1MessageCode -> DecodeQuote1Message(bytes)
              [] tag = Quote2MessageCode -> DecodeQuote2Message(bytes)
              [] tag = Quote3MessageCode -> DecodeQuote3Message(bytes)
              [] tag = Quote4MessageCode -> DecodeQuote4Message(bytes)
              [] tag = Quote5MessageCode -> DecodeQuote5Message(bytes)
              [] tag = Quote6MessageCode -> DecodeQuote6Message(bytes)
              [] tag = Quote7MessageCode -> DecodeQuote7Message(bytes)
              [] tag = Quote8MessageCode -> DecodeQuote8Message(bytes)
              [] tag = Quote9MessageCode -> DecodeQuote9Message(bytes)
              [] tag = Quote10MessageCode -> DecodeQuote10Message(bytes)
              [] tag = MarketOrderMessageCode -> DecodeMarketOrderMessage(bytes)
              [] tag = OverUnderMessageCode -> DecodeOverUnderMessage(bytes)
              [] tag = TradingVolumeMessageCode -> DecodeTradingVolumeMessage(bytes)
              [] tag = TurnoverMessageCode -> DecodeTurnoverMessage(bytes)
              [] tag = VwapMessageCode -> DecodeVwapMessage(bytes)
              [] tag = ParityMessageCode -> DecodeParityMessage(bytes)
              [] tag = YieldMessageCode -> DecodeYieldMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> UpdateNoMessageCode, body |-> ZeroUpdateNoMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> UpdateNoMessageCode, body |-> one] : one \in CheckedUpdateNoMessage }
        \cup { [tag |-> StatusInformationMessageCode, body |-> one] : one \in CheckedStatusInformationMessage }
        \cup { [tag |-> OpenHighLowAndCurrentPriceMessageCode, body |-> one] : one \in CheckedOpenHighLowAndCurrentPriceMessage }
        \cup { [tag |-> Quote1MessageCode, body |-> one] : one \in CheckedQuote1Message }
        \cup { [tag |-> Quote2MessageCode, body |-> one] : one \in CheckedQuote2Message }
        \cup { [tag |-> Quote3MessageCode, body |-> one] : one \in CheckedQuote3Message }
        \cup { [tag |-> Quote4MessageCode, body |-> one] : one \in CheckedQuote4Message }
        \cup { [tag |-> Quote5MessageCode, body |-> one] : one \in CheckedQuote5Message }
        \cup { [tag |-> Quote6MessageCode, body |-> one] : one \in CheckedQuote6Message }
        \cup { [tag |-> Quote7MessageCode, body |-> one] : one \in CheckedQuote7Message }
        \cup { [tag |-> Quote8MessageCode, body |-> one] : one \in CheckedQuote8Message }
        \cup { [tag |-> Quote9MessageCode, body |-> one] : one \in CheckedQuote9Message }
        \cup { [tag |-> Quote10MessageCode, body |-> one] : one \in CheckedQuote10Message }
        \cup { [tag |-> MarketOrderMessageCode, body |-> one] : one \in CheckedMarketOrderMessage }
        \cup { [tag |-> OverUnderMessageCode, body |-> one] : one \in CheckedOverUnderMessage }
        \cup { [tag |-> TradingVolumeMessageCode, body |-> one] : one \in CheckedTradingVolumeMessage }
        \cup { [tag |-> TurnoverMessageCode, body |-> one] : one \in CheckedTurnoverMessage }
        \cup { [tag |-> VwapMessageCode, body |-> one] : one \in CheckedVwapMessage }
        \cup { [tag |-> ParityMessageCode, body |-> one] : one \in CheckedParityMessage }
        \cup { [tag |-> YieldMessageCode, body |-> one] : one \in CheckedYieldMessage }
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
    { [ZeroTagInformation EXCEPT !.payload = [tag |-> UpdateNoMessageCode, body |-> ZeroUpdateNoMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> StatusInformationMessageCode, body |-> ZeroStatusInformationMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> OpenHighLowAndCurrentPriceMessageCode, body |-> ZeroOpenHighLowAndCurrentPriceMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> Quote1MessageCode, body |-> ZeroQuote1Message]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> Quote2MessageCode, body |-> ZeroQuote2Message]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> Quote3MessageCode, body |-> ZeroQuote3Message]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> Quote4MessageCode, body |-> ZeroQuote4Message]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> Quote5MessageCode, body |-> ZeroQuote5Message]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> Quote6MessageCode, body |-> ZeroQuote6Message]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> Quote7MessageCode, body |-> ZeroQuote7Message]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> Quote8MessageCode, body |-> ZeroQuote8Message]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> Quote9MessageCode, body |-> ZeroQuote9Message]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> Quote10MessageCode, body |-> ZeroQuote10Message]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> MarketOrderMessageCode, body |-> ZeroMarketOrderMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> OverUnderMessageCode, body |-> ZeroOverUnderMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> TradingVolumeMessageCode, body |-> ZeroTradingVolumeMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> TurnoverMessageCode, body |-> ZeroTurnoverMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> VwapMessageCode, body |-> ZeroVwapMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> ParityMessageCode, body |-> ZeroParityMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> YieldMessageCode, body |-> ZeroYieldMessage]],
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

(* Every Update No Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUpdateNoMessage ==
    \A message \in CheckedUpdateNoMessage :
        LET read == DecodeUpdateNoMessage(EncodeUpdateNoMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Status Information decodes back to what was encoded, and leaves nothing over *)
RoundTripStatusInformation ==
    \A message \in CheckedStatusInformation :
        LET read == DecodeStatusInformation(EncodeStatusInformation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Status Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatusInformationMessage ==
    \A message \in CheckedStatusInformationMessage :
        LET read == DecodeStatusInformationMessage(EncodeStatusInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice ==
    \A message \in CheckedPrice :
        LET read == DecodePrice(EncodePrice(message))
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

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice2 ==
    \A message \in CheckedPrice2 :
        LET read == DecodePrice2(EncodePrice2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every High decodes back to what was encoded, and leaves nothing over *)
RoundTripHigh ==
    \A message \in CheckedHigh :
        LET read == DecodeHigh(EncodeHigh(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice3 ==
    \A message \in CheckedPrice3 :
        LET read == DecodePrice3(EncodePrice3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Low decodes back to what was encoded, and leaves nothing over *)
RoundTripLow ==
    \A message \in CheckedLow :
        LET read == DecodeLow(EncodeLow(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice4 ==
    \A message \in CheckedPrice4 :
        LET read == DecodePrice4(EncodePrice4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Current decodes back to what was encoded, and leaves nothing over *)
RoundTripCurrent ==
    \A message \in CheckedCurrent :
        LET read == DecodeCurrent(EncodeCurrent(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open High Low And Current Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpenHighLowAndCurrentPriceMessage ==
    \A message \in CheckedOpenHighLowAndCurrentPriceMessage :
        LET read == DecodeOpenHighLowAndCurrentPriceMessage(EncodeOpenHighLowAndCurrentPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice5 ==
    \A message \in CheckedPrice5 :
        LET read == DecodePrice5(EncodePrice5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity ==
    \A message \in CheckedQuoteQuantity :
        LET read == DecodeQuoteQuantity(EncodeQuoteQuantity(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripAskQuote ==
    \A message \in CheckedAskQuote :
        LET read == DecodeAskQuote(EncodeAskQuote(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice6 ==
    \A message \in CheckedPrice6 :
        LET read == DecodePrice6(EncodePrice6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity2 ==
    \A message \in CheckedQuoteQuantity2 :
        LET read == DecodeQuoteQuantity2(EncodeQuoteQuantity2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripBidQuote ==
    \A message \in CheckedBidQuote :
        LET read == DecodeBidQuote(EncodeBidQuote(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote 1 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuote1Message ==
    \A message \in CheckedQuote1Message :
        LET read == DecodeQuote1Message(EncodeQuote1Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice7 ==
    \A message \in CheckedPrice7 :
        LET read == DecodePrice7(EncodePrice7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity3 ==
    \A message \in CheckedQuoteQuantity3 :
        LET read == DecodeQuoteQuantity3(EncodeQuoteQuantity3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripAskQuote2 ==
    \A message \in CheckedAskQuote2 :
        LET read == DecodeAskQuote2(EncodeAskQuote2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice8 ==
    \A message \in CheckedPrice8 :
        LET read == DecodePrice8(EncodePrice8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity4 ==
    \A message \in CheckedQuoteQuantity4 :
        LET read == DecodeQuoteQuantity4(EncodeQuoteQuantity4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripBidQuote2 ==
    \A message \in CheckedBidQuote2 :
        LET read == DecodeBidQuote2(EncodeBidQuote2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote 2 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuote2Message ==
    \A message \in CheckedQuote2Message :
        LET read == DecodeQuote2Message(EncodeQuote2Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice9 ==
    \A message \in CheckedPrice9 :
        LET read == DecodePrice9(EncodePrice9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity5 ==
    \A message \in CheckedQuoteQuantity5 :
        LET read == DecodeQuoteQuantity5(EncodeQuoteQuantity5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripAskQuote3 ==
    \A message \in CheckedAskQuote3 :
        LET read == DecodeAskQuote3(EncodeAskQuote3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice10 ==
    \A message \in CheckedPrice10 :
        LET read == DecodePrice10(EncodePrice10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity6 ==
    \A message \in CheckedQuoteQuantity6 :
        LET read == DecodeQuoteQuantity6(EncodeQuoteQuantity6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripBidQuote3 ==
    \A message \in CheckedBidQuote3 :
        LET read == DecodeBidQuote3(EncodeBidQuote3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote 3 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuote3Message ==
    \A message \in CheckedQuote3Message :
        LET read == DecodeQuote3Message(EncodeQuote3Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice11 ==
    \A message \in CheckedPrice11 :
        LET read == DecodePrice11(EncodePrice11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity7 ==
    \A message \in CheckedQuoteQuantity7 :
        LET read == DecodeQuoteQuantity7(EncodeQuoteQuantity7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripAskQuote4 ==
    \A message \in CheckedAskQuote4 :
        LET read == DecodeAskQuote4(EncodeAskQuote4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice12 ==
    \A message \in CheckedPrice12 :
        LET read == DecodePrice12(EncodePrice12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity8 ==
    \A message \in CheckedQuoteQuantity8 :
        LET read == DecodeQuoteQuantity8(EncodeQuoteQuantity8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripBidQuote4 ==
    \A message \in CheckedBidQuote4 :
        LET read == DecodeBidQuote4(EncodeBidQuote4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote 4 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuote4Message ==
    \A message \in CheckedQuote4Message :
        LET read == DecodeQuote4Message(EncodeQuote4Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice13 ==
    \A message \in CheckedPrice13 :
        LET read == DecodePrice13(EncodePrice13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity9 ==
    \A message \in CheckedQuoteQuantity9 :
        LET read == DecodeQuoteQuantity9(EncodeQuoteQuantity9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripAskQuote5 ==
    \A message \in CheckedAskQuote5 :
        LET read == DecodeAskQuote5(EncodeAskQuote5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice14 ==
    \A message \in CheckedPrice14 :
        LET read == DecodePrice14(EncodePrice14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity10 ==
    \A message \in CheckedQuoteQuantity10 :
        LET read == DecodeQuoteQuantity10(EncodeQuoteQuantity10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripBidQuote5 ==
    \A message \in CheckedBidQuote5 :
        LET read == DecodeBidQuote5(EncodeBidQuote5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote 5 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuote5Message ==
    \A message \in CheckedQuote5Message :
        LET read == DecodeQuote5Message(EncodeQuote5Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice15 ==
    \A message \in CheckedPrice15 :
        LET read == DecodePrice15(EncodePrice15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity11 ==
    \A message \in CheckedQuoteQuantity11 :
        LET read == DecodeQuoteQuantity11(EncodeQuoteQuantity11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripAskQuote6 ==
    \A message \in CheckedAskQuote6 :
        LET read == DecodeAskQuote6(EncodeAskQuote6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice16 ==
    \A message \in CheckedPrice16 :
        LET read == DecodePrice16(EncodePrice16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity12 ==
    \A message \in CheckedQuoteQuantity12 :
        LET read == DecodeQuoteQuantity12(EncodeQuoteQuantity12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripBidQuote6 ==
    \A message \in CheckedBidQuote6 :
        LET read == DecodeBidQuote6(EncodeBidQuote6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote 6 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuote6Message ==
    \A message \in CheckedQuote6Message :
        LET read == DecodeQuote6Message(EncodeQuote6Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice17 ==
    \A message \in CheckedPrice17 :
        LET read == DecodePrice17(EncodePrice17(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity13 ==
    \A message \in CheckedQuoteQuantity13 :
        LET read == DecodeQuoteQuantity13(EncodeQuoteQuantity13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripAskQuote7 ==
    \A message \in CheckedAskQuote7 :
        LET read == DecodeAskQuote7(EncodeAskQuote7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice18 ==
    \A message \in CheckedPrice18 :
        LET read == DecodePrice18(EncodePrice18(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity14 ==
    \A message \in CheckedQuoteQuantity14 :
        LET read == DecodeQuoteQuantity14(EncodeQuoteQuantity14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripBidQuote7 ==
    \A message \in CheckedBidQuote7 :
        LET read == DecodeBidQuote7(EncodeBidQuote7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote 7 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuote7Message ==
    \A message \in CheckedQuote7Message :
        LET read == DecodeQuote7Message(EncodeQuote7Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice19 ==
    \A message \in CheckedPrice19 :
        LET read == DecodePrice19(EncodePrice19(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity15 ==
    \A message \in CheckedQuoteQuantity15 :
        LET read == DecodeQuoteQuantity15(EncodeQuoteQuantity15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripAskQuote8 ==
    \A message \in CheckedAskQuote8 :
        LET read == DecodeAskQuote8(EncodeAskQuote8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice20 ==
    \A message \in CheckedPrice20 :
        LET read == DecodePrice20(EncodePrice20(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity16 ==
    \A message \in CheckedQuoteQuantity16 :
        LET read == DecodeQuoteQuantity16(EncodeQuoteQuantity16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripBidQuote8 ==
    \A message \in CheckedBidQuote8 :
        LET read == DecodeBidQuote8(EncodeBidQuote8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote 8 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuote8Message ==
    \A message \in CheckedQuote8Message :
        LET read == DecodeQuote8Message(EncodeQuote8Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice21 ==
    \A message \in CheckedPrice21 :
        LET read == DecodePrice21(EncodePrice21(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity17 ==
    \A message \in CheckedQuoteQuantity17 :
        LET read == DecodeQuoteQuantity17(EncodeQuoteQuantity17(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripAskQuote9 ==
    \A message \in CheckedAskQuote9 :
        LET read == DecodeAskQuote9(EncodeAskQuote9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice22 ==
    \A message \in CheckedPrice22 :
        LET read == DecodePrice22(EncodePrice22(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity18 ==
    \A message \in CheckedQuoteQuantity18 :
        LET read == DecodeQuoteQuantity18(EncodeQuoteQuantity18(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripBidQuote9 ==
    \A message \in CheckedBidQuote9 :
        LET read == DecodeBidQuote9(EncodeBidQuote9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote 9 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuote9Message ==
    \A message \in CheckedQuote9Message :
        LET read == DecodeQuote9Message(EncodeQuote9Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice23 ==
    \A message \in CheckedPrice23 :
        LET read == DecodePrice23(EncodePrice23(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity19 ==
    \A message \in CheckedQuoteQuantity19 :
        LET read == DecodeQuoteQuantity19(EncodeQuoteQuantity19(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripAskQuote10 ==
    \A message \in CheckedAskQuote10 :
        LET read == DecodeAskQuote10(EncodeAskQuote10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price decodes back to what was encoded, and leaves nothing over *)
RoundTripPrice24 ==
    \A message \in CheckedPrice24 :
        LET read == DecodePrice24(EncodePrice24(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity20 ==
    \A message \in CheckedQuoteQuantity20 :
        LET read == DecodeQuoteQuantity20(EncodeQuoteQuantity20(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripBidQuote10 ==
    \A message \in CheckedBidQuote10 :
        LET read == DecodeBidQuote10(EncodeBidQuote10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote 10 Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuote10Message ==
    \A message \in CheckedQuote10Message :
        LET read == DecodeQuote10Message(EncodeQuote10Message(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity21 ==
    \A message \in CheckedQuoteQuantity21 :
        LET read == DecodeQuoteQuantity21(EncodeQuoteQuantity21(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sell Order decodes back to what was encoded, and leaves nothing over *)
RoundTripSellOrder ==
    \A message \in CheckedSellOrder :
        LET read == DecodeSellOrder(EncodeSellOrder(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity22 ==
    \A message \in CheckedQuoteQuantity22 :
        LET read == DecodeQuoteQuantity22(EncodeQuoteQuantity22(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Buy Order decodes back to what was encoded, and leaves nothing over *)
RoundTripBuyOrder ==
    \A message \in CheckedBuyOrder :
        LET read == DecodeBuyOrder(EncodeBuyOrder(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketOrderMessage ==
    \A message \in CheckedMarketOrderMessage :
        LET read == DecodeMarketOrderMessage(EncodeMarketOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity23 ==
    \A message \in CheckedQuoteQuantity23 :
        LET read == DecodeQuoteQuantity23(EncodeQuoteQuantity23(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Over Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripOverQuote ==
    \A message \in CheckedOverQuote :
        LET read == DecodeOverQuote(EncodeOverQuote(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteQuantity24 ==
    \A message \in CheckedQuoteQuantity24 :
        LET read == DecodeQuoteQuantity24(EncodeQuoteQuantity24(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Under Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderQuote ==
    \A message \in CheckedUnderQuote :
        LET read == DecodeUnderQuote(EncodeUnderQuote(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Over Under Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOverUnderMessage ==
    \A message \in CheckedOverUnderMessage :
        LET read == DecodeOverUnderMessage(EncodeOverUnderMessage(message))
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

(* Every Trading Volume Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingVolumeMessage ==
    \A message \in CheckedTradingVolumeMessage :
        LET read == DecodeTradingVolumeMessage(EncodeTradingVolumeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Turnover In Yen Value decodes back to what was encoded, and leaves nothing over *)
RoundTripTurnoverInYenValue ==
    \A message \in CheckedTurnoverInYenValue :
        LET read == DecodeTurnoverInYenValue(EncodeTurnoverInYenValue(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Turnover Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTurnoverMessage ==
    \A message \in CheckedTurnoverMessage :
        LET read == DecodeTurnoverMessage(EncodeTurnoverMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every All Day Vwap decodes back to what was encoded, and leaves nothing over *)
RoundTripAllDayVwap ==
    \A message \in CheckedAllDayVwap :
        LET read == DecodeAllDayVwap(EncodeAllDayVwap(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Current Session Vwap decodes back to what was encoded, and leaves nothing over *)
RoundTripCurrentSessionVwap ==
    \A message \in CheckedCurrentSessionVwap :
        LET read == DecodeCurrentSessionVwap(EncodeCurrentSessionVwap(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Vwap Message decodes back to what was encoded, and leaves nothing over *)
RoundTripVwapMessage ==
    \A message \in CheckedVwapMessage :
        LET read == DecodeVwapMessage(EncodeVwapMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parity Estimated Price decodes back to what was encoded, and leaves nothing over *)
RoundTripParityEstimatedPrice ==
    \A message \in CheckedParityEstimatedPrice :
        LET read == DecodeParityEstimatedPrice(EncodeParityEstimatedPrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Parity Message decodes back to what was encoded, and leaves nothing over *)
RoundTripParityMessage ==
    \A message \in CheckedParityMessage :
        LET read == DecodeParityMessage(EncodeParityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Direct Yield decodes back to what was encoded, and leaves nothing over *)
RoundTripDirectYield ==
    \A message \in CheckedDirectYield :
        LET read == DecodeDirectYield(EncodeDirectYield(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Final Yield decodes back to what was encoded, and leaves nothing over *)
RoundTripFinalYield ==
    \A message \in CheckedFinalYield :
        LET read == DecodeFinalYield(EncodeFinalYield(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Yield Message decodes back to what was encoded, and leaves nothing over *)
RoundTripYieldMessage ==
    \A message \in CheckedYieldMessage :
        LET read == DecodeYieldMessage(EncodeYieldMessage(message))
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
