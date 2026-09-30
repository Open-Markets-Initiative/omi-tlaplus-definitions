-------------------- MODULE IexOptions_MarketData_v1_03 --------------------
(***************************************************************************)
(* Investors Exchange Market Data v1.03                                    *)
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
(* Underlying Ref Data Message: 31 bytes                                   *)
(***************************************************************************)

UnderlyingRefDataMessage ==
    [ time             : Sample(8),
      underlyingId     : Sample(4),
      underlyingSymbol : Sample(16),
      exchangeCode     : Sample(1),
      mpvGroup         : Sample(1),
      closeIndicator   : Sample(1) ]

EncodeUnderlyingRefDataMessage(message) ==
    message.time
        \o message.underlyingId
        \o message.underlyingSymbol
        \o message.exchangeCode
        \o message.mpvGroup
        \o message.closeIndicator

DecodeUnderlyingRefDataMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET underlyingId == ReadBytes(time.rest, 4) IN IF ~underlyingId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(underlyingId.rest, 16) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET exchangeCode == ReadBytes(underlyingSymbol.rest, 1) IN IF ~exchangeCode.ok THEN Fail ELSE
    LET mpvGroup == ReadBytes(exchangeCode.rest, 1) IN IF ~mpvGroup.ok THEN Fail ELSE
    LET closeIndicator == ReadBytes(mpvGroup.rest, 1) IN IF ~closeIndicator.ok THEN Fail ELSE
    Ok([ time             |-> time.value,
         underlyingId     |-> underlyingId.value,
         underlyingSymbol |-> underlyingSymbol.value,
         exchangeCode     |-> exchangeCode.value,
         mpvGroup         |-> mpvGroup.value,
         closeIndicator   |-> closeIndicator.value ], closeIndicator.rest)

ZeroUnderlyingRefDataMessage ==
    [ time             |-> [i \in 1 .. 8 |-> 0],
      underlyingId     |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 16 |-> 0],
      exchangeCode     |-> [i \in 1 .. 1 |-> 0],
      mpvGroup         |-> [i \in 1 .. 1 |-> 0],
      closeIndicator   |-> [i \in 1 .. 1 |-> 0] ]

(* Underlying Ref Data Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingRefDataMessage ==
    { ZeroUnderlyingRefDataMessage }
        \cup { [ZeroUnderlyingRefDataMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroUnderlyingRefDataMessage EXCEPT !.underlyingId = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingRefDataMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(16) }
        \cup { [ZeroUnderlyingRefDataMessage EXCEPT !.exchangeCode = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingRefDataMessage EXCEPT !.mpvGroup = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingRefDataMessage EXCEPT !.closeIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol Mapping Message: 68 bytes                                        *)
(***************************************************************************)

SymbolMappingMessage ==
    [ time              : Sample(8),
      instrumentId      : Sample(4),
      osiSymbol         : Sample(32),
      tradingRing       : Sample(1),
      closingOnlySeries : Sample(1),
      underlyingId      : Sample(4),
      maturityDate      : Sample(8),
      optionType        : Sample(1),
      strikePrice       : Sample(8),
      orpEnablement     : Sample(1) ]

EncodeSymbolMappingMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.osiSymbol
        \o message.tradingRing
        \o message.closingOnlySeries
        \o message.underlyingId
        \o message.maturityDate
        \o message.optionType
        \o message.strikePrice
        \o message.orpEnablement

DecodeSymbolMappingMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET osiSymbol == ReadBytes(instrumentId.rest, 32) IN IF ~osiSymbol.ok THEN Fail ELSE
    LET tradingRing == ReadBytes(osiSymbol.rest, 1) IN IF ~tradingRing.ok THEN Fail ELSE
    LET closingOnlySeries == ReadBytes(tradingRing.rest, 1) IN IF ~closingOnlySeries.ok THEN Fail ELSE
    LET underlyingId == ReadBytes(closingOnlySeries.rest, 4) IN IF ~underlyingId.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(underlyingId.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET optionType == ReadBytes(maturityDate.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(optionType.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET orpEnablement == ReadBytes(strikePrice.rest, 1) IN IF ~orpEnablement.ok THEN Fail ELSE
    Ok([ time              |-> time.value,
         instrumentId      |-> instrumentId.value,
         osiSymbol         |-> osiSymbol.value,
         tradingRing       |-> tradingRing.value,
         closingOnlySeries |-> closingOnlySeries.value,
         underlyingId      |-> underlyingId.value,
         maturityDate      |-> maturityDate.value,
         optionType        |-> optionType.value,
         strikePrice       |-> strikePrice.value,
         orpEnablement     |-> orpEnablement.value ], orpEnablement.rest)

ZeroSymbolMappingMessage ==
    [ time              |-> [i \in 1 .. 8 |-> 0],
      instrumentId      |-> [i \in 1 .. 4 |-> 0],
      osiSymbol         |-> [i \in 1 .. 32 |-> 0],
      tradingRing       |-> [i \in 1 .. 1 |-> 0],
      closingOnlySeries |-> [i \in 1 .. 1 |-> 0],
      underlyingId      |-> [i \in 1 .. 4 |-> 0],
      maturityDate      |-> [i \in 1 .. 8 |-> 0],
      optionType        |-> [i \in 1 .. 1 |-> 0],
      strikePrice       |-> [i \in 1 .. 8 |-> 0],
      orpEnablement     |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolMappingMessage ==
    { ZeroSymbolMappingMessage }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.osiSymbol = one] : one \in Sample(32) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.tradingRing = one] : one \in Sample(1) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.closingOnlySeries = one] : one \in Sample(1) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.underlyingId = one] : one \in Sample(4) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.orpEnablement = one] : one \in Sample(1) }

(***************************************************************************)
(* Instrument Clear Message: 12 bytes                                      *)
(***************************************************************************)

InstrumentClearMessage ==
    [ time         : Sample(8),
      instrumentId : Sample(4) ]

EncodeInstrumentClearMessage(message) ==
    message.time
        \o message.instrumentId

DecodeInstrumentClearMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    Ok([ time         |-> time.value,
         instrumentId |-> instrumentId.value ], instrumentId.rest)

ZeroInstrumentClearMessage ==
    [ time         |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0] ]

