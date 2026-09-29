----------------- MODULE NomOptions_Itto_v4_0_2025_Server ------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Itch To Trade Options v4.0.2025                                *)
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
(* Debug Packet: 1 bytes                                                   *)
(***************************************************************************)

DebugPacket ==
    [ debugText : Sample(1) ]

EncodeDebugPacket(message) ==
    message.debugText

DecodeDebugPacket(bytes) ==
    LET debugText == ReadBytes(bytes, 1) IN IF ~debugText.ok THEN Fail ELSE
    Ok([ debugText |-> debugText.value ], debugText.rest)

ZeroDebugPacket ==
    [ debugText |-> [i \in 1 .. 1 |-> 0] ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.debugText = one] : one \in Sample(1) }

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
(* System Event Message: 9 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(6),
      eventCode      : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         eventCode      |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      eventCode      |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Options Directory Message: 43 bytes                                     *)
(***************************************************************************)

OptionsDirectoryMessage ==
    [ trackingNumber      : Sample(2),
      timestamp           : Sample(6),
      optionId            : Sample(4),
      securitySymbol      : Sample(6),
      expirationYear      : Sample(1),
      expirationMonth     : Sample(1),
      expirationDate      : Sample(1),
      explicitStrikePrice : Sample(4),
      optionType          : Sample(1),
      source              : Sample(1),
      underlyingSymbol    : Sample(13),
      optionsClosingType  : Sample(1),
      tradable            : Sample(1),
      mpv                 : Sample(1) ]

EncodeOptionsDirectoryMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.optionId
        \o message.securitySymbol
        \o message.expirationYear
        \o message.expirationMonth
        \o message.expirationDate
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.source
        \o message.underlyingSymbol
        \o message.optionsClosingType
        \o message.tradable
        \o message.mpv

DecodeOptionsDirectoryMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 6) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(securitySymbol.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    LET expirationMonth == ReadBytes(expirationYear.rest, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDate.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expirationDate.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET source == ReadBytes(optionType.rest, 1) IN IF ~source.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(source.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET optionsClosingType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~optionsClosingType.ok THEN Fail ELSE
    LET tradable == ReadBytes(optionsClosingType.rest, 1) IN IF ~tradable.ok THEN Fail ELSE
    LET mpv == ReadBytes(tradable.rest, 1) IN IF ~mpv.ok THEN Fail ELSE
    Ok([ trackingNumber      |-> trackingNumber.value,
         timestamp           |-> timestamp.value,
         optionId            |-> optionId.value,
         securitySymbol      |-> securitySymbol.value,
         expirationYear      |-> expirationYear.value,
         expirationMonth     |-> expirationMonth.value,
         expirationDate      |-> expirationDate.value,
         explicitStrikePrice |-> explicitStrikePrice.value,
         optionType          |-> optionType.value,
         source              |-> source.value,
         underlyingSymbol    |-> underlyingSymbol.value,
         optionsClosingType  |-> optionsClosingType.value,
         tradable            |-> tradable.value,
         mpv                 |-> mpv.value ], mpv.rest)

ZeroOptionsDirectoryMessage ==
    [ trackingNumber      |-> [i \in 1 .. 2 |-> 0],
      timestamp           |-> [i \in 1 .. 6 |-> 0],
      optionId            |-> [i \in 1 .. 4 |-> 0],
      securitySymbol      |-> [i \in 1 .. 6 |-> 0],
      expirationYear      |-> [i \in 1 .. 1 |-> 0],
      expirationMonth     |-> [i \in 1 .. 1 |-> 0],
      expirationDate      |-> [i \in 1 .. 1 |-> 0],
      explicitStrikePrice |-> [i \in 1 .. 4 |-> 0],
      optionType          |-> [i \in 1 .. 1 |-> 0],
      source              |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol    |-> [i \in 1 .. 13 |-> 0],
      optionsClosingType  |-> [i \in 1 .. 1 |-> 0],
      tradable            |-> [i \in 1 .. 1 |-> 0],
      mpv                 |-> [i \in 1 .. 1 |-> 0] ]

(* Options Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsDirectoryMessage ==
    { ZeroOptionsDirectoryMessage }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.expirationYear = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.expirationDate = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.source = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.optionsClosingType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.tradable = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.mpv = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Action Message: 13 bytes                                        *)
(***************************************************************************)

TradingActionMessage ==
    [ trackingNumber      : Sample(2),
      timestamp           : Sample(6),
      optionId            : Sample(4),
      currentTradingState : Sample(1) ]

EncodeTradingActionMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.optionId
        \o message.currentTradingState

DecodeTradingActionMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(optionId.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    Ok([ trackingNumber      |-> trackingNumber.value,
         timestamp           |-> timestamp.value,
         optionId            |-> optionId.value,
         currentTradingState |-> currentTradingState.value ], currentTradingState.rest)

ZeroTradingActionMessage ==
    [ trackingNumber      |-> [i \in 1 .. 2 |-> 0],
      timestamp           |-> [i \in 1 .. 6 |-> 0],
      optionId            |-> [i \in 1 .. 4 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingActionMessage ==
    { ZeroTradingActionMessage }
        \cup { [ZeroTradingActionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroTradingActionMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Open Message: 13 bytes                                         *)
(***************************************************************************)

SecurityOpenMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(6),
      optionId       : Sample(4),
      openState      : Sample(1) ]

EncodeSecurityOpenMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.optionId
        \o message.openState

DecodeSecurityOpenMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET openState == ReadBytes(optionId.rest, 1) IN IF ~openState.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         optionId       |-> optionId.value,
         openState      |-> openState.value ], openState.rest)

ZeroSecurityOpenMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      optionId       |-> [i \in 1 .. 4 |-> 0],
      openState      |-> [i \in 1 .. 1 |-> 0] ]

(* Security Open Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityOpenMessage ==
    { ZeroSecurityOpenMessage }
        \cup { [ZeroSecurityOpenMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSecurityOpenMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroSecurityOpenMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityOpenMessage EXCEPT !.openState = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Message Short Message Form: 25 bytes                          *)
(***************************************************************************)

AddOrderMessageShortMessageForm ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(6),
      orderReferenceNumber : Sample(8),
      marketSide           : Sample(1),
      optionId             : Sample(4),
      priceShort           : Sample(2),
      volumeShort          : Sample(2) ]

EncodeAddOrderMessageShortMessageForm(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.marketSide
        \o message.optionId
        \o message.priceShort
        \o message.volumeShort

DecodeAddOrderMessageShortMessageForm(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET marketSide == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~marketSide.ok THEN Fail ELSE
    LET optionId == ReadBytes(marketSide.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET priceShort == ReadBytes(optionId.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET volumeShort == ReadBytes(priceShort.rest, 2) IN IF ~volumeShort.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         marketSide           |-> marketSide.value,
         optionId             |-> optionId.value,
         priceShort           |-> priceShort.value,
         volumeShort          |-> volumeShort.value ], volumeShort.rest)

ZeroAddOrderMessageShortMessageForm ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 6 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      marketSide           |-> [i \in 1 .. 1 |-> 0],
      optionId             |-> [i \in 1 .. 4 |-> 0],
      priceShort           |-> [i \in 1 .. 2 |-> 0],
      volumeShort          |-> [i \in 1 .. 2 |-> 0] ]

(* Add Order Message Short Message Form at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessageShortMessageForm ==
    { ZeroAddOrderMessageShortMessageForm }
        \cup { [ZeroAddOrderMessageShortMessageForm EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMessageShortMessageForm EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessageShortMessageForm EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessageShortMessageForm EXCEPT !.marketSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessageShortMessageForm EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessageShortMessageForm EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMessageShortMessageForm EXCEPT !.volumeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Add Order Message Long Form Message: 29 bytes                           *)
(***************************************************************************)

AddOrderMessageLongFormMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(6),
      orderReferenceNumber : Sample(8),
      marketSide           : Sample(1),
      optionId             : Sample(4),
      priceLong            : Sample(4),
      volumeLong           : Sample(4) ]

EncodeAddOrderMessageLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.marketSide
        \o message.optionId
        \o message.priceLong
        \o message.volumeLong

DecodeAddOrderMessageLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET marketSide == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~marketSide.ok THEN Fail ELSE
    LET optionId == ReadBytes(marketSide.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET priceLong == ReadBytes(optionId.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         marketSide           |-> marketSide.value,
         optionId             |-> optionId.value,
         priceLong            |-> priceLong.value,
         volumeLong           |-> volumeLong.value ], volumeLong.rest)

ZeroAddOrderMessageLongFormMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 6 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      marketSide           |-> [i \in 1 .. 1 |-> 0],
      optionId             |-> [i \in 1 .. 4 |-> 0],
      priceLong            |-> [i \in 1 .. 4 |-> 0],
      volumeLong           |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order Message Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessageLongFormMessage ==
    { ZeroAddOrderMessageLongFormMessage }
        \cup { [ZeroAddOrderMessageLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMessageLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessageLongFormMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessageLongFormMessage EXCEPT !.marketSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessageLongFormMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessageLongFormMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessageLongFormMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Quote Message Short Form Message: 36 bytes                          *)
(***************************************************************************)

AddQuoteMessageShortFormMessage ==
    [ trackingNumber     : Sample(2),
      timestamp          : Sample(6),
      bidReferenceNumber : Sample(8),
      askReferenceNumber : Sample(8),
      optionId           : Sample(4),
      bidPriceShort      : Sample(2),
      bidSizeShort       : Sample(2),
      askPriceShort      : Sample(2),
      askSizeShort       : Sample(2) ]

EncodeAddQuoteMessageShortFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.bidReferenceNumber
        \o message.askReferenceNumber
        \o message.optionId
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.askPriceShort
        \o message.askSizeShort

DecodeAddQuoteMessageShortFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    LET optionId == ReadBytes(askReferenceNumber.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(optionId.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET askPriceShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~askPriceShort.ok THEN Fail ELSE
    LET askSizeShort == ReadBytes(askPriceShort.rest, 2) IN IF ~askSizeShort.ok THEN Fail ELSE
    Ok([ trackingNumber     |-> trackingNumber.value,
         timestamp          |-> timestamp.value,
         bidReferenceNumber |-> bidReferenceNumber.value,
         askReferenceNumber |-> askReferenceNumber.value,
         optionId           |-> optionId.value,
         bidPriceShort      |-> bidPriceShort.value,
         bidSizeShort       |-> bidSizeShort.value,
         askPriceShort      |-> askPriceShort.value,
         askSizeShort       |-> askSizeShort.value ], askSizeShort.rest)

ZeroAddQuoteMessageShortFormMessage ==
    [ trackingNumber     |-> [i \in 1 .. 2 |-> 0],
      timestamp          |-> [i \in 1 .. 6 |-> 0],
      bidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      optionId           |-> [i \in 1 .. 4 |-> 0],
      bidPriceShort      |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort       |-> [i \in 1 .. 2 |-> 0],
      askPriceShort      |-> [i \in 1 .. 2 |-> 0],
      askSizeShort       |-> [i \in 1 .. 2 |-> 0] ]

(* Add Quote Message Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddQuoteMessageShortFormMessage ==
    { ZeroAddQuoteMessageShortFormMessage }
        \cup { [ZeroAddQuoteMessageShortFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteMessageShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroAddQuoteMessageShortFormMessage EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteMessageShortFormMessage EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteMessageShortFormMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageShortFormMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteMessageShortFormMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteMessageShortFormMessage EXCEPT !.askPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteMessageShortFormMessage EXCEPT !.askSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Add Quote Message Long Form Message: 44 bytes                           *)
(***************************************************************************)

AddQuoteMessageLongFormMessage ==
    [ trackingNumber     : Sample(2),
      timestamp          : Sample(6),
      bidReferenceNumber : Sample(8),
      askReferenceNumber : Sample(8),
      optionId           : Sample(4),
      bid                : Sample(4),
      bidSizeLong        : Sample(4),
      ask                : Sample(4),
      askSizeLong        : Sample(4) ]

EncodeAddQuoteMessageLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.bidReferenceNumber
        \o message.askReferenceNumber
        \o message.optionId
        \o message.bid
        \o message.bidSizeLong
        \o message.ask
        \o message.askSizeLong

DecodeAddQuoteMessageLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    LET optionId == ReadBytes(askReferenceNumber.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET bid == ReadBytes(optionId.rest, 4) IN IF ~bid.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bid.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET ask == ReadBytes(bidSizeLong.rest, 4) IN IF ~ask.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(ask.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    Ok([ trackingNumber     |-> trackingNumber.value,
         timestamp          |-> timestamp.value,
         bidReferenceNumber |-> bidReferenceNumber.value,
         askReferenceNumber |-> askReferenceNumber.value,
         optionId           |-> optionId.value,
         bid                |-> bid.value,
         bidSizeLong        |-> bidSizeLong.value,
         ask                |-> ask.value,
         askSizeLong        |-> askSizeLong.value ], askSizeLong.rest)

ZeroAddQuoteMessageLongFormMessage ==
    [ trackingNumber     |-> [i \in 1 .. 2 |-> 0],
      timestamp          |-> [i \in 1 .. 6 |-> 0],
      bidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      optionId           |-> [i \in 1 .. 4 |-> 0],
      bid                |-> [i \in 1 .. 4 |-> 0],
      bidSizeLong        |-> [i \in 1 .. 4 |-> 0],
      ask                |-> [i \in 1 .. 4 |-> 0],
      askSizeLong        |-> [i \in 1 .. 4 |-> 0] ]

(* Add Quote Message Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddQuoteMessageLongFormMessage ==
    { ZeroAddQuoteMessageLongFormMessage }
        \cup { [ZeroAddQuoteMessageLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteMessageLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroAddQuoteMessageLongFormMessage EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteMessageLongFormMessage EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteMessageLongFormMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageLongFormMessage EXCEPT !.bid = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageLongFormMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageLongFormMessage EXCEPT !.ask = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteMessageLongFormMessage EXCEPT !.askSizeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Executed Message: 28 bytes                                  *)
(***************************************************************************)

SingleSideExecutedMessage ==
    [ trackingNumber    : Sample(2),
      timestamp         : Sample(6),
      referenceNumber   : Sample(8),
      executedContracts : Sample(4),
      crossNumber       : Sample(4),
      matchNumber       : Sample(4) ]

EncodeSingleSideExecutedMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.referenceNumber
        \o message.executedContracts
        \o message.crossNumber
        \o message.matchNumber

DecodeSingleSideExecutedMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET referenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~referenceNumber.ok THEN Fail ELSE
    LET executedContracts == ReadBytes(referenceNumber.rest, 4) IN IF ~executedContracts.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(executedContracts.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ trackingNumber    |-> trackingNumber.value,
         timestamp         |-> timestamp.value,
         referenceNumber   |-> referenceNumber.value,
         executedContracts |-> executedContracts.value,
         crossNumber       |-> crossNumber.value,
         matchNumber       |-> matchNumber.value ], matchNumber.rest)

ZeroSingleSideExecutedMessage ==
    [ trackingNumber    |-> [i \in 1 .. 2 |-> 0],
      timestamp         |-> [i \in 1 .. 6 |-> 0],
      referenceNumber   |-> [i \in 1 .. 8 |-> 0],
      executedContracts |-> [i \in 1 .. 4 |-> 0],
      crossNumber       |-> [i \in 1 .. 4 |-> 0],
      matchNumber       |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideExecutedMessage ==
    { ZeroSingleSideExecutedMessage }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.referenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.executedContracts = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Executed With Price Message: 33 bytes                       *)
(***************************************************************************)

SingleSideExecutedWithPriceMessage ==
    [ trackingNumber  : Sample(2),
      timestamp       : Sample(6),
      referenceNumber : Sample(8),
      crossNumber     : Sample(4),
      matchNumber     : Sample(4),
      printable       : Sample(1),
      priceLong       : Sample(4),
      volumeLong      : Sample(4) ]

EncodeSingleSideExecutedWithPriceMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.referenceNumber
        \o message.crossNumber
        \o message.matchNumber
        \o message.printable
        \o message.priceLong
        \o message.volumeLong

DecodeSingleSideExecutedWithPriceMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET referenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~referenceNumber.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(referenceNumber.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET printable == ReadBytes(matchNumber.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET priceLong == ReadBytes(printable.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ trackingNumber  |-> trackingNumber.value,
         timestamp       |-> timestamp.value,
         referenceNumber |-> referenceNumber.value,
         crossNumber     |-> crossNumber.value,
         matchNumber     |-> matchNumber.value,
         printable       |-> printable.value,
         priceLong       |-> priceLong.value,
         volumeLong      |-> volumeLong.value ], volumeLong.rest)

ZeroSingleSideExecutedWithPriceMessage ==
    [ trackingNumber  |-> [i \in 1 .. 2 |-> 0],
      timestamp       |-> [i \in 1 .. 6 |-> 0],
      referenceNumber |-> [i \in 1 .. 8 |-> 0],
      crossNumber     |-> [i \in 1 .. 4 |-> 0],
      matchNumber     |-> [i \in 1 .. 4 |-> 0],
      printable       |-> [i \in 1 .. 1 |-> 0],
      priceLong       |-> [i \in 1 .. 4 |-> 0],
      volumeLong      |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideExecutedWithPriceMessage ==
    { ZeroSingleSideExecutedWithPriceMessage }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.referenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideExecutedWithPriceMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Message: 20 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(6),
      orderReferenceNumber : Sample(8),
      cancelledContracts   : Sample(4) ]

EncodeOrderCancelMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.cancelledContracts

DecodeOrderCancelMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET cancelledContracts == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~cancelledContracts.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         cancelledContracts   |-> cancelledContracts.value ], cancelledContracts.rest)

ZeroOrderCancelMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 6 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      cancelledContracts   |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.cancelledContracts = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Replace Message Short Form: 28 bytes                        *)
(***************************************************************************)

SingleSideReplaceMessageShortForm ==
    [ trackingNumber          : Sample(2),
      timestamp               : Sample(6),
      originalReferenceNumber : Sample(8),
      newReferenceNumber      : Sample(8),
      priceShort              : Sample(2),
      volumeShort             : Sample(2) ]

EncodeSingleSideReplaceMessageShortForm(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.originalReferenceNumber
        \o message.newReferenceNumber
        \o message.priceShort
        \o message.volumeShort

DecodeSingleSideReplaceMessageShortForm(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET originalReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~originalReferenceNumber.ok THEN Fail ELSE
    LET newReferenceNumber == ReadBytes(originalReferenceNumber.rest, 8) IN IF ~newReferenceNumber.ok THEN Fail ELSE
    LET priceShort == ReadBytes(newReferenceNumber.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET volumeShort == ReadBytes(priceShort.rest, 2) IN IF ~volumeShort.ok THEN Fail ELSE
    Ok([ trackingNumber          |-> trackingNumber.value,
         timestamp               |-> timestamp.value,
         originalReferenceNumber |-> originalReferenceNumber.value,
         newReferenceNumber      |-> newReferenceNumber.value,
         priceShort              |-> priceShort.value,
         volumeShort             |-> volumeShort.value ], volumeShort.rest)

ZeroSingleSideReplaceMessageShortForm ==
    [ trackingNumber          |-> [i \in 1 .. 2 |-> 0],
      timestamp               |-> [i \in 1 .. 6 |-> 0],
      originalReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      newReferenceNumber      |-> [i \in 1 .. 8 |-> 0],
      priceShort              |-> [i \in 1 .. 2 |-> 0],
      volumeShort             |-> [i \in 1 .. 2 |-> 0] ]

(* Single Side Replace Message Short Form at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideReplaceMessageShortForm ==
    { ZeroSingleSideReplaceMessageShortForm }
        \cup { [ZeroSingleSideReplaceMessageShortForm EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideReplaceMessageShortForm EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroSingleSideReplaceMessageShortForm EXCEPT !.originalReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceMessageShortForm EXCEPT !.newReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceMessageShortForm EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideReplaceMessageShortForm EXCEPT !.volumeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Single Side Replace Message Long Form: 32 bytes                         *)
(***************************************************************************)

SingleSideReplaceMessageLongForm ==
    [ trackingNumber          : Sample(2),
      timestamp               : Sample(6),
      originalReferenceNumber : Sample(8),
      newReferenceNumber      : Sample(8),
      priceLong               : Sample(4),
      volumeLong              : Sample(4) ]

EncodeSingleSideReplaceMessageLongForm(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.originalReferenceNumber
        \o message.newReferenceNumber
        \o message.priceLong
        \o message.volumeLong

DecodeSingleSideReplaceMessageLongForm(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET originalReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~originalReferenceNumber.ok THEN Fail ELSE
    LET newReferenceNumber == ReadBytes(originalReferenceNumber.rest, 8) IN IF ~newReferenceNumber.ok THEN Fail ELSE
    LET priceLong == ReadBytes(newReferenceNumber.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ trackingNumber          |-> trackingNumber.value,
         timestamp               |-> timestamp.value,
         originalReferenceNumber |-> originalReferenceNumber.value,
         newReferenceNumber      |-> newReferenceNumber.value,
         priceLong               |-> priceLong.value,
         volumeLong              |-> volumeLong.value ], volumeLong.rest)

ZeroSingleSideReplaceMessageLongForm ==
    [ trackingNumber          |-> [i \in 1 .. 2 |-> 0],
      timestamp               |-> [i \in 1 .. 6 |-> 0],
      originalReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      newReferenceNumber      |-> [i \in 1 .. 8 |-> 0],
      priceLong               |-> [i \in 1 .. 4 |-> 0],
      volumeLong              |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Replace Message Long Form at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideReplaceMessageLongForm ==
    { ZeroSingleSideReplaceMessageLongForm }
        \cup { [ZeroSingleSideReplaceMessageLongForm EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideReplaceMessageLongForm EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroSingleSideReplaceMessageLongForm EXCEPT !.originalReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceMessageLongForm EXCEPT !.newReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideReplaceMessageLongForm EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideReplaceMessageLongForm EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Single Side Delete Message: 16 bytes                                    *)
(***************************************************************************)

SingleSideDeleteMessage ==
    [ trackingNumber  : Sample(2),
      timestamp       : Sample(6),
      referenceNumber : Sample(8) ]

EncodeSingleSideDeleteMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.referenceNumber

DecodeSingleSideDeleteMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET referenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~referenceNumber.ok THEN Fail ELSE
    Ok([ trackingNumber  |-> trackingNumber.value,
         timestamp       |-> timestamp.value,
         referenceNumber |-> referenceNumber.value ], referenceNumber.rest)

ZeroSingleSideDeleteMessage ==
    [ trackingNumber  |-> [i \in 1 .. 2 |-> 0],
      timestamp       |-> [i \in 1 .. 6 |-> 0],
      referenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Single Side Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideDeleteMessage ==
    { ZeroSingleSideDeleteMessage }
        \cup { [ZeroSingleSideDeleteMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideDeleteMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroSingleSideDeleteMessage EXCEPT !.referenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Single Side Change Message: 25 bytes                                    *)
(***************************************************************************)

SingleSideChangeMessage ==
    [ trackingNumber  : Sample(2),
      timestamp       : Sample(6),
      referenceNumber : Sample(8),
      changeReason    : Sample(1),
      priceLong       : Sample(4),
      volumeLong      : Sample(4) ]

EncodeSingleSideChangeMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.referenceNumber
        \o message.changeReason
        \o message.priceLong
        \o message.volumeLong

DecodeSingleSideChangeMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET referenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~referenceNumber.ok THEN Fail ELSE
    LET changeReason == ReadBytes(referenceNumber.rest, 1) IN IF ~changeReason.ok THEN Fail ELSE
    LET priceLong == ReadBytes(changeReason.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ trackingNumber  |-> trackingNumber.value,
         timestamp       |-> timestamp.value,
         referenceNumber |-> referenceNumber.value,
         changeReason    |-> changeReason.value,
         priceLong       |-> priceLong.value,
         volumeLong      |-> volumeLong.value ], volumeLong.rest)

ZeroSingleSideChangeMessage ==
    [ trackingNumber  |-> [i \in 1 .. 2 |-> 0],
      timestamp       |-> [i \in 1 .. 6 |-> 0],
      referenceNumber |-> [i \in 1 .. 8 |-> 0],
      changeReason    |-> [i \in 1 .. 1 |-> 0],
      priceLong       |-> [i \in 1 .. 4 |-> 0],
      volumeLong      |-> [i \in 1 .. 4 |-> 0] ]

(* Single Side Change Message at zero, then each field in turn at the values it is checked at *)
CheckedSingleSideChangeMessage ==
    { ZeroSingleSideChangeMessage }
        \cup { [ZeroSingleSideChangeMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSingleSideChangeMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroSingleSideChangeMessage EXCEPT !.referenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSingleSideChangeMessage EXCEPT !.changeReason = one] : one \in Sample(1) }
        \cup { [ZeroSingleSideChangeMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroSingleSideChangeMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Replace Message Short Form: 48 bytes                              *)
(***************************************************************************)

QuoteReplaceMessageShortForm ==
    [ trackingNumber             : Sample(2),
      timestamp                  : Sample(6),
      originalBidReferenceNumber : Sample(8),
      bidReferenceNumber         : Sample(8),
      originalAskReferenceNumber : Sample(8),
      askReferenceNumber         : Sample(8),
      bidPriceShort              : Sample(2),
      bidSizeShort               : Sample(2),
      askPriceShort              : Sample(2),
      askSizeShort               : Sample(2) ]

EncodeQuoteReplaceMessageShortForm(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.originalBidReferenceNumber
        \o message.bidReferenceNumber
        \o message.originalAskReferenceNumber
        \o message.askReferenceNumber
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.askPriceShort
        \o message.askSizeShort

DecodeQuoteReplaceMessageShortForm(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET originalBidReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~originalBidReferenceNumber.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(originalBidReferenceNumber.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET originalAskReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~originalAskReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(originalAskReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(askReferenceNumber.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET askPriceShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~askPriceShort.ok THEN Fail ELSE
    LET askSizeShort == ReadBytes(askPriceShort.rest, 2) IN IF ~askSizeShort.ok THEN Fail ELSE
    Ok([ trackingNumber             |-> trackingNumber.value,
         timestamp                  |-> timestamp.value,
         originalBidReferenceNumber |-> originalBidReferenceNumber.value,
         bidReferenceNumber         |-> bidReferenceNumber.value,
         originalAskReferenceNumber |-> originalAskReferenceNumber.value,
         askReferenceNumber         |-> askReferenceNumber.value,
         bidPriceShort              |-> bidPriceShort.value,
         bidSizeShort               |-> bidSizeShort.value,
         askPriceShort              |-> askPriceShort.value,
         askSizeShort               |-> askSizeShort.value ], askSizeShort.rest)

ZeroQuoteReplaceMessageShortForm ==
    [ trackingNumber             |-> [i \in 1 .. 2 |-> 0],
      timestamp                  |-> [i \in 1 .. 6 |-> 0],
      originalBidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      bidReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      originalAskReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      bidPriceShort              |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort               |-> [i \in 1 .. 2 |-> 0],
      askPriceShort              |-> [i \in 1 .. 2 |-> 0],
      askSizeShort               |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Replace Message Short Form at zero, then each field in turn at the values it is checked at *)
CheckedQuoteReplaceMessageShortForm ==
    { ZeroQuoteReplaceMessageShortForm }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.originalBidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.originalAskReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.askPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceMessageShortForm EXCEPT !.askSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Quote Replace Message Long Form: 56 bytes                               *)
(***************************************************************************)

QuoteReplaceMessageLongForm ==
    [ trackingNumber             : Sample(2),
      timestamp                  : Sample(6),
      originalBidReferenceNumber : Sample(8),
      bidReferenceNumber         : Sample(8),
      originalAskReferenceNumber : Sample(8),
      askReferenceNumber         : Sample(8),
      bidPriceLong               : Sample(4),
      bidSizeLong                : Sample(4),
      askPriceLong               : Sample(4),
      askSizeLong                : Sample(4) ]

EncodeQuoteReplaceMessageLongForm(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.originalBidReferenceNumber
        \o message.bidReferenceNumber
        \o message.originalAskReferenceNumber
        \o message.askReferenceNumber
        \o message.bidPriceLong
        \o message.bidSizeLong
        \o message.askPriceLong
        \o message.askSizeLong

DecodeQuoteReplaceMessageLongForm(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET originalBidReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~originalBidReferenceNumber.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(originalBidReferenceNumber.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET originalAskReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~originalAskReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(originalAskReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(askReferenceNumber.rest, 4) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(bidSizeLong.rest, 4) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(askPriceLong.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    Ok([ trackingNumber             |-> trackingNumber.value,
         timestamp                  |-> timestamp.value,
         originalBidReferenceNumber |-> originalBidReferenceNumber.value,
         bidReferenceNumber         |-> bidReferenceNumber.value,
         originalAskReferenceNumber |-> originalAskReferenceNumber.value,
         askReferenceNumber         |-> askReferenceNumber.value,
         bidPriceLong               |-> bidPriceLong.value,
         bidSizeLong                |-> bidSizeLong.value,
         askPriceLong               |-> askPriceLong.value,
         askSizeLong                |-> askSizeLong.value ], askSizeLong.rest)

ZeroQuoteReplaceMessageLongForm ==
    [ trackingNumber             |-> [i \in 1 .. 2 |-> 0],
      timestamp                  |-> [i \in 1 .. 6 |-> 0],
      originalBidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      bidReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      originalAskReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      bidPriceLong               |-> [i \in 1 .. 4 |-> 0],
      bidSizeLong                |-> [i \in 1 .. 4 |-> 0],
      askPriceLong               |-> [i \in 1 .. 4 |-> 0],
      askSizeLong                |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Replace Message Long Form at zero, then each field in turn at the values it is checked at *)
CheckedQuoteReplaceMessageLongForm ==
    { ZeroQuoteReplaceMessageLongForm }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.originalBidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.originalAskReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.bidPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.askPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceMessageLongForm EXCEPT !.askSizeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Delete Message: 24 bytes                                          *)
(***************************************************************************)

QuoteDeleteMessage ==
    [ trackingNumber     : Sample(2),
      timestamp          : Sample(6),
      bidReferenceNumber : Sample(8),
      askReferenceNumber : Sample(8) ]

EncodeQuoteDeleteMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.bidReferenceNumber
        \o message.askReferenceNumber

DecodeQuoteDeleteMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    Ok([ trackingNumber     |-> trackingNumber.value,
         timestamp          |-> timestamp.value,
         bidReferenceNumber |-> bidReferenceNumber.value,
         askReferenceNumber |-> askReferenceNumber.value ], askReferenceNumber.rest)

ZeroQuoteDeleteMessage ==
    [ trackingNumber     |-> [i \in 1 .. 2 |-> 0],
      timestamp          |-> [i \in 1 .. 6 |-> 0],
      bidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteDeleteMessage ==
    { ZeroQuoteDeleteMessage }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Options Trade Messages Non Auction: 29 bytes                            *)
(***************************************************************************)

OptionsTradeMessagesNonAuction ==
    [ trackingNumber   : Sample(2),
      timestamp        : Sample(6),
      buySellIndicator : Sample(1),
      optionId         : Sample(4),
      crossNumber      : Sample(4),
      matchNumber      : Sample(4),
      priceLong        : Sample(4),
      volumeLong       : Sample(4) ]

EncodeOptionsTradeMessagesNonAuction(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.buySellIndicator
        \o message.optionId
        \o message.crossNumber
        \o message.matchNumber
        \o message.priceLong
        \o message.volumeLong

DecodeOptionsTradeMessagesNonAuction(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(timestamp.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET optionId == ReadBytes(buySellIndicator.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(optionId.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET priceLong == ReadBytes(matchNumber.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ trackingNumber   |-> trackingNumber.value,
         timestamp        |-> timestamp.value,
         buySellIndicator |-> buySellIndicator.value,
         optionId         |-> optionId.value,
         crossNumber      |-> crossNumber.value,
         matchNumber      |-> matchNumber.value,
         priceLong        |-> priceLong.value,
         volumeLong       |-> volumeLong.value ], volumeLong.rest)

ZeroOptionsTradeMessagesNonAuction ==
    [ trackingNumber   |-> [i \in 1 .. 2 |-> 0],
      timestamp        |-> [i \in 1 .. 6 |-> 0],
      buySellIndicator |-> [i \in 1 .. 1 |-> 0],
      optionId         |-> [i \in 1 .. 4 |-> 0],
      crossNumber      |-> [i \in 1 .. 4 |-> 0],
      matchNumber      |-> [i \in 1 .. 4 |-> 0],
      priceLong        |-> [i \in 1 .. 4 |-> 0],
      volumeLong       |-> [i \in 1 .. 4 |-> 0] ]

(* Options Trade Messages Non Auction at zero, then each field in turn at the values it is checked at *)
CheckedOptionsTradeMessagesNonAuction ==
    { ZeroOptionsTradeMessagesNonAuction }
        \cup { [ZeroOptionsTradeMessagesNonAuction EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOptionsTradeMessagesNonAuction EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOptionsTradeMessagesNonAuction EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOptionsTradeMessagesNonAuction EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeMessagesNonAuction EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeMessagesNonAuction EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeMessagesNonAuction EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroOptionsTradeMessagesNonAuction EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Options Cross Trade Message: 29 bytes                                   *)
(***************************************************************************)

OptionsCrossTradeMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(6),
      optionId       : Sample(4),
      crossNumber    : Sample(4),
      matchNumber    : Sample(4),
      crossType      : Sample(1),
      priceLong      : Sample(4),
      volumeLong     : Sample(4) ]

EncodeOptionsCrossTradeMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.optionId
        \o message.crossNumber
        \o message.matchNumber
        \o message.crossType
        \o message.priceLong
        \o message.volumeLong

DecodeOptionsCrossTradeMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(optionId.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET crossType == ReadBytes(matchNumber.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET priceLong == ReadBytes(crossType.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         optionId       |-> optionId.value,
         crossNumber    |-> crossNumber.value,
         matchNumber    |-> matchNumber.value,
         crossType      |-> crossType.value,
         priceLong      |-> priceLong.value,
         volumeLong     |-> volumeLong.value ], volumeLong.rest)

ZeroOptionsCrossTradeMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      optionId       |-> [i \in 1 .. 4 |-> 0],
      crossNumber    |-> [i \in 1 .. 4 |-> 0],
      matchNumber    |-> [i \in 1 .. 4 |-> 0],
      crossType      |-> [i \in 1 .. 1 |-> 0],
      priceLong      |-> [i \in 1 .. 4 |-> 0],
      volumeLong     |-> [i \in 1 .. 4 |-> 0] ]

(* Options Cross Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsCrossTradeMessage ==
    { ZeroOptionsCrossTradeMessage }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroOptionsCrossTradeMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Broken Trade Order Executed Message: 16 bytes                           *)
(***************************************************************************)

BrokenTradeOrderExecutedMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(6),
      crossNumber    : Sample(4),
      matchNumber    : Sample(4) ]

EncodeBrokenTradeOrderExecutedMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.crossNumber
        \o message.matchNumber

DecodeBrokenTradeOrderExecutedMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(timestamp.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         crossNumber    |-> crossNumber.value,
         matchNumber    |-> matchNumber.value ], matchNumber.rest)

ZeroBrokenTradeOrderExecutedMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      crossNumber    |-> [i \in 1 .. 4 |-> 0],
      matchNumber    |-> [i \in 1 .. 4 |-> 0] ]

(* Broken Trade Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeOrderExecutedMessage ==
    { ZeroBrokenTradeOrderExecutedMessage }
        \cup { [ZeroBrokenTradeOrderExecutedMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroBrokenTradeOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroBrokenTradeOrderExecutedMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Noii Message: 34 bytes                                                  *)
(***************************************************************************)

NoiiMessage ==
    [ trackingNumber        : Sample(2),
      timestamp             : Sample(6),
      auctionId             : Sample(4),
      auctionType           : Sample(1),
      pairedContracts       : Sample(4),
      imbalanceDirection    : Sample(1),
      optionId              : Sample(4),
      imbalancePrice        : Sample(4),
      imbalanceVolume       : Sample(4),
      customerFirmIndicator : Sample(1),
      reserved3             : Sample(3) ]

EncodeNoiiMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.auctionId
        \o message.auctionType
        \o message.pairedContracts
        \o message.imbalanceDirection
        \o message.optionId
        \o message.imbalancePrice
        \o message.imbalanceVolume
        \o message.customerFirmIndicator
        \o message.reserved3

DecodeNoiiMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET auctionId == ReadBytes(timestamp.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET pairedContracts == ReadBytes(auctionType.rest, 4) IN IF ~pairedContracts.ok THEN Fail ELSE
    LET imbalanceDirection == ReadBytes(pairedContracts.rest, 1) IN IF ~imbalanceDirection.ok THEN Fail ELSE
    LET optionId == ReadBytes(imbalanceDirection.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET imbalancePrice == ReadBytes(optionId.rest, 4) IN IF ~imbalancePrice.ok THEN Fail ELSE
    LET imbalanceVolume == ReadBytes(imbalancePrice.rest, 4) IN IF ~imbalanceVolume.ok THEN Fail ELSE
    LET customerFirmIndicator == ReadBytes(imbalanceVolume.rest, 1) IN IF ~customerFirmIndicator.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(customerFirmIndicator.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ trackingNumber        |-> trackingNumber.value,
         timestamp             |-> timestamp.value,
         auctionId             |-> auctionId.value,
         auctionType           |-> auctionType.value,
         pairedContracts       |-> pairedContracts.value,
         imbalanceDirection    |-> imbalanceDirection.value,
         optionId              |-> optionId.value,
         imbalancePrice        |-> imbalancePrice.value,
         imbalanceVolume       |-> imbalanceVolume.value,
         customerFirmIndicator |-> customerFirmIndicator.value,
         reserved3             |-> reserved3.value ], reserved3.rest)

ZeroNoiiMessage ==
    [ trackingNumber        |-> [i \in 1 .. 2 |-> 0],
      timestamp             |-> [i \in 1 .. 6 |-> 0],
      auctionId             |-> [i \in 1 .. 4 |-> 0],
      auctionType           |-> [i \in 1 .. 1 |-> 0],
      pairedContracts       |-> [i \in 1 .. 4 |-> 0],
      imbalanceDirection    |-> [i \in 1 .. 1 |-> 0],
      optionId              |-> [i \in 1 .. 4 |-> 0],
      imbalancePrice        |-> [i \in 1 .. 4 |-> 0],
      imbalanceVolume       |-> [i \in 1 .. 4 |-> 0],
      customerFirmIndicator |-> [i \in 1 .. 1 |-> 0],
      reserved3             |-> [i \in 1 .. 3 |-> 0] ]

(* Noii Message at zero, then each field in turn at the values it is checked at *)
CheckedNoiiMessage ==
    { ZeroNoiiMessage }
        \cup { [ZeroNoiiMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroNoiiMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroNoiiMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroNoiiMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroNoiiMessage EXCEPT !.pairedContracts = one] : one \in Sample(4) }
        \cup { [ZeroNoiiMessage EXCEPT !.imbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroNoiiMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroNoiiMessage EXCEPT !.imbalancePrice = one] : one \in Sample(4) }
        \cup { [ZeroNoiiMessage EXCEPT !.imbalanceVolume = one] : one \in Sample(4) }
        \cup { [ZeroNoiiMessage EXCEPT !.customerFirmIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNoiiMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* End Of Replay Sequence Message: 20 bytes                                *)
(***************************************************************************)

EndOfReplaySequenceMessage ==
    [ endOfReplaySequenceNumber : Sample(20) ]

EncodeEndOfReplaySequenceMessage(message) ==
    message.endOfReplaySequenceNumber

DecodeEndOfReplaySequenceMessage(bytes) ==
    LET endOfReplaySequenceNumber == ReadBytes(bytes, 20) IN IF ~endOfReplaySequenceNumber.ok THEN Fail ELSE
    Ok([ endOfReplaySequenceNumber |-> endOfReplaySequenceNumber.value ], endOfReplaySequenceNumber.rest)

ZeroEndOfReplaySequenceMessage ==
    [ endOfReplaySequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* End Of Replay Sequence Message at zero, then each field in turn at the values it is checked at *)
CheckedEndOfReplaySequenceMessage ==
    { ZeroEndOfReplaySequenceMessage }
        \cup { [ZeroEndOfReplaySequenceMessage EXCEPT !.endOfReplaySequenceNumber = one] : one \in Sample(20) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
OptionsDirectoryMessageCode == 82  \* "R"
TradingActionMessageCode == 72  \* "H"
SecurityOpenMessageCode == 79  \* "O"
AddOrderMessageShortMessageFormCode == 97  \* "a"
AddOrderMessageLongFormMessageCode == 65  \* "A"
AddQuoteMessageShortFormMessageCode == 106  \* "j"
AddQuoteMessageLongFormMessageCode == 74  \* "J"
SingleSideExecutedMessageCode == 69  \* "E"
SingleSideExecutedWithPriceMessageCode == 67  \* "C"
OrderCancelMessageCode == 88  \* "X"
SingleSideReplaceMessageShortFormCode == 117  \* "u"
SingleSideReplaceMessageLongFormCode == 85  \* "U"
SingleSideDeleteMessageCode == 68  \* "D"
SingleSideChangeMessageCode == 71  \* "G"
QuoteReplaceMessageShortFormCode == 107  \* "k"
QuoteReplaceMessageLongFormCode == 75  \* "K"
QuoteDeleteMessageCode == 89  \* "Y"
OptionsTradeMessagesNonAuctionCode == 80  \* "P"
OptionsCrossTradeMessageCode == 81  \* "Q"
BrokenTradeOrderExecutedMessageCode == 66  \* "B"
NoiiMessageCode == 73  \* "I"
EndOfReplaySequenceMessageCode == 77  \* "M"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OptionsDirectoryMessageCode}, body : OptionsDirectoryMessage ]
        \cup [ tag : {TradingActionMessageCode}, body : TradingActionMessage ]
        \cup [ tag : {SecurityOpenMessageCode}, body : SecurityOpenMessage ]
        \cup [ tag : {AddOrderMessageShortMessageFormCode}, body : AddOrderMessageShortMessageForm ]
        \cup [ tag : {AddOrderMessageLongFormMessageCode}, body : AddOrderMessageLongFormMessage ]
        \cup [ tag : {AddQuoteMessageShortFormMessageCode}, body : AddQuoteMessageShortFormMessage ]
        \cup [ tag : {AddQuoteMessageLongFormMessageCode}, body : AddQuoteMessageLongFormMessage ]
        \cup [ tag : {SingleSideExecutedMessageCode}, body : SingleSideExecutedMessage ]
        \cup [ tag : {SingleSideExecutedWithPriceMessageCode}, body : SingleSideExecutedWithPriceMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {SingleSideReplaceMessageShortFormCode}, body : SingleSideReplaceMessageShortForm ]
        \cup [ tag : {SingleSideReplaceMessageLongFormCode}, body : SingleSideReplaceMessageLongForm ]
        \cup [ tag : {SingleSideDeleteMessageCode}, body : SingleSideDeleteMessage ]
        \cup [ tag : {SingleSideChangeMessageCode}, body : SingleSideChangeMessage ]
        \cup [ tag : {QuoteReplaceMessageShortFormCode}, body : QuoteReplaceMessageShortForm ]
        \cup [ tag : {QuoteReplaceMessageLongFormCode}, body : QuoteReplaceMessageLongForm ]
        \cup [ tag : {QuoteDeleteMessageCode}, body : QuoteDeleteMessage ]
        \cup [ tag : {OptionsTradeMessagesNonAuctionCode}, body : OptionsTradeMessagesNonAuction ]
        \cup [ tag : {OptionsCrossTradeMessageCode}, body : OptionsCrossTradeMessage ]
        \cup [ tag : {BrokenTradeOrderExecutedMessageCode}, body : BrokenTradeOrderExecutedMessage ]
        \cup [ tag : {NoiiMessageCode}, body : NoiiMessage ]
        \cup [ tag : {EndOfReplaySequenceMessageCode}, body : EndOfReplaySequenceMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OptionsDirectoryMessageCode -> EncodeOptionsDirectoryMessage(message.body)
      [] message.tag = TradingActionMessageCode -> EncodeTradingActionMessage(message.body)
      [] message.tag = SecurityOpenMessageCode -> EncodeSecurityOpenMessage(message.body)
      [] message.tag = AddOrderMessageShortMessageFormCode -> EncodeAddOrderMessageShortMessageForm(message.body)
      [] message.tag = AddOrderMessageLongFormMessageCode -> EncodeAddOrderMessageLongFormMessage(message.body)
      [] message.tag = AddQuoteMessageShortFormMessageCode -> EncodeAddQuoteMessageShortFormMessage(message.body)
      [] message.tag = AddQuoteMessageLongFormMessageCode -> EncodeAddQuoteMessageLongFormMessage(message.body)
      [] message.tag = SingleSideExecutedMessageCode -> EncodeSingleSideExecutedMessage(message.body)
      [] message.tag = SingleSideExecutedWithPriceMessageCode -> EncodeSingleSideExecutedWithPriceMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = SingleSideReplaceMessageShortFormCode -> EncodeSingleSideReplaceMessageShortForm(message.body)
      [] message.tag = SingleSideReplaceMessageLongFormCode -> EncodeSingleSideReplaceMessageLongForm(message.body)
      [] message.tag = SingleSideDeleteMessageCode -> EncodeSingleSideDeleteMessage(message.body)
      [] message.tag = SingleSideChangeMessageCode -> EncodeSingleSideChangeMessage(message.body)
      [] message.tag = QuoteReplaceMessageShortFormCode -> EncodeQuoteReplaceMessageShortForm(message.body)
      [] message.tag = QuoteReplaceMessageLongFormCode -> EncodeQuoteReplaceMessageLongForm(message.body)
      [] message.tag = QuoteDeleteMessageCode -> EncodeQuoteDeleteMessage(message.body)
      [] message.tag = OptionsTradeMessagesNonAuctionCode -> EncodeOptionsTradeMessagesNonAuction(message.body)
      [] message.tag = OptionsCrossTradeMessageCode -> EncodeOptionsCrossTradeMessage(message.body)
      [] message.tag = BrokenTradeOrderExecutedMessageCode -> EncodeBrokenTradeOrderExecutedMessage(message.body)
      [] message.tag = NoiiMessageCode -> EncodeNoiiMessage(message.body)
      [] message.tag = EndOfReplaySequenceMessageCode -> EncodeEndOfReplaySequenceMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OptionsDirectoryMessageCode -> DecodeOptionsDirectoryMessage(bytes)
              [] tag = TradingActionMessageCode -> DecodeTradingActionMessage(bytes)
              [] tag = SecurityOpenMessageCode -> DecodeSecurityOpenMessage(bytes)
              [] tag = AddOrderMessageShortMessageFormCode -> DecodeAddOrderMessageShortMessageForm(bytes)
              [] tag = AddOrderMessageLongFormMessageCode -> DecodeAddOrderMessageLongFormMessage(bytes)
              [] tag = AddQuoteMessageShortFormMessageCode -> DecodeAddQuoteMessageShortFormMessage(bytes)
              [] tag = AddQuoteMessageLongFormMessageCode -> DecodeAddQuoteMessageLongFormMessage(bytes)
              [] tag = SingleSideExecutedMessageCode -> DecodeSingleSideExecutedMessage(bytes)
              [] tag = SingleSideExecutedWithPriceMessageCode -> DecodeSingleSideExecutedWithPriceMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = SingleSideReplaceMessageShortFormCode -> DecodeSingleSideReplaceMessageShortForm(bytes)
              [] tag = SingleSideReplaceMessageLongFormCode -> DecodeSingleSideReplaceMessageLongForm(bytes)
              [] tag = SingleSideDeleteMessageCode -> DecodeSingleSideDeleteMessage(bytes)
              [] tag = SingleSideChangeMessageCode -> DecodeSingleSideChangeMessage(bytes)
              [] tag = QuoteReplaceMessageShortFormCode -> DecodeQuoteReplaceMessageShortForm(bytes)
              [] tag = QuoteReplaceMessageLongFormCode -> DecodeQuoteReplaceMessageLongForm(bytes)
              [] tag = QuoteDeleteMessageCode -> DecodeQuoteDeleteMessage(bytes)
              [] tag = OptionsTradeMessagesNonAuctionCode -> DecodeOptionsTradeMessagesNonAuction(bytes)
              [] tag = OptionsCrossTradeMessageCode -> DecodeOptionsCrossTradeMessage(bytes)
              [] tag = BrokenTradeOrderExecutedMessageCode -> DecodeBrokenTradeOrderExecutedMessage(bytes)
              [] tag = NoiiMessageCode -> DecodeNoiiMessage(bytes)
              [] tag = EndOfReplaySequenceMessageCode -> DecodeEndOfReplaySequenceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OptionsDirectoryMessageCode, body |-> one] : one \in CheckedOptionsDirectoryMessage }
        \cup { [tag |-> TradingActionMessageCode, body |-> one] : one \in CheckedTradingActionMessage }
        \cup { [tag |-> SecurityOpenMessageCode, body |-> one] : one \in CheckedSecurityOpenMessage }
        \cup { [tag |-> AddOrderMessageShortMessageFormCode, body |-> one] : one \in CheckedAddOrderMessageShortMessageForm }
        \cup { [tag |-> AddOrderMessageLongFormMessageCode, body |-> one] : one \in CheckedAddOrderMessageLongFormMessage }
        \cup { [tag |-> AddQuoteMessageShortFormMessageCode, body |-> one] : one \in CheckedAddQuoteMessageShortFormMessage }
        \cup { [tag |-> AddQuoteMessageLongFormMessageCode, body |-> one] : one \in CheckedAddQuoteMessageLongFormMessage }
        \cup { [tag |-> SingleSideExecutedMessageCode, body |-> one] : one \in CheckedSingleSideExecutedMessage }
        \cup { [tag |-> SingleSideExecutedWithPriceMessageCode, body |-> one] : one \in CheckedSingleSideExecutedWithPriceMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> SingleSideReplaceMessageShortFormCode, body |-> one] : one \in CheckedSingleSideReplaceMessageShortForm }
        \cup { [tag |-> SingleSideReplaceMessageLongFormCode, body |-> one] : one \in CheckedSingleSideReplaceMessageLongForm }
        \cup { [tag |-> SingleSideDeleteMessageCode, body |-> one] : one \in CheckedSingleSideDeleteMessage }
        \cup { [tag |-> SingleSideChangeMessageCode, body |-> one] : one \in CheckedSingleSideChangeMessage }
        \cup { [tag |-> QuoteReplaceMessageShortFormCode, body |-> one] : one \in CheckedQuoteReplaceMessageShortForm }
        \cup { [tag |-> QuoteReplaceMessageLongFormCode, body |-> one] : one \in CheckedQuoteReplaceMessageLongForm }
        \cup { [tag |-> QuoteDeleteMessageCode, body |-> one] : one \in CheckedQuoteDeleteMessage }
        \cup { [tag |-> OptionsTradeMessagesNonAuctionCode, body |-> one] : one \in CheckedOptionsTradeMessagesNonAuction }
        \cup { [tag |-> OptionsCrossTradeMessageCode, body |-> one] : one \in CheckedOptionsCrossTradeMessage }
        \cup { [tag |-> BrokenTradeOrderExecutedMessageCode, body |-> one] : one \in CheckedBrokenTradeOrderExecutedMessage }
        \cup { [tag |-> NoiiMessageCode, body |-> one] : one \in CheckedNoiiMessage }
        \cup { [tag |-> EndOfReplaySequenceMessageCode, body |-> one] : one \in CheckedEndOfReplaySequenceMessage }

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
        \cup [ tag : {ServerHeartbeatPacketCode}, body : {0} ]
        \cup [ tag : {EndOfSessionPacketCode}, body : {0} ]

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
              [] tag = ServerHeartbeatPacketCode -> Ok(0, bytes)
              [] tag = EndOfSessionPacketCode -> Ok(0, bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> ServerHeartbeatPacketCode, body |-> 0] }
        \cup { [tag |-> EndOfSessionPacketCode, body |-> 0] }

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
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatPacketCode, body |-> 0]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> EndOfSessionPacketCode, body |-> 0]] }

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

(* Every Options Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsDirectoryMessage ==
    \A message \in CheckedOptionsDirectoryMessage :
        LET read == DecodeOptionsDirectoryMessage(EncodeOptionsDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingActionMessage ==
    \A message \in CheckedTradingActionMessage :
        LET read == DecodeTradingActionMessage(EncodeTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Open Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityOpenMessage ==
    \A message \in CheckedSecurityOpenMessage :
        LET read == DecodeSecurityOpenMessage(EncodeSecurityOpenMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Message Short Message Form decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessageShortMessageForm ==
    \A message \in CheckedAddOrderMessageShortMessageForm :
        LET read == DecodeAddOrderMessageShortMessageForm(EncodeAddOrderMessageShortMessageForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Message Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessageLongFormMessage ==
    \A message \in CheckedAddOrderMessageLongFormMessage :
        LET read == DecodeAddOrderMessageLongFormMessage(EncodeAddOrderMessageLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Quote Message Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddQuoteMessageShortFormMessage ==
    \A message \in CheckedAddQuoteMessageShortFormMessage :
        LET read == DecodeAddQuoteMessageShortFormMessage(EncodeAddQuoteMessageShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Quote Message Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddQuoteMessageLongFormMessage ==
    \A message \in CheckedAddQuoteMessageLongFormMessage :
        LET read == DecodeAddQuoteMessageLongFormMessage(EncodeAddQuoteMessageLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideExecutedMessage ==
    \A message \in CheckedSingleSideExecutedMessage :
        LET read == DecodeSingleSideExecutedMessage(EncodeSingleSideExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Executed With Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideExecutedWithPriceMessage ==
    \A message \in CheckedSingleSideExecutedWithPriceMessage :
        LET read == DecodeSingleSideExecutedWithPriceMessage(EncodeSingleSideExecutedWithPriceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelMessage ==
    \A message \in CheckedOrderCancelMessage :
        LET read == DecodeOrderCancelMessage(EncodeOrderCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Replace Message Short Form decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideReplaceMessageShortForm ==
    \A message \in CheckedSingleSideReplaceMessageShortForm :
        LET read == DecodeSingleSideReplaceMessageShortForm(EncodeSingleSideReplaceMessageShortForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Replace Message Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideReplaceMessageLongForm ==
    \A message \in CheckedSingleSideReplaceMessageLongForm :
        LET read == DecodeSingleSideReplaceMessageLongForm(EncodeSingleSideReplaceMessageLongForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideDeleteMessage ==
    \A message \in CheckedSingleSideDeleteMessage :
        LET read == DecodeSingleSideDeleteMessage(EncodeSingleSideDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Single Side Change Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSingleSideChangeMessage ==
    \A message \in CheckedSingleSideChangeMessage :
        LET read == DecodeSingleSideChangeMessage(EncodeSingleSideChangeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Replace Message Short Form decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteReplaceMessageShortForm ==
    \A message \in CheckedQuoteReplaceMessageShortForm :
        LET read == DecodeQuoteReplaceMessageShortForm(EncodeQuoteReplaceMessageShortForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Replace Message Long Form decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteReplaceMessageLongForm ==
    \A message \in CheckedQuoteReplaceMessageLongForm :
        LET read == DecodeQuoteReplaceMessageLongForm(EncodeQuoteReplaceMessageLongForm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteDeleteMessage ==
    \A message \in CheckedQuoteDeleteMessage :
        LET read == DecodeQuoteDeleteMessage(EncodeQuoteDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Trade Messages Non Auction decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsTradeMessagesNonAuction ==
    \A message \in CheckedOptionsTradeMessagesNonAuction :
        LET read == DecodeOptionsTradeMessagesNonAuction(EncodeOptionsTradeMessagesNonAuction(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Options Cross Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionsCrossTradeMessage ==
    \A message \in CheckedOptionsCrossTradeMessage :
        LET read == DecodeOptionsCrossTradeMessage(EncodeOptionsCrossTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broken Trade Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeOrderExecutedMessage ==
    \A message \in CheckedBrokenTradeOrderExecutedMessage :
        LET read == DecodeBrokenTradeOrderExecutedMessage(EncodeBrokenTradeOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Noii Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNoiiMessage ==
    \A message \in CheckedNoiiMessage :
        LET read == DecodeNoiiMessage(EncodeNoiiMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every End Of Replay Sequence Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEndOfReplaySequenceMessage ==
    \A message \in CheckedEndOfReplaySequenceMessage :
        LET read == DecodeEndOfReplaySequenceMessage(EncodeEndOfReplaySequenceMessage(message))
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
