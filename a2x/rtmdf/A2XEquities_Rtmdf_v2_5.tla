---------------------- MODULE A2XEquities_Rtmdf_v2_5 -----------------------
(***************************************************************************)
(* A2X Markets Real Time Market Data Feed v2.5                             *)
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
(* Note: Md Flags is a bit field set, checked as its 1 byte rather than    *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Flags is a bit field set, checked as its 2 bytes rather than bit  *)
(* by bit.                                                                 *)
(*                                                                         *)
(* Note: Market Flags is a bit field set, checked as its 1 byte rather     *)
(* than bit by bit.                                                        *)
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
(* Order Add Message: 28 bytes                                             *)
(***************************************************************************)

OrderAddMessage ==
    [ securityId : Sample(2),
      side       : Sample(1),
      quantity   : Sample(4),
      price      : Sample(8),
      orderRef   : Sample(4),
      timestamp  : Sample(8),
      mdFlags    : Sample(1) ]

EncodeOrderAddMessage(message) ==
    message.securityId
        \o message.side
        \o message.quantity
        \o message.price
        \o message.orderRef
        \o message.timestamp
        \o message.mdFlags

DecodeOrderAddMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderRef == ReadBytes(price.rest, 4) IN IF ~orderRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(orderRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET mdFlags == ReadBytes(timestamp.rest, 1) IN IF ~mdFlags.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         side       |-> side.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         orderRef   |-> orderRef.value,
         timestamp  |-> timestamp.value,
         mdFlags    |-> mdFlags.value ], mdFlags.rest)

