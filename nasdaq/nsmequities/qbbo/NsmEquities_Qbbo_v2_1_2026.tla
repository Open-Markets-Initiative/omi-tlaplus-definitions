-------------------- MODULE NsmEquities_Qbbo_v2_1_2026 ---------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Quoted Best Bid And Offer v2.1.2026                            *)
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
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
(*                                                                         *)
(* Note: a Message Count of 0 marks End Of Session and carries no Message. *)
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
(* System Event Message: 9 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ trackingNumber : Sample(2),
      timeStamp      : Sample(6),
      eventCode      : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.trackingNumber
        \o message.timeStamp
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timeStamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timeStamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timeStamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timeStamp      |-> timeStamp.value,
         eventCode      |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timeStamp      |-> [i \in 1 .. 6 |-> 0],
      eventCode      |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.timeStamp = one] : one \in Sample(6) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Directory Message: 36 bytes                                       *)
(***************************************************************************)

StockDirectoryMessage ==
    [ trackingNumber              : Sample(2),
      timeStamp                   : Sample(6),
      stock                       : Sample(8),
      marketCategory              : Sample(1),
      financialStatusIndicator    : Sample(1),
      roundLotSize                : Sample(4),
      roundLotsOnly               : Sample(1),
      issueClassification         : Sample(1),
      issueSubtype                : Sample(2),
      authenticity                : Sample(1),
      shortSaleThresholdIndicator : Sample(1),
      ipoFlag                     : Sample(1),
      luldReferencePriceTier      : Sample(1),
      etpFlag                     : Sample(1),
      etpLeverageFactor           : Sample(4),
      inverseIndicator            : Sample(1) ]

EncodeStockDirectoryMessage(message) ==
    message.trackingNumber
        \o message.timeStamp
        \o message.stock
        \o message.marketCategory
        \o message.financialStatusIndicator
        \o message.roundLotSize
        \o message.roundLotsOnly
        \o message.issueClassification
        \o message.issueSubtype
        \o message.authenticity
        \o message.shortSaleThresholdIndicator
        \o message.ipoFlag
        \o message.luldReferencePriceTier
        \o message.etpFlag
        \o message.etpLeverageFactor
        \o message.inverseIndicator

DecodeStockDirectoryMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timeStamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timeStamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timeStamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET marketCategory == ReadBytes(stock.rest, 1) IN IF ~marketCategory.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(marketCategory.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(financialStatusIndicator.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET roundLotsOnly == ReadBytes(roundLotSize.rest, 1) IN IF ~roundLotsOnly.ok THEN Fail ELSE
    LET issueClassification == ReadBytes(roundLotsOnly.rest, 1) IN IF ~issueClassification.ok THEN Fail ELSE
    LET issueSubtype == ReadBytes(issueClassification.rest, 2) IN IF ~issueSubtype.ok THEN Fail ELSE
    LET authenticity == ReadBytes(issueSubtype.rest, 1) IN IF ~authenticity.ok THEN Fail ELSE
    LET shortSaleThresholdIndicator == ReadBytes(authenticity.rest, 1) IN IF ~shortSaleThresholdIndicator.ok THEN Fail ELSE
    LET ipoFlag == ReadBytes(shortSaleThresholdIndicator.rest, 1) IN IF ~ipoFlag.ok THEN Fail ELSE
    LET luldReferencePriceTier == ReadBytes(ipoFlag.rest, 1) IN IF ~luldReferencePriceTier.ok THEN Fail ELSE
    LET etpFlag == ReadBytes(luldReferencePriceTier.rest, 1) IN IF ~etpFlag.ok THEN Fail ELSE
    LET etpLeverageFactor == ReadBytes(etpFlag.rest, 4) IN IF ~etpLeverageFactor.ok THEN Fail ELSE
    LET inverseIndicator == ReadBytes(etpLeverageFactor.rest, 1) IN IF ~inverseIndicator.ok THEN Fail ELSE
    Ok([ trackingNumber              |-> trackingNumber.value,
         timeStamp                   |-> timeStamp.value,
         stock                       |-> stock.value,
         marketCategory              |-> marketCategory.value,
         financialStatusIndicator    |-> financialStatusIndicator.value,
         roundLotSize                |-> roundLotSize.value,
         roundLotsOnly               |-> roundLotsOnly.value,
         issueClassification         |-> issueClassification.value,
         issueSubtype                |-> issueSubtype.value,
         authenticity                |-> authenticity.value,
         shortSaleThresholdIndicator |-> shortSaleThresholdIndicator.value,
         ipoFlag                     |-> ipoFlag.value,
         luldReferencePriceTier      |-> luldReferencePriceTier.value,
         etpFlag                     |-> etpFlag.value,
         etpLeverageFactor           |-> etpLeverageFactor.value,
         inverseIndicator            |-> inverseIndicator.value ], inverseIndicator.rest)

ZeroStockDirectoryMessage ==
    [ trackingNumber              |-> [i \in 1 .. 2 |-> 0],
      timeStamp                   |-> [i \in 1 .. 6 |-> 0],
      stock                       |-> [i \in 1 .. 8 |-> 0],
      marketCategory              |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator    |-> [i \in 1 .. 1 |-> 0],
      roundLotSize                |-> [i \in 1 .. 4 |-> 0],
      roundLotsOnly               |-> [i \in 1 .. 1 |-> 0],
      issueClassification         |-> [i \in 1 .. 1 |-> 0],
      issueSubtype                |-> [i \in 1 .. 2 |-> 0],
      authenticity                |-> [i \in 1 .. 1 |-> 0],
      shortSaleThresholdIndicator |-> [i \in 1 .. 1 |-> 0],
      ipoFlag                     |-> [i \in 1 .. 1 |-> 0],
      luldReferencePriceTier      |-> [i \in 1 .. 1 |-> 0],
      etpFlag                     |-> [i \in 1 .. 1 |-> 0],
      etpLeverageFactor           |-> [i \in 1 .. 4 |-> 0],
      inverseIndicator            |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedStockDirectoryMessage ==
    { ZeroStockDirectoryMessage }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.timeStamp = one] : one \in Sample(6) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.marketCategory = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotsOnly = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.issueClassification = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.issueSubtype = one] : one \in Sample(2) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.authenticity = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.shortSaleThresholdIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.ipoFlag = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.luldReferencePriceTier = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.etpFlag = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.etpLeverageFactor = one] : one \in Sample(4) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.inverseIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Trading Action Message: 22 bytes                                  *)
(***************************************************************************)

StockTradingActionMessage ==
    [ trackingNumber      : Sample(2),
      timeStamp           : Sample(6),
      stock               : Sample(8),
      securityClass       : Sample(1),
      currentTradingState : Sample(1),
      reason              : Sample(4) ]

EncodeStockTradingActionMessage(message) ==
    message.trackingNumber
        \o message.timeStamp
        \o message.stock
        \o message.securityClass
        \o message.currentTradingState
        \o message.reason

DecodeStockTradingActionMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timeStamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timeStamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timeStamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET securityClass == ReadBytes(stock.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(securityClass.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    LET reason == ReadBytes(currentTradingState.rest, 4) IN IF ~reason.ok THEN Fail ELSE
    Ok([ trackingNumber      |-> trackingNumber.value,
         timeStamp           |-> timeStamp.value,
         stock               |-> stock.value,
         securityClass       |-> securityClass.value,
         currentTradingState |-> currentTradingState.value,
         reason              |-> reason.value ], reason.rest)

ZeroStockTradingActionMessage ==
    [ trackingNumber      |-> [i \in 1 .. 2 |-> 0],
      timeStamp           |-> [i \in 1 .. 6 |-> 0],
      stock               |-> [i \in 1 .. 8 |-> 0],
      securityClass       |-> [i \in 1 .. 1 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0],
      reason              |-> [i \in 1 .. 4 |-> 0] ]

(* Stock Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStockTradingActionMessage ==
    { ZeroStockTradingActionMessage }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.timeStamp = one] : one \in Sample(6) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reason = one] : one \in Sample(4) }

(***************************************************************************)
(* Reg Sho Restriction Message: 17 bytes                                   *)
(***************************************************************************)

RegShoRestrictionMessage ==
    [ trackingNumber : Sample(2),
      timeStamp      : Sample(6),
      stock          : Sample(8),
      regShoAction   : Sample(1) ]

