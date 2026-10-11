------------------ MODULE MemxOptions_MemoirDepth_v1_6_a -------------------
(***************************************************************************)
(* The Members Exchange Member Order Information Record Depth v1.6.a       *)
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
(* Note: Trade Conditions is a bit field set, checked as its 1 byte rather *)
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
(* Instrument Directory Message: 56 bytes                                  *)
(***************************************************************************)

InstrumentDirectoryMessage ==
    [ timestamp          : Sample(8),
      symbol             : Sample(8),
      optionsProductType : Sample(1),
      underlier          : Sample(6),
      osiRoot            : Sample(6),
      maturityDate       : Sample(8),
      strikePutOrCall    : Sample(1),
      strikePrice        : Sample(8),
      closingOnly        : Sample(1),
      closingTime        : Sample(8),
      isTestSymbol       : Sample(1) ]

EncodeInstrumentDirectoryMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.optionsProductType
        \o message.underlier
        \o message.osiRoot
        \o message.maturityDate
        \o message.strikePutOrCall
        \o message.strikePrice
        \o message.closingOnly
        \o message.closingTime
        \o message.isTestSymbol

DecodeInstrumentDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET optionsProductType == ReadBytes(symbol.rest, 1) IN IF ~optionsProductType.ok THEN Fail ELSE
    LET underlier == ReadBytes(optionsProductType.rest, 6) IN IF ~underlier.ok THEN Fail ELSE
    LET osiRoot == ReadBytes(underlier.rest, 6) IN IF ~osiRoot.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(osiRoot.rest, 8) IN IF ~maturityDate.ok THEN Fail ELSE
    LET strikePutOrCall == ReadBytes(maturityDate.rest, 1) IN IF ~strikePutOrCall.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(strikePutOrCall.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET closingOnly == ReadBytes(strikePrice.rest, 1) IN IF ~closingOnly.ok THEN Fail ELSE
    LET closingTime == ReadBytes(closingOnly.rest, 8) IN IF ~closingTime.ok THEN Fail ELSE
    LET isTestSymbol == ReadBytes(closingTime.rest, 1) IN IF ~isTestSymbol.ok THEN Fail ELSE
    Ok([ timestamp          |-> timestamp.value,
         symbol             |-> symbol.value,
         optionsProductType |-> optionsProductType.value,
         underlier          |-> underlier.value,
         osiRoot            |-> osiRoot.value,
         maturityDate       |-> maturityDate.value,
         strikePutOrCall    |-> strikePutOrCall.value,
         strikePrice        |-> strikePrice.value,
         closingOnly        |-> closingOnly.value,
         closingTime        |-> closingTime.value,
         isTestSymbol       |-> isTestSymbol.value ], isTestSymbol.rest)

ZeroInstrumentDirectoryMessage ==
    [ timestamp          |-> [i \in 1 .. 8 |-> 0],
      symbol             |-> [i \in 1 .. 8 |-> 0],
      optionsProductType |-> [i \in 1 .. 1 |-> 0],
      underlier          |-> [i \in 1 .. 6 |-> 0],
      osiRoot            |-> [i \in 1 .. 6 |-> 0],
      maturityDate       |-> [i \in 1 .. 8 |-> 0],
      strikePutOrCall    |-> [i \in 1 .. 1 |-> 0],
      strikePrice        |-> [i \in 1 .. 8 |-> 0],
      closingOnly        |-> [i \in 1 .. 1 |-> 0],
      closingTime        |-> [i \in 1 .. 8 |-> 0],
      isTestSymbol       |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDirectoryMessage ==
    { ZeroInstrumentDirectoryMessage }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.optionsProductType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.underlier = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.osiRoot = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.maturityDate = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.strikePutOrCall = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.closingOnly = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.closingTime = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.isTestSymbol = one] : one \in Sample(1) }

(***************************************************************************)
(* Options Instrument Status Message: 19 bytes                             *)
(***************************************************************************)

