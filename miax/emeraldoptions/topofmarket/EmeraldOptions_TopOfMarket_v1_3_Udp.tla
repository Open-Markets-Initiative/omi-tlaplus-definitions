---------------- MODULE EmeraldOptions_TopOfMarket_v1_3_Udp ----------------
(***************************************************************************)
(* Miami International Holdings Top of Market v1.3                         *)
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
      emeraldBboPostingIncrementIndicator   : Sample(1),
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
        \o message.emeraldBboPostingIncrementIndicator
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
    LET emeraldBboPostingIncrementIndicator == ReadBytes(activeOnMiax.rest, 1) IN IF ~emeraldBboPostingIncrementIndicator.ok THEN Fail ELSE
    LET liquidityAcceptanceIncrementIndicator == ReadBytes(emeraldBboPostingIncrementIndicator.rest, 1) IN IF ~liquidityAcceptanceIncrementIndicator.ok THEN Fail ELSE
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
         emeraldBboPostingIncrementIndicator   |-> emeraldBboPostingIncrementIndicator.value,
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
      emeraldBboPostingIncrementIndicator   |-> [i \in 1 .. 1 |-> 0],
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
        \cup { [ZeroSimpleSeriesUpdateMessage EXCEPT !.emeraldBboPostingIncrementIndicator = one] : one \in Sample(1) }
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
(* Simple Top Of Market Best Bid Or Offer Compact Bid Message: 15 bytes    *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferCompactBidMessage ==
    [ nanoseconds                   : Sample(4),
      productId                     : Sample(4),
      ebboPriceShort                : Sample(2),
      ebboSizeShort                 : Sample(2),
      ebboPriorityCustomerSizeShort : Sample(2),
      ebboCondition                 : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferCompactBidMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.ebboPriceShort
        \o message.ebboSizeShort
        \o message.ebboPriorityCustomerSizeShort
        \o message.ebboCondition

DecodeSimpleTopOfMarketBestBidOrOfferCompactBidMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET ebboPriceShort == ReadBytes(productId.rest, 2) IN IF ~ebboPriceShort.ok THEN Fail ELSE
    LET ebboSizeShort == ReadBytes(ebboPriceShort.rest, 2) IN IF ~ebboSizeShort.ok THEN Fail ELSE
    LET ebboPriorityCustomerSizeShort == ReadBytes(ebboSizeShort.rest, 2) IN IF ~ebboPriorityCustomerSizeShort.ok THEN Fail ELSE
    LET ebboCondition == ReadBytes(ebboPriorityCustomerSizeShort.rest, 1) IN IF ~ebboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                   |-> nanoseconds.value,
         productId                     |-> productId.value,
         ebboPriceShort                |-> ebboPriceShort.value,
         ebboSizeShort                 |-> ebboSizeShort.value,
         ebboPriorityCustomerSizeShort |-> ebboPriorityCustomerSizeShort.value,
         ebboCondition                 |-> ebboCondition.value ], ebboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferCompactBidMessage ==
    [ nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      productId                     |-> [i \in 1 .. 4 |-> 0],
      ebboPriceShort                |-> [i \in 1 .. 2 |-> 0],
      ebboSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      ebboPriorityCustomerSizeShort |-> [i \in 1 .. 2 |-> 0],
      ebboCondition                 |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Compact Bid Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferCompactBidMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferCompactBidMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactBidMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactBidMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactBidMessage EXCEPT !.ebboPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactBidMessage EXCEPT !.ebboSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactBidMessage EXCEPT !.ebboPriorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactBidMessage EXCEPT !.ebboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Best Bid Or Offer Compact Bid With Priority        *)
(* Customer Message: 15 bytes                                              *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage ==
    [ nanoseconds                   : Sample(4),
      productId                     : Sample(4),
      ebboPriceShort                : Sample(2),
      ebboSizeShort                 : Sample(2),
      ebboPriorityCustomerSizeShort : Sample(2),
      ebboCondition                 : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.ebboPriceShort
        \o message.ebboSizeShort
        \o message.ebboPriorityCustomerSizeShort
        \o message.ebboCondition

DecodeSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET ebboPriceShort == ReadBytes(productId.rest, 2) IN IF ~ebboPriceShort.ok THEN Fail ELSE
    LET ebboSizeShort == ReadBytes(ebboPriceShort.rest, 2) IN IF ~ebboSizeShort.ok THEN Fail ELSE
    LET ebboPriorityCustomerSizeShort == ReadBytes(ebboSizeShort.rest, 2) IN IF ~ebboPriorityCustomerSizeShort.ok THEN Fail ELSE
    LET ebboCondition == ReadBytes(ebboPriorityCustomerSizeShort.rest, 1) IN IF ~ebboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                   |-> nanoseconds.value,
         productId                     |-> productId.value,
         ebboPriceShort                |-> ebboPriceShort.value,
         ebboSizeShort                 |-> ebboSizeShort.value,
         ebboPriorityCustomerSizeShort |-> ebboPriorityCustomerSizeShort.value,
         ebboCondition                 |-> ebboCondition.value ], ebboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage ==
    [ nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      productId                     |-> [i \in 1 .. 4 |-> 0],
      ebboPriceShort                |-> [i \in 1 .. 2 |-> 0],
      ebboSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      ebboPriorityCustomerSizeShort |-> [i \in 1 .. 2 |-> 0],
      ebboCondition                 |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Compact Bid With Priority Customer Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage EXCEPT !.ebboPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage EXCEPT !.ebboSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage EXCEPT !.ebboPriorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage EXCEPT !.ebboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Best Bid Or Offer Compact Offer Message: 15 bytes  *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferCompactOfferMessage ==
    [ nanoseconds                   : Sample(4),
      productId                     : Sample(4),
      ebboPriceShort                : Sample(2),
      ebboSizeShort                 : Sample(2),
      ebboPriorityCustomerSizeShort : Sample(2),
      ebboCondition                 : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferCompactOfferMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.ebboPriceShort
        \o message.ebboSizeShort
        \o message.ebboPriorityCustomerSizeShort
        \o message.ebboCondition

DecodeSimpleTopOfMarketBestBidOrOfferCompactOfferMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET ebboPriceShort == ReadBytes(productId.rest, 2) IN IF ~ebboPriceShort.ok THEN Fail ELSE
    LET ebboSizeShort == ReadBytes(ebboPriceShort.rest, 2) IN IF ~ebboSizeShort.ok THEN Fail ELSE
    LET ebboPriorityCustomerSizeShort == ReadBytes(ebboSizeShort.rest, 2) IN IF ~ebboPriorityCustomerSizeShort.ok THEN Fail ELSE
    LET ebboCondition == ReadBytes(ebboPriorityCustomerSizeShort.rest, 1) IN IF ~ebboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                   |-> nanoseconds.value,
         productId                     |-> productId.value,
         ebboPriceShort                |-> ebboPriceShort.value,
         ebboSizeShort                 |-> ebboSizeShort.value,
         ebboPriorityCustomerSizeShort |-> ebboPriorityCustomerSizeShort.value,
         ebboCondition                 |-> ebboCondition.value ], ebboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferMessage ==
    [ nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      productId                     |-> [i \in 1 .. 4 |-> 0],
      ebboPriceShort                |-> [i \in 1 .. 2 |-> 0],
      ebboSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      ebboPriorityCustomerSizeShort |-> [i \in 1 .. 2 |-> 0],
      ebboCondition                 |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Compact Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferCompactOfferMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferMessage EXCEPT !.ebboPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferMessage EXCEPT !.ebboSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferMessage EXCEPT !.ebboPriorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferMessage EXCEPT !.ebboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Best Bid Or Offer Compact Offer With Priority      *)
(* Customer Message: 15 bytes                                              *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage ==
    [ nanoseconds                   : Sample(4),
      productId                     : Sample(4),
      ebboPriceShort                : Sample(2),
      ebboSizeShort                 : Sample(2),
      ebboPriorityCustomerSizeShort : Sample(2),
      ebboCondition                 : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.ebboPriceShort
        \o message.ebboSizeShort
        \o message.ebboPriorityCustomerSizeShort
        \o message.ebboCondition

DecodeSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET ebboPriceShort == ReadBytes(productId.rest, 2) IN IF ~ebboPriceShort.ok THEN Fail ELSE
    LET ebboSizeShort == ReadBytes(ebboPriceShort.rest, 2) IN IF ~ebboSizeShort.ok THEN Fail ELSE
    LET ebboPriorityCustomerSizeShort == ReadBytes(ebboSizeShort.rest, 2) IN IF ~ebboPriorityCustomerSizeShort.ok THEN Fail ELSE
    LET ebboCondition == ReadBytes(ebboPriorityCustomerSizeShort.rest, 1) IN IF ~ebboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                   |-> nanoseconds.value,
         productId                     |-> productId.value,
         ebboPriceShort                |-> ebboPriceShort.value,
         ebboSizeShort                 |-> ebboSizeShort.value,
         ebboPriorityCustomerSizeShort |-> ebboPriorityCustomerSizeShort.value,
         ebboCondition                 |-> ebboCondition.value ], ebboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage ==
    [ nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      productId                     |-> [i \in 1 .. 4 |-> 0],
      ebboPriceShort                |-> [i \in 1 .. 2 |-> 0],
      ebboSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      ebboPriorityCustomerSizeShort |-> [i \in 1 .. 2 |-> 0],
      ebboCondition                 |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Compact Offer With Priority Customer Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage EXCEPT !.ebboPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage EXCEPT !.ebboSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage EXCEPT !.ebboPriorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage EXCEPT !.ebboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Best Bid Or Offer Wide Bid Message: 21 bytes       *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferWideBidMessage ==
    [ nanoseconds                  : Sample(4),
      productId                    : Sample(4),
      ebboPriceLong                : Sample(4),
      ebboSizeLong                 : Sample(4),
      ebboPriorityCustomerSizeLong : Sample(4),
      ebboCondition                : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferWideBidMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.ebboPriceLong
        \o message.ebboSizeLong
        \o message.ebboPriorityCustomerSizeLong
        \o message.ebboCondition

DecodeSimpleTopOfMarketBestBidOrOfferWideBidMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET ebboPriceLong == ReadBytes(productId.rest, 4) IN IF ~ebboPriceLong.ok THEN Fail ELSE
    LET ebboSizeLong == ReadBytes(ebboPriceLong.rest, 4) IN IF ~ebboSizeLong.ok THEN Fail ELSE
    LET ebboPriorityCustomerSizeLong == ReadBytes(ebboSizeLong.rest, 4) IN IF ~ebboPriorityCustomerSizeLong.ok THEN Fail ELSE
    LET ebboCondition == ReadBytes(ebboPriorityCustomerSizeLong.rest, 1) IN IF ~ebboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         productId                    |-> productId.value,
         ebboPriceLong                |-> ebboPriceLong.value,
         ebboSizeLong                 |-> ebboSizeLong.value,
         ebboPriorityCustomerSizeLong |-> ebboPriorityCustomerSizeLong.value,
         ebboCondition                |-> ebboCondition.value ], ebboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferWideBidMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      productId                    |-> [i \in 1 .. 4 |-> 0],
      ebboPriceLong                |-> [i \in 1 .. 4 |-> 0],
      ebboSizeLong                 |-> [i \in 1 .. 4 |-> 0],
      ebboPriorityCustomerSizeLong |-> [i \in 1 .. 4 |-> 0],
      ebboCondition                |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Wide Bid Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferWideBidMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferWideBidMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideBidMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideBidMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideBidMessage EXCEPT !.ebboPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideBidMessage EXCEPT !.ebboSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideBidMessage EXCEPT !.ebboPriorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideBidMessage EXCEPT !.ebboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Best Bid Or Offer Wide Bid With Priority Customer  *)
(* Message: 21 bytes                                                       *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage ==
    [ nanoseconds                  : Sample(4),
      productId                    : Sample(4),
      ebboPriceLong                : Sample(4),
      ebboSizeLong                 : Sample(4),
      ebboPriorityCustomerSizeLong : Sample(4),
      ebboCondition                : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.ebboPriceLong
        \o message.ebboSizeLong
        \o message.ebboPriorityCustomerSizeLong
        \o message.ebboCondition

DecodeSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET ebboPriceLong == ReadBytes(productId.rest, 4) IN IF ~ebboPriceLong.ok THEN Fail ELSE
    LET ebboSizeLong == ReadBytes(ebboPriceLong.rest, 4) IN IF ~ebboSizeLong.ok THEN Fail ELSE
    LET ebboPriorityCustomerSizeLong == ReadBytes(ebboSizeLong.rest, 4) IN IF ~ebboPriorityCustomerSizeLong.ok THEN Fail ELSE
    LET ebboCondition == ReadBytes(ebboPriorityCustomerSizeLong.rest, 1) IN IF ~ebboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         productId                    |-> productId.value,
         ebboPriceLong                |-> ebboPriceLong.value,
         ebboSizeLong                 |-> ebboSizeLong.value,
         ebboPriorityCustomerSizeLong |-> ebboPriorityCustomerSizeLong.value,
         ebboCondition                |-> ebboCondition.value ], ebboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      productId                    |-> [i \in 1 .. 4 |-> 0],
      ebboPriceLong                |-> [i \in 1 .. 4 |-> 0],
      ebboSizeLong                 |-> [i \in 1 .. 4 |-> 0],
      ebboPriorityCustomerSizeLong |-> [i \in 1 .. 4 |-> 0],
      ebboCondition                |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Wide Bid With Priority Customer Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage EXCEPT !.ebboPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage EXCEPT !.ebboSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage EXCEPT !.ebboPriorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage EXCEPT !.ebboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Best Bid Or Offer Wide Offer Message: 21 bytes     *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferWideOfferMessage ==
    [ nanoseconds                  : Sample(4),
      productId                    : Sample(4),
      ebboPriceLong                : Sample(4),
      ebboSizeLong                 : Sample(4),
      ebboPriorityCustomerSizeLong : Sample(4),
      ebboCondition                : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferWideOfferMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.ebboPriceLong
        \o message.ebboSizeLong
        \o message.ebboPriorityCustomerSizeLong
        \o message.ebboCondition

DecodeSimpleTopOfMarketBestBidOrOfferWideOfferMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET ebboPriceLong == ReadBytes(productId.rest, 4) IN IF ~ebboPriceLong.ok THEN Fail ELSE
    LET ebboSizeLong == ReadBytes(ebboPriceLong.rest, 4) IN IF ~ebboSizeLong.ok THEN Fail ELSE
    LET ebboPriorityCustomerSizeLong == ReadBytes(ebboSizeLong.rest, 4) IN IF ~ebboPriorityCustomerSizeLong.ok THEN Fail ELSE
    LET ebboCondition == ReadBytes(ebboPriorityCustomerSizeLong.rest, 1) IN IF ~ebboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         productId                    |-> productId.value,
         ebboPriceLong                |-> ebboPriceLong.value,
         ebboSizeLong                 |-> ebboSizeLong.value,
         ebboPriorityCustomerSizeLong |-> ebboPriorityCustomerSizeLong.value,
         ebboCondition                |-> ebboCondition.value ], ebboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferWideOfferMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      productId                    |-> [i \in 1 .. 4 |-> 0],
      ebboPriceLong                |-> [i \in 1 .. 4 |-> 0],
      ebboSizeLong                 |-> [i \in 1 .. 4 |-> 0],
      ebboPriorityCustomerSizeLong |-> [i \in 1 .. 4 |-> 0],
      ebboCondition                |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Wide Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferWideOfferMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferWideOfferMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideOfferMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideOfferMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideOfferMessage EXCEPT !.ebboPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideOfferMessage EXCEPT !.ebboSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideOfferMessage EXCEPT !.ebboPriorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideOfferMessage EXCEPT !.ebboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Best Bid Or Offer Wide Offer With Priority         *)
(* Customer Message: 21 bytes                                              *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage ==
    [ nanoseconds                  : Sample(4),
      productId                    : Sample(4),
      ebboPriceLong                : Sample(4),
      ebboSizeLong                 : Sample(4),
      ebboPriorityCustomerSizeLong : Sample(4),
      ebboCondition                : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.ebboPriceLong
        \o message.ebboSizeLong
        \o message.ebboPriorityCustomerSizeLong
        \o message.ebboCondition

DecodeSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET ebboPriceLong == ReadBytes(productId.rest, 4) IN IF ~ebboPriceLong.ok THEN Fail ELSE
    LET ebboSizeLong == ReadBytes(ebboPriceLong.rest, 4) IN IF ~ebboSizeLong.ok THEN Fail ELSE
    LET ebboPriorityCustomerSizeLong == ReadBytes(ebboSizeLong.rest, 4) IN IF ~ebboPriorityCustomerSizeLong.ok THEN Fail ELSE
    LET ebboCondition == ReadBytes(ebboPriorityCustomerSizeLong.rest, 1) IN IF ~ebboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         productId                    |-> productId.value,
         ebboPriceLong                |-> ebboPriceLong.value,
         ebboSizeLong                 |-> ebboSizeLong.value,
         ebboPriorityCustomerSizeLong |-> ebboPriorityCustomerSizeLong.value,
         ebboCondition                |-> ebboCondition.value ], ebboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      productId                    |-> [i \in 1 .. 4 |-> 0],
      ebboPriceLong                |-> [i \in 1 .. 4 |-> 0],
      ebboSizeLong                 |-> [i \in 1 .. 4 |-> 0],
      ebboPriorityCustomerSizeLong |-> [i \in 1 .. 4 |-> 0],
      ebboCondition                |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Wide Offer With Priority Customer Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage EXCEPT !.ebboPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage EXCEPT !.ebboSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage EXCEPT !.ebboPriorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage EXCEPT !.ebboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Double Sided Top Of Market Best Bid Or Offer Compact Message: 22 *)
(* bytes                                                                   *)
(***************************************************************************)

SimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage ==
    [ nanoseconds                    : Sample(4),
      productId                      : Sample(4),
      bidPriceShort                  : Sample(2),
      bidSizeShort                   : Sample(2),
      bidPriorityCustomerSizeShort   : Sample(2),
      bidCondition                   : Sample(1),
      offerPriceShort                : Sample(2),
      offerSizeShort                 : Sample(2),
      offerPriorityCustomerSizeShort : Sample(2),
      offerCondition                 : Sample(1) ]

EncodeSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.bidPriorityCustomerSizeShort
        \o message.bidCondition
        \o message.offerPriceShort
        \o message.offerSizeShort
        \o message.offerPriorityCustomerSizeShort
        \o message.offerCondition

DecodeSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(productId.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET bidPriorityCustomerSizeShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~bidPriorityCustomerSizeShort.ok THEN Fail ELSE
    LET bidCondition == ReadBytes(bidPriorityCustomerSizeShort.rest, 1) IN IF ~bidCondition.ok THEN Fail ELSE
    LET offerPriceShort == ReadBytes(bidCondition.rest, 2) IN IF ~offerPriceShort.ok THEN Fail ELSE
    LET offerSizeShort == ReadBytes(offerPriceShort.rest, 2) IN IF ~offerSizeShort.ok THEN Fail ELSE
    LET offerPriorityCustomerSizeShort == ReadBytes(offerSizeShort.rest, 2) IN IF ~offerPriorityCustomerSizeShort.ok THEN Fail ELSE
    LET offerCondition == ReadBytes(offerPriorityCustomerSizeShort.rest, 1) IN IF ~offerCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                    |-> nanoseconds.value,
         productId                      |-> productId.value,
         bidPriceShort                  |-> bidPriceShort.value,
         bidSizeShort                   |-> bidSizeShort.value,
         bidPriorityCustomerSizeShort   |-> bidPriorityCustomerSizeShort.value,
         bidCondition                   |-> bidCondition.value,
         offerPriceShort                |-> offerPriceShort.value,
         offerSizeShort                 |-> offerSizeShort.value,
         offerPriorityCustomerSizeShort |-> offerPriorityCustomerSizeShort.value,
         offerCondition                 |-> offerCondition.value ], offerCondition.rest)

ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage ==
    [ nanoseconds                    |-> [i \in 1 .. 4 |-> 0],
      productId                      |-> [i \in 1 .. 4 |-> 0],
      bidPriceShort                  |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort                   |-> [i \in 1 .. 2 |-> 0],
      bidPriorityCustomerSizeShort   |-> [i \in 1 .. 2 |-> 0],
      bidCondition                   |-> [i \in 1 .. 1 |-> 0],
      offerPriceShort                |-> [i \in 1 .. 2 |-> 0],
      offerSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      offerPriorityCustomerSizeShort |-> [i \in 1 .. 2 |-> 0],
      offerCondition                 |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Double Sided Top Of Market Best Bid Or Offer Compact Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage ==
    { ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage EXCEPT !.bidPriorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage EXCEPT !.bidCondition = one] : one \in Sample(1) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage EXCEPT !.offerPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage EXCEPT !.offerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage EXCEPT !.offerPriorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage EXCEPT !.offerCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Double Sided Top Of Market Best Bid Or Offer Wide Message: 34    *)
(* bytes                                                                   *)
(***************************************************************************)

SimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage ==
    [ nanoseconds                   : Sample(4),
      productId                     : Sample(4),
      bidPriceLong                  : Sample(4),
      bidSizeLong                   : Sample(4),
      bidPriorityCustomerSizeLong   : Sample(4),
      bidCondition                  : Sample(1),
      offerPriceLong                : Sample(4),
      offerSizeLong                 : Sample(4),
      offerPriorityCustomerSizeLong : Sample(4),
      offerCondition                : Sample(1) ]

EncodeSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.bidPriceLong
        \o message.bidSizeLong
        \o message.bidPriorityCustomerSizeLong
        \o message.bidCondition
        \o message.offerPriceLong
        \o message.offerSizeLong
        \o message.offerPriorityCustomerSizeLong
        \o message.offerCondition

DecodeSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(productId.rest, 4) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET bidPriorityCustomerSizeLong == ReadBytes(bidSizeLong.rest, 4) IN IF ~bidPriorityCustomerSizeLong.ok THEN Fail ELSE
    LET bidCondition == ReadBytes(bidPriorityCustomerSizeLong.rest, 1) IN IF ~bidCondition.ok THEN Fail ELSE
    LET offerPriceLong == ReadBytes(bidCondition.rest, 4) IN IF ~offerPriceLong.ok THEN Fail ELSE
    LET offerSizeLong == ReadBytes(offerPriceLong.rest, 4) IN IF ~offerSizeLong.ok THEN Fail ELSE
    LET offerPriorityCustomerSizeLong == ReadBytes(offerSizeLong.rest, 4) IN IF ~offerPriorityCustomerSizeLong.ok THEN Fail ELSE
    LET offerCondition == ReadBytes(offerPriorityCustomerSizeLong.rest, 1) IN IF ~offerCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                   |-> nanoseconds.value,
         productId                     |-> productId.value,
         bidPriceLong                  |-> bidPriceLong.value,
         bidSizeLong                   |-> bidSizeLong.value,
         bidPriorityCustomerSizeLong   |-> bidPriorityCustomerSizeLong.value,
         bidCondition                  |-> bidCondition.value,
         offerPriceLong                |-> offerPriceLong.value,
         offerSizeLong                 |-> offerSizeLong.value,
         offerPriorityCustomerSizeLong |-> offerPriorityCustomerSizeLong.value,
         offerCondition                |-> offerCondition.value ], offerCondition.rest)

ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage ==
    [ nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      productId                     |-> [i \in 1 .. 4 |-> 0],
      bidPriceLong                  |-> [i \in 1 .. 4 |-> 0],
      bidSizeLong                   |-> [i \in 1 .. 4 |-> 0],
      bidPriorityCustomerSizeLong   |-> [i \in 1 .. 4 |-> 0],
      bidCondition                  |-> [i \in 1 .. 1 |-> 0],
      offerPriceLong                |-> [i \in 1 .. 4 |-> 0],
      offerSizeLong                 |-> [i \in 1 .. 4 |-> 0],
      offerPriorityCustomerSizeLong |-> [i \in 1 .. 4 |-> 0],
      offerCondition                |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Double Sided Top Of Market Best Bid Or Offer Wide Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage ==
    { ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage EXCEPT !.bidPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage EXCEPT !.bidPriorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage EXCEPT !.bidCondition = one] : one \in Sample(1) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage EXCEPT !.offerPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage EXCEPT !.offerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage EXCEPT !.offerPriorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage EXCEPT !.offerCondition = one] : one \in Sample(1) }

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
    [ nanoseconds                      : Sample(4),
      underlyingSymbol                 : Sample(11),
      tradingStatus                    : Sample(1),
      eventReason                      : Sample(1),
      expectedEventTimeSecondsPart     : Sample(4),
      expectedEventTimeNanoSecondsPart : Sample(4) ]