EncodeRegShoRestrictionMessage(message) ==
    message.trackingNumber
        \o message.timeStamp
        \o message.stock
        \o message.regShoAction

DecodeRegShoRestrictionMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timeStamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timeStamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timeStamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(stock.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timeStamp      |-> timeStamp.value,
         stock          |-> stock.value,
         regShoAction   |-> regShoAction.value ], regShoAction.rest)

ZeroRegShoRestrictionMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timeStamp      |-> [i \in 1 .. 6 |-> 0],
      stock          |-> [i \in 1 .. 8 |-> 0],
      regShoAction   |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Restriction Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoRestrictionMessage ==
    { ZeroRegShoRestrictionMessage }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.timeStamp = one] : one \in Sample(6) }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Mwcb Decline Level Message: 32 bytes                                    *)
(***************************************************************************)

MwcbDeclineLevelMessage ==
    [ trackingNumber : Sample(2),
      timeStamp      : Sample(6),
      level1         : Sample(8),
      level2         : Sample(8),
      level3         : Sample(8) ]

EncodeMwcbDeclineLevelMessage(message) ==
    message.trackingNumber
        \o message.timeStamp
        \o message.level1
        \o message.level2
        \o message.level3

DecodeMwcbDeclineLevelMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timeStamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timeStamp.ok THEN Fail ELSE
    LET level1 == ReadBytes(timeStamp.rest, 8) IN IF ~level1.ok THEN Fail ELSE
    LET level2 == ReadBytes(level1.rest, 8) IN IF ~level2.ok THEN Fail ELSE
    LET level3 == ReadBytes(level2.rest, 8) IN IF ~level3.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timeStamp      |-> timeStamp.value,
         level1         |-> level1.value,
         level2         |-> level2.value,
         level3         |-> level3.value ], level3.rest)

ZeroMwcbDeclineLevelMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timeStamp      |-> [i \in 1 .. 6 |-> 0],
      level1         |-> [i \in 1 .. 8 |-> 0],
      level2         |-> [i \in 1 .. 8 |-> 0],
      level3         |-> [i \in 1 .. 8 |-> 0] ]

(* Mwcb Decline Level Message at zero, then each field in turn at the values it is checked at *)
CheckedMwcbDeclineLevelMessage ==
    { ZeroMwcbDeclineLevelMessage }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.timeStamp = one] : one \in Sample(6) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level1 = one] : one \in Sample(8) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level2 = one] : one \in Sample(8) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level3 = one] : one \in Sample(8) }

(***************************************************************************)
(* Mwcb Breach Message: 9 bytes                                            *)
(***************************************************************************)

MwcbBreachMessage ==
    [ trackingNumber : Sample(2),
      timeStamp      : Sample(6),
      breachedLevel  : Sample(1) ]

EncodeMwcbBreachMessage(message) ==
    message.trackingNumber
        \o message.timeStamp
        \o message.breachedLevel

DecodeMwcbBreachMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timeStamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timeStamp.ok THEN Fail ELSE
    LET breachedLevel == ReadBytes(timeStamp.rest, 1) IN IF ~breachedLevel.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timeStamp      |-> timeStamp.value,
         breachedLevel  |-> breachedLevel.value ], breachedLevel.rest)

ZeroMwcbBreachMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timeStamp      |-> [i \in 1 .. 6 |-> 0],
      breachedLevel  |-> [i \in 1 .. 1 |-> 0] ]

(* Mwcb Breach Message at zero, then each field in turn at the values it is checked at *)
CheckedMwcbBreachMessage ==
    { ZeroMwcbBreachMessage }
        \cup { [ZeroMwcbBreachMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroMwcbBreachMessage EXCEPT !.timeStamp = one] : one \in Sample(6) }
        \cup { [ZeroMwcbBreachMessage EXCEPT !.breachedLevel = one] : one \in Sample(1) }

(***************************************************************************)
(* Operational Halt Message: 18 bytes                                      *)
(***************************************************************************)

OperationalHaltMessage ==
    [ trackingNumber        : Sample(2),
      timeStamp             : Sample(6),
      stock                 : Sample(8),
      marketCode            : Sample(1),
      operationalHaltAction : Sample(1) ]

