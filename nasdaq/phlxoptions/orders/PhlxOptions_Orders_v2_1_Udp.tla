-------------------- MODULE PhlxOptions_Orders_v2_1_Udp --------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) PHLX Orders v2.1                                               *)
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
(* Note: a Message Count of 0 marks End Of Session and carries no Message. *)
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
(* Derivative Directory Message: 62 bytes                                  *)
(***************************************************************************)

DerivativeDirectoryMessage ==
    [ trackingNumber      : Sample(2),
      timestamp           : Sample(8),
      instrumentId        : Sample(4),
      securitySymbol      : Sample(8),
      expirationYear      : Sample(1),
      expirationMonth     : Sample(1),
      expirationDay       : Sample(1),
      explicitStrikePrice : Sample(4),
      optionType          : Sample(1),
      underlyingSymbol    : Sample(13),
      closingType         : Sample(1),
      tradable            : Sample(1),
      mpv                 : Sample(1),
      reserved16          : Sample(16) ]

EncodeDerivativeDirectoryMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.securitySymbol
        \o message.expirationYear
        \o message.expirationMonth
        \o message.expirationDay
        \o message.explicitStrikePrice
        \o message.optionType
        \o message.underlyingSymbol
        \o message.closingType
        \o message.tradable
        \o message.mpv
        \o message.reserved16

DecodeDerivativeDirectoryMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(instrumentId.rest, 8) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(securitySymbol.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    LET expirationMonth == ReadBytes(expirationYear.rest, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDay == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDay.ok THEN Fail ELSE
    LET explicitStrikePrice == ReadBytes(expirationDay.rest, 4) IN IF ~explicitStrikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(explicitStrikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(optionType.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET closingType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~closingType.ok THEN Fail ELSE
    LET tradable == ReadBytes(closingType.rest, 1) IN IF ~tradable.ok THEN Fail ELSE
    LET mpv == ReadBytes(tradable.rest, 1) IN IF ~mpv.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(mpv.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ trackingNumber      |-> trackingNumber.value,
         timestamp           |-> timestamp.value,
         instrumentId        |-> instrumentId.value,
         securitySymbol      |-> securitySymbol.value,
         expirationYear      |-> expirationYear.value,
         expirationMonth     |-> expirationMonth.value,
         expirationDay       |-> expirationDay.value,
         explicitStrikePrice |-> explicitStrikePrice.value,
         optionType          |-> optionType.value,
         underlyingSymbol    |-> underlyingSymbol.value,
         closingType         |-> closingType.value,
         tradable            |-> tradable.value,
         mpv                 |-> mpv.value,
         reserved16          |-> reserved16.value ], reserved16.rest)

ZeroDerivativeDirectoryMessage ==
    [ trackingNumber      |-> [i \in 1 .. 2 |-> 0],
      timestamp           |-> [i \in 1 .. 8 |-> 0],
      instrumentId        |-> [i \in 1 .. 4 |-> 0],
      securitySymbol      |-> [i \in 1 .. 8 |-> 0],
      expirationYear      |-> [i \in 1 .. 1 |-> 0],
      expirationMonth     |-> [i \in 1 .. 1 |-> 0],
      expirationDay       |-> [i \in 1 .. 1 |-> 0],
      explicitStrikePrice |-> [i \in 1 .. 4 |-> 0],
      optionType          |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol    |-> [i \in 1 .. 13 |-> 0],
      closingType         |-> [i \in 1 .. 1 |-> 0],
      tradable            |-> [i \in 1 .. 1 |-> 0],
      mpv                 |-> [i \in 1 .. 1 |-> 0],
      reserved16          |-> [i \in 1 .. 16 |-> 0] ]

(* Derivative Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedDerivativeDirectoryMessage ==
    { ZeroDerivativeDirectoryMessage }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.securitySymbol = one] : one \in Sample(8) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.expirationYear = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.expirationDay = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.explicitStrikePrice = one] : one \in Sample(4) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.closingType = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.tradable = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.mpv = one] : one \in Sample(1) }
        \cup { [ZeroDerivativeDirectoryMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

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
(* Add Order Message: 60 bytes                                             *)
(***************************************************************************)

AddOrderMessage ==
    [ trackingNumber        : Sample(2),
      timestamp             : Sample(8),
      instrumentId          : Sample(4),
      orderReferenceNumber  : Sample(8),
      side                  : Sample(1),
      originalOrderVolume   : Sample(4),
      executableOrderVolume : Sample(4),
      orderStatus           : Sample(1),
      orderType             : Sample(1),
      orderQualifier        : Sample(1),
      limitPrice            : Sample(4),
      allOrNone             : Sample(1),
      timeInForce           : Sample(1),
      orderCapacity         : Sample(1),
      openCloseIndicator    : Sample(1),
      ownerId               : Sample(6),
      giveup                : Sample(6),
      cmta                  : Sample(6) ]

EncodeAddOrderMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.orderReferenceNumber
        \o message.side
        \o message.originalOrderVolume
        \o message.executableOrderVolume
        \o message.orderStatus
        \o message.orderType
        \o message.orderQualifier
        \o message.limitPrice
        \o message.allOrNone
        \o message.timeInForce
        \o message.orderCapacity
        \o message.openCloseIndicator
        \o message.ownerId
        \o message.giveup
        \o message.cmta

DecodeAddOrderMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(instrumentId.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET side == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET originalOrderVolume == ReadBytes(side.rest, 4) IN IF ~originalOrderVolume.ok THEN Fail ELSE
    LET executableOrderVolume == ReadBytes(originalOrderVolume.rest, 4) IN IF ~executableOrderVolume.ok THEN Fail ELSE
    LET orderStatus == ReadBytes(executableOrderVolume.rest, 1) IN IF ~orderStatus.ok THEN Fail ELSE
    LET orderType == ReadBytes(orderStatus.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET orderQualifier == ReadBytes(orderType.rest, 1) IN IF ~orderQualifier.ok THEN Fail ELSE
    LET limitPrice == ReadBytes(orderQualifier.rest, 4) IN IF ~limitPrice.ok THEN Fail ELSE
    LET allOrNone == ReadBytes(limitPrice.rest, 1) IN IF ~allOrNone.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(allOrNone.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(timeInForce.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET openCloseIndicator == ReadBytes(orderCapacity.rest, 1) IN IF ~openCloseIndicator.ok THEN Fail ELSE
    LET ownerId == ReadBytes(openCloseIndicator.rest, 6) IN IF ~ownerId.ok THEN Fail ELSE
    LET giveup == ReadBytes(ownerId.rest, 6) IN IF ~giveup.ok THEN Fail ELSE
    LET cmta == ReadBytes(giveup.rest, 6) IN IF ~cmta.ok THEN Fail ELSE
    Ok([ trackingNumber        |-> trackingNumber.value,
         timestamp             |-> timestamp.value,
         instrumentId          |-> instrumentId.value,
         orderReferenceNumber  |-> orderReferenceNumber.value,
         side                  |-> side.value,
         originalOrderVolume   |-> originalOrderVolume.value,
         executableOrderVolume |-> executableOrderVolume.value,
         orderStatus           |-> orderStatus.value,
         orderType             |-> orderType.value,
         orderQualifier        |-> orderQualifier.value,
         limitPrice            |-> limitPrice.value,
         allOrNone             |-> allOrNone.value,
         timeInForce           |-> timeInForce.value,
         orderCapacity         |-> orderCapacity.value,
         openCloseIndicator    |-> openCloseIndicator.value,
         ownerId               |-> ownerId.value,
         giveup                |-> giveup.value,
         cmta                  |-> cmta.value ], cmta.rest)

ZeroAddOrderMessage ==
    [ trackingNumber        |-> [i \in 1 .. 2 |-> 0],
      timestamp             |-> [i \in 1 .. 8 |-> 0],
      instrumentId          |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber  |-> [i \in 1 .. 8 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      originalOrderVolume   |-> [i \in 1 .. 4 |-> 0],
      executableOrderVolume |-> [i \in 1 .. 4 |-> 0],
      orderStatus           |-> [i \in 1 .. 1 |-> 0],
      orderType             |-> [i \in 1 .. 1 |-> 0],
      orderQualifier        |-> [i \in 1 .. 1 |-> 0],
      limitPrice            |-> [i \in 1 .. 4 |-> 0],
      allOrNone             |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      orderCapacity         |-> [i \in 1 .. 1 |-> 0],
      openCloseIndicator    |-> [i \in 1 .. 1 |-> 0],
      ownerId               |-> [i \in 1 .. 6 |-> 0],
      giveup                |-> [i \in 1 .. 6 |-> 0],
      cmta                  |-> [i \in 1 .. 6 |-> 0] ]

(* Add Order Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderMessage ==
    { ZeroAddOrderMessage }
        \cup { [ZeroAddOrderMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.originalOrderVolume = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.executableOrderVolume = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderStatus = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderQualifier = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.limitPrice = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderMessage EXCEPT !.allOrNone = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.openCloseIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderMessage EXCEPT !.ownerId = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.giveup = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderMessage EXCEPT !.cmta = one] : one \in Sample(6) }

(***************************************************************************)
(* Auction Message: 73 bytes                                               *)
(***************************************************************************)

AuctionMessage ==
    [ trackingNumber  : Sample(2),
      timestamp       : Sample(8),
      instrumentId    : Sample(4),
      auctionId       : Sample(4),
      auctionType     : Sample(1),
      auctionDuration : Sample(4),
      auctionEvent    : Sample(1),
      quantity        : Sample(4),
      side            : Sample(1),
      price           : Sample(4),
      imbalanceVolume : Sample(4),
      execFlag        : Sample(1),
      orderCapacity   : Sample(1),
      ownerId         : Sample(6),
      giveup          : Sample(6),
      cmta            : Sample(6),
      reserved16      : Sample(16) ]

EncodeAuctionMessage(message) ==
    message.trackingNumber
        \o message.timestamp
        \o message.instrumentId
        \o message.auctionId
        \o message.auctionType
        \o message.auctionDuration
        \o message.auctionEvent
        \o message.quantity
        \o message.side
        \o message.price
        \o message.imbalanceVolume
        \o message.execFlag
        \o message.orderCapacity
        \o message.ownerId
        \o message.giveup
        \o message.cmta
        \o message.reserved16

DecodeAuctionMessage(bytes) ==
    LET trackingNumber == ReadBytes(bytes, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(timestamp.rest, 4) IN IF ~instrumentId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(instrumentId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET auctionDuration == ReadBytes(auctionType.rest, 4) IN IF ~auctionDuration.ok THEN Fail ELSE
    LET auctionEvent == ReadBytes(auctionDuration.rest, 1) IN IF ~auctionEvent.ok THEN Fail ELSE
    LET quantity == ReadBytes(auctionEvent.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET side == ReadBytes(quantity.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET imbalanceVolume == ReadBytes(price.rest, 4) IN IF ~imbalanceVolume.ok THEN Fail ELSE
    LET execFlag == ReadBytes(imbalanceVolume.rest, 1) IN IF ~execFlag.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(execFlag.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET ownerId == ReadBytes(orderCapacity.rest, 6) IN IF ~ownerId.ok THEN Fail ELSE
    LET giveup == ReadBytes(ownerId.rest, 6) IN IF ~giveup.ok THEN Fail ELSE
    LET cmta == ReadBytes(giveup.rest, 6) IN IF ~cmta.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(cmta.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ trackingNumber  |-> trackingNumber.value,
         timestamp       |-> timestamp.value,
         instrumentId    |-> instrumentId.value,
         auctionId       |-> auctionId.value,
         auctionType     |-> auctionType.value,
         auctionDuration |-> auctionDuration.value,
         auctionEvent    |-> auctionEvent.value,
         quantity        |-> quantity.value,
         side            |-> side.value,
         price           |-> price.value,
         imbalanceVolume |-> imbalanceVolume.value,
         execFlag        |-> execFlag.value,
         orderCapacity   |-> orderCapacity.value,
         ownerId         |-> ownerId.value,
         giveup          |-> giveup.value,
         cmta            |-> cmta.value,
         reserved16      |-> reserved16.value ], reserved16.rest)

ZeroAuctionMessage ==
    [ trackingNumber  |-> [i \in 1 .. 2 |-> 0],
      timestamp       |-> [i \in 1 .. 8 |-> 0],
      instrumentId    |-> [i \in 1 .. 4 |-> 0],
      auctionId       |-> [i \in 1 .. 4 |-> 0],
      auctionType     |-> [i \in 1 .. 1 |-> 0],
      auctionDuration |-> [i \in 1 .. 4 |-> 0],
      auctionEvent    |-> [i \in 1 .. 1 |-> 0],
      quantity        |-> [i \in 1 .. 4 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      imbalanceVolume |-> [i \in 1 .. 4 |-> 0],
      execFlag        |-> [i \in 1 .. 1 |-> 0],
      orderCapacity   |-> [i \in 1 .. 1 |-> 0],
      ownerId         |-> [i \in 1 .. 6 |-> 0],
      giveup          |-> [i \in 1 .. 6 |-> 0],
      cmta            |-> [i \in 1 .. 6 |-> 0],
      reserved16      |-> [i \in 1 .. 16 |-> 0] ]

(* Auction Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionMessage ==
    { ZeroAuctionMessage }
        \cup { [ZeroAuctionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAuctionMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAuctionMessage EXCEPT !.instrumentId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionMessage EXCEPT !.auctionDuration = one] : one \in Sample(4) }
        \cup { [ZeroAuctionMessage EXCEPT !.auctionEvent = one] : one \in Sample(1) }
        \cup { [ZeroAuctionMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroAuctionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAuctionMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAuctionMessage EXCEPT !.imbalanceVolume = one] : one \in Sample(4) }
        \cup { [ZeroAuctionMessage EXCEPT !.execFlag = one] : one \in Sample(1) }
        \cup { [ZeroAuctionMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroAuctionMessage EXCEPT !.ownerId = one] : one \in Sample(6) }
        \cup { [ZeroAuctionMessage EXCEPT !.giveup = one] : one \in Sample(6) }
        \cup { [ZeroAuctionMessage EXCEPT !.cmta = one] : one \in Sample(6) }
        \cup { [ZeroAuctionMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Udp Payload, selected by Message Type                                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
DerivativeDirectoryMessageCode == 109  \* "m"
TradingActionMessageCode == 72  \* "H"
AddOrderMessageCode == 79  \* "O"
AuctionMessageCode == 74  \* "J"

UdpPayload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {DerivativeDirectoryMessageCode}, body : DerivativeDirectoryMessage ]
        \cup [ tag : {TradingActionMessageCode}, body : TradingActionMessage ]
        \cup [ tag : {AddOrderMessageCode}, body : AddOrderMessage ]
        \cup [ tag : {AuctionMessageCode}, body : AuctionMessage ]

EncodeUdpPayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = DerivativeDirectoryMessageCode -> EncodeDerivativeDirectoryMessage(message.body)
      [] message.tag = TradingActionMessageCode -> EncodeTradingActionMessage(message.body)
      [] message.tag = AddOrderMessageCode -> EncodeAddOrderMessage(message.body)
      [] message.tag = AuctionMessageCode -> EncodeAuctionMessage(message.body)

DecodeUdpPayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = DerivativeDirectoryMessageCode -> DecodeDerivativeDirectoryMessage(bytes)
              [] tag = TradingActionMessageCode -> DecodeTradingActionMessage(bytes)
              [] tag = AddOrderMessageCode -> DecodeAddOrderMessage(bytes)
              [] tag = AuctionMessageCode -> DecodeAuctionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUdpPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Udp Payload in turn, at the values the message it names is checked at *)
CheckedUdpPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> DerivativeDirectoryMessageCode, body |-> one] : one \in CheckedDerivativeDirectoryMessage }
        \cup { [tag |-> TradingActionMessageCode, body |-> one] : one \in CheckedTradingActionMessage }
        \cup { [tag |-> AddOrderMessageCode, body |-> one] : one \in CheckedAddOrderMessage }
        \cup { [tag |-> AuctionMessageCode, body |-> one] : one \in CheckedAuctionMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ udpPayload : UdpPayload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.udpPayload.tag, 1)
        \o EncodeUdpPayload(message.udpPayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET udpPayload == DecodeUdpPayload(messageType.value, messageType.rest) IN IF ~udpPayload.ok THEN Fail ELSE
    Ok([ udpPayload |-> udpPayload.value ], udpPayload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeMessageBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroMessage ==
    [ udpPayload |-> ZeroUdpPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.udpPayload = one] : one \in CheckedUdpPayload }

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
    { [ZeroMessage EXCEPT !.udpPayload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> DerivativeDirectoryMessageCode, body |-> ZeroDerivativeDirectoryMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> TradingActionMessageCode, body |-> ZeroTradingActionMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> AddOrderMessageCode, body |-> ZeroAddOrderMessage]],
      [ZeroMessage EXCEPT !.udpPayload = [tag |-> AuctionMessageCode, body |-> ZeroAuctionMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ udpSession        : Sample(10),
      udpSequenceNumber : Sample(8),
      message           : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.udpSession
        \o message.udpSequenceNumber
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET udpSession == ReadBytes(bytes, 10) IN IF ~udpSession.ok THEN Fail ELSE
    LET udpSequenceNumber == ReadBytes(udpSession.rest, 8) IN IF ~udpSequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(udpSequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ udpSession        |-> udpSession.value,
         udpSequenceNumber |-> udpSequenceNumber.value,
         message           |-> message.value ], message.rest)

ZeroPacket ==
    [ udpSession        |-> [i \in 1 .. 10 |-> 0],
      udpSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message           |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.udpSession = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.udpSequenceNumber = one] : one \in Sample(8) }
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

(* Every Add Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderMessage ==
    \A message \in CheckedAddOrderMessage :
        LET read == DecodeAddOrderMessage(EncodeAddOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionMessage ==
    \A message \in CheckedAuctionMessage :
        LET read == DecodeAuctionMessage(EncodeAuctionMessage(message))
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

(* A Udp Payload is selected by the Message Type it is written under *)
SelectsUdpPayload ==
    \A message \in CheckedUdpPayload :
        LET read == DecodeUdpPayload(message.tag, EncodeUdpPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
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
