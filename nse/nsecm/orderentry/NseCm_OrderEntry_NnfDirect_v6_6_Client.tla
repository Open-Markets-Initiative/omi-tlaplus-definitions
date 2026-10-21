-------------- MODULE NseCm_OrderEntry_NnfDirect_v6_6_Client ---------------
(***************************************************************************)
(* National Stock Exchange of India Ltd Order Entry v6.6                   *)
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
(* Note: St Order Flags is a bit field set, checked as its 2 bytes rather  *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Broker Eligibility Per Market is a bit field set, checked as its  *)
(* 2 bytes rather than bit by bit.                                         *)
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
(* Branch Limit: 32 bytes                                                  *)
(***************************************************************************)

BranchLimit ==
    [ branchBuyValueLimit  : Sample(8),
      reserved8            : Sample(8),
      branchSellValueLimit : Sample(8),
      secondReserved8      : Sample(8) ]

EncodeBranchLimit(message) ==
    message.branchBuyValueLimit
        \o message.reserved8
        \o message.branchSellValueLimit
        \o message.secondReserved8

DecodeBranchLimit(bytes) ==
    LET branchBuyValueLimit == ReadBytes(bytes, 8) IN IF ~branchBuyValueLimit.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(branchBuyValueLimit.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET branchSellValueLimit == ReadBytes(reserved8.rest, 8) IN IF ~branchSellValueLimit.ok THEN Fail ELSE
    LET secondReserved8 == ReadBytes(branchSellValueLimit.rest, 8) IN IF ~secondReserved8.ok THEN Fail ELSE
    Ok([ branchBuyValueLimit  |-> branchBuyValueLimit.value,
         reserved8            |-> reserved8.value,
         branchSellValueLimit |-> branchSellValueLimit.value,
         secondReserved8      |-> secondReserved8.value ], secondReserved8.rest)

ZeroBranchLimit ==
    [ branchBuyValueLimit  |-> [i \in 1 .. 8 |-> 0],
      reserved8            |-> [i \in 1 .. 8 |-> 0],
      branchSellValueLimit |-> [i \in 1 .. 8 |-> 0],
      secondReserved8      |-> [i \in 1 .. 8 |-> 0] ]

(* Branch Limit at zero, then each field in turn at the values it is checked at *)
CheckedBranchLimit ==
    { ZeroBranchLimit }
        \cup { [ZeroBranchLimit EXCEPT !.branchBuyValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroBranchLimit EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroBranchLimit EXCEPT !.branchSellValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroBranchLimit EXCEPT !.secondReserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* Branch Order Value Limit Update In Message: 64 bytes                    *)
(***************************************************************************)

BranchOrderValueLimitUpdateInMessage ==
    [ brokerId    : Sample(5),
      reserved25  : Sample(25),
      branch      : Sample(2),
      branchLimit : BranchLimit ]

EncodeBranchOrderValueLimitUpdateInMessage(message) ==
    message.brokerId
        \o message.reserved25
        \o message.branch
        \o EncodeBranchLimit(message.branchLimit)

DecodeBranchOrderValueLimitUpdateInMessage(bytes) ==
    LET brokerId == ReadBytes(bytes, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved25 == ReadBytes(brokerId.rest, 25) IN IF ~reserved25.ok THEN Fail ELSE
    LET branch == ReadBytes(reserved25.rest, 2) IN IF ~branch.ok THEN Fail ELSE
    LET branchLimit == DecodeBranchLimit(branch.rest) IN IF ~branchLimit.ok THEN Fail ELSE
    Ok([ brokerId    |-> brokerId.value,
         reserved25  |-> reserved25.value,
         branch      |-> branch.value,
         branchLimit |-> branchLimit.value ], branchLimit.rest)

ZeroBranchOrderValueLimitUpdateInMessage ==
    [ brokerId    |-> [i \in 1 .. 5 |-> 0],
      reserved25  |-> [i \in 1 .. 25 |-> 0],
      branch      |-> [i \in 1 .. 2 |-> 0],
      branchLimit |-> ZeroBranchLimit ]

(* Branch Order Value Limit Update In Message at zero, then each field in turn at the values it is checked at *)
CheckedBranchOrderValueLimitUpdateInMessage ==
    { ZeroBranchOrderValueLimitUpdateInMessage }
        \cup { [ZeroBranchOrderValueLimitUpdateInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroBranchOrderValueLimitUpdateInMessage EXCEPT !.reserved25 = one] : one \in Sample(25) }
        \cup { [ZeroBranchOrderValueLimitUpdateInMessage EXCEPT !.branch = one] : one \in Sample(2) }
        \cup { [ZeroBranchOrderValueLimitUpdateInMessage EXCEPT !.branchLimit = one] : one \in CheckedBranchLimit }

(***************************************************************************)
(* Cancel On Logout Status Request Message: 12 bytes                       *)
(***************************************************************************)

CancelOnLogoutStatusRequestMessage ==
    [ userId      : Sample(4),
      coloUserBit : Sample(1),
      reserved7   : Sample(7) ]

EncodeCancelOnLogoutStatusRequestMessage(message) ==
    message.userId
        \o message.coloUserBit
        \o message.reserved7

DecodeCancelOnLogoutStatusRequestMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET coloUserBit == ReadBytes(userId.rest, 1) IN IF ~coloUserBit.ok THEN Fail ELSE
    LET reserved7 == ReadBytes(coloUserBit.rest, 7) IN IF ~reserved7.ok THEN Fail ELSE
    Ok([ userId      |-> userId.value,
         coloUserBit |-> coloUserBit.value,
         reserved7   |-> reserved7.value ], reserved7.rest)

ZeroCancelOnLogoutStatusRequestMessage ==
    [ userId      |-> [i \in 1 .. 4 |-> 0],
      coloUserBit |-> [i \in 1 .. 1 |-> 0],
      reserved7   |-> [i \in 1 .. 7 |-> 0] ]

(* Cancel On Logout Status Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOnLogoutStatusRequestMessage ==
    { ZeroCancelOnLogoutStatusRequestMessage }
        \cup { [ZeroCancelOnLogoutStatusRequestMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroCancelOnLogoutStatusRequestMessage EXCEPT !.coloUserBit = one] : one \in Sample(1) }
        \cup { [ZeroCancelOnLogoutStatusRequestMessage EXCEPT !.reserved7 = one] : one \in Sample(7) }

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
(* Auction Inquiry Request Message: 16 bytes                               *)
(***************************************************************************)

AuctionInquiryRequestMessage ==
    [ secInfo       : SecInfo,
      auctionNo     : Sample(2),
      pageIndicator : Sample(1),
      filler        : Sample(1) ]

EncodeAuctionInquiryRequestMessage(message) ==
    EncodeSecInfo(message.secInfo)
        \o message.auctionNo
        \o message.pageIndicator
        \o message.filler

DecodeAuctionInquiryRequestMessage(bytes) ==
    LET secInfo == DecodeSecInfo(bytes) IN IF ~secInfo.ok THEN Fail ELSE
    LET auctionNo == ReadBytes(secInfo.rest, 2) IN IF ~auctionNo.ok THEN Fail ELSE
    LET pageIndicator == ReadBytes(auctionNo.rest, 1) IN IF ~pageIndicator.ok THEN Fail ELSE
    LET filler == ReadBytes(pageIndicator.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    Ok([ secInfo       |-> secInfo.value,
         auctionNo     |-> auctionNo.value,
         pageIndicator |-> pageIndicator.value,
         filler        |-> filler.value ], filler.rest)

ZeroAuctionInquiryRequestMessage ==
    [ secInfo       |-> ZeroSecInfo,
      auctionNo     |-> [i \in 1 .. 2 |-> 0],
      pageIndicator |-> [i \in 1 .. 1 |-> 0],
      filler        |-> [i \in 1 .. 1 |-> 0] ]

(* Auction Inquiry Request Message at zero, then each field in turn at the values it is checked at *)
CheckedAuctionInquiryRequestMessage ==
    { ZeroAuctionInquiryRequestMessage }
        \cup { [ZeroAuctionInquiryRequestMessage EXCEPT !.secInfo = one] : one \in CheckedSecInfo }
        \cup { [ZeroAuctionInquiryRequestMessage EXCEPT !.auctionNo = one] : one \in Sample(2) }
        \cup { [ZeroAuctionInquiryRequestMessage EXCEPT !.pageIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAuctionInquiryRequestMessage EXCEPT !.filler = one] : one \in Sample(1) }

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
(* Order Entry In Message: 250 bytes                                       *)
(***************************************************************************)

OrderEntryInMessage ==
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
      goodTillDate          : Sample(4),
      entryDateTime         : Sample(4),
      minFillAon            : Sample(4),
      lastModified          : Sample(4),
      stOrderFlags          : Sample(2),
      branchId              : Sample(2),
      traderId              : Sample(4),
      brokerId              : Sample(5),
      oeRemarks             : Sample(25),
      settlor               : Sample(12),
      proClient             : Sample(2),
      settlementType        : Sample(2),
      nnfField              : Sample(8),
      execTimeStamp         : Sample(8),
      secondReserved4       : Sample(4),
      pan                   : Sample(10),
      algoId                : Sample(4),
      reserved2             : Sample(2),
      lastActivityReference : Sample(8),
      reserved52            : Sample(52) ]

EncodeOrderEntryInMessage(message) ==
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
        \o message.goodTillDate
        \o message.entryDateTime
        \o message.minFillAon
        \o message.lastModified
        \o message.stOrderFlags
        \o message.branchId
        \o message.traderId
        \o message.brokerId
        \o message.oeRemarks
        \o message.settlor
        \o message.proClient
        \o message.settlementType
        \o message.nnfField
        \o message.execTimeStamp
        \o message.secondReserved4
        \o message.pan
        \o message.algoId
        \o message.reserved2
        \o message.lastActivityReference
        \o message.reserved52

DecodeOrderEntryInMessage(bytes) ==
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
    LET goodTillDate == ReadBytes(triggerPrice.rest, 4) IN IF ~goodTillDate.ok THEN Fail ELSE
    LET entryDateTime == ReadBytes(goodTillDate.rest, 4) IN IF ~entryDateTime.ok THEN Fail ELSE
    LET minFillAon == ReadBytes(entryDateTime.rest, 4) IN IF ~minFillAon.ok THEN Fail ELSE
    LET lastModified == ReadBytes(minFillAon.rest, 4) IN IF ~lastModified.ok THEN Fail ELSE
    LET stOrderFlags == ReadBytes(lastModified.rest, 2) IN IF ~stOrderFlags.ok THEN Fail ELSE
    LET branchId == ReadBytes(stOrderFlags.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET traderId == ReadBytes(branchId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(traderId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET oeRemarks == ReadBytes(brokerId.rest, 25) IN IF ~oeRemarks.ok THEN Fail ELSE
    LET settlor == ReadBytes(oeRemarks.rest, 12) IN IF ~settlor.ok THEN Fail ELSE
    LET proClient == ReadBytes(settlor.rest, 2) IN IF ~proClient.ok THEN Fail ELSE
    LET settlementType == ReadBytes(proClient.rest, 2) IN IF ~settlementType.ok THEN Fail ELSE
    LET nnfField == ReadBytes(settlementType.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET execTimeStamp == ReadBytes(nnfField.rest, 8) IN IF ~execTimeStamp.ok THEN Fail ELSE
    LET secondReserved4 == ReadBytes(execTimeStamp.rest, 4) IN IF ~secondReserved4.ok THEN Fail ELSE
    LET pan == ReadBytes(secondReserved4.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(algoId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(reserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
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
         goodTillDate          |-> goodTillDate.value,
         entryDateTime         |-> entryDateTime.value,
         minFillAon            |-> minFillAon.value,
         lastModified          |-> lastModified.value,
         stOrderFlags          |-> stOrderFlags.value,
         branchId              |-> branchId.value,
         traderId              |-> traderId.value,
         brokerId              |-> brokerId.value,
         oeRemarks             |-> oeRemarks.value,
         settlor               |-> settlor.value,
         proClient             |-> proClient.value,
         settlementType        |-> settlementType.value,
         nnfField              |-> nnfField.value,
         execTimeStamp         |-> execTimeStamp.value,
         secondReserved4       |-> secondReserved4.value,
         pan                   |-> pan.value,
         algoId                |-> algoId.value,
         reserved2             |-> reserved2.value,
         lastActivityReference |-> lastActivityReference.value,
         reserved52            |-> reserved52.value ], reserved52.rest)

ZeroOrderEntryInMessage ==
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
      goodTillDate          |-> [i \in 1 .. 4 |-> 0],
      entryDateTime         |-> [i \in 1 .. 4 |-> 0],
      minFillAon            |-> [i \in 1 .. 4 |-> 0],
      lastModified          |-> [i \in 1 .. 4 |-> 0],
      stOrderFlags          |-> [i \in 1 .. 2 |-> 0],
      branchId              |-> [i \in 1 .. 2 |-> 0],
      traderId              |-> [i \in 1 .. 4 |-> 0],
      brokerId              |-> [i \in 1 .. 5 |-> 0],
      oeRemarks             |-> [i \in 1 .. 25 |-> 0],
      settlor               |-> [i \in 1 .. 12 |-> 0],
      proClient             |-> [i \in 1 .. 2 |-> 0],
      settlementType        |-> [i \in 1 .. 2 |-> 0],
      nnfField              |-> [i \in 1 .. 8 |-> 0],
      execTimeStamp         |-> [i \in 1 .. 8 |-> 0],
      secondReserved4       |-> [i \in 1 .. 4 |-> 0],
      pan                   |-> [i \in 1 .. 10 |-> 0],
      algoId                |-> [i \in 1 .. 4 |-> 0],
      reserved2             |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference |-> [i \in 1 .. 8 |-> 0],
      reserved52            |-> [i \in 1 .. 52 |-> 0] ]

(* Order Entry In Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderEntryInMessage ==
    { ZeroOrderEntryInMessage }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.modCxlBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.filler9 = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.secInfo = one] : one \in CheckedSecInfo2 }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.auctionNumber = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.opBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.suspended = one] : one \in Sample(1) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.bookType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.disclosedVol = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.disclosedVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.totalVolRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.minFillAon = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.oeRemarks = one] : one \in Sample(25) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.proClient = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.settlementType = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.execTimeStamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.secondReserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderEntryInMessage EXCEPT !.reserved52 = one] : one \in Sample(52) }

(***************************************************************************)
(* Order Limit Update In Message: 28 bytes                                 *)
(***************************************************************************)

OrderLimitUpdateInMessage ==
    [ brokerId      : Sample(5),
      reserved1     : Sample(1),
      userId        : Sample(4),
      orderQtyLimit : Sample(8),
      orderValLimit : Sample(8),
      reserved2     : Sample(2) ]

EncodeOrderLimitUpdateInMessage(message) ==
    message.brokerId
        \o message.reserved1
        \o message.userId
        \o message.orderQtyLimit
        \o message.orderValLimit
        \o message.reserved2

DecodeOrderLimitUpdateInMessage(bytes) ==
    LET brokerId == ReadBytes(bytes, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(brokerId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET userId == ReadBytes(reserved1.rest, 4) IN IF ~userId.ok THEN Fail ELSE
    LET orderQtyLimit == ReadBytes(userId.rest, 8) IN IF ~orderQtyLimit.ok THEN Fail ELSE
    LET orderValLimit == ReadBytes(orderQtyLimit.rest, 8) IN IF ~orderValLimit.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(orderValLimit.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    Ok([ brokerId      |-> brokerId.value,
         reserved1     |-> reserved1.value,
         userId        |-> userId.value,
         orderQtyLimit |-> orderQtyLimit.value,
         orderValLimit |-> orderValLimit.value,
         reserved2     |-> reserved2.value ], reserved2.rest)

ZeroOrderLimitUpdateInMessage ==
    [ brokerId      |-> [i \in 1 .. 5 |-> 0],
      reserved1     |-> [i \in 1 .. 1 |-> 0],
      userId        |-> [i \in 1 .. 4 |-> 0],
      orderQtyLimit |-> [i \in 1 .. 8 |-> 0],
      orderValLimit |-> [i \in 1 .. 8 |-> 0],
      reserved2     |-> [i \in 1 .. 2 |-> 0] ]

(* Order Limit Update In Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderLimitUpdateInMessage ==
    { ZeroOrderLimitUpdateInMessage }
        \cup { [ZeroOrderLimitUpdateInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderLimitUpdateInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderLimitUpdateInMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroOrderLimitUpdateInMessage EXCEPT !.orderQtyLimit = one] : one \in Sample(8) }
        \cup { [ZeroOrderLimitUpdateInMessage EXCEPT !.orderValLimit = one] : one \in Sample(8) }
        \cup { [ZeroOrderLimitUpdateInMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }

(***************************************************************************)
(* Password Reset In Message: 18 bytes                                     *)
(***************************************************************************)

PasswordResetInMessage ==
    [ userId     : Sample(4),
      reserved14 : Sample(14) ]

EncodePasswordResetInMessage(message) ==
    message.userId
        \o message.reserved14

DecodePasswordResetInMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET reserved14 == ReadBytes(userId.rest, 14) IN IF ~reserved14.ok THEN Fail ELSE
    Ok([ userId     |-> userId.value,
         reserved14 |-> reserved14.value ], reserved14.rest)

ZeroPasswordResetInMessage ==
    [ userId     |-> [i \in 1 .. 4 |-> 0],
      reserved14 |-> [i \in 1 .. 14 |-> 0] ]

(* Password Reset In Message at zero, then each field in turn at the values it is checked at *)
CheckedPasswordResetInMessage ==
    { ZeroPasswordResetInMessage }
        \cup { [ZeroPasswordResetInMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroPasswordResetInMessage EXCEPT !.reserved14 = one] : one \in Sample(14) }

(***************************************************************************)
(* Sign On Request In Message: 236 bytes                                   *)
(***************************************************************************)

SignOnRequestInMessage ==
    [ userId                     : Sample(4),
      reserved8                  : Sample(8),
      password                   : Sample(8),
      secondReserved8            : Sample(8),
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
      brokerName                 : Sample(26),
      reserved16                 : Sample(16),
      secondReserved16           : Sample(16),
      thirdReserved16            : Sample(16) ]

EncodeSignOnRequestInMessage(message) ==
    message.userId
        \o message.reserved8
        \o message.password
        \o message.secondReserved8
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
    LET brokerName == ReadBytes(brokerEligibilityPerMarket.rest, 26) IN IF ~brokerName.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(brokerName.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    LET secondReserved16 == ReadBytes(reserved16.rest, 16) IN IF ~secondReserved16.ok THEN Fail ELSE
    LET thirdReserved16 == ReadBytes(secondReserved16.rest, 16) IN IF ~thirdReserved16.ok THEN Fail ELSE
    Ok([ userId                     |-> userId.value,
         reserved8                  |-> reserved8.value,
         password                   |-> password.value,
         secondReserved8            |-> secondReserved8.value,
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
         brokerName                 |-> brokerName.value,
         reserved16                 |-> reserved16.value,
         secondReserved16           |-> secondReserved16.value,
         thirdReserved16            |-> thirdReserved16.value ], thirdReserved16.rest)

ZeroSignOnRequestInMessage ==
    [ userId                     |-> [i \in 1 .. 4 |-> 0],
      reserved8                  |-> [i \in 1 .. 8 |-> 0],
      password                   |-> [i \in 1 .. 8 |-> 0],
      secondReserved8            |-> [i \in 1 .. 8 |-> 0],
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
      brokerName                 |-> [i \in 1 .. 26 |-> 0],
      reserved16                 |-> [i \in 1 .. 16 |-> 0],
      secondReserved16           |-> [i \in 1 .. 16 |-> 0],
      thirdReserved16            |-> [i \in 1 .. 16 |-> 0] ]

(* Sign On Request In Message at zero, then each field in turn at the values it is checked at *)
CheckedSignOnRequestInMessage ==
    { ZeroSignOnRequestInMessage }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.password = one] : one \in Sample(8) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.newPassword = one] : one \in Sample(8) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.traderName = one] : one \in Sample(26) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.lastPasswordChangeDateTime = one] : one \in Sample(4) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.versionNumber = one] : one \in Sample(4) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.reserved56 = one] : one \in Sample(56) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.userType = one] : one \in Sample(2) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.workstationNumber = one] : one \in Sample(14) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.brokerStatus = one] : one \in Sample(1) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.showIndex = one] : one \in Sample(1) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.brokerEligibilityPerMarket = one] : one \in Sample(2) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.brokerName = one] : one \in Sample(26) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.secondReserved16 = one] : one \in Sample(16) }
        \cup { [ZeroSignOnRequestInMessage EXCEPT !.thirdReserved16 = one] : one \in Sample(16) }

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
(* Trade Inquiry In Message: 170 bytes                                     *)
(***************************************************************************)

