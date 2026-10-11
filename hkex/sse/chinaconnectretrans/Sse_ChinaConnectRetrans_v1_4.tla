------------------- MODULE Sse_ChinaConnectRetrans_v1_4 --------------------
(***************************************************************************)
(* Hong Kong Exchanges and Clearing Orion Market Data China Connect        *)
(* Retransmission v1.4                                                     *)
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
(* Sequence Reset Message: 4 bytes                                         *)
(***************************************************************************)

SequenceResetMessage ==
    [ newSeqNo : Sample(4) ]

EncodeSequenceResetMessage(message) ==
    message.newSeqNo

DecodeSequenceResetMessage(bytes) ==
    LET newSeqNo == ReadBytes(bytes, 4) IN IF ~newSeqNo.ok THEN Fail ELSE
    Ok([ newSeqNo |-> newSeqNo.value ], newSeqNo.rest)

ZeroSequenceResetMessage ==
    [ newSeqNo |-> [i \in 1 .. 4 |-> 0] ]

(* Sequence Reset Message at zero, then each field in turn at the values it is checked at *)
CheckedSequenceResetMessage ==
    { ZeroSequenceResetMessage }
        \cup { [ZeroSequenceResetMessage EXCEPT !.newSeqNo = one] : one \in Sample(4) }

(***************************************************************************)
(* Disaster Recovery Signal Message: 4 bytes                               *)
(***************************************************************************)

DisasterRecoverySignalMessage ==
    [ drStatus : Sample(4) ]

EncodeDisasterRecoverySignalMessage(message) ==
    message.drStatus

DecodeDisasterRecoverySignalMessage(bytes) ==
    LET drStatus == ReadBytes(bytes, 4) IN IF ~drStatus.ok THEN Fail ELSE
    Ok([ drStatus |-> drStatus.value ], drStatus.rest)

ZeroDisasterRecoverySignalMessage ==
    [ drStatus |-> [i \in 1 .. 4 |-> 0] ]

(* Disaster Recovery Signal Message at zero, then each field in turn at the values it is checked at *)
CheckedDisasterRecoverySignalMessage ==
    { ZeroDisasterRecoverySignalMessage }
        \cup { [ZeroDisasterRecoverySignalMessage EXCEPT !.drStatus = one] : one \in Sample(4) }

(***************************************************************************)
(* Market Definition Message: 36 bytes                                     *)
(***************************************************************************)

MarketDefinitionMessage ==
    [ marketCode         : Sample(4),
      marketName         : Sample(25),
      currencyCode       : Sample(3),
      numberOfSecurities : Sample(4) ]

EncodeMarketDefinitionMessage(message) ==
    message.marketCode
        \o message.marketName
        \o message.currencyCode
        \o message.numberOfSecurities

DecodeMarketDefinitionMessage(bytes) ==
    LET marketCode == ReadBytes(bytes, 4) IN IF ~marketCode.ok THEN Fail ELSE
    LET marketName == ReadBytes(marketCode.rest, 25) IN IF ~marketName.ok THEN Fail ELSE
    LET currencyCode == ReadBytes(marketName.rest, 3) IN IF ~currencyCode.ok THEN Fail ELSE
    LET numberOfSecurities == ReadBytes(currencyCode.rest, 4) IN IF ~numberOfSecurities.ok THEN Fail ELSE
    Ok([ marketCode         |-> marketCode.value,
         marketName         |-> marketName.value,
         currencyCode       |-> currencyCode.value,
         numberOfSecurities |-> numberOfSecurities.value ], numberOfSecurities.rest)

ZeroMarketDefinitionMessage ==
    [ marketCode         |-> [i \in 1 .. 4 |-> 0],
      marketName         |-> [i \in 1 .. 25 |-> 0],
      currencyCode       |-> [i \in 1 .. 3 |-> 0],
      numberOfSecurities |-> [i \in 1 .. 4 |-> 0] ]

