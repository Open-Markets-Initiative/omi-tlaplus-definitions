-------------------- MODULE BmeFixedIncome_Replay_v1_6 ---------------------
(***************************************************************************)
(* Bolsas y Mercados Españoles BME Fixed Income Replay v1.6                *)
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
(* Logon Response Message: 26 bytes                                        *)
(***************************************************************************)

LogonResponseMessage ==
    [ sequenceNumber         : Sample(4),
      heartBtInt             : Sample(1),
      protocolVersion        : Sample(6),
      testProductionInd      : Sample(1),
      environmentCode        : Sample(2),
      sessionDate            : Sample(4),
      expectedSequenceNumber : Sample(4),
      sequenceNumberTo       : Sample(4) ]

EncodeLogonResponseMessage(message) ==
    message.sequenceNumber
        \o message.heartBtInt
        \o message.protocolVersion
        \o message.testProductionInd
        \o message.environmentCode
        \o message.sessionDate
        \o message.expectedSequenceNumber
        \o message.sequenceNumberTo

DecodeLogonResponseMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET heartBtInt == ReadBytes(sequenceNumber.rest, 1) IN IF ~heartBtInt.ok THEN Fail ELSE
    LET protocolVersion == ReadBytes(heartBtInt.rest, 6) IN IF ~protocolVersion.ok THEN Fail ELSE
    LET testProductionInd == ReadBytes(protocolVersion.rest, 1) IN IF ~testProductionInd.ok THEN Fail ELSE
    LET environmentCode == ReadBytes(testProductionInd.rest, 2) IN IF ~environmentCode.ok THEN Fail ELSE
    LET sessionDate == ReadBytes(environmentCode.rest, 4) IN IF ~sessionDate.ok THEN Fail ELSE
    LET expectedSequenceNumber == ReadBytes(sessionDate.rest, 4) IN IF ~expectedSequenceNumber.ok THEN Fail ELSE
    LET sequenceNumberTo == ReadBytes(expectedSequenceNumber.rest, 4) IN IF ~sequenceNumberTo.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         heartBtInt             |-> heartBtInt.value,
         protocolVersion        |-> protocolVersion.value,
         testProductionInd      |-> testProductionInd.value,
         environmentCode        |-> environmentCode.value,
         sessionDate            |-> sessionDate.value,
         expectedSequenceNumber |-> expectedSequenceNumber.value,
         sequenceNumberTo       |-> sequenceNumberTo.value ], sequenceNumberTo.rest)

ZeroLogonResponseMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      heartBtInt             |-> [i \in 1 .. 1 |-> 0],
      protocolVersion        |-> [i \in 1 .. 6 |-> 0],
      testProductionInd      |-> [i \in 1 .. 1 |-> 0],
      environmentCode        |-> [i \in 1 .. 2 |-> 0],
      sessionDate            |-> [i \in 1 .. 4 |-> 0],
      expectedSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      sequenceNumberTo       |-> [i \in 1 .. 4 |-> 0] ]

(* Logon Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonResponseMessage ==
    { ZeroLogonResponseMessage }
        \cup { [ZeroLogonResponseMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.heartBtInt = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.protocolVersion = one] : one \in Sample(6) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.testProductionInd = one] : one \in Sample(1) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.environmentCode = one] : one \in Sample(2) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.sessionDate = one] : one \in Sample(4) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.expectedSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLogonResponseMessage EXCEPT !.sequenceNumberTo = one] : one \in Sample(4) }

(***************************************************************************)
(* Logout Response Message: 5 bytes                                        *)
(***************************************************************************)

LogoutResponseMessage ==
    [ sequenceNumber : Sample(4),
      logoutReason   : Sample(1) ]

EncodeLogoutResponseMessage(message) ==
    message.sequenceNumber
        \o message.logoutReason

DecodeLogoutResponseMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET logoutReason == ReadBytes(sequenceNumber.rest, 1) IN IF ~logoutReason.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         logoutReason   |-> logoutReason.value ], logoutReason.rest)

ZeroLogoutResponseMessage ==
    [ sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      logoutReason   |-> [i \in 1 .. 1 |-> 0] ]

