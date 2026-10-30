------------------- MODULE NseCd_OrderEntry_v6_3_Client --------------------
(***************************************************************************)
(* National Stock Exchange of India Ltd Order Entry v6.3                   *)
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
(* Note: Additional Order Flags is a bit field set, checked as its 1 byte  *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: St Broker Eligibility Per Mkt is a bit field set, checked as its  *)
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
(* Board Lot In Message: 276 bytes                                         *)
(***************************************************************************)

BoardLotInMessage ==
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
      bookTypeShort2           : Sample(2),
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
      reference                : Sample(4),
      nnfField                 : Sample(8),
      mktReplay                : Sample(8),
      pan                      : Sample(10),
      algoId                   : Sample(4),
      secondReserved2          : Sample(2),
      lastActivityReference    : Sample(8),
      reserved52               : Sample(52) ]

EncodeBoardLotInMessage(message) ==
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
        \o message.bookTypeShort2
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
        \o message.reference
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.secondReserved2
        \o message.lastActivityReference
        \o message.reserved52

DecodeBoardLotInMessage(bytes) ==
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
    LET bookTypeShort2 == ReadBytes(accountNumber.rest, 2) IN IF ~bookTypeShort2.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(bookTypeShort2.rest, 2) IN IF ~buySellIndicator.ok THEN Fail ELSE
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
    LET reference == ReadBytes(fifthReserved1.rest, 4) IN IF ~reference.ok THEN Fail ELSE
    LET nnfField == ReadBytes(reference.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
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
         bookTypeShort2           |-> bookTypeShort2.value,
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
         reference                |-> reference.value,
         nnfField                 |-> nnfField.value,
         mktReplay                |-> mktReplay.value,
         pan                      |-> pan.value,
         algoId                   |-> algoId.value,
         secondReserved2          |-> secondReserved2.value,
         lastActivityReference    |-> lastActivityReference.value,
         reserved52               |-> reserved52.value ], reserved52.rest)

ZeroBoardLotInMessage ==
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
      bookTypeShort2           |-> [i \in 1 .. 2 |-> 0],
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
      reference                |-> [i \in 1 .. 4 |-> 0],
      nnfField                 |-> [i \in 1 .. 8 |-> 0],
      mktReplay                |-> [i \in 1 .. 8 |-> 0],
      pan                      |-> [i \in 1 .. 10 |-> 0],
      algoId                   |-> [i \in 1 .. 4 |-> 0],
      secondReserved2          |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference    |-> [i \in 1 .. 8 |-> 0],
      reserved52               |-> [i \in 1 .. 52 |-> 0] ]

(* Board Lot In Message at zero, then each field in turn at the values it is checked at *)
CheckedBoardLotInMessage ==
    { ZeroBoardLotInMessage }
        \cup { [ZeroBoardLotInMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.modifiedCancelledBy = one] : one \in Sample(1) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc }
        \cup { [ZeroBoardLotInMessage EXCEPT !.counterPartyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.closeoutFlag = one] : one \in Sample(1) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.orderType = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.bookTypeShort2 = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.buySellIndicator = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.disclosedVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.totalVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.minimumFillAonVolume = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.proClientIndicator = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.settlementPeriod = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.reference = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroBoardLotInMessage EXCEPT !.reserved52 = one] : one \in Sample(52) }

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
(* Order Mod In Message: 276 bytes                                         *)
(***************************************************************************)

OrderModInMessage ==
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
      bookTypeShort2           : Sample(2),
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
      reference                : Sample(4),
      nnfField                 : Sample(8),
      mktReplay                : Sample(8),
      pan                      : Sample(10),
      algoId                   : Sample(4),
      secondReserved2          : Sample(2),
      lastActivityReference    : Sample(8),
      reserved52               : Sample(52) ]

EncodeOrderModInMessage(message) ==
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
        \o message.bookTypeShort2
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
        \o message.reference
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.secondReserved2
        \o message.lastActivityReference
        \o message.reserved52

DecodeOrderModInMessage(bytes) ==
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
    LET bookTypeShort2 == ReadBytes(accountNumber.rest, 2) IN IF ~bookTypeShort2.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(bookTypeShort2.rest, 2) IN IF ~buySellIndicator.ok THEN Fail ELSE
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
    LET reference == ReadBytes(fifthReserved1.rest, 4) IN IF ~reference.ok THEN Fail ELSE
    LET nnfField == ReadBytes(reference.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
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
         bookTypeShort2           |-> bookTypeShort2.value,
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
         reference                |-> reference.value,
         nnfField                 |-> nnfField.value,
         mktReplay                |-> mktReplay.value,
         pan                      |-> pan.value,
         algoId                   |-> algoId.value,
         secondReserved2          |-> secondReserved2.value,
         lastActivityReference    |-> lastActivityReference.value,
         reserved52               |-> reserved52.value ], reserved52.rest)

ZeroOrderModInMessage ==
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
      bookTypeShort2           |-> [i \in 1 .. 2 |-> 0],
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
      reference                |-> [i \in 1 .. 4 |-> 0],
      nnfField                 |-> [i \in 1 .. 8 |-> 0],
      mktReplay                |-> [i \in 1 .. 8 |-> 0],
      pan                      |-> [i \in 1 .. 10 |-> 0],
      algoId                   |-> [i \in 1 .. 4 |-> 0],
      secondReserved2          |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference    |-> [i \in 1 .. 8 |-> 0],
      reserved52               |-> [i \in 1 .. 52 |-> 0] ]

(* Order Mod In Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModInMessage ==
    { ZeroOrderModInMessage }
        \cup { [ZeroOrderModInMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderModInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModInMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderModInMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderModInMessage EXCEPT !.modifiedCancelledBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderModInMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModInMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderModInMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc2 }
        \cup { [ZeroOrderModInMessage EXCEPT !.counterPartyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderModInMessage EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModInMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderModInMessage EXCEPT !.closeoutFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderModInMessage EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModInMessage EXCEPT !.orderType = one] : one \in Sample(2) }
        \cup { [ZeroOrderModInMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderModInMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderModInMessage EXCEPT !.bookTypeShort2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderModInMessage EXCEPT !.buySellIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderModInMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.disclosedVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.totalVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.minimumFillAonVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderModInMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderModInMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderModInMessage EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroOrderModInMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderModInMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderModInMessage EXCEPT !.proClientIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderModInMessage EXCEPT !.settlementPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderModInMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderModInMessage EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModInMessage EXCEPT !.reference = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderModInMessage EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroOrderModInMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderModInMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderModInMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderModInMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderModInMessage EXCEPT !.reserved52 = one] : one \in Sample(52) }

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
(* Order Cancel In Message: 276 bytes                                      *)
(***************************************************************************)

OrderCancelInMessage ==
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
      bookTypeShort2           : Sample(2),
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
      reference                : Sample(4),
      nnfField                 : Sample(8),
      mktReplay                : Sample(8),
      pan                      : Sample(10),
      algoId                   : Sample(4),
      secondReserved2          : Sample(2),
      lastActivityReference    : Sample(8),
      reserved52               : Sample(52) ]

EncodeOrderCancelInMessage(message) ==
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
        \o message.bookTypeShort2
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
        \o message.reference
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.secondReserved2
        \o message.lastActivityReference
        \o message.reserved52

DecodeOrderCancelInMessage(bytes) ==
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
    LET bookTypeShort2 == ReadBytes(accountNumber.rest, 2) IN IF ~bookTypeShort2.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(bookTypeShort2.rest, 2) IN IF ~buySellIndicator.ok THEN Fail ELSE
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
    LET reference == ReadBytes(fifthReserved1.rest, 4) IN IF ~reference.ok THEN Fail ELSE
    LET nnfField == ReadBytes(reference.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
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
         bookTypeShort2           |-> bookTypeShort2.value,
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
         reference                |-> reference.value,
         nnfField                 |-> nnfField.value,
         mktReplay                |-> mktReplay.value,
         pan                      |-> pan.value,
         algoId                   |-> algoId.value,
         secondReserved2          |-> secondReserved2.value,
         lastActivityReference    |-> lastActivityReference.value,
         reserved52               |-> reserved52.value ], reserved52.rest)

ZeroOrderCancelInMessage ==
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
      bookTypeShort2           |-> [i \in 1 .. 2 |-> 0],
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
      reference                |-> [i \in 1 .. 4 |-> 0],
      nnfField                 |-> [i \in 1 .. 8 |-> 0],
      mktReplay                |-> [i \in 1 .. 8 |-> 0],
      pan                      |-> [i \in 1 .. 10 |-> 0],
      algoId                   |-> [i \in 1 .. 4 |-> 0],
      secondReserved2          |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference    |-> [i \in 1 .. 8 |-> 0],
      reserved52               |-> [i \in 1 .. 52 |-> 0] ]

(* Order Cancel In Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelInMessage ==
    { ZeroOrderCancelInMessage }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.participantType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.competitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.solicitorPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.modifiedCancelledBy = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.reasonCode = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc3 }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.counterPartyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.thirdReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.closeoutFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.fourthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.orderType = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.accountNumber = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.bookTypeShort2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.buySellIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.disclosedVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.disclosedVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.totalVolumeRemaining = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.volumeFilledToday = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.triggerPrice = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.goodTillDate = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.entryDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.minimumFillAonVolume = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.settlor = one] : one \in Sample(12) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.proClientIndicator = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.settlementPeriod = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.fifthReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.reference = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelInMessage EXCEPT !.reserved52 = one] : one \in Sample(52) }

(***************************************************************************)
(* Price Mod In Message: 66 bytes                                          *)
(***************************************************************************)

PriceModInMessage ==
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

EncodePriceModInMessage(message) ==
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

DecodePriceModInMessage(bytes) ==
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

ZeroPriceModInMessage ==
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

(* Price Mod In Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceModInMessage ==
    { ZeroPriceModInMessage }
        \cup { [ZeroPriceModInMessage EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroPriceModInMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroPriceModInMessage EXCEPT !.orderNumber = one] : one \in Sample(8) }
        \cup { [ZeroPriceModInMessage EXCEPT !.buySell = one] : one \in Sample(2) }
        \cup { [ZeroPriceModInMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroPriceModInMessage EXCEPT !.volume = one] : one \in Sample(4) }
        \cup { [ZeroPriceModInMessage EXCEPT !.lastModified = one] : one \in Sample(4) }
        \cup { [ZeroPriceModInMessage EXCEPT !.reference = one] : one \in Sample(4) }
        \cup { [ZeroPriceModInMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroPriceModInMessage EXCEPT !.reserved24 = one] : one \in Sample(24) }

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
(* Ms Spd Leg Info Leg 2: 80 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg2 ==
    [ token2                 : Sample(4),
      contractDesc           : ContractDesc5,
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

EncodeMsSpdLegInfoLeg2(message) ==
    message.token2
        \o EncodeContractDesc5(message.contractDesc)
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

DecodeMsSpdLegInfoLeg2(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc5(token2.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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

ZeroMsSpdLegInfoLeg2 ==
    [ token2                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc           |-> ZeroContractDesc5,
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

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg2 ==
    { ZeroMsSpdLegInfoLeg2 }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc5 }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.opBrokerId2 = one] : one \in Sample(5) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.fillerx2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.orderType2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.disclosedVol2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.disclosedVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.volumeFilledToday2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.price2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.triggerPrice2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.minFillAon2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg2 EXCEPT !.fillerY = one] : one \in Sample(1) }

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
(* Ms Spd Leg Info Leg 3: 80 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg3 ==
    [ token2                 : Sample(4),
      contractDesc           : ContractDesc6,
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

EncodeMsSpdLegInfoLeg3(message) ==
    message.token2
        \o EncodeContractDesc6(message.contractDesc)
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

DecodeMsSpdLegInfoLeg3(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc6(token2.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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

ZeroMsSpdLegInfoLeg3 ==
    [ token2                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc           |-> ZeroContractDesc6,
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

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg3 ==
    { ZeroMsSpdLegInfoLeg3 }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc6 }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.opBrokerId2 = one] : one \in Sample(5) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.fillerx2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.orderType2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.disclosedVol2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.disclosedVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.volumeFilledToday2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.price2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.triggerPrice2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.minFillAon2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg3 EXCEPT !.fillerY = one] : one \in Sample(1) }

(***************************************************************************)
(* Sp Board Lot In Message: 440 bytes                                      *)
(***************************************************************************)

SpBoardLotInMessage ==
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
      contractDesc           : ContractDesc4,
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
      reserved2              : Sample(2),
      filler17               : Sample(1),
      filler18               : Sample(1),
      nnfField               : Sample(8),
      mktReplay              : Sample(8),
      pan                    : Sample(10),
      algoId                 : Sample(4),
      secondReserved2        : Sample(2),
      lastActivityReference  : Sample(8),
      reserved52             : Sample(52),
      priceDiff              : Sample(4),
      msSpdLegInfoLeg2       : MsSpdLegInfoLeg2,
      msSpdLegInfoLeg3       : MsSpdLegInfoLeg3 ]

EncodeSpBoardLotInMessage(message) ==
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
        \o EncodeContractDesc4(message.contractDesc)
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
        \o message.reserved2
        \o message.filler17
        \o message.filler18
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.secondReserved2
        \o message.lastActivityReference
        \o message.reserved52
        \o message.priceDiff
        \o EncodeMsSpdLegInfoLeg2(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg3(message.msSpdLegInfoLeg3)

DecodeSpBoardLotInMessage(bytes) ==
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
    LET contractDesc == DecodeContractDesc4(token1.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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
    LET reserved2 == ReadBytes(reserved1.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET filler17 == ReadBytes(reserved2.rest, 1) IN IF ~filler17.ok THEN Fail ELSE
    LET filler18 == ReadBytes(filler17.rest, 1) IN IF ~filler18.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler18.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET mktReplay == ReadBytes(nnfField.rest, 8) IN IF ~mktReplay.ok THEN Fail ELSE
    LET pan == ReadBytes(mktReplay.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(algoId.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(secondReserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(reserved52.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg2(priceDiff.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg3(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
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
         reserved2              |-> reserved2.value,
         filler17               |-> filler17.value,
         filler18               |-> filler18.value,
         nnfField               |-> nnfField.value,
         mktReplay              |-> mktReplay.value,
         pan                    |-> pan.value,
         algoId                 |-> algoId.value,
         secondReserved2        |-> secondReserved2.value,
         lastActivityReference  |-> lastActivityReference.value,
         reserved52             |-> reserved52.value,
         priceDiff              |-> priceDiff.value,
         msSpdLegInfoLeg2       |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3       |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroSpBoardLotInMessage ==
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
      contractDesc           |-> ZeroContractDesc4,
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
      reserved2              |-> [i \in 1 .. 2 |-> 0],
      filler17               |-> [i \in 1 .. 1 |-> 0],
      filler18               |-> [i \in 1 .. 1 |-> 0],
      nnfField               |-> [i \in 1 .. 8 |-> 0],
      mktReplay              |-> [i \in 1 .. 8 |-> 0],
      pan                    |-> [i \in 1 .. 10 |-> 0],
      algoId                 |-> [i \in 1 .. 4 |-> 0],
      secondReserved2        |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference  |-> [i \in 1 .. 8 |-> 0],
      reserved52             |-> [i \in 1 .. 52 |-> 0],
      priceDiff              |-> [i \in 1 .. 4 |-> 0],
      msSpdLegInfoLeg2       |-> ZeroMsSpdLegInfoLeg2,
      msSpdLegInfoLeg3       |-> ZeroMsSpdLegInfoLeg3 ]

(* Sp Board Lot In Message at zero, then each field in turn at the values it is checked at *)
CheckedSpBoardLotInMessage ==
    { ZeroSpBoardLotInMessage }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.participantType1 = one] : one \in Sample(1) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.competitorPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.solicitorPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.modCxlBy1 = one] : one \in Sample(1) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.filler9 = one] : one \in Sample(1) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.reasonCode1 = one] : one \in Sample(2) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.startAlpha1 = one] : one \in Sample(2) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.endAlpha1 = one] : one \in Sample(2) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc4 }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.opBrokerId1 = one] : one \in Sample(5) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.fillerx1 = one] : one \in Sample(1) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.fillerOptions1 = one] : one \in Sample(3) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.fillery1 = one] : one \in Sample(1) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.orderType1 = one] : one \in Sample(2) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.disclosedVol1 = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.disclosedVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.volumeFilledToday1 = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.price1 = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.triggerPrice1 = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.goodTillDate1 = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.entryDateTime1 = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.minFillAon1 = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.lastModified1 = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.branchId1 = one] : one \in Sample(2) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.brokerId1 = one] : one \in Sample(5) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.proClient1 = one] : one \in Sample(2) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.settlementPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.filler17 = one] : one \in Sample(1) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.filler18 = one] : one \in Sample(1) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.reserved52 = one] : one \in Sample(52) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg2 }
        \cup { [ZeroSpBoardLotInMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg3 }

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
(* Ms Spd Leg Info Leg 2: 80 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg22 ==
    [ token2                 : Sample(4),
      contractDesc           : ContractDesc8,
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

EncodeMsSpdLegInfoLeg22(message) ==
    message.token2
        \o EncodeContractDesc8(message.contractDesc)
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

DecodeMsSpdLegInfoLeg22(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc8(token2.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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

ZeroMsSpdLegInfoLeg22 ==
    [ token2                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc           |-> ZeroContractDesc8,
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

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg22 ==
    { ZeroMsSpdLegInfoLeg22 }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc8 }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.opBrokerId2 = one] : one \in Sample(5) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.fillerx2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.orderType2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.disclosedVol2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.disclosedVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.volumeFilledToday2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.price2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.triggerPrice2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.minFillAon2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg22 EXCEPT !.fillerY = one] : one \in Sample(1) }

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
(* Ms Spd Leg Info Leg 3: 80 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg32 ==
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

EncodeMsSpdLegInfoLeg32(message) ==
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

DecodeMsSpdLegInfoLeg32(bytes) ==
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

ZeroMsSpdLegInfoLeg32 ==
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

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg32 ==
    { ZeroMsSpdLegInfoLeg32 }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc9 }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.opBrokerId2 = one] : one \in Sample(5) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.fillerx2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.orderType2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.disclosedVol2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.disclosedVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.volumeFilledToday2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.price2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.triggerPrice2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.minFillAon2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg32 EXCEPT !.fillerY = one] : one \in Sample(1) }

