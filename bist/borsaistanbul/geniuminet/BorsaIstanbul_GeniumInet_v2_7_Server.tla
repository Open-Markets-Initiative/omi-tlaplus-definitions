--------------- MODULE BorsaIstanbul_GeniumInet_v2_7_Server ----------------
(***************************************************************************)
(* Borsa İstanbul A.Ş. Genium Inet v2.7                                    *)
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
(* Note: Order Attributes is a bit field set, checked as its 2 bytes       *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Sequenced Data Packet fills what is left of the frame Packet      *)
(* Length states, which is what it is read from.                           *)
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
(* Debug Packet                                                            *)
(***************************************************************************)

DebugPacket ==
    [ debugText : SampleBytes ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == Ok(bytes, << >>) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> << >> ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in SampleBytes }

(***************************************************************************)
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ acceptedSession        : Sample(10),
      acceptedSequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.acceptedSession
        \o message.acceptedSequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET acceptedSession == ReadBytes(bytes, 10) IN IF ~acceptedSession.ok THEN Fail ELSE
    LET acceptedSequenceNumber == ReadBytes(acceptedSession.rest, 20) IN IF ~acceptedSequenceNumber.ok THEN Fail ELSE
    Ok([ acceptedSession        |-> acceptedSession.value,
         acceptedSequenceNumber |-> acceptedSequenceNumber.value ], acceptedSequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ acceptedSession        |-> [i \in 1 .. 10 |-> 0],
      acceptedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Seconds Message: 4 bytes                                                *)
(***************************************************************************)

SecondsMessage ==
    [ second : Sample(4) ]

EncodeSecondsMessage(message) ==
    message.second

DecodeSecondsMessage(bytes) ==
    LET second == ReadBytes(bytes, 4) IN IF ~second.ok THEN Fail ELSE
    Ok([ second |-> second.value ], second.rest)

ZeroSecondsMessage ==
    [ second |-> [i \in 1 .. 4 |-> 0] ]

(* Seconds Message at zero, then each field in turn at the values it is checked at *)
CheckedSecondsMessage ==
    { ZeroSecondsMessage }
        \cup { [ZeroSecondsMessage EXCEPT !.second = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Book Directory: 129 bytes                                         *)
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
      underlyingOrderBookId  : Sample(4),
      strikePrice            : Sample(4),
      expirationDate         : Sample(4),
      decimalsInStrikePrice  : Sample(2),
      putOrCall              : Sample(1),
      rankingType            : Sample(1) ]

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
        \o message.underlyingOrderBookId
        \o message.strikePrice
        \o message.expirationDate
        \o message.decimalsInStrikePrice
        \o message.putOrCall
        \o message.rankingType

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
    LET underlyingOrderBookId == ReadBytes(numberOfLegs.rest, 4) IN IF ~underlyingOrderBookId.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(underlyingOrderBookId.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(strikePrice.rest, 4) IN IF ~expirationDate.ok THEN Fail ELSE
    LET decimalsInStrikePrice == ReadBytes(expirationDate.rest, 2) IN IF ~decimalsInStrikePrice.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(decimalsInStrikePrice.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET rankingType == ReadBytes(putOrCall.rest, 1) IN IF ~rankingType.ok THEN Fail ELSE
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
         underlyingOrderBookId  |-> underlyingOrderBookId.value,
         strikePrice            |-> strikePrice.value,
         expirationDate         |-> expirationDate.value,
         decimalsInStrikePrice  |-> decimalsInStrikePrice.value,
         putOrCall              |-> putOrCall.value,
         rankingType            |-> rankingType.value ], rankingType.rest)

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
      underlyingOrderBookId  |-> [i \in 1 .. 4 |-> 0],
      strikePrice            |-> [i \in 1 .. 4 |-> 0],
      expirationDate         |-> [i \in 1 .. 4 |-> 0],
      decimalsInStrikePrice  |-> [i \in 1 .. 2 |-> 0],
      putOrCall              |-> [i \in 1 .. 1 |-> 0],
      rankingType            |-> [i \in 1 .. 1 |-> 0] ]

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
        \cup { [ZeroOrderBookDirectory EXCEPT !.underlyingOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.expirationDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.decimalsInStrikePrice = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.rankingType = one] : one \in Sample(1) }

(***************************************************************************)
(* Combination Order Book Leg: 17 bytes                                    *)
(***************************************************************************)

CombinationOrderBookLeg ==
    [ nanoseconds            : Sample(4),
      combinationOrderBookId : Sample(4),
      legOrderBookId         : Sample(4),
      legSide                : Sample(1),
      legRatio               : Sample(4) ]

EncodeCombinationOrderBookLeg(message) ==
    message.nanoseconds
        \o message.combinationOrderBookId
        \o message.legOrderBookId
        \o message.legSide
        \o message.legRatio

