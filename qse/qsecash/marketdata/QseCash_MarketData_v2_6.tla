---------------------- MODULE QseCash_MarketData_v2_6 ----------------------
(***************************************************************************)
(* Qatar Stock Exchange Qse Cash Market Data v2.6                          *)
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
(* Note: a Delivery Flag of any value but 17 says nothing transformed      *)
(* Message Buffer, which is then read as it stands.                        *)
(*                                                                         *)
(* Note: Message Buffer untransformed is as many Message as Number Msg     *)
(* Entries says, which is read beside the flag and handed to the choice:   *)
(* the count says how many the bytes hold, and transformed they hold a run *)
(* no reading of them states, so it is carried rather than written from    *)
(* the run.                                                                *)
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
(* Message Buffer                                                          *)
(***************************************************************************)

MessageBufferZlib ==
    [ transformed : SampleBytes ]

EncodeMessageBufferZlib(message) ==
    message.transformed

DecodeMessageBufferZlib(bytes) ==
    LET transformed == Ok(bytes, << >>) IN IF ~transformed.ok THEN Fail ELSE
    Ok([ transformed |-> transformed.value ], transformed.rest)

ZeroMessageBufferZlib ==
    [ transformed |-> << >> ]

(* Message Buffer at zero, then each field in turn at the values it is checked at *)
CheckedMessageBufferZlib ==
    { ZeroMessageBufferZlib }
        \cup { [ZeroMessageBufferZlib EXCEPT !.transformed = one] : one \in SampleBytes }

(***************************************************************************)
(* Stock State Change Message: 48 bytes                                    *)
(***************************************************************************)

StockStateChangeMessage ==
    [ symbolIndex             : Sample(4),
      sourceSeqNum            : Sample(4),
      sourceTime              : Sample(4),
      systemId                : Sample(4),
      sourceTimeMicroSecs     : Sample(2),
      fillerBinaryInt2        : Sample(2),
      startDateHalting        : Sample(8),
      startTimeHalting        : Sample(6),
      progOpeningTime         : Sample(6),
      orderEntryRejection     : Sample(1),
      instrumentState         : Sample(1),
      instrumentTradingStatus : Sample(1),
      haltReason              : Sample(1),
      actionAffectingState    : Sample(1),
      instrumentStateTcs      : Sample(1),
      periodSide              : Sample(1),
      fillerBinaryInt1        : Sample(1) ]

EncodeStockStateChangeMessage(message) ==
    message.symbolIndex
        \o message.sourceSeqNum
        \o message.sourceTime
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.fillerBinaryInt2
        \o message.startDateHalting
        \o message.startTimeHalting
        \o message.progOpeningTime
        \o message.orderEntryRejection
        \o message.instrumentState
        \o message.instrumentTradingStatus
        \o message.haltReason
        \o message.actionAffectingState
        \o message.instrumentStateTcs
        \o message.periodSide
        \o message.fillerBinaryInt1

DecodeStockStateChangeMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET systemId == ReadBytes(sourceTime.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET fillerBinaryInt2 == ReadBytes(sourceTimeMicroSecs.rest, 2) IN IF ~fillerBinaryInt2.ok THEN Fail ELSE
    LET startDateHalting == ReadBytes(fillerBinaryInt2.rest, 8) IN IF ~startDateHalting.ok THEN Fail ELSE
    LET startTimeHalting == ReadBytes(startDateHalting.rest, 6) IN IF ~startTimeHalting.ok THEN Fail ELSE
    LET progOpeningTime == ReadBytes(startTimeHalting.rest, 6) IN IF ~progOpeningTime.ok THEN Fail ELSE
    LET orderEntryRejection == ReadBytes(progOpeningTime.rest, 1) IN IF ~orderEntryRejection.ok THEN Fail ELSE
    LET instrumentState == ReadBytes(orderEntryRejection.rest, 1) IN IF ~instrumentState.ok THEN Fail ELSE
    LET instrumentTradingStatus == ReadBytes(instrumentState.rest, 1) IN IF ~instrumentTradingStatus.ok THEN Fail ELSE
    LET haltReason == ReadBytes(instrumentTradingStatus.rest, 1) IN IF ~haltReason.ok THEN Fail ELSE
    LET actionAffectingState == ReadBytes(haltReason.rest, 1) IN IF ~actionAffectingState.ok THEN Fail ELSE
    LET instrumentStateTcs == ReadBytes(actionAffectingState.rest, 1) IN IF ~instrumentStateTcs.ok THEN Fail ELSE
    LET periodSide == ReadBytes(instrumentStateTcs.rest, 1) IN IF ~periodSide.ok THEN Fail ELSE
    LET fillerBinaryInt1 == ReadBytes(periodSide.rest, 1) IN IF ~fillerBinaryInt1.ok THEN Fail ELSE
    Ok([ symbolIndex             |-> symbolIndex.value,
         sourceSeqNum            |-> sourceSeqNum.value,
         sourceTime              |-> sourceTime.value,
         systemId                |-> systemId.value,
         sourceTimeMicroSecs     |-> sourceTimeMicroSecs.value,
         fillerBinaryInt2        |-> fillerBinaryInt2.value,
         startDateHalting        |-> startDateHalting.value,
         startTimeHalting        |-> startTimeHalting.value,
         progOpeningTime         |-> progOpeningTime.value,
         orderEntryRejection     |-> orderEntryRejection.value,
         instrumentState         |-> instrumentState.value,
         instrumentTradingStatus |-> instrumentTradingStatus.value,
         haltReason              |-> haltReason.value,
         actionAffectingState    |-> actionAffectingState.value,
         instrumentStateTcs      |-> instrumentStateTcs.value,
         periodSide              |-> periodSide.value,
         fillerBinaryInt1        |-> fillerBinaryInt1.value ], fillerBinaryInt1.rest)

ZeroStockStateChangeMessage ==
    [ symbolIndex             |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum            |-> [i \in 1 .. 4 |-> 0],
      sourceTime              |-> [i \in 1 .. 4 |-> 0],
      systemId                |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs     |-> [i \in 1 .. 2 |-> 0],
      fillerBinaryInt2        |-> [i \in 1 .. 2 |-> 0],
      startDateHalting        |-> [i \in 1 .. 8 |-> 0],
      startTimeHalting        |-> [i \in 1 .. 6 |-> 0],
      progOpeningTime         |-> [i \in 1 .. 6 |-> 0],
      orderEntryRejection     |-> [i \in 1 .. 1 |-> 0],
      instrumentState         |-> [i \in 1 .. 1 |-> 0],
      instrumentTradingStatus |-> [i \in 1 .. 1 |-> 0],
      haltReason              |-> [i \in 1 .. 1 |-> 0],
      actionAffectingState    |-> [i \in 1 .. 1 |-> 0],
      instrumentStateTcs      |-> [i \in 1 .. 1 |-> 0],
      periodSide              |-> [i \in 1 .. 1 |-> 0],
      fillerBinaryInt1        |-> [i \in 1 .. 1 |-> 0] ]

(* Stock State Change Message at zero, then each field in turn at the values it is checked at *)
CheckedStockStateChangeMessage ==
    { ZeroStockStateChangeMessage }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.fillerBinaryInt2 = one] : one \in Sample(2) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.startDateHalting = one] : one \in Sample(8) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.startTimeHalting = one] : one \in Sample(6) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.progOpeningTime = one] : one \in Sample(6) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.orderEntryRejection = one] : one \in Sample(1) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.instrumentState = one] : one \in Sample(1) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.instrumentTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.haltReason = one] : one \in Sample(1) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.actionAffectingState = one] : one \in Sample(1) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.instrumentStateTcs = one] : one \in Sample(1) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.periodSide = one] : one \in Sample(1) }
        \cup { [ZeroStockStateChangeMessage EXCEPT !.fillerBinaryInt1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Class State Change Message: 24 bytes                                    *)
(***************************************************************************)

ClassStateChangeMessage ==
    [ sourceSeqNum         : Sample(4),
      sourceTime           : Sample(4),
      systemId             : Sample(4),
      sourceTimeMicroSecs  : Sample(2),
      instrumentGroupCode  : Sample(3),
      instrumentGroupState : Sample(1),
      sessionType          : Sample(1),
      fillerBinaryInt1     : Sample(1),
      classState           : Sample(4) ]

EncodeClassStateChangeMessage(message) ==
    message.sourceSeqNum
        \o message.sourceTime
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.instrumentGroupCode
        \o message.instrumentGroupState
        \o message.sessionType
        \o message.fillerBinaryInt1
        \o message.classState

DecodeClassStateChangeMessage(bytes) ==
    LET sourceSeqNum == ReadBytes(bytes, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET systemId == ReadBytes(sourceTime.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET instrumentGroupCode == ReadBytes(sourceTimeMicroSecs.rest, 3) IN IF ~instrumentGroupCode.ok THEN Fail ELSE
    LET instrumentGroupState == ReadBytes(instrumentGroupCode.rest, 1) IN IF ~instrumentGroupState.ok THEN Fail ELSE
    LET sessionType == ReadBytes(instrumentGroupState.rest, 1) IN IF ~sessionType.ok THEN Fail ELSE
    LET fillerBinaryInt1 == ReadBytes(sessionType.rest, 1) IN IF ~fillerBinaryInt1.ok THEN Fail ELSE
    LET classState == ReadBytes(fillerBinaryInt1.rest, 4) IN IF ~classState.ok THEN Fail ELSE
    Ok([ sourceSeqNum         |-> sourceSeqNum.value,
         sourceTime           |-> sourceTime.value,
         systemId             |-> systemId.value,
         sourceTimeMicroSecs  |-> sourceTimeMicroSecs.value,
         instrumentGroupCode  |-> instrumentGroupCode.value,
         instrumentGroupState |-> instrumentGroupState.value,
         sessionType          |-> sessionType.value,
         fillerBinaryInt1     |-> fillerBinaryInt1.value,
         classState           |-> classState.value ], classState.rest)

ZeroClassStateChangeMessage ==
    [ sourceSeqNum         |-> [i \in 1 .. 4 |-> 0],
      sourceTime           |-> [i \in 1 .. 4 |-> 0],
      systemId             |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs  |-> [i \in 1 .. 2 |-> 0],
      instrumentGroupCode  |-> [i \in 1 .. 3 |-> 0],
      instrumentGroupState |-> [i \in 1 .. 1 |-> 0],
      sessionType          |-> [i \in 1 .. 1 |-> 0],
      fillerBinaryInt1     |-> [i \in 1 .. 1 |-> 0],
      classState           |-> [i \in 1 .. 4 |-> 0] ]

(* Class State Change Message at zero, then each field in turn at the values it is checked at *)
CheckedClassStateChangeMessage ==
    { ZeroClassStateChangeMessage }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.instrumentGroupCode = one] : one \in Sample(3) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.instrumentGroupState = one] : one \in Sample(1) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.sessionType = one] : one \in Sample(1) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.fillerBinaryInt1 = one] : one \in Sample(1) }
        \cup { [ZeroClassStateChangeMessage EXCEPT !.classState = one] : one \in Sample(4) }

(***************************************************************************)
(* Mail Message: 964 bytes                                                 *)
(***************************************************************************)

MailMessage ==
    [ sourceSeqNum        : Sample(4),
      sourceTime          : Sample(4),
      systemId            : Sample(4),
      sourceTimeMicroSecs : Sample(2),
      eMailMsgNumber      : Sample(2),
      numberOfMessage     : Sample(2),
      sequenceNumber      : Sample(2),
      instrumentGroupCode : Sample(3),
      fillerAsciiStr1     : Sample(1),
      priorityIndicator   : Sample(1),
      typeOfMessage       : Sample(1),
      addressType         : Sample(2),
      title               : Sample(80),
      text                : Sample(854),
      fillerAsciiStr2     : Sample(2) ]

EncodeMailMessage(message) ==
    message.sourceSeqNum
        \o message.sourceTime
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.eMailMsgNumber
        \o message.numberOfMessage
        \o message.sequenceNumber
        \o message.instrumentGroupCode
        \o message.fillerAsciiStr1
        \o message.priorityIndicator
        \o message.typeOfMessage
        \o message.addressType
        \o message.title
        \o message.text
        \o message.fillerAsciiStr2

