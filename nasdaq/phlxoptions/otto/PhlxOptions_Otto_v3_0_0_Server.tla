------------------ MODULE PhlxOptions_Otto_v3_0_0_Server -------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Ouch to Trade Options v3.0.0                                   *)
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
(* Note: Sequenced Data Packet fills what is left of the frame Packet      *)
(* Length states, which is what it is read from.                           *)
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
(* Debug Packet                                                            *)
(***************************************************************************)

DebugPacket ==
    [ debugText : SampleBytes ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == Ok(bytes, << >>) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> << >> ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in SampleBytes }

(***************************************************************************)
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ acceptedSession        : Sample(10),
      acceptedSequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.acceptedSession
        \o message.acceptedSequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET acceptedSession == ReadBytes(bytes, 10) IN IF ~acceptedSession.ok THEN Fail ELSE
    LET acceptedSequenceNumber == ReadBytes(acceptedSession.rest, 20) IN IF ~acceptedSequenceNumber.ok THEN Fail ELSE
    Ok([ acceptedSession        |-> acceptedSession.value,
         acceptedSequenceNumber |-> acceptedSequenceNumber.value ], acceptedSequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ acceptedSession        |-> [i \in 1 .. 10 |-> 0],
      acceptedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.acceptedSequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Login Rejected Packet: 1 bytes                                          *)
(***************************************************************************)

LoginRejectedPacket ==
    [ rejectReasonCode : Sample(1) ]

EncodeLoginRejectedPacket(message) ==
    message.rejectReasonCode

DecodeLoginRejectedPacket(bytes) ==
    LET rejectReasonCode == ReadBytes(bytes, 1) IN IF ~rejectReasonCode.ok THEN Fail ELSE
    Ok([ rejectReasonCode |-> rejectReasonCode.value ], rejectReasonCode.rest)

