------------------ MODULE LmeSelect_Level1Snapshot_v4_18 -------------------
(***************************************************************************)
(* The London Metal Exchange LMEsource Level1 Refresh v4.18                *)
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
(* Top Of Book Message: 98 bytes                                           *)
(***************************************************************************)

TopOfBookMessage ==
    [ tradingVenue            : Sample(2),
      timeOfEvent             : Sample(8),
      tradableInstrumentId    : Sample(8),
      aggregateBidVolume      : Sample(8),
      aggregateAskVolume      : Sample(8),
      bidPrice                : Sample(8),
      askPrice                : Sample(8),
      numberBidExplicitOrders : Sample(4),
      bidQtyExplicitOrders    : Sample(8),
      numberAskExplicitOrders : Sample(4),
      askQtyExplicitOrders    : Sample(8),
      numberBidImpliedOrders  : Sample(4),
      bidQtyImpliedOrders     : Sample(8),
      numberAskImpliedOrders  : Sample(4),
      askQtyImpliedOrders     : Sample(8) ]

EncodeTopOfBookMessage(message) ==
    message.tradingVenue
        \o message.timeOfEvent
        \o message.tradableInstrumentId
        \o message.aggregateBidVolume
        \o message.aggregateAskVolume
        \o message.bidPrice
        \o message.askPrice
        \o message.numberBidExplicitOrders
        \o message.bidQtyExplicitOrders
        \o message.numberAskExplicitOrders
        \o message.askQtyExplicitOrders
        \o message.numberBidImpliedOrders
        \o message.bidQtyImpliedOrders
        \o message.numberAskImpliedOrders
        \o message.askQtyImpliedOrders

DecodeTopOfBookMessage(bytes) ==
    LET tradingVenue == ReadBytes(bytes, 2) IN IF ~tradingVenue.ok THEN Fail ELSE
    LET timeOfEvent == ReadBytes(tradingVenue.rest, 8) IN IF ~timeOfEvent.ok THEN Fail ELSE
    LET tradableInstrumentId == ReadBytes(timeOfEvent.rest, 8) IN IF ~tradableInstrumentId.ok THEN Fail ELSE
    LET aggregateBidVolume == ReadBytes(tradableInstrumentId.rest, 8) IN IF ~aggregateBidVolume.ok THEN Fail ELSE
    LET aggregateAskVolume == ReadBytes(aggregateBidVolume.rest, 8) IN IF ~aggregateAskVolume.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(aggregateAskVolume.rest, 8) IN IF ~bidPrice.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidPrice.rest, 8) IN IF ~askPrice.ok THEN Fail ELSE
    LET numberBidExplicitOrders == ReadBytes(askPrice.rest, 4) IN IF ~numberBidExplicitOrders.ok THEN Fail ELSE
    LET bidQtyExplicitOrders == ReadBytes(numberBidExplicitOrders.rest, 8) IN IF ~bidQtyExplicitOrders.ok THEN Fail ELSE
    LET numberAskExplicitOrders == ReadBytes(bidQtyExplicitOrders.rest, 4) IN IF ~numberAskExplicitOrders.ok THEN Fail ELSE
    LET askQtyExplicitOrders == ReadBytes(numberAskExplicitOrders.rest, 8) IN IF ~askQtyExplicitOrders.ok THEN Fail ELSE
    LET numberBidImpliedOrders == ReadBytes(askQtyExplicitOrders.rest, 4) IN IF ~numberBidImpliedOrders.ok THEN Fail ELSE
    LET bidQtyImpliedOrders == ReadBytes(numberBidImpliedOrders.rest, 8) IN IF ~bidQtyImpliedOrders.ok THEN Fail ELSE
    LET numberAskImpliedOrders == ReadBytes(bidQtyImpliedOrders.rest, 4) IN IF ~numberAskImpliedOrders.ok THEN Fail ELSE
    LET askQtyImpliedOrders == ReadBytes(numberAskImpliedOrders.rest, 8) IN IF ~askQtyImpliedOrders.ok THEN Fail ELSE
    Ok([ tradingVenue            |-> tradingVenue.value,
         timeOfEvent             |-> timeOfEvent.value,
         tradableInstrumentId    |-> tradableInstrumentId.value,
         aggregateBidVolume      |-> aggregateBidVolume.value,
         aggregateAskVolume      |-> aggregateAskVolume.value,
         bidPrice                |-> bidPrice.value,
         askPrice                |-> askPrice.value,
         numberBidExplicitOrders |-> numberBidExplicitOrders.value,
         bidQtyExplicitOrders    |-> bidQtyExplicitOrders.value,
         numberAskExplicitOrders |-> numberAskExplicitOrders.value,
         askQtyExplicitOrders    |-> askQtyExplicitOrders.value,
         numberBidImpliedOrders  |-> numberBidImpliedOrders.value,
         bidQtyImpliedOrders     |-> bidQtyImpliedOrders.value,
         numberAskImpliedOrders  |-> numberAskImpliedOrders.value,
         askQtyImpliedOrders     |-> askQtyImpliedOrders.value ], askQtyImpliedOrders.rest)

