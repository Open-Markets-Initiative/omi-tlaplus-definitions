------------------- MODULE PearlOptions_TopOfMarket_v2_3 -------------------
(***************************************************************************)
(* Miami International Holdings Top Of Market v2.3                         *)
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
(* Simple Series Update Message: 72 bytes                                  *)
(***************************************************************************)

SimpleSeriesUpdateMessage ==
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

EncodeSimpleSeriesUpdateMessage(message) ==
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

DecodeSimpleSeriesUpdateMessage(bytes) ==
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

ZeroSimpleSeriesUpdateMessage ==
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

(* Simple Series Update Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleSeriesUpdateMessage ==
    { ZeroSimpleSeriesUpdateMessage }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.expirationDate = one] : one \in Sample(8) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.callOrPut = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.openingTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.closingTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.restrictedOption = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.longTermOption = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.activeOnMiax = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.miaxBboPostingIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.liquidityAcceptanceIncrementIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.openingUnderlyingMarketCode = one] : one \in Sample(1) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.priorityQuoteWidth = one] : one \in Sample(4) }
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

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
(* Simple Top Of Market Bid Compact Message: 15 bytes                      *)
(***************************************************************************)

SimpleTopOfMarketBidCompactMessage ==
    [ nanoseconds               : Sample(4),
      productId                 : Sample(4),
      mbboPrice2                : Sample(2),
      mbboSize2                 : Sample(2),
      mbboPriorityCustomerSize2 : Sample(2),
      mbboCondition             : Sample(1) ]

EncodeSimpleTopOfMarketBidCompactMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.mbboPrice2
        \o message.mbboSize2
        \o message.mbboPriorityCustomerSize2
        \o message.mbboCondition

DecodeSimpleTopOfMarketBidCompactMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET mbboPrice2 == ReadBytes(productId.rest, 2) IN IF ~mbboPrice2.ok THEN Fail ELSE
    LET mbboSize2 == ReadBytes(mbboPrice2.rest, 2) IN IF ~mbboSize2.ok THEN Fail ELSE
    LET mbboPriorityCustomerSize2 == ReadBytes(mbboSize2.rest, 2) IN IF ~mbboPriorityCustomerSize2.ok THEN Fail ELSE
    LET mbboCondition == ReadBytes(mbboPriorityCustomerSize2.rest, 1) IN IF ~mbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         productId                 |-> productId.value,
         mbboPrice2                |-> mbboPrice2.value,
         mbboSize2                 |-> mbboSize2.value,
         mbboPriorityCustomerSize2 |-> mbboPriorityCustomerSize2.value,
         mbboCondition             |-> mbboCondition.value ], mbboCondition.rest)

ZeroSimpleTopOfMarketBidCompactMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      productId                 |-> [i \in 1 .. 4 |-> 0],
      mbboPrice2                |-> [i \in 1 .. 2 |-> 0],
      mbboSize2                 |-> [i \in 1 .. 2 |-> 0],
      mbboPriorityCustomerSize2 |-> [i \in 1 .. 2 |-> 0],
      mbboCondition             |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Bid Compact Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBidCompactMessage ==
    { ZeroSimpleTopOfMarketBidCompactMessage }
        \cup { [ZeroSimpleTopOfMarketBidCompactMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBidCompactMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBidCompactMessage EXCEPT !.mbboPrice2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBidCompactMessage EXCEPT !.mbboSize2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBidCompactMessage EXCEPT !.mbboPriorityCustomerSize2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBidCompactMessage EXCEPT !.mbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Offer Compact Message: 15 bytes                    *)
(***************************************************************************)

SimpleTopOfMarketOfferCompactMessage ==
    [ nanoseconds               : Sample(4),
      productId                 : Sample(4),
      mbboPrice2                : Sample(2),
      mbboSize2                 : Sample(2),
      mbboPriorityCustomerSize2 : Sample(2),
      mbboCondition             : Sample(1) ]

EncodeSimpleTopOfMarketOfferCompactMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.mbboPrice2
        \o message.mbboSize2
        \o message.mbboPriorityCustomerSize2
        \o message.mbboCondition

DecodeSimpleTopOfMarketOfferCompactMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET mbboPrice2 == ReadBytes(productId.rest, 2) IN IF ~mbboPrice2.ok THEN Fail ELSE
    LET mbboSize2 == ReadBytes(mbboPrice2.rest, 2) IN IF ~mbboSize2.ok THEN Fail ELSE
    LET mbboPriorityCustomerSize2 == ReadBytes(mbboSize2.rest, 2) IN IF ~mbboPriorityCustomerSize2.ok THEN Fail ELSE
    LET mbboCondition == ReadBytes(mbboPriorityCustomerSize2.rest, 1) IN IF ~mbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         productId                 |-> productId.value,
         mbboPrice2                |-> mbboPrice2.value,
         mbboSize2                 |-> mbboSize2.value,
         mbboPriorityCustomerSize2 |-> mbboPriorityCustomerSize2.value,
         mbboCondition             |-> mbboCondition.value ], mbboCondition.rest)

