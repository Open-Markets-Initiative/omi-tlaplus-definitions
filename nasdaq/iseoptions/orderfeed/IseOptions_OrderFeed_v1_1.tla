--------------------- MODULE IseOptions_OrderFeed_v1_1 ---------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Ise Order Feed Market Data v1.1                                *)
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
(* System Event Message: 13 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp    : Sample(6),
      eventCode    : Sample(1),
      currentYear  : Sample(2),
      currentMonth : Sample(1),
      currentDay   : Sample(1),
      version      : Sample(1),
      subversion   : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.eventCode
        \o message.currentYear
        \o message.currentMonth
        \o message.currentDay
        \o message.version
        \o message.subversion

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    LET currentYear == ReadBytes(eventCode.rest, 2) IN IF ~currentYear.ok THEN Fail ELSE
    LET currentMonth == ReadBytes(currentYear.rest, 1) IN IF ~currentMonth.ok THEN Fail ELSE
    LET currentDay == ReadBytes(currentMonth.rest, 1) IN IF ~currentDay.ok THEN Fail ELSE
    LET version == ReadBytes(currentDay.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET subversion == ReadBytes(version.rest, 1) IN IF ~subversion.ok THEN Fail ELSE
    Ok([ timestamp    |-> timestamp.value,
         eventCode    |-> eventCode.value,
         currentYear  |-> currentYear.value,
         currentMonth |-> currentMonth.value,
         currentDay   |-> currentDay.value,
         version      |-> version.value,
         subversion   |-> subversion.value ], subversion.rest)

ZeroSystemEventMessage ==
    [ timestamp    |-> [i \in 1 .. 6 |-> 0],
      eventCode    |-> [i \in 1 .. 1 |-> 0],
      currentYear  |-> [i \in 1 .. 2 |-> 0],
      currentMonth |-> [i \in 1 .. 1 |-> 0],
      currentDay   |-> [i \in 1 .. 1 |-> 0],
      version      |-> [i \in 1 .. 1 |-> 0],
      subversion   |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.currentYear = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.currentMonth = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.currentDay = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.subversion = one] : one \in Sample(1) }

(***************************************************************************)
(* Option Directory Message: 49 bytes                                      *)
(***************************************************************************)

OptionDirectoryMessage ==
    [ timestamp         : Sample(6),
      optionId          : Sample(4),
      securitySymbol    : Sample(6),
      expirationYear    : Sample(1),
      expirationMonth   : Sample(1),
      expirationDay     : Sample(1),
      strikePrice       : Sample(8),
      optionType        : Sample(1),
      source            : Sample(1),
      underlyingSymbol  : Sample(13),
      tradingType       : Sample(1),
      contractSize      : Sample(2),
      optionClosingType : Sample(1),
      tradable          : Sample(1),
      mpv               : Sample(1),
      closingOnly       : Sample(1) ]

EncodeOptionDirectoryMessage(message) ==
    message.timestamp
        \o message.optionId
        \o message.securitySymbol
        \o message.expirationYear
        \o message.expirationMonth
        \o message.expirationDay
        \o message.strikePrice
        \o message.optionType
        \o message.source
        \o message.underlyingSymbol
        \o message.tradingType
        \o message.contractSize
        \o message.optionClosingType
        \o message.tradable
        \o message.mpv
        \o message.closingOnly

DecodeOptionDirectoryMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 6) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expirationYear == ReadBytes(securitySymbol.rest, 1) IN IF ~expirationYear.ok THEN Fail ELSE
    LET expirationMonth == ReadBytes(expirationYear.rest, 1) IN IF ~expirationMonth.ok THEN Fail ELSE
    LET expirationDay == ReadBytes(expirationMonth.rest, 1) IN IF ~expirationDay.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expirationDay.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET source == ReadBytes(optionType.rest, 1) IN IF ~source.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(source.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET tradingType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~tradingType.ok THEN Fail ELSE
    LET contractSize == ReadBytes(tradingType.rest, 2) IN IF ~contractSize.ok THEN Fail ELSE
    LET optionClosingType == ReadBytes(contractSize.rest, 1) IN IF ~optionClosingType.ok THEN Fail ELSE
    LET tradable == ReadBytes(optionClosingType.rest, 1) IN IF ~tradable.ok THEN Fail ELSE
    LET mpv == ReadBytes(tradable.rest, 1) IN IF ~mpv.ok THEN Fail ELSE
    LET closingOnly == ReadBytes(mpv.rest, 1) IN IF ~closingOnly.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         optionId          |-> optionId.value,
         securitySymbol    |-> securitySymbol.value,
         expirationYear    |-> expirationYear.value,
         expirationMonth   |-> expirationMonth.value,
         expirationDay     |-> expirationDay.value,
         strikePrice       |-> strikePrice.value,
         optionType        |-> optionType.value,
         source            |-> source.value,
         underlyingSymbol  |-> underlyingSymbol.value,
         tradingType       |-> tradingType.value,
         contractSize      |-> contractSize.value,
         optionClosingType |-> optionClosingType.value,
         tradable          |-> tradable.value,
         mpv               |-> mpv.value,
         closingOnly       |-> closingOnly.value ], closingOnly.rest)

