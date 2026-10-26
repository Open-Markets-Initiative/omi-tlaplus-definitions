------------------- MODULE PearlOptions_TopOfMarket_v1_0 -------------------
(***************************************************************************)
(* Miami International Holdings Top Of Market v1.0                         *)
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
(* Note: Application Message fills what is left of the frame Packet Length *)
(* states, which is what it is read from.                                  *)
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
(* System Time Message: 4 bytes                                            *)
(***************************************************************************)

SystemTimeMessage ==
    [ seconds : Sample(4) ]

EncodeSystemTimeMessage(message) ==
    message.seconds

DecodeSystemTimeMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    Ok([ seconds |-> seconds.value ], seconds.rest)

ZeroSystemTimeMessage ==
    [ seconds |-> [i \in 1 .. 4 |-> 0] ]

(* System Time Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemTimeMessage ==
    { ZeroSystemTimeMessage }
        \cup { [ZeroSystemTimeMessage EXCEPT !.seconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Series Update Message: 72 bytes                                         *)
(***************************************************************************)

SeriesUpdateMessage ==
    [ nanoseconds                           : Sample(4),
      productId                             : Sample(4),
      underlyingSymbol                      : Sample(11),
      securitySymbol                        : Sample(6),
      expirationDate                        : Sample(8),
      strikePrice                           : Sample(4),
      callOrPut                             : Sample(1),
      openingTime                           : Sample(8),
      closingTime                           : Sample(8),
      restrictedOption                      : Sample(1),
      longTermOption                        : Sample(1),
      activeOnPearl                         : Sample(1),
      pearlBboPostingIncrementIndicator     : Sample(1),
      liquidityAcceptanceIncrementIndicator : Sample(1),
      openingUnderlyingMarketCode           : Sample(1),
      reserved12                            : Sample(12) ]

EncodeSeriesUpdateMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.underlyingSymbol
        \o message.securitySymbol
        \o message.expirationDate
        \o message.strikePrice
        \o message.callOrPut
        \o message.openingTime
        \o message.closingTime
        \o message.restrictedOption
        \o message.longTermOption
        \o message.activeOnPearl
        \o message.pearlBboPostingIncrementIndicator
        \o message.liquidityAcceptanceIncrementIndicator
        \o message.openingUnderlyingMarketCode
        \o message.reserved12

DecodeSeriesUpdateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(productId.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(underlyingSymbol.rest, 6) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(securitySymbol.rest, 8) IN IF ~expirationDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expirationDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET callOrPut == ReadBytes(strikePrice.rest, 1) IN IF ~callOrPut.ok THEN Fail ELSE
    LET openingTime == ReadBytes(callOrPut.rest, 8) IN IF ~openingTime.ok THEN Fail ELSE
    LET closingTime == ReadBytes(openingTime.rest, 8) IN IF ~closingTime.ok THEN Fail ELSE
    LET restrictedOption == ReadBytes(closingTime.rest, 1) IN IF ~restrictedOption.ok THEN Fail ELSE
    LET longTermOption == ReadBytes(restrictedOption.rest, 1) IN IF ~longTermOption.ok THEN Fail ELSE
    LET activeOnPearl == ReadBytes(longTermOption.rest, 1) IN IF ~activeOnPearl.ok THEN Fail ELSE
    LET pearlBboPostingIncrementIndicator == ReadBytes(activeOnPearl.rest, 1) IN IF ~pearlBboPostingIncrementIndicator.ok THEN Fail ELSE
    LET liquidityAcceptanceIncrementIndicator == ReadBytes(pearlBboPostingIncrementIndicator.rest, 1) IN IF ~liquidityAcceptanceIncrementIndicator.ok THEN Fail ELSE
    LET openingUnderlyingMarketCode == ReadBytes(liquidityAcceptanceIncrementIndicator.rest, 1) IN IF ~openingUnderlyingMarketCode.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(openingUnderlyingMarketCode.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    Ok([ nanoseconds                           |-> nanoseconds.value,
         productId                             |-> productId.value,
         underlyingSymbol                      |-> underlyingSymbol.value,
         securitySymbol                        |-> securitySymbol.value,
         expirationDate                        |-> expirationDate.value,
         strikePrice                           |-> strikePrice.value,
         callOrPut                             |-> callOrPut.value,
         openingTime                           |-> openingTime.value,
         closingTime                           |-> closingTime.value,
         restrictedOption                      |-> restrictedOption.value,
         longTermOption                        |-> longTermOption.value,
         activeOnPearl                         |-> activeOnPearl.value,
         pearlBboPostingIncrementIndicator     |-> pearlBboPostingIncrementIndicator.value,
         liquidityAcceptanceIncrementIndicator |-> liquidityAcceptanceIncrementIndicator.value,
         openingUnderlyingMarketCode           |-> openingUnderlyingMarketCode.value,
         reserved12                            |-> reserved12.value ], reserved12.rest)

ZeroSeriesUpdateMessage ==
    [ nanoseconds                           |-> [i \in 1 .. 4 |-> 0],
      productId                             |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol                      |-> [i \in 1 .. 11 |-> 0],
      securitySymbol                        |-> [i \in 1 .. 6 |-> 0],
      expirationDate                        |-> [i \in 1 .. 8 |-> 0],
      strikePrice                           |-> [i \in 1 .. 4 |-> 0],
      callOrPut                             |-> [i \in 1 .. 1 |-> 0],
      openingTime                           |-> [i \in 1 .. 8 |-> 0],
      closingTime                           |-> [i \in 1 .. 8 |-> 0],
      restrictedOption                      |-> [i \in 1 .. 1 |-> 0],
      longTermOption                        |-> [i \in 1 .. 1 |-> 0],
      activeOnPearl                         |-> [i \in 1 .. 1 |-> 0],
      pearlBboPostingIncrementIndicator     |-> [i \in 1 .. 1 |-> 0],
      liquidityAcceptanceIncrementIndicator |-> [i \in 1 .. 1 |-> 0],
      openingUnderlyingMarketCode           |-> [i \in 1 .. 1 |-> 0],
      reserved12                            |-> [i \in 1 .. 12 |-> 0] ]

(* Series Update Message at zero, then each field in turn at the values it is checked at *)
CheckedSeriesUpdateMessage ==
    { ZeroSeriesUpdateMessage }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.callOrPut = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.openingTime = one] : one \in Sample(8) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.closingTime = one] : one \in Sample(8) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.restrictedOption = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.longTermOption = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.activeOnPearl = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.pearlBboPostingIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.liquidityAcceptanceIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.openingUnderlyingMarketCode = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }

(***************************************************************************)
(* System State Message: 17 bytes                                          *)
(***************************************************************************)

SystemStateMessage ==
    [ nanoseconds  : Sample(4),
      toMVersion   : Sample(8),
      sessionId    : Sample(4),
      systemStatus : Sample(1) ]

EncodeSystemStateMessage(message) ==
    message.nanoseconds
        \o message.toMVersion
        \o message.sessionId
        \o message.systemStatus

DecodeSystemStateMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET toMVersion == ReadBytes(nanoseconds.rest, 8) IN IF ~toMVersion.ok THEN Fail ELSE
    LET sessionId == ReadBytes(toMVersion.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET systemStatus == ReadBytes(sessionId.rest, 1) IN IF ~systemStatus.ok THEN Fail ELSE
    Ok([ nanoseconds  |-> nanoseconds.value,
         toMVersion   |-> toMVersion.value,
         sessionId    |-> sessionId.value,
         systemStatus |-> systemStatus.value ], systemStatus.rest)

ZeroSystemStateMessage ==
    [ nanoseconds  |-> [i \in 1 .. 4 |-> 0],
      toMVersion   |-> [i \in 1 .. 8 |-> 0],
      sessionId    |-> [i \in 1 .. 4 |-> 0],
      systemStatus |-> [i \in 1 .. 1 |-> 0] ]

(* System State Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemStateMessage ==
    { ZeroSystemStateMessage }
        \cup { [ZeroSystemStateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemStateMessage EXCEPT !.toMVersion = one] : one \in Sample(8) }
        \cup { [ZeroSystemStateMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroSystemStateMessage EXCEPT !.systemStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Compact Top Of Market Bid Message: 15 bytes                             *)
(***************************************************************************)

CompactTopOfMarketBidMessage ==
    [ nanoseconds              : Sample(4),
      productId                : Sample(4),
      pbboPrice                : Sample(2),
      pbboSize                 : Sample(2),
      pbboPriorityCustomerSize : Sample(2),
      pbboCondition            : Sample(1) ]

EncodeCompactTopOfMarketBidMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.pbboPrice
        \o message.pbboSize
        \o message.pbboPriorityCustomerSize
        \o message.pbboCondition

DecodeCompactTopOfMarketBidMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET pbboPrice == ReadBytes(productId.rest, 2) IN IF ~pbboPrice.ok THEN Fail ELSE
    LET pbboSize == ReadBytes(pbboPrice.rest, 2) IN IF ~pbboSize.ok THEN Fail ELSE
    LET pbboPriorityCustomerSize == ReadBytes(pbboSize.rest, 2) IN IF ~pbboPriorityCustomerSize.ok THEN Fail ELSE
    LET pbboCondition == ReadBytes(pbboPriorityCustomerSize.rest, 1) IN IF ~pbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds              |-> nanoseconds.value,
         productId                |-> productId.value,
         pbboPrice                |-> pbboPrice.value,
         pbboSize                 |-> pbboSize.value,
         pbboPriorityCustomerSize |-> pbboPriorityCustomerSize.value,
         pbboCondition            |-> pbboCondition.value ], pbboCondition.rest)

ZeroCompactTopOfMarketBidMessage ==
    [ nanoseconds              |-> [i \in 1 .. 4 |-> 0],
      productId                |-> [i \in 1 .. 4 |-> 0],
      pbboPrice                |-> [i \in 1 .. 2 |-> 0],
      pbboSize                 |-> [i \in 1 .. 2 |-> 0],
      pbboPriorityCustomerSize |-> [i \in 1 .. 2 |-> 0],
      pbboCondition            |-> [i \in 1 .. 1 |-> 0] ]

(* Compact Top Of Market Bid Message at zero, then each field in turn at the values it is checked at *)
CheckedCompactTopOfMarketBidMessage ==
    { ZeroCompactTopOfMarketBidMessage }
        \cup { [ZeroCompactTopOfMarketBidMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCompactTopOfMarketBidMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroCompactTopOfMarketBidMessage EXCEPT !.pbboPrice = one] : one \in Sample(2) }
        \cup { [ZeroCompactTopOfMarketBidMessage EXCEPT !.pbboSize = one] : one \in Sample(2) }
        \cup { [ZeroCompactTopOfMarketBidMessage EXCEPT !.pbboPriorityCustomerSize = one] : one \in Sample(2) }
        \cup { [ZeroCompactTopOfMarketBidMessage EXCEPT !.pbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Compact Top Of Market Best Offer Message: 15 bytes                      *)
(***************************************************************************)

CompactTopOfMarketBestOfferMessage ==
    [ nanoseconds              : Sample(4),
      productId                : Sample(4),
      pbboPrice                : Sample(2),
      pbboSize                 : Sample(2),
      pbboPriorityCustomerSize : Sample(2),
      pbboCondition            : Sample(1) ]

EncodeCompactTopOfMarketBestOfferMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.pbboPrice
        \o message.pbboSize
        \o message.pbboPriorityCustomerSize
        \o message.pbboCondition

DecodeCompactTopOfMarketBestOfferMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET pbboPrice == ReadBytes(productId.rest, 2) IN IF ~pbboPrice.ok THEN Fail ELSE
    LET pbboSize == ReadBytes(pbboPrice.rest, 2) IN IF ~pbboSize.ok THEN Fail ELSE
    LET pbboPriorityCustomerSize == ReadBytes(pbboSize.rest, 2) IN IF ~pbboPriorityCustomerSize.ok THEN Fail ELSE
    LET pbboCondition == ReadBytes(pbboPriorityCustomerSize.rest, 1) IN IF ~pbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds              |-> nanoseconds.value,
         productId                |-> productId.value,
         pbboPrice                |-> pbboPrice.value,
         pbboSize                 |-> pbboSize.value,
         pbboPriorityCustomerSize |-> pbboPriorityCustomerSize.value,
         pbboCondition            |-> pbboCondition.value ], pbboCondition.rest)

ZeroCompactTopOfMarketBestOfferMessage ==
    [ nanoseconds              |-> [i \in 1 .. 4 |-> 0],
      productId                |-> [i \in 1 .. 4 |-> 0],
      pbboPrice                |-> [i \in 1 .. 2 |-> 0],
      pbboSize                 |-> [i \in 1 .. 2 |-> 0],
      pbboPriorityCustomerSize |-> [i \in 1 .. 2 |-> 0],
      pbboCondition            |-> [i \in 1 .. 1 |-> 0] ]

(* Compact Top Of Market Best Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedCompactTopOfMarketBestOfferMessage ==
    { ZeroCompactTopOfMarketBestOfferMessage }
        \cup { [ZeroCompactTopOfMarketBestOfferMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCompactTopOfMarketBestOfferMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroCompactTopOfMarketBestOfferMessage EXCEPT !.pbboPrice = one] : one \in Sample(2) }
        \cup { [ZeroCompactTopOfMarketBestOfferMessage EXCEPT !.pbboSize = one] : one \in Sample(2) }
        \cup { [ZeroCompactTopOfMarketBestOfferMessage EXCEPT !.pbboPriorityCustomerSize = one] : one \in Sample(2) }
        \cup { [ZeroCompactTopOfMarketBestOfferMessage EXCEPT !.pbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Wide Top Of Market Best Bid Message: 21 bytes                           *)
(***************************************************************************)

WideTopOfMarketBestBidMessage ==
    [ nanoseconds                  : Sample(4),
      productId                    : Sample(4),
      widePbboPrice                : Sample(4),
      widePbboSize                 : Sample(4),
      widePbboPriorityCustomerSize : Sample(4),
      pbboCondition                : Sample(1) ]

EncodeWideTopOfMarketBestBidMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.widePbboPrice
        \o message.widePbboSize
        \o message.widePbboPriorityCustomerSize
        \o message.pbboCondition

DecodeWideTopOfMarketBestBidMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET widePbboPrice == ReadBytes(productId.rest, 4) IN IF ~widePbboPrice.ok THEN Fail ELSE
    LET widePbboSize == ReadBytes(widePbboPrice.rest, 4) IN IF ~widePbboSize.ok THEN Fail ELSE
    LET widePbboPriorityCustomerSize == ReadBytes(widePbboSize.rest, 4) IN IF ~widePbboPriorityCustomerSize.ok THEN Fail ELSE
    LET pbboCondition == ReadBytes(widePbboPriorityCustomerSize.rest, 1) IN IF ~pbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         productId                    |-> productId.value,
         widePbboPrice                |-> widePbboPrice.value,
         widePbboSize                 |-> widePbboSize.value,
         widePbboPriorityCustomerSize |-> widePbboPriorityCustomerSize.value,
         pbboCondition                |-> pbboCondition.value ], pbboCondition.rest)

ZeroWideTopOfMarketBestBidMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      productId                    |-> [i \in 1 .. 4 |-> 0],
      widePbboPrice                |-> [i \in 1 .. 4 |-> 0],
      widePbboSize                 |-> [i \in 1 .. 4 |-> 0],
      widePbboPriorityCustomerSize |-> [i \in 1 .. 4 |-> 0],
      pbboCondition                |-> [i \in 1 .. 1 |-> 0] ]

