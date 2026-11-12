--------------------- MODULE TseEquities_ToSTNeT_v19_5 ---------------------
(***************************************************************************)
(* Japan Exchange Group ToSTNeT v19.5                                      *)
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
(* Trading Halt: 8 bytes                                                   *)
(***************************************************************************)

TradingHalt ==
    [ stateFlag : Sample(2),
      timeC6    : Sample(6) ]

EncodeTradingHalt(message) ==
    message.stateFlag
        \o message.timeC6

DecodeTradingHalt(bytes) ==
    LET stateFlag == ReadBytes(bytes, 2) IN IF ~stateFlag.ok THEN Fail ELSE
    LET timeC6 == ReadBytes(stateFlag.rest, 6) IN IF ~timeC6.ok THEN Fail ELSE
    Ok([ stateFlag |-> stateFlag.value,
         timeC6    |-> timeC6.value ], timeC6.rest)

ZeroTradingHalt ==
    [ stateFlag |-> [i \in 1 .. 2 |-> 0],
      timeC6    |-> [i \in 1 .. 6 |-> 0] ]

(* Trading Halt at zero, then each field in turn at the values it is checked at *)
CheckedTradingHalt ==
    { ZeroTradingHalt }
        \cup { [ZeroTradingHalt EXCEPT !.stateFlag = one] : one \in Sample(2) }
        \cup { [ZeroTradingHalt EXCEPT !.timeC6 = one] : one \in Sample(6) }

(***************************************************************************)
(* Price: 30 bytes                                                         *)
(***************************************************************************)

Price ==
    [ priceCode       : Sample(2),
      lotSizeUnitFlag : Sample(1),
      priceC14        : Sample(14),
      sign            : Sample(1),
      timeC12         : Sample(12) ]

EncodePrice(message) ==
    message.priceCode
        \o message.lotSizeUnitFlag
        \o message.priceC14
        \o message.sign
        \o message.timeC12

DecodePrice(bytes) ==
    LET priceCode == ReadBytes(bytes, 2) IN IF ~priceCode.ok THEN Fail ELSE
    LET lotSizeUnitFlag == ReadBytes(priceCode.rest, 1) IN IF ~lotSizeUnitFlag.ok THEN Fail ELSE
    LET priceC14 == ReadBytes(lotSizeUnitFlag.rest, 14) IN IF ~priceC14.ok THEN Fail ELSE
    LET sign == ReadBytes(priceC14.rest, 1) IN IF ~sign.ok THEN Fail ELSE
    LET timeC12 == ReadBytes(sign.rest, 12) IN IF ~timeC12.ok THEN Fail ELSE
    Ok([ priceCode       |-> priceCode.value,
         lotSizeUnitFlag |-> lotSizeUnitFlag.value,
         priceC14        |-> priceC14.value,
         sign            |-> sign.value,
         timeC12         |-> timeC12.value ], timeC12.rest)

ZeroPrice ==
    [ priceCode       |-> [i \in 1 .. 2 |-> 0],
      lotSizeUnitFlag |-> [i \in 1 .. 1 |-> 0],
      priceC14        |-> [i \in 1 .. 14 |-> 0],
      sign            |-> [i \in 1 .. 1 |-> 0],
      timeC12         |-> [i \in 1 .. 12 |-> 0] ]

(* Price at zero, then each field in turn at the values it is checked at *)
CheckedPrice ==
    { ZeroPrice }
        \cup { [ZeroPrice EXCEPT !.priceCode = one] : one \in Sample(2) }
        \cup { [ZeroPrice EXCEPT !.lotSizeUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroPrice EXCEPT !.priceC14 = one] : one \in Sample(14) }
        \cup { [ZeroPrice EXCEPT !.sign = one] : one \in Sample(1) }
        \cup { [ZeroPrice EXCEPT !.timeC12 = one] : one \in Sample(12) }

(***************************************************************************)
(* Trading Volume: 15 bytes                                                *)
(***************************************************************************)

TradingVolume ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      tradingVolumeC14              : Sample(14) ]

EncodeTradingVolume(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.tradingVolumeC14

DecodeTradingVolume(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET tradingVolumeC14 == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~tradingVolumeC14.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         tradingVolumeC14              |-> tradingVolumeC14.value ], tradingVolumeC14.rest)

ZeroTradingVolume ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      tradingVolumeC14              |-> [i \in 1 .. 14 |-> 0] ]

(* Trading Volume at zero, then each field in turn at the values it is checked at *)
CheckedTradingVolume ==
    { ZeroTradingVolume }
        \cup { [ZeroTradingVolume EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradingVolume EXCEPT !.tradingVolumeC14 = one] : one \in Sample(14) }

(***************************************************************************)
(* Turnover: 15 bytes                                                      *)
(***************************************************************************)

Turnover ==
    [ tradingVolumeTurnoverUnitFlag : Sample(1),
      turnoverC14                   : Sample(14) ]

EncodeTurnover(message) ==
    message.tradingVolumeTurnoverUnitFlag
        \o message.turnoverC14

