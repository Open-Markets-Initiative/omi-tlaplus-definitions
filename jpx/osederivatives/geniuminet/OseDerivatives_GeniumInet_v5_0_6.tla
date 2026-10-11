----------------- MODULE OseDerivatives_GeniumInet_v5_0_6 ------------------
(***************************************************************************)
(* Japan Exchange Group Genium Inet v5.0.6                                 *)
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
(*                                                                         *)
(* Note: Order Attributes is a bit field set, checked as its 2 bytes       *)
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
(* Seconds Message: 4 bytes                                                *)
(***************************************************************************)

SecondsMessage ==
    [ seconds : Sample(4) ]

EncodeSecondsMessage(message) ==
    message.seconds

DecodeSecondsMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    Ok([ seconds |-> seconds.value ], seconds.rest)

ZeroSecondsMessage ==
    [ seconds |-> [i \in 1 .. 4 |-> 0] ]

(* Seconds Message at zero, then each field in turn at the values it is checked at *)
CheckedSecondsMessage ==
    { ZeroSecondsMessage }
        \cup { [ZeroSecondsMessage EXCEPT !.seconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Book Directory: 128 bytes                                         *)
(***************************************************************************)

OrderBookDirectory ==
    [ nanoseconds            : Sample(4),
      orderBookId            : Sample(4),
      symbol                 : Sample(32),
      longName               : Sample(32),
      isin                   : Sample(12),
      financialProduct       : Sample(1),
      tradingCurrency        : Sample(3),
      decimalsInPrice        : Sample(2),
      decimalsInNominalValue : Sample(2),
      oddLotSize             : Sample(4),
      roundLotSize           : Sample(4),
      blockLotSize           : Sample(4),
      nominalValue           : Sample(8),
      numberOfLegs           : Sample(1),
      underlyingOrderbookId  : Sample(4),
      strikePrice            : Sample(4),
      expirationDate         : Sample(4),
      decimalsInStrikePrice  : Sample(2),
      putOrCall              : Sample(1) ]

EncodeOrderBookDirectory(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.symbol
        \o message.longName
        \o message.isin
        \o message.financialProduct
        \o message.tradingCurrency
        \o message.decimalsInPrice
        \o message.decimalsInNominalValue
        \o message.oddLotSize
        \o message.roundLotSize
        \o message.blockLotSize
        \o message.nominalValue
        \o message.numberOfLegs
        \o message.underlyingOrderbookId
        \o message.strikePrice
        \o message.expirationDate
        \o message.decimalsInStrikePrice
        \o message.putOrCall

DecodeOrderBookDirectory(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderBookId.rest, 32) IN IF ~symbol.ok THEN Fail ELSE
    LET longName == ReadBytes(symbol.rest, 32) IN IF ~longName.ok THEN Fail ELSE
    LET isin == ReadBytes(longName.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET financialProduct == ReadBytes(isin.rest, 1) IN IF ~financialProduct.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(financialProduct.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET decimalsInPrice == ReadBytes(tradingCurrency.rest, 2) IN IF ~decimalsInPrice.ok THEN Fail ELSE
    LET decimalsInNominalValue == ReadBytes(decimalsInPrice.rest, 2) IN IF ~decimalsInNominalValue.ok THEN Fail ELSE
    LET oddLotSize == ReadBytes(decimalsInNominalValue.rest, 4) IN IF ~oddLotSize.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(oddLotSize.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET blockLotSize == ReadBytes(roundLotSize.rest, 4) IN IF ~blockLotSize.ok THEN Fail ELSE
    LET nominalValue == ReadBytes(blockLotSize.rest, 8) IN IF ~nominalValue.ok THEN Fail ELSE
    LET numberOfLegs == ReadBytes(nominalValue.rest, 1) IN IF ~numberOfLegs.ok THEN Fail ELSE
    LET underlyingOrderbookId == ReadBytes(numberOfLegs.rest, 4) IN IF ~underlyingOrderbookId.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(underlyingOrderbookId.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(strikePrice.rest, 4) IN IF ~expirationDate.ok THEN Fail ELSE
    LET decimalsInStrikePrice == ReadBytes(expirationDate.rest, 2) IN IF ~decimalsInStrikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(decimalsInStrikePrice.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    Ok([ nanoseconds            |-> nanoseconds.value,
         orderBookId            |-> orderBookId.value,
         symbol                 |-> symbol.value,
         longName               |-> longName.value,
         isin                   |-> isin.value,
         financialProduct       |-> financialProduct.value,
         tradingCurrency        |-> tradingCurrency.value,
         decimalsInPrice        |-> decimalsInPrice.value,
         decimalsInNominalValue |-> decimalsInNominalValue.value,
         oddLotSize             |-> oddLotSize.value,
         roundLotSize           |-> roundLotSize.value,
         blockLotSize           |-> blockLotSize.value,
         nominalValue           |-> nominalValue.value,
         numberOfLegs           |-> numberOfLegs.value,
         underlyingOrderbookId  |-> underlyingOrderbookId.value,
         strikePrice            |-> strikePrice.value,
         expirationDate         |-> expirationDate.value,
         decimalsInStrikePrice  |-> decimalsInStrikePrice.value,
         putOrCall              |-> putOrCall.value ], putOrCall.rest)

ZeroOrderBookDirectory ==
    [ nanoseconds            |-> [i \in 1 .. 4 |-> 0],
      orderBookId            |-> [i \in 1 .. 4 |-> 0],
      symbol                 |-> [i \in 1 .. 32 |-> 0],
      longName               |-> [i \in 1 .. 32 |-> 0],
      isin                   |-> [i \in 1 .. 12 |-> 0],
      financialProduct       |-> [i \in 1 .. 1 |-> 0],
      tradingCurrency        |-> [i \in 1 .. 3 |-> 0],
      decimalsInPrice        |-> [i \in 1 .. 2 |-> 0],
      decimalsInNominalValue |-> [i \in 1 .. 2 |-> 0],
      oddLotSize             |-> [i \in 1 .. 4 |-> 0],
      roundLotSize           |-> [i \in 1 .. 4 |-> 0],
      blockLotSize           |-> [i \in 1 .. 4 |-> 0],
      nominalValue           |-> [i \in 1 .. 8 |-> 0],
      numberOfLegs           |-> [i \in 1 .. 1 |-> 0],
      underlyingOrderbookId  |-> [i \in 1 .. 4 |-> 0],
      strikePrice            |-> [i \in 1 .. 4 |-> 0],
      expirationDate         |-> [i \in 1 .. 4 |-> 0],
      decimalsInStrikePrice  |-> [i \in 1 .. 2 |-> 0],
      putOrCall              |-> [i \in 1 .. 1 |-> 0] ]

(* Order Book Directory at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookDirectory ==
    { ZeroOrderBookDirectory }
        \cup { [ZeroOrderBookDirectory EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.symbol = one] : one \in Sample(32) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.longName = one] : one \in Sample(32) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.financialProduct = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.decimalsInPrice = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.decimalsInNominalValue = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.oddLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.blockLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.nominalValue = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.numberOfLegs = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.underlyingOrderbookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.expirationDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.decimalsInStrikePrice = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.putOrCall = one] : one \in Sample(1) }

(***************************************************************************)
(* Combination Orderbook Leg: 17 bytes                                     *)
(***************************************************************************)

CombinationOrderbookLeg ==
    [ nanoseconds            : Sample(4),
      combinationOrderbookId : Sample(4),
      legOrderbookId         : Sample(4),
      legSide                : Sample(1),
      legRatio               : Sample(4) ]

EncodeCombinationOrderbookLeg(message) ==
    message.nanoseconds
        \o message.combinationOrderbookId
        \o message.legOrderbookId
        \o message.legSide
        \o message.legRatio

DecodeCombinationOrderbookLeg(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET combinationOrderbookId == ReadBytes(nanoseconds.rest, 4) IN IF ~combinationOrderbookId.ok THEN Fail ELSE
    LET legOrderbookId == ReadBytes(combinationOrderbookId.rest, 4) IN IF ~legOrderbookId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legOrderbookId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSide.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ nanoseconds            |-> nanoseconds.value,
         combinationOrderbookId |-> combinationOrderbookId.value,
         legOrderbookId         |-> legOrderbookId.value,
         legSide                |-> legSide.value,
         legRatio               |-> legRatio.value ], legRatio.rest)

ZeroCombinationOrderbookLeg ==
    [ nanoseconds            |-> [i \in 1 .. 4 |-> 0],
      combinationOrderbookId |-> [i \in 1 .. 4 |-> 0],
      legOrderbookId         |-> [i \in 1 .. 4 |-> 0],
      legSide                |-> [i \in 1 .. 1 |-> 0],
      legRatio               |-> [i \in 1 .. 4 |-> 0] ]

(* Combination Orderbook Leg at zero, then each field in turn at the values it is checked at *)
CheckedCombinationOrderbookLeg ==
    { ZeroCombinationOrderbookLeg }
        \cup { [ZeroCombinationOrderbookLeg EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderbookLeg EXCEPT !.combinationOrderbookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderbookLeg EXCEPT !.legOrderbookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderbookLeg EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroCombinationOrderbookLeg EXCEPT !.legRatio = one] : one \in Sample(4) }

(***************************************************************************)
(* Tick Size Table Entry: 24 bytes                                         *)
(***************************************************************************)

TickSizeTableEntry ==
    [ nanoseconds : Sample(4),
      orderBookId : Sample(4),
      tickSize    : Sample(8),
      priceFrom   : Sample(4),
      priceTo     : Sample(4) ]

EncodeTickSizeTableEntry(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.tickSize
        \o message.priceFrom
        \o message.priceTo

DecodeTickSizeTableEntry(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET tickSize == ReadBytes(orderBookId.rest, 8) IN IF ~tickSize.ok THEN Fail ELSE
    LET priceFrom == ReadBytes(tickSize.rest, 4) IN IF ~priceFrom.ok THEN Fail ELSE
    LET priceTo == ReadBytes(priceFrom.rest, 4) IN IF ~priceTo.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         orderBookId |-> orderBookId.value,
         tickSize    |-> tickSize.value,
         priceFrom   |-> priceFrom.value,
         priceTo     |-> priceTo.value ], priceTo.rest)

ZeroTickSizeTableEntry ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId |-> [i \in 1 .. 4 |-> 0],
      tickSize    |-> [i \in 1 .. 8 |-> 0],
      priceFrom   |-> [i \in 1 .. 4 |-> 0],
      priceTo     |-> [i \in 1 .. 4 |-> 0] ]

(* Tick Size Table Entry at zero, then each field in turn at the values it is checked at *)
CheckedTickSizeTableEntry ==
    { ZeroTickSizeTableEntry }
        \cup { [ZeroTickSizeTableEntry EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeTableEntry EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeTableEntry EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroTickSizeTableEntry EXCEPT !.priceFrom = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeTableEntry EXCEPT !.priceTo = one] : one \in Sample(4) }

(***************************************************************************)
(* System Event Message: 5 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ nanoseconds : Sample(4),
      eventCode   : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.nanoseconds
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET eventCode == ReadBytes(nanoseconds.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         eventCode   |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Book State Message: 28 bytes                                      *)
(***************************************************************************)

OrderBookStateMessage ==
    [ nanoseconds : Sample(4),
      orderBookId : Sample(4),
      stateName   : Sample(20) ]

EncodeOrderBookStateMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.stateName

DecodeOrderBookStateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET stateName == ReadBytes(orderBookId.rest, 20) IN IF ~stateName.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         orderBookId |-> orderBookId.value,
         stateName   |-> stateName.value ], stateName.rest)

ZeroOrderBookStateMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId |-> [i \in 1 .. 4 |-> 0],
      stateName   |-> [i \in 1 .. 20 |-> 0] ]

(* Order Book State Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookStateMessage ==
    { ZeroOrderBookStateMessage }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookStateMessage EXCEPT !.stateName = one] : one \in Sample(20) }

(***************************************************************************)
(* Add Order No Mpid: 36 bytes                                             *)
(***************************************************************************)

AddOrderNoMpid ==
    [ nanoseconds       : Sample(4),
      orderId           : Sample(8),
      orderBookId       : Sample(4),
      side              : Sample(1),
      orderBookPosition : Sample(4),
      quantity          : Sample(8),
      price             : Sample(4),
      orderAttributes   : Sample(2),
      lotType           : Sample(1) ]

EncodeAddOrderNoMpid(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.orderBookPosition
        \o message.quantity
        \o message.price
        \o message.orderAttributes
        \o message.lotType

DecodeAddOrderNoMpid(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderBookPosition == ReadBytes(side.rest, 4) IN IF ~orderBookPosition.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBookPosition.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET orderAttributes == ReadBytes(price.rest, 2) IN IF ~orderAttributes.ok THEN Fail ELSE
    LET lotType == ReadBytes(orderAttributes.rest, 1) IN IF ~lotType.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         orderId           |-> orderId.value,
         orderBookId       |-> orderBookId.value,
         side              |-> side.value,
         orderBookPosition |-> orderBookPosition.value,
         quantity          |-> quantity.value,
         price             |-> price.value,
         orderAttributes   |-> orderAttributes.value,
         lotType           |-> lotType.value ], lotType.rest)

ZeroAddOrderNoMpid ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      orderBookId       |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      orderBookPosition |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      orderAttributes   |-> [i \in 1 .. 2 |-> 0],
      lotType           |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order No Mpid at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderNoMpid ==
    { ZeroAddOrderNoMpid }
        \cup { [ZeroAddOrderNoMpid EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoMpid EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderNoMpid EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoMpid EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderNoMpid EXCEPT !.orderBookPosition = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoMpid EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderNoMpid EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoMpid EXCEPT !.orderAttributes = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderNoMpid EXCEPT !.lotType = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order With Mpid: 43 bytes                                           *)
(***************************************************************************)

AddOrderWithMpid ==
    [ nanoseconds       : Sample(4),
      orderId           : Sample(8),
      orderBookId       : Sample(4),
      side              : Sample(1),
      orderBookPosition : Sample(4),
      quantity          : Sample(8),
      price             : Sample(4),
      orderAttributes   : Sample(2),
      lotType           : Sample(1),
      participantId     : Sample(7) ]

EncodeAddOrderWithMpid(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.orderBookPosition
        \o message.quantity
        \o message.price
        \o message.orderAttributes
        \o message.lotType
        \o message.participantId

DecodeAddOrderWithMpid(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderBookPosition == ReadBytes(side.rest, 4) IN IF ~orderBookPosition.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBookPosition.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET orderAttributes == ReadBytes(price.rest, 2) IN IF ~orderAttributes.ok THEN Fail ELSE
    LET lotType == ReadBytes(orderAttributes.rest, 1) IN IF ~lotType.ok THEN Fail ELSE
    LET participantId == ReadBytes(lotType.rest, 7) IN IF ~participantId.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         orderId           |-> orderId.value,
         orderBookId       |-> orderBookId.value,
         side              |-> side.value,
         orderBookPosition |-> orderBookPosition.value,
         quantity          |-> quantity.value,
         price             |-> price.value,
         orderAttributes   |-> orderAttributes.value,
         lotType           |-> lotType.value,
         participantId     |-> participantId.value ], participantId.rest)

ZeroAddOrderWithMpid ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      orderBookId       |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      orderBookPosition |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      orderAttributes   |-> [i \in 1 .. 2 |-> 0],
      lotType           |-> [i \in 1 .. 1 |-> 0],
      participantId     |-> [i \in 1 .. 7 |-> 0] ]

(* Add Order With Mpid at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderWithMpid ==
    { ZeroAddOrderWithMpid }
        \cup { [ZeroAddOrderWithMpid EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpid EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderWithMpid EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpid EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderWithMpid EXCEPT !.orderBookPosition = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpid EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderWithMpid EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpid EXCEPT !.orderAttributes = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderWithMpid EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderWithMpid EXCEPT !.participantId = one] : one \in Sample(7) }

(***************************************************************************)
(* Order Executed Message: 51 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ nanoseconds               : Sample(4),
      orderId                   : Sample(8),
      orderBookId               : Sample(4),
      side                      : Sample(1),
      executedQuantity          : Sample(8),
      matchId                   : Sample(8),
      comboGroupId              : Sample(4),
      participantIdOwner        : Sample(7),
      participantIdCounterparty : Sample(7) ]

EncodeOrderExecutedMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.executedQuantity
        \o message.matchId
        \o message.comboGroupId
        \o message.participantIdOwner
        \o message.participantIdCounterparty

DecodeOrderExecutedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(side.rest, 8) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchId == ReadBytes(executedQuantity.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET comboGroupId == ReadBytes(matchId.rest, 4) IN IF ~comboGroupId.ok THEN Fail ELSE
    LET participantIdOwner == ReadBytes(comboGroupId.rest, 7) IN IF ~participantIdOwner.ok THEN Fail ELSE
    LET participantIdCounterparty == ReadBytes(participantIdOwner.rest, 7) IN IF ~participantIdCounterparty.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         orderId                   |-> orderId.value,
         orderBookId               |-> orderBookId.value,
         side                      |-> side.value,
         executedQuantity          |-> executedQuantity.value,
         matchId                   |-> matchId.value,
         comboGroupId              |-> comboGroupId.value,
         participantIdOwner        |-> participantIdOwner.value,
         participantIdCounterparty |-> participantIdCounterparty.value ], participantIdCounterparty.rest)

ZeroOrderExecutedMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      orderBookId               |-> [i \in 1 .. 4 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      executedQuantity          |-> [i \in 1 .. 8 |-> 0],
      matchId                   |-> [i \in 1 .. 8 |-> 0],
      comboGroupId              |-> [i \in 1 .. 4 |-> 0],
      participantIdOwner        |-> [i \in 1 .. 7 |-> 0],
      participantIdCounterparty |-> [i \in 1 .. 7 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.comboGroupId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.participantIdOwner = one] : one \in Sample(7) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.participantIdCounterparty = one] : one \in Sample(7) }

