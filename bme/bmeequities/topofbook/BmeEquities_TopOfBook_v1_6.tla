-------------------- MODULE BmeEquities_TopOfBook_v1_6 ---------------------
(***************************************************************************)
(* Bolsas y Mercados Españoles BME Equities Top Of Book v1.6               *)
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
(* Security List Message: 976 bytes                                        *)
(***************************************************************************)

SecurityListMessage ==
    [ sequenceNumber                          : Sample(4),
      marketId                                : Sample(4),
      marketSegmentId                         : Sample(4),
      securityCode                            : Sample(4),
      symbol                                  : Sample(22),
      symbolIsin                              : Sample(12),
      fisn                                    : Sample(35),
      issuerLei                               : Sample(20),
      securityGroup                           : Sample(2),
      cfiCode                                 : Sample(6),
      securityType                            : Sample(2),
      maturityDate                            : Sample(4),
      issueDate                               : Sample(4),
      contractMultiplier                      : Sample(8),
      liSpre                                  : Sample(8),
      sstIpre                                 : Sample(8),
      liSpost                                 : Sample(8),
      sstIpost                                : Sample(8),
      liquidInstrument                        : Sample(1),
      admissionRequestedByIssuer              : Sample(1),
      minTradeVol                             : Sample(4),
      roundLot                                : Sample(4),
      currency                                : Sample(3),
      modalityMaskB4                          : Sample(4),
      securityDescription                     : Sample(80),
      tradingObligation                       : Sample(1),
      securityName                            : Sample(40),
      netAssetValueIdentifier                 : Sample(7),
      securitySubType                         : Sample(2),
      maturityMonthYear                       : Sample(8),
      securityStatus                          : Sample(1),
      strikePrice                             : Sample(8),
      strikeValue                             : Sample(8),
      exerciseStyle                           : Sample(1),
      putOrCall                               : Sample(1),
      positionLimit                           : Sample(8),
      ntPositionLimit                         : Sample(8),
      issuer                                  : Sample(12),
      cpRegType                               : Sample(1),
      barrier                                 : Sample(8),
      lastTradingDay                          : Sample(4),
      automaticExpiration                     : Sample(1),
      feeType                                 : Sample(2),
      barrier2                                : Sample(8),
      triggerBarrier                          : Sample(8),
      triggerUpperBarrier                     : Sample(8),
      averageQuarterlyTurnover                : Sample(8),
      tradingScope                            : Sample(1),
      sicavCounterpartyMember                 : Sample(4),
      netAssetValueIndicator                  : Sample(1),
      referenceTradingVenue                   : Sample(1),
      outstandingCapital                      : Sample(8),
      firstTradingDate                        : Sample(4),
      settlementSystem                        : Sample(1),
      numberOfDecimals                        : Sample(1),
      numberOfHolders                         : Sample(4),
      outstandingShares                       : Sample(4),
      minimumAuthorizedShares                 : Sample(4),
      minimumCapital                          : Sample(8),
      lastAdmissionDate                       : Sample(4),
      barrierReturn                           : Sample(8),
      investmentFundManager                   : Sample(80),
      effectiveAmountFiltersRoutedOrders      : Sample(8),
      orderNumberOfDecimals                   : Sample(1),
      investmentFundClass                     : Sample(1),
      masterFundName                          : Sample(80),
      investmentFundManagementCompany         : Sample(80),
      investmentFundDepository                : Sample(80),
      investmentFundCategory                  : Sample(80),
      investmentFundMinimumSubscriptionAmount : Sample(8),
      investmentFundMinimumMaintenanceAmount  : Sample(8),
      investmentFundCutOffTime                : Sample(8),
      navCommunicationTerm                    : Sample(1),
      investmentFundNumberOfDecimals          : Sample(1),
      commodityDerivativeIndicator            : Sample(1),
      doubleVolumeCapReached                  : Sample(1),
      adt                                     : Sample(8),
      baseProduct                             : Sample(4),
      subProduct                              : Sample(4),
      furtherSubProduct                       : Sample(4),
      adnt                                    : Sample(8),
      priceTickRule                           : Sample(1),
      underlyingSymbol                        : Sample(22),
      underlyingIsin                          : Sample(12),
      underlyingCurrency                      : Sample(3),
      minimumDisplayQty                       : Sample(4),
      retailServiceFlag                       : Sample(1),
      selfMatchPrevention                     : Sample(1) ]

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
        \o message.netAssetValueIdentifier
        \o message.securitySubType
        \o message.maturityMonthYear
        \o message.securityStatus
        \o message.strikePrice
        \o message.strikeValue
        \o message.exerciseStyle
        \o message.putOrCall
        \o message.positionLimit
        \o message.ntPositionLimit
        \o message.issuer
        \o message.cpRegType
        \o message.barrier
        \o message.lastTradingDay
        \o message.automaticExpiration
        \o message.feeType
        \o message.barrier2
        \o message.triggerBarrier
        \o message.triggerUpperBarrier
        \o message.averageQuarterlyTurnover
        \o message.tradingScope
        \o message.sicavCounterpartyMember
        \o message.netAssetValueIndicator
        \o message.referenceTradingVenue
        \o message.outstandingCapital
        \o message.firstTradingDate
        \o message.settlementSystem
        \o message.numberOfDecimals
        \o message.numberOfHolders
        \o message.outstandingShares
        \o message.minimumAuthorizedShares
        \o message.minimumCapital
        \o message.lastAdmissionDate
        \o message.barrierReturn
        \o message.investmentFundManager
        \o message.effectiveAmountFiltersRoutedOrders
        \o message.orderNumberOfDecimals
        \o message.investmentFundClass
        \o message.masterFundName
        \o message.investmentFundManagementCompany
        \o message.investmentFundDepository
        \o message.investmentFundCategory
        \o message.investmentFundMinimumSubscriptionAmount
        \o message.investmentFundMinimumMaintenanceAmount
        \o message.investmentFundCutOffTime
        \o message.navCommunicationTerm
        \o message.investmentFundNumberOfDecimals
        \o message.commodityDerivativeIndicator
        \o message.doubleVolumeCapReached
        \o message.adt
        \o message.baseProduct
        \o message.subProduct
        \o message.furtherSubProduct
        \o message.adnt
        \o message.priceTickRule
        \o message.underlyingSymbol
        \o message.underlyingIsin
        \o message.underlyingCurrency
        \o message.minimumDisplayQty
        \o message.retailServiceFlag
        \o message.selfMatchPrevention

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
    LET netAssetValueIdentifier == ReadBytes(securityName.rest, 7) IN IF ~netAssetValueIdentifier.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(netAssetValueIdentifier.rest, 2) IN IF ~securitySubType.ok THEN Fail ELSE
    LET maturityMonthYear == ReadBytes(securitySubType.rest, 8) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(maturityMonthYear.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(securityStatus.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikeValue == ReadBytes(strikePrice.rest, 8) IN IF ~strikeValue.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(strikeValue.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(exerciseStyle.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET positionLimit == ReadBytes(putOrCall.rest, 8) IN IF ~positionLimit.ok THEN Fail ELSE
    LET ntPositionLimit == ReadBytes(positionLimit.rest, 8) IN IF ~ntPositionLimit.ok THEN Fail ELSE
    LET issuer == ReadBytes(ntPositionLimit.rest, 12) IN IF ~issuer.ok THEN Fail ELSE
    LET cpRegType == ReadBytes(issuer.rest, 1) IN IF ~cpRegType.ok THEN Fail ELSE
    LET barrier == ReadBytes(cpRegType.rest, 8) IN IF ~barrier.ok THEN Fail ELSE
    LET lastTradingDay == ReadBytes(barrier.rest, 4) IN IF ~lastTradingDay.ok THEN Fail ELSE
    LET automaticExpiration == ReadBytes(lastTradingDay.rest, 1) IN IF ~automaticExpiration.ok THEN Fail ELSE
    LET feeType == ReadBytes(automaticExpiration.rest, 2) IN IF ~feeType.ok THEN Fail ELSE
    LET barrier2 == ReadBytes(feeType.rest, 8) IN IF ~barrier2.ok THEN Fail ELSE
    LET triggerBarrier == ReadBytes(barrier2.rest, 8) IN IF ~triggerBarrier.ok THEN Fail ELSE
    LET triggerUpperBarrier == ReadBytes(triggerBarrier.rest, 8) IN IF ~triggerUpperBarrier.ok THEN Fail ELSE
    LET averageQuarterlyTurnover == ReadBytes(triggerUpperBarrier.rest, 8) IN IF ~averageQuarterlyTurnover.ok THEN Fail ELSE
    LET tradingScope == ReadBytes(averageQuarterlyTurnover.rest, 1) IN IF ~tradingScope.ok THEN Fail ELSE
    LET sicavCounterpartyMember == ReadBytes(tradingScope.rest, 4) IN IF ~sicavCounterpartyMember.ok THEN Fail ELSE
    LET netAssetValueIndicator == ReadBytes(sicavCounterpartyMember.rest, 1) IN IF ~netAssetValueIndicator.ok THEN Fail ELSE
    LET referenceTradingVenue == ReadBytes(netAssetValueIndicator.rest, 1) IN IF ~referenceTradingVenue.ok THEN Fail ELSE
    LET outstandingCapital == ReadBytes(referenceTradingVenue.rest, 8) IN IF ~outstandingCapital.ok THEN Fail ELSE
    LET firstTradingDate == ReadBytes(outstandingCapital.rest, 4) IN IF ~firstTradingDate.ok THEN Fail ELSE
    LET settlementSystem == ReadBytes(firstTradingDate.rest, 1) IN IF ~settlementSystem.ok THEN Fail ELSE
    LET numberOfDecimals == ReadBytes(settlementSystem.rest, 1) IN IF ~numberOfDecimals.ok THEN Fail ELSE
    LET numberOfHolders == ReadBytes(numberOfDecimals.rest, 4) IN IF ~numberOfHolders.ok THEN Fail ELSE
    LET outstandingShares == ReadBytes(numberOfHolders.rest, 4) IN IF ~outstandingShares.ok THEN Fail ELSE
    LET minimumAuthorizedShares == ReadBytes(outstandingShares.rest, 4) IN IF ~minimumAuthorizedShares.ok THEN Fail ELSE
    LET minimumCapital == ReadBytes(minimumAuthorizedShares.rest, 8) IN IF ~minimumCapital.ok THEN Fail ELSE
    LET lastAdmissionDate == ReadBytes(minimumCapital.rest, 4) IN IF ~lastAdmissionDate.ok THEN Fail ELSE
    LET barrierReturn == ReadBytes(lastAdmissionDate.rest, 8) IN IF ~barrierReturn.ok THEN Fail ELSE
    LET investmentFundManager == ReadBytes(barrierReturn.rest, 80) IN IF ~investmentFundManager.ok THEN Fail ELSE
    LET effectiveAmountFiltersRoutedOrders == ReadBytes(investmentFundManager.rest, 8) IN IF ~effectiveAmountFiltersRoutedOrders.ok THEN Fail ELSE
    LET orderNumberOfDecimals == ReadBytes(effectiveAmountFiltersRoutedOrders.rest, 1) IN IF ~orderNumberOfDecimals.ok THEN Fail ELSE
    LET investmentFundClass == ReadBytes(orderNumberOfDecimals.rest, 1) IN IF ~investmentFundClass.ok THEN Fail ELSE
    LET masterFundName == ReadBytes(investmentFundClass.rest, 80) IN IF ~masterFundName.ok THEN Fail ELSE
    LET investmentFundManagementCompany == ReadBytes(masterFundName.rest, 80) IN IF ~investmentFundManagementCompany.ok THEN Fail ELSE
    LET investmentFundDepository == ReadBytes(investmentFundManagementCompany.rest, 80) IN IF ~investmentFundDepository.ok THEN Fail ELSE
    LET investmentFundCategory == ReadBytes(investmentFundDepository.rest, 80) IN IF ~investmentFundCategory.ok THEN Fail ELSE
    LET investmentFundMinimumSubscriptionAmount == ReadBytes(investmentFundCategory.rest, 8) IN IF ~investmentFundMinimumSubscriptionAmount.ok THEN Fail ELSE
    LET investmentFundMinimumMaintenanceAmount == ReadBytes(investmentFundMinimumSubscriptionAmount.rest, 8) IN IF ~investmentFundMinimumMaintenanceAmount.ok THEN Fail ELSE
    LET investmentFundCutOffTime == ReadBytes(investmentFundMinimumMaintenanceAmount.rest, 8) IN IF ~investmentFundCutOffTime.ok THEN Fail ELSE
    LET navCommunicationTerm == ReadBytes(investmentFundCutOffTime.rest, 1) IN IF ~navCommunicationTerm.ok THEN Fail ELSE
    LET investmentFundNumberOfDecimals == ReadBytes(navCommunicationTerm.rest, 1) IN IF ~investmentFundNumberOfDecimals.ok THEN Fail ELSE
    LET commodityDerivativeIndicator == ReadBytes(investmentFundNumberOfDecimals.rest, 1) IN IF ~commodityDerivativeIndicator.ok THEN Fail ELSE
    LET doubleVolumeCapReached == ReadBytes(commodityDerivativeIndicator.rest, 1) IN IF ~doubleVolumeCapReached.ok THEN Fail ELSE
    LET adt == ReadBytes(doubleVolumeCapReached.rest, 8) IN IF ~adt.ok THEN Fail ELSE
    LET baseProduct == ReadBytes(adt.rest, 4) IN IF ~baseProduct.ok THEN Fail ELSE
    LET subProduct == ReadBytes(baseProduct.rest, 4) IN IF ~subProduct.ok THEN Fail ELSE
    LET furtherSubProduct == ReadBytes(subProduct.rest, 4) IN IF ~furtherSubProduct.ok THEN Fail ELSE
    LET adnt == ReadBytes(furtherSubProduct.rest, 8) IN IF ~adnt.ok THEN Fail ELSE
    LET priceTickRule == ReadBytes(adnt.rest, 1) IN IF ~priceTickRule.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(priceTickRule.rest, 22) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET underlyingIsin == ReadBytes(underlyingSymbol.rest, 12) IN IF ~underlyingIsin.ok THEN Fail ELSE
    LET underlyingCurrency == ReadBytes(underlyingIsin.rest, 3) IN IF ~underlyingCurrency.ok THEN Fail ELSE
    LET minimumDisplayQty == ReadBytes(underlyingCurrency.rest, 4) IN IF ~minimumDisplayQty.ok THEN Fail ELSE
    LET retailServiceFlag == ReadBytes(minimumDisplayQty.rest, 1) IN IF ~retailServiceFlag.ok THEN Fail ELSE
    LET selfMatchPrevention == ReadBytes(retailServiceFlag.rest, 1) IN IF ~selfMatchPrevention.ok THEN Fail ELSE
    Ok([ sequenceNumber                          |-> sequenceNumber.value,
         marketId                                |-> marketId.value,
         marketSegmentId                         |-> marketSegmentId.value,
         securityCode                            |-> securityCode.value,
         symbol                                  |-> symbol.value,
         symbolIsin                              |-> symbolIsin.value,
         fisn                                    |-> fisn.value,
         issuerLei                               |-> issuerLei.value,
         securityGroup                           |-> securityGroup.value,
         cfiCode                                 |-> cfiCode.value,
         securityType                            |-> securityType.value,
         maturityDate                            |-> maturityDate.value,
         issueDate                               |-> issueDate.value,
         contractMultiplier                      |-> contractMultiplier.value,
         liSpre                                  |-> liSpre.value,
         sstIpre                                 |-> sstIpre.value,
         liSpost                                 |-> liSpost.value,
         sstIpost                                |-> sstIpost.value,
         liquidInstrument                        |-> liquidInstrument.value,
         admissionRequestedByIssuer              |-> admissionRequestedByIssuer.value,
         minTradeVol                             |-> minTradeVol.value,
         roundLot                                |-> roundLot.value,
         currency                                |-> currency.value,
         modalityMaskB4                          |-> modalityMaskB4.value,
         securityDescription                     |-> securityDescription.value,
         tradingObligation                       |-> tradingObligation.value,
         securityName                            |-> securityName.value,
         netAssetValueIdentifier                 |-> netAssetValueIdentifier.value,
         securitySubType                         |-> securitySubType.value,
         maturityMonthYear                       |-> maturityMonthYear.value,
         securityStatus                          |-> securityStatus.value,
         strikePrice                             |-> strikePrice.value,
         strikeValue                             |-> strikeValue.value,
         exerciseStyle                           |-> exerciseStyle.value,
         putOrCall                               |-> putOrCall.value,
         positionLimit                           |-> positionLimit.value,
         ntPositionLimit                         |-> ntPositionLimit.value,
         issuer                                  |-> issuer.value,
         cpRegType                               |-> cpRegType.value,
         barrier                                 |-> barrier.value,
         lastTradingDay                          |-> lastTradingDay.value,
         automaticExpiration                     |-> automaticExpiration.value,
         feeType                                 |-> feeType.value,
         barrier2                                |-> barrier2.value,
         triggerBarrier                          |-> triggerBarrier.value,
         triggerUpperBarrier                     |-> triggerUpperBarrier.value,
         averageQuarterlyTurnover                |-> averageQuarterlyTurnover.value,
         tradingScope                            |-> tradingScope.value,
         sicavCounterpartyMember                 |-> sicavCounterpartyMember.value,
         netAssetValueIndicator                  |-> netAssetValueIndicator.value,
         referenceTradingVenue                   |-> referenceTradingVenue.value,
         outstandingCapital                      |-> outstandingCapital.value,
         firstTradingDate                        |-> firstTradingDate.value,
         settlementSystem                        |-> settlementSystem.value,
         numberOfDecimals                        |-> numberOfDecimals.value,
         numberOfHolders                         |-> numberOfHolders.value,
         outstandingShares                       |-> outstandingShares.value,
         minimumAuthorizedShares                 |-> minimumAuthorizedShares.value,
         minimumCapital                          |-> minimumCapital.value,
         lastAdmissionDate                       |-> lastAdmissionDate.value,
         barrierReturn                           |-> barrierReturn.value,
         investmentFundManager                   |-> investmentFundManager.value,
         effectiveAmountFiltersRoutedOrders      |-> effectiveAmountFiltersRoutedOrders.value,
         orderNumberOfDecimals                   |-> orderNumberOfDecimals.value,
         investmentFundClass                     |-> investmentFundClass.value,
         masterFundName                          |-> masterFundName.value,
         investmentFundManagementCompany         |-> investmentFundManagementCompany.value,
         investmentFundDepository                |-> investmentFundDepository.value,
         investmentFundCategory                  |-> investmentFundCategory.value,
         investmentFundMinimumSubscriptionAmount |-> investmentFundMinimumSubscriptionAmount.value,
         investmentFundMinimumMaintenanceAmount  |-> investmentFundMinimumMaintenanceAmount.value,
         investmentFundCutOffTime                |-> investmentFundCutOffTime.value,
         navCommunicationTerm                    |-> navCommunicationTerm.value,
         investmentFundNumberOfDecimals          |-> investmentFundNumberOfDecimals.value,
         commodityDerivativeIndicator            |-> commodityDerivativeIndicator.value,
         doubleVolumeCapReached                  |-> doubleVolumeCapReached.value,
         adt                                     |-> adt.value,
         baseProduct                             |-> baseProduct.value,
         subProduct                              |-> subProduct.value,
         furtherSubProduct                       |-> furtherSubProduct.value,
         adnt                                    |-> adnt.value,
         priceTickRule                           |-> priceTickRule.value,
         underlyingSymbol                        |-> underlyingSymbol.value,
         underlyingIsin                          |-> underlyingIsin.value,
         underlyingCurrency                      |-> underlyingCurrency.value,
         minimumDisplayQty                       |-> minimumDisplayQty.value,
         retailServiceFlag                       |-> retailServiceFlag.value,
         selfMatchPrevention                     |-> selfMatchPrevention.value ], selfMatchPrevention.rest)

ZeroSecurityListMessage ==
    [ sequenceNumber                          |-> [i \in 1 .. 4 |-> 0],
      marketId                                |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      securityCode                            |-> [i \in 1 .. 4 |-> 0],
      symbol                                  |-> [i \in 1 .. 22 |-> 0],
      symbolIsin                              |-> [i \in 1 .. 12 |-> 0],
      fisn                                    |-> [i \in 1 .. 35 |-> 0],
      issuerLei                               |-> [i \in 1 .. 20 |-> 0],
      securityGroup                           |-> [i \in 1 .. 2 |-> 0],
      cfiCode                                 |-> [i \in 1 .. 6 |-> 0],
      securityType                            |-> [i \in 1 .. 2 |-> 0],
      maturityDate                            |-> [i \in 1 .. 4 |-> 0],
      issueDate                               |-> [i \in 1 .. 4 |-> 0],
      contractMultiplier                      |-> [i \in 1 .. 8 |-> 0],
      liSpre                                  |-> [i \in 1 .. 8 |-> 0],
      sstIpre                                 |-> [i \in 1 .. 8 |-> 0],
      liSpost                                 |-> [i \in 1 .. 8 |-> 0],
      sstIpost                                |-> [i \in 1 .. 8 |-> 0],
      liquidInstrument                        |-> [i \in 1 .. 1 |-> 0],
      admissionRequestedByIssuer              |-> [i \in 1 .. 1 |-> 0],
      minTradeVol                             |-> [i \in 1 .. 4 |-> 0],
      roundLot                                |-> [i \in 1 .. 4 |-> 0],
      currency                                |-> [i \in 1 .. 3 |-> 0],
      modalityMaskB4                          |-> [i \in 1 .. 4 |-> 0],
      securityDescription                     |-> [i \in 1 .. 80 |-> 0],
      tradingObligation                       |-> [i \in 1 .. 1 |-> 0],
      securityName                            |-> [i \in 1 .. 40 |-> 0],
      netAssetValueIdentifier                 |-> [i \in 1 .. 7 |-> 0],
      securitySubType                         |-> [i \in 1 .. 2 |-> 0],
      maturityMonthYear                       |-> [i \in 1 .. 8 |-> 0],
      securityStatus                          |-> [i \in 1 .. 1 |-> 0],
      strikePrice                             |-> [i \in 1 .. 8 |-> 0],
      strikeValue                             |-> [i \in 1 .. 8 |-> 0],
      exerciseStyle                           |-> [i \in 1 .. 1 |-> 0],
      putOrCall                               |-> [i \in 1 .. 1 |-> 0],
      positionLimit                           |-> [i \in 1 .. 8 |-> 0],
      ntPositionLimit                         |-> [i \in 1 .. 8 |-> 0],
      issuer                                  |-> [i \in 1 .. 12 |-> 0],
      cpRegType                               |-> [i \in 1 .. 1 |-> 0],
      barrier                                 |-> [i \in 1 .. 8 |-> 0],
      lastTradingDay                          |-> [i \in 1 .. 4 |-> 0],
      automaticExpiration                     |-> [i \in 1 .. 1 |-> 0],
      feeType                                 |-> [i \in 1 .. 2 |-> 0],
      barrier2                                |-> [i \in 1 .. 8 |-> 0],
      triggerBarrier                          |-> [i \in 1 .. 8 |-> 0],
      triggerUpperBarrier                     |-> [i \in 1 .. 8 |-> 0],
      averageQuarterlyTurnover                |-> [i \in 1 .. 8 |-> 0],
      tradingScope                            |-> [i \in 1 .. 1 |-> 0],
      sicavCounterpartyMember                 |-> [i \in 1 .. 4 |-> 0],
      netAssetValueIndicator                  |-> [i \in 1 .. 1 |-> 0],
      referenceTradingVenue                   |-> [i \in 1 .. 1 |-> 0],
      outstandingCapital                      |-> [i \in 1 .. 8 |-> 0],
      firstTradingDate                        |-> [i \in 1 .. 4 |-> 0],
      settlementSystem                        |-> [i \in 1 .. 1 |-> 0],
      numberOfDecimals                        |-> [i \in 1 .. 1 |-> 0],
      numberOfHolders                         |-> [i \in 1 .. 4 |-> 0],
      outstandingShares                       |-> [i \in 1 .. 4 |-> 0],
      minimumAuthorizedShares                 |-> [i \in 1 .. 4 |-> 0],
      minimumCapital                          |-> [i \in 1 .. 8 |-> 0],
      lastAdmissionDate                       |-> [i \in 1 .. 4 |-> 0],
      barrierReturn                           |-> [i \in 1 .. 8 |-> 0],
      investmentFundManager                   |-> [i \in 1 .. 80 |-> 0],
      effectiveAmountFiltersRoutedOrders      |-> [i \in 1 .. 8 |-> 0],
      orderNumberOfDecimals                   |-> [i \in 1 .. 1 |-> 0],
      investmentFundClass                     |-> [i \in 1 .. 1 |-> 0],
      masterFundName                          |-> [i \in 1 .. 80 |-> 0],
      investmentFundManagementCompany         |-> [i \in 1 .. 80 |-> 0],
      investmentFundDepository                |-> [i \in 1 .. 80 |-> 0],
      investmentFundCategory                  |-> [i \in 1 .. 80 |-> 0],
      investmentFundMinimumSubscriptionAmount |-> [i \in 1 .. 8 |-> 0],
      investmentFundMinimumMaintenanceAmount  |-> [i \in 1 .. 8 |-> 0],
      investmentFundCutOffTime                |-> [i \in 1 .. 8 |-> 0],
      navCommunicationTerm                    |-> [i \in 1 .. 1 |-> 0],
      investmentFundNumberOfDecimals          |-> [i \in 1 .. 1 |-> 0],
      commodityDerivativeIndicator            |-> [i \in 1 .. 1 |-> 0],
      doubleVolumeCapReached                  |-> [i \in 1 .. 1 |-> 0],
      adt                                     |-> [i \in 1 .. 8 |-> 0],
      baseProduct                             |-> [i \in 1 .. 4 |-> 0],
      subProduct                              |-> [i \in 1 .. 4 |-> 0],
      furtherSubProduct                       |-> [i \in 1 .. 4 |-> 0],
      adnt                                    |-> [i \in 1 .. 8 |-> 0],
      priceTickRule                           |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol                        |-> [i \in 1 .. 22 |-> 0],
      underlyingIsin                          |-> [i \in 1 .. 12 |-> 0],
      underlyingCurrency                      |-> [i \in 1 .. 3 |-> 0],
      minimumDisplayQty                       |-> [i \in 1 .. 4 |-> 0],
      retailServiceFlag                       |-> [i \in 1 .. 1 |-> 0],
      selfMatchPrevention                     |-> [i \in 1 .. 1 |-> 0] ]

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
        \cup { [ZeroSecurityListMessage EXCEPT !.netAssetValueIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroSecurityListMessage EXCEPT !.securitySubType = one] : one \in Sample(2) }
        \cup { [ZeroSecurityListMessage EXCEPT !.maturityMonthYear = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.strikeValue = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.positionLimit = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.ntPositionLimit = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.issuer = one] : one \in Sample(12) }
        \cup { [ZeroSecurityListMessage EXCEPT !.cpRegType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.barrier = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.lastTradingDay = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.automaticExpiration = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.feeType = one] : one \in Sample(2) }
        \cup { [ZeroSecurityListMessage EXCEPT !.barrier2 = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.triggerBarrier = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.triggerUpperBarrier = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.averageQuarterlyTurnover = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.tradingScope = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.sicavCounterpartyMember = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.netAssetValueIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.referenceTradingVenue = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.outstandingCapital = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.firstTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.settlementSystem = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.numberOfDecimals = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.numberOfHolders = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.outstandingShares = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.minimumAuthorizedShares = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.minimumCapital = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.lastAdmissionDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.barrierReturn = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.investmentFundManager = one] : one \in Sample(80) }
        \cup { [ZeroSecurityListMessage EXCEPT !.effectiveAmountFiltersRoutedOrders = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.orderNumberOfDecimals = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.investmentFundClass = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.masterFundName = one] : one \in Sample(80) }
        \cup { [ZeroSecurityListMessage EXCEPT !.investmentFundManagementCompany = one] : one \in Sample(80) }
        \cup { [ZeroSecurityListMessage EXCEPT !.investmentFundDepository = one] : one \in Sample(80) }
        \cup { [ZeroSecurityListMessage EXCEPT !.investmentFundCategory = one] : one \in Sample(80) }
        \cup { [ZeroSecurityListMessage EXCEPT !.investmentFundMinimumSubscriptionAmount = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.investmentFundMinimumMaintenanceAmount = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.investmentFundCutOffTime = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.navCommunicationTerm = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.investmentFundNumberOfDecimals = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.commodityDerivativeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.doubleVolumeCapReached = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.adt = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.baseProduct = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.subProduct = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.furtherSubProduct = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.adnt = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListMessage EXCEPT !.priceTickRule = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(22) }
        \cup { [ZeroSecurityListMessage EXCEPT !.underlyingIsin = one] : one \in Sample(12) }
        \cup { [ZeroSecurityListMessage EXCEPT !.underlyingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityListMessage EXCEPT !.minimumDisplayQty = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListMessage EXCEPT !.retailServiceFlag = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListMessage EXCEPT !.selfMatchPrevention = one] : one \in Sample(1) }

(***************************************************************************)
(* Security List Update Report Message: 976 bytes                          *)
(***************************************************************************)

SecurityListUpdateReportMessage ==
    [ sequenceNumber                          : Sample(4),
      marketId                                : Sample(4),
      marketSegmentId                         : Sample(4),
      securityCode                            : Sample(4),
      symbol                                  : Sample(22),
      symbolIsin                              : Sample(12),
      fisn                                    : Sample(35),
      issuerLei                               : Sample(20),
      securityGroup                           : Sample(2),
      cfiCode                                 : Sample(6),
      securityType                            : Sample(2),
      maturityDate                            : Sample(4),
      issueDate                               : Sample(4),
      contractMultiplier                      : Sample(8),
      liSpre                                  : Sample(8),
      sstIpre                                 : Sample(8),
      liSpost                                 : Sample(8),
      sstIpost                                : Sample(8),
      liquidInstrument                        : Sample(1),
      admissionRequestedByIssuer              : Sample(1),
      minTradeVol                             : Sample(4),
      roundLot                                : Sample(4),
      currency                                : Sample(3),
      modalityMaskB4                          : Sample(4),
      securityDescription                     : Sample(80),
      tradingObligation                       : Sample(1),
      securityName                            : Sample(40),
      netAssetValueIdentifier                 : Sample(7),
      securitySubType                         : Sample(2),
      maturityMonthYear                       : Sample(8),
      securityStatus                          : Sample(1),
      strikePrice                             : Sample(8),
      strikeValue                             : Sample(8),
      exerciseStyle                           : Sample(1),
      putOrCall                               : Sample(1),
      positionLimit                           : Sample(8),
      ntPositionLimit                         : Sample(8),
      issuer                                  : Sample(12),
      cpRegType                               : Sample(1),
      barrier                                 : Sample(8),
      lastTradingDay                          : Sample(4),
      automaticExpiration                     : Sample(1),
      feeType                                 : Sample(2),
      barrier2                                : Sample(8),
      triggerBarrier                          : Sample(8),
      triggerUpperBarrier                     : Sample(8),
      averageQuarterlyTurnover                : Sample(8),
      tradingScope                            : Sample(1),
      sicavCounterpartyMember                 : Sample(4),
      netAssetValueIndicator                  : Sample(1),
      referenceTradingVenue                   : Sample(1),
      outstandingCapital                      : Sample(8),
      firstTradingDate                        : Sample(4),
      settlementSystem                        : Sample(1),
      numberOfDecimals                        : Sample(1),
      numberOfHolders                         : Sample(4),
      outstandingShares                       : Sample(4),
      minimumAuthorizedShares                 : Sample(4),
      minimumCapital                          : Sample(8),
      lastAdmissionDate                       : Sample(4),
      barrierReturn                           : Sample(8),
      investmentFundManager                   : Sample(80),
      effectiveAmountFiltersRoutedOrders      : Sample(8),
      orderNumberOfDecimals                   : Sample(1),
      investmentFundClass                     : Sample(1),
      masterFundName                          : Sample(80),
      investmentFundManagementCompany         : Sample(80),
      investmentFundDepository                : Sample(80),
      investmentFundCategory                  : Sample(80),
      investmentFundMinimumSubscriptionAmount : Sample(8),
      investmentFundMinimumMaintenanceAmount  : Sample(8),
      investmentFundCutOffTime                : Sample(8),
      navCommunicationTerm                    : Sample(1),
      investmentFundNumberOfDecimals          : Sample(1),
      commodityDerivativeIndicator            : Sample(1),
      doubleVolumeCapReached                  : Sample(1),
      adt                                     : Sample(8),
      baseProduct                             : Sample(4),
      subProduct                              : Sample(4),
      furtherSubProduct                       : Sample(4),
      adnt                                    : Sample(8),
      priceTickRule                           : Sample(1),
      underlyingSymbol                        : Sample(22),
      underlyingIsin                          : Sample(12),
      underlyingCurrency                      : Sample(3),
      minimumDisplayQty                       : Sample(4),
      retailServiceFlag                       : Sample(1),
      selfMatchPrevention                     : Sample(1) ]

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
        \o message.netAssetValueIdentifier
        \o message.securitySubType
        \o message.maturityMonthYear
        \o message.securityStatus
        \o message.strikePrice
        \o message.strikeValue
        \o message.exerciseStyle
        \o message.putOrCall
        \o message.positionLimit
        \o message.ntPositionLimit
        \o message.issuer
        \o message.cpRegType
        \o message.barrier
        \o message.lastTradingDay
        \o message.automaticExpiration
        \o message.feeType
        \o message.barrier2
        \o message.triggerBarrier
        \o message.triggerUpperBarrier
        \o message.averageQuarterlyTurnover
        \o message.tradingScope
        \o message.sicavCounterpartyMember
        \o message.netAssetValueIndicator
        \o message.referenceTradingVenue
        \o message.outstandingCapital
        \o message.firstTradingDate
        \o message.settlementSystem
        \o message.numberOfDecimals
        \o message.numberOfHolders
        \o message.outstandingShares
        \o message.minimumAuthorizedShares
        \o message.minimumCapital
        \o message.lastAdmissionDate
        \o message.barrierReturn
        \o message.investmentFundManager
        \o message.effectiveAmountFiltersRoutedOrders
        \o message.orderNumberOfDecimals
        \o message.investmentFundClass
        \o message.masterFundName
        \o message.investmentFundManagementCompany
        \o message.investmentFundDepository
        \o message.investmentFundCategory
        \o message.investmentFundMinimumSubscriptionAmount
        \o message.investmentFundMinimumMaintenanceAmount
        \o message.investmentFundCutOffTime
        \o message.navCommunicationTerm
        \o message.investmentFundNumberOfDecimals
        \o message.commodityDerivativeIndicator
        \o message.doubleVolumeCapReached
        \o message.adt
        \o message.baseProduct
        \o message.subProduct
        \o message.furtherSubProduct
        \o message.adnt
        \o message.priceTickRule
        \o message.underlyingSymbol
        \o message.underlyingIsin
        \o message.underlyingCurrency
        \o message.minimumDisplayQty
        \o message.retailServiceFlag
        \o message.selfMatchPrevention

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
    LET netAssetValueIdentifier == ReadBytes(securityName.rest, 7) IN IF ~netAssetValueIdentifier.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(netAssetValueIdentifier.rest, 2) IN IF ~securitySubType.ok THEN Fail ELSE
    LET maturityMonthYear == ReadBytes(securitySubType.rest, 8) IN IF ~maturityMonthYear.ok THEN Fail ELSE
    LET securityStatus == ReadBytes(maturityMonthYear.rest, 1) IN IF ~securityStatus.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(securityStatus.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikeValue == ReadBytes(strikePrice.rest, 8) IN IF ~strikeValue.ok THEN Fail ELSE
    LET exerciseStyle == ReadBytes(strikeValue.rest, 1) IN IF ~exerciseStyle.ok THEN Fail ELSE
    LET putOrCall == ReadBytes(exerciseStyle.rest, 1) IN IF ~putOrCall.ok THEN Fail ELSE
    LET positionLimit == ReadBytes(putOrCall.rest, 8) IN IF ~positionLimit.ok THEN Fail ELSE
    LET ntPositionLimit == ReadBytes(positionLimit.rest, 8) IN IF ~ntPositionLimit.ok THEN Fail ELSE
    LET issuer == ReadBytes(ntPositionLimit.rest, 12) IN IF ~issuer.ok THEN Fail ELSE
    LET cpRegType == ReadBytes(issuer.rest, 1) IN IF ~cpRegType.ok THEN Fail ELSE
    LET barrier == ReadBytes(cpRegType.rest, 8) IN IF ~barrier.ok THEN Fail ELSE
    LET lastTradingDay == ReadBytes(barrier.rest, 4) IN IF ~lastTradingDay.ok THEN Fail ELSE
    LET automaticExpiration == ReadBytes(lastTradingDay.rest, 1) IN IF ~automaticExpiration.ok THEN Fail ELSE
    LET feeType == ReadBytes(automaticExpiration.rest, 2) IN IF ~feeType.ok THEN Fail ELSE
    LET barrier2 == ReadBytes(feeType.rest, 8) IN IF ~barrier2.ok THEN Fail ELSE
    LET triggerBarrier == ReadBytes(barrier2.rest, 8) IN IF ~triggerBarrier.ok THEN Fail ELSE
    LET triggerUpperBarrier == ReadBytes(triggerBarrier.rest, 8) IN IF ~triggerUpperBarrier.ok THEN Fail ELSE
    LET averageQuarterlyTurnover == ReadBytes(triggerUpperBarrier.rest, 8) IN IF ~averageQuarterlyTurnover.ok THEN Fail ELSE
    LET tradingScope == ReadBytes(averageQuarterlyTurnover.rest, 1) IN IF ~tradingScope.ok THEN Fail ELSE
    LET sicavCounterpartyMember == ReadBytes(tradingScope.rest, 4) IN IF ~sicavCounterpartyMember.ok THEN Fail ELSE
    LET netAssetValueIndicator == ReadBytes(sicavCounterpartyMember.rest, 1) IN IF ~netAssetValueIndicator.ok THEN Fail ELSE
    LET referenceTradingVenue == ReadBytes(netAssetValueIndicator.rest, 1) IN IF ~referenceTradingVenue.ok THEN Fail ELSE
    LET outstandingCapital == ReadBytes(referenceTradingVenue.rest, 8) IN IF ~outstandingCapital.ok THEN Fail ELSE
    LET firstTradingDate == ReadBytes(outstandingCapital.rest, 4) IN IF ~firstTradingDate.ok THEN Fail ELSE
    LET settlementSystem == ReadBytes(firstTradingDate.rest, 1) IN IF ~settlementSystem.ok THEN Fail ELSE
    LET numberOfDecimals == ReadBytes(settlementSystem.rest, 1) IN IF ~numberOfDecimals.ok THEN Fail ELSE
    LET numberOfHolders == ReadBytes(numberOfDecimals.rest, 4) IN IF ~numberOfHolders.ok THEN Fail ELSE
    LET outstandingShares == ReadBytes(numberOfHolders.rest, 4) IN IF ~outstandingShares.ok THEN Fail ELSE
    LET minimumAuthorizedShares == ReadBytes(outstandingShares.rest, 4) IN IF ~minimumAuthorizedShares.ok THEN Fail ELSE
    LET minimumCapital == ReadBytes(minimumAuthorizedShares.rest, 8) IN IF ~minimumCapital.ok THEN Fail ELSE
    LET lastAdmissionDate == ReadBytes(minimumCapital.rest, 4) IN IF ~lastAdmissionDate.ok THEN Fail ELSE
    LET barrierReturn == ReadBytes(lastAdmissionDate.rest, 8) IN IF ~barrierReturn.ok THEN Fail ELSE
    LET investmentFundManager == ReadBytes(barrierReturn.rest, 80) IN IF ~investmentFundManager.ok THEN Fail ELSE
    LET effectiveAmountFiltersRoutedOrders == ReadBytes(investmentFundManager.rest, 8) IN IF ~effectiveAmountFiltersRoutedOrders.ok THEN Fail ELSE
    LET orderNumberOfDecimals == ReadBytes(effectiveAmountFiltersRoutedOrders.rest, 1) IN IF ~orderNumberOfDecimals.ok THEN Fail ELSE
    LET investmentFundClass == ReadBytes(orderNumberOfDecimals.rest, 1) IN IF ~investmentFundClass.ok THEN Fail ELSE
    LET masterFundName == ReadBytes(investmentFundClass.rest, 80) IN IF ~masterFundName.ok THEN Fail ELSE
    LET investmentFundManagementCompany == ReadBytes(masterFundName.rest, 80) IN IF ~investmentFundManagementCompany.ok THEN Fail ELSE
    LET investmentFundDepository == ReadBytes(investmentFundManagementCompany.rest, 80) IN IF ~investmentFundDepository.ok THEN Fail ELSE
    LET investmentFundCategory == ReadBytes(investmentFundDepository.rest, 80) IN IF ~investmentFundCategory.ok THEN Fail ELSE
    LET investmentFundMinimumSubscriptionAmount == ReadBytes(investmentFundCategory.rest, 8) IN IF ~investmentFundMinimumSubscriptionAmount.ok THEN Fail ELSE
    LET investmentFundMinimumMaintenanceAmount == ReadBytes(investmentFundMinimumSubscriptionAmount.rest, 8) IN IF ~investmentFundMinimumMaintenanceAmount.ok THEN Fail ELSE
    LET investmentFundCutOffTime == ReadBytes(investmentFundMinimumMaintenanceAmount.rest, 8) IN IF ~investmentFundCutOffTime.ok THEN Fail ELSE
    LET navCommunicationTerm == ReadBytes(investmentFundCutOffTime.rest, 1) IN IF ~navCommunicationTerm.ok THEN Fail ELSE
    LET investmentFundNumberOfDecimals == ReadBytes(navCommunicationTerm.rest, 1) IN IF ~investmentFundNumberOfDecimals.ok THEN Fail ELSE
    LET commodityDerivativeIndicator == ReadBytes(investmentFundNumberOfDecimals.rest, 1) IN IF ~commodityDerivativeIndicator.ok THEN Fail ELSE
    LET doubleVolumeCapReached == ReadBytes(commodityDerivativeIndicator.rest, 1) IN IF ~doubleVolumeCapReached.ok THEN Fail ELSE
    LET adt == ReadBytes(doubleVolumeCapReached.rest, 8) IN IF ~adt.ok THEN Fail ELSE
    LET baseProduct == ReadBytes(adt.rest, 4) IN IF ~baseProduct.ok THEN Fail ELSE
    LET subProduct == ReadBytes(baseProduct.rest, 4) IN IF ~subProduct.ok THEN Fail ELSE
    LET furtherSubProduct == ReadBytes(subProduct.rest, 4) IN IF ~furtherSubProduct.ok THEN Fail ELSE
    LET adnt == ReadBytes(furtherSubProduct.rest, 8) IN IF ~adnt.ok THEN Fail ELSE
    LET priceTickRule == ReadBytes(adnt.rest, 1) IN IF ~priceTickRule.ok THEN Fail ELSE
    LET underlyingSymbol == ReadBytes(priceTickRule.rest, 22) IN IF ~underlyingSymbol.ok THEN Fail ELSE
    LET underlyingIsin == ReadBytes(underlyingSymbol.rest, 12) IN IF ~underlyingIsin.ok THEN Fail ELSE
    LET underlyingCurrency == ReadBytes(underlyingIsin.rest, 3) IN IF ~underlyingCurrency.ok THEN Fail ELSE
    LET minimumDisplayQty == ReadBytes(underlyingCurrency.rest, 4) IN IF ~minimumDisplayQty.ok THEN Fail ELSE
    LET retailServiceFlag == ReadBytes(minimumDisplayQty.rest, 1) IN IF ~retailServiceFlag.ok THEN Fail ELSE
    LET selfMatchPrevention == ReadBytes(retailServiceFlag.rest, 1) IN IF ~selfMatchPrevention.ok THEN Fail ELSE
    Ok([ sequenceNumber                          |-> sequenceNumber.value,
         marketId                                |-> marketId.value,
         marketSegmentId                         |-> marketSegmentId.value,
         securityCode                            |-> securityCode.value,
         symbol                                  |-> symbol.value,
         symbolIsin                              |-> symbolIsin.value,
         fisn                                    |-> fisn.value,
         issuerLei                               |-> issuerLei.value,
         securityGroup                           |-> securityGroup.value,
         cfiCode                                 |-> cfiCode.value,
         securityType                            |-> securityType.value,
         maturityDate                            |-> maturityDate.value,
         issueDate                               |-> issueDate.value,
         contractMultiplier                      |-> contractMultiplier.value,
         liSpre                                  |-> liSpre.value,
         sstIpre                                 |-> sstIpre.value,
         liSpost                                 |-> liSpost.value,
         sstIpost                                |-> sstIpost.value,
         liquidInstrument                        |-> liquidInstrument.value,
         admissionRequestedByIssuer              |-> admissionRequestedByIssuer.value,
         minTradeVol                             |-> minTradeVol.value,
         roundLot                                |-> roundLot.value,
         currency                                |-> currency.value,
         modalityMaskB4                          |-> modalityMaskB4.value,
         securityDescription                     |-> securityDescription.value,
         tradingObligation                       |-> tradingObligation.value,
         securityName                            |-> securityName.value,
         netAssetValueIdentifier                 |-> netAssetValueIdentifier.value,
         securitySubType                         |-> securitySubType.value,
         maturityMonthYear                       |-> maturityMonthYear.value,
         securityStatus                          |-> securityStatus.value,
         strikePrice                             |-> strikePrice.value,
         strikeValue                             |-> strikeValue.value,
         exerciseStyle                           |-> exerciseStyle.value,
         putOrCall                               |-> putOrCall.value,
         positionLimit                           |-> positionLimit.value,
         ntPositionLimit                         |-> ntPositionLimit.value,
         issuer                                  |-> issuer.value,
         cpRegType                               |-> cpRegType.value,
         barrier                                 |-> barrier.value,
         lastTradingDay                          |-> lastTradingDay.value,
         automaticExpiration                     |-> automaticExpiration.value,
         feeType                                 |-> feeType.value,
         barrier2                                |-> barrier2.value,
         triggerBarrier                          |-> triggerBarrier.value,
         triggerUpperBarrier                     |-> triggerUpperBarrier.value,
         averageQuarterlyTurnover                |-> averageQuarterlyTurnover.value,
         tradingScope                            |-> tradingScope.value,
         sicavCounterpartyMember                 |-> sicavCounterpartyMember.value,
         netAssetValueIndicator                  |-> netAssetValueIndicator.value,
         referenceTradingVenue                   |-> referenceTradingVenue.value,
         outstandingCapital                      |-> outstandingCapital.value,
         firstTradingDate                        |-> firstTradingDate.value,
         settlementSystem                        |-> settlementSystem.value,
         numberOfDecimals                        |-> numberOfDecimals.value,
         numberOfHolders                         |-> numberOfHolders.value,
         outstandingShares                       |-> outstandingShares.value,
         minimumAuthorizedShares                 |-> minimumAuthorizedShares.value,
         minimumCapital                          |-> minimumCapital.value,
         lastAdmissionDate                       |-> lastAdmissionDate.value,
         barrierReturn                           |-> barrierReturn.value,
         investmentFundManager                   |-> investmentFundManager.value,
         effectiveAmountFiltersRoutedOrders      |-> effectiveAmountFiltersRoutedOrders.value,
         orderNumberOfDecimals                   |-> orderNumberOfDecimals.value,
         investmentFundClass                     |-> investmentFundClass.value,
         masterFundName                          |-> masterFundName.value,
         investmentFundManagementCompany         |-> investmentFundManagementCompany.value,
         investmentFundDepository                |-> investmentFundDepository.value,
         investmentFundCategory                  |-> investmentFundCategory.value,
         investmentFundMinimumSubscriptionAmount |-> investmentFundMinimumSubscriptionAmount.value,
         investmentFundMinimumMaintenanceAmount  |-> investmentFundMinimumMaintenanceAmount.value,
         investmentFundCutOffTime                |-> investmentFundCutOffTime.value,
         navCommunicationTerm                    |-> navCommunicationTerm.value,
         investmentFundNumberOfDecimals          |-> investmentFundNumberOfDecimals.value,
         commodityDerivativeIndicator            |-> commodityDerivativeIndicator.value,
         doubleVolumeCapReached                  |-> doubleVolumeCapReached.value,
         adt                                     |-> adt.value,
         baseProduct                             |-> baseProduct.value,
         subProduct                              |-> subProduct.value,
         furtherSubProduct                       |-> furtherSubProduct.value,
         adnt                                    |-> adnt.value,
         priceTickRule                           |-> priceTickRule.value,
         underlyingSymbol                        |-> underlyingSymbol.value,
         underlyingIsin                          |-> underlyingIsin.value,
         underlyingCurrency                      |-> underlyingCurrency.value,
         minimumDisplayQty                       |-> minimumDisplayQty.value,
         retailServiceFlag                       |-> retailServiceFlag.value,
         selfMatchPrevention                     |-> selfMatchPrevention.value ], selfMatchPrevention.rest)

ZeroSecurityListUpdateReportMessage ==
    [ sequenceNumber                          |-> [i \in 1 .. 4 |-> 0],
      marketId                                |-> [i \in 1 .. 4 |-> 0],
      marketSegmentId                         |-> [i \in 1 .. 4 |-> 0],
      securityCode                            |-> [i \in 1 .. 4 |-> 0],
      symbol                                  |-> [i \in 1 .. 22 |-> 0],
      symbolIsin                              |-> [i \in 1 .. 12 |-> 0],
      fisn                                    |-> [i \in 1 .. 35 |-> 0],
      issuerLei                               |-> [i \in 1 .. 20 |-> 0],
      securityGroup                           |-> [i \in 1 .. 2 |-> 0],
      cfiCode                                 |-> [i \in 1 .. 6 |-> 0],
      securityType                            |-> [i \in 1 .. 2 |-> 0],
      maturityDate                            |-> [i \in 1 .. 4 |-> 0],
      issueDate                               |-> [i \in 1 .. 4 |-> 0],
      contractMultiplier                      |-> [i \in 1 .. 8 |-> 0],
      liSpre                                  |-> [i \in 1 .. 8 |-> 0],
      sstIpre                                 |-> [i \in 1 .. 8 |-> 0],
      liSpost                                 |-> [i \in 1 .. 8 |-> 0],
      sstIpost                                |-> [i \in 1 .. 8 |-> 0],
      liquidInstrument                        |-> [i \in 1 .. 1 |-> 0],
      admissionRequestedByIssuer              |-> [i \in 1 .. 1 |-> 0],
      minTradeVol                             |-> [i \in 1 .. 4 |-> 0],
      roundLot                                |-> [i \in 1 .. 4 |-> 0],
      currency                                |-> [i \in 1 .. 3 |-> 0],
      modalityMaskB4                          |-> [i \in 1 .. 4 |-> 0],
      securityDescription                     |-> [i \in 1 .. 80 |-> 0],
      tradingObligation                       |-> [i \in 1 .. 1 |-> 0],
      securityName                            |-> [i \in 1 .. 40 |-> 0],
      netAssetValueIdentifier                 |-> [i \in 1 .. 7 |-> 0],
      securitySubType                         |-> [i \in 1 .. 2 |-> 0],
      maturityMonthYear                       |-> [i \in 1 .. 8 |-> 0],
      securityStatus                          |-> [i \in 1 .. 1 |-> 0],
      strikePrice                             |-> [i \in 1 .. 8 |-> 0],
      strikeValue                             |-> [i \in 1 .. 8 |-> 0],
      exerciseStyle                           |-> [i \in 1 .. 1 |-> 0],
      putOrCall                               |-> [i \in 1 .. 1 |-> 0],
      positionLimit                           |-> [i \in 1 .. 8 |-> 0],
      ntPositionLimit                         |-> [i \in 1 .. 8 |-> 0],
      issuer                                  |-> [i \in 1 .. 12 |-> 0],
      cpRegType                               |-> [i \in 1 .. 1 |-> 0],
      barrier                                 |-> [i \in 1 .. 8 |-> 0],
      lastTradingDay                          |-> [i \in 1 .. 4 |-> 0],
      automaticExpiration                     |-> [i \in 1 .. 1 |-> 0],
      feeType                                 |-> [i \in 1 .. 2 |-> 0],
      barrier2                                |-> [i \in 1 .. 8 |-> 0],
      triggerBarrier                          |-> [i \in 1 .. 8 |-> 0],
      triggerUpperBarrier                     |-> [i \in 1 .. 8 |-> 0],
      averageQuarterlyTurnover                |-> [i \in 1 .. 8 |-> 0],
      tradingScope                            |-> [i \in 1 .. 1 |-> 0],
      sicavCounterpartyMember                 |-> [i \in 1 .. 4 |-> 0],
      netAssetValueIndicator                  |-> [i \in 1 .. 1 |-> 0],
      referenceTradingVenue                   |-> [i \in 1 .. 1 |-> 0],
      outstandingCapital                      |-> [i \in 1 .. 8 |-> 0],
      firstTradingDate                        |-> [i \in 1 .. 4 |-> 0],
      settlementSystem                        |-> [i \in 1 .. 1 |-> 0],
      numberOfDecimals                        |-> [i \in 1 .. 1 |-> 0],
      numberOfHolders                         |-> [i \in 1 .. 4 |-> 0],
      outstandingShares                       |-> [i \in 1 .. 4 |-> 0],
      minimumAuthorizedShares                 |-> [i \in 1 .. 4 |-> 0],
      minimumCapital                          |-> [i \in 1 .. 8 |-> 0],
      lastAdmissionDate                       |-> [i \in 1 .. 4 |-> 0],
      barrierReturn                           |-> [i \in 1 .. 8 |-> 0],
      investmentFundManager                   |-> [i \in 1 .. 80 |-> 0],
      effectiveAmountFiltersRoutedOrders      |-> [i \in 1 .. 8 |-> 0],
      orderNumberOfDecimals                   |-> [i \in 1 .. 1 |-> 0],
      investmentFundClass                     |-> [i \in 1 .. 1 |-> 0],
      masterFundName                          |-> [i \in 1 .. 80 |-> 0],
      investmentFundManagementCompany         |-> [i \in 1 .. 80 |-> 0],
      investmentFundDepository                |-> [i \in 1 .. 80 |-> 0],
      investmentFundCategory                  |-> [i \in 1 .. 80 |-> 0],
      investmentFundMinimumSubscriptionAmount |-> [i \in 1 .. 8 |-> 0],
      investmentFundMinimumMaintenanceAmount  |-> [i \in 1 .. 8 |-> 0],
      investmentFundCutOffTime                |-> [i \in 1 .. 8 |-> 0],
      navCommunicationTerm                    |-> [i \in 1 .. 1 |-> 0],
      investmentFundNumberOfDecimals          |-> [i \in 1 .. 1 |-> 0],
      commodityDerivativeIndicator            |-> [i \in 1 .. 1 |-> 0],
      doubleVolumeCapReached                  |-> [i \in 1 .. 1 |-> 0],
      adt                                     |-> [i \in 1 .. 8 |-> 0],
      baseProduct                             |-> [i \in 1 .. 4 |-> 0],
      subProduct                              |-> [i \in 1 .. 4 |-> 0],
      furtherSubProduct                       |-> [i \in 1 .. 4 |-> 0],
      adnt                                    |-> [i \in 1 .. 8 |-> 0],
      priceTickRule                           |-> [i \in 1 .. 1 |-> 0],
      underlyingSymbol                        |-> [i \in 1 .. 22 |-> 0],
      underlyingIsin                          |-> [i \in 1 .. 12 |-> 0],
      underlyingCurrency                      |-> [i \in 1 .. 3 |-> 0],
      minimumDisplayQty                       |-> [i \in 1 .. 4 |-> 0],
      retailServiceFlag                       |-> [i \in 1 .. 1 |-> 0],
      selfMatchPrevention                     |-> [i \in 1 .. 1 |-> 0] ]

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
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.netAssetValueIdentifier = one] : one \in Sample(7) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.securitySubType = one] : one \in Sample(2) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.maturityMonthYear = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.securityStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.strikeValue = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.exerciseStyle = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.putOrCall = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.positionLimit = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.ntPositionLimit = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.issuer = one] : one \in Sample(12) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.cpRegType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.barrier = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.lastTradingDay = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.automaticExpiration = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.feeType = one] : one \in Sample(2) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.barrier2 = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.triggerBarrier = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.triggerUpperBarrier = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.averageQuarterlyTurnover = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.tradingScope = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.sicavCounterpartyMember = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.netAssetValueIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.referenceTradingVenue = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.outstandingCapital = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.firstTradingDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.settlementSystem = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.numberOfDecimals = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.numberOfHolders = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.outstandingShares = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.minimumAuthorizedShares = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.minimumCapital = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.lastAdmissionDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.barrierReturn = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.investmentFundManager = one] : one \in Sample(80) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.effectiveAmountFiltersRoutedOrders = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.orderNumberOfDecimals = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.investmentFundClass = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.masterFundName = one] : one \in Sample(80) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.investmentFundManagementCompany = one] : one \in Sample(80) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.investmentFundDepository = one] : one \in Sample(80) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.investmentFundCategory = one] : one \in Sample(80) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.investmentFundMinimumSubscriptionAmount = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.investmentFundMinimumMaintenanceAmount = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.investmentFundCutOffTime = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.navCommunicationTerm = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.investmentFundNumberOfDecimals = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.commodityDerivativeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.doubleVolumeCapReached = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.adt = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.baseProduct = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.subProduct = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.furtherSubProduct = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.adnt = one] : one \in Sample(8) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.priceTickRule = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.underlyingSymbol = one] : one \in Sample(22) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.underlyingIsin = one] : one \in Sample(12) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.underlyingCurrency = one] : one \in Sample(3) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.minimumDisplayQty = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.retailServiceFlag = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListUpdateReportMessage EXCEPT !.selfMatchPrevention = one] : one \in Sample(1) }