EncodeUnderlyingTradingStatusNotificationMessage(message) ==
    message.nanoseconds
        \o message.underlyingSymbol
        \o message.tradingStatus
        \o message.eventReason
        \o message.expectedEventTimeSecondsPart
        \o message.expectedEventTimeNanoSecondsPart

DecodeUnderlyingTradingStatusNotificationMessage(bytes) ==
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

ZeroUnderlyingTradingStatusNotificationMessage ==
    [ nanoseconds                      |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol                 |-> [i \in 1 .. 11 |-> 0],
      tradingStatus                    |-> [i \in 1 .. 1 |-> 0],
      eventReason                      |-> [i \in 1 .. 1 |-> 0],
      expectedEventTimeSecondsPart     |-> [i \in 1 .. 4 |-> 0],
      expectedEventTimeNanoSecondsPart |-> [i \in 1 .. 4 |-> 0] ]

(* Underlying Trading Status Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedUnderlyingTradingStatusNotificationMessage ==
    { ZeroUnderlyingTradingStatusNotificationMessage }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(11) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.eventReason = one] : one \in Sample(1) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.expectedEventTimeSecondsPart = one] : one \in Sample(4) }
        \cup { [ZeroUnderlyingTradingStatusNotificationMessage EXCEPT !.expectedEventTimeNanoSecondsPart = one] : one \in Sample(4) }