TradeInquiryInMessage ==
    [ secInfo           : SecInfo3,
      fillNumber        : Sample(4),
      fillQty           : Sample(4),
      fillPrice         : Sample(4),
      marketType        : Sample(2),
      newVolume         : Sample(4),
      reserved24        : Sample(24),
      buyBrokerId       : Sample(5),
      sellBrokerId      : Sample(5),
      traderId          : Sample(4),
      requestedBy       : Sample(2),
      buyAccountNumber  : Sample(10),
      sellAccountNumber : Sample(10),
      buyPan            : Sample(10),
      sellPan           : Sample(10),
      reserved60        : Sample(60) ]

EncodeTradeInquiryInMessage(message) ==
    EncodeSecInfo3(message.secInfo)
        \o message.fillNumber
        \o message.fillQty
        \o message.fillPrice
        \o message.marketType
        \o message.newVolume
        \o message.reserved24
        \o message.buyBrokerId
        \o message.sellBrokerId
        \o message.traderId
        \o message.requestedBy
        \o message.buyAccountNumber
        \o message.sellAccountNumber
        \o message.buyPan
        \o message.sellPan
        \o message.reserved60

DecodeTradeInquiryInMessage(bytes) ==
    LET secInfo == DecodeSecInfo3(bytes) IN IF ~secInfo.ok THEN Fail ELSE
    LET fillNumber == ReadBytes(secInfo.rest, 4) IN IF ~fillNumber.ok THEN Fail ELSE
    LET fillQty == ReadBytes(fillNumber.rest, 4) IN IF ~fillQty.ok THEN Fail ELSE
    LET fillPrice == ReadBytes(fillQty.rest, 4) IN IF ~fillPrice.ok THEN Fail ELSE
    LET marketType == ReadBytes(fillPrice.rest, 2) IN IF ~marketType.ok THEN Fail ELSE
    LET newVolume == ReadBytes(marketType.rest, 4) IN IF ~newVolume.ok THEN Fail ELSE
    LET reserved24 == ReadBytes(newVolume.rest, 24) IN IF ~reserved24.ok THEN Fail ELSE
    LET buyBrokerId == ReadBytes(reserved24.rest, 5) IN IF ~buyBrokerId.ok THEN Fail ELSE
    LET sellBrokerId == ReadBytes(buyBrokerId.rest, 5) IN IF ~sellBrokerId.ok THEN Fail ELSE
    LET traderId == ReadBytes(sellBrokerId.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET requestedBy == ReadBytes(traderId.rest, 2) IN IF ~requestedBy.ok THEN Fail ELSE
    LET buyAccountNumber == ReadBytes(requestedBy.rest, 10) IN IF ~buyAccountNumber.ok THEN Fail ELSE
    LET sellAccountNumber == ReadBytes(buyAccountNumber.rest, 10) IN IF ~sellAccountNumber.ok THEN Fail ELSE
    LET buyPan == ReadBytes(sellAccountNumber.rest, 10) IN IF ~buyPan.ok THEN Fail ELSE
    LET sellPan == ReadBytes(buyPan.rest, 10) IN IF ~sellPan.ok THEN Fail ELSE
    LET reserved60 == ReadBytes(sellPan.rest, 60) IN IF ~reserved60.ok THEN Fail ELSE
    Ok([ secInfo           |-> secInfo.value,
         fillNumber        |-> fillNumber.value,
         fillQty           |-> fillQty.value,
         fillPrice         |-> fillPrice.value,
         marketType        |-> marketType.value,
         newVolume         |-> newVolume.value,
         reserved24        |-> reserved24.value,
         buyBrokerId       |-> buyBrokerId.value,
         sellBrokerId      |-> sellBrokerId.value,
         traderId          |-> traderId.value,
         requestedBy       |-> requestedBy.value,
         buyAccountNumber  |-> buyAccountNumber.value,
         sellAccountNumber |-> sellAccountNumber.value,
         buyPan            |-> buyPan.value,
         sellPan           |-> sellPan.value,
         reserved60        |-> reserved60.value ], reserved60.rest)

ZeroTradeInquiryInMessage ==
    [ secInfo           |-> ZeroSecInfo3,
      fillNumber        |-> [i \in 1 .. 4 |-> 0],
      fillQty           |-> [i \in 1 .. 4 |-> 0],
      fillPrice         |-> [i \in 1 .. 4 |-> 0],
      marketType        |-> [i \in 1 .. 2 |-> 0],
      newVolume         |-> [i \in 1 .. 4 |-> 0],
      reserved24        |-> [i \in 1 .. 24 |-> 0],
      buyBrokerId       |-> [i \in 1 .. 5 |-> 0],
      sellBrokerId      |-> [i \in 1 .. 5 |-> 0],
      traderId          |-> [i \in 1 .. 4 |-> 0],
      requestedBy       |-> [i \in 1 .. 2 |-> 0],
      buyAccountNumber  |-> [i \in 1 .. 10 |-> 0],
      sellAccountNumber |-> [i \in 1 .. 10 |-> 0],
      buyPan            |-> [i \in 1 .. 10 |-> 0],
      sellPan           |-> [i \in 1 .. 10 |-> 0],
      reserved60        |-> [i \in 1 .. 60 |-> 0] ]

(* Trade Inquiry In Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeInquiryInMessage ==
    { ZeroTradeInquiryInMessage }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.secInfo = one] : one \in CheckedSecInfo3 }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.fillQty = one] : one \in Sample(4) }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.marketType = one] : one \in Sample(2) }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.newVolume = one] : one \in Sample(4) }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.reserved24 = one] : one \in Sample(24) }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.buyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.sellBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.requestedBy = one] : one \in Sample(2) }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.buyAccountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.sellAccountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.buyPan = one] : one \in Sample(10) }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.sellPan = one] : one \in Sample(10) }
        \cup { [ZeroTradeInquiryInMessage EXCEPT !.reserved60 = one] : one \in Sample(60) }

