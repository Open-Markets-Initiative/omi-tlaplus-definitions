-------------------- MODULE NomOptions_Cti_v3_0_Server ---------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Clearing Trade Interface v3.0                                  *)
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
(* Note: Expiration is a bit field set, checked as its 2 bytes rather than *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Trade Flags is a bit field set, checked as its 2 bytes rather     *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Clearing Flags is a bit field set, checked as its 2 bytes rather  *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Order Date is a bit field set, checked as its 2 bytes rather than *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Order Indicators is a bit field set, checked as its 2 bytes       *)
(* rather than bit by bit.                                                 *)
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
(* System Event Message: 10 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4),
      version     : Sample(1),
      eventCode   : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.version
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET version == ReadBytes(nanoseconds.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET eventCode == ReadBytes(version.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value,
         version     |-> version.value,
         eventCode   |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0],
      version     |-> [i \in 1 .. 1 |-> 0],
      eventCode   |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSystemEventMessage EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Options Directory Message: 65 bytes                                     *)
(***************************************************************************)

OptionsDirectoryMessage ==
    [ seconds           : Sample(4),
      nanoseconds       : Sample(4),
      version           : Sample(1),
      optionId          : Sample(4),
      securitySymbol    : Sample(8),
      expiration        : Sample(2),
      strikePrice       : Sample(4),
      optionKind        : Sample(1),
      underlyingSymbol  : Sample(13),
      optionClosingType : Sample(1),
      tradable          : Sample(1),
      mpv               : Sample(1),
      closingOnly       : Sample(1),
      contractSize      : Sample(4),
      reserved16        : Sample(16) ]

EncodeOptionsDirectoryMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.version
        \o message.optionId
        \o message.securitySymbol
        \o message.expiration
        \o message.strikePrice
        \o message.optionKind
        \o message.underlyingSymbol
        \o message.optionClosingType
        \o message.tradable
        \o message.mpv
        \o message.closingOnly
        \o message.contractSize
        \o message.reserved16

DecodeOptionsDirectoryMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET version == ReadBytes(nanoseconds.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET optionId == ReadBytes(version.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 8) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expiration == ReadBytes(securitySymbol.rest, 2) IN IF ~expiration.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiration.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionKind == ReadBytes(strikePrice.rest, 1) IN IF ~optionKind.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(optionKind.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET optionClosingType == ReadBytes(underlyingSymbol.rest, 1) IN IF ~optionClosingType.ok THEN Fail ELSE
    LET tradable == ReadBytes(optionClosingType.rest, 1) IN IF ~tradable.ok THEN Fail ELSE
    LET mpv == ReadBytes(tradable.rest, 1) IN IF ~mpv.ok THEN Fail ELSE
    LET closingOnly == ReadBytes(mpv.rest, 1) IN IF ~closingOnly.ok THEN Fail ELSE
    LET contractSize == ReadBytes(closingOnly.rest, 4) IN IF ~contractSize.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(contractSize.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ seconds           |-> seconds.value,
         nanoseconds       |-> nanoseconds.value,
         version           |-> version.value,
         optionId          |-> optionId.value,
         securitySymbol    |-> securitySymbol.value,
         expiration        |-> expiration.value,
         strikePrice       |-> strikePrice.value,
         optionKind        |-> optionKind.value,
         underlyingSymbol  |-> underlyingSymbol.value,
         optionClosingType |-> optionClosingType.value,
         tradable          |-> tradable.value,
         mpv               |-> mpv.value,
         closingOnly       |-> closingOnly.value,
         contractSize      |-> contractSize.value,
         reserved16        |-> reserved16.value ], reserved16.rest)

ZeroOptionsDirectoryMessage ==
    [ seconds           |-> [i \in 1 .. 4 |-> 0],
      nanoseconds       |-> [i \in 1 .. 4 |-> 0],
      version           |-> [i \in 1 .. 1 |-> 0],
      optionId          |-> [i \in 1 .. 4 |-> 0],
      securitySymbol    |-> [i \in 1 .. 8 |-> 0],
      expiration        |-> [i \in 1 .. 2 |-> 0],
      strikePrice       |-> [i \in 1 .. 4 |-> 0],
      optionKind        |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol  |-> [i \in 1 .. 13 |-> 0],
      optionClosingType |-> [i \in 1 .. 1 |-> 0],
      tradable          |-> [i \in 1 .. 1 |-> 0],
      mpv               |-> [i \in 1 .. 1 |-> 0],
      closingOnly       |-> [i \in 1 .. 1 |-> 0],
      contractSize      |-> [i \in 1 .. 4 |-> 0],
      reserved16        |-> [i \in 1 .. 16 |-> 0] ]

(* Options Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedOptionsDirectoryMessage ==
    { ZeroOptionsDirectoryMessage }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.securitySymbol = one] : one \in Sample(8) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.expiration = one] : one \in Sample(2) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.optionKind = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.optionClosingType = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.tradable = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.mpv = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.closingOnly = one] : one \in Sample(1) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.contractSize = one] : one \in Sample(4) }
        \cup { [ZeroOptionsDirectoryMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Security Trading Action Message: 29 bytes                               *)
(***************************************************************************)

SecurityTradingActionMessage ==
    [ seconds             : Sample(4),
      nanoseconds         : Sample(4),
      version             : Sample(1),
      optionId            : Sample(4),
      securitySymbol      : Sample(8),
      expiration          : Sample(2),
      strikePrice         : Sample(4),
      optionKind          : Sample(1),
      currentTradingState : Sample(1) ]

EncodeSecurityTradingActionMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.version
        \o message.optionId
        \o message.securitySymbol
        \o message.expiration
        \o message.strikePrice
        \o message.optionKind
        \o message.currentTradingState

DecodeSecurityTradingActionMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET version == ReadBytes(nanoseconds.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET optionId == ReadBytes(version.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(optionId.rest, 8) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expiration == ReadBytes(securitySymbol.rest, 2) IN IF ~expiration.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiration.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionKind == ReadBytes(strikePrice.rest, 1) IN IF ~optionKind.ok THEN Fail ELSE
    LET currentTradingState == ReadBytes(optionKind.rest, 1) IN IF ~currentTradingState.ok THEN Fail ELSE
    Ok([ seconds             |-> seconds.value,
         nanoseconds         |-> nanoseconds.value,
         version             |-> version.value,
         optionId            |-> optionId.value,
         securitySymbol      |-> securitySymbol.value,
         expiration          |-> expiration.value,
         strikePrice         |-> strikePrice.value,
         optionKind          |-> optionKind.value,
         currentTradingState |-> currentTradingState.value ], currentTradingState.rest)

ZeroSecurityTradingActionMessage ==
    [ seconds             |-> [i \in 1 .. 4 |-> 0],
      nanoseconds         |-> [i \in 1 .. 4 |-> 0],
      version             |-> [i \in 1 .. 1 |-> 0],
      optionId            |-> [i \in 1 .. 4 |-> 0],
      securitySymbol      |-> [i \in 1 .. 8 |-> 0],
      expiration          |-> [i \in 1 .. 2 |-> 0],
      strikePrice         |-> [i \in 1 .. 4 |-> 0],
      optionKind          |-> [i \in 1 .. 1 |-> 0],
      currentTradingState |-> [i \in 1 .. 1 |-> 0] ]

(* Security Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityTradingActionMessage ==
    { ZeroSecurityTradingActionMessage }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.securitySymbol = one] : one \in Sample(8) }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.expiration = one] : one \in Sample(2) }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.optionKind = one] : one \in Sample(1) }
        \cup { [ZeroSecurityTradingActionMessage EXCEPT !.currentTradingState = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Message: 336 bytes                                                *)
(***************************************************************************)

TradeMessage ==
    [ seconds                       : Sample(4),
      nanoseconds                   : Sample(4),
      version                       : Sample(1),
      sendType                      : Sample(1),
      optionId                      : Sample(4),
      underlyingSymbol              : Sample(13),
      securitySymbol                : Sample(8),
      expiration                    : Sample(2),
      strikePrice                   : Sample(4),
      optionKind                    : Sample(1),
      tradeFlags                    : Sample(2),
      reserved4                     : Sample(4),
      transactionType               : Sample(1),
      liquidity                     : Sample(1),
      tradeId                       : Sample(4),
      correctionNumber              : Sample(2),
      crossId                       : Sample(4),
      matchId                       : Sample(4),
      auctionId                     : Sample(4),
      auctionType                   : Sample(1),
      refTradeId                    : Sample(4),
      refCorrectionNumber           : Sample(2),
      refMatchId                    : Sample(4),
      executionType                 : Sample(1),
      executionMarket               : Sample(1),
      tradeSide                     : Sample(1),
      tradePrice                    : Sample(8),
      tradeContracts                : Sample(4),
      sideChanged                   : Sample(1),
      strategyId                    : Sample(4),
      strategyLeg                   : Sample(2),
      reserved8                     : Sample(8),
      occClearingNumber             : Sample(4),
      giveUpOccClearingNumber       : Sample(4),
      exchangeClearingNumber        : Sample(4),
      exchangeHouse                 : Sample(4),
      exchangeSuffix                : Sample(1),
      capacity                      : Sample(1),
      multiAccount                  : Sample(5),
      broker                        : Sample(4),
      secondBroker                  : Sample(4),
      originMarket                  : Sample(1),
      account                       : Sample(32),
      nscc                          : Sample(4),
      mpid                          : Sample(5),
      clearingFlags                 : Sample(2),
      executingBroker               : Sample(4),
      reserved6                     : Sample(6),
      contraOccClearingNumber       : Sample(4),
      contraGiveUpOccClearingNumber : Sample(4),
      contraExchangeClearingNumber  : Sample(4),
      contraExchangeHouse           : Sample(4),
      contraCapacity                : Sample(1),
      contraBroker                  : Sample(4),
      contraSecondBroker            : Sample(4),
      contraNscc                    : Sample(4),
      contraMpid                    : Sample(5),
      secondReserved8               : Sample(8),
      firm                          : Sample(4),
      orderDate                     : Sample(2),
      orderId                       : Sample(30),
      quoteId                       : Sample(8),
      sqfSweepId                    : Sample(8),
      openCloseIndicator            : Sample(1),
      customerStrategyLeg           : Sample(10),
      shortSell                     : Sample(1),
      principalAgent                : Sample(1),
      supplementaryId               : Sample(15),
      orderIndicators               : Sample(2),
      originType                    : Sample(1),
      orderSize                     : Sample(4),
      orderPrice                    : Sample(4),
      tif                           : Sample(1),
      thirdReserved8                : Sample(8) ]

EncodeTradeMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.version
        \o message.sendType
        \o message.optionId
        \o message.underlyingSymbol
        \o message.securitySymbol
        \o message.expiration
        \o message.strikePrice
        \o message.optionKind
        \o message.tradeFlags
        \o message.reserved4
        \o message.transactionType
        \o message.liquidity
        \o message.tradeId
        \o message.correctionNumber
        \o message.crossId
        \o message.matchId
        \o message.auctionId
        \o message.auctionType
        \o message.refTradeId
        \o message.refCorrectionNumber
        \o message.refMatchId
        \o message.executionType
        \o message.executionMarket
        \o message.tradeSide
        \o message.tradePrice
        \o message.tradeContracts
        \o message.sideChanged
        \o message.strategyId
        \o message.strategyLeg
        \o message.reserved8
        \o message.occClearingNumber
        \o message.giveUpOccClearingNumber
        \o message.exchangeClearingNumber
        \o message.exchangeHouse
        \o message.exchangeSuffix
        \o message.capacity
        \o message.multiAccount
        \o message.broker
        \o message.secondBroker
        \o message.originMarket
        \o message.account
        \o message.nscc
        \o message.mpid
        \o message.clearingFlags
        \o message.executingBroker
        \o message.reserved6
        \o message.contraOccClearingNumber
        \o message.contraGiveUpOccClearingNumber
        \o message.contraExchangeClearingNumber
        \o message.contraExchangeHouse
        \o message.contraCapacity
        \o message.contraBroker
        \o message.contraSecondBroker
        \o message.contraNscc
        \o message.contraMpid
        \o message.secondReserved8
        \o message.firm
        \o message.orderDate
        \o message.orderId
        \o message.quoteId
        \o message.sqfSweepId
        \o message.openCloseIndicator
        \o message.customerStrategyLeg
        \o message.shortSell
        \o message.principalAgent
        \o message.supplementaryId
        \o message.orderIndicators
        \o message.originType
        \o message.orderSize
        \o message.orderPrice
        \o message.tif
        \o message.thirdReserved8

DecodeTradeMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET version == ReadBytes(nanoseconds.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET sendType == ReadBytes(version.rest, 1) IN IF ~sendType.ok THEN Fail ELSE
    LET optionId == ReadBytes(sendType.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(optionId.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(underlyingSymbol.rest, 8) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expiration == ReadBytes(securitySymbol.rest, 2) IN IF ~expiration.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiration.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionKind == ReadBytes(strikePrice.rest, 1) IN IF ~optionKind.ok THEN Fail ELSE
    LET tradeFlags == ReadBytes(optionKind.rest, 2) IN IF ~tradeFlags.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(tradeFlags.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET transactionType == ReadBytes(reserved4.rest, 1) IN IF ~transactionType.ok THEN Fail ELSE
    LET liquidity == ReadBytes(transactionType.rest, 1) IN IF ~liquidity.ok THEN Fail ELSE
    LET tradeId == ReadBytes(liquidity.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(tradeId.rest, 2) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET crossId == ReadBytes(correctionNumber.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET matchId == ReadBytes(crossId.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    LET auctionId == ReadBytes(matchId.rest, 4) IN IF ~auctionId.ok THEN Fail ELSE
    LET auctionType == ReadBytes(auctionId.rest, 1) IN IF ~auctionType.ok THEN Fail ELSE
    LET refTradeId == ReadBytes(auctionType.rest, 4) IN IF ~refTradeId.ok THEN Fail ELSE
    LET refCorrectionNumber == ReadBytes(refTradeId.rest, 2) IN IF ~refCorrectionNumber.ok THEN Fail ELSE
    LET refMatchId == ReadBytes(refCorrectionNumber.rest, 4) IN IF ~refMatchId.ok THEN Fail ELSE
    LET executionType == ReadBytes(refMatchId.rest, 1) IN IF ~executionType.ok THEN Fail ELSE
    LET executionMarket == ReadBytes(executionType.rest, 1) IN IF ~executionMarket.ok THEN Fail ELSE
    LET tradeSide == ReadBytes(executionMarket.rest, 1) IN IF ~tradeSide.ok THEN Fail ELSE
    LET tradePrice == ReadBytes(tradeSide.rest, 8) IN IF ~tradePrice.ok THEN Fail ELSE
    LET tradeContracts == ReadBytes(tradePrice.rest, 4) IN IF ~tradeContracts.ok THEN Fail ELSE
    LET sideChanged == ReadBytes(tradeContracts.rest, 1) IN IF ~sideChanged.ok THEN Fail ELSE
    LET strategyId == ReadBytes(sideChanged.rest, 4) IN IF ~strategyId.ok THEN Fail ELSE
    LET strategyLeg == ReadBytes(strategyId.rest, 2) IN IF ~strategyLeg.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(strategyLeg.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET occClearingNumber == ReadBytes(reserved8.rest, 4) IN IF ~occClearingNumber.ok THEN Fail ELSE
    LET giveUpOccClearingNumber == ReadBytes(occClearingNumber.rest, 4) IN IF ~giveUpOccClearingNumber.ok THEN Fail ELSE
    LET exchangeClearingNumber == ReadBytes(giveUpOccClearingNumber.rest, 4) IN IF ~exchangeClearingNumber.ok THEN Fail ELSE
    LET exchangeHouse == ReadBytes(exchangeClearingNumber.rest, 4) IN IF ~exchangeHouse.ok THEN Fail ELSE
    LET exchangeSuffix == ReadBytes(exchangeHouse.rest, 1) IN IF ~exchangeSuffix.ok THEN Fail ELSE
    LET capacity == ReadBytes(exchangeSuffix.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET multiAccount == ReadBytes(capacity.rest, 5) IN IF ~multiAccount.ok THEN Fail ELSE
    LET broker == ReadBytes(multiAccount.rest, 4) IN IF ~broker.ok THEN Fail ELSE
    LET secondBroker == ReadBytes(broker.rest, 4) IN IF ~secondBroker.ok THEN Fail ELSE
    LET originMarket == ReadBytes(secondBroker.rest, 1) IN IF ~originMarket.ok THEN Fail ELSE
    LET account == ReadBytes(originMarket.rest, 32) IN IF ~account.ok THEN Fail ELSE
    LET nscc == ReadBytes(account.rest, 4) IN IF ~nscc.ok THEN Fail ELSE
    LET mpid == ReadBytes(nscc.rest, 5) IN IF ~mpid.ok THEN Fail ELSE
    LET clearingFlags == ReadBytes(mpid.rest, 2) IN IF ~clearingFlags.ok THEN Fail ELSE
    LET executingBroker == ReadBytes(clearingFlags.rest, 4) IN IF ~executingBroker.ok THEN Fail ELSE
    LET reserved6 == ReadBytes(executingBroker.rest, 6) IN IF ~reserved6.ok THEN Fail ELSE
    LET contraOccClearingNumber == ReadBytes(reserved6.rest, 4) IN IF ~contraOccClearingNumber.ok THEN Fail ELSE
    LET contraGiveUpOccClearingNumber == ReadBytes(contraOccClearingNumber.rest, 4) IN IF ~contraGiveUpOccClearingNumber.ok THEN Fail ELSE
    LET contraExchangeClearingNumber == ReadBytes(contraGiveUpOccClearingNumber.rest, 4) IN IF ~contraExchangeClearingNumber.ok THEN Fail ELSE
    LET contraExchangeHouse == ReadBytes(contraExchangeClearingNumber.rest, 4) IN IF ~contraExchangeHouse.ok THEN Fail ELSE
    LET contraCapacity == ReadBytes(contraExchangeHouse.rest, 1) IN IF ~contraCapacity.ok THEN Fail ELSE
    LET contraBroker == ReadBytes(contraCapacity.rest, 4) IN IF ~contraBroker.ok THEN Fail ELSE
    LET contraSecondBroker == ReadBytes(contraBroker.rest, 4) IN IF ~contraSecondBroker.ok THEN Fail ELSE
    LET contraNscc == ReadBytes(contraSecondBroker.rest, 4) IN IF ~contraNscc.ok THEN Fail ELSE
    LET contraMpid == ReadBytes(contraNscc.rest, 5) IN IF ~contraMpid.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(contraMpid.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET firm == ReadBytes(secondReserved8.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET orderDate == ReadBytes(firm.rest, 2) IN IF ~orderDate.ok THEN Fail ELSE
    LET orderId == ReadBytes(orderDate.rest, 30) IN IF ~orderId.ok THEN Fail ELSE
    LET quoteId == ReadBytes(orderId.rest, 8) IN IF ~quoteId.ok THEN Fail ELSE
    LET sqfSweepId == ReadBytes(quoteId.rest, 8) IN IF ~sqfSweepId.ok THEN Fail ELSE
    LET openCloseIndicator == ReadBytes(sqfSweepId.rest, 1) IN IF ~openCloseIndicator.ok THEN Fail ELSE
    LET customerStrategyLeg == ReadBytes(openCloseIndicator.rest, 10) IN IF ~customerStrategyLeg.ok THEN Fail ELSE
    LET shortSell == ReadBytes(customerStrategyLeg.rest, 1) IN IF ~shortSell.ok THEN Fail ELSE
    LET principalAgent == ReadBytes(shortSell.rest, 1) IN IF ~principalAgent.ok THEN Fail ELSE
    LET supplementaryId == ReadBytes(principalAgent.rest, 15) IN IF ~supplementaryId.ok THEN Fail ELSE
    LET orderIndicators == ReadBytes(supplementaryId.rest, 2) IN IF ~orderIndicators.ok THEN Fail ELSE
    LET originType == ReadBytes(orderIndicators.rest, 1) IN IF ~originType.ok THEN Fail ELSE
    LET orderSize == ReadBytes(originType.rest, 4) IN IF ~orderSize.ok THEN Fail ELSE
    LET orderPrice == ReadBytes(orderSize.rest, 4) IN IF ~orderPrice.ok THEN Fail ELSE
    LET tif == ReadBytes(orderPrice.rest, 1) IN IF ~tif.ok THEN Fail ELSE
    LET thirdReserved8 == ReadBytes(tif.rest, 8) IN IF ~thirdReserved8.ok THEN Fail ELSE
    Ok([ seconds                       |-> seconds.value,
         nanoseconds                   |-> nanoseconds.value,
         version                       |-> version.value,
         sendType                      |-> sendType.value,
         optionId                      |-> optionId.value,
         underlyingSymbol              |-> underlyingSymbol.value,
         securitySymbol                |-> securitySymbol.value,
         expiration                    |-> expiration.value,
         strikePrice                   |-> strikePrice.value,
         optionKind                    |-> optionKind.value,
         tradeFlags                    |-> tradeFlags.value,
         reserved4                     |-> reserved4.value,
         transactionType               |-> transactionType.value,
         liquidity                     |-> liquidity.value,
         tradeId                       |-> tradeId.value,
         correctionNumber              |-> correctionNumber.value,
         crossId                       |-> crossId.value,
         matchId                       |-> matchId.value,
         auctionId                     |-> auctionId.value,
         auctionType                   |-> auctionType.value,
         refTradeId                    |-> refTradeId.value,
         refCorrectionNumber           |-> refCorrectionNumber.value,
         refMatchId                    |-> refMatchId.value,
         executionType                 |-> executionType.value,
         executionMarket               |-> executionMarket.value,
         tradeSide                     |-> tradeSide.value,
         tradePrice                    |-> tradePrice.value,
         tradeContracts                |-> tradeContracts.value,
         sideChanged                   |-> sideChanged.value,
         strategyId                    |-> strategyId.value,
         strategyLeg                   |-> strategyLeg.value,
         reserved8                     |-> reserved8.value,
         occClearingNumber             |-> occClearingNumber.value,
         giveUpOccClearingNumber       |-> giveUpOccClearingNumber.value,
         exchangeClearingNumber        |-> exchangeClearingNumber.value,
         exchangeHouse                 |-> exchangeHouse.value,
         exchangeSuffix                |-> exchangeSuffix.value,
         capacity                      |-> capacity.value,
         multiAccount                  |-> multiAccount.value,
         broker                        |-> broker.value,
         secondBroker                  |-> secondBroker.value,
         originMarket                  |-> originMarket.value,
         account                       |-> account.value,
         nscc                          |-> nscc.value,
         mpid                          |-> mpid.value,
         clearingFlags                 |-> clearingFlags.value,
         executingBroker               |-> executingBroker.value,
         reserved6                     |-> reserved6.value,
         contraOccClearingNumber       |-> contraOccClearingNumber.value,
         contraGiveUpOccClearingNumber |-> contraGiveUpOccClearingNumber.value,
         contraExchangeClearingNumber  |-> contraExchangeClearingNumber.value,
         contraExchangeHouse           |-> contraExchangeHouse.value,
         contraCapacity                |-> contraCapacity.value,
         contraBroker                  |-> contraBroker.value,
         contraSecondBroker            |-> contraSecondBroker.value,
         contraNscc                    |-> contraNscc.value,
         contraMpid                    |-> contraMpid.value,
         secondReserved8               |-> secondReserved8.value,
         firm                          |-> firm.value,
         orderDate                     |-> orderDate.value,
         orderId                       |-> orderId.value,
         quoteId                       |-> quoteId.value,
         sqfSweepId                    |-> sqfSweepId.value,
         openCloseIndicator            |-> openCloseIndicator.value,
         customerStrategyLeg           |-> customerStrategyLeg.value,
         shortSell                     |-> shortSell.value,
         principalAgent                |-> principalAgent.value,
         supplementaryId               |-> supplementaryId.value,
         orderIndicators               |-> orderIndicators.value,
         originType                    |-> originType.value,
         orderSize                     |-> orderSize.value,
         orderPrice                    |-> orderPrice.value,
         tif                           |-> tif.value,
         thirdReserved8                |-> thirdReserved8.value ], thirdReserved8.rest)

ZeroTradeMessage ==
    [ seconds                       |-> [i \in 1 .. 4 |-> 0],
      nanoseconds                   |-> [i \in 1 .. 4 |-> 0],
      version                       |-> [i \in 1 .. 1 |-> 0],
      sendType                      |-> [i \in 1 .. 1 |-> 0],
      optionId                      |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol              |-> [i \in 1 .. 13 |-> 0],
      securitySymbol                |-> [i \in 1 .. 8 |-> 0],
      expiration                    |-> [i \in 1 .. 2 |-> 0],
      strikePrice                   |-> [i \in 1 .. 4 |-> 0],
      optionKind                    |-> [i \in 1 .. 1 |-> 0],
      tradeFlags                    |-> [i \in 1 .. 2 |-> 0],
      reserved4                     |-> [i \in 1 .. 4 |-> 0],
      transactionType               |-> [i \in 1 .. 1 |-> 0],
      liquidity                     |-> [i \in 1 .. 1 |-> 0],
      tradeId                       |-> [i \in 1 .. 4 |-> 0],
      correctionNumber              |-> [i \in 1 .. 2 |-> 0],
      crossId                       |-> [i \in 1 .. 4 |-> 0],
      matchId                       |-> [i \in 1 .. 4 |-> 0],
      auctionId                     |-> [i \in 1 .. 4 |-> 0],
      auctionType                   |-> [i \in 1 .. 1 |-> 0],
      refTradeId                    |-> [i \in 1 .. 4 |-> 0],
      refCorrectionNumber           |-> [i \in 1 .. 2 |-> 0],
      refMatchId                    |-> [i \in 1 .. 4 |-> 0],
      executionType                 |-> [i \in 1 .. 1 |-> 0],
      executionMarket               |-> [i \in 1 .. 1 |-> 0],
      tradeSide                     |-> [i \in 1 .. 1 |-> 0],
      tradePrice                    |-> [i \in 1 .. 8 |-> 0],
      tradeContracts                |-> [i \in 1 .. 4 |-> 0],
      sideChanged                   |-> [i \in 1 .. 1 |-> 0],
      strategyId                    |-> [i \in 1 .. 4 |-> 0],
      strategyLeg                   |-> [i \in 1 .. 2 |-> 0],
      reserved8                     |-> [i \in 1 .. 8 |-> 0],
      occClearingNumber             |-> [i \in 1 .. 4 |-> 0],
      giveUpOccClearingNumber       |-> [i \in 1 .. 4 |-> 0],
      exchangeClearingNumber        |-> [i \in 1 .. 4 |-> 0],
      exchangeHouse                 |-> [i \in 1 .. 4 |-> 0],
      exchangeSuffix                |-> [i \in 1 .. 1 |-> 0],
      capacity                      |-> [i \in 1 .. 1 |-> 0],
      multiAccount                  |-> [i \in 1 .. 5 |-> 0],
      broker                        |-> [i \in 1 .. 4 |-> 0],
      secondBroker                  |-> [i \in 1 .. 4 |-> 0],
      originMarket                  |-> [i \in 1 .. 1 |-> 0],
      account                       |-> [i \in 1 .. 32 |-> 0],
      nscc                          |-> [i \in 1 .. 4 |-> 0],
      mpid                          |-> [i \in 1 .. 5 |-> 0],
      clearingFlags                 |-> [i \in 1 .. 2 |-> 0],
      executingBroker               |-> [i \in 1 .. 4 |-> 0],
      reserved6                     |-> [i \in 1 .. 6 |-> 0],
      contraOccClearingNumber       |-> [i \in 1 .. 4 |-> 0],
      contraGiveUpOccClearingNumber |-> [i \in 1 .. 4 |-> 0],
      contraExchangeClearingNumber  |-> [i \in 1 .. 4 |-> 0],
      contraExchangeHouse           |-> [i \in 1 .. 4 |-> 0],
      contraCapacity                |-> [i \in 1 .. 1 |-> 0],
      contraBroker                  |-> [i \in 1 .. 4 |-> 0],
      contraSecondBroker            |-> [i \in 1 .. 4 |-> 0],
      contraNscc                    |-> [i \in 1 .. 4 |-> 0],
      contraMpid                    |-> [i \in 1 .. 5 |-> 0],
      secondReserved8               |-> [i \in 1 .. 8 |-> 0],
      firm                          |-> [i \in 1 .. 4 |-> 0],
      orderDate                     |-> [i \in 1 .. 2 |-> 0],
      orderId                       |-> [i \in 1 .. 30 |-> 0],
      quoteId                       |-> [i \in 1 .. 8 |-> 0],
      sqfSweepId                    |-> [i \in 1 .. 8 |-> 0],
      openCloseIndicator            |-> [i \in 1 .. 1 |-> 0],
      customerStrategyLeg           |-> [i \in 1 .. 10 |-> 0],
      shortSell                     |-> [i \in 1 .. 1 |-> 0],
      principalAgent                |-> [i \in 1 .. 1 |-> 0],
      supplementaryId               |-> [i \in 1 .. 15 |-> 0],
      orderIndicators               |-> [i \in 1 .. 2 |-> 0],
      originType                    |-> [i \in 1 .. 1 |-> 0],
      orderSize                     |-> [i \in 1 .. 4 |-> 0],
      orderPrice                    |-> [i \in 1 .. 4 |-> 0],
      tif                           |-> [i \in 1 .. 1 |-> 0],
      thirdReserved8                |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.sendType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.expiration = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.optionKind = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeFlags = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.transactionType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.liquidity = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.correctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.matchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.auctionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.auctionType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.refTradeId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.refCorrectionNumber = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.refMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.executionType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.executionMarket = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeSide = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeContracts = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.sideChanged = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.strategyId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.strategyLeg = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.occClearingNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.giveUpOccClearingNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.exchangeClearingNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.exchangeHouse = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.exchangeSuffix = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.multiAccount = one] : one \in Sample(5) }
        \cup { [ZeroTradeMessage EXCEPT !.broker = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.secondBroker = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.originMarket = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.account = one] : one \in Sample(32) }
        \cup { [ZeroTradeMessage EXCEPT !.nscc = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.mpid = one] : one \in Sample(5) }
        \cup { [ZeroTradeMessage EXCEPT !.clearingFlags = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.executingBroker = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.reserved6 = one] : one \in Sample(6) }
        \cup { [ZeroTradeMessage EXCEPT !.contraOccClearingNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.contraGiveUpOccClearingNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.contraExchangeClearingNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.contraExchangeHouse = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.contraCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.contraBroker = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.contraSecondBroker = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.contraNscc = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.contraMpid = one] : one \in Sample(5) }
        \cup { [ZeroTradeMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.orderDate = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.orderId = one] : one \in Sample(30) }
        \cup { [ZeroTradeMessage EXCEPT !.quoteId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.sqfSweepId = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.openCloseIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.customerStrategyLeg = one] : one \in Sample(10) }
        \cup { [ZeroTradeMessage EXCEPT !.shortSell = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.principalAgent = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.supplementaryId = one] : one \in Sample(15) }
        \cup { [ZeroTradeMessage EXCEPT !.orderIndicators = one] : one \in Sample(2) }
        \cup { [ZeroTradeMessage EXCEPT !.originType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.orderSize = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.orderPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.tif = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.thirdReserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Cancel Trade Message: 65 bytes                                          *)
(***************************************************************************)

CancelTradeMessage ==
    [ seconds          : Sample(4),
      nanoseconds      : Sample(4),
      version          : Sample(1),
      sendType         : Sample(1),
      optionId         : Sample(4),
      underlyingSymbol : Sample(13),
      securitySymbol   : Sample(8),
      expiration       : Sample(2),
      strikePrice      : Sample(4),
      optionKind       : Sample(1),
      tradeId          : Sample(4),
      correctionNumber : Sample(2),
      crossId          : Sample(4),
      tradeSide        : Sample(1),
      matchId          : Sample(4),
      reserved8        : Sample(8) ]

EncodeCancelTradeMessage(message) ==
    message.seconds
        \o message.nanoseconds
        \o message.version
        \o message.sendType
        \o message.optionId
        \o message.underlyingSymbol
        \o message.securitySymbol
        \o message.expiration
        \o message.strikePrice
        \o message.optionKind
        \o message.tradeId
        \o message.correctionNumber
        \o message.crossId
        \o message.tradeSide
        \o message.matchId
        \o message.reserved8

DecodeCancelTradeMessage(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    LET version == ReadBytes(nanoseconds.rest, 1) IN IF ~version.ok THEN Fail ELSE
    LET sendType == ReadBytes(version.rest, 1) IN IF ~sendType.ok THEN Fail ELSE
    LET optionId == ReadBytes(sendType.rest, 4) IN IF ~optionId.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(optionId.rest, 13) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET securitySymbol == ReadBytes(underlyingSymbol.rest, 8) IN IF ~securitySymbol.ok THEN Fail ELSE
    LET expiration == ReadBytes(securitySymbol.rest, 2) IN IF ~expiration.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiration.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionKind == ReadBytes(strikePrice.rest, 1) IN IF ~optionKind.ok THEN Fail ELSE
    LET tradeId == ReadBytes(optionKind.rest, 4) IN IF ~tradeId.ok THEN Fail ELSE
    LET correctionNumber == ReadBytes(tradeId.rest, 2) IN IF ~correctionNumber.ok THEN Fail ELSE
    LET crossId == ReadBytes(correctionNumber.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET tradeSide == ReadBytes(crossId.rest, 1) IN IF ~tradeSide.ok THEN Fail ELSE
    LET matchId == ReadBytes(tradeSide.rest, 4) IN IF ~matchId.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(matchId.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ seconds          |-> seconds.value,
         nanoseconds      |-> nanoseconds.value,
         version          |-> version.value,
         sendType         |-> sendType.value,
         optionId         |-> optionId.value,
         underlyingSymbol |-> underlyingSymbol.value,
         securitySymbol   |-> securitySymbol.value,
         expiration       |-> expiration.value,
         strikePrice      |-> strikePrice.value,
         optionKind       |-> optionKind.value,
         tradeId          |-> tradeId.value,
         correctionNumber |-> correctionNumber.value,
         crossId          |-> crossId.value,
         tradeSide        |-> tradeSide.value,
         matchId          |-> matchId.value,
         reserved8        |-> reserved8.value ], reserved8.rest)

ZeroCancelTradeMessage ==
    [ seconds          |-> [i \in 1 .. 4 |-> 0],
      nanoseconds      |-> [i \in 1 .. 4 |-> 0],
      version          |-> [i \in 1 .. 1 |-> 0],
      sendType         |-> [i \in 1 .. 1 |-> 0],
      optionId         |-> [i \in 1 .. 4 |-> 0],
      underlyingSymbol |-> [i \in 1 .. 13 |-> 0],
      securitySymbol   |-> [i \in 1 .. 8 |-> 0],
      expiration       |-> [i \in 1 .. 2 |-> 0],
      strikePrice      |-> [i \in 1 .. 4 |-> 0],
      optionKind       |-> [i \in 1 .. 1 |-> 0],
      tradeId          |-> [i \in 1 .. 4 |-> 0],
      correctionNumber |-> [i \in 1 .. 2 |-> 0],
      crossId          |-> [i \in 1 .. 4 |-> 0],
      tradeSide        |-> [i \in 1 .. 1 |-> 0],
      matchId          |-> [i \in 1 .. 4 |-> 0],
      reserved8        |-> [i \in 1 .. 8 |-> 0] ]

(* Cancel Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelTradeMessage ==
    { ZeroCancelTradeMessage }
        \cup { [ZeroCancelTradeMessage EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.nanoseconds = one] : one \in Sample(4) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.version = one] : one \in Sample(1) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.sendType = one] : one \in Sample(1) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.optionId = one] : one \in Sample(4) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(13) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.securitySymbol = one] : one \in Sample(8) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.expiration = one] : one \in Sample(2) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.optionKind = one] : one \in Sample(1) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.tradeId = one] : one \in Sample(4) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.correctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.tradeSide = one] : one \in Sample(1) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.matchId = one] : one \in Sample(4) }
        \cup { [ZeroCancelTradeMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
OptionsDirectoryMessageCode == 68  \* "D"
SecurityTradingActionMessageCode == 72  \* "H"
TradeMessageCode == 84  \* "T"
CancelTradeMessageCode == 86  \* "V"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OptionsDirectoryMessageCode}, body : OptionsDirectoryMessage ]
        \cup [ tag : {SecurityTradingActionMessageCode}, body : SecurityTradingActionMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {CancelTradeMessageCode}, body : CancelTradeMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OptionsDirectoryMessageCode -> EncodeOptionsDirectoryMessage(message.body)
      [] message.tag = SecurityTradingActionMessageCode -> EncodeSecurityTradingActionMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = CancelTradeMessageCode -> EncodeCancelTradeMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OptionsDirectoryMessageCode -> DecodeOptionsDirectoryMessage(bytes)
              [] tag = SecurityTradingActionMessageCode -> DecodeSecurityTradingActionMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = CancelTradeMessageCode -> DecodeCancelTradeMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OptionsDirectoryMessageCode, body |-> one] : one \in CheckedOptionsDirectoryMessage }
        \cup { [tag |-> SecurityTradingActionMessageCode, body |-> one] : one \in CheckedSecurityTradingActionMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> CancelTradeMessageCode, body |-> one] : one \in CheckedCancelTradeMessage }

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
ServerHeartbeatCode == 72  \* "H"
EndOfSessionCode == 90  \* "Z"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]
        \cup [ tag : {ServerHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfSessionCode}, body : {[empty |-> 0]} ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)
      [] message.tag = ServerHeartbeatCode -> << >>
      [] message.tag = EndOfSessionCode -> << >>

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] tag = ServerHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfSessionCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }
        \cup { [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfSessionCode, body |-> [empty |-> 0]] }

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
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> ServerHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroServerSoupBinTcpPacket EXCEPT !.serverPayload = [tag |-> EndOfSessionCode, body |-> [empty |-> 0]]] }

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

(* Every Security Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityTradingActionMessage ==
    \A message \in CheckedSecurityTradingActionMessage :
        LET read == DecodeSecurityTradingActionMessage(EncodeSecurityTradingActionMessage(message))
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

(* Every Cancel Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelTradeMessage ==
    \A message \in CheckedCancelTradeMessage :
        LET read == DecodeCancelTradeMessage(EncodeCancelTradeMessage(message))
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