(***************************************************************************)
(* Security Status Message: 115 bytes                                      *)
(***************************************************************************)

SecurityStatusMessage ==
    [ sequenceNumber                   : Sample(4),
      securityCode                     : Sample(4),
      transactionDateAndTime           : Sample(8),
      referencePrice                   : Sample(8),
      staticPrice                      : Sample(8),
      dynamicPriceOscilationPercentage : Sample(8),
      dynamicRangeMultiplier           : Sample(1),
      auctionTriggerPrice              : Sample(8),
      auctionEndTime                   : Sample(8),
      liquidativeValueDate             : Sample(4),
      bonusWarrantsWithActiveBonus     : Sample(1),
      securityTradingStatus            : Sample(1),
      auctionOrigin                    : Sample(1),
      nonAvailabilityReason            : Sample(1),
      exemptionSituation               : Sample(1),
      blockOscilationPercentage        : Sample(8),
      highLimitPrice                   : Sample(8),
      lowLimitPrice                    : Sample(8),
      liquidativeValue                 : Sample(8),
      staticRangeType                  : Sample(1),
      orderStaticRange                 : Sample(8),
      blockStaticRange                 : Sample(8) ]

EncodeSecurityStatusMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime
        \o message.referencePrice
        \o message.staticPrice
        \o message.dynamicPriceOscilationPercentage
        \o message.dynamicRangeMultiplier
        \o message.auctionTriggerPrice
        \o message.auctionEndTime
        \o message.liquidativeValueDate
        \o message.bonusWarrantsWithActiveBonus
        \o message.securityTradingStatus
        \o message.auctionOrigin
        \o message.nonAvailabilityReason
        \o message.exemptionSituation
        \o message.blockOscilationPercentage
        \o message.highLimitPrice
        \o message.lowLimitPrice
        \o message.liquidativeValue
        \o message.staticRangeType
        \o message.orderStaticRange
        \o message.blockStaticRange

DecodeSecurityStatusMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET referencePrice == ReadBytes(transactionDateAndTime.rest, 8) IN IF ~referencePrice.ok THEN Fail ELSE
    LET staticPrice == ReadBytes(referencePrice.rest, 8) IN IF ~staticPrice.ok THEN Fail ELSE
    LET dynamicPriceOscilationPercentage == ReadBytes(staticPrice.rest, 8) IN IF ~dynamicPriceOscilationPercentage.ok THEN Fail ELSE
    LET dynamicRangeMultiplier == ReadBytes(dynamicPriceOscilationPercentage.rest, 1) IN IF ~dynamicRangeMultiplier.ok THEN Fail ELSE
    LET auctionTriggerPrice == ReadBytes(dynamicRangeMultiplier.rest, 8) IN IF ~auctionTriggerPrice.ok THEN Fail ELSE
    LET auctionEndTime == ReadBytes(auctionTriggerPrice.rest, 8) IN IF ~auctionEndTime.ok THEN Fail ELSE
    LET liquidativeValueDate == ReadBytes(auctionEndTime.rest, 4) IN IF ~liquidativeValueDate.ok THEN Fail ELSE
    LET bonusWarrantsWithActiveBonus == ReadBytes(liquidativeValueDate.rest, 1) IN IF ~bonusWarrantsWithActiveBonus.ok THEN Fail ELSE
    LET securityTradingStatus == ReadBytes(bonusWarrantsWithActiveBonus.rest, 1) IN IF ~securityTradingStatus.ok THEN Fail ELSE
    LET auctionOrigin == ReadBytes(securityTradingStatus.rest, 1) IN IF ~auctionOrigin.ok THEN Fail ELSE
    LET nonAvailabilityReason == ReadBytes(auctionOrigin.rest, 1) IN IF ~nonAvailabilityReason.ok THEN Fail ELSE
    LET exemptionSituation == ReadBytes(nonAvailabilityReason.rest, 1) IN IF ~exemptionSituation.ok THEN Fail ELSE
    LET blockOscilationPercentage == ReadBytes(exemptionSituation.rest, 8) IN IF ~blockOscilationPercentage.ok THEN Fail ELSE
    LET highLimitPrice == ReadBytes(blockOscilationPercentage.rest, 8) IN IF ~highLimitPrice.ok THEN Fail ELSE
    LET lowLimitPrice == ReadBytes(highLimitPrice.rest, 8) IN IF ~lowLimitPrice.ok THEN Fail ELSE
    LET liquidativeValue == ReadBytes(lowLimitPrice.rest, 8) IN IF ~liquidativeValue.ok THEN Fail ELSE
    LET staticRangeType == ReadBytes(liquidativeValue.rest, 1) IN IF ~staticRangeType.ok THEN Fail ELSE
    LET orderStaticRange == ReadBytes(staticRangeType.rest, 8) IN IF ~orderStaticRange.ok THEN Fail ELSE
    LET blockStaticRange == ReadBytes(orderStaticRange.rest, 8) IN IF ~blockStaticRange.ok THEN Fail ELSE
    Ok([ sequenceNumber                   |-> sequenceNumber.value,
         securityCode                     |-> securityCode.value,
         transactionDateAndTime           |-> transactionDateAndTime.value,
         referencePrice                   |-> referencePrice.value,
         staticPrice                      |-> staticPrice.value,
         dynamicPriceOscilationPercentage |-> dynamicPriceOscilationPercentage.value,
         dynamicRangeMultiplier           |-> dynamicRangeMultiplier.value,
         auctionTriggerPrice              |-> auctionTriggerPrice.value,
         auctionEndTime                   |-> auctionEndTime.value,
         liquidativeValueDate             |-> liquidativeValueDate.value,
         bonusWarrantsWithActiveBonus     |-> bonusWarrantsWithActiveBonus.value,
         securityTradingStatus            |-> securityTradingStatus.value,
         auctionOrigin                    |-> auctionOrigin.value,
         nonAvailabilityReason            |-> nonAvailabilityReason.value,
         exemptionSituation               |-> exemptionSituation.value,
         blockOscilationPercentage        |-> blockOscilationPercentage.value,
         highLimitPrice                   |-> highLimitPrice.value,
         lowLimitPrice                    |-> lowLimitPrice.value,
         liquidativeValue                 |-> liquidativeValue.value,
         staticRangeType                  |-> staticRangeType.value,
         orderStaticRange                 |-> orderStaticRange.value,
         blockStaticRange                 |-> blockStaticRange.value ], blockStaticRange.rest)