ZeroTopOfBookMessage ==
    [ tradingVenue            |-> [i \in 1 .. 2 |-> 0],
      timeOfEvent             |-> [i \in 1 .. 8 |-> 0],
      tradableInstrumentId    |-> [i \in 1 .. 8 |-> 0],
      aggregateBidVolume      |-> [i \in 1 .. 8 |-> 0],
      aggregateAskVolume      |-> [i \in 1 .. 8 |-> 0],
      bidPrice                |-> [i \in 1 .. 8 |-> 0],
      askPrice                |-> [i \in 1 .. 8 |-> 0],
      numberBidExplicitOrders |-> [i \in 1 .. 4 |-> 0],
      bidQtyExplicitOrders    |-> [i \in 1 .. 8 |-> 0],
      numberAskExplicitOrders |-> [i \in 1 .. 4 |-> 0],
      askQtyExplicitOrders    |-> [i \in 1 .. 8 |-> 0],
      numberBidImpliedOrders  |-> [i \in 1 .. 4 |-> 0],
      bidQtyImpliedOrders     |-> [i \in 1 .. 8 |-> 0],
      numberAskImpliedOrders  |-> [i \in 1 .. 4 |-> 0],
      askQtyImpliedOrders     |-> [i \in 1 .. 8 |-> 0] ]

(* Top Of Book Message at zero, then each field in turn at the values it is checked at *)
CheckedTopOfBookMessage ==
    { ZeroTopOfBookMessage }
        \cup { [ZeroTopOfBookMessage EXCEPT !.tradingVenue = one] : one \in Sample(2) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.timeOfEvent = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.tradableInstrumentId = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.aggregateBidVolume = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.aggregateAskVolume = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.bidPrice = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.askPrice = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.numberBidExplicitOrders = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.bidQtyExplicitOrders = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.numberAskExplicitOrders = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.askQtyExplicitOrders = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.numberBidImpliedOrders = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.bidQtyImpliedOrders = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.numberAskImpliedOrders = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.askQtyImpliedOrders = one] : one \in Sample(8) }

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
MarketStateContractMessageCode == 311  \* 0x137
MarketStateInstrumentMessageCode == 312  \* 0x138
IndicativeOpeningPriceMessageCode == 320  \* 0x140
QuoteRequestMessageCode == 329  \* 0x149
TopOfBookMessageCode == 321  \* 0x141
RefreshCompleteMessageCode == 203  \* 0xcb

Payload ==
    [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {MarketStateContractMessageCode}, body : MarketStateContractMessage ]
        \cup [ tag : {MarketStateInstrumentMessageCode}, body : MarketStateInstrumentMessage ]
        \cup [ tag : {IndicativeOpeningPriceMessageCode}, body : IndicativeOpeningPriceMessage ]
        \cup [ tag : {QuoteRequestMessageCode}, body : QuoteRequestMessage ]
        \cup [ tag : {TopOfBookMessageCode}, body : TopOfBookMessage ]
        \cup [ tag : {RefreshCompleteMessageCode}, body : RefreshCompleteMessage ]

EncodePayload(message) ==
    CASE message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = MarketStateContractMessageCode -> EncodeMarketStateContractMessage(message.body)
      [] message.tag = MarketStateInstrumentMessageCode -> EncodeMarketStateInstrumentMessage(message.body)
      [] message.tag = IndicativeOpeningPriceMessageCode -> EncodeIndicativeOpeningPriceMessage(message.body)
      [] message.tag = QuoteRequestMessageCode -> EncodeQuoteRequestMessage(message.body)
      [] message.tag = TopOfBookMessageCode -> EncodeTopOfBookMessage(message.body)
      [] message.tag = RefreshCompleteMessageCode -> EncodeRefreshCompleteMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = MarketStateContractMessageCode -> DecodeMarketStateContractMessage(bytes)
              [] tag = MarketStateInstrumentMessageCode -> DecodeMarketStateInstrumentMessage(bytes)
              [] tag = IndicativeOpeningPriceMessageCode -> DecodeIndicativeOpeningPriceMessage(bytes)
              [] tag = QuoteRequestMessageCode -> DecodeQuoteRequestMessage(bytes)
              [] tag = TopOfBookMessageCode -> DecodeTopOfBookMessage(bytes)
              [] tag = RefreshCompleteMessageCode -> DecodeRefreshCompleteMessage(bytes)
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
        \cup { [tag |-> TopOfBookMessageCode, body |-> one] : one \in CheckedTopOfBookMessage }
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
      [ZeroMessages EXCEPT !.payload = [tag |-> MarketStateContractMessageCode, body |-> ZeroMarketStateContractMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> MarketStateInstrumentMessageCode, body |-> ZeroMarketStateInstrumentMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> IndicativeOpeningPriceMessageCode, body |-> ZeroIndicativeOpeningPriceMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> QuoteRequestMessageCode, body |-> ZeroQuoteRequestMessage]],
      [ZeroMessages EXCEPT !.payload = [tag |-> TopOfBookMessageCode, body |-> ZeroTopOfBookMessage]],
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

(* Every Top Of Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopOfBookMessage ==
    \A message \in CheckedTopOfBookMessage :
        LET read == DecodeTopOfBookMessage(EncodeTopOfBookMessage(message))
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
