----------------- MODULE BlueEquities_MemoirDepthFeed_v1_3 -----------------
(***************************************************************************)
(* Blue Ocean Technologies Member Order Information Record Depth Feed v1.3 *)
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
(* Instrument Directory Message: 36 bytes                                  *)
(***************************************************************************)

InstrumentDirectoryMessage ==
    [ timestamp    : Sample(8),
      securityId   : Sample(2),
      symbol       : Sample(6),
      symbolSfx    : Sample(6),
      roundLot     : Sample(4),
      reserved     : Sample(1),
      isTestSymbol : Sample(1),
      mpv          : Sample(8) ]

EncodeInstrumentDirectoryMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.symbol
        \o message.symbolSfx
        \o message.roundLot
        \o message.reserved
        \o message.isTestSymbol
        \o message.mpv

DecodeInstrumentDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET symbol == ReadBytes(securityId.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET roundLot == ReadBytes(symbolSfx.rest, 4) IN IF ~roundLot.ok THEN Fail ELSE
    LET reserved == ReadBytes(roundLot.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET isTestSymbol == ReadBytes(reserved.rest, 1) IN IF ~isTestSymbol.ok THEN Fail ELSE
    LET mpv == ReadBytes(isTestSymbol.rest, 8) IN IF ~mpv.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         securityId   |-> securityId.value,
         symbol       |-> symbol.value,
         symbolSfx    |-> symbolSfx.value,
         roundLot     |-> roundLot.value,
         reserved     |-> reserved.value,
         isTestSymbol |-> isTestSymbol.value,
         mpv          |-> mpv.value ], mpv.rest)

ZeroInstrumentDirectoryMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      securityId   |-> [i \in 1 .. 2 |-> 0],
      symbol       |-> [i \in 1 .. 6 |-> 0],
      symbolSfx    |-> [i \in 1 .. 6 |-> 0],
      roundLot     |-> [i \in 1 .. 4 |-> 0],
      reserved     |-> [i \in 1 .. 1 |-> 0],
      isTestSymbol |-> [i \in 1 .. 1 |-> 0],
      mpv          |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDirectoryMessage ==
    { ZeroInstrumentDirectoryMessage }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.roundLot = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.isTestSymbol = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.mpv = one] : one \in Sample(8) }

(***************************************************************************)
(* Reg Sho Restriction Message: 11 bytes                                   *)
(***************************************************************************)

RegShoRestrictionMessage ==
    [ timestamp            : Sample(8),
      securityId           : Sample(2),
      shortSaleRestriction : Sample(1) ]

EncodeRegShoRestrictionMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.shortSaleRestriction

DecodeRegShoRestrictionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET shortSaleRestriction == ReadBytes(securityId.rest, 1) IN IF ~shortSaleRestriction.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         securityId           |-> securityId.value,
         shortSaleRestriction |-> shortSaleRestriction.value ], shortSaleRestriction.rest)

ZeroRegShoRestrictionMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      securityId           |-> [i \in 1 .. 2 |-> 0],
      shortSaleRestriction |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Restriction Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoRestrictionMessage ==
    { ZeroRegShoRestrictionMessage }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.shortSaleRestriction = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Trading Status Message: 12 bytes                               *)
(***************************************************************************)

SecurityTradingStatusMessage ==
    [ timestamp                   : Sample(8),
      securityId                  : Sample(2),
      securityTradingStatus       : Sample(1),
      securityTradingStatusReason : Sample(1) ]

EncodeSecurityTradingStatusMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.securityTradingStatus
        \o message.securityTradingStatusReason

DecodeSecurityTradingStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityId.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET securityTradingStatusReason == ReadBytes(securityTradingStatus.rest, 1) IN IF ~securityTradingStatusReason.ok THEN Fail ELSE
    Ok([ timestamp                   |-> timestamp.value,
         securityId                  |-> securityId.value,
         securityTradingStatus       |-> securityTradingStatus.value,
         securityTradingStatusReason |-> securityTradingStatusReason.value ], securityTradingStatusReason.rest)

ZeroSecurityTradingStatusMessage ==
    [ timestamp                   |-> [i \in 1 .. 8 |-> 0],
      securityId                  |-> [i \in 1 .. 2 |-> 0],
      securityTradingStatus       |-> [i \in 1 .. 1 |-> 0],
      securityTradingStatusReason |-> [i \in 1 .. 1 |-> 0] ]