(* Market Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedMarketDefinitionMessage ==
    { ZeroMarketDefinitionMessage }
        \cup { [ZeroMarketDefinitionMessage EXCEPT !.marketCode = one] : one \in Sample(4) }
        \cup { [ZeroMarketDefinitionMessage EXCEPT !.marketName = one] : one \in Sample(25) }
        \cup { [ZeroMarketDefinitionMessage EXCEPT !.currencyCode = one] : one \in Sample(3) }
        \cup { [ZeroMarketDefinitionMessage EXCEPT !.numberOfSecurities = one] : one \in Sample(4) }

(***************************************************************************)
(* Logon Message: 12 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ username : Sample(12) ]

EncodeLogonMessage(message) ==
    message.username

DecodeLogonMessage(bytes) ==
    LET username == ReadBytes(bytes, 12) IN IF ~username.ok THEN Fail ELSE
    Ok([ username |-> username.value ], username.rest)

ZeroLogonMessage ==
    [ username |-> [i \in 1 .. 12 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.username = one] : one \in Sample(12) }

(***************************************************************************)
(* Logon Response Message: 4 bytes                                         *)
(***************************************************************************)

LogonResponseMessage ==
    [ sessionStatus : Sample(1),
      filler3       : Sample(3) ]

EncodeLogonResponseMessage(message) ==
    message.sessionStatus
        \o message.filler3

DecodeLogonResponseMessage(bytes) ==
    LET sessionStatus == ReadBytes(bytes, 1) IN IF ~sessionStatus.ok THEN Fail ELSE
    LET filler3 == ReadBytes(sessionStatus.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    Ok([ sessionStatus |-> sessionStatus.value,
         filler3       |-> filler3.value ], filler3.rest)

ZeroLogonResponseMessage ==
    [ sessionStatus |-> [i \in 1 .. 1 |-> 0],
      filler3       |-> [i \in 1 .. 3 |-> 0] ]

(* Logon Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonResponseMessage ==
    { ZeroLogonResponseMessage }
        \cup { [ZeroLogonResponseMessage EXCEPT !.sessionStatus = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.filler3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Retransmission Request Message: 12 bytes                                *)
(***************************************************************************)

RetransmissionRequestMessage ==
    [ channelId   : Sample(2),
      filler2     : Sample(2),
      beginSeqNum : Sample(4),
      endSeqNum   : Sample(4) ]

EncodeRetransmissionRequestMessage(message) ==
    message.channelId
        \o message.filler2
        \o message.beginSeqNum
        \o message.endSeqNum

DecodeRetransmissionRequestMessage(bytes) ==
    LET channelId == ReadBytes(bytes, 2) IN IF ~channelId.ok THEN Fail ELSE
    LET filler2 == ReadBytes(channelId.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET beginSeqNum == ReadBytes(filler2.rest, 4) IN IF ~beginSeqNum.ok THEN Fail ELSE
    LET endSeqNum == ReadBytes(beginSeqNum.rest, 4) IN IF ~endSeqNum.ok THEN Fail ELSE
    Ok([ channelId   |-> channelId.value,
         filler2     |-> filler2.value,
         beginSeqNum |-> beginSeqNum.value,
         endSeqNum   |-> endSeqNum.value ], endSeqNum.rest)

ZeroRetransmissionRequestMessage ==
    [ channelId   |-> [i \in 1 .. 2 |-> 0],
      filler2     |-> [i \in 1 .. 2 |-> 0],
      beginSeqNum |-> [i \in 1 .. 4 |-> 0],
      endSeqNum   |-> [i \in 1 .. 4 |-> 0] ]

(* Retransmission Request Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionRequestMessage ==
    { ZeroRetransmissionRequestMessage }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.channelId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.beginSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionRequestMessage EXCEPT !.endSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Retransmission Response Message: 12 bytes                               *)
(***************************************************************************)

RetransmissionResponseMessage ==
    [ channelId     : Sample(2),
      retransStatus : Sample(1),
      filler1       : Sample(1),
      beginSeqNum   : Sample(4),
      endSeqNum     : Sample(4) ]

EncodeRetransmissionResponseMessage(message) ==
    message.channelId
        \o message.retransStatus
        \o message.filler1
        \o message.beginSeqNum
        \o message.endSeqNum

DecodeRetransmissionResponseMessage(bytes) ==
    LET channelId == ReadBytes(bytes, 2) IN IF ~channelId.ok THEN Fail ELSE
    LET retransStatus == ReadBytes(channelId.rest, 1) IN IF ~retransStatus.ok THEN Fail ELSE
    LET filler1 == ReadBytes(retransStatus.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET beginSeqNum == ReadBytes(filler1.rest, 4) IN IF ~beginSeqNum.ok THEN Fail ELSE
    LET endSeqNum == ReadBytes(beginSeqNum.rest, 4) IN IF ~endSeqNum.ok THEN Fail ELSE
    Ok([ channelId     |-> channelId.value,
         retransStatus |-> retransStatus.value,
         filler1       |-> filler1.value,
         beginSeqNum   |-> beginSeqNum.value,
         endSeqNum     |-> endSeqNum.value ], endSeqNum.rest)

ZeroRetransmissionResponseMessage ==
    [ channelId     |-> [i \in 1 .. 2 |-> 0],
      retransStatus |-> [i \in 1 .. 1 |-> 0],
      filler1       |-> [i \in 1 .. 1 |-> 0],
      beginSeqNum   |-> [i \in 1 .. 4 |-> 0],
      endSeqNum     |-> [i \in 1 .. 4 |-> 0] ]

(* Retransmission Response Message at zero, then each field in turn at the values it is checked at *)
CheckedRetransmissionResponseMessage ==
    { ZeroRetransmissionResponseMessage }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.channelId = one] : one \in Sample(2) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.retransStatus = one] : one \in Sample(1) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.beginSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRetransmissionResponseMessage EXCEPT !.endSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Security Definition Message: 216 bytes                                  *)
(***************************************************************************)

SecurityDefinitionMessage ==
    [ securityCode         : Sample(4),
      marketCode           : Sample(4),
      isinCode             : Sample(12),
      instrumentType       : Sample(4),
      filler2              : Sample(2),
      securityShortName    : Sample(40),
      currencyCode         : Sample(3),
      filler60             : Sample(60),
      securityNameGb       : Sample(60),
      lotSize              : Sample(4),
      previousClosingPrice : Sample(4),
      filler1              : Sample(1),
      shortsellFlag        : Sample(1),
      filler6              : Sample(6),
      listingDate          : Sample(4),
      filler7              : Sample(7) ]

EncodeSecurityDefinitionMessage(message) ==
    message.securityCode
        \o message.marketCode
        \o message.isinCode
        \o message.instrumentType
        \o message.filler2
        \o message.securityShortName
        \o message.currencyCode
        \o message.filler60
        \o message.securityNameGb
        \o message.lotSize
        \o message.previousClosingPrice
        \o message.filler1
        \o message.shortsellFlag
        \o message.filler6
        \o message.listingDate
        \o message.filler7

DecodeSecurityDefinitionMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET marketCode == ReadBytes(securityCode.rest, 4) IN IF ~marketCode.ok THEN Fail ELSE
    LET isinCode == ReadBytes(marketCode.rest, 12) IN IF ~isinCode.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(isinCode.rest, 4) IN IF ~instrumentType.ok THEN Fail ELSE
    LET filler2 == ReadBytes(instrumentType.rest, 2) IN IF ~filler2.ok THEN Fail ELSE
    LET securityShortName == ReadBytes(filler2.rest, 40) IN IF ~securityShortName.ok THEN Fail ELSE
    LET currencyCode == ReadBytes(securityShortName.rest, 3) IN IF ~currencyCode.ok THEN Fail ELSE
    LET filler60 == ReadBytes(currencyCode.rest, 60) IN IF ~filler60.ok THEN Fail ELSE
    LET securityNameGb == ReadBytes(filler60.rest, 60) IN IF ~securityNameGb.ok THEN Fail ELSE
    LET lotSize == ReadBytes(securityNameGb.rest, 4) IN IF ~lotSize.ok THEN Fail ELSE
    LET previousClosingPrice == ReadBytes(lotSize.rest, 4) IN IF ~previousClosingPrice.ok THEN Fail ELSE
    LET filler1 == ReadBytes(previousClosingPrice.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET shortsellFlag == ReadBytes(filler1.rest, 1) IN IF ~shortsellFlag.ok THEN Fail ELSE
    LET filler6 == ReadBytes(shortsellFlag.rest, 6) IN IF ~filler6.ok THEN Fail ELSE
    LET listingDate == ReadBytes(filler6.rest, 4) IN IF ~listingDate.ok THEN Fail ELSE
    LET filler7 == ReadBytes(listingDate.rest, 7) IN IF ~filler7.ok THEN Fail ELSE
    Ok([ securityCode         |-> securityCode.value,
         marketCode           |-> marketCode.value,
         isinCode             |-> isinCode.value,
         instrumentType       |-> instrumentType.value,
         filler2              |-> filler2.value,
         securityShortName    |-> securityShortName.value,
         currencyCode         |-> currencyCode.value,
         filler60             |-> filler60.value,
         securityNameGb       |-> securityNameGb.value,
         lotSize              |-> lotSize.value,
         previousClosingPrice |-> previousClosingPrice.value,
         filler1              |-> filler1.value,
         shortsellFlag        |-> shortsellFlag.value,
         filler6              |-> filler6.value,
         listingDate          |-> listingDate.value,
         filler7              |-> filler7.value ], filler7.rest)

ZeroSecurityDefinitionMessage ==
    [ securityCode         |-> [i \in 1 .. 4 |-> 0],
      marketCode           |-> [i \in 1 .. 4 |-> 0],
      isinCode             |-> [i \in 1 .. 12 |-> 0],
      instrumentType       |-> [i \in 1 .. 4 |-> 0],
      filler2              |-> [i \in 1 .. 2 |-> 0],
      securityShortName    |-> [i \in 1 .. 40 |-> 0],
      currencyCode         |-> [i \in 1 .. 3 |-> 0],
      filler60             |-> [i \in 1 .. 60 |-> 0],
      securityNameGb       |-> [i \in 1 .. 60 |-> 0],
      lotSize              |-> [i \in 1 .. 4 |-> 0],
      previousClosingPrice |-> [i \in 1 .. 4 |-> 0],
      filler1              |-> [i \in 1 .. 1 |-> 0],
      shortsellFlag        |-> [i \in 1 .. 1 |-> 0],
      filler6              |-> [i \in 1 .. 6 |-> 0],
      listingDate          |-> [i \in 1 .. 4 |-> 0],
      filler7              |-> [i \in 1 .. 7 |-> 0] ]

(* Security Definition Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionMessage ==
    { ZeroSecurityDefinitionMessage }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.marketCode = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.isinCode = one] : one \in Sample(12) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.instrumentType = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.filler2 = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityShortName = one] : one \in Sample(40) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.currencyCode = one] : one \in Sample(3) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.filler60 = one] : one \in Sample(60) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.securityNameGb = one] : one \in Sample(60) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.lotSize = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.previousClosingPrice = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.shortsellFlag = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.filler6 = one] : one \in Sample(6) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.listingDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionMessage EXCEPT !.filler7 = one] : one \in Sample(7) }