ZeroOrderAddMessage ==
    [ securityId |-> [i \in 1 .. 2 |-> 0],
      side       |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      orderRef   |-> [i \in 1 .. 4 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0],
      mdFlags    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Add Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddMessage ==
    { ZeroOrderAddMessage }
        \cup { [ZeroOrderAddMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroOrderAddMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.orderRef = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.mdFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Cancel Message: 15 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ securityId : Sample(2),
      orderRef   : Sample(4),
      timestamp  : Sample(8),
      mdFlags    : Sample(1) ]

EncodeOrderCancelMessage(message) ==
    message.securityId
        \o message.orderRef
        \o message.timestamp
        \o message.mdFlags

DecodeOrderCancelMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET orderRef == ReadBytes(securityId.rest, 4) IN IF ~orderRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(orderRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET mdFlags == ReadBytes(timestamp.rest, 1) IN IF ~mdFlags.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         orderRef   |-> orderRef.value,
         timestamp  |-> timestamp.value,
         mdFlags    |-> mdFlags.value ], mdFlags.rest)

ZeroOrderCancelMessage ==
    [ securityId |-> [i \in 1 .. 2 |-> 0],
      orderRef   |-> [i \in 1 .. 4 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0],
      mdFlags    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderRef = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.mdFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Modify Message: 27 bytes                                          *)
(***************************************************************************)

OrderModifyMessage ==
    [ securityId : Sample(2),
      quantity   : Sample(4),
      price      : Sample(8),
      orderRef   : Sample(4),
      timestamp  : Sample(8),
      mdFlags    : Sample(1) ]

EncodeOrderModifyMessage(message) ==
    message.securityId
        \o message.quantity
        \o message.price
        \o message.orderRef
        \o message.timestamp
        \o message.mdFlags

DecodeOrderModifyMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET quantity == ReadBytes(securityId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderRef == ReadBytes(price.rest, 4) IN IF ~orderRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(orderRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET mdFlags == ReadBytes(timestamp.rest, 1) IN IF ~mdFlags.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         orderRef   |-> orderRef.value,
         timestamp  |-> timestamp.value,
         mdFlags    |-> mdFlags.value ], mdFlags.rest)

ZeroOrderModifyMessage ==
    [ securityId |-> [i \in 1 .. 2 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      orderRef   |-> [i \in 1 .. 4 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0],
      mdFlags    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Modify Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyMessage ==
    { ZeroOrderModifyMessage }
        \cup { [ZeroOrderModifyMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.orderRef = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.mdFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Message: 31 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ securityId : Sample(2),
      tradeType  : Sample(1),
      quantity   : Sample(4),
      price      : Sample(8),
      orderRef   : Sample(4),
      tradeRef   : Sample(4),
      timestamp  : Sample(8) ]

EncodeTradeMessage(message) ==
    message.securityId
        \o message.tradeType
        \o message.quantity
        \o message.price
        \o message.orderRef
        \o message.tradeRef
        \o message.timestamp

DecodeTradeMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradeType == ReadBytes(securityId.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradeType.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderRef == ReadBytes(price.rest, 4) IN IF ~orderRef.ok THEN Fail ELSE
    LET tradeRef == ReadBytes(orderRef.rest, 4) IN IF ~tradeRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(tradeRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         tradeType  |-> tradeType.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         orderRef   |-> orderRef.value,
         tradeRef   |-> tradeRef.value,
         timestamp  |-> timestamp.value ], timestamp.rest)

ZeroTradeMessage ==
    [ securityId |-> [i \in 1 .. 2 |-> 0],
      tradeType  |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      orderRef   |-> [i \in 1 .. 4 |-> 0],
      tradeRef   |-> [i \in 1 .. 4 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.orderRef = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeRef = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Bust Message: 26 bytes                                            *)
(***************************************************************************)

TradeBustMessage ==
    [ securityId : Sample(2),
      quantity   : Sample(4),
      price      : Sample(8),
      tradeRef   : Sample(4),
      timestamp  : Sample(8) ]

EncodeTradeBustMessage(message) ==
    message.securityId
        \o message.quantity
        \o message.price
        \o message.tradeRef
        \o message.timestamp

DecodeTradeBustMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET quantity == ReadBytes(securityId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeRef == ReadBytes(price.rest, 4) IN IF ~tradeRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(tradeRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         tradeRef   |-> tradeRef.value,
         timestamp  |-> timestamp.value ], timestamp.rest)

ZeroTradeBustMessage ==
    [ securityId |-> [i \in 1 .. 2 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      tradeRef   |-> [i \in 1 .. 4 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Bust Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustMessage ==
    { ZeroTradeBustMessage }
        \cup { [ZeroTradeBustMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroTradeBustMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.tradeRef = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Tick Table Data Message: 27 bytes                                       *)
(***************************************************************************)

TickTableDataMessage ==
    [ tickTableId : Sample(1),
      name        : Sample(10),
      threshold   : Sample(8),
      tickSize    : Sample(8) ]

EncodeTickTableDataMessage(message) ==
    message.tickTableId
        \o message.name
        \o message.threshold
        \o message.tickSize

DecodeTickTableDataMessage(bytes) ==
    LET tickTableId == ReadBytes(bytes, 1) IN IF ~tickTableId.ok THEN Fail ELSE
    LET name == ReadBytes(tickTableId.rest, 10) IN IF ~name.ok THEN Fail ELSE
    LET threshold == ReadBytes(name.rest, 8) IN IF ~threshold.ok THEN Fail ELSE
    LET tickSize == ReadBytes(threshold.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    Ok([ tickTableId |-> tickTableId.value,
         name        |-> name.value,
         threshold   |-> threshold.value,
         tickSize    |-> tickSize.value ], tickSize.rest)

ZeroTickTableDataMessage ==
    [ tickTableId |-> [i \in 1 .. 1 |-> 0],
      name        |-> [i \in 1 .. 10 |-> 0],
      threshold   |-> [i \in 1 .. 8 |-> 0],
      tickSize    |-> [i \in 1 .. 8 |-> 0] ]

(* Tick Table Data Message at zero, then each field in turn at the values it is checked at *)
CheckedTickTableDataMessage ==
    { ZeroTickTableDataMessage }
        \cup { [ZeroTickTableDataMessage EXCEPT !.tickTableId = one] : one \in Sample(1) }
        \cup { [ZeroTickTableDataMessage EXCEPT !.name = one] : one \in Sample(10) }
        \cup { [ZeroTickTableDataMessage EXCEPT !.threshold = one] : one \in Sample(8) }
        \cup { [ZeroTickTableDataMessage EXCEPT !.tickSize = one] : one \in Sample(8) }

(***************************************************************************)
(* Security Definition Message: 30 bytes                                   *)
(***************************************************************************)

SecurityDefinitionMessage ==
    [ securityId  : Sample(2),
      umtf        : Sample(6),
      isin        : Sample(12),
      currency    : Sample(3),
      mic         : Sample(4),
      tickTableId : Sample(1),
      flags       : Sample(2) ]

EncodeSecurityDefinitionMessage(message) ==
    message.securityId
        \o message.umtf
        \o message.isin
        \o message.currency
        \o message.mic
        \o message.tickTableId
        \o message.flags

DecodeSecurityDefinitionMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET umtf == ReadBytes(securityId.rest, 6) IN IF ~umtf.ok THEN Fail ELSE
    LET isin == ReadBytes(umtf.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET currency == ReadBytes(isin.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET mic == ReadBytes(currency.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET tickTableId == ReadBytes(mic.rest, 1) IN IF ~tickTableId.ok THEN Fail ELSE
    LET flags == ReadBytes(tickTableId.rest, 2) IN IF ~flags.ok THEN Fail ELSE
    Ok([ securityId  |-> securityId.value,
         umtf        |-> umtf.value,
         isin        |-> isin.value,
         currency    |-> currency.value,
         mic         |-> mic.value,
         tickTableId |-> tickTableId.value,
         flags       |-> flags.value ], flags.rest)

ZeroSecurityDefinitionMessage ==
    [ securityId  |-> [i \in 1 .. 2 |-> 0],
      umtf        |-> [i \in 1 .. 6 |-> 0],
      isin        |-> [i \in 1 .. 12 |-> 0],
      currency    |-> [i \in 1 .. 3 |-> 0],
      mic         |-> [i \in 1 .. 4 |-> 0],
      tickTableId |-> [i \in 1 .. 1 |-> 0],
      flags       |-> [i \in 1 .. 2 |-> 0] ]

(* Security Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessage ==
    { ZeroSecurityDefinitionMessage }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.umtf = one] : one \in Sample(6) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.tickTableId = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.flags = one] : one \in Sample(2) }

(***************************************************************************)
(* Security Status Message: 12 bytes                                       *)
(***************************************************************************)

SecurityStatusMessage ==
    [ securityId    : Sample(2),
      tradingStatus : Sample(1),
      marketFlags   : Sample(1),
      timestamp     : Sample(8) ]

EncodeSecurityStatusMessage(message) ==
    message.securityId
        \o message.tradingStatus
        \o message.marketFlags
        \o message.timestamp

DecodeSecurityStatusMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(securityId.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET marketFlags == ReadBytes(tradingStatus.rest, 1) IN IF ~marketFlags.ok THEN Fail ELSE
    LET timestamp == ReadBytes(marketFlags.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId    |-> securityId.value,
         tradingStatus |-> tradingStatus.value,
         marketFlags   |-> marketFlags.value,
         timestamp     |-> timestamp.value ], timestamp.rest)

ZeroSecurityStatusMessage ==
    [ securityId    |-> [i \in 1 .. 2 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0],
      marketFlags   |-> [i \in 1 .. 1 |-> 0],
      timestamp     |-> [i \in 1 .. 8 |-> 0] ]

(* Security Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusMessage ==
    { ZeroSecurityStatusMessage }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.marketFlags = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Mac Update Message: 26 bytes                                            *)
(***************************************************************************)

MacUpdateMessage ==
    [ securityId      : Sample(2),
      indicativePrice : Sample(8),
      closingBuyQty   : Sample(4),
      closingSellQty  : Sample(4),
      timestamp       : Sample(8) ]

EncodeMacUpdateMessage(message) ==
    message.securityId
        \o message.indicativePrice
        \o message.closingBuyQty
        \o message.closingSellQty
        \o message.timestamp

DecodeMacUpdateMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(securityId.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET closingBuyQty == ReadBytes(indicativePrice.rest, 4) IN IF ~closingBuyQty.ok THEN Fail ELSE
    LET closingSellQty == ReadBytes(closingBuyQty.rest, 4) IN IF ~closingSellQty.ok THEN Fail ELSE
    LET timestamp == ReadBytes(closingSellQty.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId      |-> securityId.value,
         indicativePrice |-> indicativePrice.value,
         closingBuyQty   |-> closingBuyQty.value,
         closingSellQty  |-> closingSellQty.value,
         timestamp       |-> timestamp.value ], timestamp.rest)

ZeroMacUpdateMessage ==
    [ securityId      |-> [i \in 1 .. 2 |-> 0],
      indicativePrice |-> [i \in 1 .. 8 |-> 0],
      closingBuyQty   |-> [i \in 1 .. 4 |-> 0],
      closingSellQty  |-> [i \in 1 .. 4 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0] ]

(* Mac Update Message at zero, then each field in turn at the values it is checked at *)
CheckedMacUpdateMessage ==
    { ZeroMacUpdateMessage }
        \cup { [ZeroMacUpdateMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroMacUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroMacUpdateMessage EXCEPT !.closingBuyQty = one] : one \in Sample(4) }
        \cup { [ZeroMacUpdateMessage EXCEPT !.closingSellQty = one] : one \in Sample(4) }
        \cup { [ZeroMacUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Aod Update Message: 22 bytes                                            *)
(***************************************************************************)

AodUpdateMessage ==
    [ securityId      : Sample(2),
      indicativePrice : Sample(8),
      matchVol        : Sample(4),
      timestamp       : Sample(8) ]

EncodeAodUpdateMessage(message) ==
    message.securityId
        \o message.indicativePrice
        \o message.matchVol
        \o message.timestamp

DecodeAodUpdateMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(securityId.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET matchVol == ReadBytes(indicativePrice.rest, 4) IN IF ~matchVol.ok THEN Fail ELSE
    LET timestamp == ReadBytes(matchVol.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId      |-> securityId.value,
         indicativePrice |-> indicativePrice.value,
         matchVol        |-> matchVol.value,
         timestamp       |-> timestamp.value ], timestamp.rest)

ZeroAodUpdateMessage ==
    [ securityId      |-> [i \in 1 .. 2 |-> 0],
      indicativePrice |-> [i \in 1 .. 8 |-> 0],
      matchVol        |-> [i \in 1 .. 4 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0] ]

(* Aod Update Message at zero, then each field in turn at the values it is checked at *)
CheckedAodUpdateMessage ==
    { ZeroAodUpdateMessage }
        \cup { [ZeroAodUpdateMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroAodUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroAodUpdateMessage EXCEPT !.matchVol = one] : one \in Sample(4) }
        \cup { [ZeroAodUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

HeartbeatMessageCode == 1  \* 0x01
OrderAddMessageCode == 2  \* 0x02
OrderCancelMessageCode == 3  \* 0x03
OrderModifyMessageCode == 4  \* 0x04
TradeMessageCode == 5  \* 0x05
TradeBustMessageCode == 6  \* 0x06
TickTableDataMessageCode == 7  \* 0x07
SecurityDefinitionMessageCode == 8  \* 0x08
SecurityStatusMessageCode == 9  \* 0x09
MacUpdateMessageCode == 16  \* 0x10
AodUpdateMessageCode == 17  \* 0x11

Payload ==
    [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {OrderAddMessageCode}, body : OrderAddMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {OrderModifyMessageCode}, body : OrderModifyMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeBustMessageCode}, body : TradeBustMessage ]
        \cup [ tag : {TickTableDataMessageCode}, body : TickTableDataMessage ]
        \cup [ tag : {SecurityDefinitionMessageCode}, body : SecurityDefinitionMessage ]
        \cup [ tag : {SecurityStatusMessageCode}, body : SecurityStatusMessage ]
        \cup [ tag : {MacUpdateMessageCode}, body : MacUpdateMessage ]
        \cup [ tag : {AodUpdateMessageCode}, body : AodUpdateMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = OrderAddMessageCode -> EncodeOrderAddMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = OrderModifyMessageCode -> EncodeOrderModifyMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeBustMessageCode -> EncodeTradeBustMessage(message.body)
      [] message.tag = TickTableDataMessageCode -> EncodeTickTableDataMessage(message.body)
      [] message.tag = SecurityDefinitionMessageCode -> EncodeSecurityDefinitionMessage(message.body)
      [] message.tag = SecurityStatusMessageCode -> EncodeSecurityStatusMessage(message.body)
      [] message.tag = MacUpdateMessageCode -> EncodeMacUpdateMessage(message.body)
      [] message.tag = AodUpdateMessageCode -> EncodeAodUpdateMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = OrderAddMessageCode -> DecodeOrderAddMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = OrderModifyMessageCode -> DecodeOrderModifyMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeBustMessageCode -> DecodeTradeBustMessage(bytes)
              [] tag = TickTableDataMessageCode -> DecodeTickTableDataMessage(bytes)
              [] tag = SecurityDefinitionMessageCode -> DecodeSecurityDefinitionMessage(bytes)
              [] tag = SecurityStatusMessageCode -> DecodeSecurityStatusMessage(bytes)
              [] tag = MacUpdateMessageCode -> DecodeMacUpdateMessage(bytes)
              [] tag = AodUpdateMessageCode -> DecodeAodUpdateMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> OrderAddMessageCode, body |-> one] : one \in CheckedOrderAddMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> OrderModifyMessageCode, body |-> one] : one \in CheckedOrderModifyMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeBustMessageCode, body |-> one] : one \in CheckedTradeBustMessage }
        \cup { [tag |-> TickTableDataMessageCode, body |-> one] : one \in CheckedTickTableDataMessage }
        \cup { [tag |-> SecurityDefinitionMessageCode, body |-> one] : one \in CheckedSecurityDefinitionMessage }
        \cup { [tag |-> SecurityStatusMessageCode, body |-> one] : one \in CheckedSecurityStatusMessage }
        \cup { [tag |-> MacUpdateMessageCode, body |-> one] : one \in CheckedMacUpdateMessage }
        \cup { [tag |-> AodUpdateMessageCode, body |-> one] : one \in CheckedAodUpdateMessage }

(***************************************************************************)
(* Message, framed by Msg Length                                           *)
(***************************************************************************)

Message ==
    [ seqNo   : Sample(4),
      payload : Payload ]

EncodeMessageBody(message) ==
    message.seqNo
        \o EncodePayload(message.payload)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(message.payload.tag, 1) \o EncodeUIntBE(Len(body) + 2, 1) \o body

DecodeMessage(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET length == ReadUIntBE(msgType.rest, 1) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET seqNo == ReadBytes(framed, 4) IN IF ~seqNo.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, seqNo.rest) IN IF ~payload.ok THEN Fail ELSE
    IF payload.rest # << >> THEN Fail ELSE
    Ok([ seqNo   |-> seqNo.value,
         payload |-> payload.value ], beyond)

ZeroMessage ==
    [ seqNo   |-> [i \in 1 .. 4 |-> 0],
      payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.seqNo = one] : one \in Sample(4) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAddMessageCode, body |-> ZeroOrderAddMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelMessageCode, body |-> ZeroOrderCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifyMessageCode, body |-> ZeroOrderModifyMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBustMessageCode, body |-> ZeroTradeBustMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TickTableDataMessageCode, body |-> ZeroTickTableDataMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionMessageCode, body |-> ZeroSecurityDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatusMessageCode, body |-> ZeroSecurityStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MacUpdateMessageCode, body |-> ZeroMacUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AodUpdateMessageCode, body |-> ZeroAodUpdateMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ message : SampleLists(OneMessage) ]

EncodePacket(message) ==
    EncodeUIntBE(Len(message.message), 1)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET messageCount == ReadUIntBE(bytes, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
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

(* Every Order Add Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddMessage ==
    \A message \in CheckedOrderAddMessage :
        LET read == DecodeOrderAddMessage(EncodeOrderAddMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelMessage ==
    \A message \in CheckedOrderCancelMessage :
        LET read == DecodeOrderCancelMessage(EncodeOrderCancelMessage(message))
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

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBustMessage ==
    \A message \in CheckedTradeBustMessage :
        LET read == DecodeTradeBustMessage(EncodeTradeBustMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Table Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTickTableDataMessage ==
    \A message \in CheckedTickTableDataMessage :
        LET read == DecodeTickTableDataMessage(EncodeTickTableDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessage ==
    \A message \in CheckedSecurityDefinitionMessage :
        LET read == DecodeSecurityDefinitionMessage(EncodeSecurityDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusMessage ==
    \A message \in CheckedSecurityStatusMessage :
        LET read == DecodeSecurityStatusMessage(EncodeSecurityStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mac Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMacUpdateMessage ==
    \A message \in CheckedMacUpdateMessage :
        LET read == DecodeMacUpdateMessage(EncodeMacUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Aod Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAodUpdateMessage ==
    \A message \in CheckedAodUpdateMessage :
        LET read == DecodeAodUpdateMessage(EncodeAodUpdateMessage(message))
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

(* A Payload is selected by the Msg Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Msg Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 2, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