ZeroSimpleTopOfMarketOfferCompactMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      productId                 |-> [i \in 1 .. 4 |-> 0],
      mbboPrice2                |-> [i \in 1 .. 2 |-> 0],
      mbboSize2                 |-> [i \in 1 .. 2 |-> 0],
      mbboPriorityCustomerSize2 |-> [i \in 1 .. 2 |-> 0],
      mbboCondition             |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Offer Compact Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketOfferCompactMessage ==
    { ZeroSimpleTopOfMarketOfferCompactMessage }
        \cup { [ZeroSimpleTopOfMarketOfferCompactMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketOfferCompactMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketOfferCompactMessage EXCEPT !.mbboPrice2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketOfferCompactMessage EXCEPT !.mbboSize2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketOfferCompactMessage EXCEPT !.mbboPriorityCustomerSize2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketOfferCompactMessage EXCEPT !.mbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Bid Wide Message: 21 bytes                         *)
(***************************************************************************)

SimpleTopOfMarketBidWideMessage ==
    [ nanoseconds               : Sample(4),
      productId                 : Sample(4),
      mbboPrice4                : Sample(4),
      mbboSize4                 : Sample(4),
      mbboPriorityCustomerSize4 : Sample(4),
      mbboCondition             : Sample(1) ]

EncodeSimpleTopOfMarketBidWideMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.mbboPrice4
        \o message.mbboSize4
        \o message.mbboPriorityCustomerSize4
        \o message.mbboCondition

DecodeSimpleTopOfMarketBidWideMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET mbboPrice4 == ReadBytes(productId.rest, 4) IN IF ~mbboPrice4.ok THEN Fail ELSE
    LET mbboSize4 == ReadBytes(mbboPrice4.rest, 4) IN IF ~mbboSize4.ok THEN Fail ELSE
    LET mbboPriorityCustomerSize4 == ReadBytes(mbboSize4.rest, 4) IN IF ~mbboPriorityCustomerSize4.ok THEN Fail ELSE
    LET mbboCondition == ReadBytes(mbboPriorityCustomerSize4.rest, 1) IN IF ~mbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         productId                 |-> productId.value,
         mbboPrice4                |-> mbboPrice4.value,
         mbboSize4                 |-> mbboSize4.value,
         mbboPriorityCustomerSize4 |-> mbboPriorityCustomerSize4.value,
         mbboCondition             |-> mbboCondition.value ], mbboCondition.rest)

ZeroSimpleTopOfMarketBidWideMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      productId                 |-> [i \in 1 .. 4 |-> 0],
      mbboPrice4                |-> [i \in 1 .. 4 |-> 0],
      mbboSize4                 |-> [i \in 1 .. 4 |-> 0],
      mbboPriorityCustomerSize4 |-> [i \in 1 .. 4 |-> 0],
      mbboCondition             |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Bid Wide Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBidWideMessage ==
    { ZeroSimpleTopOfMarketBidWideMessage }
        \cup { [ZeroSimpleTopOfMarketBidWideMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBidWideMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBidWideMessage EXCEPT !.mbboPrice4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBidWideMessage EXCEPT !.mbboSize4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBidWideMessage EXCEPT !.mbboPriorityCustomerSize4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBidWideMessage EXCEPT !.mbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Offer Wide Message: 21 bytes                       *)
(***************************************************************************)

SimpleTopOfMarketOfferWideMessage ==
    [ nanoseconds               : Sample(4),
      productId                 : Sample(4),
      mbboPrice4                : Sample(4),
      mbboSize4                 : Sample(4),
      mbboPriorityCustomerSize4 : Sample(4),
      mbboCondition             : Sample(1) ]

EncodeSimpleTopOfMarketOfferWideMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.mbboPrice4
        \o message.mbboSize4
        \o message.mbboPriorityCustomerSize4
        \o message.mbboCondition

DecodeSimpleTopOfMarketOfferWideMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET mbboPrice4 == ReadBytes(productId.rest, 4) IN IF ~mbboPrice4.ok THEN Fail ELSE
    LET mbboSize4 == ReadBytes(mbboPrice4.rest, 4) IN IF ~mbboSize4.ok THEN Fail ELSE
    LET mbboPriorityCustomerSize4 == ReadBytes(mbboSize4.rest, 4) IN IF ~mbboPriorityCustomerSize4.ok THEN Fail ELSE
    LET mbboCondition == ReadBytes(mbboPriorityCustomerSize4.rest, 1) IN IF ~mbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds               |-> nanoseconds.value,
         productId                 |-> productId.value,
         mbboPrice4                |-> mbboPrice4.value,
         mbboSize4                 |-> mbboSize4.value,
         mbboPriorityCustomerSize4 |-> mbboPriorityCustomerSize4.value,
         mbboCondition             |-> mbboCondition.value ], mbboCondition.rest)

