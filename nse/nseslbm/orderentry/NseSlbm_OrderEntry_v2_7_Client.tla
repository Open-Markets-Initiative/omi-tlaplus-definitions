------------------ MODULE NseSlbm_OrderEntry_v2_7_Client -------------------
(***************************************************************************)
(* National Stock Exchange of India Ltd Order Entry v2.7                   *)
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
(* License: MIT No Attribution                                             *)
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
(* Logon Request Message: 172 bytes                                        *)
(***************************************************************************)

LogonRequestMessage ==
    [ userId                     : Sample(4),
      password                   : Sample(8),
      newPassword                : Sample(8),
      traderName                 : Sample(26),
      lastPasswordChangeDateTime : Sample(4),
      brokerId                   : Sample(5),
      reserved1                  : Sample(1),
      branchId                   : Sample(2),
      versionNumber              : Sample(4),
      reserved56                 : Sample(56),
      userType                   : Sample(2),
      sequenceNumber             : Sample(8),
      workstationNumber          : Sample(14),
      brokerStatus               : Sample(1),
      showIndex                  : Sample(1),
      brokerEligibilityPerMarket : Sample(2),
      logonRequestBrokerName     : Sample(26) ]

EncodeLogonRequestMessage(message) ==
    message.userId
        \o message.password
        \o message.newPassword
        \o message.traderName
        \o message.lastPasswordChangeDateTime
        \o message.brokerId
        \o message.reserved1
        \o message.branchId
        \o message.versionNumber
        \o message.reserved56
        \o message.userType
        \o message.sequenceNumber
        \o message.workstationNumber
        \o message.brokerStatus
        \o message.showIndex
        \o message.brokerEligibilityPerMarket
        \o message.logonRequestBrokerName

DecodeLogonRequestMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET password == ReadBytes(userId.rest, 8) IN IF ~password.ok THEN Fail ELSE
    LET newPassword == ReadBytes(password.rest, 8) IN IF ~newPassword.ok THEN Fail ELSE
    LET traderName == ReadBytes(newPassword.rest, 26) IN IF ~traderName.ok THEN Fail ELSE
    LET lastPasswordChangeDateTime == ReadBytes(traderName.rest, 4) IN IF ~lastPasswordChangeDateTime.ok THEN Fail ELSE
    LET brokerId == ReadBytes(lastPasswordChangeDateTime.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(brokerId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET branchId == ReadBytes(reserved1.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET versionNumber == ReadBytes(branchId.rest, 4) IN IF ~versionNumber.ok THEN Fail ELSE
    LET reserved56 == ReadBytes(versionNumber.rest, 56) IN IF ~reserved56.ok THEN Fail ELSE
    LET userType == ReadBytes(reserved56.rest, 2) IN IF ~userType.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(userType.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET workstationNumber == ReadBytes(sequenceNumber.rest, 14) IN IF ~workstationNumber.ok THEN Fail ELSE
    LET brokerStatus == ReadBytes(workstationNumber.rest, 1) IN IF ~brokerStatus.ok THEN Fail ELSE
    LET showIndex == ReadBytes(brokerStatus.rest, 1) IN IF ~showIndex.ok THEN Fail ELSE
    LET brokerEligibilityPerMarket == ReadBytes(showIndex.rest, 2) IN IF ~brokerEligibilityPerMarket.ok THEN Fail ELSE
    LET logonRequestBrokerName == ReadBytes(brokerEligibilityPerMarket.rest, 26) IN IF ~logonRequestBrokerName.ok THEN Fail ELSE
    Ok([ userId                     |-> userId.value,
         password                   |-> password.value,
         newPassword                |-> newPassword.value,
         traderName                 |-> traderName.value,
         lastPasswordChangeDateTime |-> lastPasswordChangeDateTime.value,
         brokerId                   |-> brokerId.value,
         reserved1                  |-> reserved1.value,
         branchId                   |-> branchId.value,
         versionNumber              |-> versionNumber.value,
         reserved56                 |-> reserved56.value,
         userType                   |-> userType.value,
         sequenceNumber             |-> sequenceNumber.value,
         workstationNumber          |-> workstationNumber.value,
         brokerStatus               |-> brokerStatus.value,
         showIndex                  |-> showIndex.value,
         brokerEligibilityPerMarket |-> brokerEligibilityPerMarket.value,
         logonRequestBrokerName     |-> logonRequestBrokerName.value ], logonRequestBrokerName.rest)

ZeroLogonRequestMessage ==
    [ userId                     |-> [i \in 1 .. 4 |-> 0],
      password                   |-> [i \in 1 .. 8 |-> 0],
      newPassword                |-> [i \in 1 .. 8 |-> 0],
      traderName                 |-> [i \in 1 .. 26 |-> 0],
      lastPasswordChangeDateTime |-> [i \in 1 .. 4 |-> 0],
      brokerId                   |-> [i \in 1 .. 5 |-> 0],
      reserved1                  |-> [i \in 1 .. 1 |-> 0],
      branchId                   |-> [i \in 1 .. 2 |-> 0],
      versionNumber              |-> [i \in 1 .. 4 |-> 0],
      reserved56                 |-> [i \in 1 .. 56 |-> 0],
      userType                   |-> [i \in 1 .. 2 |-> 0],
      sequenceNumber             |-> [i \in 1 .. 8 |-> 0],
      workstationNumber          |-> [i \in 1 .. 14 |-> 0],
      brokerStatus               |-> [i \in 1 .. 1 |-> 0],
      showIndex                  |-> [i \in 1 .. 1 |-> 0],
      brokerEligibilityPerMarket |-> [i \in 1 .. 2 |-> 0],
      logonRequestBrokerName     |-> [i \in 1 .. 26 |-> 0] ]

(* Logon Request Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonRequestMessage ==
    { ZeroLogonRequestMessage }
        \cup { [ZeroLogonRequestMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.password = one] : one \in Sample(8) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.newPassword = one] : one \in Sample(8) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.traderName = one] : one \in Sample(26) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.lastPasswordChangeDateTime = one] : one \in Sample(4) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.versionNumber = one] : one \in Sample(4) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.reserved56 = one] : one \in Sample(56) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.userType = one] : one \in Sample(2) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.workstationNumber = one] : one \in Sample(14) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.brokerStatus = one] : one \in Sample(1) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.showIndex = one] : one \in Sample(1) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.brokerEligibilityPerMarket = one] : one \in Sample(2) }
        \cup { [ZeroLogonRequestMessage EXCEPT !.logonRequestBrokerName = one] : one \in Sample(26) }

(***************************************************************************)
(* Update Local Database Request Message: 18 bytes                         *)
(***************************************************************************)

UpdateLocalDatabaseRequestMessage ==
    [ lastUpdateSecurityTime    : Sample(4),
      lastUpdateParticipantTime : Sample(4),
      requestForOpenOrders      : Sample(1),
      reserved1                 : Sample(1),
      normalMarketStatus        : Sample(2),
      oddLotMarketStatus        : Sample(2),
      spotMarketStatus          : Sample(2),
      auctionMarketStatus       : Sample(2) ]

EncodeUpdateLocalDatabaseRequestMessage(message) ==
    message.lastUpdateSecurityTime
        \o message.lastUpdateParticipantTime
        \o message.requestForOpenOrders
        \o message.reserved1
        \o message.normalMarketStatus
        \o message.oddLotMarketStatus
        \o message.spotMarketStatus
        \o message.auctionMarketStatus

