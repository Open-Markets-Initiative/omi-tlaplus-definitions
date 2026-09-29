------------------- MODULE NsmEquities_NlsPlus_v4_0_2026 -------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Last Sale Plus v4.0.2026                                       *)
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
      timestamp      : Sample(6),
      eventCode      : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         eventCode      |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      eventCode      |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Report Message: 64 bytes                                          *)
(***************************************************************************)

TradeReportMessage ==
    [ trackingNumber                    : Sample(2),
      timestamp                         : Sample(6),
      clientTimestamp                   : Sample(8),
      originatingMarketCenterIdentifier : Sample(1),
      issueSymbol                       : Sample(8),
      securityClass                     : Sample(1),
      tradeControlNumber                : Sample(10),
      tradePrice                        : Sample(8),
      tradeSize                         : Sample(8),
      saleConditionModifier             : Sample(4),
      consolidatedVolume                : Sample(8) ]

EncodeTradeReportMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.clientTimestamp
        \o message.originatingMarketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.tradeControlNumber
        \o message.tradePrice
        \o message.tradeSize
        \o message.saleConditionModifier
        \o message.consolidatedVolume

DecodeTradeReportMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET clientTimestamp == ReadBytes(timestamp.rest, 8) IN IF ~clientTimestamp.ok THEN Fail ELSE
    LET originatingMarketCenterIdentifier == ReadBytes(clientTimestamp.rest, 1) IN IF ~originatingMarketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(originatingMarketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET tradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~tradeControlNumber.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradeControlNumber.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeSize == ReadBytes(tradePrice.rest, 8) IN IF ~tradeSize.ok THEN Fail ELSE
    LET saleConditionModifier == ReadBytes(tradeSize.rest, 4) IN IF ~saleConditionModifier.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(saleConditionModifier.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    Ok([ trackingNumber                    |-> trackingNumber.value,
         timestamp                         |-> timestamp.value,
         clientTimestamp                   |-> clientTimestamp.value,
         originatingMarketCenterIdentifier |-> originatingMarketCenterIdentifier.value,
         issueSymbol                       |-> issueSymbol.value,
         securityClass                     |-> securityClass.value,
         tradeControlNumber                |-> tradeControlNumber.value,
         tradePrice                        |-> tradePrice.value,
         tradeSize                         |-> tradeSize.value,
         saleConditionModifier             |-> saleConditionModifier.value,
         consolidatedVolume                |-> consolidatedVolume.value ], consolidatedVolume.rest)

ZeroTradeReportMessage ==
    [ trackingNumber                    |-> [i \in 1 .. 2 |-> 0],
      timestamp                         |-> [i \in 1 .. 6 |-> 0],
      clientTimestamp                   |-> [i \in 1 .. 8 |-> 0],
      originatingMarketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                       |-> [i \in 1 .. 8 |-> 0],
      securityClass                     |-> [i \in 1 .. 1 |-> 0],
      tradeControlNumber                |-> [i \in 1 .. 10 |-> 0],
      tradePrice                        |-> [i \in 1 .. 8 |-> 0],
      tradeSize                         |-> [i \in 1 .. 8 |-> 0],
      saleConditionModifier             |-> [i \in 1 .. 4 |-> 0],
      consolidatedVolume                |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessage ==
    { ZeroTradeReportMessage }
        \cup { [ZeroTradeReportMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradeReportMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroTradeReportMessage EXCEPT !.clientTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.originatingMarketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeSize = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.saleConditionModifier = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Cancel Error Message: 64 bytes                                    *)
(***************************************************************************)

TradeCancelErrorMessage ==
    [ trackingNumber                    : Sample(2),
      timestamp                         : Sample(6),
      clientTimestamp                   : Sample(8),
      originatingMarketCenterIdentifier : Sample(1),
      issueSymbol                       : Sample(8),
      securityClass                     : Sample(1),
      originalTradeControlNumber        : Sample(10),
      originalTradePrice                : Sample(8),
      originalTradeSize                 : Sample(8),
      originalSaleConditionModifier     : Sample(4),
      consolidatedVolume                : Sample(8) ]

EncodeTradeCancelErrorMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.clientTimestamp
        \o message.originatingMarketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.originalTradeControlNumber
        \o message.originalTradePrice
        \o message.originalTradeSize
        \o message.originalSaleConditionModifier
        \o message.consolidatedVolume

DecodeTradeCancelErrorMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET clientTimestamp == ReadBytes(timestamp.rest, 8) IN IF ~clientTimestamp.ok THEN Fail ELSE
    LET originatingMarketCenterIdentifier == ReadBytes(clientTimestamp.rest, 1) IN IF ~originatingMarketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(originatingMarketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET originalTradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~originalTradeControlNumber.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeControlNumber.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalTradePrice.rest, 8) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET originalSaleConditionModifier == ReadBytes(originalTradeSize.rest, 4) IN IF ~originalSaleConditionModifier.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(originalSaleConditionModifier.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    Ok([ trackingNumber                    |-> trackingNumber.value,
         timestamp                         |-> timestamp.value,
         clientTimestamp                   |-> clientTimestamp.value,
         originatingMarketCenterIdentifier |-> originatingMarketCenterIdentifier.value,
         issueSymbol                       |-> issueSymbol.value,
         securityClass                     |-> securityClass.value,
         originalTradeControlNumber        |-> originalTradeControlNumber.value,
         originalTradePrice                |-> originalTradePrice.value,
         originalTradeSize                 |-> originalTradeSize.value,
         originalSaleConditionModifier     |-> originalSaleConditionModifier.value,
         consolidatedVolume                |-> consolidatedVolume.value ], consolidatedVolume.rest)

ZeroTradeCancelErrorMessage ==
    [ trackingNumber                    |-> [i \in 1 .. 2 |-> 0],
      timestamp                         |-> [i \in 1 .. 6 |-> 0],
      clientTimestamp                   |-> [i \in 1 .. 8 |-> 0],
      originatingMarketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                       |-> [i \in 1 .. 8 |-> 0],
      securityClass                     |-> [i \in 1 .. 1 |-> 0],
      originalTradeControlNumber        |-> [i \in 1 .. 10 |-> 0],
      originalTradePrice                |-> [i \in 1 .. 8 |-> 0],
      originalTradeSize                 |-> [i \in 1 .. 8 |-> 0],
      originalSaleConditionModifier     |-> [i \in 1 .. 4 |-> 0],
      consolidatedVolume                |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Cancel Error Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelErrorMessage ==
    { ZeroTradeCancelErrorMessage }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.clientTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originatingMarketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalTradeSize = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.originalSaleConditionModifier = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelErrorMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Correction Message: 94 bytes                                      *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ trackingNumber                    : Sample(2),
      timestamp                         : Sample(6),
      clientTimestamp                   : Sample(8),
      originatingMarketCenterIdentifier : Sample(1),
      issueSymbol                       : Sample(8),
      securityClass                     : Sample(1),
      originalTradeControlNumber        : Sample(10),
      originalTradePrice                : Sample(8),
      originalTradeSize                 : Sample(8),
      originalSaleConditionModifier     : Sample(4),
      correctedTradeControlNumber       : Sample(10),
      correctedTradePrice               : Sample(8),
      correctedTradeSize                : Sample(8),
      correctedSaleConditionModifier    : Sample(4),
      consolidatedVolume                : Sample(8) ]

EncodeTradeCorrectionMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.clientTimestamp
        \o message.originatingMarketCenterIdentifier
        \o message.issueSymbol
        \o message.securityClass
        \o message.originalTradeControlNumber
        \o message.originalTradePrice
        \o message.originalTradeSize
        \o message.originalSaleConditionModifier
        \o message.correctedTradeControlNumber
        \o message.correctedTradePrice
        \o message.correctedTradeSize
        \o message.correctedSaleConditionModifier
        \o message.consolidatedVolume

DecodeTradeCorrectionMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET clientTimestamp == ReadBytes(timestamp.rest, 8) IN IF ~clientTimestamp.ok THEN Fail ELSE
    LET originatingMarketCenterIdentifier == ReadBytes(clientTimestamp.rest, 1) IN IF ~originatingMarketCenterIdentifier.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(originatingMarketCenterIdentifier.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET originalTradeControlNumber == ReadBytes(securityClass.rest, 10) IN IF ~originalTradeControlNumber.ok THEN Fail ELSE
    LET originalTradePrice == ReadBytes(originalTradeControlNumber.rest, 8) IN IF ~originalTradePrice.ok THEN Fail ELSE
    LET originalTradeSize == ReadBytes(originalTradePrice.rest, 8) IN IF ~originalTradeSize.ok THEN Fail ELSE
    LET originalSaleConditionModifier == ReadBytes(originalTradeSize.rest, 4) IN IF ~originalSaleConditionModifier.ok THEN Fail ELSE
    LET correctedTradeControlNumber == ReadBytes(originalSaleConditionModifier.rest, 10) IN IF ~correctedTradeControlNumber.ok THEN Fail ELSE
    LET correctedTradePrice == ReadBytes(correctedTradeControlNumber.rest, 8) IN IF ~correctedTradePrice.ok THEN Fail ELSE
    LET correctedTradeSize == ReadBytes(correctedTradePrice.rest, 8) IN IF ~correctedTradeSize.ok THEN Fail ELSE
    LET correctedSaleConditionModifier == ReadBytes(correctedTradeSize.rest, 4) IN IF ~correctedSaleConditionModifier.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(correctedSaleConditionModifier.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    Ok([ trackingNumber                    |-> trackingNumber.value,
         timestamp                         |-> timestamp.value,
         clientTimestamp                   |-> clientTimestamp.value,
         originatingMarketCenterIdentifier |-> originatingMarketCenterIdentifier.value,
         issueSymbol                       |-> issueSymbol.value,
         securityClass                     |-> securityClass.value,
         originalTradeControlNumber        |-> originalTradeControlNumber.value,
         originalTradePrice                |-> originalTradePrice.value,
         originalTradeSize                 |-> originalTradeSize.value,
         originalSaleConditionModifier     |-> originalSaleConditionModifier.value,
         correctedTradeControlNumber       |-> correctedTradeControlNumber.value,
         correctedTradePrice               |-> correctedTradePrice.value,
         correctedTradeSize                |-> correctedTradeSize.value,
         correctedSaleConditionModifier    |-> correctedSaleConditionModifier.value,
         consolidatedVolume                |-> consolidatedVolume.value ], consolidatedVolume.rest)

ZeroTradeCorrectionMessage ==
    [ trackingNumber                    |-> [i \in 1 .. 2 |-> 0],
      timestamp                         |-> [i \in 1 .. 6 |-> 0],
      clientTimestamp                   |-> [i \in 1 .. 8 |-> 0],
      originatingMarketCenterIdentifier |-> [i \in 1 .. 1 |-> 0],
      issueSymbol                       |-> [i \in 1 .. 8 |-> 0],
      securityClass                     |-> [i \in 1 .. 1 |-> 0],
      originalTradeControlNumber        |-> [i \in 1 .. 10 |-> 0],
      originalTradePrice                |-> [i \in 1 .. 8 |-> 0],
      originalTradeSize                 |-> [i \in 1 .. 8 |-> 0],
      originalSaleConditionModifier     |-> [i \in 1 .. 4 |-> 0],
      correctedTradeControlNumber       |-> [i \in 1 .. 10 |-> 0],
      correctedTradePrice               |-> [i \in 1 .. 8 |-> 0],
      correctedTradeSize                |-> [i \in 1 .. 8 |-> 0],
      correctedSaleConditionModifier    |-> [i \in 1 .. 4 |-> 0],
      consolidatedVolume                |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.clientTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originatingMarketCenterIdentifier = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeSize = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalSaleConditionModifier = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeControlNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedTradeSize = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.correctedSaleConditionModifier = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }

(***************************************************************************)
(* Stock Trading Action Message: 22 bytes                                  *)
(***************************************************************************)

StockTradingActionMessage ==
    [ trackingNumber      : Sample(2),
      timestamp           : Sample(6),
      issueSymbol         : Sample(8),
      securityClass       : Sample(1),
      currentTradingState : Sample(1),
      reason              : Sample(4) ]

EncodeStockTradingActionMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.issueSymbol
        \o message.securityClass
        \o message.currentTradingState
        \o message.reason

DecodeStockTradingActionMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(timestamp.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(securityClass.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    LET reason == ReadBytes(currentTradingState.rest, 4) IN IF ~reason.ok THEN Fail ELSE
    Ok([ trackingNumber      |-> trackingNumber.value,
         timestamp           |-> timestamp.value,
         issueSymbol         |-> issueSymbol.value,
         securityClass       |-> securityClass.value,
         currentTradingState |-> currentTradingState.value,
         reason              |-> reason.value ], reason.rest)

ZeroStockTradingActionMessage ==
    [ trackingNumber      |-> [i \in 1 .. 2 |-> 0],
      timestamp           |-> [i \in 1 .. 6 |-> 0],
      issueSymbol         |-> [i \in 1 .. 8 |-> 0],
      securityClass       |-> [i \in 1 .. 1 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0],
      reason              |-> [i \in 1 .. 4 |-> 0] ]

(* Stock Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStockTradingActionMessage ==
    { ZeroStockTradingActionMessage }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reason = one] : one \in Sample(4) }

(***************************************************************************)
(* Reg Sho Short Sale Price Test Restricted Indicator Message: 17 bytes    *)
(***************************************************************************)

RegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(6),
      issueSymbol    : Sample(8),
      regShoAction   : Sample(1) ]

EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.issueSymbol
        \o message.regShoAction

DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(timestamp.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(issueSymbol.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         issueSymbol    |-> issueSymbol.value,
         regShoAction   |-> regShoAction.value ], regShoAction.rest)

ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      issueSymbol    |-> [i \in 1 .. 8 |-> 0],
      regShoAction   |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Short Sale Price Test Restricted Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    { ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Directory Message: 48 bytes                                       *)
(***************************************************************************)

StockDirectoryMessage ==
    [ trackingNumber              : Sample(2),
      timestamp                   : Sample(6),
      stock                       : Sample(8),
      marketCategory              : Sample(1),
      financialStatusIndicator    : Sample(1),
      roundLotSize                : Sample(4),
      roundLotsOnly               : Sample(1),
      issueClassification         : Sample(1),
      issueSubType                : Sample(2),
      authenticity                : Sample(1),
      shortSaleThresholdIndicator : Sample(1),
      ipoFlag                     : Sample(1),
      luldReferencePriceTier      : Sample(1),
      etpFlag                     : Sample(1),
      etpLeverageFactor           : Sample(4),
      inverseIndicator            : Sample(1),
      bloombergId                 : Sample(12) ]

EncodeStockDirectoryMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.stock
        \o message.marketCategory
        \o message.financialStatusIndicator
        \o message.roundLotSize
        \o message.roundLotsOnly
        \o message.issueClassification
        \o message.issueSubType
        \o message.authenticity
        \o message.shortSaleThresholdIndicator
        \o message.ipoFlag
        \o message.luldReferencePriceTier
        \o message.etpFlag
        \o message.etpLeverageFactor
        \o message.inverseIndicator
        \o message.bloombergId

DecodeStockDirectoryMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET marketCategory == ReadBytes(stock.rest, 1) IN IF ~marketCategory.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(marketCategory.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(financialStatusIndicator.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET roundLotsOnly == ReadBytes(roundLotSize.rest, 1) IN IF ~roundLotsOnly.ok THEN Fail ELSE
    LET issueClassification == ReadBytes(roundLotsOnly.rest, 1) IN IF ~issueClassification.ok THEN Fail ELSE
    LET issueSubType == ReadBytes(issueClassification.rest, 2) IN IF ~issueSubType.ok THEN Fail ELSE
    LET authenticity == ReadBytes(issueSubType.rest, 1) IN IF ~authenticity.ok THEN Fail ELSE
    LET shortSaleThresholdIndicator == ReadBytes(authenticity.rest, 1) IN IF ~shortSaleThresholdIndicator.ok THEN Fail ELSE
    LET ipoFlag == ReadBytes(shortSaleThresholdIndicator.rest, 1) IN IF ~ipoFlag.ok THEN Fail ELSE
    LET luldReferencePriceTier == ReadBytes(ipoFlag.rest, 1) IN IF ~luldReferencePriceTier.ok THEN Fail ELSE
    LET etpFlag == ReadBytes(luldReferencePriceTier.rest, 1) IN IF ~etpFlag.ok THEN Fail ELSE
    LET etpLeverageFactor == ReadBytes(etpFlag.rest, 4) IN IF ~etpLeverageFactor.ok THEN Fail ELSE
    LET inverseIndicator == ReadBytes(etpLeverageFactor.rest, 1) IN IF ~inverseIndicator.ok THEN Fail ELSE
    LET bloombergId == ReadBytes(inverseIndicator.rest, 12) IN IF ~bloombergId.ok THEN Fail ELSE
    Ok([ trackingNumber              |-> trackingNumber.value,
         timestamp                   |-> timestamp.value,
         stock                       |-> stock.value,
         marketCategory              |-> marketCategory.value,
         financialStatusIndicator    |-> financialStatusIndicator.value,
         roundLotSize                |-> roundLotSize.value,
         roundLotsOnly               |-> roundLotsOnly.value,
         issueClassification         |-> issueClassification.value,
         issueSubType                |-> issueSubType.value,
         authenticity                |-> authenticity.value,
         shortSaleThresholdIndicator |-> shortSaleThresholdIndicator.value,
         ipoFlag                     |-> ipoFlag.value,
         luldReferencePriceTier      |-> luldReferencePriceTier.value,
         etpFlag                     |-> etpFlag.value,
         etpLeverageFactor           |-> etpLeverageFactor.value,
         inverseIndicator            |-> inverseIndicator.value,
         bloombergId                 |-> bloombergId.value ], bloombergId.rest)

ZeroStockDirectoryMessage ==
    [ trackingNumber              |-> [i \in 1 .. 2 |-> 0],
      timestamp                   |-> [i \in 1 .. 6 |-> 0],
      stock                       |-> [i \in 1 .. 8 |-> 0],
      marketCategory              |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator    |-> [i \in 1 .. 1 |-> 0],
      roundLotSize                |-> [i \in 1 .. 4 |-> 0],
      roundLotsOnly               |-> [i \in 1 .. 1 |-> 0],
      issueClassification         |-> [i \in 1 .. 1 |-> 0],
      issueSubType                |-> [i \in 1 .. 2 |-> 0],
      authenticity                |-> [i \in 1 .. 1 |-> 0],
      shortSaleThresholdIndicator |-> [i \in 1 .. 1 |-> 0],
      ipoFlag                     |-> [i \in 1 .. 1 |-> 0],
      luldReferencePriceTier      |-> [i \in 1 .. 1 |-> 0],
      etpFlag                     |-> [i \in 1 .. 1 |-> 0],
      etpLeverageFactor           |-> [i \in 1 .. 4 |-> 0],
      inverseIndicator            |-> [i \in 1 .. 1 |-> 0],
      bloombergId                 |-> [i \in 1 .. 12 |-> 0] ]

(* Stock Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedStockDirectoryMessage ==
    { ZeroStockDirectoryMessage }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.marketCategory = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotsOnly = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.issueClassification = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.issueSubType = one] : one \in Sample(2) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.authenticity = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.shortSaleThresholdIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.ipoFlag = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.luldReferencePriceTier = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.etpFlag = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.etpLeverageFactor = one] : one \in Sample(4) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.inverseIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.bloombergId = one] : one \in Sample(12) }

(***************************************************************************)
(* Adjusted Closing Price Message: 25 bytes                                *)
(***************************************************************************)

AdjustedClosingPriceMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(6),
      issueSymbol          : Sample(8),
      securityClass        : Sample(1),
      adjustedClosingPrice : Sample(8) ]

EncodeAdjustedClosingPriceMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.issueSymbol
        \o message.securityClass
        \o message.adjustedClosingPrice

DecodeAdjustedClosingPriceMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(timestamp.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET adjustedClosingPrice == ReadBytes(securityClass.rest, 8) IN IF ~adjustedClosingPrice.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         issueSymbol          |-> issueSymbol.value,
         securityClass        |-> securityClass.value,
         adjustedClosingPrice |-> adjustedClosingPrice.value ], adjustedClosingPrice.rest)

ZeroAdjustedClosingPriceMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 6 |-> 0],
      issueSymbol          |-> [i \in 1 .. 8 |-> 0],
      securityClass        |-> [i \in 1 .. 1 |-> 0],
      adjustedClosingPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Adjusted Closing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedAdjustedClosingPriceMessage ==
    { ZeroAdjustedClosingPriceMessage }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroAdjustedClosingPriceMessage EXCEPT !.adjustedClosingPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* End Of Day Trade Summary Message: 57 bytes                              *)
(***************************************************************************)

EndOfDayTradeSummaryMessage ==
    [ trackingNumber           : Sample(2),
      timestamp                : Sample(6),
      issueSymbol              : Sample(8),
      securityClass            : Sample(1),
      consolidatedHighPrice    : Sample(8),
      consolidatedLowPrice     : Sample(8),
      consolidatedClosingPrice : Sample(8),
      consolidatedVolume       : Sample(8),
      consolidatedOpenPrice    : Sample(8) ]

EncodeEndOfDayTradeSummaryMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.issueSymbol
        \o message.securityClass
        \o message.consolidatedHighPrice
        \o message.consolidatedLowPrice
        \o message.consolidatedClosingPrice
        \o message.consolidatedVolume
        \o message.consolidatedOpenPrice

DecodeEndOfDayTradeSummaryMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(timestamp.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET consolidatedHighPrice == ReadBytes(securityClass.rest, 8) IN IF ~consolidatedHighPrice.ok THEN Fail ELSE
    LET consolidatedLowPrice == ReadBytes(consolidatedHighPrice.rest, 8) IN IF ~consolidatedLowPrice.ok THEN Fail ELSE
    LET consolidatedClosingPrice == ReadBytes(consolidatedLowPrice.rest, 8) IN IF ~consolidatedClosingPrice.ok THEN Fail ELSE
    LET consolidatedVolume == ReadBytes(consolidatedClosingPrice.rest, 8) IN IF ~consolidatedVolume.ok THEN Fail ELSE
    LET consolidatedOpenPrice == ReadBytes(consolidatedVolume.rest, 8) IN IF ~consolidatedOpenPrice.ok THEN Fail ELSE
    Ok([ trackingNumber           |-> trackingNumber.value,
         timestamp                |-> timestamp.value,
         issueSymbol              |-> issueSymbol.value,
         securityClass            |-> securityClass.value,
         consolidatedHighPrice    |-> consolidatedHighPrice.value,
         consolidatedLowPrice     |-> consolidatedLowPrice.value,
         consolidatedClosingPrice |-> consolidatedClosingPrice.value,
         consolidatedVolume       |-> consolidatedVolume.value,
         consolidatedOpenPrice    |-> consolidatedOpenPrice.value ], consolidatedOpenPrice.rest)

ZeroEndOfDayTradeSummaryMessage ==
    [ trackingNumber           |-> [i \in 1 .. 2 |-> 0],
      timestamp                |-> [i \in 1 .. 6 |-> 0],
      issueSymbol              |-> [i \in 1 .. 8 |-> 0],
      securityClass            |-> [i \in 1 .. 1 |-> 0],
      consolidatedHighPrice    |-> [i \in 1 .. 8 |-> 0],
      consolidatedLowPrice     |-> [i \in 1 .. 8 |-> 0],
      consolidatedClosingPrice |-> [i \in 1 .. 8 |-> 0],
      consolidatedVolume       |-> [i \in 1 .. 8 |-> 0],
      consolidatedOpenPrice    |-> [i \in 1 .. 8 |-> 0] ]

(* End Of Day Trade Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfDayTradeSummaryMessage ==
    { ZeroEndOfDayTradeSummaryMessage }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedHighPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedLowPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedVolume = one] : one \in Sample(8) }
        \cup { [ZeroEndOfDayTradeSummaryMessage EXCEPT !.consolidatedOpenPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Ipo Information Message: 26 bytes                                       *)
(***************************************************************************)

IpoInformationMessage ==
    [ trackingNumber        : Sample(2),
      timestamp             : Sample(6),
      issueSymbol           : Sample(8),
      securityClass         : Sample(1),
      referenceForNetChange : Sample(1),
      referencePrice        : Sample(8) ]

EncodeIpoInformationMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.issueSymbol
        \o message.securityClass
        \o message.referenceForNetChange
        \o message.referencePrice

DecodeIpoInformationMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET issueSymbol == ReadBytes(timestamp.rest, 8) IN IF ~issueSymbol.ok THEN Fail ELSE
    LET securityClass == ReadBytes(issueSymbol.rest, 1) IN IF ~securityClass.ok THEN Fail ELSE
    LET referenceForNetChange == ReadBytes(securityClass.rest, 1) IN IF ~referenceForNetChange.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(referenceForNetChange.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    Ok([ trackingNumber        |-> trackingNumber.value,
         timestamp             |-> timestamp.value,
         issueSymbol           |-> issueSymbol.value,
         securityClass         |-> securityClass.value,
         referenceForNetChange |-> referenceForNetChange.value,
         referencePrice        |-> referencePrice.value ], referencePrice.rest)

ZeroIpoInformationMessage ==
    [ trackingNumber        |-> [i \in 1 .. 2 |-> 0],
      timestamp             |-> [i \in 1 .. 6 |-> 0],
      issueSymbol           |-> [i \in 1 .. 8 |-> 0],
      securityClass         |-> [i \in 1 .. 1 |-> 0],
      referenceForNetChange |-> [i \in 1 .. 1 |-> 0],
      referencePrice        |-> [i \in 1 .. 8 |-> 0] ]

(* Ipo Information Message at zero, then each field in turn at the values it is checked at *)
CheckedIpoInformationMessage ==
    { ZeroIpoInformationMessage }
        \cup { [ZeroIpoInformationMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroIpoInformationMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroIpoInformationMessage EXCEPT !.issueSymbol = one] : one \in Sample(8) }
        \cup { [ZeroIpoInformationMessage EXCEPT !.securityClass = one] : one \in Sample(1) }
        \cup { [ZeroIpoInformationMessage EXCEPT !.referenceForNetChange = one] : one \in Sample(1) }
        \cup { [ZeroIpoInformationMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Mwcb Decline Level Message: 32 bytes                                    *)
(***************************************************************************)

MwcbDeclineLevelMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(6),
      level1         : Sample(8),
      level2         : Sample(8),
      level3         : Sample(8) ]

EncodeMwcbDeclineLevelMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.level1
        \o message.level2
        \o message.level3

DecodeMwcbDeclineLevelMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET level1 == ReadBytes(timestamp.rest, 8) IN IF ~level1.ok THEN Fail ELSE
    LET level2 == ReadBytes(level1.rest, 8) IN IF ~level2.ok THEN Fail ELSE
    LET level3 == ReadBytes(level2.rest, 8) IN IF ~level3.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         level1         |-> level1.value,
         level2         |-> level2.value,
         level3         |-> level3.value ], level3.rest)

ZeroMwcbDeclineLevelMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      level1         |-> [i \in 1 .. 8 |-> 0],
      level2         |-> [i \in 1 .. 8 |-> 0],
      level3         |-> [i \in 1 .. 8 |-> 0] ]

(* Mwcb Decline Level Message at zero, then each field in turn at the values it is checked at *)
CheckedMwcbDeclineLevelMessage ==
    { ZeroMwcbDeclineLevelMessage }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level1 = one] : one \in Sample(8) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level2 = one] : one \in Sample(8) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level3 = one] : one \in Sample(8) }

