---------------- MODULE BmeFixedIncome_MarketAndOrder_v1_6 -----------------
(***************************************************************************)
(* Bolsas y Mercados Españoles BME Fixed Income Market And Order v1.6      *)
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
      textC58              : Sample(58),
      msgRejectedReference : Sample(7) ]

EncodeRejectMessage(message) ==
    message.sequenceNumber
        \o message.sessionRejectReason
        \o message.textC58
        \o message.msgRejectedReference

DecodeRejectMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET sessionRejectReason == ReadBytes(sequenceNumber.rest, 1) IN IF ~sessionRejectReason.ok THEN Fail ELSE
    LET textC58 == ReadBytes(sessionRejectReason.rest, 58) IN IF ~textC58.ok THEN Fail ELSE
    LET msgRejectedReference == ReadBytes(textC58.rest, 7) IN IF ~msgRejectedReference.ok THEN Fail ELSE
    Ok([ sequenceNumber       |-> sequenceNumber.value,
         sessionRejectReason  |-> sessionRejectReason.value,
         textC58              |-> textC58.value,
         msgRejectedReference |-> msgRejectedReference.value ], msgRejectedReference.rest)

ZeroRejectMessage ==
    [ sequenceNumber       |-> [i \in 1 .. 4 |-> 0],
      sessionRejectReason  |-> [i \in 1 .. 1 |-> 0],
      textC58              |-> [i \in 1 .. 58 |-> 0],
      msgRejectedReference |-> [i \in 1 .. 7 |-> 0] ]

(* Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectMessage ==
    { ZeroRejectMessage }
        \cup { [ZeroRejectMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroRejectMessage EXCEPT !.sessionRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroRejectMessage EXCEPT !.textC58 = one] : one \in Sample(58) }
        \cup { [ZeroRejectMessage EXCEPT !.msgRejectedReference = one] : one \in Sample(7) }

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
(* Statistics Message: 18 bytes                                            *)
(***************************************************************************)

StatisticsMessage ==
    [ sequenceNumber         : Sample(4),
      securityCode           : Sample(4),
      transactionDateAndTime : Sample(8),
      dataCount              : Sample(1),
      dataCode               : Sample(1) ]

EncodeStatisticsMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime
        \o message.dataCount
        \o message.dataCode

DecodeStatisticsMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET dataCount == ReadBytes(transactionDateAndTime.rest, 1) IN IF ~dataCount.ok THEN Fail ELSE
    LET dataCode == ReadBytes(dataCount.rest, 1) IN IF ~dataCode.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         securityCode           |-> securityCode.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         dataCount              |-> dataCount.value,
         dataCode               |-> dataCode.value ], dataCode.rest)

ZeroStatisticsMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      securityCode           |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      dataCount              |-> [i \in 1 .. 1 |-> 0],
      dataCode               |-> [i \in 1 .. 1 |-> 0] ]

(* Statistics Message at zero, then each field in turn at the values it is checked at *)
CheckedStatisticsMessage ==
    { ZeroStatisticsMessage }
        \cup { [ZeroStatisticsMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroStatisticsMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroStatisticsMessage EXCEPT !.dataCount = one] : one \in Sample(1) }
        \cup { [ZeroStatisticsMessage EXCEPT !.dataCode = one] : one \in Sample(1) }

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
(* Trade Market Post Transparency Information Topofbook Message: 78 bytes  *)
(***************************************************************************)

TradeMarketPostTransparencyInformationTopofbookMessage ==
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

EncodeTradeMarketPostTransparencyInformationTopofbookMessage(message) ==
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

DecodeTradeMarketPostTransparencyInformationTopofbookMessage(bytes) ==
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

ZeroTradeMarketPostTransparencyInformationTopofbookMessage ==
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

(* Trade Market Post Transparency Information Topofbook Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMarketPostTransparencyInformationTopofbookMessage ==
    { ZeroTradeMarketPostTransparencyInformationTopofbookMessage }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.grossTradeAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.designation = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.algoFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.altLastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.accruedInterestAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.accruedInterestRateP8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }

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
      lastChangeFlagF1            : Sample(1),
      bencrfptFlag                : Sample(1),
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
        \o message.lastChangeFlagF1
        \o message.bencrfptFlag
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
    LET lastChangeFlagF1 == ReadBytes(transactionCategory.rest, 1) IN IF ~lastChangeFlagF1.ok THEN Fail ELSE
    LET bencrfptFlag == ReadBytes(lastChangeFlagF1.rest, 1) IN IF ~bencrfptFlag.ok THEN Fail ELSE
    LET tradePriceCondition == ReadBytes(bencrfptFlag.rest, 1) IN IF ~tradePriceCondition.ok THEN Fail ELSE
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
         lastChangeFlagF1            |-> lastChangeFlagF1.value,
         bencrfptFlag                |-> bencrfptFlag.value,
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
      lastChangeFlagF1            |-> [i \in 1 .. 1 |-> 0],
      bencrfptFlag                |-> [i \in 1 .. 1 |-> 0],
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
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.lastChangeFlagF1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.bencrfptFlag = one] : one \in Sample(1) }
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
(* Topofbook Message: 60 bytes                                             *)
(***************************************************************************)

TopofbookMessage ==
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

EncodeTopofbookMessage(message) ==
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

DecodeTopofbookMessage(bytes) ==
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

ZeroTopofbookMessage ==
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

(* Topofbook Message at zero, then each field in turn at the values it is checked at *)
CheckedTopofbookMessage ==
    { ZeroTopofbookMessage }
        \cup { [ZeroTopofbookMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTopofbookMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroTopofbookMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTopofbookMessage EXCEPT !.bidOrders1 = one] : one \in Sample(2) }
        \cup { [ZeroTopofbookMessage EXCEPT !.bidSize1 = one] : one \in Sample(4) }
        \cup { [ZeroTopofbookMessage EXCEPT !.bidPx1 = one] : one \in Sample(8) }
        \cup { [ZeroTopofbookMessage EXCEPT !.altBidPx1 = one] : one \in Sample(8) }
        \cup { [ZeroTopofbookMessage EXCEPT !.askOrders1 = one] : one \in Sample(2) }
        \cup { [ZeroTopofbookMessage EXCEPT !.askSize1 = one] : one \in Sample(4) }
        \cup { [ZeroTopofbookMessage EXCEPT !.askPx1 = one] : one \in Sample(8) }
        \cup { [ZeroTopofbookMessage EXCEPT !.altSellPx1 = one] : one \in Sample(8) }

(***************************************************************************)
(* Order And Quote Client Data Message: 64 bytes                           *)
(***************************************************************************)

OrderAndQuoteClientDataMessage ==
    [ requestId                  : Sample(4),
      clientDataId               : Sample(2),
      algorithmicTradeIndicator  : Sample(1),
      clientId                   : Sample(4),
      accountBolsa               : Sample(16),
      account                    : Sample(5),
      deaFlag                    : Sample(1),
      decisorId                  : Sample(4),
      executorId                 : Sample(4),
      liquidityProvisionActivity : Sample(1),
      accountMember              : Sample(4),
      lastCapacity               : Sample(1),
      receivedDeptId             : Sample(1),
      persistence                : Sample(1),
      clientDataReference        : Sample(15) ]

EncodeOrderAndQuoteClientDataMessage(message) ==
    message.requestId
        \o message.clientDataId
        \o message.algorithmicTradeIndicator
        \o message.clientId
        \o message.accountBolsa
        \o message.account
        \o message.deaFlag
        \o message.decisorId
        \o message.executorId
        \o message.liquidityProvisionActivity
        \o message.accountMember
        \o message.lastCapacity
        \o message.receivedDeptId
        \o message.persistence
        \o message.clientDataReference

DecodeOrderAndQuoteClientDataMessage(bytes) ==
    LET requestId == ReadBytes(bytes, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET clientDataId == ReadBytes(requestId.rest, 2) IN IF ~clientDataId.ok THEN Fail ELSE
    LET algorithmicTradeIndicator == ReadBytes(clientDataId.rest, 1) IN IF ~algorithmicTradeIndicator.ok THEN Fail ELSE
    LET clientId == ReadBytes(algorithmicTradeIndicator.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET accountBolsa == ReadBytes(clientId.rest, 16) IN IF ~accountBolsa.ok THEN Fail ELSE
    LET account == ReadBytes(accountBolsa.rest, 5) IN IF ~account.ok THEN Fail ELSE
    LET deaFlag == ReadBytes(account.rest, 1) IN IF ~deaFlag.ok THEN Fail ELSE
    LET decisorId == ReadBytes(deaFlag.rest, 4) IN IF ~decisorId.ok THEN Fail ELSE
    LET executorId == ReadBytes(decisorId.rest, 4) IN IF ~executorId.ok THEN Fail ELSE
    LET liquidityProvisionActivity == ReadBytes(executorId.rest, 1) IN IF ~liquidityProvisionActivity.ok THEN Fail ELSE
    LET accountMember == ReadBytes(liquidityProvisionActivity.rest, 4) IN IF ~accountMember.ok THEN Fail ELSE
    LET lastCapacity == ReadBytes(accountMember.rest, 1) IN IF ~lastCapacity.ok THEN Fail ELSE
    LET receivedDeptId == ReadBytes(lastCapacity.rest, 1) IN IF ~receivedDeptId.ok THEN Fail ELSE
    LET persistence == ReadBytes(receivedDeptId.rest, 1) IN IF ~persistence.ok THEN Fail ELSE
    LET clientDataReference == ReadBytes(persistence.rest, 15) IN IF ~clientDataReference.ok THEN Fail ELSE
    Ok([ requestId                  |-> requestId.value,
         clientDataId               |-> clientDataId.value,
         algorithmicTradeIndicator  |-> algorithmicTradeIndicator.value,
         clientId                   |-> clientId.value,
         accountBolsa               |-> accountBolsa.value,
         account                    |-> account.value,
         deaFlag                    |-> deaFlag.value,
         decisorId                  |-> decisorId.value,
         executorId                 |-> executorId.value,
         liquidityProvisionActivity |-> liquidityProvisionActivity.value,
         accountMember              |-> accountMember.value,
         lastCapacity               |-> lastCapacity.value,
         receivedDeptId             |-> receivedDeptId.value,
         persistence                |-> persistence.value,
         clientDataReference        |-> clientDataReference.value ], clientDataReference.rest)

ZeroOrderAndQuoteClientDataMessage ==
    [ requestId                  |-> [i \in 1 .. 4 |-> 0],
      clientDataId               |-> [i \in 1 .. 2 |-> 0],
      algorithmicTradeIndicator  |-> [i \in 1 .. 1 |-> 0],
      clientId                   |-> [i \in 1 .. 4 |-> 0],
      accountBolsa               |-> [i \in 1 .. 16 |-> 0],
      account                    |-> [i \in 1 .. 5 |-> 0],
      deaFlag                    |-> [i \in 1 .. 1 |-> 0],
      decisorId                  |-> [i \in 1 .. 4 |-> 0],
      executorId                 |-> [i \in 1 .. 4 |-> 0],
      liquidityProvisionActivity |-> [i \in 1 .. 1 |-> 0],
      accountMember              |-> [i \in 1 .. 4 |-> 0],
      lastCapacity               |-> [i \in 1 .. 1 |-> 0],
      receivedDeptId             |-> [i \in 1 .. 1 |-> 0],
      persistence                |-> [i \in 1 .. 1 |-> 0],
      clientDataReference        |-> [i \in 1 .. 15 |-> 0] ]

(* Order And Quote Client Data Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAndQuoteClientDataMessage ==
    { ZeroOrderAndQuoteClientDataMessage }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.clientDataId = one] : one \in Sample(2) }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.algorithmicTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.accountBolsa = one] : one \in Sample(16) }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.account = one] : one \in Sample(5) }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.deaFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.decisorId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.executorId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.liquidityProvisionActivity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.accountMember = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.lastCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.receivedDeptId = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.persistence = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndQuoteClientDataMessage EXCEPT !.clientDataReference = one] : one \in Sample(15) }

(***************************************************************************)
(* Simple New Order Message: 28 bytes                                      *)
(***************************************************************************)

SimpleNewOrderMessage ==
    [ requestId    : Sample(4),
      securityCode : Sample(4),
      clientDataId : Sample(2),
      orderId      : Sample(4),
      side         : Sample(1),
      price        : Sample(8),
      orderQty     : Sample(4),
      timeInForce  : Sample(1) ]

EncodeSimpleNewOrderMessage(message) ==
    message.requestId
        \o message.securityCode
        \o message.clientDataId
        \o message.orderId
        \o message.side
        \o message.price
        \o message.orderQty
        \o message.timeInForce