OptionsInstrumentStatusMessage ==
    [ timestamp                     : Sample(8),
      symbol                        : Sample(8),
      instrumentTradingStatus       : Sample(1),
      instrumentTradingStatusReason : Sample(1),
      tradingSession                : Sample(1) ]

EncodeOptionsInstrumentStatusMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.instrumentTradingStatus
        \o message.instrumentTradingStatusReason
        \o message.tradingSession

DecodeOptionsInstrumentStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(symbol.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET instrumentTradingStatusReason == ReadBytes(instrumentTradingStatus.rest, 1) IN IF ~instrumentTradingStatusReason.ok THEN Fail ELSE
    LET tradingSession == ReadBytes(instrumentTradingStatusReason.rest, 1) IN IF ~tradingSession.ok THEN Fail ELSE
    Ok([ timestamp                     |-> timestamp.value,
         symbol                        |-> symbol.value,
         instrumentTradingStatus       |-> instrumentTradingStatus.value,
         instrumentTradingStatusReason |-> instrumentTradingStatusReason.value,
         tradingSession                |-> tradingSession.value ], tradingSession.rest)

ZeroOptionsInstrumentStatusMessage ==
    [ timestamp                     |-> [i \in 1 .. 8 |-> 0],
      symbol                        |-> [i \in 1 .. 8 |-> 0],
      instrumentTradingStatus       |-> [i \in 1 .. 1 |-> 0],
      instrumentTradingStatusReason |-> [i \in 1 .. 1 |-> 0],
      tradingSession                |-> [i \in 1 .. 1 |-> 0] ]

(* Options Instrument Status Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsInstrumentStatusMessage ==
    { ZeroOptionsInstrumentStatusMessage }
        \cup { [ZeroOptionsInstrumentStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOptionsInstrumentStatusMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOptionsInstrumentStatusMessage EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroOptionsInstrumentStatusMessage EXCEPT !.instrumentTradingStatusReason = one] : one \in Sample(1) }
        \cup { [ZeroOptionsInstrumentStatusMessage EXCEPT !.tradingSession = one] : one \in Sample(1) }

(***************************************************************************)
(* Underlier Instrument Status Message: 15 bytes                           *)
(***************************************************************************)

UnderlierInstrumentStatusMessage ==
    [ timestamp      : Sample(8),
      tradingSession : Sample(1),
      underlier      : Sample(6) ]

EncodeUnderlierInstrumentStatusMessage(message) ==
    message.timestamp
        \o message.tradingSession
        \o message.underlier

DecodeUnderlierInstrumentStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET tradingSession == ReadBytes(timestamp.rest, 1) IN IF ~tradingSession.ok THEN Fail ELSE
    LET underlier == ReadBytes(tradingSession.rest, 6) IN IF ~underlier.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         tradingSession |-> tradingSession.value,
         underlier      |-> underlier.value ], underlier.rest)

ZeroUnderlierInstrumentStatusMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      tradingSession |-> [i \in 1 .. 1 |-> 0],
      underlier      |-> [i \in 1 .. 6 |-> 0] ]

(* Underlier Instrument Status Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlierInstrumentStatusMessage ==
    { ZeroUnderlierInstrumentStatusMessage }
        \cup { [ZeroUnderlierInstrumentStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroUnderlierInstrumentStatusMessage EXCEPT !.tradingSession = one] : one \in Sample(1) }
        \cup { [ZeroUnderlierInstrumentStatusMessage EXCEPT !.underlier = one] : one \in Sample(6) }

(***************************************************************************)
(* Broken Trade Message: 36 bytes                                          *)
(***************************************************************************)

BrokenTradeMessage ==
    [ timestamp        : Sample(8),
      symbol           : Sample(8),
      tradeId          : Sample(8),
      originalQuantity : Sample(4),
      originalPrice    : Sample(8) ]

EncodeBrokenTradeMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.tradeId
        \o message.originalQuantity
        \o message.originalPrice

DecodeBrokenTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbol.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET originalQuantity == ReadBytes(tradeId.rest, 4) IN IF ~originalQuantity.ok THEN Fail ELSE
    LET originalPrice == ReadBytes(originalQuantity.rest, 8) IN IF ~originalPrice.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         symbol           |-> symbol.value,
         tradeId          |-> tradeId.value,
         originalQuantity |-> originalQuantity.value,
         originalPrice    |-> originalPrice.value ], originalPrice.rest)

ZeroBrokenTradeMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      symbol           |-> [i \in 1 .. 8 |-> 0],
      tradeId          |-> [i \in 1 .. 8 |-> 0],
      originalQuantity |-> [i \in 1 .. 4 |-> 0],
      originalPrice    |-> [i \in 1 .. 8 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.originalQuantity = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.originalPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Corrected Trade Message: 48 bytes                                       *)
(***************************************************************************)

CorrectedTradeMessage ==
    [ timestamp         : Sample(8),
      symbol            : Sample(8),
      tradeId           : Sample(8),
      originalQuantity  : Sample(4),
      originalPrice     : Sample(8),
      correctedQuantity : Sample(4),
      correctedPrice    : Sample(8) ]

EncodeCorrectedTradeMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.tradeId
        \o message.originalQuantity
        \o message.originalPrice
        \o message.correctedQuantity
        \o message.correctedPrice

DecodeCorrectedTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbol.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET originalQuantity == ReadBytes(tradeId.rest, 4) IN IF ~originalQuantity.ok THEN Fail ELSE
    LET originalPrice == ReadBytes(originalQuantity.rest, 8) IN IF ~originalPrice.ok THEN Fail ELSE
    LET correctedQuantity == ReadBytes(originalPrice.rest, 4) IN IF ~correctedQuantity.ok THEN Fail ELSE
    LET correctedPrice == ReadBytes(correctedQuantity.rest, 8) IN IF ~correctedPrice.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         symbol            |-> symbol.value,
         tradeId           |-> tradeId.value,
         originalQuantity  |-> originalQuantity.value,
         originalPrice     |-> originalPrice.value,
         correctedQuantity |-> correctedQuantity.value,
         correctedPrice    |-> correctedPrice.value ], correctedPrice.rest)

ZeroCorrectedTradeMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      symbol            |-> [i \in 1 .. 8 |-> 0],
      tradeId           |-> [i \in 1 .. 8 |-> 0],
      originalQuantity  |-> [i \in 1 .. 4 |-> 0],
      originalPrice     |-> [i \in 1 .. 8 |-> 0],
      correctedQuantity |-> [i \in 1 .. 4 |-> 0],
      correctedPrice    |-> [i \in 1 .. 8 |-> 0] ]

(* Corrected Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedCorrectedTradeMessage ==
    { ZeroCorrectedTradeMessage }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.originalQuantity = one] : one \in Sample(4) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.originalPrice = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.correctedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroCorrectedTradeMessage EXCEPT !.correctedPrice = one] : one \in Sample(8) }

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
(* Order Added Short Message: 29 bytes                                     *)
(***************************************************************************)

OrderAddedShortMessage ==
    [ timestamp     : Sample(8),
      symbol        : Sample(8),
      orderId       : Sample(8),
      side          : Sample(1),
      quantityShort : Sample(2),
      priceShort    : Sample(2) ]

EncodeOrderAddedShortMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.orderId
        \o message.side
        \o message.quantityShort
        \o message.priceShort

DecodeOrderAddedShortMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbol.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(side.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET priceShort == ReadBytes(quantityShort.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         symbol        |-> symbol.value,
         orderId       |-> orderId.value,
         side          |-> side.value,
         quantityShort |-> quantityShort.value,
         priceShort    |-> priceShort.value ], priceShort.rest)

ZeroOrderAddedShortMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      symbol        |-> [i \in 1 .. 8 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      quantityShort |-> [i \in 1 .. 2 |-> 0],
      priceShort    |-> [i \in 1 .. 2 |-> 0] ]

(* Order Added Short Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddedShortMessage ==
    { ZeroOrderAddedShortMessage }
        \cup { [ZeroOrderAddedShortMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddedShortMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddedShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddedShortMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddedShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroOrderAddedShortMessage EXCEPT !.priceShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Added Long Message: 37 bytes                                      *)
(***************************************************************************)

OrderAddedLongMessage ==
    [ timestamp : Sample(8),
      symbol    : Sample(8),
      orderId   : Sample(8),
      side      : Sample(1),
      quantity  : Sample(4),
      price     : Sample(8) ]

EncodeOrderAddedLongMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.orderId
        \o message.side
        \o message.quantity
        \o message.price

DecodeOrderAddedLongMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET orderId == ReadBytes(symbol.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         symbol    |-> symbol.value,
         orderId   |-> orderId.value,
         side      |-> side.value,
         quantity  |-> quantity.value,
         price     |-> price.value ], price.rest)

ZeroOrderAddedLongMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      symbol    |-> [i \in 1 .. 8 |-> 0],
      orderId   |-> [i \in 1 .. 8 |-> 0],
      side      |-> [i \in 1 .. 1 |-> 0],
      quantity  |-> [i \in 1 .. 4 |-> 0],
      price     |-> [i \in 1 .. 8 |-> 0] ]

(* Order Added Long Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddedLongMessage ==
    { ZeroOrderAddedLongMessage }
        \cup { [ZeroOrderAddedLongMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddedLongMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddedLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddedLongMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddedLongMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddedLongMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Added Extended Message: 38 bytes                                  *)
(***************************************************************************)

OrderAddedExtendedMessage ==
    [ timestamp     : Sample(8),
      symbol        : Sample(8),
      orderCapacity : Sample(1),
      orderId       : Sample(8),
      side          : Sample(1),
      quantity      : Sample(4),
      price         : Sample(8) ]

EncodeOrderAddedExtendedMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.orderCapacity
        \o message.orderId
        \o message.side
        \o message.quantity
        \o message.price

DecodeOrderAddedExtendedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(symbol.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderCapacity.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         symbol        |-> symbol.value,
         orderCapacity |-> orderCapacity.value,
         orderId       |-> orderId.value,
         side          |-> side.value,
         quantity      |-> quantity.value,
         price         |-> price.value ], price.rest)

ZeroOrderAddedExtendedMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      symbol        |-> [i \in 1 .. 8 |-> 0],
      orderCapacity |-> [i \in 1 .. 1 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      quantity      |-> [i \in 1 .. 4 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0] ]

(* Order Added Extended Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddedExtendedMessage ==
    { ZeroOrderAddedExtendedMessage }
        \cup { [ZeroOrderAddedExtendedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddedExtendedMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddedExtendedMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddedExtendedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddedExtendedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddedExtendedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddedExtendedMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Deleted Message: 25 bytes                                         *)
(***************************************************************************)

OrderDeletedMessage ==
    [ timestamp     : Sample(8),
      symbol        : Sample(8),
      orderCapacity : Sample(1),
      orderId       : Sample(8) ]

EncodeOrderDeletedMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.orderCapacity
        \o message.orderId

DecodeOrderDeletedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(symbol.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderCapacity.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         symbol        |-> symbol.value,
         orderCapacity |-> orderCapacity.value,
         orderId       |-> orderId.value ], orderId.rest)

ZeroOrderDeletedMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      symbol        |-> [i \in 1 .. 8 |-> 0],
      orderCapacity |-> [i \in 1 .. 1 |-> 0],
      orderId       |-> [i \in 1 .. 8 |-> 0] ]

(* Order Deleted Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeletedMessage ==
    { ZeroOrderDeletedMessage }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderDeletedMessage EXCEPT !.orderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Reduced Message: 42 bytes                                         *)
(***************************************************************************)

OrderReducedMessage ==
    [ timestamp       : Sample(8),
      symbol          : Sample(8),
      orderCapacity   : Sample(1),
      orderId         : Sample(8),
      side            : Sample(1),
      quantity        : Sample(4),
      price           : Sample(8),
      quantityReduced : Sample(4) ]

EncodeOrderReducedMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.orderCapacity
        \o message.orderId
        \o message.side
        \o message.quantity
        \o message.price
        \o message.quantityReduced

DecodeOrderReducedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(symbol.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderCapacity.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantityReduced == ReadBytes(price.rest, 4) IN IF ~quantityReduced.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         symbol          |-> symbol.value,
         orderCapacity   |-> orderCapacity.value,
         orderId         |-> orderId.value,
         side            |-> side.value,
         quantity        |-> quantity.value,
         price           |-> price.value,
         quantityReduced |-> quantityReduced.value ], quantityReduced.rest)

