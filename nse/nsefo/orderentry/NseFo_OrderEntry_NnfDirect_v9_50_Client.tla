-------------- MODULE NseFo_OrderEntry_NnfDirect_v9_50_Client --------------
(***************************************************************************)
(* National Stock Exchange of India Ltd Order Entry v9.50                  *)
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
(* Note: St Broker Eligibility Per Mkt is a bit field set, checked as its  *)
(* 2 bytes rather than bit by bit.                                         *)
(*                                                                         *)
(* Note: St Order Flags is a bit field set, checked as its 2 bytes rather  *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Additional Order Flags is a bit field set, checked as its 1 byte  *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Ms Spd Leg Info is written as 2 slots, however many of them the   *)
(* count beside it says are in use.                                        *)
(*                                                                         *)
(* Note: Branch Limits is written as 2 slots, however many of them the     *)
(* count beside it says are in use.                                        *)
(*                                                                         *)
(* Note: User Limits is written as 2 slots, however many of them the count *)
(* beside it says are in use.                                              *)
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
(* Sign On Request In Message: 238 bytes                                   *)
(***************************************************************************)

SignOnRequestInMessage ==
    [ userId                    : Sample(4),
      reserved8                 : Sample(8),
      password                  : Sample(8),
      secondReserved8           : Sample(8),
      newPassword               : Sample(8),
      traderName                : Sample(26),
      lastPasswordChangeDate    : Sample(4),
      brokerId                  : Sample(5),
      reserved1                 : Sample(1),
      branchId                  : Sample(2),
      versionNumber             : Sample(4),
      batch2StartTime           : Sample(4),
      hostSwitchContext         : Sample(1),
      colour                    : Sample(50),
      secondReserved1           : Sample(1),
      userType                  : Sample(2),
      sequenceNumber            : Sample(8),
      wsClassName               : Sample(14),
      brokerStatus              : Sample(1),
      showIndex                 : Sample(1),
      stBrokerEligibilityPerMkt : Sample(2),
      memberType                : Sample(2),
      clearingStatus            : Sample(1),
      brokerName                : Sample(25),
      reserved16                : Sample(16),
      secondReserved16          : Sample(16),
      thirdReserved16           : Sample(16) ]

EncodeSignOnRequestInMessage(message) ==
    message.userId
        \o message.reserved8
        \o message.password
        \o message.secondReserved8
        \o message.newPassword
        \o message.traderName
        \o message.lastPasswordChangeDate
        \o message.brokerId
        \o message.reserved1
        \o message.branchId
        \o message.versionNumber
        \o message.batch2StartTime
        \o message.hostSwitchContext
        \o message.colour
        \o message.secondReserved1
        \o message.userType
        \o message.sequenceNumber
        \o message.wsClassName
        \o message.brokerStatus
        \o message.showIndex
        \o message.stBrokerEligibilityPerMkt
        \o message.memberType
        \o message.clearingStatus
        \o message.brokerName
        \o message.reserved16
        \o message.secondReserved16
        \o message.thirdReserved16

DecodeSignOnRequestInMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(userId.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET password == ReadBytes(reserved8.rest, 8) IN IF ~password.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(password.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    LET newPassword == ReadBytes(secondReserved8.rest, 8) IN IF ~newPassword.ok THEN Fail ELSE
    LET traderName == ReadBytes(newPassword.rest, 26) IN IF ~traderName.ok THEN Fail ELSE
    LET lastPasswordChangeDate == ReadBytes(traderName.rest, 4) IN IF ~lastPasswordChangeDate.ok THEN Fail ELSE
    LET brokerId == ReadBytes(lastPasswordChangeDate.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(brokerId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET branchId == ReadBytes(reserved1.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET versionNumber == ReadBytes(branchId.rest, 4) IN IF ~versionNumber.ok THEN Fail ELSE
    LET batch2StartTime == ReadBytes(versionNumber.rest, 4) IN IF ~batch2StartTime.ok THEN Fail ELSE
    LET hostSwitchContext == ReadBytes(batch2StartTime.rest, 1) IN IF ~hostSwitchContext.ok THEN Fail ELSE
    LET colour == ReadBytes(hostSwitchContext.rest, 50) IN IF ~colour.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(colour.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET userType == ReadBytes(secondReserved1.rest, 2) IN IF ~userType.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(userType.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET wsClassName == ReadBytes(sequenceNumber.rest, 14) IN IF ~wsClassName.ok THEN Fail ELSE
    LET brokerStatus == ReadBytes(wsClassName.rest, 1) IN IF ~brokerStatus.ok THEN Fail ELSE
    LET showIndex == ReadBytes(brokerStatus.rest, 1) IN IF ~showIndex.ok THEN Fail ELSE
    LET stBrokerEligibilityPerMkt == ReadBytes(showIndex.rest, 2) IN IF ~stBrokerEligibilityPerMkt.ok THEN Fail ELSE
    LET memberType == ReadBytes(stBrokerEligibilityPerMkt.rest, 2) IN IF ~memberType.ok THEN Fail ELSE
    LET clearingStatus == ReadBytes(memberType.rest, 1) IN IF ~clearingStatus.ok THEN Fail ELSE
    LET brokerName == ReadBytes(clearingStatus.rest, 25) IN IF ~brokerName.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(brokerName.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    LET secondReserved16 == ReadBytes(reserved16.rest, 16) IN IF ~secondReserved16.ok THEN Fail ELSE
    LET thirdReserved16 == ReadBytes(secondReserved16.rest, 16) IN IF ~thirdReserved16.ok THEN Fail ELSE
    Ok([ userId                    |-> userId.value,
         reserved8                 |-> reserved8.value,
         password                  |-> password.value,
         secondReserved8           |-> secondReserved8.value,
         newPassword               |-> newPassword.value,
         traderName                |-> traderName.value,
         lastPasswordChangeDate    |-> lastPasswordChangeDate.value,
         brokerId                  |-> brokerId.value,
         reserved1                 |-> reserved1.value,
         branchId                  |-> branchId.value,
         versionNumber             |-> versionNumber.value,
         batch2StartTime           |-> batch2StartTime.value,
         hostSwitchContext         |-> hostSwitchContext.value,
         colour                    |-> colour.value,
         secondReserved1           |-> secondReserved1.value,
         userType                  |-> userType.value,
         sequenceNumber            |-> sequenceNumber.value,
         wsClassName               |-> wsClassName.value,
         brokerStatus              |-> brokerStatus.value,
         showIndex                 |-> showIndex.value,
         stBrokerEligibilityPerMkt |-> stBrokerEligibilityPerMkt.value,
         memberType                |-> memberType.value,
         clearingStatus            |-> clearingStatus.value,
         brokerName                |-> brokerName.value,
         reserved16                |-> reserved16.value,
         secondReserved16          |-> secondReserved16.value,
         thirdReserved16           |-> thirdReserved16.value ], thirdReserved16.rest)

ZeroSignOnRequestInMessage ==
    [ userId                    |-> [i \in 1 .. 4 |-> 0],
      reserved8                 |-> [i \in 1 .. 8 |-> 0],
      password                  |-> [i \in 1 .. 8 |-> 0],
      secondReserved8           |-> [i \in 1 .. 8 |-> 0],
      newPassword               |-> [i \in 1 .. 8 |-> 0],
      traderName                |-> [i \in 1 .. 26 |-> 0],
      lastPasswordChangeDate    |-> [i \in 1 .. 4 |-> 0],
      brokerId                  |-> [i \in 1 .. 5 |-> 0],
      reserved1                 |-> [i \in 1 .. 1 |-> 0],
      branchId                  |-> [i \in 1 .. 2 |-> 0],
      versionNumber             |-> [i \in 1 .. 4 |-> 0],
      batch2StartTime           |-> [i \in 1 .. 4 |-> 0],
      hostSwitchContext         |-> [i \in 1 .. 1 |-> 0],
      colour                    |-> [i \in 1 .. 50 |-> 0],
      secondReserved1           |-> [i \in 1 .. 1 |-> 0],
      userType                  |-> [i \in 1 .. 2 |-> 0],
      sequenceNumber            |-> [i \in 1 .. 8 |-> 0],
      wsClassName               |-> [i \in 1 .. 14 |-> 0],
      brokerStatus              |-> [i \in 1 .. 1 |-> 0],
      showIndex                 |-> [i \in 1 .. 1 |-> 0],
      stBrokerEligibilityPerMkt |-> [i \in 1 .. 2 |-> 0],
      memberType                |-> [i \in 1 .. 2 |-> 0],
      clearingStatus            |-> [i \in 1 .. 1 |-> 0],
      brokerName                |-> [i \in 1 .. 25 |-> 0],
      reserved16                |-> [i \in 1 .. 16 |-> 0],
      secondReserved16          |-> [i \in 1 .. 16 |-> 0],
      thirdReserved16           |-> [i \in 1 .. 16 |-> 0] ]

(* Sign On Request In Message at zero, then each field in turn at the values it is checked at *)
CheckedSignOnRequestInMessage ==
    { ZeroSignOnRequestInMessage }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.password = one] : one \in Sample(8) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.newPassword = one] : one \in Sample(8) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.traderName = one] : one \in Sample(26) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.lastPasswordChangeDate = one] : one \in Sample(4) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.versionNumber = one] : one \in Sample(4) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.batch2StartTime = one] : one \in Sample(4) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.hostSwitchContext = one] : one \in Sample(1) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.colour = one] : one \in Sample(50) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.userType = one] : one \in Sample(2) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.wsClassName = one] : one \in Sample(14) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.brokerStatus = one] : one \in Sample(1) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.showIndex = one] : one \in Sample(1) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.stBrokerEligibilityPerMkt = one] : one \in Sample(2) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.memberType = one] : one \in Sample(2) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.clearingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.brokerName = one] : one \in Sample(25) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.secondReserved16 = one] : one \in Sample(16) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.thirdReserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* System Information In Message: 4 bytes                                  *)
(***************************************************************************)

SystemInformationInMessage ==
    [ lastUpdatePortfolioTIme : Sample(4) ]

EncodeSystemInformationInMessage(message) ==
    message.lastUpdatePortfolioTIme

DecodeSystemInformationInMessage(bytes) ==
    LET lastUpdatePortfolioTIme == ReadBytes(bytes, 4) IN IF ~lastUpdatePortfolioTIme.ok THEN Fail ELSE
    Ok([ lastUpdatePortfolioTIme |-> lastUpdatePortfolioTIme.value ], lastUpdatePortfolioTIme.rest)

ZeroSystemInformationInMessage ==
    [ lastUpdatePortfolioTIme |-> [i \in 1 .. 4 |-> 0] ]

