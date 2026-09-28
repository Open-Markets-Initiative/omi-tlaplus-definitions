------------ MODULE NordicDerivatives_DepthOfBook_Itch_v2_22_4 -------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Genium INET Depth Of Book v2.22.4                              *)
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
(* Order Book Directory: 112 bytes                                         *)
(***************************************************************************)

OrderBookDirectory ==
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

EncodeOrderBookDirectory(message) ==
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

DecodeOrderBookDirectory(bytes) ==
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

ZeroOrderBookDirectory ==
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
        \cup { [ZeroOrderBookDirectory EXCEPT !.numberOfDecimalsInPrice = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.numberOfDecimalsInNominalValue = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.oddLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.blockLotSize = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookDirectory EXCEPT !.nominalValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Combination Order Book Directory: 260 bytes                             *)
(***************************************************************************)

CombinationOrderBookDirectory ==
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
      leg1Symbol                     : Sample(32),
      leg1Side                       : Sample(1),
      leg1Ratio                      : Sample(4),
      leg2Symbol                     : Sample(32),
      leg2Side                       : Sample(1),
      leg2Ratio                      : Sample(4),
      leg3Symbol                     : Sample(32),
      leg3Side                       : Sample(1),
      leg3Ratio                      : Sample(4),
      leg4Symbol                     : Sample(32),
      leg4Side                       : Sample(1),
      leg4Ratio                      : Sample(4) ]

EncodeCombinationOrderBookDirectory(message) ==
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
        \o message.leg1Symbol
        \o message.leg1Side
        \o message.leg1Ratio
        \o message.leg2Symbol
        \o message.leg2Side
        \o message.leg2Ratio
        \o message.leg3Symbol
        \o message.leg3Side
        \o message.leg3Ratio
        \o message.leg4Symbol
        \o message.leg4Side
        \o message.leg4Ratio

DecodeCombinationOrderBookDirectory(bytes) ==
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
    LET leg1Symbol == ReadBytes(nominalValue.rest, 32) IN IF ~leg1Symbol.ok THEN Fail ELSE
    LET leg1Side == ReadBytes(leg1Symbol.rest, 1) IN IF ~leg1Side.ok THEN Fail ELSE
    LET leg1Ratio == ReadBytes(leg1Side.rest, 4) IN IF ~leg1Ratio.ok THEN Fail ELSE
    LET leg2Symbol == ReadBytes(leg1Ratio.rest, 32) IN IF ~leg2Symbol.ok THEN Fail ELSE
    LET leg2Side == ReadBytes(leg2Symbol.rest, 1) IN IF ~leg2Side.ok THEN Fail ELSE
    LET leg2Ratio == ReadBytes(leg2Side.rest, 4) IN IF ~leg2Ratio.ok THEN Fail ELSE
    LET leg3Symbol == ReadBytes(leg2Ratio.rest, 32) IN IF ~leg3Symbol.ok THEN Fail ELSE
    LET leg3Side == ReadBytes(leg3Symbol.rest, 1) IN IF ~leg3Side.ok THEN Fail ELSE
    LET leg3Ratio == ReadBytes(leg3Side.rest, 4) IN IF ~leg3Ratio.ok THEN Fail ELSE
    LET leg4Symbol == ReadBytes(leg3Ratio.rest, 32) IN IF ~leg4Symbol.ok THEN Fail ELSE
    LET leg4Side == ReadBytes(leg4Symbol.rest, 1) IN IF ~leg4Side.ok THEN Fail ELSE
    LET leg4Ratio == ReadBytes(leg4Side.rest, 4) IN IF ~leg4Ratio.ok THEN Fail ELSE
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
         leg1Symbol                     |-> leg1Symbol.value,
         leg1Side                       |-> leg1Side.value,
         leg1Ratio                      |-> leg1Ratio.value,
         leg2Symbol                     |-> leg2Symbol.value,
         leg2Side                       |-> leg2Side.value,
         leg2Ratio                      |-> leg2Ratio.value,
         leg3Symbol                     |-> leg3Symbol.value,
         leg3Side                       |-> leg3Side.value,
         leg3Ratio                      |-> leg3Ratio.value,
         leg4Symbol                     |-> leg4Symbol.value,
         leg4Side                       |-> leg4Side.value,
         leg4Ratio                      |-> leg4Ratio.value ], leg4Ratio.rest)

