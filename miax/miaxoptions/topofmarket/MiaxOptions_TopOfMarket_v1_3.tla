------------------- MODULE MiaxOptions_TopOfMarket_v1_3 --------------------
(***************************************************************************)
(* Miami International Holdings Top Of Market v1.3                         *)
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
(* License: MIT No Attribution                                             *)
(*                                                                         *)
(* Note: Application Message fills what is left of the frame Packet Length *)
(* states, which is what it is read from.                                  *)
(*                                                                         *)
(* Note: a Mach Message that ends the session is the last of its Packet:   *)
(* nothing may follow it.                                                  *)
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
      activeOnMiax                          : Sample(1),
      miaxBboPostingIncrementIndicator      : Sample(1),
      liquidityAcceptanceIncrementIndicator : Sample(1),
      openingUnderlyingMarketCode           : Sample(1),
      priorityQuoteWidth                    : Sample(4),
      reserved8                             : Sample(8) ]

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
        \o message.activeOnMiax
        \o message.miaxBboPostingIncrementIndicator
        \o message.liquidityAcceptanceIncrementIndicator
        \o message.openingUnderlyingMarketCode
        \o message.priorityQuoteWidth
        \o message.reserved8

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
    LET activeOnMiax == ReadBytes(longTermOption.rest, 1) IN IF ~activeOnMiax.ok THEN Fail ELSE
    LET miaxBboPostingIncrementIndicator == ReadBytes(activeOnMiax.rest, 1) IN IF ~miaxBboPostingIncrementIndicator.ok THEN Fail ELSE
    LET liquidityAcceptanceIncrementIndicator == ReadBytes(miaxBboPostingIncrementIndicator.rest, 1) IN IF ~liquidityAcceptanceIncrementIndicator.ok THEN Fail ELSE
    LET openingUnderlyingMarketCode == ReadBytes(liquidityAcceptanceIncrementIndicator.rest, 1) IN IF ~openingUnderlyingMarketCode.ok THEN Fail ELSE
    LET priorityQuoteWidth == ReadBytes(openingUnderlyingMarketCode.rest, 4) IN IF ~priorityQuoteWidth.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(priorityQuoteWidth.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
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
         activeOnMiax                          |-> activeOnMiax.value,
         miaxBboPostingIncrementIndicator      |-> miaxBboPostingIncrementIndicator.value,
         liquidityAcceptanceIncrementIndicator |-> liquidityAcceptanceIncrementIndicator.value,
         openingUnderlyingMarketCode           |-> openingUnderlyingMarketCode.value,
         priorityQuoteWidth                    |-> priorityQuoteWidth.value,
         reserved8                             |-> reserved8.value ], reserved8.rest)

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
      activeOnMiax                          |-> [i \in 1 .. 1 |-> 0],
      miaxBboPostingIncrementIndicator      |-> [i \in 1 .. 1 |-> 0],
      liquidityAcceptanceIncrementIndicator |-> [i \in 1 .. 1 |-> 0],
      openingUnderlyingMarketCode           |-> [i \in 1 .. 1 |-> 0],
      priorityQuoteWidth                    |-> [i \in 1 .. 4 |-> 0],
      reserved8                             |-> [i \in 1 .. 8 |-> 0] ]

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
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.activeOnMiax = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.miaxBboPostingIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.liquidityAcceptanceIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.openingUnderlyingMarketCode = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.priorityQuoteWidth = one] : one \in Sample(4) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

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
(* Top Of Market Bid Compact Message: 15 bytes                             *)
(***************************************************************************)

TopOfMarketBidCompactMessage ==
    [ nanoseconds   : Sample(4),
      productId     : Sample(4),
      mbboPrice2    : Sample(2),
      mbboSize2     : Sample(2),
      reserved2     : Sample(2),
      mbboCondition : Sample(1) ]

EncodeTopOfMarketBidCompactMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.mbboPrice2
        \o message.mbboSize2
        \o message.reserved2
        \o message.mbboCondition

DecodeTopOfMarketBidCompactMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET mbboPrice2 == ReadBytes(productId.rest, 2) IN IF ~mbboPrice2.ok THEN Fail ELSE
    LET mbboSize2 == ReadBytes(mbboPrice2.rest, 2) IN IF ~mbboSize2.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(mbboSize2.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET mbboCondition == ReadBytes(reserved2.rest, 1) IN IF ~mbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds   |-> nanoseconds.value,
         productId     |-> productId.value,
         mbboPrice2    |-> mbboPrice2.value,
         mbboSize2     |-> mbboSize2.value,
         reserved2     |-> reserved2.value,
         mbboCondition |-> mbboCondition.value ], mbboCondition.rest)