ZeroSimpleTopOfMarketOfferWideMessage ==
    [ nanoseconds               |-> [i \in 1 .. 4 |-> 0],
      productId                 |-> [i \in 1 .. 4 |-> 0],
      mbboPrice4                |-> [i \in 1 .. 4 |-> 0],
      mbboSize4                 |-> [i \in 1 .. 4 |-> 0],
      mbboPriorityCustomerSize4 |-> [i \in 1 .. 4 |-> 0],
      mbboCondition             |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Offer Wide Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketOfferWideMessage ==
    { ZeroSimpleTopOfMarketOfferWideMessage }
        \cup { [ZeroSimpleTopOfMarketOfferWideMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketOfferWideMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketOfferWideMessage EXCEPT !.mbboPrice4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketOfferWideMessage EXCEPT !.mbboSize4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketOfferWideMessage EXCEPT !.mbboPriorityCustomerSize4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketOfferWideMessage EXCEPT !.mbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Double Sided Top Of Market Compact Message: 22 bytes             *)
(***************************************************************************)

SimpleDoubleSidedTopOfMarketCompactMessage ==
    [ nanoseconds                : Sample(4),
      productId                  : Sample(4),
      bidPrice2                  : Sample(2),
      bidSize2                   : Sample(2),
      bidPriorityCustomerSize2   : Sample(2),
      bidCondition               : Sample(1),
      offerPrice2                : Sample(2),
      offerSize2                 : Sample(2),
      offerPriorityCustomerSize2 : Sample(2),
      offerCondition             : Sample(1) ]

EncodeSimpleDoubleSidedTopOfMarketCompactMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.bidPrice2
        \o message.bidSize2
        \o message.bidPriorityCustomerSize2
        \o message.bidCondition
        \o message.offerPrice2
        \o message.offerSize2
        \o message.offerPriorityCustomerSize2
        \o message.offerCondition

DecodeSimpleDoubleSidedTopOfMarketCompactMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET bidPrice2 == ReadBytes(productId.rest, 2) IN IF ~bidPrice2.ok THEN Fail ELSE
    LET bidSize2 == ReadBytes(bidPrice2.rest, 2) IN IF ~bidSize2.ok THEN Fail ELSE
    LET bidPriorityCustomerSize2 == ReadBytes(bidSize2.rest, 2) IN IF ~bidPriorityCustomerSize2.ok THEN Fail ELSE
    LET bidCondition == ReadBytes(bidPriorityCustomerSize2.rest, 1) IN IF ~bidCondition.ok THEN Fail ELSE
    LET offerPrice2 == ReadBytes(bidCondition.rest, 2) IN IF ~offerPrice2.ok THEN Fail ELSE
    LET offerSize2 == ReadBytes(offerPrice2.rest, 2) IN IF ~offerSize2.ok THEN Fail ELSE
    LET offerPriorityCustomerSize2 == ReadBytes(offerSize2.rest, 2) IN IF ~offerPriorityCustomerSize2.ok THEN Fail ELSE
    LET offerCondition == ReadBytes(offerPriorityCustomerSize2.rest, 1) IN IF ~offerCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                |-> nanoseconds.value,
         productId                  |-> productId.value,
         bidPrice2                  |-> bidPrice2.value,
         bidSize2                   |-> bidSize2.value,
         bidPriorityCustomerSize2   |-> bidPriorityCustomerSize2.value,
         bidCondition               |-> bidCondition.value,
         offerPrice2                |-> offerPrice2.value,
         offerSize2                 |-> offerSize2.value,
         offerPriorityCustomerSize2 |-> offerPriorityCustomerSize2.value,
         offerCondition             |-> offerCondition.value ], offerCondition.rest)