(***************************************************************************)
(* Order Executed With Price Message: 57 bytes                             *)
(***************************************************************************)

OrderExecutedWithPriceMessage ==
    [ nanoseconds               : Sample(4),
      orderId                   : Sample(8),
      orderBookId               : Sample(4),
      side                      : Sample(1),
      executedQuantity          : Sample(8),
      matchId                   : Sample(8),
      comboGroupId              : Sample(4),
      ownerParticipantId        : Sample(7),
      counterpartyParticipantId : Sample(7),
      tradePrice                : Sample(4),
      occurredAtCross           : Sample(1),
      printable                 : Sample(1) ]

EncodeOrderExecutedWithPriceMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.executedQuantity
        \o message.matchId
        \o message.comboGroupId
        \o message.ownerParticipantId
        \o message.counterpartyParticipantId
        \o message.tradePrice
        \o message.occurredAtCross
        \o message.printable

DecodeOrderExecutedWithPriceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(side.rest, 8) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchId == ReadBytes(executedQuantity.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET comboGroupId == ReadBytes(matchId.rest, 4) IN IF ~comboGroupId.ok THEN Fail ELSE
    LET ownerParticipantId == ReadBytes(comboGroupId.rest, 7) IN IF ~ownerParticipantId.ok THEN Fail ELSE
    LET counterpartyParticipantId == ReadBytes(ownerParticipantId.rest, 7) IN IF ~counterpartyParticipantId.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(counterpartyParticipantId.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET occurredAtCross == ReadBytes(tradePrice.rest, 1) IN IF ~occurredAtCross.ok THEN Fail ELSE
    LET printable == ReadBytes(occurredAtCross.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         orderId                   |-> orderId.value,
         orderBookId               |-> orderBookId.value,
         side                      |-> side.value,
         executedQuantity          |-> executedQuantity.value,
         matchId                   |-> matchId.value,
         comboGroupId              |-> comboGroupId.value,
         ownerParticipantId        |-> ownerParticipantId.value,
         counterpartyParticipantId |-> counterpartyParticipantId.value,
         tradePrice                |-> tradePrice.value,
         occurredAtCross           |-> occurredAtCross.value,
         printable                 |-> printable.value ], printable.rest)

ZeroOrderExecutedWithPriceMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      orderBookId               |-> [i \in 1 .. 4 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      executedQuantity          |-> [i \in 1 .. 8 |-> 0],
      matchId                   |-> [i \in 1 .. 8 |-> 0],
      comboGroupId              |-> [i \in 1 .. 4 |-> 0],
      ownerParticipantId        |-> [i \in 1 .. 7 |-> 0],
      counterpartyParticipantId |-> [i \in 1 .. 7 |-> 0],
      tradePrice                |-> [i \in 1 .. 4 |-> 0],
      occurredAtCross           |-> [i \in 1 .. 1 |-> 0],
      printable                 |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceMessage ==
    { ZeroOrderExecutedWithPriceMessage }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.comboGroupId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.ownerParticipantId = one] : one \in Sample(7) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.counterpartyParticipantId = one] : one \in Sample(7) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.occurredAtCross = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.printable = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Replace Message: 35 bytes                                         *)