ZeroTopOfMarketBidCompactMessage ==
    [ nanoseconds   |-> [i \in 1 .. 4 |-> 0],
      productId     |-> [i \in 1 .. 4 |-> 0],
      mbboPrice2    |-> [i \in 1 .. 2 |-> 0],
      mbboSize2     |-> [i \in 1 .. 2 |-> 0],
      reserved2     |-> [i \in 1 .. 2 |-> 0],
      mbboCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Top Of Market Bid Compact Message at zero, then each field in turn at the values it is checked at *)
CheckedTopOfMarketBidCompactMessage ==
    { ZeroTopOfMarketBidCompactMessage }
        \cup { [ZeroTopOfMarketBidCompactMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTopOfMarketBidCompactMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroTopOfMarketBidCompactMessage EXCEPT !.mbboPrice2 = one] : one \in Sample(2) }
        \cup { [ZeroTopOfMarketBidCompactMessage EXCEPT !.mbboSize2 = one] : one \in Sample(2) }
        \cup { [ZeroTopOfMarketBidCompactMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTopOfMarketBidCompactMessage EXCEPT !.mbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Top Of Market Offer Compact Message: 15 bytes                           *)
(***************************************************************************)

TopOfMarketOfferCompactMessage ==
    [ nanoseconds   : Sample(4),
      productId     : Sample(4),
      mbboPrice2    : Sample(2),
      mbboSize2     : Sample(2),
      reserved2     : Sample(2),
      mbboCondition : Sample(1) ]

EncodeTopOfMarketOfferCompactMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.mbboPrice2
        \o message.mbboSize2
        \o message.reserved2
        \o message.mbboCondition

DecodeTopOfMarketOfferCompactMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET mbboPrice2 == ReadBytes(productId.rest, 2) IN IF ~mbboPrice2.ok THEN Fail ELSE
    LET mbboSize2 == ReadBytes(mbboPrice2.rest, 2) IN IF ~mbboSize2.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(mbboSize2.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET mbboCondition == ReadBytes(reserved2.rest, 1) IN IF ~mbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds   |-> nanoseconds.value,
         productId     |-> productId.value,
         mbboPrice2    |-> mbboPrice2.value,
         mbboSize2     |-> mbboSize2.value,
         reserved2     |-> reserved2.value,
         mbboCondition |-> mbboCondition.value ], mbboCondition.rest)

ZeroTopOfMarketOfferCompactMessage ==
    [ nanoseconds   |-> [i \in 1 .. 4 |-> 0],
      productId     |-> [i \in 1 .. 4 |-> 0],
      mbboPrice2    |-> [i \in 1 .. 2 |-> 0],
      mbboSize2     |-> [i \in 1 .. 2 |-> 0],
      reserved2     |-> [i \in 1 .. 2 |-> 0],
      mbboCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Top Of Market Offer Compact Message at zero, then each field in turn at the values it is checked at *)
CheckedTopOfMarketOfferCompactMessage ==
    { ZeroTopOfMarketOfferCompactMessage }
        \cup { [ZeroTopOfMarketOfferCompactMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTopOfMarketOfferCompactMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroTopOfMarketOfferCompactMessage EXCEPT !.mbboPrice2 = one] : one \in Sample(2) }
        \cup { [ZeroTopOfMarketOfferCompactMessage EXCEPT !.mbboSize2 = one] : one \in Sample(2) }
        \cup { [ZeroTopOfMarketOfferCompactMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTopOfMarketOfferCompactMessage EXCEPT !.mbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Top Of Market Bid Wide Message: 21 bytes                                *)
(***************************************************************************)

TopOfMarketBidWideMessage ==
    [ nanoseconds   : Sample(4),
      productId     : Sample(4),
      mbboPrice4    : Sample(4),
      mbboSize4     : Sample(4),
      reserved4     : Sample(4),
      mbboCondition : Sample(1) ]

EncodeTopOfMarketBidWideMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.mbboPrice4
        \o message.mbboSize4
        \o message.reserved4
        \o message.mbboCondition

DecodeTopOfMarketBidWideMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET mbboPrice4 == ReadBytes(productId.rest, 4) IN IF ~mbboPrice4.ok THEN Fail ELSE
    LET mbboSize4 == ReadBytes(mbboPrice4.rest, 4) IN IF ~mbboSize4.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(mbboSize4.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET mbboCondition == ReadBytes(reserved4.rest, 1) IN IF ~mbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds   |-> nanoseconds.value,
         productId     |-> productId.value,
         mbboPrice4    |-> mbboPrice4.value,
         mbboSize4     |-> mbboSize4.value,
         reserved4     |-> reserved4.value,
         mbboCondition |-> mbboCondition.value ], mbboCondition.rest)