DecodeCombinationOrderBookLeg(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET combinationOrderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~combinationOrderBookId.ok THEN Fail ELSE
    LET legOrderBookId == ReadBytes(combinationOrderBookId.rest, 4) IN IF ~legOrderBookId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legOrderBookId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSide.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ nanoseconds            |-> nanoseconds.value,
         combinationOrderBookId |-> combinationOrderBookId.value,
         legOrderBookId         |-> legOrderBookId.value,
         legSide                |-> legSide.value,
         legRatio               |-> legRatio.value ], legRatio.rest)

ZeroCombinationOrderBookLeg ==
    [ nanoseconds            |-> [i \in 1 .. 4 |-> 0],
      combinationOrderBookId |-> [i \in 1 .. 4 |-> 0],
      legOrderBookId         |-> [i \in 1 .. 4 |-> 0],
      legSide                |-> [i \in 1 .. 1 |-> 0],
      legRatio               |-> [i \in 1 .. 4 |-> 0] ]

(* Combination Order Book Leg at zero, then each field in turn at the values it is checked at *)
CheckedCombinationOrderBookLeg ==
    { ZeroCombinationOrderBookLeg }
        \cup { [ZeroCombinationOrderBookLeg EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLeg EXCEPT !.combinationOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLeg EXCEPT !.legOrderBookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookLeg EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroCombinationOrderBookLeg EXCEPT !.legRatio = one] : one \in Sample(4) }

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
(* Short Sell Status: 9 bytes                                              *)
(***************************************************************************)

ShortSellStatus ==
    [ nanoseconds          : Sample(4),
      orderBookId          : Sample(4),
      shortSaleRestriction : Sample(1) ]

EncodeShortSellStatus(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.shortSaleRestriction

DecodeShortSellStatus(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET shortSaleRestriction == ReadBytes(orderBookId.rest, 1) IN IF ~shortSaleRestriction.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         orderBookId          |-> orderBookId.value,
         shortSaleRestriction |-> shortSaleRestriction.value ], shortSaleRestriction.rest)

ZeroShortSellStatus ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      shortSaleRestriction |-> [i \in 1 .. 1 |-> 0] ]

(* Short Sell Status at zero, then each field in turn at the values it is checked at *)
CheckedShortSellStatus ==
    { ZeroShortSellStatus }
        \cup { [ZeroShortSellStatus EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroShortSellStatus EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroShortSellStatus EXCEPT !.shortSaleRestriction = one] : one \in Sample(1) }

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
(* Add Order No Mpid Attribution: 44 bytes                                 *)
(***************************************************************************)

AddOrderNoMpidAttribution ==
    [ nanoseconds           : Sample(4),
      orderId               : Sample(8),
      orderBookId           : Sample(4),
      side                  : Sample(1),
      rankingSequenceNumber : Sample(4),
      quantity              : Sample(8),
      price                 : Sample(4),
      orderAttributes       : Sample(2),
      lotType               : Sample(1),
      rankingTime           : Sample(8) ]