(***************************************************************************)
(* Security Status Message: 16 bytes                                       *)
(***************************************************************************)

SecurityStatusMessage ==
    [ securityCode          : Sample(4),
      securityTradingStatus : Sample(1),
      filler3               : Sample(3),
      tradingPhaseCode      : Sample(8) ]

EncodeSecurityStatusMessage(message) ==
    message.securityCode
        \o message.securityTradingStatus
        \o message.filler3
        \o message.tradingPhaseCode

DecodeSecurityStatusMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(securityCode.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET filler3 == ReadBytes(securityTradingStatus.rest, 3) IN IF ~filler3.ok THEN Fail ELSE
    LET tradingPhaseCode == ReadBytes(filler3.rest, 8) IN IF ~tradingPhaseCode.ok THEN Fail ELSE
    Ok([ securityCode          |-> securityCode.value,
         securityTradingStatus |-> securityTradingStatus.value,
         filler3               |-> filler3.value,
         tradingPhaseCode      |-> tradingPhaseCode.value ], tradingPhaseCode.rest)

ZeroSecurityStatusMessage ==
    [ securityCode          |-> [i \in 1 .. 4 |-> 0],
      securityTradingStatus |-> [i \in 1 .. 1 |-> 0],
      filler3               |-> [i \in 1 .. 3 |-> 0],
      tradingPhaseCode      |-> [i \in 1 .. 8 |-> 0] ]

(* Security Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusMessage ==
    { ZeroSecurityStatusMessage }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.filler3 = one] : one \in Sample(3) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.tradingPhaseCode = one] : one \in Sample(8) }

