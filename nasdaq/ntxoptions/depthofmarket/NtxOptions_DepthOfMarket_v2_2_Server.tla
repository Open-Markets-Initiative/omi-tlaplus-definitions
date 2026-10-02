--------------- MODULE NtxOptions_DepthOfMarket_v2_2_Server ----------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Depth Of Market v2.2                                           *)
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
    [ trackingNumber : Sample(2),
      timestamp      : Sample(8),
      eventCode      : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         eventCode      |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      eventCode      |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Derivative Directory Message: 86 bytes                                  *)
(***************************************************************************)

DerivativeDirectoryMessage ==
    [ trackingNumber      : Sample(2),
      timestamp           : Sample(8),
      instrumentId        : Sample(4),
      securitySymbol      : Sample(6),
      expirationYear      : Sample(1),
      expirationMonth     : Sample(1),
      expirationDate      : Sample(1),
      explicitStrikePrice : Sample(4),
      optionType          : Sample(1),
      underlyingSymbol    : Sample(13),
      closingType         : Sample(1),
      tradable            : Sample(1),
      mpv                 : Sample(1),
      isin                : Sample(12),
      tickSizeTableId     : Sample(2),
      priceNotation       : Sample(1),
      volumeNotation      : Sample(1),
      financialProduct    : Sample(2),
      marketSegmentId     : Sample(1),
      tradingCurrency     : Sample(3),
      mic                 : Sample(4),
      instrumentLongName  : Sample(16) ]

EncodeDerivativeDirectoryMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.securitySymbol
        \o message.expirationYear
        \o message.expirationMonth
        \o message.expirationDate
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.underlyingSymbol
        \o message.closingType
        \o message.tradable
        \o message.mpv
        \o message.isin
        \o message.tickSizeTableId
        \o message.priceNotation
        \o message.volumeNotation
        \o message.financialProduct
        \o message.marketSegmentId
        \o message.tradingCurrency
        \o message.mic
        \o message.instrumentLongName

DecodeDerivativeDirectoryMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(instrumentId.rest, 6) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(securitySymbol.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    LET expirationMonth == ReadBytes(expirationYear.rest, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDate.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expirationDate.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(optionType.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET closingType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~closingType.ok THEN Fail ELSE
    LET tradable == ReadBytes(closingType.rest, 1) IN IF ~tradable.ok THEN Fail ELSE
    LET mpv == ReadBytes(tradable.rest, 1) IN IF ~mpv.ok THEN Fail ELSE
    LET isin == ReadBytes(mpv.rest, 12) IN IF ~isin.ok THEN Fail ELSE
    LET tickSizeTableId == ReadBytes(isin.rest, 2) IN IF ~tickSizeTableId.ok THEN Fail ELSE
    LET priceNotation == ReadBytes(tickSizeTableId.rest, 1) IN IF ~priceNotation.ok THEN Fail ELSE
    LET volumeNotation == ReadBytes(priceNotation.rest, 1) IN IF ~volumeNotation.ok THEN Fail ELSE
    LET financialProduct == ReadBytes(volumeNotation.rest, 2) IN IF ~financialProduct.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(financialProduct.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tradingCurrency == ReadBytes(marketSegmentId.rest, 3) IN IF ~tradingCurrency.ok THEN Fail ELSE
    LET mic == ReadBytes(tradingCurrency.rest, 4) IN IF ~mic.ok THEN Fail ELSE
    LET instrumentLongName == ReadBytes(mic.rest, 16) IN IF ~instrumentLongName.ok THEN Fail ELSE
    Ok([ trackingNumber      |-> trackingNumber.value,
         timestamp           |-> timestamp.value,
         instrumentId        |-> instrumentId.value,
         securitySymbol      |-> securitySymbol.value,
         expirationYear      |-> expirationYear.value,
         expirationMonth     |-> expirationMonth.value,
         expirationDate      |-> expirationDate.value,
         explicitStrikePrice |-> explicitStrikePrice.value,
         optionType          |-> optionType.value,
         underlyingSymbol    |-> underlyingSymbol.value,
         closingType         |-> closingType.value,
         tradable            |-> tradable.value,
         mpv                 |-> mpv.value,
         isin                |-> isin.value,
         tickSizeTableId     |-> tickSizeTableId.value,
         priceNotation       |-> priceNotation.value,
         volumeNotation      |-> volumeNotation.value,
         financialProduct    |-> financialProduct.value,
         marketSegmentId     |-> marketSegmentId.value,
         tradingCurrency     |-> tradingCurrency.value,
         mic                 |-> mic.value,
         instrumentLongName  |-> instrumentLongName.value ], instrumentLongName.rest)

ZeroDerivativeDirectoryMessage ==
    [ trackingNumber      |-> [i \in 1 .. 2 |-> 0],
      timestamp           |-> [i \in 1 .. 8 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      securitySymbol      |-> [i \in 1 .. 6 |-> 0],
      expirationYear      |-> [i \in 1 .. 1 |-> 0],
      expirationMonth     |-> [i \in 1 .. 1 |-> 0],
      expirationDate      |-> [i \in 1 .. 1 |-> 0],
      explicitStrikePrice |-> [i \in 1 .. 4 |-> 0],
      optionType          |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol    |-> [i \in 1 .. 13 |-> 0],
      closingType         |-> [i \in 1 .. 1 |-> 0],
      tradable            |-> [i \in 1 .. 1 |-> 0],
      mpv                 |-> [i \in 1 .. 1 |-> 0],
      isin                |-> [i \in 1 .. 12 |-> 0],
      tickSizeTableId     |-> [i \in 1 .. 2 |-> 0],
      priceNotation       |-> [i \in 1 .. 1 |-> 0],
      volumeNotation      |-> [i \in 1 .. 1 |-> 0],
      financialProduct    |-> [i \in 1 .. 2 |-> 0],
      marketSegmentId     |-> [i \in 1 .. 1 |-> 0],
      tradingCurrency     |-> [i \in 1 .. 3 |-> 0],
      mic                 |-> [i \in 1 .. 4 |-> 0],
      instrumentLongName  |-> [i \in 1 .. 16 |-> 0] ]

(* Derivative Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativeDirectoryMessage ==
    { ZeroDerivativeDirectoryMessage }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.expirationYear = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.expirationDate = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.closingType = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.tradable = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.mpv = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.isin = one] : one \in Sample(12) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.tickSizeTableId = one] : one \in Sample(2) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.priceNotation = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.volumeNotation = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.financialProduct = one] : one \in Sample(2) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.tradingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.mic = one] : one \in Sample(4) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.instrumentLongName = one] : one \in Sample(16) }

