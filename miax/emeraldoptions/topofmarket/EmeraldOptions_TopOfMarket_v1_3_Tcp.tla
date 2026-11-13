---------------- MODULE EmeraldOptions_TopOfMarket_v1_3_Tcp ----------------
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
(* License: MIT No Attribution                                             *)
(*                                                                         *)
(* Note: Sequenced Data Packet fills what is left of the frame Sesm Packet *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Application Message fills what is left of the frame Sesm Packet   *)
(* Length states, which is what it is read from.                           *)
(*                                                                         *)
(* Note: Unsequenced Data Packet fills what is left of the frame Sesm      *)
(* Packet Length states, which is what it is read from.                    *)
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
(* Sequenced Data Packet: 10 bytes                                         *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequenceNumber       : Sample(8),
      matchingEngineId     : Sample(1),
      sequencedMessageType : Sample(1) ]

EncodeSequencedDataPacket(message) ==
    message.sequenceNumber
        \o message.matchingEngineId
        \o message.sequencedMessageType

DecodeSequencedDataPacket(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET matchingEngineId == ReadBytes(sequenceNumber.rest, 1) IN IF ~matchingEngineId.ok THEN Fail ELSE
    LET sequencedMessageType == ReadBytes(matchingEngineId.rest, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    Ok([ sequenceNumber       |-> sequenceNumber.value,
         matchingEngineId     |-> matchingEngineId.value,
         sequencedMessageType |-> sequencedMessageType.value ], sequencedMessageType.rest)

ZeroSequencedDataPacket ==
    [ sequenceNumber       |-> [i \in 1 .. 8 |-> 0],
      matchingEngineId     |-> [i \in 1 .. 1 |-> 0],
      sequencedMessageType |-> [i \in 1 .. 1 |-> 0] ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.matchingEngineId = one] : one \in Sample(1) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessageType = one] : one \in Sample(1) }

(***************************************************************************)
(* Refresh Request Message: 1 bytes                                        *)
(***************************************************************************)

RefreshRequestMessage ==
    [ refreshMessageType : Sample(1) ]

EncodeRefreshRequestMessage(message) ==
    message.refreshMessageType

DecodeRefreshRequestMessage(bytes) ==
    LET refreshMessageType == ReadBytes(bytes, 1) IN IF ~refreshMessageType.ok THEN Fail ELSE
    Ok([ refreshMessageType |-> refreshMessageType.value ], refreshMessageType.rest)

ZeroRefreshRequestMessage ==
    [ refreshMessageType |-> [i \in 1 .. 1 |-> 0] ]