DecodeSimpleNewOrderMessage(bytes) ==
    LET requestId == ReadBytes(bytes, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET securityCode == ReadBytes(requestId.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET clientDataId == ReadBytes(securityCode.rest, 2) IN IF ~clientDataId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clientDataId.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(orderQty.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    Ok([ requestId    |-> requestId.value,
         securityCode |-> securityCode.value,
         clientDataId |-> clientDataId.value,
         orderId      |-> orderId.value,
         side         |-> side.value,
         price        |-> price.value,
         orderQty     |-> orderQty.value,
         timeInForce  |-> timeInForce.value ], timeInForce.rest)

ZeroSimpleNewOrderMessage ==
    [ requestId    |-> [i \in 1 .. 4 |-> 0],
      securityCode |-> [i \in 1 .. 4 |-> 0],
      clientDataId |-> [i \in 1 .. 2 |-> 0],
      orderId      |-> [i \in 1 .. 4 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      orderQty     |-> [i \in 1 .. 4 |-> 0],
      timeInForce  |-> [i \in 1 .. 1 |-> 0] ]

(* Simple New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleNewOrderMessage ==
    { ZeroSimpleNewOrderMessage }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.clientDataId = one] : one \in Sample(2) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroSimpleNewOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }

(***************************************************************************)
(* Simple New Order With Client Data Message: 84 bytes                     *)
(***************************************************************************)

SimpleNewOrderWithClientDataMessage ==
    [ requestId                  : Sample(4),
      securityCode               : Sample(4),
      orderId                    : Sample(4),
      side                       : Sample(1),
      price                      : Sample(8),
      orderQty                   : Sample(4),
      timeInForce                : Sample(1),
      algorithmicTradeIndicator  : Sample(1),
      clientId                   : Sample(4),
      accountBolsa               : Sample(16),
      account                    : Sample(5),
      deaFlag                    : Sample(1),
      decisorId                  : Sample(4),
      executorId                 : Sample(4),
      liquidityProvisionActivity : Sample(1),
      accountMember              : Sample(4),
      lastCapacity               : Sample(1),
      receivedDeptId             : Sample(1),
      persistence                : Sample(1),
      clientDataReference        : Sample(15) ]

EncodeSimpleNewOrderWithClientDataMessage(message) ==
    message.requestId
        \o message.securityCode
        \o message.orderId
        \o message.side
        \o message.price
        \o message.orderQty
        \o message.timeInForce
        \o message.algorithmicTradeIndicator
        \o message.clientId
        \o message.accountBolsa
        \o message.account
        \o message.deaFlag
        \o message.decisorId
        \o message.executorId
        \o message.liquidityProvisionActivity
        \o message.accountMember
        \o message.lastCapacity
        \o message.receivedDeptId
        \o message.persistence
        \o message.clientDataReference

DecodeSimpleNewOrderWithClientDataMessage(bytes) ==
    LET requestId == ReadBytes(bytes, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET securityCode == ReadBytes(requestId.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityCode.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(orderQty.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET algorithmicTradeIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~algorithmicTradeIndicator.ok THEN Fail ELSE
    LET clientId == ReadBytes(algorithmicTradeIndicator.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET accountBolsa == ReadBytes(clientId.rest, 16) IN IF ~accountBolsa.ok THEN Fail ELSE
    LET account == ReadBytes(accountBolsa.rest, 5) IN IF ~account.ok THEN Fail ELSE
    LET deaFlag == ReadBytes(account.rest, 1) IN IF ~deaFlag.ok THEN Fail ELSE
    LET decisorId == ReadBytes(deaFlag.rest, 4) IN IF ~decisorId.ok THEN Fail ELSE
    LET executorId == ReadBytes(decisorId.rest, 4) IN IF ~executorId.ok THEN Fail ELSE
    LET liquidityProvisionActivity == ReadBytes(executorId.rest, 1) IN IF ~liquidityProvisionActivity.ok THEN Fail ELSE
    LET accountMember == ReadBytes(liquidityProvisionActivity.rest, 4) IN IF ~accountMember.ok THEN Fail ELSE
    LET lastCapacity == ReadBytes(accountMember.rest, 1) IN IF ~lastCapacity.ok THEN Fail ELSE
    LET receivedDeptId == ReadBytes(lastCapacity.rest, 1) IN IF ~receivedDeptId.ok THEN Fail ELSE
    LET persistence == ReadBytes(receivedDeptId.rest, 1) IN IF ~persistence.ok THEN Fail ELSE
    LET clientDataReference == ReadBytes(persistence.rest, 15) IN IF ~clientDataReference.ok THEN Fail ELSE
    Ok([ requestId                  |-> requestId.value,
         securityCode               |-> securityCode.value,
         orderId                    |-> orderId.value,
         side                       |-> side.value,
         price                      |-> price.value,
         orderQty                   |-> orderQty.value,
         timeInForce                |-> timeInForce.value,
         algorithmicTradeIndicator  |-> algorithmicTradeIndicator.value,
         clientId                   |-> clientId.value,
         accountBolsa               |-> accountBolsa.value,
         account                    |-> account.value,
         deaFlag                    |-> deaFlag.value,
         decisorId                  |-> decisorId.value,
         executorId                 |-> executorId.value,
         liquidityProvisionActivity |-> liquidityProvisionActivity.value,
         accountMember              |-> accountMember.value,
         lastCapacity               |-> lastCapacity.value,
         receivedDeptId             |-> receivedDeptId.value,
         persistence                |-> persistence.value,
         clientDataReference        |-> clientDataReference.value ], clientDataReference.rest)

ZeroSimpleNewOrderWithClientDataMessage ==
    [ requestId                  |-> [i \in 1 .. 4 |-> 0],
      securityCode               |-> [i \in 1 .. 4 |-> 0],
      orderId                    |-> [i \in 1 .. 4 |-> 0],
      side                       |-> [i \in 1 .. 1 |-> 0],
      price                      |-> [i \in 1 .. 8 |-> 0],
      orderQty                   |-> [i \in 1 .. 4 |-> 0],
      timeInForce                |-> [i \in 1 .. 1 |-> 0],
      algorithmicTradeIndicator  |-> [i \in 1 .. 1 |-> 0],
      clientId                   |-> [i \in 1 .. 4 |-> 0],
      accountBolsa               |-> [i \in 1 .. 16 |-> 0],
      account                    |-> [i \in 1 .. 5 |-> 0],
      deaFlag                    |-> [i \in 1 .. 1 |-> 0],
      decisorId                  |-> [i \in 1 .. 4 |-> 0],
      executorId                 |-> [i \in 1 .. 4 |-> 0],
      liquidityProvisionActivity |-> [i \in 1 .. 1 |-> 0],
      accountMember              |-> [i \in 1 .. 4 |-> 0],
      lastCapacity               |-> [i \in 1 .. 1 |-> 0],
      receivedDeptId             |-> [i \in 1 .. 1 |-> 0],
      persistence                |-> [i \in 1 .. 1 |-> 0],
      clientDataReference        |-> [i \in 1 .. 15 |-> 0] ]

(* Simple New Order With Client Data Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleNewOrderWithClientDataMessage ==
    { ZeroSimpleNewOrderWithClientDataMessage }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.algorithmicTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.accountBolsa = one] : one \in Sample(16) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.account = one] : one \in Sample(5) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.deaFlag = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.decisorId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.executorId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.liquidityProvisionActivity = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.accountMember = one] : one \in Sample(4) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.lastCapacity = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.receivedDeptId = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.persistence = one] : one \in Sample(1) }
        \cup { [ZeroSimpleNewOrderWithClientDataMessage EXCEPT !.clientDataReference = one] : one \in Sample(15) }

(***************************************************************************)
(* Simple Order Modification Message: 27 bytes                             *)
(***************************************************************************)

SimpleOrderModificationMessage ==
    [ requestId    : Sample(4),
      securityCode : Sample(4),
      orderId      : Sample(4),
      side         : Sample(1),
      price        : Sample(8),
      orderQty     : Sample(4),
      clientDataId : Sample(2) ]

EncodeSimpleOrderModificationMessage(message) ==
    message.requestId
        \o message.securityCode
        \o message.orderId
        \o message.side
        \o message.price
        \o message.orderQty
        \o message.clientDataId

DecodeSimpleOrderModificationMessage(bytes) ==
    LET requestId == ReadBytes(bytes, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET securityCode == ReadBytes(requestId.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityCode.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET clientDataId == ReadBytes(orderQty.rest, 2) IN IF ~clientDataId.ok THEN Fail ELSE
    Ok([ requestId    |-> requestId.value,
         securityCode |-> securityCode.value,
         orderId      |-> orderId.value,
         side         |-> side.value,
         price        |-> price.value,
         orderQty     |-> orderQty.value,
         clientDataId |-> clientDataId.value ], clientDataId.rest)

ZeroSimpleOrderModificationMessage ==
    [ requestId    |-> [i \in 1 .. 4 |-> 0],
      securityCode |-> [i \in 1 .. 4 |-> 0],
      orderId      |-> [i \in 1 .. 4 |-> 0],
      side         |-> [i \in 1 .. 1 |-> 0],
      price        |-> [i \in 1 .. 8 |-> 0],
      orderQty     |-> [i \in 1 .. 4 |-> 0],
      clientDataId |-> [i \in 1 .. 2 |-> 0] ]

(* Simple Order Modification Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleOrderModificationMessage ==
    { ZeroSimpleOrderModificationMessage }
        \cup { [ZeroSimpleOrderModificationMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderModificationMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderModificationMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderModificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderModificationMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroSimpleOrderModificationMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderModificationMessage EXCEPT !.clientDataId = one] : one \in Sample(2) }

(***************************************************************************)
(* Simple Order Modification With Client Data Message: 83 bytes            *)
(***************************************************************************)

SimpleOrderModificationWithClientDataMessage ==
    [ requestId                  : Sample(4),
      securityCode               : Sample(4),
      orderId                    : Sample(4),
      side                       : Sample(1),
      price                      : Sample(8),
      orderQty                   : Sample(4),
      algorithmicTradeIndicator  : Sample(1),
      clientId                   : Sample(4),
      accountBolsa               : Sample(16),
      account                    : Sample(5),
      deaFlag                    : Sample(1),
      decisorId                  : Sample(4),
      executorId                 : Sample(4),
      liquidityProvisionActivity : Sample(1),
      accountMember              : Sample(4),
      lastCapacity               : Sample(1),
      receivedDeptId             : Sample(1),
      persistence                : Sample(1),
      clientDataReference        : Sample(15) ]

EncodeSimpleOrderModificationWithClientDataMessage(message) ==
    message.requestId
        \o message.securityCode
        \o message.orderId
        \o message.side
        \o message.price
        \o message.orderQty
        \o message.algorithmicTradeIndicator
        \o message.clientId
        \o message.accountBolsa
        \o message.account
        \o message.deaFlag
        \o message.decisorId
        \o message.executorId
        \o message.liquidityProvisionActivity
        \o message.accountMember
        \o message.lastCapacity
        \o message.receivedDeptId
        \o message.persistence
        \o message.clientDataReference

DecodeSimpleOrderModificationWithClientDataMessage(bytes) ==
    LET requestId == ReadBytes(bytes, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET securityCode == ReadBytes(requestId.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityCode.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET side == ReadBytes(orderId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET price == ReadBytes(side.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderQty == ReadBytes(price.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET algorithmicTradeIndicator == ReadBytes(orderQty.rest, 1) IN IF ~algorithmicTradeIndicator.ok THEN Fail ELSE
    LET clientId == ReadBytes(algorithmicTradeIndicator.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET accountBolsa == ReadBytes(clientId.rest, 16) IN IF ~accountBolsa.ok THEN Fail ELSE
    LET account == ReadBytes(accountBolsa.rest, 5) IN IF ~account.ok THEN Fail ELSE
    LET deaFlag == ReadBytes(account.rest, 1) IN IF ~deaFlag.ok THEN Fail ELSE
    LET decisorId == ReadBytes(deaFlag.rest, 4) IN IF ~decisorId.ok THEN Fail ELSE
    LET executorId == ReadBytes(decisorId.rest, 4) IN IF ~executorId.ok THEN Fail ELSE
    LET liquidityProvisionActivity == ReadBytes(executorId.rest, 1) IN IF ~liquidityProvisionActivity.ok THEN Fail ELSE
    LET accountMember == ReadBytes(liquidityProvisionActivity.rest, 4) IN IF ~accountMember.ok THEN Fail ELSE
    LET lastCapacity == ReadBytes(accountMember.rest, 1) IN IF ~lastCapacity.ok THEN Fail ELSE
    LET receivedDeptId == ReadBytes(lastCapacity.rest, 1) IN IF ~receivedDeptId.ok THEN Fail ELSE
    LET persistence == ReadBytes(receivedDeptId.rest, 1) IN IF ~persistence.ok THEN Fail ELSE
    LET clientDataReference == ReadBytes(persistence.rest, 15) IN IF ~clientDataReference.ok THEN Fail ELSE
    Ok([ requestId                  |-> requestId.value,
         securityCode               |-> securityCode.value,
         orderId                    |-> orderId.value,
         side                       |-> side.value,
         price                      |-> price.value,
         orderQty                   |-> orderQty.value,
         algorithmicTradeIndicator  |-> algorithmicTradeIndicator.value,
         clientId                   |-> clientId.value,
         accountBolsa               |-> accountBolsa.value,
         account                    |-> account.value,
         deaFlag                    |-> deaFlag.value,
         decisorId                  |-> decisorId.value,
         executorId                 |-> executorId.value,
         liquidityProvisionActivity |-> liquidityProvisionActivity.value,
         accountMember              |-> accountMember.value,
         lastCapacity               |-> lastCapacity.value,
         receivedDeptId             |-> receivedDeptId.value,
         persistence                |-> persistence.value,
         clientDataReference        |-> clientDataReference.value ], clientDataReference.rest)

ZeroSimpleOrderModificationWithClientDataMessage ==
    [ requestId                  |-> [i \in 1 .. 4 |-> 0],
      securityCode               |-> [i \in 1 .. 4 |-> 0],
      orderId                    |-> [i \in 1 .. 4 |-> 0],
      side                       |-> [i \in 1 .. 1 |-> 0],
      price                      |-> [i \in 1 .. 8 |-> 0],
      orderQty                   |-> [i \in 1 .. 4 |-> 0],
      algorithmicTradeIndicator  |-> [i \in 1 .. 1 |-> 0],
      clientId                   |-> [i \in 1 .. 4 |-> 0],
      accountBolsa               |-> [i \in 1 .. 16 |-> 0],
      account                    |-> [i \in 1 .. 5 |-> 0],
      deaFlag                    |-> [i \in 1 .. 1 |-> 0],
      decisorId                  |-> [i \in 1 .. 4 |-> 0],
      executorId                 |-> [i \in 1 .. 4 |-> 0],
      liquidityProvisionActivity |-> [i \in 1 .. 1 |-> 0],
      accountMember              |-> [i \in 1 .. 4 |-> 0],
      lastCapacity               |-> [i \in 1 .. 1 |-> 0],
      receivedDeptId             |-> [i \in 1 .. 1 |-> 0],
      persistence                |-> [i \in 1 .. 1 |-> 0],
      clientDataReference        |-> [i \in 1 .. 15 |-> 0] ]

(* Simple Order Modification With Client Data Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleOrderModificationWithClientDataMessage ==
    { ZeroSimpleOrderModificationWithClientDataMessage }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.algorithmicTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.accountBolsa = one] : one \in Sample(16) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.account = one] : one \in Sample(5) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.deaFlag = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.decisorId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.executorId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.liquidityProvisionActivity = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.accountMember = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.lastCapacity = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.receivedDeptId = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.persistence = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderModificationWithClientDataMessage EXCEPT !.clientDataReference = one] : one \in Sample(15) }

(***************************************************************************)
(* Order Cancellation Request Message: 12 bytes                            *)
(***************************************************************************)

OrderCancellationRequestMessage ==
    [ requestId    : Sample(4),
      securityCode : Sample(4),
      orderId      : Sample(4) ]

EncodeOrderCancellationRequestMessage(message) ==
    message.requestId
        \o message.securityCode
        \o message.orderId

DecodeOrderCancellationRequestMessage(bytes) ==
    LET requestId == ReadBytes(bytes, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET securityCode == ReadBytes(requestId.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET orderId == ReadBytes(securityCode.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    Ok([ requestId    |-> requestId.value,
         securityCode |-> securityCode.value,
         orderId      |-> orderId.value ], orderId.rest)

ZeroOrderCancellationRequestMessage ==
    [ requestId    |-> [i \in 1 .. 4 |-> 0],
      securityCode |-> [i \in 1 .. 4 |-> 0],
      orderId      |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancellation Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancellationRequestMessage ==
    { ZeroOrderCancellationRequestMessage }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.orderId = one] : one \in Sample(4) }

(***************************************************************************)
(* New Quote Message: 34 bytes                                             *)
(***************************************************************************)

NewQuoteMessage ==
    [ requestId    : Sample(4),
      securityCode : Sample(4),
      clientDataId : Sample(2),
      bidSize1     : Sample(4),
      bidPx1       : Sample(8),
      askSize1     : Sample(4),
      askPx1       : Sample(8) ]

EncodeNewQuoteMessage(message) ==
    message.requestId
        \o message.securityCode
        \o message.clientDataId
        \o message.bidSize1
        \o message.bidPx1
        \o message.askSize1
        \o message.askPx1

DecodeNewQuoteMessage(bytes) ==
    LET requestId == ReadBytes(bytes, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET securityCode == ReadBytes(requestId.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET clientDataId == ReadBytes(securityCode.rest, 2) IN IF ~clientDataId.ok THEN Fail ELSE
    LET bidSize1 == ReadBytes(clientDataId.rest, 4) IN IF ~bidSize1.ok THEN Fail ELSE
    LET bidPx1 == ReadBytes(bidSize1.rest, 8) IN IF ~bidPx1.ok THEN Fail ELSE
    LET askSize1 == ReadBytes(bidPx1.rest, 4) IN IF ~askSize1.ok THEN Fail ELSE
    LET askPx1 == ReadBytes(askSize1.rest, 8) IN IF ~askPx1.ok THEN Fail ELSE
    Ok([ requestId    |-> requestId.value,
         securityCode |-> securityCode.value,
         clientDataId |-> clientDataId.value,
         bidSize1     |-> bidSize1.value,
         bidPx1       |-> bidPx1.value,
         askSize1     |-> askSize1.value,
         askPx1       |-> askPx1.value ], askPx1.rest)

ZeroNewQuoteMessage ==
    [ requestId    |-> [i \in 1 .. 4 |-> 0],
      securityCode |-> [i \in 1 .. 4 |-> 0],
      clientDataId |-> [i \in 1 .. 2 |-> 0],
      bidSize1     |-> [i \in 1 .. 4 |-> 0],
      bidPx1       |-> [i \in 1 .. 8 |-> 0],
      askSize1     |-> [i \in 1 .. 4 |-> 0],
      askPx1       |-> [i \in 1 .. 8 |-> 0] ]

(* New Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedNewQuoteMessage ==
    { ZeroNewQuoteMessage }
        \cup { [ZeroNewQuoteMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroNewQuoteMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroNewQuoteMessage EXCEPT !.clientDataId = one] : one \in Sample(2) }
        \cup { [ZeroNewQuoteMessage EXCEPT !.bidSize1 = one] : one \in Sample(4) }
        \cup { [ZeroNewQuoteMessage EXCEPT !.bidPx1 = one] : one \in Sample(8) }
        \cup { [ZeroNewQuoteMessage EXCEPT !.askSize1 = one] : one \in Sample(4) }
        \cup { [ZeroNewQuoteMessage EXCEPT !.askPx1 = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Modification Request Message: 26 bytes                            *)
(***************************************************************************)

QuoteModificationRequestMessage ==
    [ requestId    : Sample(4),
      securityCode : Sample(4),
      clientDataId : Sample(2),
      bidPx1       : Sample(8),
      askPx1       : Sample(8) ]

EncodeQuoteModificationRequestMessage(message) ==
    message.requestId
        \o message.securityCode
        \o message.clientDataId
        \o message.bidPx1
        \o message.askPx1

DecodeQuoteModificationRequestMessage(bytes) ==
    LET requestId == ReadBytes(bytes, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET securityCode == ReadBytes(requestId.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET clientDataId == ReadBytes(securityCode.rest, 2) IN IF ~clientDataId.ok THEN Fail ELSE
    LET bidPx1 == ReadBytes(clientDataId.rest, 8) IN IF ~bidPx1.ok THEN Fail ELSE
    LET askPx1 == ReadBytes(bidPx1.rest, 8) IN IF ~askPx1.ok THEN Fail ELSE
    Ok([ requestId    |-> requestId.value,
         securityCode |-> securityCode.value,
         clientDataId |-> clientDataId.value,
         bidPx1       |-> bidPx1.value,
         askPx1       |-> askPx1.value ], askPx1.rest)

ZeroQuoteModificationRequestMessage ==
    [ requestId    |-> [i \in 1 .. 4 |-> 0],
      securityCode |-> [i \in 1 .. 4 |-> 0],
      clientDataId |-> [i \in 1 .. 2 |-> 0],
      bidPx1       |-> [i \in 1 .. 8 |-> 0],
      askPx1       |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Modification Request Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteModificationRequestMessage ==
    { ZeroQuoteModificationRequestMessage }
        \cup { [ZeroQuoteModificationRequestMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteModificationRequestMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroQuoteModificationRequestMessage EXCEPT !.clientDataId = one] : one \in Sample(2) }
        \cup { [ZeroQuoteModificationRequestMessage EXCEPT !.bidPx1 = one] : one \in Sample(8) }
        \cup { [ZeroQuoteModificationRequestMessage EXCEPT !.askPx1 = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Cancellation Request Message: 10 bytes                            *)
(***************************************************************************)

QuoteCancellationRequestMessage ==
    [ requestId    : Sample(4),
      securityCode : Sample(4),
      clientDataId : Sample(2) ]

EncodeQuoteCancellationRequestMessage(message) ==
    message.requestId
        \o message.securityCode
        \o message.clientDataId

DecodeQuoteCancellationRequestMessage(bytes) ==
    LET requestId == ReadBytes(bytes, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET securityCode == ReadBytes(requestId.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET clientDataId == ReadBytes(securityCode.rest, 2) IN IF ~clientDataId.ok THEN Fail ELSE
    Ok([ requestId    |-> requestId.value,
         securityCode |-> securityCode.value,
         clientDataId |-> clientDataId.value ], clientDataId.rest)

ZeroQuoteCancellationRequestMessage ==
    [ requestId    |-> [i \in 1 .. 4 |-> 0],
      securityCode |-> [i \in 1 .. 4 |-> 0],
      clientDataId |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Cancellation Request Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancellationRequestMessage ==
    { ZeroQuoteCancellationRequestMessage }
        \cup { [ZeroQuoteCancellationRequestMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancellationRequestMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancellationRequestMessage EXCEPT !.clientDataId = one] : one \in Sample(2) }

(***************************************************************************)
(* Mass Orderquote Cancellation Message: 48 bytes                          *)
(***************************************************************************)

MassOrderquoteCancellationMessage ==
    [ requestId          : Sample(4),
      account            : Sample(5),
      securityCode       : Sample(4),
      side               : Sample(1),
      cancellationType   : Sample(1),
      issuer             : Sample(12),
      accountBolsa       : Sample(16),
      accountMember      : Sample(4),
      orderOrQuoteCancel : Sample(1) ]

EncodeMassOrderquoteCancellationMessage(message) ==
    message.requestId
        \o message.account
        \o message.securityCode
        \o message.side
        \o message.cancellationType
        \o message.issuer
        \o message.accountBolsa
        \o message.accountMember
        \o message.orderOrQuoteCancel

DecodeMassOrderquoteCancellationMessage(bytes) ==
    LET requestId == ReadBytes(bytes, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET account == ReadBytes(requestId.rest, 5) IN IF ~account.ok THEN Fail ELSE
    LET securityCode == ReadBytes(account.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET side == ReadBytes(securityCode.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET cancellationType == ReadBytes(side.rest, 1) IN IF ~cancellationType.ok THEN Fail ELSE
    LET issuer == ReadBytes(cancellationType.rest, 12) IN IF ~issuer.ok THEN Fail ELSE
    LET accountBolsa == ReadBytes(issuer.rest, 16) IN IF ~accountBolsa.ok THEN Fail ELSE
    LET accountMember == ReadBytes(accountBolsa.rest, 4) IN IF ~accountMember.ok THEN Fail ELSE
    LET orderOrQuoteCancel == ReadBytes(accountMember.rest, 1) IN IF ~orderOrQuoteCancel.ok THEN Fail ELSE
    Ok([ requestId          |-> requestId.value,
         account            |-> account.value,
         securityCode       |-> securityCode.value,
         side               |-> side.value,
         cancellationType   |-> cancellationType.value,
         issuer             |-> issuer.value,
         accountBolsa       |-> accountBolsa.value,
         accountMember      |-> accountMember.value,
         orderOrQuoteCancel |-> orderOrQuoteCancel.value ], orderOrQuoteCancel.rest)

ZeroMassOrderquoteCancellationMessage ==
    [ requestId          |-> [i \in 1 .. 4 |-> 0],
      account            |-> [i \in 1 .. 5 |-> 0],
      securityCode       |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      cancellationType   |-> [i \in 1 .. 1 |-> 0],
      issuer             |-> [i \in 1 .. 12 |-> 0],
      accountBolsa       |-> [i \in 1 .. 16 |-> 0],
      accountMember      |-> [i \in 1 .. 4 |-> 0],
      orderOrQuoteCancel |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Orderquote Cancellation Message at zero, then each field in turn at the values it is checked at *)
CheckedMassOrderquoteCancellationMessage ==
    { ZeroMassOrderquoteCancellationMessage }
        \cup { [ZeroMassOrderquoteCancellationMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroMassOrderquoteCancellationMessage EXCEPT !.account = one] : one \in Sample(5) }
        \cup { [ZeroMassOrderquoteCancellationMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroMassOrderquoteCancellationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroMassOrderquoteCancellationMessage EXCEPT !.cancellationType = one] : one \in Sample(1) }
        \cup { [ZeroMassOrderquoteCancellationMessage EXCEPT !.issuer = one] : one \in Sample(12) }
        \cup { [ZeroMassOrderquoteCancellationMessage EXCEPT !.accountBolsa = one] : one \in Sample(16) }
        \cup { [ZeroMassOrderquoteCancellationMessage EXCEPT !.accountMember = one] : one \in Sample(4) }
        \cup { [ZeroMassOrderquoteCancellationMessage EXCEPT !.orderOrQuoteCancel = one] : one \in Sample(1) }

(***************************************************************************)
(* Order And Quote Client Data Parameters Ack Nack Message: 69 bytes       *)
(***************************************************************************)

OrderAndQuoteClientDataParametersAckNackMessage ==
    [ sequenceNumber             : Sample(4),
      requestId                  : Sample(4),
      status                     : Sample(1),
      clientDataId               : Sample(2),
      algorithmicTradeIndicator  : Sample(1),
      clientId                   : Sample(4),
      accountBolsa               : Sample(16),
      account                    : Sample(5),
      deaFlag                    : Sample(1),
      decisorId                  : Sample(4),
      executorId                 : Sample(4),
      liquidityProvisionActivity : Sample(1),
      accountMember              : Sample(4),
      lastCapacity               : Sample(1),
      receivedDeptId             : Sample(1),
      persistence                : Sample(1),
      clientDataReference        : Sample(15) ]

EncodeOrderAndQuoteClientDataParametersAckNackMessage(message) ==
    message.sequenceNumber
        \o message.requestId
        \o message.status
        \o message.clientDataId
        \o message.algorithmicTradeIndicator
        \o message.clientId
        \o message.accountBolsa
        \o message.account
        \o message.deaFlag
        \o message.decisorId
        \o message.executorId
        \o message.liquidityProvisionActivity
        \o message.accountMember
        \o message.lastCapacity
        \o message.receivedDeptId
        \o message.persistence
        \o message.clientDataReference

DecodeOrderAndQuoteClientDataParametersAckNackMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET requestId == ReadBytes(sequenceNumber.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET status == ReadBytes(requestId.rest, 1) IN IF ~status.ok THEN Fail ELSE
    LET clientDataId == ReadBytes(status.rest, 2) IN IF ~clientDataId.ok THEN Fail ELSE
    LET algorithmicTradeIndicator == ReadBytes(clientDataId.rest, 1) IN IF ~algorithmicTradeIndicator.ok THEN Fail ELSE
    LET clientId == ReadBytes(algorithmicTradeIndicator.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET accountBolsa == ReadBytes(clientId.rest, 16) IN IF ~accountBolsa.ok THEN Fail ELSE
    LET account == ReadBytes(accountBolsa.rest, 5) IN IF ~account.ok THEN Fail ELSE
    LET deaFlag == ReadBytes(account.rest, 1) IN IF ~deaFlag.ok THEN Fail ELSE
    LET decisorId == ReadBytes(deaFlag.rest, 4) IN IF ~decisorId.ok THEN Fail ELSE
    LET executorId == ReadBytes(decisorId.rest, 4) IN IF ~executorId.ok THEN Fail ELSE
    LET liquidityProvisionActivity == ReadBytes(executorId.rest, 1) IN IF ~liquidityProvisionActivity.ok THEN Fail ELSE
    LET accountMember == ReadBytes(liquidityProvisionActivity.rest, 4) IN IF ~accountMember.ok THEN Fail ELSE
    LET lastCapacity == ReadBytes(accountMember.rest, 1) IN IF ~lastCapacity.ok THEN Fail ELSE
    LET receivedDeptId == ReadBytes(lastCapacity.rest, 1) IN IF ~receivedDeptId.ok THEN Fail ELSE
    LET persistence == ReadBytes(receivedDeptId.rest, 1) IN IF ~persistence.ok THEN Fail ELSE
    LET clientDataReference == ReadBytes(persistence.rest, 15) IN IF ~clientDataReference.ok THEN Fail ELSE
    Ok([ sequenceNumber             |-> sequenceNumber.value,
         requestId                  |-> requestId.value,
         status                     |-> status.value,
         clientDataId               |-> clientDataId.value,
         algorithmicTradeIndicator  |-> algorithmicTradeIndicator.value,
         clientId                   |-> clientId.value,
         accountBolsa               |-> accountBolsa.value,
         account                    |-> account.value,
         deaFlag                    |-> deaFlag.value,
         decisorId                  |-> decisorId.value,
         executorId                 |-> executorId.value,
         liquidityProvisionActivity |-> liquidityProvisionActivity.value,
         accountMember              |-> accountMember.value,
         lastCapacity               |-> lastCapacity.value,
         receivedDeptId             |-> receivedDeptId.value,
         persistence                |-> persistence.value,
         clientDataReference        |-> clientDataReference.value ], clientDataReference.rest)

ZeroOrderAndQuoteClientDataParametersAckNackMessage ==
    [ sequenceNumber             |-> [i \in 1 .. 4 |-> 0],
      requestId                  |-> [i \in 1 .. 4 |-> 0],
      status                     |-> [i \in 1 .. 1 |-> 0],
      clientDataId               |-> [i \in 1 .. 2 |-> 0],
      algorithmicTradeIndicator  |-> [i \in 1 .. 1 |-> 0],
      clientId                   |-> [i \in 1 .. 4 |-> 0],
      accountBolsa               |-> [i \in 1 .. 16 |-> 0],
      account                    |-> [i \in 1 .. 5 |-> 0],
      deaFlag                    |-> [i \in 1 .. 1 |-> 0],
      decisorId                  |-> [i \in 1 .. 4 |-> 0],
      executorId                 |-> [i \in 1 .. 4 |-> 0],
      liquidityProvisionActivity |-> [i \in 1 .. 1 |-> 0],
      accountMember              |-> [i \in 1 .. 4 |-> 0],
      lastCapacity               |-> [i \in 1 .. 1 |-> 0],
      receivedDeptId             |-> [i \in 1 .. 1 |-> 0],
      persistence                |-> [i \in 1 .. 1 |-> 0],
      clientDataReference        |-> [i \in 1 .. 15 |-> 0] ]

(* Order And Quote Client Data Parameters Ack Nack Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAndQuoteClientDataParametersAckNackMessage ==
    { ZeroOrderAndQuoteClientDataParametersAckNackMessage }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.status = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.clientDataId = one] : one \in Sample(2) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.algorithmicTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.accountBolsa = one] : one \in Sample(16) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.account = one] : one \in Sample(5) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.deaFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.decisorId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.executorId = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.liquidityProvisionActivity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.accountMember = one] : one \in Sample(4) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.lastCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.receivedDeptId = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.persistence = one] : one \in Sample(1) }
        \cup { [ZeroOrderAndQuoteClientDataParametersAckNackMessage EXCEPT !.clientDataReference = one] : one \in Sample(15) }

(***************************************************************************)
(* Simple Order Status Message: 70 bytes                                   *)
(***************************************************************************)

SimpleOrderStatusMessage ==
    [ sequenceNumber         : Sample(4),
      securityCode           : Sample(4),
      transactionDateAndTime : Sample(8),
      secondaryOrderId       : Sample(4),
      entryDate              : Sample(4),
      side                   : Sample(1),
      priority               : Sample(4),
      price                  : Sample(8),
      displayQty             : Sample(4),
      altPrice               : Sample(8),
      orderId                : Sample(4),
      secondaryExecId        : Sample(4),
      orderQty               : Sample(4),
      ordStatus              : Sample(1),
      ordRejReason           : Sample(1),
      execType               : Sample(1),
      requestId              : Sample(4),
      clientDataId           : Sample(2) ]

EncodeSimpleOrderStatusMessage(message) ==
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
        \o message.orderId
        \o message.secondaryExecId
        \o message.orderQty
        \o message.ordStatus
        \o message.ordRejReason
        \o message.execType
        \o message.requestId
        \o message.clientDataId

DecodeSimpleOrderStatusMessage(bytes) ==
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
    LET orderId == ReadBytes(altPrice.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET secondaryExecId == ReadBytes(orderId.rest, 4) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(secondaryExecId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(orderQty.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ordRejReason == ReadBytes(ordStatus.rest, 1) IN IF ~ordRejReason.ok THEN Fail ELSE
    LET execType == ReadBytes(ordRejReason.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET requestId == ReadBytes(execType.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET clientDataId == ReadBytes(requestId.rest, 2) IN IF ~clientDataId.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         securityCode           |-> securityCode.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         secondaryOrderId       |-> secondaryOrderId.value,
         entryDate              |-> entryDate.value,
         side                   |-> side.value,
         priority               |-> priority.value,
         price                  |-> price.value,
         displayQty             |-> displayQty.value,
         altPrice               |-> altPrice.value,
         orderId                |-> orderId.value,
         secondaryExecId        |-> secondaryExecId.value,
         orderQty               |-> orderQty.value,
         ordStatus              |-> ordStatus.value,
         ordRejReason           |-> ordRejReason.value,
         execType               |-> execType.value,
         requestId              |-> requestId.value,
         clientDataId           |-> clientDataId.value ], clientDataId.rest)

ZeroSimpleOrderStatusMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      securityCode           |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      secondaryOrderId       |-> [i \in 1 .. 4 |-> 0],
      entryDate              |-> [i \in 1 .. 4 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      priority               |-> [i \in 1 .. 4 |-> 0],
      price                  |-> [i \in 1 .. 8 |-> 0],
      displayQty             |-> [i \in 1 .. 4 |-> 0],
      altPrice               |-> [i \in 1 .. 8 |-> 0],
      orderId                |-> [i \in 1 .. 4 |-> 0],
      secondaryExecId        |-> [i \in 1 .. 4 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      ordRejReason           |-> [i \in 1 .. 1 |-> 0],
      execType               |-> [i \in 1 .. 1 |-> 0],
      requestId              |-> [i \in 1 .. 4 |-> 0],
      clientDataId           |-> [i \in 1 .. 2 |-> 0] ]

(* Simple Order Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSimpleOrderStatusMessage ==
    { ZeroSimpleOrderStatusMessage }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.entryDate = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.priority = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.altPrice = one] : one \in Sample(8) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.secondaryExecId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.ordRejReason = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroSimpleOrderStatusMessage EXCEPT !.clientDataId = one] : one \in Sample(2) }

(***************************************************************************)
(* Quote Status Message: 108 bytes                                         *)
(***************************************************************************)

QuoteStatusMessage ==
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
      altPrice2              : Sample(8),
      orderId                : Sample(4),
      secondaryExecId        : Sample(4),
      orderQty               : Sample(4),
      ordStatus              : Sample(1),
      ordRejReason           : Sample(1),
      execType               : Sample(1),
      orderId2               : Sample(4),
      secondaryExecId2       : Sample(4),
      orderQty2              : Sample(4),
      ordStatus2             : Sample(1),
      ordRejReason2          : Sample(1),
      execType2              : Sample(1),
      requestId              : Sample(4),
      clientDataId           : Sample(2) ]

EncodeQuoteStatusMessage(message) ==
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
        \o message.orderId
        \o message.secondaryExecId
        \o message.orderQty
        \o message.ordStatus
        \o message.ordRejReason
        \o message.execType
        \o message.orderId2
        \o message.secondaryExecId2
        \o message.orderQty2
        \o message.ordStatus2
        \o message.ordRejReason2
        \o message.execType2
        \o message.requestId
        \o message.clientDataId

DecodeQuoteStatusMessage(bytes) ==
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
    LET orderId == ReadBytes(altPrice2.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET secondaryExecId == ReadBytes(orderId.rest, 4) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(secondaryExecId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(orderQty.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ordRejReason == ReadBytes(ordStatus.rest, 1) IN IF ~ordRejReason.ok THEN Fail ELSE
    LET execType == ReadBytes(ordRejReason.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET orderId2 == ReadBytes(execType.rest, 4) IN IF ~orderId2.ok THEN Fail ELSE
    LET secondaryExecId2 == ReadBytes(orderId2.rest, 4) IN IF ~secondaryExecId2.ok THEN Fail ELSE
    LET orderQty2 == ReadBytes(secondaryExecId2.rest, 4) IN IF ~orderQty2.ok THEN Fail ELSE
    LET ordStatus2 == ReadBytes(orderQty2.rest, 1) IN IF ~ordStatus2.ok THEN Fail ELSE
    LET ordRejReason2 == ReadBytes(ordStatus2.rest, 1) IN IF ~ordRejReason2.ok THEN Fail ELSE
    LET execType2 == ReadBytes(ordRejReason2.rest, 1) IN IF ~execType2.ok THEN Fail ELSE
    LET requestId == ReadBytes(execType2.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET clientDataId == ReadBytes(requestId.rest, 2) IN IF ~clientDataId.ok THEN Fail ELSE
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
         altPrice2              |-> altPrice2.value,
         orderId                |-> orderId.value,
         secondaryExecId        |-> secondaryExecId.value,
         orderQty               |-> orderQty.value,
         ordStatus              |-> ordStatus.value,
         ordRejReason           |-> ordRejReason.value,
         execType               |-> execType.value,
         orderId2               |-> orderId2.value,
         secondaryExecId2       |-> secondaryExecId2.value,
         orderQty2              |-> orderQty2.value,
         ordStatus2             |-> ordStatus2.value,
         ordRejReason2          |-> ordRejReason2.value,
         execType2              |-> execType2.value,
         requestId              |-> requestId.value,
         clientDataId           |-> clientDataId.value ], clientDataId.rest)

ZeroQuoteStatusMessage ==
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
      altPrice2              |-> [i \in 1 .. 8 |-> 0],
      orderId                |-> [i \in 1 .. 4 |-> 0],
      secondaryExecId        |-> [i \in 1 .. 4 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      ordRejReason           |-> [i \in 1 .. 1 |-> 0],
      execType               |-> [i \in 1 .. 1 |-> 0],
      orderId2               |-> [i \in 1 .. 4 |-> 0],
      secondaryExecId2       |-> [i \in 1 .. 4 |-> 0],
      orderQty2              |-> [i \in 1 .. 4 |-> 0],
      ordStatus2             |-> [i \in 1 .. 1 |-> 0],
      ordRejReason2          |-> [i \in 1 .. 1 |-> 0],
      execType2              |-> [i \in 1 .. 1 |-> 0],
      requestId              |-> [i \in 1 .. 4 |-> 0],
      clientDataId           |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Status Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteStatusMessage ==
    { ZeroQuoteStatusMessage }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.secondaryOrderId2 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.priority = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.altPrice = one] : one \in Sample(8) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.priority2 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.price2 = one] : one \in Sample(8) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.displayQty2 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.altPrice2 = one] : one \in Sample(8) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.secondaryExecId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.ordRejReason = one] : one \in Sample(1) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.orderId2 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.secondaryExecId2 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.orderQty2 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.ordStatus2 = one] : one \in Sample(1) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.ordRejReason2 = one] : one \in Sample(1) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.execType2 = one] : one \in Sample(1) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteStatusMessage EXCEPT !.clientDataId = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Cancel Reject Message: 19 bytes                                   *)
(***************************************************************************)

OrderCancelRejectMessage ==
    [ sequenceNumber         : Sample(4),
      transactionDateAndTime : Sample(8),
      orderId                : Sample(4),
      ordStatus              : Sample(1),
      cxlRejResponseTo       : Sample(1),
      cxlRejReason           : Sample(1) ]

EncodeOrderCancelRejectMessage(message) ==
    message.sequenceNumber
        \o message.transactionDateAndTime
        \o message.orderId
        \o message.ordStatus
        \o message.cxlRejResponseTo
        \o message.cxlRejReason

DecodeOrderCancelRejectMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(sequenceNumber.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET orderId == ReadBytes(transactionDateAndTime.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(orderId.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET cxlRejResponseTo == ReadBytes(ordStatus.rest, 1) IN IF ~cxlRejResponseTo.ok THEN Fail ELSE
    LET cxlRejReason == ReadBytes(cxlRejResponseTo.rest, 1) IN IF ~cxlRejReason.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         orderId                |-> orderId.value,
         ordStatus              |-> ordStatus.value,
         cxlRejResponseTo       |-> cxlRejResponseTo.value,
         cxlRejReason           |-> cxlRejReason.value ], cxlRejReason.rest)

ZeroOrderCancelRejectMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      orderId                |-> [i \in 1 .. 4 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      cxlRejResponseTo       |-> [i \in 1 .. 1 |-> 0],
      cxlRejReason           |-> [i \in 1 .. 1 |-> 0] ]

(* Order Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRejectMessage ==
    { ZeroOrderCancelRejectMessage }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.cxlRejResponseTo = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.cxlRejReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Orderquote Cancellation Completion Message: 19 bytes               *)
(***************************************************************************)

MassOrderquoteCancellationCompletionMessage ==
    [ sequenceNumber         : Sample(4),
      transactionDateAndTime : Sample(8),
      tradingUnit            : Sample(1),
      cancellationType       : Sample(1),
      orderOrQuoteCancel     : Sample(1),
      requestId              : Sample(4) ]

EncodeMassOrderquoteCancellationCompletionMessage(message) ==
    message.sequenceNumber
        \o message.transactionDateAndTime
        \o message.tradingUnit
        \o message.cancellationType
        \o message.orderOrQuoteCancel
        \o message.requestId

DecodeMassOrderquoteCancellationCompletionMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(sequenceNumber.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET tradingUnit == ReadBytes(transactionDateAndTime.rest, 1) IN IF ~tradingUnit.ok THEN Fail ELSE
    LET cancellationType == ReadBytes(tradingUnit.rest, 1) IN IF ~cancellationType.ok THEN Fail ELSE
    LET orderOrQuoteCancel == ReadBytes(cancellationType.rest, 1) IN IF ~orderOrQuoteCancel.ok THEN Fail ELSE
    LET requestId == ReadBytes(orderOrQuoteCancel.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         tradingUnit            |-> tradingUnit.value,
         cancellationType       |-> cancellationType.value,
         orderOrQuoteCancel     |-> orderOrQuoteCancel.value,
         requestId              |-> requestId.value ], requestId.rest)

ZeroMassOrderquoteCancellationCompletionMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      tradingUnit            |-> [i \in 1 .. 1 |-> 0],
      cancellationType       |-> [i \in 1 .. 1 |-> 0],
      orderOrQuoteCancel     |-> [i \in 1 .. 1 |-> 0],
      requestId              |-> [i \in 1 .. 4 |-> 0] ]

(* Mass Orderquote Cancellation Completion Message at zero, then each field in turn at the values it is checked at *)
CheckedMassOrderquoteCancellationCompletionMessage ==
    { ZeroMassOrderquoteCancellationCompletionMessage }
        \cup { [ZeroMassOrderquoteCancellationCompletionMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroMassOrderquoteCancellationCompletionMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroMassOrderquoteCancellationCompletionMessage EXCEPT !.tradingUnit = one] : one \in Sample(1) }
        \cup { [ZeroMassOrderquoteCancellationCompletionMessage EXCEPT !.cancellationType = one] : one \in Sample(1) }
        \cup { [ZeroMassOrderquoteCancellationCompletionMessage EXCEPT !.orderOrQuoteCancel = one] : one \in Sample(1) }
        \cup { [ZeroMassOrderquoteCancellationCompletionMessage EXCEPT !.requestId = one] : one \in Sample(4) }

(***************************************************************************)
(* Mass Orderquote Cancellation Reject Message: 14 bytes                   *)
(***************************************************************************)

MassOrderquoteCancellationRejectMessage ==
    [ sequenceNumber         : Sample(4),
      transactionDateAndTime : Sample(8),
      tradingUnit            : Sample(1),
      massCancelRejectReason : Sample(1) ]

EncodeMassOrderquoteCancellationRejectMessage(message) ==
    message.sequenceNumber
        \o message.transactionDateAndTime
        \o message.tradingUnit
        \o message.massCancelRejectReason

DecodeMassOrderquoteCancellationRejectMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(sequenceNumber.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET tradingUnit == ReadBytes(transactionDateAndTime.rest, 1) IN IF ~tradingUnit.ok THEN Fail ELSE
    LET massCancelRejectReason == ReadBytes(tradingUnit.rest, 1) IN IF ~massCancelRejectReason.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         tradingUnit            |-> tradingUnit.value,
         massCancelRejectReason |-> massCancelRejectReason.value ], massCancelRejectReason.rest)

ZeroMassOrderquoteCancellationRejectMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      tradingUnit            |-> [i \in 1 .. 1 |-> 0],
      massCancelRejectReason |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Orderquote Cancellation Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedMassOrderquoteCancellationRejectMessage ==
    { ZeroMassOrderquoteCancellationRejectMessage }
        \cup { [ZeroMassOrderquoteCancellationRejectMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroMassOrderquoteCancellationRejectMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroMassOrderquoteCancellationRejectMessage EXCEPT !.tradingUnit = one] : one \in Sample(1) }
        \cup { [ZeroMassOrderquoteCancellationRejectMessage EXCEPT !.massCancelRejectReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Business Message Reject Message: 79 bytes                               *)
(***************************************************************************)

BusinessMessageRejectMessage ==
    [ sequenceNumber         : Sample(4),
      transactionDateAndTime : Sample(8),
      refMsgType             : Sample(1),
      businessRejectReason   : Sample(1),
      textC65                : Sample(65) ]

EncodeBusinessMessageRejectMessage(message) ==
    message.sequenceNumber
        \o message.transactionDateAndTime
        \o message.refMsgType
        \o message.businessRejectReason
        \o message.textC65

DecodeBusinessMessageRejectMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(sequenceNumber.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET refMsgType == ReadBytes(transactionDateAndTime.rest, 1) IN IF ~refMsgType.ok THEN Fail ELSE
    LET businessRejectReason == ReadBytes(refMsgType.rest, 1) IN IF ~businessRejectReason.ok THEN Fail ELSE
    LET textC65 == ReadBytes(businessRejectReason.rest, 65) IN IF ~textC65.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         refMsgType             |-> refMsgType.value,
         businessRejectReason   |-> businessRejectReason.value,
         textC65                |-> textC65.value ], textC65.rest)

ZeroBusinessMessageRejectMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      refMsgType             |-> [i \in 1 .. 1 |-> 0],
      businessRejectReason   |-> [i \in 1 .. 1 |-> 0],
      textC65                |-> [i \in 1 .. 65 |-> 0] ]

(* Business Message Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedBusinessMessageRejectMessage ==
    { ZeroBusinessMessageRejectMessage }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.refMsgType = one] : one \in Sample(1) }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.businessRejectReason = one] : one \in Sample(1) }
        \cup { [ZeroBusinessMessageRejectMessage EXCEPT !.textC65 = one] : one \in Sample(65) }

(***************************************************************************)
(* Execution Private Information 2 Legs Message: 184 bytes                 *)
(***************************************************************************)

ExecutionPrivateInformation2LegsMessage ==
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
      orderId                : Sample(4),
      secondaryExecId        : Sample(4),
      orderQty               : Sample(4),
      ordStatus              : Sample(1),
      ccpCode                : Sample(1),
      aggressorIndicator     : Sample(1),
      requestId              : Sample(4),
      clientDataId           : Sample(2),
      secondaryOrderId2      : Sample(4),
      entryDate2             : Sample(4),
      priority2              : Sample(4),
      price2                 : Sample(8),
      displayQty2            : Sample(4),
      altPrice2              : Sample(8),
      orderId2               : Sample(4),
      secondaryExecId2       : Sample(4),
      orderQty2              : Sample(4),
      ordStatus2             : Sample(1),
      ccpCode2               : Sample(1),
      aggressorIndicator2    : Sample(1),
      requestId2             : Sample(4),
      clientDataId2U2        : Sample(2) ]

EncodeExecutionPrivateInformation2LegsMessage(message) ==
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
        \o message.orderId
        \o message.secondaryExecId
        \o message.orderQty
        \o message.ordStatus
        \o message.ccpCode
        \o message.aggressorIndicator
        \o message.requestId
        \o message.clientDataId
        \o message.secondaryOrderId2
        \o message.entryDate2
        \o message.priority2
        \o message.price2
        \o message.displayQty2
        \o message.altPrice2
        \o message.orderId2
        \o message.secondaryExecId2
        \o message.orderQty2
        \o message.ordStatus2
        \o message.ccpCode2
        \o message.aggressorIndicator2
        \o message.requestId2
        \o message.clientDataId2U2

DecodeExecutionPrivateInformation2LegsMessage(bytes) ==
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
    LET orderId == ReadBytes(altPrice.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET secondaryExecId == ReadBytes(orderId.rest, 4) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(secondaryExecId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(orderQty.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ccpCode == ReadBytes(ordStatus.rest, 1) IN IF ~ccpCode.ok THEN Fail ELSE
    LET aggressorIndicator == ReadBytes(ccpCode.rest, 1) IN IF ~aggressorIndicator.ok THEN Fail ELSE
    LET requestId == ReadBytes(aggressorIndicator.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET clientDataId == ReadBytes(requestId.rest, 2) IN IF ~clientDataId.ok THEN Fail ELSE
    LET secondaryOrderId2 == ReadBytes(clientDataId.rest, 4) IN IF ~secondaryOrderId2.ok THEN Fail ELSE
    LET entryDate2 == ReadBytes(secondaryOrderId2.rest, 4) IN IF ~entryDate2.ok THEN Fail ELSE
    LET priority2 == ReadBytes(entryDate2.rest, 4) IN IF ~priority2.ok THEN Fail ELSE
    LET price2 == ReadBytes(priority2.rest, 8) IN IF ~price2.ok THEN Fail ELSE
    LET displayQty2 == ReadBytes(price2.rest, 4) IN IF ~displayQty2.ok THEN Fail ELSE
    LET altPrice2 == ReadBytes(displayQty2.rest, 8) IN IF ~altPrice2.ok THEN Fail ELSE
    LET orderId2 == ReadBytes(altPrice2.rest, 4) IN IF ~orderId2.ok THEN Fail ELSE
    LET secondaryExecId2 == ReadBytes(orderId2.rest, 4) IN IF ~secondaryExecId2.ok THEN Fail ELSE
    LET orderQty2 == ReadBytes(secondaryExecId2.rest, 4) IN IF ~orderQty2.ok THEN Fail ELSE
    LET ordStatus2 == ReadBytes(orderQty2.rest, 1) IN IF ~ordStatus2.ok THEN Fail ELSE
    LET ccpCode2 == ReadBytes(ordStatus2.rest, 1) IN IF ~ccpCode2.ok THEN Fail ELSE
    LET aggressorIndicator2 == ReadBytes(ccpCode2.rest, 1) IN IF ~aggressorIndicator2.ok THEN Fail ELSE
    LET requestId2 == ReadBytes(aggressorIndicator2.rest, 4) IN IF ~requestId2.ok THEN Fail ELSE
    LET clientDataId2U2 == ReadBytes(requestId2.rest, 2) IN IF ~clientDataId2U2.ok THEN Fail ELSE
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
         orderId                |-> orderId.value,
         secondaryExecId        |-> secondaryExecId.value,
         orderQty               |-> orderQty.value,
         ordStatus              |-> ordStatus.value,
         ccpCode                |-> ccpCode.value,
         aggressorIndicator     |-> aggressorIndicator.value,
         requestId              |-> requestId.value,
         clientDataId           |-> clientDataId.value,
         secondaryOrderId2      |-> secondaryOrderId2.value,
         entryDate2             |-> entryDate2.value,
         priority2              |-> priority2.value,
         price2                 |-> price2.value,
         displayQty2            |-> displayQty2.value,
         altPrice2              |-> altPrice2.value,
         orderId2               |-> orderId2.value,
         secondaryExecId2       |-> secondaryExecId2.value,
         orderQty2              |-> orderQty2.value,
         ordStatus2             |-> ordStatus2.value,
         ccpCode2               |-> ccpCode2.value,
         aggressorIndicator2    |-> aggressorIndicator2.value,
         requestId2             |-> requestId2.value,
         clientDataId2U2        |-> clientDataId2U2.value ], clientDataId2U2.rest)

ZeroExecutionPrivateInformation2LegsMessage ==
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
      orderId                |-> [i \in 1 .. 4 |-> 0],
      secondaryExecId        |-> [i \in 1 .. 4 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      ccpCode                |-> [i \in 1 .. 1 |-> 0],
      aggressorIndicator     |-> [i \in 1 .. 1 |-> 0],
      requestId              |-> [i \in 1 .. 4 |-> 0],
      clientDataId           |-> [i \in 1 .. 2 |-> 0],
      secondaryOrderId2      |-> [i \in 1 .. 4 |-> 0],
      entryDate2             |-> [i \in 1 .. 4 |-> 0],
      priority2              |-> [i \in 1 .. 4 |-> 0],
      price2                 |-> [i \in 1 .. 8 |-> 0],
      displayQty2            |-> [i \in 1 .. 4 |-> 0],
      altPrice2              |-> [i \in 1 .. 8 |-> 0],
      orderId2               |-> [i \in 1 .. 4 |-> 0],
      secondaryExecId2       |-> [i \in 1 .. 4 |-> 0],
      orderQty2              |-> [i \in 1 .. 4 |-> 0],
      ordStatus2             |-> [i \in 1 .. 1 |-> 0],
      ccpCode2               |-> [i \in 1 .. 1 |-> 0],
      aggressorIndicator2    |-> [i \in 1 .. 1 |-> 0],
      requestId2             |-> [i \in 1 .. 4 |-> 0],
      clientDataId2U2        |-> [i \in 1 .. 2 |-> 0] ]

(* Execution Private Information 2 Legs Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionPrivateInformation2LegsMessage ==
    { ZeroExecutionPrivateInformation2LegsMessage }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.grossTradeAmt = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.designation = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.algoFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.altLastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.accruedInterestAmt = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.accruedInterestRateP8 = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.entryDate = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.priority = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.altPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.secondaryExecId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.ccpCode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.aggressorIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.clientDataId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.secondaryOrderId2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.entryDate2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.priority2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.price2 = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.displayQty2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.altPrice2 = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.orderId2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.secondaryExecId2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.orderQty2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.ordStatus2 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.ccpCode2 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.aggressorIndicator2 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.requestId2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation2LegsMessage EXCEPT !.clientDataId2U2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Trade Amendment Or Cancellation 1 Leg Buy Private Information     *)
(* Message: 255 bytes                                                      *)
(***************************************************************************)

TradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage ==
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
      lastChangeFlagB1            : Sample(1),
      bencrfptFlag                : Sample(1),
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
      amendedTradeDate            : Sample(4),
      brokerTrader                : Sample(3),
      brokerText                  : Sample(15),
      secondaryOrderId            : Sample(4),
      entryDate                   : Sample(4),
      priority                    : Sample(4),
      price                       : Sample(8),
      displayQty                  : Sample(4),
      altPrice                    : Sample(8),
      orderId                     : Sample(4),
      secondaryExecId             : Sample(4),
      orderQty                    : Sample(4),
      ordStatus                   : Sample(1),
      ccpCode                     : Sample(1),
      aggressorIndicator          : Sample(1),
      requestId                   : Sample(4),
      clientDataId                : Sample(2),
      algorithmicTradeIndicator   : Sample(1),
      clientId                    : Sample(4),
      accountBolsa                : Sample(16),
      account                     : Sample(5),
      deaFlag                     : Sample(1),
      decisorId                   : Sample(4),
      executorId                  : Sample(4),
      liquidityProvisionActivity  : Sample(1),
      accountMember               : Sample(4),
      lastCapacity                : Sample(1),
      receivedDeptId              : Sample(1),
      persistence                 : Sample(1),
      member                      : Sample(4),
      trader                      : Sample(3),
      subMember                   : Sample(1),
      crossId                     : Sample(4),
      orderSecurityCode           : Sample(4) ]

EncodeTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage(message) ==
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
        \o message.lastChangeFlagB1
        \o message.bencrfptFlag
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
        \o message.brokerTrader
        \o message.brokerText
        \o message.secondaryOrderId
        \o message.entryDate
        \o message.priority
        \o message.price
        \o message.displayQty
        \o message.altPrice
        \o message.orderId
        \o message.secondaryExecId
        \o message.orderQty
        \o message.ordStatus
        \o message.ccpCode
        \o message.aggressorIndicator
        \o message.requestId
        \o message.clientDataId
        \o message.algorithmicTradeIndicator
        \o message.clientId
        \o message.accountBolsa
        \o message.account
        \o message.deaFlag
        \o message.decisorId
        \o message.executorId
        \o message.liquidityProvisionActivity
        \o message.accountMember
        \o message.lastCapacity
        \o message.receivedDeptId
        \o message.persistence
        \o message.member
        \o message.trader
        \o message.subMember
        \o message.crossId
        \o message.orderSecurityCode

DecodeTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage(bytes) ==
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
    LET lastChangeFlagB1 == ReadBytes(transactionCategory.rest, 1) IN IF ~lastChangeFlagB1.ok THEN Fail ELSE
    LET bencrfptFlag == ReadBytes(lastChangeFlagB1.rest, 1) IN IF ~bencrfptFlag.ok THEN Fail ELSE
    LET tradePriceCondition == ReadBytes(bencrfptFlag.rest, 1) IN IF ~tradePriceCondition.ok THEN Fail ELSE
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
    LET brokerTrader == ReadBytes(amendedTradeDate.rest, 3) IN IF ~brokerTrader.ok THEN Fail ELSE
    LET brokerText == ReadBytes(brokerTrader.rest, 15) IN IF ~brokerText.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(brokerText.rest, 4) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET entryDate == ReadBytes(secondaryOrderId.rest, 4) IN IF ~entryDate.ok THEN Fail ELSE
    LET priority == ReadBytes(entryDate.rest, 4) IN IF ~priority.ok THEN Fail ELSE
    LET price == ReadBytes(priority.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET displayQty == ReadBytes(price.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET altPrice == ReadBytes(displayQty.rest, 8) IN IF ~altPrice.ok THEN Fail ELSE
    LET orderId == ReadBytes(altPrice.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET secondaryExecId == ReadBytes(orderId.rest, 4) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(secondaryExecId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(orderQty.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ccpCode == ReadBytes(ordStatus.rest, 1) IN IF ~ccpCode.ok THEN Fail ELSE
    LET aggressorIndicator == ReadBytes(ccpCode.rest, 1) IN IF ~aggressorIndicator.ok THEN Fail ELSE
    LET requestId == ReadBytes(aggressorIndicator.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET clientDataId == ReadBytes(requestId.rest, 2) IN IF ~clientDataId.ok THEN Fail ELSE
    LET algorithmicTradeIndicator == ReadBytes(clientDataId.rest, 1) IN IF ~algorithmicTradeIndicator.ok THEN Fail ELSE
    LET clientId == ReadBytes(algorithmicTradeIndicator.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET accountBolsa == ReadBytes(clientId.rest, 16) IN IF ~accountBolsa.ok THEN Fail ELSE
    LET account == ReadBytes(accountBolsa.rest, 5) IN IF ~account.ok THEN Fail ELSE
    LET deaFlag == ReadBytes(account.rest, 1) IN IF ~deaFlag.ok THEN Fail ELSE
    LET decisorId == ReadBytes(deaFlag.rest, 4) IN IF ~decisorId.ok THEN Fail ELSE
    LET executorId == ReadBytes(decisorId.rest, 4) IN IF ~executorId.ok THEN Fail ELSE
    LET liquidityProvisionActivity == ReadBytes(executorId.rest, 1) IN IF ~liquidityProvisionActivity.ok THEN Fail ELSE
    LET accountMember == ReadBytes(liquidityProvisionActivity.rest, 4) IN IF ~accountMember.ok THEN Fail ELSE
    LET lastCapacity == ReadBytes(accountMember.rest, 1) IN IF ~lastCapacity.ok THEN Fail ELSE
    LET receivedDeptId == ReadBytes(lastCapacity.rest, 1) IN IF ~receivedDeptId.ok THEN Fail ELSE
    LET persistence == ReadBytes(receivedDeptId.rest, 1) IN IF ~persistence.ok THEN Fail ELSE
    LET member == ReadBytes(persistence.rest, 4) IN IF ~member.ok THEN Fail ELSE
    LET trader == ReadBytes(member.rest, 3) IN IF ~trader.ok THEN Fail ELSE
    LET subMember == ReadBytes(trader.rest, 1) IN IF ~subMember.ok THEN Fail ELSE
    LET crossId == ReadBytes(subMember.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET orderSecurityCode == ReadBytes(crossId.rest, 4) IN IF ~orderSecurityCode.ok THEN Fail ELSE
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
         lastChangeFlagB1            |-> lastChangeFlagB1.value,
         bencrfptFlag                |-> bencrfptFlag.value,
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
         amendedTradeDate            |-> amendedTradeDate.value,
         brokerTrader                |-> brokerTrader.value,
         brokerText                  |-> brokerText.value,
         secondaryOrderId            |-> secondaryOrderId.value,
         entryDate                   |-> entryDate.value,
         priority                    |-> priority.value,
         price                       |-> price.value,
         displayQty                  |-> displayQty.value,
         altPrice                    |-> altPrice.value,
         orderId                     |-> orderId.value,
         secondaryExecId             |-> secondaryExecId.value,
         orderQty                    |-> orderQty.value,
         ordStatus                   |-> ordStatus.value,
         ccpCode                     |-> ccpCode.value,
         aggressorIndicator          |-> aggressorIndicator.value,
         requestId                   |-> requestId.value,
         clientDataId                |-> clientDataId.value,
         algorithmicTradeIndicator   |-> algorithmicTradeIndicator.value,
         clientId                    |-> clientId.value,
         accountBolsa                |-> accountBolsa.value,
         account                     |-> account.value,
         deaFlag                     |-> deaFlag.value,
         decisorId                   |-> decisorId.value,
         executorId                  |-> executorId.value,
         liquidityProvisionActivity  |-> liquidityProvisionActivity.value,
         accountMember               |-> accountMember.value,
         lastCapacity                |-> lastCapacity.value,
         receivedDeptId              |-> receivedDeptId.value,
         persistence                 |-> persistence.value,
         member                      |-> member.value,
         trader                      |-> trader.value,
         subMember                   |-> subMember.value,
         crossId                     |-> crossId.value,
         orderSecurityCode           |-> orderSecurityCode.value ], orderSecurityCode.rest)

ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage ==
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
      lastChangeFlagB1            |-> [i \in 1 .. 1 |-> 0],
      bencrfptFlag                |-> [i \in 1 .. 1 |-> 0],
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
      amendedTradeDate            |-> [i \in 1 .. 4 |-> 0],
      brokerTrader                |-> [i \in 1 .. 3 |-> 0],
      brokerText                  |-> [i \in 1 .. 15 |-> 0],
      secondaryOrderId            |-> [i \in 1 .. 4 |-> 0],
      entryDate                   |-> [i \in 1 .. 4 |-> 0],
      priority                    |-> [i \in 1 .. 4 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      displayQty                  |-> [i \in 1 .. 4 |-> 0],
      altPrice                    |-> [i \in 1 .. 8 |-> 0],
      orderId                     |-> [i \in 1 .. 4 |-> 0],
      secondaryExecId             |-> [i \in 1 .. 4 |-> 0],
      orderQty                    |-> [i \in 1 .. 4 |-> 0],
      ordStatus                   |-> [i \in 1 .. 1 |-> 0],
      ccpCode                     |-> [i \in 1 .. 1 |-> 0],
      aggressorIndicator          |-> [i \in 1 .. 1 |-> 0],
      requestId                   |-> [i \in 1 .. 4 |-> 0],
      clientDataId                |-> [i \in 1 .. 2 |-> 0],
      algorithmicTradeIndicator   |-> [i \in 1 .. 1 |-> 0],
      clientId                    |-> [i \in 1 .. 4 |-> 0],
      accountBolsa                |-> [i \in 1 .. 16 |-> 0],
      account                     |-> [i \in 1 .. 5 |-> 0],
      deaFlag                     |-> [i \in 1 .. 1 |-> 0],
      decisorId                   |-> [i \in 1 .. 4 |-> 0],
      executorId                  |-> [i \in 1 .. 4 |-> 0],
      liquidityProvisionActivity  |-> [i \in 1 .. 1 |-> 0],
      accountMember               |-> [i \in 1 .. 4 |-> 0],
      lastCapacity                |-> [i \in 1 .. 1 |-> 0],
      receivedDeptId              |-> [i \in 1 .. 1 |-> 0],
      persistence                 |-> [i \in 1 .. 1 |-> 0],
      member                      |-> [i \in 1 .. 4 |-> 0],
      trader                      |-> [i \in 1 .. 3 |-> 0],
      subMember                   |-> [i \in 1 .. 1 |-> 0],
      crossId                     |-> [i \in 1 .. 4 |-> 0],
      orderSecurityCode           |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Trade Amendment Or Cancellation 1 Leg Buy Private Information Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage ==
    { ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.grossTradeAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.designation = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.algoFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.altLastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.accruedInterestAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.accruedInterestRateP8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.lastChangeFlagB1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.bencrfptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.tradePriceCondition = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.preTradeTransparencyWaiver = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.deferralWaiver = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.postDeferralPublicationType = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.publishDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.tradeSessionDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.settlDate2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.endCash = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.amendedTradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.execRefId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.amendedTradeDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.brokerTrader = one] : one \in Sample(3) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.brokerText = one] : one \in Sample(15) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.entryDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.priority = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.altPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.secondaryExecId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.ccpCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.aggressorIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.clientDataId = one] : one \in Sample(2) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.algorithmicTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.accountBolsa = one] : one \in Sample(16) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.account = one] : one \in Sample(5) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.deaFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.decisorId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.executorId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.liquidityProvisionActivity = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.accountMember = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.lastCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.receivedDeptId = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.persistence = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.member = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.trader = one] : one \in Sample(3) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.subMember = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage EXCEPT !.orderSecurityCode = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Trade Amendment Or Cancellation 1 Leg Sell Private Information    *)
(* Message: 255 bytes                                                      *)
(***************************************************************************)

TradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage ==
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
      lastChangeFlagB1            : Sample(1),
      bencrfptFlag                : Sample(1),
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
      amendedTradeDate            : Sample(4),
      brokerTrader                : Sample(3),
      brokerText                  : Sample(15),
      secondaryOrderId            : Sample(4),
      entryDate                   : Sample(4),
      priority                    : Sample(4),
      price                       : Sample(8),
      displayQty                  : Sample(4),
      altPrice                    : Sample(8),
      orderId                     : Sample(4),
      secondaryExecId             : Sample(4),
      orderQty                    : Sample(4),
      ordStatus                   : Sample(1),
      ccpCode                     : Sample(1),
      aggressorIndicator          : Sample(1),
      requestId                   : Sample(4),
      clientDataId                : Sample(2),
      algorithmicTradeIndicator   : Sample(1),
      clientId                    : Sample(4),
      accountBolsa                : Sample(16),
      account                     : Sample(5),
      deaFlag                     : Sample(1),
      decisorId                   : Sample(4),
      executorId                  : Sample(4),
      liquidityProvisionActivity  : Sample(1),
      accountMember               : Sample(4),
      lastCapacity                : Sample(1),
      receivedDeptId              : Sample(1),
      persistence                 : Sample(1),
      member                      : Sample(4),
      trader                      : Sample(3),
      subMember                   : Sample(1),
      crossId                     : Sample(4),
      orderSecurityCode           : Sample(4) ]

EncodeTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage(message) ==
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
        \o message.lastChangeFlagB1
        \o message.bencrfptFlag
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
        \o message.brokerTrader
        \o message.brokerText
        \o message.secondaryOrderId
        \o message.entryDate
        \o message.priority
        \o message.price
        \o message.displayQty
        \o message.altPrice
        \o message.orderId
        \o message.secondaryExecId
        \o message.orderQty
        \o message.ordStatus
        \o message.ccpCode
        \o message.aggressorIndicator
        \o message.requestId
        \o message.clientDataId
        \o message.algorithmicTradeIndicator
        \o message.clientId
        \o message.accountBolsa
        \o message.account
        \o message.deaFlag
        \o message.decisorId
        \o message.executorId
        \o message.liquidityProvisionActivity
        \o message.accountMember
        \o message.lastCapacity
        \o message.receivedDeptId
        \o message.persistence
        \o message.member
        \o message.trader
        \o message.subMember
        \o message.crossId
        \o message.orderSecurityCode

DecodeTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage(bytes) ==
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
    LET lastChangeFlagB1 == ReadBytes(transactionCategory.rest, 1) IN IF ~lastChangeFlagB1.ok THEN Fail ELSE
    LET bencrfptFlag == ReadBytes(lastChangeFlagB1.rest, 1) IN IF ~bencrfptFlag.ok THEN Fail ELSE
    LET tradePriceCondition == ReadBytes(bencrfptFlag.rest, 1) IN IF ~tradePriceCondition.ok THEN Fail ELSE
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
    LET brokerTrader == ReadBytes(amendedTradeDate.rest, 3) IN IF ~brokerTrader.ok THEN Fail ELSE
    LET brokerText == ReadBytes(brokerTrader.rest, 15) IN IF ~brokerText.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(brokerText.rest, 4) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET entryDate == ReadBytes(secondaryOrderId.rest, 4) IN IF ~entryDate.ok THEN Fail ELSE
    LET priority == ReadBytes(entryDate.rest, 4) IN IF ~priority.ok THEN Fail ELSE
    LET price == ReadBytes(priority.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET displayQty == ReadBytes(price.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET altPrice == ReadBytes(displayQty.rest, 8) IN IF ~altPrice.ok THEN Fail ELSE
    LET orderId == ReadBytes(altPrice.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET secondaryExecId == ReadBytes(orderId.rest, 4) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(secondaryExecId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(orderQty.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ccpCode == ReadBytes(ordStatus.rest, 1) IN IF ~ccpCode.ok THEN Fail ELSE
    LET aggressorIndicator == ReadBytes(ccpCode.rest, 1) IN IF ~aggressorIndicator.ok THEN Fail ELSE
    LET requestId == ReadBytes(aggressorIndicator.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET clientDataId == ReadBytes(requestId.rest, 2) IN IF ~clientDataId.ok THEN Fail ELSE
    LET algorithmicTradeIndicator == ReadBytes(clientDataId.rest, 1) IN IF ~algorithmicTradeIndicator.ok THEN Fail ELSE
    LET clientId == ReadBytes(algorithmicTradeIndicator.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET accountBolsa == ReadBytes(clientId.rest, 16) IN IF ~accountBolsa.ok THEN Fail ELSE
    LET account == ReadBytes(accountBolsa.rest, 5) IN IF ~account.ok THEN Fail ELSE
    LET deaFlag == ReadBytes(account.rest, 1) IN IF ~deaFlag.ok THEN Fail ELSE
    LET decisorId == ReadBytes(deaFlag.rest, 4) IN IF ~decisorId.ok THEN Fail ELSE
    LET executorId == ReadBytes(decisorId.rest, 4) IN IF ~executorId.ok THEN Fail ELSE
    LET liquidityProvisionActivity == ReadBytes(executorId.rest, 1) IN IF ~liquidityProvisionActivity.ok THEN Fail ELSE
    LET accountMember == ReadBytes(liquidityProvisionActivity.rest, 4) IN IF ~accountMember.ok THEN Fail ELSE
    LET lastCapacity == ReadBytes(accountMember.rest, 1) IN IF ~lastCapacity.ok THEN Fail ELSE
    LET receivedDeptId == ReadBytes(lastCapacity.rest, 1) IN IF ~receivedDeptId.ok THEN Fail ELSE
    LET persistence == ReadBytes(receivedDeptId.rest, 1) IN IF ~persistence.ok THEN Fail ELSE
    LET member == ReadBytes(persistence.rest, 4) IN IF ~member.ok THEN Fail ELSE
    LET trader == ReadBytes(member.rest, 3) IN IF ~trader.ok THEN Fail ELSE
    LET subMember == ReadBytes(trader.rest, 1) IN IF ~subMember.ok THEN Fail ELSE
    LET crossId == ReadBytes(subMember.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET orderSecurityCode == ReadBytes(crossId.rest, 4) IN IF ~orderSecurityCode.ok THEN Fail ELSE
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
         lastChangeFlagB1            |-> lastChangeFlagB1.value,
         bencrfptFlag                |-> bencrfptFlag.value,
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
         amendedTradeDate            |-> amendedTradeDate.value,
         brokerTrader                |-> brokerTrader.value,
         brokerText                  |-> brokerText.value,
         secondaryOrderId            |-> secondaryOrderId.value,
         entryDate                   |-> entryDate.value,
         priority                    |-> priority.value,
         price                       |-> price.value,
         displayQty                  |-> displayQty.value,
         altPrice                    |-> altPrice.value,
         orderId                     |-> orderId.value,
         secondaryExecId             |-> secondaryExecId.value,
         orderQty                    |-> orderQty.value,
         ordStatus                   |-> ordStatus.value,
         ccpCode                     |-> ccpCode.value,
         aggressorIndicator          |-> aggressorIndicator.value,
         requestId                   |-> requestId.value,
         clientDataId                |-> clientDataId.value,
         algorithmicTradeIndicator   |-> algorithmicTradeIndicator.value,
         clientId                    |-> clientId.value,
         accountBolsa                |-> accountBolsa.value,
         account                     |-> account.value,
         deaFlag                     |-> deaFlag.value,
         decisorId                   |-> decisorId.value,
         executorId                  |-> executorId.value,
         liquidityProvisionActivity  |-> liquidityProvisionActivity.value,
         accountMember               |-> accountMember.value,
         lastCapacity                |-> lastCapacity.value,
         receivedDeptId              |-> receivedDeptId.value,
         persistence                 |-> persistence.value,
         member                      |-> member.value,
         trader                      |-> trader.value,
         subMember                   |-> subMember.value,
         crossId                     |-> crossId.value,
         orderSecurityCode           |-> orderSecurityCode.value ], orderSecurityCode.rest)

ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage ==
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
      lastChangeFlagB1            |-> [i \in 1 .. 1 |-> 0],
      bencrfptFlag                |-> [i \in 1 .. 1 |-> 0],
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
      amendedTradeDate            |-> [i \in 1 .. 4 |-> 0],
      brokerTrader                |-> [i \in 1 .. 3 |-> 0],
      brokerText                  |-> [i \in 1 .. 15 |-> 0],
      secondaryOrderId            |-> [i \in 1 .. 4 |-> 0],
      entryDate                   |-> [i \in 1 .. 4 |-> 0],
      priority                    |-> [i \in 1 .. 4 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      displayQty                  |-> [i \in 1 .. 4 |-> 0],
      altPrice                    |-> [i \in 1 .. 8 |-> 0],
      orderId                     |-> [i \in 1 .. 4 |-> 0],
      secondaryExecId             |-> [i \in 1 .. 4 |-> 0],
      orderQty                    |-> [i \in 1 .. 4 |-> 0],
      ordStatus                   |-> [i \in 1 .. 1 |-> 0],
      ccpCode                     |-> [i \in 1 .. 1 |-> 0],
      aggressorIndicator          |-> [i \in 1 .. 1 |-> 0],
      requestId                   |-> [i \in 1 .. 4 |-> 0],
      clientDataId                |-> [i \in 1 .. 2 |-> 0],
      algorithmicTradeIndicator   |-> [i \in 1 .. 1 |-> 0],
      clientId                    |-> [i \in 1 .. 4 |-> 0],
      accountBolsa                |-> [i \in 1 .. 16 |-> 0],
      account                     |-> [i \in 1 .. 5 |-> 0],
      deaFlag                     |-> [i \in 1 .. 1 |-> 0],
      decisorId                   |-> [i \in 1 .. 4 |-> 0],
      executorId                  |-> [i \in 1 .. 4 |-> 0],
      liquidityProvisionActivity  |-> [i \in 1 .. 1 |-> 0],
      accountMember               |-> [i \in 1 .. 4 |-> 0],
      lastCapacity                |-> [i \in 1 .. 1 |-> 0],
      receivedDeptId              |-> [i \in 1 .. 1 |-> 0],
      persistence                 |-> [i \in 1 .. 1 |-> 0],
      member                      |-> [i \in 1 .. 4 |-> 0],
      trader                      |-> [i \in 1 .. 3 |-> 0],
      subMember                   |-> [i \in 1 .. 1 |-> 0],
      crossId                     |-> [i \in 1 .. 4 |-> 0],
      orderSecurityCode           |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Trade Amendment Or Cancellation 1 Leg Sell Private Information Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage ==
    { ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.grossTradeAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.designation = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.algoFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.altLastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.accruedInterestAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.accruedInterestRateP8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.lastChangeFlagB1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.bencrfptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.tradePriceCondition = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.preTradeTransparencyWaiver = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.deferralWaiver = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.postDeferralPublicationType = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.publishDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.tradeSessionDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.settlDate2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.endCash = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.amendedTradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.execRefId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.amendedTradeDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.brokerTrader = one] : one \in Sample(3) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.brokerText = one] : one \in Sample(15) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.entryDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.priority = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.altPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.secondaryExecId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.ccpCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.aggressorIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.clientDataId = one] : one \in Sample(2) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.algorithmicTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.accountBolsa = one] : one \in Sample(16) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.account = one] : one \in Sample(5) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.deaFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.decisorId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.executorId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.liquidityProvisionActivity = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.accountMember = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.lastCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.receivedDeptId = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.persistence = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.member = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.trader = one] : one \in Sample(3) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.subMember = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage EXCEPT !.orderSecurityCode = one] : one \in Sample(4) }

(***************************************************************************)
(* Trade Trade Amendment Or Cancellation 2 Legs Private Information        *)
(* Message: 367 bytes                                                      *)
(***************************************************************************)

TradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage ==
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
      lastChangeFlagB1            : Sample(1),
      bencrfptFlag                : Sample(1),
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
      amendedTradeDate            : Sample(4),
      brokerTrader                : Sample(3),
      brokerText                  : Sample(15),
      secondaryOrderId            : Sample(4),
      entryDate                   : Sample(4),
      priority                    : Sample(4),
      price                       : Sample(8),
      displayQty                  : Sample(4),
      altPrice                    : Sample(8),
      orderId                     : Sample(4),
      secondaryExecId             : Sample(4),
      orderQty                    : Sample(4),
      ordStatus                   : Sample(1),
      ccpCode                     : Sample(1),
      aggressorIndicator          : Sample(1),
      requestId                   : Sample(4),
      clientDataId                : Sample(2),
      algorithmicTradeIndicator   : Sample(1),
      clientId                    : Sample(4),
      accountBolsa                : Sample(16),
      account                     : Sample(5),
      deaFlag                     : Sample(1),
      decisorId                   : Sample(4),
      executorId                  : Sample(4),
      liquidityProvisionActivity  : Sample(1),
      accountMember               : Sample(4),
      lastCapacity                : Sample(1),
      receivedDeptId              : Sample(1),
      persistence                 : Sample(1),
      member                      : Sample(4),
      trader                      : Sample(3),
      subMember                   : Sample(1),
      crossId                     : Sample(4),
      orderSecurityCode           : Sample(4),
      secondaryOrderId2           : Sample(4),
      entryDate2                  : Sample(4),
      priority2                   : Sample(4),
      price2                      : Sample(8),
      displayQty2                 : Sample(4),
      altPrice2                   : Sample(8),
      orderId2                    : Sample(4),
      secondaryExecId2            : Sample(4),
      orderQty2                   : Sample(4),
      ordStatus2                  : Sample(1),
      ccpCode2                    : Sample(1),
      aggressorIndicator2         : Sample(1),
      requestId2                  : Sample(4),
      clientDataId2U2             : Sample(2),
      algorithmicTradeIndicator2  : Sample(1),
      clientId2                   : Sample(4),
      accountBolsa2               : Sample(16),
      account2                    : Sample(5),
      deaFlag2                    : Sample(1),
      decisorId2                  : Sample(4),
      executorId2                 : Sample(4),
      liquidityProvisionActivity2 : Sample(1),
      accountMember2              : Sample(4),
      lastCapacity2               : Sample(1),
      receivedDeptId2             : Sample(1),
      persistence2                : Sample(1),
      member2                     : Sample(4),
      trader2                     : Sample(3),
      subMember2                  : Sample(1),
      crossId2                    : Sample(4),
      orderSecurityCode2          : Sample(4) ]

EncodeTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage(message) ==
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
        \o message.lastChangeFlagB1
        \o message.bencrfptFlag
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
        \o message.brokerTrader
        \o message.brokerText
        \o message.secondaryOrderId
        \o message.entryDate
        \o message.priority
        \o message.price
        \o message.displayQty
        \o message.altPrice
        \o message.orderId
        \o message.secondaryExecId
        \o message.orderQty
        \o message.ordStatus
        \o message.ccpCode
        \o message.aggressorIndicator
        \o message.requestId
        \o message.clientDataId
        \o message.algorithmicTradeIndicator
        \o message.clientId
        \o message.accountBolsa
        \o message.account
        \o message.deaFlag
        \o message.decisorId
        \o message.executorId
        \o message.liquidityProvisionActivity
        \o message.accountMember
        \o message.lastCapacity
        \o message.receivedDeptId
        \o message.persistence
        \o message.member
        \o message.trader
        \o message.subMember
        \o message.crossId
        \o message.orderSecurityCode
        \o message.secondaryOrderId2
        \o message.entryDate2
        \o message.priority2
        \o message.price2
        \o message.displayQty2
        \o message.altPrice2
        \o message.orderId2
        \o message.secondaryExecId2
        \o message.orderQty2
        \o message.ordStatus2
        \o message.ccpCode2
        \o message.aggressorIndicator2
        \o message.requestId2
        \o message.clientDataId2U2
        \o message.algorithmicTradeIndicator2
        \o message.clientId2
        \o message.accountBolsa2
        \o message.account2
        \o message.deaFlag2
        \o message.decisorId2
        \o message.executorId2
        \o message.liquidityProvisionActivity2
        \o message.accountMember2
        \o message.lastCapacity2
        \o message.receivedDeptId2
        \o message.persistence2
        \o message.member2
        \o message.trader2
        \o message.subMember2
        \o message.crossId2
        \o message.orderSecurityCode2

DecodeTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage(bytes) ==
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
    LET lastChangeFlagB1 == ReadBytes(transactionCategory.rest, 1) IN IF ~lastChangeFlagB1.ok THEN Fail ELSE
    LET bencrfptFlag == ReadBytes(lastChangeFlagB1.rest, 1) IN IF ~bencrfptFlag.ok THEN Fail ELSE
    LET tradePriceCondition == ReadBytes(bencrfptFlag.rest, 1) IN IF ~tradePriceCondition.ok THEN Fail ELSE
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
    LET brokerTrader == ReadBytes(amendedTradeDate.rest, 3) IN IF ~brokerTrader.ok THEN Fail ELSE
    LET brokerText == ReadBytes(brokerTrader.rest, 15) IN IF ~brokerText.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(brokerText.rest, 4) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET entryDate == ReadBytes(secondaryOrderId.rest, 4) IN IF ~entryDate.ok THEN Fail ELSE
    LET priority == ReadBytes(entryDate.rest, 4) IN IF ~priority.ok THEN Fail ELSE
    LET price == ReadBytes(priority.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET displayQty == ReadBytes(price.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET altPrice == ReadBytes(displayQty.rest, 8) IN IF ~altPrice.ok THEN Fail ELSE
    LET orderId == ReadBytes(altPrice.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET secondaryExecId == ReadBytes(orderId.rest, 4) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(secondaryExecId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(orderQty.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ccpCode == ReadBytes(ordStatus.rest, 1) IN IF ~ccpCode.ok THEN Fail ELSE
    LET aggressorIndicator == ReadBytes(ccpCode.rest, 1) IN IF ~aggressorIndicator.ok THEN Fail ELSE
    LET requestId == ReadBytes(aggressorIndicator.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET clientDataId == ReadBytes(requestId.rest, 2) IN IF ~clientDataId.ok THEN Fail ELSE
    LET algorithmicTradeIndicator == ReadBytes(clientDataId.rest, 1) IN IF ~algorithmicTradeIndicator.ok THEN Fail ELSE
    LET clientId == ReadBytes(algorithmicTradeIndicator.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET accountBolsa == ReadBytes(clientId.rest, 16) IN IF ~accountBolsa.ok THEN Fail ELSE
    LET account == ReadBytes(accountBolsa.rest, 5) IN IF ~account.ok THEN Fail ELSE
    LET deaFlag == ReadBytes(account.rest, 1) IN IF ~deaFlag.ok THEN Fail ELSE
    LET decisorId == ReadBytes(deaFlag.rest, 4) IN IF ~decisorId.ok THEN Fail ELSE
    LET executorId == ReadBytes(decisorId.rest, 4) IN IF ~executorId.ok THEN Fail ELSE
    LET liquidityProvisionActivity == ReadBytes(executorId.rest, 1) IN IF ~liquidityProvisionActivity.ok THEN Fail ELSE
    LET accountMember == ReadBytes(liquidityProvisionActivity.rest, 4) IN IF ~accountMember.ok THEN Fail ELSE
    LET lastCapacity == ReadBytes(accountMember.rest, 1) IN IF ~lastCapacity.ok THEN Fail ELSE
    LET receivedDeptId == ReadBytes(lastCapacity.rest, 1) IN IF ~receivedDeptId.ok THEN Fail ELSE
    LET persistence == ReadBytes(receivedDeptId.rest, 1) IN IF ~persistence.ok THEN Fail ELSE
    LET member == ReadBytes(persistence.rest, 4) IN IF ~member.ok THEN Fail ELSE
    LET trader == ReadBytes(member.rest, 3) IN IF ~trader.ok THEN Fail ELSE
    LET subMember == ReadBytes(trader.rest, 1) IN IF ~subMember.ok THEN Fail ELSE
    LET crossId == ReadBytes(subMember.rest, 4) IN IF ~crossId.ok THEN Fail ELSE
    LET orderSecurityCode == ReadBytes(crossId.rest, 4) IN IF ~orderSecurityCode.ok THEN Fail ELSE
    LET secondaryOrderId2 == ReadBytes(orderSecurityCode.rest, 4) IN IF ~secondaryOrderId2.ok THEN Fail ELSE
    LET entryDate2 == ReadBytes(secondaryOrderId2.rest, 4) IN IF ~entryDate2.ok THEN Fail ELSE
    LET priority2 == ReadBytes(entryDate2.rest, 4) IN IF ~priority2.ok THEN Fail ELSE
    LET price2 == ReadBytes(priority2.rest, 8) IN IF ~price2.ok THEN Fail ELSE
    LET displayQty2 == ReadBytes(price2.rest, 4) IN IF ~displayQty2.ok THEN Fail ELSE
    LET altPrice2 == ReadBytes(displayQty2.rest, 8) IN IF ~altPrice2.ok THEN Fail ELSE
    LET orderId2 == ReadBytes(altPrice2.rest, 4) IN IF ~orderId2.ok THEN Fail ELSE
    LET secondaryExecId2 == ReadBytes(orderId2.rest, 4) IN IF ~secondaryExecId2.ok THEN Fail ELSE
    LET orderQty2 == ReadBytes(secondaryExecId2.rest, 4) IN IF ~orderQty2.ok THEN Fail ELSE
    LET ordStatus2 == ReadBytes(orderQty2.rest, 1) IN IF ~ordStatus2.ok THEN Fail ELSE
    LET ccpCode2 == ReadBytes(ordStatus2.rest, 1) IN IF ~ccpCode2.ok THEN Fail ELSE
    LET aggressorIndicator2 == ReadBytes(ccpCode2.rest, 1) IN IF ~aggressorIndicator2.ok THEN Fail ELSE
    LET requestId2 == ReadBytes(aggressorIndicator2.rest, 4) IN IF ~requestId2.ok THEN Fail ELSE
    LET clientDataId2U2 == ReadBytes(requestId2.rest, 2) IN IF ~clientDataId2U2.ok THEN Fail ELSE
    LET algorithmicTradeIndicator2 == ReadBytes(clientDataId2U2.rest, 1) IN IF ~algorithmicTradeIndicator2.ok THEN Fail ELSE
    LET clientId2 == ReadBytes(algorithmicTradeIndicator2.rest, 4) IN IF ~clientId2.ok THEN Fail ELSE
    LET accountBolsa2 == ReadBytes(clientId2.rest, 16) IN IF ~accountBolsa2.ok THEN Fail ELSE
    LET account2 == ReadBytes(accountBolsa2.rest, 5) IN IF ~account2.ok THEN Fail ELSE
    LET deaFlag2 == ReadBytes(account2.rest, 1) IN IF ~deaFlag2.ok THEN Fail ELSE
    LET decisorId2 == ReadBytes(deaFlag2.rest, 4) IN IF ~decisorId2.ok THEN Fail ELSE
    LET executorId2 == ReadBytes(decisorId2.rest, 4) IN IF ~executorId2.ok THEN Fail ELSE
    LET liquidityProvisionActivity2 == ReadBytes(executorId2.rest, 1) IN IF ~liquidityProvisionActivity2.ok THEN Fail ELSE
    LET accountMember2 == ReadBytes(liquidityProvisionActivity2.rest, 4) IN IF ~accountMember2.ok THEN Fail ELSE
    LET lastCapacity2 == ReadBytes(accountMember2.rest, 1) IN IF ~lastCapacity2.ok THEN Fail ELSE
    LET receivedDeptId2 == ReadBytes(lastCapacity2.rest, 1) IN IF ~receivedDeptId2.ok THEN Fail ELSE
    LET persistence2 == ReadBytes(receivedDeptId2.rest, 1) IN IF ~persistence2.ok THEN Fail ELSE
    LET member2 == ReadBytes(persistence2.rest, 4) IN IF ~member2.ok THEN Fail ELSE
    LET trader2 == ReadBytes(member2.rest, 3) IN IF ~trader2.ok THEN Fail ELSE
    LET subMember2 == ReadBytes(trader2.rest, 1) IN IF ~subMember2.ok THEN Fail ELSE
    LET crossId2 == ReadBytes(subMember2.rest, 4) IN IF ~crossId2.ok THEN Fail ELSE
    LET orderSecurityCode2 == ReadBytes(crossId2.rest, 4) IN IF ~orderSecurityCode2.ok THEN Fail ELSE
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
         lastChangeFlagB1            |-> lastChangeFlagB1.value,
         bencrfptFlag                |-> bencrfptFlag.value,
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
         amendedTradeDate            |-> amendedTradeDate.value,
         brokerTrader                |-> brokerTrader.value,
         brokerText                  |-> brokerText.value,
         secondaryOrderId            |-> secondaryOrderId.value,
         entryDate                   |-> entryDate.value,
         priority                    |-> priority.value,
         price                       |-> price.value,
         displayQty                  |-> displayQty.value,
         altPrice                    |-> altPrice.value,
         orderId                     |-> orderId.value,
         secondaryExecId             |-> secondaryExecId.value,
         orderQty                    |-> orderQty.value,
         ordStatus                   |-> ordStatus.value,
         ccpCode                     |-> ccpCode.value,
         aggressorIndicator          |-> aggressorIndicator.value,
         requestId                   |-> requestId.value,
         clientDataId                |-> clientDataId.value,
         algorithmicTradeIndicator   |-> algorithmicTradeIndicator.value,
         clientId                    |-> clientId.value,
         accountBolsa                |-> accountBolsa.value,
         account                     |-> account.value,
         deaFlag                     |-> deaFlag.value,
         decisorId                   |-> decisorId.value,
         executorId                  |-> executorId.value,
         liquidityProvisionActivity  |-> liquidityProvisionActivity.value,
         accountMember               |-> accountMember.value,
         lastCapacity                |-> lastCapacity.value,
         receivedDeptId              |-> receivedDeptId.value,
         persistence                 |-> persistence.value,
         member                      |-> member.value,
         trader                      |-> trader.value,
         subMember                   |-> subMember.value,
         crossId                     |-> crossId.value,
         orderSecurityCode           |-> orderSecurityCode.value,
         secondaryOrderId2           |-> secondaryOrderId2.value,
         entryDate2                  |-> entryDate2.value,
         priority2                   |-> priority2.value,
         price2                      |-> price2.value,
         displayQty2                 |-> displayQty2.value,
         altPrice2                   |-> altPrice2.value,
         orderId2                    |-> orderId2.value,
         secondaryExecId2            |-> secondaryExecId2.value,
         orderQty2                   |-> orderQty2.value,
         ordStatus2                  |-> ordStatus2.value,
         ccpCode2                    |-> ccpCode2.value,
         aggressorIndicator2         |-> aggressorIndicator2.value,
         requestId2                  |-> requestId2.value,
         clientDataId2U2             |-> clientDataId2U2.value,
         algorithmicTradeIndicator2  |-> algorithmicTradeIndicator2.value,
         clientId2                   |-> clientId2.value,
         accountBolsa2               |-> accountBolsa2.value,
         account2                    |-> account2.value,
         deaFlag2                    |-> deaFlag2.value,
         decisorId2                  |-> decisorId2.value,
         executorId2                 |-> executorId2.value,
         liquidityProvisionActivity2 |-> liquidityProvisionActivity2.value,
         accountMember2              |-> accountMember2.value,
         lastCapacity2               |-> lastCapacity2.value,
         receivedDeptId2             |-> receivedDeptId2.value,
         persistence2                |-> persistence2.value,
         member2                     |-> member2.value,
         trader2                     |-> trader2.value,
         subMember2                  |-> subMember2.value,
         crossId2                    |-> crossId2.value,
         orderSecurityCode2          |-> orderSecurityCode2.value ], orderSecurityCode2.rest)

ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage ==
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
      lastChangeFlagB1            |-> [i \in 1 .. 1 |-> 0],
      bencrfptFlag                |-> [i \in 1 .. 1 |-> 0],
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
      amendedTradeDate            |-> [i \in 1 .. 4 |-> 0],
      brokerTrader                |-> [i \in 1 .. 3 |-> 0],
      brokerText                  |-> [i \in 1 .. 15 |-> 0],
      secondaryOrderId            |-> [i \in 1 .. 4 |-> 0],
      entryDate                   |-> [i \in 1 .. 4 |-> 0],
      priority                    |-> [i \in 1 .. 4 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      displayQty                  |-> [i \in 1 .. 4 |-> 0],
      altPrice                    |-> [i \in 1 .. 8 |-> 0],
      orderId                     |-> [i \in 1 .. 4 |-> 0],
      secondaryExecId             |-> [i \in 1 .. 4 |-> 0],
      orderQty                    |-> [i \in 1 .. 4 |-> 0],
      ordStatus                   |-> [i \in 1 .. 1 |-> 0],
      ccpCode                     |-> [i \in 1 .. 1 |-> 0],
      aggressorIndicator          |-> [i \in 1 .. 1 |-> 0],
      requestId                   |-> [i \in 1 .. 4 |-> 0],
      clientDataId                |-> [i \in 1 .. 2 |-> 0],
      algorithmicTradeIndicator   |-> [i \in 1 .. 1 |-> 0],
      clientId                    |-> [i \in 1 .. 4 |-> 0],
      accountBolsa                |-> [i \in 1 .. 16 |-> 0],
      account                     |-> [i \in 1 .. 5 |-> 0],
      deaFlag                     |-> [i \in 1 .. 1 |-> 0],
      decisorId                   |-> [i \in 1 .. 4 |-> 0],
      executorId                  |-> [i \in 1 .. 4 |-> 0],
      liquidityProvisionActivity  |-> [i \in 1 .. 1 |-> 0],
      accountMember               |-> [i \in 1 .. 4 |-> 0],
      lastCapacity                |-> [i \in 1 .. 1 |-> 0],
      receivedDeptId              |-> [i \in 1 .. 1 |-> 0],
      persistence                 |-> [i \in 1 .. 1 |-> 0],
      member                      |-> [i \in 1 .. 4 |-> 0],
      trader                      |-> [i \in 1 .. 3 |-> 0],
      subMember                   |-> [i \in 1 .. 1 |-> 0],
      crossId                     |-> [i \in 1 .. 4 |-> 0],
      orderSecurityCode           |-> [i \in 1 .. 4 |-> 0],
      secondaryOrderId2           |-> [i \in 1 .. 4 |-> 0],
      entryDate2                  |-> [i \in 1 .. 4 |-> 0],
      priority2                   |-> [i \in 1 .. 4 |-> 0],
      price2                      |-> [i \in 1 .. 8 |-> 0],
      displayQty2                 |-> [i \in 1 .. 4 |-> 0],
      altPrice2                   |-> [i \in 1 .. 8 |-> 0],
      orderId2                    |-> [i \in 1 .. 4 |-> 0],
      secondaryExecId2            |-> [i \in 1 .. 4 |-> 0],
      orderQty2                   |-> [i \in 1 .. 4 |-> 0],
      ordStatus2                  |-> [i \in 1 .. 1 |-> 0],
      ccpCode2                    |-> [i \in 1 .. 1 |-> 0],
      aggressorIndicator2         |-> [i \in 1 .. 1 |-> 0],
      requestId2                  |-> [i \in 1 .. 4 |-> 0],
      clientDataId2U2             |-> [i \in 1 .. 2 |-> 0],
      algorithmicTradeIndicator2  |-> [i \in 1 .. 1 |-> 0],
      clientId2                   |-> [i \in 1 .. 4 |-> 0],
      accountBolsa2               |-> [i \in 1 .. 16 |-> 0],
      account2                    |-> [i \in 1 .. 5 |-> 0],
      deaFlag2                    |-> [i \in 1 .. 1 |-> 0],
      decisorId2                  |-> [i \in 1 .. 4 |-> 0],
      executorId2                 |-> [i \in 1 .. 4 |-> 0],
      liquidityProvisionActivity2 |-> [i \in 1 .. 1 |-> 0],
      accountMember2              |-> [i \in 1 .. 4 |-> 0],
      lastCapacity2               |-> [i \in 1 .. 1 |-> 0],
      receivedDeptId2             |-> [i \in 1 .. 1 |-> 0],
      persistence2                |-> [i \in 1 .. 1 |-> 0],
      member2                     |-> [i \in 1 .. 4 |-> 0],
      trader2                     |-> [i \in 1 .. 3 |-> 0],
      subMember2                  |-> [i \in 1 .. 1 |-> 0],
      crossId2                    |-> [i \in 1 .. 4 |-> 0],
      orderSecurityCode2          |-> [i \in 1 .. 4 |-> 0] ]

(* Trade Trade Amendment Or Cancellation 2 Legs Private Information Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage ==
    { ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.grossTradeAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.designation = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.algoFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.altLastPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.accruedInterestAmt = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.accruedInterestRateP8 = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.lastChangeFlagB1 = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.bencrfptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.tradePriceCondition = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.preTradeTransparencyWaiver = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.deferralWaiver = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.postDeferralPublicationType = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.publishDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.tradeSessionDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.settlDate2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.endCash = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.amendedTradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.execRefId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.amendedTradeDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.brokerTrader = one] : one \in Sample(3) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.brokerText = one] : one \in Sample(15) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.entryDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.priority = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.altPrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.secondaryExecId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.ccpCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.aggressorIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.clientDataId = one] : one \in Sample(2) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.algorithmicTradeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.accountBolsa = one] : one \in Sample(16) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.account = one] : one \in Sample(5) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.deaFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.decisorId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.executorId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.liquidityProvisionActivity = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.accountMember = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.lastCapacity = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.receivedDeptId = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.persistence = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.member = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.trader = one] : one \in Sample(3) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.subMember = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.crossId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.orderSecurityCode = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.secondaryOrderId2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.entryDate2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.priority2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.price2 = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.displayQty2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.altPrice2 = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.orderId2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.secondaryExecId2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.orderQty2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.ordStatus2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.ccpCode2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.aggressorIndicator2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.requestId2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.clientDataId2U2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.algorithmicTradeIndicator2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.clientId2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.accountBolsa2 = one] : one \in Sample(16) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.account2 = one] : one \in Sample(5) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.deaFlag2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.decisorId2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.executorId2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.liquidityProvisionActivity2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.accountMember2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.lastCapacity2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.receivedDeptId2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.persistence2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.member2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.trader2 = one] : one \in Sample(3) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.subMember2 = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.crossId2 = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage EXCEPT !.orderSecurityCode2 = one] : one \in Sample(4) }

(***************************************************************************)
(* Execution Private Information 1 Leg Buy Market Order Message: 163 bytes *)
(***************************************************************************)

ExecutionPrivateInformation1LegBuyMarketOrderMessage ==
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
      orderId                : Sample(4),
      secondaryExecId        : Sample(4),
      orderQty               : Sample(4),
      ordStatus              : Sample(1),
      ccpCode                : Sample(1),
      aggressorIndicator     : Sample(1),
      requestId              : Sample(4),
      clientDataId           : Sample(2),
      secondaryOrderId2      : Sample(4),
      entryDate2             : Sample(4),
      priority2              : Sample(4),
      price2                 : Sample(8),
      displayQty2            : Sample(4),
      altPrice2              : Sample(8) ]

EncodeExecutionPrivateInformation1LegBuyMarketOrderMessage(message) ==
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
        \o message.orderId
        \o message.secondaryExecId
        \o message.orderQty
        \o message.ordStatus
        \o message.ccpCode
        \o message.aggressorIndicator
        \o message.requestId
        \o message.clientDataId
        \o message.secondaryOrderId2
        \o message.entryDate2
        \o message.priority2
        \o message.price2
        \o message.displayQty2
        \o message.altPrice2

DecodeExecutionPrivateInformation1LegBuyMarketOrderMessage(bytes) ==
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
    LET orderId == ReadBytes(altPrice.rest, 4) IN IF ~orderId.ok THEN Fail ELSE
    LET secondaryExecId == ReadBytes(orderId.rest, 4) IN IF ~secondaryExecId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(secondaryExecId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET ordStatus == ReadBytes(orderQty.rest, 1) IN IF ~ordStatus.ok THEN Fail ELSE
    LET ccpCode == ReadBytes(ordStatus.rest, 1) IN IF ~ccpCode.ok THEN Fail ELSE
    LET aggressorIndicator == ReadBytes(ccpCode.rest, 1) IN IF ~aggressorIndicator.ok THEN Fail ELSE
    LET requestId == ReadBytes(aggressorIndicator.rest, 4) IN IF ~requestId.ok THEN Fail ELSE
    LET clientDataId == ReadBytes(requestId.rest, 2) IN IF ~clientDataId.ok THEN Fail ELSE
    LET secondaryOrderId2 == ReadBytes(clientDataId.rest, 4) IN IF ~secondaryOrderId2.ok THEN Fail ELSE
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
         orderId                |-> orderId.value,
         secondaryExecId        |-> secondaryExecId.value,
         orderQty               |-> orderQty.value,
         ordStatus              |-> ordStatus.value,
         ccpCode                |-> ccpCode.value,
         aggressorIndicator     |-> aggressorIndicator.value,
         requestId              |-> requestId.value,
         clientDataId           |-> clientDataId.value,
         secondaryOrderId2      |-> secondaryOrderId2.value,
         entryDate2             |-> entryDate2.value,
         priority2              |-> priority2.value,
         price2                 |-> price2.value,
         displayQty2            |-> displayQty2.value,
         altPrice2              |-> altPrice2.value ], altPrice2.rest)

ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage ==
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
      orderId                |-> [i \in 1 .. 4 |-> 0],
      secondaryExecId        |-> [i \in 1 .. 4 |-> 0],
      orderQty               |-> [i \in 1 .. 4 |-> 0],
      ordStatus              |-> [i \in 1 .. 1 |-> 0],
      ccpCode                |-> [i \in 1 .. 1 |-> 0],
      aggressorIndicator     |-> [i \in 1 .. 1 |-> 0],
      requestId              |-> [i \in 1 .. 4 |-> 0],
      clientDataId           |-> [i \in 1 .. 2 |-> 0],
      secondaryOrderId2      |-> [i \in 1 .. 4 |-> 0],
      entryDate2             |-> [i \in 1 .. 4 |-> 0],
      priority2              |-> [i \in 1 .. 4 |-> 0],
      price2                 |-> [i \in 1 .. 8 |-> 0],
      displayQty2            |-> [i \in 1 .. 4 |-> 0],
      altPrice2              |-> [i \in 1 .. 8 |-> 0] ]

(* Execution Private Information 1 Leg Buy Market Order Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionPrivateInformation1LegBuyMarketOrderMessage ==
    { ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.grossTradeAmt = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.designation = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.algoFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.altLastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.accruedInterestAmt = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.accruedInterestRateP8 = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.entryDate = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.priority = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.altPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.orderId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.secondaryExecId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.ordStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.ccpCode = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.aggressorIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.requestId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.clientDataId = one] : one \in Sample(2) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.secondaryOrderId2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.entryDate2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.priority2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.price2 = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.displayQty2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage EXCEPT !.altPrice2 = one] : one \in Sample(8) }

(***************************************************************************)
(* Execution Private Information 1 Leg Sell Market Order Message: 163      *)
(* bytes                                                                   *)
(***************************************************************************)

ExecutionPrivateInformation1LegSellMarketOrderMessage ==
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
      altPrice2              : Sample(8),
      orderId2               : Sample(4),
      secondaryExecId2       : Sample(4),
      orderQty2              : Sample(4),
      ordStatus2             : Sample(1),
      ccpCode2               : Sample(1),
      aggressorIndicator2    : Sample(1),
      requestId2             : Sample(4),
      clientDataId2B2        : Sample(2) ]

EncodeExecutionPrivateInformation1LegSellMarketOrderMessage(message) ==
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
        \o message.orderId2
        \o message.secondaryExecId2
        \o message.orderQty2
        \o message.ordStatus2
        \o message.ccpCode2
        \o message.aggressorIndicator2
        \o message.requestId2
        \o message.clientDataId2B2

DecodeExecutionPrivateInformation1LegSellMarketOrderMessage(bytes) ==
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
    LET orderId2 == ReadBytes(altPrice2.rest, 4) IN IF ~orderId2.ok THEN Fail ELSE
    LET secondaryExecId2 == ReadBytes(orderId2.rest, 4) IN IF ~secondaryExecId2.ok THEN Fail ELSE
    LET orderQty2 == ReadBytes(secondaryExecId2.rest, 4) IN IF ~orderQty2.ok THEN Fail ELSE
    LET ordStatus2 == ReadBytes(orderQty2.rest, 1) IN IF ~ordStatus2.ok THEN Fail ELSE
    LET ccpCode2 == ReadBytes(ordStatus2.rest, 1) IN IF ~ccpCode2.ok THEN Fail ELSE
    LET aggressorIndicator2 == ReadBytes(ccpCode2.rest, 1) IN IF ~aggressorIndicator2.ok THEN Fail ELSE
    LET requestId2 == ReadBytes(aggressorIndicator2.rest, 4) IN IF ~requestId2.ok THEN Fail ELSE
    LET clientDataId2B2 == ReadBytes(requestId2.rest, 2) IN IF ~clientDataId2B2.ok THEN Fail ELSE
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
         altPrice2              |-> altPrice2.value,
         orderId2               |-> orderId2.value,
         secondaryExecId2       |-> secondaryExecId2.value,
         orderQty2              |-> orderQty2.value,
         ordStatus2             |-> ordStatus2.value,
         ccpCode2               |-> ccpCode2.value,
         aggressorIndicator2    |-> aggressorIndicator2.value,
         requestId2             |-> requestId2.value,
         clientDataId2B2        |-> clientDataId2B2.value ], clientDataId2B2.rest)

ZeroExecutionPrivateInformation1LegSellMarketOrderMessage ==
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
      altPrice2              |-> [i \in 1 .. 8 |-> 0],
      orderId2               |-> [i \in 1 .. 4 |-> 0],
      secondaryExecId2       |-> [i \in 1 .. 4 |-> 0],
      orderQty2              |-> [i \in 1 .. 4 |-> 0],
      ordStatus2             |-> [i \in 1 .. 1 |-> 0],
      ccpCode2               |-> [i \in 1 .. 1 |-> 0],
      aggressorIndicator2    |-> [i \in 1 .. 1 |-> 0],
      requestId2             |-> [i \in 1 .. 4 |-> 0],
      clientDataId2B2        |-> [i \in 1 .. 2 |-> 0] ]

(* Execution Private Information 1 Leg Sell Market Order Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionPrivateInformation1LegSellMarketOrderMessage ==
    { ZeroExecutionPrivateInformation1LegSellMarketOrderMessage }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.marketSegmentId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.tradingSessionId = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.trdMatchId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.grossTradeAmt = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.designation = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.marketMechanism = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.algoFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.altLastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.accruedInterestAmt = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.accruedInterestRateP8 = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.entryDate = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.priority = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.altPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.secondaryOrderId2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.entryDate2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.priority2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.price2 = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.displayQty2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.altPrice2 = one] : one \in Sample(8) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.orderId2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.secondaryExecId2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.orderQty2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.ordStatus2 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.ccpCode2 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.aggressorIndicator2 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.requestId2 = one] : one \in Sample(4) }
        \cup { [ZeroExecutionPrivateInformation1LegSellMarketOrderMessage EXCEPT !.clientDataId2B2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LogonResponseMessageCode == 8  \* 0x08
LogoutResponseMessageCode == 11  \* 0x0b
HeartbeatMessageCode == 48  \* 0x30
NetworkStatusMessageCode == 10  \* 0x0a
LogonMessageCode == 65  \* 0x41
RejectMessageCode == 13  \* 0x0d
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
TradeMarketPostTransparencyInformationTopofbookMessageCode == 16  \* 0x10
TradeTradeAmendmentOrCancellationMessageCode == 24  \* 0x18
TradeMarketPostTransparencyInformationFullDepthMessageCode == 17  \* 0x11
IndicationOfInterestMessageCode == 54  \* 0x36
RfqMarketPreTransparencyInformationMessageCode == 133  \* 0x85
TopofbookMessageCode == 130  \* 0x82
OrderAndQuoteClientDataMessageCode == 111  \* 0x6f
SimpleNewOrderMessageCode == 68  \* 0x44
SimpleNewOrderWithClientDataMessageCode == 69  \* 0x45
SimpleOrderModificationMessageCode == 71  \* 0x47
SimpleOrderModificationWithClientDataMessageCode == 72  \* 0x48
OrderCancellationRequestMessageCode == 70  \* 0x46
NewQuoteMessageCode == 83  \* 0x53
QuoteModificationRequestMessageCode == 97  \* 0x61
QuoteCancellationRequestMessageCode == 90  \* 0x5a
MassOrderquoteCancellationMessageCode == 113  \* 0x71
OrderAndQuoteClientDataParametersAckNackMessageCode == 135  \* 0x87
SimpleOrderStatusMessageCode == 2  \* 0x02
QuoteStatusMessageCode == 6  \* 0x06
OrderCancelRejectMessageCode == 57  \* 0x39
MassOrderquoteCancellationCompletionMessageCode == 114  \* 0x72
MassOrderquoteCancellationRejectMessageCode == 115  \* 0x73
BusinessMessageRejectMessageCode == 106  \* 0x6a
ExecutionPrivateInformation2LegsMessageCode == 23  \* 0x17
TradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessageCode == 26  \* 0x1a
TradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessageCode == 28  \* 0x1c
TradeTradeAmendmentOrCancellation2LegsPrivateInformationMessageCode == 30  \* 0x1e
ExecutionPrivateInformation1LegBuyMarketOrderMessageCode == 19  \* 0x13
ExecutionPrivateInformation1LegSellMarketOrderMessageCode == 21  \* 0x15

Payload ==
    [ tag : {LogonResponseMessageCode}, body : LogonResponseMessage ]
        \cup [ tag : {LogoutResponseMessageCode}, body : LogoutResponseMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : HeartbeatMessage ]
        \cup [ tag : {NetworkStatusMessageCode}, body : NetworkStatusMessage ]
        \cup [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {RejectMessageCode}, body : RejectMessage ]
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
        \cup [ tag : {TradeMarketPostTransparencyInformationTopofbookMessageCode}, body : TradeMarketPostTransparencyInformationTopofbookMessage ]
        \cup [ tag : {TradeTradeAmendmentOrCancellationMessageCode}, body : TradeTradeAmendmentOrCancellationMessage ]
        \cup [ tag : {TradeMarketPostTransparencyInformationFullDepthMessageCode}, body : TradeMarketPostTransparencyInformationFullDepthMessage ]
        \cup [ tag : {IndicationOfInterestMessageCode}, body : IndicationOfInterestMessage ]
        \cup [ tag : {RfqMarketPreTransparencyInformationMessageCode}, body : RfqMarketPreTransparencyInformationMessage ]
        \cup [ tag : {TopofbookMessageCode}, body : TopofbookMessage ]
        \cup [ tag : {OrderAndQuoteClientDataMessageCode}, body : OrderAndQuoteClientDataMessage ]
        \cup [ tag : {SimpleNewOrderMessageCode}, body : SimpleNewOrderMessage ]
        \cup [ tag : {SimpleNewOrderWithClientDataMessageCode}, body : SimpleNewOrderWithClientDataMessage ]
        \cup [ tag : {SimpleOrderModificationMessageCode}, body : SimpleOrderModificationMessage ]
        \cup [ tag : {SimpleOrderModificationWithClientDataMessageCode}, body : SimpleOrderModificationWithClientDataMessage ]
        \cup [ tag : {OrderCancellationRequestMessageCode}, body : OrderCancellationRequestMessage ]
        \cup [ tag : {NewQuoteMessageCode}, body : NewQuoteMessage ]
        \cup [ tag : {QuoteModificationRequestMessageCode}, body : QuoteModificationRequestMessage ]
        \cup [ tag : {QuoteCancellationRequestMessageCode}, body : QuoteCancellationRequestMessage ]
        \cup [ tag : {MassOrderquoteCancellationMessageCode}, body : MassOrderquoteCancellationMessage ]
        \cup [ tag : {OrderAndQuoteClientDataParametersAckNackMessageCode}, body : OrderAndQuoteClientDataParametersAckNackMessage ]
        \cup [ tag : {SimpleOrderStatusMessageCode}, body : SimpleOrderStatusMessage ]
        \cup [ tag : {QuoteStatusMessageCode}, body : QuoteStatusMessage ]
        \cup [ tag : {OrderCancelRejectMessageCode}, body : OrderCancelRejectMessage ]
        \cup [ tag : {MassOrderquoteCancellationCompletionMessageCode}, body : MassOrderquoteCancellationCompletionMessage ]
        \cup [ tag : {MassOrderquoteCancellationRejectMessageCode}, body : MassOrderquoteCancellationRejectMessage ]
        \cup [ tag : {BusinessMessageRejectMessageCode}, body : BusinessMessageRejectMessage ]
        \cup [ tag : {ExecutionPrivateInformation2LegsMessageCode}, body : ExecutionPrivateInformation2LegsMessage ]
        \cup [ tag : {TradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessageCode}, body : TradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage ]
        \cup [ tag : {TradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessageCode}, body : TradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage ]
        \cup [ tag : {TradeTradeAmendmentOrCancellation2LegsPrivateInformationMessageCode}, body : TradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage ]
        \cup [ tag : {ExecutionPrivateInformation1LegBuyMarketOrderMessageCode}, body : ExecutionPrivateInformation1LegBuyMarketOrderMessage ]
        \cup [ tag : {ExecutionPrivateInformation1LegSellMarketOrderMessageCode}, body : ExecutionPrivateInformation1LegSellMarketOrderMessage ]

EncodePayload(message) ==
    CASE message.tag = LogonResponseMessageCode -> EncodeLogonResponseMessage(message.body)
      [] message.tag = LogoutResponseMessageCode -> EncodeLogoutResponseMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> EncodeHeartbeatMessage(message.body)
      [] message.tag = NetworkStatusMessageCode -> EncodeNetworkStatusMessage(message.body)
      [] message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = RejectMessageCode -> EncodeRejectMessage(message.body)
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
      [] message.tag = TradeMarketPostTransparencyInformationTopofbookMessageCode -> EncodeTradeMarketPostTransparencyInformationTopofbookMessage(message.body)
      [] message.tag = TradeTradeAmendmentOrCancellationMessageCode -> EncodeTradeTradeAmendmentOrCancellationMessage(message.body)
      [] message.tag = TradeMarketPostTransparencyInformationFullDepthMessageCode -> EncodeTradeMarketPostTransparencyInformationFullDepthMessage(message.body)
      [] message.tag = IndicationOfInterestMessageCode -> EncodeIndicationOfInterestMessage(message.body)
      [] message.tag = RfqMarketPreTransparencyInformationMessageCode -> EncodeRfqMarketPreTransparencyInformationMessage(message.body)
      [] message.tag = TopofbookMessageCode -> EncodeTopofbookMessage(message.body)
      [] message.tag = OrderAndQuoteClientDataMessageCode -> EncodeOrderAndQuoteClientDataMessage(message.body)
      [] message.tag = SimpleNewOrderMessageCode -> EncodeSimpleNewOrderMessage(message.body)
      [] message.tag = SimpleNewOrderWithClientDataMessageCode -> EncodeSimpleNewOrderWithClientDataMessage(message.body)
      [] message.tag = SimpleOrderModificationMessageCode -> EncodeSimpleOrderModificationMessage(message.body)
      [] message.tag = SimpleOrderModificationWithClientDataMessageCode -> EncodeSimpleOrderModificationWithClientDataMessage(message.body)
      [] message.tag = OrderCancellationRequestMessageCode -> EncodeOrderCancellationRequestMessage(message.body)
      [] message.tag = NewQuoteMessageCode -> EncodeNewQuoteMessage(message.body)
      [] message.tag = QuoteModificationRequestMessageCode -> EncodeQuoteModificationRequestMessage(message.body)
      [] message.tag = QuoteCancellationRequestMessageCode -> EncodeQuoteCancellationRequestMessage(message.body)
      [] message.tag = MassOrderquoteCancellationMessageCode -> EncodeMassOrderquoteCancellationMessage(message.body)
      [] message.tag = OrderAndQuoteClientDataParametersAckNackMessageCode -> EncodeOrderAndQuoteClientDataParametersAckNackMessage(message.body)
      [] message.tag = SimpleOrderStatusMessageCode -> EncodeSimpleOrderStatusMessage(message.body)
      [] message.tag = QuoteStatusMessageCode -> EncodeQuoteStatusMessage(message.body)
      [] message.tag = OrderCancelRejectMessageCode -> EncodeOrderCancelRejectMessage(message.body)
      [] message.tag = MassOrderquoteCancellationCompletionMessageCode -> EncodeMassOrderquoteCancellationCompletionMessage(message.body)
      [] message.tag = MassOrderquoteCancellationRejectMessageCode -> EncodeMassOrderquoteCancellationRejectMessage(message.body)
      [] message.tag = BusinessMessageRejectMessageCode -> EncodeBusinessMessageRejectMessage(message.body)
      [] message.tag = ExecutionPrivateInformation2LegsMessageCode -> EncodeExecutionPrivateInformation2LegsMessage(message.body)
      [] message.tag = TradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessageCode -> EncodeTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage(message.body)
      [] message.tag = TradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessageCode -> EncodeTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage(message.body)
      [] message.tag = TradeTradeAmendmentOrCancellation2LegsPrivateInformationMessageCode -> EncodeTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage(message.body)
      [] message.tag = ExecutionPrivateInformation1LegBuyMarketOrderMessageCode -> EncodeExecutionPrivateInformation1LegBuyMarketOrderMessage(message.body)
      [] message.tag = ExecutionPrivateInformation1LegSellMarketOrderMessageCode -> EncodeExecutionPrivateInformation1LegSellMarketOrderMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonResponseMessageCode -> DecodeLogonResponseMessage(bytes)
              [] tag = LogoutResponseMessageCode -> DecodeLogoutResponseMessage(bytes)
              [] tag = HeartbeatMessageCode -> DecodeHeartbeatMessage(bytes)
              [] tag = NetworkStatusMessageCode -> DecodeNetworkStatusMessage(bytes)
              [] tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = RejectMessageCode -> DecodeRejectMessage(bytes)
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
              [] tag = TradeMarketPostTransparencyInformationTopofbookMessageCode -> DecodeTradeMarketPostTransparencyInformationTopofbookMessage(bytes)
              [] tag = TradeTradeAmendmentOrCancellationMessageCode -> DecodeTradeTradeAmendmentOrCancellationMessage(bytes)
              [] tag = TradeMarketPostTransparencyInformationFullDepthMessageCode -> DecodeTradeMarketPostTransparencyInformationFullDepthMessage(bytes)
              [] tag = IndicationOfInterestMessageCode -> DecodeIndicationOfInterestMessage(bytes)
              [] tag = RfqMarketPreTransparencyInformationMessageCode -> DecodeRfqMarketPreTransparencyInformationMessage(bytes)
              [] tag = TopofbookMessageCode -> DecodeTopofbookMessage(bytes)
              [] tag = OrderAndQuoteClientDataMessageCode -> DecodeOrderAndQuoteClientDataMessage(bytes)
              [] tag = SimpleNewOrderMessageCode -> DecodeSimpleNewOrderMessage(bytes)
              [] tag = SimpleNewOrderWithClientDataMessageCode -> DecodeSimpleNewOrderWithClientDataMessage(bytes)
              [] tag = SimpleOrderModificationMessageCode -> DecodeSimpleOrderModificationMessage(bytes)
              [] tag = SimpleOrderModificationWithClientDataMessageCode -> DecodeSimpleOrderModificationWithClientDataMessage(bytes)
              [] tag = OrderCancellationRequestMessageCode -> DecodeOrderCancellationRequestMessage(bytes)
              [] tag = NewQuoteMessageCode -> DecodeNewQuoteMessage(bytes)
              [] tag = QuoteModificationRequestMessageCode -> DecodeQuoteModificationRequestMessage(bytes)
              [] tag = QuoteCancellationRequestMessageCode -> DecodeQuoteCancellationRequestMessage(bytes)
              [] tag = MassOrderquoteCancellationMessageCode -> DecodeMassOrderquoteCancellationMessage(bytes)
              [] tag = OrderAndQuoteClientDataParametersAckNackMessageCode -> DecodeOrderAndQuoteClientDataParametersAckNackMessage(bytes)
              [] tag = SimpleOrderStatusMessageCode -> DecodeSimpleOrderStatusMessage(bytes)
              [] tag = QuoteStatusMessageCode -> DecodeQuoteStatusMessage(bytes)
              [] tag = OrderCancelRejectMessageCode -> DecodeOrderCancelRejectMessage(bytes)
              [] tag = MassOrderquoteCancellationCompletionMessageCode -> DecodeMassOrderquoteCancellationCompletionMessage(bytes)
              [] tag = MassOrderquoteCancellationRejectMessageCode -> DecodeMassOrderquoteCancellationRejectMessage(bytes)
              [] tag = BusinessMessageRejectMessageCode -> DecodeBusinessMessageRejectMessage(bytes)
              [] tag = ExecutionPrivateInformation2LegsMessageCode -> DecodeExecutionPrivateInformation2LegsMessage(bytes)
              [] tag = TradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessageCode -> DecodeTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage(bytes)
              [] tag = TradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessageCode -> DecodeTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage(bytes)
              [] tag = TradeTradeAmendmentOrCancellation2LegsPrivateInformationMessageCode -> DecodeTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage(bytes)
              [] tag = ExecutionPrivateInformation1LegBuyMarketOrderMessageCode -> DecodeExecutionPrivateInformation1LegBuyMarketOrderMessage(bytes)
              [] tag = ExecutionPrivateInformation1LegSellMarketOrderMessageCode -> DecodeExecutionPrivateInformation1LegSellMarketOrderMessage(bytes)
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
        \cup { [tag |-> RejectMessageCode, body |-> one] : one \in CheckedRejectMessage }
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
        \cup { [tag |-> TradeMarketPostTransparencyInformationTopofbookMessageCode, body |-> one] : one \in CheckedTradeMarketPostTransparencyInformationTopofbookMessage }
        \cup { [tag |-> TradeTradeAmendmentOrCancellationMessageCode, body |-> one] : one \in CheckedTradeTradeAmendmentOrCancellationMessage }
        \cup { [tag |-> TradeMarketPostTransparencyInformationFullDepthMessageCode, body |-> one] : one \in CheckedTradeMarketPostTransparencyInformationFullDepthMessage }
        \cup { [tag |-> IndicationOfInterestMessageCode, body |-> one] : one \in CheckedIndicationOfInterestMessage }
        \cup { [tag |-> RfqMarketPreTransparencyInformationMessageCode, body |-> one] : one \in CheckedRfqMarketPreTransparencyInformationMessage }
        \cup { [tag |-> TopofbookMessageCode, body |-> one] : one \in CheckedTopofbookMessage }
        \cup { [tag |-> OrderAndQuoteClientDataMessageCode, body |-> one] : one \in CheckedOrderAndQuoteClientDataMessage }
        \cup { [tag |-> SimpleNewOrderMessageCode, body |-> one] : one \in CheckedSimpleNewOrderMessage }
        \cup { [tag |-> SimpleNewOrderWithClientDataMessageCode, body |-> one] : one \in CheckedSimpleNewOrderWithClientDataMessage }
        \cup { [tag |-> SimpleOrderModificationMessageCode, body |-> one] : one \in CheckedSimpleOrderModificationMessage }
        \cup { [tag |-> SimpleOrderModificationWithClientDataMessageCode, body |-> one] : one \in CheckedSimpleOrderModificationWithClientDataMessage }
        \cup { [tag |-> OrderCancellationRequestMessageCode, body |-> one] : one \in CheckedOrderCancellationRequestMessage }
        \cup { [tag |-> NewQuoteMessageCode, body |-> one] : one \in CheckedNewQuoteMessage }
        \cup { [tag |-> QuoteModificationRequestMessageCode, body |-> one] : one \in CheckedQuoteModificationRequestMessage }
        \cup { [tag |-> QuoteCancellationRequestMessageCode, body |-> one] : one \in CheckedQuoteCancellationRequestMessage }
        \cup { [tag |-> MassOrderquoteCancellationMessageCode, body |-> one] : one \in CheckedMassOrderquoteCancellationMessage }
        \cup { [tag |-> OrderAndQuoteClientDataParametersAckNackMessageCode, body |-> one] : one \in CheckedOrderAndQuoteClientDataParametersAckNackMessage }
        \cup { [tag |-> SimpleOrderStatusMessageCode, body |-> one] : one \in CheckedSimpleOrderStatusMessage }
        \cup { [tag |-> QuoteStatusMessageCode, body |-> one] : one \in CheckedQuoteStatusMessage }
        \cup { [tag |-> OrderCancelRejectMessageCode, body |-> one] : one \in CheckedOrderCancelRejectMessage }
        \cup { [tag |-> MassOrderquoteCancellationCompletionMessageCode, body |-> one] : one \in CheckedMassOrderquoteCancellationCompletionMessage }
        \cup { [tag |-> MassOrderquoteCancellationRejectMessageCode, body |-> one] : one \in CheckedMassOrderquoteCancellationRejectMessage }
        \cup { [tag |-> BusinessMessageRejectMessageCode, body |-> one] : one \in CheckedBusinessMessageRejectMessage }
        \cup { [tag |-> ExecutionPrivateInformation2LegsMessageCode, body |-> one] : one \in CheckedExecutionPrivateInformation2LegsMessage }
        \cup { [tag |-> TradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessageCode, body |-> one] : one \in CheckedTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage }
        \cup { [tag |-> TradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessageCode, body |-> one] : one \in CheckedTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage }
        \cup { [tag |-> TradeTradeAmendmentOrCancellation2LegsPrivateInformationMessageCode, body |-> one] : one \in CheckedTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage }
        \cup { [tag |-> ExecutionPrivateInformation1LegBuyMarketOrderMessageCode, body |-> one] : one \in CheckedExecutionPrivateInformation1LegBuyMarketOrderMessage }
        \cup { [tag |-> ExecutionPrivateInformation1LegSellMarketOrderMessageCode, body |-> one] : one \in CheckedExecutionPrivateInformation1LegSellMarketOrderMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> RejectMessageCode, body |-> ZeroRejectMessage]],
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
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMarketPostTransparencyInformationTopofbookMessageCode, body |-> ZeroTradeMarketPostTransparencyInformationTopofbookMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeTradeAmendmentOrCancellationMessageCode, body |-> ZeroTradeTradeAmendmentOrCancellationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMarketPostTransparencyInformationFullDepthMessageCode, body |-> ZeroTradeMarketPostTransparencyInformationFullDepthMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> IndicationOfInterestMessageCode, body |-> ZeroIndicationOfInterestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RfqMarketPreTransparencyInformationMessageCode, body |-> ZeroRfqMarketPreTransparencyInformationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TopofbookMessageCode, body |-> ZeroTopofbookMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAndQuoteClientDataMessageCode, body |-> ZeroOrderAndQuoteClientDataMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SimpleNewOrderMessageCode, body |-> ZeroSimpleNewOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SimpleNewOrderWithClientDataMessageCode, body |-> ZeroSimpleNewOrderWithClientDataMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SimpleOrderModificationMessageCode, body |-> ZeroSimpleOrderModificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SimpleOrderModificationWithClientDataMessageCode, body |-> ZeroSimpleOrderModificationWithClientDataMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancellationRequestMessageCode, body |-> ZeroOrderCancellationRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewQuoteMessageCode, body |-> ZeroNewQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteModificationRequestMessageCode, body |-> ZeroQuoteModificationRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteCancellationRequestMessageCode, body |-> ZeroQuoteCancellationRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MassOrderquoteCancellationMessageCode, body |-> ZeroMassOrderquoteCancellationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAndQuoteClientDataParametersAckNackMessageCode, body |-> ZeroOrderAndQuoteClientDataParametersAckNackMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SimpleOrderStatusMessageCode, body |-> ZeroSimpleOrderStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteStatusMessageCode, body |-> ZeroQuoteStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelRejectMessageCode, body |-> ZeroOrderCancelRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MassOrderquoteCancellationCompletionMessageCode, body |-> ZeroMassOrderquoteCancellationCompletionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MassOrderquoteCancellationRejectMessageCode, body |-> ZeroMassOrderquoteCancellationRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BusinessMessageRejectMessageCode, body |-> ZeroBusinessMessageRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExecutionPrivateInformation2LegsMessageCode, body |-> ZeroExecutionPrivateInformation2LegsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessageCode, body |-> ZeroTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessageCode, body |-> ZeroTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeTradeAmendmentOrCancellation2LegsPrivateInformationMessageCode, body |-> ZeroTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExecutionPrivateInformation1LegBuyMarketOrderMessageCode, body |-> ZeroExecutionPrivateInformation1LegBuyMarketOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExecutionPrivateInformation1LegSellMarketOrderMessageCode, body |-> ZeroExecutionPrivateInformation1LegSellMarketOrderMessage]] }

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

