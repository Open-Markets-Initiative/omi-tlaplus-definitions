----------------- MODULE LtseEquities_MemoirTopOfBook_v2_0 -----------------
(***************************************************************************)
(* Long-Term Stock Exchange Member Order Information Record Top Of Book    *)
(* v2.0                                                                    *)
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
(* Note: Bid Flags is a bit field set, checked as its 1 byte rather than   *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Offer Flags is a bit field set, checked as its 1 byte rather than *)
(* bit by bit.                                                             *)
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
(* Instrument Directory Message: 27 bytes                                  *)
(***************************************************************************)

InstrumentDirectoryMessage ==
    [ timestamp    : Sample(8),
      securityId   : Sample(2),
      symbol       : Sample(6),
      symbolSfx    : Sample(6),
      roundLot     : Sample(4),
      isTestSymbol : Sample(1) ]

EncodeInstrumentDirectoryMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.symbol
        \o message.symbolSfx
        \o message.roundLot
        \o message.isTestSymbol

DecodeInstrumentDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET symbol == ReadBytes(securityId.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolSfx == ReadBytes(symbol.rest, 6) IN IF ~symbolSfx.ok THEN Fail ELSE
    LET roundLot == ReadBytes(symbolSfx.rest, 4) IN IF ~roundLot.ok THEN Fail ELSE
    LET isTestSymbol == ReadBytes(roundLot.rest, 1) IN IF ~isTestSymbol.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         securityId   |-> securityId.value,
         symbol       |-> symbol.value,
         symbolSfx    |-> symbolSfx.value,
         roundLot     |-> roundLot.value,
         isTestSymbol |-> isTestSymbol.value ], isTestSymbol.rest)

ZeroInstrumentDirectoryMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      securityId   |-> [i \in 1 .. 2 |-> 0],
      symbol       |-> [i \in 1 .. 6 |-> 0],
      symbolSfx    |-> [i \in 1 .. 6 |-> 0],
      roundLot     |-> [i \in 1 .. 4 |-> 0],
      isTestSymbol |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDirectoryMessage ==
    { ZeroInstrumentDirectoryMessage }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.symbolSfx = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.roundLot = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDirectoryMessage EXCEPT !.isTestSymbol = one] : one \in Sample(1) }

(***************************************************************************)
(* Reg Sho Restriction Message: 11 bytes                                   *)
(***************************************************************************)

RegShoRestrictionMessage ==
    [ timestamp            : Sample(8),
      securityId           : Sample(2),
      shortSaleRestriction : Sample(1) ]

EncodeRegShoRestrictionMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.shortSaleRestriction

DecodeRegShoRestrictionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET shortSaleRestriction == ReadBytes(securityId.rest, 1) IN IF ~shortSaleRestriction.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         securityId           |-> securityId.value,
         shortSaleRestriction |-> shortSaleRestriction.value ], shortSaleRestriction.rest)

ZeroRegShoRestrictionMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      securityId           |-> [i \in 1 .. 2 |-> 0],
      shortSaleRestriction |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Restriction Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoRestrictionMessage ==
    { ZeroRegShoRestrictionMessage }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroRegShoRestrictionMessage EXCEPT !.shortSaleRestriction = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Trading Status Message: 13 bytes                               *)
(***************************************************************************)

SecurityTradingStatusMessage ==
    [ timestamp                   : Sample(8),
      securityId                  : Sample(2),
      securityTradingStatus       : Sample(1),
      securityTradingStatusReason : Sample(1),
      haltReason                  : Sample(1) ]

EncodeSecurityTradingStatusMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.securityTradingStatus
        \o message.securityTradingStatusReason
        \o message.haltReason

DecodeSecurityTradingStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityId.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET securityTradingStatusReason == ReadBytes(securityTradingStatus.rest, 1) IN IF ~securityTradingStatusReason.ok THEN Fail ELSE
    LET haltReason == ReadBytes(securityTradingStatusReason.rest, 1) IN IF ~haltReason.ok THEN Fail ELSE
    Ok([ timestamp                   |-> timestamp.value,
         securityId                  |-> securityId.value,
         securityTradingStatus       |-> securityTradingStatus.value,
         securityTradingStatusReason |-> securityTradingStatusReason.value,
         haltReason                  |-> haltReason.value ], haltReason.rest)

ZeroSecurityTradingStatusMessage ==
    [ timestamp                   |-> [i \in 1 .. 8 |-> 0],
      securityId                  |-> [i \in 1 .. 2 |-> 0],
      securityTradingStatus       |-> [i \in 1 .. 1 |-> 0],
      securityTradingStatusReason |-> [i \in 1 .. 1 |-> 0],
      haltReason                  |-> [i \in 1 .. 1 |-> 0] ]