DecodeTurnover(bytes) ==
    LET tradingVolumeTurnoverUnitFlag == ReadBytes(bytes, 1) IN IF ~tradingVolumeTurnoverUnitFlag.ok THEN Fail ELSE
    LET turnoverC14 == ReadBytes(tradingVolumeTurnoverUnitFlag.rest, 14) IN IF ~turnoverC14.ok THEN Fail ELSE
    Ok([ tradingVolumeTurnoverUnitFlag |-> tradingVolumeTurnoverUnitFlag.value,
         turnoverC14                   |-> turnoverC14.value ], turnoverC14.rest)

ZeroTurnover ==
    [ tradingVolumeTurnoverUnitFlag |-> [i \in 1 .. 1 |-> 0],
      turnoverC14                   |-> [i \in 1 .. 14 |-> 0] ]

(* Turnover at zero, then each field in turn at the values it is checked at *)
CheckedTurnover ==
    { ZeroTurnover }
        \cup { [ZeroTurnover EXCEPT !.tradingVolumeTurnoverUnitFlag = one] : one \in Sample(1) }
        \cup { [ZeroTurnover EXCEPT !.turnoverC14 = one] : one \in Sample(14) }

(***************************************************************************)
(* ToSTNeT By-Issue Information Message: 72 bytes                          *)
(***************************************************************************)

TostnetByissueInformationMessage ==
    [ reserved2                     : Sample(2),
      marketIdentificationFlag      : Sample(1),
      tradingHalt                   : TradingHalt,
      transactionIdentificationFlag : Sample(1),
      price                         : Price,
      tradingVolume                 : TradingVolume,
      turnover                      : Turnover ]

EncodeTostnetByissueInformationMessage(message) ==
    message.reserved2
        \o message.marketIdentificationFlag
        \o EncodeTradingHalt(message.tradingHalt)
        \o message.transactionIdentificationFlag
        \o EncodePrice(message.price)
        \o EncodeTradingVolume(message.tradingVolume)
        \o EncodeTurnover(message.turnover)

DecodeTostnetByissueInformationMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET marketIdentificationFlag == ReadBytes(reserved2.rest, 1) IN IF ~marketIdentificationFlag.ok THEN Fail ELSE
    LET tradingHalt == DecodeTradingHalt(marketIdentificationFlag.rest) IN IF ~tradingHalt.ok THEN Fail ELSE
    LET transactionIdentificationFlag == ReadBytes(tradingHalt.rest, 1) IN IF ~transactionIdentificationFlag.ok THEN Fail ELSE
    LET price == DecodePrice(transactionIdentificationFlag.rest) IN IF ~price.ok THEN Fail ELSE
    LET tradingVolume == DecodeTradingVolume(price.rest) IN IF ~tradingVolume.ok THEN Fail ELSE
    LET turnover == DecodeTurnover(tradingVolume.rest) IN IF ~turnover.ok THEN Fail ELSE
    Ok([ reserved2                     |-> reserved2.value,
         marketIdentificationFlag      |-> marketIdentificationFlag.value,
         tradingHalt                   |-> tradingHalt.value,
         transactionIdentificationFlag |-> transactionIdentificationFlag.value,
         price                         |-> price.value,
         tradingVolume                 |-> tradingVolume.value,
         turnover                      |-> turnover.value ], turnover.rest)

ZeroTostnetByissueInformationMessage ==
    [ reserved2                     |-> [i \in 1 .. 2 |-> 0],
      marketIdentificationFlag      |-> [i \in 1 .. 1 |-> 0],
      tradingHalt                   |-> ZeroTradingHalt,
      transactionIdentificationFlag |-> [i \in 1 .. 1 |-> 0],
      price                         |-> ZeroPrice,
      tradingVolume                 |-> ZeroTradingVolume,
      turnover                      |-> ZeroTurnover ]

(* ToSTNeT By-Issue Information Message at zero, then each field in turn at the values it is checked at *)
CheckedTostnetByissueInformationMessage ==
    { ZeroTostnetByissueInformationMessage }
        \cup { [ZeroTostnetByissueInformationMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTostnetByissueInformationMessage EXCEPT !.marketIdentificationFlag = one] : one \in Sample(1) }
        \cup { [ZeroTostnetByissueInformationMessage EXCEPT !.tradingHalt = one] : one \in CheckedTradingHalt }
        \cup { [ZeroTostnetByissueInformationMessage EXCEPT !.transactionIdentificationFlag = one] : one \in Sample(1) }
        \cup { [ZeroTostnetByissueInformationMessage EXCEPT !.price = one] : one \in CheckedPrice }
        \cup { [ZeroTostnetByissueInformationMessage EXCEPT !.tradingVolume = one] : one \in CheckedTradingVolume }
        \cup { [ZeroTostnetByissueInformationMessage EXCEPT !.turnover = one] : one \in CheckedTurnover }

(***************************************************************************)
(* State: 8 bytes                                                          *)
(***************************************************************************)

State ==
    [ marketStateFlag : Sample(2),
      timeC6          : Sample(6) ]

EncodeState(message) ==
    message.marketStateFlag
        \o message.timeC6