EncodeOperationalHaltMessage(message) ==
    message.trackingNumber
        \o message.timeStamp
        \o message.stock
        \o message.marketCode
        \o message.operationalHaltAction

DecodeOperationalHaltMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timeStamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timeStamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timeStamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET marketCode == ReadBytes(stock.rest, 1) IN IF ~marketCode.ok THEN Fail ELSE
    LET operationalHaltAction == ReadBytes(marketCode.rest, 1) IN IF ~operationalHaltAction.ok THEN Fail ELSE
    Ok([ trackingNumber        |-> trackingNumber.value,
         timeStamp             |-> timeStamp.value,
         stock                 |-> stock.value,
         marketCode            |-> marketCode.value,
         operationalHaltAction |-> operationalHaltAction.value ], operationalHaltAction.rest)

ZeroOperationalHaltMessage ==
    [ trackingNumber        |-> [i \in 1 .. 2 |-> 0],
      timeStamp             |-> [i \in 1 .. 6 |-> 0],
      stock                 |-> [i \in 1 .. 8 |-> 0],
      marketCode            |-> [i \in 1 .. 1 |-> 0],
      operationalHaltAction |-> [i \in 1 .. 1 |-> 0] ]

(* Operational Halt Message at zero, then each field in turn at the values it is checked at *)
CheckedOperationalHaltMessage ==
    { ZeroOperationalHaltMessage }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.timeStamp = one] : one \in Sample(6) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.marketCode = one] : one \in Sample(1) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.operationalHaltAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Bbo Quotation Message: 33 bytes                                         *)
(***************************************************************************)

BboQuotationMessage ==
    [ trackingNumber : Sample(2),
      timeStamp      : Sample(6),
      stock          : Sample(8),
      securityClass  : Sample(1),
      bestBidPrice   : Sample(4),
      bestBidSize    : Sample(4),
      bestOfferPrice : Sample(4),
      bestOfferSize  : Sample(4) ]

EncodeBboQuotationMessage(message) ==
    message.trackingNumber
        \o message.timeStamp
        \o message.stock
        \o message.securityClass
        \o message.bestBidPrice
        \o message.bestBidSize
        \o message.bestOfferPrice
        \o message.bestOfferSize

DecodeBboQuotationMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timeStamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timeStamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timeStamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET securityClass == ReadBytes(stock.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET bestBidPrice == ReadBytes(securityClass.rest, 4) IN IF ~bestBidPrice.ok THEN Fail ELSE
    LET bestBidSize == ReadBytes(bestBidPrice.rest, 4) IN IF ~bestBidSize.ok THEN Fail ELSE
    LET bestOfferPrice == ReadBytes(bestBidSize.rest, 4) IN IF ~bestOfferPrice.ok THEN Fail ELSE
    LET bestOfferSize == ReadBytes(bestOfferPrice.rest, 4) IN IF ~bestOfferSize.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timeStamp      |-> timeStamp.value,
         stock          |-> stock.value,
         securityClass  |-> securityClass.value,
         bestBidPrice   |-> bestBidPrice.value,
         bestBidSize    |-> bestBidSize.value,
         bestOfferPrice |-> bestOfferPrice.value,
         bestOfferSize  |-> bestOfferSize.value ], bestOfferSize.rest)

ZeroBboQuotationMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timeStamp      |-> [i \in 1 .. 6 |-> 0],
      stock          |-> [i \in 1 .. 8 |-> 0],
      securityClass  |-> [i \in 1 .. 1 |-> 0],
      bestBidPrice   |-> [i \in 1 .. 4 |-> 0],
      bestBidSize    |-> [i \in 1 .. 4 |-> 0],
      bestOfferPrice |-> [i \in 1 .. 4 |-> 0],
      bestOfferSize  |-> [i \in 1 .. 4 |-> 0] ]