(***************************************************************************)
(* Trading Action Message: 15 bytes                                        *)
(***************************************************************************)

TradingActionMessage ==
    [ trackingNumber      : Sample(2),
      timestamp           : Sample(8),
      instrumentId        : Sample(4),
      currentTradingState : Sample(1) ]

EncodeTradingActionMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.currentTradingState

DecodeTradingActionMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(instrumentId.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    Ok([ trackingNumber      |-> trackingNumber.value,
         timestamp           |-> timestamp.value,
         instrumentId        |-> instrumentId.value,
         currentTradingState |-> currentTradingState.value ], currentTradingState.rest)

ZeroTradingActionMessage ==
    [ trackingNumber      |-> [i \in 1 .. 2 |-> 0],
      timestamp           |-> [i \in 1 .. 8 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingActionMessage ==
    { ZeroTradingActionMessage }
        \cup { [ZeroTradingActionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradingActionMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order Short Form Message: 30 bytes                                  *)
(***************************************************************************)

AddOrderShortFormMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      instrumentId         : Sample(4),
      orderReferenceNumber : Sample(8),
      marketSide           : Sample(1),
      orderCapacity        : Sample(1),
      priceShort           : Sample(2),
      volumeShort          : Sample(2),
      rank                 : Sample(2) ]

EncodeAddOrderShortFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.orderReferenceNumber
        \o message.marketSide
        \o message.orderCapacity
        \o message.priceShort
        \o message.volumeShort
        \o message.rank

DecodeAddOrderShortFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET marketSide == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~marketSide.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(marketSide.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET priceShort == ReadBytes(orderCapacity.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET volumeShort == ReadBytes(priceShort.rest, 2) IN IF ~volumeShort.ok THEN Fail ELSE
    LET rank == ReadBytes(volumeShort.rest, 2) IN IF ~rank.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         instrumentId         |-> instrumentId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         marketSide           |-> marketSide.value,
         orderCapacity        |-> orderCapacity.value,
         priceShort           |-> priceShort.value,
         volumeShort          |-> volumeShort.value,
         rank                 |-> rank.value ], rank.rest)

ZeroAddOrderShortFormMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      marketSide           |-> [i \in 1 .. 1 |-> 0],
      orderCapacity        |-> [i \in 1 .. 1 |-> 0],
      priceShort           |-> [i \in 1 .. 2 |-> 0],
      volumeShort          |-> [i \in 1 .. 2 |-> 0],
      rank                 |-> [i \in 1 .. 2 |-> 0] ]

(* Add Order Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderShortFormMessage ==
    { ZeroAddOrderShortFormMessage }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.marketSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.volumeShort = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderShortFormMessage EXCEPT !.rank = one] : one \in Sample(2) }

(***************************************************************************)
(* Add Order Long Form Message: 34 bytes                                   *)
(***************************************************************************)

AddOrderLongFormMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      instrumentId         : Sample(4),
      orderReferenceNumber : Sample(8),
      marketSide           : Sample(1),
      orderCapacity        : Sample(1),
      priceLong            : Sample(4),
      volumeLong           : Sample(4),
      rank                 : Sample(2) ]

EncodeAddOrderLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.orderReferenceNumber
        \o message.marketSide
        \o message.orderCapacity
        \o message.priceLong
        \o message.volumeLong
        \o message.rank

DecodeAddOrderLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET marketSide == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~marketSide.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(marketSide.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET priceLong == ReadBytes(orderCapacity.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    LET rank == ReadBytes(volumeLong.rest, 2) IN IF ~rank.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         instrumentId         |-> instrumentId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         marketSide           |-> marketSide.value,
         orderCapacity        |-> orderCapacity.value,
         priceLong            |-> priceLong.value,
         volumeLong           |-> volumeLong.value,
         rank                 |-> rank.value ], rank.rest)

ZeroAddOrderLongFormMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      marketSide           |-> [i \in 1 .. 1 |-> 0],
      orderCapacity        |-> [i \in 1 .. 1 |-> 0],
      priceLong            |-> [i \in 1 .. 4 |-> 0],
      volumeLong           |-> [i \in 1 .. 4 |-> 0],
      rank                 |-> [i \in 1 .. 2 |-> 0] ]

(* Add Order Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderLongFormMessage ==
    { ZeroAddOrderLongFormMessage }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.marketSide = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderLongFormMessage EXCEPT !.rank = one] : one \in Sample(2) }

(***************************************************************************)
(* Add Quote Short Form Message: 38 bytes                                  *)
(***************************************************************************)

AddQuoteShortFormMessage ==
    [ trackingNumber     : Sample(2),
      timestamp          : Sample(8),
      instrumentId       : Sample(4),
      bidReferenceNumber : Sample(8),
      askReferenceNumber : Sample(8),
      bidPriceShort      : Sample(2),
      bidSizeShort       : Sample(2),
      askPriceShort      : Sample(2),
      askSizeShort       : Sample(2) ]

EncodeAddQuoteShortFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.bidReferenceNumber
        \o message.askReferenceNumber
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.askPriceShort
        \o message.askSizeShort

DecodeAddQuoteShortFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(askReferenceNumber.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET askPriceShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~askPriceShort.ok THEN Fail ELSE
    LET askSizeShort == ReadBytes(askPriceShort.rest, 2) IN IF ~askSizeShort.ok THEN Fail ELSE
    Ok([ trackingNumber     |-> trackingNumber.value,
         timestamp          |-> timestamp.value,
         instrumentId       |-> instrumentId.value,
         bidReferenceNumber |-> bidReferenceNumber.value,
         askReferenceNumber |-> askReferenceNumber.value,
         bidPriceShort      |-> bidPriceShort.value,
         bidSizeShort       |-> bidSizeShort.value,
         askPriceShort      |-> askPriceShort.value,
         askSizeShort       |-> askSizeShort.value ], askSizeShort.rest)

ZeroAddQuoteShortFormMessage ==
    [ trackingNumber     |-> [i \in 1 .. 2 |-> 0],
      timestamp          |-> [i \in 1 .. 8 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      bidPriceShort      |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort       |-> [i \in 1 .. 2 |-> 0],
      askPriceShort      |-> [i \in 1 .. 2 |-> 0],
      askSizeShort       |-> [i \in 1 .. 2 |-> 0] ]

(* Add Quote Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddQuoteShortFormMessage ==
    { ZeroAddQuoteShortFormMessage }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.askPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteShortFormMessage EXCEPT !.askSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Add Quote Long Form Message: 46 bytes                                   *)
(***************************************************************************)

AddQuoteLongFormMessage ==
    [ trackingNumber     : Sample(2),
      timestamp          : Sample(8),
      instrumentId       : Sample(4),
      bidReferenceNumber : Sample(8),
      askReferenceNumber : Sample(8),
      bidPriceLong       : Sample(4),
      bidSizeLong        : Sample(4),
      askPriceLong       : Sample(4),
      askSizeLong        : Sample(4) ]

EncodeAddQuoteLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.bidReferenceNumber
        \o message.askReferenceNumber
        \o message.bidPriceLong
        \o message.bidSizeLong
        \o message.askPriceLong
        \o message.askSizeLong

DecodeAddQuoteLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(askReferenceNumber.rest, 4) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(bidSizeLong.rest, 4) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(askPriceLong.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    Ok([ trackingNumber     |-> trackingNumber.value,
         timestamp          |-> timestamp.value,
         instrumentId       |-> instrumentId.value,
         bidReferenceNumber |-> bidReferenceNumber.value,
         askReferenceNumber |-> askReferenceNumber.value,
         bidPriceLong       |-> bidPriceLong.value,
         bidSizeLong        |-> bidSizeLong.value,
         askPriceLong       |-> askPriceLong.value,
         askSizeLong        |-> askSizeLong.value ], askSizeLong.rest)

ZeroAddQuoteLongFormMessage ==
    [ trackingNumber     |-> [i \in 1 .. 2 |-> 0],
      timestamp          |-> [i \in 1 .. 8 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      bidPriceLong       |-> [i \in 1 .. 4 |-> 0],
      bidSizeLong        |-> [i \in 1 .. 4 |-> 0],
      askPriceLong       |-> [i \in 1 .. 4 |-> 0],
      askSizeLong        |-> [i \in 1 .. 4 |-> 0] ]

(* Add Quote Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedAddQuoteLongFormMessage ==
    { ZeroAddQuoteLongFormMessage }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.bidPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.askPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroAddQuoteLongFormMessage EXCEPT !.askSizeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed Message: 38 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ trackingNumber  : Sample(2),
      timestamp       : Sample(8),
      instrumentId    : Sample(4),
      strategyId      : Sample(4),
      referenceNumber : Sample(8),
      executedVolume  : Sample(4),
      crossNumber     : Sample(4),
      matchNumber     : Sample(4) ]

EncodeOrderExecutedMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.strategyId
        \o message.referenceNumber
        \o message.executedVolume
        \o message.crossNumber
        \o message.matchNumber

DecodeOrderExecutedMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET strategyId == ReadBytes(instrumentId.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET referenceNumber == ReadBytes(strategyId.rest, 8) IN IF ~referenceNumber.ok THEN Fail ELSE
    LET executedVolume == ReadBytes(referenceNumber.rest, 4) IN IF ~executedVolume.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(executedVolume.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ trackingNumber  |-> trackingNumber.value,
         timestamp       |-> timestamp.value,
         instrumentId    |-> instrumentId.value,
         strategyId      |-> strategyId.value,
         referenceNumber |-> referenceNumber.value,
         executedVolume  |-> executedVolume.value,
         crossNumber     |-> crossNumber.value,
         matchNumber     |-> matchNumber.value ], matchNumber.rest)

ZeroOrderExecutedMessage ==
    [ trackingNumber  |-> [i \in 1 .. 2 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0],
      instrumentId    |-> [i \in 1 .. 4 |-> 0],
      strategyId      |-> [i \in 1 .. 4 |-> 0],
      referenceNumber |-> [i \in 1 .. 8 |-> 0],
      executedVolume  |-> [i \in 1 .. 4 |-> 0],
      crossNumber     |-> [i \in 1 .. 4 |-> 0],
      matchNumber     |-> [i \in 1 .. 4 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.referenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed With Price Message: 43 bytes                             *)
(***************************************************************************)

OrderExecutedWithPriceMessage ==
    [ trackingNumber  : Sample(2),
      timestamp       : Sample(8),
      instrumentId    : Sample(4),
      strategyId      : Sample(4),
      referenceNumber : Sample(8),
      crossNumber     : Sample(4),
      matchNumber     : Sample(4),
      printable       : Sample(1),
      priceLong       : Sample(4),
      volumeLong      : Sample(4) ]

EncodeOrderExecutedWithPriceMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.strategyId
        \o message.referenceNumber
        \o message.crossNumber
        \o message.matchNumber
        \o message.printable
        \o message.priceLong
        \o message.volumeLong

DecodeOrderExecutedWithPriceMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET strategyId == ReadBytes(instrumentId.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET referenceNumber == ReadBytes(strategyId.rest, 8) IN IF ~referenceNumber.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(referenceNumber.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET printable == ReadBytes(matchNumber.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET priceLong == ReadBytes(printable.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ trackingNumber  |-> trackingNumber.value,
         timestamp       |-> timestamp.value,
         instrumentId    |-> instrumentId.value,
         strategyId      |-> strategyId.value,
         referenceNumber |-> referenceNumber.value,
         crossNumber     |-> crossNumber.value,
         matchNumber     |-> matchNumber.value,
         printable       |-> printable.value,
         priceLong       |-> priceLong.value,
         volumeLong      |-> volumeLong.value ], volumeLong.rest)

ZeroOrderExecutedWithPriceMessage ==
    [ trackingNumber  |-> [i \in 1 .. 2 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0],
      instrumentId    |-> [i \in 1 .. 4 |-> 0],
      strategyId      |-> [i \in 1 .. 4 |-> 0],
      referenceNumber |-> [i \in 1 .. 8 |-> 0],
      crossNumber     |-> [i \in 1 .. 4 |-> 0],
      matchNumber     |-> [i \in 1 .. 4 |-> 0],
      printable       |-> [i \in 1 .. 1 |-> 0],
      priceLong       |-> [i \in 1 .. 4 |-> 0],
      volumeLong      |-> [i \in 1 .. 4 |-> 0] ]

(* Order Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceMessage ==
    { ZeroOrderExecutedWithPriceMessage }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.referenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Message: 26 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ trackingNumber       : Sample(2),
      timestamp            : Sample(8),
      instrumentId         : Sample(4),
      orderReferenceNumber : Sample(8),
      cancelledVolume      : Sample(4) ]

EncodeOrderCancelMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.orderReferenceNumber
        \o message.cancelledVolume

DecodeOrderCancelMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET cancelledVolume == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~cancelledVolume.ok THEN Fail ELSE
    Ok([ trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         instrumentId         |-> instrumentId.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         cancelledVolume      |-> cancelledVolume.value ], cancelledVolume.rest)

ZeroOrderCancelMessage ==
    [ trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 8 |-> 0],
      instrumentId         |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      cancelledVolume      |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.cancelledVolume = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Replace Short Form Message: 34 bytes                              *)
(***************************************************************************)

OrderReplaceShortFormMessage ==
    [ trackingNumber          : Sample(2),
      timestamp               : Sample(8),
      instrumentId            : Sample(4),
      originalReferenceNumber : Sample(8),
      newReferenceNumber      : Sample(8),
      priceShort              : Sample(2),
      volumeShort             : Sample(2) ]

EncodeOrderReplaceShortFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.originalReferenceNumber
        \o message.newReferenceNumber
        \o message.priceShort
        \o message.volumeShort

DecodeOrderReplaceShortFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET originalReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~originalReferenceNumber.ok THEN Fail ELSE
    LET newReferenceNumber == ReadBytes(originalReferenceNumber.rest, 8) IN IF ~newReferenceNumber.ok THEN Fail ELSE
    LET priceShort == ReadBytes(newReferenceNumber.rest, 2) IN IF ~priceShort.ok THEN Fail ELSE
    LET volumeShort == ReadBytes(priceShort.rest, 2) IN IF ~volumeShort.ok THEN Fail ELSE
    Ok([ trackingNumber          |-> trackingNumber.value,
         timestamp               |-> timestamp.value,
         instrumentId            |-> instrumentId.value,
         originalReferenceNumber |-> originalReferenceNumber.value,
         newReferenceNumber      |-> newReferenceNumber.value,
         priceShort              |-> priceShort.value,
         volumeShort             |-> volumeShort.value ], volumeShort.rest)

ZeroOrderReplaceShortFormMessage ==
    [ trackingNumber          |-> [i \in 1 .. 2 |-> 0],
      timestamp               |-> [i \in 1 .. 8 |-> 0],
      instrumentId            |-> [i \in 1 .. 4 |-> 0],
      originalReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      newReferenceNumber      |-> [i \in 1 .. 8 |-> 0],
      priceShort              |-> [i \in 1 .. 2 |-> 0],
      volumeShort             |-> [i \in 1 .. 2 |-> 0] ]

(* Order Replace Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceShortFormMessage ==
    { ZeroOrderReplaceShortFormMessage }
        \cup { [ZeroOrderReplaceShortFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderReplaceShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceShortFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceShortFormMessage EXCEPT !.originalReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceShortFormMessage EXCEPT !.newReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceShortFormMessage EXCEPT !.priceShort = one] : one \in Sample(2) }
        \cup { [ZeroOrderReplaceShortFormMessage EXCEPT !.volumeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Replace Long Form Message: 38 bytes                               *)
(***************************************************************************)

OrderReplaceLongFormMessage ==
    [ trackingNumber          : Sample(2),
      timestamp               : Sample(8),
      instrumentId            : Sample(4),
      originalReferenceNumber : Sample(8),
      newReferenceNumber      : Sample(8),
      priceLong               : Sample(4),
      volumeLong              : Sample(4) ]

EncodeOrderReplaceLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.originalReferenceNumber
        \o message.newReferenceNumber
        \o message.priceLong
        \o message.volumeLong

DecodeOrderReplaceLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET originalReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~originalReferenceNumber.ok THEN Fail ELSE
    LET newReferenceNumber == ReadBytes(originalReferenceNumber.rest, 8) IN IF ~newReferenceNumber.ok THEN Fail ELSE
    LET priceLong == ReadBytes(newReferenceNumber.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ trackingNumber          |-> trackingNumber.value,
         timestamp               |-> timestamp.value,
         instrumentId            |-> instrumentId.value,
         originalReferenceNumber |-> originalReferenceNumber.value,
         newReferenceNumber      |-> newReferenceNumber.value,
         priceLong               |-> priceLong.value,
         volumeLong              |-> volumeLong.value ], volumeLong.rest)

ZeroOrderReplaceLongFormMessage ==
    [ trackingNumber          |-> [i \in 1 .. 2 |-> 0],
      timestamp               |-> [i \in 1 .. 8 |-> 0],
      instrumentId            |-> [i \in 1 .. 4 |-> 0],
      originalReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      newReferenceNumber      |-> [i \in 1 .. 8 |-> 0],
      priceLong               |-> [i \in 1 .. 4 |-> 0],
      volumeLong              |-> [i \in 1 .. 4 |-> 0] ]

(* Order Replace Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceLongFormMessage ==
    { ZeroOrderReplaceLongFormMessage }
        \cup { [ZeroOrderReplaceLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderReplaceLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceLongFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceLongFormMessage EXCEPT !.originalReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceLongFormMessage EXCEPT !.newReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceLongFormMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceLongFormMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Delete Message: 22 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ trackingNumber  : Sample(2),
      timestamp       : Sample(8),
      instrumentId    : Sample(4),
      referenceNumber : Sample(8) ]

EncodeOrderDeleteMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.referenceNumber

DecodeOrderDeleteMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET referenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~referenceNumber.ok THEN Fail ELSE
    Ok([ trackingNumber  |-> trackingNumber.value,
         timestamp       |-> timestamp.value,
         instrumentId    |-> instrumentId.value,
         referenceNumber |-> referenceNumber.value ], referenceNumber.rest)

ZeroOrderDeleteMessage ==
    [ trackingNumber  |-> [i \in 1 .. 2 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0],
      instrumentId    |-> [i \in 1 .. 4 |-> 0],
      referenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.referenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Change Message: 31 bytes                                          *)
(***************************************************************************)

OrderChangeMessage ==
    [ trackingNumber  : Sample(2),
      timestamp       : Sample(8),
      instrumentId    : Sample(4),
      referenceNumber : Sample(8),
      changeReason    : Sample(1),
      priceLong       : Sample(4),
      volumeLong      : Sample(4) ]

EncodeOrderChangeMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.referenceNumber
        \o message.changeReason
        \o message.priceLong
        \o message.volumeLong

DecodeOrderChangeMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET referenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~referenceNumber.ok THEN Fail ELSE
    LET changeReason == ReadBytes(referenceNumber.rest, 1) IN IF ~changeReason.ok THEN Fail ELSE
    LET priceLong == ReadBytes(changeReason.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    Ok([ trackingNumber  |-> trackingNumber.value,
         timestamp       |-> timestamp.value,
         instrumentId    |-> instrumentId.value,
         referenceNumber |-> referenceNumber.value,
         changeReason    |-> changeReason.value,
         priceLong       |-> priceLong.value,
         volumeLong      |-> volumeLong.value ], volumeLong.rest)

ZeroOrderChangeMessage ==
    [ trackingNumber  |-> [i \in 1 .. 2 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0],
      instrumentId    |-> [i \in 1 .. 4 |-> 0],
      referenceNumber |-> [i \in 1 .. 8 |-> 0],
      changeReason    |-> [i \in 1 .. 1 |-> 0],
      priceLong       |-> [i \in 1 .. 4 |-> 0],
      volumeLong      |-> [i \in 1 .. 4 |-> 0] ]

(* Order Change Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderChangeMessage ==
    { ZeroOrderChangeMessage }
        \cup { [ZeroOrderChangeMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.referenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.changeReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroOrderChangeMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Replace Short Form Message: 54 bytes                              *)
(***************************************************************************)

QuoteReplaceShortFormMessage ==
    [ trackingNumber             : Sample(2),
      timestamp                  : Sample(8),
      instrumentId               : Sample(4),
      originalBidReferenceNumber : Sample(8),
      bidReferenceNumber         : Sample(8),
      originalAskReferenceNumber : Sample(8),
      askReferenceNumber         : Sample(8),
      bidPriceShort              : Sample(2),
      bidSizeShort               : Sample(2),
      askPriceShort              : Sample(2),
      askSizeShort               : Sample(2) ]

EncodeQuoteReplaceShortFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.originalBidReferenceNumber
        \o message.bidReferenceNumber
        \o message.originalAskReferenceNumber
        \o message.askReferenceNumber
        \o message.bidPriceShort
        \o message.bidSizeShort
        \o message.askPriceShort
        \o message.askSizeShort

DecodeQuoteReplaceShortFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET originalBidReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~originalBidReferenceNumber.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(originalBidReferenceNumber.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET originalAskReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~originalAskReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(originalAskReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    LET bidPriceShort == ReadBytes(askReferenceNumber.rest, 2) IN IF ~bidPriceShort.ok THEN Fail ELSE
    LET bidSizeShort == ReadBytes(bidPriceShort.rest, 2) IN IF ~bidSizeShort.ok THEN Fail ELSE
    LET askPriceShort == ReadBytes(bidSizeShort.rest, 2) IN IF ~askPriceShort.ok THEN Fail ELSE
    LET askSizeShort == ReadBytes(askPriceShort.rest, 2) IN IF ~askSizeShort.ok THEN Fail ELSE
    Ok([ trackingNumber             |-> trackingNumber.value,
         timestamp                  |-> timestamp.value,
         instrumentId               |-> instrumentId.value,
         originalBidReferenceNumber |-> originalBidReferenceNumber.value,
         bidReferenceNumber         |-> bidReferenceNumber.value,
         originalAskReferenceNumber |-> originalAskReferenceNumber.value,
         askReferenceNumber         |-> askReferenceNumber.value,
         bidPriceShort              |-> bidPriceShort.value,
         bidSizeShort               |-> bidSizeShort.value,
         askPriceShort              |-> askPriceShort.value,
         askSizeShort               |-> askSizeShort.value ], askSizeShort.rest)

ZeroQuoteReplaceShortFormMessage ==
    [ trackingNumber             |-> [i \in 1 .. 2 |-> 0],
      timestamp                  |-> [i \in 1 .. 8 |-> 0],
      instrumentId               |-> [i \in 1 .. 4 |-> 0],
      originalBidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      bidReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      originalAskReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      bidPriceShort              |-> [i \in 1 .. 2 |-> 0],
      bidSizeShort               |-> [i \in 1 .. 2 |-> 0],
      askPriceShort              |-> [i \in 1 .. 2 |-> 0],
      askSizeShort               |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Replace Short Form Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteReplaceShortFormMessage ==
    { ZeroQuoteReplaceShortFormMessage }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.originalBidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.originalAskReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.bidPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.bidSizeShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.askPriceShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceShortFormMessage EXCEPT !.askSizeShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Quote Replace Long Form Message: 62 bytes                               *)
(***************************************************************************)

QuoteReplaceLongFormMessage ==
    [ trackingNumber             : Sample(2),
      timestamp                  : Sample(8),
      instrumentId               : Sample(4),
      originalBidReferenceNumber : Sample(8),
      bidReferenceNumber         : Sample(8),
      originalAskReferenceNumber : Sample(8),
      askReferenceNumber         : Sample(8),
      bidPriceLong               : Sample(4),
      bidSizeLong                : Sample(4),
      askPriceLong               : Sample(4),
      askSizeLong                : Sample(4) ]

EncodeQuoteReplaceLongFormMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.originalBidReferenceNumber
        \o message.bidReferenceNumber
        \o message.originalAskReferenceNumber
        \o message.askReferenceNumber
        \o message.bidPriceLong
        \o message.bidSizeLong
        \o message.askPriceLong
        \o message.askSizeLong

DecodeQuoteReplaceLongFormMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET originalBidReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~originalBidReferenceNumber.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(originalBidReferenceNumber.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET originalAskReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~originalAskReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(originalAskReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    LET bidPriceLong == ReadBytes(askReferenceNumber.rest, 4) IN IF ~bidPriceLong.ok THEN Fail ELSE
    LET bidSizeLong == ReadBytes(bidPriceLong.rest, 4) IN IF ~bidSizeLong.ok THEN Fail ELSE
    LET askPriceLong == ReadBytes(bidSizeLong.rest, 4) IN IF ~askPriceLong.ok THEN Fail ELSE
    LET askSizeLong == ReadBytes(askPriceLong.rest, 4) IN IF ~askSizeLong.ok THEN Fail ELSE
    Ok([ trackingNumber             |-> trackingNumber.value,
         timestamp                  |-> timestamp.value,
         instrumentId               |-> instrumentId.value,
         originalBidReferenceNumber |-> originalBidReferenceNumber.value,
         bidReferenceNumber         |-> bidReferenceNumber.value,
         originalAskReferenceNumber |-> originalAskReferenceNumber.value,
         askReferenceNumber         |-> askReferenceNumber.value,
         bidPriceLong               |-> bidPriceLong.value,
         bidSizeLong                |-> bidSizeLong.value,
         askPriceLong               |-> askPriceLong.value,
         askSizeLong                |-> askSizeLong.value ], askSizeLong.rest)

ZeroQuoteReplaceLongFormMessage ==
    [ trackingNumber             |-> [i \in 1 .. 2 |-> 0],
      timestamp                  |-> [i \in 1 .. 8 |-> 0],
      instrumentId               |-> [i \in 1 .. 4 |-> 0],
      originalBidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      bidReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      originalAskReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber         |-> [i \in 1 .. 8 |-> 0],
      bidPriceLong               |-> [i \in 1 .. 4 |-> 0],
      bidSizeLong                |-> [i \in 1 .. 4 |-> 0],
      askPriceLong               |-> [i \in 1 .. 4 |-> 0],
      askSizeLong                |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Replace Long Form Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteReplaceLongFormMessage ==
    { ZeroQuoteReplaceLongFormMessage }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.originalBidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.originalAskReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.bidPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.bidSizeLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.askPriceLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteReplaceLongFormMessage EXCEPT !.askSizeLong = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Delete Message: 30 bytes                                          *)
(***************************************************************************)

QuoteDeleteMessage ==
    [ trackingNumber     : Sample(2),
      timestamp          : Sample(8),
      instrumentId       : Sample(4),
      bidReferenceNumber : Sample(8),
      askReferenceNumber : Sample(8) ]

EncodeQuoteDeleteMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.bidReferenceNumber
        \o message.askReferenceNumber

DecodeQuoteDeleteMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET bidReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~bidReferenceNumber.ok THEN Fail ELSE
    LET askReferenceNumber == ReadBytes(bidReferenceNumber.rest, 8) IN IF ~askReferenceNumber.ok THEN Fail ELSE
    Ok([ trackingNumber     |-> trackingNumber.value,
         timestamp          |-> timestamp.value,
         instrumentId       |-> instrumentId.value,
         bidReferenceNumber |-> bidReferenceNumber.value,
         askReferenceNumber |-> askReferenceNumber.value ], askReferenceNumber.rest)

ZeroQuoteDeleteMessage ==
    [ trackingNumber     |-> [i \in 1 .. 2 |-> 0],
      timestamp          |-> [i \in 1 .. 8 |-> 0],
      instrumentId       |-> [i \in 1 .. 4 |-> 0],
      bidReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      askReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteDeleteMessage ==
    { ZeroQuoteDeleteMessage }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.bidReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroQuoteDeleteMessage EXCEPT !.askReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Message: 37 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ trackingNumber : Sample(2),
      timestamp      : Sample(8),
      instrumentId   : Sample(4),
      crossNumber    : Sample(4),
      matchNumber    : Sample(4),
      strategyId     : Sample(4),
      crossType      : Sample(1),
      priceLong      : Sample(4),
      volumeLong     : Sample(4),
      printable      : Sample(1),
      tradeType      : Sample(1) ]

EncodeTradeMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.crossNumber
        \o message.matchNumber
        \o message.strategyId
        \o message.crossType
        \o message.priceLong
        \o message.volumeLong
        \o message.printable
        \o message.tradeType

DecodeTradeMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET crossNumber == ReadBytes(instrumentId.rest, 4) IN IF ~crossNumber.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossNumber.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET strategyId == ReadBytes(matchNumber.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET crossType == ReadBytes(strategyId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET priceLong == ReadBytes(crossType.rest, 4) IN IF ~priceLong.ok THEN Fail ELSE
    LET volumeLong == ReadBytes(priceLong.rest, 4) IN IF ~volumeLong.ok THEN Fail ELSE
    LET printable == ReadBytes(volumeLong.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET tradeType == ReadBytes(printable.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    Ok([ trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         instrumentId   |-> instrumentId.value,
         crossNumber    |-> crossNumber.value,
         matchNumber    |-> matchNumber.value,
         strategyId     |-> strategyId.value,
         crossType      |-> crossType.value,
         priceLong      |-> priceLong.value,
         volumeLong     |-> volumeLong.value,
         printable      |-> printable.value,
         tradeType      |-> tradeType.value ], tradeType.rest)

ZeroTradeMessage ==
    [ trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      instrumentId   |-> [i \in 1 .. 4 |-> 0],
      crossNumber    |-> [i \in 1 .. 4 |-> 0],
      matchNumber    |-> [i \in 1 .. 4 |-> 0],
      strategyId     |-> [i \in 1 .. 4 |-> 0],
      crossType      |-> [i \in 1 .. 1 |-> 0],
      priceLong      |-> [i \in 1 .. 4 |-> 0],
      volumeLong     |-> [i \in 1 .. 4 |-> 0],
      printable      |-> [i \in 1 .. 1 |-> 0],
      tradeType      |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.crossNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.priceLong = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.volumeLong = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeType = one] : one \in Sample(1) }

(***************************************************************************)
(* Net Order Imbalance Message: 49 bytes                                   *)
(***************************************************************************)

NetOrderImbalanceMessage ==
    [ trackingNumber        : Sample(2),
      timestamp             : Sample(8),
      instrumentId          : Sample(4),
      auctionId             : Sample(4),
      auctionType           : Sample(1),
      pairedQuantity        : Sample(4),
      imbalanceDirection    : Sample(1),
      imbalancePrice        : Sample(4),
      imbalanceVolume       : Sample(4),
      customerFirmIndicator : Sample(1),
      bestBidPrice          : Sample(4),
      bestBidQuantity       : Sample(4),
      bestAskPrice          : Sample(4),
      bestAskQuantity       : Sample(4) ]

EncodeNetOrderImbalanceMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.auctionId
        \o message.auctionType
        \o message.pairedQuantity
        \o message.imbalanceDirection
        \o message.imbalancePrice
        \o message.imbalanceVolume
        \o message.customerFirmIndicator
        \o message.bestBidPrice
        \o message.bestBidQuantity
        \o message.bestAskPrice
        \o message.bestAskQuantity

DecodeNetOrderImbalanceMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(instrumentId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET pairedQuantity == ReadBytes(auctionType.rest, 4) IN IF ~pairedQuantity.ok THEN Fail ELSE
    LET imbalanceDirection == ReadBytes(pairedQuantity.rest, 1) IN IF ~imbalanceDirection.ok THEN Fail ELSE
    LET imbalancePrice == ReadBytes(imbalanceDirection.rest, 4) IN IF ~imbalancePrice.ok THEN Fail ELSE
    LET imbalanceVolume == ReadBytes(imbalancePrice.rest, 4) IN IF ~imbalanceVolume.ok THEN Fail ELSE
    LET customerFirmIndicator == ReadBytes(imbalanceVolume.rest, 1) IN IF ~customerFirmIndicator.ok THEN Fail ELSE
    LET bestBidPrice == ReadBytes(customerFirmIndicator.rest, 4) IN IF ~bestBidPrice.ok THEN Fail ELSE
    LET bestBidQuantity == ReadBytes(bestBidPrice.rest, 4) IN IF ~bestBidQuantity.ok THEN Fail ELSE
    LET bestAskPrice == ReadBytes(bestBidQuantity.rest, 4) IN IF ~bestAskPrice.ok THEN Fail ELSE
    LET bestAskQuantity == ReadBytes(bestAskPrice.rest, 4) IN IF ~bestAskQuantity.ok THEN Fail ELSE
    Ok([ trackingNumber        |-> trackingNumber.value,
         timestamp             |-> timestamp.value,
         instrumentId          |-> instrumentId.value,
         auctionId             |-> auctionId.value,
         auctionType           |-> auctionType.value,
         pairedQuantity        |-> pairedQuantity.value,
         imbalanceDirection    |-> imbalanceDirection.value,
         imbalancePrice        |-> imbalancePrice.value,
         imbalanceVolume       |-> imbalanceVolume.value,
         customerFirmIndicator |-> customerFirmIndicator.value,
         bestBidPrice          |-> bestBidPrice.value,
         bestBidQuantity       |-> bestBidQuantity.value,
         bestAskPrice          |-> bestAskPrice.value,
         bestAskQuantity       |-> bestAskQuantity.value ], bestAskQuantity.rest)

ZeroNetOrderImbalanceMessage ==
    [ trackingNumber        |-> [i \in 1 .. 2 |-> 0],
      timestamp             |-> [i \in 1 .. 8 |-> 0],
      instrumentId          |-> [i \in 1 .. 4 |-> 0],
      auctionId             |-> [i \in 1 .. 4 |-> 0],
      auctionType           |-> [i \in 1 .. 1 |-> 0],
      pairedQuantity        |-> [i \in 1 .. 4 |-> 0],
      imbalanceDirection    |-> [i \in 1 .. 1 |-> 0],
      imbalancePrice        |-> [i \in 1 .. 4 |-> 0],
      imbalanceVolume       |-> [i \in 1 .. 4 |-> 0],
      customerFirmIndicator |-> [i \in 1 .. 1 |-> 0],
      bestBidPrice          |-> [i \in 1 .. 4 |-> 0],
      bestBidQuantity       |-> [i \in 1 .. 4 |-> 0],
      bestAskPrice          |-> [i \in 1 .. 4 |-> 0],
      bestAskQuantity       |-> [i \in 1 .. 4 |-> 0] ]

(* Net Order Imbalance Message at zero, then each field in turn at the values it is checked at *)
CheckedNetOrderImbalanceMessage ==
    { ZeroNetOrderImbalanceMessage }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.pairedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.imbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.imbalancePrice = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.imbalanceVolume = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.customerFirmIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.bestBidPrice = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.bestBidQuantity = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.bestAskPrice = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceMessage EXCEPT !.bestAskQuantity = one] : one \in Sample(4) }

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
DerivativeDirectoryMessageCode == 82  \* "R"
TradingActionMessageCode == 72  \* "H"
AddOrderShortFormMessageCode == 97  \* "a"
AddOrderLongFormMessageCode == 65  \* "A"
AddQuoteShortFormMessageCode == 106  \* "j"
AddQuoteLongFormMessageCode == 74  \* "J"
OrderExecutedMessageCode == 69  \* "E"
OrderExecutedWithPriceMessageCode == 67  \* "C"
OrderCancelMessageCode == 88  \* "X"
OrderReplaceShortFormMessageCode == 117  \* "u"
OrderReplaceLongFormMessageCode == 85  \* "U"
OrderDeleteMessageCode == 68  \* "D"
OrderChangeMessageCode == 71  \* "G"
QuoteReplaceShortFormMessageCode == 107  \* "k"
QuoteReplaceLongFormMessageCode == 75  \* "K"
QuoteDeleteMessageCode == 89  \* "Y"
TradeMessageCode == 81  \* "Q"
NetOrderImbalanceMessageCode == 73  \* "I"
EndOfReplaySequenceMessageCode == 77  \* "M"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {DerivativeDirectoryMessageCode}, body : DerivativeDirectoryMessage ]
        \cup [ tag : {TradingActionMessageCode}, body : TradingActionMessage ]
        \cup [ tag : {AddOrderShortFormMessageCode}, body : AddOrderShortFormMessage ]
        \cup [ tag : {AddOrderLongFormMessageCode}, body : AddOrderLongFormMessage ]
        \cup [ tag : {AddQuoteShortFormMessageCode}, body : AddQuoteShortFormMessage ]
        \cup [ tag : {AddQuoteLongFormMessageCode}, body : AddQuoteLongFormMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceMessageCode}, body : OrderExecutedWithPriceMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {OrderReplaceShortFormMessageCode}, body : OrderReplaceShortFormMessage ]
        \cup [ tag : {OrderReplaceLongFormMessageCode}, body : OrderReplaceLongFormMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {OrderChangeMessageCode}, body : OrderChangeMessage ]
        \cup [ tag : {QuoteReplaceShortFormMessageCode}, body : QuoteReplaceShortFormMessage ]
        \cup [ tag : {QuoteReplaceLongFormMessageCode}, body : QuoteReplaceLongFormMessage ]
        \cup [ tag : {QuoteDeleteMessageCode}, body : QuoteDeleteMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {NetOrderImbalanceMessageCode}, body : NetOrderImbalanceMessage ]
        \cup [ tag : {EndOfReplaySequenceMessageCode}, body : EndOfReplaySequenceMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = DerivativeDirectoryMessageCode -> EncodeDerivativeDirectoryMessage(message.body)
      [] message.tag = TradingActionMessageCode -> EncodeTradingActionMessage(message.body)
      [] message.tag = AddOrderShortFormMessageCode -> EncodeAddOrderShortFormMessage(message.body)
      [] message.tag = AddOrderLongFormMessageCode -> EncodeAddOrderLongFormMessage(message.body)
      [] message.tag = AddQuoteShortFormMessageCode -> EncodeAddQuoteShortFormMessage(message.body)
      [] message.tag = AddQuoteLongFormMessageCode -> EncodeAddQuoteLongFormMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceMessageCode -> EncodeOrderExecutedWithPriceMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = OrderReplaceShortFormMessageCode -> EncodeOrderReplaceShortFormMessage(message.body)
      [] message.tag = OrderReplaceLongFormMessageCode -> EncodeOrderReplaceLongFormMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = OrderChangeMessageCode -> EncodeOrderChangeMessage(message.body)
      [] message.tag = QuoteReplaceShortFormMessageCode -> EncodeQuoteReplaceShortFormMessage(message.body)
      [] message.tag = QuoteReplaceLongFormMessageCode -> EncodeQuoteReplaceLongFormMessage(message.body)
      [] message.tag = QuoteDeleteMessageCode -> EncodeQuoteDeleteMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = NetOrderImbalanceMessageCode -> EncodeNetOrderImbalanceMessage(message.body)
      [] message.tag = EndOfReplaySequenceMessageCode -> EncodeEndOfReplaySequenceMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = DerivativeDirectoryMessageCode -> DecodeDerivativeDirectoryMessage(bytes)
              [] tag = TradingActionMessageCode -> DecodeTradingActionMessage(bytes)
              [] tag = AddOrderShortFormMessageCode -> DecodeAddOrderShortFormMessage(bytes)
              [] tag = AddOrderLongFormMessageCode -> DecodeAddOrderLongFormMessage(bytes)
              [] tag = AddQuoteShortFormMessageCode -> DecodeAddQuoteShortFormMessage(bytes)
              [] tag = AddQuoteLongFormMessageCode -> DecodeAddQuoteLongFormMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceMessageCode -> DecodeOrderExecutedWithPriceMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = OrderReplaceShortFormMessageCode -> DecodeOrderReplaceShortFormMessage(bytes)
              [] tag = OrderReplaceLongFormMessageCode -> DecodeOrderReplaceLongFormMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = OrderChangeMessageCode -> DecodeOrderChangeMessage(bytes)
              [] tag = QuoteReplaceShortFormMessageCode -> DecodeQuoteReplaceShortFormMessage(bytes)
              [] tag = QuoteReplaceLongFormMessageCode -> DecodeQuoteReplaceLongFormMessage(bytes)
              [] tag = QuoteDeleteMessageCode -> DecodeQuoteDeleteMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = NetOrderImbalanceMessageCode -> DecodeNetOrderImbalanceMessage(bytes)
              [] tag = EndOfReplaySequenceMessageCode -> DecodeEndOfReplaySequenceMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> DerivativeDirectoryMessageCode, body |-> one] : one \in CheckedDerivativeDirectoryMessage }
        \cup { [tag |-> TradingActionMessageCode, body |-> one] : one \in CheckedTradingActionMessage }
        \cup { [tag |-> AddOrderShortFormMessageCode, body |-> one] : one \in CheckedAddOrderShortFormMessage }
        \cup { [tag |-> AddOrderLongFormMessageCode, body |-> one] : one \in CheckedAddOrderLongFormMessage }
        \cup { [tag |-> AddQuoteShortFormMessageCode, body |-> one] : one \in CheckedAddQuoteShortFormMessage }
        \cup { [tag |-> AddQuoteLongFormMessageCode, body |-> one] : one \in CheckedAddQuoteLongFormMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> OrderReplaceShortFormMessageCode, body |-> one] : one \in CheckedOrderReplaceShortFormMessage }
        \cup { [tag |-> OrderReplaceLongFormMessageCode, body |-> one] : one \in CheckedOrderReplaceLongFormMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> OrderChangeMessageCode, body |-> one] : one \in CheckedOrderChangeMessage }
        \cup { [tag |-> QuoteReplaceShortFormMessageCode, body |-> one] : one \in CheckedQuoteReplaceShortFormMessage }
        \cup { [tag |-> QuoteReplaceLongFormMessageCode, body |-> one] : one \in CheckedQuoteReplaceLongFormMessage }
        \cup { [tag |-> QuoteDeleteMessageCode, body |-> one] : one \in CheckedQuoteDeleteMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> NetOrderImbalanceMessageCode, body |-> one] : one \in CheckedNetOrderImbalanceMessage }
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

(* Every Derivative Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDerivativeDirectoryMessage ==
    \A message \in CheckedDerivativeDirectoryMessage :
        LET read == DecodeDerivativeDirectoryMessage(EncodeDerivativeDirectoryMessage(message))
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

(* Every Add Order Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderShortFormMessage ==
    \A message \in CheckedAddOrderShortFormMessage :
        LET read == DecodeAddOrderShortFormMessage(EncodeAddOrderShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderLongFormMessage ==
    \A message \in CheckedAddOrderLongFormMessage :
        LET read == DecodeAddOrderLongFormMessage(EncodeAddOrderLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Quote Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddQuoteShortFormMessage ==
    \A message \in CheckedAddQuoteShortFormMessage :
        LET read == DecodeAddQuoteShortFormMessage(EncodeAddQuoteShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Quote Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddQuoteLongFormMessage ==
    \A message \in CheckedAddQuoteLongFormMessage :
        LET read == DecodeAddQuoteLongFormMessage(EncodeAddQuoteLongFormMessage(message))
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

(* Every Order Executed With Price Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderExecutedWithPriceMessage ==
    \A message \in CheckedOrderExecutedWithPriceMessage :
        LET read == DecodeOrderExecutedWithPriceMessage(EncodeOrderExecutedWithPriceMessage(message))
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

(* Every Order Replace Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplaceShortFormMessage ==
    \A message \in CheckedOrderReplaceShortFormMessage :
        LET read == DecodeOrderReplaceShortFormMessage(EncodeOrderReplaceShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replace Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplaceLongFormMessage ==
    \A message \in CheckedOrderReplaceLongFormMessage :
        LET read == DecodeOrderReplaceLongFormMessage(EncodeOrderReplaceLongFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeleteMessage ==
    \A message \in CheckedOrderDeleteMessage :
        LET read == DecodeOrderDeleteMessage(EncodeOrderDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Change Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderChangeMessage ==
    \A message \in CheckedOrderChangeMessage :
        LET read == DecodeOrderChangeMessage(EncodeOrderChangeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Replace Short Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteReplaceShortFormMessage ==
    \A message \in CheckedQuoteReplaceShortFormMessage :
        LET read == DecodeQuoteReplaceShortFormMessage(EncodeQuoteReplaceShortFormMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Replace Long Form Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteReplaceLongFormMessage ==
    \A message \in CheckedQuoteReplaceLongFormMessage :
        LET read == DecodeQuoteReplaceLongFormMessage(EncodeQuoteReplaceLongFormMessage(message))
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

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Net Order Imbalance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNetOrderImbalanceMessage ==
    \A message \in CheckedNetOrderImbalanceMessage :
        LET read == DecodeNetOrderImbalanceMessage(EncodeNetOrderImbalanceMessage(message))
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