(* Wide Top Of Market Best Bid Message at zero, then each field in turn at the values it is checked at *)
CheckedWideTopOfMarketBestBidMessage ==
    { ZeroWideTopOfMarketBestBidMessage }
        \cup { [ZeroWideTopOfMarketBestBidMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroWideTopOfMarketBestBidMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroWideTopOfMarketBestBidMessage EXCEPT !.widePbboPrice = one] : one \in Sample(4) }
        \cup { [ZeroWideTopOfMarketBestBidMessage EXCEPT !.widePbboSize = one] : one \in Sample(4) }
        \cup { [ZeroWideTopOfMarketBestBidMessage EXCEPT !.widePbboPriorityCustomerSize = one] : one \in Sample(4) }
        \cup { [ZeroWideTopOfMarketBestBidMessage EXCEPT !.pbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Wide Top Of Market Best Offer Message: 21 bytes                         *)
(***************************************************************************)

WideTopOfMarketBestOfferMessage ==
    [ nanoseconds                  : Sample(4),
      productId                    : Sample(4),
      widePbboPrice                : Sample(4),
      widePbboSize                 : Sample(4),
      widePbboPriorityCustomerSize : Sample(4),
      pbboCondition                : Sample(1) ]

EncodeWideTopOfMarketBestOfferMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.widePbboPrice
        \o message.widePbboSize
        \o message.widePbboPriorityCustomerSize
        \o message.pbboCondition

DecodeWideTopOfMarketBestOfferMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET widePbboPrice == ReadBytes(productId.rest, 4) IN IF ~widePbboPrice.ok THEN Fail ELSE
    LET widePbboSize == ReadBytes(widePbboPrice.rest, 4) IN IF ~widePbboSize.ok THEN Fail ELSE
    LET widePbboPriorityCustomerSize == ReadBytes(widePbboSize.rest, 4) IN IF ~widePbboPriorityCustomerSize.ok THEN Fail ELSE
    LET pbboCondition == ReadBytes(widePbboPriorityCustomerSize.rest, 1) IN IF ~pbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         productId                    |-> productId.value,
         widePbboPrice                |-> widePbboPrice.value,
         widePbboSize                 |-> widePbboSize.value,
         widePbboPriorityCustomerSize |-> widePbboPriorityCustomerSize.value,
         pbboCondition                |-> pbboCondition.value ], pbboCondition.rest)

ZeroWideTopOfMarketBestOfferMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      productId                    |-> [i \in 1 .. 4 |-> 0],
      widePbboPrice                |-> [i \in 1 .. 4 |-> 0],
      widePbboSize                 |-> [i \in 1 .. 4 |-> 0],
      widePbboPriorityCustomerSize |-> [i \in 1 .. 4 |-> 0],
      pbboCondition                |-> [i \in 1 .. 1 |-> 0] ]

(* Wide Top Of Market Best Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedWideTopOfMarketBestOfferMessage ==
    { ZeroWideTopOfMarketBestOfferMessage }
        \cup { [ZeroWideTopOfMarketBestOfferMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroWideTopOfMarketBestOfferMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroWideTopOfMarketBestOfferMessage EXCEPT !.widePbboPrice = one] : one \in Sample(4) }
        \cup { [ZeroWideTopOfMarketBestOfferMessage EXCEPT !.widePbboSize = one] : one \in Sample(4) }
        \cup { [ZeroWideTopOfMarketBestOfferMessage EXCEPT !.widePbboPriorityCustomerSize = one] : one \in Sample(4) }
        \cup { [ZeroWideTopOfMarketBestOfferMessage EXCEPT !.pbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Compact Double Sided Top Of Market Message: 22 bytes                    *)
(***************************************************************************)

CompactDoubleSidedTopOfMarketMessage ==
    [ nanoseconds               : Sample(4),
      productId                 : Sample(4),
      bidPrice                  : Sample(2),
      bidSize                   : Sample(2),
      bidPriorityCustomerSize   : Sample(2),
      bidCondition              : Sample(1),
      offerPrice                : Sample(2),
      offerSize                 : Sample(2),
      offerPriorityCustomerSize : Sample(2),
      offerCondition            : Sample(1) ]

EncodeCompactDoubleSidedTopOfMarketMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.bidPrice
        \o message.bidSize
        \o message.bidPriorityCustomerSize
        \o message.bidCondition
        \o message.offerPrice
        \o message.offerSize
        \o message.offerPriorityCustomerSize
        \o message.offerCondition

DecodeCompactDoubleSidedTopOfMarketMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(productId.rest, 2) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 2) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidPriorityCustomerSize == ReadBytes(bidSize.rest, 2) IN IF ~bidPriorityCustomerSize.ok THEN Fail ELSE
    LET bidCondition == ReadBytes(bidPriorityCustomerSize.rest, 1) IN IF ~bidCondition.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(bidCondition.rest, 2) IN IF ~offerPrice.ok THEN Fail ELSE
    LET offerSize == ReadBytes(offerPrice.rest, 2) IN IF ~offerSize.ok THEN Fail ELSE
    LET offerPriorityCustomerSize == ReadBytes(offerSize.rest, 2) IN IF ~offerPriorityCustomerSize.ok THEN Fail ELSE
    LET offerCondition == ReadBytes(offerPriorityCustomerSize.rest, 1) IN IF ~offerCondition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         productId                 |-> productId.value,
         bidPrice                  |-> bidPrice.value,
         bidSize                   |-> bidSize.value,
         bidPriorityCustomerSize   |-> bidPriorityCustomerSize.value,
         bidCondition              |-> bidCondition.value,
         offerPrice                |-> offerPrice.value,
         offerSize                 |-> offerSize.value,
         offerPriorityCustomerSize |-> offerPriorityCustomerSize.value,
         offerCondition            |-> offerCondition.value ], offerCondition.rest)