(* Bbo Quotation Message at zero, then each field in turn at the values it is checked at *)
CheckedBboQuotationMessage ==
    { ZeroBboQuotationMessage }
        \cup { [ZeroBboQuotationMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroBboQuotationMessage EXCEPT !.timeStamp = one] : one \in Sample(6) }
        \cup { [ZeroBboQuotationMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroBboQuotationMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroBboQuotationMessage EXCEPT !.bestBidPrice = one] : one \in Sample(4) }
        \cup { [ZeroBboQuotationMessage EXCEPT !.bestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroBboQuotationMessage EXCEPT !.bestOfferPrice = one] : one \in Sample(4) }
        \cup { [ZeroBboQuotationMessage EXCEPT !.bestOfferSize = one] : one \in Sample(4) }

(***************************************************************************)
(* Price Improvement Message: 17 bytes                                     *)
(***************************************************************************)

PriceImprovementMessage ==
    [ tracking     : Sample(2),
      timeStamp    : Sample(6),
      stock        : Sample(8),
      interestFlag : Sample(1) ]

EncodePriceImprovementMessage(message) ==
    message.tracking
        \o message.timeStamp
        \o message.stock
        \o message.interestFlag

DecodePriceImprovementMessage(bytes) ==
    LET tracking == ReadBytes(bytes, 2) IN IF ~tracking.ok THEN Fail ELSE
    LET timeStamp == ReadBytes(tracking.rest, 6) IN IF ~timeStamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timeStamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET interestFlag == ReadBytes(stock.rest, 1) IN IF ~interestFlag.ok THEN Fail ELSE
    Ok([ tracking     |-> tracking.value,
         timeStamp    |-> timeStamp.value,
         stock        |-> stock.value,
         interestFlag |-> interestFlag.value ], interestFlag.rest)

ZeroPriceImprovementMessage ==
    [ tracking     |-> [i \in 1 .. 2 |-> 0],
      timeStamp    |-> [i \in 1 .. 6 |-> 0],
      stock        |-> [i \in 1 .. 8 |-> 0],
      interestFlag |-> [i \in 1 .. 1 |-> 0] ]

(* Price Improvement Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceImprovementMessage ==
    { ZeroPriceImprovementMessage }
        \cup { [ZeroPriceImprovementMessage EXCEPT !.tracking = one] : one \in Sample(2) }
        \cup { [ZeroPriceImprovementMessage EXCEPT !.timeStamp = one] : one \in Sample(6) }
        \cup { [ZeroPriceImprovementMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroPriceImprovementMessage EXCEPT !.interestFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Ipo Quoting Period Update Message: 25 bytes                             *)
(***************************************************************************)

IpoQuotingPeriodUpdateMessage ==
    [ tracking                     : Sample(2),
      timeStamp                    : Sample(6),
      stock                        : Sample(8),
      ipoQuotationReleaseTime      : Sample(4),
      ipoQuotationReleaseQualifier : Sample(1),
      ipoPrice                     : Sample(4) ]

EncodeIpoQuotingPeriodUpdateMessage(message) ==
    message.tracking
        \o message.timeStamp
        \o message.stock
        \o message.ipoQuotationReleaseTime
        \o message.ipoQuotationReleaseQualifier
        \o message.ipoPrice

DecodeIpoQuotingPeriodUpdateMessage(bytes) ==
    LET tracking == ReadBytes(bytes, 2) IN IF ~tracking.ok THEN Fail ELSE
    LET timeStamp == ReadBytes(tracking.rest, 6) IN IF ~timeStamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timeStamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET ipoQuotationReleaseTime == ReadBytes(stock.rest, 4) IN IF ~ipoQuotationReleaseTime.ok THEN Fail ELSE
    LET ipoQuotationReleaseQualifier == ReadBytes(ipoQuotationReleaseTime.rest, 1) IN IF ~ipoQuotationReleaseQualifier.ok THEN Fail ELSE
    LET ipoPrice == ReadBytes(ipoQuotationReleaseQualifier.rest, 4) IN IF ~ipoPrice.ok THEN Fail ELSE
    Ok([ tracking                     |-> tracking.value,
         timeStamp                    |-> timeStamp.value,
         stock                        |-> stock.value,
         ipoQuotationReleaseTime      |-> ipoQuotationReleaseTime.value,
         ipoQuotationReleaseQualifier |-> ipoQuotationReleaseQualifier.value,
         ipoPrice                     |-> ipoPrice.value ], ipoPrice.rest)

ZeroIpoQuotingPeriodUpdateMessage ==
    [ tracking                     |-> [i \in 1 .. 2 |-> 0],
      timeStamp                    |-> [i \in 1 .. 6 |-> 0],
      stock                        |-> [i \in 1 .. 8 |-> 0],
      ipoQuotationReleaseTime      |-> [i \in 1 .. 4 |-> 0],
      ipoQuotationReleaseQualifier |-> [i \in 1 .. 1 |-> 0],
      ipoPrice                     |-> [i \in 1 .. 4 |-> 0] ]

(* Ipo Quoting Period Update Message at zero, then each field in turn at the values it is checked at *)
CheckedIpoQuotingPeriodUpdateMessage ==
    { ZeroIpoQuotingPeriodUpdateMessage }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.tracking = one] : one \in Sample(2) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.timeStamp = one] : one \in Sample(6) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.ipoQuotationReleaseTime = one] : one \in Sample(4) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.ipoQuotationReleaseQualifier = one] : one \in Sample(1) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.ipoPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