ZeroTopOfMarketBidWideMessage ==
    [ nanoseconds   |-> [i \in 1 .. 4 |-> 0],
      productId     |-> [i \in 1 .. 4 |-> 0],
      mbboPrice4    |-> [i \in 1 .. 4 |-> 0],
      mbboSize4     |-> [i \in 1 .. 4 |-> 0],
      reserved4     |-> [i \in 1 .. 4 |-> 0],
      mbboCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Top Of Market Bid Wide Message at zero, then each field in turn at the values it is checked at *)
CheckedTopOfMarketBidWideMessage ==
    { ZeroTopOfMarketBidWideMessage }
        \cup { [ZeroTopOfMarketBidWideMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTopOfMarketBidWideMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroTopOfMarketBidWideMessage EXCEPT !.mbboPrice4 = one] : one \in Sample(4) }
        \cup { [ZeroTopOfMarketBidWideMessage EXCEPT !.mbboSize4 = one] : one \in Sample(4) }
        \cup { [ZeroTopOfMarketBidWideMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroTopOfMarketBidWideMessage EXCEPT !.mbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Top Of Market Offer Wide Message: 21 bytes                              *)
(***************************************************************************)

TopOfMarketOfferWideMessage ==
    [ nanoseconds   : Sample(4),
      productId     : Sample(4),
      mbboPrice4    : Sample(4),
      mbboSize4     : Sample(4),
      reserved4     : Sample(4),
      mbboCondition : Sample(1) ]

EncodeTopOfMarketOfferWideMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.mbboPrice4
        \o message.mbboSize4
        \o message.reserved4
        \o message.mbboCondition

DecodeTopOfMarketOfferWideMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET mbboPrice4 == ReadBytes(productId.rest, 4) IN IF ~mbboPrice4.ok THEN Fail ELSE
    LET mbboSize4 == ReadBytes(mbboPrice4.rest, 4) IN IF ~mbboSize4.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(mbboSize4.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET mbboCondition == ReadBytes(reserved4.rest, 1) IN IF ~mbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds   |-> nanoseconds.value,
         productId     |-> productId.value,
         mbboPrice4    |-> mbboPrice4.value,
         mbboSize4     |-> mbboSize4.value,
         reserved4     |-> reserved4.value,
         mbboCondition |-> mbboCondition.value ], mbboCondition.rest)

ZeroTopOfMarketOfferWideMessage ==
    [ nanoseconds   |-> [i \in 1 .. 4 |-> 0],
      productId     |-> [i \in 1 .. 4 |-> 0],
      mbboPrice4    |-> [i \in 1 .. 4 |-> 0],
      mbboSize4     |-> [i \in 1 .. 4 |-> 0],
      reserved4     |-> [i \in 1 .. 4 |-> 0],
      mbboCondition |-> [i \in 1 .. 1 |-> 0] ]

(* Top Of Market Offer Wide Message at zero, then each field in turn at the values it is checked at *)
CheckedTopOfMarketOfferWideMessage ==
    { ZeroTopOfMarketOfferWideMessage }
        \cup { [ZeroTopOfMarketOfferWideMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTopOfMarketOfferWideMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroTopOfMarketOfferWideMessage EXCEPT !.mbboPrice4 = one] : one \in Sample(4) }
        \cup { [ZeroTopOfMarketOfferWideMessage EXCEPT !.mbboSize4 = one] : one \in Sample(4) }
        \cup { [ZeroTopOfMarketOfferWideMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroTopOfMarketOfferWideMessage EXCEPT !.mbboCondition = one] : one \in Sample(1) }

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
(* Liquidity Seeking Event Notification Message: 46 bytes                  *)
(***************************************************************************)