ZeroCombinationOrderBookDirectory ==
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
      leg1Symbol                     |-> [i \in 1 .. 32 |-> 0],
      leg1Side                       |-> [i \in 1 .. 1 |-> 0],
      leg1Ratio                      |-> [i \in 1 .. 4 |-> 0],
      leg2Symbol                     |-> [i \in 1 .. 32 |-> 0],
      leg2Side                       |-> [i \in 1 .. 1 |-> 0],
      leg2Ratio                      |-> [i \in 1 .. 4 |-> 0],
      leg3Symbol                     |-> [i \in 1 .. 32 |-> 0],
      leg3Side                       |-> [i \in 1 .. 1 |-> 0],
      leg3Ratio                      |-> [i \in 1 .. 4 |-> 0],
      leg4Symbol                     |-> [i \in 1 .. 32 |-> 0],
      leg4Side                       |-> [i \in 1 .. 1 |-> 0],
      leg4Ratio                      |-> [i \in 1 .. 4 |-> 0] ]

(* Combination Order Book Directory at zero, then each field in turn at the values it is checked at *)
CheckedCombinationOrderBookDirectory ==
    { ZeroCombinationOrderBookDirectory }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.symbol = one] : one \in Sample(32) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.longName = one] : one \in Sample(32) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.financialProduct = one] : one \in Sample(1) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.numberOfDecimalsInPrice = one] : one \in Sample(2) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.numberOfDecimalsInNominalValue = one] : one \in Sample(2) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.oddLotSize = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.blockLotSize = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.nominalValue = one] : one \in Sample(8) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.leg1Symbol = one] : one \in Sample(32) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.leg1Side = one] : one \in Sample(1) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.leg1Ratio = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.leg2Symbol = one] : one \in Sample(32) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.leg2Side = one] : one \in Sample(1) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.leg2Ratio = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.leg3Symbol = one] : one \in Sample(32) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.leg3Side = one] : one \in Sample(1) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.leg3Ratio = one] : one \in Sample(4) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.leg4Symbol = one] : one \in Sample(32) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.leg4Side = one] : one \in Sample(1) }
        \cup { [ZeroCombinationOrderBookDirectory EXCEPT !.leg4Ratio = one] : one \in Sample(4) }

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
(* Stressed Market Message: 9 bytes                                        *)
(***************************************************************************)

StressedMarketMessage ==
    [ nanoseconds    : Sample(4),
      orderBookId    : Sample(4),
      stressedMarket : Sample(1) ]

EncodeStressedMarketMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.stressedMarket

DecodeStressedMarketMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET stressedMarket == ReadBytes(orderBookId.rest, 1) IN IF ~stressedMarket.ok THEN Fail ELSE
    Ok([ nanoseconds    |-> nanoseconds.value,
         orderBookId    |-> orderBookId.value,
         stressedMarket |-> stressedMarket.value ], stressedMarket.rest)

ZeroStressedMarketMessage ==
    [ nanoseconds    |-> [i \in 1 .. 4 |-> 0],
      orderBookId    |-> [i \in 1 .. 4 |-> 0],
      stressedMarket |-> [i \in 1 .. 1 |-> 0] ]

(* Stressed Market Message at zero, then each field in turn at the values it is checked at *)
CheckedStressedMarketMessage ==
    { ZeroStressedMarketMessage }
        \cup { [ZeroStressedMarketMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroStressedMarketMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroStressedMarketMessage EXCEPT !.stressedMarket = one] : one \in Sample(1) }

(***************************************************************************)
(* Exceptional Market Message: 9 bytes                                     *)
(***************************************************************************)

ExceptionalMarketMessage ==
    [ nanoseconds       : Sample(4),
      orderBookId       : Sample(4),
      exceptionalMarket : Sample(1) ]

EncodeExceptionalMarketMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.exceptionalMarket

DecodeExceptionalMarketMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET exceptionalMarket == ReadBytes(orderBookId.rest, 1) IN IF ~exceptionalMarket.ok THEN Fail ELSE
    Ok([ nanoseconds       |-> nanoseconds.value,
         orderBookId       |-> orderBookId.value,
         exceptionalMarket |-> exceptionalMarket.value ], exceptionalMarket.rest)

ZeroExceptionalMarketMessage ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      orderBookId       |-> [i \in 1 .. 4 |-> 0],
      exceptionalMarket |-> [i \in 1 .. 1 |-> 0] ]

