-------------------- MODULE MemxOptions_MemoirTop_v1_3 ---------------------
(***************************************************************************)
(* The Members Exchange Member Order Information Record Top v1.3           *)
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
(* Instrument Trading Status Message: 18 bytes                             *)
(***************************************************************************)

InstrumentTradingStatusMessage ==
    [ timestamp                     : Sample(8),
      symbol                        : Sample(8),
      instrumentTradingStatus       : Sample(1),
      instrumentTradingStatusReason : Sample(1) ]

EncodeInstrumentTradingStatusMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.instrumentTradingStatus
        \o message.instrumentTradingStatusReason

DecodeInstrumentTradingStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(symbol.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET instrumentTradingStatusReason == ReadBytes(instrumentTradingStatus.rest, 1) IN IF ~instrumentTradingStatusReason.ok THEN Fail ELSE
    Ok([ timestamp                     |-> timestamp.value,
         symbol                        |-> symbol.value,
         instrumentTradingStatus       |-> instrumentTradingStatus.value,
         instrumentTradingStatusReason |-> instrumentTradingStatusReason.value ], instrumentTradingStatusReason.rest)

ZeroInstrumentTradingStatusMessage ==
    [ timestamp                     |-> [i \in 1 .. 8 |-> 0],
      symbol                        |-> [i \in 1 .. 8 |-> 0],
      instrumentTradingStatus       |-> [i \in 1 .. 1 |-> 0],
      instrumentTradingStatusReason |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentTradingStatusMessage ==
    { ZeroInstrumentTradingStatusMessage }
        \cup { [ZeroInstrumentTradingStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentTradingStatusMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentTradingStatusMessage EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentTradingStatusMessage EXCEPT !.instrumentTradingStatusReason = one] : one \in Sample(1) }

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
(* Best Bid Offer Message: 48 bytes                                        *)
(***************************************************************************)

BestBidOfferMessage ==
    [ timestamp      : Sample(8),
      symbol         : Sample(8),
      totalBidSize   : Sample(4),
      custBidSize    : Sample(4),
      bidPrice       : Sample(8),
      totalOfferSize : Sample(4),
      custOfferSize  : Sample(4),
      offerPrice     : Sample(8) ]

EncodeBestBidOfferMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.totalBidSize
        \o message.custBidSize
        \o message.bidPrice
        \o message.totalOfferSize
        \o message.custOfferSize
        \o message.offerPrice

DecodeBestBidOfferMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET totalBidSize == ReadBytes(symbol.rest, 4) IN IF ~totalBidSize.ok THEN Fail ELSE
    LET custBidSize == ReadBytes(totalBidSize.rest, 4) IN IF ~custBidSize.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(custBidSize.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET totalOfferSize == ReadBytes(bidPrice.rest, 4) IN IF ~totalOfferSize.ok THEN Fail ELSE
    LET custOfferSize == ReadBytes(totalOfferSize.rest, 4) IN IF ~custOfferSize.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(custOfferSize.rest, 8) IN IF ~offerPrice.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         symbol         |-> symbol.value,
         totalBidSize   |-> totalBidSize.value,
         custBidSize    |-> custBidSize.value,
         bidPrice       |-> bidPrice.value,
         totalOfferSize |-> totalOfferSize.value,
         custOfferSize  |-> custOfferSize.value,
         offerPrice     |-> offerPrice.value ], offerPrice.rest)

ZeroBestBidOfferMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      symbol         |-> [i \in 1 .. 8 |-> 0],
      totalBidSize   |-> [i \in 1 .. 4 |-> 0],
      custBidSize    |-> [i \in 1 .. 4 |-> 0],
      bidPrice       |-> [i \in 1 .. 8 |-> 0],
      totalOfferSize |-> [i \in 1 .. 4 |-> 0],
      custOfferSize  |-> [i \in 1 .. 4 |-> 0],
      offerPrice     |-> [i \in 1 .. 8 |-> 0] ]