ZeroOptionDirectoryMessage ==
    [ timestamp         |-> [i \in 1 .. 6 |-> 0],
      optionId          |-> [i \in 1 .. 4 |-> 0],
      securitySymbol    |-> [i \in 1 .. 6 |-> 0],
      expirationYear    |-> [i \in 1 .. 1 |-> 0],
      expirationMonth   |-> [i \in 1 .. 1 |-> 0],
      expirationDay     |-> [i \in 1 .. 1 |-> 0],
      strikePrice       |-> [i \in 1 .. 8 |-> 0],
      optionType        |-> [i \in 1 .. 1 |-> 0],
      source            |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol  |-> [i \in 1 .. 13 |-> 0],
      tradingType       |-> [i \in 1 .. 1 |-> 0],
      contractSize      |-> [i \in 1 .. 2 |-> 0],
      optionClosingType |-> [i \in 1 .. 1 |-> 0],
      tradable          |-> [i \in 1 .. 1 |-> 0],
      mpv               |-> [i \in 1 .. 1 |-> 0],
      closingOnly       |-> [i \in 1 .. 1 |-> 0] ]

(* Option Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionDirectoryMessage ==
    { ZeroOptionDirectoryMessage }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.securitySymbol = one] : one \in Sample(6) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.expirationYear = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.expirationMonth = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.expirationDay = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.source = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.tradingType = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.contractSize = one] : one \in Sample(2) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.optionClosingType = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.tradable = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.mpv = one] : one \in Sample(1) }
        \cup { [ZeroOptionDirectoryMessage EXCEPT !.closingOnly = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Action Message: 11 bytes                                        *)
(***************************************************************************)

TradingActionMessage ==
    [ timestamp           : Sample(6),
      optionId            : Sample(4),
      currentTradingState : Sample(1) ]

EncodeTradingActionMessage(message) ==
    message.timestamp
        \o message.optionId
        \o message.currentTradingState

DecodeTradingActionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(optionId.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         optionId            |-> optionId.value,
         currentTradingState |-> currentTradingState.value ], currentTradingState.rest)