(***************************************************************************)
(* Mwcb Status Message: 9 bytes                                            *)
(***************************************************************************)

MwcbStatusMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(6),
      breachedLevel  : Sample(1) ]

EncodeMwcbStatusMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.breachedLevel

DecodeMwcbStatusMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET breachedLevel == ReadBytes(timestamp.rest, 1) IN IF ~breachedLevel.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         breachedLevel  |-> breachedLevel.value ], breachedLevel.rest)

ZeroMwcbStatusMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      breachedLevel  |-> [i \in 1 .. 1 |-> 0] ]

(* Mwcb Status Message at zero, then each field in turn at the values it is checked at *)
CheckedMwcbStatusMessage ==
    { ZeroMwcbStatusMessage }
        \cup { [ZeroMwcbStatusMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroMwcbStatusMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroMwcbStatusMessage EXCEPT !.breachedLevel = one] : one \in Sample(1) }

(***************************************************************************)
(* Ipo Quoting Period Update Message: 29 bytes                             *)
(***************************************************************************)

IpoQuotingPeriodUpdateMessage ==
    [ trackingNumber               : Sample(2),
      timestamp                    : Sample(6),
      stock                        : Sample(8),
      ipoQuotationReleaseTime      : Sample(4),
      ipoQuotationReleaseQualifier : Sample(1),
      ipoPrice                     : Sample(8) ]

EncodeIpoQuotingPeriodUpdateMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.stock
        \o message.ipoQuotationReleaseTime
        \o message.ipoQuotationReleaseQualifier
        \o message.ipoPrice

DecodeIpoQuotingPeriodUpdateMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET ipoQuotationReleaseTime == ReadBytes(stock.rest, 4) IN IF ~ipoQuotationReleaseTime.ok THEN Fail ELSE
    LET ipoQuotationReleaseQualifier == ReadBytes(ipoQuotationReleaseTime.rest, 1) IN IF ~ipoQuotationReleaseQualifier.ok THEN Fail ELSE
    LET ipoPrice == ReadBytes(ipoQuotationReleaseQualifier.rest, 8) IN IF ~ipoPrice.ok THEN Fail ELSE
    Ok([ trackingNumber               |-> trackingNumber.value,
         timestamp                    |-> timestamp.value,
         stock                        |-> stock.value,
         ipoQuotationReleaseTime      |-> ipoQuotationReleaseTime.value,
         ipoQuotationReleaseQualifier |-> ipoQuotationReleaseQualifier.value,
         ipoPrice                     |-> ipoPrice.value ], ipoPrice.rest)

ZeroIpoQuotingPeriodUpdateMessage ==
    [ trackingNumber               |-> [i \in 1 .. 2 |-> 0],
      timestamp                    |-> [i \in 1 .. 6 |-> 0],
      stock                        |-> [i \in 1 .. 8 |-> 0],
      ipoQuotationReleaseTime      |-> [i \in 1 .. 4 |-> 0],
      ipoQuotationReleaseQualifier |-> [i \in 1 .. 1 |-> 0],
      ipoPrice                     |-> [i \in 1 .. 8 |-> 0] ]