(* Every Trade Market Post Transparency Information Topofbook Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMarketPostTransparencyInformationTopofbookMessage ==
    \A message \in CheckedTradeMarketPostTransparencyInformationTopofbookMessage :
        LET read == DecodeTradeMarketPostTransparencyInformationTopofbookMessage(EncodeTradeMarketPostTransparencyInformationTopofbookMessage(message))
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

(* Every Topofbook Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopofbookMessage ==
    \A message \in CheckedTopofbookMessage :
        LET read == DecodeTopofbookMessage(EncodeTopofbookMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order And Quote Client Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAndQuoteClientDataMessage ==
    \A message \in CheckedOrderAndQuoteClientDataMessage :
        LET read == DecodeOrderAndQuoteClientDataMessage(EncodeOrderAndQuoteClientDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleNewOrderMessage ==
    \A message \in CheckedSimpleNewOrderMessage :
        LET read == DecodeSimpleNewOrderMessage(EncodeSimpleNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple New Order With Client Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleNewOrderWithClientDataMessage ==
    \A message \in CheckedSimpleNewOrderWithClientDataMessage :
        LET read == DecodeSimpleNewOrderWithClientDataMessage(EncodeSimpleNewOrderWithClientDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Order Modification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleOrderModificationMessage ==
    \A message \in CheckedSimpleOrderModificationMessage :
        LET read == DecodeSimpleOrderModificationMessage(EncodeSimpleOrderModificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Order Modification With Client Data Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleOrderModificationWithClientDataMessage ==
    \A message \in CheckedSimpleOrderModificationWithClientDataMessage :
        LET read == DecodeSimpleOrderModificationWithClientDataMessage(EncodeSimpleOrderModificationWithClientDataMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancellation Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancellationRequestMessage ==
    \A message \in CheckedOrderCancellationRequestMessage :
        LET read == DecodeOrderCancellationRequestMessage(EncodeOrderCancellationRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewQuoteMessage ==
    \A message \in CheckedNewQuoteMessage :
        LET read == DecodeNewQuoteMessage(EncodeNewQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Modification Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteModificationRequestMessage ==
    \A message \in CheckedQuoteModificationRequestMessage :
        LET read == DecodeQuoteModificationRequestMessage(EncodeQuoteModificationRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancellation Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancellationRequestMessage ==
    \A message \in CheckedQuoteCancellationRequestMessage :
        LET read == DecodeQuoteCancellationRequestMessage(EncodeQuoteCancellationRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Orderquote Cancellation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassOrderquoteCancellationMessage ==
    \A message \in CheckedMassOrderquoteCancellationMessage :
        LET read == DecodeMassOrderquoteCancellationMessage(EncodeMassOrderquoteCancellationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order And Quote Client Data Parameters Ack Nack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAndQuoteClientDataParametersAckNackMessage ==
    \A message \in CheckedOrderAndQuoteClientDataParametersAckNackMessage :
        LET read == DecodeOrderAndQuoteClientDataParametersAckNackMessage(EncodeOrderAndQuoteClientDataParametersAckNackMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Simple Order Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSimpleOrderStatusMessage ==
    \A message \in CheckedSimpleOrderStatusMessage :
        LET read == DecodeSimpleOrderStatusMessage(EncodeSimpleOrderStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteStatusMessage ==
    \A message \in CheckedQuoteStatusMessage :
        LET read == DecodeQuoteStatusMessage(EncodeQuoteStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelRejectMessage ==
    \A message \in CheckedOrderCancelRejectMessage :
        LET read == DecodeOrderCancelRejectMessage(EncodeOrderCancelRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Orderquote Cancellation Completion Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassOrderquoteCancellationCompletionMessage ==
    \A message \in CheckedMassOrderquoteCancellationCompletionMessage :
        LET read == DecodeMassOrderquoteCancellationCompletionMessage(EncodeMassOrderquoteCancellationCompletionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Orderquote Cancellation Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassOrderquoteCancellationRejectMessage ==
    \A message \in CheckedMassOrderquoteCancellationRejectMessage :
        LET read == DecodeMassOrderquoteCancellationRejectMessage(EncodeMassOrderquoteCancellationRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Business Message Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBusinessMessageRejectMessage ==
    \A message \in CheckedBusinessMessageRejectMessage :
        LET read == DecodeBusinessMessageRejectMessage(EncodeBusinessMessageRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Private Information 2 Legs Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionPrivateInformation2LegsMessage ==
    \A message \in CheckedExecutionPrivateInformation2LegsMessage :
        LET read == DecodeExecutionPrivateInformation2LegsMessage(EncodeExecutionPrivateInformation2LegsMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Trade Amendment Or Cancellation 1 Leg Buy Private Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage ==
    \A message \in CheckedTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage :
        LET read == DecodeTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage(EncodeTradeTradeAmendmentOrCancellation1LegBuyPrivateInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Trade Amendment Or Cancellation 1 Leg Sell Private Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage ==
    \A message \in CheckedTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage :
        LET read == DecodeTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage(EncodeTradeTradeAmendmentOrCancellation1LegSellPrivateInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Trade Amendment Or Cancellation 2 Legs Private Information Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage ==
    \A message \in CheckedTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage :
        LET read == DecodeTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage(EncodeTradeTradeAmendmentOrCancellation2LegsPrivateInformationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Private Information 1 Leg Buy Market Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionPrivateInformation1LegBuyMarketOrderMessage ==
    \A message \in CheckedExecutionPrivateInformation1LegBuyMarketOrderMessage :
        LET read == DecodeExecutionPrivateInformation1LegBuyMarketOrderMessage(EncodeExecutionPrivateInformation1LegBuyMarketOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Private Information 1 Leg Sell Market Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionPrivateInformation1LegSellMarketOrderMessage ==
    \A message \in CheckedExecutionPrivateInformation1LegSellMarketOrderMessage :
        LET read == DecodeExecutionPrivateInformation1LegSellMarketOrderMessage(EncodeExecutionPrivateInformation1LegSellMarketOrderMessage(message))
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
