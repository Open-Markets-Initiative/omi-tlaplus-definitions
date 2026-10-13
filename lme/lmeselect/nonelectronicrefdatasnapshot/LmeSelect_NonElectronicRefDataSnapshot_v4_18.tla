----------- MODULE LmeSelect_NonElectronicRefDataSnapshot_v4_18 ------------
(***************************************************************************)
(* The London Metal Exchange LMEsource NonElectronicRefData Refresh v4.18  *)
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
(* Sequence Reset Message: 4 bytes                                         *)
(***************************************************************************)

SequenceResetMessage ==
    [ newSeqNo : Sample(4) ]

EncodeSequenceResetMessage(message) ==
    message.newSeqNo

DecodeSequenceResetMessage(bytes) ==
    LET newSeqNo == ReadBytes(bytes, 4) IN IF ~newSeqNo.ok THEN Fail ELSE
    Ok([ newSeqNo |-> newSeqNo.value ], newSeqNo.rest)

ZeroSequenceResetMessage ==
    [ newSeqNo |-> [i \in 1 .. 4 |-> 0] ]

(* Sequence Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceResetMessage ==
    { ZeroSequenceResetMessage }
        \cup { [ZeroSequenceResetMessage EXCEPT !.newSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Definition Message: 99 bytes                                 *)
(***************************************************************************)

InstrumentDefinitionMessage ==
    [ instrumentId           : Sample(8),
      name                   : Sample(40),
      contractCode           : Sample(12),
      underlyingInstrumentId : Sample(8),
      expiryDate             : Sample(4),
      strikePrice            : Sample(8),
      optionType             : Sample(1),
      cfiCode                : Sample(6),
      isin                   : Sample(12) ]

EncodeInstrumentDefinitionMessage(message) ==
    message.instrumentId
        \o message.name
        \o message.contractCode
        \o message.underlyingInstrumentId
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.cfiCode
        \o message.isin

DecodeInstrumentDefinitionMessage(bytes) ==
    LET instrumentId == ReadBytes(bytes, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET name == ReadBytes(instrumentId.rest, 40) IN IF ~name.ok THEN Fail ELSE
    LET contractCode == ReadBytes(name.rest, 12) IN IF ~contractCode.ok THEN Fail ELSE
    LET underlyingInstrumentId == ReadBytes(contractCode.rest, 8) IN IF ~underlyingInstrumentId.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(underlyingInstrumentId.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(optionType.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET isin == ReadBytes(cfiCode.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    Ok([ instrumentId           |-> instrumentId.value,
         name                   |-> name.value,
         contractCode           |-> contractCode.value,
         underlyingInstrumentId |-> underlyingInstrumentId.value,
         expiryDate             |-> expiryDate.value,
         strikePrice            |-> strikePrice.value,
         optionType             |-> optionType.value,
         cfiCode                |-> cfiCode.value,
         isin                   |-> isin.value ], isin.rest)

ZeroInstrumentDefinitionMessage ==
    [ instrumentId           |-> [i \in 1 .. 8 |-> 0],
      name                   |-> [i \in 1 .. 40 |-> 0],
      contractCode           |-> [i \in 1 .. 12 |-> 0],
      underlyingInstrumentId |-> [i \in 1 .. 8 |-> 0],
      expiryDate             |-> [i \in 1 .. 4 |-> 0],
      strikePrice            |-> [i \in 1 .. 8 |-> 0],
      optionType             |-> [i \in 1 .. 1 |-> 0],
      cfiCode                |-> [i \in 1 .. 6 |-> 0],
      isin                   |-> [i \in 1 .. 12 |-> 0] ]

(* Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentDefinitionMessage ==
    { ZeroInstrumentDefinitionMessage }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.name = one] : one \in Sample(40) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.contractCode = one] : one \in Sample(12) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.underlyingInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroInstrumentDefinitionMessage EXCEPT !.isin = one] : one \in Sample(12) }

(***************************************************************************)
(* Definition Legs: 29 bytes                                               *)
(***************************************************************************)

DefinitionLegs ==
    [ legNumber               : Sample(4),
      legBuySell              : Sample(1),
      legRatio                : Sample(8),
      legDeltaHedgePrice      : Sample(8),
      legTradableInstrumentId : Sample(8) ]

EncodeDefinitionLegs(message) ==
    message.legNumber
        \o message.legBuySell
        \o message.legRatio
        \o message.legDeltaHedgePrice
        \o message.legTradableInstrumentId

DecodeDefinitionLegs(bytes) ==
    LET legNumber == ReadBytes(bytes, 4) IN IF ~legNumber.ok THEN Fail ELSE
    LET legBuySell == ReadBytes(legNumber.rest, 1) IN IF ~legBuySell.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legBuySell.rest, 8) IN IF ~legRatio.ok THEN Fail ELSE
    LET legDeltaHedgePrice == ReadBytes(legRatio.rest, 8) IN IF ~legDeltaHedgePrice.ok THEN Fail ELSE
    LET legTradableInstrumentId == ReadBytes(legDeltaHedgePrice.rest, 8) IN IF ~legTradableInstrumentId.ok THEN Fail ELSE
    Ok([ legNumber               |-> legNumber.value,
         legBuySell              |-> legBuySell.value,
         legRatio                |-> legRatio.value,
         legDeltaHedgePrice      |-> legDeltaHedgePrice.value,
         legTradableInstrumentId |-> legTradableInstrumentId.value ], legTradableInstrumentId.rest)

ZeroDefinitionLegs ==
    [ legNumber               |-> [i \in 1 .. 4 |-> 0],
      legBuySell              |-> [i \in 1 .. 1 |-> 0],
      legRatio                |-> [i \in 1 .. 8 |-> 0],
      legDeltaHedgePrice      |-> [i \in 1 .. 8 |-> 0],
      legTradableInstrumentId |-> [i \in 1 .. 8 |-> 0] ]

(* Definition Legs at zero, then each field in turn at the values it is checked at *)
CheckedDefinitionLegs ==
    { ZeroDefinitionLegs }
        \cup { [ZeroDefinitionLegs EXCEPT !.legNumber = one] : one \in Sample(4) }
        \cup { [ZeroDefinitionLegs EXCEPT !.legBuySell = one] : one \in Sample(1) }
        \cup { [ZeroDefinitionLegs EXCEPT !.legRatio = one] : one \in Sample(8) }
        \cup { [ZeroDefinitionLegs EXCEPT !.legDeltaHedgePrice = one] : one \in Sample(8) }
        \cup { [ZeroDefinitionLegs EXCEPT !.legTradableInstrumentId = one] : one \in Sample(8) }

(* A run of Definition Legs, written one after another *)
RECURSIVE EncodeDefinitionLegsList(_)
EncodeDefinitionLegsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDefinitionLegs(Head(messages)) \o EncodeDefinitionLegsList(Tail(messages))

(* As many Definition Legs as the field that counts them says *)
RECURSIVE ReadDefinitionLegsList(_, _)
ReadDefinitionLegsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDefinitionLegs(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDefinitionLegsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Definition Legs of each kind, for the lists that carry them *)
OneDefinitionLegs == { ZeroDefinitionLegs }

(***************************************************************************)
(* Tradable Instrument Definition Message                                  *)
(***************************************************************************)

TradableInstrumentDefinitionMessage ==
    [ tradableInstrumentId           : Sample(8),
      instrumentId                   : Sample(8),
      tradingVenue                   : Sample(2),
      businessDaysToExpiry           : Sample(4),
      lastTradingDate                : Sample(4),
      tickSizeId                     : Sample(4),
      contractCode                   : Sample(12),
      contractType                   : Sample(1),
      instrumentType                 : Sample(1),
      tradingCurrency                : Sample(3),
      marketCode                     : Sample(4),
      marketSegmentCode              : Sample(12),
      productCode                    : Sample(2),
      underlyingTradableInstrumentId : Sample(8),
      settlementDate                 : Sample(4),
      expiryDate                     : Sample(4),
      optionType                     : Sample(1),
      strikePrice                    : Sample(8),
      cfiCode                        : Sample(6),
      isin                           : Sample(12),
      tradeAtReference               : Sample(1),
      priceCode                      : Sample(2),
      promptDateLabel                : Sample(6),
      promptType                     : Sample(1),
      optionStrikeRelativePosition   : Sample(4),
      strategyTypeCode               : Sample(4),
      remainingRecords               : Sample(2),
      strategyLegCount               : Sample(4),
      definitionLegs                 : SampleLists(OneDefinitionLegs) ]

EncodeTradableInstrumentDefinitionMessage(message) ==
    message.tradableInstrumentId
        \o message.instrumentId
        \o message.tradingVenue
        \o message.businessDaysToExpiry
        \o message.lastTradingDate
        \o message.tickSizeId
        \o message.contractCode
        \o message.contractType
        \o message.instrumentType
        \o message.tradingCurrency
        \o message.marketCode
        \o message.marketSegmentCode
        \o message.productCode
        \o message.underlyingTradableInstrumentId
        \o message.settlementDate
        \o message.expiryDate
        \o message.optionType
        \o message.strikePrice
        \o message.cfiCode
        \o message.isin
        \o message.tradeAtReference
        \o message.priceCode
        \o message.promptDateLabel
        \o message.promptType
        \o message.optionStrikeRelativePosition
        \o message.strategyTypeCode
        \o message.remainingRecords
        \o EncodeUIntLE(Len(message.definitionLegs), 2)
        \o message.strategyLegCount
        \o EncodeDefinitionLegsList(message.definitionLegs)

DecodeTradableInstrumentDefinitionMessage(bytes) ==
    LET tradableInstrumentId == ReadBytes(bytes, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(tradableInstrumentId.rest, 8) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradingVenue == ReadBytes(instrumentId.rest, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET businessDaysToExpiry == ReadBytes(tradingVenue.rest, 4) IN IF ~businessDaysToExpiry.ok THEN Fail ELSE
    LET lastTradingDate == ReadBytes(businessDaysToExpiry.rest, 4) IN IF ~lastTradingDate.ok THEN Fail ELSE
    LET tickSizeId == ReadBytes(lastTradingDate.rest, 4) IN IF ~tickSizeId.ok THEN Fail ELSE
    LET contractCode == ReadBytes(tickSizeId.rest, 12) IN IF ~contractCode.ok THEN Fail ELSE
    LET contractType == ReadBytes(contractCode.rest, 1) IN IF ~contractType.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(contractType.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(instrumentType.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET marketCode == ReadBytes(tradingCurrency.rest, 4) IN IF ~marketCode.ok THEN Fail ELSE
    LET marketSegmentCode == ReadBytes(marketCode.rest, 12) IN IF ~marketSegmentCode.ok THEN Fail ELSE
    LET productCode == ReadBytes(marketSegmentCode.rest, 2) IN IF ~productCode.ok THEN Fail ELSE
    LET underlyingTradableInstrumentId == ReadBytes(productCode.rest, 8) IN IF ~underlyingTradableInstrumentId.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(underlyingTradableInstrumentId.rest, 4) IN IF ~settlementDate.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(settlementDate.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET optionType == ReadBytes(expiryDate.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(optionType.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(strikePrice.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET isin == ReadBytes(cfiCode.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET tradeAtReference == ReadBytes(isin.rest, 1) IN IF ~tradeAtReference.ok THEN Fail ELSE
    LET priceCode == ReadBytes(tradeAtReference.rest, 2) IN IF ~priceCode.ok THEN Fail ELSE
    LET promptDateLabel == ReadBytes(priceCode.rest, 6) IN IF ~promptDateLabel.ok THEN Fail ELSE
    LET promptType == ReadBytes(promptDateLabel.rest, 1) IN IF ~promptType.ok THEN Fail ELSE
    LET optionStrikeRelativePosition == ReadBytes(promptType.rest, 4) IN IF ~optionStrikeRelativePosition.ok THEN Fail ELSE
    LET strategyTypeCode == ReadBytes(optionStrikeRelativePosition.rest, 4) IN IF ~strategyTypeCode.ok THEN Fail ELSE
    LET remainingRecords == ReadBytes(strategyTypeCode.rest, 2) IN IF ~remainingRecords.ok THEN Fail ELSE
    LET recordCount == ReadUIntLE(remainingRecords.rest, 2) IN IF ~recordCount.ok THEN Fail ELSE
    LET strategyLegCount == ReadBytes(recordCount.rest, 4) IN IF ~strategyLegCount.ok THEN Fail ELSE
    LET definitionLegs == ReadDefinitionLegsList(strategyLegCount.rest, recordCount.value) IN IF ~definitionLegs.ok THEN Fail ELSE
    Ok([ tradableInstrumentId           |-> tradableInstrumentId.value,
         instrumentId                   |-> instrumentId.value,
         tradingVenue                   |-> tradingVenue.value,
         businessDaysToExpiry           |-> businessDaysToExpiry.value,
         lastTradingDate                |-> lastTradingDate.value,
         tickSizeId                     |-> tickSizeId.value,
         contractCode                   |-> contractCode.value,
         contractType                   |-> contractType.value,
         instrumentType                 |-> instrumentType.value,
         tradingCurrency                |-> tradingCurrency.value,
         marketCode                     |-> marketCode.value,
         marketSegmentCode              |-> marketSegmentCode.value,
         productCode                    |-> productCode.value,
         underlyingTradableInstrumentId |-> underlyingTradableInstrumentId.value,
         settlementDate                 |-> settlementDate.value,
         expiryDate                     |-> expiryDate.value,
         optionType                     |-> optionType.value,
         strikePrice                    |-> strikePrice.value,
         cfiCode                        |-> cfiCode.value,
         isin                           |-> isin.value,
         tradeAtReference               |-> tradeAtReference.value,
         priceCode                      |-> priceCode.value,
         promptDateLabel                |-> promptDateLabel.value,
         promptType                     |-> promptType.value,
         optionStrikeRelativePosition   |-> optionStrikeRelativePosition.value,
         strategyTypeCode               |-> strategyTypeCode.value,
         remainingRecords               |-> remainingRecords.value,
         strategyLegCount               |-> strategyLegCount.value,
         definitionLegs                 |-> definitionLegs.value ], definitionLegs.rest)

ZeroTradableInstrumentDefinitionMessage ==
    [ tradableInstrumentId           |-> [i \in 1 .. 8 |-> 0],
      instrumentId                   |-> [i \in 1 .. 8 |-> 0],
      tradingVenue                   |-> [i \in 1 .. 2 |-> 0],
      businessDaysToExpiry           |-> [i \in 1 .. 4 |-> 0],
      lastTradingDate                |-> [i \in 1 .. 4 |-> 0],
      tickSizeId                     |-> [i \in 1 .. 4 |-> 0],
      contractCode                   |-> [i \in 1 .. 12 |-> 0],
      contractType                   |-> [i \in 1 .. 1 |-> 0],
      instrumentType                 |-> [i \in 1 .. 1 |-> 0],
      tradingCurrency                |-> [i \in 1 .. 3 |-> 0],
      marketCode                     |-> [i \in 1 .. 4 |-> 0],
      marketSegmentCode              |-> [i \in 1 .. 12 |-> 0],
      productCode                    |-> [i \in 1 .. 2 |-> 0],
      underlyingTradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      settlementDate                 |-> [i \in 1 .. 4 |-> 0],
      expiryDate                     |-> [i \in 1 .. 4 |-> 0],
      optionType                     |-> [i \in 1 .. 1 |-> 0],
      strikePrice                    |-> [i \in 1 .. 8 |-> 0],
      cfiCode                        |-> [i \in 1 .. 6 |-> 0],
      isin                           |-> [i \in 1 .. 12 |-> 0],
      tradeAtReference               |-> [i \in 1 .. 1 |-> 0],
      priceCode                      |-> [i \in 1 .. 2 |-> 0],
      promptDateLabel                |-> [i \in 1 .. 6 |-> 0],
      promptType                     |-> [i \in 1 .. 1 |-> 0],
      optionStrikeRelativePosition   |-> [i \in 1 .. 4 |-> 0],
      strategyTypeCode               |-> [i \in 1 .. 4 |-> 0],
      remainingRecords               |-> [i \in 1 .. 2 |-> 0],
      strategyLegCount               |-> [i \in 1 .. 4 |-> 0],
      definitionLegs                 |-> << >> ]

(* Tradable Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedTradableInstrumentDefinitionMessage ==
    { ZeroTradableInstrumentDefinitionMessage }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.instrumentId = one] : one \in Sample(8) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.businessDaysToExpiry = one] : one \in Sample(4) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.lastTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.tickSizeId = one] : one \in Sample(4) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.contractCode = one] : one \in Sample(12) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.contractType = one] : one \in Sample(1) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.marketCode = one] : one \in Sample(4) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.marketSegmentCode = one] : one \in Sample(12) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.productCode = one] : one \in Sample(2) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.underlyingTradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.settlementDate = one] : one \in Sample(4) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.tradeAtReference = one] : one \in Sample(1) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.priceCode = one] : one \in Sample(2) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.promptDateLabel = one] : one \in Sample(6) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.promptType = one] : one \in Sample(1) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.optionStrikeRelativePosition = one] : one \in Sample(4) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.strategyTypeCode = one] : one \in Sample(4) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.remainingRecords = one] : one \in Sample(2) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.strategyLegCount = one] : one \in Sample(4) }
        \cup { [ZeroTradableInstrumentDefinitionMessage EXCEPT !.definitionLegs = one] : one \in SampleLists(OneDefinitionLegs) }