(***************************************************************************)
(* Data, selected by Message Type                                          *)
(***************************************************************************)

SystemTimeMessageCode == 49  \* "1"
SimpleSeriesUpdateMessageCode == 80  \* "P"
SystemStateMessageCode == 83  \* "S"
SimpleTopOfMarketBestBidOrOfferCompactBidMessageCode == 66  \* "B"
SimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessageCode == 104  \* "h"
SimpleTopOfMarketBestBidOrOfferCompactOfferMessageCode == 79  \* "O"
SimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessageCode == 105  \* "i"
SimpleTopOfMarketBestBidOrOfferWideBidMessageCode == 87  \* "W"
SimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessageCode == 106  \* "j"
SimpleTopOfMarketBestBidOrOfferWideOfferMessageCode == 65  \* "A"
SimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessageCode == 107  \* "k"
SimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessageCode == 100  \* "d"
SimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessageCode == 68  \* "D"
LastSaleMessageCode == 84  \* "T"
TradeCancelMessageCode == 88  \* "X"
UnderlyingTradingStatusNotificationMessageCode == 72  \* "H"

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SimpleSeriesUpdateMessageCode}, body : SimpleSeriesUpdateMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferCompactBidMessageCode}, body : SimpleTopOfMarketBestBidOrOfferCompactBidMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessageCode}, body : SimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferCompactOfferMessageCode}, body : SimpleTopOfMarketBestBidOrOfferCompactOfferMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessageCode}, body : SimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferWideBidMessageCode}, body : SimpleTopOfMarketBestBidOrOfferWideBidMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessageCode}, body : SimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferWideOfferMessageCode}, body : SimpleTopOfMarketBestBidOrOfferWideOfferMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessageCode}, body : SimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage ]
        \cup [ tag : {SimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessageCode}, body : SimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage ]
        \cup [ tag : {SimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessageCode}, body : SimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage ]
        \cup [ tag : {LastSaleMessageCode}, body : LastSaleMessage ]
        \cup [ tag : {TradeCancelMessageCode}, body : TradeCancelMessage ]
        \cup [ tag : {UnderlyingTradingStatusNotificationMessageCode}, body : UnderlyingTradingStatusNotificationMessage ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SimpleSeriesUpdateMessageCode -> EncodeSimpleSeriesUpdateMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferCompactBidMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferCompactBidMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferCompactOfferMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferCompactOfferMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferWideBidMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferWideBidMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferWideOfferMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferWideOfferMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage(message.body)
      [] message.tag = SimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessageCode -> EncodeSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage(message.body)
      [] message.tag = SimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessageCode -> EncodeSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage(message.body)
      [] message.tag = LastSaleMessageCode -> EncodeLastSaleMessage(message.body)
      [] message.tag = TradeCancelMessageCode -> EncodeTradeCancelMessage(message.body)
      [] message.tag = UnderlyingTradingStatusNotificationMessageCode -> EncodeUnderlyingTradingStatusNotificationMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SimpleSeriesUpdateMessageCode -> DecodeSimpleSeriesUpdateMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferCompactBidMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferCompactBidMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferCompactOfferMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferCompactOfferMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferWideBidMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferWideBidMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferWideOfferMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferWideOfferMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage(bytes)
              [] tag = SimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessageCode -> DecodeSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage(bytes)
              [] tag = SimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessageCode -> DecodeSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage(bytes)
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
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferCompactBidMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferCompactBidMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferCompactOfferMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferCompactOfferMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferWideBidMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferWideBidMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferWideOfferMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferWideOfferMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage }
        \cup { [tag |-> SimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessageCode, body |-> one] : one \in CheckedSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage }
        \cup { [tag |-> SimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessageCode, body |-> one] : one \in CheckedSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage }
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
(* Udp Packet                                                              *)
(***************************************************************************)

