-------------------- MODULE AquisEquities_RealTime_v4_0 --------------------
(***************************************************************************)
(* Aquis Exchange Real Time Market Data Feed v4.0                          *)
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
(* Note: Binary Mmt is a bit field set, checked as its 4 bytes rather than *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Security Definition Flags is a bit field set, checked as its 2    *)
(* bytes rather than bit by bit.                                           *)
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
(* Order Add: 28 bytes                                                     *)
(***************************************************************************)

OrderAdd ==
    [ securityId : Sample(2),
      side       : Sample(1),
      quantity   : Sample(4),
      price      : Sample(8),
      orderRef   : Sample(4),
      timestamp  : Sample(8),
      mdFlags    : Sample(1) ]

EncodeOrderAdd(message) ==
    message.securityId
        \o message.side
        \o message.quantity
        \o message.price
        \o message.orderRef
        \o message.timestamp
        \o message.mdFlags

DecodeOrderAdd(bytes) ==
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

ZeroOrderAdd ==
    [ securityId |-> [i \in 1 .. 2 |-> 0],
      side       |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      orderRef   |-> [i \in 1 .. 4 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0],
      mdFlags    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Add at zero, then each field in turn at the values it is checked at *)
CheckedOrderAdd ==
    { ZeroOrderAdd }
        \cup { [ZeroOrderAdd EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroOrderAdd EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAdd EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAdd EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAdd EXCEPT !.orderRef = one] : one \in Sample(4) }
        \cup { [ZeroOrderAdd EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderAdd EXCEPT !.mdFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Cancel: 15 bytes                                                  *)
(***************************************************************************)

OrderCancel ==
    [ securityId : Sample(2),
      orderRef   : Sample(4),
      timestamp  : Sample(8),
      mdFlags    : Sample(1) ]

EncodeOrderCancel(message) ==
    message.securityId
        \o message.orderRef
        \o message.timestamp
        \o message.mdFlags

DecodeOrderCancel(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET orderRef == ReadBytes(securityId.rest, 4) IN IF ~orderRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(orderRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET mdFlags == ReadBytes(timestamp.rest, 1) IN IF ~mdFlags.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         orderRef   |-> orderRef.value,
         timestamp  |-> timestamp.value,
         mdFlags    |-> mdFlags.value ], mdFlags.rest)

ZeroOrderCancel ==
    [ securityId |-> [i \in 1 .. 2 |-> 0],
      orderRef   |-> [i \in 1 .. 4 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0],
      mdFlags    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Cancel at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancel ==
    { ZeroOrderCancel }
        \cup { [ZeroOrderCancel EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancel EXCEPT !.orderRef = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancel EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancel EXCEPT !.mdFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Modify: 27 bytes                                                  *)
(***************************************************************************)

OrderModify ==
    [ securityId : Sample(2),
      quantity   : Sample(4),
      price      : Sample(8),
      orderRef   : Sample(4),
      timestamp  : Sample(8),
      mdFlags    : Sample(1) ]

EncodeOrderModify(message) ==
    message.securityId
        \o message.quantity
        \o message.price
        \o message.orderRef
        \o message.timestamp
        \o message.mdFlags

DecodeOrderModify(bytes) ==
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

ZeroOrderModify ==
    [ securityId |-> [i \in 1 .. 2 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      orderRef   |-> [i \in 1 .. 4 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0],
      mdFlags    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Modify at zero, then each field in turn at the values it is checked at *)
CheckedOrderModify ==
    { ZeroOrderModify }
        \cup { [ZeroOrderModify EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroOrderModify EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderModify EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModify EXCEPT !.orderRef = one] : one \in Sample(4) }
        \cup { [ZeroOrderModify EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderModify EXCEPT !.mdFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade: 36 bytes                                                         *)
(***************************************************************************)

Trade ==
    [ securityId : Sample(2),
      tradeType  : Sample(1),
      quantity   : Sample(4),
      price      : Sample(8),
      orderRef   : Sample(4),
      tradeRef   : Sample(4),
      timestamp  : Sample(8),
      binaryMmt  : Sample(4),
      mdFlags    : Sample(1) ]

EncodeTrade(message) ==
    message.securityId
        \o message.tradeType
        \o message.quantity
        \o message.price
        \o message.orderRef
        \o message.tradeRef
        \o message.timestamp
        \o message.binaryMmt
        \o message.mdFlags

DecodeTrade(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradeType == ReadBytes(securityId.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradeType.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderRef == ReadBytes(price.rest, 4) IN IF ~orderRef.ok THEN Fail ELSE
    LET tradeRef == ReadBytes(orderRef.rest, 4) IN IF ~tradeRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(tradeRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET binaryMmt == ReadBytes(timestamp.rest, 4) IN IF ~binaryMmt.ok THEN Fail ELSE
    LET mdFlags == ReadBytes(binaryMmt.rest, 1) IN IF ~mdFlags.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         tradeType  |-> tradeType.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         orderRef   |-> orderRef.value,
         tradeRef   |-> tradeRef.value,
         timestamp  |-> timestamp.value,
         binaryMmt  |-> binaryMmt.value,
         mdFlags    |-> mdFlags.value ], mdFlags.rest)

ZeroTrade ==
    [ securityId |-> [i \in 1 .. 2 |-> 0],
      tradeType  |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      orderRef   |-> [i \in 1 .. 4 |-> 0],
      tradeRef   |-> [i \in 1 .. 4 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0],
      binaryMmt  |-> [i \in 1 .. 4 |-> 0],
      mdFlags    |-> [i \in 1 .. 1 |-> 0] ]

(* Trade at zero, then each field in turn at the values it is checked at *)
CheckedTrade ==
    { ZeroTrade }
        \cup { [ZeroTrade EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroTrade EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTrade EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.orderRef = one] : one \in Sample(4) }
        \cup { [ZeroTrade EXCEPT !.tradeRef = one] : one \in Sample(4) }
        \cup { [ZeroTrade EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.binaryMmt = one] : one \in Sample(4) }
        \cup { [ZeroTrade EXCEPT !.mdFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Bust Message: 30 bytes                                            *)
(***************************************************************************)

TradeBustMessage ==
    [ securityId : Sample(2),
      quantity   : Sample(4),
      price      : Sample(8),
      tradeRef   : Sample(4),
      timestamp  : Sample(8),
      binaryMmt  : Sample(4) ]

EncodeTradeBustMessage(message) ==
    message.securityId
        \o message.quantity
        \o message.price
        \o message.tradeRef
        \o message.timestamp
        \o message.binaryMmt

DecodeTradeBustMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET quantity == ReadBytes(securityId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeRef == ReadBytes(price.rest, 4) IN IF ~tradeRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(tradeRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET binaryMmt == ReadBytes(timestamp.rest, 4) IN IF ~binaryMmt.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         tradeRef   |-> tradeRef.value,
         timestamp  |-> timestamp.value,
         binaryMmt  |-> binaryMmt.value ], binaryMmt.rest)

ZeroTradeBustMessage ==
    [ securityId |-> [i \in 1 .. 2 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      tradeRef   |-> [i \in 1 .. 4 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0],
      binaryMmt  |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Bust Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustMessage ==
    { ZeroTradeBustMessage }
        \cup { [ZeroTradeBustMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroTradeBustMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.tradeRef = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.binaryMmt = one] : one \in Sample(4) }

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
(* Security Definition Message: 59 bytes                                   *)
(***************************************************************************)

SecurityDefinitionMessage ==
    [ securityId              : Sample(2),
      umtf                    : Sample(6),
      isin                    : Sample(12),
      currency                : Sample(3),
      mic                     : Sample(4),
      tickTableId             : Sample(1),
      securityDefinitionFlags : Sample(2),
      reserved20              : Sample(20),
      lotSize                 : Sample(8),
      lotSizeDecimal          : Sample(1) ]

EncodeSecurityDefinitionMessage(message) ==
    message.securityId
        \o message.umtf
        \o message.isin
        \o message.currency
        \o message.mic
        \o message.tickTableId
        \o message.securityDefinitionFlags
        \o message.reserved20
        \o message.lotSize
        \o message.lotSizeDecimal

DecodeSecurityDefinitionMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET umtf == ReadBytes(securityId.rest, 6) IN IF ~umtf.ok THEN Fail ELSE
    LET isin == ReadBytes(umtf.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET currency == ReadBytes(isin.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET mic == ReadBytes(currency.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET tickTableId == ReadBytes(mic.rest, 1) IN IF ~tickTableId.ok THEN Fail ELSE
    LET securityDefinitionFlags == ReadBytes(tickTableId.rest, 2) IN IF ~securityDefinitionFlags.ok THEN Fail ELSE
    LET reserved20 == ReadBytes(securityDefinitionFlags.rest, 20) IN IF ~reserved20.ok THEN Fail ELSE
    LET lotSize == ReadBytes(reserved20.rest, 8) IN IF ~lotSize.ok THEN Fail ELSE
    LET lotSizeDecimal == ReadBytes(lotSize.rest, 1) IN IF ~lotSizeDecimal.ok THEN Fail ELSE
    Ok([ securityId              |-> securityId.value,
         umtf                    |-> umtf.value,
         isin                    |-> isin.value,
         currency                |-> currency.value,
         mic                     |-> mic.value,
         tickTableId             |-> tickTableId.value,
         securityDefinitionFlags |-> securityDefinitionFlags.value,
         reserved20              |-> reserved20.value,
         lotSize                 |-> lotSize.value,
         lotSizeDecimal          |-> lotSizeDecimal.value ], lotSizeDecimal.rest)

ZeroSecurityDefinitionMessage ==
    [ securityId              |-> [i \in 1 .. 2 |-> 0],
      umtf                    |-> [i \in 1 .. 6 |-> 0],
      isin                    |-> [i \in 1 .. 12 |-> 0],
      currency                |-> [i \in 1 .. 3 |-> 0],
      mic                     |-> [i \in 1 .. 4 |-> 0],
      tickTableId             |-> [i \in 1 .. 1 |-> 0],
      securityDefinitionFlags |-> [i \in 1 .. 2 |-> 0],
      reserved20              |-> [i \in 1 .. 20 |-> 0],
      lotSize                 |-> [i \in 1 .. 8 |-> 0],
      lotSizeDecimal          |-> [i \in 1 .. 1 |-> 0] ]

(* Security Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessage ==
    { ZeroSecurityDefinitionMessage }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.umtf = one] : one \in Sample(6) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.tickTableId = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityDefinitionFlags = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.reserved20 = one] : one \in Sample(20) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.lotSize = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.lotSizeDecimal = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Status Message: 13 bytes                                       *)
(***************************************************************************)

SecurityStatusMessage ==
    [ securityId    : Sample(2),
      tradingStatus : Sample(1),
      marketFlags   : Sample(1),
      timestamp     : Sample(8),
      tradingPhase  : Sample(1) ]

EncodeSecurityStatusMessage(message) ==
    message.securityId
        \o message.tradingStatus
        \o message.marketFlags
        \o message.timestamp
        \o message.tradingPhase

DecodeSecurityStatusMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(securityId.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET marketFlags == ReadBytes(tradingStatus.rest, 1) IN IF ~marketFlags.ok THEN Fail ELSE
    LET timestamp == ReadBytes(marketFlags.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradingPhase == ReadBytes(timestamp.rest, 1) IN IF ~tradingPhase.ok THEN Fail ELSE
    Ok([ securityId    |-> securityId.value,
         tradingStatus |-> tradingStatus.value,
         marketFlags   |-> marketFlags.value,
         timestamp     |-> timestamp.value,
         tradingPhase  |-> tradingPhase.value ], tradingPhase.rest)

ZeroSecurityStatusMessage ==
    [ securityId    |-> [i \in 1 .. 2 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0],
      marketFlags   |-> [i \in 1 .. 1 |-> 0],
      timestamp     |-> [i \in 1 .. 8 |-> 0],
      tradingPhase  |-> [i \in 1 .. 1 |-> 0] ]

(* Security Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusMessage ==
    { ZeroSecurityStatusMessage }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.marketFlags = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.tradingPhase = one] : one \in Sample(1) }

(***************************************************************************)
(* Ao D Update Message: 22 bytes                                           *)
(***************************************************************************)

AoDUpdateMessage ==
    [ securityId      : Sample(2),
      indicativePrice : Sample(8),
      matchVol        : Sample(4),
      timestamp       : Sample(8) ]

EncodeAoDUpdateMessage(message) ==
    message.securityId
        \o message.indicativePrice
        \o message.matchVol
        \o message.timestamp

DecodeAoDUpdateMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET indicativePrice == ReadBytes(securityId.rest, 8) IN IF ~indicativePrice.ok THEN Fail ELSE
    LET matchVol == ReadBytes(indicativePrice.rest, 4) IN IF ~matchVol.ok THEN Fail ELSE
    LET timestamp == ReadBytes(matchVol.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId      |-> securityId.value,
         indicativePrice |-> indicativePrice.value,
         matchVol        |-> matchVol.value,
         timestamp       |-> timestamp.value ], timestamp.rest)

ZeroAoDUpdateMessage ==
    [ securityId      |-> [i \in 1 .. 2 |-> 0],
      indicativePrice |-> [i \in 1 .. 8 |-> 0],
      matchVol        |-> [i \in 1 .. 4 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0] ]

(* Ao D Update Message at zero, then each field in turn at the values it is checked at *)
CheckedAoDUpdateMessage ==
    { ZeroAoDUpdateMessage }
        \cup { [ZeroAoDUpdateMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroAoDUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroAoDUpdateMessage EXCEPT !.matchVol = one] : one \in Sample(4) }
        \cup { [ZeroAoDUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Ma C Update Message: 26 bytes                                           *)
(***************************************************************************)

MaCUpdateMessage ==
    [ securityId      : Sample(2),
      indicativePrice : Sample(8),
      closingBuyQty   : Sample(4),
      closingSellQty  : Sample(4),
      timestamp       : Sample(8) ]

EncodeMaCUpdateMessage(message) ==
    message.securityId
        \o message.indicativePrice
        \o message.closingBuyQty
        \o message.closingSellQty
        \o message.timestamp

DecodeMaCUpdateMessage(bytes) ==
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

ZeroMaCUpdateMessage ==
    [ securityId      |-> [i \in 1 .. 2 |-> 0],
      indicativePrice |-> [i \in 1 .. 8 |-> 0],
      closingBuyQty   |-> [i \in 1 .. 4 |-> 0],
      closingSellQty  |-> [i \in 1 .. 4 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0] ]

(* Ma C Update Message at zero, then each field in turn at the values it is checked at *)
CheckedMaCUpdateMessage ==
    { ZeroMaCUpdateMessage }
        \cup { [ZeroMaCUpdateMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroMaCUpdateMessage EXCEPT !.indicativePrice = one] : one \in Sample(8) }
        \cup { [ZeroMaCUpdateMessage EXCEPT !.closingBuyQty = one] : one \in Sample(4) }
        \cup { [ZeroMaCUpdateMessage EXCEPT !.closingSellQty = one] : one \in Sample(4) }
        \cup { [ZeroMaCUpdateMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

OrderAddCode == 2  \* 0x02
OrderCancelCode == 3  \* 0x03
OrderModifyCode == 4  \* 0x04
TradeCode == 5  \* 0x05
TradeBustMessageCode == 6  \* 0x06
TickTableDataMessageCode == 7  \* 0x07
SecurityDefinitionMessageCode == 8  \* 0x08
SecurityStatusMessageCode == 9  \* 0x09
AoDUpdateMessageCode == 17  \* 0x11
MaCUpdateMessageCode == 16  \* 0x10

Payload ==
    [ tag : {OrderAddCode}, body : OrderAdd ]
        \cup [ tag : {OrderCancelCode}, body : OrderCancel ]
        \cup [ tag : {OrderModifyCode}, body : OrderModify ]
        \cup [ tag : {TradeCode}, body : Trade ]
        \cup [ tag : {TradeBustMessageCode}, body : TradeBustMessage ]
        \cup [ tag : {TickTableDataMessageCode}, body : TickTableDataMessage ]
        \cup [ tag : {SecurityDefinitionMessageCode}, body : SecurityDefinitionMessage ]
        \cup [ tag : {SecurityStatusMessageCode}, body : SecurityStatusMessage ]
        \cup [ tag : {AoDUpdateMessageCode}, body : AoDUpdateMessage ]
        \cup [ tag : {MaCUpdateMessageCode}, body : MaCUpdateMessage ]

EncodePayload(message) ==
    CASE message.tag = OrderAddCode -> EncodeOrderAdd(message.body)
      [] message.tag = OrderCancelCode -> EncodeOrderCancel(message.body)
      [] message.tag = OrderModifyCode -> EncodeOrderModify(message.body)
      [] message.tag = TradeCode -> EncodeTrade(message.body)
      [] message.tag = TradeBustMessageCode -> EncodeTradeBustMessage(message.body)
      [] message.tag = TickTableDataMessageCode -> EncodeTickTableDataMessage(message.body)
      [] message.tag = SecurityDefinitionMessageCode -> EncodeSecurityDefinitionMessage(message.body)
      [] message.tag = SecurityStatusMessageCode -> EncodeSecurityStatusMessage(message.body)
      [] message.tag = AoDUpdateMessageCode -> EncodeAoDUpdateMessage(message.body)
      [] message.tag = MaCUpdateMessageCode -> EncodeMaCUpdateMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = OrderAddCode -> DecodeOrderAdd(bytes)
              [] tag = OrderCancelCode -> DecodeOrderCancel(bytes)
              [] tag = OrderModifyCode -> DecodeOrderModify(bytes)
              [] tag = TradeCode -> DecodeTrade(bytes)
              [] tag = TradeBustMessageCode -> DecodeTradeBustMessage(bytes)
              [] tag = TickTableDataMessageCode -> DecodeTickTableDataMessage(bytes)
              [] tag = SecurityDefinitionMessageCode -> DecodeSecurityDefinitionMessage(bytes)
              [] tag = SecurityStatusMessageCode -> DecodeSecurityStatusMessage(bytes)
              [] tag = AoDUpdateMessageCode -> DecodeAoDUpdateMessage(bytes)
              [] tag = MaCUpdateMessageCode -> DecodeMaCUpdateMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> OrderAddCode, body |-> ZeroOrderAdd]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> OrderAddCode, body |-> one] : one \in CheckedOrderAdd }
        \cup { [tag |-> OrderCancelCode, body |-> one] : one \in CheckedOrderCancel }
        \cup { [tag |-> OrderModifyCode, body |-> one] : one \in CheckedOrderModify }
        \cup { [tag |-> TradeCode, body |-> one] : one \in CheckedTrade }
        \cup { [tag |-> TradeBustMessageCode, body |-> one] : one \in CheckedTradeBustMessage }
        \cup { [tag |-> TickTableDataMessageCode, body |-> one] : one \in CheckedTickTableDataMessage }
        \cup { [tag |-> SecurityDefinitionMessageCode, body |-> one] : one \in CheckedSecurityDefinitionMessage }
        \cup { [tag |-> SecurityStatusMessageCode, body |-> one] : one \in CheckedSecurityStatusMessage }
        \cup { [tag |-> AoDUpdateMessageCode, body |-> one] : one \in CheckedAoDUpdateMessage }
        \cup { [tag |-> MaCUpdateMessageCode, body |-> one] : one \in CheckedMaCUpdateMessage }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> OrderAddCode, body |-> ZeroOrderAdd]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelCode, body |-> ZeroOrderCancel]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifyCode, body |-> ZeroOrderModify]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCode, body |-> ZeroTrade]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBustMessageCode, body |-> ZeroTradeBustMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TickTableDataMessageCode, body |-> ZeroTickTableDataMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionMessageCode, body |-> ZeroSecurityDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatusMessageCode, body |-> ZeroSecurityStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AoDUpdateMessageCode, body |-> ZeroAoDUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MaCUpdateMessageCode, body |-> ZeroMaCUpdateMessage]] }

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

(* Every Order Add decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAdd ==
    \A message \in CheckedOrderAdd :
        LET read == DecodeOrderAdd(EncodeOrderAdd(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancel ==
    \A message \in CheckedOrderCancel :
        LET read == DecodeOrderCancel(EncodeOrderCancel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModify ==
    \A message \in CheckedOrderModify :
        LET read == DecodeOrderModify(EncodeOrderModify(message))
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

(* Every Ao D Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAoDUpdateMessage ==
    \A message \in CheckedAoDUpdateMessage :
        LET read == DecodeAoDUpdateMessage(EncodeAoDUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ma C Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMaCUpdateMessage ==
    \A message \in CheckedMaCUpdateMessage :
        LET read == DecodeMaCUpdateMessage(EncodeMaCUpdateMessage(message))
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