(***************************************************************************)

OrderReplaceMessage ==
    [ nanoseconds          : Sample(4),
      orderId              : Sample(8),
      orderBookId          : Sample(4),
      side                 : Sample(1),
      newOrderbookPosition : Sample(4),
      quantity             : Sample(8),
      price                : Sample(4),
      orderAttributes      : Sample(2) ]

EncodeOrderReplaceMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.newOrderbookPosition
        \o message.quantity
        \o message.price
        \o message.orderAttributes

DecodeOrderReplaceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET newOrderbookPosition == ReadBytes(side.rest, 4) IN IF ~newOrderbookPosition.ok THEN Fail ELSE
    LET quantity == ReadBytes(newOrderbookPosition.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET orderAttributes == ReadBytes(price.rest, 2) IN IF ~orderAttributes.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         orderId              |-> orderId.value,
         orderBookId          |-> orderBookId.value,
         side                 |-> side.value,
         newOrderbookPosition |-> newOrderbookPosition.value,
         quantity             |-> quantity.value,
         price                |-> price.value,
         orderAttributes      |-> orderAttributes.value ], orderAttributes.rest)

ZeroOrderReplaceMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      newOrderbookPosition |-> [i \in 1 .. 4 |-> 0],
      quantity             |-> [i \in 1 .. 8 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      orderAttributes      |-> [i \in 1 .. 2 |-> 0] ]