ZeroSimpleDoubleSidedTopOfMarketCompactMessage ==
    [ nanoseconds                |-> [i \in 1 .. 4 |-> 0],
      productId                  |-> [i \in 1 .. 4 |-> 0],
      bidPrice2                  |-> [i \in 1 .. 2 |-> 0],
      bidSize2                   |-> [i \in 1 .. 2 |-> 0],
      bidPriorityCustomerSize2   |-> [i \in 1 .. 2 |-> 0],
      bidCondition               |-> [i \in 1 .. 1 |-> 0],
      offerPrice2                |-> [i \in 1 .. 2 |-> 0],
      offerSize2                 |-> [i \in 1 .. 2 |-> 0],
      offerPriorityCustomerSize2 |-> [i \in 1 .. 2 |-> 0],
      offerCondition             |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Double Sided Top Of Market Compact Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleDoubleSidedTopOfMarketCompactMessage ==
    { ZeroSimpleDoubleSidedTopOfMarketCompactMessage }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketCompactMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketCompactMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketCompactMessage EXCEPT !.bidPrice2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketCompactMessage EXCEPT !.bidSize2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketCompactMessage EXCEPT !.bidPriorityCustomerSize2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketCompactMessage EXCEPT !.bidCondition = one] : one \in Sample(1) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketCompactMessage EXCEPT !.offerPrice2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketCompactMessage EXCEPT !.offerSize2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketCompactMessage EXCEPT !.offerPriorityCustomerSize2 = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketCompactMessage EXCEPT !.offerCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Double Sided Top Of Market Wide Message: 34 bytes                *)
(***************************************************************************)

SimpleDoubleSidedTopOfMarketWideMessage ==
    [ nanoseconds                : Sample(4),
      productId                  : Sample(4),
      bidPrice4                  : Sample(4),
      bidSize4                   : Sample(4),
      bidPriorityCustomerSize4   : Sample(4),
      bidCondition               : Sample(1),
      offerPrice4                : Sample(4),
      offerSize4                 : Sample(4),
      offerPriorityCustomerSize4 : Sample(4),
      offerCondition             : Sample(1) ]

EncodeSimpleDoubleSidedTopOfMarketWideMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.bidPrice4
        \o message.bidSize4
        \o message.bidPriorityCustomerSize4
        \o message.bidCondition
        \o message.offerPrice4
        \o message.offerSize4
        \o message.offerPriorityCustomerSize4
        \o message.offerCondition

DecodeSimpleDoubleSidedTopOfMarketWideMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET bidPrice4 == ReadBytes(productId.rest, 4) IN IF ~bidPrice4.ok THEN Fail ELSE
    LET bidSize4 == ReadBytes(bidPrice4.rest, 4) IN IF ~bidSize4.ok THEN Fail ELSE
    LET bidPriorityCustomerSize4 == ReadBytes(bidSize4.rest, 4) IN IF ~bidPriorityCustomerSize4.ok THEN Fail ELSE
    LET bidCondition == ReadBytes(bidPriorityCustomerSize4.rest, 1) IN IF ~bidCondition.ok THEN Fail ELSE
    LET offerPrice4 == ReadBytes(bidCondition.rest, 4) IN IF ~offerPrice4.ok THEN Fail ELSE
    LET offerSize4 == ReadBytes(offerPrice4.rest, 4) IN IF ~offerSize4.ok THEN Fail ELSE
    LET offerPriorityCustomerSize4 == ReadBytes(offerSize4.rest, 4) IN IF ~offerPriorityCustomerSize4.ok THEN Fail ELSE
    LET offerCondition == ReadBytes(offerPriorityCustomerSize4.rest, 1) IN IF ~offerCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                |-> nanoseconds.value,
         productId                  |-> productId.value,
         bidPrice4                  |-> bidPrice4.value,
         bidSize4                   |-> bidSize4.value,
         bidPriorityCustomerSize4   |-> bidPriorityCustomerSize4.value,
         bidCondition               |-> bidCondition.value,
         offerPrice4                |-> offerPrice4.value,
         offerSize4                 |-> offerSize4.value,
         offerPriorityCustomerSize4 |-> offerPriorityCustomerSize4.value,
         offerCondition             |-> offerCondition.value ], offerCondition.rest)

