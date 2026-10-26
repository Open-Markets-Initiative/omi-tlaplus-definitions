--------------- MODULE SapphireOptions_TopOfMarket_v2_0_Udp ----------------
(***************************************************************************)
(* Miami International Holdings Top of Market v2.0                         *)
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
      activeOnSapphire                      : Sample(1),
      sapphireBboPostingIncrementIndicator  : Sample(1),
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
        \o message.activeOnSapphire
        \o message.sapphireBboPostingIncrementIndicator
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
    LET activeOnSapphire == ReadBytes(longTermOption.rest, 1) IN IF ~activeOnSapphire.ok THEN Fail ELSE
    LET sapphireBboPostingIncrementIndicator == ReadBytes(activeOnSapphire.rest, 1) IN IF ~sapphireBboPostingIncrementIndicator.ok THEN Fail ELSE
    LET liquidityAcceptanceIncrementIndicator == ReadBytes(sapphireBboPostingIncrementIndicator.rest, 1) IN IF ~liquidityAcceptanceIncrementIndicator.ok THEN Fail ELSE
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
         activeOnSapphire                      |-> activeOnSapphire.value,
         sapphireBboPostingIncrementIndicator  |-> sapphireBboPostingIncrementIndicator.value,
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
      activeOnSapphire                      |-> [i \in 1 .. 1 |-> 0],
      sapphireBboPostingIncrementIndicator  |-> [i \in 1 .. 1 |-> 0],
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
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.activeOnSapphire = one] : one \in Sample(1) }
        \cup { [ZeroSeriesUpdateMessage EXCEPT !.sapphireBboPostingIncrementIndicator = one] : one \in Sample(1) }
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
(* Simple Top Of Market Best Bid Or Offer Compact Format Bid Message: 15   *)
(* bytes                                                                   *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage ==
    [ nanoseconds                   : Sample(4),
      productId                     : Sample(4),
      sbboPriceShort                : Sample(2),
      sbboSizeShort                 : Sample(2),
      sbboPriorityCustomerSizeShort : Sample(2),
      sbboCondition                 : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.sbboPriceShort
        \o message.sbboSizeShort
        \o message.sbboPriorityCustomerSizeShort
        \o message.sbboCondition

DecodeSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET sbboPriceShort == ReadBytes(productId.rest, 2) IN IF ~sbboPriceShort.ok THEN Fail ELSE
    LET sbboSizeShort == ReadBytes(sbboPriceShort.rest, 2) IN IF ~sbboSizeShort.ok THEN Fail ELSE
    LET sbboPriorityCustomerSizeShort == ReadBytes(sbboSizeShort.rest, 2) IN IF ~sbboPriorityCustomerSizeShort.ok THEN Fail ELSE
    LET sbboCondition == ReadBytes(sbboPriorityCustomerSizeShort.rest, 1) IN IF ~sbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                   |-> nanoseconds.value,
         productId                     |-> productId.value,
         sbboPriceShort                |-> sbboPriceShort.value,
         sbboSizeShort                 |-> sbboSizeShort.value,
         sbboPriorityCustomerSizeShort |-> sbboPriorityCustomerSizeShort.value,
         sbboCondition                 |-> sbboCondition.value ], sbboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage ==
    [ nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      productId                     |-> [i \in 1 .. 4 |-> 0],
      sbboPriceShort                |-> [i \in 1 .. 2 |-> 0],
      sbboSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      sbboPriorityCustomerSizeShort |-> [i \in 1 .. 2 |-> 0],
      sbboCondition                 |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Compact Format Bid Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage EXCEPT !.sbboPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage EXCEPT !.sbboSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage EXCEPT !.sbboPriorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage EXCEPT !.sbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Best Bid Or Offer Compact Format Bid Priority      *)
(* Customer Message: 15 bytes                                              *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage ==
    [ nanoseconds                   : Sample(4),
      productId                     : Sample(4),
      sbboPriceShort                : Sample(2),
      sbboSizeShort                 : Sample(2),
      sbboPriorityCustomerSizeShort : Sample(2),
      sbboCondition                 : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.sbboPriceShort
        \o message.sbboSizeShort
        \o message.sbboPriorityCustomerSizeShort
        \o message.sbboCondition

DecodeSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET sbboPriceShort == ReadBytes(productId.rest, 2) IN IF ~sbboPriceShort.ok THEN Fail ELSE
    LET sbboSizeShort == ReadBytes(sbboPriceShort.rest, 2) IN IF ~sbboSizeShort.ok THEN Fail ELSE
    LET sbboPriorityCustomerSizeShort == ReadBytes(sbboSizeShort.rest, 2) IN IF ~sbboPriorityCustomerSizeShort.ok THEN Fail ELSE
    LET sbboCondition == ReadBytes(sbboPriorityCustomerSizeShort.rest, 1) IN IF ~sbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                   |-> nanoseconds.value,
         productId                     |-> productId.value,
         sbboPriceShort                |-> sbboPriceShort.value,
         sbboSizeShort                 |-> sbboSizeShort.value,
         sbboPriorityCustomerSizeShort |-> sbboPriorityCustomerSizeShort.value,
         sbboCondition                 |-> sbboCondition.value ], sbboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage ==
    [ nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      productId                     |-> [i \in 1 .. 4 |-> 0],
      sbboPriceShort                |-> [i \in 1 .. 2 |-> 0],
      sbboSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      sbboPriorityCustomerSizeShort |-> [i \in 1 .. 2 |-> 0],
      sbboCondition                 |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Compact Format Bid Priority Customer Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage EXCEPT !.sbboPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage EXCEPT !.sbboSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage EXCEPT !.sbboPriorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage EXCEPT !.sbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Best Bid Or Offer Compact Format Offer Message: 15 *)
(* bytes                                                                   *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage ==
    [ nanoseconds                   : Sample(4),
      productId                     : Sample(4),
      sbboPriceShort                : Sample(2),
      sbboSizeShort                 : Sample(2),
      sbboPriorityCustomerSizeShort : Sample(2),
      sbboCondition                 : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.sbboPriceShort
        \o message.sbboSizeShort
        \o message.sbboPriorityCustomerSizeShort
        \o message.sbboCondition

DecodeSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET sbboPriceShort == ReadBytes(productId.rest, 2) IN IF ~sbboPriceShort.ok THEN Fail ELSE
    LET sbboSizeShort == ReadBytes(sbboPriceShort.rest, 2) IN IF ~sbboSizeShort.ok THEN Fail ELSE
    LET sbboPriorityCustomerSizeShort == ReadBytes(sbboSizeShort.rest, 2) IN IF ~sbboPriorityCustomerSizeShort.ok THEN Fail ELSE
    LET sbboCondition == ReadBytes(sbboPriorityCustomerSizeShort.rest, 1) IN IF ~sbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                   |-> nanoseconds.value,
         productId                     |-> productId.value,
         sbboPriceShort                |-> sbboPriceShort.value,
         sbboSizeShort                 |-> sbboSizeShort.value,
         sbboPriorityCustomerSizeShort |-> sbboPriorityCustomerSizeShort.value,
         sbboCondition                 |-> sbboCondition.value ], sbboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage ==
    [ nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      productId                     |-> [i \in 1 .. 4 |-> 0],
      sbboPriceShort                |-> [i \in 1 .. 2 |-> 0],
      sbboSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      sbboPriorityCustomerSizeShort |-> [i \in 1 .. 2 |-> 0],
      sbboCondition                 |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Compact Format Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage EXCEPT !.sbboPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage EXCEPT !.sbboSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage EXCEPT !.sbboPriorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage EXCEPT !.sbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Best Bid Or Offer Compact Format Offer Priority    *)
(* Customer Message: 15 bytes                                              *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage ==
    [ nanoseconds                   : Sample(4),
      productId                     : Sample(4),
      sbboPriceShort                : Sample(2),
      sbboSizeShort                 : Sample(2),
      sbboPriorityCustomerSizeShort : Sample(2),
      sbboCondition                 : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.sbboPriceShort
        \o message.sbboSizeShort
        \o message.sbboPriorityCustomerSizeShort
        \o message.sbboCondition

DecodeSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET sbboPriceShort == ReadBytes(productId.rest, 2) IN IF ~sbboPriceShort.ok THEN Fail ELSE
    LET sbboSizeShort == ReadBytes(sbboPriceShort.rest, 2) IN IF ~sbboSizeShort.ok THEN Fail ELSE
    LET sbboPriorityCustomerSizeShort == ReadBytes(sbboSizeShort.rest, 2) IN IF ~sbboPriorityCustomerSizeShort.ok THEN Fail ELSE
    LET sbboCondition == ReadBytes(sbboPriorityCustomerSizeShort.rest, 1) IN IF ~sbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                   |-> nanoseconds.value,
         productId                     |-> productId.value,
         sbboPriceShort                |-> sbboPriceShort.value,
         sbboSizeShort                 |-> sbboSizeShort.value,
         sbboPriorityCustomerSizeShort |-> sbboPriorityCustomerSizeShort.value,
         sbboCondition                 |-> sbboCondition.value ], sbboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage ==
    [ nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      productId                     |-> [i \in 1 .. 4 |-> 0],
      sbboPriceShort                |-> [i \in 1 .. 2 |-> 0],
      sbboSizeShort                 |-> [i \in 1 .. 2 |-> 0],
      sbboPriorityCustomerSizeShort |-> [i \in 1 .. 2 |-> 0],
      sbboCondition                 |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Compact Format Offer Priority Customer Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage EXCEPT !.sbboPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage EXCEPT !.sbboSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage EXCEPT !.sbboPriorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage EXCEPT !.sbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Best Bid Or Offer Wide Format Bid Message: 21      *)
(* bytes                                                                   *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferWideFormatBidMessage ==
    [ nanoseconds                  : Sample(4),
      productId                    : Sample(4),
      sbboPriceLong                : Sample(4),
      sbboSizeLong                 : Sample(4),
      sbboPriorityCustomerSizeLong : Sample(4),
      sbboCondition                : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.sbboPriceLong
        \o message.sbboSizeLong
        \o message.sbboPriorityCustomerSizeLong
        \o message.sbboCondition

DecodeSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET sbboPriceLong == ReadBytes(productId.rest, 4) IN IF ~sbboPriceLong.ok THEN Fail ELSE
    LET sbboSizeLong == ReadBytes(sbboPriceLong.rest, 4) IN IF ~sbboSizeLong.ok THEN Fail ELSE
    LET sbboPriorityCustomerSizeLong == ReadBytes(sbboSizeLong.rest, 4) IN IF ~sbboPriorityCustomerSizeLong.ok THEN Fail ELSE
    LET sbboCondition == ReadBytes(sbboPriorityCustomerSizeLong.rest, 1) IN IF ~sbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         productId                    |-> productId.value,
         sbboPriceLong                |-> sbboPriceLong.value,
         sbboSizeLong                 |-> sbboSizeLong.value,
         sbboPriorityCustomerSizeLong |-> sbboPriorityCustomerSizeLong.value,
         sbboCondition                |-> sbboCondition.value ], sbboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      productId                    |-> [i \in 1 .. 4 |-> 0],
      sbboPriceLong                |-> [i \in 1 .. 4 |-> 0],
      sbboSizeLong                 |-> [i \in 1 .. 4 |-> 0],
      sbboPriorityCustomerSizeLong |-> [i \in 1 .. 4 |-> 0],
      sbboCondition                |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Wide Format Bid Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage EXCEPT !.sbboPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage EXCEPT !.sbboSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage EXCEPT !.sbboPriorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage EXCEPT !.sbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Best Bid Or Offer Wide Format Bid Priority         *)
(* Customer Message: 21 bytes                                              *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage ==
    [ nanoseconds                  : Sample(4),
      productId                    : Sample(4),
      sbboPriceLong                : Sample(4),
      sbboSizeLong                 : Sample(4),
      sbboPriorityCustomerSizeLong : Sample(4),
      sbboCondition                : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.sbboPriceLong
        \o message.sbboSizeLong
        \o message.sbboPriorityCustomerSizeLong
        \o message.sbboCondition

DecodeSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET sbboPriceLong == ReadBytes(productId.rest, 4) IN IF ~sbboPriceLong.ok THEN Fail ELSE
    LET sbboSizeLong == ReadBytes(sbboPriceLong.rest, 4) IN IF ~sbboSizeLong.ok THEN Fail ELSE
    LET sbboPriorityCustomerSizeLong == ReadBytes(sbboSizeLong.rest, 4) IN IF ~sbboPriorityCustomerSizeLong.ok THEN Fail ELSE
    LET sbboCondition == ReadBytes(sbboPriorityCustomerSizeLong.rest, 1) IN IF ~sbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         productId                    |-> productId.value,
         sbboPriceLong                |-> sbboPriceLong.value,
         sbboSizeLong                 |-> sbboSizeLong.value,
         sbboPriorityCustomerSizeLong |-> sbboPriorityCustomerSizeLong.value,
         sbboCondition                |-> sbboCondition.value ], sbboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      productId                    |-> [i \in 1 .. 4 |-> 0],
      sbboPriceLong                |-> [i \in 1 .. 4 |-> 0],
      sbboSizeLong                 |-> [i \in 1 .. 4 |-> 0],
      sbboPriorityCustomerSizeLong |-> [i \in 1 .. 4 |-> 0],
      sbboCondition                |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Wide Format Bid Priority Customer Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage EXCEPT !.sbboPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage EXCEPT !.sbboSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage EXCEPT !.sbboPriorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage EXCEPT !.sbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Best Bid Or Offer Wide Format Offer Message: 21    *)
(* bytes                                                                   *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage ==
    [ nanoseconds                  : Sample(4),
      productId                    : Sample(4),
      sbboPriceLong                : Sample(4),
      sbboSizeLong                 : Sample(4),
      sbboPriorityCustomerSizeLong : Sample(4),
      sbboCondition                : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.sbboPriceLong
        \o message.sbboSizeLong
        \o message.sbboPriorityCustomerSizeLong
        \o message.sbboCondition

DecodeSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET sbboPriceLong == ReadBytes(productId.rest, 4) IN IF ~sbboPriceLong.ok THEN Fail ELSE
    LET sbboSizeLong == ReadBytes(sbboPriceLong.rest, 4) IN IF ~sbboSizeLong.ok THEN Fail ELSE
    LET sbboPriorityCustomerSizeLong == ReadBytes(sbboSizeLong.rest, 4) IN IF ~sbboPriorityCustomerSizeLong.ok THEN Fail ELSE
    LET sbboCondition == ReadBytes(sbboPriorityCustomerSizeLong.rest, 1) IN IF ~sbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         productId                    |-> productId.value,
         sbboPriceLong                |-> sbboPriceLong.value,
         sbboSizeLong                 |-> sbboSizeLong.value,
         sbboPriorityCustomerSizeLong |-> sbboPriorityCustomerSizeLong.value,
         sbboCondition                |-> sbboCondition.value ], sbboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      productId                    |-> [i \in 1 .. 4 |-> 0],
      sbboPriceLong                |-> [i \in 1 .. 4 |-> 0],
      sbboSizeLong                 |-> [i \in 1 .. 4 |-> 0],
      sbboPriorityCustomerSizeLong |-> [i \in 1 .. 4 |-> 0],
      sbboCondition                |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Wide Format Offer Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage EXCEPT !.sbboPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage EXCEPT !.sbboSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage EXCEPT !.sbboPriorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage EXCEPT !.sbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Top Of Market Best Bid Or Offer Wide Format Offer Priority       *)
(* Customer Message: 21 bytes                                              *)
(***************************************************************************)

SimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage ==
    [ nanoseconds                  : Sample(4),
      productId                    : Sample(4),
      sbboPriceLong                : Sample(4),
      sbboSizeLong                 : Sample(4),
      sbboPriorityCustomerSizeLong : Sample(4),
      sbboCondition                : Sample(1) ]

EncodeSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage(message) ==
    message.nanoseconds
        \o message.productId
        \o message.sbboPriceLong
        \o message.sbboSizeLong
        \o message.sbboPriorityCustomerSizeLong
        \o message.sbboCondition

DecodeSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage(bytes) ==
    LET nanoseconds == ReadBytes(bytes, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET productId == ReadBytes(nanoseconds.rest, 4) IN IF ~productId.ok THEN Fail ELSE
    LET sbboPriceLong == ReadBytes(productId.rest, 4) IN IF ~sbboPriceLong.ok THEN Fail ELSE
    LET sbboSizeLong == ReadBytes(sbboPriceLong.rest, 4) IN IF ~sbboSizeLong.ok THEN Fail ELSE
    LET sbboPriorityCustomerSizeLong == ReadBytes(sbboSizeLong.rest, 4) IN IF ~sbboPriorityCustomerSizeLong.ok THEN Fail ELSE
    LET sbboCondition == ReadBytes(sbboPriorityCustomerSizeLong.rest, 1) IN IF ~sbboCondition.ok THEN Fail ELSE
    Ok([ nanoseconds                  |-> nanoseconds.value,
         productId                    |-> productId.value,
         sbboPriceLong                |-> sbboPriceLong.value,
         sbboSizeLong                 |-> sbboSizeLong.value,
         sbboPriorityCustomerSizeLong |-> sbboPriorityCustomerSizeLong.value,
         sbboCondition                |-> sbboCondition.value ], sbboCondition.rest)

ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage ==
    [ nanoseconds                  |-> [i \in 1 .. 4 |-> 0],
      productId                    |-> [i \in 1 .. 4 |-> 0],
      sbboPriceLong                |-> [i \in 1 .. 4 |-> 0],
      sbboSizeLong                 |-> [i \in 1 .. 4 |-> 0],
      sbboPriorityCustomerSizeLong |-> [i \in 1 .. 4 |-> 0],
      sbboCondition                |-> [i \in 1 .. 1 |-> 0] ]

(* Simple Top Of Market Best Bid Or Offer Wide Format Offer Priority Customer Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage ==
    { ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage EXCEPT !.sbboPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage EXCEPT !.sbboSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage EXCEPT !.sbboPriorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage EXCEPT !.sbboCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Double Sided Top Of Market Best Bid Or Offer Compact Format      *)
(* Message: 22 bytes                                                       *)
(***************************************************************************)

SimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage ==
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

EncodeSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage(message) ==
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

DecodeSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage(bytes) ==
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

ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage ==
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

(* Simple Double Sided Top Of Market Best Bid Or Offer Compact Format Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage ==
    { ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage EXCEPT !.bidPriorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage EXCEPT !.bidCondition = one] : one \in Sample(1) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage EXCEPT !.offerPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage EXCEPT !.offerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage EXCEPT !.offerPriorityCustomerSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage EXCEPT !.offerCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Double Sided Top Of Market Best Bid Or Offer Wide Format         *)
(* Message: 34 bytes                                                       *)
(***************************************************************************)

SimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage ==
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

EncodeSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage(message) ==
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

DecodeSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage(bytes) ==
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

ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage ==
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

(* Simple Double Sided Top Of Market Best Bid Or Offer Wide Format Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage ==
    { ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage EXCEPT !.productId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage EXCEPT !.bidPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage EXCEPT !.bidPriorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage EXCEPT !.bidCondition = one] : one \in Sample(1) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage EXCEPT !.offerPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage EXCEPT !.offerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage EXCEPT !.offerPriorityCustomerSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage EXCEPT !.offerCondition = one] : one \in Sample(1) }

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
SeriesUpdateMessageCode == 80  \* "P"
SystemStateMessageCode == 83  \* "S"
SimpleTopOfMarketBestBidOrOfferCompactFormatBidMessageCode == 66  \* "B"
SimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessageCode == 104  \* "h"
SimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessageCode == 79  \* "O"
SimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessageCode == 105  \* "i"
SimpleTopOfMarketBestBidOrOfferWideFormatBidMessageCode == 87  \* "W"
SimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessageCode == 106  \* "j"
SimpleTopOfMarketBestBidOrOfferWideFormatOfferMessageCode == 65  \* "A"
SimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessageCode == 107  \* "k"
SimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessageCode == 100  \* "d"
SimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessageCode == 68  \* "D"
LastSaleMessageCode == 84  \* "T"
TradeCancelMessageCode == 88  \* "X"
UnderlyingTradingStatusNotificationMessageCode == 72  \* "H"

Data ==
    [ tag : {SystemTimeMessageCode}, body : SystemTimeMessage ]
        \cup [ tag : {SeriesUpdateMessageCode}, body : SeriesUpdateMessage ]
        \cup [ tag : {SystemStateMessageCode}, body : SystemStateMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferCompactFormatBidMessageCode}, body : SimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessageCode}, body : SimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessageCode}, body : SimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessageCode}, body : SimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferWideFormatBidMessageCode}, body : SimpleTopOfMarketBestBidOrOfferWideFormatBidMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessageCode}, body : SimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferWideFormatOfferMessageCode}, body : SimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage ]
        \cup [ tag : {SimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessageCode}, body : SimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage ]
        \cup [ tag : {SimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessageCode}, body : SimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage ]
        \cup [ tag : {SimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessageCode}, body : SimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage ]
        \cup [ tag : {LastSaleMessageCode}, body : LastSaleMessage ]
        \cup [ tag : {TradeCancelMessageCode}, body : TradeCancelMessage ]
        \cup [ tag : {UnderlyingTradingStatusNotificationMessageCode}, body : UnderlyingTradingStatusNotificationMessage ]