(* Best Bid Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedBestBidOfferMessage ==
    { ZeroBestBidOfferMessage }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.totalBidSize = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.custBidSize = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.totalOfferSize = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.custOfferSize = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.offerPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Best Bid Message: 32 bytes                                              *)
(***************************************************************************)

BestBidMessage ==
    [ timestamp    : Sample(8),
      symbol       : Sample(8),
      totalBidSize : Sample(4),
      custBidSize  : Sample(4),
      bidPrice     : Sample(8) ]

EncodeBestBidMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.totalBidSize
        \o message.custBidSize
        \o message.bidPrice

DecodeBestBidMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET totalBidSize == ReadBytes(symbol.rest, 4) IN IF ~totalBidSize.ok THEN Fail ELSE
    LET custBidSize == ReadBytes(totalBidSize.rest, 4) IN IF ~custBidSize.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(custBidSize.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         symbol       |-> symbol.value,
         totalBidSize |-> totalBidSize.value,
         custBidSize  |-> custBidSize.value,
         bidPrice     |-> bidPrice.value ], bidPrice.rest)

ZeroBestBidMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      symbol       |-> [i \in 1 .. 8 |-> 0],
      totalBidSize |-> [i \in 1 .. 4 |-> 0],
      custBidSize  |-> [i \in 1 .. 4 |-> 0],
      bidPrice     |-> [i \in 1 .. 8 |-> 0] ]

(* Best Bid Message at zero, then each field in turn at the values it is checked at *)
CheckedBestBidMessage ==
    { ZeroBestBidMessage }
        \cup { [ZeroBestBidMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestBidMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroBestBidMessage EXCEPT !.totalBidSize = one] : one \in Sample(4) }
        \cup { [ZeroBestBidMessage EXCEPT !.custBidSize = one] : one \in Sample(4) }
        \cup { [ZeroBestBidMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Best Offer Message: 32 bytes                                            *)
(***************************************************************************)

BestOfferMessage ==
    [ timestamp      : Sample(8),
      symbol         : Sample(8),
      totalOfferSize : Sample(4),
      custOfferSize  : Sample(4),
      offerPrice     : Sample(8) ]

EncodeBestOfferMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.totalOfferSize
        \o message.custOfferSize
        \o message.offerPrice

DecodeBestOfferMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET totalOfferSize == ReadBytes(symbol.rest, 4) IN IF ~totalOfferSize.ok THEN Fail ELSE
    LET custOfferSize == ReadBytes(totalOfferSize.rest, 4) IN IF ~custOfferSize.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(custOfferSize.rest, 8) IN IF ~offerPrice.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         symbol         |-> symbol.value,
         totalOfferSize |-> totalOfferSize.value,
         custOfferSize  |-> custOfferSize.value,
         offerPrice     |-> offerPrice.value ], offerPrice.rest)

ZeroBestOfferMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      symbol         |-> [i \in 1 .. 8 |-> 0],
      totalOfferSize |-> [i \in 1 .. 4 |-> 0],
      custOfferSize  |-> [i \in 1 .. 4 |-> 0],
      offerPrice     |-> [i \in 1 .. 8 |-> 0] ]

