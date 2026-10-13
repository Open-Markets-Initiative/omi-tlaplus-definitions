--------------- MODULE LmeSelect_Level3Retransmission_v4_18 ----------------
(***************************************************************************)
(* The London Metal Exchange LMEsource Level3 Retransmission v4.18         *)
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
(* Market State Contract Message: 42 bytes                                 *)
(***************************************************************************)

MarketStateContractMessage ==
    [ tradingVenue          : Sample(2),
      timeOfEvent           : Sample(8),
      contractCode          : Sample(12),
      tradingState          : Sample(1),
      startTime             : Sample(8),
      endTime               : Sample(8),
      tradingStateCondition : Sample(1),
      fillerString2         : Sample(2) ]

EncodeMarketStateContractMessage(message) ==
    message.tradingVenue
        \o message.timeOfEvent
        \o message.contractCode
        \o message.tradingState
        \o message.startTime
        \o message.endTime
        \o message.tradingStateCondition
        \o message.fillerString2

DecodeMarketStateContractMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET timeOfEvent == ReadBytes(tradingVenue.rest, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET contractCode == ReadBytes(timeOfEvent.rest, 12) IN IF ~contractCode.ok THEN Fail ELSE
    LET tradingState == ReadBytes(contractCode.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET startTime == ReadBytes(tradingState.rest, 8) IN IF ~startTime.ok THEN Fail ELSE
    LET endTime == ReadBytes(startTime.rest, 8) IN IF ~endTime.ok THEN Fail ELSE
    LET tradingStateCondition == ReadBytes(endTime.rest, 1) IN IF ~tradingStateCondition.ok THEN Fail ELSE
    LET fillerString2 == ReadBytes(tradingStateCondition.rest, 2) IN IF ~fillerString2.ok THEN Fail ELSE
    Ok([ tradingVenue          |-> tradingVenue.value,
         timeOfEvent           |-> timeOfEvent.value,
         contractCode          |-> contractCode.value,
         tradingState          |-> tradingState.value,
         startTime             |-> startTime.value,
         endTime               |-> endTime.value,
         tradingStateCondition |-> tradingStateCondition.value,
         fillerString2         |-> fillerString2.value ], fillerString2.rest)

ZeroMarketStateContractMessage ==
    [ tradingVenue          |-> [i \in 1 .. 2 |-> 0],
      timeOfEvent           |-> [i \in 1 .. 8 |-> 0],
      contractCode          |-> [i \in 1 .. 12 |-> 0],
      tradingState          |-> [i \in 1 .. 1 |-> 0],
      startTime             |-> [i \in 1 .. 8 |-> 0],
      endTime               |-> [i \in 1 .. 8 |-> 0],
      tradingStateCondition |-> [i \in 1 .. 1 |-> 0],
      fillerString2         |-> [i \in 1 .. 2 |-> 0] ]

(* Market State Contract Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketStateContractMessage ==
    { ZeroMarketStateContractMessage }
        \cup { [ZeroMarketStateContractMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroMarketStateContractMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroMarketStateContractMessage EXCEPT !.contractCode = one] : one \in Sample(12) }
        \cup { [ZeroMarketStateContractMessage EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroMarketStateContractMessage EXCEPT !.startTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketStateContractMessage EXCEPT !.endTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketStateContractMessage EXCEPT !.tradingStateCondition = one] : one \in Sample(1) }
        \cup { [ZeroMarketStateContractMessage EXCEPT !.fillerString2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Market State Instrument Message: 40 bytes                               *)
(***************************************************************************)

MarketStateInstrumentMessage ==
    [ tradingVenue          : Sample(2),
      timeOfEvent           : Sample(8),
      tradableInstrumentId  : Sample(8),
      timetableControlType  : Sample(1),
      tradingState          : Sample(1),
      startTime             : Sample(8),
      endTime               : Sample(8),
      tradingStateCondition : Sample(1),
      fillerString3         : Sample(3) ]

EncodeMarketStateInstrumentMessage(message) ==
    message.tradingVenue
        \o message.timeOfEvent
        \o message.tradableInstrumentId
        \o message.timetableControlType
        \o message.tradingState
        \o message.startTime
        \o message.endTime
        \o message.tradingStateCondition
        \o message.fillerString3

DecodeMarketStateInstrumentMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET timeOfEvent == ReadBytes(tradingVenue.rest, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(timeOfEvent.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET timetableControlType == ReadBytes(tradableInstrumentId.rest, 1) IN IF ~timetableControlType.ok THEN Fail ELSE
    LET tradingState == ReadBytes(timetableControlType.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET startTime == ReadBytes(tradingState.rest, 8) IN IF ~startTime.ok THEN Fail ELSE
    LET endTime == ReadBytes(startTime.rest, 8) IN IF ~endTime.ok THEN Fail ELSE
    LET tradingStateCondition == ReadBytes(endTime.rest, 1) IN IF ~tradingStateCondition.ok THEN Fail ELSE
    LET fillerString3 == ReadBytes(tradingStateCondition.rest, 3) IN IF ~fillerString3.ok THEN Fail ELSE
    Ok([ tradingVenue          |-> tradingVenue.value,
         timeOfEvent           |-> timeOfEvent.value,
         tradableInstrumentId  |-> tradableInstrumentId.value,
         timetableControlType  |-> timetableControlType.value,
         tradingState          |-> tradingState.value,
         startTime             |-> startTime.value,
         endTime               |-> endTime.value,
         tradingStateCondition |-> tradingStateCondition.value,
         fillerString3         |-> fillerString3.value ], fillerString3.rest)

ZeroMarketStateInstrumentMessage ==
    [ tradingVenue          |-> [i \in 1 .. 2 |-> 0],
      timeOfEvent           |-> [i \in 1 .. 8 |-> 0],
      tradableInstrumentId  |-> [i \in 1 .. 8 |-> 0],
      timetableControlType  |-> [i \in 1 .. 1 |-> 0],
      tradingState          |-> [i \in 1 .. 1 |-> 0],
      startTime             |-> [i \in 1 .. 8 |-> 0],
      endTime               |-> [i \in 1 .. 8 |-> 0],
      tradingStateCondition |-> [i \in 1 .. 1 |-> 0],
      fillerString3         |-> [i \in 1 .. 3 |-> 0] ]

(* Market State Instrument Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketStateInstrumentMessage ==
    { ZeroMarketStateInstrumentMessage }
        \cup { [ZeroMarketStateInstrumentMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroMarketStateInstrumentMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroMarketStateInstrumentMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroMarketStateInstrumentMessage EXCEPT !.timetableControlType = one] : one \in Sample(1) }
        \cup { [ZeroMarketStateInstrumentMessage EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroMarketStateInstrumentMessage EXCEPT !.startTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketStateInstrumentMessage EXCEPT !.endTime = one] : one \in Sample(8) }
        \cup { [ZeroMarketStateInstrumentMessage EXCEPT !.tradingStateCondition = one] : one \in Sample(1) }
        \cup { [ZeroMarketStateInstrumentMessage EXCEPT !.fillerString3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Indicative Opening Price Message: 40 bytes                              *)
(***************************************************************************)

IndicativeOpeningPriceMessage ==
    [ tradingVenue              : Sample(2),
      timeOfEvent               : Sample(8),
      tradableInstrumentId      : Sample(8),
      indicativeOpeningPrice    : Sample(8),
      indicativeOpeningVolume   : Sample(4),
      indicativeOpeningMidPrice : Sample(8),
      fillerString2             : Sample(2) ]

EncodeIndicativeOpeningPriceMessage(message) ==
    message.tradingVenue
        \o message.timeOfEvent
        \o message.tradableInstrumentId
        \o message.indicativeOpeningPrice
        \o message.indicativeOpeningVolume
        \o message.indicativeOpeningMidPrice
        \o message.fillerString2

DecodeIndicativeOpeningPriceMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET timeOfEvent == ReadBytes(tradingVenue.rest, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(timeOfEvent.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET indicativeOpeningPrice == ReadBytes(tradableInstrumentId.rest, 8) IN IF ~indicativeOpeningPrice.ok THEN Fail ELSE
    LET indicativeOpeningVolume == ReadBytes(indicativeOpeningPrice.rest, 4) IN IF ~indicativeOpeningVolume.ok THEN Fail ELSE
    LET indicativeOpeningMidPrice == ReadBytes(indicativeOpeningVolume.rest, 8) IN IF ~indicativeOpeningMidPrice.ok THEN Fail ELSE
    LET fillerString2 == ReadBytes(indicativeOpeningMidPrice.rest, 2) IN IF ~fillerString2.ok THEN Fail ELSE
    Ok([ tradingVenue              |-> tradingVenue.value,
         timeOfEvent               |-> timeOfEvent.value,
         tradableInstrumentId      |-> tradableInstrumentId.value,
         indicativeOpeningPrice    |-> indicativeOpeningPrice.value,
         indicativeOpeningVolume   |-> indicativeOpeningVolume.value,
         indicativeOpeningMidPrice |-> indicativeOpeningMidPrice.value,
         fillerString2             |-> fillerString2.value ], fillerString2.rest)

ZeroIndicativeOpeningPriceMessage ==
    [ tradingVenue              |-> [i \in 1 .. 2 |-> 0],
      timeOfEvent               |-> [i \in 1 .. 8 |-> 0],
      tradableInstrumentId      |-> [i \in 1 .. 8 |-> 0],
      indicativeOpeningPrice    |-> [i \in 1 .. 8 |-> 0],
      indicativeOpeningVolume   |-> [i \in 1 .. 4 |-> 0],
      indicativeOpeningMidPrice |-> [i \in 1 .. 8 |-> 0],
      fillerString2             |-> [i \in 1 .. 2 |-> 0] ]

(* Indicative Opening Price Message at zero, then each field in turn at the values it is checked at *)
CheckedIndicativeOpeningPriceMessage ==
    { ZeroIndicativeOpeningPriceMessage }
        \cup { [ZeroIndicativeOpeningPriceMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroIndicativeOpeningPriceMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroIndicativeOpeningPriceMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroIndicativeOpeningPriceMessage EXCEPT !.indicativeOpeningPrice = one] : one \in Sample(8) }
        \cup { [ZeroIndicativeOpeningPriceMessage EXCEPT !.indicativeOpeningVolume = one] : one \in Sample(4) }
        \cup { [ZeroIndicativeOpeningPriceMessage EXCEPT !.indicativeOpeningMidPrice = one] : one \in Sample(8) }
        \cup { [ZeroIndicativeOpeningPriceMessage EXCEPT !.fillerString2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Quote Request Message: 26 bytes                                         *)
(***************************************************************************)

QuoteRequestMessage ==
    [ tradingVenue         : Sample(2),
      timeOfEvent          : Sample(8),
      tradableInstrumentId : Sample(8),
      quoteRequestType     : Sample(1),
      buySell              : Sample(1),
      volume               : Sample(4),
      fillerString2        : Sample(2) ]

EncodeQuoteRequestMessage(message) ==
    message.tradingVenue
        \o message.timeOfEvent
        \o message.tradableInstrumentId
        \o message.quoteRequestType
        \o message.buySell
        \o message.volume
        \o message.fillerString2

DecodeQuoteRequestMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET timeOfEvent == ReadBytes(tradingVenue.rest, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(timeOfEvent.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET quoteRequestType == ReadBytes(tradableInstrumentId.rest, 1) IN IF ~quoteRequestType.ok THEN Fail ELSE
    LET buySell == ReadBytes(quoteRequestType.rest, 1) IN IF ~buySell.ok THEN Fail ELSE
    LET volume == ReadBytes(buySell.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET fillerString2 == ReadBytes(volume.rest, 2) IN IF ~fillerString2.ok THEN Fail ELSE
    Ok([ tradingVenue         |-> tradingVenue.value,
         timeOfEvent          |-> timeOfEvent.value,
         tradableInstrumentId |-> tradableInstrumentId.value,
         quoteRequestType     |-> quoteRequestType.value,
         buySell              |-> buySell.value,
         volume               |-> volume.value,
         fillerString2        |-> fillerString2.value ], fillerString2.rest)

ZeroQuoteRequestMessage ==
    [ tradingVenue         |-> [i \in 1 .. 2 |-> 0],
      timeOfEvent          |-> [i \in 1 .. 8 |-> 0],
      tradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      quoteRequestType     |-> [i \in 1 .. 1 |-> 0],
      buySell              |-> [i \in 1 .. 1 |-> 0],
      volume               |-> [i \in 1 .. 4 |-> 0],
      fillerString2        |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Request Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestMessage ==
    { ZeroQuoteRequestMessage }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.quoteRequestType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.buySell = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.fillerString2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Book Clear Message: 18 bytes                                      *)
(***************************************************************************)

OrderBookClearMessage ==
    [ tradingVenue         : Sample(2),
      timeOfEvent          : Sample(8),
      tradableInstrumentId : Sample(8) ]

EncodeOrderBookClearMessage(message) ==
    message.tradingVenue
        \o message.timeOfEvent
        \o message.tradableInstrumentId

DecodeOrderBookClearMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET timeOfEvent == ReadBytes(tradingVenue.rest, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(timeOfEvent.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    Ok([ tradingVenue         |-> tradingVenue.value,
         timeOfEvent          |-> timeOfEvent.value,
         tradableInstrumentId |-> tradableInstrumentId.value ], tradableInstrumentId.rest)

ZeroOrderBookClearMessage ==
    [ tradingVenue         |-> [i \in 1 .. 2 |-> 0],
      timeOfEvent          |-> [i \in 1 .. 8 |-> 0],
      tradableInstrumentId |-> [i \in 1 .. 8 |-> 0] ]

(* Order Book Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookClearMessage ==
    { ZeroOrderBookClearMessage }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }

(***************************************************************************)
(* Cross Request Message: 40 bytes                                         *)
(***************************************************************************)

CrossRequestMessage ==
    [ tradingVenue         : Sample(2),
      timeOfEvent          : Sample(8),
      tradableInstrumentId : Sample(8),
      crossId              : Sample(8),
      volume               : Sample(4),
      expireTime           : Sample(8),
      fillerString2        : Sample(2) ]

EncodeCrossRequestMessage(message) ==
    message.tradingVenue
        \o message.timeOfEvent
        \o message.tradableInstrumentId
        \o message.crossId
        \o message.volume
        \o message.expireTime
        \o message.fillerString2

DecodeCrossRequestMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET timeOfEvent == ReadBytes(tradingVenue.rest, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(timeOfEvent.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET crossId == ReadBytes(tradableInstrumentId.rest, 8) IN IF ~crossId.ok THEN Fail ELSE
    LET volume == ReadBytes(crossId.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET expireTime == ReadBytes(volume.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET fillerString2 == ReadBytes(expireTime.rest, 2) IN IF ~fillerString2.ok THEN Fail ELSE
    Ok([ tradingVenue         |-> tradingVenue.value,
         timeOfEvent          |-> timeOfEvent.value,
         tradableInstrumentId |-> tradableInstrumentId.value,
         crossId              |-> crossId.value,
         volume               |-> volume.value,
         expireTime           |-> expireTime.value,
         fillerString2        |-> fillerString2.value ], fillerString2.rest)

ZeroCrossRequestMessage ==
    [ tradingVenue         |-> [i \in 1 .. 2 |-> 0],
      timeOfEvent          |-> [i \in 1 .. 8 |-> 0],
      tradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      crossId              |-> [i \in 1 .. 8 |-> 0],
      volume               |-> [i \in 1 .. 4 |-> 0],
      expireTime           |-> [i \in 1 .. 8 |-> 0],
      fillerString2        |-> [i \in 1 .. 2 |-> 0] ]

(* Cross Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossRequestMessage ==
    { ZeroCrossRequestMessage }
        \cup { [ZeroCrossRequestMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroCrossRequestMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequestMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequestMessage EXCEPT !.crossId = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequestMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroCrossRequestMessage EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroCrossRequestMessage EXCEPT !.fillerString2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Add Message: 68 bytes                                             *)
(***************************************************************************)

OrderAddMessage ==
    [ tradingVenue         : Sample(2),
      timeOfEvent          : Sample(8),
      t1                   : Sample(8),
      t2                   : Sample(8),
      t3                   : Sample(8),
      tradableInstrumentId : Sample(8),
      orderId              : Sample(8),
      buySell              : Sample(1),
      volume               : Sample(4),
      price                : Sample(8),
      orderBookPosition    : Sample(4),
      fillerString1        : Sample(1) ]

EncodeOrderAddMessage(message) ==
    message.tradingVenue
        \o message.timeOfEvent
        \o message.t1
        \o message.t2
        \o message.t3
        \o message.tradableInstrumentId
        \o message.orderId
        \o message.buySell
        \o message.volume
        \o message.price
        \o message.orderBookPosition
        \o message.fillerString1

DecodeOrderAddMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET timeOfEvent == ReadBytes(tradingVenue.rest, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET t1 == ReadBytes(timeOfEvent.rest, 8) IN IF ~t1.ok THEN Fail ELSE
    LET t2 == ReadBytes(t1.rest, 8) IN IF ~t2.ok THEN Fail ELSE
    LET t3 == ReadBytes(t2.rest, 8) IN IF ~t3.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(t3.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(tradableInstrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET buySell == ReadBytes(orderId.rest, 1) IN IF ~buySell.ok THEN Fail ELSE
    LET volume == ReadBytes(buySell.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderBookPosition == ReadBytes(price.rest, 4) IN IF ~orderBookPosition.ok THEN Fail ELSE
    LET fillerString1 == ReadBytes(orderBookPosition.rest, 1) IN IF ~fillerString1.ok THEN Fail ELSE
    Ok([ tradingVenue         |-> tradingVenue.value,
         timeOfEvent          |-> timeOfEvent.value,
         t1                   |-> t1.value,
         t2                   |-> t2.value,
         t3                   |-> t3.value,
         tradableInstrumentId |-> tradableInstrumentId.value,
         orderId              |-> orderId.value,
         buySell              |-> buySell.value,
         volume               |-> volume.value,
         price                |-> price.value,
         orderBookPosition    |-> orderBookPosition.value,
         fillerString1        |-> fillerString1.value ], fillerString1.rest)

ZeroOrderAddMessage ==
    [ tradingVenue         |-> [i \in 1 .. 2 |-> 0],
      timeOfEvent          |-> [i \in 1 .. 8 |-> 0],
      t1                   |-> [i \in 1 .. 8 |-> 0],
      t2                   |-> [i \in 1 .. 8 |-> 0],
      t3                   |-> [i \in 1 .. 8 |-> 0],
      tradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      buySell              |-> [i \in 1 .. 1 |-> 0],
      volume               |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      orderBookPosition    |-> [i \in 1 .. 4 |-> 0],
      fillerString1        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Add Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddMessage ==
    { ZeroOrderAddMessage }
        \cup { [ZeroOrderAddMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroOrderAddMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.t1 = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.t2 = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.t3 = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.buySell = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.orderBookPosition = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddMessage EXCEPT !.fillerString1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Amend Message: 68 bytes                                           *)
(***************************************************************************)

OrderAmendMessage ==
    [ tradingVenue         : Sample(2),
      timeOfEvent          : Sample(8),
      t1                   : Sample(8),
      t2                   : Sample(8),
      t3                   : Sample(8),
      tradableInstrumentId : Sample(8),
      orderId              : Sample(8),
      buySell              : Sample(1),
      volume               : Sample(4),
      price                : Sample(8),
      orderBookPosition    : Sample(4),
      fillerString1        : Sample(1) ]

EncodeOrderAmendMessage(message) ==
    message.tradingVenue
        \o message.timeOfEvent
        \o message.t1
        \o message.t2
        \o message.t3
        \o message.tradableInstrumentId
        \o message.orderId
        \o message.buySell
        \o message.volume
        \o message.price
        \o message.orderBookPosition
        \o message.fillerString1

DecodeOrderAmendMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET timeOfEvent == ReadBytes(tradingVenue.rest, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET t1 == ReadBytes(timeOfEvent.rest, 8) IN IF ~t1.ok THEN Fail ELSE
    LET t2 == ReadBytes(t1.rest, 8) IN IF ~t2.ok THEN Fail ELSE
    LET t3 == ReadBytes(t2.rest, 8) IN IF ~t3.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(t3.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(tradableInstrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET buySell == ReadBytes(orderId.rest, 1) IN IF ~buySell.ok THEN Fail ELSE
    LET volume == ReadBytes(buySell.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderBookPosition == ReadBytes(price.rest, 4) IN IF ~orderBookPosition.ok THEN Fail ELSE
    LET fillerString1 == ReadBytes(orderBookPosition.rest, 1) IN IF ~fillerString1.ok THEN Fail ELSE
    Ok([ tradingVenue         |-> tradingVenue.value,
         timeOfEvent          |-> timeOfEvent.value,
         t1                   |-> t1.value,
         t2                   |-> t2.value,
         t3                   |-> t3.value,
         tradableInstrumentId |-> tradableInstrumentId.value,
         orderId              |-> orderId.value,
         buySell              |-> buySell.value,
         volume               |-> volume.value,
         price                |-> price.value,
         orderBookPosition    |-> orderBookPosition.value,
         fillerString1        |-> fillerString1.value ], fillerString1.rest)

ZeroOrderAmendMessage ==
    [ tradingVenue         |-> [i \in 1 .. 2 |-> 0],
      timeOfEvent          |-> [i \in 1 .. 8 |-> 0],
      t1                   |-> [i \in 1 .. 8 |-> 0],
      t2                   |-> [i \in 1 .. 8 |-> 0],
      t3                   |-> [i \in 1 .. 8 |-> 0],
      tradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      buySell              |-> [i \in 1 .. 1 |-> 0],
      volume               |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      orderBookPosition    |-> [i \in 1 .. 4 |-> 0],
      fillerString1        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Amend Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAmendMessage ==
    { ZeroOrderAmendMessage }
        \cup { [ZeroOrderAmendMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroOrderAmendMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroOrderAmendMessage EXCEPT !.t1 = one] : one \in Sample(8) }
        \cup { [ZeroOrderAmendMessage EXCEPT !.t2 = one] : one \in Sample(8) }
        \cup { [ZeroOrderAmendMessage EXCEPT !.t3 = one] : one \in Sample(8) }
        \cup { [ZeroOrderAmendMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAmendMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAmendMessage EXCEPT !.buySell = one] : one \in Sample(1) }
        \cup { [ZeroOrderAmendMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderAmendMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAmendMessage EXCEPT !.orderBookPosition = one] : one \in Sample(4) }
        \cup { [ZeroOrderAmendMessage EXCEPT !.fillerString1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Cancel Message: 52 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ tradingVenue         : Sample(2),
      timeOfEvent          : Sample(8),
      t1                   : Sample(8),
      t2                   : Sample(8),
      t3                   : Sample(8),
      tradableInstrumentId : Sample(8),
      orderId              : Sample(8),
      buySell              : Sample(1),
      fillerString1        : Sample(1) ]

EncodeOrderCancelMessage(message) ==
    message.tradingVenue
        \o message.timeOfEvent
        \o message.t1
        \o message.t2
        \o message.t3
        \o message.tradableInstrumentId
        \o message.orderId
        \o message.buySell
        \o message.fillerString1

DecodeOrderCancelMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET timeOfEvent == ReadBytes(tradingVenue.rest, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET t1 == ReadBytes(timeOfEvent.rest, 8) IN IF ~t1.ok THEN Fail ELSE
    LET t2 == ReadBytes(t1.rest, 8) IN IF ~t2.ok THEN Fail ELSE
    LET t3 == ReadBytes(t2.rest, 8) IN IF ~t3.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(t3.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(tradableInstrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET buySell == ReadBytes(orderId.rest, 1) IN IF ~buySell.ok THEN Fail ELSE
    LET fillerString1 == ReadBytes(buySell.rest, 1) IN IF ~fillerString1.ok THEN Fail ELSE
    Ok([ tradingVenue         |-> tradingVenue.value,
         timeOfEvent          |-> timeOfEvent.value,
         t1                   |-> t1.value,
         t2                   |-> t2.value,
         t3                   |-> t3.value,
         tradableInstrumentId |-> tradableInstrumentId.value,
         orderId              |-> orderId.value,
         buySell              |-> buySell.value,
         fillerString1        |-> fillerString1.value ], fillerString1.rest)

ZeroOrderCancelMessage ==
    [ tradingVenue         |-> [i \in 1 .. 2 |-> 0],
      timeOfEvent          |-> [i \in 1 .. 8 |-> 0],
      t1                   |-> [i \in 1 .. 8 |-> 0],
      t2                   |-> [i \in 1 .. 8 |-> 0],
      t3                   |-> [i \in 1 .. 8 |-> 0],
      tradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      buySell              |-> [i \in 1 .. 1 |-> 0],
      fillerString1        |-> [i \in 1 .. 1 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.t1 = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.t2 = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.t3 = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.buySell = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.fillerString1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Executed Legs: 29 bytes                                                 *)
(***************************************************************************)

ExecutedLegs ==
    [ legTradableInstrumentId : Sample(8),
      legBuySell              : Sample(1),
      legPrice                : Sample(8),
      legVolume               : Sample(4),
      legMatchId              : Sample(8) ]

EncodeExecutedLegs(message) ==
    message.legTradableInstrumentId
        \o message.legBuySell
        \o message.legPrice
        \o message.legVolume
        \o message.legMatchId

DecodeExecutedLegs(bytes) ==
    LET legTradableInstrumentId == ReadBytes(bytes, 8) IN IF ~legTradableInstrumentId.ok THEN Fail ELSE
    LET legBuySell == ReadBytes(legTradableInstrumentId.rest, 1) IN IF ~legBuySell.ok THEN Fail ELSE
    LET legPrice == ReadBytes(legBuySell.rest, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET legVolume == ReadBytes(legPrice.rest, 4) IN IF ~legVolume.ok THEN Fail ELSE
    LET legMatchId == ReadBytes(legVolume.rest, 8) IN IF ~legMatchId.ok THEN Fail ELSE
    Ok([ legTradableInstrumentId |-> legTradableInstrumentId.value,
         legBuySell              |-> legBuySell.value,
         legPrice                |-> legPrice.value,
         legVolume               |-> legVolume.value,
         legMatchId              |-> legMatchId.value ], legMatchId.rest)

ZeroExecutedLegs ==
    [ legTradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      legBuySell              |-> [i \in 1 .. 1 |-> 0],
      legPrice                |-> [i \in 1 .. 8 |-> 0],
      legVolume               |-> [i \in 1 .. 4 |-> 0],
      legMatchId              |-> [i \in 1 .. 8 |-> 0] ]

(* Executed Legs at zero, then each field in turn at the values it is checked at *)
CheckedExecutedLegs ==
    { ZeroExecutedLegs }
        \cup { [ZeroExecutedLegs EXCEPT !.legTradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroExecutedLegs EXCEPT !.legBuySell = one] : one \in Sample(1) }
        \cup { [ZeroExecutedLegs EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutedLegs EXCEPT !.legVolume = one] : one \in Sample(4) }
        \cup { [ZeroExecutedLegs EXCEPT !.legMatchId = one] : one \in Sample(8) }

(* A run of Executed Legs, written one after another *)
RECURSIVE EncodeExecutedLegsList(_)
EncodeExecutedLegsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeExecutedLegs(Head(messages)) \o EncodeExecutedLegsList(Tail(messages))

(* As many Executed Legs as the field that counts them says *)
RECURSIVE ReadExecutedLegsList(_, _)
ReadExecutedLegsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeExecutedLegs(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadExecutedLegsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Executed Legs of each kind, for the lists that carry them *)
OneExecutedLegs == { ZeroExecutedLegs }

(***************************************************************************)
(* Order Executed Message                                                  *)
(***************************************************************************)

OrderExecutedMessage ==
    [ tradingVenue         : Sample(2),
      timeOfEvent          : Sample(8),
      tradableInstrumentId : Sample(8),
      price                : Sample(8),
      volume               : Sample(4),
      orderId              : Sample(8),
      matchId              : Sample(8),
      tradeCancelFlag      : Sample(1),
      subTypeOfTrade       : Sample(1),
      tradeBuySell         : Sample(1),
      executedLegs         : SampleLists(OneExecutedLegs) ]

EncodeOrderExecutedMessage(message) ==
    message.tradingVenue
        \o message.timeOfEvent
        \o message.tradableInstrumentId
        \o message.price
        \o message.volume
        \o message.orderId
        \o message.matchId
        \o message.tradeCancelFlag
        \o message.subTypeOfTrade
        \o message.tradeBuySell
        \o EncodeUIntLE(Len(message.executedLegs), 4)
        \o EncodeExecutedLegsList(message.executedLegs)

DecodeOrderExecutedMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET timeOfEvent == ReadBytes(tradingVenue.rest, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(timeOfEvent.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET price == ReadBytes(tradableInstrumentId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET orderId == ReadBytes(volume.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET matchId == ReadBytes(orderId.rest, 8) IN IF ~matchId.ok THEN Fail ELSE
    LET tradeCancelFlag == ReadBytes(matchId.rest, 1) IN IF ~tradeCancelFlag.ok THEN Fail ELSE
    LET subTypeOfTrade == ReadBytes(tradeCancelFlag.rest, 1) IN IF ~subTypeOfTrade.ok THEN Fail ELSE
    LET tradeBuySell == ReadBytes(subTypeOfTrade.rest, 1) IN IF ~tradeBuySell.ok THEN Fail ELSE
    LET strategyLegCount == ReadUIntLE(tradeBuySell.rest, 4) IN IF ~strategyLegCount.ok THEN Fail ELSE
    LET executedLegs == ReadExecutedLegsList(strategyLegCount.rest, strategyLegCount.value) IN IF ~executedLegs.ok THEN Fail ELSE
    Ok([ tradingVenue         |-> tradingVenue.value,
         timeOfEvent          |-> timeOfEvent.value,
         tradableInstrumentId |-> tradableInstrumentId.value,
         price                |-> price.value,
         volume               |-> volume.value,
         orderId              |-> orderId.value,
         matchId              |-> matchId.value,
         tradeCancelFlag      |-> tradeCancelFlag.value,
         subTypeOfTrade       |-> subTypeOfTrade.value,
         tradeBuySell         |-> tradeBuySell.value,
         executedLegs         |-> executedLegs.value ], executedLegs.rest)

ZeroOrderExecutedMessage ==
    [ tradingVenue         |-> [i \in 1 .. 2 |-> 0],
      timeOfEvent          |-> [i \in 1 .. 8 |-> 0],
      tradableInstrumentId |-> [i \in 1 .. 8 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      volume               |-> [i \in 1 .. 4 |-> 0],
      orderId              |-> [i \in 1 .. 8 |-> 0],
      matchId              |-> [i \in 1 .. 8 |-> 0],
      tradeCancelFlag      |-> [i \in 1 .. 1 |-> 0],
      subTypeOfTrade       |-> [i \in 1 .. 1 |-> 0],
      tradeBuySell         |-> [i \in 1 .. 1 |-> 0],
      executedLegs         |-> << >> ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeCancelFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.subTypeOfTrade = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.tradeBuySell = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedLegs = one] : one \in SampleLists(OneExecutedLegs) }

(***************************************************************************)
(* Logon Message: 12 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ username : Sample(12) ]

EncodeLogonMessage(message) ==
    message.username

DecodeLogonMessage(bytes) ==
    LET username == ReadBytes(bytes, 12) IN IF ~username.ok THEN Fail ELSE
    Ok([ username |-> username.value ], username.rest)

ZeroLogonMessage ==
    [ username |-> [i \in 1 .. 12 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.username = one] : one \in Sample(12) }

(***************************************************************************)
(* Logon Response Message: 4 bytes                                         *)
(***************************************************************************)

LogonResponseMessage ==
    [ sessionStatus : Sample(1),
      fillerString3 : Sample(3) ]

EncodeLogonResponseMessage(message) ==
    message.sessionStatus
        \o message.fillerString3

DecodeLogonResponseMessage(bytes) ==
    LET sessionStatus == ReadBytes(bytes, 1) IN IF ~sessionStatus.ok THEN Fail ELSE
    LET fillerString3 == ReadBytes(sessionStatus.rest, 3) IN IF ~fillerString3.ok THEN Fail ELSE
    Ok([ sessionStatus |-> sessionStatus.value,
         fillerString3 |-> fillerString3.value ], fillerString3.rest)

ZeroLogonResponseMessage ==
    [ sessionStatus |-> [i \in 1 .. 1 |-> 0],
      fillerString3 |-> [i \in 1 .. 3 |-> 0] ]

(* Logon Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonResponseMessage ==
    { ZeroLogonResponseMessage }
        \cup { [ZeroLogonResponseMessage EXCEPT !.sessionStatus = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.fillerString3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Retransmission Request Message: 12 bytes                                *)
(***************************************************************************)

RetransmissionRequestMessage ==
    [ channelId     : Sample(2),
      fillerString2 : Sample(2),
      beginSeqNum   : Sample(4),
      endSeqNum     : Sample(4) ]

EncodeRetransmissionRequestMessage(message) ==
    message.channelId
        \o message.fillerString2
        \o message.beginSeqNum
        \o message.endSeqNum

DecodeRetransmissionRequestMessage(bytes) ==
    LET channelId == ReadBytes(bytes, 2) IN IF ~channelId.ok THEN Fail ELSE
    LET fillerString2 == ReadBytes(channelId.rest, 2) IN IF ~fillerString2.ok THEN Fail ELSE
    LET beginSeqNum == ReadBytes(fillerString2.rest, 4) IN IF ~beginSeqNum.ok THEN Fail ELSE
    LET endSeqNum == ReadBytes(beginSeqNum.rest, 4) IN IF ~endSeqNum.ok THEN Fail ELSE
    Ok([ channelId     |-> channelId.value,
         fillerString2 |-> fillerString2.value,
         beginSeqNum   |-> beginSeqNum.value,
         endSeqNum     |-> endSeqNum.value ], endSeqNum.rest)

ZeroRetransmissionRequestMessage ==
    [ channelId     |-> [i \in 1 .. 2 |-> 0],
      fillerString2 |-> [i \in 1 .. 2 |-> 0],
      beginSeqNum   |-> [i \in 1 .. 4 |-> 0],
      endSeqNum     |-> [i \in 1 .. 4 |-> 0] ]

(* Retransmission Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequestMessage ==
    { ZeroRetransmissionRequestMessage }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.channelId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.fillerString2 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.beginSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.endSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmission Response Message: 12 bytes                               *)
(***************************************************************************)

RetransmissionResponseMessage ==
    [ channelId     : Sample(2),
      retransStatus : Sample(1),
      fillerString1 : Sample(1),
      beginSeqNum   : Sample(4),
      endSeqNum     : Sample(4) ]

EncodeRetransmissionResponseMessage(message) ==
    message.channelId
        \o message.retransStatus
        \o message.fillerString1
        \o message.beginSeqNum
        \o message.endSeqNum

DecodeRetransmissionResponseMessage(bytes) ==
    LET channelId == ReadBytes(bytes, 2) IN IF ~channelId.ok THEN Fail ELSE
    LET retransStatus == ReadBytes(channelId.rest, 1) IN IF ~retransStatus.ok THEN Fail ELSE
    LET fillerString1 == ReadBytes(retransStatus.rest, 1) IN IF ~fillerString1.ok THEN Fail ELSE
    LET beginSeqNum == ReadBytes(fillerString1.rest, 4) IN IF ~beginSeqNum.ok THEN Fail ELSE
    LET endSeqNum == ReadBytes(beginSeqNum.rest, 4) IN IF ~endSeqNum.ok THEN Fail ELSE
    Ok([ channelId     |-> channelId.value,
         retransStatus |-> retransStatus.value,
         fillerString1 |-> fillerString1.value,
         beginSeqNum   |-> beginSeqNum.value,
         endSeqNum     |-> endSeqNum.value ], endSeqNum.rest)

ZeroRetransmissionResponseMessage ==
    [ channelId     |-> [i \in 1 .. 2 |-> 0],
      retransStatus |-> [i \in 1 .. 1 |-> 0],
      fillerString1 |-> [i \in 1 .. 1 |-> 0],
      beginSeqNum   |-> [i \in 1 .. 4 |-> 0],
      endSeqNum     |-> [i \in 1 .. 4 |-> 0] ]

(* Retransmission Response Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionResponseMessage ==
    { ZeroRetransmissionResponseMessage }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.channelId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.retransStatus = one] : one \in Sample(1) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.fillerString1 = one] : one \in Sample(1) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.beginSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.endSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

SequenceResetMessageCode == 100  \* 0x64
MarketStateContractMessageCode == 311  \* 0x137
MarketStateInstrumentMessageCode == 312  \* 0x138
IndicativeOpeningPriceMessageCode == 320  \* 0x140
QuoteRequestMessageCode == 329  \* 0x149
OrderBookClearMessageCode == 327  \* 0x147
CrossRequestMessageCode == 330  \* 0x14a
OrderAddMessageCode == 323  \* 0x143
OrderAmendMessageCode == 324  \* 0x144
OrderCancelMessageCode == 325  \* 0x145
OrderExecutedMessageCode == 326  \* 0x146
LogonMessageCode == 101  \* 0x65
LogonResponseMessageCode == 102  \* 0x66
RetransmissionRequestMessageCode == 201  \* 0xc9
RetransmissionResponseMessageCode == 202  \* 0xca

Payload ==
    [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {MarketStateContractMessageCode}, body : MarketStateContractMessage ]
        \cup [ tag : {MarketStateInstrumentMessageCode}, body : MarketStateInstrumentMessage ]
        \cup [ tag : {IndicativeOpeningPriceMessageCode}, body : IndicativeOpeningPriceMessage ]
        \cup [ tag : {QuoteRequestMessageCode}, body : QuoteRequestMessage ]
        \cup [ tag : {OrderBookClearMessageCode}, body : OrderBookClearMessage ]
        \cup [ tag : {CrossRequestMessageCode}, body : CrossRequestMessage ]
        \cup [ tag : {OrderAddMessageCode}, body : OrderAddMessage ]
        \cup [ tag : {OrderAmendMessageCode}, body : OrderAmendMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogonResponseMessageCode}, body : LogonResponseMessage ]
        \cup [ tag : {RetransmissionRequestMessageCode}, body : RetransmissionRequestMessage ]
        \cup [ tag : {RetransmissionResponseMessageCode}, body : RetransmissionResponseMessage ]

EncodePayload(message) ==
    CASE message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = MarketStateContractMessageCode -> EncodeMarketStateContractMessage(message.body)
      [] message.tag = MarketStateInstrumentMessageCode -> EncodeMarketStateInstrumentMessage(message.body)
      [] message.tag = IndicativeOpeningPriceMessageCode -> EncodeIndicativeOpeningPriceMessage(message.body)
      [] message.tag = QuoteRequestMessageCode -> EncodeQuoteRequestMessage(message.body)
      [] message.tag = OrderBookClearMessageCode -> EncodeOrderBookClearMessage(message.body)
      [] message.tag = CrossRequestMessageCode -> EncodeCrossRequestMessage(message.body)
      [] message.tag = OrderAddMessageCode -> EncodeOrderAddMessage(message.body)
      [] message.tag = OrderAmendMessageCode -> EncodeOrderAmendMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogonResponseMessageCode -> EncodeLogonResponseMessage(message.body)
      [] message.tag = RetransmissionRequestMessageCode -> EncodeRetransmissionRequestMessage(message.body)
      [] message.tag = RetransmissionResponseMessageCode -> EncodeRetransmissionResponseMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = MarketStateContractMessageCode -> DecodeMarketStateContractMessage(bytes)
              [] tag = MarketStateInstrumentMessageCode -> DecodeMarketStateInstrumentMessage(bytes)
              [] tag = IndicativeOpeningPriceMessageCode -> DecodeIndicativeOpeningPriceMessage(bytes)
              [] tag = QuoteRequestMessageCode -> DecodeQuoteRequestMessage(bytes)
              [] tag = OrderBookClearMessageCode -> DecodeOrderBookClearMessage(bytes)
              [] tag = CrossRequestMessageCode -> DecodeCrossRequestMessage(bytes)
              [] tag = OrderAddMessageCode -> DecodeOrderAddMessage(bytes)
              [] tag = OrderAmendMessageCode -> DecodeOrderAmendMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogonResponseMessageCode -> DecodeLogonResponseMessage(bytes)
              [] tag = RetransmissionRequestMessageCode -> DecodeRetransmissionRequestMessage(bytes)
              [] tag = RetransmissionResponseMessageCode -> DecodeRetransmissionResponseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }
        \cup { [tag |-> MarketStateContractMessageCode, body |-> one] : one \in CheckedMarketStateContractMessage }
        \cup { [tag |-> MarketStateInstrumentMessageCode, body |-> one] : one \in CheckedMarketStateInstrumentMessage }
        \cup { [tag |-> IndicativeOpeningPriceMessageCode, body |-> one] : one \in CheckedIndicativeOpeningPriceMessage }
        \cup { [tag |-> QuoteRequestMessageCode, body |-> one] : one \in CheckedQuoteRequestMessage }
        \cup { [tag |-> OrderBookClearMessageCode, body |-> one] : one \in CheckedOrderBookClearMessage }
        \cup { [tag |-> CrossRequestMessageCode, body |-> one] : one \in CheckedCrossRequestMessage }
        \cup { [tag |-> OrderAddMessageCode, body |-> one] : one \in CheckedOrderAddMessage }
        \cup { [tag |-> OrderAmendMessageCode, body |-> one] : one \in CheckedOrderAmendMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogonResponseMessageCode, body |-> one] : one \in CheckedLogonResponseMessage }
        \cup { [tag |-> RetransmissionRequestMessageCode, body |-> one] : one \in CheckedRetransmissionRequestMessage }
        \cup { [tag |-> RetransmissionResponseMessageCode, body |-> one] : one \in CheckedRetransmissionResponseMessage }

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
      [ZeroMessages EXCEPT !.payload = [tag |-> MarketStateContractMessageCode, body |-> ZeroMarketStateContractMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> MarketStateInstrumentMessageCode, body |-> ZeroMarketStateInstrumentMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> IndicativeOpeningPriceMessageCode, body |-> ZeroIndicativeOpeningPriceMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> QuoteRequestMessageCode, body |-> ZeroQuoteRequestMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> OrderBookClearMessageCode, body |-> ZeroOrderBookClearMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> CrossRequestMessageCode, body |-> ZeroCrossRequestMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> OrderAddMessageCode, body |-> ZeroOrderAddMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> OrderAmendMessageCode, body |-> ZeroOrderAmendMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> OrderCancelMessageCode, body |-> ZeroOrderCancelMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> OrderExecutedMessageCode, body |-> ZeroOrderExecutedMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> LogonResponseMessageCode, body |-> ZeroLogonResponseMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> RetransmissionRequestMessageCode, body |-> ZeroRetransmissionRequestMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> RetransmissionResponseMessageCode, body |-> ZeroRetransmissionResponseMessage]] }

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

(* Every Market State Contract Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStateContractMessage ==
    \A message \in CheckedMarketStateContractMessage :
        LET read == DecodeMarketStateContractMessage(EncodeMarketStateContractMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market State Instrument Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketStateInstrumentMessage ==
    \A message \in CheckedMarketStateInstrumentMessage :
        LET read == DecodeMarketStateInstrumentMessage(EncodeMarketStateInstrumentMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Indicative Opening Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndicativeOpeningPriceMessage ==
    \A message \in CheckedIndicativeOpeningPriceMessage :
        LET read == DecodeIndicativeOpeningPriceMessage(EncodeIndicativeOpeningPriceMessage(message))
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

(* Every Order Book Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookClearMessage ==
    \A message \in CheckedOrderBookClearMessage :
        LET read == DecodeOrderBookClearMessage(EncodeOrderBookClearMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossRequestMessage ==
    \A message \in CheckedCrossRequestMessage :
        LET read == DecodeCrossRequestMessage(EncodeCrossRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Add Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddMessage ==
    \A message \in CheckedOrderAddMessage :
        LET read == DecodeOrderAddMessage(EncodeOrderAddMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Amend Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAmendMessage ==
    \A message \in CheckedOrderAmendMessage :
        LET read == DecodeOrderAmendMessage(EncodeOrderAmendMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelMessage ==
    \A message \in CheckedOrderCancelMessage :
        LET read == DecodeOrderCancelMessage(EncodeOrderCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Executed Legs decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutedLegs ==
    \A message \in CheckedExecutedLegs :
        LET read == DecodeExecutedLegs(EncodeExecutedLegs(message))
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

(* Every Logon Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonMessage ==
    \A message \in CheckedLogonMessage :
        LET read == DecodeLogonMessage(EncodeLogonMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonResponseMessage ==
    \A message \in CheckedLogonResponseMessage :
        LET read == DecodeLogonResponseMessage(EncodeLogonResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequestMessage ==
    \A message \in CheckedRetransmissionRequestMessage :
        LET read == DecodeRetransmissionRequestMessage(EncodeRetransmissionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionResponseMessage ==
    \A message \in CheckedRetransmissionResponseMessage :
        LET read == DecodeRetransmissionResponseMessage(EncodeRetransmissionResponseMessage(message))
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