(* Order Replace Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceMessage ==
    { ZeroOrderReplaceMessage }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.newOrderbookPosition = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.orderAttributes = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Delete Message: 17 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ nanoseconds : Sample(4),
      orderId     : Sample(8),
      orderBookId : Sample(4),
      side        : Sample(1) ]

EncodeOrderDeleteMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side

DecodeOrderDeleteMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         orderId     |-> orderId.value,
         orderBookId |-> orderBookId.value,
         side        |-> side.value ], side.rest)

ZeroOrderDeleteMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderId     |-> [i \in 1 .. 8 |-> 0],
      orderBookId |-> [i \in 1 .. 4 |-> 0],
      side        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Message: 49 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ nanoseconds               : Sample(4),
      matchId                   : Sample(8),
      comboGroupId              : Sample(4),
      side                      : Sample(1),
      quantity                  : Sample(8),
      orderBookId               : Sample(4),
      tradePrice                : Sample(4),
      ownerParticipantId        : Sample(7),
      counterpartyParticipantId : Sample(7),
      printable                 : Sample(1),
      occurredAtCross           : Sample(1) ]

EncodeTradeMessage(message) ==
    message.nanoseconds
        \o message.matchId
        \o message.comboGroupId
        \o message.side
        \o message.quantity
        \o message.orderBookId
        \o message.tradePrice
        \o message.ownerParticipantId
        \o message.counterpartyParticipantId
        \o message.printable
        \o message.occurredAtCross

DecodeTradeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET matchId == ReadBytes(nanoseconds.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET comboGroupId == ReadBytes(matchId.rest, 4) IN IF ~comboGroupId.ok THEN Fail ELSE
    LET side == ReadBytes(comboGroupId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(quantity.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(orderBookId.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET ownerParticipantId == ReadBytes(tradePrice.rest, 7) IN IF ~ownerParticipantId.ok THEN Fail ELSE
    LET counterpartyParticipantId == ReadBytes(ownerParticipantId.rest, 7) IN IF ~counterpartyParticipantId.ok THEN Fail ELSE
    LET printable == ReadBytes(counterpartyParticipantId.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET occurredAtCross == ReadBytes(printable.rest, 1) IN IF ~occurredAtCross.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         matchId                   |-> matchId.value,
         comboGroupId              |-> comboGroupId.value,
         side                      |-> side.value,
         quantity                  |-> quantity.value,
         orderBookId               |-> orderBookId.value,
         tradePrice                |-> tradePrice.value,
         ownerParticipantId        |-> ownerParticipantId.value,
         counterpartyParticipantId |-> counterpartyParticipantId.value,
         printable                 |-> printable.value,
         occurredAtCross           |-> occurredAtCross.value ], occurredAtCross.rest)

ZeroTradeMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      matchId                   |-> [i \in 1 .. 8 |-> 0],
      comboGroupId              |-> [i \in 1 .. 4 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      quantity                  |-> [i \in 1 .. 8 |-> 0],
      orderBookId               |-> [i \in 1 .. 4 |-> 0],
      tradePrice                |-> [i \in 1 .. 4 |-> 0],
      ownerParticipantId        |-> [i \in 1 .. 7 |-> 0],
      counterpartyParticipantId |-> [i \in 1 .. 7 |-> 0],
      printable                 |-> [i \in 1 .. 1 |-> 0],
      occurredAtCross           |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.comboGroupId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.ownerParticipantId = one] : one \in Sample(7) }
        \cup { [ZeroTradeMessage EXCEPT !.counterpartyParticipantId = one] : one \in Sample(7) }
        \cup { [ZeroTradeMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.occurredAtCross = one] : one \in Sample(1) }

(***************************************************************************)
(* Equilibrium Price Update: 52 bytes                                      *)
(***************************************************************************)

EquilibriumPriceUpdate ==
    [ nanoseconds                            : Sample(4),
      orderBookId                            : Sample(4),
      availableBidQuantityAtEquilibriumPrice : Sample(8),
      availableAskQuantityAtEquilibriumPrice : Sample(8),
      equilibriumPrice                       : Sample(4),
      reserved24                             : Sample(24) ]

EncodeEquilibriumPriceUpdate(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.availableBidQuantityAtEquilibriumPrice
        \o message.availableAskQuantityAtEquilibriumPrice
        \o message.equilibriumPrice
        \o message.reserved24

DecodeEquilibriumPriceUpdate(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET availableBidQuantityAtEquilibriumPrice == ReadBytes(orderBookId.rest, 8) IN IF ~availableBidQuantityAtEquilibriumPrice.ok THEN Fail ELSE
    LET availableAskQuantityAtEquilibriumPrice == ReadBytes(availableBidQuantityAtEquilibriumPrice.rest, 8) IN IF ~availableAskQuantityAtEquilibriumPrice.ok THEN Fail ELSE
    LET equilibriumPrice == ReadBytes(availableAskQuantityAtEquilibriumPrice.rest, 4) IN IF ~equilibriumPrice.ok THEN Fail ELSE
    LET reserved24 == ReadBytes(equilibriumPrice.rest, 24) IN IF ~reserved24.ok THEN Fail ELSE
    Ok([ nanoseconds                            |-> nanoseconds.value,
         orderBookId                            |-> orderBookId.value,
         availableBidQuantityAtEquilibriumPrice |-> availableBidQuantityAtEquilibriumPrice.value,
         availableAskQuantityAtEquilibriumPrice |-> availableAskQuantityAtEquilibriumPrice.value,
         equilibriumPrice                       |-> equilibriumPrice.value,
         reserved24                             |-> reserved24.value ], reserved24.rest)

ZeroEquilibriumPriceUpdate ==
    [ nanoseconds                            |-> [i \in 1 .. 4 |-> 0],
      orderBookId                            |-> [i \in 1 .. 4 |-> 0],
      availableBidQuantityAtEquilibriumPrice |-> [i \in 1 .. 8 |-> 0],
      availableAskQuantityAtEquilibriumPrice |-> [i \in 1 .. 8 |-> 0],
      equilibriumPrice                       |-> [i \in 1 .. 4 |-> 0],
      reserved24                             |-> [i \in 1 .. 24 |-> 0] ]

(* Equilibrium Price Update at zero, then each field in turn at the values it is checked at *)
CheckedEquilibriumPriceUpdate ==
    { ZeroEquilibriumPriceUpdate }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.availableBidQuantityAtEquilibriumPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.availableAskQuantityAtEquilibriumPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.equilibriumPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.reserved24 = one] : one \in Sample(24) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
OrderBookDirectoryCode == 82  \* "R"
CombinationOrderbookLegCode == 77  \* "M"
TickSizeTableEntryCode == 76  \* "L"
SystemEventMessageCode == 83  \* "S"
OrderBookStateMessageCode == 79  \* "O"
AddOrderNoMpidCode == 65  \* "A"
AddOrderWithMpidCode == 70  \* "F"
OrderExecutedMessageCode == 69  \* "E"
OrderExecutedWithPriceMessageCode == 67  \* "C"
OrderReplaceMessageCode == 85  \* "U"
OrderDeleteMessageCode == 68  \* "D"
TradeMessageCode == 80  \* "P"
EquilibriumPriceUpdateCode == 90  \* "Z"

Payload ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {OrderBookDirectoryCode}, body : OrderBookDirectory ]
        \cup [ tag : {CombinationOrderbookLegCode}, body : CombinationOrderbookLeg ]
        \cup [ tag : {TickSizeTableEntryCode}, body : TickSizeTableEntry ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OrderBookStateMessageCode}, body : OrderBookStateMessage ]
        \cup [ tag : {AddOrderNoMpidCode}, body : AddOrderNoMpid ]
        \cup [ tag : {AddOrderWithMpidCode}, body : AddOrderWithMpid ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceMessageCode}, body : OrderExecutedWithPriceMessage ]
        \cup [ tag : {OrderReplaceMessageCode}, body : OrderReplaceMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {EquilibriumPriceUpdateCode}, body : EquilibriumPriceUpdate ]

