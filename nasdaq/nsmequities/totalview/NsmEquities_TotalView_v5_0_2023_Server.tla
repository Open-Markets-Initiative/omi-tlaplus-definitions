-------------- MODULE NsmEquities_TotalView_v5_0_2023_Server ---------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) TotalView Itch v5.0.2023                                       *)
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
(* System Event Message: 11 bytes                                          *)
(***************************************************************************)

SystemEventMessage ==
    [ stockLocate    : Sample(2),
      trackingNumber : Sample(2),
      timestamp      : Sample(6),
      eventCode      : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ stockLocate    |-> stockLocate.value,
         trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         eventCode      |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ stockLocate    |-> [i \in 1 .. 2 |-> 0],
      trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      eventCode      |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Directory Message: 38 bytes                                       *)
(***************************************************************************)

StockDirectoryMessage ==
    [ stockLocate                 : Sample(2),
      trackingNumber              : Sample(2),
      timestamp                   : Sample(6),
      stock                       : Sample(8),
      marketCategory              : Sample(1),
      financialStatusIndicator    : Sample(1),
      roundLotSize                : Sample(4),
      roundLotsOnly               : Sample(1),
      issueClassification         : Sample(1),
      issueSubType                : Sample(2),
      authenticity                : Sample(1),
      shortSaleThresholdIndicator : Sample(1),
      ipoFlag                     : Sample(1),
      luldReferencePriceTier      : Sample(1),
      etpFlag                     : Sample(1),
      etpLeverageFactor           : Sample(4),
      inverseIndicator            : Sample(1) ]

EncodeStockDirectoryMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.stock
        \o message.marketCategory
        \o message.financialStatusIndicator
        \o message.roundLotSize
        \o message.roundLotsOnly
        \o message.issueClassification
        \o message.issueSubType
        \o message.authenticity
        \o message.shortSaleThresholdIndicator
        \o message.ipoFlag
        \o message.luldReferencePriceTier
        \o message.etpFlag
        \o message.etpLeverageFactor
        \o message.inverseIndicator

DecodeStockDirectoryMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET marketCategory == ReadBytes(stock.rest, 1) IN IF ~marketCategory.ok THEN Fail ELSE
    LET financialStatusIndicator == ReadBytes(marketCategory.rest, 1) IN IF ~financialStatusIndicator.ok THEN Fail ELSE
    LET roundLotSize == ReadBytes(financialStatusIndicator.rest, 4) IN IF ~roundLotSize.ok THEN Fail ELSE
    LET roundLotsOnly == ReadBytes(roundLotSize.rest, 1) IN IF ~roundLotsOnly.ok THEN Fail ELSE
    LET issueClassification == ReadBytes(roundLotsOnly.rest, 1) IN IF ~issueClassification.ok THEN Fail ELSE
    LET issueSubType == ReadBytes(issueClassification.rest, 2) IN IF ~issueSubType.ok THEN Fail ELSE
    LET authenticity == ReadBytes(issueSubType.rest, 1) IN IF ~authenticity.ok THEN Fail ELSE
    LET shortSaleThresholdIndicator == ReadBytes(authenticity.rest, 1) IN IF ~shortSaleThresholdIndicator.ok THEN Fail ELSE
    LET ipoFlag == ReadBytes(shortSaleThresholdIndicator.rest, 1) IN IF ~ipoFlag.ok THEN Fail ELSE
    LET luldReferencePriceTier == ReadBytes(ipoFlag.rest, 1) IN IF ~luldReferencePriceTier.ok THEN Fail ELSE
    LET etpFlag == ReadBytes(luldReferencePriceTier.rest, 1) IN IF ~etpFlag.ok THEN Fail ELSE
    LET etpLeverageFactor == ReadBytes(etpFlag.rest, 4) IN IF ~etpLeverageFactor.ok THEN Fail ELSE
    LET inverseIndicator == ReadBytes(etpLeverageFactor.rest, 1) IN IF ~inverseIndicator.ok THEN Fail ELSE
    Ok([ stockLocate                 |-> stockLocate.value,
         trackingNumber              |-> trackingNumber.value,
         timestamp                   |-> timestamp.value,
         stock                       |-> stock.value,
         marketCategory              |-> marketCategory.value,
         financialStatusIndicator    |-> financialStatusIndicator.value,
         roundLotSize                |-> roundLotSize.value,
         roundLotsOnly               |-> roundLotsOnly.value,
         issueClassification         |-> issueClassification.value,
         issueSubType                |-> issueSubType.value,
         authenticity                |-> authenticity.value,
         shortSaleThresholdIndicator |-> shortSaleThresholdIndicator.value,
         ipoFlag                     |-> ipoFlag.value,
         luldReferencePriceTier      |-> luldReferencePriceTier.value,
         etpFlag                     |-> etpFlag.value,
         etpLeverageFactor           |-> etpLeverageFactor.value,
         inverseIndicator            |-> inverseIndicator.value ], inverseIndicator.rest)

ZeroStockDirectoryMessage ==
    [ stockLocate                 |-> [i \in 1 .. 2 |-> 0],
      trackingNumber              |-> [i \in 1 .. 2 |-> 0],
      timestamp                   |-> [i \in 1 .. 6 |-> 0],
      stock                       |-> [i \in 1 .. 8 |-> 0],
      marketCategory              |-> [i \in 1 .. 1 |-> 0],
      financialStatusIndicator    |-> [i \in 1 .. 1 |-> 0],
      roundLotSize                |-> [i \in 1 .. 4 |-> 0],
      roundLotsOnly               |-> [i \in 1 .. 1 |-> 0],
      issueClassification         |-> [i \in 1 .. 1 |-> 0],
      issueSubType                |-> [i \in 1 .. 2 |-> 0],
      authenticity                |-> [i \in 1 .. 1 |-> 0],
      shortSaleThresholdIndicator |-> [i \in 1 .. 1 |-> 0],
      ipoFlag                     |-> [i \in 1 .. 1 |-> 0],
      luldReferencePriceTier      |-> [i \in 1 .. 1 |-> 0],
      etpFlag                     |-> [i \in 1 .. 1 |-> 0],
      etpLeverageFactor           |-> [i \in 1 .. 4 |-> 0],
      inverseIndicator            |-> [i \in 1 .. 1 |-> 0] ]

(* Stock Directory Message at zero, then each field in turn at the values it is checked at *)
CheckedStockDirectoryMessage ==
    { ZeroStockDirectoryMessage }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.marketCategory = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.financialStatusIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotSize = one] : one \in Sample(4) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.roundLotsOnly = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.issueClassification = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.issueSubType = one] : one \in Sample(2) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.authenticity = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.shortSaleThresholdIndicator = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.ipoFlag = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.luldReferencePriceTier = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.etpFlag = one] : one \in Sample(1) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.etpLeverageFactor = one] : one \in Sample(4) }
        \cup { [ZeroStockDirectoryMessage EXCEPT !.inverseIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Stock Trading Action Message: 24 bytes                                  *)
(***************************************************************************)

StockTradingActionMessage ==
    [ stockLocate    : Sample(2),
      trackingNumber : Sample(2),
      timestamp      : Sample(6),
      stock          : Sample(8),
      tradingState   : Sample(1),
      reserved       : Sample(1),
      reasonCode     : Sample(4) ]

EncodeStockTradingActionMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.stock
        \o message.tradingState
        \o message.reserved
        \o message.reasonCode

DecodeStockTradingActionMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET tradingState == ReadBytes(stock.rest, 1) IN IF ~tradingState.ok THEN Fail ELSE
    LET reserved == ReadBytes(tradingState.rest, 1) IN IF ~reserved.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(reserved.rest, 4) IN IF ~reasonCode.ok THEN Fail ELSE
    Ok([ stockLocate    |-> stockLocate.value,
         trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         stock          |-> stock.value,
         tradingState   |-> tradingState.value,
         reserved       |-> reserved.value,
         reasonCode     |-> reasonCode.value ], reasonCode.rest)

ZeroStockTradingActionMessage ==
    [ stockLocate    |-> [i \in 1 .. 2 |-> 0],
      trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      stock          |-> [i \in 1 .. 8 |-> 0],
      tradingState   |-> [i \in 1 .. 1 |-> 0],
      reserved       |-> [i \in 1 .. 1 |-> 0],
      reasonCode     |-> [i \in 1 .. 4 |-> 0] ]

(* Stock Trading Action Message at zero, then each field in turn at the values it is checked at *)
CheckedStockTradingActionMessage ==
    { ZeroStockTradingActionMessage }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.tradingState = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reserved = one] : one \in Sample(1) }
        \cup { [ZeroStockTradingActionMessage EXCEPT !.reasonCode = one] : one \in Sample(4) }

