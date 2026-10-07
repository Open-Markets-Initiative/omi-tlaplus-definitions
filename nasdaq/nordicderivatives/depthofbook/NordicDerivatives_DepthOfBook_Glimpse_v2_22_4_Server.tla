------- MODULE NordicDerivatives_DepthOfBook_Glimpse_v2_22_4_Server --------
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
(* Note: Exchange Order Type is a bit field set, checked as its 2 bytes    *)
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
      exchangeOrderType : Sample(2),
      lotType           : Sample(1) ]

EncodeAddOrderNoMpidAttribution(message) ==
    message.nanoseconds
        \o message.orderId
        \o message.orderBookId
        \o message.side
        \o message.orderBookPosition
        \o message.quantity
        \o message.price
        \o message.exchangeOrderType
        \o message.lotType

DecodeAddOrderNoMpidAttribution(bytes) ==
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

ZeroAddOrderNoMpidAttribution ==
    [ nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      orderBookId       |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      orderBookPosition |-> [i \in 1 .. 4 |-> 0],
      quantity          |-> [i \in 1 .. 8 |-> 0],
      price             |-> [i \in 1 .. 4 |-> 0],
      exchangeOrderType |-> [i \in 1 .. 2 |-> 0],
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
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.exchangeOrderType = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderNoMpidAttribution EXCEPT !.lotType = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Mpid Attribution: 43 bytes                                    *)
(***************************************************************************)

AddOrderMpidAttribution ==
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

EncodeAddOrderMpidAttribution(message) ==
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

DecodeAddOrderMpidAttribution(bytes) ==
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

ZeroAddOrderMpidAttribution ==
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

(* Add Order Mpid Attribution at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMpidAttribution ==
    { ZeroAddOrderMpidAttribution }
        \cup { [ZeroAddOrderMpidAttribution EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMpidAttribution EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMpidAttribution EXCEPT !.orderBookId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMpidAttribution EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMpidAttribution EXCEPT !.orderBookPosition = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMpidAttribution EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMpidAttribution EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMpidAttribution EXCEPT !.exchangeOrderType = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMpidAttribution EXCEPT !.lotType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMpidAttribution EXCEPT !.participantId = one] : one \in Sample(7) }

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
CombinationOrderBookDirectoryCode == 77  \* "M"
TickSizeTableEntryCode == 76  \* "L"
OrderBookStateMessageCode == 79  \* "O"
AddOrderNoMpidAttributionCode == 65  \* "A"
AddOrderMpidAttributionCode == 70  \* "F"
EndOfSnapshotMessageCode == 71  \* "G"

SequencedMessage ==
    [ tag : {SecondsMessageCode}, body : SecondsMessage ]
        \cup [ tag : {OrderBookDirectoryCode}, body : OrderBookDirectory ]
        \cup [ tag : {CombinationOrderBookDirectoryCode}, body : CombinationOrderBookDirectory ]
        \cup [ tag : {TickSizeTableEntryCode}, body : TickSizeTableEntry ]
        \cup [ tag : {OrderBookStateMessageCode}, body : OrderBookStateMessage ]
        \cup [ tag : {AddOrderNoMpidAttributionCode}, body : AddOrderNoMpidAttribution ]
        \cup [ tag : {AddOrderMpidAttributionCode}, body : AddOrderMpidAttribution ]
        \cup [ tag : {EndOfSnapshotMessageCode}, body : EndOfSnapshotMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SecondsMessageCode -> EncodeSecondsMessage(message.body)
      [] message.tag = OrderBookDirectoryCode -> EncodeOrderBookDirectory(message.body)
      [] message.tag = CombinationOrderBookDirectoryCode -> EncodeCombinationOrderBookDirectory(message.body)
      [] message.tag = TickSizeTableEntryCode -> EncodeTickSizeTableEntry(message.body)
      [] message.tag = OrderBookStateMessageCode -> EncodeOrderBookStateMessage(message.body)
      [] message.tag = AddOrderNoMpidAttributionCode -> EncodeAddOrderNoMpidAttribution(message.body)
      [] message.tag = AddOrderMpidAttributionCode -> EncodeAddOrderMpidAttribution(message.body)
      [] message.tag = EndOfSnapshotMessageCode -> EncodeEndOfSnapshotMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SecondsMessageCode -> DecodeSecondsMessage(bytes)
              [] tag = OrderBookDirectoryCode -> DecodeOrderBookDirectory(bytes)
              [] tag = CombinationOrderBookDirectoryCode -> DecodeCombinationOrderBookDirectory(bytes)
              [] tag = TickSizeTableEntryCode -> DecodeTickSizeTableEntry(bytes)
              [] tag = OrderBookStateMessageCode -> DecodeOrderBookStateMessage(bytes)
              [] tag = AddOrderNoMpidAttributionCode -> DecodeAddOrderNoMpidAttribution(bytes)
              [] tag = AddOrderMpidAttributionCode -> DecodeAddOrderMpidAttribution(bytes)
              [] tag = EndOfSnapshotMessageCode -> DecodeEndOfSnapshotMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SecondsMessageCode, body |-> ZeroSecondsMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SecondsMessageCode, body |-> one] : one \in CheckedSecondsMessage }
        \cup { [tag |-> OrderBookDirectoryCode, body |-> one] : one \in CheckedOrderBookDirectory }
        \cup { [tag |-> CombinationOrderBookDirectoryCode, body |-> one] : one \in CheckedCombinationOrderBookDirectory }
        \cup { [tag |-> TickSizeTableEntryCode, body |-> one] : one \in CheckedTickSizeTableEntry }
        \cup { [tag |-> OrderBookStateMessageCode, body |-> one] : one \in CheckedOrderBookStateMessage }
        \cup { [tag |-> AddOrderNoMpidAttributionCode, body |-> one] : one \in CheckedAddOrderNoMpidAttribution }
        \cup { [tag |-> AddOrderMpidAttributionCode, body |-> one] : one \in CheckedAddOrderMpidAttribution }
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

(* Every Add Order Mpid Attribution decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMpidAttribution ==
    \A message \in CheckedAddOrderMpidAttribution :
        LET read == DecodeAddOrderMpidAttribution(EncodeAddOrderMpidAttribution(message))
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