ZeroSecurityStatusMessage ==
    [ sequenceNumber                   |-> [i \in 1 .. 4 |-> 0],
      securityCode                     |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime           |-> [i \in 1 .. 8 |-> 0],
      referencePrice                   |-> [i \in 1 .. 8 |-> 0],
      staticPrice                      |-> [i \in 1 .. 8 |-> 0],
      dynamicPriceOscilationPercentage |-> [i \in 1 .. 8 |-> 0],
      dynamicRangeMultiplier           |-> [i \in 1 .. 1 |-> 0],
      auctionTriggerPrice              |-> [i \in 1 .. 8 |-> 0],
      auctionEndTime                   |-> [i \in 1 .. 8 |-> 0],
      liquidativeValueDate             |-> [i \in 1 .. 4 |-> 0],
      bonusWarrantsWithActiveBonus     |-> [i \in 1 .. 1 |-> 0],
      securityTradingStatus            |-> [i \in 1 .. 1 |-> 0],
      auctionOrigin                    |-> [i \in 1 .. 1 |-> 0],
      nonAvailabilityReason            |-> [i \in 1 .. 1 |-> 0],
      exemptionSituation               |-> [i \in 1 .. 1 |-> 0],
      blockOscilationPercentage        |-> [i \in 1 .. 8 |-> 0],
      highLimitPrice                   |-> [i \in 1 .. 8 |-> 0],
      lowLimitPrice                    |-> [i \in 1 .. 8 |-> 0],
      liquidativeValue                 |-> [i \in 1 .. 8 |-> 0],
      staticRangeType                  |-> [i \in 1 .. 1 |-> 0],
      orderStaticRange                 |-> [i \in 1 .. 8 |-> 0],
      blockStaticRange                 |-> [i \in 1 .. 8 |-> 0] ]