EncodeAddOrderNoMpidAttribution(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.rankingSequenceNumber
        \o message.quantity
        \o message.price
        \o message.orderAttributes
        \o message.lotType
        \o message.rankingTime

DecodeAddOrderNoMpidAttribution(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET rankingSequenceNumber == ReadBytes(side.rest, 4) IN IF ~rankingSequenceNumber.ok THEN Fail ELSE
    LET quantity == ReadBytes(rankingSequenceNumber.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET orderAttributes == ReadBytes(price.rest, 2) IN IF ~orderAttributes.ok THEN Fail ELSE
    LET lotType == ReadBytes(orderAttributes.rest, 1) IN IF ~lotType.ok THEN Fail ELSE
    LET rankingTime == ReadBytes(lotType.rest, 8) IN IF ~rankingTime.ok THEN Fail ELSE
    Ok([ nanoseconds           |-> nanoseconds.value,
         orderId               |-> orderId.value,
         orderBookId           |-> orderBookId.value,
         side                  |-> side.value,
         rankingSequenceNumber |-> rankingSequenceNumber.value,
         quantity              |-> quantity.value,
         price                 |-> price.value,
         orderAttributes       |-> orderAttributes.value,
         lotType               |-> lotType.value,
         rankingTime           |-> rankingTime.value ], rankingTime.rest)

ZeroAddOrderNoMpidAttribution ==
    [ nanoseconds           |-> [i \in 1 .. 4 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      orderBookId           |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      rankingSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      quantity              |-> [i \in 1 .. 8 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      orderAttributes       |-> [i \in 1 .. 2 |-> 0],
      lotType               |-> [i \in 1 .. 1 |-> 0],
      rankingTime           |-> [i \in 1 .. 8 |-> 0] ]

(* Add Order No Mpid Attribution at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderNoMpidAttribution ==
    { ZeroAddOrderNoMpidAttribution }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.rankingSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.orderAttributes = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.rankingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Add Order With Mpid Attribution: 43 bytes                               *)
(***************************************************************************)

AddOrderWithMpidAttribution ==
    [ nanoseconds     : Sample(4),
      orderId         : Sample(8),
      orderBookId     : Sample(4),
      side            : Sample(1),
      reserved4       : Sample(4),
      quantity        : Sample(8),
      price           : Sample(4),
      orderAttributes : Sample(2),
      lotType         : Sample(1),
      participantId   : Sample(7) ]

EncodeAddOrderWithMpidAttribution(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.reserved4
        \o message.quantity
        \o message.price
        \o message.orderAttributes
        \o message.lotType
        \o message.participantId

DecodeAddOrderWithMpidAttribution(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(side.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET quantity == ReadBytes(reserved4.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET orderAttributes == ReadBytes(price.rest, 2) IN IF ~orderAttributes.ok THEN Fail ELSE
    LET lotType == ReadBytes(orderAttributes.rest, 1) IN IF ~lotType.ok THEN Fail ELSE
    LET participantId == ReadBytes(lotType.rest, 7) IN IF ~participantId.ok THEN Fail ELSE
    Ok([ nanoseconds     |-> nanoseconds.value,
         orderId         |-> orderId.value,
         orderBookId     |-> orderBookId.value,
         side            |-> side.value,
         reserved4       |-> reserved4.value,
         quantity        |-> quantity.value,
         price           |-> price.value,
         orderAttributes |-> orderAttributes.value,
         lotType         |-> lotType.value,
         participantId   |-> participantId.value ], participantId.rest)

ZeroAddOrderWithMpidAttribution ==
    [ nanoseconds     |-> [i \in 1 .. 4 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      orderBookId     |-> [i \in 1 .. 4 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      reserved4       |-> [i \in 1 .. 4 |-> 0],
      quantity        |-> [i \in 1 .. 8 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      orderAttributes |-> [i \in 1 .. 2 |-> 0],
      lotType         |-> [i \in 1 .. 1 |-> 0],
      participantId   |-> [i \in 1 .. 7 |-> 0] ]

(* Add Order With Mpid Attribution at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderWithMpidAttribution ==
    { ZeroAddOrderWithMpidAttribution }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.orderAttributes = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.participantId = one] : one \in Sample(7) }

(***************************************************************************)
(* End Of Snapshot Message: 20 bytes                                       *)
(***************************************************************************)

EndOfSnapshotMessage ==
    [ sequenceNumber : Sample(20) ]

EncodeEndOfSnapshotMessage(message) ==
    message.sequenceNumber

DecodeEndOfSnapshotMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 20) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroEndOfSnapshotMessage ==
    [ sequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* End Of Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSnapshotMessage ==
    { ZeroEndOfSnapshotMessage }
        \cup { [ZeroEndOfSnapshotMessage EXCEPT !.sequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
OrderBookDirectoryCode == 82  \* "R"
CombinationOrderBookLegCode == 77  \* "M"
TickSizeTableEntryCode == 76  \* "L"
ShortSellStatusCode == 86  \* "V"
OrderBookStateMessageCode == 79  \* "O"
AddOrderNoMpidAttributionCode == 65  \* "A"
AddOrderWithMpidAttributionCode == 70  \* "F"
EndOfSnapshotMessageCode == 71  \* "G"

SequencedMessage ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {OrderBookDirectoryCode}, body : OrderBookDirectory ]
        \cup [ tag : {CombinationOrderBookLegCode}, body : CombinationOrderBookLeg ]
        \cup [ tag : {TickSizeTableEntryCode}, body : TickSizeTableEntry ]
        \cup [ tag : {ShortSellStatusCode}, body : ShortSellStatus ]
        \cup [ tag : {OrderBookStateMessageCode}, body : OrderBookStateMessage ]
        \cup [ tag : {AddOrderNoMpidAttributionCode}, body : AddOrderNoMpidAttribution ]
        \cup [ tag : {AddOrderWithMpidAttributionCode}, body : AddOrderWithMpidAttribution ]
        \cup [ tag : {EndOfSnapshotMessageCode}, body : EndOfSnapshotMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = OrderBookDirectoryCode -> EncodeOrderBookDirectory(message.body)
      [] message.tag = CombinationOrderBookLegCode -> EncodeCombinationOrderBookLeg(message.body)
      [] message.tag = TickSizeTableEntryCode -> EncodeTickSizeTableEntry(message.body)
      [] message.tag = ShortSellStatusCode -> EncodeShortSellStatus(message.body)
      [] message.tag = OrderBookStateMessageCode -> EncodeOrderBookStateMessage(message.body)
      [] message.tag = AddOrderNoMpidAttributionCode -> EncodeAddOrderNoMpidAttribution(message.body)
      [] message.tag = AddOrderWithMpidAttributionCode -> EncodeAddOrderWithMpidAttribution(message.body)
      [] message.tag = EndOfSnapshotMessageCode -> EncodeEndOfSnapshotMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = OrderBookDirectoryCode -> DecodeOrderBookDirectory(bytes)
              [] tag = CombinationOrderBookLegCode -> DecodeCombinationOrderBookLeg(bytes)
              [] tag = TickSizeTableEntryCode -> DecodeTickSizeTableEntry(bytes)
              [] tag = ShortSellStatusCode -> DecodeShortSellStatus(bytes)
              [] tag = OrderBookStateMessageCode -> DecodeOrderBookStateMessage(bytes)
              [] tag = AddOrderNoMpidAttributionCode -> DecodeAddOrderNoMpidAttribution(bytes)
              [] tag = AddOrderWithMpidAttributionCode -> DecodeAddOrderWithMpidAttribution(bytes)
              [] tag = EndOfSnapshotMessageCode -> DecodeEndOfSnapshotMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> OrderBookDirectoryCode, body |-> one] : one \in CheckedOrderBookDirectory }
        \cup { [tag |-> CombinationOrderBookLegCode, body |-> one] : one \in CheckedCombinationOrderBookLeg }
        \cup { [tag |-> TickSizeTableEntryCode, body |-> one] : one \in CheckedTickSizeTableEntry }
        \cup { [tag |-> ShortSellStatusCode, body |-> one] : one \in CheckedShortSellStatus }
        \cup { [tag |-> OrderBookStateMessageCode, body |-> one] : one \in CheckedOrderBookStateMessage }
        \cup { [tag |-> AddOrderNoMpidAttributionCode, body |-> one] : one \in CheckedAddOrderNoMpidAttribution }
        \cup { [tag |-> AddOrderWithMpidAttributionCode, body |-> one] : one \in CheckedAddOrderWithMpidAttribution }
        \cup { [tag |-> EndOfSnapshotMessageCode, body |-> one] : one \in CheckedEndOfSnapshotMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"
ServerHeartbeatCode == 72  \* "H"
EndOfSessionCode == 90  \* "Z"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Server Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ServerSoupBinTcpPacket ==
    [ serverPayload : ServerPayload ]

EncodeServerSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerSoupBinTcpPacket(message) ==
    LET body == EncodeServerSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeServerSoupBinTcpPacketBody(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerSoupBinTcpPacket ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerSoupBinTcpPacket ==
    { ZeroServerSoupBinTcpPacket }
        \cup { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneServerSoupBinTcpPacket ==
    { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginRejectedPacketCode, body |-> ZeroLoginRejectedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleLists(OneServerSoupBinTcpPacket) ]

EncodeServerPacket(message) ==
    EncodeServerSoupBinTcpPacketList(message.serverSoupBinTcpPacket)

DecodeServerPacket(bytes) ==
    LET serverSoupBinTcpPacket == ReadServerSoupBinTcpPacketAll(bytes) IN IF ~serverSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ serverSoupBinTcpPacket |-> serverSoupBinTcpPacket.value ], serverSoupBinTcpPacket.rest)

ZeroServerPacket ==
    [ serverSoupBinTcpPacket |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleLists(OneServerSoupBinTcpPacket) }

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

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

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

(* Every Combination Order Book Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinationOrderBookLeg ==
    \A message \in CheckedCombinationOrderBookLeg :
        LET read == DecodeCombinationOrderBookLeg(EncodeCombinationOrderBookLeg(message))
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

(* Every Short Sell Status decodes back to what was encoded, and leaves nothing over *)
RoundTripShortSellStatus ==
    \A message \in CheckedShortSellStatus :
        LET read == DecodeShortSellStatus(EncodeShortSellStatus(message))
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

(* Every Add Order No Mpid Attribution decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderNoMpidAttribution ==
    \A message \in CheckedAddOrderNoMpidAttribution :
        LET read == DecodeAddOrderNoMpidAttribution(EncodeAddOrderNoMpidAttribution(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order With Mpid Attribution decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderWithMpidAttribution ==
    \A message \in CheckedAddOrderWithMpidAttribution :
        LET read == DecodeAddOrderWithMpidAttribution(EncodeAddOrderWithMpidAttribution(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSnapshotMessage ==
    \A message \in CheckedEndOfSnapshotMessage :
        LET read == DecodeEndOfSnapshotMessage(EncodeEndOfSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET read == DecodeServerSoupBinTcpPacket(EncodeServerSoupBinTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET bytes == EncodeServerSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
