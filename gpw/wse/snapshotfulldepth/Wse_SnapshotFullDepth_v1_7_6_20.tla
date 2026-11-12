------------------ MODULE Wse_SnapshotFullDepth_v1_7_6_20 ------------------
(***************************************************************************)
(* Giełda Papierów Wartościowych w Warszawie Warsaw Stock Exchange Full    *)
(* Depth Snapshot v1.7.6                                                   *)
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
(* Note: Items is written as 3 slots, however many of them the count       *)
(* beside it says are in use.                                              *)
(*                                                                         *)
(* Note: Buy is written as 5 slots, however many of them the count beside  *)
(* it says are in use.                                                     *)
(*                                                                         *)
(* Note: Sell is written as 5 slots, however many of them the count beside *)
(* it says are in use.                                                     *)
(*                                                                         *)
(* Note: Message is of no one width: each is read by its own fields, and   *)
(* since every reading of it takes at least 42 bytes off the reader the    *)
(* run ends where the data does.                                           *)
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
(* Week Plan: 5 bytes                                                      *)
(***************************************************************************)

WeekPlan ==
    [ calendarId : Sample(4),
      weekdays   : Sample(1) ]

EncodeWeekPlan(message) ==
    message.calendarId
        \o message.weekdays

DecodeWeekPlan(bytes) ==
    LET calendarId == ReadBytes(bytes, 4) IN IF ~calendarId.ok THEN Fail ELSE
    LET weekdays == ReadBytes(calendarId.rest, 1) IN IF ~weekdays.ok THEN Fail ELSE
    Ok([ calendarId |-> calendarId.value,
         weekdays   |-> weekdays.value ], weekdays.rest)

ZeroWeekPlan ==
    [ calendarId |-> [i \in 1 .. 4 |-> 0],
      weekdays   |-> [i \in 1 .. 1 |-> 0] ]

(* Week Plan at zero, then each field in turn at the values it is checked at *)
CheckedWeekPlan ==
    { ZeroWeekPlan }
        \cup { [ZeroWeekPlan EXCEPT !.calendarId = one] : one \in Sample(4) }
        \cup { [ZeroWeekPlan EXCEPT !.weekdays = one] : one \in Sample(1) }

(***************************************************************************)
(* Calendar Exception: 9 bytes                                             *)
(***************************************************************************)

CalendarException ==
    [ calendarId            : Sample(4),
      calendarExceptionDate : Sample(4),
      calendarExceptionType : Sample(1) ]

EncodeCalendarException(message) ==
    message.calendarId
        \o message.calendarExceptionDate
        \o message.calendarExceptionType

DecodeCalendarException(bytes) ==
    LET calendarId == ReadBytes(bytes, 4) IN IF ~calendarId.ok THEN Fail ELSE
    LET calendarExceptionDate == ReadBytes(calendarId.rest, 4) IN IF ~calendarExceptionDate.ok THEN Fail ELSE
    LET calendarExceptionType == ReadBytes(calendarExceptionDate.rest, 1) IN IF ~calendarExceptionType.ok THEN Fail ELSE
    Ok([ calendarId            |-> calendarId.value,
         calendarExceptionDate |-> calendarExceptionDate.value,
         calendarExceptionType |-> calendarExceptionType.value ], calendarExceptionType.rest)

ZeroCalendarException ==
    [ calendarId            |-> [i \in 1 .. 4 |-> 0],
      calendarExceptionDate |-> [i \in 1 .. 4 |-> 0],
      calendarExceptionType |-> [i \in 1 .. 1 |-> 0] ]

(* Calendar Exception at zero, then each field in turn at the values it is checked at *)
CheckedCalendarException ==
    { ZeroCalendarException }
        \cup { [ZeroCalendarException EXCEPT !.calendarId = one] : one \in Sample(4) }
        \cup { [ZeroCalendarException EXCEPT !.calendarExceptionDate = one] : one \in Sample(4) }
        \cup { [ZeroCalendarException EXCEPT !.calendarExceptionType = one] : one \in Sample(1) }

(***************************************************************************)
(* Tick Table Entry: 20 bytes                                              *)
(***************************************************************************)

TickTableEntry ==
    [ tickSize    : Sample(8),
      lowerBound  : Sample(8),
      tickTableId : Sample(4) ]

EncodeTickTableEntry(message) ==
    message.tickSize
        \o message.lowerBound
        \o message.tickTableId

DecodeTickTableEntry(bytes) ==
    LET tickSize == ReadBytes(bytes, 8) IN IF ~tickSize.ok THEN Fail ELSE
    LET lowerBound == ReadBytes(tickSize.rest, 8) IN IF ~lowerBound.ok THEN Fail ELSE
    LET tickTableId == ReadBytes(lowerBound.rest, 4) IN IF ~tickTableId.ok THEN Fail ELSE
    Ok([ tickSize    |-> tickSize.value,
         lowerBound  |-> lowerBound.value,
         tickTableId |-> tickTableId.value ], tickTableId.rest)

ZeroTickTableEntry ==
    [ tickSize    |-> [i \in 1 .. 8 |-> 0],
      lowerBound  |-> [i \in 1 .. 8 |-> 0],
      tickTableId |-> [i \in 1 .. 4 |-> 0] ]

(* Tick Table Entry at zero, then each field in turn at the values it is checked at *)
CheckedTickTableEntry ==
    { ZeroTickTableEntry }
        \cup { [ZeroTickTableEntry EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroTickTableEntry EXCEPT !.lowerBound = one] : one \in Sample(8) }
        \cup { [ZeroTickTableEntry EXCEPT !.tickTableId = one] : one \in Sample(4) }

(***************************************************************************)
(* Collar Table Entry: 54 bytes                                            *)
(***************************************************************************)

CollarTableEntry ==
    [ collarTableId    : Sample(4),
      collarMode       : Sample(1),
      collarExpression : Sample(1),
      collarLowerBound : Sample(8),
      collarValue      : Sample(8),
      collarLowerBid   : Sample(8),
      collarUpperBid   : Sample(8),
      collarUpperAsk   : Sample(8),
      collarLowerAsk   : Sample(8) ]

EncodeCollarTableEntry(message) ==
    message.collarTableId
        \o message.collarMode
        \o message.collarExpression
        \o message.collarLowerBound
        \o message.collarValue
        \o message.collarLowerBid
        \o message.collarUpperBid
        \o message.collarUpperAsk
        \o message.collarLowerAsk

DecodeCollarTableEntry(bytes) ==
    LET collarTableId == ReadBytes(bytes, 4) IN IF ~collarTableId.ok THEN Fail ELSE
    LET collarMode == ReadBytes(collarTableId.rest, 1) IN IF ~collarMode.ok THEN Fail ELSE
    LET collarExpression == ReadBytes(collarMode.rest, 1) IN IF ~collarExpression.ok THEN Fail ELSE
    LET collarLowerBound == ReadBytes(collarExpression.rest, 8) IN IF ~collarLowerBound.ok THEN Fail ELSE
    LET collarValue == ReadBytes(collarLowerBound.rest, 8) IN IF ~collarValue.ok THEN Fail ELSE
    LET collarLowerBid == ReadBytes(collarValue.rest, 8) IN IF ~collarLowerBid.ok THEN Fail ELSE
    LET collarUpperBid == ReadBytes(collarLowerBid.rest, 8) IN IF ~collarUpperBid.ok THEN Fail ELSE
    LET collarUpperAsk == ReadBytes(collarUpperBid.rest, 8) IN IF ~collarUpperAsk.ok THEN Fail ELSE
    LET collarLowerAsk == ReadBytes(collarUpperAsk.rest, 8) IN IF ~collarLowerAsk.ok THEN Fail ELSE
    Ok([ collarTableId    |-> collarTableId.value,
         collarMode       |-> collarMode.value,
         collarExpression |-> collarExpression.value,
         collarLowerBound |-> collarLowerBound.value,
         collarValue      |-> collarValue.value,
         collarLowerBid   |-> collarLowerBid.value,
         collarUpperBid   |-> collarUpperBid.value,
         collarUpperAsk   |-> collarUpperAsk.value,
         collarLowerAsk   |-> collarLowerAsk.value ], collarLowerAsk.rest)

ZeroCollarTableEntry ==
    [ collarTableId    |-> [i \in 1 .. 4 |-> 0],
      collarMode       |-> [i \in 1 .. 1 |-> 0],
      collarExpression |-> [i \in 1 .. 1 |-> 0],
      collarLowerBound |-> [i \in 1 .. 8 |-> 0],
      collarValue      |-> [i \in 1 .. 8 |-> 0],
      collarLowerBid   |-> [i \in 1 .. 8 |-> 0],
      collarUpperBid   |-> [i \in 1 .. 8 |-> 0],
      collarUpperAsk   |-> [i \in 1 .. 8 |-> 0],
      collarLowerAsk   |-> [i \in 1 .. 8 |-> 0] ]

(* Collar Table Entry at zero, then each field in turn at the values it is checked at *)
CheckedCollarTableEntry ==
    { ZeroCollarTableEntry }
        \cup { [ZeroCollarTableEntry EXCEPT !.collarTableId = one] : one \in Sample(4) }
        \cup { [ZeroCollarTableEntry EXCEPT !.collarMode = one] : one \in Sample(1) }
        \cup { [ZeroCollarTableEntry EXCEPT !.collarExpression = one] : one \in Sample(1) }
        \cup { [ZeroCollarTableEntry EXCEPT !.collarLowerBound = one] : one \in Sample(8) }
        \cup { [ZeroCollarTableEntry EXCEPT !.collarValue = one] : one \in Sample(8) }
        \cup { [ZeroCollarTableEntry EXCEPT !.collarLowerBid = one] : one \in Sample(8) }
        \cup { [ZeroCollarTableEntry EXCEPT !.collarUpperBid = one] : one \in Sample(8) }
        \cup { [ZeroCollarTableEntry EXCEPT !.collarUpperAsk = one] : one \in Sample(8) }
        \cup { [ZeroCollarTableEntry EXCEPT !.collarLowerAsk = one] : one \in Sample(8) }

(***************************************************************************)
(* Trading Phase Schedule Entry: 40 bytes                                  *)
(***************************************************************************)

TradingPhaseScheduleEntry ==
    [ tradingScheduleId                   : Sample(4),
      tradingPhaseId                      : Sample(4),
      tradingPhaseSettlementCycle         : Sample(1),
      tradingPhaseMaxBlockSettlementCycle : Sample(1),
      staticCollarVolatilityAuctionId     : Sample(4),
      dynamicCollarVolatilityAuctionId    : Sample(4),
      tradingPhaseStartTime               : Sample(8),
      tradingPhaseType                    : Sample(1),
      uncrossing                          : Sample(1),
      extStaticCollarVolatilityAuctionId  : Sample(4),
      extDynamicCollarVolatilityAuctionId : Sample(4),
      clatId                              : Sample(4) ]

EncodeTradingPhaseScheduleEntry(message) ==
    message.tradingScheduleId
        \o message.tradingPhaseId
        \o message.tradingPhaseSettlementCycle
        \o message.tradingPhaseMaxBlockSettlementCycle
        \o message.staticCollarVolatilityAuctionId
        \o message.dynamicCollarVolatilityAuctionId
        \o message.tradingPhaseStartTime
        \o message.tradingPhaseType
        \o message.uncrossing
        \o message.extStaticCollarVolatilityAuctionId
        \o message.extDynamicCollarVolatilityAuctionId
        \o message.clatId

DecodeTradingPhaseScheduleEntry(bytes) ==
    LET tradingScheduleId == ReadBytes(bytes, 4) IN IF ~tradingScheduleId.ok THEN Fail ELSE
    LET tradingPhaseId == ReadBytes(tradingScheduleId.rest, 4) IN IF ~tradingPhaseId.ok THEN Fail ELSE
    LET tradingPhaseSettlementCycle == ReadBytes(tradingPhaseId.rest, 1) IN IF ~tradingPhaseSettlementCycle.ok THEN Fail ELSE
    LET tradingPhaseMaxBlockSettlementCycle == ReadBytes(tradingPhaseSettlementCycle.rest, 1) IN IF ~tradingPhaseMaxBlockSettlementCycle.ok THEN Fail ELSE
    LET staticCollarVolatilityAuctionId == ReadBytes(tradingPhaseMaxBlockSettlementCycle.rest, 4) IN IF ~staticCollarVolatilityAuctionId.ok THEN Fail ELSE
    LET dynamicCollarVolatilityAuctionId == ReadBytes(staticCollarVolatilityAuctionId.rest, 4) IN IF ~dynamicCollarVolatilityAuctionId.ok THEN Fail ELSE
    LET tradingPhaseStartTime == ReadBytes(dynamicCollarVolatilityAuctionId.rest, 8) IN IF ~tradingPhaseStartTime.ok THEN Fail ELSE
    LET tradingPhaseType == ReadBytes(tradingPhaseStartTime.rest, 1) IN IF ~tradingPhaseType.ok THEN Fail ELSE
    LET uncrossing == ReadBytes(tradingPhaseType.rest, 1) IN IF ~uncrossing.ok THEN Fail ELSE
    LET extStaticCollarVolatilityAuctionId == ReadBytes(uncrossing.rest, 4) IN IF ~extStaticCollarVolatilityAuctionId.ok THEN Fail ELSE
    LET extDynamicCollarVolatilityAuctionId == ReadBytes(extStaticCollarVolatilityAuctionId.rest, 4) IN IF ~extDynamicCollarVolatilityAuctionId.ok THEN Fail ELSE
    LET clatId == ReadBytes(extDynamicCollarVolatilityAuctionId.rest, 4) IN IF ~clatId.ok THEN Fail ELSE
    Ok([ tradingScheduleId                   |-> tradingScheduleId.value,
         tradingPhaseId                      |-> tradingPhaseId.value,
         tradingPhaseSettlementCycle         |-> tradingPhaseSettlementCycle.value,
         tradingPhaseMaxBlockSettlementCycle |-> tradingPhaseMaxBlockSettlementCycle.value,
         staticCollarVolatilityAuctionId     |-> staticCollarVolatilityAuctionId.value,
         dynamicCollarVolatilityAuctionId    |-> dynamicCollarVolatilityAuctionId.value,
         tradingPhaseStartTime               |-> tradingPhaseStartTime.value,
         tradingPhaseType                    |-> tradingPhaseType.value,
         uncrossing                          |-> uncrossing.value,
         extStaticCollarVolatilityAuctionId  |-> extStaticCollarVolatilityAuctionId.value,
         extDynamicCollarVolatilityAuctionId |-> extDynamicCollarVolatilityAuctionId.value,
         clatId                              |-> clatId.value ], clatId.rest)

ZeroTradingPhaseScheduleEntry ==
    [ tradingScheduleId                   |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseId                      |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseSettlementCycle         |-> [i \in 1 .. 1 |-> 0],
      tradingPhaseMaxBlockSettlementCycle |-> [i \in 1 .. 1 |-> 0],
      staticCollarVolatilityAuctionId     |-> [i \in 1 .. 4 |-> 0],
      dynamicCollarVolatilityAuctionId    |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseStartTime               |-> [i \in 1 .. 8 |-> 0],
      tradingPhaseType                    |-> [i \in 1 .. 1 |-> 0],
      uncrossing                          |-> [i \in 1 .. 1 |-> 0],
      extStaticCollarVolatilityAuctionId  |-> [i \in 1 .. 4 |-> 0],
      extDynamicCollarVolatilityAuctionId |-> [i \in 1 .. 4 |-> 0],
      clatId                              |-> [i \in 1 .. 4 |-> 0] ]

(* Trading Phase Schedule Entry at zero, then each field in turn at the values it is checked at *)
CheckedTradingPhaseScheduleEntry ==
    { ZeroTradingPhaseScheduleEntry }
        \cup { [ZeroTradingPhaseScheduleEntry EXCEPT !.tradingScheduleId = one] : one \in Sample(4) }
        \cup { [ZeroTradingPhaseScheduleEntry EXCEPT !.tradingPhaseId = one] : one \in Sample(4) }
        \cup { [ZeroTradingPhaseScheduleEntry EXCEPT !.tradingPhaseSettlementCycle = one] : one \in Sample(1) }
        \cup { [ZeroTradingPhaseScheduleEntry EXCEPT !.tradingPhaseMaxBlockSettlementCycle = one] : one \in Sample(1) }
        \cup { [ZeroTradingPhaseScheduleEntry EXCEPT !.staticCollarVolatilityAuctionId = one] : one \in Sample(4) }
        \cup { [ZeroTradingPhaseScheduleEntry EXCEPT !.dynamicCollarVolatilityAuctionId = one] : one \in Sample(4) }
        \cup { [ZeroTradingPhaseScheduleEntry EXCEPT !.tradingPhaseStartTime = one] : one \in Sample(8) }
        \cup { [ZeroTradingPhaseScheduleEntry EXCEPT !.tradingPhaseType = one] : one \in Sample(1) }
        \cup { [ZeroTradingPhaseScheduleEntry EXCEPT !.uncrossing = one] : one \in Sample(1) }
        \cup { [ZeroTradingPhaseScheduleEntry EXCEPT !.extStaticCollarVolatilityAuctionId = one] : one \in Sample(4) }
        \cup { [ZeroTradingPhaseScheduleEntry EXCEPT !.extDynamicCollarVolatilityAuctionId = one] : one \in Sample(4) }
        \cup { [ZeroTradingPhaseScheduleEntry EXCEPT !.clatId = one] : one \in Sample(4) }

(***************************************************************************)
(* Market Structure: 63 bytes                                              *)
(***************************************************************************)

MarketStructure ==
    [ id              : Sample(4),
      parentId        : Sample(4),
      mic             : Sample(4),
      name            : Sample(50),
      marketModelType : Sample(1) ]

EncodeMarketStructure(message) ==
    message.id
        \o message.parentId
        \o message.mic
        \o message.name
        \o message.marketModelType