ZeroOrderReducedMessage ==
    [ timestamp       |-> [i \in 1 .. 8 |-> 0],
      symbol          |-> [i \in 1 .. 8 |-> 0],
      orderCapacity   |-> [i \in 1 .. 1 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      quantity        |-> [i \in 1 .. 4 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0],
      quantityReduced |-> [i \in 1 .. 4 |-> 0] ]

(* Order Reduced Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReducedMessage ==
    { ZeroOrderReducedMessage }
        \cup { [ZeroOrderReducedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderReducedMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderReducedMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderReducedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReducedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderReducedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderReducedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderReducedMessage EXCEPT !.quantityReduced = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed Message: 46 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timestamp       : Sample(8),
      symbol          : Sample(8),
      orderCapacity   : Sample(1),
      tradeConditions : Sample(1),
      orderId         : Sample(8),
      tradeId         : Sample(8),
      quantity        : Sample(4),
      price           : Sample(8) ]

EncodeOrderExecutedMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.orderCapacity
        \o message.tradeConditions
        \o message.orderId
        \o message.tradeId
        \o message.quantity
        \o message.price

DecodeOrderExecutedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(symbol.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET tradeConditions == ReadBytes(orderCapacity.rest, 1) IN IF ~tradeConditions.ok THEN Fail ELSE
    LET orderId == ReadBytes(tradeConditions.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(orderId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET quantity == ReadBytes(tradeId.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         symbol          |-> symbol.value,
         orderCapacity   |-> orderCapacity.value,
         tradeConditions |-> tradeConditions.value,
         orderId         |-> orderId.value,
         tradeId         |-> tradeId.value,
         quantity        |-> quantity.value,
         price           |-> price.value ], price.rest)

ZeroOrderExecutedMessage ==
    [ timestamp       |-> [i \in 1 .. 8 |-> 0],
      symbol          |-> [i \in 1 .. 8 |-> 0],
      orderCapacity   |-> [i \in 1 .. 1 |-> 0],
      tradeConditions |-> [i \in 1 .. 1 |-> 0],
      orderId         |-> [i \in 1 .. 8 |-> 0],
      tradeId         |-> [i \in 1 .. 8 |-> 0],
      quantity        |-> [i \in 1 .. 4 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeConditions = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Clear Book Message: 16 bytes                                            *)
(***************************************************************************)

ClearBookMessage ==
    [ timestamp : Sample(8),
      symbol    : Sample(8) ]

EncodeClearBookMessage(message) ==
    message.timestamp
        \o message.symbol

DecodeClearBookMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         symbol    |-> symbol.value ], symbol.rest)

ZeroClearBookMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      symbol    |-> [i \in 1 .. 8 |-> 0] ]

(* Clear Book Message at zero, then each field in turn at the values it is checked at *)
CheckedClearBookMessage ==
    { ZeroClearBookMessage }
        \cup { [ZeroClearBookMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroClearBookMessage EXCEPT !.symbol = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

InstrumentDirectoryMessageCode == 1  \* 0x01
OptionsInstrumentStatusMessageCode == 2  \* 0x02
UnderlierInstrumentStatusMessageCode == 3  \* 0x03
BrokenTradeMessageCode == 5  \* 0x05
CorrectedTradeMessageCode == 6  \* 0x06
SnapshotCompleteMessageCode == 7  \* 0x07
OrderAddedShortMessageCode == 10  \* 0x0a
OrderAddedLongMessageCode == 11  \* 0x0b
OrderAddedExtendedMessageCode == 12  \* 0x0c
OrderDeletedMessageCode == 13  \* 0x0d
OrderReducedMessageCode == 14  \* 0x0e
OrderExecutedMessageCode == 15  \* 0x0f
ClearBookMessageCode == 18  \* 0x12

Payload ==
    [ tag : {InstrumentDirectoryMessageCode}, body : InstrumentDirectoryMessage ]
        \cup [ tag : {OptionsInstrumentStatusMessageCode}, body : OptionsInstrumentStatusMessage ]
        \cup [ tag : {UnderlierInstrumentStatusMessageCode}, body : UnderlierInstrumentStatusMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {CorrectedTradeMessageCode}, body : CorrectedTradeMessage ]
        \cup [ tag : {SnapshotCompleteMessageCode}, body : SnapshotCompleteMessage ]
        \cup [ tag : {OrderAddedShortMessageCode}, body : OrderAddedShortMessage ]
        \cup [ tag : {OrderAddedLongMessageCode}, body : OrderAddedLongMessage ]
        \cup [ tag : {OrderAddedExtendedMessageCode}, body : OrderAddedExtendedMessage ]
        \cup [ tag : {OrderDeletedMessageCode}, body : OrderDeletedMessage ]
        \cup [ tag : {OrderReducedMessageCode}, body : OrderReducedMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {ClearBookMessageCode}, body : ClearBookMessage ]

EncodePayload(message) ==
    CASE message.tag = InstrumentDirectoryMessageCode -> EncodeInstrumentDirectoryMessage(message.body)
      [] message.tag = OptionsInstrumentStatusMessageCode -> EncodeOptionsInstrumentStatusMessage(message.body)
      [] message.tag = UnderlierInstrumentStatusMessageCode -> EncodeUnderlierInstrumentStatusMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = CorrectedTradeMessageCode -> EncodeCorrectedTradeMessage(message.body)
      [] message.tag = SnapshotCompleteMessageCode -> EncodeSnapshotCompleteMessage(message.body)
      [] message.tag = OrderAddedShortMessageCode -> EncodeOrderAddedShortMessage(message.body)
      [] message.tag = OrderAddedLongMessageCode -> EncodeOrderAddedLongMessage(message.body)
      [] message.tag = OrderAddedExtendedMessageCode -> EncodeOrderAddedExtendedMessage(message.body)
      [] message.tag = OrderDeletedMessageCode -> EncodeOrderDeletedMessage(message.body)
      [] message.tag = OrderReducedMessageCode -> EncodeOrderReducedMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = ClearBookMessageCode -> EncodeClearBookMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = InstrumentDirectoryMessageCode -> DecodeInstrumentDirectoryMessage(bytes)
              [] tag = OptionsInstrumentStatusMessageCode -> DecodeOptionsInstrumentStatusMessage(bytes)
              [] tag = UnderlierInstrumentStatusMessageCode -> DecodeUnderlierInstrumentStatusMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = CorrectedTradeMessageCode -> DecodeCorrectedTradeMessage(bytes)
              [] tag = SnapshotCompleteMessageCode -> DecodeSnapshotCompleteMessage(bytes)
              [] tag = OrderAddedShortMessageCode -> DecodeOrderAddedShortMessage(bytes)
              [] tag = OrderAddedLongMessageCode -> DecodeOrderAddedLongMessage(bytes)
              [] tag = OrderAddedExtendedMessageCode -> DecodeOrderAddedExtendedMessage(bytes)
              [] tag = OrderDeletedMessageCode -> DecodeOrderDeletedMessage(bytes)
              [] tag = OrderReducedMessageCode -> DecodeOrderReducedMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = ClearBookMessageCode -> DecodeClearBookMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> InstrumentDirectoryMessageCode, body |-> ZeroInstrumentDirectoryMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> InstrumentDirectoryMessageCode, body |-> one] : one \in CheckedInstrumentDirectoryMessage }
        \cup { [tag |-> OptionsInstrumentStatusMessageCode, body |-> one] : one \in CheckedOptionsInstrumentStatusMessage }
        \cup { [tag |-> UnderlierInstrumentStatusMessageCode, body |-> one] : one \in CheckedUnderlierInstrumentStatusMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> CorrectedTradeMessageCode, body |-> one] : one \in CheckedCorrectedTradeMessage }
        \cup { [tag |-> SnapshotCompleteMessageCode, body |-> one] : one \in CheckedSnapshotCompleteMessage }
        \cup { [tag |-> OrderAddedShortMessageCode, body |-> one] : one \in CheckedOrderAddedShortMessage }
        \cup { [tag |-> OrderAddedLongMessageCode, body |-> one] : one \in CheckedOrderAddedLongMessage }
        \cup { [tag |-> OrderAddedExtendedMessageCode, body |-> one] : one \in CheckedOrderAddedExtendedMessage }
        \cup { [tag |-> OrderDeletedMessageCode, body |-> one] : one \in CheckedOrderDeletedMessage }
        \cup { [tag |-> OrderReducedMessageCode, body |-> one] : one \in CheckedOrderReducedMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> ClearBookMessageCode, body |-> one] : one \in CheckedClearBookMessage }

(***************************************************************************)
(* Sbe Message                                                             *)
(***************************************************************************)

SbeMessage ==
    [ blockLength : Sample(2),
      schemaId    : Sample(1),
      version     : Sample(2),
      payload     : Payload ]

EncodeSbeMessage(message) ==
    message.blockLength
        \o EncodeUIntBE(message.payload.tag, 1)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

DecodeSbeMessage(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntBE(blockLength.rest, 1) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 1) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

ZeroSbeMessage ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 1 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
        \cup { [ZeroSbeMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
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

(* Every Options Instrument Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsInstrumentStatusMessage ==
    \A message \in CheckedOptionsInstrumentStatusMessage :
        LET read == DecodeOptionsInstrumentStatusMessage(EncodeOptionsInstrumentStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlier Instrument Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlierInstrumentStatusMessage ==
    \A message \in CheckedUnderlierInstrumentStatusMessage :
        LET read == DecodeUnderlierInstrumentStatusMessage(EncodeUnderlierInstrumentStatusMessage(message))
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

(* Every Snapshot Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotCompleteMessage ==
    \A message \in CheckedSnapshotCompleteMessage :
        LET read == DecodeSnapshotCompleteMessage(EncodeSnapshotCompleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Added Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddedShortMessage ==
    \A message \in CheckedOrderAddedShortMessage :
        LET read == DecodeOrderAddedShortMessage(EncodeOrderAddedShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Added Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddedLongMessage ==
    \A message \in CheckedOrderAddedLongMessage :
        LET read == DecodeOrderAddedLongMessage(EncodeOrderAddedLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Added Extended Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddedExtendedMessage ==
    \A message \in CheckedOrderAddedExtendedMessage :
        LET read == DecodeOrderAddedExtendedMessage(EncodeOrderAddedExtendedMessage(message))
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

(* Every Clear Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClearBookMessage ==
    \A message \in CheckedClearBookMessage :
        LET read == DecodeClearBookMessage(EncodeClearBookMessage(message))
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
