--------------------- MODULE AsxSecurities_Trade_v3_1 ----------------------
(***************************************************************************)
(* Australian Securities Exchange Asx Trade v3.1                           *)
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
(* Note: Exchange Order Type is a bit field set, checked as its 2 bytes    *)
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
(* Order Book Directory Message: 112 bytes                                 *)
(***************************************************************************)

OrderBookDirectoryMessage ==
    [ nanoseconds                    : Sample(4),
      orderBookId                    : Sample(4),
      symbol                         : Sample(32),
      longName                       : Sample(32),
      isin                           : Sample(12),
      financialProduct               : Sample(1),
      tradingCurrency                : Sample(3),
      numberOfDecimalsInPrice        : Sample(2),
      numberOfDecimalsInNominalValue : Sample(2),
      oddLotSize                     : Sample(4),
      roundLotSize                   : Sample(4),
      blockLotSize                   : Sample(4),
      nominalValue                   : Sample(8) ]

EncodeOrderBookDirectoryMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.symbol
        \o message.longName
        \o message.isin
        \o message.financialProduct
        \o message.tradingCurrency
        \o message.numberOfDecimalsInPrice
        \o message.numberOfDecimalsInNominalValue
        \o message.oddLotSize
        \o message.roundLotSize
        \o message.blockLotSize
        \o message.nominalValue

DecodeOrderBookDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderBookId.rest, 32) IN IF ~symbol.ok THEN Fail ELSE
    LET longName == ReadBytes(symbol.rest, 32) IN IF ~longName.ok THEN Fail ELSE
    LET isin == ReadBytes(longName.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET financialProduct == ReadBytes(isin.rest, 1) IN IF ~financialProduct.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(financialProduct.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET numberOfDecimalsInPrice == ReadBytes(tradingCurrency.rest, 2) IN IF ~numberOfDecimalsInPrice.ok THEN Fail ELSE
    LET numberOfDecimalsInNominalValue == ReadBytes(numberOfDecimalsInPrice.rest, 2) IN IF ~numberOfDecimalsInNominalValue.ok THEN Fail ELSE
    LET oddLotSize == ReadBytes(numberOfDecimalsInNominalValue.rest, 4) IN IF ~oddLotSize.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(oddLotSize.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET blockLotSize == ReadBytes(roundLotSize.rest, 4) IN IF ~blockLotSize.ok THEN Fail ELSE
    LET nominalValue == ReadBytes(blockLotSize.rest, 8) IN IF ~nominalValue.ok THEN Fail ELSE
    Ok([ nanoseconds                    |-> nanoseconds.value,
         orderBookId                    |-> orderBookId.value,
         symbol                         |-> symbol.value,
         longName                       |-> longName.value,
         isin                           |-> isin.value,
         financialProduct               |-> financialProduct.value,
         tradingCurrency                |-> tradingCurrency.value,
         numberOfDecimalsInPrice        |-> numberOfDecimalsInPrice.value,
         numberOfDecimalsInNominalValue |-> numberOfDecimalsInNominalValue.value,
         oddLotSize                     |-> oddLotSize.value,
         roundLotSize                   |-> roundLotSize.value,
         blockLotSize                   |-> blockLotSize.value,
         nominalValue                   |-> nominalValue.value ], nominalValue.rest)

ZeroOrderBookDirectoryMessage ==
    [ nanoseconds                    |-> [i \in 1 .. 4 |-> 0],
      orderBookId                    |-> [i \in 1 .. 4 |-> 0],
      symbol                         |-> [i \in 1 .. 32 |-> 0],
      longName                       |-> [i \in 1 .. 32 |-> 0],
      isin                           |-> [i \in 1 .. 12 |-> 0],
      financialProduct               |-> [i \in 1 .. 1 |-> 0],
      tradingCurrency                |-> [i \in 1 .. 3 |-> 0],
      numberOfDecimalsInPrice        |-> [i \in 1 .. 2 |-> 0],
      numberOfDecimalsInNominalValue |-> [i \in 1 .. 2 |-> 0],
      oddLotSize                     |-> [i \in 1 .. 4 |-> 0],
      roundLotSize                   |-> [i \in 1 .. 4 |-> 0],
      blockLotSize                   |-> [i \in 1 .. 4 |-> 0],
      nominalValue                   |-> [i \in 1 .. 8 |-> 0] ]

(* Order Book Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookDirectoryMessage ==
    { ZeroOrderBookDirectoryMessage }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(32) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.longName = one] : one \in Sample(32) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.financialProduct = one] : one \in Sample(1) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.numberOfDecimalsInPrice = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.numberOfDecimalsInNominalValue = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.oddLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.blockLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectoryMessage EXCEPT !.nominalValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Leg 1: 37 bytes                                                         *)
(***************************************************************************)

Leg1 ==
    [ legSymbol : Sample(32),
      legSide   : Sample(1),
      legRatio  : Sample(4) ]

EncodeLeg1(message) ==
    message.legSymbol
        \o message.legSide
        \o message.legRatio

DecodeLeg1(bytes) ==
    LET legSymbol == ReadBytes(bytes, 32) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSymbol.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSide.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ legSymbol |-> legSymbol.value,
         legSide   |-> legSide.value,
         legRatio  |-> legRatio.value ], legRatio.rest)