StockDirectoryMessageCode == 82  \* "R"
StockTradingActionMessageCode == 72  \* "H"
RegShoRestrictionMessageCode == 89  \* "Y"
MwcbDeclineLevelMessageCode == 86  \* "V"
MwcbBreachMessageCode == 87  \* "W"
OperationalHaltMessageCode == 104  \* "h"
BboQuotationMessageCode == 81  \* "Q"
PriceImprovementMessageCode == 78  \* "N"
IpoQuotingPeriodUpdateMessageCode == 75  \* "K"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {StockDirectoryMessageCode}, body : StockDirectoryMessage ]
        \cup [ tag : {StockTradingActionMessageCode}, body : StockTradingActionMessage ]
        \cup [ tag : {RegShoRestrictionMessageCode}, body : RegShoRestrictionMessage ]
        \cup [ tag : {MwcbDeclineLevelMessageCode}, body : MwcbDeclineLevelMessage ]
        \cup [ tag : {MwcbBreachMessageCode}, body : MwcbBreachMessage ]
        \cup [ tag : {OperationalHaltMessageCode}, body : OperationalHaltMessage ]
        \cup [ tag : {BboQuotationMessageCode}, body : BboQuotationMessage ]
        \cup [ tag : {PriceImprovementMessageCode}, body : PriceImprovementMessage ]
        \cup [ tag : {IpoQuotingPeriodUpdateMessageCode}, body : IpoQuotingPeriodUpdateMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = StockDirectoryMessageCode -> EncodeStockDirectoryMessage(message.body)
      [] message.tag = StockTradingActionMessageCode -> EncodeStockTradingActionMessage(message.body)
      [] message.tag = RegShoRestrictionMessageCode -> EncodeRegShoRestrictionMessage(message.body)
      [] message.tag = MwcbDeclineLevelMessageCode -> EncodeMwcbDeclineLevelMessage(message.body)
      [] message.tag = MwcbBreachMessageCode -> EncodeMwcbBreachMessage(message.body)
      [] message.tag = OperationalHaltMessageCode -> EncodeOperationalHaltMessage(message.body)
      [] message.tag = BboQuotationMessageCode -> EncodeBboQuotationMessage(message.body)
      [] message.tag = PriceImprovementMessageCode -> EncodePriceImprovementMessage(message.body)
      [] message.tag = IpoQuotingPeriodUpdateMessageCode -> EncodeIpoQuotingPeriodUpdateMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = StockDirectoryMessageCode -> DecodeStockDirectoryMessage(bytes)
              [] tag = StockTradingActionMessageCode -> DecodeStockTradingActionMessage(bytes)
              [] tag = RegShoRestrictionMessageCode -> DecodeRegShoRestrictionMessage(bytes)
              [] tag = MwcbDeclineLevelMessageCode -> DecodeMwcbDeclineLevelMessage(bytes)
              [] tag = MwcbBreachMessageCode -> DecodeMwcbBreachMessage(bytes)
              [] tag = OperationalHaltMessageCode -> DecodeOperationalHaltMessage(bytes)
              [] tag = BboQuotationMessageCode -> DecodeBboQuotationMessage(bytes)
              [] tag = PriceImprovementMessageCode -> DecodePriceImprovementMessage(bytes)
              [] tag = IpoQuotingPeriodUpdateMessageCode -> DecodeIpoQuotingPeriodUpdateMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> StockDirectoryMessageCode, body |-> one] : one \in CheckedStockDirectoryMessage }
        \cup { [tag |-> StockTradingActionMessageCode, body |-> one] : one \in CheckedStockTradingActionMessage }
        \cup { [tag |-> RegShoRestrictionMessageCode, body |-> one] : one \in CheckedRegShoRestrictionMessage }
        \cup { [tag |-> MwcbDeclineLevelMessageCode, body |-> one] : one \in CheckedMwcbDeclineLevelMessage }
        \cup { [tag |-> MwcbBreachMessageCode, body |-> one] : one \in CheckedMwcbBreachMessage }
        \cup { [tag |-> OperationalHaltMessageCode, body |-> one] : one \in CheckedOperationalHaltMessage }
        \cup { [tag |-> BboQuotationMessageCode, body |-> one] : one \in CheckedBboQuotationMessage }
        \cup { [tag |-> PriceImprovementMessageCode, body |-> one] : one \in CheckedPriceImprovementMessage }
        \cup { [tag |-> IpoQuotingPeriodUpdateMessageCode, body |-> one] : one \in CheckedIpoQuotingPeriodUpdateMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the field that counts them says *)