ZeroCompactDoubleSidedTopOfMarketMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      productId                 |-> [i \in 1 .. 4 |-> 0],
      bidPrice                  |-> [i \in 1 .. 2 |-> 0],
      bidSize                   |-> [i \in 1 .. 2 |-> 0],
      bidPriorityCustomerSize   |-> [i \in 1 .. 2 |-> 0],
      bidCondition              |-> [i \in 1 .. 1 |-> 0],
      offerPrice                |-> [i \in 1 .. 2 |-> 0],
      offerSize                 |-> [i \in 1 .. 2 |-> 0],
      offerPriorityCustomerSize |-> [i \in 1 .. 2 |-> 0],
      offerCondition            |-> [i \in 1 .. 1 |-> 0] ]

(* Compact Double Sided Top Of Market Message at zero, then each field in turn at the values it is checked at *)
CheckedCompactDoubleSidedTopOfMarketMessage ==
    { ZeroCompactDoubleSidedTopOfMarketMessage }
        \cup { [ZeroCompactDoubleSidedTopOfMarketMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCompactDoubleSidedTopOfMarketMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroCompactDoubleSidedTopOfMarketMessage EXCEPT !.bidPrice = one] : one \in Sample(2) }
        \cup { [ZeroCompactDoubleSidedTopOfMarketMessage EXCEPT !.bidSize = one] : one \in Sample(2) }
        \cup { [ZeroCompactDoubleSidedTopOfMarketMessage EXCEPT !.bidPriorityCustomerSize = one] : one \in Sample(2) }
        \cup { [ZeroCompactDoubleSidedTopOfMarketMessage EXCEPT !.bidCondition = one] : one \in Sample(1) }
        \cup { [ZeroCompactDoubleSidedTopOfMarketMessage EXCEPT !.offerPrice = one] : one \in Sample(2) }
        \cup { [ZeroCompactDoubleSidedTopOfMarketMessage EXCEPT !.offerSize = one] : one \in Sample(2) }
        \cup { [ZeroCompactDoubleSidedTopOfMarketMessage EXCEPT !.offerPriorityCustomerSize = one] : one \in Sample(2) }
        \cup { [ZeroCompactDoubleSidedTopOfMarketMessage EXCEPT !.offerCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Wide Double Sided Top Of Market Message: 34 bytes                       *)
(***************************************************************************)

WideDoubleSidedTopOfMarketMessage ==
    [ nanoseconds                   : Sample(4),
      productId                     : Sample(4),
      wideBidPrice                  : Sample(4),
      wideBidSize                   : Sample(4),
      wideBidPriorityCustomerSize   : Sample(4),
      bidCondition                  : Sample(1),
      wideOfferPrice                : Sample(4),
      wideOfferSize                 : Sample(4),
      wideOfferPriorityCustomerSize : Sample(4),
      offerCondition                : Sample(1) ]

EncodeWideDoubleSidedTopOfMarketMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.wideBidPrice
        \o message.wideBidSize
        \o message.wideBidPriorityCustomerSize
        \o message.bidCondition
        \o message.wideOfferPrice
        \o message.wideOfferSize
        \o message.wideOfferPriorityCustomerSize
        \o message.offerCondition

DecodeWideDoubleSidedTopOfMarketMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET wideBidPrice == ReadBytes(productId.rest, 4) IN IF ~wideBidPrice.ok THEN Fail ELSE
    LET wideBidSize == ReadBytes(wideBidPrice.rest, 4) IN IF ~wideBidSize.ok THEN Fail ELSE
    LET wideBidPriorityCustomerSize == ReadBytes(wideBidSize.rest, 4) IN IF ~wideBidPriorityCustomerSize.ok THEN Fail ELSE
    LET bidCondition == ReadBytes(wideBidPriorityCustomerSize.rest, 1) IN IF ~bidCondition.ok THEN Fail ELSE
    LET wideOfferPrice == ReadBytes(bidCondition.rest, 4) IN IF ~wideOfferPrice.ok THEN Fail ELSE
    LET wideOfferSize == ReadBytes(wideOfferPrice.rest, 4) IN IF ~wideOfferSize.ok THEN Fail ELSE
    LET wideOfferPriorityCustomerSize == ReadBytes(wideOfferSize.rest, 4) IN IF ~wideOfferPriorityCustomerSize.ok THEN Fail ELSE
    LET offerCondition == ReadBytes(wideOfferPriorityCustomerSize.rest, 1) IN IF ~offerCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                   |-> nanoseconds.value,
         productId                     |-> productId.value,
         wideBidPrice                  |-> wideBidPrice.value,
         wideBidSize                   |-> wideBidSize.value,
         wideBidPriorityCustomerSize   |-> wideBidPriorityCustomerSize.value,
         bidCondition                  |-> bidCondition.value,
         wideOfferPrice                |-> wideOfferPrice.value,
         wideOfferSize                 |-> wideOfferSize.value,
         wideOfferPriorityCustomerSize |-> wideOfferPriorityCustomerSize.value,
         offerCondition                |-> offerCondition.value ], offerCondition.rest)