LiquiditySeekingEventNotificationMessage ==
    [ nanoseconds   : Sample(4),
      productId     : Sample(4),
      eventType     : Sample(1),
      eventId       : Sample(4),
      price         : Sample(4),
      imbalanceSide : Sample(1),
      quantity1     : Sample(4),
      quantity2     : Sample(4),
      quantity3     : Sample(4),
      quantity4     : Sample(4),
      reserved12    : Sample(12) ]

EncodeLiquiditySeekingEventNotificationMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.eventType
        \o message.eventId
        \o message.price
        \o message.imbalanceSide
        \o message.quantity1
        \o message.quantity2
        \o message.quantity3
        \o message.quantity4
        \o message.reserved12

DecodeLiquiditySeekingEventNotificationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET eventType == ReadBytes(productId.rest, 1) IN IF ~eventType.ok THEN Fail ELSE
    LET eventId == ReadBytes(eventType.rest, 4) IN IF ~eventId.ok THEN Fail ELSE
    LET price == ReadBytes(eventId.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET imbalanceSide == ReadBytes(price.rest, 1) IN IF ~imbalanceSide.ok THEN Fail ELSE
    LET quantity1 == ReadBytes(imbalanceSide.rest, 4) IN IF ~quantity1.ok THEN Fail ELSE
    LET quantity2 == ReadBytes(quantity1.rest, 4) IN IF ~quantity2.ok THEN Fail ELSE
    LET quantity3 == ReadBytes(quantity2.rest, 4) IN IF ~quantity3.ok THEN Fail ELSE
    LET quantity4 == ReadBytes(quantity3.rest, 4) IN IF ~quantity4.ok THEN Fail ELSE
    LET reserved12 == ReadBytes(quantity4.rest, 12) IN IF ~reserved12.ok THEN Fail ELSE
    Ok([ nanoseconds   |-> nanoseconds.value,
         productId     |-> productId.value,
         eventType     |-> eventType.value,
         eventId       |-> eventId.value,
         price         |-> price.value,
         imbalanceSide |-> imbalanceSide.value,
         quantity1     |-> quantity1.value,
         quantity2     |-> quantity2.value,
         quantity3     |-> quantity3.value,
         quantity4     |-> quantity4.value,
         reserved12    |-> reserved12.value ], reserved12.rest)

ZeroLiquiditySeekingEventNotificationMessage ==
    [ nanoseconds   |-> [i \in 1 .. 4 |-> 0],
      productId     |-> [i \in 1 .. 4 |-> 0],
      eventType     |-> [i \in 1 .. 1 |-> 0],
      eventId       |-> [i \in 1 .. 4 |-> 0],
      price         |-> [i \in 1 .. 4 |-> 0],
      imbalanceSide |-> [i \in 1 .. 1 |-> 0],
      quantity1     |-> [i \in 1 .. 4 |-> 0],
      quantity2     |-> [i \in 1 .. 4 |-> 0],
      quantity3     |-> [i \in 1 .. 4 |-> 0],
      quantity4     |-> [i \in 1 .. 4 |-> 0],
      reserved12    |-> [i \in 1 .. 12 |-> 0] ]

(* Liquidity Seeking Event Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedLiquiditySeekingEventNotificationMessage ==
    { ZeroLiquiditySeekingEventNotificationMessage }
        \cup { [ZeroLiquiditySeekingEventNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotificationMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotificationMessage EXCEPT !.eventType = one] : one \in Sample(1) }
        \cup { [ZeroLiquiditySeekingEventNotificationMessage EXCEPT !.eventId = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotificationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotificationMessage EXCEPT !.imbalanceSide = one] : one \in Sample(1) }
        \cup { [ZeroLiquiditySeekingEventNotificationMessage EXCEPT !.quantity1 = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotificationMessage EXCEPT !.quantity2 = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotificationMessage EXCEPT !.quantity3 = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotificationMessage EXCEPT !.quantity4 = one] : one \in Sample(4) }
        \cup { [ZeroLiquiditySeekingEventNotificationMessage EXCEPT !.reserved12 = one] : one \in Sample(12) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SystemTimeMessageCode == 49  \* "1"
SeriesUpdateMessageCode == 80  \* "P"
SystemStateMessageCode == 83  \* "S"
TopOfMarketBidCompactMessageCode == 66  \* "B"
TopOfMarketOfferCompactMessageCode == 79  \* "O"
TopOfMarketBidWideMessageCode == 87  \* "W"
TopOfMarketOfferWideMessageCode == 65  \* "A"
LastSaleMessageCode == 84  \* "T"
TradeCancelMessageCode == 88  \* "X"
LiquiditySeekingEventNotificationMessageCode == 76  \* "L"

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SeriesUpdateMessageCode}, body : SeriesUpdateMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {TopOfMarketBidCompactMessageCode}, body : TopOfMarketBidCompactMessage ]
        \cup [ tag : {TopOfMarketOfferCompactMessageCode}, body : TopOfMarketOfferCompactMessage ]
        \cup [ tag : {TopOfMarketBidWideMessageCode}, body : TopOfMarketBidWideMessage ]
        \cup [ tag : {TopOfMarketOfferWideMessageCode}, body : TopOfMarketOfferWideMessage ]
        \cup [ tag : {LastSaleMessageCode}, body : LastSaleMessage ]
        \cup [ tag : {TradeCancelMessageCode}, body : TradeCancelMessage ]
        \cup [ tag : {LiquiditySeekingEventNotificationMessageCode}, body : LiquiditySeekingEventNotificationMessage ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SeriesUpdateMessageCode -> EncodeSeriesUpdateMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = TopOfMarketBidCompactMessageCode -> EncodeTopOfMarketBidCompactMessage(message.body)
      [] message.tag = TopOfMarketOfferCompactMessageCode -> EncodeTopOfMarketOfferCompactMessage(message.body)
      [] message.tag = TopOfMarketBidWideMessageCode -> EncodeTopOfMarketBidWideMessage(message.body)
      [] message.tag = TopOfMarketOfferWideMessageCode -> EncodeTopOfMarketOfferWideMessage(message.body)
      [] message.tag = LastSaleMessageCode -> EncodeLastSaleMessage(message.body)
      [] message.tag = TradeCancelMessageCode -> EncodeTradeCancelMessage(message.body)
      [] message.tag = LiquiditySeekingEventNotificationMessageCode -> EncodeLiquiditySeekingEventNotificationMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SeriesUpdateMessageCode -> DecodeSeriesUpdateMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = TopOfMarketBidCompactMessageCode -> DecodeTopOfMarketBidCompactMessage(bytes)
              [] tag = TopOfMarketOfferCompactMessageCode -> DecodeTopOfMarketOfferCompactMessage(bytes)
              [] tag = TopOfMarketBidWideMessageCode -> DecodeTopOfMarketBidWideMessage(bytes)
              [] tag = TopOfMarketOfferWideMessageCode -> DecodeTopOfMarketOfferWideMessage(bytes)
              [] tag = LastSaleMessageCode -> DecodeLastSaleMessage(bytes)
              [] tag = TradeCancelMessageCode -> DecodeTradeCancelMessage(bytes)
              [] tag = LiquiditySeekingEventNotificationMessageCode -> DecodeLiquiditySeekingEventNotificationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData == [tag |-> SystemTimeMessageCode, body |-> ZeroSystemTimeMessage]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData ==
    { [tag |-> SystemTimeMessageCode, body |-> one] : one \in CheckedSystemTimeMessage }
        \cup { [tag |-> SeriesUpdateMessageCode, body |-> one] : one \in CheckedSeriesUpdateMessage }
        \cup { [tag |-> SystemStateMessageCode, body |-> one] : one \in CheckedSystemStateMessage }
        \cup { [tag |-> TopOfMarketBidCompactMessageCode, body |-> one] : one \in CheckedTopOfMarketBidCompactMessage }
        \cup { [tag |-> TopOfMarketOfferCompactMessageCode, body |-> one] : one \in CheckedTopOfMarketOfferCompactMessage }
        \cup { [tag |-> TopOfMarketBidWideMessageCode, body |-> one] : one \in CheckedTopOfMarketBidWideMessage }
        \cup { [tag |-> TopOfMarketOfferWideMessageCode, body |-> one] : one \in CheckedTopOfMarketOfferWideMessage }
        \cup { [tag |-> LastSaleMessageCode, body |-> one] : one \in CheckedLastSaleMessage }
        \cup { [tag |-> TradeCancelMessageCode, body |-> one] : one \in CheckedTradeCancelMessage }
        \cup { [tag |-> LiquiditySeekingEventNotificationMessageCode, body |-> one] : one \in CheckedLiquiditySeekingEventNotificationMessage }

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

HeartbeatCode == 0  \* 0x00
StartOfSessionCode == 1  \* 0x01
EndOfSessionCode == 2  \* 0x02
ApplicationMessageCode == 3  \* 0x03

Payload ==
    [ tag : {HeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {StartOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ApplicationMessageCode}, body : ApplicationMessage ]

EncodePayload(message) ==
    CASE message.tag = HeartbeatCode -> << >>
      [] message.tag = StartOfSessionCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>
      [] message.tag = ApplicationMessageCode -> EncodeApplicationMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = HeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = StartOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] tag = ApplicationMessageCode -> DecodeApplicationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> HeartbeatCode, body |-> [empty |-> 0]]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> HeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> StartOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ApplicationMessageCode, body |-> one] : one \in CheckedApplicationMessage }