(* Logout Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutResponseMessage ==
    { ZeroLogoutResponseMessage }
        \cup { [ZeroLogoutResponseMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLogoutResponseMessage EXCEPT !.logoutReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Heartbeat Message: 4 bytes                                              *)
(***************************************************************************)

HeartbeatMessage ==
    [ sequenceNumber : Sample(4) ]

EncodeHeartbeatMessage(message) ==
    message.sequenceNumber

DecodeHeartbeatMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroHeartbeatMessage ==
    [ sequenceNumber |-> [i \in 1 .. 4 |-> 0] ]

(* Heartbeat Message at zero, then each field in turn at the values it is checked at *)
CheckedHeartbeatMessage ==
    { ZeroHeartbeatMessage }
        \cup { [ZeroHeartbeatMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }

(***************************************************************************)
(* Network Status Message: 5 bytes                                         *)
(***************************************************************************)

NetworkStatusMessage ==
    [ sequenceNumber     : Sample(4),
      networkStatusValue : Sample(1) ]

EncodeNetworkStatusMessage(message) ==
    message.sequenceNumber
        \o message.networkStatusValue

DecodeNetworkStatusMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET networkStatusValue == ReadBytes(sequenceNumber.rest, 1) IN IF ~networkStatusValue.ok THEN Fail ELSE
    Ok([ sequenceNumber     |-> sequenceNumber.value,
         networkStatusValue |-> networkStatusValue.value ], networkStatusValue.rest)

ZeroNetworkStatusMessage ==
    [ sequenceNumber     |-> [i \in 1 .. 4 |-> 0],
      networkStatusValue |-> [i \in 1 .. 1 |-> 0] ]

(* Network Status Message at zero, then each field in turn at the values it is checked at *)
CheckedNetworkStatusMessage ==
    { ZeroNetworkStatusMessage }
        \cup { [ZeroNetworkStatusMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroNetworkStatusMessage EXCEPT !.networkStatusValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Logon Message: 53 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ username               : Sample(7),
      password               : Sample(10),
      softwareName           : Sample(25),
      expectedSequenceNumber : Sample(4),
      subscriptions          : Sample(1),
      protocolVersion        : Sample(6) ]

EncodeLogonMessage(message) ==
    message.username
        \o message.password
        \o message.softwareName
        \o message.expectedSequenceNumber
        \o message.subscriptions
        \o message.protocolVersion

DecodeLogonMessage(bytes) ==
    LET username == ReadBytes(bytes, 7) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET softwareName == ReadBytes(password.rest, 25) IN IF ~softwareName.ok THEN Fail ELSE
    LET expectedSequenceNumber == ReadBytes(softwareName.rest, 4) IN IF ~expectedSequenceNumber.ok THEN Fail ELSE
    LET subscriptions == ReadBytes(expectedSequenceNumber.rest, 1) IN IF ~subscriptions.ok THEN Fail ELSE
    LET protocolVersion == ReadBytes(subscriptions.rest, 6) IN IF ~protocolVersion.ok THEN Fail ELSE
    Ok([ username               |-> username.value,
         password               |-> password.value,
         softwareName           |-> softwareName.value,
         expectedSequenceNumber |-> expectedSequenceNumber.value,
         subscriptions          |-> subscriptions.value,
         protocolVersion        |-> protocolVersion.value ], protocolVersion.rest)

ZeroLogonMessage ==
    [ username               |-> [i \in 1 .. 7 |-> 0],
      password               |-> [i \in 1 .. 10 |-> 0],
      softwareName           |-> [i \in 1 .. 25 |-> 0],
      expectedSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      subscriptions          |-> [i \in 1 .. 1 |-> 0],
      protocolVersion        |-> [i \in 1 .. 6 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.username = one] : one \in Sample(7) }
        \cup { [ZeroLogonMessage EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLogonMessage EXCEPT !.softwareName = one] : one \in Sample(25) }
        \cup { [ZeroLogonMessage EXCEPT !.expectedSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroLogonMessage EXCEPT !.subscriptions = one] : one \in Sample(1) }
        \cup { [ZeroLogonMessage EXCEPT !.protocolVersion = one] : one \in Sample(6) }

(***************************************************************************)
(* Reject Message: 70 bytes                                                *)
(***************************************************************************)

RejectMessage ==
    [ sequenceNumber       : Sample(4),
      sessionRejectReason  : Sample(1),
      text                 : Sample(58),
      msgRejectedReference : Sample(7) ]

EncodeRejectMessage(message) ==
    message.sequenceNumber
        \o message.sessionRejectReason
        \o message.text
        \o message.msgRejectedReference

DecodeRejectMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET sessionRejectReason == ReadBytes(sequenceNumber.rest, 1) IN IF ~sessionRejectReason.ok THEN Fail ELSE
    LET text == ReadBytes(sessionRejectReason.rest, 58) IN IF ~text.ok THEN Fail ELSE
    LET msgRejectedReference == ReadBytes(text.rest, 7) IN IF ~msgRejectedReference.ok THEN Fail ELSE
    Ok([ sequenceNumber       |-> sequenceNumber.value,
         sessionRejectReason  |-> sessionRejectReason.value,
         text                 |-> text.value,
         msgRejectedReference |-> msgRejectedReference.value ], msgRejectedReference.rest)

ZeroRejectMessage ==
    [ sequenceNumber       |-> [i \in 1 .. 4 |-> 0],
      sessionRejectReason  |-> [i \in 1 .. 1 |-> 0],
      text                 |-> [i \in 1 .. 58 |-> 0],
      msgRejectedReference |-> [i \in 1 .. 7 |-> 0] ]

(* Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectMessage ==
    { ZeroRejectMessage }
        \cup { [ZeroRejectMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroRejectMessage EXCEPT !.sessionRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroRejectMessage EXCEPT !.text = one] : one \in Sample(58) }
        \cup { [ZeroRejectMessage EXCEPT !.msgRejectedReference = one] : one \in Sample(7) }

(***************************************************************************)
(* Replay Request Message: 12 bytes                                        *)
(***************************************************************************)

ReplayRequestMessage ==
    [ sequenceNumberFrom : Sample(4),
      sequenceNumberTo   : Sample(4),
      requestId          : Sample(4) ]

EncodeReplayRequestMessage(message) ==
    message.sequenceNumberFrom
        \o message.sequenceNumberTo
        \o message.requestId

DecodeReplayRequestMessage(bytes) ==
    LET sequenceNumberFrom == ReadBytes(bytes, 4) IN IF ~sequenceNumberFrom.ok THEN Fail ELSE
    LET sequenceNumberTo == ReadBytes(sequenceNumberFrom.rest, 4) IN IF ~sequenceNumberTo.ok THEN Fail ELSE
    LET requestId == ReadBytes(sequenceNumberTo.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    Ok([ sequenceNumberFrom |-> sequenceNumberFrom.value,
         sequenceNumberTo   |-> sequenceNumberTo.value,
         requestId          |-> requestId.value ], requestId.rest)

ZeroReplayRequestMessage ==
    [ sequenceNumberFrom |-> [i \in 1 .. 4 |-> 0],
      sequenceNumberTo   |-> [i \in 1 .. 4 |-> 0],
      requestId          |-> [i \in 1 .. 4 |-> 0] ]

(* Replay Request Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayRequestMessage ==
    { ZeroReplayRequestMessage }
        \cup { [ZeroReplayRequestMessage EXCEPT !.sequenceNumberFrom = one] : one \in Sample(4) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.sequenceNumberTo = one] : one \in Sample(4) }
        \cup { [ZeroReplayRequestMessage EXCEPT !.requestId = one] : one \in Sample(4) }

(***************************************************************************)
(* Replay Request Ack Nack Message: 17 bytes                               *)
(***************************************************************************)

ReplayRequestAckNackMessage ==
    [ sequenceNumber     : Sample(4),
      sequenceNumberFrom : Sample(4),
      sequenceNumberTo   : Sample(4),
      requestId          : Sample(4),
      status             : Sample(1) ]

EncodeReplayRequestAckNackMessage(message) ==
    message.sequenceNumber
        \o message.sequenceNumberFrom
        \o message.sequenceNumberTo
        \o message.requestId
        \o message.status

DecodeReplayRequestAckNackMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET sequenceNumberFrom == ReadBytes(sequenceNumber.rest, 4) IN IF ~sequenceNumberFrom.ok THEN Fail ELSE
    LET sequenceNumberTo == ReadBytes(sequenceNumberFrom.rest, 4) IN IF ~sequenceNumberTo.ok THEN Fail ELSE
    LET requestId == ReadBytes(sequenceNumberTo.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET status == ReadBytes(requestId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ sequenceNumber     |-> sequenceNumber.value,
         sequenceNumberFrom |-> sequenceNumberFrom.value,
         sequenceNumberTo   |-> sequenceNumberTo.value,
         requestId          |-> requestId.value,
         status             |-> status.value ], status.rest)

ZeroReplayRequestAckNackMessage ==
    [ sequenceNumber     |-> [i \in 1 .. 4 |-> 0],
      sequenceNumberFrom |-> [i \in 1 .. 4 |-> 0],
      sequenceNumberTo   |-> [i \in 1 .. 4 |-> 0],
      requestId          |-> [i \in 1 .. 4 |-> 0],
      status             |-> [i \in 1 .. 1 |-> 0] ]

(* Replay Request Ack Nack Message at zero, then each field in turn at the values it is checked at *)
CheckedReplayRequestAckNackMessage ==
    { ZeroReplayRequestAckNackMessage }
        \cup { [ZeroReplayRequestAckNackMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroReplayRequestAckNackMessage EXCEPT !.sequenceNumberFrom = one] : one \in Sample(4) }
        \cup { [ZeroReplayRequestAckNackMessage EXCEPT !.sequenceNumberTo = one] : one \in Sample(4) }
        \cup { [ZeroReplayRequestAckNackMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroReplayRequestAckNackMessage EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading Session Status Message: 15 bytes                                *)
(***************************************************************************)

TradingSessionStatusMessage ==
    [ sequenceNumber         : Sample(4),
      tradingSessionId       : Sample(1),
      tradingSessionSubId    : Sample(1),
      tradSesStatus          : Sample(1),
      transactionDateAndTime : Sample(8) ]

EncodeTradingSessionStatusMessage(message) ==
    message.sequenceNumber
        \o message.tradingSessionId
        \o message.tradingSessionSubId
        \o message.tradSesStatus
        \o message.transactionDateAndTime

DecodeTradingSessionStatusMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(sequenceNumber.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET tradingSessionSubId == ReadBytes(tradingSessionId.rest, 1) IN IF ~tradingSessionSubId.ok THEN Fail ELSE
    LET tradSesStatus == ReadBytes(tradingSessionSubId.rest, 1) IN IF ~tradSesStatus.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(tradSesStatus.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         tradingSessionId       |-> tradingSessionId.value,
         tradingSessionSubId    |-> tradingSessionSubId.value,
         tradSesStatus          |-> tradSesStatus.value,
         transactionDateAndTime |-> transactionDateAndTime.value ], transactionDateAndTime.rest)

ZeroTradingSessionStatusMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      tradingSessionId       |-> [i \in 1 .. 1 |-> 0],
      tradingSessionSubId    |-> [i \in 1 .. 1 |-> 0],
      tradSesStatus          |-> [i \in 1 .. 1 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0] ]

(* Trading Session Status Message at zero, then each field in turn at the values it is checked at *)
CheckedTradingSessionStatusMessage ==
    { ZeroTradingSessionStatusMessage }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradingSessionSubId = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.tradSesStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradingSessionStatusMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }

(***************************************************************************)
(* News Message: 82 bytes                                                  *)
(***************************************************************************)

NewsMessage ==
    [ sequenceNumber : Sample(4),
      newsText       : Sample(78) ]

EncodeNewsMessage(message) ==
    message.sequenceNumber
        \o message.newsText

DecodeNewsMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET newsText == ReadBytes(sequenceNumber.rest, 78) IN IF ~newsText.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value,
         newsText       |-> newsText.value ], newsText.rest)

ZeroNewsMessage ==
    [ sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      newsText       |-> [i \in 1 .. 78 |-> 0] ]

(* News Message at zero, then each field in turn at the values it is checked at *)
CheckedNewsMessage ==
    { ZeroNewsMessage }
        \cup { [ZeroNewsMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroNewsMessage EXCEPT !.newsText = one] : one \in Sample(78) }

(***************************************************************************)
(* Security List Cancellation Report Message: 50 bytes                     *)
(***************************************************************************)

SecurityListCancellationReportMessage ==
    [ sequenceNumber  : Sample(4),
      marketId        : Sample(4),
      marketSegmentId : Sample(4),
      securityCode    : Sample(4),
      symbol          : Sample(22),
      symbolIsin      : Sample(12) ]

EncodeSecurityListCancellationReportMessage(message) ==
    message.sequenceNumber
        \o message.marketId
        \o message.marketSegmentId
        \o message.securityCode
        \o message.symbol
        \o message.symbolIsin

DecodeSecurityListCancellationReportMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET marketId == ReadBytes(sequenceNumber.rest, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(marketId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET securityCode == ReadBytes(marketSegmentId.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET symbol == ReadBytes(securityCode.rest, 22) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolIsin == ReadBytes(symbol.rest, 12) IN IF ~symbolIsin.ok THEN Fail ELSE
    Ok([ sequenceNumber  |-> sequenceNumber.value,
         marketId        |-> marketId.value,
         marketSegmentId |-> marketSegmentId.value,
         securityCode    |-> securityCode.value,
         symbol          |-> symbol.value,
         symbolIsin      |-> symbolIsin.value ], symbolIsin.rest)

ZeroSecurityListCancellationReportMessage ==
    [ sequenceNumber  |-> [i \in 1 .. 4 |-> 0],
      marketId        |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId |-> [i \in 1 .. 4 |-> 0],
      securityCode    |-> [i \in 1 .. 4 |-> 0],
      symbol          |-> [i \in 1 .. 22 |-> 0],
      symbolIsin      |-> [i \in 1 .. 12 |-> 0] ]

(* Security List Cancellation Report Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityListCancellationReportMessage ==
    { ZeroSecurityListCancellationReportMessage }
        \cup { [ZeroSecurityListCancellationReportMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListCancellationReportMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListCancellationReportMessage EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListCancellationReportMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListCancellationReportMessage EXCEPT !.symbol = one] : one \in Sample(22) }
        \cup { [ZeroSecurityListCancellationReportMessage EXCEPT !.symbolIsin = one] : one \in Sample(12) }

(***************************************************************************)
(* Statistics Repeating Group: 9 bytes                                     *)
(***************************************************************************)

StatisticsRepeatingGroup ==
    [ dataCode  : Sample(1),
      dataValue : Sample(8) ]

EncodeStatisticsRepeatingGroup(message) ==
    message.dataCode
        \o message.dataValue

DecodeStatisticsRepeatingGroup(bytes) ==
    LET dataCode == ReadBytes(bytes, 1) IN IF ~dataCode.ok THEN Fail ELSE
    LET dataValue == ReadBytes(dataCode.rest, 8) IN IF ~dataValue.ok THEN Fail ELSE
    Ok([ dataCode  |-> dataCode.value,
         dataValue |-> dataValue.value ], dataValue.rest)

ZeroStatisticsRepeatingGroup ==
    [ dataCode  |-> [i \in 1 .. 1 |-> 0],
      dataValue |-> [i \in 1 .. 8 |-> 0] ]

(* Statistics Repeating Group at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsRepeatingGroup ==
    { ZeroStatisticsRepeatingGroup }
        \cup { [ZeroStatisticsRepeatingGroup EXCEPT !.dataCode = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsRepeatingGroup EXCEPT !.dataValue = one] : one \in Sample(8) }

(* A run of Statistics Repeating Group, written one after another *)
RECURSIVE EncodeStatisticsRepeatingGroupList(_)
EncodeStatisticsRepeatingGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStatisticsRepeatingGroup(Head(messages)) \o EncodeStatisticsRepeatingGroupList(Tail(messages))

(* As many Statistics Repeating Group as the field that counts them says *)
RECURSIVE ReadStatisticsRepeatingGroupList(_, _)
ReadStatisticsRepeatingGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeStatisticsRepeatingGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStatisticsRepeatingGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Statistics Repeating Group of each kind, for the lists that carry them *)
OneStatisticsRepeatingGroup == { ZeroStatisticsRepeatingGroup }

(***************************************************************************)
(* Statistics Message                                                      *)
(***************************************************************************)

StatisticsMessage ==
    [ sequenceNumber           : Sample(4),
      securityCode             : Sample(4),
      transactionDateAndTime   : Sample(8),
      statisticsRepeatingGroup : SampleLists(OneStatisticsRepeatingGroup) ]

EncodeStatisticsMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime
        \o EncodeUIntLE(Len(message.statisticsRepeatingGroup), 1)
        \o EncodeStatisticsRepeatingGroupList(message.statisticsRepeatingGroup)

DecodeStatisticsMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET dataCount == ReadUIntLE(transactionDateAndTime.rest, 1) IN IF ~dataCount.ok THEN Fail ELSE
    LET statisticsRepeatingGroup == ReadStatisticsRepeatingGroupList(dataCount.rest, dataCount.value) IN IF ~statisticsRepeatingGroup.ok THEN Fail ELSE
    Ok([ sequenceNumber           |-> sequenceNumber.value,
         securityCode             |-> securityCode.value,
         transactionDateAndTime   |-> transactionDateAndTime.value,
         statisticsRepeatingGroup |-> statisticsRepeatingGroup.value ], statisticsRepeatingGroup.rest)

ZeroStatisticsMessage ==
    [ sequenceNumber           |-> [i \in 1 .. 4 |-> 0],
      securityCode             |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime   |-> [i \in 1 .. 8 |-> 0],
      statisticsRepeatingGroup |-> << >> ]

(* Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsMessage ==
    { ZeroStatisticsMessage }
        \cup { [ZeroStatisticsMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.statisticsRepeatingGroup = one] : one \in SampleLists(OneStatisticsRepeatingGroup) }

(***************************************************************************)
(* Security List Message: 450 bytes                                        *)
(***************************************************************************)

SecurityListMessage ==
    [ sequenceNumber                      : Sample(4),
      marketId                            : Sample(4),
      marketSegmentId                     : Sample(4),
      securityCode                        : Sample(4),
      symbol                              : Sample(22),
      symbolIsin                          : Sample(12),
      fisn                                : Sample(35),
      issuerLei                           : Sample(20),
      securityGroup                       : Sample(2),
      cfiCode                             : Sample(6),
      securityType                        : Sample(2),
      maturityDate                        : Sample(4),
      issueDate                           : Sample(4),
      contractMultiplier                  : Sample(8),
      liSpre                              : Sample(8),
      sstIpre                             : Sample(8),
      liSpost                             : Sample(8),
      sstIpost                            : Sample(8),
      liquidInstrument                    : Sample(1),
      admissionRequestedByIssuer          : Sample(1),
      minTradeVol                         : Sample(4),
      roundLot                            : Sample(4),
      currency                            : Sample(3),
      modalityMaskB4                      : Sample(4),
      securityDescription                 : Sample(80),
      tradingObligation                   : Sample(1),
      securityName                        : Sample(40),
      securityStatus                      : Sample(1),
      couponPaymentDate                   : Sample(4),
      minPriceIncrement                   : Sample(8),
      numberOfDecimals                    : Sample(1),
      orderNumberOfDecimals               : Sample(1),
      couponRate                          : Sample(8),
      issuer                              : Sample(12),
      tradingScopeB1                      : Sample(1),
      firstTradingDate                    : Sample(4),
      settlementSystem                    : Sample(1),
      maturity                            : Sample(8),
      couponPeriodicity                   : Sample(1),
      benchmark                           : Sample(1),
      strippable                          : Sample(1),
      volumeIssued                        : Sample(8),
      aliveVolume                         : Sample(8),
      couponType                          : Sample(1),
      couponQuotation                     : Sample(1),
      accruedInterestCalculationProcedure : Sample(1),
      nextRedemptionDate                  : Sample(4),
      typeOfRedemption                    : Sample(2),
      facial                              : Sample(8),
      calculationMethod                   : Sample(1),
      dateLastCouponWasPaid               : Sample(4),
      bondSeniority                       : Sample(4),
      interestAccrualDate                 : Sample(4),
      startDate                           : Sample(4),
      priceType                           : Sample(1),
      spreadToIndex                       : Sample(8),
      benchmarkCurvePointsUnits           : Sample(4),
      benchmarkCurvePointsValue           : Sample(1),
      benchmarkSecurityId                 : Sample(25),
      accruedInterestRateR8               : Sample(8) ]

EncodeSecurityListMessage(message) ==
    message.sequenceNumber
        \o message.marketId
        \o message.marketSegmentId
        \o message.securityCode
        \o message.symbol
        \o message.symbolIsin
        \o message.fisn
        \o message.issuerLei
        \o message.securityGroup
        \o message.cfiCode
        \o message.securityType
        \o message.maturityDate
        \o message.issueDate
        \o message.contractMultiplier
        \o message.liSpre
        \o message.sstIpre
        \o message.liSpost
        \o message.sstIpost
        \o message.liquidInstrument
        \o message.admissionRequestedByIssuer
        \o message.minTradeVol
        \o message.roundLot
        \o message.currency
        \o message.modalityMaskB4
        \o message.securityDescription
        \o message.tradingObligation
        \o message.securityName
        \o message.securityStatus
        \o message.couponPaymentDate
        \o message.minPriceIncrement
        \o message.numberOfDecimals
        \o message.orderNumberOfDecimals
        \o message.couponRate
        \o message.issuer
        \o message.tradingScopeB1
        \o message.firstTradingDate
        \o message.settlementSystem
        \o message.maturity
        \o message.couponPeriodicity
        \o message.benchmark
        \o message.strippable
        \o message.volumeIssued
        \o message.aliveVolume
        \o message.couponType
        \o message.couponQuotation
        \o message.accruedInterestCalculationProcedure
        \o message.nextRedemptionDate
        \o message.typeOfRedemption
        \o message.facial
        \o message.calculationMethod
        \o message.dateLastCouponWasPaid
        \o message.bondSeniority
        \o message.interestAccrualDate
        \o message.startDate
        \o message.priceType
        \o message.spreadToIndex
        \o message.benchmarkCurvePointsUnits
        \o message.benchmarkCurvePointsValue
        \o message.benchmarkSecurityId
        \o message.accruedInterestRateR8

DecodeSecurityListMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET marketId == ReadBytes(sequenceNumber.rest, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(marketId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET securityCode == ReadBytes(marketSegmentId.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET symbol == ReadBytes(securityCode.rest, 22) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolIsin == ReadBytes(symbol.rest, 12) IN IF ~symbolIsin.ok THEN Fail ELSE
    LET fisn == ReadBytes(symbolIsin.rest, 35) IN IF ~fisn.ok THEN Fail ELSE
    LET issuerLei == ReadBytes(fisn.rest, 20) IN IF ~issuerLei.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(issuerLei.rest, 2) IN IF ~securityGroup.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(securityGroup.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET securityType == ReadBytes(cfiCode.rest, 2) IN IF ~securityType.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(securityType.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET issueDate == ReadBytes(maturityDate.rest, 4) IN IF ~issueDate.ok THEN Fail ELSE
    LET contractMultiplier == ReadBytes(issueDate.rest, 8) IN IF ~contractMultiplier.ok THEN Fail ELSE
    LET liSpre == ReadBytes(contractMultiplier.rest, 8) IN IF ~liSpre.ok THEN Fail ELSE
    LET sstIpre == ReadBytes(liSpre.rest, 8) IN IF ~sstIpre.ok THEN Fail ELSE
    LET liSpost == ReadBytes(sstIpre.rest, 8) IN IF ~liSpost.ok THEN Fail ELSE
    LET sstIpost == ReadBytes(liSpost.rest, 8) IN IF ~sstIpost.ok THEN Fail ELSE
    LET liquidInstrument == ReadBytes(sstIpost.rest, 1) IN IF ~liquidInstrument.ok THEN Fail ELSE
    LET admissionRequestedByIssuer == ReadBytes(liquidInstrument.rest, 1) IN IF ~admissionRequestedByIssuer.ok THEN Fail ELSE
    LET minTradeVol == ReadBytes(admissionRequestedByIssuer.rest, 4) IN IF ~minTradeVol.ok THEN Fail ELSE
    LET roundLot == ReadBytes(minTradeVol.rest, 4) IN IF ~roundLot.ok THEN Fail ELSE
    LET currency == ReadBytes(roundLot.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET modalityMaskB4 == ReadBytes(currency.rest, 4) IN IF ~modalityMaskB4.ok THEN Fail ELSE
    LET securityDescription == ReadBytes(modalityMaskB4.rest, 80) IN IF ~securityDescription.ok THEN Fail ELSE
    LET tradingObligation == ReadBytes(securityDescription.rest, 1) IN IF ~tradingObligation.ok THEN Fail ELSE
    LET securityName == ReadBytes(tradingObligation.rest, 40) IN IF ~securityName.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(securityName.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET couponPaymentDate == ReadBytes(securityStatus.rest, 4) IN IF ~couponPaymentDate.ok THEN Fail ELSE
    LET minPriceIncrement == ReadBytes(couponPaymentDate.rest, 8) IN IF ~minPriceIncrement.ok THEN Fail ELSE
    LET numberOfDecimals == ReadBytes(minPriceIncrement.rest, 1) IN IF ~numberOfDecimals.ok THEN Fail ELSE
    LET orderNumberOfDecimals == ReadBytes(numberOfDecimals.rest, 1) IN IF ~orderNumberOfDecimals.ok THEN Fail ELSE
    LET couponRate == ReadBytes(orderNumberOfDecimals.rest, 8) IN IF ~couponRate.ok THEN Fail ELSE
    LET issuer == ReadBytes(couponRate.rest, 12) IN IF ~issuer.ok THEN Fail ELSE
    LET tradingScopeB1 == ReadBytes(issuer.rest, 1) IN IF ~tradingScopeB1.ok THEN Fail ELSE
    LET firstTradingDate == ReadBytes(tradingScopeB1.rest, 4) IN IF ~firstTradingDate.ok THEN Fail ELSE
    LET settlementSystem == ReadBytes(firstTradingDate.rest, 1) IN IF ~settlementSystem.ok THEN Fail ELSE
    LET maturity == ReadBytes(settlementSystem.rest, 8) IN IF ~maturity.ok THEN Fail ELSE
    LET couponPeriodicity == ReadBytes(maturity.rest, 1) IN IF ~couponPeriodicity.ok THEN Fail ELSE
    LET benchmark == ReadBytes(couponPeriodicity.rest, 1) IN IF ~benchmark.ok THEN Fail ELSE
    LET strippable == ReadBytes(benchmark.rest, 1) IN IF ~strippable.ok THEN Fail ELSE
    LET volumeIssued == ReadBytes(strippable.rest, 8) IN IF ~volumeIssued.ok THEN Fail ELSE
    LET aliveVolume == ReadBytes(volumeIssued.rest, 8) IN IF ~aliveVolume.ok THEN Fail ELSE
    LET couponType == ReadBytes(aliveVolume.rest, 1) IN IF ~couponType.ok THEN Fail ELSE
    LET couponQuotation == ReadBytes(couponType.rest, 1) IN IF ~couponQuotation.ok THEN Fail ELSE
    LET accruedInterestCalculationProcedure == ReadBytes(couponQuotation.rest, 1) IN IF ~accruedInterestCalculationProcedure.ok THEN Fail ELSE
    LET nextRedemptionDate == ReadBytes(accruedInterestCalculationProcedure.rest, 4) IN IF ~nextRedemptionDate.ok THEN Fail ELSE
    LET typeOfRedemption == ReadBytes(nextRedemptionDate.rest, 2) IN IF ~typeOfRedemption.ok THEN Fail ELSE
    LET facial == ReadBytes(typeOfRedemption.rest, 8) IN IF ~facial.ok THEN Fail ELSE
    LET calculationMethod == ReadBytes(facial.rest, 1) IN IF ~calculationMethod.ok THEN Fail ELSE
    LET dateLastCouponWasPaid == ReadBytes(calculationMethod.rest, 4) IN IF ~dateLastCouponWasPaid.ok THEN Fail ELSE
    LET bondSeniority == ReadBytes(dateLastCouponWasPaid.rest, 4) IN IF ~bondSeniority.ok THEN Fail ELSE
    LET interestAccrualDate == ReadBytes(bondSeniority.rest, 4) IN IF ~interestAccrualDate.ok THEN Fail ELSE
    LET startDate == ReadBytes(interestAccrualDate.rest, 4) IN IF ~startDate.ok THEN Fail ELSE
    LET priceType == ReadBytes(startDate.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET spreadToIndex == ReadBytes(priceType.rest, 8) IN IF ~spreadToIndex.ok THEN Fail ELSE
    LET benchmarkCurvePointsUnits == ReadBytes(spreadToIndex.rest, 4) IN IF ~benchmarkCurvePointsUnits.ok THEN Fail ELSE
    LET benchmarkCurvePointsValue == ReadBytes(benchmarkCurvePointsUnits.rest, 1) IN IF ~benchmarkCurvePointsValue.ok THEN Fail ELSE
    LET benchmarkSecurityId == ReadBytes(benchmarkCurvePointsValue.rest, 25) IN IF ~benchmarkSecurityId.ok THEN Fail ELSE
    LET accruedInterestRateR8 == ReadBytes(benchmarkSecurityId.rest, 8) IN IF ~accruedInterestRateR8.ok THEN Fail ELSE
    Ok([ sequenceNumber                      |-> sequenceNumber.value,
         marketId                            |-> marketId.value,
         marketSegmentId                     |-> marketSegmentId.value,
         securityCode                        |-> securityCode.value,
         symbol                              |-> symbol.value,
         symbolIsin                          |-> symbolIsin.value,
         fisn                                |-> fisn.value,
         issuerLei                           |-> issuerLei.value,
         securityGroup                       |-> securityGroup.value,
         cfiCode                             |-> cfiCode.value,
         securityType                        |-> securityType.value,
         maturityDate                        |-> maturityDate.value,
         issueDate                           |-> issueDate.value,
         contractMultiplier                  |-> contractMultiplier.value,
         liSpre                              |-> liSpre.value,
         sstIpre                             |-> sstIpre.value,
         liSpost                             |-> liSpost.value,
         sstIpost                            |-> sstIpost.value,
         liquidInstrument                    |-> liquidInstrument.value,
         admissionRequestedByIssuer          |-> admissionRequestedByIssuer.value,
         minTradeVol                         |-> minTradeVol.value,
         roundLot                            |-> roundLot.value,
         currency                            |-> currency.value,
         modalityMaskB4                      |-> modalityMaskB4.value,
         securityDescription                 |-> securityDescription.value,
         tradingObligation                   |-> tradingObligation.value,
         securityName                        |-> securityName.value,
         securityStatus                      |-> securityStatus.value,
         couponPaymentDate                   |-> couponPaymentDate.value,
         minPriceIncrement                   |-> minPriceIncrement.value,
         numberOfDecimals                    |-> numberOfDecimals.value,
         orderNumberOfDecimals               |-> orderNumberOfDecimals.value,
         couponRate                          |-> couponRate.value,
         issuer                              |-> issuer.value,
         tradingScopeB1                      |-> tradingScopeB1.value,
         firstTradingDate                    |-> firstTradingDate.value,
         settlementSystem                    |-> settlementSystem.value,
         maturity                            |-> maturity.value,
         couponPeriodicity                   |-> couponPeriodicity.value,
         benchmark                           |-> benchmark.value,
         strippable                          |-> strippable.value,
         volumeIssued                        |-> volumeIssued.value,
         aliveVolume                         |-> aliveVolume.value,
         couponType                          |-> couponType.value,
         couponQuotation                     |-> couponQuotation.value,
         accruedInterestCalculationProcedure |-> accruedInterestCalculationProcedure.value,
         nextRedemptionDate                  |-> nextRedemptionDate.value,
         typeOfRedemption                    |-> typeOfRedemption.value,
         facial                              |-> facial.value,
         calculationMethod                   |-> calculationMethod.value,
         dateLastCouponWasPaid               |-> dateLastCouponWasPaid.value,
         bondSeniority                       |-> bondSeniority.value,
         interestAccrualDate                 |-> interestAccrualDate.value,
         startDate                           |-> startDate.value,
         priceType                           |-> priceType.value,
         spreadToIndex                       |-> spreadToIndex.value,
         benchmarkCurvePointsUnits           |-> benchmarkCurvePointsUnits.value,
         benchmarkCurvePointsValue           |-> benchmarkCurvePointsValue.value,
         benchmarkSecurityId                 |-> benchmarkSecurityId.value,
         accruedInterestRateR8               |-> accruedInterestRateR8.value ], accruedInterestRateR8.rest)

ZeroSecurityListMessage ==
    [ sequenceNumber                      |-> [i \in 1 .. 4 |-> 0],
      marketId                            |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                     |-> [i \in 1 .. 4 |-> 0],
      securityCode                        |-> [i \in 1 .. 4 |-> 0],
      symbol                              |-> [i \in 1 .. 22 |-> 0],
      symbolIsin                          |-> [i \in 1 .. 12 |-> 0],
      fisn                                |-> [i \in 1 .. 35 |-> 0],
      issuerLei                           |-> [i \in 1 .. 20 |-> 0],
      securityGroup                       |-> [i \in 1 .. 2 |-> 0],
      cfiCode                             |-> [i \in 1 .. 6 |-> 0],
      securityType                        |-> [i \in 1 .. 2 |-> 0],
      maturityDate                        |-> [i \in 1 .. 4 |-> 0],
      issueDate                           |-> [i \in 1 .. 4 |-> 0],
      contractMultiplier                  |-> [i \in 1 .. 8 |-> 0],
      liSpre                              |-> [i \in 1 .. 8 |-> 0],
      sstIpre                             |-> [i \in 1 .. 8 |-> 0],
      liSpost                             |-> [i \in 1 .. 8 |-> 0],
      sstIpost                            |-> [i \in 1 .. 8 |-> 0],
      liquidInstrument                    |-> [i \in 1 .. 1 |-> 0],
      admissionRequestedByIssuer          |-> [i \in 1 .. 1 |-> 0],
      minTradeVol                         |-> [i \in 1 .. 4 |-> 0],
      roundLot                            |-> [i \in 1 .. 4 |-> 0],
      currency                            |-> [i \in 1 .. 3 |-> 0],
      modalityMaskB4                      |-> [i \in 1 .. 4 |-> 0],
      securityDescription                 |-> [i \in 1 .. 80 |-> 0],
      tradingObligation                   |-> [i \in 1 .. 1 |-> 0],
      securityName                        |-> [i \in 1 .. 40 |-> 0],
      securityStatus                      |-> [i \in 1 .. 1 |-> 0],
      couponPaymentDate                   |-> [i \in 1 .. 4 |-> 0],
      minPriceIncrement                   |-> [i \in 1 .. 8 |-> 0],
      numberOfDecimals                    |-> [i \in 1 .. 1 |-> 0],
      orderNumberOfDecimals               |-> [i \in 1 .. 1 |-> 0],
      couponRate                          |-> [i \in 1 .. 8 |-> 0],
      issuer                              |-> [i \in 1 .. 12 |-> 0],
      tradingScopeB1                      |-> [i \in 1 .. 1 |-> 0],
      firstTradingDate                    |-> [i \in 1 .. 4 |-> 0],
      settlementSystem                    |-> [i \in 1 .. 1 |-> 0],
      maturity                            |-> [i \in 1 .. 8 |-> 0],
      couponPeriodicity                   |-> [i \in 1 .. 1 |-> 0],
      benchmark                           |-> [i \in 1 .. 1 |-> 0],
      strippable                          |-> [i \in 1 .. 1 |-> 0],
      volumeIssued                        |-> [i \in 1 .. 8 |-> 0],
      aliveVolume                         |-> [i \in 1 .. 8 |-> 0],
      couponType                          |-> [i \in 1 .. 1 |-> 0],
      couponQuotation                     |-> [i \in 1 .. 1 |-> 0],
      accruedInterestCalculationProcedure |-> [i \in 1 .. 1 |-> 0],
      nextRedemptionDate                  |-> [i \in 1 .. 4 |-> 0],
      typeOfRedemption                    |-> [i \in 1 .. 2 |-> 0],
      facial                              |-> [i \in 1 .. 8 |-> 0],
      calculationMethod                   |-> [i \in 1 .. 1 |-> 0],
      dateLastCouponWasPaid               |-> [i \in 1 .. 4 |-> 0],
      bondSeniority                       |-> [i \in 1 .. 4 |-> 0],
      interestAccrualDate                 |-> [i \in 1 .. 4 |-> 0],
      startDate                           |-> [i \in 1 .. 4 |-> 0],
      priceType                           |-> [i \in 1 .. 1 |-> 0],
      spreadToIndex                       |-> [i \in 1 .. 8 |-> 0],
      benchmarkCurvePointsUnits           |-> [i \in 1 .. 4 |-> 0],
      benchmarkCurvePointsValue           |-> [i \in 1 .. 1 |-> 0],
      benchmarkSecurityId                 |-> [i \in 1 .. 25 |-> 0],
      accruedInterestRateR8               |-> [i \in 1 .. 8 |-> 0] ]

(* Security List Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityListMessage ==
    { ZeroSecurityListMessage }
        \cup { [ZeroSecurityListMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.symbol = one] : one \in Sample(22) }
        \cup { [ZeroSecurityListMessage EXCEPT !.symbolIsin = one] : one \in Sample(12) }
        \cup { [ZeroSecurityListMessage EXCEPT !.fisn = one] : one \in Sample(35) }
        \cup { [ZeroSecurityListMessage EXCEPT !.issuerLei = one] : one \in Sample(20) }
        \cup { [ZeroSecurityListMessage EXCEPT !.securityGroup = one] : one \in Sample(2) }
        \cup { [ZeroSecurityListMessage EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroSecurityListMessage EXCEPT !.securityType = one] : one \in Sample(2) }
        \cup { [ZeroSecurityListMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.issueDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.contractMultiplier = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.liSpre = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.sstIpre = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.liSpost = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.sstIpost = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.liquidInstrument = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.admissionRequestedByIssuer = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.minTradeVol = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.roundLot = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityListMessage EXCEPT !.modalityMaskB4 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.securityDescription = one] : one \in Sample(80) }
        \cup { [ZeroSecurityListMessage EXCEPT !.tradingObligation = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.securityName = one] : one \in Sample(40) }
        \cup { [ZeroSecurityListMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.couponPaymentDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.minPriceIncrement = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.numberOfDecimals = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.orderNumberOfDecimals = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.couponRate = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.issuer = one] : one \in Sample(12) }
        \cup { [ZeroSecurityListMessage EXCEPT !.tradingScopeB1 = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.firstTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.settlementSystem = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.maturity = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.couponPeriodicity = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.benchmark = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.strippable = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.volumeIssued = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.aliveVolume = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.couponType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.couponQuotation = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.accruedInterestCalculationProcedure = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.nextRedemptionDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.typeOfRedemption = one] : one \in Sample(2) }
        \cup { [ZeroSecurityListMessage EXCEPT !.facial = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.calculationMethod = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.dateLastCouponWasPaid = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.bondSeniority = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.interestAccrualDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.startDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.spreadToIndex = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.benchmarkCurvePointsUnits = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.benchmarkCurvePointsValue = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.benchmarkSecurityId = one] : one \in Sample(25) }
        \cup { [ZeroSecurityListMessage EXCEPT !.accruedInterestRateR8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Security List Update Report Message: 450 bytes                          *)
(***************************************************************************)

SecurityListUpdateReportMessage ==
    [ sequenceNumber                      : Sample(4),
      marketId                            : Sample(4),
      marketSegmentId                     : Sample(4),
      securityCode                        : Sample(4),
      symbol                              : Sample(22),
      symbolIsin                          : Sample(12),
      fisn                                : Sample(35),
      issuerLei                           : Sample(20),
      securityGroup                       : Sample(2),
      cfiCode                             : Sample(6),
      securityType                        : Sample(2),
      maturityDate                        : Sample(4),
      issueDate                           : Sample(4),
      contractMultiplier                  : Sample(8),
      liSpre                              : Sample(8),
      sstIpre                             : Sample(8),
      liSpost                             : Sample(8),
      sstIpost                            : Sample(8),
      liquidInstrument                    : Sample(1),
      admissionRequestedByIssuer          : Sample(1),
      minTradeVol                         : Sample(4),
      roundLot                            : Sample(4),
      currency                            : Sample(3),
      modalityMaskB4                      : Sample(4),
      securityDescription                 : Sample(80),
      tradingObligation                   : Sample(1),
      securityName                        : Sample(40),
      securityStatus                      : Sample(1),
      couponPaymentDate                   : Sample(4),
      minPriceIncrement                   : Sample(8),
      numberOfDecimals                    : Sample(1),
      orderNumberOfDecimals               : Sample(1),
      couponRate                          : Sample(8),
      issuer                              : Sample(12),
      tradingScopeB1                      : Sample(1),
      firstTradingDate                    : Sample(4),
      settlementSystem                    : Sample(1),
      maturity                            : Sample(8),
      couponPeriodicity                   : Sample(1),
      benchmark                           : Sample(1),
      strippable                          : Sample(1),
      volumeIssued                        : Sample(8),
      aliveVolume                         : Sample(8),
      couponType                          : Sample(1),
      couponQuotation                     : Sample(1),
      accruedInterestCalculationProcedure : Sample(1),
      nextRedemptionDate                  : Sample(4),
      typeOfRedemption                    : Sample(2),
      facial                              : Sample(8),
      calculationMethod                   : Sample(1),
      dateLastCouponWasPaid               : Sample(4),
      bondSeniority                       : Sample(4),
      interestAccrualDate                 : Sample(4),
      startDate                           : Sample(4),
      priceType                           : Sample(1),
      spreadToIndex                       : Sample(8),
      benchmarkCurvePointsUnits           : Sample(4),
      benchmarkCurvePointsValue           : Sample(1),
      benchmarkSecurityId                 : Sample(25),
      accruedInterestRateR8               : Sample(8) ]

EncodeSecurityListUpdateReportMessage(message) ==
    message.sequenceNumber
        \o message.marketId
        \o message.marketSegmentId
        \o message.securityCode
        \o message.symbol
        \o message.symbolIsin
        \o message.fisn
        \o message.issuerLei
        \o message.securityGroup
        \o message.cfiCode
        \o message.securityType
        \o message.maturityDate
        \o message.issueDate
        \o message.contractMultiplier
        \o message.liSpre
        \o message.sstIpre
        \o message.liSpost
        \o message.sstIpost
        \o message.liquidInstrument
        \o message.admissionRequestedByIssuer
        \o message.minTradeVol
        \o message.roundLot
        \o message.currency
        \o message.modalityMaskB4
        \o message.securityDescription
        \o message.tradingObligation
        \o message.securityName
        \o message.securityStatus
        \o message.couponPaymentDate
        \o message.minPriceIncrement
        \o message.numberOfDecimals
        \o message.orderNumberOfDecimals
        \o message.couponRate
        \o message.issuer
        \o message.tradingScopeB1
        \o message.firstTradingDate
        \o message.settlementSystem
        \o message.maturity
        \o message.couponPeriodicity
        \o message.benchmark
        \o message.strippable
        \o message.volumeIssued
        \o message.aliveVolume
        \o message.couponType
        \o message.couponQuotation
        \o message.accruedInterestCalculationProcedure
        \o message.nextRedemptionDate
        \o message.typeOfRedemption
        \o message.facial
        \o message.calculationMethod
        \o message.dateLastCouponWasPaid
        \o message.bondSeniority
        \o message.interestAccrualDate
        \o message.startDate
        \o message.priceType
        \o message.spreadToIndex
        \o message.benchmarkCurvePointsUnits
        \o message.benchmarkCurvePointsValue
        \o message.benchmarkSecurityId
        \o message.accruedInterestRateR8

DecodeSecurityListUpdateReportMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET marketId == ReadBytes(sequenceNumber.rest, 4) IN IF ~marketId.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(marketId.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET securityCode == ReadBytes(marketSegmentId.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET symbol == ReadBytes(securityCode.rest, 22) IN IF ~symbol.ok THEN Fail ELSE
    LET symbolIsin == ReadBytes(symbol.rest, 12) IN IF ~symbolIsin.ok THEN Fail ELSE
    LET fisn == ReadBytes(symbolIsin.rest, 35) IN IF ~fisn.ok THEN Fail ELSE
    LET issuerLei == ReadBytes(fisn.rest, 20) IN IF ~issuerLei.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(issuerLei.rest, 2) IN IF ~securityGroup.ok THEN Fail ELSE
    LET cfiCode == ReadBytes(securityGroup.rest, 6) IN IF ~cfiCode.ok THEN Fail ELSE
    LET securityType == ReadBytes(cfiCode.rest, 2) IN IF ~securityType.ok THEN Fail ELSE
    LET maturityDate == ReadBytes(securityType.rest, 4) IN IF ~maturityDate.ok THEN Fail ELSE
    LET issueDate == ReadBytes(maturityDate.rest, 4) IN IF ~issueDate.ok THEN Fail ELSE
    LET contractMultiplier == ReadBytes(issueDate.rest, 8) IN IF ~contractMultiplier.ok THEN Fail ELSE
    LET liSpre == ReadBytes(contractMultiplier.rest, 8) IN IF ~liSpre.ok THEN Fail ELSE
    LET sstIpre == ReadBytes(liSpre.rest, 8) IN IF ~sstIpre.ok THEN Fail ELSE
    LET liSpost == ReadBytes(sstIpre.rest, 8) IN IF ~liSpost.ok THEN Fail ELSE
    LET sstIpost == ReadBytes(liSpost.rest, 8) IN IF ~sstIpost.ok THEN Fail ELSE
    LET liquidInstrument == ReadBytes(sstIpost.rest, 1) IN IF ~liquidInstrument.ok THEN Fail ELSE
    LET admissionRequestedByIssuer == ReadBytes(liquidInstrument.rest, 1) IN IF ~admissionRequestedByIssuer.ok THEN Fail ELSE
    LET minTradeVol == ReadBytes(admissionRequestedByIssuer.rest, 4) IN IF ~minTradeVol.ok THEN Fail ELSE
    LET roundLot == ReadBytes(minTradeVol.rest, 4) IN IF ~roundLot.ok THEN Fail ELSE
    LET currency == ReadBytes(roundLot.rest, 3) IN IF ~currency.ok THEN Fail ELSE
    LET modalityMaskB4 == ReadBytes(currency.rest, 4) IN IF ~modalityMaskB4.ok THEN Fail ELSE
    LET securityDescription == ReadBytes(modalityMaskB4.rest, 80) IN IF ~securityDescription.ok THEN Fail ELSE
    LET tradingObligation == ReadBytes(securityDescription.rest, 1) IN IF ~tradingObligation.ok THEN Fail ELSE
    LET securityName == ReadBytes(tradingObligation.rest, 40) IN IF ~securityName.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(securityName.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET couponPaymentDate == ReadBytes(securityStatus.rest, 4) IN IF ~couponPaymentDate.ok THEN Fail ELSE
    LET minPriceIncrement == ReadBytes(couponPaymentDate.rest, 8) IN IF ~minPriceIncrement.ok THEN Fail ELSE
    LET numberOfDecimals == ReadBytes(minPriceIncrement.rest, 1) IN IF ~numberOfDecimals.ok THEN Fail ELSE
    LET orderNumberOfDecimals == ReadBytes(numberOfDecimals.rest, 1) IN IF ~orderNumberOfDecimals.ok THEN Fail ELSE
    LET couponRate == ReadBytes(orderNumberOfDecimals.rest, 8) IN IF ~couponRate.ok THEN Fail ELSE
    LET issuer == ReadBytes(couponRate.rest, 12) IN IF ~issuer.ok THEN Fail ELSE
    LET tradingScopeB1 == ReadBytes(issuer.rest, 1) IN IF ~tradingScopeB1.ok THEN Fail ELSE
    LET firstTradingDate == ReadBytes(tradingScopeB1.rest, 4) IN IF ~firstTradingDate.ok THEN Fail ELSE
    LET settlementSystem == ReadBytes(firstTradingDate.rest, 1) IN IF ~settlementSystem.ok THEN Fail ELSE
    LET maturity == ReadBytes(settlementSystem.rest, 8) IN IF ~maturity.ok THEN Fail ELSE
    LET couponPeriodicity == ReadBytes(maturity.rest, 1) IN IF ~couponPeriodicity.ok THEN Fail ELSE
    LET benchmark == ReadBytes(couponPeriodicity.rest, 1) IN IF ~benchmark.ok THEN Fail ELSE
    LET strippable == ReadBytes(benchmark.rest, 1) IN IF ~strippable.ok THEN Fail ELSE
    LET volumeIssued == ReadBytes(strippable.rest, 8) IN IF ~volumeIssued.ok THEN Fail ELSE
    LET aliveVolume == ReadBytes(volumeIssued.rest, 8) IN IF ~aliveVolume.ok THEN Fail ELSE
    LET couponType == ReadBytes(aliveVolume.rest, 1) IN IF ~couponType.ok THEN Fail ELSE
    LET couponQuotation == ReadBytes(couponType.rest, 1) IN IF ~couponQuotation.ok THEN Fail ELSE
    LET accruedInterestCalculationProcedure == ReadBytes(couponQuotation.rest, 1) IN IF ~accruedInterestCalculationProcedure.ok THEN Fail ELSE
    LET nextRedemptionDate == ReadBytes(accruedInterestCalculationProcedure.rest, 4) IN IF ~nextRedemptionDate.ok THEN Fail ELSE
    LET typeOfRedemption == ReadBytes(nextRedemptionDate.rest, 2) IN IF ~typeOfRedemption.ok THEN Fail ELSE
    LET facial == ReadBytes(typeOfRedemption.rest, 8) IN IF ~facial.ok THEN Fail ELSE
    LET calculationMethod == ReadBytes(facial.rest, 1) IN IF ~calculationMethod.ok THEN Fail ELSE
    LET dateLastCouponWasPaid == ReadBytes(calculationMethod.rest, 4) IN IF ~dateLastCouponWasPaid.ok THEN Fail ELSE
    LET bondSeniority == ReadBytes(dateLastCouponWasPaid.rest, 4) IN IF ~bondSeniority.ok THEN Fail ELSE
    LET interestAccrualDate == ReadBytes(bondSeniority.rest, 4) IN IF ~interestAccrualDate.ok THEN Fail ELSE
    LET startDate == ReadBytes(interestAccrualDate.rest, 4) IN IF ~startDate.ok THEN Fail ELSE
    LET priceType == ReadBytes(startDate.rest, 1) IN IF ~priceType.ok THEN Fail ELSE
    LET spreadToIndex == ReadBytes(priceType.rest, 8) IN IF ~spreadToIndex.ok THEN Fail ELSE
    LET benchmarkCurvePointsUnits == ReadBytes(spreadToIndex.rest, 4) IN IF ~benchmarkCurvePointsUnits.ok THEN Fail ELSE
    LET benchmarkCurvePointsValue == ReadBytes(benchmarkCurvePointsUnits.rest, 1) IN IF ~benchmarkCurvePointsValue.ok THEN Fail ELSE
    LET benchmarkSecurityId == ReadBytes(benchmarkCurvePointsValue.rest, 25) IN IF ~benchmarkSecurityId.ok THEN Fail ELSE
    LET accruedInterestRateR8 == ReadBytes(benchmarkSecurityId.rest, 8) IN IF ~accruedInterestRateR8.ok THEN Fail ELSE
    Ok([ sequenceNumber                      |-> sequenceNumber.value,
         marketId                            |-> marketId.value,
         marketSegmentId                     |-> marketSegmentId.value,
         securityCode                        |-> securityCode.value,
         symbol                              |-> symbol.value,
         symbolIsin                          |-> symbolIsin.value,
         fisn                                |-> fisn.value,
         issuerLei                           |-> issuerLei.value,
         securityGroup                       |-> securityGroup.value,
         cfiCode                             |-> cfiCode.value,
         securityType                        |-> securityType.value,
         maturityDate                        |-> maturityDate.value,
         issueDate                           |-> issueDate.value,
         contractMultiplier                  |-> contractMultiplier.value,
         liSpre                              |-> liSpre.value,
         sstIpre                             |-> sstIpre.value,
         liSpost                             |-> liSpost.value,
         sstIpost                            |-> sstIpost.value,
         liquidInstrument                    |-> liquidInstrument.value,
         admissionRequestedByIssuer          |-> admissionRequestedByIssuer.value,
         minTradeVol                         |-> minTradeVol.value,
         roundLot                            |-> roundLot.value,
         currency                            |-> currency.value,
         modalityMaskB4                      |-> modalityMaskB4.value,
         securityDescription                 |-> securityDescription.value,
         tradingObligation                   |-> tradingObligation.value,
         securityName                        |-> securityName.value,
         securityStatus                      |-> securityStatus.value,
         couponPaymentDate                   |-> couponPaymentDate.value,
         minPriceIncrement                   |-> minPriceIncrement.value,
         numberOfDecimals                    |-> numberOfDecimals.value,
         orderNumberOfDecimals               |-> orderNumberOfDecimals.value,
         couponRate                          |-> couponRate.value,
         issuer                              |-> issuer.value,
         tradingScopeB1                      |-> tradingScopeB1.value,
         firstTradingDate                    |-> firstTradingDate.value,
         settlementSystem                    |-> settlementSystem.value,
         maturity                            |-> maturity.value,
         couponPeriodicity                   |-> couponPeriodicity.value,
         benchmark                           |-> benchmark.value,
         strippable                          |-> strippable.value,
         volumeIssued                        |-> volumeIssued.value,
         aliveVolume                         |-> aliveVolume.value,
         couponType                          |-> couponType.value,
         couponQuotation                     |-> couponQuotation.value,
         accruedInterestCalculationProcedure |-> accruedInterestCalculationProcedure.value,
         nextRedemptionDate                  |-> nextRedemptionDate.value,
         typeOfRedemption                    |-> typeOfRedemption.value,
         facial                              |-> facial.value,
         calculationMethod                   |-> calculationMethod.value,
         dateLastCouponWasPaid               |-> dateLastCouponWasPaid.value,
         bondSeniority                       |-> bondSeniority.value,
         interestAccrualDate                 |-> interestAccrualDate.value,
         startDate                           |-> startDate.value,
         priceType                           |-> priceType.value,
         spreadToIndex                       |-> spreadToIndex.value,
         benchmarkCurvePointsUnits           |-> benchmarkCurvePointsUnits.value,
         benchmarkCurvePointsValue           |-> benchmarkCurvePointsValue.value,
         benchmarkSecurityId                 |-> benchmarkSecurityId.value,
         accruedInterestRateR8               |-> accruedInterestRateR8.value ], accruedInterestRateR8.rest)

ZeroSecurityListUpdateReportMessage ==
    [ sequenceNumber                      |-> [i \in 1 .. 4 |-> 0],
      marketId                            |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                     |-> [i \in 1 .. 4 |-> 0],
      securityCode                        |-> [i \in 1 .. 4 |-> 0],
      symbol                              |-> [i \in 1 .. 22 |-> 0],
      symbolIsin                          |-> [i \in 1 .. 12 |-> 0],
      fisn                                |-> [i \in 1 .. 35 |-> 0],
      issuerLei                           |-> [i \in 1 .. 20 |-> 0],
      securityGroup                       |-> [i \in 1 .. 2 |-> 0],
      cfiCode                             |-> [i \in 1 .. 6 |-> 0],
      securityType                        |-> [i \in 1 .. 2 |-> 0],
      maturityDate                        |-> [i \in 1 .. 4 |-> 0],
      issueDate                           |-> [i \in 1 .. 4 |-> 0],
      contractMultiplier                  |-> [i \in 1 .. 8 |-> 0],
      liSpre                              |-> [i \in 1 .. 8 |-> 0],
      sstIpre                             |-> [i \in 1 .. 8 |-> 0],
      liSpost                             |-> [i \in 1 .. 8 |-> 0],
      sstIpost                            |-> [i \in 1 .. 8 |-> 0],
      liquidInstrument                    |-> [i \in 1 .. 1 |-> 0],
      admissionRequestedByIssuer          |-> [i \in 1 .. 1 |-> 0],
      minTradeVol                         |-> [i \in 1 .. 4 |-> 0],
      roundLot                            |-> [i \in 1 .. 4 |-> 0],
      currency                            |-> [i \in 1 .. 3 |-> 0],
      modalityMaskB4                      |-> [i \in 1 .. 4 |-> 0],
      securityDescription                 |-> [i \in 1 .. 80 |-> 0],
      tradingObligation                   |-> [i \in 1 .. 1 |-> 0],
      securityName                        |-> [i \in 1 .. 40 |-> 0],
      securityStatus                      |-> [i \in 1 .. 1 |-> 0],
      couponPaymentDate                   |-> [i \in 1 .. 4 |-> 0],
      minPriceIncrement                   |-> [i \in 1 .. 8 |-> 0],
      numberOfDecimals                    |-> [i \in 1 .. 1 |-> 0],
      orderNumberOfDecimals               |-> [i \in 1 .. 1 |-> 0],
      couponRate                          |-> [i \in 1 .. 8 |-> 0],
      issuer                              |-> [i \in 1 .. 12 |-> 0],
      tradingScopeB1                      |-> [i \in 1 .. 1 |-> 0],
      firstTradingDate                    |-> [i \in 1 .. 4 |-> 0],
      settlementSystem                    |-> [i \in 1 .. 1 |-> 0],
      maturity                            |-> [i \in 1 .. 8 |-> 0],
      couponPeriodicity                   |-> [i \in 1 .. 1 |-> 0],
      benchmark                           |-> [i \in 1 .. 1 |-> 0],
      strippable                          |-> [i \in 1 .. 1 |-> 0],
      volumeIssued                        |-> [i \in 1 .. 8 |-> 0],
      aliveVolume                         |-> [i \in 1 .. 8 |-> 0],
      couponType                          |-> [i \in 1 .. 1 |-> 0],
      couponQuotation                     |-> [i \in 1 .. 1 |-> 0],
      accruedInterestCalculationProcedure |-> [i \in 1 .. 1 |-> 0],
      nextRedemptionDate                  |-> [i \in 1 .. 4 |-> 0],
      typeOfRedemption                    |-> [i \in 1 .. 2 |-> 0],
      facial                              |-> [i \in 1 .. 8 |-> 0],
      calculationMethod                   |-> [i \in 1 .. 1 |-> 0],
      dateLastCouponWasPaid               |-> [i \in 1 .. 4 |-> 0],
      bondSeniority                       |-> [i \in 1 .. 4 |-> 0],
      interestAccrualDate                 |-> [i \in 1 .. 4 |-> 0],
      startDate                           |-> [i \in 1 .. 4 |-> 0],
      priceType                           |-> [i \in 1 .. 1 |-> 0],
      spreadToIndex                       |-> [i \in 1 .. 8 |-> 0],
      benchmarkCurvePointsUnits           |-> [i \in 1 .. 4 |-> 0],
      benchmarkCurvePointsValue           |-> [i \in 1 .. 1 |-> 0],
      benchmarkSecurityId                 |-> [i \in 1 .. 25 |-> 0],
      accruedInterestRateR8               |-> [i \in 1 .. 8 |-> 0] ]

(* Security List Update Report Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityListUpdateReportMessage ==
    { ZeroSecurityListUpdateReportMessage }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.marketId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.symbol = one] : one \in Sample(22) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.symbolIsin = one] : one \in Sample(12) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.fisn = one] : one \in Sample(35) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.issuerLei = one] : one \in Sample(20) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.securityGroup = one] : one \in Sample(2) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.cfiCode = one] : one \in Sample(6) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.securityType = one] : one \in Sample(2) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.maturityDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.issueDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.contractMultiplier = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.liSpre = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.sstIpre = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.liSpost = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.sstIpost = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.liquidInstrument = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.admissionRequestedByIssuer = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.minTradeVol = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.roundLot = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.currency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.modalityMaskB4 = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.securityDescription = one] : one \in Sample(80) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.tradingObligation = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.securityName = one] : one \in Sample(40) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.couponPaymentDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.minPriceIncrement = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.numberOfDecimals = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.orderNumberOfDecimals = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.couponRate = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.issuer = one] : one \in Sample(12) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.tradingScopeB1 = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.firstTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.settlementSystem = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.maturity = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.couponPeriodicity = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.benchmark = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.strippable = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.volumeIssued = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.aliveVolume = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.couponType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.couponQuotation = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.accruedInterestCalculationProcedure = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.nextRedemptionDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.typeOfRedemption = one] : one \in Sample(2) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.facial = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.calculationMethod = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.dateLastCouponWasPaid = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.bondSeniority = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.interestAccrualDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.startDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.priceType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.spreadToIndex = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.benchmarkCurvePointsUnits = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.benchmarkCurvePointsValue = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.benchmarkSecurityId = one] : one \in Sample(25) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.accruedInterestRateR8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Security Status Message: 59 bytes                                       *)
(***************************************************************************)

SecurityStatusMessage ==
    [ sequenceNumber         : Sample(4),
      securityCode           : Sample(4),
      transactionDateAndTime : Sample(8),
      referencePrice         : Sample(8),
      securityTradingStatus  : Sample(1),
      nonAvailabilityReason  : Sample(1),
      highLimitPrice         : Sample(8),
      lowLimitPrice          : Sample(8),
      staticRangeType        : Sample(1),
      orderStaticRange       : Sample(8),
      blockStaticRange       : Sample(8) ]

EncodeSecurityStatusMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime
        \o message.referencePrice
        \o message.securityTradingStatus
        \o message.nonAvailabilityReason
        \o message.highLimitPrice
        \o message.lowLimitPrice
        \o message.staticRangeType
        \o message.orderStaticRange
        \o message.blockStaticRange

DecodeSecurityStatusMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(transactionDateAndTime.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(referencePrice.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET nonAvailabilityReason == ReadBytes(securityTradingStatus.rest, 1) IN IF ~nonAvailabilityReason.ok THEN Fail ELSE
    LET highLimitPrice == ReadBytes(nonAvailabilityReason.rest, 8) IN IF ~highLimitPrice.ok THEN Fail ELSE
    LET lowLimitPrice == ReadBytes(highLimitPrice.rest, 8) IN IF ~lowLimitPrice.ok THEN Fail ELSE
    LET staticRangeType == ReadBytes(lowLimitPrice.rest, 1) IN IF ~staticRangeType.ok THEN Fail ELSE
    LET orderStaticRange == ReadBytes(staticRangeType.rest, 8) IN IF ~orderStaticRange.ok THEN Fail ELSE
    LET blockStaticRange == ReadBytes(orderStaticRange.rest, 8) IN IF ~blockStaticRange.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         securityCode           |-> securityCode.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         referencePrice         |-> referencePrice.value,
         securityTradingStatus  |-> securityTradingStatus.value,
         nonAvailabilityReason  |-> nonAvailabilityReason.value,
         highLimitPrice         |-> highLimitPrice.value,
         lowLimitPrice          |-> lowLimitPrice.value,
         staticRangeType        |-> staticRangeType.value,
         orderStaticRange       |-> orderStaticRange.value,
         blockStaticRange       |-> blockStaticRange.value ], blockStaticRange.rest)

ZeroSecurityStatusMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      securityCode           |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      referencePrice         |-> [i \in 1 .. 8 |-> 0],
      securityTradingStatus  |-> [i \in 1 .. 1 |-> 0],
      nonAvailabilityReason  |-> [i \in 1 .. 1 |-> 0],
      highLimitPrice         |-> [i \in 1 .. 8 |-> 0],
      lowLimitPrice          |-> [i \in 1 .. 8 |-> 0],
      staticRangeType        |-> [i \in 1 .. 1 |-> 0],
      orderStaticRange       |-> [i \in 1 .. 8 |-> 0],
      blockStaticRange       |-> [i \in 1 .. 8 |-> 0] ]

(* Security Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusMessage ==
    { ZeroSecurityStatusMessage }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.nonAvailabilityReason = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.staticRangeType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.orderStaticRange = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.blockStaticRange = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Book Clear Message: 16 bytes                                      *)
(***************************************************************************)

OrderBookClearMessage ==
    [ sequenceNumber         : Sample(4),
      securityCode           : Sample(4),
      transactionDateAndTime : Sample(8) ]

EncodeOrderBookClearMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime

DecodeOrderBookClearMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         securityCode           |-> securityCode.value,
         transactionDateAndTime |-> transactionDateAndTime.value ], transactionDateAndTime.rest)

ZeroOrderBookClearMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      securityCode           |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0] ]

(* Order Book Clear Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderBookClearMessage ==
    { ZeroOrderBookClearMessage }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroOrderBookClearMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Market Pre Transparency Information Message: 49 bytes             *)
(***************************************************************************)

OrderMarketPreTransparencyInformationMessage ==
    [ sequenceNumber         : Sample(4),
      securityCode           : Sample(4),
      transactionDateAndTime : Sample(8),
      secondaryOrderId       : Sample(4),
      entryDate              : Sample(4),
      side                   : Sample(1),
      priority               : Sample(4),
      price                  : Sample(8),
      displayQty             : Sample(4),
      altPrice               : Sample(8) ]

EncodeOrderMarketPreTransparencyInformationMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime
        \o message.secondaryOrderId
        \o message.entryDate
        \o message.side
        \o message.priority
        \o message.price
        \o message.displayQty
        \o message.altPrice

DecodeOrderMarketPreTransparencyInformationMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(transactionDateAndTime.rest, 4) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET entryDate == ReadBytes(secondaryOrderId.rest, 4) IN IF ~entryDate.ok THEN Fail ELSE
    LET side == ReadBytes(entryDate.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET priority == ReadBytes(side.rest, 4) IN IF ~priority.ok THEN Fail ELSE
    LET price == ReadBytes(priority.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET displayQty == ReadBytes(price.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET altPrice == ReadBytes(displayQty.rest, 8) IN IF ~altPrice.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         securityCode           |-> securityCode.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         secondaryOrderId       |-> secondaryOrderId.value,
         entryDate              |-> entryDate.value,
         side                   |-> side.value,
         priority               |-> priority.value,
         price                  |-> price.value,
         displayQty             |-> displayQty.value,
         altPrice               |-> altPrice.value ], altPrice.rest)

ZeroOrderMarketPreTransparencyInformationMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      securityCode           |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 4 |-> 0],
      entryDate              |-> [i \in 1 .. 4 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      priority               |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      displayQty             |-> [i \in 1 .. 4 |-> 0],
      altPrice               |-> [i \in 1 .. 8 |-> 0] ]

(* Order Market Pre Transparency Information Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMarketPreTransparencyInformationMessage ==
    { ZeroOrderMarketPreTransparencyInformationMessage }
        \cup { [ZeroOrderMarketPreTransparencyInformationMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderMarketPreTransparencyInformationMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroOrderMarketPreTransparencyInformationMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderMarketPreTransparencyInformationMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderMarketPreTransparencyInformationMessage EXCEPT !.entryDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderMarketPreTransparencyInformationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderMarketPreTransparencyInformationMessage EXCEPT !.priority = one] : one \in Sample(4) }
        \cup { [ZeroOrderMarketPreTransparencyInformationMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderMarketPreTransparencyInformationMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderMarketPreTransparencyInformationMessage EXCEPT !.altPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Market Pre Transparency Information Message: 72 bytes             *)
(***************************************************************************)

QuoteMarketPreTransparencyInformationMessage ==
    [ sequenceNumber         : Sample(4),
      securityCode           : Sample(4),
      transactionDateAndTime : Sample(8),
      secondaryOrderId       : Sample(4),
      secondaryOrderId2      : Sample(4),
      priority               : Sample(4),
      price                  : Sample(8),
      displayQty             : Sample(4),
      altPrice               : Sample(8),
      priority2              : Sample(4),
      price2                 : Sample(8),
      displayQty2            : Sample(4),
      altPrice2              : Sample(8) ]

EncodeQuoteMarketPreTransparencyInformationMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime
        \o message.secondaryOrderId
        \o message.secondaryOrderId2
        \o message.priority
        \o message.price
        \o message.displayQty
        \o message.altPrice
        \o message.priority2
        \o message.price2
        \o message.displayQty2
        \o message.altPrice2

DecodeQuoteMarketPreTransparencyInformationMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(transactionDateAndTime.rest, 4) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET secondaryOrderId2 == ReadBytes(secondaryOrderId.rest, 4) IN IF ~secondaryOrderId2.ok THEN Fail ELSE
    LET priority == ReadBytes(secondaryOrderId2.rest, 4) IN IF ~priority.ok THEN Fail ELSE
    LET price == ReadBytes(priority.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET displayQty == ReadBytes(price.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET altPrice == ReadBytes(displayQty.rest, 8) IN IF ~altPrice.ok THEN Fail ELSE
    LET priority2 == ReadBytes(altPrice.rest, 4) IN IF ~priority2.ok THEN Fail ELSE
    LET price2 == ReadBytes(priority2.rest, 8) IN IF ~price2.ok THEN Fail ELSE
    LET displayQty2 == ReadBytes(price2.rest, 4) IN IF ~displayQty2.ok THEN Fail ELSE
    LET altPrice2 == ReadBytes(displayQty2.rest, 8) IN IF ~altPrice2.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         securityCode           |-> securityCode.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         secondaryOrderId       |-> secondaryOrderId.value,
         secondaryOrderId2      |-> secondaryOrderId2.value,
         priority               |-> priority.value,
         price                  |-> price.value,
         displayQty             |-> displayQty.value,
         altPrice               |-> altPrice.value,
         priority2              |-> priority2.value,
         price2                 |-> price2.value,
         displayQty2            |-> displayQty2.value,
         altPrice2              |-> altPrice2.value ], altPrice2.rest)

ZeroQuoteMarketPreTransparencyInformationMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      securityCode           |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 4 |-> 0],
      secondaryOrderId2      |-> [i \in 1 .. 4 |-> 0],
      priority               |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      displayQty             |-> [i \in 1 .. 4 |-> 0],
      altPrice               |-> [i \in 1 .. 8 |-> 0],
      priority2              |-> [i \in 1 .. 4 |-> 0],
      price2                 |-> [i \in 1 .. 8 |-> 0],
      displayQty2            |-> [i \in 1 .. 4 |-> 0],
      altPrice2              |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Market Pre Transparency Information Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteMarketPreTransparencyInformationMessage ==
    { ZeroQuoteMarketPreTransparencyInformationMessage }
        \cup { [ZeroQuoteMarketPreTransparencyInformationMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMarketPreTransparencyInformationMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMarketPreTransparencyInformationMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMarketPreTransparencyInformationMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMarketPreTransparencyInformationMessage EXCEPT !.secondaryOrderId2 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMarketPreTransparencyInformationMessage EXCEPT !.priority = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMarketPreTransparencyInformationMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMarketPreTransparencyInformationMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMarketPreTransparencyInformationMessage EXCEPT !.altPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMarketPreTransparencyInformationMessage EXCEPT !.priority2 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMarketPreTransparencyInformationMessage EXCEPT !.price2 = one] : one \in Sample(8) }
        \cup { [ZeroQuoteMarketPreTransparencyInformationMessage EXCEPT !.displayQty2 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteMarketPreTransparencyInformationMessage EXCEPT !.altPrice2 = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancellation Market Member Message: 24 bytes                      *)
(***************************************************************************)

OrderCancellationMarketMemberMessage ==
    [ sequenceNumber         : Sample(4),
      securityCode           : Sample(4),
      transactionDateAndTime : Sample(8),
      secondaryOrderId       : Sample(4),
      entryDate              : Sample(4) ]

EncodeOrderCancellationMarketMemberMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime
        \o message.secondaryOrderId
        \o message.entryDate

DecodeOrderCancellationMarketMemberMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(transactionDateAndTime.rest, 4) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET entryDate == ReadBytes(secondaryOrderId.rest, 4) IN IF ~entryDate.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         securityCode           |-> securityCode.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         secondaryOrderId       |-> secondaryOrderId.value,
         entryDate              |-> entryDate.value ], entryDate.rest)

ZeroOrderCancellationMarketMemberMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      securityCode           |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 4 |-> 0],
      entryDate              |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancellation Market Member Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancellationMarketMemberMessage ==
    { ZeroOrderCancellationMarketMemberMessage }
        \cup { [ZeroOrderCancellationMarketMemberMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationMarketMemberMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationMarketMemberMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationMarketMemberMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationMarketMemberMessage EXCEPT !.entryDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Cancellation Market Member Message: 24 bytes                      *)
(***************************************************************************)

QuoteCancellationMarketMemberMessage ==
    [ sequenceNumber         : Sample(4),
      securityCode           : Sample(4),
      transactionDateAndTime : Sample(8),
      secondaryOrderId       : Sample(4),
      secondaryOrderId2      : Sample(4) ]

EncodeQuoteCancellationMarketMemberMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime
        \o message.secondaryOrderId
        \o message.secondaryOrderId2

DecodeQuoteCancellationMarketMemberMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(transactionDateAndTime.rest, 4) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET secondaryOrderId2 == ReadBytes(secondaryOrderId.rest, 4) IN IF ~secondaryOrderId2.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         securityCode           |-> securityCode.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         secondaryOrderId       |-> secondaryOrderId.value,
         secondaryOrderId2      |-> secondaryOrderId2.value ], secondaryOrderId2.rest)

ZeroQuoteCancellationMarketMemberMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      securityCode           |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 4 |-> 0],
      secondaryOrderId2      |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Cancellation Market Member Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancellationMarketMemberMessage ==
    { ZeroQuoteCancellationMarketMemberMessage }
        \cup { [ZeroQuoteCancellationMarketMemberMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancellationMarketMemberMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancellationMarketMemberMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancellationMarketMemberMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancellationMarketMemberMessage EXCEPT !.secondaryOrderId2 = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Market Post Transparency Information Top Of Book Message: 78      *)
(* bytes                                                                   *)
(***************************************************************************)

TradeMarketPostTransparencyInformationTopOfBookMessage ==
    [ sequenceNumber         : Sample(4),
      securityCode           : Sample(4),
      transactionDateAndTime : Sample(8),
      marketSegmentId        : Sample(4),
      tradingSessionId       : Sample(1),
      trdMatchId             : Sample(4),
      tradeType              : Sample(1),
      lastPx                 : Sample(8),
      lastQty                : Sample(4),
      grossTradeAmt          : Sample(8),
      designation            : Sample(1),
      marketMechanism        : Sample(1),
      algoFlag               : Sample(1),
      altLastPx              : Sample(8),
      accruedInterestAmt     : Sample(8),
      accruedInterestRateP8  : Sample(8),
      settlDate              : Sample(4),
      transactionCategory    : Sample(1) ]

EncodeTradeMarketPostTransparencyInformationTopOfBookMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime
        \o message.marketSegmentId
        \o message.tradingSessionId
        \o message.trdMatchId
        \o message.tradeType
        \o message.lastPx
        \o message.lastQty
        \o message.grossTradeAmt
        \o message.designation
        \o message.marketMechanism
        \o message.algoFlag
        \o message.altLastPx
        \o message.accruedInterestAmt
        \o message.accruedInterestRateP8
        \o message.settlDate
        \o message.transactionCategory

DecodeTradeMarketPostTransparencyInformationTopOfBookMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(transactionDateAndTime.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(marketSegmentId.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(tradingSessionId.rest, 4) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET tradeType == ReadBytes(trdMatchId.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeType.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET grossTradeAmt == ReadBytes(lastQty.rest, 8) IN IF ~grossTradeAmt.ok THEN Fail ELSE
    LET designation == ReadBytes(grossTradeAmt.rest, 1) IN IF ~designation.ok THEN Fail ELSE
    LET marketMechanism == ReadBytes(designation.rest, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET algoFlag == ReadBytes(marketMechanism.rest, 1) IN IF ~algoFlag.ok THEN Fail ELSE
    LET altLastPx == ReadBytes(algoFlag.rest, 8) IN IF ~altLastPx.ok THEN Fail ELSE
    LET accruedInterestAmt == ReadBytes(altLastPx.rest, 8) IN IF ~accruedInterestAmt.ok THEN Fail ELSE
    LET accruedInterestRateP8 == ReadBytes(accruedInterestAmt.rest, 8) IN IF ~accruedInterestRateP8.ok THEN Fail ELSE
    LET settlDate == ReadBytes(accruedInterestRateP8.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET transactionCategory == ReadBytes(settlDate.rest, 1) IN IF ~transactionCategory.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         securityCode           |-> securityCode.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         marketSegmentId        |-> marketSegmentId.value,
         tradingSessionId       |-> tradingSessionId.value,
         trdMatchId             |-> trdMatchId.value,
         tradeType              |-> tradeType.value,
         lastPx                 |-> lastPx.value,
         lastQty                |-> lastQty.value,
         grossTradeAmt          |-> grossTradeAmt.value,
         designation            |-> designation.value,
         marketMechanism        |-> marketMechanism.value,
         algoFlag               |-> algoFlag.value,
         altLastPx              |-> altLastPx.value,
         accruedInterestAmt     |-> accruedInterestAmt.value,
         accruedInterestRateP8  |-> accruedInterestRateP8.value,
         settlDate              |-> settlDate.value,
         transactionCategory    |-> transactionCategory.value ], transactionCategory.rest)

ZeroTradeMarketPostTransparencyInformationTopOfBookMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      securityCode           |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionId       |-> [i \in 1 .. 1 |-> 0],
      trdMatchId             |-> [i \in 1 .. 4 |-> 0],
      tradeType              |-> [i \in 1 .. 1 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      lastQty                |-> [i \in 1 .. 4 |-> 0],
      grossTradeAmt          |-> [i \in 1 .. 8 |-> 0],
      designation            |-> [i \in 1 .. 1 |-> 0],
      marketMechanism        |-> [i \in 1 .. 1 |-> 0],
      algoFlag               |-> [i \in 1 .. 1 |-> 0],
      altLastPx              |-> [i \in 1 .. 8 |-> 0],
      accruedInterestAmt     |-> [i \in 1 .. 8 |-> 0],
      accruedInterestRateP8  |-> [i \in 1 .. 8 |-> 0],
      settlDate              |-> [i \in 1 .. 4 |-> 0],
      transactionCategory    |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Market Post Transparency Information Top Of Book Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMarketPostTransparencyInformationTopOfBookMessage ==
    { ZeroTradeMarketPostTransparencyInformationTopOfBookMessage }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.grossTradeAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.designation = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.algoFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.altLastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.accruedInterestAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.accruedInterestRateP8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopOfBookMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Trade Amendment Or Cancellation Message: 125 bytes                *)
(***************************************************************************)

TradeTradeAmendmentOrCancellationMessage ==
    [ sequenceNumber              : Sample(4),
      securityCode                : Sample(4),
      transactionDateAndTime      : Sample(8),
      marketSegmentId             : Sample(4),
      tradingSessionId            : Sample(1),
      trdMatchId                  : Sample(4),
      tradeType                   : Sample(1),
      lastPx                      : Sample(8),
      lastQty                     : Sample(4),
      grossTradeAmt               : Sample(8),
      designation                 : Sample(1),
      marketMechanism             : Sample(1),
      algoFlag                    : Sample(1),
      altLastPx                   : Sample(8),
      accruedInterestAmt          : Sample(8),
      accruedInterestRateP8       : Sample(8),
      settlDate                   : Sample(4),
      transactionCategory         : Sample(1),
      lastChangeFlag              : Sample(1),
      bencRfptFlag                : Sample(1),
      tradePriceCondition         : Sample(1),
      preTradeTransparencyWaiver  : Sample(1),
      deferralWaiver              : Sample(1),
      postDeferralPublicationType : Sample(1),
      publishDateAndTime          : Sample(8),
      tradeDate                   : Sample(8),
      tradeSessionDate            : Sample(4),
      settlDate2                  : Sample(4),
      endCash                     : Sample(8),
      amendedTradeType            : Sample(1),
      execRefId                   : Sample(4),
      amendedTradeDate            : Sample(4) ]

EncodeTradeTradeAmendmentOrCancellationMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime
        \o message.marketSegmentId
        \o message.tradingSessionId
        \o message.trdMatchId
        \o message.tradeType
        \o message.lastPx
        \o message.lastQty
        \o message.grossTradeAmt
        \o message.designation
        \o message.marketMechanism
        \o message.algoFlag
        \o message.altLastPx
        \o message.accruedInterestAmt
        \o message.accruedInterestRateP8
        \o message.settlDate
        \o message.transactionCategory
        \o message.lastChangeFlag
        \o message.bencRfptFlag
        \o message.tradePriceCondition
        \o message.preTradeTransparencyWaiver
        \o message.deferralWaiver
        \o message.postDeferralPublicationType
        \o message.publishDateAndTime
        \o message.tradeDate
        \o message.tradeSessionDate
        \o message.settlDate2
        \o message.endCash
        \o message.amendedTradeType
        \o message.execRefId
        \o message.amendedTradeDate

DecodeTradeTradeAmendmentOrCancellationMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(transactionDateAndTime.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(marketSegmentId.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(tradingSessionId.rest, 4) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET tradeType == ReadBytes(trdMatchId.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeType.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET grossTradeAmt == ReadBytes(lastQty.rest, 8) IN IF ~grossTradeAmt.ok THEN Fail ELSE
    LET designation == ReadBytes(grossTradeAmt.rest, 1) IN IF ~designation.ok THEN Fail ELSE
    LET marketMechanism == ReadBytes(designation.rest, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET algoFlag == ReadBytes(marketMechanism.rest, 1) IN IF ~algoFlag.ok THEN Fail ELSE
    LET altLastPx == ReadBytes(algoFlag.rest, 8) IN IF ~altLastPx.ok THEN Fail ELSE
    LET accruedInterestAmt == ReadBytes(altLastPx.rest, 8) IN IF ~accruedInterestAmt.ok THEN Fail ELSE
    LET accruedInterestRateP8 == ReadBytes(accruedInterestAmt.rest, 8) IN IF ~accruedInterestRateP8.ok THEN Fail ELSE
    LET settlDate == ReadBytes(accruedInterestRateP8.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET transactionCategory == ReadBytes(settlDate.rest, 1) IN IF ~transactionCategory.ok THEN Fail ELSE
    LET lastChangeFlag == ReadBytes(transactionCategory.rest, 1) IN IF ~lastChangeFlag.ok THEN Fail ELSE
    LET bencRfptFlag == ReadBytes(lastChangeFlag.rest, 1) IN IF ~bencRfptFlag.ok THEN Fail ELSE
    LET tradePriceCondition == ReadBytes(bencRfptFlag.rest, 1) IN IF ~tradePriceCondition.ok THEN Fail ELSE
    LET preTradeTransparencyWaiver == ReadBytes(tradePriceCondition.rest, 1) IN IF ~preTradeTransparencyWaiver.ok THEN Fail ELSE
    LET deferralWaiver == ReadBytes(preTradeTransparencyWaiver.rest, 1) IN IF ~deferralWaiver.ok THEN Fail ELSE
    LET postDeferralPublicationType == ReadBytes(deferralWaiver.rest, 1) IN IF ~postDeferralPublicationType.ok THEN Fail ELSE
    LET publishDateAndTime == ReadBytes(postDeferralPublicationType.rest, 8) IN IF ~publishDateAndTime.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(publishDateAndTime.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeSessionDate == ReadBytes(tradeDate.rest, 4) IN IF ~tradeSessionDate.ok THEN Fail ELSE
    LET settlDate2 == ReadBytes(tradeSessionDate.rest, 4) IN IF ~settlDate2.ok THEN Fail ELSE
    LET endCash == ReadBytes(settlDate2.rest, 8) IN IF ~endCash.ok THEN Fail ELSE
    LET amendedTradeType == ReadBytes(endCash.rest, 1) IN IF ~amendedTradeType.ok THEN Fail ELSE
    LET execRefId == ReadBytes(amendedTradeType.rest, 4) IN IF ~execRefId.ok THEN Fail ELSE
    LET amendedTradeDate == ReadBytes(execRefId.rest, 4) IN IF ~amendedTradeDate.ok THEN Fail ELSE
    Ok([ sequenceNumber              |-> sequenceNumber.value,
         securityCode                |-> securityCode.value,
         transactionDateAndTime      |-> transactionDateAndTime.value,
         marketSegmentId             |-> marketSegmentId.value,
         tradingSessionId            |-> tradingSessionId.value,
         trdMatchId                  |-> trdMatchId.value,
         tradeType                   |-> tradeType.value,
         lastPx                      |-> lastPx.value,
         lastQty                     |-> lastQty.value,
         grossTradeAmt               |-> grossTradeAmt.value,
         designation                 |-> designation.value,
         marketMechanism             |-> marketMechanism.value,
         algoFlag                    |-> algoFlag.value,
         altLastPx                   |-> altLastPx.value,
         accruedInterestAmt          |-> accruedInterestAmt.value,
         accruedInterestRateP8       |-> accruedInterestRateP8.value,
         settlDate                   |-> settlDate.value,
         transactionCategory         |-> transactionCategory.value,
         lastChangeFlag              |-> lastChangeFlag.value,
         bencRfptFlag                |-> bencRfptFlag.value,
         tradePriceCondition         |-> tradePriceCondition.value,
         preTradeTransparencyWaiver  |-> preTradeTransparencyWaiver.value,
         deferralWaiver              |-> deferralWaiver.value,
         postDeferralPublicationType |-> postDeferralPublicationType.value,
         publishDateAndTime          |-> publishDateAndTime.value,
         tradeDate                   |-> tradeDate.value,
         tradeSessionDate            |-> tradeSessionDate.value,
         settlDate2                  |-> settlDate2.value,
         endCash                     |-> endCash.value,
         amendedTradeType            |-> amendedTradeType.value,
         execRefId                   |-> execRefId.value,
         amendedTradeDate            |-> amendedTradeDate.value ], amendedTradeDate.rest)

ZeroTradeTradeAmendmentOrCancellationMessage ==
    [ sequenceNumber              |-> [i \in 1 .. 4 |-> 0],
      securityCode                |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime      |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId             |-> [i \in 1 .. 4 |-> 0],
      tradingSessionId            |-> [i \in 1 .. 1 |-> 0],
      trdMatchId                  |-> [i \in 1 .. 4 |-> 0],
      tradeType                   |-> [i \in 1 .. 1 |-> 0],
      lastPx                      |-> [i \in 1 .. 8 |-> 0],
      lastQty                     |-> [i \in 1 .. 4 |-> 0],
      grossTradeAmt               |-> [i \in 1 .. 8 |-> 0],
      designation                 |-> [i \in 1 .. 1 |-> 0],
      marketMechanism             |-> [i \in 1 .. 1 |-> 0],
      algoFlag                    |-> [i \in 1 .. 1 |-> 0],
      altLastPx                   |-> [i \in 1 .. 8 |-> 0],
      accruedInterestAmt          |-> [i \in 1 .. 8 |-> 0],
      accruedInterestRateP8       |-> [i \in 1 .. 8 |-> 0],
      settlDate                   |-> [i \in 1 .. 4 |-> 0],
      transactionCategory         |-> [i \in 1 .. 1 |-> 0],
      lastChangeFlag              |-> [i \in 1 .. 1 |-> 0],
      bencRfptFlag                |-> [i \in 1 .. 1 |-> 0],
      tradePriceCondition         |-> [i \in 1 .. 1 |-> 0],
      preTradeTransparencyWaiver  |-> [i \in 1 .. 1 |-> 0],
      deferralWaiver              |-> [i \in 1 .. 1 |-> 0],
      postDeferralPublicationType |-> [i \in 1 .. 1 |-> 0],
      publishDateAndTime          |-> [i \in 1 .. 8 |-> 0],
      tradeDate                   |-> [i \in 1 .. 8 |-> 0],
      tradeSessionDate            |-> [i \in 1 .. 4 |-> 0],
      settlDate2                  |-> [i \in 1 .. 4 |-> 0],
      endCash                     |-> [i \in 1 .. 8 |-> 0],
      amendedTradeType            |-> [i \in 1 .. 1 |-> 0],
      execRefId                   |-> [i \in 1 .. 4 |-> 0],
      amendedTradeDate            |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Trade Amendment Or Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeTradeAmendmentOrCancellationMessage ==
    { ZeroTradeTradeAmendmentOrCancellationMessage }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.grossTradeAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.designation = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.algoFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.altLastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.accruedInterestAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.accruedInterestRateP8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.lastChangeFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.bencRfptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.tradePriceCondition = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.preTradeTransparencyWaiver = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.deferralWaiver = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.postDeferralPublicationType = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.publishDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.tradeSessionDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.settlDate2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.endCash = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.amendedTradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.execRefId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.amendedTradeDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Market Post Transparency Information Full Depth Message: 142      *)
(* bytes                                                                   *)
(***************************************************************************)

TradeMarketPostTransparencyInformationFullDepthMessage ==
    [ sequenceNumber         : Sample(4),
      securityCode           : Sample(4),
      transactionDateAndTime : Sample(8),
      marketSegmentId        : Sample(4),
      tradingSessionId       : Sample(1),
      trdMatchId             : Sample(4),
      tradeType              : Sample(1),
      lastPx                 : Sample(8),
      lastQty                : Sample(4),
      grossTradeAmt          : Sample(8),
      designation            : Sample(1),
      marketMechanism        : Sample(1),
      algoFlag               : Sample(1),
      altLastPx              : Sample(8),
      accruedInterestAmt     : Sample(8),
      accruedInterestRateP8  : Sample(8),
      settlDate              : Sample(4),
      transactionCategory    : Sample(1),
      secondaryOrderId       : Sample(4),
      entryDate              : Sample(4),
      priority               : Sample(4),
      price                  : Sample(8),
      displayQty             : Sample(4),
      altPrice               : Sample(8),
      secondaryOrderId2      : Sample(4),
      entryDate2             : Sample(4),
      priority2              : Sample(4),
      price2                 : Sample(8),
      displayQty2            : Sample(4),
      altPrice2              : Sample(8) ]

EncodeTradeMarketPostTransparencyInformationFullDepthMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime
        \o message.marketSegmentId
        \o message.tradingSessionId
        \o message.trdMatchId
        \o message.tradeType
        \o message.lastPx
        \o message.lastQty
        \o message.grossTradeAmt
        \o message.designation
        \o message.marketMechanism
        \o message.algoFlag
        \o message.altLastPx
        \o message.accruedInterestAmt
        \o message.accruedInterestRateP8
        \o message.settlDate
        \o message.transactionCategory
        \o message.secondaryOrderId
        \o message.entryDate
        \o message.priority
        \o message.price
        \o message.displayQty
        \o message.altPrice
        \o message.secondaryOrderId2
        \o message.entryDate2
        \o message.priority2
        \o message.price2
        \o message.displayQty2
        \o message.altPrice2

DecodeTradeMarketPostTransparencyInformationFullDepthMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(transactionDateAndTime.rest, 4) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(marketSegmentId.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET trdMatchId == ReadBytes(tradingSessionId.rest, 4) IN IF ~trdMatchId.ok THEN Fail ELSE
    LET tradeType == ReadBytes(trdMatchId.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET lastPx == ReadBytes(tradeType.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET lastQty == ReadBytes(lastPx.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET grossTradeAmt == ReadBytes(lastQty.rest, 8) IN IF ~grossTradeAmt.ok THEN Fail ELSE
    LET designation == ReadBytes(grossTradeAmt.rest, 1) IN IF ~designation.ok THEN Fail ELSE
    LET marketMechanism == ReadBytes(designation.rest, 1) IN IF ~marketMechanism.ok THEN Fail ELSE
    LET algoFlag == ReadBytes(marketMechanism.rest, 1) IN IF ~algoFlag.ok THEN Fail ELSE
    LET altLastPx == ReadBytes(algoFlag.rest, 8) IN IF ~altLastPx.ok THEN Fail ELSE
    LET accruedInterestAmt == ReadBytes(altLastPx.rest, 8) IN IF ~accruedInterestAmt.ok THEN Fail ELSE
    LET accruedInterestRateP8 == ReadBytes(accruedInterestAmt.rest, 8) IN IF ~accruedInterestRateP8.ok THEN Fail ELSE
    LET settlDate == ReadBytes(accruedInterestRateP8.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET transactionCategory == ReadBytes(settlDate.rest, 1) IN IF ~transactionCategory.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(transactionCategory.rest, 4) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET entryDate == ReadBytes(secondaryOrderId.rest, 4) IN IF ~entryDate.ok THEN Fail ELSE
    LET priority == ReadBytes(entryDate.rest, 4) IN IF ~priority.ok THEN Fail ELSE
    LET price == ReadBytes(priority.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET displayQty == ReadBytes(price.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET altPrice == ReadBytes(displayQty.rest, 8) IN IF ~altPrice.ok THEN Fail ELSE
    LET secondaryOrderId2 == ReadBytes(altPrice.rest, 4) IN IF ~secondaryOrderId2.ok THEN Fail ELSE
    LET entryDate2 == ReadBytes(secondaryOrderId2.rest, 4) IN IF ~entryDate2.ok THEN Fail ELSE
    LET priority2 == ReadBytes(entryDate2.rest, 4) IN IF ~priority2.ok THEN Fail ELSE
    LET price2 == ReadBytes(priority2.rest, 8) IN IF ~price2.ok THEN Fail ELSE
    LET displayQty2 == ReadBytes(price2.rest, 4) IN IF ~displayQty2.ok THEN Fail ELSE
    LET altPrice2 == ReadBytes(displayQty2.rest, 8) IN IF ~altPrice2.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         securityCode           |-> securityCode.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         marketSegmentId        |-> marketSegmentId.value,
         tradingSessionId       |-> tradingSessionId.value,
         trdMatchId             |-> trdMatchId.value,
         tradeType              |-> tradeType.value,
         lastPx                 |-> lastPx.value,
         lastQty                |-> lastQty.value,
         grossTradeAmt          |-> grossTradeAmt.value,
         designation            |-> designation.value,
         marketMechanism        |-> marketMechanism.value,
         algoFlag               |-> algoFlag.value,
         altLastPx              |-> altLastPx.value,
         accruedInterestAmt     |-> accruedInterestAmt.value,
         accruedInterestRateP8  |-> accruedInterestRateP8.value,
         settlDate              |-> settlDate.value,
         transactionCategory    |-> transactionCategory.value,
         secondaryOrderId       |-> secondaryOrderId.value,
         entryDate              |-> entryDate.value,
         priority               |-> priority.value,
         price                  |-> price.value,
         displayQty             |-> displayQty.value,
         altPrice               |-> altPrice.value,
         secondaryOrderId2      |-> secondaryOrderId2.value,
         entryDate2             |-> entryDate2.value,
         priority2              |-> priority2.value,
         price2                 |-> price2.value,
         displayQty2            |-> displayQty2.value,
         altPrice2              |-> altPrice2.value ], altPrice2.rest)

ZeroTradeMarketPostTransparencyInformationFullDepthMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      securityCode           |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId        |-> [i \in 1 .. 4 |-> 0],
      tradingSessionId       |-> [i \in 1 .. 1 |-> 0],
      trdMatchId             |-> [i \in 1 .. 4 |-> 0],
      tradeType              |-> [i \in 1 .. 1 |-> 0],
      lastPx                 |-> [i \in 1 .. 8 |-> 0],
      lastQty                |-> [i \in 1 .. 4 |-> 0],
      grossTradeAmt          |-> [i \in 1 .. 8 |-> 0],
      designation            |-> [i \in 1 .. 1 |-> 0],
      marketMechanism        |-> [i \in 1 .. 1 |-> 0],
      algoFlag               |-> [i \in 1 .. 1 |-> 0],
      altLastPx              |-> [i \in 1 .. 8 |-> 0],
      accruedInterestAmt     |-> [i \in 1 .. 8 |-> 0],
      accruedInterestRateP8  |-> [i \in 1 .. 8 |-> 0],
      settlDate              |-> [i \in 1 .. 4 |-> 0],
      transactionCategory    |-> [i \in 1 .. 1 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 4 |-> 0],
      entryDate              |-> [i \in 1 .. 4 |-> 0],
      priority               |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      displayQty             |-> [i \in 1 .. 4 |-> 0],
      altPrice               |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId2      |-> [i \in 1 .. 4 |-> 0],
      entryDate2             |-> [i \in 1 .. 4 |-> 0],
      priority2              |-> [i \in 1 .. 4 |-> 0],
      price2                 |-> [i \in 1 .. 8 |-> 0],
      displayQty2            |-> [i \in 1 .. 4 |-> 0],
      altPrice2              |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Market Post Transparency Information Full Depth Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMarketPostTransparencyInformationFullDepthMessage ==
    { ZeroTradeMarketPostTransparencyInformationFullDepthMessage }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.grossTradeAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.designation = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.algoFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.altLastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.accruedInterestAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.accruedInterestRateP8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.entryDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.priority = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.altPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.secondaryOrderId2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.entryDate2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.priority2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.price2 = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.displayQty2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationFullDepthMessage EXCEPT !.altPrice2 = one] : one \in Sample(8) }

(***************************************************************************)
(* Indication Of Interest Message: 35 bytes                                *)
(***************************************************************************)

IndicationOfInterestMessage ==
    [ sequenceNumber         : Sample(4),
      securityCode           : Sample(4),
      transactionDateAndTime : Sample(8),
      ioiid                  : Sample(4),
      ioiTransType           : Sample(1),
      side                   : Sample(1),
      ioiQty                 : Sample(4),
      ioiPrice               : Sample(8),
      tradingSessionId       : Sample(1) ]

EncodeIndicationOfInterestMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime
        \o message.ioiid
        \o message.ioiTransType
        \o message.side
        \o message.ioiQty
        \o message.ioiPrice
        \o message.tradingSessionId

DecodeIndicationOfInterestMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET ioiid == ReadBytes(transactionDateAndTime.rest, 4) IN IF ~ioiid.ok THEN Fail ELSE
    LET ioiTransType == ReadBytes(ioiid.rest, 1) IN IF ~ioiTransType.ok THEN Fail ELSE
    LET side == ReadBytes(ioiTransType.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET ioiQty == ReadBytes(side.rest, 4) IN IF ~ioiQty.ok THEN Fail ELSE
    LET ioiPrice == ReadBytes(ioiQty.rest, 8) IN IF ~ioiPrice.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(ioiPrice.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         securityCode           |-> securityCode.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         ioiid                  |-> ioiid.value,
         ioiTransType           |-> ioiTransType.value,
         side                   |-> side.value,
         ioiQty                 |-> ioiQty.value,
         ioiPrice               |-> ioiPrice.value,
         tradingSessionId       |-> tradingSessionId.value ], tradingSessionId.rest)

ZeroIndicationOfInterestMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      securityCode           |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      ioiid                  |-> [i \in 1 .. 4 |-> 0],
      ioiTransType           |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      ioiQty                 |-> [i \in 1 .. 4 |-> 0],
      ioiPrice               |-> [i \in 1 .. 8 |-> 0],
      tradingSessionId       |-> [i \in 1 .. 1 |-> 0] ]

(* Indication Of Interest Message at zero, then each field in turn at the values it is checked at *)
CheckedIndicationOfInterestMessage ==
    { ZeroIndicationOfInterestMessage }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.ioiid = one] : one \in Sample(4) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.ioiTransType = one] : one \in Sample(1) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.ioiQty = one] : one \in Sample(4) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.ioiPrice = one] : one \in Sample(8) }
        \cup { [ZeroIndicationOfInterestMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }

(***************************************************************************)
(* Rfq Market Pre Transparency Information Message: 189 bytes              *)
(***************************************************************************)

RfqMarketPreTransparencyInformationMessage ==
    [ sequenceNumber         : Sample(4),
      rfqid                  : Sample(4),
      tradingSessionId       : Sample(1),
      securityCode           : Sample(4),
      transactionDateAndTime : Sample(8),
      midBuyPrice            : Sample(8),
      midBuyVolume           : Sample(4),
      buyRfQsNumber          : Sample(2),
      midSellPrice           : Sample(8),
      midSellVolume          : Sample(4),
      sellRfQsNumber         : Sample(2),
      bidOrders1             : Sample(2),
      bidSize1               : Sample(4),
      bidPx1                 : Sample(8),
      askOrders1             : Sample(2),
      askSize1               : Sample(4),
      askPx1                 : Sample(8),
      bidOrders2             : Sample(2),
      bidSize2               : Sample(4),
      bidPx2                 : Sample(8),
      askOrders2             : Sample(2),
      askSize2               : Sample(4),
      askPx2                 : Sample(8),
      bidOrders3             : Sample(2),
      bidSize3               : Sample(4),
      bidPx3                 : Sample(8),
      askOrders3             : Sample(2),
      askSize3               : Sample(4),
      askPx3                 : Sample(8),
      bidOrders4             : Sample(2),
      bidSize4               : Sample(4),
      bidPx4                 : Sample(8),
      askOrders4             : Sample(2),
      askSize4               : Sample(4),
      askPx4                 : Sample(8),
      bidOrders5             : Sample(2),
      bidSize5               : Sample(4),
      bidPx5                 : Sample(8),
      askOrders5             : Sample(2),
      askSize5               : Sample(4),
      askPx5                 : Sample(8) ]

EncodeRfqMarketPreTransparencyInformationMessage(message) ==
    message.sequenceNumber
        \o message.rfqid
        \o message.tradingSessionId
        \o message.securityCode
        \o message.transactionDateAndTime
        \o message.midBuyPrice
        \o message.midBuyVolume
        \o message.buyRfQsNumber
        \o message.midSellPrice
        \o message.midSellVolume
        \o message.sellRfQsNumber
        \o message.bidOrders1
        \o message.bidSize1
        \o message.bidPx1
        \o message.askOrders1
        \o message.askSize1
        \o message.askPx1
        \o message.bidOrders2
        \o message.bidSize2
        \o message.bidPx2
        \o message.askOrders2
        \o message.askSize2
        \o message.askPx2
        \o message.bidOrders3
        \o message.bidSize3
        \o message.bidPx3
        \o message.askOrders3
        \o message.askSize3
        \o message.askPx3
        \o message.bidOrders4
        \o message.bidSize4
        \o message.bidPx4
        \o message.askOrders4
        \o message.askSize4
        \o message.askPx4
        \o message.bidOrders5
        \o message.bidSize5
        \o message.bidPx5
        \o message.askOrders5
        \o message.askSize5
        \o message.askPx5

DecodeRfqMarketPreTransparencyInformationMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET rfqid == ReadBytes(sequenceNumber.rest, 4) IN IF ~rfqid.ok THEN Fail ELSE
    LET tradingSessionId == ReadBytes(rfqid.rest, 1) IN IF ~tradingSessionId.ok THEN Fail ELSE
    LET securityCode == ReadBytes(tradingSessionId.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET midBuyPrice == ReadBytes(transactionDateAndTime.rest, 8) IN IF ~midBuyPrice.ok THEN Fail ELSE
    LET midBuyVolume == ReadBytes(midBuyPrice.rest, 4) IN IF ~midBuyVolume.ok THEN Fail ELSE
    LET buyRfQsNumber == ReadBytes(midBuyVolume.rest, 2) IN IF ~buyRfQsNumber.ok THEN Fail ELSE
    LET midSellPrice == ReadBytes(buyRfQsNumber.rest, 8) IN IF ~midSellPrice.ok THEN Fail ELSE
    LET midSellVolume == ReadBytes(midSellPrice.rest, 4) IN IF ~midSellVolume.ok THEN Fail ELSE
    LET sellRfQsNumber == ReadBytes(midSellVolume.rest, 2) IN IF ~sellRfQsNumber.ok THEN Fail ELSE
    LET bidOrders1 == ReadBytes(sellRfQsNumber.rest, 2) IN IF ~bidOrders1.ok THEN Fail ELSE
    LET bidSize1 == ReadBytes(bidOrders1.rest, 4) IN IF ~bidSize1.ok THEN Fail ELSE
    LET bidPx1 == ReadBytes(bidSize1.rest, 8) IN IF ~bidPx1.ok THEN Fail ELSE
    LET askOrders1 == ReadBytes(bidPx1.rest, 2) IN IF ~askOrders1.ok THEN Fail ELSE
    LET askSize1 == ReadBytes(askOrders1.rest, 4) IN IF ~askSize1.ok THEN Fail ELSE
    LET askPx1 == ReadBytes(askSize1.rest, 8) IN IF ~askPx1.ok THEN Fail ELSE
    LET bidOrders2 == ReadBytes(askPx1.rest, 2) IN IF ~bidOrders2.ok THEN Fail ELSE
    LET bidSize2 == ReadBytes(bidOrders2.rest, 4) IN IF ~bidSize2.ok THEN Fail ELSE
    LET bidPx2 == ReadBytes(bidSize2.rest, 8) IN IF ~bidPx2.ok THEN Fail ELSE
    LET askOrders2 == ReadBytes(bidPx2.rest, 2) IN IF ~askOrders2.ok THEN Fail ELSE
    LET askSize2 == ReadBytes(askOrders2.rest, 4) IN IF ~askSize2.ok THEN Fail ELSE
    LET askPx2 == ReadBytes(askSize2.rest, 8) IN IF ~askPx2.ok THEN Fail ELSE
    LET bidOrders3 == ReadBytes(askPx2.rest, 2) IN IF ~bidOrders3.ok THEN Fail ELSE
    LET bidSize3 == ReadBytes(bidOrders3.rest, 4) IN IF ~bidSize3.ok THEN Fail ELSE
    LET bidPx3 == ReadBytes(bidSize3.rest, 8) IN IF ~bidPx3.ok THEN Fail ELSE
    LET askOrders3 == ReadBytes(bidPx3.rest, 2) IN IF ~askOrders3.ok THEN Fail ELSE
    LET askSize3 == ReadBytes(askOrders3.rest, 4) IN IF ~askSize3.ok THEN Fail ELSE
    LET askPx3 == ReadBytes(askSize3.rest, 8) IN IF ~askPx3.ok THEN Fail ELSE
    LET bidOrders4 == ReadBytes(askPx3.rest, 2) IN IF ~bidOrders4.ok THEN Fail ELSE
    LET bidSize4 == ReadBytes(bidOrders4.rest, 4) IN IF ~bidSize4.ok THEN Fail ELSE
    LET bidPx4 == ReadBytes(bidSize4.rest, 8) IN IF ~bidPx4.ok THEN Fail ELSE
    LET askOrders4 == ReadBytes(bidPx4.rest, 2) IN IF ~askOrders4.ok THEN Fail ELSE
    LET askSize4 == ReadBytes(askOrders4.rest, 4) IN IF ~askSize4.ok THEN Fail ELSE
    LET askPx4 == ReadBytes(askSize4.rest, 8) IN IF ~askPx4.ok THEN Fail ELSE
    LET bidOrders5 == ReadBytes(askPx4.rest, 2) IN IF ~bidOrders5.ok THEN Fail ELSE
    LET bidSize5 == ReadBytes(bidOrders5.rest, 4) IN IF ~bidSize5.ok THEN Fail ELSE
    LET bidPx5 == ReadBytes(bidSize5.rest, 8) IN IF ~bidPx5.ok THEN Fail ELSE
    LET askOrders5 == ReadBytes(bidPx5.rest, 2) IN IF ~askOrders5.ok THEN Fail ELSE
    LET askSize5 == ReadBytes(askOrders5.rest, 4) IN IF ~askSize5.ok THEN Fail ELSE
    LET askPx5 == ReadBytes(askSize5.rest, 8) IN IF ~askPx5.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         rfqid                  |-> rfqid.value,
         tradingSessionId       |-> tradingSessionId.value,
         securityCode           |-> securityCode.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         midBuyPrice            |-> midBuyPrice.value,
         midBuyVolume           |-> midBuyVolume.value,
         buyRfQsNumber          |-> buyRfQsNumber.value,
         midSellPrice           |-> midSellPrice.value,
         midSellVolume          |-> midSellVolume.value,
         sellRfQsNumber         |-> sellRfQsNumber.value,
         bidOrders1             |-> bidOrders1.value,
         bidSize1               |-> bidSize1.value,
         bidPx1                 |-> bidPx1.value,
         askOrders1             |-> askOrders1.value,
         askSize1               |-> askSize1.value,
         askPx1                 |-> askPx1.value,
         bidOrders2             |-> bidOrders2.value,
         bidSize2               |-> bidSize2.value,
         bidPx2                 |-> bidPx2.value,
         askOrders2             |-> askOrders2.value,
         askSize2               |-> askSize2.value,
         askPx2                 |-> askPx2.value,
         bidOrders3             |-> bidOrders3.value,
         bidSize3               |-> bidSize3.value,
         bidPx3                 |-> bidPx3.value,
         askOrders3             |-> askOrders3.value,
         askSize3               |-> askSize3.value,
         askPx3                 |-> askPx3.value,
         bidOrders4             |-> bidOrders4.value,
         bidSize4               |-> bidSize4.value,
         bidPx4                 |-> bidPx4.value,
         askOrders4             |-> askOrders4.value,
         askSize4               |-> askSize4.value,
         askPx4                 |-> askPx4.value,
         bidOrders5             |-> bidOrders5.value,
         bidSize5               |-> bidSize5.value,
         bidPx5                 |-> bidPx5.value,
         askOrders5             |-> askOrders5.value,
         askSize5               |-> askSize5.value,
         askPx5                 |-> askPx5.value ], askPx5.rest)

ZeroRfqMarketPreTransparencyInformationMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      rfqid                  |-> [i \in 1 .. 4 |-> 0],
      tradingSessionId       |-> [i \in 1 .. 1 |-> 0],
      securityCode           |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      midBuyPrice            |-> [i \in 1 .. 8 |-> 0],
      midBuyVolume           |-> [i \in 1 .. 4 |-> 0],
      buyRfQsNumber          |-> [i \in 1 .. 2 |-> 0],
      midSellPrice           |-> [i \in 1 .. 8 |-> 0],
      midSellVolume          |-> [i \in 1 .. 4 |-> 0],
      sellRfQsNumber         |-> [i \in 1 .. 2 |-> 0],
      bidOrders1             |-> [i \in 1 .. 2 |-> 0],
      bidSize1               |-> [i \in 1 .. 4 |-> 0],
      bidPx1                 |-> [i \in 1 .. 8 |-> 0],
      askOrders1             |-> [i \in 1 .. 2 |-> 0],
      askSize1               |-> [i \in 1 .. 4 |-> 0],
      askPx1                 |-> [i \in 1 .. 8 |-> 0],
      bidOrders2             |-> [i \in 1 .. 2 |-> 0],
      bidSize2               |-> [i \in 1 .. 4 |-> 0],
      bidPx2                 |-> [i \in 1 .. 8 |-> 0],
      askOrders2             |-> [i \in 1 .. 2 |-> 0],
      askSize2               |-> [i \in 1 .. 4 |-> 0],
      askPx2                 |-> [i \in 1 .. 8 |-> 0],
      bidOrders3             |-> [i \in 1 .. 2 |-> 0],
      bidSize3               |-> [i \in 1 .. 4 |-> 0],
      bidPx3                 |-> [i \in 1 .. 8 |-> 0],
      askOrders3             |-> [i \in 1 .. 2 |-> 0],
      askSize3               |-> [i \in 1 .. 4 |-> 0],
      askPx3                 |-> [i \in 1 .. 8 |-> 0],
      bidOrders4             |-> [i \in 1 .. 2 |-> 0],
      bidSize4               |-> [i \in 1 .. 4 |-> 0],
      bidPx4                 |-> [i \in 1 .. 8 |-> 0],
      askOrders4             |-> [i \in 1 .. 2 |-> 0],
      askSize4               |-> [i \in 1 .. 4 |-> 0],
      askPx4                 |-> [i \in 1 .. 8 |-> 0],
      bidOrders5             |-> [i \in 1 .. 2 |-> 0],
      bidSize5               |-> [i \in 1 .. 4 |-> 0],
      bidPx5                 |-> [i \in 1 .. 8 |-> 0],
      askOrders5             |-> [i \in 1 .. 2 |-> 0],
      askSize5               |-> [i \in 1 .. 4 |-> 0],
      askPx5                 |-> [i \in 1 .. 8 |-> 0] ]

(* Rfq Market Pre Transparency Information Message at zero, then each field in turn at the values it is checked at *)
CheckedRfqMarketPreTransparencyInformationMessage ==
    { ZeroRfqMarketPreTransparencyInformationMessage }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.rfqid = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.midBuyPrice = one] : one \in Sample(8) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.midBuyVolume = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.buyRfQsNumber = one] : one \in Sample(2) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.midSellPrice = one] : one \in Sample(8) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.midSellVolume = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.sellRfQsNumber = one] : one \in Sample(2) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidOrders1 = one] : one \in Sample(2) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidSize1 = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidPx1 = one] : one \in Sample(8) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askOrders1 = one] : one \in Sample(2) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askSize1 = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askPx1 = one] : one \in Sample(8) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidOrders2 = one] : one \in Sample(2) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidSize2 = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidPx2 = one] : one \in Sample(8) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askOrders2 = one] : one \in Sample(2) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askSize2 = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askPx2 = one] : one \in Sample(8) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidOrders3 = one] : one \in Sample(2) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidSize3 = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidPx3 = one] : one \in Sample(8) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askOrders3 = one] : one \in Sample(2) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askSize3 = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askPx3 = one] : one \in Sample(8) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidOrders4 = one] : one \in Sample(2) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidSize4 = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidPx4 = one] : one \in Sample(8) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askOrders4 = one] : one \in Sample(2) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askSize4 = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askPx4 = one] : one \in Sample(8) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidOrders5 = one] : one \in Sample(2) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidSize5 = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.bidPx5 = one] : one \in Sample(8) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askOrders5 = one] : one \in Sample(2) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askSize5 = one] : one \in Sample(4) }
        \cup { [ZeroRfqMarketPreTransparencyInformationMessage EXCEPT !.askPx5 = one] : one \in Sample(8) }