(* Ipo Quoting Period Update Message at zero, then each field in turn at the values it is checked at *)
CheckedIpoQuotingPeriodUpdateMessage ==
    { ZeroIpoQuotingPeriodUpdateMessage }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.ipoQuotationReleaseTime = one] : one \in Sample(4) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.ipoQuotationReleaseQualifier = one] : one \in Sample(1) }
        \cup { [ZeroIpoQuotingPeriodUpdateMessage EXCEPT !.ipoPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Operational Halt Message: 18 bytes                                      *)
(***************************************************************************)

OperationalHaltMessage ==
    [ trackingNumber        : Sample(2),
      timestamp             : Sample(6),
      stockAlpha8           : Sample(8),
      marketCode            : Sample(1),
      operationalHaltAction : Sample(1) ]

EncodeOperationalHaltMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.stockAlpha8
        \o message.marketCode
        \o message.operationalHaltAction

DecodeOperationalHaltMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET stockAlpha8 == ReadBytes(timestamp.rest, 8) IN IF ~stockAlpha8.ok THEN Fail ELSE
    LET marketCode == ReadBytes(stockAlpha8.rest, 1) IN IF ~marketCode.ok THEN Fail ELSE
    LET operationalHaltAction == ReadBytes(marketCode.rest, 1) IN IF ~operationalHaltAction.ok THEN Fail ELSE
    Ok([ trackingNumber        |-> trackingNumber.value,
         timestamp             |-> timestamp.value,
         stockAlpha8           |-> stockAlpha8.value,
         marketCode            |-> marketCode.value,
         operationalHaltAction |-> operationalHaltAction.value ], operationalHaltAction.rest)

ZeroOperationalHaltMessage ==
    [ trackingNumber        |-> [i \in 1 .. 2 |-> 0],
      timestamp             |-> [i \in 1 .. 6 |-> 0],
      stockAlpha8           |-> [i \in 1 .. 8 |-> 0],
      marketCode            |-> [i \in 1 .. 1 |-> 0],
      operationalHaltAction |-> [i \in 1 .. 1 |-> 0] ]

(* Operational Halt Message at zero, then each field in turn at the values it is checked at *)
CheckedOperationalHaltMessage ==
    { ZeroOperationalHaltMessage }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.stockAlpha8 = one] : one \in Sample(8) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.marketCode = one] : one \in Sample(1) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.operationalHaltAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