(* Security Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityTradingStatusMessage ==
    { ZeroSecurityTradingStatusMessage }
        \cup { [ZeroSecurityTradingStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSecurityTradingStatusMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroSecurityTradingStatusMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityTradingStatusMessage EXCEPT !.securityTradingStatusReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Session Status Message: 9 bytes                                 *)
(***************************************************************************)

TradingSessionStatusMessage ==
    [ timestamp      : Sample(8),
      tradingSession : Sample(1) ]

EncodeTradingSessionStatusMessage(message) ==
    message.timestamp
        \o message.tradingSession

DecodeTradingSessionStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradingSession == ReadBytes(timestamp.rest, 1) IN IF ~tradingSession.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         tradingSession |-> tradingSession.value ], tradingSession.rest)

ZeroTradingSessionStatusMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      tradingSession |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Session Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionStatusMessage ==
    { ZeroTradingSessionStatusMessage }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradingSession = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Added Message: 31 bytes                                           *)
(***************************************************************************)

OrderAddedMessage ==
    [ timestamp  : Sample(8),
      securityId : Sample(2),
      orderId    : Sample(8),
      side       : Sample(1),
      quantity   : Sample(4),
      price      : Sample(8) ]

EncodeOrderAddedMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.orderId
        \o message.side
        \o message.quantity
        \o message.price

DecodeOrderAddedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         securityId |-> securityId.value,
         orderId    |-> orderId.value,
         side       |-> side.value,
         quantity   |-> quantity.value,
         price      |-> price.value ], price.rest)

ZeroOrderAddedMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      securityId |-> [i \in 1 .. 2 |-> 0],
      orderId    |-> [i \in 1 .. 8 |-> 0],
      side       |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0] ]

(* Order Added Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddedMessage ==
    { ZeroOrderAddedMessage }
        \cup { [ZeroOrderAddedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddedMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Deleted Message: 18 bytes                                         *)
(***************************************************************************)

OrderDeletedMessage ==
    [ timestamp  : Sample(8),
      securityId : Sample(2),
      orderId    : Sample(8) ]

EncodeOrderDeletedMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.orderId

DecodeOrderDeletedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         securityId |-> securityId.value,
         orderId    |-> orderId.value ], orderId.rest)

ZeroOrderDeletedMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      securityId |-> [i \in 1 .. 2 |-> 0],
      orderId    |-> [i \in 1 .. 8 |-> 0] ]

(* Order Deleted Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeletedMessage ==
    { ZeroOrderDeletedMessage }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Reduced Message: 22 bytes                                         *)
(***************************************************************************)

OrderReducedMessage ==
    [ timestamp  : Sample(8),
      securityId : Sample(2),
      orderId    : Sample(8),
      quantity   : Sample(4) ]

EncodeOrderReducedMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.orderId
        \o message.quantity

DecodeOrderReducedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         securityId |-> securityId.value,
         orderId    |-> orderId.value,
         quantity   |-> quantity.value ], quantity.rest)

ZeroOrderReducedMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      securityId |-> [i \in 1 .. 2 |-> 0],
      orderId    |-> [i \in 1 .. 8 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0] ]

(* Order Reduced Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReducedMessage ==
    { ZeroOrderReducedMessage }
        \cup { [ZeroOrderReducedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderReducedMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroOrderReducedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReducedMessage EXCEPT !.quantity = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed Message: 38 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timestamp  : Sample(8),
      securityId : Sample(2),
      orderId    : Sample(8),
      tradeId    : Sample(8),
      quantity   : Sample(4),
      price      : Sample(8) ]

EncodeOrderExecutedMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.orderId
        \o message.tradeId
        \o message.quantity
        \o message.price

DecodeOrderExecutedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(orderId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradeId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         securityId |-> securityId.value,
         orderId    |-> orderId.value,
         tradeId    |-> tradeId.value,
         quantity   |-> quantity.value,
         price      |-> price.value ], price.rest)

ZeroOrderExecutedMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      securityId |-> [i \in 1 .. 2 |-> 0],
      orderId    |-> [i \in 1 .. 8 |-> 0],
      tradeId    |-> [i \in 1 .. 8 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 30 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ timestamp  : Sample(8),
      securityId : Sample(2),
      tradeId    : Sample(8),
      quantity   : Sample(4),
      price      : Sample(8) ]

EncodeTradeMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.tradeId
        \o message.quantity
        \o message.price

DecodeTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(securityId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradeId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         securityId |-> securityId.value,
         tradeId    |-> tradeId.value,
         quantity   |-> quantity.value,
         price      |-> price.value ], price.rest)

ZeroTradeMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      securityId |-> [i \in 1 .. 2 |-> 0],
      tradeId    |-> [i \in 1 .. 8 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Broken Trade Message: 30 bytes                                          *)
(***************************************************************************)

BrokenTradeMessage ==
    [ timestamp        : Sample(8),
      securityId       : Sample(2),
      tradeId          : Sample(8),
      originalQuantity : Sample(4),
      originalPrice    : Sample(8) ]

EncodeBrokenTradeMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.tradeId
        \o message.originalQuantity
        \o message.originalPrice

DecodeBrokenTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(securityId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET originalQuantity == ReadBytes(tradeId.rest, 4) IN IF ~originalQuantity.ok THEN Fail ELSE
    LET originalPrice == ReadBytes(originalQuantity.rest, 8) IN IF ~originalPrice.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         securityId       |-> securityId.value,
         tradeId          |-> tradeId.value,
         originalQuantity |-> originalQuantity.value,
         originalPrice    |-> originalPrice.value ], originalPrice.rest)

ZeroBrokenTradeMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      securityId       |-> [i \in 1 .. 2 |-> 0],
      tradeId          |-> [i \in 1 .. 8 |-> 0],
      originalQuantity |-> [i \in 1 .. 4 |-> 0],
      originalPrice    |-> [i \in 1 .. 8 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.originalQuantity = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.originalPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Corrected Trade Message: 42 bytes                                       *)
(***************************************************************************)

CorrectedTradeMessage ==
    [ timestamp         : Sample(8),
      securityId        : Sample(2),
      tradeId           : Sample(8),
      originalQuantity  : Sample(4),
      originalPrice     : Sample(8),
      correctedQuantity : Sample(4),
      correctedPrice    : Sample(8) ]

EncodeCorrectedTradeMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.tradeId
        \o message.originalQuantity
        \o message.originalPrice
        \o message.correctedQuantity
        \o message.correctedPrice

DecodeCorrectedTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(securityId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET originalQuantity == ReadBytes(tradeId.rest, 4) IN IF ~originalQuantity.ok THEN Fail ELSE
    LET originalPrice == ReadBytes(originalQuantity.rest, 8) IN IF ~originalPrice.ok THEN Fail ELSE
    LET correctedQuantity == ReadBytes(originalPrice.rest, 4) IN IF ~correctedQuantity.ok THEN Fail ELSE
    LET correctedPrice == ReadBytes(correctedQuantity.rest, 8) IN IF ~correctedPrice.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         securityId        |-> securityId.value,
         tradeId           |-> tradeId.value,
         originalQuantity  |-> originalQuantity.value,
         originalPrice     |-> originalPrice.value,
         correctedQuantity |-> correctedQuantity.value,
         correctedPrice    |-> correctedPrice.value ], correctedPrice.rest)

ZeroCorrectedTradeMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      securityId        |-> [i \in 1 .. 2 |-> 0],
      tradeId           |-> [i \in 1 .. 8 |-> 0],
      originalQuantity  |-> [i \in 1 .. 4 |-> 0],
      originalPrice     |-> [i \in 1 .. 8 |-> 0],
      correctedQuantity |-> [i \in 1 .. 4 |-> 0],
      correctedPrice    |-> [i \in 1 .. 8 |-> 0] ]

(* Corrected Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedCorrectedTradeMessage ==
    { ZeroCorrectedTradeMessage }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.originalQuantity = one] : one \in Sample(4) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.originalPrice = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.correctedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.correctedPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Clear Book Message: 10 bytes                                            *)
(***************************************************************************)

ClearBookMessage ==
    [ timestamp  : Sample(8),
      securityId : Sample(2) ]

EncodeClearBookMessage(message) ==
    message.timestamp
        \o message.securityId

DecodeClearBookMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         securityId |-> securityId.value ], securityId.rest)

ZeroClearBookMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      securityId |-> [i \in 1 .. 2 |-> 0] ]

(* Clear Book Message at zero, then each field in turn at the values it is checked at *)
CheckedClearBookMessage ==
    { ZeroClearBookMessage }
        \cup { [ZeroClearBookMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroClearBookMessage EXCEPT !.securityId = one] : one \in Sample(2) }