ZeroTradingActionMessage ==
    [ timestamp           |-> [i \in 1 .. 6 |-> 0],
      optionId            |-> [i \in 1 .. 4 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingActionMessage ==
    { ZeroTradingActionMessage }
        \cup { [ZeroTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroTradingActionMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Open Closed Message: 11 bytes                                  *)
(***************************************************************************)

SecurityOpenClosedMessage ==
    [ timestamp : Sample(6),
      optionId  : Sample(4),
      openState : Sample(1) ]

EncodeSecurityOpenClosedMessage(message) ==
    message.timestamp
        \o message.optionId
        \o message.openState

DecodeSecurityOpenClosedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET openState == ReadBytes(optionId.rest, 1) IN IF ~openState.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         optionId  |-> optionId.value,
         openState |-> openState.value ], openState.rest)

ZeroSecurityOpenClosedMessage ==
    [ timestamp |-> [i \in 1 .. 6 |-> 0],
      optionId  |-> [i \in 1 .. 4 |-> 0],
      openState |-> [i \in 1 .. 1 |-> 0] ]

(* Security Open Closed Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityOpenClosedMessage ==
    { ZeroSecurityOpenClosedMessage }
        \cup { [ZeroSecurityOpenClosedMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroSecurityOpenClosedMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityOpenClosedMessage EXCEPT !.openState = one] : one \in Sample(1) }

(***************************************************************************)
(* Opening Imbalance Message: 23 bytes                                     *)
(***************************************************************************)

OpeningImbalanceMessage ==
    [ timestamp          : Sample(6),
      optionId           : Sample(4),
      pairedContracts    : Sample(4),
      imbalanceDirection : Sample(1),
      imbalancePrice     : Sample(4),
      imbalanceVolume    : Sample(4) ]

EncodeOpeningImbalanceMessage(message) ==
    message.timestamp
        \o message.optionId
        \o message.pairedContracts
        \o message.imbalanceDirection
        \o message.imbalancePrice
        \o message.imbalanceVolume

DecodeOpeningImbalanceMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET pairedContracts == ReadBytes(optionId.rest, 4) IN IF ~pairedContracts.ok THEN Fail ELSE
    LET imbalanceDirection == ReadBytes(pairedContracts.rest, 1) IN IF ~imbalanceDirection.ok THEN Fail ELSE
    LET imbalancePrice == ReadBytes(imbalanceDirection.rest, 4) IN IF ~imbalancePrice.ok THEN Fail ELSE
    LET imbalanceVolume == ReadBytes(imbalancePrice.rest, 4) IN IF ~imbalanceVolume.ok THEN Fail ELSE
    Ok([ timestamp          |-> timestamp.value,
         optionId           |-> optionId.value,
         pairedContracts    |-> pairedContracts.value,
         imbalanceDirection |-> imbalanceDirection.value,
         imbalancePrice     |-> imbalancePrice.value,
         imbalanceVolume    |-> imbalanceVolume.value ], imbalanceVolume.rest)

ZeroOpeningImbalanceMessage ==
    [ timestamp          |-> [i \in 1 .. 6 |-> 0],
      optionId           |-> [i \in 1 .. 4 |-> 0],
      pairedContracts    |-> [i \in 1 .. 4 |-> 0],
      imbalanceDirection |-> [i \in 1 .. 1 |-> 0],
      imbalancePrice     |-> [i \in 1 .. 4 |-> 0],
      imbalanceVolume    |-> [i \in 1 .. 4 |-> 0] ]

(* Opening Imbalance Message at zero, then each field in turn at the values it is checked at *)
CheckedOpeningImbalanceMessage ==
    { ZeroOpeningImbalanceMessage }
        \cup { [ZeroOpeningImbalanceMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOpeningImbalanceMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroOpeningImbalanceMessage EXCEPT !.pairedContracts = one] : one \in Sample(4) }
        \cup { [ZeroOpeningImbalanceMessage EXCEPT !.imbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroOpeningImbalanceMessage EXCEPT !.imbalancePrice = one] : one \in Sample(4) }
        \cup { [ZeroOpeningImbalanceMessage EXCEPT !.imbalanceVolume = one] : one \in Sample(4) }

(***************************************************************************)
(* Order On Book Message: 40 bytes                                         *)
(***************************************************************************)

OrderOnBookMessage ==
    [ timestamp     : Sample(6),
      optionId      : Sample(4),
      orderType     : Sample(1),
      side          : Sample(1),
      price         : Sample(4),
      size          : Sample(4),
      execFlag      : Sample(1),
      orderCapacity : Sample(1),
      ownerId       : Sample(6),
      giveup        : Sample(6),
      cmta          : Sample(6) ]

EncodeOrderOnBookMessage(message) ==
    message.timestamp
        \o message.optionId
        \o message.orderType
        \o message.side
        \o message.price
        \o message.size
        \o message.execFlag
        \o message.orderCapacity
        \o message.ownerId
        \o message.giveup
        \o message.cmta

DecodeOrderOnBookMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET orderType == ReadBytes(optionId.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET side == ReadBytes(orderType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET execFlag == ReadBytes(size.rest, 1) IN IF ~execFlag.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(execFlag.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET ownerId == ReadBytes(orderCapacity.rest, 6) IN IF ~ownerId.ok THEN Fail ELSE
    LET giveup == ReadBytes(ownerId.rest, 6) IN IF ~giveup.ok THEN Fail ELSE
    LET cmta == ReadBytes(giveup.rest, 6) IN IF ~cmta.ok THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         optionId      |-> optionId.value,
         orderType     |-> orderType.value,
         side          |-> side.value,
         price         |-> price.value,
         size          |-> size.value,
         execFlag      |-> execFlag.value,
         orderCapacity |-> orderCapacity.value,
         ownerId       |-> ownerId.value,
         giveup        |-> giveup.value,
         cmta          |-> cmta.value ], cmta.rest)

ZeroOrderOnBookMessage ==
    [ timestamp     |-> [i \in 1 .. 6 |-> 0],
      optionId      |-> [i \in 1 .. 4 |-> 0],
      orderType     |-> [i \in 1 .. 1 |-> 0],
      side          |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 4 |-> 0],
      size          |-> [i \in 1 .. 4 |-> 0],
      execFlag      |-> [i \in 1 .. 1 |-> 0],
      orderCapacity |-> [i \in 1 .. 1 |-> 0],
      ownerId       |-> [i \in 1 .. 6 |-> 0],
      giveup        |-> [i \in 1 .. 6 |-> 0],
      cmta          |-> [i \in 1 .. 6 |-> 0] ]

(* Order On Book Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderOnBookMessage ==
    { ZeroOrderOnBookMessage }
        \cup { [ZeroOrderOnBookMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOrderOnBookMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderOnBookMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderOnBookMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderOnBookMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderOnBookMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroOrderOnBookMessage EXCEPT !.execFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderOnBookMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderOnBookMessage EXCEPT !.ownerId = one] : one \in Sample(6) }
        \cup { [ZeroOrderOnBookMessage EXCEPT !.giveup = one] : one \in Sample(6) }
        \cup { [ZeroOrderOnBookMessage EXCEPT !.cmta = one] : one \in Sample(6) }

(***************************************************************************)
(* Auction Response: 8 bytes                                               *)
(***************************************************************************)

AuctionResponse ==
    [ responsePrice : Sample(4),
      responseSize  : Sample(4) ]

EncodeAuctionResponse(message) ==
    message.responsePrice
        \o message.responseSize

DecodeAuctionResponse(bytes) ==
    LET responsePrice == ReadBytes(bytes, 4) IN IF ~responsePrice.ok THEN Fail ELSE
    LET responseSize == ReadBytes(responsePrice.rest, 4) IN IF ~responseSize.ok THEN Fail ELSE
    Ok([ responsePrice |-> responsePrice.value,
         responseSize  |-> responseSize.value ], responseSize.rest)

ZeroAuctionResponse ==
    [ responsePrice |-> [i \in 1 .. 4 |-> 0],
      responseSize  |-> [i \in 1 .. 4 |-> 0] ]

(* Auction Response at zero, then each field in turn at the values it is checked at *)
CheckedAuctionResponse ==
    { ZeroAuctionResponse }
        \cup { [ZeroAuctionResponse EXCEPT !.responsePrice = one] : one \in Sample(4) }
        \cup { [ZeroAuctionResponse EXCEPT !.responseSize = one] : one \in Sample(4) }

(* A run of Auction Response, written one after another *)
RECURSIVE EncodeAuctionResponseList(_)
EncodeAuctionResponseList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAuctionResponse(Head(messages)) \o EncodeAuctionResponseList(Tail(messages))

(* As many Auction Response as the field that counts them says *)
RECURSIVE ReadAuctionResponseList(_, _)
ReadAuctionResponseList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAuctionResponse(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAuctionResponseList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Auction Response of each kind, for the lists that carry them *)
OneAuctionResponse == { ZeroAuctionResponse }

(***************************************************************************)
(* Auction Message                                                         *)
(***************************************************************************)

AuctionMessage ==
    [ timestamp       : Sample(6),
      optionId        : Sample(4),
      auctionId       : Sample(4),
      orderType       : Sample(1),
      side            : Sample(1),
      price           : Sample(4),
      size            : Sample(4),
      execFlag        : Sample(1),
      orderCapacity   : Sample(1),
      ownerId         : Sample(6),
      giveup          : Sample(6),
      cmta            : Sample(6),
      auctionEvent    : Sample(1),
      auctionResponse : SampleLists(OneAuctionResponse) ]

EncodeAuctionMessage(message) ==
    message.timestamp
        \o message.optionId
        \o message.auctionId
        \o message.orderType
        \o message.side
        \o message.price
        \o message.size
        \o message.execFlag
        \o message.orderCapacity
        \o message.ownerId
        \o message.giveup
        \o message.cmta
        \o message.auctionEvent
        \o EncodeUIntBE(Len(message.auctionResponse), 1)
        \o EncodeAuctionResponseList(message.auctionResponse)

DecodeAuctionMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET optionId == ReadBytes(timestamp.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(optionId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET orderType == ReadBytes(auctionId.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET side == ReadBytes(orderType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET size == ReadBytes(price.rest, 4) IN IF ~size.ok THEN Fail ELSE
    LET execFlag == ReadBytes(size.rest, 1) IN IF ~execFlag.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(execFlag.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET ownerId == ReadBytes(orderCapacity.rest, 6) IN IF ~ownerId.ok THEN Fail ELSE
    LET giveup == ReadBytes(ownerId.rest, 6) IN IF ~giveup.ok THEN Fail ELSE
    LET cmta == ReadBytes(giveup.rest, 6) IN IF ~cmta.ok THEN Fail ELSE
    LET auctionEvent == ReadBytes(cmta.rest, 1) IN IF ~auctionEvent.ok THEN Fail ELSE
    LET numberOfResponses == ReadUIntBE(auctionEvent.rest, 1) IN IF ~numberOfResponses.ok THEN Fail ELSE
    LET auctionResponse == ReadAuctionResponseList(numberOfResponses.rest, numberOfResponses.value) IN IF ~auctionResponse.ok THEN Fail ELSE
    Ok([ timestamp       |-> timestamp.value,
         optionId        |-> optionId.value,
         auctionId       |-> auctionId.value,
         orderType       |-> orderType.value,
         side            |-> side.value,
         price           |-> price.value,
         size            |-> size.value,
         execFlag        |-> execFlag.value,
         orderCapacity   |-> orderCapacity.value,
         ownerId         |-> ownerId.value,
         giveup          |-> giveup.value,
         cmta            |-> cmta.value,
         auctionEvent    |-> auctionEvent.value,
         auctionResponse |-> auctionResponse.value ], auctionResponse.rest)

ZeroAuctionMessage ==
    [ timestamp       |-> [i \in 1 .. 6 |-> 0],
      optionId        |-> [i \in 1 .. 4 |-> 0],
      auctionId       |-> [i \in 1 .. 4 |-> 0],
      orderType       |-> [i \in 1 .. 1 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      size            |-> [i \in 1 .. 4 |-> 0],
      execFlag        |-> [i \in 1 .. 1 |-> 0],
      orderCapacity   |-> [i \in 1 .. 1 |-> 0],
      ownerId         |-> [i \in 1 .. 6 |-> 0],
      giveup          |-> [i \in 1 .. 6 |-> 0],
      cmta            |-> [i \in 1 .. 6 |-> 0],
      auctionEvent    |-> [i \in 1 .. 1 |-> 0],
      auctionResponse |-> << >> ]

(* Auction Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionMessage ==
    { ZeroAuctionMessage }
        \cup { [ZeroAuctionMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroAuctionMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroAuctionMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroAuctionMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroAuctionMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAuctionMessage EXCEPT !.size = one] : one \in Sample(4) }
        \cup { [ZeroAuctionMessage EXCEPT !.execFlag = one] : one \in Sample(1) }
        \cup { [ZeroAuctionMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroAuctionMessage EXCEPT !.ownerId = one] : one \in Sample(6) }
        \cup { [ZeroAuctionMessage EXCEPT !.giveup = one] : one \in Sample(6) }
        \cup { [ZeroAuctionMessage EXCEPT !.cmta = one] : one \in Sample(6) }
        \cup { [ZeroAuctionMessage EXCEPT !.auctionEvent = one] : one \in Sample(1) }
        \cup { [ZeroAuctionMessage EXCEPT !.auctionResponse = one] : one \in SampleLists(OneAuctionResponse) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
OptionDirectoryMessageCode == 68  \* "D"
TradingActionMessageCode == 72  \* "H"
SecurityOpenClosedMessageCode == 79  \* "O"
OpeningImbalanceMessageCode == 78  \* "N"
OrderOnBookMessageCode == 66  \* "B"
AuctionMessageCode == 65  \* "A"

Payload ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OptionDirectoryMessageCode}, body : OptionDirectoryMessage ]
        \cup [ tag : {TradingActionMessageCode}, body : TradingActionMessage ]
        \cup [ tag : {SecurityOpenClosedMessageCode}, body : SecurityOpenClosedMessage ]
        \cup [ tag : {OpeningImbalanceMessageCode}, body : OpeningImbalanceMessage ]
        \cup [ tag : {OrderOnBookMessageCode}, body : OrderOnBookMessage ]
        \cup [ tag : {AuctionMessageCode}, body : AuctionMessage ]

EncodePayload(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OptionDirectoryMessageCode -> EncodeOptionDirectoryMessage(message.body)
      [] message.tag = TradingActionMessageCode -> EncodeTradingActionMessage(message.body)
      [] message.tag = SecurityOpenClosedMessageCode -> EncodeSecurityOpenClosedMessage(message.body)
      [] message.tag = OpeningImbalanceMessageCode -> EncodeOpeningImbalanceMessage(message.body)
      [] message.tag = OrderOnBookMessageCode -> EncodeOrderOnBookMessage(message.body)
      [] message.tag = AuctionMessageCode -> EncodeAuctionMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OptionDirectoryMessageCode -> DecodeOptionDirectoryMessage(bytes)
              [] tag = TradingActionMessageCode -> DecodeTradingActionMessage(bytes)
              [] tag = SecurityOpenClosedMessageCode -> DecodeSecurityOpenClosedMessage(bytes)
              [] tag = OpeningImbalanceMessageCode -> DecodeOpeningImbalanceMessage(bytes)
              [] tag = OrderOnBookMessageCode -> DecodeOrderOnBookMessage(bytes)
              [] tag = AuctionMessageCode -> DecodeAuctionMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OptionDirectoryMessageCode, body |-> one] : one \in CheckedOptionDirectoryMessage }
        \cup { [tag |-> TradingActionMessageCode, body |-> one] : one \in CheckedTradingActionMessage }
        \cup { [tag |-> SecurityOpenClosedMessageCode, body |-> one] : one \in CheckedSecurityOpenClosedMessage }
        \cup { [tag |-> OpeningImbalanceMessageCode, body |-> one] : one \in CheckedOpeningImbalanceMessage }
        \cup { [tag |-> OrderOnBookMessageCode, body |-> one] : one \in CheckedOrderOnBookMessage }
        \cup { [tag |-> AuctionMessageCode, body |-> one] : one \in CheckedAuctionMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OptionDirectoryMessageCode, body |-> ZeroOptionDirectoryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingActionMessageCode, body |-> ZeroTradingActionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityOpenClosedMessageCode, body |-> ZeroSecurityOpenClosedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpeningImbalanceMessageCode, body |-> ZeroOpeningImbalanceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderOnBookMessageCode, body |-> ZeroOrderOnBookMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AuctionMessageCode, body |-> ZeroAuctionMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ session        : Sample(10),
      sequenceNumber : Sample(8),
      message        : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.session
        \o message.sequenceNumber
        \o EncodeUIntBE(Len(message.message), 2)
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET messageCount == ReadUIntBE(sequenceNumber.rest, 2) IN IF ~messageCount.ok THEN Fail ELSE
    LET message == ReadMessageList(messageCount.rest, messageCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value,
         message        |-> message.value ], message.rest)

ZeroPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 8 |-> 0],
      message        |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
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

(* Every Option Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOptionDirectoryMessage ==
    \A message \in CheckedOptionDirectoryMessage :
        LET read == DecodeOptionDirectoryMessage(EncodeOptionDirectoryMessage(message))
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

(* Every Security Open Closed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityOpenClosedMessage ==
    \A message \in CheckedSecurityOpenClosedMessage :
        LET read == DecodeSecurityOpenClosedMessage(EncodeSecurityOpenClosedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Opening Imbalance Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpeningImbalanceMessage ==
    \A message \in CheckedOpeningImbalanceMessage :
        LET read == DecodeOpeningImbalanceMessage(EncodeOpeningImbalanceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order On Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderOnBookMessage ==
    \A message \in CheckedOrderOnBookMessage :
        LET read == DecodeOrderOnBookMessage(EncodeOrderOnBookMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Auction Response decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionResponse ==
    \A message \in CheckedAuctionResponse :
        LET read == DecodeAuctionResponse(EncodeAuctionResponse(message))
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

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
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