(***************************************************************************)
(* Reg Sho Short Sale Price Test Restricted Indicator Message: 19 bytes    *)
(***************************************************************************)

RegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ locateCode     : Sample(2),
      trackingNumber : Sample(2),
      timestamp      : Sample(6),
      stock          : Sample(8),
      regShoAction   : Sample(1) ]

EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message) ==
    message.locateCode
        \o message.trackingNumber
        \o message.timestamp
        \o message.stock
        \o message.regShoAction

DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes) ==
    LET locateCode == ReadBytes(bytes, 2) IN IF ~locateCode.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(locateCode.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET regShoAction == ReadBytes(stock.rest, 1) IN IF ~regShoAction.ok THEN Fail ELSE
    Ok([ locateCode     |-> locateCode.value,
         trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         stock          |-> stock.value,
         regShoAction   |-> regShoAction.value ], regShoAction.rest)

ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    [ locateCode     |-> [i \in 1 .. 2 |-> 0],
      trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      stock          |-> [i \in 1 .. 8 |-> 0],
      regShoAction   |-> [i \in 1 .. 1 |-> 0] ]

(* Reg Sho Short Sale Price Test Restricted Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    { ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.locateCode = one] : one \in Sample(2) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroRegShoShortSalePriceTestRestrictedIndicatorMessage EXCEPT !.regShoAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Market Participant Position Message: 25 bytes                           *)
(***************************************************************************)

MarketParticipantPositionMessage ==
    [ stockLocate            : Sample(2),
      trackingNumber         : Sample(2),
      timestamp              : Sample(6),
      mpid                   : Sample(4),
      stock                  : Sample(8),
      primaryMarketMaker     : Sample(1),
      marketMakerMode        : Sample(1),
      marketParticipantState : Sample(1) ]

EncodeMarketParticipantPositionMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.mpid
        \o message.stock
        \o message.primaryMarketMaker
        \o message.marketMakerMode
        \o message.marketParticipantState

DecodeMarketParticipantPositionMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET mpid == ReadBytes(timestamp.rest, 4) IN IF ~mpid.ok THEN Fail ELSE
    LET stock == ReadBytes(mpid.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET primaryMarketMaker == ReadBytes(stock.rest, 1) IN IF ~primaryMarketMaker.ok THEN Fail ELSE
    LET marketMakerMode == ReadBytes(primaryMarketMaker.rest, 1) IN IF ~marketMakerMode.ok THEN Fail ELSE
    LET marketParticipantState == ReadBytes(marketMakerMode.rest, 1) IN IF ~marketParticipantState.ok THEN Fail ELSE
    Ok([ stockLocate            |-> stockLocate.value,
         trackingNumber         |-> trackingNumber.value,
         timestamp              |-> timestamp.value,
         mpid                   |-> mpid.value,
         stock                  |-> stock.value,
         primaryMarketMaker     |-> primaryMarketMaker.value,
         marketMakerMode        |-> marketMakerMode.value,
         marketParticipantState |-> marketParticipantState.value ], marketParticipantState.rest)

ZeroMarketParticipantPositionMessage ==
    [ stockLocate            |-> [i \in 1 .. 2 |-> 0],
      trackingNumber         |-> [i \in 1 .. 2 |-> 0],
      timestamp              |-> [i \in 1 .. 6 |-> 0],
      mpid                   |-> [i \in 1 .. 4 |-> 0],
      stock                  |-> [i \in 1 .. 8 |-> 0],
      primaryMarketMaker     |-> [i \in 1 .. 1 |-> 0],
      marketMakerMode        |-> [i \in 1 .. 1 |-> 0],
      marketParticipantState |-> [i \in 1 .. 1 |-> 0] ]

(* Market Participant Position Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketParticipantPositionMessage ==
    { ZeroMarketParticipantPositionMessage }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.mpid = one] : one \in Sample(4) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.primaryMarketMaker = one] : one \in Sample(1) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.marketMakerMode = one] : one \in Sample(1) }
        \cup { [ZeroMarketParticipantPositionMessage EXCEPT !.marketParticipantState = one] : one \in Sample(1) }

(***************************************************************************)
(* Mwcb Decline Level Message: 34 bytes                                    *)
(***************************************************************************)

MwcbDeclineLevelMessage ==
    [ stockLocate    : Sample(2),
      trackingNumber : Sample(2),
      timestamp      : Sample(6),
      level1         : Sample(8),
      level2         : Sample(8),
      level3         : Sample(8) ]

EncodeMwcbDeclineLevelMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.level1
        \o message.level2
        \o message.level3

DecodeMwcbDeclineLevelMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET level1 == ReadBytes(timestamp.rest, 8) IN IF ~level1.ok THEN Fail ELSE
    LET level2 == ReadBytes(level1.rest, 8) IN IF ~level2.ok THEN Fail ELSE
    LET level3 == ReadBytes(level2.rest, 8) IN IF ~level3.ok THEN Fail ELSE
    Ok([ stockLocate    |-> stockLocate.value,
         trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         level1         |-> level1.value,
         level2         |-> level2.value,
         level3         |-> level3.value ], level3.rest)

ZeroMwcbDeclineLevelMessage ==
    [ stockLocate    |-> [i \in 1 .. 2 |-> 0],
      trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      level1         |-> [i \in 1 .. 8 |-> 0],
      level2         |-> [i \in 1 .. 8 |-> 0],
      level3         |-> [i \in 1 .. 8 |-> 0] ]

(* Mwcb Decline Level Message at zero, then each field in turn at the values it is checked at *)
CheckedMwcbDeclineLevelMessage ==
    { ZeroMwcbDeclineLevelMessage }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level1 = one] : one \in Sample(8) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level2 = one] : one \in Sample(8) }
        \cup { [ZeroMwcbDeclineLevelMessage EXCEPT !.level3 = one] : one \in Sample(8) }

(***************************************************************************)
(* Mwcb Status Level Message: 11 bytes                                     *)
(***************************************************************************)

MwcbStatusLevelMessage ==
    [ stockLocate    : Sample(2),
      trackingNumber : Sample(2),
      timestamp      : Sample(6),
      breachedLevel  : Sample(1) ]

EncodeMwcbStatusLevelMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.breachedLevel

DecodeMwcbStatusLevelMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET breachedLevel == ReadBytes(timestamp.rest, 1) IN IF ~breachedLevel.ok THEN Fail ELSE
    Ok([ stockLocate    |-> stockLocate.value,
         trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         breachedLevel  |-> breachedLevel.value ], breachedLevel.rest)

ZeroMwcbStatusLevelMessage ==
    [ stockLocate    |-> [i \in 1 .. 2 |-> 0],
      trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      breachedLevel  |-> [i \in 1 .. 1 |-> 0] ]

(* Mwcb Status Level Message at zero, then each field in turn at the values it is checked at *)
CheckedMwcbStatusLevelMessage ==
    { ZeroMwcbStatusLevelMessage }
        \cup { [ZeroMwcbStatusLevelMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroMwcbStatusLevelMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroMwcbStatusLevelMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroMwcbStatusLevelMessage EXCEPT !.breachedLevel = one] : one \in Sample(1) }

(***************************************************************************)
(* Ipo Quoting Period Update: 27 bytes                                     *)
(***************************************************************************)

IpoQuotingPeriodUpdate ==
    [ stockLocate                  : Sample(2),
      trackingNumber               : Sample(2),
      timestamp                    : Sample(6),
      stock                        : Sample(8),
      ipoQuotationReleaseTime      : Sample(4),
      ipoQuotationReleaseQualifier : Sample(1),
      ipoPrice                     : Sample(4) ]