(* Security Status Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusMessage ==
    { ZeroSecurityStatusMessage }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.referencePrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.staticPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.dynamicPriceOscilationPercentage = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.dynamicRangeMultiplier = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.auctionTriggerPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.auctionEndTime = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.liquidativeValueDate = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.bonusWarrantsWithActiveBonus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.securityTradingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.auctionOrigin = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.nonAvailabilityReason = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.exemptionSituation = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.blockOscilationPercentage = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.highLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.lowLimitPrice = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.liquidativeValue = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.staticRangeType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.orderStaticRange = one] : one \in Sample(8) }
        \cup { [ZeroSecurityStatusMessage EXCEPT !.blockStaticRange = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade Market Post Transparency Information Topofbook Message: 55 bytes  *)
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
      buyerBolsaCode         : Sample(1),
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
        \o message.buyerBolsaCode
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
    LET buyerBolsaCode == ReadBytes(algoFlag.rest, 1) IN IF ~buyerBolsaCode.ok THEN Fail ELSE
    LET settlDate == ReadBytes(buyerBolsaCode.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
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
         buyerBolsaCode         |-> buyerBolsaCode.value,
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
      buyerBolsaCode         |-> [i \in 1 .. 1 |-> 0],
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
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.buyerBolsaCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeMarketPostTransparencyInformationTopofbookMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Trade Amendment Or Cancellation Message: 98 bytes                 *)
(***************************************************************************)

TradeTradeAmendmentOrCancellationMessage ==
    [ sequenceNumber             : Sample(4),
      securityCode               : Sample(4),
      transactionDateAndTime     : Sample(8),
      marketSegmentId            : Sample(4),
      tradingSessionId           : Sample(1),
      trdMatchId                 : Sample(4),
      tradeType                  : Sample(1),
      lastPx                     : Sample(8),
      lastQty                    : Sample(4),
      grossTradeAmt              : Sample(8),
      designation                : Sample(1),
      marketMechanism            : Sample(1),
      algoFlag                   : Sample(1),
      buyerBolsaCode             : Sample(1),
      settlDate                  : Sample(4),
      transactionCategory        : Sample(1),
      lastChangeFlag             : Sample(1),
      bencrfptFlag               : Sample(1),
      tradePriceCondition        : Sample(1),
      preTradeTransparencyWaiver : Sample(1),
      deferralWaiver             : Sample(1),
      publishDateAndTime         : Sample(8),
      tradeDate                  : Sample(8),
      tradeSessionDate           : Sample(4),
      volumeFloat                : Sample(8),
      sicavFundCounterpartySide  : Sample(1),
      amendedTradeType           : Sample(1),
      execRefId                  : Sample(4),
      amendedTradeDate           : Sample(4) ]

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
        \o message.buyerBolsaCode
        \o message.settlDate
        \o message.transactionCategory
        \o message.lastChangeFlag
        \o message.bencrfptFlag
        \o message.tradePriceCondition
        \o message.preTradeTransparencyWaiver
        \o message.deferralWaiver
        \o message.publishDateAndTime
        \o message.tradeDate
        \o message.tradeSessionDate
        \o message.volumeFloat
        \o message.sicavFundCounterpartySide
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
    LET buyerBolsaCode == ReadBytes(algoFlag.rest, 1) IN IF ~buyerBolsaCode.ok THEN Fail ELSE
    LET settlDate == ReadBytes(buyerBolsaCode.rest, 4) IN IF ~settlDate.ok THEN Fail ELSE
    LET transactionCategory == ReadBytes(settlDate.rest, 1) IN IF ~transactionCategory.ok THEN Fail ELSE
    LET lastChangeFlag == ReadBytes(transactionCategory.rest, 1) IN IF ~lastChangeFlag.ok THEN Fail ELSE
    LET bencrfptFlag == ReadBytes(lastChangeFlag.rest, 1) IN IF ~bencrfptFlag.ok THEN Fail ELSE
    LET tradePriceCondition == ReadBytes(bencrfptFlag.rest, 1) IN IF ~tradePriceCondition.ok THEN Fail ELSE
    LET preTradeTransparencyWaiver == ReadBytes(tradePriceCondition.rest, 1) IN IF ~preTradeTransparencyWaiver.ok THEN Fail ELSE
    LET deferralWaiver == ReadBytes(preTradeTransparencyWaiver.rest, 1) IN IF ~deferralWaiver.ok THEN Fail ELSE
    LET publishDateAndTime == ReadBytes(deferralWaiver.rest, 8) IN IF ~publishDateAndTime.ok THEN Fail ELSE
    LET tradeDate == ReadBytes(publishDateAndTime.rest, 8) IN IF ~tradeDate.ok THEN Fail ELSE
    LET tradeSessionDate == ReadBytes(tradeDate.rest, 4) IN IF ~tradeSessionDate.ok THEN Fail ELSE
    LET volumeFloat == ReadBytes(tradeSessionDate.rest, 8) IN IF ~volumeFloat.ok THEN Fail ELSE
    LET sicavFundCounterpartySide == ReadBytes(volumeFloat.rest, 1) IN IF ~sicavFundCounterpartySide.ok THEN Fail ELSE
    LET amendedTradeType == ReadBytes(sicavFundCounterpartySide.rest, 1) IN IF ~amendedTradeType.ok THEN Fail ELSE
    LET execRefId == ReadBytes(amendedTradeType.rest, 4) IN IF ~execRefId.ok THEN Fail ELSE
    LET amendedTradeDate == ReadBytes(execRefId.rest, 4) IN IF ~amendedTradeDate.ok THEN Fail ELSE
    Ok([ sequenceNumber             |-> sequenceNumber.value,
         securityCode               |-> securityCode.value,
         transactionDateAndTime     |-> transactionDateAndTime.value,
         marketSegmentId            |-> marketSegmentId.value,
         tradingSessionId           |-> tradingSessionId.value,
         trdMatchId                 |-> trdMatchId.value,
         tradeType                  |-> tradeType.value,
         lastPx                     |-> lastPx.value,
         lastQty                    |-> lastQty.value,
         grossTradeAmt              |-> grossTradeAmt.value,
         designation                |-> designation.value,
         marketMechanism            |-> marketMechanism.value,
         algoFlag                   |-> algoFlag.value,
         buyerBolsaCode             |-> buyerBolsaCode.value,
         settlDate                  |-> settlDate.value,
         transactionCategory        |-> transactionCategory.value,
         lastChangeFlag             |-> lastChangeFlag.value,
         bencrfptFlag               |-> bencrfptFlag.value,
         tradePriceCondition        |-> tradePriceCondition.value,
         preTradeTransparencyWaiver |-> preTradeTransparencyWaiver.value,
         deferralWaiver             |-> deferralWaiver.value,
         publishDateAndTime         |-> publishDateAndTime.value,
         tradeDate                  |-> tradeDate.value,
         tradeSessionDate           |-> tradeSessionDate.value,
         volumeFloat                |-> volumeFloat.value,
         sicavFundCounterpartySide  |-> sicavFundCounterpartySide.value,
         amendedTradeType           |-> amendedTradeType.value,
         execRefId                  |-> execRefId.value,
         amendedTradeDate           |-> amendedTradeDate.value ], amendedTradeDate.rest)

ZeroTradeTradeAmendmentOrCancellationMessage ==
    [ sequenceNumber             |-> [i \in 1 .. 4 |-> 0],
      securityCode               |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime     |-> [i \in 1 .. 8 |-> 0],
      marketSegmentId            |-> [i \in 1 .. 4 |-> 0],
      tradingSessionId           |-> [i \in 1 .. 1 |-> 0],
      trdMatchId                 |-> [i \in 1 .. 4 |-> 0],
      tradeType                  |-> [i \in 1 .. 1 |-> 0],
      lastPx                     |-> [i \in 1 .. 8 |-> 0],
      lastQty                    |-> [i \in 1 .. 4 |-> 0],
      grossTradeAmt              |-> [i \in 1 .. 8 |-> 0],
      designation                |-> [i \in 1 .. 1 |-> 0],
      marketMechanism            |-> [i \in 1 .. 1 |-> 0],
      algoFlag                   |-> [i \in 1 .. 1 |-> 0],
      buyerBolsaCode             |-> [i \in 1 .. 1 |-> 0],
      settlDate                  |-> [i \in 1 .. 4 |-> 0],
      transactionCategory        |-> [i \in 1 .. 1 |-> 0],
      lastChangeFlag             |-> [i \in 1 .. 1 |-> 0],
      bencrfptFlag               |-> [i \in 1 .. 1 |-> 0],
      tradePriceCondition        |-> [i \in 1 .. 1 |-> 0],
      preTradeTransparencyWaiver |-> [i \in 1 .. 1 |-> 0],
      deferralWaiver             |-> [i \in 1 .. 1 |-> 0],
      publishDateAndTime         |-> [i \in 1 .. 8 |-> 0],
      tradeDate                  |-> [i \in 1 .. 8 |-> 0],
      tradeSessionDate           |-> [i \in 1 .. 4 |-> 0],
      volumeFloat                |-> [i \in 1 .. 8 |-> 0],
      sicavFundCounterpartySide  |-> [i \in 1 .. 1 |-> 0],
      amendedTradeType           |-> [i \in 1 .. 1 |-> 0],
      execRefId                  |-> [i \in 1 .. 4 |-> 0],
      amendedTradeDate           |-> [i \in 1 .. 4 |-> 0] ]

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
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.buyerBolsaCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.settlDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.lastChangeFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.bencrfptFlag = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.tradePriceCondition = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.preTradeTransparencyWaiver = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.deferralWaiver = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.publishDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.tradeDate = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.tradeSessionDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.volumeFloat = one] : one \in Sample(8) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.sicavFundCounterpartySide = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.amendedTradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.execRefId = one] : one \in Sample(4) }
        \cup { [ZeroTradeTradeAmendmentOrCancellationMessage EXCEPT !.amendedTradeDate = one] : one \in Sample(4) }