UdpPacket ==
    [ machMessage : SampleLists(OneMachMessage) ]

EncodeUdpPacket(message) ==
    EncodeMachMessageList(message.machMessage)

DecodeUdpPacket(bytes) ==
    LET machMessage == ReadMachMessageAll(bytes) IN IF ~machMessage.ok THEN Fail ELSE
    Ok([ machMessage |-> machMessage.value ], machMessage.rest)

ZeroUdpPacket ==
    [ machMessage |-> << >> ]

(* Udp Packet at zero, then each field in turn at the values it is checked at *)
CheckedUdpPacket ==
    { ZeroUdpPacket }
        \cup { [ZeroUdpPacket EXCEPT !.machMessage = one] : one \in SampleLists(OneMachMessage) }

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

(* Every Simple Top Of Market Best Bid Or Offer Compact Bid Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferCompactBidMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferCompactBidMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferCompactBidMessage(EncodeSimpleTopOfMarketBestBidOrOfferCompactBidMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Best Bid Or Offer Compact Bid With Priority Customer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage(EncodeSimpleTopOfMarketBestBidOrOfferCompactBidWithPriorityCustomerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Best Bid Or Offer Compact Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferCompactOfferMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferCompactOfferMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferCompactOfferMessage(EncodeSimpleTopOfMarketBestBidOrOfferCompactOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Best Bid Or Offer Compact Offer With Priority Customer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage(EncodeSimpleTopOfMarketBestBidOrOfferCompactOfferWithPriorityCustomerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Best Bid Or Offer Wide Bid Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferWideBidMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferWideBidMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferWideBidMessage(EncodeSimpleTopOfMarketBestBidOrOfferWideBidMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Best Bid Or Offer Wide Bid With Priority Customer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage(EncodeSimpleTopOfMarketBestBidOrOfferWideBidWithPriorityCustomerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Best Bid Or Offer Wide Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferWideOfferMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferWideOfferMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferWideOfferMessage(EncodeSimpleTopOfMarketBestBidOrOfferWideOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Best Bid Or Offer Wide Offer With Priority Customer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage(EncodeSimpleTopOfMarketBestBidOrOfferWideOfferWithPriorityCustomerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Double Sided Top Of Market Best Bid Or Offer Compact Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage ==
    \A message \in CheckedSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage :
        LET read == DecodeSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage(EncodeSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Double Sided Top Of Market Best Bid Or Offer Wide Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage ==
    \A message \in CheckedSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage :
        LET read == DecodeSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage(EncodeSimpleDoubleSidedTopOfMarketBestBidOrOfferWideMessage(message))
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

(* Every Udp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUdpPacket ==
    \A message \in CheckedUdpPacket :
        LET read == DecodeUdpPacket(EncodeUdpPacket(message))
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