EncodeData(message) ==
    CASE message.tag = SystemTimeMessageCode -> EncodeSystemTimeMessage(message.body)
      [] message.tag = SeriesUpdateMessageCode -> EncodeSeriesUpdateMessage(message.body)
      [] message.tag = SystemStateMessageCode -> EncodeSystemStateMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferCompactFormatBidMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferWideFormatBidMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferWideFormatOfferMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage(message.body)
      [] message.tag = SimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessageCode -> EncodeSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage(message.body)
      [] message.tag = SimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessageCode -> EncodeSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage(message.body)
      [] message.tag = SimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessageCode -> EncodeSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage(message.body)
      [] message.tag = LastSaleMessageCode -> EncodeLastSaleMessage(message.body)
      [] message.tag = TradeCancelMessageCode -> EncodeTradeCancelMessage(message.body)
      [] message.tag = UnderlyingTradingStatusNotificationMessageCode -> EncodeUnderlyingTradingStatusNotificationMessage(message.body)

DecodeData(tag, bytes) ==
    LET read ==
            CASE tag = SystemTimeMessageCode -> DecodeSystemTimeMessage(bytes)
              [] tag = SeriesUpdateMessageCode -> DecodeSeriesUpdateMessage(bytes)
              [] tag = SystemStateMessageCode -> DecodeSystemStateMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferCompactFormatBidMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferWideFormatBidMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferWideFormatOfferMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage(bytes)
              [] tag = SimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessageCode -> DecodeSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage(bytes)
              [] tag = SimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessageCode -> DecodeSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage(bytes)
              [] tag = SimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessageCode -> DecodeSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage(bytes)
              [] tag = LastSaleMessageCode -> DecodeLastSaleMessage(bytes)
              [] tag = TradeCancelMessageCode -> DecodeTradeCancelMessage(bytes)
              [] tag = UnderlyingTradingStatusNotificationMessageCode -> DecodeUnderlyingTradingStatusNotificationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroData == [tag |-> SystemTimeMessageCode, body |-> ZeroSystemTimeMessage]