(***************************************************************************)
(* Mach Message, framed by Packet Length                                   *)
(***************************************************************************)

MachMessage ==
    [ sequenceNumber : Sample(8),
      sessionNumber  : Sample(1),
      payload        : Payload ]

EncodeMachMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
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
    LET packetType == ReadUIntBE(framed, 1) IN IF ~packetType.ok THEN Fail ELSE
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

(* Does a Mach Message end the session? Nothing may follow one that does *)
EndsSessionMachMessage(message) == message.payload.tag \in {EndOfSessionCode}

(* A run of Mach Message, written one after another *)
RECURSIVE EncodeMachMessageList(_)
EncodeMachMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMachMessage(Head(messages)) \o EncodeMachMessageList(Tail(messages))

(* As many Mach Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
(* Only the last of them may end the session, so one that does with bytes left fails *)
RECURSIVE ReadMachMessageAll(_)
ReadMachMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMachMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE IF EndsSessionMachMessage(one.value) /\ one.rest # << >> THEN Fail
             ELSE LET more == ReadMachMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mach Message of each kind, for the lists that carry them *)
OneMachMessage ==
    { [ZeroMachMessage EXCEPT !.payload = [tag |-> HeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> StartOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> ApplicationMessageCode, body |-> ZeroApplicationMessage]] }