(***************************************************************************)
(* Snapshot Complete Message: 16 bytes                                     *)
(***************************************************************************)

SnapshotCompleteMessage ==
    [ timestamp          : Sample(8),
      asOfSequenceNumber : Sample(8) ]

EncodeSnapshotCompleteMessage(message) ==
    message.timestamp
        \o message.asOfSequenceNumber

DecodeSnapshotCompleteMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET asOfSequenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~asOfSequenceNumber.ok THEN Fail ELSE
    Ok([ timestamp          |-> timestamp.value,
         asOfSequenceNumber |-> asOfSequenceNumber.value ], asOfSequenceNumber.rest)

ZeroSnapshotCompleteMessage ==
    [ timestamp          |-> [i \in 1 .. 8 |-> 0],
      asOfSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Snapshot Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotCompleteMessage ==
    { ZeroSnapshotCompleteMessage }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSnapshotCompleteMessage EXCEPT !.asOfSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

InstrumentDirectoryMessageCode == 1  \* 0x01
RegShoRestrictionMessageCode == 2  \* 0x02
SecurityTradingStatusMessageCode == 3  \* 0x03
TradingSessionStatusMessageCode == 5  \* 0x05
OrderAddedMessageCode == 10  \* 0x0a
OrderDeletedMessageCode == 11  \* 0x0b
OrderReducedMessageCode == 12  \* 0x0c
OrderExecutedMessageCode == 13  \* 0x0d
TradeMessageCode == 14  \* 0x0e
BrokenTradeMessageCode == 15  \* 0x0f
CorrectedTradeMessageCode == 16  \* 0x10
ClearBookMessageCode == 18  \* 0x12
SnapshotCompleteMessageCode == 100  \* 0x64

Payload ==
    [ tag : {InstrumentDirectoryMessageCode}, body : InstrumentDirectoryMessage ]
        \cup [ tag : {RegShoRestrictionMessageCode}, body : RegShoRestrictionMessage ]
        \cup [ tag : {SecurityTradingStatusMessageCode}, body : SecurityTradingStatusMessage ]
        \cup [ tag : {TradingSessionStatusMessageCode}, body : TradingSessionStatusMessage ]
        \cup [ tag : {OrderAddedMessageCode}, body : OrderAddedMessage ]
        \cup [ tag : {OrderDeletedMessageCode}, body : OrderDeletedMessage ]
        \cup [ tag : {OrderReducedMessageCode}, body : OrderReducedMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {CorrectedTradeMessageCode}, body : CorrectedTradeMessage ]
        \cup [ tag : {ClearBookMessageCode}, body : ClearBookMessage ]
        \cup [ tag : {SnapshotCompleteMessageCode}, body : SnapshotCompleteMessage ]

EncodePayload(message) ==
    CASE message.tag = InstrumentDirectoryMessageCode -> EncodeInstrumentDirectoryMessage(message.body)
      [] message.tag = RegShoRestrictionMessageCode -> EncodeRegShoRestrictionMessage(message.body)
      [] message.tag = SecurityTradingStatusMessageCode -> EncodeSecurityTradingStatusMessage(message.body)
      [] message.tag = TradingSessionStatusMessageCode -> EncodeTradingSessionStatusMessage(message.body)
      [] message.tag = OrderAddedMessageCode -> EncodeOrderAddedMessage(message.body)
      [] message.tag = OrderDeletedMessageCode -> EncodeOrderDeletedMessage(message.body)
      [] message.tag = OrderReducedMessageCode -> EncodeOrderReducedMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = CorrectedTradeMessageCode -> EncodeCorrectedTradeMessage(message.body)
      [] message.tag = ClearBookMessageCode -> EncodeClearBookMessage(message.body)
      [] message.tag = SnapshotCompleteMessageCode -> EncodeSnapshotCompleteMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = InstrumentDirectoryMessageCode -> DecodeInstrumentDirectoryMessage(bytes)
              [] tag = RegShoRestrictionMessageCode -> DecodeRegShoRestrictionMessage(bytes)
              [] tag = SecurityTradingStatusMessageCode -> DecodeSecurityTradingStatusMessage(bytes)
              [] tag = TradingSessionStatusMessageCode -> DecodeTradingSessionStatusMessage(bytes)
              [] tag = OrderAddedMessageCode -> DecodeOrderAddedMessage(bytes)
              [] tag = OrderDeletedMessageCode -> DecodeOrderDeletedMessage(bytes)
              [] tag = OrderReducedMessageCode -> DecodeOrderReducedMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = CorrectedTradeMessageCode -> DecodeCorrectedTradeMessage(bytes)
              [] tag = ClearBookMessageCode -> DecodeClearBookMessage(bytes)
              [] tag = SnapshotCompleteMessageCode -> DecodeSnapshotCompleteMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> InstrumentDirectoryMessageCode, body |-> ZeroInstrumentDirectoryMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> InstrumentDirectoryMessageCode, body |-> one] : one \in CheckedInstrumentDirectoryMessage }
        \cup { [tag |-> RegShoRestrictionMessageCode, body |-> one] : one \in CheckedRegShoRestrictionMessage }
        \cup { [tag |-> SecurityTradingStatusMessageCode, body |-> one] : one \in CheckedSecurityTradingStatusMessage }
        \cup { [tag |-> TradingSessionStatusMessageCode, body |-> one] : one \in CheckedTradingSessionStatusMessage }
        \cup { [tag |-> OrderAddedMessageCode, body |-> one] : one \in CheckedOrderAddedMessage }
        \cup { [tag |-> OrderDeletedMessageCode, body |-> one] : one \in CheckedOrderDeletedMessage }
        \cup { [tag |-> OrderReducedMessageCode, body |-> one] : one \in CheckedOrderReducedMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> CorrectedTradeMessageCode, body |-> one] : one \in CheckedCorrectedTradeMessage }
        \cup { [tag |-> ClearBookMessageCode, body |-> one] : one \in CheckedClearBookMessage }
        \cup { [tag |-> SnapshotCompleteMessageCode, body |-> one] : one \in CheckedSnapshotCompleteMessage }