DecodeState(bytes) ==
    LET marketStateFlag == ReadBytes(bytes, 2) IN IF ~marketStateFlag.ok THEN Fail ELSE
    LET timeC6 == ReadBytes(marketStateFlag.rest, 6) IN IF ~timeC6.ok THEN Fail ELSE
    Ok([ marketStateFlag |-> marketStateFlag.value,
         timeC6          |-> timeC6.value ], timeC6.rest)

ZeroState ==
    [ marketStateFlag |-> [i \in 1 .. 2 |-> 0],
      timeC6          |-> [i \in 1 .. 6 |-> 0] ]

(* State at zero, then each field in turn at the values it is checked at *)
CheckedState ==
    { ZeroState }
        \cup { [ZeroState EXCEPT !.marketStateFlag = one] : one \in Sample(2) }
        \cup { [ZeroState EXCEPT !.timeC6 = one] : one \in Sample(6) }

(***************************************************************************)
(* ToSTNeT Market Information Message: 11 bytes                            *)
(***************************************************************************)

TostnetMarketInformationMessage ==
    [ reserved2                : Sample(2),
      marketIdentificationFlag : Sample(1),
      state                    : State ]

EncodeTostnetMarketInformationMessage(message) ==
    message.reserved2
        \o message.marketIdentificationFlag
        \o EncodeState(message.state)

DecodeTostnetMarketInformationMessage(bytes) ==
    LET reserved2 == ReadBytes(bytes, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET marketIdentificationFlag == ReadBytes(reserved2.rest, 1) IN IF ~marketIdentificationFlag.ok THEN Fail ELSE
    LET state == DecodeState(marketIdentificationFlag.rest) IN IF ~state.ok THEN Fail ELSE
    Ok([ reserved2                |-> reserved2.value,
         marketIdentificationFlag |-> marketIdentificationFlag.value,
         state                    |-> state.value ], state.rest)

ZeroTostnetMarketInformationMessage ==
    [ reserved2                |-> [i \in 1 .. 2 |-> 0],
      marketIdentificationFlag |-> [i \in 1 .. 1 |-> 0],
      state                    |-> ZeroState ]

(* ToSTNeT Market Information Message at zero, then each field in turn at the values it is checked at *)
CheckedTostnetMarketInformationMessage ==
    { ZeroTostnetMarketInformationMessage }
        \cup { [ZeroTostnetMarketInformationMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTostnetMarketInformationMessage EXCEPT !.marketIdentificationFlag = one] : one \in Sample(1) }
        \cup { [ZeroTostnetMarketInformationMessage EXCEPT !.state = one] : one \in CheckedState }

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

TostnetByissueInformationMessageCode == 21577  \* "TI"
TostnetMarketInformationMessageCode == 21581  \* "TM"
ControlMessageCode == 19523  \* "LC"

Payload ==
    [ tag : {TostnetByissueInformationMessageCode}, body : TostnetByissueInformationMessage ]
        \cup [ tag : {TostnetMarketInformationMessageCode}, body : TostnetMarketInformationMessage ]
        \cup [ tag : {ControlMessageCode}, body : ControlMessage ]

EncodePayload(message) ==
    CASE message.tag = TostnetByissueInformationMessageCode -> EncodeTostnetByissueInformationMessage(message.body)
      [] message.tag = TostnetMarketInformationMessageCode -> EncodeTostnetMarketInformationMessage(message.body)
      [] message.tag = ControlMessageCode -> EncodeControlMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TostnetByissueInformationMessageCode -> DecodeTostnetByissueInformationMessage(bytes)
              [] tag = TostnetMarketInformationMessageCode -> DecodeTostnetMarketInformationMessage(bytes)
              [] tag = ControlMessageCode -> DecodeControlMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TostnetByissueInformationMessageCode, body |-> ZeroTostnetByissueInformationMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TostnetByissueInformationMessageCode, body |-> one] : one \in CheckedTostnetByissueInformationMessage }
        \cup { [tag |-> TostnetMarketInformationMessageCode, body |-> one] : one \in CheckedTostnetMarketInformationMessage }
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
    { [ZeroTagInformation EXCEPT !.payload = [tag |-> TostnetByissueInformationMessageCode, body |-> ZeroTostnetByissueInformationMessage]],
      [ZeroTagInformation EXCEPT !.payload = [tag |-> TostnetMarketInformationMessageCode, body |-> ZeroTostnetMarketInformationMessage]],
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

(* Every Trading Halt decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingHalt ==
    \A message \in CheckedTradingHalt :
        LET read == DecodeTradingHalt(EncodeTradingHalt(message))
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

(* Every ToSTNeT By-Issue Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTostnetByissueInformationMessage ==
    \A message \in CheckedTostnetByissueInformationMessage :
        LET read == DecodeTostnetByissueInformationMessage(EncodeTostnetByissueInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every State decodes back to what was encoded, and leaves nothing over *)
RoundTripState ==
    \A message \in CheckedState :
        LET read == DecodeState(EncodeState(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every ToSTNeT Market Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTostnetMarketInformationMessage ==
    \A message \in CheckedTostnetMarketInformationMessage :
        LET read == DecodeTostnetMarketInformationMessage(EncodeTostnetMarketInformationMessage(message))
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