(* Security Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityTradingStatusMessage ==
    { ZeroSecurityTradingStatusMessage }
        \cup { [ZeroSecurityTradingStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSecurityTradingStatusMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroSecurityTradingStatusMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityTradingStatusMessage EXCEPT !.securityTradingStatusReason = one] : one \in Sample(1) }
        \cup { [ZeroSecurityTradingStatusMessage EXCEPT !.haltReason = one] : one \in Sample(1) }

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
(* Best Bid Offer Message: 36 bytes                                        *)
(***************************************************************************)

BestBidOfferMessage ==
    [ timestamp  : Sample(8),
      securityId : Sample(2),
      bidSize    : Sample(4),
      bidPrice   : Sample(8),
      offerSize  : Sample(4),
      offerPrice : Sample(8),
      bidFlags   : Sample(1),
      offerFlags : Sample(1) ]

EncodeBestBidOfferMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.bidSize
        \o message.bidPrice
        \o message.offerSize
        \o message.offerPrice
        \o message.bidFlags
        \o message.offerFlags

DecodeBestBidOfferMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET bidSize == ReadBytes(securityId.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(bidSize.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidPrice.rest, 4) IN IF ~offerSize.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(offerSize.rest, 8) IN IF ~offerPrice.ok THEN Fail ELSE
    LET bidFlags == ReadBytes(offerPrice.rest, 1) IN IF ~bidFlags.ok THEN Fail ELSE
    LET offerFlags == ReadBytes(bidFlags.rest, 1) IN IF ~offerFlags.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         securityId |-> securityId.value,
         bidSize    |-> bidSize.value,
         bidPrice   |-> bidPrice.value,
         offerSize  |-> offerSize.value,
         offerPrice |-> offerPrice.value,
         bidFlags   |-> bidFlags.value,
         offerFlags |-> offerFlags.value ], offerFlags.rest)

ZeroBestBidOfferMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      securityId |-> [i \in 1 .. 2 |-> 0],
      bidSize    |-> [i \in 1 .. 4 |-> 0],
      bidPrice   |-> [i \in 1 .. 8 |-> 0],
      offerSize  |-> [i \in 1 .. 4 |-> 0],
      offerPrice |-> [i \in 1 .. 8 |-> 0],
      bidFlags   |-> [i \in 1 .. 1 |-> 0],
      offerFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Best Bid Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedBestBidOfferMessage ==
    { ZeroBestBidOfferMessage }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.offerSize = one] : one \in Sample(4) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.offerPrice = one] : one \in Sample(8) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.bidFlags = one] : one \in Sample(1) }
        \cup { [ZeroBestBidOfferMessage EXCEPT !.offerFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Best Bid Message: 23 bytes                                              *)
(***************************************************************************)

BestBidMessage ==
    [ timestamp  : Sample(8),
      securityId : Sample(2),
      bidSize    : Sample(4),
      bidPrice   : Sample(8),
      bidFlags   : Sample(1) ]

EncodeBestBidMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.bidSize
        \o message.bidPrice
        \o message.bidFlags

DecodeBestBidMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET bidSize == ReadBytes(securityId.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(bidSize.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidFlags == ReadBytes(bidPrice.rest, 1) IN IF ~bidFlags.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         securityId |-> securityId.value,
         bidSize    |-> bidSize.value,
         bidPrice   |-> bidPrice.value,
         bidFlags   |-> bidFlags.value ], bidFlags.rest)

ZeroBestBidMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      securityId |-> [i \in 1 .. 2 |-> 0],
      bidSize    |-> [i \in 1 .. 4 |-> 0],
      bidPrice   |-> [i \in 1 .. 8 |-> 0],
      bidFlags   |-> [i \in 1 .. 1 |-> 0] ]

(* Best Bid Message at zero, then each field in turn at the values it is checked at *)
CheckedBestBidMessage ==
    { ZeroBestBidMessage }
        \cup { [ZeroBestBidMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestBidMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroBestBidMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroBestBidMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroBestBidMessage EXCEPT !.bidFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Best Offer Message: 23 bytes                                            *)
(***************************************************************************)

BestOfferMessage ==
    [ timestamp  : Sample(8),
      securityId : Sample(2),
      offerSize  : Sample(4),
      offerPrice : Sample(8),
      offerFlags : Sample(1) ]

EncodeBestOfferMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.offerSize
        \o message.offerPrice
        \o message.offerFlags

DecodeBestOfferMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET offerSize == ReadBytes(securityId.rest, 4) IN IF ~offerSize.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(offerSize.rest, 8) IN IF ~offerPrice.ok THEN Fail ELSE
    LET offerFlags == ReadBytes(offerPrice.rest, 1) IN IF ~offerFlags.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         securityId |-> securityId.value,
         offerSize  |-> offerSize.value,
         offerPrice |-> offerPrice.value,
         offerFlags |-> offerFlags.value ], offerFlags.rest)

ZeroBestOfferMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      securityId |-> [i \in 1 .. 2 |-> 0],
      offerSize  |-> [i \in 1 .. 4 |-> 0],
      offerPrice |-> [i \in 1 .. 8 |-> 0],
      offerFlags |-> [i \in 1 .. 1 |-> 0] ]

(* Best Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedBestOfferMessage ==
    { ZeroBestOfferMessage }
        \cup { [ZeroBestOfferMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestOfferMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroBestOfferMessage EXCEPT !.offerSize = one] : one \in Sample(4) }
        \cup { [ZeroBestOfferMessage EXCEPT !.offerPrice = one] : one \in Sample(8) }
        \cup { [ZeroBestOfferMessage EXCEPT !.offerFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Best Bid Short Message: 15 bytes                                        *)
(***************************************************************************)

BestBidShortMessage ==
    [ timestamp     : Sample(8),
      securityId    : Sample(2),
      bidSizeShort  : Sample(2),
      bidPriceShort : Sample(2),
      bidFlags      : Sample(1) ]

EncodeBestBidShortMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.bidSizeShort
        \o message.bidPriceShort
        \o message.bidFlags

DecodeBestBidShortMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(securityId.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidFlags == ReadBytes(bidPriceShort.rest, 1) IN IF ~bidFlags.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         securityId    |-> securityId.value,
         bidSizeShort  |-> bidSizeShort.value,
         bidPriceShort |-> bidPriceShort.value,
         bidFlags      |-> bidFlags.value ], bidFlags.rest)

ZeroBestBidShortMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      securityId    |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort  |-> [i \in 1 .. 2 |-> 0],
      bidPriceShort |-> [i \in 1 .. 2 |-> 0],
      bidFlags      |-> [i \in 1 .. 1 |-> 0] ]

(* Best Bid Short Message at zero, then each field in turn at the values it is checked at *)
CheckedBestBidShortMessage ==
    { ZeroBestBidShortMessage }
        \cup { [ZeroBestBidShortMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestBidShortMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroBestBidShortMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidShortMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroBestBidShortMessage EXCEPT !.bidFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Best Offer Short Message: 15 bytes                                      *)
(***************************************************************************)

BestOfferShortMessage ==
    [ timestamp       : Sample(8),
      securityId      : Sample(2),
      offerSizeShort  : Sample(2),
      offerPriceShort : Sample(2),
      offerFlags      : Sample(1) ]

EncodeBestOfferShortMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.offerSizeShort
        \o message.offerPriceShort
        \o message.offerFlags

DecodeBestOfferShortMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET offerSizeShort == ReadBytes(securityId.rest, 2) IN IF ~offerSizeShort.ok THEN Fail ELSE
    LET offerPriceShort == ReadBytes(offerSizeShort.rest, 2) IN IF ~offerPriceShort.ok THEN Fail ELSE
    LET offerFlags == ReadBytes(offerPriceShort.rest, 1) IN IF ~offerFlags.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         securityId      |-> securityId.value,
         offerSizeShort  |-> offerSizeShort.value,
         offerPriceShort |-> offerPriceShort.value,
         offerFlags      |-> offerFlags.value ], offerFlags.rest)

ZeroBestOfferShortMessage ==
    [ timestamp       |-> [i \in 1 .. 8 |-> 0],
      securityId      |-> [i \in 1 .. 2 |-> 0],
      offerSizeShort  |-> [i \in 1 .. 2 |-> 0],
      offerPriceShort |-> [i \in 1 .. 2 |-> 0],
      offerFlags      |-> [i \in 1 .. 1 |-> 0] ]

(* Best Offer Short Message at zero, then each field in turn at the values it is checked at *)
CheckedBestOfferShortMessage ==
    { ZeroBestOfferShortMessage }
        \cup { [ZeroBestOfferShortMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBestOfferShortMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroBestOfferShortMessage EXCEPT !.offerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroBestOfferShortMessage EXCEPT !.offerPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroBestOfferShortMessage EXCEPT !.offerFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Clear Book Message: 10 bytes                                            *)
(***************************************************************************)

ClearBookMessage ==
    [ timestamp  : Sample(8),
      securityId : Sample(2) ]

EncodeClearBookMessage(message) ==
    message.timestamp
        \o message.securityId

DecodeClearBookMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         securityId |-> securityId.value ], securityId.rest)

ZeroClearBookMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      securityId |-> [i \in 1 .. 2 |-> 0] ]

(* Clear Book Message at zero, then each field in turn at the values it is checked at *)
CheckedClearBookMessage ==
    { ZeroClearBookMessage }
        \cup { [ZeroClearBookMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroClearBookMessage EXCEPT !.securityId = one] : one \in Sample(2) }

(***************************************************************************)
(* Auction Trade Message: 47 bytes                                         *)
(***************************************************************************)

AuctionTradeMessage ==
    [ timestamp       : Sample(8),
      securityId      : Sample(2),
      auctionId       : Sample(8),
      auctionType     : Sample(1),
      auctionQuantity : Sample(8),
      auctionPrice    : Sample(8),
      tradeId         : Sample(8),
      saleCondition1  : Sample(1),
      saleCondition2  : Sample(1),
      saleCondition3  : Sample(1),
      saleCondition4  : Sample(1) ]

EncodeAuctionTradeMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.auctionId
        \o message.auctionType
        \o message.auctionQuantity
        \o message.auctionPrice
        \o message.tradeId
        \o message.saleCondition1
        \o message.saleCondition2
        \o message.saleCondition3
        \o message.saleCondition4

DecodeAuctionTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(securityId.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionQuantity == ReadBytes(auctionType.rest, 8) IN IF ~auctionQuantity.ok THEN Fail ELSE
    LET auctionPrice == ReadBytes(auctionQuantity.rest, 8) IN IF ~auctionPrice.ok THEN Fail ELSE
    LET tradeId == ReadBytes(auctionPrice.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET saleCondition1 == ReadBytes(tradeId.rest, 1) IN IF ~saleCondition1.ok THEN Fail ELSE
    LET saleCondition2 == ReadBytes(saleCondition1.rest, 1) IN IF ~saleCondition2.ok THEN Fail ELSE
    LET saleCondition3 == ReadBytes(saleCondition2.rest, 1) IN IF ~saleCondition3.ok THEN Fail ELSE
    LET saleCondition4 == ReadBytes(saleCondition3.rest, 1) IN IF ~saleCondition4.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         securityId      |-> securityId.value,
         auctionId       |-> auctionId.value,
         auctionType     |-> auctionType.value,
         auctionQuantity |-> auctionQuantity.value,
         auctionPrice    |-> auctionPrice.value,
         tradeId         |-> tradeId.value,
         saleCondition1  |-> saleCondition1.value,
         saleCondition2  |-> saleCondition2.value,
         saleCondition3  |-> saleCondition3.value,
         saleCondition4  |-> saleCondition4.value ], saleCondition4.rest)

ZeroAuctionTradeMessage ==
    [ timestamp       |-> [i \in 1 .. 8 |-> 0],
      securityId      |-> [i \in 1 .. 2 |-> 0],
      auctionId       |-> [i \in 1 .. 8 |-> 0],
      auctionType     |-> [i \in 1 .. 1 |-> 0],
      auctionQuantity |-> [i \in 1 .. 8 |-> 0],
      auctionPrice    |-> [i \in 1 .. 8 |-> 0],
      tradeId         |-> [i \in 1 .. 8 |-> 0],
      saleCondition1  |-> [i \in 1 .. 1 |-> 0],
      saleCondition2  |-> [i \in 1 .. 1 |-> 0],
      saleCondition3  |-> [i \in 1 .. 1 |-> 0],
      saleCondition4  |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionTradeMessage ==
    { ZeroAuctionTradeMessage }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.auctionQuantity = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.auctionPrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.saleCondition1 = one] : one \in Sample(1) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.saleCondition2 = one] : one \in Sample(1) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.saleCondition3 = one] : one \in Sample(1) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.saleCondition4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Broken Auction Trade Message: 42 bytes                                  *)
(***************************************************************************)

BrokenAuctionTradeMessage ==
    [ timestamp               : Sample(8),
      securityId              : Sample(2),
      auctionId               : Sample(8),
      tradeId                 : Sample(8),
      originalAuctionQuantity : Sample(8),
      originalAuctionPrice    : Sample(8) ]

EncodeBrokenAuctionTradeMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.auctionId
        \o message.tradeId
        \o message.originalAuctionQuantity
        \o message.originalAuctionPrice

DecodeBrokenAuctionTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(securityId.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(auctionId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET originalAuctionQuantity == ReadBytes(tradeId.rest, 8) IN IF ~originalAuctionQuantity.ok THEN Fail ELSE
    LET originalAuctionPrice == ReadBytes(originalAuctionQuantity.rest, 8) IN IF ~originalAuctionPrice.ok THEN Fail ELSE
    Ok([ timestamp               |-> timestamp.value,
         securityId              |-> securityId.value,
         auctionId               |-> auctionId.value,
         tradeId                 |-> tradeId.value,
         originalAuctionQuantity |-> originalAuctionQuantity.value,
         originalAuctionPrice    |-> originalAuctionPrice.value ], originalAuctionPrice.rest)

ZeroBrokenAuctionTradeMessage ==
    [ timestamp               |-> [i \in 1 .. 8 |-> 0],
      securityId              |-> [i \in 1 .. 2 |-> 0],
      auctionId               |-> [i \in 1 .. 8 |-> 0],
      tradeId                 |-> [i \in 1 .. 8 |-> 0],
      originalAuctionQuantity |-> [i \in 1 .. 8 |-> 0],
      originalAuctionPrice    |-> [i \in 1 .. 8 |-> 0] ]

(* Broken Auction Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenAuctionTradeMessage ==
    { ZeroBrokenAuctionTradeMessage }
        \cup { [ZeroBrokenAuctionTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBrokenAuctionTradeMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroBrokenAuctionTradeMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroBrokenAuctionTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroBrokenAuctionTradeMessage EXCEPT !.originalAuctionQuantity = one] : one \in Sample(8) }
        \cup { [ZeroBrokenAuctionTradeMessage EXCEPT !.originalAuctionPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Corrected Auction Trade Message: 66 bytes                               *)
(***************************************************************************)

CorrectedAuctionTradeMessage ==
    [ timestamp                : Sample(8),
      securityId               : Sample(2),
      auctionId                : Sample(8),
      tradeId                  : Sample(8),
      originalAuctionQuantity  : Sample(8),
      originalAuctionPrice     : Sample(8),
      originalSaleCondition1   : Sample(1),
      originalSaleCondition2   : Sample(1),
      originalSaleCondition3   : Sample(1),
      originalSaleCondition4   : Sample(1),
      correctedAuctionQuantity : Sample(8),
      correctedAuctionPrice    : Sample(8),
      correctedSaleCondition1  : Sample(1),
      correctedSaleCondition2  : Sample(1),
      correctedSaleCondition3  : Sample(1),
      correctedSaleCondition4  : Sample(1) ]

EncodeCorrectedAuctionTradeMessage(message) ==
    message.timestamp
        \o message.securityId
        \o message.auctionId
        \o message.tradeId
        \o message.originalAuctionQuantity
        \o message.originalAuctionPrice
        \o message.originalSaleCondition1
        \o message.originalSaleCondition2
        \o message.originalSaleCondition3
        \o message.originalSaleCondition4
        \o message.correctedAuctionQuantity
        \o message.correctedAuctionPrice
        \o message.correctedSaleCondition1
        \o message.correctedSaleCondition2
        \o message.correctedSaleCondition3
        \o message.correctedSaleCondition4

DecodeCorrectedAuctionTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET securityId == ReadBytes(timestamp.rest, 2) IN IF ~securityId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(securityId.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(auctionId.rest, 8) IN IF ~tradeId.ok THEN Fail ELSE
    LET originalAuctionQuantity == ReadBytes(tradeId.rest, 8) IN IF ~originalAuctionQuantity.ok THEN Fail ELSE
    LET originalAuctionPrice == ReadBytes(originalAuctionQuantity.rest, 8) IN IF ~originalAuctionPrice.ok THEN Fail ELSE
    LET originalSaleCondition1 == ReadBytes(originalAuctionPrice.rest, 1) IN IF ~originalSaleCondition1.ok THEN Fail ELSE
    LET originalSaleCondition2 == ReadBytes(originalSaleCondition1.rest, 1) IN IF ~originalSaleCondition2.ok THEN Fail ELSE
    LET originalSaleCondition3 == ReadBytes(originalSaleCondition2.rest, 1) IN IF ~originalSaleCondition3.ok THEN Fail ELSE
    LET originalSaleCondition4 == ReadBytes(originalSaleCondition3.rest, 1) IN IF ~originalSaleCondition4.ok THEN Fail ELSE
    LET correctedAuctionQuantity == ReadBytes(originalSaleCondition4.rest, 8) IN IF ~correctedAuctionQuantity.ok THEN Fail ELSE
    LET correctedAuctionPrice == ReadBytes(correctedAuctionQuantity.rest, 8) IN IF ~correctedAuctionPrice.ok THEN Fail ELSE
    LET correctedSaleCondition1 == ReadBytes(correctedAuctionPrice.rest, 1) IN IF ~correctedSaleCondition1.ok THEN Fail ELSE
    LET correctedSaleCondition2 == ReadBytes(correctedSaleCondition1.rest, 1) IN IF ~correctedSaleCondition2.ok THEN Fail ELSE
    LET correctedSaleCondition3 == ReadBytes(correctedSaleCondition2.rest, 1) IN IF ~correctedSaleCondition3.ok THEN Fail ELSE
    LET correctedSaleCondition4 == ReadBytes(correctedSaleCondition3.rest, 1) IN IF ~correctedSaleCondition4.ok THEN Fail ELSE
    Ok([ timestamp                |-> timestamp.value,
         securityId               |-> securityId.value,
         auctionId                |-> auctionId.value,
         tradeId                  |-> tradeId.value,
         originalAuctionQuantity  |-> originalAuctionQuantity.value,
         originalAuctionPrice     |-> originalAuctionPrice.value,
         originalSaleCondition1   |-> originalSaleCondition1.value,
         originalSaleCondition2   |-> originalSaleCondition2.value,
         originalSaleCondition3   |-> originalSaleCondition3.value,
         originalSaleCondition4   |-> originalSaleCondition4.value,
         correctedAuctionQuantity |-> correctedAuctionQuantity.value,
         correctedAuctionPrice    |-> correctedAuctionPrice.value,
         correctedSaleCondition1  |-> correctedSaleCondition1.value,
         correctedSaleCondition2  |-> correctedSaleCondition2.value,
         correctedSaleCondition3  |-> correctedSaleCondition3.value,
         correctedSaleCondition4  |-> correctedSaleCondition4.value ], correctedSaleCondition4.rest)

ZeroCorrectedAuctionTradeMessage ==
    [ timestamp                |-> [i \in 1 .. 8 |-> 0],
      securityId               |-> [i \in 1 .. 2 |-> 0],
      auctionId                |-> [i \in 1 .. 8 |-> 0],
      tradeId                  |-> [i \in 1 .. 8 |-> 0],
      originalAuctionQuantity  |-> [i \in 1 .. 8 |-> 0],
      originalAuctionPrice     |-> [i \in 1 .. 8 |-> 0],
      originalSaleCondition1   |-> [i \in 1 .. 1 |-> 0],
      originalSaleCondition2   |-> [i \in 1 .. 1 |-> 0],
      originalSaleCondition3   |-> [i \in 1 .. 1 |-> 0],
      originalSaleCondition4   |-> [i \in 1 .. 1 |-> 0],
      correctedAuctionQuantity |-> [i \in 1 .. 8 |-> 0],
      correctedAuctionPrice    |-> [i \in 1 .. 8 |-> 0],
      correctedSaleCondition1  |-> [i \in 1 .. 1 |-> 0],
      correctedSaleCondition2  |-> [i \in 1 .. 1 |-> 0],
      correctedSaleCondition3  |-> [i \in 1 .. 1 |-> 0],
      correctedSaleCondition4  |-> [i \in 1 .. 1 |-> 0] ]

(* Corrected Auction Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedCorrectedAuctionTradeMessage ==
    { ZeroCorrectedAuctionTradeMessage }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.securityId = one] : one \in Sample(2) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.tradeId = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.originalAuctionQuantity = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.originalAuctionPrice = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.originalSaleCondition1 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.originalSaleCondition2 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.originalSaleCondition3 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.originalSaleCondition4 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.correctedAuctionQuantity = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.correctedAuctionPrice = one] : one \in Sample(8) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.correctedSaleCondition1 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.correctedSaleCondition2 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.correctedSaleCondition3 = one] : one \in Sample(1) }
        \cup { [ZeroCorrectedAuctionTradeMessage EXCEPT !.correctedSaleCondition4 = one] : one \in Sample(1) }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

InstrumentDirectoryMessageCode == 1  \* 0x01
RegShoRestrictionMessageCode == 2  \* 0x02
SecurityTradingStatusMessageCode == 3  \* 0x03
SnapshotCompleteMessageCode == 4  \* 0x04
TradingSessionStatusMessageCode == 5  \* 0x05
BestBidOfferMessageCode == 10  \* 0x0a
BestBidMessageCode == 11  \* 0x0b
BestOfferMessageCode == 12  \* 0x0c
BestBidShortMessageCode == 13  \* 0x0d
BestOfferShortMessageCode == 14  \* 0x0e
ClearBookMessageCode == 15  \* 0x0f
AuctionTradeMessageCode == 16  \* 0x10
BrokenAuctionTradeMessageCode == 17  \* 0x11
CorrectedAuctionTradeMessageCode == 18  \* 0x12

Payload ==
    [ tag : {InstrumentDirectoryMessageCode}, body : InstrumentDirectoryMessage ]
        \cup [ tag : {RegShoRestrictionMessageCode}, body : RegShoRestrictionMessage ]
        \cup [ tag : {SecurityTradingStatusMessageCode}, body : SecurityTradingStatusMessage ]
        \cup [ tag : {SnapshotCompleteMessageCode}, body : SnapshotCompleteMessage ]
        \cup [ tag : {TradingSessionStatusMessageCode}, body : TradingSessionStatusMessage ]
        \cup [ tag : {BestBidOfferMessageCode}, body : BestBidOfferMessage ]
        \cup [ tag : {BestBidMessageCode}, body : BestBidMessage ]
        \cup [ tag : {BestOfferMessageCode}, body : BestOfferMessage ]
        \cup [ tag : {BestBidShortMessageCode}, body : BestBidShortMessage ]
        \cup [ tag : {BestOfferShortMessageCode}, body : BestOfferShortMessage ]
        \cup [ tag : {ClearBookMessageCode}, body : ClearBookMessage ]
        \cup [ tag : {AuctionTradeMessageCode}, body : AuctionTradeMessage ]
        \cup [ tag : {BrokenAuctionTradeMessageCode}, body : BrokenAuctionTradeMessage ]
        \cup [ tag : {CorrectedAuctionTradeMessageCode}, body : CorrectedAuctionTradeMessage ]

EncodePayload(message) ==
    CASE message.tag = InstrumentDirectoryMessageCode -> EncodeInstrumentDirectoryMessage(message.body)
      [] message.tag = RegShoRestrictionMessageCode -> EncodeRegShoRestrictionMessage(message.body)
      [] message.tag = SecurityTradingStatusMessageCode -> EncodeSecurityTradingStatusMessage(message.body)
      [] message.tag = SnapshotCompleteMessageCode -> EncodeSnapshotCompleteMessage(message.body)
      [] message.tag = TradingSessionStatusMessageCode -> EncodeTradingSessionStatusMessage(message.body)
      [] message.tag = BestBidOfferMessageCode -> EncodeBestBidOfferMessage(message.body)
      [] message.tag = BestBidMessageCode -> EncodeBestBidMessage(message.body)
      [] message.tag = BestOfferMessageCode -> EncodeBestOfferMessage(message.body)
      [] message.tag = BestBidShortMessageCode -> EncodeBestBidShortMessage(message.body)
      [] message.tag = BestOfferShortMessageCode -> EncodeBestOfferShortMessage(message.body)
      [] message.tag = ClearBookMessageCode -> EncodeClearBookMessage(message.body)
      [] message.tag = AuctionTradeMessageCode -> EncodeAuctionTradeMessage(message.body)
      [] message.tag = BrokenAuctionTradeMessageCode -> EncodeBrokenAuctionTradeMessage(message.body)
      [] message.tag = CorrectedAuctionTradeMessageCode -> EncodeCorrectedAuctionTradeMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = InstrumentDirectoryMessageCode -> DecodeInstrumentDirectoryMessage(bytes)
              [] tag = RegShoRestrictionMessageCode -> DecodeRegShoRestrictionMessage(bytes)
              [] tag = SecurityTradingStatusMessageCode -> DecodeSecurityTradingStatusMessage(bytes)
              [] tag = SnapshotCompleteMessageCode -> DecodeSnapshotCompleteMessage(bytes)
              [] tag = TradingSessionStatusMessageCode -> DecodeTradingSessionStatusMessage(bytes)
              [] tag = BestBidOfferMessageCode -> DecodeBestBidOfferMessage(bytes)
              [] tag = BestBidMessageCode -> DecodeBestBidMessage(bytes)
              [] tag = BestOfferMessageCode -> DecodeBestOfferMessage(bytes)
              [] tag = BestBidShortMessageCode -> DecodeBestBidShortMessage(bytes)
              [] tag = BestOfferShortMessageCode -> DecodeBestOfferShortMessage(bytes)
              [] tag = ClearBookMessageCode -> DecodeClearBookMessage(bytes)
              [] tag = AuctionTradeMessageCode -> DecodeAuctionTradeMessage(bytes)
              [] tag = BrokenAuctionTradeMessageCode -> DecodeBrokenAuctionTradeMessage(bytes)
              [] tag = CorrectedAuctionTradeMessageCode -> DecodeCorrectedAuctionTradeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> InstrumentDirectoryMessageCode, body |-> ZeroInstrumentDirectoryMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> InstrumentDirectoryMessageCode, body |-> one] : one \in CheckedInstrumentDirectoryMessage }
        \cup { [tag |-> RegShoRestrictionMessageCode, body |-> one] : one \in CheckedRegShoRestrictionMessage }
        \cup { [tag |-> SecurityTradingStatusMessageCode, body |-> one] : one \in CheckedSecurityTradingStatusMessage }
        \cup { [tag |-> SnapshotCompleteMessageCode, body |-> one] : one \in CheckedSnapshotCompleteMessage }
        \cup { [tag |-> TradingSessionStatusMessageCode, body |-> one] : one \in CheckedTradingSessionStatusMessage }
        \cup { [tag |-> BestBidOfferMessageCode, body |-> one] : one \in CheckedBestBidOfferMessage }
        \cup { [tag |-> BestBidMessageCode, body |-> one] : one \in CheckedBestBidMessage }
        \cup { [tag |-> BestOfferMessageCode, body |-> one] : one \in CheckedBestOfferMessage }
        \cup { [tag |-> BestBidShortMessageCode, body |-> one] : one \in CheckedBestBidShortMessage }
        \cup { [tag |-> BestOfferShortMessageCode, body |-> one] : one \in CheckedBestOfferShortMessage }
        \cup { [tag |-> ClearBookMessageCode, body |-> one] : one \in CheckedClearBookMessage }
        \cup { [tag |-> AuctionTradeMessageCode, body |-> one] : one \in CheckedAuctionTradeMessage }
        \cup { [tag |-> BrokenAuctionTradeMessageCode, body |-> one] : one \in CheckedBrokenAuctionTradeMessage }
        \cup { [tag |-> CorrectedAuctionTradeMessageCode, body |-> one] : one \in CheckedCorrectedAuctionTradeMessage }