(* System Information In Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemInformationInMessage ==
    { ZeroSystemInformationInMessage }
        \cup { [ZeroSystemInformationInMessage EXCEPT !.lastUpdatePortfolioTIme = one] : one \in Sample(4) }

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
(* St Market Status: 8 bytes                                               *)
(***************************************************************************)

StMarketStatus ==
    [ marketStatusNormal  : Sample(2),
      marketStatusOddlot  : Sample(2),
      marketStatusSpot    : Sample(2),
      marketStatusAuction : Sample(2) ]

EncodeStMarketStatus(message) ==
    message.marketStatusNormal
        \o message.marketStatusOddlot
        \o message.marketStatusSpot
        \o message.marketStatusAuction

DecodeStMarketStatus(bytes) ==
    LET marketStatusNormal == ReadBytes(bytes, 2) IN IF ~marketStatusNormal.ok THEN Fail ELSE
    LET marketStatusOddlot == ReadBytes(marketStatusNormal.rest, 2) IN IF ~marketStatusOddlot.ok THEN Fail ELSE
    LET marketStatusSpot == ReadBytes(marketStatusOddlot.rest, 2) IN IF ~marketStatusSpot.ok THEN Fail ELSE
    LET marketStatusAuction == ReadBytes(marketStatusSpot.rest, 2) IN IF ~marketStatusAuction.ok THEN Fail ELSE
    Ok([ marketStatusNormal  |-> marketStatusNormal.value,
         marketStatusOddlot  |-> marketStatusOddlot.value,
         marketStatusSpot    |-> marketStatusSpot.value,
         marketStatusAuction |-> marketStatusAuction.value ], marketStatusAuction.rest)

ZeroStMarketStatus ==
    [ marketStatusNormal  |-> [i \in 1 .. 2 |-> 0],
      marketStatusOddlot  |-> [i \in 1 .. 2 |-> 0],
      marketStatusSpot    |-> [i \in 1 .. 2 |-> 0],
      marketStatusAuction |-> [i \in 1 .. 2 |-> 0] ]

(* St Market Status at zero, then each field in turn at the values it is checked at *)
CheckedStMarketStatus ==
    { ZeroStMarketStatus }
        \cup { [ZeroStMarketStatus EXCEPT !.marketStatusNormal = one] : one \in Sample(2) }
        \cup { [ZeroStMarketStatus EXCEPT !.marketStatusOddlot = one] : one \in Sample(2) }
        \cup { [ZeroStMarketStatus EXCEPT !.marketStatusSpot = one] : one \in Sample(2) }
        \cup { [ZeroStMarketStatus EXCEPT !.marketStatusAuction = one] : one \in Sample(2) }

(***************************************************************************)
(* St Ex Market Status: 8 bytes                                            *)
(***************************************************************************)

StExMarketStatus ==
    [ exMarketStatusNormal  : Sample(2),
      exMarketStatusOddlot  : Sample(2),
      exMarketStatusSpot    : Sample(2),
      exMarketStatusAuction : Sample(2) ]

EncodeStExMarketStatus(message) ==
    message.exMarketStatusNormal
        \o message.exMarketStatusOddlot
        \o message.exMarketStatusSpot
        \o message.exMarketStatusAuction

DecodeStExMarketStatus(bytes) ==
    LET exMarketStatusNormal == ReadBytes(bytes, 2) IN IF ~exMarketStatusNormal.ok THEN Fail ELSE
    LET exMarketStatusOddlot == ReadBytes(exMarketStatusNormal.rest, 2) IN IF ~exMarketStatusOddlot.ok THEN Fail ELSE
    LET exMarketStatusSpot == ReadBytes(exMarketStatusOddlot.rest, 2) IN IF ~exMarketStatusSpot.ok THEN Fail ELSE
    LET exMarketStatusAuction == ReadBytes(exMarketStatusSpot.rest, 2) IN IF ~exMarketStatusAuction.ok THEN Fail ELSE
    Ok([ exMarketStatusNormal  |-> exMarketStatusNormal.value,
         exMarketStatusOddlot  |-> exMarketStatusOddlot.value,
         exMarketStatusSpot    |-> exMarketStatusSpot.value,
         exMarketStatusAuction |-> exMarketStatusAuction.value ], exMarketStatusAuction.rest)

ZeroStExMarketStatus ==
    [ exMarketStatusNormal  |-> [i \in 1 .. 2 |-> 0],
      exMarketStatusOddlot  |-> [i \in 1 .. 2 |-> 0],
      exMarketStatusSpot    |-> [i \in 1 .. 2 |-> 0],
      exMarketStatusAuction |-> [i \in 1 .. 2 |-> 0] ]

(* St Ex Market Status at zero, then each field in turn at the values it is checked at *)
CheckedStExMarketStatus ==
    { ZeroStExMarketStatus }
        \cup { [ZeroStExMarketStatus EXCEPT !.exMarketStatusNormal = one] : one \in Sample(2) }
        \cup { [ZeroStExMarketStatus EXCEPT !.exMarketStatusOddlot = one] : one \in Sample(2) }
        \cup { [ZeroStExMarketStatus EXCEPT !.exMarketStatusSpot = one] : one \in Sample(2) }
        \cup { [ZeroStExMarketStatus EXCEPT !.exMarketStatusAuction = one] : one \in Sample(2) }

(***************************************************************************)
(* St Pl Market Status: 8 bytes                                            *)
(***************************************************************************)

StPlMarketStatus ==
    [ plMarketStatusNormal  : Sample(2),
      plMarketStatusOddlot  : Sample(2),
      plMarketStatusSpot    : Sample(2),
      plMarketStatusAuction : Sample(2) ]

EncodeStPlMarketStatus(message) ==
    message.plMarketStatusNormal
        \o message.plMarketStatusOddlot
        \o message.plMarketStatusSpot
        \o message.plMarketStatusAuction

DecodeStPlMarketStatus(bytes) ==
    LET plMarketStatusNormal == ReadBytes(bytes, 2) IN IF ~plMarketStatusNormal.ok THEN Fail ELSE
    LET plMarketStatusOddlot == ReadBytes(plMarketStatusNormal.rest, 2) IN IF ~plMarketStatusOddlot.ok THEN Fail ELSE
    LET plMarketStatusSpot == ReadBytes(plMarketStatusOddlot.rest, 2) IN IF ~plMarketStatusSpot.ok THEN Fail ELSE
    LET plMarketStatusAuction == ReadBytes(plMarketStatusSpot.rest, 2) IN IF ~plMarketStatusAuction.ok THEN Fail ELSE
    Ok([ plMarketStatusNormal  |-> plMarketStatusNormal.value,
         plMarketStatusOddlot  |-> plMarketStatusOddlot.value,
         plMarketStatusSpot    |-> plMarketStatusSpot.value,
         plMarketStatusAuction |-> plMarketStatusAuction.value ], plMarketStatusAuction.rest)

ZeroStPlMarketStatus ==
    [ plMarketStatusNormal  |-> [i \in 1 .. 2 |-> 0],
      plMarketStatusOddlot  |-> [i \in 1 .. 2 |-> 0],
      plMarketStatusSpot    |-> [i \in 1 .. 2 |-> 0],
      plMarketStatusAuction |-> [i \in 1 .. 2 |-> 0] ]

(* St Pl Market Status at zero, then each field in turn at the values it is checked at *)
CheckedStPlMarketStatus ==
    { ZeroStPlMarketStatus }
        \cup { [ZeroStPlMarketStatus EXCEPT !.plMarketStatusNormal = one] : one \in Sample(2) }
        \cup { [ZeroStPlMarketStatus EXCEPT !.plMarketStatusOddlot = one] : one \in Sample(2) }
        \cup { [ZeroStPlMarketStatus EXCEPT !.plMarketStatusSpot = one] : one \in Sample(2) }
        \cup { [ZeroStPlMarketStatus EXCEPT !.plMarketStatusAuction = one] : one \in Sample(2) }

(***************************************************************************)
(* Update Local Database In Message: 42 bytes                              *)
(***************************************************************************)

UpdateLocalDatabaseInMessage ==
    [ lastUpdateSecurityTime    : Sample(4),
      lastUpdateParticipantTime : Sample(4),
      lastUpdateInstrumentTime  : Sample(4),
      lastUpdateIndexTime       : Sample(4),
      requestForOpenOrders      : Sample(1),
      reserved1                 : Sample(1),
      stMarketStatus            : StMarketStatus,
      stExMarketStatus          : StExMarketStatus,
      stPlMarketStatus          : StPlMarketStatus ]

EncodeUpdateLocalDatabaseInMessage(message) ==
    message.lastUpdateSecurityTime
        \o message.lastUpdateParticipantTime
        \o message.lastUpdateInstrumentTime
        \o message.lastUpdateIndexTime
        \o message.requestForOpenOrders
        \o message.reserved1
        \o EncodeStMarketStatus(message.stMarketStatus)
        \o EncodeStExMarketStatus(message.stExMarketStatus)
        \o EncodeStPlMarketStatus(message.stPlMarketStatus)

DecodeUpdateLocalDatabaseInMessage(bytes) ==
    LET lastUpdateSecurityTime == ReadBytes(bytes, 4) IN IF ~lastUpdateSecurityTime.ok THEN Fail ELSE
    LET lastUpdateParticipantTime == ReadBytes(lastUpdateSecurityTime.rest, 4) IN IF ~lastUpdateParticipantTime.ok THEN Fail ELSE
    LET lastUpdateInstrumentTime == ReadBytes(lastUpdateParticipantTime.rest, 4) IN IF ~lastUpdateInstrumentTime.ok THEN Fail ELSE
    LET lastUpdateIndexTime == ReadBytes(lastUpdateInstrumentTime.rest, 4) IN IF ~lastUpdateIndexTime.ok THEN Fail ELSE
    LET requestForOpenOrders == ReadBytes(lastUpdateIndexTime.rest, 1) IN IF ~requestForOpenOrders.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(requestForOpenOrders.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET stMarketStatus == DecodeStMarketStatus(reserved1.rest) IN IF ~stMarketStatus.ok THEN Fail ELSE
    LET stExMarketStatus == DecodeStExMarketStatus(stMarketStatus.rest) IN IF ~stExMarketStatus.ok THEN Fail ELSE
    LET stPlMarketStatus == DecodeStPlMarketStatus(stExMarketStatus.rest) IN IF ~stPlMarketStatus.ok THEN Fail ELSE
    Ok([ lastUpdateSecurityTime    |-> lastUpdateSecurityTime.value,
         lastUpdateParticipantTime |-> lastUpdateParticipantTime.value,
         lastUpdateInstrumentTime  |-> lastUpdateInstrumentTime.value,
         lastUpdateIndexTime       |-> lastUpdateIndexTime.value,
         requestForOpenOrders      |-> requestForOpenOrders.value,
         reserved1                 |-> reserved1.value,
         stMarketStatus            |-> stMarketStatus.value,
         stExMarketStatus          |-> stExMarketStatus.value,
         stPlMarketStatus          |-> stPlMarketStatus.value ], stPlMarketStatus.rest)

ZeroUpdateLocalDatabaseInMessage ==
    [ lastUpdateSecurityTime    |-> [i \in 1 .. 4 |-> 0],
      lastUpdateParticipantTime |-> [i \in 1 .. 4 |-> 0],
      lastUpdateInstrumentTime  |-> [i \in 1 .. 4 |-> 0],
      lastUpdateIndexTime       |-> [i \in 1 .. 4 |-> 0],
      requestForOpenOrders      |-> [i \in 1 .. 1 |-> 0],
      reserved1                 |-> [i \in 1 .. 1 |-> 0],
      stMarketStatus            |-> ZeroStMarketStatus,
      stExMarketStatus          |-> ZeroStExMarketStatus,
      stPlMarketStatus          |-> ZeroStPlMarketStatus ]

(* Update Local Database In Message at zero, then each field in turn at the values it is checked at *)
CheckedUpdateLocalDatabaseInMessage ==
    { ZeroUpdateLocalDatabaseInMessage }
        \cup { [ZeroUpdateLocalDatabaseInMessage EXCEPT !.lastUpdateSecurityTime = one] : one \in Sample(4) }
        \cup { [ZeroUpdateLocalDatabaseInMessage EXCEPT !.lastUpdateParticipantTime = one] : one \in Sample(4) }
        \cup { [ZeroUpdateLocalDatabaseInMessage EXCEPT !.lastUpdateInstrumentTime = one] : one \in Sample(4) }
        \cup { [ZeroUpdateLocalDatabaseInMessage EXCEPT !.lastUpdateIndexTime = one] : one \in Sample(4) }
        \cup { [ZeroUpdateLocalDatabaseInMessage EXCEPT !.requestForOpenOrders = one] : one \in Sample(1) }
        \cup { [ZeroUpdateLocalDatabaseInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroUpdateLocalDatabaseInMessage EXCEPT !.stMarketStatus = one] : one \in CheckedStMarketStatus }
        \cup { [ZeroUpdateLocalDatabaseInMessage EXCEPT !.stExMarketStatus = one] : one \in CheckedStExMarketStatus }
        \cup { [ZeroUpdateLocalDatabaseInMessage EXCEPT !.stPlMarketStatus = one] : one \in CheckedStPlMarketStatus }

(***************************************************************************)
(* Download Request Message: 8 bytes                                       *)
(***************************************************************************)

DownloadRequestMessage ==
    [ sequenceNumber : Sample(8) ]

EncodeDownloadRequestMessage(message) ==
    message.sequenceNumber

DecodeDownloadRequestMessage(bytes) ==
    LET sequenceNumber == ReadBytes(bytes, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroDownloadRequestMessage ==
    [ sequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Download Request Message at zero, then each field in turn at the values it is checked at *)
CheckedDownloadRequestMessage ==
    { ZeroDownloadRequestMessage }
        \cup { [ZeroDownloadRequestMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         caLevel        |-> caLevel.value ], caLevel.rest)

ZeroContractDesc ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc ==
    { ZeroContractDesc }
        \cup { [ZeroContractDesc EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Entry Body: 276 bytes                                             *)
(***************************************************************************)

OrderEntryBody ==
    [ participantType          : Sample(1),
      reserved1                : Sample(1),
      competitorPeriod         : Sample(2),
      solicitorPeriod          : Sample(2),
      modifiedCancelledBy      : Sample(1),
      secondReserved1          : Sample(1),
      reasonCode               : Sample(2),
      reserved4                : Sample(4),
      tokenNo                  : Sample(4),
      contractDesc             : ContractDesc,
      counterPartyBrokerId     : Sample(5),
      thirdReserved1           : Sample(1),
      reserved2                : Sample(2),
      closeoutFlag             : Sample(1),
      fourthReserved1          : Sample(1),
      orderType                : Sample(2),
      orderNumber              : Sample(8),
      accountNumber            : Sample(10),
      bookType                 : Sample(2),
      buySellIndicator         : Sample(2),
      disclosedVolume          : Sample(4),
      disclosedVolumeRemaining : Sample(4),
      totalVolumeRemaining     : Sample(4),
      volume                   : Sample(4),
      volumeFilledToday        : Sample(4),
      price                    : Sample(4),
      triggerPrice             : Sample(4),
      goodTillDate             : Sample(4),
      entryDateTime            : Sample(4),
      minimumFillAonVolume     : Sample(4),
      lastModified             : Sample(4),
      stOrderFlags             : Sample(2),
      branchId                 : Sample(2),
      traderId                 : Sample(4),
      brokerId                 : Sample(5),
      cOrdFiller               : Sample(24),
      openClose                : Sample(1),
      settlor                  : Sample(12),
      proClientIndicator       : Sample(2),
      settlementPeriod         : Sample(2),
      additionalOrderFlags     : Sample(1),
      fifthReserved1           : Sample(1),
      filler116                : Sample(2),
      filler17                 : Sample(1),
      filler18                 : Sample(1),
      nnfField                 : Sample(8),
      mktReplay                : Sample(8),
      pan                      : Sample(10),
      algoId                   : Sample(4),
      secondReserved2          : Sample(2),
      lastActivityReference    : Sample(8),
      reserved52               : Sample(52) ]

EncodeOrderEntryBody(message) ==
    message.participantType
        \o message.reserved1
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.modifiedCancelledBy
        \o message.secondReserved1
        \o message.reasonCode
        \o message.reserved4
        \o message.tokenNo
        \o EncodeContractDesc(message.contractDesc)
        \o message.counterPartyBrokerId
        \o message.thirdReserved1
        \o message.reserved2
        \o message.closeoutFlag
        \o message.fourthReserved1
        \o message.orderType
        \o message.orderNumber
        \o message.accountNumber
        \o message.bookType
        \o message.buySellIndicator
        \o message.disclosedVolume
        \o message.disclosedVolumeRemaining
        \o message.totalVolumeRemaining
        \o message.volume
        \o message.volumeFilledToday
        \o message.price
        \o message.triggerPrice
        \o message.goodTillDate
        \o message.entryDateTime
        \o message.minimumFillAonVolume
        \o message.lastModified
        \o message.stOrderFlags
        \o message.branchId
        \o message.traderId
        \o message.brokerId
        \o message.cOrdFiller
        \o message.openClose
        \o message.settlor
        \o message.proClientIndicator
        \o message.settlementPeriod
        \o message.additionalOrderFlags
        \o message.fifthReserved1
        \o message.filler116
        \o message.filler17
        \o message.filler18
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.secondReserved2
        \o message.lastActivityReference
        \o message.reserved52

DecodeOrderEntryBody(bytes) ==
    LET participantType == ReadBytes(bytes, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(participantType.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET competitorPeriod == ReadBytes(reserved1.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET modifiedCancelledBy == ReadBytes(solicitorPeriod.rest, 1) IN IF ~modifiedCancelledBy.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(modifiedCancelledBy.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(secondReserved1.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reasonCode.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET tokenNo == ReadBytes(reserved4.rest, 4) IN IF ~tokenNo.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc(tokenNo.rest) IN IF ~contractDesc.ok THEN Fail ELSE
    LET counterPartyBrokerId == ReadBytes(contractDesc.rest, 5) IN IF ~counterPartyBrokerId.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(counterPartyBrokerId.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(thirdReserved1.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET closeoutFlag == ReadBytes(reserved2.rest, 1) IN IF ~closeoutFlag.ok THEN Fail ELSE
    LET fourthReserved1 == ReadBytes(closeoutFlag.rest, 1) IN IF ~fourthReserved1.ok THEN Fail ELSE
    LET orderType == ReadBytes(fourthReserved1.rest, 2) IN IF ~orderType.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(orderType.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(orderNumber.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(bookType.rest, 2) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySellIndicator.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolumeRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolumeRemaining.ok THEN Fail ELSE
    LET totalVolumeRemaining == ReadBytes(disclosedVolumeRemaining.rest, 4) IN IF ~totalVolumeRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolumeRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET volumeFilledToday == ReadBytes(volume.rest, 4) IN IF ~volumeFilledToday.ok THEN Fail ELSE
    LET price == ReadBytes(volumeFilledToday.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET goodTillDate == ReadBytes(triggerPrice.rest, 4) IN IF ~goodTillDate.ok THEN Fail ELSE
    LET entryDateTime == ReadBytes(goodTillDate.rest, 4) IN IF ~entryDateTime.ok THEN Fail ELSE
    LET minimumFillAonVolume == ReadBytes(entryDateTime.rest, 4) IN IF ~minimumFillAonVolume.ok THEN Fail ELSE
    LET lastModified == ReadBytes(minimumFillAonVolume.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET traderId == ReadBytes(branchId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(traderId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET cOrdFiller == ReadBytes(brokerId.rest, 24) IN IF ~cOrdFiller.ok THEN Fail ELSE
    LET openClose == ReadBytes(cOrdFiller.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET settlor == ReadBytes(openClose.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClientIndicator == ReadBytes(settlor.rest, 2) IN IF ~proClientIndicator.ok THEN Fail ELSE
    LET settlementPeriod == ReadBytes(proClientIndicator.rest, 2) IN IF ~settlementPeriod.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(settlementPeriod.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET fifthReserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~fifthReserved1.ok THEN Fail ELSE
    LET filler116 == ReadBytes(fifthReserved1.rest, 2) IN IF ~filler116.ok THEN Fail ELSE
    LET filler17 == ReadBytes(filler116.rest, 1) IN IF ~filler17.ok THEN Fail ELSE
    LET filler18 == ReadBytes(filler17.rest, 1) IN IF ~filler18.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler18.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET mktReplay == ReadBytes(nnfField.rest, 8) IN IF ~mktReplay.ok THEN Fail ELSE
    LET pan == ReadBytes(mktReplay.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(algoId.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(secondReserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    Ok([ participantType          |-> participantType.value,
         reserved1                |-> reserved1.value,
         competitorPeriod         |-> competitorPeriod.value,
         solicitorPeriod          |-> solicitorPeriod.value,
         modifiedCancelledBy      |-> modifiedCancelledBy.value,
         secondReserved1          |-> secondReserved1.value,
         reasonCode               |-> reasonCode.value,
         reserved4                |-> reserved4.value,
         tokenNo                  |-> tokenNo.value,
         contractDesc             |-> contractDesc.value,
         counterPartyBrokerId     |-> counterPartyBrokerId.value,
         thirdReserved1           |-> thirdReserved1.value,
         reserved2                |-> reserved2.value,
         closeoutFlag             |-> closeoutFlag.value,
         fourthReserved1          |-> fourthReserved1.value,
         orderType                |-> orderType.value,
         orderNumber              |-> orderNumber.value,
         accountNumber            |-> accountNumber.value,
         bookType                 |-> bookType.value,
         buySellIndicator         |-> buySellIndicator.value,
         disclosedVolume          |-> disclosedVolume.value,
         disclosedVolumeRemaining |-> disclosedVolumeRemaining.value,
         totalVolumeRemaining     |-> totalVolumeRemaining.value,
         volume                   |-> volume.value,
         volumeFilledToday        |-> volumeFilledToday.value,
         price                    |-> price.value,
         triggerPrice             |-> triggerPrice.value,
         goodTillDate             |-> goodTillDate.value,
         entryDateTime            |-> entryDateTime.value,
         minimumFillAonVolume     |-> minimumFillAonVolume.value,
         lastModified             |-> lastModified.value,
         stOrderFlags             |-> stOrderFlags.value,
         branchId                 |-> branchId.value,
         traderId                 |-> traderId.value,
         brokerId                 |-> brokerId.value,
         cOrdFiller               |-> cOrdFiller.value,
         openClose                |-> openClose.value,
         settlor                  |-> settlor.value,
         proClientIndicator       |-> proClientIndicator.value,
         settlementPeriod         |-> settlementPeriod.value,
         additionalOrderFlags     |-> additionalOrderFlags.value,
         fifthReserved1           |-> fifthReserved1.value,
         filler116                |-> filler116.value,
         filler17                 |-> filler17.value,
         filler18                 |-> filler18.value,
         nnfField                 |-> nnfField.value,
         mktReplay                |-> mktReplay.value,
         pan                      |-> pan.value,
         algoId                   |-> algoId.value,
         secondReserved2          |-> secondReserved2.value,
         lastActivityReference    |-> lastActivityReference.value,
         reserved52               |-> reserved52.value ], reserved52.rest)

ZeroOrderEntryBody ==
    [ participantType          |-> [i \in 1 .. 1 |-> 0],
      reserved1                |-> [i \in 1 .. 1 |-> 0],
      competitorPeriod         |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod          |-> [i \in 1 .. 2 |-> 0],
      modifiedCancelledBy      |-> [i \in 1 .. 1 |-> 0],
      secondReserved1          |-> [i \in 1 .. 1 |-> 0],
      reasonCode               |-> [i \in 1 .. 2 |-> 0],
      reserved4                |-> [i \in 1 .. 4 |-> 0],
      tokenNo                  |-> [i \in 1 .. 4 |-> 0],
      contractDesc             |-> ZeroContractDesc,
      counterPartyBrokerId     |-> [i \in 1 .. 5 |-> 0],
      thirdReserved1           |-> [i \in 1 .. 1 |-> 0],
      reserved2                |-> [i \in 1 .. 2 |-> 0],
      closeoutFlag             |-> [i \in 1 .. 1 |-> 0],
      fourthReserved1          |-> [i \in 1 .. 1 |-> 0],
      orderType                |-> [i \in 1 .. 2 |-> 0],
      orderNumber              |-> [i \in 1 .. 8 |-> 0],
      accountNumber            |-> [i \in 1 .. 10 |-> 0],
      bookType                 |-> [i \in 1 .. 2 |-> 0],
      buySellIndicator         |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolumeRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolumeRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                   |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday        |-> [i \in 1 .. 4 |-> 0],
      price                    |-> [i \in 1 .. 4 |-> 0],
      triggerPrice             |-> [i \in 1 .. 4 |-> 0],
      goodTillDate             |-> [i \in 1 .. 4 |-> 0],
      entryDateTime            |-> [i \in 1 .. 4 |-> 0],
      minimumFillAonVolume     |-> [i \in 1 .. 4 |-> 0],
      lastModified             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags             |-> [i \in 1 .. 2 |-> 0],
      branchId                 |-> [i \in 1 .. 2 |-> 0],
      traderId                 |-> [i \in 1 .. 4 |-> 0],
      brokerId                 |-> [i \in 1 .. 5 |-> 0],
      cOrdFiller               |-> [i \in 1 .. 24 |-> 0],
      openClose                |-> [i \in 1 .. 1 |-> 0],
      settlor                  |-> [i \in 1 .. 12 |-> 0],
      proClientIndicator       |-> [i \in 1 .. 2 |-> 0],
      settlementPeriod         |-> [i \in 1 .. 2 |-> 0],
      additionalOrderFlags     |-> [i \in 1 .. 1 |-> 0],
      fifthReserved1           |-> [i \in 1 .. 1 |-> 0],
      filler116                |-> [i \in 1 .. 2 |-> 0],
      filler17                 |-> [i \in 1 .. 1 |-> 0],
      filler18                 |-> [i \in 1 .. 1 |-> 0],
      nnfField                 |-> [i \in 1 .. 8 |-> 0],
      mktReplay                |-> [i \in 1 .. 8 |-> 0],
      pan                      |-> [i \in 1 .. 10 |-> 0],
      algoId                   |-> [i \in 1 .. 4 |-> 0],
      secondReserved2          |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference    |-> [i \in 1 .. 8 |-> 0],
      reserved52               |-> [i \in 1 .. 52 |-> 0] ]

(* Order Entry Body at zero, then each field in turn at the values it is checked at *)
CheckedOrderEntryBody ==
    { ZeroOrderEntryBody }
        \cup { [ZeroOrderEntryBody EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody EXCEPT !.modifiedCancelledBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.contractDesc = one] : one \in CheckedContractDesc }
        \cup { [ZeroOrderEntryBody EXCEPT !.counterPartyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryBody EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody EXCEPT !.closeoutFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody EXCEPT !.orderType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryBody EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody EXCEPT !.buySellIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.disclosedVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.totalVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.minimumFillAonVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryBody EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroOrderEntryBody EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderEntryBody EXCEPT !.proClientIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody EXCEPT !.settlementPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody EXCEPT !.filler116 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody EXCEPT !.filler17 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody EXCEPT !.filler18 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryBody EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody EXCEPT !.reserved52 = one] : one \in Sample(52) }

(***************************************************************************)
(* Order Entry Request Message: 276 bytes                                  *)
(***************************************************************************)

OrderEntryRequestMessage ==
    [ orderEntryBody : OrderEntryBody ]

EncodeOrderEntryRequestMessage(message) ==
    EncodeOrderEntryBody(message.orderEntryBody)

DecodeOrderEntryRequestMessage(bytes) ==
    LET orderEntryBody == DecodeOrderEntryBody(bytes) IN IF ~orderEntryBody.ok THEN Fail ELSE
    Ok([ orderEntryBody |-> orderEntryBody.value ], orderEntryBody.rest)

ZeroOrderEntryRequestMessage ==
    [ orderEntryBody |-> ZeroOrderEntryBody ]

(* Order Entry Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderEntryRequestMessage ==
    { ZeroOrderEntryRequestMessage }
        \cup { [ZeroOrderEntryRequestMessage EXCEPT !.orderEntryBody = one] : one \in CheckedOrderEntryBody }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc2 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc2(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc2(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         caLevel        |-> caLevel.value ], caLevel.rest)

ZeroContractDesc2 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc2 ==
    { ZeroContractDesc2 }
        \cup { [ZeroContractDesc2 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc2 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc2 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc2 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc2 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc2 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Entry Body: 276 bytes                                             *)
(***************************************************************************)

OrderEntryBody2 ==
    [ participantType          : Sample(1),
      reserved1                : Sample(1),
      competitorPeriod         : Sample(2),
      solicitorPeriod          : Sample(2),
      modifiedCancelledBy      : Sample(1),
      secondReserved1          : Sample(1),
      reasonCode               : Sample(2),
      reserved4                : Sample(4),
      tokenNo                  : Sample(4),
      contractDesc             : ContractDesc2,
      counterPartyBrokerId     : Sample(5),
      thirdReserved1           : Sample(1),
      reserved2                : Sample(2),
      closeoutFlag             : Sample(1),
      fourthReserved1          : Sample(1),
      orderType                : Sample(2),
      orderNumber              : Sample(8),
      accountNumber            : Sample(10),
      bookType                 : Sample(2),
      buySellIndicator         : Sample(2),
      disclosedVolume          : Sample(4),
      disclosedVolumeRemaining : Sample(4),
      totalVolumeRemaining     : Sample(4),
      volume                   : Sample(4),
      volumeFilledToday        : Sample(4),
      price                    : Sample(4),
      triggerPrice             : Sample(4),
      goodTillDate             : Sample(4),
      entryDateTime            : Sample(4),
      minimumFillAonVolume     : Sample(4),
      lastModified             : Sample(4),
      stOrderFlags             : Sample(2),
      branchId                 : Sample(2),
      traderId                 : Sample(4),
      brokerId                 : Sample(5),
      cOrdFiller               : Sample(24),
      openClose                : Sample(1),
      settlor                  : Sample(12),
      proClientIndicator       : Sample(2),
      settlementPeriod         : Sample(2),
      additionalOrderFlags     : Sample(1),
      fifthReserved1           : Sample(1),
      filler116                : Sample(2),
      filler17                 : Sample(1),
      filler18                 : Sample(1),
      nnfField                 : Sample(8),
      mktReplay                : Sample(8),
      pan                      : Sample(10),
      algoId                   : Sample(4),
      secondReserved2          : Sample(2),
      lastActivityReference    : Sample(8),
      reserved52               : Sample(52) ]

EncodeOrderEntryBody2(message) ==
    message.participantType
        \o message.reserved1
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.modifiedCancelledBy
        \o message.secondReserved1
        \o message.reasonCode
        \o message.reserved4
        \o message.tokenNo
        \o EncodeContractDesc2(message.contractDesc)
        \o message.counterPartyBrokerId
        \o message.thirdReserved1
        \o message.reserved2
        \o message.closeoutFlag
        \o message.fourthReserved1
        \o message.orderType
        \o message.orderNumber
        \o message.accountNumber
        \o message.bookType
        \o message.buySellIndicator
        \o message.disclosedVolume
        \o message.disclosedVolumeRemaining
        \o message.totalVolumeRemaining
        \o message.volume
        \o message.volumeFilledToday
        \o message.price
        \o message.triggerPrice
        \o message.goodTillDate
        \o message.entryDateTime
        \o message.minimumFillAonVolume
        \o message.lastModified
        \o message.stOrderFlags
        \o message.branchId
        \o message.traderId
        \o message.brokerId
        \o message.cOrdFiller
        \o message.openClose
        \o message.settlor
        \o message.proClientIndicator
        \o message.settlementPeriod
        \o message.additionalOrderFlags
        \o message.fifthReserved1
        \o message.filler116
        \o message.filler17
        \o message.filler18
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.secondReserved2
        \o message.lastActivityReference
        \o message.reserved52

DecodeOrderEntryBody2(bytes) ==
    LET participantType == ReadBytes(bytes, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(participantType.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET competitorPeriod == ReadBytes(reserved1.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET modifiedCancelledBy == ReadBytes(solicitorPeriod.rest, 1) IN IF ~modifiedCancelledBy.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(modifiedCancelledBy.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(secondReserved1.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reasonCode.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET tokenNo == ReadBytes(reserved4.rest, 4) IN IF ~tokenNo.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc2(tokenNo.rest) IN IF ~contractDesc.ok THEN Fail ELSE
    LET counterPartyBrokerId == ReadBytes(contractDesc.rest, 5) IN IF ~counterPartyBrokerId.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(counterPartyBrokerId.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(thirdReserved1.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET closeoutFlag == ReadBytes(reserved2.rest, 1) IN IF ~closeoutFlag.ok THEN Fail ELSE
    LET fourthReserved1 == ReadBytes(closeoutFlag.rest, 1) IN IF ~fourthReserved1.ok THEN Fail ELSE
    LET orderType == ReadBytes(fourthReserved1.rest, 2) IN IF ~orderType.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(orderType.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(orderNumber.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(bookType.rest, 2) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySellIndicator.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolumeRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolumeRemaining.ok THEN Fail ELSE
    LET totalVolumeRemaining == ReadBytes(disclosedVolumeRemaining.rest, 4) IN IF ~totalVolumeRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolumeRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET volumeFilledToday == ReadBytes(volume.rest, 4) IN IF ~volumeFilledToday.ok THEN Fail ELSE
    LET price == ReadBytes(volumeFilledToday.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET goodTillDate == ReadBytes(triggerPrice.rest, 4) IN IF ~goodTillDate.ok THEN Fail ELSE
    LET entryDateTime == ReadBytes(goodTillDate.rest, 4) IN IF ~entryDateTime.ok THEN Fail ELSE
    LET minimumFillAonVolume == ReadBytes(entryDateTime.rest, 4) IN IF ~minimumFillAonVolume.ok THEN Fail ELSE
    LET lastModified == ReadBytes(minimumFillAonVolume.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET traderId == ReadBytes(branchId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(traderId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET cOrdFiller == ReadBytes(brokerId.rest, 24) IN IF ~cOrdFiller.ok THEN Fail ELSE
    LET openClose == ReadBytes(cOrdFiller.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET settlor == ReadBytes(openClose.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClientIndicator == ReadBytes(settlor.rest, 2) IN IF ~proClientIndicator.ok THEN Fail ELSE
    LET settlementPeriod == ReadBytes(proClientIndicator.rest, 2) IN IF ~settlementPeriod.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(settlementPeriod.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET fifthReserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~fifthReserved1.ok THEN Fail ELSE
    LET filler116 == ReadBytes(fifthReserved1.rest, 2) IN IF ~filler116.ok THEN Fail ELSE
    LET filler17 == ReadBytes(filler116.rest, 1) IN IF ~filler17.ok THEN Fail ELSE
    LET filler18 == ReadBytes(filler17.rest, 1) IN IF ~filler18.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler18.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET mktReplay == ReadBytes(nnfField.rest, 8) IN IF ~mktReplay.ok THEN Fail ELSE
    LET pan == ReadBytes(mktReplay.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(algoId.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(secondReserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    Ok([ participantType          |-> participantType.value,
         reserved1                |-> reserved1.value,
         competitorPeriod         |-> competitorPeriod.value,
         solicitorPeriod          |-> solicitorPeriod.value,
         modifiedCancelledBy      |-> modifiedCancelledBy.value,
         secondReserved1          |-> secondReserved1.value,
         reasonCode               |-> reasonCode.value,
         reserved4                |-> reserved4.value,
         tokenNo                  |-> tokenNo.value,
         contractDesc             |-> contractDesc.value,
         counterPartyBrokerId     |-> counterPartyBrokerId.value,
         thirdReserved1           |-> thirdReserved1.value,
         reserved2                |-> reserved2.value,
         closeoutFlag             |-> closeoutFlag.value,
         fourthReserved1          |-> fourthReserved1.value,
         orderType                |-> orderType.value,
         orderNumber              |-> orderNumber.value,
         accountNumber            |-> accountNumber.value,
         bookType                 |-> bookType.value,
         buySellIndicator         |-> buySellIndicator.value,
         disclosedVolume          |-> disclosedVolume.value,
         disclosedVolumeRemaining |-> disclosedVolumeRemaining.value,
         totalVolumeRemaining     |-> totalVolumeRemaining.value,
         volume                   |-> volume.value,
         volumeFilledToday        |-> volumeFilledToday.value,
         price                    |-> price.value,
         triggerPrice             |-> triggerPrice.value,
         goodTillDate             |-> goodTillDate.value,
         entryDateTime            |-> entryDateTime.value,
         minimumFillAonVolume     |-> minimumFillAonVolume.value,
         lastModified             |-> lastModified.value,
         stOrderFlags             |-> stOrderFlags.value,
         branchId                 |-> branchId.value,
         traderId                 |-> traderId.value,
         brokerId                 |-> brokerId.value,
         cOrdFiller               |-> cOrdFiller.value,
         openClose                |-> openClose.value,
         settlor                  |-> settlor.value,
         proClientIndicator       |-> proClientIndicator.value,
         settlementPeriod         |-> settlementPeriod.value,
         additionalOrderFlags     |-> additionalOrderFlags.value,
         fifthReserved1           |-> fifthReserved1.value,
         filler116                |-> filler116.value,
         filler17                 |-> filler17.value,
         filler18                 |-> filler18.value,
         nnfField                 |-> nnfField.value,
         mktReplay                |-> mktReplay.value,
         pan                      |-> pan.value,
         algoId                   |-> algoId.value,
         secondReserved2          |-> secondReserved2.value,
         lastActivityReference    |-> lastActivityReference.value,
         reserved52               |-> reserved52.value ], reserved52.rest)

ZeroOrderEntryBody2 ==
    [ participantType          |-> [i \in 1 .. 1 |-> 0],
      reserved1                |-> [i \in 1 .. 1 |-> 0],
      competitorPeriod         |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod          |-> [i \in 1 .. 2 |-> 0],
      modifiedCancelledBy      |-> [i \in 1 .. 1 |-> 0],
      secondReserved1          |-> [i \in 1 .. 1 |-> 0],
      reasonCode               |-> [i \in 1 .. 2 |-> 0],
      reserved4                |-> [i \in 1 .. 4 |-> 0],
      tokenNo                  |-> [i \in 1 .. 4 |-> 0],
      contractDesc             |-> ZeroContractDesc2,
      counterPartyBrokerId     |-> [i \in 1 .. 5 |-> 0],
      thirdReserved1           |-> [i \in 1 .. 1 |-> 0],
      reserved2                |-> [i \in 1 .. 2 |-> 0],
      closeoutFlag             |-> [i \in 1 .. 1 |-> 0],
      fourthReserved1          |-> [i \in 1 .. 1 |-> 0],
      orderType                |-> [i \in 1 .. 2 |-> 0],
      orderNumber              |-> [i \in 1 .. 8 |-> 0],
      accountNumber            |-> [i \in 1 .. 10 |-> 0],
      bookType                 |-> [i \in 1 .. 2 |-> 0],
      buySellIndicator         |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolumeRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolumeRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                   |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday        |-> [i \in 1 .. 4 |-> 0],
      price                    |-> [i \in 1 .. 4 |-> 0],
      triggerPrice             |-> [i \in 1 .. 4 |-> 0],
      goodTillDate             |-> [i \in 1 .. 4 |-> 0],
      entryDateTime            |-> [i \in 1 .. 4 |-> 0],
      minimumFillAonVolume     |-> [i \in 1 .. 4 |-> 0],
      lastModified             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags             |-> [i \in 1 .. 2 |-> 0],
      branchId                 |-> [i \in 1 .. 2 |-> 0],
      traderId                 |-> [i \in 1 .. 4 |-> 0],
      brokerId                 |-> [i \in 1 .. 5 |-> 0],
      cOrdFiller               |-> [i \in 1 .. 24 |-> 0],
      openClose                |-> [i \in 1 .. 1 |-> 0],
      settlor                  |-> [i \in 1 .. 12 |-> 0],
      proClientIndicator       |-> [i \in 1 .. 2 |-> 0],
      settlementPeriod         |-> [i \in 1 .. 2 |-> 0],
      additionalOrderFlags     |-> [i \in 1 .. 1 |-> 0],
      fifthReserved1           |-> [i \in 1 .. 1 |-> 0],
      filler116                |-> [i \in 1 .. 2 |-> 0],
      filler17                 |-> [i \in 1 .. 1 |-> 0],
      filler18                 |-> [i \in 1 .. 1 |-> 0],
      nnfField                 |-> [i \in 1 .. 8 |-> 0],
      mktReplay                |-> [i \in 1 .. 8 |-> 0],
      pan                      |-> [i \in 1 .. 10 |-> 0],
      algoId                   |-> [i \in 1 .. 4 |-> 0],
      secondReserved2          |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference    |-> [i \in 1 .. 8 |-> 0],
      reserved52               |-> [i \in 1 .. 52 |-> 0] ]

(* Order Entry Body at zero, then each field in turn at the values it is checked at *)
CheckedOrderEntryBody2 ==
    { ZeroOrderEntryBody2 }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.modifiedCancelledBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc2 }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.counterPartyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.closeoutFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.orderType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.buySellIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.disclosedVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.totalVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.minimumFillAonVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.proClientIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.settlementPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.filler116 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.filler17 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.filler18 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody2 EXCEPT !.reserved52 = one] : one \in Sample(52) }

(***************************************************************************)
(* Order Modification Request Message: 276 bytes                           *)
(***************************************************************************)

OrderModificationRequestMessage ==
    [ orderEntryBody : OrderEntryBody2 ]

EncodeOrderModificationRequestMessage(message) ==
    EncodeOrderEntryBody2(message.orderEntryBody)

DecodeOrderModificationRequestMessage(bytes) ==
    LET orderEntryBody == DecodeOrderEntryBody2(bytes) IN IF ~orderEntryBody.ok THEN Fail ELSE
    Ok([ orderEntryBody |-> orderEntryBody.value ], orderEntryBody.rest)

ZeroOrderModificationRequestMessage ==
    [ orderEntryBody |-> ZeroOrderEntryBody2 ]

(* Order Modification Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModificationRequestMessage ==
    { ZeroOrderModificationRequestMessage }
        \cup { [ZeroOrderModificationRequestMessage EXCEPT !.orderEntryBody = one] : one \in CheckedOrderEntryBody2 }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc3 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc3(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc3(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         caLevel        |-> caLevel.value ], caLevel.rest)

ZeroContractDesc3 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc3 ==
    { ZeroContractDesc3 }
        \cup { [ZeroContractDesc3 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc3 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc3 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc3 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc3 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc3 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Entry Body: 276 bytes                                             *)
(***************************************************************************)

OrderEntryBody3 ==
    [ participantType          : Sample(1),
      reserved1                : Sample(1),
      competitorPeriod         : Sample(2),
      solicitorPeriod          : Sample(2),
      modifiedCancelledBy      : Sample(1),
      secondReserved1          : Sample(1),
      reasonCode               : Sample(2),
      reserved4                : Sample(4),
      tokenNo                  : Sample(4),
      contractDesc             : ContractDesc3,
      counterPartyBrokerId     : Sample(5),
      thirdReserved1           : Sample(1),
      reserved2                : Sample(2),
      closeoutFlag             : Sample(1),
      fourthReserved1          : Sample(1),
      orderType                : Sample(2),
      orderNumber              : Sample(8),
      accountNumber            : Sample(10),
      bookType                 : Sample(2),
      buySellIndicator         : Sample(2),
      disclosedVolume          : Sample(4),
      disclosedVolumeRemaining : Sample(4),
      totalVolumeRemaining     : Sample(4),
      volume                   : Sample(4),
      volumeFilledToday        : Sample(4),
      price                    : Sample(4),
      triggerPrice             : Sample(4),
      goodTillDate             : Sample(4),
      entryDateTime            : Sample(4),
      minimumFillAonVolume     : Sample(4),
      lastModified             : Sample(4),
      stOrderFlags             : Sample(2),
      branchId                 : Sample(2),
      traderId                 : Sample(4),
      brokerId                 : Sample(5),
      cOrdFiller               : Sample(24),
      openClose                : Sample(1),
      settlor                  : Sample(12),
      proClientIndicator       : Sample(2),
      settlementPeriod         : Sample(2),
      additionalOrderFlags     : Sample(1),
      fifthReserved1           : Sample(1),
      filler116                : Sample(2),
      filler17                 : Sample(1),
      filler18                 : Sample(1),
      nnfField                 : Sample(8),
      mktReplay                : Sample(8),
      pan                      : Sample(10),
      algoId                   : Sample(4),
      secondReserved2          : Sample(2),
      lastActivityReference    : Sample(8),
      reserved52               : Sample(52) ]

EncodeOrderEntryBody3(message) ==
    message.participantType
        \o message.reserved1
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.modifiedCancelledBy
        \o message.secondReserved1
        \o message.reasonCode
        \o message.reserved4
        \o message.tokenNo
        \o EncodeContractDesc3(message.contractDesc)
        \o message.counterPartyBrokerId
        \o message.thirdReserved1
        \o message.reserved2
        \o message.closeoutFlag
        \o message.fourthReserved1
        \o message.orderType
        \o message.orderNumber
        \o message.accountNumber
        \o message.bookType
        \o message.buySellIndicator
        \o message.disclosedVolume
        \o message.disclosedVolumeRemaining
        \o message.totalVolumeRemaining
        \o message.volume
        \o message.volumeFilledToday
        \o message.price
        \o message.triggerPrice
        \o message.goodTillDate
        \o message.entryDateTime
        \o message.minimumFillAonVolume
        \o message.lastModified
        \o message.stOrderFlags
        \o message.branchId
        \o message.traderId
        \o message.brokerId
        \o message.cOrdFiller
        \o message.openClose
        \o message.settlor
        \o message.proClientIndicator
        \o message.settlementPeriod
        \o message.additionalOrderFlags
        \o message.fifthReserved1
        \o message.filler116
        \o message.filler17
        \o message.filler18
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.secondReserved2
        \o message.lastActivityReference
        \o message.reserved52

DecodeOrderEntryBody3(bytes) ==
    LET participantType == ReadBytes(bytes, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(participantType.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET competitorPeriod == ReadBytes(reserved1.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET modifiedCancelledBy == ReadBytes(solicitorPeriod.rest, 1) IN IF ~modifiedCancelledBy.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(modifiedCancelledBy.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(secondReserved1.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reasonCode.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET tokenNo == ReadBytes(reserved4.rest, 4) IN IF ~tokenNo.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc3(tokenNo.rest) IN IF ~contractDesc.ok THEN Fail ELSE
    LET counterPartyBrokerId == ReadBytes(contractDesc.rest, 5) IN IF ~counterPartyBrokerId.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(counterPartyBrokerId.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(thirdReserved1.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET closeoutFlag == ReadBytes(reserved2.rest, 1) IN IF ~closeoutFlag.ok THEN Fail ELSE
    LET fourthReserved1 == ReadBytes(closeoutFlag.rest, 1) IN IF ~fourthReserved1.ok THEN Fail ELSE
    LET orderType == ReadBytes(fourthReserved1.rest, 2) IN IF ~orderType.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(orderType.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(orderNumber.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(bookType.rest, 2) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySellIndicator.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolumeRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolumeRemaining.ok THEN Fail ELSE
    LET totalVolumeRemaining == ReadBytes(disclosedVolumeRemaining.rest, 4) IN IF ~totalVolumeRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolumeRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET volumeFilledToday == ReadBytes(volume.rest, 4) IN IF ~volumeFilledToday.ok THEN Fail ELSE
    LET price == ReadBytes(volumeFilledToday.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET goodTillDate == ReadBytes(triggerPrice.rest, 4) IN IF ~goodTillDate.ok THEN Fail ELSE
    LET entryDateTime == ReadBytes(goodTillDate.rest, 4) IN IF ~entryDateTime.ok THEN Fail ELSE
    LET minimumFillAonVolume == ReadBytes(entryDateTime.rest, 4) IN IF ~minimumFillAonVolume.ok THEN Fail ELSE
    LET lastModified == ReadBytes(minimumFillAonVolume.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET traderId == ReadBytes(branchId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(traderId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET cOrdFiller == ReadBytes(brokerId.rest, 24) IN IF ~cOrdFiller.ok THEN Fail ELSE
    LET openClose == ReadBytes(cOrdFiller.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET settlor == ReadBytes(openClose.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClientIndicator == ReadBytes(settlor.rest, 2) IN IF ~proClientIndicator.ok THEN Fail ELSE
    LET settlementPeriod == ReadBytes(proClientIndicator.rest, 2) IN IF ~settlementPeriod.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(settlementPeriod.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET fifthReserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~fifthReserved1.ok THEN Fail ELSE
    LET filler116 == ReadBytes(fifthReserved1.rest, 2) IN IF ~filler116.ok THEN Fail ELSE
    LET filler17 == ReadBytes(filler116.rest, 1) IN IF ~filler17.ok THEN Fail ELSE
    LET filler18 == ReadBytes(filler17.rest, 1) IN IF ~filler18.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler18.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET mktReplay == ReadBytes(nnfField.rest, 8) IN IF ~mktReplay.ok THEN Fail ELSE
    LET pan == ReadBytes(mktReplay.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(algoId.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(secondReserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    Ok([ participantType          |-> participantType.value,
         reserved1                |-> reserved1.value,
         competitorPeriod         |-> competitorPeriod.value,
         solicitorPeriod          |-> solicitorPeriod.value,
         modifiedCancelledBy      |-> modifiedCancelledBy.value,
         secondReserved1          |-> secondReserved1.value,
         reasonCode               |-> reasonCode.value,
         reserved4                |-> reserved4.value,
         tokenNo                  |-> tokenNo.value,
         contractDesc             |-> contractDesc.value,
         counterPartyBrokerId     |-> counterPartyBrokerId.value,
         thirdReserved1           |-> thirdReserved1.value,
         reserved2                |-> reserved2.value,
         closeoutFlag             |-> closeoutFlag.value,
         fourthReserved1          |-> fourthReserved1.value,
         orderType                |-> orderType.value,
         orderNumber              |-> orderNumber.value,
         accountNumber            |-> accountNumber.value,
         bookType                 |-> bookType.value,
         buySellIndicator         |-> buySellIndicator.value,
         disclosedVolume          |-> disclosedVolume.value,
         disclosedVolumeRemaining |-> disclosedVolumeRemaining.value,
         totalVolumeRemaining     |-> totalVolumeRemaining.value,
         volume                   |-> volume.value,
         volumeFilledToday        |-> volumeFilledToday.value,
         price                    |-> price.value,
         triggerPrice             |-> triggerPrice.value,
         goodTillDate             |-> goodTillDate.value,
         entryDateTime            |-> entryDateTime.value,
         minimumFillAonVolume     |-> minimumFillAonVolume.value,
         lastModified             |-> lastModified.value,
         stOrderFlags             |-> stOrderFlags.value,
         branchId                 |-> branchId.value,
         traderId                 |-> traderId.value,
         brokerId                 |-> brokerId.value,
         cOrdFiller               |-> cOrdFiller.value,
         openClose                |-> openClose.value,
         settlor                  |-> settlor.value,
         proClientIndicator       |-> proClientIndicator.value,
         settlementPeriod         |-> settlementPeriod.value,
         additionalOrderFlags     |-> additionalOrderFlags.value,
         fifthReserved1           |-> fifthReserved1.value,
         filler116                |-> filler116.value,
         filler17                 |-> filler17.value,
         filler18                 |-> filler18.value,
         nnfField                 |-> nnfField.value,
         mktReplay                |-> mktReplay.value,
         pan                      |-> pan.value,
         algoId                   |-> algoId.value,
         secondReserved2          |-> secondReserved2.value,
         lastActivityReference    |-> lastActivityReference.value,
         reserved52               |-> reserved52.value ], reserved52.rest)

ZeroOrderEntryBody3 ==
    [ participantType          |-> [i \in 1 .. 1 |-> 0],
      reserved1                |-> [i \in 1 .. 1 |-> 0],
      competitorPeriod         |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod          |-> [i \in 1 .. 2 |-> 0],
      modifiedCancelledBy      |-> [i \in 1 .. 1 |-> 0],
      secondReserved1          |-> [i \in 1 .. 1 |-> 0],
      reasonCode               |-> [i \in 1 .. 2 |-> 0],
      reserved4                |-> [i \in 1 .. 4 |-> 0],
      tokenNo                  |-> [i \in 1 .. 4 |-> 0],
      contractDesc             |-> ZeroContractDesc3,
      counterPartyBrokerId     |-> [i \in 1 .. 5 |-> 0],
      thirdReserved1           |-> [i \in 1 .. 1 |-> 0],
      reserved2                |-> [i \in 1 .. 2 |-> 0],
      closeoutFlag             |-> [i \in 1 .. 1 |-> 0],
      fourthReserved1          |-> [i \in 1 .. 1 |-> 0],
      orderType                |-> [i \in 1 .. 2 |-> 0],
      orderNumber              |-> [i \in 1 .. 8 |-> 0],
      accountNumber            |-> [i \in 1 .. 10 |-> 0],
      bookType                 |-> [i \in 1 .. 2 |-> 0],
      buySellIndicator         |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolumeRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolumeRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                   |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday        |-> [i \in 1 .. 4 |-> 0],
      price                    |-> [i \in 1 .. 4 |-> 0],
      triggerPrice             |-> [i \in 1 .. 4 |-> 0],
      goodTillDate             |-> [i \in 1 .. 4 |-> 0],
      entryDateTime            |-> [i \in 1 .. 4 |-> 0],
      minimumFillAonVolume     |-> [i \in 1 .. 4 |-> 0],
      lastModified             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags             |-> [i \in 1 .. 2 |-> 0],
      branchId                 |-> [i \in 1 .. 2 |-> 0],
      traderId                 |-> [i \in 1 .. 4 |-> 0],
      brokerId                 |-> [i \in 1 .. 5 |-> 0],
      cOrdFiller               |-> [i \in 1 .. 24 |-> 0],
      openClose                |-> [i \in 1 .. 1 |-> 0],
      settlor                  |-> [i \in 1 .. 12 |-> 0],
      proClientIndicator       |-> [i \in 1 .. 2 |-> 0],
      settlementPeriod         |-> [i \in 1 .. 2 |-> 0],
      additionalOrderFlags     |-> [i \in 1 .. 1 |-> 0],
      fifthReserved1           |-> [i \in 1 .. 1 |-> 0],
      filler116                |-> [i \in 1 .. 2 |-> 0],
      filler17                 |-> [i \in 1 .. 1 |-> 0],
      filler18                 |-> [i \in 1 .. 1 |-> 0],
      nnfField                 |-> [i \in 1 .. 8 |-> 0],
      mktReplay                |-> [i \in 1 .. 8 |-> 0],
      pan                      |-> [i \in 1 .. 10 |-> 0],
      algoId                   |-> [i \in 1 .. 4 |-> 0],
      secondReserved2          |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference    |-> [i \in 1 .. 8 |-> 0],
      reserved52               |-> [i \in 1 .. 52 |-> 0] ]

(* Order Entry Body at zero, then each field in turn at the values it is checked at *)
CheckedOrderEntryBody3 ==
    { ZeroOrderEntryBody3 }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.modifiedCancelledBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc3 }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.counterPartyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.closeoutFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.orderType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.buySellIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.disclosedVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.totalVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.minimumFillAonVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.proClientIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.settlementPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.filler116 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.filler17 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.filler18 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody3 EXCEPT !.reserved52 = one] : one \in Sample(52) }

(***************************************************************************)
(* Order Cancellation Request Message: 276 bytes                           *)
(***************************************************************************)

OrderCancellationRequestMessage ==
    [ orderEntryBody : OrderEntryBody3 ]

EncodeOrderCancellationRequestMessage(message) ==
    EncodeOrderEntryBody3(message.orderEntryBody)

DecodeOrderCancellationRequestMessage(bytes) ==
    LET orderEntryBody == DecodeOrderEntryBody3(bytes) IN IF ~orderEntryBody.ok THEN Fail ELSE
    Ok([ orderEntryBody |-> orderEntryBody.value ], orderEntryBody.rest)

ZeroOrderCancellationRequestMessage ==
    [ orderEntryBody |-> ZeroOrderEntryBody3 ]

(* Order Cancellation Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancellationRequestMessage ==
    { ZeroOrderCancellationRequestMessage }
        \cup { [ZeroOrderCancellationRequestMessage EXCEPT !.orderEntryBody = one] : one \in CheckedOrderEntryBody3 }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc4 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc4(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc4(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         caLevel        |-> caLevel.value ], caLevel.rest)

ZeroContractDesc4 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc4 ==
    { ZeroContractDesc4 }
        \cup { [ZeroContractDesc4 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc4 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc4 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc4 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc4 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc4 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Entry Body: 276 bytes                                             *)
(***************************************************************************)

OrderEntryBody4 ==
    [ participantType          : Sample(1),
      reserved1                : Sample(1),
      competitorPeriod         : Sample(2),
      solicitorPeriod          : Sample(2),
      modifiedCancelledBy      : Sample(1),
      secondReserved1          : Sample(1),
      reasonCode               : Sample(2),
      reserved4                : Sample(4),
      tokenNo                  : Sample(4),
      contractDesc             : ContractDesc4,
      counterPartyBrokerId     : Sample(5),
      thirdReserved1           : Sample(1),
      reserved2                : Sample(2),
      closeoutFlag             : Sample(1),
      fourthReserved1          : Sample(1),
      orderType                : Sample(2),
      orderNumber              : Sample(8),
      accountNumber            : Sample(10),
      bookType                 : Sample(2),
      buySellIndicator         : Sample(2),
      disclosedVolume          : Sample(4),
      disclosedVolumeRemaining : Sample(4),
      totalVolumeRemaining     : Sample(4),
      volume                   : Sample(4),
      volumeFilledToday        : Sample(4),
      price                    : Sample(4),
      triggerPrice             : Sample(4),
      goodTillDate             : Sample(4),
      entryDateTime            : Sample(4),
      minimumFillAonVolume     : Sample(4),
      lastModified             : Sample(4),
      stOrderFlags             : Sample(2),
      branchId                 : Sample(2),
      traderId                 : Sample(4),
      brokerId                 : Sample(5),
      cOrdFiller               : Sample(24),
      openClose                : Sample(1),
      settlor                  : Sample(12),
      proClientIndicator       : Sample(2),
      settlementPeriod         : Sample(2),
      additionalOrderFlags     : Sample(1),
      fifthReserved1           : Sample(1),
      filler116                : Sample(2),
      filler17                 : Sample(1),
      filler18                 : Sample(1),
      nnfField                 : Sample(8),
      mktReplay                : Sample(8),
      pan                      : Sample(10),
      algoId                   : Sample(4),
      secondReserved2          : Sample(2),
      lastActivityReference    : Sample(8),
      reserved52               : Sample(52) ]

EncodeOrderEntryBody4(message) ==
    message.participantType
        \o message.reserved1
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.modifiedCancelledBy
        \o message.secondReserved1
        \o message.reasonCode
        \o message.reserved4
        \o message.tokenNo
        \o EncodeContractDesc4(message.contractDesc)
        \o message.counterPartyBrokerId
        \o message.thirdReserved1
        \o message.reserved2
        \o message.closeoutFlag
        \o message.fourthReserved1
        \o message.orderType
        \o message.orderNumber
        \o message.accountNumber
        \o message.bookType
        \o message.buySellIndicator
        \o message.disclosedVolume
        \o message.disclosedVolumeRemaining
        \o message.totalVolumeRemaining
        \o message.volume
        \o message.volumeFilledToday
        \o message.price
        \o message.triggerPrice
        \o message.goodTillDate
        \o message.entryDateTime
        \o message.minimumFillAonVolume
        \o message.lastModified
        \o message.stOrderFlags
        \o message.branchId
        \o message.traderId
        \o message.brokerId
        \o message.cOrdFiller
        \o message.openClose
        \o message.settlor
        \o message.proClientIndicator
        \o message.settlementPeriod
        \o message.additionalOrderFlags
        \o message.fifthReserved1
        \o message.filler116
        \o message.filler17
        \o message.filler18
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.secondReserved2
        \o message.lastActivityReference
        \o message.reserved52

DecodeOrderEntryBody4(bytes) ==
    LET participantType == ReadBytes(bytes, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(participantType.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET competitorPeriod == ReadBytes(reserved1.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET modifiedCancelledBy == ReadBytes(solicitorPeriod.rest, 1) IN IF ~modifiedCancelledBy.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(modifiedCancelledBy.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(secondReserved1.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reasonCode.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET tokenNo == ReadBytes(reserved4.rest, 4) IN IF ~tokenNo.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc4(tokenNo.rest) IN IF ~contractDesc.ok THEN Fail ELSE
    LET counterPartyBrokerId == ReadBytes(contractDesc.rest, 5) IN IF ~counterPartyBrokerId.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(counterPartyBrokerId.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(thirdReserved1.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET closeoutFlag == ReadBytes(reserved2.rest, 1) IN IF ~closeoutFlag.ok THEN Fail ELSE
    LET fourthReserved1 == ReadBytes(closeoutFlag.rest, 1) IN IF ~fourthReserved1.ok THEN Fail ELSE
    LET orderType == ReadBytes(fourthReserved1.rest, 2) IN IF ~orderType.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(orderType.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(orderNumber.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(bookType.rest, 2) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySellIndicator.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolumeRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolumeRemaining.ok THEN Fail ELSE
    LET totalVolumeRemaining == ReadBytes(disclosedVolumeRemaining.rest, 4) IN IF ~totalVolumeRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolumeRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET volumeFilledToday == ReadBytes(volume.rest, 4) IN IF ~volumeFilledToday.ok THEN Fail ELSE
    LET price == ReadBytes(volumeFilledToday.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET goodTillDate == ReadBytes(triggerPrice.rest, 4) IN IF ~goodTillDate.ok THEN Fail ELSE
    LET entryDateTime == ReadBytes(goodTillDate.rest, 4) IN IF ~entryDateTime.ok THEN Fail ELSE
    LET minimumFillAonVolume == ReadBytes(entryDateTime.rest, 4) IN IF ~minimumFillAonVolume.ok THEN Fail ELSE
    LET lastModified == ReadBytes(minimumFillAonVolume.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET traderId == ReadBytes(branchId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(traderId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET cOrdFiller == ReadBytes(brokerId.rest, 24) IN IF ~cOrdFiller.ok THEN Fail ELSE
    LET openClose == ReadBytes(cOrdFiller.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET settlor == ReadBytes(openClose.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClientIndicator == ReadBytes(settlor.rest, 2) IN IF ~proClientIndicator.ok THEN Fail ELSE
    LET settlementPeriod == ReadBytes(proClientIndicator.rest, 2) IN IF ~settlementPeriod.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(settlementPeriod.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET fifthReserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~fifthReserved1.ok THEN Fail ELSE
    LET filler116 == ReadBytes(fifthReserved1.rest, 2) IN IF ~filler116.ok THEN Fail ELSE
    LET filler17 == ReadBytes(filler116.rest, 1) IN IF ~filler17.ok THEN Fail ELSE
    LET filler18 == ReadBytes(filler17.rest, 1) IN IF ~filler18.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler18.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET mktReplay == ReadBytes(nnfField.rest, 8) IN IF ~mktReplay.ok THEN Fail ELSE
    LET pan == ReadBytes(mktReplay.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(algoId.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(secondReserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    Ok([ participantType          |-> participantType.value,
         reserved1                |-> reserved1.value,
         competitorPeriod         |-> competitorPeriod.value,
         solicitorPeriod          |-> solicitorPeriod.value,
         modifiedCancelledBy      |-> modifiedCancelledBy.value,
         secondReserved1          |-> secondReserved1.value,
         reasonCode               |-> reasonCode.value,
         reserved4                |-> reserved4.value,
         tokenNo                  |-> tokenNo.value,
         contractDesc             |-> contractDesc.value,
         counterPartyBrokerId     |-> counterPartyBrokerId.value,
         thirdReserved1           |-> thirdReserved1.value,
         reserved2                |-> reserved2.value,
         closeoutFlag             |-> closeoutFlag.value,
         fourthReserved1          |-> fourthReserved1.value,
         orderType                |-> orderType.value,
         orderNumber              |-> orderNumber.value,
         accountNumber            |-> accountNumber.value,
         bookType                 |-> bookType.value,
         buySellIndicator         |-> buySellIndicator.value,
         disclosedVolume          |-> disclosedVolume.value,
         disclosedVolumeRemaining |-> disclosedVolumeRemaining.value,
         totalVolumeRemaining     |-> totalVolumeRemaining.value,
         volume                   |-> volume.value,
         volumeFilledToday        |-> volumeFilledToday.value,
         price                    |-> price.value,
         triggerPrice             |-> triggerPrice.value,
         goodTillDate             |-> goodTillDate.value,
         entryDateTime            |-> entryDateTime.value,
         minimumFillAonVolume     |-> minimumFillAonVolume.value,
         lastModified             |-> lastModified.value,
         stOrderFlags             |-> stOrderFlags.value,
         branchId                 |-> branchId.value,
         traderId                 |-> traderId.value,
         brokerId                 |-> brokerId.value,
         cOrdFiller               |-> cOrdFiller.value,
         openClose                |-> openClose.value,
         settlor                  |-> settlor.value,
         proClientIndicator       |-> proClientIndicator.value,
         settlementPeriod         |-> settlementPeriod.value,
         additionalOrderFlags     |-> additionalOrderFlags.value,
         fifthReserved1           |-> fifthReserved1.value,
         filler116                |-> filler116.value,
         filler17                 |-> filler17.value,
         filler18                 |-> filler18.value,
         nnfField                 |-> nnfField.value,
         mktReplay                |-> mktReplay.value,
         pan                      |-> pan.value,
         algoId                   |-> algoId.value,
         secondReserved2          |-> secondReserved2.value,
         lastActivityReference    |-> lastActivityReference.value,
         reserved52               |-> reserved52.value ], reserved52.rest)

ZeroOrderEntryBody4 ==
    [ participantType          |-> [i \in 1 .. 1 |-> 0],
      reserved1                |-> [i \in 1 .. 1 |-> 0],
      competitorPeriod         |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod          |-> [i \in 1 .. 2 |-> 0],
      modifiedCancelledBy      |-> [i \in 1 .. 1 |-> 0],
      secondReserved1          |-> [i \in 1 .. 1 |-> 0],
      reasonCode               |-> [i \in 1 .. 2 |-> 0],
      reserved4                |-> [i \in 1 .. 4 |-> 0],
      tokenNo                  |-> [i \in 1 .. 4 |-> 0],
      contractDesc             |-> ZeroContractDesc4,
      counterPartyBrokerId     |-> [i \in 1 .. 5 |-> 0],
      thirdReserved1           |-> [i \in 1 .. 1 |-> 0],
      reserved2                |-> [i \in 1 .. 2 |-> 0],
      closeoutFlag             |-> [i \in 1 .. 1 |-> 0],
      fourthReserved1          |-> [i \in 1 .. 1 |-> 0],
      orderType                |-> [i \in 1 .. 2 |-> 0],
      orderNumber              |-> [i \in 1 .. 8 |-> 0],
      accountNumber            |-> [i \in 1 .. 10 |-> 0],
      bookType                 |-> [i \in 1 .. 2 |-> 0],
      buySellIndicator         |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolumeRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolumeRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                   |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday        |-> [i \in 1 .. 4 |-> 0],
      price                    |-> [i \in 1 .. 4 |-> 0],
      triggerPrice             |-> [i \in 1 .. 4 |-> 0],
      goodTillDate             |-> [i \in 1 .. 4 |-> 0],
      entryDateTime            |-> [i \in 1 .. 4 |-> 0],
      minimumFillAonVolume     |-> [i \in 1 .. 4 |-> 0],
      lastModified             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags             |-> [i \in 1 .. 2 |-> 0],
      branchId                 |-> [i \in 1 .. 2 |-> 0],
      traderId                 |-> [i \in 1 .. 4 |-> 0],
      brokerId                 |-> [i \in 1 .. 5 |-> 0],
      cOrdFiller               |-> [i \in 1 .. 24 |-> 0],
      openClose                |-> [i \in 1 .. 1 |-> 0],
      settlor                  |-> [i \in 1 .. 12 |-> 0],
      proClientIndicator       |-> [i \in 1 .. 2 |-> 0],
      settlementPeriod         |-> [i \in 1 .. 2 |-> 0],
      additionalOrderFlags     |-> [i \in 1 .. 1 |-> 0],
      fifthReserved1           |-> [i \in 1 .. 1 |-> 0],
      filler116                |-> [i \in 1 .. 2 |-> 0],
      filler17                 |-> [i \in 1 .. 1 |-> 0],
      filler18                 |-> [i \in 1 .. 1 |-> 0],
      nnfField                 |-> [i \in 1 .. 8 |-> 0],
      mktReplay                |-> [i \in 1 .. 8 |-> 0],
      pan                      |-> [i \in 1 .. 10 |-> 0],
      algoId                   |-> [i \in 1 .. 4 |-> 0],
      secondReserved2          |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference    |-> [i \in 1 .. 8 |-> 0],
      reserved52               |-> [i \in 1 .. 52 |-> 0] ]

(* Order Entry Body at zero, then each field in turn at the values it is checked at *)
CheckedOrderEntryBody4 ==
    { ZeroOrderEntryBody4 }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.modifiedCancelledBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc4 }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.counterPartyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.closeoutFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.orderType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.buySellIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.disclosedVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.totalVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.minimumFillAonVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.proClientIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.settlementPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.filler116 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.filler17 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.filler18 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody4 EXCEPT !.reserved52 = one] : one \in Sample(52) }

(***************************************************************************)
(* Order Confirmation Message: 276 bytes                                   *)
(***************************************************************************)

OrderConfirmationMessage ==
    [ orderEntryBody : OrderEntryBody4 ]

EncodeOrderConfirmationMessage(message) ==
    EncodeOrderEntryBody4(message.orderEntryBody)

DecodeOrderConfirmationMessage(bytes) ==
    LET orderEntryBody == DecodeOrderEntryBody4(bytes) IN IF ~orderEntryBody.ok THEN Fail ELSE
    Ok([ orderEntryBody |-> orderEntryBody.value ], orderEntryBody.rest)

ZeroOrderConfirmationMessage ==
    [ orderEntryBody |-> ZeroOrderEntryBody4 ]

(* Order Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderConfirmationMessage ==
    { ZeroOrderConfirmationMessage }
        \cup { [ZeroOrderConfirmationMessage EXCEPT !.orderEntryBody = one] : one \in CheckedOrderEntryBody4 }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc5 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc5(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc5(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         caLevel        |-> caLevel.value ], caLevel.rest)

ZeroContractDesc5 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc5 ==
    { ZeroContractDesc5 }
        \cup { [ZeroContractDesc5 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc5 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc5 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc5 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc5 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc5 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Entry Body: 276 bytes                                             *)
(***************************************************************************)

OrderEntryBody5 ==
    [ participantType          : Sample(1),
      reserved1                : Sample(1),
      competitorPeriod         : Sample(2),
      solicitorPeriod          : Sample(2),
      modifiedCancelledBy      : Sample(1),
      secondReserved1          : Sample(1),
      reasonCode               : Sample(2),
      reserved4                : Sample(4),
      tokenNo                  : Sample(4),
      contractDesc             : ContractDesc5,
      counterPartyBrokerId     : Sample(5),
      thirdReserved1           : Sample(1),
      reserved2                : Sample(2),
      closeoutFlag             : Sample(1),
      fourthReserved1          : Sample(1),
      orderType                : Sample(2),
      orderNumber              : Sample(8),
      accountNumber            : Sample(10),
      bookType                 : Sample(2),
      buySellIndicator         : Sample(2),
      disclosedVolume          : Sample(4),
      disclosedVolumeRemaining : Sample(4),
      totalVolumeRemaining     : Sample(4),
      volume                   : Sample(4),
      volumeFilledToday        : Sample(4),
      price                    : Sample(4),
      triggerPrice             : Sample(4),
      goodTillDate             : Sample(4),
      entryDateTime            : Sample(4),
      minimumFillAonVolume     : Sample(4),
      lastModified             : Sample(4),
      stOrderFlags             : Sample(2),
      branchId                 : Sample(2),
      traderId                 : Sample(4),
      brokerId                 : Sample(5),
      cOrdFiller               : Sample(24),
      openClose                : Sample(1),
      settlor                  : Sample(12),
      proClientIndicator       : Sample(2),
      settlementPeriod         : Sample(2),
      additionalOrderFlags     : Sample(1),
      fifthReserved1           : Sample(1),
      filler116                : Sample(2),
      filler17                 : Sample(1),
      filler18                 : Sample(1),
      nnfField                 : Sample(8),
      mktReplay                : Sample(8),
      pan                      : Sample(10),
      algoId                   : Sample(4),
      secondReserved2          : Sample(2),
      lastActivityReference    : Sample(8),
      reserved52               : Sample(52) ]

EncodeOrderEntryBody5(message) ==
    message.participantType
        \o message.reserved1
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.modifiedCancelledBy
        \o message.secondReserved1
        \o message.reasonCode
        \o message.reserved4
        \o message.tokenNo
        \o EncodeContractDesc5(message.contractDesc)
        \o message.counterPartyBrokerId
        \o message.thirdReserved1
        \o message.reserved2
        \o message.closeoutFlag
        \o message.fourthReserved1
        \o message.orderType
        \o message.orderNumber
        \o message.accountNumber
        \o message.bookType
        \o message.buySellIndicator
        \o message.disclosedVolume
        \o message.disclosedVolumeRemaining
        \o message.totalVolumeRemaining
        \o message.volume
        \o message.volumeFilledToday
        \o message.price
        \o message.triggerPrice
        \o message.goodTillDate
        \o message.entryDateTime
        \o message.minimumFillAonVolume
        \o message.lastModified
        \o message.stOrderFlags
        \o message.branchId
        \o message.traderId
        \o message.brokerId
        \o message.cOrdFiller
        \o message.openClose
        \o message.settlor
        \o message.proClientIndicator
        \o message.settlementPeriod
        \o message.additionalOrderFlags
        \o message.fifthReserved1
        \o message.filler116
        \o message.filler17
        \o message.filler18
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.secondReserved2
        \o message.lastActivityReference
        \o message.reserved52

DecodeOrderEntryBody5(bytes) ==
    LET participantType == ReadBytes(bytes, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(participantType.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET competitorPeriod == ReadBytes(reserved1.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET modifiedCancelledBy == ReadBytes(solicitorPeriod.rest, 1) IN IF ~modifiedCancelledBy.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(modifiedCancelledBy.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(secondReserved1.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reasonCode.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET tokenNo == ReadBytes(reserved4.rest, 4) IN IF ~tokenNo.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc5(tokenNo.rest) IN IF ~contractDesc.ok THEN Fail ELSE
    LET counterPartyBrokerId == ReadBytes(contractDesc.rest, 5) IN IF ~counterPartyBrokerId.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(counterPartyBrokerId.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(thirdReserved1.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET closeoutFlag == ReadBytes(reserved2.rest, 1) IN IF ~closeoutFlag.ok THEN Fail ELSE
    LET fourthReserved1 == ReadBytes(closeoutFlag.rest, 1) IN IF ~fourthReserved1.ok THEN Fail ELSE
    LET orderType == ReadBytes(fourthReserved1.rest, 2) IN IF ~orderType.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(orderType.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(orderNumber.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(bookType.rest, 2) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySellIndicator.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolumeRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolumeRemaining.ok THEN Fail ELSE
    LET totalVolumeRemaining == ReadBytes(disclosedVolumeRemaining.rest, 4) IN IF ~totalVolumeRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolumeRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET volumeFilledToday == ReadBytes(volume.rest, 4) IN IF ~volumeFilledToday.ok THEN Fail ELSE
    LET price == ReadBytes(volumeFilledToday.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET goodTillDate == ReadBytes(triggerPrice.rest, 4) IN IF ~goodTillDate.ok THEN Fail ELSE
    LET entryDateTime == ReadBytes(goodTillDate.rest, 4) IN IF ~entryDateTime.ok THEN Fail ELSE
    LET minimumFillAonVolume == ReadBytes(entryDateTime.rest, 4) IN IF ~minimumFillAonVolume.ok THEN Fail ELSE
    LET lastModified == ReadBytes(minimumFillAonVolume.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET traderId == ReadBytes(branchId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(traderId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET cOrdFiller == ReadBytes(brokerId.rest, 24) IN IF ~cOrdFiller.ok THEN Fail ELSE
    LET openClose == ReadBytes(cOrdFiller.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET settlor == ReadBytes(openClose.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClientIndicator == ReadBytes(settlor.rest, 2) IN IF ~proClientIndicator.ok THEN Fail ELSE
    LET settlementPeriod == ReadBytes(proClientIndicator.rest, 2) IN IF ~settlementPeriod.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(settlementPeriod.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET fifthReserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~fifthReserved1.ok THEN Fail ELSE
    LET filler116 == ReadBytes(fifthReserved1.rest, 2) IN IF ~filler116.ok THEN Fail ELSE
    LET filler17 == ReadBytes(filler116.rest, 1) IN IF ~filler17.ok THEN Fail ELSE
    LET filler18 == ReadBytes(filler17.rest, 1) IN IF ~filler18.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler18.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET mktReplay == ReadBytes(nnfField.rest, 8) IN IF ~mktReplay.ok THEN Fail ELSE
    LET pan == ReadBytes(mktReplay.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(algoId.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(secondReserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    Ok([ participantType          |-> participantType.value,
         reserved1                |-> reserved1.value,
         competitorPeriod         |-> competitorPeriod.value,
         solicitorPeriod          |-> solicitorPeriod.value,
         modifiedCancelledBy      |-> modifiedCancelledBy.value,
         secondReserved1          |-> secondReserved1.value,
         reasonCode               |-> reasonCode.value,
         reserved4                |-> reserved4.value,
         tokenNo                  |-> tokenNo.value,
         contractDesc             |-> contractDesc.value,
         counterPartyBrokerId     |-> counterPartyBrokerId.value,
         thirdReserved1           |-> thirdReserved1.value,
         reserved2                |-> reserved2.value,
         closeoutFlag             |-> closeoutFlag.value,
         fourthReserved1          |-> fourthReserved1.value,
         orderType                |-> orderType.value,
         orderNumber              |-> orderNumber.value,
         accountNumber            |-> accountNumber.value,
         bookType                 |-> bookType.value,
         buySellIndicator         |-> buySellIndicator.value,
         disclosedVolume          |-> disclosedVolume.value,
         disclosedVolumeRemaining |-> disclosedVolumeRemaining.value,
         totalVolumeRemaining     |-> totalVolumeRemaining.value,
         volume                   |-> volume.value,
         volumeFilledToday        |-> volumeFilledToday.value,
         price                    |-> price.value,
         triggerPrice             |-> triggerPrice.value,
         goodTillDate             |-> goodTillDate.value,
         entryDateTime            |-> entryDateTime.value,
         minimumFillAonVolume     |-> minimumFillAonVolume.value,
         lastModified             |-> lastModified.value,
         stOrderFlags             |-> stOrderFlags.value,
         branchId                 |-> branchId.value,
         traderId                 |-> traderId.value,
         brokerId                 |-> brokerId.value,
         cOrdFiller               |-> cOrdFiller.value,
         openClose                |-> openClose.value,
         settlor                  |-> settlor.value,
         proClientIndicator       |-> proClientIndicator.value,
         settlementPeriod         |-> settlementPeriod.value,
         additionalOrderFlags     |-> additionalOrderFlags.value,
         fifthReserved1           |-> fifthReserved1.value,
         filler116                |-> filler116.value,
         filler17                 |-> filler17.value,
         filler18                 |-> filler18.value,
         nnfField                 |-> nnfField.value,
         mktReplay                |-> mktReplay.value,
         pan                      |-> pan.value,
         algoId                   |-> algoId.value,
         secondReserved2          |-> secondReserved2.value,
         lastActivityReference    |-> lastActivityReference.value,
         reserved52               |-> reserved52.value ], reserved52.rest)

ZeroOrderEntryBody5 ==
    [ participantType          |-> [i \in 1 .. 1 |-> 0],
      reserved1                |-> [i \in 1 .. 1 |-> 0],
      competitorPeriod         |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod          |-> [i \in 1 .. 2 |-> 0],
      modifiedCancelledBy      |-> [i \in 1 .. 1 |-> 0],
      secondReserved1          |-> [i \in 1 .. 1 |-> 0],
      reasonCode               |-> [i \in 1 .. 2 |-> 0],
      reserved4                |-> [i \in 1 .. 4 |-> 0],
      tokenNo                  |-> [i \in 1 .. 4 |-> 0],
      contractDesc             |-> ZeroContractDesc5,
      counterPartyBrokerId     |-> [i \in 1 .. 5 |-> 0],
      thirdReserved1           |-> [i \in 1 .. 1 |-> 0],
      reserved2                |-> [i \in 1 .. 2 |-> 0],
      closeoutFlag             |-> [i \in 1 .. 1 |-> 0],
      fourthReserved1          |-> [i \in 1 .. 1 |-> 0],
      orderType                |-> [i \in 1 .. 2 |-> 0],
      orderNumber              |-> [i \in 1 .. 8 |-> 0],
      accountNumber            |-> [i \in 1 .. 10 |-> 0],
      bookType                 |-> [i \in 1 .. 2 |-> 0],
      buySellIndicator         |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolumeRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolumeRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                   |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday        |-> [i \in 1 .. 4 |-> 0],
      price                    |-> [i \in 1 .. 4 |-> 0],
      triggerPrice             |-> [i \in 1 .. 4 |-> 0],
      goodTillDate             |-> [i \in 1 .. 4 |-> 0],
      entryDateTime            |-> [i \in 1 .. 4 |-> 0],
      minimumFillAonVolume     |-> [i \in 1 .. 4 |-> 0],
      lastModified             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags             |-> [i \in 1 .. 2 |-> 0],
      branchId                 |-> [i \in 1 .. 2 |-> 0],
      traderId                 |-> [i \in 1 .. 4 |-> 0],
      brokerId                 |-> [i \in 1 .. 5 |-> 0],
      cOrdFiller               |-> [i \in 1 .. 24 |-> 0],
      openClose                |-> [i \in 1 .. 1 |-> 0],
      settlor                  |-> [i \in 1 .. 12 |-> 0],
      proClientIndicator       |-> [i \in 1 .. 2 |-> 0],
      settlementPeriod         |-> [i \in 1 .. 2 |-> 0],
      additionalOrderFlags     |-> [i \in 1 .. 1 |-> 0],
      fifthReserved1           |-> [i \in 1 .. 1 |-> 0],
      filler116                |-> [i \in 1 .. 2 |-> 0],
      filler17                 |-> [i \in 1 .. 1 |-> 0],
      filler18                 |-> [i \in 1 .. 1 |-> 0],
      nnfField                 |-> [i \in 1 .. 8 |-> 0],
      mktReplay                |-> [i \in 1 .. 8 |-> 0],
      pan                      |-> [i \in 1 .. 10 |-> 0],
      algoId                   |-> [i \in 1 .. 4 |-> 0],
      secondReserved2          |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference    |-> [i \in 1 .. 8 |-> 0],
      reserved52               |-> [i \in 1 .. 52 |-> 0] ]

(* Order Entry Body at zero, then each field in turn at the values it is checked at *)
CheckedOrderEntryBody5 ==
    { ZeroOrderEntryBody5 }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.modifiedCancelledBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc5 }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.counterPartyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.closeoutFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.orderType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.buySellIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.disclosedVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.totalVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.minimumFillAonVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.proClientIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.settlementPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.filler116 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.filler17 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.filler18 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody5 EXCEPT !.reserved52 = one] : one \in Sample(52) }

(***************************************************************************)
(* Order Modification Confirmation Message: 276 bytes                      *)
(***************************************************************************)

OrderModificationConfirmationMessage ==
    [ orderEntryBody : OrderEntryBody5 ]

EncodeOrderModificationConfirmationMessage(message) ==
    EncodeOrderEntryBody5(message.orderEntryBody)

DecodeOrderModificationConfirmationMessage(bytes) ==
    LET orderEntryBody == DecodeOrderEntryBody5(bytes) IN IF ~orderEntryBody.ok THEN Fail ELSE
    Ok([ orderEntryBody |-> orderEntryBody.value ], orderEntryBody.rest)

ZeroOrderModificationConfirmationMessage ==
    [ orderEntryBody |-> ZeroOrderEntryBody5 ]

(* Order Modification Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModificationConfirmationMessage ==
    { ZeroOrderModificationConfirmationMessage }
        \cup { [ZeroOrderModificationConfirmationMessage EXCEPT !.orderEntryBody = one] : one \in CheckedOrderEntryBody5 }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc6 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc6(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc6(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         caLevel        |-> caLevel.value ], caLevel.rest)

ZeroContractDesc6 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc6 ==
    { ZeroContractDesc6 }
        \cup { [ZeroContractDesc6 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc6 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc6 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc6 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc6 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc6 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Order Entry Body: 276 bytes                                             *)
(***************************************************************************)

OrderEntryBody6 ==
    [ participantType          : Sample(1),
      reserved1                : Sample(1),
      competitorPeriod         : Sample(2),
      solicitorPeriod          : Sample(2),
      modifiedCancelledBy      : Sample(1),
      secondReserved1          : Sample(1),
      reasonCode               : Sample(2),
      reserved4                : Sample(4),
      tokenNo                  : Sample(4),
      contractDesc             : ContractDesc6,
      counterPartyBrokerId     : Sample(5),
      thirdReserved1           : Sample(1),
      reserved2                : Sample(2),
      closeoutFlag             : Sample(1),
      fourthReserved1          : Sample(1),
      orderType                : Sample(2),
      orderNumber              : Sample(8),
      accountNumber            : Sample(10),
      bookType                 : Sample(2),
      buySellIndicator         : Sample(2),
      disclosedVolume          : Sample(4),
      disclosedVolumeRemaining : Sample(4),
      totalVolumeRemaining     : Sample(4),
      volume                   : Sample(4),
      volumeFilledToday        : Sample(4),
      price                    : Sample(4),
      triggerPrice             : Sample(4),
      goodTillDate             : Sample(4),
      entryDateTime            : Sample(4),
      minimumFillAonVolume     : Sample(4),
      lastModified             : Sample(4),
      stOrderFlags             : Sample(2),
      branchId                 : Sample(2),
      traderId                 : Sample(4),
      brokerId                 : Sample(5),
      cOrdFiller               : Sample(24),
      openClose                : Sample(1),
      settlor                  : Sample(12),
      proClientIndicator       : Sample(2),
      settlementPeriod         : Sample(2),
      additionalOrderFlags     : Sample(1),
      fifthReserved1           : Sample(1),
      filler116                : Sample(2),
      filler17                 : Sample(1),
      filler18                 : Sample(1),
      nnfField                 : Sample(8),
      mktReplay                : Sample(8),
      pan                      : Sample(10),
      algoId                   : Sample(4),
      secondReserved2          : Sample(2),
      lastActivityReference    : Sample(8),
      reserved52               : Sample(52) ]

EncodeOrderEntryBody6(message) ==
    message.participantType
        \o message.reserved1
        \o message.competitorPeriod
        \o message.solicitorPeriod
        \o message.modifiedCancelledBy
        \o message.secondReserved1
        \o message.reasonCode
        \o message.reserved4
        \o message.tokenNo
        \o EncodeContractDesc6(message.contractDesc)
        \o message.counterPartyBrokerId
        \o message.thirdReserved1
        \o message.reserved2
        \o message.closeoutFlag
        \o message.fourthReserved1
        \o message.orderType
        \o message.orderNumber
        \o message.accountNumber
        \o message.bookType
        \o message.buySellIndicator
        \o message.disclosedVolume
        \o message.disclosedVolumeRemaining
        \o message.totalVolumeRemaining
        \o message.volume
        \o message.volumeFilledToday
        \o message.price
        \o message.triggerPrice
        \o message.goodTillDate
        \o message.entryDateTime
        \o message.minimumFillAonVolume
        \o message.lastModified
        \o message.stOrderFlags
        \o message.branchId
        \o message.traderId
        \o message.brokerId
        \o message.cOrdFiller
        \o message.openClose
        \o message.settlor
        \o message.proClientIndicator
        \o message.settlementPeriod
        \o message.additionalOrderFlags
        \o message.fifthReserved1
        \o message.filler116
        \o message.filler17
        \o message.filler18
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.secondReserved2
        \o message.lastActivityReference
        \o message.reserved52

DecodeOrderEntryBody6(bytes) ==
    LET participantType == ReadBytes(bytes, 1) IN IF ~participantType.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(participantType.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET competitorPeriod == ReadBytes(reserved1.rest, 2) IN IF ~competitorPeriod.ok THEN Fail ELSE
    LET solicitorPeriod == ReadBytes(competitorPeriod.rest, 2) IN IF ~solicitorPeriod.ok THEN Fail ELSE
    LET modifiedCancelledBy == ReadBytes(solicitorPeriod.rest, 1) IN IF ~modifiedCancelledBy.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(modifiedCancelledBy.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET reasonCode == ReadBytes(secondReserved1.rest, 2) IN IF ~reasonCode.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(reasonCode.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET tokenNo == ReadBytes(reserved4.rest, 4) IN IF ~tokenNo.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc6(tokenNo.rest) IN IF ~contractDesc.ok THEN Fail ELSE
    LET counterPartyBrokerId == ReadBytes(contractDesc.rest, 5) IN IF ~counterPartyBrokerId.ok THEN Fail ELSE
    LET thirdReserved1 == ReadBytes(counterPartyBrokerId.rest, 1) IN IF ~thirdReserved1.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(thirdReserved1.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET closeoutFlag == ReadBytes(reserved2.rest, 1) IN IF ~closeoutFlag.ok THEN Fail ELSE
    LET fourthReserved1 == ReadBytes(closeoutFlag.rest, 1) IN IF ~fourthReserved1.ok THEN Fail ELSE
    LET orderType == ReadBytes(fourthReserved1.rest, 2) IN IF ~orderType.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(orderType.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(orderNumber.rest, 10) IN IF ~accountNumber.ok THEN Fail ELSE
    LET bookType == ReadBytes(accountNumber.rest, 2) IN IF ~bookType.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(bookType.rest, 2) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET disclosedVolume == ReadBytes(buySellIndicator.rest, 4) IN IF ~disclosedVolume.ok THEN Fail ELSE
    LET disclosedVolumeRemaining == ReadBytes(disclosedVolume.rest, 4) IN IF ~disclosedVolumeRemaining.ok THEN Fail ELSE
    LET totalVolumeRemaining == ReadBytes(disclosedVolumeRemaining.rest, 4) IN IF ~totalVolumeRemaining.ok THEN Fail ELSE
    LET volume == ReadBytes(totalVolumeRemaining.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET volumeFilledToday == ReadBytes(volume.rest, 4) IN IF ~volumeFilledToday.ok THEN Fail ELSE
    LET price == ReadBytes(volumeFilledToday.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET triggerPrice == ReadBytes(price.rest, 4) IN IF ~triggerPrice.ok THEN Fail ELSE
    LET goodTillDate == ReadBytes(triggerPrice.rest, 4) IN IF ~goodTillDate.ok THEN Fail ELSE
    LET entryDateTime == ReadBytes(goodTillDate.rest, 4) IN IF ~entryDateTime.ok THEN Fail ELSE
    LET minimumFillAonVolume == ReadBytes(entryDateTime.rest, 4) IN IF ~minimumFillAonVolume.ok THEN Fail ELSE
    LET lastModified == ReadBytes(minimumFillAonVolume.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET traderId == ReadBytes(branchId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(traderId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET cOrdFiller == ReadBytes(brokerId.rest, 24) IN IF ~cOrdFiller.ok THEN Fail ELSE
    LET openClose == ReadBytes(cOrdFiller.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET settlor == ReadBytes(openClose.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClientIndicator == ReadBytes(settlor.rest, 2) IN IF ~proClientIndicator.ok THEN Fail ELSE
    LET settlementPeriod == ReadBytes(proClientIndicator.rest, 2) IN IF ~settlementPeriod.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(settlementPeriod.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET fifthReserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~fifthReserved1.ok THEN Fail ELSE
    LET filler116 == ReadBytes(fifthReserved1.rest, 2) IN IF ~filler116.ok THEN Fail ELSE
    LET filler17 == ReadBytes(filler116.rest, 1) IN IF ~filler17.ok THEN Fail ELSE
    LET filler18 == ReadBytes(filler17.rest, 1) IN IF ~filler18.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler18.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET mktReplay == ReadBytes(nnfField.rest, 8) IN IF ~mktReplay.ok THEN Fail ELSE
    LET pan == ReadBytes(mktReplay.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(algoId.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(secondReserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    Ok([ participantType          |-> participantType.value,
         reserved1                |-> reserved1.value,
         competitorPeriod         |-> competitorPeriod.value,
         solicitorPeriod          |-> solicitorPeriod.value,
         modifiedCancelledBy      |-> modifiedCancelledBy.value,
         secondReserved1          |-> secondReserved1.value,
         reasonCode               |-> reasonCode.value,
         reserved4                |-> reserved4.value,
         tokenNo                  |-> tokenNo.value,
         contractDesc             |-> contractDesc.value,
         counterPartyBrokerId     |-> counterPartyBrokerId.value,
         thirdReserved1           |-> thirdReserved1.value,
         reserved2                |-> reserved2.value,
         closeoutFlag             |-> closeoutFlag.value,
         fourthReserved1          |-> fourthReserved1.value,
         orderType                |-> orderType.value,
         orderNumber              |-> orderNumber.value,
         accountNumber            |-> accountNumber.value,
         bookType                 |-> bookType.value,
         buySellIndicator         |-> buySellIndicator.value,
         disclosedVolume          |-> disclosedVolume.value,
         disclosedVolumeRemaining |-> disclosedVolumeRemaining.value,
         totalVolumeRemaining     |-> totalVolumeRemaining.value,
         volume                   |-> volume.value,
         volumeFilledToday        |-> volumeFilledToday.value,
         price                    |-> price.value,
         triggerPrice             |-> triggerPrice.value,
         goodTillDate             |-> goodTillDate.value,
         entryDateTime            |-> entryDateTime.value,
         minimumFillAonVolume     |-> minimumFillAonVolume.value,
         lastModified             |-> lastModified.value,
         stOrderFlags             |-> stOrderFlags.value,
         branchId                 |-> branchId.value,
         traderId                 |-> traderId.value,
         brokerId                 |-> brokerId.value,
         cOrdFiller               |-> cOrdFiller.value,
         openClose                |-> openClose.value,
         settlor                  |-> settlor.value,
         proClientIndicator       |-> proClientIndicator.value,
         settlementPeriod         |-> settlementPeriod.value,
         additionalOrderFlags     |-> additionalOrderFlags.value,
         fifthReserved1           |-> fifthReserved1.value,
         filler116                |-> filler116.value,
         filler17                 |-> filler17.value,
         filler18                 |-> filler18.value,
         nnfField                 |-> nnfField.value,
         mktReplay                |-> mktReplay.value,
         pan                      |-> pan.value,
         algoId                   |-> algoId.value,
         secondReserved2          |-> secondReserved2.value,
         lastActivityReference    |-> lastActivityReference.value,
         reserved52               |-> reserved52.value ], reserved52.rest)

ZeroOrderEntryBody6 ==
    [ participantType          |-> [i \in 1 .. 1 |-> 0],
      reserved1                |-> [i \in 1 .. 1 |-> 0],
      competitorPeriod         |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod          |-> [i \in 1 .. 2 |-> 0],
      modifiedCancelledBy      |-> [i \in 1 .. 1 |-> 0],
      secondReserved1          |-> [i \in 1 .. 1 |-> 0],
      reasonCode               |-> [i \in 1 .. 2 |-> 0],
      reserved4                |-> [i \in 1 .. 4 |-> 0],
      tokenNo                  |-> [i \in 1 .. 4 |-> 0],
      contractDesc             |-> ZeroContractDesc6,
      counterPartyBrokerId     |-> [i \in 1 .. 5 |-> 0],
      thirdReserved1           |-> [i \in 1 .. 1 |-> 0],
      reserved2                |-> [i \in 1 .. 2 |-> 0],
      closeoutFlag             |-> [i \in 1 .. 1 |-> 0],
      fourthReserved1          |-> [i \in 1 .. 1 |-> 0],
      orderType                |-> [i \in 1 .. 2 |-> 0],
      orderNumber              |-> [i \in 1 .. 8 |-> 0],
      accountNumber            |-> [i \in 1 .. 10 |-> 0],
      bookType                 |-> [i \in 1 .. 2 |-> 0],
      buySellIndicator         |-> [i \in 1 .. 2 |-> 0],
      disclosedVolume          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolumeRemaining |-> [i \in 1 .. 4 |-> 0],
      totalVolumeRemaining     |-> [i \in 1 .. 4 |-> 0],
      volume                   |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday        |-> [i \in 1 .. 4 |-> 0],
      price                    |-> [i \in 1 .. 4 |-> 0],
      triggerPrice             |-> [i \in 1 .. 4 |-> 0],
      goodTillDate             |-> [i \in 1 .. 4 |-> 0],
      entryDateTime            |-> [i \in 1 .. 4 |-> 0],
      minimumFillAonVolume     |-> [i \in 1 .. 4 |-> 0],
      lastModified             |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags             |-> [i \in 1 .. 2 |-> 0],
      branchId                 |-> [i \in 1 .. 2 |-> 0],
      traderId                 |-> [i \in 1 .. 4 |-> 0],
      brokerId                 |-> [i \in 1 .. 5 |-> 0],
      cOrdFiller               |-> [i \in 1 .. 24 |-> 0],
      openClose                |-> [i \in 1 .. 1 |-> 0],
      settlor                  |-> [i \in 1 .. 12 |-> 0],
      proClientIndicator       |-> [i \in 1 .. 2 |-> 0],
      settlementPeriod         |-> [i \in 1 .. 2 |-> 0],
      additionalOrderFlags     |-> [i \in 1 .. 1 |-> 0],
      fifthReserved1           |-> [i \in 1 .. 1 |-> 0],
      filler116                |-> [i \in 1 .. 2 |-> 0],
      filler17                 |-> [i \in 1 .. 1 |-> 0],
      filler18                 |-> [i \in 1 .. 1 |-> 0],
      nnfField                 |-> [i \in 1 .. 8 |-> 0],
      mktReplay                |-> [i \in 1 .. 8 |-> 0],
      pan                      |-> [i \in 1 .. 10 |-> 0],
      algoId                   |-> [i \in 1 .. 4 |-> 0],
      secondReserved2          |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference    |-> [i \in 1 .. 8 |-> 0],
      reserved52               |-> [i \in 1 .. 52 |-> 0] ]

(* Order Entry Body at zero, then each field in turn at the values it is checked at *)
CheckedOrderEntryBody6 ==
    { ZeroOrderEntryBody6 }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.modifiedCancelledBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc6 }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.counterPartyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.closeoutFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.orderType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.buySellIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.disclosedVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.totalVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.minimumFillAonVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.proClientIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.settlementPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.filler116 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.filler17 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.filler18 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryBody6 EXCEPT !.reserved52 = one] : one \in Sample(52) }

(***************************************************************************)
(* Order Entry Message: 276 bytes                                          *)
(***************************************************************************)

OrderEntryMessage ==
    [ orderEntryBody : OrderEntryBody6 ]

EncodeOrderEntryMessage(message) ==
    EncodeOrderEntryBody6(message.orderEntryBody)

DecodeOrderEntryMessage(bytes) ==
    LET orderEntryBody == DecodeOrderEntryBody6(bytes) IN IF ~orderEntryBody.ok THEN Fail ELSE
    Ok([ orderEntryBody |-> orderEntryBody.value ], orderEntryBody.rest)

ZeroOrderEntryMessage ==
    [ orderEntryBody |-> ZeroOrderEntryBody6 ]

(* Order Entry Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderEntryMessage ==
    { ZeroOrderEntryMessage }
        \cup { [ZeroOrderEntryMessage EXCEPT !.orderEntryBody = one] : one \in CheckedOrderEntryBody6 }

(***************************************************************************)
(* Price Modification Message: 66 bytes                                    *)
(***************************************************************************)

PriceModificationMessage ==
    [ tokenNo               : Sample(4),
      traderId              : Sample(4),
      orderNumber           : Sample(8),
      buySell               : Sample(2),
      price                 : Sample(4),
      volume                : Sample(4),
      lastModified          : Sample(4),
      reference             : Sample(4),
      lastActivityReference : Sample(8),
      reserved24            : Sample(24) ]

EncodePriceModificationMessage(message) ==
    message.tokenNo
        \o message.traderId
        \o message.orderNumber
        \o message.buySell
        \o message.price
        \o message.volume
        \o message.lastModified
        \o message.reference
        \o message.lastActivityReference
        \o message.reserved24

DecodePriceModificationMessage(bytes) ==
    LET tokenNo == ReadBytes(bytes, 4) IN IF ~tokenNo.ok THEN Fail ELSE
    LET traderId == ReadBytes(tokenNo.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET orderNumber == ReadBytes(traderId.rest, 8) IN IF ~orderNumber.ok THEN Fail ELSE
    LET buySell == ReadBytes(orderNumber.rest, 2) IN IF ~buySell.ok THEN Fail ELSE
    LET price == ReadBytes(buySell.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET volume == ReadBytes(price.rest, 4) IN IF ~volume.ok THEN Fail ELSE
    LET lastModified == ReadBytes(volume.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET reference == ReadBytes(lastModified.rest, 4) IN IF ~reference.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(reference.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved24 == ReadBytes(lastActivityReference.rest, 24) IN IF ~reserved24.ok THEN Fail ELSE
    Ok([ tokenNo               |-> tokenNo.value,
         traderId              |-> traderId.value,
         orderNumber           |-> orderNumber.value,
         buySell               |-> buySell.value,
         price                 |-> price.value,
         volume                |-> volume.value,
         lastModified          |-> lastModified.value,
         reference             |-> reference.value,
         lastActivityReference |-> lastActivityReference.value,
         reserved24            |-> reserved24.value ], reserved24.rest)

ZeroPriceModificationMessage ==
    [ tokenNo               |-> [i \in 1 .. 4 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      orderNumber           |-> [i \in 1 .. 8 |-> 0],
      buySell               |-> [i \in 1 .. 2 |-> 0],
      price                 |-> [i \in 1 .. 4 |-> 0],
      volume                |-> [i \in 1 .. 4 |-> 0],
      lastModified          |-> [i \in 1 .. 4 |-> 0],
      reference             |-> [i \in 1 .. 4 |-> 0],
      lastActivityReference |-> [i \in 1 .. 8 |-> 0],
      reserved24            |-> [i \in 1 .. 24 |-> 0] ]

(* Price Modification Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceModificationMessage ==
    { ZeroPriceModificationMessage }
        \cup { [ZeroPriceModificationMessage EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroPriceModificationMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroPriceModificationMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroPriceModificationMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroPriceModificationMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroPriceModificationMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroPriceModificationMessage EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroPriceModificationMessage EXCEPT !.reference = one] : one \in Sample(4) }
        \cup { [ZeroPriceModificationMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroPriceModificationMessage EXCEPT !.reserved24 = one] : one \in Sample(24) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc7 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc7(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc7(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         caLevel        |-> caLevel.value ], caLevel.rest)

ZeroContractDesc7 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc7 ==
    { ZeroContractDesc7 }
        \cup { [ZeroContractDesc7 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc7 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc7 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc7 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc7 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc7 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Inquiry Message: 194 bytes                                        *)
(***************************************************************************)

TradeInquiryMessage ==
    [ tokenNo           : Sample(4),
      contractDesc      : ContractDesc7,
      fillNumber        : Sample(4),
      fillQuantity      : Sample(4),
      fillPrice         : Sample(4),
      mktType           : Sample(1),
      buyOpenClose      : Sample(1),
      reserved4         : Sample(4),
      buyBrokerId       : Sample(5),
      sellBrokerId      : Sample(5),
      traderId          : Sample(4),
      requestedBy       : Sample(1),
      sellOpenClose     : Sample(1),
      buyAccountNumber  : Sample(10),
      sellAccountNumber : Sample(10),
      reserved24        : Sample(24),
      reserved2         : Sample(2),
      secondReserved2   : Sample(2),
      buyPan            : Sample(10),
      sellPan           : Sample(10),
      reserved60        : Sample(60) ]

EncodeTradeInquiryMessage(message) ==
    message.tokenNo
        \o EncodeContractDesc7(message.contractDesc)
        \o message.fillNumber
        \o message.fillQuantity
        \o message.fillPrice
        \o message.mktType
        \o message.buyOpenClose
        \o message.reserved4
        \o message.buyBrokerId
        \o message.sellBrokerId
        \o message.traderId
        \o message.requestedBy
        \o message.sellOpenClose
        \o message.buyAccountNumber
        \o message.sellAccountNumber
        \o message.reserved24
        \o message.reserved2
        \o message.secondReserved2
        \o message.buyPan
        \o message.sellPan
        \o message.reserved60

DecodeTradeInquiryMessage(bytes) ==
    LET tokenNo == ReadBytes(bytes, 4) IN IF ~tokenNo.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc7(tokenNo.rest) IN IF ~contractDesc.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(contractDesc.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQuantity == ReadBytes(fillNumber.rest, 4) IN IF ~fillQuantity.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQuantity.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET mktType == ReadBytes(fillPrice.rest, 1) IN IF ~mktType.ok THEN Fail ELSE
    LET buyOpenClose == ReadBytes(mktType.rest, 1) IN IF ~buyOpenClose.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(buyOpenClose.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET buyBrokerId == ReadBytes(reserved4.rest, 5) IN IF ~buyBrokerId.ok THEN Fail ELSE
    LET sellBrokerId == ReadBytes(buyBrokerId.rest, 5) IN IF ~sellBrokerId.ok THEN Fail ELSE
    LET traderId == ReadBytes(sellBrokerId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET requestedBy == ReadBytes(traderId.rest, 1) IN IF ~requestedBy.ok THEN Fail ELSE
    LET sellOpenClose == ReadBytes(requestedBy.rest, 1) IN IF ~sellOpenClose.ok THEN Fail ELSE
    LET buyAccountNumber == ReadBytes(sellOpenClose.rest, 10) IN IF ~buyAccountNumber.ok THEN Fail ELSE
    LET sellAccountNumber == ReadBytes(buyAccountNumber.rest, 10) IN IF ~sellAccountNumber.ok THEN Fail ELSE
    LET reserved24 == ReadBytes(sellAccountNumber.rest, 24) IN IF ~reserved24.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(reserved24.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(reserved2.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET buyPan == ReadBytes(secondReserved2.rest, 10) IN IF ~buyPan.ok THEN Fail ELSE
    LET sellPan == ReadBytes(buyPan.rest, 10) IN IF ~sellPan.ok THEN Fail ELSE
    LET reserved60 == ReadBytes(sellPan.rest, 60) IN IF ~reserved60.ok THEN Fail ELSE
    Ok([ tokenNo           |-> tokenNo.value,
         contractDesc      |-> contractDesc.value,
         fillNumber        |-> fillNumber.value,
         fillQuantity      |-> fillQuantity.value,
         fillPrice         |-> fillPrice.value,
         mktType           |-> mktType.value,
         buyOpenClose      |-> buyOpenClose.value,
         reserved4         |-> reserved4.value,
         buyBrokerId       |-> buyBrokerId.value,
         sellBrokerId      |-> sellBrokerId.value,
         traderId          |-> traderId.value,
         requestedBy       |-> requestedBy.value,
         sellOpenClose     |-> sellOpenClose.value,
         buyAccountNumber  |-> buyAccountNumber.value,
         sellAccountNumber |-> sellAccountNumber.value,
         reserved24        |-> reserved24.value,
         reserved2         |-> reserved2.value,
         secondReserved2   |-> secondReserved2.value,
         buyPan            |-> buyPan.value,
         sellPan           |-> sellPan.value,
         reserved60        |-> reserved60.value ], reserved60.rest)

ZeroTradeInquiryMessage ==
    [ tokenNo           |-> [i \in 1 .. 4 |-> 0],
      contractDesc      |-> ZeroContractDesc7,
      fillNumber        |-> [i \in 1 .. 4 |-> 0],
      fillQuantity      |-> [i \in 1 .. 4 |-> 0],
      fillPrice         |-> [i \in 1 .. 4 |-> 0],
      mktType           |-> [i \in 1 .. 1 |-> 0],
      buyOpenClose      |-> [i \in 1 .. 1 |-> 0],
      reserved4         |-> [i \in 1 .. 4 |-> 0],
      buyBrokerId       |-> [i \in 1 .. 5 |-> 0],
      sellBrokerId      |-> [i \in 1 .. 5 |-> 0],
      traderId          |-> [i \in 1 .. 4 |-> 0],
      requestedBy       |-> [i \in 1 .. 1 |-> 0],
      sellOpenClose     |-> [i \in 1 .. 1 |-> 0],
      buyAccountNumber  |-> [i \in 1 .. 10 |-> 0],
      sellAccountNumber |-> [i \in 1 .. 10 |-> 0],
      reserved24        |-> [i \in 1 .. 24 |-> 0],
      reserved2         |-> [i \in 1 .. 2 |-> 0],
      secondReserved2   |-> [i \in 1 .. 2 |-> 0],
      buyPan            |-> [i \in 1 .. 10 |-> 0],
      sellPan           |-> [i \in 1 .. 10 |-> 0],
      reserved60        |-> [i \in 1 .. 60 |-> 0] ]

(* Trade Inquiry Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeInquiryMessage ==
    { ZeroTradeInquiryMessage }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc7 }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.fillQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.mktType = one] : one \in Sample(1) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.buyOpenClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.buyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.sellBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.requestedBy = one] : one \in Sample(1) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.sellOpenClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.buyAccountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.sellAccountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.reserved24 = one] : one \in Sample(24) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.buyPan = one] : one \in Sample(10) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.sellPan = one] : one \in Sample(10) }
        \cup { [ZeroTradeInquiryMessage EXCEPT !.reserved60 = one] : one \in Sample(60) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc8 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc8(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc8(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         caLevel        |-> caLevel.value ], caLevel.rest)

ZeroContractDesc8 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc8 ==
    { ZeroContractDesc8 }
        \cup { [ZeroContractDesc8 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc8 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc8 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc8 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc8 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc8 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc9 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc9(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc9(bytes) ==
    LET instrumentName == ReadBytes(bytes, 6) IN IF ~instrumentName.ok THEN Fail ELSE
    LET symbol == ReadBytes(instrumentName.rest, 10) IN IF ~symbol.ok THEN Fail ELSE
    LET expiryDate == ReadBytes(symbol.rest, 4) IN IF ~expiryDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expiryDate.rest, 4) IN IF ~strikePrice.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePrice.rest, 2) IN IF ~optionType.ok THEN Fail ELSE
    LET caLevel == ReadBytes(optionType.rest, 2) IN IF ~caLevel.ok THEN Fail ELSE
    Ok([ instrumentName |-> instrumentName.value,
         symbol         |-> symbol.value,
         expiryDate     |-> expiryDate.value,
         strikePrice    |-> strikePrice.value,
         optionType     |-> optionType.value,
         caLevel        |-> caLevel.value ], caLevel.rest)

ZeroContractDesc9 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc9 ==
    { ZeroContractDesc9 }
        \cup { [ZeroContractDesc9 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc9 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc9 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc9 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc9 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc9 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Ms Spd Leg Info: 80 bytes                                               *)
(***************************************************************************)

MsSpdLegInfo ==
    [ token2                 : Sample(4),
      contractDesc           : ContractDesc9,
      opBrokerId2            : Sample(5),
      fillerx2               : Sample(1),
      orderType2             : Sample(2),
      buySell2               : Sample(2),
      disclosedVol2          : Sample(4),
      disclosedVolRemaining2 : Sample(4),
      totalVolRemaining2     : Sample(4),
      volume2                : Sample(4),
      volumeFilledToday2     : Sample(4),
      price2                 : Sample(4),
      triggerPrice2          : Sample(4),
      minFillAon2            : Sample(4),
      stOrderFlags           : Sample(2),
      openClose2             : Sample(1),
      additionalOrderFlags   : Sample(1),
      reserved1              : Sample(1),
      fillerY                : Sample(1) ]

EncodeMsSpdLegInfo(message) ==
    message.token2
        \o EncodeContractDesc9(message.contractDesc)
        \o message.opBrokerId2
        \o message.fillerx2
        \o message.orderType2
        \o message.buySell2
        \o message.disclosedVol2
        \o message.disclosedVolRemaining2
        \o message.totalVolRemaining2
        \o message.volume2
        \o message.volumeFilledToday2
        \o message.price2
        \o message.triggerPrice2
        \o message.minFillAon2
        \o message.stOrderFlags
        \o message.openClose2
        \o message.additionalOrderFlags
        \o message.reserved1
        \o message.fillerY

DecodeMsSpdLegInfo(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc9(token2.rest) IN IF ~contractDesc.ok THEN Fail ELSE
    LET opBrokerId2 == ReadBytes(contractDesc.rest, 5) IN IF ~opBrokerId2.ok THEN Fail ELSE
    LET fillerx2 == ReadBytes(opBrokerId2.rest, 1) IN IF ~fillerx2.ok THEN Fail ELSE
    LET orderType2 == ReadBytes(fillerx2.rest, 2) IN IF ~orderType2.ok THEN Fail ELSE
    LET buySell2 == ReadBytes(orderType2.rest, 2) IN IF ~buySell2.ok THEN Fail ELSE
    LET disclosedVol2 == ReadBytes(buySell2.rest, 4) IN IF ~disclosedVol2.ok THEN Fail ELSE
    LET disclosedVolRemaining2 == ReadBytes(disclosedVol2.rest, 4) IN IF ~disclosedVolRemaining2.ok THEN Fail ELSE
    LET totalVolRemaining2 == ReadBytes(disclosedVolRemaining2.rest, 4) IN IF ~totalVolRemaining2.ok THEN Fail ELSE
    LET volume2 == ReadBytes(totalVolRemaining2.rest, 4) IN IF ~volume2.ok THEN Fail ELSE
    LET volumeFilledToday2 == ReadBytes(volume2.rest, 4) IN IF ~volumeFilledToday2.ok THEN Fail ELSE
    LET price2 == ReadBytes(volumeFilledToday2.rest, 4) IN IF ~price2.ok THEN Fail ELSE
    LET triggerPrice2 == ReadBytes(price2.rest, 4) IN IF ~triggerPrice2.ok THEN Fail ELSE
    LET minFillAon2 == ReadBytes(triggerPrice2.rest, 4) IN IF ~minFillAon2.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(minFillAon2.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET openClose2 == ReadBytes(stOrderFlags.rest, 1) IN IF ~openClose2.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(openClose2.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET fillerY == ReadBytes(reserved1.rest, 1) IN IF ~fillerY.ok THEN Fail ELSE
    Ok([ token2                 |-> token2.value,
         contractDesc           |-> contractDesc.value,
         opBrokerId2            |-> opBrokerId2.value,
         fillerx2               |-> fillerx2.value,
         orderType2             |-> orderType2.value,
         buySell2               |-> buySell2.value,
         disclosedVol2          |-> disclosedVol2.value,
         disclosedVolRemaining2 |-> disclosedVolRemaining2.value,
         totalVolRemaining2     |-> totalVolRemaining2.value,
         volume2                |-> volume2.value,
         volumeFilledToday2     |-> volumeFilledToday2.value,
         price2                 |-> price2.value,
         triggerPrice2          |-> triggerPrice2.value,
         minFillAon2            |-> minFillAon2.value,
         stOrderFlags           |-> stOrderFlags.value,
         openClose2             |-> openClose2.value,
         additionalOrderFlags   |-> additionalOrderFlags.value,
         reserved1              |-> reserved1.value,
         fillerY                |-> fillerY.value ], fillerY.rest)

ZeroMsSpdLegInfo ==
    [ token2                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc           |-> ZeroContractDesc9,
      opBrokerId2            |-> [i \in 1 .. 5 |-> 0],
      fillerx2               |-> [i \in 1 .. 1 |-> 0],
      orderType2             |-> [i \in 1 .. 2 |-> 0],
      buySell2               |-> [i \in 1 .. 2 |-> 0],
      disclosedVol2          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining2 |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining2     |-> [i \in 1 .. 4 |-> 0],
      volume2                |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday2     |-> [i \in 1 .. 4 |-> 0],
      price2                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice2          |-> [i \in 1 .. 4 |-> 0],
      minFillAon2            |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags           |-> [i \in 1 .. 2 |-> 0],
      openClose2             |-> [i \in 1 .. 1 |-> 0],
      additionalOrderFlags   |-> [i \in 1 .. 1 |-> 0],
      reserved1              |-> [i \in 1 .. 1 |-> 0],
      fillerY                |-> [i \in 1 .. 1 |-> 0] ]

(* Ms Spd Leg Info at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfo ==
    { ZeroMsSpdLegInfo }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.contractDesc = one] : one \in CheckedContractDesc9 }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.opBrokerId2 = one] : one \in Sample(5) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.fillerx2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.orderType2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.disclosedVol2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.disclosedVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.volumeFilledToday2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.price2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.triggerPrice2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.minFillAon2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfo EXCEPT !.fillerY = one] : one \in Sample(1) }

(* A run of Ms Spd Leg Info, written one after another *)
RECURSIVE EncodeMsSpdLegInfoList(_)
EncodeMsSpdLegInfoList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMsSpdLegInfo(Head(messages)) \o EncodeMsSpdLegInfoList(Tail(messages))

(* As many Ms Spd Leg Info as the field that counts them says *)
RECURSIVE ReadMsSpdLegInfoList(_, _)
ReadMsSpdLegInfoList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMsSpdLegInfo(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMsSpdLegInfoList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Ms Spd Leg Info of each kind, for the lists that carry them *)
OneMsSpdLegInfo == { ZeroMsSpdLegInfo }

(* The 2 slots a run of Ms Spd Leg Info is written as, whatever the field beside it says are in use *)
SlotsMsSpdLegInfo == { [i \in 1 .. 2 |-> one] : one \in OneMsSpdLegInfo }

(***************************************************************************)
(* Spread Order Body                                                       *)
(***************************************************************************)

SpreadOrderBody ==
    [ participantType1       : Sample(1),
      filler1                : Sample(1),
      competitorPeriod1      : Sample(2),
      solicitorPeriod1       : Sample(2),
      modCxlBy1              : Sample(1),
      filler9                : Sample(1),
      reasonCode1            : Sample(2),
      startAlpha1            : Sample(2),
      endAlpha1              : Sample(2),
      token1                 : Sample(4),
      contractDesc           : ContractDesc8,
      opBrokerId1            : Sample(5),
      fillerx1               : Sample(1),
      fillerOptions1         : Sample(3),
      fillery1               : Sample(1),
      orderType1             : Sample(2),
      orderNumber1           : Sample(8),
      accountNumber1         : Sample(10),
      bookType1              : Sample(2),
      buySell1               : Sample(2),
      disclosedVol1          : Sample(4),
      disclosedVolRemaining1 : Sample(4),
      totalVolRemaining1     : Sample(4),
      volume1                : Sample(4),
      volumeFilledToday1     : Sample(4),
      price1                 : Sample(4),
      triggerPrice1          : Sample(4),
      goodTillDate1          : Sample(4),
      entryDateTime1         : Sample(4),
      minFillAon1            : Sample(4),
      lastModified1          : Sample(4),
      stOrderFlags           : Sample(2),
      branchId1              : Sample(2),
      traderId1              : Sample(4),
      brokerId1              : Sample(5),
      cOrdFiller             : Sample(24),
      openClose1             : Sample(1),
      settlor1               : Sample(12),
      proClient1             : Sample(2),
      settlementPeriod1      : Sample(2),
      additionalOrderFlags   : Sample(1),
      reserved1              : Sample(1),
      filler116              : Sample(2),
      filler17               : Sample(1),
      filler18               : Sample(1),
      nnfField               : Sample(8),
      mktReplay              : Sample(8),
      pan                    : Sample(10),
      algoId                 : Sample(4),
      reserved2              : Sample(2),
      lastActivityReference  : Sample(8),
      reserved52             : Sample(52),
      priceDiff              : Sample(4),
      msSpdLegInfo           : SlotsMsSpdLegInfo ]

EncodeSpreadOrderBody(message) ==
    message.participantType1
        \o message.filler1
        \o message.competitorPeriod1
        \o message.solicitorPeriod1
        \o message.modCxlBy1
        \o message.filler9
        \o message.reasonCode1
        \o message.startAlpha1
        \o message.endAlpha1
        \o message.token1
        \o EncodeContractDesc8(message.contractDesc)
        \o message.opBrokerId1
        \o message.fillerx1
        \o message.fillerOptions1
        \o message.fillery1
        \o message.orderType1
        \o message.orderNumber1
        \o message.accountNumber1
        \o message.bookType1
        \o message.buySell1
        \o message.disclosedVol1
        \o message.disclosedVolRemaining1
        \o message.totalVolRemaining1
        \o message.volume1
        \o message.volumeFilledToday1
        \o message.price1
        \o message.triggerPrice1
        \o message.goodTillDate1
        \o message.entryDateTime1
        \o message.minFillAon1
        \o message.lastModified1
        \o message.stOrderFlags
        \o message.branchId1
        \o message.traderId1
        \o message.brokerId1
        \o message.cOrdFiller
        \o message.openClose1
        \o message.settlor1
        \o message.proClient1
        \o message.settlementPeriod1
        \o message.additionalOrderFlags
        \o message.reserved1
        \o message.filler116
        \o message.filler17
        \o message.filler18
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.reserved2
        \o message.lastActivityReference
        \o message.reserved52
        \o message.priceDiff
        \o EncodeMsSpdLegInfoList(message.msSpdLegInfo)

DecodeSpreadOrderBody(bytes) ==
    LET participantType1 == ReadBytes(bytes, 1) IN IF ~participantType1.ok THEN Fail ELSE
    LET filler1 == ReadBytes(participantType1.rest, 1) IN IF ~filler1.ok THEN Fail ELSE
    LET competitorPeriod1 == ReadBytes(filler1.rest, 2) IN IF ~competitorPeriod1.ok THEN Fail ELSE
    LET solicitorPeriod1 == ReadBytes(competitorPeriod1.rest, 2) IN IF ~solicitorPeriod1.ok THEN Fail ELSE
    LET modCxlBy1 == ReadBytes(solicitorPeriod1.rest, 1) IN IF ~modCxlBy1.ok THEN Fail ELSE
    LET filler9 == ReadBytes(modCxlBy1.rest, 1) IN IF ~filler9.ok THEN Fail ELSE
    LET reasonCode1 == ReadBytes(filler9.rest, 2) IN IF ~reasonCode1.ok THEN Fail ELSE
    LET startAlpha1 == ReadBytes(reasonCode1.rest, 2) IN IF ~startAlpha1.ok THEN Fail ELSE
    LET endAlpha1 == ReadBytes(startAlpha1.rest, 2) IN IF ~endAlpha1.ok THEN Fail ELSE
    LET token1 == ReadBytes(endAlpha1.rest, 4) IN IF ~token1.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc8(token1.rest) IN IF ~contractDesc.ok THEN Fail ELSE
    LET opBrokerId1 == ReadBytes(contractDesc.rest, 5) IN IF ~opBrokerId1.ok THEN Fail ELSE
    LET fillerx1 == ReadBytes(opBrokerId1.rest, 1) IN IF ~fillerx1.ok THEN Fail ELSE
    LET fillerOptions1 == ReadBytes(fillerx1.rest, 3) IN IF ~fillerOptions1.ok THEN Fail ELSE
    LET fillery1 == ReadBytes(fillerOptions1.rest, 1) IN IF ~fillery1.ok THEN Fail ELSE
    LET orderType1 == ReadBytes(fillery1.rest, 2) IN IF ~orderType1.ok THEN Fail ELSE
    LET orderNumber1 == ReadBytes(orderType1.rest, 8) IN IF ~orderNumber1.ok THEN Fail ELSE
    LET accountNumber1 == ReadBytes(orderNumber1.rest, 10) IN IF ~accountNumber1.ok THEN Fail ELSE
    LET bookType1 == ReadBytes(accountNumber1.rest, 2) IN IF ~bookType1.ok THEN Fail ELSE
    LET buySell1 == ReadBytes(bookType1.rest, 2) IN IF ~buySell1.ok THEN Fail ELSE
    LET disclosedVol1 == ReadBytes(buySell1.rest, 4) IN IF ~disclosedVol1.ok THEN Fail ELSE
    LET disclosedVolRemaining1 == ReadBytes(disclosedVol1.rest, 4) IN IF ~disclosedVolRemaining1.ok THEN Fail ELSE
    LET totalVolRemaining1 == ReadBytes(disclosedVolRemaining1.rest, 4) IN IF ~totalVolRemaining1.ok THEN Fail ELSE
    LET volume1 == ReadBytes(totalVolRemaining1.rest, 4) IN IF ~volume1.ok THEN Fail ELSE
    LET volumeFilledToday1 == ReadBytes(volume1.rest, 4) IN IF ~volumeFilledToday1.ok THEN Fail ELSE
    LET price1 == ReadBytes(volumeFilledToday1.rest, 4) IN IF ~price1.ok THEN Fail ELSE
    LET triggerPrice1 == ReadBytes(price1.rest, 4) IN IF ~triggerPrice1.ok THEN Fail ELSE
    LET goodTillDate1 == ReadBytes(triggerPrice1.rest, 4) IN IF ~goodTillDate1.ok THEN Fail ELSE
    LET entryDateTime1 == ReadBytes(goodTillDate1.rest, 4) IN IF ~entryDateTime1.ok THEN Fail ELSE
    LET minFillAon1 == ReadBytes(entryDateTime1.rest, 4) IN IF ~minFillAon1.ok THEN Fail ELSE
    LET lastModified1 == ReadBytes(minFillAon1.rest, 4) IN IF ~lastModified1.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified1.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId1 == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId1.ok THEN Fail ELSE
    LET traderId1 == ReadBytes(branchId1.rest, 4) IN IF ~traderId1.ok THEN Fail ELSE
    LET brokerId1 == ReadBytes(traderId1.rest, 5) IN IF ~brokerId1.ok THEN Fail ELSE
    LET cOrdFiller == ReadBytes(brokerId1.rest, 24) IN IF ~cOrdFiller.ok THEN Fail ELSE
    LET openClose1 == ReadBytes(cOrdFiller.rest, 1) IN IF ~openClose1.ok THEN Fail ELSE
    LET settlor1 == ReadBytes(openClose1.rest, 12) IN IF ~settlor1.ok THEN Fail ELSE
    LET proClient1 == ReadBytes(settlor1.rest, 2) IN IF ~proClient1.ok THEN Fail ELSE
    LET settlementPeriod1 == ReadBytes(proClient1.rest, 2) IN IF ~settlementPeriod1.ok THEN Fail ELSE
    LET additionalOrderFlags == ReadBytes(settlementPeriod1.rest, 1) IN IF ~additionalOrderFlags.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(additionalOrderFlags.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET filler116 == ReadBytes(reserved1.rest, 2) IN IF ~filler116.ok THEN Fail ELSE
    LET filler17 == ReadBytes(filler116.rest, 1) IN IF ~filler17.ok THEN Fail ELSE
    LET filler18 == ReadBytes(filler17.rest, 1) IN IF ~filler18.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler18.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET mktReplay == ReadBytes(nnfField.rest, 8) IN IF ~mktReplay.ok THEN Fail ELSE
    LET pan == ReadBytes(mktReplay.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(reserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(reserved52.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET msSpdLegInfo == ReadMsSpdLegInfoList(priceDiff.rest, 2) IN IF ~msSpdLegInfo.ok THEN Fail ELSE
    Ok([ participantType1       |-> participantType1.value,
         filler1                |-> filler1.value,
         competitorPeriod1      |-> competitorPeriod1.value,
         solicitorPeriod1       |-> solicitorPeriod1.value,
         modCxlBy1              |-> modCxlBy1.value,
         filler9                |-> filler9.value,
         reasonCode1            |-> reasonCode1.value,
         startAlpha1            |-> startAlpha1.value,
         endAlpha1              |-> endAlpha1.value,
         token1                 |-> token1.value,
         contractDesc           |-> contractDesc.value,
         opBrokerId1            |-> opBrokerId1.value,
         fillerx1               |-> fillerx1.value,
         fillerOptions1         |-> fillerOptions1.value,
         fillery1               |-> fillery1.value,
         orderType1             |-> orderType1.value,
         orderNumber1           |-> orderNumber1.value,
         accountNumber1         |-> accountNumber1.value,
         bookType1              |-> bookType1.value,
         buySell1               |-> buySell1.value,
         disclosedVol1          |-> disclosedVol1.value,
         disclosedVolRemaining1 |-> disclosedVolRemaining1.value,
         totalVolRemaining1     |-> totalVolRemaining1.value,
         volume1                |-> volume1.value,
         volumeFilledToday1     |-> volumeFilledToday1.value,
         price1                 |-> price1.value,
         triggerPrice1          |-> triggerPrice1.value,
         goodTillDate1          |-> goodTillDate1.value,
         entryDateTime1         |-> entryDateTime1.value,
         minFillAon1            |-> minFillAon1.value,
         lastModified1          |-> lastModified1.value,
         stOrderFlags           |-> stOrderFlags.value,
         branchId1              |-> branchId1.value,
         traderId1              |-> traderId1.value,
         brokerId1              |-> brokerId1.value,
         cOrdFiller             |-> cOrdFiller.value,
         openClose1             |-> openClose1.value,
         settlor1               |-> settlor1.value,
         proClient1             |-> proClient1.value,
         settlementPeriod1      |-> settlementPeriod1.value,
         additionalOrderFlags   |-> additionalOrderFlags.value,
         reserved1              |-> reserved1.value,
         filler116              |-> filler116.value,
         filler17               |-> filler17.value,
         filler18               |-> filler18.value,
         nnfField               |-> nnfField.value,
         mktReplay              |-> mktReplay.value,
         pan                    |-> pan.value,
         algoId                 |-> algoId.value,
         reserved2              |-> reserved2.value,
         lastActivityReference  |-> lastActivityReference.value,
         reserved52             |-> reserved52.value,
         priceDiff              |-> priceDiff.value,
         msSpdLegInfo           |-> msSpdLegInfo.value ], msSpdLegInfo.rest)

ZeroSpreadOrderBody ==
    [ participantType1       |-> [i \in 1 .. 1 |-> 0],
      filler1                |-> [i \in 1 .. 1 |-> 0],
      competitorPeriod1      |-> [i \in 1 .. 2 |-> 0],
      solicitorPeriod1       |-> [i \in 1 .. 2 |-> 0],
      modCxlBy1              |-> [i \in 1 .. 1 |-> 0],
      filler9                |-> [i \in 1 .. 1 |-> 0],
      reasonCode1            |-> [i \in 1 .. 2 |-> 0],
      startAlpha1            |-> [i \in 1 .. 2 |-> 0],
      endAlpha1              |-> [i \in 1 .. 2 |-> 0],
      token1                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc           |-> ZeroContractDesc8,
      opBrokerId1            |-> [i \in 1 .. 5 |-> 0],
      fillerx1               |-> [i \in 1 .. 1 |-> 0],
      fillerOptions1         |-> [i \in 1 .. 3 |-> 0],
      fillery1               |-> [i \in 1 .. 1 |-> 0],
      orderType1             |-> [i \in 1 .. 2 |-> 0],
      orderNumber1           |-> [i \in 1 .. 8 |-> 0],
      accountNumber1         |-> [i \in 1 .. 10 |-> 0],
      bookType1              |-> [i \in 1 .. 2 |-> 0],
      buySell1               |-> [i \in 1 .. 2 |-> 0],
      disclosedVol1          |-> [i \in 1 .. 4 |-> 0],
      disclosedVolRemaining1 |-> [i \in 1 .. 4 |-> 0],
      totalVolRemaining1     |-> [i \in 1 .. 4 |-> 0],
      volume1                |-> [i \in 1 .. 4 |-> 0],
      volumeFilledToday1     |-> [i \in 1 .. 4 |-> 0],
      price1                 |-> [i \in 1 .. 4 |-> 0],
      triggerPrice1          |-> [i \in 1 .. 4 |-> 0],
      goodTillDate1          |-> [i \in 1 .. 4 |-> 0],
      entryDateTime1         |-> [i \in 1 .. 4 |-> 0],
      minFillAon1            |-> [i \in 1 .. 4 |-> 0],
      lastModified1          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags           |-> [i \in 1 .. 2 |-> 0],
      branchId1              |-> [i \in 1 .. 2 |-> 0],
      traderId1              |-> [i \in 1 .. 4 |-> 0],
      brokerId1              |-> [i \in 1 .. 5 |-> 0],
      cOrdFiller             |-> [i \in 1 .. 24 |-> 0],
      openClose1             |-> [i \in 1 .. 1 |-> 0],
      settlor1               |-> [i \in 1 .. 12 |-> 0],
      proClient1             |-> [i \in 1 .. 2 |-> 0],
      settlementPeriod1      |-> [i \in 1 .. 2 |-> 0],
      additionalOrderFlags   |-> [i \in 1 .. 1 |-> 0],
      reserved1              |-> [i \in 1 .. 1 |-> 0],
      filler116              |-> [i \in 1 .. 2 |-> 0],
      filler17               |-> [i \in 1 .. 1 |-> 0],
      filler18               |-> [i \in 1 .. 1 |-> 0],
      nnfField               |-> [i \in 1 .. 8 |-> 0],
      mktReplay              |-> [i \in 1 .. 8 |-> 0],
      pan                    |-> [i \in 1 .. 10 |-> 0],
      algoId                 |-> [i \in 1 .. 4 |-> 0],
      reserved2              |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference  |-> [i \in 1 .. 8 |-> 0],
      reserved52             |-> [i \in 1 .. 52 |-> 0],
      priceDiff              |-> [i \in 1 .. 4 |-> 0],
      msSpdLegInfo           |-> [i \in 1 .. 2 |-> ZeroMsSpdLegInfo] ]

(* Spread Order Body at zero, then each field in turn at the values it is checked at *)
CheckedSpreadOrderBody ==
    { ZeroSpreadOrderBody }
        \cup { [ZeroSpreadOrderBody EXCEPT !.participantType1 = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.competitorPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.solicitorPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.modCxlBy1 = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.filler9 = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.reasonCode1 = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.startAlpha1 = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.endAlpha1 = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.contractDesc = one] : one \in CheckedContractDesc8 }
        \cup { [ZeroSpreadOrderBody EXCEPT !.opBrokerId1 = one] : one \in Sample(5) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.fillerx1 = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.fillerOptions1 = one] : one \in Sample(3) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.fillery1 = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.orderType1 = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.disclosedVol1 = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.disclosedVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.volumeFilledToday1 = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.price1 = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.triggerPrice1 = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.goodTillDate1 = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.entryDateTime1 = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.minFillAon1 = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.lastModified1 = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.branchId1 = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.brokerId1 = one] : one \in Sample(5) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.proClient1 = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.settlementPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.filler116 = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.filler17 = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.filler18 = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.reserved52 = one] : one \in Sample(52) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrderBody EXCEPT !.msSpdLegInfo = one] : one \in SlotsMsSpdLegInfo }

(***************************************************************************)
(* Spread Order Entry Message                                              *)
(***************************************************************************)

SpreadOrderEntryMessage ==
    [ spreadOrderBody : SpreadOrderBody ]

EncodeSpreadOrderEntryMessage(message) ==
    EncodeSpreadOrderBody(message.spreadOrderBody)

DecodeSpreadOrderEntryMessage(bytes) ==
    LET spreadOrderBody == DecodeSpreadOrderBody(bytes) IN IF ~spreadOrderBody.ok THEN Fail ELSE
    Ok([ spreadOrderBody |-> spreadOrderBody.value ], spreadOrderBody.rest)

ZeroSpreadOrderEntryMessage ==
    [ spreadOrderBody |-> ZeroSpreadOrderBody ]

(* Spread Order Entry Message at zero, then each field in turn at the values it is checked at *)
CheckedSpreadOrderEntryMessage ==
    { ZeroSpreadOrderEntryMessage }
        \cup { [ZeroSpreadOrderEntryMessage EXCEPT !.spreadOrderBody = one] : one \in CheckedSpreadOrderBody }

(***************************************************************************)
(* Secure Box Registration Request In Message: 2 bytes                     *)
(***************************************************************************)

SecureBoxRegistrationRequestInMessage ==
    [ boxId : Sample(2) ]

EncodeSecureBoxRegistrationRequestInMessage(message) ==
    message.boxId

DecodeSecureBoxRegistrationRequestInMessage(bytes) ==
    LET boxId == ReadBytes(bytes, 2) IN IF ~boxId.ok THEN Fail ELSE
    Ok([ boxId |-> boxId.value ], boxId.rest)

ZeroSecureBoxRegistrationRequestInMessage ==
    [ boxId |-> [i \in 1 .. 2 |-> 0] ]

(* Secure Box Registration Request In Message at zero, then each field in turn at the values it is checked at *)
CheckedSecureBoxRegistrationRequestInMessage ==
    { ZeroSecureBoxRegistrationRequestInMessage }
        \cup { [ZeroSecureBoxRegistrationRequestInMessage EXCEPT !.boxId = one] : one \in Sample(2) }

(***************************************************************************)
(* Box Sign On Request In Message: 20 bytes                                *)
(***************************************************************************)

BoxSignOnRequestInMessage ==
    [ boxId      : Sample(2),
      brokerId   : Sample(5),
      reserved5  : Sample(5),
      sessionKey : Sample(8) ]

EncodeBoxSignOnRequestInMessage(message) ==
    message.boxId
        \o message.brokerId
        \o message.reserved5
        \o message.sessionKey

DecodeBoxSignOnRequestInMessage(bytes) ==
    LET boxId == ReadBytes(bytes, 2) IN IF ~boxId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(boxId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved5 == ReadBytes(brokerId.rest, 5) IN IF ~reserved5.ok THEN Fail ELSE
    LET sessionKey == ReadBytes(reserved5.rest, 8) IN IF ~sessionKey.ok THEN Fail ELSE
    Ok([ boxId      |-> boxId.value,
         brokerId   |-> brokerId.value,
         reserved5  |-> reserved5.value,
         sessionKey |-> sessionKey.value ], sessionKey.rest)

ZeroBoxSignOnRequestInMessage ==
    [ boxId      |-> [i \in 1 .. 2 |-> 0],
      brokerId   |-> [i \in 1 .. 5 |-> 0],
      reserved5  |-> [i \in 1 .. 5 |-> 0],
      sessionKey |-> [i \in 1 .. 8 |-> 0] ]

(* Box Sign On Request In Message at zero, then each field in turn at the values it is checked at *)
CheckedBoxSignOnRequestInMessage ==
    { ZeroBoxSignOnRequestInMessage }
        \cup { [ZeroBoxSignOnRequestInMessage EXCEPT !.boxId = one] : one \in Sample(2) }
        \cup { [ZeroBoxSignOnRequestInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroBoxSignOnRequestInMessage EXCEPT !.reserved5 = one] : one \in Sample(5) }
        \cup { [ZeroBoxSignOnRequestInMessage EXCEPT !.sessionKey = one] : one \in Sample(8) }

(***************************************************************************)
(* Box Sign Off Message: 2 bytes                                           *)
(***************************************************************************)

BoxSignOffMessage ==
    [ boxId : Sample(2) ]

EncodeBoxSignOffMessage(message) ==
    message.boxId

DecodeBoxSignOffMessage(bytes) ==
    LET boxId == ReadBytes(bytes, 2) IN IF ~boxId.ok THEN Fail ELSE
    Ok([ boxId |-> boxId.value ], boxId.rest)

ZeroBoxSignOffMessage ==
    [ boxId |-> [i \in 1 .. 2 |-> 0] ]

(* Box Sign Off Message at zero, then each field in turn at the values it is checked at *)
CheckedBoxSignOffMessage ==
    { ZeroBoxSignOffMessage }
        \cup { [ZeroBoxSignOffMessage EXCEPT !.boxId = one] : one \in Sample(2) }

(***************************************************************************)
(* Branch Limits: 32 bytes                                                 *)
(***************************************************************************)

BranchLimits ==
    [ branchBuyValueLimit  : Sample(8),
      branchSellValueLimit : Sample(8),
      reserved16           : Sample(16) ]

EncodeBranchLimits(message) ==
    message.branchBuyValueLimit
        \o message.branchSellValueLimit
        \o message.reserved16

DecodeBranchLimits(bytes) ==
    LET branchBuyValueLimit == ReadBytes(bytes, 8) IN IF ~branchBuyValueLimit.ok THEN Fail ELSE
    LET branchSellValueLimit == ReadBytes(branchBuyValueLimit.rest, 8) IN IF ~branchSellValueLimit.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(branchSellValueLimit.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ branchBuyValueLimit  |-> branchBuyValueLimit.value,
         branchSellValueLimit |-> branchSellValueLimit.value,
         reserved16           |-> reserved16.value ], reserved16.rest)

ZeroBranchLimits ==
    [ branchBuyValueLimit  |-> [i \in 1 .. 8 |-> 0],
      branchSellValueLimit |-> [i \in 1 .. 8 |-> 0],
      reserved16           |-> [i \in 1 .. 16 |-> 0] ]

(* Branch Limits at zero, then each field in turn at the values it is checked at *)
CheckedBranchLimits ==
    { ZeroBranchLimits }
        \cup { [ZeroBranchLimits EXCEPT !.branchBuyValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroBranchLimits EXCEPT !.branchSellValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroBranchLimits EXCEPT !.reserved16 = one] : one \in Sample(16) }

(* A run of Branch Limits, written one after another *)
RECURSIVE EncodeBranchLimitsList(_)
EncodeBranchLimitsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeBranchLimits(Head(messages)) \o EncodeBranchLimitsList(Tail(messages))

(* As many Branch Limits as the field that counts them says *)
RECURSIVE ReadBranchLimitsList(_, _)
ReadBranchLimitsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeBranchLimits(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadBranchLimitsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Branch Limits of each kind, for the lists that carry them *)
OneBranchLimits == { ZeroBranchLimits }

(* The 2 slots a run of Branch Limits is written as, whatever the field beside it says are in use *)
SlotsBranchLimits == { [i \in 1 .. 2 |-> one] : one \in OneBranchLimits }

(***************************************************************************)
(* Branch Order Value Limit Update Message                                 *)
(***************************************************************************)

BranchOrderValueLimitUpdateMessage ==
    [ brokerId     : Sample(5),
      reserved25   : Sample(25),
      branchId     : Sample(2),
      branchLimits : SlotsBranchLimits ]

EncodeBranchOrderValueLimitUpdateMessage(message) ==
    message.brokerId
        \o message.reserved25
        \o message.branchId
        \o EncodeBranchLimitsList(message.branchLimits)

DecodeBranchOrderValueLimitUpdateMessage(bytes) ==
    LET brokerId == ReadBytes(bytes, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved25 == ReadBytes(brokerId.rest, 25) IN IF ~reserved25.ok THEN Fail ELSE
    LET branchId == ReadBytes(reserved25.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET branchLimits == ReadBranchLimitsList(branchId.rest, 2) IN IF ~branchLimits.ok THEN Fail ELSE
    Ok([ brokerId     |-> brokerId.value,
         reserved25   |-> reserved25.value,
         branchId     |-> branchId.value,
         branchLimits |-> branchLimits.value ], branchLimits.rest)

ZeroBranchOrderValueLimitUpdateMessage ==
    [ brokerId     |-> [i \in 1 .. 5 |-> 0],
      reserved25   |-> [i \in 1 .. 25 |-> 0],
      branchId     |-> [i \in 1 .. 2 |-> 0],
      branchLimits |-> [i \in 1 .. 2 |-> ZeroBranchLimits] ]

(* Branch Order Value Limit Update Message at zero, then each field in turn at the values it is checked at *)
CheckedBranchOrderValueLimitUpdateMessage ==
    { ZeroBranchOrderValueLimitUpdateMessage }
        \cup { [ZeroBranchOrderValueLimitUpdateMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroBranchOrderValueLimitUpdateMessage EXCEPT !.reserved25 = one] : one \in Sample(25) }
        \cup { [ZeroBranchOrderValueLimitUpdateMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroBranchOrderValueLimitUpdateMessage EXCEPT !.branchLimits = one] : one \in SlotsBranchLimits }

(***************************************************************************)
(* User Limits: 64 bytes                                                   *)
(***************************************************************************)

UserLimits ==
    [ reserved32              : Sample(32),
      userOrderBuyValueLimit  : Sample(8),
      userOrderSellValueLimit : Sample(8),
      reserved16              : Sample(16) ]

EncodeUserLimits(message) ==
    message.reserved32
        \o message.userOrderBuyValueLimit
        \o message.userOrderSellValueLimit
        \o message.reserved16

DecodeUserLimits(bytes) ==
    LET reserved32 == ReadBytes(bytes, 32) IN IF ~reserved32.ok THEN Fail ELSE
    LET userOrderBuyValueLimit == ReadBytes(reserved32.rest, 8) IN IF ~userOrderBuyValueLimit.ok THEN Fail ELSE
    LET userOrderSellValueLimit == ReadBytes(userOrderBuyValueLimit.rest, 8) IN IF ~userOrderSellValueLimit.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(userOrderSellValueLimit.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ reserved32              |-> reserved32.value,
         userOrderBuyValueLimit  |-> userOrderBuyValueLimit.value,
         userOrderSellValueLimit |-> userOrderSellValueLimit.value,
         reserved16              |-> reserved16.value ], reserved16.rest)

ZeroUserLimits ==
    [ reserved32              |-> [i \in 1 .. 32 |-> 0],
      userOrderBuyValueLimit  |-> [i \in 1 .. 8 |-> 0],
      userOrderSellValueLimit |-> [i \in 1 .. 8 |-> 0],
      reserved16              |-> [i \in 1 .. 16 |-> 0] ]

(* User Limits at zero, then each field in turn at the values it is checked at *)
CheckedUserLimits ==
    { ZeroUserLimits }
        \cup { [ZeroUserLimits EXCEPT !.reserved32 = one] : one \in Sample(32) }
        \cup { [ZeroUserLimits EXCEPT !.userOrderBuyValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroUserLimits EXCEPT !.userOrderSellValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroUserLimits EXCEPT !.reserved16 = one] : one \in Sample(16) }

(* A run of User Limits, written one after another *)
RECURSIVE EncodeUserLimitsList(_)
EncodeUserLimitsList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeUserLimits(Head(messages)) \o EncodeUserLimitsList(Tail(messages))

(* As many User Limits as the field that counts them says *)
RECURSIVE ReadUserLimitsList(_, _)
ReadUserLimitsList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeUserLimits(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadUserLimitsList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One User Limits of each kind, for the lists that carry them *)
OneUserLimits == { ZeroUserLimits }

(* The 2 slots a run of User Limits is written as, whatever the field beside it says are in use *)
SlotsUserLimits == { [i \in 1 .. 2 |-> one] : one \in OneUserLimits }

(***************************************************************************)
(* User Order Value Limit Update Message                                   *)
(***************************************************************************)

UserOrderValueLimitUpdateMessage ==
    [ brokerId   : Sample(5),
      reserved1  : Sample(1),
      branchId   : Sample(2),
      reserved26 : Sample(26),
      userId     : Sample(4),
      reserved2  : Sample(2),
      userLimits : SlotsUserLimits ]

EncodeUserOrderValueLimitUpdateMessage(message) ==
    message.brokerId
        \o message.reserved1
        \o message.branchId
        \o message.reserved26
        \o message.userId
        \o message.reserved2
        \o EncodeUserLimitsList(message.userLimits)

DecodeUserOrderValueLimitUpdateMessage(bytes) ==
    LET brokerId == ReadBytes(bytes, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(brokerId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET branchId == ReadBytes(reserved1.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET reserved26 == ReadBytes(branchId.rest, 26) IN IF ~reserved26.ok THEN Fail ELSE
    LET userId == ReadBytes(reserved26.rest, 4) IN IF ~userId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(userId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET userLimits == ReadUserLimitsList(reserved2.rest, 2) IN IF ~userLimits.ok THEN Fail ELSE
    Ok([ brokerId   |-> brokerId.value,
         reserved1  |-> reserved1.value,
         branchId   |-> branchId.value,
         reserved26 |-> reserved26.value,
         userId     |-> userId.value,
         reserved2  |-> reserved2.value,
         userLimits |-> userLimits.value ], userLimits.rest)

ZeroUserOrderValueLimitUpdateMessage ==
    [ brokerId   |-> [i \in 1 .. 5 |-> 0],
      reserved1  |-> [i \in 1 .. 1 |-> 0],
      branchId   |-> [i \in 1 .. 2 |-> 0],
      reserved26 |-> [i \in 1 .. 26 |-> 0],
      userId     |-> [i \in 1 .. 4 |-> 0],
      reserved2  |-> [i \in 1 .. 2 |-> 0],
      userLimits |-> [i \in 1 .. 2 |-> ZeroUserLimits] ]

(* User Order Value Limit Update Message at zero, then each field in turn at the values it is checked at *)
CheckedUserOrderValueLimitUpdateMessage ==
    { ZeroUserOrderValueLimitUpdateMessage }
        \cup { [ZeroUserOrderValueLimitUpdateMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroUserOrderValueLimitUpdateMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroUserOrderValueLimitUpdateMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroUserOrderValueLimitUpdateMessage EXCEPT !.reserved26 = one] : one \in Sample(26) }
        \cup { [ZeroUserOrderValueLimitUpdateMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroUserOrderValueLimitUpdateMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroUserOrderValueLimitUpdateMessage EXCEPT !.userLimits = one] : one \in SlotsUserLimits }

(***************************************************************************)
(* Normal Order Limit Update Message: 26 bytes                             *)
(***************************************************************************)

NormalOrderLimitUpdateMessage ==
    [ brokerId      : Sample(5),
      reserved1     : Sample(1),
      userId        : Sample(4),
      orderQtyLimit : Sample(8),
      orderValLimit : Sample(8) ]

EncodeNormalOrderLimitUpdateMessage(message) ==
    message.brokerId
        \o message.reserved1
        \o message.userId
        \o message.orderQtyLimit
        \o message.orderValLimit

DecodeNormalOrderLimitUpdateMessage(bytes) ==
    LET brokerId == ReadBytes(bytes, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(brokerId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET userId == ReadBytes(reserved1.rest, 4) IN IF ~userId.ok THEN Fail ELSE
    LET orderQtyLimit == ReadBytes(userId.rest, 8) IN IF ~orderQtyLimit.ok THEN Fail ELSE
    LET orderValLimit == ReadBytes(orderQtyLimit.rest, 8) IN IF ~orderValLimit.ok THEN Fail ELSE
    Ok([ brokerId      |-> brokerId.value,
         reserved1     |-> reserved1.value,
         userId        |-> userId.value,
         orderQtyLimit |-> orderQtyLimit.value,
         orderValLimit |-> orderValLimit.value ], orderValLimit.rest)

ZeroNormalOrderLimitUpdateMessage ==
    [ brokerId      |-> [i \in 1 .. 5 |-> 0],
      reserved1     |-> [i \in 1 .. 1 |-> 0],
      userId        |-> [i \in 1 .. 4 |-> 0],
      orderQtyLimit |-> [i \in 1 .. 8 |-> 0],
      orderValLimit |-> [i \in 1 .. 8 |-> 0] ]

(* Normal Order Limit Update Message at zero, then each field in turn at the values it is checked at *)
CheckedNormalOrderLimitUpdateMessage ==
    { ZeroNormalOrderLimitUpdateMessage }
        \cup { [ZeroNormalOrderLimitUpdateMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroNormalOrderLimitUpdateMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroNormalOrderLimitUpdateMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroNormalOrderLimitUpdateMessage EXCEPT !.orderQtyLimit = one] : one \in Sample(8) }
        \cup { [ZeroNormalOrderLimitUpdateMessage EXCEPT !.orderValLimit = one] : one \in Sample(8) }

(***************************************************************************)
(* Reset User Password Message: 18 bytes                                   *)
(***************************************************************************)

ResetUserPasswordMessage ==
    [ userId     : Sample(4),
      reserved14 : Sample(14) ]

EncodeResetUserPasswordMessage(message) ==
    message.userId
        \o message.reserved14

DecodeResetUserPasswordMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET reserved14 == ReadBytes(userId.rest, 14) IN IF ~reserved14.ok THEN Fail ELSE
    Ok([ userId     |-> userId.value,
         reserved14 |-> reserved14.value ], reserved14.rest)

ZeroResetUserPasswordMessage ==
    [ userId     |-> [i \in 1 .. 4 |-> 0],
      reserved14 |-> [i \in 1 .. 14 |-> 0] ]

(* Reset User Password Message at zero, then each field in turn at the values it is checked at *)
CheckedResetUserPasswordMessage ==
    { ZeroResetUserPasswordMessage }
        \cup { [ZeroResetUserPasswordMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroResetUserPasswordMessage EXCEPT !.reserved14 = one] : one \in Sample(14) }

(***************************************************************************)
(* Collateral User Status Change Request Message: 12 bytes                 *)
(***************************************************************************)

CollateralUserStatusChangeRequestMessage ==
    [ userId     : Sample(4),
      colUserBit : Sample(1),
      reserved7  : Sample(7) ]

EncodeCollateralUserStatusChangeRequestMessage(message) ==
    message.userId
        \o message.colUserBit
        \o message.reserved7

DecodeCollateralUserStatusChangeRequestMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET colUserBit == ReadBytes(userId.rest, 1) IN IF ~colUserBit.ok THEN Fail ELSE
    LET reserved7 == ReadBytes(colUserBit.rest, 7) IN IF ~reserved7.ok THEN Fail ELSE
    Ok([ userId     |-> userId.value,
         colUserBit |-> colUserBit.value,
         reserved7  |-> reserved7.value ], reserved7.rest)

ZeroCollateralUserStatusChangeRequestMessage ==
    [ userId     |-> [i \in 1 .. 4 |-> 0],
      colUserBit |-> [i \in 1 .. 1 |-> 0],
      reserved7  |-> [i \in 1 .. 7 |-> 0] ]

(* Collateral User Status Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCollateralUserStatusChangeRequestMessage ==
    { ZeroCollateralUserStatusChangeRequestMessage }
        \cup { [ZeroCollateralUserStatusChangeRequestMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroCollateralUserStatusChangeRequestMessage EXCEPT !.colUserBit = one] : one \in Sample(1) }
        \cup { [ZeroCollateralUserStatusChangeRequestMessage EXCEPT !.reserved7 = one] : one \in Sample(7) }

(***************************************************************************)
(* User Trade Modify Cancel Status Change Request Message: 12 bytes        *)
(***************************************************************************)

UserTradeModifyCancelStatusChangeRequestMessage ==
    [ userId       : Sample(4),
      trdModCxlBit : Sample(1),
      reserved7    : Sample(7) ]

EncodeUserTradeModifyCancelStatusChangeRequestMessage(message) ==
    message.userId
        \o message.trdModCxlBit
        \o message.reserved7

DecodeUserTradeModifyCancelStatusChangeRequestMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET trdModCxlBit == ReadBytes(userId.rest, 1) IN IF ~trdModCxlBit.ok THEN Fail ELSE
    LET reserved7 == ReadBytes(trdModCxlBit.rest, 7) IN IF ~reserved7.ok THEN Fail ELSE
    Ok([ userId       |-> userId.value,
         trdModCxlBit |-> trdModCxlBit.value,
         reserved7    |-> reserved7.value ], reserved7.rest)

ZeroUserTradeModifyCancelStatusChangeRequestMessage ==
    [ userId       |-> [i \in 1 .. 4 |-> 0],
      trdModCxlBit |-> [i \in 1 .. 1 |-> 0],
      reserved7    |-> [i \in 1 .. 7 |-> 0] ]

(* User Trade Modify Cancel Status Change Request Message at zero, then each field in turn at the values it is checked at *)
CheckedUserTradeModifyCancelStatusChangeRequestMessage ==
    { ZeroUserTradeModifyCancelStatusChangeRequestMessage }
        \cup { [ZeroUserTradeModifyCancelStatusChangeRequestMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroUserTradeModifyCancelStatusChangeRequestMessage EXCEPT !.trdModCxlBit = one] : one \in Sample(1) }
        \cup { [ZeroUserTradeModifyCancelStatusChangeRequestMessage EXCEPT !.reserved7 = one] : one \in Sample(7) }

(***************************************************************************)
(* User Address Unlock Request Message: 74 bytes                           *)
(***************************************************************************)

UserAddressUnlockRequestMessage ==
    [ userId     : Sample(4),
      reserved70 : Sample(70) ]

EncodeUserAddressUnlockRequestMessage(message) ==
    message.userId
        \o message.reserved70

DecodeUserAddressUnlockRequestMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET reserved70 == ReadBytes(userId.rest, 70) IN IF ~reserved70.ok THEN Fail ELSE
    Ok([ userId     |-> userId.value,
         reserved70 |-> reserved70.value ], reserved70.rest)

ZeroUserAddressUnlockRequestMessage ==
    [ userId     |-> [i \in 1 .. 4 |-> 0],
      reserved70 |-> [i \in 1 .. 70 |-> 0] ]

(* User Address Unlock Request Message at zero, then each field in turn at the values it is checked at *)
CheckedUserAddressUnlockRequestMessage ==
    { ZeroUserAddressUnlockRequestMessage }
        \cup { [ZeroUserAddressUnlockRequestMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroUserAddressUnlockRequestMessage EXCEPT !.reserved70 = one] : one \in Sample(70) }

(***************************************************************************)
(* Client Message Payload, selected by Transaction Code                    *)
(***************************************************************************)

SignOnRequestInMessageCode == 2300  \* 0x8fc
SystemInformationInMessageCode == 1600  \* 0x640
GatewayRouterRequestMessageCode == 2400  \* 0x960
SignOffRequestInMessageCode == 2320  \* 0x910
UpdateLocalDatabaseInMessageCode == 7300  \* 0x1c84
DownloadRequestMessageCode == 7000  \* 0x1b58
OrderEntryRequestMessageCode == 2000  \* 0x7d0
OrderModificationRequestMessageCode == 2040  \* 0x7f8
OrderCancellationRequestMessageCode == 2070  \* 0x816
OrderConfirmationMessageCode == 2073  \* 0x819
OrderModificationConfirmationMessageCode == 2074  \* 0x81a
OrderEntryMessageCode == 2012  \* 0x7dc
OrderEntryMessageCode2 == 2042  \* 0x7fa
OrderEntryMessageCode3 == 2062  \* 0x80e
OrderEntryMessageCode4 == 2072  \* 0x818
OrderEntryMessageCode5 == 2170  \* 0x87a
OrderEntryMessageCode6 == 2231  \* 0x8b7
OrderEntryMessageCode7 == 9002  \* 0x232a
PriceModificationMessageCode == 2013  \* 0x7dd
PriceModificationMessageCode2 == 20406  \* 0x4fb6
TradeInquiryMessageCode == 5445  \* 0x1545
TradeInquiryMessageCode2 == 5440  \* 0x1540
TradeInquiryMessageCode3 == 5441  \* 0x1541
TradeInquiryMessageCode4 == 2223  \* 0x8af
SpreadOrderEntryMessageCode == 2100  \* 0x834
SpreadOrderEntryMessageCode2 == 2102  \* 0x836
SpreadOrderEntryMessageCode3 == 2104  \* 0x838
SpreadOrderEntryMessageCode4 == 2106  \* 0x83a
SpreadOrderEntryMessageCode5 == 2118  \* 0x846
SpreadOrderEntryMessageCode6 == 2124  \* 0x84c
SpreadOrderEntryMessageCode7 == 2125  \* 0x84d
SpreadOrderEntryMessageCode8 == 2126  \* 0x84e
SpreadOrderEntryMessageCode9 == 2127  \* 0x84f
SpreadOrderEntryMessageCode10 == 2130  \* 0x852
SpreadOrderEntryMessageCode11 == 2131  \* 0x853
SpreadOrderEntryMessageCode12 == 2132  \* 0x854
SpreadOrderEntryMessageCode13 == 2133  \* 0x855
SpreadOrderEntryMessageCode14 == 2136  \* 0x858
SpreadOrderEntryMessageCode15 == 2154  \* 0x86a
SpreadOrderEntryMessageCode16 == 2155  \* 0x86b
SpreadOrderEntryMessageCode17 == 2156  \* 0x86c
SpreadOrderEntryMessageCode18 == 9004  \* 0x232c
SpreadOrderEntryMessageCode19 == 20408  \* 0x4fb8
SpreadOrderEntryMessageCode20 == 20410  \* 0x4fba
SpreadOrderEntryMessageCode21 == 20412  \* 0x4fbc
SpreadOrderEntryMessageCode22 == 20414  \* 0x4fbe
SpreadOrderEntryMessageCode23 == 20416  \* 0x4fc0
SecureBoxRegistrationRequestInMessageCode == 23008  \* 0x59e0
BoxSignOnRequestInMessageCode == 23000  \* 0x59d8
HeartbeatMessageCode == 23506  \* 0x5bd2
BoxSignOffMessageCode == 20322  \* 0x4f62
BranchOrderValueLimitUpdateMessageCode == 5716  \* 0x1654
UserOrderValueLimitUpdateMessageCode == 5730  \* 0x1662
NormalOrderLimitUpdateMessageCode == 5732  \* 0x1664
ResetUserPasswordMessageCode == 5740  \* 0x166c
CollateralUserStatusChangeRequestMessageCode == 5744  \* 0x1670
UserTradeModifyCancelStatusChangeRequestMessageCode == 5738  \* 0x166a
UserAddressUnlockRequestMessageCode == 5427  \* 0x1533

ClientMessagePayload ==
    [ tag : {SignOnRequestInMessageCode}, body : SignOnRequestInMessage ]
        \cup [ tag : {SystemInformationInMessageCode}, body : SystemInformationInMessage ]
        \cup [ tag : {GatewayRouterRequestMessageCode}, body : GatewayRouterRequestMessage ]
        \cup [ tag : {SignOffRequestInMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {UpdateLocalDatabaseInMessageCode}, body : UpdateLocalDatabaseInMessage ]
        \cup [ tag : {DownloadRequestMessageCode}, body : DownloadRequestMessage ]
        \cup [ tag : {OrderEntryRequestMessageCode}, body : OrderEntryRequestMessage ]
        \cup [ tag : {OrderModificationRequestMessageCode}, body : OrderModificationRequestMessage ]
        \cup [ tag : {OrderCancellationRequestMessageCode}, body : OrderCancellationRequestMessage ]
        \cup [ tag : {OrderConfirmationMessageCode}, body : OrderConfirmationMessage ]
        \cup [ tag : {OrderModificationConfirmationMessageCode}, body : OrderModificationConfirmationMessage ]
        \cup [ tag : {OrderEntryMessageCode}, body : OrderEntryMessage ]
        \cup [ tag : {OrderEntryMessageCode2}, body : OrderEntryMessage ]
        \cup [ tag : {OrderEntryMessageCode3}, body : OrderEntryMessage ]
        \cup [ tag : {OrderEntryMessageCode4}, body : OrderEntryMessage ]
        \cup [ tag : {OrderEntryMessageCode5}, body : OrderEntryMessage ]
        \cup [ tag : {OrderEntryMessageCode6}, body : OrderEntryMessage ]
        \cup [ tag : {OrderEntryMessageCode7}, body : OrderEntryMessage ]
        \cup [ tag : {PriceModificationMessageCode}, body : PriceModificationMessage ]
        \cup [ tag : {PriceModificationMessageCode2}, body : PriceModificationMessage ]
        \cup [ tag : {TradeInquiryMessageCode}, body : TradeInquiryMessage ]
        \cup [ tag : {TradeInquiryMessageCode2}, body : TradeInquiryMessage ]
        \cup [ tag : {TradeInquiryMessageCode3}, body : TradeInquiryMessage ]
        \cup [ tag : {TradeInquiryMessageCode4}, body : TradeInquiryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode2}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode3}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode4}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode5}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode6}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode7}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode8}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode9}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode10}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode11}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode12}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode13}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode14}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode15}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode16}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode17}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode18}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode19}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode20}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode21}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode22}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SpreadOrderEntryMessageCode23}, body : SpreadOrderEntryMessage ]
        \cup [ tag : {SecureBoxRegistrationRequestInMessageCode}, body : SecureBoxRegistrationRequestInMessage ]
        \cup [ tag : {BoxSignOnRequestInMessageCode}, body : BoxSignOnRequestInMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {BoxSignOffMessageCode}, body : BoxSignOffMessage ]
        \cup [ tag : {BranchOrderValueLimitUpdateMessageCode}, body : BranchOrderValueLimitUpdateMessage ]
        \cup [ tag : {UserOrderValueLimitUpdateMessageCode}, body : UserOrderValueLimitUpdateMessage ]
        \cup [ tag : {NormalOrderLimitUpdateMessageCode}, body : NormalOrderLimitUpdateMessage ]
        \cup [ tag : {ResetUserPasswordMessageCode}, body : ResetUserPasswordMessage ]
        \cup [ tag : {CollateralUserStatusChangeRequestMessageCode}, body : CollateralUserStatusChangeRequestMessage ]
        \cup [ tag : {UserTradeModifyCancelStatusChangeRequestMessageCode}, body : UserTradeModifyCancelStatusChangeRequestMessage ]
        \cup [ tag : {UserAddressUnlockRequestMessageCode}, body : UserAddressUnlockRequestMessage ]

EncodeClientMessagePayload(message) ==
    CASE message.tag = SignOnRequestInMessageCode -> EncodeSignOnRequestInMessage(message.body)
      [] message.tag = SystemInformationInMessageCode -> EncodeSystemInformationInMessage(message.body)
      [] message.tag = GatewayRouterRequestMessageCode -> EncodeGatewayRouterRequestMessage(message.body)
      [] message.tag = SignOffRequestInMessageCode -> << >>
      [] message.tag = UpdateLocalDatabaseInMessageCode -> EncodeUpdateLocalDatabaseInMessage(message.body)
      [] message.tag = DownloadRequestMessageCode -> EncodeDownloadRequestMessage(message.body)
      [] message.tag = OrderEntryRequestMessageCode -> EncodeOrderEntryRequestMessage(message.body)
      [] message.tag = OrderModificationRequestMessageCode -> EncodeOrderModificationRequestMessage(message.body)
      [] message.tag = OrderCancellationRequestMessageCode -> EncodeOrderCancellationRequestMessage(message.body)
      [] message.tag = OrderConfirmationMessageCode -> EncodeOrderConfirmationMessage(message.body)
      [] message.tag = OrderModificationConfirmationMessageCode -> EncodeOrderModificationConfirmationMessage(message.body)
      [] message.tag = OrderEntryMessageCode -> EncodeOrderEntryMessage(message.body)
      [] message.tag = OrderEntryMessageCode2 -> EncodeOrderEntryMessage(message.body)
      [] message.tag = OrderEntryMessageCode3 -> EncodeOrderEntryMessage(message.body)
      [] message.tag = OrderEntryMessageCode4 -> EncodeOrderEntryMessage(message.body)
      [] message.tag = OrderEntryMessageCode5 -> EncodeOrderEntryMessage(message.body)
      [] message.tag = OrderEntryMessageCode6 -> EncodeOrderEntryMessage(message.body)
      [] message.tag = OrderEntryMessageCode7 -> EncodeOrderEntryMessage(message.body)
      [] message.tag = PriceModificationMessageCode -> EncodePriceModificationMessage(message.body)
      [] message.tag = PriceModificationMessageCode2 -> EncodePriceModificationMessage(message.body)
      [] message.tag = TradeInquiryMessageCode -> EncodeTradeInquiryMessage(message.body)
      [] message.tag = TradeInquiryMessageCode2 -> EncodeTradeInquiryMessage(message.body)
      [] message.tag = TradeInquiryMessageCode3 -> EncodeTradeInquiryMessage(message.body)
      [] message.tag = TradeInquiryMessageCode4 -> EncodeTradeInquiryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode2 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode3 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode4 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode5 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode6 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode7 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode8 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode9 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode10 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode11 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode12 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode13 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode14 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode15 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode16 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode17 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode18 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode19 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode20 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode21 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode22 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SpreadOrderEntryMessageCode23 -> EncodeSpreadOrderEntryMessage(message.body)
      [] message.tag = SecureBoxRegistrationRequestInMessageCode -> EncodeSecureBoxRegistrationRequestInMessage(message.body)
      [] message.tag = BoxSignOnRequestInMessageCode -> EncodeBoxSignOnRequestInMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = BoxSignOffMessageCode -> EncodeBoxSignOffMessage(message.body)
      [] message.tag = BranchOrderValueLimitUpdateMessageCode -> EncodeBranchOrderValueLimitUpdateMessage(message.body)
      [] message.tag = UserOrderValueLimitUpdateMessageCode -> EncodeUserOrderValueLimitUpdateMessage(message.body)
      [] message.tag = NormalOrderLimitUpdateMessageCode -> EncodeNormalOrderLimitUpdateMessage(message.body)
      [] message.tag = ResetUserPasswordMessageCode -> EncodeResetUserPasswordMessage(message.body)
      [] message.tag = CollateralUserStatusChangeRequestMessageCode -> EncodeCollateralUserStatusChangeRequestMessage(message.body)
      [] message.tag = UserTradeModifyCancelStatusChangeRequestMessageCode -> EncodeUserTradeModifyCancelStatusChangeRequestMessage(message.body)
      [] message.tag = UserAddressUnlockRequestMessageCode -> EncodeUserAddressUnlockRequestMessage(message.body)

DecodeClientMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = SignOnRequestInMessageCode -> DecodeSignOnRequestInMessage(bytes)
              [] tag = SystemInformationInMessageCode -> DecodeSystemInformationInMessage(bytes)
              [] tag = GatewayRouterRequestMessageCode -> DecodeGatewayRouterRequestMessage(bytes)
              [] tag = SignOffRequestInMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = UpdateLocalDatabaseInMessageCode -> DecodeUpdateLocalDatabaseInMessage(bytes)
              [] tag = DownloadRequestMessageCode -> DecodeDownloadRequestMessage(bytes)
              [] tag = OrderEntryRequestMessageCode -> DecodeOrderEntryRequestMessage(bytes)
              [] tag = OrderModificationRequestMessageCode -> DecodeOrderModificationRequestMessage(bytes)
              [] tag = OrderCancellationRequestMessageCode -> DecodeOrderCancellationRequestMessage(bytes)
              [] tag = OrderConfirmationMessageCode -> DecodeOrderConfirmationMessage(bytes)
              [] tag = OrderModificationConfirmationMessageCode -> DecodeOrderModificationConfirmationMessage(bytes)
              [] tag = OrderEntryMessageCode -> DecodeOrderEntryMessage(bytes)
              [] tag = OrderEntryMessageCode2 -> DecodeOrderEntryMessage(bytes)
              [] tag = OrderEntryMessageCode3 -> DecodeOrderEntryMessage(bytes)
              [] tag = OrderEntryMessageCode4 -> DecodeOrderEntryMessage(bytes)
              [] tag = OrderEntryMessageCode5 -> DecodeOrderEntryMessage(bytes)
              [] tag = OrderEntryMessageCode6 -> DecodeOrderEntryMessage(bytes)
              [] tag = OrderEntryMessageCode7 -> DecodeOrderEntryMessage(bytes)
              [] tag = PriceModificationMessageCode -> DecodePriceModificationMessage(bytes)
              [] tag = PriceModificationMessageCode2 -> DecodePriceModificationMessage(bytes)
              [] tag = TradeInquiryMessageCode -> DecodeTradeInquiryMessage(bytes)
              [] tag = TradeInquiryMessageCode2 -> DecodeTradeInquiryMessage(bytes)
              [] tag = TradeInquiryMessageCode3 -> DecodeTradeInquiryMessage(bytes)
              [] tag = TradeInquiryMessageCode4 -> DecodeTradeInquiryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode2 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode3 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode4 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode5 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode6 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode7 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode8 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode9 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode10 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode11 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode12 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode13 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode14 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode15 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode16 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode17 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode18 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode19 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode20 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode21 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode22 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SpreadOrderEntryMessageCode23 -> DecodeSpreadOrderEntryMessage(bytes)
              [] tag = SecureBoxRegistrationRequestInMessageCode -> DecodeSecureBoxRegistrationRequestInMessage(bytes)
              [] tag = BoxSignOnRequestInMessageCode -> DecodeBoxSignOnRequestInMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = BoxSignOffMessageCode -> DecodeBoxSignOffMessage(bytes)
              [] tag = BranchOrderValueLimitUpdateMessageCode -> DecodeBranchOrderValueLimitUpdateMessage(bytes)
              [] tag = UserOrderValueLimitUpdateMessageCode -> DecodeUserOrderValueLimitUpdateMessage(bytes)
              [] tag = NormalOrderLimitUpdateMessageCode -> DecodeNormalOrderLimitUpdateMessage(bytes)
              [] tag = ResetUserPasswordMessageCode -> DecodeResetUserPasswordMessage(bytes)
              [] tag = CollateralUserStatusChangeRequestMessageCode -> DecodeCollateralUserStatusChangeRequestMessage(bytes)
              [] tag = UserTradeModifyCancelStatusChangeRequestMessageCode -> DecodeUserTradeModifyCancelStatusChangeRequestMessage(bytes)
              [] tag = UserAddressUnlockRequestMessageCode -> DecodeUserAddressUnlockRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientMessagePayload == [tag |-> SignOnRequestInMessageCode, body |-> ZeroSignOnRequestInMessage]

(* Each Client Message Payload in turn, at the values the message it names is checked at *)
CheckedClientMessagePayload ==
    { [tag |-> SignOnRequestInMessageCode, body |-> one] : one \in CheckedSignOnRequestInMessage }
        \cup { [tag |-> SystemInformationInMessageCode, body |-> one] : one \in CheckedSystemInformationInMessage }
        \cup { [tag |-> GatewayRouterRequestMessageCode, body |-> one] : one \in CheckedGatewayRouterRequestMessage }
        \cup { [tag |-> SignOffRequestInMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> UpdateLocalDatabaseInMessageCode, body |-> one] : one \in CheckedUpdateLocalDatabaseInMessage }
        \cup { [tag |-> DownloadRequestMessageCode, body |-> one] : one \in CheckedDownloadRequestMessage }
        \cup { [tag |-> OrderEntryRequestMessageCode, body |-> one] : one \in CheckedOrderEntryRequestMessage }
        \cup { [tag |-> OrderModificationRequestMessageCode, body |-> one] : one \in CheckedOrderModificationRequestMessage }
        \cup { [tag |-> OrderCancellationRequestMessageCode, body |-> one] : one \in CheckedOrderCancellationRequestMessage }
        \cup { [tag |-> OrderConfirmationMessageCode, body |-> one] : one \in CheckedOrderConfirmationMessage }
        \cup { [tag |-> OrderModificationConfirmationMessageCode, body |-> one] : one \in CheckedOrderModificationConfirmationMessage }
        \cup { [tag |-> OrderEntryMessageCode, body |-> one] : one \in CheckedOrderEntryMessage }
        \cup { [tag |-> OrderEntryMessageCode2, body |-> one] : one \in CheckedOrderEntryMessage }
        \cup { [tag |-> OrderEntryMessageCode3, body |-> one] : one \in CheckedOrderEntryMessage }
        \cup { [tag |-> OrderEntryMessageCode4, body |-> one] : one \in CheckedOrderEntryMessage }
        \cup { [tag |-> OrderEntryMessageCode5, body |-> one] : one \in CheckedOrderEntryMessage }
        \cup { [tag |-> OrderEntryMessageCode6, body |-> one] : one \in CheckedOrderEntryMessage }
        \cup { [tag |-> OrderEntryMessageCode7, body |-> one] : one \in CheckedOrderEntryMessage }
        \cup { [tag |-> PriceModificationMessageCode, body |-> one] : one \in CheckedPriceModificationMessage }
        \cup { [tag |-> PriceModificationMessageCode2, body |-> one] : one \in CheckedPriceModificationMessage }
        \cup { [tag |-> TradeInquiryMessageCode, body |-> one] : one \in CheckedTradeInquiryMessage }
        \cup { [tag |-> TradeInquiryMessageCode2, body |-> one] : one \in CheckedTradeInquiryMessage }
        \cup { [tag |-> TradeInquiryMessageCode3, body |-> one] : one \in CheckedTradeInquiryMessage }
        \cup { [tag |-> TradeInquiryMessageCode4, body |-> one] : one \in CheckedTradeInquiryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode2, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode3, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode4, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode5, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode6, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode7, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode8, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode9, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode10, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode11, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode12, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode13, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode14, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode15, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode16, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode17, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode18, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode19, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode20, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode21, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode22, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SpreadOrderEntryMessageCode23, body |-> one] : one \in CheckedSpreadOrderEntryMessage }
        \cup { [tag |-> SecureBoxRegistrationRequestInMessageCode, body |-> one] : one \in CheckedSecureBoxRegistrationRequestInMessage }
        \cup { [tag |-> BoxSignOnRequestInMessageCode, body |-> one] : one \in CheckedBoxSignOnRequestInMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> BoxSignOffMessageCode, body |-> one] : one \in CheckedBoxSignOffMessage }
        \cup { [tag |-> BranchOrderValueLimitUpdateMessageCode, body |-> one] : one \in CheckedBranchOrderValueLimitUpdateMessage }
        \cup { [tag |-> UserOrderValueLimitUpdateMessageCode, body |-> one] : one \in CheckedUserOrderValueLimitUpdateMessage }
        \cup { [tag |-> NormalOrderLimitUpdateMessageCode, body |-> one] : one \in CheckedNormalOrderLimitUpdateMessage }
        \cup { [tag |-> ResetUserPasswordMessageCode, body |-> one] : one \in CheckedResetUserPasswordMessage }
        \cup { [tag |-> CollateralUserStatusChangeRequestMessageCode, body |-> one] : one \in CheckedCollateralUserStatusChangeRequestMessage }
        \cup { [tag |-> UserTradeModifyCancelStatusChangeRequestMessageCode, body |-> one] : one \in CheckedUserTradeModifyCancelStatusChangeRequestMessage }
        \cup { [tag |-> UserAddressUnlockRequestMessageCode, body |-> one] : one \in CheckedUserAddressUnlockRequestMessage }

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
    { [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SignOnRequestInMessageCode, body |-> ZeroSignOnRequestInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SystemInformationInMessageCode, body |-> ZeroSystemInformationInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> GatewayRouterRequestMessageCode, body |-> ZeroGatewayRouterRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SignOffRequestInMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> UpdateLocalDatabaseInMessageCode, body |-> ZeroUpdateLocalDatabaseInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> DownloadRequestMessageCode, body |-> ZeroDownloadRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderEntryRequestMessageCode, body |-> ZeroOrderEntryRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderModificationRequestMessageCode, body |-> ZeroOrderModificationRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderCancellationRequestMessageCode, body |-> ZeroOrderCancellationRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderConfirmationMessageCode, body |-> ZeroOrderConfirmationMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderModificationConfirmationMessageCode, body |-> ZeroOrderModificationConfirmationMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderEntryMessageCode, body |-> ZeroOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderEntryMessageCode2, body |-> ZeroOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderEntryMessageCode3, body |-> ZeroOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderEntryMessageCode4, body |-> ZeroOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderEntryMessageCode5, body |-> ZeroOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderEntryMessageCode6, body |-> ZeroOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderEntryMessageCode7, body |-> ZeroOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> PriceModificationMessageCode, body |-> ZeroPriceModificationMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> PriceModificationMessageCode2, body |-> ZeroPriceModificationMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> TradeInquiryMessageCode, body |-> ZeroTradeInquiryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> TradeInquiryMessageCode2, body |-> ZeroTradeInquiryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> TradeInquiryMessageCode3, body |-> ZeroTradeInquiryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> TradeInquiryMessageCode4, body |-> ZeroTradeInquiryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode2, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode3, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode4, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode5, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode6, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode7, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode8, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode9, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode10, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode11, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode12, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode13, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode14, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode15, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode16, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode17, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode18, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode19, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode20, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode21, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode22, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SpreadOrderEntryMessageCode23, body |-> ZeroSpreadOrderEntryMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SecureBoxRegistrationRequestInMessageCode, body |-> ZeroSecureBoxRegistrationRequestInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> BoxSignOnRequestInMessageCode, body |-> ZeroBoxSignOnRequestInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> BoxSignOffMessageCode, body |-> ZeroBoxSignOffMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> BranchOrderValueLimitUpdateMessageCode, body |-> ZeroBranchOrderValueLimitUpdateMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> UserOrderValueLimitUpdateMessageCode, body |-> ZeroUserOrderValueLimitUpdateMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> NormalOrderLimitUpdateMessageCode, body |-> ZeroNormalOrderLimitUpdateMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> ResetUserPasswordMessageCode, body |-> ZeroResetUserPasswordMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> CollateralUserStatusChangeRequestMessageCode, body |-> ZeroCollateralUserStatusChangeRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> UserTradeModifyCancelStatusChangeRequestMessageCode, body |-> ZeroUserTradeModifyCancelStatusChangeRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> UserAddressUnlockRequestMessageCode, body |-> ZeroUserAddressUnlockRequestMessage]] }

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

(* Every Sign On Request In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSignOnRequestInMessage ==
    \A message \in CheckedSignOnRequestInMessage :
        LET read == DecodeSignOnRequestInMessage(EncodeSignOnRequestInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every System Information In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemInformationInMessage ==
    \A message \in CheckedSystemInformationInMessage :
        LET read == DecodeSystemInformationInMessage(EncodeSystemInformationInMessage(message))
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

(* Every St Market Status decodes back to what was encoded, and leaves nothing over *)
RoundTripStMarketStatus ==
    \A message \in CheckedStMarketStatus :
        LET read == DecodeStMarketStatus(EncodeStMarketStatus(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every St Ex Market Status decodes back to what was encoded, and leaves nothing over *)
RoundTripStExMarketStatus ==
    \A message \in CheckedStExMarketStatus :
        LET read == DecodeStExMarketStatus(EncodeStExMarketStatus(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every St Pl Market Status decodes back to what was encoded, and leaves nothing over *)
RoundTripStPlMarketStatus ==
    \A message \in CheckedStPlMarketStatus :
        LET read == DecodeStPlMarketStatus(EncodeStPlMarketStatus(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Update Local Database In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUpdateLocalDatabaseInMessage ==
    \A message \in CheckedUpdateLocalDatabaseInMessage :
        LET read == DecodeUpdateLocalDatabaseInMessage(EncodeUpdateLocalDatabaseInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Download Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDownloadRequestMessage ==
    \A message \in CheckedDownloadRequestMessage :
        LET read == DecodeDownloadRequestMessage(EncodeDownloadRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc ==
    \A message \in CheckedContractDesc :
        LET read == DecodeContractDesc(EncodeContractDesc(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Entry Body decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderEntryBody ==
    \A message \in CheckedOrderEntryBody :
        LET read == DecodeOrderEntryBody(EncodeOrderEntryBody(message))
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

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc2 ==
    \A message \in CheckedContractDesc2 :
        LET read == DecodeContractDesc2(EncodeContractDesc2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Entry Body decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderEntryBody2 ==
    \A message \in CheckedOrderEntryBody2 :
        LET read == DecodeOrderEntryBody2(EncodeOrderEntryBody2(message))
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

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc3 ==
    \A message \in CheckedContractDesc3 :
        LET read == DecodeContractDesc3(EncodeContractDesc3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Entry Body decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderEntryBody3 ==
    \A message \in CheckedOrderEntryBody3 :
        LET read == DecodeOrderEntryBody3(EncodeOrderEntryBody3(message))
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

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc4 ==
    \A message \in CheckedContractDesc4 :
        LET read == DecodeContractDesc4(EncodeContractDesc4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Entry Body decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderEntryBody4 ==
    \A message \in CheckedOrderEntryBody4 :
        LET read == DecodeOrderEntryBody4(EncodeOrderEntryBody4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderConfirmationMessage ==
    \A message \in CheckedOrderConfirmationMessage :
        LET read == DecodeOrderConfirmationMessage(EncodeOrderConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc5 ==
    \A message \in CheckedContractDesc5 :
        LET read == DecodeContractDesc5(EncodeContractDesc5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Entry Body decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderEntryBody5 ==
    \A message \in CheckedOrderEntryBody5 :
        LET read == DecodeOrderEntryBody5(EncodeOrderEntryBody5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modification Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModificationConfirmationMessage ==
    \A message \in CheckedOrderModificationConfirmationMessage :
        LET read == DecodeOrderModificationConfirmationMessage(EncodeOrderModificationConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc6 ==
    \A message \in CheckedContractDesc6 :
        LET read == DecodeContractDesc6(EncodeContractDesc6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Entry Body decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderEntryBody6 ==
    \A message \in CheckedOrderEntryBody6 :
        LET read == DecodeOrderEntryBody6(EncodeOrderEntryBody6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Entry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderEntryMessage ==
    \A message \in CheckedOrderEntryMessage :
        LET read == DecodeOrderEntryMessage(EncodeOrderEntryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Modification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceModificationMessage ==
    \A message \in CheckedPriceModificationMessage :
        LET read == DecodePriceModificationMessage(EncodePriceModificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc7 ==
    \A message \in CheckedContractDesc7 :
        LET read == DecodeContractDesc7(EncodeContractDesc7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Inquiry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeInquiryMessage ==
    \A message \in CheckedTradeInquiryMessage :
        LET read == DecodeTradeInquiryMessage(EncodeTradeInquiryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc8 ==
    \A message \in CheckedContractDesc8 :
        LET read == DecodeContractDesc8(EncodeContractDesc8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc9 ==
    \A message \in CheckedContractDesc9 :
        LET read == DecodeContractDesc9(EncodeContractDesc9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfo ==
    \A message \in CheckedMsSpdLegInfo :
        LET read == DecodeMsSpdLegInfo(EncodeMsSpdLegInfo(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Order Body decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadOrderBody ==
    \A message \in CheckedSpreadOrderBody :
        LET read == DecodeSpreadOrderBody(EncodeSpreadOrderBody(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Order Entry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadOrderEntryMessage ==
    \A message \in CheckedSpreadOrderEntryMessage :
        LET read == DecodeSpreadOrderEntryMessage(EncodeSpreadOrderEntryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secure Box Registration Request In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecureBoxRegistrationRequestInMessage ==
    \A message \in CheckedSecureBoxRegistrationRequestInMessage :
        LET read == DecodeSecureBoxRegistrationRequestInMessage(EncodeSecureBoxRegistrationRequestInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Box Sign On Request In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBoxSignOnRequestInMessage ==
    \A message \in CheckedBoxSignOnRequestInMessage :
        LET read == DecodeBoxSignOnRequestInMessage(EncodeBoxSignOnRequestInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Box Sign Off Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBoxSignOffMessage ==
    \A message \in CheckedBoxSignOffMessage :
        LET read == DecodeBoxSignOffMessage(EncodeBoxSignOffMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Branch Limits decodes back to what was encoded, and leaves nothing over *)
RoundTripBranchLimits ==
    \A message \in CheckedBranchLimits :
        LET read == DecodeBranchLimits(EncodeBranchLimits(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Branch Order Value Limit Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBranchOrderValueLimitUpdateMessage ==
    \A message \in CheckedBranchOrderValueLimitUpdateMessage :
        LET read == DecodeBranchOrderValueLimitUpdateMessage(EncodeBranchOrderValueLimitUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Limits decodes back to what was encoded, and leaves nothing over *)
RoundTripUserLimits ==
    \A message \in CheckedUserLimits :
        LET read == DecodeUserLimits(EncodeUserLimits(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Order Value Limit Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUserOrderValueLimitUpdateMessage ==
    \A message \in CheckedUserOrderValueLimitUpdateMessage :
        LET read == DecodeUserOrderValueLimitUpdateMessage(EncodeUserOrderValueLimitUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Normal Order Limit Update Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNormalOrderLimitUpdateMessage ==
    \A message \in CheckedNormalOrderLimitUpdateMessage :
        LET read == DecodeNormalOrderLimitUpdateMessage(EncodeNormalOrderLimitUpdateMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reset User Password Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResetUserPasswordMessage ==
    \A message \in CheckedResetUserPasswordMessage :
        LET read == DecodeResetUserPasswordMessage(EncodeResetUserPasswordMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Collateral User Status Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCollateralUserStatusChangeRequestMessage ==
    \A message \in CheckedCollateralUserStatusChangeRequestMessage :
        LET read == DecodeCollateralUserStatusChangeRequestMessage(EncodeCollateralUserStatusChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Trade Modify Cancel Status Change Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUserTradeModifyCancelStatusChangeRequestMessage ==
    \A message \in CheckedUserTradeModifyCancelStatusChangeRequestMessage :
        LET read == DecodeUserTradeModifyCancelStatusChangeRequestMessage(EncodeUserTradeModifyCancelStatusChangeRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Address Unlock Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUserAddressUnlockRequestMessage ==
    \A message \in CheckedUserAddressUnlockRequestMessage :
        LET read == DecodeUserAddressUnlockRequestMessage(EncodeUserAddressUnlockRequestMessage(message))
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
        LET read == DecodeClientMessagePayload(message.tag, EncodeClientMessagePayload(message))
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