EncodePayload(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = OrderBookDirectoryCode -> EncodeOrderBookDirectory(message.body)
      [] message.tag = CombinationOrderbookLegCode -> EncodeCombinationOrderbookLeg(message.body)
      [] message.tag = TickSizeTableEntryCode -> EncodeTickSizeTableEntry(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OrderBookStateMessageCode -> EncodeOrderBookStateMessage(message.body)
      [] message.tag = AddOrderNoMpidCode -> EncodeAddOrderNoMpid(message.body)
      [] message.tag = AddOrderWithMpidCode -> EncodeAddOrderWithMpid(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceMessageCode -> EncodeOrderExecutedWithPriceMessage(message.body)
      [] message.tag = OrderReplaceMessageCode -> EncodeOrderReplaceMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = EquilibriumPriceUpdateCode -> EncodeEquilibriumPriceUpdate(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = OrderBookDirectoryCode -> DecodeOrderBookDirectory(bytes)
              [] tag = CombinationOrderbookLegCode -> DecodeCombinationOrderbookLeg(bytes)
              [] tag = TickSizeTableEntryCode -> DecodeTickSizeTableEntry(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OrderBookStateMessageCode -> DecodeOrderBookStateMessage(bytes)
              [] tag = AddOrderNoMpidCode -> DecodeAddOrderNoMpid(bytes)
              [] tag = AddOrderWithMpidCode -> DecodeAddOrderWithMpid(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceMessageCode -> DecodeOrderExecutedWithPriceMessage(bytes)
              [] tag = OrderReplaceMessageCode -> DecodeOrderReplaceMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = EquilibriumPriceUpdateCode -> DecodeEquilibriumPriceUpdate(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> OrderBookDirectoryCode, body |-> one] : one \in CheckedOrderBookDirectory }
        \cup { [tag |-> CombinationOrderbookLegCode, body |-> one] : one \in CheckedCombinationOrderbookLeg }
        \cup { [tag |-> TickSizeTableEntryCode, body |-> one] : one \in CheckedTickSizeTableEntry }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OrderBookStateMessageCode, body |-> one] : one \in CheckedOrderBookStateMessage }
        \cup { [tag |-> AddOrderNoMpidCode, body |-> one] : one \in CheckedAddOrderNoMpid }
        \cup { [tag |-> AddOrderWithMpidCode, body |-> one] : one \in CheckedAddOrderWithMpid }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceMessage }
        \cup { [tag |-> OrderReplaceMessageCode, body |-> one] : one \in CheckedOrderReplaceMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> EquilibriumPriceUpdateCode, body |-> one] : one \in CheckedEquilibriumPriceUpdate }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookDirectoryCode, body |-> ZeroOrderBookDirectory]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CombinationOrderbookLegCode, body |-> ZeroCombinationOrderbookLeg]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TickSizeTableEntryCode, body |-> ZeroTickSizeTableEntry]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookStateMessageCode, body |-> ZeroOrderBookStateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderNoMpidCode, body |-> ZeroAddOrderNoMpid]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderWithMpidCode, body |-> ZeroAddOrderWithMpid]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedWithPriceMessageCode, body |-> ZeroOrderExecutedWithPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderReplaceMessageCode, body |-> ZeroOrderReplaceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeleteMessageCode, body |-> ZeroOrderDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EquilibriumPriceUpdateCode, body |-> ZeroEquilibriumPriceUpdate]] }

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