(***************************************************************************)
(* Topofbook Message: 44 bytes                                             *)
(***************************************************************************)

TopofbookMessage ==
    [ sequenceNumber         : Sample(4),
      securityCode           : Sample(4),
      transactionDateAndTime : Sample(8),
      bidOrders1             : Sample(2),
      bidSize1               : Sample(4),
      bidPx1                 : Sample(8),
      askOrders1             : Sample(2),
      askSize1               : Sample(4),
      askPx1                 : Sample(8) ]

EncodeTopofbookMessage(message) ==
    message.sequenceNumber
        \o message.securityCode
        \o message.transactionDateAndTime
        \o message.bidOrders1
        \o message.bidSize1
        \o message.bidPx1
        \o message.askOrders1
        \o message.askSize1
        \o message.askPx1

DecodeTopofbookMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET securityCode == ReadBytes(sequenceNumber.rest, 4) IN IF ~securityCode.ok THEN Fail ELSE
    LET transactionDateAndTime == ReadBytes(securityCode.rest, 8) IN IF ~transactionDateAndTime.ok THEN Fail ELSE
    LET bidOrders1 == ReadBytes(transactionDateAndTime.rest, 2) IN IF ~bidOrders1.ok THEN Fail ELSE
    LET bidSize1 == ReadBytes(bidOrders1.rest, 4) IN IF ~bidSize1.ok THEN Fail ELSE
    LET bidPx1 == ReadBytes(bidSize1.rest, 8) IN IF ~bidPx1.ok THEN Fail ELSE
    LET askOrders1 == ReadBytes(bidPx1.rest, 2) IN IF ~askOrders1.ok THEN Fail ELSE
    LET askSize1 == ReadBytes(askOrders1.rest, 4) IN IF ~askSize1.ok THEN Fail ELSE
    LET askPx1 == ReadBytes(askSize1.rest, 8) IN IF ~askPx1.ok THEN Fail ELSE
    Ok([ sequenceNumber         |-> sequenceNumber.value,
         securityCode           |-> securityCode.value,
         transactionDateAndTime |-> transactionDateAndTime.value,
         bidOrders1             |-> bidOrders1.value,
         bidSize1               |-> bidSize1.value,
         bidPx1                 |-> bidPx1.value,
         askOrders1             |-> askOrders1.value,
         askSize1               |-> askSize1.value,
         askPx1                 |-> askPx1.value ], askPx1.rest)