(***************************************************************************)
(* Order Statistics Intraday Message: 36 bytes                             *)
(***************************************************************************)

OrderStatisticsIntradayMessage ==
    [ timeOfEvent          : Sample(8),
      tradableInstrumentId : Sample(8),
      tradingVenue         : Sample(2),
      ringSession          : Sample(2),
      orderHigh            : Sample(8),
      orderLow             : Sample(8) ]

EncodeOrderStatisticsIntradayMessage(message) ==
    message.timeOfEvent
        \o message.tradableInstrumentId
        \o message.tradingVenue
        \o message.ringSession
        \o message.orderHigh
        \o message.orderLow

DecodeOrderStatisticsIntradayMessage(bytes) ==
    LET timeOfEvent == ReadBytes(bytes, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(timeOfEvent.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET tradingVenue == ReadBytes(tradableInstrumentId.rest, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET ringSession == ReadBytes(tradingVenue.rest, 2) IN IF ~ringSession.ok THEN Fail ELSE
    LET orderHigh == ReadBytes(ringSession.rest, 8) IN IF ~orderHigh.ok THEN Fail ELSE
    LET orderLow == ReadBytes(orderHigh.rest, 8) IN IF ~orderLow.ok THEN Fail ELSE
    Ok([ timeOfEvent          |-> timeOfEvent.value,
         tradableInstrumentId |-> tradableInstrumentId.value,
         tradingVenue         |-> tradingVenue.value,
         ringSession          |-> ringSession.value,
         orderHigh            |-> orderHigh.value,
         orderLow             |-> orderLow.value ], orderLow.rest)

ZeroOrderStatisticsIntradayMessage ==
    [ timeOfEvent          |-> [i \in 1 .. 8 |-> 0],
      tradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      tradingVenue         |-> [i \in 1 .. 2 |-> 0],
      ringSession          |-> [i \in 1 .. 2 |-> 0],
      orderHigh            |-> [i \in 1 .. 8 |-> 0],
      orderLow             |-> [i \in 1 .. 8 |-> 0] ]

(* Order Statistics Intraday Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderStatisticsIntradayMessage ==
    { ZeroOrderStatisticsIntradayMessage }
        \cup { [ZeroOrderStatisticsIntradayMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatisticsIntradayMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatisticsIntradayMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatisticsIntradayMessage EXCEPT !.ringSession = one] : one \in Sample(2) }
        \cup { [ZeroOrderStatisticsIntradayMessage EXCEPT !.orderHigh = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatisticsIntradayMessage EXCEPT !.orderLow = one] : one \in Sample(8) }

(***************************************************************************)
(* Refresh Complete Message: 4 bytes                                       *)
(***************************************************************************)

RefreshCompleteMessage ==
    [ lastSeqNum : Sample(4) ]

EncodeRefreshCompleteMessage(message) ==
    message.lastSeqNum

DecodeRefreshCompleteMessage(bytes) ==
    LET lastSeqNum == ReadBytes(bytes, 4) IN IF ~lastSeqNum.ok THEN Fail ELSE
    Ok([ lastSeqNum |-> lastSeqNum.value ], lastSeqNum.rest)

ZeroRefreshCompleteMessage ==
    [ lastSeqNum |-> [i \in 1 .. 4 |-> 0] ]

(* Refresh Complete Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshCompleteMessage ==
    { ZeroRefreshCompleteMessage }
        \cup { [ZeroRefreshCompleteMessage EXCEPT !.lastSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

SequenceResetMessageCode == 100  \* 0x64
InstrumentDefinitionMessageCode == 303  \* 0x12f
TradableInstrumentDefinitionMessageCode == 304  \* 0x130
OrderStatisticsIntradayMessageCode == 350  \* 0x15e
RefreshCompleteMessageCode == 203  \* 0xcb

Payload ==
    [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {InstrumentDefinitionMessageCode}, body : InstrumentDefinitionMessage ]
        \cup [ tag : {TradableInstrumentDefinitionMessageCode}, body : TradableInstrumentDefinitionMessage ]
        \cup [ tag : {OrderStatisticsIntradayMessageCode}, body : OrderStatisticsIntradayMessage ]
        \cup [ tag : {RefreshCompleteMessageCode}, body : RefreshCompleteMessage ]

EncodePayload(message) ==
    CASE message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = InstrumentDefinitionMessageCode -> EncodeInstrumentDefinitionMessage(message.body)
      [] message.tag = TradableInstrumentDefinitionMessageCode -> EncodeTradableInstrumentDefinitionMessage(message.body)
      [] message.tag = OrderStatisticsIntradayMessageCode -> EncodeOrderStatisticsIntradayMessage(message.body)
      [] message.tag = RefreshCompleteMessageCode -> EncodeRefreshCompleteMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = InstrumentDefinitionMessageCode -> DecodeInstrumentDefinitionMessage(bytes)
              [] tag = TradableInstrumentDefinitionMessageCode -> DecodeTradableInstrumentDefinitionMessage(bytes)
              [] tag = OrderStatisticsIntradayMessageCode -> DecodeOrderStatisticsIntradayMessage(bytes)
              [] tag = RefreshCompleteMessageCode -> DecodeRefreshCompleteMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }
        \cup { [tag |-> InstrumentDefinitionMessageCode, body |-> one] : one \in CheckedInstrumentDefinitionMessage }
        \cup { [tag |-> TradableInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedTradableInstrumentDefinitionMessage }
        \cup { [tag |-> OrderStatisticsIntradayMessageCode, body |-> one] : one \in CheckedOrderStatisticsIntradayMessage }
        \cup { [tag |-> RefreshCompleteMessageCode, body |-> one] : one \in CheckedRefreshCompleteMessage }

(***************************************************************************)
(* Messages                                                                *)
(***************************************************************************)

Messages ==
    [ msgSize : 0 .. 255,
      payload : Payload ]

EncodeMessages(message) ==
    EncodeUIntLE(message.msgSize, 2)
        \o EncodeUIntLE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

DecodeMessages(bytes) ==
    LET msgSize == ReadUIntLE(bytes, 2) IN IF ~msgSize.ok THEN Fail ELSE
    LET msgType == ReadUIntLE(msgSize.rest, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, msgType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ msgSize |-> msgSize.value,
         payload |-> payload.value ], payload.rest)

ZeroMessages ==
    [ msgSize |-> 0,
      payload |-> ZeroPayload ]

(* Messages at zero, then each field in turn at the values it is checked at *)
CheckedMessages ==
    { ZeroMessages }
        \cup { [ZeroMessages EXCEPT !.msgSize = one] : one \in {0, 1, 255} }
        \cup { [ZeroMessages EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Messages, written one after another *)
RECURSIVE EncodeMessagesList(_)
EncodeMessagesList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMessages(Head(messages)) \o EncodeMessagesList(Tail(messages))

(* As many Messages as the field that counts them says *)
RECURSIVE ReadMessagesList(_, _)
ReadMessagesList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMessages(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessagesList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Messages of each kind, for the lists that carry them *)
OneMessages ==
    { [ZeroMessages EXCEPT !.payload = [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> InstrumentDefinitionMessageCode, body |-> ZeroInstrumentDefinitionMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> TradableInstrumentDefinitionMessageCode, body |-> ZeroTradableInstrumentDefinitionMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> OrderStatisticsIntradayMessageCode, body |-> ZeroOrderStatisticsIntradayMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> RefreshCompleteMessageCode, body |-> ZeroRefreshCompleteMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ pktSize  : Sample(2),
      filler   : Sample(1),
      seqNum   : Sample(4),
      sendTime : Sample(8),
      messages : SampleLists(OneMessages) ]

EncodePacket(message) ==
    message.pktSize
        \o EncodeUIntBE(Len(message.messages), 1)
        \o message.filler
        \o message.seqNum
        \o message.sendTime
        \o EncodeMessagesList(message.messages)

DecodePacket(bytes) ==
    LET pktSize == ReadBytes(bytes, 2) IN IF ~pktSize.ok THEN Fail ELSE
    LET msgCount == ReadUIntBE(pktSize.rest, 1) IN IF ~msgCount.ok THEN Fail ELSE
    LET filler == ReadBytes(msgCount.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET seqNum == ReadBytes(filler.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET sendTime == ReadBytes(seqNum.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET messages == ReadMessagesList(sendTime.rest, msgCount.value) IN IF ~messages.ok THEN Fail ELSE
    Ok([ pktSize  |-> pktSize.value,
         filler   |-> filler.value,
         seqNum   |-> seqNum.value,
         sendTime |-> sendTime.value,
         messages |-> messages.value ], messages.rest)

ZeroPacket ==
    [ pktSize  |-> [i \in 1 .. 2 |-> 0],
      filler   |-> [i \in 1 .. 1 |-> 0],
      seqNum   |-> [i \in 1 .. 4 |-> 0],
      sendTime |-> [i \in 1 .. 8 |-> 0],
      messages |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.pktSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.messages = one] : one \in SampleLists(OneMessages) }

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

(* Every Sequence Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceResetMessage ==
    \A message \in CheckedSequenceResetMessage :
        LET read == DecodeSequenceResetMessage(EncodeSequenceResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentDefinitionMessage ==
    \A message \in CheckedInstrumentDefinitionMessage :
        LET read == DecodeInstrumentDefinitionMessage(EncodeInstrumentDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Definition Legs decodes back to what was encoded, and leaves nothing over *)
RoundTripDefinitionLegs ==
    \A message \in CheckedDefinitionLegs :
        LET read == DecodeDefinitionLegs(EncodeDefinitionLegs(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tradable Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradableInstrumentDefinitionMessage ==
    \A message \in CheckedTradableInstrumentDefinitionMessage :
        LET read == DecodeTradableInstrumentDefinitionMessage(EncodeTradableInstrumentDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Statistics Intraday Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderStatisticsIntradayMessage ==
    \A message \in CheckedOrderStatisticsIntradayMessage :
        LET read == DecodeOrderStatisticsIntradayMessage(EncodeOrderStatisticsIntradayMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Complete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshCompleteMessage ==
    \A message \in CheckedRefreshCompleteMessage :
        LET read == DecodeRefreshCompleteMessage(EncodeRefreshCompleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Messages decodes back to what was encoded, and leaves nothing over *)
RoundTripMessages ==
    \A message \in CheckedMessages :
        LET read == DecodeMessages(EncodeMessages(message))
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

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