ZeroLoginRejectedPacket ==
    [ rejectReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Login Rejected Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRejectedPacket ==
    { ZeroLoginRejectedPacket }
        \cup { [ZeroLoginRejectedPacket EXCEPT !.rejectReasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* System Event Message: 11 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp  : Sample(8),
      eventCode  : Sample(1),
      version    : Sample(1),
      subversion : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.eventCode
        \o message.version
        \o message.subversion

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET version == ReadBytes(eventCode.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET subversion == ReadBytes(version.rest, 1) IN IF ~subversion.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         eventCode  |-> eventCode.value,
         version    |-> version.value,
         subversion |-> subversion.value ], subversion.rest)

ZeroSystemEventMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      eventCode  |-> [i \in 1 .. 1 |-> 0],
      version    |-> [i \in 1 .. 1 |-> 0],
      subversion |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.subversion = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple Instrument Directory Message: 69 bytes                           *)
(***************************************************************************)

SimpleInstrumentDirectoryMessage ==
    [ timestamp      : Sample(8),
      productId      : Sample(2),
      productName    : Sample(13),
      instrumentId   : Sample(4),
      expirYear      : Sample(1),
      expirMon       : Sample(1),
      expirDay       : Sample(1),
      strikePrice    : Sample(8),
      optionType     : Sample(1),
      closingType    : Sample(1),
      tradable       : Sample(1),
      closingOnly    : Sample(1),
      contractSize   : Sample(2),
      mpv            : Sample(1),
      securitySymbol : Sample(8),
      reserved16     : Sample(16) ]

EncodeSimpleInstrumentDirectoryMessage(message) ==
    message.timestamp
        \o message.productId
        \o message.productName
        \o message.instrumentId
        \o message.expirYear
        \o message.expirMon
        \o message.expirDay
        \o message.strikePrice
        \o message.optionType
        \o message.closingType
        \o message.tradable
        \o message.closingOnly
        \o message.contractSize
        \o message.mpv
        \o message.securitySymbol
        \o message.reserved16

DecodeSimpleInstrumentDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET productId == ReadBytes(timestamp.rest, 2) IN IF ~productId.ok THEN Fail ELSE
    LET productName == ReadBytes(productId.rest, 13) IN IF ~productName.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(productName.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET expirYear == ReadBytes(instrumentId.rest, 1) IN IF ~expirYear.ok THEN Fail ELSE
    LET expirMon == ReadBytes(expirYear.rest, 1) IN IF ~expirMon.ok THEN Fail ELSE
    LET expirDay == ReadBytes(expirMon.rest, 1) IN IF ~expirDay.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expirDay.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET closingType == ReadBytes(optionType.rest, 1) IN IF ~closingType.ok THEN Fail ELSE
    LET tradable == ReadBytes(closingType.rest, 1) IN IF ~tradable.ok THEN Fail ELSE
    LET closingOnly == ReadBytes(tradable.rest, 1) IN IF ~closingOnly.ok THEN Fail ELSE
    LET contractSize == ReadBytes(closingOnly.rest, 2) IN IF ~contractSize.ok THEN Fail ELSE
    LET mpv == ReadBytes(contractSize.rest, 1) IN IF ~mpv.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(mpv.rest, 8) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(securitySymbol.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         productId      |-> productId.value,
         productName    |-> productName.value,
         instrumentId   |-> instrumentId.value,
         expirYear      |-> expirYear.value,
         expirMon       |-> expirMon.value,
         expirDay       |-> expirDay.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         closingType    |-> closingType.value,
         tradable       |-> tradable.value,
         closingOnly    |-> closingOnly.value,
         contractSize   |-> contractSize.value,
         mpv            |-> mpv.value,
         securitySymbol |-> securitySymbol.value,
         reserved16     |-> reserved16.value ], reserved16.rest)

ZeroSimpleInstrumentDirectoryMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      productId      |-> [i \in 1 .. 2 |-> 0],
      productName    |-> [i \in 1 .. 13 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      expirYear      |-> [i \in 1 .. 1 |-> 0],
      expirMon       |-> [i \in 1 .. 1 |-> 0],
      expirDay       |-> [i \in 1 .. 1 |-> 0],
      strikePrice    |-> [i \in 1 .. 8 |-> 0],
      optionType     |-> [i \in 1 .. 1 |-> 0],
      closingType    |-> [i \in 1 .. 1 |-> 0],
      tradable       |-> [i \in 1 .. 1 |-> 0],
      closingOnly    |-> [i \in 1 .. 1 |-> 0],
      contractSize   |-> [i \in 1 .. 2 |-> 0],
      mpv            |-> [i \in 1 .. 1 |-> 0],
      securitySymbol |-> [i \in 1 .. 8 |-> 0],
      reserved16     |-> [i \in 1 .. 16 |-> 0] ]

(* Simple Instrument Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleInstrumentDirectoryMessage ==
    { ZeroSimpleInstrumentDirectoryMessage }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.productId = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.productName = one] : one \in Sample(13) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.expirYear = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.expirMon = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.expirDay = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.closingType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.tradable = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.closingOnly = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.contractSize = one] : one \in Sample(2) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.mpv = one] : one \in Sample(1) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.securitySymbol = one] : one \in Sample(8) }
        \cup { [ZeroSimpleInstrumentDirectoryMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Complex Directory Legs: 9 bytes                                         *)
(***************************************************************************)

ComplexDirectoryLegs ==
    [ legType         : Sample(1),
      legInstrumentId : Sample(4),
      legSide         : Sample(1),
      legRatio        : Sample(2),
      legId           : Sample(1) ]

EncodeComplexDirectoryLegs(message) ==
    message.legType
        \o message.legInstrumentId
        \o message.legSide
        \o message.legRatio
        \o message.legId

DecodeComplexDirectoryLegs(bytes) ==
    LET legType == ReadBytes(bytes, 1) IN IF ~legType.ok THEN Fail ELSE
    LET legInstrumentId == ReadBytes(legType.rest, 4) IN IF ~legInstrumentId.ok THEN Fail ELSE
    LET legSide == ReadBytes(legInstrumentId.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSide.rest, 2) IN IF ~legRatio.ok THEN Fail ELSE
    LET legId == ReadBytes(legRatio.rest, 1) IN IF ~legId.ok THEN Fail ELSE
    Ok([ legType         |-> legType.value,
         legInstrumentId |-> legInstrumentId.value,
         legSide         |-> legSide.value,
         legRatio        |-> legRatio.value,
         legId           |-> legId.value ], legId.rest)

ZeroComplexDirectoryLegs ==
    [ legType         |-> [i \in 1 .. 1 |-> 0],
      legInstrumentId |-> [i \in 1 .. 4 |-> 0],
      legSide         |-> [i \in 1 .. 1 |-> 0],
      legRatio        |-> [i \in 1 .. 2 |-> 0],
      legId           |-> [i \in 1 .. 1 |-> 0] ]

(* Complex Directory Legs at zero, then each field in turn at the values it is checked at *)
CheckedComplexDirectoryLegs ==
    { ZeroComplexDirectoryLegs }
        \cup { [ZeroComplexDirectoryLegs EXCEPT !.legType = one] : one \in Sample(1) }
        \cup { [ZeroComplexDirectoryLegs EXCEPT !.legInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexDirectoryLegs EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroComplexDirectoryLegs EXCEPT !.legRatio = one] : one \in Sample(2) }
        \cup { [ZeroComplexDirectoryLegs EXCEPT !.legId = one] : one \in Sample(1) }

(* A run of Complex Directory Legs, written one after another *)
RECURSIVE EncodeComplexDirectoryLegsList(_)
EncodeComplexDirectoryLegsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeComplexDirectoryLegs(Head(messages)) \o EncodeComplexDirectoryLegsList(Tail(messages))

(* As many Complex Directory Legs as the field that counts them says *)
RECURSIVE ReadComplexDirectoryLegsList(_, _)
ReadComplexDirectoryLegsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeComplexDirectoryLegs(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadComplexDirectoryLegsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Complex Directory Legs of each kind, for the lists that carry them *)
OneComplexDirectoryLegs == { ZeroComplexDirectoryLegs }

(***************************************************************************)
(* Complex Instrument Directory Message                                    *)
(***************************************************************************)

ComplexInstrumentDirectoryMessage ==
    [ timestamp            : Sample(8),
      productId            : Sample(2),
      productName          : Sample(13),
      instrumentId         : Sample(4),
      reserved1            : Sample(1),
      complexDirectoryLegs : SampleLists(OneComplexDirectoryLegs) ]

EncodeComplexInstrumentDirectoryMessage(message) ==
    message.timestamp
        \o message.productId
        \o message.productName
        \o message.instrumentId
        \o message.reserved1
        \o EncodeUIntBE(Len(message.complexDirectoryLegs), 1)
        \o EncodeComplexDirectoryLegsList(message.complexDirectoryLegs)

DecodeComplexInstrumentDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET productId == ReadBytes(timestamp.rest, 2) IN IF ~productId.ok THEN Fail ELSE
    LET productName == ReadBytes(productId.rest, 13) IN IF ~productName.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(productName.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(instrumentId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET numLegs == ReadUIntBE(reserved1.rest, 1) IN IF ~numLegs.ok THEN Fail ELSE
    LET complexDirectoryLegs == ReadComplexDirectoryLegsList(numLegs.rest, numLegs.value) IN IF ~complexDirectoryLegs.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         productId            |-> productId.value,
         productName          |-> productName.value,
         instrumentId         |-> instrumentId.value,
         reserved1            |-> reserved1.value,
         complexDirectoryLegs |-> complexDirectoryLegs.value ], complexDirectoryLegs.rest)

ZeroComplexInstrumentDirectoryMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      productId            |-> [i \in 1 .. 2 |-> 0],
      productName          |-> [i \in 1 .. 13 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      reserved1            |-> [i \in 1 .. 1 |-> 0],
      complexDirectoryLegs |-> << >> ]

(* Complex Instrument Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedComplexInstrumentDirectoryMessage ==
    { ZeroComplexInstrumentDirectoryMessage }
        \cup { [ZeroComplexInstrumentDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroComplexInstrumentDirectoryMessage EXCEPT !.productId = one] : one \in Sample(2) }
        \cup { [ZeroComplexInstrumentDirectoryMessage EXCEPT !.productName = one] : one \in Sample(13) }
        \cup { [ZeroComplexInstrumentDirectoryMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroComplexInstrumentDirectoryMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroComplexInstrumentDirectoryMessage EXCEPT !.complexDirectoryLegs = one] : one \in SampleLists(OneComplexDirectoryLegs) }

(***************************************************************************)
(* Instrument Trading Action Message: 15 bytes                             *)
(***************************************************************************)

InstrumentTradingActionMessage ==
    [ timestamp    : Sample(8),
      productId    : Sample(2),
      instrumentId : Sample(4),
      tradingState : Sample(1) ]

EncodeInstrumentTradingActionMessage(message) ==
    message.timestamp
        \o message.productId
        \o message.instrumentId
        \o message.tradingState

DecodeInstrumentTradingActionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET productId == ReadBytes(timestamp.rest, 2) IN IF ~productId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(productId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET tradingState == ReadBytes(instrumentId.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         productId    |-> productId.value,
         instrumentId |-> instrumentId.value,
         tradingState |-> tradingState.value ], tradingState.rest)

ZeroInstrumentTradingActionMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      productId    |-> [i \in 1 .. 2 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      tradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentTradingActionMessage ==
    { ZeroInstrumentTradingActionMessage }
        \cup { [ZeroInstrumentTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentTradingActionMessage EXCEPT !.productId = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentTradingActionMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentTradingActionMessage EXCEPT !.tradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Flex Dac Legs: 8 bytes                                                  *)
(***************************************************************************)

FlexDacLegs ==
    [ reserved8 : Sample(8) ]

EncodeFlexDacLegs(message) ==
    message.reserved8

DecodeFlexDacLegs(bytes) ==
    LET reserved8 == ReadBytes(bytes, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ reserved8 |-> reserved8.value ], reserved8.rest)

ZeroFlexDacLegs ==
    [ reserved8 |-> [i \in 1 .. 8 |-> 0] ]

(* Flex Dac Legs at zero, then each field in turn at the values it is checked at *)
CheckedFlexDacLegs ==
    { ZeroFlexDacLegs }
        \cup { [ZeroFlexDacLegs EXCEPT !.reserved8 = one] : one \in Sample(8) }

(* A run of Flex Dac Legs, written one after another *)
RECURSIVE EncodeFlexDacLegsList(_)
EncodeFlexDacLegsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFlexDacLegs(Head(messages)) \o EncodeFlexDacLegsList(Tail(messages))

(* As many Flex Dac Legs as the field that counts them says *)
RECURSIVE ReadFlexDacLegsList(_, _)
ReadFlexDacLegsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFlexDacLegs(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFlexDacLegsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Flex Dac Legs of each kind, for the lists that carry them *)
OneFlexDacLegs == { ZeroFlexDacLegs }

(***************************************************************************)
(* Auction Notification Message                                            *)
(***************************************************************************)

AuctionNotificationMessage ==
    [ timestamp         : Sample(8),
      instrumentType    : Sample(1),
      instrumentId      : Sample(4),
      auctionId         : Sample(4),
      orderType         : Sample(1),
      side              : Sample(1),
      price             : Sample(8),
      quantity          : Sample(4),
      execFlag          : Sample(1),
      orderCapacity     : Sample(1),
      firmId            : Sample(4),
      occAccount        : Sample(4),
      cmta              : Sample(4),
      auctionEvent      : Sample(1),
      auctionType       : Sample(1),
      auctionDuration   : Sample(4),
      bestResponsePrice : Sample(8),
      bestResponseSize  : Sample(4),
      reserved9         : Sample(9),
      flexDacLegs       : SampleLists(OneFlexDacLegs) ]

EncodeAuctionNotificationMessage(message) ==
    message.timestamp
        \o message.instrumentType
        \o message.instrumentId
        \o message.auctionId
        \o message.orderType
        \o message.side
        \o message.price
        \o message.quantity
        \o message.execFlag
        \o message.orderCapacity
        \o message.firmId
        \o message.occAccount
        \o message.cmta
        \o message.auctionEvent
        \o message.auctionType
        \o message.auctionDuration
        \o message.bestResponsePrice
        \o message.bestResponseSize
        \o message.reserved9
        \o EncodeUIntBE(Len(message.flexDacLegs), 1)
        \o EncodeFlexDacLegsList(message.flexDacLegs)

DecodeAuctionNotificationMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(timestamp.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentType.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(instrumentId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET orderType == ReadBytes(auctionId.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET side == ReadBytes(orderType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET execFlag == ReadBytes(quantity.rest, 1) IN IF ~execFlag.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(execFlag.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET firmId == ReadBytes(orderCapacity.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET occAccount == ReadBytes(firmId.rest, 4) IN IF ~occAccount.ok THEN Fail ELSE
    LET cmta == ReadBytes(occAccount.rest, 4) IN IF ~cmta.ok THEN Fail ELSE
    LET auctionEvent == ReadBytes(cmta.rest, 1) IN IF ~auctionEvent.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionEvent.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionDuration == ReadBytes(auctionType.rest, 4) IN IF ~auctionDuration.ok THEN Fail ELSE
    LET bestResponsePrice == ReadBytes(auctionDuration.rest, 8) IN IF ~bestResponsePrice.ok THEN Fail ELSE
    LET bestResponseSize == ReadBytes(bestResponsePrice.rest, 4) IN IF ~bestResponseSize.ok THEN Fail ELSE
    LET reserved9 == ReadBytes(bestResponseSize.rest, 9) IN IF ~reserved9.ok THEN Fail ELSE
    LET numberOfFlexDacLegs == ReadUIntBE(reserved9.rest, 1) IN IF ~numberOfFlexDacLegs.ok THEN Fail ELSE
    LET flexDacLegs == ReadFlexDacLegsList(numberOfFlexDacLegs.rest, numberOfFlexDacLegs.value) IN IF ~flexDacLegs.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         instrumentType    |-> instrumentType.value,
         instrumentId      |-> instrumentId.value,
         auctionId         |-> auctionId.value,
         orderType         |-> orderType.value,
         side              |-> side.value,
         price             |-> price.value,
         quantity          |-> quantity.value,
         execFlag          |-> execFlag.value,
         orderCapacity     |-> orderCapacity.value,
         firmId            |-> firmId.value,
         occAccount        |-> occAccount.value,
         cmta              |-> cmta.value,
         auctionEvent      |-> auctionEvent.value,
         auctionType       |-> auctionType.value,
         auctionDuration   |-> auctionDuration.value,
         bestResponsePrice |-> bestResponsePrice.value,
         bestResponseSize  |-> bestResponseSize.value,
         reserved9         |-> reserved9.value,
         flexDacLegs       |-> flexDacLegs.value ], flexDacLegs.rest)

ZeroAuctionNotificationMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      instrumentType    |-> [i \in 1 .. 1 |-> 0],
      instrumentId      |-> [i \in 1 .. 4 |-> 0],
      auctionId         |-> [i \in 1 .. 4 |-> 0],
      orderType         |-> [i \in 1 .. 1 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      execFlag          |-> [i \in 1 .. 1 |-> 0],
      orderCapacity     |-> [i \in 1 .. 1 |-> 0],
      firmId            |-> [i \in 1 .. 4 |-> 0],
      occAccount        |-> [i \in 1 .. 4 |-> 0],
      cmta              |-> [i \in 1 .. 4 |-> 0],
      auctionEvent      |-> [i \in 1 .. 1 |-> 0],
      auctionType       |-> [i \in 1 .. 1 |-> 0],
      auctionDuration   |-> [i \in 1 .. 4 |-> 0],
      bestResponsePrice |-> [i \in 1 .. 8 |-> 0],
      bestResponseSize  |-> [i \in 1 .. 4 |-> 0],
      reserved9         |-> [i \in 1 .. 9 |-> 0],
      flexDacLegs       |-> << >> ]

(* Auction Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionNotificationMessage ==
    { ZeroAuctionNotificationMessage }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.execFlag = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.occAccount = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.cmta = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionEvent = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.auctionDuration = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.bestResponsePrice = one] : one \in Sample(8) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.bestResponseSize = one] : one \in Sample(4) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.reserved9 = one] : one \in Sample(9) }
        \cup { [ZeroAuctionNotificationMessage EXCEPT !.flexDacLegs = one] : one \in SampleLists(OneFlexDacLegs) }

(***************************************************************************)
(* Flex Legs: 8 bytes                                                      *)
(***************************************************************************)

FlexLegs ==
    [ reserved8 : Sample(8) ]

EncodeFlexLegs(message) ==
    message.reserved8

DecodeFlexLegs(bytes) ==
    LET reserved8 == ReadBytes(bytes, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ reserved8 |-> reserved8.value ], reserved8.rest)

ZeroFlexLegs ==
    [ reserved8 |-> [i \in 1 .. 8 |-> 0] ]

(* Flex Legs at zero, then each field in turn at the values it is checked at *)
CheckedFlexLegs ==
    { ZeroFlexLegs }
        \cup { [ZeroFlexLegs EXCEPT !.reserved8 = one] : one \in Sample(8) }

(* A run of Flex Legs, written one after another *)
RECURSIVE EncodeFlexLegsList(_)
EncodeFlexLegsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFlexLegs(Head(messages)) \o EncodeFlexLegsList(Tail(messages))

(* As many Flex Legs as the field that counts them says *)
RECURSIVE ReadFlexLegsList(_, _)
ReadFlexLegsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFlexLegs(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFlexLegsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Flex Legs of each kind, for the lists that carry them *)
OneFlexLegs == { ZeroFlexLegs }

(***************************************************************************)
(* Order Accepted Long Form Message                                        *)
(***************************************************************************)

OrderAcceptedLongFormMessage ==
    [ timestamp          : Sample(8),
      firmId             : Sample(4),
      instrumentId       : Sample(4),
      orderId            : Sample(8),
      clOrdId            : Sample(16),
      cmta               : Sample(4),
      clearingAccount    : Sample(4),
      occAccount         : Sample(4),
      custAcct           : Sample(10),
      preferredParty     : Sample(3),
      aloInst            : Sample(1),
      iso                : Sample(1),
      side               : Sample(1),
      orderType          : Sample(1),
      price              : Sample(8),
      quantity           : Sample(4),
      minQty             : Sample(4),
      tif                : Sample(1),
      capacity           : Sample(1),
      auctionType        : Sample(1),
      auctionId          : Sample(4),
      disclosureMask     : Sample(1),
      priceProtection    : Sample(1),
      displayQty         : Sample(2),
      displayWhen        : Sample(1),
      displayMethod      : Sample(1),
      displayLowQty      : Sample(2),
      displayHighQty     : Sample(2),
      positionEffectMask : Sample(2),
      stockLegShortSale  : Sample(1),
      stockLegMpid       : Sample(4),
      stockCapacity      : Sample(1),
      reserved9          : Sample(9),
      flexLegs           : SampleLists(OneFlexLegs) ]

EncodeOrderAcceptedLongFormMessage(message) ==
    message.timestamp
        \o message.firmId
        \o message.instrumentId
        \o message.orderId
        \o message.clOrdId
        \o message.cmta
        \o message.clearingAccount
        \o message.occAccount
        \o message.custAcct
        \o message.preferredParty
        \o message.aloInst
        \o message.iso
        \o message.side
        \o message.orderType
        \o message.price
        \o message.quantity
        \o message.minQty
        \o message.tif
        \o message.capacity
        \o message.auctionType
        \o message.auctionId
        \o message.disclosureMask
        \o message.priceProtection
        \o message.displayQty
        \o message.displayWhen
        \o message.displayMethod
        \o message.displayLowQty
        \o message.displayHighQty
        \o message.positionEffectMask
        \o message.stockLegShortSale
        \o message.stockLegMpid
        \o message.stockCapacity
        \o message.reserved9
        \o EncodeUIntBE(Len(message.flexLegs), 1)
        \o EncodeFlexLegsList(message.flexLegs)

DecodeOrderAcceptedLongFormMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET firmId == ReadBytes(timestamp.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(firmId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 16) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cmta == ReadBytes(clOrdId.rest, 4) IN IF ~cmta.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(cmta.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET occAccount == ReadBytes(clearingAccount.rest, 4) IN IF ~occAccount.ok THEN Fail ELSE
    LET custAcct == ReadBytes(occAccount.rest, 10) IN IF ~custAcct.ok THEN Fail ELSE
    LET preferredParty == ReadBytes(custAcct.rest, 3) IN IF ~preferredParty.ok THEN Fail ELSE
    LET aloInst == ReadBytes(preferredParty.rest, 1) IN IF ~aloInst.ok THEN Fail ELSE
    LET iso == ReadBytes(aloInst.rest, 1) IN IF ~iso.ok THEN Fail ELSE
    LET side == ReadBytes(iso.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderType == ReadBytes(side.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET price == ReadBytes(orderType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET minQty == ReadBytes(quantity.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET tif == ReadBytes(minQty.rest, 1) IN IF ~tif.ok THEN Fail ELSE
    LET capacity == ReadBytes(tif.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET auctionType == ReadBytes(capacity.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionId == ReadBytes(auctionType.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET disclosureMask == ReadBytes(auctionId.rest, 1) IN IF ~disclosureMask.ok THEN Fail ELSE
    LET priceProtection == ReadBytes(disclosureMask.rest, 1) IN IF ~priceProtection.ok THEN Fail ELSE
    LET displayQty == ReadBytes(priceProtection.rest, 2) IN IF ~displayQty.ok THEN Fail ELSE
    LET displayWhen == ReadBytes(displayQty.rest, 1) IN IF ~displayWhen.ok THEN Fail ELSE
    LET displayMethod == ReadBytes(displayWhen.rest, 1) IN IF ~displayMethod.ok THEN Fail ELSE
    LET displayLowQty == ReadBytes(displayMethod.rest, 2) IN IF ~displayLowQty.ok THEN Fail ELSE
    LET displayHighQty == ReadBytes(displayLowQty.rest, 2) IN IF ~displayHighQty.ok THEN Fail ELSE
    LET positionEffectMask == ReadBytes(displayHighQty.rest, 2) IN IF ~positionEffectMask.ok THEN Fail ELSE
    LET stockLegShortSale == ReadBytes(positionEffectMask.rest, 1) IN IF ~stockLegShortSale.ok THEN Fail ELSE
    LET stockLegMpid == ReadBytes(stockLegShortSale.rest, 4) IN IF ~stockLegMpid.ok THEN Fail ELSE
    LET stockCapacity == ReadBytes(stockLegMpid.rest, 1) IN IF ~stockCapacity.ok THEN Fail ELSE
    LET reserved9 == ReadBytes(stockCapacity.rest, 9) IN IF ~reserved9.ok THEN Fail ELSE
    LET numberOfFlexLegs == ReadUIntBE(reserved9.rest, 1) IN IF ~numberOfFlexLegs.ok THEN Fail ELSE
    LET flexLegs == ReadFlexLegsList(numberOfFlexLegs.rest, numberOfFlexLegs.value) IN IF ~flexLegs.ok THEN Fail ELSE
    Ok([ timestamp          |-> timestamp.value,
         firmId             |-> firmId.value,
         instrumentId       |-> instrumentId.value,
         orderId            |-> orderId.value,
         clOrdId            |-> clOrdId.value,
         cmta               |-> cmta.value,
         clearingAccount    |-> clearingAccount.value,
         occAccount         |-> occAccount.value,
         custAcct           |-> custAcct.value,
         preferredParty     |-> preferredParty.value,
         aloInst            |-> aloInst.value,
         iso                |-> iso.value,
         side               |-> side.value,
         orderType          |-> orderType.value,
         price              |-> price.value,
         quantity           |-> quantity.value,
         minQty             |-> minQty.value,
         tif                |-> tif.value,
         capacity           |-> capacity.value,
         auctionType        |-> auctionType.value,
         auctionId          |-> auctionId.value,
         disclosureMask     |-> disclosureMask.value,
         priceProtection    |-> priceProtection.value,
         displayQty         |-> displayQty.value,
         displayWhen        |-> displayWhen.value,
         displayMethod      |-> displayMethod.value,
         displayLowQty      |-> displayLowQty.value,
         displayHighQty     |-> displayHighQty.value,
         positionEffectMask |-> positionEffectMask.value,
         stockLegShortSale  |-> stockLegShortSale.value,
         stockLegMpid       |-> stockLegMpid.value,
         stockCapacity      |-> stockCapacity.value,
         reserved9          |-> reserved9.value,
         flexLegs           |-> flexLegs.value ], flexLegs.rest)

ZeroOrderAcceptedLongFormMessage ==
    [ timestamp          |-> [i \in 1 .. 8 |-> 0],
      firmId             |-> [i \in 1 .. 4 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      clOrdId            |-> [i \in 1 .. 16 |-> 0],
      cmta               |-> [i \in 1 .. 4 |-> 0],
      clearingAccount    |-> [i \in 1 .. 4 |-> 0],
      occAccount         |-> [i \in 1 .. 4 |-> 0],
      custAcct           |-> [i \in 1 .. 10 |-> 0],
      preferredParty     |-> [i \in 1 .. 3 |-> 0],
      aloInst            |-> [i \in 1 .. 1 |-> 0],
      iso                |-> [i \in 1 .. 1 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      orderType          |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      quantity           |-> [i \in 1 .. 4 |-> 0],
      minQty             |-> [i \in 1 .. 4 |-> 0],
      tif                |-> [i \in 1 .. 1 |-> 0],
      capacity           |-> [i \in 1 .. 1 |-> 0],
      auctionType        |-> [i \in 1 .. 1 |-> 0],
      auctionId          |-> [i \in 1 .. 4 |-> 0],
      disclosureMask     |-> [i \in 1 .. 1 |-> 0],
      priceProtection    |-> [i \in 1 .. 1 |-> 0],
      displayQty         |-> [i \in 1 .. 2 |-> 0],
      displayWhen        |-> [i \in 1 .. 1 |-> 0],
      displayMethod      |-> [i \in 1 .. 1 |-> 0],
      displayLowQty      |-> [i \in 1 .. 2 |-> 0],
      displayHighQty     |-> [i \in 1 .. 2 |-> 0],
      positionEffectMask |-> [i \in 1 .. 2 |-> 0],
      stockLegShortSale  |-> [i \in 1 .. 1 |-> 0],
      stockLegMpid       |-> [i \in 1 .. 4 |-> 0],
      stockCapacity      |-> [i \in 1 .. 1 |-> 0],
      reserved9          |-> [i \in 1 .. 9 |-> 0],
      flexLegs           |-> << >> ]

(* Order Accepted Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcceptedLongFormMessage ==
    { ZeroOrderAcceptedLongFormMessage }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.clOrdId = one] : one \in Sample(16) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.cmta = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.occAccount = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.custAcct = one] : one \in Sample(10) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.preferredParty = one] : one \in Sample(3) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.aloInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.iso = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.tif = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.disclosureMask = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.priceProtection = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.displayQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.displayWhen = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.displayMethod = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.displayLowQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.displayHighQty = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.positionEffectMask = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.stockLegShortSale = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.stockLegMpid = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.stockCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.reserved9 = one] : one \in Sample(9) }
        \cup { [ZeroOrderAcceptedLongFormMessage EXCEPT !.flexLegs = one] : one \in SampleLists(OneFlexLegs) }

(***************************************************************************)
(* Order Accepted Short Form Message: 65 bytes                             *)
(***************************************************************************)

OrderAcceptedShortFormMessage ==
    [ timestamp          : Sample(8),
      firmId             : Sample(4),
      instrumentId       : Sample(4),
      orderId            : Sample(8),
      clOrdId            : Sample(16),
      aloInst            : Sample(1),
      iso                : Sample(1),
      side               : Sample(1),
      orderType          : Sample(1),
      price              : Sample(8),
      quantityShort      : Sample(2),
      tif                : Sample(1),
      capacity           : Sample(1),
      auctionType        : Sample(1),
      auctionId          : Sample(4),
      priceProtection    : Sample(1),
      positionEffectMask : Sample(2),
      stockCapacity      : Sample(1) ]

EncodeOrderAcceptedShortFormMessage(message) ==
    message.timestamp
        \o message.firmId
        \o message.instrumentId
        \o message.orderId
        \o message.clOrdId
        \o message.aloInst
        \o message.iso
        \o message.side
        \o message.orderType
        \o message.price
        \o message.quantityShort
        \o message.tif
        \o message.capacity
        \o message.auctionType
        \o message.auctionId
        \o message.priceProtection
        \o message.positionEffectMask
        \o message.stockCapacity

DecodeOrderAcceptedShortFormMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET firmId == ReadBytes(timestamp.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(firmId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 16) IN IF ~clOrdId.ok THEN Fail ELSE
    LET aloInst == ReadBytes(clOrdId.rest, 1) IN IF ~aloInst.ok THEN Fail ELSE
    LET iso == ReadBytes(aloInst.rest, 1) IN IF ~iso.ok THEN Fail ELSE
    LET side == ReadBytes(iso.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderType == ReadBytes(side.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET price == ReadBytes(orderType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantityShort == ReadBytes(price.rest, 2) IN IF ~quantityShort.ok THEN Fail ELSE
    LET tif == ReadBytes(quantityShort.rest, 1) IN IF ~tif.ok THEN Fail ELSE
    LET capacity == ReadBytes(tif.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET auctionType == ReadBytes(capacity.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionId == ReadBytes(auctionType.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET priceProtection == ReadBytes(auctionId.rest, 1) IN IF ~priceProtection.ok THEN Fail ELSE
    LET positionEffectMask == ReadBytes(priceProtection.rest, 2) IN IF ~positionEffectMask.ok THEN Fail ELSE
    LET stockCapacity == ReadBytes(positionEffectMask.rest, 1) IN IF ~stockCapacity.ok THEN Fail ELSE
    Ok([ timestamp          |-> timestamp.value,
         firmId             |-> firmId.value,
         instrumentId       |-> instrumentId.value,
         orderId            |-> orderId.value,
         clOrdId            |-> clOrdId.value,
         aloInst            |-> aloInst.value,
         iso                |-> iso.value,
         side               |-> side.value,
         orderType          |-> orderType.value,
         price              |-> price.value,
         quantityShort      |-> quantityShort.value,
         tif                |-> tif.value,
         capacity           |-> capacity.value,
         auctionType        |-> auctionType.value,
         auctionId          |-> auctionId.value,
         priceProtection    |-> priceProtection.value,
         positionEffectMask |-> positionEffectMask.value,
         stockCapacity      |-> stockCapacity.value ], stockCapacity.rest)

ZeroOrderAcceptedShortFormMessage ==
    [ timestamp          |-> [i \in 1 .. 8 |-> 0],
      firmId             |-> [i \in 1 .. 4 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      clOrdId            |-> [i \in 1 .. 16 |-> 0],
      aloInst            |-> [i \in 1 .. 1 |-> 0],
      iso                |-> [i \in 1 .. 1 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      orderType          |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      quantityShort      |-> [i \in 1 .. 2 |-> 0],
      tif                |-> [i \in 1 .. 1 |-> 0],
      capacity           |-> [i \in 1 .. 1 |-> 0],
      auctionType        |-> [i \in 1 .. 1 |-> 0],
      auctionId          |-> [i \in 1 .. 4 |-> 0],
      priceProtection    |-> [i \in 1 .. 1 |-> 0],
      positionEffectMask |-> [i \in 1 .. 2 |-> 0],
      stockCapacity      |-> [i \in 1 .. 1 |-> 0] ]

(* Order Accepted Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcceptedShortFormMessage ==
    { ZeroOrderAcceptedShortFormMessage }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.clOrdId = one] : one \in Sample(16) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.aloInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.iso = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.quantityShort = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.tif = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.priceProtection = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.positionEffectMask = one] : one \in Sample(2) }
        \cup { [ZeroOrderAcceptedShortFormMessage EXCEPT !.stockCapacity = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Replaced Message: 100 bytes                                       *)
(***************************************************************************)

OrderReplacedMessage ==
    [ timestamp          : Sample(8),
      firmId             : Sample(4),
      instrumentId       : Sample(4),
      origOrderId        : Sample(8),
      orderId            : Sample(8),
      origClOrdId        : Sample(16),
      clOrdId            : Sample(16),
      aloInst            : Sample(1),
      iso                : Sample(1),
      side               : Sample(1),
      orderType          : Sample(1),
      price              : Sample(8),
      quantity           : Sample(4),
      tif                : Sample(1),
      custAcct           : Sample(10),
      capacity           : Sample(1),
      auctionType        : Sample(1),
      auctionId          : Sample(4),
      positionEffectMask : Sample(2),
      priceProtection    : Sample(1) ]

EncodeOrderReplacedMessage(message) ==
    message.timestamp
        \o message.firmId
        \o message.instrumentId
        \o message.origOrderId
        \o message.orderId
        \o message.origClOrdId
        \o message.clOrdId
        \o message.aloInst
        \o message.iso
        \o message.side
        \o message.orderType
        \o message.price
        \o message.quantity
        \o message.tif
        \o message.custAcct
        \o message.capacity
        \o message.auctionType
        \o message.auctionId
        \o message.positionEffectMask
        \o message.priceProtection

DecodeOrderReplacedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET firmId == ReadBytes(timestamp.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(firmId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET origOrderId == ReadBytes(instrumentId.rest, 8) IN IF ~origOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(origOrderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET origClOrdId == ReadBytes(orderId.rest, 16) IN IF ~origClOrdId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(origClOrdId.rest, 16) IN IF ~clOrdId.ok THEN Fail ELSE
    LET aloInst == ReadBytes(clOrdId.rest, 1) IN IF ~aloInst.ok THEN Fail ELSE
    LET iso == ReadBytes(aloInst.rest, 1) IN IF ~iso.ok THEN Fail ELSE
    LET side == ReadBytes(iso.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderType == ReadBytes(side.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET price == ReadBytes(orderType.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET tif == ReadBytes(quantity.rest, 1) IN IF ~tif.ok THEN Fail ELSE
    LET custAcct == ReadBytes(tif.rest, 10) IN IF ~custAcct.ok THEN Fail ELSE
    LET capacity == ReadBytes(custAcct.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET auctionType == ReadBytes(capacity.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionId == ReadBytes(auctionType.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET positionEffectMask == ReadBytes(auctionId.rest, 2) IN IF ~positionEffectMask.ok THEN Fail ELSE
    LET priceProtection == ReadBytes(positionEffectMask.rest, 1) IN IF ~priceProtection.ok THEN Fail ELSE
    Ok([ timestamp          |-> timestamp.value,
         firmId             |-> firmId.value,
         instrumentId       |-> instrumentId.value,
         origOrderId        |-> origOrderId.value,
         orderId            |-> orderId.value,
         origClOrdId        |-> origClOrdId.value,
         clOrdId            |-> clOrdId.value,
         aloInst            |-> aloInst.value,
         iso                |-> iso.value,
         side               |-> side.value,
         orderType          |-> orderType.value,
         price              |-> price.value,
         quantity           |-> quantity.value,
         tif                |-> tif.value,
         custAcct           |-> custAcct.value,
         capacity           |-> capacity.value,
         auctionType        |-> auctionType.value,
         auctionId          |-> auctionId.value,
         positionEffectMask |-> positionEffectMask.value,
         priceProtection    |-> priceProtection.value ], priceProtection.rest)

ZeroOrderReplacedMessage ==
    [ timestamp          |-> [i \in 1 .. 8 |-> 0],
      firmId             |-> [i \in 1 .. 4 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      origOrderId        |-> [i \in 1 .. 8 |-> 0],
      orderId            |-> [i \in 1 .. 8 |-> 0],
      origClOrdId        |-> [i \in 1 .. 16 |-> 0],
      clOrdId            |-> [i \in 1 .. 16 |-> 0],
      aloInst            |-> [i \in 1 .. 1 |-> 0],
      iso                |-> [i \in 1 .. 1 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      orderType          |-> [i \in 1 .. 1 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      quantity           |-> [i \in 1 .. 4 |-> 0],
      tif                |-> [i \in 1 .. 1 |-> 0],
      custAcct           |-> [i \in 1 .. 10 |-> 0],
      capacity           |-> [i \in 1 .. 1 |-> 0],
      auctionType        |-> [i \in 1 .. 1 |-> 0],
      auctionId          |-> [i \in 1 .. 4 |-> 0],
      positionEffectMask |-> [i \in 1 .. 2 |-> 0],
      priceProtection    |-> [i \in 1 .. 1 |-> 0] ]

(* Order Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplacedMessage ==
    { ZeroOrderReplacedMessage }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.origOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.origClOrdId = one] : one \in Sample(16) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.clOrdId = one] : one \in Sample(16) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.aloInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.iso = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.tif = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.custAcct = one] : one \in Sample(10) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.positionEffectMask = one] : one \in Sample(2) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.priceProtection = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Canceled Message: 41 bytes                                        *)
(***************************************************************************)

OrderCanceledMessage ==
    [ timestamp    : Sample(8),
      firmId       : Sample(4),
      instrumentId : Sample(4),
      orderId      : Sample(8),
      clOrdId      : Sample(16),
      cancelReason : Sample(1) ]

EncodeOrderCanceledMessage(message) ==
    message.timestamp
        \o message.firmId
        \o message.instrumentId
        \o message.orderId
        \o message.clOrdId
        \o message.cancelReason

DecodeOrderCanceledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET firmId == ReadBytes(timestamp.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(firmId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderId == ReadBytes(instrumentId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 16) IN IF ~clOrdId.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(clOrdId.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         firmId       |-> firmId.value,
         instrumentId |-> instrumentId.value,
         orderId      |-> orderId.value,
         clOrdId      |-> clOrdId.value,
         cancelReason |-> cancelReason.value ], cancelReason.rest)

ZeroOrderCanceledMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      firmId       |-> [i \in 1 .. 4 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      orderId      |-> [i \in 1 .. 8 |-> 0],
      clOrdId      |-> [i \in 1 .. 16 |-> 0],
      cancelReason |-> [i \in 1 .. 1 |-> 0] ]

(* Order Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCanceledMessage ==
    { ZeroOrderCanceledMessage }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.clOrdId = one] : one \in Sample(16) }
        \cup { [ZeroOrderCanceledMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Executed Message: 72 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ timestamp         : Sample(8),
      firmId            : Sample(4),
      productId         : Sample(2),
      ordExecType       : Sample(1),
      instrumentId      : Sample(4),
      legInstrumentId   : Sample(4),
      legId             : Sample(1),
      auctionType       : Sample(1),
      orderId           : Sample(8),
      clOrdId           : Sample(16),
      crossId           : Sample(4),
      matchId           : Sample(4),
      side              : Sample(1),
      stockLegShortSale : Sample(1),
      price             : Sample(8),
      quantity          : Sample(4),
      liquidityInd      : Sample(1) ]

EncodeOrderExecutedMessage(message) ==
    message.timestamp
        \o message.firmId
        \o message.productId
        \o message.ordExecType
        \o message.instrumentId
        \o message.legInstrumentId
        \o message.legId
        \o message.auctionType
        \o message.orderId
        \o message.clOrdId
        \o message.crossId
        \o message.matchId
        \o message.side
        \o message.stockLegShortSale
        \o message.price
        \o message.quantity
        \o message.liquidityInd

DecodeOrderExecutedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET firmId == ReadBytes(timestamp.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET productId == ReadBytes(firmId.rest, 2) IN IF ~productId.ok THEN Fail ELSE
    LET ordExecType == ReadBytes(productId.rest, 1) IN IF ~ordExecType.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(ordExecType.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET legInstrumentId == ReadBytes(instrumentId.rest, 4) IN IF ~legInstrumentId.ok THEN Fail ELSE
    LET legId == ReadBytes(legInstrumentId.rest, 1) IN IF ~legId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(legId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET orderId == ReadBytes(auctionType.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 16) IN IF ~clOrdId.ok THEN Fail ELSE
    LET crossId == ReadBytes(clOrdId.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET matchId == ReadBytes(crossId.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    LET side == ReadBytes(matchId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET stockLegShortSale == ReadBytes(side.rest, 1) IN IF ~stockLegShortSale.ok THEN Fail ELSE
    LET price == ReadBytes(stockLegShortSale.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET liquidityInd == ReadBytes(quantity.rest, 1) IN IF ~liquidityInd.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         firmId            |-> firmId.value,
         productId         |-> productId.value,
         ordExecType       |-> ordExecType.value,
         instrumentId      |-> instrumentId.value,
         legInstrumentId   |-> legInstrumentId.value,
         legId             |-> legId.value,
         auctionType       |-> auctionType.value,
         orderId           |-> orderId.value,
         clOrdId           |-> clOrdId.value,
         crossId           |-> crossId.value,
         matchId           |-> matchId.value,
         side              |-> side.value,
         stockLegShortSale |-> stockLegShortSale.value,
         price             |-> price.value,
         quantity          |-> quantity.value,
         liquidityInd      |-> liquidityInd.value ], liquidityInd.rest)

ZeroOrderExecutedMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      firmId            |-> [i \in 1 .. 4 |-> 0],
      productId         |-> [i \in 1 .. 2 |-> 0],
      ordExecType       |-> [i \in 1 .. 1 |-> 0],
      instrumentId      |-> [i \in 1 .. 4 |-> 0],
      legInstrumentId   |-> [i \in 1 .. 4 |-> 0],
      legId             |-> [i \in 1 .. 1 |-> 0],
      auctionType       |-> [i \in 1 .. 1 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      clOrdId           |-> [i \in 1 .. 16 |-> 0],
      crossId           |-> [i \in 1 .. 4 |-> 0],
      matchId           |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      stockLegShortSale |-> [i \in 1 .. 1 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      liquidityInd      |-> [i \in 1 .. 1 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.productId = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.ordExecType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.legInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.legId = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.clOrdId = one] : one \in Sample(16) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.stockLegShortSale = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.liquidityInd = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Details Message: 107 bytes                                        *)
(***************************************************************************)

TradeDetailsMessage ==
    [ timestamp         : Sample(8),
      firmId            : Sample(4),
      productId         : Sample(2),
      ordExecType       : Sample(1),
      instrumentId      : Sample(4),
      legInstrumentId   : Sample(4),
      legId             : Sample(1),
      transType         : Sample(1),
      eventSource       : Sample(1),
      auctionType       : Sample(1),
      orderId           : Sample(8),
      clOrdId           : Sample(16),
      crossId           : Sample(4),
      matchId           : Sample(4),
      refMatchId        : Sample(4),
      side              : Sample(1),
      stockLegShortSale : Sample(1),
      price             : Sample(8),
      quantity          : Sample(4),
      liquidityInd      : Sample(1),
      cmta              : Sample(4),
      clearingAccount   : Sample(4),
      occAccount        : Sample(4),
      custAcct          : Sample(10),
      stockVenue        : Sample(1),
      stockLegMpid      : Sample(4),
      capacity          : Sample(1),
      openClose         : Sample(1) ]

EncodeTradeDetailsMessage(message) ==
    message.timestamp
        \o message.firmId
        \o message.productId
        \o message.ordExecType
        \o message.instrumentId
        \o message.legInstrumentId
        \o message.legId
        \o message.transType
        \o message.eventSource
        \o message.auctionType
        \o message.orderId
        \o message.clOrdId
        \o message.crossId
        \o message.matchId
        \o message.refMatchId
        \o message.side
        \o message.stockLegShortSale
        \o message.price
        \o message.quantity
        \o message.liquidityInd
        \o message.cmta
        \o message.clearingAccount
        \o message.occAccount
        \o message.custAcct
        \o message.stockVenue
        \o message.stockLegMpid
        \o message.capacity
        \o message.openClose

DecodeTradeDetailsMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET firmId == ReadBytes(timestamp.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET productId == ReadBytes(firmId.rest, 2) IN IF ~productId.ok THEN Fail ELSE
    LET ordExecType == ReadBytes(productId.rest, 1) IN IF ~ordExecType.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(ordExecType.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET legInstrumentId == ReadBytes(instrumentId.rest, 4) IN IF ~legInstrumentId.ok THEN Fail ELSE
    LET legId == ReadBytes(legInstrumentId.rest, 1) IN IF ~legId.ok THEN Fail ELSE
    LET transType == ReadBytes(legId.rest, 1) IN IF ~transType.ok THEN Fail ELSE
    LET eventSource == ReadBytes(transType.rest, 1) IN IF ~eventSource.ok THEN Fail ELSE
    LET auctionType == ReadBytes(eventSource.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET orderId == ReadBytes(auctionType.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(orderId.rest, 16) IN IF ~clOrdId.ok THEN Fail ELSE
    LET crossId == ReadBytes(clOrdId.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET matchId == ReadBytes(crossId.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    LET refMatchId == ReadBytes(matchId.rest, 4) IN IF ~refMatchId.ok THEN Fail ELSE
    LET side == ReadBytes(refMatchId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET stockLegShortSale == ReadBytes(side.rest, 1) IN IF ~stockLegShortSale.ok THEN Fail ELSE
    LET price == ReadBytes(stockLegShortSale.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET liquidityInd == ReadBytes(quantity.rest, 1) IN IF ~liquidityInd.ok THEN Fail ELSE
    LET cmta == ReadBytes(liquidityInd.rest, 4) IN IF ~cmta.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(cmta.rest, 4) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET occAccount == ReadBytes(clearingAccount.rest, 4) IN IF ~occAccount.ok THEN Fail ELSE
    LET custAcct == ReadBytes(occAccount.rest, 10) IN IF ~custAcct.ok THEN Fail ELSE
    LET stockVenue == ReadBytes(custAcct.rest, 1) IN IF ~stockVenue.ok THEN Fail ELSE
    LET stockLegMpid == ReadBytes(stockVenue.rest, 4) IN IF ~stockLegMpid.ok THEN Fail ELSE
    LET capacity == ReadBytes(stockLegMpid.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET openClose == ReadBytes(capacity.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         firmId            |-> firmId.value,
         productId         |-> productId.value,
         ordExecType       |-> ordExecType.value,
         instrumentId      |-> instrumentId.value,
         legInstrumentId   |-> legInstrumentId.value,
         legId             |-> legId.value,
         transType         |-> transType.value,
         eventSource       |-> eventSource.value,
         auctionType       |-> auctionType.value,
         orderId           |-> orderId.value,
         clOrdId           |-> clOrdId.value,
         crossId           |-> crossId.value,
         matchId           |-> matchId.value,
         refMatchId        |-> refMatchId.value,
         side              |-> side.value,
         stockLegShortSale |-> stockLegShortSale.value,
         price             |-> price.value,
         quantity          |-> quantity.value,
         liquidityInd      |-> liquidityInd.value,
         cmta              |-> cmta.value,
         clearingAccount   |-> clearingAccount.value,
         occAccount        |-> occAccount.value,
         custAcct          |-> custAcct.value,
         stockVenue        |-> stockVenue.value,
         stockLegMpid      |-> stockLegMpid.value,
         capacity          |-> capacity.value,
         openClose         |-> openClose.value ], openClose.rest)

ZeroTradeDetailsMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      firmId            |-> [i \in 1 .. 4 |-> 0],
      productId         |-> [i \in 1 .. 2 |-> 0],
      ordExecType       |-> [i \in 1 .. 1 |-> 0],
      instrumentId      |-> [i \in 1 .. 4 |-> 0],
      legInstrumentId   |-> [i \in 1 .. 4 |-> 0],
      legId             |-> [i \in 1 .. 1 |-> 0],
      transType         |-> [i \in 1 .. 1 |-> 0],
      eventSource       |-> [i \in 1 .. 1 |-> 0],
      auctionType       |-> [i \in 1 .. 1 |-> 0],
      orderId           |-> [i \in 1 .. 8 |-> 0],
      clOrdId           |-> [i \in 1 .. 16 |-> 0],
      crossId           |-> [i \in 1 .. 4 |-> 0],
      matchId           |-> [i \in 1 .. 4 |-> 0],
      refMatchId        |-> [i \in 1 .. 4 |-> 0],
      side              |-> [i \in 1 .. 1 |-> 0],
      stockLegShortSale |-> [i \in 1 .. 1 |-> 0],
      price             |-> [i \in 1 .. 8 |-> 0],
      quantity          |-> [i \in 1 .. 4 |-> 0],
      liquidityInd      |-> [i \in 1 .. 1 |-> 0],
      cmta              |-> [i \in 1 .. 4 |-> 0],
      clearingAccount   |-> [i \in 1 .. 4 |-> 0],
      occAccount        |-> [i \in 1 .. 4 |-> 0],
      custAcct          |-> [i \in 1 .. 10 |-> 0],
      stockVenue        |-> [i \in 1 .. 1 |-> 0],
      stockLegMpid      |-> [i \in 1 .. 4 |-> 0],
      capacity          |-> [i \in 1 .. 1 |-> 0],
      openClose         |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Details Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeDetailsMessage ==
    { ZeroTradeDetailsMessage }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.productId = one] : one \in Sample(2) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.ordExecType = one] : one \in Sample(1) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.legInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.legId = one] : one \in Sample(1) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.transType = one] : one \in Sample(1) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.eventSource = one] : one \in Sample(1) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.clOrdId = one] : one \in Sample(16) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.matchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.refMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.stockLegShortSale = one] : one \in Sample(1) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.liquidityInd = one] : one \in Sample(1) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.cmta = one] : one \in Sample(4) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.clearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.occAccount = one] : one \in Sample(4) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.custAcct = one] : one \in Sample(10) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.stockVenue = one] : one \in Sample(1) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.stockLegMpid = one] : one \in Sample(4) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeDetailsMessage EXCEPT !.openClose = one] : one \in Sample(1) }

(***************************************************************************)
(* Cross Order Accepted Message: 169 bytes                                 *)
(***************************************************************************)

CrossOrderAcceptedMessage ==
    [ timestamp                 : Sample(8),
      firmId                    : Sample(4),
      instrumentId              : Sample(4),
      crossType                 : Sample(1),
      auctionType               : Sample(1),
      auctionId                 : Sample(4),
      auctionAllocPct           : Sample(1),
      side                      : Sample(1),
      iso                       : Sample(1),
      priceProtection           : Sample(1),
      effectiveTime             : Sample(8),
      disclosureMask            : Sample(1),
      primaryOrderId            : Sample(8),
      primaryClOrdId            : Sample(16),
      primaryCmta               : Sample(4),
      primaryClearingAccount    : Sample(4),
      primaryOccAccount         : Sample(4),
      primaryCustAcct           : Sample(10),
      primaryPrice              : Sample(8),
      primaryQuantity           : Sample(4),
      primaryCapacity           : Sample(1),
      primaryPositionEffectMask : Sample(2),
      primaryStockLegShortSale  : Sample(1),
      primaryStockLegMpid       : Sample(4),
      contraOrderId             : Sample(8),
      contraClOrdId             : Sample(16),
      contraCmta                : Sample(4),
      contraClearingAccount     : Sample(4),
      contraOccAccount          : Sample(4),
      contraCustAcct            : Sample(10),
      contraOrderType           : Sample(1),
      contraPrice               : Sample(8),
      contraQuantity            : Sample(4),
      contraCapacity            : Sample(1),
      contraPositionEffectMask  : Sample(2),
      contraStockLegShortSale   : Sample(1),
      contraStockLegMpid        : Sample(4),
      reserved1                 : Sample(1) ]

EncodeCrossOrderAcceptedMessage(message) ==
    message.timestamp
        \o message.firmId
        \o message.instrumentId
        \o message.crossType
        \o message.auctionType
        \o message.auctionId
        \o message.auctionAllocPct
        \o message.side
        \o message.iso
        \o message.priceProtection
        \o message.effectiveTime
        \o message.disclosureMask
        \o message.primaryOrderId
        \o message.primaryClOrdId
        \o message.primaryCmta
        \o message.primaryClearingAccount
        \o message.primaryOccAccount
        \o message.primaryCustAcct
        \o message.primaryPrice
        \o message.primaryQuantity
        \o message.primaryCapacity
        \o message.primaryPositionEffectMask
        \o message.primaryStockLegShortSale
        \o message.primaryStockLegMpid
        \o message.contraOrderId
        \o message.contraClOrdId
        \o message.contraCmta
        \o message.contraClearingAccount
        \o message.contraOccAccount
        \o message.contraCustAcct
        \o message.contraOrderType
        \o message.contraPrice
        \o message.contraQuantity
        \o message.contraCapacity
        \o message.contraPositionEffectMask
        \o message.contraStockLegShortSale
        \o message.contraStockLegMpid
        \o message.reserved1

DecodeCrossOrderAcceptedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET firmId == ReadBytes(timestamp.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(firmId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET crossType == ReadBytes(instrumentId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET auctionType == ReadBytes(crossType.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionId == ReadBytes(auctionType.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionAllocPct == ReadBytes(auctionId.rest, 1) IN IF ~auctionAllocPct.ok THEN Fail ELSE
    LET side == ReadBytes(auctionAllocPct.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET iso == ReadBytes(side.rest, 1) IN IF ~iso.ok THEN Fail ELSE
    LET priceProtection == ReadBytes(iso.rest, 1) IN IF ~priceProtection.ok THEN Fail ELSE
    LET effectiveTime == ReadBytes(priceProtection.rest, 8) IN IF ~effectiveTime.ok THEN Fail ELSE
    LET disclosureMask == ReadBytes(effectiveTime.rest, 1) IN IF ~disclosureMask.ok THEN Fail ELSE
    LET primaryOrderId == ReadBytes(disclosureMask.rest, 8) IN IF ~primaryOrderId.ok THEN Fail ELSE
    LET primaryClOrdId == ReadBytes(primaryOrderId.rest, 16) IN IF ~primaryClOrdId.ok THEN Fail ELSE
    LET primaryCmta == ReadBytes(primaryClOrdId.rest, 4) IN IF ~primaryCmta.ok THEN Fail ELSE
    LET primaryClearingAccount == ReadBytes(primaryCmta.rest, 4) IN IF ~primaryClearingAccount.ok THEN Fail ELSE
    LET primaryOccAccount == ReadBytes(primaryClearingAccount.rest, 4) IN IF ~primaryOccAccount.ok THEN Fail ELSE
    LET primaryCustAcct == ReadBytes(primaryOccAccount.rest, 10) IN IF ~primaryCustAcct.ok THEN Fail ELSE
    LET primaryPrice == ReadBytes(primaryCustAcct.rest, 8) IN IF ~primaryPrice.ok THEN Fail ELSE
    LET primaryQuantity == ReadBytes(primaryPrice.rest, 4) IN IF ~primaryQuantity.ok THEN Fail ELSE
    LET primaryCapacity == ReadBytes(primaryQuantity.rest, 1) IN IF ~primaryCapacity.ok THEN Fail ELSE
    LET primaryPositionEffectMask == ReadBytes(primaryCapacity.rest, 2) IN IF ~primaryPositionEffectMask.ok THEN Fail ELSE
    LET primaryStockLegShortSale == ReadBytes(primaryPositionEffectMask.rest, 1) IN IF ~primaryStockLegShortSale.ok THEN Fail ELSE
    LET primaryStockLegMpid == ReadBytes(primaryStockLegShortSale.rest, 4) IN IF ~primaryStockLegMpid.ok THEN Fail ELSE
    LET contraOrderId == ReadBytes(primaryStockLegMpid.rest, 8) IN IF ~contraOrderId.ok THEN Fail ELSE
    LET contraClOrdId == ReadBytes(contraOrderId.rest, 16) IN IF ~contraClOrdId.ok THEN Fail ELSE
    LET contraCmta == ReadBytes(contraClOrdId.rest, 4) IN IF ~contraCmta.ok THEN Fail ELSE
    LET contraClearingAccount == ReadBytes(contraCmta.rest, 4) IN IF ~contraClearingAccount.ok THEN Fail ELSE
    LET contraOccAccount == ReadBytes(contraClearingAccount.rest, 4) IN IF ~contraOccAccount.ok THEN Fail ELSE
    LET contraCustAcct == ReadBytes(contraOccAccount.rest, 10) IN IF ~contraCustAcct.ok THEN Fail ELSE
    LET contraOrderType == ReadBytes(contraCustAcct.rest, 1) IN IF ~contraOrderType.ok THEN Fail ELSE
    LET contraPrice == ReadBytes(contraOrderType.rest, 8) IN IF ~contraPrice.ok THEN Fail ELSE
    LET contraQuantity == ReadBytes(contraPrice.rest, 4) IN IF ~contraQuantity.ok THEN Fail ELSE
    LET contraCapacity == ReadBytes(contraQuantity.rest, 1) IN IF ~contraCapacity.ok THEN Fail ELSE
    LET contraPositionEffectMask == ReadBytes(contraCapacity.rest, 2) IN IF ~contraPositionEffectMask.ok THEN Fail ELSE
    LET contraStockLegShortSale == ReadBytes(contraPositionEffectMask.rest, 1) IN IF ~contraStockLegShortSale.ok THEN Fail ELSE
    LET contraStockLegMpid == ReadBytes(contraStockLegShortSale.rest, 4) IN IF ~contraStockLegMpid.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(contraStockLegMpid.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    Ok([ timestamp                 |-> timestamp.value,
         firmId                    |-> firmId.value,
         instrumentId              |-> instrumentId.value,
         crossType                 |-> crossType.value,
         auctionType               |-> auctionType.value,
         auctionId                 |-> auctionId.value,
         auctionAllocPct           |-> auctionAllocPct.value,
         side                      |-> side.value,
         iso                       |-> iso.value,
         priceProtection           |-> priceProtection.value,
         effectiveTime             |-> effectiveTime.value,
         disclosureMask            |-> disclosureMask.value,
         primaryOrderId            |-> primaryOrderId.value,
         primaryClOrdId            |-> primaryClOrdId.value,
         primaryCmta               |-> primaryCmta.value,
         primaryClearingAccount    |-> primaryClearingAccount.value,
         primaryOccAccount         |-> primaryOccAccount.value,
         primaryCustAcct           |-> primaryCustAcct.value,
         primaryPrice              |-> primaryPrice.value,
         primaryQuantity           |-> primaryQuantity.value,
         primaryCapacity           |-> primaryCapacity.value,
         primaryPositionEffectMask |-> primaryPositionEffectMask.value,
         primaryStockLegShortSale  |-> primaryStockLegShortSale.value,
         primaryStockLegMpid       |-> primaryStockLegMpid.value,
         contraOrderId             |-> contraOrderId.value,
         contraClOrdId             |-> contraClOrdId.value,
         contraCmta                |-> contraCmta.value,
         contraClearingAccount     |-> contraClearingAccount.value,
         contraOccAccount          |-> contraOccAccount.value,
         contraCustAcct            |-> contraCustAcct.value,
         contraOrderType           |-> contraOrderType.value,
         contraPrice               |-> contraPrice.value,
         contraQuantity            |-> contraQuantity.value,
         contraCapacity            |-> contraCapacity.value,
         contraPositionEffectMask  |-> contraPositionEffectMask.value,
         contraStockLegShortSale   |-> contraStockLegShortSale.value,
         contraStockLegMpid        |-> contraStockLegMpid.value,
         reserved1                 |-> reserved1.value ], reserved1.rest)

ZeroCrossOrderAcceptedMessage ==
    [ timestamp                 |-> [i \in 1 .. 8 |-> 0],
      firmId                    |-> [i \in 1 .. 4 |-> 0],
      instrumentId              |-> [i \in 1 .. 4 |-> 0],
      crossType                 |-> [i \in 1 .. 1 |-> 0],
      auctionType               |-> [i \in 1 .. 1 |-> 0],
      auctionId                 |-> [i \in 1 .. 4 |-> 0],
      auctionAllocPct           |-> [i \in 1 .. 1 |-> 0],
      side                      |-> [i \in 1 .. 1 |-> 0],
      iso                       |-> [i \in 1 .. 1 |-> 0],
      priceProtection           |-> [i \in 1 .. 1 |-> 0],
      effectiveTime             |-> [i \in 1 .. 8 |-> 0],
      disclosureMask            |-> [i \in 1 .. 1 |-> 0],
      primaryOrderId            |-> [i \in 1 .. 8 |-> 0],
      primaryClOrdId            |-> [i \in 1 .. 16 |-> 0],
      primaryCmta               |-> [i \in 1 .. 4 |-> 0],
      primaryClearingAccount    |-> [i \in 1 .. 4 |-> 0],
      primaryOccAccount         |-> [i \in 1 .. 4 |-> 0],
      primaryCustAcct           |-> [i \in 1 .. 10 |-> 0],
      primaryPrice              |-> [i \in 1 .. 8 |-> 0],
      primaryQuantity           |-> [i \in 1 .. 4 |-> 0],
      primaryCapacity           |-> [i \in 1 .. 1 |-> 0],
      primaryPositionEffectMask |-> [i \in 1 .. 2 |-> 0],
      primaryStockLegShortSale  |-> [i \in 1 .. 1 |-> 0],
      primaryStockLegMpid       |-> [i \in 1 .. 4 |-> 0],
      contraOrderId             |-> [i \in 1 .. 8 |-> 0],
      contraClOrdId             |-> [i \in 1 .. 16 |-> 0],
      contraCmta                |-> [i \in 1 .. 4 |-> 0],
      contraClearingAccount     |-> [i \in 1 .. 4 |-> 0],
      contraOccAccount          |-> [i \in 1 .. 4 |-> 0],
      contraCustAcct            |-> [i \in 1 .. 10 |-> 0],
      contraOrderType           |-> [i \in 1 .. 1 |-> 0],
      contraPrice               |-> [i \in 1 .. 8 |-> 0],
      contraQuantity            |-> [i \in 1 .. 4 |-> 0],
      contraCapacity            |-> [i \in 1 .. 1 |-> 0],
      contraPositionEffectMask  |-> [i \in 1 .. 2 |-> 0],
      contraStockLegShortSale   |-> [i \in 1 .. 1 |-> 0],
      contraStockLegMpid        |-> [i \in 1 .. 4 |-> 0],
      reserved1                 |-> [i \in 1 .. 1 |-> 0] ]

(* Cross Order Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossOrderAcceptedMessage ==
    { ZeroCrossOrderAcceptedMessage }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.auctionAllocPct = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.iso = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.priceProtection = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.effectiveTime = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.disclosureMask = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.primaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.primaryClOrdId = one] : one \in Sample(16) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.primaryCmta = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.primaryClearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.primaryOccAccount = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.primaryCustAcct = one] : one \in Sample(10) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.primaryPrice = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.primaryQuantity = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.primaryCapacity = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.primaryPositionEffectMask = one] : one \in Sample(2) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.primaryStockLegShortSale = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.primaryStockLegMpid = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.contraOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.contraClOrdId = one] : one \in Sample(16) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.contraCmta = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.contraClearingAccount = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.contraOccAccount = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.contraCustAcct = one] : one \in Sample(10) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.contraOrderType = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.contraPrice = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.contraQuantity = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.contraCapacity = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.contraPositionEffectMask = one] : one \in Sample(2) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.contraStockLegShortSale = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.contraStockLegMpid = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderAcceptedMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }

(***************************************************************************)
(* Member Kill Switch Notification Message: 33 bytes                       *)
(***************************************************************************)

MemberKillSwitchNotificationMessage ==
    [ timestamp    : Sample(8),
      firmId       : Sample(4),
      clRequestId  : Sample(16),
      targetFirmId : Sample(4),
      killAction   : Sample(1) ]

EncodeMemberKillSwitchNotificationMessage(message) ==
    message.timestamp
        \o message.firmId
        \o message.clRequestId
        \o message.targetFirmId
        \o message.killAction

DecodeMemberKillSwitchNotificationMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET firmId == ReadBytes(timestamp.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET clRequestId == ReadBytes(firmId.rest, 16) IN IF ~clRequestId.ok THEN Fail ELSE
    LET targetFirmId == ReadBytes(clRequestId.rest, 4) IN IF ~targetFirmId.ok THEN Fail ELSE
    LET killAction == ReadBytes(targetFirmId.rest, 1) IN IF ~killAction.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         firmId       |-> firmId.value,
         clRequestId  |-> clRequestId.value,
         targetFirmId |-> targetFirmId.value,
         killAction   |-> killAction.value ], killAction.rest)

ZeroMemberKillSwitchNotificationMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      firmId       |-> [i \in 1 .. 4 |-> 0],
      clRequestId  |-> [i \in 1 .. 16 |-> 0],
      targetFirmId |-> [i \in 1 .. 4 |-> 0],
      killAction   |-> [i \in 1 .. 1 |-> 0] ]

(* Member Kill Switch Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedMemberKillSwitchNotificationMessage ==
    { ZeroMemberKillSwitchNotificationMessage }
        \cup { [ZeroMemberKillSwitchNotificationMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMemberKillSwitchNotificationMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroMemberKillSwitchNotificationMessage EXCEPT !.clRequestId = one] : one \in Sample(16) }
        \cup { [ZeroMemberKillSwitchNotificationMessage EXCEPT !.targetFirmId = one] : one \in Sample(4) }
        \cup { [ZeroMemberKillSwitchNotificationMessage EXCEPT !.killAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Cancel Response Message: 36 bytes                                  *)
(***************************************************************************)

MassCancelResponseMessage ==
    [ timestamp   : Sample(8),
      firmId      : Sample(4),
      clRequestId : Sample(16),
      numCanceled : Sample(4),
      numPending  : Sample(4) ]

EncodeMassCancelResponseMessage(message) ==
    message.timestamp
        \o message.firmId
        \o message.clRequestId
        \o message.numCanceled
        \o message.numPending

DecodeMassCancelResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET firmId == ReadBytes(timestamp.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET clRequestId == ReadBytes(firmId.rest, 16) IN IF ~clRequestId.ok THEN Fail ELSE
    LET numCanceled == ReadBytes(clRequestId.rest, 4) IN IF ~numCanceled.ok THEN Fail ELSE
    LET numPending == ReadBytes(numCanceled.rest, 4) IN IF ~numPending.ok THEN Fail ELSE
    Ok([ timestamp   |-> timestamp.value,
         firmId      |-> firmId.value,
         clRequestId |-> clRequestId.value,
         numCanceled |-> numCanceled.value,
         numPending  |-> numPending.value ], numPending.rest)

ZeroMassCancelResponseMessage ==
    [ timestamp   |-> [i \in 1 .. 8 |-> 0],
      firmId      |-> [i \in 1 .. 4 |-> 0],
      clRequestId |-> [i \in 1 .. 16 |-> 0],
      numCanceled |-> [i \in 1 .. 4 |-> 0],
      numPending  |-> [i \in 1 .. 4 |-> 0] ]

(* Mass Cancel Response Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelResponseMessage ==
    { ZeroMassCancelResponseMessage }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.clRequestId = one] : one \in Sample(16) }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.numCanceled = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelResponseMessage EXCEPT !.numPending = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Complex Instrument Response Message: 32 bytes                       *)
(***************************************************************************)

AddComplexInstrumentResponseMessage ==
    [ timestamp    : Sample(8),
      firmId       : Sample(4),
      clRequestId  : Sample(16),
      instrumentId : Sample(4) ]

EncodeAddComplexInstrumentResponseMessage(message) ==
    message.timestamp
        \o message.firmId
        \o message.clRequestId
        \o message.instrumentId

DecodeAddComplexInstrumentResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET firmId == ReadBytes(timestamp.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET clRequestId == ReadBytes(firmId.rest, 16) IN IF ~clRequestId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(clRequestId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         firmId       |-> firmId.value,
         clRequestId  |-> clRequestId.value,
         instrumentId |-> instrumentId.value ], instrumentId.rest)

ZeroAddComplexInstrumentResponseMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      firmId       |-> [i \in 1 .. 4 |-> 0],
      clRequestId  |-> [i \in 1 .. 16 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0] ]

(* Add Complex Instrument Response Message at zero, then each field in turn at the values it is checked at *)
CheckedAddComplexInstrumentResponseMessage ==
    { ZeroAddComplexInstrumentResponseMessage }
        \cup { [ZeroAddComplexInstrumentResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddComplexInstrumentResponseMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroAddComplexInstrumentResponseMessage EXCEPT !.clRequestId = one] : one \in Sample(16) }
        \cup { [ZeroAddComplexInstrumentResponseMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }

(***************************************************************************)
(* Modify Trade Response Message: 56 bytes                                 *)
(***************************************************************************)

ModifyTradeResponseMessage ==
    [ timestamp    : Sample(8),
      firmId       : Sample(4),
      instrumentId : Sample(4),
      clRequestId  : Sample(16),
      clOrdId      : Sample(16),
      crossId      : Sample(4),
      matchId      : Sample(4) ]

EncodeModifyTradeResponseMessage(message) ==
    message.timestamp
        \o message.firmId
        \o message.instrumentId
        \o message.clRequestId
        \o message.clOrdId
        \o message.crossId
        \o message.matchId

DecodeModifyTradeResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET firmId == ReadBytes(timestamp.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(firmId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET clRequestId == ReadBytes(instrumentId.rest, 16) IN IF ~clRequestId.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(clRequestId.rest, 16) IN IF ~clOrdId.ok THEN Fail ELSE
    LET crossId == ReadBytes(clOrdId.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET matchId == ReadBytes(crossId.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         firmId       |-> firmId.value,
         instrumentId |-> instrumentId.value,
         clRequestId  |-> clRequestId.value,
         clOrdId      |-> clOrdId.value,
         crossId      |-> crossId.value,
         matchId      |-> matchId.value ], matchId.rest)

ZeroModifyTradeResponseMessage ==
    [ timestamp    |-> [i \in 1 .. 8 |-> 0],
      firmId       |-> [i \in 1 .. 4 |-> 0],
      instrumentId |-> [i \in 1 .. 4 |-> 0],
      clRequestId  |-> [i \in 1 .. 16 |-> 0],
      clOrdId      |-> [i \in 1 .. 16 |-> 0],
      crossId      |-> [i \in 1 .. 4 |-> 0],
      matchId      |-> [i \in 1 .. 4 |-> 0] ]

(* Modify Trade Response Message at zero, then each field in turn at the values it is checked at *)
CheckedModifyTradeResponseMessage ==
    { ZeroModifyTradeResponseMessage }
        \cup { [ZeroModifyTradeResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroModifyTradeResponseMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTradeResponseMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTradeResponseMessage EXCEPT !.clRequestId = one] : one \in Sample(16) }
        \cup { [ZeroModifyTradeResponseMessage EXCEPT !.clOrdId = one] : one \in Sample(16) }
        \cup { [ZeroModifyTradeResponseMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroModifyTradeResponseMessage EXCEPT !.matchId = one] : one \in Sample(4) }

(***************************************************************************)
(* Subscription Response Message: 28 bytes                                 *)
(***************************************************************************)

SubscriptionResponseMessage ==
    [ timestamp   : Sample(8),
      firmId      : Sample(4),
      clRequestId : Sample(16) ]

EncodeSubscriptionResponseMessage(message) ==
    message.timestamp
        \o message.firmId
        \o message.clRequestId

DecodeSubscriptionResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET firmId == ReadBytes(timestamp.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET clRequestId == ReadBytes(firmId.rest, 16) IN IF ~clRequestId.ok THEN Fail ELSE
    Ok([ timestamp   |-> timestamp.value,
         firmId      |-> firmId.value,
         clRequestId |-> clRequestId.value ], clRequestId.rest)

ZeroSubscriptionResponseMessage ==
    [ timestamp   |-> [i \in 1 .. 8 |-> 0],
      firmId      |-> [i \in 1 .. 4 |-> 0],
      clRequestId |-> [i \in 1 .. 16 |-> 0] ]

(* Subscription Response Message at zero, then each field in turn at the values it is checked at *)
CheckedSubscriptionResponseMessage ==
    { ZeroSubscriptionResponseMessage }
        \cup { [ZeroSubscriptionResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSubscriptionResponseMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroSubscriptionResponseMessage EXCEPT !.clRequestId = one] : one \in Sample(16) }

(***************************************************************************)
(* Reject Message: 27 bytes                                                *)
(***************************************************************************)

RejectMessage ==
    [ timestamp     : Sample(8),
      rejectMsgType : Sample(1),
      clOrdId       : Sample(16),
      rejectCode    : Sample(2) ]

EncodeRejectMessage(message) ==
    message.timestamp
        \o message.rejectMsgType
        \o message.clOrdId
        \o message.rejectCode

DecodeRejectMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET rejectMsgType == ReadBytes(timestamp.rest, 1) IN IF ~rejectMsgType.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(rejectMsgType.rest, 16) IN IF ~clOrdId.ok THEN Fail ELSE
    LET rejectCode == ReadBytes(clOrdId.rest, 2) IN IF ~rejectCode.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         rejectMsgType |-> rejectMsgType.value,
         clOrdId       |-> clOrdId.value,
         rejectCode    |-> rejectCode.value ], rejectCode.rest)

ZeroRejectMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      rejectMsgType |-> [i \in 1 .. 1 |-> 0],
      clOrdId       |-> [i \in 1 .. 16 |-> 0],
      rejectCode    |-> [i \in 1 .. 2 |-> 0] ]

(* Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectMessage ==
    { ZeroRejectMessage }
        \cup { [ZeroRejectMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.rejectMsgType = one] : one \in Sample(1) }
        \cup { [ZeroRejectMessage EXCEPT !.clOrdId = one] : one \in Sample(16) }
        \cup { [ZeroRejectMessage EXCEPT !.rejectCode = one] : one \in Sample(2) }

(***************************************************************************)
(* Pending Response Message: 34 bytes                                      *)
(***************************************************************************)

PendingResponseMessage ==
    [ timestamp      : Sample(8),
      firmId         : Sample(4),
      instrumentId   : Sample(4),
      pendingMsgType : Sample(1),
      clOrdId        : Sample(16),
      pendingReason  : Sample(1) ]

EncodePendingResponseMessage(message) ==
    message.timestamp
        \o message.firmId
        \o message.instrumentId
        \o message.pendingMsgType
        \o message.clOrdId
        \o message.pendingReason

DecodePendingResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET firmId == ReadBytes(timestamp.rest, 4) IN IF ~firmId.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(firmId.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET pendingMsgType == ReadBytes(instrumentId.rest, 1) IN IF ~pendingMsgType.ok THEN Fail ELSE
    LET clOrdId == ReadBytes(pendingMsgType.rest, 16) IN IF ~clOrdId.ok THEN Fail ELSE
    LET pendingReason == ReadBytes(clOrdId.rest, 1) IN IF ~pendingReason.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         firmId         |-> firmId.value,
         instrumentId   |-> instrumentId.value,
         pendingMsgType |-> pendingMsgType.value,
         clOrdId        |-> clOrdId.value,
         pendingReason  |-> pendingReason.value ], pendingReason.rest)

ZeroPendingResponseMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      firmId         |-> [i \in 1 .. 4 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      pendingMsgType |-> [i \in 1 .. 1 |-> 0],
      clOrdId        |-> [i \in 1 .. 16 |-> 0],
      pendingReason  |-> [i \in 1 .. 1 |-> 0] ]

(* Pending Response Message at zero, then each field in turn at the values it is checked at *)
CheckedPendingResponseMessage ==
    { ZeroPendingResponseMessage }
        \cup { [ZeroPendingResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroPendingResponseMessage EXCEPT !.firmId = one] : one \in Sample(4) }
        \cup { [ZeroPendingResponseMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroPendingResponseMessage EXCEPT !.pendingMsgType = one] : one \in Sample(1) }
        \cup { [ZeroPendingResponseMessage EXCEPT !.clOrdId = one] : one \in Sample(16) }
        \cup { [ZeroPendingResponseMessage EXCEPT !.pendingReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemEventMessageCode == 122  \* "z"
SimpleInstrumentDirectoryMessageCode == 111  \* "o"
ComplexInstrumentDirectoryMessageCode == 115  \* "s"
InstrumentTradingActionMessageCode == 105  \* "i"
AuctionNotificationMessageCode == 110  \* "n"
OrderAcceptedLongFormMessageCode == 97  \* "a"
OrderAcceptedShortFormMessageCode == 98  \* "b"
OrderReplacedMessageCode == 114  \* "r"
OrderCanceledMessageCode == 99  \* "c"
OrderExecutedMessageCode == 101  \* "e"
TradeDetailsMessageCode == 116  \* "t"
CrossOrderAcceptedMessageCode == 120  \* "x"
MemberKillSwitchNotificationMessageCode == 107  \* "k"
MassCancelResponseMessageCode == 117  \* "u"
AddComplexInstrumentResponseMessageCode == 100  \* "d"
ModifyTradeResponseMessageCode == 109  \* "m"
SubscriptionResponseMessageCode == 102  \* "f"
RejectMessageCode == 106  \* "j"
PendingResponseMessageCode == 112  \* "p"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {SimpleInstrumentDirectoryMessageCode}, body : SimpleInstrumentDirectoryMessage ]
        \cup [ tag : {ComplexInstrumentDirectoryMessageCode}, body : ComplexInstrumentDirectoryMessage ]
        \cup [ tag : {InstrumentTradingActionMessageCode}, body : InstrumentTradingActionMessage ]
        \cup [ tag : {AuctionNotificationMessageCode}, body : AuctionNotificationMessage ]
        \cup [ tag : {OrderAcceptedLongFormMessageCode}, body : OrderAcceptedLongFormMessage ]
        \cup [ tag : {OrderAcceptedShortFormMessageCode}, body : OrderAcceptedShortFormMessage ]
        \cup [ tag : {OrderReplacedMessageCode}, body : OrderReplacedMessage ]
        \cup [ tag : {OrderCanceledMessageCode}, body : OrderCanceledMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {TradeDetailsMessageCode}, body : TradeDetailsMessage ]
        \cup [ tag : {CrossOrderAcceptedMessageCode}, body : CrossOrderAcceptedMessage ]
        \cup [ tag : {MemberKillSwitchNotificationMessageCode}, body : MemberKillSwitchNotificationMessage ]
        \cup [ tag : {MassCancelResponseMessageCode}, body : MassCancelResponseMessage ]
        \cup [ tag : {AddComplexInstrumentResponseMessageCode}, body : AddComplexInstrumentResponseMessage ]
        \cup [ tag : {ModifyTradeResponseMessageCode}, body : ModifyTradeResponseMessage ]
        \cup [ tag : {SubscriptionResponseMessageCode}, body : SubscriptionResponseMessage ]
        \cup [ tag : {RejectMessageCode}, body : RejectMessage ]
        \cup [ tag : {PendingResponseMessageCode}, body : PendingResponseMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = SimpleInstrumentDirectoryMessageCode -> EncodeSimpleInstrumentDirectoryMessage(message.body)
      [] message.tag = ComplexInstrumentDirectoryMessageCode -> EncodeComplexInstrumentDirectoryMessage(message.body)
      [] message.tag = InstrumentTradingActionMessageCode -> EncodeInstrumentTradingActionMessage(message.body)
      [] message.tag = AuctionNotificationMessageCode -> EncodeAuctionNotificationMessage(message.body)
      [] message.tag = OrderAcceptedLongFormMessageCode -> EncodeOrderAcceptedLongFormMessage(message.body)
      [] message.tag = OrderAcceptedShortFormMessageCode -> EncodeOrderAcceptedShortFormMessage(message.body)
      [] message.tag = OrderReplacedMessageCode -> EncodeOrderReplacedMessage(message.body)
      [] message.tag = OrderCanceledMessageCode -> EncodeOrderCanceledMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = TradeDetailsMessageCode -> EncodeTradeDetailsMessage(message.body)
      [] message.tag = CrossOrderAcceptedMessageCode -> EncodeCrossOrderAcceptedMessage(message.body)
      [] message.tag = MemberKillSwitchNotificationMessageCode -> EncodeMemberKillSwitchNotificationMessage(message.body)
      [] message.tag = MassCancelResponseMessageCode -> EncodeMassCancelResponseMessage(message.body)
      [] message.tag = AddComplexInstrumentResponseMessageCode -> EncodeAddComplexInstrumentResponseMessage(message.body)
      [] message.tag = ModifyTradeResponseMessageCode -> EncodeModifyTradeResponseMessage(message.body)
      [] message.tag = SubscriptionResponseMessageCode -> EncodeSubscriptionResponseMessage(message.body)
      [] message.tag = RejectMessageCode -> EncodeRejectMessage(message.body)
      [] message.tag = PendingResponseMessageCode -> EncodePendingResponseMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = SimpleInstrumentDirectoryMessageCode -> DecodeSimpleInstrumentDirectoryMessage(bytes)
              [] tag = ComplexInstrumentDirectoryMessageCode -> DecodeComplexInstrumentDirectoryMessage(bytes)
              [] tag = InstrumentTradingActionMessageCode -> DecodeInstrumentTradingActionMessage(bytes)
              [] tag = AuctionNotificationMessageCode -> DecodeAuctionNotificationMessage(bytes)
              [] tag = OrderAcceptedLongFormMessageCode -> DecodeOrderAcceptedLongFormMessage(bytes)
              [] tag = OrderAcceptedShortFormMessageCode -> DecodeOrderAcceptedShortFormMessage(bytes)
              [] tag = OrderReplacedMessageCode -> DecodeOrderReplacedMessage(bytes)
              [] tag = OrderCanceledMessageCode -> DecodeOrderCanceledMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = TradeDetailsMessageCode -> DecodeTradeDetailsMessage(bytes)
              [] tag = CrossOrderAcceptedMessageCode -> DecodeCrossOrderAcceptedMessage(bytes)
              [] tag = MemberKillSwitchNotificationMessageCode -> DecodeMemberKillSwitchNotificationMessage(bytes)
              [] tag = MassCancelResponseMessageCode -> DecodeMassCancelResponseMessage(bytes)
              [] tag = AddComplexInstrumentResponseMessageCode -> DecodeAddComplexInstrumentResponseMessage(bytes)
              [] tag = ModifyTradeResponseMessageCode -> DecodeModifyTradeResponseMessage(bytes)
              [] tag = SubscriptionResponseMessageCode -> DecodeSubscriptionResponseMessage(bytes)
              [] tag = RejectMessageCode -> DecodeRejectMessage(bytes)
              [] tag = PendingResponseMessageCode -> DecodePendingResponseMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> SimpleInstrumentDirectoryMessageCode, body |-> one] : one \in CheckedSimpleInstrumentDirectoryMessage }
        \cup { [tag |-> ComplexInstrumentDirectoryMessageCode, body |-> one] : one \in CheckedComplexInstrumentDirectoryMessage }
        \cup { [tag |-> InstrumentTradingActionMessageCode, body |-> one] : one \in CheckedInstrumentTradingActionMessage }
        \cup { [tag |-> AuctionNotificationMessageCode, body |-> one] : one \in CheckedAuctionNotificationMessage }
        \cup { [tag |-> OrderAcceptedLongFormMessageCode, body |-> one] : one \in CheckedOrderAcceptedLongFormMessage }
        \cup { [tag |-> OrderAcceptedShortFormMessageCode, body |-> one] : one \in CheckedOrderAcceptedShortFormMessage }
        \cup { [tag |-> OrderReplacedMessageCode, body |-> one] : one \in CheckedOrderReplacedMessage }
        \cup { [tag |-> OrderCanceledMessageCode, body |-> one] : one \in CheckedOrderCanceledMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> TradeDetailsMessageCode, body |-> one] : one \in CheckedTradeDetailsMessage }
        \cup { [tag |-> CrossOrderAcceptedMessageCode, body |-> one] : one \in CheckedCrossOrderAcceptedMessage }
        \cup { [tag |-> MemberKillSwitchNotificationMessageCode, body |-> one] : one \in CheckedMemberKillSwitchNotificationMessage }
        \cup { [tag |-> MassCancelResponseMessageCode, body |-> one] : one \in CheckedMassCancelResponseMessage }
        \cup { [tag |-> AddComplexInstrumentResponseMessageCode, body |-> one] : one \in CheckedAddComplexInstrumentResponseMessage }
        \cup { [tag |-> ModifyTradeResponseMessageCode, body |-> one] : one \in CheckedModifyTradeResponseMessage }
        \cup { [tag |-> SubscriptionResponseMessageCode, body |-> one] : one \in CheckedSubscriptionResponseMessage }
        \cup { [tag |-> RejectMessageCode, body |-> one] : one \in CheckedRejectMessage }
        \cup { [tag |-> PendingResponseMessageCode, body |-> one] : one \in CheckedPendingResponseMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET sequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~sequencedMessageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(sequencedMessageType.value, sequencedMessageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"
ServerHeartbeatPacketCode == 72  \* "H"
EndOfSessionPacketCode == 90  \* "Z"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {ServerHeartbeatPacketCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionPacketCode}, body : {[empty |-> 0]} ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = ServerHeartbeatPacketCode -> << >>
      [] message.tag = EndOfSessionPacketCode -> << >>

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = ServerHeartbeatPacketCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionPacketCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> ServerHeartbeatPacketCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionPacketCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Server Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ServerSoupBinTcpPacket ==
    [ serverPayload : ServerPayload ]

EncodeServerSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeServerSoupBinTcpPacket(message) ==
    LET body == EncodeServerSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeServerSoupBinTcpPacketBody(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value ], serverPayload.rest)

DecodeServerSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeServerSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroServerSoupBinTcpPacket ==
    [ serverPayload |-> ZeroServerPayload ]

(* Server Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerSoupBinTcpPacket ==
    { ZeroServerSoupBinTcpPacket }
        \cup { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }

(* A run of Server Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeServerSoupBinTcpPacketList(_)
EncodeServerSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSoupBinTcpPacket(Head(messages)) \o EncodeServerSoupBinTcpPacketList(Tail(messages))

(* As many Server Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerSoupBinTcpPacketAll(_)
ReadServerSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneServerSoupBinTcpPacket ==
    { [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginAcceptedPacketCode, body |-> ZeroLoginAcceptedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> LoginRejectedPacketCode, body |-> ZeroLoginRejectedPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> SequencedDataPacketCode, body |-> ZeroSequencedDataPacket]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatPacketCode, body |-> [empty |-> 0]]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> EndOfSessionPacketCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSoupBinTcpPacket : SampleLists(OneServerSoupBinTcpPacket) ]

EncodeServerPacket(message) ==
    EncodeServerSoupBinTcpPacketList(message.serverSoupBinTcpPacket)

DecodeServerPacket(bytes) ==
    LET serverSoupBinTcpPacket == ReadServerSoupBinTcpPacketAll(bytes) IN IF ~serverSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ serverSoupBinTcpPacket |-> serverSoupBinTcpPacket.value ], serverSoupBinTcpPacket.rest)

ZeroServerPacket ==
    [ serverSoupBinTcpPacket |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSoupBinTcpPacket = one] : one \in SampleLists(OneServerSoupBinTcpPacket) }

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

(* Every Debug Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripDebugPacket ==
    \A message \in CheckedDebugPacket :
        LET read == DecodeDebugPacket(EncodeDebugPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Accepted Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginAcceptedPacket ==
    \A message \in CheckedLoginAcceptedPacket :
        LET read == DecodeLoginAcceptedPacket(EncodeLoginAcceptedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Rejected Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRejectedPacket ==
    \A message \in CheckedLoginRejectedPacket :
        LET read == DecodeLoginRejectedPacket(EncodeLoginRejectedPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Event Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemEventMessage ==
    \A message \in CheckedSystemEventMessage :
        LET read == DecodeSystemEventMessage(EncodeSystemEventMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Instrument Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleInstrumentDirectoryMessage ==
    \A message \in CheckedSimpleInstrumentDirectoryMessage :
        LET read == DecodeSimpleInstrumentDirectoryMessage(EncodeSimpleInstrumentDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Directory Legs decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexDirectoryLegs ==
    \A message \in CheckedComplexDirectoryLegs :
        LET read == DecodeComplexDirectoryLegs(EncodeComplexDirectoryLegs(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Complex Instrument Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripComplexInstrumentDirectoryMessage ==
    \A message \in CheckedComplexInstrumentDirectoryMessage :
        LET read == DecodeComplexInstrumentDirectoryMessage(EncodeComplexInstrumentDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentTradingActionMessage ==
    \A message \in CheckedInstrumentTradingActionMessage :
        LET read == DecodeInstrumentTradingActionMessage(EncodeInstrumentTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Flex Dac Legs decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexDacLegs ==
    \A message \in CheckedFlexDacLegs :
        LET read == DecodeFlexDacLegs(EncodeFlexDacLegs(message))
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

(* Every Flex Legs decodes back to what was encoded, and leaves nothing over *)
RoundTripFlexLegs ==
    \A message \in CheckedFlexLegs :
        LET read == DecodeFlexLegs(EncodeFlexLegs(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Accepted Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcceptedLongFormMessage ==
    \A message \in CheckedOrderAcceptedLongFormMessage :
        LET read == DecodeOrderAcceptedLongFormMessage(EncodeOrderAcceptedLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Accepted Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcceptedShortFormMessage ==
    \A message \in CheckedOrderAcceptedShortFormMessage :
        LET read == DecodeOrderAcceptedShortFormMessage(EncodeOrderAcceptedShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replaced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplacedMessage ==
    \A message \in CheckedOrderReplacedMessage :
        LET read == DecodeOrderReplacedMessage(EncodeOrderReplacedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCanceledMessage ==
    \A message \in CheckedOrderCanceledMessage :
        LET read == DecodeOrderCanceledMessage(EncodeOrderCanceledMessage(message))
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

(* Every Trade Details Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeDetailsMessage ==
    \A message \in CheckedTradeDetailsMessage :
        LET read == DecodeTradeDetailsMessage(EncodeTradeDetailsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Order Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossOrderAcceptedMessage ==
    \A message \in CheckedCrossOrderAcceptedMessage :
        LET read == DecodeCrossOrderAcceptedMessage(EncodeCrossOrderAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Member Kill Switch Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMemberKillSwitchNotificationMessage ==
    \A message \in CheckedMemberKillSwitchNotificationMessage :
        LET read == DecodeMemberKillSwitchNotificationMessage(EncodeMemberKillSwitchNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelResponseMessage ==
    \A message \in CheckedMassCancelResponseMessage :
        LET read == DecodeMassCancelResponseMessage(EncodeMassCancelResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Complex Instrument Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddComplexInstrumentResponseMessage ==
    \A message \in CheckedAddComplexInstrumentResponseMessage :
        LET read == DecodeAddComplexInstrumentResponseMessage(EncodeAddComplexInstrumentResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Modify Trade Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripModifyTradeResponseMessage ==
    \A message \in CheckedModifyTradeResponseMessage :
        LET read == DecodeModifyTradeResponseMessage(EncodeModifyTradeResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subscription Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubscriptionResponseMessage ==
    \A message \in CheckedSubscriptionResponseMessage :
        LET read == DecodeSubscriptionResponseMessage(EncodeSubscriptionResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectMessage ==
    \A message \in CheckedRejectMessage :
        LET read == DecodeRejectMessage(EncodeRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Pending Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPendingResponseMessage ==
    \A message \in CheckedPendingResponseMessage :
        LET read == DecodePendingResponseMessage(EncodePendingResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripSequencedDataPacket ==
    \A message \in CheckedSequencedDataPacket :
        LET read == DecodeSequencedDataPacket(EncodeSequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET read == DecodeServerSoupBinTcpPacket(EncodeServerSoupBinTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Sequenced Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesServerSoupBinTcpPacket ==
    \A message \in CheckedServerSoupBinTcpPacket :
        LET bytes == EncodeServerSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