TradeReportMessageCode == 101  \* "e"
TradeCancelErrorMessageCode == 111  \* "o"
TradeCorrectionMessageCode == 98  \* "b"
StockTradingActionMessageCode == 72  \* "H"
RegShoShortSalePriceTestRestrictedIndicatorMessageCode == 89  \* "Y"
StockDirectoryMessageCode == 82  \* "R"
AdjustedClosingPriceMessageCode == 103  \* "g"
EndOfDayTradeSummaryMessageCode == 112  \* "p"
IpoInformationMessageCode == 105  \* "i"
MwcbDeclineLevelMessageCode == 86  \* "V"
MwcbStatusMessageCode == 87  \* "W"
IpoQuotingPeriodUpdateMessageCode == 107  \* "k"
OperationalHaltMessageCode == 104  \* "h"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {TradeReportMessageCode}, body : TradeReportMessage ]
        \cup [ tag : {TradeCancelErrorMessageCode}, body : TradeCancelErrorMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
        \cup [ tag : {StockTradingActionMessageCode}, body : StockTradingActionMessage ]
        \cup [ tag : {RegShoShortSalePriceTestRestrictedIndicatorMessageCode}, body : RegShoShortSalePriceTestRestrictedIndicatorMessage ]
        \cup [ tag : {StockDirectoryMessageCode}, body : StockDirectoryMessage ]
        \cup [ tag : {AdjustedClosingPriceMessageCode}, body : AdjustedClosingPriceMessage ]
        \cup [ tag : {EndOfDayTradeSummaryMessageCode}, body : EndOfDayTradeSummaryMessage ]
        \cup [ tag : {IpoInformationMessageCode}, body : IpoInformationMessage ]
        \cup [ tag : {MwcbDeclineLevelMessageCode}, body : MwcbDeclineLevelMessage ]
        \cup [ tag : {MwcbStatusMessageCode}, body : MwcbStatusMessage ]
        \cup [ tag : {IpoQuotingPeriodUpdateMessageCode}, body : IpoQuotingPeriodUpdateMessage ]
        \cup [ tag : {OperationalHaltMessageCode}, body : OperationalHaltMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = TradeReportMessageCode -> EncodeTradeReportMessage(message.body)
      [] message.tag = TradeCancelErrorMessageCode -> EncodeTradeCancelErrorMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
      [] message.tag = StockTradingActionMessageCode -> EncodeStockTradingActionMessage(message.body)
      [] message.tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message.body)
      [] message.tag = StockDirectoryMessageCode -> EncodeStockDirectoryMessage(message.body)
      [] message.tag = AdjustedClosingPriceMessageCode -> EncodeAdjustedClosingPriceMessage(message.body)
      [] message.tag = EndOfDayTradeSummaryMessageCode -> EncodeEndOfDayTradeSummaryMessage(message.body)
      [] message.tag = IpoInformationMessageCode -> EncodeIpoInformationMessage(message.body)
      [] message.tag = MwcbDeclineLevelMessageCode -> EncodeMwcbDeclineLevelMessage(message.body)
      [] message.tag = MwcbStatusMessageCode -> EncodeMwcbStatusMessage(message.body)
      [] message.tag = IpoQuotingPeriodUpdateMessageCode -> EncodeIpoQuotingPeriodUpdateMessage(message.body)
      [] message.tag = OperationalHaltMessageCode -> EncodeOperationalHaltMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = TradeReportMessageCode -> DecodeTradeReportMessage(bytes)
              [] tag = TradeCancelErrorMessageCode -> DecodeTradeCancelErrorMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] tag = StockTradingActionMessageCode -> DecodeStockTradingActionMessage(bytes)
              [] tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes)
              [] tag = StockDirectoryMessageCode -> DecodeStockDirectoryMessage(bytes)
              [] tag = AdjustedClosingPriceMessageCode -> DecodeAdjustedClosingPriceMessage(bytes)
              [] tag = EndOfDayTradeSummaryMessageCode -> DecodeEndOfDayTradeSummaryMessage(bytes)
              [] tag = IpoInformationMessageCode -> DecodeIpoInformationMessage(bytes)
              [] tag = MwcbDeclineLevelMessageCode -> DecodeMwcbDeclineLevelMessage(bytes)
              [] tag = MwcbStatusMessageCode -> DecodeMwcbStatusMessage(bytes)
              [] tag = IpoQuotingPeriodUpdateMessageCode -> DecodeIpoQuotingPeriodUpdateMessage(bytes)
              [] tag = OperationalHaltMessageCode -> DecodeOperationalHaltMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> TradeReportMessageCode, body |-> one] : one \in CheckedTradeReportMessage }
        \cup { [tag |-> TradeCancelErrorMessageCode, body |-> one] : one \in CheckedTradeCancelErrorMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
        \cup { [tag |-> StockTradingActionMessageCode, body |-> one] : one \in CheckedStockTradingActionMessage }
        \cup { [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> one] : one \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [tag |-> StockDirectoryMessageCode, body |-> one] : one \in CheckedStockDirectoryMessage }
        \cup { [tag |-> AdjustedClosingPriceMessageCode, body |-> one] : one \in CheckedAdjustedClosingPriceMessage }
        \cup { [tag |-> EndOfDayTradeSummaryMessageCode, body |-> one] : one \in CheckedEndOfDayTradeSummaryMessage }
        \cup { [tag |-> IpoInformationMessageCode, body |-> one] : one \in CheckedIpoInformationMessage }
        \cup { [tag |-> MwcbDeclineLevelMessageCode, body |-> one] : one \in CheckedMwcbDeclineLevelMessage }
        \cup { [tag |-> MwcbStatusMessageCode, body |-> one] : one \in CheckedMwcbStatusMessage }
        \cup { [tag |-> IpoQuotingPeriodUpdateMessageCode, body |-> one] : one \in CheckedIpoQuotingPeriodUpdateMessage }
        \cup { [tag |-> OperationalHaltMessageCode, body |-> one] : one \in CheckedOperationalHaltMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeReportMessageCode, body |-> ZeroTradeReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCancelErrorMessageCode, body |-> ZeroTradeCancelErrorMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCorrectionMessageCode, body |-> ZeroTradeCorrectionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockTradingActionMessageCode, body |-> ZeroStockTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StockDirectoryMessageCode, body |-> ZeroStockDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AdjustedClosingPriceMessageCode, body |-> ZeroAdjustedClosingPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfDayTradeSummaryMessageCode, body |-> ZeroEndOfDayTradeSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IpoInformationMessageCode, body |-> ZeroIpoInformationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MwcbDeclineLevelMessageCode, body |-> ZeroMwcbDeclineLevelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MwcbStatusMessageCode, body |-> ZeroMwcbStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IpoQuotingPeriodUpdateMessageCode, body |-> ZeroIpoQuotingPeriodUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OperationalHaltMessageCode, body |-> ZeroOperationalHaltMessage]] }

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

