---------------------- MODULE Siac_Cqs_Snapshot_v2_1 -----------------------
(***************************************************************************)
(* The Securities Industry Automation Corporation  v2.1                    *)
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
(* Note: Block Pad Byte pads to a 2 byte boundary: it is read as the bytes *)
(* left to the end of the frame, and the frame's length is trusted to keep *)
(* that boundary.                                                          *)
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
(* Sip Block Timestamp: 8 bytes                                            *)
(***************************************************************************)

SipBlockTimestamp ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeSipBlockTimestamp(message) ==
    message.seconds
        \o message.nanoseconds

DecodeSipBlockTimestamp(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroSipBlockTimestamp ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Sip Block Timestamp at zero, then each field in turn at the values it is checked at *)
CheckedSipBlockTimestamp ==
    { ZeroSipBlockTimestamp }
        \cup { [ZeroSipBlockTimestamp EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroSipBlockTimestamp EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Line Integrity Message: 1 bytes                                         *)
(***************************************************************************)

LineIntegrityMessage ==
    [ participantId : Sample(1) ]

EncodeLineIntegrityMessage(message) ==
    message.participantId

DecodeLineIntegrityMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    Ok([ participantId |-> participantId.value ], participantId.rest)

ZeroLineIntegrityMessage ==
    [ participantId |-> [i \in 1 .. 1 |-> 0] ]

(* Line Integrity Message at zero, then each field in turn at the values it is checked at *)
CheckedLineIntegrityMessage ==
    { ZeroLineIntegrityMessage }
        \cup { [ZeroLineIntegrityMessage EXCEPT !.participantId = one] : one \in Sample(1) }

(***************************************************************************)
(* Symbol Reference Data Message: 57 bytes                                 *)
(***************************************************************************)

SymbolReferenceDataMessage ==
    [ participantId                            : Sample(1),
      securitySymbol                           : Sample(11),
      priorSecuritySymbol                      : Sample(11),
      primaryListingMarketParticipantId        : Sample(1),
      primaryListingMarketPreviousClosingPrice : Sample(8),
      consolidatedClosingPrice                 : Sample(8),
      roundLotSize                             : Sample(2),
      reserved                                 : Sample(1),
      luldTier                                 : Sample(1),
      luldLeverageRatio                        : Sample(4),
      test                                     : Sample(1),
      ipo                                      : Sample(1),
      financialStatusIndicator                 : Sample(1),
      shortSaleRestrictionIndicator            : Sample(1),
      haltReason                               : Sample(1),
      instrumentType                           : Sample(1),
      secondReserved                           : Sample(1),
      thirdReserved                            : Sample(1),
      fourthReserved                           : Sample(1) ]

EncodeSymbolReferenceDataMessage(message) ==
    message.participantId
        \o message.securitySymbol
        \o message.priorSecuritySymbol
        \o message.primaryListingMarketParticipantId
        \o message.primaryListingMarketPreviousClosingPrice
        \o message.consolidatedClosingPrice
        \o message.roundLotSize
        \o message.reserved
        \o message.luldTier
        \o message.luldLeverageRatio
        \o message.test
        \o message.ipo
        \o message.financialStatusIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.haltReason
        \o message.instrumentType
        \o message.secondReserved
        \o message.thirdReserved
        \o message.fourthReserved

DecodeSymbolReferenceDataMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantId.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET priorSecuritySymbol == ReadBytes(securitySymbol.rest, 11) IN IF ~priorSecuritySymbol.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(priorSecuritySymbol.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET primaryListingMarketPreviousClosingPrice == ReadBytes(primaryListingMarketParticipantId.rest, 8) IN IF ~primaryListingMarketPreviousClosingPrice.ok THEN Fail ELSE
    LET consolidatedClosingPrice == ReadBytes(primaryListingMarketPreviousClosingPrice.rest, 8) IN IF ~consolidatedClosingPrice.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(consolidatedClosingPrice.rest, 2) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET reserved == ReadBytes(roundLotSize.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET luldTier == ReadBytes(reserved.rest, 1) IN IF ~luldTier.ok THEN Fail ELSE
    LET luldLeverageRatio == ReadBytes(luldTier.rest, 4) IN IF ~luldLeverageRatio.ok THEN Fail ELSE
    LET test == ReadBytes(luldLeverageRatio.rest, 1) IN IF ~test.ok THEN Fail ELSE
    LET ipo == ReadBytes(test.rest, 1) IN IF ~ipo.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(ipo.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(financialStatusIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET haltReason == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~haltReason.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(haltReason.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET secondReserved == ReadBytes(instrumentType.rest, 1) IN IF ~secondReserved.ok THEN Fail ELSE
    LET thirdReserved == ReadBytes(secondReserved.rest, 1) IN IF ~thirdReserved.ok THEN Fail ELSE
    LET fourthReserved == ReadBytes(thirdReserved.rest, 1) IN IF ~fourthReserved.ok THEN Fail ELSE
    Ok([ participantId                            |-> participantId.value,
         securitySymbol                           |-> securitySymbol.value,
         priorSecuritySymbol                      |-> priorSecuritySymbol.value,
         primaryListingMarketParticipantId        |-> primaryListingMarketParticipantId.value,
         primaryListingMarketPreviousClosingPrice |-> primaryListingMarketPreviousClosingPrice.value,
         consolidatedClosingPrice                 |-> consolidatedClosingPrice.value,
         roundLotSize                             |-> roundLotSize.value,
         reserved                                 |-> reserved.value,
         luldTier                                 |-> luldTier.value,
         luldLeverageRatio                        |-> luldLeverageRatio.value,
         test                                     |-> test.value,
         ipo                                      |-> ipo.value,
         financialStatusIndicator                 |-> financialStatusIndicator.value,
         shortSaleRestrictionIndicator            |-> shortSaleRestrictionIndicator.value,
         haltReason                               |-> haltReason.value,
         instrumentType                           |-> instrumentType.value,
         secondReserved                           |-> secondReserved.value,
         thirdReserved                            |-> thirdReserved.value,
         fourthReserved                           |-> fourthReserved.value ], fourthReserved.rest)

ZeroSymbolReferenceDataMessage ==
    [ participantId                            |-> [i \in 1 .. 1 |-> 0],
      securitySymbol                           |-> [i \in 1 .. 11 |-> 0],
      priorSecuritySymbol                      |-> [i \in 1 .. 11 |-> 0],
      primaryListingMarketParticipantId        |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketPreviousClosingPrice |-> [i \in 1 .. 8 |-> 0],
      consolidatedClosingPrice                 |-> [i \in 1 .. 8 |-> 0],
      roundLotSize                             |-> [i \in 1 .. 2 |-> 0],
      reserved                                 |-> [i \in 1 .. 1 |-> 0],
      luldTier                                 |-> [i \in 1 .. 1 |-> 0],
      luldLeverageRatio                        |-> [i \in 1 .. 4 |-> 0],
      test                                     |-> [i \in 1 .. 1 |-> 0],
      ipo                                      |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator                 |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator            |-> [i \in 1 .. 1 |-> 0],
      haltReason                               |-> [i \in 1 .. 1 |-> 0],
      instrumentType                           |-> [i \in 1 .. 1 |-> 0],
      secondReserved                           |-> [i \in 1 .. 1 |-> 0],
      thirdReserved                            |-> [i \in 1 .. 1 |-> 0],
      fourthReserved                           |-> [i \in 1 .. 1 |-> 0] ]

(* Symbol Reference Data Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolReferenceDataMessage ==
    { ZeroSymbolReferenceDataMessage }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.priorSecuritySymbol = one] : one \in Sample(11) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.primaryListingMarketPreviousClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.consolidatedClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.roundLotSize = one] : one \in Sample(2) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.luldTier = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.luldLeverageRatio = one] : one \in Sample(4) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.test = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.ipo = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.haltReason = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.secondReserved = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.thirdReserved = one] : one \in Sample(1) }
        \cup { [ZeroSymbolReferenceDataMessage EXCEPT !.fourthReserved = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Wide Circuit Breaker Decline Level Status Snapshot Message: 26   *)
(* bytes                                                                   *)
(***************************************************************************)

MarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage ==
    [ participantId : Sample(1),
      mwcbLevel1    : Sample(8),
      mwcbLevel2    : Sample(8),
      mwcbLevel3    : Sample(8),
      reserved      : Sample(1) ]

EncodeMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage(message) ==
    message.participantId
        \o message.mwcbLevel1
        \o message.mwcbLevel2
        \o message.mwcbLevel3
        \o message.reserved

DecodeMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET mwcbLevel1 == ReadBytes(participantId.rest, 8) IN IF ~mwcbLevel1.ok THEN Fail ELSE
    LET mwcbLevel2 == ReadBytes(mwcbLevel1.rest, 8) IN IF ~mwcbLevel2.ok THEN Fail ELSE
    LET mwcbLevel3 == ReadBytes(mwcbLevel2.rest, 8) IN IF ~mwcbLevel3.ok THEN Fail ELSE
    LET reserved == ReadBytes(mwcbLevel3.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    Ok([ participantId |-> participantId.value,
         mwcbLevel1    |-> mwcbLevel1.value,
         mwcbLevel2    |-> mwcbLevel2.value,
         mwcbLevel3    |-> mwcbLevel3.value,
         reserved      |-> reserved.value ], reserved.rest)

ZeroMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage ==
    [ participantId |-> [i \in 1 .. 1 |-> 0],
      mwcbLevel1    |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel2    |-> [i \in 1 .. 8 |-> 0],
      mwcbLevel3    |-> [i \in 1 .. 8 |-> 0],
      reserved      |-> [i \in 1 .. 1 |-> 0] ]

(* Market Wide Circuit Breaker Decline Level Status Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage ==
    { ZeroMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage EXCEPT !.mwcbLevel1 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage EXCEPT !.mwcbLevel2 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage EXCEPT !.mwcbLevel3 = one] : one \in Sample(8) }
        \cup { [ZeroMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage EXCEPT !.reserved = one] : one \in Sample(1) }

(***************************************************************************)
(* Consolidated Snapshot Message: 96 bytes                                 *)
(***************************************************************************)

ConsolidatedSnapshotMessage ==
    [ participantId                     : Sample(1),
      securitySymbol                    : Sample(11),
      instrumentType                    : Sample(1),
      lowerLimitPriceBand               : Sample(8),
      upperLimitPriceBand               : Sample(8),
      auctionCollarReferencePrice       : Sample(8),
      auctionCollarUpperThresholdPrice  : Sample(8),
      auctionCollarLowerThresholdPrice  : Sample(8),
      numberOfExtensions                : Sample(1),
      nationalBestBidParticipantId      : Sample(1),
      nationalBestBidQuoteCondition     : Sample(1),
      nationalBestBidPrice              : Sample(8),
      nationalBestBidSize               : Sample(4),
      finraBestBidMarketMakerId         : Sample(4),
      nationalBestOfferParticipantId    : Sample(1),
      nationalBestOfferQuoteCondition   : Sample(1),
      nationalBestOfferPrice            : Sample(8),
      nationalBestOfferSize             : Sample(4),
      finraBestOfferMarketMakerId       : Sample(4),
      nationalBboLuldIndicator          : Sample(1),
      primaryListingMarketParticipantId : Sample(1),
      financialStatusIndicator          : Sample(1),
      shortSaleRestrictionIndicator     : Sample(1),
      haltReason                        : Sample(1),
      reserved                          : Sample(1) ]

EncodeConsolidatedSnapshotMessage(message) ==
    message.participantId
        \o message.securitySymbol
        \o message.instrumentType
        \o message.lowerLimitPriceBand
        \o message.upperLimitPriceBand
        \o message.auctionCollarReferencePrice
        \o message.auctionCollarUpperThresholdPrice
        \o message.auctionCollarLowerThresholdPrice
        \o message.numberOfExtensions
        \o message.nationalBestBidParticipantId
        \o message.nationalBestBidQuoteCondition
        \o message.nationalBestBidPrice
        \o message.nationalBestBidSize
        \o message.finraBestBidMarketMakerId
        \o message.nationalBestOfferParticipantId
        \o message.nationalBestOfferQuoteCondition
        \o message.nationalBestOfferPrice
        \o message.nationalBestOfferSize
        \o message.finraBestOfferMarketMakerId
        \o message.nationalBboLuldIndicator
        \o message.primaryListingMarketParticipantId
        \o message.financialStatusIndicator
        \o message.shortSaleRestrictionIndicator
        \o message.haltReason
        \o message.reserved

DecodeConsolidatedSnapshotMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantId.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(securitySymbol.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET lowerLimitPriceBand == ReadBytes(instrumentType.rest, 8) IN IF ~lowerLimitPriceBand.ok THEN Fail ELSE
    LET upperLimitPriceBand == ReadBytes(lowerLimitPriceBand.rest, 8) IN IF ~upperLimitPriceBand.ok THEN Fail ELSE
    LET auctionCollarReferencePrice == ReadBytes(upperLimitPriceBand.rest, 8) IN IF ~auctionCollarReferencePrice.ok THEN Fail ELSE
    LET auctionCollarUpperThresholdPrice == ReadBytes(auctionCollarReferencePrice.rest, 8) IN IF ~auctionCollarUpperThresholdPrice.ok THEN Fail ELSE
    LET auctionCollarLowerThresholdPrice == ReadBytes(auctionCollarUpperThresholdPrice.rest, 8) IN IF ~auctionCollarLowerThresholdPrice.ok THEN Fail ELSE
    LET numberOfExtensions == ReadBytes(auctionCollarLowerThresholdPrice.rest, 1) IN IF ~numberOfExtensions.ok THEN Fail ELSE
    LET nationalBestBidParticipantId == ReadBytes(numberOfExtensions.rest, 1) IN IF ~nationalBestBidParticipantId.ok THEN Fail ELSE
    LET nationalBestBidQuoteCondition == ReadBytes(nationalBestBidParticipantId.rest, 1) IN IF ~nationalBestBidQuoteCondition.ok THEN Fail ELSE
    LET nationalBestBidPrice == ReadBytes(nationalBestBidQuoteCondition.rest, 8) IN IF ~nationalBestBidPrice.ok THEN Fail ELSE
    LET nationalBestBidSize == ReadBytes(nationalBestBidPrice.rest, 4) IN IF ~nationalBestBidSize.ok THEN Fail ELSE
    LET finraBestBidMarketMakerId == ReadBytes(nationalBestBidSize.rest, 4) IN IF ~finraBestBidMarketMakerId.ok THEN Fail ELSE
    LET nationalBestOfferParticipantId == ReadBytes(finraBestBidMarketMakerId.rest, 1) IN IF ~nationalBestOfferParticipantId.ok THEN Fail ELSE
    LET nationalBestOfferQuoteCondition == ReadBytes(nationalBestOfferParticipantId.rest, 1) IN IF ~nationalBestOfferQuoteCondition.ok THEN Fail ELSE
    LET nationalBestOfferPrice == ReadBytes(nationalBestOfferQuoteCondition.rest, 8) IN IF ~nationalBestOfferPrice.ok THEN Fail ELSE
    LET nationalBestOfferSize == ReadBytes(nationalBestOfferPrice.rest, 4) IN IF ~nationalBestOfferSize.ok THEN Fail ELSE
    LET finraBestOfferMarketMakerId == ReadBytes(nationalBestOfferSize.rest, 4) IN IF ~finraBestOfferMarketMakerId.ok THEN Fail ELSE
    LET nationalBboLuldIndicator == ReadBytes(finraBestOfferMarketMakerId.rest, 1) IN IF ~nationalBboLuldIndicator.ok THEN Fail ELSE
    LET primaryListingMarketParticipantId == ReadBytes(nationalBboLuldIndicator.rest, 1) IN IF ~primaryListingMarketParticipantId.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(primaryListingMarketParticipantId.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET shortSaleRestrictionIndicator == ReadBytes(financialStatusIndicator.rest, 1) IN IF ~shortSaleRestrictionIndicator.ok THEN Fail ELSE
    LET haltReason == ReadBytes(shortSaleRestrictionIndicator.rest, 1) IN IF ~haltReason.ok THEN Fail ELSE
    LET reserved == ReadBytes(haltReason.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    Ok([ participantId                     |-> participantId.value,
         securitySymbol                    |-> securitySymbol.value,
         instrumentType                    |-> instrumentType.value,
         lowerLimitPriceBand               |-> lowerLimitPriceBand.value,
         upperLimitPriceBand               |-> upperLimitPriceBand.value,
         auctionCollarReferencePrice       |-> auctionCollarReferencePrice.value,
         auctionCollarUpperThresholdPrice  |-> auctionCollarUpperThresholdPrice.value,
         auctionCollarLowerThresholdPrice  |-> auctionCollarLowerThresholdPrice.value,
         numberOfExtensions                |-> numberOfExtensions.value,
         nationalBestBidParticipantId      |-> nationalBestBidParticipantId.value,
         nationalBestBidQuoteCondition     |-> nationalBestBidQuoteCondition.value,
         nationalBestBidPrice              |-> nationalBestBidPrice.value,
         nationalBestBidSize               |-> nationalBestBidSize.value,
         finraBestBidMarketMakerId         |-> finraBestBidMarketMakerId.value,
         nationalBestOfferParticipantId    |-> nationalBestOfferParticipantId.value,
         nationalBestOfferQuoteCondition   |-> nationalBestOfferQuoteCondition.value,
         nationalBestOfferPrice            |-> nationalBestOfferPrice.value,
         nationalBestOfferSize             |-> nationalBestOfferSize.value,
         finraBestOfferMarketMakerId       |-> finraBestOfferMarketMakerId.value,
         nationalBboLuldIndicator          |-> nationalBboLuldIndicator.value,
         primaryListingMarketParticipantId |-> primaryListingMarketParticipantId.value,
         financialStatusIndicator          |-> financialStatusIndicator.value,
         shortSaleRestrictionIndicator     |-> shortSaleRestrictionIndicator.value,
         haltReason                        |-> haltReason.value,
         reserved                          |-> reserved.value ], reserved.rest)

ZeroConsolidatedSnapshotMessage ==
    [ participantId                     |-> [i \in 1 .. 1 |-> 0],
      securitySymbol                    |-> [i \in 1 .. 11 |-> 0],
      instrumentType                    |-> [i \in 1 .. 1 |-> 0],
      lowerLimitPriceBand               |-> [i \in 1 .. 8 |-> 0],
      upperLimitPriceBand               |-> [i \in 1 .. 8 |-> 0],
      auctionCollarReferencePrice       |-> [i \in 1 .. 8 |-> 0],
      auctionCollarUpperThresholdPrice  |-> [i \in 1 .. 8 |-> 0],
      auctionCollarLowerThresholdPrice  |-> [i \in 1 .. 8 |-> 0],
      numberOfExtensions                |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidParticipantId      |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidQuoteCondition     |-> [i \in 1 .. 1 |-> 0],
      nationalBestBidPrice              |-> [i \in 1 .. 8 |-> 0],
      nationalBestBidSize               |-> [i \in 1 .. 4 |-> 0],
      finraBestBidMarketMakerId         |-> [i \in 1 .. 4 |-> 0],
      nationalBestOfferParticipantId    |-> [i \in 1 .. 1 |-> 0],
      nationalBestOfferQuoteCondition   |-> [i \in 1 .. 1 |-> 0],
      nationalBestOfferPrice            |-> [i \in 1 .. 8 |-> 0],
      nationalBestOfferSize             |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferMarketMakerId       |-> [i \in 1 .. 4 |-> 0],
      nationalBboLuldIndicator          |-> [i \in 1 .. 1 |-> 0],
      primaryListingMarketParticipantId |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator          |-> [i \in 1 .. 1 |-> 0],
      shortSaleRestrictionIndicator     |-> [i \in 1 .. 1 |-> 0],
      haltReason                        |-> [i \in 1 .. 1 |-> 0],
      reserved                          |-> [i \in 1 .. 1 |-> 0] ]

(* Consolidated Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedConsolidatedSnapshotMessage ==
    { ZeroConsolidatedSnapshotMessage }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.lowerLimitPriceBand = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.upperLimitPriceBand = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.auctionCollarReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.auctionCollarUpperThresholdPrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.auctionCollarLowerThresholdPrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.numberOfExtensions = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.nationalBestBidParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.nationalBestBidQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.nationalBestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.nationalBestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.finraBestBidMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.nationalBestOfferParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.nationalBestOfferQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.nationalBestOfferPrice = one] : one \in Sample(8) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.nationalBestOfferSize = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.finraBestOfferMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.nationalBboLuldIndicator = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.primaryListingMarketParticipantId = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.shortSaleRestrictionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.haltReason = one] : one \in Sample(1) }
        \cup { [ZeroConsolidatedSnapshotMessage EXCEPT !.reserved = one] : one \in Sample(1) }

(***************************************************************************)
(* Participant Snapshot Message: 58 bytes                                  *)
(***************************************************************************)

ParticipantSnapshotMessage ==
    [ participantId                 : Sample(1),
      securitySymbol                : Sample(11),
      quoteCondition                : Sample(1),
      bidPrice                      : Sample(8),
      bidSize                       : Sample(4),
      offerPrice                    : Sample(8),
      offerSize                     : Sample(4),
      retailInterestIndicator       : Sample(1),
      settlementCondition           : Sample(1),
      marketCondition               : Sample(1),
      limitUpLimitDownLuldIndicator : Sample(1),
      highIndicationPrice           : Sample(8),
      lowIndicationPrice            : Sample(8),
      haltReason                    : Sample(1) ]

EncodeParticipantSnapshotMessage(message) ==
    message.participantId
        \o message.securitySymbol
        \o message.quoteCondition
        \o message.bidPrice
        \o message.bidSize
        \o message.offerPrice
        \o message.offerSize
        \o message.retailInterestIndicator
        \o message.settlementCondition
        \o message.marketCondition
        \o message.limitUpLimitDownLuldIndicator
        \o message.highIndicationPrice
        \o message.lowIndicationPrice
        \o message.haltReason

DecodeParticipantSnapshotMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantId.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(securitySymbol.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(quoteCondition.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(bidSize.rest, 8) IN IF ~offerPrice.ok THEN Fail ELSE
    LET offerSize == ReadBytes(offerPrice.rest, 4) IN IF ~offerSize.ok THEN Fail ELSE
    LET retailInterestIndicator == ReadBytes(offerSize.rest, 1) IN IF ~retailInterestIndicator.ok THEN Fail ELSE
    LET settlementCondition == ReadBytes(retailInterestIndicator.rest, 1) IN IF ~settlementCondition.ok THEN Fail ELSE
    LET marketCondition == ReadBytes(settlementCondition.rest, 1) IN IF ~marketCondition.ok THEN Fail ELSE
    LET limitUpLimitDownLuldIndicator == ReadBytes(marketCondition.rest, 1) IN IF ~limitUpLimitDownLuldIndicator.ok THEN Fail ELSE
    LET highIndicationPrice == ReadBytes(limitUpLimitDownLuldIndicator.rest, 8) IN IF ~highIndicationPrice.ok THEN Fail ELSE
    LET lowIndicationPrice == ReadBytes(highIndicationPrice.rest, 8) IN IF ~lowIndicationPrice.ok THEN Fail ELSE
    LET haltReason == ReadBytes(lowIndicationPrice.rest, 1) IN IF ~haltReason.ok THEN Fail ELSE
    Ok([ participantId                 |-> participantId.value,
         securitySymbol                |-> securitySymbol.value,
         quoteCondition                |-> quoteCondition.value,
         bidPrice                      |-> bidPrice.value,
         bidSize                       |-> bidSize.value,
         offerPrice                    |-> offerPrice.value,
         offerSize                     |-> offerSize.value,
         retailInterestIndicator       |-> retailInterestIndicator.value,
         settlementCondition           |-> settlementCondition.value,
         marketCondition               |-> marketCondition.value,
         limitUpLimitDownLuldIndicator |-> limitUpLimitDownLuldIndicator.value,
         highIndicationPrice           |-> highIndicationPrice.value,
         lowIndicationPrice            |-> lowIndicationPrice.value,
         haltReason                    |-> haltReason.value ], haltReason.rest)

ZeroParticipantSnapshotMessage ==
    [ participantId                 |-> [i \in 1 .. 1 |-> 0],
      securitySymbol                |-> [i \in 1 .. 11 |-> 0],
      quoteCondition                |-> [i \in 1 .. 1 |-> 0],
      bidPrice                      |-> [i \in 1 .. 8 |-> 0],
      bidSize                       |-> [i \in 1 .. 4 |-> 0],
      offerPrice                    |-> [i \in 1 .. 8 |-> 0],
      offerSize                     |-> [i \in 1 .. 4 |-> 0],
      retailInterestIndicator       |-> [i \in 1 .. 1 |-> 0],
      settlementCondition           |-> [i \in 1 .. 1 |-> 0],
      marketCondition               |-> [i \in 1 .. 1 |-> 0],
      limitUpLimitDownLuldIndicator |-> [i \in 1 .. 1 |-> 0],
      highIndicationPrice           |-> [i \in 1 .. 8 |-> 0],
      lowIndicationPrice            |-> [i \in 1 .. 8 |-> 0],
      haltReason                    |-> [i \in 1 .. 1 |-> 0] ]

(* Participant Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedParticipantSnapshotMessage ==
    { ZeroParticipantSnapshotMessage }
        \cup { [ZeroParticipantSnapshotMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroParticipantSnapshotMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroParticipantSnapshotMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroParticipantSnapshotMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantSnapshotMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroParticipantSnapshotMessage EXCEPT !.offerPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantSnapshotMessage EXCEPT !.offerSize = one] : one \in Sample(4) }
        \cup { [ZeroParticipantSnapshotMessage EXCEPT !.retailInterestIndicator = one] : one \in Sample(1) }
        \cup { [ZeroParticipantSnapshotMessage EXCEPT !.settlementCondition = one] : one \in Sample(1) }
        \cup { [ZeroParticipantSnapshotMessage EXCEPT !.marketCondition = one] : one \in Sample(1) }
        \cup { [ZeroParticipantSnapshotMessage EXCEPT !.limitUpLimitDownLuldIndicator = one] : one \in Sample(1) }
        \cup { [ZeroParticipantSnapshotMessage EXCEPT !.highIndicationPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantSnapshotMessage EXCEPT !.lowIndicationPrice = one] : one \in Sample(8) }
        \cup { [ZeroParticipantSnapshotMessage EXCEPT !.haltReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Finra Snapshot Message: 64 bytes                                        *)
(***************************************************************************)

FinraSnapshotMessage ==
    [ participantId                : Sample(1),
      securitySymbol               : Sample(11),
      finraBestBidQuoteCondition   : Sample(1),
      finraBestBidPrice            : Sample(8),
      finraBestBidSize             : Sample(4),
      finraBestBidMarketMakerId    : Sample(4),
      finraBestOfferQuoteCondition : Sample(1),
      finraBestOfferPrice          : Sample(8),
      finraBestOfferSize           : Sample(4),
      finraBestOfferMarketMakerId  : Sample(4),
      finraBboLuldIndicator        : Sample(1),
      highIndicationPrice          : Sample(8),
      lowIndicationPrice           : Sample(8),
      haltReason                   : Sample(1) ]

EncodeFinraSnapshotMessage(message) ==
    message.participantId
        \o message.securitySymbol
        \o message.finraBestBidQuoteCondition
        \o message.finraBestBidPrice
        \o message.finraBestBidSize
        \o message.finraBestBidMarketMakerId
        \o message.finraBestOfferQuoteCondition
        \o message.finraBestOfferPrice
        \o message.finraBestOfferSize
        \o message.finraBestOfferMarketMakerId
        \o message.finraBboLuldIndicator
        \o message.highIndicationPrice
        \o message.lowIndicationPrice
        \o message.haltReason

DecodeFinraSnapshotMessage(bytes) ==
    LET participantId == ReadBytes(bytes, 1) IN IF ~participantId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(participantId.rest, 11) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET finraBestBidQuoteCondition == ReadBytes(securitySymbol.rest, 1) IN IF ~finraBestBidQuoteCondition.ok THEN Fail ELSE
    LET finraBestBidPrice == ReadBytes(finraBestBidQuoteCondition.rest, 8) IN IF ~finraBestBidPrice.ok THEN Fail ELSE
    LET finraBestBidSize == ReadBytes(finraBestBidPrice.rest, 4) IN IF ~finraBestBidSize.ok THEN Fail ELSE
    LET finraBestBidMarketMakerId == ReadBytes(finraBestBidSize.rest, 4) IN IF ~finraBestBidMarketMakerId.ok THEN Fail ELSE
    LET finraBestOfferQuoteCondition == ReadBytes(finraBestBidMarketMakerId.rest, 1) IN IF ~finraBestOfferQuoteCondition.ok THEN Fail ELSE
    LET finraBestOfferPrice == ReadBytes(finraBestOfferQuoteCondition.rest, 8) IN IF ~finraBestOfferPrice.ok THEN Fail ELSE
    LET finraBestOfferSize == ReadBytes(finraBestOfferPrice.rest, 4) IN IF ~finraBestOfferSize.ok THEN Fail ELSE
    LET finraBestOfferMarketMakerId == ReadBytes(finraBestOfferSize.rest, 4) IN IF ~finraBestOfferMarketMakerId.ok THEN Fail ELSE
    LET finraBboLuldIndicator == ReadBytes(finraBestOfferMarketMakerId.rest, 1) IN IF ~finraBboLuldIndicator.ok THEN Fail ELSE
    LET highIndicationPrice == ReadBytes(finraBboLuldIndicator.rest, 8) IN IF ~highIndicationPrice.ok THEN Fail ELSE
    LET lowIndicationPrice == ReadBytes(highIndicationPrice.rest, 8) IN IF ~lowIndicationPrice.ok THEN Fail ELSE
    LET haltReason == ReadBytes(lowIndicationPrice.rest, 1) IN IF ~haltReason.ok THEN Fail ELSE
    Ok([ participantId                |-> participantId.value,
         securitySymbol               |-> securitySymbol.value,
         finraBestBidQuoteCondition   |-> finraBestBidQuoteCondition.value,
         finraBestBidPrice            |-> finraBestBidPrice.value,
         finraBestBidSize             |-> finraBestBidSize.value,
         finraBestBidMarketMakerId    |-> finraBestBidMarketMakerId.value,
         finraBestOfferQuoteCondition |-> finraBestOfferQuoteCondition.value,
         finraBestOfferPrice          |-> finraBestOfferPrice.value,
         finraBestOfferSize           |-> finraBestOfferSize.value,
         finraBestOfferMarketMakerId  |-> finraBestOfferMarketMakerId.value,
         finraBboLuldIndicator        |-> finraBboLuldIndicator.value,
         highIndicationPrice          |-> highIndicationPrice.value,
         lowIndicationPrice           |-> lowIndicationPrice.value,
         haltReason                   |-> haltReason.value ], haltReason.rest)

ZeroFinraSnapshotMessage ==
    [ participantId                |-> [i \in 1 .. 1 |-> 0],
      securitySymbol               |-> [i \in 1 .. 11 |-> 0],
      finraBestBidQuoteCondition   |-> [i \in 1 .. 1 |-> 0],
      finraBestBidPrice            |-> [i \in 1 .. 8 |-> 0],
      finraBestBidSize             |-> [i \in 1 .. 4 |-> 0],
      finraBestBidMarketMakerId    |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferQuoteCondition |-> [i \in 1 .. 1 |-> 0],
      finraBestOfferPrice          |-> [i \in 1 .. 8 |-> 0],
      finraBestOfferSize           |-> [i \in 1 .. 4 |-> 0],
      finraBestOfferMarketMakerId  |-> [i \in 1 .. 4 |-> 0],
      finraBboLuldIndicator        |-> [i \in 1 .. 1 |-> 0],
      highIndicationPrice          |-> [i \in 1 .. 8 |-> 0],
      lowIndicationPrice           |-> [i \in 1 .. 8 |-> 0],
      haltReason                   |-> [i \in 1 .. 1 |-> 0] ]

(* Finra Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedFinraSnapshotMessage ==
    { ZeroFinraSnapshotMessage }
        \cup { [ZeroFinraSnapshotMessage EXCEPT !.participantId = one] : one \in Sample(1) }
        \cup { [ZeroFinraSnapshotMessage EXCEPT !.securitySymbol = one] : one \in Sample(11) }
        \cup { [ZeroFinraSnapshotMessage EXCEPT !.finraBestBidQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroFinraSnapshotMessage EXCEPT !.finraBestBidPrice = one] : one \in Sample(8) }
        \cup { [ZeroFinraSnapshotMessage EXCEPT !.finraBestBidSize = one] : one \in Sample(4) }
        \cup { [ZeroFinraSnapshotMessage EXCEPT !.finraBestBidMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroFinraSnapshotMessage EXCEPT !.finraBestOfferQuoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroFinraSnapshotMessage EXCEPT !.finraBestOfferPrice = one] : one \in Sample(8) }
        \cup { [ZeroFinraSnapshotMessage EXCEPT !.finraBestOfferSize = one] : one \in Sample(4) }
        \cup { [ZeroFinraSnapshotMessage EXCEPT !.finraBestOfferMarketMakerId = one] : one \in Sample(4) }
        \cup { [ZeroFinraSnapshotMessage EXCEPT !.finraBboLuldIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFinraSnapshotMessage EXCEPT !.highIndicationPrice = one] : one \in Sample(8) }
        \cup { [ZeroFinraSnapshotMessage EXCEPT !.lowIndicationPrice = one] : one \in Sample(8) }
        \cup { [ZeroFinraSnapshotMessage EXCEPT !.haltReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Snapshot Message Payload, selected by Snapshot Message Type             *)
(***************************************************************************)

LineIntegrityMessageCode == 84  \* "T"
SymbolReferenceDataMessageCode == 83  \* "S"
MarketWideCircuitBreakerDeclineLevelStatusSnapshotMessageCode == 75  \* "K"
ConsolidatedSnapshotMessageCode == 67  \* "C"
ParticipantSnapshotMessageCode == 80  \* "P"
FinraSnapshotMessageCode == 70  \* "F"

SnapshotMessagePayload ==
    [ tag : {LineIntegrityMessageCode}, body : LineIntegrityMessage ]
        \cup [ tag : {SymbolReferenceDataMessageCode}, body : SymbolReferenceDataMessage ]
        \cup [ tag : {MarketWideCircuitBreakerDeclineLevelStatusSnapshotMessageCode}, body : MarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage ]
        \cup [ tag : {ConsolidatedSnapshotMessageCode}, body : ConsolidatedSnapshotMessage ]
        \cup [ tag : {ParticipantSnapshotMessageCode}, body : ParticipantSnapshotMessage ]
        \cup [ tag : {FinraSnapshotMessageCode}, body : FinraSnapshotMessage ]

EncodeSnapshotMessagePayload(message) ==
    CASE message.tag = LineIntegrityMessageCode -> EncodeLineIntegrityMessage(message.body)
      [] message.tag = SymbolReferenceDataMessageCode -> EncodeSymbolReferenceDataMessage(message.body)
      [] message.tag = MarketWideCircuitBreakerDeclineLevelStatusSnapshotMessageCode -> EncodeMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage(message.body)
      [] message.tag = ConsolidatedSnapshotMessageCode -> EncodeConsolidatedSnapshotMessage(message.body)
      [] message.tag = ParticipantSnapshotMessageCode -> EncodeParticipantSnapshotMessage(message.body)
      [] message.tag = FinraSnapshotMessageCode -> EncodeFinraSnapshotMessage(message.body)

DecodeSnapshotMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = LineIntegrityMessageCode -> DecodeLineIntegrityMessage(bytes)
              [] tag = SymbolReferenceDataMessageCode -> DecodeSymbolReferenceDataMessage(bytes)
              [] tag = MarketWideCircuitBreakerDeclineLevelStatusSnapshotMessageCode -> DecodeMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage(bytes)
              [] tag = ConsolidatedSnapshotMessageCode -> DecodeConsolidatedSnapshotMessage(bytes)
              [] tag = ParticipantSnapshotMessageCode -> DecodeParticipantSnapshotMessage(bytes)
              [] tag = FinraSnapshotMessageCode -> DecodeFinraSnapshotMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSnapshotMessagePayload == [tag |-> LineIntegrityMessageCode, body |-> ZeroLineIntegrityMessage]

(* Each Snapshot Message Payload in turn, at the values the message it names is checked at *)
CheckedSnapshotMessagePayload ==
    { [tag |-> LineIntegrityMessageCode, body |-> one] : one \in CheckedLineIntegrityMessage }
        \cup { [tag |-> SymbolReferenceDataMessageCode, body |-> one] : one \in CheckedSymbolReferenceDataMessage }
        \cup { [tag |-> MarketWideCircuitBreakerDeclineLevelStatusSnapshotMessageCode, body |-> one] : one \in CheckedMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage }
        \cup { [tag |-> ConsolidatedSnapshotMessageCode, body |-> one] : one \in CheckedConsolidatedSnapshotMessage }
        \cup { [tag |-> ParticipantSnapshotMessageCode, body |-> one] : one \in CheckedParticipantSnapshotMessage }
        \cup { [tag |-> FinraSnapshotMessageCode, body |-> one] : one \in CheckedFinraSnapshotMessage }

(***************************************************************************)
(* Snapshot Message                                                        *)
(***************************************************************************)

SnapshotMessage ==
    [ snapshotMessagePayload : SnapshotMessagePayload ]

EncodeSnapshotMessage(message) ==
    EncodeUIntBE(message.snapshotMessagePayload.tag, 1)
        \o EncodeSnapshotMessagePayload(message.snapshotMessagePayload)

DecodeSnapshotMessage(bytes) ==
    LET snapshotMessageType == ReadUIntBE(bytes, 1) IN IF ~snapshotMessageType.ok THEN Fail ELSE
    LET snapshotMessagePayload == DecodeSnapshotMessagePayload(snapshotMessageType.value, snapshotMessageType.rest) IN IF ~snapshotMessagePayload.ok THEN Fail ELSE
    Ok([ snapshotMessagePayload |-> snapshotMessagePayload.value ], snapshotMessagePayload.rest)

ZeroSnapshotMessage ==
    [ snapshotMessagePayload |-> ZeroSnapshotMessagePayload ]

(* Snapshot Message at zero, then each field in turn at the values it is checked at *)
CheckedSnapshotMessage ==
    { ZeroSnapshotMessage }
        \cup { [ZeroSnapshotMessage EXCEPT !.snapshotMessagePayload = one] : one \in CheckedSnapshotMessagePayload }

(***************************************************************************)
(* Category Payload, selected by Message Category                          *)
(***************************************************************************)

SnapshotMessageCode == 82  \* "R"

CategoryPayload ==
    [ tag : {SnapshotMessageCode}, body : SnapshotMessage ]

EncodeCategoryPayload(message) ==
    CASE message.tag = SnapshotMessageCode -> EncodeSnapshotMessage(message.body)

DecodeCategoryPayload(tag, bytes) ==
    LET read ==
            CASE tag = SnapshotMessageCode -> DecodeSnapshotMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroCategoryPayload == [tag |-> SnapshotMessageCode, body |-> ZeroSnapshotMessage]

(* Each Category Payload in turn, at the values the message it names is checked at *)
CheckedCategoryPayload ==
    { [tag |-> SnapshotMessageCode, body |-> one] : one \in CheckedSnapshotMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ categoryPayload : CategoryPayload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.categoryPayload.tag, 1)
        \o EncodeCategoryPayload(message.categoryPayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET messageCategory == ReadUIntBE(bytes, 1) IN IF ~messageCategory.ok THEN Fail ELSE
    LET categoryPayload == DecodeCategoryPayload(messageCategory.value, messageCategory.rest) IN IF ~categoryPayload.ok THEN Fail ELSE
    Ok([ categoryPayload |-> categoryPayload.value ], categoryPayload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ categoryPayload |-> ZeroCategoryPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.categoryPayload = one] : one \in CheckedCategoryPayload }

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
    { [ZeroMessage EXCEPT !.categoryPayload = [tag |-> SnapshotMessageCode, body |-> ZeroSnapshotMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ version             : Sample(1),
      blockSize           : Sample(2),
      blockSequenceNumber : Sample(4),
      deliveryflag        : Sample(1),
      lastseqnum          : Sample(4),
      totpubseqrollover   : Sample(1),
      sipBlockTimestamp   : SipBlockTimestamp,
      blockChecksum       : Sample(2),
      message             : SampleLists(OneMessage),
      blockPadByte        : SampleBytes ]

EncodePacket(message) ==
    message.version
        \o message.blockSize
        \o message.blockSequenceNumber
        \o EncodeUIntBE(Len(message.message), 1)
        \o message.deliveryflag
        \o message.lastseqnum
        \o message.totpubseqrollover
        \o EncodeSipBlockTimestamp(message.sipBlockTimestamp)
        \o message.blockChecksum
        \o EncodeMessageList(message.message)
        \o message.blockPadByte

DecodePacket(bytes) ==
    LET version == ReadBytes(bytes, 1) IN IF ~version.ok THEN Fail ELSE
    LET blockSize == ReadBytes(version.rest, 2) IN IF ~blockSize.ok THEN Fail ELSE
    LET blockSequenceNumber == ReadBytes(blockSize.rest, 4) IN IF ~blockSequenceNumber.ok THEN Fail ELSE
    LET messagesInBlock == ReadUIntBE(blockSequenceNumber.rest, 1) IN IF ~messagesInBlock.ok THEN Fail ELSE
    LET deliveryflag == ReadBytes(messagesInBlock.rest, 1) IN IF ~deliveryflag.ok THEN Fail ELSE
    LET lastseqnum == ReadBytes(deliveryflag.rest, 4) IN IF ~lastseqnum.ok THEN Fail ELSE
    LET totpubseqrollover == ReadBytes(lastseqnum.rest, 1) IN IF ~totpubseqrollover.ok THEN Fail ELSE
    LET sipBlockTimestamp == DecodeSipBlockTimestamp(totpubseqrollover.rest) IN IF ~sipBlockTimestamp.ok THEN Fail ELSE
    LET blockChecksum == ReadBytes(sipBlockTimestamp.rest, 2) IN IF ~blockChecksum.ok THEN Fail ELSE
    LET message == ReadMessageList(blockChecksum.rest, messagesInBlock.value) IN IF ~message.ok THEN Fail ELSE
    LET blockPadByte == Ok(message.rest, << >>) IN IF ~blockPadByte.ok THEN Fail ELSE
    Ok([ version             |-> version.value,
         blockSize           |-> blockSize.value,
         blockSequenceNumber |-> blockSequenceNumber.value,
         deliveryflag        |-> deliveryflag.value,
         lastseqnum          |-> lastseqnum.value,
         totpubseqrollover   |-> totpubseqrollover.value,
         sipBlockTimestamp   |-> sipBlockTimestamp.value,
         blockChecksum       |-> blockChecksum.value,
         message             |-> message.value,
         blockPadByte        |-> blockPadByte.value ], blockPadByte.rest)

ZeroPacket ==
    [ version             |-> [i \in 1 .. 1 |-> 0],
      blockSize           |-> [i \in 1 .. 2 |-> 0],
      blockSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      deliveryflag        |-> [i \in 1 .. 1 |-> 0],
      lastseqnum          |-> [i \in 1 .. 4 |-> 0],
      totpubseqrollover   |-> [i \in 1 .. 1 |-> 0],
      sipBlockTimestamp   |-> ZeroSipBlockTimestamp,
      blockChecksum       |-> [i \in 1 .. 2 |-> 0],
      message             |-> << >>,
      blockPadByte        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.blockSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.blockSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.deliveryflag = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.lastseqnum = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.totpubseqrollover = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sipBlockTimestamp = one] : one \in CheckedSipBlockTimestamp }
        \cup { [ZeroPacket EXCEPT !.blockChecksum = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }
        \cup { [ZeroPacket EXCEPT !.blockPadByte = one] : one \in SampleBytes }

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

(* Every Sip Block Timestamp decodes back to what was encoded, and leaves nothing over *)
RoundTripSipBlockTimestamp ==
    \A message \in CheckedSipBlockTimestamp :
        LET read == DecodeSipBlockTimestamp(EncodeSipBlockTimestamp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Line Integrity Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLineIntegrityMessage ==
    \A message \in CheckedLineIntegrityMessage :
        LET read == DecodeLineIntegrityMessage(EncodeLineIntegrityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Reference Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolReferenceDataMessage ==
    \A message \in CheckedSymbolReferenceDataMessage :
        LET read == DecodeSymbolReferenceDataMessage(EncodeSymbolReferenceDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Wide Circuit Breaker Decline Level Status Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage ==
    \A message \in CheckedMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage :
        LET read == DecodeMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage(EncodeMarketWideCircuitBreakerDeclineLevelStatusSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Consolidated Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripConsolidatedSnapshotMessage ==
    \A message \in CheckedConsolidatedSnapshotMessage :
        LET read == DecodeConsolidatedSnapshotMessage(EncodeConsolidatedSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Participant Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripParticipantSnapshotMessage ==
    \A message \in CheckedParticipantSnapshotMessage :
        LET read == DecodeParticipantSnapshotMessage(EncodeParticipantSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Finra Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFinraSnapshotMessage ==
    \A message \in CheckedFinraSnapshotMessage :
        LET read == DecodeFinraSnapshotMessage(EncodeFinraSnapshotMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Snapshot Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSnapshotMessage ==
    \A message \in CheckedSnapshotMessage :
        LET read == DecodeSnapshotMessage(EncodeSnapshotMessage(message))
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

(* A Snapshot Message Payload is selected by the Snapshot Message Type it is written under *)
SelectsSnapshotMessagePayload ==
    \A message \in CheckedSnapshotMessagePayload :
        LET read == DecodeSnapshotMessagePayload(message.tag, EncodeSnapshotMessagePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Category Payload is selected by the Message Category it is written under *)
SelectsCategoryPayload ==
    \A message \in CheckedCategoryPayload :
        LET read == DecodeCategoryPayload(message.tag, EncodeCategoryPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