(* The runs of Mach Message checked: none, one, two of a kind and each kind followed by *)
(* another, keeping those in which only the last may end the session *)
SampleMachMessageLists ==
    { run \in SampleLists(OneMachMessage) \cup { <<one, other>> : one \in OneMachMessage, other \in OneMachMessage } :
          \A at \in 1 .. Len(run) - 1 : ~EndsSessionMachMessage(run[at]) }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ machMessage : SampleMachMessageLists ]

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
        \cup { [ZeroPacket EXCEPT !.machMessage = one] : one \in SampleMachMessageLists }

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

(* Every Top Of Market Bid Compact Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopOfMarketBidCompactMessage ==
    \A message \in CheckedTopOfMarketBidCompactMessage :
        LET read == DecodeTopOfMarketBidCompactMessage(EncodeTopOfMarketBidCompactMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Of Market Offer Compact Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopOfMarketOfferCompactMessage ==
    \A message \in CheckedTopOfMarketOfferCompactMessage :
        LET read == DecodeTopOfMarketOfferCompactMessage(EncodeTopOfMarketOfferCompactMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Of Market Bid Wide Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopOfMarketBidWideMessage ==
    \A message \in CheckedTopOfMarketBidWideMessage :
        LET read == DecodeTopOfMarketBidWideMessage(EncodeTopOfMarketBidWideMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Of Market Offer Wide Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopOfMarketOfferWideMessage ==
    \A message \in CheckedTopOfMarketOfferWideMessage :
        LET read == DecodeTopOfMarketOfferWideMessage(EncodeTopOfMarketOfferWideMessage(message))
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

(* Every Liquidity Seeking Event Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquiditySeekingEventNotificationMessage ==
    \A message \in CheckedLiquiditySeekingEventNotificationMessage :
        LET read == DecodeLiquiditySeekingEventNotificationMessage(EncodeLiquiditySeekingEventNotificationMessage(message))
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
        LET sent == EncodeData(message)
            read == DecodeData(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Payload is selected by the Packet Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesMachMessage ==
    \A message \in CheckedMachMessage :
        LET bytes == EncodeMachMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 9, 10)) = Len(bytes) - 0

(* A Mach Message that ends the session is the last of its Packet: a run with one after it does not decode *)
EndsSessionLastMachMessage ==
    \A last \in { one \in OneMachMessage : EndsSessionMachMessage(one) } :
        \A after \in OneMachMessage :
            ~ReadMachMessageAll(EncodeMachMessageList(<<last, after>>)).ok

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
