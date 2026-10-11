------------------- MODULE C1Options_Flex_Pitch_v1_1_30 --------------------
(***************************************************************************)
(* Chicago Board Options Exchange Flex v1.1.30                             *)
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
(* Note: a Message Count of 0 marks Heartbeat and carries no Message.      *)
(*                                                                         *)
(* Note: Bit Fields is a bit field set, checked as its 1 byte rather than  *)
(* bit by bit.                                                             *)
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
(* Time Reference Message: 16 bytes                                        *)
(***************************************************************************)

TimeReferenceMessage ==
    [ midnightReference : Sample(4),
      timeReference     : Sample(4),
      timeOffset        : Sample(4),
      tradeDate         : Sample(4) ]

EncodeTimeReferenceMessage(message) ==
    message.midnightReference
        \o message.timeReference
        \o message.timeOffset
        \o message.tradeDate

DecodeTimeReferenceMessage(bytes) ==
    LET midnightReference == ReadBytes(bytes, 4) IN IF ~midnightReference.ok THEN Fail ELSE
    LET timeReference == ReadBytes(midnightReference.rest, 4) IN IF ~timeReference.ok THEN Fail ELSE
    LET timeOffset == ReadBytes(timeReference.rest, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(timeOffset.rest, 4) IN IF ~tradeDate.ok THEN Fail ELSE
    Ok([ midnightReference |-> midnightReference.value,
         timeReference     |-> timeReference.value,
         timeOffset        |-> timeOffset.value,
         tradeDate         |-> tradeDate.value ], tradeDate.rest)

ZeroTimeReferenceMessage ==
    [ midnightReference |-> [i \in 1 .. 4 |-> 0],
      timeReference     |-> [i \in 1 .. 4 |-> 0],
      timeOffset        |-> [i \in 1 .. 4 |-> 0],
      tradeDate         |-> [i \in 1 .. 4 |-> 0] ]

(* Time Reference Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeReferenceMessage ==
    { ZeroTimeReferenceMessage }
        \cup { [ZeroTimeReferenceMessage EXCEPT !.midnightReference = one] : one \in Sample(4) }
        \cup { [ZeroTimeReferenceMessage EXCEPT !.timeReference = one] : one \in Sample(4) }
        \cup { [ZeroTimeReferenceMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTimeReferenceMessage EXCEPT !.tradeDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Time Message: 8 bytes                                                   *)
(***************************************************************************)

TimeMessage ==
    [ time      : Sample(4),
      epochTime : Sample(4) ]

EncodeTimeMessage(message) ==
    message.time
        \o message.epochTime

DecodeTimeMessage(bytes) ==
    LET time == ReadBytes(bytes, 4) IN IF ~time.ok THEN Fail ELSE
    LET epochTime == ReadBytes(time.rest, 4) IN IF ~epochTime.ok THEN Fail ELSE
    Ok([ time      |-> time.value,
         epochTime |-> epochTime.value ], epochTime.rest)

ZeroTimeMessage ==
    [ time      |-> [i \in 1 .. 4 |-> 0],
      epochTime |-> [i \in 1 .. 4 |-> 0] ]

(* Time Message at zero, then each field in turn at the values it is checked at *)
CheckedTimeMessage ==
    { ZeroTimeMessage }
        \cup { [ZeroTimeMessage EXCEPT !.time = one] : one \in Sample(4) }
        \cup { [ZeroTimeMessage EXCEPT !.epochTime = one] : one \in Sample(4) }

(***************************************************************************)
(* Flex Instrument Definition Message: 55 bytes                            *)
(***************************************************************************)

FlexInstrumentDefinitionMessage ==
    [ timeOffset          : Sample(4),
      feedSymbol          : Sample(6),
      osiRoot             : Sample(6),
      year                : Sample(2),
      month               : Sample(2),
      day                 : Sample(2),
      callPutIndicator    : Sample(1),
      dollarStrike        : Sample(5),
      decimalStrike       : Sample(3),
      symbolCondition     : Sample(1),
      underlying          : Sample(8),
      exerciseStyle       : Sample(1),
      settlementType      : Sample(1),
      percentage          : Sample(4),
      observationDay      : Sample(2),
      returnCapPercentage : Sample(4),
      creationDay         : Sample(2),
      bitFields           : Sample(1) ]

EncodeFlexInstrumentDefinitionMessage(message) ==
    message.timeOffset
        \o message.feedSymbol
        \o message.osiRoot
        \o message.year
        \o message.month
        \o message.day
        \o message.callPutIndicator
        \o message.dollarStrike
        \o message.decimalStrike
        \o message.symbolCondition
        \o message.underlying
        \o message.exerciseStyle
        \o message.settlementType
        \o message.percentage
        \o message.observationDay
        \o message.returnCapPercentage
        \o message.creationDay
        \o message.bitFields

DecodeFlexInstrumentDefinitionMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET feedSymbol == ReadBytes(timeOffset.rest, 6) IN IF ~feedSymbol.ok THEN Fail ELSE
    LET osiRoot == ReadBytes(feedSymbol.rest, 6) IN IF ~osiRoot.ok THEN Fail ELSE
    LET year == ReadBytes(osiRoot.rest, 2) IN IF ~year.ok THEN Fail ELSE
    LET month == ReadBytes(year.rest, 2) IN IF ~month.ok THEN Fail ELSE
    LET day == ReadBytes(month.rest, 2) IN IF ~day.ok THEN Fail ELSE
    LET callPutIndicator == ReadBytes(day.rest, 1) IN IF ~callPutIndicator.ok THEN Fail ELSE
    LET dollarStrike == ReadBytes(callPutIndicator.rest, 5) IN IF ~dollarStrike.ok THEN Fail ELSE
    LET decimalStrike == ReadBytes(dollarStrike.rest, 3) IN IF ~decimalStrike.ok THEN Fail ELSE
    LET symbolCondition == ReadBytes(decimalStrike.rest, 1) IN IF ~symbolCondition.ok THEN Fail ELSE
    LET underlying == ReadBytes(symbolCondition.rest, 8) IN IF ~underlying.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(underlying.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    LET settlementType == ReadBytes(exerciseStyle.rest, 1) IN IF ~settlementType.ok THEN Fail ELSE
    LET percentage == ReadBytes(settlementType.rest, 4) IN IF ~percentage.ok THEN Fail ELSE
    LET observationDay == ReadBytes(percentage.rest, 2) IN IF ~observationDay.ok THEN Fail ELSE
    LET returnCapPercentage == ReadBytes(observationDay.rest, 4) IN IF ~returnCapPercentage.ok THEN Fail ELSE
    LET creationDay == ReadBytes(returnCapPercentage.rest, 2) IN IF ~creationDay.ok THEN Fail ELSE
    LET bitFields == ReadBytes(creationDay.rest, 1) IN IF ~bitFields.ok THEN Fail ELSE
    Ok([ timeOffset          |-> timeOffset.value,
         feedSymbol          |-> feedSymbol.value,
         osiRoot             |-> osiRoot.value,
         year                |-> year.value,
         month               |-> month.value,
         day                 |-> day.value,
         callPutIndicator    |-> callPutIndicator.value,
         dollarStrike        |-> dollarStrike.value,
         decimalStrike       |-> decimalStrike.value,
         symbolCondition     |-> symbolCondition.value,
         underlying          |-> underlying.value,
         exerciseStyle       |-> exerciseStyle.value,
         settlementType      |-> settlementType.value,
         percentage          |-> percentage.value,
         observationDay      |-> observationDay.value,
         returnCapPercentage |-> returnCapPercentage.value,
         creationDay         |-> creationDay.value,
         bitFields           |-> bitFields.value ], bitFields.rest)

ZeroFlexInstrumentDefinitionMessage ==
    [ timeOffset          |-> [i \in 1 .. 4 |-> 0],
      feedSymbol          |-> [i \in 1 .. 6 |-> 0],
      osiRoot             |-> [i \in 1 .. 6 |-> 0],
      year                |-> [i \in 1 .. 2 |-> 0],
      month               |-> [i \in 1 .. 2 |-> 0],
      day                 |-> [i \in 1 .. 2 |-> 0],
      callPutIndicator    |-> [i \in 1 .. 1 |-> 0],
      dollarStrike        |-> [i \in 1 .. 5 |-> 0],
      decimalStrike       |-> [i \in 1 .. 3 |-> 0],
      symbolCondition     |-> [i \in 1 .. 1 |-> 0],
      underlying          |-> [i \in 1 .. 8 |-> 0],
      exerciseStyle       |-> [i \in 1 .. 1 |-> 0],
      settlementType      |-> [i \in 1 .. 1 |-> 0],
      percentage          |-> [i \in 1 .. 4 |-> 0],
      observationDay      |-> [i \in 1 .. 2 |-> 0],
      returnCapPercentage |-> [i \in 1 .. 4 |-> 0],
      creationDay         |-> [i \in 1 .. 2 |-> 0],
      bitFields           |-> [i \in 1 .. 1 |-> 0] ]

(* Flex Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedFlexInstrumentDefinitionMessage ==
    { ZeroFlexInstrumentDefinitionMessage }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.feedSymbol = one] : one \in Sample(6) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.osiRoot = one] : one \in Sample(6) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.year = one] : one \in Sample(2) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.month = one] : one \in Sample(2) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.day = one] : one \in Sample(2) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.callPutIndicator = one] : one \in Sample(1) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.dollarStrike = one] : one \in Sample(5) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.decimalStrike = one] : one \in Sample(3) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.symbolCondition = one] : one \in Sample(1) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.underlying = one] : one \in Sample(8) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.settlementType = one] : one \in Sample(1) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.percentage = one] : one \in Sample(4) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.observationDay = one] : one \in Sample(2) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.returnCapPercentage = one] : one \in Sample(4) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.creationDay = one] : one \in Sample(2) }
        \cup { [ZeroFlexInstrumentDefinitionMessage EXCEPT !.bitFields = one] : one \in Sample(1) }