(***************************************************************************)
(* Statistics Message: 48 bytes                                            *)
(***************************************************************************)

StatisticsMessage ==
    [ securityCode : Sample(4),
      sharesTraded : Sample(8),
      turnover     : Sample(8),
      highPrice    : Sample(4),
      lowPrice     : Sample(4),
      lastPrice    : Sample(4),
      openingPrice : Sample(4),
      filler12     : Sample(12) ]

EncodeStatisticsMessage(message) ==
    message.securityCode
        \o message.sharesTraded
        \o message.turnover
        \o message.highPrice
        \o message.lowPrice
        \o message.lastPrice
        \o message.openingPrice
        \o message.filler12

DecodeStatisticsMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET sharesTraded == ReadBytes(securityCode.rest, 8) IN IF ~sharesTraded.ok THEN Fail ELSE
    LET turnover == ReadBytes(sharesTraded.rest, 8) IN IF ~turnover.ok THEN Fail ELSE
    LET highPrice == ReadBytes(turnover.rest, 4) IN IF ~highPrice.ok THEN Fail ELSE
    LET lowPrice == ReadBytes(highPrice.rest, 4) IN IF ~lowPrice.ok THEN Fail ELSE
    LET lastPrice == ReadBytes(lowPrice.rest, 4) IN IF ~lastPrice.ok THEN Fail ELSE
    LET openingPrice == ReadBytes(lastPrice.rest, 4) IN IF ~openingPrice.ok THEN Fail ELSE
    LET filler12 == ReadBytes(openingPrice.rest, 12) IN IF ~filler12.ok THEN Fail ELSE
    Ok([ securityCode |-> securityCode.value,
         sharesTraded |-> sharesTraded.value,
         turnover     |-> turnover.value,
         highPrice    |-> highPrice.value,
         lowPrice     |-> lowPrice.value,
         lastPrice    |-> lastPrice.value,
         openingPrice |-> openingPrice.value,
         filler12     |-> filler12.value ], filler12.rest)