(***************************************************************************)
(* Top Of Book Message: 60 bytes                                           *)
(***************************************************************************)

TopOfBookMessage ==
    [ sequenceNumber         : Sample(4),
      securityCode           : Sample(4),
      transactionDateAndTime : Sample(8),
      bidOrders1             : Sample(2),
      bidSize1               : Sample(4),
      bidPx1                 : Sample(8),
      altBidPx1              : Sample(8),
      askOrders1             : Sample(2),
      askSize1               : Sample(4),
      askPx1                 : Sample(8),
      altSellPx1             : Sample(8) ]

EncodeTopOfBookMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime
        \o message.bidOrders1
        \o message.bidSize1
        \o message.bidPx1
        \o message.altBidPx1
        \o message.askOrders1
        \o message.askSize1
        \o message.askPx1
        \o message.altSellPx1

DecodeTopOfBookMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET bidOrders1 == ReadBytes(transactionDateAndTime.rest, 2) IN IF ~bidOrders1.ok THEN Fail ELSE
    LET bidSize1 == ReadBytes(bidOrders1.rest, 4) IN IF ~bidSize1.ok THEN Fail ELSE
    LET bidPx1 == ReadBytes(bidSize1.rest, 8) IN IF ~bidPx1.ok THEN Fail ELSE
    LET altBidPx1 == ReadBytes(bidPx1.rest, 8) IN IF ~altBidPx1.ok THEN Fail ELSE
    LET askOrders1 == ReadBytes(altBidPx1.rest, 2) IN IF ~askOrders1.ok THEN Fail ELSE
    LET askSize1 == ReadBytes(askOrders1.rest, 4) IN IF ~askSize1.ok THEN Fail ELSE
    LET askPx1 == ReadBytes(askSize1.rest, 8) IN IF ~askPx1.ok THEN Fail ELSE
    LET altSellPx1 == ReadBytes(askPx1.rest, 8) IN IF ~altSellPx1.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         securityCode           |-> securityCode.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         bidOrders1             |-> bidOrders1.value,
         bidSize1               |-> bidSize1.value,
         bidPx1                 |-> bidPx1.value,
         altBidPx1              |-> altBidPx1.value,
         askOrders1             |-> askOrders1.value,
         askSize1               |-> askSize1.value,
         askPx1                 |-> askPx1.value,
         altSellPx1             |-> altSellPx1.value ], altSellPx1.rest)

ZeroTopOfBookMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      securityCode           |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      bidOrders1             |-> [i \in 1 .. 2 |-> 0],
      bidSize1               |-> [i \in 1 .. 4 |-> 0],
      bidPx1                 |-> [i \in 1 .. 8 |-> 0],
      altBidPx1              |-> [i \in 1 .. 8 |-> 0],
      askOrders1             |-> [i \in 1 .. 2 |-> 0],
      askSize1               |-> [i \in 1 .. 4 |-> 0],
      askPx1                 |-> [i \in 1 .. 8 |-> 0],
      altSellPx1             |-> [i \in 1 .. 8 |-> 0] ]

(* Top Of Book Message at zero, then each field in turn at the values it is checked at *)
CheckedTopOfBookMessage ==
    { ZeroTopOfBookMessage }
        \cup { [ZeroTopOfBookMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.bidOrders1 = one] : one \in Sample(2) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.bidSize1 = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.bidPx1 = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.altBidPx1 = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.askOrders1 = one] : one \in Sample(2) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.askSize1 = one] : one \in Sample(4) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.askPx1 = one] : one \in Sample(8) }
        \cup { [ZeroTopOfBookMessage EXCEPT !.altSellPx1 = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LogonResponseMessageCode == 8  \* 0x08
LogoutResponseMessageCode == 11  \* 0x0b
HeartbeatMessageCode == 48  \* 0x30
NetworkStatusMessageCode == 10  \* 0x0a
LogonMessageCode == 65  \* 0x41
LogoutMessageCode == 53  \* 0x35
RejectMessageCode == 13  \* 0x0d
ReplayRequestMessageCode == 9  \* 0x09
ReplayRequestAckNackMessageCode == 12  \* 0x0c
TradingSessionStatusMessageCode == 104  \* 0x68
NewsMessageCode == 66  \* 0x42
SecurityListCancellationReportMessageCode == 120  \* 0x78
StatisticsMessageCode == 132  \* 0x84
SecurityListMessageCode == 121  \* 0x79
SecurityListUpdateReportMessageCode == 128  \* 0x80
SecurityStatusMessageCode == 102  \* 0x66
OrderBookClearMessageCode == 129  \* 0x81
OrderMarketPreTransparencyInformationMessageCode == 3  \* 0x03
QuoteMarketPreTransparencyInformationMessageCode == 7  \* 0x07
OrderCancellationMarketMemberMessageCode == 1  \* 0x01
QuoteCancellationMarketMemberMessageCode == 5  \* 0x05
TradeMarketPostTransparencyInformationTopOfBookMessageCode == 16  \* 0x10
TradeTradeAmendmentOrCancellationMessageCode == 24  \* 0x18
TradeMarketPostTransparencyInformationFullDepthMessageCode == 17  \* 0x11
IndicationOfInterestMessageCode == 54  \* 0x36
RfqMarketPreTransparencyInformationMessageCode == 133  \* 0x85
TopOfBookMessageCode == 130  \* 0x82

Payload ==
    [ tag : {LogonResponseMessageCode}, body : LogonResponseMessage ]
        \cup [ tag : {LogoutResponseMessageCode}, body : LogoutResponseMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : HeartbeatMessage ]
        \cup [ tag : {NetworkStatusMessageCode}, body : NetworkStatusMessage ]
        \cup [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogoutMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RejectMessageCode}, body : RejectMessage ]
        \cup [ tag : {ReplayRequestMessageCode}, body : ReplayRequestMessage ]
        \cup [ tag : {ReplayRequestAckNackMessageCode}, body : ReplayRequestAckNackMessage ]
        \cup [ tag : {TradingSessionStatusMessageCode}, body : TradingSessionStatusMessage ]
        \cup [ tag : {NewsMessageCode}, body : NewsMessage ]
        \cup [ tag : {SecurityListCancellationReportMessageCode}, body : SecurityListCancellationReportMessage ]
        \cup [ tag : {StatisticsMessageCode}, body : StatisticsMessage ]
        \cup [ tag : {SecurityListMessageCode}, body : SecurityListMessage ]
        \cup [ tag : {SecurityListUpdateReportMessageCode}, body : SecurityListUpdateReportMessage ]
        \cup [ tag : {SecurityStatusMessageCode}, body : SecurityStatusMessage ]
        \cup [ tag : {OrderBookClearMessageCode}, body : OrderBookClearMessage ]
        \cup [ tag : {OrderMarketPreTransparencyInformationMessageCode}, body : OrderMarketPreTransparencyInformationMessage ]
        \cup [ tag : {QuoteMarketPreTransparencyInformationMessageCode}, body : QuoteMarketPreTransparencyInformationMessage ]
        \cup [ tag : {OrderCancellationMarketMemberMessageCode}, body : OrderCancellationMarketMemberMessage ]
        \cup [ tag : {QuoteCancellationMarketMemberMessageCode}, body : QuoteCancellationMarketMemberMessage ]
        \cup [ tag : {TradeMarketPostTransparencyInformationTopOfBookMessageCode}, body : TradeMarketPostTransparencyInformationTopOfBookMessage ]
        \cup [ tag : {TradeTradeAmendmentOrCancellationMessageCode}, body : TradeTradeAmendmentOrCancellationMessage ]
        \cup [ tag : {TradeMarketPostTransparencyInformationFullDepthMessageCode}, body : TradeMarketPostTransparencyInformationFullDepthMessage ]
        \cup [ tag : {IndicationOfInterestMessageCode}, body : IndicationOfInterestMessage ]
        \cup [ tag : {RfqMarketPreTransparencyInformationMessageCode}, body : RfqMarketPreTransparencyInformationMessage ]
        \cup [ tag : {TopOfBookMessageCode}, body : TopOfBookMessage ]

EncodePayload(message) ==
    CASE message.tag = LogonResponseMessageCode -> EncodeLogonResponseMessage(message.body)
      [] message.tag = LogoutResponseMessageCode -> EncodeLogoutResponseMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> EncodeHeartbeatMessage(message.body)
      [] message.tag = NetworkStatusMessageCode -> EncodeNetworkStatusMessage(message.body)
      [] message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogoutMessageCode -> << >>
      [] message.tag = RejectMessageCode -> EncodeRejectMessage(message.body)
      [] message.tag = ReplayRequestMessageCode -> EncodeReplayRequestMessage(message.body)
      [] message.tag = ReplayRequestAckNackMessageCode -> EncodeReplayRequestAckNackMessage(message.body)
      [] message.tag = TradingSessionStatusMessageCode -> EncodeTradingSessionStatusMessage(message.body)
      [] message.tag = NewsMessageCode -> EncodeNewsMessage(message.body)
      [] message.tag = SecurityListCancellationReportMessageCode -> EncodeSecurityListCancellationReportMessage(message.body)
      [] message.tag = StatisticsMessageCode -> EncodeStatisticsMessage(message.body)
      [] message.tag = SecurityListMessageCode -> EncodeSecurityListMessage(message.body)
      [] message.tag = SecurityListUpdateReportMessageCode -> EncodeSecurityListUpdateReportMessage(message.body)
      [] message.tag = SecurityStatusMessageCode -> EncodeSecurityStatusMessage(message.body)
      [] message.tag = OrderBookClearMessageCode -> EncodeOrderBookClearMessage(message.body)
      [] message.tag = OrderMarketPreTransparencyInformationMessageCode -> EncodeOrderMarketPreTransparencyInformationMessage(message.body)
      [] message.tag = QuoteMarketPreTransparencyInformationMessageCode -> EncodeQuoteMarketPreTransparencyInformationMessage(message.body)
      [] message.tag = OrderCancellationMarketMemberMessageCode -> EncodeOrderCancellationMarketMemberMessage(message.body)
      [] message.tag = QuoteCancellationMarketMemberMessageCode -> EncodeQuoteCancellationMarketMemberMessage(message.body)
      [] message.tag = TradeMarketPostTransparencyInformationTopOfBookMessageCode -> EncodeTradeMarketPostTransparencyInformationTopOfBookMessage(message.body)
      [] message.tag = TradeTradeAmendmentOrCancellationMessageCode -> EncodeTradeTradeAmendmentOrCancellationMessage(message.body)
      [] message.tag = TradeMarketPostTransparencyInformationFullDepthMessageCode -> EncodeTradeMarketPostTransparencyInformationFullDepthMessage(message.body)
      [] message.tag = IndicationOfInterestMessageCode -> EncodeIndicationOfInterestMessage(message.body)
      [] message.tag = RfqMarketPreTransparencyInformationMessageCode -> EncodeRfqMarketPreTransparencyInformationMessage(message.body)
      [] message.tag = TopOfBookMessageCode -> EncodeTopOfBookMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonResponseMessageCode -> DecodeLogonResponseMessage(bytes)
              [] tag = LogoutResponseMessageCode -> DecodeLogoutResponseMessage(bytes)
              [] tag = HeartbeatMessageCode -> DecodeHeartbeatMessage(bytes)
              [] tag = NetworkStatusMessageCode -> DecodeNetworkStatusMessage(bytes)
              [] tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogoutMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = RejectMessageCode -> DecodeRejectMessage(bytes)
              [] tag = ReplayRequestMessageCode -> DecodeReplayRequestMessage(bytes)
              [] tag = ReplayRequestAckNackMessageCode -> DecodeReplayRequestAckNackMessage(bytes)
              [] tag = TradingSessionStatusMessageCode -> DecodeTradingSessionStatusMessage(bytes)
              [] tag = NewsMessageCode -> DecodeNewsMessage(bytes)
              [] tag = SecurityListCancellationReportMessageCode -> DecodeSecurityListCancellationReportMessage(bytes)
              [] tag = StatisticsMessageCode -> DecodeStatisticsMessage(bytes)
              [] tag = SecurityListMessageCode -> DecodeSecurityListMessage(bytes)
              [] tag = SecurityListUpdateReportMessageCode -> DecodeSecurityListUpdateReportMessage(bytes)
              [] tag = SecurityStatusMessageCode -> DecodeSecurityStatusMessage(bytes)
              [] tag = OrderBookClearMessageCode -> DecodeOrderBookClearMessage(bytes)
              [] tag = OrderMarketPreTransparencyInformationMessageCode -> DecodeOrderMarketPreTransparencyInformationMessage(bytes)
              [] tag = QuoteMarketPreTransparencyInformationMessageCode -> DecodeQuoteMarketPreTransparencyInformationMessage(bytes)
              [] tag = OrderCancellationMarketMemberMessageCode -> DecodeOrderCancellationMarketMemberMessage(bytes)
              [] tag = QuoteCancellationMarketMemberMessageCode -> DecodeQuoteCancellationMarketMemberMessage(bytes)
              [] tag = TradeMarketPostTransparencyInformationTopOfBookMessageCode -> DecodeTradeMarketPostTransparencyInformationTopOfBookMessage(bytes)
              [] tag = TradeTradeAmendmentOrCancellationMessageCode -> DecodeTradeTradeAmendmentOrCancellationMessage(bytes)
              [] tag = TradeMarketPostTransparencyInformationFullDepthMessageCode -> DecodeTradeMarketPostTransparencyInformationFullDepthMessage(bytes)
              [] tag = IndicationOfInterestMessageCode -> DecodeIndicationOfInterestMessage(bytes)
              [] tag = RfqMarketPreTransparencyInformationMessageCode -> DecodeRfqMarketPreTransparencyInformationMessage(bytes)
              [] tag = TopOfBookMessageCode -> DecodeTopOfBookMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LogonResponseMessageCode, body |-> ZeroLogonResponseMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LogonResponseMessageCode, body |-> one] : one \in CheckedLogonResponseMessage }
        \cup { [tag |-> LogoutResponseMessageCode, body |-> one] : one \in CheckedLogoutResponseMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> one] : one \in CheckedHeartbeatMessage }
        \cup { [tag |-> NetworkStatusMessageCode, body |-> one] : one \in CheckedNetworkStatusMessage }
        \cup { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RejectMessageCode, body |-> one] : one \in CheckedRejectMessage }
        \cup { [tag |-> ReplayRequestMessageCode, body |-> one] : one \in CheckedReplayRequestMessage }
        \cup { [tag |-> ReplayRequestAckNackMessageCode, body |-> one] : one \in CheckedReplayRequestAckNackMessage }
        \cup { [tag |-> TradingSessionStatusMessageCode, body |-> one] : one \in CheckedTradingSessionStatusMessage }
        \cup { [tag |-> NewsMessageCode, body |-> one] : one \in CheckedNewsMessage }
        \cup { [tag |-> SecurityListCancellationReportMessageCode, body |-> one] : one \in CheckedSecurityListCancellationReportMessage }
        \cup { [tag |-> StatisticsMessageCode, body |-> one] : one \in CheckedStatisticsMessage }
        \cup { [tag |-> SecurityListMessageCode, body |-> one] : one \in CheckedSecurityListMessage }
        \cup { [tag |-> SecurityListUpdateReportMessageCode, body |-> one] : one \in CheckedSecurityListUpdateReportMessage }
        \cup { [tag |-> SecurityStatusMessageCode, body |-> one] : one \in CheckedSecurityStatusMessage }
        \cup { [tag |-> OrderBookClearMessageCode, body |-> one] : one \in CheckedOrderBookClearMessage }
        \cup { [tag |-> OrderMarketPreTransparencyInformationMessageCode, body |-> one] : one \in CheckedOrderMarketPreTransparencyInformationMessage }
        \cup { [tag |-> QuoteMarketPreTransparencyInformationMessageCode, body |-> one] : one \in CheckedQuoteMarketPreTransparencyInformationMessage }
        \cup { [tag |-> OrderCancellationMarketMemberMessageCode, body |-> one] : one \in CheckedOrderCancellationMarketMemberMessage }
        \cup { [tag |-> QuoteCancellationMarketMemberMessageCode, body |-> one] : one \in CheckedQuoteCancellationMarketMemberMessage }
        \cup { [tag |-> TradeMarketPostTransparencyInformationTopOfBookMessageCode, body |-> one] : one \in CheckedTradeMarketPostTransparencyInformationTopOfBookMessage }
        \cup { [tag |-> TradeTradeAmendmentOrCancellationMessageCode, body |-> one] : one \in CheckedTradeTradeAmendmentOrCancellationMessage }
        \cup { [tag |-> TradeMarketPostTransparencyInformationFullDepthMessageCode, body |-> one] : one \in CheckedTradeMarketPostTransparencyInformationFullDepthMessage }
        \cup { [tag |-> IndicationOfInterestMessageCode, body |-> one] : one \in CheckedIndicationOfInterestMessage }
        \cup { [tag |-> RfqMarketPreTransparencyInformationMessageCode, body |-> one] : one \in CheckedRfqMarketPreTransparencyInformationMessage }
        \cup { [tag |-> TopOfBookMessageCode, body |-> one] : one \in CheckedTopOfBookMessage }