(***************************************************************************)
(* Update Local Database Request Message: 22 bytes                         *)
(***************************************************************************)

UpdateLocalDatabaseRequestMessage ==
    [ lastUpdateSecurityTime    : Sample(4),
      lastUpdateParticipantTime : Sample(4),
      requestForOpenOrders      : Sample(1),
      reserved1                 : Sample(1),
      normalMarketStatus        : Sample(2),
      oddLotMarketStatus        : Sample(2),
      spotMarketStatus          : Sample(2),
      auctionMarketStatus       : Sample(2),
      callAuction1MarketStatus  : Sample(2),
      callAuction2MarketStatus  : Sample(2) ]

EncodeUpdateLocalDatabaseRequestMessage(message) ==
    message.lastUpdateSecurityTime
        \o message.lastUpdateParticipantTime
        \o message.requestForOpenOrders
        \o message.reserved1
        \o message.normalMarketStatus
        \o message.oddLotMarketStatus
        \o message.spotMarketStatus
        \o message.auctionMarketStatus
        \o message.callAuction1MarketStatus
        \o message.callAuction2MarketStatus

DecodeUpdateLocalDatabaseRequestMessage(bytes) ==
    LET lastUpdateSecurityTime == ReadBytes(bytes, 4) IN IF ~lastUpdateSecurityTime.ok THEN Fail ELSE
    LET lastUpdateParticipantTime == ReadBytes(lastUpdateSecurityTime.rest, 4) IN IF ~lastUpdateParticipantTime.ok THEN Fail ELSE
    LET requestForOpenOrders == ReadBytes(lastUpdateParticipantTime.rest, 1) IN IF ~requestForOpenOrders.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(requestForOpenOrders.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET normalMarketStatus == ReadBytes(reserved1.rest, 2) IN IF ~normalMarketStatus.ok THEN Fail ELSE
    LET oddLotMarketStatus == ReadBytes(normalMarketStatus.rest, 2) IN IF ~oddLotMarketStatus.ok THEN Fail ELSE
    LET spotMarketStatus == ReadBytes(oddLotMarketStatus.rest, 2) IN IF ~spotMarketStatus.ok THEN Fail ELSE
    LET auctionMarketStatus == ReadBytes(spotMarketStatus.rest, 2) IN IF ~auctionMarketStatus.ok THEN Fail ELSE
    LET callAuction1MarketStatus == ReadBytes(auctionMarketStatus.rest, 2) IN IF ~callAuction1MarketStatus.ok THEN Fail ELSE
    LET callAuction2MarketStatus == ReadBytes(callAuction1MarketStatus.rest, 2) IN IF ~callAuction2MarketStatus.ok THEN Fail ELSE
    Ok([ lastUpdateSecurityTime    |-> lastUpdateSecurityTime.value,
         lastUpdateParticipantTime |-> lastUpdateParticipantTime.value,
         requestForOpenOrders      |-> requestForOpenOrders.value,
         reserved1                 |-> reserved1.value,
         normalMarketStatus        |-> normalMarketStatus.value,
         oddLotMarketStatus        |-> oddLotMarketStatus.value,
         spotMarketStatus          |-> spotMarketStatus.value,
         auctionMarketStatus       |-> auctionMarketStatus.value,
         callAuction1MarketStatus  |-> callAuction1MarketStatus.value,
         callAuction2MarketStatus  |-> callAuction2MarketStatus.value ], callAuction2MarketStatus.rest)

ZeroUpdateLocalDatabaseRequestMessage ==
    [ lastUpdateSecurityTime    |-> [i \in 1 .. 4 |-> 0],
      lastUpdateParticipantTime |-> [i \in 1 .. 4 |-> 0],
      requestForOpenOrders      |-> [i \in 1 .. 1 |-> 0],
      reserved1                 |-> [i \in 1 .. 1 |-> 0],
      normalMarketStatus        |-> [i \in 1 .. 2 |-> 0],
      oddLotMarketStatus        |-> [i \in 1 .. 2 |-> 0],
      spotMarketStatus          |-> [i \in 1 .. 2 |-> 0],
      auctionMarketStatus       |-> [i \in 1 .. 2 |-> 0],
      callAuction1MarketStatus  |-> [i \in 1 .. 2 |-> 0],
      callAuction2MarketStatus  |-> [i \in 1 .. 2 |-> 0] ]

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
        \cup { [ZeroUpdateLocalDatabaseRequestMessage EXCEPT !.callAuction1MarketStatus = one] : one \in Sample(2) }
        \cup { [ZeroUpdateLocalDatabaseRequestMessage EXCEPT !.callAuction2MarketStatus = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Modification Cancellation Status Request Message: 12 bytes        *)
(***************************************************************************)

TradeModificationCancellationStatusRequestMessage ==
    [ userId       : Sample(4),
      trdModCxlBit : Sample(1),
      reserved7    : Sample(7) ]

EncodeTradeModificationCancellationStatusRequestMessage(message) ==
    message.userId
        \o message.trdModCxlBit
        \o message.reserved7

DecodeTradeModificationCancellationStatusRequestMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET trdModCxlBit == ReadBytes(userId.rest, 1) IN IF ~trdModCxlBit.ok THEN Fail ELSE
    LET reserved7 == ReadBytes(trdModCxlBit.rest, 7) IN IF ~reserved7.ok THEN Fail ELSE
    Ok([ userId       |-> userId.value,
         trdModCxlBit |-> trdModCxlBit.value,
         reserved7    |-> reserved7.value ], reserved7.rest)

ZeroTradeModificationCancellationStatusRequestMessage ==
    [ userId       |-> [i \in 1 .. 4 |-> 0],
      trdModCxlBit |-> [i \in 1 .. 1 |-> 0],
      reserved7    |-> [i \in 1 .. 7 |-> 0] ]

(* Trade Modification Cancellation Status Request Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeModificationCancellationStatusRequestMessage ==
    { ZeroTradeModificationCancellationStatusRequestMessage }
        \cup { [ZeroTradeModificationCancellationStatusRequestMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroTradeModificationCancellationStatusRequestMessage EXCEPT !.trdModCxlBit = one] : one \in Sample(1) }
        \cup { [ZeroTradeModificationCancellationStatusRequestMessage EXCEPT !.reserved7 = one] : one \in Sample(7) }

(***************************************************************************)
(* User Unlock Request Message: 28 bytes                                   *)
(***************************************************************************)

UserUnlockRequestMessage ==
    [ userId     : Sample(4),
      reserved24 : Sample(24) ]

EncodeUserUnlockRequestMessage(message) ==
    message.userId
        \o message.reserved24

DecodeUserUnlockRequestMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET reserved24 == ReadBytes(userId.rest, 24) IN IF ~reserved24.ok THEN Fail ELSE
    Ok([ userId     |-> userId.value,
         reserved24 |-> reserved24.value ], reserved24.rest)

ZeroUserUnlockRequestMessage ==
    [ userId     |-> [i \in 1 .. 4 |-> 0],
      reserved24 |-> [i \in 1 .. 24 |-> 0] ]

(* User Unlock Request Message at zero, then each field in turn at the values it is checked at *)
CheckedUserUnlockRequestMessage ==
    { ZeroUserUnlockRequestMessage }
        \cup { [ZeroUserUnlockRequestMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroUserUnlockRequestMessage EXCEPT !.reserved24 = one] : one \in Sample(24) }

(***************************************************************************)
(* User Limits: 64 bytes                                                   *)
(***************************************************************************)

UserLimits ==
    [ reserved16              : Sample(16),
      userOrderBuyValueLimit  : Sample(8),
      reserved24              : Sample(24),
      userOrderSellValueLimit : Sample(8),
      reserved8               : Sample(8) ]

EncodeUserLimits(message) ==
    message.reserved16
        \o message.userOrderBuyValueLimit
        \o message.reserved24
        \o message.userOrderSellValueLimit
        \o message.reserved8

DecodeUserLimits(bytes) ==
    LET reserved16 == ReadBytes(bytes, 16) IN IF ~reserved16.ok THEN Fail ELSE
    LET userOrderBuyValueLimit == ReadBytes(reserved16.rest, 8) IN IF ~userOrderBuyValueLimit.ok THEN Fail ELSE
    LET reserved24 == ReadBytes(userOrderBuyValueLimit.rest, 24) IN IF ~reserved24.ok THEN Fail ELSE
    LET userOrderSellValueLimit == ReadBytes(reserved24.rest, 8) IN IF ~userOrderSellValueLimit.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(userOrderSellValueLimit.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    Ok([ reserved16              |-> reserved16.value,
         userOrderBuyValueLimit  |-> userOrderBuyValueLimit.value,
         reserved24              |-> reserved24.value,
         userOrderSellValueLimit |-> userOrderSellValueLimit.value,
         reserved8               |-> reserved8.value ], reserved8.rest)

ZeroUserLimits ==
    [ reserved16              |-> [i \in 1 .. 16 |-> 0],
      userOrderBuyValueLimit  |-> [i \in 1 .. 8 |-> 0],
      reserved24              |-> [i \in 1 .. 24 |-> 0],
      userOrderSellValueLimit |-> [i \in 1 .. 8 |-> 0],
      reserved8               |-> [i \in 1 .. 8 |-> 0] ]

(* User Limits at zero, then each field in turn at the values it is checked at *)
CheckedUserLimits ==
    { ZeroUserLimits }
        \cup { [ZeroUserLimits EXCEPT !.reserved16 = one] : one \in Sample(16) }
        \cup { [ZeroUserLimits EXCEPT !.userOrderBuyValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroUserLimits EXCEPT !.reserved24 = one] : one \in Sample(24) }
        \cup { [ZeroUserLimits EXCEPT !.userOrderSellValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroUserLimits EXCEPT !.reserved8 = one] : one \in Sample(8) }

(***************************************************************************)
(* User Order Value Limit Update In Message: 102 bytes                     *)
(***************************************************************************)

UserOrderValueLimitUpdateInMessage ==
    [ brokerId   : Sample(5),
      reserved1  : Sample(1),
      branch     : Sample(2),
      reserved26 : Sample(26),
      userId     : Sample(4),
      userLimits : UserLimits ]

EncodeUserOrderValueLimitUpdateInMessage(message) ==
    message.brokerId
        \o message.reserved1
        \o message.branch
        \o message.reserved26
        \o message.userId
        \o EncodeUserLimits(message.userLimits)

DecodeUserOrderValueLimitUpdateInMessage(bytes) ==
    LET brokerId == ReadBytes(bytes, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(brokerId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET branch == ReadBytes(reserved1.rest, 2) IN IF ~branch.ok THEN Fail ELSE
    LET reserved26 == ReadBytes(branch.rest, 26) IN IF ~reserved26.ok THEN Fail ELSE
    LET userId == ReadBytes(reserved26.rest, 4) IN IF ~userId.ok THEN Fail ELSE
    LET userLimits == DecodeUserLimits(userId.rest) IN IF ~userLimits.ok THEN Fail ELSE
    Ok([ brokerId   |-> brokerId.value,
         reserved1  |-> reserved1.value,
         branch     |-> branch.value,
         reserved26 |-> reserved26.value,
         userId     |-> userId.value,
         userLimits |-> userLimits.value ], userLimits.rest)

ZeroUserOrderValueLimitUpdateInMessage ==
    [ brokerId   |-> [i \in 1 .. 5 |-> 0],
      reserved1  |-> [i \in 1 .. 1 |-> 0],
      branch     |-> [i \in 1 .. 2 |-> 0],
      reserved26 |-> [i \in 1 .. 26 |-> 0],
      userId     |-> [i \in 1 .. 4 |-> 0],
      userLimits |-> ZeroUserLimits ]

(* User Order Value Limit Update In Message at zero, then each field in turn at the values it is checked at *)
CheckedUserOrderValueLimitUpdateInMessage ==
    { ZeroUserOrderValueLimitUpdateInMessage }
        \cup { [ZeroUserOrderValueLimitUpdateInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroUserOrderValueLimitUpdateInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroUserOrderValueLimitUpdateInMessage EXCEPT !.branch = one] : one \in Sample(2) }
        \cup { [ZeroUserOrderValueLimitUpdateInMessage EXCEPT !.reserved26 = one] : one \in Sample(26) }
        \cup { [ZeroUserOrderValueLimitUpdateInMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroUserOrderValueLimitUpdateInMessage EXCEPT !.userLimits = one] : one \in CheckedUserLimits }

(***************************************************************************)
(* Client Message Payload, selected by Transaction Code                    *)
(***************************************************************************)

BranchOrderValueLimitUpdateInMessageCode == 5716  \* 0x1654
CancelOnLogoutStatusRequestMessageCode == 5790  \* 0x169e
MessageDownloadRequestMessageCode == 7000  \* 0x1b58
AuctionInquiryRequestMessageCode == 18016  \* 0x4660
BoxSignOffMessageCode == 20322  \* 0x4f62
BoxSignOnRequestMessageCode == 23000  \* 0x59d8
GatewayRouterRequestMessageCode == 2400  \* 0x960
OrderEntryInMessageCode == 2000  \* 0x7d0
OrderEntryInMessageCode2 == 2040  \* 0x7f8
OrderEntryInMessageCode3 == 2062  \* 0x80e
OrderEntryInMessageCode4 == 2070  \* 0x816
OrderLimitUpdateInMessageCode == 5721  \* 0x1659
PasswordResetInMessageCode == 5738  \* 0x166a
SignOnRequestInMessageCode == 2300  \* 0x8fc
SignOnRequestInMessageCode2 == 5723  \* 0x165b
TradeInquiryInMessageCode == 5440  \* 0x1540
TradeInquiryInMessageCode2 == 5445  \* 0x1545
UpdateLocalDatabaseRequestMessageCode == 7300  \* 0x1c84
TradeModificationCancellationStatusRequestMessageCode == 5792  \* 0x16a0
UserUnlockRequestMessageCode == 5424  \* 0x1530
UserOrderValueLimitUpdateInMessageCode == 5719  \* 0x1657

ClientMessagePayload ==
    [ tag : {BranchOrderValueLimitUpdateInMessageCode}, body : BranchOrderValueLimitUpdateInMessage ]
        \cup [ tag : {CancelOnLogoutStatusRequestMessageCode}, body : CancelOnLogoutStatusRequestMessage ]
        \cup [ tag : {MessageDownloadRequestMessageCode}, body : MessageDownloadRequestMessage ]
        \cup [ tag : {AuctionInquiryRequestMessageCode}, body : AuctionInquiryRequestMessage ]
        \cup [ tag : {BoxSignOffMessageCode}, body : BoxSignOffMessage ]
        \cup [ tag : {BoxSignOnRequestMessageCode}, body : BoxSignOnRequestMessage ]
        \cup [ tag : {GatewayRouterRequestMessageCode}, body : GatewayRouterRequestMessage ]
        \cup [ tag : {OrderEntryInMessageCode}, body : OrderEntryInMessage ]
        \cup [ tag : {OrderEntryInMessageCode2}, body : OrderEntryInMessage ]
        \cup [ tag : {OrderEntryInMessageCode3}, body : OrderEntryInMessage ]
        \cup [ tag : {OrderEntryInMessageCode4}, body : OrderEntryInMessage ]
        \cup [ tag : {OrderLimitUpdateInMessageCode}, body : OrderLimitUpdateInMessage ]
        \cup [ tag : {PasswordResetInMessageCode}, body : PasswordResetInMessage ]
        \cup [ tag : {SignOnRequestInMessageCode}, body : SignOnRequestInMessage ]
        \cup [ tag : {SignOnRequestInMessageCode2}, body : SignOnRequestInMessage ]
        \cup [ tag : {TradeInquiryInMessageCode}, body : TradeInquiryInMessage ]
        \cup [ tag : {TradeInquiryInMessageCode2}, body : TradeInquiryInMessage ]
        \cup [ tag : {UpdateLocalDatabaseRequestMessageCode}, body : UpdateLocalDatabaseRequestMessage ]
        \cup [ tag : {TradeModificationCancellationStatusRequestMessageCode}, body : TradeModificationCancellationStatusRequestMessage ]
        \cup [ tag : {UserUnlockRequestMessageCode}, body : UserUnlockRequestMessage ]
        \cup [ tag : {UserOrderValueLimitUpdateInMessageCode}, body : UserOrderValueLimitUpdateInMessage ]

EncodeClientMessagePayload(message) ==
    CASE message.tag = BranchOrderValueLimitUpdateInMessageCode -> EncodeBranchOrderValueLimitUpdateInMessage(message.body)
      [] message.tag = CancelOnLogoutStatusRequestMessageCode -> EncodeCancelOnLogoutStatusRequestMessage(message.body)
      [] message.tag = MessageDownloadRequestMessageCode -> EncodeMessageDownloadRequestMessage(message.body)
      [] message.tag = AuctionInquiryRequestMessageCode -> EncodeAuctionInquiryRequestMessage(message.body)
      [] message.tag = BoxSignOffMessageCode -> EncodeBoxSignOffMessage(message.body)
      [] message.tag = BoxSignOnRequestMessageCode -> EncodeBoxSignOnRequestMessage(message.body)
      [] message.tag = GatewayRouterRequestMessageCode -> EncodeGatewayRouterRequestMessage(message.body)
      [] message.tag = OrderEntryInMessageCode -> EncodeOrderEntryInMessage(message.body)
      [] message.tag = OrderEntryInMessageCode2 -> EncodeOrderEntryInMessage(message.body)
      [] message.tag = OrderEntryInMessageCode3 -> EncodeOrderEntryInMessage(message.body)
      [] message.tag = OrderEntryInMessageCode4 -> EncodeOrderEntryInMessage(message.body)
      [] message.tag = OrderLimitUpdateInMessageCode -> EncodeOrderLimitUpdateInMessage(message.body)
      [] message.tag = PasswordResetInMessageCode -> EncodePasswordResetInMessage(message.body)
      [] message.tag = SignOnRequestInMessageCode -> EncodeSignOnRequestInMessage(message.body)
      [] message.tag = SignOnRequestInMessageCode2 -> EncodeSignOnRequestInMessage(message.body)
      [] message.tag = TradeInquiryInMessageCode -> EncodeTradeInquiryInMessage(message.body)
      [] message.tag = TradeInquiryInMessageCode2 -> EncodeTradeInquiryInMessage(message.body)
      [] message.tag = UpdateLocalDatabaseRequestMessageCode -> EncodeUpdateLocalDatabaseRequestMessage(message.body)
      [] message.tag = TradeModificationCancellationStatusRequestMessageCode -> EncodeTradeModificationCancellationStatusRequestMessage(message.body)
      [] message.tag = UserUnlockRequestMessageCode -> EncodeUserUnlockRequestMessage(message.body)
      [] message.tag = UserOrderValueLimitUpdateInMessageCode -> EncodeUserOrderValueLimitUpdateInMessage(message.body)

DecodeClientMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = BranchOrderValueLimitUpdateInMessageCode -> DecodeBranchOrderValueLimitUpdateInMessage(bytes)
              [] tag = CancelOnLogoutStatusRequestMessageCode -> DecodeCancelOnLogoutStatusRequestMessage(bytes)
              [] tag = MessageDownloadRequestMessageCode -> DecodeMessageDownloadRequestMessage(bytes)
              [] tag = AuctionInquiryRequestMessageCode -> DecodeAuctionInquiryRequestMessage(bytes)
              [] tag = BoxSignOffMessageCode -> DecodeBoxSignOffMessage(bytes)
              [] tag = BoxSignOnRequestMessageCode -> DecodeBoxSignOnRequestMessage(bytes)
              [] tag = GatewayRouterRequestMessageCode -> DecodeGatewayRouterRequestMessage(bytes)
              [] tag = OrderEntryInMessageCode -> DecodeOrderEntryInMessage(bytes)
              [] tag = OrderEntryInMessageCode2 -> DecodeOrderEntryInMessage(bytes)
              [] tag = OrderEntryInMessageCode3 -> DecodeOrderEntryInMessage(bytes)
              [] tag = OrderEntryInMessageCode4 -> DecodeOrderEntryInMessage(bytes)
              [] tag = OrderLimitUpdateInMessageCode -> DecodeOrderLimitUpdateInMessage(bytes)
              [] tag = PasswordResetInMessageCode -> DecodePasswordResetInMessage(bytes)
              [] tag = SignOnRequestInMessageCode -> DecodeSignOnRequestInMessage(bytes)
              [] tag = SignOnRequestInMessageCode2 -> DecodeSignOnRequestInMessage(bytes)
              [] tag = TradeInquiryInMessageCode -> DecodeTradeInquiryInMessage(bytes)
              [] tag = TradeInquiryInMessageCode2 -> DecodeTradeInquiryInMessage(bytes)
              [] tag = UpdateLocalDatabaseRequestMessageCode -> DecodeUpdateLocalDatabaseRequestMessage(bytes)
              [] tag = TradeModificationCancellationStatusRequestMessageCode -> DecodeTradeModificationCancellationStatusRequestMessage(bytes)
              [] tag = UserUnlockRequestMessageCode -> DecodeUserUnlockRequestMessage(bytes)
              [] tag = UserOrderValueLimitUpdateInMessageCode -> DecodeUserOrderValueLimitUpdateInMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientMessagePayload == [tag |-> BranchOrderValueLimitUpdateInMessageCode, body |-> ZeroBranchOrderValueLimitUpdateInMessage]

(* Each Client Message Payload in turn, at the values the message it names is checked at *)
CheckedClientMessagePayload ==
    { [tag |-> BranchOrderValueLimitUpdateInMessageCode, body |-> one] : one \in CheckedBranchOrderValueLimitUpdateInMessage }
        \cup { [tag |-> CancelOnLogoutStatusRequestMessageCode, body |-> one] : one \in CheckedCancelOnLogoutStatusRequestMessage }
        \cup { [tag |-> MessageDownloadRequestMessageCode, body |-> one] : one \in CheckedMessageDownloadRequestMessage }
        \cup { [tag |-> AuctionInquiryRequestMessageCode, body |-> one] : one \in CheckedAuctionInquiryRequestMessage }
        \cup { [tag |-> BoxSignOffMessageCode, body |-> one] : one \in CheckedBoxSignOffMessage }
        \cup { [tag |-> BoxSignOnRequestMessageCode, body |-> one] : one \in CheckedBoxSignOnRequestMessage }
        \cup { [tag |-> GatewayRouterRequestMessageCode, body |-> one] : one \in CheckedGatewayRouterRequestMessage }
        \cup { [tag |-> OrderEntryInMessageCode, body |-> one] : one \in CheckedOrderEntryInMessage }
        \cup { [tag |-> OrderEntryInMessageCode2, body |-> one] : one \in CheckedOrderEntryInMessage }
        \cup { [tag |-> OrderEntryInMessageCode3, body |-> one] : one \in CheckedOrderEntryInMessage }
        \cup { [tag |-> OrderEntryInMessageCode4, body |-> one] : one \in CheckedOrderEntryInMessage }
        \cup { [tag |-> OrderLimitUpdateInMessageCode, body |-> one] : one \in CheckedOrderLimitUpdateInMessage }
        \cup { [tag |-> PasswordResetInMessageCode, body |-> one] : one \in CheckedPasswordResetInMessage }
        \cup { [tag |-> SignOnRequestInMessageCode, body |-> one] : one \in CheckedSignOnRequestInMessage }
        \cup { [tag |-> SignOnRequestInMessageCode2, body |-> one] : one \in CheckedSignOnRequestInMessage }
        \cup { [tag |-> TradeInquiryInMessageCode, body |-> one] : one \in CheckedTradeInquiryInMessage }
        \cup { [tag |-> TradeInquiryInMessageCode2, body |-> one] : one \in CheckedTradeInquiryInMessage }
        \cup { [tag |-> UpdateLocalDatabaseRequestMessageCode, body |-> one] : one \in CheckedUpdateLocalDatabaseRequestMessage }
        \cup { [tag |-> TradeModificationCancellationStatusRequestMessageCode, body |-> one] : one \in CheckedTradeModificationCancellationStatusRequestMessage }
        \cup { [tag |-> UserUnlockRequestMessageCode, body |-> one] : one \in CheckedUserUnlockRequestMessage }
        \cup { [tag |-> UserOrderValueLimitUpdateInMessageCode, body |-> one] : one \in CheckedUserOrderValueLimitUpdateInMessage }

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
    { [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> BranchOrderValueLimitUpdateInMessageCode, body |-> ZeroBranchOrderValueLimitUpdateInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> CancelOnLogoutStatusRequestMessageCode, body |-> ZeroCancelOnLogoutStatusRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> MessageDownloadRequestMessageCode, body |-> ZeroMessageDownloadRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> AuctionInquiryRequestMessageCode, body |-> ZeroAuctionInquiryRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> BoxSignOffMessageCode, body |-> ZeroBoxSignOffMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> BoxSignOnRequestMessageCode, body |-> ZeroBoxSignOnRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> GatewayRouterRequestMessageCode, body |-> ZeroGatewayRouterRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderEntryInMessageCode, body |-> ZeroOrderEntryInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderEntryInMessageCode2, body |-> ZeroOrderEntryInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderEntryInMessageCode3, body |-> ZeroOrderEntryInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderEntryInMessageCode4, body |-> ZeroOrderEntryInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> OrderLimitUpdateInMessageCode, body |-> ZeroOrderLimitUpdateInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> PasswordResetInMessageCode, body |-> ZeroPasswordResetInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SignOnRequestInMessageCode, body |-> ZeroSignOnRequestInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> SignOnRequestInMessageCode2, body |-> ZeroSignOnRequestInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> TradeInquiryInMessageCode, body |-> ZeroTradeInquiryInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> TradeInquiryInMessageCode2, body |-> ZeroTradeInquiryInMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> UpdateLocalDatabaseRequestMessageCode, body |-> ZeroUpdateLocalDatabaseRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> TradeModificationCancellationStatusRequestMessageCode, body |-> ZeroTradeModificationCancellationStatusRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> UserUnlockRequestMessageCode, body |-> ZeroUserUnlockRequestMessage]],
      [ZeroClientDirectPacket EXCEPT !.clientMessagePayload = [tag |-> UserOrderValueLimitUpdateInMessageCode, body |-> ZeroUserOrderValueLimitUpdateInMessage]] }

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

(* Every Branch Limit decodes back to what was encoded, and leaves nothing over *)
RoundTripBranchLimit ==
    \A message \in CheckedBranchLimit :
        LET read == DecodeBranchLimit(EncodeBranchLimit(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Branch Order Value Limit Update In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBranchOrderValueLimitUpdateInMessage ==
    \A message \in CheckedBranchOrderValueLimitUpdateInMessage :
        LET read == DecodeBranchOrderValueLimitUpdateInMessage(EncodeBranchOrderValueLimitUpdateInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel On Logout Status Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOnLogoutStatusRequestMessage ==
    \A message \in CheckedCancelOnLogoutStatusRequestMessage :
        LET read == DecodeCancelOnLogoutStatusRequestMessage(EncodeCancelOnLogoutStatusRequestMessage(message))
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

(* Every Auction Inquiry Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAuctionInquiryRequestMessage ==
    \A message \in CheckedAuctionInquiryRequestMessage :
        LET read == DecodeAuctionInquiryRequestMessage(EncodeAuctionInquiryRequestMessage(message))
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

(* Every Box Sign On Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBoxSignOnRequestMessage ==
    \A message \in CheckedBoxSignOnRequestMessage :
        LET read == DecodeBoxSignOnRequestMessage(EncodeBoxSignOnRequestMessage(message))
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

(* Every Sec Info decodes back to what was encoded, and leaves nothing over *)
RoundTripSecInfo2 ==
    \A message \in CheckedSecInfo2 :
        LET read == DecodeSecInfo2(EncodeSecInfo2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Entry In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderEntryInMessage ==
    \A message \in CheckedOrderEntryInMessage :
        LET read == DecodeOrderEntryInMessage(EncodeOrderEntryInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Limit Update In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderLimitUpdateInMessage ==
    \A message \in CheckedOrderLimitUpdateInMessage :
        LET read == DecodeOrderLimitUpdateInMessage(EncodeOrderLimitUpdateInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Password Reset In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPasswordResetInMessage ==
    \A message \in CheckedPasswordResetInMessage :
        LET read == DecodePasswordResetInMessage(EncodePasswordResetInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sign On Request In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSignOnRequestInMessage ==
    \A message \in CheckedSignOnRequestInMessage :
        LET read == DecodeSignOnRequestInMessage(EncodeSignOnRequestInMessage(message))
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

(* Every Trade Inquiry In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeInquiryInMessage ==
    \A message \in CheckedTradeInquiryInMessage :
        LET read == DecodeTradeInquiryInMessage(EncodeTradeInquiryInMessage(message))
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

(* Every Trade Modification Cancellation Status Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeModificationCancellationStatusRequestMessage ==
    \A message \in CheckedTradeModificationCancellationStatusRequestMessage :
        LET read == DecodeTradeModificationCancellationStatusRequestMessage(EncodeTradeModificationCancellationStatusRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Unlock Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUserUnlockRequestMessage ==
    \A message \in CheckedUserUnlockRequestMessage :
        LET read == DecodeUserUnlockRequestMessage(EncodeUserUnlockRequestMessage(message))
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

(* Every User Order Value Limit Update In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUserOrderValueLimitUpdateInMessage ==
    \A message \in CheckedUserOrderValueLimitUpdateInMessage :
        LET read == DecodeUserOrderValueLimitUpdateInMessage(EncodeUserOrderValueLimitUpdateInMessage(message))
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