(***************************************************************************)
(* Complex Flex Leg: 13 bytes                                              *)
(***************************************************************************)

ComplexFlexLeg ==
    [ legSymbol       : Sample(8),
      legRatio        : Sample(4),
      legSecurityType : Sample(1) ]

EncodeComplexFlexLeg(message) ==
    message.legSymbol
        \o message.legRatio
        \o message.legSecurityType

DecodeComplexFlexLeg(bytes) ==
    LET legSymbol == ReadBytes(bytes, 8) IN IF ~legSymbol.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSymbol.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legRatio.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    Ok([ legSymbol       |-> legSymbol.value,
         legRatio        |-> legRatio.value,
         legSecurityType |-> legSecurityType.value ], legSecurityType.rest)

ZeroComplexFlexLeg ==
    [ legSymbol       |-> [i \in 1 .. 8 |-> 0],
      legRatio        |-> [i \in 1 .. 4 |-> 0],
      legSecurityType |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Flex Leg at zero, then each field in turn at the values it is checked at *)
CheckedComplexFlexLeg ==
    { ZeroComplexFlexLeg }
        \cup { [ZeroComplexFlexLeg EXCEPT !.legSymbol = one] : one \in Sample(8) }
        \cup { [ZeroComplexFlexLeg EXCEPT !.legRatio = one] : one \in Sample(4) }
        \cup { [ZeroComplexFlexLeg EXCEPT !.legSecurityType = one] : one \in Sample(1) }

(* A run of Complex Flex Leg, written one after another *)
RECURSIVE EncodeComplexFlexLegList(_)
EncodeComplexFlexLegList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexFlexLeg(Head(messages)) \o EncodeComplexFlexLegList(Tail(messages))

(* As many Complex Flex Leg as the field that counts them says *)
RECURSIVE ReadComplexFlexLegList(_, _)
ReadComplexFlexLegList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexFlexLeg(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexFlexLegList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Flex Leg of each kind, for the lists that carry them *)
OneComplexFlexLeg == { ZeroComplexFlexLeg }

(***************************************************************************)
(* Complex Flex Instrument Definition Message                              *)
(***************************************************************************)

ComplexFlexInstrumentDefinitionMessage ==
    [ timeOffset            : Sample(4),
      complexInstrumentId   : Sample(6),
      underlying            : Sample(8),
      complexInstrumentType : Sample(4),
      legCount              : Sample(1),
      messageCount          : Sample(1),
      messageNumber         : Sample(1),
      complexFlexLeg        : SampleLists(OneComplexFlexLeg) ]

EncodeComplexFlexInstrumentDefinitionMessage(message) ==
    message.timeOffset
        \o message.complexInstrumentId
        \o message.underlying
        \o message.complexInstrumentType
        \o message.legCount
        \o message.messageCount
        \o message.messageNumber
        \o EncodeUIntLE(Len(message.complexFlexLeg), 1)
        \o EncodeComplexFlexLegList(message.complexFlexLeg)

DecodeComplexFlexInstrumentDefinitionMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET complexInstrumentId == ReadBytes(timeOffset.rest, 6) IN IF ~complexInstrumentId.ok THEN Fail ELSE
    LET underlying == ReadBytes(complexInstrumentId.rest, 8) IN IF ~underlying.ok THEN Fail ELSE
    LET complexInstrumentType == ReadBytes(underlying.rest, 4) IN IF ~complexInstrumentType.ok THEN Fail ELSE
    LET legCount == ReadBytes(complexInstrumentType.rest, 1) IN IF ~legCount.ok THEN Fail ELSE
    LET messageCount == ReadBytes(legCount.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET messageNumber == ReadBytes(messageCount.rest, 1) IN IF ~messageNumber.ok THEN Fail ELSE
    LET messageLegCount == ReadUIntLE(messageNumber.rest, 1) IN IF ~messageLegCount.ok THEN Fail ELSE
    LET complexFlexLeg == ReadComplexFlexLegList(messageLegCount.rest, messageLegCount.value) IN IF ~complexFlexLeg.ok THEN Fail ELSE
    Ok([ timeOffset            |-> timeOffset.value,
         complexInstrumentId   |-> complexInstrumentId.value,
         underlying            |-> underlying.value,
         complexInstrumentType |-> complexInstrumentType.value,
         legCount              |-> legCount.value,
         messageCount          |-> messageCount.value,
         messageNumber         |-> messageNumber.value,
         complexFlexLeg        |-> complexFlexLeg.value ], complexFlexLeg.rest)

ZeroComplexFlexInstrumentDefinitionMessage ==
    [ timeOffset            |-> [i \in 1 .. 4 |-> 0],
      complexInstrumentId   |-> [i \in 1 .. 6 |-> 0],
      underlying            |-> [i \in 1 .. 8 |-> 0],
      complexInstrumentType |-> [i \in 1 .. 4 |-> 0],
      legCount              |-> [i \in 1 .. 1 |-> 0],
      messageCount          |-> [i \in 1 .. 1 |-> 0],
      messageNumber         |-> [i \in 1 .. 1 |-> 0],
      complexFlexLeg        |-> << >> ]

(* Complex Flex Instrument Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexFlexInstrumentDefinitionMessage ==
    { ZeroComplexFlexInstrumentDefinitionMessage }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.complexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.underlying = one] : one \in Sample(8) }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.complexInstrumentType = one] : one \in Sample(4) }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.legCount = one] : one \in Sample(1) }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.messageCount = one] : one \in Sample(1) }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.messageNumber = one] : one \in Sample(1) }
        \cup { [ZeroComplexFlexInstrumentDefinitionMessage EXCEPT !.complexFlexLeg = one] : one \in SampleLists(OneComplexFlexLeg) }

(***************************************************************************)
(* Auction Notification Message: 45 bytes                                  *)
(***************************************************************************)

AuctionNotificationMessage ==
    [ timeOffset        : Sample(4),
      flexInstrumentId  : Sample(6),
      auctionId         : Sample(8),
      auctionType       : Sample(1),
      side              : Sample(1),
      signedPriceLong   : Sample(8),
      quantityLong      : Sample(4),
      customerIndicator : Sample(1),
      participantId     : Sample(4),
      auctionEndOffset  : Sample(4),
      clientId          : Sample(4) ]

EncodeAuctionNotificationMessage(message) ==
    message.timeOffset
        \o message.flexInstrumentId
        \o message.auctionId
        \o message.auctionType
        \o message.side
        \o message.signedPriceLong
        \o message.quantityLong
        \o message.customerIndicator
        \o message.participantId
        \o message.auctionEndOffset
        \o message.clientId

DecodeAuctionNotificationMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET flexInstrumentId == ReadBytes(timeOffset.rest, 6) IN IF ~flexInstrumentId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(flexInstrumentId.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET side == ReadBytes(auctionType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET signedPriceLong == ReadBytes(side.rest, 8) IN IF ~signedPriceLong.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(signedPriceLong.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(quantityLong.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    LET participantId == ReadBytes(customerIndicator.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET auctionEndOffset == ReadBytes(participantId.rest, 4) IN IF ~auctionEndOffset.ok THEN Fail ELSE
    LET clientId == ReadBytes(auctionEndOffset.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         flexInstrumentId  |-> flexInstrumentId.value,
         auctionId         |-> auctionId.value,
         auctionType       |-> auctionType.value,
         side              |-> side.value,
         signedPriceLong   |-> signedPriceLong.value,
         quantityLong      |-> quantityLong.value,
         customerIndicator |-> customerIndicator.value,
         participantId     |-> participantId.value,
         auctionEndOffset  |-> auctionEndOffset.value,
         clientId          |-> clientId.value ], clientId.rest)

ZeroAuctionNotificationMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      flexInstrumentId  |-> [i \in 1 .. 6 |-> 0],
      auctionId         |-> [i \in 1 .. 8 |-> 0],
      auctionType       |-> [i \in 1 .. 1 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      signedPriceLong   |-> [i \in 1 .. 8 |-> 0],
      quantityLong      |-> [i \in 1 .. 4 |-> 0],
      customerIndicator |-> [i \in 1 .. 1 |-> 0],
      participantId     |-> [i \in 1 .. 4 |-> 0],
      auctionEndOffset  |-> [i \in 1 .. 4 |-> 0],
      clientId          |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionNotificationMessage ==
    { ZeroAuctionNotificationMessage }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.flexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.signedPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionEndOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.clientId = one] : one \in Sample(4) }

(***************************************************************************)
(* Dac Delta: 2 bytes                                                      *)
(***************************************************************************)

DacDelta ==
    [ deltaValue : Sample(2) ]

EncodeDacDelta(message) ==
    message.deltaValue

DecodeDacDelta(bytes) ==
    LET deltaValue == ReadBytes(bytes, 2) IN IF ~deltaValue.ok THEN Fail ELSE
    Ok([ deltaValue |-> deltaValue.value ], deltaValue.rest)

ZeroDacDelta ==
    [ deltaValue |-> [i \in 1 .. 2 |-> 0] ]

(* Dac Delta at zero, then each field in turn at the values it is checked at *)
CheckedDacDelta ==
    { ZeroDacDelta }
        \cup { [ZeroDacDelta EXCEPT !.deltaValue = one] : one \in Sample(2) }

(* A run of Dac Delta, written one after another *)
RECURSIVE EncodeDacDeltaList(_)
EncodeDacDeltaList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeDacDelta(Head(messages)) \o EncodeDacDeltaList(Tail(messages))

(* As many Dac Delta as the field that counts them says *)
RECURSIVE ReadDacDeltaList(_, _)
ReadDacDeltaList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeDacDelta(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadDacDeltaList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Dac Delta of each kind, for the lists that carry them *)
OneDacDelta == { ZeroDacDelta }

(***************************************************************************)
(* Dac Auction Notification Message                                        *)
(***************************************************************************)

DacAuctionNotificationMessage ==
    [ timeOffset        : Sample(4),
      flexInstrumentId  : Sample(6),
      auctionId         : Sample(8),
      auctionType       : Sample(1),
      side              : Sample(1),
      signedPriceLong   : Sample(8),
      quantityLong      : Sample(4),
      customerIndicator : Sample(1),
      participantId     : Sample(4),
      auctionEndOffset  : Sample(4),
      clientId          : Sample(4),
      dacReferencePrice : Sample(8),
      dacDelta          : SampleLists(OneDacDelta) ]

EncodeDacAuctionNotificationMessage(message) ==
    message.timeOffset
        \o message.flexInstrumentId
        \o message.auctionId
        \o message.auctionType
        \o message.side
        \o message.signedPriceLong
        \o message.quantityLong
        \o message.customerIndicator
        \o message.participantId
        \o message.auctionEndOffset
        \o message.clientId
        \o message.dacReferencePrice
        \o EncodeUIntLE(Len(message.dacDelta), 1)
        \o EncodeDacDeltaList(message.dacDelta)

DecodeDacAuctionNotificationMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET flexInstrumentId == ReadBytes(timeOffset.rest, 6) IN IF ~flexInstrumentId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(flexInstrumentId.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET side == ReadBytes(auctionType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET signedPriceLong == ReadBytes(side.rest, 8) IN IF ~signedPriceLong.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(signedPriceLong.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET customerIndicator == ReadBytes(quantityLong.rest, 1) IN IF ~customerIndicator.ok THEN Fail ELSE
    LET participantId == ReadBytes(customerIndicator.rest, 4) IN IF ~participantId.ok THEN Fail ELSE
    LET auctionEndOffset == ReadBytes(participantId.rest, 4) IN IF ~auctionEndOffset.ok THEN Fail ELSE
    LET clientId == ReadBytes(auctionEndOffset.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET dacReferencePrice == ReadBytes(clientId.rest, 8) IN IF ~dacReferencePrice.ok THEN Fail ELSE
    LET dacDeltaCount == ReadUIntLE(dacReferencePrice.rest, 1) IN IF ~dacDeltaCount.ok THEN Fail ELSE
    LET dacDelta == ReadDacDeltaList(dacDeltaCount.rest, dacDeltaCount.value) IN IF ~dacDelta.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         flexInstrumentId  |-> flexInstrumentId.value,
         auctionId         |-> auctionId.value,
         auctionType       |-> auctionType.value,
         side              |-> side.value,
         signedPriceLong   |-> signedPriceLong.value,
         quantityLong      |-> quantityLong.value,
         customerIndicator |-> customerIndicator.value,
         participantId     |-> participantId.value,
         auctionEndOffset  |-> auctionEndOffset.value,
         clientId          |-> clientId.value,
         dacReferencePrice |-> dacReferencePrice.value,
         dacDelta          |-> dacDelta.value ], dacDelta.rest)

ZeroDacAuctionNotificationMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      flexInstrumentId  |-> [i \in 1 .. 6 |-> 0],
      auctionId         |-> [i \in 1 .. 8 |-> 0],
      auctionType       |-> [i \in 1 .. 1 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      signedPriceLong   |-> [i \in 1 .. 8 |-> 0],
      quantityLong      |-> [i \in 1 .. 4 |-> 0],
      customerIndicator |-> [i \in 1 .. 1 |-> 0],
      participantId     |-> [i \in 1 .. 4 |-> 0],
      auctionEndOffset  |-> [i \in 1 .. 4 |-> 0],
      clientId          |-> [i \in 1 .. 4 |-> 0],
      dacReferencePrice |-> [i \in 1 .. 8 |-> 0],
      dacDelta          |-> << >> ]

(* Dac Auction Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedDacAuctionNotificationMessage ==
    { ZeroDacAuctionNotificationMessage }
        \cup { [ZeroDacAuctionNotificationMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroDacAuctionNotificationMessage EXCEPT !.flexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroDacAuctionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroDacAuctionNotificationMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroDacAuctionNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDacAuctionNotificationMessage EXCEPT !.signedPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroDacAuctionNotificationMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroDacAuctionNotificationMessage EXCEPT !.customerIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDacAuctionNotificationMessage EXCEPT !.participantId = one] : one \in Sample(4) }
        \cup { [ZeroDacAuctionNotificationMessage EXCEPT !.auctionEndOffset = one] : one \in Sample(4) }
        \cup { [ZeroDacAuctionNotificationMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroDacAuctionNotificationMessage EXCEPT !.dacReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroDacAuctionNotificationMessage EXCEPT !.dacDelta = one] : one \in SampleLists(OneDacDelta) }

(***************************************************************************)
(* Auction Cancel Message: 12 bytes                                        *)
(***************************************************************************)

AuctionCancelMessage ==
    [ timeOffset : Sample(4),
      auctionId  : Sample(8) ]

EncodeAuctionCancelMessage(message) ==
    message.timeOffset
        \o message.auctionId

DecodeAuctionCancelMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timeOffset.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value,
         auctionId  |-> auctionId.value ], auctionId.rest)

ZeroAuctionCancelMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0],
      auctionId  |-> [i \in 1 .. 8 |-> 0] ]

(* Auction Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionCancelMessage ==
    { ZeroAuctionCancelMessage }
        \cup { [ZeroAuctionCancelMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionCancelMessage EXCEPT !.auctionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Auction Trade Message: 32 bytes                                         *)
(***************************************************************************)

AuctionTradeMessage ==
    [ timeOffset      : Sample(4),
      auctionId       : Sample(8),
      executionId     : Sample(8),
      signedPriceLong : Sample(8),
      quantityLong    : Sample(4) ]

EncodeAuctionTradeMessage(message) ==
    message.timeOffset
        \o message.auctionId
        \o message.executionId
        \o message.signedPriceLong
        \o message.quantityLong

DecodeAuctionTradeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timeOffset.rest, 8) IN IF ~auctionId.ok THEN Fail ELSE
    LET executionId == ReadBytes(auctionId.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET signedPriceLong == ReadBytes(executionId.rest, 8) IN IF ~signedPriceLong.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(signedPriceLong.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    Ok([ timeOffset      |-> timeOffset.value,
         auctionId       |-> auctionId.value,
         executionId     |-> executionId.value,
         signedPriceLong |-> signedPriceLong.value,
         quantityLong    |-> quantityLong.value ], quantityLong.rest)

ZeroAuctionTradeMessage ==
    [ timeOffset      |-> [i \in 1 .. 4 |-> 0],
      auctionId       |-> [i \in 1 .. 8 |-> 0],
      executionId     |-> [i \in 1 .. 8 |-> 0],
      signedPriceLong |-> [i \in 1 .. 8 |-> 0],
      quantityLong    |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionTradeMessage ==
    { ZeroAuctionTradeMessage }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.auctionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.signedPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroAuctionTradeMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Long Message: 40 bytes                                            *)
(***************************************************************************)

TradeLongMessage ==
    [ timeOffset       : Sample(4),
      orderId          : Sample(8),
      sideIndicator    : Sample(1),
      quantityLong     : Sample(4),
      flexInstrumentId : Sample(6),
      signedPriceLong  : Sample(8),
      executionId      : Sample(8),
      tradeCondition   : Sample(1) ]

EncodeTradeLongMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.flexInstrumentId
        \o message.signedPriceLong
        \o message.executionId
        \o message.tradeCondition

DecodeTradeLongMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET flexInstrumentId == ReadBytes(quantityLong.rest, 6) IN IF ~flexInstrumentId.ok THEN Fail ELSE
    LET signedPriceLong == ReadBytes(flexInstrumentId.rest, 8) IN IF ~signedPriceLong.ok THEN Fail ELSE
    LET executionId == ReadBytes(signedPriceLong.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         orderId          |-> orderId.value,
         sideIndicator    |-> sideIndicator.value,
         quantityLong     |-> quantityLong.value,
         flexInstrumentId |-> flexInstrumentId.value,
         signedPriceLong  |-> signedPriceLong.value,
         executionId      |-> executionId.value,
         tradeCondition   |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeLongMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      sideIndicator    |-> [i \in 1 .. 1 |-> 0],
      quantityLong     |-> [i \in 1 .. 4 |-> 0],
      flexInstrumentId |-> [i \in 1 .. 6 |-> 0],
      signedPriceLong  |-> [i \in 1 .. 8 |-> 0],
      executionId      |-> [i \in 1 .. 8 |-> 0],
      tradeCondition   |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Long Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeLongMessage ==
    { ZeroTradeLongMessage }
        \cup { [ZeroTradeLongMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeLongMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroTradeLongMessage EXCEPT !.flexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroTradeLongMessage EXCEPT !.signedPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeLongMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Short Message: 32 bytes                                           *)
(***************************************************************************)

TradeShortMessage ==
    [ timeOffset       : Sample(4),
      orderId          : Sample(8),
      sideIndicator    : Sample(1),
      quantityShort    : Sample(2),
      flexInstrumentId : Sample(6),
      signedPriceShort : Sample(2),
      executionId      : Sample(8),
      tradeCondition   : Sample(1) ]

EncodeTradeShortMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityShort
        \o message.flexInstrumentId
        \o message.signedPriceShort
        \o message.executionId
        \o message.tradeCondition

DecodeTradeShortMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(sideIndicator.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET flexInstrumentId == ReadBytes(quantityShort.rest, 6) IN IF ~flexInstrumentId.ok THEN Fail ELSE
    LET signedPriceShort == ReadBytes(flexInstrumentId.rest, 2) IN IF ~signedPriceShort.ok THEN Fail ELSE
    LET executionId == ReadBytes(signedPriceShort.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         orderId          |-> orderId.value,
         sideIndicator    |-> sideIndicator.value,
         quantityShort    |-> quantityShort.value,
         flexInstrumentId |-> flexInstrumentId.value,
         signedPriceShort |-> signedPriceShort.value,
         executionId      |-> executionId.value,
         tradeCondition   |-> tradeCondition.value ], tradeCondition.rest)

ZeroTradeShortMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      orderId          |-> [i \in 1 .. 8 |-> 0],
      sideIndicator    |-> [i \in 1 .. 1 |-> 0],
      quantityShort    |-> [i \in 1 .. 2 |-> 0],
      flexInstrumentId |-> [i \in 1 .. 6 |-> 0],
      signedPriceShort |-> [i \in 1 .. 2 |-> 0],
      executionId      |-> [i \in 1 .. 8 |-> 0],
      tradeCondition   |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Short Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeShortMessage ==
    { ZeroTradeShortMessage }
        \cup { [ZeroTradeShortMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeShortMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeShortMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.flexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroTradeShortMessage EXCEPT !.signedPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroTradeShortMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroTradeShortMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }

(***************************************************************************)
(* Dac Trade Message: 58 bytes                                             *)
(***************************************************************************)

DacTradeMessage ==
    [ timeOffset        : Sample(4),
      orderId           : Sample(8),
      sideIndicator     : Sample(1),
      quantityLong      : Sample(4),
      flexInstrumentId  : Sample(6),
      signedPriceLong   : Sample(8),
      executionId       : Sample(8),
      tradeCondition    : Sample(1),
      dacReferencePrice : Sample(8),
      dacClosingPrice   : Sample(8),
      dacDeltaValue     : Sample(2) ]

EncodeDacTradeMessage(message) ==
    message.timeOffset
        \o message.orderId
        \o message.sideIndicator
        \o message.quantityLong
        \o message.flexInstrumentId
        \o message.signedPriceLong
        \o message.executionId
        \o message.tradeCondition
        \o message.dacReferencePrice
        \o message.dacClosingPrice
        \o message.dacDeltaValue

DecodeDacTradeMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET orderId == ReadBytes(timeOffset.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sideIndicator == ReadBytes(orderId.rest, 1) IN IF ~sideIndicator.ok THEN Fail ELSE
    LET quantityLong == ReadBytes(sideIndicator.rest, 4) IN IF ~quantityLong.ok THEN Fail ELSE
    LET flexInstrumentId == ReadBytes(quantityLong.rest, 6) IN IF ~flexInstrumentId.ok THEN Fail ELSE
    LET signedPriceLong == ReadBytes(flexInstrumentId.rest, 8) IN IF ~signedPriceLong.ok THEN Fail ELSE
    LET executionId == ReadBytes(signedPriceLong.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    LET tradeCondition == ReadBytes(executionId.rest, 1) IN IF ~tradeCondition.ok THEN Fail ELSE
    LET dacReferencePrice == ReadBytes(tradeCondition.rest, 8) IN IF ~dacReferencePrice.ok THEN Fail ELSE
    LET dacClosingPrice == ReadBytes(dacReferencePrice.rest, 8) IN IF ~dacClosingPrice.ok THEN Fail ELSE
    LET dacDeltaValue == ReadBytes(dacClosingPrice.rest, 2) IN IF ~dacDeltaValue.ok THEN Fail ELSE
    Ok([ timeOffset        |-> timeOffset.value,
         orderId           |-> orderId.value,
         sideIndicator     |-> sideIndicator.value,
         quantityLong      |-> quantityLong.value,
         flexInstrumentId  |-> flexInstrumentId.value,
         signedPriceLong   |-> signedPriceLong.value,
         executionId       |-> executionId.value,
         tradeCondition    |-> tradeCondition.value,
         dacReferencePrice |-> dacReferencePrice.value,
         dacClosingPrice   |-> dacClosingPrice.value,
         dacDeltaValue     |-> dacDeltaValue.value ], dacDeltaValue.rest)

ZeroDacTradeMessage ==
    [ timeOffset        |-> [i \in 1 .. 4 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      sideIndicator     |-> [i \in 1 .. 1 |-> 0],
      quantityLong      |-> [i \in 1 .. 4 |-> 0],
      flexInstrumentId  |-> [i \in 1 .. 6 |-> 0],
      signedPriceLong   |-> [i \in 1 .. 8 |-> 0],
      executionId       |-> [i \in 1 .. 8 |-> 0],
      tradeCondition    |-> [i \in 1 .. 1 |-> 0],
      dacReferencePrice |-> [i \in 1 .. 8 |-> 0],
      dacClosingPrice   |-> [i \in 1 .. 8 |-> 0],
      dacDeltaValue     |-> [i \in 1 .. 2 |-> 0] ]

(* Dac Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedDacTradeMessage ==
    { ZeroDacTradeMessage }
        \cup { [ZeroDacTradeMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroDacTradeMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroDacTradeMessage EXCEPT !.sideIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDacTradeMessage EXCEPT !.quantityLong = one] : one \in Sample(4) }
        \cup { [ZeroDacTradeMessage EXCEPT !.flexInstrumentId = one] : one \in Sample(6) }
        \cup { [ZeroDacTradeMessage EXCEPT !.signedPriceLong = one] : one \in Sample(8) }
        \cup { [ZeroDacTradeMessage EXCEPT !.executionId = one] : one \in Sample(8) }
        \cup { [ZeroDacTradeMessage EXCEPT !.tradeCondition = one] : one \in Sample(1) }
        \cup { [ZeroDacTradeMessage EXCEPT !.dacReferencePrice = one] : one \in Sample(8) }
        \cup { [ZeroDacTradeMessage EXCEPT !.dacClosingPrice = one] : one \in Sample(8) }
        \cup { [ZeroDacTradeMessage EXCEPT !.dacDeltaValue = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Break Message: 12 bytes                                           *)
(***************************************************************************)

TradeBreakMessage ==
    [ timeOffset  : Sample(4),
      executionId : Sample(8) ]

EncodeTradeBreakMessage(message) ==
    message.timeOffset
        \o message.executionId

DecodeTradeBreakMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET executionId == ReadBytes(timeOffset.rest, 8) IN IF ~executionId.ok THEN Fail ELSE
    Ok([ timeOffset  |-> timeOffset.value,
         executionId |-> executionId.value ], executionId.rest)

ZeroTradeBreakMessage ==
    [ timeOffset  |-> [i \in 1 .. 4 |-> 0],
      executionId |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Break Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBreakMessage ==
    { ZeroTradeBreakMessage }
        \cup { [ZeroTradeBreakMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradeBreakMessage EXCEPT !.executionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Symbol Mapping Message: 36 bytes                                        *)
(***************************************************************************)

SymbolMappingMessage ==
    [ feedSymbol      : Sample(6),
      osiSymbol       : Sample(21),
      symbolCondition : Sample(1),
      underlying      : Sample(8) ]

EncodeSymbolMappingMessage(message) ==
    message.feedSymbol
        \o message.osiSymbol
        \o message.symbolCondition
        \o message.underlying

DecodeSymbolMappingMessage(bytes) ==
    LET feedSymbol == ReadBytes(bytes, 6) IN IF ~feedSymbol.ok THEN Fail ELSE
    LET osiSymbol == ReadBytes(feedSymbol.rest, 21) IN IF ~osiSymbol.ok THEN Fail ELSE
    LET symbolCondition == ReadBytes(osiSymbol.rest, 1) IN IF ~symbolCondition.ok THEN Fail ELSE
    LET underlying == ReadBytes(symbolCondition.rest, 8) IN IF ~underlying.ok THEN Fail ELSE
    Ok([ feedSymbol      |-> feedSymbol.value,
         osiSymbol       |-> osiSymbol.value,
         symbolCondition |-> symbolCondition.value,
         underlying      |-> underlying.value ], underlying.rest)

ZeroSymbolMappingMessage ==
    [ feedSymbol      |-> [i \in 1 .. 6 |-> 0],
      osiSymbol       |-> [i \in 1 .. 21 |-> 0],
      symbolCondition |-> [i \in 1 .. 1 |-> 0],
      underlying      |-> [i \in 1 .. 8 |-> 0] ]

(* Symbol Mapping Message at zero, then each field in turn at the values it is checked at *)
CheckedSymbolMappingMessage ==
    { ZeroSymbolMappingMessage }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.feedSymbol = one] : one \in Sample(6) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.osiSymbol = one] : one \in Sample(21) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.symbolCondition = one] : one \in Sample(1) }
        \cup { [ZeroSymbolMappingMessage EXCEPT !.underlying = one] : one \in Sample(8) }

(***************************************************************************)
(* Trading Status Message: 16 bytes                                        *)
(***************************************************************************)

TradingStatusMessage ==
    [ timeOffset       : Sample(4),
      symbol           : Sample(6),
      reserved2        : Sample(2),
      tradingStatus    : Sample(1),
      reserved1        : Sample(1),
      gthTradingStatus : Sample(1),
      secondReserved1  : Sample(1) ]

EncodeTradingStatusMessage(message) ==
    message.timeOffset
        \o message.symbol
        \o message.reserved2
        \o message.tradingStatus
        \o message.reserved1
        \o message.gthTradingStatus
        \o message.secondReserved1

DecodeTradingStatusMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    LET symbol == ReadBytes(timeOffset.rest, 6) IN IF ~symbol.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(symbol.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET tradingStatus == ReadBytes(reserved2.rest, 1) IN IF ~tradingStatus.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(tradingStatus.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET gthTradingStatus == ReadBytes(reserved1.rest, 1) IN IF ~gthTradingStatus.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(gthTradingStatus.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    Ok([ timeOffset       |-> timeOffset.value,
         symbol           |-> symbol.value,
         reserved2        |-> reserved2.value,
         tradingStatus    |-> tradingStatus.value,
         reserved1        |-> reserved1.value,
         gthTradingStatus |-> gthTradingStatus.value,
         secondReserved1  |-> secondReserved1.value ], secondReserved1.rest)

ZeroTradingStatusMessage ==
    [ timeOffset       |-> [i \in 1 .. 4 |-> 0],
      symbol           |-> [i \in 1 .. 6 |-> 0],
      reserved2        |-> [i \in 1 .. 2 |-> 0],
      tradingStatus    |-> [i \in 1 .. 1 |-> 0],
      reserved1        |-> [i \in 1 .. 1 |-> 0],
      gthTradingStatus |-> [i \in 1 .. 1 |-> 0],
      secondReserved1  |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingStatusMessage ==
    { ZeroTradingStatusMessage }
        \cup { [ZeroTradingStatusMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.symbol = one] : one \in Sample(6) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.tradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.gthTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingStatusMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* End Of Session Message: 4 bytes                                         *)
(***************************************************************************)

EndOfSessionMessage ==
    [ timeOffset : Sample(4) ]

EncodeEndOfSessionMessage(message) ==
    message.timeOffset

DecodeEndOfSessionMessage(bytes) ==
    LET timeOffset == ReadBytes(bytes, 4) IN IF ~timeOffset.ok THEN Fail ELSE
    Ok([ timeOffset |-> timeOffset.value ], timeOffset.rest)

ZeroEndOfSessionMessage ==
    [ timeOffset |-> [i \in 1 .. 4 |-> 0] ]

(* End Of Session Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfSessionMessage ==
    { ZeroEndOfSessionMessage }
        \cup { [ZeroEndOfSessionMessage EXCEPT !.timeOffset = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

TimeReferenceMessageCode == 177  \* 0xb1
TimeMessageCode == 32  \* 0x20
FlexInstrumentDefinitionMessageCode == 156  \* 0x9c
ComplexFlexInstrumentDefinitionMessageCode == 155  \* 0x9b
AuctionNotificationMessageCode == 173  \* 0xad
DacAuctionNotificationMessageCode == 221  \* 0xdd
AuctionCancelMessageCode == 174  \* 0xae
AuctionTradeMessageCode == 175  \* 0xaf
TradeLongMessageCode == 42  \* 0x2a
TradeShortMessageCode == 43  \* 0x2b
DacTradeMessageCode == 54  \* 0x36
TradeBreakMessageCode == 44  \* 0x2c
SymbolMappingMessageCode == 46  \* 0x2e
TradingStatusMessageCode == 49  \* 0x31
EndOfSessionMessageCode == 45  \* 0x2d

Payload ==
    [ tag : {TimeReferenceMessageCode}, body : TimeReferenceMessage ]
        \cup [ tag : {TimeMessageCode}, body : TimeMessage ]
        \cup [ tag : {FlexInstrumentDefinitionMessageCode}, body : FlexInstrumentDefinitionMessage ]
        \cup [ tag : {ComplexFlexInstrumentDefinitionMessageCode}, body : ComplexFlexInstrumentDefinitionMessage ]
        \cup [ tag : {AuctionNotificationMessageCode}, body : AuctionNotificationMessage ]
        \cup [ tag : {DacAuctionNotificationMessageCode}, body : DacAuctionNotificationMessage ]
        \cup [ tag : {AuctionCancelMessageCode}, body : AuctionCancelMessage ]
        \cup [ tag : {AuctionTradeMessageCode}, body : AuctionTradeMessage ]
        \cup [ tag : {TradeLongMessageCode}, body : TradeLongMessage ]
        \cup [ tag : {TradeShortMessageCode}, body : TradeShortMessage ]
        \cup [ tag : {DacTradeMessageCode}, body : DacTradeMessage ]
        \cup [ tag : {TradeBreakMessageCode}, body : TradeBreakMessage ]
        \cup [ tag : {SymbolMappingMessageCode}, body : SymbolMappingMessage ]
        \cup [ tag : {TradingStatusMessageCode}, body : TradingStatusMessage ]
        \cup [ tag : {EndOfSessionMessageCode}, body : EndOfSessionMessage ]

EncodePayload(message) ==
    CASE message.tag = TimeReferenceMessageCode -> EncodeTimeReferenceMessage(message.body)
      [] message.tag = TimeMessageCode -> EncodeTimeMessage(message.body)
      [] message.tag = FlexInstrumentDefinitionMessageCode -> EncodeFlexInstrumentDefinitionMessage(message.body)
      [] message.tag = ComplexFlexInstrumentDefinitionMessageCode -> EncodeComplexFlexInstrumentDefinitionMessage(message.body)
      [] message.tag = AuctionNotificationMessageCode -> EncodeAuctionNotificationMessage(message.body)
      [] message.tag = DacAuctionNotificationMessageCode -> EncodeDacAuctionNotificationMessage(message.body)
      [] message.tag = AuctionCancelMessageCode -> EncodeAuctionCancelMessage(message.body)
      [] message.tag = AuctionTradeMessageCode -> EncodeAuctionTradeMessage(message.body)
      [] message.tag = TradeLongMessageCode -> EncodeTradeLongMessage(message.body)
      [] message.tag = TradeShortMessageCode -> EncodeTradeShortMessage(message.body)
      [] message.tag = DacTradeMessageCode -> EncodeDacTradeMessage(message.body)
      [] message.tag = TradeBreakMessageCode -> EncodeTradeBreakMessage(message.body)
      [] message.tag = SymbolMappingMessageCode -> EncodeSymbolMappingMessage(message.body)
      [] message.tag = TradingStatusMessageCode -> EncodeTradingStatusMessage(message.body)
      [] message.tag = EndOfSessionMessageCode -> EncodeEndOfSessionMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = TimeReferenceMessageCode -> DecodeTimeReferenceMessage(bytes)
              [] tag = TimeMessageCode -> DecodeTimeMessage(bytes)
              [] tag = FlexInstrumentDefinitionMessageCode -> DecodeFlexInstrumentDefinitionMessage(bytes)
              [] tag = ComplexFlexInstrumentDefinitionMessageCode -> DecodeComplexFlexInstrumentDefinitionMessage(bytes)
              [] tag = AuctionNotificationMessageCode -> DecodeAuctionNotificationMessage(bytes)
              [] tag = DacAuctionNotificationMessageCode -> DecodeDacAuctionNotificationMessage(bytes)
              [] tag = AuctionCancelMessageCode -> DecodeAuctionCancelMessage(bytes)
              [] tag = AuctionTradeMessageCode -> DecodeAuctionTradeMessage(bytes)
              [] tag = TradeLongMessageCode -> DecodeTradeLongMessage(bytes)
              [] tag = TradeShortMessageCode -> DecodeTradeShortMessage(bytes)
              [] tag = DacTradeMessageCode -> DecodeDacTradeMessage(bytes)
              [] tag = TradeBreakMessageCode -> DecodeTradeBreakMessage(bytes)
              [] tag = SymbolMappingMessageCode -> DecodeSymbolMappingMessage(bytes)
              [] tag = TradingStatusMessageCode -> DecodeTradingStatusMessage(bytes)
              [] tag = EndOfSessionMessageCode -> DecodeEndOfSessionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> TimeReferenceMessageCode, body |-> ZeroTimeReferenceMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> TimeReferenceMessageCode, body |-> one] : one \in CheckedTimeReferenceMessage }
        \cup { [tag |-> TimeMessageCode, body |-> one] : one \in CheckedTimeMessage }
        \cup { [tag |-> FlexInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedFlexInstrumentDefinitionMessage }
        \cup { [tag |-> ComplexFlexInstrumentDefinitionMessageCode, body |-> one] : one \in CheckedComplexFlexInstrumentDefinitionMessage }
        \cup { [tag |-> AuctionNotificationMessageCode, body |-> one] : one \in CheckedAuctionNotificationMessage }
        \cup { [tag |-> DacAuctionNotificationMessageCode, body |-> one] : one \in CheckedDacAuctionNotificationMessage }
        \cup { [tag |-> AuctionCancelMessageCode, body |-> one] : one \in CheckedAuctionCancelMessage }
        \cup { [tag |-> AuctionTradeMessageCode, body |-> one] : one \in CheckedAuctionTradeMessage }
        \cup { [tag |-> TradeLongMessageCode, body |-> one] : one \in CheckedTradeLongMessage }
        \cup { [tag |-> TradeShortMessageCode, body |-> one] : one \in CheckedTradeShortMessage }
        \cup { [tag |-> DacTradeMessageCode, body |-> one] : one \in CheckedDacTradeMessage }
        \cup { [tag |-> TradeBreakMessageCode, body |-> one] : one \in CheckedTradeBreakMessage }
        \cup { [tag |-> SymbolMappingMessageCode, body |-> one] : one \in CheckedSymbolMappingMessage }
        \cup { [tag |-> TradingStatusMessageCode, body |-> one] : one \in CheckedTradingStatusMessage }
        \cup { [tag |-> EndOfSessionMessageCode, body |-> one] : one \in CheckedEndOfSessionMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 1, 1) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntLE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 1 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ payload |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.payload = one] : one \in CheckedPayload }

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
    { [ZeroMessage EXCEPT !.payload = [tag |-> TimeReferenceMessageCode, body |-> ZeroTimeReferenceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TimeMessageCode, body |-> ZeroTimeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FlexInstrumentDefinitionMessageCode, body |-> ZeroFlexInstrumentDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ComplexFlexInstrumentDefinitionMessageCode, body |-> ZeroComplexFlexInstrumentDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionNotificationMessageCode, body |-> ZeroAuctionNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DacAuctionNotificationMessageCode, body |-> ZeroDacAuctionNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionCancelMessageCode, body |-> ZeroAuctionCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionTradeMessageCode, body |-> ZeroAuctionTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeLongMessageCode, body |-> ZeroTradeLongMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeShortMessageCode, body |-> ZeroTradeShortMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DacTradeMessageCode, body |-> ZeroDacTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBreakMessageCode, body |-> ZeroTradeBreakMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SymbolMappingMessageCode, body |-> ZeroSymbolMappingMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingStatusMessageCode, body |-> ZeroTradingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndOfSessionMessageCode, body |-> ZeroEndOfSessionMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ length   : Sample(2),
      unit     : Sample(1),
      sequence : Sample(4),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.length
        \o EncodeUIntLE(Len(message.message), 1)
        \o message.unit
        \o message.sequence
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET length == ReadBytes(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET messageCount == ReadUIntLE(length.rest, 1) IN IF ~messageCount.ok THEN Fail ELSE
    LET unit == ReadBytes(messageCount.rest, 1) IN IF ~unit.ok THEN Fail ELSE
    LET sequence == ReadBytes(unit.rest, 4) IN IF ~sequence.ok THEN Fail ELSE
    LET message == ReadMessageList(sequence.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ length   |-> length.value,
         unit     |-> unit.value,
         sequence |-> sequence.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ length   |-> [i \in 1 .. 2 |-> 0],
      unit     |-> [i \in 1 .. 1 |-> 0],
      sequence |-> [i \in 1 .. 4 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.length = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.unit = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequence = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.message = one] : one \in SampleLists(OneMessage) }

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

(* Every Time Reference Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeReferenceMessage ==
    \A message \in CheckedTimeReferenceMessage :
        LET read == DecodeTimeReferenceMessage(EncodeTimeReferenceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeMessage ==
    \A message \in CheckedTimeMessage :
        LET read == DecodeTimeMessage(EncodeTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexInstrumentDefinitionMessage ==
    \A message \in CheckedFlexInstrumentDefinitionMessage :
        LET read == DecodeFlexInstrumentDefinitionMessage(EncodeFlexInstrumentDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Flex Leg decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexFlexLeg ==
    \A message \in CheckedComplexFlexLeg :
        LET read == DecodeComplexFlexLeg(EncodeComplexFlexLeg(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Flex Instrument Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexFlexInstrumentDefinitionMessage ==
    \A message \in CheckedComplexFlexInstrumentDefinitionMessage :
        LET read == DecodeComplexFlexInstrumentDefinitionMessage(EncodeComplexFlexInstrumentDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionNotificationMessage ==
    \A message \in CheckedAuctionNotificationMessage :
        LET read == DecodeAuctionNotificationMessage(EncodeAuctionNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dac Delta decodes back to what was encoded, and leaves nothing over *)
RoundTripDacDelta ==
    \A message \in CheckedDacDelta :
        LET read == DecodeDacDelta(EncodeDacDelta(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dac Auction Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDacAuctionNotificationMessage ==
    \A message \in CheckedDacAuctionNotificationMessage :
        LET read == DecodeDacAuctionNotificationMessage(EncodeDacAuctionNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionCancelMessage ==
    \A message \in CheckedAuctionCancelMessage :
        LET read == DecodeAuctionCancelMessage(EncodeAuctionCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionTradeMessage ==
    \A message \in CheckedAuctionTradeMessage :
        LET read == DecodeAuctionTradeMessage(EncodeAuctionTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Long Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeLongMessage ==
    \A message \in CheckedTradeLongMessage :
        LET read == DecodeTradeLongMessage(EncodeTradeLongMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Short Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeShortMessage ==
    \A message \in CheckedTradeShortMessage :
        LET read == DecodeTradeShortMessage(EncodeTradeShortMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dac Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDacTradeMessage ==
    \A message \in CheckedDacTradeMessage :
        LET read == DecodeDacTradeMessage(EncodeDacTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Break Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBreakMessage ==
    \A message \in CheckedTradeBreakMessage :
        LET read == DecodeTradeBreakMessage(EncodeTradeBreakMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Symbol Mapping Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSymbolMappingMessage ==
    \A message \in CheckedSymbolMappingMessage :
        LET read == DecodeSymbolMappingMessage(EncodeSymbolMappingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingStatusMessage ==
    \A message \in CheckedTradingStatusMessage :
        LET read == DecodeTradingStatusMessage(EncodeTradingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Session Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfSessionMessage ==
    \A message \in CheckedEndOfSessionMessage :
        LET read == DecodeEndOfSessionMessage(EncodeEndOfSessionMessage(message))
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

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 1)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