DecodeMailMessage(bytes) ==
    LET sourceSeqNum == ReadBytes(bytes, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET systemId == ReadBytes(sourceTime.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET eMailMsgNumber == ReadBytes(sourceTimeMicroSecs.rest, 2) IN IF ~eMailMsgNumber.ok THEN Fail ELSE
    LET numberOfMessage == ReadBytes(eMailMsgNumber.rest, 2) IN IF ~numberOfMessage.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(numberOfMessage.rest, 2) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET instrumentGroupCode == ReadBytes(sequenceNumber.rest, 3) IN IF ~instrumentGroupCode.ok THEN Fail ELSE
    LET fillerAsciiStr1 == ReadBytes(instrumentGroupCode.rest, 1) IN IF ~fillerAsciiStr1.ok THEN Fail ELSE
    LET priorityIndicator == ReadBytes(fillerAsciiStr1.rest, 1) IN IF ~priorityIndicator.ok THEN Fail ELSE
    LET typeOfMessage == ReadBytes(priorityIndicator.rest, 1) IN IF ~typeOfMessage.ok THEN Fail ELSE
    LET addressType == ReadBytes(typeOfMessage.rest, 2) IN IF ~addressType.ok THEN Fail ELSE
    LET title == ReadBytes(addressType.rest, 80) IN IF ~title.ok THEN Fail ELSE
    LET text == ReadBytes(title.rest, 854) IN IF ~text.ok THEN Fail ELSE
    LET fillerAsciiStr2 == ReadBytes(text.rest, 2) IN IF ~fillerAsciiStr2.ok THEN Fail ELSE
    Ok([ sourceSeqNum        |-> sourceSeqNum.value,
         sourceTime          |-> sourceTime.value,
         systemId            |-> systemId.value,
         sourceTimeMicroSecs |-> sourceTimeMicroSecs.value,
         eMailMsgNumber      |-> eMailMsgNumber.value,
         numberOfMessage     |-> numberOfMessage.value,
         sequenceNumber      |-> sequenceNumber.value,
         instrumentGroupCode |-> instrumentGroupCode.value,
         fillerAsciiStr1     |-> fillerAsciiStr1.value,
         priorityIndicator   |-> priorityIndicator.value,
         typeOfMessage       |-> typeOfMessage.value,
         addressType         |-> addressType.value,
         title               |-> title.value,
         text                |-> text.value,
         fillerAsciiStr2     |-> fillerAsciiStr2.value ], fillerAsciiStr2.rest)

ZeroMailMessage ==
    [ sourceSeqNum        |-> [i \in 1 .. 4 |-> 0],
      sourceTime          |-> [i \in 1 .. 4 |-> 0],
      systemId            |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs |-> [i \in 1 .. 2 |-> 0],
      eMailMsgNumber      |-> [i \in 1 .. 2 |-> 0],
      numberOfMessage     |-> [i \in 1 .. 2 |-> 0],
      sequenceNumber      |-> [i \in 1 .. 2 |-> 0],
      instrumentGroupCode |-> [i \in 1 .. 3 |-> 0],
      fillerAsciiStr1     |-> [i \in 1 .. 1 |-> 0],
      priorityIndicator   |-> [i \in 1 .. 1 |-> 0],
      typeOfMessage       |-> [i \in 1 .. 1 |-> 0],
      addressType         |-> [i \in 1 .. 2 |-> 0],
      title               |-> [i \in 1 .. 80 |-> 0],
      text                |-> [i \in 1 .. 854 |-> 0],
      fillerAsciiStr2     |-> [i \in 1 .. 2 |-> 0] ]

(* Mail Message at zero, then each field in turn at the values it is checked at *)
CheckedMailMessage ==
    { ZeroMailMessage }
        \cup { [ZeroMailMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMailMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroMailMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroMailMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroMailMessage EXCEPT !.eMailMsgNumber = one] : one \in Sample(2) }
        \cup { [ZeroMailMessage EXCEPT !.numberOfMessage = one] : one \in Sample(2) }
        \cup { [ZeroMailMessage EXCEPT !.sequenceNumber = one] : one \in Sample(2) }
        \cup { [ZeroMailMessage EXCEPT !.instrumentGroupCode = one] : one \in Sample(3) }
        \cup { [ZeroMailMessage EXCEPT !.fillerAsciiStr1 = one] : one \in Sample(1) }
        \cup { [ZeroMailMessage EXCEPT !.priorityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMailMessage EXCEPT !.typeOfMessage = one] : one \in Sample(1) }
        \cup { [ZeroMailMessage EXCEPT !.addressType = one] : one \in Sample(2) }
        \cup { [ZeroMailMessage EXCEPT !.title = one] : one \in Sample(80) }
        \cup { [ZeroMailMessage EXCEPT !.text = one] : one \in Sample(854) }
        \cup { [ZeroMailMessage EXCEPT !.fillerAsciiStr2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Indicative Matching Price Message: 32 bytes                             *)
(***************************************************************************)

IndicativeMatchingPriceMessage ==
    [ symbolIndex         : Sample(4),
      sourceSeqNum        : Sample(4),
      sourceTime          : Sample(4),
      imPrice             : Sample(4),
      variation           : Sample(4),
      systemId            : Sample(4),
      sourceTimeMicroSecs : Sample(2),
      priceScaleCode      : Sample(1),
      variationScaleCode  : Sample(1),
      imVolume            : Sample(4) ]

EncodeIndicativeMatchingPriceMessage(message) ==
    message.symbolIndex
        \o message.sourceSeqNum
        \o message.sourceTime
        \o message.imPrice
        \o message.variation
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.priceScaleCode
        \o message.variationScaleCode
        \o message.imVolume

DecodeIndicativeMatchingPriceMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET imPrice == ReadBytes(sourceTime.rest, 4) IN IF ~imPrice.ok THEN Fail ELSE
    LET variation == ReadBytes(imPrice.rest, 4) IN IF ~variation.ok THEN Fail ELSE
    LET systemId == ReadBytes(variation.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(sourceTimeMicroSecs.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET variationScaleCode == ReadBytes(priceScaleCode.rest, 1) IN IF ~variationScaleCode.ok THEN Fail ELSE
    LET imVolume == ReadBytes(variationScaleCode.rest, 4) IN IF ~imVolume.ok THEN Fail ELSE
    Ok([ symbolIndex         |-> symbolIndex.value,
         sourceSeqNum        |-> sourceSeqNum.value,
         sourceTime          |-> sourceTime.value,
         imPrice             |-> imPrice.value,
         variation           |-> variation.value,
         systemId            |-> systemId.value,
         sourceTimeMicroSecs |-> sourceTimeMicroSecs.value,
         priceScaleCode      |-> priceScaleCode.value,
         variationScaleCode  |-> variationScaleCode.value,
         imVolume            |-> imVolume.value ], imVolume.rest)

ZeroIndicativeMatchingPriceMessage ==
    [ symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum        |-> [i \in 1 .. 4 |-> 0],
      sourceTime          |-> [i \in 1 .. 4 |-> 0],
      imPrice             |-> [i \in 1 .. 4 |-> 0],
      variation           |-> [i \in 1 .. 4 |-> 0],
      systemId            |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs |-> [i \in 1 .. 2 |-> 0],
      priceScaleCode      |-> [i \in 1 .. 1 |-> 0],
      variationScaleCode  |-> [i \in 1 .. 1 |-> 0],
      imVolume            |-> [i \in 1 .. 4 |-> 0] ]

(* Indicative Matching Price Message at zero, then each field in turn at the values it is checked at *)
CheckedIndicativeMatchingPriceMessage ==
    { ZeroIndicativeMatchingPriceMessage }
        \cup { [ZeroIndicativeMatchingPriceMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroIndicativeMatchingPriceMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroIndicativeMatchingPriceMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroIndicativeMatchingPriceMessage EXCEPT !.imPrice = one] : one \in Sample(4) }
        \cup { [ZeroIndicativeMatchingPriceMessage EXCEPT !.variation = one] : one \in Sample(4) }
        \cup { [ZeroIndicativeMatchingPriceMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroIndicativeMatchingPriceMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroIndicativeMatchingPriceMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroIndicativeMatchingPriceMessage EXCEPT !.variationScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroIndicativeMatchingPriceMessage EXCEPT !.imVolume = one] : one \in Sample(4) }

(***************************************************************************)
(* Collars Message: 32 bytes                                               *)
(***************************************************************************)

CollarsMessage ==
    [ symbolIndex         : Sample(4),
      sourceSeqNum        : Sample(4),
      sourceTime          : Sample(4),
      highCollar          : Sample(4),
      lowCollar           : Sample(4),
      systemId            : Sample(4),
      sourceTimeMicroSecs : Sample(2),
      highScaleCode       : Sample(1),
      lowScaleCode        : Sample(1),
      collarType          : Sample(1),
      fillerAsciiStr3     : Sample(3) ]

EncodeCollarsMessage(message) ==
    message.symbolIndex
        \o message.sourceSeqNum
        \o message.sourceTime
        \o message.highCollar
        \o message.lowCollar
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.highScaleCode
        \o message.lowScaleCode
        \o message.collarType
        \o message.fillerAsciiStr3

DecodeCollarsMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET highCollar == ReadBytes(sourceTime.rest, 4) IN IF ~highCollar.ok THEN Fail ELSE
    LET lowCollar == ReadBytes(highCollar.rest, 4) IN IF ~lowCollar.ok THEN Fail ELSE
    LET systemId == ReadBytes(lowCollar.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET highScaleCode == ReadBytes(sourceTimeMicroSecs.rest, 1) IN IF ~highScaleCode.ok THEN Fail ELSE
    LET lowScaleCode == ReadBytes(highScaleCode.rest, 1) IN IF ~lowScaleCode.ok THEN Fail ELSE
    LET collarType == ReadBytes(lowScaleCode.rest, 1) IN IF ~collarType.ok THEN Fail ELSE
    LET fillerAsciiStr3 == ReadBytes(collarType.rest, 3) IN IF ~fillerAsciiStr3.ok THEN Fail ELSE
    Ok([ symbolIndex         |-> symbolIndex.value,
         sourceSeqNum        |-> sourceSeqNum.value,
         sourceTime          |-> sourceTime.value,
         highCollar          |-> highCollar.value,
         lowCollar           |-> lowCollar.value,
         systemId            |-> systemId.value,
         sourceTimeMicroSecs |-> sourceTimeMicroSecs.value,
         highScaleCode       |-> highScaleCode.value,
         lowScaleCode        |-> lowScaleCode.value,
         collarType          |-> collarType.value,
         fillerAsciiStr3     |-> fillerAsciiStr3.value ], fillerAsciiStr3.rest)

ZeroCollarsMessage ==
    [ symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum        |-> [i \in 1 .. 4 |-> 0],
      sourceTime          |-> [i \in 1 .. 4 |-> 0],
      highCollar          |-> [i \in 1 .. 4 |-> 0],
      lowCollar           |-> [i \in 1 .. 4 |-> 0],
      systemId            |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs |-> [i \in 1 .. 2 |-> 0],
      highScaleCode       |-> [i \in 1 .. 1 |-> 0],
      lowScaleCode        |-> [i \in 1 .. 1 |-> 0],
      collarType          |-> [i \in 1 .. 1 |-> 0],
      fillerAsciiStr3     |-> [i \in 1 .. 3 |-> 0] ]

(* Collars Message at zero, then each field in turn at the values it is checked at *)
CheckedCollarsMessage ==
    { ZeroCollarsMessage }
        \cup { [ZeroCollarsMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroCollarsMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroCollarsMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroCollarsMessage EXCEPT !.highCollar = one] : one \in Sample(4) }
        \cup { [ZeroCollarsMessage EXCEPT !.lowCollar = one] : one \in Sample(4) }
        \cup { [ZeroCollarsMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroCollarsMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroCollarsMessage EXCEPT !.highScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroCollarsMessage EXCEPT !.lowScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroCollarsMessage EXCEPT !.collarType = one] : one \in Sample(1) }
        \cup { [ZeroCollarsMessage EXCEPT !.fillerAsciiStr3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Session Timetable Message: 80 bytes                                     *)
(***************************************************************************)

SessionTimetableMessage ==
    [ sourceSeqNum        : Sample(4),
      sourceTime          : Sample(4),
      systemId            : Sample(4),
      sourceTimeMicroSecs : Sample(2),
      instrumentGroupCode : Sample(3),
      sessionType         : Sample(1),
      timePreOpening1     : Sample(6),
      timeOpening1        : Sample(6),
      timeClosing1        : Sample(6),
      timePreOpening2     : Sample(6),
      timeOpening2        : Sample(6),
      timeClosing2        : Sample(6),
      timePreOpening3     : Sample(6),
      timeOpening3        : Sample(6),
      timeClosing3        : Sample(6),
      eodTime             : Sample(6),
      fillerAsciiStr2     : Sample(2) ]

EncodeSessionTimetableMessage(message) ==
    message.sourceSeqNum
        \o message.sourceTime
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.instrumentGroupCode
        \o message.sessionType
        \o message.timePreOpening1
        \o message.timeOpening1
        \o message.timeClosing1
        \o message.timePreOpening2
        \o message.timeOpening2
        \o message.timeClosing2
        \o message.timePreOpening3
        \o message.timeOpening3
        \o message.timeClosing3
        \o message.eodTime
        \o message.fillerAsciiStr2

DecodeSessionTimetableMessage(bytes) ==
    LET sourceSeqNum == ReadBytes(bytes, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET systemId == ReadBytes(sourceTime.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET instrumentGroupCode == ReadBytes(sourceTimeMicroSecs.rest, 3) IN IF ~instrumentGroupCode.ok THEN Fail ELSE
    LET sessionType == ReadBytes(instrumentGroupCode.rest, 1) IN IF ~sessionType.ok THEN Fail ELSE
    LET timePreOpening1 == ReadBytes(sessionType.rest, 6) IN IF ~timePreOpening1.ok THEN Fail ELSE
    LET timeOpening1 == ReadBytes(timePreOpening1.rest, 6) IN IF ~timeOpening1.ok THEN Fail ELSE
    LET timeClosing1 == ReadBytes(timeOpening1.rest, 6) IN IF ~timeClosing1.ok THEN Fail ELSE
    LET timePreOpening2 == ReadBytes(timeClosing1.rest, 6) IN IF ~timePreOpening2.ok THEN Fail ELSE
    LET timeOpening2 == ReadBytes(timePreOpening2.rest, 6) IN IF ~timeOpening2.ok THEN Fail ELSE
    LET timeClosing2 == ReadBytes(timeOpening2.rest, 6) IN IF ~timeClosing2.ok THEN Fail ELSE
    LET timePreOpening3 == ReadBytes(timeClosing2.rest, 6) IN IF ~timePreOpening3.ok THEN Fail ELSE
    LET timeOpening3 == ReadBytes(timePreOpening3.rest, 6) IN IF ~timeOpening3.ok THEN Fail ELSE
    LET timeClosing3 == ReadBytes(timeOpening3.rest, 6) IN IF ~timeClosing3.ok THEN Fail ELSE
    LET eodTime == ReadBytes(timeClosing3.rest, 6) IN IF ~eodTime.ok THEN Fail ELSE
    LET fillerAsciiStr2 == ReadBytes(eodTime.rest, 2) IN IF ~fillerAsciiStr2.ok THEN Fail ELSE
    Ok([ sourceSeqNum        |-> sourceSeqNum.value,
         sourceTime          |-> sourceTime.value,
         systemId            |-> systemId.value,
         sourceTimeMicroSecs |-> sourceTimeMicroSecs.value,
         instrumentGroupCode |-> instrumentGroupCode.value,
         sessionType         |-> sessionType.value,
         timePreOpening1     |-> timePreOpening1.value,
         timeOpening1        |-> timeOpening1.value,
         timeClosing1        |-> timeClosing1.value,
         timePreOpening2     |-> timePreOpening2.value,
         timeOpening2        |-> timeOpening2.value,
         timeClosing2        |-> timeClosing2.value,
         timePreOpening3     |-> timePreOpening3.value,
         timeOpening3        |-> timeOpening3.value,
         timeClosing3        |-> timeClosing3.value,
         eodTime             |-> eodTime.value,
         fillerAsciiStr2     |-> fillerAsciiStr2.value ], fillerAsciiStr2.rest)

ZeroSessionTimetableMessage ==
    [ sourceSeqNum        |-> [i \in 1 .. 4 |-> 0],
      sourceTime          |-> [i \in 1 .. 4 |-> 0],
      systemId            |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs |-> [i \in 1 .. 2 |-> 0],
      instrumentGroupCode |-> [i \in 1 .. 3 |-> 0],
      sessionType         |-> [i \in 1 .. 1 |-> 0],
      timePreOpening1     |-> [i \in 1 .. 6 |-> 0],
      timeOpening1        |-> [i \in 1 .. 6 |-> 0],
      timeClosing1        |-> [i \in 1 .. 6 |-> 0],
      timePreOpening2     |-> [i \in 1 .. 6 |-> 0],
      timeOpening2        |-> [i \in 1 .. 6 |-> 0],
      timeClosing2        |-> [i \in 1 .. 6 |-> 0],
      timePreOpening3     |-> [i \in 1 .. 6 |-> 0],
      timeOpening3        |-> [i \in 1 .. 6 |-> 0],
      timeClosing3        |-> [i \in 1 .. 6 |-> 0],
      eodTime             |-> [i \in 1 .. 6 |-> 0],
      fillerAsciiStr2     |-> [i \in 1 .. 2 |-> 0] ]

(* Session Timetable Message at zero, then each field in turn at the values it is checked at *)
CheckedSessionTimetableMessage ==
    { ZeroSessionTimetableMessage }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.instrumentGroupCode = one] : one \in Sample(3) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.sessionType = one] : one \in Sample(1) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.timePreOpening1 = one] : one \in Sample(6) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.timeOpening1 = one] : one \in Sample(6) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.timeClosing1 = one] : one \in Sample(6) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.timePreOpening2 = one] : one \in Sample(6) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.timeOpening2 = one] : one \in Sample(6) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.timeClosing2 = one] : one \in Sample(6) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.timePreOpening3 = one] : one \in Sample(6) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.timeOpening3 = one] : one \in Sample(6) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.timeClosing3 = one] : one \in Sample(6) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.eodTime = one] : one \in Sample(6) }
        \cup { [ZeroSessionTimetableMessage EXCEPT !.fillerAsciiStr2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Global Market Activity Summary Message: 30 bytes                        *)
(***************************************************************************)

GlobalMarketActivitySummaryMessage ==
    [ sourceSeqNum        : Sample(4),
      sourceTime          : Sample(4),
      systemId            : Sample(4),
      sourceTimeMicroSecs : Sample(2),
      nbTrades            : Sample(4),
      qtyShares           : Sample(4),
      amountTraded        : Sample(4),
      priceScaleCode      : Sample(1),
      fillerAsciiStr3     : Sample(3) ]

EncodeGlobalMarketActivitySummaryMessage(message) ==
    message.sourceSeqNum
        \o message.sourceTime
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.nbTrades
        \o message.qtyShares
        \o message.amountTraded
        \o message.priceScaleCode
        \o message.fillerAsciiStr3

DecodeGlobalMarketActivitySummaryMessage(bytes) ==
    LET sourceSeqNum == ReadBytes(bytes, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET systemId == ReadBytes(sourceTime.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET nbTrades == ReadBytes(sourceTimeMicroSecs.rest, 4) IN IF ~nbTrades.ok THEN Fail ELSE
    LET qtyShares == ReadBytes(nbTrades.rest, 4) IN IF ~qtyShares.ok THEN Fail ELSE
    LET amountTraded == ReadBytes(qtyShares.rest, 4) IN IF ~amountTraded.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(amountTraded.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET fillerAsciiStr3 == ReadBytes(priceScaleCode.rest, 3) IN IF ~fillerAsciiStr3.ok THEN Fail ELSE
    Ok([ sourceSeqNum        |-> sourceSeqNum.value,
         sourceTime          |-> sourceTime.value,
         systemId            |-> systemId.value,
         sourceTimeMicroSecs |-> sourceTimeMicroSecs.value,
         nbTrades            |-> nbTrades.value,
         qtyShares           |-> qtyShares.value,
         amountTraded        |-> amountTraded.value,
         priceScaleCode      |-> priceScaleCode.value,
         fillerAsciiStr3     |-> fillerAsciiStr3.value ], fillerAsciiStr3.rest)

ZeroGlobalMarketActivitySummaryMessage ==
    [ sourceSeqNum        |-> [i \in 1 .. 4 |-> 0],
      sourceTime          |-> [i \in 1 .. 4 |-> 0],
      systemId            |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs |-> [i \in 1 .. 2 |-> 0],
      nbTrades            |-> [i \in 1 .. 4 |-> 0],
      qtyShares           |-> [i \in 1 .. 4 |-> 0],
      amountTraded        |-> [i \in 1 .. 4 |-> 0],
      priceScaleCode      |-> [i \in 1 .. 1 |-> 0],
      fillerAsciiStr3     |-> [i \in 1 .. 3 |-> 0] ]

(* Global Market Activity Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedGlobalMarketActivitySummaryMessage ==
    { ZeroGlobalMarketActivitySummaryMessage }
        \cup { [ZeroGlobalMarketActivitySummaryMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroGlobalMarketActivitySummaryMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroGlobalMarketActivitySummaryMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroGlobalMarketActivitySummaryMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroGlobalMarketActivitySummaryMessage EXCEPT !.nbTrades = one] : one \in Sample(4) }
        \cup { [ZeroGlobalMarketActivitySummaryMessage EXCEPT !.qtyShares = one] : one \in Sample(4) }
        \cup { [ZeroGlobalMarketActivitySummaryMessage EXCEPT !.amountTraded = one] : one \in Sample(4) }
        \cup { [ZeroGlobalMarketActivitySummaryMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroGlobalMarketActivitySummaryMessage EXCEPT !.fillerAsciiStr3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Start Referential Message: 4 bytes                                      *)
(***************************************************************************)

StartReferentialMessage ==
    [ indicator       : Sample(1),
      fillerAsciiStr3 : Sample(3) ]

EncodeStartReferentialMessage(message) ==
    message.indicator
        \o message.fillerAsciiStr3

DecodeStartReferentialMessage(bytes) ==
    LET indicator == ReadBytes(bytes, 1) IN IF ~indicator.ok THEN Fail ELSE
    LET fillerAsciiStr3 == ReadBytes(indicator.rest, 3) IN IF ~fillerAsciiStr3.ok THEN Fail ELSE
    Ok([ indicator       |-> indicator.value,
         fillerAsciiStr3 |-> fillerAsciiStr3.value ], fillerAsciiStr3.rest)

ZeroStartReferentialMessage ==
    [ indicator       |-> [i \in 1 .. 1 |-> 0],
      fillerAsciiStr3 |-> [i \in 1 .. 3 |-> 0] ]

(* Start Referential Message at zero, then each field in turn at the values it is checked at *)
CheckedStartReferentialMessage ==
    { ZeroStartReferentialMessage }
        \cup { [ZeroStartReferentialMessage EXCEPT !.indicator = one] : one \in Sample(1) }
        \cup { [ZeroStartReferentialMessage EXCEPT !.fillerAsciiStr3 = one] : one \in Sample(3) }

(***************************************************************************)
(* End Referential Message: 4 bytes                                        *)
(***************************************************************************)

EndReferentialMessage ==
    [ indicator       : Sample(1),
      fillerAsciiStr3 : Sample(3) ]

EncodeEndReferentialMessage(message) ==
    message.indicator
        \o message.fillerAsciiStr3

DecodeEndReferentialMessage(bytes) ==
    LET indicator == ReadBytes(bytes, 1) IN IF ~indicator.ok THEN Fail ELSE
    LET fillerAsciiStr3 == ReadBytes(indicator.rest, 3) IN IF ~fillerAsciiStr3.ok THEN Fail ELSE
    Ok([ indicator       |-> indicator.value,
         fillerAsciiStr3 |-> fillerAsciiStr3.value ], fillerAsciiStr3.rest)

ZeroEndReferentialMessage ==
    [ indicator       |-> [i \in 1 .. 1 |-> 0],
      fillerAsciiStr3 |-> [i \in 1 .. 3 |-> 0] ]

(* End Referential Message at zero, then each field in turn at the values it is checked at *)
CheckedEndReferentialMessage ==
    { ZeroEndReferentialMessage }
        \cup { [ZeroEndReferentialMessage EXCEPT !.indicator = one] : one \in Sample(1) }
        \cup { [ZeroEndReferentialMessage EXCEPT !.fillerAsciiStr3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Referential Message: 492 bytes                                          *)
(***************************************************************************)

ReferentialMessage ==
    [ symbolIndex                   : Sample(4),
      sourceSeqNum                  : Sample(4),
      sourceTime                    : Sample(4),
      lastAdjPrice                  : Sample(4),
      systemId                      : Sample(4),
      prevVolumeTraded              : Sample(4),
      fixPriceTick                  : Sample(4),
      sourceTimeMicroSecs           : Sample(2),
      stockExchangeCode             : Sample(2),
      typeOfInstrument              : Sample(2),
      eventDate                     : Sample(8),
      instrumentName                : Sample(18),
      periodIndicator               : Sample(1),
      typeOfMarketAdmission         : Sample(1),
      issuingCountryCode            : Sample(3),
      tradingCurrency               : Sample(3),
      instrumentGroupCode           : Sample(3),
      instrumentCategory            : Sample(1),
      instrumentCode                : Sample(12),
      dateOfLastTrade               : Sample(8),
      underlyingRepoIsinCode        : Sample(12),
      repoExpiryDate                : Sample(8),
      firstSettlementDate           : Sample(8),
      typeOfDerivatives             : Sample(1),
      bicDepositary                 : Sample(11),
      icb                           : Sample(4),
      mic                           : Sample(4),
      underlyingWisinCode           : Sample(12),
      depositaryList                : Sample(25),
      mainDepositary                : Sample(5),
      typeOfCorporateEvent          : Sample(2),
      timeLagEuronextUtc            : Sample(5),
      timeLagMiFidRegUtc            : Sample(5),
      cfi                           : Sample(6),
      quantityNotation              : Sample(4),
      indexSetOfVarPriceTick        : Sample(2),
      marketFeedCode                : Sample(2),
      micList                       : Sample(24),
      industryCode                  : Sample(4),
      industryText                  : Sample(100),
      financialMarketCode           : Sample(3),
      usIndicators                  : Sample(7),
      fillerAsciiStr2               : Sample(2),
      prevDayCapitalTraded          : Sample(8),
      nomMktPrice                   : Sample(8),
      lotSize                       : Sample(8),
      numberInstrumentCirc          : Sample(8),
      sharesOut                     : Sample(8),
      authShares                    : Sample(8),
      headingNumber                 : Sample(2),
      sectionNumber                 : Sample(1),
      repoIndicator                 : Sample(1),
      lastAdjPriceScaleCode         : Sample(1),
      typeOfUnitExp                 : Sample(1),
      marketIndicator               : Sample(1),
      prevDayCapitalTradedScaleCode : Sample(1),
      taxCode                       : Sample(1),
      nomMkdtPriceScaleCode         : Sample(1),
      lotSizeScaleCode              : Sample(1),
      fixPriceTickScaleCode         : Sample(1),
      mnemo                         : Sample(5),
      tradingCode                   : Sample(12),
      fillerAsciiStr3               : Sample(3),
      strikePrice                   : Sample(4),
      strikeCurrency                : Sample(3),
      strikeScaleCode               : Sample(1),
      currencyCoef                  : Sample(4),
      currencyCoefScaleCode         : Sample(1),
      tradingCurrencyIndicator      : Sample(1),
      strikeCurrencyIndicator       : Sample(1),
      marketSegment                 : Sample(2),
      algo                          : Sample(1),
      localName                     : Sample(30),
      smallTrade                    : Sample(4),
      fillerBinaryInt12             : Sample(12) ]

EncodeReferentialMessage(message) ==
    message.symbolIndex
        \o message.sourceSeqNum
        \o message.sourceTime
        \o message.lastAdjPrice
        \o message.systemId
        \o message.prevVolumeTraded
        \o message.fixPriceTick
        \o message.sourceTimeMicroSecs
        \o message.stockExchangeCode
        \o message.typeOfInstrument
        \o message.eventDate
        \o message.instrumentName
        \o message.periodIndicator
        \o message.typeOfMarketAdmission
        \o message.issuingCountryCode
        \o message.tradingCurrency
        \o message.instrumentGroupCode
        \o message.instrumentCategory
        \o message.instrumentCode
        \o message.dateOfLastTrade
        \o message.underlyingRepoIsinCode
        \o message.repoExpiryDate
        \o message.firstSettlementDate
        \o message.typeOfDerivatives
        \o message.bicDepositary
        \o message.icb
        \o message.mic
        \o message.underlyingWisinCode
        \o message.depositaryList
        \o message.mainDepositary
        \o message.typeOfCorporateEvent
        \o message.timeLagEuronextUtc
        \o message.timeLagMiFidRegUtc
        \o message.cfi
        \o message.quantityNotation
        \o message.indexSetOfVarPriceTick
        \o message.marketFeedCode
        \o message.micList
        \o message.industryCode
        \o message.industryText
        \o message.financialMarketCode
        \o message.usIndicators
        \o message.fillerAsciiStr2
        \o message.prevDayCapitalTraded
        \o message.nomMktPrice
        \o message.lotSize
        \o message.numberInstrumentCirc
        \o message.sharesOut
        \o message.authShares
        \o message.headingNumber
        \o message.sectionNumber
        \o message.repoIndicator
        \o message.lastAdjPriceScaleCode
        \o message.typeOfUnitExp
        \o message.marketIndicator
        \o message.prevDayCapitalTradedScaleCode
        \o message.taxCode
        \o message.nomMkdtPriceScaleCode
        \o message.lotSizeScaleCode
        \o message.fixPriceTickScaleCode
        \o message.mnemo
        \o message.tradingCode
        \o message.fillerAsciiStr3
        \o message.strikePrice
        \o message.strikeCurrency
        \o message.strikeScaleCode
        \o message.currencyCoef
        \o message.currencyCoefScaleCode
        \o message.tradingCurrencyIndicator
        \o message.strikeCurrencyIndicator
        \o message.marketSegment
        \o message.algo
        \o message.localName
        \o message.smallTrade
        \o message.fillerBinaryInt12

DecodeReferentialMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET lastAdjPrice == ReadBytes(sourceTime.rest, 4) IN IF ~lastAdjPrice.ok THEN Fail ELSE
    LET systemId == ReadBytes(lastAdjPrice.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET prevVolumeTraded == ReadBytes(systemId.rest, 4) IN IF ~prevVolumeTraded.ok THEN Fail ELSE
    LET fixPriceTick == ReadBytes(prevVolumeTraded.rest, 4) IN IF ~fixPriceTick.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(fixPriceTick.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET stockExchangeCode == ReadBytes(sourceTimeMicroSecs.rest, 2) IN IF ~stockExchangeCode.ok THEN Fail ELSE
    LET typeOfInstrument == ReadBytes(stockExchangeCode.rest, 2) IN IF ~typeOfInstrument.ok THEN Fail ELSE
    LET eventDate == ReadBytes(typeOfInstrument.rest, 8) IN IF ~eventDate.ok THEN Fail ELSE
    LET instrumentName == ReadBytes(eventDate.rest, 18) IN IF ~instrumentName.ok THEN Fail ELSE
    LET periodIndicator == ReadBytes(instrumentName.rest, 1) IN IF ~periodIndicator.ok THEN Fail ELSE
    LET typeOfMarketAdmission == ReadBytes(periodIndicator.rest, 1) IN IF ~typeOfMarketAdmission.ok THEN Fail ELSE
    LET issuingCountryCode == ReadBytes(typeOfMarketAdmission.rest, 3) IN IF ~issuingCountryCode.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(issuingCountryCode.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET instrumentGroupCode == ReadBytes(tradingCurrency.rest, 3) IN IF ~instrumentGroupCode.ok THEN Fail ELSE
    LET instrumentCategory == ReadBytes(instrumentGroupCode.rest, 1) IN IF ~instrumentCategory.ok THEN Fail ELSE
    LET instrumentCode == ReadBytes(instrumentCategory.rest, 12) IN IF ~instrumentCode.ok THEN Fail ELSE
    LET dateOfLastTrade == ReadBytes(instrumentCode.rest, 8) IN IF ~dateOfLastTrade.ok THEN Fail ELSE
    LET underlyingRepoIsinCode == ReadBytes(dateOfLastTrade.rest, 12) IN IF ~underlyingRepoIsinCode.ok THEN Fail ELSE
    LET repoExpiryDate == ReadBytes(underlyingRepoIsinCode.rest, 8) IN IF ~repoExpiryDate.ok THEN Fail ELSE
    LET firstSettlementDate == ReadBytes(repoExpiryDate.rest, 8) IN IF ~firstSettlementDate.ok THEN Fail ELSE
    LET typeOfDerivatives == ReadBytes(firstSettlementDate.rest, 1) IN IF ~typeOfDerivatives.ok THEN Fail ELSE
    LET bicDepositary == ReadBytes(typeOfDerivatives.rest, 11) IN IF ~bicDepositary.ok THEN Fail ELSE
    LET icb == ReadBytes(bicDepositary.rest, 4) IN IF ~icb.ok THEN Fail ELSE
    LET mic == ReadBytes(icb.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET underlyingWisinCode == ReadBytes(mic.rest, 12) IN IF ~underlyingWisinCode.ok THEN Fail ELSE
    LET depositaryList == ReadBytes(underlyingWisinCode.rest, 25) IN IF ~depositaryList.ok THEN Fail ELSE
    LET mainDepositary == ReadBytes(depositaryList.rest, 5) IN IF ~mainDepositary.ok THEN Fail ELSE
    LET typeOfCorporateEvent == ReadBytes(mainDepositary.rest, 2) IN IF ~typeOfCorporateEvent.ok THEN Fail ELSE
    LET timeLagEuronextUtc == ReadBytes(typeOfCorporateEvent.rest, 5) IN IF ~timeLagEuronextUtc.ok THEN Fail ELSE
    LET timeLagMiFidRegUtc == ReadBytes(timeLagEuronextUtc.rest, 5) IN IF ~timeLagMiFidRegUtc.ok THEN Fail ELSE
    LET cfi == ReadBytes(timeLagMiFidRegUtc.rest, 6) IN IF ~cfi.ok THEN Fail ELSE
    LET quantityNotation == ReadBytes(cfi.rest, 4) IN IF ~quantityNotation.ok THEN Fail ELSE
    LET indexSetOfVarPriceTick == ReadBytes(quantityNotation.rest, 2) IN IF ~indexSetOfVarPriceTick.ok THEN Fail ELSE
    LET marketFeedCode == ReadBytes(indexSetOfVarPriceTick.rest, 2) IN IF ~marketFeedCode.ok THEN Fail ELSE
    LET micList == ReadBytes(marketFeedCode.rest, 24) IN IF ~micList.ok THEN Fail ELSE
    LET industryCode == ReadBytes(micList.rest, 4) IN IF ~industryCode.ok THEN Fail ELSE
    LET industryText == ReadBytes(industryCode.rest, 100) IN IF ~industryText.ok THEN Fail ELSE
    LET financialMarketCode == ReadBytes(industryText.rest, 3) IN IF ~financialMarketCode.ok THEN Fail ELSE
    LET usIndicators == ReadBytes(financialMarketCode.rest, 7) IN IF ~usIndicators.ok THEN Fail ELSE
    LET fillerAsciiStr2 == ReadBytes(usIndicators.rest, 2) IN IF ~fillerAsciiStr2.ok THEN Fail ELSE
    LET prevDayCapitalTraded == ReadBytes(fillerAsciiStr2.rest, 8) IN IF ~prevDayCapitalTraded.ok THEN Fail ELSE
    LET nomMktPrice == ReadBytes(prevDayCapitalTraded.rest, 8) IN IF ~nomMktPrice.ok THEN Fail ELSE
    LET lotSize == ReadBytes(nomMktPrice.rest, 8) IN IF ~lotSize.ok THEN Fail ELSE
    LET numberInstrumentCirc == ReadBytes(lotSize.rest, 8) IN IF ~numberInstrumentCirc.ok THEN Fail ELSE
    LET sharesOut == ReadBytes(numberInstrumentCirc.rest, 8) IN IF ~sharesOut.ok THEN Fail ELSE
    LET authShares == ReadBytes(sharesOut.rest, 8) IN IF ~authShares.ok THEN Fail ELSE
    LET headingNumber == ReadBytes(authShares.rest, 2) IN IF ~headingNumber.ok THEN Fail ELSE
    LET sectionNumber == ReadBytes(headingNumber.rest, 1) IN IF ~sectionNumber.ok THEN Fail ELSE
    LET repoIndicator == ReadBytes(sectionNumber.rest, 1) IN IF ~repoIndicator.ok THEN Fail ELSE
    LET lastAdjPriceScaleCode == ReadBytes(repoIndicator.rest, 1) IN IF ~lastAdjPriceScaleCode.ok THEN Fail ELSE
    LET typeOfUnitExp == ReadBytes(lastAdjPriceScaleCode.rest, 1) IN IF ~typeOfUnitExp.ok THEN Fail ELSE
    LET marketIndicator == ReadBytes(typeOfUnitExp.rest, 1) IN IF ~marketIndicator.ok THEN Fail ELSE
    LET prevDayCapitalTradedScaleCode == ReadBytes(marketIndicator.rest, 1) IN IF ~prevDayCapitalTradedScaleCode.ok THEN Fail ELSE
    LET taxCode == ReadBytes(prevDayCapitalTradedScaleCode.rest, 1) IN IF ~taxCode.ok THEN Fail ELSE
    LET nomMkdtPriceScaleCode == ReadBytes(taxCode.rest, 1) IN IF ~nomMkdtPriceScaleCode.ok THEN Fail ELSE
    LET lotSizeScaleCode == ReadBytes(nomMkdtPriceScaleCode.rest, 1) IN IF ~lotSizeScaleCode.ok THEN Fail ELSE
    LET fixPriceTickScaleCode == ReadBytes(lotSizeScaleCode.rest, 1) IN IF ~fixPriceTickScaleCode.ok THEN Fail ELSE
    LET mnemo == ReadBytes(fixPriceTickScaleCode.rest, 5) IN IF ~mnemo.ok THEN Fail ELSE
    LET tradingCode == ReadBytes(mnemo.rest, 12) IN IF ~tradingCode.ok THEN Fail ELSE
    LET fillerAsciiStr3 == ReadBytes(tradingCode.rest, 3) IN IF ~fillerAsciiStr3.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(fillerAsciiStr3.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikeCurrency == ReadBytes(strikePrice.rest, 3) IN IF ~strikeCurrency.ok THEN Fail ELSE
    LET strikeScaleCode == ReadBytes(strikeCurrency.rest, 1) IN IF ~strikeScaleCode.ok THEN Fail ELSE
    LET currencyCoef == ReadBytes(strikeScaleCode.rest, 4) IN IF ~currencyCoef.ok THEN Fail ELSE
    LET currencyCoefScaleCode == ReadBytes(currencyCoef.rest, 1) IN IF ~currencyCoefScaleCode.ok THEN Fail ELSE
    LET tradingCurrencyIndicator == ReadBytes(currencyCoefScaleCode.rest, 1) IN IF ~tradingCurrencyIndicator.ok THEN Fail ELSE
    LET strikeCurrencyIndicator == ReadBytes(tradingCurrencyIndicator.rest, 1) IN IF ~strikeCurrencyIndicator.ok THEN Fail ELSE
    LET marketSegment == ReadBytes(strikeCurrencyIndicator.rest, 2) IN IF ~marketSegment.ok THEN Fail ELSE
    LET algo == ReadBytes(marketSegment.rest, 1) IN IF ~algo.ok THEN Fail ELSE
    LET localName == ReadBytes(algo.rest, 30) IN IF ~localName.ok THEN Fail ELSE
    LET smallTrade == ReadBytes(localName.rest, 4) IN IF ~smallTrade.ok THEN Fail ELSE
    LET fillerBinaryInt12 == ReadBytes(smallTrade.rest, 12) IN IF ~fillerBinaryInt12.ok THEN Fail ELSE
    Ok([ symbolIndex                   |-> symbolIndex.value,
         sourceSeqNum                  |-> sourceSeqNum.value,
         sourceTime                    |-> sourceTime.value,
         lastAdjPrice                  |-> lastAdjPrice.value,
         systemId                      |-> systemId.value,
         prevVolumeTraded              |-> prevVolumeTraded.value,
         fixPriceTick                  |-> fixPriceTick.value,
         sourceTimeMicroSecs           |-> sourceTimeMicroSecs.value,
         stockExchangeCode             |-> stockExchangeCode.value,
         typeOfInstrument              |-> typeOfInstrument.value,
         eventDate                     |-> eventDate.value,
         instrumentName                |-> instrumentName.value,
         periodIndicator               |-> periodIndicator.value,
         typeOfMarketAdmission         |-> typeOfMarketAdmission.value,
         issuingCountryCode            |-> issuingCountryCode.value,
         tradingCurrency               |-> tradingCurrency.value,
         instrumentGroupCode           |-> instrumentGroupCode.value,
         instrumentCategory            |-> instrumentCategory.value,
         instrumentCode                |-> instrumentCode.value,
         dateOfLastTrade               |-> dateOfLastTrade.value,
         underlyingRepoIsinCode        |-> underlyingRepoIsinCode.value,
         repoExpiryDate                |-> repoExpiryDate.value,
         firstSettlementDate           |-> firstSettlementDate.value,
         typeOfDerivatives             |-> typeOfDerivatives.value,
         bicDepositary                 |-> bicDepositary.value,
         icb                           |-> icb.value,
         mic                           |-> mic.value,
         underlyingWisinCode           |-> underlyingWisinCode.value,
         depositaryList                |-> depositaryList.value,
         mainDepositary                |-> mainDepositary.value,
         typeOfCorporateEvent          |-> typeOfCorporateEvent.value,
         timeLagEuronextUtc            |-> timeLagEuronextUtc.value,
         timeLagMiFidRegUtc            |-> timeLagMiFidRegUtc.value,
         cfi                           |-> cfi.value,
         quantityNotation              |-> quantityNotation.value,
         indexSetOfVarPriceTick        |-> indexSetOfVarPriceTick.value,
         marketFeedCode                |-> marketFeedCode.value,
         micList                       |-> micList.value,
         industryCode                  |-> industryCode.value,
         industryText                  |-> industryText.value,
         financialMarketCode           |-> financialMarketCode.value,
         usIndicators                  |-> usIndicators.value,
         fillerAsciiStr2               |-> fillerAsciiStr2.value,
         prevDayCapitalTraded          |-> prevDayCapitalTraded.value,
         nomMktPrice                   |-> nomMktPrice.value,
         lotSize                       |-> lotSize.value,
         numberInstrumentCirc          |-> numberInstrumentCirc.value,
         sharesOut                     |-> sharesOut.value,
         authShares                    |-> authShares.value,
         headingNumber                 |-> headingNumber.value,
         sectionNumber                 |-> sectionNumber.value,
         repoIndicator                 |-> repoIndicator.value,
         lastAdjPriceScaleCode         |-> lastAdjPriceScaleCode.value,
         typeOfUnitExp                 |-> typeOfUnitExp.value,
         marketIndicator               |-> marketIndicator.value,
         prevDayCapitalTradedScaleCode |-> prevDayCapitalTradedScaleCode.value,
         taxCode                       |-> taxCode.value,
         nomMkdtPriceScaleCode         |-> nomMkdtPriceScaleCode.value,
         lotSizeScaleCode              |-> lotSizeScaleCode.value,
         fixPriceTickScaleCode         |-> fixPriceTickScaleCode.value,
         mnemo                         |-> mnemo.value,
         tradingCode                   |-> tradingCode.value,
         fillerAsciiStr3               |-> fillerAsciiStr3.value,
         strikePrice                   |-> strikePrice.value,
         strikeCurrency                |-> strikeCurrency.value,
         strikeScaleCode               |-> strikeScaleCode.value,
         currencyCoef                  |-> currencyCoef.value,
         currencyCoefScaleCode         |-> currencyCoefScaleCode.value,
         tradingCurrencyIndicator      |-> tradingCurrencyIndicator.value,
         strikeCurrencyIndicator       |-> strikeCurrencyIndicator.value,
         marketSegment                 |-> marketSegment.value,
         algo                          |-> algo.value,
         localName                     |-> localName.value,
         smallTrade                    |-> smallTrade.value,
         fillerBinaryInt12             |-> fillerBinaryInt12.value ], fillerBinaryInt12.rest)

ZeroReferentialMessage ==
    [ symbolIndex                   |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum                  |-> [i \in 1 .. 4 |-> 0],
      sourceTime                    |-> [i \in 1 .. 4 |-> 0],
      lastAdjPrice                  |-> [i \in 1 .. 4 |-> 0],
      systemId                      |-> [i \in 1 .. 4 |-> 0],
      prevVolumeTraded              |-> [i \in 1 .. 4 |-> 0],
      fixPriceTick                  |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs           |-> [i \in 1 .. 2 |-> 0],
      stockExchangeCode             |-> [i \in 1 .. 2 |-> 0],
      typeOfInstrument              |-> [i \in 1 .. 2 |-> 0],
      eventDate                     |-> [i \in 1 .. 8 |-> 0],
      instrumentName                |-> [i \in 1 .. 18 |-> 0],
      periodIndicator               |-> [i \in 1 .. 1 |-> 0],
      typeOfMarketAdmission         |-> [i \in 1 .. 1 |-> 0],
      issuingCountryCode            |-> [i \in 1 .. 3 |-> 0],
      tradingCurrency               |-> [i \in 1 .. 3 |-> 0],
      instrumentGroupCode           |-> [i \in 1 .. 3 |-> 0],
      instrumentCategory            |-> [i \in 1 .. 1 |-> 0],
      instrumentCode                |-> [i \in 1 .. 12 |-> 0],
      dateOfLastTrade               |-> [i \in 1 .. 8 |-> 0],
      underlyingRepoIsinCode        |-> [i \in 1 .. 12 |-> 0],
      repoExpiryDate                |-> [i \in 1 .. 8 |-> 0],
      firstSettlementDate           |-> [i \in 1 .. 8 |-> 0],
      typeOfDerivatives             |-> [i \in 1 .. 1 |-> 0],
      bicDepositary                 |-> [i \in 1 .. 11 |-> 0],
      icb                           |-> [i \in 1 .. 4 |-> 0],
      mic                           |-> [i \in 1 .. 4 |-> 0],
      underlyingWisinCode           |-> [i \in 1 .. 12 |-> 0],
      depositaryList                |-> [i \in 1 .. 25 |-> 0],
      mainDepositary                |-> [i \in 1 .. 5 |-> 0],
      typeOfCorporateEvent          |-> [i \in 1 .. 2 |-> 0],
      timeLagEuronextUtc            |-> [i \in 1 .. 5 |-> 0],
      timeLagMiFidRegUtc            |-> [i \in 1 .. 5 |-> 0],
      cfi                           |-> [i \in 1 .. 6 |-> 0],
      quantityNotation              |-> [i \in 1 .. 4 |-> 0],
      indexSetOfVarPriceTick        |-> [i \in 1 .. 2 |-> 0],
      marketFeedCode                |-> [i \in 1 .. 2 |-> 0],
      micList                       |-> [i \in 1 .. 24 |-> 0],
      industryCode                  |-> [i \in 1 .. 4 |-> 0],
      industryText                  |-> [i \in 1 .. 100 |-> 0],
      financialMarketCode           |-> [i \in 1 .. 3 |-> 0],
      usIndicators                  |-> [i \in 1 .. 7 |-> 0],
      fillerAsciiStr2               |-> [i \in 1 .. 2 |-> 0],
      prevDayCapitalTraded          |-> [i \in 1 .. 8 |-> 0],
      nomMktPrice                   |-> [i \in 1 .. 8 |-> 0],
      lotSize                       |-> [i \in 1 .. 8 |-> 0],
      numberInstrumentCirc          |-> [i \in 1 .. 8 |-> 0],
      sharesOut                     |-> [i \in 1 .. 8 |-> 0],
      authShares                    |-> [i \in 1 .. 8 |-> 0],
      headingNumber                 |-> [i \in 1 .. 2 |-> 0],
      sectionNumber                 |-> [i \in 1 .. 1 |-> 0],
      repoIndicator                 |-> [i \in 1 .. 1 |-> 0],
      lastAdjPriceScaleCode         |-> [i \in 1 .. 1 |-> 0],
      typeOfUnitExp                 |-> [i \in 1 .. 1 |-> 0],
      marketIndicator               |-> [i \in 1 .. 1 |-> 0],
      prevDayCapitalTradedScaleCode |-> [i \in 1 .. 1 |-> 0],
      taxCode                       |-> [i \in 1 .. 1 |-> 0],
      nomMkdtPriceScaleCode         |-> [i \in 1 .. 1 |-> 0],
      lotSizeScaleCode              |-> [i \in 1 .. 1 |-> 0],
      fixPriceTickScaleCode         |-> [i \in 1 .. 1 |-> 0],
      mnemo                         |-> [i \in 1 .. 5 |-> 0],
      tradingCode                   |-> [i \in 1 .. 12 |-> 0],
      fillerAsciiStr3               |-> [i \in 1 .. 3 |-> 0],
      strikePrice                   |-> [i \in 1 .. 4 |-> 0],
      strikeCurrency                |-> [i \in 1 .. 3 |-> 0],
      strikeScaleCode               |-> [i \in 1 .. 1 |-> 0],
      currencyCoef                  |-> [i \in 1 .. 4 |-> 0],
      currencyCoefScaleCode         |-> [i \in 1 .. 1 |-> 0],
      tradingCurrencyIndicator      |-> [i \in 1 .. 1 |-> 0],
      strikeCurrencyIndicator       |-> [i \in 1 .. 1 |-> 0],
      marketSegment                 |-> [i \in 1 .. 2 |-> 0],
      algo                          |-> [i \in 1 .. 1 |-> 0],
      localName                     |-> [i \in 1 .. 30 |-> 0],
      smallTrade                    |-> [i \in 1 .. 4 |-> 0],
      fillerBinaryInt12             |-> [i \in 1 .. 12 |-> 0] ]

(* Referential Message at zero, then each field in turn at the values it is checked at *)
CheckedReferentialMessage ==
    { ZeroReferentialMessage }
        \cup { [ZeroReferentialMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.lastAdjPrice = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.prevVolumeTraded = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.fixPriceTick = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.stockExchangeCode = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.typeOfInstrument = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.eventDate = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.instrumentName = one] : one \in Sample(18) }
        \cup { [ZeroReferentialMessage EXCEPT !.periodIndicator = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.typeOfMarketAdmission = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.issuingCountryCode = one] : one \in Sample(3) }
        \cup { [ZeroReferentialMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroReferentialMessage EXCEPT !.instrumentGroupCode = one] : one \in Sample(3) }
        \cup { [ZeroReferentialMessage EXCEPT !.instrumentCategory = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.instrumentCode = one] : one \in Sample(12) }
        \cup { [ZeroReferentialMessage EXCEPT !.dateOfLastTrade = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.underlyingRepoIsinCode = one] : one \in Sample(12) }
        \cup { [ZeroReferentialMessage EXCEPT !.repoExpiryDate = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.firstSettlementDate = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.typeOfDerivatives = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.bicDepositary = one] : one \in Sample(11) }
        \cup { [ZeroReferentialMessage EXCEPT !.icb = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.underlyingWisinCode = one] : one \in Sample(12) }
        \cup { [ZeroReferentialMessage EXCEPT !.depositaryList = one] : one \in Sample(25) }
        \cup { [ZeroReferentialMessage EXCEPT !.mainDepositary = one] : one \in Sample(5) }
        \cup { [ZeroReferentialMessage EXCEPT !.typeOfCorporateEvent = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.timeLagEuronextUtc = one] : one \in Sample(5) }
        \cup { [ZeroReferentialMessage EXCEPT !.timeLagMiFidRegUtc = one] : one \in Sample(5) }
        \cup { [ZeroReferentialMessage EXCEPT !.cfi = one] : one \in Sample(6) }
        \cup { [ZeroReferentialMessage EXCEPT !.quantityNotation = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.indexSetOfVarPriceTick = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.marketFeedCode = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.micList = one] : one \in Sample(24) }
        \cup { [ZeroReferentialMessage EXCEPT !.industryCode = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.industryText = one] : one \in Sample(100) }
        \cup { [ZeroReferentialMessage EXCEPT !.financialMarketCode = one] : one \in Sample(3) }
        \cup { [ZeroReferentialMessage EXCEPT !.usIndicators = one] : one \in Sample(7) }
        \cup { [ZeroReferentialMessage EXCEPT !.fillerAsciiStr2 = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.prevDayCapitalTraded = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.nomMktPrice = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.lotSize = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.numberInstrumentCirc = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.sharesOut = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.authShares = one] : one \in Sample(8) }
        \cup { [ZeroReferentialMessage EXCEPT !.headingNumber = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.sectionNumber = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.repoIndicator = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.lastAdjPriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.typeOfUnitExp = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.marketIndicator = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.prevDayCapitalTradedScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.taxCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.nomMkdtPriceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.lotSizeScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.fixPriceTickScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.mnemo = one] : one \in Sample(5) }
        \cup { [ZeroReferentialMessage EXCEPT !.tradingCode = one] : one \in Sample(12) }
        \cup { [ZeroReferentialMessage EXCEPT !.fillerAsciiStr3 = one] : one \in Sample(3) }
        \cup { [ZeroReferentialMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.strikeCurrency = one] : one \in Sample(3) }
        \cup { [ZeroReferentialMessage EXCEPT !.strikeScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.currencyCoef = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.currencyCoefScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.tradingCurrencyIndicator = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.strikeCurrencyIndicator = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.marketSegment = one] : one \in Sample(2) }
        \cup { [ZeroReferentialMessage EXCEPT !.algo = one] : one \in Sample(1) }
        \cup { [ZeroReferentialMessage EXCEPT !.localName = one] : one \in Sample(30) }
        \cup { [ZeroReferentialMessage EXCEPT !.smallTrade = one] : one \in Sample(4) }
        \cup { [ZeroReferentialMessage EXCEPT !.fillerBinaryInt12 = one] : one \in Sample(12) }

(***************************************************************************)
(* Trade Creation Message: 40 bytes                                        *)
(***************************************************************************)

TradeCreationMessage ==
    [ symbolIndex           : Sample(4),
      sourceTime            : Sample(4),
      tradeIdNumber         : Sample(4),
      quoteLinkId           : Sample(4),
      sourceSeqNum          : Sample(4),
      price                 : Sample(4),
      volume                : Sample(4),
      systemId              : Sample(4),
      sourceTimeMicroSecs   : Sample(2),
      smallTradeIndicator   : Sample(1),
      tradCond2             : Sample(1),
      tradCond3             : Sample(1),
      tradeOrigin           : Sample(1),
      openingTradeIndicator : Sample(1),
      priceScaleCode        : Sample(1) ]

EncodeTradeCreationMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.tradeIdNumber
        \o message.quoteLinkId
        \o message.sourceSeqNum
        \o message.price
        \o message.volume
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.smallTradeIndicator
        \o message.tradCond2
        \o message.tradCond3
        \o message.tradeOrigin
        \o message.openingTradeIndicator
        \o message.priceScaleCode

DecodeTradeCreationMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET tradeIdNumber == ReadBytes(sourceTime.rest, 4) IN IF ~tradeIdNumber.ok THEN Fail ELSE
    LET quoteLinkId == ReadBytes(tradeIdNumber.rest, 4) IN IF ~quoteLinkId.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(quoteLinkId.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET price == ReadBytes(sourceSeqNum.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET systemId == ReadBytes(volume.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET smallTradeIndicator == ReadBytes(sourceTimeMicroSecs.rest, 1) IN IF ~smallTradeIndicator.ok THEN Fail ELSE
    LET tradCond2 == ReadBytes(smallTradeIndicator.rest, 1) IN IF ~tradCond2.ok THEN Fail ELSE
    LET tradCond3 == ReadBytes(tradCond2.rest, 1) IN IF ~tradCond3.ok THEN Fail ELSE
    LET tradeOrigin == ReadBytes(tradCond3.rest, 1) IN IF ~tradeOrigin.ok THEN Fail ELSE
    LET openingTradeIndicator == ReadBytes(tradeOrigin.rest, 1) IN IF ~openingTradeIndicator.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(openingTradeIndicator.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    Ok([ symbolIndex           |-> symbolIndex.value,
         sourceTime            |-> sourceTime.value,
         tradeIdNumber         |-> tradeIdNumber.value,
         quoteLinkId           |-> quoteLinkId.value,
         sourceSeqNum          |-> sourceSeqNum.value,
         price                 |-> price.value,
         volume                |-> volume.value,
         systemId              |-> systemId.value,
         sourceTimeMicroSecs   |-> sourceTimeMicroSecs.value,
         smallTradeIndicator   |-> smallTradeIndicator.value,
         tradCond2             |-> tradCond2.value,
         tradCond3             |-> tradCond3.value,
         tradeOrigin           |-> tradeOrigin.value,
         openingTradeIndicator |-> openingTradeIndicator.value,
         priceScaleCode        |-> priceScaleCode.value ], priceScaleCode.rest)

ZeroTradeCreationMessage ==
    [ symbolIndex           |-> [i \in 1 .. 4 |-> 0],
      sourceTime            |-> [i \in 1 .. 4 |-> 0],
      tradeIdNumber         |-> [i \in 1 .. 4 |-> 0],
      quoteLinkId           |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum          |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      systemId              |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs   |-> [i \in 1 .. 2 |-> 0],
      smallTradeIndicator   |-> [i \in 1 .. 1 |-> 0],
      tradCond2             |-> [i \in 1 .. 1 |-> 0],
      tradCond3             |-> [i \in 1 .. 1 |-> 0],
      tradeOrigin           |-> [i \in 1 .. 1 |-> 0],
      openingTradeIndicator |-> [i \in 1 .. 1 |-> 0],
      priceScaleCode        |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Creation Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCreationMessage ==
    { ZeroTradeCreationMessage }
        \cup { [ZeroTradeCreationMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroTradeCreationMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroTradeCreationMessage EXCEPT !.tradeIdNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeCreationMessage EXCEPT !.quoteLinkId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCreationMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroTradeCreationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeCreationMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCreationMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCreationMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroTradeCreationMessage EXCEPT !.smallTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCreationMessage EXCEPT !.tradCond2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCreationMessage EXCEPT !.tradCond3 = one] : one \in Sample(1) }
        \cup { [ZeroTradeCreationMessage EXCEPT !.tradeOrigin = one] : one \in Sample(1) }
        \cup { [ZeroTradeCreationMessage EXCEPT !.openingTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCreationMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Cancellation Message: 24 bytes                                    *)
(***************************************************************************)

TradeCancellationMessage ==
    [ symbolIndex           : Sample(4),
      sourceTime            : Sample(4),
      sourceSeqNum          : Sample(4),
      originalTradeIdNumber : Sample(4),
      systemId              : Sample(4),
      sourceTimeMicroSecs   : Sample(2),
      fillerBinaryInt2      : Sample(2) ]

EncodeTradeCancellationMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.sourceSeqNum
        \o message.originalTradeIdNumber
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.fillerBinaryInt2

DecodeTradeCancellationMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET originalTradeIdNumber == ReadBytes(sourceSeqNum.rest, 4) IN IF ~originalTradeIdNumber.ok THEN Fail ELSE
    LET systemId == ReadBytes(originalTradeIdNumber.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET fillerBinaryInt2 == ReadBytes(sourceTimeMicroSecs.rest, 2) IN IF ~fillerBinaryInt2.ok THEN Fail ELSE
    Ok([ symbolIndex           |-> symbolIndex.value,
         sourceTime            |-> sourceTime.value,
         sourceSeqNum          |-> sourceSeqNum.value,
         originalTradeIdNumber |-> originalTradeIdNumber.value,
         systemId              |-> systemId.value,
         sourceTimeMicroSecs   |-> sourceTimeMicroSecs.value,
         fillerBinaryInt2      |-> fillerBinaryInt2.value ], fillerBinaryInt2.rest)

ZeroTradeCancellationMessage ==
    [ symbolIndex           |-> [i \in 1 .. 4 |-> 0],
      sourceTime            |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum          |-> [i \in 1 .. 4 |-> 0],
      originalTradeIdNumber |-> [i \in 1 .. 4 |-> 0],
      systemId              |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs   |-> [i \in 1 .. 2 |-> 0],
      fillerBinaryInt2      |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancellationMessage ==
    { ZeroTradeCancellationMessage }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.originalTradeIdNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancellationMessage EXCEPT !.fillerBinaryInt2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Full Information Message: 60 bytes                                *)
(***************************************************************************)

TradeFullInformationMessage ==
    [ symbolIndex           : Sample(4),
      sourceTime            : Sample(4),
      tradeIdNumber         : Sample(4),
      quoteLinkId           : Sample(4),
      sourceSeqNum          : Sample(4),
      price                 : Sample(4),
      volume                : Sample(4),
      cumulativeQuantity    : Sample(4),
      highestPrice          : Sample(4),
      lowestPrice           : Sample(4),
      variationLastPrice    : Sample(4),
      systemId              : Sample(4),
      sourceTimeMicroSecs   : Sample(2),
      fillerBinaryInt2      : Sample(2),
      smallTradeIndicator   : Sample(1),
      tradCond2             : Sample(1),
      tradCond3             : Sample(1),
      tradeOrigin           : Sample(1),
      tickDirection         : Sample(1),
      openingTradeIndicator : Sample(1),
      variationScaleCode    : Sample(1),
      priceScaleCode        : Sample(1) ]

EncodeTradeFullInformationMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.tradeIdNumber
        \o message.quoteLinkId
        \o message.sourceSeqNum
        \o message.price
        \o message.volume
        \o message.cumulativeQuantity
        \o message.highestPrice
        \o message.lowestPrice
        \o message.variationLastPrice
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.fillerBinaryInt2
        \o message.smallTradeIndicator
        \o message.tradCond2
        \o message.tradCond3
        \o message.tradeOrigin
        \o message.tickDirection
        \o message.openingTradeIndicator
        \o message.variationScaleCode
        \o message.priceScaleCode

DecodeTradeFullInformationMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET tradeIdNumber == ReadBytes(sourceTime.rest, 4) IN IF ~tradeIdNumber.ok THEN Fail ELSE
    LET quoteLinkId == ReadBytes(tradeIdNumber.rest, 4) IN IF ~quoteLinkId.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(quoteLinkId.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET price == ReadBytes(sourceSeqNum.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET cumulativeQuantity == ReadBytes(volume.rest, 4) IN IF ~cumulativeQuantity.ok THEN Fail ELSE
    LET highestPrice == ReadBytes(cumulativeQuantity.rest, 4) IN IF ~highestPrice.ok THEN Fail ELSE
    LET lowestPrice == ReadBytes(highestPrice.rest, 4) IN IF ~lowestPrice.ok THEN Fail ELSE
    LET variationLastPrice == ReadBytes(lowestPrice.rest, 4) IN IF ~variationLastPrice.ok THEN Fail ELSE
    LET systemId == ReadBytes(variationLastPrice.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET fillerBinaryInt2 == ReadBytes(sourceTimeMicroSecs.rest, 2) IN IF ~fillerBinaryInt2.ok THEN Fail ELSE
    LET smallTradeIndicator == ReadBytes(fillerBinaryInt2.rest, 1) IN IF ~smallTradeIndicator.ok THEN Fail ELSE
    LET tradCond2 == ReadBytes(smallTradeIndicator.rest, 1) IN IF ~tradCond2.ok THEN Fail ELSE
    LET tradCond3 == ReadBytes(tradCond2.rest, 1) IN IF ~tradCond3.ok THEN Fail ELSE
    LET tradeOrigin == ReadBytes(tradCond3.rest, 1) IN IF ~tradeOrigin.ok THEN Fail ELSE
    LET tickDirection == ReadBytes(tradeOrigin.rest, 1) IN IF ~tickDirection.ok THEN Fail ELSE
    LET openingTradeIndicator == ReadBytes(tickDirection.rest, 1) IN IF ~openingTradeIndicator.ok THEN Fail ELSE
    LET variationScaleCode == ReadBytes(openingTradeIndicator.rest, 1) IN IF ~variationScaleCode.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(variationScaleCode.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    Ok([ symbolIndex           |-> symbolIndex.value,
         sourceTime            |-> sourceTime.value,
         tradeIdNumber         |-> tradeIdNumber.value,
         quoteLinkId           |-> quoteLinkId.value,
         sourceSeqNum          |-> sourceSeqNum.value,
         price                 |-> price.value,
         volume                |-> volume.value,
         cumulativeQuantity    |-> cumulativeQuantity.value,
         highestPrice          |-> highestPrice.value,
         lowestPrice           |-> lowestPrice.value,
         variationLastPrice    |-> variationLastPrice.value,
         systemId              |-> systemId.value,
         sourceTimeMicroSecs   |-> sourceTimeMicroSecs.value,
         fillerBinaryInt2      |-> fillerBinaryInt2.value,
         smallTradeIndicator   |-> smallTradeIndicator.value,
         tradCond2             |-> tradCond2.value,
         tradCond3             |-> tradCond3.value,
         tradeOrigin           |-> tradeOrigin.value,
         tickDirection         |-> tickDirection.value,
         openingTradeIndicator |-> openingTradeIndicator.value,
         variationScaleCode    |-> variationScaleCode.value,
         priceScaleCode        |-> priceScaleCode.value ], priceScaleCode.rest)

ZeroTradeFullInformationMessage ==
    [ symbolIndex           |-> [i \in 1 .. 4 |-> 0],
      sourceTime            |-> [i \in 1 .. 4 |-> 0],
      tradeIdNumber         |-> [i \in 1 .. 4 |-> 0],
      quoteLinkId           |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum          |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      cumulativeQuantity    |-> [i \in 1 .. 4 |-> 0],
      highestPrice          |-> [i \in 1 .. 4 |-> 0],
      lowestPrice           |-> [i \in 1 .. 4 |-> 0],
      variationLastPrice    |-> [i \in 1 .. 4 |-> 0],
      systemId              |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs   |-> [i \in 1 .. 2 |-> 0],
      fillerBinaryInt2      |-> [i \in 1 .. 2 |-> 0],
      smallTradeIndicator   |-> [i \in 1 .. 1 |-> 0],
      tradCond2             |-> [i \in 1 .. 1 |-> 0],
      tradCond3             |-> [i \in 1 .. 1 |-> 0],
      tradeOrigin           |-> [i \in 1 .. 1 |-> 0],
      tickDirection         |-> [i \in 1 .. 1 |-> 0],
      openingTradeIndicator |-> [i \in 1 .. 1 |-> 0],
      variationScaleCode    |-> [i \in 1 .. 1 |-> 0],
      priceScaleCode        |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Full Information Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeFullInformationMessage ==
    { ZeroTradeFullInformationMessage }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.tradeIdNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.quoteLinkId = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.cumulativeQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.highestPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.lowestPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.variationLastPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.fillerBinaryInt2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.smallTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.tradCond2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.tradCond3 = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.tradeOrigin = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.tickDirection = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.openingTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.variationScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeFullInformationMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Price Update Message: 40 bytes                                          *)
(***************************************************************************)

PriceUpdateMessage ==
    [ symbolIndex         : Sample(4),
      sourceTime          : Sample(4),
      sourceSeqNum        : Sample(4),
      price               : Sample(4),
      highestPrice        : Sample(4),
      lowestPrice         : Sample(4),
      variationLastPrice  : Sample(4),
      systemId            : Sample(4),
      sourceTimeMicroSecs : Sample(2),
      typeOfPrice         : Sample(2),
      fillerBinaryInt2    : Sample(2),
      priceScaleCode      : Sample(1),
      variationScaleCode  : Sample(1) ]

EncodePriceUpdateMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.sourceSeqNum
        \o message.price
        \o message.highestPrice
        \o message.lowestPrice
        \o message.variationLastPrice
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.typeOfPrice
        \o message.fillerBinaryInt2
        \o message.priceScaleCode
        \o message.variationScaleCode

DecodePriceUpdateMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET price == ReadBytes(sourceSeqNum.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET highestPrice == ReadBytes(price.rest, 4) IN IF ~highestPrice.ok THEN Fail ELSE
    LET lowestPrice == ReadBytes(highestPrice.rest, 4) IN IF ~lowestPrice.ok THEN Fail ELSE
    LET variationLastPrice == ReadBytes(lowestPrice.rest, 4) IN IF ~variationLastPrice.ok THEN Fail ELSE
    LET systemId == ReadBytes(variationLastPrice.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET typeOfPrice == ReadBytes(sourceTimeMicroSecs.rest, 2) IN IF ~typeOfPrice.ok THEN Fail ELSE
    LET fillerBinaryInt2 == ReadBytes(typeOfPrice.rest, 2) IN IF ~fillerBinaryInt2.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(fillerBinaryInt2.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET variationScaleCode == ReadBytes(priceScaleCode.rest, 1) IN IF ~variationScaleCode.ok THEN Fail ELSE
    Ok([ symbolIndex         |-> symbolIndex.value,
         sourceTime          |-> sourceTime.value,
         sourceSeqNum        |-> sourceSeqNum.value,
         price               |-> price.value,
         highestPrice        |-> highestPrice.value,
         lowestPrice         |-> lowestPrice.value,
         variationLastPrice  |-> variationLastPrice.value,
         systemId            |-> systemId.value,
         sourceTimeMicroSecs |-> sourceTimeMicroSecs.value,
         typeOfPrice         |-> typeOfPrice.value,
         fillerBinaryInt2    |-> fillerBinaryInt2.value,
         priceScaleCode      |-> priceScaleCode.value,
         variationScaleCode  |-> variationScaleCode.value ], variationScaleCode.rest)

ZeroPriceUpdateMessage ==
    [ symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      sourceTime          |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum        |-> [i \in 1 .. 4 |-> 0],
      price               |-> [i \in 1 .. 4 |-> 0],
      highestPrice        |-> [i \in 1 .. 4 |-> 0],
      lowestPrice         |-> [i \in 1 .. 4 |-> 0],
      variationLastPrice  |-> [i \in 1 .. 4 |-> 0],
      systemId            |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs |-> [i \in 1 .. 2 |-> 0],
      typeOfPrice         |-> [i \in 1 .. 2 |-> 0],
      fillerBinaryInt2    |-> [i \in 1 .. 2 |-> 0],
      priceScaleCode      |-> [i \in 1 .. 1 |-> 0],
      variationScaleCode  |-> [i \in 1 .. 1 |-> 0] ]

(* Price Update Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceUpdateMessage ==
    { ZeroPriceUpdateMessage }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.highestPrice = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.lowestPrice = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.variationLastPrice = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.typeOfPrice = one] : one \in Sample(2) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.fillerBinaryInt2 = one] : one \in Sample(2) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroPriceUpdateMessage EXCEPT !.variationScaleCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Auction Summary Message: 48 bytes                                       *)
(***************************************************************************)

AuctionSummaryMessage ==
    [ symbolIndex              : Sample(4),
      sourceTime               : Sample(4),
      sourceSeqNum             : Sample(4),
      firstPrice               : Sample(4),
      lastPrice                : Sample(4),
      highestPrice             : Sample(4),
      lowestPrice              : Sample(4),
      cumulativeQuantity       : Sample(4),
      variation                : Sample(4),
      systemId                 : Sample(4),
      sourceTimeMicroSecs      : Sample(2),
      typeOfLastPrice          : Sample(2),
      tickDirection            : Sample(1),
      instrumentValuationPrice : Sample(1),
      priceScaleCode           : Sample(1),
      variationScaleCode       : Sample(1) ]

EncodeAuctionSummaryMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.sourceSeqNum
        \o message.firstPrice
        \o message.lastPrice
        \o message.highestPrice
        \o message.lowestPrice
        \o message.cumulativeQuantity
        \o message.variation
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.typeOfLastPrice
        \o message.tickDirection
        \o message.instrumentValuationPrice
        \o message.priceScaleCode
        \o message.variationScaleCode

DecodeAuctionSummaryMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET firstPrice == ReadBytes(sourceSeqNum.rest, 4) IN IF ~firstPrice.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(firstPrice.rest, 4) IN IF ~lastPrice.ok THEN Fail ELSE
    LET highestPrice == ReadBytes(lastPrice.rest, 4) IN IF ~highestPrice.ok THEN Fail ELSE
    LET lowestPrice == ReadBytes(highestPrice.rest, 4) IN IF ~lowestPrice.ok THEN Fail ELSE
    LET cumulativeQuantity == ReadBytes(lowestPrice.rest, 4) IN IF ~cumulativeQuantity.ok THEN Fail ELSE
    LET variation == ReadBytes(cumulativeQuantity.rest, 4) IN IF ~variation.ok THEN Fail ELSE
    LET systemId == ReadBytes(variation.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET typeOfLastPrice == ReadBytes(sourceTimeMicroSecs.rest, 2) IN IF ~typeOfLastPrice.ok THEN Fail ELSE
    LET tickDirection == ReadBytes(typeOfLastPrice.rest, 1) IN IF ~tickDirection.ok THEN Fail ELSE
    LET instrumentValuationPrice == ReadBytes(tickDirection.rest, 1) IN IF ~instrumentValuationPrice.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(instrumentValuationPrice.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET variationScaleCode == ReadBytes(priceScaleCode.rest, 1) IN IF ~variationScaleCode.ok THEN Fail ELSE
    Ok([ symbolIndex              |-> symbolIndex.value,
         sourceTime               |-> sourceTime.value,
         sourceSeqNum             |-> sourceSeqNum.value,
         firstPrice               |-> firstPrice.value,
         lastPrice                |-> lastPrice.value,
         highestPrice             |-> highestPrice.value,
         lowestPrice              |-> lowestPrice.value,
         cumulativeQuantity       |-> cumulativeQuantity.value,
         variation                |-> variation.value,
         systemId                 |-> systemId.value,
         sourceTimeMicroSecs      |-> sourceTimeMicroSecs.value,
         typeOfLastPrice          |-> typeOfLastPrice.value,
         tickDirection            |-> tickDirection.value,
         instrumentValuationPrice |-> instrumentValuationPrice.value,
         priceScaleCode           |-> priceScaleCode.value,
         variationScaleCode       |-> variationScaleCode.value ], variationScaleCode.rest)

ZeroAuctionSummaryMessage ==
    [ symbolIndex              |-> [i \in 1 .. 4 |-> 0],
      sourceTime               |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum             |-> [i \in 1 .. 4 |-> 0],
      firstPrice               |-> [i \in 1 .. 4 |-> 0],
      lastPrice                |-> [i \in 1 .. 4 |-> 0],
      highestPrice             |-> [i \in 1 .. 4 |-> 0],
      lowestPrice              |-> [i \in 1 .. 4 |-> 0],
      cumulativeQuantity       |-> [i \in 1 .. 4 |-> 0],
      variation                |-> [i \in 1 .. 4 |-> 0],
      systemId                 |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs      |-> [i \in 1 .. 2 |-> 0],
      typeOfLastPrice          |-> [i \in 1 .. 2 |-> 0],
      tickDirection            |-> [i \in 1 .. 1 |-> 0],
      instrumentValuationPrice |-> [i \in 1 .. 1 |-> 0],
      priceScaleCode           |-> [i \in 1 .. 1 |-> 0],
      variationScaleCode       |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionSummaryMessage ==
    { ZeroAuctionSummaryMessage }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.firstPrice = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.lastPrice = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.highestPrice = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.lowestPrice = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.cumulativeQuantity = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.variation = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.typeOfLastPrice = one] : one \in Sample(2) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.tickDirection = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.instrumentValuationPrice = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroAuctionSummaryMessage EXCEPT !.variationScaleCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Vwap Closing Price Message: 44 bytes                                    *)
(***************************************************************************)

VwapClosingPriceMessage ==
    [ symbolIndex          : Sample(4),
      sourceTime           : Sample(4),
      sourceSeqNum         : Sample(4),
      sendingIndicator     : Sample(2),
      closingPriceRule     : Sample(2),
      closingPrice         : Sample(4),
      adjustedClosingPrice : Sample(4),
      nbTrades             : Sample(4),
      qtyShares            : Sample(4),
      amountTraded         : Sample(4),
      systemId             : Sample(4),
      priceScaleCode       : Sample(1),
      fillerAsciiStr3      : Sample(3) ]

EncodeVwapClosingPriceMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.sourceSeqNum
        \o message.sendingIndicator
        \o message.closingPriceRule
        \o message.closingPrice
        \o message.adjustedClosingPrice
        \o message.nbTrades
        \o message.qtyShares
        \o message.amountTraded
        \o message.systemId
        \o message.priceScaleCode
        \o message.fillerAsciiStr3

DecodeVwapClosingPriceMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sendingIndicator == ReadBytes(sourceSeqNum.rest, 2) IN IF ~sendingIndicator.ok THEN Fail ELSE
    LET closingPriceRule == ReadBytes(sendingIndicator.rest, 2) IN IF ~closingPriceRule.ok THEN Fail ELSE
    LET closingPrice == ReadBytes(closingPriceRule.rest, 4) IN IF ~closingPrice.ok THEN Fail ELSE
    LET adjustedClosingPrice == ReadBytes(closingPrice.rest, 4) IN IF ~adjustedClosingPrice.ok THEN Fail ELSE
    LET nbTrades == ReadBytes(adjustedClosingPrice.rest, 4) IN IF ~nbTrades.ok THEN Fail ELSE
    LET qtyShares == ReadBytes(nbTrades.rest, 4) IN IF ~qtyShares.ok THEN Fail ELSE
    LET amountTraded == ReadBytes(qtyShares.rest, 4) IN IF ~amountTraded.ok THEN Fail ELSE
    LET systemId == ReadBytes(amountTraded.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(systemId.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET fillerAsciiStr3 == ReadBytes(priceScaleCode.rest, 3) IN IF ~fillerAsciiStr3.ok THEN Fail ELSE
    Ok([ symbolIndex          |-> symbolIndex.value,
         sourceTime           |-> sourceTime.value,
         sourceSeqNum         |-> sourceSeqNum.value,
         sendingIndicator     |-> sendingIndicator.value,
         closingPriceRule     |-> closingPriceRule.value,
         closingPrice         |-> closingPrice.value,
         adjustedClosingPrice |-> adjustedClosingPrice.value,
         nbTrades             |-> nbTrades.value,
         qtyShares            |-> qtyShares.value,
         amountTraded         |-> amountTraded.value,
         systemId             |-> systemId.value,
         priceScaleCode       |-> priceScaleCode.value,
         fillerAsciiStr3      |-> fillerAsciiStr3.value ], fillerAsciiStr3.rest)

ZeroVwapClosingPriceMessage ==
    [ symbolIndex          |-> [i \in 1 .. 4 |-> 0],
      sourceTime           |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum         |-> [i \in 1 .. 4 |-> 0],
      sendingIndicator     |-> [i \in 1 .. 2 |-> 0],
      closingPriceRule     |-> [i \in 1 .. 2 |-> 0],
      closingPrice         |-> [i \in 1 .. 4 |-> 0],
      adjustedClosingPrice |-> [i \in 1 .. 4 |-> 0],
      nbTrades             |-> [i \in 1 .. 4 |-> 0],
      qtyShares            |-> [i \in 1 .. 4 |-> 0],
      amountTraded         |-> [i \in 1 .. 4 |-> 0],
      systemId             |-> [i \in 1 .. 4 |-> 0],
      priceScaleCode       |-> [i \in 1 .. 1 |-> 0],
      fillerAsciiStr3      |-> [i \in 1 .. 3 |-> 0] ]

(* Vwap Closing Price Message at zero, then each field in turn at the values it is checked at *)
CheckedVwapClosingPriceMessage ==
    { ZeroVwapClosingPriceMessage }
        \cup { [ZeroVwapClosingPriceMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroVwapClosingPriceMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroVwapClosingPriceMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroVwapClosingPriceMessage EXCEPT !.sendingIndicator = one] : one \in Sample(2) }
        \cup { [ZeroVwapClosingPriceMessage EXCEPT !.closingPriceRule = one] : one \in Sample(2) }
        \cup { [ZeroVwapClosingPriceMessage EXCEPT !.closingPrice = one] : one \in Sample(4) }
        \cup { [ZeroVwapClosingPriceMessage EXCEPT !.adjustedClosingPrice = one] : one \in Sample(4) }
        \cup { [ZeroVwapClosingPriceMessage EXCEPT !.nbTrades = one] : one \in Sample(4) }
        \cup { [ZeroVwapClosingPriceMessage EXCEPT !.qtyShares = one] : one \in Sample(4) }
        \cup { [ZeroVwapClosingPriceMessage EXCEPT !.amountTraded = one] : one \in Sample(4) }
        \cup { [ZeroVwapClosingPriceMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroVwapClosingPriceMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroVwapClosingPriceMessage EXCEPT !.fillerAsciiStr3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Quotes Message: 48 bytes                                                *)
(***************************************************************************)

QuotesMessage ==
    [ symbolIndex         : Sample(4),
      sourceSeqNum        : Sample(4),
      sourceTime          : Sample(4),
      quoteLinkId         : Sample(4),
      askPrice            : Sample(4),
      askSize             : Sample(4),
      bidPrice            : Sample(4),
      bidSize             : Sample(4),
      systemId            : Sample(4),
      numberAskOrders     : Sample(2),
      numberBidOrders     : Sample(2),
      sourceTimeMicroSecs : Sample(2),
      typeOfAskPrice      : Sample(1),
      typeOfBidPrice      : Sample(1),
      quoteCondition      : Sample(1),
      quoteNumber         : Sample(1),
      priceScaleCode      : Sample(1),
      fillerAsciiStr1     : Sample(1) ]

EncodeQuotesMessage(message) ==
    message.symbolIndex
        \o message.sourceSeqNum
        \o message.sourceTime
        \o message.quoteLinkId
        \o message.askPrice
        \o message.askSize
        \o message.bidPrice
        \o message.bidSize
        \o message.systemId
        \o message.numberAskOrders
        \o message.numberBidOrders
        \o message.sourceTimeMicroSecs
        \o message.typeOfAskPrice
        \o message.typeOfBidPrice
        \o message.quoteCondition
        \o message.quoteNumber
        \o message.priceScaleCode
        \o message.fillerAsciiStr1

DecodeQuotesMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(sourceSeqNum.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET quoteLinkId == ReadBytes(sourceTime.rest, 4) IN IF ~quoteLinkId.ok THEN Fail ELSE
    LET askPrice == ReadBytes(quoteLinkId.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET askSize == ReadBytes(askPrice.rest, 4) IN IF ~askSize.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(askSize.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET bidSize == ReadBytes(bidPrice.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET systemId == ReadBytes(bidSize.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET numberAskOrders == ReadBytes(systemId.rest, 2) IN IF ~numberAskOrders.ok THEN Fail ELSE
    LET numberBidOrders == ReadBytes(numberAskOrders.rest, 2) IN IF ~numberBidOrders.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(numberBidOrders.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET typeOfAskPrice == ReadBytes(sourceTimeMicroSecs.rest, 1) IN IF ~typeOfAskPrice.ok THEN Fail ELSE
    LET typeOfBidPrice == ReadBytes(typeOfAskPrice.rest, 1) IN IF ~typeOfBidPrice.ok THEN Fail ELSE
    LET quoteCondition == ReadBytes(typeOfBidPrice.rest, 1) IN IF ~quoteCondition.ok THEN Fail ELSE
    LET quoteNumber == ReadBytes(quoteCondition.rest, 1) IN IF ~quoteNumber.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(quoteNumber.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET fillerAsciiStr1 == ReadBytes(priceScaleCode.rest, 1) IN IF ~fillerAsciiStr1.ok THEN Fail ELSE
    Ok([ symbolIndex         |-> symbolIndex.value,
         sourceSeqNum        |-> sourceSeqNum.value,
         sourceTime          |-> sourceTime.value,
         quoteLinkId         |-> quoteLinkId.value,
         askPrice            |-> askPrice.value,
         askSize             |-> askSize.value,
         bidPrice            |-> bidPrice.value,
         bidSize             |-> bidSize.value,
         systemId            |-> systemId.value,
         numberAskOrders     |-> numberAskOrders.value,
         numberBidOrders     |-> numberBidOrders.value,
         sourceTimeMicroSecs |-> sourceTimeMicroSecs.value,
         typeOfAskPrice      |-> typeOfAskPrice.value,
         typeOfBidPrice      |-> typeOfBidPrice.value,
         quoteCondition      |-> quoteCondition.value,
         quoteNumber         |-> quoteNumber.value,
         priceScaleCode      |-> priceScaleCode.value,
         fillerAsciiStr1     |-> fillerAsciiStr1.value ], fillerAsciiStr1.rest)

ZeroQuotesMessage ==
    [ symbolIndex         |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum        |-> [i \in 1 .. 4 |-> 0],
      sourceTime          |-> [i \in 1 .. 4 |-> 0],
      quoteLinkId         |-> [i \in 1 .. 4 |-> 0],
      askPrice            |-> [i \in 1 .. 4 |-> 0],
      askSize             |-> [i \in 1 .. 4 |-> 0],
      bidPrice            |-> [i \in 1 .. 4 |-> 0],
      bidSize             |-> [i \in 1 .. 4 |-> 0],
      systemId            |-> [i \in 1 .. 4 |-> 0],
      numberAskOrders     |-> [i \in 1 .. 2 |-> 0],
      numberBidOrders     |-> [i \in 1 .. 2 |-> 0],
      sourceTimeMicroSecs |-> [i \in 1 .. 2 |-> 0],
      typeOfAskPrice      |-> [i \in 1 .. 1 |-> 0],
      typeOfBidPrice      |-> [i \in 1 .. 1 |-> 0],
      quoteCondition      |-> [i \in 1 .. 1 |-> 0],
      quoteNumber         |-> [i \in 1 .. 1 |-> 0],
      priceScaleCode      |-> [i \in 1 .. 1 |-> 0],
      fillerAsciiStr1     |-> [i \in 1 .. 1 |-> 0] ]

(* Quotes Message at zero, then each field in turn at the values it is checked at *)
CheckedQuotesMessage ==
    { ZeroQuotesMessage }
        \cup { [ZeroQuotesMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroQuotesMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroQuotesMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroQuotesMessage EXCEPT !.quoteLinkId = one] : one \in Sample(4) }
        \cup { [ZeroQuotesMessage EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroQuotesMessage EXCEPT !.askSize = one] : one \in Sample(4) }
        \cup { [ZeroQuotesMessage EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroQuotesMessage EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuotesMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroQuotesMessage EXCEPT !.numberAskOrders = one] : one \in Sample(2) }
        \cup { [ZeroQuotesMessage EXCEPT !.numberBidOrders = one] : one \in Sample(2) }
        \cup { [ZeroQuotesMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroQuotesMessage EXCEPT !.typeOfAskPrice = one] : one \in Sample(1) }
        \cup { [ZeroQuotesMessage EXCEPT !.typeOfBidPrice = one] : one \in Sample(1) }
        \cup { [ZeroQuotesMessage EXCEPT !.quoteCondition = one] : one \in Sample(1) }
        \cup { [ZeroQuotesMessage EXCEPT !.quoteNumber = one] : one \in Sample(1) }
        \cup { [ZeroQuotesMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroQuotesMessage EXCEPT !.fillerAsciiStr1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Update Market Sheet Message: 60 bytes                             *)
(***************************************************************************)

OrderUpdateMarketSheetMessage ==
    [ symbolIndex            : Sample(4),
      sourceTime             : Sample(4),
      sourceSeqNum           : Sample(4),
      price                  : Sample(4),
      aggregatedVolume       : Sample(4),
      volume                 : Sample(4),
      linkId                 : Sample(4),
      orderId                : Sample(4),
      systemId               : Sample(4),
      sourceTimeMicroSecs    : Sample(2),
      numberOrders           : Sample(2),
      side                   : Sample(1),
      orderType              : Sample(1),
      actionType             : Sample(1),
      priceScaleCode         : Sample(1),
      orderDate              : Sample(4),
      orderPriorityDate      : Sample(4),
      orderPriorityTime      : Sample(4),
      orderPriorityMicroSecs : Sample(2),
      orderOrigin            : Sample(1),
      fillerBinaryInt1       : Sample(1) ]

EncodeOrderUpdateMarketSheetMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.sourceSeqNum
        \o message.price
        \o message.aggregatedVolume
        \o message.volume
        \o message.linkId
        \o message.orderId
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.numberOrders
        \o message.side
        \o message.orderType
        \o message.actionType
        \o message.priceScaleCode
        \o message.orderDate
        \o message.orderPriorityDate
        \o message.orderPriorityTime
        \o message.orderPriorityMicroSecs
        \o message.orderOrigin
        \o message.fillerBinaryInt1

DecodeOrderUpdateMarketSheetMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET price == ReadBytes(sourceSeqNum.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET aggregatedVolume == ReadBytes(price.rest, 4) IN IF ~aggregatedVolume.ok THEN Fail ELSE
    LET volume == ReadBytes(aggregatedVolume.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET linkId == ReadBytes(volume.rest, 4) IN IF ~linkId.ok THEN Fail ELSE
    LET orderId == ReadBytes(linkId.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET systemId == ReadBytes(orderId.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET numberOrders == ReadBytes(sourceTimeMicroSecs.rest, 2) IN IF ~numberOrders.ok THEN Fail ELSE
    LET side == ReadBytes(numberOrders.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderType == ReadBytes(side.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET actionType == ReadBytes(orderType.rest, 1) IN IF ~actionType.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(actionType.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET orderDate == ReadBytes(priceScaleCode.rest, 4) IN IF ~orderDate.ok THEN Fail ELSE
    LET orderPriorityDate == ReadBytes(orderDate.rest, 4) IN IF ~orderPriorityDate.ok THEN Fail ELSE
    LET orderPriorityTime == ReadBytes(orderPriorityDate.rest, 4) IN IF ~orderPriorityTime.ok THEN Fail ELSE
    LET orderPriorityMicroSecs == ReadBytes(orderPriorityTime.rest, 2) IN IF ~orderPriorityMicroSecs.ok THEN Fail ELSE
    LET orderOrigin == ReadBytes(orderPriorityMicroSecs.rest, 1) IN IF ~orderOrigin.ok THEN Fail ELSE
    LET fillerBinaryInt1 == ReadBytes(orderOrigin.rest, 1) IN IF ~fillerBinaryInt1.ok THEN Fail ELSE
    Ok([ symbolIndex            |-> symbolIndex.value,
         sourceTime             |-> sourceTime.value,
         sourceSeqNum           |-> sourceSeqNum.value,
         price                  |-> price.value,
         aggregatedVolume       |-> aggregatedVolume.value,
         volume                 |-> volume.value,
         linkId                 |-> linkId.value,
         orderId                |-> orderId.value,
         systemId               |-> systemId.value,
         sourceTimeMicroSecs    |-> sourceTimeMicroSecs.value,
         numberOrders           |-> numberOrders.value,
         side                   |-> side.value,
         orderType              |-> orderType.value,
         actionType             |-> actionType.value,
         priceScaleCode         |-> priceScaleCode.value,
         orderDate              |-> orderDate.value,
         orderPriorityDate      |-> orderPriorityDate.value,
         orderPriorityTime      |-> orderPriorityTime.value,
         orderPriorityMicroSecs |-> orderPriorityMicroSecs.value,
         orderOrigin            |-> orderOrigin.value,
         fillerBinaryInt1       |-> fillerBinaryInt1.value ], fillerBinaryInt1.rest)

ZeroOrderUpdateMarketSheetMessage ==
    [ symbolIndex            |-> [i \in 1 .. 4 |-> 0],
      sourceTime             |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum           |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 4 |-> 0],
      aggregatedVolume       |-> [i \in 1 .. 4 |-> 0],
      volume                 |-> [i \in 1 .. 4 |-> 0],
      linkId                 |-> [i \in 1 .. 4 |-> 0],
      orderId                |-> [i \in 1 .. 4 |-> 0],
      systemId               |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs    |-> [i \in 1 .. 2 |-> 0],
      numberOrders           |-> [i \in 1 .. 2 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      orderType              |-> [i \in 1 .. 1 |-> 0],
      actionType             |-> [i \in 1 .. 1 |-> 0],
      priceScaleCode         |-> [i \in 1 .. 1 |-> 0],
      orderDate              |-> [i \in 1 .. 4 |-> 0],
      orderPriorityDate      |-> [i \in 1 .. 4 |-> 0],
      orderPriorityTime      |-> [i \in 1 .. 4 |-> 0],
      orderPriorityMicroSecs |-> [i \in 1 .. 2 |-> 0],
      orderOrigin            |-> [i \in 1 .. 1 |-> 0],
      fillerBinaryInt1       |-> [i \in 1 .. 1 |-> 0] ]

(* Order Update Market Sheet Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderUpdateMarketSheetMessage ==
    { ZeroOrderUpdateMarketSheetMessage }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.aggregatedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.linkId = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.numberOrders = one] : one \in Sample(2) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.actionType = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.orderDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.orderPriorityDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.orderPriorityTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.orderPriorityMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.orderOrigin = one] : one \in Sample(1) }
        \cup { [ZeroOrderUpdateMarketSheetMessage EXCEPT !.fillerBinaryInt1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Orderbook Retransmission Delimiter Message: 12 bytes                    *)
(***************************************************************************)

OrderbookRetransmissionDelimiterMessage ==
    [ sourceTime              : Sample(4),
      sourceSeqNum            : Sample(4),
      tradingEngineId         : Sample(2),
      instanceId              : Sample(1),
      retransmissionIndicator : Sample(1) ]

EncodeOrderbookRetransmissionDelimiterMessage(message) ==
    message.sourceTime
        \o message.sourceSeqNum
        \o message.tradingEngineId
        \o message.instanceId
        \o message.retransmissionIndicator

DecodeOrderbookRetransmissionDelimiterMessage(bytes) ==
    LET sourceTime == ReadBytes(bytes, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET sourceSeqNum == ReadBytes(sourceTime.rest, 4) IN IF ~sourceSeqNum.ok THEN Fail ELSE
    LET tradingEngineId == ReadBytes(sourceSeqNum.rest, 2) IN IF ~tradingEngineId.ok THEN Fail ELSE
    LET instanceId == ReadBytes(tradingEngineId.rest, 1) IN IF ~instanceId.ok THEN Fail ELSE
    LET retransmissionIndicator == ReadBytes(instanceId.rest, 1) IN IF ~retransmissionIndicator.ok THEN Fail ELSE
    Ok([ sourceTime              |-> sourceTime.value,
         sourceSeqNum            |-> sourceSeqNum.value,
         tradingEngineId         |-> tradingEngineId.value,
         instanceId              |-> instanceId.value,
         retransmissionIndicator |-> retransmissionIndicator.value ], retransmissionIndicator.rest)

ZeroOrderbookRetransmissionDelimiterMessage ==
    [ sourceTime              |-> [i \in 1 .. 4 |-> 0],
      sourceSeqNum            |-> [i \in 1 .. 4 |-> 0],
      tradingEngineId         |-> [i \in 1 .. 2 |-> 0],
      instanceId              |-> [i \in 1 .. 1 |-> 0],
      retransmissionIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Orderbook Retransmission Delimiter Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderbookRetransmissionDelimiterMessage ==
    { ZeroOrderbookRetransmissionDelimiterMessage }
        \cup { [ZeroOrderbookRetransmissionDelimiterMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookRetransmissionDelimiterMessage EXCEPT !.sourceSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderbookRetransmissionDelimiterMessage EXCEPT !.tradingEngineId = one] : one \in Sample(2) }
        \cup { [ZeroOrderbookRetransmissionDelimiterMessage EXCEPT !.instanceId = one] : one \in Sample(1) }
        \cup { [ZeroOrderbookRetransmissionDelimiterMessage EXCEPT !.retransmissionIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Real Time Index Message: 48 bytes                                       *)
(***************************************************************************)

RealTimeIndexMessage ==
    [ symbolIndex                    : Sample(4),
      sourceTime                     : Sample(4),
      indexLevel                     : Sample(4),
      forerunnerLevel                : Sample(4),
      sessionHigh                    : Sample(4),
      sessionLow                     : Sample(4),
      percentageOfCapitalization     : Sample(4),
      variationFromPreviousDaysPrice : Sample(4),
      systemId                       : Sample(4),
      sourceTimeMicroSecs            : Sample(2),
      numOfSecuritiesQuoted          : Sample(2),
      indexLevelCode                 : Sample(1),
      typeOfLevel                    : Sample(1),
      levelScaleCode                 : Sample(1),
      percentageScaleCode            : Sample(1),
      variationScaleCode             : Sample(1),
      rebroadcastIndicator           : Sample(1),
      fillerAsciiStr2                : Sample(2) ]

EncodeRealTimeIndexMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.indexLevel
        \o message.forerunnerLevel
        \o message.sessionHigh
        \o message.sessionLow
        \o message.percentageOfCapitalization
        \o message.variationFromPreviousDaysPrice
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.numOfSecuritiesQuoted
        \o message.indexLevelCode
        \o message.typeOfLevel
        \o message.levelScaleCode
        \o message.percentageScaleCode
        \o message.variationScaleCode
        \o message.rebroadcastIndicator
        \o message.fillerAsciiStr2

DecodeRealTimeIndexMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET indexLevel == ReadBytes(sourceTime.rest, 4) IN IF ~indexLevel.ok THEN Fail ELSE
    LET forerunnerLevel == ReadBytes(indexLevel.rest, 4) IN IF ~forerunnerLevel.ok THEN Fail ELSE
    LET sessionHigh == ReadBytes(forerunnerLevel.rest, 4) IN IF ~sessionHigh.ok THEN Fail ELSE
    LET sessionLow == ReadBytes(sessionHigh.rest, 4) IN IF ~sessionLow.ok THEN Fail ELSE
    LET percentageOfCapitalization == ReadBytes(sessionLow.rest, 4) IN IF ~percentageOfCapitalization.ok THEN Fail ELSE
    LET variationFromPreviousDaysPrice == ReadBytes(percentageOfCapitalization.rest, 4) IN IF ~variationFromPreviousDaysPrice.ok THEN Fail ELSE
    LET systemId == ReadBytes(variationFromPreviousDaysPrice.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET numOfSecuritiesQuoted == ReadBytes(sourceTimeMicroSecs.rest, 2) IN IF ~numOfSecuritiesQuoted.ok THEN Fail ELSE
    LET indexLevelCode == ReadBytes(numOfSecuritiesQuoted.rest, 1) IN IF ~indexLevelCode.ok THEN Fail ELSE
    LET typeOfLevel == ReadBytes(indexLevelCode.rest, 1) IN IF ~typeOfLevel.ok THEN Fail ELSE
    LET levelScaleCode == ReadBytes(typeOfLevel.rest, 1) IN IF ~levelScaleCode.ok THEN Fail ELSE
    LET percentageScaleCode == ReadBytes(levelScaleCode.rest, 1) IN IF ~percentageScaleCode.ok THEN Fail ELSE
    LET variationScaleCode == ReadBytes(percentageScaleCode.rest, 1) IN IF ~variationScaleCode.ok THEN Fail ELSE
    LET rebroadcastIndicator == ReadBytes(variationScaleCode.rest, 1) IN IF ~rebroadcastIndicator.ok THEN Fail ELSE
    LET fillerAsciiStr2 == ReadBytes(rebroadcastIndicator.rest, 2) IN IF ~fillerAsciiStr2.ok THEN Fail ELSE
    Ok([ symbolIndex                    |-> symbolIndex.value,
         sourceTime                     |-> sourceTime.value,
         indexLevel                     |-> indexLevel.value,
         forerunnerLevel                |-> forerunnerLevel.value,
         sessionHigh                    |-> sessionHigh.value,
         sessionLow                     |-> sessionLow.value,
         percentageOfCapitalization     |-> percentageOfCapitalization.value,
         variationFromPreviousDaysPrice |-> variationFromPreviousDaysPrice.value,
         systemId                       |-> systemId.value,
         sourceTimeMicroSecs            |-> sourceTimeMicroSecs.value,
         numOfSecuritiesQuoted          |-> numOfSecuritiesQuoted.value,
         indexLevelCode                 |-> indexLevelCode.value,
         typeOfLevel                    |-> typeOfLevel.value,
         levelScaleCode                 |-> levelScaleCode.value,
         percentageScaleCode            |-> percentageScaleCode.value,
         variationScaleCode             |-> variationScaleCode.value,
         rebroadcastIndicator           |-> rebroadcastIndicator.value,
         fillerAsciiStr2                |-> fillerAsciiStr2.value ], fillerAsciiStr2.rest)

ZeroRealTimeIndexMessage ==
    [ symbolIndex                    |-> [i \in 1 .. 4 |-> 0],
      sourceTime                     |-> [i \in 1 .. 4 |-> 0],
      indexLevel                     |-> [i \in 1 .. 4 |-> 0],
      forerunnerLevel                |-> [i \in 1 .. 4 |-> 0],
      sessionHigh                    |-> [i \in 1 .. 4 |-> 0],
      sessionLow                     |-> [i \in 1 .. 4 |-> 0],
      percentageOfCapitalization     |-> [i \in 1 .. 4 |-> 0],
      variationFromPreviousDaysPrice |-> [i \in 1 .. 4 |-> 0],
      systemId                       |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs            |-> [i \in 1 .. 2 |-> 0],
      numOfSecuritiesQuoted          |-> [i \in 1 .. 2 |-> 0],
      indexLevelCode                 |-> [i \in 1 .. 1 |-> 0],
      typeOfLevel                    |-> [i \in 1 .. 1 |-> 0],
      levelScaleCode                 |-> [i \in 1 .. 1 |-> 0],
      percentageScaleCode            |-> [i \in 1 .. 1 |-> 0],
      variationScaleCode             |-> [i \in 1 .. 1 |-> 0],
      rebroadcastIndicator           |-> [i \in 1 .. 1 |-> 0],
      fillerAsciiStr2                |-> [i \in 1 .. 2 |-> 0] ]

(* Real Time Index Message at zero, then each field in turn at the values it is checked at *)
CheckedRealTimeIndexMessage ==
    { ZeroRealTimeIndexMessage }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.indexLevel = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.forerunnerLevel = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.sessionHigh = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.sessionLow = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.percentageOfCapitalization = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.variationFromPreviousDaysPrice = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.numOfSecuritiesQuoted = one] : one \in Sample(2) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.indexLevelCode = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.typeOfLevel = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.levelScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.percentageScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.variationScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.rebroadcastIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRealTimeIndexMessage EXCEPT !.fillerAsciiStr2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Index Summary Message: 88 bytes                                         *)
(***************************************************************************)

IndexSummaryMessage ==
    [ symbolIndex              : Sample(4),
      sourceTime               : Sample(4),
      preliminaryOpeningLevel  : Sample(4),
      preliminaryOpeningTime   : Sample(4),
      firstLevel               : Sample(4),
      firstTime                : Sample(4),
      openingReferenceLevel    : Sample(4),
      openingReferenceTime     : Sample(4),
      closingReferenceLevel    : Sample(4),
      closingReferenceTime     : Sample(4),
      percentVariationPrevClos : Sample(4),
      highLevel                : Sample(4),
      highTime                 : Sample(4),
      lowLevel                 : Sample(4),
      lowTime                  : Sample(4),
      clearingLevel            : Sample(4),
      clearingTime             : Sample(4),
      liquidationLevel         : Sample(4),
      liquidationTime          : Sample(4),
      systemId                 : Sample(4),
      sourceTimeMicroSecs      : Sample(2),
      typeOfLevel              : Sample(1),
      levelScaleCode           : Sample(1),
      variationScaleCode       : Sample(1),
      fillerAsciiStr3          : Sample(3) ]

EncodeIndexSummaryMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.preliminaryOpeningLevel
        \o message.preliminaryOpeningTime
        \o message.firstLevel
        \o message.firstTime
        \o message.openingReferenceLevel
        \o message.openingReferenceTime
        \o message.closingReferenceLevel
        \o message.closingReferenceTime
        \o message.percentVariationPrevClos
        \o message.highLevel
        \o message.highTime
        \o message.lowLevel
        \o message.lowTime
        \o message.clearingLevel
        \o message.clearingTime
        \o message.liquidationLevel
        \o message.liquidationTime
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.typeOfLevel
        \o message.levelScaleCode
        \o message.variationScaleCode
        \o message.fillerAsciiStr3

DecodeIndexSummaryMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET preliminaryOpeningLevel == ReadBytes(sourceTime.rest, 4) IN IF ~preliminaryOpeningLevel.ok THEN Fail ELSE
    LET preliminaryOpeningTime == ReadBytes(preliminaryOpeningLevel.rest, 4) IN IF ~preliminaryOpeningTime.ok THEN Fail ELSE
    LET firstLevel == ReadBytes(preliminaryOpeningTime.rest, 4) IN IF ~firstLevel.ok THEN Fail ELSE
    LET firstTime == ReadBytes(firstLevel.rest, 4) IN IF ~firstTime.ok THEN Fail ELSE
    LET openingReferenceLevel == ReadBytes(firstTime.rest, 4) IN IF ~openingReferenceLevel.ok THEN Fail ELSE
    LET openingReferenceTime == ReadBytes(openingReferenceLevel.rest, 4) IN IF ~openingReferenceTime.ok THEN Fail ELSE
    LET closingReferenceLevel == ReadBytes(openingReferenceTime.rest, 4) IN IF ~closingReferenceLevel.ok THEN Fail ELSE
    LET closingReferenceTime == ReadBytes(closingReferenceLevel.rest, 4) IN IF ~closingReferenceTime.ok THEN Fail ELSE
    LET percentVariationPrevClos == ReadBytes(closingReferenceTime.rest, 4) IN IF ~percentVariationPrevClos.ok THEN Fail ELSE
    LET highLevel == ReadBytes(percentVariationPrevClos.rest, 4) IN IF ~highLevel.ok THEN Fail ELSE
    LET highTime == ReadBytes(highLevel.rest, 4) IN IF ~highTime.ok THEN Fail ELSE
    LET lowLevel == ReadBytes(highTime.rest, 4) IN IF ~lowLevel.ok THEN Fail ELSE
    LET lowTime == ReadBytes(lowLevel.rest, 4) IN IF ~lowTime.ok THEN Fail ELSE
    LET clearingLevel == ReadBytes(lowTime.rest, 4) IN IF ~clearingLevel.ok THEN Fail ELSE
    LET clearingTime == ReadBytes(clearingLevel.rest, 4) IN IF ~clearingTime.ok THEN Fail ELSE
    LET liquidationLevel == ReadBytes(clearingTime.rest, 4) IN IF ~liquidationLevel.ok THEN Fail ELSE
    LET liquidationTime == ReadBytes(liquidationLevel.rest, 4) IN IF ~liquidationTime.ok THEN Fail ELSE
    LET systemId == ReadBytes(liquidationTime.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET typeOfLevel == ReadBytes(sourceTimeMicroSecs.rest, 1) IN IF ~typeOfLevel.ok THEN Fail ELSE
    LET levelScaleCode == ReadBytes(typeOfLevel.rest, 1) IN IF ~levelScaleCode.ok THEN Fail ELSE
    LET variationScaleCode == ReadBytes(levelScaleCode.rest, 1) IN IF ~variationScaleCode.ok THEN Fail ELSE
    LET fillerAsciiStr3 == ReadBytes(variationScaleCode.rest, 3) IN IF ~fillerAsciiStr3.ok THEN Fail ELSE
    Ok([ symbolIndex              |-> symbolIndex.value,
         sourceTime               |-> sourceTime.value,
         preliminaryOpeningLevel  |-> preliminaryOpeningLevel.value,
         preliminaryOpeningTime   |-> preliminaryOpeningTime.value,
         firstLevel               |-> firstLevel.value,
         firstTime                |-> firstTime.value,
         openingReferenceLevel    |-> openingReferenceLevel.value,
         openingReferenceTime     |-> openingReferenceTime.value,
         closingReferenceLevel    |-> closingReferenceLevel.value,
         closingReferenceTime     |-> closingReferenceTime.value,
         percentVariationPrevClos |-> percentVariationPrevClos.value,
         highLevel                |-> highLevel.value,
         highTime                 |-> highTime.value,
         lowLevel                 |-> lowLevel.value,
         lowTime                  |-> lowTime.value,
         clearingLevel            |-> clearingLevel.value,
         clearingTime             |-> clearingTime.value,
         liquidationLevel         |-> liquidationLevel.value,
         liquidationTime          |-> liquidationTime.value,
         systemId                 |-> systemId.value,
         sourceTimeMicroSecs      |-> sourceTimeMicroSecs.value,
         typeOfLevel              |-> typeOfLevel.value,
         levelScaleCode           |-> levelScaleCode.value,
         variationScaleCode       |-> variationScaleCode.value,
         fillerAsciiStr3          |-> fillerAsciiStr3.value ], fillerAsciiStr3.rest)

ZeroIndexSummaryMessage ==
    [ symbolIndex              |-> [i \in 1 .. 4 |-> 0],
      sourceTime               |-> [i \in 1 .. 4 |-> 0],
      preliminaryOpeningLevel  |-> [i \in 1 .. 4 |-> 0],
      preliminaryOpeningTime   |-> [i \in 1 .. 4 |-> 0],
      firstLevel               |-> [i \in 1 .. 4 |-> 0],
      firstTime                |-> [i \in 1 .. 4 |-> 0],
      openingReferenceLevel    |-> [i \in 1 .. 4 |-> 0],
      openingReferenceTime     |-> [i \in 1 .. 4 |-> 0],
      closingReferenceLevel    |-> [i \in 1 .. 4 |-> 0],
      closingReferenceTime     |-> [i \in 1 .. 4 |-> 0],
      percentVariationPrevClos |-> [i \in 1 .. 4 |-> 0],
      highLevel                |-> [i \in 1 .. 4 |-> 0],
      highTime                 |-> [i \in 1 .. 4 |-> 0],
      lowLevel                 |-> [i \in 1 .. 4 |-> 0],
      lowTime                  |-> [i \in 1 .. 4 |-> 0],
      clearingLevel            |-> [i \in 1 .. 4 |-> 0],
      clearingTime             |-> [i \in 1 .. 4 |-> 0],
      liquidationLevel         |-> [i \in 1 .. 4 |-> 0],
      liquidationTime          |-> [i \in 1 .. 4 |-> 0],
      systemId                 |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs      |-> [i \in 1 .. 2 |-> 0],
      typeOfLevel              |-> [i \in 1 .. 1 |-> 0],
      levelScaleCode           |-> [i \in 1 .. 1 |-> 0],
      variationScaleCode       |-> [i \in 1 .. 1 |-> 0],
      fillerAsciiStr3          |-> [i \in 1 .. 3 |-> 0] ]

(* Index Summary Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexSummaryMessage ==
    { ZeroIndexSummaryMessage }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.preliminaryOpeningLevel = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.preliminaryOpeningTime = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.firstLevel = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.firstTime = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.openingReferenceLevel = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.openingReferenceTime = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.closingReferenceLevel = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.closingReferenceTime = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.percentVariationPrevClos = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.highLevel = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.highTime = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.lowLevel = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.lowTime = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.clearingLevel = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.clearingTime = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.liquidationLevel = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.liquidationTime = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.typeOfLevel = one] : one \in Sample(1) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.levelScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.variationScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroIndexSummaryMessage EXCEPT !.fillerAsciiStr3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Index Composition Message: 48 bytes                                     *)
(***************************************************************************)

IndexCompositionMessage ==
    [ symbolIndex             : Sample(4),
      sourceTime              : Sample(4),
      instrumentWeight        : Sample(4),
      instrumentFactor        : Sample(4),
      previousClose           : Sample(4),
      systemId                : Sample(4),
      sourceTimeMicroSecs     : Sample(2),
      numberOfConponents      : Sample(2),
      instrumentIdOfComponent : Sample(12),
      mnemo                   : Sample(5),
      indexFrequency          : Sample(1),
      priceScaleCode          : Sample(1),
      levelScaleCode          : Sample(1) ]

EncodeIndexCompositionMessage(message) ==
    message.symbolIndex
        \o message.sourceTime
        \o message.instrumentWeight
        \o message.instrumentFactor
        \o message.previousClose
        \o message.systemId
        \o message.sourceTimeMicroSecs
        \o message.numberOfConponents
        \o message.instrumentIdOfComponent
        \o message.mnemo
        \o message.indexFrequency
        \o message.priceScaleCode
        \o message.levelScaleCode

DecodeIndexCompositionMessage(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET sourceTime == ReadBytes(symbolIndex.rest, 4) IN IF ~sourceTime.ok THEN Fail ELSE
    LET instrumentWeight == ReadBytes(sourceTime.rest, 4) IN IF ~instrumentWeight.ok THEN Fail ELSE
    LET instrumentFactor == ReadBytes(instrumentWeight.rest, 4) IN IF ~instrumentFactor.ok THEN Fail ELSE
    LET previousClose == ReadBytes(instrumentFactor.rest, 4) IN IF ~previousClose.ok THEN Fail ELSE
    LET systemId == ReadBytes(previousClose.rest, 4) IN IF ~systemId.ok THEN Fail ELSE
    LET sourceTimeMicroSecs == ReadBytes(systemId.rest, 2) IN IF ~sourceTimeMicroSecs.ok THEN Fail ELSE
    LET numberOfConponents == ReadBytes(sourceTimeMicroSecs.rest, 2) IN IF ~numberOfConponents.ok THEN Fail ELSE
    LET instrumentIdOfComponent == ReadBytes(numberOfConponents.rest, 12) IN IF ~instrumentIdOfComponent.ok THEN Fail ELSE
    LET mnemo == ReadBytes(instrumentIdOfComponent.rest, 5) IN IF ~mnemo.ok THEN Fail ELSE
    LET indexFrequency == ReadBytes(mnemo.rest, 1) IN IF ~indexFrequency.ok THEN Fail ELSE
    LET priceScaleCode == ReadBytes(indexFrequency.rest, 1) IN IF ~priceScaleCode.ok THEN Fail ELSE
    LET levelScaleCode == ReadBytes(priceScaleCode.rest, 1) IN IF ~levelScaleCode.ok THEN Fail ELSE
    Ok([ symbolIndex             |-> symbolIndex.value,
         sourceTime              |-> sourceTime.value,
         instrumentWeight        |-> instrumentWeight.value,
         instrumentFactor        |-> instrumentFactor.value,
         previousClose           |-> previousClose.value,
         systemId                |-> systemId.value,
         sourceTimeMicroSecs     |-> sourceTimeMicroSecs.value,
         numberOfConponents      |-> numberOfConponents.value,
         instrumentIdOfComponent |-> instrumentIdOfComponent.value,
         mnemo                   |-> mnemo.value,
         indexFrequency          |-> indexFrequency.value,
         priceScaleCode          |-> priceScaleCode.value,
         levelScaleCode          |-> levelScaleCode.value ], levelScaleCode.rest)

ZeroIndexCompositionMessage ==
    [ symbolIndex             |-> [i \in 1 .. 4 |-> 0],
      sourceTime              |-> [i \in 1 .. 4 |-> 0],
      instrumentWeight        |-> [i \in 1 .. 4 |-> 0],
      instrumentFactor        |-> [i \in 1 .. 4 |-> 0],
      previousClose           |-> [i \in 1 .. 4 |-> 0],
      systemId                |-> [i \in 1 .. 4 |-> 0],
      sourceTimeMicroSecs     |-> [i \in 1 .. 2 |-> 0],
      numberOfConponents      |-> [i \in 1 .. 2 |-> 0],
      instrumentIdOfComponent |-> [i \in 1 .. 12 |-> 0],
      mnemo                   |-> [i \in 1 .. 5 |-> 0],
      indexFrequency          |-> [i \in 1 .. 1 |-> 0],
      priceScaleCode          |-> [i \in 1 .. 1 |-> 0],
      levelScaleCode          |-> [i \in 1 .. 1 |-> 0] ]

(* Index Composition Message at zero, then each field in turn at the values it is checked at *)
CheckedIndexCompositionMessage ==
    { ZeroIndexCompositionMessage }
        \cup { [ZeroIndexCompositionMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroIndexCompositionMessage EXCEPT !.sourceTime = one] : one \in Sample(4) }
        \cup { [ZeroIndexCompositionMessage EXCEPT !.instrumentWeight = one] : one \in Sample(4) }
        \cup { [ZeroIndexCompositionMessage EXCEPT !.instrumentFactor = one] : one \in Sample(4) }
        \cup { [ZeroIndexCompositionMessage EXCEPT !.previousClose = one] : one \in Sample(4) }
        \cup { [ZeroIndexCompositionMessage EXCEPT !.systemId = one] : one \in Sample(4) }
        \cup { [ZeroIndexCompositionMessage EXCEPT !.sourceTimeMicroSecs = one] : one \in Sample(2) }
        \cup { [ZeroIndexCompositionMessage EXCEPT !.numberOfConponents = one] : one \in Sample(2) }
        \cup { [ZeroIndexCompositionMessage EXCEPT !.instrumentIdOfComponent = one] : one \in Sample(12) }
        \cup { [ZeroIndexCompositionMessage EXCEPT !.mnemo = one] : one \in Sample(5) }
        \cup { [ZeroIndexCompositionMessage EXCEPT !.indexFrequency = one] : one \in Sample(1) }
        \cup { [ZeroIndexCompositionMessage EXCEPT !.priceScaleCode = one] : one \in Sample(1) }
        \cup { [ZeroIndexCompositionMessage EXCEPT !.levelScaleCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Start Refresh Message: 4 bytes                                          *)
(***************************************************************************)

StartRefreshMessage ==
    [ lastSeqNum : Sample(4) ]

EncodeStartRefreshMessage(message) ==
    message.lastSeqNum

DecodeStartRefreshMessage(bytes) ==
    LET lastSeqNum == ReadBytes(bytes, 4) IN IF ~lastSeqNum.ok THEN Fail ELSE
    Ok([ lastSeqNum |-> lastSeqNum.value ], lastSeqNum.rest)

ZeroStartRefreshMessage ==
    [ lastSeqNum |-> [i \in 1 .. 4 |-> 0] ]

(* Start Refresh Message at zero, then each field in turn at the values it is checked at *)
CheckedStartRefreshMessage ==
    { ZeroStartRefreshMessage }
        \cup { [ZeroStartRefreshMessage EXCEPT !.lastSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* End Refresh Message: 4 bytes                                            *)
(***************************************************************************)

EndRefreshMessage ==
    [ lastSeqNum : Sample(4) ]

EncodeEndRefreshMessage(message) ==
    message.lastSeqNum

DecodeEndRefreshMessage(bytes) ==
    LET lastSeqNum == ReadBytes(bytes, 4) IN IF ~lastSeqNum.ok THEN Fail ELSE
    Ok([ lastSeqNum |-> lastSeqNum.value ], lastSeqNum.rest)

ZeroEndRefreshMessage ==
    [ lastSeqNum |-> [i \in 1 .. 4 |-> 0] ]

(* End Refresh Message at zero, then each field in turn at the values it is checked at *)
CheckedEndRefreshMessage ==
    { ZeroEndRefreshMessage }
        \cup { [ZeroEndRefreshMessage EXCEPT !.lastSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

StockStateChangeMessageCode == 505  \* 0x1f9
ClassStateChangeMessageCode == 516  \* 0x204
MailMessageCode == 523  \* 0x20b
IndicativeMatchingPriceMessageCode == 530  \* 0x212
CollarsMessageCode == 537  \* 0x219
SessionTimetableMessageCode == 539  \* 0x21b
GlobalMarketActivitySummaryMessageCode == 545  \* 0x221
StartReferentialMessageCode == 550  \* 0x226
EndReferentialMessageCode == 551  \* 0x227
ReferentialMessageCode == 555  \* 0x22b
TradeCreationMessageCode == 220  \* 0xdc
TradeCancellationMessageCode == 221  \* 0xdd
TradeFullInformationMessageCode == 240  \* 0xf0
PriceUpdateMessageCode == 241  \* 0xf1
AuctionSummaryMessageCode == 245  \* 0xf5
VwapClosingPriceMessageCode == 247  \* 0xf7
QuotesMessageCode == 140  \* 0x8c
OrderUpdateMarketSheetMessageCode == 230  \* 0xe6
OrderbookRetransmissionDelimiterMessageCode == 231  \* 0xe7
RealTimeIndexMessageCode == 542  \* 0x21e
IndexSummaryMessageCode == 543  \* 0x21f
IndexCompositionMessageCode == 544  \* 0x220
StartRefreshMessageCode == 580  \* 0x244
EndRefreshMessageCode == 581  \* 0x245

Payload ==
    [ tag : {StockStateChangeMessageCode}, body : StockStateChangeMessage ]
        \cup [ tag : {ClassStateChangeMessageCode}, body : ClassStateChangeMessage ]
        \cup [ tag : {MailMessageCode}, body : MailMessage ]
        \cup [ tag : {IndicativeMatchingPriceMessageCode}, body : IndicativeMatchingPriceMessage ]
        \cup [ tag : {CollarsMessageCode}, body : CollarsMessage ]
        \cup [ tag : {SessionTimetableMessageCode}, body : SessionTimetableMessage ]
        \cup [ tag : {GlobalMarketActivitySummaryMessageCode}, body : GlobalMarketActivitySummaryMessage ]
        \cup [ tag : {StartReferentialMessageCode}, body : StartReferentialMessage ]
        \cup [ tag : {EndReferentialMessageCode}, body : EndReferentialMessage ]
        \cup [ tag : {ReferentialMessageCode}, body : ReferentialMessage ]
        \cup [ tag : {TradeCreationMessageCode}, body : TradeCreationMessage ]
        \cup [ tag : {TradeCancellationMessageCode}, body : TradeCancellationMessage ]
        \cup [ tag : {TradeFullInformationMessageCode}, body : TradeFullInformationMessage ]
        \cup [ tag : {PriceUpdateMessageCode}, body : PriceUpdateMessage ]
        \cup [ tag : {AuctionSummaryMessageCode}, body : AuctionSummaryMessage ]
        \cup [ tag : {VwapClosingPriceMessageCode}, body : VwapClosingPriceMessage ]
        \cup [ tag : {QuotesMessageCode}, body : QuotesMessage ]
        \cup [ tag : {OrderUpdateMarketSheetMessageCode}, body : OrderUpdateMarketSheetMessage ]
        \cup [ tag : {OrderbookRetransmissionDelimiterMessageCode}, body : OrderbookRetransmissionDelimiterMessage ]
        \cup [ tag : {RealTimeIndexMessageCode}, body : RealTimeIndexMessage ]
        \cup [ tag : {IndexSummaryMessageCode}, body : IndexSummaryMessage ]
        \cup [ tag : {IndexCompositionMessageCode}, body : IndexCompositionMessage ]
        \cup [ tag : {StartRefreshMessageCode}, body : StartRefreshMessage ]
        \cup [ tag : {EndRefreshMessageCode}, body : EndRefreshMessage ]

EncodePayload(message) ==
    CASE message.tag = StockStateChangeMessageCode -> EncodeStockStateChangeMessage(message.body)
      [] message.tag = ClassStateChangeMessageCode -> EncodeClassStateChangeMessage(message.body)
      [] message.tag = MailMessageCode -> EncodeMailMessage(message.body)
      [] message.tag = IndicativeMatchingPriceMessageCode -> EncodeIndicativeMatchingPriceMessage(message.body)
      [] message.tag = CollarsMessageCode -> EncodeCollarsMessage(message.body)
      [] message.tag = SessionTimetableMessageCode -> EncodeSessionTimetableMessage(message.body)
      [] message.tag = GlobalMarketActivitySummaryMessageCode -> EncodeGlobalMarketActivitySummaryMessage(message.body)
      [] message.tag = StartReferentialMessageCode -> EncodeStartReferentialMessage(message.body)
      [] message.tag = EndReferentialMessageCode -> EncodeEndReferentialMessage(message.body)
      [] message.tag = ReferentialMessageCode -> EncodeReferentialMessage(message.body)
      [] message.tag = TradeCreationMessageCode -> EncodeTradeCreationMessage(message.body)
      [] message.tag = TradeCancellationMessageCode -> EncodeTradeCancellationMessage(message.body)
      [] message.tag = TradeFullInformationMessageCode -> EncodeTradeFullInformationMessage(message.body)
      [] message.tag = PriceUpdateMessageCode -> EncodePriceUpdateMessage(message.body)
      [] message.tag = AuctionSummaryMessageCode -> EncodeAuctionSummaryMessage(message.body)
      [] message.tag = VwapClosingPriceMessageCode -> EncodeVwapClosingPriceMessage(message.body)
      [] message.tag = QuotesMessageCode -> EncodeQuotesMessage(message.body)
      [] message.tag = OrderUpdateMarketSheetMessageCode -> EncodeOrderUpdateMarketSheetMessage(message.body)
      [] message.tag = OrderbookRetransmissionDelimiterMessageCode -> EncodeOrderbookRetransmissionDelimiterMessage(message.body)
      [] message.tag = RealTimeIndexMessageCode -> EncodeRealTimeIndexMessage(message.body)
      [] message.tag = IndexSummaryMessageCode -> EncodeIndexSummaryMessage(message.body)
      [] message.tag = IndexCompositionMessageCode -> EncodeIndexCompositionMessage(message.body)
      [] message.tag = StartRefreshMessageCode -> EncodeStartRefreshMessage(message.body)
      [] message.tag = EndRefreshMessageCode -> EncodeEndRefreshMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = StockStateChangeMessageCode -> DecodeStockStateChangeMessage(bytes)
              [] tag = ClassStateChangeMessageCode -> DecodeClassStateChangeMessage(bytes)
              [] tag = MailMessageCode -> DecodeMailMessage(bytes)
              [] tag = IndicativeMatchingPriceMessageCode -> DecodeIndicativeMatchingPriceMessage(bytes)
              [] tag = CollarsMessageCode -> DecodeCollarsMessage(bytes)
              [] tag = SessionTimetableMessageCode -> DecodeSessionTimetableMessage(bytes)
              [] tag = GlobalMarketActivitySummaryMessageCode -> DecodeGlobalMarketActivitySummaryMessage(bytes)
              [] tag = StartReferentialMessageCode -> DecodeStartReferentialMessage(bytes)
              [] tag = EndReferentialMessageCode -> DecodeEndReferentialMessage(bytes)
              [] tag = ReferentialMessageCode -> DecodeReferentialMessage(bytes)
              [] tag = TradeCreationMessageCode -> DecodeTradeCreationMessage(bytes)
              [] tag = TradeCancellationMessageCode -> DecodeTradeCancellationMessage(bytes)
              [] tag = TradeFullInformationMessageCode -> DecodeTradeFullInformationMessage(bytes)
              [] tag = PriceUpdateMessageCode -> DecodePriceUpdateMessage(bytes)
              [] tag = AuctionSummaryMessageCode -> DecodeAuctionSummaryMessage(bytes)
              [] tag = VwapClosingPriceMessageCode -> DecodeVwapClosingPriceMessage(bytes)
              [] tag = QuotesMessageCode -> DecodeQuotesMessage(bytes)
              [] tag = OrderUpdateMarketSheetMessageCode -> DecodeOrderUpdateMarketSheetMessage(bytes)
              [] tag = OrderbookRetransmissionDelimiterMessageCode -> DecodeOrderbookRetransmissionDelimiterMessage(bytes)
              [] tag = RealTimeIndexMessageCode -> DecodeRealTimeIndexMessage(bytes)
              [] tag = IndexSummaryMessageCode -> DecodeIndexSummaryMessage(bytes)
              [] tag = IndexCompositionMessageCode -> DecodeIndexCompositionMessage(bytes)
              [] tag = StartRefreshMessageCode -> DecodeStartRefreshMessage(bytes)
              [] tag = EndRefreshMessageCode -> DecodeEndRefreshMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> StockStateChangeMessageCode, body |-> ZeroStockStateChangeMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> StockStateChangeMessageCode, body |-> one] : one \in CheckedStockStateChangeMessage }
        \cup { [tag |-> ClassStateChangeMessageCode, body |-> one] : one \in CheckedClassStateChangeMessage }
        \cup { [tag |-> MailMessageCode, body |-> one] : one \in CheckedMailMessage }
        \cup { [tag |-> IndicativeMatchingPriceMessageCode, body |-> one] : one \in CheckedIndicativeMatchingPriceMessage }
        \cup { [tag |-> CollarsMessageCode, body |-> one] : one \in CheckedCollarsMessage }
        \cup { [tag |-> SessionTimetableMessageCode, body |-> one] : one \in CheckedSessionTimetableMessage }
        \cup { [tag |-> GlobalMarketActivitySummaryMessageCode, body |-> one] : one \in CheckedGlobalMarketActivitySummaryMessage }
        \cup { [tag |-> StartReferentialMessageCode, body |-> one] : one \in CheckedStartReferentialMessage }
        \cup { [tag |-> EndReferentialMessageCode, body |-> one] : one \in CheckedEndReferentialMessage }
        \cup { [tag |-> ReferentialMessageCode, body |-> one] : one \in CheckedReferentialMessage }
        \cup { [tag |-> TradeCreationMessageCode, body |-> one] : one \in CheckedTradeCreationMessage }
        \cup { [tag |-> TradeCancellationMessageCode, body |-> one] : one \in CheckedTradeCancellationMessage }
        \cup { [tag |-> TradeFullInformationMessageCode, body |-> one] : one \in CheckedTradeFullInformationMessage }
        \cup { [tag |-> PriceUpdateMessageCode, body |-> one] : one \in CheckedPriceUpdateMessage }
        \cup { [tag |-> AuctionSummaryMessageCode, body |-> one] : one \in CheckedAuctionSummaryMessage }
        \cup { [tag |-> VwapClosingPriceMessageCode, body |-> one] : one \in CheckedVwapClosingPriceMessage }
        \cup { [tag |-> QuotesMessageCode, body |-> one] : one \in CheckedQuotesMessage }
        \cup { [tag |-> OrderUpdateMarketSheetMessageCode, body |-> one] : one \in CheckedOrderUpdateMarketSheetMessage }
        \cup { [tag |-> OrderbookRetransmissionDelimiterMessageCode, body |-> one] : one \in CheckedOrderbookRetransmissionDelimiterMessage }
        \cup { [tag |-> RealTimeIndexMessageCode, body |-> one] : one \in CheckedRealTimeIndexMessage }
        \cup { [tag |-> IndexSummaryMessageCode, body |-> one] : one \in CheckedIndexSummaryMessage }
        \cup { [tag |-> IndexCompositionMessageCode, body |-> one] : one \in CheckedIndexCompositionMessage }
        \cup { [tag |-> StartRefreshMessageCode, body |-> one] : one \in CheckedStartRefreshMessage }
        \cup { [tag |-> EndRefreshMessageCode, body |-> one] : one \in CheckedEndRefreshMessage }

(***************************************************************************)
(* Message, framed by Message Size                                         *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> StockStateChangeMessageCode, body |-> ZeroStockStateChangeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ClassStateChangeMessageCode, body |-> ZeroClassStateChangeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MailMessageCode, body |-> ZeroMailMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndicativeMatchingPriceMessageCode, body |-> ZeroIndicativeMatchingPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CollarsMessageCode, body |-> ZeroCollarsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SessionTimetableMessageCode, body |-> ZeroSessionTimetableMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> GlobalMarketActivitySummaryMessageCode, body |-> ZeroGlobalMarketActivitySummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StartReferentialMessageCode, body |-> ZeroStartReferentialMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndReferentialMessageCode, body |-> ZeroEndReferentialMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReferentialMessageCode, body |-> ZeroReferentialMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCreationMessageCode, body |-> ZeroTradeCreationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeCancellationMessageCode, body |-> ZeroTradeCancellationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeFullInformationMessageCode, body |-> ZeroTradeFullInformationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PriceUpdateMessageCode, body |-> ZeroPriceUpdateMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionSummaryMessageCode, body |-> ZeroAuctionSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> VwapClosingPriceMessageCode, body |-> ZeroVwapClosingPriceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuotesMessageCode, body |-> ZeroQuotesMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderUpdateMarketSheetMessageCode, body |-> ZeroOrderUpdateMarketSheetMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderbookRetransmissionDelimiterMessageCode, body |-> ZeroOrderbookRetransmissionDelimiterMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RealTimeIndexMessageCode, body |-> ZeroRealTimeIndexMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexSummaryMessageCode, body |-> ZeroIndexSummaryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndexCompositionMessageCode, body |-> ZeroIndexCompositionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StartRefreshMessageCode, body |-> ZeroStartRefreshMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> EndRefreshMessageCode, body |-> ZeroEndRefreshMessage]] }

(***************************************************************************)
(* Message Buffer, selected by Delivery Flag                               *)
(***************************************************************************)

MessageBufferZlibCode == 17  \* 0x11
MessageBufferPlainCode == 0  \* stands for every value no other case names

MessageBufferBody ==
    [ tag : {MessageBufferZlibCode}, body : MessageBufferZlib ]
        \cup [ tag : (0 .. 255) \ {MessageBufferZlibCode}, body : SampleLists(OneMessage) ]

EncodeMessageBufferBody(message) ==
    CASE message.tag = MessageBufferZlibCode -> EncodeMessageBufferZlib(message.body)
      [] OTHER -> EncodeMessageList(message.body)

(* How many Message a Message Buffer holds, which is what Number Msg Entries states. *)
(* A case that is no run of them says nothing about the number, so it holds whatever was stated. *)
CountMessageBufferBody(choice, stated) ==
    CASE choice.tag = MessageBufferZlibCode -> stated
      [] OTHER -> Len(choice.body)

DecodeMessageBufferBody(tag, count, bytes) ==
    LET read ==
            CASE tag = MessageBufferZlibCode -> DecodeMessageBufferZlib(bytes)
              [] OTHER -> ReadMessageList(bytes, count)
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBufferBody == [tag |-> MessageBufferZlibCode, body |-> ZeroMessageBufferZlib]

(* Each Message Buffer in turn, at the values the message it names is checked at *)
CheckedMessageBufferBody ==
    { [tag |-> MessageBufferZlibCode, body |-> one] : one \in CheckedMessageBufferZlib }
        \cup [ tag : {0, 1, 255} \ {MessageBufferZlibCode}, body : SampleLists(OneMessage) ]

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ packetLength         : Sample(2),
      packetType           : Sample(2),
      packetSequenceNumber : Sample(4),
      sendTime             : Sample(4),
      serviceId            : Sample(2),
      numberMsgEntries     : 0 .. 255,
      messageBuffer        : MessageBufferBody ]

EncodePacket(message) ==
    message.packetLength
        \o message.packetType
        \o message.packetSequenceNumber
        \o message.sendTime
        \o message.serviceId
        \o EncodeUIntBE(message.messageBuffer.tag, 1)
        \o EncodeUIntBE(message.numberMsgEntries, 1)
        \o EncodeMessageBufferBody(message.messageBuffer)

DecodePacket(bytes) ==
    LET packetLength == ReadBytes(bytes, 2) IN IF ~packetLength.ok THEN Fail ELSE
    LET packetType == ReadBytes(packetLength.rest, 2) IN IF ~packetType.ok THEN Fail ELSE
    LET packetSequenceNumber == ReadBytes(packetType.rest, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET sendTime == ReadBytes(packetSequenceNumber.rest, 4) IN IF ~sendTime.ok THEN Fail ELSE
    LET serviceId == ReadBytes(sendTime.rest, 2) IN IF ~serviceId.ok THEN Fail ELSE
    LET deliveryFlag == ReadUIntBE(serviceId.rest, 1) IN IF ~deliveryFlag.ok THEN Fail ELSE
    LET numberMsgEntries == ReadUIntBE(deliveryFlag.rest, 1) IN IF ~numberMsgEntries.ok THEN Fail ELSE
    LET messageBuffer == DecodeMessageBufferBody(deliveryFlag.value, numberMsgEntries.value, numberMsgEntries.rest) IN IF ~messageBuffer.ok THEN Fail ELSE
    Ok([ packetLength         |-> packetLength.value,
         packetType           |-> packetType.value,
         packetSequenceNumber |-> packetSequenceNumber.value,
         sendTime             |-> sendTime.value,
         serviceId            |-> serviceId.value,
         numberMsgEntries     |-> numberMsgEntries.value,
         messageBuffer        |-> messageBuffer.value ], messageBuffer.rest)

ZeroPacket ==
    [ packetLength         |-> [i \in 1 .. 2 |-> 0],
      packetType           |-> [i \in 1 .. 2 |-> 0],
      packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      sendTime             |-> [i \in 1 .. 4 |-> 0],
      serviceId            |-> [i \in 1 .. 2 |-> 0],
      numberMsgEntries     |-> 0,
      messageBuffer        |-> ZeroMessageBufferBody ]

(* Packet at zero, then each field in turn at the values it is checked at *)
(* Number Msg Entries is varied with the Message Buffer it counts, which is read as many as it says *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.packetLength = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.packetType = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.serviceId = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.numberMsgEntries = one] : one \in {0, 1, 255} }
        \cup { [ZeroPacket EXCEPT !.numberMsgEntries = CountMessageBufferBody(one, 0), !.messageBuffer = one] : one \in CheckedMessageBufferBody }

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

(* Every Message Buffer decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageBufferZlib ==
    \A message \in CheckedMessageBufferZlib :
        LET read == DecodeMessageBufferZlib(EncodeMessageBufferZlib(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock State Change Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockStateChangeMessage ==
    \A message \in CheckedStockStateChangeMessage :
        LET read == DecodeStockStateChangeMessage(EncodeStockStateChangeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Class State Change Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClassStateChangeMessage ==
    \A message \in CheckedClassStateChangeMessage :
        LET read == DecodeClassStateChangeMessage(EncodeClassStateChangeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mail Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMailMessage ==
    \A message \in CheckedMailMessage :
        LET read == DecodeMailMessage(EncodeMailMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Indicative Matching Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndicativeMatchingPriceMessage ==
    \A message \in CheckedIndicativeMatchingPriceMessage :
        LET read == DecodeIndicativeMatchingPriceMessage(EncodeIndicativeMatchingPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Collars Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCollarsMessage ==
    \A message \in CheckedCollarsMessage :
        LET read == DecodeCollarsMessage(EncodeCollarsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Session Timetable Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSessionTimetableMessage ==
    \A message \in CheckedSessionTimetableMessage :
        LET read == DecodeSessionTimetableMessage(EncodeSessionTimetableMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Global Market Activity Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGlobalMarketActivitySummaryMessage ==
    \A message \in CheckedGlobalMarketActivitySummaryMessage :
        LET read == DecodeGlobalMarketActivitySummaryMessage(EncodeGlobalMarketActivitySummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Referential Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartReferentialMessage ==
    \A message \in CheckedStartReferentialMessage :
        LET read == DecodeStartReferentialMessage(EncodeStartReferentialMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Referential Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndReferentialMessage ==
    \A message \in CheckedEndReferentialMessage :
        LET read == DecodeEndReferentialMessage(EncodeEndReferentialMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Referential Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReferentialMessage ==
    \A message \in CheckedReferentialMessage :
        LET read == DecodeReferentialMessage(EncodeReferentialMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Creation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCreationMessage ==
    \A message \in CheckedTradeCreationMessage :
        LET read == DecodeTradeCreationMessage(EncodeTradeCreationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancellationMessage ==
    \A message \in CheckedTradeCancellationMessage :
        LET read == DecodeTradeCancellationMessage(EncodeTradeCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Full Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeFullInformationMessage ==
    \A message \in CheckedTradeFullInformationMessage :
        LET read == DecodeTradeFullInformationMessage(EncodeTradeFullInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceUpdateMessage ==
    \A message \in CheckedPriceUpdateMessage :
        LET read == DecodePriceUpdateMessage(EncodePriceUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionSummaryMessage ==
    \A message \in CheckedAuctionSummaryMessage :
        LET read == DecodeAuctionSummaryMessage(EncodeAuctionSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Vwap Closing Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripVwapClosingPriceMessage ==
    \A message \in CheckedVwapClosingPriceMessage :
        LET read == DecodeVwapClosingPriceMessage(EncodeVwapClosingPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quotes Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuotesMessage ==
    \A message \in CheckedQuotesMessage :
        LET read == DecodeQuotesMessage(EncodeQuotesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Update Market Sheet Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderUpdateMarketSheetMessage ==
    \A message \in CheckedOrderUpdateMarketSheetMessage :
        LET read == DecodeOrderUpdateMarketSheetMessage(EncodeOrderUpdateMarketSheetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Orderbook Retransmission Delimiter Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderbookRetransmissionDelimiterMessage ==
    \A message \in CheckedOrderbookRetransmissionDelimiterMessage :
        LET read == DecodeOrderbookRetransmissionDelimiterMessage(EncodeOrderbookRetransmissionDelimiterMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Real Time Index Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRealTimeIndexMessage ==
    \A message \in CheckedRealTimeIndexMessage :
        LET read == DecodeRealTimeIndexMessage(EncodeRealTimeIndexMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Summary Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexSummaryMessage ==
    \A message \in CheckedIndexSummaryMessage :
        LET read == DecodeIndexSummaryMessage(EncodeIndexSummaryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Index Composition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndexCompositionMessage ==
    \A message \in CheckedIndexCompositionMessage :
        LET read == DecodeIndexCompositionMessage(EncodeIndexCompositionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Start Refresh Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStartRefreshMessage ==
    \A message \in CheckedStartRefreshMessage :
        LET read == DecodeStartRefreshMessage(EncodeStartRefreshMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Refresh Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndRefreshMessage ==
    \A message \in CheckedEndRefreshMessage :
        LET read == DecodeEndRefreshMessage(EncodeEndRefreshMessage(message))
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
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* A Message Buffer is selected by the Delivery Flag it is written under *)
SelectsMessageBufferBody ==
    \A message \in CheckedMessageBufferBody :
        LET sent == EncodeMessageBufferBody(message)
            read == DecodeMessageBufferBody(message.tag, CountMessageBufferBody(message, 0), sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