(* Each Data in turn, at the values the message it names is checked at *)
CheckedData ==
    { [tag |-> SystemTimeMessageCode, body |-> one] : one \in CheckedSystemTimeMessage }
        \cup { [tag |-> SeriesUpdateMessageCode, body |-> one] : one \in CheckedSeriesUpdateMessage }
        \cup { [tag |-> SystemStateMessageCode, body |-> one] : one \in CheckedSystemStateMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferCompactFormatBidMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferWideFormatBidMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferWideFormatOfferMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage }
        \cup { [tag |-> SimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessageCode, body |-> one] : one \in CheckedSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage }
        \cup { [tag |-> SimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessageCode, body |-> one] : one \in CheckedSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage }
        \cup { [tag |-> SimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessageCode, body |-> one] : one \in CheckedSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage }
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

(* Every Simple Top Of Market Best Bid Or Offer Compact Format Bid Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage(EncodeSimpleTopOfMarketBestBidOrOfferCompactFormatBidMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Best Bid Or Offer Compact Format Bid Priority Customer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage(EncodeSimpleTopOfMarketBestBidOrOfferCompactFormatBidPriorityCustomerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Best Bid Or Offer Compact Format Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage(EncodeSimpleTopOfMarketBestBidOrOfferCompactFormatOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Best Bid Or Offer Compact Format Offer Priority Customer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage(EncodeSimpleTopOfMarketBestBidOrOfferCompactFormatOfferPriorityCustomerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Best Bid Or Offer Wide Format Bid Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage(EncodeSimpleTopOfMarketBestBidOrOfferWideFormatBidMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Best Bid Or Offer Wide Format Bid Priority Customer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage(EncodeSimpleTopOfMarketBestBidOrOfferWideFormatBidPriorityCustomerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Best Bid Or Offer Wide Format Offer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage(EncodeSimpleTopOfMarketBestBidOrOfferWideFormatOfferMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Top Of Market Best Bid Or Offer Wide Format Offer Priority Customer Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage ==
    \A message \in CheckedSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage :
        LET read == DecodeSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage(EncodeSimpleTopOfMarketBestBidOrOfferWideFormatOfferPriorityCustomerMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Double Sided Top Of Market Best Bid Or Offer Compact Format Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage ==
    \A message \in CheckedSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage :
        LET read == DecodeSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage(EncodeSimpleDoubleSidedTopOfMarketBestBidOrOfferCompactFormatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Double Sided Top Of Market Best Bid Or Offer Wide Format Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage ==
    \A message \in CheckedSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage :
        LET read == DecodeSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage(EncodeSimpleDoubleSidedTopOfMarketBestBidOrOfferWideFormatMessage(message))
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