(***************************************************************************)
(* Sbe Message, framed by Block Length                                     *)
(***************************************************************************)

SbeMessage ==
    [ schemaId : Sample(1),
      version  : Sample(2),
      payload  : Payload ]

EncodeSbeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

(* Block Length counts the bytes it frames, so it is written from them *)
EncodeSbeMessage(message) ==
    LET body == EncodeSbeMessageBody(message)
    IN  EncodeUIntBE(Len(body) - 4, 2) \o body

DecodeSbeMessageBody(bytes) ==
    LET templateId == ReadUIntBE(bytes, 1) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 1) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ schemaId |-> schemaId.value,
         version  |-> version.value,
         payload  |-> payload.value ], payload.rest)

DecodeSbeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value + 4 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeSbeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSbeMessage ==
    [ schemaId |-> [i \in 1 .. 1 |-> 0],
      version  |-> [i \in 1 .. 2 |-> 0],
      payload  |-> ZeroPayload ]

(* Sbe Message at zero, then each field in turn at the values it is checked at *)
CheckedSbeMessage ==
    { ZeroSbeMessage }
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

(* Every Reg Sho Restriction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegShoRestrictionMessage ==
    \A message \in CheckedRegShoRestrictionMessage :
        LET read == DecodeRegShoRestrictionMessage(EncodeRegShoRestrictionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityTradingStatusMessage ==
    \A message \in CheckedSecurityTradingStatusMessage :
        LET read == DecodeSecurityTradingStatusMessage(EncodeSecurityTradingStatusMessage(message))
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

(* Every Trading Session Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingSessionStatusMessage ==
    \A message \in CheckedTradingSessionStatusMessage :
        LET read == DecodeTradingSessionStatusMessage(EncodeTradingSessionStatusMessage(message))
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

(* Every Clear Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClearBookMessage ==
    \A message \in CheckedClearBookMessage :
        LET read == DecodeClearBookMessage(EncodeClearBookMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionTradeMessage ==
    \A message \in CheckedAuctionTradeMessage :
        LET read == DecodeAuctionTradeMessage(EncodeAuctionTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broken Auction Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenAuctionTradeMessage ==
    \A message \in CheckedBrokenAuctionTradeMessage :
        LET read == DecodeBrokenAuctionTradeMessage(EncodeBrokenAuctionTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Corrected Auction Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCorrectedAuctionTradeMessage ==
    \A message \in CheckedCorrectedAuctionTradeMessage :
        LET read == DecodeCorrectedAuctionTradeMessage(EncodeCorrectedAuctionTradeMessage(message))
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

(* Block Length is written from the bytes it frames *)
FramesSbeMessage ==
    \A message \in CheckedSbeMessage :
        LET bytes == EncodeSbeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 6

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