(* Exceptional Market Message at zero, then each field in turn at the values it is checked at *)
CheckedExceptionalMarketMessage ==
    { ZeroExceptionalMarketMessage }
        \cup { [ZeroExceptionalMarketMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroExceptionalMarketMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroExceptionalMarketMessage EXCEPT !.exceptionalMarket = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order No Mpid Attribution: 36 bytes                                 *)
(***************************************************************************)

AddOrderNoMpidAttribution ==
    [ nanoseconds       : Sample(4),
      orderId           : Sample(8),
      orderBookId       : Sample(4),
      side              : Sample(1),
      orderBookPosition : Sample(4),
      quantity          : Sample(8),
      price             : Sample(4),
      orderAttributes   : Sample(2),
      lotType           : Sample(1) ]

EncodeAddOrderNoMpidAttribution(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.orderBookPosition
        \o message.quantity
        \o message.price
        \o message.orderAttributes
        \o message.lotType

DecodeAddOrderNoMpidAttribution(bytes) ==
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

ZeroAddOrderNoMpidAttribution ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      orderBookId       |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      orderBookPosition |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      orderAttributes   |-> [i \in 1 .. 2 |-> 0],
      lotType           |-> [i \in 1 .. 1 |-> 0] ]

(* Add Order No Mpid Attribution at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderNoMpidAttribution ==
    { ZeroAddOrderNoMpidAttribution }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.orderBookPosition = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.orderAttributes = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.lotType = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order With Mpid Attribution: 43 bytes                               *)
(***************************************************************************)

AddOrderWithMpidAttribution ==
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

EncodeAddOrderWithMpidAttribution(message) ==
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

DecodeAddOrderWithMpidAttribution(bytes) ==
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

ZeroAddOrderWithMpidAttribution ==
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

(* Add Order With Mpid Attribution at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderWithMpidAttribution ==
    { ZeroAddOrderWithMpidAttribution }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.orderBookPosition = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.orderAttributes = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderWithMpidAttribution EXCEPT !.participantId = one] : one \in Sample(7) }

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
      orderAttributes      : Sample(2) ]