(***************************************************************************)
(* Message, framed by Message Size                                         *)
(***************************************************************************)

Message ==
    [ payload : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET messageType == ReadUIntBE(bytes, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
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

(* As many Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadMessageAll(_)
ReadMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Message of each kind, for the lists that carry them *)
OneMessage ==
    { [ZeroMessage EXCEPT !.payload = [tag |-> LogonResponseMessageCode, body |-> ZeroLogonResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogoutResponseMessageCode, body |-> ZeroLogoutResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> ZeroHeartbeatMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NetworkStatusMessageCode, body |-> ZeroNetworkStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogoutMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RejectMessageCode, body |-> ZeroRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReplayRequestMessageCode, body |-> ZeroReplayRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ReplayRequestAckNackMessageCode, body |-> ZeroReplayRequestAckNackMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingSessionStatusMessageCode, body |-> ZeroTradingSessionStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewsMessageCode, body |-> ZeroNewsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityListCancellationReportMessageCode, body |-> ZeroSecurityListCancellationReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StatisticsMessageCode, body |-> ZeroStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityListMessageCode, body |-> ZeroSecurityListMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityListUpdateReportMessageCode, body |-> ZeroSecurityListUpdateReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatusMessageCode, body |-> ZeroSecurityStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderBookClearMessageCode, body |-> ZeroOrderBookClearMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderMarketPreTransparencyInformationMessageCode, body |-> ZeroOrderMarketPreTransparencyInformationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteMarketPreTransparencyInformationMessageCode, body |-> ZeroQuoteMarketPreTransparencyInformationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancellationMarketMemberMessageCode, body |-> ZeroOrderCancellationMarketMemberMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteCancellationMarketMemberMessageCode, body |-> ZeroQuoteCancellationMarketMemberMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMarketPostTransparencyInformationTopOfBookMessageCode, body |-> ZeroTradeMarketPostTransparencyInformationTopOfBookMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeTradeAmendmentOrCancellationMessageCode, body |-> ZeroTradeTradeAmendmentOrCancellationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMarketPostTransparencyInformationFullDepthMessageCode, body |-> ZeroTradeMarketPostTransparencyInformationFullDepthMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndicationOfInterestMessageCode, body |-> ZeroIndicationOfInterestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RfqMarketPreTransparencyInformationMessageCode, body |-> ZeroRfqMarketPreTransparencyInformationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TopOfBookMessageCode, body |-> ZeroTopOfBookMessage]] }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ message : SampleLists(OneMessage) ]

EncodePacket(message) ==
    EncodeMessageList(message.message)

DecodePacket(bytes) ==
    LET message == ReadMessageAll(bytes) IN IF ~message.ok THEN Fail ELSE
    Ok([ message |-> message.value ], message.rest)

ZeroPacket ==
    [ message |-> << >> ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
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

(* Every Logon Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonResponseMessage ==
    \A message \in CheckedLogonResponseMessage :
        LET read == DecodeLogonResponseMessage(EncodeLogonResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutResponseMessage ==
    \A message \in CheckedLogoutResponseMessage :
        LET read == DecodeLogoutResponseMessage(EncodeLogoutResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heartbeat Message decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartbeatMessage ==
    \A message \in CheckedHeartbeatMessage :
        LET read == DecodeHeartbeatMessage(EncodeHeartbeatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Network Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNetworkStatusMessage ==
    \A message \in CheckedNetworkStatusMessage :
        LET read == DecodeNetworkStatusMessage(EncodeNetworkStatusMessage(message))
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

(* Every Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectMessage ==
    \A message \in CheckedRejectMessage :
        LET read == DecodeRejectMessage(EncodeRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayRequestMessage ==
    \A message \in CheckedReplayRequestMessage :
        LET read == DecodeReplayRequestMessage(EncodeReplayRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replay Request Ack Nack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplayRequestAckNackMessage ==
    \A message \in CheckedReplayRequestAckNackMessage :
        LET read == DecodeReplayRequestAckNackMessage(EncodeReplayRequestAckNackMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading Session Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingSessionStatusMessage ==
    \A message \in CheckedTradingSessionStatusMessage :
        LET read == DecodeTradingSessionStatusMessage(EncodeTradingSessionStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every News Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewsMessage ==
    \A message \in CheckedNewsMessage :
        LET read == DecodeNewsMessage(EncodeNewsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security List Cancellation Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityListCancellationReportMessage ==
    \A message \in CheckedSecurityListCancellationReportMessage :
        LET read == DecodeSecurityListCancellationReportMessage(EncodeSecurityListCancellationReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Statistics Repeating Group decodes back to what was encoded, and leaves nothing over *)
RoundTripStatisticsRepeatingGroup ==
    \A message \in CheckedStatisticsRepeatingGroup :
        LET read == DecodeStatisticsRepeatingGroup(EncodeStatisticsRepeatingGroup(message))
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

(* Every Security List Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityListMessage ==
    \A message \in CheckedSecurityListMessage :
        LET read == DecodeSecurityListMessage(EncodeSecurityListMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security List Update Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityListUpdateReportMessage ==
    \A message \in CheckedSecurityListUpdateReportMessage :
        LET read == DecodeSecurityListUpdateReportMessage(EncodeSecurityListUpdateReportMessage(message))
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

(* Every Order Book Clear Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderBookClearMessage ==
    \A message \in CheckedOrderBookClearMessage :
        LET read == DecodeOrderBookClearMessage(EncodeOrderBookClearMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Market Pre Transparency Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMarketPreTransparencyInformationMessage ==
    \A message \in CheckedOrderMarketPreTransparencyInformationMessage :
        LET read == DecodeOrderMarketPreTransparencyInformationMessage(EncodeOrderMarketPreTransparencyInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Market Pre Transparency Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteMarketPreTransparencyInformationMessage ==
    \A message \in CheckedQuoteMarketPreTransparencyInformationMessage :
        LET read == DecodeQuoteMarketPreTransparencyInformationMessage(EncodeQuoteMarketPreTransparencyInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancellation Market Member Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancellationMarketMemberMessage ==
    \A message \in CheckedOrderCancellationMarketMemberMessage :
        LET read == DecodeOrderCancellationMarketMemberMessage(EncodeOrderCancellationMarketMemberMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancellation Market Member Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancellationMarketMemberMessage ==
    \A message \in CheckedQuoteCancellationMarketMemberMessage :
        LET read == DecodeQuoteCancellationMarketMemberMessage(EncodeQuoteCancellationMarketMemberMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Market Post Transparency Information Top Of Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMarketPostTransparencyInformationTopOfBookMessage ==
    \A message \in CheckedTradeMarketPostTransparencyInformationTopOfBookMessage :
        LET read == DecodeTradeMarketPostTransparencyInformationTopOfBookMessage(EncodeTradeMarketPostTransparencyInformationTopOfBookMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Trade Amendment Or Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeTradeAmendmentOrCancellationMessage ==
    \A message \in CheckedTradeTradeAmendmentOrCancellationMessage :
        LET read == DecodeTradeTradeAmendmentOrCancellationMessage(EncodeTradeTradeAmendmentOrCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Market Post Transparency Information Full Depth Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMarketPostTransparencyInformationFullDepthMessage ==
    \A message \in CheckedTradeMarketPostTransparencyInformationFullDepthMessage :
        LET read == DecodeTradeMarketPostTransparencyInformationFullDepthMessage(EncodeTradeMarketPostTransparencyInformationFullDepthMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Indication Of Interest Message decodes back to what was encoded, and leaves nothing over *)
RoundTripIndicationOfInterestMessage ==
    \A message \in CheckedIndicationOfInterestMessage :
        LET read == DecodeIndicationOfInterestMessage(EncodeIndicationOfInterestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Market Pre Transparency Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqMarketPreTransparencyInformationMessage ==
    \A message \in CheckedRfqMarketPreTransparencyInformationMessage :
        LET read == DecodeRfqMarketPreTransparencyInformationMessage(EncodeRfqMarketPreTransparencyInformationMessage(message))
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

(* A Payload is selected by the Message Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
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
