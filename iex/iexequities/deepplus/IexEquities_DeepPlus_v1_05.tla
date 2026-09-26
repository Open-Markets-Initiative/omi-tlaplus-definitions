-------------------- MODULE IexEquities_DeepPlus_v1_05 ---------------------
(***************************************************************************)
(* Investors Exchange DeepPlus v1.05                                       *)
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
(* Note: Security Directory Flags is a bit field set, checked as its 1     *)
(* byte rather than bit by bit.                                            *)
(*                                                                         *)
(* Note: Modify Flags is a bit field set, checked as its 1 byte rather     *)
(* than bit by bit.                                                        *)
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
(* Add Order Message: 37 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ side      : Sample(1),
      timestamp : Sample(8),
      symbol    : Sample(8),
      orderId   : Sample(8),
      size      : Sample(4),
      price     : Sample(8) ]

EncodeAddOrderMessage(message) ==
    message.side
        \o message.timestamp
        \o message.symbol
        \o message.orderId
        \o message.size
        \o message.price

DecodeAddOrderMessage(bytes) ==
    LET side == ReadBytes(bytes, 1) IN IF ~side.ok THEN Fail ELSE
    LET timestamp == ReadBytes(side.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbol.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET size == ReadBytes(orderId.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET price == ReadBytes(size.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ side      |-> side.value,
         timestamp |-> timestamp.value,
         symbol    |-> symbol.value,
         orderId   |-> orderId.value,
         size      |-> size.value,
         price     |-> price.value ], price.rest)

ZeroAddOrderMessage ==
    [ side      |-> [i \in 1 .. 1 |-> 0],
      timestamp |-> [i \in 1 .. 8 |-> 0],
      symbol    |-> [i \in 1 .. 8 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      size      |-> [i \in 1 .. 4 |-> 0],
      price     |-> [i \in 1 .. 8 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Modify Message: 37 bytes                                          *)
(***************************************************************************)

OrderModifyMessage ==
    [ modifyFlags      : Sample(1),
      timestamp        : Sample(8),
      symbol           : Sample(8),
      orderIdReference : Sample(8),
      size             : Sample(4),
      price            : Sample(8) ]

EncodeOrderModifyMessage(message) ==
    message.modifyFlags
        \o message.timestamp
        \o message.symbol
        \o message.orderIdReference
        \o message.size
        \o message.price

DecodeOrderModifyMessage(bytes) ==
    LET modifyFlags == ReadBytes(bytes, 1) IN IF ~modifyFlags.ok THEN Fail ELSE
    LET timestamp == ReadBytes(modifyFlags.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET orderIdReference == ReadBytes(symbol.rest, 8) IN IF ~orderIdReference.ok THEN Fail ELSE
    LET size == ReadBytes(orderIdReference.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET price == ReadBytes(size.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ modifyFlags      |-> modifyFlags.value,
         timestamp        |-> timestamp.value,
         symbol           |-> symbol.value,
         orderIdReference |-> orderIdReference.value,
         size             |-> size.value,
         price            |-> price.value ], price.rest)

ZeroOrderModifyMessage ==
    [ modifyFlags      |-> [i \in 1 .. 1 |-> 0],
      timestamp        |-> [i \in 1 .. 8 |-> 0],
      symbol           |-> [i \in 1 .. 8 |-> 0],
      orderIdReference |-> [i \in 1 .. 8 |-> 0],
      size             |-> [i \in 1 .. 4 |-> 0],
      price            |-> [i \in 1 .. 8 |-> 0] ]

(* Order Modify Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyMessage ==
    { ZeroOrderModifyMessage }
        \cup { [ZeroOrderModifyMessage EXCEPT !.modifyFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.orderIdReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Delete Message: 25 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ reserved1        : Sample(1),
      timestamp        : Sample(8),
      symbol           : Sample(8),
      orderIdReference : Sample(8) ]

EncodeOrderDeleteMessage(message) ==
    message.reserved1
        \o message.timestamp
        \o message.symbol
        \o message.orderIdReference

DecodeOrderDeleteMessage(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET timestamp == ReadBytes(reserved1.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET orderIdReference == ReadBytes(symbol.rest, 8) IN IF ~orderIdReference.ok THEN Fail ELSE
    Ok([ reserved1        |-> reserved1.value,
         timestamp        |-> timestamp.value,
         symbol           |-> symbol.value,
         orderIdReference |-> orderIdReference.value ], orderIdReference.rest)

ZeroOrderDeleteMessage ==
    [ reserved1        |-> [i \in 1 .. 1 |-> 0],
      timestamp        |-> [i \in 1 .. 8 |-> 0],
      symbol           |-> [i \in 1 .. 8 |-> 0],
      orderIdReference |-> [i \in 1 .. 8 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderIdReference = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Executed Message: 45 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ saleConditionFlags : Sample(1),
      timestamp          : Sample(8),
      symbol             : Sample(8),
      orderIdReference   : Sample(8),
      size               : Sample(4),
      price              : Sample(8),
      tradeId            : Sample(8) ]

EncodeOrderExecutedMessage(message) ==
    message.saleConditionFlags
        \o message.timestamp
        \o message.symbol
        \o message.orderIdReference
        \o message.size
        \o message.price
        \o message.tradeId

DecodeOrderExecutedMessage(bytes) ==
    LET saleConditionFlags == ReadBytes(bytes, 1) IN IF ~saleConditionFlags.ok THEN Fail ELSE
    LET timestamp == ReadBytes(saleConditionFlags.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET orderIdReference == ReadBytes(symbol.rest, 8) IN IF ~orderIdReference.ok THEN Fail ELSE
    LET size == ReadBytes(orderIdReference.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET price == ReadBytes(size.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeId == ReadBytes(price.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    Ok([ saleConditionFlags |-> saleConditionFlags.value,
         timestamp          |-> timestamp.value,
         symbol             |-> symbol.value,
         orderIdReference   |-> orderIdReference.value,
         size               |-> size.value,
         price              |-> price.value,
         tradeId            |-> tradeId.value ], tradeId.rest)

ZeroOrderExecutedMessage ==
    [ saleConditionFlags |-> [i \in 1 .. 1 |-> 0],
      timestamp          |-> [i \in 1 .. 8 |-> 0],
      symbol             |-> [i \in 1 .. 8 |-> 0],
      orderIdReference   |-> [i \in 1 .. 8 |-> 0],
      size               |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      tradeId            |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.saleConditionFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderIdReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeId = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 37 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ saleConditionFlags : Sample(1),
      timestamp          : Sample(8),
      symbol             : Sample(8),
      size               : Sample(4),
      price              : Sample(8),
      tradeId            : Sample(8) ]

EncodeTradeMessage(message) ==
    message.saleConditionFlags
        \o message.timestamp
        \o message.symbol
        \o message.size
        \o message.price
        \o message.tradeId

DecodeTradeMessage(bytes) ==
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

ZeroTradeMessage ==
    [ saleConditionFlags |-> [i \in 1 .. 1 |-> 0],
      timestamp          |-> [i \in 1 .. 8 |-> 0],
      symbol             |-> [i \in 1 .. 8 |-> 0],
      size               |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      tradeId            |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.saleConditionFlags = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }

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
(* Clear Book Message: 17 bytes                                            *)
(***************************************************************************)

ClearBookMessage ==
    [ reserved1 : Sample(1),
      timestamp : Sample(8),
      symbol    : Sample(8) ]

EncodeClearBookMessage(message) ==
    message.reserved1
        \o message.timestamp
        \o message.symbol

DecodeClearBookMessage(bytes) ==
    LET reserved1 == ReadBytes(bytes, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET timestamp == ReadBytes(reserved1.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ reserved1 |-> reserved1.value,
         timestamp |-> timestamp.value,
         symbol    |-> symbol.value ], symbol.rest)

ZeroClearBookMessage ==
    [ reserved1 |-> [i \in 1 .. 1 |-> 0],
      timestamp |-> [i \in 1 .. 8 |-> 0],
      symbol    |-> [i \in 1 .. 8 |-> 0] ]

(* Clear Book Message at zero, then each field in turn at the values it is checked at *)
CheckedClearBookMessage ==
    { ZeroClearBookMessage }
        \cup { [ZeroClearBookMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroClearBookMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroClearBookMessage EXCEPT !.symbol = one] : one \in Sample(8) }

(***************************************************************************)
(* Message Data, selected by Message Type                                  *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
SecurityDirectoryMessageCode == 68  \* "D"
TradingStatusMessageCode == 72  \* "H"
RetailLiquidityIndicatorMessageCode == 73  \* "I"
OperationalHaltStatusMessageCode == 79  \* "O"
ShortSalePriceTestStatusMessageCode == 80  \* "P"
SecurityEventMessageCode == 69  \* "E"
AddOrderMessageCode == 97  \* "a"
OrderModifyMessageCode == 77  \* "M"
OrderDeleteMessageCode == 82  \* "R"
OrderExecutedMessageCode == 76  \* "L"
TradeMessageCode == 84  \* "T"
TradeBreakMessageCode == 66  \* "B"
ClearBookMessageCode == 67  \* "C"

MessageData ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {SecurityDirectoryMessageCode}, body : SecurityDirectoryMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {RetailLiquidityIndicatorMessageCode}, body : RetailLiquidityIndicatorMessage ]
        \cup [ tag : {OperationalHaltStatusMessageCode}, body : OperationalHaltStatusMessage ]
        \cup [ tag : {ShortSalePriceTestStatusMessageCode}, body : ShortSalePriceTestStatusMessage ]
        \cup [ tag : {SecurityEventMessageCode}, body : SecurityEventMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {OrderModifyMessageCode}, body : OrderModifyMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]
        \cup [ tag : {ClearBookMessageCode}, body : ClearBookMessage ]

EncodeMessageData(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = SecurityDirectoryMessageCode -> EncodeSecurityDirectoryMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = RetailLiquidityIndicatorMessageCode -> EncodeRetailLiquidityIndicatorMessage(message.body)
      [] message.tag = OperationalHaltStatusMessageCode -> EncodeOperationalHaltStatusMessage(message.body)
      [] message.tag = ShortSalePriceTestStatusMessageCode -> EncodeShortSalePriceTestStatusMessage(message.body)
      [] message.tag = SecurityEventMessageCode -> EncodeSecurityEventMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = OrderModifyMessageCode -> EncodeOrderModifyMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)
      [] message.tag = ClearBookMessageCode -> EncodeClearBookMessage(message.body)

DecodeMessageData(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = SecurityDirectoryMessageCode -> DecodeSecurityDirectoryMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = RetailLiquidityIndicatorMessageCode -> DecodeRetailLiquidityIndicatorMessage(bytes)
              [] tag = OperationalHaltStatusMessageCode -> DecodeOperationalHaltStatusMessage(bytes)
              [] tag = ShortSalePriceTestStatusMessageCode -> DecodeShortSalePriceTestStatusMessage(bytes)
              [] tag = SecurityEventMessageCode -> DecodeSecurityEventMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = OrderModifyMessageCode -> DecodeOrderModifyMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] tag = ClearBookMessageCode -> DecodeClearBookMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageData == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Message Data in turn, at the values the message it names is checked at *)
CheckedMessageData ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> SecurityDirectoryMessageCode, body |-> one] : one \in CheckedSecurityDirectoryMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> RetailLiquidityIndicatorMessageCode, body |-> one] : one \in CheckedRetailLiquidityIndicatorMessage }
        \cup { [tag |-> OperationalHaltStatusMessageCode, body |-> one] : one \in CheckedOperationalHaltStatusMessage }
        \cup { [tag |-> ShortSalePriceTestStatusMessageCode, body |-> one] : one \in CheckedShortSalePriceTestStatusMessage }
        \cup { [tag |-> SecurityEventMessageCode, body |-> one] : one \in CheckedSecurityEventMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> OrderModifyMessageCode, body |-> one] : one \in CheckedOrderModifyMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }
        \cup { [tag |-> ClearBookMessageCode, body |-> one] : one \in CheckedClearBookMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ messageData : MessageData ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.messageData.tag, 1)
        \o EncodeMessageData(message.messageData)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
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
    { [ZeroMessage EXCEPT !.messageData = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> SecurityDirectoryMessageCode, body |-> ZeroSecurityDirectoryMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> RetailLiquidityIndicatorMessageCode, body |-> ZeroRetailLiquidityIndicatorMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> OperationalHaltStatusMessageCode, body |-> ZeroOperationalHaltStatusMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> ShortSalePriceTestStatusMessageCode, body |-> ZeroShortSalePriceTestStatusMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> SecurityEventMessageCode, body |-> ZeroSecurityEventMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> OrderModifyMessageCode, body |-> ZeroOrderModifyMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> OrderDeleteMessageCode, body |-> ZeroOrderDeleteMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> TradeBreakMessageCode, body |-> ZeroTradeBreakMessage]],
      [ZeroMessage EXCEPT !.messageData = [tag |-> ClearBookMessageCode, body |-> ZeroClearBookMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ version                    : Sample(1),
      reserved                   : Sample(1),
      messageProtocolId          : Sample(2),
      channelId                  : Sample(4),
      sessionId                  : Sample(4),
      streamOffset               : Sample(8),
      firstMessageSequenceNumber : Sample(8),
      sendTime                   : Sample(8),
      message                    : SampleLists(OneMessage) ]

EncodePacket(message) ==
    LET payload == EncodeMessageList(message.message)
    IN  message.version
            \o message.reserved
            \o message.messageProtocolId
            \o message.channelId
            \o message.sessionId
            \o EncodeUIntLE(Len(payload), 2)
            \o EncodeUIntLE(Len(message.message), 2)
            \o message.streamOffset
            \o message.firstMessageSequenceNumber
            \o message.sendTime
            \o payload

DecodePacket(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    LET reserved == ReadBytes(version.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET messageProtocolId == ReadBytes(reserved.rest, 2) IN IF ~messageProtocolId.ok THEN Fail ELSE
    LET channelId == ReadBytes(messageProtocolId.rest, 4) IN IF ~channelId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(channelId.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET payloadLength == ReadUIntLE(sessionId.rest, 2) IN IF ~payloadLength.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(payloadLength.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET streamOffset == ReadBytes(messageCount.rest, 8) IN IF ~streamOffset.ok THEN Fail ELSE
    LET firstMessageSequenceNumber == ReadBytes(streamOffset.rest, 8) IN IF ~firstMessageSequenceNumber.ok THEN Fail ELSE
    LET sendTime == ReadBytes(firstMessageSequenceNumber.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    IF Len(sendTime.rest) < payloadLength.value THEN Fail ELSE
    LET framed == SubSeq(sendTime.rest, 1, payloadLength.value)
        beyond == SubSeq(sendTime.rest, payloadLength.value + 1, Len(sendTime.rest))
        message == ReadMessageList(framed, messageCount.value)
    IN  IF ~message.ok \/ message.rest # << >> THEN Fail ELSE
    Ok([ version                    |-> version.value,
         reserved                   |-> reserved.value,
         messageProtocolId          |-> messageProtocolId.value,
         channelId                  |-> channelId.value,
         sessionId                  |-> sessionId.value,
         streamOffset               |-> streamOffset.value,
         firstMessageSequenceNumber |-> firstMessageSequenceNumber.value,
         sendTime                   |-> sendTime.value,
         message                    |-> message.value ], beyond)

ZeroPacket ==
    [ version                    |-> [i \in 1 .. 1 |-> 0],
      reserved                   |-> [i \in 1 .. 1 |-> 0],
      messageProtocolId          |-> [i \in 1 .. 2 |-> 0],
      channelId                  |-> [i \in 1 .. 4 |-> 0],
      sessionId                  |-> [i \in 1 .. 4 |-> 0],
      streamOffset               |-> [i \in 1 .. 8 |-> 0],
      firstMessageSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      sendTime                   |-> [i \in 1 .. 8 |-> 0],
      message                    |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.messageProtocolId = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.channelId = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.streamOffset = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.firstMessageSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(8) }
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

(* Every Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessage ==
    \A message \in CheckedAddOrderMessage :
        LET read == DecodeAddOrderMessage(EncodeAddOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifyMessage ==
    \A message \in CheckedOrderModifyMessage :
        LET read == DecodeOrderModifyMessage(EncodeOrderModifyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeleteMessage ==
    \A message \in CheckedOrderDeleteMessage :
        LET read == DecodeOrderDeleteMessage(EncodeOrderDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedMessage ==
    \A message \in CheckedOrderExecutedMessage :
        LET read == DecodeOrderExecutedMessage(EncodeOrderExecutedMessage(message))
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

(* Every Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBreakMessage ==
    \A message \in CheckedTradeBreakMessage :
        LET read == DecodeTradeBreakMessage(EncodeTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clear Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClearBookMessage ==
    \A message \in CheckedClearBookMessage :
        LET read == DecodeClearBookMessage(EncodeClearBookMessage(message))
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

(* A Message Data is selected by the Message Type it is written under *)
SelectsMessageData ==
    \A message \in CheckedMessageData :
        LET read == DecodeMessageData(message.tag, EncodeMessageData(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
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