ZeroWideDoubleSidedTopOfMarketMessage ==
    [ nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      productId                     |-> [i \in 1 .. 4 |-> 0],
      wideBidPrice                  |-> [i \in 1 .. 4 |-> 0],
      wideBidSize                   |-> [i \in 1 .. 4 |-> 0],
      wideBidPriorityCustomerSize   |-> [i \in 1 .. 4 |-> 0],
      bidCondition                  |-> [i \in 1 .. 1 |-> 0],
      wideOfferPrice                |-> [i \in 1 .. 4 |-> 0],
      wideOfferSize                 |-> [i \in 1 .. 4 |-> 0],
      wideOfferPriorityCustomerSize |-> [i \in 1 .. 4 |-> 0],
      offerCondition                |-> [i \in 1 .. 1 |-> 0] ]

(* Wide Double Sided Top Of Market Message at zero, then each field in turn at the values it is checked at *)
CheckedWideDoubleSidedTopOfMarketMessage ==
    { ZeroWideDoubleSidedTopOfMarketMessage }
        \cup { [ZeroWideDoubleSidedTopOfMarketMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroWideDoubleSidedTopOfMarketMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroWideDoubleSidedTopOfMarketMessage EXCEPT !.wideBidPrice = one] : one \in Sample(4) }
        \cup { [ZeroWideDoubleSidedTopOfMarketMessage EXCEPT !.wideBidSize = one] : one \in Sample(4) }
        \cup { [ZeroWideDoubleSidedTopOfMarketMessage EXCEPT !.wideBidPriorityCustomerSize = one] : one \in Sample(4) }
        \cup { [ZeroWideDoubleSidedTopOfMarketMessage EXCEPT !.bidCondition = one] : one \in Sample(1) }
        \cup { [ZeroWideDoubleSidedTopOfMarketMessage EXCEPT !.wideOfferPrice = one] : one \in Sample(4) }
        \cup { [ZeroWideDoubleSidedTopOfMarketMessage EXCEPT !.wideOfferSize = one] : one \in Sample(4) }
        \cup { [ZeroWideDoubleSidedTopOfMarketMessage EXCEPT !.wideOfferPriorityCustomerSize = one] : one \in Sample(4) }
        \cup { [ZeroWideDoubleSidedTopOfMarketMessage EXCEPT !.offerCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Last Sale Message: 27 bytes                                             *)
(***************************************************************************)

LastSaleMessage ==
    [ nanoseconds               : Sample(4),
      productId                 : Sample(4),
      tradeId                   : Sample(4),
      correctionNumber          : Sample(1),
      referenceTradeId          : Sample(4),
      referenceCorrectionNumber : Sample(1),
      tradePrice                : Sample(4),
      tradeSize                 : Sample(4),
      tradeCondition            : Sample(1) ]

EncodeLastSaleMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.tradeId
        \o message.correctionNumber
        \o message.referenceTradeId
        \o message.referenceCorrectionNumber
        \o message.tradePrice
        \o message.tradeSize
        \o message.tradeCondition

DecodeLastSaleMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(productId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(tradeId.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET referenceTradeId == ReadBytes(correctionNumber.rest, 4) IN IF ~referenceTradeId.ok THEN Fail ELSE
    LET referenceCorrectionNumber == ReadBytes(referenceTradeId.rest, 1) IN IF ~referenceCorrectionNumber.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(referenceCorrectionNumber.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeSize == ReadBytes(tradePrice.rest, 4) IN IF ~tradeSize.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(tradeSize.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         productId                 |-> productId.value,
         tradeId                   |-> tradeId.value,
         correctionNumber          |-> correctionNumber.value,
         referenceTradeId          |-> referenceTradeId.value,
         referenceCorrectionNumber |-> referenceCorrectionNumber.value,
         tradePrice                |-> tradePrice.value,
         tradeSize                 |-> tradeSize.value,
         tradeCondition            |-> tradeCondition.value ], tradeCondition.rest)

ZeroLastSaleMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      productId                 |-> [i \in 1 .. 4 |-> 0],
      tradeId                   |-> [i \in 1 .. 4 |-> 0],
      correctionNumber          |-> [i \in 1 .. 1 |-> 0],
      referenceTradeId          |-> [i \in 1 .. 4 |-> 0],
      referenceCorrectionNumber |-> [i \in 1 .. 1 |-> 0],
      tradePrice                |-> [i \in 1 .. 4 |-> 0],
      tradeSize                 |-> [i \in 1 .. 4 |-> 0],
      tradeCondition            |-> [i \in 1 .. 1 |-> 0] ]

(* Last Sale Message at zero, then each field in turn at the values it is checked at *)
CheckedLastSaleMessage ==
    { ZeroLastSaleMessage }
        \cup { [ZeroLastSaleMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.correctionNumber = one] : one \in Sample(1) }
        \cup { [ZeroLastSaleMessage EXCEPT !.referenceTradeId = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.referenceCorrectionNumber = one] : one \in Sample(1) }
        \cup { [ZeroLastSaleMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.tradeSize = one] : one \in Sample(4) }
        \cup { [ZeroLastSaleMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancel Message: 22 bytes                                          *)
(***************************************************************************)

TradeCancelMessage ==
    [ nanoseconds      : Sample(4),
      productId        : Sample(4),
      tradeId          : Sample(4),
      correctionNumber : Sample(1),
      tradePrice       : Sample(4),
      tradeSize        : Sample(4),
      tradeCondition   : Sample(1) ]

EncodeTradeCancelMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.tradeId
        \o message.correctionNumber
        \o message.tradePrice
        \o message.tradeSize
        \o message.tradeCondition

DecodeTradeCancelMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET tradeId == ReadBytes(productId.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(tradeId.rest, 1) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(correctionNumber.rest, 4) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeSize == ReadBytes(tradePrice.rest, 4) IN IF ~tradeSize.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(tradeSize.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ nanoseconds      |-> nanoseconds.value,
         productId        |-> productId.value,
         tradeId          |-> tradeId.value,
         correctionNumber |-> correctionNumber.value,
         tradePrice       |-> tradePrice.value,
         tradeSize        |-> tradeSize.value,
         tradeCondition   |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeCancelMessage ==
    [ nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      productId        |-> [i \in 1 .. 4 |-> 0],
      tradeId          |-> [i \in 1 .. 4 |-> 0],
      correctionNumber |-> [i \in 1 .. 1 |-> 0],
      tradePrice       |-> [i \in 1 .. 4 |-> 0],
      tradeSize        |-> [i \in 1 .. 4 |-> 0],
      tradeCondition   |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelMessage ==
    { ZeroTradeCancelMessage }
        \cup { [ZeroTradeCancelMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.correctionNumber = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.tradePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.tradeSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Underlying Trading Status Notification: 25 bytes                        *)
(***************************************************************************)

UnderlyingTradingStatusNotification ==
    [ nanoseconds                      : Sample(4),
      underlyingSymbol                 : Sample(11),
      tradingStatus                    : Sample(1),
      eventReason                      : Sample(1),
      expectedEventTimeSecondsPart     : Sample(4),
      expectedEventTimeNanoSecondsPart : Sample(4) ]

EncodeUnderlyingTradingStatusNotification(message) ==
    message.nanoseconds
        \o message.underlyingSymbol
        \o message.tradingStatus
        \o message.eventReason
        \o message.expectedEventTimeSecondsPart
        \o message.expectedEventTimeNanoSecondsPart

DecodeUnderlyingTradingStatusNotification(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(nanoseconds.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(underlyingSymbol.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET eventReason == ReadBytes(tradingStatus.rest, 1) IN IF ~eventReason.ok THEN Fail ELSE
    LET expectedEventTimeSecondsPart == ReadBytes(eventReason.rest, 4) IN IF ~expectedEventTimeSecondsPart.ok THEN Fail ELSE
    LET expectedEventTimeNanoSecondsPart == ReadBytes(expectedEventTimeSecondsPart.rest, 4) IN IF ~expectedEventTimeNanoSecondsPart.ok THEN Fail ELSE
    Ok([ nanoseconds                      |-> nanoseconds.value,
         underlyingSymbol                 |-> underlyingSymbol.value,
         tradingStatus                    |-> tradingStatus.value,
         eventReason                      |-> eventReason.value,
         expectedEventTimeSecondsPart     |-> expectedEventTimeSecondsPart.value,
         expectedEventTimeNanoSecondsPart |-> expectedEventTimeNanoSecondsPart.value ], expectedEventTimeNanoSecondsPart.rest)

ZeroUnderlyingTradingStatusNotification ==
    [ nanoseconds                      |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol                 |-> [i \in 1 .. 11 |-> 0],
      tradingStatus                    |-> [i \in 1 .. 1 |-> 0],
      eventReason                      |-> [i \in 1 .. 1 |-> 0],
      expectedEventTimeSecondsPart     |-> [i \in 1 .. 4 |-> 0],
      expectedEventTimeNanoSecondsPart |-> [i \in 1 .. 4 |-> 0] ]

(* Underlying Trading Status Notification at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingTradingStatusNotification ==
    { ZeroUnderlyingTradingStatusNotification }
        \cup { [ZeroUnderlyingTradingStatusNotification EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingTradingStatusNotification EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroUnderlyingTradingStatusNotification EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingTradingStatusNotification EXCEPT !.eventReason = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingTradingStatusNotification EXCEPT !.expectedEventTimeSecondsPart = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingTradingStatusNotification EXCEPT !.expectedEventTimeNanoSecondsPart = one] : one \in Sample(4) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SystemTimeMessageCode == 49  \* "1"
SeriesUpdateMessageCode == 80  \* "P"
SystemStateMessageCode == 83  \* "S"
CompactTopOfMarketBidMessageCode == 66  \* "B"
CompactTopOfMarketBestOfferMessageCode == 79  \* "O"
WideTopOfMarketBestBidMessageCode == 87  \* "W"
WideTopOfMarketBestOfferMessageCode == 65  \* "A"
CompactDoubleSidedTopOfMarketMessageCode == 100  \* "d"
WideDoubleSidedTopOfMarketMessageCode == 68  \* "D"
LastSaleMessageCode == 84  \* "T"
TradeCancelMessageCode == 88  \* "X"
UnderlyingTradingStatusNotificationCode == 72  \* "H"

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SeriesUpdateMessageCode}, body : SeriesUpdateMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {CompactTopOfMarketBidMessageCode}, body : CompactTopOfMarketBidMessage ]
        \cup [ tag : {CompactTopOfMarketBestOfferMessageCode}, body : CompactTopOfMarketBestOfferMessage ]
        \cup [ tag : {WideTopOfMarketBestBidMessageCode}, body : WideTopOfMarketBestBidMessage ]
        \cup [ tag : {WideTopOfMarketBestOfferMessageCode}, body : WideTopOfMarketBestOfferMessage ]
        \cup [ tag : {CompactDoubleSidedTopOfMarketMessageCode}, body : CompactDoubleSidedTopOfMarketMessage ]
        \cup [ tag : {WideDoubleSidedTopOfMarketMessageCode}, body : WideDoubleSidedTopOfMarketMessage ]
        \cup [ tag : {LastSaleMessageCode}, body : LastSaleMessage ]
        \cup [ tag : {TradeCancelMessageCode}, body : TradeCancelMessage ]
        \cup [ tag : {UnderlyingTradingStatusNotificationCode}, body : UnderlyingTradingStatusNotification ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SeriesUpdateMessageCode -> EncodeSeriesUpdateMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = CompactTopOfMarketBidMessageCode -> EncodeCompactTopOfMarketBidMessage(message.body)
      [] message.tag = CompactTopOfMarketBestOfferMessageCode -> EncodeCompactTopOfMarketBestOfferMessage(message.body)
      [] message.tag = WideTopOfMarketBestBidMessageCode -> EncodeWideTopOfMarketBestBidMessage(message.body)
      [] message.tag = WideTopOfMarketBestOfferMessageCode -> EncodeWideTopOfMarketBestOfferMessage(message.body)
      [] message.tag = CompactDoubleSidedTopOfMarketMessageCode -> EncodeCompactDoubleSidedTopOfMarketMessage(message.body)
      [] message.tag = WideDoubleSidedTopOfMarketMessageCode -> EncodeWideDoubleSidedTopOfMarketMessage(message.body)
      [] message.tag = LastSaleMessageCode -> EncodeLastSaleMessage(message.body)
      [] message.tag = TradeCancelMessageCode -> EncodeTradeCancelMessage(message.body)
      [] message.tag = UnderlyingTradingStatusNotificationCode -> EncodeUnderlyingTradingStatusNotification(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SeriesUpdateMessageCode -> DecodeSeriesUpdateMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = CompactTopOfMarketBidMessageCode -> DecodeCompactTopOfMarketBidMessage(bytes)
              [] tag = CompactTopOfMarketBestOfferMessageCode -> DecodeCompactTopOfMarketBestOfferMessage(bytes)
              [] tag = WideTopOfMarketBestBidMessageCode -> DecodeWideTopOfMarketBestBidMessage(bytes)
              [] tag = WideTopOfMarketBestOfferMessageCode -> DecodeWideTopOfMarketBestOfferMessage(bytes)
              [] tag = CompactDoubleSidedTopOfMarketMessageCode -> DecodeCompactDoubleSidedTopOfMarketMessage(bytes)
              [] tag = WideDoubleSidedTopOfMarketMessageCode -> DecodeWideDoubleSidedTopOfMarketMessage(bytes)
              [] tag = LastSaleMessageCode -> DecodeLastSaleMessage(bytes)
              [] tag = TradeCancelMessageCode -> DecodeTradeCancelMessage(bytes)
              [] tag = UnderlyingTradingStatusNotificationCode -> DecodeUnderlyingTradingStatusNotification(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData == [tag |-> SystemTimeMessageCode, body |-> ZeroSystemTimeMessage]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData ==
    { [tag |-> SystemTimeMessageCode, body |-> one] : one \in CheckedSystemTimeMessage }
        \cup { [tag |-> SeriesUpdateMessageCode, body |-> one] : one \in CheckedSeriesUpdateMessage }
        \cup { [tag |-> SystemStateMessageCode, body |-> one] : one \in CheckedSystemStateMessage }
        \cup { [tag |-> CompactTopOfMarketBidMessageCode, body |-> one] : one \in CheckedCompactTopOfMarketBidMessage }
        \cup { [tag |-> CompactTopOfMarketBestOfferMessageCode, body |-> one] : one \in CheckedCompactTopOfMarketBestOfferMessage }
        \cup { [tag |-> WideTopOfMarketBestBidMessageCode, body |-> one] : one \in CheckedWideTopOfMarketBestBidMessage }
        \cup { [tag |-> WideTopOfMarketBestOfferMessageCode, body |-> one] : one \in CheckedWideTopOfMarketBestOfferMessage }
        \cup { [tag |-> CompactDoubleSidedTopOfMarketMessageCode, body |-> one] : one \in CheckedCompactDoubleSidedTopOfMarketMessage }
        \cup { [tag |-> WideDoubleSidedTopOfMarketMessageCode, body |-> one] : one \in CheckedWideDoubleSidedTopOfMarketMessage }
        \cup { [tag |-> LastSaleMessageCode, body |-> one] : one \in CheckedLastSaleMessage }
        \cup { [tag |-> TradeCancelMessageCode, body |-> one] : one \in CheckedTradeCancelMessage }
        \cup { [tag |-> UnderlyingTradingStatusNotificationCode, body |-> one] : one \in CheckedUnderlyingTradingStatusNotification }

(***************************************************************************)
(* Application Message                                                     *)
(***************************************************************************)

ApplicationMessage ==
    [ data : Data ]

EncodeApplicationMessage(message) ==
    EncodeUIntBE(message.data.tag, 1)
        \o EncodeData(message.data)

DecodeApplicationMessage(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET data == DecodeData(messageType.value, messageType.rest) IN IF ~data.ok THEN Fail ELSE
    Ok([ data |-> data.value ], data.rest)

ZeroApplicationMessage ==
    [ data |-> ZeroData ]

(* Application Message at zero, then each field in turn at the values it is checked at *)
CheckedApplicationMessage ==
    { ZeroApplicationMessage }
        \cup { [ZeroApplicationMessage EXCEPT !.data = one] : one \in CheckedData }

(***************************************************************************)
(* Payload, selected by Packet Type                                        *)
(***************************************************************************)

ApplicationMessageCode == 3  \* 0x03
HeartbeatCode == 0  \* 0x00
StartOfSessionCode == 1  \* 0x01
EndOfSessionCode == 2  \* 0x02

Payload ==
    [ tag : {ApplicationMessageCode}, body : ApplicationMessage ]
        \cup [ tag : {HeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {StartOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]

EncodePayload(message) ==
    CASE message.tag = ApplicationMessageCode -> EncodeApplicationMessage(message.body)
      [] message.tag = HeartbeatCode -> << >>
      [] message.tag = StartOfSessionCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = ApplicationMessageCode -> DecodeApplicationMessage(bytes)
              [] tag = HeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = StartOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> ApplicationMessageCode, body |-> ZeroApplicationMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> ApplicationMessageCode, body |-> one] : one \in CheckedApplicationMessage }
        \cup { [tag |-> HeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> StartOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Mach Message, framed by Packet Length                                   *)
(***************************************************************************)

MachMessage ==
    [ sequenceNumber : Sample(8),
      sessionNumber  : Sample(1),
      payload        : Payload ]

EncodeMachMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o message.sessionNumber
        \o EncodePayload(message.payload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeMachMessage(message) ==
    LET body == EncodeMachMessageBody(message)
    IN  message.sequenceNumber \o EncodeUIntLE(Len(body) + 10, 2) \o body

DecodeMachMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET length == ReadUIntLE(sequenceNumber.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 10 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET packetType == ReadUIntLE(framed, 1) IN IF ~packetType.ok THEN Fail ELSE
    LET sessionNumber == ReadBytes(packetType.rest, 1) IN IF ~sessionNumber.ok THEN Fail ELSE
    LET payload == DecodePayload(packetType.value, sessionNumber.rest) IN IF ~payload.ok THEN Fail ELSE
    IF payload.rest # << >> THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         sessionNumber  |-> sessionNumber.value,
         payload        |-> payload.value ], beyond)

ZeroMachMessage ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      sessionNumber  |-> [i \in 1 .. 1 |-> 0],
      payload        |-> ZeroPayload ]

(* Mach Message at zero, then each field in turn at the values it is checked at *)
CheckedMachMessage ==
    { ZeroMachMessage }
        \cup { [ZeroMachMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroMachMessage EXCEPT !.sessionNumber = one] : one \in Sample(1) }
        \cup { [ZeroMachMessage EXCEPT !.payload = one] : one \in CheckedPayload }

(* A run of Mach Message, written one after another *)
RECURSIVE EncodeMachMessageList(_)
EncodeMachMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMachMessage(Head(messages)) \o EncodeMachMessageList(Tail(messages))

(* As many Mach Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMachMessageAll(_)
ReadMachMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMachMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMachMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mach Message of each kind, for the lists that carry them *)
OneMachMessage ==
    { [ZeroMachMessage EXCEPT !.payload = [tag |-> ApplicationMessageCode, body |-> ZeroApplicationMessage]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> HeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> StartOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ machMessage : SampleLists(OneMachMessage) ]

EncodePacket(message) ==
    EncodeMachMessageList(message.machMessage)

DecodePacket(bytes) ==
    LET machMessage == ReadMachMessageAll(bytes) IN IF ~machMessage.ok THEN Fail ELSE
    Ok([ machMessage |-> machMessage.value ], machMessage.rest)

ZeroPacket ==
    [ machMessage |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.machMessage = one] : one \in SampleLists(OneMachMessage) }

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

(* Every System Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemTimeMessage ==
    \A message \in CheckedSystemTimeMessage :
        LET read == DecodeSystemTimeMessage(EncodeSystemTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Series Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSeriesUpdateMessage ==
    \A message \in CheckedSeriesUpdateMessage :
        LET read == DecodeSeriesUpdateMessage(EncodeSeriesUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System State Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemStateMessage ==
    \A message \in CheckedSystemStateMessage :
        LET read == DecodeSystemStateMessage(EncodeSystemStateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Compact Top Of Market Bid Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCompactTopOfMarketBidMessage ==
    \A message \in CheckedCompactTopOfMarketBidMessage :
        LET read == DecodeCompactTopOfMarketBidMessage(EncodeCompactTopOfMarketBidMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Compact Top Of Market Best Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCompactTopOfMarketBestOfferMessage ==
    \A message \in CheckedCompactTopOfMarketBestOfferMessage :
        LET read == DecodeCompactTopOfMarketBestOfferMessage(EncodeCompactTopOfMarketBestOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wide Top Of Market Best Bid Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWideTopOfMarketBestBidMessage ==
    \A message \in CheckedWideTopOfMarketBestBidMessage :
        LET read == DecodeWideTopOfMarketBestBidMessage(EncodeWideTopOfMarketBestBidMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wide Top Of Market Best Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWideTopOfMarketBestOfferMessage ==
    \A message \in CheckedWideTopOfMarketBestOfferMessage :
        LET read == DecodeWideTopOfMarketBestOfferMessage(EncodeWideTopOfMarketBestOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Compact Double Sided Top Of Market Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCompactDoubleSidedTopOfMarketMessage ==
    \A message \in CheckedCompactDoubleSidedTopOfMarketMessage :
        LET read == DecodeCompactDoubleSidedTopOfMarketMessage(EncodeCompactDoubleSidedTopOfMarketMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wide Double Sided Top Of Market Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWideDoubleSidedTopOfMarketMessage ==
    \A message \in CheckedWideDoubleSidedTopOfMarketMessage :
        LET read == DecodeWideDoubleSidedTopOfMarketMessage(EncodeWideDoubleSidedTopOfMarketMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Last Sale Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLastSaleMessage ==
    \A message \in CheckedLastSaleMessage :
        LET read == DecodeLastSaleMessage(EncodeLastSaleMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelMessage ==
    \A message \in CheckedTradeCancelMessage :
        LET read == DecodeTradeCancelMessage(EncodeTradeCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Underlying Trading Status Notification decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingTradingStatusNotification ==
    \A message \in CheckedUnderlyingTradingStatusNotification :
        LET read == DecodeUnderlyingTradingStatusNotification(EncodeUnderlyingTradingStatusNotification(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Application Message decodes back to what was encoded, and leaves nothing over *)
RoundTripApplicationMessage ==
    \A message \in CheckedApplicationMessage :
        LET read == DecodeApplicationMessage(EncodeApplicationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mach Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMachMessage ==
    \A message \in CheckedMachMessage :
        LET read == DecodeMachMessage(EncodeMachMessage(message))
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

(* A Data is selected by the Message Type it is written under *)
SelectsData ==
    \A message \in CheckedData :
        LET read == DecodeData(message.tag, EncodeData(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Packet Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesMachMessage ==
    \A message \in CheckedMachMessage :
        LET bytes == EncodeMachMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 9, 10)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