(* Every Seconds Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondsMessage ==
    \A message \in CheckedSecondsMessage :
        LET read == DecodeSecondsMessage(EncodeSecondsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Book Directory decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookDirectory ==
    \A message \in CheckedOrderBookDirectory :
        LET read == DecodeOrderBookDirectory(EncodeOrderBookDirectory(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Combination Orderbook Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinationOrderbookLeg ==
    \A message \in CheckedCombinationOrderbookLeg :
        LET read == DecodeCombinationOrderbookLeg(EncodeCombinationOrderbookLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Size Table Entry decodes back to what was encoded, and leaves nothing over *)
RoundTripTickSizeTableEntry ==
    \A message \in CheckedTickSizeTableEntry :
        LET read == DecodeTickSizeTableEntry(EncodeTickSizeTableEntry(message))
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

(* Every Order Book State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookStateMessage ==
    \A message \in CheckedOrderBookStateMessage :
        LET read == DecodeOrderBookStateMessage(EncodeOrderBookStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order No Mpid decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderNoMpid ==
    \A message \in CheckedAddOrderNoMpid :
        LET read == DecodeAddOrderNoMpid(EncodeAddOrderNoMpid(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order With Mpid decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderWithMpid ==
    \A message \in CheckedAddOrderWithMpid :
        LET read == DecodeAddOrderWithMpid(EncodeAddOrderWithMpid(message))
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

(* Every Order Executed With Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedWithPriceMessage ==
    \A message \in CheckedOrderExecutedWithPriceMessage :
        LET read == DecodeOrderExecutedWithPriceMessage(EncodeOrderExecutedWithPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replace Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplaceMessage ==
    \A message \in CheckedOrderReplaceMessage :
        LET read == DecodeOrderReplaceMessage(EncodeOrderReplaceMessage(message))
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

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Equilibrium Price Update decodes back to what was encoded, and leaves nothing over *)
RoundTripEquilibriumPriceUpdate ==
    \A message \in CheckedEquilibriumPriceUpdate :
        LET read == DecodeEquilibriumPriceUpdate(EncodeEquilibriumPriceUpdate(message))
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