(* Best Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedBestOfferMessage ==
    { ZeroBestOfferMessage }
        \cup { [ZeroBestOfferMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestOfferMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroBestOfferMessage EXCEPT !.totalOfferSize = one] : one \in Sample(4) }
        \cup { [ZeroBestOfferMessage EXCEPT !.custOfferSize = one] : one \in Sample(4) }
        \cup { [ZeroBestOfferMessage EXCEPT !.offerPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Best Bid Short Message: 22 bytes                                        *)
(***************************************************************************)

BestBidShortMessage ==
    [ timestamp         : Sample(8),
      symbol            : Sample(8),
      totalBidSizeShort : Sample(2),
      custBidSizeShort  : Sample(2),
      bidPriceShort     : Sample(2) ]

EncodeBestBidShortMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.totalBidSizeShort
        \o message.custBidSizeShort
        \o message.bidPriceShort

DecodeBestBidShortMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET totalBidSizeShort == ReadBytes(symbol.rest, 2) IN IF ~totalBidSizeShort.ok THEN Fail ELSE
    LET custBidSizeShort == ReadBytes(totalBidSizeShort.rest, 2) IN IF ~custBidSizeShort.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(custBidSizeShort.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         symbol            |-> symbol.value,
         totalBidSizeShort |-> totalBidSizeShort.value,
         custBidSizeShort  |-> custBidSizeShort.value,
         bidPriceShort     |-> bidPriceShort.value ], bidPriceShort.rest)

ZeroBestBidShortMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      symbol            |-> [i \in 1 .. 8 |-> 0],
      totalBidSizeShort |-> [i \in 1 .. 2 |-> 0],
      custBidSizeShort  |-> [i \in 1 .. 2 |-> 0],
      bidPriceShort     |-> [i \in 1 .. 2 |-> 0] ]

(* Best Bid Short Message at zero, then each field in turn at the values it is checked at *)
CheckedBestBidShortMessage ==
    { ZeroBestBidShortMessage }
        \cup { [ZeroBestBidShortMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestBidShortMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroBestBidShortMessage EXCEPT !.totalBidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidShortMessage EXCEPT !.custBidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidShortMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Best Offer Short Message: 22 bytes                                      *)
(***************************************************************************)

BestOfferShortMessage ==
    [ timestamp           : Sample(8),
      symbol              : Sample(8),
      totalOfferSizeShort : Sample(2),
      custOfferSizeShort  : Sample(2),
      offerPriceShort     : Sample(2) ]

EncodeBestOfferShortMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.totalOfferSizeShort
        \o message.custOfferSizeShort
        \o message.offerPriceShort

DecodeBestOfferShortMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET totalOfferSizeShort == ReadBytes(symbol.rest, 2) IN IF ~totalOfferSizeShort.ok THEN Fail ELSE
    LET custOfferSizeShort == ReadBytes(totalOfferSizeShort.rest, 2) IN IF ~custOfferSizeShort.ok THEN Fail ELSE
    LET offerPriceShort == ReadBytes(custOfferSizeShort.rest, 2) IN IF ~offerPriceShort.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         symbol              |-> symbol.value,
         totalOfferSizeShort |-> totalOfferSizeShort.value,
         custOfferSizeShort  |-> custOfferSizeShort.value,
         offerPriceShort     |-> offerPriceShort.value ], offerPriceShort.rest)

ZeroBestOfferShortMessage ==
    [ timestamp           |-> [i \in 1 .. 8 |-> 0],
      symbol              |-> [i \in 1 .. 8 |-> 0],
      totalOfferSizeShort |-> [i \in 1 .. 2 |-> 0],
      custOfferSizeShort  |-> [i \in 1 .. 2 |-> 0],
      offerPriceShort     |-> [i \in 1 .. 2 |-> 0] ]

