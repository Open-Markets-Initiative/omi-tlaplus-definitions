--------------------- MODULE Turquoise_Analytics_v26_3 ---------------------
(***************************************************************************)
(* London Stock Exchange Analytics v26.3                                   *)
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
(* Note: Allowed Book Types is a bit field set, checked as its 1 byte      *)
(* rather than bit by bit.                                                 *)
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
(* System Event Message: 11 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp   : Sample(8),
      eventCode   : Sample(1),
      sourceVenue : Sample(2) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.eventCode
        \o message.sourceVenue

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(eventCode.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    Ok([ timestamp   |-> timestamp.value,
         eventCode   |-> eventCode.value,
         sourceVenue |-> sourceVenue.value ], sourceVenue.rest)

ZeroSystemEventMessage ==
    [ timestamp   |-> [i \in 1 .. 8 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0],
      sourceVenue |-> [i \in 1 .. 2 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }

(***************************************************************************)
(* Instrument Directory Message: 138 bytes                                 *)
(***************************************************************************)

InstrumentDirectoryMessage ==
    [ timestamp                       : Sample(8),
      instrument                      : Sample(8),
      isin                            : Sample(12),
      allowedBookTypes                : Sample(1),
      sourceVenue                     : Sample(2),
      venueInstrumentId               : Sample(11),
      tickId                          : Sample(2),
      reserved8                       : Sample(8),
      dynamicCircuitBreakerTolerances : Sample(8),
      staticCircuitBreakerTolerances  : Sample(8),
      segment                         : Sample(6),
      reserved12                      : Sample(12),
      securityExchange                : Sample(11),
      currency                        : Sample(3),
      partitionId                     : Sample(1),
      reserved4                       : Sample(4),
      averageDailyTurnoverAdt         : Sample(8),
      secondReserved8                 : Sample(8),
      reserved1                       : Sample(1),
      thirdReserved8                  : Sample(8),
      fourthReserved8                 : Sample(8) ]

EncodeInstrumentDirectoryMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.isin
        \o message.allowedBookTypes
        \o message.sourceVenue
        \o message.venueInstrumentId
        \o message.tickId
        \o message.reserved8
        \o message.dynamicCircuitBreakerTolerances
        \o message.staticCircuitBreakerTolerances
        \o message.segment
        \o message.reserved12
        \o message.securityExchange
        \o message.currency
        \o message.partitionId
        \o message.reserved4
        \o message.averageDailyTurnoverAdt
        \o message.secondReserved8
        \o message.reserved1
        \o message.thirdReserved8
        \o message.fourthReserved8

DecodeInstrumentDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET isin == ReadBytes(instrument.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET allowedBookTypes == ReadBytes(isin.rest, 1) IN IF ~allowedBookTypes.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(allowedBookTypes.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET venueInstrumentId == ReadBytes(sourceVenue.rest, 11) IN IF ~venueInstrumentId.ok THEN Fail ELSE
    LET tickId == ReadBytes(venueInstrumentId.rest, 2) IN IF ~tickId.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(tickId.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET dynamicCircuitBreakerTolerances == ReadBytes(reserved8.rest, 8) IN IF ~dynamicCircuitBreakerTolerances.ok THEN Fail ELSE
    LET staticCircuitBreakerTolerances == ReadBytes(dynamicCircuitBreakerTolerances.rest, 8) IN IF ~staticCircuitBreakerTolerances.ok THEN Fail ELSE
    LET segment == ReadBytes(staticCircuitBreakerTolerances.rest, 6) IN IF ~segment.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(segment.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    LET securityExchange == ReadBytes(reserved12.rest, 11) IN IF ~securityExchange.ok THEN Fail ELSE
    LET currency == ReadBytes(securityExchange.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET partitionId == ReadBytes(currency.rest, 1) IN IF ~partitionId.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(partitionId.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET averageDailyTurnoverAdt == ReadBytes(reserved4.rest, 8) IN IF ~averageDailyTurnoverAdt.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(averageDailyTurnoverAdt.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(secondReserved8.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET thirdReserved8 == ReadBytes(reserved1.rest, 8) IN IF ~thirdReserved8.ok THEN Fail ELSE
    LET fourthReserved8 == ReadBytes(thirdReserved8.rest, 8) IN IF ~fourthReserved8.ok THEN Fail ELSE
    Ok([ timestamp                       |-> timestamp.value,
         instrument                      |-> instrument.value,
         isin                            |-> isin.value,
         allowedBookTypes                |-> allowedBookTypes.value,
         sourceVenue                     |-> sourceVenue.value,
         venueInstrumentId               |-> venueInstrumentId.value,
         tickId                          |-> tickId.value,
         reserved8                       |-> reserved8.value,
         dynamicCircuitBreakerTolerances |-> dynamicCircuitBreakerTolerances.value,
         staticCircuitBreakerTolerances  |-> staticCircuitBreakerTolerances.value,
         segment                         |-> segment.value,
         reserved12                      |-> reserved12.value,
         securityExchange                |-> securityExchange.value,
         currency                        |-> currency.value,
         partitionId                     |-> partitionId.value,
         reserved4                       |-> reserved4.value,
         averageDailyTurnoverAdt         |-> averageDailyTurnoverAdt.value,
         secondReserved8                 |-> secondReserved8.value,
         reserved1                       |-> reserved1.value,
         thirdReserved8                  |-> thirdReserved8.value,
         fourthReserved8                 |-> fourthReserved8.value ], fourthReserved8.rest)

ZeroInstrumentDirectoryMessage ==
    [ timestamp                       |-> [i \in 1 .. 8 |-> 0],
      instrument                      |-> [i \in 1 .. 8 |-> 0],
      isin                            |-> [i \in 1 .. 12 |-> 0],
      allowedBookTypes                |-> [i \in 1 .. 1 |-> 0],
      sourceVenue                     |-> [i \in 1 .. 2 |-> 0],
      venueInstrumentId               |-> [i \in 1 .. 11 |-> 0],
      tickId                          |-> [i \in 1 .. 2 |-> 0],
      reserved8                       |-> [i \in 1 .. 8 |-> 0],
      dynamicCircuitBreakerTolerances |-> [i \in 1 .. 8 |-> 0],
      staticCircuitBreakerTolerances  |-> [i \in 1 .. 8 |-> 0],
      segment                         |-> [i \in 1 .. 6 |-> 0],
      reserved12                      |-> [i \in 1 .. 12 |-> 0],
      securityExchange                |-> [i \in 1 .. 11 |-> 0],
      currency                        |-> [i \in 1 .. 3 |-> 0],
      partitionId                     |-> [i \in 1 .. 1 |-> 0],
      reserved4                       |-> [i \in 1 .. 4 |-> 0],
      averageDailyTurnoverAdt         |-> [i \in 1 .. 8 |-> 0],
      secondReserved8                 |-> [i \in 1 .. 8 |-> 0],
      reserved1                       |-> [i \in 1 .. 1 |-> 0],
      thirdReserved8                  |-> [i \in 1 .. 8 |-> 0],
      fourthReserved8                 |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDirectoryMessage ==
    { ZeroInstrumentDirectoryMessage }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.allowedBookTypes = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.venueInstrumentId = one] : one \in Sample(11) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.tickId = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.dynamicCircuitBreakerTolerances = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.staticCircuitBreakerTolerances = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.segment = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.securityExchange = one] : one \in Sample(11) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.partitionId = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.averageDailyTurnoverAdt = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.thirdReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.fourthReserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Instrument Status Message: 27 bytes                                     *)
(***************************************************************************)

InstrumentStatusMessage ==
    [ timestamp           : Sample(8),
      instrument          : Sample(8),
      sourceVenue         : Sample(2),
      tradingStatus       : Sample(1),
      sessionChangeReason : Sample(1),
      newEndTime          : Sample(6),
      orderBookType       : Sample(1) ]

EncodeInstrumentStatusMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.sourceVenue
        \o message.tradingStatus
        \o message.sessionChangeReason
        \o message.newEndTime
        \o message.orderBookType

DecodeInstrumentStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(instrument.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(sourceVenue.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET sessionChangeReason == ReadBytes(tradingStatus.rest, 1) IN IF ~sessionChangeReason.ok THEN Fail ELSE
    LET newEndTime == ReadBytes(sessionChangeReason.rest, 6) IN IF ~newEndTime.ok THEN Fail ELSE
    LET orderBookType == ReadBytes(newEndTime.rest, 1) IN IF ~orderBookType.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         instrument          |-> instrument.value,
         sourceVenue         |-> sourceVenue.value,
         tradingStatus       |-> tradingStatus.value,
         sessionChangeReason |-> sessionChangeReason.value,
         newEndTime          |-> newEndTime.value,
         orderBookType       |-> orderBookType.value ], orderBookType.rest)

ZeroInstrumentStatusMessage ==
    [ timestamp           |-> [i \in 1 .. 8 |-> 0],
      instrument          |-> [i \in 1 .. 8 |-> 0],
      sourceVenue         |-> [i \in 1 .. 2 |-> 0],
      tradingStatus       |-> [i \in 1 .. 1 |-> 0],
      sessionChangeReason |-> [i \in 1 .. 1 |-> 0],
      newEndTime          |-> [i \in 1 .. 6 |-> 0],
      orderBookType       |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Status Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentStatusMessage ==
    { ZeroInstrumentStatusMessage }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.sessionChangeReason = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.newEndTime = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentStatusMessage EXCEPT !.orderBookType = one] : one \in Sample(1) }

(***************************************************************************)
(* Analytics Message: 106 bytes                                            *)
(***************************************************************************)

AnalyticsMessage ==
    [ timestamp                    : Sample(8),
      instrument                   : Sample(8),
      sourceVenue                  : Sample(2),
      startTime                    : Sample(8),
      endTime                      : Sample(8),
      buyOrderCount                : Sample(4),
      sellOrderCount               : Sample(4),
      buyOrderSize                 : Sample(8),
      sellOrderSize                : Sample(8),
      buyOrderCancellations        : Sample(4),
      sellOrderCancellations       : Sample(4),
      buyLimitOrderCancellations   : Sample(4),
      buyMarketOrderCancellations  : Sample(4),
      sellLimitOrderCancellations  : Sample(4),
      sellMarketOrderCancellations : Sample(4),
      bidAskSpread                 : Sample(8),
      vwapBuy                      : Sample(8),
      vwapSell                     : Sample(8) ]

EncodeAnalyticsMessage(message) ==
    message.timestamp
        \o message.instrument
        \o message.sourceVenue
        \o message.startTime
        \o message.endTime
        \o message.buyOrderCount
        \o message.sellOrderCount
        \o message.buyOrderSize
        \o message.sellOrderSize
        \o message.buyOrderCancellations
        \o message.sellOrderCancellations
        \o message.buyLimitOrderCancellations
        \o message.buyMarketOrderCancellations
        \o message.sellLimitOrderCancellations
        \o message.sellMarketOrderCancellations
        \o message.bidAskSpread
        \o message.vwapBuy
        \o message.vwapSell

DecodeAnalyticsMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrument == ReadBytes(timestamp.rest, 8) IN IF ~instrument.ok THEN Fail ELSE
    LET sourceVenue == ReadBytes(instrument.rest, 2) IN IF ~sourceVenue.ok THEN Fail ELSE
    LET startTime == ReadBytes(sourceVenue.rest, 8) IN IF ~startTime.ok THEN Fail ELSE
    LET endTime == ReadBytes(startTime.rest, 8) IN IF ~endTime.ok THEN Fail ELSE
    LET buyOrderCount == ReadBytes(endTime.rest, 4) IN IF ~buyOrderCount.ok THEN Fail ELSE
    LET sellOrderCount == ReadBytes(buyOrderCount.rest, 4) IN IF ~sellOrderCount.ok THEN Fail ELSE
    LET buyOrderSize == ReadBytes(sellOrderCount.rest, 8) IN IF ~buyOrderSize.ok THEN Fail ELSE
    LET sellOrderSize == ReadBytes(buyOrderSize.rest, 8) IN IF ~sellOrderSize.ok THEN Fail ELSE
    LET buyOrderCancellations == ReadBytes(sellOrderSize.rest, 4) IN IF ~buyOrderCancellations.ok THEN Fail ELSE
    LET sellOrderCancellations == ReadBytes(buyOrderCancellations.rest, 4) IN IF ~sellOrderCancellations.ok THEN Fail ELSE
    LET buyLimitOrderCancellations == ReadBytes(sellOrderCancellations.rest, 4) IN IF ~buyLimitOrderCancellations.ok THEN Fail ELSE
    LET buyMarketOrderCancellations == ReadBytes(buyLimitOrderCancellations.rest, 4) IN IF ~buyMarketOrderCancellations.ok THEN Fail ELSE
    LET sellLimitOrderCancellations == ReadBytes(buyMarketOrderCancellations.rest, 4) IN IF ~sellLimitOrderCancellations.ok THEN Fail ELSE
    LET sellMarketOrderCancellations == ReadBytes(sellLimitOrderCancellations.rest, 4) IN IF ~sellMarketOrderCancellations.ok THEN Fail ELSE
    LET bidAskSpread == ReadBytes(sellMarketOrderCancellations.rest, 8) IN IF ~bidAskSpread.ok THEN Fail ELSE
    LET vwapBuy == ReadBytes(bidAskSpread.rest, 8) IN IF ~vwapBuy.ok THEN Fail ELSE
    LET vwapSell == ReadBytes(vwapBuy.rest, 8) IN IF ~vwapSell.ok THEN Fail ELSE
    Ok([ timestamp                    |-> timestamp.value,
         instrument                   |-> instrument.value,
         sourceVenue                  |-> sourceVenue.value,
         startTime                    |-> startTime.value,
         endTime                      |-> endTime.value,
         buyOrderCount                |-> buyOrderCount.value,
         sellOrderCount               |-> sellOrderCount.value,
         buyOrderSize                 |-> buyOrderSize.value,
         sellOrderSize                |-> sellOrderSize.value,
         buyOrderCancellations        |-> buyOrderCancellations.value,
         sellOrderCancellations       |-> sellOrderCancellations.value,
         buyLimitOrderCancellations   |-> buyLimitOrderCancellations.value,
         buyMarketOrderCancellations  |-> buyMarketOrderCancellations.value,
         sellLimitOrderCancellations  |-> sellLimitOrderCancellations.value,
         sellMarketOrderCancellations |-> sellMarketOrderCancellations.value,
         bidAskSpread                 |-> bidAskSpread.value,
         vwapBuy                      |-> vwapBuy.value,
         vwapSell                     |-> vwapSell.value ], vwapSell.rest)

ZeroAnalyticsMessage ==
    [ timestamp                    |-> [i \in 1 .. 8 |-> 0],
      instrument                   |-> [i \in 1 .. 8 |-> 0],
      sourceVenue                  |-> [i \in 1 .. 2 |-> 0],
      startTime                    |-> [i \in 1 .. 8 |-> 0],
      endTime                      |-> [i \in 1 .. 8 |-> 0],
      buyOrderCount                |-> [i \in 1 .. 4 |-> 0],
      sellOrderCount               |-> [i \in 1 .. 4 |-> 0],
      buyOrderSize                 |-> [i \in 1 .. 8 |-> 0],
      sellOrderSize                |-> [i \in 1 .. 8 |-> 0],
      buyOrderCancellations        |-> [i \in 1 .. 4 |-> 0],
      sellOrderCancellations       |-> [i \in 1 .. 4 |-> 0],
      buyLimitOrderCancellations   |-> [i \in 1 .. 4 |-> 0],
      buyMarketOrderCancellations  |-> [i \in 1 .. 4 |-> 0],
      sellLimitOrderCancellations  |-> [i \in 1 .. 4 |-> 0],
      sellMarketOrderCancellations |-> [i \in 1 .. 4 |-> 0],
      bidAskSpread                 |-> [i \in 1 .. 8 |-> 0],
      vwapBuy                      |-> [i \in 1 .. 8 |-> 0],
      vwapSell                     |-> [i \in 1 .. 8 |-> 0] ]

(* Analytics Message at zero, then each field in turn at the values it is checked at *)
CheckedAnalyticsMessage ==
    { ZeroAnalyticsMessage }
        \cup { [ZeroAnalyticsMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.instrument = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.sourceVenue = one] : one \in Sample(2) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.startTime = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.endTime = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.buyOrderCount = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.sellOrderCount = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.buyOrderSize = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.sellOrderSize = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.buyOrderCancellations = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.sellOrderCancellations = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.buyLimitOrderCancellations = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.buyMarketOrderCancellations = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.sellLimitOrderCancellations = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.sellMarketOrderCancellations = one] : one \in Sample(4) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.bidAskSpread = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.vwapBuy = one] : one \in Sample(8) }
        \cup { [ZeroAnalyticsMessage EXCEPT !.vwapSell = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* 0x53
InstrumentDirectoryMessageCode == 112  \* 0x70
InstrumentStatusMessageCode == 72  \* 0x48
AnalyticsMessageCode == 97  \* 0x61

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {InstrumentDirectoryMessageCode}, body : InstrumentDirectoryMessage ]
        \cup [ tag : {InstrumentStatusMessageCode}, body : InstrumentStatusMessage ]
        \cup [ tag : {AnalyticsMessageCode}, body : AnalyticsMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = InstrumentDirectoryMessageCode -> EncodeInstrumentDirectoryMessage(message.body)
      [] message.tag = InstrumentStatusMessageCode -> EncodeInstrumentStatusMessage(message.body)
      [] message.tag = AnalyticsMessageCode -> EncodeAnalyticsMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = InstrumentDirectoryMessageCode -> DecodeInstrumentDirectoryMessage(bytes)
              [] tag = InstrumentStatusMessageCode -> DecodeInstrumentStatusMessage(bytes)
              [] tag = AnalyticsMessageCode -> DecodeAnalyticsMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> InstrumentDirectoryMessageCode, body |-> one] : one \in CheckedInstrumentDirectoryMessage }
        \cup { [tag |-> InstrumentStatusMessageCode, body |-> one] : one \in CheckedInstrumentStatusMessage }
        \cup { [tag |-> AnalyticsMessageCode, body |-> one] : one \in CheckedAnalyticsMessage }

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
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
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
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentDirectoryMessageCode, body |-> ZeroInstrumentDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentStatusMessageCode, body |-> ZeroInstrumentStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AnalyticsMessageCode, body |-> ZeroAnalyticsMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length          : Sample(2),
      marketDataGroup : Sample(1),
      sequenceNumber  : Sample(4),
      message         : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.marketDataGroup
        \o message.sequenceNumber
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(length.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET marketDataGroup == ReadBytes(messageCount.rest, 1) IN IF ~marketDataGroup.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(marketDataGroup.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET message == ReadMessageList(sequenceNumber.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ length          |-> length.value,
         marketDataGroup |-> marketDataGroup.value,
         sequenceNumber  |-> sequenceNumber.value,
         message         |-> message.value ], message.rest)

ZeroPacket ==
    [ length          |-> [i \in 1 .. 2 |-> 0],
      marketDataGroup |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      message         |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.marketDataGroup = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
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

(* Every Instrument Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDirectoryMessage ==
    \A message \in CheckedInstrumentDirectoryMessage :
        LET read == DecodeInstrumentDirectoryMessage(EncodeInstrumentDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentStatusMessage ==
    \A message \in CheckedInstrumentStatusMessage :
        LET read == DecodeInstrumentStatusMessage(EncodeInstrumentStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Analytics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAnalyticsMessage ==
    \A message \in CheckedAnalyticsMessage :
        LET read == DecodeAnalyticsMessage(EncodeAnalyticsMessage(message))
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
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