ZeroLeg1 ==
    [ legSymbol |-> [i \in 1 .. 32 |-> 0],
      legSide   |-> [i \in 1 .. 1 |-> 0],
      legRatio  |-> [i \in 1 .. 4 |-> 0] ]

(* Leg 1 at zero, then each field in turn at the values it is checked at *)
CheckedLeg1 ==
    { ZeroLeg1 }
        \cup { [ZeroLeg1 EXCEPT !.legSymbol = one] : one \in Sample(32) }
        \cup { [ZeroLeg1 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLeg1 EXCEPT !.legRatio = one] : one \in Sample(4) }

(***************************************************************************)
(* Leg 2: 37 bytes                                                         *)
(***************************************************************************)

Leg2 ==
    [ legSymbol : Sample(32),
      legSide   : Sample(1),
      legRatio  : Sample(4) ]

EncodeLeg2(message) ==
    message.legSymbol
        \o message.legSide
        \o message.legRatio

DecodeLeg2(bytes) ==
    LET legSymbol == ReadBytes(bytes, 32) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSymbol.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSide.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ legSymbol |-> legSymbol.value,
         legSide   |-> legSide.value,
         legRatio  |-> legRatio.value ], legRatio.rest)

ZeroLeg2 ==
    [ legSymbol |-> [i \in 1 .. 32 |-> 0],
      legSide   |-> [i \in 1 .. 1 |-> 0],
      legRatio  |-> [i \in 1 .. 4 |-> 0] ]

(* Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedLeg2 ==
    { ZeroLeg2 }
        \cup { [ZeroLeg2 EXCEPT !.legSymbol = one] : one \in Sample(32) }
        \cup { [ZeroLeg2 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLeg2 EXCEPT !.legRatio = one] : one \in Sample(4) }

(***************************************************************************)
(* Leg 3: 37 bytes                                                         *)
(***************************************************************************)

Leg3 ==
    [ legSymbol : Sample(32),
      legSide   : Sample(1),
      legRatio  : Sample(4) ]

EncodeLeg3(message) ==
    message.legSymbol
        \o message.legSide
        \o message.legRatio

DecodeLeg3(bytes) ==
    LET legSymbol == ReadBytes(bytes, 32) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSymbol.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSide.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ legSymbol |-> legSymbol.value,
         legSide   |-> legSide.value,
         legRatio  |-> legRatio.value ], legRatio.rest)

ZeroLeg3 ==
    [ legSymbol |-> [i \in 1 .. 32 |-> 0],
      legSide   |-> [i \in 1 .. 1 |-> 0],
      legRatio  |-> [i \in 1 .. 4 |-> 0] ]

(* Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedLeg3 ==
    { ZeroLeg3 }
        \cup { [ZeroLeg3 EXCEPT !.legSymbol = one] : one \in Sample(32) }
        \cup { [ZeroLeg3 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLeg3 EXCEPT !.legRatio = one] : one \in Sample(4) }

(***************************************************************************)
(* Leg 4: 37 bytes                                                         *)
(***************************************************************************)

Leg4 ==
    [ legSymbol : Sample(32),
      legSide   : Sample(1),
      legRatio  : Sample(4) ]

EncodeLeg4(message) ==
    message.legSymbol
        \o message.legSide
        \o message.legRatio

DecodeLeg4(bytes) ==
    LET legSymbol == ReadBytes(bytes, 32) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legSide == ReadBytes(legSymbol.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSide.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    Ok([ legSymbol |-> legSymbol.value,
         legSide   |-> legSide.value,
         legRatio  |-> legRatio.value ], legRatio.rest)

ZeroLeg4 ==
    [ legSymbol |-> [i \in 1 .. 32 |-> 0],
      legSide   |-> [i \in 1 .. 1 |-> 0],
      legRatio  |-> [i \in 1 .. 4 |-> 0] ]

(* Leg 4 at zero, then each field in turn at the values it is checked at *)
CheckedLeg4 ==
    { ZeroLeg4 }
        \cup { [ZeroLeg4 EXCEPT !.legSymbol = one] : one \in Sample(32) }
        \cup { [ZeroLeg4 EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroLeg4 EXCEPT !.legRatio = one] : one \in Sample(4) }

(***************************************************************************)
(* Combination Order Book Directory Message: 260 bytes                     *)
(***************************************************************************)

CombinationOrderBookDirectoryMessage ==
    [ nanoseconds                    : Sample(4),
      orderBookId                    : Sample(4),
      symbol                         : Sample(32),
      longName                       : Sample(32),
      isin                           : Sample(12),
      financialProduct               : Sample(1),
      tradingCurrency                : Sample(3),
      numberOfDecimalsInPrice        : Sample(2),
      numberOfDecimalsInNominalValue : Sample(2),
      oddLotSize                     : Sample(4),
      roundLotSize                   : Sample(4),
      blockLotSize                   : Sample(4),
      nominalValue                   : Sample(8),
      leg1                           : Leg1,
      leg2                           : Leg2,
      leg3                           : Leg3,
      leg4                           : Leg4 ]

EncodeCombinationOrderBookDirectoryMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.symbol
        \o message.longName
        \o message.isin
        \o message.financialProduct
        \o message.tradingCurrency
        \o message.numberOfDecimalsInPrice
        \o message.numberOfDecimalsInNominalValue
        \o message.oddLotSize
        \o message.roundLotSize
        \o message.blockLotSize
        \o message.nominalValue
        \o EncodeLeg1(message.leg1)
        \o EncodeLeg2(message.leg2)
        \o EncodeLeg3(message.leg3)
        \o EncodeLeg4(message.leg4)

DecodeCombinationOrderBookDirectoryMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET symbol == ReadBytes(orderBookId.rest, 32) IN IF ~symbol.ok THEN Fail ELSE
    LET longName == ReadBytes(symbol.rest, 32) IN IF ~longName.ok THEN Fail ELSE
    LET isin == ReadBytes(longName.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET financialProduct == ReadBytes(isin.rest, 1) IN IF ~financialProduct.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(financialProduct.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET numberOfDecimalsInPrice == ReadBytes(tradingCurrency.rest, 2) IN IF ~numberOfDecimalsInPrice.ok THEN Fail ELSE
    LET numberOfDecimalsInNominalValue == ReadBytes(numberOfDecimalsInPrice.rest, 2) IN IF ~numberOfDecimalsInNominalValue.ok THEN Fail ELSE
    LET oddLotSize == ReadBytes(numberOfDecimalsInNominalValue.rest, 4) IN IF ~oddLotSize.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(oddLotSize.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET blockLotSize == ReadBytes(roundLotSize.rest, 4) IN IF ~blockLotSize.ok THEN Fail ELSE
    LET nominalValue == ReadBytes(blockLotSize.rest, 8) IN IF ~nominalValue.ok THEN Fail ELSE
    LET leg1 == DecodeLeg1(nominalValue.rest) IN IF ~leg1.ok THEN Fail ELSE
    LET leg2 == DecodeLeg2(leg1.rest) IN IF ~leg2.ok THEN Fail ELSE
    LET leg3 == DecodeLeg3(leg2.rest) IN IF ~leg3.ok THEN Fail ELSE
    LET leg4 == DecodeLeg4(leg3.rest) IN IF ~leg4.ok THEN Fail ELSE
    Ok([ nanoseconds                    |-> nanoseconds.value,
         orderBookId                    |-> orderBookId.value,
         symbol                         |-> symbol.value,
         longName                       |-> longName.value,
         isin                           |-> isin.value,
         financialProduct               |-> financialProduct.value,
         tradingCurrency                |-> tradingCurrency.value,
         numberOfDecimalsInPrice        |-> numberOfDecimalsInPrice.value,
         numberOfDecimalsInNominalValue |-> numberOfDecimalsInNominalValue.value,
         oddLotSize                     |-> oddLotSize.value,
         roundLotSize                   |-> roundLotSize.value,
         blockLotSize                   |-> blockLotSize.value,
         nominalValue                   |-> nominalValue.value,
         leg1                           |-> leg1.value,
         leg2                           |-> leg2.value,
         leg3                           |-> leg3.value,
         leg4                           |-> leg4.value ], leg4.rest)

ZeroCombinationOrderBookDirectoryMessage ==
    [ nanoseconds                    |-> [i \in 1 .. 4 |-> 0],
      orderBookId                    |-> [i \in 1 .. 4 |-> 0],
      symbol                         |-> [i \in 1 .. 32 |-> 0],
      longName                       |-> [i \in 1 .. 32 |-> 0],
      isin                           |-> [i \in 1 .. 12 |-> 0],
      financialProduct               |-> [i \in 1 .. 1 |-> 0],
      tradingCurrency                |-> [i \in 1 .. 3 |-> 0],
      numberOfDecimalsInPrice        |-> [i \in 1 .. 2 |-> 0],
      numberOfDecimalsInNominalValue |-> [i \in 1 .. 2 |-> 0],
      oddLotSize                     |-> [i \in 1 .. 4 |-> 0],
      roundLotSize                   |-> [i \in 1 .. 4 |-> 0],
      blockLotSize                   |-> [i \in 1 .. 4 |-> 0],
      nominalValue                   |-> [i \in 1 .. 8 |-> 0],
      leg1                           |-> ZeroLeg1,
      leg2                           |-> ZeroLeg2,
      leg3                           |-> ZeroLeg3,
      leg4                           |-> ZeroLeg4 ]

(* Combination Order Book Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedCombinationOrderBookDirectoryMessage ==
    { ZeroCombinationOrderBookDirectoryMessage }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(32) }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.longName = one] : one \in Sample(32) }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.financialProduct = one] : one \in Sample(1) }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.numberOfDecimalsInPrice = one] : one \in Sample(2) }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.numberOfDecimalsInNominalValue = one] : one \in Sample(2) }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.oddLotSize = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.blockLotSize = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.nominalValue = one] : one \in Sample(8) }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.leg1 = one] : one \in CheckedLeg1 }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.leg2 = one] : one \in CheckedLeg2 }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.leg3 = one] : one \in CheckedLeg3 }
        \cup { [ZeroCombinationOrderBookDirectoryMessage EXCEPT !.leg4 = one] : one \in CheckedLeg4 }