(***************************************************************************)
(* Sbe Message, framed by Block Length                                     *)
(***************************************************************************)

SbeMessage ==
    [ schemaId : Sample(1),
      version  : Sample(2),
      payload  : Payload ]

EncodeSbeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

(* Block Length counts the bytes it frames, so it is written from them *)
EncodeSbeMessage(message) ==
    LET body == EncodeSbeMessageBody(message)
    IN  EncodeUIntBE(Len(body) - 4, 2) \o body

DecodeSbeMessageBody(bytes) ==
    LET templateId == ReadUIntBE(bytes, 1) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 1) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ schemaId |-> schemaId.value,
         version  |-> version.value,
         payload  |-> payload.value ], payload.rest)

DecodeSbeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value + 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeSbeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSbeMessage ==
    [ schemaId |-> [i \in 1 .. 1 |-> 0],
      version  |-> [i \in 1 .. 2 |-> 0],
      payload  |-> ZeroPayload ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
        \cup { [ZeroSbeMessage EXCEPT !.schemaId = one] : one \in Sample(1) }
        \cup { [ZeroSbeMessage EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroSbeMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ sbeMessage : SbeMessage ]

EncodeMessageBody(message) ==
    EncodeSbeMessage(message.sbeMessage)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET sbeMessage == DecodeSbeMessage(bytes) IN IF ~sbeMessage.ok THEN Fail ELSE
    Ok([ sbeMessage |-> sbeMessage.value ], sbeMessage.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ sbeMessage |-> ZeroSbeMessage ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.sbeMessage = one] : one \in CheckedSbeMessage }

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
OneMessage == { ZeroMessage }

(***************************************************************************)
(* Sequenced Message                                                       *)
(***************************************************************************)

SequencedMessage ==
    [ message : SampleLists(OneMessage) ]

EncodeSequencedMessage(message) ==
    EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodeSequencedMessage(bytes) ==
    LET messageCount == ReadUIntBE(bytes, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroSequencedMessage ==
    [ message |-> << >> ]

(* Sequenced Message at zero, then each field in turn at the values it is checked at *)
CheckedSequencedMessage ==
    { ZeroSequencedMessage }
        \cup { [ZeroSequencedMessage EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

(***************************************************************************)
(* Sequenced Messages, selected by Message Type                            *)
(***************************************************************************)

HeartbeatCode == 0  \* 0x00
SessionShutdownCode == 1  \* 0x01
SequencedMessageCode == 2  \* 0x02

SequencedMessages ==
    [ tag : {HeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SessionShutdownCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequencedMessageCode}, body : SequencedMessage ]

EncodeSequencedMessages(message) ==
    CASE message.tag = HeartbeatCode -> << >>
      [] message.tag = SessionShutdownCode -> << >>
      [] message.tag = SequencedMessageCode -> EncodeSequencedMessage(message.body)

DecodeSequencedMessages(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = SessionShutdownCode -> Ok([empty |-> 0], bytes)
              [] tag = SequencedMessageCode -> DecodeSequencedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessages == [tag |-> HeartbeatCode, body |-> [empty |-> 0]]

(* Each Sequenced Messages in turn, at the values the message it names is checked at *)
CheckedSequencedMessages ==
    { [tag |-> HeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SessionShutdownCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequencedMessageCode, body |-> one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ headerLength      : Sample(1),
      sessionId         : Sample(8),
      sequenceNumber    : Sample(8),
      sequencedMessages : SequencedMessages ]

EncodePacket(message) ==
    EncodeUIntBE(message.sequencedMessages.tag, 1)
        \o message.headerLength
        \o message.sessionId
        \o message.sequenceNumber
        \o EncodeSequencedMessages(message.sequencedMessages)

DecodePacket(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET headerLength == ReadBytes(messageType.rest, 1) IN IF ~headerLength.ok THEN Fail ELSE
    LET sessionId == ReadBytes(headerLength.rest, 8) IN IF ~sessionId.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(sessionId.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET sequencedMessages == DecodeSequencedMessages(messageType.value, sequenceNumber.rest) IN IF ~sequencedMessages.ok THEN Fail ELSE
    Ok([ headerLength      |-> headerLength.value,
         sessionId         |-> sessionId.value,
         sequenceNumber    |-> sequenceNumber.value,
         sequencedMessages |-> sequencedMessages.value ], sequencedMessages.rest)

ZeroPacket ==
    [ headerLength      |-> [i \in 1 .. 1 |-> 0],
      sessionId         |-> [i \in 1 .. 8 |-> 0],
      sequenceNumber    |-> [i \in 1 .. 8 |-> 0],
      sequencedMessages |-> ZeroSequencedMessages ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.headerLength = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sessionId = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.sequencedMessages = one] : one \in CheckedSequencedMessages }

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

(* Every Instrument Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDirectoryMessage ==
    \A message \in CheckedInstrumentDirectoryMessage :
        LET read == DecodeInstrumentDirectoryMessage(EncodeInstrumentDirectoryMessage(message))
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

(* Every Security Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityTradingStatusMessage ==
    \A message \in CheckedSecurityTradingStatusMessage :
        LET read == DecodeSecurityTradingStatusMessage(EncodeSecurityTradingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Session Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingSessionStatusMessage ==
    \A message \in CheckedTradingSessionStatusMessage :
        LET read == DecodeTradingSessionStatusMessage(EncodeTradingSessionStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Added Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddedMessage ==
    \A message \in CheckedOrderAddedMessage :
        LET read == DecodeOrderAddedMessage(EncodeOrderAddedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Deleted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeletedMessage ==
    \A message \in CheckedOrderDeletedMessage :
        LET read == DecodeOrderDeletedMessage(EncodeOrderDeletedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Reduced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReducedMessage ==
    \A message \in CheckedOrderReducedMessage :
        LET read == DecodeOrderReducedMessage(EncodeOrderReducedMessage(message))
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

(* Every Broken Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeMessage ==
    \A message \in CheckedBrokenTradeMessage :
        LET read == DecodeBrokenTradeMessage(EncodeBrokenTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Corrected Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCorrectedTradeMessage ==
    \A message \in CheckedCorrectedTradeMessage :
        LET read == DecodeCorrectedTradeMessage(EncodeCorrectedTradeMessage(message))
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

(* Every Snapshot Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotCompleteMessage ==
    \A message \in CheckedSnapshotCompleteMessage :
        LET read == DecodeSnapshotCompleteMessage(EncodeSnapshotCompleteMessage(message))
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

(* Every Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(EncodeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(EncodeSequencedMessage(message))
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

(* A Sequenced Messages is selected by the Message Type it is written under *)
SelectsSequencedMessages ==
    \A message \in CheckedSequencedMessages :
        LET read == DecodeSequencedMessages(message.tag, EncodeSequencedMessages(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Block Length is written from the bytes it frames *)
FramesSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET bytes == EncodeSbeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 6

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
