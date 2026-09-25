----------------------- MODULE IexEquities_Deep_v1_6 -----------------------
(***************************************************************************)
(* Investors Exchange Deep v1.6                                            *)
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
(* Note: Security Directory Flags is a bit field set, checked as its 1     *)
(* byte rather than bit by bit.                                            *)
(*                                                                         *)
(* Note: Sale Condition Flags is a bit field set, checked as its 1 byte    *)
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

(* The integer a rule depends on *)
ReadUIntLE(bytes, width) ==
    IF Len(bytes) < width
    THEN Fail
    ELSE Ok(DecodeUIntLE(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

(***************************************************************************)
(* The values a field is checked at: zero, the spaces a text field is      *)
(* padded with, and                                                        *)
(* every bit set, which is where an encoding goes wrong if it goes wrong   *)
(***************************************************************************)

Sample(width) ==
    { [i \in 1 .. width |-> 0],
      [i \in 1 .. width |-> 32],
      [i \in 1 .. width |-> 255] }

(* The lists a record is checked over: none, one, and a run of two. What a run has *)
(* to get right is reading one entry after another, which two of a kind already say. *)
SampleLists(entries) ==
    { << >> }
        \cup { <<one>> : one \in entries }
        \cup { <<one, one>> : one \in entries }

(***************************************************************************)
(* Snapshot Request Message: 56 bytes                                      *)
(***************************************************************************)

SnapshotRequestMessage ==
    [ authenticationToken   : Sample(40),
      channelId             : Sample(4),
      sessionId             : Sample(4),
      minimumSequenceNumber : Sample(8) ]

EncodeSnapshotRequestMessage(message) ==
    message.authenticationToken
        \o message.channelId
        \o message.sessionId
        \o message.minimumSequenceNumber

DecodeSnapshotRequestMessage(bytes) ==
    LET authenticationToken == ReadBytes(bytes, 40) IN IF ~authenticationToken.ok THEN Fail ELSE
    LET channelId == ReadBytes(authenticationToken.rest, 4) IN IF ~channelId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(channelId.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET minimumSequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~minimumSequenceNumber.ok THEN Fail ELSE
    Ok([ authenticationToken   |-> authenticationToken.value,
         channelId             |-> channelId.value,
         sessionId             |-> sessionId.value,
         minimumSequenceNumber |-> minimumSequenceNumber.value ], minimumSequenceNumber.rest)

ZeroSnapshotRequestMessage ==
    [ authenticationToken   |-> [i \in 1 .. 40 |-> 0],
      channelId             |-> [i \in 1 .. 4 |-> 0],
      sessionId             |-> [i \in 1 .. 4 |-> 0],
      minimumSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Snapshot Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotRequestMessage ==
    { ZeroSnapshotRequestMessage }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.authenticationToken = one] : one \in Sample(40) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.channelId = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroSnapshotRequestMessage EXCEPT !.minimumSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Error Response Message: 1 bytes                                         *)
(***************************************************************************)

ErrorResponseMessage ==
    [ rejectReasonCode : Sample(1) ]

EncodeErrorResponseMessage(message) ==
    message.rejectReasonCode

DecodeErrorResponseMessage(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroErrorResponseMessage ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Error Response Message at zero, then each field in turn at the values it is checked at *)
CheckedErrorResponseMessage ==
    { ZeroErrorResponseMessage }
        \cup { [ZeroErrorResponseMessage EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Snapshot Start Message: 8 bytes                                         *)
(***************************************************************************)

SnapshotStartMessage ==
    [ snapshotLength : Sample(8) ]

EncodeSnapshotStartMessage(message) ==
    message.snapshotLength

DecodeSnapshotStartMessage(bytes) ==
    LET snapshotLength == ReadBytes(bytes, 8) IN IF ~snapshotLength.ok THEN Fail ELSE
    Ok([ snapshotLength |-> snapshotLength.value ], snapshotLength.rest)

ZeroSnapshotStartMessage ==
    [ snapshotLength |-> [i \in 1 .. 8 |-> 0] ]

(* Snapshot Start Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotStartMessage ==
    { ZeroSnapshotStartMessage }
        \cup { [ZeroSnapshotStartMessage EXCEPT !.snapshotLength = one] : one \in Sample(8) }

(***************************************************************************)
(* System Event Message: 9 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ systemEvent : Sample(1),
      timestamp   : Sample(8) ]

EncodeSystemEventMessage(message) ==
    message.systemEvent
        \o message.timestamp

DecodeSystemEventMessage(bytes) ==
    LET systemEvent == ReadBytes(bytes, 1) IN IF ~systemEvent.ok THEN Fail ELSE
    LET timestamp == ReadBytes(systemEvent.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ systemEvent |-> systemEvent.value,
         timestamp   |-> timestamp.value ], timestamp.rest)

ZeroSystemEventMessage ==
    [ systemEvent |-> [i \in 1 .. 1 |-> 0],
      timestamp   |-> [i \in 1 .. 8 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.systemEvent = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Security Directory Message: 30 bytes                                    *)
(***************************************************************************)

SecurityDirectoryMessage ==
    [ securityDirectoryFlags : Sample(1),
      timestamp              : Sample(8),
      symbol                 : Sample(8),
      roundLotSize           : Sample(4),
      adjustedPocPrice       : Sample(8),
      luldTier               : Sample(1) ]

EncodeSecurityDirectoryMessage(message) ==
    message.securityDirectoryFlags
        \o message.timestamp
        \o message.symbol
        \o message.roundLotSize
        \o message.adjustedPocPrice
        \o message.luldTier

DecodeSecurityDirectoryMessage(bytes) ==
    LET securityDirectoryFlags == ReadBytes(bytes, 1) IN IF ~securityDirectoryFlags.ok THEN Fail ELSE
    LET timestamp == ReadBytes(securityDirectoryFlags.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(symbol.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET adjustedPocPrice == ReadBytes(roundLotSize.rest, 8) IN IF ~adjustedPocPrice.ok THEN Fail ELSE
    LET luldTier == ReadBytes(adjustedPocPrice.rest, 1) IN IF ~luldTier.ok THEN Fail ELSE
    Ok([ securityDirectoryFlags |-> securityDirectoryFlags.value,
         timestamp              |-> timestamp.value,
         symbol                 |-> symbol.value,
         roundLotSize           |-> roundLotSize.value,
         adjustedPocPrice       |-> adjustedPocPrice.value,
         luldTier               |-> luldTier.value ], luldTier.rest)

ZeroSecurityDirectoryMessage ==
    [ securityDirectoryFlags |-> [i \in 1 .. 1 |-> 0],
      timestamp              |-> [i \in 1 .. 8 |-> 0],
      symbol                 |-> [i \in 1 .. 8 |-> 0],
      roundLotSize           |-> [i \in 1 .. 4 |-> 0],
      adjustedPocPrice       |-> [i \in 1 .. 8 |-> 0],
      luldTier               |-> [i \in 1 .. 1 |-> 0] ]

(* Security Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDirectoryMessage ==
    { ZeroSecurityDirectoryMessage }
        \cup { [ZeroSecurityDirectoryMessage EXCEPT !.securityDirectoryFlags = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDirectoryMessage EXCEPT !.adjustedPocPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDirectoryMessage EXCEPT !.luldTier = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Status Message: 21 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ tradingStatus : Sample(1),
      timestamp     : Sample(8),
      symbol        : Sample(8),
      reason        : Sample(4) ]

EncodeTradingStatusMessage(message) ==
    message.tradingStatus
        \o message.timestamp
        \o message.symbol
        \o message.reason

DecodeTradingStatusMessage(bytes) ==
    LET tradingStatus == ReadBytes(bytes, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET timestamp == ReadBytes(tradingStatus.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET reason == ReadBytes(symbol.rest, 4) IN IF ~reason.ok THEN Fail ELSE
    Ok([ tradingStatus |-> tradingStatus.value,
         timestamp     |-> timestamp.value,
         symbol        |-> symbol.value,
         reason        |-> reason.value ], reason.rest)

ZeroTradingStatusMessage ==
    [ tradingStatus |-> [i \in 1 .. 1 |-> 0],
      timestamp     |-> [i \in 1 .. 8 |-> 0],
      symbol        |-> [i \in 1 .. 8 |-> 0],
      reason        |-> [i \in 1 .. 4 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reason = one] : one \in Sample(4) }

(***************************************************************************)
(* Retail Liquidity Indicator Message: 17 bytes                            *)
(***************************************************************************)

RetailLiquidityIndicatorMessage ==
    [ retailLiquidityIndicator : Sample(1),
      timestamp                : Sample(8),
      symbol                   : Sample(8) ]

EncodeRetailLiquidityIndicatorMessage(message) ==
    message.retailLiquidityIndicator
        \o message.timestamp
        \o message.symbol

DecodeRetailLiquidityIndicatorMessage(bytes) ==
    LET retailLiquidityIndicator == ReadBytes(bytes, 1) IN IF ~retailLiquidityIndicator.ok THEN Fail ELSE
    LET timestamp == ReadBytes(retailLiquidityIndicator.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ retailLiquidityIndicator |-> retailLiquidityIndicator.value,
         timestamp                |-> timestamp.value,
         symbol                   |-> symbol.value ], symbol.rest)

ZeroRetailLiquidityIndicatorMessage ==
    [ retailLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      timestamp                |-> [i \in 1 .. 8 |-> 0],
      symbol                   |-> [i \in 1 .. 8 |-> 0] ]

(* Retail Liquidity Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedRetailLiquidityIndicatorMessage ==
    { ZeroRetailLiquidityIndicatorMessage }
        \cup { [ZeroRetailLiquidityIndicatorMessage EXCEPT !.retailLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRetailLiquidityIndicatorMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRetailLiquidityIndicatorMessage EXCEPT !.symbol = one] : one \in Sample(8) }

(***************************************************************************)
(* Operational Halt Status Message: 17 bytes                               *)
(***************************************************************************)

OperationalHaltStatusMessage ==
    [ operationalHaltStatus : Sample(1),
      timestamp             : Sample(8),
      symbol                : Sample(8) ]

EncodeOperationalHaltStatusMessage(message) ==
    message.operationalHaltStatus
        \o message.timestamp
        \o message.symbol

DecodeOperationalHaltStatusMessage(bytes) ==
    LET operationalHaltStatus == ReadBytes(bytes, 1) IN IF ~operationalHaltStatus.ok THEN Fail ELSE
    LET timestamp == ReadBytes(operationalHaltStatus.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ operationalHaltStatus |-> operationalHaltStatus.value,
         timestamp             |-> timestamp.value,
         symbol                |-> symbol.value ], symbol.rest)

ZeroOperationalHaltStatusMessage ==
    [ operationalHaltStatus |-> [i \in 1 .. 1 |-> 0],
      timestamp             |-> [i \in 1 .. 8 |-> 0],
      symbol                |-> [i \in 1 .. 8 |-> 0] ]

(* Operational Halt Status Message at zero, then each field in turn at the values it is checked at *)
CheckedOperationalHaltStatusMessage ==
    { ZeroOperationalHaltStatusMessage }
        \cup { [ZeroOperationalHaltStatusMessage EXCEPT !.operationalHaltStatus = one] : one \in Sample(1) }
        \cup { [ZeroOperationalHaltStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOperationalHaltStatusMessage EXCEPT !.symbol = one] : one \in Sample(8) }

(***************************************************************************)
(* Short Sale Price Test Status Message: 18 bytes                          *)
(***************************************************************************)

ShortSalePriceTestStatusMessage ==
    [ shortSalePriceTestStatus : Sample(1),
      timestamp                : Sample(8),
      symbol                   : Sample(8),
      detail                   : Sample(1) ]

EncodeShortSalePriceTestStatusMessage(message) ==
    message.shortSalePriceTestStatus
        \o message.timestamp
        \o message.symbol
        \o message.detail

DecodeShortSalePriceTestStatusMessage(bytes) ==
    LET shortSalePriceTestStatus == ReadBytes(bytes, 1) IN IF ~shortSalePriceTestStatus.ok THEN Fail ELSE
    LET timestamp == ReadBytes(shortSalePriceTestStatus.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET detail == ReadBytes(symbol.rest, 1) IN IF ~detail.ok THEN Fail ELSE
    Ok([ shortSalePriceTestStatus |-> shortSalePriceTestStatus.value,
         timestamp                |-> timestamp.value,
         symbol                   |-> symbol.value,
         detail                   |-> detail.value ], detail.rest)

ZeroShortSalePriceTestStatusMessage ==
    [ shortSalePriceTestStatus |-> [i \in 1 .. 1 |-> 0],
      timestamp                |-> [i \in 1 .. 8 |-> 0],
      symbol                   |-> [i \in 1 .. 8 |-> 0],
      detail                   |-> [i \in 1 .. 1 |-> 0] ]

(* Short Sale Price Test Status Message at zero, then each field in turn at the values it is checked at *)
CheckedShortSalePriceTestStatusMessage ==
    { ZeroShortSalePriceTestStatusMessage }
        \cup { [ZeroShortSalePriceTestStatusMessage EXCEPT !.shortSalePriceTestStatus = one] : one \in Sample(1) }
        \cup { [ZeroShortSalePriceTestStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroShortSalePriceTestStatusMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroShortSalePriceTestStatusMessage EXCEPT !.detail = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Event Message: 17 bytes                                        *)
(***************************************************************************)

SecurityEventMessage ==
    [ securityEvent : Sample(1),
      timestamp     : Sample(8),
      symbol        : Sample(8) ]

EncodeSecurityEventMessage(message) ==
    message.securityEvent
        \o message.timestamp
        \o message.symbol

DecodeSecurityEventMessage(bytes) ==
    LET securityEvent == ReadBytes(bytes, 1) IN IF ~securityEvent.ok THEN Fail ELSE
    LET timestamp == ReadBytes(securityEvent.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ securityEvent |-> securityEvent.value,
         timestamp     |-> timestamp.value,
         symbol        |-> symbol.value ], symbol.rest)

ZeroSecurityEventMessage ==
    [ securityEvent |-> [i \in 1 .. 1 |-> 0],
      timestamp     |-> [i \in 1 .. 8 |-> 0],
      symbol        |-> [i \in 1 .. 8 |-> 0] ]

(* Security Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityEventMessage ==
    { ZeroSecurityEventMessage }
        \cup { [ZeroSecurityEventMessage EXCEPT !.securityEvent = one] : one \in Sample(1) }
        \cup { [ZeroSecurityEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSecurityEventMessage EXCEPT !.symbol = one] : one \in Sample(8) }

(***************************************************************************)
(* Price Level Buy Update Message: 29 bytes                                *)
(***************************************************************************)

PriceLevelBuyUpdateMessage ==
    [ eventFlags : Sample(1),
      timestamp  : Sample(8),
      symbol     : Sample(8),
      size       : Sample(4),
      price      : Sample(8) ]

EncodePriceLevelBuyUpdateMessage(message) ==
    message.eventFlags
        \o message.timestamp
        \o message.symbol
        \o message.size
        \o message.price

DecodePriceLevelBuyUpdateMessage(bytes) ==
    LET eventFlags == ReadBytes(bytes, 1) IN IF ~eventFlags.ok THEN Fail ELSE
    LET timestamp == ReadBytes(eventFlags.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET size == ReadBytes(symbol.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET price == ReadBytes(size.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ eventFlags |-> eventFlags.value,
         timestamp  |-> timestamp.value,
         symbol     |-> symbol.value,
         size       |-> size.value,
         price      |-> price.value ], price.rest)

ZeroPriceLevelBuyUpdateMessage ==
    [ eventFlags |-> [i \in 1 .. 1 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0],
      symbol     |-> [i \in 1 .. 8 |-> 0],
      size       |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0] ]

(* Price Level Buy Update Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceLevelBuyUpdateMessage ==
    { ZeroPriceLevelBuyUpdateMessage }
        \cup { [ZeroPriceLevelBuyUpdateMessage EXCEPT !.eventFlags = one] : one \in Sample(1) }
        \cup { [ZeroPriceLevelBuyUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroPriceLevelBuyUpdateMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroPriceLevelBuyUpdateMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroPriceLevelBuyUpdateMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Price Level Sell Update Message: 29 bytes                               *)
(***************************************************************************)

PriceLevelSellUpdateMessage ==
    [ eventFlags : Sample(1),
      timestamp  : Sample(8),
      symbol     : Sample(8),
      size       : Sample(4),
      price      : Sample(8) ]

EncodePriceLevelSellUpdateMessage(message) ==
    message.eventFlags
        \o message.timestamp
        \o message.symbol
        \o message.size
        \o message.price

DecodePriceLevelSellUpdateMessage(bytes) ==
    LET eventFlags == ReadBytes(bytes, 1) IN IF ~eventFlags.ok THEN Fail ELSE
    LET timestamp == ReadBytes(eventFlags.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET size == ReadBytes(symbol.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET price == ReadBytes(size.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ eventFlags |-> eventFlags.value,
         timestamp  |-> timestamp.value,
         symbol     |-> symbol.value,
         size       |-> size.value,
         price      |-> price.value ], price.rest)

ZeroPriceLevelSellUpdateMessage ==
    [ eventFlags |-> [i \in 1 .. 1 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0],
      symbol     |-> [i \in 1 .. 8 |-> 0],
      size       |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0] ]

(* Price Level Sell Update Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceLevelSellUpdateMessage ==
    { ZeroPriceLevelSellUpdateMessage }
        \cup { [ZeroPriceLevelSellUpdateMessage EXCEPT !.eventFlags = one] : one \in Sample(1) }
        \cup { [ZeroPriceLevelSellUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroPriceLevelSellUpdateMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroPriceLevelSellUpdateMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroPriceLevelSellUpdateMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Report Message: 37 bytes                                          *)
(***************************************************************************)

TradeReportMessage ==
    [ saleConditionFlags : Sample(1),
      timestamp          : Sample(8),
      symbol             : Sample(8),
      size               : Sample(4),
      price              : Sample(8),
      tradeId            : Sample(8) ]

EncodeTradeReportMessage(message) ==
    message.saleConditionFlags
        \o message.timestamp
        \o message.symbol
        \o message.size
        \o message.price
        \o message.tradeId

DecodeTradeReportMessage(bytes) ==
    LET saleConditionFlags == ReadBytes(bytes, 1) IN IF ~saleConditionFlags.ok THEN Fail ELSE
    LET timestamp == ReadBytes(saleConditionFlags.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET size == ReadBytes(symbol.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET price == ReadBytes(size.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeId == ReadBytes(price.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    Ok([ saleConditionFlags |-> saleConditionFlags.value,
         timestamp          |-> timestamp.value,
         symbol             |-> symbol.value,
         size               |-> size.value,
         price              |-> price.value,
         tradeId            |-> tradeId.value ], tradeId.rest)

ZeroTradeReportMessage ==
    [ saleConditionFlags |-> [i \in 1 .. 1 |-> 0],
      timestamp          |-> [i \in 1 .. 8 |-> 0],
      symbol             |-> [i \in 1 .. 8 |-> 0],
      size               |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      tradeId            |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Report Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeReportMessage ==
    { ZeroTradeReportMessage }
        \cup { [ZeroTradeReportMessage EXCEPT !.saleConditionFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeReportMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroTradeReportMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeReportMessage EXCEPT !.tradeId = one] : one \in Sample(8) }

(***************************************************************************)
(* Official Price Message: 25 bytes                                        *)
(***************************************************************************)

OfficialPriceMessage ==
    [ priceType     : Sample(1),
      timestamp     : Sample(8),
      symbol        : Sample(8),
      officialPrice : Sample(8) ]

EncodeOfficialPriceMessage(message) ==
    message.priceType
        \o message.timestamp
        \o message.symbol
        \o message.officialPrice

DecodeOfficialPriceMessage(bytes) ==
    LET priceType == ReadBytes(bytes, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET timestamp == ReadBytes(priceType.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET officialPrice == ReadBytes(symbol.rest, 8) IN IF ~officialPrice.ok THEN Fail ELSE
    Ok([ priceType     |-> priceType.value,
         timestamp     |-> timestamp.value,
         symbol        |-> symbol.value,
         officialPrice |-> officialPrice.value ], officialPrice.rest)

ZeroOfficialPriceMessage ==
    [ priceType     |-> [i \in 1 .. 1 |-> 0],
      timestamp     |-> [i \in 1 .. 8 |-> 0],
      symbol        |-> [i \in 1 .. 8 |-> 0],
      officialPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Official Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOfficialPriceMessage ==
    { ZeroOfficialPriceMessage }
        \cup { [ZeroOfficialPriceMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroOfficialPriceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOfficialPriceMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOfficialPriceMessage EXCEPT !.officialPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Break Message: 37 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ saleConditionFlags : Sample(1),
      timestamp          : Sample(8),
      symbol             : Sample(8),
      size               : Sample(4),
      price              : Sample(8),
      tradeId            : Sample(8) ]

EncodeTradeBreakMessage(message) ==
    message.saleConditionFlags
        \o message.timestamp
        \o message.symbol
        \o message.size
        \o message.price
        \o message.tradeId

DecodeTradeBreakMessage(bytes) ==
    LET saleConditionFlags == ReadBytes(bytes, 1) IN IF ~saleConditionFlags.ok THEN Fail ELSE
    LET timestamp == ReadBytes(saleConditionFlags.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET size == ReadBytes(symbol.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET price == ReadBytes(size.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeId == ReadBytes(price.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    Ok([ saleConditionFlags |-> saleConditionFlags.value,
         timestamp          |-> timestamp.value,
         symbol             |-> symbol.value,
         size               |-> size.value,
         price              |-> price.value,
         tradeId            |-> tradeId.value ], tradeId.rest)

ZeroTradeBreakMessage ==
    [ saleConditionFlags |-> [i \in 1 .. 1 |-> 0],
      timestamp          |-> [i \in 1 .. 8 |-> 0],
      symbol             |-> [i \in 1 .. 8 |-> 0],
      size               |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      tradeId            |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.saleConditionFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.tradeId = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Information Message: 79 bytes                                   *)
(***************************************************************************)

AuctionInformationMessage ==
    [ auctionType              : Sample(1),
      timestamp                : Sample(8),
      symbol                   : Sample(8),
      pairedShares             : Sample(4),
      referencePrice           : Sample(8),
      indicativeClearingPrice  : Sample(8),
      imbalanceShares          : Sample(4),
      imbalanceSide            : Sample(1),
      extensionNumber          : Sample(1),
      scheduledAuctionTime     : Sample(4),
      auctionBookClearingPrice : Sample(8),
      collarReferencePrice     : Sample(8),
      lowerAuctionCollar       : Sample(8),
      upperAuctionCollar       : Sample(8) ]

EncodeAuctionInformationMessage(message) ==
    message.auctionType
        \o message.timestamp
        \o message.symbol
        \o message.pairedShares
        \o message.referencePrice
        \o message.indicativeClearingPrice
        \o message.imbalanceShares
        \o message.imbalanceSide
        \o message.extensionNumber
        \o message.scheduledAuctionTime
        \o message.auctionBookClearingPrice
        \o message.collarReferencePrice
        \o message.lowerAuctionCollar
        \o message.upperAuctionCollar

DecodeAuctionInformationMessage(bytes) ==
    LET auctionType == ReadBytes(bytes, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET timestamp == ReadBytes(auctionType.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET pairedShares == ReadBytes(symbol.rest, 4) IN IF ~pairedShares.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(pairedShares.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET indicativeClearingPrice == ReadBytes(referencePrice.rest, 8) IN IF ~indicativeClearingPrice.ok THEN Fail ELSE
    LET imbalanceShares == ReadBytes(indicativeClearingPrice.rest, 4) IN IF ~imbalanceShares.ok THEN Fail ELSE
    LET imbalanceSide == ReadBytes(imbalanceShares.rest, 1) IN IF ~imbalanceSide.ok THEN Fail ELSE
    LET extensionNumber == ReadBytes(imbalanceSide.rest, 1) IN IF ~extensionNumber.ok THEN Fail ELSE
    LET scheduledAuctionTime == ReadBytes(extensionNumber.rest, 4) IN IF ~scheduledAuctionTime.ok THEN Fail ELSE
    LET auctionBookClearingPrice == ReadBytes(scheduledAuctionTime.rest, 8) IN IF ~auctionBookClearingPrice.ok THEN Fail ELSE
    LET collarReferencePrice == ReadBytes(auctionBookClearingPrice.rest, 8) IN IF ~collarReferencePrice.ok THEN Fail ELSE
    LET lowerAuctionCollar == ReadBytes(collarReferencePrice.rest, 8) IN IF ~lowerAuctionCollar.ok THEN Fail ELSE
    LET upperAuctionCollar == ReadBytes(lowerAuctionCollar.rest, 8) IN IF ~upperAuctionCollar.ok THEN Fail ELSE
    Ok([ auctionType              |-> auctionType.value,
         timestamp                |-> timestamp.value,
         symbol                   |-> symbol.value,
         pairedShares             |-> pairedShares.value,
         referencePrice           |-> referencePrice.value,
         indicativeClearingPrice  |-> indicativeClearingPrice.value,
         imbalanceShares          |-> imbalanceShares.value,
         imbalanceSide            |-> imbalanceSide.value,
         extensionNumber          |-> extensionNumber.value,
         scheduledAuctionTime     |-> scheduledAuctionTime.value,
         auctionBookClearingPrice |-> auctionBookClearingPrice.value,
         collarReferencePrice     |-> collarReferencePrice.value,
         lowerAuctionCollar       |-> lowerAuctionCollar.value,
         upperAuctionCollar       |-> upperAuctionCollar.value ], upperAuctionCollar.rest)

ZeroAuctionInformationMessage ==
    [ auctionType              |-> [i \in 1 .. 1 |-> 0],
      timestamp                |-> [i \in 1 .. 8 |-> 0],
      symbol                   |-> [i \in 1 .. 8 |-> 0],
      pairedShares             |-> [i \in 1 .. 4 |-> 0],
      referencePrice           |-> [i \in 1 .. 8 |-> 0],
      indicativeClearingPrice  |-> [i \in 1 .. 8 |-> 0],
      imbalanceShares          |-> [i \in 1 .. 4 |-> 0],
      imbalanceSide            |-> [i \in 1 .. 1 |-> 0],
      extensionNumber          |-> [i \in 1 .. 1 |-> 0],
      scheduledAuctionTime     |-> [i \in 1 .. 4 |-> 0],
      auctionBookClearingPrice |-> [i \in 1 .. 8 |-> 0],
      collarReferencePrice     |-> [i \in 1 .. 8 |-> 0],
      lowerAuctionCollar       |-> [i \in 1 .. 8 |-> 0],
      upperAuctionCollar       |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Information Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionInformationMessage ==
    { ZeroAuctionInformationMessage }
        \cup { [ZeroAuctionInformationMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionInformationMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionInformationMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroAuctionInformationMessage EXCEPT !.pairedShares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInformationMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionInformationMessage EXCEPT !.indicativeClearingPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionInformationMessage EXCEPT !.imbalanceShares = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInformationMessage EXCEPT !.imbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroAuctionInformationMessage EXCEPT !.extensionNumber = one] : one \in Sample(1) }
        \cup { [ZeroAuctionInformationMessage EXCEPT !.scheduledAuctionTime = one] : one \in Sample(4) }
        \cup { [ZeroAuctionInformationMessage EXCEPT !.auctionBookClearingPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionInformationMessage EXCEPT !.collarReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionInformationMessage EXCEPT !.lowerAuctionCollar = one] : one \in Sample(8) }
        \cup { [ZeroAuctionInformationMessage EXCEPT !.upperAuctionCollar = one] : one \in Sample(8) }

(***************************************************************************)
(* Iex Tp Message Data, selected by Iex Tp Message Type                    *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
SecurityDirectoryMessageCode == 68  \* "D"
TradingStatusMessageCode == 72  \* "H"
RetailLiquidityIndicatorMessageCode == 73  \* "I"
OperationalHaltStatusMessageCode == 79  \* "O"
ShortSalePriceTestStatusMessageCode == 80  \* "P"
SecurityEventMessageCode == 69  \* "E"
PriceLevelBuyUpdateMessageCode == 56  \* "8"
PriceLevelSellUpdateMessageCode == 53  \* "5"
TradeReportMessageCode == 84  \* "T"
OfficialPriceMessageCode == 88  \* "X"
TradeBreakMessageCode == 66  \* "B"
AuctionInformationMessageCode == 65  \* "A"

IexTpMessageData ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {SecurityDirectoryMessageCode}, body : SecurityDirectoryMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {RetailLiquidityIndicatorMessageCode}, body : RetailLiquidityIndicatorMessage ]
        \cup [ tag : {OperationalHaltStatusMessageCode}, body : OperationalHaltStatusMessage ]
        \cup [ tag : {ShortSalePriceTestStatusMessageCode}, body : ShortSalePriceTestStatusMessage ]
        \cup [ tag : {SecurityEventMessageCode}, body : SecurityEventMessage ]
        \cup [ tag : {PriceLevelBuyUpdateMessageCode}, body : PriceLevelBuyUpdateMessage ]
        \cup [ tag : {PriceLevelSellUpdateMessageCode}, body : PriceLevelSellUpdateMessage ]
        \cup [ tag : {TradeReportMessageCode}, body : TradeReportMessage ]
        \cup [ tag : {OfficialPriceMessageCode}, body : OfficialPriceMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]
        \cup [ tag : {AuctionInformationMessageCode}, body : AuctionInformationMessage ]

EncodeIexTpMessageData(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = SecurityDirectoryMessageCode -> EncodeSecurityDirectoryMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = RetailLiquidityIndicatorMessageCode -> EncodeRetailLiquidityIndicatorMessage(message.body)
      [] message.tag = OperationalHaltStatusMessageCode -> EncodeOperationalHaltStatusMessage(message.body)
      [] message.tag = ShortSalePriceTestStatusMessageCode -> EncodeShortSalePriceTestStatusMessage(message.body)
      [] message.tag = SecurityEventMessageCode -> EncodeSecurityEventMessage(message.body)
      [] message.tag = PriceLevelBuyUpdateMessageCode -> EncodePriceLevelBuyUpdateMessage(message.body)
      [] message.tag = PriceLevelSellUpdateMessageCode -> EncodePriceLevelSellUpdateMessage(message.body)
      [] message.tag = TradeReportMessageCode -> EncodeTradeReportMessage(message.body)
      [] message.tag = OfficialPriceMessageCode -> EncodeOfficialPriceMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)
      [] message.tag = AuctionInformationMessageCode -> EncodeAuctionInformationMessage(message.body)

DecodeIexTpMessageData(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = SecurityDirectoryMessageCode -> DecodeSecurityDirectoryMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = RetailLiquidityIndicatorMessageCode -> DecodeRetailLiquidityIndicatorMessage(bytes)
              [] tag = OperationalHaltStatusMessageCode -> DecodeOperationalHaltStatusMessage(bytes)
              [] tag = ShortSalePriceTestStatusMessageCode -> DecodeShortSalePriceTestStatusMessage(bytes)
              [] tag = SecurityEventMessageCode -> DecodeSecurityEventMessage(bytes)
              [] tag = PriceLevelBuyUpdateMessageCode -> DecodePriceLevelBuyUpdateMessage(bytes)
              [] tag = PriceLevelSellUpdateMessageCode -> DecodePriceLevelSellUpdateMessage(bytes)
              [] tag = TradeReportMessageCode -> DecodeTradeReportMessage(bytes)
              [] tag = OfficialPriceMessageCode -> DecodeOfficialPriceMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] tag = AuctionInformationMessageCode -> DecodeAuctionInformationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroIexTpMessageData == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Iex Tp Message Data in turn, at the values the message it names is checked at *)
CheckedIexTpMessageData ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> SecurityDirectoryMessageCode, body |-> one] : one \in CheckedSecurityDirectoryMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> RetailLiquidityIndicatorMessageCode, body |-> one] : one \in CheckedRetailLiquidityIndicatorMessage }
        \cup { [tag |-> OperationalHaltStatusMessageCode, body |-> one] : one \in CheckedOperationalHaltStatusMessage }
        \cup { [tag |-> ShortSalePriceTestStatusMessageCode, body |-> one] : one \in CheckedShortSalePriceTestStatusMessage }
        \cup { [tag |-> SecurityEventMessageCode, body |-> one] : one \in CheckedSecurityEventMessage }
        \cup { [tag |-> PriceLevelBuyUpdateMessageCode, body |-> one] : one \in CheckedPriceLevelBuyUpdateMessage }
        \cup { [tag |-> PriceLevelSellUpdateMessageCode, body |-> one] : one \in CheckedPriceLevelSellUpdateMessage }
        \cup { [tag |-> TradeReportMessageCode, body |-> one] : one \in CheckedTradeReportMessage }
        \cup { [tag |-> OfficialPriceMessageCode, body |-> one] : one \in CheckedOfficialPriceMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }
        \cup { [tag |-> AuctionInformationMessageCode, body |-> one] : one \in CheckedAuctionInformationMessage }

(***************************************************************************)
(* Snapshot Data Message                                                   *)
(***************************************************************************)

SnapshotDataMessage ==
    [ iexTpHeader             : Sample(1),
      iexTpMessageBlockLength : Sample(2),
      iexTpMessageLength      : Sample(2),
      iexTpMessageData        : IexTpMessageData ]

EncodeSnapshotDataMessage(message) ==
    message.iexTpHeader
        \o message.iexTpMessageBlockLength
        \o message.iexTpMessageLength
        \o EncodeUIntLE(message.iexTpMessageData.tag, 1)
        \o EncodeIexTpMessageData(message.iexTpMessageData)

DecodeSnapshotDataMessage(bytes) ==
    LET iexTpHeader == ReadBytes(bytes, 1) IN IF ~iexTpHeader.ok THEN Fail ELSE
    LET iexTpMessageBlockLength == ReadBytes(iexTpHeader.rest, 2) IN IF ~iexTpMessageBlockLength.ok THEN Fail ELSE
    LET iexTpMessageLength == ReadBytes(iexTpMessageBlockLength.rest, 2) IN IF ~iexTpMessageLength.ok THEN Fail ELSE
    LET iexTpMessageType == ReadUIntLE(iexTpMessageLength.rest, 1) IN IF ~iexTpMessageType.ok THEN Fail ELSE
    LET iexTpMessageData == DecodeIexTpMessageData(iexTpMessageType.value, iexTpMessageType.rest) IN IF ~iexTpMessageData.ok THEN Fail ELSE
    Ok([ iexTpHeader             |-> iexTpHeader.value,
         iexTpMessageBlockLength |-> iexTpMessageBlockLength.value,
         iexTpMessageLength      |-> iexTpMessageLength.value,
         iexTpMessageData        |-> iexTpMessageData.value ], iexTpMessageData.rest)

ZeroSnapshotDataMessage ==
    [ iexTpHeader             |-> [i \in 1 .. 1 |-> 0],
      iexTpMessageBlockLength |-> [i \in 1 .. 2 |-> 0],
      iexTpMessageLength      |-> [i \in 1 .. 2 |-> 0],
      iexTpMessageData        |-> ZeroIexTpMessageData ]

(* Snapshot Data Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotDataMessage ==
    { ZeroSnapshotDataMessage }
        \cup { [ZeroSnapshotDataMessage EXCEPT !.iexTpHeader = one] : one \in Sample(1) }
        \cup { [ZeroSnapshotDataMessage EXCEPT !.iexTpMessageBlockLength = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotDataMessage EXCEPT !.iexTpMessageLength = one] : one \in Sample(2) }
        \cup { [ZeroSnapshotDataMessage EXCEPT !.iexTpMessageData = one] : one \in CheckedIexTpMessageData }

(***************************************************************************)
(* Snapshot End Message: 8 bytes                                           *)
(***************************************************************************)

SnapshotEndMessage ==
    [ snapshotSequenceNumber : Sample(8) ]

EncodeSnapshotEndMessage(message) ==
    message.snapshotSequenceNumber

DecodeSnapshotEndMessage(bytes) ==
    LET snapshotSequenceNumber == ReadBytes(bytes, 8) IN IF ~snapshotSequenceNumber.ok THEN Fail ELSE
    Ok([ snapshotSequenceNumber |-> snapshotSequenceNumber.value ], snapshotSequenceNumber.rest)

ZeroSnapshotEndMessage ==
    [ snapshotSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Snapshot End Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotEndMessage ==
    { ZeroSnapshotEndMessage }
        \cup { [ZeroSnapshotEndMessage EXCEPT !.snapshotSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Message Data, selected by Message Type                                  *)
(***************************************************************************)

SnapshotRequestMessageCode == 114  \* "r"
ErrorResponseMessageCode == 101  \* "e"
SnapshotStartMessageCode == 115  \* "s"
SnapshotDataMessageCode == 100  \* "d"
SnapshotEndMessageCode == 120  \* "x"

MessageData ==
    [ tag : {SnapshotRequestMessageCode}, body : SnapshotRequestMessage ]
        \cup [ tag : {ErrorResponseMessageCode}, body : ErrorResponseMessage ]
        \cup [ tag : {SnapshotStartMessageCode}, body : SnapshotStartMessage ]
        \cup [ tag : {SnapshotDataMessageCode}, body : SnapshotDataMessage ]
        \cup [ tag : {SnapshotEndMessageCode}, body : SnapshotEndMessage ]

EncodeMessageData(message) ==
    CASE message.tag = SnapshotRequestMessageCode -> EncodeSnapshotRequestMessage(message.body)
      [] message.tag = ErrorResponseMessageCode -> EncodeErrorResponseMessage(message.body)
      [] message.tag = SnapshotStartMessageCode -> EncodeSnapshotStartMessage(message.body)
      [] message.tag = SnapshotDataMessageCode -> EncodeSnapshotDataMessage(message.body)
      [] message.tag = SnapshotEndMessageCode -> EncodeSnapshotEndMessage(message.body)

DecodeMessageData(tag, bytes) ==
    LET read ==
            CASE tag = SnapshotRequestMessageCode -> DecodeSnapshotRequestMessage(bytes)
              [] tag = ErrorResponseMessageCode -> DecodeErrorResponseMessage(bytes)
              [] tag = SnapshotStartMessageCode -> DecodeSnapshotStartMessage(bytes)
              [] tag = SnapshotDataMessageCode -> DecodeSnapshotDataMessage(bytes)
              [] tag = SnapshotEndMessageCode -> DecodeSnapshotEndMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageData == [tag |-> SnapshotRequestMessageCode, body |-> ZeroSnapshotRequestMessage]

(* Each Message Data in turn, at the values the message it names is checked at *)
CheckedMessageData ==
    { [tag |-> SnapshotRequestMessageCode, body |-> one] : one \in CheckedSnapshotRequestMessage }
        \cup { [tag |-> ErrorResponseMessageCode, body |-> one] : one \in CheckedErrorResponseMessage }
        \cup { [tag |-> SnapshotStartMessageCode, body |-> one] : one \in CheckedSnapshotStartMessage }
        \cup { [tag |-> SnapshotDataMessageCode, body |-> one] : one \in CheckedSnapshotDataMessage }
        \cup { [tag |-> SnapshotEndMessageCode, body |-> one] : one \in CheckedSnapshotEndMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ messageData : MessageData ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.messageData.tag, 1)
        \o EncodeMessageData(message.messageData)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET messageData == DecodeMessageData(messageType.value, messageType.rest) IN IF ~messageData.ok THEN Fail ELSE
    Ok([ messageData |-> messageData.value ], messageData.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ messageData |-> ZeroMessageData ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.messageData = one] : one \in CheckedMessageData }

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
    { [ZeroMessage EXCEPT !.messageData = [tag |-> SnapshotRequestMessageCode, body |-> ZeroSnapshotRequestMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> ErrorResponseMessageCode, body |-> ZeroErrorResponseMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> SnapshotStartMessageCode, body |-> ZeroSnapshotStartMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> SnapshotDataMessageCode, body |-> ZeroSnapshotDataMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> SnapshotEndMessageCode, body |-> ZeroSnapshotEndMessage]] }

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
                /\ \A i \in 1 .. width : EncodeUIntLE(value, width)[i] \in Byte

(* Every Snapshot Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotRequestMessage ==
    \A message \in CheckedSnapshotRequestMessage :
        LET read == DecodeSnapshotRequestMessage(EncodeSnapshotRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Error Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripErrorResponseMessage ==
    \A message \in CheckedErrorResponseMessage :
        LET read == DecodeErrorResponseMessage(EncodeErrorResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Start Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotStartMessage ==
    \A message \in CheckedSnapshotStartMessage :
        LET read == DecodeSnapshotStartMessage(EncodeSnapshotStartMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDirectoryMessage ==
    \A message \in CheckedSecurityDirectoryMessage :
        LET read == DecodeSecurityDirectoryMessage(EncodeSecurityDirectoryMessage(message))
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

(* Every Retail Liquidity Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetailLiquidityIndicatorMessage ==
    \A message \in CheckedRetailLiquidityIndicatorMessage :
        LET read == DecodeRetailLiquidityIndicatorMessage(EncodeRetailLiquidityIndicatorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Operational Halt Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOperationalHaltStatusMessage ==
    \A message \in CheckedOperationalHaltStatusMessage :
        LET read == DecodeOperationalHaltStatusMessage(EncodeOperationalHaltStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Short Sale Price Test Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripShortSalePriceTestStatusMessage ==
    \A message \in CheckedShortSalePriceTestStatusMessage :
        LET read == DecodeShortSalePriceTestStatusMessage(EncodeShortSalePriceTestStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityEventMessage ==
    \A message \in CheckedSecurityEventMessage :
        LET read == DecodeSecurityEventMessage(EncodeSecurityEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Level Buy Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceLevelBuyUpdateMessage ==
    \A message \in CheckedPriceLevelBuyUpdateMessage :
        LET read == DecodePriceLevelBuyUpdateMessage(EncodePriceLevelBuyUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Level Sell Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceLevelSellUpdateMessage ==
    \A message \in CheckedPriceLevelSellUpdateMessage :
        LET read == DecodePriceLevelSellUpdateMessage(EncodePriceLevelSellUpdateMessage(message))
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

(* Every Official Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOfficialPriceMessage ==
    \A message \in CheckedOfficialPriceMessage :
        LET read == DecodeOfficialPriceMessage(EncodeOfficialPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBreakMessage ==
    \A message \in CheckedTradeBreakMessage :
        LET read == DecodeTradeBreakMessage(EncodeTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionInformationMessage ==
    \A message \in CheckedAuctionInformationMessage :
        LET read == DecodeAuctionInformationMessage(EncodeAuctionInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotDataMessage ==
    \A message \in CheckedSnapshotDataMessage :
        LET read == DecodeSnapshotDataMessage(EncodeSnapshotDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot End Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotEndMessage ==
    \A message \in CheckedSnapshotEndMessage :
        LET read == DecodeSnapshotEndMessage(EncodeSnapshotEndMessage(message))
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

(* A Iex Tp Message Data is selected by the Iex Tp Message Type it is written under *)
SelectsIexTpMessageData ==
    \A message \in IexTpMessageData :
        LET read == DecodeIexTpMessageData(message.tag, EncodeIexTpMessageData(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Message Data is selected by the Message Type it is written under *)
SelectsMessageData ==
    \A message \in MessageData :
        LET read == DecodeMessageData(message.tag, EncodeMessageData(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in Message :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