(***************************************************************************)
(* Tick Size Table Entry Message: 24 bytes                                 *)
(***************************************************************************)

TickSizeTableEntryMessage ==
    [ nanoseconds : Sample(4),
      orderBookId : Sample(4),
      tickSize    : Sample(8),
      priceFrom   : Sample(4),
      priceTo     : Sample(4) ]

EncodeTickSizeTableEntryMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.tickSize
        \o message.priceFrom
        \o message.priceTo

DecodeTickSizeTableEntryMessage(bytes) ==
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

ZeroTickSizeTableEntryMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId |-> [i \in 1 .. 4 |-> 0],
      tickSize    |-> [i \in 1 .. 8 |-> 0],
      priceFrom   |-> [i \in 1 .. 4 |-> 0],
      priceTo     |-> [i \in 1 .. 4 |-> 0] ]

(* Tick Size Table Entry Message at zero, then each field in turn at the values it is checked at *)
CheckedTickSizeTableEntryMessage ==
    { ZeroTickSizeTableEntryMessage }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.tickSize = one] : one \in Sample(8) }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.priceFrom = one] : one \in Sample(4) }
        \cup { [ZeroTickSizeTableEntryMessage EXCEPT !.priceTo = one] : one \in Sample(4) }

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
(* Add Order No Participant Id Message: 36 bytes                           *)
(***************************************************************************)

AddOrderNoParticipantIdMessage ==
    [ nanoseconds       : Sample(4),
      orderId           : Sample(8),
      orderBookId       : Sample(4),
      side              : Sample(1),
      orderBookPosition : Sample(4),
      quantity          : Sample(8),
      price             : Sample(4),
      exchangeOrderType : Sample(2),
      lotType           : Sample(1) ]

EncodeAddOrderNoParticipantIdMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.orderBookPosition
        \o message.quantity
        \o message.price
        \o message.exchangeOrderType
        \o message.lotType

DecodeAddOrderNoParticipantIdMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderBookPosition == ReadBytes(side.rest, 4) IN IF ~orderBookPosition.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBookPosition.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET exchangeOrderType == ReadBytes(price.rest, 2) IN IF ~exchangeOrderType.ok THEN Fail ELSE
    LET lotType == ReadBytes(exchangeOrderType.rest, 1) IN IF ~lotType.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         orderId           |-> orderId.value,
         orderBookId       |-> orderBookId.value,
         side              |-> side.value,
         orderBookPosition |-> orderBookPosition.value,
         quantity          |-> quantity.value,
         price             |-> price.value,
         exchangeOrderType |-> exchangeOrderType.value,
         lotType           |-> lotType.value ], lotType.rest)

ZeroAddOrderNoParticipantIdMessage ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      orderBookId       |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      orderBookPosition |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      exchangeOrderType |-> [i \in 1 .. 2 |-> 0],
      lotType           |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order No Participant Id Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderNoParticipantIdMessage ==
    { ZeroAddOrderNoParticipantIdMessage }
        \cup { [ZeroAddOrderNoParticipantIdMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoParticipantIdMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderNoParticipantIdMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoParticipantIdMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderNoParticipantIdMessage EXCEPT !.orderBookPosition = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoParticipantIdMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderNoParticipantIdMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoParticipantIdMessage EXCEPT !.exchangeOrderType = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderNoParticipantIdMessage EXCEPT !.lotType = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Participant Id Message: 43 bytes                              *)
(***************************************************************************)

AddOrderParticipantIdMessage ==
    [ nanoseconds       : Sample(4),
      orderId           : Sample(8),
      orderBookId       : Sample(4),
      side              : Sample(1),
      orderBookPosition : Sample(4),
      quantity          : Sample(8),
      price             : Sample(4),
      exchangeOrderType : Sample(2),
      lotType           : Sample(1),
      participantId     : Sample(7) ]

EncodeAddOrderParticipantIdMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.orderBookPosition
        \o message.quantity
        \o message.price
        \o message.exchangeOrderType
        \o message.lotType
        \o message.participantId

DecodeAddOrderParticipantIdMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderBookPosition == ReadBytes(side.rest, 4) IN IF ~orderBookPosition.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBookPosition.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET exchangeOrderType == ReadBytes(price.rest, 2) IN IF ~exchangeOrderType.ok THEN Fail ELSE
    LET lotType == ReadBytes(exchangeOrderType.rest, 1) IN IF ~lotType.ok THEN Fail ELSE
    LET participantId == ReadBytes(lotType.rest, 7) IN IF ~participantId.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         orderId           |-> orderId.value,
         orderBookId       |-> orderBookId.value,
         side              |-> side.value,
         orderBookPosition |-> orderBookPosition.value,
         quantity          |-> quantity.value,
         price             |-> price.value,
         exchangeOrderType |-> exchangeOrderType.value,
         lotType           |-> lotType.value,
         participantId     |-> participantId.value ], participantId.rest)