DecodeMarketStructure(bytes) ==
    LET id == ReadBytes(bytes, 4) IN IF ~id.ok THEN Fail ELSE
    LET parentId == ReadBytes(id.rest, 4) IN IF ~parentId.ok THEN Fail ELSE
    LET mic == ReadBytes(parentId.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET name == ReadBytes(mic.rest, 50) IN IF ~name.ok THEN Fail ELSE
    LET marketModelType == ReadBytes(name.rest, 1) IN IF ~marketModelType.ok THEN Fail ELSE
    Ok([ id              |-> id.value,
         parentId        |-> parentId.value,
         mic             |-> mic.value,
         name            |-> name.value,
         marketModelType |-> marketModelType.value ], marketModelType.rest)

ZeroMarketStructure ==
    [ id              |-> [i \in 1 .. 4 |-> 0],
      parentId        |-> [i \in 1 .. 4 |-> 0],
      mic             |-> [i \in 1 .. 4 |-> 0],
      name            |-> [i \in 1 .. 50 |-> 0],
      marketModelType |-> [i \in 1 .. 1 |-> 0] ]

(* Market Structure at zero, then each field in turn at the values it is checked at *)
CheckedMarketStructure ==
    { ZeroMarketStructure }
        \cup { [ZeroMarketStructure EXCEPT !.id = one] : one \in Sample(4) }
        \cup { [ZeroMarketStructure EXCEPT !.parentId = one] : one \in Sample(4) }
        \cup { [ZeroMarketStructure EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroMarketStructure EXCEPT !.name = one] : one \in Sample(50) }
        \cup { [ZeroMarketStructure EXCEPT !.marketModelType = one] : one \in Sample(1) }

(***************************************************************************)
(* Collar Group: 20 bytes                                                  *)
(***************************************************************************)

CollarGroup ==
    [ id                        : Sample(4),
      orderStaticCollarTableId  : Sample(4),
      orderDynamicCollarTableId : Sample(4),
      tradeStaticCollarTableId  : Sample(4),
      tradeDynamicCollarTableId : Sample(4) ]

EncodeCollarGroup(message) ==
    message.id
        \o message.orderStaticCollarTableId
        \o message.orderDynamicCollarTableId
        \o message.tradeStaticCollarTableId
        \o message.tradeDynamicCollarTableId

DecodeCollarGroup(bytes) ==
    LET id == ReadBytes(bytes, 4) IN IF ~id.ok THEN Fail ELSE
    LET orderStaticCollarTableId == ReadBytes(id.rest, 4) IN IF ~orderStaticCollarTableId.ok THEN Fail ELSE
    LET orderDynamicCollarTableId == ReadBytes(orderStaticCollarTableId.rest, 4) IN IF ~orderDynamicCollarTableId.ok THEN Fail ELSE
    LET tradeStaticCollarTableId == ReadBytes(orderDynamicCollarTableId.rest, 4) IN IF ~tradeStaticCollarTableId.ok THEN Fail ELSE
    LET tradeDynamicCollarTableId == ReadBytes(tradeStaticCollarTableId.rest, 4) IN IF ~tradeDynamicCollarTableId.ok THEN Fail ELSE
    Ok([ id                        |-> id.value,
         orderStaticCollarTableId  |-> orderStaticCollarTableId.value,
         orderDynamicCollarTableId |-> orderDynamicCollarTableId.value,
         tradeStaticCollarTableId  |-> tradeStaticCollarTableId.value,
         tradeDynamicCollarTableId |-> tradeDynamicCollarTableId.value ], tradeDynamicCollarTableId.rest)

ZeroCollarGroup ==
    [ id                        |-> [i \in 1 .. 4 |-> 0],
      orderStaticCollarTableId  |-> [i \in 1 .. 4 |-> 0],
      orderDynamicCollarTableId |-> [i \in 1 .. 4 |-> 0],
      tradeStaticCollarTableId  |-> [i \in 1 .. 4 |-> 0],
      tradeDynamicCollarTableId |-> [i \in 1 .. 4 |-> 0] ]

(* Collar Group at zero, then each field in turn at the values it is checked at *)
CheckedCollarGroup ==
    { ZeroCollarGroup }
        \cup { [ZeroCollarGroup EXCEPT !.id = one] : one \in Sample(4) }
        \cup { [ZeroCollarGroup EXCEPT !.orderStaticCollarTableId = one] : one \in Sample(4) }
        \cup { [ZeroCollarGroup EXCEPT !.orderDynamicCollarTableId = one] : one \in Sample(4) }
        \cup { [ZeroCollarGroup EXCEPT !.tradeStaticCollarTableId = one] : one \in Sample(4) }
        \cup { [ZeroCollarGroup EXCEPT !.tradeDynamicCollarTableId = one] : one \in Sample(4) }

(***************************************************************************)
(* External Underlying: 113 bytes                                          *)
(***************************************************************************)

ExternalUnderlying ==
    [ externalUnderlyingId                       : Sample(4),
      productIdentificationProductIdentification : Sample(30),
      productIdentificationType                  : Sample(1),
      productCode                                : Sample(20),
      productName                                : Sample(50),
      mic                                        : Sample(4),
      nominalCurrency                            : Sample(2),
      tradingCurrency                            : Sample(2) ]

EncodeExternalUnderlying(message) ==
    message.externalUnderlyingId
        \o message.productIdentificationProductIdentification
        \o message.productIdentificationType
        \o message.productCode
        \o message.productName
        \o message.mic
        \o message.nominalCurrency
        \o message.tradingCurrency

DecodeExternalUnderlying(bytes) ==
    LET externalUnderlyingId == ReadBytes(bytes, 4) IN IF ~externalUnderlyingId.ok THEN Fail ELSE
    LET productIdentificationProductIdentification == ReadBytes(externalUnderlyingId.rest, 30) IN IF ~productIdentificationProductIdentification.ok THEN Fail ELSE
    LET productIdentificationType == ReadBytes(productIdentificationProductIdentification.rest, 1) IN IF ~productIdentificationType.ok THEN Fail ELSE
    LET productCode == ReadBytes(productIdentificationType.rest, 20) IN IF ~productCode.ok THEN Fail ELSE
    LET productName == ReadBytes(productCode.rest, 50) IN IF ~productName.ok THEN Fail ELSE
    LET mic == ReadBytes(productName.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET nominalCurrency == ReadBytes(mic.rest, 2) IN IF ~nominalCurrency.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(nominalCurrency.rest, 2) IN IF ~tradingCurrency.ok THEN Fail ELSE
    Ok([ externalUnderlyingId                       |-> externalUnderlyingId.value,
         productIdentificationProductIdentification |-> productIdentificationProductIdentification.value,
         productIdentificationType                  |-> productIdentificationType.value,
         productCode                                |-> productCode.value,
         productName                                |-> productName.value,
         mic                                        |-> mic.value,
         nominalCurrency                            |-> nominalCurrency.value,
         tradingCurrency                            |-> tradingCurrency.value ], tradingCurrency.rest)

ZeroExternalUnderlying ==
    [ externalUnderlyingId                       |-> [i \in 1 .. 4 |-> 0],
      productIdentificationProductIdentification |-> [i \in 1 .. 30 |-> 0],
      productIdentificationType                  |-> [i \in 1 .. 1 |-> 0],
      productCode                                |-> [i \in 1 .. 20 |-> 0],
      productName                                |-> [i \in 1 .. 50 |-> 0],
      mic                                        |-> [i \in 1 .. 4 |-> 0],
      nominalCurrency                            |-> [i \in 1 .. 2 |-> 0],
      tradingCurrency                            |-> [i \in 1 .. 2 |-> 0] ]

(* External Underlying at zero, then each field in turn at the values it is checked at *)
CheckedExternalUnderlying ==
    { ZeroExternalUnderlying }
        \cup { [ZeroExternalUnderlying EXCEPT !.externalUnderlyingId = one] : one \in Sample(4) }
        \cup { [ZeroExternalUnderlying EXCEPT !.productIdentificationProductIdentification = one] : one \in Sample(30) }
        \cup { [ZeroExternalUnderlying EXCEPT !.productIdentificationType = one] : one \in Sample(1) }
        \cup { [ZeroExternalUnderlying EXCEPT !.productCode = one] : one \in Sample(20) }
        \cup { [ZeroExternalUnderlying EXCEPT !.productName = one] : one \in Sample(50) }
        \cup { [ZeroExternalUnderlying EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroExternalUnderlying EXCEPT !.nominalCurrency = one] : one \in Sample(2) }
        \cup { [ZeroExternalUnderlying EXCEPT !.tradingCurrency = one] : one \in Sample(2) }

(***************************************************************************)
(* Instrument: 699 bytes                                                   *)
(***************************************************************************)

Instrument ==
    [ instrumentId                               : Sample(4),
      productType                                : Sample(1),
      productSubtype                             : Sample(1),
      firstTradingDate                           : Sample(4),
      lastTradingDate                            : Sample(4),
      productId                                  : Sample(4),
      currency                                   : Sample(2),
      icebergMinValue                            : Sample(8),
      lotSize                                    : Sample(4),
      priceExpressionType                        : Sample(1),
      calendarId                                 : Sample(4),
      marketStructureId                          : Sample(4),
      tickTableId                                : Sample(4),
      referenceInstrumentId                      : Sample(4),
      collarGroupId                              : Sample(4),
      tradingScheduleId                          : Sample(4),
      description                                : Sample(64),
      mic                                        : Sample(4),
      nominalValuePrice                          : Sample(8),
      nominalValueType                           : Sample(1),
      multiplierMultiplier                       : Sample(8),
      strikePrice                                : Sample(8),
      strikePriceCurrency                        : Sample(2),
      productIdentificationProductIdentification : Sample(30),
      productIdentificationType                  : Sample(1),
      settlementCalendarId                       : Sample(4),
      bondCouponType                             : Sample(1),
      preTradeCheckMinPrice                      : Sample(8),
      preTradeCheckMaxPrice                      : Sample(8),
      preTradeCheckMinQuantity                   : Sample(8),
      preTradeCheckMaxQuantity                   : Sample(8),
      preTradeCheckMaxValue                      : Sample(8),
      preTradeCheckMinValue                      : Sample(8),
      liquidity                                  : Sample(1),
      marketModelType                            : Sample(1),
      issuer                                     : Sample(150),
      issuerRegCountry                           : Sample(2),
      underlyingInstrumentId                     : Sample(4),
      productCode                                : Sample(20),
      cfi                                        : Sample(6),
      fisn                                       : Sample(35),
      issueSize                                  : Sample(8),
      nominalCurrency                            : Sample(2),
      usIndicator                                : Sample(1),
      expiryDate                                 : Sample(4),
      versionNumber                              : Sample(1),
      settlementType                             : Sample(1),
      optionType                                 : Sample(1),
      exerciseType                               : Sample(1),
      productName                                : Sample(50),
      referencePrice                             : Sample(8),
      status                                     : Sample(1),
      initialPhaseId                             : Sample(4),
      thresholdMax                               : Sample(8),
      thresholdMin                               : Sample(8),
      isLeverage                                 : Sample(1),
      accruedInterestValue                       : Sample(8),
      kid                                        : Sample(128),
      kidIssueDate                               : Sample(4),
      valueAtRisk                                : Sample(1),
      externalUnderlyingId                       : Sample(4) ]

EncodeInstrument(message) ==
    message.instrumentId
        \o message.productType
        \o message.productSubtype
        \o message.firstTradingDate
        \o message.lastTradingDate
        \o message.productId
        \o message.currency
        \o message.icebergMinValue
        \o message.lotSize
        \o message.priceExpressionType
        \o message.calendarId
        \o message.marketStructureId
        \o message.tickTableId
        \o message.referenceInstrumentId
        \o message.collarGroupId
        \o message.tradingScheduleId
        \o message.description
        \o message.mic
        \o message.nominalValuePrice
        \o message.nominalValueType
        \o message.multiplierMultiplier
        \o message.strikePrice
        \o message.strikePriceCurrency
        \o message.productIdentificationProductIdentification
        \o message.productIdentificationType
        \o message.settlementCalendarId
        \o message.bondCouponType
        \o message.preTradeCheckMinPrice
        \o message.preTradeCheckMaxPrice
        \o message.preTradeCheckMinQuantity
        \o message.preTradeCheckMaxQuantity
        \o message.preTradeCheckMaxValue
        \o message.preTradeCheckMinValue
        \o message.liquidity
        \o message.marketModelType
        \o message.issuer
        \o message.issuerRegCountry
        \o message.underlyingInstrumentId
        \o message.productCode
        \o message.cfi
        \o message.fisn
        \o message.issueSize
        \o message.nominalCurrency
        \o message.usIndicator
        \o message.expiryDate
        \o message.versionNumber
        \o message.settlementType
        \o message.optionType
        \o message.exerciseType
        \o message.productName
        \o message.referencePrice
        \o message.status
        \o message.initialPhaseId
        \o message.thresholdMax
        \o message.thresholdMin
        \o message.isLeverage
        \o message.accruedInterestValue
        \o message.kid
        \o message.kidIssueDate
        \o message.valueAtRisk
        \o message.externalUnderlyingId

DecodeInstrument(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET productType == ReadBytes(instrumentId.rest, 1) IN IF ~productType.ok THEN Fail ELSE
    LET productSubtype == ReadBytes(productType.rest, 1) IN IF ~productSubtype.ok THEN Fail ELSE
    LET firstTradingDate == ReadBytes(productSubtype.rest, 4) IN IF ~firstTradingDate.ok THEN Fail ELSE
    LET lastTradingDate == ReadBytes(firstTradingDate.rest, 4) IN IF ~lastTradingDate.ok THEN Fail ELSE
    LET productId == ReadBytes(lastTradingDate.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET currency == ReadBytes(productId.rest, 2) IN IF ~currency.ok THEN Fail ELSE
    LET icebergMinValue == ReadBytes(currency.rest, 8) IN IF ~icebergMinValue.ok THEN Fail ELSE
    LET lotSize == ReadBytes(icebergMinValue.rest, 4) IN IF ~lotSize.ok THEN Fail ELSE
    LET priceExpressionType == ReadBytes(lotSize.rest, 1) IN IF ~priceExpressionType.ok THEN Fail ELSE
    LET calendarId == ReadBytes(priceExpressionType.rest, 4) IN IF ~calendarId.ok THEN Fail ELSE
    LET marketStructureId == ReadBytes(calendarId.rest, 4) IN IF ~marketStructureId.ok THEN Fail ELSE
    LET tickTableId == ReadBytes(marketStructureId.rest, 4) IN IF ~tickTableId.ok THEN Fail ELSE
    LET referenceInstrumentId == ReadBytes(tickTableId.rest, 4) IN IF ~referenceInstrumentId.ok THEN Fail ELSE
    LET collarGroupId == ReadBytes(referenceInstrumentId.rest, 4) IN IF ~collarGroupId.ok THEN Fail ELSE
    LET tradingScheduleId == ReadBytes(collarGroupId.rest, 4) IN IF ~tradingScheduleId.ok THEN Fail ELSE
    LET description == ReadBytes(tradingScheduleId.rest, 64) IN IF ~description.ok THEN Fail ELSE
    LET mic == ReadBytes(description.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET nominalValuePrice == ReadBytes(mic.rest, 8) IN IF ~nominalValuePrice.ok THEN Fail ELSE
    LET nominalValueType == ReadBytes(nominalValuePrice.rest, 1) IN IF ~nominalValueType.ok THEN Fail ELSE
    LET multiplierMultiplier == ReadBytes(nominalValueType.rest, 8) IN IF ~multiplierMultiplier.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(multiplierMultiplier.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceCurrency == ReadBytes(strikePrice.rest, 2) IN IF ~strikePriceCurrency.ok THEN Fail ELSE
    LET productIdentificationProductIdentification == ReadBytes(strikePriceCurrency.rest, 30) IN IF ~productIdentificationProductIdentification.ok THEN Fail ELSE
    LET productIdentificationType == ReadBytes(productIdentificationProductIdentification.rest, 1) IN IF ~productIdentificationType.ok THEN Fail ELSE
    LET settlementCalendarId == ReadBytes(productIdentificationType.rest, 4) IN IF ~settlementCalendarId.ok THEN Fail ELSE
    LET bondCouponType == ReadBytes(settlementCalendarId.rest, 1) IN IF ~bondCouponType.ok THEN Fail ELSE
    LET preTradeCheckMinPrice == ReadBytes(bondCouponType.rest, 8) IN IF ~preTradeCheckMinPrice.ok THEN Fail ELSE
    LET preTradeCheckMaxPrice == ReadBytes(preTradeCheckMinPrice.rest, 8) IN IF ~preTradeCheckMaxPrice.ok THEN Fail ELSE
    LET preTradeCheckMinQuantity == ReadBytes(preTradeCheckMaxPrice.rest, 8) IN IF ~preTradeCheckMinQuantity.ok THEN Fail ELSE
    LET preTradeCheckMaxQuantity == ReadBytes(preTradeCheckMinQuantity.rest, 8) IN IF ~preTradeCheckMaxQuantity.ok THEN Fail ELSE
    LET preTradeCheckMaxValue == ReadBytes(preTradeCheckMaxQuantity.rest, 8) IN IF ~preTradeCheckMaxValue.ok THEN Fail ELSE
    LET preTradeCheckMinValue == ReadBytes(preTradeCheckMaxValue.rest, 8) IN IF ~preTradeCheckMinValue.ok THEN Fail ELSE
    LET liquidity == ReadBytes(preTradeCheckMinValue.rest, 1) IN IF ~liquidity.ok THEN Fail ELSE
    LET marketModelType == ReadBytes(liquidity.rest, 1) IN IF ~marketModelType.ok THEN Fail ELSE
    LET issuer == ReadBytes(marketModelType.rest, 150) IN IF ~issuer.ok THEN Fail ELSE
    LET issuerRegCountry == ReadBytes(issuer.rest, 2) IN IF ~issuerRegCountry.ok THEN Fail ELSE
    LET underlyingInstrumentId == ReadBytes(issuerRegCountry.rest, 4) IN IF ~underlyingInstrumentId.ok THEN Fail ELSE
    LET productCode == ReadBytes(underlyingInstrumentId.rest, 20) IN IF ~productCode.ok THEN Fail ELSE
    LET cfi == ReadBytes(productCode.rest, 6) IN IF ~cfi.ok THEN Fail ELSE
    LET fisn == ReadBytes(cfi.rest, 35) IN IF ~fisn.ok THEN Fail ELSE
    LET issueSize == ReadBytes(fisn.rest, 8) IN IF ~issueSize.ok THEN Fail ELSE
    LET nominalCurrency == ReadBytes(issueSize.rest, 2) IN IF ~nominalCurrency.ok THEN Fail ELSE
    LET usIndicator == ReadBytes(nominalCurrency.rest, 1) IN IF ~usIndicator.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(usIndicator.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET versionNumber == ReadBytes(expiryDate.rest, 1) IN IF ~versionNumber.ok THEN Fail ELSE
    LET settlementType == ReadBytes(versionNumber.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET optionType == ReadBytes(settlementType.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET exerciseType == ReadBytes(optionType.rest, 1) IN IF ~exerciseType.ok THEN Fail ELSE
    LET productName == ReadBytes(exerciseType.rest, 50) IN IF ~productName.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(productName.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET status == ReadBytes(referencePrice.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET initialPhaseId == ReadBytes(status.rest, 4) IN IF ~initialPhaseId.ok THEN Fail ELSE
    LET thresholdMax == ReadBytes(initialPhaseId.rest, 8) IN IF ~thresholdMax.ok THEN Fail ELSE
    LET thresholdMin == ReadBytes(thresholdMax.rest, 8) IN IF ~thresholdMin.ok THEN Fail ELSE
    LET isLeverage == ReadBytes(thresholdMin.rest, 1) IN IF ~isLeverage.ok THEN Fail ELSE
    LET accruedInterestValue == ReadBytes(isLeverage.rest, 8) IN IF ~accruedInterestValue.ok THEN Fail ELSE
    LET kid == ReadBytes(accruedInterestValue.rest, 128) IN IF ~kid.ok THEN Fail ELSE
    LET kidIssueDate == ReadBytes(kid.rest, 4) IN IF ~kidIssueDate.ok THEN Fail ELSE
    LET valueAtRisk == ReadBytes(kidIssueDate.rest, 1) IN IF ~valueAtRisk.ok THEN Fail ELSE
    LET externalUnderlyingId == ReadBytes(valueAtRisk.rest, 4) IN IF ~externalUnderlyingId.ok THEN Fail ELSE
    Ok([ instrumentId                               |-> instrumentId.value,
         productType                                |-> productType.value,
         productSubtype                             |-> productSubtype.value,
         firstTradingDate                           |-> firstTradingDate.value,
         lastTradingDate                            |-> lastTradingDate.value,
         productId                                  |-> productId.value,
         currency                                   |-> currency.value,
         icebergMinValue                            |-> icebergMinValue.value,
         lotSize                                    |-> lotSize.value,
         priceExpressionType                        |-> priceExpressionType.value,
         calendarId                                 |-> calendarId.value,
         marketStructureId                          |-> marketStructureId.value,
         tickTableId                                |-> tickTableId.value,
         referenceInstrumentId                      |-> referenceInstrumentId.value,
         collarGroupId                              |-> collarGroupId.value,
         tradingScheduleId                          |-> tradingScheduleId.value,
         description                                |-> description.value,
         mic                                        |-> mic.value,
         nominalValuePrice                          |-> nominalValuePrice.value,
         nominalValueType                           |-> nominalValueType.value,
         multiplierMultiplier                       |-> multiplierMultiplier.value,
         strikePrice                                |-> strikePrice.value,
         strikePriceCurrency                        |-> strikePriceCurrency.value,
         productIdentificationProductIdentification |-> productIdentificationProductIdentification.value,
         productIdentificationType                  |-> productIdentificationType.value,
         settlementCalendarId                       |-> settlementCalendarId.value,
         bondCouponType                             |-> bondCouponType.value,
         preTradeCheckMinPrice                      |-> preTradeCheckMinPrice.value,
         preTradeCheckMaxPrice                      |-> preTradeCheckMaxPrice.value,
         preTradeCheckMinQuantity                   |-> preTradeCheckMinQuantity.value,
         preTradeCheckMaxQuantity                   |-> preTradeCheckMaxQuantity.value,
         preTradeCheckMaxValue                      |-> preTradeCheckMaxValue.value,
         preTradeCheckMinValue                      |-> preTradeCheckMinValue.value,
         liquidity                                  |-> liquidity.value,
         marketModelType                            |-> marketModelType.value,
         issuer                                     |-> issuer.value,
         issuerRegCountry                           |-> issuerRegCountry.value,
         underlyingInstrumentId                     |-> underlyingInstrumentId.value,
         productCode                                |-> productCode.value,
         cfi                                        |-> cfi.value,
         fisn                                       |-> fisn.value,
         issueSize                                  |-> issueSize.value,
         nominalCurrency                            |-> nominalCurrency.value,
         usIndicator                                |-> usIndicator.value,
         expiryDate                                 |-> expiryDate.value,
         versionNumber                              |-> versionNumber.value,
         settlementType                             |-> settlementType.value,
         optionType                                 |-> optionType.value,
         exerciseType                               |-> exerciseType.value,
         productName                                |-> productName.value,
         referencePrice                             |-> referencePrice.value,
         status                                     |-> status.value,
         initialPhaseId                             |-> initialPhaseId.value,
         thresholdMax                               |-> thresholdMax.value,
         thresholdMin                               |-> thresholdMin.value,
         isLeverage                                 |-> isLeverage.value,
         accruedInterestValue                       |-> accruedInterestValue.value,
         kid                                        |-> kid.value,
         kidIssueDate                               |-> kidIssueDate.value,
         valueAtRisk                                |-> valueAtRisk.value,
         externalUnderlyingId                       |-> externalUnderlyingId.value ], externalUnderlyingId.rest)

ZeroInstrument ==
    [ instrumentId                               |-> [i \in 1 .. 4 |-> 0],
      productType                                |-> [i \in 1 .. 1 |-> 0],
      productSubtype                             |-> [i \in 1 .. 1 |-> 0],
      firstTradingDate                           |-> [i \in 1 .. 4 |-> 0],
      lastTradingDate                            |-> [i \in 1 .. 4 |-> 0],
      productId                                  |-> [i \in 1 .. 4 |-> 0],
      currency                                   |-> [i \in 1 .. 2 |-> 0],
      icebergMinValue                            |-> [i \in 1 .. 8 |-> 0],
      lotSize                                    |-> [i \in 1 .. 4 |-> 0],
      priceExpressionType                        |-> [i \in 1 .. 1 |-> 0],
      calendarId                                 |-> [i \in 1 .. 4 |-> 0],
      marketStructureId                          |-> [i \in 1 .. 4 |-> 0],
      tickTableId                                |-> [i \in 1 .. 4 |-> 0],
      referenceInstrumentId                      |-> [i \in 1 .. 4 |-> 0],
      collarGroupId                              |-> [i \in 1 .. 4 |-> 0],
      tradingScheduleId                          |-> [i \in 1 .. 4 |-> 0],
      description                                |-> [i \in 1 .. 64 |-> 0],
      mic                                        |-> [i \in 1 .. 4 |-> 0],
      nominalValuePrice                          |-> [i \in 1 .. 8 |-> 0],
      nominalValueType                           |-> [i \in 1 .. 1 |-> 0],
      multiplierMultiplier                       |-> [i \in 1 .. 8 |-> 0],
      strikePrice                                |-> [i \in 1 .. 8 |-> 0],
      strikePriceCurrency                        |-> [i \in 1 .. 2 |-> 0],
      productIdentificationProductIdentification |-> [i \in 1 .. 30 |-> 0],
      productIdentificationType                  |-> [i \in 1 .. 1 |-> 0],
      settlementCalendarId                       |-> [i \in 1 .. 4 |-> 0],
      bondCouponType                             |-> [i \in 1 .. 1 |-> 0],
      preTradeCheckMinPrice                      |-> [i \in 1 .. 8 |-> 0],
      preTradeCheckMaxPrice                      |-> [i \in 1 .. 8 |-> 0],
      preTradeCheckMinQuantity                   |-> [i \in 1 .. 8 |-> 0],
      preTradeCheckMaxQuantity                   |-> [i \in 1 .. 8 |-> 0],
      preTradeCheckMaxValue                      |-> [i \in 1 .. 8 |-> 0],
      preTradeCheckMinValue                      |-> [i \in 1 .. 8 |-> 0],
      liquidity                                  |-> [i \in 1 .. 1 |-> 0],
      marketModelType                            |-> [i \in 1 .. 1 |-> 0],
      issuer                                     |-> [i \in 1 .. 150 |-> 0],
      issuerRegCountry                           |-> [i \in 1 .. 2 |-> 0],
      underlyingInstrumentId                     |-> [i \in 1 .. 4 |-> 0],
      productCode                                |-> [i \in 1 .. 20 |-> 0],
      cfi                                        |-> [i \in 1 .. 6 |-> 0],
      fisn                                       |-> [i \in 1 .. 35 |-> 0],
      issueSize                                  |-> [i \in 1 .. 8 |-> 0],
      nominalCurrency                            |-> [i \in 1 .. 2 |-> 0],
      usIndicator                                |-> [i \in 1 .. 1 |-> 0],
      expiryDate                                 |-> [i \in 1 .. 4 |-> 0],
      versionNumber                              |-> [i \in 1 .. 1 |-> 0],
      settlementType                             |-> [i \in 1 .. 1 |-> 0],
      optionType                                 |-> [i \in 1 .. 1 |-> 0],
      exerciseType                               |-> [i \in 1 .. 1 |-> 0],
      productName                                |-> [i \in 1 .. 50 |-> 0],
      referencePrice                             |-> [i \in 1 .. 8 |-> 0],
      status                                     |-> [i \in 1 .. 1 |-> 0],
      initialPhaseId                             |-> [i \in 1 .. 4 |-> 0],
      thresholdMax                               |-> [i \in 1 .. 8 |-> 0],
      thresholdMin                               |-> [i \in 1 .. 8 |-> 0],
      isLeverage                                 |-> [i \in 1 .. 1 |-> 0],
      accruedInterestValue                       |-> [i \in 1 .. 8 |-> 0],
      kid                                        |-> [i \in 1 .. 128 |-> 0],
      kidIssueDate                               |-> [i \in 1 .. 4 |-> 0],
      valueAtRisk                                |-> [i \in 1 .. 1 |-> 0],
      externalUnderlyingId                       |-> [i \in 1 .. 4 |-> 0] ]

(* Instrument at zero, then each field in turn at the values it is checked at *)
CheckedInstrument ==
    { ZeroInstrument }
        \cup { [ZeroInstrument EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.productType = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.productSubtype = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.firstTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.lastTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.currency = one] : one \in Sample(2) }
        \cup { [ZeroInstrument EXCEPT !.icebergMinValue = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.lotSize = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.priceExpressionType = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.calendarId = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.marketStructureId = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.tickTableId = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.referenceInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.collarGroupId = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.tradingScheduleId = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.description = one] : one \in Sample(64) }
        \cup { [ZeroInstrument EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.nominalValuePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.nominalValueType = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.multiplierMultiplier = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.strikePriceCurrency = one] : one \in Sample(2) }
        \cup { [ZeroInstrument EXCEPT !.productIdentificationProductIdentification = one] : one \in Sample(30) }
        \cup { [ZeroInstrument EXCEPT !.productIdentificationType = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.settlementCalendarId = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.bondCouponType = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.preTradeCheckMinPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.preTradeCheckMaxPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.preTradeCheckMinQuantity = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.preTradeCheckMaxQuantity = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.preTradeCheckMaxValue = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.preTradeCheckMinValue = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.liquidity = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.marketModelType = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.issuer = one] : one \in Sample(150) }
        \cup { [ZeroInstrument EXCEPT !.issuerRegCountry = one] : one \in Sample(2) }
        \cup { [ZeroInstrument EXCEPT !.underlyingInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.productCode = one] : one \in Sample(20) }
        \cup { [ZeroInstrument EXCEPT !.cfi = one] : one \in Sample(6) }
        \cup { [ZeroInstrument EXCEPT !.fisn = one] : one \in Sample(35) }
        \cup { [ZeroInstrument EXCEPT !.issueSize = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.nominalCurrency = one] : one \in Sample(2) }
        \cup { [ZeroInstrument EXCEPT !.usIndicator = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.versionNumber = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.exerciseType = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.productName = one] : one \in Sample(50) }
        \cup { [ZeroInstrument EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.initialPhaseId = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.thresholdMax = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.thresholdMin = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.isLeverage = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.accruedInterestValue = one] : one \in Sample(8) }
        \cup { [ZeroInstrument EXCEPT !.kid = one] : one \in Sample(128) }
        \cup { [ZeroInstrument EXCEPT !.kidIssueDate = one] : one \in Sample(4) }
        \cup { [ZeroInstrument EXCEPT !.valueAtRisk = one] : one \in Sample(1) }
        \cup { [ZeroInstrument EXCEPT !.externalUnderlyingId = one] : one \in Sample(4) }

(***************************************************************************)
(* Accrued Interest Table Entry: 16 bytes                                  *)
(***************************************************************************)

AccruedInterestTableEntry ==
    [ productId                      : Sample(4),
      accruedInterestTableEntryDate  : Sample(4),
      accruedInterestTableEntryValue : Sample(8) ]

EncodeAccruedInterestTableEntry(message) ==
    message.productId
        \o message.accruedInterestTableEntryDate
        \o message.accruedInterestTableEntryValue

DecodeAccruedInterestTableEntry(bytes) ==
    LET productId == ReadBytes(bytes, 4) IN IF ~productId.ok THEN Fail ELSE
    LET accruedInterestTableEntryDate == ReadBytes(productId.rest, 4) IN IF ~accruedInterestTableEntryDate.ok THEN Fail ELSE
    LET accruedInterestTableEntryValue == ReadBytes(accruedInterestTableEntryDate.rest, 8) IN IF ~accruedInterestTableEntryValue.ok THEN Fail ELSE
    Ok([ productId                      |-> productId.value,
         accruedInterestTableEntryDate  |-> accruedInterestTableEntryDate.value,
         accruedInterestTableEntryValue |-> accruedInterestTableEntryValue.value ], accruedInterestTableEntryValue.rest)

ZeroAccruedInterestTableEntry ==
    [ productId                      |-> [i \in 1 .. 4 |-> 0],
      accruedInterestTableEntryDate  |-> [i \in 1 .. 4 |-> 0],
      accruedInterestTableEntryValue |-> [i \in 1 .. 8 |-> 0] ]

(* Accrued Interest Table Entry at zero, then each field in turn at the values it is checked at *)
CheckedAccruedInterestTableEntry ==
    { ZeroAccruedInterestTableEntry }
        \cup { [ZeroAccruedInterestTableEntry EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroAccruedInterestTableEntry EXCEPT !.accruedInterestTableEntryDate = one] : one \in Sample(4) }
        \cup { [ZeroAccruedInterestTableEntry EXCEPT !.accruedInterestTableEntryValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Indexation Table Entry: 16 bytes                                        *)
(***************************************************************************)

IndexationTableEntry ==
    [ productId                 : Sample(4),
      indexationTableEntryDate  : Sample(4),
      indexationTableEntryValue : Sample(8) ]

EncodeIndexationTableEntry(message) ==
    message.productId
        \o message.indexationTableEntryDate
        \o message.indexationTableEntryValue

DecodeIndexationTableEntry(bytes) ==
    LET productId == ReadBytes(bytes, 4) IN IF ~productId.ok THEN Fail ELSE
    LET indexationTableEntryDate == ReadBytes(productId.rest, 4) IN IF ~indexationTableEntryDate.ok THEN Fail ELSE
    LET indexationTableEntryValue == ReadBytes(indexationTableEntryDate.rest, 8) IN IF ~indexationTableEntryValue.ok THEN Fail ELSE
    Ok([ productId                 |-> productId.value,
         indexationTableEntryDate  |-> indexationTableEntryDate.value,
         indexationTableEntryValue |-> indexationTableEntryValue.value ], indexationTableEntryValue.rest)

ZeroIndexationTableEntry ==
    [ productId                 |-> [i \in 1 .. 4 |-> 0],
      indexationTableEntryDate  |-> [i \in 1 .. 4 |-> 0],
      indexationTableEntryValue |-> [i \in 1 .. 8 |-> 0] ]

(* Indexation Table Entry at zero, then each field in turn at the values it is checked at *)
CheckedIndexationTableEntry ==
    { ZeroIndexationTableEntry }
        \cup { [ZeroIndexationTableEntry EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroIndexationTableEntry EXCEPT !.indexationTableEntryDate = one] : one \in Sample(4) }
        \cup { [ZeroIndexationTableEntry EXCEPT !.indexationTableEntryValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Product Identification Public Product Identification: 31 bytes          *)
(***************************************************************************)

ProductIdentificationPublicProductIdentification ==
    [ productIdentificationProductIdentification : Sample(30),
      productIdentificationType                  : Sample(1) ]

EncodeProductIdentificationPublicProductIdentification(message) ==
    message.productIdentificationProductIdentification
        \o message.productIdentificationType

DecodeProductIdentificationPublicProductIdentification(bytes) ==
    LET productIdentificationProductIdentification == ReadBytes(bytes, 30) IN IF ~productIdentificationProductIdentification.ok THEN Fail ELSE
    LET productIdentificationType == ReadBytes(productIdentificationProductIdentification.rest, 1) IN IF ~productIdentificationType.ok THEN Fail ELSE
    Ok([ productIdentificationProductIdentification |-> productIdentificationProductIdentification.value,
         productIdentificationType                  |-> productIdentificationType.value ], productIdentificationType.rest)

ZeroProductIdentificationPublicProductIdentification ==
    [ productIdentificationProductIdentification |-> [i \in 1 .. 30 |-> 0],
      productIdentificationType                  |-> [i \in 1 .. 1 |-> 0] ]

(* Product Identification Public Product Identification at zero, then each field in turn at the values it is checked at *)
CheckedProductIdentificationPublicProductIdentification ==
    { ZeroProductIdentificationPublicProductIdentification }
        \cup { [ZeroProductIdentificationPublicProductIdentification EXCEPT !.productIdentificationProductIdentification = one] : one \in Sample(30) }
        \cup { [ZeroProductIdentificationPublicProductIdentification EXCEPT !.productIdentificationType = one] : one \in Sample(1) }

(***************************************************************************)
(* Index Underlying: 32 bytes                                              *)
(***************************************************************************)

IndexUnderlying ==
    [ productIdentificationPublicProductIdentification : ProductIdentificationPublicProductIdentification,
      indexUnderlyingType                              : Sample(1) ]

EncodeIndexUnderlying(message) ==
    EncodeProductIdentificationPublicProductIdentification(message.productIdentificationPublicProductIdentification)
        \o message.indexUnderlyingType

DecodeIndexUnderlying(bytes) ==
    LET productIdentificationPublicProductIdentification == DecodeProductIdentificationPublicProductIdentification(bytes) IN IF ~productIdentificationPublicProductIdentification.ok THEN Fail ELSE
    LET indexUnderlyingType == ReadBytes(productIdentificationPublicProductIdentification.rest, 1) IN IF ~indexUnderlyingType.ok THEN Fail ELSE
    Ok([ productIdentificationPublicProductIdentification |-> productIdentificationPublicProductIdentification.value,
         indexUnderlyingType                              |-> indexUnderlyingType.value ], indexUnderlyingType.rest)

ZeroIndexUnderlying ==
    [ productIdentificationPublicProductIdentification |-> ZeroProductIdentificationPublicProductIdentification,
      indexUnderlyingType                              |-> [i \in 1 .. 1 |-> 0] ]

(* Index Underlying at zero, then each field in turn at the values it is checked at *)
CheckedIndexUnderlying ==
    { ZeroIndexUnderlying }
        \cup { [ZeroIndexUnderlying EXCEPT !.productIdentificationPublicProductIdentification = one] : one \in CheckedProductIdentificationPublicProductIdentification }
        \cup { [ZeroIndexUnderlying EXCEPT !.indexUnderlyingType = one] : one \in Sample(1) }

(***************************************************************************)
(* Items: 32 bytes                                                         *)
(***************************************************************************)

Items ==
    [ indexUnderlying : IndexUnderlying ]

EncodeItems(message) ==
    EncodeIndexUnderlying(message.indexUnderlying)

DecodeItems(bytes) ==
    LET indexUnderlying == DecodeIndexUnderlying(bytes) IN IF ~indexUnderlying.ok THEN Fail ELSE
    Ok([ indexUnderlying |-> indexUnderlying.value ], indexUnderlying.rest)

ZeroItems ==
    [ indexUnderlying |-> ZeroIndexUnderlying ]

(* Items at zero, then each field in turn at the values it is checked at *)
CheckedItems ==
    { ZeroItems }
        \cup { [ZeroItems EXCEPT !.indexUnderlying = one] : one \in CheckedIndexUnderlying }

(* A run of Items, written one after another *)
RECURSIVE EncodeItemsList(_)
EncodeItemsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeItems(Head(messages)) \o EncodeItemsList(Tail(messages))

(* As many Items as the field that counts them says *)
RECURSIVE ReadItemsList(_, _)
ReadItemsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeItems(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadItemsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Items of each kind, for the lists that carry them *)
OneItems == { ZeroItems }

(* The 3 slots a run of Items is written as, whatever the field beside it says are in use *)
SlotsItems == { [i \in 1 .. 3 |-> one] : one \in OneItems }

(***************************************************************************)
(* Index Underlyings                                                       *)
(***************************************************************************)

IndexUnderlyings ==
    [ count : Sample(1),
      items : SlotsItems ]

EncodeIndexUnderlyings(message) ==
    message.count
        \o EncodeItemsList(message.items)

DecodeIndexUnderlyings(bytes) ==
    LET count == ReadBytes(bytes, 1) IN IF ~count.ok THEN Fail ELSE
    LET items == ReadItemsList(count.rest, 3) IN IF ~items.ok THEN Fail ELSE
    Ok([ count |-> count.value,
         items |-> items.value ], items.rest)

ZeroIndexUnderlyings ==
    [ count |-> [i \in 1 .. 1 |-> 0],
      items |-> [i \in 1 .. 3 |-> ZeroItems] ]

(* Index Underlyings at zero, then each field in turn at the values it is checked at *)
CheckedIndexUnderlyings ==
    { ZeroIndexUnderlyings }
        \cup { [ZeroIndexUnderlyings EXCEPT !.count = one] : one \in Sample(1) }
        \cup { [ZeroIndexUnderlyings EXCEPT !.items = one] : one \in SlotsItems }

(***************************************************************************)
(* Index Params                                                            *)
(***************************************************************************)

IndexParams ==
    [ instrumentId                          : Sample(4),
      indexBaseValue                        : Sample(8),
      indexBaseCapitalisation               : Sample(8),
      indexBaseDate                         : Sample(4),
      correctionCoefficient                 : Sample(8),
      numOfComponents                       : Sample(2),
      indexPublicationSchedule              : Sample(1),
      indexType                             : Sample(1),
      presenceFlagsIndexParamsPresenceFlags : Sample(1),
      daysSinceLastPublication              : Sample(1),
      numberOfDividends                     : Sample(2),
      indexUnderlyings                      : IndexUnderlyings,
      publicationOrder                      : Sample(2),
      currency                              : Sample(2),
      dateValidity                          : Sample(4) ]

EncodeIndexParams(message) ==
    message.instrumentId
        \o message.indexBaseValue
        \o message.indexBaseCapitalisation
        \o message.indexBaseDate
        \o message.correctionCoefficient
        \o message.numOfComponents
        \o message.indexPublicationSchedule
        \o message.indexType
        \o message.presenceFlagsIndexParamsPresenceFlags
        \o message.daysSinceLastPublication
        \o message.numberOfDividends
        \o EncodeIndexUnderlyings(message.indexUnderlyings)
        \o message.publicationOrder
        \o message.currency
        \o message.dateValidity

DecodeIndexParams(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET indexBaseValue == ReadBytes(instrumentId.rest, 8) IN IF ~indexBaseValue.ok THEN Fail ELSE
    LET indexBaseCapitalisation == ReadBytes(indexBaseValue.rest, 8) IN IF ~indexBaseCapitalisation.ok THEN Fail ELSE
    LET indexBaseDate == ReadBytes(indexBaseCapitalisation.rest, 4) IN IF ~indexBaseDate.ok THEN Fail ELSE
    LET correctionCoefficient == ReadBytes(indexBaseDate.rest, 8) IN IF ~correctionCoefficient.ok THEN Fail ELSE
    LET numOfComponents == ReadBytes(correctionCoefficient.rest, 2) IN IF ~numOfComponents.ok THEN Fail ELSE
    LET indexPublicationSchedule == ReadBytes(numOfComponents.rest, 1) IN IF ~indexPublicationSchedule.ok THEN Fail ELSE
    LET indexType == ReadBytes(indexPublicationSchedule.rest, 1) IN IF ~indexType.ok THEN Fail ELSE
    LET presenceFlagsIndexParamsPresenceFlags == ReadBytes(indexType.rest, 1) IN IF ~presenceFlagsIndexParamsPresenceFlags.ok THEN Fail ELSE
    LET daysSinceLastPublication == ReadBytes(presenceFlagsIndexParamsPresenceFlags.rest, 1) IN IF ~daysSinceLastPublication.ok THEN Fail ELSE
    LET numberOfDividends == ReadBytes(daysSinceLastPublication.rest, 2) IN IF ~numberOfDividends.ok THEN Fail ELSE
    LET indexUnderlyings == DecodeIndexUnderlyings(numberOfDividends.rest) IN IF ~indexUnderlyings.ok THEN Fail ELSE
    LET publicationOrder == ReadBytes(indexUnderlyings.rest, 2) IN IF ~publicationOrder.ok THEN Fail ELSE
    LET currency == ReadBytes(publicationOrder.rest, 2) IN IF ~currency.ok THEN Fail ELSE
    LET dateValidity == ReadBytes(currency.rest, 4) IN IF ~dateValidity.ok THEN Fail ELSE
    Ok([ instrumentId                          |-> instrumentId.value,
         indexBaseValue                        |-> indexBaseValue.value,
         indexBaseCapitalisation               |-> indexBaseCapitalisation.value,
         indexBaseDate                         |-> indexBaseDate.value,
         correctionCoefficient                 |-> correctionCoefficient.value,
         numOfComponents                       |-> numOfComponents.value,
         indexPublicationSchedule              |-> indexPublicationSchedule.value,
         indexType                             |-> indexType.value,
         presenceFlagsIndexParamsPresenceFlags |-> presenceFlagsIndexParamsPresenceFlags.value,
         daysSinceLastPublication              |-> daysSinceLastPublication.value,
         numberOfDividends                     |-> numberOfDividends.value,
         indexUnderlyings                      |-> indexUnderlyings.value,
         publicationOrder                      |-> publicationOrder.value,
         currency                              |-> currency.value,
         dateValidity                          |-> dateValidity.value ], dateValidity.rest)

ZeroIndexParams ==
    [ instrumentId                          |-> [i \in 1 .. 4 |-> 0],
      indexBaseValue                        |-> [i \in 1 .. 8 |-> 0],
      indexBaseCapitalisation               |-> [i \in 1 .. 8 |-> 0],
      indexBaseDate                         |-> [i \in 1 .. 4 |-> 0],
      correctionCoefficient                 |-> [i \in 1 .. 8 |-> 0],
      numOfComponents                       |-> [i \in 1 .. 2 |-> 0],
      indexPublicationSchedule              |-> [i \in 1 .. 1 |-> 0],
      indexType                             |-> [i \in 1 .. 1 |-> 0],
      presenceFlagsIndexParamsPresenceFlags |-> [i \in 1 .. 1 |-> 0],
      daysSinceLastPublication              |-> [i \in 1 .. 1 |-> 0],
      numberOfDividends                     |-> [i \in 1 .. 2 |-> 0],
      indexUnderlyings                      |-> ZeroIndexUnderlyings,
      publicationOrder                      |-> [i \in 1 .. 2 |-> 0],
      currency                              |-> [i \in 1 .. 2 |-> 0],
      dateValidity                          |-> [i \in 1 .. 4 |-> 0] ]

(* Index Params at zero, then each field in turn at the values it is checked at *)
CheckedIndexParams ==
    { ZeroIndexParams }
        \cup { [ZeroIndexParams EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroIndexParams EXCEPT !.indexBaseValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexParams EXCEPT !.indexBaseCapitalisation = one] : one \in Sample(8) }
        \cup { [ZeroIndexParams EXCEPT !.indexBaseDate = one] : one \in Sample(4) }
        \cup { [ZeroIndexParams EXCEPT !.correctionCoefficient = one] : one \in Sample(8) }
        \cup { [ZeroIndexParams EXCEPT !.numOfComponents = one] : one \in Sample(2) }
        \cup { [ZeroIndexParams EXCEPT !.indexPublicationSchedule = one] : one \in Sample(1) }
        \cup { [ZeroIndexParams EXCEPT !.indexType = one] : one \in Sample(1) }
        \cup { [ZeroIndexParams EXCEPT !.presenceFlagsIndexParamsPresenceFlags = one] : one \in Sample(1) }
        \cup { [ZeroIndexParams EXCEPT !.daysSinceLastPublication = one] : one \in Sample(1) }
        \cup { [ZeroIndexParams EXCEPT !.numberOfDividends = one] : one \in Sample(2) }
        \cup { [ZeroIndexParams EXCEPT !.indexUnderlyings = one] : one \in CheckedIndexUnderlyings }
        \cup { [ZeroIndexParams EXCEPT !.publicationOrder = one] : one \in Sample(2) }
        \cup { [ZeroIndexParams EXCEPT !.currency = one] : one \in Sample(2) }
        \cup { [ZeroIndexParams EXCEPT !.dateValidity = one] : one \in Sample(4) }

(***************************************************************************)
(* Public Product Identification: 31 bytes                                 *)
(***************************************************************************)

PublicProductIdentification ==
    [ productIdentificationProductIdentification : Sample(30),
      productIdentificationType                  : Sample(1) ]

EncodePublicProductIdentification(message) ==
    message.productIdentificationProductIdentification
        \o message.productIdentificationType

DecodePublicProductIdentification(bytes) ==
    LET productIdentificationProductIdentification == ReadBytes(bytes, 30) IN IF ~productIdentificationProductIdentification.ok THEN Fail ELSE
    LET productIdentificationType == ReadBytes(productIdentificationProductIdentification.rest, 1) IN IF ~productIdentificationType.ok THEN Fail ELSE
    Ok([ productIdentificationProductIdentification |-> productIdentificationProductIdentification.value,
         productIdentificationType                  |-> productIdentificationType.value ], productIdentificationType.rest)

ZeroPublicProductIdentification ==
    [ productIdentificationProductIdentification |-> [i \in 1 .. 30 |-> 0],
      productIdentificationType                  |-> [i \in 1 .. 1 |-> 0] ]

(* Public Product Identification at zero, then each field in turn at the values it is checked at *)
CheckedPublicProductIdentification ==
    { ZeroPublicProductIdentification }
        \cup { [ZeroPublicProductIdentification EXCEPT !.productIdentificationProductIdentification = one] : one \in Sample(30) }
        \cup { [ZeroPublicProductIdentification EXCEPT !.productIdentificationType = one] : one \in Sample(1) }

(***************************************************************************)
(* Index Portfolio Entry: 59 bytes                                         *)
(***************************************************************************)

IndexPortfolioEntry ==
    [ id                                            : Sample(4),
      indexId                                       : Sample(4),
      presenceFlagsIndexPortfolioEntryPresenceFlags : Sample(1),
      instrumentId                                  : Sample(4),
      publicProductIdentification                   : PublicProductIdentification,
      mic                                           : Sample(4),
      currency                                      : Sample(2),
      instrumentPacket                              : Sample(8),
      suspended                                     : Sample(1) ]

EncodeIndexPortfolioEntry(message) ==
    message.id
        \o message.indexId
        \o message.presenceFlagsIndexPortfolioEntryPresenceFlags
        \o message.instrumentId
        \o EncodePublicProductIdentification(message.publicProductIdentification)
        \o message.mic
        \o message.currency
        \o message.instrumentPacket
        \o message.suspended

DecodeIndexPortfolioEntry(bytes) ==
    LET id == ReadBytes(bytes, 4) IN IF ~id.ok THEN Fail ELSE
    LET indexId == ReadBytes(id.rest, 4) IN IF ~indexId.ok THEN Fail ELSE
    LET presenceFlagsIndexPortfolioEntryPresenceFlags == ReadBytes(indexId.rest, 1) IN IF ~presenceFlagsIndexPortfolioEntryPresenceFlags.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(presenceFlagsIndexPortfolioEntryPresenceFlags.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET publicProductIdentification == DecodePublicProductIdentification(instrumentId.rest) IN IF ~publicProductIdentification.ok THEN Fail ELSE
    LET mic == ReadBytes(publicProductIdentification.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET currency == ReadBytes(mic.rest, 2) IN IF ~currency.ok THEN Fail ELSE
    LET instrumentPacket == ReadBytes(currency.rest, 8) IN IF ~instrumentPacket.ok THEN Fail ELSE
    LET suspended == ReadBytes(instrumentPacket.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    Ok([ id                                            |-> id.value,
         indexId                                       |-> indexId.value,
         presenceFlagsIndexPortfolioEntryPresenceFlags |-> presenceFlagsIndexPortfolioEntryPresenceFlags.value,
         instrumentId                                  |-> instrumentId.value,
         publicProductIdentification                   |-> publicProductIdentification.value,
         mic                                           |-> mic.value,
         currency                                      |-> currency.value,
         instrumentPacket                              |-> instrumentPacket.value,
         suspended                                     |-> suspended.value ], suspended.rest)

ZeroIndexPortfolioEntry ==
    [ id                                            |-> [i \in 1 .. 4 |-> 0],
      indexId                                       |-> [i \in 1 .. 4 |-> 0],
      presenceFlagsIndexPortfolioEntryPresenceFlags |-> [i \in 1 .. 1 |-> 0],
      instrumentId                                  |-> [i \in 1 .. 4 |-> 0],
      publicProductIdentification                   |-> ZeroPublicProductIdentification,
      mic                                           |-> [i \in 1 .. 4 |-> 0],
      currency                                      |-> [i \in 1 .. 2 |-> 0],
      instrumentPacket                              |-> [i \in 1 .. 8 |-> 0],
      suspended                                     |-> [i \in 1 .. 1 |-> 0] ]

(* Index Portfolio Entry at zero, then each field in turn at the values it is checked at *)
CheckedIndexPortfolioEntry ==
    { ZeroIndexPortfolioEntry }
        \cup { [ZeroIndexPortfolioEntry EXCEPT !.id = one] : one \in Sample(4) }
        \cup { [ZeroIndexPortfolioEntry EXCEPT !.indexId = one] : one \in Sample(4) }
        \cup { [ZeroIndexPortfolioEntry EXCEPT !.presenceFlagsIndexPortfolioEntryPresenceFlags = one] : one \in Sample(1) }
        \cup { [ZeroIndexPortfolioEntry EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroIndexPortfolioEntry EXCEPT !.publicProductIdentification = one] : one \in CheckedPublicProductIdentification }
        \cup { [ZeroIndexPortfolioEntry EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroIndexPortfolioEntry EXCEPT !.currency = one] : one \in Sample(2) }
        \cup { [ZeroIndexPortfolioEntry EXCEPT !.instrumentPacket = one] : one \in Sample(8) }
        \cup { [ZeroIndexPortfolioEntry EXCEPT !.suspended = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Summary: 21 bytes                                               *)
(***************************************************************************)

AuctionSummary ==
    [ instrumentId : Sample(4),
      price        : Sample(8),
      quantity     : Sample(8),
      auctionType  : Sample(1) ]

EncodeAuctionSummary(message) ==
    message.instrumentId
        \o message.price
        \o message.quantity
        \o message.auctionType

DecodeAuctionSummary(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET price == ReadBytes(instrumentId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET auctionType == ReadBytes(quantity.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    Ok([ instrumentId |-> instrumentId.value,
         price        |-> price.value,
         quantity     |-> quantity.value,
         auctionType  |-> auctionType.value ], auctionType.rest)

ZeroAuctionSummary ==
    [ instrumentId |-> [i \in 1 .. 4 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      quantity     |-> [i \in 1 .. 8 |-> 0],
      auctionType  |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Summary at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummary ==
    { ZeroAuctionSummary }
        \cup { [ZeroAuctionSummary EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummary EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummary EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAuctionSummary EXCEPT !.auctionType = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Update: 68 bytes                                                *)
(***************************************************************************)

AuctionUpdate ==
    [ instrumentId             : Sample(4),
      indicativeMatchingPrice  : Sample(8),
      indicativeMatchingVolume : Sample(8),
      totalSellQuantityAtImp   : Sample(8),
      totalBuyQuantityAtImp    : Sample(8),
      bestSellLevel            : Sample(8),
      bestSellLevelQuantity    : Sample(8),
      bestBuyLevel             : Sample(8),
      bestBuyLevelQuantity     : Sample(8) ]

EncodeAuctionUpdate(message) ==
    message.instrumentId
        \o message.indicativeMatchingPrice
        \o message.indicativeMatchingVolume
        \o message.totalSellQuantityAtImp
        \o message.totalBuyQuantityAtImp
        \o message.bestSellLevel
        \o message.bestSellLevelQuantity
        \o message.bestBuyLevel
        \o message.bestBuyLevelQuantity

DecodeAuctionUpdate(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET indicativeMatchingPrice == ReadBytes(instrumentId.rest, 8) IN IF ~indicativeMatchingPrice.ok THEN Fail ELSE
    LET indicativeMatchingVolume == ReadBytes(indicativeMatchingPrice.rest, 8) IN IF ~indicativeMatchingVolume.ok THEN Fail ELSE
    LET totalSellQuantityAtImp == ReadBytes(indicativeMatchingVolume.rest, 8) IN IF ~totalSellQuantityAtImp.ok THEN Fail ELSE
    LET totalBuyQuantityAtImp == ReadBytes(totalSellQuantityAtImp.rest, 8) IN IF ~totalBuyQuantityAtImp.ok THEN Fail ELSE
    LET bestSellLevel == ReadBytes(totalBuyQuantityAtImp.rest, 8) IN IF ~bestSellLevel.ok THEN Fail ELSE
    LET bestSellLevelQuantity == ReadBytes(bestSellLevel.rest, 8) IN IF ~bestSellLevelQuantity.ok THEN Fail ELSE
    LET bestBuyLevel == ReadBytes(bestSellLevelQuantity.rest, 8) IN IF ~bestBuyLevel.ok THEN Fail ELSE
    LET bestBuyLevelQuantity == ReadBytes(bestBuyLevel.rest, 8) IN IF ~bestBuyLevelQuantity.ok THEN Fail ELSE
    Ok([ instrumentId             |-> instrumentId.value,
         indicativeMatchingPrice  |-> indicativeMatchingPrice.value,
         indicativeMatchingVolume |-> indicativeMatchingVolume.value,
         totalSellQuantityAtImp   |-> totalSellQuantityAtImp.value,
         totalBuyQuantityAtImp    |-> totalBuyQuantityAtImp.value,
         bestSellLevel            |-> bestSellLevel.value,
         bestSellLevelQuantity    |-> bestSellLevelQuantity.value,
         bestBuyLevel             |-> bestBuyLevel.value,
         bestBuyLevelQuantity     |-> bestBuyLevelQuantity.value ], bestBuyLevelQuantity.rest)

ZeroAuctionUpdate ==
    [ instrumentId             |-> [i \in 1 .. 4 |-> 0],
      indicativeMatchingPrice  |-> [i \in 1 .. 8 |-> 0],
      indicativeMatchingVolume |-> [i \in 1 .. 8 |-> 0],
      totalSellQuantityAtImp   |-> [i \in 1 .. 8 |-> 0],
      totalBuyQuantityAtImp    |-> [i \in 1 .. 8 |-> 0],
      bestSellLevel            |-> [i \in 1 .. 8 |-> 0],
      bestSellLevelQuantity    |-> [i \in 1 .. 8 |-> 0],
      bestBuyLevel             |-> [i \in 1 .. 8 |-> 0],
      bestBuyLevelQuantity     |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Update at zero, then each field in turn at the values it is checked at *)
CheckedAuctionUpdate ==
    { ZeroAuctionUpdate }
        \cup { [ZeroAuctionUpdate EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionUpdate EXCEPT !.indicativeMatchingPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdate EXCEPT !.indicativeMatchingVolume = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdate EXCEPT !.totalSellQuantityAtImp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdate EXCEPT !.totalBuyQuantityAtImp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdate EXCEPT !.bestSellLevel = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdate EXCEPT !.bestSellLevelQuantity = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdate EXCEPT !.bestBuyLevel = one] : one \in Sample(8) }
        \cup { [ZeroAuctionUpdate EXCEPT !.bestBuyLevelQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Price Level: 31 bytes                                                   *)
(***************************************************************************)

PriceLevel ==
    [ isEncrypted      : Sample(1),
      encryptionOffset : Sample(8),
      encryptionKeyId  : Sample(4),
      price            : Sample(8),
      quantity         : Sample(8),
      orderCount       : Sample(2) ]

EncodePriceLevel(message) ==
    message.isEncrypted
        \o message.encryptionOffset
        \o message.encryptionKeyId
        \o message.price
        \o message.quantity
        \o message.orderCount

DecodePriceLevel(bytes) ==
    LET isEncrypted == ReadBytes(bytes, 1) IN IF ~isEncrypted.ok THEN Fail ELSE
    LET encryptionOffset == ReadBytes(isEncrypted.rest, 8) IN IF ~encryptionOffset.ok THEN Fail ELSE
    LET encryptionKeyId == ReadBytes(encryptionOffset.rest, 4) IN IF ~encryptionKeyId.ok THEN Fail ELSE
    LET price == ReadBytes(encryptionKeyId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET orderCount == ReadBytes(quantity.rest, 2) IN IF ~orderCount.ok THEN Fail ELSE
    Ok([ isEncrypted      |-> isEncrypted.value,
         encryptionOffset |-> encryptionOffset.value,
         encryptionKeyId  |-> encryptionKeyId.value,
         price            |-> price.value,
         quantity         |-> quantity.value,
         orderCount       |-> orderCount.value ], orderCount.rest)

ZeroPriceLevel ==
    [ isEncrypted      |-> [i \in 1 .. 1 |-> 0],
      encryptionOffset |-> [i \in 1 .. 8 |-> 0],
      encryptionKeyId  |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      quantity         |-> [i \in 1 .. 8 |-> 0],
      orderCount       |-> [i \in 1 .. 2 |-> 0] ]

(* Price Level at zero, then each field in turn at the values it is checked at *)
CheckedPriceLevel ==
    { ZeroPriceLevel }
        \cup { [ZeroPriceLevel EXCEPT !.isEncrypted = one] : one \in Sample(1) }
        \cup { [ZeroPriceLevel EXCEPT !.encryptionOffset = one] : one \in Sample(8) }
        \cup { [ZeroPriceLevel EXCEPT !.encryptionKeyId = one] : one \in Sample(4) }
        \cup { [ZeroPriceLevel EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroPriceLevel EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroPriceLevel EXCEPT !.orderCount = one] : one \in Sample(2) }

(***************************************************************************)
(* Buy: 31 bytes                                                           *)
(***************************************************************************)

Buy ==
    [ priceLevel : PriceLevel ]

EncodeBuy(message) ==
    EncodePriceLevel(message.priceLevel)

DecodeBuy(bytes) ==
    LET priceLevel == DecodePriceLevel(bytes) IN IF ~priceLevel.ok THEN Fail ELSE
    Ok([ priceLevel |-> priceLevel.value ], priceLevel.rest)

ZeroBuy ==
    [ priceLevel |-> ZeroPriceLevel ]

(* Buy at zero, then each field in turn at the values it is checked at *)
CheckedBuy ==
    { ZeroBuy }
        \cup { [ZeroBuy EXCEPT !.priceLevel = one] : one \in CheckedPriceLevel }

(* A run of Buy, written one after another *)
RECURSIVE EncodeBuyList(_)
EncodeBuyList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBuy(Head(messages)) \o EncodeBuyList(Tail(messages))

(* As many Buy as the field that counts them says *)
RECURSIVE ReadBuyList(_, _)
ReadBuyList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBuy(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBuyList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Buy of each kind, for the lists that carry them *)
OneBuy == { ZeroBuy }

(* The 5 slots a run of Buy is written as, whatever the field beside it says are in use *)
SlotsBuy == { [i \in 1 .. 5 |-> one] : one \in OneBuy }

(***************************************************************************)
(* Price Level: 31 bytes                                                   *)
(***************************************************************************)

PriceLevel2 ==
    [ isEncrypted      : Sample(1),
      encryptionOffset : Sample(8),
      encryptionKeyId  : Sample(4),
      price            : Sample(8),
      quantity         : Sample(8),
      orderCount       : Sample(2) ]

EncodePriceLevel2(message) ==
    message.isEncrypted
        \o message.encryptionOffset
        \o message.encryptionKeyId
        \o message.price
        \o message.quantity
        \o message.orderCount

DecodePriceLevel2(bytes) ==
    LET isEncrypted == ReadBytes(bytes, 1) IN IF ~isEncrypted.ok THEN Fail ELSE
    LET encryptionOffset == ReadBytes(isEncrypted.rest, 8) IN IF ~encryptionOffset.ok THEN Fail ELSE
    LET encryptionKeyId == ReadBytes(encryptionOffset.rest, 4) IN IF ~encryptionKeyId.ok THEN Fail ELSE
    LET price == ReadBytes(encryptionKeyId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET orderCount == ReadBytes(quantity.rest, 2) IN IF ~orderCount.ok THEN Fail ELSE
    Ok([ isEncrypted      |-> isEncrypted.value,
         encryptionOffset |-> encryptionOffset.value,
         encryptionKeyId  |-> encryptionKeyId.value,
         price            |-> price.value,
         quantity         |-> quantity.value,
         orderCount       |-> orderCount.value ], orderCount.rest)

ZeroPriceLevel2 ==
    [ isEncrypted      |-> [i \in 1 .. 1 |-> 0],
      encryptionOffset |-> [i \in 1 .. 8 |-> 0],
      encryptionKeyId  |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0],
      quantity         |-> [i \in 1 .. 8 |-> 0],
      orderCount       |-> [i \in 1 .. 2 |-> 0] ]

(* Price Level at zero, then each field in turn at the values it is checked at *)
CheckedPriceLevel2 ==
    { ZeroPriceLevel2 }
        \cup { [ZeroPriceLevel2 EXCEPT !.isEncrypted = one] : one \in Sample(1) }
        \cup { [ZeroPriceLevel2 EXCEPT !.encryptionOffset = one] : one \in Sample(8) }
        \cup { [ZeroPriceLevel2 EXCEPT !.encryptionKeyId = one] : one \in Sample(4) }
        \cup { [ZeroPriceLevel2 EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroPriceLevel2 EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroPriceLevel2 EXCEPT !.orderCount = one] : one \in Sample(2) }

(***************************************************************************)
(* Sell: 31 bytes                                                          *)
(***************************************************************************)

Sell ==
    [ priceLevel : PriceLevel2 ]

EncodeSell(message) ==
    EncodePriceLevel2(message.priceLevel)

DecodeSell(bytes) ==
    LET priceLevel == DecodePriceLevel2(bytes) IN IF ~priceLevel.ok THEN Fail ELSE
    Ok([ priceLevel |-> priceLevel.value ], priceLevel.rest)

ZeroSell ==
    [ priceLevel |-> ZeroPriceLevel2 ]

(* Sell at zero, then each field in turn at the values it is checked at *)
CheckedSell ==
    { ZeroSell }
        \cup { [ZeroSell EXCEPT !.priceLevel = one] : one \in CheckedPriceLevel2 }

(* A run of Sell, written one after another *)
RECURSIVE EncodeSellList(_)
EncodeSellList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSell(Head(messages)) \o EncodeSellList(Tail(messages))

(* As many Sell as the field that counts them says *)
RECURSIVE ReadSellList(_, _)
ReadSellList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSell(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSellList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sell of each kind, for the lists that carry them *)
OneSell == { ZeroSell }

(* The 5 slots a run of Sell is written as, whatever the field beside it says are in use *)
SlotsSell == { [i \in 1 .. 5 |-> one] : one \in OneSell }

(***************************************************************************)
(* Price Level Snapshot                                                    *)
(***************************************************************************)

PriceLevelSnapshot ==
    [ instrumentId     : Sample(4),
      maxDepth         : Sample(1),
      mmBuyQuoteLevel  : Sample(1),
      mmSellQuoteLevel : Sample(1),
      buy              : SlotsBuy,
      sell             : SlotsSell ]

EncodePriceLevelSnapshot(message) ==
    message.instrumentId
        \o message.maxDepth
        \o message.mmBuyQuoteLevel
        \o message.mmSellQuoteLevel
        \o EncodeBuyList(message.buy)
        \o EncodeSellList(message.sell)

DecodePriceLevelSnapshot(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET maxDepth == ReadBytes(instrumentId.rest, 1) IN IF ~maxDepth.ok THEN Fail ELSE
    LET mmBuyQuoteLevel == ReadBytes(maxDepth.rest, 1) IN IF ~mmBuyQuoteLevel.ok THEN Fail ELSE
    LET mmSellQuoteLevel == ReadBytes(mmBuyQuoteLevel.rest, 1) IN IF ~mmSellQuoteLevel.ok THEN Fail ELSE
    LET buy == ReadBuyList(mmSellQuoteLevel.rest, 5) IN IF ~buy.ok THEN Fail ELSE
    LET sell == ReadSellList(buy.rest, 5) IN IF ~sell.ok THEN Fail ELSE
    Ok([ instrumentId     |-> instrumentId.value,
         maxDepth         |-> maxDepth.value,
         mmBuyQuoteLevel  |-> mmBuyQuoteLevel.value,
         mmSellQuoteLevel |-> mmSellQuoteLevel.value,
         buy              |-> buy.value,
         sell             |-> sell.value ], sell.rest)

ZeroPriceLevelSnapshot ==
    [ instrumentId     |-> [i \in 1 .. 4 |-> 0],
      maxDepth         |-> [i \in 1 .. 1 |-> 0],
      mmBuyQuoteLevel  |-> [i \in 1 .. 1 |-> 0],
      mmSellQuoteLevel |-> [i \in 1 .. 1 |-> 0],
      buy              |-> [i \in 1 .. 5 |-> ZeroBuy],
      sell             |-> [i \in 1 .. 5 |-> ZeroSell] ]

(* Price Level Snapshot at zero, then each field in turn at the values it is checked at *)
CheckedPriceLevelSnapshot ==
    { ZeroPriceLevelSnapshot }
        \cup { [ZeroPriceLevelSnapshot EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroPriceLevelSnapshot EXCEPT !.maxDepth = one] : one \in Sample(1) }
        \cup { [ZeroPriceLevelSnapshot EXCEPT !.mmBuyQuoteLevel = one] : one \in Sample(1) }
        \cup { [ZeroPriceLevelSnapshot EXCEPT !.mmSellQuoteLevel = one] : one \in Sample(1) }
        \cup { [ZeroPriceLevelSnapshot EXCEPT !.buy = one] : one \in SlotsBuy }
        \cup { [ZeroPriceLevelSnapshot EXCEPT !.sell = one] : one \in SlotsSell }

(***************************************************************************)
(* Top Price Level Update: 23 bytes                                        *)
(***************************************************************************)

TopPriceLevelUpdate ==
    [ instrumentId : Sample(4),
      price        : Sample(8),
      quantity     : Sample(8),
      side         : Sample(1),
      orderCount   : Sample(2) ]

EncodeTopPriceLevelUpdate(message) ==
    message.instrumentId
        \o message.price
        \o message.quantity
        \o message.side
        \o message.orderCount

DecodeTopPriceLevelUpdate(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET price == ReadBytes(instrumentId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET side == ReadBytes(quantity.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderCount == ReadBytes(side.rest, 2) IN IF ~orderCount.ok THEN Fail ELSE
    Ok([ instrumentId |-> instrumentId.value,
         price        |-> price.value,
         quantity     |-> quantity.value,
         side         |-> side.value,
         orderCount   |-> orderCount.value ], orderCount.rest)

ZeroTopPriceLevelUpdate ==
    [ instrumentId |-> [i \in 1 .. 4 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      quantity     |-> [i \in 1 .. 8 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      orderCount   |-> [i \in 1 .. 2 |-> 0] ]

(* Top Price Level Update at zero, then each field in turn at the values it is checked at *)
CheckedTopPriceLevelUpdate ==
    { ZeroTopPriceLevelUpdate }
        \cup { [ZeroTopPriceLevelUpdate EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTopPriceLevelUpdate EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTopPriceLevelUpdate EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroTopPriceLevelUpdate EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTopPriceLevelUpdate EXCEPT !.orderCount = one] : one \in Sample(2) }

(***************************************************************************)
(* Public Product Identification: 31 bytes                                 *)
(***************************************************************************)

PublicProductIdentification2 ==
    [ productIdentificationProductIdentification : Sample(30),
      productIdentificationType                  : Sample(1) ]

EncodePublicProductIdentification2(message) ==
    message.productIdentificationProductIdentification
        \o message.productIdentificationType

DecodePublicProductIdentification2(bytes) ==
    LET productIdentificationProductIdentification == ReadBytes(bytes, 30) IN IF ~productIdentificationProductIdentification.ok THEN Fail ELSE
    LET productIdentificationType == ReadBytes(productIdentificationProductIdentification.rest, 1) IN IF ~productIdentificationType.ok THEN Fail ELSE
    Ok([ productIdentificationProductIdentification |-> productIdentificationProductIdentification.value,
         productIdentificationType                  |-> productIdentificationType.value ], productIdentificationType.rest)

ZeroPublicProductIdentification2 ==
    [ productIdentificationProductIdentification |-> [i \in 1 .. 30 |-> 0],
      productIdentificationType                  |-> [i \in 1 .. 1 |-> 0] ]

(* Public Product Identification at zero, then each field in turn at the values it is checked at *)
CheckedPublicProductIdentification2 ==
    { ZeroPublicProductIdentification2 }
        \cup { [ZeroPublicProductIdentification2 EXCEPT !.productIdentificationProductIdentification = one] : one \in Sample(30) }
        \cup { [ZeroPublicProductIdentification2 EXCEPT !.productIdentificationType = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade: 178 bytes                                                        *)
(***************************************************************************)

Trade ==
    [ instrumentId                        : Sample(4),
      settlementValueValue                : Sample(8),
      settlementDate                      : Sample(4),
      tradingTimestamp                    : Sample(8),
      publicProductIdentification         : PublicProductIdentification2,
      price                               : Sample(8),
      priceCurrency                       : Sample(2),
      priceNotation                       : Sample(1),
      quantity                            : Sample(8),
      nominalValueValue                   : Sample(8),
      nominalCurrency                     : Sample(2),
      mic                                 : Sample(4),
      publicationTimestamp                : Sample(8),
      tradeId                             : Sample(4),
      tradeToBeCleared                    : Sample(1),
      pctChange                           : Sample(8),
      vwap                                : Sample(8),
      noTrades                            : Sample(8),
      totalVolume                         : Sample(8),
      totalValue                          : Sample(8),
      openingPrice                        : Sample(8),
      maxPrice                            : Sample(8),
      minPrice                            : Sample(8),
      mmtMarketMechanism                  : Sample(1),
      mmtTradingMode                      : Sample(1),
      mmtTransactionCategory              : Sample(1),
      mmtNegotiationIndicator             : Sample(1),
      mmtAgencyCrossTradeIndicator        : Sample(1),
      mmtModificationIndicator            : Sample(1),
      mmtBenchmarkReferencePriceIndicator : Sample(1),
      mmtSpecialDividendIndicator         : Sample(1),
      mmtOffBookAutomatedIndicator        : Sample(1),
      mmtOrdinaryTradeIndicator           : Sample(1),
      mmtAlgorithmicIndicator             : Sample(1),
      mmtPostTradeDeferralReason          : Sample(1),
      mmtPostTradeDeferralType            : Sample(1) ]

EncodeTrade(message) ==
    message.instrumentId
        \o message.settlementValueValue
        \o message.settlementDate
        \o message.tradingTimestamp
        \o EncodePublicProductIdentification2(message.publicProductIdentification)
        \o message.price
        \o message.priceCurrency
        \o message.priceNotation
        \o message.quantity
        \o message.nominalValueValue
        \o message.nominalCurrency
        \o message.mic
        \o message.publicationTimestamp
        \o message.tradeId
        \o message.tradeToBeCleared
        \o message.pctChange
        \o message.vwap
        \o message.noTrades
        \o message.totalVolume
        \o message.totalValue
        \o message.openingPrice
        \o message.maxPrice
        \o message.minPrice
        \o message.mmtMarketMechanism
        \o message.mmtTradingMode
        \o message.mmtTransactionCategory
        \o message.mmtNegotiationIndicator
        \o message.mmtAgencyCrossTradeIndicator
        \o message.mmtModificationIndicator
        \o message.mmtBenchmarkReferencePriceIndicator
        \o message.mmtSpecialDividendIndicator
        \o message.mmtOffBookAutomatedIndicator
        \o message.mmtOrdinaryTradeIndicator
        \o message.mmtAlgorithmicIndicator
        \o message.mmtPostTradeDeferralReason
        \o message.mmtPostTradeDeferralType

DecodeTrade(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET settlementValueValue == ReadBytes(instrumentId.rest, 8) IN IF ~settlementValueValue.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(settlementValueValue.rest, 4) IN IF ~settlementDate.ok THEN Fail ELSE
    LET tradingTimestamp == ReadBytes(settlementDate.rest, 8) IN IF ~tradingTimestamp.ok THEN Fail ELSE
    LET publicProductIdentification == DecodePublicProductIdentification2(tradingTimestamp.rest) IN IF ~publicProductIdentification.ok THEN Fail ELSE
    LET price == ReadBytes(publicProductIdentification.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET priceCurrency == ReadBytes(price.rest, 2) IN IF ~priceCurrency.ok THEN Fail ELSE
    LET priceNotation == ReadBytes(priceCurrency.rest, 1) IN IF ~priceNotation.ok THEN Fail ELSE
    LET quantity == ReadBytes(priceNotation.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET nominalValueValue == ReadBytes(quantity.rest, 8) IN IF ~nominalValueValue.ok THEN Fail ELSE
    LET nominalCurrency == ReadBytes(nominalValueValue.rest, 2) IN IF ~nominalCurrency.ok THEN Fail ELSE
    LET mic == ReadBytes(nominalCurrency.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET publicationTimestamp == ReadBytes(mic.rest, 8) IN IF ~publicationTimestamp.ok THEN Fail ELSE
    LET tradeId == ReadBytes(publicationTimestamp.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeToBeCleared == ReadBytes(tradeId.rest, 1) IN IF ~tradeToBeCleared.ok THEN Fail ELSE
    LET pctChange == ReadBytes(tradeToBeCleared.rest, 8) IN IF ~pctChange.ok THEN Fail ELSE
    LET vwap == ReadBytes(pctChange.rest, 8) IN IF ~vwap.ok THEN Fail ELSE
    LET noTrades == ReadBytes(vwap.rest, 8) IN IF ~noTrades.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(noTrades.rest, 8) IN IF ~totalVolume.ok THEN Fail ELSE
    LET totalValue == ReadBytes(totalVolume.rest, 8) IN IF ~totalValue.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(totalValue.rest, 8) IN IF ~openingPrice.ok THEN Fail ELSE
    LET maxPrice == ReadBytes(openingPrice.rest, 8) IN IF ~maxPrice.ok THEN Fail ELSE
    LET minPrice == ReadBytes(maxPrice.rest, 8) IN IF ~minPrice.ok THEN Fail ELSE
    LET mmtMarketMechanism == ReadBytes(minPrice.rest, 1) IN IF ~mmtMarketMechanism.ok THEN Fail ELSE
    LET mmtTradingMode == ReadBytes(mmtMarketMechanism.rest, 1) IN IF ~mmtTradingMode.ok THEN Fail ELSE
    LET mmtTransactionCategory == ReadBytes(mmtTradingMode.rest, 1) IN IF ~mmtTransactionCategory.ok THEN Fail ELSE
    LET mmtNegotiationIndicator == ReadBytes(mmtTransactionCategory.rest, 1) IN IF ~mmtNegotiationIndicator.ok THEN Fail ELSE
    LET mmtAgencyCrossTradeIndicator == ReadBytes(mmtNegotiationIndicator.rest, 1) IN IF ~mmtAgencyCrossTradeIndicator.ok THEN Fail ELSE
    LET mmtModificationIndicator == ReadBytes(mmtAgencyCrossTradeIndicator.rest, 1) IN IF ~mmtModificationIndicator.ok THEN Fail ELSE
    LET mmtBenchmarkReferencePriceIndicator == ReadBytes(mmtModificationIndicator.rest, 1) IN IF ~mmtBenchmarkReferencePriceIndicator.ok THEN Fail ELSE
    LET mmtSpecialDividendIndicator == ReadBytes(mmtBenchmarkReferencePriceIndicator.rest, 1) IN IF ~mmtSpecialDividendIndicator.ok THEN Fail ELSE
    LET mmtOffBookAutomatedIndicator == ReadBytes(mmtSpecialDividendIndicator.rest, 1) IN IF ~mmtOffBookAutomatedIndicator.ok THEN Fail ELSE
    LET mmtOrdinaryTradeIndicator == ReadBytes(mmtOffBookAutomatedIndicator.rest, 1) IN IF ~mmtOrdinaryTradeIndicator.ok THEN Fail ELSE
    LET mmtAlgorithmicIndicator == ReadBytes(mmtOrdinaryTradeIndicator.rest, 1) IN IF ~mmtAlgorithmicIndicator.ok THEN Fail ELSE
    LET mmtPostTradeDeferralReason == ReadBytes(mmtAlgorithmicIndicator.rest, 1) IN IF ~mmtPostTradeDeferralReason.ok THEN Fail ELSE
    LET mmtPostTradeDeferralType == ReadBytes(mmtPostTradeDeferralReason.rest, 1) IN IF ~mmtPostTradeDeferralType.ok THEN Fail ELSE
    Ok([ instrumentId                        |-> instrumentId.value,
         settlementValueValue                |-> settlementValueValue.value,
         settlementDate                      |-> settlementDate.value,
         tradingTimestamp                    |-> tradingTimestamp.value,
         publicProductIdentification         |-> publicProductIdentification.value,
         price                               |-> price.value,
         priceCurrency                       |-> priceCurrency.value,
         priceNotation                       |-> priceNotation.value,
         quantity                            |-> quantity.value,
         nominalValueValue                   |-> nominalValueValue.value,
         nominalCurrency                     |-> nominalCurrency.value,
         mic                                 |-> mic.value,
         publicationTimestamp                |-> publicationTimestamp.value,
         tradeId                             |-> tradeId.value,
         tradeToBeCleared                    |-> tradeToBeCleared.value,
         pctChange                           |-> pctChange.value,
         vwap                                |-> vwap.value,
         noTrades                            |-> noTrades.value,
         totalVolume                         |-> totalVolume.value,
         totalValue                          |-> totalValue.value,
         openingPrice                        |-> openingPrice.value,
         maxPrice                            |-> maxPrice.value,
         minPrice                            |-> minPrice.value,
         mmtMarketMechanism                  |-> mmtMarketMechanism.value,
         mmtTradingMode                      |-> mmtTradingMode.value,
         mmtTransactionCategory              |-> mmtTransactionCategory.value,
         mmtNegotiationIndicator             |-> mmtNegotiationIndicator.value,
         mmtAgencyCrossTradeIndicator        |-> mmtAgencyCrossTradeIndicator.value,
         mmtModificationIndicator            |-> mmtModificationIndicator.value,
         mmtBenchmarkReferencePriceIndicator |-> mmtBenchmarkReferencePriceIndicator.value,
         mmtSpecialDividendIndicator         |-> mmtSpecialDividendIndicator.value,
         mmtOffBookAutomatedIndicator        |-> mmtOffBookAutomatedIndicator.value,
         mmtOrdinaryTradeIndicator           |-> mmtOrdinaryTradeIndicator.value,
         mmtAlgorithmicIndicator             |-> mmtAlgorithmicIndicator.value,
         mmtPostTradeDeferralReason          |-> mmtPostTradeDeferralReason.value,
         mmtPostTradeDeferralType            |-> mmtPostTradeDeferralType.value ], mmtPostTradeDeferralType.rest)

ZeroTrade ==
    [ instrumentId                        |-> [i \in 1 .. 4 |-> 0],
      settlementValueValue                |-> [i \in 1 .. 8 |-> 0],
      settlementDate                      |-> [i \in 1 .. 4 |-> 0],
      tradingTimestamp                    |-> [i \in 1 .. 8 |-> 0],
      publicProductIdentification         |-> ZeroPublicProductIdentification2,
      price                               |-> [i \in 1 .. 8 |-> 0],
      priceCurrency                       |-> [i \in 1 .. 2 |-> 0],
      priceNotation                       |-> [i \in 1 .. 1 |-> 0],
      quantity                            |-> [i \in 1 .. 8 |-> 0],
      nominalValueValue                   |-> [i \in 1 .. 8 |-> 0],
      nominalCurrency                     |-> [i \in 1 .. 2 |-> 0],
      mic                                 |-> [i \in 1 .. 4 |-> 0],
      publicationTimestamp                |-> [i \in 1 .. 8 |-> 0],
      tradeId                             |-> [i \in 1 .. 4 |-> 0],
      tradeToBeCleared                    |-> [i \in 1 .. 1 |-> 0],
      pctChange                           |-> [i \in 1 .. 8 |-> 0],
      vwap                                |-> [i \in 1 .. 8 |-> 0],
      noTrades                            |-> [i \in 1 .. 8 |-> 0],
      totalVolume                         |-> [i \in 1 .. 8 |-> 0],
      totalValue                          |-> [i \in 1 .. 8 |-> 0],
      openingPrice                        |-> [i \in 1 .. 8 |-> 0],
      maxPrice                            |-> [i \in 1 .. 8 |-> 0],
      minPrice                            |-> [i \in 1 .. 8 |-> 0],
      mmtMarketMechanism                  |-> [i \in 1 .. 1 |-> 0],
      mmtTradingMode                      |-> [i \in 1 .. 1 |-> 0],
      mmtTransactionCategory              |-> [i \in 1 .. 1 |-> 0],
      mmtNegotiationIndicator             |-> [i \in 1 .. 1 |-> 0],
      mmtAgencyCrossTradeIndicator        |-> [i \in 1 .. 1 |-> 0],
      mmtModificationIndicator            |-> [i \in 1 .. 1 |-> 0],
      mmtBenchmarkReferencePriceIndicator |-> [i \in 1 .. 1 |-> 0],
      mmtSpecialDividendIndicator         |-> [i \in 1 .. 1 |-> 0],
      mmtOffBookAutomatedIndicator        |-> [i \in 1 .. 1 |-> 0],
      mmtOrdinaryTradeIndicator           |-> [i \in 1 .. 1 |-> 0],
      mmtAlgorithmicIndicator             |-> [i \in 1 .. 1 |-> 0],
      mmtPostTradeDeferralReason          |-> [i \in 1 .. 1 |-> 0],
      mmtPostTradeDeferralType            |-> [i \in 1 .. 1 |-> 0] ]

(* Trade at zero, then each field in turn at the values it is checked at *)
CheckedTrade ==
    { ZeroTrade }
        \cup { [ZeroTrade EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTrade EXCEPT !.settlementValueValue = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.settlementDate = one] : one \in Sample(4) }
        \cup { [ZeroTrade EXCEPT !.tradingTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.publicProductIdentification = one] : one \in CheckedPublicProductIdentification2 }
        \cup { [ZeroTrade EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.priceCurrency = one] : one \in Sample(2) }
        \cup { [ZeroTrade EXCEPT !.priceNotation = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.nominalValueValue = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.nominalCurrency = one] : one \in Sample(2) }
        \cup { [ZeroTrade EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroTrade EXCEPT !.publicationTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTrade EXCEPT !.tradeToBeCleared = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.pctChange = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.vwap = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.noTrades = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.totalVolume = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.totalValue = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.openingPrice = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.maxPrice = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.minPrice = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.mmtMarketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.mmtTradingMode = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.mmtTransactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.mmtNegotiationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.mmtAgencyCrossTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.mmtModificationIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.mmtBenchmarkReferencePriceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.mmtSpecialDividendIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.mmtOffBookAutomatedIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.mmtOrdinaryTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.mmtAlgorithmicIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.mmtPostTradeDeferralReason = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.mmtPostTradeDeferralType = one] : one \in Sample(1) }

(***************************************************************************)
(* Public Product Identification: 31 bytes                                 *)
(***************************************************************************)

PublicProductIdentification3 ==
    [ productIdentificationProductIdentification : Sample(30),
      productIdentificationType                  : Sample(1) ]

EncodePublicProductIdentification3(message) ==
    message.productIdentificationProductIdentification
        \o message.productIdentificationType

DecodePublicProductIdentification3(bytes) ==
    LET productIdentificationProductIdentification == ReadBytes(bytes, 30) IN IF ~productIdentificationProductIdentification.ok THEN Fail ELSE
    LET productIdentificationType == ReadBytes(productIdentificationProductIdentification.rest, 1) IN IF ~productIdentificationType.ok THEN Fail ELSE
    Ok([ productIdentificationProductIdentification |-> productIdentificationProductIdentification.value,
         productIdentificationType                  |-> productIdentificationType.value ], productIdentificationType.rest)

ZeroPublicProductIdentification3 ==
    [ productIdentificationProductIdentification |-> [i \in 1 .. 30 |-> 0],
      productIdentificationType                  |-> [i \in 1 .. 1 |-> 0] ]

(* Public Product Identification at zero, then each field in turn at the values it is checked at *)
CheckedPublicProductIdentification3 ==
    { ZeroPublicProductIdentification3 }
        \cup { [ZeroPublicProductIdentification3 EXCEPT !.productIdentificationProductIdentification = one] : one \in Sample(30) }
        \cup { [ZeroPublicProductIdentification3 EXCEPT !.productIdentificationType = one] : one \in Sample(1) }

(***************************************************************************)
(* Position Report: 40 bytes                                               *)
(***************************************************************************)

PositionReport ==
    [ publicProductIdentification : PublicProductIdentification3,
      posType                     : Sample(1),
      openPositions               : Sample(4),
      tradeId                     : Sample(4) ]

EncodePositionReport(message) ==
    EncodePublicProductIdentification3(message.publicProductIdentification)
        \o message.posType
        \o message.openPositions
        \o message.tradeId

DecodePositionReport(bytes) ==
    LET publicProductIdentification == DecodePublicProductIdentification3(bytes) IN IF ~publicProductIdentification.ok THEN Fail ELSE
    LET posType == ReadBytes(publicProductIdentification.rest, 1) IN IF ~posType.ok THEN Fail ELSE
    LET openPositions == ReadBytes(posType.rest, 4) IN IF ~openPositions.ok THEN Fail ELSE
    LET tradeId == ReadBytes(openPositions.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    Ok([ publicProductIdentification |-> publicProductIdentification.value,
         posType                     |-> posType.value,
         openPositions               |-> openPositions.value,
         tradeId                     |-> tradeId.value ], tradeId.rest)

ZeroPositionReport ==
    [ publicProductIdentification |-> ZeroPublicProductIdentification3,
      posType                     |-> [i \in 1 .. 1 |-> 0],
      openPositions               |-> [i \in 1 .. 4 |-> 0],
      tradeId                     |-> [i \in 1 .. 4 |-> 0] ]

(* Position Report at zero, then each field in turn at the values it is checked at *)
CheckedPositionReport ==
    { ZeroPositionReport }
        \cup { [ZeroPositionReport EXCEPT !.publicProductIdentification = one] : one \in CheckedPublicProductIdentification3 }
        \cup { [ZeroPositionReport EXCEPT !.posType = one] : one \in Sample(1) }
        \cup { [ZeroPositionReport EXCEPT !.openPositions = one] : one \in Sample(4) }
        \cup { [ZeroPositionReport EXCEPT !.tradeId = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Status Change: 11 bytes                                      *)
(***************************************************************************)

InstrumentStatusChange ==
    [ instrumentId     : Sample(4),
      tradingPhaseId   : Sample(4),
      tradingPhaseType : Sample(1),
      status           : Sample(1),
      stressedMarket   : Sample(1) ]

EncodeInstrumentStatusChange(message) ==
    message.instrumentId
        \o message.tradingPhaseId
        \o message.tradingPhaseType
        \o message.status
        \o message.stressedMarket

DecodeInstrumentStatusChange(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradingPhaseId == ReadBytes(instrumentId.rest, 4) IN IF ~tradingPhaseId.ok THEN Fail ELSE
    LET tradingPhaseType == ReadBytes(tradingPhaseId.rest, 1) IN IF ~tradingPhaseType.ok THEN Fail ELSE
    LET status == ReadBytes(tradingPhaseType.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET stressedMarket == ReadBytes(status.rest, 1) IN IF ~stressedMarket.ok THEN Fail ELSE
    Ok([ instrumentId     |-> instrumentId.value,
         tradingPhaseId   |-> tradingPhaseId.value,
         tradingPhaseType |-> tradingPhaseType.value,
         status           |-> status.value,
         stressedMarket   |-> stressedMarket.value ], stressedMarket.rest)

ZeroInstrumentStatusChange ==
    [ instrumentId     |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseId   |-> [i \in 1 .. 4 |-> 0],
      tradingPhaseType |-> [i \in 1 .. 1 |-> 0],
      status           |-> [i \in 1 .. 1 |-> 0],
      stressedMarket   |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Status Change at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentStatusChange ==
    { ZeroInstrumentStatusChange }
        \cup { [ZeroInstrumentStatusChange EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentStatusChange EXCEPT !.tradingPhaseId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentStatusChange EXCEPT !.tradingPhaseType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStatusChange EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStatusChange EXCEPT !.stressedMarket = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Collars: 45 bytes                                                 *)
(***************************************************************************)

OrderCollars ==
    [ instrumentId : Sample(4),
      collarType   : Sample(1),
      price        : Sample(8),
      lowerBid     : Sample(8),
      upperBid     : Sample(8),
      lowerAsk     : Sample(8),
      upperAsk     : Sample(8) ]

EncodeOrderCollars(message) ==
    message.instrumentId
        \o message.collarType
        \o message.price
        \o message.lowerBid
        \o message.upperBid
        \o message.lowerAsk
        \o message.upperAsk

DecodeOrderCollars(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET collarType == ReadBytes(instrumentId.rest, 1) IN IF ~collarType.ok THEN Fail ELSE
    LET price == ReadBytes(collarType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET lowerBid == ReadBytes(price.rest, 8) IN IF ~lowerBid.ok THEN Fail ELSE
    LET upperBid == ReadBytes(lowerBid.rest, 8) IN IF ~upperBid.ok THEN Fail ELSE
    LET lowerAsk == ReadBytes(upperBid.rest, 8) IN IF ~lowerAsk.ok THEN Fail ELSE
    LET upperAsk == ReadBytes(lowerAsk.rest, 8) IN IF ~upperAsk.ok THEN Fail ELSE
    Ok([ instrumentId |-> instrumentId.value,
         collarType   |-> collarType.value,
         price        |-> price.value,
         lowerBid     |-> lowerBid.value,
         upperBid     |-> upperBid.value,
         lowerAsk     |-> lowerAsk.value,
         upperAsk     |-> upperAsk.value ], upperAsk.rest)

ZeroOrderCollars ==
    [ instrumentId |-> [i \in 1 .. 4 |-> 0],
      collarType   |-> [i \in 1 .. 1 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      lowerBid     |-> [i \in 1 .. 8 |-> 0],
      upperBid     |-> [i \in 1 .. 8 |-> 0],
      lowerAsk     |-> [i \in 1 .. 8 |-> 0],
      upperAsk     |-> [i \in 1 .. 8 |-> 0] ]

(* Order Collars at zero, then each field in turn at the values it is checked at *)
CheckedOrderCollars ==
    { ZeroOrderCollars }
        \cup { [ZeroOrderCollars EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCollars EXCEPT !.collarType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCollars EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderCollars EXCEPT !.lowerBid = one] : one \in Sample(8) }
        \cup { [ZeroOrderCollars EXCEPT !.upperBid = one] : one \in Sample(8) }
        \cup { [ZeroOrderCollars EXCEPT !.lowerAsk = one] : one \in Sample(8) }
        \cup { [ZeroOrderCollars EXCEPT !.upperAsk = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Collars: 29 bytes                                                 *)
(***************************************************************************)

TradeCollars ==
    [ instrumentId : Sample(4),
      collarType   : Sample(1),
      price        : Sample(8),
      lower        : Sample(8),
      upper        : Sample(8) ]

EncodeTradeCollars(message) ==
    message.instrumentId
        \o message.collarType
        \o message.price
        \o message.lower
        \o message.upper

DecodeTradeCollars(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET collarType == ReadBytes(instrumentId.rest, 1) IN IF ~collarType.ok THEN Fail ELSE
    LET price == ReadBytes(collarType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET lower == ReadBytes(price.rest, 8) IN IF ~lower.ok THEN Fail ELSE
    LET upper == ReadBytes(lower.rest, 8) IN IF ~upper.ok THEN Fail ELSE
    Ok([ instrumentId |-> instrumentId.value,
         collarType   |-> collarType.value,
         price        |-> price.value,
         lower        |-> lower.value,
         upper        |-> upper.value ], upper.rest)

ZeroTradeCollars ==
    [ instrumentId |-> [i \in 1 .. 4 |-> 0],
      collarType   |-> [i \in 1 .. 1 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      lower        |-> [i \in 1 .. 8 |-> 0],
      upper        |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Collars at zero, then each field in turn at the values it is checked at *)
CheckedTradeCollars ==
    { ZeroTradeCollars }
        \cup { [ZeroTradeCollars EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCollars EXCEPT !.collarType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCollars EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeCollars EXCEPT !.lower = one] : one \in Sample(8) }
        \cup { [ZeroTradeCollars EXCEPT !.upper = one] : one \in Sample(8) }

(***************************************************************************)
(* Instrument Summary: 95 bytes                                            *)
(***************************************************************************)

InstrumentSummary ==
    [ instrumentId               : Sample(4),
      lastTradedPrice            : Sample(8),
      closingPrice               : Sample(8),
      closingPriceType           : Sample(1),
      adjustedClosingPrice       : Sample(8),
      adjustedClosingPriceReason : Sample(1),
      pctChange                  : Sample(8),
      vwap                       : Sample(8),
      noTrades                   : Sample(8),
      totalVolume                : Sample(8),
      totalValue                 : Sample(8),
      openingPrice               : Sample(8),
      maxPrice                   : Sample(8),
      minPrice                   : Sample(8),
      isCorrection               : Sample(1) ]

EncodeInstrumentSummary(message) ==
    message.instrumentId
        \o message.lastTradedPrice
        \o message.closingPrice
        \o message.closingPriceType
        \o message.adjustedClosingPrice
        \o message.adjustedClosingPriceReason
        \o message.pctChange
        \o message.vwap
        \o message.noTrades
        \o message.totalVolume
        \o message.totalValue
        \o message.openingPrice
        \o message.maxPrice
        \o message.minPrice
        \o message.isCorrection

DecodeInstrumentSummary(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET lastTradedPrice == ReadBytes(instrumentId.rest, 8) IN IF ~lastTradedPrice.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(lastTradedPrice.rest, 8) IN IF ~closingPrice.ok THEN Fail ELSE
    LET closingPriceType == ReadBytes(closingPrice.rest, 1) IN IF ~closingPriceType.ok THEN Fail ELSE
    LET adjustedClosingPrice == ReadBytes(closingPriceType.rest, 8) IN IF ~adjustedClosingPrice.ok THEN Fail ELSE
    LET adjustedClosingPriceReason == ReadBytes(adjustedClosingPrice.rest, 1) IN IF ~adjustedClosingPriceReason.ok THEN Fail ELSE
    LET pctChange == ReadBytes(adjustedClosingPriceReason.rest, 8) IN IF ~pctChange.ok THEN Fail ELSE
    LET vwap == ReadBytes(pctChange.rest, 8) IN IF ~vwap.ok THEN Fail ELSE
    LET noTrades == ReadBytes(vwap.rest, 8) IN IF ~noTrades.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(noTrades.rest, 8) IN IF ~totalVolume.ok THEN Fail ELSE
    LET totalValue == ReadBytes(totalVolume.rest, 8) IN IF ~totalValue.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(totalValue.rest, 8) IN IF ~openingPrice.ok THEN Fail ELSE
    LET maxPrice == ReadBytes(openingPrice.rest, 8) IN IF ~maxPrice.ok THEN Fail ELSE
    LET minPrice == ReadBytes(maxPrice.rest, 8) IN IF ~minPrice.ok THEN Fail ELSE
    LET isCorrection == ReadBytes(minPrice.rest, 1) IN IF ~isCorrection.ok THEN Fail ELSE
    Ok([ instrumentId               |-> instrumentId.value,
         lastTradedPrice            |-> lastTradedPrice.value,
         closingPrice               |-> closingPrice.value,
         closingPriceType           |-> closingPriceType.value,
         adjustedClosingPrice       |-> adjustedClosingPrice.value,
         adjustedClosingPriceReason |-> adjustedClosingPriceReason.value,
         pctChange                  |-> pctChange.value,
         vwap                       |-> vwap.value,
         noTrades                   |-> noTrades.value,
         totalVolume                |-> totalVolume.value,
         totalValue                 |-> totalValue.value,
         openingPrice               |-> openingPrice.value,
         maxPrice                   |-> maxPrice.value,
         minPrice                   |-> minPrice.value,
         isCorrection               |-> isCorrection.value ], isCorrection.rest)

ZeroInstrumentSummary ==
    [ instrumentId               |-> [i \in 1 .. 4 |-> 0],
      lastTradedPrice            |-> [i \in 1 .. 8 |-> 0],
      closingPrice               |-> [i \in 1 .. 8 |-> 0],
      closingPriceType           |-> [i \in 1 .. 1 |-> 0],
      adjustedClosingPrice       |-> [i \in 1 .. 8 |-> 0],
      adjustedClosingPriceReason |-> [i \in 1 .. 1 |-> 0],
      pctChange                  |-> [i \in 1 .. 8 |-> 0],
      vwap                       |-> [i \in 1 .. 8 |-> 0],
      noTrades                   |-> [i \in 1 .. 8 |-> 0],
      totalVolume                |-> [i \in 1 .. 8 |-> 0],
      totalValue                 |-> [i \in 1 .. 8 |-> 0],
      openingPrice               |-> [i \in 1 .. 8 |-> 0],
      maxPrice                   |-> [i \in 1 .. 8 |-> 0],
      minPrice                   |-> [i \in 1 .. 8 |-> 0],
      isCorrection               |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Summary at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentSummary ==
    { ZeroInstrumentSummary }
        \cup { [ZeroInstrumentSummary EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentSummary EXCEPT !.lastTradedPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.closingPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.closingPriceType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentSummary EXCEPT !.adjustedClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.adjustedClosingPriceReason = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentSummary EXCEPT !.pctChange = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.vwap = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.noTrades = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.totalVolume = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.totalValue = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.openingPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.maxPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.minPrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSummary EXCEPT !.isCorrection = one] : one \in Sample(1) }

(***************************************************************************)
(* Clob Instrument: 119 bytes                                              *)
(***************************************************************************)

ClobInstrument ==
    [ instrumentId               : Sample(4),
      marketModelType            : Sample(1),
      lastTradedPrice            : Sample(8),
      closingPrice               : Sample(8),
      closingPriceType           : Sample(1),
      adjustedClosingPrice       : Sample(8),
      adjustedClosingPriceReason : Sample(1),
      pctChange                  : Sample(8),
      vwap                       : Sample(8),
      noTrades                   : Sample(8),
      totalVolume                : Sample(8),
      totalValue                 : Sample(8),
      openingPrice               : Sample(8),
      maxPrice                   : Sample(8),
      minPrice                   : Sample(8),
      settlementPrice            : Sample(8),
      settlementValuePrice       : Sample(8),
      endTradingDate             : Sample(4),
      lastTradeDate              : Sample(4) ]

EncodeClobInstrument(message) ==
    message.instrumentId
        \o message.marketModelType
        \o message.lastTradedPrice
        \o message.closingPrice
        \o message.closingPriceType
        \o message.adjustedClosingPrice
        \o message.adjustedClosingPriceReason
        \o message.pctChange
        \o message.vwap
        \o message.noTrades
        \o message.totalVolume
        \o message.totalValue
        \o message.openingPrice
        \o message.maxPrice
        \o message.minPrice
        \o message.settlementPrice
        \o message.settlementValuePrice
        \o message.endTradingDate
        \o message.lastTradeDate

DecodeClobInstrument(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET marketModelType == ReadBytes(instrumentId.rest, 1) IN IF ~marketModelType.ok THEN Fail ELSE
    LET lastTradedPrice == ReadBytes(marketModelType.rest, 8) IN IF ~lastTradedPrice.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(lastTradedPrice.rest, 8) IN IF ~closingPrice.ok THEN Fail ELSE
    LET closingPriceType == ReadBytes(closingPrice.rest, 1) IN IF ~closingPriceType.ok THEN Fail ELSE
    LET adjustedClosingPrice == ReadBytes(closingPriceType.rest, 8) IN IF ~adjustedClosingPrice.ok THEN Fail ELSE
    LET adjustedClosingPriceReason == ReadBytes(adjustedClosingPrice.rest, 1) IN IF ~adjustedClosingPriceReason.ok THEN Fail ELSE
    LET pctChange == ReadBytes(adjustedClosingPriceReason.rest, 8) IN IF ~pctChange.ok THEN Fail ELSE
    LET vwap == ReadBytes(pctChange.rest, 8) IN IF ~vwap.ok THEN Fail ELSE
    LET noTrades == ReadBytes(vwap.rest, 8) IN IF ~noTrades.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(noTrades.rest, 8) IN IF ~totalVolume.ok THEN Fail ELSE
    LET totalValue == ReadBytes(totalVolume.rest, 8) IN IF ~totalValue.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(totalValue.rest, 8) IN IF ~openingPrice.ok THEN Fail ELSE
    LET maxPrice == ReadBytes(openingPrice.rest, 8) IN IF ~maxPrice.ok THEN Fail ELSE
    LET minPrice == ReadBytes(maxPrice.rest, 8) IN IF ~minPrice.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(minPrice.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementValuePrice == ReadBytes(settlementPrice.rest, 8) IN IF ~settlementValuePrice.ok THEN Fail ELSE
    LET endTradingDate == ReadBytes(settlementValuePrice.rest, 4) IN IF ~endTradingDate.ok THEN Fail ELSE
    LET lastTradeDate == ReadBytes(endTradingDate.rest, 4) IN IF ~lastTradeDate.ok THEN Fail ELSE
    Ok([ instrumentId               |-> instrumentId.value,
         marketModelType            |-> marketModelType.value,
         lastTradedPrice            |-> lastTradedPrice.value,
         closingPrice               |-> closingPrice.value,
         closingPriceType           |-> closingPriceType.value,
         adjustedClosingPrice       |-> adjustedClosingPrice.value,
         adjustedClosingPriceReason |-> adjustedClosingPriceReason.value,
         pctChange                  |-> pctChange.value,
         vwap                       |-> vwap.value,
         noTrades                   |-> noTrades.value,
         totalVolume                |-> totalVolume.value,
         totalValue                 |-> totalValue.value,
         openingPrice               |-> openingPrice.value,
         maxPrice                   |-> maxPrice.value,
         minPrice                   |-> minPrice.value,
         settlementPrice            |-> settlementPrice.value,
         settlementValuePrice       |-> settlementValuePrice.value,
         endTradingDate             |-> endTradingDate.value,
         lastTradeDate              |-> lastTradeDate.value ], lastTradeDate.rest)

ZeroClobInstrument ==
    [ instrumentId               |-> [i \in 1 .. 4 |-> 0],
      marketModelType            |-> [i \in 1 .. 1 |-> 0],
      lastTradedPrice            |-> [i \in 1 .. 8 |-> 0],
      closingPrice               |-> [i \in 1 .. 8 |-> 0],
      closingPriceType           |-> [i \in 1 .. 1 |-> 0],
      adjustedClosingPrice       |-> [i \in 1 .. 8 |-> 0],
      adjustedClosingPriceReason |-> [i \in 1 .. 1 |-> 0],
      pctChange                  |-> [i \in 1 .. 8 |-> 0],
      vwap                       |-> [i \in 1 .. 8 |-> 0],
      noTrades                   |-> [i \in 1 .. 8 |-> 0],
      totalVolume                |-> [i \in 1 .. 8 |-> 0],
      totalValue                 |-> [i \in 1 .. 8 |-> 0],
      openingPrice               |-> [i \in 1 .. 8 |-> 0],
      maxPrice                   |-> [i \in 1 .. 8 |-> 0],
      minPrice                   |-> [i \in 1 .. 8 |-> 0],
      settlementPrice            |-> [i \in 1 .. 8 |-> 0],
      settlementValuePrice       |-> [i \in 1 .. 8 |-> 0],
      endTradingDate             |-> [i \in 1 .. 4 |-> 0],
      lastTradeDate              |-> [i \in 1 .. 4 |-> 0] ]

(* Clob Instrument at zero, then each field in turn at the values it is checked at *)
CheckedClobInstrument ==
    { ZeroClobInstrument }
        \cup { [ZeroClobInstrument EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroClobInstrument EXCEPT !.marketModelType = one] : one \in Sample(1) }
        \cup { [ZeroClobInstrument EXCEPT !.lastTradedPrice = one] : one \in Sample(8) }
        \cup { [ZeroClobInstrument EXCEPT !.closingPrice = one] : one \in Sample(8) }
        \cup { [ZeroClobInstrument EXCEPT !.closingPriceType = one] : one \in Sample(1) }
        \cup { [ZeroClobInstrument EXCEPT !.adjustedClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroClobInstrument EXCEPT !.adjustedClosingPriceReason = one] : one \in Sample(1) }
        \cup { [ZeroClobInstrument EXCEPT !.pctChange = one] : one \in Sample(8) }
        \cup { [ZeroClobInstrument EXCEPT !.vwap = one] : one \in Sample(8) }
        \cup { [ZeroClobInstrument EXCEPT !.noTrades = one] : one \in Sample(8) }
        \cup { [ZeroClobInstrument EXCEPT !.totalVolume = one] : one \in Sample(8) }
        \cup { [ZeroClobInstrument EXCEPT !.totalValue = one] : one \in Sample(8) }
        \cup { [ZeroClobInstrument EXCEPT !.openingPrice = one] : one \in Sample(8) }
        \cup { [ZeroClobInstrument EXCEPT !.maxPrice = one] : one \in Sample(8) }
        \cup { [ZeroClobInstrument EXCEPT !.minPrice = one] : one \in Sample(8) }
        \cup { [ZeroClobInstrument EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroClobInstrument EXCEPT !.settlementValuePrice = one] : one \in Sample(8) }
        \cup { [ZeroClobInstrument EXCEPT !.endTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroClobInstrument EXCEPT !.lastTradeDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Cross Instrument: 119 bytes                                             *)
(***************************************************************************)

CrossInstrument ==
    [ instrumentId               : Sample(4),
      marketModelType            : Sample(1),
      lastTradedPrice            : Sample(8),
      closingPrice               : Sample(8),
      closingPriceType           : Sample(1),
      adjustedClosingPrice       : Sample(8),
      adjustedClosingPriceReason : Sample(1),
      pctChange                  : Sample(8),
      vwap                       : Sample(8),
      noTrades                   : Sample(8),
      totalVolume                : Sample(8),
      totalValue                 : Sample(8),
      openingPrice               : Sample(8),
      maxPrice                   : Sample(8),
      minPrice                   : Sample(8),
      settlementPrice            : Sample(8),
      settlementValuePrice       : Sample(8),
      endTradingDate             : Sample(4),
      lastTradeDate              : Sample(4) ]

EncodeCrossInstrument(message) ==
    message.instrumentId
        \o message.marketModelType
        \o message.lastTradedPrice
        \o message.closingPrice
        \o message.closingPriceType
        \o message.adjustedClosingPrice
        \o message.adjustedClosingPriceReason
        \o message.pctChange
        \o message.vwap
        \o message.noTrades
        \o message.totalVolume
        \o message.totalValue
        \o message.openingPrice
        \o message.maxPrice
        \o message.minPrice
        \o message.settlementPrice
        \o message.settlementValuePrice
        \o message.endTradingDate
        \o message.lastTradeDate

DecodeCrossInstrument(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET marketModelType == ReadBytes(instrumentId.rest, 1) IN IF ~marketModelType.ok THEN Fail ELSE
    LET lastTradedPrice == ReadBytes(marketModelType.rest, 8) IN IF ~lastTradedPrice.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(lastTradedPrice.rest, 8) IN IF ~closingPrice.ok THEN Fail ELSE
    LET closingPriceType == ReadBytes(closingPrice.rest, 1) IN IF ~closingPriceType.ok THEN Fail ELSE
    LET adjustedClosingPrice == ReadBytes(closingPriceType.rest, 8) IN IF ~adjustedClosingPrice.ok THEN Fail ELSE
    LET adjustedClosingPriceReason == ReadBytes(adjustedClosingPrice.rest, 1) IN IF ~adjustedClosingPriceReason.ok THEN Fail ELSE
    LET pctChange == ReadBytes(adjustedClosingPriceReason.rest, 8) IN IF ~pctChange.ok THEN Fail ELSE
    LET vwap == ReadBytes(pctChange.rest, 8) IN IF ~vwap.ok THEN Fail ELSE
    LET noTrades == ReadBytes(vwap.rest, 8) IN IF ~noTrades.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(noTrades.rest, 8) IN IF ~totalVolume.ok THEN Fail ELSE
    LET totalValue == ReadBytes(totalVolume.rest, 8) IN IF ~totalValue.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(totalValue.rest, 8) IN IF ~openingPrice.ok THEN Fail ELSE
    LET maxPrice == ReadBytes(openingPrice.rest, 8) IN IF ~maxPrice.ok THEN Fail ELSE
    LET minPrice == ReadBytes(maxPrice.rest, 8) IN IF ~minPrice.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(minPrice.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementValuePrice == ReadBytes(settlementPrice.rest, 8) IN IF ~settlementValuePrice.ok THEN Fail ELSE
    LET endTradingDate == ReadBytes(settlementValuePrice.rest, 4) IN IF ~endTradingDate.ok THEN Fail ELSE
    LET lastTradeDate == ReadBytes(endTradingDate.rest, 4) IN IF ~lastTradeDate.ok THEN Fail ELSE
    Ok([ instrumentId               |-> instrumentId.value,
         marketModelType            |-> marketModelType.value,
         lastTradedPrice            |-> lastTradedPrice.value,
         closingPrice               |-> closingPrice.value,
         closingPriceType           |-> closingPriceType.value,
         adjustedClosingPrice       |-> adjustedClosingPrice.value,
         adjustedClosingPriceReason |-> adjustedClosingPriceReason.value,
         pctChange                  |-> pctChange.value,
         vwap                       |-> vwap.value,
         noTrades                   |-> noTrades.value,
         totalVolume                |-> totalVolume.value,
         totalValue                 |-> totalValue.value,
         openingPrice               |-> openingPrice.value,
         maxPrice                   |-> maxPrice.value,
         minPrice                   |-> minPrice.value,
         settlementPrice            |-> settlementPrice.value,
         settlementValuePrice       |-> settlementValuePrice.value,
         endTradingDate             |-> endTradingDate.value,
         lastTradeDate              |-> lastTradeDate.value ], lastTradeDate.rest)

ZeroCrossInstrument ==
    [ instrumentId               |-> [i \in 1 .. 4 |-> 0],
      marketModelType            |-> [i \in 1 .. 1 |-> 0],
      lastTradedPrice            |-> [i \in 1 .. 8 |-> 0],
      closingPrice               |-> [i \in 1 .. 8 |-> 0],
      closingPriceType           |-> [i \in 1 .. 1 |-> 0],
      adjustedClosingPrice       |-> [i \in 1 .. 8 |-> 0],
      adjustedClosingPriceReason |-> [i \in 1 .. 1 |-> 0],
      pctChange                  |-> [i \in 1 .. 8 |-> 0],
      vwap                       |-> [i \in 1 .. 8 |-> 0],
      noTrades                   |-> [i \in 1 .. 8 |-> 0],
      totalVolume                |-> [i \in 1 .. 8 |-> 0],
      totalValue                 |-> [i \in 1 .. 8 |-> 0],
      openingPrice               |-> [i \in 1 .. 8 |-> 0],
      maxPrice                   |-> [i \in 1 .. 8 |-> 0],
      minPrice                   |-> [i \in 1 .. 8 |-> 0],
      settlementPrice            |-> [i \in 1 .. 8 |-> 0],
      settlementValuePrice       |-> [i \in 1 .. 8 |-> 0],
      endTradingDate             |-> [i \in 1 .. 4 |-> 0],
      lastTradeDate              |-> [i \in 1 .. 4 |-> 0] ]

(* Cross Instrument at zero, then each field in turn at the values it is checked at *)
CheckedCrossInstrument ==
    { ZeroCrossInstrument }
        \cup { [ZeroCrossInstrument EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroCrossInstrument EXCEPT !.marketModelType = one] : one \in Sample(1) }
        \cup { [ZeroCrossInstrument EXCEPT !.lastTradedPrice = one] : one \in Sample(8) }
        \cup { [ZeroCrossInstrument EXCEPT !.closingPrice = one] : one \in Sample(8) }
        \cup { [ZeroCrossInstrument EXCEPT !.closingPriceType = one] : one \in Sample(1) }
        \cup { [ZeroCrossInstrument EXCEPT !.adjustedClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroCrossInstrument EXCEPT !.adjustedClosingPriceReason = one] : one \in Sample(1) }
        \cup { [ZeroCrossInstrument EXCEPT !.pctChange = one] : one \in Sample(8) }
        \cup { [ZeroCrossInstrument EXCEPT !.vwap = one] : one \in Sample(8) }
        \cup { [ZeroCrossInstrument EXCEPT !.noTrades = one] : one \in Sample(8) }
        \cup { [ZeroCrossInstrument EXCEPT !.totalVolume = one] : one \in Sample(8) }
        \cup { [ZeroCrossInstrument EXCEPT !.totalValue = one] : one \in Sample(8) }
        \cup { [ZeroCrossInstrument EXCEPT !.openingPrice = one] : one \in Sample(8) }
        \cup { [ZeroCrossInstrument EXCEPT !.maxPrice = one] : one \in Sample(8) }
        \cup { [ZeroCrossInstrument EXCEPT !.minPrice = one] : one \in Sample(8) }
        \cup { [ZeroCrossInstrument EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroCrossInstrument EXCEPT !.settlementValuePrice = one] : one \in Sample(8) }
        \cup { [ZeroCrossInstrument EXCEPT !.endTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroCrossInstrument EXCEPT !.lastTradeDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Block Instrument: 119 bytes                                             *)
(***************************************************************************)

BlockInstrument ==
    [ instrumentId               : Sample(4),
      marketModelType            : Sample(1),
      lastTradedPrice            : Sample(8),
      closingPrice               : Sample(8),
      closingPriceType           : Sample(1),
      adjustedClosingPrice       : Sample(8),
      adjustedClosingPriceReason : Sample(1),
      pctChange                  : Sample(8),
      vwap                       : Sample(8),
      noTrades                   : Sample(8),
      totalVolume                : Sample(8),
      totalValue                 : Sample(8),
      openingPrice               : Sample(8),
      maxPrice                   : Sample(8),
      minPrice                   : Sample(8),
      settlementPrice            : Sample(8),
      settlementValuePrice       : Sample(8),
      endTradingDate             : Sample(4),
      lastTradeDate              : Sample(4) ]

EncodeBlockInstrument(message) ==
    message.instrumentId
        \o message.marketModelType
        \o message.lastTradedPrice
        \o message.closingPrice
        \o message.closingPriceType
        \o message.adjustedClosingPrice
        \o message.adjustedClosingPriceReason
        \o message.pctChange
        \o message.vwap
        \o message.noTrades
        \o message.totalVolume
        \o message.totalValue
        \o message.openingPrice
        \o message.maxPrice
        \o message.minPrice
        \o message.settlementPrice
        \o message.settlementValuePrice
        \o message.endTradingDate
        \o message.lastTradeDate

DecodeBlockInstrument(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET marketModelType == ReadBytes(instrumentId.rest, 1) IN IF ~marketModelType.ok THEN Fail ELSE
    LET lastTradedPrice == ReadBytes(marketModelType.rest, 8) IN IF ~lastTradedPrice.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(lastTradedPrice.rest, 8) IN IF ~closingPrice.ok THEN Fail ELSE
    LET closingPriceType == ReadBytes(closingPrice.rest, 1) IN IF ~closingPriceType.ok THEN Fail ELSE
    LET adjustedClosingPrice == ReadBytes(closingPriceType.rest, 8) IN IF ~adjustedClosingPrice.ok THEN Fail ELSE
    LET adjustedClosingPriceReason == ReadBytes(adjustedClosingPrice.rest, 1) IN IF ~adjustedClosingPriceReason.ok THEN Fail ELSE
    LET pctChange == ReadBytes(adjustedClosingPriceReason.rest, 8) IN IF ~pctChange.ok THEN Fail ELSE
    LET vwap == ReadBytes(pctChange.rest, 8) IN IF ~vwap.ok THEN Fail ELSE
    LET noTrades == ReadBytes(vwap.rest, 8) IN IF ~noTrades.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(noTrades.rest, 8) IN IF ~totalVolume.ok THEN Fail ELSE
    LET totalValue == ReadBytes(totalVolume.rest, 8) IN IF ~totalValue.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(totalValue.rest, 8) IN IF ~openingPrice.ok THEN Fail ELSE
    LET maxPrice == ReadBytes(openingPrice.rest, 8) IN IF ~maxPrice.ok THEN Fail ELSE
    LET minPrice == ReadBytes(maxPrice.rest, 8) IN IF ~minPrice.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(minPrice.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementValuePrice == ReadBytes(settlementPrice.rest, 8) IN IF ~settlementValuePrice.ok THEN Fail ELSE
    LET endTradingDate == ReadBytes(settlementValuePrice.rest, 4) IN IF ~endTradingDate.ok THEN Fail ELSE
    LET lastTradeDate == ReadBytes(endTradingDate.rest, 4) IN IF ~lastTradeDate.ok THEN Fail ELSE
    Ok([ instrumentId               |-> instrumentId.value,
         marketModelType            |-> marketModelType.value,
         lastTradedPrice            |-> lastTradedPrice.value,
         closingPrice               |-> closingPrice.value,
         closingPriceType           |-> closingPriceType.value,
         adjustedClosingPrice       |-> adjustedClosingPrice.value,
         adjustedClosingPriceReason |-> adjustedClosingPriceReason.value,
         pctChange                  |-> pctChange.value,
         vwap                       |-> vwap.value,
         noTrades                   |-> noTrades.value,
         totalVolume                |-> totalVolume.value,
         totalValue                 |-> totalValue.value,
         openingPrice               |-> openingPrice.value,
         maxPrice                   |-> maxPrice.value,
         minPrice                   |-> minPrice.value,
         settlementPrice            |-> settlementPrice.value,
         settlementValuePrice       |-> settlementValuePrice.value,
         endTradingDate             |-> endTradingDate.value,
         lastTradeDate              |-> lastTradeDate.value ], lastTradeDate.rest)

ZeroBlockInstrument ==
    [ instrumentId               |-> [i \in 1 .. 4 |-> 0],
      marketModelType            |-> [i \in 1 .. 1 |-> 0],
      lastTradedPrice            |-> [i \in 1 .. 8 |-> 0],
      closingPrice               |-> [i \in 1 .. 8 |-> 0],
      closingPriceType           |-> [i \in 1 .. 1 |-> 0],
      adjustedClosingPrice       |-> [i \in 1 .. 8 |-> 0],
      adjustedClosingPriceReason |-> [i \in 1 .. 1 |-> 0],
      pctChange                  |-> [i \in 1 .. 8 |-> 0],
      vwap                       |-> [i \in 1 .. 8 |-> 0],
      noTrades                   |-> [i \in 1 .. 8 |-> 0],
      totalVolume                |-> [i \in 1 .. 8 |-> 0],
      totalValue                 |-> [i \in 1 .. 8 |-> 0],
      openingPrice               |-> [i \in 1 .. 8 |-> 0],
      maxPrice                   |-> [i \in 1 .. 8 |-> 0],
      minPrice                   |-> [i \in 1 .. 8 |-> 0],
      settlementPrice            |-> [i \in 1 .. 8 |-> 0],
      settlementValuePrice       |-> [i \in 1 .. 8 |-> 0],
      endTradingDate             |-> [i \in 1 .. 4 |-> 0],
      lastTradeDate              |-> [i \in 1 .. 4 |-> 0] ]

(* Block Instrument at zero, then each field in turn at the values it is checked at *)
CheckedBlockInstrument ==
    { ZeroBlockInstrument }
        \cup { [ZeroBlockInstrument EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroBlockInstrument EXCEPT !.marketModelType = one] : one \in Sample(1) }
        \cup { [ZeroBlockInstrument EXCEPT !.lastTradedPrice = one] : one \in Sample(8) }
        \cup { [ZeroBlockInstrument EXCEPT !.closingPrice = one] : one \in Sample(8) }
        \cup { [ZeroBlockInstrument EXCEPT !.closingPriceType = one] : one \in Sample(1) }
        \cup { [ZeroBlockInstrument EXCEPT !.adjustedClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroBlockInstrument EXCEPT !.adjustedClosingPriceReason = one] : one \in Sample(1) }
        \cup { [ZeroBlockInstrument EXCEPT !.pctChange = one] : one \in Sample(8) }
        \cup { [ZeroBlockInstrument EXCEPT !.vwap = one] : one \in Sample(8) }
        \cup { [ZeroBlockInstrument EXCEPT !.noTrades = one] : one \in Sample(8) }
        \cup { [ZeroBlockInstrument EXCEPT !.totalVolume = one] : one \in Sample(8) }
        \cup { [ZeroBlockInstrument EXCEPT !.totalValue = one] : one \in Sample(8) }
        \cup { [ZeroBlockInstrument EXCEPT !.openingPrice = one] : one \in Sample(8) }
        \cup { [ZeroBlockInstrument EXCEPT !.maxPrice = one] : one \in Sample(8) }
        \cup { [ZeroBlockInstrument EXCEPT !.minPrice = one] : one \in Sample(8) }
        \cup { [ZeroBlockInstrument EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroBlockInstrument EXCEPT !.settlementValuePrice = one] : one \in Sample(8) }
        \cup { [ZeroBlockInstrument EXCEPT !.endTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroBlockInstrument EXCEPT !.lastTradeDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Hybrid Instrument: 119 bytes                                            *)
(***************************************************************************)

HybridInstrument ==
    [ instrumentId               : Sample(4),
      marketModelType            : Sample(1),
      lastTradedPrice            : Sample(8),
      closingPrice               : Sample(8),
      closingPriceType           : Sample(1),
      adjustedClosingPrice       : Sample(8),
      adjustedClosingPriceReason : Sample(1),
      pctChange                  : Sample(8),
      vwap                       : Sample(8),
      noTrades                   : Sample(8),
      totalVolume                : Sample(8),
      totalValue                 : Sample(8),
      openingPrice               : Sample(8),
      maxPrice                   : Sample(8),
      minPrice                   : Sample(8),
      settlementPrice            : Sample(8),
      settlementValuePrice       : Sample(8),
      endTradingDate             : Sample(4),
      lastTradeDate              : Sample(4) ]

EncodeHybridInstrument(message) ==
    message.instrumentId
        \o message.marketModelType
        \o message.lastTradedPrice
        \o message.closingPrice
        \o message.closingPriceType
        \o message.adjustedClosingPrice
        \o message.adjustedClosingPriceReason
        \o message.pctChange
        \o message.vwap
        \o message.noTrades
        \o message.totalVolume
        \o message.totalValue
        \o message.openingPrice
        \o message.maxPrice
        \o message.minPrice
        \o message.settlementPrice
        \o message.settlementValuePrice
        \o message.endTradingDate
        \o message.lastTradeDate

DecodeHybridInstrument(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET marketModelType == ReadBytes(instrumentId.rest, 1) IN IF ~marketModelType.ok THEN Fail ELSE
    LET lastTradedPrice == ReadBytes(marketModelType.rest, 8) IN IF ~lastTradedPrice.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(lastTradedPrice.rest, 8) IN IF ~closingPrice.ok THEN Fail ELSE
    LET closingPriceType == ReadBytes(closingPrice.rest, 1) IN IF ~closingPriceType.ok THEN Fail ELSE
    LET adjustedClosingPrice == ReadBytes(closingPriceType.rest, 8) IN IF ~adjustedClosingPrice.ok THEN Fail ELSE
    LET adjustedClosingPriceReason == ReadBytes(adjustedClosingPrice.rest, 1) IN IF ~adjustedClosingPriceReason.ok THEN Fail ELSE
    LET pctChange == ReadBytes(adjustedClosingPriceReason.rest, 8) IN IF ~pctChange.ok THEN Fail ELSE
    LET vwap == ReadBytes(pctChange.rest, 8) IN IF ~vwap.ok THEN Fail ELSE
    LET noTrades == ReadBytes(vwap.rest, 8) IN IF ~noTrades.ok THEN Fail ELSE
    LET totalVolume == ReadBytes(noTrades.rest, 8) IN IF ~totalVolume.ok THEN Fail ELSE
    LET totalValue == ReadBytes(totalVolume.rest, 8) IN IF ~totalValue.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(totalValue.rest, 8) IN IF ~openingPrice.ok THEN Fail ELSE
    LET maxPrice == ReadBytes(openingPrice.rest, 8) IN IF ~maxPrice.ok THEN Fail ELSE
    LET minPrice == ReadBytes(maxPrice.rest, 8) IN IF ~minPrice.ok THEN Fail ELSE
    LET settlementPrice == ReadBytes(minPrice.rest, 8) IN IF ~settlementPrice.ok THEN Fail ELSE
    LET settlementValuePrice == ReadBytes(settlementPrice.rest, 8) IN IF ~settlementValuePrice.ok THEN Fail ELSE
    LET endTradingDate == ReadBytes(settlementValuePrice.rest, 4) IN IF ~endTradingDate.ok THEN Fail ELSE
    LET lastTradeDate == ReadBytes(endTradingDate.rest, 4) IN IF ~lastTradeDate.ok THEN Fail ELSE
    Ok([ instrumentId               |-> instrumentId.value,
         marketModelType            |-> marketModelType.value,
         lastTradedPrice            |-> lastTradedPrice.value,
         closingPrice               |-> closingPrice.value,
         closingPriceType           |-> closingPriceType.value,
         adjustedClosingPrice       |-> adjustedClosingPrice.value,
         adjustedClosingPriceReason |-> adjustedClosingPriceReason.value,
         pctChange                  |-> pctChange.value,
         vwap                       |-> vwap.value,
         noTrades                   |-> noTrades.value,
         totalVolume                |-> totalVolume.value,
         totalValue                 |-> totalValue.value,
         openingPrice               |-> openingPrice.value,
         maxPrice                   |-> maxPrice.value,
         minPrice                   |-> minPrice.value,
         settlementPrice            |-> settlementPrice.value,
         settlementValuePrice       |-> settlementValuePrice.value,
         endTradingDate             |-> endTradingDate.value,
         lastTradeDate              |-> lastTradeDate.value ], lastTradeDate.rest)

ZeroHybridInstrument ==
    [ instrumentId               |-> [i \in 1 .. 4 |-> 0],
      marketModelType            |-> [i \in 1 .. 1 |-> 0],
      lastTradedPrice            |-> [i \in 1 .. 8 |-> 0],
      closingPrice               |-> [i \in 1 .. 8 |-> 0],
      closingPriceType           |-> [i \in 1 .. 1 |-> 0],
      adjustedClosingPrice       |-> [i \in 1 .. 8 |-> 0],
      adjustedClosingPriceReason |-> [i \in 1 .. 1 |-> 0],
      pctChange                  |-> [i \in 1 .. 8 |-> 0],
      vwap                       |-> [i \in 1 .. 8 |-> 0],
      noTrades                   |-> [i \in 1 .. 8 |-> 0],
      totalVolume                |-> [i \in 1 .. 8 |-> 0],
      totalValue                 |-> [i \in 1 .. 8 |-> 0],
      openingPrice               |-> [i \in 1 .. 8 |-> 0],
      maxPrice                   |-> [i \in 1 .. 8 |-> 0],
      minPrice                   |-> [i \in 1 .. 8 |-> 0],
      settlementPrice            |-> [i \in 1 .. 8 |-> 0],
      settlementValuePrice       |-> [i \in 1 .. 8 |-> 0],
      endTradingDate             |-> [i \in 1 .. 4 |-> 0],
      lastTradeDate              |-> [i \in 1 .. 4 |-> 0] ]

(* Hybrid Instrument at zero, then each field in turn at the values it is checked at *)
CheckedHybridInstrument ==
    { ZeroHybridInstrument }
        \cup { [ZeroHybridInstrument EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroHybridInstrument EXCEPT !.marketModelType = one] : one \in Sample(1) }
        \cup { [ZeroHybridInstrument EXCEPT !.lastTradedPrice = one] : one \in Sample(8) }
        \cup { [ZeroHybridInstrument EXCEPT !.closingPrice = one] : one \in Sample(8) }
        \cup { [ZeroHybridInstrument EXCEPT !.closingPriceType = one] : one \in Sample(1) }
        \cup { [ZeroHybridInstrument EXCEPT !.adjustedClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroHybridInstrument EXCEPT !.adjustedClosingPriceReason = one] : one \in Sample(1) }
        \cup { [ZeroHybridInstrument EXCEPT !.pctChange = one] : one \in Sample(8) }
        \cup { [ZeroHybridInstrument EXCEPT !.vwap = one] : one \in Sample(8) }
        \cup { [ZeroHybridInstrument EXCEPT !.noTrades = one] : one \in Sample(8) }
        \cup { [ZeroHybridInstrument EXCEPT !.totalVolume = one] : one \in Sample(8) }
        \cup { [ZeroHybridInstrument EXCEPT !.totalValue = one] : one \in Sample(8) }
        \cup { [ZeroHybridInstrument EXCEPT !.openingPrice = one] : one \in Sample(8) }
        \cup { [ZeroHybridInstrument EXCEPT !.maxPrice = one] : one \in Sample(8) }
        \cup { [ZeroHybridInstrument EXCEPT !.minPrice = one] : one \in Sample(8) }
        \cup { [ZeroHybridInstrument EXCEPT !.settlementPrice = one] : one \in Sample(8) }
        \cup { [ZeroHybridInstrument EXCEPT !.settlementValuePrice = one] : one \in Sample(8) }
        \cup { [ZeroHybridInstrument EXCEPT !.endTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroHybridInstrument EXCEPT !.lastTradeDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Product Summary: 629 bytes                                              *)
(***************************************************************************)

ProductSummary ==
    [ clobInstrument                             : ClobInstrument,
      crossInstrument                            : CrossInstrument,
      blockInstrument                            : BlockInstrument,
      hybridInstrument                           : HybridInstrument,
      productIdentificationType                  : Sample(1),
      productIdentificationProductIdentification : Sample(30),
      productId                                  : Sample(4),
      mic                                        : Sample(4),
      accumulatedInterest                        : Sample(8),
      interestRate                               : Sample(8),
      currency                                   : Sample(2),
      sessionDate                                : Sample(4),
      tradingValueCurrency                       : Sample(8),
      status                                     : Sample(1),
      sector                                     : Sample(2),
      market                                     : Sample(1),
      markerPriceChange                          : Sample(1),
      lowerLiquidity                             : Sample(1),
      multiplierNumber                           : Sample(8),
      dividendRate                               : Sample(8),
      delta                                      : Sample(8),
      gamma                                      : Sample(8),
      rho                                        : Sample(8),
      theta                                      : Sample(8),
      vega                                       : Sample(8),
      volatility                                 : Sample(8),
      optionsStrikePrice                         : Sample(8),
      dividend                                   : Sample(1),
      subscriptionRight                          : Sample(1),
      interimDividendRight                       : Sample(1),
      split                                      : Sample(1),
      quotationSystem                            : Sample(1),
      liquiditySupportPge                        : Sample(1) ]

EncodeProductSummary(message) ==
    EncodeClobInstrument(message.clobInstrument)
        \o EncodeCrossInstrument(message.crossInstrument)
        \o EncodeBlockInstrument(message.blockInstrument)
        \o EncodeHybridInstrument(message.hybridInstrument)
        \o message.productIdentificationType
        \o message.productIdentificationProductIdentification
        \o message.productId
        \o message.mic
        \o message.accumulatedInterest
        \o message.interestRate
        \o message.currency
        \o message.sessionDate
        \o message.tradingValueCurrency
        \o message.status
        \o message.sector
        \o message.market
        \o message.markerPriceChange
        \o message.lowerLiquidity
        \o message.multiplierNumber
        \o message.dividendRate
        \o message.delta
        \o message.gamma
        \o message.rho
        \o message.theta
        \o message.vega
        \o message.volatility
        \o message.optionsStrikePrice
        \o message.dividend
        \o message.subscriptionRight
        \o message.interimDividendRight
        \o message.split
        \o message.quotationSystem
        \o message.liquiditySupportPge

DecodeProductSummary(bytes) ==
    LET clobInstrument == DecodeClobInstrument(bytes) IN IF ~clobInstrument.ok THEN Fail ELSE
    LET crossInstrument == DecodeCrossInstrument(clobInstrument.rest) IN IF ~crossInstrument.ok THEN Fail ELSE
    LET blockInstrument == DecodeBlockInstrument(crossInstrument.rest) IN IF ~blockInstrument.ok THEN Fail ELSE
    LET hybridInstrument == DecodeHybridInstrument(blockInstrument.rest) IN IF ~hybridInstrument.ok THEN Fail ELSE
    LET productIdentificationType == ReadBytes(hybridInstrument.rest, 1) IN IF ~productIdentificationType.ok THEN Fail ELSE
    LET productIdentificationProductIdentification == ReadBytes(productIdentificationType.rest, 30) IN IF ~productIdentificationProductIdentification.ok THEN Fail ELSE
    LET productId == ReadBytes(productIdentificationProductIdentification.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET mic == ReadBytes(productId.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET accumulatedInterest == ReadBytes(mic.rest, 8) IN IF ~accumulatedInterest.ok THEN Fail ELSE
    LET interestRate == ReadBytes(accumulatedInterest.rest, 8) IN IF ~interestRate.ok THEN Fail ELSE
    LET currency == ReadBytes(interestRate.rest, 2) IN IF ~currency.ok THEN Fail ELSE
    LET sessionDate == ReadBytes(currency.rest, 4) IN IF ~sessionDate.ok THEN Fail ELSE
    LET tradingValueCurrency == ReadBytes(sessionDate.rest, 8) IN IF ~tradingValueCurrency.ok THEN Fail ELSE
    LET status == ReadBytes(tradingValueCurrency.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET sector == ReadBytes(status.rest, 2) IN IF ~sector.ok THEN Fail ELSE
    LET market == ReadBytes(sector.rest, 1) IN IF ~market.ok THEN Fail ELSE
    LET markerPriceChange == ReadBytes(market.rest, 1) IN IF ~markerPriceChange.ok THEN Fail ELSE
    LET lowerLiquidity == ReadBytes(markerPriceChange.rest, 1) IN IF ~lowerLiquidity.ok THEN Fail ELSE
    LET multiplierNumber == ReadBytes(lowerLiquidity.rest, 8) IN IF ~multiplierNumber.ok THEN Fail ELSE
    LET dividendRate == ReadBytes(multiplierNumber.rest, 8) IN IF ~dividendRate.ok THEN Fail ELSE
    LET delta == ReadBytes(dividendRate.rest, 8) IN IF ~delta.ok THEN Fail ELSE
    LET gamma == ReadBytes(delta.rest, 8) IN IF ~gamma.ok THEN Fail ELSE
    LET rho == ReadBytes(gamma.rest, 8) IN IF ~rho.ok THEN Fail ELSE
    LET theta == ReadBytes(rho.rest, 8) IN IF ~theta.ok THEN Fail ELSE
    LET vega == ReadBytes(theta.rest, 8) IN IF ~vega.ok THEN Fail ELSE
    LET volatility == ReadBytes(vega.rest, 8) IN IF ~volatility.ok THEN Fail ELSE
    LET optionsStrikePrice == ReadBytes(volatility.rest, 8) IN IF ~optionsStrikePrice.ok THEN Fail ELSE
    LET dividend == ReadBytes(optionsStrikePrice.rest, 1) IN IF ~dividend.ok THEN Fail ELSE
    LET subscriptionRight == ReadBytes(dividend.rest, 1) IN IF ~subscriptionRight.ok THEN Fail ELSE
    LET interimDividendRight == ReadBytes(subscriptionRight.rest, 1) IN IF ~interimDividendRight.ok THEN Fail ELSE
    LET split == ReadBytes(interimDividendRight.rest, 1) IN IF ~split.ok THEN Fail ELSE
    LET quotationSystem == ReadBytes(split.rest, 1) IN IF ~quotationSystem.ok THEN Fail ELSE
    LET liquiditySupportPge == ReadBytes(quotationSystem.rest, 1) IN IF ~liquiditySupportPge.ok THEN Fail ELSE
    Ok([ clobInstrument                             |-> clobInstrument.value,
         crossInstrument                            |-> crossInstrument.value,
         blockInstrument                            |-> blockInstrument.value,
         hybridInstrument                           |-> hybridInstrument.value,
         productIdentificationType                  |-> productIdentificationType.value,
         productIdentificationProductIdentification |-> productIdentificationProductIdentification.value,
         productId                                  |-> productId.value,
         mic                                        |-> mic.value,
         accumulatedInterest                        |-> accumulatedInterest.value,
         interestRate                               |-> interestRate.value,
         currency                                   |-> currency.value,
         sessionDate                                |-> sessionDate.value,
         tradingValueCurrency                       |-> tradingValueCurrency.value,
         status                                     |-> status.value,
         sector                                     |-> sector.value,
         market                                     |-> market.value,
         markerPriceChange                          |-> markerPriceChange.value,
         lowerLiquidity                             |-> lowerLiquidity.value,
         multiplierNumber                           |-> multiplierNumber.value,
         dividendRate                               |-> dividendRate.value,
         delta                                      |-> delta.value,
         gamma                                      |-> gamma.value,
         rho                                        |-> rho.value,
         theta                                      |-> theta.value,
         vega                                       |-> vega.value,
         volatility                                 |-> volatility.value,
         optionsStrikePrice                         |-> optionsStrikePrice.value,
         dividend                                   |-> dividend.value,
         subscriptionRight                          |-> subscriptionRight.value,
         interimDividendRight                       |-> interimDividendRight.value,
         split                                      |-> split.value,
         quotationSystem                            |-> quotationSystem.value,
         liquiditySupportPge                        |-> liquiditySupportPge.value ], liquiditySupportPge.rest)

ZeroProductSummary ==
    [ clobInstrument                             |-> ZeroClobInstrument,
      crossInstrument                            |-> ZeroCrossInstrument,
      blockInstrument                            |-> ZeroBlockInstrument,
      hybridInstrument                           |-> ZeroHybridInstrument,
      productIdentificationType                  |-> [i \in 1 .. 1 |-> 0],
      productIdentificationProductIdentification |-> [i \in 1 .. 30 |-> 0],
      productId                                  |-> [i \in 1 .. 4 |-> 0],
      mic                                        |-> [i \in 1 .. 4 |-> 0],
      accumulatedInterest                        |-> [i \in 1 .. 8 |-> 0],
      interestRate                               |-> [i \in 1 .. 8 |-> 0],
      currency                                   |-> [i \in 1 .. 2 |-> 0],
      sessionDate                                |-> [i \in 1 .. 4 |-> 0],
      tradingValueCurrency                       |-> [i \in 1 .. 8 |-> 0],
      status                                     |-> [i \in 1 .. 1 |-> 0],
      sector                                     |-> [i \in 1 .. 2 |-> 0],
      market                                     |-> [i \in 1 .. 1 |-> 0],
      markerPriceChange                          |-> [i \in 1 .. 1 |-> 0],
      lowerLiquidity                             |-> [i \in 1 .. 1 |-> 0],
      multiplierNumber                           |-> [i \in 1 .. 8 |-> 0],
      dividendRate                               |-> [i \in 1 .. 8 |-> 0],
      delta                                      |-> [i \in 1 .. 8 |-> 0],
      gamma                                      |-> [i \in 1 .. 8 |-> 0],
      rho                                        |-> [i \in 1 .. 8 |-> 0],
      theta                                      |-> [i \in 1 .. 8 |-> 0],
      vega                                       |-> [i \in 1 .. 8 |-> 0],
      volatility                                 |-> [i \in 1 .. 8 |-> 0],
      optionsStrikePrice                         |-> [i \in 1 .. 8 |-> 0],
      dividend                                   |-> [i \in 1 .. 1 |-> 0],
      subscriptionRight                          |-> [i \in 1 .. 1 |-> 0],
      interimDividendRight                       |-> [i \in 1 .. 1 |-> 0],
      split                                      |-> [i \in 1 .. 1 |-> 0],
      quotationSystem                            |-> [i \in 1 .. 1 |-> 0],
      liquiditySupportPge                        |-> [i \in 1 .. 1 |-> 0] ]

(* Product Summary at zero, then each field in turn at the values it is checked at *)
CheckedProductSummary ==
    { ZeroProductSummary }
        \cup { [ZeroProductSummary EXCEPT !.clobInstrument = one] : one \in CheckedClobInstrument }
        \cup { [ZeroProductSummary EXCEPT !.crossInstrument = one] : one \in CheckedCrossInstrument }
        \cup { [ZeroProductSummary EXCEPT !.blockInstrument = one] : one \in CheckedBlockInstrument }
        \cup { [ZeroProductSummary EXCEPT !.hybridInstrument = one] : one \in CheckedHybridInstrument }
        \cup { [ZeroProductSummary EXCEPT !.productIdentificationType = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.productIdentificationProductIdentification = one] : one \in Sample(30) }
        \cup { [ZeroProductSummary EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroProductSummary EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroProductSummary EXCEPT !.accumulatedInterest = one] : one \in Sample(8) }
        \cup { [ZeroProductSummary EXCEPT !.interestRate = one] : one \in Sample(8) }
        \cup { [ZeroProductSummary EXCEPT !.currency = one] : one \in Sample(2) }
        \cup { [ZeroProductSummary EXCEPT !.sessionDate = one] : one \in Sample(4) }
        \cup { [ZeroProductSummary EXCEPT !.tradingValueCurrency = one] : one \in Sample(8) }
        \cup { [ZeroProductSummary EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.sector = one] : one \in Sample(2) }
        \cup { [ZeroProductSummary EXCEPT !.market = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.markerPriceChange = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.lowerLiquidity = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.multiplierNumber = one] : one \in Sample(8) }
        \cup { [ZeroProductSummary EXCEPT !.dividendRate = one] : one \in Sample(8) }
        \cup { [ZeroProductSummary EXCEPT !.delta = one] : one \in Sample(8) }
        \cup { [ZeroProductSummary EXCEPT !.gamma = one] : one \in Sample(8) }
        \cup { [ZeroProductSummary EXCEPT !.rho = one] : one \in Sample(8) }
        \cup { [ZeroProductSummary EXCEPT !.theta = one] : one \in Sample(8) }
        \cup { [ZeroProductSummary EXCEPT !.vega = one] : one \in Sample(8) }
        \cup { [ZeroProductSummary EXCEPT !.volatility = one] : one \in Sample(8) }
        \cup { [ZeroProductSummary EXCEPT !.optionsStrikePrice = one] : one \in Sample(8) }
        \cup { [ZeroProductSummary EXCEPT !.dividend = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.subscriptionRight = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.interimDividendRight = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.split = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.quotationSystem = one] : one \in Sample(1) }
        \cup { [ZeroProductSummary EXCEPT !.liquiditySupportPge = one] : one \in Sample(1) }

(***************************************************************************)
(* Price Update: 31 bytes                                                  *)
(***************************************************************************)

PriceUpdate ==
    [ instrumentId     : Sample(4),
      priceUpdateType  : Sample(1),
      priceYtmPresence : Sample(2),
      value            : Sample(8),
      valueBid         : Sample(8),
      valueAsk         : Sample(8) ]

EncodePriceUpdate(message) ==
    message.instrumentId
        \o message.priceUpdateType
        \o message.priceYtmPresence
        \o message.value
        \o message.valueBid
        \o message.valueAsk

DecodePriceUpdate(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET priceUpdateType == ReadBytes(instrumentId.rest, 1) IN IF ~priceUpdateType.ok THEN Fail ELSE
    LET priceYtmPresence == ReadBytes(priceUpdateType.rest, 2) IN IF ~priceYtmPresence.ok THEN Fail ELSE
    LET value == ReadBytes(priceYtmPresence.rest, 8) IN IF ~value.ok THEN Fail ELSE
    LET valueBid == ReadBytes(value.rest, 8) IN IF ~valueBid.ok THEN Fail ELSE
    LET valueAsk == ReadBytes(valueBid.rest, 8) IN IF ~valueAsk.ok THEN Fail ELSE
    Ok([ instrumentId     |-> instrumentId.value,
         priceUpdateType  |-> priceUpdateType.value,
         priceYtmPresence |-> priceYtmPresence.value,
         value            |-> value.value,
         valueBid         |-> valueBid.value,
         valueAsk         |-> valueAsk.value ], valueAsk.rest)

ZeroPriceUpdate ==
    [ instrumentId     |-> [i \in 1 .. 4 |-> 0],
      priceUpdateType  |-> [i \in 1 .. 1 |-> 0],
      priceYtmPresence |-> [i \in 1 .. 2 |-> 0],
      value            |-> [i \in 1 .. 8 |-> 0],
      valueBid         |-> [i \in 1 .. 8 |-> 0],
      valueAsk         |-> [i \in 1 .. 8 |-> 0] ]

(* Price Update at zero, then each field in turn at the values it is checked at *)
CheckedPriceUpdate ==
    { ZeroPriceUpdate }
        \cup { [ZeroPriceUpdate EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdate EXCEPT !.priceUpdateType = one] : one \in Sample(1) }
        \cup { [ZeroPriceUpdate EXCEPT !.priceYtmPresence = one] : one \in Sample(2) }
        \cup { [ZeroPriceUpdate EXCEPT !.value = one] : one \in Sample(8) }
        \cup { [ZeroPriceUpdate EXCEPT !.valueBid = one] : one \in Sample(8) }
        \cup { [ZeroPriceUpdate EXCEPT !.valueAsk = one] : one \in Sample(8) }

(***************************************************************************)
(* News: 890 bytes                                                         *)
(***************************************************************************)

News ==
    [ marketStructureId : Sample(4),
      newsId            : Sample(4),
      title             : Sample(80),
      entryNumber       : Sample(1),
      total             : Sample(1),
      text              : Sample(800) ]

EncodeNews(message) ==
    message.marketStructureId
        \o message.newsId
        \o message.title
        \o message.entryNumber
        \o message.total
        \o message.text

DecodeNews(bytes) ==
    LET marketStructureId == ReadBytes(bytes, 4) IN IF ~marketStructureId.ok THEN Fail ELSE
    LET newsId == ReadBytes(marketStructureId.rest, 4) IN IF ~newsId.ok THEN Fail ELSE
    LET title == ReadBytes(newsId.rest, 80) IN IF ~title.ok THEN Fail ELSE
    LET entryNumber == ReadBytes(title.rest, 1) IN IF ~entryNumber.ok THEN Fail ELSE
    LET total == ReadBytes(entryNumber.rest, 1) IN IF ~total.ok THEN Fail ELSE
    LET text == ReadBytes(total.rest, 800) IN IF ~text.ok THEN Fail ELSE
    Ok([ marketStructureId |-> marketStructureId.value,
         newsId            |-> newsId.value,
         title             |-> title.value,
         entryNumber       |-> entryNumber.value,
         total             |-> total.value,
         text              |-> text.value ], text.rest)

ZeroNews ==
    [ marketStructureId |-> [i \in 1 .. 4 |-> 0],
      newsId            |-> [i \in 1 .. 4 |-> 0],
      title             |-> [i \in 1 .. 80 |-> 0],
      entryNumber       |-> [i \in 1 .. 1 |-> 0],
      total             |-> [i \in 1 .. 1 |-> 0],
      text              |-> [i \in 1 .. 800 |-> 0] ]

(* News at zero, then each field in turn at the values it is checked at *)
CheckedNews ==
    { ZeroNews }
        \cup { [ZeroNews EXCEPT !.marketStructureId = one] : one \in Sample(4) }
        \cup { [ZeroNews EXCEPT !.newsId = one] : one \in Sample(4) }
        \cup { [ZeroNews EXCEPT !.title = one] : one \in Sample(80) }
        \cup { [ZeroNews EXCEPT !.entryNumber = one] : one \in Sample(1) }
        \cup { [ZeroNews EXCEPT !.total = one] : one \in Sample(1) }
        \cup { [ZeroNews EXCEPT !.text = one] : one \in Sample(800) }

(***************************************************************************)
(* Real Time Index: 88 bytes                                               *)
(***************************************************************************)

RealTimeIndex ==
    [ instrumentId                            : Sample(4),
      indexLevelCode                          : Sample(1),
      numOfActiveInstruments                  : Sample(2),
      indIndexOpeningPortfolio                : Sample(8),
      indexValue                              : Sample(8),
      pctChangeIndexValPrevSession            : Sample(8),
      sessionLow                              : Sample(8),
      sessionHigh                             : Sample(8),
      presenceFlagsRealTimeIndexPresenceFlags : Sample(1),
      tradingValue                            : Sample(8),
      indexValueBid                           : Sample(8),
      indexValueAsk                           : Sample(8),
      midSpreadIndex                          : Sample(8),
      differenceCentralSpread                 : Sample(8) ]

EncodeRealTimeIndex(message) ==
    message.instrumentId
        \o message.indexLevelCode
        \o message.numOfActiveInstruments
        \o message.indIndexOpeningPortfolio
        \o message.indexValue
        \o message.pctChangeIndexValPrevSession
        \o message.sessionLow
        \o message.sessionHigh
        \o message.presenceFlagsRealTimeIndexPresenceFlags
        \o message.tradingValue
        \o message.indexValueBid
        \o message.indexValueAsk
        \o message.midSpreadIndex
        \o message.differenceCentralSpread

DecodeRealTimeIndex(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET indexLevelCode == ReadBytes(instrumentId.rest, 1) IN IF ~indexLevelCode.ok THEN Fail ELSE
    LET numOfActiveInstruments == ReadBytes(indexLevelCode.rest, 2) IN IF ~numOfActiveInstruments.ok THEN Fail ELSE
    LET indIndexOpeningPortfolio == ReadBytes(numOfActiveInstruments.rest, 8) IN IF ~indIndexOpeningPortfolio.ok THEN Fail ELSE
    LET indexValue == ReadBytes(indIndexOpeningPortfolio.rest, 8) IN IF ~indexValue.ok THEN Fail ELSE
    LET pctChangeIndexValPrevSession == ReadBytes(indexValue.rest, 8) IN IF ~pctChangeIndexValPrevSession.ok THEN Fail ELSE
    LET sessionLow == ReadBytes(pctChangeIndexValPrevSession.rest, 8) IN IF ~sessionLow.ok THEN Fail ELSE
    LET sessionHigh == ReadBytes(sessionLow.rest, 8) IN IF ~sessionHigh.ok THEN Fail ELSE
    LET presenceFlagsRealTimeIndexPresenceFlags == ReadBytes(sessionHigh.rest, 1) IN IF ~presenceFlagsRealTimeIndexPresenceFlags.ok THEN Fail ELSE
    LET tradingValue == ReadBytes(presenceFlagsRealTimeIndexPresenceFlags.rest, 8) IN IF ~tradingValue.ok THEN Fail ELSE
    LET indexValueBid == ReadBytes(tradingValue.rest, 8) IN IF ~indexValueBid.ok THEN Fail ELSE
    LET indexValueAsk == ReadBytes(indexValueBid.rest, 8) IN IF ~indexValueAsk.ok THEN Fail ELSE
    LET midSpreadIndex == ReadBytes(indexValueAsk.rest, 8) IN IF ~midSpreadIndex.ok THEN Fail ELSE
    LET differenceCentralSpread == ReadBytes(midSpreadIndex.rest, 8) IN IF ~differenceCentralSpread.ok THEN Fail ELSE
    Ok([ instrumentId                            |-> instrumentId.value,
         indexLevelCode                          |-> indexLevelCode.value,
         numOfActiveInstruments                  |-> numOfActiveInstruments.value,
         indIndexOpeningPortfolio                |-> indIndexOpeningPortfolio.value,
         indexValue                              |-> indexValue.value,
         pctChangeIndexValPrevSession            |-> pctChangeIndexValPrevSession.value,
         sessionLow                              |-> sessionLow.value,
         sessionHigh                             |-> sessionHigh.value,
         presenceFlagsRealTimeIndexPresenceFlags |-> presenceFlagsRealTimeIndexPresenceFlags.value,
         tradingValue                            |-> tradingValue.value,
         indexValueBid                           |-> indexValueBid.value,
         indexValueAsk                           |-> indexValueAsk.value,
         midSpreadIndex                          |-> midSpreadIndex.value,
         differenceCentralSpread                 |-> differenceCentralSpread.value ], differenceCentralSpread.rest)

ZeroRealTimeIndex ==
    [ instrumentId                            |-> [i \in 1 .. 4 |-> 0],
      indexLevelCode                          |-> [i \in 1 .. 1 |-> 0],
      numOfActiveInstruments                  |-> [i \in 1 .. 2 |-> 0],
      indIndexOpeningPortfolio                |-> [i \in 1 .. 8 |-> 0],
      indexValue                              |-> [i \in 1 .. 8 |-> 0],
      pctChangeIndexValPrevSession            |-> [i \in 1 .. 8 |-> 0],
      sessionLow                              |-> [i \in 1 .. 8 |-> 0],
      sessionHigh                             |-> [i \in 1 .. 8 |-> 0],
      presenceFlagsRealTimeIndexPresenceFlags |-> [i \in 1 .. 1 |-> 0],
      tradingValue                            |-> [i \in 1 .. 8 |-> 0],
      indexValueBid                           |-> [i \in 1 .. 8 |-> 0],
      indexValueAsk                           |-> [i \in 1 .. 8 |-> 0],
      midSpreadIndex                          |-> [i \in 1 .. 8 |-> 0],
      differenceCentralSpread                 |-> [i \in 1 .. 8 |-> 0] ]

(* Real Time Index at zero, then each field in turn at the values it is checked at *)
CheckedRealTimeIndex ==
    { ZeroRealTimeIndex }
        \cup { [ZeroRealTimeIndex EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndex EXCEPT !.indexLevelCode = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndex EXCEPT !.numOfActiveInstruments = one] : one \in Sample(2) }
        \cup { [ZeroRealTimeIndex EXCEPT !.indIndexOpeningPortfolio = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndex EXCEPT !.indexValue = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndex EXCEPT !.pctChangeIndexValPrevSession = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndex EXCEPT !.sessionLow = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndex EXCEPT !.sessionHigh = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndex EXCEPT !.presenceFlagsRealTimeIndexPresenceFlags = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndex EXCEPT !.tradingValue = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndex EXCEPT !.indexValueBid = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndex EXCEPT !.indexValueAsk = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndex EXCEPT !.midSpreadIndex = one] : one \in Sample(8) }
        \cup { [ZeroRealTimeIndex EXCEPT !.differenceCentralSpread = one] : one \in Sample(8) }

(***************************************************************************)
(* Index Summary: 77 bytes                                                 *)
(***************************************************************************)

IndexSummary ==
    [ instrumentId                           : Sample(4),
      openingIndexValue                      : Sample(8),
      sessionLow                             : Sample(8),
      sessionHigh                            : Sample(8),
      closingIndexValue                      : Sample(8),
      presenceFlagsIndexSummaryPresenceFlags : Sample(1),
      sessionAvg                             : Sample(8),
      pctChangeIndexValPrevSession           : Sample(8),
      pctChangeIndexValPrevYear              : Sample(8),
      closingCapitalisationPortfolio         : Sample(8),
      indIndexOpeningPortfolio               : Sample(8) ]

EncodeIndexSummary(message) ==
    message.instrumentId
        \o message.openingIndexValue
        \o message.sessionLow
        \o message.sessionHigh
        \o message.closingIndexValue
        \o message.presenceFlagsIndexSummaryPresenceFlags
        \o message.sessionAvg
        \o message.pctChangeIndexValPrevSession
        \o message.pctChangeIndexValPrevYear
        \o message.closingCapitalisationPortfolio
        \o message.indIndexOpeningPortfolio

DecodeIndexSummary(bytes) ==
    LET instrumentId == ReadBytes(bytes, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET openingIndexValue == ReadBytes(instrumentId.rest, 8) IN IF ~openingIndexValue.ok THEN Fail ELSE
    LET sessionLow == ReadBytes(openingIndexValue.rest, 8) IN IF ~sessionLow.ok THEN Fail ELSE
    LET sessionHigh == ReadBytes(sessionLow.rest, 8) IN IF ~sessionHigh.ok THEN Fail ELSE
    LET closingIndexValue == ReadBytes(sessionHigh.rest, 8) IN IF ~closingIndexValue.ok THEN Fail ELSE
    LET presenceFlagsIndexSummaryPresenceFlags == ReadBytes(closingIndexValue.rest, 1) IN IF ~presenceFlagsIndexSummaryPresenceFlags.ok THEN Fail ELSE
    LET sessionAvg == ReadBytes(presenceFlagsIndexSummaryPresenceFlags.rest, 8) IN IF ~sessionAvg.ok THEN Fail ELSE
    LET pctChangeIndexValPrevSession == ReadBytes(sessionAvg.rest, 8) IN IF ~pctChangeIndexValPrevSession.ok THEN Fail ELSE
    LET pctChangeIndexValPrevYear == ReadBytes(pctChangeIndexValPrevSession.rest, 8) IN IF ~pctChangeIndexValPrevYear.ok THEN Fail ELSE
    LET closingCapitalisationPortfolio == ReadBytes(pctChangeIndexValPrevYear.rest, 8) IN IF ~closingCapitalisationPortfolio.ok THEN Fail ELSE
    LET indIndexOpeningPortfolio == ReadBytes(closingCapitalisationPortfolio.rest, 8) IN IF ~indIndexOpeningPortfolio.ok THEN Fail ELSE
    Ok([ instrumentId                           |-> instrumentId.value,
         openingIndexValue                      |-> openingIndexValue.value,
         sessionLow                             |-> sessionLow.value,
         sessionHigh                            |-> sessionHigh.value,
         closingIndexValue                      |-> closingIndexValue.value,
         presenceFlagsIndexSummaryPresenceFlags |-> presenceFlagsIndexSummaryPresenceFlags.value,
         sessionAvg                             |-> sessionAvg.value,
         pctChangeIndexValPrevSession           |-> pctChangeIndexValPrevSession.value,
         pctChangeIndexValPrevYear              |-> pctChangeIndexValPrevYear.value,
         closingCapitalisationPortfolio         |-> closingCapitalisationPortfolio.value,
         indIndexOpeningPortfolio               |-> indIndexOpeningPortfolio.value ], indIndexOpeningPortfolio.rest)

ZeroIndexSummary ==
    [ instrumentId                           |-> [i \in 1 .. 4 |-> 0],
      openingIndexValue                      |-> [i \in 1 .. 8 |-> 0],
      sessionLow                             |-> [i \in 1 .. 8 |-> 0],
      sessionHigh                            |-> [i \in 1 .. 8 |-> 0],
      closingIndexValue                      |-> [i \in 1 .. 8 |-> 0],
      presenceFlagsIndexSummaryPresenceFlags |-> [i \in 1 .. 1 |-> 0],
      sessionAvg                             |-> [i \in 1 .. 8 |-> 0],
      pctChangeIndexValPrevSession           |-> [i \in 1 .. 8 |-> 0],
      pctChangeIndexValPrevYear              |-> [i \in 1 .. 8 |-> 0],
      closingCapitalisationPortfolio         |-> [i \in 1 .. 8 |-> 0],
      indIndexOpeningPortfolio               |-> [i \in 1 .. 8 |-> 0] ]

(* Index Summary at zero, then each field in turn at the values it is checked at *)
CheckedIndexSummary ==
    { ZeroIndexSummary }
        \cup { [ZeroIndexSummary EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummary EXCEPT !.openingIndexValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummary EXCEPT !.sessionLow = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummary EXCEPT !.sessionHigh = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummary EXCEPT !.closingIndexValue = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummary EXCEPT !.presenceFlagsIndexSummaryPresenceFlags = one] : one \in Sample(1) }
        \cup { [ZeroIndexSummary EXCEPT !.sessionAvg = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummary EXCEPT !.pctChangeIndexValPrevSession = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummary EXCEPT !.pctChangeIndexValPrevYear = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummary EXCEPT !.closingCapitalisationPortfolio = one] : one \in Sample(8) }
        \cup { [ZeroIndexSummary EXCEPT !.indIndexOpeningPortfolio = one] : one \in Sample(8) }

(***************************************************************************)
(* Trading Session Status: 13 bytes                                        *)
(***************************************************************************)

TradingSessionStatus ==
    [ marketId            : Sample(4),
      marketStructureId   : Sample(4),
      tradingSessionEvent : Sample(1),
      date                : Sample(4) ]

EncodeTradingSessionStatus(message) ==
    message.marketId
        \o message.marketStructureId
        \o message.tradingSessionEvent
        \o message.date

DecodeTradingSessionStatus(bytes) ==
    LET marketId == ReadBytes(bytes, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET marketStructureId == ReadBytes(marketId.rest, 4) IN IF ~marketStructureId.ok THEN Fail ELSE
    LET tradingSessionEvent == ReadBytes(marketStructureId.rest, 1) IN IF ~tradingSessionEvent.ok THEN Fail ELSE
    LET date == ReadBytes(tradingSessionEvent.rest, 4) IN IF ~date.ok THEN Fail ELSE
    Ok([ marketId            |-> marketId.value,
         marketStructureId   |-> marketStructureId.value,
         tradingSessionEvent |-> tradingSessionEvent.value,
         date                |-> date.value ], date.rest)

ZeroTradingSessionStatus ==
    [ marketId            |-> [i \in 1 .. 4 |-> 0],
      marketStructureId   |-> [i \in 1 .. 4 |-> 0],
      tradingSessionEvent |-> [i \in 1 .. 1 |-> 0],
      date                |-> [i \in 1 .. 4 |-> 0] ]

(* Trading Session Status at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionStatus ==
    { ZeroTradingSessionStatus }
        \cup { [ZeroTradingSessionStatus EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatus EXCEPT !.marketStructureId = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatus EXCEPT !.tradingSessionEvent = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatus EXCEPT !.date = one] : one \in Sample(4) }

(***************************************************************************)
(* Test Event: 201 bytes                                                   *)
(***************************************************************************)

TestEvent ==
    [ scenarioName : Sample(200),
      eventType    : Sample(1) ]

EncodeTestEvent(message) ==
    message.scenarioName
        \o message.eventType

DecodeTestEvent(bytes) ==
    LET scenarioName == ReadBytes(bytes, 200) IN IF ~scenarioName.ok THEN Fail ELSE
    LET eventType == ReadBytes(scenarioName.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    Ok([ scenarioName |-> scenarioName.value,
         eventType    |-> eventType.value ], eventType.rest)

ZeroTestEvent ==
    [ scenarioName |-> [i \in 1 .. 200 |-> 0],
      eventType    |-> [i \in 1 .. 1 |-> 0] ]

(* Test Event at zero, then each field in turn at the values it is checked at *)
CheckedTestEvent ==
    { ZeroTestEvent }
        \cup { [ZeroTestEvent EXCEPT !.scenarioName = one] : one \in Sample(200) }
        \cup { [ZeroTestEvent EXCEPT !.eventType = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Add: 30 bytes                                                     *)
(***************************************************************************)

OrderAdd ==
    [ publicOrderId : Sample(8),
      instrumentId  : Sample(4),
      side          : Sample(1),
      price         : Sample(8),
      quantity      : Sample(8),
      mmQuote       : Sample(1) ]

EncodeOrderAdd(message) ==
    message.publicOrderId
        \o message.instrumentId
        \o message.side
        \o message.price
        \o message.quantity
        \o message.mmQuote

DecodeOrderAdd(bytes) ==
    LET publicOrderId == ReadBytes(bytes, 8) IN IF ~publicOrderId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(publicOrderId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET side == ReadBytes(instrumentId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET mmQuote == ReadBytes(quantity.rest, 1) IN IF ~mmQuote.ok THEN Fail ELSE
    Ok([ publicOrderId |-> publicOrderId.value,
         instrumentId  |-> instrumentId.value,
         side          |-> side.value,
         price         |-> price.value,
         quantity      |-> quantity.value,
         mmQuote       |-> mmQuote.value ], mmQuote.rest)

ZeroOrderAdd ==
    [ publicOrderId |-> [i \in 1 .. 8 |-> 0],
      instrumentId  |-> [i \in 1 .. 4 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      quantity      |-> [i \in 1 .. 8 |-> 0],
      mmQuote       |-> [i \in 1 .. 1 |-> 0] ]

(* Order Add at zero, then each field in turn at the values it is checked at *)
CheckedOrderAdd ==
    { ZeroOrderAdd }
        \cup { [ZeroOrderAdd EXCEPT !.publicOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAdd EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAdd EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAdd EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAdd EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderAdd EXCEPT !.mmQuote = one] : one \in Sample(1) }

(***************************************************************************)
(* Encryption Key: 5 bytes                                                 *)
(***************************************************************************)

EncryptionKey ==
    [ id        : Sample(4),
      secretKey : Sample(1) ]

EncodeEncryptionKey(message) ==
    message.id
        \o message.secretKey

DecodeEncryptionKey(bytes) ==
    LET id == ReadBytes(bytes, 4) IN IF ~id.ok THEN Fail ELSE
    LET secretKey == ReadBytes(id.rest, 1) IN IF ~secretKey.ok THEN Fail ELSE
    Ok([ id        |-> id.value,
         secretKey |-> secretKey.value ], secretKey.rest)

ZeroEncryptionKey ==
    [ id        |-> [i \in 1 .. 4 |-> 0],
      secretKey |-> [i \in 1 .. 1 |-> 0] ]

(* Encryption Key at zero, then each field in turn at the values it is checked at *)
CheckedEncryptionKey ==
    { ZeroEncryptionKey }
        \cup { [ZeroEncryptionKey EXCEPT !.id = one] : one \in Sample(4) }
        \cup { [ZeroEncryptionKey EXCEPT !.secretKey = one] : one \in Sample(1) }

(***************************************************************************)
(* Login: 11 bytes                                                         *)
(***************************************************************************)

Login ==
    [ connectionId : Sample(2),
      token        : Sample(8),
      filter       : Sample(1) ]

EncodeLogin(message) ==
    message.connectionId
        \o message.token
        \o message.filter

DecodeLogin(bytes) ==
    LET connectionId == ReadBytes(bytes, 2) IN IF ~connectionId.ok THEN Fail ELSE
    LET token == ReadBytes(connectionId.rest, 8) IN IF ~token.ok THEN Fail ELSE
    LET filter == ReadBytes(token.rest, 1) IN IF ~filter.ok THEN Fail ELSE
    Ok([ connectionId |-> connectionId.value,
         token        |-> token.value,
         filter       |-> filter.value ], filter.rest)

ZeroLogin ==
    [ connectionId |-> [i \in 1 .. 2 |-> 0],
      token        |-> [i \in 1 .. 8 |-> 0],
      filter       |-> [i \in 1 .. 1 |-> 0] ]

(* Login at zero, then each field in turn at the values it is checked at *)
CheckedLogin ==
    { ZeroLogin }
        \cup { [ZeroLogin EXCEPT !.connectionId = one] : one \in Sample(2) }
        \cup { [ZeroLogin EXCEPT !.token = one] : one \in Sample(8) }
        \cup { [ZeroLogin EXCEPT !.filter = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Response: 1 bytes                                                 *)
(***************************************************************************)

LoginResponse ==
    [ result : Sample(1) ]

EncodeLoginResponse(message) ==
    message.result

DecodeLoginResponse(bytes) ==
    LET result == ReadBytes(bytes, 1) IN IF ~result.ok THEN Fail ELSE
    Ok([ result |-> result.value ], result.rest)

ZeroLoginResponse ==
    [ result |-> [i \in 1 .. 1 |-> 0] ]

(* Login Response at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponse ==
    { ZeroLoginResponse }
        \cup { [ZeroLoginResponse EXCEPT !.result = one] : one \in Sample(1) }

(***************************************************************************)
(* End Of Snapshot: 4 bytes                                                *)
(***************************************************************************)

EndOfSnapshot ==
    [ lastSeqNum : Sample(4) ]

EncodeEndOfSnapshot(message) ==
    message.lastSeqNum

DecodeEndOfSnapshot(bytes) ==
    LET lastSeqNum == ReadBytes(bytes, 4) IN IF ~lastSeqNum.ok THEN Fail ELSE
    Ok([ lastSeqNum |-> lastSeqNum.value ], lastSeqNum.rest)

ZeroEndOfSnapshot ==
    [ lastSeqNum |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Snapshot at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSnapshot ==
    { ZeroEndOfSnapshot }
        \cup { [ZeroEndOfSnapshot EXCEPT !.lastSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

WeekPlanCode == 33  \* 0x21
CalendarExceptionCode == 35  \* 0x23
TickTableEntryCode == 32  \* 0x20
CollarTableEntryCode == 108  \* 0x6c
TradingPhaseScheduleEntryCode == 27  \* 0x1b
MarketStructureCode == 275  \* 0x113
CollarGroupCode == 299  \* 0x12b
ExternalUnderlyingCode == 806  \* 0x326
InstrumentCode == 279  \* 0x117
AccruedInterestTableEntryCode == 36  \* 0x24
IndexationTableEntryCode == 37  \* 0x25
IndexParamsCode == 503  \* 0x1f7
IndexPortfolioEntryCode == 502  \* 0x1f6
AuctionSummaryCode == 270  \* 0x10e
AuctionUpdateCode == 268  \* 0x10c
PriceLevelSnapshotCode == 257  \* 0x101
TopPriceLevelUpdateCode == 256  \* 0x100
TradeCode == 38  \* 0x26
PositionReportCode == 801  \* 0x321
InstrumentStatusChangeCode == 26  \* 0x1a
OrderCollarsCode == 272  \* 0x110
TradeCollarsCode == 273  \* 0x111
InstrumentSummaryCode == 671  \* 0x29f
ProductSummaryCode == 672  \* 0x2a0
PriceUpdateCode == 271  \* 0x10f
NewsCode == 517  \* 0x205
RealTimeIndexCode == 500  \* 0x1f4
IndexSummaryCode == 501  \* 0x1f5
TradingSessionStatusCode == 23  \* 0x17
HeartbeatCode == 1  \* 0x01
TestEventCode == 8192  \* 0x2000
OrderAddCode == 9  \* 0x09
EncryptionKeyCode == 24  \* 0x18
LoginCode == 667  \* 0x29b
LoginResponseCode == 668  \* 0x29c
LogoutCode == 669  \* 0x29d
EndOfSnapshotCode == 670  \* 0x29e

Payload ==
    [ tag : {WeekPlanCode}, body : WeekPlan ]
        \cup [ tag : {CalendarExceptionCode}, body : CalendarException ]
        \cup [ tag : {TickTableEntryCode}, body : TickTableEntry ]
        \cup [ tag : {CollarTableEntryCode}, body : CollarTableEntry ]
        \cup [ tag : {TradingPhaseScheduleEntryCode}, body : TradingPhaseScheduleEntry ]
        \cup [ tag : {MarketStructureCode}, body : MarketStructure ]
        \cup [ tag : {CollarGroupCode}, body : CollarGroup ]
        \cup [ tag : {ExternalUnderlyingCode}, body : ExternalUnderlying ]
        \cup [ tag : {InstrumentCode}, body : Instrument ]
        \cup [ tag : {AccruedInterestTableEntryCode}, body : AccruedInterestTableEntry ]
        \cup [ tag : {IndexationTableEntryCode}, body : IndexationTableEntry ]
        \cup [ tag : {IndexParamsCode}, body : IndexParams ]
        \cup [ tag : {IndexPortfolioEntryCode}, body : IndexPortfolioEntry ]
        \cup [ tag : {AuctionSummaryCode}, body : AuctionSummary ]
        \cup [ tag : {AuctionUpdateCode}, body : AuctionUpdate ]
        \cup [ tag : {PriceLevelSnapshotCode}, body : PriceLevelSnapshot ]
        \cup [ tag : {TopPriceLevelUpdateCode}, body : TopPriceLevelUpdate ]
        \cup [ tag : {TradeCode}, body : Trade ]
        \cup [ tag : {PositionReportCode}, body : PositionReport ]
        \cup [ tag : {InstrumentStatusChangeCode}, body : InstrumentStatusChange ]
        \cup [ tag : {OrderCollarsCode}, body : OrderCollars ]
        \cup [ tag : {TradeCollarsCode}, body : TradeCollars ]
        \cup [ tag : {InstrumentSummaryCode}, body : InstrumentSummary ]
        \cup [ tag : {ProductSummaryCode}, body : ProductSummary ]
        \cup [ tag : {PriceUpdateCode}, body : PriceUpdate ]
        \cup [ tag : {NewsCode}, body : News ]
        \cup [ tag : {RealTimeIndexCode}, body : RealTimeIndex ]
        \cup [ tag : {IndexSummaryCode}, body : IndexSummary ]
        \cup [ tag : {TradingSessionStatusCode}, body : TradingSessionStatus ]
        \cup [ tag : {HeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TestEventCode}, body : TestEvent ]
        \cup [ tag : {OrderAddCode}, body : OrderAdd ]
        \cup [ tag : {EncryptionKeyCode}, body : EncryptionKey ]
        \cup [ tag : {LoginCode}, body : Login ]
        \cup [ tag : {LoginResponseCode}, body : LoginResponse ]
        \cup [ tag : {LogoutCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSnapshotCode}, body : EndOfSnapshot ]

EncodePayload(message) ==
    CASE message.tag = WeekPlanCode -> EncodeWeekPlan(message.body)
      [] message.tag = CalendarExceptionCode -> EncodeCalendarException(message.body)
      [] message.tag = TickTableEntryCode -> EncodeTickTableEntry(message.body)
      [] message.tag = CollarTableEntryCode -> EncodeCollarTableEntry(message.body)
      [] message.tag = TradingPhaseScheduleEntryCode -> EncodeTradingPhaseScheduleEntry(message.body)
      [] message.tag = MarketStructureCode -> EncodeMarketStructure(message.body)
      [] message.tag = CollarGroupCode -> EncodeCollarGroup(message.body)
      [] message.tag = ExternalUnderlyingCode -> EncodeExternalUnderlying(message.body)
      [] message.tag = InstrumentCode -> EncodeInstrument(message.body)
      [] message.tag = AccruedInterestTableEntryCode -> EncodeAccruedInterestTableEntry(message.body)
      [] message.tag = IndexationTableEntryCode -> EncodeIndexationTableEntry(message.body)
      [] message.tag = IndexParamsCode -> EncodeIndexParams(message.body)
      [] message.tag = IndexPortfolioEntryCode -> EncodeIndexPortfolioEntry(message.body)
      [] message.tag = AuctionSummaryCode -> EncodeAuctionSummary(message.body)
      [] message.tag = AuctionUpdateCode -> EncodeAuctionUpdate(message.body)
      [] message.tag = PriceLevelSnapshotCode -> EncodePriceLevelSnapshot(message.body)
      [] message.tag = TopPriceLevelUpdateCode -> EncodeTopPriceLevelUpdate(message.body)
      [] message.tag = TradeCode -> EncodeTrade(message.body)
      [] message.tag = PositionReportCode -> EncodePositionReport(message.body)
      [] message.tag = InstrumentStatusChangeCode -> EncodeInstrumentStatusChange(message.body)
      [] message.tag = OrderCollarsCode -> EncodeOrderCollars(message.body)
      [] message.tag = TradeCollarsCode -> EncodeTradeCollars(message.body)
      [] message.tag = InstrumentSummaryCode -> EncodeInstrumentSummary(message.body)
      [] message.tag = ProductSummaryCode -> EncodeProductSummary(message.body)
      [] message.tag = PriceUpdateCode -> EncodePriceUpdate(message.body)
      [] message.tag = NewsCode -> EncodeNews(message.body)
      [] message.tag = RealTimeIndexCode -> EncodeRealTimeIndex(message.body)
      [] message.tag = IndexSummaryCode -> EncodeIndexSummary(message.body)
      [] message.tag = TradingSessionStatusCode -> EncodeTradingSessionStatus(message.body)
      [] message.tag = HeartbeatCode -> << >>
      [] message.tag = TestEventCode -> EncodeTestEvent(message.body)
      [] message.tag = OrderAddCode -> EncodeOrderAdd(message.body)
      [] message.tag = EncryptionKeyCode -> EncodeEncryptionKey(message.body)
      [] message.tag = LoginCode -> EncodeLogin(message.body)
      [] message.tag = LoginResponseCode -> EncodeLoginResponse(message.body)
      [] message.tag = LogoutCode -> << >>
      [] message.tag = EndOfSnapshotCode -> EncodeEndOfSnapshot(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = WeekPlanCode -> DecodeWeekPlan(bytes)
              [] tag = CalendarExceptionCode -> DecodeCalendarException(bytes)
              [] tag = TickTableEntryCode -> DecodeTickTableEntry(bytes)
              [] tag = CollarTableEntryCode -> DecodeCollarTableEntry(bytes)
              [] tag = TradingPhaseScheduleEntryCode -> DecodeTradingPhaseScheduleEntry(bytes)
              [] tag = MarketStructureCode -> DecodeMarketStructure(bytes)
              [] tag = CollarGroupCode -> DecodeCollarGroup(bytes)
              [] tag = ExternalUnderlyingCode -> DecodeExternalUnderlying(bytes)
              [] tag = InstrumentCode -> DecodeInstrument(bytes)
              [] tag = AccruedInterestTableEntryCode -> DecodeAccruedInterestTableEntry(bytes)
              [] tag = IndexationTableEntryCode -> DecodeIndexationTableEntry(bytes)
              [] tag = IndexParamsCode -> DecodeIndexParams(bytes)
              [] tag = IndexPortfolioEntryCode -> DecodeIndexPortfolioEntry(bytes)
              [] tag = AuctionSummaryCode -> DecodeAuctionSummary(bytes)
              [] tag = AuctionUpdateCode -> DecodeAuctionUpdate(bytes)
              [] tag = PriceLevelSnapshotCode -> DecodePriceLevelSnapshot(bytes)
              [] tag = TopPriceLevelUpdateCode -> DecodeTopPriceLevelUpdate(bytes)
              [] tag = TradeCode -> DecodeTrade(bytes)
              [] tag = PositionReportCode -> DecodePositionReport(bytes)
              [] tag = InstrumentStatusChangeCode -> DecodeInstrumentStatusChange(bytes)
              [] tag = OrderCollarsCode -> DecodeOrderCollars(bytes)
              [] tag = TradeCollarsCode -> DecodeTradeCollars(bytes)
              [] tag = InstrumentSummaryCode -> DecodeInstrumentSummary(bytes)
              [] tag = ProductSummaryCode -> DecodeProductSummary(bytes)
              [] tag = PriceUpdateCode -> DecodePriceUpdate(bytes)
              [] tag = NewsCode -> DecodeNews(bytes)
              [] tag = RealTimeIndexCode -> DecodeRealTimeIndex(bytes)
              [] tag = IndexSummaryCode -> DecodeIndexSummary(bytes)
              [] tag = TradingSessionStatusCode -> DecodeTradingSessionStatus(bytes)
              [] tag = HeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = TestEventCode -> DecodeTestEvent(bytes)
              [] tag = OrderAddCode -> DecodeOrderAdd(bytes)
              [] tag = EncryptionKeyCode -> DecodeEncryptionKey(bytes)
              [] tag = LoginCode -> DecodeLogin(bytes)
              [] tag = LoginResponseCode -> DecodeLoginResponse(bytes)
              [] tag = LogoutCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSnapshotCode -> DecodeEndOfSnapshot(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> WeekPlanCode, body |-> ZeroWeekPlan]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> WeekPlanCode, body |-> one] : one \in CheckedWeekPlan }
        \cup { [tag |-> CalendarExceptionCode, body |-> one] : one \in CheckedCalendarException }
        \cup { [tag |-> TickTableEntryCode, body |-> one] : one \in CheckedTickTableEntry }
        \cup { [tag |-> CollarTableEntryCode, body |-> one] : one \in CheckedCollarTableEntry }
        \cup { [tag |-> TradingPhaseScheduleEntryCode, body |-> one] : one \in CheckedTradingPhaseScheduleEntry }
        \cup { [tag |-> MarketStructureCode, body |-> one] : one \in CheckedMarketStructure }
        \cup { [tag |-> CollarGroupCode, body |-> one] : one \in CheckedCollarGroup }
        \cup { [tag |-> ExternalUnderlyingCode, body |-> one] : one \in CheckedExternalUnderlying }
        \cup { [tag |-> InstrumentCode, body |-> one] : one \in CheckedInstrument }
        \cup { [tag |-> AccruedInterestTableEntryCode, body |-> one] : one \in CheckedAccruedInterestTableEntry }
        \cup { [tag |-> IndexationTableEntryCode, body |-> one] : one \in CheckedIndexationTableEntry }
        \cup { [tag |-> IndexParamsCode, body |-> one] : one \in CheckedIndexParams }
        \cup { [tag |-> IndexPortfolioEntryCode, body |-> one] : one \in CheckedIndexPortfolioEntry }
        \cup { [tag |-> AuctionSummaryCode, body |-> one] : one \in CheckedAuctionSummary }
        \cup { [tag |-> AuctionUpdateCode, body |-> one] : one \in CheckedAuctionUpdate }
        \cup { [tag |-> PriceLevelSnapshotCode, body |-> one] : one \in CheckedPriceLevelSnapshot }
        \cup { [tag |-> TopPriceLevelUpdateCode, body |-> one] : one \in CheckedTopPriceLevelUpdate }
        \cup { [tag |-> TradeCode, body |-> one] : one \in CheckedTrade }
        \cup { [tag |-> PositionReportCode, body |-> one] : one \in CheckedPositionReport }
        \cup { [tag |-> InstrumentStatusChangeCode, body |-> one] : one \in CheckedInstrumentStatusChange }
        \cup { [tag |-> OrderCollarsCode, body |-> one] : one \in CheckedOrderCollars }
        \cup { [tag |-> TradeCollarsCode, body |-> one] : one \in CheckedTradeCollars }
        \cup { [tag |-> InstrumentSummaryCode, body |-> one] : one \in CheckedInstrumentSummary }
        \cup { [tag |-> ProductSummaryCode, body |-> one] : one \in CheckedProductSummary }
        \cup { [tag |-> PriceUpdateCode, body |-> one] : one \in CheckedPriceUpdate }
        \cup { [tag |-> NewsCode, body |-> one] : one \in CheckedNews }
        \cup { [tag |-> RealTimeIndexCode, body |-> one] : one \in CheckedRealTimeIndex }
        \cup { [tag |-> IndexSummaryCode, body |-> one] : one \in CheckedIndexSummary }
        \cup { [tag |-> TradingSessionStatusCode, body |-> one] : one \in CheckedTradingSessionStatus }
        \cup { [tag |-> HeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TestEventCode, body |-> one] : one \in CheckedTestEvent }
        \cup { [tag |-> OrderAddCode, body |-> one] : one \in CheckedOrderAdd }
        \cup { [tag |-> EncryptionKeyCode, body |-> one] : one \in CheckedEncryptionKey }
        \cup { [tag |-> LoginCode, body |-> one] : one \in CheckedLogin }
        \cup { [tag |-> LoginResponseCode, body |-> one] : one \in CheckedLoginResponse }
        \cup { [tag |-> LogoutCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSnapshotCode, body |-> one] : one \in CheckedEndOfSnapshot }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ messageLength    : 0 .. 255,
      messageVersion   : Sample(2),
      sequenceNumber   : Sample(4),
      timestamp        : Sample(8),
      sourceTimestamp  : Sample(8),
      isEncrypted      : Sample(1),
      encryptionOffset : Sample(8),
      encryptionKeyId  : Sample(4),
      sessionId        : Sample(2),
      streamId         : Sample(1),
      payload          : Payload ]

EncodeMessage(message) ==
    EncodeUIntLE(message.messageLength, 2)
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.messageVersion
        \o message.sequenceNumber
        \o message.timestamp
        \o message.sourceTimestamp
        \o message.isEncrypted
        \o message.encryptionOffset
        \o message.encryptionKeyId
        \o message.sessionId
        \o message.streamId
        \o EncodePayload(message.payload)

DecodeMessage(bytes) ==
    LET messageLength == ReadUIntLE(bytes, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET messageType == ReadUIntLE(messageLength.rest, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET messageVersion == ReadBytes(messageType.rest, 2) IN IF ~messageVersion.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(messageVersion.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(sequenceNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET sourceTimestamp == ReadBytes(timestamp.rest, 8) IN IF ~sourceTimestamp.ok THEN Fail ELSE
    LET isEncrypted == ReadBytes(sourceTimestamp.rest, 1) IN IF ~isEncrypted.ok THEN Fail ELSE
    LET encryptionOffset == ReadBytes(isEncrypted.rest, 8) IN IF ~encryptionOffset.ok THEN Fail ELSE
    LET encryptionKeyId == ReadBytes(encryptionOffset.rest, 4) IN IF ~encryptionKeyId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(encryptionKeyId.rest, 2) IN IF ~sessionId.ok THEN Fail ELSE
    LET streamId == ReadBytes(sessionId.rest, 1) IN IF ~streamId.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, streamId.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ messageLength    |-> messageLength.value,
         messageVersion   |-> messageVersion.value,
         sequenceNumber   |-> sequenceNumber.value,
         timestamp        |-> timestamp.value,
         sourceTimestamp  |-> sourceTimestamp.value,
         isEncrypted      |-> isEncrypted.value,
         encryptionOffset |-> encryptionOffset.value,
         encryptionKeyId  |-> encryptionKeyId.value,
         sessionId        |-> sessionId.value,
         streamId         |-> streamId.value,
         payload          |-> payload.value ], payload.rest)

ZeroMessage ==
    [ messageLength    |-> 0,
      messageVersion   |-> [i \in 1 .. 2 |-> 0],
      sequenceNumber   |-> [i \in 1 .. 4 |-> 0],
      timestamp        |-> [i \in 1 .. 8 |-> 0],
      sourceTimestamp  |-> [i \in 1 .. 8 |-> 0],
      isEncrypted      |-> [i \in 1 .. 1 |-> 0],
      encryptionOffset |-> [i \in 1 .. 8 |-> 0],
      encryptionKeyId  |-> [i \in 1 .. 4 |-> 0],
      sessionId        |-> [i \in 1 .. 2 |-> 0],
      streamId         |-> [i \in 1 .. 1 |-> 0],
      payload          |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.messageLength = one] : one \in {0, 1, 255} }
        \cup { [ZeroMessage EXCEPT !.messageVersion = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessage EXCEPT !.sourceTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroMessage EXCEPT !.isEncrypted = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.encryptionOffset = one] : one \in Sample(8) }
        \cup { [ZeroMessage EXCEPT !.encryptionKeyId = one] : one \in Sample(4) }
        \cup { [ZeroMessage EXCEPT !.sessionId = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.streamId = one] : one \in Sample(1) }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Message, written one after another *)
RECURSIVE EncodeMessageList(_)
EncodeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessage(Head(messages)) \o EncodeMessageList(Tail(messages))

(* As many Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMessageAll(_)
ReadMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> WeekPlanCode, body |-> ZeroWeekPlan]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CalendarExceptionCode, body |-> ZeroCalendarException]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TickTableEntryCode, body |-> ZeroTickTableEntry]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CollarTableEntryCode, body |-> ZeroCollarTableEntry]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingPhaseScheduleEntryCode, body |-> ZeroTradingPhaseScheduleEntry]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketStructureCode, body |-> ZeroMarketStructure]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CollarGroupCode, body |-> ZeroCollarGroup]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExternalUnderlyingCode, body |-> ZeroExternalUnderlying]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentCode, body |-> ZeroInstrument]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AccruedInterestTableEntryCode, body |-> ZeroAccruedInterestTableEntry]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexationTableEntryCode, body |-> ZeroIndexationTableEntry]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexParamsCode, body |-> ZeroIndexParams]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexPortfolioEntryCode, body |-> ZeroIndexPortfolioEntry]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionSummaryCode, body |-> ZeroAuctionSummary]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionUpdateCode, body |-> ZeroAuctionUpdate]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PriceLevelSnapshotCode, body |-> ZeroPriceLevelSnapshot]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TopPriceLevelUpdateCode, body |-> ZeroTopPriceLevelUpdate]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCode, body |-> ZeroTrade]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PositionReportCode, body |-> ZeroPositionReport]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentStatusChangeCode, body |-> ZeroInstrumentStatusChange]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCollarsCode, body |-> ZeroOrderCollars]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCollarsCode, body |-> ZeroTradeCollars]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentSummaryCode, body |-> ZeroInstrumentSummary]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ProductSummaryCode, body |-> ZeroProductSummary]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PriceUpdateCode, body |-> ZeroPriceUpdate]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewsCode, body |-> ZeroNews]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RealTimeIndexCode, body |-> ZeroRealTimeIndex]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexSummaryCode, body |-> ZeroIndexSummary]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingSessionStatusCode, body |-> ZeroTradingSessionStatus]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TestEventCode, body |-> ZeroTestEvent]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAddCode, body |-> ZeroOrderAdd]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EncryptionKeyCode, body |-> ZeroEncryptionKey]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LoginCode, body |-> ZeroLogin]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LoginResponseCode, body |-> ZeroLoginResponse]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogoutCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSnapshotCode, body |-> ZeroEndOfSnapshot]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ message : SampleLists(OneMessage) ]

EncodePacket(message) ==
    EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET message == ReadMessageAll(bytes) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroPacket ==
    [ message |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
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

(* Every Week Plan decodes back to what was encoded, and leaves nothing over *)
RoundTripWeekPlan ==
    \A message \in CheckedWeekPlan :
        LET read == DecodeWeekPlan(EncodeWeekPlan(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Calendar Exception decodes back to what was encoded, and leaves nothing over *)
RoundTripCalendarException ==
    \A message \in CheckedCalendarException :
        LET read == DecodeCalendarException(EncodeCalendarException(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Table Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripTickTableEntry ==
    \A message \in CheckedTickTableEntry :
        LET read == DecodeTickTableEntry(EncodeTickTableEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Collar Table Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripCollarTableEntry ==
    \A message \in CheckedCollarTableEntry :
        LET read == DecodeCollarTableEntry(EncodeCollarTableEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Phase Schedule Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingPhaseScheduleEntry ==
    \A message \in CheckedTradingPhaseScheduleEntry :
        LET read == DecodeTradingPhaseScheduleEntry(EncodeTradingPhaseScheduleEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Structure decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStructure ==
    \A message \in CheckedMarketStructure :
        LET read == DecodeMarketStructure(EncodeMarketStructure(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Collar Group decodes back to what was encoded, and leaves nothing over *)
RoundTripCollarGroup ==
    \A message \in CheckedCollarGroup :
        LET read == DecodeCollarGroup(EncodeCollarGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every External Underlying decodes back to what was encoded, and leaves nothing over *)
RoundTripExternalUnderlying ==
    \A message \in CheckedExternalUnderlying :
        LET read == DecodeExternalUnderlying(EncodeExternalUnderlying(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrument ==
    \A message \in CheckedInstrument :
        LET read == DecodeInstrument(EncodeInstrument(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Accrued Interest Table Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripAccruedInterestTableEntry ==
    \A message \in CheckedAccruedInterestTableEntry :
        LET read == DecodeAccruedInterestTableEntry(EncodeAccruedInterestTableEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Indexation Table Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexationTableEntry ==
    \A message \in CheckedIndexationTableEntry :
        LET read == DecodeIndexationTableEntry(EncodeIndexationTableEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Product Identification Public Product Identification decodes back to what was encoded, and leaves nothing over *)
RoundTripProductIdentificationPublicProductIdentification ==
    \A message \in CheckedProductIdentificationPublicProductIdentification :
        LET read == DecodeProductIdentificationPublicProductIdentification(EncodeProductIdentificationPublicProductIdentification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Underlying decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexUnderlying ==
    \A message \in CheckedIndexUnderlying :
        LET read == DecodeIndexUnderlying(EncodeIndexUnderlying(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Items decodes back to what was encoded, and leaves nothing over *)
RoundTripItems ==
    \A message \in CheckedItems :
        LET read == DecodeItems(EncodeItems(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Underlyings decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexUnderlyings ==
    \A message \in CheckedIndexUnderlyings :
        LET read == DecodeIndexUnderlyings(EncodeIndexUnderlyings(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Params decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexParams ==
    \A message \in CheckedIndexParams :
        LET read == DecodeIndexParams(EncodeIndexParams(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Public Product Identification decodes back to what was encoded, and leaves nothing over *)
RoundTripPublicProductIdentification ==
    \A message \in CheckedPublicProductIdentification :
        LET read == DecodePublicProductIdentification(EncodePublicProductIdentification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Portfolio Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexPortfolioEntry ==
    \A message \in CheckedIndexPortfolioEntry :
        LET read == DecodeIndexPortfolioEntry(EncodeIndexPortfolioEntry(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Summary decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionSummary ==
    \A message \in CheckedAuctionSummary :
        LET read == DecodeAuctionSummary(EncodeAuctionSummary(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Update decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionUpdate ==
    \A message \in CheckedAuctionUpdate :
        LET read == DecodeAuctionUpdate(EncodeAuctionUpdate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Level decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceLevel ==
    \A message \in CheckedPriceLevel :
        LET read == DecodePriceLevel(EncodePriceLevel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Buy decodes back to what was encoded, and leaves nothing over *)
RoundTripBuy ==
    \A message \in CheckedBuy :
        LET read == DecodeBuy(EncodeBuy(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Level decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceLevel2 ==
    \A message \in CheckedPriceLevel2 :
        LET read == DecodePriceLevel2(EncodePriceLevel2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sell decodes back to what was encoded, and leaves nothing over *)
RoundTripSell ==
    \A message \in CheckedSell :
        LET read == DecodeSell(EncodeSell(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Level Snapshot decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceLevelSnapshot ==
    \A message \in CheckedPriceLevelSnapshot :
        LET read == DecodePriceLevelSnapshot(EncodePriceLevelSnapshot(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Price Level Update decodes back to what was encoded, and leaves nothing over *)
RoundTripTopPriceLevelUpdate ==
    \A message \in CheckedTopPriceLevelUpdate :
        LET read == DecodeTopPriceLevelUpdate(EncodeTopPriceLevelUpdate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Public Product Identification decodes back to what was encoded, and leaves nothing over *)
RoundTripPublicProductIdentification2 ==
    \A message \in CheckedPublicProductIdentification2 :
        LET read == DecodePublicProductIdentification2(EncodePublicProductIdentification2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripTrade ==
    \A message \in CheckedTrade :
        LET read == DecodeTrade(EncodeTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Public Product Identification decodes back to what was encoded, and leaves nothing over *)
RoundTripPublicProductIdentification3 ==
    \A message \in CheckedPublicProductIdentification3 :
        LET read == DecodePublicProductIdentification3(EncodePublicProductIdentification3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Position Report decodes back to what was encoded, and leaves nothing over *)
RoundTripPositionReport ==
    \A message \in CheckedPositionReport :
        LET read == DecodePositionReport(EncodePositionReport(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Status Change decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentStatusChange ==
    \A message \in CheckedInstrumentStatusChange :
        LET read == DecodeInstrumentStatusChange(EncodeInstrumentStatusChange(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Collars decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCollars ==
    \A message \in CheckedOrderCollars :
        LET read == DecodeOrderCollars(EncodeOrderCollars(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Collars decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCollars ==
    \A message \in CheckedTradeCollars :
        LET read == DecodeTradeCollars(EncodeTradeCollars(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Summary decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentSummary ==
    \A message \in CheckedInstrumentSummary :
        LET read == DecodeInstrumentSummary(EncodeInstrumentSummary(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clob Instrument decodes back to what was encoded, and leaves nothing over *)
RoundTripClobInstrument ==
    \A message \in CheckedClobInstrument :
        LET read == DecodeClobInstrument(EncodeClobInstrument(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Instrument decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossInstrument ==
    \A message \in CheckedCrossInstrument :
        LET read == DecodeCrossInstrument(EncodeCrossInstrument(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Block Instrument decodes back to what was encoded, and leaves nothing over *)
RoundTripBlockInstrument ==
    \A message \in CheckedBlockInstrument :
        LET read == DecodeBlockInstrument(EncodeBlockInstrument(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Hybrid Instrument decodes back to what was encoded, and leaves nothing over *)
RoundTripHybridInstrument ==
    \A message \in CheckedHybridInstrument :
        LET read == DecodeHybridInstrument(EncodeHybridInstrument(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Product Summary decodes back to what was encoded, and leaves nothing over *)
RoundTripProductSummary ==
    \A message \in CheckedProductSummary :
        LET read == DecodeProductSummary(EncodeProductSummary(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Update decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceUpdate ==
    \A message \in CheckedPriceUpdate :
        LET read == DecodePriceUpdate(EncodePriceUpdate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every News decodes back to what was encoded, and leaves nothing over *)
RoundTripNews ==
    \A message \in CheckedNews :
        LET read == DecodeNews(EncodeNews(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Real Time Index decodes back to what was encoded, and leaves nothing over *)
RoundTripRealTimeIndex ==
    \A message \in CheckedRealTimeIndex :
        LET read == DecodeRealTimeIndex(EncodeRealTimeIndex(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Summary decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexSummary ==
    \A message \in CheckedIndexSummary :
        LET read == DecodeIndexSummary(EncodeIndexSummary(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Session Status decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingSessionStatus ==
    \A message \in CheckedTradingSessionStatus :
        LET read == DecodeTradingSessionStatus(EncodeTradingSessionStatus(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Test Event decodes back to what was encoded, and leaves nothing over *)
RoundTripTestEvent ==
    \A message \in CheckedTestEvent :
        LET read == DecodeTestEvent(EncodeTestEvent(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Add decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAdd ==
    \A message \in CheckedOrderAdd :
        LET read == DecodeOrderAdd(EncodeOrderAdd(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Encryption Key decodes back to what was encoded, and leaves nothing over *)
RoundTripEncryptionKey ==
    \A message \in CheckedEncryptionKey :
        LET read == DecodeEncryptionKey(EncodeEncryptionKey(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login decodes back to what was encoded, and leaves nothing over *)
RoundTripLogin ==
    \A message \in CheckedLogin :
        LET read == DecodeLogin(EncodeLogin(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Response decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponse ==
    \A message \in CheckedLoginResponse :
        LET read == DecodeLoginResponse(EncodeLoginResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Snapshot decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSnapshot ==
    \A message \in CheckedEndOfSnapshot :
        LET read == DecodeEndOfSnapshot(EncodeEndOfSnapshot(message))
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