(* Every Trade Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeReportMessage ==
    \A message \in CheckedTradeReportMessage :
        LET read == DecodeTradeReportMessage(EncodeTradeReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelErrorMessage ==
    \A message \in CheckedTradeCancelErrorMessage :
        LET read == DecodeTradeCancelErrorMessage(EncodeTradeCancelErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Correction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCorrectionMessage ==
    \A message \in CheckedTradeCorrectionMessage :
        LET read == DecodeTradeCorrectionMessage(EncodeTradeCorrectionMessage(message))
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

(* Every Reg Sho Short Sale Price Test Restricted Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    \A message \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage :
        LET read == DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message))
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

(* Every Adjusted Closing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAdjustedClosingPriceMessage ==
    \A message \in CheckedAdjustedClosingPriceMessage :
        LET read == DecodeAdjustedClosingPriceMessage(EncodeAdjustedClosingPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Day Trade Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfDayTradeSummaryMessage ==
    \A message \in CheckedEndOfDayTradeSummaryMessage :
        LET read == DecodeEndOfDayTradeSummaryMessage(EncodeEndOfDayTradeSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ipo Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIpoInformationMessage ==
    \A message \in CheckedIpoInformationMessage :
        LET read == DecodeIpoInformationMessage(EncodeIpoInformationMessage(message))
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

(* Every Mwcb Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMwcbStatusMessage ==
    \A message \in CheckedMwcbStatusMessage :
        LET read == DecodeMwcbStatusMessage(EncodeMwcbStatusMessage(message))
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

(* Every Operational Halt Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOperationalHaltMessage ==
    \A message \in CheckedOperationalHaltMessage :
        LET read == DecodeOperationalHaltMessage(EncodeOperationalHaltMessage(message))
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