RECURSIVE ReadMessageList(_, _)
ReadMessageList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockDirectoryMessageCode, body |-> ZeroStockDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockTradingActionMessageCode, body |-> ZeroStockTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RegShoRestrictionMessageCode, body |-> ZeroRegShoRestrictionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MwcbDeclineLevelMessageCode, body |-> ZeroMwcbDeclineLevelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MwcbBreachMessageCode, body |-> ZeroMwcbBreachMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OperationalHaltMessageCode, body |-> ZeroOperationalHaltMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BboQuotationMessageCode, body |-> ZeroBboQuotationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PriceImprovementMessageCode, body |-> ZeroPriceImprovementMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IpoQuotingPeriodUpdateMessageCode, body |-> ZeroIpoQuotingPeriodUpdateMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session        : Sample(10),
      sequenceNumber : Sample(8),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequenceNumber
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockDirectoryMessage ==
    \A message \in CheckedStockDirectoryMessage :
        LET read == DecodeStockDirectoryMessage(EncodeStockDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockTradingActionMessage ==
    \A message \in CheckedStockTradingActionMessage :
        LET read == DecodeStockTradingActionMessage(EncodeStockTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reg Sho Restriction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegShoRestrictionMessage ==
    \A message \in CheckedRegShoRestrictionMessage :
        LET read == DecodeRegShoRestrictionMessage(EncodeRegShoRestrictionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mwcb Decline Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMwcbDeclineLevelMessage ==
    \A message \in CheckedMwcbDeclineLevelMessage :
        LET read == DecodeMwcbDeclineLevelMessage(EncodeMwcbDeclineLevelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mwcb Breach Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMwcbBreachMessage ==
    \A message \in CheckedMwcbBreachMessage :
        LET read == DecodeMwcbBreachMessage(EncodeMwcbBreachMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Operational Halt Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOperationalHaltMessage ==
    \A message \in CheckedOperationalHaltMessage :
        LET read == DecodeOperationalHaltMessage(EncodeOperationalHaltMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bbo Quotation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBboQuotationMessage ==
    \A message \in CheckedBboQuotationMessage :
        LET read == DecodeBboQuotationMessage(EncodeBboQuotationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Improvement Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceImprovementMessage ==
    \A message \in CheckedPriceImprovementMessage :
        LET read == DecodePriceImprovementMessage(EncodePriceImprovementMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ipo Quoting Period Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIpoQuotingPeriodUpdateMessage ==
    \A message \in CheckedIpoQuotingPeriodUpdateMessage :
        LET read == DecodeIpoQuotingPeriodUpdateMessage(EncodeIpoQuotingPeriodUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripPacket ==
    \A message \in CheckedPacket :
        LET read == DecodePacket(EncodePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