(***************************************************************************)
(* Twol Board Lot In Message: 440 bytes                                    *)
(***************************************************************************)

TwolBoardLotInMessage ==
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
      contractDesc           : ContractDesc7,
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
      reserved2              : Sample(2),
      filler17               : Sample(1),
      filler18               : Sample(1),
      nnfField               : Sample(8),
      mktReplay              : Sample(8),
      pan                    : Sample(10),
      algoId                 : Sample(4),
      secondReserved2        : Sample(2),
      lastActivityReference  : Sample(8),
      reserved52             : Sample(52),
      priceDiff              : Sample(4),
      msSpdLegInfoLeg2       : MsSpdLegInfoLeg22,
      msSpdLegInfoLeg3       : MsSpdLegInfoLeg32 ]

EncodeTwolBoardLotInMessage(message) ==
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
        \o EncodeContractDesc7(message.contractDesc)
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
        \o message.reserved2
        \o message.filler17
        \o message.filler18
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.secondReserved2
        \o message.lastActivityReference
        \o message.reserved52
        \o message.priceDiff
        \o EncodeMsSpdLegInfoLeg22(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg32(message.msSpdLegInfoLeg3)

DecodeTwolBoardLotInMessage(bytes) ==
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
    LET contractDesc == DecodeContractDesc7(token1.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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
    LET reserved2 == ReadBytes(reserved1.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET filler17 == ReadBytes(reserved2.rest, 1) IN IF ~filler17.ok THEN Fail ELSE
    LET filler18 == ReadBytes(filler17.rest, 1) IN IF ~filler18.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler18.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET mktReplay == ReadBytes(nnfField.rest, 8) IN IF ~mktReplay.ok THEN Fail ELSE
    LET pan == ReadBytes(mktReplay.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(algoId.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(secondReserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(reserved52.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg22(priceDiff.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg32(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
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
         reserved2              |-> reserved2.value,
         filler17               |-> filler17.value,
         filler18               |-> filler18.value,
         nnfField               |-> nnfField.value,
         mktReplay              |-> mktReplay.value,
         pan                    |-> pan.value,
         algoId                 |-> algoId.value,
         secondReserved2        |-> secondReserved2.value,
         lastActivityReference  |-> lastActivityReference.value,
         reserved52             |-> reserved52.value,
         priceDiff              |-> priceDiff.value,
         msSpdLegInfoLeg2       |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3       |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroTwolBoardLotInMessage ==
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
      contractDesc           |-> ZeroContractDesc7,
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
      reserved2              |-> [i \in 1 .. 2 |-> 0],
      filler17               |-> [i \in 1 .. 1 |-> 0],
      filler18               |-> [i \in 1 .. 1 |-> 0],
      nnfField               |-> [i \in 1 .. 8 |-> 0],
      mktReplay              |-> [i \in 1 .. 8 |-> 0],
      pan                    |-> [i \in 1 .. 10 |-> 0],
      algoId                 |-> [i \in 1 .. 4 |-> 0],
      secondReserved2        |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference  |-> [i \in 1 .. 8 |-> 0],
      reserved52             |-> [i \in 1 .. 52 |-> 0],
      priceDiff              |-> [i \in 1 .. 4 |-> 0],
      msSpdLegInfoLeg2       |-> ZeroMsSpdLegInfoLeg22,
      msSpdLegInfoLeg3       |-> ZeroMsSpdLegInfoLeg32 ]

(* Twol Board Lot In Message at zero, then each field in turn at the values it is checked at *)
CheckedTwolBoardLotInMessage ==
    { ZeroTwolBoardLotInMessage }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.participantType1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.competitorPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.solicitorPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.modCxlBy1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.filler9 = one] : one \in Sample(1) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.reasonCode1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.startAlpha1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.endAlpha1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc7 }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.opBrokerId1 = one] : one \in Sample(5) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.fillerx1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.fillerOptions1 = one] : one \in Sample(3) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.fillery1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.orderType1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.disclosedVol1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.disclosedVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.volumeFilledToday1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.price1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.triggerPrice1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.goodTillDate1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.entryDateTime1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.minFillAon1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.lastModified1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.branchId1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.brokerId1 = one] : one \in Sample(5) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.proClient1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.settlementPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.filler17 = one] : one \in Sample(1) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.filler18 = one] : one \in Sample(1) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.reserved52 = one] : one \in Sample(52) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg22 }
        \cup { [ZeroTwolBoardLotInMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg32 }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc10 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc10(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc10(bytes) ==
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

ZeroContractDesc10 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc10 ==
    { ZeroContractDesc10 }
        \cup { [ZeroContractDesc10 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc10 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc10 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc10 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc10 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc10 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc11 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc11(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc11(bytes) ==
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

ZeroContractDesc11 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc11 ==
    { ZeroContractDesc11 }
        \cup { [ZeroContractDesc11 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc11 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc11 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc11 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc11 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc11 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 80 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg23 ==
    [ token2                 : Sample(4),
      contractDesc           : ContractDesc11,
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

EncodeMsSpdLegInfoLeg23(message) ==
    message.token2
        \o EncodeContractDesc11(message.contractDesc)
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

DecodeMsSpdLegInfoLeg23(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc11(token2.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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

ZeroMsSpdLegInfoLeg23 ==
    [ token2                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc           |-> ZeroContractDesc11,
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

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg23 ==
    { ZeroMsSpdLegInfoLeg23 }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc11 }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.opBrokerId2 = one] : one \in Sample(5) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.fillerx2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.orderType2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.disclosedVol2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.disclosedVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.volumeFilledToday2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.price2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.triggerPrice2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.minFillAon2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg23 EXCEPT !.fillerY = one] : one \in Sample(1) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc12 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc12(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc12(bytes) ==
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

ZeroContractDesc12 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc12 ==
    { ZeroContractDesc12 }
        \cup { [ZeroContractDesc12 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc12 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc12 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc12 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc12 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc12 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 80 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg33 ==
    [ token2                 : Sample(4),
      contractDesc           : ContractDesc12,
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

EncodeMsSpdLegInfoLeg33(message) ==
    message.token2
        \o EncodeContractDesc12(message.contractDesc)
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

DecodeMsSpdLegInfoLeg33(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc12(token2.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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

ZeroMsSpdLegInfoLeg33 ==
    [ token2                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc           |-> ZeroContractDesc12,
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

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg33 ==
    { ZeroMsSpdLegInfoLeg33 }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc12 }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.opBrokerId2 = one] : one \in Sample(5) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.fillerx2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.orderType2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.disclosedVol2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.disclosedVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.volumeFilledToday2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.price2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.triggerPrice2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.minFillAon2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg33 EXCEPT !.fillerY = one] : one \in Sample(1) }

(***************************************************************************)
(* Thrl Board Lot In Message: 440 bytes                                    *)
(***************************************************************************)

ThrlBoardLotInMessage ==
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
      contractDesc           : ContractDesc10,
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
      reserved2              : Sample(2),
      filler17               : Sample(1),
      filler18               : Sample(1),
      nnfField               : Sample(8),
      mktReplay              : Sample(8),
      pan                    : Sample(10),
      algoId                 : Sample(4),
      secondReserved2        : Sample(2),
      lastActivityReference  : Sample(8),
      reserved52             : Sample(52),
      priceDiff              : Sample(4),
      msSpdLegInfoLeg2       : MsSpdLegInfoLeg23,
      msSpdLegInfoLeg3       : MsSpdLegInfoLeg33 ]

EncodeThrlBoardLotInMessage(message) ==
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
        \o EncodeContractDesc10(message.contractDesc)
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
        \o message.reserved2
        \o message.filler17
        \o message.filler18
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.secondReserved2
        \o message.lastActivityReference
        \o message.reserved52
        \o message.priceDiff
        \o EncodeMsSpdLegInfoLeg23(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg33(message.msSpdLegInfoLeg3)

DecodeThrlBoardLotInMessage(bytes) ==
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
    LET contractDesc == DecodeContractDesc10(token1.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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
    LET reserved2 == ReadBytes(reserved1.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET filler17 == ReadBytes(reserved2.rest, 1) IN IF ~filler17.ok THEN Fail ELSE
    LET filler18 == ReadBytes(filler17.rest, 1) IN IF ~filler18.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler18.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET mktReplay == ReadBytes(nnfField.rest, 8) IN IF ~mktReplay.ok THEN Fail ELSE
    LET pan == ReadBytes(mktReplay.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(algoId.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(secondReserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(reserved52.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg23(priceDiff.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg33(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
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
         reserved2              |-> reserved2.value,
         filler17               |-> filler17.value,
         filler18               |-> filler18.value,
         nnfField               |-> nnfField.value,
         mktReplay              |-> mktReplay.value,
         pan                    |-> pan.value,
         algoId                 |-> algoId.value,
         secondReserved2        |-> secondReserved2.value,
         lastActivityReference  |-> lastActivityReference.value,
         reserved52             |-> reserved52.value,
         priceDiff              |-> priceDiff.value,
         msSpdLegInfoLeg2       |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3       |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroThrlBoardLotInMessage ==
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
      contractDesc           |-> ZeroContractDesc10,
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
      reserved2              |-> [i \in 1 .. 2 |-> 0],
      filler17               |-> [i \in 1 .. 1 |-> 0],
      filler18               |-> [i \in 1 .. 1 |-> 0],
      nnfField               |-> [i \in 1 .. 8 |-> 0],
      mktReplay              |-> [i \in 1 .. 8 |-> 0],
      pan                    |-> [i \in 1 .. 10 |-> 0],
      algoId                 |-> [i \in 1 .. 4 |-> 0],
      secondReserved2        |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference  |-> [i \in 1 .. 8 |-> 0],
      reserved52             |-> [i \in 1 .. 52 |-> 0],
      priceDiff              |-> [i \in 1 .. 4 |-> 0],
      msSpdLegInfoLeg2       |-> ZeroMsSpdLegInfoLeg23,
      msSpdLegInfoLeg3       |-> ZeroMsSpdLegInfoLeg33 ]

(* Thrl Board Lot In Message at zero, then each field in turn at the values it is checked at *)
CheckedThrlBoardLotInMessage ==
    { ZeroThrlBoardLotInMessage }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.participantType1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.competitorPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.solicitorPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.modCxlBy1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.filler9 = one] : one \in Sample(1) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.reasonCode1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.startAlpha1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.endAlpha1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc10 }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.opBrokerId1 = one] : one \in Sample(5) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.fillerx1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.fillerOptions1 = one] : one \in Sample(3) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.fillery1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.orderType1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.disclosedVol1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.disclosedVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.volumeFilledToday1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.price1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.triggerPrice1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.goodTillDate1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.entryDateTime1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.minFillAon1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.lastModified1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.branchId1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.brokerId1 = one] : one \in Sample(5) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.proClient1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.settlementPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.filler17 = one] : one \in Sample(1) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.filler18 = one] : one \in Sample(1) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.reserved52 = one] : one \in Sample(52) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg23 }
        \cup { [ZeroThrlBoardLotInMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg33 }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc13 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc13(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc13(bytes) ==
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

ZeroContractDesc13 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc13 ==
    { ZeroContractDesc13 }
        \cup { [ZeroContractDesc13 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc13 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc13 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc13 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc13 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc13 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc14 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc14(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc14(bytes) ==
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

ZeroContractDesc14 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc14 ==
    { ZeroContractDesc14 }
        \cup { [ZeroContractDesc14 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc14 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc14 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc14 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc14 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc14 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 80 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg24 ==
    [ token2                 : Sample(4),
      contractDesc           : ContractDesc14,
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

EncodeMsSpdLegInfoLeg24(message) ==
    message.token2
        \o EncodeContractDesc14(message.contractDesc)
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

DecodeMsSpdLegInfoLeg24(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc14(token2.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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

ZeroMsSpdLegInfoLeg24 ==
    [ token2                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc           |-> ZeroContractDesc14,
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

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg24 ==
    { ZeroMsSpdLegInfoLeg24 }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc14 }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.opBrokerId2 = one] : one \in Sample(5) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.fillerx2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.orderType2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.disclosedVol2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.disclosedVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.volumeFilledToday2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.price2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.triggerPrice2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.minFillAon2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg24 EXCEPT !.fillerY = one] : one \in Sample(1) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc15 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc15(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc15(bytes) ==
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

ZeroContractDesc15 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc15 ==
    { ZeroContractDesc15 }
        \cup { [ZeroContractDesc15 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc15 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc15 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc15 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc15 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc15 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 80 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg34 ==
    [ token2                 : Sample(4),
      contractDesc           : ContractDesc15,
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

EncodeMsSpdLegInfoLeg34(message) ==
    message.token2
        \o EncodeContractDesc15(message.contractDesc)
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

DecodeMsSpdLegInfoLeg34(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc15(token2.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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

ZeroMsSpdLegInfoLeg34 ==
    [ token2                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc           |-> ZeroContractDesc15,
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

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg34 ==
    { ZeroMsSpdLegInfoLeg34 }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc15 }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.opBrokerId2 = one] : one \in Sample(5) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.fillerx2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.orderType2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.disclosedVol2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.disclosedVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.volumeFilledToday2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.price2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.triggerPrice2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.minFillAon2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg34 EXCEPT !.fillerY = one] : one \in Sample(1) }

(***************************************************************************)
(* Sp Order Cancel In Message: 440 bytes                                   *)
(***************************************************************************)

SpOrderCancelInMessage ==
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
      contractDesc           : ContractDesc13,
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
      reserved2              : Sample(2),
      filler17               : Sample(1),
      filler18               : Sample(1),
      nnfField               : Sample(8),
      mktReplay              : Sample(8),
      pan                    : Sample(10),
      algoId                 : Sample(4),
      secondReserved2        : Sample(2),
      lastActivityReference  : Sample(8),
      reserved52             : Sample(52),
      priceDiff              : Sample(4),
      msSpdLegInfoLeg2       : MsSpdLegInfoLeg24,
      msSpdLegInfoLeg3       : MsSpdLegInfoLeg34 ]

EncodeSpOrderCancelInMessage(message) ==
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
        \o EncodeContractDesc13(message.contractDesc)
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
        \o message.reserved2
        \o message.filler17
        \o message.filler18
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.secondReserved2
        \o message.lastActivityReference
        \o message.reserved52
        \o message.priceDiff
        \o EncodeMsSpdLegInfoLeg24(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg34(message.msSpdLegInfoLeg3)

DecodeSpOrderCancelInMessage(bytes) ==
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
    LET contractDesc == DecodeContractDesc13(token1.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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
    LET reserved2 == ReadBytes(reserved1.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET filler17 == ReadBytes(reserved2.rest, 1) IN IF ~filler17.ok THEN Fail ELSE
    LET filler18 == ReadBytes(filler17.rest, 1) IN IF ~filler18.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler18.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET mktReplay == ReadBytes(nnfField.rest, 8) IN IF ~mktReplay.ok THEN Fail ELSE
    LET pan == ReadBytes(mktReplay.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(algoId.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(secondReserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(reserved52.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg24(priceDiff.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg34(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
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
         reserved2              |-> reserved2.value,
         filler17               |-> filler17.value,
         filler18               |-> filler18.value,
         nnfField               |-> nnfField.value,
         mktReplay              |-> mktReplay.value,
         pan                    |-> pan.value,
         algoId                 |-> algoId.value,
         secondReserved2        |-> secondReserved2.value,
         lastActivityReference  |-> lastActivityReference.value,
         reserved52             |-> reserved52.value,
         priceDiff              |-> priceDiff.value,
         msSpdLegInfoLeg2       |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3       |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroSpOrderCancelInMessage ==
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
      contractDesc           |-> ZeroContractDesc13,
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
      reserved2              |-> [i \in 1 .. 2 |-> 0],
      filler17               |-> [i \in 1 .. 1 |-> 0],
      filler18               |-> [i \in 1 .. 1 |-> 0],
      nnfField               |-> [i \in 1 .. 8 |-> 0],
      mktReplay              |-> [i \in 1 .. 8 |-> 0],
      pan                    |-> [i \in 1 .. 10 |-> 0],
      algoId                 |-> [i \in 1 .. 4 |-> 0],
      secondReserved2        |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference  |-> [i \in 1 .. 8 |-> 0],
      reserved52             |-> [i \in 1 .. 52 |-> 0],
      priceDiff              |-> [i \in 1 .. 4 |-> 0],
      msSpdLegInfoLeg2       |-> ZeroMsSpdLegInfoLeg24,
      msSpdLegInfoLeg3       |-> ZeroMsSpdLegInfoLeg34 ]

(* Sp Order Cancel In Message at zero, then each field in turn at the values it is checked at *)
CheckedSpOrderCancelInMessage ==
    { ZeroSpOrderCancelInMessage }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.participantType1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.competitorPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.solicitorPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.modCxlBy1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.filler9 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.reasonCode1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.startAlpha1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.endAlpha1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc13 }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.opBrokerId1 = one] : one \in Sample(5) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.fillerx1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.fillerOptions1 = one] : one \in Sample(3) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.fillery1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.orderType1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.disclosedVol1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.disclosedVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.volumeFilledToday1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.price1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.triggerPrice1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.goodTillDate1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.entryDateTime1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.minFillAon1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.lastModified1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.branchId1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.brokerId1 = one] : one \in Sample(5) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.proClient1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.settlementPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.filler17 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.filler18 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.reserved52 = one] : one \in Sample(52) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg24 }
        \cup { [ZeroSpOrderCancelInMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg34 }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc16 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc16(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc16(bytes) ==
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

ZeroContractDesc16 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc16 ==
    { ZeroContractDesc16 }
        \cup { [ZeroContractDesc16 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc16 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc16 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc16 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc16 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc16 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc17 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc17(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc17(bytes) ==
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

ZeroContractDesc17 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc17 ==
    { ZeroContractDesc17 }
        \cup { [ZeroContractDesc17 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc17 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc17 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc17 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc17 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc17 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 2: 80 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg25 ==
    [ token2                 : Sample(4),
      contractDesc           : ContractDesc17,
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

EncodeMsSpdLegInfoLeg25(message) ==
    message.token2
        \o EncodeContractDesc17(message.contractDesc)
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

DecodeMsSpdLegInfoLeg25(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc17(token2.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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

ZeroMsSpdLegInfoLeg25 ==
    [ token2                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc           |-> ZeroContractDesc17,
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

(* Ms Spd Leg Info Leg 2 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg25 ==
    { ZeroMsSpdLegInfoLeg25 }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc17 }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.opBrokerId2 = one] : one \in Sample(5) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.fillerx2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.orderType2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.disclosedVol2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.disclosedVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.volumeFilledToday2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.price2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.triggerPrice2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.minFillAon2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg25 EXCEPT !.fillerY = one] : one \in Sample(1) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc18 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc18(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc18(bytes) ==
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

ZeroContractDesc18 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc18 ==
    { ZeroContractDesc18 }
        \cup { [ZeroContractDesc18 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc18 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc18 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc18 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc18 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc18 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Ms Spd Leg Info Leg 3: 80 bytes                                         *)
(***************************************************************************)

MsSpdLegInfoLeg35 ==
    [ token2                 : Sample(4),
      contractDesc           : ContractDesc18,
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

EncodeMsSpdLegInfoLeg35(message) ==
    message.token2
        \o EncodeContractDesc18(message.contractDesc)
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

DecodeMsSpdLegInfoLeg35(bytes) ==
    LET token2 == ReadBytes(bytes, 4) IN IF ~token2.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc18(token2.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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

ZeroMsSpdLegInfoLeg35 ==
    [ token2                 |-> [i \in 1 .. 4 |-> 0],
      contractDesc           |-> ZeroContractDesc18,
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

(* Ms Spd Leg Info Leg 3 at zero, then each field in turn at the values it is checked at *)
CheckedMsSpdLegInfoLeg35 ==
    { ZeroMsSpdLegInfoLeg35 }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.token2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.contractDesc = one] : one \in CheckedContractDesc18 }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.opBrokerId2 = one] : one \in Sample(5) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.fillerx2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.orderType2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.buySell2 = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.disclosedVol2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.disclosedVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.totalVolRemaining2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.volume2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.volumeFilledToday2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.price2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.triggerPrice2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.minFillAon2 = one] : one \in Sample(4) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.openClose2 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroMsSpdLegInfoLeg35 EXCEPT !.fillerY = one] : one \in Sample(1) }

(***************************************************************************)
(* Sp Order Mod In Message: 440 bytes                                      *)
(***************************************************************************)

SpOrderModInMessage ==
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
      contractDesc           : ContractDesc16,
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
      reserved2              : Sample(2),
      filler17               : Sample(1),
      filler18               : Sample(1),
      nnfField               : Sample(8),
      mktReplay              : Sample(8),
      pan                    : Sample(10),
      algoId                 : Sample(4),
      secondReserved2        : Sample(2),
      lastActivityReference  : Sample(8),
      reserved52             : Sample(52),
      priceDiff              : Sample(4),
      msSpdLegInfoLeg2       : MsSpdLegInfoLeg25,
      msSpdLegInfoLeg3       : MsSpdLegInfoLeg35 ]

EncodeSpOrderModInMessage(message) ==
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
        \o EncodeContractDesc16(message.contractDesc)
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
        \o message.reserved2
        \o message.filler17
        \o message.filler18
        \o message.nnfField
        \o message.mktReplay
        \o message.pan
        \o message.algoId
        \o message.secondReserved2
        \o message.lastActivityReference
        \o message.reserved52
        \o message.priceDiff
        \o EncodeMsSpdLegInfoLeg25(message.msSpdLegInfoLeg2)
        \o EncodeMsSpdLegInfoLeg35(message.msSpdLegInfoLeg3)

DecodeSpOrderModInMessage(bytes) ==
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
    LET contractDesc == DecodeContractDesc16(token1.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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
    LET reserved2 == ReadBytes(reserved1.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET filler17 == ReadBytes(reserved2.rest, 1) IN IF ~filler17.ok THEN Fail ELSE
    LET filler18 == ReadBytes(filler17.rest, 1) IN IF ~filler18.ok THEN Fail ELSE
    LET nnfField == ReadBytes(filler18.rest, 8) IN IF ~nnfField.ok THEN Fail ELSE
    LET mktReplay == ReadBytes(nnfField.rest, 8) IN IF ~mktReplay.ok THEN Fail ELSE
    LET pan == ReadBytes(mktReplay.rest, 10) IN IF ~pan.ok THEN Fail ELSE
    LET algoId == ReadBytes(pan.rest, 4) IN IF ~algoId.ok THEN Fail ELSE
    LET secondReserved2 == ReadBytes(algoId.rest, 2) IN IF ~secondReserved2.ok THEN Fail ELSE
    LET lastActivityReference == ReadBytes(secondReserved2.rest, 8) IN IF ~lastActivityReference.ok THEN Fail ELSE
    LET reserved52 == ReadBytes(lastActivityReference.rest, 52) IN IF ~reserved52.ok THEN Fail ELSE
    LET priceDiff == ReadBytes(reserved52.rest, 4) IN IF ~priceDiff.ok THEN Fail ELSE
    LET msSpdLegInfoLeg2 == DecodeMsSpdLegInfoLeg25(priceDiff.rest) IN IF ~msSpdLegInfoLeg2.ok THEN Fail ELSE
    LET msSpdLegInfoLeg3 == DecodeMsSpdLegInfoLeg35(msSpdLegInfoLeg2.rest) IN IF ~msSpdLegInfoLeg3.ok THEN Fail ELSE
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
         reserved2              |-> reserved2.value,
         filler17               |-> filler17.value,
         filler18               |-> filler18.value,
         nnfField               |-> nnfField.value,
         mktReplay              |-> mktReplay.value,
         pan                    |-> pan.value,
         algoId                 |-> algoId.value,
         secondReserved2        |-> secondReserved2.value,
         lastActivityReference  |-> lastActivityReference.value,
         reserved52             |-> reserved52.value,
         priceDiff              |-> priceDiff.value,
         msSpdLegInfoLeg2       |-> msSpdLegInfoLeg2.value,
         msSpdLegInfoLeg3       |-> msSpdLegInfoLeg3.value ], msSpdLegInfoLeg3.rest)

ZeroSpOrderModInMessage ==
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
      contractDesc           |-> ZeroContractDesc16,
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
      reserved2              |-> [i \in 1 .. 2 |-> 0],
      filler17               |-> [i \in 1 .. 1 |-> 0],
      filler18               |-> [i \in 1 .. 1 |-> 0],
      nnfField               |-> [i \in 1 .. 8 |-> 0],
      mktReplay              |-> [i \in 1 .. 8 |-> 0],
      pan                    |-> [i \in 1 .. 10 |-> 0],
      algoId                 |-> [i \in 1 .. 4 |-> 0],
      secondReserved2        |-> [i \in 1 .. 2 |-> 0],
      lastActivityReference  |-> [i \in 1 .. 8 |-> 0],
      reserved52             |-> [i \in 1 .. 52 |-> 0],
      priceDiff              |-> [i \in 1 .. 4 |-> 0],
      msSpdLegInfoLeg2       |-> ZeroMsSpdLegInfoLeg25,
      msSpdLegInfoLeg3       |-> ZeroMsSpdLegInfoLeg35 ]

(* Sp Order Mod In Message at zero, then each field in turn at the values it is checked at *)
CheckedSpOrderModInMessage ==
    { ZeroSpOrderModInMessage }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.participantType1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.filler1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.competitorPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.solicitorPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.modCxlBy1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.filler9 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.reasonCode1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.startAlpha1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.endAlpha1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.token1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc16 }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.opBrokerId1 = one] : one \in Sample(5) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.fillerx1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.fillerOptions1 = one] : one \in Sample(3) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.fillery1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.orderType1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.orderNumber1 = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.accountNumber1 = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.bookType1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.buySell1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.disclosedVol1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.disclosedVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.totalVolRemaining1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.volume1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.volumeFilledToday1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.price1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.triggerPrice1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.goodTillDate1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.entryDateTime1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.minFillAon1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.lastModified1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.stOrderFlags = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.branchId1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.traderId1 = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.brokerId1 = one] : one \in Sample(5) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.cOrdFiller = one] : one \in Sample(24) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.openClose1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.settlor1 = one] : one \in Sample(12) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.proClient1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.settlementPeriod1 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.additionalOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.filler17 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.filler18 = one] : one \in Sample(1) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.nnfField = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.mktReplay = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.pan = one] : one \in Sample(10) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.algoId = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.lastActivityReference = one] : one \in Sample(8) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.reserved52 = one] : one \in Sample(52) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.priceDiff = one] : one \in Sample(4) }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.msSpdLegInfoLeg2 = one] : one \in CheckedMsSpdLegInfoLeg25 }
        \cup { [ZeroSpOrderModInMessage EXCEPT !.msSpdLegInfoLeg3 = one] : one \in CheckedMsSpdLegInfoLeg35 }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc19 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc19(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc19(bytes) ==
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

ZeroContractDesc19 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc19 ==
    { ZeroContractDesc19 }
        \cup { [ZeroContractDesc19 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc19 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc19 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc19 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc19 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc19 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Cancel In Message: 194 bytes                                      *)
(***************************************************************************)

TradeCancelInMessage ==
    [ tokenNo           : Sample(4),
      contractDesc      : ContractDesc19,
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

EncodeTradeCancelInMessage(message) ==
    message.tokenNo
        \o EncodeContractDesc19(message.contractDesc)
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

DecodeTradeCancelInMessage(bytes) ==
    LET tokenNo == ReadBytes(bytes, 4) IN IF ~tokenNo.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc19(tokenNo.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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

ZeroTradeCancelInMessage ==
    [ tokenNo           |-> [i \in 1 .. 4 |-> 0],
      contractDesc      |-> ZeroContractDesc19,
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

(* Trade Cancel In Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancelInMessage ==
    { ZeroTradeCancelInMessage }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc19 }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.fillQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.mktType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.buyOpenClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.buyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.sellBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.requestedBy = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.sellOpenClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.buyAccountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.sellAccountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.reserved24 = one] : one \in Sample(24) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.buyPan = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.sellPan = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancelInMessage EXCEPT !.reserved60 = one] : one \in Sample(60) }

(***************************************************************************)
(* Contract Desc: 28 bytes                                                 *)
(***************************************************************************)

ContractDesc20 ==
    [ instrumentName : Sample(6),
      symbol         : Sample(10),
      expiryDate     : Sample(4),
      strikePrice    : Sample(4),
      optionType     : Sample(2),
      caLevel        : Sample(2) ]

EncodeContractDesc20(message) ==
    message.instrumentName
        \o message.symbol
        \o message.expiryDate
        \o message.strikePrice
        \o message.optionType
        \o message.caLevel

DecodeContractDesc20(bytes) ==
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

ZeroContractDesc20 ==
    [ instrumentName |-> [i \in 1 .. 6 |-> 0],
      symbol         |-> [i \in 1 .. 10 |-> 0],
      expiryDate     |-> [i \in 1 .. 4 |-> 0],
      strikePrice    |-> [i \in 1 .. 4 |-> 0],
      optionType     |-> [i \in 1 .. 2 |-> 0],
      caLevel        |-> [i \in 1 .. 2 |-> 0] ]

(* Contract Desc at zero, then each field in turn at the values it is checked at *)
CheckedContractDesc20 ==
    { ZeroContractDesc20 }
        \cup { [ZeroContractDesc20 EXCEPT !.instrumentName = one] : one \in Sample(6) }
        \cup { [ZeroContractDesc20 EXCEPT !.symbol = one] : one \in Sample(10) }
        \cup { [ZeroContractDesc20 EXCEPT !.expiryDate = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc20 EXCEPT !.strikePrice = one] : one \in Sample(4) }
        \cup { [ZeroContractDesc20 EXCEPT !.optionType = one] : one \in Sample(2) }
        \cup { [ZeroContractDesc20 EXCEPT !.caLevel = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Mod In Message: 194 bytes                                         *)
(***************************************************************************)

TradeModInMessage ==
    [ tokenNo           : Sample(4),
      contractDesc      : ContractDesc20,
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

EncodeTradeModInMessage(message) ==
    message.tokenNo
        \o EncodeContractDesc20(message.contractDesc)
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

DecodeTradeModInMessage(bytes) ==
    LET tokenNo == ReadBytes(bytes, 4) IN IF ~tokenNo.ok THEN Fail ELSE
    LET contractDesc == DecodeContractDesc20(tokenNo.rest) IN IF ~contractDesc.ok THEN Fail ELSE
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

ZeroTradeModInMessage ==
    [ tokenNo           |-> [i \in 1 .. 4 |-> 0],
      contractDesc      |-> ZeroContractDesc20,
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

(* Trade Mod In Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeModInMessage ==
    { ZeroTradeModInMessage }
        \cup { [ZeroTradeModInMessage EXCEPT !.tokenNo = one] : one \in Sample(4) }
        \cup { [ZeroTradeModInMessage EXCEPT !.contractDesc = one] : one \in CheckedContractDesc20 }
        \cup { [ZeroTradeModInMessage EXCEPT !.fillNumber = one] : one \in Sample(4) }
        \cup { [ZeroTradeModInMessage EXCEPT !.fillQuantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeModInMessage EXCEPT !.fillPrice = one] : one \in Sample(4) }
        \cup { [ZeroTradeModInMessage EXCEPT !.mktType = one] : one \in Sample(1) }
        \cup { [ZeroTradeModInMessage EXCEPT !.buyOpenClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeModInMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroTradeModInMessage EXCEPT !.buyBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeModInMessage EXCEPT !.sellBrokerId = one] : one \in Sample(5) }
        \cup { [ZeroTradeModInMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroTradeModInMessage EXCEPT !.requestedBy = one] : one \in Sample(1) }
        \cup { [ZeroTradeModInMessage EXCEPT !.sellOpenClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeModInMessage EXCEPT !.buyAccountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeModInMessage EXCEPT !.sellAccountNumber = one] : one \in Sample(10) }
        \cup { [ZeroTradeModInMessage EXCEPT !.reserved24 = one] : one \in Sample(24) }
        \cup { [ZeroTradeModInMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeModInMessage EXCEPT !.secondReserved2 = one] : one \in Sample(2) }
        \cup { [ZeroTradeModInMessage EXCEPT !.buyPan = one] : one \in Sample(10) }
        \cup { [ZeroTradeModInMessage EXCEPT !.sellPan = one] : one \in Sample(10) }
        \cup { [ZeroTradeModInMessage EXCEPT !.reserved60 = one] : one \in Sample(60) }

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
(* Sign Off Trader In Message: 238 bytes                                   *)
(***************************************************************************)

SignOffTraderInMessage ==
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

EncodeSignOffTraderInMessage(message) ==
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

DecodeSignOffTraderInMessage(bytes) ==
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

ZeroSignOffTraderInMessage ==
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

(* Sign Off Trader In Message at zero, then each field in turn at the values it is checked at *)
CheckedSignOffTraderInMessage ==
    { ZeroSignOffTraderInMessage }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.password = one] : one \in Sample(8) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.secondReserved8 = one] : one \in Sample(8) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.newPassword = one] : one \in Sample(8) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.traderName = one] : one \in Sample(26) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.lastPasswordChangeDate = one] : one \in Sample(4) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.versionNumber = one] : one \in Sample(4) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.batch2StartTime = one] : one \in Sample(4) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.hostSwitchContext = one] : one \in Sample(1) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.colour = one] : one \in Sample(50) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.userType = one] : one \in Sample(2) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.wsClassName = one] : one \in Sample(14) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.brokerStatus = one] : one \in Sample(1) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.showIndex = one] : one \in Sample(1) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.stBrokerEligibilityPerMkt = one] : one \in Sample(2) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.memberType = one] : one \in Sample(2) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.clearingStatus = one] : one \in Sample(1) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.brokerName = one] : one \in Sample(25) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.reserved16 = one] : one \in Sample(16) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.secondReserved16 = one] : one \in Sample(16) }
        \cup { [ZeroSignOffTraderInMessage EXCEPT !.thirdReserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Gr Request Message: 8 bytes                                             *)
(***************************************************************************)

GrRequestMessage ==
    [ boxId    : Sample(2),
      brokerId : Sample(5),
      filler   : Sample(1) ]

EncodeGrRequestMessage(message) ==
    message.boxId
        \o message.brokerId
        \o message.filler

DecodeGrRequestMessage(bytes) ==
    LET boxId == ReadBytes(bytes, 2) IN IF ~boxId.ok THEN Fail ELSE
    LET brokerId == ReadBytes(boxId.rest, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET filler == ReadBytes(brokerId.rest, 1) IN IF ~filler.ok THEN Fail ELSE
    Ok([ boxId    |-> boxId.value,
         brokerId |-> brokerId.value,
         filler   |-> filler.value ], filler.rest)

ZeroGrRequestMessage ==
    [ boxId    |-> [i \in 1 .. 2 |-> 0],
      brokerId |-> [i \in 1 .. 5 |-> 0],
      filler   |-> [i \in 1 .. 1 |-> 0] ]

(* Gr Request Message at zero, then each field in turn at the values it is checked at *)
CheckedGrRequestMessage ==
    { ZeroGrRequestMessage }
        \cup { [ZeroGrRequestMessage EXCEPT !.boxId = one] : one \in Sample(2) }
        \cup { [ZeroGrRequestMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroGrRequestMessage EXCEPT !.filler = one] : one \in Sample(1) }

(***************************************************************************)
(* User Addr Unlock In Message: 74 bytes                                   *)
(***************************************************************************)

UserAddrUnlockInMessage ==
    [ userId     : Sample(4),
      reserved70 : Sample(70) ]

EncodeUserAddrUnlockInMessage(message) ==
    message.userId
        \o message.reserved70

DecodeUserAddrUnlockInMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET reserved70 == ReadBytes(userId.rest, 70) IN IF ~reserved70.ok THEN Fail ELSE
    Ok([ userId     |-> userId.value,
         reserved70 |-> reserved70.value ], reserved70.rest)

ZeroUserAddrUnlockInMessage ==
    [ userId     |-> [i \in 1 .. 4 |-> 0],
      reserved70 |-> [i \in 1 .. 70 |-> 0] ]

(* User Addr Unlock In Message at zero, then each field in turn at the values it is checked at *)
CheckedUserAddrUnlockInMessage ==
    { ZeroUserAddrUnlockInMessage }
        \cup { [ZeroUserAddrUnlockInMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroUserAddrUnlockInMessage EXCEPT !.reserved70 = one] : one \in Sample(70) }

(***************************************************************************)
(* Branch Limits 1: 32 bytes                                               *)
(***************************************************************************)

BranchLimits1 ==
    [ branchBuyValueLimit  : Sample(8),
      branchSellValueLimit : Sample(8),
      reserved16           : Sample(16) ]

EncodeBranchLimits1(message) ==
    message.branchBuyValueLimit
        \o message.branchSellValueLimit
        \o message.reserved16

DecodeBranchLimits1(bytes) ==
    LET branchBuyValueLimit == ReadBytes(bytes, 8) IN IF ~branchBuyValueLimit.ok THEN Fail ELSE
    LET branchSellValueLimit == ReadBytes(branchBuyValueLimit.rest, 8) IN IF ~branchSellValueLimit.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(branchSellValueLimit.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ branchBuyValueLimit  |-> branchBuyValueLimit.value,
         branchSellValueLimit |-> branchSellValueLimit.value,
         reserved16           |-> reserved16.value ], reserved16.rest)

ZeroBranchLimits1 ==
    [ branchBuyValueLimit  |-> [i \in 1 .. 8 |-> 0],
      branchSellValueLimit |-> [i \in 1 .. 8 |-> 0],
      reserved16           |-> [i \in 1 .. 16 |-> 0] ]

(* Branch Limits 1 at zero, then each field in turn at the values it is checked at *)
CheckedBranchLimits1 ==
    { ZeroBranchLimits1 }
        \cup { [ZeroBranchLimits1 EXCEPT !.branchBuyValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroBranchLimits1 EXCEPT !.branchSellValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroBranchLimits1 EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Branch Limits 2: 32 bytes                                               *)
(***************************************************************************)

BranchLimits2 ==
    [ branchBuyValueLimit  : Sample(8),
      branchSellValueLimit : Sample(8),
      reserved16           : Sample(16) ]

EncodeBranchLimits2(message) ==
    message.branchBuyValueLimit
        \o message.branchSellValueLimit
        \o message.reserved16

DecodeBranchLimits2(bytes) ==
    LET branchBuyValueLimit == ReadBytes(bytes, 8) IN IF ~branchBuyValueLimit.ok THEN Fail ELSE
    LET branchSellValueLimit == ReadBytes(branchBuyValueLimit.rest, 8) IN IF ~branchSellValueLimit.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(branchSellValueLimit.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ branchBuyValueLimit  |-> branchBuyValueLimit.value,
         branchSellValueLimit |-> branchSellValueLimit.value,
         reserved16           |-> reserved16.value ], reserved16.rest)

ZeroBranchLimits2 ==
    [ branchBuyValueLimit  |-> [i \in 1 .. 8 |-> 0],
      branchSellValueLimit |-> [i \in 1 .. 8 |-> 0],
      reserved16           |-> [i \in 1 .. 16 |-> 0] ]

(* Branch Limits 2 at zero, then each field in turn at the values it is checked at *)
CheckedBranchLimits2 ==
    { ZeroBranchLimits2 }
        \cup { [ZeroBranchLimits2 EXCEPT !.branchBuyValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroBranchLimits2 EXCEPT !.branchSellValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroBranchLimits2 EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* Branch Ord Val Limit Update In Message: 96 bytes                        *)
(***************************************************************************)

BranchOrdValLimitUpdateInMessage ==
    [ brokerId      : Sample(5),
      reserved25    : Sample(25),
      branchId      : Sample(2),
      branchLimits1 : BranchLimits1,
      branchLimits2 : BranchLimits2 ]

EncodeBranchOrdValLimitUpdateInMessage(message) ==
    message.brokerId
        \o message.reserved25
        \o message.branchId
        \o EncodeBranchLimits1(message.branchLimits1)
        \o EncodeBranchLimits2(message.branchLimits2)

DecodeBranchOrdValLimitUpdateInMessage(bytes) ==
    LET brokerId == ReadBytes(bytes, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved25 == ReadBytes(brokerId.rest, 25) IN IF ~reserved25.ok THEN Fail ELSE
    LET branchId == ReadBytes(reserved25.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET branchLimits1 == DecodeBranchLimits1(branchId.rest) IN IF ~branchLimits1.ok THEN Fail ELSE
    LET branchLimits2 == DecodeBranchLimits2(branchLimits1.rest) IN IF ~branchLimits2.ok THEN Fail ELSE
    Ok([ brokerId      |-> brokerId.value,
         reserved25    |-> reserved25.value,
         branchId      |-> branchId.value,
         branchLimits1 |-> branchLimits1.value,
         branchLimits2 |-> branchLimits2.value ], branchLimits2.rest)

ZeroBranchOrdValLimitUpdateInMessage ==
    [ brokerId      |-> [i \in 1 .. 5 |-> 0],
      reserved25    |-> [i \in 1 .. 25 |-> 0],
      branchId      |-> [i \in 1 .. 2 |-> 0],
      branchLimits1 |-> ZeroBranchLimits1,
      branchLimits2 |-> ZeroBranchLimits2 ]

(* Branch Ord Val Limit Update In Message at zero, then each field in turn at the values it is checked at *)
CheckedBranchOrdValLimitUpdateInMessage ==
    { ZeroBranchOrdValLimitUpdateInMessage }
        \cup { [ZeroBranchOrdValLimitUpdateInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroBranchOrdValLimitUpdateInMessage EXCEPT !.reserved25 = one] : one \in Sample(25) }
        \cup { [ZeroBranchOrdValLimitUpdateInMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroBranchOrdValLimitUpdateInMessage EXCEPT !.branchLimits1 = one] : one \in CheckedBranchLimits1 }
        \cup { [ZeroBranchOrdValLimitUpdateInMessage EXCEPT !.branchLimits2 = one] : one \in CheckedBranchLimits2 }

(***************************************************************************)
(* User Limits 1: 64 bytes                                                 *)
(***************************************************************************)

UserLimits1 ==
    [ reserved32              : Sample(32),
      userOrderBuyValueLimit  : Sample(8),
      userOrderSellValueLimit : Sample(8),
      reserved16              : Sample(16) ]

EncodeUserLimits1(message) ==
    message.reserved32
        \o message.userOrderBuyValueLimit
        \o message.userOrderSellValueLimit
        \o message.reserved16

DecodeUserLimits1(bytes) ==
    LET reserved32 == ReadBytes(bytes, 32) IN IF ~reserved32.ok THEN Fail ELSE
    LET userOrderBuyValueLimit == ReadBytes(reserved32.rest, 8) IN IF ~userOrderBuyValueLimit.ok THEN Fail ELSE
    LET userOrderSellValueLimit == ReadBytes(userOrderBuyValueLimit.rest, 8) IN IF ~userOrderSellValueLimit.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(userOrderSellValueLimit.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ reserved32              |-> reserved32.value,
         userOrderBuyValueLimit  |-> userOrderBuyValueLimit.value,
         userOrderSellValueLimit |-> userOrderSellValueLimit.value,
         reserved16              |-> reserved16.value ], reserved16.rest)

ZeroUserLimits1 ==
    [ reserved32              |-> [i \in 1 .. 32 |-> 0],
      userOrderBuyValueLimit  |-> [i \in 1 .. 8 |-> 0],
      userOrderSellValueLimit |-> [i \in 1 .. 8 |-> 0],
      reserved16              |-> [i \in 1 .. 16 |-> 0] ]

(* User Limits 1 at zero, then each field in turn at the values it is checked at *)
CheckedUserLimits1 ==
    { ZeroUserLimits1 }
        \cup { [ZeroUserLimits1 EXCEPT !.reserved32 = one] : one \in Sample(32) }
        \cup { [ZeroUserLimits1 EXCEPT !.userOrderBuyValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroUserLimits1 EXCEPT !.userOrderSellValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroUserLimits1 EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* User Limits 2: 64 bytes                                                 *)
(***************************************************************************)

UserLimits2 ==
    [ reserved32              : Sample(32),
      userOrderBuyValueLimit  : Sample(8),
      userOrderSellValueLimit : Sample(8),
      reserved16              : Sample(16) ]

EncodeUserLimits2(message) ==
    message.reserved32
        \o message.userOrderBuyValueLimit
        \o message.userOrderSellValueLimit
        \o message.reserved16

DecodeUserLimits2(bytes) ==
    LET reserved32 == ReadBytes(bytes, 32) IN IF ~reserved32.ok THEN Fail ELSE
    LET userOrderBuyValueLimit == ReadBytes(reserved32.rest, 8) IN IF ~userOrderBuyValueLimit.ok THEN Fail ELSE
    LET userOrderSellValueLimit == ReadBytes(userOrderBuyValueLimit.rest, 8) IN IF ~userOrderSellValueLimit.ok THEN Fail ELSE
    LET reserved16 == ReadBytes(userOrderSellValueLimit.rest, 16) IN IF ~reserved16.ok THEN Fail ELSE
    Ok([ reserved32              |-> reserved32.value,
         userOrderBuyValueLimit  |-> userOrderBuyValueLimit.value,
         userOrderSellValueLimit |-> userOrderSellValueLimit.value,
         reserved16              |-> reserved16.value ], reserved16.rest)

ZeroUserLimits2 ==
    [ reserved32              |-> [i \in 1 .. 32 |-> 0],
      userOrderBuyValueLimit  |-> [i \in 1 .. 8 |-> 0],
      userOrderSellValueLimit |-> [i \in 1 .. 8 |-> 0],
      reserved16              |-> [i \in 1 .. 16 |-> 0] ]

(* User Limits 2 at zero, then each field in turn at the values it is checked at *)
CheckedUserLimits2 ==
    { ZeroUserLimits2 }
        \cup { [ZeroUserLimits2 EXCEPT !.reserved32 = one] : one \in Sample(32) }
        \cup { [ZeroUserLimits2 EXCEPT !.userOrderBuyValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroUserLimits2 EXCEPT !.userOrderSellValueLimit = one] : one \in Sample(8) }
        \cup { [ZeroUserLimits2 EXCEPT !.reserved16 = one] : one \in Sample(16) }

(***************************************************************************)
(* User Ord Val Limit Update In Message: 168 bytes                         *)
(***************************************************************************)

UserOrdValLimitUpdateInMessage ==
    [ brokerId    : Sample(5),
      reserved1   : Sample(1),
      branchId    : Sample(2),
      reserved26  : Sample(26),
      userId      : Sample(4),
      reserved2   : Sample(2),
      userLimits1 : UserLimits1,
      userLimits2 : UserLimits2 ]

EncodeUserOrdValLimitUpdateInMessage(message) ==
    message.brokerId
        \o message.reserved1
        \o message.branchId
        \o message.reserved26
        \o message.userId
        \o message.reserved2
        \o EncodeUserLimits1(message.userLimits1)
        \o EncodeUserLimits2(message.userLimits2)

DecodeUserOrdValLimitUpdateInMessage(bytes) ==
    LET brokerId == ReadBytes(bytes, 5) IN IF ~brokerId.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(brokerId.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET branchId == ReadBytes(reserved1.rest, 2) IN IF ~branchId.ok THEN Fail ELSE
    LET reserved26 == ReadBytes(branchId.rest, 26) IN IF ~reserved26.ok THEN Fail ELSE
    LET userId == ReadBytes(reserved26.rest, 4) IN IF ~userId.ok THEN Fail ELSE
    LET reserved2 == ReadBytes(userId.rest, 2) IN IF ~reserved2.ok THEN Fail ELSE
    LET userLimits1 == DecodeUserLimits1(reserved2.rest) IN IF ~userLimits1.ok THEN Fail ELSE
    LET userLimits2 == DecodeUserLimits2(userLimits1.rest) IN IF ~userLimits2.ok THEN Fail ELSE
    Ok([ brokerId    |-> brokerId.value,
         reserved1   |-> reserved1.value,
         branchId    |-> branchId.value,
         reserved26  |-> reserved26.value,
         userId      |-> userId.value,
         reserved2   |-> reserved2.value,
         userLimits1 |-> userLimits1.value,
         userLimits2 |-> userLimits2.value ], userLimits2.rest)

ZeroUserOrdValLimitUpdateInMessage ==
    [ brokerId    |-> [i \in 1 .. 5 |-> 0],
      reserved1   |-> [i \in 1 .. 1 |-> 0],
      branchId    |-> [i \in 1 .. 2 |-> 0],
      reserved26  |-> [i \in 1 .. 26 |-> 0],
      userId      |-> [i \in 1 .. 4 |-> 0],
      reserved2   |-> [i \in 1 .. 2 |-> 0],
      userLimits1 |-> ZeroUserLimits1,
      userLimits2 |-> ZeroUserLimits2 ]

(* User Ord Val Limit Update In Message at zero, then each field in turn at the values it is checked at *)
CheckedUserOrdValLimitUpdateInMessage ==
    { ZeroUserOrdValLimitUpdateInMessage }
        \cup { [ZeroUserOrdValLimitUpdateInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroUserOrdValLimitUpdateInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroUserOrdValLimitUpdateInMessage EXCEPT !.branchId = one] : one \in Sample(2) }
        \cup { [ZeroUserOrdValLimitUpdateInMessage EXCEPT !.reserved26 = one] : one \in Sample(26) }
        \cup { [ZeroUserOrdValLimitUpdateInMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroUserOrdValLimitUpdateInMessage EXCEPT !.reserved2 = one] : one \in Sample(2) }
        \cup { [ZeroUserOrdValLimitUpdateInMessage EXCEPT !.userLimits1 = one] : one \in CheckedUserLimits1 }
        \cup { [ZeroUserOrdValLimitUpdateInMessage EXCEPT !.userLimits2 = one] : one \in CheckedUserLimits2 }

(***************************************************************************)
(* Normal Ord Limit Update In Message: 26 bytes                            *)
(***************************************************************************)

NormalOrdLimitUpdateInMessage ==
    [ brokerId      : Sample(5),
      reserved1     : Sample(1),
      userId        : Sample(4),
      orderQtyLimit : Sample(8),
      orderValLimit : Sample(8) ]

EncodeNormalOrdLimitUpdateInMessage(message) ==
    message.brokerId
        \o message.reserved1
        \o message.userId
        \o message.orderQtyLimit
        \o message.orderValLimit

DecodeNormalOrdLimitUpdateInMessage(bytes) ==
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

ZeroNormalOrdLimitUpdateInMessage ==
    [ brokerId      |-> [i \in 1 .. 5 |-> 0],
      reserved1     |-> [i \in 1 .. 1 |-> 0],
      userId        |-> [i \in 1 .. 4 |-> 0],
      orderQtyLimit |-> [i \in 1 .. 8 |-> 0],
      orderValLimit |-> [i \in 1 .. 8 |-> 0] ]

(* Normal Ord Limit Update In Message at zero, then each field in turn at the values it is checked at *)
CheckedNormalOrdLimitUpdateInMessage ==
    { ZeroNormalOrdLimitUpdateInMessage }
        \cup { [ZeroNormalOrdLimitUpdateInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroNormalOrdLimitUpdateInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroNormalOrdLimitUpdateInMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroNormalOrdLimitUpdateInMessage EXCEPT !.orderQtyLimit = one] : one \in Sample(8) }
        \cup { [ZeroNormalOrdLimitUpdateInMessage EXCEPT !.orderValLimit = one] : one \in Sample(8) }

(***************************************************************************)
(* Spread Ord Limit Update In Message: 26 bytes                            *)
(***************************************************************************)

SpreadOrdLimitUpdateInMessage ==
    [ brokerId      : Sample(5),
      reserved1     : Sample(1),
      userId        : Sample(4),
      orderQtyLimit : Sample(8),
      orderValLimit : Sample(8) ]

EncodeSpreadOrdLimitUpdateInMessage(message) ==
    message.brokerId
        \o message.reserved1
        \o message.userId
        \o message.orderQtyLimit
        \o message.orderValLimit

DecodeSpreadOrdLimitUpdateInMessage(bytes) ==
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

ZeroSpreadOrdLimitUpdateInMessage ==
    [ brokerId      |-> [i \in 1 .. 5 |-> 0],
      reserved1     |-> [i \in 1 .. 1 |-> 0],
      userId        |-> [i \in 1 .. 4 |-> 0],
      orderQtyLimit |-> [i \in 1 .. 8 |-> 0],
      orderValLimit |-> [i \in 1 .. 8 |-> 0] ]

(* Spread Ord Limit Update In Message at zero, then each field in turn at the values it is checked at *)
CheckedSpreadOrdLimitUpdateInMessage ==
    { ZeroSpreadOrdLimitUpdateInMessage }
        \cup { [ZeroSpreadOrdLimitUpdateInMessage EXCEPT !.brokerId = one] : one \in Sample(5) }
        \cup { [ZeroSpreadOrdLimitUpdateInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroSpreadOrdLimitUpdateInMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroSpreadOrdLimitUpdateInMessage EXCEPT !.orderQtyLimit = one] : one \in Sample(8) }
        \cup { [ZeroSpreadOrdLimitUpdateInMessage EXCEPT !.orderValLimit = one] : one \in Sample(8) }

(***************************************************************************)
(* Reset User Password In Message: 18 bytes                                *)
(***************************************************************************)

ResetUserPasswordInMessage ==
    [ userId     : Sample(4),
      reserved14 : Sample(14) ]

EncodeResetUserPasswordInMessage(message) ==
    message.userId
        \o message.reserved14

DecodeResetUserPasswordInMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET reserved14 == ReadBytes(userId.rest, 14) IN IF ~reserved14.ok THEN Fail ELSE
    Ok([ userId     |-> userId.value,
         reserved14 |-> reserved14.value ], reserved14.rest)

ZeroResetUserPasswordInMessage ==
    [ userId     |-> [i \in 1 .. 4 |-> 0],
      reserved14 |-> [i \in 1 .. 14 |-> 0] ]

(* Reset User Password In Message at zero, then each field in turn at the values it is checked at *)
CheckedResetUserPasswordInMessage ==
    { ZeroResetUserPasswordInMessage }
        \cup { [ZeroResetUserPasswordInMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroResetUserPasswordInMessage EXCEPT !.reserved14 = one] : one \in Sample(14) }

(***************************************************************************)
(* Col User Status Change In Message: 12 bytes                             *)
(***************************************************************************)

ColUserStatusChangeInMessage ==
    [ userId     : Sample(4),
      colUserBit : Sample(1),
      reserved7  : Sample(7) ]

EncodeColUserStatusChangeInMessage(message) ==
    message.userId
        \o message.colUserBit
        \o message.reserved7

DecodeColUserStatusChangeInMessage(bytes) ==
    LET userId == ReadBytes(bytes, 4) IN IF ~userId.ok THEN Fail ELSE
    LET colUserBit == ReadBytes(userId.rest, 1) IN IF ~colUserBit.ok THEN Fail ELSE
    LET reserved7 == ReadBytes(colUserBit.rest, 7) IN IF ~reserved7.ok THEN Fail ELSE
    Ok([ userId     |-> userId.value,
         colUserBit |-> colUserBit.value,
         reserved7  |-> reserved7.value ], reserved7.rest)

ZeroColUserStatusChangeInMessage ==
    [ userId     |-> [i \in 1 .. 4 |-> 0],
      colUserBit |-> [i \in 1 .. 1 |-> 0],
      reserved7  |-> [i \in 1 .. 7 |-> 0] ]

(* Col User Status Change In Message at zero, then each field in turn at the values it is checked at *)
CheckedColUserStatusChangeInMessage ==
    { ZeroColUserStatusChangeInMessage }
        \cup { [ZeroColUserStatusChangeInMessage EXCEPT !.userId = one] : one \in Sample(4) }
        \cup { [ZeroColUserStatusChangeInMessage EXCEPT !.colUserBit = one] : one \in Sample(1) }
        \cup { [ZeroColUserStatusChangeInMessage EXCEPT !.reserved7 = one] : one \in Sample(7) }

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
(* St Market Status: 8 bytes                                               *)
(***************************************************************************)

StMarketStatus ==
    [ normal  : Sample(2),
      oddlot  : Sample(2),
      spot    : Sample(2),
      auction : Sample(2) ]

EncodeStMarketStatus(message) ==
    message.normal
        \o message.oddlot
        \o message.spot
        \o message.auction

DecodeStMarketStatus(bytes) ==
    LET normal == ReadBytes(bytes, 2) IN IF ~normal.ok THEN Fail ELSE
    LET oddlot == ReadBytes(normal.rest, 2) IN IF ~oddlot.ok THEN Fail ELSE
    LET spot == ReadBytes(oddlot.rest, 2) IN IF ~spot.ok THEN Fail ELSE
    LET auction == ReadBytes(spot.rest, 2) IN IF ~auction.ok THEN Fail ELSE
    Ok([ normal  |-> normal.value,
         oddlot  |-> oddlot.value,
         spot    |-> spot.value,
         auction |-> auction.value ], auction.rest)

ZeroStMarketStatus ==
    [ normal  |-> [i \in 1 .. 2 |-> 0],
      oddlot  |-> [i \in 1 .. 2 |-> 0],
      spot    |-> [i \in 1 .. 2 |-> 0],
      auction |-> [i \in 1 .. 2 |-> 0] ]

(* St Market Status at zero, then each field in turn at the values it is checked at *)
CheckedStMarketStatus ==
    { ZeroStMarketStatus }
        \cup { [ZeroStMarketStatus EXCEPT !.normal = one] : one \in Sample(2) }
        \cup { [ZeroStMarketStatus EXCEPT !.oddlot = one] : one \in Sample(2) }
        \cup { [ZeroStMarketStatus EXCEPT !.spot = one] : one \in Sample(2) }
        \cup { [ZeroStMarketStatus EXCEPT !.auction = one] : one \in Sample(2) }

(***************************************************************************)
(* St Ex Market Status: 8 bytes                                            *)
(***************************************************************************)

StExMarketStatus ==
    [ normal  : Sample(2),
      oddlot  : Sample(2),
      spot    : Sample(2),
      auction : Sample(2) ]

EncodeStExMarketStatus(message) ==
    message.normal
        \o message.oddlot
        \o message.spot
        \o message.auction

DecodeStExMarketStatus(bytes) ==
    LET normal == ReadBytes(bytes, 2) IN IF ~normal.ok THEN Fail ELSE
    LET oddlot == ReadBytes(normal.rest, 2) IN IF ~oddlot.ok THEN Fail ELSE
    LET spot == ReadBytes(oddlot.rest, 2) IN IF ~spot.ok THEN Fail ELSE
    LET auction == ReadBytes(spot.rest, 2) IN IF ~auction.ok THEN Fail ELSE
    Ok([ normal  |-> normal.value,
         oddlot  |-> oddlot.value,
         spot    |-> spot.value,
         auction |-> auction.value ], auction.rest)

ZeroStExMarketStatus ==
    [ normal  |-> [i \in 1 .. 2 |-> 0],
      oddlot  |-> [i \in 1 .. 2 |-> 0],
      spot    |-> [i \in 1 .. 2 |-> 0],
      auction |-> [i \in 1 .. 2 |-> 0] ]

(* St Ex Market Status at zero, then each field in turn at the values it is checked at *)
CheckedStExMarketStatus ==
    { ZeroStExMarketStatus }
        \cup { [ZeroStExMarketStatus EXCEPT !.normal = one] : one \in Sample(2) }
        \cup { [ZeroStExMarketStatus EXCEPT !.oddlot = one] : one \in Sample(2) }
        \cup { [ZeroStExMarketStatus EXCEPT !.spot = one] : one \in Sample(2) }
        \cup { [ZeroStExMarketStatus EXCEPT !.auction = one] : one \in Sample(2) }

(***************************************************************************)
(* St Pl Market Status: 8 bytes                                            *)
(***************************************************************************)

StPlMarketStatus ==
    [ normal  : Sample(2),
      oddlot  : Sample(2),
      spot    : Sample(2),
      auction : Sample(2) ]

EncodeStPlMarketStatus(message) ==
    message.normal
        \o message.oddlot
        \o message.spot
        \o message.auction

DecodeStPlMarketStatus(bytes) ==
    LET normal == ReadBytes(bytes, 2) IN IF ~normal.ok THEN Fail ELSE
    LET oddlot == ReadBytes(normal.rest, 2) IN IF ~oddlot.ok THEN Fail ELSE
    LET spot == ReadBytes(oddlot.rest, 2) IN IF ~spot.ok THEN Fail ELSE
    LET auction == ReadBytes(spot.rest, 2) IN IF ~auction.ok THEN Fail ELSE
    Ok([ normal  |-> normal.value,
         oddlot  |-> oddlot.value,
         spot    |-> spot.value,
         auction |-> auction.value ], auction.rest)

ZeroStPlMarketStatus ==
    [ normal  |-> [i \in 1 .. 2 |-> 0],
      oddlot  |-> [i \in 1 .. 2 |-> 0],
      spot    |-> [i \in 1 .. 2 |-> 0],
      auction |-> [i \in 1 .. 2 |-> 0] ]

(* St Pl Market Status at zero, then each field in turn at the values it is checked at *)
CheckedStPlMarketStatus ==
    { ZeroStPlMarketStatus }
        \cup { [ZeroStPlMarketStatus EXCEPT !.normal = one] : one \in Sample(2) }
        \cup { [ZeroStPlMarketStatus EXCEPT !.oddlot = one] : one \in Sample(2) }
        \cup { [ZeroStPlMarketStatus EXCEPT !.spot = one] : one \in Sample(2) }
        \cup { [ZeroStPlMarketStatus EXCEPT !.auction = one] : one \in Sample(2) }

(***************************************************************************)
(* Update Localdb In Message: 42 bytes                                     *)
(***************************************************************************)

UpdateLocaldbInMessage ==
    [ lastUpdateSecurityTime    : Sample(4),
      lastUpdateParticipantTime : Sample(4),
      lastUpdateInstrumentTime  : Sample(4),
      lastUpdateIndexTime       : Sample(4),
      requestForOpenOrders      : Sample(1),
      reserved1                 : Sample(1),
      stMarketStatus            : StMarketStatus,
      stExMarketStatus          : StExMarketStatus,
      stPlMarketStatus          : StPlMarketStatus ]

EncodeUpdateLocaldbInMessage(message) ==
    message.lastUpdateSecurityTime
        \o message.lastUpdateParticipantTime
        \o message.lastUpdateInstrumentTime
        \o message.lastUpdateIndexTime
        \o message.requestForOpenOrders
        \o message.reserved1
        \o EncodeStMarketStatus(message.stMarketStatus)
        \o EncodeStExMarketStatus(message.stExMarketStatus)
        \o EncodeStPlMarketStatus(message.stPlMarketStatus)

DecodeUpdateLocaldbInMessage(bytes) ==
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

ZeroUpdateLocaldbInMessage ==
    [ lastUpdateSecurityTime    |-> [i \in 1 .. 4 |-> 0],
      lastUpdateParticipantTime |-> [i \in 1 .. 4 |-> 0],
      lastUpdateInstrumentTime  |-> [i \in 1 .. 4 |-> 0],
      lastUpdateIndexTime       |-> [i \in 1 .. 4 |-> 0],
      requestForOpenOrders      |-> [i \in 1 .. 1 |-> 0],
      reserved1                 |-> [i \in 1 .. 1 |-> 0],
      stMarketStatus            |-> ZeroStMarketStatus,
      stExMarketStatus          |-> ZeroStExMarketStatus,
      stPlMarketStatus          |-> ZeroStPlMarketStatus ]

(* Update Localdb In Message at zero, then each field in turn at the values it is checked at *)
CheckedUpdateLocaldbInMessage ==
    { ZeroUpdateLocaldbInMessage }
        \cup { [ZeroUpdateLocaldbInMessage EXCEPT !.lastUpdateSecurityTime = one] : one \in Sample(4) }
        \cup { [ZeroUpdateLocaldbInMessage EXCEPT !.lastUpdateParticipantTime = one] : one \in Sample(4) }
        \cup { [ZeroUpdateLocaldbInMessage EXCEPT !.lastUpdateInstrumentTime = one] : one \in Sample(4) }
        \cup { [ZeroUpdateLocaldbInMessage EXCEPT !.lastUpdateIndexTime = one] : one \in Sample(4) }
        \cup { [ZeroUpdateLocaldbInMessage EXCEPT !.requestForOpenOrders = one] : one \in Sample(1) }
        \cup { [ZeroUpdateLocaldbInMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroUpdateLocaldbInMessage EXCEPT !.stMarketStatus = one] : one \in CheckedStMarketStatus }
        \cup { [ZeroUpdateLocaldbInMessage EXCEPT !.stExMarketStatus = one] : one \in CheckedStExMarketStatus }
        \cup { [ZeroUpdateLocaldbInMessage EXCEPT !.stPlMarketStatus = one] : one \in CheckedStPlMarketStatus }

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
(* Client Message Payload, selected by Transaction Code                    *)
(***************************************************************************)

SystemInformationInMessageCode == 1600  \* 0x640
BoardLotInMessageCode == 2000  \* 0x7d0
OrderModInMessageCode == 2040  \* 0x7f8
OrderCancelInMessageCode == 2070  \* 0x816
PriceModInMessageCode == 2013  \* 0x7dd
SpBoardLotInMessageCode == 2100  \* 0x834
TwolBoardLotInMessageCode == 2102  \* 0x836
ThrlBoardLotInMessageCode == 2104  \* 0x838
SpOrderCancelInMessageCode == 2106  \* 0x83a
SpOrderModInMessageCode == 2118  \* 0x846
TradeCancelInMessageCode == 5440  \* 0x1540
TradeModInMessageCode == 5445  \* 0x1545
SignOnRequestInMessageCode == 2300  \* 0x8fc
SignOffTraderInMessageCode == 5584  \* 0x15d0
GrRequestMessageCode == 2400  \* 0x960
UserAddrUnlockInMessageCode == 5427  \* 0x1533
BranchOrdValLimitUpdateInMessageCode == 5716  \* 0x1654
UserOrdValLimitUpdateInMessageCode == 5730  \* 0x1662
NormalOrdLimitUpdateInMessageCode == 5732  \* 0x1664
SpreadOrdLimitUpdateInMessageCode == 5771  \* 0x168b
ResetUserPasswordInMessageCode == 5740  \* 0x166c
ColUserStatusChangeInMessageCode == 5744  \* 0x1670
DownloadRequestMessageCode == 7000  \* 0x1b58
UpdateLocaldbInMessageCode == 7300  \* 0x1c84
BoxSignOnRequestInMessageCode == 23000  \* 0x59d8

ClientMessagePayload ==
    [ tag : {SystemInformationInMessageCode}, body : SystemInformationInMessage ]
        \cup [ tag : {BoardLotInMessageCode}, body : BoardLotInMessage ]
        \cup [ tag : {OrderModInMessageCode}, body : OrderModInMessage ]
        \cup [ tag : {OrderCancelInMessageCode}, body : OrderCancelInMessage ]
        \cup [ tag : {PriceModInMessageCode}, body : PriceModInMessage ]
        \cup [ tag : {SpBoardLotInMessageCode}, body : SpBoardLotInMessage ]
        \cup [ tag : {TwolBoardLotInMessageCode}, body : TwolBoardLotInMessage ]
        \cup [ tag : {ThrlBoardLotInMessageCode}, body : ThrlBoardLotInMessage ]
        \cup [ tag : {SpOrderCancelInMessageCode}, body : SpOrderCancelInMessage ]
        \cup [ tag : {SpOrderModInMessageCode}, body : SpOrderModInMessage ]
        \cup [ tag : {TradeCancelInMessageCode}, body : TradeCancelInMessage ]
        \cup [ tag : {TradeModInMessageCode}, body : TradeModInMessage ]
        \cup [ tag : {SignOnRequestInMessageCode}, body : SignOnRequestInMessage ]
        \cup [ tag : {SignOffTraderInMessageCode}, body : SignOffTraderInMessage ]
        \cup [ tag : {GrRequestMessageCode}, body : GrRequestMessage ]
        \cup [ tag : {UserAddrUnlockInMessageCode}, body : UserAddrUnlockInMessage ]
        \cup [ tag : {BranchOrdValLimitUpdateInMessageCode}, body : BranchOrdValLimitUpdateInMessage ]
        \cup [ tag : {UserOrdValLimitUpdateInMessageCode}, body : UserOrdValLimitUpdateInMessage ]
        \cup [ tag : {NormalOrdLimitUpdateInMessageCode}, body : NormalOrdLimitUpdateInMessage ]
        \cup [ tag : {SpreadOrdLimitUpdateInMessageCode}, body : SpreadOrdLimitUpdateInMessage ]
        \cup [ tag : {ResetUserPasswordInMessageCode}, body : ResetUserPasswordInMessage ]
        \cup [ tag : {ColUserStatusChangeInMessageCode}, body : ColUserStatusChangeInMessage ]
        \cup [ tag : {DownloadRequestMessageCode}, body : DownloadRequestMessage ]
        \cup [ tag : {UpdateLocaldbInMessageCode}, body : UpdateLocaldbInMessage ]
        \cup [ tag : {BoxSignOnRequestInMessageCode}, body : BoxSignOnRequestInMessage ]

EncodeClientMessagePayload(message) ==
    CASE message.tag = SystemInformationInMessageCode -> EncodeSystemInformationInMessage(message.body)
      [] message.tag = BoardLotInMessageCode -> EncodeBoardLotInMessage(message.body)
      [] message.tag = OrderModInMessageCode -> EncodeOrderModInMessage(message.body)
      [] message.tag = OrderCancelInMessageCode -> EncodeOrderCancelInMessage(message.body)
      [] message.tag = PriceModInMessageCode -> EncodePriceModInMessage(message.body)
      [] message.tag = SpBoardLotInMessageCode -> EncodeSpBoardLotInMessage(message.body)
      [] message.tag = TwolBoardLotInMessageCode -> EncodeTwolBoardLotInMessage(message.body)
      [] message.tag = ThrlBoardLotInMessageCode -> EncodeThrlBoardLotInMessage(message.body)
      [] message.tag = SpOrderCancelInMessageCode -> EncodeSpOrderCancelInMessage(message.body)
      [] message.tag = SpOrderModInMessageCode -> EncodeSpOrderModInMessage(message.body)
      [] message.tag = TradeCancelInMessageCode -> EncodeTradeCancelInMessage(message.body)
      [] message.tag = TradeModInMessageCode -> EncodeTradeModInMessage(message.body)
      [] message.tag = SignOnRequestInMessageCode -> EncodeSignOnRequestInMessage(message.body)
      [] message.tag = SignOffTraderInMessageCode -> EncodeSignOffTraderInMessage(message.body)
      [] message.tag = GrRequestMessageCode -> EncodeGrRequestMessage(message.body)
      [] message.tag = UserAddrUnlockInMessageCode -> EncodeUserAddrUnlockInMessage(message.body)
      [] message.tag = BranchOrdValLimitUpdateInMessageCode -> EncodeBranchOrdValLimitUpdateInMessage(message.body)
      [] message.tag = UserOrdValLimitUpdateInMessageCode -> EncodeUserOrdValLimitUpdateInMessage(message.body)
      [] message.tag = NormalOrdLimitUpdateInMessageCode -> EncodeNormalOrdLimitUpdateInMessage(message.body)
      [] message.tag = SpreadOrdLimitUpdateInMessageCode -> EncodeSpreadOrdLimitUpdateInMessage(message.body)
      [] message.tag = ResetUserPasswordInMessageCode -> EncodeResetUserPasswordInMessage(message.body)
      [] message.tag = ColUserStatusChangeInMessageCode -> EncodeColUserStatusChangeInMessage(message.body)
      [] message.tag = DownloadRequestMessageCode -> EncodeDownloadRequestMessage(message.body)
      [] message.tag = UpdateLocaldbInMessageCode -> EncodeUpdateLocaldbInMessage(message.body)
      [] message.tag = BoxSignOnRequestInMessageCode -> EncodeBoxSignOnRequestInMessage(message.body)

DecodeClientMessagePayload(tag, bytes) ==
    LET read ==
            CASE tag = SystemInformationInMessageCode -> DecodeSystemInformationInMessage(bytes)
              [] tag = BoardLotInMessageCode -> DecodeBoardLotInMessage(bytes)
              [] tag = OrderModInMessageCode -> DecodeOrderModInMessage(bytes)
              [] tag = OrderCancelInMessageCode -> DecodeOrderCancelInMessage(bytes)
              [] tag = PriceModInMessageCode -> DecodePriceModInMessage(bytes)
              [] tag = SpBoardLotInMessageCode -> DecodeSpBoardLotInMessage(bytes)
              [] tag = TwolBoardLotInMessageCode -> DecodeTwolBoardLotInMessage(bytes)
              [] tag = ThrlBoardLotInMessageCode -> DecodeThrlBoardLotInMessage(bytes)
              [] tag = SpOrderCancelInMessageCode -> DecodeSpOrderCancelInMessage(bytes)
              [] tag = SpOrderModInMessageCode -> DecodeSpOrderModInMessage(bytes)
              [] tag = TradeCancelInMessageCode -> DecodeTradeCancelInMessage(bytes)
              [] tag = TradeModInMessageCode -> DecodeTradeModInMessage(bytes)
              [] tag = SignOnRequestInMessageCode -> DecodeSignOnRequestInMessage(bytes)
              [] tag = SignOffTraderInMessageCode -> DecodeSignOffTraderInMessage(bytes)
              [] tag = GrRequestMessageCode -> DecodeGrRequestMessage(bytes)
              [] tag = UserAddrUnlockInMessageCode -> DecodeUserAddrUnlockInMessage(bytes)
              [] tag = BranchOrdValLimitUpdateInMessageCode -> DecodeBranchOrdValLimitUpdateInMessage(bytes)
              [] tag = UserOrdValLimitUpdateInMessageCode -> DecodeUserOrdValLimitUpdateInMessage(bytes)
              [] tag = NormalOrdLimitUpdateInMessageCode -> DecodeNormalOrdLimitUpdateInMessage(bytes)
              [] tag = SpreadOrdLimitUpdateInMessageCode -> DecodeSpreadOrdLimitUpdateInMessage(bytes)
              [] tag = ResetUserPasswordInMessageCode -> DecodeResetUserPasswordInMessage(bytes)
              [] tag = ColUserStatusChangeInMessageCode -> DecodeColUserStatusChangeInMessage(bytes)
              [] tag = DownloadRequestMessageCode -> DecodeDownloadRequestMessage(bytes)
              [] tag = UpdateLocaldbInMessageCode -> DecodeUpdateLocaldbInMessage(bytes)
              [] tag = BoxSignOnRequestInMessageCode -> DecodeBoxSignOnRequestInMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientMessagePayload == [tag |-> SystemInformationInMessageCode, body |-> ZeroSystemInformationInMessage]

(* Each Client Message Payload in turn, at the values the message it names is checked at *)
CheckedClientMessagePayload ==
    { [tag |-> SystemInformationInMessageCode, body |-> one] : one \in CheckedSystemInformationInMessage }
        \cup { [tag |-> BoardLotInMessageCode, body |-> one] : one \in CheckedBoardLotInMessage }
        \cup { [tag |-> OrderModInMessageCode, body |-> one] : one \in CheckedOrderModInMessage }
        \cup { [tag |-> OrderCancelInMessageCode, body |-> one] : one \in CheckedOrderCancelInMessage }
        \cup { [tag |-> PriceModInMessageCode, body |-> one] : one \in CheckedPriceModInMessage }
        \cup { [tag |-> SpBoardLotInMessageCode, body |-> one] : one \in CheckedSpBoardLotInMessage }
        \cup { [tag |-> TwolBoardLotInMessageCode, body |-> one] : one \in CheckedTwolBoardLotInMessage }
        \cup { [tag |-> ThrlBoardLotInMessageCode, body |-> one] : one \in CheckedThrlBoardLotInMessage }
        \cup { [tag |-> SpOrderCancelInMessageCode, body |-> one] : one \in CheckedSpOrderCancelInMessage }
        \cup { [tag |-> SpOrderModInMessageCode, body |-> one] : one \in CheckedSpOrderModInMessage }
        \cup { [tag |-> TradeCancelInMessageCode, body |-> one] : one \in CheckedTradeCancelInMessage }
        \cup { [tag |-> TradeModInMessageCode, body |-> one] : one \in CheckedTradeModInMessage }
        \cup { [tag |-> SignOnRequestInMessageCode, body |-> one] : one \in CheckedSignOnRequestInMessage }
        \cup { [tag |-> SignOffTraderInMessageCode, body |-> one] : one \in CheckedSignOffTraderInMessage }
        \cup { [tag |-> GrRequestMessageCode, body |-> one] : one \in CheckedGrRequestMessage }
        \cup { [tag |-> UserAddrUnlockInMessageCode, body |-> one] : one \in CheckedUserAddrUnlockInMessage }
        \cup { [tag |-> BranchOrdValLimitUpdateInMessageCode, body |-> one] : one \in CheckedBranchOrdValLimitUpdateInMessage }
        \cup { [tag |-> UserOrdValLimitUpdateInMessageCode, body |-> one] : one \in CheckedUserOrdValLimitUpdateInMessage }
        \cup { [tag |-> NormalOrdLimitUpdateInMessageCode, body |-> one] : one \in CheckedNormalOrdLimitUpdateInMessage }
        \cup { [tag |-> SpreadOrdLimitUpdateInMessageCode, body |-> one] : one \in CheckedSpreadOrdLimitUpdateInMessage }
        \cup { [tag |-> ResetUserPasswordInMessageCode, body |-> one] : one \in CheckedResetUserPasswordInMessage }
        \cup { [tag |-> ColUserStatusChangeInMessageCode, body |-> one] : one \in CheckedColUserStatusChangeInMessage }
        \cup { [tag |-> DownloadRequestMessageCode, body |-> one] : one \in CheckedDownloadRequestMessage }
        \cup { [tag |-> UpdateLocaldbInMessageCode, body |-> one] : one \in CheckedUpdateLocaldbInMessage }
        \cup { [tag |-> BoxSignOnRequestInMessageCode, body |-> one] : one \in CheckedBoxSignOnRequestInMessage }

(***************************************************************************)
(* Client Message, framed by Message Length                                *)
(***************************************************************************)

ClientMessage ==
    [ logTime              : Sample(4),
      alphaChar            : Sample(2),
      traderId             : Sample(4),
      errorCode            : Sample(2),
      headerTimestamp      : Sample(8),
      timeStamp1           : Sample(8),
      timeStamp2           : Sample(8),
      clientMessagePayload : ClientMessagePayload ]

EncodeClientMessageBody(message) ==
    EncodeClientMessagePayload(message.clientMessagePayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeClientMessage(message) ==
    LET body == EncodeClientMessageBody(message)
    IN  EncodeUIntBE(message.clientMessagePayload.tag, 2) \o message.logTime \o message.alphaChar \o message.traderId \o message.errorCode \o message.headerTimestamp \o message.timeStamp1 \o message.timeStamp2 \o EncodeUIntBE(Len(body) + 40, 2) \o body

DecodeClientMessage(bytes) ==
    LET transactionCode == ReadUIntBE(bytes, 2) IN IF ~transactionCode.ok THEN Fail ELSE
    LET logTime == ReadBytes(transactionCode.rest, 4) IN IF ~logTime.ok THEN Fail ELSE
    LET alphaChar == ReadBytes(logTime.rest, 2) IN IF ~alphaChar.ok THEN Fail ELSE
    LET traderId == ReadBytes(alphaChar.rest, 4) IN IF ~traderId.ok THEN Fail ELSE
    LET errorCode == ReadBytes(traderId.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET headerTimestamp == ReadBytes(errorCode.rest, 8) IN IF ~headerTimestamp.ok THEN Fail ELSE
    LET timeStamp1 == ReadBytes(headerTimestamp.rest, 8) IN IF ~timeStamp1.ok THEN Fail ELSE
    LET timeStamp2 == ReadBytes(timeStamp1.rest, 8) IN IF ~timeStamp2.ok THEN Fail ELSE
    LET length == ReadUIntBE(timeStamp2.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 40 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET clientMessagePayload == DecodeClientMessagePayload(transactionCode.value, framed) IN IF ~clientMessagePayload.ok THEN Fail ELSE
    IF clientMessagePayload.rest # << >> THEN Fail ELSE
    Ok([ logTime              |-> logTime.value,
         alphaChar            |-> alphaChar.value,
         traderId             |-> traderId.value,
         errorCode            |-> errorCode.value,
         headerTimestamp      |-> headerTimestamp.value,
         timeStamp1           |-> timeStamp1.value,
         timeStamp2           |-> timeStamp2.value,
         clientMessagePayload |-> clientMessagePayload.value ], beyond)

ZeroClientMessage ==
    [ logTime              |-> [i \in 1 .. 4 |-> 0],
      alphaChar            |-> [i \in 1 .. 2 |-> 0],
      traderId             |-> [i \in 1 .. 4 |-> 0],
      errorCode            |-> [i \in 1 .. 2 |-> 0],
      headerTimestamp      |-> [i \in 1 .. 8 |-> 0],
      timeStamp1           |-> [i \in 1 .. 8 |-> 0],
      timeStamp2           |-> [i \in 1 .. 8 |-> 0],
      clientMessagePayload |-> ZeroClientMessagePayload ]

(* Client Message at zero, then each field in turn at the values it is checked at *)
CheckedClientMessage ==
    { ZeroClientMessage }
        \cup { [ZeroClientMessage EXCEPT !.logTime = one] : one \in Sample(4) }
        \cup { [ZeroClientMessage EXCEPT !.alphaChar = one] : one \in Sample(2) }
        \cup { [ZeroClientMessage EXCEPT !.traderId = one] : one \in Sample(4) }
        \cup { [ZeroClientMessage EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroClientMessage EXCEPT !.headerTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroClientMessage EXCEPT !.timeStamp1 = one] : one \in Sample(8) }
        \cup { [ZeroClientMessage EXCEPT !.timeStamp2 = one] : one \in Sample(8) }
        \cup { [ZeroClientMessage EXCEPT !.clientMessagePayload = one] : one \in CheckedClientMessagePayload }

(* A run of Client Message, written one after another *)
RECURSIVE EncodeClientMessageList(_)
EncodeClientMessageList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientMessage(Head(messages)) \o EncodeClientMessageList(Tail(messages))

(* As many Client Message as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientMessageAll(_)
ReadClientMessageAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientMessage(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientMessageAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Message of each kind, for the lists that carry them *)
OneClientMessage ==
    { [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> SystemInformationInMessageCode, body |-> ZeroSystemInformationInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> BoardLotInMessageCode, body |-> ZeroBoardLotInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> OrderModInMessageCode, body |-> ZeroOrderModInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> OrderCancelInMessageCode, body |-> ZeroOrderCancelInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> PriceModInMessageCode, body |-> ZeroPriceModInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> SpBoardLotInMessageCode, body |-> ZeroSpBoardLotInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> TwolBoardLotInMessageCode, body |-> ZeroTwolBoardLotInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> ThrlBoardLotInMessageCode, body |-> ZeroThrlBoardLotInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> SpOrderCancelInMessageCode, body |-> ZeroSpOrderCancelInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> SpOrderModInMessageCode, body |-> ZeroSpOrderModInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> TradeCancelInMessageCode, body |-> ZeroTradeCancelInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> TradeModInMessageCode, body |-> ZeroTradeModInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> SignOnRequestInMessageCode, body |-> ZeroSignOnRequestInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> SignOffTraderInMessageCode, body |-> ZeroSignOffTraderInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> GrRequestMessageCode, body |-> ZeroGrRequestMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> UserAddrUnlockInMessageCode, body |-> ZeroUserAddrUnlockInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> BranchOrdValLimitUpdateInMessageCode, body |-> ZeroBranchOrdValLimitUpdateInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> UserOrdValLimitUpdateInMessageCode, body |-> ZeroUserOrdValLimitUpdateInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> NormalOrdLimitUpdateInMessageCode, body |-> ZeroNormalOrdLimitUpdateInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> SpreadOrdLimitUpdateInMessageCode, body |-> ZeroSpreadOrdLimitUpdateInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> ResetUserPasswordInMessageCode, body |-> ZeroResetUserPasswordInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> ColUserStatusChangeInMessageCode, body |-> ZeroColUserStatusChangeInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> DownloadRequestMessageCode, body |-> ZeroDownloadRequestMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> UpdateLocaldbInMessageCode, body |-> ZeroUpdateLocaldbInMessage]],
      [ZeroClientMessage EXCEPT !.clientMessagePayload = [tag |-> BoxSignOnRequestInMessageCode, body |-> ZeroBoxSignOnRequestInMessage]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientMessage : SampleLists(OneClientMessage) ]

EncodeClientPacket(message) ==
    EncodeClientMessageList(message.clientMessage)

DecodeClientPacket(bytes) ==
    LET clientMessage == ReadClientMessageAll(bytes) IN IF ~clientMessage.ok THEN Fail ELSE
    Ok([ clientMessage |-> clientMessage.value ], clientMessage.rest)

ZeroClientPacket ==
    [ clientMessage |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientMessage = one] : one \in SampleLists(OneClientMessage) }

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

(* Every System Information In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSystemInformationInMessage ==
    \A message \in CheckedSystemInformationInMessage :
        LET read == DecodeSystemInformationInMessage(EncodeSystemInformationInMessage(message))
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

(* Every Board Lot In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBoardLotInMessage ==
    \A message \in CheckedBoardLotInMessage :
        LET read == DecodeBoardLotInMessage(EncodeBoardLotInMessage(message))
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

(* Every Order Mod In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModInMessage ==
    \A message \in CheckedOrderModInMessage :
        LET read == DecodeOrderModInMessage(EncodeOrderModInMessage(message))
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

(* Every Order Cancel In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelInMessage ==
    \A message \in CheckedOrderCancelInMessage :
        LET read == DecodeOrderCancelInMessage(EncodeOrderCancelInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Mod In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceModInMessage ==
    \A message \in CheckedPriceModInMessage :
        LET read == DecodePriceModInMessage(EncodePriceModInMessage(message))
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

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc5 ==
    \A message \in CheckedContractDesc5 :
        LET read == DecodeContractDesc5(EncodeContractDesc5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg2 ==
    \A message \in CheckedMsSpdLegInfoLeg2 :
        LET read == DecodeMsSpdLegInfoLeg2(EncodeMsSpdLegInfoLeg2(message))
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

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg3 ==
    \A message \in CheckedMsSpdLegInfoLeg3 :
        LET read == DecodeMsSpdLegInfoLeg3(EncodeMsSpdLegInfoLeg3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sp Board Lot In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpBoardLotInMessage ==
    \A message \in CheckedSpBoardLotInMessage :
        LET read == DecodeSpBoardLotInMessage(EncodeSpBoardLotInMessage(message))
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

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc8 ==
    \A message \in CheckedContractDesc8 :
        LET read == DecodeContractDesc8(EncodeContractDesc8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg22 ==
    \A message \in CheckedMsSpdLegInfoLeg22 :
        LET read == DecodeMsSpdLegInfoLeg22(EncodeMsSpdLegInfoLeg22(message))
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

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg32 ==
    \A message \in CheckedMsSpdLegInfoLeg32 :
        LET read == DecodeMsSpdLegInfoLeg32(EncodeMsSpdLegInfoLeg32(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Twol Board Lot In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTwolBoardLotInMessage ==
    \A message \in CheckedTwolBoardLotInMessage :
        LET read == DecodeTwolBoardLotInMessage(EncodeTwolBoardLotInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc10 ==
    \A message \in CheckedContractDesc10 :
        LET read == DecodeContractDesc10(EncodeContractDesc10(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc11 ==
    \A message \in CheckedContractDesc11 :
        LET read == DecodeContractDesc11(EncodeContractDesc11(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg23 ==
    \A message \in CheckedMsSpdLegInfoLeg23 :
        LET read == DecodeMsSpdLegInfoLeg23(EncodeMsSpdLegInfoLeg23(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc12 ==
    \A message \in CheckedContractDesc12 :
        LET read == DecodeContractDesc12(EncodeContractDesc12(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg33 ==
    \A message \in CheckedMsSpdLegInfoLeg33 :
        LET read == DecodeMsSpdLegInfoLeg33(EncodeMsSpdLegInfoLeg33(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Thrl Board Lot In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripThrlBoardLotInMessage ==
    \A message \in CheckedThrlBoardLotInMessage :
        LET read == DecodeThrlBoardLotInMessage(EncodeThrlBoardLotInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc13 ==
    \A message \in CheckedContractDesc13 :
        LET read == DecodeContractDesc13(EncodeContractDesc13(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc14 ==
    \A message \in CheckedContractDesc14 :
        LET read == DecodeContractDesc14(EncodeContractDesc14(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg24 ==
    \A message \in CheckedMsSpdLegInfoLeg24 :
        LET read == DecodeMsSpdLegInfoLeg24(EncodeMsSpdLegInfoLeg24(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc15 ==
    \A message \in CheckedContractDesc15 :
        LET read == DecodeContractDesc15(EncodeContractDesc15(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg34 ==
    \A message \in CheckedMsSpdLegInfoLeg34 :
        LET read == DecodeMsSpdLegInfoLeg34(EncodeMsSpdLegInfoLeg34(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sp Order Cancel In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpOrderCancelInMessage ==
    \A message \in CheckedSpOrderCancelInMessage :
        LET read == DecodeSpOrderCancelInMessage(EncodeSpOrderCancelInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc16 ==
    \A message \in CheckedContractDesc16 :
        LET read == DecodeContractDesc16(EncodeContractDesc16(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc17 ==
    \A message \in CheckedContractDesc17 :
        LET read == DecodeContractDesc17(EncodeContractDesc17(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg25 ==
    \A message \in CheckedMsSpdLegInfoLeg25 :
        LET read == DecodeMsSpdLegInfoLeg25(EncodeMsSpdLegInfoLeg25(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc18 ==
    \A message \in CheckedContractDesc18 :
        LET read == DecodeContractDesc18(EncodeContractDesc18(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ms Spd Leg Info Leg 3 decodes back to what was encoded, and leaves nothing over *)
RoundTripMsSpdLegInfoLeg35 ==
    \A message \in CheckedMsSpdLegInfoLeg35 :
        LET read == DecodeMsSpdLegInfoLeg35(EncodeMsSpdLegInfoLeg35(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sp Order Mod In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpOrderModInMessage ==
    \A message \in CheckedSpOrderModInMessage :
        LET read == DecodeSpOrderModInMessage(EncodeSpOrderModInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc19 ==
    \A message \in CheckedContractDesc19 :
        LET read == DecodeContractDesc19(EncodeContractDesc19(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancelInMessage ==
    \A message \in CheckedTradeCancelInMessage :
        LET read == DecodeTradeCancelInMessage(EncodeTradeCancelInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Contract Desc decodes back to what was encoded, and leaves nothing over *)
RoundTripContractDesc20 ==
    \A message \in CheckedContractDesc20 :
        LET read == DecodeContractDesc20(EncodeContractDesc20(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Mod In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeModInMessage ==
    \A message \in CheckedTradeModInMessage :
        LET read == DecodeTradeModInMessage(EncodeTradeModInMessage(message))
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

(* Every Sign Off Trader In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSignOffTraderInMessage ==
    \A message \in CheckedSignOffTraderInMessage :
        LET read == DecodeSignOffTraderInMessage(EncodeSignOffTraderInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gr Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGrRequestMessage ==
    \A message \in CheckedGrRequestMessage :
        LET read == DecodeGrRequestMessage(EncodeGrRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Addr Unlock In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUserAddrUnlockInMessage ==
    \A message \in CheckedUserAddrUnlockInMessage :
        LET read == DecodeUserAddrUnlockInMessage(EncodeUserAddrUnlockInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Branch Limits 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripBranchLimits1 ==
    \A message \in CheckedBranchLimits1 :
        LET read == DecodeBranchLimits1(EncodeBranchLimits1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Branch Limits 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripBranchLimits2 ==
    \A message \in CheckedBranchLimits2 :
        LET read == DecodeBranchLimits2(EncodeBranchLimits2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Branch Ord Val Limit Update In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBranchOrdValLimitUpdateInMessage ==
    \A message \in CheckedBranchOrdValLimitUpdateInMessage :
        LET read == DecodeBranchOrdValLimitUpdateInMessage(EncodeBranchOrdValLimitUpdateInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Limits 1 decodes back to what was encoded, and leaves nothing over *)
RoundTripUserLimits1 ==
    \A message \in CheckedUserLimits1 :
        LET read == DecodeUserLimits1(EncodeUserLimits1(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Limits 2 decodes back to what was encoded, and leaves nothing over *)
RoundTripUserLimits2 ==
    \A message \in CheckedUserLimits2 :
        LET read == DecodeUserLimits2(EncodeUserLimits2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Ord Val Limit Update In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUserOrdValLimitUpdateInMessage ==
    \A message \in CheckedUserOrdValLimitUpdateInMessage :
        LET read == DecodeUserOrdValLimitUpdateInMessage(EncodeUserOrdValLimitUpdateInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Normal Ord Limit Update In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNormalOrdLimitUpdateInMessage ==
    \A message \in CheckedNormalOrdLimitUpdateInMessage :
        LET read == DecodeNormalOrdLimitUpdateInMessage(EncodeNormalOrdLimitUpdateInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Spread Ord Limit Update In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSpreadOrdLimitUpdateInMessage ==
    \A message \in CheckedSpreadOrdLimitUpdateInMessage :
        LET read == DecodeSpreadOrdLimitUpdateInMessage(EncodeSpreadOrdLimitUpdateInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Reset User Password In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResetUserPasswordInMessage ==
    \A message \in CheckedResetUserPasswordInMessage :
        LET read == DecodeResetUserPasswordInMessage(EncodeResetUserPasswordInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Col User Status Change In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripColUserStatusChangeInMessage ==
    \A message \in CheckedColUserStatusChangeInMessage :
        LET read == DecodeColUserStatusChangeInMessage(EncodeColUserStatusChangeInMessage(message))
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

(* Every Update Localdb In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUpdateLocaldbInMessage ==
    \A message \in CheckedUpdateLocaldbInMessage :
        LET read == DecodeUpdateLocaldbInMessage(EncodeUpdateLocaldbInMessage(message))
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

(* Every Client Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClientMessage ==
    \A message \in CheckedClientMessage :
        LET read == DecodeClientMessage(EncodeClientMessage(message))
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

(* Message Length is written from the bytes it frames *)
FramesClientMessage ==
    \A message \in CheckedClientMessage :
        LET bytes == EncodeClientMessage(message)
        IN  DecodeUIntBE(SubSeq(bytes, 39, 40)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