EncodeOrderReplaceMessage(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.newOrderBookPosition
        \o message.quantity
        \o message.price
        \o message.orderAttributes

DecodeOrderReplaceMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderId == ReadBytes(nanoseconds.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(orderId.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET side == ReadBytes(orderBookId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET newOrderBookPosition == ReadBytes(side.rest, 4) IN IF ~newOrderBookPosition.ok THEN Fail ELSE
    LET quantity == ReadBytes(newOrderBookPosition.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET orderAttributes == ReadBytes(price.rest, 2) IN IF ~orderAttributes.ok THEN Fail ELSE
    Ok([ nanoseconds          |-> nanoseconds.value,
         orderId              |-> orderId.value,
         orderBookId          |-> orderBookId.value,
         side                 |-> side.value,
         newOrderBookPosition |-> newOrderBookPosition.value,
         quantity             |-> quantity.value,
         price                |-> price.value,
         orderAttributes      |-> orderAttributes.value ], orderAttributes.rest)

ZeroOrderReplaceMessage ==
    [ nanoseconds          |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      orderBookId          |-> [i \in 1 .. 4 |-> 0],
      side                 |-> [i \in 1 .. 1 |-> 0],
      newOrderBookPosition |-> [i \in 1 .. 4 |-> 0],
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
        \cup { [ZeroOrderReplaceMessage EXCEPT !.newOrderBookPosition = one] : one \in Sample(4) }
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
(* Equilibrium Price Update: 52 bytes                                      *)
(***************************************************************************)

EquilibriumPriceUpdate ==
    [ nanoseconds                            : Sample(4),
      orderBookId                            : Sample(4),
      availableBidQuantityAtEquilibriumPrice : Sample(8),
      availableAskQuantityAtEquilibriumPrice : Sample(8),
      equilibriumPrice                       : Sample(4),
      reserved4A                             : Sample(4),
      reserved4B                             : Sample(4),
      reserved8A                             : Sample(8),
      reserved8B                             : Sample(8) ]

EncodeEquilibriumPriceUpdate(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.availableBidQuantityAtEquilibriumPrice
        \o message.availableAskQuantityAtEquilibriumPrice
        \o message.equilibriumPrice
        \o message.reserved4A
        \o message.reserved4B
        \o message.reserved8A
        \o message.reserved8B

DecodeEquilibriumPriceUpdate(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET availableBidQuantityAtEquilibriumPrice == ReadBytes(orderBookId.rest, 8) IN IF ~availableBidQuantityAtEquilibriumPrice.ok THEN Fail ELSE
    LET availableAskQuantityAtEquilibriumPrice == ReadBytes(availableBidQuantityAtEquilibriumPrice.rest, 8) IN IF ~availableAskQuantityAtEquilibriumPrice.ok THEN Fail ELSE
    LET equilibriumPrice == ReadBytes(availableAskQuantityAtEquilibriumPrice.rest, 4) IN IF ~equilibriumPrice.ok THEN Fail ELSE
    LET reserved4A == ReadBytes(equilibriumPrice.rest, 4) IN IF ~reserved4A.ok THEN Fail ELSE
    LET reserved4B == ReadBytes(reserved4A.rest, 4) IN IF ~reserved4B.ok THEN Fail ELSE
    LET reserved8A == ReadBytes(reserved4B.rest, 8) IN IF ~reserved8A.ok THEN Fail ELSE
    LET reserved8B == ReadBytes(reserved8A.rest, 8) IN IF ~reserved8B.ok THEN Fail ELSE
    Ok([ nanoseconds                            |-> nanoseconds.value,
         orderBookId                            |-> orderBookId.value,
         availableBidQuantityAtEquilibriumPrice |-> availableBidQuantityAtEquilibriumPrice.value,
         availableAskQuantityAtEquilibriumPrice |-> availableAskQuantityAtEquilibriumPrice.value,
         equilibriumPrice                       |-> equilibriumPrice.value,
         reserved4A                             |-> reserved4A.value,
         reserved4B                             |-> reserved4B.value,
         reserved8A                             |-> reserved8A.value,
         reserved8B                             |-> reserved8B.value ], reserved8B.rest)

ZeroEquilibriumPriceUpdate ==
    [ nanoseconds                            |-> [i \in 1 .. 4 |-> 0],
      orderBookId                            |-> [i \in 1 .. 4 |-> 0],
      availableBidQuantityAtEquilibriumPrice |-> [i \in 1 .. 8 |-> 0],
      availableAskQuantityAtEquilibriumPrice |-> [i \in 1 .. 8 |-> 0],
      equilibriumPrice                       |-> [i \in 1 .. 4 |-> 0],
      reserved4A                             |-> [i \in 1 .. 4 |-> 0],
      reserved4B                             |-> [i \in 1 .. 4 |-> 0],
      reserved8A                             |-> [i \in 1 .. 8 |-> 0],
      reserved8B                             |-> [i \in 1 .. 8 |-> 0] ]

(* Equilibrium Price Update at zero, then each field in turn at the values it is checked at *)
CheckedEquilibriumPriceUpdate ==
    { ZeroEquilibriumPriceUpdate }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.availableBidQuantityAtEquilibriumPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.availableAskQuantityAtEquilibriumPrice = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.equilibriumPrice = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.reserved4A = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.reserved4B = one] : one \in Sample(4) }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.reserved8A = one] : one \in Sample(8) }
        \cup { [ZeroEquilibriumPriceUpdate EXCEPT !.reserved8B = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Request Message: 30 bytes                                         *)
(***************************************************************************)

QuoteRequestMessage ==
    [ nanoseconds : Sample(4),
      orderBookId : Sample(4),
      reserved7   : Sample(7),
      reserved5   : Sample(5),
      reserved1   : Sample(1),
      side        : Sample(1),
      quantity    : Sample(8) ]

EncodeQuoteRequestMessage(message) ==
    message.nanoseconds
        \o message.orderBookId
        \o message.reserved7
        \o message.reserved5
        \o message.reserved1
        \o message.side
        \o message.quantity

DecodeQuoteRequestMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET orderBookId == ReadBytes(nanoseconds.rest, 4) IN IF ~orderBookId.ok THEN Fail ELSE
    LET reserved7 == ReadBytes(orderBookId.rest, 7) IN IF ~reserved7.ok THEN Fail ELSE
    LET reserved5 == ReadBytes(reserved7.rest, 5) IN IF ~reserved5.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(reserved5.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET side == ReadBytes(reserved1.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    Ok([ nanoseconds |-> nanoseconds.value,
         orderBookId |-> orderBookId.value,
         reserved7   |-> reserved7.value,
         reserved5   |-> reserved5.value,
         reserved1   |-> reserved1.value,
         side        |-> side.value,
         quantity    |-> quantity.value ], quantity.rest)

ZeroQuoteRequestMessage ==
    [ nanoseconds |-> [i \in 1 .. 4 |-> 0],
      orderBookId |-> [i \in 1 .. 4 |-> 0],
      reserved7   |-> [i \in 1 .. 7 |-> 0],
      reserved5   |-> [i \in 1 .. 5 |-> 0],
      reserved1   |-> [i \in 1 .. 1 |-> 0],
      side        |-> [i \in 1 .. 1 |-> 0],
      quantity    |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Request Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestMessage ==
    { ZeroQuoteRequestMessage }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.reserved7 = one] : one \in Sample(7) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.reserved5 = one] : one \in Sample(5) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.quantity = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SecondsMessageCode == 84  \* "T"
OrderBookDirectoryCode == 82  \* "R"
CombinationOrderBookDirectoryCode == 77  \* "M"
TickSizeTableEntryCode == 76  \* "L"
SystemEventMessageCode == 83  \* "S"
OrderBookStateMessageCode == 79  \* "O"
StressedMarketMessageCode == 75  \* "K"
ExceptionalMarketMessageCode == 88  \* "X"
AddOrderNoMpidAttributionCode == 65  \* "A"
AddOrderWithMpidAttributionCode == 70  \* "F"
OrderExecutedMessageCode == 69  \* "E"
OrderExecutedWithPriceMessageCode == 67  \* "C"
OrderReplaceMessageCode == 85  \* "U"
OrderDeleteMessageCode == 68  \* "D"
TradeMessageCode == 80  \* "P"
EquilibriumPriceUpdateCode == 90  \* "Z"
QuoteRequestMessageCode == 113  \* "q"

Payload ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {OrderBookDirectoryCode}, body : OrderBookDirectory ]
        \cup [ tag : {CombinationOrderBookDirectoryCode}, body : CombinationOrderBookDirectory ]
        \cup [ tag : {TickSizeTableEntryCode}, body : TickSizeTableEntry ]
        \cup [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OrderBookStateMessageCode}, body : OrderBookStateMessage ]
        \cup [ tag : {StressedMarketMessageCode}, body : StressedMarketMessage ]
        \cup [ tag : {ExceptionalMarketMessageCode}, body : ExceptionalMarketMessage ]
        \cup [ tag : {AddOrderNoMpidAttributionCode}, body : AddOrderNoMpidAttribution ]
        \cup [ tag : {AddOrderWithMpidAttributionCode}, body : AddOrderWithMpidAttribution ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceMessageCode}, body : OrderExecutedWithPriceMessage ]
        \cup [ tag : {OrderReplaceMessageCode}, body : OrderReplaceMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {EquilibriumPriceUpdateCode}, body : EquilibriumPriceUpdate ]
        \cup [ tag : {QuoteRequestMessageCode}, body : QuoteRequestMessage ]

EncodePayload(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = OrderBookDirectoryCode -> EncodeOrderBookDirectory(message.body)
      [] message.tag = CombinationOrderBookDirectoryCode -> EncodeCombinationOrderBookDirectory(message.body)
      [] message.tag = TickSizeTableEntryCode -> EncodeTickSizeTableEntry(message.body)
      [] message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OrderBookStateMessageCode -> EncodeOrderBookStateMessage(message.body)
      [] message.tag = StressedMarketMessageCode -> EncodeStressedMarketMessage(message.body)
      [] message.tag = ExceptionalMarketMessageCode -> EncodeExceptionalMarketMessage(message.body)
      [] message.tag = AddOrderNoMpidAttributionCode -> EncodeAddOrderNoMpidAttribution(message.body)
      [] message.tag = AddOrderWithMpidAttributionCode -> EncodeAddOrderWithMpidAttribution(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceMessageCode -> EncodeOrderExecutedWithPriceMessage(message.body)
      [] message.tag = OrderReplaceMessageCode -> EncodeOrderReplaceMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = EquilibriumPriceUpdateCode -> EncodeEquilibriumPriceUpdate(message.body)
      [] message.tag = QuoteRequestMessageCode -> EncodeQuoteRequestMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = OrderBookDirectoryCode -> DecodeOrderBookDirectory(bytes)
              [] tag = CombinationOrderBookDirectoryCode -> DecodeCombinationOrderBookDirectory(bytes)
              [] tag = TickSizeTableEntryCode -> DecodeTickSizeTableEntry(bytes)
              [] tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OrderBookStateMessageCode -> DecodeOrderBookStateMessage(bytes)
              [] tag = StressedMarketMessageCode -> DecodeStressedMarketMessage(bytes)
              [] tag = ExceptionalMarketMessageCode -> DecodeExceptionalMarketMessage(bytes)
              [] tag = AddOrderNoMpidAttributionCode -> DecodeAddOrderNoMpidAttribution(bytes)
              [] tag = AddOrderWithMpidAttributionCode -> DecodeAddOrderWithMpidAttribution(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceMessageCode -> DecodeOrderExecutedWithPriceMessage(bytes)
              [] tag = OrderReplaceMessageCode -> DecodeOrderReplaceMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = EquilibriumPriceUpdateCode -> DecodeEquilibriumPriceUpdate(bytes)
              [] tag = QuoteRequestMessageCode -> DecodeQuoteRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> OrderBookDirectoryCode, body |-> one] : one \in CheckedOrderBookDirectory }
        \cup { [tag |-> CombinationOrderBookDirectoryCode, body |-> one] : one \in CheckedCombinationOrderBookDirectory }
        \cup { [tag |-> TickSizeTableEntryCode, body |-> one] : one \in CheckedTickSizeTableEntry }
        \cup { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OrderBookStateMessageCode, body |-> one] : one \in CheckedOrderBookStateMessage }
        \cup { [tag |-> StressedMarketMessageCode, body |-> one] : one \in CheckedStressedMarketMessage }
        \cup { [tag |-> ExceptionalMarketMessageCode, body |-> one] : one \in CheckedExceptionalMarketMessage }
        \cup { [tag |-> AddOrderNoMpidAttributionCode, body |-> one] : one \in CheckedAddOrderNoMpidAttribution }
        \cup { [tag |-> AddOrderWithMpidAttributionCode, body |-> one] : one \in CheckedAddOrderWithMpidAttribution }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceMessage }
        \cup { [tag |-> OrderReplaceMessageCode, body |-> one] : one \in CheckedOrderReplaceMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> EquilibriumPriceUpdateCode, body |-> one] : one \in CheckedEquilibriumPriceUpdate }
        \cup { [tag |-> QuoteRequestMessageCode, body |-> one] : one \in CheckedQuoteRequestMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> CombinationOrderBookDirectoryCode, body |-> ZeroCombinationOrderBookDirectory]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TickSizeTableEntryCode, body |-> ZeroTickSizeTableEntry]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookStateMessageCode, body |-> ZeroOrderBookStateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StressedMarketMessageCode, body |-> ZeroStressedMarketMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExceptionalMarketMessageCode, body |-> ZeroExceptionalMarketMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderNoMpidAttributionCode, body |-> ZeroAddOrderNoMpidAttribution]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AddOrderWithMpidAttributionCode, body |-> ZeroAddOrderWithMpidAttribution]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderExecutedWithPriceMessageCode, body |-> ZeroOrderExecutedWithPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderReplaceMessageCode, body |-> ZeroOrderReplaceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderDeleteMessageCode, body |-> ZeroOrderDeleteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EquilibriumPriceUpdateCode, body |-> ZeroEquilibriumPriceUpdate]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteRequestMessageCode, body |-> ZeroQuoteRequestMessage]] }

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

(* Every Combination Order Book Directory decodes back to what was encoded, and leaves nothing over *)
RoundTripCombinationOrderBookDirectory ==
    \A message \in CheckedCombinationOrderBookDirectory :
        LET read == DecodeCombinationOrderBookDirectory(EncodeCombinationOrderBookDirectory(message))
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

(* Every Stressed Market Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStressedMarketMessage ==
    \A message \in CheckedStressedMarketMessage :
        LET read == DecodeStressedMarketMessage(EncodeStressedMarketMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Exceptional Market Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExceptionalMarketMessage ==
    \A message \in CheckedExceptionalMarketMessage :
        LET read == DecodeExceptionalMarketMessage(EncodeExceptionalMarketMessage(message))
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

(* Every Quote Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequestMessage ==
    \A message \in CheckedQuoteRequestMessage :
        LET read == DecodeQuoteRequestMessage(EncodeQuoteRequestMessage(message))
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