ZeroSimpleDoubleSidedTopOfMarketWideMessage ==
    [ nanoseconds                |-> [i \in 1 .. 4 |-> 0],
      productId                  |-> [i \in 1 .. 4 |-> 0],
      bidPrice4                  |-> [i \in 1 .. 4 |-> 0],
      bidSize4                   |-> [i \in 1 .. 4 |-> 0],
      bidPriorityCustomerSize4   |-> [i \in 1 .. 4 |-> 0],
      bidCondition               |-> [i \in 1 .. 1 |-> 0],
      offerPrice4                |-> [i \in 1 .. 4 |-> 0],
      offerSize4                 |-> [i \in 1 .. 4 |-> 0],
      offerPriorityCustomerSize4 |-> [i \in 1 .. 4 |-> 0],
      offerCondition             |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Double Sided Top Of Market Wide Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleDoubleSidedTopOfMarketWideMessage ==
    { ZeroSimpleDoubleSidedTopOfMarketWideMessage }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketWideMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketWideMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketWideMessage EXCEPT !.bidPrice4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketWideMessage EXCEPT !.bidSize4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketWideMessage EXCEPT !.bidPriorityCustomerSize4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketWideMessage EXCEPT !.bidCondition = one] : one \in Sample(1) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketWideMessage EXCEPT !.offerPrice4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketWideMessage EXCEPT !.offerSize4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketWideMessage EXCEPT !.offerPriorityCustomerSize4 = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketWideMessage EXCEPT !.offerCondition = one] : one \in Sample(1) }

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
(* Underlying Trading Status Notification Message: 25 bytes                *)
(***************************************************************************)

UnderlyingTradingStatusNotificationMessage ==
    [ nanoseconds                  : Sample(4),
      underlyingSymbol             : Sample(11),
      tradingStatus                : Sample(1),
      eventReason                  : Sample(1),
      expectedEventTimeSeconds     : Sample(4),
      expectedEventTimeNanoSeconds : Sample(4) ]

EncodeUnderlyingTradingStatusNotificationMessage(message) ==
    message.nanoseconds
        \o message.underlyingSymbol
        \o message.tradingStatus
        \o message.eventReason
        \o message.expectedEventTimeSeconds
        \o message.expectedEventTimeNanoSeconds

DecodeUnderlyingTradingStatusNotificationMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(nanoseconds.rest, 11) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(underlyingSymbol.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET eventReason == ReadBytes(tradingStatus.rest, 1) IN IF ~eventReason.ok THEN Fail ELSE
    LET expectedEventTimeSeconds == ReadBytes(eventReason.rest, 4) IN IF ~expectedEventTimeSeconds.ok THEN Fail ELSE
    LET expectedEventTimeNanoSeconds == ReadBytes(expectedEventTimeSeconds.rest, 4) IN IF ~expectedEventTimeNanoSeconds.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         underlyingSymbol             |-> underlyingSymbol.value,
         tradingStatus                |-> tradingStatus.value,
         eventReason                  |-> eventReason.value,
         expectedEventTimeSeconds     |-> expectedEventTimeSeconds.value,
         expectedEventTimeNanoSeconds |-> expectedEventTimeNanoSeconds.value ], expectedEventTimeNanoSeconds.rest)

ZeroUnderlyingTradingStatusNotificationMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol             |-> [i \in 1 .. 11 |-> 0],
      tradingStatus                |-> [i \in 1 .. 1 |-> 0],
      eventReason                  |-> [i \in 1 .. 1 |-> 0],
      expectedEventTimeSeconds     |-> [i \in 1 .. 4 |-> 0],
      expectedEventTimeNanoSeconds |-> [i \in 1 .. 4 |-> 0] ]