ZeroStatisticsMessage ==
    [ securityCode |-> [i \in 1 .. 4 |-> 0],
      sharesTraded |-> [i \in 1 .. 8 |-> 0],
      turnover     |-> [i \in 1 .. 8 |-> 0],
      highPrice    |-> [i \in 1 .. 4 |-> 0],
      lowPrice     |-> [i \in 1 .. 4 |-> 0],
      lastPrice    |-> [i \in 1 .. 4 |-> 0],
      openingPrice |-> [i \in 1 .. 4 |-> 0],
      filler12     |-> [i \in 1 .. 12 |-> 0] ]

(* Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsMessage ==
    { ZeroStatisticsMessage }
        \cup { [ZeroStatisticsMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.sharesTraded = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.turnover = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.highPrice = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.lowPrice = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.lastPrice = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.openingPrice = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.filler12 = one] : one \in Sample(12) }

(***************************************************************************)
(* Top Of Book Message: 36 bytes                                           *)
(***************************************************************************)

TopOfBookMessage ==
    [ securityCode         : Sample(4),
      aggregateBidQuantity : Sample(8),
      aggregateAskQuantity : Sample(8),
      bidPrice             : Sample(4),
      askPrice             : Sample(4),
      filler8              : Sample(8) ]

EncodeTopOfBookMessage(message) ==
    message.securityCode
        \o message.aggregateBidQuantity
        \o message.aggregateAskQuantity
        \o message.bidPrice
        \o message.askPrice
        \o message.filler8

DecodeTopOfBookMessage(bytes) ==
    LET securityCode == ReadBytes(bytes, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET aggregateBidQuantity == ReadBytes(securityCode.rest, 8) IN IF ~aggregateBidQuantity.ok THEN Fail ELSE
    LET aggregateAskQuantity == ReadBytes(aggregateBidQuantity.rest, 8) IN IF ~aggregateAskQuantity.ok THEN Fail ELSE
    LET bidPrice == ReadBytes(aggregateAskQuantity.rest, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET askPrice == ReadBytes(bidPrice.rest, 4) IN IF ~askPrice.ok THEN Fail ELSE
    LET filler8 == ReadBytes(askPrice.rest, 8) IN IF ~filler8.ok THEN Fail ELSE
    Ok([ securityCode         |-> securityCode.value,
         aggregateBidQuantity |-> aggregateBidQuantity.value,
         aggregateAskQuantity |-> aggregateAskQuantity.value,
         bidPrice             |-> bidPrice.value,
         askPrice             |-> askPrice.value,
         filler8              |-> filler8.value ], filler8.rest)

ZeroTopOfBookMessage ==
    [ securityCode         |-> [i \in 1 .. 4 |-> 0],
      aggregateBidQuantity |-> [i \in 1 .. 8 |-> 0],
      aggregateAskQuantity |-> [i \in 1 .. 8 |-> 0],
      bidPrice             |-> [i \in 1 .. 4 |-> 0],
      askPrice             |-> [i \in 1 .. 4 |-> 0],
      filler8              |-> [i \in 1 .. 8 |-> 0] ]

(* Top Of Book Message at zero, then each field in turn at the values it is checked at *)
CheckedTopOfBookMessage ==
    { ZeroTopOfBookMessage }
        \cup { [ZeroTopOfBookMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.aggregateBidQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.aggregateAskQuantity = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.askPrice = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.filler8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

SequenceResetMessageCode == 100  \* 0x64
DisasterRecoverySignalMessageCode == 105  \* 0x69
MarketDefinitionMessageCode == 610  \* 0x262
LogonMessageCode == 101  \* 0x65
LogonResponseMessageCode == 102  \* 0x66
RetransmissionRequestMessageCode == 201  \* 0xc9
RetransmissionResponseMessageCode == 202  \* 0xca
SecurityDefinitionMessageCode == 611  \* 0x263
SecurityStatusMessageCode == 621  \* 0x26d
StatisticsMessageCode == 660  \* 0x294
TopOfBookMessageCode == 655  \* 0x28f

Payload ==
    [ tag : {SequenceResetMessageCode}, body : SequenceResetMessage ]
        \cup [ tag : {DisasterRecoverySignalMessageCode}, body : DisasterRecoverySignalMessage ]
        \cup [ tag : {MarketDefinitionMessageCode}, body : MarketDefinitionMessage ]
        \cup [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogonResponseMessageCode}, body : LogonResponseMessage ]
        \cup [ tag : {RetransmissionRequestMessageCode}, body : RetransmissionRequestMessage ]
        \cup [ tag : {RetransmissionResponseMessageCode}, body : RetransmissionResponseMessage ]
        \cup [ tag : {SecurityDefinitionMessageCode}, body : SecurityDefinitionMessage ]
        \cup [ tag : {SecurityStatusMessageCode}, body : SecurityStatusMessage ]
        \cup [ tag : {StatisticsMessageCode}, body : StatisticsMessage ]
        \cup [ tag : {TopOfBookMessageCode}, body : TopOfBookMessage ]

EncodePayload(message) ==
    CASE message.tag = SequenceResetMessageCode -> EncodeSequenceResetMessage(message.body)
      [] message.tag = DisasterRecoverySignalMessageCode -> EncodeDisasterRecoverySignalMessage(message.body)
      [] message.tag = MarketDefinitionMessageCode -> EncodeMarketDefinitionMessage(message.body)
      [] message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogonResponseMessageCode -> EncodeLogonResponseMessage(message.body)
      [] message.tag = RetransmissionRequestMessageCode -> EncodeRetransmissionRequestMessage(message.body)
      [] message.tag = RetransmissionResponseMessageCode -> EncodeRetransmissionResponseMessage(message.body)
      [] message.tag = SecurityDefinitionMessageCode -> EncodeSecurityDefinitionMessage(message.body)
      [] message.tag = SecurityStatusMessageCode -> EncodeSecurityStatusMessage(message.body)
      [] message.tag = StatisticsMessageCode -> EncodeStatisticsMessage(message.body)
      [] message.tag = TopOfBookMessageCode -> EncodeTopOfBookMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = SequenceResetMessageCode -> DecodeSequenceResetMessage(bytes)
              [] tag = DisasterRecoverySignalMessageCode -> DecodeDisasterRecoverySignalMessage(bytes)
              [] tag = MarketDefinitionMessageCode -> DecodeMarketDefinitionMessage(bytes)
              [] tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogonResponseMessageCode -> DecodeLogonResponseMessage(bytes)
              [] tag = RetransmissionRequestMessageCode -> DecodeRetransmissionRequestMessage(bytes)
              [] tag = RetransmissionResponseMessageCode -> DecodeRetransmissionResponseMessage(bytes)
              [] tag = SecurityDefinitionMessageCode -> DecodeSecurityDefinitionMessage(bytes)
              [] tag = SecurityStatusMessageCode -> DecodeSecurityStatusMessage(bytes)
              [] tag = StatisticsMessageCode -> DecodeStatisticsMessage(bytes)
              [] tag = TopOfBookMessageCode -> DecodeTopOfBookMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> SequenceResetMessageCode, body |-> one] : one \in CheckedSequenceResetMessage }
        \cup { [tag |-> DisasterRecoverySignalMessageCode, body |-> one] : one \in CheckedDisasterRecoverySignalMessage }
        \cup { [tag |-> MarketDefinitionMessageCode, body |-> one] : one \in CheckedMarketDefinitionMessage }
        \cup { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogonResponseMessageCode, body |-> one] : one \in CheckedLogonResponseMessage }
        \cup { [tag |-> RetransmissionRequestMessageCode, body |-> one] : one \in CheckedRetransmissionRequestMessage }
        \cup { [tag |-> RetransmissionResponseMessageCode, body |-> one] : one \in CheckedRetransmissionResponseMessage }
        \cup { [tag |-> SecurityDefinitionMessageCode, body |-> one] : one \in CheckedSecurityDefinitionMessage }
        \cup { [tag |-> SecurityStatusMessageCode, body |-> one] : one \in CheckedSecurityStatusMessage }
        \cup { [tag |-> StatisticsMessageCode, body |-> one] : one \in CheckedStatisticsMessage }
        \cup { [tag |-> TopOfBookMessageCode, body |-> one] : one \in CheckedTopOfBookMessage }

(***************************************************************************)
(* Message, framed by Msg Size                                             *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntLE(message.payload.tag, 2)
        \o EncodePayload(message.payload)

(* Msg Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET msgType == ReadUIntLE(bytes, 2) IN IF ~msgType.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, msgType.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ payload |-> payload.value ], payload.rest)

DecodeMessage(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> SequenceResetMessageCode, body |-> ZeroSequenceResetMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DisasterRecoverySignalMessageCode, body |-> ZeroDisasterRecoverySignalMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MarketDefinitionMessageCode, body |-> ZeroMarketDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogonResponseMessageCode, body |-> ZeroLogonResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RetransmissionRequestMessageCode, body |-> ZeroRetransmissionRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RetransmissionResponseMessageCode, body |-> ZeroRetransmissionResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionMessageCode, body |-> ZeroSecurityDefinitionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatusMessageCode, body |-> ZeroSecurityStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StatisticsMessageCode, body |-> ZeroStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TopOfBookMessageCode, body |-> ZeroTopOfBookMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ pktSize  : Sample(2),
      filler   : Sample(1),
      seqNum   : Sample(4),
      sendTime : Sample(8),
      message  : SampleLists(OneMessage) ]

EncodePacket(message) ==
    message.pktSize
        \o EncodeUIntBE(Len(message.message), 1)
        \o message.filler
        \o message.seqNum
        \o message.sendTime
        \o EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET pktSize == ReadBytes(bytes, 2) IN IF ~pktSize.ok THEN Fail ELSE
    LET msgCount == ReadUIntBE(pktSize.rest, 1) IN IF ~msgCount.ok THEN Fail ELSE
    LET filler == ReadBytes(msgCount.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    LET seqNum == ReadBytes(filler.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET sendTime == ReadBytes(seqNum.rest, 8) IN IF ~sendTime.ok THEN Fail ELSE
    LET message == ReadMessageList(sendTime.rest, msgCount.value) IN IF ~message.ok THEN Fail ELSE
    Ok([ pktSize  |-> pktSize.value,
         filler   |-> filler.value,
         seqNum   |-> seqNum.value,
         sendTime |-> sendTime.value,
         message  |-> message.value ], message.rest)

ZeroPacket ==
    [ pktSize  |-> [i \in 1 .. 2 |-> 0],
      filler   |-> [i \in 1 .. 1 |-> 0],
      seqNum   |-> [i \in 1 .. 4 |-> 0],
      sendTime |-> [i \in 1 .. 8 |-> 0],
      message  |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.pktSize = one] : one \in Sample(2) }
        \cup { [ZeroPacket EXCEPT !.filler = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.sendTime = one] : one \in Sample(8) }
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

(* Every Sequence Reset Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSequenceResetMessage ==
    \A message \in CheckedSequenceResetMessage :
        LET read == DecodeSequenceResetMessage(EncodeSequenceResetMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Disaster Recovery Signal Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDisasterRecoverySignalMessage ==
    \A message \in CheckedDisasterRecoverySignalMessage :
        LET read == DecodeDisasterRecoverySignalMessage(EncodeDisasterRecoverySignalMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDefinitionMessage ==
    \A message \in CheckedMarketDefinitionMessage :
        LET read == DecodeMarketDefinitionMessage(EncodeMarketDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonMessage ==
    \A message \in CheckedLogonMessage :
        LET read == DecodeLogonMessage(EncodeLogonMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonResponseMessage ==
    \A message \in CheckedLogonResponseMessage :
        LET read == DecodeLogonResponseMessage(EncodeLogonResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionRequestMessage ==
    \A message \in CheckedRetransmissionRequestMessage :
        LET read == DecodeRetransmissionRequestMessage(EncodeRetransmissionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Retransmission Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmissionResponseMessage ==
    \A message \in CheckedRetransmissionResponseMessage :
        LET read == DecodeRetransmissionResponseMessage(EncodeRetransmissionResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionMessage ==
    \A message \in CheckedSecurityDefinitionMessage :
        LET read == DecodeSecurityDefinitionMessage(EncodeSecurityDefinitionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusMessage ==
    \A message \in CheckedSecurityStatusMessage :
        LET read == DecodeSecurityStatusMessage(EncodeSecurityStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Statistics Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStatisticsMessage ==
    \A message \in CheckedStatisticsMessage :
        LET read == DecodeStatisticsMessage(EncodeStatisticsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Top Of Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopOfBookMessage ==
    \A message \in CheckedTopOfBookMessage :
        LET read == DecodeTopOfBookMessage(EncodeTopOfBookMessage(message))
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

(* A Payload is selected by the Msg Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Msg Size is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