EncodeIpoQuotingPeriodUpdate(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.stock
        \o message.ipoQuotationReleaseTime
        \o message.ipoQuotationReleaseQualifier
        \o message.ipoPrice

DecodeIpoQuotingPeriodUpdate(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET ipoQuotationReleaseTime == ReadBytes(stock.rest, 4) IN IF ~ipoQuotationReleaseTime.ok THEN Fail ELSE
    LET ipoQuotationReleaseQualifier == ReadBytes(ipoQuotationReleaseTime.rest, 1) IN IF ~ipoQuotationReleaseQualifier.ok THEN Fail ELSE
    LET ipoPrice == ReadBytes(ipoQuotationReleaseQualifier.rest, 4) IN IF ~ipoPrice.ok THEN Fail ELSE
    Ok([ stockLocate                  |-> stockLocate.value,
         trackingNumber               |-> trackingNumber.value,
         timestamp                    |-> timestamp.value,
         stock                        |-> stock.value,
         ipoQuotationReleaseTime      |-> ipoQuotationReleaseTime.value,
         ipoQuotationReleaseQualifier |-> ipoQuotationReleaseQualifier.value,
         ipoPrice                     |-> ipoPrice.value ], ipoPrice.rest)

ZeroIpoQuotingPeriodUpdate ==
    [ stockLocate                  |-> [i \in 1 .. 2 |-> 0],
      trackingNumber               |-> [i \in 1 .. 2 |-> 0],
      timestamp                    |-> [i \in 1 .. 6 |-> 0],
      stock                        |-> [i \in 1 .. 8 |-> 0],
      ipoQuotationReleaseTime      |-> [i \in 1 .. 4 |-> 0],
      ipoQuotationReleaseQualifier |-> [i \in 1 .. 1 |-> 0],
      ipoPrice                     |-> [i \in 1 .. 4 |-> 0] ]

(* Ipo Quoting Period Update at zero, then each field in turn at the values it is checked at *)
CheckedIpoQuotingPeriodUpdate ==
    { ZeroIpoQuotingPeriodUpdate }
        \cup { [ZeroIpoQuotingPeriodUpdate EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroIpoQuotingPeriodUpdate EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroIpoQuotingPeriodUpdate EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroIpoQuotingPeriodUpdate EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroIpoQuotingPeriodUpdate EXCEPT !.ipoQuotationReleaseTime = one] : one \in Sample(4) }
        \cup { [ZeroIpoQuotingPeriodUpdate EXCEPT !.ipoQuotationReleaseQualifier = one] : one \in Sample(1) }
        \cup { [ZeroIpoQuotingPeriodUpdate EXCEPT !.ipoPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Luld Auction Collar Message: 34 bytes                                   *)
(***************************************************************************)

LuldAuctionCollarMessage ==
    [ stockLocate                 : Sample(2),
      trackingNumber              : Sample(2),
      timestamp                   : Sample(6),
      stock                       : Sample(8),
      auctionCollarReferencePrice : Sample(4),
      upperAuctionCollarPrice     : Sample(4),
      lowerAuctionCollarPrice     : Sample(4),
      auctionCollarExtension      : Sample(4) ]

EncodeLuldAuctionCollarMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.stock
        \o message.auctionCollarReferencePrice
        \o message.upperAuctionCollarPrice
        \o message.lowerAuctionCollarPrice
        \o message.auctionCollarExtension

DecodeLuldAuctionCollarMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET auctionCollarReferencePrice == ReadBytes(stock.rest, 4) IN IF ~auctionCollarReferencePrice.ok THEN Fail ELSE
    LET upperAuctionCollarPrice == ReadBytes(auctionCollarReferencePrice.rest, 4) IN IF ~upperAuctionCollarPrice.ok THEN Fail ELSE
    LET lowerAuctionCollarPrice == ReadBytes(upperAuctionCollarPrice.rest, 4) IN IF ~lowerAuctionCollarPrice.ok THEN Fail ELSE
    LET auctionCollarExtension == ReadBytes(lowerAuctionCollarPrice.rest, 4) IN IF ~auctionCollarExtension.ok THEN Fail ELSE
    Ok([ stockLocate                 |-> stockLocate.value,
         trackingNumber              |-> trackingNumber.value,
         timestamp                   |-> timestamp.value,
         stock                       |-> stock.value,
         auctionCollarReferencePrice |-> auctionCollarReferencePrice.value,
         upperAuctionCollarPrice     |-> upperAuctionCollarPrice.value,
         lowerAuctionCollarPrice     |-> lowerAuctionCollarPrice.value,
         auctionCollarExtension      |-> auctionCollarExtension.value ], auctionCollarExtension.rest)

ZeroLuldAuctionCollarMessage ==
    [ stockLocate                 |-> [i \in 1 .. 2 |-> 0],
      trackingNumber              |-> [i \in 1 .. 2 |-> 0],
      timestamp                   |-> [i \in 1 .. 6 |-> 0],
      stock                       |-> [i \in 1 .. 8 |-> 0],
      auctionCollarReferencePrice |-> [i \in 1 .. 4 |-> 0],
      upperAuctionCollarPrice     |-> [i \in 1 .. 4 |-> 0],
      lowerAuctionCollarPrice     |-> [i \in 1 .. 4 |-> 0],
      auctionCollarExtension      |-> [i \in 1 .. 4 |-> 0] ]

(* Luld Auction Collar Message at zero, then each field in turn at the values it is checked at *)
CheckedLuldAuctionCollarMessage ==
    { ZeroLuldAuctionCollarMessage }
        \cup { [ZeroLuldAuctionCollarMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroLuldAuctionCollarMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroLuldAuctionCollarMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroLuldAuctionCollarMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroLuldAuctionCollarMessage EXCEPT !.auctionCollarReferencePrice = one] : one \in Sample(4) }
        \cup { [ZeroLuldAuctionCollarMessage EXCEPT !.upperAuctionCollarPrice = one] : one \in Sample(4) }
        \cup { [ZeroLuldAuctionCollarMessage EXCEPT !.lowerAuctionCollarPrice = one] : one \in Sample(4) }
        \cup { [ZeroLuldAuctionCollarMessage EXCEPT !.auctionCollarExtension = one] : one \in Sample(4) }

(***************************************************************************)
(* Operational Halt Message: 20 bytes                                      *)
(***************************************************************************)

OperationalHaltMessage ==
    [ stockLocate           : Sample(2),
      trackingNumber        : Sample(2),
      timestamp             : Sample(6),
      stock                 : Sample(8),
      marketCode            : Sample(1),
      operationalHaltAction : Sample(1) ]

EncodeOperationalHaltMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.stock
        \o message.marketCode
        \o message.operationalHaltAction

DecodeOperationalHaltMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET marketCode == ReadBytes(stock.rest, 1) IN IF ~marketCode.ok THEN Fail ELSE
    LET operationalHaltAction == ReadBytes(marketCode.rest, 1) IN IF ~operationalHaltAction.ok THEN Fail ELSE
    Ok([ stockLocate           |-> stockLocate.value,
         trackingNumber        |-> trackingNumber.value,
         timestamp             |-> timestamp.value,
         stock                 |-> stock.value,
         marketCode            |-> marketCode.value,
         operationalHaltAction |-> operationalHaltAction.value ], operationalHaltAction.rest)

ZeroOperationalHaltMessage ==
    [ stockLocate           |-> [i \in 1 .. 2 |-> 0],
      trackingNumber        |-> [i \in 1 .. 2 |-> 0],
      timestamp             |-> [i \in 1 .. 6 |-> 0],
      stock                 |-> [i \in 1 .. 8 |-> 0],
      marketCode            |-> [i \in 1 .. 1 |-> 0],
      operationalHaltAction |-> [i \in 1 .. 1 |-> 0] ]

(* Operational Halt Message at zero, then each field in turn at the values it is checked at *)
CheckedOperationalHaltMessage ==
    { ZeroOperationalHaltMessage }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.marketCode = one] : one \in Sample(1) }
        \cup { [ZeroOperationalHaltMessage EXCEPT !.operationalHaltAction = one] : one \in Sample(1) }

(***************************************************************************)
(* Add Order No Mpid Attribution Message: 35 bytes                         *)
(***************************************************************************)

AddOrderNoMpidAttributionMessage ==
    [ stockLocate          : Sample(2),
      trackingNumber       : Sample(2),
      timestamp            : Sample(6),
      orderReferenceNumber : Sample(8),
      buySellIndicator     : Sample(1),
      shares               : Sample(4),
      stock                : Sample(8),
      price                : Sample(4) ]

EncodeAddOrderNoMpidAttributionMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.buySellIndicator
        \o message.shares
        \o message.stock
        \o message.price

DecodeAddOrderNoMpidAttributionMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET shares == ReadBytes(buySellIndicator.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET stock == ReadBytes(shares.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET price == ReadBytes(stock.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ stockLocate          |-> stockLocate.value,
         trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         buySellIndicator     |-> buySellIndicator.value,
         shares               |-> shares.value,
         stock                |-> stock.value,
         price                |-> price.value ], price.rest)

ZeroAddOrderNoMpidAttributionMessage ==
    [ stockLocate          |-> [i \in 1 .. 2 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 6 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      shares               |-> [i \in 1 .. 4 |-> 0],
      stock                |-> [i \in 1 .. 8 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order No Mpid Attribution Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderNoMpidAttributionMessage ==
    { ZeroAddOrderNoMpidAttributionMessage }
        \cup { [ZeroAddOrderNoMpidAttributionMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderNoMpidAttributionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderNoMpidAttributionMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderNoMpidAttributionMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderNoMpidAttributionMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderNoMpidAttributionMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderNoMpidAttributionMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderNoMpidAttributionMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Add Order With Mpid Attribution Message: 39 bytes                       *)
(***************************************************************************)

AddOrderWithMpidAttributionMessage ==
    [ stockLocate          : Sample(2),
      trackingNumber       : Sample(2),
      timestamp            : Sample(6),
      orderReferenceNumber : Sample(8),
      buySellIndicator     : Sample(1),
      shares               : Sample(4),
      stock                : Sample(8),
      price                : Sample(4),
      attribution          : Sample(4) ]

EncodeAddOrderWithMpidAttributionMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.buySellIndicator
        \o message.shares
        \o message.stock
        \o message.price
        \o message.attribution

DecodeAddOrderWithMpidAttributionMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET shares == ReadBytes(buySellIndicator.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET stock == ReadBytes(shares.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET price == ReadBytes(stock.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET attribution == ReadBytes(price.rest, 4) IN IF ~attribution.ok THEN Fail ELSE
    Ok([ stockLocate          |-> stockLocate.value,
         trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         buySellIndicator     |-> buySellIndicator.value,
         shares               |-> shares.value,
         stock                |-> stock.value,
         price                |-> price.value,
         attribution          |-> attribution.value ], attribution.rest)

ZeroAddOrderWithMpidAttributionMessage ==
    [ stockLocate          |-> [i \in 1 .. 2 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 6 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      shares               |-> [i \in 1 .. 4 |-> 0],
      stock                |-> [i \in 1 .. 8 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      attribution          |-> [i \in 1 .. 4 |-> 0] ]

(* Add Order With Mpid Attribution Message at zero, then each field in turn at the values it is checked at *)
CheckedAddOrderWithMpidAttributionMessage ==
    { ZeroAddOrderWithMpidAttributionMessage }
        \cup { [ZeroAddOrderWithMpidAttributionMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderWithMpidAttributionMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroAddOrderWithMpidAttributionMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroAddOrderWithMpidAttributionMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderWithMpidAttributionMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAddOrderWithMpidAttributionMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpidAttributionMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroAddOrderWithMpidAttributionMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroAddOrderWithMpidAttributionMessage EXCEPT !.attribution = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Executed Message: 30 bytes                                        *)
(***************************************************************************)

OrderExecutedMessage ==
    [ stockLocate          : Sample(2),
      trackingNumber       : Sample(2),
      timestamp            : Sample(6),
      orderReferenceNumber : Sample(8),
      executedShares       : Sample(4),
      matchNumber          : Sample(8) ]

EncodeOrderExecutedMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.executedShares
        \o message.matchNumber

DecodeOrderExecutedMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET executedShares == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~executedShares.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedShares.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ stockLocate          |-> stockLocate.value,
         trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         executedShares       |-> executedShares.value,
         matchNumber          |-> matchNumber.value ], matchNumber.rest)

ZeroOrderExecutedMessage ==
    [ stockLocate          |-> [i \in 1 .. 2 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 6 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      executedShares       |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 8 |-> 0] ]

(* Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedMessage ==
    { ZeroOrderExecutedMessage }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.executedShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Executed With Price Message: 35 bytes                             *)
(***************************************************************************)

OrderExecutedWithPriceMessage ==
    [ stockLocate          : Sample(2),
      trackingNumber       : Sample(2),
      timestamp            : Sample(6),
      orderReferenceNumber : Sample(8),
      executedShares       : Sample(4),
      matchNumber          : Sample(8),
      printable            : Sample(1),
      executionPrice       : Sample(4) ]

EncodeOrderExecutedWithPriceMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.executedShares
        \o message.matchNumber
        \o message.printable
        \o message.executionPrice

DecodeOrderExecutedWithPriceMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET executedShares == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~executedShares.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(executedShares.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET printable == ReadBytes(matchNumber.rest, 1) IN IF ~printable.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(printable.rest, 4) IN IF ~executionPrice.ok THEN Fail ELSE
    Ok([ stockLocate          |-> stockLocate.value,
         trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         executedShares       |-> executedShares.value,
         matchNumber          |-> matchNumber.value,
         printable            |-> printable.value,
         executionPrice       |-> executionPrice.value ], executionPrice.rest)

ZeroOrderExecutedWithPriceMessage ==
    [ stockLocate          |-> [i \in 1 .. 2 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 6 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      executedShares       |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 8 |-> 0],
      printable            |-> [i \in 1 .. 1 |-> 0],
      executionPrice       |-> [i \in 1 .. 4 |-> 0] ]

(* Order Executed With Price Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderExecutedWithPriceMessage ==
    { ZeroOrderExecutedWithPriceMessage }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executedShares = one] : one \in Sample(4) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.printable = one] : one \in Sample(1) }
        \cup { [ZeroOrderExecutedWithPriceMessage EXCEPT !.executionPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Message: 22 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ stockLocate          : Sample(2),
      trackingNumber       : Sample(2),
      timestamp            : Sample(6),
      orderReferenceNumber : Sample(8),
      canceledShares       : Sample(4) ]

EncodeOrderCancelMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.canceledShares

DecodeOrderCancelMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET canceledShares == ReadBytes(orderReferenceNumber.rest, 4) IN IF ~canceledShares.ok THEN Fail ELSE
    Ok([ stockLocate          |-> stockLocate.value,
         trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         canceledShares       |-> canceledShares.value ], canceledShares.rest)

ZeroOrderCancelMessage ==
    [ stockLocate          |-> [i \in 1 .. 2 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 6 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      canceledShares       |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.canceledShares = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Delete Message: 18 bytes                                          *)
(***************************************************************************)

OrderDeleteMessage ==
    [ stockLocate          : Sample(2),
      trackingNumber       : Sample(2),
      timestamp            : Sample(6),
      orderReferenceNumber : Sample(8) ]

EncodeOrderDeleteMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.orderReferenceNumber

DecodeOrderDeleteMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    Ok([ stockLocate          |-> stockLocate.value,
         trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value ], orderReferenceNumber.rest)

ZeroOrderDeleteMessage ==
    [ stockLocate          |-> [i \in 1 .. 2 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 6 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Order Delete Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderDeleteMessage ==
    { ZeroOrderDeleteMessage }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOrderDeleteMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Replace Message: 34 bytes                                         *)
(***************************************************************************)

OrderReplaceMessage ==
    [ stockLocate                  : Sample(2),
      trackingNumber               : Sample(2),
      timestamp                    : Sample(6),
      originalOrderReferenceNumber : Sample(8),
      newOrderReferenceNumber      : Sample(8),
      shares                       : Sample(4),
      price                        : Sample(4) ]

EncodeOrderReplaceMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.originalOrderReferenceNumber
        \o message.newOrderReferenceNumber
        \o message.shares
        \o message.price

DecodeOrderReplaceMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET originalOrderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~originalOrderReferenceNumber.ok THEN Fail ELSE
    LET newOrderReferenceNumber == ReadBytes(originalOrderReferenceNumber.rest, 8) IN IF ~newOrderReferenceNumber.ok THEN Fail ELSE
    LET shares == ReadBytes(newOrderReferenceNumber.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET price == ReadBytes(shares.rest, 4) IN IF ~price.ok THEN Fail ELSE
    Ok([ stockLocate                  |-> stockLocate.value,
         trackingNumber               |-> trackingNumber.value,
         timestamp                    |-> timestamp.value,
         originalOrderReferenceNumber |-> originalOrderReferenceNumber.value,
         newOrderReferenceNumber      |-> newOrderReferenceNumber.value,
         shares                       |-> shares.value,
         price                        |-> price.value ], price.rest)

ZeroOrderReplaceMessage ==
    [ stockLocate                  |-> [i \in 1 .. 2 |-> 0],
      trackingNumber               |-> [i \in 1 .. 2 |-> 0],
      timestamp                    |-> [i \in 1 .. 6 |-> 0],
      originalOrderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      newOrderReferenceNumber      |-> [i \in 1 .. 8 |-> 0],
      shares                       |-> [i \in 1 .. 4 |-> 0],
      price                        |-> [i \in 1 .. 4 |-> 0] ]

(* Order Replace Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplaceMessage ==
    { ZeroOrderReplaceMessage }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.originalOrderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.newOrderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplaceMessage EXCEPT !.price = one] : one \in Sample(4) }

(***************************************************************************)
(* Non Cross Trade Message: 43 bytes                                       *)
(***************************************************************************)

NonCrossTradeMessage ==
    [ stockLocate          : Sample(2),
      trackingNumber       : Sample(2),
      timestamp            : Sample(6),
      orderReferenceNumber : Sample(8),
      buySellIndicator     : Sample(1),
      shares               : Sample(4),
      stock                : Sample(8),
      price                : Sample(4),
      matchNumber          : Sample(8) ]

EncodeNonCrossTradeMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.orderReferenceNumber
        \o message.buySellIndicator
        \o message.shares
        \o message.stock
        \o message.price
        \o message.matchNumber

DecodeNonCrossTradeMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(timestamp.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET shares == ReadBytes(buySellIndicator.rest, 4) IN IF ~shares.ok THEN Fail ELSE
    LET stock == ReadBytes(shares.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET price == ReadBytes(stock.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(price.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ stockLocate          |-> stockLocate.value,
         trackingNumber       |-> trackingNumber.value,
         timestamp            |-> timestamp.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         buySellIndicator     |-> buySellIndicator.value,
         shares               |-> shares.value,
         stock                |-> stock.value,
         price                |-> price.value,
         matchNumber          |-> matchNumber.value ], matchNumber.rest)

ZeroNonCrossTradeMessage ==
    [ stockLocate          |-> [i \in 1 .. 2 |-> 0],
      trackingNumber       |-> [i \in 1 .. 2 |-> 0],
      timestamp            |-> [i \in 1 .. 6 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      shares               |-> [i \in 1 .. 4 |-> 0],
      stock                |-> [i \in 1 .. 8 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      matchNumber          |-> [i \in 1 .. 8 |-> 0] ]

(* Non Cross Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedNonCrossTradeMessage ==
    { ZeroNonCrossTradeMessage }
        \cup { [ZeroNonCrossTradeMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroNonCrossTradeMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroNonCrossTradeMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroNonCrossTradeMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroNonCrossTradeMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNonCrossTradeMessage EXCEPT !.shares = one] : one \in Sample(4) }
        \cup { [ZeroNonCrossTradeMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroNonCrossTradeMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroNonCrossTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Cross Trade Message: 39 bytes                                           *)
(***************************************************************************)

CrossTradeMessage ==
    [ stockLocate    : Sample(2),
      trackingNumber : Sample(2),
      timestamp      : Sample(6),
      crossShares    : Sample(8),
      stock          : Sample(8),
      crossPrice     : Sample(4),
      matchNumber    : Sample(8),
      crossType      : Sample(1) ]

EncodeCrossTradeMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.crossShares
        \o message.stock
        \o message.crossPrice
        \o message.matchNumber
        \o message.crossType

DecodeCrossTradeMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET crossShares == ReadBytes(timestamp.rest, 8) IN IF ~crossShares.ok THEN Fail ELSE
    LET stock == ReadBytes(crossShares.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET crossPrice == ReadBytes(stock.rest, 4) IN IF ~crossPrice.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(crossPrice.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    LET crossType == ReadBytes(matchNumber.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    Ok([ stockLocate    |-> stockLocate.value,
         trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         crossShares    |-> crossShares.value,
         stock          |-> stock.value,
         crossPrice     |-> crossPrice.value,
         matchNumber    |-> matchNumber.value,
         crossType      |-> crossType.value ], crossType.rest)

ZeroCrossTradeMessage ==
    [ stockLocate    |-> [i \in 1 .. 2 |-> 0],
      trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      crossShares    |-> [i \in 1 .. 8 |-> 0],
      stock          |-> [i \in 1 .. 8 |-> 0],
      crossPrice     |-> [i \in 1 .. 4 |-> 0],
      matchNumber    |-> [i \in 1 .. 8 |-> 0],
      crossType      |-> [i \in 1 .. 1 |-> 0] ]

(* Cross Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossTradeMessage ==
    { ZeroCrossTradeMessage }
        \cup { [ZeroCrossTradeMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.crossShares = one] : one \in Sample(8) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.crossPrice = one] : one \in Sample(4) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }
        \cup { [ZeroCrossTradeMessage EXCEPT !.crossType = one] : one \in Sample(1) }

(***************************************************************************)
(* Broken Trade Message: 18 bytes                                          *)
(***************************************************************************)

BrokenTradeMessage ==
    [ stockLocate    : Sample(2),
      trackingNumber : Sample(2),
      timestamp      : Sample(6),
      matchNumber    : Sample(8) ]

EncodeBrokenTradeMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.matchNumber

DecodeBrokenTradeMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(timestamp.rest, 8) IN IF ~matchNumber.ok THEN Fail ELSE
    Ok([ stockLocate    |-> stockLocate.value,
         trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         matchNumber    |-> matchNumber.value ], matchNumber.rest)

ZeroBrokenTradeMessage ==
    [ stockLocate    |-> [i \in 1 .. 2 |-> 0],
      trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      matchNumber    |-> [i \in 1 .. 8 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Net Order Imbalance Indicator Message: 49 bytes                         *)
(***************************************************************************)

NetOrderImbalanceIndicatorMessage ==
    [ stockLocate             : Sample(2),
      trackingNumber          : Sample(2),
      timestamp               : Sample(6),
      pairedShares            : Sample(8),
      imbalanceShares         : Sample(8),
      imbalanceDirection      : Sample(1),
      stock                   : Sample(8),
      farPrice                : Sample(4),
      nearPrice               : Sample(4),
      currentReferencePrice   : Sample(4),
      crossType               : Sample(1),
      priceVariationIndicator : Sample(1) ]

EncodeNetOrderImbalanceIndicatorMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.pairedShares
        \o message.imbalanceShares
        \o message.imbalanceDirection
        \o message.stock
        \o message.farPrice
        \o message.nearPrice
        \o message.currentReferencePrice
        \o message.crossType
        \o message.priceVariationIndicator

DecodeNetOrderImbalanceIndicatorMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET pairedShares == ReadBytes(timestamp.rest, 8) IN IF ~pairedShares.ok THEN Fail ELSE
    LET imbalanceShares == ReadBytes(pairedShares.rest, 8) IN IF ~imbalanceShares.ok THEN Fail ELSE
    LET imbalanceDirection == ReadBytes(imbalanceShares.rest, 1) IN IF ~imbalanceDirection.ok THEN Fail ELSE
    LET stock == ReadBytes(imbalanceDirection.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET farPrice == ReadBytes(stock.rest, 4) IN IF ~farPrice.ok THEN Fail ELSE
    LET nearPrice == ReadBytes(farPrice.rest, 4) IN IF ~nearPrice.ok THEN Fail ELSE
    LET currentReferencePrice == ReadBytes(nearPrice.rest, 4) IN IF ~currentReferencePrice.ok THEN Fail ELSE
    LET crossType == ReadBytes(currentReferencePrice.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET priceVariationIndicator == ReadBytes(crossType.rest, 1) IN IF ~priceVariationIndicator.ok THEN Fail ELSE
    Ok([ stockLocate             |-> stockLocate.value,
         trackingNumber          |-> trackingNumber.value,
         timestamp               |-> timestamp.value,
         pairedShares            |-> pairedShares.value,
         imbalanceShares         |-> imbalanceShares.value,
         imbalanceDirection      |-> imbalanceDirection.value,
         stock                   |-> stock.value,
         farPrice                |-> farPrice.value,
         nearPrice               |-> nearPrice.value,
         currentReferencePrice   |-> currentReferencePrice.value,
         crossType               |-> crossType.value,
         priceVariationIndicator |-> priceVariationIndicator.value ], priceVariationIndicator.rest)

ZeroNetOrderImbalanceIndicatorMessage ==
    [ stockLocate             |-> [i \in 1 .. 2 |-> 0],
      trackingNumber          |-> [i \in 1 .. 2 |-> 0],
      timestamp               |-> [i \in 1 .. 6 |-> 0],
      pairedShares            |-> [i \in 1 .. 8 |-> 0],
      imbalanceShares         |-> [i \in 1 .. 8 |-> 0],
      imbalanceDirection      |-> [i \in 1 .. 1 |-> 0],
      stock                   |-> [i \in 1 .. 8 |-> 0],
      farPrice                |-> [i \in 1 .. 4 |-> 0],
      nearPrice               |-> [i \in 1 .. 4 |-> 0],
      currentReferencePrice   |-> [i \in 1 .. 4 |-> 0],
      crossType               |-> [i \in 1 .. 1 |-> 0],
      priceVariationIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Net Order Imbalance Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedNetOrderImbalanceIndicatorMessage ==
    { ZeroNetOrderImbalanceIndicatorMessage }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.pairedShares = one] : one \in Sample(8) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.imbalanceShares = one] : one \in Sample(8) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.imbalanceDirection = one] : one \in Sample(1) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.farPrice = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.nearPrice = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.currentReferencePrice = one] : one \in Sample(4) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroNetOrderImbalanceIndicatorMessage EXCEPT !.priceVariationIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Retail Price Improvement Indicator Message: 19 bytes                    *)
(***************************************************************************)

RetailPriceImprovementIndicatorMessage ==
    [ stockLocate    : Sample(2),
      trackingNumber : Sample(2),
      timestamp      : Sample(6),
      stock          : Sample(8),
      interestFlag   : Sample(1) ]

EncodeRetailPriceImprovementIndicatorMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.stock
        \o message.interestFlag

DecodeRetailPriceImprovementIndicatorMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET interestFlag == ReadBytes(stock.rest, 1) IN IF ~interestFlag.ok THEN Fail ELSE
    Ok([ stockLocate    |-> stockLocate.value,
         trackingNumber |-> trackingNumber.value,
         timestamp      |-> timestamp.value,
         stock          |-> stock.value,
         interestFlag   |-> interestFlag.value ], interestFlag.rest)

ZeroRetailPriceImprovementIndicatorMessage ==
    [ stockLocate    |-> [i \in 1 .. 2 |-> 0],
      trackingNumber |-> [i \in 1 .. 2 |-> 0],
      timestamp      |-> [i \in 1 .. 6 |-> 0],
      stock          |-> [i \in 1 .. 8 |-> 0],
      interestFlag   |-> [i \in 1 .. 1 |-> 0] ]

(* Retail Price Improvement Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedRetailPriceImprovementIndicatorMessage ==
    { ZeroRetailPriceImprovementIndicatorMessage }
        \cup { [ZeroRetailPriceImprovementIndicatorMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroRetailPriceImprovementIndicatorMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroRetailPriceImprovementIndicatorMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroRetailPriceImprovementIndicatorMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroRetailPriceImprovementIndicatorMessage EXCEPT !.interestFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Direct Listing With Capital Raise Price Discovery Message: 47 bytes     *)
(***************************************************************************)

DirectListingWithCapitalRaisePriceDiscoveryMessage ==
    [ stockLocate           : Sample(2),
      trackingNumber        : Sample(2),
      timestamp             : Sample(6),
      stock                 : Sample(8),
      openEligibilityStatus : Sample(1),
      minimumAllowablePrice : Sample(4),
      maximumAllowablePrice : Sample(4),
      nearExecutionPrice    : Sample(4),
      nearExecutionTime     : Sample(8),
      lowerPriceRangeCollar : Sample(4),
      upperPriceRangeCollar : Sample(4) ]

EncodeDirectListingWithCapitalRaisePriceDiscoveryMessage(message) ==
    message.stockLocate
        \o message.trackingNumber
        \o message.timestamp
        \o message.stock
        \o message.openEligibilityStatus
        \o message.minimumAllowablePrice
        \o message.maximumAllowablePrice
        \o message.nearExecutionPrice
        \o message.nearExecutionTime
        \o message.lowerPriceRangeCollar
        \o message.upperPriceRangeCollar

DecodeDirectListingWithCapitalRaisePriceDiscoveryMessage(bytes) ==
    LET stockLocate == ReadBytes(bytes, 2) IN IF ~stockLocate.ok THEN Fail ELSE
    LET trackingNumber == ReadBytes(stockLocate.rest, 2) IN IF ~trackingNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(trackingNumber.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET stock == ReadBytes(timestamp.rest, 8) IN IF ~stock.ok THEN Fail ELSE
    LET openEligibilityStatus == ReadBytes(stock.rest, 1) IN IF ~openEligibilityStatus.ok THEN Fail ELSE
    LET minimumAllowablePrice == ReadBytes(openEligibilityStatus.rest, 4) IN IF ~minimumAllowablePrice.ok THEN Fail ELSE
    LET maximumAllowablePrice == ReadBytes(minimumAllowablePrice.rest, 4) IN IF ~maximumAllowablePrice.ok THEN Fail ELSE
    LET nearExecutionPrice == ReadBytes(maximumAllowablePrice.rest, 4) IN IF ~nearExecutionPrice.ok THEN Fail ELSE
    LET nearExecutionTime == ReadBytes(nearExecutionPrice.rest, 8) IN IF ~nearExecutionTime.ok THEN Fail ELSE
    LET lowerPriceRangeCollar == ReadBytes(nearExecutionTime.rest, 4) IN IF ~lowerPriceRangeCollar.ok THEN Fail ELSE
    LET upperPriceRangeCollar == ReadBytes(lowerPriceRangeCollar.rest, 4) IN IF ~upperPriceRangeCollar.ok THEN Fail ELSE
    Ok([ stockLocate           |-> stockLocate.value,
         trackingNumber        |-> trackingNumber.value,
         timestamp             |-> timestamp.value,
         stock                 |-> stock.value,
         openEligibilityStatus |-> openEligibilityStatus.value,
         minimumAllowablePrice |-> minimumAllowablePrice.value,
         maximumAllowablePrice |-> maximumAllowablePrice.value,
         nearExecutionPrice    |-> nearExecutionPrice.value,
         nearExecutionTime     |-> nearExecutionTime.value,
         lowerPriceRangeCollar |-> lowerPriceRangeCollar.value,
         upperPriceRangeCollar |-> upperPriceRangeCollar.value ], upperPriceRangeCollar.rest)

ZeroDirectListingWithCapitalRaisePriceDiscoveryMessage ==
    [ stockLocate           |-> [i \in 1 .. 2 |-> 0],
      trackingNumber        |-> [i \in 1 .. 2 |-> 0],
      timestamp             |-> [i \in 1 .. 6 |-> 0],
      stock                 |-> [i \in 1 .. 8 |-> 0],
      openEligibilityStatus |-> [i \in 1 .. 1 |-> 0],
      minimumAllowablePrice |-> [i \in 1 .. 4 |-> 0],
      maximumAllowablePrice |-> [i \in 1 .. 4 |-> 0],
      nearExecutionPrice    |-> [i \in 1 .. 4 |-> 0],
      nearExecutionTime     |-> [i \in 1 .. 8 |-> 0],
      lowerPriceRangeCollar |-> [i \in 1 .. 4 |-> 0],
      upperPriceRangeCollar |-> [i \in 1 .. 4 |-> 0] ]

(* Direct Listing With Capital Raise Price Discovery Message at zero, then each field in turn at the values it is checked at *)
CheckedDirectListingWithCapitalRaisePriceDiscoveryMessage ==
    { ZeroDirectListingWithCapitalRaisePriceDiscoveryMessage }
        \cup { [ZeroDirectListingWithCapitalRaisePriceDiscoveryMessage EXCEPT !.stockLocate = one] : one \in Sample(2) }
        \cup { [ZeroDirectListingWithCapitalRaisePriceDiscoveryMessage EXCEPT !.trackingNumber = one] : one \in Sample(2) }
        \cup { [ZeroDirectListingWithCapitalRaisePriceDiscoveryMessage EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroDirectListingWithCapitalRaisePriceDiscoveryMessage EXCEPT !.stock = one] : one \in Sample(8) }
        \cup { [ZeroDirectListingWithCapitalRaisePriceDiscoveryMessage EXCEPT !.openEligibilityStatus = one] : one \in Sample(1) }
        \cup { [ZeroDirectListingWithCapitalRaisePriceDiscoveryMessage EXCEPT !.minimumAllowablePrice = one] : one \in Sample(4) }
        \cup { [ZeroDirectListingWithCapitalRaisePriceDiscoveryMessage EXCEPT !.maximumAllowablePrice = one] : one \in Sample(4) }
        \cup { [ZeroDirectListingWithCapitalRaisePriceDiscoveryMessage EXCEPT !.nearExecutionPrice = one] : one \in Sample(4) }
        \cup { [ZeroDirectListingWithCapitalRaisePriceDiscoveryMessage EXCEPT !.nearExecutionTime = one] : one \in Sample(8) }
        \cup { [ZeroDirectListingWithCapitalRaisePriceDiscoveryMessage EXCEPT !.lowerPriceRangeCollar = one] : one \in Sample(4) }
        \cup { [ZeroDirectListingWithCapitalRaisePriceDiscoveryMessage EXCEPT !.upperPriceRangeCollar = one] : one \in Sample(4) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
StockDirectoryMessageCode == 82  \* "R"
StockTradingActionMessageCode == 72  \* "H"
RegShoShortSalePriceTestRestrictedIndicatorMessageCode == 89  \* "Y"
MarketParticipantPositionMessageCode == 76  \* "L"
MwcbDeclineLevelMessageCode == 86  \* "V"
MwcbStatusLevelMessageCode == 87  \* "W"
IpoQuotingPeriodUpdateCode == 75  \* "K"
LuldAuctionCollarMessageCode == 74  \* "J"
OperationalHaltMessageCode == 104  \* "h"
AddOrderNoMpidAttributionMessageCode == 65  \* "A"
AddOrderWithMpidAttributionMessageCode == 70  \* "F"
OrderExecutedMessageCode == 69  \* "E"
OrderExecutedWithPriceMessageCode == 67  \* "C"
OrderCancelMessageCode == 88  \* "X"
OrderDeleteMessageCode == 68  \* "D"
OrderReplaceMessageCode == 85  \* "U"
NonCrossTradeMessageCode == 80  \* "P"
CrossTradeMessageCode == 81  \* "Q"
BrokenTradeMessageCode == 66  \* "B"
NetOrderImbalanceIndicatorMessageCode == 73  \* "I"
RetailPriceImprovementIndicatorMessageCode == 78  \* "N"
DirectListingWithCapitalRaisePriceDiscoveryMessageCode == 79  \* "O"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {StockDirectoryMessageCode}, body : StockDirectoryMessage ]
        \cup [ tag : {StockTradingActionMessageCode}, body : StockTradingActionMessage ]
        \cup [ tag : {RegShoShortSalePriceTestRestrictedIndicatorMessageCode}, body : RegShoShortSalePriceTestRestrictedIndicatorMessage ]
        \cup [ tag : {MarketParticipantPositionMessageCode}, body : MarketParticipantPositionMessage ]
        \cup [ tag : {MwcbDeclineLevelMessageCode}, body : MwcbDeclineLevelMessage ]
        \cup [ tag : {MwcbStatusLevelMessageCode}, body : MwcbStatusLevelMessage ]
        \cup [ tag : {IpoQuotingPeriodUpdateCode}, body : IpoQuotingPeriodUpdate ]
        \cup [ tag : {LuldAuctionCollarMessageCode}, body : LuldAuctionCollarMessage ]
        \cup [ tag : {OperationalHaltMessageCode}, body : OperationalHaltMessage ]
        \cup [ tag : {AddOrderNoMpidAttributionMessageCode}, body : AddOrderNoMpidAttributionMessage ]
        \cup [ tag : {AddOrderWithMpidAttributionMessageCode}, body : AddOrderWithMpidAttributionMessage ]
        \cup [ tag : {OrderExecutedMessageCode}, body : OrderExecutedMessage ]
        \cup [ tag : {OrderExecutedWithPriceMessageCode}, body : OrderExecutedWithPriceMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {OrderDeleteMessageCode}, body : OrderDeleteMessage ]
        \cup [ tag : {OrderReplaceMessageCode}, body : OrderReplaceMessage ]
        \cup [ tag : {NonCrossTradeMessageCode}, body : NonCrossTradeMessage ]
        \cup [ tag : {CrossTradeMessageCode}, body : CrossTradeMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {NetOrderImbalanceIndicatorMessageCode}, body : NetOrderImbalanceIndicatorMessage ]
        \cup [ tag : {RetailPriceImprovementIndicatorMessageCode}, body : RetailPriceImprovementIndicatorMessage ]
        \cup [ tag : {DirectListingWithCapitalRaisePriceDiscoveryMessageCode}, body : DirectListingWithCapitalRaisePriceDiscoveryMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = StockDirectoryMessageCode -> EncodeStockDirectoryMessage(message.body)
      [] message.tag = StockTradingActionMessageCode -> EncodeStockTradingActionMessage(message.body)
      [] message.tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message.body)
      [] message.tag = MarketParticipantPositionMessageCode -> EncodeMarketParticipantPositionMessage(message.body)
      [] message.tag = MwcbDeclineLevelMessageCode -> EncodeMwcbDeclineLevelMessage(message.body)
      [] message.tag = MwcbStatusLevelMessageCode -> EncodeMwcbStatusLevelMessage(message.body)
      [] message.tag = IpoQuotingPeriodUpdateCode -> EncodeIpoQuotingPeriodUpdate(message.body)
      [] message.tag = LuldAuctionCollarMessageCode -> EncodeLuldAuctionCollarMessage(message.body)
      [] message.tag = OperationalHaltMessageCode -> EncodeOperationalHaltMessage(message.body)
      [] message.tag = AddOrderNoMpidAttributionMessageCode -> EncodeAddOrderNoMpidAttributionMessage(message.body)
      [] message.tag = AddOrderWithMpidAttributionMessageCode -> EncodeAddOrderWithMpidAttributionMessage(message.body)
      [] message.tag = OrderExecutedMessageCode -> EncodeOrderExecutedMessage(message.body)
      [] message.tag = OrderExecutedWithPriceMessageCode -> EncodeOrderExecutedWithPriceMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = OrderDeleteMessageCode -> EncodeOrderDeleteMessage(message.body)
      [] message.tag = OrderReplaceMessageCode -> EncodeOrderReplaceMessage(message.body)
      [] message.tag = NonCrossTradeMessageCode -> EncodeNonCrossTradeMessage(message.body)
      [] message.tag = CrossTradeMessageCode -> EncodeCrossTradeMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = NetOrderImbalanceIndicatorMessageCode -> EncodeNetOrderImbalanceIndicatorMessage(message.body)
      [] message.tag = RetailPriceImprovementIndicatorMessageCode -> EncodeRetailPriceImprovementIndicatorMessage(message.body)
      [] message.tag = DirectListingWithCapitalRaisePriceDiscoveryMessageCode -> EncodeDirectListingWithCapitalRaisePriceDiscoveryMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = StockDirectoryMessageCode -> DecodeStockDirectoryMessage(bytes)
              [] tag = StockTradingActionMessageCode -> DecodeStockTradingActionMessage(bytes)
              [] tag = RegShoShortSalePriceTestRestrictedIndicatorMessageCode -> DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(bytes)
              [] tag = MarketParticipantPositionMessageCode -> DecodeMarketParticipantPositionMessage(bytes)
              [] tag = MwcbDeclineLevelMessageCode -> DecodeMwcbDeclineLevelMessage(bytes)
              [] tag = MwcbStatusLevelMessageCode -> DecodeMwcbStatusLevelMessage(bytes)
              [] tag = IpoQuotingPeriodUpdateCode -> DecodeIpoQuotingPeriodUpdate(bytes)
              [] tag = LuldAuctionCollarMessageCode -> DecodeLuldAuctionCollarMessage(bytes)
              [] tag = OperationalHaltMessageCode -> DecodeOperationalHaltMessage(bytes)
              [] tag = AddOrderNoMpidAttributionMessageCode -> DecodeAddOrderNoMpidAttributionMessage(bytes)
              [] tag = AddOrderWithMpidAttributionMessageCode -> DecodeAddOrderWithMpidAttributionMessage(bytes)
              [] tag = OrderExecutedMessageCode -> DecodeOrderExecutedMessage(bytes)
              [] tag = OrderExecutedWithPriceMessageCode -> DecodeOrderExecutedWithPriceMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = OrderDeleteMessageCode -> DecodeOrderDeleteMessage(bytes)
              [] tag = OrderReplaceMessageCode -> DecodeOrderReplaceMessage(bytes)
              [] tag = NonCrossTradeMessageCode -> DecodeNonCrossTradeMessage(bytes)
              [] tag = CrossTradeMessageCode -> DecodeCrossTradeMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = NetOrderImbalanceIndicatorMessageCode -> DecodeNetOrderImbalanceIndicatorMessage(bytes)
              [] tag = RetailPriceImprovementIndicatorMessageCode -> DecodeRetailPriceImprovementIndicatorMessage(bytes)
              [] tag = DirectListingWithCapitalRaisePriceDiscoveryMessageCode -> DecodeDirectListingWithCapitalRaisePriceDiscoveryMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> StockDirectoryMessageCode, body |-> one] : one \in CheckedStockDirectoryMessage }
        \cup { [tag |-> StockTradingActionMessageCode, body |-> one] : one \in CheckedStockTradingActionMessage }
        \cup { [tag |-> RegShoShortSalePriceTestRestrictedIndicatorMessageCode, body |-> one] : one \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage }
        \cup { [tag |-> MarketParticipantPositionMessageCode, body |-> one] : one \in CheckedMarketParticipantPositionMessage }
        \cup { [tag |-> MwcbDeclineLevelMessageCode, body |-> one] : one \in CheckedMwcbDeclineLevelMessage }
        \cup { [tag |-> MwcbStatusLevelMessageCode, body |-> one] : one \in CheckedMwcbStatusLevelMessage }
        \cup { [tag |-> IpoQuotingPeriodUpdateCode, body |-> one] : one \in CheckedIpoQuotingPeriodUpdate }
        \cup { [tag |-> LuldAuctionCollarMessageCode, body |-> one] : one \in CheckedLuldAuctionCollarMessage }
        \cup { [tag |-> OperationalHaltMessageCode, body |-> one] : one \in CheckedOperationalHaltMessage }
        \cup { [tag |-> AddOrderNoMpidAttributionMessageCode, body |-> one] : one \in CheckedAddOrderNoMpidAttributionMessage }
        \cup { [tag |-> AddOrderWithMpidAttributionMessageCode, body |-> one] : one \in CheckedAddOrderWithMpidAttributionMessage }
        \cup { [tag |-> OrderExecutedMessageCode, body |-> one] : one \in CheckedOrderExecutedMessage }
        \cup { [tag |-> OrderExecutedWithPriceMessageCode, body |-> one] : one \in CheckedOrderExecutedWithPriceMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> OrderDeleteMessageCode, body |-> one] : one \in CheckedOrderDeleteMessage }
        \cup { [tag |-> OrderReplaceMessageCode, body |-> one] : one \in CheckedOrderReplaceMessage }
        \cup { [tag |-> NonCrossTradeMessageCode, body |-> one] : one \in CheckedNonCrossTradeMessage }
        \cup { [tag |-> CrossTradeMessageCode, body |-> one] : one \in CheckedCrossTradeMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> NetOrderImbalanceIndicatorMessageCode, body |-> one] : one \in CheckedNetOrderImbalanceIndicatorMessage }
        \cup { [tag |-> RetailPriceImprovementIndicatorMessageCode, body |-> one] : one \in CheckedRetailPriceImprovementIndicatorMessage }
        \cup { [tag |-> DirectListingWithCapitalRaisePriceDiscoveryMessageCode, body |-> one] : one \in CheckedDirectListingWithCapitalRaisePriceDiscoveryMessage }

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

(* Every Stock Directory Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockDirectoryMessage ==
    \A message \in CheckedStockDirectoryMessage :
        LET read == DecodeStockDirectoryMessage(EncodeStockDirectoryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stock Trading Action Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStockTradingActionMessage ==
    \A message \in CheckedStockTradingActionMessage :
        LET read == DecodeStockTradingActionMessage(EncodeStockTradingActionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reg Sho Short Sale Price Test Restricted Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRegShoShortSalePriceTestRestrictedIndicatorMessage ==
    \A message \in CheckedRegShoShortSalePriceTestRestrictedIndicatorMessage :
        LET read == DecodeRegShoShortSalePriceTestRestrictedIndicatorMessage(EncodeRegShoShortSalePriceTestRestrictedIndicatorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Participant Position Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketParticipantPositionMessage ==
    \A message \in CheckedMarketParticipantPositionMessage :
        LET read == DecodeMarketParticipantPositionMessage(EncodeMarketParticipantPositionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mwcb Decline Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMwcbDeclineLevelMessage ==
    \A message \in CheckedMwcbDeclineLevelMessage :
        LET read == DecodeMwcbDeclineLevelMessage(EncodeMwcbDeclineLevelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mwcb Status Level Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMwcbStatusLevelMessage ==
    \A message \in CheckedMwcbStatusLevelMessage :
        LET read == DecodeMwcbStatusLevelMessage(EncodeMwcbStatusLevelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ipo Quoting Period Update decodes back to what was encoded, and leaves nothing over *)
RoundTripIpoQuotingPeriodUpdate ==
    \A message \in CheckedIpoQuotingPeriodUpdate :
        LET read == DecodeIpoQuotingPeriodUpdate(EncodeIpoQuotingPeriodUpdate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Luld Auction Collar Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLuldAuctionCollarMessage ==
    \A message \in CheckedLuldAuctionCollarMessage :
        LET read == DecodeLuldAuctionCollarMessage(EncodeLuldAuctionCollarMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Operational Halt Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOperationalHaltMessage ==
    \A message \in CheckedOperationalHaltMessage :
        LET read == DecodeOperationalHaltMessage(EncodeOperationalHaltMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order No Mpid Attribution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderNoMpidAttributionMessage ==
    \A message \in CheckedAddOrderNoMpidAttributionMessage :
        LET read == DecodeAddOrderNoMpidAttributionMessage(EncodeAddOrderNoMpidAttributionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Add Order With Mpid Attribution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAddOrderWithMpidAttributionMessage ==
    \A message \in CheckedAddOrderWithMpidAttributionMessage :
        LET read == DecodeAddOrderWithMpidAttributionMessage(EncodeAddOrderWithMpidAttributionMessage(message))
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

(* Every Order Delete Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderDeleteMessage ==
    \A message \in CheckedOrderDeleteMessage :
        LET read == DecodeOrderDeleteMessage(EncodeOrderDeleteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replace Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplaceMessage ==
    \A message \in CheckedOrderReplaceMessage :
        LET read == DecodeOrderReplaceMessage(EncodeOrderReplaceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Non Cross Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNonCrossTradeMessage ==
    \A message \in CheckedNonCrossTradeMessage :
        LET read == DecodeNonCrossTradeMessage(EncodeNonCrossTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossTradeMessage ==
    \A message \in CheckedCrossTradeMessage :
        LET read == DecodeCrossTradeMessage(EncodeCrossTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Broken Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBrokenTradeMessage ==
    \A message \in CheckedBrokenTradeMessage :
        LET read == DecodeBrokenTradeMessage(EncodeBrokenTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Net Order Imbalance Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNetOrderImbalanceIndicatorMessage ==
    \A message \in CheckedNetOrderImbalanceIndicatorMessage :
        LET read == DecodeNetOrderImbalanceIndicatorMessage(EncodeNetOrderImbalanceIndicatorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retail Price Improvement Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetailPriceImprovementIndicatorMessage ==
    \A message \in CheckedRetailPriceImprovementIndicatorMessage :
        LET read == DecodeRetailPriceImprovementIndicatorMessage(EncodeRetailPriceImprovementIndicatorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Direct Listing With Capital Raise Price Discovery Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDirectListingWithCapitalRaisePriceDiscoveryMessage ==
    \A message \in CheckedDirectListingWithCapitalRaisePriceDiscoveryMessage :
        LET read == DecodeDirectListingWithCapitalRaisePriceDiscoveryMessage(EncodeDirectListingWithCapitalRaisePriceDiscoveryMessage(message))
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