(* Refresh Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshRequestMessage ==
    { ZeroRefreshRequestMessage }
        \cup { [ZeroRefreshRequestMessage EXCEPT !.refreshMessageType = one] : one \in Sample(1) }

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
(* Refresh Response Message                                                *)
(***************************************************************************)

RefreshResponseMessage ==
    [ sequenceNumber     : Sample(8),
      applicationMessage : ApplicationMessage ]

EncodeRefreshResponseMessage(message) ==
    message.sequenceNumber
        \o EncodeApplicationMessage(message.applicationMessage)

DecodeRefreshResponseMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET applicationMessage == DecodeApplicationMessage(sequenceNumber.rest) IN IF ~applicationMessage.ok THEN Fail ELSE
    Ok([ sequenceNumber     |-> sequenceNumber.value,
         applicationMessage |-> applicationMessage.value ], applicationMessage.rest)

ZeroRefreshResponseMessage ==
    [ sequenceNumber     |-> [i \in 1 .. 8 |-> 0],
      applicationMessage |-> ZeroApplicationMessage ]

(* Refresh Response Message at zero, then each field in turn at the values it is checked at *)
CheckedRefreshResponseMessage ==
    { ZeroRefreshResponseMessage }
        \cup { [ZeroRefreshResponseMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRefreshResponseMessage EXCEPT !.applicationMessage = one] : one \in CheckedApplicationMessage }

(***************************************************************************)
(* End Of Refresh Notification Message: 1 bytes                            *)
(***************************************************************************)

EndOfRefreshNotificationMessage ==
    [ refreshMessageType : Sample(1) ]

EncodeEndOfRefreshNotificationMessage(message) ==
    message.refreshMessageType

DecodeEndOfRefreshNotificationMessage(bytes) ==
    LET refreshMessageType == ReadBytes(bytes, 1) IN IF ~refreshMessageType.ok THEN Fail ELSE
    Ok([ refreshMessageType |-> refreshMessageType.value ], refreshMessageType.rest)

ZeroEndOfRefreshNotificationMessage ==
    [ refreshMessageType |-> [i \in 1 .. 1 |-> 0] ]

(* End Of Refresh Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfRefreshNotificationMessage ==
    { ZeroEndOfRefreshNotificationMessage }
        \cup { [ZeroEndOfRefreshNotificationMessage EXCEPT !.refreshMessageType = one] : one \in Sample(1) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

RefreshRequestMessageCode == 82  \* "R"
RefreshResponseMessageCode == 114  \* "r"
EndOfRefreshNotificationMessageCode == 69  \* "E"

UnsequencedMessage ==
    [ tag : {RefreshRequestMessageCode}, body : RefreshRequestMessage ]
        \cup [ tag : {RefreshResponseMessageCode}, body : RefreshResponseMessage ]
        \cup [ tag : {EndOfRefreshNotificationMessageCode}, body : EndOfRefreshNotificationMessage ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = RefreshRequestMessageCode -> EncodeRefreshRequestMessage(message.body)
      [] message.tag = RefreshResponseMessageCode -> EncodeRefreshResponseMessage(message.body)
      [] message.tag = EndOfRefreshNotificationMessageCode -> EncodeEndOfRefreshNotificationMessage(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = RefreshRequestMessageCode -> DecodeRefreshRequestMessage(bytes)
              [] tag = RefreshResponseMessageCode -> DecodeRefreshResponseMessage(bytes)
              [] tag = EndOfRefreshNotificationMessageCode -> DecodeEndOfRefreshNotificationMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> RefreshRequestMessageCode, body |-> ZeroRefreshRequestMessage]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> RefreshRequestMessageCode, body |-> one] : one \in CheckedRefreshRequestMessage }
        \cup { [tag |-> RefreshResponseMessageCode, body |-> one] : one \in CheckedRefreshResponseMessage }
        \cup { [tag |-> EndOfRefreshNotificationMessageCode, body |-> one] : one \in CheckedEndOfRefreshNotificationMessage }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessage : UnsequencedMessage ]

EncodeUnsequencedDataPacket(message) ==
    EncodeUIntBE(message.unsequencedMessage.tag, 1)
        \o EncodeUnsequencedMessage(message.unsequencedMessage)

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~unsequencedMessageType.ok THEN Fail ELSE
    LET unsequencedMessage == DecodeUnsequencedMessage(unsequencedMessageType.value, unsequencedMessageType.rest) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroUnsequencedDataPacket ==
    [ unsequencedMessage |-> ZeroUnsequencedMessage ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessage = one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Login Request: 35 bytes                                                 *)
(***************************************************************************)

LoginRequest ==
    [ sesmVersion               : Sample(5),
      username                  : Sample(5),
      computerId                : Sample(8),
      applicationProtocol       : Sample(8),
      requestedTradingSessionId : Sample(1),
      requestedSequenceNumber   : Sample(8) ]

EncodeLoginRequest(message) ==
    message.sesmVersion
        \o message.username
        \o message.computerId
        \o message.applicationProtocol
        \o message.requestedTradingSessionId
        \o message.requestedSequenceNumber

DecodeLoginRequest(bytes) ==
    LET sesmVersion == ReadBytes(bytes, 5) IN IF ~sesmVersion.ok THEN Fail ELSE
    LET username == ReadBytes(sesmVersion.rest, 5) IN IF ~username.ok THEN Fail ELSE
    LET computerId == ReadBytes(username.rest, 8) IN IF ~computerId.ok THEN Fail ELSE
    LET applicationProtocol == ReadBytes(computerId.rest, 8) IN IF ~applicationProtocol.ok THEN Fail ELSE
    LET requestedTradingSessionId == ReadBytes(applicationProtocol.rest, 1) IN IF ~requestedTradingSessionId.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedTradingSessionId.rest, 8) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ sesmVersion               |-> sesmVersion.value,
         username                  |-> username.value,
         computerId                |-> computerId.value,
         applicationProtocol       |-> applicationProtocol.value,
         requestedTradingSessionId |-> requestedTradingSessionId.value,
         requestedSequenceNumber   |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroLoginRequest ==
    [ sesmVersion               |-> [i \in 1 .. 5 |-> 0],
      username                  |-> [i \in 1 .. 5 |-> 0],
      computerId                |-> [i \in 1 .. 8 |-> 0],
      applicationProtocol       |-> [i \in 1 .. 8 |-> 0],
      requestedTradingSessionId |-> [i \in 1 .. 1 |-> 0],
      requestedSequenceNumber   |-> [i \in 1 .. 8 |-> 0] ]