(* Instrument Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentClearMessage ==
    { ZeroInstrumentClearMessage }
        \cup { [ZeroInstrumentClearMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentClearMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }

(***************************************************************************)
(* Trading Status Message: 13 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ time          : Sample(8),
      instrumentId  : Sample(4),
      tradingStatus : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.tradingStatus

DecodeTradingStatusMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(instrumentId.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    Ok([ time          |-> time.value,
         instrumentId  |-> instrumentId.value,
         tradingStatus |-> tradingStatus.value ], tradingStatus.rest)

ZeroTradingStatusMessage ==
    [ time          |-> [i \in 1 .. 8 |-> 0],
      instrumentId  |-> [i \in 1 .. 4 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Options Auction Summary Message: 25 bytes                               *)
(***************************************************************************)

OptionsAuctionSummaryMessage ==
    [ time               : Sample(8),
      instrumentId       : Sample(4),
      auctionSummaryType : Sample(1),
      price              : Sample(8),
      contracts          : Sample(4) ]

EncodeOptionsAuctionSummaryMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.auctionSummaryType
        \o message.price
        \o message.contracts

DecodeOptionsAuctionSummaryMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET auctionSummaryType == ReadBytes(instrumentId.rest, 1) IN IF ~auctionSummaryType.ok THEN Fail ELSE
    LET price == ReadBytes(auctionSummaryType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET contracts == ReadBytes(price.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    Ok([ time               |-> time.value,
         instrumentId       |-> instrumentId.value,
         auctionSummaryType |-> auctionSummaryType.value,
         price              |-> price.value,
         contracts          |-> contracts.value ], contracts.rest)

ZeroOptionsAuctionSummaryMessage ==
    [ time               |-> [i \in 1 .. 8 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      auctionSummaryType |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      contracts          |-> [i \in 1 .. 4 |-> 0] ]

(* Options Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsAuctionSummaryMessage ==
    { ZeroOptionsAuctionSummaryMessage }
        \cup { [ZeroOptionsAuctionSummaryMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionSummaryMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsAuctionSummaryMessage EXCEPT !.auctionSummaryType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsAuctionSummaryMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionSummaryMessage EXCEPT !.contracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Options Auction Width Update Message: 13 bytes                          *)
(***************************************************************************)

OptionsAuctionWidthUpdateMessage ==
    [ time                  : Sample(8),
      underlyingId          : Sample(4),
      quoteReliefMultiplier : Sample(1) ]

EncodeOptionsAuctionWidthUpdateMessage(message) ==
    message.time
        \o message.underlyingId
        \o message.quoteReliefMultiplier

DecodeOptionsAuctionWidthUpdateMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET underlyingId == ReadBytes(time.rest, 4) IN IF ~underlyingId.ok THEN Fail ELSE
    LET quoteReliefMultiplier == ReadBytes(underlyingId.rest, 1) IN IF ~quoteReliefMultiplier.ok THEN Fail ELSE
    Ok([ time                  |-> time.value,
         underlyingId          |-> underlyingId.value,
         quoteReliefMultiplier |-> quoteReliefMultiplier.value ], quoteReliefMultiplier.rest)

ZeroOptionsAuctionWidthUpdateMessage ==
    [ time                  |-> [i \in 1 .. 8 |-> 0],
      underlyingId          |-> [i \in 1 .. 4 |-> 0],
      quoteReliefMultiplier |-> [i \in 1 .. 1 |-> 0] ]

(* Options Auction Width Update Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsAuctionWidthUpdateMessage ==
    { ZeroOptionsAuctionWidthUpdateMessage }
        \cup { [ZeroOptionsAuctionWidthUpdateMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroOptionsAuctionWidthUpdateMessage EXCEPT !.underlyingId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsAuctionWidthUpdateMessage EXCEPT !.quoteReliefMultiplier = one] : one \in Sample(1) }

(***************************************************************************)
(* Liquidity Event Notification Message: 39 bytes                          *)
(***************************************************************************)

LiquidityEventNotificationMessage ==
    [ time               : Sample(8),
      instrumentId       : Sample(4),
      eventId            : Sample(4),
      liquidityEventType : Sample(1),
      side               : Sample(1),
      price              : Sample(8),
      contracts          : Sample(4),
      capacity           : Sample(1),
      participantId      : Sample(4),
      eventEndOffset     : Sample(4) ]

EncodeLiquidityEventNotificationMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.eventId
        \o message.liquidityEventType
        \o message.side
        \o message.price
        \o message.contracts
        \o message.capacity
        \o message.participantId
        \o message.eventEndOffset

DecodeLiquidityEventNotificationMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET eventId == ReadBytes(instrumentId.rest, 4) IN IF ~eventId.ok THEN Fail ELSE
    LET liquidityEventType == ReadBytes(eventId.rest, 1) IN IF ~liquidityEventType.ok THEN Fail ELSE
    LET side == ReadBytes(liquidityEventType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET contracts == ReadBytes(price.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET capacity == ReadBytes(contracts.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET participantId == ReadBytes(capacity.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET eventEndOffset == ReadBytes(participantId.rest, 4) IN IF ~eventEndOffset.ok THEN Fail ELSE
    Ok([ time               |-> time.value,
         instrumentId       |-> instrumentId.value,
         eventId            |-> eventId.value,
         liquidityEventType |-> liquidityEventType.value,
         side               |-> side.value,
         price              |-> price.value,
         contracts          |-> contracts.value,
         capacity           |-> capacity.value,
         participantId      |-> participantId.value,
         eventEndOffset     |-> eventEndOffset.value ], eventEndOffset.rest)

ZeroLiquidityEventNotificationMessage ==
    [ time               |-> [i \in 1 .. 8 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      eventId            |-> [i \in 1 .. 4 |-> 0],
      liquidityEventType |-> [i \in 1 .. 1 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      contracts          |-> [i \in 1 .. 4 |-> 0],
      capacity           |-> [i \in 1 .. 1 |-> 0],
      participantId      |-> [i \in 1 .. 4 |-> 0],
      eventEndOffset     |-> [i \in 1 .. 4 |-> 0] ]

(* Liquidity Event Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityEventNotificationMessage ==
    { ZeroLiquidityEventNotificationMessage }
        \cup { [ZeroLiquidityEventNotificationMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroLiquidityEventNotificationMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityEventNotificationMessage EXCEPT !.eventId = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityEventNotificationMessage EXCEPT !.liquidityEventType = one] : one \in Sample(1) }
        \cup { [ZeroLiquidityEventNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroLiquidityEventNotificationMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroLiquidityEventNotificationMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityEventNotificationMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroLiquidityEventNotificationMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityEventNotificationMessage EXCEPT !.eventEndOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Liquidity Event Execution Message: 36 bytes                             *)
(***************************************************************************)

LiquidityEventExecutionMessage ==
    [ time         : Sample(8),
      instrumentId : Sample(4),
      eventId      : Sample(4),
      tradeId      : Sample(8),
      price        : Sample(8),
      contracts    : Sample(4) ]

EncodeLiquidityEventExecutionMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.eventId
        \o message.tradeId
        \o message.price
        \o message.contracts

DecodeLiquidityEventExecutionMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET eventId == ReadBytes(instrumentId.rest, 4) IN IF ~eventId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(eventId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET contracts == ReadBytes(price.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    Ok([ time         |-> time.value,
         instrumentId |-> instrumentId.value,
         eventId      |-> eventId.value,
         tradeId      |-> tradeId.value,
         price        |-> price.value,
         contracts    |-> contracts.value ], contracts.rest)

ZeroLiquidityEventExecutionMessage ==
    [ time         |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      eventId      |-> [i \in 1 .. 4 |-> 0],
      tradeId      |-> [i \in 1 .. 8 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      contracts    |-> [i \in 1 .. 4 |-> 0] ]

(* Liquidity Event Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityEventExecutionMessage ==
    { ZeroLiquidityEventExecutionMessage }
        \cup { [ZeroLiquidityEventExecutionMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroLiquidityEventExecutionMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityEventExecutionMessage EXCEPT !.eventId = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityEventExecutionMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroLiquidityEventExecutionMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroLiquidityEventExecutionMessage EXCEPT !.contracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Liquidity Event Cancel Message: 16 bytes                                *)
(***************************************************************************)

LiquidityEventCancelMessage ==
    [ time         : Sample(8),
      instrumentId : Sample(4),
      eventId      : Sample(4) ]

EncodeLiquidityEventCancelMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.eventId

DecodeLiquidityEventCancelMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET eventId == ReadBytes(instrumentId.rest, 4) IN IF ~eventId.ok THEN Fail ELSE
    Ok([ time         |-> time.value,
         instrumentId |-> instrumentId.value,
         eventId      |-> eventId.value ], eventId.rest)

ZeroLiquidityEventCancelMessage ==
    [ time         |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      eventId      |-> [i \in 1 .. 4 |-> 0] ]

(* Liquidity Event Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityEventCancelMessage ==
    { ZeroLiquidityEventCancelMessage }
        \cup { [ZeroLiquidityEventCancelMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroLiquidityEventCancelMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityEventCancelMessage EXCEPT !.eventId = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order Non Customer Message: 33 bytes                                *)
(***************************************************************************)

AddOrderNonCustomerMessage ==
    [ time         : Sample(8),
      instrumentId : Sample(4),
      orderId      : Sample(8),
      side         : Sample(1),
      price        : Sample(8),
      contracts    : Sample(4) ]

EncodeAddOrderNonCustomerMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.orderId
        \o message.side
        \o message.price
        \o message.contracts

DecodeAddOrderNonCustomerMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET contracts == ReadBytes(price.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    Ok([ time         |-> time.value,
         instrumentId |-> instrumentId.value,
         orderId      |-> orderId.value,
         side         |-> side.value,
         price        |-> price.value,
         contracts    |-> contracts.value ], contracts.rest)

ZeroAddOrderNonCustomerMessage ==
    [ time         |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      contracts    |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Non Customer Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderNonCustomerMessage ==
    { ZeroAddOrderNonCustomerMessage }
        \cup { [ZeroAddOrderNonCustomerMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderNonCustomerMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNonCustomerMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderNonCustomerMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderNonCustomerMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderNonCustomerMessage EXCEPT !.contracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order Customer Message: 34 bytes                                    *)
(***************************************************************************)

AddOrderCustomerMessage ==
    [ time              : Sample(8),
      instrumentId      : Sample(4),
      orderId           : Sample(8),
      side              : Sample(1),
      price             : Sample(8),
      contracts         : Sample(4),
      customerIndicator : Sample(1) ]

EncodeAddOrderCustomerMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.orderId
        \o message.side
        \o message.price
        \o message.contracts
        \o message.customerIndicator

DecodeAddOrderCustomerMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET contracts == ReadBytes(price.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(contracts.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    Ok([ time              |-> time.value,
         instrumentId      |-> instrumentId.value,
         orderId           |-> orderId.value,
         side              |-> side.value,
         price             |-> price.value,
         contracts         |-> contracts.value,
         customerIndicator |-> customerIndicator.value ], customerIndicator.rest)

ZeroAddOrderCustomerMessage ==
    [ time              |-> [i \in 1 .. 8 |-> 0],
      instrumentId      |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      contracts         |-> [i \in 1 .. 4 |-> 0],
      customerIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order Customer Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderCustomerMessage ==
    { ZeroAddOrderCustomerMessage }
        \cup { [ZeroAddOrderCustomerMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderCustomerMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderCustomerMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderCustomerMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderCustomerMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderCustomerMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderCustomerMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Modify Order Message: 33 bytes                                          *)
(***************************************************************************)

ModifyOrderMessage ==
    [ time         : Sample(8),
      instrumentId : Sample(4),
      orderId      : Sample(8),
      price        : Sample(8),
      contracts    : Sample(4),
      modFlag      : Sample(1) ]

EncodeModifyOrderMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.orderId
        \o message.price
        \o message.contracts
        \o message.modFlag

DecodeModifyOrderMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET price == ReadBytes(orderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET contracts == ReadBytes(price.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET modFlag == ReadBytes(contracts.rest, 1) IN IF ~modFlag.ok THEN Fail ELSE
    Ok([ time         |-> time.value,
         instrumentId |-> instrumentId.value,
         orderId      |-> orderId.value,
         price        |-> price.value,
         contracts    |-> contracts.value,
         modFlag      |-> modFlag.value ], modFlag.rest)

ZeroModifyOrderMessage ==
    [ time         |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      contracts    |-> [i \in 1 .. 4 |-> 0],
      modFlag      |-> [i \in 1 .. 1 |-> 0] ]

(* Modify Order Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyOrderMessage ==
    { ZeroModifyOrderMessage }
        \cup { [ZeroModifyOrderMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroModifyOrderMessage EXCEPT !.modFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Delete Order Message: 20 bytes                                          *)
(***************************************************************************)

DeleteOrderMessage ==
    [ time         : Sample(8),
      instrumentId : Sample(4),
      orderId      : Sample(8) ]

EncodeDeleteOrderMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.orderId

DecodeDeleteOrderMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ time         |-> time.value,
         instrumentId |-> instrumentId.value,
         orderId      |-> orderId.value ], orderId.rest)

ZeroDeleteOrderMessage ==
    [ time         |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0] ]

(* Delete Order Message at zero, then each field in turn at the values it is checked at *)
CheckedDeleteOrderMessage ==
    { ZeroDeleteOrderMessage }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroDeleteOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Execution Message: 45 bytes                                       *)
(***************************************************************************)

OrderExecutionMessage ==
    [ time               : Sample(8),
      instrumentId       : Sample(4),
      orderId            : Sample(8),
      tradeId            : Sample(8),
      price              : Sample(8),
      executedContracts  : Sample(4),
      remainingContracts : Sample(4),
      tradeCondition     : Sample(1) ]

EncodeOrderExecutionMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.orderId
        \o message.tradeId
        \o message.price
        \o message.executedContracts
        \o message.remainingContracts
        \o message.tradeCondition

DecodeOrderExecutionMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(orderId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET executedContracts == ReadBytes(price.rest, 4) IN IF ~executedContracts.ok THEN Fail ELSE
    LET remainingContracts == ReadBytes(executedContracts.rest, 4) IN IF ~remainingContracts.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(remainingContracts.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ time               |-> time.value,
         instrumentId       |-> instrumentId.value,
         orderId            |-> orderId.value,
         tradeId            |-> tradeId.value,
         price              |-> price.value,
         executedContracts  |-> executedContracts.value,
         remainingContracts |-> remainingContracts.value,
         tradeCondition     |-> tradeCondition.value ], tradeCondition.rest)

ZeroOrderExecutionMessage ==
    [ time               |-> [i \in 1 .. 8 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      tradeId            |-> [i \in 1 .. 8 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      executedContracts  |-> [i \in 1 .. 4 |-> 0],
      remainingContracts |-> [i \in 1 .. 4 |-> 0],
      tradeCondition     |-> [i \in 1 .. 1 |-> 0] ]

(* Order Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutionMessage ==
    { ZeroOrderExecutionMessage }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.executedContracts = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.remainingContracts = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutionMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Deep Trade Break Message: 20 bytes                                      *)
(***************************************************************************)

DeepTradeBreakMessage ==
    [ time         : Sample(8),
      instrumentId : Sample(4),
      tradeId      : Sample(8) ]

EncodeDeepTradeBreakMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.tradeId

DecodeDeepTradeBreakMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(instrumentId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    Ok([ time         |-> time.value,
         instrumentId |-> instrumentId.value,
         tradeId      |-> tradeId.value ], tradeId.rest)

ZeroDeepTradeBreakMessage ==
    [ time         |-> [i \in 1 .. 8 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      tradeId      |-> [i \in 1 .. 8 |-> 0] ]

(* Deep Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedDeepTradeBreakMessage ==
    { ZeroDeepTradeBreakMessage }
        \cup { [ZeroDeepTradeBreakMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroDeepTradeBreakMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroDeepTradeBreakMessage EXCEPT !.tradeId = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Update No Customer Interest Message: 37 bytes                     *)
(***************************************************************************)

QuoteUpdateNoCustomerInterestMessage ==
    [ time             : Sample(8),
      instrumentId     : Sample(4),
      bidSize          : Sample(4),
      bidPrice         : Sample(8),
      askSize          : Sample(4),
      askPrice         : Sample(8),
      statusStatusType : Sample(1) ]

EncodeQuoteUpdateNoCustomerInterestMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.bidSize
        \o message.bidPrice
        \o message.askSize
        \o message.askPrice
        \o message.statusStatusType

DecodeQuoteUpdateNoCustomerInterestMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidSize == ReadBytes(instrumentId.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(bidSize.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(bidPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(askSize.rest, 8) IN IF ~askPrice.ok THEN Fail ELSE
    LET statusStatusType == ReadBytes(askPrice.rest, 1) IN IF ~statusStatusType.ok THEN Fail ELSE
    Ok([ time             |-> time.value,
         instrumentId     |-> instrumentId.value,
         bidSize          |-> bidSize.value,
         bidPrice         |-> bidPrice.value,
         askSize          |-> askSize.value,
         askPrice         |-> askPrice.value,
         statusStatusType |-> statusStatusType.value ], statusStatusType.rest)

ZeroQuoteUpdateNoCustomerInterestMessage ==
    [ time             |-> [i \in 1 .. 8 |-> 0],
      instrumentId     |-> [i \in 1 .. 4 |-> 0],
      bidSize          |-> [i \in 1 .. 4 |-> 0],
      bidPrice         |-> [i \in 1 .. 8 |-> 0],
      askSize          |-> [i \in 1 .. 4 |-> 0],
      askPrice         |-> [i \in 1 .. 8 |-> 0],
      statusStatusType |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Update No Customer Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateNoCustomerInterestMessage ==
    { ZeroQuoteUpdateNoCustomerInterestMessage }
        \cup { [ZeroQuoteUpdateNoCustomerInterestMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateNoCustomerInterestMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateNoCustomerInterestMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateNoCustomerInterestMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateNoCustomerInterestMessage EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateNoCustomerInterestMessage EXCEPT !.askPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateNoCustomerInterestMessage EXCEPT !.statusStatusType = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Update Customer Interest Message: 45 bytes                        *)
(***************************************************************************)

QuoteUpdateCustomerInterestMessage ==
    [ time             : Sample(8),
      instrumentId     : Sample(4),
      bidSize          : Sample(4),
      bidCustomerSize  : Sample(4),
      bidPrice         : Sample(8),
      askSize          : Sample(4),
      askCustomerSize  : Sample(4),
      askPrice         : Sample(8),
      statusStatusType : Sample(1) ]

EncodeQuoteUpdateCustomerInterestMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.bidSize
        \o message.bidCustomerSize
        \o message.bidPrice
        \o message.askSize
        \o message.askCustomerSize
        \o message.askPrice
        \o message.statusStatusType

DecodeQuoteUpdateCustomerInterestMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidSize == ReadBytes(instrumentId.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidCustomerSize == ReadBytes(bidSize.rest, 4) IN IF ~bidCustomerSize.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(bidCustomerSize.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(bidPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET askCustomerSize == ReadBytes(askSize.rest, 4) IN IF ~askCustomerSize.ok THEN Fail ELSE
    LET askPrice == ReadBytes(askCustomerSize.rest, 8) IN IF ~askPrice.ok THEN Fail ELSE
    LET statusStatusType == ReadBytes(askPrice.rest, 1) IN IF ~statusStatusType.ok THEN Fail ELSE
    Ok([ time             |-> time.value,
         instrumentId     |-> instrumentId.value,
         bidSize          |-> bidSize.value,
         bidCustomerSize  |-> bidCustomerSize.value,
         bidPrice         |-> bidPrice.value,
         askSize          |-> askSize.value,
         askCustomerSize  |-> askCustomerSize.value,
         askPrice         |-> askPrice.value,
         statusStatusType |-> statusStatusType.value ], statusStatusType.rest)

ZeroQuoteUpdateCustomerInterestMessage ==
    [ time             |-> [i \in 1 .. 8 |-> 0],
      instrumentId     |-> [i \in 1 .. 4 |-> 0],
      bidSize          |-> [i \in 1 .. 4 |-> 0],
      bidCustomerSize  |-> [i \in 1 .. 4 |-> 0],
      bidPrice         |-> [i \in 1 .. 8 |-> 0],
      askSize          |-> [i \in 1 .. 4 |-> 0],
      askCustomerSize  |-> [i \in 1 .. 4 |-> 0],
      askPrice         |-> [i \in 1 .. 8 |-> 0],
      statusStatusType |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Update Customer Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteUpdateCustomerInterestMessage ==
    { ZeroQuoteUpdateCustomerInterestMessage }
        \cup { [ZeroQuoteUpdateCustomerInterestMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateCustomerInterestMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateCustomerInterestMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateCustomerInterestMessage EXCEPT !.bidCustomerSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateCustomerInterestMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateCustomerInterestMessage EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateCustomerInterestMessage EXCEPT !.askCustomerSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteUpdateCustomerInterestMessage EXCEPT !.askPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteUpdateCustomerInterestMessage EXCEPT !.statusStatusType = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Message: 33 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ time           : Sample(8),
      instrumentId   : Sample(4),
      tradeId        : Sample(8),
      price          : Sample(8),
      contracts      : Sample(4),
      tradeCondition : Sample(1) ]

EncodeTradeMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.tradeId
        \o message.price
        \o message.contracts
        \o message.tradeCondition

DecodeTradeMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(instrumentId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET contracts == ReadBytes(price.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(contracts.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ time           |-> time.value,
         instrumentId   |-> instrumentId.value,
         tradeId        |-> tradeId.value,
         price          |-> price.value,
         contracts      |-> contracts.value,
         tradeCondition |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeMessage ==
    [ time           |-> [i \in 1 .. 8 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      tradeId        |-> [i \in 1 .. 8 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      contracts      |-> [i \in 1 .. 4 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Correction Message: 41 bytes                                      *)
(***************************************************************************)

TradeCorrectionMessage ==
    [ time            : Sample(8),
      instrumentId    : Sample(4),
      originalTradeId : Sample(8),
      tradeId         : Sample(8),
      price           : Sample(8),
      contracts       : Sample(4),
      tradeCondition  : Sample(1) ]

EncodeTradeCorrectionMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.originalTradeId
        \o message.tradeId
        \o message.price
        \o message.contracts
        \o message.tradeCondition

DecodeTradeCorrectionMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET originalTradeId == ReadBytes(instrumentId.rest, 8) IN IF ~originalTradeId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(originalTradeId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET price == ReadBytes(tradeId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET contracts == ReadBytes(price.rest, 4) IN IF ~contracts.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(contracts.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ time            |-> time.value,
         instrumentId    |-> instrumentId.value,
         originalTradeId |-> originalTradeId.value,
         tradeId         |-> tradeId.value,
         price           |-> price.value,
         contracts       |-> contracts.value,
         tradeCondition  |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeCorrectionMessage ==
    [ time            |-> [i \in 1 .. 8 |-> 0],
      instrumentId    |-> [i \in 1 .. 4 |-> 0],
      originalTradeId |-> [i \in 1 .. 8 |-> 0],
      tradeId         |-> [i \in 1 .. 8 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0],
      contracts       |-> [i \in 1 .. 4 |-> 0],
      tradeCondition  |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Correction Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCorrectionMessage ==
    { ZeroTradeCorrectionMessage }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.originalTradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.contracts = one] : one \in Sample(4) }
        \cup { [ZeroTradeCorrectionMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Tops Trade Break Message: 21 bytes                                      *)
(***************************************************************************)

TopsTradeBreakMessage ==
    [ time           : Sample(8),
      instrumentId   : Sample(4),
      tradeId        : Sample(8),
      tradeCondition : Sample(1) ]

EncodeTopsTradeBreakMessage(message) ==
    message.time
        \o message.instrumentId
        \o message.tradeId
        \o message.tradeCondition

DecodeTopsTradeBreakMessage(bytes) ==
    LET time == ReadBytes(bytes, 8) IN IF ~time.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(time.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(instrumentId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(tradeId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ time           |-> time.value,
         instrumentId   |-> instrumentId.value,
         tradeId        |-> tradeId.value,
         tradeCondition |-> tradeCondition.value ], tradeCondition.rest)

ZeroTopsTradeBreakMessage ==
    [ time           |-> [i \in 1 .. 8 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      tradeId        |-> [i \in 1 .. 8 |-> 0],
      tradeCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Tops Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTopsTradeBreakMessage ==
    { ZeroTopsTradeBreakMessage }
        \cup { [ZeroTopsTradeBreakMessage EXCEPT !.time = one] : one \in Sample(8) }
        \cup { [ZeroTopsTradeBreakMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTopsTradeBreakMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTopsTradeBreakMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Heartbeat Message: 12 bytes                                             *)
(***************************************************************************)

HeartbeatMessage ==
    [ channelId      : Sample(4),
      sequenceNumber : Sample(8) ]

EncodeHeartbeatMessage(message) ==
    message.channelId
        \o message.sequenceNumber

DecodeHeartbeatMessage(bytes) ==
    LET channelId == ReadBytes(bytes, 4) IN IF ~channelId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(channelId.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ channelId      |-> channelId.value,
         sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroHeartbeatMessage ==
    [ channelId      |-> [i \in 1 .. 4 |-> 0],
      sequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Heartbeat Message at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatMessage ==
    { ZeroHeartbeatMessage }
        \cup { [ZeroHeartbeatMessage EXCEPT !.channelId = one] : one \in Sample(4) }
        \cup { [ZeroHeartbeatMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Message                                                                 *)
(***************************************************************************)

Message ==
    [ messageData : SampleBytes ]

EncodeMessage(message) ==
    EncodeUIntLE(Len(message.messageData), 2)
        \o message.messageData

DecodeMessage(bytes) ==
    LET messageLength == ReadUIntLE(bytes, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET messageData == ReadBytes(messageLength.rest, messageLength.value) IN IF ~messageData.ok THEN Fail ELSE
    Ok([ messageData |-> messageData.value ], messageData.rest)

ZeroMessage ==
    [ messageData |-> << >> ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.messageData = one] : one \in SampleBytes }

(***************************************************************************)
(* Sequenced Packet Message messages Group                                 *)
(***************************************************************************)

SequencedPacketMessageMessagesGroup ==
    [ message : Message ]

EncodeSequencedPacketMessageMessagesGroup(message) ==
    EncodeMessage(message.message)

DecodeSequencedPacketMessageMessagesGroup(bytes) ==
    LET message == DecodeMessage(bytes) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroSequencedPacketMessageMessagesGroup ==
    [ message |-> ZeroMessage ]

(* Sequenced Packet Message messages Group at zero, then each field in turn at the values it is checked at *)
CheckedSequencedPacketMessageMessagesGroup ==
    { ZeroSequencedPacketMessageMessagesGroup }
        \cup { [ZeroSequencedPacketMessageMessagesGroup EXCEPT !.message = one] : one \in CheckedMessage }

(* A run of Sequenced Packet Message messages Group, written one after another *)
RECURSIVE EncodeSequencedPacketMessageMessagesGroupList(_)
EncodeSequencedPacketMessageMessagesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSequencedPacketMessageMessagesGroup(Head(messages)) \o EncodeSequencedPacketMessageMessagesGroupList(Tail(messages))

(* As many Sequenced Packet Message messages Group as the field that counts them says *)
RECURSIVE ReadSequencedPacketMessageMessagesGroupList(_, _)
ReadSequencedPacketMessageMessagesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSequencedPacketMessageMessagesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSequencedPacketMessageMessagesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sequenced Packet Message messages Group of each kind, for the lists that carry them *)
OneSequencedPacketMessageMessagesGroup == { ZeroSequencedPacketMessageMessagesGroup }

(***************************************************************************)
(* Sequenced Packet Message messages Groups                                *)
(***************************************************************************)

SequencedPacketMessageMessagesGroups ==
    [ blockLengthShort                    : Sample(1),
      sequencedPacketMessageMessagesGroup : SampleLists(OneSequencedPacketMessageMessagesGroup) ]

EncodeSequencedPacketMessageMessagesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.sequencedPacketMessageMessagesGroup), 1)
        \o EncodeSequencedPacketMessageMessagesGroupList(message.sequencedPacketMessageMessagesGroup)

DecodeSequencedPacketMessageMessagesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET sequencedPacketMessageMessagesGroup == ReadSequencedPacketMessageMessagesGroupList(numInGroup.rest, numInGroup.value) IN IF ~sequencedPacketMessageMessagesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                    |-> blockLengthShort.value,
         sequencedPacketMessageMessagesGroup |-> sequencedPacketMessageMessagesGroup.value ], sequencedPacketMessageMessagesGroup.rest)

ZeroSequencedPacketMessageMessagesGroups ==
    [ blockLengthShort                    |-> [i \in 1 .. 1 |-> 0],
      sequencedPacketMessageMessagesGroup |-> << >> ]

(* Sequenced Packet Message messages Groups at zero, then each field in turn at the values it is checked at *)
CheckedSequencedPacketMessageMessagesGroups ==
    { ZeroSequencedPacketMessageMessagesGroups }
        \cup { [ZeroSequencedPacketMessageMessagesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroSequencedPacketMessageMessagesGroups EXCEPT !.sequencedPacketMessageMessagesGroup = one] : one \in SampleLists(OneSequencedPacketMessageMessagesGroup) }

(***************************************************************************)
(* Sequenced Packet Message                                                *)
(***************************************************************************)

SequencedPacketMessage ==
    [ channelId                            : Sample(4),
      sequenceNumber                       : Sample(8),
      sequencedPacketMessageMessagesGroups : SequencedPacketMessageMessagesGroups ]

EncodeSequencedPacketMessage(message) ==
    message.channelId
        \o message.sequenceNumber
        \o EncodeSequencedPacketMessageMessagesGroups(message.sequencedPacketMessageMessagesGroups)

DecodeSequencedPacketMessage(bytes) ==
    LET channelId == ReadBytes(bytes, 4) IN IF ~channelId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(channelId.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET sequencedPacketMessageMessagesGroups == DecodeSequencedPacketMessageMessagesGroups(sequenceNumber.rest) IN IF ~sequencedPacketMessageMessagesGroups.ok THEN Fail ELSE
    Ok([ channelId                            |-> channelId.value,
         sequenceNumber                       |-> sequenceNumber.value,
         sequencedPacketMessageMessagesGroups |-> sequencedPacketMessageMessagesGroups.value ], sequencedPacketMessageMessagesGroups.rest)

ZeroSequencedPacketMessage ==
    [ channelId                            |-> [i \in 1 .. 4 |-> 0],
      sequenceNumber                       |-> [i \in 1 .. 8 |-> 0],
      sequencedPacketMessageMessagesGroups |-> ZeroSequencedPacketMessageMessagesGroups ]

(* Sequenced Packet Message at zero, then each field in turn at the values it is checked at *)
CheckedSequencedPacketMessage ==
    { ZeroSequencedPacketMessage }
        \cup { [ZeroSequencedPacketMessage EXCEPT !.channelId = one] : one \in Sample(4) }
        \cup { [ZeroSequencedPacketMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSequencedPacketMessage EXCEPT !.sequencedPacketMessageMessagesGroups = one] : one \in CheckedSequencedPacketMessageMessagesGroups }

(***************************************************************************)
(* Session Shutdown Message: 12 bytes                                      *)
(***************************************************************************)

SessionShutdownMessage ==
    [ channelId      : Sample(4),
      sequenceNumber : Sample(8) ]

EncodeSessionShutdownMessage(message) ==
    message.channelId
        \o message.sequenceNumber

DecodeSessionShutdownMessage(bytes) ==
    LET channelId == ReadBytes(bytes, 4) IN IF ~channelId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(channelId.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ channelId      |-> channelId.value,
         sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroSessionShutdownMessage ==
    [ channelId      |-> [i \in 1 .. 4 |-> 0],
      sequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Session Shutdown Message at zero, then each field in turn at the values it is checked at *)
CheckedSessionShutdownMessage ==
    { ZeroSessionShutdownMessage }
        \cup { [ZeroSessionShutdownMessage EXCEPT !.channelId = one] : one \in Sample(4) }
        \cup { [ZeroSessionShutdownMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Retransmission Request Message: 41 bytes                                *)
(***************************************************************************)

RetransmissionRequestMessage ==
    [ beginSequence : Sample(8),
      endSequence   : Sample(8),
      logonId       : Sample(16),
      requestId     : Sample(4),
      channelId     : Sample(4),
      feed          : Sample(1) ]

EncodeRetransmissionRequestMessage(message) ==
    message.beginSequence
        \o message.endSequence
        \o message.logonId
        \o message.requestId
        \o message.channelId
        \o message.feed

DecodeRetransmissionRequestMessage(bytes) ==
    LET beginSequence == ReadBytes(bytes, 8) IN IF ~beginSequence.ok THEN Fail ELSE
    LET endSequence == ReadBytes(beginSequence.rest, 8) IN IF ~endSequence.ok THEN Fail ELSE
    LET logonId == ReadBytes(endSequence.rest, 16) IN IF ~logonId.ok THEN Fail ELSE
    LET requestId == ReadBytes(logonId.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET channelId == ReadBytes(requestId.rest, 4) IN IF ~channelId.ok THEN Fail ELSE
    LET feed == ReadBytes(channelId.rest, 1) IN IF ~feed.ok THEN Fail ELSE
    Ok([ beginSequence |-> beginSequence.value,
         endSequence   |-> endSequence.value,
         logonId       |-> logonId.value,
         requestId     |-> requestId.value,
         channelId     |-> channelId.value,
         feed          |-> feed.value ], feed.rest)

ZeroRetransmissionRequestMessage ==
    [ beginSequence |-> [i \in 1 .. 8 |-> 0],
      endSequence   |-> [i \in 1 .. 8 |-> 0],
      logonId       |-> [i \in 1 .. 16 |-> 0],
      requestId     |-> [i \in 1 .. 4 |-> 0],
      channelId     |-> [i \in 1 .. 4 |-> 0],
      feed          |-> [i \in 1 .. 1 |-> 0] ]

(* Retransmission Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequestMessage ==
    { ZeroRetransmissionRequestMessage }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.beginSequence = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.endSequence = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.logonId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.channelId = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.feed = one] : one \in Sample(1) }

(***************************************************************************)
(* Retransmission Response Message: 26 bytes                               *)
(***************************************************************************)

RetransmissionResponseMessage ==
    [ logonId                        : Sample(16),
      requestId                      : Sample(4),
      channelId                      : Sample(4),
      feed                           : Sample(1),
      statusRetransmissionStatusType : Sample(1) ]

EncodeRetransmissionResponseMessage(message) ==
    message.logonId
        \o message.requestId
        \o message.channelId
        \o message.feed
        \o message.statusRetransmissionStatusType

DecodeRetransmissionResponseMessage(bytes) ==
    LET logonId == ReadBytes(bytes, 16) IN IF ~logonId.ok THEN Fail ELSE
    LET requestId == ReadBytes(logonId.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET channelId == ReadBytes(requestId.rest, 4) IN IF ~channelId.ok THEN Fail ELSE
    LET feed == ReadBytes(channelId.rest, 1) IN IF ~feed.ok THEN Fail ELSE
    LET statusRetransmissionStatusType == ReadBytes(feed.rest, 1) IN IF ~statusRetransmissionStatusType.ok THEN Fail ELSE
    Ok([ logonId                        |-> logonId.value,
         requestId                      |-> requestId.value,
         channelId                      |-> channelId.value,
         feed                           |-> feed.value,
         statusRetransmissionStatusType |-> statusRetransmissionStatusType.value ], statusRetransmissionStatusType.rest)

ZeroRetransmissionResponseMessage ==
    [ logonId                        |-> [i \in 1 .. 16 |-> 0],
      requestId                      |-> [i \in 1 .. 4 |-> 0],
      channelId                      |-> [i \in 1 .. 4 |-> 0],
      feed                           |-> [i \in 1 .. 1 |-> 0],
      statusRetransmissionStatusType |-> [i \in 1 .. 1 |-> 0] ]

(* Retransmission Response Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionResponseMessage ==
    { ZeroRetransmissionResponseMessage }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.logonId = one] : one \in Sample(16) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.channelId = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.feed = one] : one \in Sample(1) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.statusRetransmissionStatusType = one] : one \in Sample(1) }

(***************************************************************************)
(* Snapshot Header Message: 20 bytes                                       *)
(***************************************************************************)

SnapshotHeaderMessage ==
    [ snapshotId          : Sample(4),
      currentPacketNumber : Sample(4),
      totalPacketCount    : Sample(4),
      asOfSequenceNumber  : Sample(8) ]

EncodeSnapshotHeaderMessage(message) ==
    message.snapshotId
        \o message.currentPacketNumber
        \o message.totalPacketCount
        \o message.asOfSequenceNumber

DecodeSnapshotHeaderMessage(bytes) ==
    LET snapshotId == ReadBytes(bytes, 4) IN IF ~snapshotId.ok THEN Fail ELSE
    LET currentPacketNumber == ReadBytes(snapshotId.rest, 4) IN IF ~currentPacketNumber.ok THEN Fail ELSE
    LET totalPacketCount == ReadBytes(currentPacketNumber.rest, 4) IN IF ~totalPacketCount.ok THEN Fail ELSE
    LET asOfSequenceNumber == ReadBytes(totalPacketCount.rest, 8) IN IF ~asOfSequenceNumber.ok THEN Fail ELSE
    Ok([ snapshotId          |-> snapshotId.value,
         currentPacketNumber |-> currentPacketNumber.value,
         totalPacketCount    |-> totalPacketCount.value,
         asOfSequenceNumber  |-> asOfSequenceNumber.value ], asOfSequenceNumber.rest)

ZeroSnapshotHeaderMessage ==
    [ snapshotId          |-> [i \in 1 .. 4 |-> 0],
      currentPacketNumber |-> [i \in 1 .. 4 |-> 0],
      totalPacketCount    |-> [i \in 1 .. 4 |-> 0],
      asOfSequenceNumber  |-> [i \in 1 .. 8 |-> 0] ]

(* Snapshot Header Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotHeaderMessage ==
    { ZeroSnapshotHeaderMessage }
        \cup { [ZeroSnapshotHeaderMessage EXCEPT !.snapshotId = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotHeaderMessage EXCEPT !.currentPacketNumber = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotHeaderMessage EXCEPT !.totalPacketCount = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotHeaderMessage EXCEPT !.asOfSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

UnderlyingRefDataMessageCode == 1  \* 0x01
SymbolMappingMessageCode == 2  \* 0x02
InstrumentClearMessageCode == 3  \* 0x03
TradingStatusMessageCode == 4  \* 0x04
OptionsAuctionSummaryMessageCode == 5  \* 0x05
OptionsAuctionWidthUpdateMessageCode == 6  \* 0x06
LiquidityEventNotificationMessageCode == 7  \* 0x07
LiquidityEventExecutionMessageCode == 8  \* 0x08
LiquidityEventCancelMessageCode == 9  \* 0x09
AddOrderNonCustomerMessageCode == 100  \* 0x64
AddOrderCustomerMessageCode == 101  \* 0x65
ModifyOrderMessageCode == 102  \* 0x66
DeleteOrderMessageCode == 103  \* 0x67
OrderExecutionMessageCode == 104  \* 0x68
DeepTradeBreakMessageCode == 105  \* 0x69
QuoteUpdateNoCustomerInterestMessageCode == 200  \* 0xc8
QuoteUpdateCustomerInterestMessageCode == 201  \* 0xc9
TradeMessageCode == 202  \* 0xca
TradeCorrectionMessageCode == 203  \* 0xcb
TopsTradeBreakMessageCode == 204  \* 0xcc
HeartbeatMessageCode == 300  \* 0x12c
SequencedPacketMessageCode == 301  \* 0x12d
SessionShutdownMessageCode == 302  \* 0x12e
ServerHeartbeatMessageCode == 400  \* 0x190
ClientHeartbeatMessageCode == 401  \* 0x191
RetransmissionRequestMessageCode == 402  \* 0x192
RetransmissionResponseMessageCode == 403  \* 0x193
SnapshotHeaderMessageCode == 601  \* 0x259

Payload ==
    [ tag : {UnderlyingRefDataMessageCode}, body : UnderlyingRefDataMessage ]
        \cup [ tag : {SymbolMappingMessageCode}, body : SymbolMappingMessage ]
        \cup [ tag : {InstrumentClearMessageCode}, body : InstrumentClearMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {OptionsAuctionSummaryMessageCode}, body : OptionsAuctionSummaryMessage ]
        \cup [ tag : {OptionsAuctionWidthUpdateMessageCode}, body : OptionsAuctionWidthUpdateMessage ]
        \cup [ tag : {LiquidityEventNotificationMessageCode}, body : LiquidityEventNotificationMessage ]
        \cup [ tag : {LiquidityEventExecutionMessageCode}, body : LiquidityEventExecutionMessage ]
        \cup [ tag : {LiquidityEventCancelMessageCode}, body : LiquidityEventCancelMessage ]
        \cup [ tag : {AddOrderNonCustomerMessageCode}, body : AddOrderNonCustomerMessage ]
        \cup [ tag : {AddOrderCustomerMessageCode}, body : AddOrderCustomerMessage ]
        \cup [ tag : {ModifyOrderMessageCode}, body : ModifyOrderMessage ]
        \cup [ tag : {DeleteOrderMessageCode}, body : DeleteOrderMessage ]
        \cup [ tag : {OrderExecutionMessageCode}, body : OrderExecutionMessage ]
        \cup [ tag : {DeepTradeBreakMessageCode}, body : DeepTradeBreakMessage ]
        \cup [ tag : {QuoteUpdateNoCustomerInterestMessageCode}, body : QuoteUpdateNoCustomerInterestMessage ]
        \cup [ tag : {QuoteUpdateCustomerInterestMessageCode}, body : QuoteUpdateCustomerInterestMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeCorrectionMessageCode}, body : TradeCorrectionMessage ]
        \cup [ tag : {TopsTradeBreakMessageCode}, body : TopsTradeBreakMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : HeartbeatMessage ]
        \cup [ tag : {SequencedPacketMessageCode}, body : SequencedPacketMessage ]
        \cup [ tag : {SessionShutdownMessageCode}, body : SessionShutdownMessage ]
        \cup [ tag : {ServerHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RetransmissionRequestMessageCode}, body : RetransmissionRequestMessage ]
        \cup [ tag : {RetransmissionResponseMessageCode}, body : RetransmissionResponseMessage ]
        \cup [ tag : {SnapshotHeaderMessageCode}, body : SnapshotHeaderMessage ]

EncodePayload(message) ==
    CASE message.tag = UnderlyingRefDataMessageCode -> EncodeUnderlyingRefDataMessage(message.body)
      [] message.tag = SymbolMappingMessageCode -> EncodeSymbolMappingMessage(message.body)
      [] message.tag = InstrumentClearMessageCode -> EncodeInstrumentClearMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = OptionsAuctionSummaryMessageCode -> EncodeOptionsAuctionSummaryMessage(message.body)
      [] message.tag = OptionsAuctionWidthUpdateMessageCode -> EncodeOptionsAuctionWidthUpdateMessage(message.body)
      [] message.tag = LiquidityEventNotificationMessageCode -> EncodeLiquidityEventNotificationMessage(message.body)
      [] message.tag = LiquidityEventExecutionMessageCode -> EncodeLiquidityEventExecutionMessage(message.body)
      [] message.tag = LiquidityEventCancelMessageCode -> EncodeLiquidityEventCancelMessage(message.body)
      [] message.tag = AddOrderNonCustomerMessageCode -> EncodeAddOrderNonCustomerMessage(message.body)
      [] message.tag = AddOrderCustomerMessageCode -> EncodeAddOrderCustomerMessage(message.body)
      [] message.tag = ModifyOrderMessageCode -> EncodeModifyOrderMessage(message.body)
      [] message.tag = DeleteOrderMessageCode -> EncodeDeleteOrderMessage(message.body)
      [] message.tag = OrderExecutionMessageCode -> EncodeOrderExecutionMessage(message.body)
      [] message.tag = DeepTradeBreakMessageCode -> EncodeDeepTradeBreakMessage(message.body)
      [] message.tag = QuoteUpdateNoCustomerInterestMessageCode -> EncodeQuoteUpdateNoCustomerInterestMessage(message.body)
      [] message.tag = QuoteUpdateCustomerInterestMessageCode -> EncodeQuoteUpdateCustomerInterestMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeCorrectionMessageCode -> EncodeTradeCorrectionMessage(message.body)
      [] message.tag = TopsTradeBreakMessageCode -> EncodeTopsTradeBreakMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> EncodeHeartbeatMessage(message.body)
      [] message.tag = SequencedPacketMessageCode -> EncodeSequencedPacketMessage(message.body)
      [] message.tag = SessionShutdownMessageCode -> EncodeSessionShutdownMessage(message.body)
      [] message.tag = ServerHeartbeatMessageCode -> << >>
      [] message.tag = ClientHeartbeatMessageCode -> << >>
      [] message.tag = RetransmissionRequestMessageCode -> EncodeRetransmissionRequestMessage(message.body)
      [] message.tag = RetransmissionResponseMessageCode -> EncodeRetransmissionResponseMessage(message.body)
      [] message.tag = SnapshotHeaderMessageCode -> EncodeSnapshotHeaderMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = UnderlyingRefDataMessageCode -> DecodeUnderlyingRefDataMessage(bytes)
              [] tag = SymbolMappingMessageCode -> DecodeSymbolMappingMessage(bytes)
              [] tag = InstrumentClearMessageCode -> DecodeInstrumentClearMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = OptionsAuctionSummaryMessageCode -> DecodeOptionsAuctionSummaryMessage(bytes)
              [] tag = OptionsAuctionWidthUpdateMessageCode -> DecodeOptionsAuctionWidthUpdateMessage(bytes)
              [] tag = LiquidityEventNotificationMessageCode -> DecodeLiquidityEventNotificationMessage(bytes)
              [] tag = LiquidityEventExecutionMessageCode -> DecodeLiquidityEventExecutionMessage(bytes)
              [] tag = LiquidityEventCancelMessageCode -> DecodeLiquidityEventCancelMessage(bytes)
              [] tag = AddOrderNonCustomerMessageCode -> DecodeAddOrderNonCustomerMessage(bytes)
              [] tag = AddOrderCustomerMessageCode -> DecodeAddOrderCustomerMessage(bytes)
              [] tag = ModifyOrderMessageCode -> DecodeModifyOrderMessage(bytes)
              [] tag = DeleteOrderMessageCode -> DecodeDeleteOrderMessage(bytes)
              [] tag = OrderExecutionMessageCode -> DecodeOrderExecutionMessage(bytes)
              [] tag = DeepTradeBreakMessageCode -> DecodeDeepTradeBreakMessage(bytes)
              [] tag = QuoteUpdateNoCustomerInterestMessageCode -> DecodeQuoteUpdateNoCustomerInterestMessage(bytes)
              [] tag = QuoteUpdateCustomerInterestMessageCode -> DecodeQuoteUpdateCustomerInterestMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeCorrectionMessageCode -> DecodeTradeCorrectionMessage(bytes)
              [] tag = TopsTradeBreakMessageCode -> DecodeTopsTradeBreakMessage(bytes)
              [] tag = HeartbeatMessageCode -> DecodeHeartbeatMessage(bytes)
              [] tag = SequencedPacketMessageCode -> DecodeSequencedPacketMessage(bytes)
              [] tag = SessionShutdownMessageCode -> DecodeSessionShutdownMessage(bytes)
              [] tag = ServerHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = RetransmissionRequestMessageCode -> DecodeRetransmissionRequestMessage(bytes)
              [] tag = RetransmissionResponseMessageCode -> DecodeRetransmissionResponseMessage(bytes)
              [] tag = SnapshotHeaderMessageCode -> DecodeSnapshotHeaderMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> UnderlyingRefDataMessageCode, body |-> ZeroUnderlyingRefDataMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> UnderlyingRefDataMessageCode, body |-> one] : one \in CheckedUnderlyingRefDataMessage }
        \cup { [tag |-> SymbolMappingMessageCode, body |-> one] : one \in CheckedSymbolMappingMessage }
        \cup { [tag |-> InstrumentClearMessageCode, body |-> one] : one \in CheckedInstrumentClearMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> OptionsAuctionSummaryMessageCode, body |-> one] : one \in CheckedOptionsAuctionSummaryMessage }
        \cup { [tag |-> OptionsAuctionWidthUpdateMessageCode, body |-> one] : one \in CheckedOptionsAuctionWidthUpdateMessage }
        \cup { [tag |-> LiquidityEventNotificationMessageCode, body |-> one] : one \in CheckedLiquidityEventNotificationMessage }
        \cup { [tag |-> LiquidityEventExecutionMessageCode, body |-> one] : one \in CheckedLiquidityEventExecutionMessage }
        \cup { [tag |-> LiquidityEventCancelMessageCode, body |-> one] : one \in CheckedLiquidityEventCancelMessage }
        \cup { [tag |-> AddOrderNonCustomerMessageCode, body |-> one] : one \in CheckedAddOrderNonCustomerMessage }
        \cup { [tag |-> AddOrderCustomerMessageCode, body |-> one] : one \in CheckedAddOrderCustomerMessage }
        \cup { [tag |-> ModifyOrderMessageCode, body |-> one] : one \in CheckedModifyOrderMessage }
        \cup { [tag |-> DeleteOrderMessageCode, body |-> one] : one \in CheckedDeleteOrderMessage }
        \cup { [tag |-> OrderExecutionMessageCode, body |-> one] : one \in CheckedOrderExecutionMessage }
        \cup { [tag |-> DeepTradeBreakMessageCode, body |-> one] : one \in CheckedDeepTradeBreakMessage }
        \cup { [tag |-> QuoteUpdateNoCustomerInterestMessageCode, body |-> one] : one \in CheckedQuoteUpdateNoCustomerInterestMessage }
        \cup { [tag |-> QuoteUpdateCustomerInterestMessageCode, body |-> one] : one \in CheckedQuoteUpdateCustomerInterestMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeCorrectionMessageCode, body |-> one] : one \in CheckedTradeCorrectionMessage }
        \cup { [tag |-> TopsTradeBreakMessageCode, body |-> one] : one \in CheckedTopsTradeBreakMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> one] : one \in CheckedHeartbeatMessage }
        \cup { [tag |-> SequencedPacketMessageCode, body |-> one] : one \in CheckedSequencedPacketMessage }
        \cup { [tag |-> SessionShutdownMessageCode, body |-> one] : one \in CheckedSessionShutdownMessage }
        \cup { [tag |-> ServerHeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RetransmissionRequestMessageCode, body |-> one] : one \in CheckedRetransmissionRequestMessage }
        \cup { [tag |-> RetransmissionResponseMessageCode, body |-> one] : one \in CheckedRetransmissionResponseMessage }
        \cup { [tag |-> SnapshotHeaderMessageCode, body |-> one] : one \in CheckedSnapshotHeaderMessage }

(***************************************************************************)
(* Sbe Message, framed by Packet Length                                    *)
(***************************************************************************)

SbeMessage ==
    [ blockLength : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeSbeMessageBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeSbeMessage(message) ==
    LET body == EncodeSbeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 4, 2) \o body

DecodeSbeMessageBody(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

DecodeSbeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeSbeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSbeMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
        \cup { [ZeroSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Sbe Message, written one after another *)
RECURSIVE EncodeSbeMessageList(_)
EncodeSbeMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSbeMessage(Head(messages)) \o EncodeSbeMessageList(Tail(messages))

(* As many Sbe Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadSbeMessageAll(_)
ReadSbeMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSbeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSbeMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sbe Message of each kind, for the lists that carry them *)
OneSbeMessage ==
    { [ZeroSbeMessage EXCEPT !.payload = [tag |-> UnderlyingRefDataMessageCode, body |-> ZeroUnderlyingRefDataMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SymbolMappingMessageCode, body |-> ZeroSymbolMappingMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> InstrumentClearMessageCode, body |-> ZeroInstrumentClearMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OptionsAuctionSummaryMessageCode, body |-> ZeroOptionsAuctionSummaryMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OptionsAuctionWidthUpdateMessageCode, body |-> ZeroOptionsAuctionWidthUpdateMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LiquidityEventNotificationMessageCode, body |-> ZeroLiquidityEventNotificationMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LiquidityEventExecutionMessageCode, body |-> ZeroLiquidityEventExecutionMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> LiquidityEventCancelMessageCode, body |-> ZeroLiquidityEventCancelMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> AddOrderNonCustomerMessageCode, body |-> ZeroAddOrderNonCustomerMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> AddOrderCustomerMessageCode, body |-> ZeroAddOrderCustomerMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> ModifyOrderMessageCode, body |-> ZeroModifyOrderMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> DeleteOrderMessageCode, body |-> ZeroDeleteOrderMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> OrderExecutionMessageCode, body |-> ZeroOrderExecutionMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> DeepTradeBreakMessageCode, body |-> ZeroDeepTradeBreakMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> QuoteUpdateNoCustomerInterestMessageCode, body |-> ZeroQuoteUpdateNoCustomerInterestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> QuoteUpdateCustomerInterestMessageCode, body |-> ZeroQuoteUpdateCustomerInterestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TradeCorrectionMessageCode, body |-> ZeroTradeCorrectionMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> TopsTradeBreakMessageCode, body |-> ZeroTopsTradeBreakMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> ZeroHeartbeatMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SequencedPacketMessageCode, body |-> ZeroSequencedPacketMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SessionShutdownMessageCode, body |-> ZeroSessionShutdownMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> ServerHeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> ClientHeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> RetransmissionRequestMessageCode, body |-> ZeroRetransmissionRequestMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> RetransmissionResponseMessageCode, body |-> ZeroRetransmissionResponseMessage]],
      [ZeroSbeMessage EXCEPT !.payload = [tag |-> SnapshotHeaderMessageCode, body |-> ZeroSnapshotHeaderMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ sbeMessage : SampleLists(OneSbeMessage) ]

EncodePacket(message) ==
    EncodeSbeMessageList(message.sbeMessage)

DecodePacket(bytes) ==
    LET sbeMessage == ReadSbeMessageAll(bytes) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sbeMessage |-> sbeMessage.value ], sbeMessage.rest)

ZeroPacket ==
    [ sbeMessage |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.sbeMessage = one] : one \in SampleLists(OneSbeMessage) }

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

(* Every Underlying Ref Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingRefDataMessage ==
    \A message \in CheckedUnderlyingRefDataMessage :
        LET read == DecodeUnderlyingRefDataMessage(EncodeUnderlyingRefDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolMappingMessage ==
    \A message \in CheckedSymbolMappingMessage :
        LET read == DecodeSymbolMappingMessage(EncodeSymbolMappingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentClearMessage ==
    \A message \in CheckedInstrumentClearMessage :
        LET read == DecodeInstrumentClearMessage(EncodeInstrumentClearMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Auction Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsAuctionSummaryMessage ==
    \A message \in CheckedOptionsAuctionSummaryMessage :
        LET read == DecodeOptionsAuctionSummaryMessage(EncodeOptionsAuctionSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Auction Width Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsAuctionWidthUpdateMessage ==
    \A message \in CheckedOptionsAuctionWidthUpdateMessage :
        LET read == DecodeOptionsAuctionWidthUpdateMessage(EncodeOptionsAuctionWidthUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Event Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityEventNotificationMessage ==
    \A message \in CheckedLiquidityEventNotificationMessage :
        LET read == DecodeLiquidityEventNotificationMessage(EncodeLiquidityEventNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Event Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityEventExecutionMessage ==
    \A message \in CheckedLiquidityEventExecutionMessage :
        LET read == DecodeLiquidityEventExecutionMessage(EncodeLiquidityEventExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Event Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityEventCancelMessage ==
    \A message \in CheckedLiquidityEventCancelMessage :
        LET read == DecodeLiquidityEventCancelMessage(EncodeLiquidityEventCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Non Customer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderNonCustomerMessage ==
    \A message \in CheckedAddOrderNonCustomerMessage :
        LET read == DecodeAddOrderNonCustomerMessage(EncodeAddOrderNonCustomerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Customer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderCustomerMessage ==
    \A message \in CheckedAddOrderCustomerMessage :
        LET read == DecodeAddOrderCustomerMessage(EncodeAddOrderCustomerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyOrderMessage ==
    \A message \in CheckedModifyOrderMessage :
        LET read == DecodeModifyOrderMessage(EncodeModifyOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Delete Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeleteOrderMessage ==
    \A message \in CheckedDeleteOrderMessage :
        LET read == DecodeDeleteOrderMessage(EncodeDeleteOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutionMessage ==
    \A message \in CheckedOrderExecutionMessage :
        LET read == DecodeOrderExecutionMessage(EncodeOrderExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Deep Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeepTradeBreakMessage ==
    \A message \in CheckedDeepTradeBreakMessage :
        LET read == DecodeDeepTradeBreakMessage(EncodeDeepTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update No Customer Interest Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateNoCustomerInterestMessage ==
    \A message \in CheckedQuoteUpdateNoCustomerInterestMessage :
        LET read == DecodeQuoteUpdateNoCustomerInterestMessage(EncodeQuoteUpdateNoCustomerInterestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Update Customer Interest Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteUpdateCustomerInterestMessage ==
    \A message \in CheckedQuoteUpdateCustomerInterestMessage :
        LET read == DecodeQuoteUpdateCustomerInterestMessage(EncodeQuoteUpdateCustomerInterestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
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

(* Every Tops Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopsTradeBreakMessage ==
    \A message \in CheckedTopsTradeBreakMessage :
        LET read == DecodeTopsTradeBreakMessage(EncodeTopsTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat Message decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatMessage ==
    \A message \in CheckedHeartbeatMessage :
        LET read == DecodeHeartbeatMessage(EncodeHeartbeatMessage(message))
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

(* Every Sequenced Packet Message messages Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedPacketMessageMessagesGroup ==
    \A message \in CheckedSequencedPacketMessageMessagesGroup :
        LET read == DecodeSequencedPacketMessageMessagesGroup(EncodeSequencedPacketMessageMessagesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Packet Message messages Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedPacketMessageMessagesGroups ==
    \A message \in CheckedSequencedPacketMessageMessagesGroups :
        LET read == DecodeSequencedPacketMessageMessagesGroups(EncodeSequencedPacketMessageMessagesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Packet Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedPacketMessage ==
    \A message \in CheckedSequencedPacketMessage :
        LET read == DecodeSequencedPacketMessage(EncodeSequencedPacketMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Session Shutdown Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionShutdownMessage ==
    \A message \in CheckedSessionShutdownMessage :
        LET read == DecodeSessionShutdownMessage(EncodeSessionShutdownMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequestMessage ==
    \A message \in CheckedRetransmissionRequestMessage :
        LET read == DecodeRetransmissionRequestMessage(EncodeRetransmissionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionResponseMessage ==
    \A message \in CheckedRetransmissionResponseMessage :
        LET read == DecodeRetransmissionResponseMessage(EncodeRetransmissionResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Header Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotHeaderMessage ==
    \A message \in CheckedSnapshotHeaderMessage :
        LET read == DecodeSnapshotHeaderMessage(EncodeSnapshotHeaderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sbe Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET read == DecodeSbeMessage(EncodeSbeMessage(message))
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

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET bytes == EncodeSbeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - -2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