(* Best Offer Short Message at zero, then each field in turn at the values it is checked at *)
CheckedBestOfferShortMessage ==
    { ZeroBestOfferShortMessage }
        \cup { [ZeroBestOfferShortMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestOfferShortMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroBestOfferShortMessage EXCEPT !.totalOfferSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestOfferShortMessage EXCEPT !.custOfferSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestOfferShortMessage EXCEPT !.offerPriceShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Message: 43 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ timestamp       : Sample(8),
      symbol          : Sample(8),
      tradeId         : Sample(8),
      tradeConditions : Sample(1),
      side            : Sample(1),
      quantity        : Sample(4),
      price           : Sample(8),
      custQuantity    : Sample(4),
      capacity        : Sample(1) ]

EncodeTradeMessage(message) ==
    message.timestamp
        \o message.symbol
        \o message.tradeId
        \o message.tradeConditions
        \o message.side
        \o message.quantity
        \o message.price
        \o message.custQuantity
        \o message.capacity

DecodeTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 8) IN IF ~symbol.ok THEN Fail ELSE
    LET tradeId == ReadBytes(symbol.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET tradeConditions == ReadBytes(tradeId.rest, 1) IN IF ~tradeConditions.ok THEN Fail ELSE
    LET side == ReadBytes(tradeConditions.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET custQuantity == ReadBytes(price.rest, 4) IN IF ~custQuantity.ok THEN Fail ELSE
    LET capacity == ReadBytes(custQuantity.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         symbol          |-> symbol.value,
         tradeId         |-> tradeId.value,
         tradeConditions |-> tradeConditions.value,
         side            |-> side.value,
         quantity        |-> quantity.value,
         price           |-> price.value,
         custQuantity    |-> custQuantity.value,
         capacity        |-> capacity.value ], capacity.rest)

ZeroTradeMessage ==
    [ timestamp       |-> [i \in 1 .. 8 |-> 0],
      symbol          |-> [i \in 1 .. 8 |-> 0],
      tradeId         |-> [i \in 1 .. 8 |-> 0],
      tradeConditions |-> [i \in 1 .. 1 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      quantity        |-> [i \in 1 .. 4 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0],
      custQuantity    |-> [i \in 1 .. 4 |-> 0],
      capacity        |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.symbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeConditions = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.custQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.capacity = one] : one \in Sample(1) }

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
InstrumentTradingStatusMessageCode == 2  \* 0x02
TradingSessionStatusMessageCode == 3  \* 0x03
BrokenTradeMessageCode == 5  \* 0x05
CorrectedTradeMessageCode == 6  \* 0x06
SnapshotCompleteMessageCode == 7  \* 0x07
BestBidOfferMessageCode == 10  \* 0x0a
BestBidMessageCode == 11  \* 0x0b
BestOfferMessageCode == 12  \* 0x0c
BestBidShortMessageCode == 13  \* 0x0d
BestOfferShortMessageCode == 14  \* 0x0e
TradeMessageCode == 15  \* 0x0f
ClearBookMessageCode == 16  \* 0x10

Payload ==
    [ tag : {InstrumentDirectoryMessageCode}, body : InstrumentDirectoryMessage ]
        \cup [ tag : {InstrumentTradingStatusMessageCode}, body : InstrumentTradingStatusMessage ]
        \cup [ tag : {TradingSessionStatusMessageCode}, body : TradingSessionStatusMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {CorrectedTradeMessageCode}, body : CorrectedTradeMessage ]
        \cup [ tag : {SnapshotCompleteMessageCode}, body : SnapshotCompleteMessage ]
        \cup [ tag : {BestBidOfferMessageCode}, body : BestBidOfferMessage ]
        \cup [ tag : {BestBidMessageCode}, body : BestBidMessage ]
        \cup [ tag : {BestOfferMessageCode}, body : BestOfferMessage ]
        \cup [ tag : {BestBidShortMessageCode}, body : BestBidShortMessage ]
        \cup [ tag : {BestOfferShortMessageCode}, body : BestOfferShortMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {ClearBookMessageCode}, body : ClearBookMessage ]

EncodePayload(message) ==
    CASE message.tag = InstrumentDirectoryMessageCode -> EncodeInstrumentDirectoryMessage(message.body)
      [] message.tag = InstrumentTradingStatusMessageCode -> EncodeInstrumentTradingStatusMessage(message.body)
      [] message.tag = TradingSessionStatusMessageCode -> EncodeTradingSessionStatusMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = CorrectedTradeMessageCode -> EncodeCorrectedTradeMessage(message.body)
      [] message.tag = SnapshotCompleteMessageCode -> EncodeSnapshotCompleteMessage(message.body)
      [] message.tag = BestBidOfferMessageCode -> EncodeBestBidOfferMessage(message.body)
      [] message.tag = BestBidMessageCode -> EncodeBestBidMessage(message.body)
      [] message.tag = BestOfferMessageCode -> EncodeBestOfferMessage(message.body)
      [] message.tag = BestBidShortMessageCode -> EncodeBestBidShortMessage(message.body)
      [] message.tag = BestOfferShortMessageCode -> EncodeBestOfferShortMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = ClearBookMessageCode -> EncodeClearBookMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = InstrumentDirectoryMessageCode -> DecodeInstrumentDirectoryMessage(bytes)
              [] tag = InstrumentTradingStatusMessageCode -> DecodeInstrumentTradingStatusMessage(bytes)
              [] tag = TradingSessionStatusMessageCode -> DecodeTradingSessionStatusMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = CorrectedTradeMessageCode -> DecodeCorrectedTradeMessage(bytes)
              [] tag = SnapshotCompleteMessageCode -> DecodeSnapshotCompleteMessage(bytes)
              [] tag = BestBidOfferMessageCode -> DecodeBestBidOfferMessage(bytes)
              [] tag = BestBidMessageCode -> DecodeBestBidMessage(bytes)
              [] tag = BestOfferMessageCode -> DecodeBestOfferMessage(bytes)
              [] tag = BestBidShortMessageCode -> DecodeBestBidShortMessage(bytes)
              [] tag = BestOfferShortMessageCode -> DecodeBestOfferShortMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = ClearBookMessageCode -> DecodeClearBookMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> InstrumentDirectoryMessageCode, body |-> ZeroInstrumentDirectoryMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> InstrumentDirectoryMessageCode, body |-> one] : one \in CheckedInstrumentDirectoryMessage }
        \cup { [tag |-> InstrumentTradingStatusMessageCode, body |-> one] : one \in CheckedInstrumentTradingStatusMessage }
        \cup { [tag |-> TradingSessionStatusMessageCode, body |-> one] : one \in CheckedTradingSessionStatusMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> CorrectedTradeMessageCode, body |-> one] : one \in CheckedCorrectedTradeMessage }
        \cup { [tag |-> SnapshotCompleteMessageCode, body |-> one] : one \in CheckedSnapshotCompleteMessage }
        \cup { [tag |-> BestBidOfferMessageCode, body |-> one] : one \in CheckedBestBidOfferMessage }
        \cup { [tag |-> BestBidMessageCode, body |-> one] : one \in CheckedBestBidMessage }
        \cup { [tag |-> BestOfferMessageCode, body |-> one] : one \in CheckedBestOfferMessage }
        \cup { [tag |-> BestBidShortMessageCode, body |-> one] : one \in CheckedBestBidShortMessage }
        \cup { [tag |-> BestOfferShortMessageCode, body |-> one] : one \in CheckedBestOfferShortMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
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

(* Every Instrument Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentTradingStatusMessage ==
    \A message \in CheckedInstrumentTradingStatusMessage :
        LET read == DecodeInstrumentTradingStatusMessage(EncodeInstrumentTradingStatusMessage(message))
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

(* Every Best Bid Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestBidOfferMessage ==
    \A message \in CheckedBestBidOfferMessage :
        LET read == DecodeBestBidOfferMessage(EncodeBestBidOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Bid Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestBidMessage ==
    \A message \in CheckedBestBidMessage :
        LET read == DecodeBestBidMessage(EncodeBestBidMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestOfferMessage ==
    \A message \in CheckedBestOfferMessage :
        LET read == DecodeBestOfferMessage(EncodeBestOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Bid Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestBidShortMessage ==
    \A message \in CheckedBestBidShortMessage :
        LET read == DecodeBestBidShortMessage(EncodeBestBidShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Best Offer Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBestOfferShortMessage ==
    \A message \in CheckedBestOfferShortMessage :
        LET read == DecodeBestOfferShortMessage(EncodeBestOfferShortMessage(message))
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