(* Login Request at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequest ==
    { ZeroLoginRequest }
        \cup { [ZeroLoginRequest EXCEPT !.sesmVersion = one] : one \in Sample(5) }
        \cup { [ZeroLoginRequest EXCEPT !.username = one] : one \in Sample(5) }
        \cup { [ZeroLoginRequest EXCEPT !.computerId = one] : one \in Sample(8) }
        \cup { [ZeroLoginRequest EXCEPT !.applicationProtocol = one] : one \in Sample(8) }
        \cup { [ZeroLoginRequest EXCEPT !.requestedTradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroLoginRequest EXCEPT !.requestedSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Login Response: 11 bytes                                                *)
(***************************************************************************)

LoginResponse ==
    [ numberOfMatchingEngines : Sample(1),
      loginStatus             : Sample(1),
      tradingSessionId        : Sample(1),
      highestSequenceNumber   : Sample(8) ]

EncodeLoginResponse(message) ==
    message.numberOfMatchingEngines
        \o message.loginStatus
        \o message.tradingSessionId
        \o message.highestSequenceNumber

DecodeLoginResponse(bytes) ==
    LET numberOfMatchingEngines == ReadBytes(bytes, 1) IN IF ~numberOfMatchingEngines.ok THEN Fail ELSE
    LET loginStatus == ReadBytes(numberOfMatchingEngines.rest, 1) IN IF ~loginStatus.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(loginStatus.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET highestSequenceNumber == ReadBytes(tradingSessionId.rest, 8) IN IF ~highestSequenceNumber.ok THEN Fail ELSE
    Ok([ numberOfMatchingEngines |-> numberOfMatchingEngines.value,
         loginStatus             |-> loginStatus.value,
         tradingSessionId        |-> tradingSessionId.value,
         highestSequenceNumber   |-> highestSequenceNumber.value ], highestSequenceNumber.rest)

ZeroLoginResponse ==
    [ numberOfMatchingEngines |-> [i \in 1 .. 1 |-> 0],
      loginStatus             |-> [i \in 1 .. 1 |-> 0],
      tradingSessionId        |-> [i \in 1 .. 1 |-> 0],
      highestSequenceNumber   |-> [i \in 1 .. 8 |-> 0] ]

(* Login Response at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponse ==
    { ZeroLoginResponse }
        \cup { [ZeroLoginResponse EXCEPT !.numberOfMatchingEngines = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.loginStatus = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponse EXCEPT !.highestSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Synchronization Complete: 1 bytes                                       *)
(***************************************************************************)

SynchronizationComplete ==
    [ numberOfMatchingEngines : Sample(1) ]

EncodeSynchronizationComplete(message) ==
    message.numberOfMatchingEngines

DecodeSynchronizationComplete(bytes) ==
    LET numberOfMatchingEngines == ReadBytes(bytes, 1) IN IF ~numberOfMatchingEngines.ok THEN Fail ELSE
    Ok([ numberOfMatchingEngines |-> numberOfMatchingEngines.value ], numberOfMatchingEngines.rest)

ZeroSynchronizationComplete ==
    [ numberOfMatchingEngines |-> [i \in 1 .. 1 |-> 0] ]

(* Synchronization Complete at zero, then each field in turn at the values it is checked at *)
CheckedSynchronizationComplete ==
    { ZeroSynchronizationComplete }
        \cup { [ZeroSynchronizationComplete EXCEPT !.numberOfMatchingEngines = one] : one \in Sample(1) }

(***************************************************************************)
(* Retransmission Request: 16 bytes                                        *)
(***************************************************************************)

RetransmissionRequest ==
    [ startSequenceNumber : Sample(8),
      endSequenceNumber   : Sample(8) ]

EncodeRetransmissionRequest(message) ==
    message.startSequenceNumber
        \o message.endSequenceNumber

DecodeRetransmissionRequest(bytes) ==
    LET startSequenceNumber == ReadBytes(bytes, 8) IN IF ~startSequenceNumber.ok THEN Fail ELSE
    LET endSequenceNumber == ReadBytes(startSequenceNumber.rest, 8) IN IF ~endSequenceNumber.ok THEN Fail ELSE
    Ok([ startSequenceNumber |-> startSequenceNumber.value,
         endSequenceNumber   |-> endSequenceNumber.value ], endSequenceNumber.rest)

ZeroRetransmissionRequest ==
    [ startSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      endSequenceNumber   |-> [i \in 1 .. 8 |-> 0] ]

(* Retransmission Request at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequest ==
    { ZeroRetransmissionRequest }
        \cup { [ZeroRetransmissionRequest EXCEPT !.startSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroRetransmissionRequest EXCEPT !.endSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Logout Request                                                          *)
(***************************************************************************)

LogoutRequest ==
    [ logoutReason : Sample(1),
      logoutText   : SampleBytes ]

EncodeLogoutRequest(message) ==
    message.logoutReason
        \o message.logoutText

DecodeLogoutRequest(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutText == Ok(logoutReason.rest, << >>) IN IF ~logoutText.ok THEN Fail ELSE
    Ok([ logoutReason |-> logoutReason.value,
         logoutText   |-> logoutText.value ], logoutText.rest)

ZeroLogoutRequest ==
    [ logoutReason |-> [i \in 1 .. 1 |-> 0],
      logoutText   |-> << >> ]

(* Logout Request at zero, then each field in turn at the values it is checked at *)
CheckedLogoutRequest ==
    { ZeroLogoutRequest }
        \cup { [ZeroLogoutRequest EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroLogoutRequest EXCEPT !.logoutText = one] : one \in SampleBytes }

(***************************************************************************)
(* Goodbye Packet                                                          *)
(***************************************************************************)

GoodbyePacket ==
    [ logoutReason : Sample(1),
      logoutText   : SampleBytes ]

EncodeGoodbyePacket(message) ==
    message.logoutReason
        \o message.logoutText

DecodeGoodbyePacket(bytes) ==
    LET logoutReason == ReadBytes(bytes, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    LET logoutText == Ok(logoutReason.rest, << >>) IN IF ~logoutText.ok THEN Fail ELSE
    Ok([ logoutReason |-> logoutReason.value,
         logoutText   |-> logoutText.value ], logoutText.rest)

ZeroGoodbyePacket ==
    [ logoutReason |-> [i \in 1 .. 1 |-> 0],
      logoutText   |-> << >> ]

(* Goodbye Packet at zero, then each field in turn at the values it is checked at *)
CheckedGoodbyePacket ==
    { ZeroGoodbyePacket }
        \cup { [ZeroGoodbyePacket EXCEPT !.logoutReason = one] : one \in Sample(1) }
        \cup { [ZeroGoodbyePacket EXCEPT !.logoutText = one] : one \in SampleBytes }

(***************************************************************************)
(* Test Packet                                                             *)
(***************************************************************************)

TestPacket ==
    [ testText : SampleBytes ]

EncodeTestPacket(message) ==
    message.testText

DecodeTestPacket(bytes) ==
    LET testText == Ok(bytes, << >>) IN IF ~testText.ok THEN Fail ELSE
    Ok([ testText |-> testText.value ], testText.rest)

ZeroTestPacket ==
    [ testText |-> << >> ]

(* Test Packet at zero, then each field in turn at the values it is checked at *)
CheckedTestPacket ==
    { ZeroTestPacket }
        \cup { [ZeroTestPacket EXCEPT !.testText = one] : one \in SampleBytes }

(***************************************************************************)
(* Sesm Payload, selected by Sesm Packet Type                              *)
(***************************************************************************)

SequencedDataPacketCode == 115  \* "s"
UnsequencedDataPacketCode == 85  \* "U"
LoginRequestCode == 108  \* "l"
LoginResponseCode == 114  \* "r"
SynchronizationCompleteCode == 99  \* "c"
RetransmissionRequestCode == 97  \* "a"
LogoutRequestCode == 88  \* "X"
GoodbyePacketCode == 71  \* "G"
TradingSessionUpdateCode == 117  \* "u"
ServerHeartbeatCode == 48  \* "0"
ClientHeartbeatCode == 49  \* "1"
TestPacketCode == 84  \* "T"

SesmPayload ==
    [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {LoginRequestCode}, body : LoginRequest ]
        \cup [ tag : {LoginResponseCode}, body : LoginResponse ]
        \cup [ tag : {SynchronizationCompleteCode}, body : SynchronizationComplete ]
        \cup [ tag : {RetransmissionRequestCode}, body : RetransmissionRequest ]
        \cup [ tag : {LogoutRequestCode}, body : LogoutRequest ]
        \cup [ tag : {GoodbyePacketCode}, body : GoodbyePacket ]
        \cup [ tag : {TradingSessionUpdateCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TestPacketCode}, body : TestPacket ]

EncodeSesmPayload(message) ==
    CASE message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = LoginRequestCode -> EncodeLoginRequest(message.body)
      [] message.tag = LoginResponseCode -> EncodeLoginResponse(message.body)
      [] message.tag = SynchronizationCompleteCode -> EncodeSynchronizationComplete(message.body)
      [] message.tag = RetransmissionRequestCode -> EncodeRetransmissionRequest(message.body)
      [] message.tag = LogoutRequestCode -> EncodeLogoutRequest(message.body)
      [] message.tag = GoodbyePacketCode -> EncodeGoodbyePacket(message.body)
      [] message.tag = TradingSessionUpdateCode -> << >>
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = TestPacketCode -> EncodeTestPacket(message.body)

DecodeSesmPayload(tag, bytes) ==
    LET read ==
            CASE tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = LoginRequestCode -> DecodeLoginRequest(bytes)
              [] tag = LoginResponseCode -> DecodeLoginResponse(bytes)
              [] tag = SynchronizationCompleteCode -> DecodeSynchronizationComplete(bytes)
              [] tag = RetransmissionRequestCode -> DecodeRetransmissionRequest(bytes)
              [] tag = LogoutRequestCode -> DecodeLogoutRequest(bytes)
              [] tag = GoodbyePacketCode -> DecodeGoodbyePacket(bytes)
              [] tag = TradingSessionUpdateCode -> Ok([empty |-> 0], bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = TestPacketCode -> DecodeTestPacket(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSesmPayload == [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]

(* Each Sesm Payload in turn, at the values the message it names is checked at *)
CheckedSesmPayload ==
    { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }
        \cup { [tag |-> LoginRequestCode, body |-> one] : one \in CheckedLoginRequest }
        \cup { [tag |-> LoginResponseCode, body |-> one] : one \in CheckedLoginResponse }
        \cup { [tag |-> SynchronizationCompleteCode, body |-> one] : one \in CheckedSynchronizationComplete }
        \cup { [tag |-> RetransmissionRequestCode, body |-> one] : one \in CheckedRetransmissionRequest }
        \cup { [tag |-> LogoutRequestCode, body |-> one] : one \in CheckedLogoutRequest }
        \cup { [tag |-> GoodbyePacketCode, body |-> one] : one \in CheckedGoodbyePacket }
        \cup { [tag |-> TradingSessionUpdateCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TestPacketCode, body |-> one] : one \in CheckedTestPacket }

(***************************************************************************)
(* Sesm Tcp Packet, framed by Sesm Packet Length                           *)
(***************************************************************************)

SesmTcpPacket ==
    [ sesmPayload : SesmPayload ]

EncodeSesmTcpPacketBody(message) ==
    EncodeUIntBE(message.sesmPayload.tag, 1)
        \o EncodeSesmPayload(message.sesmPayload)

(* Sesm Packet Length counts the bytes it frames, so it is written from them *)
EncodeSesmTcpPacket(message) ==
    LET body == EncodeSesmTcpPacketBody(message)
    IN  EncodeUIntLE(Len(body), 2) \o body

DecodeSesmTcpPacketBody(bytes) ==
    LET sesmPacketType == ReadUIntBE(bytes, 1) IN IF ~sesmPacketType.ok THEN Fail ELSE
    LET sesmPayload == DecodeSesmPayload(sesmPacketType.value, sesmPacketType.rest) IN IF ~sesmPayload.ok THEN Fail ELSE
    Ok([ sesmPayload |-> sesmPayload.value ], sesmPayload.rest)

DecodeSesmTcpPacket(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeSesmTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroSesmTcpPacket ==
    [ sesmPayload |-> ZeroSesmPayload ]

(* Sesm Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedSesmTcpPacket ==
    { ZeroSesmTcpPacket }
        \cup { [ZeroSesmTcpPacket EXCEPT !.sesmPayload = one] : one \in CheckedSesmPayload }

(* A run of Sesm Tcp Packet, written one after another *)
RECURSIVE EncodeSesmTcpPacketList(_)
EncodeSesmTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSesmTcpPacket(Head(messages)) \o EncodeSesmTcpPacketList(Tail(messages))

(* As many Sesm Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadSesmTcpPacketAll(_)
ReadSesmTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeSesmTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSesmTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sesm Tcp Packet of each kind, for the lists that carry them *)
OneSesmTcpPacket ==
    { [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LoginRequestCode, body |-> ZeroLoginRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LoginResponseCode, body |-> ZeroLoginResponse]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> SynchronizationCompleteCode, body |-> ZeroSynchronizationComplete]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> RetransmissionRequestCode, body |-> ZeroRetransmissionRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> LogoutRequestCode, body |-> ZeroLogoutRequest]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> GoodbyePacketCode, body |-> ZeroGoodbyePacket]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> TradingSessionUpdateCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroSesmTcpPacket EXCEPT !.sesmPayload = [tag |-> TestPacketCode, body |-> ZeroTestPacket]] }

(***************************************************************************)
(* Tcp Packet                                                              *)
(***************************************************************************)

TcpPacket ==
    [ sesmTcpPacket : SampleLists(OneSesmTcpPacket) ]

EncodeTcpPacket(message) ==
    EncodeSesmTcpPacketList(message.sesmTcpPacket)

DecodeTcpPacket(bytes) ==
    LET sesmTcpPacket == ReadSesmTcpPacketAll(bytes) IN IF ~sesmTcpPacket.ok THEN Fail ELSE
    Ok([ sesmTcpPacket |-> sesmTcpPacket.value ], sesmTcpPacket.rest)

ZeroTcpPacket ==
    [ sesmTcpPacket |-> << >> ]

(* Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedTcpPacket ==
    { ZeroTcpPacket }
        \cup { [ZeroTcpPacket EXCEPT !.sesmTcpPacket = one] : one \in SampleLists(OneSesmTcpPacket) }

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

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Refresh Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshRequestMessage ==
    \A message \in CheckedRefreshRequestMessage :
        LET read == DecodeRefreshRequestMessage(EncodeRefreshRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

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

(* Every Refresh Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRefreshResponseMessage ==
    \A message \in CheckedRefreshResponseMessage :
        LET read == DecodeRefreshResponseMessage(EncodeRefreshResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Refresh Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfRefreshNotificationMessage ==
    \A message \in CheckedEndOfRefreshNotificationMessage :
        LET read == DecodeEndOfRefreshNotificationMessage(EncodeEndOfRefreshNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedDataPacket ==
    \A message \in CheckedUnsequencedDataPacket :
        LET read == DecodeUnsequencedDataPacket(EncodeUnsequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequest ==
    \A message \in CheckedLoginRequest :
        LET read == DecodeLoginRequest(EncodeLoginRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Response decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponse ==
    \A message \in CheckedLoginResponse :
        LET read == DecodeLoginResponse(EncodeLoginResponse(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Synchronization Complete decodes back to what was encoded, and leaves nothing over *)
RoundTripSynchronizationComplete ==
    \A message \in CheckedSynchronizationComplete :
        LET read == DecodeSynchronizationComplete(EncodeSynchronizationComplete(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequest ==
    \A message \in CheckedRetransmissionRequest :
        LET read == DecodeRetransmissionRequest(EncodeRetransmissionRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Request decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutRequest ==
    \A message \in CheckedLogoutRequest :
        LET read == DecodeLogoutRequest(EncodeLogoutRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Goodbye Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripGoodbyePacket ==
    \A message \in CheckedGoodbyePacket :
        LET read == DecodeGoodbyePacket(EncodeGoodbyePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Test Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripTestPacket ==
    \A message \in CheckedTestPacket :
        LET read == DecodeTestPacket(EncodeTestPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sesm Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSesmTcpPacket ==
    \A message \in CheckedSesmTcpPacket :
        LET read == DecodeSesmTcpPacket(EncodeSesmTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripTcpPacket ==
    \A message \in CheckedTcpPacket :
        LET read == DecodeTcpPacket(EncodeTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Data is selected by the Message Type it is written under *)
SelectsData ==
    \A message \in CheckedData :
        LET sent == EncodeData(message)
            read == DecodeData(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Unsequenced Message is selected by the Unsequenced Message Type it is written under *)
SelectsUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET sent == EncodeUnsequencedMessage(message)
            read == DecodeUnsequencedMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Sesm Payload is selected by the Sesm Packet Type it is written under *)
SelectsSesmPayload ==
    \A message \in CheckedSesmPayload :
        LET sent == EncodeSesmPayload(message)
            read == DecodeSesmPayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Sesm Packet Length is written from the bytes it frames *)
FramesSesmTcpPacket ==
    \A message \in CheckedSesmTcpPacket :
        LET bytes == EncodeSesmTcpPacket(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