ZeroAddOrderParticipantIdMessage ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      orderBookId       |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      orderBookPosition |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      exchangeOrderType |-> [i \in 1 .. 2 |-> 0],
      lotType           |-> [i \in 1 .. 1 |-> 0],
      participantId     |-> [i \in 1 .. 7 |-> 0] ]

(* Add Order Participant Id Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderParticipantIdMessage ==
    { ZeroAddOrderParticipantIdMessage }
        \cup { [ZeroAddOrderParticipantIdMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderParticipantIdMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderParticipantIdMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderParticipantIdMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderParticipantIdMessage EXCEPT !.orderBookPosition = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderParticipantIdMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderParticipantIdMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderParticipantIdMessage EXCEPT !.exchangeOrderType = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderParticipantIdMessage EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderParticipantIdMessage EXCEPT !.participantId = one] : one \in Sample(7) }

(***************************************************************************)
(* Order Executed Message: 51 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ nanoseconds               : Sample(4),
      orderId                   : Sample(8),
      orderBookId               : Sample(4),
      side                      : Sample(1),
      executedQuantity          : Sample(8),
      matchId                   : Sample(12),
      participantIdOwner        : Sample(7),
      participantIdCounterparty : Sample(7) ]

EncodeOrderExecutedMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.executedQuantity
        \o message.matchId
        \o message.participantIdOwner
        \o message.participantIdCounterparty

DecodeOrderExecutedMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(side.rest, 8) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchId == ReadBytes(executedQuantity.rest, 12) IN IF ~matchId.ok THEN Fail ELSE
    LET participantIdOwner == ReadBytes(matchId.rest, 7) IN IF ~participantIdOwner.ok THEN Fail ELSE
    LET participantIdCounterparty == ReadBytes(participantIdOwner.rest, 7) IN IF ~participantIdCounterparty.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         orderId                   |-> orderId.value,
         orderBookId               |-> orderBookId.value,
         side                      |-> side.value,
         executedQuantity          |-> executedQuantity.value,
         matchId                   |-> matchId.value,
         participantIdOwner        |-> participantIdOwner.value,
         participantIdCounterparty |-> participantIdCounterparty.value ], participantIdCounterparty.rest)

ZeroOrderExecutedMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      orderBookId               |-> [i \in 1 .. 4 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      executedQuantity          |-> [i \in 1 .. 8 |-> 0],
      matchId                   |-> [i \in 1 .. 12 |-> 0],
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
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchId = one] : one \in Sample(12) }
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
      matchId                   : Sample(12),
      participantIdOwner        : Sample(7),
      participantIdCounterparty : Sample(7),
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
        \o message.participantIdOwner
        \o message.participantIdCounterparty
        \o message.tradePrice
        \o message.occurredAtCross
        \o message.printable

DecodeOrderExecutedWithPriceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(side.rest, 8) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET matchId == ReadBytes(executedQuantity.rest, 12) IN IF ~matchId.ok THEN Fail ELSE
    LET participantIdOwner == ReadBytes(matchId.rest, 7) IN IF ~participantIdOwner.ok THEN Fail ELSE
    LET participantIdCounterparty == ReadBytes(participantIdOwner.rest, 7) IN IF ~participantIdCounterparty.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(participantIdCounterparty.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET occurredAtCross == ReadBytes(tradePrice.rest, 1) IN IF ~occurredAtCross.ok THEN Fail ELSE
    LET printable == ReadBytes(occurredAtCross.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         orderId                   |-> orderId.value,
         orderBookId               |-> orderBookId.value,
         side                      |-> side.value,
         executedQuantity          |-> executedQuantity.value,
         matchId                   |-> matchId.value,
         participantIdOwner        |-> participantIdOwner.value,
         participantIdCounterparty |-> participantIdCounterparty.value,
         tradePrice                |-> tradePrice.value,
         occurredAtCross           |-> occurredAtCross.value,
         printable                 |-> printable.value ], printable.rest)

ZeroOrderExecutedWithPriceMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      orderId                   |-> [i \in 1 .. 8 |-> 0],
      orderBookId               |-> [i \in 1 .. 4 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      executedQuantity          |-> [i \in 1 .. 8 |-> 0],
      matchId                   |-> [i \in 1 .. 12 |-> 0],
      participantIdOwner        |-> [i \in 1 .. 7 |-> 0],
      participantIdCounterparty |-> [i \in 1 .. 7 |-> 0],
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
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.matchId = one] : one \in Sample(12) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.participantIdOwner = one] : one \in Sample(7) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.participantIdCounterparty = one] : one \in Sample(7) }
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
      newOrderBookPosition : Sample(4),
      quantity             : Sample(8),
      price                : Sample(4),
      exchangeOrderType    : Sample(2) ]

EncodeOrderReplaceMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.newOrderBookPosition
        \o message.quantity
        \o message.price
        \o message.exchangeOrderType

DecodeOrderReplaceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET newOrderBookPosition == ReadBytes(side.rest, 4) IN IF ~newOrderBookPosition.ok THEN Fail ELSE
    LET quantity == ReadBytes(newOrderBookPosition.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET exchangeOrderType == ReadBytes(price.rest, 2) IN IF ~exchangeOrderType.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         orderId              |-> orderId.value,
         orderBookId          |-> orderBookId.value,
         side                 |-> side.value,
         newOrderBookPosition |-> newOrderBookPosition.value,
         quantity             |-> quantity.value,
         price                |-> price.value,
         exchangeOrderType    |-> exchangeOrderType.value ], exchangeOrderType.rest)

ZeroOrderReplaceMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      newOrderBookPosition |-> [i \in 1 .. 4 |-> 0],
      quantity             |-> [i \in 1 .. 8 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      exchangeOrderType    |-> [i \in 1 .. 2 |-> 0] ]

(* Order Replace Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceMessage ==
    { ZeroOrderReplaceMessage }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.newOrderBookPosition = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.exchangeOrderType = one] : one \in Sample(2) }

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
      matchId                   : Sample(12),
      side                      : Sample(1),
      quantity                  : Sample(8),
      orderBookId               : Sample(4),
      tradePrice                : Sample(4),
      participantIdOwner        : Sample(7),
      participantIdCounterparty : Sample(7),
      printable                 : Sample(1),
      occurredAtCross           : Sample(1) ]

EncodeTradeMessage(message) ==
    message.nanoseconds
        \o message.matchId
        \o message.side
        \o message.quantity
        \o message.orderBookId
        \o message.tradePrice
        \o message.participantIdOwner
        \o message.participantIdCounterparty
        \o message.printable
        \o message.occurredAtCross

DecodeTradeMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET matchId == ReadBytes(nanoseconds.rest, 12) IN IF ~matchId.ok THEN Fail ELSE
    LET side == ReadBytes(matchId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(quantity.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(orderBookId.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET participantIdOwner == ReadBytes(tradePrice.rest, 7) IN IF ~participantIdOwner.ok THEN Fail ELSE
    LET participantIdCounterparty == ReadBytes(participantIdOwner.rest, 7) IN IF ~participantIdCounterparty.ok THEN Fail ELSE
    LET printable == ReadBytes(participantIdCounterparty.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET occurredAtCross == ReadBytes(printable.rest, 1) IN IF ~occurredAtCross.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         matchId                   |-> matchId.value,
         side                      |-> side.value,
         quantity                  |-> quantity.value,
         orderBookId               |-> orderBookId.value,
         tradePrice                |-> tradePrice.value,
         participantIdOwner        |-> participantIdOwner.value,
         participantIdCounterparty |-> participantIdCounterparty.value,
         printable                 |-> printable.value,
         occurredAtCross           |-> occurredAtCross.value ], occurredAtCross.rest)

ZeroTradeMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      matchId                   |-> [i \in 1 .. 12 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      quantity                  |-> [i \in 1 .. 8 |-> 0],
      orderBookId               |-> [i \in 1 .. 4 |-> 0],
      tradePrice                |-> [i \in 1 .. 4 |-> 0],
      participantIdOwner        |-> [i \in 1 .. 7 |-> 0],
      participantIdCounterparty |-> [i \in 1 .. 7 |-> 0],
      printable                 |-> [i \in 1 .. 1 |-> 0],
      occurredAtCross           |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.matchId = one] : one \in Sample(12) }
        \cup { [ZeroTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.participantIdOwner = one] : one \in Sample(7) }
        \cup { [ZeroTradeMessage EXCEPT !.participantIdCounterparty = one] : one \in Sample(7) }
        \cup { [ZeroTradeMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.occurredAtCross = one] : one \in Sample(1) }

(***************************************************************************)
(* Equilibrium Price Update Message: 52 bytes                              *)
(***************************************************************************)

EquilibriumPriceUpdateMessage ==
    [ nanoseconds      : Sample(4),
      orderBookId      : Sample(4),
      bidQuantity      : Sample(8),
      askQuantity      : Sample(8),
      equilibriumPrice : Sample(4),
      bestBidPrice     : Sample(4),
      bestAskPrice     : Sample(4),
      bestBidQuantity  : Sample(8),
      bestAskQuantity  : Sample(8) ]

EncodeEquilibriumPriceUpdateMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.bidQuantity
        \o message.askQuantity
        \o message.equilibriumPrice
        \o message.bestBidPrice
        \o message.bestAskPrice
        \o message.bestBidQuantity
        \o message.bestAskQuantity

DecodeEquilibriumPriceUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET bidQuantity == ReadBytes(orderBookId.rest, 8) IN IF ~bidQuantity.ok THEN Fail ELSE
    LET askQuantity == ReadBytes(bidQuantity.rest, 8) IN IF ~askQuantity.ok THEN Fail ELSE
    LET equilibriumPrice == ReadBytes(askQuantity.rest, 4) IN IF ~equilibriumPrice.ok THEN Fail ELSE
    LET bestBidPrice == ReadBytes(equilibriumPrice.rest, 4) IN IF ~bestBidPrice.ok THEN Fail ELSE
    LET bestAskPrice == ReadBytes(bestBidPrice.rest, 4) IN IF ~bestAskPrice.ok THEN Fail ELSE
    LET bestBidQuantity == ReadBytes(bestAskPrice.rest, 8) IN IF ~bestBidQuantity.ok THEN Fail ELSE
    LET bestAskQuantity == ReadBytes(bestBidQuantity.rest, 8) IN IF ~bestAskQuantity.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         orderBookId      |-> orderBookId.value,
         bidQuantity      |-> bidQuantity.value,
         askQuantity      |-> askQuantity.value,
         equilibriumPrice |-> equilibriumPrice.value,
         bestBidPrice     |-> bestBidPrice.value,
         bestAskPrice     |-> bestAskPrice.value,
         bestBidQuantity  |-> bestBidQuantity.value,
         bestAskQuantity  |-> bestAskQuantity.value ], bestAskQuantity.rest)

ZeroEquilibriumPriceUpdateMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      orderBookId      |-> [i \in 1 .. 4 |-> 0],
      bidQuantity      |-> [i \in 1 .. 8 |-> 0],
      askQuantity      |-> [i \in 1 .. 8 |-> 0],
      equilibriumPrice |-> [i \in 1 .. 4 |-> 0],
      bestBidPrice     |-> [i \in 1 .. 4 |-> 0],
      bestAskPrice     |-> [i \in 1 .. 4 |-> 0],
      bestBidQuantity  |-> [i \in 1 .. 8 |-> 0],
      bestAskQuantity  |-> [i \in 1 .. 8 |-> 0] ]

(* Equilibrium Price Update Message at zero, then each field in turn at the values it is checked at *)
CheckedEquilibriumPriceUpdateMessage ==
    { ZeroEquilibriumPriceUpdateMessage }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.bidQuantity = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.askQuantity = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.equilibriumPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.bestBidPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.bestAskPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.bestBidQuantity = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceUpdateMessage EXCEPT !.bestAskQuantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
OrderBookDirectoryMessageCode == 82  \* "R"
CombinationOrderBookDirectoryMessageCode == 77  \* "M"
TickSizeTableEntryMessageCode == 76  \* "L"
SystemEventMessageCode == 83  \* "S"
OrderBookStateMessageCode == 79  \* "O"
AddOrderNoParticipantIdMessageCode == 65  \* "A"
AddOrderParticipantIdMessageCode == 70  \* "F"
OrderExecutedMessageCode == 69  \* "E"
OrderExecutedWithPriceMessageCode == 67  \* "C"
OrderReplaceMessageCode == 85  \* "U"
OrderDeleteMessageCode == 68  \* "D"
TradeMessageCode == 80  \* "P"
EquilibriumPriceUpdateMessageCode == 90  \* "Z"

Payload ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {OrderBookDirectoryMessageCode}, body : OrderBookDirectoryMessage ]
        \cup [ tag : {CombinationOrderBookDirectoryMessageCode}, body : CombinationOrderBookDirectoryMessage ]
        \cup [ tag : {TickSizeTableEntryMessageCode}, body : TickSizeTableEntryMessage ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OrderBookStateMessageCode}, body : OrderBookStateMessage ]
        \cup [ tag : {AddOrderNoParticipantIdMessageCode}, body : AddOrderNoParticipantIdMessage ]
        \cup [ tag : {AddOrderParticipantIdMessageCode}, body : AddOrderParticipantIdMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceMessageCode}, body : OrderExecutedWithPriceMessage ]
        \cup [ tag : {OrderReplaceMessageCode}, body : OrderReplaceMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {EquilibriumPriceUpdateMessageCode}, body : EquilibriumPriceUpdateMessage ]