DecodeUpdateLocalDatabaseRequestMessage(bytes) ==
    LET lastUpdateSecurityTime == ReadBytes(bytes, 4) IN IF ~lastUpdateSecurityTime.ok THEN Fail ELSE
    LET lastUpdateParticipantTime == ReadBytes(lastUpdateSecurityTime.rest, 4) IN IF ~lastUpdateParticipantTime.ok THEN Fail ELSE
    LET requestForOpenOrders == ReadBytes(lastUpdateParticipantTime.rest, 1) IN IF ~requestForOpenOrders.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(requestForOpenOrders.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET normalMarketStatus == ReadBytes(reserved1.rest, 2) IN IF ~normalMarketStatus.ok THEN Fail ELSE
    LET oddLotMarketStatus == ReadBytes(normalMarketStatus.rest, 2) IN IF ~oddLotMarketStatus.ok THEN Fail ELSE
    LET spotMarketStatus == ReadBytes(oddLotMarketStatus.rest, 2) IN IF ~spotMarketStatus.ok THEN Fail ELSE
    LET auctionMarketStatus == ReadBytes(spotMarketStatus.rest, 2) IN IF ~auctionMarketStatus.ok THEN Fail ELSE
    Ok([ lastUpdateSecurityTime    |-> lastUpdateSecurityTime.value,
         lastUpdateParticipantTime |-> lastUpdateParticipantTime.value,
         requestForOpenOrders      |-> requestForOpenOrders.value,
         reserved1                 |-> reserved1.value,
         normalMarketStatus        |-> normalMarketStatus.value,
         oddLotMarketStatus        |-> oddLotMarketStatus.value,
         spotMarketStatus          |-> spotMarketStatus.value,
         auctionMarketStatus       |-> auctionMarketStatus.value ], auctionMarketStatus.rest)

ZeroUpdateLocalDatabaseRequestMessage ==
    [ lastUpdateSecurityTime    |-> [i \in 1 .. 4 |-> 0],
      lastUpdateParticipantTime |-> [i \in 1 .. 4 |-> 0],
      requestForOpenOrders      |-> [i \in 1 .. 1 |-> 0],
      reserved1                 |-> [i \in 1 .. 1 |-> 0],
      normalMarketStatus        |-> [i \in 1 .. 2 |-> 0],
      oddLotMarketStatus        |-> [i \in 1 .. 2 |-> 0],
      spotMarketStatus          |-> [i \in 1 .. 2 |-> 0],
      auctionMarketStatus       |-> [i \in 1 .. 2 |-> 0] ]

(* Update Local Database Request Message at zero, then each field in turn at the values it is checked at *)
CheckedUpdateLocalDatabaseRequestMessage ==
    { ZeroUpdateLocalDatabaseRequestMessage }
        \cup { [ZeroUpdateLocalDatabaseRequestMessage EXCEPT !.lastUpdateSecurityTime = one] : one \in Sample(4) }
        \cup { [ZeroUpdateLocalDatabaseRequestMessage EXCEPT !.lastUpdateParticipantTime = one] : one \in Sample(4) }
        \cup { [ZeroUpdateLocalDatabaseRequestMessage EXCEPT !.requestForOpenOrders = one] : one \in Sample(1) }
        \cup { [ZeroUpdateLocalDatabaseRequestMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroUpdateLocalDatabaseRequestMessage EXCEPT !.normalMarketStatus = one] : one \in Sample(2) }
        \cup { [ZeroUpdateLocalDatabaseRequestMessage EXCEPT !.oddLotMarketStatus = one] : one \in Sample(2) }
        \cup { [ZeroUpdateLocalDatabaseRequestMessage EXCEPT !.spotMarketStatus = one] : one \in Sample(2) }
        \cup { [ZeroUpdateLocalDatabaseRequestMessage EXCEPT !.auctionMarketStatus = one] : one \in Sample(2) }

(***************************************************************************)
(* Message Download Request Message: 8 bytes                               *)
(***************************************************************************)

MessageDownloadRequestMessage ==
    [ sequenceNumber : Sample(8) ]

EncodeMessageDownloadRequestMessage(message) ==
    message.sequenceNumber

DecodeMessageDownloadRequestMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroMessageDownloadRequestMessage ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Message Download Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMessageDownloadRequestMessage ==
    { ZeroMessageDownloadRequestMessage }
        \cup { [ZeroMessageDownloadRequestMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Sec Info: 12 bytes                                                      *)
(***************************************************************************)

SecInfo ==
    [ symbol : Sample(10),
      series : Sample(2) ]

EncodeSecInfo(message) ==
    message.symbol
        \o message.series

DecodeSecInfo(bytes) ==
    LET symbol == ReadBytes(bytes, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET series == ReadBytes(symbol.rest, 2) IN IF ~series.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value,
         series |-> series.value ], series.rest)

ZeroSecInfo ==
    [ symbol |-> [i \in 1 .. 10 |-> 0],
      series |-> [i \in 1 .. 2 |-> 0] ]

(* Sec Info at zero, then each field in turn at the values it is checked at *)
CheckedSecInfo ==
    { ZeroSecInfo }
        \cup { [ZeroSecInfo EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroSecInfo EXCEPT !.series = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Entry Request Message: 174 bytes                                  *)
(***************************************************************************)

OrderEntryRequestMessage ==
    [ participantType       : Sample(1),
      reserved1             : Sample(1),
      competitorPeriod      : Sample(2),
      solicitorPeriod       : Sample(2),
      modCxlBy              : Sample(1),
      filler9               : Sample(1),
      reasonCode            : Sample(2),
      reserved4             : Sample(4),
      secInfo               : SecInfo,
      auctionNumber         : Sample(2),
      opBrokerId            : Sample(5),
      suspended             : Sample(1),
      orderNumber           : Sample(8),
      accountNumber         : Sample(10),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVol          : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      volumeFilledToday     : Sample(4),
      price                 : Sample(4),
      triggerPrice          : Sample(4),
      reverseLegSettlDate   : Sample(4),
      entryDateTime         : Sample(4),
      minFillAon            : Sample(4),
      lastModified          : Sample(4),
      stOrderFlags          : Sample(2),
      branchId              : Sample(2),
      traderId              : Sample(4),
      brokerId              : Sample(5),
      oeRemarks             : Sample(21),
      transactionId         : Sample(4),
      settlor               : Sample(12),
      proClient             : Sample(2),
      settlementPeriod      : Sample(2),
      nnfField              : Sample(8),
      execTimeStamp         : Sample(8),
      reserved2             : Sample(2),
      orderType             : Sample(2) ]

EncodeOrderEntryRequestMessage(message) ==
    message.participantType
        \o message.reserved1
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.modCxlBy
        \o message.filler9
        \o message.reasonCode
        \o message.reserved4
        \o EncodeSecInfo(message.secInfo)
        \o message.auctionNumber
        \o message.opBrokerId
        \o message.suspended
        \o message.orderNumber
        \o message.accountNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVol
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.volumeFilledToday
        \o message.price
        \o message.triggerPrice
        \o message.reverseLegSettlDate
        \o message.entryDateTime
        \o message.minFillAon
        \o message.lastModified
        \o message.stOrderFlags
        \o message.branchId
        \o message.traderId
        \o message.brokerId
        \o message.oeRemarks
        \o message.transactionId
        \o message.settlor
        \o message.proClient
        \o message.settlementPeriod
        \o message.nnfField
        \o message.execTimeStamp
        \o message.reserved2
        \o message.orderType

DecodeOrderEntryRequestMessage(bytes) ==
    LET participantType == ReadBytes(bytes, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(participantType.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET competitorPeriod == ReadBytes(reserved1.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET modCxlBy == ReadBytes(solicitorPeriod.rest, 1) IN IF ~modCxlBy.ok THEN Fail ELSE
    LET filler9 == ReadBytes(modCxlBy.rest, 1) IN IF ~filler9.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(filler9.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reasonCode.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET secInfo == DecodeSecInfo(reserved4.rest) IN IF ~secInfo.ok THEN Fail ELSE
    LET auctionNumber == ReadBytes(secInfo.rest, 2) IN IF ~auctionNumber.ok THEN Fail ELSE
    LET opBrokerId == ReadBytes(auctionNumber.rest, 5) IN IF ~opBrokerId.ok THEN Fail ELSE
    LET suspended == ReadBytes(opBrokerId.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(suspended.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(orderNumber.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVol == ReadBytes(buySell.rest, 4) IN IF ~disclosedVol.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVol.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET volumeFilledToday == ReadBytes(volume.rest, 4) IN IF ~volumeFilledToday.ok THEN Fail ELSE
    LET price == ReadBytes(volumeFilledToday.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET reverseLegSettlDate == ReadBytes(triggerPrice.rest, 4) IN IF ~reverseLegSettlDate.ok THEN Fail ELSE
    LET entryDateTime == ReadBytes(reverseLegSettlDate.rest, 4) IN IF ~entryDateTime.ok THEN Fail ELSE
    LET minFillAon == ReadBytes(entryDateTime.rest, 4) IN IF ~minFillAon.ok THEN Fail ELSE
    LET lastModified == ReadBytes(minFillAon.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET traderId == ReadBytes(branchId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(traderId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET oeRemarks == ReadBytes(brokerId.rest, 21) IN IF ~oeRemarks.ok THEN Fail ELSE
    LET transactionId == ReadBytes(oeRemarks.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET settlor == ReadBytes(transactionId.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClient == ReadBytes(settlor.rest, 2) IN IF ~proClient.ok THEN Fail ELSE
    LET settlementPeriod == ReadBytes(proClient.rest, 2) IN IF ~settlementPeriod.ok THEN Fail ELSE
    LET nnfField == ReadBytes(settlementPeriod.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET execTimeStamp == ReadBytes(nnfField.rest, 8) IN IF ~execTimeStamp.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(execTimeStamp.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET orderType == ReadBytes(reserved2.rest, 2) IN IF ~orderType.ok THEN Fail ELSE
    Ok([ participantType       |-> participantType.value,
         reserved1             |-> reserved1.value,
         competitorPeriod      |-> competitorPeriod.value,
         solicitorPeriod       |-> solicitorPeriod.value,
         modCxlBy              |-> modCxlBy.value,
         filler9               |-> filler9.value,
         reasonCode            |-> reasonCode.value,
         reserved4             |-> reserved4.value,
         secInfo               |-> secInfo.value,
         auctionNumber         |-> auctionNumber.value,
         opBrokerId            |-> opBrokerId.value,
         suspended             |-> suspended.value,
         orderNumber           |-> orderNumber.value,
         accountNumber         |-> accountNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVol          |-> disclosedVol.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         volumeFilledToday     |-> volumeFilledToday.value,
         price                 |-> price.value,
         triggerPrice          |-> triggerPrice.value,
         reverseLegSettlDate   |-> reverseLegSettlDate.value,
         entryDateTime         |-> entryDateTime.value,
         minFillAon            |-> minFillAon.value,
         lastModified          |-> lastModified.value,
         stOrderFlags          |-> stOrderFlags.value,
         branchId              |-> branchId.value,
         traderId              |-> traderId.value,
         brokerId              |-> brokerId.value,
         oeRemarks             |-> oeRemarks.value,
         transactionId         |-> transactionId.value,
         settlor               |-> settlor.value,
         proClient             |-> proClient.value,
         settlementPeriod      |-> settlementPeriod.value,
         nnfField              |-> nnfField.value,
         execTimeStamp         |-> execTimeStamp.value,
         reserved2             |-> reserved2.value,
         orderType             |-> orderType.value ], orderType.rest)

ZeroOrderEntryRequestMessage ==
    [ participantType       |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      competitorPeriod      |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod       |-> [i \in 1 .. 2 |-> 0],
      modCxlBy              |-> [i \in 1 .. 1 |-> 0],
      filler9               |-> [i \in 1 .. 1 |-> 0],
      reasonCode            |-> [i \in 1 .. 2 |-> 0],
      reserved4             |-> [i \in 1 .. 4 |-> 0],
      secInfo               |-> ZeroSecInfo,
      auctionNumber         |-> [i \in 1 .. 2 |-> 0],
      opBrokerId            |-> [i \in 1 .. 5 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVol          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday     |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice          |-> [i \in 1 .. 4 |-> 0],
      reverseLegSettlDate   |-> [i \in 1 .. 4 |-> 0],
      entryDateTime         |-> [i \in 1 .. 4 |-> 0],
      minFillAon            |-> [i \in 1 .. 4 |-> 0],
      lastModified          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      branchId              |-> [i \in 1 .. 2 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      oeRemarks             |-> [i \in 1 .. 21 |-> 0],
      transactionId         |-> [i \in 1 .. 4 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      proClient             |-> [i \in 1 .. 2 |-> 0],
      settlementPeriod      |-> [i \in 1 .. 2 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      execTimeStamp         |-> [i \in 1 .. 8 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      orderType             |-> [i \in 1 .. 2 |-> 0] ]

(* Order Entry Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderEntryRequestMessage ==
    { ZeroOrderEntryRequestMessage }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.modCxlBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.filler9 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.secInfo = one] : one \in CheckedSecInfo }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.auctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.opBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.disclosedVol = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.reverseLegSettlDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.minFillAon = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.oeRemarks = one] : one \in Sample(21) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.proClient = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.settlementPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.execTimeStamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.orderType = one] : one \in Sample(2) }

(***************************************************************************)
(* Sec Info: 12 bytes                                                      *)
(***************************************************************************)

SecInfo2 ==
    [ symbol : Sample(10),
      series : Sample(2) ]

EncodeSecInfo2(message) ==
    message.symbol
        \o message.series

DecodeSecInfo2(bytes) ==
    LET symbol == ReadBytes(bytes, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET series == ReadBytes(symbol.rest, 2) IN IF ~series.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value,
         series |-> series.value ], series.rest)

ZeroSecInfo2 ==
    [ symbol |-> [i \in 1 .. 10 |-> 0],
      series |-> [i \in 1 .. 2 |-> 0] ]

(* Sec Info at zero, then each field in turn at the values it is checked at *)
CheckedSecInfo2 ==
    { ZeroSecInfo2 }
        \cup { [ZeroSecInfo2 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroSecInfo2 EXCEPT !.series = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Modification Request Message: 174 bytes                           *)
(***************************************************************************)

OrderModificationRequestMessage ==
    [ participantType       : Sample(1),
      reserved1             : Sample(1),
      competitorPeriod      : Sample(2),
      solicitorPeriod       : Sample(2),
      modCxlBy              : Sample(1),
      filler9               : Sample(1),
      reasonCode            : Sample(2),
      reserved4             : Sample(4),
      secInfo               : SecInfo2,
      auctionNumber         : Sample(2),
      opBrokerId            : Sample(5),
      suspended             : Sample(1),
      orderNumber           : Sample(8),
      accountNumber         : Sample(10),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVol          : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      volumeFilledToday     : Sample(4),
      price                 : Sample(4),
      triggerPrice          : Sample(4),
      reverseLegSettlDate   : Sample(4),
      entryDateTime         : Sample(4),
      minFillAon            : Sample(4),
      lastModified          : Sample(4),
      stOrderFlags          : Sample(2),
      branchId              : Sample(2),
      traderId              : Sample(4),
      brokerId              : Sample(5),
      oeRemarks             : Sample(21),
      transactionId         : Sample(4),
      settlor               : Sample(12),
      proClient             : Sample(2),
      settlementPeriod      : Sample(2),
      nnfField              : Sample(8),
      execTimeStamp         : Sample(8),
      reserved2             : Sample(2),
      orderType             : Sample(2) ]

EncodeOrderModificationRequestMessage(message) ==
    message.participantType
        \o message.reserved1
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.modCxlBy
        \o message.filler9
        \o message.reasonCode
        \o message.reserved4
        \o EncodeSecInfo2(message.secInfo)
        \o message.auctionNumber
        \o message.opBrokerId
        \o message.suspended
        \o message.orderNumber
        \o message.accountNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVol
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.volumeFilledToday
        \o message.price
        \o message.triggerPrice
        \o message.reverseLegSettlDate
        \o message.entryDateTime
        \o message.minFillAon
        \o message.lastModified
        \o message.stOrderFlags
        \o message.branchId
        \o message.traderId
        \o message.brokerId
        \o message.oeRemarks
        \o message.transactionId
        \o message.settlor
        \o message.proClient
        \o message.settlementPeriod
        \o message.nnfField
        \o message.execTimeStamp
        \o message.reserved2
        \o message.orderType

DecodeOrderModificationRequestMessage(bytes) ==
    LET participantType == ReadBytes(bytes, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(participantType.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET competitorPeriod == ReadBytes(reserved1.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET modCxlBy == ReadBytes(solicitorPeriod.rest, 1) IN IF ~modCxlBy.ok THEN Fail ELSE
    LET filler9 == ReadBytes(modCxlBy.rest, 1) IN IF ~filler9.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(filler9.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reasonCode.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET secInfo == DecodeSecInfo2(reserved4.rest) IN IF ~secInfo.ok THEN Fail ELSE
    LET auctionNumber == ReadBytes(secInfo.rest, 2) IN IF ~auctionNumber.ok THEN Fail ELSE
    LET opBrokerId == ReadBytes(auctionNumber.rest, 5) IN IF ~opBrokerId.ok THEN Fail ELSE
    LET suspended == ReadBytes(opBrokerId.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(suspended.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(orderNumber.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVol == ReadBytes(buySell.rest, 4) IN IF ~disclosedVol.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVol.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET volumeFilledToday == ReadBytes(volume.rest, 4) IN IF ~volumeFilledToday.ok THEN Fail ELSE
    LET price == ReadBytes(volumeFilledToday.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET reverseLegSettlDate == ReadBytes(triggerPrice.rest, 4) IN IF ~reverseLegSettlDate.ok THEN Fail ELSE
    LET entryDateTime == ReadBytes(reverseLegSettlDate.rest, 4) IN IF ~entryDateTime.ok THEN Fail ELSE
    LET minFillAon == ReadBytes(entryDateTime.rest, 4) IN IF ~minFillAon.ok THEN Fail ELSE
    LET lastModified == ReadBytes(minFillAon.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET traderId == ReadBytes(branchId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(traderId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET oeRemarks == ReadBytes(brokerId.rest, 21) IN IF ~oeRemarks.ok THEN Fail ELSE
    LET transactionId == ReadBytes(oeRemarks.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET settlor == ReadBytes(transactionId.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClient == ReadBytes(settlor.rest, 2) IN IF ~proClient.ok THEN Fail ELSE
    LET settlementPeriod == ReadBytes(proClient.rest, 2) IN IF ~settlementPeriod.ok THEN Fail ELSE
    LET nnfField == ReadBytes(settlementPeriod.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET execTimeStamp == ReadBytes(nnfField.rest, 8) IN IF ~execTimeStamp.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(execTimeStamp.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET orderType == ReadBytes(reserved2.rest, 2) IN IF ~orderType.ok THEN Fail ELSE
    Ok([ participantType       |-> participantType.value,
         reserved1             |-> reserved1.value,
         competitorPeriod      |-> competitorPeriod.value,
         solicitorPeriod       |-> solicitorPeriod.value,
         modCxlBy              |-> modCxlBy.value,
         filler9               |-> filler9.value,
         reasonCode            |-> reasonCode.value,
         reserved4             |-> reserved4.value,
         secInfo               |-> secInfo.value,
         auctionNumber         |-> auctionNumber.value,
         opBrokerId            |-> opBrokerId.value,
         suspended             |-> suspended.value,
         orderNumber           |-> orderNumber.value,
         accountNumber         |-> accountNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVol          |-> disclosedVol.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         volumeFilledToday     |-> volumeFilledToday.value,
         price                 |-> price.value,
         triggerPrice          |-> triggerPrice.value,
         reverseLegSettlDate   |-> reverseLegSettlDate.value,
         entryDateTime         |-> entryDateTime.value,
         minFillAon            |-> minFillAon.value,
         lastModified          |-> lastModified.value,
         stOrderFlags          |-> stOrderFlags.value,
         branchId              |-> branchId.value,
         traderId              |-> traderId.value,
         brokerId              |-> brokerId.value,
         oeRemarks             |-> oeRemarks.value,
         transactionId         |-> transactionId.value,
         settlor               |-> settlor.value,
         proClient             |-> proClient.value,
         settlementPeriod      |-> settlementPeriod.value,
         nnfField              |-> nnfField.value,
         execTimeStamp         |-> execTimeStamp.value,
         reserved2             |-> reserved2.value,
         orderType             |-> orderType.value ], orderType.rest)

ZeroOrderModificationRequestMessage ==
    [ participantType       |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      competitorPeriod      |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod       |-> [i \in 1 .. 2 |-> 0],
      modCxlBy              |-> [i \in 1 .. 1 |-> 0],
      filler9               |-> [i \in 1 .. 1 |-> 0],
      reasonCode            |-> [i \in 1 .. 2 |-> 0],
      reserved4             |-> [i \in 1 .. 4 |-> 0],
      secInfo               |-> ZeroSecInfo2,
      auctionNumber         |-> [i \in 1 .. 2 |-> 0],
      opBrokerId            |-> [i \in 1 .. 5 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVol          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday     |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice          |-> [i \in 1 .. 4 |-> 0],
      reverseLegSettlDate   |-> [i \in 1 .. 4 |-> 0],
      entryDateTime         |-> [i \in 1 .. 4 |-> 0],
      minFillAon            |-> [i \in 1 .. 4 |-> 0],
      lastModified          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      branchId              |-> [i \in 1 .. 2 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      oeRemarks             |-> [i \in 1 .. 21 |-> 0],
      transactionId         |-> [i \in 1 .. 4 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      proClient             |-> [i \in 1 .. 2 |-> 0],
      settlementPeriod      |-> [i \in 1 .. 2 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      execTimeStamp         |-> [i \in 1 .. 8 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      orderType             |-> [i \in 1 .. 2 |-> 0] ]

(* Order Modification Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModificationRequestMessage ==
    { ZeroOrderModificationRequestMessage }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.modCxlBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.filler9 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.secInfo = one] : one \in CheckedSecInfo2 }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.auctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.opBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.disclosedVol = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.reverseLegSettlDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.minFillAon = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.oeRemarks = one] : one \in Sample(21) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.proClient = one] : one \in Sample(2) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.settlementPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.execTimeStamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.orderType = one] : one \in Sample(2) }

(***************************************************************************)
(* Sec Info: 12 bytes                                                      *)
(***************************************************************************)

SecInfo3 ==
    [ symbol : Sample(10),
      series : Sample(2) ]

EncodeSecInfo3(message) ==
    message.symbol
        \o message.series

DecodeSecInfo3(bytes) ==
    LET symbol == ReadBytes(bytes, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET series == ReadBytes(symbol.rest, 2) IN IF ~series.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value,
         series |-> series.value ], series.rest)

ZeroSecInfo3 ==
    [ symbol |-> [i \in 1 .. 10 |-> 0],
      series |-> [i \in 1 .. 2 |-> 0] ]

(* Sec Info at zero, then each field in turn at the values it is checked at *)
CheckedSecInfo3 ==
    { ZeroSecInfo3 }
        \cup { [ZeroSecInfo3 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroSecInfo3 EXCEPT !.series = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Cancellation Request Message: 174 bytes                           *)
(***************************************************************************)

OrderCancellationRequestMessage ==
    [ participantType       : Sample(1),
      reserved1             : Sample(1),
      competitorPeriod      : Sample(2),
      solicitorPeriod       : Sample(2),
      modCxlBy              : Sample(1),
      filler9               : Sample(1),
      reasonCode            : Sample(2),
      reserved4             : Sample(4),
      secInfo               : SecInfo3,
      auctionNumber         : Sample(2),
      opBrokerId            : Sample(5),
      suspended             : Sample(1),
      orderNumber           : Sample(8),
      accountNumber         : Sample(10),
      bookType              : Sample(2),
      buySell               : Sample(2),
      disclosedVol          : Sample(4),
      disclosedVolRemaining : Sample(4),
      totalVolRemaining     : Sample(4),
      volume                : Sample(4),
      volumeFilledToday     : Sample(4),
      price                 : Sample(4),
      triggerPrice          : Sample(4),
      reverseLegSettlDate   : Sample(4),
      entryDateTime         : Sample(4),
      minFillAon            : Sample(4),
      lastModified          : Sample(4),
      stOrderFlags          : Sample(2),
      branchId              : Sample(2),
      traderId              : Sample(4),
      brokerId              : Sample(5),
      oeRemarks             : Sample(21),
      transactionId         : Sample(4),
      settlor               : Sample(12),
      proClient             : Sample(2),
      settlementPeriod      : Sample(2),
      nnfField              : Sample(8),
      execTimeStamp         : Sample(8),
      reserved2             : Sample(2),
      orderType             : Sample(2) ]

EncodeOrderCancellationRequestMessage(message) ==
    message.participantType
        \o message.reserved1
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.modCxlBy
        \o message.filler9
        \o message.reasonCode
        \o message.reserved4
        \o EncodeSecInfo3(message.secInfo)
        \o message.auctionNumber
        \o message.opBrokerId
        \o message.suspended
        \o message.orderNumber
        \o message.accountNumber
        \o message.bookType
        \o message.buySell
        \o message.disclosedVol
        \o message.disclosedVolRemaining
        \o message.totalVolRemaining
        \o message.volume
        \o message.volumeFilledToday
        \o message.price
        \o message.triggerPrice
        \o message.reverseLegSettlDate
        \o message.entryDateTime
        \o message.minFillAon
        \o message.lastModified
        \o message.stOrderFlags
        \o message.branchId
        \o message.traderId
        \o message.brokerId
        \o message.oeRemarks
        \o message.transactionId
        \o message.settlor
        \o message.proClient
        \o message.settlementPeriod
        \o message.nnfField
        \o message.execTimeStamp
        \o message.reserved2
        \o message.orderType

DecodeOrderCancellationRequestMessage(bytes) ==
    LET participantType == ReadBytes(bytes, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(participantType.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET competitorPeriod == ReadBytes(reserved1.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET modCxlBy == ReadBytes(solicitorPeriod.rest, 1) IN IF ~modCxlBy.ok THEN Fail ELSE
    LET filler9 == ReadBytes(modCxlBy.rest, 1) IN IF ~filler9.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(filler9.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reasonCode.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET secInfo == DecodeSecInfo3(reserved4.rest) IN IF ~secInfo.ok THEN Fail ELSE
    LET auctionNumber == ReadBytes(secInfo.rest, 2) IN IF ~auctionNumber.ok THEN Fail ELSE
    LET opBrokerId == ReadBytes(auctionNumber.rest, 5) IN IF ~opBrokerId.ok THEN Fail ELSE
    LET suspended == ReadBytes(opBrokerId.rest, 1) IN IF ~suspended.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(suspended.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(orderNumber.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySell == ReadBytes(bookType.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET disclosedVol == ReadBytes(buySell.rest, 4) IN IF ~disclosedVol.ok THEN Fail ELSE
    LET disclosedVolRemaining == ReadBytes(disclosedVol.rest, 4) IN IF ~disclosedVolRemaining.ok THEN Fail ELSE
    LET totalVolRemaining == ReadBytes(disclosedVolRemaining.rest, 4) IN IF ~totalVolRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET volumeFilledToday == ReadBytes(volume.rest, 4) IN IF ~volumeFilledToday.ok THEN Fail ELSE
    LET price == ReadBytes(volumeFilledToday.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET reverseLegSettlDate == ReadBytes(triggerPrice.rest, 4) IN IF ~reverseLegSettlDate.ok THEN Fail ELSE
    LET entryDateTime == ReadBytes(reverseLegSettlDate.rest, 4) IN IF ~entryDateTime.ok THEN Fail ELSE
    LET minFillAon == ReadBytes(entryDateTime.rest, 4) IN IF ~minFillAon.ok THEN Fail ELSE
    LET lastModified == ReadBytes(minFillAon.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET traderId == ReadBytes(branchId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(traderId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET oeRemarks == ReadBytes(brokerId.rest, 21) IN IF ~oeRemarks.ok THEN Fail ELSE
    LET transactionId == ReadBytes(oeRemarks.rest, 4) IN IF ~transactionId.ok THEN Fail ELSE
    LET settlor == ReadBytes(transactionId.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClient == ReadBytes(settlor.rest, 2) IN IF ~proClient.ok THEN Fail ELSE
    LET settlementPeriod == ReadBytes(proClient.rest, 2) IN IF ~settlementPeriod.ok THEN Fail ELSE
    LET nnfField == ReadBytes(settlementPeriod.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET execTimeStamp == ReadBytes(nnfField.rest, 8) IN IF ~execTimeStamp.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(execTimeStamp.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET orderType == ReadBytes(reserved2.rest, 2) IN IF ~orderType.ok THEN Fail ELSE
    Ok([ participantType       |-> participantType.value,
         reserved1             |-> reserved1.value,
         competitorPeriod      |-> competitorPeriod.value,
         solicitorPeriod       |-> solicitorPeriod.value,
         modCxlBy              |-> modCxlBy.value,
         filler9               |-> filler9.value,
         reasonCode            |-> reasonCode.value,
         reserved4             |-> reserved4.value,
         secInfo               |-> secInfo.value,
         auctionNumber         |-> auctionNumber.value,
         opBrokerId            |-> opBrokerId.value,
         suspended             |-> suspended.value,
         orderNumber           |-> orderNumber.value,
         accountNumber         |-> accountNumber.value,
         bookType              |-> bookType.value,
         buySell               |-> buySell.value,
         disclosedVol          |-> disclosedVol.value,
         disclosedVolRemaining |-> disclosedVolRemaining.value,
         totalVolRemaining     |-> totalVolRemaining.value,
         volume                |-> volume.value,
         volumeFilledToday     |-> volumeFilledToday.value,
         price                 |-> price.value,
         triggerPrice          |-> triggerPrice.value,
         reverseLegSettlDate   |-> reverseLegSettlDate.value,
         entryDateTime         |-> entryDateTime.value,
         minFillAon            |-> minFillAon.value,
         lastModified          |-> lastModified.value,
         stOrderFlags          |-> stOrderFlags.value,
         branchId              |-> branchId.value,
         traderId              |-> traderId.value,
         brokerId              |-> brokerId.value,
         oeRemarks             |-> oeRemarks.value,
         transactionId         |-> transactionId.value,
         settlor               |-> settlor.value,
         proClient             |-> proClient.value,
         settlementPeriod      |-> settlementPeriod.value,
         nnfField              |-> nnfField.value,
         execTimeStamp         |-> execTimeStamp.value,
         reserved2             |-> reserved2.value,
         orderType             |-> orderType.value ], orderType.rest)

ZeroOrderCancellationRequestMessage ==
    [ participantType       |-> [i \in 1 .. 1 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      competitorPeriod      |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod       |-> [i \in 1 .. 2 |-> 0],
      modCxlBy              |-> [i \in 1 .. 1 |-> 0],
      filler9               |-> [i \in 1 .. 1 |-> 0],
      reasonCode            |-> [i \in 1 .. 2 |-> 0],
      reserved4             |-> [i \in 1 .. 4 |-> 0],
      secInfo               |-> ZeroSecInfo3,
      auctionNumber         |-> [i \in 1 .. 2 |-> 0],
      opBrokerId            |-> [i \in 1 .. 5 |-> 0],
      suspended             |-> [i \in 1 .. 1 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      accountNumber         |-> [i \in 1 .. 10 |-> 0],
      bookType              |-> [i \in 1 .. 2 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      disclosedVol          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday     |-> [i \in 1 .. 4 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice          |-> [i \in 1 .. 4 |-> 0],
      reverseLegSettlDate   |-> [i \in 1 .. 4 |-> 0],
      entryDateTime         |-> [i \in 1 .. 4 |-> 0],
      minFillAon            |-> [i \in 1 .. 4 |-> 0],
      lastModified          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      branchId              |-> [i \in 1 .. 2 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      oeRemarks             |-> [i \in 1 .. 21 |-> 0],
      transactionId         |-> [i \in 1 .. 4 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      proClient             |-> [i \in 1 .. 2 |-> 0],
      settlementPeriod      |-> [i \in 1 .. 2 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      execTimeStamp         |-> [i \in 1 .. 8 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      orderType             |-> [i \in 1 .. 2 |-> 0] ]

(* Order Cancellation Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancellationRequestMessage ==
    { ZeroOrderCancellationRequestMessage }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.modCxlBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.filler9 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.secInfo = one] : one \in CheckedSecInfo3 }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.auctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.opBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.disclosedVol = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.reverseLegSettlDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.minFillAon = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.oeRemarks = one] : one \in Sample(21) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.transactionId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.proClient = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.settlementPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.execTimeStamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.orderType = one] : one \in Sample(2) }

(***************************************************************************)
(* Sec Info: 12 bytes                                                      *)
(***************************************************************************)

SecInfo4 ==
    [ symbol : Sample(10),
      series : Sample(2) ]

EncodeSecInfo4(message) ==
    message.symbol
        \o message.series

DecodeSecInfo4(bytes) ==
    LET symbol == ReadBytes(bytes, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET series == ReadBytes(symbol.rest, 2) IN IF ~series.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value,
         series |-> series.value ], series.rest)

ZeroSecInfo4 ==
    [ symbol |-> [i \in 1 .. 10 |-> 0],
      series |-> [i \in 1 .. 2 |-> 0] ]

(* Sec Info at zero, then each field in turn at the values it is checked at *)
CheckedSecInfo4 ==
    { ZeroSecInfo4 }
        \cup { [ZeroSecInfo4 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroSecInfo4 EXCEPT !.series = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Cancellation Request Message: 74 bytes                            *)
(***************************************************************************)

TradeCancellationRequestMessage ==
    [ secInfo             : SecInfo4,
      reverseLegSettlDate : Sample(4),
      lFillNumber         : Sample(4),
      lFillQty            : Sample(4),
      lFillPrice          : Sample(4),
      iMktType            : Sample(2),
      lNewVolume          : Sample(4),
      buyParticipantId    : Sample(12),
      sellParticipantId   : Sample(12),
      buyBrokerId         : Sample(5),
      sellBrokerId        : Sample(5),
      traderId            : Sample(4),
      requestedBy         : Sample(2) ]

EncodeTradeCancellationRequestMessage(message) ==
    EncodeSecInfo4(message.secInfo)
        \o message.reverseLegSettlDate
        \o message.lFillNumber
        \o message.lFillQty
        \o message.lFillPrice
        \o message.iMktType
        \o message.lNewVolume
        \o message.buyParticipantId
        \o message.sellParticipantId
        \o message.buyBrokerId
        \o message.sellBrokerId
        \o message.traderId
        \o message.requestedBy

DecodeTradeCancellationRequestMessage(bytes) ==
    LET secInfo == DecodeSecInfo4(bytes) IN IF ~secInfo.ok THEN Fail ELSE
    LET reverseLegSettlDate == ReadBytes(secInfo.rest, 4) IN IF ~reverseLegSettlDate.ok THEN Fail ELSE
    LET lFillNumber == ReadBytes(reverseLegSettlDate.rest, 4) IN IF ~lFillNumber.ok THEN Fail ELSE
    LET lFillQty == ReadBytes(lFillNumber.rest, 4) IN IF ~lFillQty.ok THEN Fail ELSE
    LET lFillPrice == ReadBytes(lFillQty.rest, 4) IN IF ~lFillPrice.ok THEN Fail ELSE
    LET iMktType == ReadBytes(lFillPrice.rest, 2) IN IF ~iMktType.ok THEN Fail ELSE
    LET lNewVolume == ReadBytes(iMktType.rest, 4) IN IF ~lNewVolume.ok THEN Fail ELSE
    LET buyParticipantId == ReadBytes(lNewVolume.rest, 12) IN IF ~buyParticipantId.ok THEN Fail ELSE
    LET sellParticipantId == ReadBytes(buyParticipantId.rest, 12) IN IF ~sellParticipantId.ok THEN Fail ELSE
    LET buyBrokerId == ReadBytes(sellParticipantId.rest, 5) IN IF ~buyBrokerId.ok THEN Fail ELSE
    LET sellBrokerId == ReadBytes(buyBrokerId.rest, 5) IN IF ~sellBrokerId.ok THEN Fail ELSE
    LET traderId == ReadBytes(sellBrokerId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET requestedBy == ReadBytes(traderId.rest, 2) IN IF ~requestedBy.ok THEN Fail ELSE
    Ok([ secInfo             |-> secInfo.value,
         reverseLegSettlDate |-> reverseLegSettlDate.value,
         lFillNumber         |-> lFillNumber.value,
         lFillQty            |-> lFillQty.value,
         lFillPrice          |-> lFillPrice.value,
         iMktType            |-> iMktType.value,
         lNewVolume          |-> lNewVolume.value,
         buyParticipantId    |-> buyParticipantId.value,
         sellParticipantId   |-> sellParticipantId.value,
         buyBrokerId         |-> buyBrokerId.value,
         sellBrokerId        |-> sellBrokerId.value,
         traderId            |-> traderId.value,
         requestedBy         |-> requestedBy.value ], requestedBy.rest)

ZeroTradeCancellationRequestMessage ==
    [ secInfo             |-> ZeroSecInfo4,
      reverseLegSettlDate |-> [i \in 1 .. 4 |-> 0],
      lFillNumber         |-> [i \in 1 .. 4 |-> 0],
      lFillQty            |-> [i \in 1 .. 4 |-> 0],
      lFillPrice          |-> [i \in 1 .. 4 |-> 0],
      iMktType            |-> [i \in 1 .. 2 |-> 0],
      lNewVolume          |-> [i \in 1 .. 4 |-> 0],
      buyParticipantId    |-> [i \in 1 .. 12 |-> 0],
      sellParticipantId   |-> [i \in 1 .. 12 |-> 0],
      buyBrokerId         |-> [i \in 1 .. 5 |-> 0],
      sellBrokerId        |-> [i \in 1 .. 5 |-> 0],
      traderId            |-> [i \in 1 .. 4 |-> 0],
      requestedBy         |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Cancellation Request Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancellationRequestMessage ==
    { ZeroTradeCancellationRequestMessage }
        \cup { [ZeroTradeCancellationRequestMessage EXCEPT !.secInfo = one] : one \in CheckedSecInfo4 }
        \cup { [ZeroTradeCancellationRequestMessage EXCEPT !.reverseLegSettlDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationRequestMessage EXCEPT !.lFillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationRequestMessage EXCEPT !.lFillQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationRequestMessage EXCEPT !.lFillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationRequestMessage EXCEPT !.iMktType = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancellationRequestMessage EXCEPT !.lNewVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationRequestMessage EXCEPT !.buyParticipantId = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancellationRequestMessage EXCEPT !.sellParticipantId = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancellationRequestMessage EXCEPT !.buyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeCancellationRequestMessage EXCEPT !.sellBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeCancellationRequestMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancellationRequestMessage EXCEPT !.requestedBy = one] : one \in Sample(2) }

(***************************************************************************)
(* Sec Info: 12 bytes                                                      *)
(***************************************************************************)

SecInfo5 ==
    [ symbol : Sample(10),
      series : Sample(2) ]

EncodeSecInfo5(message) ==
    message.symbol
        \o message.series

DecodeSecInfo5(bytes) ==
    LET symbol == ReadBytes(bytes, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET series == ReadBytes(symbol.rest, 2) IN IF ~series.ok THEN Fail ELSE
    Ok([ symbol |-> symbol.value,
         series |-> series.value ], series.rest)

ZeroSecInfo5 ==
    [ symbol |-> [i \in 1 .. 10 |-> 0],
      series |-> [i \in 1 .. 2 |-> 0] ]

(* Sec Info at zero, then each field in turn at the values it is checked at *)
CheckedSecInfo5 ==
    { ZeroSecInfo5 }
        \cup { [ZeroSecInfo5 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroSecInfo5 EXCEPT !.series = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Modification Request Message: 74 bytes                            *)
(***************************************************************************)

TradeModificationRequestMessage ==
    [ secInfo             : SecInfo5,
      reverseLegSettlDate : Sample(4),
      lFillNumber         : Sample(4),
      lFillQty            : Sample(4),
      lFillPrice          : Sample(4),
      iMktType            : Sample(2),
      lNewVolume          : Sample(4),
      buyParticipantId    : Sample(12),
      sellParticipantId   : Sample(12),
      buyBrokerId         : Sample(5),
      sellBrokerId        : Sample(5),
      traderId            : Sample(4),
      requestedBy         : Sample(2) ]

EncodeTradeModificationRequestMessage(message) ==
    EncodeSecInfo5(message.secInfo)
        \o message.reverseLegSettlDate
        \o message.lFillNumber
        \o message.lFillQty
        \o message.lFillPrice
        \o message.iMktType
        \o message.lNewVolume
        \o message.buyParticipantId
        \o message.sellParticipantId
        \o message.buyBrokerId
        \o message.sellBrokerId
        \o message.traderId
        \o message.requestedBy

DecodeTradeModificationRequestMessage(bytes) ==
    LET secInfo == DecodeSecInfo5(bytes) IN IF ~secInfo.ok THEN Fail ELSE
    LET reverseLegSettlDate == ReadBytes(secInfo.rest, 4) IN IF ~reverseLegSettlDate.ok THEN Fail ELSE
    LET lFillNumber == ReadBytes(reverseLegSettlDate.rest, 4) IN IF ~lFillNumber.ok THEN Fail ELSE
    LET lFillQty == ReadBytes(lFillNumber.rest, 4) IN IF ~lFillQty.ok THEN Fail ELSE
    LET lFillPrice == ReadBytes(lFillQty.rest, 4) IN IF ~lFillPrice.ok THEN Fail ELSE
    LET iMktType == ReadBytes(lFillPrice.rest, 2) IN IF ~iMktType.ok THEN Fail ELSE
    LET lNewVolume == ReadBytes(iMktType.rest, 4) IN IF ~lNewVolume.ok THEN Fail ELSE
    LET buyParticipantId == ReadBytes(lNewVolume.rest, 12) IN IF ~buyParticipantId.ok THEN Fail ELSE
    LET sellParticipantId == ReadBytes(buyParticipantId.rest, 12) IN IF ~sellParticipantId.ok THEN Fail ELSE
    LET buyBrokerId == ReadBytes(sellParticipantId.rest, 5) IN IF ~buyBrokerId.ok THEN Fail ELSE
    LET sellBrokerId == ReadBytes(buyBrokerId.rest, 5) IN IF ~sellBrokerId.ok THEN Fail ELSE
    LET traderId == ReadBytes(sellBrokerId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET requestedBy == ReadBytes(traderId.rest, 2) IN IF ~requestedBy.ok THEN Fail ELSE
    Ok([ secInfo             |-> secInfo.value,
         reverseLegSettlDate |-> reverseLegSettlDate.value,
         lFillNumber         |-> lFillNumber.value,
         lFillQty            |-> lFillQty.value,
         lFillPrice          |-> lFillPrice.value,
         iMktType            |-> iMktType.value,
         lNewVolume          |-> lNewVolume.value,
         buyParticipantId    |-> buyParticipantId.value,
         sellParticipantId   |-> sellParticipantId.value,
         buyBrokerId         |-> buyBrokerId.value,
         sellBrokerId        |-> sellBrokerId.value,
         traderId            |-> traderId.value,
         requestedBy         |-> requestedBy.value ], requestedBy.rest)

ZeroTradeModificationRequestMessage ==
    [ secInfo             |-> ZeroSecInfo5,
      reverseLegSettlDate |-> [i \in 1 .. 4 |-> 0],
      lFillNumber         |-> [i \in 1 .. 4 |-> 0],
      lFillQty            |-> [i \in 1 .. 4 |-> 0],
      lFillPrice          |-> [i \in 1 .. 4 |-> 0],
      iMktType            |-> [i \in 1 .. 2 |-> 0],
      lNewVolume          |-> [i \in 1 .. 4 |-> 0],
      buyParticipantId    |-> [i \in 1 .. 12 |-> 0],
      sellParticipantId   |-> [i \in 1 .. 12 |-> 0],
      buyBrokerId         |-> [i \in 1 .. 5 |-> 0],
      sellBrokerId        |-> [i \in 1 .. 5 |-> 0],
      traderId            |-> [i \in 1 .. 4 |-> 0],
      requestedBy         |-> [i \in 1 .. 2 |-> 0] ]

(* Trade Modification Request Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeModificationRequestMessage ==
    { ZeroTradeModificationRequestMessage }
        \cup { [ZeroTradeModificationRequestMessage EXCEPT !.secInfo = one] : one \in CheckedSecInfo5 }
        \cup { [ZeroTradeModificationRequestMessage EXCEPT !.reverseLegSettlDate = one] : one \in Sample(4) }
        \cup { [ZeroTradeModificationRequestMessage EXCEPT !.lFillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeModificationRequestMessage EXCEPT !.lFillQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeModificationRequestMessage EXCEPT !.lFillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeModificationRequestMessage EXCEPT !.iMktType = one] : one \in Sample(2) }
        \cup { [ZeroTradeModificationRequestMessage EXCEPT !.lNewVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeModificationRequestMessage EXCEPT !.buyParticipantId = one] : one \in Sample(12) }
        \cup { [ZeroTradeModificationRequestMessage EXCEPT !.sellParticipantId = one] : one \in Sample(12) }
        \cup { [ZeroTradeModificationRequestMessage EXCEPT !.buyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeModificationRequestMessage EXCEPT !.sellBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeModificationRequestMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeModificationRequestMessage EXCEPT !.requestedBy = one] : one \in Sample(2) }

(***************************************************************************)
(* Gateway Router Request Message: 8 bytes                                 *)
(***************************************************************************)

GatewayRouterRequestMessage ==
    [ boxId    : Sample(2),
      brokerId : Sample(5),
      filler   : Sample(1) ]

EncodeGatewayRouterRequestMessage(message) ==
    message.boxId
        \o message.brokerId
        \o message.filler

DecodeGatewayRouterRequestMessage(bytes) ==
    LET boxId == ReadBytes(bytes, 2) IN IF ~boxId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(boxId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET filler == ReadBytes(brokerId.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    Ok([ boxId    |-> boxId.value,
         brokerId |-> brokerId.value,
         filler   |-> filler.value ], filler.rest)

ZeroGatewayRouterRequestMessage ==
    [ boxId    |-> [i \in 1 .. 2 |-> 0],
      brokerId |-> [i \in 1 .. 5 |-> 0],
      filler   |-> [i \in 1 .. 1 |-> 0] ]

(* Gateway Router Request Message at zero, then each field in turn at the values it is checked at *)
CheckedGatewayRouterRequestMessage ==
    { ZeroGatewayRouterRequestMessage }
        \cup { [ZeroGatewayRouterRequestMessage EXCEPT !.boxId = one] : one \in Sample(2) }
        \cup { [ZeroGatewayRouterRequestMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroGatewayRouterRequestMessage EXCEPT !.filler = one] : one \in Sample(1) }

(***************************************************************************)
(* Secure Box Registration Request Message: 2 bytes                        *)
(***************************************************************************)

SecureBoxRegistrationRequestMessage ==
    [ boxId : Sample(2) ]

EncodeSecureBoxRegistrationRequestMessage(message) ==
    message.boxId

DecodeSecureBoxRegistrationRequestMessage(bytes) ==
    LET boxId == ReadBytes(bytes, 2) IN IF ~boxId.ok THEN Fail ELSE
    Ok([ boxId |-> boxId.value ], boxId.rest)

ZeroSecureBoxRegistrationRequestMessage ==
    [ boxId |-> [i \in 1 .. 2 |-> 0] ]

(* Secure Box Registration Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSecureBoxRegistrationRequestMessage ==
    { ZeroSecureBoxRegistrationRequestMessage }
        \cup { [ZeroSecureBoxRegistrationRequestMessage EXCEPT !.boxId = one] : one \in Sample(2) }

(***************************************************************************)
(* Box Sign On Request Message: 20 bytes                                   *)
(***************************************************************************)

BoxSignOnRequestMessage ==
    [ boxId      : Sample(2),
      brokerId   : Sample(5),
      reserved5  : Sample(5),
      sessionKey : Sample(8) ]

EncodeBoxSignOnRequestMessage(message) ==
    message.boxId
        \o message.brokerId
        \o message.reserved5
        \o message.sessionKey

DecodeBoxSignOnRequestMessage(bytes) ==
    LET boxId == ReadBytes(bytes, 2) IN IF ~boxId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(boxId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved5 == ReadBytes(brokerId.rest, 5) IN IF ~reserved5.ok THEN Fail ELSE
    LET sessionKey == ReadBytes(reserved5.rest, 8) IN IF ~sessionKey.ok THEN Fail ELSE
    Ok([ boxId      |-> boxId.value,
         brokerId   |-> brokerId.value,
         reserved5  |-> reserved5.value,
         sessionKey |-> sessionKey.value ], sessionKey.rest)

ZeroBoxSignOnRequestMessage ==
    [ boxId      |-> [i \in 1 .. 2 |-> 0],
      brokerId   |-> [i \in 1 .. 5 |-> 0],
      reserved5  |-> [i \in 1 .. 5 |-> 0],
      sessionKey |-> [i \in 1 .. 8 |-> 0] ]

(* Box Sign On Request Message at zero, then each field in turn at the values it is checked at *)
CheckedBoxSignOnRequestMessage ==
    { ZeroBoxSignOnRequestMessage }
        \cup { [ZeroBoxSignOnRequestMessage EXCEPT !.boxId = one] : one \in Sample(2) }
        \cup { [ZeroBoxSignOnRequestMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroBoxSignOnRequestMessage EXCEPT !.reserved5 = one] : one \in Sample(5) }
        \cup { [ZeroBoxSignOnRequestMessage EXCEPT !.sessionKey = one] : one \in Sample(8) }

(***************************************************************************)
(* Client Message Payload, selected by Transaction Code                    *)
(***************************************************************************)

LogonRequestMessageCode == 2300  \* 0x8fc
SystemInformationRequestMessageCode == 1600  \* 0x640
UpdateLocalDatabaseRequestMessageCode == 7300  \* 0x1c84
MessageDownloadRequestMessageCode == 7000  \* 0x1b58
LogoffRequestMessageCode == 2320  \* 0x910
OrderEntryRequestMessageCode == 2000  \* 0x7d0
OrderModificationRequestMessageCode == 2040  \* 0x7f8
OrderCancellationRequestMessageCode == 2070  \* 0x816
TradeCancellationRequestMessageCode == 5440  \* 0x1540
TradeModificationRequestMessageCode == 5445  \* 0x1545
GatewayRouterRequestMessageCode == 2400  \* 0x960
SecureBoxRegistrationRequestMessageCode == 23008  \* 0x59e0
BoxSignOnRequestMessageCode == 23000  \* 0x59d8
HeartbeatMessageCode == 23506  \* 0x5bd2

ClientMessagePayload ==
    [ tag : {LogonRequestMessageCode}, body : LogonRequestMessage ]
        \cup [ tag : {SystemInformationRequestMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {UpdateLocalDatabaseRequestMessageCode}, body : UpdateLocalDatabaseRequestMessage ]
        \cup [ tag : {MessageDownloadRequestMessageCode}, body : MessageDownloadRequestMessage ]
        \cup [ tag : {LogoffRequestMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {OrderEntryRequestMessageCode}, body : OrderEntryRequestMessage ]
        \cup [ tag : {OrderModificationRequestMessageCode}, body : OrderModificationRequestMessage ]
        \cup [ tag : {OrderCancellationRequestMessageCode}, body : OrderCancellationRequestMessage ]
        \cup [ tag : {TradeCancellationRequestMessageCode}, body : TradeCancellationRequestMessage ]
        \cup [ tag : {TradeModificationRequestMessageCode}, body : TradeModificationRequestMessage ]
        \cup [ tag : {GatewayRouterRequestMessageCode}, body : GatewayRouterRequestMessage ]
        \cup [ tag : {SecureBoxRegistrationRequestMessageCode}, body : SecureBoxRegistrationRequestMessage ]
        \cup [ tag : {BoxSignOnRequestMessageCode}, body : BoxSignOnRequestMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]

EncodeClientMessagePayload(message) ==
    CASE message.tag = LogonRequestMessageCode -> EncodeLogonRequestMessage(message.body)
      [] message.tag = SystemInformationRequestMessageCode -> << >>
      [] message.tag = UpdateLocalDatabaseRequestMessageCode -> EncodeUpdateLocalDatabaseRequestMessage(message.body)
      [] message.tag = MessageDownloadRequestMessageCode -> EncodeMessageDownloadRequestMessage(message.body)
      [] message.tag = LogoffRequestMessageCode -> << >>
      [] message.tag = OrderEntryRequestMessageCode -> EncodeOrderEntryRequestMessage(message.body)
      [] message.tag = OrderModificationRequestMessageCode -> EncodeOrderModificationRequestMessage(message.body)
      [] message.tag = OrderCancellationRequestMessageCode -> EncodeOrderCancellationRequestMessage(message.body)
      [] message.tag = TradeCancellationRequestMessageCode -> EncodeTradeCancellationRequestMessage(message.body)
      [] message.tag = TradeModificationRequestMessageCode -> EncodeTradeModificationRequestMessage(message.body)
      [] message.tag = GatewayRouterRequestMessageCode -> EncodeGatewayRouterRequestMessage(message.body)
      [] message.tag = SecureBoxRegistrationRequestMessageCode -> EncodeSecureBoxRegistrationRequestMessage(message.body)
      [] message.tag = BoxSignOnRequestMessageCode -> EncodeBoxSignOnRequestMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>

DecodeClientMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonRequestMessageCode -> DecodeLogonRequestMessage(bytes)
              [] tag = SystemInformationRequestMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = UpdateLocalDatabaseRequestMessageCode -> DecodeUpdateLocalDatabaseRequestMessage(bytes)
              [] tag = MessageDownloadRequestMessageCode -> DecodeMessageDownloadRequestMessage(bytes)
              [] tag = LogoffRequestMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = OrderEntryRequestMessageCode -> DecodeOrderEntryRequestMessage(bytes)
              [] tag = OrderModificationRequestMessageCode -> DecodeOrderModificationRequestMessage(bytes)
              [] tag = OrderCancellationRequestMessageCode -> DecodeOrderCancellationRequestMessage(bytes)
              [] tag = TradeCancellationRequestMessageCode -> DecodeTradeCancellationRequestMessage(bytes)
              [] tag = TradeModificationRequestMessageCode -> DecodeTradeModificationRequestMessage(bytes)
              [] tag = GatewayRouterRequestMessageCode -> DecodeGatewayRouterRequestMessage(bytes)
              [] tag = SecureBoxRegistrationRequestMessageCode -> DecodeSecureBoxRegistrationRequestMessage(bytes)
              [] tag = BoxSignOnRequestMessageCode -> DecodeBoxSignOnRequestMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientMessagePayload == [tag |-> LogonRequestMessageCode, body |-> ZeroLogonRequestMessage]

(* Each Client Message Payload in turn, at the values the message it names is checked at *)
CheckedClientMessagePayload ==
    { [tag |-> LogonRequestMessageCode, body |-> one] : one \in CheckedLogonRequestMessage }
        \cup { [tag |-> SystemInformationRequestMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> UpdateLocalDatabaseRequestMessageCode, body |-> one] : one \in CheckedUpdateLocalDatabaseRequestMessage }
        \cup { [tag |-> MessageDownloadRequestMessageCode, body |-> one] : one \in CheckedMessageDownloadRequestMessage }
        \cup { [tag |-> LogoffRequestMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> OrderEntryRequestMessageCode, body |-> one] : one \in CheckedOrderEntryRequestMessage }
        \cup { [tag |-> OrderModificationRequestMessageCode, body |-> one] : one \in CheckedOrderModificationRequestMessage }
        \cup { [tag |-> OrderCancellationRequestMessageCode, body |-> one] : one \in CheckedOrderCancellationRequestMessage }
        \cup { [tag |-> TradeCancellationRequestMessageCode, body |-> one] : one \in CheckedTradeCancellationRequestMessage }
        \cup { [tag |-> TradeModificationRequestMessageCode, body |-> one] : one \in CheckedTradeModificationRequestMessage }
        \cup { [tag |-> GatewayRouterRequestMessageCode, body |-> one] : one \in CheckedGatewayRouterRequestMessage }
        \cup { [tag |-> SecureBoxRegistrationRequestMessageCode, body |-> one] : one \in CheckedSecureBoxRegistrationRequestMessage }
        \cup { [tag |-> BoxSignOnRequestMessageCode, body |-> one] : one \in CheckedBoxSignOnRequestMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Client Direct Packet, framed by Packet Length                           *)
(***************************************************************************)

ClientDirectPacket ==
    [ packetSequenceNumber : Sample(4),
      checksum             : Sample(16),
      logTime              : Sample(4),
      alphaChar            : Sample(2),
      traderId             : Sample(4),
      errorCode            : Sample(2),
      headerTimestamp      : Sample(8),
      timeStamp1           : Sample(8),
      timeStamp2           : Sample(8),
      messageLength        : Sample(2),
      clientMessagePayload : ClientMessagePayload ]

EncodeClientDirectPacketBody(message) ==
    message.packetSequenceNumber
        \o message.checksum
        \o EncodeUIntBE(message.clientMessagePayload.tag, 2)
        \o message.logTime
        \o message.alphaChar
        \o message.traderId
        \o message.errorCode
        \o message.headerTimestamp
        \o message.timeStamp1
        \o message.timeStamp2
        \o message.messageLength
        \o EncodeClientMessagePayload(message.clientMessagePayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeClientDirectPacket(message) ==
    LET body == EncodeClientDirectPacketBody(message)
    IN  EncodeUIntBE(Len(body) + 2, 2) \o body

DecodeClientDirectPacketBody(bytes) ==
    LET packetSequenceNumber == ReadBytes(bytes, 4) IN IF ~packetSequenceNumber.ok THEN Fail ELSE
    LET checksum == ReadBytes(packetSequenceNumber.rest, 16) IN IF ~checksum.ok THEN Fail ELSE
    LET transactionCode == ReadUIntBE(checksum.rest, 2) IN IF ~transactionCode.ok THEN Fail ELSE
    LET logTime == ReadBytes(transactionCode.rest, 4) IN IF ~logTime.ok THEN Fail ELSE
    LET alphaChar == ReadBytes(logTime.rest, 2) IN IF ~alphaChar.ok THEN Fail ELSE
    LET traderId == ReadBytes(alphaChar.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET errorCode == ReadBytes(traderId.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET headerTimestamp == ReadBytes(errorCode.rest, 8) IN IF ~headerTimestamp.ok THEN Fail ELSE
    LET timeStamp1 == ReadBytes(headerTimestamp.rest, 8) IN IF ~timeStamp1.ok THEN Fail ELSE
    LET timeStamp2 == ReadBytes(timeStamp1.rest, 8) IN IF ~timeStamp2.ok THEN Fail ELSE
    LET messageLength == ReadBytes(timeStamp2.rest, 2) IN IF ~messageLength.ok THEN Fail ELSE
    LET clientMessagePayload == DecodeClientMessagePayload(transactionCode.value, messageLength.rest) IN IF ~clientMessagePayload.ok THEN Fail ELSE
    Ok([ packetSequenceNumber |-> packetSequenceNumber.value,
         checksum             |-> checksum.value,
         logTime              |-> logTime.value,
         alphaChar            |-> alphaChar.value,
         traderId             |-> traderId.value,
         errorCode            |-> errorCode.value,
         headerTimestamp      |-> headerTimestamp.value,
         timeStamp1           |-> timeStamp1.value,
         timeStamp2           |-> timeStamp2.value,
         messageLength        |-> messageLength.value,
         clientMessagePayload |-> clientMessagePayload.value ], clientMessagePayload.rest)

DecodeClientDirectPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeClientDirectPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientDirectPacket ==
    [ packetSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      checksum             |-> [i \in 1 .. 16 |-> 0],
      logTime              |-> [i \in 1 .. 4 |-> 0],
      alphaChar            |-> [i \in 1 .. 2 |-> 0],
      traderId             |-> [i \in 1 .. 4 |-> 0],
      errorCode            |-> [i \in 1 .. 2 |-> 0],
      headerTimestamp      |-> [i \in 1 .. 8 |-> 0],
      timeStamp1           |-> [i \in 1 .. 8 |-> 0],
      timeStamp2           |-> [i \in 1 .. 8 |-> 0],
      messageLength        |-> [i \in 1 .. 2 |-> 0],
      clientMessagePayload |-> ZeroClientMessagePayload ]

(* Client Direct Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientDirectPacket ==
    { ZeroClientDirectPacket }
        \cup { [ZeroClientDirectPacket EXCEPT !.packetSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroClientDirectPacket EXCEPT !.checksum = one] : one \in Sample(16) }
        \cup { [ZeroClientDirectPacket EXCEPT !.logTime = one] : one \in Sample(4) }
        \cup { [ZeroClientDirectPacket EXCEPT !.alphaChar = one] : one \in Sample(2) }
        \cup { [ZeroClientDirectPacket EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroClientDirectPacket EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroClientDirectPacket EXCEPT !.headerTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroClientDirectPacket EXCEPT !.timeStamp1 = one] : one \in Sample(8) }
        \cup { [ZeroClientDirectPacket EXCEPT !.timeStamp2 = one] : one \in Sample(8) }
        \cup { [ZeroClientDirectPacket EXCEPT !.messageLength = one] : one \in Sample(2) }
        \cup { [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = one] : one \in CheckedClientMessagePayload }

(* A run of Client Direct Packet, written one after another *)
RECURSIVE EncodeClientDirectPacketList(_)
EncodeClientDirectPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientDirectPacket(Head(messages)) \o EncodeClientDirectPacketList(Tail(messages))

(* As many Client Direct Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientDirectPacketAll(_)
ReadClientDirectPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientDirectPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientDirectPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Direct Packet of each kind, for the lists that carry them *)
OneClientDirectPacket ==
    { [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> LogonRequestMessageCode, body |-> ZeroLogonRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SystemInformationRequestMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> UpdateLocalDatabaseRequestMessageCode, body |-> ZeroUpdateLocalDatabaseRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> MessageDownloadRequestMessageCode, body |-> ZeroMessageDownloadRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> LogoffRequestMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderEntryRequestMessageCode, body |-> ZeroOrderEntryRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderModificationRequestMessageCode, body |-> ZeroOrderModificationRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderCancellationRequestMessageCode, body |-> ZeroOrderCancellationRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> TradeCancellationRequestMessageCode, body |-> ZeroTradeCancellationRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> TradeModificationRequestMessageCode, body |-> ZeroTradeModificationRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> GatewayRouterRequestMessageCode, body |-> ZeroGatewayRouterRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SecureBoxRegistrationRequestMessageCode, body |-> ZeroSecureBoxRegistrationRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> BoxSignOnRequestMessageCode, body |-> ZeroBoxSignOnRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientDirectPacket : SampleLists(OneClientDirectPacket) ]

EncodeClientPacket(message) ==
    EncodeClientDirectPacketList(message.clientDirectPacket)

DecodeClientPacket(bytes) ==
    LET clientDirectPacket == ReadClientDirectPacketAll(bytes) IN IF ~clientDirectPacket.ok THEN Fail ELSE
    Ok([ clientDirectPacket |-> clientDirectPacket.value ], clientDirectPacket.rest)

ZeroClientPacket ==
    [ clientDirectPacket |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientDirectPacket = one] : one \in SampleLists(OneClientDirectPacket) }

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

(* Every Logon Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonRequestMessage ==
    \A message \in CheckedLogonRequestMessage :
        LET read == DecodeLogonRequestMessage(EncodeLogonRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Update Local Database Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUpdateLocalDatabaseRequestMessage ==
    \A message \in CheckedUpdateLocalDatabaseRequestMessage :
        LET read == DecodeUpdateLocalDatabaseRequestMessage(EncodeUpdateLocalDatabaseRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Message Download Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMessageDownloadRequestMessage ==
    \A message \in CheckedMessageDownloadRequestMessage :
        LET read == DecodeMessageDownloadRequestMessage(EncodeMessageDownloadRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sec Info decodes back to what was encoded, and leaves nothing over *)
RoundTripSecInfo ==
    \A message \in CheckedSecInfo :
        LET read == DecodeSecInfo(EncodeSecInfo(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Entry Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderEntryRequestMessage ==
    \A message \in CheckedOrderEntryRequestMessage :
        LET read == DecodeOrderEntryRequestMessage(EncodeOrderEntryRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sec Info decodes back to what was encoded, and leaves nothing over *)
RoundTripSecInfo2 ==
    \A message \in CheckedSecInfo2 :
        LET read == DecodeSecInfo2(EncodeSecInfo2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modification Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModificationRequestMessage ==
    \A message \in CheckedOrderModificationRequestMessage :
        LET read == DecodeOrderModificationRequestMessage(EncodeOrderModificationRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sec Info decodes back to what was encoded, and leaves nothing over *)
RoundTripSecInfo3 ==
    \A message \in CheckedSecInfo3 :
        LET read == DecodeSecInfo3(EncodeSecInfo3(message))
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

(* Every Sec Info decodes back to what was encoded, and leaves nothing over *)
RoundTripSecInfo4 ==
    \A message \in CheckedSecInfo4 :
        LET read == DecodeSecInfo4(EncodeSecInfo4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancellation Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancellationRequestMessage ==
    \A message \in CheckedTradeCancellationRequestMessage :
        LET read == DecodeTradeCancellationRequestMessage(EncodeTradeCancellationRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sec Info decodes back to what was encoded, and leaves nothing over *)
RoundTripSecInfo5 ==
    \A message \in CheckedSecInfo5 :
        LET read == DecodeSecInfo5(EncodeSecInfo5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Modification Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeModificationRequestMessage ==
    \A message \in CheckedTradeModificationRequestMessage :
        LET read == DecodeTradeModificationRequestMessage(EncodeTradeModificationRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gateway Router Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGatewayRouterRequestMessage ==
    \A message \in CheckedGatewayRouterRequestMessage :
        LET read == DecodeGatewayRouterRequestMessage(EncodeGatewayRouterRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secure Box Registration Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecureBoxRegistrationRequestMessage ==
    \A message \in CheckedSecureBoxRegistrationRequestMessage :
        LET read == DecodeSecureBoxRegistrationRequestMessage(EncodeSecureBoxRegistrationRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Box Sign On Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBoxSignOnRequestMessage ==
    \A message \in CheckedBoxSignOnRequestMessage :
        LET read == DecodeBoxSignOnRequestMessage(EncodeBoxSignOnRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Direct Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientDirectPacket ==
    \A message \in CheckedClientDirectPacket :
        LET read == DecodeClientDirectPacket(EncodeClientDirectPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientPacket ==
    \A message \in CheckedClientPacket :
        LET read == DecodeClientPacket(EncodeClientPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Client Message Payload is selected by the Transaction Code it is written under *)
SelectsClientMessagePayload ==
    \A message \in CheckedClientMessagePayload :
        LET sent == EncodeClientMessagePayload(message)
            read == DecodeClientMessagePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Packet Length is written from the bytes it frames *)
FramesClientDirectPacket ==
    \A message \in CheckedClientDirectPacket :
        LET bytes == EncodeClientDirectPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