ZeroTopofbookMessage ==
    [ sequenceNumber         |-> [i \in 1 .. 4 |-> 0],
      securityCode           |-> [i \in 1 .. 4 |-> 0],
      transactionDateAndTime |-> [i \in 1 .. 8 |-> 0],
      bidOrders1             |-> [i \in 1 .. 2 |-> 0],
      bidSize1               |-> [i \in 1 .. 4 |-> 0],
      bidPx1                 |-> [i \in 1 .. 8 |-> 0],
      askOrders1             |-> [i \in 1 .. 2 |-> 0],
      askSize1               |-> [i \in 1 .. 4 |-> 0],
      askPx1                 |-> [i \in 1 .. 8 |-> 0] ]

(* Topofbook Message at zero, then each field in turn at the values it is checked at *)
CheckedTopofbookMessage ==
    { ZeroTopofbookMessage }
        \cup { [ZeroTopofbookMessage EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTopofbookMessage EXCEPT !.securityCode = one] : one \in Sample(4) }
        \cup { [ZeroTopofbookMessage EXCEPT !.transactionDateAndTime = one] : one \in Sample(8) }
        \cup { [ZeroTopofbookMessage EXCEPT !.bidOrders1 = one] : one \in Sample(2) }
        \cup { [ZeroTopofbookMessage EXCEPT !.bidSize1 = one] : one \in Sample(4) }
        \cup { [ZeroTopofbookMessage EXCEPT !.bidPx1 = one] : one \in Sample(8) }
        \cup { [ZeroTopofbookMessage EXCEPT !.askOrders1 = one] : one \in Sample(2) }
        \cup { [ZeroTopofbookMessage EXCEPT !.askSize1 = one] : one \in Sample(4) }
        \cup { [ZeroTopofbookMessage EXCEPT !.askPx1 = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LogonResponseMessageCode == 8  \* 0x08
LogoutResponseMessageCode == 11  \* 0x0b
HeartbeatMessageCode == 48  \* 0x30
NetworkStatusMessageCode == 10  \* 0x0a
TradingSessionStatusMessageCode == 104  \* 0x68
NewsMessageCode == 66  \* 0x42
SecurityListCancellationReportMessageCode == 120  \* 0x78
StatisticsMessageCode == 132  \* 0x84
SecurityListMessageCode == 121  \* 0x79
SecurityListUpdateReportMessageCode == 128  \* 0x80
SecurityStatusMessageCode == 102  \* 0x66
TradeMarketPostTransparencyInformationTopofbookMessageCode == 16  \* 0x10
TradeTradeAmendmentOrCancellationMessageCode == 24  \* 0x18
TopofbookMessageCode == 130  \* 0x82

Payload ==
    [ tag : {LogonResponseMessageCode}, body : LogonResponseMessage ]
        \cup [ tag : {LogoutResponseMessageCode}, body : LogoutResponseMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : HeartbeatMessage ]
        \cup [ tag : {NetworkStatusMessageCode}, body : NetworkStatusMessage ]
        \cup [ tag : {TradingSessionStatusMessageCode}, body : TradingSessionStatusMessage ]
        \cup [ tag : {NewsMessageCode}, body : NewsMessage ]
        \cup [ tag : {SecurityListCancellationReportMessageCode}, body : SecurityListCancellationReportMessage ]
        \cup [ tag : {StatisticsMessageCode}, body : StatisticsMessage ]
        \cup [ tag : {SecurityListMessageCode}, body : SecurityListMessage ]
        \cup [ tag : {SecurityListUpdateReportMessageCode}, body : SecurityListUpdateReportMessage ]
        \cup [ tag : {SecurityStatusMessageCode}, body : SecurityStatusMessage ]
        \cup [ tag : {TradeMarketPostTransparencyInformationTopofbookMessageCode}, body : TradeMarketPostTransparencyInformationTopofbookMessage ]
        \cup [ tag : {TradeTradeAmendmentOrCancellationMessageCode}, body : TradeTradeAmendmentOrCancellationMessage ]
        \cup [ tag : {TopofbookMessageCode}, body : TopofbookMessage ]

EncodePayload(message) ==
    CASE message.tag = LogonResponseMessageCode -> EncodeLogonResponseMessage(message.body)
      [] message.tag = LogoutResponseMessageCode -> EncodeLogoutResponseMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> EncodeHeartbeatMessage(message.body)
      [] message.tag = NetworkStatusMessageCode -> EncodeNetworkStatusMessage(message.body)
      [] message.tag = TradingSessionStatusMessageCode -> EncodeTradingSessionStatusMessage(message.body)
      [] message.tag = NewsMessageCode -> EncodeNewsMessage(message.body)
      [] message.tag = SecurityListCancellationReportMessageCode -> EncodeSecurityListCancellationReportMessage(message.body)
      [] message.tag = StatisticsMessageCode -> EncodeStatisticsMessage(message.body)
      [] message.tag = SecurityListMessageCode -> EncodeSecurityListMessage(message.body)
      [] message.tag = SecurityListUpdateReportMessageCode -> EncodeSecurityListUpdateReportMessage(message.body)
      [] message.tag = SecurityStatusMessageCode -> EncodeSecurityStatusMessage(message.body)
      [] message.tag = TradeMarketPostTransparencyInformationTopofbookMessageCode -> EncodeTradeMarketPostTransparencyInformationTopofbookMessage(message.body)
      [] message.tag = TradeTradeAmendmentOrCancellationMessageCode -> EncodeTradeTradeAmendmentOrCancellationMessage(message.body)
      [] message.tag = TopofbookMessageCode -> EncodeTopofbookMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonResponseMessageCode -> DecodeLogonResponseMessage(bytes)
              [] tag = LogoutResponseMessageCode -> DecodeLogoutResponseMessage(bytes)
              [] tag = HeartbeatMessageCode -> DecodeHeartbeatMessage(bytes)
              [] tag = NetworkStatusMessageCode -> DecodeNetworkStatusMessage(bytes)
              [] tag = TradingSessionStatusMessageCode -> DecodeTradingSessionStatusMessage(bytes)
              [] tag = NewsMessageCode -> DecodeNewsMessage(bytes)
              [] tag = SecurityListCancellationReportMessageCode -> DecodeSecurityListCancellationReportMessage(bytes)
              [] tag = StatisticsMessageCode -> DecodeStatisticsMessage(bytes)
              [] tag = SecurityListMessageCode -> DecodeSecurityListMessage(bytes)
              [] tag = SecurityListUpdateReportMessageCode -> DecodeSecurityListUpdateReportMessage(bytes)
              [] tag = SecurityStatusMessageCode -> DecodeSecurityStatusMessage(bytes)
              [] tag = TradeMarketPostTransparencyInformationTopofbookMessageCode -> DecodeTradeMarketPostTransparencyInformationTopofbookMessage(bytes)
              [] tag = TradeTradeAmendmentOrCancellationMessageCode -> DecodeTradeTradeAmendmentOrCancellationMessage(bytes)
              [] tag = TopofbookMessageCode -> DecodeTopofbookMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LogonResponseMessageCode, body |-> ZeroLogonResponseMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LogonResponseMessageCode, body |-> one] : one \in CheckedLogonResponseMessage }
        \cup { [tag |-> LogoutResponseMessageCode, body |-> one] : one \in CheckedLogoutResponseMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> one] : one \in CheckedHeartbeatMessage }
        \cup { [tag |-> NetworkStatusMessageCode, body |-> one] : one \in CheckedNetworkStatusMessage }
        \cup { [tag |-> TradingSessionStatusMessageCode, body |-> one] : one \in CheckedTradingSessionStatusMessage }
        \cup { [tag |-> NewsMessageCode, body |-> one] : one \in CheckedNewsMessage }
        \cup { [tag |-> SecurityListCancellationReportMessageCode, body |-> one] : one \in CheckedSecurityListCancellationReportMessage }
        \cup { [tag |-> StatisticsMessageCode, body |-> one] : one \in CheckedStatisticsMessage }
        \cup { [tag |-> SecurityListMessageCode, body |-> one] : one \in CheckedSecurityListMessage }
        \cup { [tag |-> SecurityListUpdateReportMessageCode, body |-> one] : one \in CheckedSecurityListUpdateReportMessage }
        \cup { [tag |-> SecurityStatusMessageCode, body |-> one] : one \in CheckedSecurityStatusMessage }
        \cup { [tag |-> TradeMarketPostTransparencyInformationTopofbookMessageCode, body |-> one] : one \in CheckedTradeMarketPostTransparencyInformationTopofbookMessage }
        \cup { [tag |-> TradeTradeAmendmentOrCancellationMessageCode, body |-> one] : one \in CheckedTradeTradeAmendmentOrCancellationMessage }
        \cup { [tag |-> TopofbookMessageCode, body |-> one] : one \in CheckedTopofbookMessage }

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
      [ZeroMessage EXCEPT !.payload = [tag |-> TradingSessionStatusMessageCode, body |-> ZeroTradingSessionStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewsMessageCode, body |-> ZeroNewsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityListCancellationReportMessageCode, body |-> ZeroSecurityListCancellationReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> StatisticsMessageCode, body |-> ZeroStatisticsMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityListMessageCode, body |-> ZeroSecurityListMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityListUpdateReportMessageCode, body |-> ZeroSecurityListUpdateReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityStatusMessageCode, body |-> ZeroSecurityStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMarketPostTransparencyInformationTopofbookMessageCode, body |-> ZeroTradeMarketPostTransparencyInformationTopofbookMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeTradeAmendmentOrCancellationMessageCode, body |-> ZeroTradeTradeAmendmentOrCancellationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TopofbookMessageCode, body |-> ZeroTopofbookMessage]] }

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

(* Every Topofbook Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTopofbookMessage ==
    \A message \in CheckedTopofbookMessage :
        LET read == DecodeTopofbookMessage(EncodeTopofbookMessage(message))
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