EncodePayload(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = OrderBookDirectoryMessageCode -> EncodeOrderBookDirectoryMessage(message.body)
      [] message.tag = CombinationOrderBookDirectoryMessageCode -> EncodeCombinationOrderBookDirectoryMessage(message.body)
      [] message.tag = TickSizeTableEntryMessageCode -> EncodeTickSizeTableEntryMessage(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OrderBookStateMessageCode -> EncodeOrderBookStateMessage(message.body)
      [] message.tag = AddOrderNoParticipantIdMessageCode -> EncodeAddOrderNoParticipantIdMessage(message.body)
      [] message.tag = AddOrderParticipantIdMessageCode -> EncodeAddOrderParticipantIdMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceMessageCode -> EncodeOrderExecutedWithPriceMessage(message.body)
      [] message.tag = OrderReplaceMessageCode -> EncodeOrderReplaceMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = EquilibriumPriceUpdateMessageCode -> EncodeEquilibriumPriceUpdateMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = OrderBookDirectoryMessageCode -> DecodeOrderBookDirectoryMessage(bytes)
              [] tag = CombinationOrderBookDirectoryMessageCode -> DecodeCombinationOrderBookDirectoryMessage(bytes)
              [] tag = TickSizeTableEntryMessageCode -> DecodeTickSizeTableEntryMessage(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OrderBookStateMessageCode -> DecodeOrderBookStateMessage(bytes)
              [] tag = AddOrderNoParticipantIdMessageCode -> DecodeAddOrderNoParticipantIdMessage(bytes)
              [] tag = AddOrderParticipantIdMessageCode -> DecodeAddOrderParticipantIdMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceMessageCode -> DecodeOrderExecutedWithPriceMessage(bytes)
              [] tag = OrderReplaceMessageCode -> DecodeOrderReplaceMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = EquilibriumPriceUpdateMessageCode -> DecodeEquilibriumPriceUpdateMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> OrderBookDirectoryMessageCode, body |-> one] : one \in CheckedOrderBookDirectoryMessage }
        \cup { [tag |-> CombinationOrderBookDirectoryMessageCode, body |-> one] : one \in CheckedCombinationOrderBookDirectoryMessage }
        \cup { [tag |-> TickSizeTableEntryMessageCode, body |-> one] : one \in CheckedTickSizeTableEntryMessage }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OrderBookStateMessageCode, body |-> one] : one \in CheckedOrderBookStateMessage }
        \cup { [tag |-> AddOrderNoParticipantIdMessageCode, body |-> one] : one \in CheckedAddOrderNoParticipantIdMessage }
        \cup { [tag |-> AddOrderParticipantIdMessageCode, body |-> one] : one \in CheckedAddOrderParticipantIdMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceMessage }
        \cup { [tag |-> OrderReplaceMessageCode, body |-> one] : one \in CheckedOrderReplaceMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> EquilibriumPriceUpdateMessageCode, body |-> one] : one \in CheckedEquilibriumPriceUpdateMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookDirectoryMessageCode, body |-> ZeroOrderBookDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CombinationOrderBookDirectoryMessageCode, body |-> ZeroCombinationOrderBookDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TickSizeTableEntryMessageCode, body |-> ZeroTickSizeTableEntryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookStateMessageCode, body |-> ZeroOrderBookStateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderNoParticipantIdMessageCode, body |-> ZeroAddOrderNoParticipantIdMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderParticipantIdMessageCode, body |-> ZeroAddOrderParticipantIdMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedWithPriceMessageCode, body |-> ZeroOrderExecutedWithPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderReplaceMessageCode, body |-> ZeroOrderReplaceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeleteMessageCode, body |-> ZeroOrderDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EquilibriumPriceUpdateMessageCode, body |-> ZeroEquilibriumPriceUpdateMessage]] }

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

(* Every Order Book Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookDirectoryMessage ==
    \A message \in CheckedOrderBookDirectoryMessage :
        LET read == DecodeOrderBookDirectoryMessage(EncodeOrderBookDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripLeg1 ==
    \A message \in CheckedLeg1 :
        LET read == DecodeLeg1(EncodeLeg1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripLeg2 ==
    \A message \in CheckedLeg2 :
        LET read == DecodeLeg2(EncodeLeg2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripLeg3 ==
    \A message \in CheckedLeg3 :
        LET read == DecodeLeg3(EncodeLeg3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg 4 decodes back to what was encoded, and leaves nothing over *)
RoundTripLeg4 ==
    \A message \in CheckedLeg4 :
        LET read == DecodeLeg4(EncodeLeg4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Combination Order Book Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinationOrderBookDirectoryMessage ==
    \A message \in CheckedCombinationOrderBookDirectoryMessage :
        LET read == DecodeCombinationOrderBookDirectoryMessage(EncodeCombinationOrderBookDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tick Size Table Entry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTickSizeTableEntryMessage ==
    \A message \in CheckedTickSizeTableEntryMessage :
        LET read == DecodeTickSizeTableEntryMessage(EncodeTickSizeTableEntryMessage(message))
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

(* Every Add Order No Participant Id Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderNoParticipantIdMessage ==
    \A message \in CheckedAddOrderNoParticipantIdMessage :
        LET read == DecodeAddOrderNoParticipantIdMessage(EncodeAddOrderNoParticipantIdMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Participant Id Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderParticipantIdMessage ==
    \A message \in CheckedAddOrderParticipantIdMessage :
        LET read == DecodeAddOrderParticipantIdMessage(EncodeAddOrderParticipantIdMessage(message))
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

(* Every Equilibrium Price Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEquilibriumPriceUpdateMessage ==
    \A message \in CheckedEquilibriumPriceUpdateMessage :
        LET read == DecodeEquilibriumPriceUpdateMessage(EncodeEquilibriumPriceUpdateMessage(message))
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