(* Underlying Trading Status Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingTradingStatusNotificationMessage ==
    { ZeroUnderlyingTradingStatusNotificationMessage }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.eventReason = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.expectedEventTimeSeconds = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.expectedEventTimeNanoSeconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SystemTimeMessageCode == 49  \* "1"
SimpleSeriesUpdateMessageCode == 80  \* "P"
SystemStateMessageCode == 83  \* "S"
SimpleTopOfMarketBidCompactMessageCode == 66  \* "B"
SimpleTopOfMarketOfferCompactMessageCode == 79  \* "O"
SimpleTopOfMarketBidWideMessageCode == 87  \* "W"
SimpleTopOfMarketOfferWideMessageCode == 65  \* "A"
SimpleDoubleSidedTopOfMarketCompactMessageCode == 100  \* "d"
SimpleDoubleSidedTopOfMarketWideMessageCode == 68  \* "D"
LastSaleMessageCode == 84  \* "T"
TradeCancelMessageCode == 88  \* "X"
UnderlyingTradingStatusNotificationMessageCode == 72  \* "H"

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SimpleSeriesUpdateMessageCode}, body : SimpleSeriesUpdateMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {SimpleTopOfMarketBidCompactMessageCode}, body : SimpleTopOfMarketBidCompactMessage ]
        \cup [ tag : {SimpleTopOfMarketOfferCompactMessageCode}, body : SimpleTopOfMarketOfferCompactMessage ]
        \cup [ tag : {SimpleTopOfMarketBidWideMessageCode}, body : SimpleTopOfMarketBidWideMessage ]
        \cup [ tag : {SimpleTopOfMarketOfferWideMessageCode}, body : SimpleTopOfMarketOfferWideMessage ]
        \cup [ tag : {SimpleDoubleSidedTopOfMarketCompactMessageCode}, body : SimpleDoubleSidedTopOfMarketCompactMessage ]
        \cup [ tag : {SimpleDoubleSidedTopOfMarketWideMessageCode}, body : SimpleDoubleSidedTopOfMarketWideMessage ]
        \cup [ tag : {LastSaleMessageCode}, body : LastSaleMessage ]
        \cup [ tag : {TradeCancelMessageCode}, body : TradeCancelMessage ]
        \cup [ tag : {UnderlyingTradingStatusNotificationMessageCode}, body : UnderlyingTradingStatusNotificationMessage ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SimpleSeriesUpdateMessageCode -> EncodeSimpleSeriesUpdateMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = SimpleTopOfMarketBidCompactMessageCode -> EncodeSimpleTopOfMarketBidCompactMessage(message.body)
      [] message.tag = SimpleTopOfMarketOfferCompactMessageCode -> EncodeSimpleTopOfMarketOfferCompactMessage(message.body)
      [] message.tag = SimpleTopOfMarketBidWideMessageCode -> EncodeSimpleTopOfMarketBidWideMessage(message.body)
      [] message.tag = SimpleTopOfMarketOfferWideMessageCode -> EncodeSimpleTopOfMarketOfferWideMessage(message.body)
      [] message.tag = SimpleDoubleSidedTopOfMarketCompactMessageCode -> EncodeSimpleDoubleSidedTopOfMarketCompactMessage(message.body)
      [] message.tag = SimpleDoubleSidedTopOfMarketWideMessageCode -> EncodeSimpleDoubleSidedTopOfMarketWideMessage(message.body)
      [] message.tag = LastSaleMessageCode -> EncodeLastSaleMessage(message.body)
      [] message.tag = TradeCancelMessageCode -> EncodeTradeCancelMessage(message.body)
      [] message.tag = UnderlyingTradingStatusNotificationMessageCode -> EncodeUnderlyingTradingStatusNotificationMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SimpleSeriesUpdateMessageCode -> DecodeSimpleSeriesUpdateMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = SimpleTopOfMarketBidCompactMessageCode -> DecodeSimpleTopOfMarketBidCompactMessage(bytes)
              [] tag = SimpleTopOfMarketOfferCompactMessageCode -> DecodeSimpleTopOfMarketOfferCompactMessage(bytes)
              [] tag = SimpleTopOfMarketBidWideMessageCode -> DecodeSimpleTopOfMarketBidWideMessage(bytes)
              [] tag = SimpleTopOfMarketOfferWideMessageCode -> DecodeSimpleTopOfMarketOfferWideMessage(bytes)
              [] tag = SimpleDoubleSidedTopOfMarketCompactMessageCode -> DecodeSimpleDoubleSidedTopOfMarketCompactMessage(bytes)
              [] tag = SimpleDoubleSidedTopOfMarketWideMessageCode -> DecodeSimpleDoubleSidedTopOfMarketWideMessage(bytes)
              [] tag = LastSaleMessageCode -> DecodeLastSaleMessage(bytes)
              [] tag = TradeCancelMessageCode -> DecodeTradeCancelMessage(bytes)
              [] tag = UnderlyingTradingStatusNotificationMessageCode -> DecodeUnderlyingTradingStatusNotificationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData == [tag |-> SystemTimeMessageCode, body |-> ZeroSystemTimeMessage]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData ==
    { [tag |-> SystemTimeMessageCode, body |-> one] : one \in CheckedSystemTimeMessage }
        \cup { [tag |-> SimpleSeriesUpdateMessageCode, body |-> one] : one \in CheckedSimpleSeriesUpdateMessage }
        \cup { [tag |-> SystemStateMessageCode, body |-> one] : one \in CheckedSystemStateMessage }
        \cup { [tag |-> SimpleTopOfMarketBidCompactMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBidCompactMessage }
        \cup { [tag |-> SimpleTopOfMarketOfferCompactMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketOfferCompactMessage }
        \cup { [tag |-> SimpleTopOfMarketBidWideMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBidWideMessage }
        \cup { [tag |-> SimpleTopOfMarketOfferWideMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketOfferWideMessage }
        \cup { [tag |-> SimpleDoubleSidedTopOfMarketCompactMessageCode, body |-> one] : one \in CheckedSimpleDoubleSidedTopOfMarketCompactMessage }
        \cup { [tag |-> SimpleDoubleSidedTopOfMarketWideMessageCode, body |-> one] : one \in CheckedSimpleDoubleSidedTopOfMarketWideMessage }
        \cup { [tag |-> LastSaleMessageCode, body |-> one] : one \in CheckedLastSaleMessage }
        \cup { [tag |-> TradeCancelMessageCode, body |-> one] : one \in CheckedTradeCancelMessage }
        \cup { [tag |-> UnderlyingTradingStatusNotificationMessageCode, body |-> one] : one \in CheckedUnderlyingTradingStatusNotificationMessage }

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
    { [ZeroMachMessage EXCEPT !.payload = [tag |-> HeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> StartOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]],
      [ZeroMachMessage EXCEPT !.payload = [tag |-> ApplicationMessageCode, body |-> ZeroApplicationMessage]] }

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

(* Every Simple Series Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleSeriesUpdateMessage ==
    \A message \in CheckedSimpleSeriesUpdateMessage :
        LET read == DecodeSimpleSeriesUpdateMessage(EncodeSimpleSeriesUpdateMessage(message))
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

(* Every Simple Top Of Market Bid Compact Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBidCompactMessage ==
    \A message \in CheckedSimpleTopOfMarketBidCompactMessage :
        LET read == DecodeSimpleTopOfMarketBidCompactMessage(EncodeSimpleTopOfMarketBidCompactMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Offer Compact Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketOfferCompactMessage ==
    \A message \in CheckedSimpleTopOfMarketOfferCompactMessage :
        LET read == DecodeSimpleTopOfMarketOfferCompactMessage(EncodeSimpleTopOfMarketOfferCompactMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Bid Wide Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBidWideMessage ==
    \A message \in CheckedSimpleTopOfMarketBidWideMessage :
        LET read == DecodeSimpleTopOfMarketBidWideMessage(EncodeSimpleTopOfMarketBidWideMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Offer Wide Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketOfferWideMessage ==
    \A message \in CheckedSimpleTopOfMarketOfferWideMessage :
        LET read == DecodeSimpleTopOfMarketOfferWideMessage(EncodeSimpleTopOfMarketOfferWideMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Double Sided Top Of Market Compact Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleDoubleSidedTopOfMarketCompactMessage ==
    \A message \in CheckedSimpleDoubleSidedTopOfMarketCompactMessage :
        LET read == DecodeSimpleDoubleSidedTopOfMarketCompactMessage(EncodeSimpleDoubleSidedTopOfMarketCompactMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Double Sided Top Of Market Wide Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleDoubleSidedTopOfMarketWideMessage ==
    \A message \in CheckedSimpleDoubleSidedTopOfMarketWideMessage :
        LET read == DecodeSimpleDoubleSidedTopOfMarketWideMessage(EncodeSimpleDoubleSidedTopOfMarketWideMessage(message))
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

(* Every Underlying Trading Status Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUnderlyingTradingStatusNotificationMessage ==
    \A message \in CheckedUnderlyingTradingStatusNotificationMessage :
        LET read == DecodeUnderlyingTradingStatusNotificationMessage(EncodeUnderlyingTradingStatusNotificationMessage(message))
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
