----------------- MODULE AsiaNextDerivatives_RealTime_v1_3 -----------------
(***************************************************************************)
(* AsiaNext Real Time Market Data Feed v1.3                                *)
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
(* Sequence Number Reset Message: 4 bytes                                  *)
(***************************************************************************)

SequenceNumberResetMessage ==
    [ nextSeqNo : Sample(4) ]

EncodeSequenceNumberResetMessage(message) ==
    message.nextSeqNo

DecodeSequenceNumberResetMessage(bytes) ==
    LET nextSeqNo == ReadBytes(bytes, 4) IN IF ~nextSeqNo.ok THEN Fail ELSE
    Ok([ nextSeqNo |-> nextSeqNo.value ], nextSeqNo.rest)

ZeroSequenceNumberResetMessage ==
    [ nextSeqNo |-> [i \in 1 .. 4 |-> 0] ]

(* Sequence Number Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceNumberResetMessage ==
    { ZeroSequenceNumberResetMessage }
        \cup { [ZeroSequenceNumberResetMessage EXCEPT !.nextSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Add Message: 37 bytes                                             *)
(***************************************************************************)

OrderAddMessage ==
    [ securityId : Sample(4),
      side       : Sample(1),
      quantity   : Sample(8),
      price      : Sample(8),
      orderRef   : Sample(8),
      timestamp  : Sample(8) ]

EncodeOrderAddMessage(message) ==
    message.securityId
        \o message.side
        \o message.quantity
        \o message.price
        \o message.orderRef
        \o message.timestamp

DecodeOrderAddMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderRef == ReadBytes(price.rest, 8) IN IF ~orderRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(orderRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         side       |-> side.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         orderRef   |-> orderRef.value,
         timestamp  |-> timestamp.value ], timestamp.rest)

ZeroOrderAddMessage ==
    [ securityId |-> [i \in 1 .. 4 |-> 0],
      side       |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 8 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      orderRef   |-> [i \in 1 .. 8 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0] ]

(* Order Add Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddMessage ==
    { ZeroOrderAddMessage }
        \cup { [ZeroOrderAddMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.orderRef = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancel Message: 20 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ securityId : Sample(4),
      orderRef   : Sample(8),
      timestamp  : Sample(8) ]

EncodeOrderCancelMessage(message) ==
    message.securityId
        \o message.orderRef
        \o message.timestamp

DecodeOrderCancelMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET orderRef == ReadBytes(securityId.rest, 8) IN IF ~orderRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(orderRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         orderRef   |-> orderRef.value,
         timestamp  |-> timestamp.value ], timestamp.rest)

ZeroOrderCancelMessage ==
    [ securityId |-> [i \in 1 .. 4 |-> 0],
      orderRef   |-> [i \in 1 .. 8 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderRef = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Modify Message: 36 bytes                                          *)
(***************************************************************************)

OrderModifyMessage ==
    [ securityId : Sample(4),
      quantity   : Sample(8),
      price      : Sample(8),
      orderRef   : Sample(8),
      timestamp  : Sample(8) ]

EncodeOrderModifyMessage(message) ==
    message.securityId
        \o message.quantity
        \o message.price
        \o message.orderRef
        \o message.timestamp

DecodeOrderModifyMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET quantity == ReadBytes(securityId.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderRef == ReadBytes(price.rest, 8) IN IF ~orderRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(orderRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         orderRef   |-> orderRef.value,
         timestamp  |-> timestamp.value ], timestamp.rest)

ZeroOrderModifyMessage ==
    [ securityId |-> [i \in 1 .. 4 |-> 0],
      quantity   |-> [i \in 1 .. 8 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      orderRef   |-> [i \in 1 .. 8 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0] ]

(* Order Modify Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyMessage ==
    { ZeroOrderModifyMessage }
        \cup { [ZeroOrderModifyMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.orderRef = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 49 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ securityId : Sample(4),
      tradeType  : Sample(1),
      quantity   : Sample(8),
      price      : Sample(8),
      orderRef   : Sample(8),
      tradeRef   : Sample(8),
      timestamp  : Sample(8),
      binaryMmt  : Sample(4) ]

EncodeTradeMessage(message) ==
    message.securityId
        \o message.tradeType
        \o message.quantity
        \o message.price
        \o message.orderRef
        \o message.tradeRef
        \o message.timestamp
        \o message.binaryMmt

DecodeTradeMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET tradeType == ReadBytes(securityId.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradeType.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderRef == ReadBytes(price.rest, 8) IN IF ~orderRef.ok THEN Fail ELSE
    LET tradeRef == ReadBytes(orderRef.rest, 8) IN IF ~tradeRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(tradeRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET binaryMmt == ReadBytes(timestamp.rest, 4) IN IF ~binaryMmt.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         tradeType  |-> tradeType.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         orderRef   |-> orderRef.value,
         tradeRef   |-> tradeRef.value,
         timestamp  |-> timestamp.value,
         binaryMmt  |-> binaryMmt.value ], binaryMmt.rest)

ZeroTradeMessage ==
    [ securityId |-> [i \in 1 .. 4 |-> 0],
      tradeType  |-> [i \in 1 .. 1 |-> 0],
      quantity   |-> [i \in 1 .. 8 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      orderRef   |-> [i \in 1 .. 8 |-> 0],
      tradeRef   |-> [i \in 1 .. 8 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0],
      binaryMmt  |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.orderRef = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeRef = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.binaryMmt = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Bust Message: 40 bytes                                            *)
(***************************************************************************)

TradeBustMessage ==
    [ securityId : Sample(4),
      quantity   : Sample(8),
      price      : Sample(8),
      tradeRef   : Sample(8),
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
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET quantity == ReadBytes(securityId.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET tradeRef == ReadBytes(price.rest, 8) IN IF ~tradeRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(tradeRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET binaryMmt == ReadBytes(timestamp.rest, 4) IN IF ~binaryMmt.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value,
         quantity   |-> quantity.value,
         price      |-> price.value,
         tradeRef   |-> tradeRef.value,
         timestamp  |-> timestamp.value,
         binaryMmt  |-> binaryMmt.value ], binaryMmt.rest)

ZeroTradeBustMessage ==
    [ securityId |-> [i \in 1 .. 4 |-> 0],
      quantity   |-> [i \in 1 .. 8 |-> 0],
      price      |-> [i \in 1 .. 8 |-> 0],
      tradeRef   |-> [i \in 1 .. 8 |-> 0],
      timestamp  |-> [i \in 1 .. 8 |-> 0],
      binaryMmt  |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Bust Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustMessage ==
    { ZeroTradeBustMessage }
        \cup { [ZeroTradeBustMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.tradeRef = one] : one \in Sample(8) }
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
(* Lot Size Composite: 9 bytes                                             *)
(***************************************************************************)

LotSizeComposite ==
    [ lotSize        : Sample(8),
      lotSizeDecimal : Sample(1) ]

EncodeLotSizeComposite(message) ==
    message.lotSize
        \o message.lotSizeDecimal

DecodeLotSizeComposite(bytes) ==
    LET lotSize == ReadBytes(bytes, 8) IN IF ~lotSize.ok THEN Fail ELSE
    LET lotSizeDecimal == ReadBytes(lotSize.rest, 1) IN IF ~lotSizeDecimal.ok THEN Fail ELSE
    Ok([ lotSize        |-> lotSize.value,
         lotSizeDecimal |-> lotSizeDecimal.value ], lotSizeDecimal.rest)

ZeroLotSizeComposite ==
    [ lotSize        |-> [i \in 1 .. 8 |-> 0],
      lotSizeDecimal |-> [i \in 1 .. 1 |-> 0] ]

(* Lot Size Composite at zero, then each field in turn at the values it is checked at *)
CheckedLotSizeComposite ==
    { ZeroLotSizeComposite }
        \cup { [ZeroLotSizeComposite EXCEPT !.lotSize = one] : one \in Sample(8) }
        \cup { [ZeroLotSizeComposite EXCEPT !.lotSizeDecimal = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Definition Message: 61 bytes                                   *)
(***************************************************************************)

SecurityDefinitionMessage ==
    [ securityId       : Sample(4),
      umtf             : Sample(6),
      isin             : Sample(12),
      currency         : Sample(3),
      mic              : Sample(4),
      tickTableId      : Sample(1),
      flags            : Sample(2),
      exchangeSymbol   : Sample(20),
      lotSizeComposite : LotSizeComposite ]

EncodeSecurityDefinitionMessage(message) ==
    message.securityId
        \o message.umtf
        \o message.isin
        \o message.currency
        \o message.mic
        \o message.tickTableId
        \o message.flags
        \o message.exchangeSymbol
        \o EncodeLotSizeComposite(message.lotSizeComposite)

DecodeSecurityDefinitionMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET umtf == ReadBytes(securityId.rest, 6) IN IF ~umtf.ok THEN Fail ELSE
    LET isin == ReadBytes(umtf.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET currency == ReadBytes(isin.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET mic == ReadBytes(currency.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET tickTableId == ReadBytes(mic.rest, 1) IN IF ~tickTableId.ok THEN Fail ELSE
    LET flags == ReadBytes(tickTableId.rest, 2) IN IF ~flags.ok THEN Fail ELSE
    LET exchangeSymbol == ReadBytes(flags.rest, 20) IN IF ~exchangeSymbol.ok THEN Fail ELSE
    LET lotSizeComposite == DecodeLotSizeComposite(exchangeSymbol.rest) IN IF ~lotSizeComposite.ok THEN Fail ELSE
    Ok([ securityId       |-> securityId.value,
         umtf             |-> umtf.value,
         isin             |-> isin.value,
         currency         |-> currency.value,
         mic              |-> mic.value,
         tickTableId      |-> tickTableId.value,
         flags            |-> flags.value,
         exchangeSymbol   |-> exchangeSymbol.value,
         lotSizeComposite |-> lotSizeComposite.value ], lotSizeComposite.rest)

ZeroSecurityDefinitionMessage ==
    [ securityId       |-> [i \in 1 .. 4 |-> 0],
      umtf             |-> [i \in 1 .. 6 |-> 0],
      isin             |-> [i \in 1 .. 12 |-> 0],
      currency         |-> [i \in 1 .. 3 |-> 0],
      mic              |-> [i \in 1 .. 4 |-> 0],
      tickTableId      |-> [i \in 1 .. 1 |-> 0],
      flags            |-> [i \in 1 .. 2 |-> 0],
      exchangeSymbol   |-> [i \in 1 .. 20 |-> 0],
      lotSizeComposite |-> ZeroLotSizeComposite ]

(* Security Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessage ==
    { ZeroSecurityDefinitionMessage }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.umtf = one] : one \in Sample(6) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.tickTableId = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.flags = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.exchangeSymbol = one] : one \in Sample(20) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.lotSizeComposite = one] : one \in CheckedLotSizeComposite }

(***************************************************************************)
(* Lot Size Composite: 9 bytes                                             *)
(***************************************************************************)

LotSizeComposite2 ==
    [ lotSize        : Sample(8),
      lotSizeDecimal : Sample(1) ]

EncodeLotSizeComposite2(message) ==
    message.lotSize
        \o message.lotSizeDecimal

DecodeLotSizeComposite2(bytes) ==
    LET lotSize == ReadBytes(bytes, 8) IN IF ~lotSize.ok THEN Fail ELSE
    LET lotSizeDecimal == ReadBytes(lotSize.rest, 1) IN IF ~lotSizeDecimal.ok THEN Fail ELSE
    Ok([ lotSize        |-> lotSize.value,
         lotSizeDecimal |-> lotSizeDecimal.value ], lotSizeDecimal.rest)

ZeroLotSizeComposite2 ==
    [ lotSize        |-> [i \in 1 .. 8 |-> 0],
      lotSizeDecimal |-> [i \in 1 .. 1 |-> 0] ]

(* Lot Size Composite at zero, then each field in turn at the values it is checked at *)
CheckedLotSizeComposite2 ==
    { ZeroLotSizeComposite2 }
        \cup { [ZeroLotSizeComposite2 EXCEPT !.lotSize = one] : one \in Sample(8) }
        \cup { [ZeroLotSizeComposite2 EXCEPT !.lotSizeDecimal = one] : one \in Sample(1) }

(***************************************************************************)
(* Contract Size Composite: 9 bytes                                        *)
(***************************************************************************)

ContractSizeComposite ==
    [ contractSize         : Sample(8),
      contractSizeDecimals : Sample(1) ]

EncodeContractSizeComposite(message) ==
    message.contractSize
        \o message.contractSizeDecimals

DecodeContractSizeComposite(bytes) ==
    LET contractSize == ReadBytes(bytes, 8) IN IF ~contractSize.ok THEN Fail ELSE
    LET contractSizeDecimals == ReadBytes(contractSize.rest, 1) IN IF ~contractSizeDecimals.ok THEN Fail ELSE
    Ok([ contractSize         |-> contractSize.value,
         contractSizeDecimals |-> contractSizeDecimals.value ], contractSizeDecimals.rest)

ZeroContractSizeComposite ==
    [ contractSize         |-> [i \in 1 .. 8 |-> 0],
      contractSizeDecimals |-> [i \in 1 .. 1 |-> 0] ]

(* Contract Size Composite at zero, then each field in turn at the values it is checked at *)
CheckedContractSizeComposite ==
    { ZeroContractSizeComposite }
        \cup { [ZeroContractSizeComposite EXCEPT !.contractSize = one] : one \in Sample(8) }
        \cup { [ZeroContractSizeComposite EXCEPT !.contractSizeDecimals = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Definition Futures Message: 99 bytes                           *)
(***************************************************************************)

SecurityDefinitionFuturesMessage ==
    [ securityId            : Sample(4),
      umtf                  : Sample(6),
      isin                  : Sample(12),
      currency              : Sample(3),
      mic                   : Sample(4),
      tickTableId           : Sample(1),
      futuresFlags          : Sample(2),
      exchangeSymbol        : Sample(20),
      lotSizeComposite      : LotSizeComposite2,
      maturityDate          : Sample(8),
      settlementType        : Sample(1),
      contractSizeComposite : ContractSizeComposite,
      underlying            : Sample(20) ]

EncodeSecurityDefinitionFuturesMessage(message) ==
    message.securityId
        \o message.umtf
        \o message.isin
        \o message.currency
        \o message.mic
        \o message.tickTableId
        \o message.futuresFlags
        \o message.exchangeSymbol
        \o EncodeLotSizeComposite2(message.lotSizeComposite)
        \o message.maturityDate
        \o message.settlementType
        \o EncodeContractSizeComposite(message.contractSizeComposite)
        \o message.underlying

DecodeSecurityDefinitionFuturesMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET umtf == ReadBytes(securityId.rest, 6) IN IF ~umtf.ok THEN Fail ELSE
    LET isin == ReadBytes(umtf.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET currency == ReadBytes(isin.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET mic == ReadBytes(currency.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET tickTableId == ReadBytes(mic.rest, 1) IN IF ~tickTableId.ok THEN Fail ELSE
    LET futuresFlags == ReadBytes(tickTableId.rest, 2) IN IF ~futuresFlags.ok THEN Fail ELSE
    LET exchangeSymbol == ReadBytes(futuresFlags.rest, 20) IN IF ~exchangeSymbol.ok THEN Fail ELSE
    LET lotSizeComposite == DecodeLotSizeComposite2(exchangeSymbol.rest) IN IF ~lotSizeComposite.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(lotSizeComposite.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET settlementType == ReadBytes(maturityDate.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET contractSizeComposite == DecodeContractSizeComposite(settlementType.rest) IN IF ~contractSizeComposite.ok THEN Fail ELSE
    LET underlying == ReadBytes(contractSizeComposite.rest, 20) IN IF ~underlying.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         umtf                  |-> umtf.value,
         isin                  |-> isin.value,
         currency              |-> currency.value,
         mic                   |-> mic.value,
         tickTableId           |-> tickTableId.value,
         futuresFlags          |-> futuresFlags.value,
         exchangeSymbol        |-> exchangeSymbol.value,
         lotSizeComposite      |-> lotSizeComposite.value,
         maturityDate          |-> maturityDate.value,
         settlementType        |-> settlementType.value,
         contractSizeComposite |-> contractSizeComposite.value,
         underlying            |-> underlying.value ], underlying.rest)

ZeroSecurityDefinitionFuturesMessage ==
    [ securityId            |-> [i \in 1 .. 4 |-> 0],
      umtf                  |-> [i \in 1 .. 6 |-> 0],
      isin                  |-> [i \in 1 .. 12 |-> 0],
      currency              |-> [i \in 1 .. 3 |-> 0],
      mic                   |-> [i \in 1 .. 4 |-> 0],
      tickTableId           |-> [i \in 1 .. 1 |-> 0],
      futuresFlags          |-> [i \in 1 .. 2 |-> 0],
      exchangeSymbol        |-> [i \in 1 .. 20 |-> 0],
      lotSizeComposite      |-> ZeroLotSizeComposite2,
      maturityDate          |-> [i \in 1 .. 8 |-> 0],
      settlementType        |-> [i \in 1 .. 1 |-> 0],
      contractSizeComposite |-> ZeroContractSizeComposite,
      underlying            |-> [i \in 1 .. 20 |-> 0] ]

(* Security Definition Futures Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionFuturesMessage ==
    { ZeroSecurityDefinitionFuturesMessage }
        \cup { [ZeroSecurityDefinitionFuturesMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionFuturesMessage EXCEPT !.umtf = one] : one \in Sample(6) }
        \cup { [ZeroSecurityDefinitionFuturesMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroSecurityDefinitionFuturesMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionFuturesMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionFuturesMessage EXCEPT !.tickTableId = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionFuturesMessage EXCEPT !.futuresFlags = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionFuturesMessage EXCEPT !.exchangeSymbol = one] : one \in Sample(20) }
        \cup { [ZeroSecurityDefinitionFuturesMessage EXCEPT !.lotSizeComposite = one] : one \in CheckedLotSizeComposite2 }
        \cup { [ZeroSecurityDefinitionFuturesMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionFuturesMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionFuturesMessage EXCEPT !.contractSizeComposite = one] : one \in CheckedContractSizeComposite }
        \cup { [ZeroSecurityDefinitionFuturesMessage EXCEPT !.underlying = one] : one \in Sample(20) }

(***************************************************************************)
(* Lot Size Composite: 9 bytes                                             *)
(***************************************************************************)

LotSizeComposite3 ==
    [ lotSize        : Sample(8),
      lotSizeDecimal : Sample(1) ]

EncodeLotSizeComposite3(message) ==
    message.lotSize
        \o message.lotSizeDecimal

DecodeLotSizeComposite3(bytes) ==
    LET lotSize == ReadBytes(bytes, 8) IN IF ~lotSize.ok THEN Fail ELSE
    LET lotSizeDecimal == ReadBytes(lotSize.rest, 1) IN IF ~lotSizeDecimal.ok THEN Fail ELSE
    Ok([ lotSize        |-> lotSize.value,
         lotSizeDecimal |-> lotSizeDecimal.value ], lotSizeDecimal.rest)

ZeroLotSizeComposite3 ==
    [ lotSize        |-> [i \in 1 .. 8 |-> 0],
      lotSizeDecimal |-> [i \in 1 .. 1 |-> 0] ]

(* Lot Size Composite at zero, then each field in turn at the values it is checked at *)
CheckedLotSizeComposite3 ==
    { ZeroLotSizeComposite3 }
        \cup { [ZeroLotSizeComposite3 EXCEPT !.lotSize = one] : one \in Sample(8) }
        \cup { [ZeroLotSizeComposite3 EXCEPT !.lotSizeDecimal = one] : one \in Sample(1) }

(***************************************************************************)
(* Contract Size Composite: 9 bytes                                        *)
(***************************************************************************)

ContractSizeComposite2 ==
    [ contractSize         : Sample(8),
      contractSizeDecimals : Sample(1) ]

EncodeContractSizeComposite2(message) ==
    message.contractSize
        \o message.contractSizeDecimals

DecodeContractSizeComposite2(bytes) ==
    LET contractSize == ReadBytes(bytes, 8) IN IF ~contractSize.ok THEN Fail ELSE
    LET contractSizeDecimals == ReadBytes(contractSize.rest, 1) IN IF ~contractSizeDecimals.ok THEN Fail ELSE
    Ok([ contractSize         |-> contractSize.value,
         contractSizeDecimals |-> contractSizeDecimals.value ], contractSizeDecimals.rest)

ZeroContractSizeComposite2 ==
    [ contractSize         |-> [i \in 1 .. 8 |-> 0],
      contractSizeDecimals |-> [i \in 1 .. 1 |-> 0] ]

(* Contract Size Composite at zero, then each field in turn at the values it is checked at *)
CheckedContractSizeComposite2 ==
    { ZeroContractSizeComposite2 }
        \cup { [ZeroContractSizeComposite2 EXCEPT !.contractSize = one] : one \in Sample(8) }
        \cup { [ZeroContractSizeComposite2 EXCEPT !.contractSizeDecimals = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Definition Options Message: 109 bytes                          *)
(***************************************************************************)

SecurityDefinitionOptionsMessage ==
    [ securityId            : Sample(4),
      umtf                  : Sample(6),
      isin                  : Sample(12),
      currency              : Sample(3),
      mic                   : Sample(4),
      tickTableId           : Sample(1),
      optionsFlags          : Sample(2),
      exchangeSymbol        : Sample(20),
      lotSizeComposite      : LotSizeComposite3,
      maturityDate          : Sample(8),
      settlementType        : Sample(1),
      contractSizeComposite : ContractSizeComposite2,
      underlying            : Sample(20),
      optionType            : Sample(1),
      exerciseStyle         : Sample(1),
      strikePrice           : Sample(8) ]

EncodeSecurityDefinitionOptionsMessage(message) ==
    message.securityId
        \o message.umtf
        \o message.isin
        \o message.currency
        \o message.mic
        \o message.tickTableId
        \o message.optionsFlags
        \o message.exchangeSymbol
        \o EncodeLotSizeComposite3(message.lotSizeComposite)
        \o message.maturityDate
        \o message.settlementType
        \o EncodeContractSizeComposite2(message.contractSizeComposite)
        \o message.underlying
        \o message.optionType
        \o message.exerciseStyle
        \o message.strikePrice

DecodeSecurityDefinitionOptionsMessage(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET umtf == ReadBytes(securityId.rest, 6) IN IF ~umtf.ok THEN Fail ELSE
    LET isin == ReadBytes(umtf.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET currency == ReadBytes(isin.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET mic == ReadBytes(currency.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET tickTableId == ReadBytes(mic.rest, 1) IN IF ~tickTableId.ok THEN Fail ELSE
    LET optionsFlags == ReadBytes(tickTableId.rest, 2) IN IF ~optionsFlags.ok THEN Fail ELSE
    LET exchangeSymbol == ReadBytes(optionsFlags.rest, 20) IN IF ~exchangeSymbol.ok THEN Fail ELSE
    LET lotSizeComposite == DecodeLotSizeComposite3(exchangeSymbol.rest) IN IF ~lotSizeComposite.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(lotSizeComposite.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET settlementType == ReadBytes(maturityDate.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET contractSizeComposite == DecodeContractSizeComposite2(settlementType.rest) IN IF ~contractSizeComposite.ok THEN Fail ELSE
    LET underlying == ReadBytes(contractSizeComposite.rest, 20) IN IF ~underlying.ok THEN Fail ELSE
    LET optionType == ReadBytes(underlying.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(optionType.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(exerciseStyle.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    Ok([ securityId            |-> securityId.value,
         umtf                  |-> umtf.value,
         isin                  |-> isin.value,
         currency              |-> currency.value,
         mic                   |-> mic.value,
         tickTableId           |-> tickTableId.value,
         optionsFlags          |-> optionsFlags.value,
         exchangeSymbol        |-> exchangeSymbol.value,
         lotSizeComposite      |-> lotSizeComposite.value,
         maturityDate          |-> maturityDate.value,
         settlementType        |-> settlementType.value,
         contractSizeComposite |-> contractSizeComposite.value,
         underlying            |-> underlying.value,
         optionType            |-> optionType.value,
         exerciseStyle         |-> exerciseStyle.value,
         strikePrice           |-> strikePrice.value ], strikePrice.rest)

ZeroSecurityDefinitionOptionsMessage ==
    [ securityId            |-> [i \in 1 .. 4 |-> 0],
      umtf                  |-> [i \in 1 .. 6 |-> 0],
      isin                  |-> [i \in 1 .. 12 |-> 0],
      currency              |-> [i \in 1 .. 3 |-> 0],
      mic                   |-> [i \in 1 .. 4 |-> 0],
      tickTableId           |-> [i \in 1 .. 1 |-> 0],
      optionsFlags          |-> [i \in 1 .. 2 |-> 0],
      exchangeSymbol        |-> [i \in 1 .. 20 |-> 0],
      lotSizeComposite      |-> ZeroLotSizeComposite3,
      maturityDate          |-> [i \in 1 .. 8 |-> 0],
      settlementType        |-> [i \in 1 .. 1 |-> 0],
      contractSizeComposite |-> ZeroContractSizeComposite2,
      underlying            |-> [i \in 1 .. 20 |-> 0],
      optionType            |-> [i \in 1 .. 1 |-> 0],
      exerciseStyle         |-> [i \in 1 .. 1 |-> 0],
      strikePrice           |-> [i \in 1 .. 8 |-> 0] ]

(* Security Definition Options Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionOptionsMessage ==
    { ZeroSecurityDefinitionOptionsMessage }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.umtf = one] : one \in Sample(6) }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.tickTableId = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.optionsFlags = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.exchangeSymbol = one] : one \in Sample(20) }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.lotSizeComposite = one] : one \in CheckedLotSizeComposite3 }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.contractSizeComposite = one] : one \in CheckedContractSizeComposite2 }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.underlying = one] : one \in Sample(20) }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionOptionsMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Security Status Message: 15 bytes                                       *)
(***************************************************************************)

SecurityStatusMessage ==
    [ securityId    : Sample(4),
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
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
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
    [ securityId    |-> [i \in 1 .. 4 |-> 0],
      tradingStatus |-> [i \in 1 .. 1 |-> 0],
      marketFlags   |-> [i \in 1 .. 1 |-> 0],
      timestamp     |-> [i \in 1 .. 8 |-> 0],
      tradingPhase  |-> [i \in 1 .. 1 |-> 0] ]

(* Security Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusMessage ==
    { ZeroSecurityStatusMessage }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.marketFlags = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.tradingPhase = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

HeartbeatMessageCode == 1  \* 0x01
SequenceNumberResetMessageCode == 29  \* 0x1d
OrderAddMessageCode == 2  \* 0x02
OrderCancelMessageCode == 3  \* 0x03
OrderModifyMessageCode == 4  \* 0x04
TradeMessageCode == 5  \* 0x05
TradeBustMessageCode == 6  \* 0x06
TickTableDataMessageCode == 7  \* 0x07
SecurityDefinitionMessageCode == 8  \* 0x08
SecurityDefinitionFuturesMessageCode == 30  \* 0x1e
SecurityDefinitionOptionsMessageCode == 32  \* 0x20
SecurityStatusMessageCode == 9  \* 0x09

Payload ==
    [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {SequenceNumberResetMessageCode}, body : SequenceNumberResetMessage ]
        \cup [ tag : {OrderAddMessageCode}, body : OrderAddMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {OrderModifyMessageCode}, body : OrderModifyMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeBustMessageCode}, body : TradeBustMessage ]
        \cup [ tag : {TickTableDataMessageCode}, body : TickTableDataMessage ]
        \cup [ tag : {SecurityDefinitionMessageCode}, body : SecurityDefinitionMessage ]
        \cup [ tag : {SecurityDefinitionFuturesMessageCode}, body : SecurityDefinitionFuturesMessage ]
        \cup [ tag : {SecurityDefinitionOptionsMessageCode}, body : SecurityDefinitionOptionsMessage ]
        \cup [ tag : {SecurityStatusMessageCode}, body : SecurityStatusMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = SequenceNumberResetMessageCode -> EncodeSequenceNumberResetMessage(message.body)
      [] message.tag = OrderAddMessageCode -> EncodeOrderAddMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = OrderModifyMessageCode -> EncodeOrderModifyMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeBustMessageCode -> EncodeTradeBustMessage(message.body)
      [] message.tag = TickTableDataMessageCode -> EncodeTickTableDataMessage(message.body)
      [] message.tag = SecurityDefinitionMessageCode -> EncodeSecurityDefinitionMessage(message.body)
      [] message.tag = SecurityDefinitionFuturesMessageCode -> EncodeSecurityDefinitionFuturesMessage(message.body)
      [] message.tag = SecurityDefinitionOptionsMessageCode -> EncodeSecurityDefinitionOptionsMessage(message.body)
      [] message.tag = SecurityStatusMessageCode -> EncodeSecurityStatusMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = SequenceNumberResetMessageCode -> DecodeSequenceNumberResetMessage(bytes)
              [] tag = OrderAddMessageCode -> DecodeOrderAddMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = OrderModifyMessageCode -> DecodeOrderModifyMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeBustMessageCode -> DecodeTradeBustMessage(bytes)
              [] tag = TickTableDataMessageCode -> DecodeTickTableDataMessage(bytes)
              [] tag = SecurityDefinitionMessageCode -> DecodeSecurityDefinitionMessage(bytes)
              [] tag = SecurityDefinitionFuturesMessageCode -> DecodeSecurityDefinitionFuturesMessage(bytes)
              [] tag = SecurityDefinitionOptionsMessageCode -> DecodeSecurityDefinitionOptionsMessage(bytes)
              [] tag = SecurityStatusMessageCode -> DecodeSecurityStatusMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> SequenceNumberResetMessageCode, body |-> one] : one \in CheckedSequenceNumberResetMessage }
        \cup { [tag |-> OrderAddMessageCode, body |-> one] : one \in CheckedOrderAddMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> OrderModifyMessageCode, body |-> one] : one \in CheckedOrderModifyMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeBustMessageCode, body |-> one] : one \in CheckedTradeBustMessage }
        \cup { [tag |-> TickTableDataMessageCode, body |-> one] : one \in CheckedTickTableDataMessage }
        \cup { [tag |-> SecurityDefinitionMessageCode, body |-> one] : one \in CheckedSecurityDefinitionMessage }
        \cup { [tag |-> SecurityDefinitionFuturesMessageCode, body |-> one] : one \in CheckedSecurityDefinitionFuturesMessage }
        \cup { [tag |-> SecurityDefinitionOptionsMessageCode, body |-> one] : one \in CheckedSecurityDefinitionOptionsMessage }
        \cup { [tag |-> SecurityStatusMessageCode, body |-> one] : one \in CheckedSecurityStatusMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> SequenceNumberResetMessageCode, body |-> ZeroSequenceNumberResetMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAddMessageCode, body |-> ZeroOrderAddMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelMessageCode, body |-> ZeroOrderCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifyMessageCode, body |-> ZeroOrderModifyMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBustMessageCode, body |-> ZeroTradeBustMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TickTableDataMessageCode, body |-> ZeroTickTableDataMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionMessageCode, body |-> ZeroSecurityDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionFuturesMessageCode, body |-> ZeroSecurityDefinitionFuturesMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionOptionsMessageCode, body |-> ZeroSecurityDefinitionOptionsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatusMessageCode, body |-> ZeroSecurityStatusMessage]] }

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

(* Every Sequence Number Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceNumberResetMessage ==
    \A message \in CheckedSequenceNumberResetMessage :
        LET read == DecodeSequenceNumberResetMessage(EncodeSequenceNumberResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

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

(* Every Lot Size Composite decodes back to what was encoded, and leaves nothing over *)
RoundTripLotSizeComposite ==
    \A message \in CheckedLotSizeComposite :
        LET read == DecodeLotSizeComposite(EncodeLotSizeComposite(message))
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

(* Every Lot Size Composite decodes back to what was encoded, and leaves nothing over *)
RoundTripLotSizeComposite2 ==
    \A message \in CheckedLotSizeComposite2 :
        LET read == DecodeLotSizeComposite2(EncodeLotSizeComposite2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Size Composite decodes back to what was encoded, and leaves nothing over *)
RoundTripContractSizeComposite ==
    \A message \in CheckedContractSizeComposite :
        LET read == DecodeContractSizeComposite(EncodeContractSizeComposite(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Futures Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionFuturesMessage ==
    \A message \in CheckedSecurityDefinitionFuturesMessage :
        LET read == DecodeSecurityDefinitionFuturesMessage(EncodeSecurityDefinitionFuturesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Lot Size Composite decodes back to what was encoded, and leaves nothing over *)
RoundTripLotSizeComposite3 ==
    \A message \in CheckedLotSizeComposite3 :
        LET read == DecodeLotSizeComposite3(EncodeLotSizeComposite3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Size Composite decodes back to what was encoded, and leaves nothing over *)
RoundTripContractSizeComposite2 ==
    \A message \in CheckedContractSizeComposite2 :
        LET read == DecodeContractSizeComposite2(EncodeContractSizeComposite2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Options Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionOptionsMessage ==
    \A message \in CheckedSecurityDefinitionOptionsMessage :
        LET read == DecodeSecurityDefinitionOptionsMessage(EncodeSecurityDefinitionOptionsMessage(message))
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
