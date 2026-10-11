-------------- MODULE Euronext_Optiq_OrderEntryGateway_v5_30 ---------------
(***************************************************************************)
(* Euronext Order Entry Gateway v5.30                                      *)
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
(* Note: Execution Instruction is a bit field set, checked as its 1 byte   *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Dark Execution Instruction is a bit field set, checked as its 1   *)
(* byte rather than bit by bit.                                            *)
(*                                                                         *)
(* Note: Mifid Indicators is a bit field set, checked as its 1 byte rather *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Trading Session is a bit field set, checked as its 1 byte rather  *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Open Close is a bit field set, checked as its 2 bytes rather than *)
(* bit by bit.                                                             *)
(*                                                                         *)
(* Note: Ack Qualifiers is a bit field set, checked as its 1 byte rather   *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Mifid Indicators Optional is a bit field set, checked as its 1    *)
(* byte rather than bit by bit.                                            *)
(*                                                                         *)
(* Note: Trade Qualifier is a bit field set, checked as its 1 byte rather  *)
(* than bit by bit.                                                        *)
(*                                                                         *)
(* Note: Ack Qualifiers Optional is a bit field set, checked as its 1 byte *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Execution Instruction Optional is a bit field set, checked as its *)
(* 1 byte rather than bit by bit.                                          *)
(*                                                                         *)
(* Note: Mmp Execution Type is a bit field set, checked as its 1 byte      *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Dark Execution Instruction Optional is a bit field set, checked   *)
(* as its 1 byte rather than bit by bit.                                   *)
(*                                                                         *)
(* Note: Target Counterparties is a bit field set, checked as its 2 bytes  *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Waiver Indicator is a bit field set, checked as its 1 byte rather *)
(* than bit by bit.                                                        *)
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
(* New Order Message Free Text Section Group: 18 bytes                     *)
(***************************************************************************)

NewOrderMessageFreeTextSectionGroup ==
    [ freeText : Sample(18) ]

EncodeNewOrderMessageFreeTextSectionGroup(message) ==
    message.freeText

DecodeNewOrderMessageFreeTextSectionGroup(bytes) ==
    LET freeText == ReadBytes(bytes, 18) IN IF ~freeText.ok THEN Fail ELSE
    Ok([ freeText |-> freeText.value ], freeText.rest)

ZeroNewOrderMessageFreeTextSectionGroup ==
    [ freeText |-> [i \in 1 .. 18 |-> 0] ]

(* New Order Message Free Text Section Group at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderMessageFreeTextSectionGroup ==
    { ZeroNewOrderMessageFreeTextSectionGroup }
        \cup { [ZeroNewOrderMessageFreeTextSectionGroup EXCEPT !.freeText = one] : one \in Sample(18) }

(* A run of New Order Message Free Text Section Group, written one after another *)
RECURSIVE EncodeNewOrderMessageFreeTextSectionGroupList(_)
EncodeNewOrderMessageFreeTextSectionGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewOrderMessageFreeTextSectionGroup(Head(messages)) \o EncodeNewOrderMessageFreeTextSectionGroupList(Tail(messages))

(* As many New Order Message Free Text Section Group as the field that counts them says *)
RECURSIVE ReadNewOrderMessageFreeTextSectionGroupList(_, _)
ReadNewOrderMessageFreeTextSectionGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewOrderMessageFreeTextSectionGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewOrderMessageFreeTextSectionGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Order Message Free Text Section Group of each kind, for the lists that carry them *)
OneNewOrderMessageFreeTextSectionGroup == { ZeroNewOrderMessageFreeTextSectionGroup }

(***************************************************************************)
(* Free Text Groups                                                        *)
(***************************************************************************)

FreeTextGroups ==
    [ blockLengthShort                    : Sample(1),
      newOrderMessageFreeTextSectionGroup : SampleLists(OneNewOrderMessageFreeTextSectionGroup) ]

EncodeFreeTextGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.newOrderMessageFreeTextSectionGroup), 1)
        \o EncodeNewOrderMessageFreeTextSectionGroupList(message.newOrderMessageFreeTextSectionGroup)

DecodeFreeTextGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET newOrderMessageFreeTextSectionGroup == ReadNewOrderMessageFreeTextSectionGroupList(numInGroup.rest, numInGroup.value) IN IF ~newOrderMessageFreeTextSectionGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                    |-> blockLengthShort.value,
         newOrderMessageFreeTextSectionGroup |-> newOrderMessageFreeTextSectionGroup.value ], newOrderMessageFreeTextSectionGroup.rest)

ZeroFreeTextGroups ==
    [ blockLengthShort                    |-> [i \in 1 .. 1 |-> 0],
      newOrderMessageFreeTextSectionGroup |-> << >> ]

(* Free Text Groups at zero, then each field in turn at the values it is checked at *)
CheckedFreeTextGroups ==
    { ZeroFreeTextGroups }
        \cup { [ZeroFreeTextGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroFreeTextGroups EXCEPT !.newOrderMessageFreeTextSectionGroup = one] : one \in SampleLists(OneNewOrderMessageFreeTextSectionGroup) }

(***************************************************************************)
(* Mifid Short Codes Group: 12 bytes                                       *)
(***************************************************************************)

MifidShortCodesGroup ==
    [ investmentDecisionWFirmShortCode : Sample(4),
      nonExecutingBrokerShortCode      : Sample(4),
      clientIdentificationShortcode    : Sample(4) ]

EncodeMifidShortCodesGroup(message) ==
    message.investmentDecisionWFirmShortCode
        \o message.nonExecutingBrokerShortCode
        \o message.clientIdentificationShortcode

DecodeMifidShortCodesGroup(bytes) ==
    LET investmentDecisionWFirmShortCode == ReadBytes(bytes, 4) IN IF ~investmentDecisionWFirmShortCode.ok THEN Fail ELSE
    LET nonExecutingBrokerShortCode == ReadBytes(investmentDecisionWFirmShortCode.rest, 4) IN IF ~nonExecutingBrokerShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(nonExecutingBrokerShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    Ok([ investmentDecisionWFirmShortCode |-> investmentDecisionWFirmShortCode.value,
         nonExecutingBrokerShortCode      |-> nonExecutingBrokerShortCode.value,
         clientIdentificationShortcode    |-> clientIdentificationShortcode.value ], clientIdentificationShortcode.rest)

ZeroMifidShortCodesGroup ==
    [ investmentDecisionWFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      nonExecutingBrokerShortCode      |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode    |-> [i \in 1 .. 4 |-> 0] ]

(* Mifid Short Codes Group at zero, then each field in turn at the values it is checked at *)
CheckedMifidShortCodesGroup ==
    { ZeroMifidShortCodesGroup }
        \cup { [ZeroMifidShortCodesGroup EXCEPT !.investmentDecisionWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroMifidShortCodesGroup EXCEPT !.nonExecutingBrokerShortCode = one] : one \in Sample(4) }
        \cup { [ZeroMifidShortCodesGroup EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }

(* A run of Mifid Short Codes Group, written one after another *)
RECURSIVE EncodeMifidShortCodesGroupList(_)
EncodeMifidShortCodesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMifidShortCodesGroup(Head(messages)) \o EncodeMifidShortCodesGroupList(Tail(messages))

(* As many Mifid Short Codes Group as the field that counts them says *)
RECURSIVE ReadMifidShortCodesGroupList(_, _)
ReadMifidShortCodesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMifidShortCodesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMifidShortCodesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mifid Short Codes Group of each kind, for the lists that carry them *)
OneMifidShortCodesGroup == { ZeroMifidShortCodesGroup }

(***************************************************************************)
(* Mifid Short Codes Groups                                                *)
(***************************************************************************)

MifidShortCodesGroups ==
    [ blockLengthShort     : Sample(1),
      mifidShortCodesGroup : SampleLists(OneMifidShortCodesGroup) ]

EncodeMifidShortCodesGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.mifidShortCodesGroup), 1)
        \o EncodeMifidShortCodesGroupList(message.mifidShortCodesGroup)

DecodeMifidShortCodesGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET mifidShortCodesGroup == ReadMifidShortCodesGroupList(numInGroup.rest, numInGroup.value) IN IF ~mifidShortCodesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort     |-> blockLengthShort.value,
         mifidShortCodesGroup |-> mifidShortCodesGroup.value ], mifidShortCodesGroup.rest)

ZeroMifidShortCodesGroups ==
    [ blockLengthShort     |-> [i \in 1 .. 1 |-> 0],
      mifidShortCodesGroup |-> << >> ]

(* Mifid Short Codes Groups at zero, then each field in turn at the values it is checked at *)
CheckedMifidShortCodesGroups ==
    { ZeroMifidShortCodesGroups }
        \cup { [ZeroMifidShortCodesGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroMifidShortCodesGroups EXCEPT !.mifidShortCodesGroup = one] : one \in SampleLists(OneMifidShortCodesGroup) }

(***************************************************************************)
(* Order Optional Fields Group: 50 bytes                                   *)
(***************************************************************************)

OrderOptionalFieldsGroup ==
    [ stopPx                   : Sample(8),
      undisclosedPrice         : Sample(8),
      disclosedQty             : Sample(8),
      minOrderQty              : Sample(8),
      quoteReqIdOptional       : Sample(8),
      orderExpirationTime      : Sample(4),
      orderExpirationDate      : Sample(2),
      pegOffset                : Sample(1),
      tradingSession           : Sample(1),
      undisclosedIcebergType   : Sample(1),
      stopTriggeredTimeInForce : Sample(1) ]

EncodeOrderOptionalFieldsGroup(message) ==
    message.stopPx
        \o message.undisclosedPrice
        \o message.disclosedQty
        \o message.minOrderQty
        \o message.quoteReqIdOptional
        \o message.orderExpirationTime
        \o message.orderExpirationDate
        \o message.pegOffset
        \o message.tradingSession
        \o message.undisclosedIcebergType
        \o message.stopTriggeredTimeInForce

DecodeOrderOptionalFieldsGroup(bytes) ==
    LET stopPx == ReadBytes(bytes, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET undisclosedPrice == ReadBytes(stopPx.rest, 8) IN IF ~undisclosedPrice.ok THEN Fail ELSE
    LET disclosedQty == ReadBytes(undisclosedPrice.rest, 8) IN IF ~disclosedQty.ok THEN Fail ELSE
    LET minOrderQty == ReadBytes(disclosedQty.rest, 8) IN IF ~minOrderQty.ok THEN Fail ELSE
    LET quoteReqIdOptional == ReadBytes(minOrderQty.rest, 8) IN IF ~quoteReqIdOptional.ok THEN Fail ELSE
    LET orderExpirationTime == ReadBytes(quoteReqIdOptional.rest, 4) IN IF ~orderExpirationTime.ok THEN Fail ELSE
    LET orderExpirationDate == ReadBytes(orderExpirationTime.rest, 2) IN IF ~orderExpirationDate.ok THEN Fail ELSE
    LET pegOffset == ReadBytes(orderExpirationDate.rest, 1) IN IF ~pegOffset.ok THEN Fail ELSE
    LET tradingSession == ReadBytes(pegOffset.rest, 1) IN IF ~tradingSession.ok THEN Fail ELSE
    LET undisclosedIcebergType == ReadBytes(tradingSession.rest, 1) IN IF ~undisclosedIcebergType.ok THEN Fail ELSE
    LET stopTriggeredTimeInForce == ReadBytes(undisclosedIcebergType.rest, 1) IN IF ~stopTriggeredTimeInForce.ok THEN Fail ELSE
    Ok([ stopPx                   |-> stopPx.value,
         undisclosedPrice         |-> undisclosedPrice.value,
         disclosedQty             |-> disclosedQty.value,
         minOrderQty              |-> minOrderQty.value,
         quoteReqIdOptional       |-> quoteReqIdOptional.value,
         orderExpirationTime      |-> orderExpirationTime.value,
         orderExpirationDate      |-> orderExpirationDate.value,
         pegOffset                |-> pegOffset.value,
         tradingSession           |-> tradingSession.value,
         undisclosedIcebergType   |-> undisclosedIcebergType.value,
         stopTriggeredTimeInForce |-> stopTriggeredTimeInForce.value ], stopTriggeredTimeInForce.rest)

ZeroOrderOptionalFieldsGroup ==
    [ stopPx                   |-> [i \in 1 .. 8 |-> 0],
      undisclosedPrice         |-> [i \in 1 .. 8 |-> 0],
      disclosedQty             |-> [i \in 1 .. 8 |-> 0],
      minOrderQty              |-> [i \in 1 .. 8 |-> 0],
      quoteReqIdOptional       |-> [i \in 1 .. 8 |-> 0],
      orderExpirationTime      |-> [i \in 1 .. 4 |-> 0],
      orderExpirationDate      |-> [i \in 1 .. 2 |-> 0],
      pegOffset                |-> [i \in 1 .. 1 |-> 0],
      tradingSession           |-> [i \in 1 .. 1 |-> 0],
      undisclosedIcebergType   |-> [i \in 1 .. 1 |-> 0],
      stopTriggeredTimeInForce |-> [i \in 1 .. 1 |-> 0] ]

(* Order Optional Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedOrderOptionalFieldsGroup ==
    { ZeroOrderOptionalFieldsGroup }
        \cup { [ZeroOrderOptionalFieldsGroup EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderOptionalFieldsGroup EXCEPT !.undisclosedPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderOptionalFieldsGroup EXCEPT !.disclosedQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderOptionalFieldsGroup EXCEPT !.minOrderQty = one] : one \in Sample(8) }
        \cup { [ZeroOrderOptionalFieldsGroup EXCEPT !.quoteReqIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderOptionalFieldsGroup EXCEPT !.orderExpirationTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderOptionalFieldsGroup EXCEPT !.orderExpirationDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderOptionalFieldsGroup EXCEPT !.pegOffset = one] : one \in Sample(1) }
        \cup { [ZeroOrderOptionalFieldsGroup EXCEPT !.tradingSession = one] : one \in Sample(1) }
        \cup { [ZeroOrderOptionalFieldsGroup EXCEPT !.undisclosedIcebergType = one] : one \in Sample(1) }
        \cup { [ZeroOrderOptionalFieldsGroup EXCEPT !.stopTriggeredTimeInForce = one] : one \in Sample(1) }

(* A run of Order Optional Fields Group, written one after another *)
RECURSIVE EncodeOrderOptionalFieldsGroupList(_)
EncodeOrderOptionalFieldsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderOptionalFieldsGroup(Head(messages)) \o EncodeOrderOptionalFieldsGroupList(Tail(messages))

(* As many Order Optional Fields Group as the field that counts them says *)
RECURSIVE ReadOrderOptionalFieldsGroupList(_, _)
ReadOrderOptionalFieldsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOrderOptionalFieldsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderOptionalFieldsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Optional Fields Group of each kind, for the lists that carry them *)
OneOrderOptionalFieldsGroup == { ZeroOrderOptionalFieldsGroup }

(***************************************************************************)
(* Order Optional Fields Groups                                            *)
(***************************************************************************)

OrderOptionalFieldsGroups ==
    [ blockLengthShort         : Sample(1),
      orderOptionalFieldsGroup : SampleLists(OneOrderOptionalFieldsGroup) ]

EncodeOrderOptionalFieldsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.orderOptionalFieldsGroup), 1)
        \o EncodeOrderOptionalFieldsGroupList(message.orderOptionalFieldsGroup)

DecodeOrderOptionalFieldsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET orderOptionalFieldsGroup == ReadOrderOptionalFieldsGroupList(numInGroup.rest, numInGroup.value) IN IF ~orderOptionalFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort         |-> blockLengthShort.value,
         orderOptionalFieldsGroup |-> orderOptionalFieldsGroup.value ], orderOptionalFieldsGroup.rest)

ZeroOrderOptionalFieldsGroups ==
    [ blockLengthShort         |-> [i \in 1 .. 1 |-> 0],
      orderOptionalFieldsGroup |-> << >> ]

(* Order Optional Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedOrderOptionalFieldsGroups ==
    { ZeroOrderOptionalFieldsGroups }
        \cup { [ZeroOrderOptionalFieldsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroOrderOptionalFieldsGroups EXCEPT !.orderOptionalFieldsGroup = one] : one \in SampleLists(OneOrderOptionalFieldsGroup) }

(***************************************************************************)
(* Order Clearing Fields Group: 35 bytes                                   *)
(***************************************************************************)

OrderClearingFieldsGroup ==
    [ clearingFirmId       : Sample(8),
      clientId             : Sample(8),
      accountNumber        : Sample(12),
      technicalOrigin      : Sample(1),
      openClose            : Sample(2),
      clearingInstruction  : Sample(2),
      accountTypeCross     : Sample(1),
      tradingCapacityCross : Sample(1) ]

EncodeOrderClearingFieldsGroup(message) ==
    message.clearingFirmId
        \o message.clientId
        \o message.accountNumber
        \o message.technicalOrigin
        \o message.openClose
        \o message.clearingInstruction
        \o message.accountTypeCross
        \o message.tradingCapacityCross

DecodeOrderClearingFieldsGroup(bytes) ==
    LET clearingFirmId == ReadBytes(bytes, 8) IN IF ~clearingFirmId.ok THEN Fail ELSE
    LET clientId == ReadBytes(clearingFirmId.rest, 8) IN IF ~clientId.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(clientId.rest, 12) IN IF ~accountNumber.ok THEN Fail ELSE
    LET technicalOrigin == ReadBytes(accountNumber.rest, 1) IN IF ~technicalOrigin.ok THEN Fail ELSE
    LET openClose == ReadBytes(technicalOrigin.rest, 2) IN IF ~openClose.ok THEN Fail ELSE
    LET clearingInstruction == ReadBytes(openClose.rest, 2) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountTypeCross == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountTypeCross.ok THEN Fail ELSE
    LET tradingCapacityCross == ReadBytes(accountTypeCross.rest, 1) IN IF ~tradingCapacityCross.ok THEN Fail ELSE
    Ok([ clearingFirmId       |-> clearingFirmId.value,
         clientId             |-> clientId.value,
         accountNumber        |-> accountNumber.value,
         technicalOrigin      |-> technicalOrigin.value,
         openClose            |-> openClose.value,
         clearingInstruction  |-> clearingInstruction.value,
         accountTypeCross     |-> accountTypeCross.value,
         tradingCapacityCross |-> tradingCapacityCross.value ], tradingCapacityCross.rest)

ZeroOrderClearingFieldsGroup ==
    [ clearingFirmId       |-> [i \in 1 .. 8 |-> 0],
      clientId             |-> [i \in 1 .. 8 |-> 0],
      accountNumber        |-> [i \in 1 .. 12 |-> 0],
      technicalOrigin      |-> [i \in 1 .. 1 |-> 0],
      openClose            |-> [i \in 1 .. 2 |-> 0],
      clearingInstruction  |-> [i \in 1 .. 2 |-> 0],
      accountTypeCross     |-> [i \in 1 .. 1 |-> 0],
      tradingCapacityCross |-> [i \in 1 .. 1 |-> 0] ]

(* Order Clearing Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedOrderClearingFieldsGroup ==
    { ZeroOrderClearingFieldsGroup }
        \cup { [ZeroOrderClearingFieldsGroup EXCEPT !.clearingFirmId = one] : one \in Sample(8) }
        \cup { [ZeroOrderClearingFieldsGroup EXCEPT !.clientId = one] : one \in Sample(8) }
        \cup { [ZeroOrderClearingFieldsGroup EXCEPT !.accountNumber = one] : one \in Sample(12) }
        \cup { [ZeroOrderClearingFieldsGroup EXCEPT !.technicalOrigin = one] : one \in Sample(1) }
        \cup { [ZeroOrderClearingFieldsGroup EXCEPT !.openClose = one] : one \in Sample(2) }
        \cup { [ZeroOrderClearingFieldsGroup EXCEPT !.clearingInstruction = one] : one \in Sample(2) }
        \cup { [ZeroOrderClearingFieldsGroup EXCEPT !.accountTypeCross = one] : one \in Sample(1) }
        \cup { [ZeroOrderClearingFieldsGroup EXCEPT !.tradingCapacityCross = one] : one \in Sample(1) }

(* A run of Order Clearing Fields Group, written one after another *)
RECURSIVE EncodeOrderClearingFieldsGroupList(_)
EncodeOrderClearingFieldsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeOrderClearingFieldsGroup(Head(messages)) \o EncodeOrderClearingFieldsGroupList(Tail(messages))

(* As many Order Clearing Fields Group as the field that counts them says *)
RECURSIVE ReadOrderClearingFieldsGroupList(_, _)
ReadOrderClearingFieldsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeOrderClearingFieldsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadOrderClearingFieldsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Order Clearing Fields Group of each kind, for the lists that carry them *)
OneOrderClearingFieldsGroup == { ZeroOrderClearingFieldsGroup }

(***************************************************************************)
(* Order Clearing Fields Groups                                            *)
(***************************************************************************)

OrderClearingFieldsGroups ==
    [ blockLengthShort         : Sample(1),
      orderClearingFieldsGroup : SampleLists(OneOrderClearingFieldsGroup) ]

EncodeOrderClearingFieldsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.orderClearingFieldsGroup), 1)
        \o EncodeOrderClearingFieldsGroupList(message.orderClearingFieldsGroup)

DecodeOrderClearingFieldsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET orderClearingFieldsGroup == ReadOrderClearingFieldsGroupList(numInGroup.rest, numInGroup.value) IN IF ~orderClearingFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort         |-> blockLengthShort.value,
         orderClearingFieldsGroup |-> orderClearingFieldsGroup.value ], orderClearingFieldsGroup.rest)

ZeroOrderClearingFieldsGroups ==
    [ blockLengthShort         |-> [i \in 1 .. 1 |-> 0],
      orderClearingFieldsGroup |-> << >> ]

(* Order Clearing Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedOrderClearingFieldsGroups ==
    { ZeroOrderClearingFieldsGroups }
        \cup { [ZeroOrderClearingFieldsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroOrderClearingFieldsGroups EXCEPT !.orderClearingFieldsGroup = one] : one \in SampleLists(OneOrderClearingFieldsGroup) }

(***************************************************************************)
(* Not Used Groups: 2 bytes                                                *)
(***************************************************************************)

NotUsedGroups ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeNotUsedGroups(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeNotUsedGroups(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroNotUsedGroups ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedNotUsedGroups ==
    { ZeroNotUsedGroups }
        \cup { [ZeroNotUsedGroups EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroNotUsedGroups EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* Other Not Used Groups: 2 bytes                                          *)
(***************************************************************************)

OtherNotUsedGroups ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeOtherNotUsedGroups(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeOtherNotUsedGroups(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroOtherNotUsedGroups ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Other Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedOtherNotUsedGroups ==
    { ZeroOtherNotUsedGroups }
        \cup { [ZeroOtherNotUsedGroups EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroOtherNotUsedGroups EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* Additional Infos Group: 16 bytes                                        *)
(***************************************************************************)

AdditionalInfosGroup ==
    [ longClientId : Sample(16) ]

EncodeAdditionalInfosGroup(message) ==
    message.longClientId

DecodeAdditionalInfosGroup(bytes) ==
    LET longClientId == ReadBytes(bytes, 16) IN IF ~longClientId.ok THEN Fail ELSE
    Ok([ longClientId |-> longClientId.value ], longClientId.rest)

ZeroAdditionalInfosGroup ==
    [ longClientId |-> [i \in 1 .. 16 |-> 0] ]

(* Additional Infos Group at zero, then each field in turn at the values it is checked at *)
CheckedAdditionalInfosGroup ==
    { ZeroAdditionalInfosGroup }
        \cup { [ZeroAdditionalInfosGroup EXCEPT !.longClientId = one] : one \in Sample(16) }

(* A run of Additional Infos Group, written one after another *)
RECURSIVE EncodeAdditionalInfosGroupList(_)
EncodeAdditionalInfosGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAdditionalInfosGroup(Head(messages)) \o EncodeAdditionalInfosGroupList(Tail(messages))

(* As many Additional Infos Group as the field that counts them says *)
RECURSIVE ReadAdditionalInfosGroupList(_, _)
ReadAdditionalInfosGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAdditionalInfosGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAdditionalInfosGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Additional Infos Group of each kind, for the lists that carry them *)
OneAdditionalInfosGroup == { ZeroAdditionalInfosGroup }

(***************************************************************************)
(* Additional Infos Groups                                                 *)
(***************************************************************************)

AdditionalInfosGroups ==
    [ blockLengthShort     : Sample(1),
      additionalInfosGroup : SampleLists(OneAdditionalInfosGroup) ]

EncodeAdditionalInfosGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.additionalInfosGroup), 1)
        \o EncodeAdditionalInfosGroupList(message.additionalInfosGroup)

DecodeAdditionalInfosGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET additionalInfosGroup == ReadAdditionalInfosGroupList(numInGroup.rest, numInGroup.value) IN IF ~additionalInfosGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort     |-> blockLengthShort.value,
         additionalInfosGroup |-> additionalInfosGroup.value ], additionalInfosGroup.rest)

ZeroAdditionalInfosGroups ==
    [ blockLengthShort     |-> [i \in 1 .. 1 |-> 0],
      additionalInfosGroup |-> << >> ]

(* Additional Infos Groups at zero, then each field in turn at the values it is checked at *)
CheckedAdditionalInfosGroups ==
    { ZeroAdditionalInfosGroups }
        \cup { [ZeroAdditionalInfosGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroAdditionalInfosGroups EXCEPT !.additionalInfosGroup = one] : one \in SampleLists(OneAdditionalInfosGroup) }

(***************************************************************************)
(* New Order Message                                                       *)
(***************************************************************************)

NewOrderMessage ==
    [ clMsgSeqNum                  : Sample(4),
      firmId                       : Sample(8),
      sendingTime                  : Sample(8),
      clientOrderId                : Sample(8),
      symbolIndex                  : Sample(4),
      emm                          : Sample(1),
      side                         : Sample(1),
      orderType                    : Sample(1),
      timeInForce                  : Sample(1),
      orderPxOptional              : Sample(8),
      orderQty                     : Sample(8),
      executionWithinFirmShortCode : Sample(4),
      tradingCapacity              : Sample(1),
      accountType                  : Sample(1),
      lpRoleOptional               : Sample(1),
      executionInstruction         : Sample(1),
      darkExecutionInstruction     : Sample(1),
      mifidIndicators              : Sample(1),
      stpid                        : Sample(2),
      nonExecutingClientId         : Sample(2),
      ioiIdOptional                : Sample(8),
      freeTextGroups               : FreeTextGroups,
      mifidShortCodesGroups        : MifidShortCodesGroups,
      orderOptionalFieldsGroups    : OrderOptionalFieldsGroups,
      orderClearingFieldsGroups    : OrderClearingFieldsGroups,
      notUsedGroups                : NotUsedGroups,
      otherNotUsedGroups           : OtherNotUsedGroups,
      additionalInfosGroups        : AdditionalInfosGroups ]

EncodeNewOrderMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.clientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.side
        \o message.orderType
        \o message.timeInForce
        \o message.orderPxOptional
        \o message.orderQty
        \o message.executionWithinFirmShortCode
        \o message.tradingCapacity
        \o message.accountType
        \o message.lpRoleOptional
        \o message.executionInstruction
        \o message.darkExecutionInstruction
        \o message.mifidIndicators
        \o message.stpid
        \o message.nonExecutingClientId
        \o message.ioiIdOptional
        \o EncodeFreeTextGroups(message.freeTextGroups)
        \o EncodeMifidShortCodesGroups(message.mifidShortCodesGroups)
        \o EncodeOrderOptionalFieldsGroups(message.orderOptionalFieldsGroups)
        \o EncodeOrderClearingFieldsGroups(message.orderClearingFieldsGroups)
        \o EncodeNotUsedGroups(message.notUsedGroups)
        \o EncodeOtherNotUsedGroups(message.otherNotUsedGroups)
        \o EncodeAdditionalInfosGroups(message.additionalInfosGroups)

DecodeNewOrderMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(sendingTime.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET side == ReadBytes(emm.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderType == ReadBytes(side.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(orderType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET orderPxOptional == ReadBytes(timeInForce.rest, 8) IN IF ~orderPxOptional.ok THEN Fail ELSE
    LET orderQty == ReadBytes(orderPxOptional.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(orderQty.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(executionWithinFirmShortCode.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET accountType == ReadBytes(tradingCapacity.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET lpRoleOptional == ReadBytes(accountType.rest, 1) IN IF ~lpRoleOptional.ok THEN Fail ELSE
    LET executionInstruction == ReadBytes(lpRoleOptional.rest, 1) IN IF ~executionInstruction.ok THEN Fail ELSE
    LET darkExecutionInstruction == ReadBytes(executionInstruction.rest, 1) IN IF ~darkExecutionInstruction.ok THEN Fail ELSE
    LET mifidIndicators == ReadBytes(darkExecutionInstruction.rest, 1) IN IF ~mifidIndicators.ok THEN Fail ELSE
    LET stpid == ReadBytes(mifidIndicators.rest, 2) IN IF ~stpid.ok THEN Fail ELSE
    LET nonExecutingClientId == ReadBytes(stpid.rest, 2) IN IF ~nonExecutingClientId.ok THEN Fail ELSE
    LET ioiIdOptional == ReadBytes(nonExecutingClientId.rest, 8) IN IF ~ioiIdOptional.ok THEN Fail ELSE
    LET freeTextGroups == DecodeFreeTextGroups(ioiIdOptional.rest) IN IF ~freeTextGroups.ok THEN Fail ELSE
    LET mifidShortCodesGroups == DecodeMifidShortCodesGroups(freeTextGroups.rest) IN IF ~mifidShortCodesGroups.ok THEN Fail ELSE
    LET orderOptionalFieldsGroups == DecodeOrderOptionalFieldsGroups(mifidShortCodesGroups.rest) IN IF ~orderOptionalFieldsGroups.ok THEN Fail ELSE
    LET orderClearingFieldsGroups == DecodeOrderClearingFieldsGroups(orderOptionalFieldsGroups.rest) IN IF ~orderClearingFieldsGroups.ok THEN Fail ELSE
    LET notUsedGroups == DecodeNotUsedGroups(orderClearingFieldsGroups.rest) IN IF ~notUsedGroups.ok THEN Fail ELSE
    LET otherNotUsedGroups == DecodeOtherNotUsedGroups(notUsedGroups.rest) IN IF ~otherNotUsedGroups.ok THEN Fail ELSE
    LET additionalInfosGroups == DecodeAdditionalInfosGroups(otherNotUsedGroups.rest) IN IF ~additionalInfosGroups.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                  |-> clMsgSeqNum.value,
         firmId                       |-> firmId.value,
         sendingTime                  |-> sendingTime.value,
         clientOrderId                |-> clientOrderId.value,
         symbolIndex                  |-> symbolIndex.value,
         emm                          |-> emm.value,
         side                         |-> side.value,
         orderType                    |-> orderType.value,
         timeInForce                  |-> timeInForce.value,
         orderPxOptional              |-> orderPxOptional.value,
         orderQty                     |-> orderQty.value,
         executionWithinFirmShortCode |-> executionWithinFirmShortCode.value,
         tradingCapacity              |-> tradingCapacity.value,
         accountType                  |-> accountType.value,
         lpRoleOptional               |-> lpRoleOptional.value,
         executionInstruction         |-> executionInstruction.value,
         darkExecutionInstruction     |-> darkExecutionInstruction.value,
         mifidIndicators              |-> mifidIndicators.value,
         stpid                        |-> stpid.value,
         nonExecutingClientId         |-> nonExecutingClientId.value,
         ioiIdOptional                |-> ioiIdOptional.value,
         freeTextGroups               |-> freeTextGroups.value,
         mifidShortCodesGroups        |-> mifidShortCodesGroups.value,
         orderOptionalFieldsGroups    |-> orderOptionalFieldsGroups.value,
         orderClearingFieldsGroups    |-> orderClearingFieldsGroups.value,
         notUsedGroups                |-> notUsedGroups.value,
         otherNotUsedGroups           |-> otherNotUsedGroups.value,
         additionalInfosGroups        |-> additionalInfosGroups.value ], additionalInfosGroups.rest)

ZeroNewOrderMessage ==
    [ clMsgSeqNum                  |-> [i \in 1 .. 4 |-> 0],
      firmId                       |-> [i \in 1 .. 8 |-> 0],
      sendingTime                  |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                  |-> [i \in 1 .. 4 |-> 0],
      emm                          |-> [i \in 1 .. 1 |-> 0],
      side                         |-> [i \in 1 .. 1 |-> 0],
      orderType                    |-> [i \in 1 .. 1 |-> 0],
      timeInForce                  |-> [i \in 1 .. 1 |-> 0],
      orderPxOptional              |-> [i \in 1 .. 8 |-> 0],
      orderQty                     |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      tradingCapacity              |-> [i \in 1 .. 1 |-> 0],
      accountType                  |-> [i \in 1 .. 1 |-> 0],
      lpRoleOptional               |-> [i \in 1 .. 1 |-> 0],
      executionInstruction         |-> [i \in 1 .. 1 |-> 0],
      darkExecutionInstruction     |-> [i \in 1 .. 1 |-> 0],
      mifidIndicators              |-> [i \in 1 .. 1 |-> 0],
      stpid                        |-> [i \in 1 .. 2 |-> 0],
      nonExecutingClientId         |-> [i \in 1 .. 2 |-> 0],
      ioiIdOptional                |-> [i \in 1 .. 8 |-> 0],
      freeTextGroups               |-> ZeroFreeTextGroups,
      mifidShortCodesGroups        |-> ZeroMifidShortCodesGroups,
      orderOptionalFieldsGroups    |-> ZeroOrderOptionalFieldsGroups,
      orderClearingFieldsGroups    |-> ZeroOrderClearingFieldsGroups,
      notUsedGroups                |-> ZeroNotUsedGroups,
      otherNotUsedGroups           |-> ZeroOtherNotUsedGroups,
      additionalInfosGroups        |-> ZeroAdditionalInfosGroups ]

(* New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderMessage ==
    { ZeroNewOrderMessage }
        \cup { [ZeroNewOrderMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderPxOptional = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.lpRoleOptional = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.executionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.darkExecutionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.mifidIndicators = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.stpid = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderMessage EXCEPT !.nonExecutingClientId = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderMessage EXCEPT !.ioiIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.freeTextGroups = one] : one \in CheckedFreeTextGroups }
        \cup { [ZeroNewOrderMessage EXCEPT !.mifidShortCodesGroups = one] : one \in CheckedMifidShortCodesGroups }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderOptionalFieldsGroups = one] : one \in CheckedOrderOptionalFieldsGroups }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderClearingFieldsGroups = one] : one \in CheckedOrderClearingFieldsGroups }
        \cup { [ZeroNewOrderMessage EXCEPT !.notUsedGroups = one] : one \in CheckedNotUsedGroups }
        \cup { [ZeroNewOrderMessage EXCEPT !.otherNotUsedGroups = one] : one \in CheckedOtherNotUsedGroups }
        \cup { [ZeroNewOrderMessage EXCEPT !.additionalInfosGroups = one] : one \in CheckedAdditionalInfosGroups }

(***************************************************************************)
(* Mifid Fields Group: 9 bytes                                             *)
(***************************************************************************)

MifidFieldsGroup ==
    [ executionWithinFirmShortCodeOptional : Sample(4),
      clientIdentificationShortcode        : Sample(4),
      mifidIndicatorsOptional              : Sample(1) ]

EncodeMifidFieldsGroup(message) ==
    message.executionWithinFirmShortCodeOptional
        \o message.clientIdentificationShortcode
        \o message.mifidIndicatorsOptional

DecodeMifidFieldsGroup(bytes) ==
    LET executionWithinFirmShortCodeOptional == ReadBytes(bytes, 4) IN IF ~executionWithinFirmShortCodeOptional.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCodeOptional.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET mifidIndicatorsOptional == ReadBytes(clientIdentificationShortcode.rest, 1) IN IF ~mifidIndicatorsOptional.ok THEN Fail ELSE
    Ok([ executionWithinFirmShortCodeOptional |-> executionWithinFirmShortCodeOptional.value,
         clientIdentificationShortcode        |-> clientIdentificationShortcode.value,
         mifidIndicatorsOptional              |-> mifidIndicatorsOptional.value ], mifidIndicatorsOptional.rest)

ZeroMifidFieldsGroup ==
    [ executionWithinFirmShortCodeOptional |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode        |-> [i \in 1 .. 4 |-> 0],
      mifidIndicatorsOptional              |-> [i \in 1 .. 1 |-> 0] ]

(* Mifid Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedMifidFieldsGroup ==
    { ZeroMifidFieldsGroup }
        \cup { [ZeroMifidFieldsGroup EXCEPT !.executionWithinFirmShortCodeOptional = one] : one \in Sample(4) }
        \cup { [ZeroMifidFieldsGroup EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroMifidFieldsGroup EXCEPT !.mifidIndicatorsOptional = one] : one \in Sample(1) }

(* A run of Mifid Fields Group, written one after another *)
RECURSIVE EncodeMifidFieldsGroupList(_)
EncodeMifidFieldsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMifidFieldsGroup(Head(messages)) \o EncodeMifidFieldsGroupList(Tail(messages))

(* As many Mifid Fields Group as the field that counts them says *)
RECURSIVE ReadMifidFieldsGroupList(_, _)
ReadMifidFieldsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMifidFieldsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMifidFieldsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mifid Fields Group of each kind, for the lists that carry them *)
OneMifidFieldsGroup == { ZeroMifidFieldsGroup }

(***************************************************************************)
(* Mifid Fields Groups                                                     *)
(***************************************************************************)

MifidFieldsGroups ==
    [ blockLengthShort : Sample(1),
      mifidFieldsGroup : SampleLists(OneMifidFieldsGroup) ]

EncodeMifidFieldsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.mifidFieldsGroup), 1)
        \o EncodeMifidFieldsGroupList(message.mifidFieldsGroup)

DecodeMifidFieldsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET mifidFieldsGroup == ReadMifidFieldsGroupList(numInGroup.rest, numInGroup.value) IN IF ~mifidFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         mifidFieldsGroup |-> mifidFieldsGroup.value ], mifidFieldsGroup.rest)

ZeroMifidFieldsGroups ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      mifidFieldsGroup |-> << >> ]

(* Mifid Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedMifidFieldsGroups ==
    { ZeroMifidFieldsGroups }
        \cup { [ZeroMifidFieldsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroMifidFieldsGroups EXCEPT !.mifidFieldsGroup = one] : one \in SampleLists(OneMifidFieldsGroup) }

(***************************************************************************)
(* Ack Message                                                             *)
(***************************************************************************)

AckMessage ==
    [ msgSeqNum              : Sample(4),
      firmId                 : Sample(8),
      sendingTimeOptional    : Sample(8),
      oegInFromMember        : Sample(8),
      oegOutTimeToMe         : Sample(8),
      bookIn                 : Sample(8),
      bookOutTimeOptional    : Sample(8),
      oegInFromMeOptional    : Sample(8),
      oegOutToMemberOptional : Sample(8),
      clientOrderIdOptional  : Sample(8),
      origClientOrderId      : Sample(8),
      symbolIndex            : Sample(4),
      emm                    : Sample(1),
      sideOptional           : Sample(1),
      ackType                : Sample(1),
      ackPhase               : Sample(1),
      orderIdOptional        : Sample(8),
      orderPriority          : Sample(8),
      orderPxOptional        : Sample(8),
      orderQtyOptional       : Sample(8),
      ackQualifiers          : Sample(1),
      mifidFieldsGroups      : MifidFieldsGroups ]

EncodeAckMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.sendingTimeOptional
        \o message.oegInFromMember
        \o message.oegOutTimeToMe
        \o message.bookIn
        \o message.bookOutTimeOptional
        \o message.oegInFromMeOptional
        \o message.oegOutToMemberOptional
        \o message.clientOrderIdOptional
        \o message.origClientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.sideOptional
        \o message.ackType
        \o message.ackPhase
        \o message.orderIdOptional
        \o message.orderPriority
        \o message.orderPxOptional
        \o message.orderQtyOptional
        \o message.ackQualifiers
        \o EncodeMifidFieldsGroups(message.mifidFieldsGroups)

DecodeAckMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTimeOptional == ReadBytes(firmId.rest, 8) IN IF ~sendingTimeOptional.ok THEN Fail ELSE
    LET oegInFromMember == ReadBytes(sendingTimeOptional.rest, 8) IN IF ~oegInFromMember.ok THEN Fail ELSE
    LET oegOutTimeToMe == ReadBytes(oegInFromMember.rest, 8) IN IF ~oegOutTimeToMe.ok THEN Fail ELSE
    LET bookIn == ReadBytes(oegOutTimeToMe.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET oegInFromMeOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~oegInFromMeOptional.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(oegInFromMeOptional.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET clientOrderIdOptional == ReadBytes(oegOutToMemberOptional.rest, 8) IN IF ~clientOrderIdOptional.ok THEN Fail ELSE
    LET origClientOrderId == ReadBytes(clientOrderIdOptional.rest, 8) IN IF ~origClientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(origClientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(emm.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET ackType == ReadBytes(sideOptional.rest, 1) IN IF ~ackType.ok THEN Fail ELSE
    LET ackPhase == ReadBytes(ackType.rest, 1) IN IF ~ackPhase.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(ackPhase.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET orderPriority == ReadBytes(orderIdOptional.rest, 8) IN IF ~orderPriority.ok THEN Fail ELSE
    LET orderPxOptional == ReadBytes(orderPriority.rest, 8) IN IF ~orderPxOptional.ok THEN Fail ELSE
    LET orderQtyOptional == ReadBytes(orderPxOptional.rest, 8) IN IF ~orderQtyOptional.ok THEN Fail ELSE
    LET ackQualifiers == ReadBytes(orderQtyOptional.rest, 1) IN IF ~ackQualifiers.ok THEN Fail ELSE
    LET mifidFieldsGroups == DecodeMifidFieldsGroups(ackQualifiers.rest) IN IF ~mifidFieldsGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum              |-> msgSeqNum.value,
         firmId                 |-> firmId.value,
         sendingTimeOptional    |-> sendingTimeOptional.value,
         oegInFromMember        |-> oegInFromMember.value,
         oegOutTimeToMe         |-> oegOutTimeToMe.value,
         bookIn                 |-> bookIn.value,
         bookOutTimeOptional    |-> bookOutTimeOptional.value,
         oegInFromMeOptional    |-> oegInFromMeOptional.value,
         oegOutToMemberOptional |-> oegOutToMemberOptional.value,
         clientOrderIdOptional  |-> clientOrderIdOptional.value,
         origClientOrderId      |-> origClientOrderId.value,
         symbolIndex            |-> symbolIndex.value,
         emm                    |-> emm.value,
         sideOptional           |-> sideOptional.value,
         ackType                |-> ackType.value,
         ackPhase               |-> ackPhase.value,
         orderIdOptional        |-> orderIdOptional.value,
         orderPriority          |-> orderPriority.value,
         orderPxOptional        |-> orderPxOptional.value,
         orderQtyOptional       |-> orderQtyOptional.value,
         ackQualifiers          |-> ackQualifiers.value,
         mifidFieldsGroups      |-> mifidFieldsGroups.value ], mifidFieldsGroups.rest)

ZeroAckMessage ==
    [ msgSeqNum              |-> [i \in 1 .. 4 |-> 0],
      firmId                 |-> [i \in 1 .. 8 |-> 0],
      sendingTimeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegInFromMember        |-> [i \in 1 .. 8 |-> 0],
      oegOutTimeToMe         |-> [i \in 1 .. 8 |-> 0],
      bookIn                 |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegInFromMeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegOutToMemberOptional |-> [i \in 1 .. 8 |-> 0],
      clientOrderIdOptional  |-> [i \in 1 .. 8 |-> 0],
      origClientOrderId      |-> [i \in 1 .. 8 |-> 0],
      symbolIndex            |-> [i \in 1 .. 4 |-> 0],
      emm                    |-> [i \in 1 .. 1 |-> 0],
      sideOptional           |-> [i \in 1 .. 1 |-> 0],
      ackType                |-> [i \in 1 .. 1 |-> 0],
      ackPhase               |-> [i \in 1 .. 1 |-> 0],
      orderIdOptional        |-> [i \in 1 .. 8 |-> 0],
      orderPriority          |-> [i \in 1 .. 8 |-> 0],
      orderPxOptional        |-> [i \in 1 .. 8 |-> 0],
      orderQtyOptional       |-> [i \in 1 .. 8 |-> 0],
      ackQualifiers          |-> [i \in 1 .. 1 |-> 0],
      mifidFieldsGroups      |-> ZeroMifidFieldsGroups ]

(* Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedAckMessage ==
    { ZeroAckMessage }
        \cup { [ZeroAckMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroAckMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroAckMessage EXCEPT !.sendingTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroAckMessage EXCEPT !.oegInFromMember = one] : one \in Sample(8) }
        \cup { [ZeroAckMessage EXCEPT !.oegOutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroAckMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroAckMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroAckMessage EXCEPT !.oegInFromMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroAckMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroAckMessage EXCEPT !.clientOrderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroAckMessage EXCEPT !.origClientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroAckMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroAckMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroAckMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroAckMessage EXCEPT !.ackType = one] : one \in Sample(1) }
        \cup { [ZeroAckMessage EXCEPT !.ackPhase = one] : one \in Sample(1) }
        \cup { [ZeroAckMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroAckMessage EXCEPT !.orderPriority = one] : one \in Sample(8) }
        \cup { [ZeroAckMessage EXCEPT !.orderPxOptional = one] : one \in Sample(8) }
        \cup { [ZeroAckMessage EXCEPT !.orderQtyOptional = one] : one \in Sample(8) }
        \cup { [ZeroAckMessage EXCEPT !.ackQualifiers = one] : one \in Sample(1) }
        \cup { [ZeroAckMessage EXCEPT !.mifidFieldsGroups = one] : one \in CheckedMifidFieldsGroups }

(***************************************************************************)
(* Fill Optional Field Group: 32 bytes                                     *)
(***************************************************************************)

FillOptionalFieldGroup ==
    [ counterpartFirmId      : Sample(8),
      otherLegLastPx         : Sample(8),
      packageId              : Sample(12),
      underlyingInstrumentId : Sample(4) ]

EncodeFillOptionalFieldGroup(message) ==
    message.counterpartFirmId
        \o message.otherLegLastPx
        \o message.packageId
        \o message.underlyingInstrumentId

DecodeFillOptionalFieldGroup(bytes) ==
    LET counterpartFirmId == ReadBytes(bytes, 8) IN IF ~counterpartFirmId.ok THEN Fail ELSE
    LET otherLegLastPx == ReadBytes(counterpartFirmId.rest, 8) IN IF ~otherLegLastPx.ok THEN Fail ELSE
    LET packageId == ReadBytes(otherLegLastPx.rest, 12) IN IF ~packageId.ok THEN Fail ELSE
    LET underlyingInstrumentId == ReadBytes(packageId.rest, 4) IN IF ~underlyingInstrumentId.ok THEN Fail ELSE
    Ok([ counterpartFirmId      |-> counterpartFirmId.value,
         otherLegLastPx         |-> otherLegLastPx.value,
         packageId              |-> packageId.value,
         underlyingInstrumentId |-> underlyingInstrumentId.value ], underlyingInstrumentId.rest)

ZeroFillOptionalFieldGroup ==
    [ counterpartFirmId      |-> [i \in 1 .. 8 |-> 0],
      otherLegLastPx         |-> [i \in 1 .. 8 |-> 0],
      packageId              |-> [i \in 1 .. 12 |-> 0],
      underlyingInstrumentId |-> [i \in 1 .. 4 |-> 0] ]

(* Fill Optional Field Group at zero, then each field in turn at the values it is checked at *)
CheckedFillOptionalFieldGroup ==
    { ZeroFillOptionalFieldGroup }
        \cup { [ZeroFillOptionalFieldGroup EXCEPT !.counterpartFirmId = one] : one \in Sample(8) }
        \cup { [ZeroFillOptionalFieldGroup EXCEPT !.otherLegLastPx = one] : one \in Sample(8) }
        \cup { [ZeroFillOptionalFieldGroup EXCEPT !.packageId = one] : one \in Sample(12) }
        \cup { [ZeroFillOptionalFieldGroup EXCEPT !.underlyingInstrumentId = one] : one \in Sample(4) }

(* A run of Fill Optional Field Group, written one after another *)
RECURSIVE EncodeFillOptionalFieldGroupList(_)
EncodeFillOptionalFieldGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFillOptionalFieldGroup(Head(messages)) \o EncodeFillOptionalFieldGroupList(Tail(messages))

(* As many Fill Optional Field Group as the field that counts them says *)
RECURSIVE ReadFillOptionalFieldGroupList(_, _)
ReadFillOptionalFieldGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFillOptionalFieldGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFillOptionalFieldGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Fill Optional Field Group of each kind, for the lists that carry them *)
OneFillOptionalFieldGroup == { ZeroFillOptionalFieldGroup }

(***************************************************************************)
(* Fill Optional Field Groups                                              *)
(***************************************************************************)

FillOptionalFieldGroups ==
    [ blockLengthShort       : Sample(1),
      fillOptionalFieldGroup : SampleLists(OneFillOptionalFieldGroup) ]

EncodeFillOptionalFieldGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.fillOptionalFieldGroup), 1)
        \o EncodeFillOptionalFieldGroupList(message.fillOptionalFieldGroup)

DecodeFillOptionalFieldGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET fillOptionalFieldGroup == ReadFillOptionalFieldGroupList(numInGroup.rest, numInGroup.value) IN IF ~fillOptionalFieldGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort       |-> blockLengthShort.value,
         fillOptionalFieldGroup |-> fillOptionalFieldGroup.value ], fillOptionalFieldGroup.rest)

ZeroFillOptionalFieldGroups ==
    [ blockLengthShort       |-> [i \in 1 .. 1 |-> 0],
      fillOptionalFieldGroup |-> << >> ]

(* Fill Optional Field Groups at zero, then each field in turn at the values it is checked at *)
CheckedFillOptionalFieldGroups ==
    { ZeroFillOptionalFieldGroups }
        \cup { [ZeroFillOptionalFieldGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroFillOptionalFieldGroups EXCEPT !.fillOptionalFieldGroup = one] : one \in SampleLists(OneFillOptionalFieldGroup) }

(***************************************************************************)
(* Fill Strategy Field Group: 41 bytes                                     *)
(***************************************************************************)

FillStrategyFieldGroup ==
    [ legLastPx             : Sample(8),
      legLastQty            : Sample(8),
      legInstrumentId       : Sample(4),
      legSideOptional       : Sample(1),
      executionIdOptional   : Sample(4),
      tradeUniqueIdentifier : Sample(16) ]

EncodeFillStrategyFieldGroup(message) ==
    message.legLastPx
        \o message.legLastQty
        \o message.legInstrumentId
        \o message.legSideOptional
        \o message.executionIdOptional
        \o message.tradeUniqueIdentifier

DecodeFillStrategyFieldGroup(bytes) ==
    LET legLastPx == ReadBytes(bytes, 8) IN IF ~legLastPx.ok THEN Fail ELSE
    LET legLastQty == ReadBytes(legLastPx.rest, 8) IN IF ~legLastQty.ok THEN Fail ELSE
    LET legInstrumentId == ReadBytes(legLastQty.rest, 4) IN IF ~legInstrumentId.ok THEN Fail ELSE
    LET legSideOptional == ReadBytes(legInstrumentId.rest, 1) IN IF ~legSideOptional.ok THEN Fail ELSE
    LET executionIdOptional == ReadBytes(legSideOptional.rest, 4) IN IF ~executionIdOptional.ok THEN Fail ELSE
    LET tradeUniqueIdentifier == ReadBytes(executionIdOptional.rest, 16) IN IF ~tradeUniqueIdentifier.ok THEN Fail ELSE
    Ok([ legLastPx             |-> legLastPx.value,
         legLastQty            |-> legLastQty.value,
         legInstrumentId       |-> legInstrumentId.value,
         legSideOptional       |-> legSideOptional.value,
         executionIdOptional   |-> executionIdOptional.value,
         tradeUniqueIdentifier |-> tradeUniqueIdentifier.value ], tradeUniqueIdentifier.rest)

ZeroFillStrategyFieldGroup ==
    [ legLastPx             |-> [i \in 1 .. 8 |-> 0],
      legLastQty            |-> [i \in 1 .. 8 |-> 0],
      legInstrumentId       |-> [i \in 1 .. 4 |-> 0],
      legSideOptional       |-> [i \in 1 .. 1 |-> 0],
      executionIdOptional   |-> [i \in 1 .. 4 |-> 0],
      tradeUniqueIdentifier |-> [i \in 1 .. 16 |-> 0] ]

(* Fill Strategy Field Group at zero, then each field in turn at the values it is checked at *)
CheckedFillStrategyFieldGroup ==
    { ZeroFillStrategyFieldGroup }
        \cup { [ZeroFillStrategyFieldGroup EXCEPT !.legLastPx = one] : one \in Sample(8) }
        \cup { [ZeroFillStrategyFieldGroup EXCEPT !.legLastQty = one] : one \in Sample(8) }
        \cup { [ZeroFillStrategyFieldGroup EXCEPT !.legInstrumentId = one] : one \in Sample(4) }
        \cup { [ZeroFillStrategyFieldGroup EXCEPT !.legSideOptional = one] : one \in Sample(1) }
        \cup { [ZeroFillStrategyFieldGroup EXCEPT !.executionIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroFillStrategyFieldGroup EXCEPT !.tradeUniqueIdentifier = one] : one \in Sample(16) }

(* A run of Fill Strategy Field Group, written one after another *)
RECURSIVE EncodeFillStrategyFieldGroupList(_)
EncodeFillStrategyFieldGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFillStrategyFieldGroup(Head(messages)) \o EncodeFillStrategyFieldGroupList(Tail(messages))

(* As many Fill Strategy Field Group as the field that counts them says *)
RECURSIVE ReadFillStrategyFieldGroupList(_, _)
ReadFillStrategyFieldGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFillStrategyFieldGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFillStrategyFieldGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Fill Strategy Field Group of each kind, for the lists that carry them *)
OneFillStrategyFieldGroup == { ZeroFillStrategyFieldGroup }

(***************************************************************************)
(* Fill Strategy Field Groups                                              *)
(***************************************************************************)

FillStrategyFieldGroups ==
    [ blockLengthShort       : Sample(1),
      fillStrategyFieldGroup : SampleLists(OneFillStrategyFieldGroup) ]

EncodeFillStrategyFieldGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.fillStrategyFieldGroup), 1)
        \o EncodeFillStrategyFieldGroupList(message.fillStrategyFieldGroup)

DecodeFillStrategyFieldGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET fillStrategyFieldGroup == ReadFillStrategyFieldGroupList(numInGroup.rest, numInGroup.value) IN IF ~fillStrategyFieldGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort       |-> blockLengthShort.value,
         fillStrategyFieldGroup |-> fillStrategyFieldGroup.value ], fillStrategyFieldGroup.rest)

ZeroFillStrategyFieldGroups ==
    [ blockLengthShort       |-> [i \in 1 .. 1 |-> 0],
      fillStrategyFieldGroup |-> << >> ]

(* Fill Strategy Field Groups at zero, then each field in turn at the values it is checked at *)
CheckedFillStrategyFieldGroups ==
    { ZeroFillStrategyFieldGroups }
        \cup { [ZeroFillStrategyFieldGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroFillStrategyFieldGroups EXCEPT !.fillStrategyFieldGroup = one] : one \in SampleLists(OneFillStrategyFieldGroup) }

(***************************************************************************)
(* Mifid Fields Group: 9 bytes                                             *)
(***************************************************************************)

MifidFieldsGroup2 ==
    [ executionWithinFirmShortCodeOptional : Sample(4),
      clientIdentificationShortcode        : Sample(4),
      mifidIndicatorsOptional              : Sample(1) ]

EncodeMifidFieldsGroup2(message) ==
    message.executionWithinFirmShortCodeOptional
        \o message.clientIdentificationShortcode
        \o message.mifidIndicatorsOptional

DecodeMifidFieldsGroup2(bytes) ==
    LET executionWithinFirmShortCodeOptional == ReadBytes(bytes, 4) IN IF ~executionWithinFirmShortCodeOptional.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCodeOptional.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET mifidIndicatorsOptional == ReadBytes(clientIdentificationShortcode.rest, 1) IN IF ~mifidIndicatorsOptional.ok THEN Fail ELSE
    Ok([ executionWithinFirmShortCodeOptional |-> executionWithinFirmShortCodeOptional.value,
         clientIdentificationShortcode        |-> clientIdentificationShortcode.value,
         mifidIndicatorsOptional              |-> mifidIndicatorsOptional.value ], mifidIndicatorsOptional.rest)

ZeroMifidFieldsGroup2 ==
    [ executionWithinFirmShortCodeOptional |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode        |-> [i \in 1 .. 4 |-> 0],
      mifidIndicatorsOptional              |-> [i \in 1 .. 1 |-> 0] ]

(* Mifid Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedMifidFieldsGroup2 ==
    { ZeroMifidFieldsGroup2 }
        \cup { [ZeroMifidFieldsGroup2 EXCEPT !.executionWithinFirmShortCodeOptional = one] : one \in Sample(4) }
        \cup { [ZeroMifidFieldsGroup2 EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroMifidFieldsGroup2 EXCEPT !.mifidIndicatorsOptional = one] : one \in Sample(1) }

(* A run of Mifid Fields Group, written one after another *)
RECURSIVE EncodeMifidFieldsGroup2List(_)
EncodeMifidFieldsGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMifidFieldsGroup2(Head(messages)) \o EncodeMifidFieldsGroup2List(Tail(messages))

(* As many Mifid Fields Group as the field that counts them says *)
RECURSIVE ReadMifidFieldsGroup2List(_, _)
ReadMifidFieldsGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMifidFieldsGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMifidFieldsGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mifid Fields Group of each kind, for the lists that carry them *)
OneMifidFieldsGroup2 == { ZeroMifidFieldsGroup2 }

(***************************************************************************)
(* Mifid Fields Groups                                                     *)
(***************************************************************************)

MifidFieldsGroups2 ==
    [ blockLengthShort : Sample(1),
      mifidFieldsGroup : SampleLists(OneMifidFieldsGroup2) ]

EncodeMifidFieldsGroups2(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.mifidFieldsGroup), 1)
        \o EncodeMifidFieldsGroup2List(message.mifidFieldsGroup)

DecodeMifidFieldsGroups2(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET mifidFieldsGroup == ReadMifidFieldsGroup2List(numInGroup.rest, numInGroup.value) IN IF ~mifidFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         mifidFieldsGroup |-> mifidFieldsGroup.value ], mifidFieldsGroup.rest)

ZeroMifidFieldsGroups2 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      mifidFieldsGroup |-> << >> ]

(* Mifid Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedMifidFieldsGroups2 ==
    { ZeroMifidFieldsGroups2 }
        \cup { [ZeroMifidFieldsGroups2 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroMifidFieldsGroups2 EXCEPT !.mifidFieldsGroup = one] : one \in SampleLists(OneMifidFieldsGroup2) }

(***************************************************************************)
(* Fill Derivatives Field Group: 17 bytes                                  *)
(***************************************************************************)

FillDerivativesFieldGroup ==
    [ evaluatedPrice       : Sample(8),
      messagePriceNotation : Sample(1),
      finalSymbolIndex     : Sample(4),
      finalExecutionId     : Sample(4) ]

EncodeFillDerivativesFieldGroup(message) ==
    message.evaluatedPrice
        \o message.messagePriceNotation
        \o message.finalSymbolIndex
        \o message.finalExecutionId

DecodeFillDerivativesFieldGroup(bytes) ==
    LET evaluatedPrice == ReadBytes(bytes, 8) IN IF ~evaluatedPrice.ok THEN Fail ELSE
    LET messagePriceNotation == ReadBytes(evaluatedPrice.rest, 1) IN IF ~messagePriceNotation.ok THEN Fail ELSE
    LET finalSymbolIndex == ReadBytes(messagePriceNotation.rest, 4) IN IF ~finalSymbolIndex.ok THEN Fail ELSE
    LET finalExecutionId == ReadBytes(finalSymbolIndex.rest, 4) IN IF ~finalExecutionId.ok THEN Fail ELSE
    Ok([ evaluatedPrice       |-> evaluatedPrice.value,
         messagePriceNotation |-> messagePriceNotation.value,
         finalSymbolIndex     |-> finalSymbolIndex.value,
         finalExecutionId     |-> finalExecutionId.value ], finalExecutionId.rest)

ZeroFillDerivativesFieldGroup ==
    [ evaluatedPrice       |-> [i \in 1 .. 8 |-> 0],
      messagePriceNotation |-> [i \in 1 .. 1 |-> 0],
      finalSymbolIndex     |-> [i \in 1 .. 4 |-> 0],
      finalExecutionId     |-> [i \in 1 .. 4 |-> 0] ]

(* Fill Derivatives Field Group at zero, then each field in turn at the values it is checked at *)
CheckedFillDerivativesFieldGroup ==
    { ZeroFillDerivativesFieldGroup }
        \cup { [ZeroFillDerivativesFieldGroup EXCEPT !.evaluatedPrice = one] : one \in Sample(8) }
        \cup { [ZeroFillDerivativesFieldGroup EXCEPT !.messagePriceNotation = one] : one \in Sample(1) }
        \cup { [ZeroFillDerivativesFieldGroup EXCEPT !.finalSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroFillDerivativesFieldGroup EXCEPT !.finalExecutionId = one] : one \in Sample(4) }

(* A run of Fill Derivatives Field Group, written one after another *)
RECURSIVE EncodeFillDerivativesFieldGroupList(_)
EncodeFillDerivativesFieldGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeFillDerivativesFieldGroup(Head(messages)) \o EncodeFillDerivativesFieldGroupList(Tail(messages))

(* As many Fill Derivatives Field Group as the field that counts them says *)
RECURSIVE ReadFillDerivativesFieldGroupList(_, _)
ReadFillDerivativesFieldGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeFillDerivativesFieldGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadFillDerivativesFieldGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Fill Derivatives Field Group of each kind, for the lists that carry them *)
OneFillDerivativesFieldGroup == { ZeroFillDerivativesFieldGroup }

(***************************************************************************)
(* Fill Derivatives Field Groups                                           *)
(***************************************************************************)

FillDerivativesFieldGroups ==
    [ blockLengthShort          : Sample(1),
      fillDerivativesFieldGroup : SampleLists(OneFillDerivativesFieldGroup) ]

EncodeFillDerivativesFieldGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.fillDerivativesFieldGroup), 1)
        \o EncodeFillDerivativesFieldGroupList(message.fillDerivativesFieldGroup)

DecodeFillDerivativesFieldGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET fillDerivativesFieldGroup == ReadFillDerivativesFieldGroupList(numInGroup.rest, numInGroup.value) IN IF ~fillDerivativesFieldGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort          |-> blockLengthShort.value,
         fillDerivativesFieldGroup |-> fillDerivativesFieldGroup.value ], fillDerivativesFieldGroup.rest)

ZeroFillDerivativesFieldGroups ==
    [ blockLengthShort          |-> [i \in 1 .. 1 |-> 0],
      fillDerivativesFieldGroup |-> << >> ]

(* Fill Derivatives Field Groups at zero, then each field in turn at the values it is checked at *)
CheckedFillDerivativesFieldGroups ==
    { ZeroFillDerivativesFieldGroups }
        \cup { [ZeroFillDerivativesFieldGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroFillDerivativesFieldGroups EXCEPT !.fillDerivativesFieldGroup = one] : one \in SampleLists(OneFillDerivativesFieldGroup) }

(***************************************************************************)
(* Fill Message                                                            *)
(***************************************************************************)

FillMessage ==
    [ msgSeqNum                  : Sample(4),
      firmId                     : Sample(8),
      tradeTime                  : Sample(8),
      bookOutTimeOptional        : Sample(8),
      oegInFromMeOptional        : Sample(8),
      oegOutToMemberOptional     : Sample(8),
      clientOrderIdOptional      : Sample(8),
      symbolIndex                : Sample(4),
      emm                        : Sample(1),
      side                       : Sample(1),
      tradeType                  : Sample(1),
      tradeQualifier             : Sample(1),
      orderId                    : Sample(8),
      lastTradedPx               : Sample(8),
      lastShares                 : Sample(8),
      leavesQty                  : Sample(8),
      executionId                : Sample(4),
      executionPhase             : Sample(1),
      lisTransactionId           : Sample(4),
      escbMembership             : Sample(1),
      tradeUniqueIdentifier      : Sample(16),
      fillOptionalFieldGroups    : FillOptionalFieldGroups,
      fillStrategyFieldGroups    : FillStrategyFieldGroups,
      mifidFieldsGroups          : MifidFieldsGroups2,
      fillDerivativesFieldGroups : FillDerivativesFieldGroups ]

EncodeFillMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.tradeTime
        \o message.bookOutTimeOptional
        \o message.oegInFromMeOptional
        \o message.oegOutToMemberOptional
        \o message.clientOrderIdOptional
        \o message.symbolIndex
        \o message.emm
        \o message.side
        \o message.tradeType
        \o message.tradeQualifier
        \o message.orderId
        \o message.lastTradedPx
        \o message.lastShares
        \o message.leavesQty
        \o message.executionId
        \o message.executionPhase
        \o message.lisTransactionId
        \o message.escbMembership
        \o message.tradeUniqueIdentifier
        \o EncodeFillOptionalFieldGroups(message.fillOptionalFieldGroups)
        \o EncodeFillStrategyFieldGroups(message.fillStrategyFieldGroups)
        \o EncodeMifidFieldsGroups2(message.mifidFieldsGroups)
        \o EncodeFillDerivativesFieldGroups(message.fillDerivativesFieldGroups)

DecodeFillMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET tradeTime == ReadBytes(firmId.rest, 8) IN IF ~tradeTime.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(tradeTime.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET oegInFromMeOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~oegInFromMeOptional.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(oegInFromMeOptional.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET clientOrderIdOptional == ReadBytes(oegOutToMemberOptional.rest, 8) IN IF ~clientOrderIdOptional.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(clientOrderIdOptional.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET side == ReadBytes(emm.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET tradeType == ReadBytes(side.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET tradeQualifier == ReadBytes(tradeType.rest, 1) IN IF ~tradeQualifier.ok THEN Fail ELSE
    LET orderId == ReadBytes(tradeQualifier.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET lastTradedPx == ReadBytes(orderId.rest, 8) IN IF ~lastTradedPx.ok THEN Fail ELSE
    LET lastShares == ReadBytes(lastTradedPx.rest, 8) IN IF ~lastShares.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(lastShares.rest, 8) IN IF ~leavesQty.ok THEN Fail ELSE
    LET executionId == ReadBytes(leavesQty.rest, 4) IN IF ~executionId.ok THEN Fail ELSE
    LET executionPhase == ReadBytes(executionId.rest, 1) IN IF ~executionPhase.ok THEN Fail ELSE
    LET lisTransactionId == ReadBytes(executionPhase.rest, 4) IN IF ~lisTransactionId.ok THEN Fail ELSE
    LET escbMembership == ReadBytes(lisTransactionId.rest, 1) IN IF ~escbMembership.ok THEN Fail ELSE
    LET tradeUniqueIdentifier == ReadBytes(escbMembership.rest, 16) IN IF ~tradeUniqueIdentifier.ok THEN Fail ELSE
    LET fillOptionalFieldGroups == DecodeFillOptionalFieldGroups(tradeUniqueIdentifier.rest) IN IF ~fillOptionalFieldGroups.ok THEN Fail ELSE
    LET fillStrategyFieldGroups == DecodeFillStrategyFieldGroups(fillOptionalFieldGroups.rest) IN IF ~fillStrategyFieldGroups.ok THEN Fail ELSE
    LET mifidFieldsGroups == DecodeMifidFieldsGroups2(fillStrategyFieldGroups.rest) IN IF ~mifidFieldsGroups.ok THEN Fail ELSE
    LET fillDerivativesFieldGroups == DecodeFillDerivativesFieldGroups(mifidFieldsGroups.rest) IN IF ~fillDerivativesFieldGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                  |-> msgSeqNum.value,
         firmId                     |-> firmId.value,
         tradeTime                  |-> tradeTime.value,
         bookOutTimeOptional        |-> bookOutTimeOptional.value,
         oegInFromMeOptional        |-> oegInFromMeOptional.value,
         oegOutToMemberOptional     |-> oegOutToMemberOptional.value,
         clientOrderIdOptional      |-> clientOrderIdOptional.value,
         symbolIndex                |-> symbolIndex.value,
         emm                        |-> emm.value,
         side                       |-> side.value,
         tradeType                  |-> tradeType.value,
         tradeQualifier             |-> tradeQualifier.value,
         orderId                    |-> orderId.value,
         lastTradedPx               |-> lastTradedPx.value,
         lastShares                 |-> lastShares.value,
         leavesQty                  |-> leavesQty.value,
         executionId                |-> executionId.value,
         executionPhase             |-> executionPhase.value,
         lisTransactionId           |-> lisTransactionId.value,
         escbMembership             |-> escbMembership.value,
         tradeUniqueIdentifier      |-> tradeUniqueIdentifier.value,
         fillOptionalFieldGroups    |-> fillOptionalFieldGroups.value,
         fillStrategyFieldGroups    |-> fillStrategyFieldGroups.value,
         mifidFieldsGroups          |-> mifidFieldsGroups.value,
         fillDerivativesFieldGroups |-> fillDerivativesFieldGroups.value ], fillDerivativesFieldGroups.rest)

ZeroFillMessage ==
    [ msgSeqNum                  |-> [i \in 1 .. 4 |-> 0],
      firmId                     |-> [i \in 1 .. 8 |-> 0],
      tradeTime                  |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional        |-> [i \in 1 .. 8 |-> 0],
      oegInFromMeOptional        |-> [i \in 1 .. 8 |-> 0],
      oegOutToMemberOptional     |-> [i \in 1 .. 8 |-> 0],
      clientOrderIdOptional      |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                |-> [i \in 1 .. 4 |-> 0],
      emm                        |-> [i \in 1 .. 1 |-> 0],
      side                       |-> [i \in 1 .. 1 |-> 0],
      tradeType                  |-> [i \in 1 .. 1 |-> 0],
      tradeQualifier             |-> [i \in 1 .. 1 |-> 0],
      orderId                    |-> [i \in 1 .. 8 |-> 0],
      lastTradedPx               |-> [i \in 1 .. 8 |-> 0],
      lastShares                 |-> [i \in 1 .. 8 |-> 0],
      leavesQty                  |-> [i \in 1 .. 8 |-> 0],
      executionId                |-> [i \in 1 .. 4 |-> 0],
      executionPhase             |-> [i \in 1 .. 1 |-> 0],
      lisTransactionId           |-> [i \in 1 .. 4 |-> 0],
      escbMembership             |-> [i \in 1 .. 1 |-> 0],
      tradeUniqueIdentifier      |-> [i \in 1 .. 16 |-> 0],
      fillOptionalFieldGroups    |-> ZeroFillOptionalFieldGroups,
      fillStrategyFieldGroups    |-> ZeroFillStrategyFieldGroups,
      mifidFieldsGroups          |-> ZeroMifidFieldsGroups2,
      fillDerivativesFieldGroups |-> ZeroFillDerivativesFieldGroups ]

(* Fill Message at zero, then each field in turn at the values it is checked at *)
CheckedFillMessage ==
    { ZeroFillMessage }
        \cup { [ZeroFillMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroFillMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroFillMessage EXCEPT !.tradeTime = one] : one \in Sample(8) }
        \cup { [ZeroFillMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroFillMessage EXCEPT !.oegInFromMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroFillMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroFillMessage EXCEPT !.clientOrderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroFillMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroFillMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroFillMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroFillMessage EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroFillMessage EXCEPT !.tradeQualifier = one] : one \in Sample(1) }
        \cup { [ZeroFillMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroFillMessage EXCEPT !.lastTradedPx = one] : one \in Sample(8) }
        \cup { [ZeroFillMessage EXCEPT !.lastShares = one] : one \in Sample(8) }
        \cup { [ZeroFillMessage EXCEPT !.leavesQty = one] : one \in Sample(8) }
        \cup { [ZeroFillMessage EXCEPT !.executionId = one] : one \in Sample(4) }
        \cup { [ZeroFillMessage EXCEPT !.executionPhase = one] : one \in Sample(1) }
        \cup { [ZeroFillMessage EXCEPT !.lisTransactionId = one] : one \in Sample(4) }
        \cup { [ZeroFillMessage EXCEPT !.escbMembership = one] : one \in Sample(1) }
        \cup { [ZeroFillMessage EXCEPT !.tradeUniqueIdentifier = one] : one \in Sample(16) }
        \cup { [ZeroFillMessage EXCEPT !.fillOptionalFieldGroups = one] : one \in CheckedFillOptionalFieldGroups }
        \cup { [ZeroFillMessage EXCEPT !.fillStrategyFieldGroups = one] : one \in CheckedFillStrategyFieldGroups }
        \cup { [ZeroFillMessage EXCEPT !.mifidFieldsGroups = one] : one \in CheckedMifidFieldsGroups2 }
        \cup { [ZeroFillMessage EXCEPT !.fillDerivativesFieldGroups = one] : one \in CheckedFillDerivativesFieldGroups }

(***************************************************************************)
(* Mifid Fields Group: 9 bytes                                             *)
(***************************************************************************)

MifidFieldsGroup3 ==
    [ executionWithinFirmShortCodeOptional : Sample(4),
      clientIdentificationShortcode        : Sample(4),
      mifidIndicatorsOptional              : Sample(1) ]

EncodeMifidFieldsGroup3(message) ==
    message.executionWithinFirmShortCodeOptional
        \o message.clientIdentificationShortcode
        \o message.mifidIndicatorsOptional

DecodeMifidFieldsGroup3(bytes) ==
    LET executionWithinFirmShortCodeOptional == ReadBytes(bytes, 4) IN IF ~executionWithinFirmShortCodeOptional.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCodeOptional.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET mifidIndicatorsOptional == ReadBytes(clientIdentificationShortcode.rest, 1) IN IF ~mifidIndicatorsOptional.ok THEN Fail ELSE
    Ok([ executionWithinFirmShortCodeOptional |-> executionWithinFirmShortCodeOptional.value,
         clientIdentificationShortcode        |-> clientIdentificationShortcode.value,
         mifidIndicatorsOptional              |-> mifidIndicatorsOptional.value ], mifidIndicatorsOptional.rest)

ZeroMifidFieldsGroup3 ==
    [ executionWithinFirmShortCodeOptional |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode        |-> [i \in 1 .. 4 |-> 0],
      mifidIndicatorsOptional              |-> [i \in 1 .. 1 |-> 0] ]

(* Mifid Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedMifidFieldsGroup3 ==
    { ZeroMifidFieldsGroup3 }
        \cup { [ZeroMifidFieldsGroup3 EXCEPT !.executionWithinFirmShortCodeOptional = one] : one \in Sample(4) }
        \cup { [ZeroMifidFieldsGroup3 EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroMifidFieldsGroup3 EXCEPT !.mifidIndicatorsOptional = one] : one \in Sample(1) }

(* A run of Mifid Fields Group, written one after another *)
RECURSIVE EncodeMifidFieldsGroup3List(_)
EncodeMifidFieldsGroup3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMifidFieldsGroup3(Head(messages)) \o EncodeMifidFieldsGroup3List(Tail(messages))

(* As many Mifid Fields Group as the field that counts them says *)
RECURSIVE ReadMifidFieldsGroup3List(_, _)
ReadMifidFieldsGroup3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMifidFieldsGroup3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMifidFieldsGroup3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mifid Fields Group of each kind, for the lists that carry them *)
OneMifidFieldsGroup3 == { ZeroMifidFieldsGroup3 }

(***************************************************************************)
(* Mifid Fields Groups                                                     *)
(***************************************************************************)

MifidFieldsGroups3 ==
    [ blockLengthShort : Sample(1),
      mifidFieldsGroup : SampleLists(OneMifidFieldsGroup3) ]

EncodeMifidFieldsGroups3(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.mifidFieldsGroup), 1)
        \o EncodeMifidFieldsGroup3List(message.mifidFieldsGroup)

DecodeMifidFieldsGroups3(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET mifidFieldsGroup == ReadMifidFieldsGroup3List(numInGroup.rest, numInGroup.value) IN IF ~mifidFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         mifidFieldsGroup |-> mifidFieldsGroup.value ], mifidFieldsGroup.rest)

ZeroMifidFieldsGroups3 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      mifidFieldsGroup |-> << >> ]

(* Mifid Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedMifidFieldsGroups3 ==
    { ZeroMifidFieldsGroups3 }
        \cup { [ZeroMifidFieldsGroups3 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroMifidFieldsGroups3 EXCEPT !.mifidFieldsGroup = one] : one \in SampleLists(OneMifidFieldsGroup3) }

(***************************************************************************)
(* Kill Message                                                            *)
(***************************************************************************)

KillMessage ==
    [ msgSeqNum              : Sample(4),
      firmId                 : Sample(8),
      sendingTimeOptional    : Sample(8),
      oegInFromMember        : Sample(8),
      oegOutTimeToMe         : Sample(8),
      bookIn                 : Sample(8),
      bookOutTimeOptional    : Sample(8),
      oegInFromMeOptional    : Sample(8),
      oegOutToMemberOptional : Sample(8),
      clientOrderIdOptional  : Sample(8),
      origClientOrderId      : Sample(8),
      orderId                : Sample(8),
      symbolIndex            : Sample(4),
      emm                    : Sample(1),
      killReason             : Sample(2),
      ackQualifiersOptional  : Sample(1),
      mifidFieldsGroups      : MifidFieldsGroups3 ]

EncodeKillMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.sendingTimeOptional
        \o message.oegInFromMember
        \o message.oegOutTimeToMe
        \o message.bookIn
        \o message.bookOutTimeOptional
        \o message.oegInFromMeOptional
        \o message.oegOutToMemberOptional
        \o message.clientOrderIdOptional
        \o message.origClientOrderId
        \o message.orderId
        \o message.symbolIndex
        \o message.emm
        \o message.killReason
        \o message.ackQualifiersOptional
        \o EncodeMifidFieldsGroups3(message.mifidFieldsGroups)

DecodeKillMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTimeOptional == ReadBytes(firmId.rest, 8) IN IF ~sendingTimeOptional.ok THEN Fail ELSE
    LET oegInFromMember == ReadBytes(sendingTimeOptional.rest, 8) IN IF ~oegInFromMember.ok THEN Fail ELSE
    LET oegOutTimeToMe == ReadBytes(oegInFromMember.rest, 8) IN IF ~oegOutTimeToMe.ok THEN Fail ELSE
    LET bookIn == ReadBytes(oegOutTimeToMe.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET oegInFromMeOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~oegInFromMeOptional.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(oegInFromMeOptional.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET clientOrderIdOptional == ReadBytes(oegOutToMemberOptional.rest, 8) IN IF ~clientOrderIdOptional.ok THEN Fail ELSE
    LET origClientOrderId == ReadBytes(clientOrderIdOptional.rest, 8) IN IF ~origClientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(origClientOrderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(orderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET killReason == ReadBytes(emm.rest, 2) IN IF ~killReason.ok THEN Fail ELSE
    LET ackQualifiersOptional == ReadBytes(killReason.rest, 1) IN IF ~ackQualifiersOptional.ok THEN Fail ELSE
    LET mifidFieldsGroups == DecodeMifidFieldsGroups3(ackQualifiersOptional.rest) IN IF ~mifidFieldsGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum              |-> msgSeqNum.value,
         firmId                 |-> firmId.value,
         sendingTimeOptional    |-> sendingTimeOptional.value,
         oegInFromMember        |-> oegInFromMember.value,
         oegOutTimeToMe         |-> oegOutTimeToMe.value,
         bookIn                 |-> bookIn.value,
         bookOutTimeOptional    |-> bookOutTimeOptional.value,
         oegInFromMeOptional    |-> oegInFromMeOptional.value,
         oegOutToMemberOptional |-> oegOutToMemberOptional.value,
         clientOrderIdOptional  |-> clientOrderIdOptional.value,
         origClientOrderId      |-> origClientOrderId.value,
         orderId                |-> orderId.value,
         symbolIndex            |-> symbolIndex.value,
         emm                    |-> emm.value,
         killReason             |-> killReason.value,
         ackQualifiersOptional  |-> ackQualifiersOptional.value,
         mifidFieldsGroups      |-> mifidFieldsGroups.value ], mifidFieldsGroups.rest)

ZeroKillMessage ==
    [ msgSeqNum              |-> [i \in 1 .. 4 |-> 0],
      firmId                 |-> [i \in 1 .. 8 |-> 0],
      sendingTimeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegInFromMember        |-> [i \in 1 .. 8 |-> 0],
      oegOutTimeToMe         |-> [i \in 1 .. 8 |-> 0],
      bookIn                 |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegInFromMeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegOutToMemberOptional |-> [i \in 1 .. 8 |-> 0],
      clientOrderIdOptional  |-> [i \in 1 .. 8 |-> 0],
      origClientOrderId      |-> [i \in 1 .. 8 |-> 0],
      orderId                |-> [i \in 1 .. 8 |-> 0],
      symbolIndex            |-> [i \in 1 .. 4 |-> 0],
      emm                    |-> [i \in 1 .. 1 |-> 0],
      killReason             |-> [i \in 1 .. 2 |-> 0],
      ackQualifiersOptional  |-> [i \in 1 .. 1 |-> 0],
      mifidFieldsGroups      |-> ZeroMifidFieldsGroups3 ]

(* Kill Message at zero, then each field in turn at the values it is checked at *)
CheckedKillMessage ==
    { ZeroKillMessage }
        \cup { [ZeroKillMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroKillMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroKillMessage EXCEPT !.sendingTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroKillMessage EXCEPT !.oegInFromMember = one] : one \in Sample(8) }
        \cup { [ZeroKillMessage EXCEPT !.oegOutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroKillMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroKillMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroKillMessage EXCEPT !.oegInFromMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroKillMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroKillMessage EXCEPT !.clientOrderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroKillMessage EXCEPT !.origClientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroKillMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroKillMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroKillMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroKillMessage EXCEPT !.killReason = one] : one \in Sample(2) }
        \cup { [ZeroKillMessage EXCEPT !.ackQualifiersOptional = one] : one \in Sample(1) }
        \cup { [ZeroKillMessage EXCEPT !.mifidFieldsGroups = one] : one \in CheckedMifidFieldsGroups3 }

(***************************************************************************)
(* New Order Message Free Text Section Group: 18 bytes                     *)
(***************************************************************************)

NewOrderMessageFreeTextSectionGroup2 ==
    [ freeText : Sample(18) ]

EncodeNewOrderMessageFreeTextSectionGroup2(message) ==
    message.freeText

DecodeNewOrderMessageFreeTextSectionGroup2(bytes) ==
    LET freeText == ReadBytes(bytes, 18) IN IF ~freeText.ok THEN Fail ELSE
    Ok([ freeText |-> freeText.value ], freeText.rest)

ZeroNewOrderMessageFreeTextSectionGroup2 ==
    [ freeText |-> [i \in 1 .. 18 |-> 0] ]

(* New Order Message Free Text Section Group at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderMessageFreeTextSectionGroup2 ==
    { ZeroNewOrderMessageFreeTextSectionGroup2 }
        \cup { [ZeroNewOrderMessageFreeTextSectionGroup2 EXCEPT !.freeText = one] : one \in Sample(18) }

(* A run of New Order Message Free Text Section Group, written one after another *)
RECURSIVE EncodeNewOrderMessageFreeTextSectionGroup2List(_)
EncodeNewOrderMessageFreeTextSectionGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewOrderMessageFreeTextSectionGroup2(Head(messages)) \o EncodeNewOrderMessageFreeTextSectionGroup2List(Tail(messages))

(* As many New Order Message Free Text Section Group as the field that counts them says *)
RECURSIVE ReadNewOrderMessageFreeTextSectionGroup2List(_, _)
ReadNewOrderMessageFreeTextSectionGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewOrderMessageFreeTextSectionGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewOrderMessageFreeTextSectionGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Order Message Free Text Section Group of each kind, for the lists that carry them *)
OneNewOrderMessageFreeTextSectionGroup2 == { ZeroNewOrderMessageFreeTextSectionGroup2 }

(***************************************************************************)
(* Free Text Groups                                                        *)
(***************************************************************************)

FreeTextGroups2 ==
    [ blockLengthShort                    : Sample(1),
      newOrderMessageFreeTextSectionGroup : SampleLists(OneNewOrderMessageFreeTextSectionGroup2) ]

EncodeFreeTextGroups2(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.newOrderMessageFreeTextSectionGroup), 1)
        \o EncodeNewOrderMessageFreeTextSectionGroup2List(message.newOrderMessageFreeTextSectionGroup)

DecodeFreeTextGroups2(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET newOrderMessageFreeTextSectionGroup == ReadNewOrderMessageFreeTextSectionGroup2List(numInGroup.rest, numInGroup.value) IN IF ~newOrderMessageFreeTextSectionGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                    |-> blockLengthShort.value,
         newOrderMessageFreeTextSectionGroup |-> newOrderMessageFreeTextSectionGroup.value ], newOrderMessageFreeTextSectionGroup.rest)

ZeroFreeTextGroups2 ==
    [ blockLengthShort                    |-> [i \in 1 .. 1 |-> 0],
      newOrderMessageFreeTextSectionGroup |-> << >> ]

(* Free Text Groups at zero, then each field in turn at the values it is checked at *)
CheckedFreeTextGroups2 ==
    { ZeroFreeTextGroups2 }
        \cup { [ZeroFreeTextGroups2 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroFreeTextGroups2 EXCEPT !.newOrderMessageFreeTextSectionGroup = one] : one \in SampleLists(OneNewOrderMessageFreeTextSectionGroup2) }

(***************************************************************************)
(* Cancel Replace Optional Field Group: 34 bytes                           *)
(***************************************************************************)

CancelReplaceOptionalFieldGroup ==
    [ stopPx                   : Sample(8),
      pegOffset                : Sample(1),
      undisclosedPrice         : Sample(8),
      disclosedQty             : Sample(8),
      orderExpirationTime      : Sample(4),
      orderExpirationDate      : Sample(2),
      tradingSession           : Sample(1),
      stopTriggeredTimeInForce : Sample(1),
      undisclosedIcebergType   : Sample(1) ]

EncodeCancelReplaceOptionalFieldGroup(message) ==
    message.stopPx
        \o message.pegOffset
        \o message.undisclosedPrice
        \o message.disclosedQty
        \o message.orderExpirationTime
        \o message.orderExpirationDate
        \o message.tradingSession
        \o message.stopTriggeredTimeInForce
        \o message.undisclosedIcebergType

DecodeCancelReplaceOptionalFieldGroup(bytes) ==
    LET stopPx == ReadBytes(bytes, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET pegOffset == ReadBytes(stopPx.rest, 1) IN IF ~pegOffset.ok THEN Fail ELSE
    LET undisclosedPrice == ReadBytes(pegOffset.rest, 8) IN IF ~undisclosedPrice.ok THEN Fail ELSE
    LET disclosedQty == ReadBytes(undisclosedPrice.rest, 8) IN IF ~disclosedQty.ok THEN Fail ELSE
    LET orderExpirationTime == ReadBytes(disclosedQty.rest, 4) IN IF ~orderExpirationTime.ok THEN Fail ELSE
    LET orderExpirationDate == ReadBytes(orderExpirationTime.rest, 2) IN IF ~orderExpirationDate.ok THEN Fail ELSE
    LET tradingSession == ReadBytes(orderExpirationDate.rest, 1) IN IF ~tradingSession.ok THEN Fail ELSE
    LET stopTriggeredTimeInForce == ReadBytes(tradingSession.rest, 1) IN IF ~stopTriggeredTimeInForce.ok THEN Fail ELSE
    LET undisclosedIcebergType == ReadBytes(stopTriggeredTimeInForce.rest, 1) IN IF ~undisclosedIcebergType.ok THEN Fail ELSE
    Ok([ stopPx                   |-> stopPx.value,
         pegOffset                |-> pegOffset.value,
         undisclosedPrice         |-> undisclosedPrice.value,
         disclosedQty             |-> disclosedQty.value,
         orderExpirationTime      |-> orderExpirationTime.value,
         orderExpirationDate      |-> orderExpirationDate.value,
         tradingSession           |-> tradingSession.value,
         stopTriggeredTimeInForce |-> stopTriggeredTimeInForce.value,
         undisclosedIcebergType   |-> undisclosedIcebergType.value ], undisclosedIcebergType.rest)

ZeroCancelReplaceOptionalFieldGroup ==
    [ stopPx                   |-> [i \in 1 .. 8 |-> 0],
      pegOffset                |-> [i \in 1 .. 1 |-> 0],
      undisclosedPrice         |-> [i \in 1 .. 8 |-> 0],
      disclosedQty             |-> [i \in 1 .. 8 |-> 0],
      orderExpirationTime      |-> [i \in 1 .. 4 |-> 0],
      orderExpirationDate      |-> [i \in 1 .. 2 |-> 0],
      tradingSession           |-> [i \in 1 .. 1 |-> 0],
      stopTriggeredTimeInForce |-> [i \in 1 .. 1 |-> 0],
      undisclosedIcebergType   |-> [i \in 1 .. 1 |-> 0] ]

(* Cancel Replace Optional Field Group at zero, then each field in turn at the values it is checked at *)
CheckedCancelReplaceOptionalFieldGroup ==
    { ZeroCancelReplaceOptionalFieldGroup }
        \cup { [ZeroCancelReplaceOptionalFieldGroup EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceOptionalFieldGroup EXCEPT !.pegOffset = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceOptionalFieldGroup EXCEPT !.undisclosedPrice = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceOptionalFieldGroup EXCEPT !.disclosedQty = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceOptionalFieldGroup EXCEPT !.orderExpirationTime = one] : one \in Sample(4) }
        \cup { [ZeroCancelReplaceOptionalFieldGroup EXCEPT !.orderExpirationDate = one] : one \in Sample(2) }
        \cup { [ZeroCancelReplaceOptionalFieldGroup EXCEPT !.tradingSession = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceOptionalFieldGroup EXCEPT !.stopTriggeredTimeInForce = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceOptionalFieldGroup EXCEPT !.undisclosedIcebergType = one] : one \in Sample(1) }

(* A run of Cancel Replace Optional Field Group, written one after another *)
RECURSIVE EncodeCancelReplaceOptionalFieldGroupList(_)
EncodeCancelReplaceOptionalFieldGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCancelReplaceOptionalFieldGroup(Head(messages)) \o EncodeCancelReplaceOptionalFieldGroupList(Tail(messages))

(* As many Cancel Replace Optional Field Group as the field that counts them says *)
RECURSIVE ReadCancelReplaceOptionalFieldGroupList(_, _)
ReadCancelReplaceOptionalFieldGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeCancelReplaceOptionalFieldGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCancelReplaceOptionalFieldGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Cancel Replace Optional Field Group of each kind, for the lists that carry them *)
OneCancelReplaceOptionalFieldGroup == { ZeroCancelReplaceOptionalFieldGroup }

(***************************************************************************)
(* Cancel Replace Optional Field Groups                                    *)
(***************************************************************************)

CancelReplaceOptionalFieldGroups ==
    [ blockLengthShort                : Sample(1),
      cancelReplaceOptionalFieldGroup : SampleLists(OneCancelReplaceOptionalFieldGroup) ]

EncodeCancelReplaceOptionalFieldGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.cancelReplaceOptionalFieldGroup), 1)
        \o EncodeCancelReplaceOptionalFieldGroupList(message.cancelReplaceOptionalFieldGroup)

DecodeCancelReplaceOptionalFieldGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET cancelReplaceOptionalFieldGroup == ReadCancelReplaceOptionalFieldGroupList(numInGroup.rest, numInGroup.value) IN IF ~cancelReplaceOptionalFieldGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                |-> blockLengthShort.value,
         cancelReplaceOptionalFieldGroup |-> cancelReplaceOptionalFieldGroup.value ], cancelReplaceOptionalFieldGroup.rest)

ZeroCancelReplaceOptionalFieldGroups ==
    [ blockLengthShort                |-> [i \in 1 .. 1 |-> 0],
      cancelReplaceOptionalFieldGroup |-> << >> ]

(* Cancel Replace Optional Field Groups at zero, then each field in turn at the values it is checked at *)
CheckedCancelReplaceOptionalFieldGroups ==
    { ZeroCancelReplaceOptionalFieldGroups }
        \cup { [ZeroCancelReplaceOptionalFieldGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceOptionalFieldGroups EXCEPT !.cancelReplaceOptionalFieldGroup = one] : one \in SampleLists(OneCancelReplaceOptionalFieldGroup) }

(***************************************************************************)
(* Cancel Replace Clearing Fields Group: 33 bytes                          *)
(***************************************************************************)

CancelReplaceClearingFieldsGroup ==
    [ clearingFirmId      : Sample(8),
      clientId            : Sample(8),
      accountNumber       : Sample(12),
      technicalOrigin     : Sample(1),
      openClose           : Sample(2),
      clearingInstruction : Sample(2) ]

EncodeCancelReplaceClearingFieldsGroup(message) ==
    message.clearingFirmId
        \o message.clientId
        \o message.accountNumber
        \o message.technicalOrigin
        \o message.openClose
        \o message.clearingInstruction

DecodeCancelReplaceClearingFieldsGroup(bytes) ==
    LET clearingFirmId == ReadBytes(bytes, 8) IN IF ~clearingFirmId.ok THEN Fail ELSE
    LET clientId == ReadBytes(clearingFirmId.rest, 8) IN IF ~clientId.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(clientId.rest, 12) IN IF ~accountNumber.ok THEN Fail ELSE
    LET technicalOrigin == ReadBytes(accountNumber.rest, 1) IN IF ~technicalOrigin.ok THEN Fail ELSE
    LET openClose == ReadBytes(technicalOrigin.rest, 2) IN IF ~openClose.ok THEN Fail ELSE
    LET clearingInstruction == ReadBytes(openClose.rest, 2) IN IF ~clearingInstruction.ok THEN Fail ELSE
    Ok([ clearingFirmId      |-> clearingFirmId.value,
         clientId            |-> clientId.value,
         accountNumber       |-> accountNumber.value,
         technicalOrigin     |-> technicalOrigin.value,
         openClose           |-> openClose.value,
         clearingInstruction |-> clearingInstruction.value ], clearingInstruction.rest)

ZeroCancelReplaceClearingFieldsGroup ==
    [ clearingFirmId      |-> [i \in 1 .. 8 |-> 0],
      clientId            |-> [i \in 1 .. 8 |-> 0],
      accountNumber       |-> [i \in 1 .. 12 |-> 0],
      technicalOrigin     |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 2 |-> 0],
      clearingInstruction |-> [i \in 1 .. 2 |-> 0] ]

(* Cancel Replace Clearing Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedCancelReplaceClearingFieldsGroup ==
    { ZeroCancelReplaceClearingFieldsGroup }
        \cup { [ZeroCancelReplaceClearingFieldsGroup EXCEPT !.clearingFirmId = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceClearingFieldsGroup EXCEPT !.clientId = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceClearingFieldsGroup EXCEPT !.accountNumber = one] : one \in Sample(12) }
        \cup { [ZeroCancelReplaceClearingFieldsGroup EXCEPT !.technicalOrigin = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceClearingFieldsGroup EXCEPT !.openClose = one] : one \in Sample(2) }
        \cup { [ZeroCancelReplaceClearingFieldsGroup EXCEPT !.clearingInstruction = one] : one \in Sample(2) }

(* A run of Cancel Replace Clearing Fields Group, written one after another *)
RECURSIVE EncodeCancelReplaceClearingFieldsGroupList(_)
EncodeCancelReplaceClearingFieldsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCancelReplaceClearingFieldsGroup(Head(messages)) \o EncodeCancelReplaceClearingFieldsGroupList(Tail(messages))

(* As many Cancel Replace Clearing Fields Group as the field that counts them says *)
RECURSIVE ReadCancelReplaceClearingFieldsGroupList(_, _)
ReadCancelReplaceClearingFieldsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeCancelReplaceClearingFieldsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCancelReplaceClearingFieldsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Cancel Replace Clearing Fields Group of each kind, for the lists that carry them *)
OneCancelReplaceClearingFieldsGroup == { ZeroCancelReplaceClearingFieldsGroup }

(***************************************************************************)
(* Cancel Replace Clearing Fields Groups                                   *)
(***************************************************************************)

CancelReplaceClearingFieldsGroups ==
    [ blockLengthShort                 : Sample(1),
      cancelReplaceClearingFieldsGroup : SampleLists(OneCancelReplaceClearingFieldsGroup) ]

EncodeCancelReplaceClearingFieldsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.cancelReplaceClearingFieldsGroup), 1)
        \o EncodeCancelReplaceClearingFieldsGroupList(message.cancelReplaceClearingFieldsGroup)

DecodeCancelReplaceClearingFieldsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET cancelReplaceClearingFieldsGroup == ReadCancelReplaceClearingFieldsGroupList(numInGroup.rest, numInGroup.value) IN IF ~cancelReplaceClearingFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                 |-> blockLengthShort.value,
         cancelReplaceClearingFieldsGroup |-> cancelReplaceClearingFieldsGroup.value ], cancelReplaceClearingFieldsGroup.rest)

ZeroCancelReplaceClearingFieldsGroups ==
    [ blockLengthShort                 |-> [i \in 1 .. 1 |-> 0],
      cancelReplaceClearingFieldsGroup |-> << >> ]

(* Cancel Replace Clearing Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedCancelReplaceClearingFieldsGroups ==
    { ZeroCancelReplaceClearingFieldsGroups }
        \cup { [ZeroCancelReplaceClearingFieldsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceClearingFieldsGroups EXCEPT !.cancelReplaceClearingFieldsGroup = one] : one \in SampleLists(OneCancelReplaceClearingFieldsGroup) }

(***************************************************************************)
(* Not Used Groups: 2 bytes                                                *)
(***************************************************************************)

NotUsedGroups2 ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeNotUsedGroups2(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeNotUsedGroups2(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroNotUsedGroups2 ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedNotUsedGroups2 ==
    { ZeroNotUsedGroups2 }
        \cup { [ZeroNotUsedGroups2 EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroNotUsedGroups2 EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* Other Not Used Groups: 2 bytes                                          *)
(***************************************************************************)

OtherNotUsedGroups2 ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeOtherNotUsedGroups2(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeOtherNotUsedGroups2(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroOtherNotUsedGroups2 ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Other Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedOtherNotUsedGroups2 ==
    { ZeroOtherNotUsedGroups2 }
        \cup { [ZeroOtherNotUsedGroups2 EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroOtherNotUsedGroups2 EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* Additional Infos Group: 16 bytes                                        *)
(***************************************************************************)

AdditionalInfosGroup2 ==
    [ longClientId : Sample(16) ]

EncodeAdditionalInfosGroup2(message) ==
    message.longClientId

DecodeAdditionalInfosGroup2(bytes) ==
    LET longClientId == ReadBytes(bytes, 16) IN IF ~longClientId.ok THEN Fail ELSE
    Ok([ longClientId |-> longClientId.value ], longClientId.rest)

ZeroAdditionalInfosGroup2 ==
    [ longClientId |-> [i \in 1 .. 16 |-> 0] ]

(* Additional Infos Group at zero, then each field in turn at the values it is checked at *)
CheckedAdditionalInfosGroup2 ==
    { ZeroAdditionalInfosGroup2 }
        \cup { [ZeroAdditionalInfosGroup2 EXCEPT !.longClientId = one] : one \in Sample(16) }

(* A run of Additional Infos Group, written one after another *)
RECURSIVE EncodeAdditionalInfosGroup2List(_)
EncodeAdditionalInfosGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeAdditionalInfosGroup2(Head(messages)) \o EncodeAdditionalInfosGroup2List(Tail(messages))

(* As many Additional Infos Group as the field that counts them says *)
RECURSIVE ReadAdditionalInfosGroup2List(_, _)
ReadAdditionalInfosGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeAdditionalInfosGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadAdditionalInfosGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Additional Infos Group of each kind, for the lists that carry them *)
OneAdditionalInfosGroup2 == { ZeroAdditionalInfosGroup2 }

(***************************************************************************)
(* Additional Infos Groups                                                 *)
(***************************************************************************)

AdditionalInfosGroups2 ==
    [ blockLengthShort     : Sample(1),
      additionalInfosGroup : SampleLists(OneAdditionalInfosGroup2) ]

EncodeAdditionalInfosGroups2(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.additionalInfosGroup), 1)
        \o EncodeAdditionalInfosGroup2List(message.additionalInfosGroup)

DecodeAdditionalInfosGroups2(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET additionalInfosGroup == ReadAdditionalInfosGroup2List(numInGroup.rest, numInGroup.value) IN IF ~additionalInfosGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort     |-> blockLengthShort.value,
         additionalInfosGroup |-> additionalInfosGroup.value ], additionalInfosGroup.rest)

ZeroAdditionalInfosGroups2 ==
    [ blockLengthShort     |-> [i \in 1 .. 1 |-> 0],
      additionalInfosGroup |-> << >> ]

(* Additional Infos Groups at zero, then each field in turn at the values it is checked at *)
CheckedAdditionalInfosGroups2 ==
    { ZeroAdditionalInfosGroups2 }
        \cup { [ZeroAdditionalInfosGroups2 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroAdditionalInfosGroups2 EXCEPT !.additionalInfosGroup = one] : one \in SampleLists(OneAdditionalInfosGroup2) }

(***************************************************************************)
(* Cancel Replace Message                                                  *)
(***************************************************************************)

CancelReplaceMessage ==
    [ clMsgSeqNum                       : Sample(4),
      firmId                            : Sample(8),
      sendingTime                       : Sample(8),
      executionWithinFirmShortCode      : Sample(4),
      clientIdentificationShortcode     : Sample(4),
      clientOrderId                     : Sample(8),
      orderIdOptional                   : Sample(8),
      origClientOrderId                 : Sample(8),
      orderPxOptional                   : Sample(8),
      orderQty                          : Sample(8),
      symbolIndex                       : Sample(4),
      emm                               : Sample(1),
      side                              : Sample(1),
      orderType                         : Sample(1),
      timeInForce                       : Sample(1),
      accountTypeOptional               : Sample(1),
      lpRoleOptional                    : Sample(1),
      executionInstruction              : Sample(1),
      darkExecutionInstruction          : Sample(1),
      mifidIndicators                   : Sample(1),
      stpid                             : Sample(2),
      freeTextGroups                    : FreeTextGroups2,
      cancelReplaceOptionalFieldGroups  : CancelReplaceOptionalFieldGroups,
      cancelReplaceClearingFieldsGroups : CancelReplaceClearingFieldsGroups,
      notUsedGroups                     : NotUsedGroups2,
      otherNotUsedGroups                : OtherNotUsedGroups2,
      additionalInfosGroups             : AdditionalInfosGroups2 ]

EncodeCancelReplaceMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.executionWithinFirmShortCode
        \o message.clientIdentificationShortcode
        \o message.clientOrderId
        \o message.orderIdOptional
        \o message.origClientOrderId
        \o message.orderPxOptional
        \o message.orderQty
        \o message.symbolIndex
        \o message.emm
        \o message.side
        \o message.orderType
        \o message.timeInForce
        \o message.accountTypeOptional
        \o message.lpRoleOptional
        \o message.executionInstruction
        \o message.darkExecutionInstruction
        \o message.mifidIndicators
        \o message.stpid
        \o EncodeFreeTextGroups2(message.freeTextGroups)
        \o EncodeCancelReplaceOptionalFieldGroups(message.cancelReplaceOptionalFieldGroups)
        \o EncodeCancelReplaceClearingFieldsGroups(message.cancelReplaceClearingFieldsGroups)
        \o EncodeNotUsedGroups2(message.notUsedGroups)
        \o EncodeOtherNotUsedGroups2(message.otherNotUsedGroups)
        \o EncodeAdditionalInfosGroups2(message.additionalInfosGroups)

DecodeCancelReplaceMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(sendingTime.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientIdentificationShortcode.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(clientOrderId.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET origClientOrderId == ReadBytes(orderIdOptional.rest, 8) IN IF ~origClientOrderId.ok THEN Fail ELSE
    LET orderPxOptional == ReadBytes(origClientOrderId.rest, 8) IN IF ~orderPxOptional.ok THEN Fail ELSE
    LET orderQty == ReadBytes(orderPxOptional.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(orderQty.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET side == ReadBytes(emm.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderType == ReadBytes(side.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(orderType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET accountTypeOptional == ReadBytes(timeInForce.rest, 1) IN IF ~accountTypeOptional.ok THEN Fail ELSE
    LET lpRoleOptional == ReadBytes(accountTypeOptional.rest, 1) IN IF ~lpRoleOptional.ok THEN Fail ELSE
    LET executionInstruction == ReadBytes(lpRoleOptional.rest, 1) IN IF ~executionInstruction.ok THEN Fail ELSE
    LET darkExecutionInstruction == ReadBytes(executionInstruction.rest, 1) IN IF ~darkExecutionInstruction.ok THEN Fail ELSE
    LET mifidIndicators == ReadBytes(darkExecutionInstruction.rest, 1) IN IF ~mifidIndicators.ok THEN Fail ELSE
    LET stpid == ReadBytes(mifidIndicators.rest, 2) IN IF ~stpid.ok THEN Fail ELSE
    LET freeTextGroups == DecodeFreeTextGroups2(stpid.rest) IN IF ~freeTextGroups.ok THEN Fail ELSE
    LET cancelReplaceOptionalFieldGroups == DecodeCancelReplaceOptionalFieldGroups(freeTextGroups.rest) IN IF ~cancelReplaceOptionalFieldGroups.ok THEN Fail ELSE
    LET cancelReplaceClearingFieldsGroups == DecodeCancelReplaceClearingFieldsGroups(cancelReplaceOptionalFieldGroups.rest) IN IF ~cancelReplaceClearingFieldsGroups.ok THEN Fail ELSE
    LET notUsedGroups == DecodeNotUsedGroups2(cancelReplaceClearingFieldsGroups.rest) IN IF ~notUsedGroups.ok THEN Fail ELSE
    LET otherNotUsedGroups == DecodeOtherNotUsedGroups2(notUsedGroups.rest) IN IF ~otherNotUsedGroups.ok THEN Fail ELSE
    LET additionalInfosGroups == DecodeAdditionalInfosGroups2(otherNotUsedGroups.rest) IN IF ~additionalInfosGroups.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                       |-> clMsgSeqNum.value,
         firmId                            |-> firmId.value,
         sendingTime                       |-> sendingTime.value,
         executionWithinFirmShortCode      |-> executionWithinFirmShortCode.value,
         clientIdentificationShortcode     |-> clientIdentificationShortcode.value,
         clientOrderId                     |-> clientOrderId.value,
         orderIdOptional                   |-> orderIdOptional.value,
         origClientOrderId                 |-> origClientOrderId.value,
         orderPxOptional                   |-> orderPxOptional.value,
         orderQty                          |-> orderQty.value,
         symbolIndex                       |-> symbolIndex.value,
         emm                               |-> emm.value,
         side                              |-> side.value,
         orderType                         |-> orderType.value,
         timeInForce                       |-> timeInForce.value,
         accountTypeOptional               |-> accountTypeOptional.value,
         lpRoleOptional                    |-> lpRoleOptional.value,
         executionInstruction              |-> executionInstruction.value,
         darkExecutionInstruction          |-> darkExecutionInstruction.value,
         mifidIndicators                   |-> mifidIndicators.value,
         stpid                             |-> stpid.value,
         freeTextGroups                    |-> freeTextGroups.value,
         cancelReplaceOptionalFieldGroups  |-> cancelReplaceOptionalFieldGroups.value,
         cancelReplaceClearingFieldsGroups |-> cancelReplaceClearingFieldsGroups.value,
         notUsedGroups                     |-> notUsedGroups.value,
         otherNotUsedGroups                |-> otherNotUsedGroups.value,
         additionalInfosGroups             |-> additionalInfosGroups.value ], additionalInfosGroups.rest)

ZeroCancelReplaceMessage ==
    [ clMsgSeqNum                       |-> [i \in 1 .. 4 |-> 0],
      firmId                            |-> [i \in 1 .. 8 |-> 0],
      sendingTime                       |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode      |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode     |-> [i \in 1 .. 4 |-> 0],
      clientOrderId                     |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional                   |-> [i \in 1 .. 8 |-> 0],
      origClientOrderId                 |-> [i \in 1 .. 8 |-> 0],
      orderPxOptional                   |-> [i \in 1 .. 8 |-> 0],
      orderQty                          |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                       |-> [i \in 1 .. 4 |-> 0],
      emm                               |-> [i \in 1 .. 1 |-> 0],
      side                              |-> [i \in 1 .. 1 |-> 0],
      orderType                         |-> [i \in 1 .. 1 |-> 0],
      timeInForce                       |-> [i \in 1 .. 1 |-> 0],
      accountTypeOptional               |-> [i \in 1 .. 1 |-> 0],
      lpRoleOptional                    |-> [i \in 1 .. 1 |-> 0],
      executionInstruction              |-> [i \in 1 .. 1 |-> 0],
      darkExecutionInstruction          |-> [i \in 1 .. 1 |-> 0],
      mifidIndicators                   |-> [i \in 1 .. 1 |-> 0],
      stpid                             |-> [i \in 1 .. 2 |-> 0],
      freeTextGroups                    |-> ZeroFreeTextGroups2,
      cancelReplaceOptionalFieldGroups  |-> ZeroCancelReplaceOptionalFieldGroups,
      cancelReplaceClearingFieldsGroups |-> ZeroCancelReplaceClearingFieldsGroups,
      notUsedGroups                     |-> ZeroNotUsedGroups2,
      otherNotUsedGroups                |-> ZeroOtherNotUsedGroups2,
      additionalInfosGroups             |-> ZeroAdditionalInfosGroups2 ]

(* Cancel Replace Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelReplaceMessage ==
    { ZeroCancelReplaceMessage }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.origClientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.orderPxOptional = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.accountTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.lpRoleOptional = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.executionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.darkExecutionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.mifidIndicators = one] : one \in Sample(1) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.stpid = one] : one \in Sample(2) }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.freeTextGroups = one] : one \in CheckedFreeTextGroups2 }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.cancelReplaceOptionalFieldGroups = one] : one \in CheckedCancelReplaceOptionalFieldGroups }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.cancelReplaceClearingFieldsGroups = one] : one \in CheckedCancelReplaceClearingFieldsGroups }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.notUsedGroups = one] : one \in CheckedNotUsedGroups2 }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.otherNotUsedGroups = one] : one \in CheckedOtherNotUsedGroups2 }
        \cup { [ZeroCancelReplaceMessage EXCEPT !.additionalInfosGroups = one] : one \in CheckedAdditionalInfosGroups2 }

(***************************************************************************)
(* Collar Fields Group: 9 bytes                                            *)
(***************************************************************************)

CollarFieldsGroup ==
    [ collarRejType       : Sample(1),
      breachedCollarPrice : Sample(8) ]

EncodeCollarFieldsGroup(message) ==
    message.collarRejType
        \o message.breachedCollarPrice

DecodeCollarFieldsGroup(bytes) ==
    LET collarRejType == ReadBytes(bytes, 1) IN IF ~collarRejType.ok THEN Fail ELSE
    LET breachedCollarPrice == ReadBytes(collarRejType.rest, 8) IN IF ~breachedCollarPrice.ok THEN Fail ELSE
    Ok([ collarRejType       |-> collarRejType.value,
         breachedCollarPrice |-> breachedCollarPrice.value ], breachedCollarPrice.rest)

ZeroCollarFieldsGroup ==
    [ collarRejType       |-> [i \in 1 .. 1 |-> 0],
      breachedCollarPrice |-> [i \in 1 .. 8 |-> 0] ]

(* Collar Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedCollarFieldsGroup ==
    { ZeroCollarFieldsGroup }
        \cup { [ZeroCollarFieldsGroup EXCEPT !.collarRejType = one] : one \in Sample(1) }
        \cup { [ZeroCollarFieldsGroup EXCEPT !.breachedCollarPrice = one] : one \in Sample(8) }

(* A run of Collar Fields Group, written one after another *)
RECURSIVE EncodeCollarFieldsGroupList(_)
EncodeCollarFieldsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCollarFieldsGroup(Head(messages)) \o EncodeCollarFieldsGroupList(Tail(messages))

(* As many Collar Fields Group as the field that counts them says *)
RECURSIVE ReadCollarFieldsGroupList(_, _)
ReadCollarFieldsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeCollarFieldsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCollarFieldsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Collar Fields Group of each kind, for the lists that carry them *)
OneCollarFieldsGroup == { ZeroCollarFieldsGroup }

(***************************************************************************)
(* Collar Fields Groups                                                    *)
(***************************************************************************)

CollarFieldsGroups ==
    [ blockLengthShort  : Sample(1),
      collarFieldsGroup : SampleLists(OneCollarFieldsGroup) ]

EncodeCollarFieldsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.collarFieldsGroup), 1)
        \o EncodeCollarFieldsGroupList(message.collarFieldsGroup)

DecodeCollarFieldsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET collarFieldsGroup == ReadCollarFieldsGroupList(numInGroup.rest, numInGroup.value) IN IF ~collarFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort  |-> blockLengthShort.value,
         collarFieldsGroup |-> collarFieldsGroup.value ], collarFieldsGroup.rest)

ZeroCollarFieldsGroups ==
    [ blockLengthShort  |-> [i \in 1 .. 1 |-> 0],
      collarFieldsGroup |-> << >> ]

(* Collar Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedCollarFieldsGroups ==
    { ZeroCollarFieldsGroups }
        \cup { [ZeroCollarFieldsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroCollarFieldsGroups EXCEPT !.collarFieldsGroup = one] : one \in SampleLists(OneCollarFieldsGroup) }

(***************************************************************************)
(* Mifid Fields Group: 9 bytes                                             *)
(***************************************************************************)

MifidFieldsGroup4 ==
    [ executionWithinFirmShortCodeOptional : Sample(4),
      clientIdentificationShortcode        : Sample(4),
      mifidIndicatorsOptional              : Sample(1) ]

EncodeMifidFieldsGroup4(message) ==
    message.executionWithinFirmShortCodeOptional
        \o message.clientIdentificationShortcode
        \o message.mifidIndicatorsOptional

DecodeMifidFieldsGroup4(bytes) ==
    LET executionWithinFirmShortCodeOptional == ReadBytes(bytes, 4) IN IF ~executionWithinFirmShortCodeOptional.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCodeOptional.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET mifidIndicatorsOptional == ReadBytes(clientIdentificationShortcode.rest, 1) IN IF ~mifidIndicatorsOptional.ok THEN Fail ELSE
    Ok([ executionWithinFirmShortCodeOptional |-> executionWithinFirmShortCodeOptional.value,
         clientIdentificationShortcode        |-> clientIdentificationShortcode.value,
         mifidIndicatorsOptional              |-> mifidIndicatorsOptional.value ], mifidIndicatorsOptional.rest)

ZeroMifidFieldsGroup4 ==
    [ executionWithinFirmShortCodeOptional |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode        |-> [i \in 1 .. 4 |-> 0],
      mifidIndicatorsOptional              |-> [i \in 1 .. 1 |-> 0] ]

(* Mifid Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedMifidFieldsGroup4 ==
    { ZeroMifidFieldsGroup4 }
        \cup { [ZeroMifidFieldsGroup4 EXCEPT !.executionWithinFirmShortCodeOptional = one] : one \in Sample(4) }
        \cup { [ZeroMifidFieldsGroup4 EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroMifidFieldsGroup4 EXCEPT !.mifidIndicatorsOptional = one] : one \in Sample(1) }

(* A run of Mifid Fields Group, written one after another *)
RECURSIVE EncodeMifidFieldsGroup4List(_)
EncodeMifidFieldsGroup4List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMifidFieldsGroup4(Head(messages)) \o EncodeMifidFieldsGroup4List(Tail(messages))

(* As many Mifid Fields Group as the field that counts them says *)
RECURSIVE ReadMifidFieldsGroup4List(_, _)
ReadMifidFieldsGroup4List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMifidFieldsGroup4(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMifidFieldsGroup4List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mifid Fields Group of each kind, for the lists that carry them *)
OneMifidFieldsGroup4 == { ZeroMifidFieldsGroup4 }

(***************************************************************************)
(* Mifid Fields Groups                                                     *)
(***************************************************************************)

MifidFieldsGroups4 ==
    [ blockLengthShort : Sample(1),
      mifidFieldsGroup : SampleLists(OneMifidFieldsGroup4) ]

EncodeMifidFieldsGroups4(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.mifidFieldsGroup), 1)
        \o EncodeMifidFieldsGroup4List(message.mifidFieldsGroup)

DecodeMifidFieldsGroups4(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET mifidFieldsGroup == ReadMifidFieldsGroup4List(numInGroup.rest, numInGroup.value) IN IF ~mifidFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         mifidFieldsGroup |-> mifidFieldsGroup.value ], mifidFieldsGroup.rest)

ZeroMifidFieldsGroups4 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      mifidFieldsGroup |-> << >> ]

(* Mifid Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedMifidFieldsGroups4 ==
    { ZeroMifidFieldsGroups4 }
        \cup { [ZeroMifidFieldsGroups4 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroMifidFieldsGroups4 EXCEPT !.mifidFieldsGroup = one] : one \in SampleLists(OneMifidFieldsGroup4) }

(***************************************************************************)
(* Reject Message                                                          *)
(***************************************************************************)

RejectMessage ==
    [ msgSeqNum              : Sample(4),
      firmIdOptional         : Sample(8),
      sendingTimeOptional    : Sample(8),
      oegInFromMember        : Sample(8),
      oegOutTimeToMe         : Sample(8),
      bookInOptional         : Sample(8),
      bookOutTimeOptional    : Sample(8),
      oegInFromMeOptional    : Sample(8),
      oegOutToMemberOptional : Sample(8),
      clientOrderIdOptional  : Sample(8),
      orderIdOptional        : Sample(8),
      symbolIndexOptional    : Sample(4),
      emmOptional            : Sample(1),
      rejectedMessage        : Sample(1),
      errorCode              : Sample(2),
      rejectedMessageId      : Sample(2),
      ackQualifiersOptional  : Sample(1),
      collarFieldsGroups     : CollarFieldsGroups,
      mifidFieldsGroups      : MifidFieldsGroups4 ]

EncodeRejectMessage(message) ==
    message.msgSeqNum
        \o message.firmIdOptional
        \o message.sendingTimeOptional
        \o message.oegInFromMember
        \o message.oegOutTimeToMe
        \o message.bookInOptional
        \o message.bookOutTimeOptional
        \o message.oegInFromMeOptional
        \o message.oegOutToMemberOptional
        \o message.clientOrderIdOptional
        \o message.orderIdOptional
        \o message.symbolIndexOptional
        \o message.emmOptional
        \o message.rejectedMessage
        \o message.errorCode
        \o message.rejectedMessageId
        \o message.ackQualifiersOptional
        \o EncodeCollarFieldsGroups(message.collarFieldsGroups)
        \o EncodeMifidFieldsGroups4(message.mifidFieldsGroups)

DecodeRejectMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmIdOptional == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmIdOptional.ok THEN Fail ELSE
    LET sendingTimeOptional == ReadBytes(firmIdOptional.rest, 8) IN IF ~sendingTimeOptional.ok THEN Fail ELSE
    LET oegInFromMember == ReadBytes(sendingTimeOptional.rest, 8) IN IF ~oegInFromMember.ok THEN Fail ELSE
    LET oegOutTimeToMe == ReadBytes(oegInFromMember.rest, 8) IN IF ~oegOutTimeToMe.ok THEN Fail ELSE
    LET bookInOptional == ReadBytes(oegOutTimeToMe.rest, 8) IN IF ~bookInOptional.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(bookInOptional.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET oegInFromMeOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~oegInFromMeOptional.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(oegInFromMeOptional.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET clientOrderIdOptional == ReadBytes(oegOutToMemberOptional.rest, 8) IN IF ~clientOrderIdOptional.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(clientOrderIdOptional.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET symbolIndexOptional == ReadBytes(orderIdOptional.rest, 4) IN IF ~symbolIndexOptional.ok THEN Fail ELSE
    LET emmOptional == ReadBytes(symbolIndexOptional.rest, 1) IN IF ~emmOptional.ok THEN Fail ELSE
    LET rejectedMessage == ReadBytes(emmOptional.rest, 1) IN IF ~rejectedMessage.ok THEN Fail ELSE
    LET errorCode == ReadBytes(rejectedMessage.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET rejectedMessageId == ReadBytes(errorCode.rest, 2) IN IF ~rejectedMessageId.ok THEN Fail ELSE
    LET ackQualifiersOptional == ReadBytes(rejectedMessageId.rest, 1) IN IF ~ackQualifiersOptional.ok THEN Fail ELSE
    LET collarFieldsGroups == DecodeCollarFieldsGroups(ackQualifiersOptional.rest) IN IF ~collarFieldsGroups.ok THEN Fail ELSE
    LET mifidFieldsGroups == DecodeMifidFieldsGroups4(collarFieldsGroups.rest) IN IF ~mifidFieldsGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum              |-> msgSeqNum.value,
         firmIdOptional         |-> firmIdOptional.value,
         sendingTimeOptional    |-> sendingTimeOptional.value,
         oegInFromMember        |-> oegInFromMember.value,
         oegOutTimeToMe         |-> oegOutTimeToMe.value,
         bookInOptional         |-> bookInOptional.value,
         bookOutTimeOptional    |-> bookOutTimeOptional.value,
         oegInFromMeOptional    |-> oegInFromMeOptional.value,
         oegOutToMemberOptional |-> oegOutToMemberOptional.value,
         clientOrderIdOptional  |-> clientOrderIdOptional.value,
         orderIdOptional        |-> orderIdOptional.value,
         symbolIndexOptional    |-> symbolIndexOptional.value,
         emmOptional            |-> emmOptional.value,
         rejectedMessage        |-> rejectedMessage.value,
         errorCode              |-> errorCode.value,
         rejectedMessageId      |-> rejectedMessageId.value,
         ackQualifiersOptional  |-> ackQualifiersOptional.value,
         collarFieldsGroups     |-> collarFieldsGroups.value,
         mifidFieldsGroups      |-> mifidFieldsGroups.value ], mifidFieldsGroups.rest)

ZeroRejectMessage ==
    [ msgSeqNum              |-> [i \in 1 .. 4 |-> 0],
      firmIdOptional         |-> [i \in 1 .. 8 |-> 0],
      sendingTimeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegInFromMember        |-> [i \in 1 .. 8 |-> 0],
      oegOutTimeToMe         |-> [i \in 1 .. 8 |-> 0],
      bookInOptional         |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegInFromMeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegOutToMemberOptional |-> [i \in 1 .. 8 |-> 0],
      clientOrderIdOptional  |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional        |-> [i \in 1 .. 8 |-> 0],
      symbolIndexOptional    |-> [i \in 1 .. 4 |-> 0],
      emmOptional            |-> [i \in 1 .. 1 |-> 0],
      rejectedMessage        |-> [i \in 1 .. 1 |-> 0],
      errorCode              |-> [i \in 1 .. 2 |-> 0],
      rejectedMessageId      |-> [i \in 1 .. 2 |-> 0],
      ackQualifiersOptional  |-> [i \in 1 .. 1 |-> 0],
      collarFieldsGroups     |-> ZeroCollarFieldsGroups,
      mifidFieldsGroups      |-> ZeroMifidFieldsGroups4 ]

(* Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectMessage ==
    { ZeroRejectMessage }
        \cup { [ZeroRejectMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRejectMessage EXCEPT !.firmIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.sendingTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.oegInFromMember = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.oegOutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.bookInOptional = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.oegInFromMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.clientOrderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroRejectMessage EXCEPT !.symbolIndexOptional = one] : one \in Sample(4) }
        \cup { [ZeroRejectMessage EXCEPT !.emmOptional = one] : one \in Sample(1) }
        \cup { [ZeroRejectMessage EXCEPT !.rejectedMessage = one] : one \in Sample(1) }
        \cup { [ZeroRejectMessage EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroRejectMessage EXCEPT !.rejectedMessageId = one] : one \in Sample(2) }
        \cup { [ZeroRejectMessage EXCEPT !.ackQualifiersOptional = one] : one \in Sample(1) }
        \cup { [ZeroRejectMessage EXCEPT !.collarFieldsGroups = one] : one \in CheckedCollarFieldsGroups }
        \cup { [ZeroRejectMessage EXCEPT !.mifidFieldsGroups = one] : one \in CheckedMifidFieldsGroups4 }

(***************************************************************************)
(* Mifid Short Codes Group: 12 bytes                                       *)
(***************************************************************************)

MifidShortCodesGroup2 ==
    [ investmentDecisionWFirmShortCode : Sample(4),
      nonExecutingBrokerShortCode      : Sample(4),
      clientIdentificationShortcode    : Sample(4) ]

EncodeMifidShortCodesGroup2(message) ==
    message.investmentDecisionWFirmShortCode
        \o message.nonExecutingBrokerShortCode
        \o message.clientIdentificationShortcode

DecodeMifidShortCodesGroup2(bytes) ==
    LET investmentDecisionWFirmShortCode == ReadBytes(bytes, 4) IN IF ~investmentDecisionWFirmShortCode.ok THEN Fail ELSE
    LET nonExecutingBrokerShortCode == ReadBytes(investmentDecisionWFirmShortCode.rest, 4) IN IF ~nonExecutingBrokerShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(nonExecutingBrokerShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    Ok([ investmentDecisionWFirmShortCode |-> investmentDecisionWFirmShortCode.value,
         nonExecutingBrokerShortCode      |-> nonExecutingBrokerShortCode.value,
         clientIdentificationShortcode    |-> clientIdentificationShortcode.value ], clientIdentificationShortcode.rest)

ZeroMifidShortCodesGroup2 ==
    [ investmentDecisionWFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      nonExecutingBrokerShortCode      |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode    |-> [i \in 1 .. 4 |-> 0] ]

(* Mifid Short Codes Group at zero, then each field in turn at the values it is checked at *)
CheckedMifidShortCodesGroup2 ==
    { ZeroMifidShortCodesGroup2 }
        \cup { [ZeroMifidShortCodesGroup2 EXCEPT !.investmentDecisionWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroMifidShortCodesGroup2 EXCEPT !.nonExecutingBrokerShortCode = one] : one \in Sample(4) }
        \cup { [ZeroMifidShortCodesGroup2 EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }

(* A run of Mifid Short Codes Group, written one after another *)
RECURSIVE EncodeMifidShortCodesGroup2List(_)
EncodeMifidShortCodesGroup2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMifidShortCodesGroup2(Head(messages)) \o EncodeMifidShortCodesGroup2List(Tail(messages))

(* As many Mifid Short Codes Group as the field that counts them says *)
RECURSIVE ReadMifidShortCodesGroup2List(_, _)
ReadMifidShortCodesGroup2List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMifidShortCodesGroup2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMifidShortCodesGroup2List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mifid Short Codes Group of each kind, for the lists that carry them *)
OneMifidShortCodesGroup2 == { ZeroMifidShortCodesGroup2 }

(***************************************************************************)
(* Mifid Short Codes Groups                                                *)
(***************************************************************************)

MifidShortCodesGroups2 ==
    [ blockLengthShort     : Sample(1),
      mifidShortCodesGroup : SampleLists(OneMifidShortCodesGroup2) ]

EncodeMifidShortCodesGroups2(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.mifidShortCodesGroup), 1)
        \o EncodeMifidShortCodesGroup2List(message.mifidShortCodesGroup)

DecodeMifidShortCodesGroups2(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET mifidShortCodesGroup == ReadMifidShortCodesGroup2List(numInGroup.rest, numInGroup.value) IN IF ~mifidShortCodesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort     |-> blockLengthShort.value,
         mifidShortCodesGroup |-> mifidShortCodesGroup.value ], mifidShortCodesGroup.rest)

ZeroMifidShortCodesGroups2 ==
    [ blockLengthShort     |-> [i \in 1 .. 1 |-> 0],
      mifidShortCodesGroup |-> << >> ]

(* Mifid Short Codes Groups at zero, then each field in turn at the values it is checked at *)
CheckedMifidShortCodesGroups2 ==
    { ZeroMifidShortCodesGroups2 }
        \cup { [ZeroMifidShortCodesGroups2 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroMifidShortCodesGroups2 EXCEPT !.mifidShortCodesGroup = one] : one \in SampleLists(OneMifidShortCodesGroup2) }

(***************************************************************************)
(* Clearing Dataset Group: 51 bytes                                        *)
(***************************************************************************)

ClearingDatasetGroup ==
    [ clearingFirmId      : Sample(8),
      clientId            : Sample(8),
      accountNumber       : Sample(12),
      technicalOrigin     : Sample(1),
      openClose           : Sample(2),
      clearingInstruction : Sample(2),
      freeText            : Sample(18) ]

EncodeClearingDatasetGroup(message) ==
    message.clearingFirmId
        \o message.clientId
        \o message.accountNumber
        \o message.technicalOrigin
        \o message.openClose
        \o message.clearingInstruction
        \o message.freeText

DecodeClearingDatasetGroup(bytes) ==
    LET clearingFirmId == ReadBytes(bytes, 8) IN IF ~clearingFirmId.ok THEN Fail ELSE
    LET clientId == ReadBytes(clearingFirmId.rest, 8) IN IF ~clientId.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(clientId.rest, 12) IN IF ~accountNumber.ok THEN Fail ELSE
    LET technicalOrigin == ReadBytes(accountNumber.rest, 1) IN IF ~technicalOrigin.ok THEN Fail ELSE
    LET openClose == ReadBytes(technicalOrigin.rest, 2) IN IF ~openClose.ok THEN Fail ELSE
    LET clearingInstruction == ReadBytes(openClose.rest, 2) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET freeText == ReadBytes(clearingInstruction.rest, 18) IN IF ~freeText.ok THEN Fail ELSE
    Ok([ clearingFirmId      |-> clearingFirmId.value,
         clientId            |-> clientId.value,
         accountNumber       |-> accountNumber.value,
         technicalOrigin     |-> technicalOrigin.value,
         openClose           |-> openClose.value,
         clearingInstruction |-> clearingInstruction.value,
         freeText            |-> freeText.value ], freeText.rest)

ZeroClearingDatasetGroup ==
    [ clearingFirmId      |-> [i \in 1 .. 8 |-> 0],
      clientId            |-> [i \in 1 .. 8 |-> 0],
      accountNumber       |-> [i \in 1 .. 12 |-> 0],
      technicalOrigin     |-> [i \in 1 .. 1 |-> 0],
      openClose           |-> [i \in 1 .. 2 |-> 0],
      clearingInstruction |-> [i \in 1 .. 2 |-> 0],
      freeText            |-> [i \in 1 .. 18 |-> 0] ]

(* Clearing Dataset Group at zero, then each field in turn at the values it is checked at *)
CheckedClearingDatasetGroup ==
    { ZeroClearingDatasetGroup }
        \cup { [ZeroClearingDatasetGroup EXCEPT !.clearingFirmId = one] : one \in Sample(8) }
        \cup { [ZeroClearingDatasetGroup EXCEPT !.clientId = one] : one \in Sample(8) }
        \cup { [ZeroClearingDatasetGroup EXCEPT !.accountNumber = one] : one \in Sample(12) }
        \cup { [ZeroClearingDatasetGroup EXCEPT !.technicalOrigin = one] : one \in Sample(1) }
        \cup { [ZeroClearingDatasetGroup EXCEPT !.openClose = one] : one \in Sample(2) }
        \cup { [ZeroClearingDatasetGroup EXCEPT !.clearingInstruction = one] : one \in Sample(2) }
        \cup { [ZeroClearingDatasetGroup EXCEPT !.freeText = one] : one \in Sample(18) }

(* A run of Clearing Dataset Group, written one after another *)
RECURSIVE EncodeClearingDatasetGroupList(_)
EncodeClearingDatasetGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClearingDatasetGroup(Head(messages)) \o EncodeClearingDatasetGroupList(Tail(messages))

(* As many Clearing Dataset Group as the field that counts them says *)
RECURSIVE ReadClearingDatasetGroupList(_, _)
ReadClearingDatasetGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeClearingDatasetGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClearingDatasetGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Clearing Dataset Group of each kind, for the lists that carry them *)
OneClearingDatasetGroup == { ZeroClearingDatasetGroup }

(***************************************************************************)
(* Clearing Dataset Groups                                                 *)
(***************************************************************************)

ClearingDatasetGroups ==
    [ blockLengthShort     : Sample(1),
      clearingDatasetGroup : SampleLists(OneClearingDatasetGroup) ]

EncodeClearingDatasetGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.clearingDatasetGroup), 1)
        \o EncodeClearingDatasetGroupList(message.clearingDatasetGroup)

DecodeClearingDatasetGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET clearingDatasetGroup == ReadClearingDatasetGroupList(numInGroup.rest, numInGroup.value) IN IF ~clearingDatasetGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort     |-> blockLengthShort.value,
         clearingDatasetGroup |-> clearingDatasetGroup.value ], clearingDatasetGroup.rest)

ZeroClearingDatasetGroups ==
    [ blockLengthShort     |-> [i \in 1 .. 1 |-> 0],
      clearingDatasetGroup |-> << >> ]

(* Clearing Dataset Groups at zero, then each field in turn at the values it is checked at *)
CheckedClearingDatasetGroups ==
    { ZeroClearingDatasetGroups }
        \cup { [ZeroClearingDatasetGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroClearingDatasetGroups EXCEPT !.clearingDatasetGroup = one] : one \in SampleLists(OneClearingDatasetGroup) }

(***************************************************************************)
(* Quotes Rep Group: 37 bytes                                              *)
(***************************************************************************)

QuotesRepGroup ==
    [ bidSize     : Sample(8),
      bidPx       : Sample(8),
      offerSize   : Sample(8),
      offerPx     : Sample(8),
      symbolIndex : Sample(4),
      emm         : Sample(1) ]

EncodeQuotesRepGroup(message) ==
    message.bidSize
        \o message.bidPx
        \o message.offerSize
        \o message.offerPx
        \o message.symbolIndex
        \o message.emm

DecodeQuotesRepGroup(bytes) ==
    LET bidSize == ReadBytes(bytes, 8) IN IF ~bidSize.ok THEN Fail ELSE
    LET bidPx == ReadBytes(bidSize.rest, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidPx.rest, 8) IN IF ~offerSize.ok THEN Fail ELSE
    LET offerPx == ReadBytes(offerSize.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(offerPx.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    Ok([ bidSize     |-> bidSize.value,
         bidPx       |-> bidPx.value,
         offerSize   |-> offerSize.value,
         offerPx     |-> offerPx.value,
         symbolIndex |-> symbolIndex.value,
         emm         |-> emm.value ], emm.rest)

ZeroQuotesRepGroup ==
    [ bidSize     |-> [i \in 1 .. 8 |-> 0],
      bidPx       |-> [i \in 1 .. 8 |-> 0],
      offerSize   |-> [i \in 1 .. 8 |-> 0],
      offerPx     |-> [i \in 1 .. 8 |-> 0],
      symbolIndex |-> [i \in 1 .. 4 |-> 0],
      emm         |-> [i \in 1 .. 1 |-> 0] ]

(* Quotes Rep Group at zero, then each field in turn at the values it is checked at *)
CheckedQuotesRepGroup ==
    { ZeroQuotesRepGroup }
        \cup { [ZeroQuotesRepGroup EXCEPT !.bidSize = one] : one \in Sample(8) }
        \cup { [ZeroQuotesRepGroup EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroQuotesRepGroup EXCEPT !.offerSize = one] : one \in Sample(8) }
        \cup { [ZeroQuotesRepGroup EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroQuotesRepGroup EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroQuotesRepGroup EXCEPT !.emm = one] : one \in Sample(1) }

(* A run of Quotes Rep Group, written one after another *)
RECURSIVE EncodeQuotesRepGroupList(_)
EncodeQuotesRepGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuotesRepGroup(Head(messages)) \o EncodeQuotesRepGroupList(Tail(messages))

(* As many Quotes Rep Group as the field that counts them says *)
RECURSIVE ReadQuotesRepGroupList(_, _)
ReadQuotesRepGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuotesRepGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuotesRepGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quotes Rep Group of each kind, for the lists that carry them *)
OneQuotesRepGroup == { ZeroQuotesRepGroup }

(***************************************************************************)
(* Quotes Rep Groups                                                       *)
(***************************************************************************)

QuotesRepGroups ==
    [ blockLengthShort : Sample(1),
      quotesRepGroup   : SampleLists(OneQuotesRepGroup) ]

EncodeQuotesRepGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.quotesRepGroup), 1)
        \o EncodeQuotesRepGroupList(message.quotesRepGroup)

DecodeQuotesRepGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET quotesRepGroup == ReadQuotesRepGroupList(numInGroup.rest, numInGroup.value) IN IF ~quotesRepGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         quotesRepGroup   |-> quotesRepGroup.value ], quotesRepGroup.rest)

ZeroQuotesRepGroups ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      quotesRepGroup   |-> << >> ]

(* Quotes Rep Groups at zero, then each field in turn at the values it is checked at *)
CheckedQuotesRepGroups ==
    { ZeroQuotesRepGroups }
        \cup { [ZeroQuotesRepGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroQuotesRepGroups EXCEPT !.quotesRepGroup = one] : one \in SampleLists(OneQuotesRepGroup) }

(***************************************************************************)
(* Quotes Message                                                          *)
(***************************************************************************)

QuotesMessage ==
    [ clMsgSeqNum                  : Sample(4),
      firmId                       : Sample(8),
      sendingTime                  : Sample(8),
      clientOrderId                : Sample(8),
      executionWithinFirmShortCode : Sample(4),
      tradingCapacity              : Sample(1),
      accountType                  : Sample(1),
      lpRole                       : Sample(1),
      mifidIndicators              : Sample(1),
      rfeAnswer                    : Sample(1),
      executionInstructionOptional : Sample(1),
      stpid                        : Sample(2),
      mifidShortCodesGroups        : MifidShortCodesGroups2,
      clearingDatasetGroups        : ClearingDatasetGroups,
      quotesRepGroups              : QuotesRepGroups ]

EncodeQuotesMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.clientOrderId
        \o message.executionWithinFirmShortCode
        \o message.tradingCapacity
        \o message.accountType
        \o message.lpRole
        \o message.mifidIndicators
        \o message.rfeAnswer
        \o message.executionInstructionOptional
        \o message.stpid
        \o EncodeMifidShortCodesGroups2(message.mifidShortCodesGroups)
        \o EncodeClearingDatasetGroups(message.clearingDatasetGroups)
        \o EncodeQuotesRepGroups(message.quotesRepGroups)

DecodeQuotesMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(sendingTime.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(clientOrderId.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(executionWithinFirmShortCode.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET accountType == ReadBytes(tradingCapacity.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET lpRole == ReadBytes(accountType.rest, 1) IN IF ~lpRole.ok THEN Fail ELSE
    LET mifidIndicators == ReadBytes(lpRole.rest, 1) IN IF ~mifidIndicators.ok THEN Fail ELSE
    LET rfeAnswer == ReadBytes(mifidIndicators.rest, 1) IN IF ~rfeAnswer.ok THEN Fail ELSE
    LET executionInstructionOptional == ReadBytes(rfeAnswer.rest, 1) IN IF ~executionInstructionOptional.ok THEN Fail ELSE
    LET stpid == ReadBytes(executionInstructionOptional.rest, 2) IN IF ~stpid.ok THEN Fail ELSE
    LET mifidShortCodesGroups == DecodeMifidShortCodesGroups2(stpid.rest) IN IF ~mifidShortCodesGroups.ok THEN Fail ELSE
    LET clearingDatasetGroups == DecodeClearingDatasetGroups(mifidShortCodesGroups.rest) IN IF ~clearingDatasetGroups.ok THEN Fail ELSE
    LET quotesRepGroups == DecodeQuotesRepGroups(clearingDatasetGroups.rest) IN IF ~quotesRepGroups.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                  |-> clMsgSeqNum.value,
         firmId                       |-> firmId.value,
         sendingTime                  |-> sendingTime.value,
         clientOrderId                |-> clientOrderId.value,
         executionWithinFirmShortCode |-> executionWithinFirmShortCode.value,
         tradingCapacity              |-> tradingCapacity.value,
         accountType                  |-> accountType.value,
         lpRole                       |-> lpRole.value,
         mifidIndicators              |-> mifidIndicators.value,
         rfeAnswer                    |-> rfeAnswer.value,
         executionInstructionOptional |-> executionInstructionOptional.value,
         stpid                        |-> stpid.value,
         mifidShortCodesGroups        |-> mifidShortCodesGroups.value,
         clearingDatasetGroups        |-> clearingDatasetGroups.value,
         quotesRepGroups              |-> quotesRepGroups.value ], quotesRepGroups.rest)

ZeroQuotesMessage ==
    [ clMsgSeqNum                  |-> [i \in 1 .. 4 |-> 0],
      firmId                       |-> [i \in 1 .. 8 |-> 0],
      sendingTime                  |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      tradingCapacity              |-> [i \in 1 .. 1 |-> 0],
      accountType                  |-> [i \in 1 .. 1 |-> 0],
      lpRole                       |-> [i \in 1 .. 1 |-> 0],
      mifidIndicators              |-> [i \in 1 .. 1 |-> 0],
      rfeAnswer                    |-> [i \in 1 .. 1 |-> 0],
      executionInstructionOptional |-> [i \in 1 .. 1 |-> 0],
      stpid                        |-> [i \in 1 .. 2 |-> 0],
      mifidShortCodesGroups        |-> ZeroMifidShortCodesGroups2,
      clearingDatasetGroups        |-> ZeroClearingDatasetGroups,
      quotesRepGroups              |-> ZeroQuotesRepGroups ]

(* Quotes Message at zero, then each field in turn at the values it is checked at *)
CheckedQuotesMessage ==
    { ZeroQuotesMessage }
        \cup { [ZeroQuotesMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroQuotesMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroQuotesMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroQuotesMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroQuotesMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroQuotesMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroQuotesMessage EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroQuotesMessage EXCEPT !.lpRole = one] : one \in Sample(1) }
        \cup { [ZeroQuotesMessage EXCEPT !.mifidIndicators = one] : one \in Sample(1) }
        \cup { [ZeroQuotesMessage EXCEPT !.rfeAnswer = one] : one \in Sample(1) }
        \cup { [ZeroQuotesMessage EXCEPT !.executionInstructionOptional = one] : one \in Sample(1) }
        \cup { [ZeroQuotesMessage EXCEPT !.stpid = one] : one \in Sample(2) }
        \cup { [ZeroQuotesMessage EXCEPT !.mifidShortCodesGroups = one] : one \in CheckedMifidShortCodesGroups2 }
        \cup { [ZeroQuotesMessage EXCEPT !.clearingDatasetGroups = one] : one \in CheckedClearingDatasetGroups }
        \cup { [ZeroQuotesMessage EXCEPT !.quotesRepGroups = one] : one \in CheckedQuotesRepGroups }

(***************************************************************************)
(* Quote Acks Group: 27 bytes                                              *)
(***************************************************************************)

QuoteAcksGroup ==
    [ bidOrderId       : Sample(8),
      offerOrderId     : Sample(8),
      symbolIndex      : Sample(4),
      emm              : Sample(1),
      buyRevisionFlag  : Sample(1),
      sellRevisionFlag : Sample(1),
      bidErrorCode     : Sample(2),
      offerErrorCode   : Sample(2) ]

EncodeQuoteAcksGroup(message) ==
    message.bidOrderId
        \o message.offerOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.buyRevisionFlag
        \o message.sellRevisionFlag
        \o message.bidErrorCode
        \o message.offerErrorCode

DecodeQuoteAcksGroup(bytes) ==
    LET bidOrderId == ReadBytes(bytes, 8) IN IF ~bidOrderId.ok THEN Fail ELSE
    LET offerOrderId == ReadBytes(bidOrderId.rest, 8) IN IF ~offerOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(offerOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET buyRevisionFlag == ReadBytes(emm.rest, 1) IN IF ~buyRevisionFlag.ok THEN Fail ELSE
    LET sellRevisionFlag == ReadBytes(buyRevisionFlag.rest, 1) IN IF ~sellRevisionFlag.ok THEN Fail ELSE
    LET bidErrorCode == ReadBytes(sellRevisionFlag.rest, 2) IN IF ~bidErrorCode.ok THEN Fail ELSE
    LET offerErrorCode == ReadBytes(bidErrorCode.rest, 2) IN IF ~offerErrorCode.ok THEN Fail ELSE
    Ok([ bidOrderId       |-> bidOrderId.value,
         offerOrderId     |-> offerOrderId.value,
         symbolIndex      |-> symbolIndex.value,
         emm              |-> emm.value,
         buyRevisionFlag  |-> buyRevisionFlag.value,
         sellRevisionFlag |-> sellRevisionFlag.value,
         bidErrorCode     |-> bidErrorCode.value,
         offerErrorCode   |-> offerErrorCode.value ], offerErrorCode.rest)

ZeroQuoteAcksGroup ==
    [ bidOrderId       |-> [i \in 1 .. 8 |-> 0],
      offerOrderId     |-> [i \in 1 .. 8 |-> 0],
      symbolIndex      |-> [i \in 1 .. 4 |-> 0],
      emm              |-> [i \in 1 .. 1 |-> 0],
      buyRevisionFlag  |-> [i \in 1 .. 1 |-> 0],
      sellRevisionFlag |-> [i \in 1 .. 1 |-> 0],
      bidErrorCode     |-> [i \in 1 .. 2 |-> 0],
      offerErrorCode   |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Acks Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteAcksGroup ==
    { ZeroQuoteAcksGroup }
        \cup { [ZeroQuoteAcksGroup EXCEPT !.bidOrderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAcksGroup EXCEPT !.offerOrderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAcksGroup EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroQuoteAcksGroup EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAcksGroup EXCEPT !.buyRevisionFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAcksGroup EXCEPT !.sellRevisionFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAcksGroup EXCEPT !.bidErrorCode = one] : one \in Sample(2) }
        \cup { [ZeroQuoteAcksGroup EXCEPT !.offerErrorCode = one] : one \in Sample(2) }

(* A run of Quote Acks Group, written one after another *)
RECURSIVE EncodeQuoteAcksGroupList(_)
EncodeQuoteAcksGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteAcksGroup(Head(messages)) \o EncodeQuoteAcksGroupList(Tail(messages))

(* As many Quote Acks Group as the field that counts them says *)
RECURSIVE ReadQuoteAcksGroupList(_, _)
ReadQuoteAcksGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteAcksGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteAcksGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Acks Group of each kind, for the lists that carry them *)
OneQuoteAcksGroup == { ZeroQuoteAcksGroup }

(***************************************************************************)
(* Quote Acks Groups                                                       *)
(***************************************************************************)

QuoteAcksGroups ==
    [ blockLengthShort : Sample(1),
      quoteAcksGroup   : SampleLists(OneQuoteAcksGroup) ]

EncodeQuoteAcksGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.quoteAcksGroup), 1)
        \o EncodeQuoteAcksGroupList(message.quoteAcksGroup)

DecodeQuoteAcksGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET quoteAcksGroup == ReadQuoteAcksGroupList(numInGroup.rest, numInGroup.value) IN IF ~quoteAcksGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         quoteAcksGroup   |-> quoteAcksGroup.value ], quoteAcksGroup.rest)

ZeroQuoteAcksGroups ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      quoteAcksGroup   |-> << >> ]

(* Quote Acks Groups at zero, then each field in turn at the values it is checked at *)
CheckedQuoteAcksGroups ==
    { ZeroQuoteAcksGroups }
        \cup { [ZeroQuoteAcksGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAcksGroups EXCEPT !.quoteAcksGroup = one] : one \in SampleLists(OneQuoteAcksGroup) }

(***************************************************************************)
(* Quote Ack Message                                                       *)
(***************************************************************************)

QuoteAckMessage ==
    [ msgSeqNum                            : Sample(4),
      firmId                               : Sample(8),
      sendingTimeOptional                  : Sample(8),
      oegInFromMember                      : Sample(8),
      oegOutTimeToMe                       : Sample(8),
      bookIn                               : Sample(8),
      bookOutTimeOptional                  : Sample(8),
      oegInFromMeOptional                  : Sample(8),
      oegOutToMemberOptional               : Sample(8),
      clientOrderId                        : Sample(8),
      accountType                          : Sample(1),
      lpRole                               : Sample(1),
      executionWithinFirmShortCodeOptional : Sample(4),
      ackQualifiersOptional                : Sample(1),
      quoteAcksGroups                      : QuoteAcksGroups ]

EncodeQuoteAckMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.sendingTimeOptional
        \o message.oegInFromMember
        \o message.oegOutTimeToMe
        \o message.bookIn
        \o message.bookOutTimeOptional
        \o message.oegInFromMeOptional
        \o message.oegOutToMemberOptional
        \o message.clientOrderId
        \o message.accountType
        \o message.lpRole
        \o message.executionWithinFirmShortCodeOptional
        \o message.ackQualifiersOptional
        \o EncodeQuoteAcksGroups(message.quoteAcksGroups)

DecodeQuoteAckMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTimeOptional == ReadBytes(firmId.rest, 8) IN IF ~sendingTimeOptional.ok THEN Fail ELSE
    LET oegInFromMember == ReadBytes(sendingTimeOptional.rest, 8) IN IF ~oegInFromMember.ok THEN Fail ELSE
    LET oegOutTimeToMe == ReadBytes(oegInFromMember.rest, 8) IN IF ~oegOutTimeToMe.ok THEN Fail ELSE
    LET bookIn == ReadBytes(oegOutTimeToMe.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET oegInFromMeOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~oegInFromMeOptional.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(oegInFromMeOptional.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(oegOutToMemberOptional.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET accountType == ReadBytes(clientOrderId.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET lpRole == ReadBytes(accountType.rest, 1) IN IF ~lpRole.ok THEN Fail ELSE
    LET executionWithinFirmShortCodeOptional == ReadBytes(lpRole.rest, 4) IN IF ~executionWithinFirmShortCodeOptional.ok THEN Fail ELSE
    LET ackQualifiersOptional == ReadBytes(executionWithinFirmShortCodeOptional.rest, 1) IN IF ~ackQualifiersOptional.ok THEN Fail ELSE
    LET quoteAcksGroups == DecodeQuoteAcksGroups(ackQualifiersOptional.rest) IN IF ~quoteAcksGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                            |-> msgSeqNum.value,
         firmId                               |-> firmId.value,
         sendingTimeOptional                  |-> sendingTimeOptional.value,
         oegInFromMember                      |-> oegInFromMember.value,
         oegOutTimeToMe                       |-> oegOutTimeToMe.value,
         bookIn                               |-> bookIn.value,
         bookOutTimeOptional                  |-> bookOutTimeOptional.value,
         oegInFromMeOptional                  |-> oegInFromMeOptional.value,
         oegOutToMemberOptional               |-> oegOutToMemberOptional.value,
         clientOrderId                        |-> clientOrderId.value,
         accountType                          |-> accountType.value,
         lpRole                               |-> lpRole.value,
         executionWithinFirmShortCodeOptional |-> executionWithinFirmShortCodeOptional.value,
         ackQualifiersOptional                |-> ackQualifiersOptional.value,
         quoteAcksGroups                      |-> quoteAcksGroups.value ], quoteAcksGroups.rest)

ZeroQuoteAckMessage ==
    [ msgSeqNum                            |-> [i \in 1 .. 4 |-> 0],
      firmId                               |-> [i \in 1 .. 8 |-> 0],
      sendingTimeOptional                  |-> [i \in 1 .. 8 |-> 0],
      oegInFromMember                      |-> [i \in 1 .. 8 |-> 0],
      oegOutTimeToMe                       |-> [i \in 1 .. 8 |-> 0],
      bookIn                               |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional                  |-> [i \in 1 .. 8 |-> 0],
      oegInFromMeOptional                  |-> [i \in 1 .. 8 |-> 0],
      oegOutToMemberOptional               |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                        |-> [i \in 1 .. 8 |-> 0],
      accountType                          |-> [i \in 1 .. 1 |-> 0],
      lpRole                               |-> [i \in 1 .. 1 |-> 0],
      executionWithinFirmShortCodeOptional |-> [i \in 1 .. 4 |-> 0],
      ackQualifiersOptional                |-> [i \in 1 .. 1 |-> 0],
      quoteAcksGroups                      |-> ZeroQuoteAcksGroups ]

(* Quote Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteAckMessage ==
    { ZeroQuoteAckMessage }
        \cup { [ZeroQuoteAckMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.sendingTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.oegInFromMember = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.oegOutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.oegInFromMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.lpRole = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.executionWithinFirmShortCodeOptional = one] : one \in Sample(4) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.ackQualifiersOptional = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAckMessage EXCEPT !.quoteAcksGroups = one] : one \in CheckedQuoteAcksGroups }

(***************************************************************************)
(* Quote Request Message: 72 bytes                                         *)
(***************************************************************************)

QuoteRequestMessage ==
    [ clMsgSeqNum                   : Sample(4),
      firmId                        : Sample(8),
      sendingTime                   : Sample(8),
      executionWithinFirmShortCode  : Sample(4),
      clientIdentificationShortcode : Sample(4),
      clientOrderId                 : Sample(8),
      orderQty                      : Sample(8),
      symbolIndex                   : Sample(4),
      emm                           : Sample(1),
      sideOptional                  : Sample(1),
      firmIdPublication             : Sample(1),
      endClient                     : Sample(11),
      darkExecutionInstruction      : Sample(1),
      minOrderQty                   : Sample(8),
      accountTypeOptional           : Sample(1) ]

EncodeQuoteRequestMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.executionWithinFirmShortCode
        \o message.clientIdentificationShortcode
        \o message.clientOrderId
        \o message.orderQty
        \o message.symbolIndex
        \o message.emm
        \o message.sideOptional
        \o message.firmIdPublication
        \o message.endClient
        \o message.darkExecutionInstruction
        \o message.minOrderQty
        \o message.accountTypeOptional

DecodeQuoteRequestMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(sendingTime.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientIdentificationShortcode.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(clientOrderId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(orderQty.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(emm.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET firmIdPublication == ReadBytes(sideOptional.rest, 1) IN IF ~firmIdPublication.ok THEN Fail ELSE
    LET endClient == ReadBytes(firmIdPublication.rest, 11) IN IF ~endClient.ok THEN Fail ELSE
    LET darkExecutionInstruction == ReadBytes(endClient.rest, 1) IN IF ~darkExecutionInstruction.ok THEN Fail ELSE
    LET minOrderQty == ReadBytes(darkExecutionInstruction.rest, 8) IN IF ~minOrderQty.ok THEN Fail ELSE
    LET accountTypeOptional == ReadBytes(minOrderQty.rest, 1) IN IF ~accountTypeOptional.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                   |-> clMsgSeqNum.value,
         firmId                        |-> firmId.value,
         sendingTime                   |-> sendingTime.value,
         executionWithinFirmShortCode  |-> executionWithinFirmShortCode.value,
         clientIdentificationShortcode |-> clientIdentificationShortcode.value,
         clientOrderId                 |-> clientOrderId.value,
         orderQty                      |-> orderQty.value,
         symbolIndex                   |-> symbolIndex.value,
         emm                           |-> emm.value,
         sideOptional                  |-> sideOptional.value,
         firmIdPublication             |-> firmIdPublication.value,
         endClient                     |-> endClient.value,
         darkExecutionInstruction      |-> darkExecutionInstruction.value,
         minOrderQty                   |-> minOrderQty.value,
         accountTypeOptional           |-> accountTypeOptional.value ], accountTypeOptional.rest)

ZeroQuoteRequestMessage ==
    [ clMsgSeqNum                   |-> [i \in 1 .. 4 |-> 0],
      firmId                        |-> [i \in 1 .. 8 |-> 0],
      sendingTime                   |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode  |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode |-> [i \in 1 .. 4 |-> 0],
      clientOrderId                 |-> [i \in 1 .. 8 |-> 0],
      orderQty                      |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                   |-> [i \in 1 .. 4 |-> 0],
      emm                           |-> [i \in 1 .. 1 |-> 0],
      sideOptional                  |-> [i \in 1 .. 1 |-> 0],
      firmIdPublication             |-> [i \in 1 .. 1 |-> 0],
      endClient                     |-> [i \in 1 .. 11 |-> 0],
      darkExecutionInstruction      |-> [i \in 1 .. 1 |-> 0],
      minOrderQty                   |-> [i \in 1 .. 8 |-> 0],
      accountTypeOptional           |-> [i \in 1 .. 1 |-> 0] ]

(* Quote Request Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestMessage ==
    { ZeroQuoteRequestMessage }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.firmIdPublication = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.endClient = one] : one \in Sample(11) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.darkExecutionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.minOrderQty = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.accountTypeOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Not Used Groups: 2 bytes                                                *)
(***************************************************************************)

NotUsedGroups3 ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeNotUsedGroups3(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeNotUsedGroups3(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroNotUsedGroups3 ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedNotUsedGroups3 ==
    { ZeroNotUsedGroups3 }
        \cup { [ZeroNotUsedGroups3 EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroNotUsedGroups3 EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* Other Not Used Groups: 2 bytes                                          *)
(***************************************************************************)

OtherNotUsedGroups3 ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeOtherNotUsedGroups3(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeOtherNotUsedGroups3(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroOtherNotUsedGroups3 ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Other Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedOtherNotUsedGroups3 ==
    { ZeroOtherNotUsedGroups3 }
        \cup { [ZeroOtherNotUsedGroups3 EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroOtherNotUsedGroups3 EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* Cancel Request Message: 64 bytes                                        *)
(***************************************************************************)

CancelRequestMessage ==
    [ clMsgSeqNum                   : Sample(4),
      firmId                        : Sample(8),
      sendingTime                   : Sample(8),
      executionWithinFirmShortCode  : Sample(4),
      clientIdentificationShortcode : Sample(4),
      clientOrderId                 : Sample(8),
      orderIdOptional               : Sample(8),
      origClientOrderId             : Sample(8),
      symbolIndex                   : Sample(4),
      emm                           : Sample(1),
      side                          : Sample(1),
      orderType                     : Sample(1),
      orderCategory                 : Sample(1),
      notUsedGroups                 : NotUsedGroups3,
      otherNotUsedGroups            : OtherNotUsedGroups3 ]

EncodeCancelRequestMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.executionWithinFirmShortCode
        \o message.clientIdentificationShortcode
        \o message.clientOrderId
        \o message.orderIdOptional
        \o message.origClientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.side
        \o message.orderType
        \o message.orderCategory
        \o EncodeNotUsedGroups3(message.notUsedGroups)
        \o EncodeOtherNotUsedGroups3(message.otherNotUsedGroups)

DecodeCancelRequestMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(sendingTime.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientIdentificationShortcode.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(clientOrderId.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET origClientOrderId == ReadBytes(orderIdOptional.rest, 8) IN IF ~origClientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(origClientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET side == ReadBytes(emm.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderType == ReadBytes(side.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET orderCategory == ReadBytes(orderType.rest, 1) IN IF ~orderCategory.ok THEN Fail ELSE
    LET notUsedGroups == DecodeNotUsedGroups3(orderCategory.rest) IN IF ~notUsedGroups.ok THEN Fail ELSE
    LET otherNotUsedGroups == DecodeOtherNotUsedGroups3(notUsedGroups.rest) IN IF ~otherNotUsedGroups.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                   |-> clMsgSeqNum.value,
         firmId                        |-> firmId.value,
         sendingTime                   |-> sendingTime.value,
         executionWithinFirmShortCode  |-> executionWithinFirmShortCode.value,
         clientIdentificationShortcode |-> clientIdentificationShortcode.value,
         clientOrderId                 |-> clientOrderId.value,
         orderIdOptional               |-> orderIdOptional.value,
         origClientOrderId             |-> origClientOrderId.value,
         symbolIndex                   |-> symbolIndex.value,
         emm                           |-> emm.value,
         side                          |-> side.value,
         orderType                     |-> orderType.value,
         orderCategory                 |-> orderCategory.value,
         notUsedGroups                 |-> notUsedGroups.value,
         otherNotUsedGroups            |-> otherNotUsedGroups.value ], otherNotUsedGroups.rest)

ZeroCancelRequestMessage ==
    [ clMsgSeqNum                   |-> [i \in 1 .. 4 |-> 0],
      firmId                        |-> [i \in 1 .. 8 |-> 0],
      sendingTime                   |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode  |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode |-> [i \in 1 .. 4 |-> 0],
      clientOrderId                 |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional               |-> [i \in 1 .. 8 |-> 0],
      origClientOrderId             |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                   |-> [i \in 1 .. 4 |-> 0],
      emm                           |-> [i \in 1 .. 1 |-> 0],
      side                          |-> [i \in 1 .. 1 |-> 0],
      orderType                     |-> [i \in 1 .. 1 |-> 0],
      orderCategory                 |-> [i \in 1 .. 1 |-> 0],
      notUsedGroups                 |-> ZeroNotUsedGroups3,
      otherNotUsedGroups            |-> ZeroOtherNotUsedGroups3 ]

(* Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelRequestMessage ==
    { ZeroCancelRequestMessage }
        \cup { [ZeroCancelRequestMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.origClientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.orderCategory = one] : one \in Sample(1) }
        \cup { [ZeroCancelRequestMessage EXCEPT !.notUsedGroups = one] : one \in CheckedNotUsedGroups3 }
        \cup { [ZeroCancelRequestMessage EXCEPT !.otherNotUsedGroups = one] : one \in CheckedOtherNotUsedGroups3 }

(***************************************************************************)
(* Not Used Groups: 2 bytes                                                *)
(***************************************************************************)

NotUsedGroups4 ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeNotUsedGroups4(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeNotUsedGroups4(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroNotUsedGroups4 ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedNotUsedGroups4 ==
    { ZeroNotUsedGroups4 }
        \cup { [ZeroNotUsedGroups4 EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroNotUsedGroups4 EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* Other Not Used Groups: 2 bytes                                          *)
(***************************************************************************)

OtherNotUsedGroups4 ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeOtherNotUsedGroups4(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeOtherNotUsedGroups4(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroOtherNotUsedGroups4 ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Other Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedOtherNotUsedGroups4 ==
    { ZeroOtherNotUsedGroups4 }
        \cup { [ZeroOtherNotUsedGroups4 EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroOtherNotUsedGroups4 EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* Mass Cancel Message: 73 bytes                                           *)
(***************************************************************************)

MassCancelMessage ==
    [ clMsgSeqNum                        : Sample(4),
      firmId                             : Sample(8),
      sendingTime                        : Sample(8),
      executionWithinFirmShortCode       : Sample(4),
      clientIdentificationShortcode      : Sample(4),
      clientOrderId                      : Sample(8),
      symbolIndexOptional                : Sample(4),
      emmOptional                        : Sample(1),
      instrumentGroupCode                : Sample(2),
      sideOptional                       : Sample(1),
      logicalAccessIdOptional            : Sample(4),
      oePartitionIdOptional              : Sample(2),
      contractId                         : Sample(4),
      maturity                           : Sample(8),
      accountTypeOptional                : Sample(1),
      optionType                         : Sample(1),
      orderCategory                      : Sample(1),
      targetExecutionWithinFirmShortCode : Sample(4),
      notUsedGroups                      : NotUsedGroups4,
      otherNotUsedGroups                 : OtherNotUsedGroups4 ]

EncodeMassCancelMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.executionWithinFirmShortCode
        \o message.clientIdentificationShortcode
        \o message.clientOrderId
        \o message.symbolIndexOptional
        \o message.emmOptional
        \o message.instrumentGroupCode
        \o message.sideOptional
        \o message.logicalAccessIdOptional
        \o message.oePartitionIdOptional
        \o message.contractId
        \o message.maturity
        \o message.accountTypeOptional
        \o message.optionType
        \o message.orderCategory
        \o message.targetExecutionWithinFirmShortCode
        \o EncodeNotUsedGroups4(message.notUsedGroups)
        \o EncodeOtherNotUsedGroups4(message.otherNotUsedGroups)

DecodeMassCancelMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(sendingTime.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientIdentificationShortcode.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolIndexOptional == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolIndexOptional.ok THEN Fail ELSE
    LET emmOptional == ReadBytes(symbolIndexOptional.rest, 1) IN IF ~emmOptional.ok THEN Fail ELSE
    LET instrumentGroupCode == ReadBytes(emmOptional.rest, 2) IN IF ~instrumentGroupCode.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(instrumentGroupCode.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET logicalAccessIdOptional == ReadBytes(sideOptional.rest, 4) IN IF ~logicalAccessIdOptional.ok THEN Fail ELSE
    LET oePartitionIdOptional == ReadBytes(logicalAccessIdOptional.rest, 2) IN IF ~oePartitionIdOptional.ok THEN Fail ELSE
    LET contractId == ReadBytes(oePartitionIdOptional.rest, 4) IN IF ~contractId.ok THEN Fail ELSE
    LET maturity == ReadBytes(contractId.rest, 8) IN IF ~maturity.ok THEN Fail ELSE
    LET accountTypeOptional == ReadBytes(maturity.rest, 1) IN IF ~accountTypeOptional.ok THEN Fail ELSE
    LET optionType == ReadBytes(accountTypeOptional.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET orderCategory == ReadBytes(optionType.rest, 1) IN IF ~orderCategory.ok THEN Fail ELSE
    LET targetExecutionWithinFirmShortCode == ReadBytes(orderCategory.rest, 4) IN IF ~targetExecutionWithinFirmShortCode.ok THEN Fail ELSE
    LET notUsedGroups == DecodeNotUsedGroups4(targetExecutionWithinFirmShortCode.rest) IN IF ~notUsedGroups.ok THEN Fail ELSE
    LET otherNotUsedGroups == DecodeOtherNotUsedGroups4(notUsedGroups.rest) IN IF ~otherNotUsedGroups.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                        |-> clMsgSeqNum.value,
         firmId                             |-> firmId.value,
         sendingTime                        |-> sendingTime.value,
         executionWithinFirmShortCode       |-> executionWithinFirmShortCode.value,
         clientIdentificationShortcode      |-> clientIdentificationShortcode.value,
         clientOrderId                      |-> clientOrderId.value,
         symbolIndexOptional                |-> symbolIndexOptional.value,
         emmOptional                        |-> emmOptional.value,
         instrumentGroupCode                |-> instrumentGroupCode.value,
         sideOptional                       |-> sideOptional.value,
         logicalAccessIdOptional            |-> logicalAccessIdOptional.value,
         oePartitionIdOptional              |-> oePartitionIdOptional.value,
         contractId                         |-> contractId.value,
         maturity                           |-> maturity.value,
         accountTypeOptional                |-> accountTypeOptional.value,
         optionType                         |-> optionType.value,
         orderCategory                      |-> orderCategory.value,
         targetExecutionWithinFirmShortCode |-> targetExecutionWithinFirmShortCode.value,
         notUsedGroups                      |-> notUsedGroups.value,
         otherNotUsedGroups                 |-> otherNotUsedGroups.value ], otherNotUsedGroups.rest)

ZeroMassCancelMessage ==
    [ clMsgSeqNum                        |-> [i \in 1 .. 4 |-> 0],
      firmId                             |-> [i \in 1 .. 8 |-> 0],
      sendingTime                        |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode       |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode      |-> [i \in 1 .. 4 |-> 0],
      clientOrderId                      |-> [i \in 1 .. 8 |-> 0],
      symbolIndexOptional                |-> [i \in 1 .. 4 |-> 0],
      emmOptional                        |-> [i \in 1 .. 1 |-> 0],
      instrumentGroupCode                |-> [i \in 1 .. 2 |-> 0],
      sideOptional                       |-> [i \in 1 .. 1 |-> 0],
      logicalAccessIdOptional            |-> [i \in 1 .. 4 |-> 0],
      oePartitionIdOptional              |-> [i \in 1 .. 2 |-> 0],
      contractId                         |-> [i \in 1 .. 4 |-> 0],
      maturity                           |-> [i \in 1 .. 8 |-> 0],
      accountTypeOptional                |-> [i \in 1 .. 1 |-> 0],
      optionType                         |-> [i \in 1 .. 1 |-> 0],
      orderCategory                      |-> [i \in 1 .. 1 |-> 0],
      targetExecutionWithinFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      notUsedGroups                      |-> ZeroNotUsedGroups4,
      otherNotUsedGroups                 |-> ZeroOtherNotUsedGroups4 ]

(* Mass Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelMessage ==
    { ZeroMassCancelMessage }
        \cup { [ZeroMassCancelMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelMessage EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelMessage EXCEPT !.symbolIndexOptional = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelMessage EXCEPT !.emmOptional = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelMessage EXCEPT !.instrumentGroupCode = one] : one \in Sample(2) }
        \cup { [ZeroMassCancelMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelMessage EXCEPT !.logicalAccessIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelMessage EXCEPT !.oePartitionIdOptional = one] : one \in Sample(2) }
        \cup { [ZeroMassCancelMessage EXCEPT !.contractId = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelMessage EXCEPT !.maturity = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelMessage EXCEPT !.accountTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelMessage EXCEPT !.orderCategory = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelMessage EXCEPT !.targetExecutionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelMessage EXCEPT !.notUsedGroups = one] : one \in CheckedNotUsedGroups4 }
        \cup { [ZeroMassCancelMessage EXCEPT !.otherNotUsedGroups = one] : one \in CheckedOtherNotUsedGroups4 }

(***************************************************************************)
(* Mifid Fields Group: 9 bytes                                             *)
(***************************************************************************)

MifidFieldsGroup5 ==
    [ executionWithinFirmShortCodeOptional : Sample(4),
      clientIdentificationShortcode        : Sample(4),
      mifidIndicatorsOptional              : Sample(1) ]

EncodeMifidFieldsGroup5(message) ==
    message.executionWithinFirmShortCodeOptional
        \o message.clientIdentificationShortcode
        \o message.mifidIndicatorsOptional

DecodeMifidFieldsGroup5(bytes) ==
    LET executionWithinFirmShortCodeOptional == ReadBytes(bytes, 4) IN IF ~executionWithinFirmShortCodeOptional.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCodeOptional.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET mifidIndicatorsOptional == ReadBytes(clientIdentificationShortcode.rest, 1) IN IF ~mifidIndicatorsOptional.ok THEN Fail ELSE
    Ok([ executionWithinFirmShortCodeOptional |-> executionWithinFirmShortCodeOptional.value,
         clientIdentificationShortcode        |-> clientIdentificationShortcode.value,
         mifidIndicatorsOptional              |-> mifidIndicatorsOptional.value ], mifidIndicatorsOptional.rest)

ZeroMifidFieldsGroup5 ==
    [ executionWithinFirmShortCodeOptional |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode        |-> [i \in 1 .. 4 |-> 0],
      mifidIndicatorsOptional              |-> [i \in 1 .. 1 |-> 0] ]

(* Mifid Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedMifidFieldsGroup5 ==
    { ZeroMifidFieldsGroup5 }
        \cup { [ZeroMifidFieldsGroup5 EXCEPT !.executionWithinFirmShortCodeOptional = one] : one \in Sample(4) }
        \cup { [ZeroMifidFieldsGroup5 EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroMifidFieldsGroup5 EXCEPT !.mifidIndicatorsOptional = one] : one \in Sample(1) }

(* A run of Mifid Fields Group, written one after another *)
RECURSIVE EncodeMifidFieldsGroup5List(_)
EncodeMifidFieldsGroup5List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMifidFieldsGroup5(Head(messages)) \o EncodeMifidFieldsGroup5List(Tail(messages))

(* As many Mifid Fields Group as the field that counts them says *)
RECURSIVE ReadMifidFieldsGroup5List(_, _)
ReadMifidFieldsGroup5List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMifidFieldsGroup5(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMifidFieldsGroup5List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mifid Fields Group of each kind, for the lists that carry them *)
OneMifidFieldsGroup5 == { ZeroMifidFieldsGroup5 }

(***************************************************************************)
(* Mifid Fields Groups                                                     *)
(***************************************************************************)

MifidFieldsGroups5 ==
    [ blockLengthShort : Sample(1),
      mifidFieldsGroup : SampleLists(OneMifidFieldsGroup5) ]

EncodeMifidFieldsGroups5(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.mifidFieldsGroup), 1)
        \o EncodeMifidFieldsGroup5List(message.mifidFieldsGroup)

DecodeMifidFieldsGroups5(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET mifidFieldsGroup == ReadMifidFieldsGroup5List(numInGroup.rest, numInGroup.value) IN IF ~mifidFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         mifidFieldsGroup |-> mifidFieldsGroup.value ], mifidFieldsGroup.rest)

ZeroMifidFieldsGroups5 ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      mifidFieldsGroup |-> << >> ]

(* Mifid Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedMifidFieldsGroups5 ==
    { ZeroMifidFieldsGroups5 }
        \cup { [ZeroMifidFieldsGroups5 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroMifidFieldsGroups5 EXCEPT !.mifidFieldsGroup = one] : one \in SampleLists(OneMifidFieldsGroup5) }

(***************************************************************************)
(* Mass Cancel Ack Message                                                 *)
(***************************************************************************)

MassCancelAckMessage ==
    [ msgSeqNum                          : Sample(4),
      firmId                             : Sample(8),
      sendingTimeOptional                : Sample(8),
      oegInFromMember                    : Sample(8),
      oegOutTimeToMe                     : Sample(8),
      bookIn                             : Sample(8),
      bookOutTime                        : Sample(8),
      oegInFromMe                        : Sample(8),
      oegOutToMember                     : Sample(8),
      clientOrderId                      : Sample(8),
      totalAffectedOrders                : Sample(4),
      symbolIndexOptional                : Sample(4),
      emmOptional                        : Sample(1),
      instrumentGroupCode                : Sample(2),
      sideOptional                       : Sample(1),
      logicalAccessIdOptional            : Sample(4),
      oePartitionIdOptional              : Sample(2),
      contractId                         : Sample(4),
      maturity                           : Sample(8),
      accountTypeOptional                : Sample(1),
      optionType                         : Sample(1),
      orderCategory                      : Sample(1),
      ackQualifiersOptional              : Sample(1),
      targetExecutionWithinFirmShortCode : Sample(4),
      mifidFieldsGroups                  : MifidFieldsGroups5 ]

EncodeMassCancelAckMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.sendingTimeOptional
        \o message.oegInFromMember
        \o message.oegOutTimeToMe
        \o message.bookIn
        \o message.bookOutTime
        \o message.oegInFromMe
        \o message.oegOutToMember
        \o message.clientOrderId
        \o message.totalAffectedOrders
        \o message.symbolIndexOptional
        \o message.emmOptional
        \o message.instrumentGroupCode
        \o message.sideOptional
        \o message.logicalAccessIdOptional
        \o message.oePartitionIdOptional
        \o message.contractId
        \o message.maturity
        \o message.accountTypeOptional
        \o message.optionType
        \o message.orderCategory
        \o message.ackQualifiersOptional
        \o message.targetExecutionWithinFirmShortCode
        \o EncodeMifidFieldsGroups5(message.mifidFieldsGroups)

DecodeMassCancelAckMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTimeOptional == ReadBytes(firmId.rest, 8) IN IF ~sendingTimeOptional.ok THEN Fail ELSE
    LET oegInFromMember == ReadBytes(sendingTimeOptional.rest, 8) IN IF ~oegInFromMember.ok THEN Fail ELSE
    LET oegOutTimeToMe == ReadBytes(oegInFromMember.rest, 8) IN IF ~oegOutTimeToMe.ok THEN Fail ELSE
    LET bookIn == ReadBytes(oegOutTimeToMe.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTime == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTime.ok THEN Fail ELSE
    LET oegInFromMe == ReadBytes(bookOutTime.rest, 8) IN IF ~oegInFromMe.ok THEN Fail ELSE
    LET oegOutToMember == ReadBytes(oegInFromMe.rest, 8) IN IF ~oegOutToMember.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(oegOutToMember.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET totalAffectedOrders == ReadBytes(clientOrderId.rest, 4) IN IF ~totalAffectedOrders.ok THEN Fail ELSE
    LET symbolIndexOptional == ReadBytes(totalAffectedOrders.rest, 4) IN IF ~symbolIndexOptional.ok THEN Fail ELSE
    LET emmOptional == ReadBytes(symbolIndexOptional.rest, 1) IN IF ~emmOptional.ok THEN Fail ELSE
    LET instrumentGroupCode == ReadBytes(emmOptional.rest, 2) IN IF ~instrumentGroupCode.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(instrumentGroupCode.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET logicalAccessIdOptional == ReadBytes(sideOptional.rest, 4) IN IF ~logicalAccessIdOptional.ok THEN Fail ELSE
    LET oePartitionIdOptional == ReadBytes(logicalAccessIdOptional.rest, 2) IN IF ~oePartitionIdOptional.ok THEN Fail ELSE
    LET contractId == ReadBytes(oePartitionIdOptional.rest, 4) IN IF ~contractId.ok THEN Fail ELSE
    LET maturity == ReadBytes(contractId.rest, 8) IN IF ~maturity.ok THEN Fail ELSE
    LET accountTypeOptional == ReadBytes(maturity.rest, 1) IN IF ~accountTypeOptional.ok THEN Fail ELSE
    LET optionType == ReadBytes(accountTypeOptional.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET orderCategory == ReadBytes(optionType.rest, 1) IN IF ~orderCategory.ok THEN Fail ELSE
    LET ackQualifiersOptional == ReadBytes(orderCategory.rest, 1) IN IF ~ackQualifiersOptional.ok THEN Fail ELSE
    LET targetExecutionWithinFirmShortCode == ReadBytes(ackQualifiersOptional.rest, 4) IN IF ~targetExecutionWithinFirmShortCode.ok THEN Fail ELSE
    LET mifidFieldsGroups == DecodeMifidFieldsGroups5(targetExecutionWithinFirmShortCode.rest) IN IF ~mifidFieldsGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                          |-> msgSeqNum.value,
         firmId                             |-> firmId.value,
         sendingTimeOptional                |-> sendingTimeOptional.value,
         oegInFromMember                    |-> oegInFromMember.value,
         oegOutTimeToMe                     |-> oegOutTimeToMe.value,
         bookIn                             |-> bookIn.value,
         bookOutTime                        |-> bookOutTime.value,
         oegInFromMe                        |-> oegInFromMe.value,
         oegOutToMember                     |-> oegOutToMember.value,
         clientOrderId                      |-> clientOrderId.value,
         totalAffectedOrders                |-> totalAffectedOrders.value,
         symbolIndexOptional                |-> symbolIndexOptional.value,
         emmOptional                        |-> emmOptional.value,
         instrumentGroupCode                |-> instrumentGroupCode.value,
         sideOptional                       |-> sideOptional.value,
         logicalAccessIdOptional            |-> logicalAccessIdOptional.value,
         oePartitionIdOptional              |-> oePartitionIdOptional.value,
         contractId                         |-> contractId.value,
         maturity                           |-> maturity.value,
         accountTypeOptional                |-> accountTypeOptional.value,
         optionType                         |-> optionType.value,
         orderCategory                      |-> orderCategory.value,
         ackQualifiersOptional              |-> ackQualifiersOptional.value,
         targetExecutionWithinFirmShortCode |-> targetExecutionWithinFirmShortCode.value,
         mifidFieldsGroups                  |-> mifidFieldsGroups.value ], mifidFieldsGroups.rest)

ZeroMassCancelAckMessage ==
    [ msgSeqNum                          |-> [i \in 1 .. 4 |-> 0],
      firmId                             |-> [i \in 1 .. 8 |-> 0],
      sendingTimeOptional                |-> [i \in 1 .. 8 |-> 0],
      oegInFromMember                    |-> [i \in 1 .. 8 |-> 0],
      oegOutTimeToMe                     |-> [i \in 1 .. 8 |-> 0],
      bookIn                             |-> [i \in 1 .. 8 |-> 0],
      bookOutTime                        |-> [i \in 1 .. 8 |-> 0],
      oegInFromMe                        |-> [i \in 1 .. 8 |-> 0],
      oegOutToMember                     |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                      |-> [i \in 1 .. 8 |-> 0],
      totalAffectedOrders                |-> [i \in 1 .. 4 |-> 0],
      symbolIndexOptional                |-> [i \in 1 .. 4 |-> 0],
      emmOptional                        |-> [i \in 1 .. 1 |-> 0],
      instrumentGroupCode                |-> [i \in 1 .. 2 |-> 0],
      sideOptional                       |-> [i \in 1 .. 1 |-> 0],
      logicalAccessIdOptional            |-> [i \in 1 .. 4 |-> 0],
      oePartitionIdOptional              |-> [i \in 1 .. 2 |-> 0],
      contractId                         |-> [i \in 1 .. 4 |-> 0],
      maturity                           |-> [i \in 1 .. 8 |-> 0],
      accountTypeOptional                |-> [i \in 1 .. 1 |-> 0],
      optionType                         |-> [i \in 1 .. 1 |-> 0],
      orderCategory                      |-> [i \in 1 .. 1 |-> 0],
      ackQualifiersOptional              |-> [i \in 1 .. 1 |-> 0],
      targetExecutionWithinFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      mifidFieldsGroups                  |-> ZeroMifidFieldsGroups5 ]

(* Mass Cancel Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedMassCancelAckMessage ==
    { ZeroMassCancelAckMessage }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.sendingTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.oegInFromMember = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.oegOutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.bookOutTime = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.oegInFromMe = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.oegOutToMember = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.totalAffectedOrders = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.symbolIndexOptional = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.emmOptional = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.instrumentGroupCode = one] : one \in Sample(2) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.logicalAccessIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.oePartitionIdOptional = one] : one \in Sample(2) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.contractId = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.maturity = one] : one \in Sample(8) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.accountTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.orderCategory = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.ackQualifiersOptional = one] : one \in Sample(1) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.targetExecutionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroMassCancelAckMessage EXCEPT !.mifidFieldsGroups = one] : one \in CheckedMifidFieldsGroups5 }

(***************************************************************************)
(* Open Order Request Message: 58 bytes                                    *)
(***************************************************************************)

OpenOrderRequestMessage ==
    [ clMsgSeqNum                   : Sample(4),
      firmId                        : Sample(8),
      sendingTime                   : Sample(8),
      executionWithinFirmShortCode  : Sample(4),
      clientIdentificationShortcode : Sample(4),
      clientOrderId                 : Sample(8),
      orderIdOptional               : Sample(8),
      origClientOrderId             : Sample(8),
      symbolIndex                   : Sample(4),
      emm                           : Sample(1),
      orderCategory                 : Sample(1) ]

EncodeOpenOrderRequestMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.executionWithinFirmShortCode
        \o message.clientIdentificationShortcode
        \o message.clientOrderId
        \o message.orderIdOptional
        \o message.origClientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.orderCategory

DecodeOpenOrderRequestMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(sendingTime.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientIdentificationShortcode.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(clientOrderId.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET origClientOrderId == ReadBytes(orderIdOptional.rest, 8) IN IF ~origClientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(origClientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET orderCategory == ReadBytes(emm.rest, 1) IN IF ~orderCategory.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                   |-> clMsgSeqNum.value,
         firmId                        |-> firmId.value,
         sendingTime                   |-> sendingTime.value,
         executionWithinFirmShortCode  |-> executionWithinFirmShortCode.value,
         clientIdentificationShortcode |-> clientIdentificationShortcode.value,
         clientOrderId                 |-> clientOrderId.value,
         orderIdOptional               |-> orderIdOptional.value,
         origClientOrderId             |-> origClientOrderId.value,
         symbolIndex                   |-> symbolIndex.value,
         emm                           |-> emm.value,
         orderCategory                 |-> orderCategory.value ], orderCategory.rest)

ZeroOpenOrderRequestMessage ==
    [ clMsgSeqNum                   |-> [i \in 1 .. 4 |-> 0],
      firmId                        |-> [i \in 1 .. 8 |-> 0],
      sendingTime                   |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode  |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode |-> [i \in 1 .. 4 |-> 0],
      clientOrderId                 |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional               |-> [i \in 1 .. 8 |-> 0],
      origClientOrderId             |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                   |-> [i \in 1 .. 4 |-> 0],
      emm                           |-> [i \in 1 .. 1 |-> 0],
      orderCategory                 |-> [i \in 1 .. 1 |-> 0] ]

(* Open Order Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOpenOrderRequestMessage ==
    { ZeroOpenOrderRequestMessage }
        \cup { [ZeroOpenOrderRequestMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOpenOrderRequestMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroOpenOrderRequestMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOpenOrderRequestMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroOpenOrderRequestMessage EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroOpenOrderRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOpenOrderRequestMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOpenOrderRequestMessage EXCEPT !.origClientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOpenOrderRequestMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroOpenOrderRequestMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroOpenOrderRequestMessage EXCEPT !.orderCategory = one] : one \in Sample(1) }

(***************************************************************************)
(* Ownership Request Ack Message: 43 bytes                                 *)
(***************************************************************************)

OwnershipRequestAckMessage ==
    [ msgSeqNum               : Sample(4),
      firmId                  : Sample(8),
      clientOrderId           : Sample(8),
      orderIdOptional         : Sample(8),
      symbolIndex             : Sample(4),
      logicalAccessIdOptional : Sample(4),
      oePartitionIdOptional   : Sample(2),
      totalAffectedOrders     : Sample(4),
      orderCategory           : Sample(1) ]

EncodeOwnershipRequestAckMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.clientOrderId
        \o message.orderIdOptional
        \o message.symbolIndex
        \o message.logicalAccessIdOptional
        \o message.oePartitionIdOptional
        \o message.totalAffectedOrders
        \o message.orderCategory

DecodeOwnershipRequestAckMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(firmId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(clientOrderId.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(orderIdOptional.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET logicalAccessIdOptional == ReadBytes(symbolIndex.rest, 4) IN IF ~logicalAccessIdOptional.ok THEN Fail ELSE
    LET oePartitionIdOptional == ReadBytes(logicalAccessIdOptional.rest, 2) IN IF ~oePartitionIdOptional.ok THEN Fail ELSE
    LET totalAffectedOrders == ReadBytes(oePartitionIdOptional.rest, 4) IN IF ~totalAffectedOrders.ok THEN Fail ELSE
    LET orderCategory == ReadBytes(totalAffectedOrders.rest, 1) IN IF ~orderCategory.ok THEN Fail ELSE
    Ok([ msgSeqNum               |-> msgSeqNum.value,
         firmId                  |-> firmId.value,
         clientOrderId           |-> clientOrderId.value,
         orderIdOptional         |-> orderIdOptional.value,
         symbolIndex             |-> symbolIndex.value,
         logicalAccessIdOptional |-> logicalAccessIdOptional.value,
         oePartitionIdOptional   |-> oePartitionIdOptional.value,
         totalAffectedOrders     |-> totalAffectedOrders.value,
         orderCategory           |-> orderCategory.value ], orderCategory.rest)

ZeroOwnershipRequestAckMessage ==
    [ msgSeqNum               |-> [i \in 1 .. 4 |-> 0],
      firmId                  |-> [i \in 1 .. 8 |-> 0],
      clientOrderId           |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional         |-> [i \in 1 .. 8 |-> 0],
      symbolIndex             |-> [i \in 1 .. 4 |-> 0],
      logicalAccessIdOptional |-> [i \in 1 .. 4 |-> 0],
      oePartitionIdOptional   |-> [i \in 1 .. 2 |-> 0],
      totalAffectedOrders     |-> [i \in 1 .. 4 |-> 0],
      orderCategory           |-> [i \in 1 .. 1 |-> 0] ]

(* Ownership Request Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedOwnershipRequestAckMessage ==
    { ZeroOwnershipRequestAckMessage }
        \cup { [ZeroOwnershipRequestAckMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOwnershipRequestAckMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroOwnershipRequestAckMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOwnershipRequestAckMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOwnershipRequestAckMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroOwnershipRequestAckMessage EXCEPT !.logicalAccessIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroOwnershipRequestAckMessage EXCEPT !.oePartitionIdOptional = one] : one \in Sample(2) }
        \cup { [ZeroOwnershipRequestAckMessage EXCEPT !.totalAffectedOrders = one] : one \in Sample(4) }
        \cup { [ZeroOwnershipRequestAckMessage EXCEPT !.orderCategory = one] : one \in Sample(1) }

(***************************************************************************)
(* Ownership Request Message: 64 bytes                                     *)
(***************************************************************************)

OwnershipRequestMessage ==
    [ clMsgSeqNum                   : Sample(4),
      firmId                        : Sample(8),
      sendingTime                   : Sample(8),
      executionWithinFirmShortCode  : Sample(4),
      clientIdentificationShortcode : Sample(4),
      clientOrderId                 : Sample(8),
      orderIdOptional               : Sample(8),
      origClientOrderId             : Sample(8),
      symbolIndex                   : Sample(4),
      emm                           : Sample(1),
      logicalAccessIdOptional       : Sample(4),
      oePartitionIdOptional         : Sample(2),
      orderCategory                 : Sample(1) ]

EncodeOwnershipRequestMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.executionWithinFirmShortCode
        \o message.clientIdentificationShortcode
        \o message.clientOrderId
        \o message.orderIdOptional
        \o message.origClientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.logicalAccessIdOptional
        \o message.oePartitionIdOptional
        \o message.orderCategory

DecodeOwnershipRequestMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(sendingTime.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientIdentificationShortcode.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(clientOrderId.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET origClientOrderId == ReadBytes(orderIdOptional.rest, 8) IN IF ~origClientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(origClientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET logicalAccessIdOptional == ReadBytes(emm.rest, 4) IN IF ~logicalAccessIdOptional.ok THEN Fail ELSE
    LET oePartitionIdOptional == ReadBytes(logicalAccessIdOptional.rest, 2) IN IF ~oePartitionIdOptional.ok THEN Fail ELSE
    LET orderCategory == ReadBytes(oePartitionIdOptional.rest, 1) IN IF ~orderCategory.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                   |-> clMsgSeqNum.value,
         firmId                        |-> firmId.value,
         sendingTime                   |-> sendingTime.value,
         executionWithinFirmShortCode  |-> executionWithinFirmShortCode.value,
         clientIdentificationShortcode |-> clientIdentificationShortcode.value,
         clientOrderId                 |-> clientOrderId.value,
         orderIdOptional               |-> orderIdOptional.value,
         origClientOrderId             |-> origClientOrderId.value,
         symbolIndex                   |-> symbolIndex.value,
         emm                           |-> emm.value,
         logicalAccessIdOptional       |-> logicalAccessIdOptional.value,
         oePartitionIdOptional         |-> oePartitionIdOptional.value,
         orderCategory                 |-> orderCategory.value ], orderCategory.rest)

ZeroOwnershipRequestMessage ==
    [ clMsgSeqNum                   |-> [i \in 1 .. 4 |-> 0],
      firmId                        |-> [i \in 1 .. 8 |-> 0],
      sendingTime                   |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode  |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode |-> [i \in 1 .. 4 |-> 0],
      clientOrderId                 |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional               |-> [i \in 1 .. 8 |-> 0],
      origClientOrderId             |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                   |-> [i \in 1 .. 4 |-> 0],
      emm                           |-> [i \in 1 .. 1 |-> 0],
      logicalAccessIdOptional       |-> [i \in 1 .. 4 |-> 0],
      oePartitionIdOptional         |-> [i \in 1 .. 2 |-> 0],
      orderCategory                 |-> [i \in 1 .. 1 |-> 0] ]

(* Ownership Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOwnershipRequestMessage ==
    { ZeroOwnershipRequestMessage }
        \cup { [ZeroOwnershipRequestMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroOwnershipRequestMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroOwnershipRequestMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroOwnershipRequestMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroOwnershipRequestMessage EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroOwnershipRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOwnershipRequestMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOwnershipRequestMessage EXCEPT !.origClientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroOwnershipRequestMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroOwnershipRequestMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroOwnershipRequestMessage EXCEPT !.logicalAccessIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroOwnershipRequestMessage EXCEPT !.oePartitionIdOptional = one] : one \in Sample(2) }
        \cup { [ZeroOwnershipRequestMessage EXCEPT !.orderCategory = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Bust Notification Message: 113 bytes                              *)
(***************************************************************************)

TradeBustNotificationMessage ==
    [ msgSeqNum                   : Sample(4),
      firmId                      : Sample(8),
      bookIn                      : Sample(8),
      bookOutTimeOptional         : Sample(8),
      oegInFromMeOptional         : Sample(8),
      oegOutToMemberOptional      : Sample(8),
      symbolIndex                 : Sample(4),
      emm                         : Sample(1),
      executionId                 : Sample(4),
      lastTradedPx                : Sample(8),
      lastShares                  : Sample(8),
      lisTransactionId            : Sample(4),
      parentExecId                : Sample(4),
      parentSymbolIndex           : Sample(4),
      tradeUniqueIdentifier       : Sample(16),
      parentTradeUniqueIdentifier : Sample(16) ]

EncodeTradeBustNotificationMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.bookIn
        \o message.bookOutTimeOptional
        \o message.oegInFromMeOptional
        \o message.oegOutToMemberOptional
        \o message.symbolIndex
        \o message.emm
        \o message.executionId
        \o message.lastTradedPx
        \o message.lastShares
        \o message.lisTransactionId
        \o message.parentExecId
        \o message.parentSymbolIndex
        \o message.tradeUniqueIdentifier
        \o message.parentTradeUniqueIdentifier

DecodeTradeBustNotificationMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET bookIn == ReadBytes(firmId.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET oegInFromMeOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~oegInFromMeOptional.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(oegInFromMeOptional.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(oegOutToMemberOptional.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET executionId == ReadBytes(emm.rest, 4) IN IF ~executionId.ok THEN Fail ELSE
    LET lastTradedPx == ReadBytes(executionId.rest, 8) IN IF ~lastTradedPx.ok THEN Fail ELSE
    LET lastShares == ReadBytes(lastTradedPx.rest, 8) IN IF ~lastShares.ok THEN Fail ELSE
    LET lisTransactionId == ReadBytes(lastShares.rest, 4) IN IF ~lisTransactionId.ok THEN Fail ELSE
    LET parentExecId == ReadBytes(lisTransactionId.rest, 4) IN IF ~parentExecId.ok THEN Fail ELSE
    LET parentSymbolIndex == ReadBytes(parentExecId.rest, 4) IN IF ~parentSymbolIndex.ok THEN Fail ELSE
    LET tradeUniqueIdentifier == ReadBytes(parentSymbolIndex.rest, 16) IN IF ~tradeUniqueIdentifier.ok THEN Fail ELSE
    LET parentTradeUniqueIdentifier == ReadBytes(tradeUniqueIdentifier.rest, 16) IN IF ~parentTradeUniqueIdentifier.ok THEN Fail ELSE
    Ok([ msgSeqNum                   |-> msgSeqNum.value,
         firmId                      |-> firmId.value,
         bookIn                      |-> bookIn.value,
         bookOutTimeOptional         |-> bookOutTimeOptional.value,
         oegInFromMeOptional         |-> oegInFromMeOptional.value,
         oegOutToMemberOptional      |-> oegOutToMemberOptional.value,
         symbolIndex                 |-> symbolIndex.value,
         emm                         |-> emm.value,
         executionId                 |-> executionId.value,
         lastTradedPx                |-> lastTradedPx.value,
         lastShares                  |-> lastShares.value,
         lisTransactionId            |-> lisTransactionId.value,
         parentExecId                |-> parentExecId.value,
         parentSymbolIndex           |-> parentSymbolIndex.value,
         tradeUniqueIdentifier       |-> tradeUniqueIdentifier.value,
         parentTradeUniqueIdentifier |-> parentTradeUniqueIdentifier.value ], parentTradeUniqueIdentifier.rest)

ZeroTradeBustNotificationMessage ==
    [ msgSeqNum                   |-> [i \in 1 .. 4 |-> 0],
      firmId                      |-> [i \in 1 .. 8 |-> 0],
      bookIn                      |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional         |-> [i \in 1 .. 8 |-> 0],
      oegInFromMeOptional         |-> [i \in 1 .. 8 |-> 0],
      oegOutToMemberOptional      |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                 |-> [i \in 1 .. 4 |-> 0],
      emm                         |-> [i \in 1 .. 1 |-> 0],
      executionId                 |-> [i \in 1 .. 4 |-> 0],
      lastTradedPx                |-> [i \in 1 .. 8 |-> 0],
      lastShares                  |-> [i \in 1 .. 8 |-> 0],
      lisTransactionId            |-> [i \in 1 .. 4 |-> 0],
      parentExecId                |-> [i \in 1 .. 4 |-> 0],
      parentSymbolIndex           |-> [i \in 1 .. 4 |-> 0],
      tradeUniqueIdentifier       |-> [i \in 1 .. 16 |-> 0],
      parentTradeUniqueIdentifier |-> [i \in 1 .. 16 |-> 0] ]

(* Trade Bust Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustNotificationMessage ==
    { ZeroTradeBustNotificationMessage }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.oegInFromMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.executionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.lastTradedPx = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.lastShares = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.lisTransactionId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.parentExecId = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.parentSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.tradeUniqueIdentifier = one] : one \in Sample(16) }
        \cup { [ZeroTradeBustNotificationMessage EXCEPT !.parentTradeUniqueIdentifier = one] : one \in Sample(16) }

(***************************************************************************)
(* Collar Breach Confirmation Message: 57 bytes                            *)
(***************************************************************************)

CollarBreachConfirmationMessage ==
    [ clMsgSeqNum                   : Sample(4),
      firmId                        : Sample(8),
      sendingTime                   : Sample(8),
      executionWithinFirmShortCode  : Sample(4),
      clientIdentificationShortcode : Sample(4),
      clientOrderId                 : Sample(8),
      symbolIndex                   : Sample(4),
      emm                           : Sample(1),
      orderIdOptional               : Sample(8),
      origClientOrderId             : Sample(8) ]

EncodeCollarBreachConfirmationMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.executionWithinFirmShortCode
        \o message.clientIdentificationShortcode
        \o message.clientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.orderIdOptional
        \o message.origClientOrderId

DecodeCollarBreachConfirmationMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(sendingTime.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientIdentificationShortcode.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(emm.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET origClientOrderId == ReadBytes(orderIdOptional.rest, 8) IN IF ~origClientOrderId.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                   |-> clMsgSeqNum.value,
         firmId                        |-> firmId.value,
         sendingTime                   |-> sendingTime.value,
         executionWithinFirmShortCode  |-> executionWithinFirmShortCode.value,
         clientIdentificationShortcode |-> clientIdentificationShortcode.value,
         clientOrderId                 |-> clientOrderId.value,
         symbolIndex                   |-> symbolIndex.value,
         emm                           |-> emm.value,
         orderIdOptional               |-> orderIdOptional.value,
         origClientOrderId             |-> origClientOrderId.value ], origClientOrderId.rest)

ZeroCollarBreachConfirmationMessage ==
    [ clMsgSeqNum                   |-> [i \in 1 .. 4 |-> 0],
      firmId                        |-> [i \in 1 .. 8 |-> 0],
      sendingTime                   |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode  |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode |-> [i \in 1 .. 4 |-> 0],
      clientOrderId                 |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                   |-> [i \in 1 .. 4 |-> 0],
      emm                           |-> [i \in 1 .. 1 |-> 0],
      orderIdOptional               |-> [i \in 1 .. 8 |-> 0],
      origClientOrderId             |-> [i \in 1 .. 8 |-> 0] ]

(* Collar Breach Confirmation Message at zero, then each field in turn at the values it is checked at *)
CheckedCollarBreachConfirmationMessage ==
    { ZeroCollarBreachConfirmationMessage }
        \cup { [ZeroCollarBreachConfirmationMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroCollarBreachConfirmationMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroCollarBreachConfirmationMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroCollarBreachConfirmationMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroCollarBreachConfirmationMessage EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroCollarBreachConfirmationMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCollarBreachConfirmationMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroCollarBreachConfirmationMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroCollarBreachConfirmationMessage EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroCollarBreachConfirmationMessage EXCEPT !.origClientOrderId = one] : one \in Sample(8) }

(***************************************************************************)
(* Price Input Message: 50 bytes                                           *)
(***************************************************************************)

PriceInputMessage ==
    [ clMsgSeqNum                   : Sample(4),
      firmId                        : Sample(8),
      sendingTime                   : Sample(8),
      executionWithinFirmShortCode  : Sample(4),
      clientIdentificationShortcode : Sample(4),
      clientOrderId                 : Sample(8),
      symbolIndex                   : Sample(4),
      emm                           : Sample(1),
      inputPriceType                : Sample(1),
      priceOptional                 : Sample(8) ]

EncodePriceInputMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.executionWithinFirmShortCode
        \o message.clientIdentificationShortcode
        \o message.clientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.inputPriceType
        \o message.priceOptional

DecodePriceInputMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(sendingTime.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientIdentificationShortcode.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET inputPriceType == ReadBytes(emm.rest, 1) IN IF ~inputPriceType.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(inputPriceType.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                   |-> clMsgSeqNum.value,
         firmId                        |-> firmId.value,
         sendingTime                   |-> sendingTime.value,
         executionWithinFirmShortCode  |-> executionWithinFirmShortCode.value,
         clientIdentificationShortcode |-> clientIdentificationShortcode.value,
         clientOrderId                 |-> clientOrderId.value,
         symbolIndex                   |-> symbolIndex.value,
         emm                           |-> emm.value,
         inputPriceType                |-> inputPriceType.value,
         priceOptional                 |-> priceOptional.value ], priceOptional.rest)

ZeroPriceInputMessage ==
    [ clMsgSeqNum                   |-> [i \in 1 .. 4 |-> 0],
      firmId                        |-> [i \in 1 .. 8 |-> 0],
      sendingTime                   |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode  |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode |-> [i \in 1 .. 4 |-> 0],
      clientOrderId                 |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                   |-> [i \in 1 .. 4 |-> 0],
      emm                           |-> [i \in 1 .. 1 |-> 0],
      inputPriceType                |-> [i \in 1 .. 1 |-> 0],
      priceOptional                 |-> [i \in 1 .. 8 |-> 0] ]

(* Price Input Message at zero, then each field in turn at the values it is checked at *)
CheckedPriceInputMessage ==
    { ZeroPriceInputMessage }
        \cup { [ZeroPriceInputMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroPriceInputMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroPriceInputMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroPriceInputMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroPriceInputMessage EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroPriceInputMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroPriceInputMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroPriceInputMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroPriceInputMessage EXCEPT !.inputPriceType = one] : one \in Sample(1) }
        \cup { [ZeroPriceInputMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }

(***************************************************************************)
(* Liquidity Provider Command Message: 42 bytes                            *)
(***************************************************************************)

LiquidityProviderCommandMessage ==
    [ clMsgSeqNum                   : Sample(4),
      firmId                        : Sample(8),
      sendingTime                   : Sample(8),
      executionWithinFirmShortCode  : Sample(4),
      clientIdentificationShortcode : Sample(4),
      clientOrderId                 : Sample(8),
      symbolIndex                   : Sample(4),
      emm                           : Sample(1),
      lpActionCode                  : Sample(1) ]

EncodeLiquidityProviderCommandMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.executionWithinFirmShortCode
        \o message.clientIdentificationShortcode
        \o message.clientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.lpActionCode

DecodeLiquidityProviderCommandMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(sendingTime.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientIdentificationShortcode.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET lpActionCode == ReadBytes(emm.rest, 1) IN IF ~lpActionCode.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                   |-> clMsgSeqNum.value,
         firmId                        |-> firmId.value,
         sendingTime                   |-> sendingTime.value,
         executionWithinFirmShortCode  |-> executionWithinFirmShortCode.value,
         clientIdentificationShortcode |-> clientIdentificationShortcode.value,
         clientOrderId                 |-> clientOrderId.value,
         symbolIndex                   |-> symbolIndex.value,
         emm                           |-> emm.value,
         lpActionCode                  |-> lpActionCode.value ], lpActionCode.rest)

ZeroLiquidityProviderCommandMessage ==
    [ clMsgSeqNum                   |-> [i \in 1 .. 4 |-> 0],
      firmId                        |-> [i \in 1 .. 8 |-> 0],
      sendingTime                   |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode  |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode |-> [i \in 1 .. 4 |-> 0],
      clientOrderId                 |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                   |-> [i \in 1 .. 4 |-> 0],
      emm                           |-> [i \in 1 .. 1 |-> 0],
      lpActionCode                  |-> [i \in 1 .. 1 |-> 0] ]

(* Liquidity Provider Command Message at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityProviderCommandMessage ==
    { ZeroLiquidityProviderCommandMessage }
        \cup { [ZeroLiquidityProviderCommandMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityProviderCommandMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroLiquidityProviderCommandMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroLiquidityProviderCommandMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityProviderCommandMessage EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityProviderCommandMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroLiquidityProviderCommandMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroLiquidityProviderCommandMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroLiquidityProviderCommandMessage EXCEPT !.lpActionCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Ask For Quote Message: 18 bytes                                         *)
(***************************************************************************)

AskForQuoteMessage ==
    [ msgSeqNum   : Sample(4),
      firmId      : Sample(8),
      symbolIndex : Sample(4),
      emm         : Sample(1),
      afqReason   : Sample(1) ]

EncodeAskForQuoteMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.symbolIndex
        \o message.emm
        \o message.afqReason

DecodeAskForQuoteMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(firmId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET afqReason == ReadBytes(emm.rest, 1) IN IF ~afqReason.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         firmId      |-> firmId.value,
         symbolIndex |-> symbolIndex.value,
         emm         |-> emm.value,
         afqReason   |-> afqReason.value ], afqReason.rest)

ZeroAskForQuoteMessage ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      firmId      |-> [i \in 1 .. 8 |-> 0],
      symbolIndex |-> [i \in 1 .. 4 |-> 0],
      emm         |-> [i \in 1 .. 1 |-> 0],
      afqReason   |-> [i \in 1 .. 1 |-> 0] ]

(* Ask For Quote Message at zero, then each field in turn at the values it is checked at *)
CheckedAskForQuoteMessage ==
    { ZeroAskForQuoteMessage }
        \cup { [ZeroAskForQuoteMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroAskForQuoteMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroAskForQuoteMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroAskForQuoteMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroAskForQuoteMessage EXCEPT !.afqReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Request For Execution Message: 17 bytes                                 *)
(***************************************************************************)

RequestForExecutionMessage ==
    [ msgSeqNum   : Sample(4),
      firmId      : Sample(8),
      symbolIndex : Sample(4),
      emm         : Sample(1) ]

EncodeRequestForExecutionMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.symbolIndex
        \o message.emm

DecodeRequestForExecutionMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(firmId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    Ok([ msgSeqNum   |-> msgSeqNum.value,
         firmId      |-> firmId.value,
         symbolIndex |-> symbolIndex.value,
         emm         |-> emm.value ], emm.rest)

ZeroRequestForExecutionMessage ==
    [ msgSeqNum   |-> [i \in 1 .. 4 |-> 0],
      firmId      |-> [i \in 1 .. 8 |-> 0],
      symbolIndex |-> [i \in 1 .. 4 |-> 0],
      emm         |-> [i \in 1 .. 1 |-> 0] ]

(* Request For Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedRequestForExecutionMessage ==
    { ZeroRequestForExecutionMessage }
        \cup { [ZeroRequestForExecutionMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestForExecutionMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroRequestForExecutionMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroRequestForExecutionMessage EXCEPT !.emm = one] : one \in Sample(1) }

(***************************************************************************)
(* Rfq Notification Message: 96 bytes                                      *)
(***************************************************************************)

RfqNotificationMessage ==
    [ msgSeqNum                : Sample(4),
      firmId                   : Sample(8),
      bookIn                   : Sample(8),
      bookOutTimeOptional      : Sample(8),
      oegInFromMeOptional      : Sample(8),
      oegOutToMemberOptional   : Sample(8),
      quoteReqId               : Sample(8),
      orderQty                 : Sample(8),
      counterpartFirmId        : Sample(8),
      symbolIndex              : Sample(4),
      emm                      : Sample(1),
      rfqUpdateType            : Sample(1),
      sideOptional             : Sample(1),
      endClient                : Sample(11),
      darkExecutionInstruction : Sample(1),
      minOrderQty              : Sample(8),
      accountTypeOptional      : Sample(1) ]

EncodeRfqNotificationMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.bookIn
        \o message.bookOutTimeOptional
        \o message.oegInFromMeOptional
        \o message.oegOutToMemberOptional
        \o message.quoteReqId
        \o message.orderQty
        \o message.counterpartFirmId
        \o message.symbolIndex
        \o message.emm
        \o message.rfqUpdateType
        \o message.sideOptional
        \o message.endClient
        \o message.darkExecutionInstruction
        \o message.minOrderQty
        \o message.accountTypeOptional

DecodeRfqNotificationMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET bookIn == ReadBytes(firmId.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET oegInFromMeOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~oegInFromMeOptional.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(oegInFromMeOptional.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(oegOutToMemberOptional.rest, 8) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(quoteReqId.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET counterpartFirmId == ReadBytes(orderQty.rest, 8) IN IF ~counterpartFirmId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(counterpartFirmId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET rfqUpdateType == ReadBytes(emm.rest, 1) IN IF ~rfqUpdateType.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(rfqUpdateType.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET endClient == ReadBytes(sideOptional.rest, 11) IN IF ~endClient.ok THEN Fail ELSE
    LET darkExecutionInstruction == ReadBytes(endClient.rest, 1) IN IF ~darkExecutionInstruction.ok THEN Fail ELSE
    LET minOrderQty == ReadBytes(darkExecutionInstruction.rest, 8) IN IF ~minOrderQty.ok THEN Fail ELSE
    LET accountTypeOptional == ReadBytes(minOrderQty.rest, 1) IN IF ~accountTypeOptional.ok THEN Fail ELSE
    Ok([ msgSeqNum                |-> msgSeqNum.value,
         firmId                   |-> firmId.value,
         bookIn                   |-> bookIn.value,
         bookOutTimeOptional      |-> bookOutTimeOptional.value,
         oegInFromMeOptional      |-> oegInFromMeOptional.value,
         oegOutToMemberOptional   |-> oegOutToMemberOptional.value,
         quoteReqId               |-> quoteReqId.value,
         orderQty                 |-> orderQty.value,
         counterpartFirmId        |-> counterpartFirmId.value,
         symbolIndex              |-> symbolIndex.value,
         emm                      |-> emm.value,
         rfqUpdateType            |-> rfqUpdateType.value,
         sideOptional             |-> sideOptional.value,
         endClient                |-> endClient.value,
         darkExecutionInstruction |-> darkExecutionInstruction.value,
         minOrderQty              |-> minOrderQty.value,
         accountTypeOptional      |-> accountTypeOptional.value ], accountTypeOptional.rest)

ZeroRfqNotificationMessage ==
    [ msgSeqNum                |-> [i \in 1 .. 4 |-> 0],
      firmId                   |-> [i \in 1 .. 8 |-> 0],
      bookIn                   |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional      |-> [i \in 1 .. 8 |-> 0],
      oegInFromMeOptional      |-> [i \in 1 .. 8 |-> 0],
      oegOutToMemberOptional   |-> [i \in 1 .. 8 |-> 0],
      quoteReqId               |-> [i \in 1 .. 8 |-> 0],
      orderQty                 |-> [i \in 1 .. 8 |-> 0],
      counterpartFirmId        |-> [i \in 1 .. 8 |-> 0],
      symbolIndex              |-> [i \in 1 .. 4 |-> 0],
      emm                      |-> [i \in 1 .. 1 |-> 0],
      rfqUpdateType            |-> [i \in 1 .. 1 |-> 0],
      sideOptional             |-> [i \in 1 .. 1 |-> 0],
      endClient                |-> [i \in 1 .. 11 |-> 0],
      darkExecutionInstruction |-> [i \in 1 .. 1 |-> 0],
      minOrderQty              |-> [i \in 1 .. 8 |-> 0],
      accountTypeOptional      |-> [i \in 1 .. 1 |-> 0] ]

(* Rfq Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedRfqNotificationMessage ==
    { ZeroRfqNotificationMessage }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.oegInFromMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.quoteReqId = one] : one \in Sample(8) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.counterpartFirmId = one] : one \in Sample(8) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.rfqUpdateType = one] : one \in Sample(1) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.endClient = one] : one \in Sample(11) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.darkExecutionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.minOrderQty = one] : one \in Sample(8) }
        \cup { [ZeroRfqNotificationMessage EXCEPT !.accountTypeOptional = one] : one \in Sample(1) }

(***************************************************************************)
(* Rfq Matching Status Message: 76 bytes                                   *)
(***************************************************************************)

RfqMatchingStatusMessage ==
    [ msgSeqNum              : Sample(4),
      firmId                 : Sample(8),
      bookIn                 : Sample(8),
      bookOutTimeOptional    : Sample(8),
      oegInFromMeOptional    : Sample(8),
      oegOutToMemberOptional : Sample(8),
      quoteReqId             : Sample(8),
      potentialMatchingPx    : Sample(8),
      potentialMatchingQty   : Sample(8),
      symbolIndex            : Sample(4),
      emm                    : Sample(1),
      side                   : Sample(1),
      numberOfLps            : Sample(1),
      recipientType          : Sample(1) ]

EncodeRfqMatchingStatusMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.bookIn
        \o message.bookOutTimeOptional
        \o message.oegInFromMeOptional
        \o message.oegOutToMemberOptional
        \o message.quoteReqId
        \o message.potentialMatchingPx
        \o message.potentialMatchingQty
        \o message.symbolIndex
        \o message.emm
        \o message.side
        \o message.numberOfLps
        \o message.recipientType

DecodeRfqMatchingStatusMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET bookIn == ReadBytes(firmId.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET oegInFromMeOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~oegInFromMeOptional.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(oegInFromMeOptional.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(oegOutToMemberOptional.rest, 8) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET potentialMatchingPx == ReadBytes(quoteReqId.rest, 8) IN IF ~potentialMatchingPx.ok THEN Fail ELSE
    LET potentialMatchingQty == ReadBytes(potentialMatchingPx.rest, 8) IN IF ~potentialMatchingQty.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(potentialMatchingQty.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET side == ReadBytes(emm.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET numberOfLps == ReadBytes(side.rest, 1) IN IF ~numberOfLps.ok THEN Fail ELSE
    LET recipientType == ReadBytes(numberOfLps.rest, 1) IN IF ~recipientType.ok THEN Fail ELSE
    Ok([ msgSeqNum              |-> msgSeqNum.value,
         firmId                 |-> firmId.value,
         bookIn                 |-> bookIn.value,
         bookOutTimeOptional    |-> bookOutTimeOptional.value,
         oegInFromMeOptional    |-> oegInFromMeOptional.value,
         oegOutToMemberOptional |-> oegOutToMemberOptional.value,
         quoteReqId             |-> quoteReqId.value,
         potentialMatchingPx    |-> potentialMatchingPx.value,
         potentialMatchingQty   |-> potentialMatchingQty.value,
         symbolIndex            |-> symbolIndex.value,
         emm                    |-> emm.value,
         side                   |-> side.value,
         numberOfLps            |-> numberOfLps.value,
         recipientType          |-> recipientType.value ], recipientType.rest)

ZeroRfqMatchingStatusMessage ==
    [ msgSeqNum              |-> [i \in 1 .. 4 |-> 0],
      firmId                 |-> [i \in 1 .. 8 |-> 0],
      bookIn                 |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegInFromMeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegOutToMemberOptional |-> [i \in 1 .. 8 |-> 0],
      quoteReqId             |-> [i \in 1 .. 8 |-> 0],
      potentialMatchingPx    |-> [i \in 1 .. 8 |-> 0],
      potentialMatchingQty   |-> [i \in 1 .. 8 |-> 0],
      symbolIndex            |-> [i \in 1 .. 4 |-> 0],
      emm                    |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0],
      numberOfLps            |-> [i \in 1 .. 1 |-> 0],
      recipientType          |-> [i \in 1 .. 1 |-> 0] ]

(* Rfq Matching Status Message at zero, then each field in turn at the values it is checked at *)
CheckedRfqMatchingStatusMessage ==
    { ZeroRfqMatchingStatusMessage }
        \cup { [ZeroRfqMatchingStatusMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRfqMatchingStatusMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroRfqMatchingStatusMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroRfqMatchingStatusMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroRfqMatchingStatusMessage EXCEPT !.oegInFromMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroRfqMatchingStatusMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroRfqMatchingStatusMessage EXCEPT !.quoteReqId = one] : one \in Sample(8) }
        \cup { [ZeroRfqMatchingStatusMessage EXCEPT !.potentialMatchingPx = one] : one \in Sample(8) }
        \cup { [ZeroRfqMatchingStatusMessage EXCEPT !.potentialMatchingQty = one] : one \in Sample(8) }
        \cup { [ZeroRfqMatchingStatusMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroRfqMatchingStatusMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroRfqMatchingStatusMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroRfqMatchingStatusMessage EXCEPT !.numberOfLps = one] : one \in Sample(1) }
        \cup { [ZeroRfqMatchingStatusMessage EXCEPT !.recipientType = one] : one \in Sample(1) }

(***************************************************************************)
(* Rfqlp Matching Status Message: 66 bytes                                 *)
(***************************************************************************)

RfqlpMatchingStatusMessage ==
    [ msgSeqNum              : Sample(4),
      firmId                 : Sample(8),
      bookIn                 : Sample(8),
      bookOutTimeOptional    : Sample(8),
      oegInFromMeOptional    : Sample(8),
      oegOutToMemberOptional : Sample(8),
      quoteReqId             : Sample(8),
      potentialMatchingQty   : Sample(8),
      symbolIndex            : Sample(4),
      emm                    : Sample(1),
      side                   : Sample(1) ]

EncodeRfqlpMatchingStatusMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.bookIn
        \o message.bookOutTimeOptional
        \o message.oegInFromMeOptional
        \o message.oegOutToMemberOptional
        \o message.quoteReqId
        \o message.potentialMatchingQty
        \o message.symbolIndex
        \o message.emm
        \o message.side

DecodeRfqlpMatchingStatusMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET bookIn == ReadBytes(firmId.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET oegInFromMeOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~oegInFromMeOptional.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(oegInFromMeOptional.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(oegOutToMemberOptional.rest, 8) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET potentialMatchingQty == ReadBytes(quoteReqId.rest, 8) IN IF ~potentialMatchingQty.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(potentialMatchingQty.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET side == ReadBytes(emm.rest, 1) IN IF ~side.ok THEN Fail ELSE
    Ok([ msgSeqNum              |-> msgSeqNum.value,
         firmId                 |-> firmId.value,
         bookIn                 |-> bookIn.value,
         bookOutTimeOptional    |-> bookOutTimeOptional.value,
         oegInFromMeOptional    |-> oegInFromMeOptional.value,
         oegOutToMemberOptional |-> oegOutToMemberOptional.value,
         quoteReqId             |-> quoteReqId.value,
         potentialMatchingQty   |-> potentialMatchingQty.value,
         symbolIndex            |-> symbolIndex.value,
         emm                    |-> emm.value,
         side                   |-> side.value ], side.rest)

ZeroRfqlpMatchingStatusMessage ==
    [ msgSeqNum              |-> [i \in 1 .. 4 |-> 0],
      firmId                 |-> [i \in 1 .. 8 |-> 0],
      bookIn                 |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegInFromMeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegOutToMemberOptional |-> [i \in 1 .. 8 |-> 0],
      quoteReqId             |-> [i \in 1 .. 8 |-> 0],
      potentialMatchingQty   |-> [i \in 1 .. 8 |-> 0],
      symbolIndex            |-> [i \in 1 .. 4 |-> 0],
      emm                    |-> [i \in 1 .. 1 |-> 0],
      side                   |-> [i \in 1 .. 1 |-> 0] ]

(* Rfqlp Matching Status Message at zero, then each field in turn at the values it is checked at *)
CheckedRfqlpMatchingStatusMessage ==
    { ZeroRfqlpMatchingStatusMessage }
        \cup { [ZeroRfqlpMatchingStatusMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRfqlpMatchingStatusMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroRfqlpMatchingStatusMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroRfqlpMatchingStatusMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroRfqlpMatchingStatusMessage EXCEPT !.oegInFromMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroRfqlpMatchingStatusMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroRfqlpMatchingStatusMessage EXCEPT !.quoteReqId = one] : one \in Sample(8) }
        \cup { [ZeroRfqlpMatchingStatusMessage EXCEPT !.potentialMatchingQty = one] : one \in Sample(8) }
        \cup { [ZeroRfqlpMatchingStatusMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroRfqlpMatchingStatusMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroRfqlpMatchingStatusMessage EXCEPT !.side = one] : one \in Sample(1) }

(***************************************************************************)
(* Not Used Groups: 2 bytes                                                *)
(***************************************************************************)

NotUsedGroups5 ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeNotUsedGroups5(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeNotUsedGroups5(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroNotUsedGroups5 ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedNotUsedGroups5 ==
    { ZeroNotUsedGroups5 }
        \cup { [ZeroNotUsedGroups5 EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroNotUsedGroups5 EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* User Notification Message: 56 bytes                                     *)
(***************************************************************************)

UserNotificationMessage ==
    [ msgSeqNum                            : Sample(4),
      firmId                               : Sample(8),
      executionWithinFirmShortCodeOptional : Sample(4),
      clientIdentificationShortcode        : Sample(4),
      familyId                             : Sample(8),
      symbolIndexOptional                  : Sample(4),
      userStatus                           : Sample(1),
      logicalAccessIdOptional              : Sample(4),
      orderSizeLimit                       : Sample(8),
      orderAmountLimit                     : Sample(8),
      exposureSide                         : Sample(1),
      notUsedGroups                        : NotUsedGroups5 ]

EncodeUserNotificationMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.executionWithinFirmShortCodeOptional
        \o message.clientIdentificationShortcode
        \o message.familyId
        \o message.symbolIndexOptional
        \o message.userStatus
        \o message.logicalAccessIdOptional
        \o message.orderSizeLimit
        \o message.orderAmountLimit
        \o message.exposureSide
        \o EncodeNotUsedGroups5(message.notUsedGroups)

DecodeUserNotificationMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET executionWithinFirmShortCodeOptional == ReadBytes(firmId.rest, 4) IN IF ~executionWithinFirmShortCodeOptional.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCodeOptional.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET familyId == ReadBytes(clientIdentificationShortcode.rest, 8) IN IF ~familyId.ok THEN Fail ELSE
    LET symbolIndexOptional == ReadBytes(familyId.rest, 4) IN IF ~symbolIndexOptional.ok THEN Fail ELSE
    LET userStatus == ReadBytes(symbolIndexOptional.rest, 1) IN IF ~userStatus.ok THEN Fail ELSE
    LET logicalAccessIdOptional == ReadBytes(userStatus.rest, 4) IN IF ~logicalAccessIdOptional.ok THEN Fail ELSE
    LET orderSizeLimit == ReadBytes(logicalAccessIdOptional.rest, 8) IN IF ~orderSizeLimit.ok THEN Fail ELSE
    LET orderAmountLimit == ReadBytes(orderSizeLimit.rest, 8) IN IF ~orderAmountLimit.ok THEN Fail ELSE
    LET exposureSide == ReadBytes(orderAmountLimit.rest, 1) IN IF ~exposureSide.ok THEN Fail ELSE
    LET notUsedGroups == DecodeNotUsedGroups5(exposureSide.rest) IN IF ~notUsedGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                            |-> msgSeqNum.value,
         firmId                               |-> firmId.value,
         executionWithinFirmShortCodeOptional |-> executionWithinFirmShortCodeOptional.value,
         clientIdentificationShortcode        |-> clientIdentificationShortcode.value,
         familyId                             |-> familyId.value,
         symbolIndexOptional                  |-> symbolIndexOptional.value,
         userStatus                           |-> userStatus.value,
         logicalAccessIdOptional              |-> logicalAccessIdOptional.value,
         orderSizeLimit                       |-> orderSizeLimit.value,
         orderAmountLimit                     |-> orderAmountLimit.value,
         exposureSide                         |-> exposureSide.value,
         notUsedGroups                        |-> notUsedGroups.value ], notUsedGroups.rest)

ZeroUserNotificationMessage ==
    [ msgSeqNum                            |-> [i \in 1 .. 4 |-> 0],
      firmId                               |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCodeOptional |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode        |-> [i \in 1 .. 4 |-> 0],
      familyId                             |-> [i \in 1 .. 8 |-> 0],
      symbolIndexOptional                  |-> [i \in 1 .. 4 |-> 0],
      userStatus                           |-> [i \in 1 .. 1 |-> 0],
      logicalAccessIdOptional              |-> [i \in 1 .. 4 |-> 0],
      orderSizeLimit                       |-> [i \in 1 .. 8 |-> 0],
      orderAmountLimit                     |-> [i \in 1 .. 8 |-> 0],
      exposureSide                         |-> [i \in 1 .. 1 |-> 0],
      notUsedGroups                        |-> ZeroNotUsedGroups5 ]

(* User Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedUserNotificationMessage ==
    { ZeroUserNotificationMessage }
        \cup { [ZeroUserNotificationMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroUserNotificationMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroUserNotificationMessage EXCEPT !.executionWithinFirmShortCodeOptional = one] : one \in Sample(4) }
        \cup { [ZeroUserNotificationMessage EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroUserNotificationMessage EXCEPT !.familyId = one] : one \in Sample(8) }
        \cup { [ZeroUserNotificationMessage EXCEPT !.symbolIndexOptional = one] : one \in Sample(4) }
        \cup { [ZeroUserNotificationMessage EXCEPT !.userStatus = one] : one \in Sample(1) }
        \cup { [ZeroUserNotificationMessage EXCEPT !.logicalAccessIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroUserNotificationMessage EXCEPT !.orderSizeLimit = one] : one \in Sample(8) }
        \cup { [ZeroUserNotificationMessage EXCEPT !.orderAmountLimit = one] : one \in Sample(8) }
        \cup { [ZeroUserNotificationMessage EXCEPT !.exposureSide = one] : one \in Sample(1) }
        \cup { [ZeroUserNotificationMessage EXCEPT !.notUsedGroups = one] : one \in CheckedNotUsedGroups5 }

(***************************************************************************)
(* Mm Sign In Message: 102 bytes                                           *)
(***************************************************************************)

MmSignInMessage ==
    [ clMsgSeqNum                  : Sample(4),
      firmId                       : Sample(8),
      sendingTime                  : Sample(8),
      logicalAccessId              : Sample(4),
      oePartitionId                : Sample(2),
      clientOrderId                : Sample(8),
      symbolIndex                  : Sample(4),
      emm                          : Sample(1),
      executionWithinFirmShortCode : Sample(4),
      clearingFirmId               : Sample(8),
      accountNumber                : Sample(12),
      technicalOrigin              : Sample(1),
      openClose                    : Sample(2),
      clearingInstruction          : Sample(2),
      freeText                     : Sample(18),
      longClientId                 : Sample(16) ]

EncodeMmSignInMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.logicalAccessId
        \o message.oePartitionId
        \o message.clientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.executionWithinFirmShortCode
        \o message.clearingFirmId
        \o message.accountNumber
        \o message.technicalOrigin
        \o message.openClose
        \o message.clearingInstruction
        \o message.freeText
        \o message.longClientId

DecodeMmSignInMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET logicalAccessId == ReadBytes(sendingTime.rest, 4) IN IF ~logicalAccessId.ok THEN Fail ELSE
    LET oePartitionId == ReadBytes(logicalAccessId.rest, 2) IN IF ~oePartitionId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(oePartitionId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(emm.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET clearingFirmId == ReadBytes(executionWithinFirmShortCode.rest, 8) IN IF ~clearingFirmId.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(clearingFirmId.rest, 12) IN IF ~accountNumber.ok THEN Fail ELSE
    LET technicalOrigin == ReadBytes(accountNumber.rest, 1) IN IF ~technicalOrigin.ok THEN Fail ELSE
    LET openClose == ReadBytes(technicalOrigin.rest, 2) IN IF ~openClose.ok THEN Fail ELSE
    LET clearingInstruction == ReadBytes(openClose.rest, 2) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET freeText == ReadBytes(clearingInstruction.rest, 18) IN IF ~freeText.ok THEN Fail ELSE
    LET longClientId == ReadBytes(freeText.rest, 16) IN IF ~longClientId.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                  |-> clMsgSeqNum.value,
         firmId                       |-> firmId.value,
         sendingTime                  |-> sendingTime.value,
         logicalAccessId              |-> logicalAccessId.value,
         oePartitionId                |-> oePartitionId.value,
         clientOrderId                |-> clientOrderId.value,
         symbolIndex                  |-> symbolIndex.value,
         emm                          |-> emm.value,
         executionWithinFirmShortCode |-> executionWithinFirmShortCode.value,
         clearingFirmId               |-> clearingFirmId.value,
         accountNumber                |-> accountNumber.value,
         technicalOrigin              |-> technicalOrigin.value,
         openClose                    |-> openClose.value,
         clearingInstruction          |-> clearingInstruction.value,
         freeText                     |-> freeText.value,
         longClientId                 |-> longClientId.value ], longClientId.rest)

ZeroMmSignInMessage ==
    [ clMsgSeqNum                  |-> [i \in 1 .. 4 |-> 0],
      firmId                       |-> [i \in 1 .. 8 |-> 0],
      sendingTime                  |-> [i \in 1 .. 8 |-> 0],
      logicalAccessId              |-> [i \in 1 .. 4 |-> 0],
      oePartitionId                |-> [i \in 1 .. 2 |-> 0],
      clientOrderId                |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                  |-> [i \in 1 .. 4 |-> 0],
      emm                          |-> [i \in 1 .. 1 |-> 0],
      executionWithinFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      clearingFirmId               |-> [i \in 1 .. 8 |-> 0],
      accountNumber                |-> [i \in 1 .. 12 |-> 0],
      technicalOrigin              |-> [i \in 1 .. 1 |-> 0],
      openClose                    |-> [i \in 1 .. 2 |-> 0],
      clearingInstruction          |-> [i \in 1 .. 2 |-> 0],
      freeText                     |-> [i \in 1 .. 18 |-> 0],
      longClientId                 |-> [i \in 1 .. 16 |-> 0] ]

(* Mm Sign In Message at zero, then each field in turn at the values it is checked at *)
CheckedMmSignInMessage ==
    { ZeroMmSignInMessage }
        \cup { [ZeroMmSignInMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMmSignInMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroMmSignInMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroMmSignInMessage EXCEPT !.logicalAccessId = one] : one \in Sample(4) }
        \cup { [ZeroMmSignInMessage EXCEPT !.oePartitionId = one] : one \in Sample(2) }
        \cup { [ZeroMmSignInMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroMmSignInMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroMmSignInMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroMmSignInMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroMmSignInMessage EXCEPT !.clearingFirmId = one] : one \in Sample(8) }
        \cup { [ZeroMmSignInMessage EXCEPT !.accountNumber = one] : one \in Sample(12) }
        \cup { [ZeroMmSignInMessage EXCEPT !.technicalOrigin = one] : one \in Sample(1) }
        \cup { [ZeroMmSignInMessage EXCEPT !.openClose = one] : one \in Sample(2) }
        \cup { [ZeroMmSignInMessage EXCEPT !.clearingInstruction = one] : one \in Sample(2) }
        \cup { [ZeroMmSignInMessage EXCEPT !.freeText = one] : one \in Sample(18) }
        \cup { [ZeroMmSignInMessage EXCEPT !.longClientId = one] : one \in Sample(16) }

(***************************************************************************)
(* Mm Sign In Ack Message: 150 bytes                                       *)
(***************************************************************************)

MmSignInAckMessage ==
    [ msgSeqNum                    : Sample(4),
      firmId                       : Sample(8),
      sendingTimeOptional          : Sample(8),
      oegInFromMember              : Sample(8),
      oegOutTimeToMe               : Sample(8),
      bookIn                       : Sample(8),
      bookOutTimeOptional          : Sample(8),
      oegInFromMeOptional          : Sample(8),
      oegOutToMemberOptional       : Sample(8),
      logicalAccessId              : Sample(4),
      oePartitionId                : Sample(2),
      clientOrderId                : Sample(8),
      symbolIndex                  : Sample(4),
      emm                          : Sample(1),
      executionWithinFirmShortCode : Sample(4),
      clearingFirmId               : Sample(8),
      accountNumber                : Sample(12),
      technicalOrigin              : Sample(1),
      openClose                    : Sample(2),
      clearingInstruction          : Sample(2),
      freeText                     : Sample(18),
      longClientId                 : Sample(16) ]

EncodeMmSignInAckMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.sendingTimeOptional
        \o message.oegInFromMember
        \o message.oegOutTimeToMe
        \o message.bookIn
        \o message.bookOutTimeOptional
        \o message.oegInFromMeOptional
        \o message.oegOutToMemberOptional
        \o message.logicalAccessId
        \o message.oePartitionId
        \o message.clientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.executionWithinFirmShortCode
        \o message.clearingFirmId
        \o message.accountNumber
        \o message.technicalOrigin
        \o message.openClose
        \o message.clearingInstruction
        \o message.freeText
        \o message.longClientId

DecodeMmSignInAckMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTimeOptional == ReadBytes(firmId.rest, 8) IN IF ~sendingTimeOptional.ok THEN Fail ELSE
    LET oegInFromMember == ReadBytes(sendingTimeOptional.rest, 8) IN IF ~oegInFromMember.ok THEN Fail ELSE
    LET oegOutTimeToMe == ReadBytes(oegInFromMember.rest, 8) IN IF ~oegOutTimeToMe.ok THEN Fail ELSE
    LET bookIn == ReadBytes(oegOutTimeToMe.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET oegInFromMeOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~oegInFromMeOptional.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(oegInFromMeOptional.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET logicalAccessId == ReadBytes(oegOutToMemberOptional.rest, 4) IN IF ~logicalAccessId.ok THEN Fail ELSE
    LET oePartitionId == ReadBytes(logicalAccessId.rest, 2) IN IF ~oePartitionId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(oePartitionId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(emm.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET clearingFirmId == ReadBytes(executionWithinFirmShortCode.rest, 8) IN IF ~clearingFirmId.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(clearingFirmId.rest, 12) IN IF ~accountNumber.ok THEN Fail ELSE
    LET technicalOrigin == ReadBytes(accountNumber.rest, 1) IN IF ~technicalOrigin.ok THEN Fail ELSE
    LET openClose == ReadBytes(technicalOrigin.rest, 2) IN IF ~openClose.ok THEN Fail ELSE
    LET clearingInstruction == ReadBytes(openClose.rest, 2) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET freeText == ReadBytes(clearingInstruction.rest, 18) IN IF ~freeText.ok THEN Fail ELSE
    LET longClientId == ReadBytes(freeText.rest, 16) IN IF ~longClientId.ok THEN Fail ELSE
    Ok([ msgSeqNum                    |-> msgSeqNum.value,
         firmId                       |-> firmId.value,
         sendingTimeOptional          |-> sendingTimeOptional.value,
         oegInFromMember              |-> oegInFromMember.value,
         oegOutTimeToMe               |-> oegOutTimeToMe.value,
         bookIn                       |-> bookIn.value,
         bookOutTimeOptional          |-> bookOutTimeOptional.value,
         oegInFromMeOptional          |-> oegInFromMeOptional.value,
         oegOutToMemberOptional       |-> oegOutToMemberOptional.value,
         logicalAccessId              |-> logicalAccessId.value,
         oePartitionId                |-> oePartitionId.value,
         clientOrderId                |-> clientOrderId.value,
         symbolIndex                  |-> symbolIndex.value,
         emm                          |-> emm.value,
         executionWithinFirmShortCode |-> executionWithinFirmShortCode.value,
         clearingFirmId               |-> clearingFirmId.value,
         accountNumber                |-> accountNumber.value,
         technicalOrigin              |-> technicalOrigin.value,
         openClose                    |-> openClose.value,
         clearingInstruction          |-> clearingInstruction.value,
         freeText                     |-> freeText.value,
         longClientId                 |-> longClientId.value ], longClientId.rest)

ZeroMmSignInAckMessage ==
    [ msgSeqNum                    |-> [i \in 1 .. 4 |-> 0],
      firmId                       |-> [i \in 1 .. 8 |-> 0],
      sendingTimeOptional          |-> [i \in 1 .. 8 |-> 0],
      oegInFromMember              |-> [i \in 1 .. 8 |-> 0],
      oegOutTimeToMe               |-> [i \in 1 .. 8 |-> 0],
      bookIn                       |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional          |-> [i \in 1 .. 8 |-> 0],
      oegInFromMeOptional          |-> [i \in 1 .. 8 |-> 0],
      oegOutToMemberOptional       |-> [i \in 1 .. 8 |-> 0],
      logicalAccessId              |-> [i \in 1 .. 4 |-> 0],
      oePartitionId                |-> [i \in 1 .. 2 |-> 0],
      clientOrderId                |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                  |-> [i \in 1 .. 4 |-> 0],
      emm                          |-> [i \in 1 .. 1 |-> 0],
      executionWithinFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      clearingFirmId               |-> [i \in 1 .. 8 |-> 0],
      accountNumber                |-> [i \in 1 .. 12 |-> 0],
      technicalOrigin              |-> [i \in 1 .. 1 |-> 0],
      openClose                    |-> [i \in 1 .. 2 |-> 0],
      clearingInstruction          |-> [i \in 1 .. 2 |-> 0],
      freeText                     |-> [i \in 1 .. 18 |-> 0],
      longClientId                 |-> [i \in 1 .. 16 |-> 0] ]

(* Mm Sign In Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedMmSignInAckMessage ==
    { ZeroMmSignInAckMessage }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.sendingTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.oegInFromMember = one] : one \in Sample(8) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.oegOutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.oegInFromMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.logicalAccessId = one] : one \in Sample(4) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.oePartitionId = one] : one \in Sample(2) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.clearingFirmId = one] : one \in Sample(8) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.accountNumber = one] : one \in Sample(12) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.technicalOrigin = one] : one \in Sample(1) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.openClose = one] : one \in Sample(2) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.clearingInstruction = one] : one \in Sample(2) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.freeText = one] : one \in Sample(18) }
        \cup { [ZeroMmSignInAckMessage EXCEPT !.longClientId = one] : one \in Sample(16) }

(***************************************************************************)
(* Instrument Synchronization Group: 5 bytes                               *)
(***************************************************************************)

InstrumentSynchronizationGroup ==
    [ symbolIndex : Sample(4),
      emm         : Sample(1) ]

EncodeInstrumentSynchronizationGroup(message) ==
    message.symbolIndex
        \o message.emm

DecodeInstrumentSynchronizationGroup(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    Ok([ symbolIndex |-> symbolIndex.value,
         emm         |-> emm.value ], emm.rest)

ZeroInstrumentSynchronizationGroup ==
    [ symbolIndex |-> [i \in 1 .. 4 |-> 0],
      emm         |-> [i \in 1 .. 1 |-> 0] ]

(* Instrument Synchronization Group at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentSynchronizationGroup ==
    { ZeroInstrumentSynchronizationGroup }
        \cup { [ZeroInstrumentSynchronizationGroup EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentSynchronizationGroup EXCEPT !.emm = one] : one \in Sample(1) }

(* A run of Instrument Synchronization Group, written one after another *)
RECURSIVE EncodeInstrumentSynchronizationGroupList(_)
EncodeInstrumentSynchronizationGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeInstrumentSynchronizationGroup(Head(messages)) \o EncodeInstrumentSynchronizationGroupList(Tail(messages))

(* As many Instrument Synchronization Group as the field that counts them says *)
RECURSIVE ReadInstrumentSynchronizationGroupList(_, _)
ReadInstrumentSynchronizationGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeInstrumentSynchronizationGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadInstrumentSynchronizationGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Instrument Synchronization Group of each kind, for the lists that carry them *)
OneInstrumentSynchronizationGroup == { ZeroInstrumentSynchronizationGroup }

(***************************************************************************)
(* Instrument Synchronization Groups                                       *)
(***************************************************************************)

InstrumentSynchronizationGroups ==
    [ blockLengthShort               : Sample(1),
      instrumentSynchronizationGroup : SampleLists(OneInstrumentSynchronizationGroup) ]

EncodeInstrumentSynchronizationGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.instrumentSynchronizationGroup), 1)
        \o EncodeInstrumentSynchronizationGroupList(message.instrumentSynchronizationGroup)

DecodeInstrumentSynchronizationGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET instrumentSynchronizationGroup == ReadInstrumentSynchronizationGroupList(numInGroup.rest, numInGroup.value) IN IF ~instrumentSynchronizationGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort               |-> blockLengthShort.value,
         instrumentSynchronizationGroup |-> instrumentSynchronizationGroup.value ], instrumentSynchronizationGroup.rest)

ZeroInstrumentSynchronizationGroups ==
    [ blockLengthShort               |-> [i \in 1 .. 1 |-> 0],
      instrumentSynchronizationGroup |-> << >> ]

(* Instrument Synchronization Groups at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentSynchronizationGroups ==
    { ZeroInstrumentSynchronizationGroups }
        \cup { [ZeroInstrumentSynchronizationGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentSynchronizationGroups EXCEPT !.instrumentSynchronizationGroup = one] : one \in SampleLists(OneInstrumentSynchronizationGroup) }

(***************************************************************************)
(* Instrument Synchronization List Message                                 *)
(***************************************************************************)

InstrumentSynchronizationListMessage ==
    [ msgSeqNum                       : Sample(4),
      oegOutToMemberOptional          : Sample(8),
      resynchronizationId             : Sample(2),
      instrumentSynchronizationGroups : InstrumentSynchronizationGroups ]

EncodeInstrumentSynchronizationListMessage(message) ==
    message.msgSeqNum
        \o message.oegOutToMemberOptional
        \o message.resynchronizationId
        \o EncodeInstrumentSynchronizationGroups(message.instrumentSynchronizationGroups)

DecodeInstrumentSynchronizationListMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(msgSeqNum.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET resynchronizationId == ReadBytes(oegOutToMemberOptional.rest, 2) IN IF ~resynchronizationId.ok THEN Fail ELSE
    LET instrumentSynchronizationGroups == DecodeInstrumentSynchronizationGroups(resynchronizationId.rest) IN IF ~instrumentSynchronizationGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                       |-> msgSeqNum.value,
         oegOutToMemberOptional          |-> oegOutToMemberOptional.value,
         resynchronizationId             |-> resynchronizationId.value,
         instrumentSynchronizationGroups |-> instrumentSynchronizationGroups.value ], instrumentSynchronizationGroups.rest)

ZeroInstrumentSynchronizationListMessage ==
    [ msgSeqNum                       |-> [i \in 1 .. 4 |-> 0],
      oegOutToMemberOptional          |-> [i \in 1 .. 8 |-> 0],
      resynchronizationId             |-> [i \in 1 .. 2 |-> 0],
      instrumentSynchronizationGroups |-> ZeroInstrumentSynchronizationGroups ]

(* Instrument Synchronization List Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentSynchronizationListMessage ==
    { ZeroInstrumentSynchronizationListMessage }
        \cup { [ZeroInstrumentSynchronizationListMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentSynchronizationListMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroInstrumentSynchronizationListMessage EXCEPT !.resynchronizationId = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentSynchronizationListMessage EXCEPT !.instrumentSynchronizationGroups = one] : one \in CheckedInstrumentSynchronizationGroups }

(***************************************************************************)
(* Synchronization Time Message: 22 bytes                                  *)
(***************************************************************************)

SynchronizationTimeMessage ==
    [ msgSeqNum              : Sample(4),
      oegOutToMemberOptional : Sample(8),
      resynchronizationId    : Sample(2),
      lastBookInTime         : Sample(8) ]

EncodeSynchronizationTimeMessage(message) ==
    message.msgSeqNum
        \o message.oegOutToMemberOptional
        \o message.resynchronizationId
        \o message.lastBookInTime

DecodeSynchronizationTimeMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(msgSeqNum.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET resynchronizationId == ReadBytes(oegOutToMemberOptional.rest, 2) IN IF ~resynchronizationId.ok THEN Fail ELSE
    LET lastBookInTime == ReadBytes(resynchronizationId.rest, 8) IN IF ~lastBookInTime.ok THEN Fail ELSE
    Ok([ msgSeqNum              |-> msgSeqNum.value,
         oegOutToMemberOptional |-> oegOutToMemberOptional.value,
         resynchronizationId    |-> resynchronizationId.value,
         lastBookInTime         |-> lastBookInTime.value ], lastBookInTime.rest)

ZeroSynchronizationTimeMessage ==
    [ msgSeqNum              |-> [i \in 1 .. 4 |-> 0],
      oegOutToMemberOptional |-> [i \in 1 .. 8 |-> 0],
      resynchronizationId    |-> [i \in 1 .. 2 |-> 0],
      lastBookInTime         |-> [i \in 1 .. 8 |-> 0] ]

(* Synchronization Time Message at zero, then each field in turn at the values it is checked at *)
CheckedSynchronizationTimeMessage ==
    { ZeroSynchronizationTimeMessage }
        \cup { [ZeroSynchronizationTimeMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroSynchronizationTimeMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroSynchronizationTimeMessage EXCEPT !.resynchronizationId = one] : one \in Sample(2) }
        \cup { [ZeroSynchronizationTimeMessage EXCEPT !.lastBookInTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Strategy Legs Group: 35 bytes                                           *)
(***************************************************************************)

StrategyLegsGroup ==
    [ legSymbolIndex     : Sample(4),
      legRatio           : Sample(4),
      legSecurityType    : Sample(1),
      legPutOrCall       : Sample(1),
      legPriceOptional   : Sample(8),
      legStrikePrice     : Sample(8),
      legLastTradingDate : Sample(8),
      legSide            : Sample(1) ]

EncodeStrategyLegsGroup(message) ==
    message.legSymbolIndex
        \o message.legRatio
        \o message.legSecurityType
        \o message.legPutOrCall
        \o message.legPriceOptional
        \o message.legStrikePrice
        \o message.legLastTradingDate
        \o message.legSide

DecodeStrategyLegsGroup(bytes) ==
    LET legSymbolIndex == ReadBytes(bytes, 4) IN IF ~legSymbolIndex.ok THEN Fail ELSE
    LET legRatio == ReadBytes(legSymbolIndex.rest, 4) IN IF ~legRatio.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legRatio.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    LET legPutOrCall == ReadBytes(legSecurityType.rest, 1) IN IF ~legPutOrCall.ok THEN Fail ELSE
    LET legPriceOptional == ReadBytes(legPutOrCall.rest, 8) IN IF ~legPriceOptional.ok THEN Fail ELSE
    LET legStrikePrice == ReadBytes(legPriceOptional.rest, 8) IN IF ~legStrikePrice.ok THEN Fail ELSE
    LET legLastTradingDate == ReadBytes(legStrikePrice.rest, 8) IN IF ~legLastTradingDate.ok THEN Fail ELSE
    LET legSide == ReadBytes(legLastTradingDate.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    Ok([ legSymbolIndex     |-> legSymbolIndex.value,
         legRatio           |-> legRatio.value,
         legSecurityType    |-> legSecurityType.value,
         legPutOrCall       |-> legPutOrCall.value,
         legPriceOptional   |-> legPriceOptional.value,
         legStrikePrice     |-> legStrikePrice.value,
         legLastTradingDate |-> legLastTradingDate.value,
         legSide            |-> legSide.value ], legSide.rest)

ZeroStrategyLegsGroup ==
    [ legSymbolIndex     |-> [i \in 1 .. 4 |-> 0],
      legRatio           |-> [i \in 1 .. 4 |-> 0],
      legSecurityType    |-> [i \in 1 .. 1 |-> 0],
      legPutOrCall       |-> [i \in 1 .. 1 |-> 0],
      legPriceOptional   |-> [i \in 1 .. 8 |-> 0],
      legStrikePrice     |-> [i \in 1 .. 8 |-> 0],
      legLastTradingDate |-> [i \in 1 .. 8 |-> 0],
      legSide            |-> [i \in 1 .. 1 |-> 0] ]

(* Strategy Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedStrategyLegsGroup ==
    { ZeroStrategyLegsGroup }
        \cup { [ZeroStrategyLegsGroup EXCEPT !.legSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLegsGroup EXCEPT !.legRatio = one] : one \in Sample(4) }
        \cup { [ZeroStrategyLegsGroup EXCEPT !.legSecurityType = one] : one \in Sample(1) }
        \cup { [ZeroStrategyLegsGroup EXCEPT !.legPutOrCall = one] : one \in Sample(1) }
        \cup { [ZeroStrategyLegsGroup EXCEPT !.legPriceOptional = one] : one \in Sample(8) }
        \cup { [ZeroStrategyLegsGroup EXCEPT !.legStrikePrice = one] : one \in Sample(8) }
        \cup { [ZeroStrategyLegsGroup EXCEPT !.legLastTradingDate = one] : one \in Sample(8) }
        \cup { [ZeroStrategyLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }

(* A run of Strategy Legs Group, written one after another *)
RECURSIVE EncodeStrategyLegsGroupList(_)
EncodeStrategyLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeStrategyLegsGroup(Head(messages)) \o EncodeStrategyLegsGroupList(Tail(messages))

(* As many Strategy Legs Group as the field that counts them says *)
RECURSIVE ReadStrategyLegsGroupList(_, _)
ReadStrategyLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeStrategyLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadStrategyLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Strategy Legs Group of each kind, for the lists that carry them *)
OneStrategyLegsGroup == { ZeroStrategyLegsGroup }

(***************************************************************************)
(* Strategy Legs Groups                                                    *)
(***************************************************************************)

StrategyLegsGroups ==
    [ blockLengthShort  : Sample(1),
      strategyLegsGroup : SampleLists(OneStrategyLegsGroup) ]

EncodeStrategyLegsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.strategyLegsGroup), 1)
        \o EncodeStrategyLegsGroupList(message.strategyLegsGroup)

DecodeStrategyLegsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET strategyLegsGroup == ReadStrategyLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~strategyLegsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort  |-> blockLengthShort.value,
         strategyLegsGroup |-> strategyLegsGroup.value ], strategyLegsGroup.rest)

ZeroStrategyLegsGroups ==
    [ blockLengthShort  |-> [i \in 1 .. 1 |-> 0],
      strategyLegsGroup |-> << >> ]

(* Strategy Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedStrategyLegsGroups ==
    { ZeroStrategyLegsGroups }
        \cup { [ZeroStrategyLegsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroStrategyLegsGroups EXCEPT !.strategyLegsGroup = one] : one \in SampleLists(OneStrategyLegsGroup) }

(***************************************************************************)
(* Security Definition Request Message                                     *)
(***************************************************************************)

SecurityDefinitionRequestMessage ==
    [ clMsgSeqNum         : Sample(4),
      firmId              : Sample(8),
      sendingTime         : Sample(8),
      securityReqId       : Sample(8),
      contractSymbolIndex : Sample(4),
      strategyCode        : Sample(1),
      strategyLegsGroups  : StrategyLegsGroups ]

EncodeSecurityDefinitionRequestMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.securityReqId
        \o message.contractSymbolIndex
        \o message.strategyCode
        \o EncodeStrategyLegsGroups(message.strategyLegsGroups)

DecodeSecurityDefinitionRequestMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET securityReqId == ReadBytes(sendingTime.rest, 8) IN IF ~securityReqId.ok THEN Fail ELSE
    LET contractSymbolIndex == ReadBytes(securityReqId.rest, 4) IN IF ~contractSymbolIndex.ok THEN Fail ELSE
    LET strategyCode == ReadBytes(contractSymbolIndex.rest, 1) IN IF ~strategyCode.ok THEN Fail ELSE
    LET strategyLegsGroups == DecodeStrategyLegsGroups(strategyCode.rest) IN IF ~strategyLegsGroups.ok THEN Fail ELSE
    Ok([ clMsgSeqNum         |-> clMsgSeqNum.value,
         firmId              |-> firmId.value,
         sendingTime         |-> sendingTime.value,
         securityReqId       |-> securityReqId.value,
         contractSymbolIndex |-> contractSymbolIndex.value,
         strategyCode        |-> strategyCode.value,
         strategyLegsGroups  |-> strategyLegsGroups.value ], strategyLegsGroups.rest)

ZeroSecurityDefinitionRequestMessage ==
    [ clMsgSeqNum         |-> [i \in 1 .. 4 |-> 0],
      firmId              |-> [i \in 1 .. 8 |-> 0],
      sendingTime         |-> [i \in 1 .. 8 |-> 0],
      securityReqId       |-> [i \in 1 .. 8 |-> 0],
      contractSymbolIndex |-> [i \in 1 .. 4 |-> 0],
      strategyCode        |-> [i \in 1 .. 1 |-> 0],
      strategyLegsGroups  |-> ZeroStrategyLegsGroups ]

(* Security Definition Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionRequestMessage ==
    { ZeroSecurityDefinitionRequestMessage }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.securityReqId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.contractSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.strategyCode = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionRequestMessage EXCEPT !.strategyLegsGroups = one] : one \in CheckedStrategyLegsGroups }

(***************************************************************************)
(* Security Definition Ack Message: 80 bytes                               *)
(***************************************************************************)

SecurityDefinitionAckMessage ==
    [ msgSeqNum              : Sample(4),
      firmId                 : Sample(8),
      sendingTimeOptional    : Sample(8),
      oegInFromMember        : Sample(8),
      oegOutTimeToMe         : Sample(8),
      bookInOptional         : Sample(8),
      bookOutTimeOptional    : Sample(8),
      oegInFromMeOptional    : Sample(8),
      oegOutToMemberOptional : Sample(8),
      securityReqId          : Sample(8),
      symbolIndex            : Sample(4) ]

EncodeSecurityDefinitionAckMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.sendingTimeOptional
        \o message.oegInFromMember
        \o message.oegOutTimeToMe
        \o message.bookInOptional
        \o message.bookOutTimeOptional
        \o message.oegInFromMeOptional
        \o message.oegOutToMemberOptional
        \o message.securityReqId
        \o message.symbolIndex

DecodeSecurityDefinitionAckMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTimeOptional == ReadBytes(firmId.rest, 8) IN IF ~sendingTimeOptional.ok THEN Fail ELSE
    LET oegInFromMember == ReadBytes(sendingTimeOptional.rest, 8) IN IF ~oegInFromMember.ok THEN Fail ELSE
    LET oegOutTimeToMe == ReadBytes(oegInFromMember.rest, 8) IN IF ~oegOutTimeToMe.ok THEN Fail ELSE
    LET bookInOptional == ReadBytes(oegOutTimeToMe.rest, 8) IN IF ~bookInOptional.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(bookInOptional.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET oegInFromMeOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~oegInFromMeOptional.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(oegInFromMeOptional.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET securityReqId == ReadBytes(oegOutToMemberOptional.rest, 8) IN IF ~securityReqId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(securityReqId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    Ok([ msgSeqNum              |-> msgSeqNum.value,
         firmId                 |-> firmId.value,
         sendingTimeOptional    |-> sendingTimeOptional.value,
         oegInFromMember        |-> oegInFromMember.value,
         oegOutTimeToMe         |-> oegOutTimeToMe.value,
         bookInOptional         |-> bookInOptional.value,
         bookOutTimeOptional    |-> bookOutTimeOptional.value,
         oegInFromMeOptional    |-> oegInFromMeOptional.value,
         oegOutToMemberOptional |-> oegOutToMemberOptional.value,
         securityReqId          |-> securityReqId.value,
         symbolIndex            |-> symbolIndex.value ], symbolIndex.rest)

ZeroSecurityDefinitionAckMessage ==
    [ msgSeqNum              |-> [i \in 1 .. 4 |-> 0],
      firmId                 |-> [i \in 1 .. 8 |-> 0],
      sendingTimeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegInFromMember        |-> [i \in 1 .. 8 |-> 0],
      oegOutTimeToMe         |-> [i \in 1 .. 8 |-> 0],
      bookInOptional         |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegInFromMeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegOutToMemberOptional |-> [i \in 1 .. 8 |-> 0],
      securityReqId          |-> [i \in 1 .. 8 |-> 0],
      symbolIndex            |-> [i \in 1 .. 4 |-> 0] ]

(* Security Definition Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionAckMessage ==
    { ZeroSecurityDefinitionAckMessage }
        \cup { [ZeroSecurityDefinitionAckMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionAckMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionAckMessage EXCEPT !.sendingTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionAckMessage EXCEPT !.oegInFromMember = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionAckMessage EXCEPT !.oegOutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionAckMessage EXCEPT !.bookInOptional = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionAckMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionAckMessage EXCEPT !.oegInFromMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionAckMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionAckMessage EXCEPT !.securityReqId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionAckMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }

(***************************************************************************)
(* Mmp Request Group: 10 bytes                                             *)
(***************************************************************************)

MmpRequestGroup ==
    [ protectionType      : Sample(1),
      protectionThreshold : Sample(8),
      breachAction        : Sample(1) ]

EncodeMmpRequestGroup(message) ==
    message.protectionType
        \o message.protectionThreshold
        \o message.breachAction

DecodeMmpRequestGroup(bytes) ==
    LET protectionType == ReadBytes(bytes, 1) IN IF ~protectionType.ok THEN Fail ELSE
    LET protectionThreshold == ReadBytes(protectionType.rest, 8) IN IF ~protectionThreshold.ok THEN Fail ELSE
    LET breachAction == ReadBytes(protectionThreshold.rest, 1) IN IF ~breachAction.ok THEN Fail ELSE
    Ok([ protectionType      |-> protectionType.value,
         protectionThreshold |-> protectionThreshold.value,
         breachAction        |-> breachAction.value ], breachAction.rest)

ZeroMmpRequestGroup ==
    [ protectionType      |-> [i \in 1 .. 1 |-> 0],
      protectionThreshold |-> [i \in 1 .. 8 |-> 0],
      breachAction        |-> [i \in 1 .. 1 |-> 0] ]

(* Mmp Request Group at zero, then each field in turn at the values it is checked at *)
CheckedMmpRequestGroup ==
    { ZeroMmpRequestGroup }
        \cup { [ZeroMmpRequestGroup EXCEPT !.protectionType = one] : one \in Sample(1) }
        \cup { [ZeroMmpRequestGroup EXCEPT !.protectionThreshold = one] : one \in Sample(8) }
        \cup { [ZeroMmpRequestGroup EXCEPT !.breachAction = one] : one \in Sample(1) }

(* A run of Mmp Request Group, written one after another *)
RECURSIVE EncodeMmpRequestGroupList(_)
EncodeMmpRequestGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMmpRequestGroup(Head(messages)) \o EncodeMmpRequestGroupList(Tail(messages))

(* As many Mmp Request Group as the field that counts them says *)
RECURSIVE ReadMmpRequestGroupList(_, _)
ReadMmpRequestGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMmpRequestGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMmpRequestGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mmp Request Group of each kind, for the lists that carry them *)
OneMmpRequestGroup == { ZeroMmpRequestGroup }

(***************************************************************************)
(* Mmp Request Groups                                                      *)
(***************************************************************************)

MmpRequestGroups ==
    [ blockLengthShort : Sample(1),
      mmpRequestGroup  : SampleLists(OneMmpRequestGroup) ]

EncodeMmpRequestGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.mmpRequestGroup), 1)
        \o EncodeMmpRequestGroupList(message.mmpRequestGroup)

DecodeMmpRequestGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET mmpRequestGroup == ReadMmpRequestGroupList(numInGroup.rest, numInGroup.value) IN IF ~mmpRequestGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         mmpRequestGroup  |-> mmpRequestGroup.value ], mmpRequestGroup.rest)

ZeroMmpRequestGroups ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      mmpRequestGroup  |-> << >> ]

(* Mmp Request Groups at zero, then each field in turn at the values it is checked at *)
CheckedMmpRequestGroups ==
    { ZeroMmpRequestGroups }
        \cup { [ZeroMmpRequestGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroMmpRequestGroups EXCEPT !.mmpRequestGroup = one] : one \in SampleLists(OneMmpRequestGroup) }

(***************************************************************************)
(* Mm Protection Request Message                                           *)
(***************************************************************************)

MmProtectionRequestMessage ==
    [ clMsgSeqNum                  : Sample(4),
      firmId                       : Sample(8),
      sendingTime                  : Sample(8),
      clientOrderId                : Sample(8),
      executionWithinFirmShortCode : Sample(4),
      symbolIndex                  : Sample(4),
      emm                          : Sample(1),
      requestType                  : Sample(1),
      mmpRequestGroups             : MmpRequestGroups ]

EncodeMmProtectionRequestMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.clientOrderId
        \o message.executionWithinFirmShortCode
        \o message.symbolIndex
        \o message.emm
        \o message.requestType
        \o EncodeMmpRequestGroups(message.mmpRequestGroups)

DecodeMmProtectionRequestMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(sendingTime.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(clientOrderId.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(executionWithinFirmShortCode.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET requestType == ReadBytes(emm.rest, 1) IN IF ~requestType.ok THEN Fail ELSE
    LET mmpRequestGroups == DecodeMmpRequestGroups(requestType.rest) IN IF ~mmpRequestGroups.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                  |-> clMsgSeqNum.value,
         firmId                       |-> firmId.value,
         sendingTime                  |-> sendingTime.value,
         clientOrderId                |-> clientOrderId.value,
         executionWithinFirmShortCode |-> executionWithinFirmShortCode.value,
         symbolIndex                  |-> symbolIndex.value,
         emm                          |-> emm.value,
         requestType                  |-> requestType.value,
         mmpRequestGroups             |-> mmpRequestGroups.value ], mmpRequestGroups.rest)

ZeroMmProtectionRequestMessage ==
    [ clMsgSeqNum                  |-> [i \in 1 .. 4 |-> 0],
      firmId                       |-> [i \in 1 .. 8 |-> 0],
      sendingTime                  |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      symbolIndex                  |-> [i \in 1 .. 4 |-> 0],
      emm                          |-> [i \in 1 .. 1 |-> 0],
      requestType                  |-> [i \in 1 .. 1 |-> 0],
      mmpRequestGroups             |-> ZeroMmpRequestGroups ]

(* Mm Protection Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMmProtectionRequestMessage ==
    { ZeroMmProtectionRequestMessage }
        \cup { [ZeroMmProtectionRequestMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMmProtectionRequestMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroMmProtectionRequestMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroMmProtectionRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroMmProtectionRequestMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroMmProtectionRequestMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroMmProtectionRequestMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroMmProtectionRequestMessage EXCEPT !.requestType = one] : one \in Sample(1) }
        \cup { [ZeroMmProtectionRequestMessage EXCEPT !.mmpRequestGroups = one] : one \in CheckedMmpRequestGroups }

(***************************************************************************)
(* Mmp Ack Group: 19 bytes                                                 *)
(***************************************************************************)

MmpAckGroup ==
    [ protectionTypeOptional : Sample(1),
      protectionThreshold    : Sample(8),
      breachAction           : Sample(1),
      currentMmpPosition     : Sample(8),
      breachStatus           : Sample(1) ]

EncodeMmpAckGroup(message) ==
    message.protectionTypeOptional
        \o message.protectionThreshold
        \o message.breachAction
        \o message.currentMmpPosition
        \o message.breachStatus

DecodeMmpAckGroup(bytes) ==
    LET protectionTypeOptional == ReadBytes(bytes, 1) IN IF ~protectionTypeOptional.ok THEN Fail ELSE
    LET protectionThreshold == ReadBytes(protectionTypeOptional.rest, 8) IN IF ~protectionThreshold.ok THEN Fail ELSE
    LET breachAction == ReadBytes(protectionThreshold.rest, 1) IN IF ~breachAction.ok THEN Fail ELSE
    LET currentMmpPosition == ReadBytes(breachAction.rest, 8) IN IF ~currentMmpPosition.ok THEN Fail ELSE
    LET breachStatus == ReadBytes(currentMmpPosition.rest, 1) IN IF ~breachStatus.ok THEN Fail ELSE
    Ok([ protectionTypeOptional |-> protectionTypeOptional.value,
         protectionThreshold    |-> protectionThreshold.value,
         breachAction           |-> breachAction.value,
         currentMmpPosition     |-> currentMmpPosition.value,
         breachStatus           |-> breachStatus.value ], breachStatus.rest)

ZeroMmpAckGroup ==
    [ protectionTypeOptional |-> [i \in 1 .. 1 |-> 0],
      protectionThreshold    |-> [i \in 1 .. 8 |-> 0],
      breachAction           |-> [i \in 1 .. 1 |-> 0],
      currentMmpPosition     |-> [i \in 1 .. 8 |-> 0],
      breachStatus           |-> [i \in 1 .. 1 |-> 0] ]

(* Mmp Ack Group at zero, then each field in turn at the values it is checked at *)
CheckedMmpAckGroup ==
    { ZeroMmpAckGroup }
        \cup { [ZeroMmpAckGroup EXCEPT !.protectionTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroMmpAckGroup EXCEPT !.protectionThreshold = one] : one \in Sample(8) }
        \cup { [ZeroMmpAckGroup EXCEPT !.breachAction = one] : one \in Sample(1) }
        \cup { [ZeroMmpAckGroup EXCEPT !.currentMmpPosition = one] : one \in Sample(8) }
        \cup { [ZeroMmpAckGroup EXCEPT !.breachStatus = one] : one \in Sample(1) }

(* A run of Mmp Ack Group, written one after another *)
RECURSIVE EncodeMmpAckGroupList(_)
EncodeMmpAckGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMmpAckGroup(Head(messages)) \o EncodeMmpAckGroupList(Tail(messages))

(* As many Mmp Ack Group as the field that counts them says *)
RECURSIVE ReadMmpAckGroupList(_, _)
ReadMmpAckGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMmpAckGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMmpAckGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mmp Ack Group of each kind, for the lists that carry them *)
OneMmpAckGroup == { ZeroMmpAckGroup }

(***************************************************************************)
(* Mmp Ack Groups                                                          *)
(***************************************************************************)

MmpAckGroups ==
    [ blockLengthShort : Sample(1),
      mmpAckGroup      : SampleLists(OneMmpAckGroup) ]

EncodeMmpAckGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.mmpAckGroup), 1)
        \o EncodeMmpAckGroupList(message.mmpAckGroup)

DecodeMmpAckGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET mmpAckGroup == ReadMmpAckGroupList(numInGroup.rest, numInGroup.value) IN IF ~mmpAckGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         mmpAckGroup      |-> mmpAckGroup.value ], mmpAckGroup.rest)

ZeroMmpAckGroups ==
    [ blockLengthShort |-> [i \in 1 .. 1 |-> 0],
      mmpAckGroup      |-> << >> ]

(* Mmp Ack Groups at zero, then each field in turn at the values it is checked at *)
CheckedMmpAckGroups ==
    { ZeroMmpAckGroups }
        \cup { [ZeroMmpAckGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroMmpAckGroups EXCEPT !.mmpAckGroup = one] : one \in SampleLists(OneMmpAckGroup) }

(***************************************************************************)
(* Mm Protection Ack Message                                               *)
(***************************************************************************)

MmProtectionAckMessage ==
    [ msgSeqNum                    : Sample(4),
      firmId                       : Sample(8),
      sendingTimeOptional          : Sample(8),
      oegInFromMember              : Sample(8),
      oegOutTimeToMe               : Sample(8),
      bookInOptional               : Sample(8),
      bookOutTimeOptional          : Sample(8),
      oegInFromMeOptional          : Sample(8),
      oegOutToMemberOptional       : Sample(8),
      clientOrderIdOptional        : Sample(8),
      executionWithinFirmShortCode : Sample(4),
      symbolIndex                  : Sample(4),
      emm                          : Sample(1),
      mmpExecutionType             : Sample(1),
      mmpAckGroups                 : MmpAckGroups ]

EncodeMmProtectionAckMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.sendingTimeOptional
        \o message.oegInFromMember
        \o message.oegOutTimeToMe
        \o message.bookInOptional
        \o message.bookOutTimeOptional
        \o message.oegInFromMeOptional
        \o message.oegOutToMemberOptional
        \o message.clientOrderIdOptional
        \o message.executionWithinFirmShortCode
        \o message.symbolIndex
        \o message.emm
        \o message.mmpExecutionType
        \o EncodeMmpAckGroups(message.mmpAckGroups)

DecodeMmProtectionAckMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTimeOptional == ReadBytes(firmId.rest, 8) IN IF ~sendingTimeOptional.ok THEN Fail ELSE
    LET oegInFromMember == ReadBytes(sendingTimeOptional.rest, 8) IN IF ~oegInFromMember.ok THEN Fail ELSE
    LET oegOutTimeToMe == ReadBytes(oegInFromMember.rest, 8) IN IF ~oegOutTimeToMe.ok THEN Fail ELSE
    LET bookInOptional == ReadBytes(oegOutTimeToMe.rest, 8) IN IF ~bookInOptional.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(bookInOptional.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET oegInFromMeOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~oegInFromMeOptional.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(oegInFromMeOptional.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET clientOrderIdOptional == ReadBytes(oegOutToMemberOptional.rest, 8) IN IF ~clientOrderIdOptional.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(clientOrderIdOptional.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(executionWithinFirmShortCode.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET mmpExecutionType == ReadBytes(emm.rest, 1) IN IF ~mmpExecutionType.ok THEN Fail ELSE
    LET mmpAckGroups == DecodeMmpAckGroups(mmpExecutionType.rest) IN IF ~mmpAckGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                    |-> msgSeqNum.value,
         firmId                       |-> firmId.value,
         sendingTimeOptional          |-> sendingTimeOptional.value,
         oegInFromMember              |-> oegInFromMember.value,
         oegOutTimeToMe               |-> oegOutTimeToMe.value,
         bookInOptional               |-> bookInOptional.value,
         bookOutTimeOptional          |-> bookOutTimeOptional.value,
         oegInFromMeOptional          |-> oegInFromMeOptional.value,
         oegOutToMemberOptional       |-> oegOutToMemberOptional.value,
         clientOrderIdOptional        |-> clientOrderIdOptional.value,
         executionWithinFirmShortCode |-> executionWithinFirmShortCode.value,
         symbolIndex                  |-> symbolIndex.value,
         emm                          |-> emm.value,
         mmpExecutionType             |-> mmpExecutionType.value,
         mmpAckGroups                 |-> mmpAckGroups.value ], mmpAckGroups.rest)

ZeroMmProtectionAckMessage ==
    [ msgSeqNum                    |-> [i \in 1 .. 4 |-> 0],
      firmId                       |-> [i \in 1 .. 8 |-> 0],
      sendingTimeOptional          |-> [i \in 1 .. 8 |-> 0],
      oegInFromMember              |-> [i \in 1 .. 8 |-> 0],
      oegOutTimeToMe               |-> [i \in 1 .. 8 |-> 0],
      bookInOptional               |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional          |-> [i \in 1 .. 8 |-> 0],
      oegInFromMeOptional          |-> [i \in 1 .. 8 |-> 0],
      oegOutToMemberOptional       |-> [i \in 1 .. 8 |-> 0],
      clientOrderIdOptional        |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      symbolIndex                  |-> [i \in 1 .. 4 |-> 0],
      emm                          |-> [i \in 1 .. 1 |-> 0],
      mmpExecutionType             |-> [i \in 1 .. 1 |-> 0],
      mmpAckGroups                 |-> ZeroMmpAckGroups ]

(* Mm Protection Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedMmProtectionAckMessage ==
    { ZeroMmProtectionAckMessage }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.sendingTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.oegInFromMember = one] : one \in Sample(8) }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.oegOutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.bookInOptional = one] : one \in Sample(8) }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.oegInFromMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.clientOrderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.mmpExecutionType = one] : one \in Sample(1) }
        \cup { [ZeroMmProtectionAckMessage EXCEPT !.mmpAckGroups = one] : one \in CheckedMmpAckGroups }

(***************************************************************************)
(* Wholesale Legs Group: 51 bytes                                          *)
(***************************************************************************)

WholesaleLegsGroup ==
    [ legSymbolIndex     : Sample(4),
      legPrice           : Sample(8),
      bidQuantity        : Sample(8),
      offerQuantity      : Sample(8),
      legSideOptional    : Sample(1),
      legStrikePrice     : Sample(8),
      legRatioOptional   : Sample(4),
      legPutOrCall       : Sample(1),
      legSecurityType    : Sample(1),
      legLastTradingDate : Sample(8) ]

EncodeWholesaleLegsGroup(message) ==
    message.legSymbolIndex
        \o message.legPrice
        \o message.bidQuantity
        \o message.offerQuantity
        \o message.legSideOptional
        \o message.legStrikePrice
        \o message.legRatioOptional
        \o message.legPutOrCall
        \o message.legSecurityType
        \o message.legLastTradingDate

DecodeWholesaleLegsGroup(bytes) ==
    LET legSymbolIndex == ReadBytes(bytes, 4) IN IF ~legSymbolIndex.ok THEN Fail ELSE
    LET legPrice == ReadBytes(legSymbolIndex.rest, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET bidQuantity == ReadBytes(legPrice.rest, 8) IN IF ~bidQuantity.ok THEN Fail ELSE
    LET offerQuantity == ReadBytes(bidQuantity.rest, 8) IN IF ~offerQuantity.ok THEN Fail ELSE
    LET legSideOptional == ReadBytes(offerQuantity.rest, 1) IN IF ~legSideOptional.ok THEN Fail ELSE
    LET legStrikePrice == ReadBytes(legSideOptional.rest, 8) IN IF ~legStrikePrice.ok THEN Fail ELSE
    LET legRatioOptional == ReadBytes(legStrikePrice.rest, 4) IN IF ~legRatioOptional.ok THEN Fail ELSE
    LET legPutOrCall == ReadBytes(legRatioOptional.rest, 1) IN IF ~legPutOrCall.ok THEN Fail ELSE
    LET legSecurityType == ReadBytes(legPutOrCall.rest, 1) IN IF ~legSecurityType.ok THEN Fail ELSE
    LET legLastTradingDate == ReadBytes(legSecurityType.rest, 8) IN IF ~legLastTradingDate.ok THEN Fail ELSE
    Ok([ legSymbolIndex     |-> legSymbolIndex.value,
         legPrice           |-> legPrice.value,
         bidQuantity        |-> bidQuantity.value,
         offerQuantity      |-> offerQuantity.value,
         legSideOptional    |-> legSideOptional.value,
         legStrikePrice     |-> legStrikePrice.value,
         legRatioOptional   |-> legRatioOptional.value,
         legPutOrCall       |-> legPutOrCall.value,
         legSecurityType    |-> legSecurityType.value,
         legLastTradingDate |-> legLastTradingDate.value ], legLastTradingDate.rest)

ZeroWholesaleLegsGroup ==
    [ legSymbolIndex     |-> [i \in 1 .. 4 |-> 0],
      legPrice           |-> [i \in 1 .. 8 |-> 0],
      bidQuantity        |-> [i \in 1 .. 8 |-> 0],
      offerQuantity      |-> [i \in 1 .. 8 |-> 0],
      legSideOptional    |-> [i \in 1 .. 1 |-> 0],
      legStrikePrice     |-> [i \in 1 .. 8 |-> 0],
      legRatioOptional   |-> [i \in 1 .. 4 |-> 0],
      legPutOrCall       |-> [i \in 1 .. 1 |-> 0],
      legSecurityType    |-> [i \in 1 .. 1 |-> 0],
      legLastTradingDate |-> [i \in 1 .. 8 |-> 0] ]

(* Wholesale Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedWholesaleLegsGroup ==
    { ZeroWholesaleLegsGroup }
        \cup { [ZeroWholesaleLegsGroup EXCEPT !.legSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleLegsGroup EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleLegsGroup EXCEPT !.bidQuantity = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleLegsGroup EXCEPT !.offerQuantity = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleLegsGroup EXCEPT !.legSideOptional = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleLegsGroup EXCEPT !.legStrikePrice = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleLegsGroup EXCEPT !.legRatioOptional = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleLegsGroup EXCEPT !.legPutOrCall = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleLegsGroup EXCEPT !.legSecurityType = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleLegsGroup EXCEPT !.legLastTradingDate = one] : one \in Sample(8) }

(* A run of Wholesale Legs Group, written one after another *)
RECURSIVE EncodeWholesaleLegsGroupList(_)
EncodeWholesaleLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeWholesaleLegsGroup(Head(messages)) \o EncodeWholesaleLegsGroupList(Tail(messages))

(* As many Wholesale Legs Group as the field that counts them says *)
RECURSIVE ReadWholesaleLegsGroupList(_, _)
ReadWholesaleLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeWholesaleLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadWholesaleLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Wholesale Legs Group of each kind, for the lists that carry them *)
OneWholesaleLegsGroup == { ZeroWholesaleLegsGroup }

(***************************************************************************)
(* Wholesale Legs Groups                                                   *)
(***************************************************************************)

WholesaleLegsGroups ==
    [ blockLengthShort   : Sample(1),
      wholesaleLegsGroup : SampleLists(OneWholesaleLegsGroup) ]

EncodeWholesaleLegsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.wholesaleLegsGroup), 1)
        \o EncodeWholesaleLegsGroupList(message.wholesaleLegsGroup)

DecodeWholesaleLegsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET wholesaleLegsGroup == ReadWholesaleLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~wholesaleLegsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort   |-> blockLengthShort.value,
         wholesaleLegsGroup |-> wholesaleLegsGroup.value ], wholesaleLegsGroup.rest)

ZeroWholesaleLegsGroups ==
    [ blockLengthShort   |-> [i \in 1 .. 1 |-> 0],
      wholesaleLegsGroup |-> << >> ]

(* Wholesale Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedWholesaleLegsGroups ==
    { ZeroWholesaleLegsGroups }
        \cup { [ZeroWholesaleLegsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleLegsGroups EXCEPT !.wholesaleLegsGroup = one] : one \in SampleLists(OneWholesaleLegsGroup) }

(***************************************************************************)
(* Wholesale Client Group: 80 bytes                                        *)
(***************************************************************************)

WholesaleClientGroup ==
    [ symbolIndex                      : Sample(4),
      side                             : Sample(1),
      accountType                      : Sample(1),
      clearingFirmId                   : Sample(8),
      longClientId                     : Sample(16),
      accountNumber                    : Sample(12),
      technicalOrigin                  : Sample(1),
      openClose                        : Sample(2),
      clearingInstruction              : Sample(2),
      freeText                         : Sample(18),
      nonExecutingClientId             : Sample(2),
      investmentDecisionWFirmShortCode : Sample(4),
      nonExecutingBrokerShortCode      : Sample(4),
      clientIdentificationShortcode    : Sample(4),
      tradingCapacityOptional          : Sample(1) ]

EncodeWholesaleClientGroup(message) ==
    message.symbolIndex
        \o message.side
        \o message.accountType
        \o message.clearingFirmId
        \o message.longClientId
        \o message.accountNumber
        \o message.technicalOrigin
        \o message.openClose
        \o message.clearingInstruction
        \o message.freeText
        \o message.nonExecutingClientId
        \o message.investmentDecisionWFirmShortCode
        \o message.nonExecutingBrokerShortCode
        \o message.clientIdentificationShortcode
        \o message.tradingCapacityOptional

DecodeWholesaleClientGroup(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET side == ReadBytes(symbolIndex.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET accountType == ReadBytes(side.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET clearingFirmId == ReadBytes(accountType.rest, 8) IN IF ~clearingFirmId.ok THEN Fail ELSE
    LET longClientId == ReadBytes(clearingFirmId.rest, 16) IN IF ~longClientId.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(longClientId.rest, 12) IN IF ~accountNumber.ok THEN Fail ELSE
    LET technicalOrigin == ReadBytes(accountNumber.rest, 1) IN IF ~technicalOrigin.ok THEN Fail ELSE
    LET openClose == ReadBytes(technicalOrigin.rest, 2) IN IF ~openClose.ok THEN Fail ELSE
    LET clearingInstruction == ReadBytes(openClose.rest, 2) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET freeText == ReadBytes(clearingInstruction.rest, 18) IN IF ~freeText.ok THEN Fail ELSE
    LET nonExecutingClientId == ReadBytes(freeText.rest, 2) IN IF ~nonExecutingClientId.ok THEN Fail ELSE
    LET investmentDecisionWFirmShortCode == ReadBytes(nonExecutingClientId.rest, 4) IN IF ~investmentDecisionWFirmShortCode.ok THEN Fail ELSE
    LET nonExecutingBrokerShortCode == ReadBytes(investmentDecisionWFirmShortCode.rest, 4) IN IF ~nonExecutingBrokerShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(nonExecutingBrokerShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET tradingCapacityOptional == ReadBytes(clientIdentificationShortcode.rest, 1) IN IF ~tradingCapacityOptional.ok THEN Fail ELSE
    Ok([ symbolIndex                      |-> symbolIndex.value,
         side                             |-> side.value,
         accountType                      |-> accountType.value,
         clearingFirmId                   |-> clearingFirmId.value,
         longClientId                     |-> longClientId.value,
         accountNumber                    |-> accountNumber.value,
         technicalOrigin                  |-> technicalOrigin.value,
         openClose                        |-> openClose.value,
         clearingInstruction              |-> clearingInstruction.value,
         freeText                         |-> freeText.value,
         nonExecutingClientId             |-> nonExecutingClientId.value,
         investmentDecisionWFirmShortCode |-> investmentDecisionWFirmShortCode.value,
         nonExecutingBrokerShortCode      |-> nonExecutingBrokerShortCode.value,
         clientIdentificationShortcode    |-> clientIdentificationShortcode.value,
         tradingCapacityOptional          |-> tradingCapacityOptional.value ], tradingCapacityOptional.rest)

ZeroWholesaleClientGroup ==
    [ symbolIndex                      |-> [i \in 1 .. 4 |-> 0],
      side                             |-> [i \in 1 .. 1 |-> 0],
      accountType                      |-> [i \in 1 .. 1 |-> 0],
      clearingFirmId                   |-> [i \in 1 .. 8 |-> 0],
      longClientId                     |-> [i \in 1 .. 16 |-> 0],
      accountNumber                    |-> [i \in 1 .. 12 |-> 0],
      technicalOrigin                  |-> [i \in 1 .. 1 |-> 0],
      openClose                        |-> [i \in 1 .. 2 |-> 0],
      clearingInstruction              |-> [i \in 1 .. 2 |-> 0],
      freeText                         |-> [i \in 1 .. 18 |-> 0],
      nonExecutingClientId             |-> [i \in 1 .. 2 |-> 0],
      investmentDecisionWFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      nonExecutingBrokerShortCode      |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode    |-> [i \in 1 .. 4 |-> 0],
      tradingCapacityOptional          |-> [i \in 1 .. 1 |-> 0] ]

(* Wholesale Client Group at zero, then each field in turn at the values it is checked at *)
CheckedWholesaleClientGroup ==
    { ZeroWholesaleClientGroup }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.clearingFirmId = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.longClientId = one] : one \in Sample(16) }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.accountNumber = one] : one \in Sample(12) }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.technicalOrigin = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.openClose = one] : one \in Sample(2) }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.clearingInstruction = one] : one \in Sample(2) }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.freeText = one] : one \in Sample(18) }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.nonExecutingClientId = one] : one \in Sample(2) }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.investmentDecisionWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.nonExecutingBrokerShortCode = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleClientGroup EXCEPT !.tradingCapacityOptional = one] : one \in Sample(1) }

(* A run of Wholesale Client Group, written one after another *)
RECURSIVE EncodeWholesaleClientGroupList(_)
EncodeWholesaleClientGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeWholesaleClientGroup(Head(messages)) \o EncodeWholesaleClientGroupList(Tail(messages))

(* As many Wholesale Client Group as the field that counts them says *)
RECURSIVE ReadWholesaleClientGroupList(_, _)
ReadWholesaleClientGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeWholesaleClientGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadWholesaleClientGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Wholesale Client Group of each kind, for the lists that carry them *)
OneWholesaleClientGroup == { ZeroWholesaleClientGroup }

(***************************************************************************)
(* Wholesale Client Groups                                                 *)
(***************************************************************************)

WholesaleClientGroups ==
    [ blockLengthShort     : Sample(1),
      wholesaleClientGroup : SampleLists(OneWholesaleClientGroup) ]

EncodeWholesaleClientGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.wholesaleClientGroup), 1)
        \o EncodeWholesaleClientGroupList(message.wholesaleClientGroup)

DecodeWholesaleClientGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET wholesaleClientGroup == ReadWholesaleClientGroupList(numInGroup.rest, numInGroup.value) IN IF ~wholesaleClientGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort     |-> blockLengthShort.value,
         wholesaleClientGroup |-> wholesaleClientGroup.value ], wholesaleClientGroup.rest)

ZeroWholesaleClientGroups ==
    [ blockLengthShort     |-> [i \in 1 .. 1 |-> 0],
      wholesaleClientGroup |-> << >> ]

(* Wholesale Client Groups at zero, then each field in turn at the values it is checked at *)
CheckedWholesaleClientGroups ==
    { ZeroWholesaleClientGroups }
        \cup { [ZeroWholesaleClientGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleClientGroups EXCEPT !.wholesaleClientGroup = one] : one \in SampleLists(OneWholesaleClientGroup) }

(***************************************************************************)
(* New Wholesale Order Message                                             *)
(***************************************************************************)

NewWholesaleOrderMessage ==
    [ clMsgSeqNum                  : Sample(4),
      firmId                       : Sample(8),
      sendingTime                  : Sample(8),
      clientOrderId                : Sample(8),
      contractSymbolIndex          : Sample(4),
      wholesaleTradeType           : Sample(1),
      lisTransactionId             : Sample(4),
      strategyCodeOptional         : Sample(1),
      price                        : Sample(8),
      quantity                     : Sample(8),
      executionWithinFirmShortCode : Sample(4),
      mifidIndicators              : Sample(1),
      wholesaleSide                : Sample(1),
      escbMembership               : Sample(1),
      messagePriceNotation         : Sample(1),
      wholesaleLegsGroups          : WholesaleLegsGroups,
      wholesaleClientGroups        : WholesaleClientGroups ]

EncodeNewWholesaleOrderMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.clientOrderId
        \o message.contractSymbolIndex
        \o message.wholesaleTradeType
        \o message.lisTransactionId
        \o message.strategyCodeOptional
        \o message.price
        \o message.quantity
        \o message.executionWithinFirmShortCode
        \o message.mifidIndicators
        \o message.wholesaleSide
        \o message.escbMembership
        \o message.messagePriceNotation
        \o EncodeWholesaleLegsGroups(message.wholesaleLegsGroups)
        \o EncodeWholesaleClientGroups(message.wholesaleClientGroups)

DecodeNewWholesaleOrderMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(sendingTime.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET contractSymbolIndex == ReadBytes(clientOrderId.rest, 4) IN IF ~contractSymbolIndex.ok THEN Fail ELSE
    LET wholesaleTradeType == ReadBytes(contractSymbolIndex.rest, 1) IN IF ~wholesaleTradeType.ok THEN Fail ELSE
    LET lisTransactionId == ReadBytes(wholesaleTradeType.rest, 4) IN IF ~lisTransactionId.ok THEN Fail ELSE
    LET strategyCodeOptional == ReadBytes(lisTransactionId.rest, 1) IN IF ~strategyCodeOptional.ok THEN Fail ELSE
    LET price == ReadBytes(strategyCodeOptional.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 8) IN IF ~quantity.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(quantity.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET mifidIndicators == ReadBytes(executionWithinFirmShortCode.rest, 1) IN IF ~mifidIndicators.ok THEN Fail ELSE
    LET wholesaleSide == ReadBytes(mifidIndicators.rest, 1) IN IF ~wholesaleSide.ok THEN Fail ELSE
    LET escbMembership == ReadBytes(wholesaleSide.rest, 1) IN IF ~escbMembership.ok THEN Fail ELSE
    LET messagePriceNotation == ReadBytes(escbMembership.rest, 1) IN IF ~messagePriceNotation.ok THEN Fail ELSE
    LET wholesaleLegsGroups == DecodeWholesaleLegsGroups(messagePriceNotation.rest) IN IF ~wholesaleLegsGroups.ok THEN Fail ELSE
    LET wholesaleClientGroups == DecodeWholesaleClientGroups(wholesaleLegsGroups.rest) IN IF ~wholesaleClientGroups.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                  |-> clMsgSeqNum.value,
         firmId                       |-> firmId.value,
         sendingTime                  |-> sendingTime.value,
         clientOrderId                |-> clientOrderId.value,
         contractSymbolIndex          |-> contractSymbolIndex.value,
         wholesaleTradeType           |-> wholesaleTradeType.value,
         lisTransactionId             |-> lisTransactionId.value,
         strategyCodeOptional         |-> strategyCodeOptional.value,
         price                        |-> price.value,
         quantity                     |-> quantity.value,
         executionWithinFirmShortCode |-> executionWithinFirmShortCode.value,
         mifidIndicators              |-> mifidIndicators.value,
         wholesaleSide                |-> wholesaleSide.value,
         escbMembership               |-> escbMembership.value,
         messagePriceNotation         |-> messagePriceNotation.value,
         wholesaleLegsGroups          |-> wholesaleLegsGroups.value,
         wholesaleClientGroups        |-> wholesaleClientGroups.value ], wholesaleClientGroups.rest)

ZeroNewWholesaleOrderMessage ==
    [ clMsgSeqNum                  |-> [i \in 1 .. 4 |-> 0],
      firmId                       |-> [i \in 1 .. 8 |-> 0],
      sendingTime                  |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                |-> [i \in 1 .. 8 |-> 0],
      contractSymbolIndex          |-> [i \in 1 .. 4 |-> 0],
      wholesaleTradeType           |-> [i \in 1 .. 1 |-> 0],
      lisTransactionId             |-> [i \in 1 .. 4 |-> 0],
      strategyCodeOptional         |-> [i \in 1 .. 1 |-> 0],
      price                        |-> [i \in 1 .. 8 |-> 0],
      quantity                     |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      mifidIndicators              |-> [i \in 1 .. 1 |-> 0],
      wholesaleSide                |-> [i \in 1 .. 1 |-> 0],
      escbMembership               |-> [i \in 1 .. 1 |-> 0],
      messagePriceNotation         |-> [i \in 1 .. 1 |-> 0],
      wholesaleLegsGroups          |-> ZeroWholesaleLegsGroups,
      wholesaleClientGroups        |-> ZeroWholesaleClientGroups ]

(* New Wholesale Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewWholesaleOrderMessage ==
    { ZeroNewWholesaleOrderMessage }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.contractSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.wholesaleTradeType = one] : one \in Sample(1) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.lisTransactionId = one] : one \in Sample(4) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.strategyCodeOptional = one] : one \in Sample(1) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.quantity = one] : one \in Sample(8) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.mifidIndicators = one] : one \in Sample(1) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.wholesaleSide = one] : one \in Sample(1) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.escbMembership = one] : one \in Sample(1) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.messagePriceNotation = one] : one \in Sample(1) }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.wholesaleLegsGroups = one] : one \in CheckedWholesaleLegsGroups }
        \cup { [ZeroNewWholesaleOrderMessage EXCEPT !.wholesaleClientGroups = one] : one \in CheckedWholesaleClientGroups }

(***************************************************************************)
(* Wholesale Ack Legs Group: 23 bytes                                      *)
(***************************************************************************)

WholesaleAckLegsGroup ==
    [ legSymbolIndex  : Sample(4),
      legBidOrderId   : Sample(8),
      legOfferOrderId : Sample(8),
      legSideOptional : Sample(1),
      legErrorCode    : Sample(2) ]

EncodeWholesaleAckLegsGroup(message) ==
    message.legSymbolIndex
        \o message.legBidOrderId
        \o message.legOfferOrderId
        \o message.legSideOptional
        \o message.legErrorCode

DecodeWholesaleAckLegsGroup(bytes) ==
    LET legSymbolIndex == ReadBytes(bytes, 4) IN IF ~legSymbolIndex.ok THEN Fail ELSE
    LET legBidOrderId == ReadBytes(legSymbolIndex.rest, 8) IN IF ~legBidOrderId.ok THEN Fail ELSE
    LET legOfferOrderId == ReadBytes(legBidOrderId.rest, 8) IN IF ~legOfferOrderId.ok THEN Fail ELSE
    LET legSideOptional == ReadBytes(legOfferOrderId.rest, 1) IN IF ~legSideOptional.ok THEN Fail ELSE
    LET legErrorCode == ReadBytes(legSideOptional.rest, 2) IN IF ~legErrorCode.ok THEN Fail ELSE
    Ok([ legSymbolIndex  |-> legSymbolIndex.value,
         legBidOrderId   |-> legBidOrderId.value,
         legOfferOrderId |-> legOfferOrderId.value,
         legSideOptional |-> legSideOptional.value,
         legErrorCode    |-> legErrorCode.value ], legErrorCode.rest)

ZeroWholesaleAckLegsGroup ==
    [ legSymbolIndex  |-> [i \in 1 .. 4 |-> 0],
      legBidOrderId   |-> [i \in 1 .. 8 |-> 0],
      legOfferOrderId |-> [i \in 1 .. 8 |-> 0],
      legSideOptional |-> [i \in 1 .. 1 |-> 0],
      legErrorCode    |-> [i \in 1 .. 2 |-> 0] ]

(* Wholesale Ack Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedWholesaleAckLegsGroup ==
    { ZeroWholesaleAckLegsGroup }
        \cup { [ZeroWholesaleAckLegsGroup EXCEPT !.legSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleAckLegsGroup EXCEPT !.legBidOrderId = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleAckLegsGroup EXCEPT !.legOfferOrderId = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleAckLegsGroup EXCEPT !.legSideOptional = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleAckLegsGroup EXCEPT !.legErrorCode = one] : one \in Sample(2) }

(* A run of Wholesale Ack Legs Group, written one after another *)
RECURSIVE EncodeWholesaleAckLegsGroupList(_)
EncodeWholesaleAckLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeWholesaleAckLegsGroup(Head(messages)) \o EncodeWholesaleAckLegsGroupList(Tail(messages))

(* As many Wholesale Ack Legs Group as the field that counts them says *)
RECURSIVE ReadWholesaleAckLegsGroupList(_, _)
ReadWholesaleAckLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeWholesaleAckLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadWholesaleAckLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Wholesale Ack Legs Group of each kind, for the lists that carry them *)
OneWholesaleAckLegsGroup == { ZeroWholesaleAckLegsGroup }

(***************************************************************************)
(* Wholesale Ack Legs Groups                                               *)
(***************************************************************************)

WholesaleAckLegsGroups ==
    [ blockLengthShort      : Sample(1),
      wholesaleAckLegsGroup : SampleLists(OneWholesaleAckLegsGroup) ]

EncodeWholesaleAckLegsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.wholesaleAckLegsGroup), 1)
        \o EncodeWholesaleAckLegsGroupList(message.wholesaleAckLegsGroup)

DecodeWholesaleAckLegsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET wholesaleAckLegsGroup == ReadWholesaleAckLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~wholesaleAckLegsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort      |-> blockLengthShort.value,
         wholesaleAckLegsGroup |-> wholesaleAckLegsGroup.value ], wholesaleAckLegsGroup.rest)

ZeroWholesaleAckLegsGroups ==
    [ blockLengthShort      |-> [i \in 1 .. 1 |-> 0],
      wholesaleAckLegsGroup |-> << >> ]

(* Wholesale Ack Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedWholesaleAckLegsGroups ==
    { ZeroWholesaleAckLegsGroups }
        \cup { [ZeroWholesaleAckLegsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleAckLegsGroups EXCEPT !.wholesaleAckLegsGroup = one] : one \in SampleLists(OneWholesaleAckLegsGroup) }

(***************************************************************************)
(* Wholesale Ack Clearing Group: 19 bytes                                  *)
(***************************************************************************)

WholesaleAckClearingGroup ==
    [ symbolIndex                      : Sample(4),
      side                             : Sample(1),
      investmentDecisionWFirmShortCode : Sample(4),
      nonExecutingBrokerShortCode      : Sample(4),
      clientIdentificationShortcode    : Sample(4),
      nonExecutingClientId             : Sample(2) ]

EncodeWholesaleAckClearingGroup(message) ==
    message.symbolIndex
        \o message.side
        \o message.investmentDecisionWFirmShortCode
        \o message.nonExecutingBrokerShortCode
        \o message.clientIdentificationShortcode
        \o message.nonExecutingClientId

DecodeWholesaleAckClearingGroup(bytes) ==
    LET symbolIndex == ReadBytes(bytes, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET side == ReadBytes(symbolIndex.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET investmentDecisionWFirmShortCode == ReadBytes(side.rest, 4) IN IF ~investmentDecisionWFirmShortCode.ok THEN Fail ELSE
    LET nonExecutingBrokerShortCode == ReadBytes(investmentDecisionWFirmShortCode.rest, 4) IN IF ~nonExecutingBrokerShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(nonExecutingBrokerShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET nonExecutingClientId == ReadBytes(clientIdentificationShortcode.rest, 2) IN IF ~nonExecutingClientId.ok THEN Fail ELSE
    Ok([ symbolIndex                      |-> symbolIndex.value,
         side                             |-> side.value,
         investmentDecisionWFirmShortCode |-> investmentDecisionWFirmShortCode.value,
         nonExecutingBrokerShortCode      |-> nonExecutingBrokerShortCode.value,
         clientIdentificationShortcode    |-> clientIdentificationShortcode.value,
         nonExecutingClientId             |-> nonExecutingClientId.value ], nonExecutingClientId.rest)

ZeroWholesaleAckClearingGroup ==
    [ symbolIndex                      |-> [i \in 1 .. 4 |-> 0],
      side                             |-> [i \in 1 .. 1 |-> 0],
      investmentDecisionWFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      nonExecutingBrokerShortCode      |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode    |-> [i \in 1 .. 4 |-> 0],
      nonExecutingClientId             |-> [i \in 1 .. 2 |-> 0] ]

(* Wholesale Ack Clearing Group at zero, then each field in turn at the values it is checked at *)
CheckedWholesaleAckClearingGroup ==
    { ZeroWholesaleAckClearingGroup }
        \cup { [ZeroWholesaleAckClearingGroup EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleAckClearingGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleAckClearingGroup EXCEPT !.investmentDecisionWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleAckClearingGroup EXCEPT !.nonExecutingBrokerShortCode = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleAckClearingGroup EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleAckClearingGroup EXCEPT !.nonExecutingClientId = one] : one \in Sample(2) }

(* A run of Wholesale Ack Clearing Group, written one after another *)
RECURSIVE EncodeWholesaleAckClearingGroupList(_)
EncodeWholesaleAckClearingGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeWholesaleAckClearingGroup(Head(messages)) \o EncodeWholesaleAckClearingGroupList(Tail(messages))

(* As many Wholesale Ack Clearing Group as the field that counts them says *)
RECURSIVE ReadWholesaleAckClearingGroupList(_, _)
ReadWholesaleAckClearingGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeWholesaleAckClearingGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadWholesaleAckClearingGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Wholesale Ack Clearing Group of each kind, for the lists that carry them *)
OneWholesaleAckClearingGroup == { ZeroWholesaleAckClearingGroup }

(***************************************************************************)
(* Wholesale Ack Clearing Groups                                           *)
(***************************************************************************)

WholesaleAckClearingGroups ==
    [ blockLengthShort          : Sample(1),
      wholesaleAckClearingGroup : SampleLists(OneWholesaleAckClearingGroup) ]

EncodeWholesaleAckClearingGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.wholesaleAckClearingGroup), 1)
        \o EncodeWholesaleAckClearingGroupList(message.wholesaleAckClearingGroup)

DecodeWholesaleAckClearingGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET wholesaleAckClearingGroup == ReadWholesaleAckClearingGroupList(numInGroup.rest, numInGroup.value) IN IF ~wholesaleAckClearingGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort          |-> blockLengthShort.value,
         wholesaleAckClearingGroup |-> wholesaleAckClearingGroup.value ], wholesaleAckClearingGroup.rest)

ZeroWholesaleAckClearingGroups ==
    [ blockLengthShort          |-> [i \in 1 .. 1 |-> 0],
      wholesaleAckClearingGroup |-> << >> ]

(* Wholesale Ack Clearing Groups at zero, then each field in turn at the values it is checked at *)
CheckedWholesaleAckClearingGroups ==
    { ZeroWholesaleAckClearingGroups }
        \cup { [ZeroWholesaleAckClearingGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleAckClearingGroups EXCEPT !.wholesaleAckClearingGroup = one] : one \in SampleLists(OneWholesaleAckClearingGroup) }

(***************************************************************************)
(* Wholesale Order Ack Message                                             *)
(***************************************************************************)

WholesaleOrderAckMessage ==
    [ msgSeqNum                    : Sample(4),
      firmId                       : Sample(8),
      sendingTimeOptional          : Sample(8),
      oegInFromMember              : Sample(8),
      oegOutTimeToMe               : Sample(8),
      bookInOptional               : Sample(8),
      bookOutTimeOptional          : Sample(8),
      oegInFromMeOptional          : Sample(8),
      oegOutToMemberOptional       : Sample(8),
      clientOrderIdOptional        : Sample(8),
      contractSymbolIndex          : Sample(4),
      wholesaleTradeType           : Sample(1),
      lisTransactionId             : Sample(4),
      strategyCodeOptional         : Sample(1),
      priceOptional                : Sample(8),
      quantityOptional             : Sample(8),
      executionWithinFirmShortCode : Sample(4),
      mifidIndicators              : Sample(1),
      wholesaleSide                : Sample(1),
      escbMembership               : Sample(1),
      responseType                 : Sample(1),
      errorCode                    : Sample(2),
      ackQualifiers                : Sample(1),
      wholesaleAckLegsGroups       : WholesaleAckLegsGroups,
      wholesaleAckClearingGroups   : WholesaleAckClearingGroups ]

EncodeWholesaleOrderAckMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.sendingTimeOptional
        \o message.oegInFromMember
        \o message.oegOutTimeToMe
        \o message.bookInOptional
        \o message.bookOutTimeOptional
        \o message.oegInFromMeOptional
        \o message.oegOutToMemberOptional
        \o message.clientOrderIdOptional
        \o message.contractSymbolIndex
        \o message.wholesaleTradeType
        \o message.lisTransactionId
        \o message.strategyCodeOptional
        \o message.priceOptional
        \o message.quantityOptional
        \o message.executionWithinFirmShortCode
        \o message.mifidIndicators
        \o message.wholesaleSide
        \o message.escbMembership
        \o message.responseType
        \o message.errorCode
        \o message.ackQualifiers
        \o EncodeWholesaleAckLegsGroups(message.wholesaleAckLegsGroups)
        \o EncodeWholesaleAckClearingGroups(message.wholesaleAckClearingGroups)

DecodeWholesaleOrderAckMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTimeOptional == ReadBytes(firmId.rest, 8) IN IF ~sendingTimeOptional.ok THEN Fail ELSE
    LET oegInFromMember == ReadBytes(sendingTimeOptional.rest, 8) IN IF ~oegInFromMember.ok THEN Fail ELSE
    LET oegOutTimeToMe == ReadBytes(oegInFromMember.rest, 8) IN IF ~oegOutTimeToMe.ok THEN Fail ELSE
    LET bookInOptional == ReadBytes(oegOutTimeToMe.rest, 8) IN IF ~bookInOptional.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(bookInOptional.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET oegInFromMeOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~oegInFromMeOptional.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(oegInFromMeOptional.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET clientOrderIdOptional == ReadBytes(oegOutToMemberOptional.rest, 8) IN IF ~clientOrderIdOptional.ok THEN Fail ELSE
    LET contractSymbolIndex == ReadBytes(clientOrderIdOptional.rest, 4) IN IF ~contractSymbolIndex.ok THEN Fail ELSE
    LET wholesaleTradeType == ReadBytes(contractSymbolIndex.rest, 1) IN IF ~wholesaleTradeType.ok THEN Fail ELSE
    LET lisTransactionId == ReadBytes(wholesaleTradeType.rest, 4) IN IF ~lisTransactionId.ok THEN Fail ELSE
    LET strategyCodeOptional == ReadBytes(lisTransactionId.rest, 1) IN IF ~strategyCodeOptional.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(strategyCodeOptional.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET quantityOptional == ReadBytes(priceOptional.rest, 8) IN IF ~quantityOptional.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(quantityOptional.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET mifidIndicators == ReadBytes(executionWithinFirmShortCode.rest, 1) IN IF ~mifidIndicators.ok THEN Fail ELSE
    LET wholesaleSide == ReadBytes(mifidIndicators.rest, 1) IN IF ~wholesaleSide.ok THEN Fail ELSE
    LET escbMembership == ReadBytes(wholesaleSide.rest, 1) IN IF ~escbMembership.ok THEN Fail ELSE
    LET responseType == ReadBytes(escbMembership.rest, 1) IN IF ~responseType.ok THEN Fail ELSE
    LET errorCode == ReadBytes(responseType.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET ackQualifiers == ReadBytes(errorCode.rest, 1) IN IF ~ackQualifiers.ok THEN Fail ELSE
    LET wholesaleAckLegsGroups == DecodeWholesaleAckLegsGroups(ackQualifiers.rest) IN IF ~wholesaleAckLegsGroups.ok THEN Fail ELSE
    LET wholesaleAckClearingGroups == DecodeWholesaleAckClearingGroups(wholesaleAckLegsGroups.rest) IN IF ~wholesaleAckClearingGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                    |-> msgSeqNum.value,
         firmId                       |-> firmId.value,
         sendingTimeOptional          |-> sendingTimeOptional.value,
         oegInFromMember              |-> oegInFromMember.value,
         oegOutTimeToMe               |-> oegOutTimeToMe.value,
         bookInOptional               |-> bookInOptional.value,
         bookOutTimeOptional          |-> bookOutTimeOptional.value,
         oegInFromMeOptional          |-> oegInFromMeOptional.value,
         oegOutToMemberOptional       |-> oegOutToMemberOptional.value,
         clientOrderIdOptional        |-> clientOrderIdOptional.value,
         contractSymbolIndex          |-> contractSymbolIndex.value,
         wholesaleTradeType           |-> wholesaleTradeType.value,
         lisTransactionId             |-> lisTransactionId.value,
         strategyCodeOptional         |-> strategyCodeOptional.value,
         priceOptional                |-> priceOptional.value,
         quantityOptional             |-> quantityOptional.value,
         executionWithinFirmShortCode |-> executionWithinFirmShortCode.value,
         mifidIndicators              |-> mifidIndicators.value,
         wholesaleSide                |-> wholesaleSide.value,
         escbMembership               |-> escbMembership.value,
         responseType                 |-> responseType.value,
         errorCode                    |-> errorCode.value,
         ackQualifiers                |-> ackQualifiers.value,
         wholesaleAckLegsGroups       |-> wholesaleAckLegsGroups.value,
         wholesaleAckClearingGroups   |-> wholesaleAckClearingGroups.value ], wholesaleAckClearingGroups.rest)

ZeroWholesaleOrderAckMessage ==
    [ msgSeqNum                    |-> [i \in 1 .. 4 |-> 0],
      firmId                       |-> [i \in 1 .. 8 |-> 0],
      sendingTimeOptional          |-> [i \in 1 .. 8 |-> 0],
      oegInFromMember              |-> [i \in 1 .. 8 |-> 0],
      oegOutTimeToMe               |-> [i \in 1 .. 8 |-> 0],
      bookInOptional               |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional          |-> [i \in 1 .. 8 |-> 0],
      oegInFromMeOptional          |-> [i \in 1 .. 8 |-> 0],
      oegOutToMemberOptional       |-> [i \in 1 .. 8 |-> 0],
      clientOrderIdOptional        |-> [i \in 1 .. 8 |-> 0],
      contractSymbolIndex          |-> [i \in 1 .. 4 |-> 0],
      wholesaleTradeType           |-> [i \in 1 .. 1 |-> 0],
      lisTransactionId             |-> [i \in 1 .. 4 |-> 0],
      strategyCodeOptional         |-> [i \in 1 .. 1 |-> 0],
      priceOptional                |-> [i \in 1 .. 8 |-> 0],
      quantityOptional             |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      mifidIndicators              |-> [i \in 1 .. 1 |-> 0],
      wholesaleSide                |-> [i \in 1 .. 1 |-> 0],
      escbMembership               |-> [i \in 1 .. 1 |-> 0],
      responseType                 |-> [i \in 1 .. 1 |-> 0],
      errorCode                    |-> [i \in 1 .. 2 |-> 0],
      ackQualifiers                |-> [i \in 1 .. 1 |-> 0],
      wholesaleAckLegsGroups       |-> ZeroWholesaleAckLegsGroups,
      wholesaleAckClearingGroups   |-> ZeroWholesaleAckClearingGroups ]

(* Wholesale Order Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedWholesaleOrderAckMessage ==
    { ZeroWholesaleOrderAckMessage }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.sendingTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.oegInFromMember = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.oegOutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.bookInOptional = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.oegInFromMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.clientOrderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.contractSymbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.wholesaleTradeType = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.lisTransactionId = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.strategyCodeOptional = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.quantityOptional = one] : one \in Sample(8) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.mifidIndicators = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.wholesaleSide = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.escbMembership = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.responseType = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.ackQualifiers = one] : one \in Sample(1) }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.wholesaleAckLegsGroups = one] : one \in CheckedWholesaleAckLegsGroups }
        \cup { [ZeroWholesaleOrderAckMessage EXCEPT !.wholesaleAckClearingGroups = one] : one \in CheckedWholesaleAckClearingGroups }

(***************************************************************************)
(* Request For Implied Execution Message: 50 bytes                         *)
(***************************************************************************)

RequestForImpliedExecutionMessage ==
    [ clMsgSeqNum                   : Sample(4),
      firmId                        : Sample(8),
      sendingTime                   : Sample(8),
      clientOrderId                 : Sample(8),
      symbolIndex                   : Sample(4),
      emm                           : Sample(1),
      orderId                       : Sample(8),
      executionWithinFirmShortCode  : Sample(4),
      clientIdentificationShortcode : Sample(4),
      mifidIndicators               : Sample(1) ]

EncodeRequestForImpliedExecutionMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.clientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.orderId
        \o message.executionWithinFirmShortCode
        \o message.clientIdentificationShortcode
        \o message.mifidIndicators

DecodeRequestForImpliedExecutionMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(sendingTime.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET orderId == ReadBytes(emm.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(orderId.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET mifidIndicators == ReadBytes(clientIdentificationShortcode.rest, 1) IN IF ~mifidIndicators.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                   |-> clMsgSeqNum.value,
         firmId                        |-> firmId.value,
         sendingTime                   |-> sendingTime.value,
         clientOrderId                 |-> clientOrderId.value,
         symbolIndex                   |-> symbolIndex.value,
         emm                           |-> emm.value,
         orderId                       |-> orderId.value,
         executionWithinFirmShortCode  |-> executionWithinFirmShortCode.value,
         clientIdentificationShortcode |-> clientIdentificationShortcode.value,
         mifidIndicators               |-> mifidIndicators.value ], mifidIndicators.rest)

ZeroRequestForImpliedExecutionMessage ==
    [ clMsgSeqNum                   |-> [i \in 1 .. 4 |-> 0],
      firmId                        |-> [i \in 1 .. 8 |-> 0],
      sendingTime                   |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                 |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                   |-> [i \in 1 .. 4 |-> 0],
      emm                           |-> [i \in 1 .. 1 |-> 0],
      orderId                       |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode  |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode |-> [i \in 1 .. 4 |-> 0],
      mifidIndicators               |-> [i \in 1 .. 1 |-> 0] ]

(* Request For Implied Execution Message at zero, then each field in turn at the values it is checked at *)
CheckedRequestForImpliedExecutionMessage ==
    { ZeroRequestForImpliedExecutionMessage }
        \cup { [ZeroRequestForImpliedExecutionMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestForImpliedExecutionMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroRequestForImpliedExecutionMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroRequestForImpliedExecutionMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroRequestForImpliedExecutionMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroRequestForImpliedExecutionMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroRequestForImpliedExecutionMessage EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroRequestForImpliedExecutionMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroRequestForImpliedExecutionMessage EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroRequestForImpliedExecutionMessage EXCEPT !.mifidIndicators = one] : one \in Sample(1) }

(***************************************************************************)
(* New Order Message Free Text Section Group: 18 bytes                     *)
(***************************************************************************)

NewOrderMessageFreeTextSectionGroup3 ==
    [ freeText : Sample(18) ]

EncodeNewOrderMessageFreeTextSectionGroup3(message) ==
    message.freeText

DecodeNewOrderMessageFreeTextSectionGroup3(bytes) ==
    LET freeText == ReadBytes(bytes, 18) IN IF ~freeText.ok THEN Fail ELSE
    Ok([ freeText |-> freeText.value ], freeText.rest)

ZeroNewOrderMessageFreeTextSectionGroup3 ==
    [ freeText |-> [i \in 1 .. 18 |-> 0] ]

(* New Order Message Free Text Section Group at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderMessageFreeTextSectionGroup3 ==
    { ZeroNewOrderMessageFreeTextSectionGroup3 }
        \cup { [ZeroNewOrderMessageFreeTextSectionGroup3 EXCEPT !.freeText = one] : one \in Sample(18) }

(* A run of New Order Message Free Text Section Group, written one after another *)
RECURSIVE EncodeNewOrderMessageFreeTextSectionGroup3List(_)
EncodeNewOrderMessageFreeTextSectionGroup3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeNewOrderMessageFreeTextSectionGroup3(Head(messages)) \o EncodeNewOrderMessageFreeTextSectionGroup3List(Tail(messages))

(* As many New Order Message Free Text Section Group as the field that counts them says *)
RECURSIVE ReadNewOrderMessageFreeTextSectionGroup3List(_, _)
ReadNewOrderMessageFreeTextSectionGroup3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeNewOrderMessageFreeTextSectionGroup3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadNewOrderMessageFreeTextSectionGroup3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One New Order Message Free Text Section Group of each kind, for the lists that carry them *)
OneNewOrderMessageFreeTextSectionGroup3 == { ZeroNewOrderMessageFreeTextSectionGroup3 }

(***************************************************************************)
(* Free Text Groups                                                        *)
(***************************************************************************)

FreeTextGroups3 ==
    [ blockLengthShort                    : Sample(1),
      newOrderMessageFreeTextSectionGroup : SampleLists(OneNewOrderMessageFreeTextSectionGroup3) ]

EncodeFreeTextGroups3(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.newOrderMessageFreeTextSectionGroup), 1)
        \o EncodeNewOrderMessageFreeTextSectionGroup3List(message.newOrderMessageFreeTextSectionGroup)

DecodeFreeTextGroups3(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET newOrderMessageFreeTextSectionGroup == ReadNewOrderMessageFreeTextSectionGroup3List(numInGroup.rest, numInGroup.value) IN IF ~newOrderMessageFreeTextSectionGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort                    |-> blockLengthShort.value,
         newOrderMessageFreeTextSectionGroup |-> newOrderMessageFreeTextSectionGroup.value ], newOrderMessageFreeTextSectionGroup.rest)

ZeroFreeTextGroups3 ==
    [ blockLengthShort                    |-> [i \in 1 .. 1 |-> 0],
      newOrderMessageFreeTextSectionGroup |-> << >> ]

(* Free Text Groups at zero, then each field in turn at the values it is checked at *)
CheckedFreeTextGroups3 ==
    { ZeroFreeTextGroups3 }
        \cup { [ZeroFreeTextGroups3 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroFreeTextGroups3 EXCEPT !.newOrderMessageFreeTextSectionGroup = one] : one \in SampleLists(OneNewOrderMessageFreeTextSectionGroup3) }

(***************************************************************************)
(* Mifid Short Codes Group: 12 bytes                                       *)
(***************************************************************************)

MifidShortCodesGroup3 ==
    [ investmentDecisionWFirmShortCode : Sample(4),
      nonExecutingBrokerShortCode      : Sample(4),
      clientIdentificationShortcode    : Sample(4) ]

EncodeMifidShortCodesGroup3(message) ==
    message.investmentDecisionWFirmShortCode
        \o message.nonExecutingBrokerShortCode
        \o message.clientIdentificationShortcode

DecodeMifidShortCodesGroup3(bytes) ==
    LET investmentDecisionWFirmShortCode == ReadBytes(bytes, 4) IN IF ~investmentDecisionWFirmShortCode.ok THEN Fail ELSE
    LET nonExecutingBrokerShortCode == ReadBytes(investmentDecisionWFirmShortCode.rest, 4) IN IF ~nonExecutingBrokerShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(nonExecutingBrokerShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    Ok([ investmentDecisionWFirmShortCode |-> investmentDecisionWFirmShortCode.value,
         nonExecutingBrokerShortCode      |-> nonExecutingBrokerShortCode.value,
         clientIdentificationShortcode    |-> clientIdentificationShortcode.value ], clientIdentificationShortcode.rest)

ZeroMifidShortCodesGroup3 ==
    [ investmentDecisionWFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      nonExecutingBrokerShortCode      |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode    |-> [i \in 1 .. 4 |-> 0] ]

(* Mifid Short Codes Group at zero, then each field in turn at the values it is checked at *)
CheckedMifidShortCodesGroup3 ==
    { ZeroMifidShortCodesGroup3 }
        \cup { [ZeroMifidShortCodesGroup3 EXCEPT !.investmentDecisionWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroMifidShortCodesGroup3 EXCEPT !.nonExecutingBrokerShortCode = one] : one \in Sample(4) }
        \cup { [ZeroMifidShortCodesGroup3 EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }

(* A run of Mifid Short Codes Group, written one after another *)
RECURSIVE EncodeMifidShortCodesGroup3List(_)
EncodeMifidShortCodesGroup3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMifidShortCodesGroup3(Head(messages)) \o EncodeMifidShortCodesGroup3List(Tail(messages))

(* As many Mifid Short Codes Group as the field that counts them says *)
RECURSIVE ReadMifidShortCodesGroup3List(_, _)
ReadMifidShortCodesGroup3List(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMifidShortCodesGroup3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMifidShortCodesGroup3List(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Mifid Short Codes Group of each kind, for the lists that carry them *)
OneMifidShortCodesGroup3 == { ZeroMifidShortCodesGroup3 }

(***************************************************************************)
(* Mifid Short Codes Groups                                                *)
(***************************************************************************)

MifidShortCodesGroups3 ==
    [ blockLengthShort     : Sample(1),
      mifidShortCodesGroup : SampleLists(OneMifidShortCodesGroup3) ]

EncodeMifidShortCodesGroups3(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.mifidShortCodesGroup), 1)
        \o EncodeMifidShortCodesGroup3List(message.mifidShortCodesGroup)

DecodeMifidShortCodesGroups3(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET mifidShortCodesGroup == ReadMifidShortCodesGroup3List(numInGroup.rest, numInGroup.value) IN IF ~mifidShortCodesGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort     |-> blockLengthShort.value,
         mifidShortCodesGroup |-> mifidShortCodesGroup.value ], mifidShortCodesGroup.rest)

ZeroMifidShortCodesGroups3 ==
    [ blockLengthShort     |-> [i \in 1 .. 1 |-> 0],
      mifidShortCodesGroup |-> << >> ]

(* Mifid Short Codes Groups at zero, then each field in turn at the values it is checked at *)
CheckedMifidShortCodesGroups3 ==
    { ZeroMifidShortCodesGroups3 }
        \cup { [ZeroMifidShortCodesGroups3 EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroMifidShortCodesGroups3 EXCEPT !.mifidShortCodesGroup = one] : one \in SampleLists(OneMifidShortCodesGroup3) }

(***************************************************************************)
(* Cross Clearing Fields Group: 43 bytes                                   *)
(***************************************************************************)

CrossClearingFieldsGroup ==
    [ clearingFirmId          : Sample(8),
      longClientId            : Sample(16),
      accountNumber           : Sample(12),
      technicalOrigin         : Sample(1),
      openClose               : Sample(2),
      clearingInstruction     : Sample(2),
      accountType             : Sample(1),
      tradingCapacityOptional : Sample(1) ]

EncodeCrossClearingFieldsGroup(message) ==
    message.clearingFirmId
        \o message.longClientId
        \o message.accountNumber
        \o message.technicalOrigin
        \o message.openClose
        \o message.clearingInstruction
        \o message.accountType
        \o message.tradingCapacityOptional

DecodeCrossClearingFieldsGroup(bytes) ==
    LET clearingFirmId == ReadBytes(bytes, 8) IN IF ~clearingFirmId.ok THEN Fail ELSE
    LET longClientId == ReadBytes(clearingFirmId.rest, 16) IN IF ~longClientId.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(longClientId.rest, 12) IN IF ~accountNumber.ok THEN Fail ELSE
    LET technicalOrigin == ReadBytes(accountNumber.rest, 1) IN IF ~technicalOrigin.ok THEN Fail ELSE
    LET openClose == ReadBytes(technicalOrigin.rest, 2) IN IF ~openClose.ok THEN Fail ELSE
    LET clearingInstruction == ReadBytes(openClose.rest, 2) IN IF ~clearingInstruction.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingInstruction.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET tradingCapacityOptional == ReadBytes(accountType.rest, 1) IN IF ~tradingCapacityOptional.ok THEN Fail ELSE
    Ok([ clearingFirmId          |-> clearingFirmId.value,
         longClientId            |-> longClientId.value,
         accountNumber           |-> accountNumber.value,
         technicalOrigin         |-> technicalOrigin.value,
         openClose               |-> openClose.value,
         clearingInstruction     |-> clearingInstruction.value,
         accountType             |-> accountType.value,
         tradingCapacityOptional |-> tradingCapacityOptional.value ], tradingCapacityOptional.rest)

ZeroCrossClearingFieldsGroup ==
    [ clearingFirmId          |-> [i \in 1 .. 8 |-> 0],
      longClientId            |-> [i \in 1 .. 16 |-> 0],
      accountNumber           |-> [i \in 1 .. 12 |-> 0],
      technicalOrigin         |-> [i \in 1 .. 1 |-> 0],
      openClose               |-> [i \in 1 .. 2 |-> 0],
      clearingInstruction     |-> [i \in 1 .. 2 |-> 0],
      accountType             |-> [i \in 1 .. 1 |-> 0],
      tradingCapacityOptional |-> [i \in 1 .. 1 |-> 0] ]

(* Cross Clearing Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedCrossClearingFieldsGroup ==
    { ZeroCrossClearingFieldsGroup }
        \cup { [ZeroCrossClearingFieldsGroup EXCEPT !.clearingFirmId = one] : one \in Sample(8) }
        \cup { [ZeroCrossClearingFieldsGroup EXCEPT !.longClientId = one] : one \in Sample(16) }
        \cup { [ZeroCrossClearingFieldsGroup EXCEPT !.accountNumber = one] : one \in Sample(12) }
        \cup { [ZeroCrossClearingFieldsGroup EXCEPT !.technicalOrigin = one] : one \in Sample(1) }
        \cup { [ZeroCrossClearingFieldsGroup EXCEPT !.openClose = one] : one \in Sample(2) }
        \cup { [ZeroCrossClearingFieldsGroup EXCEPT !.clearingInstruction = one] : one \in Sample(2) }
        \cup { [ZeroCrossClearingFieldsGroup EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroCrossClearingFieldsGroup EXCEPT !.tradingCapacityOptional = one] : one \in Sample(1) }

(* A run of Cross Clearing Fields Group, written one after another *)
RECURSIVE EncodeCrossClearingFieldsGroupList(_)
EncodeCrossClearingFieldsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCrossClearingFieldsGroup(Head(messages)) \o EncodeCrossClearingFieldsGroupList(Tail(messages))

(* As many Cross Clearing Fields Group as the field that counts them says *)
RECURSIVE ReadCrossClearingFieldsGroupList(_, _)
ReadCrossClearingFieldsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeCrossClearingFieldsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCrossClearingFieldsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Cross Clearing Fields Group of each kind, for the lists that carry them *)
OneCrossClearingFieldsGroup == { ZeroCrossClearingFieldsGroup }

(***************************************************************************)
(* Cross Clearing Fields Groups                                            *)
(***************************************************************************)

CrossClearingFieldsGroups ==
    [ blockLengthShort         : Sample(1),
      crossClearingFieldsGroup : SampleLists(OneCrossClearingFieldsGroup) ]

EncodeCrossClearingFieldsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.crossClearingFieldsGroup), 1)
        \o EncodeCrossClearingFieldsGroupList(message.crossClearingFieldsGroup)

DecodeCrossClearingFieldsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET crossClearingFieldsGroup == ReadCrossClearingFieldsGroupList(numInGroup.rest, numInGroup.value) IN IF ~crossClearingFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort         |-> blockLengthShort.value,
         crossClearingFieldsGroup |-> crossClearingFieldsGroup.value ], crossClearingFieldsGroup.rest)

ZeroCrossClearingFieldsGroups ==
    [ blockLengthShort         |-> [i \in 1 .. 1 |-> 0],
      crossClearingFieldsGroup |-> << >> ]

(* Cross Clearing Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedCrossClearingFieldsGroups ==
    { ZeroCrossClearingFieldsGroups }
        \cup { [ZeroCrossClearingFieldsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroCrossClearingFieldsGroups EXCEPT !.crossClearingFieldsGroup = one] : one \in SampleLists(OneCrossClearingFieldsGroup) }

(***************************************************************************)
(* Cross Strategy Fields Group: 20 bytes                                   *)
(***************************************************************************)

CrossStrategyFieldsGroup ==
    [ legLastPx       : Sample(8),
      legLastQty      : Sample(8),
      legInstrumentId : Sample(4) ]

EncodeCrossStrategyFieldsGroup(message) ==
    message.legLastPx
        \o message.legLastQty
        \o message.legInstrumentId

DecodeCrossStrategyFieldsGroup(bytes) ==
    LET legLastPx == ReadBytes(bytes, 8) IN IF ~legLastPx.ok THEN Fail ELSE
    LET legLastQty == ReadBytes(legLastPx.rest, 8) IN IF ~legLastQty.ok THEN Fail ELSE
    LET legInstrumentId == ReadBytes(legLastQty.rest, 4) IN IF ~legInstrumentId.ok THEN Fail ELSE
    Ok([ legLastPx       |-> legLastPx.value,
         legLastQty      |-> legLastQty.value,
         legInstrumentId |-> legInstrumentId.value ], legInstrumentId.rest)

ZeroCrossStrategyFieldsGroup ==
    [ legLastPx       |-> [i \in 1 .. 8 |-> 0],
      legLastQty      |-> [i \in 1 .. 8 |-> 0],
      legInstrumentId |-> [i \in 1 .. 4 |-> 0] ]

(* Cross Strategy Fields Group at zero, then each field in turn at the values it is checked at *)
CheckedCrossStrategyFieldsGroup ==
    { ZeroCrossStrategyFieldsGroup }
        \cup { [ZeroCrossStrategyFieldsGroup EXCEPT !.legLastPx = one] : one \in Sample(8) }
        \cup { [ZeroCrossStrategyFieldsGroup EXCEPT !.legLastQty = one] : one \in Sample(8) }
        \cup { [ZeroCrossStrategyFieldsGroup EXCEPT !.legInstrumentId = one] : one \in Sample(4) }

(* A run of Cross Strategy Fields Group, written one after another *)
RECURSIVE EncodeCrossStrategyFieldsGroupList(_)
EncodeCrossStrategyFieldsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeCrossStrategyFieldsGroup(Head(messages)) \o EncodeCrossStrategyFieldsGroupList(Tail(messages))

(* As many Cross Strategy Fields Group as the field that counts them says *)
RECURSIVE ReadCrossStrategyFieldsGroupList(_, _)
ReadCrossStrategyFieldsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeCrossStrategyFieldsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadCrossStrategyFieldsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Cross Strategy Fields Group of each kind, for the lists that carry them *)
OneCrossStrategyFieldsGroup == { ZeroCrossStrategyFieldsGroup }

(***************************************************************************)
(* Cross Strategy Fields Groups                                            *)
(***************************************************************************)

CrossStrategyFieldsGroups ==
    [ blockLengthShort         : Sample(1),
      crossStrategyFieldsGroup : SampleLists(OneCrossStrategyFieldsGroup) ]

EncodeCrossStrategyFieldsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.crossStrategyFieldsGroup), 1)
        \o EncodeCrossStrategyFieldsGroupList(message.crossStrategyFieldsGroup)

DecodeCrossStrategyFieldsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET crossStrategyFieldsGroup == ReadCrossStrategyFieldsGroupList(numInGroup.rest, numInGroup.value) IN IF ~crossStrategyFieldsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort         |-> blockLengthShort.value,
         crossStrategyFieldsGroup |-> crossStrategyFieldsGroup.value ], crossStrategyFieldsGroup.rest)

ZeroCrossStrategyFieldsGroups ==
    [ blockLengthShort         |-> [i \in 1 .. 1 |-> 0],
      crossStrategyFieldsGroup |-> << >> ]

(* Cross Strategy Fields Groups at zero, then each field in turn at the values it is checked at *)
CheckedCrossStrategyFieldsGroups ==
    { ZeroCrossStrategyFieldsGroups }
        \cup { [ZeroCrossStrategyFieldsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroCrossStrategyFieldsGroups EXCEPT !.crossStrategyFieldsGroup = one] : one \in SampleLists(OneCrossStrategyFieldsGroup) }

(***************************************************************************)
(* Cross Order Message                                                     *)
(***************************************************************************)

CrossOrderMessage ==
    [ clMsgSeqNum                  : Sample(4),
      firmId                       : Sample(8),
      sendingTime                  : Sample(8),
      clientOrderId                : Sample(8),
      symbolIndex                  : Sample(4),
      emm                          : Sample(1),
      side                         : Sample(1),
      orderType                    : Sample(1),
      orderPx                      : Sample(8),
      orderQty                     : Sample(8),
      executionWithinFirmShortCode : Sample(4),
      mifidIndicators              : Sample(1),
      nonExecutingClientId         : Sample(2),
      orderActorType               : Sample(1),
      messagePriceNotation         : Sample(1),
      freeTextGroups               : FreeTextGroups3,
      mifidShortCodesGroups        : MifidShortCodesGroups3,
      crossClearingFieldsGroups    : CrossClearingFieldsGroups,
      crossStrategyFieldsGroups    : CrossStrategyFieldsGroups ]

EncodeCrossOrderMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.clientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.side
        \o message.orderType
        \o message.orderPx
        \o message.orderQty
        \o message.executionWithinFirmShortCode
        \o message.mifidIndicators
        \o message.nonExecutingClientId
        \o message.orderActorType
        \o message.messagePriceNotation
        \o EncodeFreeTextGroups3(message.freeTextGroups)
        \o EncodeMifidShortCodesGroups3(message.mifidShortCodesGroups)
        \o EncodeCrossClearingFieldsGroups(message.crossClearingFieldsGroups)
        \o EncodeCrossStrategyFieldsGroups(message.crossStrategyFieldsGroups)

DecodeCrossOrderMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(sendingTime.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET side == ReadBytes(emm.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderType == ReadBytes(side.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET orderPx == ReadBytes(orderType.rest, 8) IN IF ~orderPx.ok THEN Fail ELSE
    LET orderQty == ReadBytes(orderPx.rest, 8) IN IF ~orderQty.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(orderQty.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET mifidIndicators == ReadBytes(executionWithinFirmShortCode.rest, 1) IN IF ~mifidIndicators.ok THEN Fail ELSE
    LET nonExecutingClientId == ReadBytes(mifidIndicators.rest, 2) IN IF ~nonExecutingClientId.ok THEN Fail ELSE
    LET orderActorType == ReadBytes(nonExecutingClientId.rest, 1) IN IF ~orderActorType.ok THEN Fail ELSE
    LET messagePriceNotation == ReadBytes(orderActorType.rest, 1) IN IF ~messagePriceNotation.ok THEN Fail ELSE
    LET freeTextGroups == DecodeFreeTextGroups3(messagePriceNotation.rest) IN IF ~freeTextGroups.ok THEN Fail ELSE
    LET mifidShortCodesGroups == DecodeMifidShortCodesGroups3(freeTextGroups.rest) IN IF ~mifidShortCodesGroups.ok THEN Fail ELSE
    LET crossClearingFieldsGroups == DecodeCrossClearingFieldsGroups(mifidShortCodesGroups.rest) IN IF ~crossClearingFieldsGroups.ok THEN Fail ELSE
    LET crossStrategyFieldsGroups == DecodeCrossStrategyFieldsGroups(crossClearingFieldsGroups.rest) IN IF ~crossStrategyFieldsGroups.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                  |-> clMsgSeqNum.value,
         firmId                       |-> firmId.value,
         sendingTime                  |-> sendingTime.value,
         clientOrderId                |-> clientOrderId.value,
         symbolIndex                  |-> symbolIndex.value,
         emm                          |-> emm.value,
         side                         |-> side.value,
         orderType                    |-> orderType.value,
         orderPx                      |-> orderPx.value,
         orderQty                     |-> orderQty.value,
         executionWithinFirmShortCode |-> executionWithinFirmShortCode.value,
         mifidIndicators              |-> mifidIndicators.value,
         nonExecutingClientId         |-> nonExecutingClientId.value,
         orderActorType               |-> orderActorType.value,
         messagePriceNotation         |-> messagePriceNotation.value,
         freeTextGroups               |-> freeTextGroups.value,
         mifidShortCodesGroups        |-> mifidShortCodesGroups.value,
         crossClearingFieldsGroups    |-> crossClearingFieldsGroups.value,
         crossStrategyFieldsGroups    |-> crossStrategyFieldsGroups.value ], crossStrategyFieldsGroups.rest)

ZeroCrossOrderMessage ==
    [ clMsgSeqNum                  |-> [i \in 1 .. 4 |-> 0],
      firmId                       |-> [i \in 1 .. 8 |-> 0],
      sendingTime                  |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                |-> [i \in 1 .. 8 |-> 0],
      symbolIndex                  |-> [i \in 1 .. 4 |-> 0],
      emm                          |-> [i \in 1 .. 1 |-> 0],
      side                         |-> [i \in 1 .. 1 |-> 0],
      orderType                    |-> [i \in 1 .. 1 |-> 0],
      orderPx                      |-> [i \in 1 .. 8 |-> 0],
      orderQty                     |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      mifidIndicators              |-> [i \in 1 .. 1 |-> 0],
      nonExecutingClientId         |-> [i \in 1 .. 2 |-> 0],
      orderActorType               |-> [i \in 1 .. 1 |-> 0],
      messagePriceNotation         |-> [i \in 1 .. 1 |-> 0],
      freeTextGroups               |-> ZeroFreeTextGroups3,
      mifidShortCodesGroups        |-> ZeroMifidShortCodesGroups3,
      crossClearingFieldsGroups    |-> ZeroCrossClearingFieldsGroups,
      crossStrategyFieldsGroups    |-> ZeroCrossStrategyFieldsGroups ]

(* Cross Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossOrderMessage ==
    { ZeroCrossOrderMessage }
        \cup { [ZeroCrossOrderMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.orderPx = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.orderQty = one] : one \in Sample(8) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.mifidIndicators = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.nonExecutingClientId = one] : one \in Sample(2) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.orderActorType = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.messagePriceNotation = one] : one \in Sample(1) }
        \cup { [ZeroCrossOrderMessage EXCEPT !.freeTextGroups = one] : one \in CheckedFreeTextGroups3 }
        \cup { [ZeroCrossOrderMessage EXCEPT !.mifidShortCodesGroups = one] : one \in CheckedMifidShortCodesGroups3 }
        \cup { [ZeroCrossOrderMessage EXCEPT !.crossClearingFieldsGroups = one] : one \in CheckedCrossClearingFieldsGroups }
        \cup { [ZeroCrossOrderMessage EXCEPT !.crossStrategyFieldsGroups = one] : one \in CheckedCrossStrategyFieldsGroups }

(***************************************************************************)
(* Rfq Counterparts Group: 26 bytes                                        *)
(***************************************************************************)

RfqCounterpartsGroup ==
    [ orderOrigin                      : Sample(1),
      orderPrice                       : Sample(8),
      lastTradedQuantity               : Sample(8),
      darkExecutionInstructionOptional : Sample(1),
      minimumOrderQuantity             : Sample(8) ]

EncodeRfqCounterpartsGroup(message) ==
    message.orderOrigin
        \o message.orderPrice
        \o message.lastTradedQuantity
        \o message.darkExecutionInstructionOptional
        \o message.minimumOrderQuantity

DecodeRfqCounterpartsGroup(bytes) ==
    LET orderOrigin == ReadBytes(bytes, 1) IN IF ~orderOrigin.ok THEN Fail ELSE
    LET orderPrice == ReadBytes(orderOrigin.rest, 8) IN IF ~orderPrice.ok THEN Fail ELSE
    LET lastTradedQuantity == ReadBytes(orderPrice.rest, 8) IN IF ~lastTradedQuantity.ok THEN Fail ELSE
    LET darkExecutionInstructionOptional == ReadBytes(lastTradedQuantity.rest, 1) IN IF ~darkExecutionInstructionOptional.ok THEN Fail ELSE
    LET minimumOrderQuantity == ReadBytes(darkExecutionInstructionOptional.rest, 8) IN IF ~minimumOrderQuantity.ok THEN Fail ELSE
    Ok([ orderOrigin                      |-> orderOrigin.value,
         orderPrice                       |-> orderPrice.value,
         lastTradedQuantity               |-> lastTradedQuantity.value,
         darkExecutionInstructionOptional |-> darkExecutionInstructionOptional.value,
         minimumOrderQuantity             |-> minimumOrderQuantity.value ], minimumOrderQuantity.rest)

ZeroRfqCounterpartsGroup ==
    [ orderOrigin                      |-> [i \in 1 .. 1 |-> 0],
      orderPrice                       |-> [i \in 1 .. 8 |-> 0],
      lastTradedQuantity               |-> [i \in 1 .. 8 |-> 0],
      darkExecutionInstructionOptional |-> [i \in 1 .. 1 |-> 0],
      minimumOrderQuantity             |-> [i \in 1 .. 8 |-> 0] ]

(* Rfq Counterparts Group at zero, then each field in turn at the values it is checked at *)
CheckedRfqCounterpartsGroup ==
    { ZeroRfqCounterpartsGroup }
        \cup { [ZeroRfqCounterpartsGroup EXCEPT !.orderOrigin = one] : one \in Sample(1) }
        \cup { [ZeroRfqCounterpartsGroup EXCEPT !.orderPrice = one] : one \in Sample(8) }
        \cup { [ZeroRfqCounterpartsGroup EXCEPT !.lastTradedQuantity = one] : one \in Sample(8) }
        \cup { [ZeroRfqCounterpartsGroup EXCEPT !.darkExecutionInstructionOptional = one] : one \in Sample(1) }
        \cup { [ZeroRfqCounterpartsGroup EXCEPT !.minimumOrderQuantity = one] : one \in Sample(8) }

(* A run of Rfq Counterparts Group, written one after another *)
RECURSIVE EncodeRfqCounterpartsGroupList(_)
EncodeRfqCounterpartsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRfqCounterpartsGroup(Head(messages)) \o EncodeRfqCounterpartsGroupList(Tail(messages))

(* As many Rfq Counterparts Group as the field that counts them says *)
RECURSIVE ReadRfqCounterpartsGroupList(_, _)
ReadRfqCounterpartsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRfqCounterpartsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRfqCounterpartsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Rfq Counterparts Group of each kind, for the lists that carry them *)
OneRfqCounterpartsGroup == { ZeroRfqCounterpartsGroup }

(***************************************************************************)
(* Rfq Counterparts Groups                                                 *)
(***************************************************************************)

RfqCounterpartsGroups ==
    [ blockLengthShort     : Sample(1),
      rfqCounterpartsGroup : SampleLists(OneRfqCounterpartsGroup) ]

EncodeRfqCounterpartsGroups(message) ==
    message.blockLengthShort
        \o EncodeUIntBE(Len(message.rfqCounterpartsGroup), 1)
        \o EncodeRfqCounterpartsGroupList(message.rfqCounterpartsGroup)

DecodeRfqCounterpartsGroups(bytes) ==
    LET blockLengthShort == ReadBytes(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET rfqCounterpartsGroup == ReadRfqCounterpartsGroupList(numInGroup.rest, numInGroup.value) IN IF ~rfqCounterpartsGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort     |-> blockLengthShort.value,
         rfqCounterpartsGroup |-> rfqCounterpartsGroup.value ], rfqCounterpartsGroup.rest)

ZeroRfqCounterpartsGroups ==
    [ blockLengthShort     |-> [i \in 1 .. 1 |-> 0],
      rfqCounterpartsGroup |-> << >> ]

(* Rfq Counterparts Groups at zero, then each field in turn at the values it is checked at *)
CheckedRfqCounterpartsGroups ==
    { ZeroRfqCounterpartsGroups }
        \cup { [ZeroRfqCounterpartsGroups EXCEPT !.blockLengthShort = one] : one \in Sample(1) }
        \cup { [ZeroRfqCounterpartsGroups EXCEPT !.rfqCounterpartsGroup = one] : one \in SampleLists(OneRfqCounterpartsGroup) }

(***************************************************************************)
(* Rfq Audit Message                                                       *)
(***************************************************************************)

RfqAuditMessage ==
    [ msgSeqNum             : Sample(4),
      firmId                : Sample(8),
      bookIn                : Sample(8),
      bookOutTime           : Sample(8),
      oegInFromMe           : Sample(8),
      oegOutToMember        : Sample(8),
      quoteReqId            : Sample(8),
      symbolIndex           : Sample(4),
      emm                   : Sample(1),
      rfqCounterpartsGroups : RfqCounterpartsGroups ]

EncodeRfqAuditMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.bookIn
        \o message.bookOutTime
        \o message.oegInFromMe
        \o message.oegOutToMember
        \o message.quoteReqId
        \o message.symbolIndex
        \o message.emm
        \o EncodeRfqCounterpartsGroups(message.rfqCounterpartsGroups)

DecodeRfqAuditMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET bookIn == ReadBytes(firmId.rest, 8) IN IF ~bookIn.ok THEN Fail ELSE
    LET bookOutTime == ReadBytes(bookIn.rest, 8) IN IF ~bookOutTime.ok THEN Fail ELSE
    LET oegInFromMe == ReadBytes(bookOutTime.rest, 8) IN IF ~oegInFromMe.ok THEN Fail ELSE
    LET oegOutToMember == ReadBytes(oegInFromMe.rest, 8) IN IF ~oegOutToMember.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(oegOutToMember.rest, 8) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(quoteReqId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET rfqCounterpartsGroups == DecodeRfqCounterpartsGroups(emm.rest) IN IF ~rfqCounterpartsGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum             |-> msgSeqNum.value,
         firmId                |-> firmId.value,
         bookIn                |-> bookIn.value,
         bookOutTime           |-> bookOutTime.value,
         oegInFromMe           |-> oegInFromMe.value,
         oegOutToMember        |-> oegOutToMember.value,
         quoteReqId            |-> quoteReqId.value,
         symbolIndex           |-> symbolIndex.value,
         emm                   |-> emm.value,
         rfqCounterpartsGroups |-> rfqCounterpartsGroups.value ], rfqCounterpartsGroups.rest)

ZeroRfqAuditMessage ==
    [ msgSeqNum             |-> [i \in 1 .. 4 |-> 0],
      firmId                |-> [i \in 1 .. 8 |-> 0],
      bookIn                |-> [i \in 1 .. 8 |-> 0],
      bookOutTime           |-> [i \in 1 .. 8 |-> 0],
      oegInFromMe           |-> [i \in 1 .. 8 |-> 0],
      oegOutToMember        |-> [i \in 1 .. 8 |-> 0],
      quoteReqId            |-> [i \in 1 .. 8 |-> 0],
      symbolIndex           |-> [i \in 1 .. 4 |-> 0],
      emm                   |-> [i \in 1 .. 1 |-> 0],
      rfqCounterpartsGroups |-> ZeroRfqCounterpartsGroups ]

(* Rfq Audit Message at zero, then each field in turn at the values it is checked at *)
CheckedRfqAuditMessage ==
    { ZeroRfqAuditMessage }
        \cup { [ZeroRfqAuditMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroRfqAuditMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroRfqAuditMessage EXCEPT !.bookIn = one] : one \in Sample(8) }
        \cup { [ZeroRfqAuditMessage EXCEPT !.bookOutTime = one] : one \in Sample(8) }
        \cup { [ZeroRfqAuditMessage EXCEPT !.oegInFromMe = one] : one \in Sample(8) }
        \cup { [ZeroRfqAuditMessage EXCEPT !.oegOutToMember = one] : one \in Sample(8) }
        \cup { [ZeroRfqAuditMessage EXCEPT !.quoteReqId = one] : one \in Sample(8) }
        \cup { [ZeroRfqAuditMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroRfqAuditMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroRfqAuditMessage EXCEPT !.rfqCounterpartsGroups = one] : one \in CheckedRfqCounterpartsGroups }

(***************************************************************************)
(* Wave For Liquidity Message: 55 bytes                                    *)
(***************************************************************************)

WaveForLiquidityMessage ==
    [ clMsgSeqNum          : Sample(4),
      firmId               : Sample(8),
      sendingTime          : Sample(8),
      ioiId                : Sample(8),
      ioiTransactionType   : Sample(1),
      originalIoiid        : Sample(8),
      targetCounterparties : Sample(2),
      symbolIndex          : Sample(4),
      emm                  : Sample(1),
      ioiSide              : Sample(1),
      orderQuantity        : Sample(8),
      ioiQuantity          : Sample(1),
      ioiQualityIndication : Sample(1) ]

EncodeWaveForLiquidityMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.ioiId
        \o message.ioiTransactionType
        \o message.originalIoiid
        \o message.targetCounterparties
        \o message.symbolIndex
        \o message.emm
        \o message.ioiSide
        \o message.orderQuantity
        \o message.ioiQuantity
        \o message.ioiQualityIndication

DecodeWaveForLiquidityMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET ioiId == ReadBytes(sendingTime.rest, 8) IN IF ~ioiId.ok THEN Fail ELSE
    LET ioiTransactionType == ReadBytes(ioiId.rest, 1) IN IF ~ioiTransactionType.ok THEN Fail ELSE
    LET originalIoiid == ReadBytes(ioiTransactionType.rest, 8) IN IF ~originalIoiid.ok THEN Fail ELSE
    LET targetCounterparties == ReadBytes(originalIoiid.rest, 2) IN IF ~targetCounterparties.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(targetCounterparties.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET ioiSide == ReadBytes(emm.rest, 1) IN IF ~ioiSide.ok THEN Fail ELSE
    LET orderQuantity == ReadBytes(ioiSide.rest, 8) IN IF ~orderQuantity.ok THEN Fail ELSE
    LET ioiQuantity == ReadBytes(orderQuantity.rest, 1) IN IF ~ioiQuantity.ok THEN Fail ELSE
    LET ioiQualityIndication == ReadBytes(ioiQuantity.rest, 1) IN IF ~ioiQualityIndication.ok THEN Fail ELSE
    Ok([ clMsgSeqNum          |-> clMsgSeqNum.value,
         firmId               |-> firmId.value,
         sendingTime          |-> sendingTime.value,
         ioiId                |-> ioiId.value,
         ioiTransactionType   |-> ioiTransactionType.value,
         originalIoiid        |-> originalIoiid.value,
         targetCounterparties |-> targetCounterparties.value,
         symbolIndex          |-> symbolIndex.value,
         emm                  |-> emm.value,
         ioiSide              |-> ioiSide.value,
         orderQuantity        |-> orderQuantity.value,
         ioiQuantity          |-> ioiQuantity.value,
         ioiQualityIndication |-> ioiQualityIndication.value ], ioiQualityIndication.rest)

ZeroWaveForLiquidityMessage ==
    [ clMsgSeqNum          |-> [i \in 1 .. 4 |-> 0],
      firmId               |-> [i \in 1 .. 8 |-> 0],
      sendingTime          |-> [i \in 1 .. 8 |-> 0],
      ioiId                |-> [i \in 1 .. 8 |-> 0],
      ioiTransactionType   |-> [i \in 1 .. 1 |-> 0],
      originalIoiid        |-> [i \in 1 .. 8 |-> 0],
      targetCounterparties |-> [i \in 1 .. 2 |-> 0],
      symbolIndex          |-> [i \in 1 .. 4 |-> 0],
      emm                  |-> [i \in 1 .. 1 |-> 0],
      ioiSide              |-> [i \in 1 .. 1 |-> 0],
      orderQuantity        |-> [i \in 1 .. 8 |-> 0],
      ioiQuantity          |-> [i \in 1 .. 1 |-> 0],
      ioiQualityIndication |-> [i \in 1 .. 1 |-> 0] ]

(* Wave For Liquidity Message at zero, then each field in turn at the values it is checked at *)
CheckedWaveForLiquidityMessage ==
    { ZeroWaveForLiquidityMessage }
        \cup { [ZeroWaveForLiquidityMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroWaveForLiquidityMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityMessage EXCEPT !.ioiId = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityMessage EXCEPT !.ioiTransactionType = one] : one \in Sample(1) }
        \cup { [ZeroWaveForLiquidityMessage EXCEPT !.originalIoiid = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityMessage EXCEPT !.targetCounterparties = one] : one \in Sample(2) }
        \cup { [ZeroWaveForLiquidityMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroWaveForLiquidityMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroWaveForLiquidityMessage EXCEPT !.ioiSide = one] : one \in Sample(1) }
        \cup { [ZeroWaveForLiquidityMessage EXCEPT !.orderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityMessage EXCEPT !.ioiQuantity = one] : one \in Sample(1) }
        \cup { [ZeroWaveForLiquidityMessage EXCEPT !.ioiQualityIndication = one] : one \in Sample(1) }

(***************************************************************************)
(* Wave For Liquidity Notification Message: 111 bytes                      *)
(***************************************************************************)

WaveForLiquidityNotificationMessage ==
    [ msgSeqNum              : Sample(4),
      firmId                 : Sample(8),
      sendingTime            : Sample(8),
      oegInFromMember        : Sample(8),
      oegOutTimeToMe         : Sample(8),
      bookInOptional         : Sample(8),
      bookOutTimeOptional    : Sample(8),
      oegInFromMeOptional    : Sample(8),
      oegOutToMemberOptional : Sample(8),
      ioiIdOptional          : Sample(8),
      exchangeIoiIdOptional  : Sample(8),
      ioiType                : Sample(1),
      originalIoiid          : Sample(8),
      symbolIndex            : Sample(4),
      emmOptional            : Sample(1),
      ioiSide                : Sample(1),
      orderQuantity          : Sample(8),
      ioiQuantity            : Sample(1),
      ioiQualityIndication   : Sample(1),
      errorCodeOptional      : Sample(2) ]

EncodeWaveForLiquidityNotificationMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.oegInFromMember
        \o message.oegOutTimeToMe
        \o message.bookInOptional
        \o message.bookOutTimeOptional
        \o message.oegInFromMeOptional
        \o message.oegOutToMemberOptional
        \o message.ioiIdOptional
        \o message.exchangeIoiIdOptional
        \o message.ioiType
        \o message.originalIoiid
        \o message.symbolIndex
        \o message.emmOptional
        \o message.ioiSide
        \o message.orderQuantity
        \o message.ioiQuantity
        \o message.ioiQualityIndication
        \o message.errorCodeOptional

DecodeWaveForLiquidityNotificationMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET oegInFromMember == ReadBytes(sendingTime.rest, 8) IN IF ~oegInFromMember.ok THEN Fail ELSE
    LET oegOutTimeToMe == ReadBytes(oegInFromMember.rest, 8) IN IF ~oegOutTimeToMe.ok THEN Fail ELSE
    LET bookInOptional == ReadBytes(oegOutTimeToMe.rest, 8) IN IF ~bookInOptional.ok THEN Fail ELSE
    LET bookOutTimeOptional == ReadBytes(bookInOptional.rest, 8) IN IF ~bookOutTimeOptional.ok THEN Fail ELSE
    LET oegInFromMeOptional == ReadBytes(bookOutTimeOptional.rest, 8) IN IF ~oegInFromMeOptional.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(oegInFromMeOptional.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET ioiIdOptional == ReadBytes(oegOutToMemberOptional.rest, 8) IN IF ~ioiIdOptional.ok THEN Fail ELSE
    LET exchangeIoiIdOptional == ReadBytes(ioiIdOptional.rest, 8) IN IF ~exchangeIoiIdOptional.ok THEN Fail ELSE
    LET ioiType == ReadBytes(exchangeIoiIdOptional.rest, 1) IN IF ~ioiType.ok THEN Fail ELSE
    LET originalIoiid == ReadBytes(ioiType.rest, 8) IN IF ~originalIoiid.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(originalIoiid.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emmOptional == ReadBytes(symbolIndex.rest, 1) IN IF ~emmOptional.ok THEN Fail ELSE
    LET ioiSide == ReadBytes(emmOptional.rest, 1) IN IF ~ioiSide.ok THEN Fail ELSE
    LET orderQuantity == ReadBytes(ioiSide.rest, 8) IN IF ~orderQuantity.ok THEN Fail ELSE
    LET ioiQuantity == ReadBytes(orderQuantity.rest, 1) IN IF ~ioiQuantity.ok THEN Fail ELSE
    LET ioiQualityIndication == ReadBytes(ioiQuantity.rest, 1) IN IF ~ioiQualityIndication.ok THEN Fail ELSE
    LET errorCodeOptional == ReadBytes(ioiQualityIndication.rest, 2) IN IF ~errorCodeOptional.ok THEN Fail ELSE
    Ok([ msgSeqNum              |-> msgSeqNum.value,
         firmId                 |-> firmId.value,
         sendingTime            |-> sendingTime.value,
         oegInFromMember        |-> oegInFromMember.value,
         oegOutTimeToMe         |-> oegOutTimeToMe.value,
         bookInOptional         |-> bookInOptional.value,
         bookOutTimeOptional    |-> bookOutTimeOptional.value,
         oegInFromMeOptional    |-> oegInFromMeOptional.value,
         oegOutToMemberOptional |-> oegOutToMemberOptional.value,
         ioiIdOptional          |-> ioiIdOptional.value,
         exchangeIoiIdOptional  |-> exchangeIoiIdOptional.value,
         ioiType                |-> ioiType.value,
         originalIoiid          |-> originalIoiid.value,
         symbolIndex            |-> symbolIndex.value,
         emmOptional            |-> emmOptional.value,
         ioiSide                |-> ioiSide.value,
         orderQuantity          |-> orderQuantity.value,
         ioiQuantity            |-> ioiQuantity.value,
         ioiQualityIndication   |-> ioiQualityIndication.value,
         errorCodeOptional      |-> errorCodeOptional.value ], errorCodeOptional.rest)

ZeroWaveForLiquidityNotificationMessage ==
    [ msgSeqNum              |-> [i \in 1 .. 4 |-> 0],
      firmId                 |-> [i \in 1 .. 8 |-> 0],
      sendingTime            |-> [i \in 1 .. 8 |-> 0],
      oegInFromMember        |-> [i \in 1 .. 8 |-> 0],
      oegOutTimeToMe         |-> [i \in 1 .. 8 |-> 0],
      bookInOptional         |-> [i \in 1 .. 8 |-> 0],
      bookOutTimeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegInFromMeOptional    |-> [i \in 1 .. 8 |-> 0],
      oegOutToMemberOptional |-> [i \in 1 .. 8 |-> 0],
      ioiIdOptional          |-> [i \in 1 .. 8 |-> 0],
      exchangeIoiIdOptional  |-> [i \in 1 .. 8 |-> 0],
      ioiType                |-> [i \in 1 .. 1 |-> 0],
      originalIoiid          |-> [i \in 1 .. 8 |-> 0],
      symbolIndex            |-> [i \in 1 .. 4 |-> 0],
      emmOptional            |-> [i \in 1 .. 1 |-> 0],
      ioiSide                |-> [i \in 1 .. 1 |-> 0],
      orderQuantity          |-> [i \in 1 .. 8 |-> 0],
      ioiQuantity            |-> [i \in 1 .. 1 |-> 0],
      ioiQualityIndication   |-> [i \in 1 .. 1 |-> 0],
      errorCodeOptional      |-> [i \in 1 .. 2 |-> 0] ]

(* Wave For Liquidity Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedWaveForLiquidityNotificationMessage ==
    { ZeroWaveForLiquidityNotificationMessage }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.oegInFromMember = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.oegOutTimeToMe = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.bookInOptional = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.bookOutTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.oegInFromMeOptional = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.ioiIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.exchangeIoiIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.ioiType = one] : one \in Sample(1) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.originalIoiid = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.emmOptional = one] : one \in Sample(1) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.ioiSide = one] : one \in Sample(1) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.orderQuantity = one] : one \in Sample(8) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.ioiQuantity = one] : one \in Sample(1) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.ioiQualityIndication = one] : one \in Sample(1) }
        \cup { [ZeroWaveForLiquidityNotificationMessage EXCEPT !.errorCodeOptional = one] : one \in Sample(2) }

(***************************************************************************)
(* Clear Book Message: 17 bytes                                            *)
(***************************************************************************)

ClearBookMessage ==
    [ msgSeqNum              : Sample(4),
      oegOutToMemberOptional : Sample(8),
      symbolIndex            : Sample(4),
      emm                    : Sample(1) ]

EncodeClearBookMessage(message) ==
    message.msgSeqNum
        \o message.oegOutToMemberOptional
        \o message.symbolIndex
        \o message.emm

DecodeClearBookMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET oegOutToMemberOptional == ReadBytes(msgSeqNum.rest, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(oegOutToMemberOptional.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    Ok([ msgSeqNum              |-> msgSeqNum.value,
         oegOutToMemberOptional |-> oegOutToMemberOptional.value,
         symbolIndex            |-> symbolIndex.value,
         emm                    |-> emm.value ], emm.rest)

ZeroClearBookMessage ==
    [ msgSeqNum              |-> [i \in 1 .. 4 |-> 0],
      oegOutToMemberOptional |-> [i \in 1 .. 8 |-> 0],
      symbolIndex            |-> [i \in 1 .. 4 |-> 0],
      emm                    |-> [i \in 1 .. 1 |-> 0] ]

(* Clear Book Message at zero, then each field in turn at the values it is checked at *)
CheckedClearBookMessage ==
    { ZeroClearBookMessage }
        \cup { [ZeroClearBookMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroClearBookMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroClearBookMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroClearBookMessage EXCEPT !.emm = one] : one \in Sample(1) }

(***************************************************************************)
(* Logon Message: 19 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ logicalAccessId       : Sample(4),
      oePartitionId         : Sample(2),
      lastMsgSeqNumOptional : Sample(4),
      softwareProvider      : Sample(8),
      queueingIndicator     : Sample(1) ]

EncodeLogonMessage(message) ==
    message.logicalAccessId
        \o message.oePartitionId
        \o message.lastMsgSeqNumOptional
        \o message.softwareProvider
        \o message.queueingIndicator

DecodeLogonMessage(bytes) ==
    LET logicalAccessId == ReadBytes(bytes, 4) IN IF ~logicalAccessId.ok THEN Fail ELSE
    LET oePartitionId == ReadBytes(logicalAccessId.rest, 2) IN IF ~oePartitionId.ok THEN Fail ELSE
    LET lastMsgSeqNumOptional == ReadBytes(oePartitionId.rest, 4) IN IF ~lastMsgSeqNumOptional.ok THEN Fail ELSE
    LET softwareProvider == ReadBytes(lastMsgSeqNumOptional.rest, 8) IN IF ~softwareProvider.ok THEN Fail ELSE
    LET queueingIndicator == ReadBytes(softwareProvider.rest, 1) IN IF ~queueingIndicator.ok THEN Fail ELSE
    Ok([ logicalAccessId       |-> logicalAccessId.value,
         oePartitionId         |-> oePartitionId.value,
         lastMsgSeqNumOptional |-> lastMsgSeqNumOptional.value,
         softwareProvider      |-> softwareProvider.value,
         queueingIndicator     |-> queueingIndicator.value ], queueingIndicator.rest)

ZeroLogonMessage ==
    [ logicalAccessId       |-> [i \in 1 .. 4 |-> 0],
      oePartitionId         |-> [i \in 1 .. 2 |-> 0],
      lastMsgSeqNumOptional |-> [i \in 1 .. 4 |-> 0],
      softwareProvider      |-> [i \in 1 .. 8 |-> 0],
      queueingIndicator     |-> [i \in 1 .. 1 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.logicalAccessId = one] : one \in Sample(4) }
        \cup { [ZeroLogonMessage EXCEPT !.oePartitionId = one] : one \in Sample(2) }
        \cup { [ZeroLogonMessage EXCEPT !.lastMsgSeqNumOptional = one] : one \in Sample(4) }
        \cup { [ZeroLogonMessage EXCEPT !.softwareProvider = one] : one \in Sample(8) }
        \cup { [ZeroLogonMessage EXCEPT !.queueingIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Logon Ack Message: 12 bytes                                             *)
(***************************************************************************)

LogonAckMessage ==
    [ exchangeId      : Sample(8),
      lastClMsgSeqNum : Sample(4) ]

EncodeLogonAckMessage(message) ==
    message.exchangeId
        \o message.lastClMsgSeqNum

DecodeLogonAckMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 8) IN IF ~exchangeId.ok THEN Fail ELSE
    LET lastClMsgSeqNum == ReadBytes(exchangeId.rest, 4) IN IF ~lastClMsgSeqNum.ok THEN Fail ELSE
    Ok([ exchangeId      |-> exchangeId.value,
         lastClMsgSeqNum |-> lastClMsgSeqNum.value ], lastClMsgSeqNum.rest)

ZeroLogonAckMessage ==
    [ exchangeId      |-> [i \in 1 .. 8 |-> 0],
      lastClMsgSeqNum |-> [i \in 1 .. 4 |-> 0] ]

(* Logon Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonAckMessage ==
    { ZeroLogonAckMessage }
        \cup { [ZeroLogonAckMessage EXCEPT !.exchangeId = one] : one \in Sample(8) }
        \cup { [ZeroLogonAckMessage EXCEPT !.lastClMsgSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Logon Reject Message: 17 bytes                                          *)
(***************************************************************************)

LogonRejectMessage ==
    [ exchangeId      : Sample(8),
      logonRejectCode : Sample(1),
      lastClMsgSeqNum : Sample(4),
      lastMsgSeqNum   : Sample(4) ]

EncodeLogonRejectMessage(message) ==
    message.exchangeId
        \o message.logonRejectCode
        \o message.lastClMsgSeqNum
        \o message.lastMsgSeqNum

DecodeLogonRejectMessage(bytes) ==
    LET exchangeId == ReadBytes(bytes, 8) IN IF ~exchangeId.ok THEN Fail ELSE
    LET logonRejectCode == ReadBytes(exchangeId.rest, 1) IN IF ~logonRejectCode.ok THEN Fail ELSE
    LET lastClMsgSeqNum == ReadBytes(logonRejectCode.rest, 4) IN IF ~lastClMsgSeqNum.ok THEN Fail ELSE
    LET lastMsgSeqNum == ReadBytes(lastClMsgSeqNum.rest, 4) IN IF ~lastMsgSeqNum.ok THEN Fail ELSE
    Ok([ exchangeId      |-> exchangeId.value,
         logonRejectCode |-> logonRejectCode.value,
         lastClMsgSeqNum |-> lastClMsgSeqNum.value,
         lastMsgSeqNum   |-> lastMsgSeqNum.value ], lastMsgSeqNum.rest)

ZeroLogonRejectMessage ==
    [ exchangeId      |-> [i \in 1 .. 8 |-> 0],
      logonRejectCode |-> [i \in 1 .. 1 |-> 0],
      lastClMsgSeqNum |-> [i \in 1 .. 4 |-> 0],
      lastMsgSeqNum   |-> [i \in 1 .. 4 |-> 0] ]

(* Logon Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonRejectMessage ==
    { ZeroLogonRejectMessage }
        \cup { [ZeroLogonRejectMessage EXCEPT !.exchangeId = one] : one \in Sample(8) }
        \cup { [ZeroLogonRejectMessage EXCEPT !.logonRejectCode = one] : one \in Sample(1) }
        \cup { [ZeroLogonRejectMessage EXCEPT !.lastClMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroLogonRejectMessage EXCEPT !.lastMsgSeqNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Logout Message: 1 bytes                                                 *)
(***************************************************************************)

LogoutMessage ==
    [ logOutReasonCode : Sample(1) ]

EncodeLogoutMessage(message) ==
    message.logOutReasonCode

DecodeLogoutMessage(bytes) ==
    LET logOutReasonCode == ReadBytes(bytes, 1) IN IF ~logOutReasonCode.ok THEN Fail ELSE
    Ok([ logOutReasonCode |-> logOutReasonCode.value ], logOutReasonCode.rest)

ZeroLogoutMessage ==
    [ logOutReasonCode |-> [i \in 1 .. 1 |-> 0] ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.logOutReasonCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Technical Reject Message: 17 bytes                                      *)
(***************************************************************************)

TechnicalRejectMessage ==
    [ oegOutToMemberOptional              : Sample(8),
      rejectedClientMessageSequenceNumber : Sample(4),
      rejectedMessage                     : Sample(1),
      errorCode                           : Sample(2),
      rejectedMessageId                   : Sample(2) ]

EncodeTechnicalRejectMessage(message) ==
    message.oegOutToMemberOptional
        \o message.rejectedClientMessageSequenceNumber
        \o message.rejectedMessage
        \o message.errorCode
        \o message.rejectedMessageId

DecodeTechnicalRejectMessage(bytes) ==
    LET oegOutToMemberOptional == ReadBytes(bytes, 8) IN IF ~oegOutToMemberOptional.ok THEN Fail ELSE
    LET rejectedClientMessageSequenceNumber == ReadBytes(oegOutToMemberOptional.rest, 4) IN IF ~rejectedClientMessageSequenceNumber.ok THEN Fail ELSE
    LET rejectedMessage == ReadBytes(rejectedClientMessageSequenceNumber.rest, 1) IN IF ~rejectedMessage.ok THEN Fail ELSE
    LET errorCode == ReadBytes(rejectedMessage.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET rejectedMessageId == ReadBytes(errorCode.rest, 2) IN IF ~rejectedMessageId.ok THEN Fail ELSE
    Ok([ oegOutToMemberOptional              |-> oegOutToMemberOptional.value,
         rejectedClientMessageSequenceNumber |-> rejectedClientMessageSequenceNumber.value,
         rejectedMessage                     |-> rejectedMessage.value,
         errorCode                           |-> errorCode.value,
         rejectedMessageId                   |-> rejectedMessageId.value ], rejectedMessageId.rest)

ZeroTechnicalRejectMessage ==
    [ oegOutToMemberOptional              |-> [i \in 1 .. 8 |-> 0],
      rejectedClientMessageSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      rejectedMessage                     |-> [i \in 1 .. 1 |-> 0],
      errorCode                           |-> [i \in 1 .. 2 |-> 0],
      rejectedMessageId                   |-> [i \in 1 .. 2 |-> 0] ]

(* Technical Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedTechnicalRejectMessage ==
    { ZeroTechnicalRejectMessage }
        \cup { [ZeroTechnicalRejectMessage EXCEPT !.oegOutToMemberOptional = one] : one \in Sample(8) }
        \cup { [ZeroTechnicalRejectMessage EXCEPT !.rejectedClientMessageSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroTechnicalRejectMessage EXCEPT !.rejectedMessage = one] : one \in Sample(1) }
        \cup { [ZeroTechnicalRejectMessage EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroTechnicalRejectMessage EXCEPT !.rejectedMessageId = one] : one \in Sample(2) }

(***************************************************************************)
(* Not Used Groups: 2 bytes                                                *)
(***************************************************************************)

NotUsedGroups6 ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeNotUsedGroups6(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeNotUsedGroups6(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroNotUsedGroups6 ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedNotUsedGroups6 ==
    { ZeroNotUsedGroups6 }
        \cup { [ZeroNotUsedGroups6 EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroNotUsedGroups6 EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* Declaration Entry Message: 200 bytes                                    *)
(***************************************************************************)

DeclarationEntryMessage ==
    [ clMsgSeqNum                        : Sample(4),
      firmId                             : Sample(8),
      sendingTime                        : Sample(8),
      clientOrderId                      : Sample(8),
      operationType                      : Sample(1),
      symbolIndex                        : Sample(4),
      emm                                : Sample(1),
      enteringCounterparty               : Sample(8),
      side                               : Sample(1),
      quantityOptional                   : Sample(8),
      priceOptional                      : Sample(8),
      executionWithinFirmShortCode       : Sample(4),
      clientIdentificationShortcode      : Sample(4),
      miCofSecondaryListing              : Sample(4),
      centralisationDate                 : Sample(10),
      clearingFirmId                     : Sample(8),
      accountType                        : Sample(1),
      accountTypeCross                   : Sample(1),
      tradingCapacity                    : Sample(1),
      tradingCapacityCross               : Sample(1),
      settlementPeriod                   : Sample(1),
      settlementFlag                     : Sample(1),
      guaranteeFlag                      : Sample(1),
      mifidIndicators                    : Sample(1),
      transactionPriceType               : Sample(1),
      principalCode                      : Sample(8),
      principalCodeCross                 : Sample(8),
      startTimeVwap                      : Sample(4),
      endTimeVwap                        : Sample(4),
      grossTradeAmount                   : Sample(8),
      accountNumber                      : Sample(12),
      accountNumberCross                 : Sample(12),
      freeText                           : Sample(18),
      freeTextCross                      : Sample(18),
      investmentDecisionWFirmShortCode   : Sample(4),
      clientIdentificationShortCodeCross : Sample(4),
      notUsedGroups                      : NotUsedGroups6 ]

EncodeDeclarationEntryMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.clientOrderId
        \o message.operationType
        \o message.symbolIndex
        \o message.emm
        \o message.enteringCounterparty
        \o message.side
        \o message.quantityOptional
        \o message.priceOptional
        \o message.executionWithinFirmShortCode
        \o message.clientIdentificationShortcode
        \o message.miCofSecondaryListing
        \o message.centralisationDate
        \o message.clearingFirmId
        \o message.accountType
        \o message.accountTypeCross
        \o message.tradingCapacity
        \o message.tradingCapacityCross
        \o message.settlementPeriod
        \o message.settlementFlag
        \o message.guaranteeFlag
        \o message.mifidIndicators
        \o message.transactionPriceType
        \o message.principalCode
        \o message.principalCodeCross
        \o message.startTimeVwap
        \o message.endTimeVwap
        \o message.grossTradeAmount
        \o message.accountNumber
        \o message.accountNumberCross
        \o message.freeText
        \o message.freeTextCross
        \o message.investmentDecisionWFirmShortCode
        \o message.clientIdentificationShortCodeCross
        \o EncodeNotUsedGroups6(message.notUsedGroups)

DecodeDeclarationEntryMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(sendingTime.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET operationType == ReadBytes(clientOrderId.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(operationType.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET enteringCounterparty == ReadBytes(emm.rest, 8) IN IF ~enteringCounterparty.ok THEN Fail ELSE
    LET side == ReadBytes(enteringCounterparty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantityOptional == ReadBytes(side.rest, 8) IN IF ~quantityOptional.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(quantityOptional.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET executionWithinFirmShortCode == ReadBytes(priceOptional.rest, 4) IN IF ~executionWithinFirmShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortcode == ReadBytes(executionWithinFirmShortCode.rest, 4) IN IF ~clientIdentificationShortcode.ok THEN Fail ELSE
    LET miCofSecondaryListing == ReadBytes(clientIdentificationShortcode.rest, 4) IN IF ~miCofSecondaryListing.ok THEN Fail ELSE
    LET centralisationDate == ReadBytes(miCofSecondaryListing.rest, 10) IN IF ~centralisationDate.ok THEN Fail ELSE
    LET clearingFirmId == ReadBytes(centralisationDate.rest, 8) IN IF ~clearingFirmId.ok THEN Fail ELSE
    LET accountType == ReadBytes(clearingFirmId.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET accountTypeCross == ReadBytes(accountType.rest, 1) IN IF ~accountTypeCross.ok THEN Fail ELSE
    LET tradingCapacity == ReadBytes(accountTypeCross.rest, 1) IN IF ~tradingCapacity.ok THEN Fail ELSE
    LET tradingCapacityCross == ReadBytes(tradingCapacity.rest, 1) IN IF ~tradingCapacityCross.ok THEN Fail ELSE
    LET settlementPeriod == ReadBytes(tradingCapacityCross.rest, 1) IN IF ~settlementPeriod.ok THEN Fail ELSE
    LET settlementFlag == ReadBytes(settlementPeriod.rest, 1) IN IF ~settlementFlag.ok THEN Fail ELSE
    LET guaranteeFlag == ReadBytes(settlementFlag.rest, 1) IN IF ~guaranteeFlag.ok THEN Fail ELSE
    LET mifidIndicators == ReadBytes(guaranteeFlag.rest, 1) IN IF ~mifidIndicators.ok THEN Fail ELSE
    LET transactionPriceType == ReadBytes(mifidIndicators.rest, 1) IN IF ~transactionPriceType.ok THEN Fail ELSE
    LET principalCode == ReadBytes(transactionPriceType.rest, 8) IN IF ~principalCode.ok THEN Fail ELSE
    LET principalCodeCross == ReadBytes(principalCode.rest, 8) IN IF ~principalCodeCross.ok THEN Fail ELSE
    LET startTimeVwap == ReadBytes(principalCodeCross.rest, 4) IN IF ~startTimeVwap.ok THEN Fail ELSE
    LET endTimeVwap == ReadBytes(startTimeVwap.rest, 4) IN IF ~endTimeVwap.ok THEN Fail ELSE
    LET grossTradeAmount == ReadBytes(endTimeVwap.rest, 8) IN IF ~grossTradeAmount.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(grossTradeAmount.rest, 12) IN IF ~accountNumber.ok THEN Fail ELSE
    LET accountNumberCross == ReadBytes(accountNumber.rest, 12) IN IF ~accountNumberCross.ok THEN Fail ELSE
    LET freeText == ReadBytes(accountNumberCross.rest, 18) IN IF ~freeText.ok THEN Fail ELSE
    LET freeTextCross == ReadBytes(freeText.rest, 18) IN IF ~freeTextCross.ok THEN Fail ELSE
    LET investmentDecisionWFirmShortCode == ReadBytes(freeTextCross.rest, 4) IN IF ~investmentDecisionWFirmShortCode.ok THEN Fail ELSE
    LET clientIdentificationShortCodeCross == ReadBytes(investmentDecisionWFirmShortCode.rest, 4) IN IF ~clientIdentificationShortCodeCross.ok THEN Fail ELSE
    LET notUsedGroups == DecodeNotUsedGroups6(clientIdentificationShortCodeCross.rest) IN IF ~notUsedGroups.ok THEN Fail ELSE
    Ok([ clMsgSeqNum                        |-> clMsgSeqNum.value,
         firmId                             |-> firmId.value,
         sendingTime                        |-> sendingTime.value,
         clientOrderId                      |-> clientOrderId.value,
         operationType                      |-> operationType.value,
         symbolIndex                        |-> symbolIndex.value,
         emm                                |-> emm.value,
         enteringCounterparty               |-> enteringCounterparty.value,
         side                               |-> side.value,
         quantityOptional                   |-> quantityOptional.value,
         priceOptional                      |-> priceOptional.value,
         executionWithinFirmShortCode       |-> executionWithinFirmShortCode.value,
         clientIdentificationShortcode      |-> clientIdentificationShortcode.value,
         miCofSecondaryListing              |-> miCofSecondaryListing.value,
         centralisationDate                 |-> centralisationDate.value,
         clearingFirmId                     |-> clearingFirmId.value,
         accountType                        |-> accountType.value,
         accountTypeCross                   |-> accountTypeCross.value,
         tradingCapacity                    |-> tradingCapacity.value,
         tradingCapacityCross               |-> tradingCapacityCross.value,
         settlementPeriod                   |-> settlementPeriod.value,
         settlementFlag                     |-> settlementFlag.value,
         guaranteeFlag                      |-> guaranteeFlag.value,
         mifidIndicators                    |-> mifidIndicators.value,
         transactionPriceType               |-> transactionPriceType.value,
         principalCode                      |-> principalCode.value,
         principalCodeCross                 |-> principalCodeCross.value,
         startTimeVwap                      |-> startTimeVwap.value,
         endTimeVwap                        |-> endTimeVwap.value,
         grossTradeAmount                   |-> grossTradeAmount.value,
         accountNumber                      |-> accountNumber.value,
         accountNumberCross                 |-> accountNumberCross.value,
         freeText                           |-> freeText.value,
         freeTextCross                      |-> freeTextCross.value,
         investmentDecisionWFirmShortCode   |-> investmentDecisionWFirmShortCode.value,
         clientIdentificationShortCodeCross |-> clientIdentificationShortCodeCross.value,
         notUsedGroups                      |-> notUsedGroups.value ], notUsedGroups.rest)

ZeroDeclarationEntryMessage ==
    [ clMsgSeqNum                        |-> [i \in 1 .. 4 |-> 0],
      firmId                             |-> [i \in 1 .. 8 |-> 0],
      sendingTime                        |-> [i \in 1 .. 8 |-> 0],
      clientOrderId                      |-> [i \in 1 .. 8 |-> 0],
      operationType                      |-> [i \in 1 .. 1 |-> 0],
      symbolIndex                        |-> [i \in 1 .. 4 |-> 0],
      emm                                |-> [i \in 1 .. 1 |-> 0],
      enteringCounterparty               |-> [i \in 1 .. 8 |-> 0],
      side                               |-> [i \in 1 .. 1 |-> 0],
      quantityOptional                   |-> [i \in 1 .. 8 |-> 0],
      priceOptional                      |-> [i \in 1 .. 8 |-> 0],
      executionWithinFirmShortCode       |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortcode      |-> [i \in 1 .. 4 |-> 0],
      miCofSecondaryListing              |-> [i \in 1 .. 4 |-> 0],
      centralisationDate                 |-> [i \in 1 .. 10 |-> 0],
      clearingFirmId                     |-> [i \in 1 .. 8 |-> 0],
      accountType                        |-> [i \in 1 .. 1 |-> 0],
      accountTypeCross                   |-> [i \in 1 .. 1 |-> 0],
      tradingCapacity                    |-> [i \in 1 .. 1 |-> 0],
      tradingCapacityCross               |-> [i \in 1 .. 1 |-> 0],
      settlementPeriod                   |-> [i \in 1 .. 1 |-> 0],
      settlementFlag                     |-> [i \in 1 .. 1 |-> 0],
      guaranteeFlag                      |-> [i \in 1 .. 1 |-> 0],
      mifidIndicators                    |-> [i \in 1 .. 1 |-> 0],
      transactionPriceType               |-> [i \in 1 .. 1 |-> 0],
      principalCode                      |-> [i \in 1 .. 8 |-> 0],
      principalCodeCross                 |-> [i \in 1 .. 8 |-> 0],
      startTimeVwap                      |-> [i \in 1 .. 4 |-> 0],
      endTimeVwap                        |-> [i \in 1 .. 4 |-> 0],
      grossTradeAmount                   |-> [i \in 1 .. 8 |-> 0],
      accountNumber                      |-> [i \in 1 .. 12 |-> 0],
      accountNumberCross                 |-> [i \in 1 .. 12 |-> 0],
      freeText                           |-> [i \in 1 .. 18 |-> 0],
      freeTextCross                      |-> [i \in 1 .. 18 |-> 0],
      investmentDecisionWFirmShortCode   |-> [i \in 1 .. 4 |-> 0],
      clientIdentificationShortCodeCross |-> [i \in 1 .. 4 |-> 0],
      notUsedGroups                      |-> ZeroNotUsedGroups6 ]

(* Declaration Entry Message at zero, then each field in turn at the values it is checked at *)
CheckedDeclarationEntryMessage ==
    { ZeroDeclarationEntryMessage }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.operationType = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.enteringCounterparty = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.quantityOptional = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.executionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.clientIdentificationShortcode = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.miCofSecondaryListing = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.centralisationDate = one] : one \in Sample(10) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.clearingFirmId = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.accountTypeCross = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.tradingCapacity = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.tradingCapacityCross = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.settlementPeriod = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.settlementFlag = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.guaranteeFlag = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.mifidIndicators = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.transactionPriceType = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.principalCode = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.principalCodeCross = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.startTimeVwap = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.endTimeVwap = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.grossTradeAmount = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.accountNumber = one] : one \in Sample(12) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.accountNumberCross = one] : one \in Sample(12) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.freeText = one] : one \in Sample(18) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.freeTextCross = one] : one \in Sample(18) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.investmentDecisionWFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.clientIdentificationShortCodeCross = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryMessage EXCEPT !.notUsedGroups = one] : one \in CheckedNotUsedGroups6 }

(***************************************************************************)
(* Not Used Groups: 2 bytes                                                *)
(***************************************************************************)

NotUsedGroups7 ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeNotUsedGroups7(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeNotUsedGroups7(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroNotUsedGroups7 ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedNotUsedGroups7 ==
    { ZeroNotUsedGroups7 }
        \cup { [ZeroNotUsedGroups7 EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroNotUsedGroups7 EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* Declaration Entry Ack Message: 42 bytes                                 *)
(***************************************************************************)

DeclarationEntryAckMessage ==
    [ msgSeqNum             : Sample(4),
      firmId                : Sample(8),
      declarationIdOptional : Sample(8),
      clientOrderId         : Sample(8),
      symbolIndex           : Sample(4),
      emm                   : Sample(1),
      miCofSecondaryListing : Sample(4),
      operationType         : Sample(1),
      preMatchingType       : Sample(1),
      waiverIndicator       : Sample(1),
      notUsedGroups         : NotUsedGroups7 ]

EncodeDeclarationEntryAckMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.declarationIdOptional
        \o message.clientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.miCofSecondaryListing
        \o message.operationType
        \o message.preMatchingType
        \o message.waiverIndicator
        \o EncodeNotUsedGroups7(message.notUsedGroups)

DecodeDeclarationEntryAckMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET declarationIdOptional == ReadBytes(firmId.rest, 8) IN IF ~declarationIdOptional.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(declarationIdOptional.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET miCofSecondaryListing == ReadBytes(emm.rest, 4) IN IF ~miCofSecondaryListing.ok THEN Fail ELSE
    LET operationType == ReadBytes(miCofSecondaryListing.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    LET preMatchingType == ReadBytes(operationType.rest, 1) IN IF ~preMatchingType.ok THEN Fail ELSE
    LET waiverIndicator == ReadBytes(preMatchingType.rest, 1) IN IF ~waiverIndicator.ok THEN Fail ELSE
    LET notUsedGroups == DecodeNotUsedGroups7(waiverIndicator.rest) IN IF ~notUsedGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum             |-> msgSeqNum.value,
         firmId                |-> firmId.value,
         declarationIdOptional |-> declarationIdOptional.value,
         clientOrderId         |-> clientOrderId.value,
         symbolIndex           |-> symbolIndex.value,
         emm                   |-> emm.value,
         miCofSecondaryListing |-> miCofSecondaryListing.value,
         operationType         |-> operationType.value,
         preMatchingType       |-> preMatchingType.value,
         waiverIndicator       |-> waiverIndicator.value,
         notUsedGroups         |-> notUsedGroups.value ], notUsedGroups.rest)

ZeroDeclarationEntryAckMessage ==
    [ msgSeqNum             |-> [i \in 1 .. 4 |-> 0],
      firmId                |-> [i \in 1 .. 8 |-> 0],
      declarationIdOptional |-> [i \in 1 .. 8 |-> 0],
      clientOrderId         |-> [i \in 1 .. 8 |-> 0],
      symbolIndex           |-> [i \in 1 .. 4 |-> 0],
      emm                   |-> [i \in 1 .. 1 |-> 0],
      miCofSecondaryListing |-> [i \in 1 .. 4 |-> 0],
      operationType         |-> [i \in 1 .. 1 |-> 0],
      preMatchingType       |-> [i \in 1 .. 1 |-> 0],
      waiverIndicator       |-> [i \in 1 .. 1 |-> 0],
      notUsedGroups         |-> ZeroNotUsedGroups7 ]

(* Declaration Entry Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedDeclarationEntryAckMessage ==
    { ZeroDeclarationEntryAckMessage }
        \cup { [ZeroDeclarationEntryAckMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryAckMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryAckMessage EXCEPT !.declarationIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryAckMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryAckMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryAckMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryAckMessage EXCEPT !.miCofSecondaryListing = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryAckMessage EXCEPT !.operationType = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryAckMessage EXCEPT !.preMatchingType = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryAckMessage EXCEPT !.waiverIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryAckMessage EXCEPT !.notUsedGroups = one] : one \in CheckedNotUsedGroups7 }

(***************************************************************************)
(* Not Used Groups: 2 bytes                                                *)
(***************************************************************************)

NotUsedGroups8 ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeNotUsedGroups8(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeNotUsedGroups8(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroNotUsedGroups8 ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedNotUsedGroups8 ==
    { ZeroNotUsedGroups8 }
        \cup { [ZeroNotUsedGroups8 EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroNotUsedGroups8 EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* Other Not Used Groups: 2 bytes                                          *)
(***************************************************************************)

OtherNotUsedGroups5 ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeOtherNotUsedGroups5(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeOtherNotUsedGroups5(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroOtherNotUsedGroups5 ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Other Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedOtherNotUsedGroups5 ==
    { ZeroOtherNotUsedGroups5 }
        \cup { [ZeroOtherNotUsedGroups5 EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroOtherNotUsedGroups5 EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* Declaration Notice Message: 222 bytes                                   *)
(***************************************************************************)

DeclarationNoticeMessage ==
    [ msgSeqNum                : Sample(4),
      firmId                   : Sample(8),
      clientOrderIdOptional    : Sample(8),
      declarationId            : Sample(8),
      declarationStatus        : Sample(1),
      operationType            : Sample(1),
      symbolIndex              : Sample(4),
      emm                      : Sample(1),
      enteringCounterparty     : Sample(8),
      sideOptional             : Sample(1),
      quantityOptional         : Sample(8),
      priceOptional            : Sample(8),
      preMatchingType          : Sample(1),
      tradeTimeOptional        : Sample(8),
      miCofSecondaryListing    : Sample(4),
      centralisationDate       : Sample(10),
      clearingFirmId           : Sample(8),
      accountTypeOptional      : Sample(1),
      accountTypeCross         : Sample(1),
      tradingCapacityOptional  : Sample(1),
      tradingCapacityCross     : Sample(1),
      settlementFlagOptional   : Sample(1),
      settlementPeriodOptional : Sample(1),
      guaranteeFlagOptional    : Sample(1),
      transactionPriceType     : Sample(1),
      principalCode            : Sample(8),
      principalCodeCross       : Sample(8),
      startTimeVwap            : Sample(4),
      endTimeVwap              : Sample(4),
      grossTradeAmount         : Sample(8),
      accountNumber            : Sample(12),
      accountNumberCross       : Sample(12),
      freeText                 : Sample(18),
      freeTextCross            : Sample(18),
      waiverIndicator          : Sample(1),
      previousDayIndicator     : Sample(1),
      miscellaneousFeeAmount   : Sample(8),
      ccpid                    : Sample(1),
      tradeUniqueIdentifier    : Sample(16),
      notUsedGroups            : NotUsedGroups8,
      otherNotUsedGroups       : OtherNotUsedGroups5 ]

EncodeDeclarationNoticeMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.clientOrderIdOptional
        \o message.declarationId
        \o message.declarationStatus
        \o message.operationType
        \o message.symbolIndex
        \o message.emm
        \o message.enteringCounterparty
        \o message.sideOptional
        \o message.quantityOptional
        \o message.priceOptional
        \o message.preMatchingType
        \o message.tradeTimeOptional
        \o message.miCofSecondaryListing
        \o message.centralisationDate
        \o message.clearingFirmId
        \o message.accountTypeOptional
        \o message.accountTypeCross
        \o message.tradingCapacityOptional
        \o message.tradingCapacityCross
        \o message.settlementFlagOptional
        \o message.settlementPeriodOptional
        \o message.guaranteeFlagOptional
        \o message.transactionPriceType
        \o message.principalCode
        \o message.principalCodeCross
        \o message.startTimeVwap
        \o message.endTimeVwap
        \o message.grossTradeAmount
        \o message.accountNumber
        \o message.accountNumberCross
        \o message.freeText
        \o message.freeTextCross
        \o message.waiverIndicator
        \o message.previousDayIndicator
        \o message.miscellaneousFeeAmount
        \o message.ccpid
        \o message.tradeUniqueIdentifier
        \o EncodeNotUsedGroups8(message.notUsedGroups)
        \o EncodeOtherNotUsedGroups5(message.otherNotUsedGroups)

DecodeDeclarationNoticeMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET clientOrderIdOptional == ReadBytes(firmId.rest, 8) IN IF ~clientOrderIdOptional.ok THEN Fail ELSE
    LET declarationId == ReadBytes(clientOrderIdOptional.rest, 8) IN IF ~declarationId.ok THEN Fail ELSE
    LET declarationStatus == ReadBytes(declarationId.rest, 1) IN IF ~declarationStatus.ok THEN Fail ELSE
    LET operationType == ReadBytes(declarationStatus.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(operationType.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET enteringCounterparty == ReadBytes(emm.rest, 8) IN IF ~enteringCounterparty.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(enteringCounterparty.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET quantityOptional == ReadBytes(sideOptional.rest, 8) IN IF ~quantityOptional.ok THEN Fail ELSE
    LET priceOptional == ReadBytes(quantityOptional.rest, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET preMatchingType == ReadBytes(priceOptional.rest, 1) IN IF ~preMatchingType.ok THEN Fail ELSE
    LET tradeTimeOptional == ReadBytes(preMatchingType.rest, 8) IN IF ~tradeTimeOptional.ok THEN Fail ELSE
    LET miCofSecondaryListing == ReadBytes(tradeTimeOptional.rest, 4) IN IF ~miCofSecondaryListing.ok THEN Fail ELSE
    LET centralisationDate == ReadBytes(miCofSecondaryListing.rest, 10) IN IF ~centralisationDate.ok THEN Fail ELSE
    LET clearingFirmId == ReadBytes(centralisationDate.rest, 8) IN IF ~clearingFirmId.ok THEN Fail ELSE
    LET accountTypeOptional == ReadBytes(clearingFirmId.rest, 1) IN IF ~accountTypeOptional.ok THEN Fail ELSE
    LET accountTypeCross == ReadBytes(accountTypeOptional.rest, 1) IN IF ~accountTypeCross.ok THEN Fail ELSE
    LET tradingCapacityOptional == ReadBytes(accountTypeCross.rest, 1) IN IF ~tradingCapacityOptional.ok THEN Fail ELSE
    LET tradingCapacityCross == ReadBytes(tradingCapacityOptional.rest, 1) IN IF ~tradingCapacityCross.ok THEN Fail ELSE
    LET settlementFlagOptional == ReadBytes(tradingCapacityCross.rest, 1) IN IF ~settlementFlagOptional.ok THEN Fail ELSE
    LET settlementPeriodOptional == ReadBytes(settlementFlagOptional.rest, 1) IN IF ~settlementPeriodOptional.ok THEN Fail ELSE
    LET guaranteeFlagOptional == ReadBytes(settlementPeriodOptional.rest, 1) IN IF ~guaranteeFlagOptional.ok THEN Fail ELSE
    LET transactionPriceType == ReadBytes(guaranteeFlagOptional.rest, 1) IN IF ~transactionPriceType.ok THEN Fail ELSE
    LET principalCode == ReadBytes(transactionPriceType.rest, 8) IN IF ~principalCode.ok THEN Fail ELSE
    LET principalCodeCross == ReadBytes(principalCode.rest, 8) IN IF ~principalCodeCross.ok THEN Fail ELSE
    LET startTimeVwap == ReadBytes(principalCodeCross.rest, 4) IN IF ~startTimeVwap.ok THEN Fail ELSE
    LET endTimeVwap == ReadBytes(startTimeVwap.rest, 4) IN IF ~endTimeVwap.ok THEN Fail ELSE
    LET grossTradeAmount == ReadBytes(endTimeVwap.rest, 8) IN IF ~grossTradeAmount.ok THEN Fail ELSE
    LET accountNumber == ReadBytes(grossTradeAmount.rest, 12) IN IF ~accountNumber.ok THEN Fail ELSE
    LET accountNumberCross == ReadBytes(accountNumber.rest, 12) IN IF ~accountNumberCross.ok THEN Fail ELSE
    LET freeText == ReadBytes(accountNumberCross.rest, 18) IN IF ~freeText.ok THEN Fail ELSE
    LET freeTextCross == ReadBytes(freeText.rest, 18) IN IF ~freeTextCross.ok THEN Fail ELSE
    LET waiverIndicator == ReadBytes(freeTextCross.rest, 1) IN IF ~waiverIndicator.ok THEN Fail ELSE
    LET previousDayIndicator == ReadBytes(waiverIndicator.rest, 1) IN IF ~previousDayIndicator.ok THEN Fail ELSE
    LET miscellaneousFeeAmount == ReadBytes(previousDayIndicator.rest, 8) IN IF ~miscellaneousFeeAmount.ok THEN Fail ELSE
    LET ccpid == ReadBytes(miscellaneousFeeAmount.rest, 1) IN IF ~ccpid.ok THEN Fail ELSE
    LET tradeUniqueIdentifier == ReadBytes(ccpid.rest, 16) IN IF ~tradeUniqueIdentifier.ok THEN Fail ELSE
    LET notUsedGroups == DecodeNotUsedGroups8(tradeUniqueIdentifier.rest) IN IF ~notUsedGroups.ok THEN Fail ELSE
    LET otherNotUsedGroups == DecodeOtherNotUsedGroups5(notUsedGroups.rest) IN IF ~otherNotUsedGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum                |-> msgSeqNum.value,
         firmId                   |-> firmId.value,
         clientOrderIdOptional    |-> clientOrderIdOptional.value,
         declarationId            |-> declarationId.value,
         declarationStatus        |-> declarationStatus.value,
         operationType            |-> operationType.value,
         symbolIndex              |-> symbolIndex.value,
         emm                      |-> emm.value,
         enteringCounterparty     |-> enteringCounterparty.value,
         sideOptional             |-> sideOptional.value,
         quantityOptional         |-> quantityOptional.value,
         priceOptional            |-> priceOptional.value,
         preMatchingType          |-> preMatchingType.value,
         tradeTimeOptional        |-> tradeTimeOptional.value,
         miCofSecondaryListing    |-> miCofSecondaryListing.value,
         centralisationDate       |-> centralisationDate.value,
         clearingFirmId           |-> clearingFirmId.value,
         accountTypeOptional      |-> accountTypeOptional.value,
         accountTypeCross         |-> accountTypeCross.value,
         tradingCapacityOptional  |-> tradingCapacityOptional.value,
         tradingCapacityCross     |-> tradingCapacityCross.value,
         settlementFlagOptional   |-> settlementFlagOptional.value,
         settlementPeriodOptional |-> settlementPeriodOptional.value,
         guaranteeFlagOptional    |-> guaranteeFlagOptional.value,
         transactionPriceType     |-> transactionPriceType.value,
         principalCode            |-> principalCode.value,
         principalCodeCross       |-> principalCodeCross.value,
         startTimeVwap            |-> startTimeVwap.value,
         endTimeVwap              |-> endTimeVwap.value,
         grossTradeAmount         |-> grossTradeAmount.value,
         accountNumber            |-> accountNumber.value,
         accountNumberCross       |-> accountNumberCross.value,
         freeText                 |-> freeText.value,
         freeTextCross            |-> freeTextCross.value,
         waiverIndicator          |-> waiverIndicator.value,
         previousDayIndicator     |-> previousDayIndicator.value,
         miscellaneousFeeAmount   |-> miscellaneousFeeAmount.value,
         ccpid                    |-> ccpid.value,
         tradeUniqueIdentifier    |-> tradeUniqueIdentifier.value,
         notUsedGroups            |-> notUsedGroups.value,
         otherNotUsedGroups       |-> otherNotUsedGroups.value ], otherNotUsedGroups.rest)

ZeroDeclarationNoticeMessage ==
    [ msgSeqNum                |-> [i \in 1 .. 4 |-> 0],
      firmId                   |-> [i \in 1 .. 8 |-> 0],
      clientOrderIdOptional    |-> [i \in 1 .. 8 |-> 0],
      declarationId            |-> [i \in 1 .. 8 |-> 0],
      declarationStatus        |-> [i \in 1 .. 1 |-> 0],
      operationType            |-> [i \in 1 .. 1 |-> 0],
      symbolIndex              |-> [i \in 1 .. 4 |-> 0],
      emm                      |-> [i \in 1 .. 1 |-> 0],
      enteringCounterparty     |-> [i \in 1 .. 8 |-> 0],
      sideOptional             |-> [i \in 1 .. 1 |-> 0],
      quantityOptional         |-> [i \in 1 .. 8 |-> 0],
      priceOptional            |-> [i \in 1 .. 8 |-> 0],
      preMatchingType          |-> [i \in 1 .. 1 |-> 0],
      tradeTimeOptional        |-> [i \in 1 .. 8 |-> 0],
      miCofSecondaryListing    |-> [i \in 1 .. 4 |-> 0],
      centralisationDate       |-> [i \in 1 .. 10 |-> 0],
      clearingFirmId           |-> [i \in 1 .. 8 |-> 0],
      accountTypeOptional      |-> [i \in 1 .. 1 |-> 0],
      accountTypeCross         |-> [i \in 1 .. 1 |-> 0],
      tradingCapacityOptional  |-> [i \in 1 .. 1 |-> 0],
      tradingCapacityCross     |-> [i \in 1 .. 1 |-> 0],
      settlementFlagOptional   |-> [i \in 1 .. 1 |-> 0],
      settlementPeriodOptional |-> [i \in 1 .. 1 |-> 0],
      guaranteeFlagOptional    |-> [i \in 1 .. 1 |-> 0],
      transactionPriceType     |-> [i \in 1 .. 1 |-> 0],
      principalCode            |-> [i \in 1 .. 8 |-> 0],
      principalCodeCross       |-> [i \in 1 .. 8 |-> 0],
      startTimeVwap            |-> [i \in 1 .. 4 |-> 0],
      endTimeVwap              |-> [i \in 1 .. 4 |-> 0],
      grossTradeAmount         |-> [i \in 1 .. 8 |-> 0],
      accountNumber            |-> [i \in 1 .. 12 |-> 0],
      accountNumberCross       |-> [i \in 1 .. 12 |-> 0],
      freeText                 |-> [i \in 1 .. 18 |-> 0],
      freeTextCross            |-> [i \in 1 .. 18 |-> 0],
      waiverIndicator          |-> [i \in 1 .. 1 |-> 0],
      previousDayIndicator     |-> [i \in 1 .. 1 |-> 0],
      miscellaneousFeeAmount   |-> [i \in 1 .. 8 |-> 0],
      ccpid                    |-> [i \in 1 .. 1 |-> 0],
      tradeUniqueIdentifier    |-> [i \in 1 .. 16 |-> 0],
      notUsedGroups            |-> ZeroNotUsedGroups8,
      otherNotUsedGroups       |-> ZeroOtherNotUsedGroups5 ]

(* Declaration Notice Message at zero, then each field in turn at the values it is checked at *)
CheckedDeclarationNoticeMessage ==
    { ZeroDeclarationNoticeMessage }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.clientOrderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.declarationId = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.declarationStatus = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.operationType = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.enteringCounterparty = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.quantityOptional = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.preMatchingType = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.tradeTimeOptional = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.miCofSecondaryListing = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.centralisationDate = one] : one \in Sample(10) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.clearingFirmId = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.accountTypeOptional = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.accountTypeCross = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.tradingCapacityOptional = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.tradingCapacityCross = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.settlementFlagOptional = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.settlementPeriodOptional = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.guaranteeFlagOptional = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.transactionPriceType = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.principalCode = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.principalCodeCross = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.startTimeVwap = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.endTimeVwap = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.grossTradeAmount = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.accountNumber = one] : one \in Sample(12) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.accountNumberCross = one] : one \in Sample(12) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.freeText = one] : one \in Sample(18) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.freeTextCross = one] : one \in Sample(18) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.waiverIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.previousDayIndicator = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.miscellaneousFeeAmount = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.ccpid = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.tradeUniqueIdentifier = one] : one \in Sample(16) }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.notUsedGroups = one] : one \in CheckedNotUsedGroups8 }
        \cup { [ZeroDeclarationNoticeMessage EXCEPT !.otherNotUsedGroups = one] : one \in CheckedOtherNotUsedGroups5 }

(***************************************************************************)
(* Declaration Cancel And Refusal Message: 58 bytes                        *)
(***************************************************************************)

DeclarationCancelAndRefusalMessage ==
    [ clMsgSeqNum           : Sample(4),
      firmId                : Sample(8),
      sendingTime           : Sample(8),
      clientOrderId         : Sample(8),
      symbolIndex           : Sample(4),
      emm                   : Sample(1),
      declarationId         : Sample(8),
      actionType            : Sample(1),
      tradeUniqueIdentifier : Sample(16) ]

EncodeDeclarationCancelAndRefusalMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.clientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.declarationId
        \o message.actionType
        \o message.tradeUniqueIdentifier

DecodeDeclarationCancelAndRefusalMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(sendingTime.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET declarationId == ReadBytes(emm.rest, 8) IN IF ~declarationId.ok THEN Fail ELSE
    LET actionType == ReadBytes(declarationId.rest, 1) IN IF ~actionType.ok THEN Fail ELSE
    LET tradeUniqueIdentifier == ReadBytes(actionType.rest, 16) IN IF ~tradeUniqueIdentifier.ok THEN Fail ELSE
    Ok([ clMsgSeqNum           |-> clMsgSeqNum.value,
         firmId                |-> firmId.value,
         sendingTime           |-> sendingTime.value,
         clientOrderId         |-> clientOrderId.value,
         symbolIndex           |-> symbolIndex.value,
         emm                   |-> emm.value,
         declarationId         |-> declarationId.value,
         actionType            |-> actionType.value,
         tradeUniqueIdentifier |-> tradeUniqueIdentifier.value ], tradeUniqueIdentifier.rest)

ZeroDeclarationCancelAndRefusalMessage ==
    [ clMsgSeqNum           |-> [i \in 1 .. 4 |-> 0],
      firmId                |-> [i \in 1 .. 8 |-> 0],
      sendingTime           |-> [i \in 1 .. 8 |-> 0],
      clientOrderId         |-> [i \in 1 .. 8 |-> 0],
      symbolIndex           |-> [i \in 1 .. 4 |-> 0],
      emm                   |-> [i \in 1 .. 1 |-> 0],
      declarationId         |-> [i \in 1 .. 8 |-> 0],
      actionType            |-> [i \in 1 .. 1 |-> 0],
      tradeUniqueIdentifier |-> [i \in 1 .. 16 |-> 0] ]

(* Declaration Cancel And Refusal Message at zero, then each field in turn at the values it is checked at *)
CheckedDeclarationCancelAndRefusalMessage ==
    { ZeroDeclarationCancelAndRefusalMessage }
        \cup { [ZeroDeclarationCancelAndRefusalMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationCancelAndRefusalMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationCancelAndRefusalMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationCancelAndRefusalMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationCancelAndRefusalMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationCancelAndRefusalMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationCancelAndRefusalMessage EXCEPT !.declarationId = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationCancelAndRefusalMessage EXCEPT !.actionType = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationCancelAndRefusalMessage EXCEPT !.tradeUniqueIdentifier = one] : one \in Sample(16) }

(***************************************************************************)
(* Fund Price Input Message: 42 bytes                                      *)
(***************************************************************************)

FundPriceInputMessage ==
    [ clMsgSeqNum     : Sample(4),
      firmId          : Sample(8),
      sendingTime     : Sample(8),
      clientOrderId   : Sample(8),
      symbolIndex     : Sample(4),
      emm             : Sample(1),
      price           : Sample(8),
      bypassIndicator : Sample(1) ]

EncodeFundPriceInputMessage(message) ==
    message.clMsgSeqNum
        \o message.firmId
        \o message.sendingTime
        \o message.clientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.price
        \o message.bypassIndicator

DecodeFundPriceInputMessage(bytes) ==
    LET clMsgSeqNum == ReadBytes(bytes, 4) IN IF ~clMsgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(clMsgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET sendingTime == ReadBytes(firmId.rest, 8) IN IF ~sendingTime.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(sendingTime.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET price == ReadBytes(emm.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET bypassIndicator == ReadBytes(price.rest, 1) IN IF ~bypassIndicator.ok THEN Fail ELSE
    Ok([ clMsgSeqNum     |-> clMsgSeqNum.value,
         firmId          |-> firmId.value,
         sendingTime     |-> sendingTime.value,
         clientOrderId   |-> clientOrderId.value,
         symbolIndex     |-> symbolIndex.value,
         emm             |-> emm.value,
         price           |-> price.value,
         bypassIndicator |-> bypassIndicator.value ], bypassIndicator.rest)

ZeroFundPriceInputMessage ==
    [ clMsgSeqNum     |-> [i \in 1 .. 4 |-> 0],
      firmId          |-> [i \in 1 .. 8 |-> 0],
      sendingTime     |-> [i \in 1 .. 8 |-> 0],
      clientOrderId   |-> [i \in 1 .. 8 |-> 0],
      symbolIndex     |-> [i \in 1 .. 4 |-> 0],
      emm             |-> [i \in 1 .. 1 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0],
      bypassIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Fund Price Input Message at zero, then each field in turn at the values it is checked at *)
CheckedFundPriceInputMessage ==
    { ZeroFundPriceInputMessage }
        \cup { [ZeroFundPriceInputMessage EXCEPT !.clMsgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroFundPriceInputMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroFundPriceInputMessage EXCEPT !.sendingTime = one] : one \in Sample(8) }
        \cup { [ZeroFundPriceInputMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroFundPriceInputMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroFundPriceInputMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroFundPriceInputMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroFundPriceInputMessage EXCEPT !.bypassIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Fund Price Input Ack Message: 34 bytes                                  *)
(***************************************************************************)

FundPriceInputAckMessage ==
    [ msgSeqNum       : Sample(4),
      firmId          : Sample(8),
      clientOrderId   : Sample(8),
      symbolIndex     : Sample(4),
      emm             : Sample(1),
      price           : Sample(8),
      bypassIndicator : Sample(1) ]

EncodeFundPriceInputAckMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.clientOrderId
        \o message.symbolIndex
        \o message.emm
        \o message.price
        \o message.bypassIndicator

DecodeFundPriceInputAckMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(firmId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emm == ReadBytes(symbolIndex.rest, 1) IN IF ~emm.ok THEN Fail ELSE
    LET price == ReadBytes(emm.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET bypassIndicator == ReadBytes(price.rest, 1) IN IF ~bypassIndicator.ok THEN Fail ELSE
    Ok([ msgSeqNum       |-> msgSeqNum.value,
         firmId          |-> firmId.value,
         clientOrderId   |-> clientOrderId.value,
         symbolIndex     |-> symbolIndex.value,
         emm             |-> emm.value,
         price           |-> price.value,
         bypassIndicator |-> bypassIndicator.value ], bypassIndicator.rest)

ZeroFundPriceInputAckMessage ==
    [ msgSeqNum       |-> [i \in 1 .. 4 |-> 0],
      firmId          |-> [i \in 1 .. 8 |-> 0],
      clientOrderId   |-> [i \in 1 .. 8 |-> 0],
      symbolIndex     |-> [i \in 1 .. 4 |-> 0],
      emm             |-> [i \in 1 .. 1 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0],
      bypassIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Fund Price Input Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedFundPriceInputAckMessage ==
    { ZeroFundPriceInputAckMessage }
        \cup { [ZeroFundPriceInputAckMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroFundPriceInputAckMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroFundPriceInputAckMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroFundPriceInputAckMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroFundPriceInputAckMessage EXCEPT !.emm = one] : one \in Sample(1) }
        \cup { [ZeroFundPriceInputAckMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroFundPriceInputAckMessage EXCEPT !.bypassIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Not Used Groups: 2 bytes                                                *)
(***************************************************************************)

NotUsedGroups9 ==
    [ blockLengthShort : 0 .. 255,
      numInGroup       : 0 .. 255 ]

EncodeNotUsedGroups9(message) ==
    EncodeUIntBE(message.blockLengthShort, 1)
        \o EncodeUIntBE(message.numInGroup, 1)

DecodeNotUsedGroups9(bytes) ==
    LET blockLengthShort == ReadUIntBE(bytes, 1) IN IF ~blockLengthShort.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLengthShort.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    Ok([ blockLengthShort |-> blockLengthShort.value,
         numInGroup       |-> numInGroup.value ], numInGroup.rest)

ZeroNotUsedGroups9 ==
    [ blockLengthShort |-> 0,
      numInGroup       |-> 0 ]

(* Not Used Groups at zero, then each field in turn at the values it is checked at *)
CheckedNotUsedGroups9 ==
    { ZeroNotUsedGroups9 }
        \cup { [ZeroNotUsedGroups9 EXCEPT !.blockLengthShort = one] : one \in {0, 1, 255} }
        \cup { [ZeroNotUsedGroups9 EXCEPT !.numInGroup = one] : one \in {0, 1, 255} }

(***************************************************************************)
(* Declaration Entry Reject Message: 37 bytes                              *)
(***************************************************************************)

DeclarationEntryRejectMessage ==
    [ msgSeqNum             : Sample(4),
      firmId                : Sample(8),
      clientOrderId         : Sample(8),
      symbolIndex           : Sample(4),
      emmOptional           : Sample(1),
      miCofSecondaryListing : Sample(4),
      operationType         : Sample(1),
      errorCode             : Sample(2),
      rejectedMessage       : Sample(1),
      rejectedMessageId     : Sample(2),
      notUsedGroups         : NotUsedGroups9 ]

EncodeDeclarationEntryRejectMessage(message) ==
    message.msgSeqNum
        \o message.firmId
        \o message.clientOrderId
        \o message.symbolIndex
        \o message.emmOptional
        \o message.miCofSecondaryListing
        \o message.operationType
        \o message.errorCode
        \o message.rejectedMessage
        \o message.rejectedMessageId
        \o EncodeNotUsedGroups9(message.notUsedGroups)

DecodeDeclarationEntryRejectMessage(bytes) ==
    LET msgSeqNum == ReadBytes(bytes, 4) IN IF ~msgSeqNum.ok THEN Fail ELSE
    LET firmId == ReadBytes(msgSeqNum.rest, 8) IN IF ~firmId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(firmId.rest, 8) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET symbolIndex == ReadBytes(clientOrderId.rest, 4) IN IF ~symbolIndex.ok THEN Fail ELSE
    LET emmOptional == ReadBytes(symbolIndex.rest, 1) IN IF ~emmOptional.ok THEN Fail ELSE
    LET miCofSecondaryListing == ReadBytes(emmOptional.rest, 4) IN IF ~miCofSecondaryListing.ok THEN Fail ELSE
    LET operationType == ReadBytes(miCofSecondaryListing.rest, 1) IN IF ~operationType.ok THEN Fail ELSE
    LET errorCode == ReadBytes(operationType.rest, 2) IN IF ~errorCode.ok THEN Fail ELSE
    LET rejectedMessage == ReadBytes(errorCode.rest, 1) IN IF ~rejectedMessage.ok THEN Fail ELSE
    LET rejectedMessageId == ReadBytes(rejectedMessage.rest, 2) IN IF ~rejectedMessageId.ok THEN Fail ELSE
    LET notUsedGroups == DecodeNotUsedGroups9(rejectedMessageId.rest) IN IF ~notUsedGroups.ok THEN Fail ELSE
    Ok([ msgSeqNum             |-> msgSeqNum.value,
         firmId                |-> firmId.value,
         clientOrderId         |-> clientOrderId.value,
         symbolIndex           |-> symbolIndex.value,
         emmOptional           |-> emmOptional.value,
         miCofSecondaryListing |-> miCofSecondaryListing.value,
         operationType         |-> operationType.value,
         errorCode             |-> errorCode.value,
         rejectedMessage       |-> rejectedMessage.value,
         rejectedMessageId     |-> rejectedMessageId.value,
         notUsedGroups         |-> notUsedGroups.value ], notUsedGroups.rest)

ZeroDeclarationEntryRejectMessage ==
    [ msgSeqNum             |-> [i \in 1 .. 4 |-> 0],
      firmId                |-> [i \in 1 .. 8 |-> 0],
      clientOrderId         |-> [i \in 1 .. 8 |-> 0],
      symbolIndex           |-> [i \in 1 .. 4 |-> 0],
      emmOptional           |-> [i \in 1 .. 1 |-> 0],
      miCofSecondaryListing |-> [i \in 1 .. 4 |-> 0],
      operationType         |-> [i \in 1 .. 1 |-> 0],
      errorCode             |-> [i \in 1 .. 2 |-> 0],
      rejectedMessage       |-> [i \in 1 .. 1 |-> 0],
      rejectedMessageId     |-> [i \in 1 .. 2 |-> 0],
      notUsedGroups         |-> ZeroNotUsedGroups9 ]

(* Declaration Entry Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedDeclarationEntryRejectMessage ==
    { ZeroDeclarationEntryRejectMessage }
        \cup { [ZeroDeclarationEntryRejectMessage EXCEPT !.msgSeqNum = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryRejectMessage EXCEPT !.firmId = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(8) }
        \cup { [ZeroDeclarationEntryRejectMessage EXCEPT !.symbolIndex = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryRejectMessage EXCEPT !.emmOptional = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryRejectMessage EXCEPT !.miCofSecondaryListing = one] : one \in Sample(4) }
        \cup { [ZeroDeclarationEntryRejectMessage EXCEPT !.operationType = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryRejectMessage EXCEPT !.errorCode = one] : one \in Sample(2) }
        \cup { [ZeroDeclarationEntryRejectMessage EXCEPT !.rejectedMessage = one] : one \in Sample(1) }
        \cup { [ZeroDeclarationEntryRejectMessage EXCEPT !.rejectedMessageId = one] : one \in Sample(2) }
        \cup { [ZeroDeclarationEntryRejectMessage EXCEPT !.notUsedGroups = one] : one \in CheckedNotUsedGroups9 }

(***************************************************************************)
(* Payload, selected by Template Id                                        *)
(***************************************************************************)

NewOrderMessageCode == 1  \* 0x01
AckMessageCode == 3  \* 0x03
FillMessageCode == 4  \* 0x04
KillMessageCode == 5  \* 0x05
CancelReplaceMessageCode == 6  \* 0x06
RejectMessageCode == 7  \* 0x07
QuotesMessageCode == 8  \* 0x08
QuoteAckMessageCode == 9  \* 0x09
QuoteRequestMessageCode == 10  \* 0x0a
CancelRequestMessageCode == 12  \* 0x0c
MassCancelMessageCode == 13  \* 0x0d
MassCancelAckMessageCode == 14  \* 0x0e
OpenOrderRequestMessageCode == 15  \* 0x0f
OwnershipRequestAckMessageCode == 17  \* 0x11
OwnershipRequestMessageCode == 18  \* 0x12
TradeBustNotificationMessageCode == 19  \* 0x13
CollarBreachConfirmationMessageCode == 20  \* 0x14
PriceInputMessageCode == 28  \* 0x1c
LiquidityProviderCommandMessageCode == 32  \* 0x20
AskForQuoteMessageCode == 33  \* 0x21
RequestForExecutionMessageCode == 34  \* 0x22
RfqNotificationMessageCode == 35  \* 0x23
RfqMatchingStatusMessageCode == 36  \* 0x24
RfqlpMatchingStatusMessageCode == 37  \* 0x25
UserNotificationMessageCode == 39  \* 0x27
MmSignInMessageCode == 47  \* 0x2f
MmSignInAckMessageCode == 48  \* 0x30
InstrumentSynchronizationListMessageCode == 50  \* 0x32
SynchronizationTimeMessageCode == 51  \* 0x33
SecurityDefinitionRequestMessageCode == 60  \* 0x3c
SecurityDefinitionAckMessageCode == 61  \* 0x3d
MmProtectionRequestMessageCode == 62  \* 0x3e
MmProtectionAckMessageCode == 63  \* 0x3f
NewWholesaleOrderMessageCode == 64  \* 0x40
WholesaleOrderAckMessageCode == 65  \* 0x41
RequestForImpliedExecutionMessageCode == 66  \* 0x42
CrossOrderMessageCode == 67  \* 0x43
RfqAuditMessageCode == 72  \* 0x48
WaveForLiquidityMessageCode == 73  \* 0x49
WaveForLiquidityNotificationMessageCode == 74  \* 0x4a
ClearBookMessageCode == 75  \* 0x4b
LogonMessageCode == 100  \* 0x64
LogonAckMessageCode == 101  \* 0x65
LogonRejectMessageCode == 102  \* 0x66
LogoutMessageCode == 103  \* 0x67
HeartbeatMessageCode == 106  \* 0x6a
TestRequestMessageCode == 107  \* 0x6b
TechnicalRejectMessageCode == 108  \* 0x6c
DeclarationEntryMessageCode == 40  \* 0x28
DeclarationEntryAckMessageCode == 41  \* 0x29
DeclarationNoticeMessageCode == 42  \* 0x2a
DeclarationCancelAndRefusalMessageCode == 43  \* 0x2b
FundPriceInputMessageCode == 44  \* 0x2c
FundPriceInputAckMessageCode == 45  \* 0x2d
DeclarationEntryRejectMessageCode == 46  \* 0x2e

Payload ==
    [ tag : {NewOrderMessageCode}, body : NewOrderMessage ]
        \cup [ tag : {AckMessageCode}, body : AckMessage ]
        \cup [ tag : {FillMessageCode}, body : FillMessage ]
        \cup [ tag : {KillMessageCode}, body : KillMessage ]
        \cup [ tag : {CancelReplaceMessageCode}, body : CancelReplaceMessage ]
        \cup [ tag : {RejectMessageCode}, body : RejectMessage ]
        \cup [ tag : {QuotesMessageCode}, body : QuotesMessage ]
        \cup [ tag : {QuoteAckMessageCode}, body : QuoteAckMessage ]
        \cup [ tag : {QuoteRequestMessageCode}, body : QuoteRequestMessage ]
        \cup [ tag : {CancelRequestMessageCode}, body : CancelRequestMessage ]
        \cup [ tag : {MassCancelMessageCode}, body : MassCancelMessage ]
        \cup [ tag : {MassCancelAckMessageCode}, body : MassCancelAckMessage ]
        \cup [ tag : {OpenOrderRequestMessageCode}, body : OpenOrderRequestMessage ]
        \cup [ tag : {OwnershipRequestAckMessageCode}, body : OwnershipRequestAckMessage ]
        \cup [ tag : {OwnershipRequestMessageCode}, body : OwnershipRequestMessage ]
        \cup [ tag : {TradeBustNotificationMessageCode}, body : TradeBustNotificationMessage ]
        \cup [ tag : {CollarBreachConfirmationMessageCode}, body : CollarBreachConfirmationMessage ]
        \cup [ tag : {PriceInputMessageCode}, body : PriceInputMessage ]
        \cup [ tag : {LiquidityProviderCommandMessageCode}, body : LiquidityProviderCommandMessage ]
        \cup [ tag : {AskForQuoteMessageCode}, body : AskForQuoteMessage ]
        \cup [ tag : {RequestForExecutionMessageCode}, body : RequestForExecutionMessage ]
        \cup [ tag : {RfqNotificationMessageCode}, body : RfqNotificationMessage ]
        \cup [ tag : {RfqMatchingStatusMessageCode}, body : RfqMatchingStatusMessage ]
        \cup [ tag : {RfqlpMatchingStatusMessageCode}, body : RfqlpMatchingStatusMessage ]
        \cup [ tag : {UserNotificationMessageCode}, body : UserNotificationMessage ]
        \cup [ tag : {MmSignInMessageCode}, body : MmSignInMessage ]
        \cup [ tag : {MmSignInAckMessageCode}, body : MmSignInAckMessage ]
        \cup [ tag : {InstrumentSynchronizationListMessageCode}, body : InstrumentSynchronizationListMessage ]
        \cup [ tag : {SynchronizationTimeMessageCode}, body : SynchronizationTimeMessage ]
        \cup [ tag : {SecurityDefinitionRequestMessageCode}, body : SecurityDefinitionRequestMessage ]
        \cup [ tag : {SecurityDefinitionAckMessageCode}, body : SecurityDefinitionAckMessage ]
        \cup [ tag : {MmProtectionRequestMessageCode}, body : MmProtectionRequestMessage ]
        \cup [ tag : {MmProtectionAckMessageCode}, body : MmProtectionAckMessage ]
        \cup [ tag : {NewWholesaleOrderMessageCode}, body : NewWholesaleOrderMessage ]
        \cup [ tag : {WholesaleOrderAckMessageCode}, body : WholesaleOrderAckMessage ]
        \cup [ tag : {RequestForImpliedExecutionMessageCode}, body : RequestForImpliedExecutionMessage ]
        \cup [ tag : {CrossOrderMessageCode}, body : CrossOrderMessage ]
        \cup [ tag : {RfqAuditMessageCode}, body : RfqAuditMessage ]
        \cup [ tag : {WaveForLiquidityMessageCode}, body : WaveForLiquidityMessage ]
        \cup [ tag : {WaveForLiquidityNotificationMessageCode}, body : WaveForLiquidityNotificationMessage ]
        \cup [ tag : {ClearBookMessageCode}, body : ClearBookMessage ]
        \cup [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogonAckMessageCode}, body : LogonAckMessage ]
        \cup [ tag : {LogonRejectMessageCode}, body : LogonRejectMessage ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TestRequestMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {TechnicalRejectMessageCode}, body : TechnicalRejectMessage ]
        \cup [ tag : {DeclarationEntryMessageCode}, body : DeclarationEntryMessage ]
        \cup [ tag : {DeclarationEntryAckMessageCode}, body : DeclarationEntryAckMessage ]
        \cup [ tag : {DeclarationNoticeMessageCode}, body : DeclarationNoticeMessage ]
        \cup [ tag : {DeclarationCancelAndRefusalMessageCode}, body : DeclarationCancelAndRefusalMessage ]
        \cup [ tag : {FundPriceInputMessageCode}, body : FundPriceInputMessage ]
        \cup [ tag : {FundPriceInputAckMessageCode}, body : FundPriceInputAckMessage ]
        \cup [ tag : {DeclarationEntryRejectMessageCode}, body : DeclarationEntryRejectMessage ]

EncodePayload(message) ==
    CASE message.tag = NewOrderMessageCode -> EncodeNewOrderMessage(message.body)
      [] message.tag = AckMessageCode -> EncodeAckMessage(message.body)
      [] message.tag = FillMessageCode -> EncodeFillMessage(message.body)
      [] message.tag = KillMessageCode -> EncodeKillMessage(message.body)
      [] message.tag = CancelReplaceMessageCode -> EncodeCancelReplaceMessage(message.body)
      [] message.tag = RejectMessageCode -> EncodeRejectMessage(message.body)
      [] message.tag = QuotesMessageCode -> EncodeQuotesMessage(message.body)
      [] message.tag = QuoteAckMessageCode -> EncodeQuoteAckMessage(message.body)
      [] message.tag = QuoteRequestMessageCode -> EncodeQuoteRequestMessage(message.body)
      [] message.tag = CancelRequestMessageCode -> EncodeCancelRequestMessage(message.body)
      [] message.tag = MassCancelMessageCode -> EncodeMassCancelMessage(message.body)
      [] message.tag = MassCancelAckMessageCode -> EncodeMassCancelAckMessage(message.body)
      [] message.tag = OpenOrderRequestMessageCode -> EncodeOpenOrderRequestMessage(message.body)
      [] message.tag = OwnershipRequestAckMessageCode -> EncodeOwnershipRequestAckMessage(message.body)
      [] message.tag = OwnershipRequestMessageCode -> EncodeOwnershipRequestMessage(message.body)
      [] message.tag = TradeBustNotificationMessageCode -> EncodeTradeBustNotificationMessage(message.body)
      [] message.tag = CollarBreachConfirmationMessageCode -> EncodeCollarBreachConfirmationMessage(message.body)
      [] message.tag = PriceInputMessageCode -> EncodePriceInputMessage(message.body)
      [] message.tag = LiquidityProviderCommandMessageCode -> EncodeLiquidityProviderCommandMessage(message.body)
      [] message.tag = AskForQuoteMessageCode -> EncodeAskForQuoteMessage(message.body)
      [] message.tag = RequestForExecutionMessageCode -> EncodeRequestForExecutionMessage(message.body)
      [] message.tag = RfqNotificationMessageCode -> EncodeRfqNotificationMessage(message.body)
      [] message.tag = RfqMatchingStatusMessageCode -> EncodeRfqMatchingStatusMessage(message.body)
      [] message.tag = RfqlpMatchingStatusMessageCode -> EncodeRfqlpMatchingStatusMessage(message.body)
      [] message.tag = UserNotificationMessageCode -> EncodeUserNotificationMessage(message.body)
      [] message.tag = MmSignInMessageCode -> EncodeMmSignInMessage(message.body)
      [] message.tag = MmSignInAckMessageCode -> EncodeMmSignInAckMessage(message.body)
      [] message.tag = InstrumentSynchronizationListMessageCode -> EncodeInstrumentSynchronizationListMessage(message.body)
      [] message.tag = SynchronizationTimeMessageCode -> EncodeSynchronizationTimeMessage(message.body)
      [] message.tag = SecurityDefinitionRequestMessageCode -> EncodeSecurityDefinitionRequestMessage(message.body)
      [] message.tag = SecurityDefinitionAckMessageCode -> EncodeSecurityDefinitionAckMessage(message.body)
      [] message.tag = MmProtectionRequestMessageCode -> EncodeMmProtectionRequestMessage(message.body)
      [] message.tag = MmProtectionAckMessageCode -> EncodeMmProtectionAckMessage(message.body)
      [] message.tag = NewWholesaleOrderMessageCode -> EncodeNewWholesaleOrderMessage(message.body)
      [] message.tag = WholesaleOrderAckMessageCode -> EncodeWholesaleOrderAckMessage(message.body)
      [] message.tag = RequestForImpliedExecutionMessageCode -> EncodeRequestForImpliedExecutionMessage(message.body)
      [] message.tag = CrossOrderMessageCode -> EncodeCrossOrderMessage(message.body)
      [] message.tag = RfqAuditMessageCode -> EncodeRfqAuditMessage(message.body)
      [] message.tag = WaveForLiquidityMessageCode -> EncodeWaveForLiquidityMessage(message.body)
      [] message.tag = WaveForLiquidityNotificationMessageCode -> EncodeWaveForLiquidityNotificationMessage(message.body)
      [] message.tag = ClearBookMessageCode -> EncodeClearBookMessage(message.body)
      [] message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogonAckMessageCode -> EncodeLogonAckMessage(message.body)
      [] message.tag = LogonRejectMessageCode -> EncodeLogonRejectMessage(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = TestRequestMessageCode -> << >>
      [] message.tag = TechnicalRejectMessageCode -> EncodeTechnicalRejectMessage(message.body)
      [] message.tag = DeclarationEntryMessageCode -> EncodeDeclarationEntryMessage(message.body)
      [] message.tag = DeclarationEntryAckMessageCode -> EncodeDeclarationEntryAckMessage(message.body)
      [] message.tag = DeclarationNoticeMessageCode -> EncodeDeclarationNoticeMessage(message.body)
      [] message.tag = DeclarationCancelAndRefusalMessageCode -> EncodeDeclarationCancelAndRefusalMessage(message.body)
      [] message.tag = FundPriceInputMessageCode -> EncodeFundPriceInputMessage(message.body)
      [] message.tag = FundPriceInputAckMessageCode -> EncodeFundPriceInputAckMessage(message.body)
      [] message.tag = DeclarationEntryRejectMessageCode -> EncodeDeclarationEntryRejectMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = NewOrderMessageCode -> DecodeNewOrderMessage(bytes)
              [] tag = AckMessageCode -> DecodeAckMessage(bytes)
              [] tag = FillMessageCode -> DecodeFillMessage(bytes)
              [] tag = KillMessageCode -> DecodeKillMessage(bytes)
              [] tag = CancelReplaceMessageCode -> DecodeCancelReplaceMessage(bytes)
              [] tag = RejectMessageCode -> DecodeRejectMessage(bytes)
              [] tag = QuotesMessageCode -> DecodeQuotesMessage(bytes)
              [] tag = QuoteAckMessageCode -> DecodeQuoteAckMessage(bytes)
              [] tag = QuoteRequestMessageCode -> DecodeQuoteRequestMessage(bytes)
              [] tag = CancelRequestMessageCode -> DecodeCancelRequestMessage(bytes)
              [] tag = MassCancelMessageCode -> DecodeMassCancelMessage(bytes)
              [] tag = MassCancelAckMessageCode -> DecodeMassCancelAckMessage(bytes)
              [] tag = OpenOrderRequestMessageCode -> DecodeOpenOrderRequestMessage(bytes)
              [] tag = OwnershipRequestAckMessageCode -> DecodeOwnershipRequestAckMessage(bytes)
              [] tag = OwnershipRequestMessageCode -> DecodeOwnershipRequestMessage(bytes)
              [] tag = TradeBustNotificationMessageCode -> DecodeTradeBustNotificationMessage(bytes)
              [] tag = CollarBreachConfirmationMessageCode -> DecodeCollarBreachConfirmationMessage(bytes)
              [] tag = PriceInputMessageCode -> DecodePriceInputMessage(bytes)
              [] tag = LiquidityProviderCommandMessageCode -> DecodeLiquidityProviderCommandMessage(bytes)
              [] tag = AskForQuoteMessageCode -> DecodeAskForQuoteMessage(bytes)
              [] tag = RequestForExecutionMessageCode -> DecodeRequestForExecutionMessage(bytes)
              [] tag = RfqNotificationMessageCode -> DecodeRfqNotificationMessage(bytes)
              [] tag = RfqMatchingStatusMessageCode -> DecodeRfqMatchingStatusMessage(bytes)
              [] tag = RfqlpMatchingStatusMessageCode -> DecodeRfqlpMatchingStatusMessage(bytes)
              [] tag = UserNotificationMessageCode -> DecodeUserNotificationMessage(bytes)
              [] tag = MmSignInMessageCode -> DecodeMmSignInMessage(bytes)
              [] tag = MmSignInAckMessageCode -> DecodeMmSignInAckMessage(bytes)
              [] tag = InstrumentSynchronizationListMessageCode -> DecodeInstrumentSynchronizationListMessage(bytes)
              [] tag = SynchronizationTimeMessageCode -> DecodeSynchronizationTimeMessage(bytes)
              [] tag = SecurityDefinitionRequestMessageCode -> DecodeSecurityDefinitionRequestMessage(bytes)
              [] tag = SecurityDefinitionAckMessageCode -> DecodeSecurityDefinitionAckMessage(bytes)
              [] tag = MmProtectionRequestMessageCode -> DecodeMmProtectionRequestMessage(bytes)
              [] tag = MmProtectionAckMessageCode -> DecodeMmProtectionAckMessage(bytes)
              [] tag = NewWholesaleOrderMessageCode -> DecodeNewWholesaleOrderMessage(bytes)
              [] tag = WholesaleOrderAckMessageCode -> DecodeWholesaleOrderAckMessage(bytes)
              [] tag = RequestForImpliedExecutionMessageCode -> DecodeRequestForImpliedExecutionMessage(bytes)
              [] tag = CrossOrderMessageCode -> DecodeCrossOrderMessage(bytes)
              [] tag = RfqAuditMessageCode -> DecodeRfqAuditMessage(bytes)
              [] tag = WaveForLiquidityMessageCode -> DecodeWaveForLiquidityMessage(bytes)
              [] tag = WaveForLiquidityNotificationMessageCode -> DecodeWaveForLiquidityNotificationMessage(bytes)
              [] tag = ClearBookMessageCode -> DecodeClearBookMessage(bytes)
              [] tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogonAckMessageCode -> DecodeLogonAckMessage(bytes)
              [] tag = LogonRejectMessageCode -> DecodeLogonRejectMessage(bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = TestRequestMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = TechnicalRejectMessageCode -> DecodeTechnicalRejectMessage(bytes)
              [] tag = DeclarationEntryMessageCode -> DecodeDeclarationEntryMessage(bytes)
              [] tag = DeclarationEntryAckMessageCode -> DecodeDeclarationEntryAckMessage(bytes)
              [] tag = DeclarationNoticeMessageCode -> DecodeDeclarationNoticeMessage(bytes)
              [] tag = DeclarationCancelAndRefusalMessageCode -> DecodeDeclarationCancelAndRefusalMessage(bytes)
              [] tag = FundPriceInputMessageCode -> DecodeFundPriceInputMessage(bytes)
              [] tag = FundPriceInputAckMessageCode -> DecodeFundPriceInputAckMessage(bytes)
              [] tag = DeclarationEntryRejectMessageCode -> DecodeDeclarationEntryRejectMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> NewOrderMessageCode, body |-> ZeroNewOrderMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> NewOrderMessageCode, body |-> one] : one \in CheckedNewOrderMessage }
        \cup { [tag |-> AckMessageCode, body |-> one] : one \in CheckedAckMessage }
        \cup { [tag |-> FillMessageCode, body |-> one] : one \in CheckedFillMessage }
        \cup { [tag |-> KillMessageCode, body |-> one] : one \in CheckedKillMessage }
        \cup { [tag |-> CancelReplaceMessageCode, body |-> one] : one \in CheckedCancelReplaceMessage }
        \cup { [tag |-> RejectMessageCode, body |-> one] : one \in CheckedRejectMessage }
        \cup { [tag |-> QuotesMessageCode, body |-> one] : one \in CheckedQuotesMessage }
        \cup { [tag |-> QuoteAckMessageCode, body |-> one] : one \in CheckedQuoteAckMessage }
        \cup { [tag |-> QuoteRequestMessageCode, body |-> one] : one \in CheckedQuoteRequestMessage }
        \cup { [tag |-> CancelRequestMessageCode, body |-> one] : one \in CheckedCancelRequestMessage }
        \cup { [tag |-> MassCancelMessageCode, body |-> one] : one \in CheckedMassCancelMessage }
        \cup { [tag |-> MassCancelAckMessageCode, body |-> one] : one \in CheckedMassCancelAckMessage }
        \cup { [tag |-> OpenOrderRequestMessageCode, body |-> one] : one \in CheckedOpenOrderRequestMessage }
        \cup { [tag |-> OwnershipRequestAckMessageCode, body |-> one] : one \in CheckedOwnershipRequestAckMessage }
        \cup { [tag |-> OwnershipRequestMessageCode, body |-> one] : one \in CheckedOwnershipRequestMessage }
        \cup { [tag |-> TradeBustNotificationMessageCode, body |-> one] : one \in CheckedTradeBustNotificationMessage }
        \cup { [tag |-> CollarBreachConfirmationMessageCode, body |-> one] : one \in CheckedCollarBreachConfirmationMessage }
        \cup { [tag |-> PriceInputMessageCode, body |-> one] : one \in CheckedPriceInputMessage }
        \cup { [tag |-> LiquidityProviderCommandMessageCode, body |-> one] : one \in CheckedLiquidityProviderCommandMessage }
        \cup { [tag |-> AskForQuoteMessageCode, body |-> one] : one \in CheckedAskForQuoteMessage }
        \cup { [tag |-> RequestForExecutionMessageCode, body |-> one] : one \in CheckedRequestForExecutionMessage }
        \cup { [tag |-> RfqNotificationMessageCode, body |-> one] : one \in CheckedRfqNotificationMessage }
        \cup { [tag |-> RfqMatchingStatusMessageCode, body |-> one] : one \in CheckedRfqMatchingStatusMessage }
        \cup { [tag |-> RfqlpMatchingStatusMessageCode, body |-> one] : one \in CheckedRfqlpMatchingStatusMessage }
        \cup { [tag |-> UserNotificationMessageCode, body |-> one] : one \in CheckedUserNotificationMessage }
        \cup { [tag |-> MmSignInMessageCode, body |-> one] : one \in CheckedMmSignInMessage }
        \cup { [tag |-> MmSignInAckMessageCode, body |-> one] : one \in CheckedMmSignInAckMessage }
        \cup { [tag |-> InstrumentSynchronizationListMessageCode, body |-> one] : one \in CheckedInstrumentSynchronizationListMessage }
        \cup { [tag |-> SynchronizationTimeMessageCode, body |-> one] : one \in CheckedSynchronizationTimeMessage }
        \cup { [tag |-> SecurityDefinitionRequestMessageCode, body |-> one] : one \in CheckedSecurityDefinitionRequestMessage }
        \cup { [tag |-> SecurityDefinitionAckMessageCode, body |-> one] : one \in CheckedSecurityDefinitionAckMessage }
        \cup { [tag |-> MmProtectionRequestMessageCode, body |-> one] : one \in CheckedMmProtectionRequestMessage }
        \cup { [tag |-> MmProtectionAckMessageCode, body |-> one] : one \in CheckedMmProtectionAckMessage }
        \cup { [tag |-> NewWholesaleOrderMessageCode, body |-> one] : one \in CheckedNewWholesaleOrderMessage }
        \cup { [tag |-> WholesaleOrderAckMessageCode, body |-> one] : one \in CheckedWholesaleOrderAckMessage }
        \cup { [tag |-> RequestForImpliedExecutionMessageCode, body |-> one] : one \in CheckedRequestForImpliedExecutionMessage }
        \cup { [tag |-> CrossOrderMessageCode, body |-> one] : one \in CheckedCrossOrderMessage }
        \cup { [tag |-> RfqAuditMessageCode, body |-> one] : one \in CheckedRfqAuditMessage }
        \cup { [tag |-> WaveForLiquidityMessageCode, body |-> one] : one \in CheckedWaveForLiquidityMessage }
        \cup { [tag |-> WaveForLiquidityNotificationMessageCode, body |-> one] : one \in CheckedWaveForLiquidityNotificationMessage }
        \cup { [tag |-> ClearBookMessageCode, body |-> one] : one \in CheckedClearBookMessage }
        \cup { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogonAckMessageCode, body |-> one] : one \in CheckedLogonAckMessage }
        \cup { [tag |-> LogonRejectMessageCode, body |-> one] : one \in CheckedLogonRejectMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TestRequestMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> TechnicalRejectMessageCode, body |-> one] : one \in CheckedTechnicalRejectMessage }
        \cup { [tag |-> DeclarationEntryMessageCode, body |-> one] : one \in CheckedDeclarationEntryMessage }
        \cup { [tag |-> DeclarationEntryAckMessageCode, body |-> one] : one \in CheckedDeclarationEntryAckMessage }
        \cup { [tag |-> DeclarationNoticeMessageCode, body |-> one] : one \in CheckedDeclarationNoticeMessage }
        \cup { [tag |-> DeclarationCancelAndRefusalMessageCode, body |-> one] : one \in CheckedDeclarationCancelAndRefusalMessage }
        \cup { [tag |-> FundPriceInputMessageCode, body |-> one] : one \in CheckedFundPriceInputMessage }
        \cup { [tag |-> FundPriceInputAckMessageCode, body |-> one] : one \in CheckedFundPriceInputAckMessage }
        \cup { [tag |-> DeclarationEntryRejectMessageCode, body |-> one] : one \in CheckedDeclarationEntryRejectMessage }

(***************************************************************************)
(* Message, framed by Frame                                                *)
(***************************************************************************)

Message ==
    [ blockLength : Sample(2),
      schemaId    : Sample(2),
      version     : Sample(2),
      payload     : Payload ]

EncodeMessageBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.payload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodePayload(message.payload)

(* Frame counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET payload == DecodePayload(templateId.value, version.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         schemaId    |-> schemaId.value,
         version     |-> version.value,
         payload     |-> payload.value ], payload.rest)

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
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      schemaId    |-> [i \in 1 .. 2 |-> 0],
      version     |-> [i \in 1 .. 2 |-> 0],
      payload     |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroMessage EXCEPT !.version = one] : one \in Sample(2) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> NewOrderMessageCode, body |-> ZeroNewOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AckMessageCode, body |-> ZeroAckMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FillMessageCode, body |-> ZeroFillMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> KillMessageCode, body |-> ZeroKillMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CancelReplaceMessageCode, body |-> ZeroCancelReplaceMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RejectMessageCode, body |-> ZeroRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuotesMessageCode, body |-> ZeroQuotesMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteAckMessageCode, body |-> ZeroQuoteAckMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteRequestMessageCode, body |-> ZeroQuoteRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CancelRequestMessageCode, body |-> ZeroCancelRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MassCancelMessageCode, body |-> ZeroMassCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MassCancelAckMessageCode, body |-> ZeroMassCancelAckMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OpenOrderRequestMessageCode, body |-> ZeroOpenOrderRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OwnershipRequestAckMessageCode, body |-> ZeroOwnershipRequestAckMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OwnershipRequestMessageCode, body |-> ZeroOwnershipRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBustNotificationMessageCode, body |-> ZeroTradeBustNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CollarBreachConfirmationMessageCode, body |-> ZeroCollarBreachConfirmationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> PriceInputMessageCode, body |-> ZeroPriceInputMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LiquidityProviderCommandMessageCode, body |-> ZeroLiquidityProviderCommandMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> AskForQuoteMessageCode, body |-> ZeroAskForQuoteMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RequestForExecutionMessageCode, body |-> ZeroRequestForExecutionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RfqNotificationMessageCode, body |-> ZeroRfqNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RfqMatchingStatusMessageCode, body |-> ZeroRfqMatchingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RfqlpMatchingStatusMessageCode, body |-> ZeroRfqlpMatchingStatusMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> UserNotificationMessageCode, body |-> ZeroUserNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MmSignInMessageCode, body |-> ZeroMmSignInMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MmSignInAckMessageCode, body |-> ZeroMmSignInAckMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> InstrumentSynchronizationListMessageCode, body |-> ZeroInstrumentSynchronizationListMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SynchronizationTimeMessageCode, body |-> ZeroSynchronizationTimeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionRequestMessageCode, body |-> ZeroSecurityDefinitionRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> SecurityDefinitionAckMessageCode, body |-> ZeroSecurityDefinitionAckMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MmProtectionRequestMessageCode, body |-> ZeroMmProtectionRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> MmProtectionAckMessageCode, body |-> ZeroMmProtectionAckMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewWholesaleOrderMessageCode, body |-> ZeroNewWholesaleOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> WholesaleOrderAckMessageCode, body |-> ZeroWholesaleOrderAckMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RequestForImpliedExecutionMessageCode, body |-> ZeroRequestForImpliedExecutionMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CrossOrderMessageCode, body |-> ZeroCrossOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RfqAuditMessageCode, body |-> ZeroRfqAuditMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> WaveForLiquidityMessageCode, body |-> ZeroWaveForLiquidityMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> WaveForLiquidityNotificationMessageCode, body |-> ZeroWaveForLiquidityNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ClearBookMessageCode, body |-> ZeroClearBookMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogonAckMessageCode, body |-> ZeroLogonAckMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogonRejectMessageCode, body |-> ZeroLogonRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogoutMessageCode, body |-> ZeroLogoutMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TestRequestMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TechnicalRejectMessageCode, body |-> ZeroTechnicalRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeclarationEntryMessageCode, body |-> ZeroDeclarationEntryMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeclarationEntryAckMessageCode, body |-> ZeroDeclarationEntryAckMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeclarationNoticeMessageCode, body |-> ZeroDeclarationNoticeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeclarationCancelAndRefusalMessageCode, body |-> ZeroDeclarationCancelAndRefusalMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FundPriceInputMessageCode, body |-> ZeroFundPriceInputMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> FundPriceInputAckMessageCode, body |-> ZeroFundPriceInputAckMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> DeclarationEntryRejectMessageCode, body |-> ZeroDeclarationEntryRejectMessage]] }

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

(* Every New Order Message Free Text Section Group decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderMessageFreeTextSectionGroup ==
    \A message \in CheckedNewOrderMessageFreeTextSectionGroup :
        LET read == DecodeNewOrderMessageFreeTextSectionGroup(EncodeNewOrderMessageFreeTextSectionGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Free Text Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFreeTextGroups ==
    \A message \in CheckedFreeTextGroups :
        LET read == DecodeFreeTextGroups(EncodeFreeTextGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Short Codes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidShortCodesGroup ==
    \A message \in CheckedMifidShortCodesGroup :
        LET read == DecodeMifidShortCodesGroup(EncodeMifidShortCodesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Short Codes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidShortCodesGroups ==
    \A message \in CheckedMifidShortCodesGroups :
        LET read == DecodeMifidShortCodesGroups(EncodeMifidShortCodesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Optional Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderOptionalFieldsGroup ==
    \A message \in CheckedOrderOptionalFieldsGroup :
        LET read == DecodeOrderOptionalFieldsGroup(EncodeOrderOptionalFieldsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Optional Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderOptionalFieldsGroups ==
    \A message \in CheckedOrderOptionalFieldsGroups :
        LET read == DecodeOrderOptionalFieldsGroups(EncodeOrderOptionalFieldsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Clearing Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderClearingFieldsGroup ==
    \A message \in CheckedOrderClearingFieldsGroup :
        LET read == DecodeOrderClearingFieldsGroup(EncodeOrderClearingFieldsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Clearing Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderClearingFieldsGroups ==
    \A message \in CheckedOrderClearingFieldsGroups :
        LET read == DecodeOrderClearingFieldsGroups(EncodeOrderClearingFieldsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNotUsedGroups ==
    \A message \in CheckedNotUsedGroups :
        LET read == DecodeNotUsedGroups(EncodeNotUsedGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Other Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOtherNotUsedGroups ==
    \A message \in CheckedOtherNotUsedGroups :
        LET read == DecodeOtherNotUsedGroups(EncodeOtherNotUsedGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Additional Infos Group decodes back to what was encoded, and leaves nothing over *)
RoundTripAdditionalInfosGroup ==
    \A message \in CheckedAdditionalInfosGroup :
        LET read == DecodeAdditionalInfosGroup(EncodeAdditionalInfosGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Additional Infos Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripAdditionalInfosGroups ==
    \A message \in CheckedAdditionalInfosGroups :
        LET read == DecodeAdditionalInfosGroups(EncodeAdditionalInfosGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderMessage ==
    \A message \in CheckedNewOrderMessage :
        LET read == DecodeNewOrderMessage(EncodeNewOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFieldsGroup ==
    \A message \in CheckedMifidFieldsGroup :
        LET read == DecodeMifidFieldsGroup(EncodeMifidFieldsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFieldsGroups ==
    \A message \in CheckedMifidFieldsGroups :
        LET read == DecodeMifidFieldsGroups(EncodeMifidFieldsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAckMessage ==
    \A message \in CheckedAckMessage :
        LET read == DecodeAckMessage(EncodeAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Optional Field Group decodes back to what was encoded, and leaves nothing over *)
RoundTripFillOptionalFieldGroup ==
    \A message \in CheckedFillOptionalFieldGroup :
        LET read == DecodeFillOptionalFieldGroup(EncodeFillOptionalFieldGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Optional Field Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFillOptionalFieldGroups ==
    \A message \in CheckedFillOptionalFieldGroups :
        LET read == DecodeFillOptionalFieldGroups(EncodeFillOptionalFieldGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Strategy Field Group decodes back to what was encoded, and leaves nothing over *)
RoundTripFillStrategyFieldGroup ==
    \A message \in CheckedFillStrategyFieldGroup :
        LET read == DecodeFillStrategyFieldGroup(EncodeFillStrategyFieldGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Strategy Field Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFillStrategyFieldGroups ==
    \A message \in CheckedFillStrategyFieldGroups :
        LET read == DecodeFillStrategyFieldGroups(EncodeFillStrategyFieldGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFieldsGroup2 ==
    \A message \in CheckedMifidFieldsGroup2 :
        LET read == DecodeMifidFieldsGroup2(EncodeMifidFieldsGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFieldsGroups2 ==
    \A message \in CheckedMifidFieldsGroups2 :
        LET read == DecodeMifidFieldsGroups2(EncodeMifidFieldsGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Derivatives Field Group decodes back to what was encoded, and leaves nothing over *)
RoundTripFillDerivativesFieldGroup ==
    \A message \in CheckedFillDerivativesFieldGroup :
        LET read == DecodeFillDerivativesFieldGroup(EncodeFillDerivativesFieldGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Derivatives Field Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFillDerivativesFieldGroups ==
    \A message \in CheckedFillDerivativesFieldGroups :
        LET read == DecodeFillDerivativesFieldGroups(EncodeFillDerivativesFieldGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fill Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFillMessage ==
    \A message \in CheckedFillMessage :
        LET read == DecodeFillMessage(EncodeFillMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFieldsGroup3 ==
    \A message \in CheckedMifidFieldsGroup3 :
        LET read == DecodeMifidFieldsGroup3(EncodeMifidFieldsGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFieldsGroups3 ==
    \A message \in CheckedMifidFieldsGroups3 :
        LET read == DecodeMifidFieldsGroups3(EncodeMifidFieldsGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Kill Message decodes back to what was encoded, and leaves nothing over *)
RoundTripKillMessage ==
    \A message \in CheckedKillMessage :
        LET read == DecodeKillMessage(EncodeKillMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Message Free Text Section Group decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderMessageFreeTextSectionGroup2 ==
    \A message \in CheckedNewOrderMessageFreeTextSectionGroup2 :
        LET read == DecodeNewOrderMessageFreeTextSectionGroup2(EncodeNewOrderMessageFreeTextSectionGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Free Text Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFreeTextGroups2 ==
    \A message \in CheckedFreeTextGroups2 :
        LET read == DecodeFreeTextGroups2(EncodeFreeTextGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Replace Optional Field Group decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelReplaceOptionalFieldGroup ==
    \A message \in CheckedCancelReplaceOptionalFieldGroup :
        LET read == DecodeCancelReplaceOptionalFieldGroup(EncodeCancelReplaceOptionalFieldGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Replace Optional Field Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelReplaceOptionalFieldGroups ==
    \A message \in CheckedCancelReplaceOptionalFieldGroups :
        LET read == DecodeCancelReplaceOptionalFieldGroups(EncodeCancelReplaceOptionalFieldGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Replace Clearing Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelReplaceClearingFieldsGroup ==
    \A message \in CheckedCancelReplaceClearingFieldsGroup :
        LET read == DecodeCancelReplaceClearingFieldsGroup(EncodeCancelReplaceClearingFieldsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Replace Clearing Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelReplaceClearingFieldsGroups ==
    \A message \in CheckedCancelReplaceClearingFieldsGroups :
        LET read == DecodeCancelReplaceClearingFieldsGroups(EncodeCancelReplaceClearingFieldsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNotUsedGroups2 ==
    \A message \in CheckedNotUsedGroups2 :
        LET read == DecodeNotUsedGroups2(EncodeNotUsedGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Other Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOtherNotUsedGroups2 ==
    \A message \in CheckedOtherNotUsedGroups2 :
        LET read == DecodeOtherNotUsedGroups2(EncodeOtherNotUsedGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Additional Infos Group decodes back to what was encoded, and leaves nothing over *)
RoundTripAdditionalInfosGroup2 ==
    \A message \in CheckedAdditionalInfosGroup2 :
        LET read == DecodeAdditionalInfosGroup2(EncodeAdditionalInfosGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Additional Infos Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripAdditionalInfosGroups2 ==
    \A message \in CheckedAdditionalInfosGroups2 :
        LET read == DecodeAdditionalInfosGroups2(EncodeAdditionalInfosGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Replace Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelReplaceMessage ==
    \A message \in CheckedCancelReplaceMessage :
        LET read == DecodeCancelReplaceMessage(EncodeCancelReplaceMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Collar Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripCollarFieldsGroup ==
    \A message \in CheckedCollarFieldsGroup :
        LET read == DecodeCollarFieldsGroup(EncodeCollarFieldsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Collar Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripCollarFieldsGroups ==
    \A message \in CheckedCollarFieldsGroups :
        LET read == DecodeCollarFieldsGroups(EncodeCollarFieldsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFieldsGroup4 ==
    \A message \in CheckedMifidFieldsGroup4 :
        LET read == DecodeMifidFieldsGroup4(EncodeMifidFieldsGroup4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFieldsGroups4 ==
    \A message \in CheckedMifidFieldsGroups4 :
        LET read == DecodeMifidFieldsGroups4(EncodeMifidFieldsGroups4(message))
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

(* Every Mifid Short Codes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidShortCodesGroup2 ==
    \A message \in CheckedMifidShortCodesGroup2 :
        LET read == DecodeMifidShortCodesGroup2(EncodeMifidShortCodesGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Short Codes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidShortCodesGroups2 ==
    \A message \in CheckedMifidShortCodesGroups2 :
        LET read == DecodeMifidShortCodesGroups2(EncodeMifidShortCodesGroups2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Dataset Group decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingDatasetGroup ==
    \A message \in CheckedClearingDatasetGroup :
        LET read == DecodeClearingDatasetGroup(EncodeClearingDatasetGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Dataset Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingDatasetGroups ==
    \A message \in CheckedClearingDatasetGroups :
        LET read == DecodeClearingDatasetGroups(EncodeClearingDatasetGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quotes Rep Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuotesRepGroup ==
    \A message \in CheckedQuotesRepGroup :
        LET read == DecodeQuotesRepGroup(EncodeQuotesRepGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quotes Rep Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripQuotesRepGroups ==
    \A message \in CheckedQuotesRepGroups :
        LET read == DecodeQuotesRepGroups(EncodeQuotesRepGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quotes Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuotesMessage ==
    \A message \in CheckedQuotesMessage :
        LET read == DecodeQuotesMessage(EncodeQuotesMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Acks Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteAcksGroup ==
    \A message \in CheckedQuoteAcksGroup :
        LET read == DecodeQuoteAcksGroup(EncodeQuoteAcksGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Acks Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteAcksGroups ==
    \A message \in CheckedQuoteAcksGroups :
        LET read == DecodeQuoteAcksGroups(EncodeQuoteAcksGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteAckMessage ==
    \A message \in CheckedQuoteAckMessage :
        LET read == DecodeQuoteAckMessage(EncodeQuoteAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequestMessage ==
    \A message \in CheckedQuoteRequestMessage :
        LET read == DecodeQuoteRequestMessage(EncodeQuoteRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNotUsedGroups3 ==
    \A message \in CheckedNotUsedGroups3 :
        LET read == DecodeNotUsedGroups3(EncodeNotUsedGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Other Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOtherNotUsedGroups3 ==
    \A message \in CheckedOtherNotUsedGroups3 :
        LET read == DecodeOtherNotUsedGroups3(EncodeOtherNotUsedGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRequestMessage ==
    \A message \in CheckedCancelRequestMessage :
        LET read == DecodeCancelRequestMessage(EncodeCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNotUsedGroups4 ==
    \A message \in CheckedNotUsedGroups4 :
        LET read == DecodeNotUsedGroups4(EncodeNotUsedGroups4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Other Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOtherNotUsedGroups4 ==
    \A message \in CheckedOtherNotUsedGroups4 :
        LET read == DecodeOtherNotUsedGroups4(EncodeOtherNotUsedGroups4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelMessage ==
    \A message \in CheckedMassCancelMessage :
        LET read == DecodeMassCancelMessage(EncodeMassCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFieldsGroup5 ==
    \A message \in CheckedMifidFieldsGroup5 :
        LET read == DecodeMifidFieldsGroup5(EncodeMifidFieldsGroup5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidFieldsGroups5 ==
    \A message \in CheckedMifidFieldsGroups5 :
        LET read == DecodeMifidFieldsGroups5(EncodeMifidFieldsGroups5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Cancel Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassCancelAckMessage ==
    \A message \in CheckedMassCancelAckMessage :
        LET read == DecodeMassCancelAckMessage(EncodeMassCancelAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Open Order Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOpenOrderRequestMessage ==
    \A message \in CheckedOpenOrderRequestMessage :
        LET read == DecodeOpenOrderRequestMessage(EncodeOpenOrderRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ownership Request Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOwnershipRequestAckMessage ==
    \A message \in CheckedOwnershipRequestAckMessage :
        LET read == DecodeOwnershipRequestAckMessage(EncodeOwnershipRequestAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ownership Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOwnershipRequestMessage ==
    \A message \in CheckedOwnershipRequestMessage :
        LET read == DecodeOwnershipRequestMessage(EncodeOwnershipRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBustNotificationMessage ==
    \A message \in CheckedTradeBustNotificationMessage :
        LET read == DecodeTradeBustNotificationMessage(EncodeTradeBustNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Collar Breach Confirmation Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCollarBreachConfirmationMessage ==
    \A message \in CheckedCollarBreachConfirmationMessage :
        LET read == DecodeCollarBreachConfirmationMessage(EncodeCollarBreachConfirmationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Price Input Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPriceInputMessage ==
    \A message \in CheckedPriceInputMessage :
        LET read == DecodePriceInputMessage(EncodePriceInputMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Provider Command Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityProviderCommandMessage ==
    \A message \in CheckedLiquidityProviderCommandMessage :
        LET read == DecodeLiquidityProviderCommandMessage(EncodeLiquidityProviderCommandMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Ask For Quote Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAskForQuoteMessage ==
    \A message \in CheckedAskForQuoteMessage :
        LET read == DecodeAskForQuoteMessage(EncodeAskForQuoteMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request For Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestForExecutionMessage ==
    \A message \in CheckedRequestForExecutionMessage :
        LET read == DecodeRequestForExecutionMessage(EncodeRequestForExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqNotificationMessage ==
    \A message \in CheckedRfqNotificationMessage :
        LET read == DecodeRfqNotificationMessage(EncodeRfqNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Matching Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqMatchingStatusMessage ==
    \A message \in CheckedRfqMatchingStatusMessage :
        LET read == DecodeRfqMatchingStatusMessage(EncodeRfqMatchingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfqlp Matching Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqlpMatchingStatusMessage ==
    \A message \in CheckedRfqlpMatchingStatusMessage :
        LET read == DecodeRfqlpMatchingStatusMessage(EncodeRfqlpMatchingStatusMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNotUsedGroups5 ==
    \A message \in CheckedNotUsedGroups5 :
        LET read == DecodeNotUsedGroups5(EncodeNotUsedGroups5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every User Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripUserNotificationMessage ==
    \A message \in CheckedUserNotificationMessage :
        LET read == DecodeUserNotificationMessage(EncodeUserNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mm Sign In Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMmSignInMessage ==
    \A message \in CheckedMmSignInMessage :
        LET read == DecodeMmSignInMessage(EncodeMmSignInMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mm Sign In Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMmSignInAckMessage ==
    \A message \in CheckedMmSignInAckMessage :
        LET read == DecodeMmSignInAckMessage(EncodeMmSignInAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Synchronization Group decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentSynchronizationGroup ==
    \A message \in CheckedInstrumentSynchronizationGroup :
        LET read == DecodeInstrumentSynchronizationGroup(EncodeInstrumentSynchronizationGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Synchronization Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentSynchronizationGroups ==
    \A message \in CheckedInstrumentSynchronizationGroups :
        LET read == DecodeInstrumentSynchronizationGroups(EncodeInstrumentSynchronizationGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Synchronization List Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentSynchronizationListMessage ==
    \A message \in CheckedInstrumentSynchronizationListMessage :
        LET read == DecodeInstrumentSynchronizationListMessage(EncodeInstrumentSynchronizationListMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Synchronization Time Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSynchronizationTimeMessage ==
    \A message \in CheckedSynchronizationTimeMessage :
        LET read == DecodeSynchronizationTimeMessage(EncodeSynchronizationTimeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyLegsGroup ==
    \A message \in CheckedStrategyLegsGroup :
        LET read == DecodeStrategyLegsGroup(EncodeStrategyLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Strategy Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripStrategyLegsGroups ==
    \A message \in CheckedStrategyLegsGroups :
        LET read == DecodeStrategyLegsGroups(EncodeStrategyLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionRequestMessage ==
    \A message \in CheckedSecurityDefinitionRequestMessage :
        LET read == DecodeSecurityDefinitionRequestMessage(EncodeSecurityDefinitionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionAckMessage ==
    \A message \in CheckedSecurityDefinitionAckMessage :
        LET read == DecodeSecurityDefinitionAckMessage(EncodeSecurityDefinitionAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mmp Request Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMmpRequestGroup ==
    \A message \in CheckedMmpRequestGroup :
        LET read == DecodeMmpRequestGroup(EncodeMmpRequestGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mmp Request Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMmpRequestGroups ==
    \A message \in CheckedMmpRequestGroups :
        LET read == DecodeMmpRequestGroups(EncodeMmpRequestGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mm Protection Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMmProtectionRequestMessage ==
    \A message \in CheckedMmProtectionRequestMessage :
        LET read == DecodeMmProtectionRequestMessage(EncodeMmProtectionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mmp Ack Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMmpAckGroup ==
    \A message \in CheckedMmpAckGroup :
        LET read == DecodeMmpAckGroup(EncodeMmpAckGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mmp Ack Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMmpAckGroups ==
    \A message \in CheckedMmpAckGroups :
        LET read == DecodeMmpAckGroups(EncodeMmpAckGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mm Protection Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMmProtectionAckMessage ==
    \A message \in CheckedMmProtectionAckMessage :
        LET read == DecodeMmProtectionAckMessage(EncodeMmProtectionAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wholesale Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripWholesaleLegsGroup ==
    \A message \in CheckedWholesaleLegsGroup :
        LET read == DecodeWholesaleLegsGroup(EncodeWholesaleLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wholesale Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripWholesaleLegsGroups ==
    \A message \in CheckedWholesaleLegsGroups :
        LET read == DecodeWholesaleLegsGroups(EncodeWholesaleLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wholesale Client Group decodes back to what was encoded, and leaves nothing over *)
RoundTripWholesaleClientGroup ==
    \A message \in CheckedWholesaleClientGroup :
        LET read == DecodeWholesaleClientGroup(EncodeWholesaleClientGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wholesale Client Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripWholesaleClientGroups ==
    \A message \in CheckedWholesaleClientGroups :
        LET read == DecodeWholesaleClientGroups(EncodeWholesaleClientGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Wholesale Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewWholesaleOrderMessage ==
    \A message \in CheckedNewWholesaleOrderMessage :
        LET read == DecodeNewWholesaleOrderMessage(EncodeNewWholesaleOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wholesale Ack Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripWholesaleAckLegsGroup ==
    \A message \in CheckedWholesaleAckLegsGroup :
        LET read == DecodeWholesaleAckLegsGroup(EncodeWholesaleAckLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wholesale Ack Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripWholesaleAckLegsGroups ==
    \A message \in CheckedWholesaleAckLegsGroups :
        LET read == DecodeWholesaleAckLegsGroups(EncodeWholesaleAckLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wholesale Ack Clearing Group decodes back to what was encoded, and leaves nothing over *)
RoundTripWholesaleAckClearingGroup ==
    \A message \in CheckedWholesaleAckClearingGroup :
        LET read == DecodeWholesaleAckClearingGroup(EncodeWholesaleAckClearingGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wholesale Ack Clearing Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripWholesaleAckClearingGroups ==
    \A message \in CheckedWholesaleAckClearingGroups :
        LET read == DecodeWholesaleAckClearingGroups(EncodeWholesaleAckClearingGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wholesale Order Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWholesaleOrderAckMessage ==
    \A message \in CheckedWholesaleOrderAckMessage :
        LET read == DecodeWholesaleOrderAckMessage(EncodeWholesaleOrderAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request For Implied Execution Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestForImpliedExecutionMessage ==
    \A message \in CheckedRequestForImpliedExecutionMessage :
        LET read == DecodeRequestForImpliedExecutionMessage(EncodeRequestForImpliedExecutionMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Message Free Text Section Group decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderMessageFreeTextSectionGroup3 ==
    \A message \in CheckedNewOrderMessageFreeTextSectionGroup3 :
        LET read == DecodeNewOrderMessageFreeTextSectionGroup3(EncodeNewOrderMessageFreeTextSectionGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Free Text Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripFreeTextGroups3 ==
    \A message \in CheckedFreeTextGroups3 :
        LET read == DecodeFreeTextGroups3(EncodeFreeTextGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Short Codes Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidShortCodesGroup3 ==
    \A message \in CheckedMifidShortCodesGroup3 :
        LET read == DecodeMifidShortCodesGroup3(EncodeMifidShortCodesGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mifid Short Codes Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMifidShortCodesGroups3 ==
    \A message \in CheckedMifidShortCodesGroups3 :
        LET read == DecodeMifidShortCodesGroups3(EncodeMifidShortCodesGroups3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Clearing Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossClearingFieldsGroup ==
    \A message \in CheckedCrossClearingFieldsGroup :
        LET read == DecodeCrossClearingFieldsGroup(EncodeCrossClearingFieldsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Clearing Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossClearingFieldsGroups ==
    \A message \in CheckedCrossClearingFieldsGroups :
        LET read == DecodeCrossClearingFieldsGroups(EncodeCrossClearingFieldsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Strategy Fields Group decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossStrategyFieldsGroup ==
    \A message \in CheckedCrossStrategyFieldsGroup :
        LET read == DecodeCrossStrategyFieldsGroup(EncodeCrossStrategyFieldsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Strategy Fields Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossStrategyFieldsGroups ==
    \A message \in CheckedCrossStrategyFieldsGroups :
        LET read == DecodeCrossStrategyFieldsGroups(EncodeCrossStrategyFieldsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossOrderMessage ==
    \A message \in CheckedCrossOrderMessage :
        LET read == DecodeCrossOrderMessage(EncodeCrossOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Counterparts Group decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqCounterpartsGroup ==
    \A message \in CheckedRfqCounterpartsGroup :
        LET read == DecodeRfqCounterpartsGroup(EncodeRfqCounterpartsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Counterparts Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqCounterpartsGroups ==
    \A message \in CheckedRfqCounterpartsGroups :
        LET read == DecodeRfqCounterpartsGroups(EncodeRfqCounterpartsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Rfq Audit Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRfqAuditMessage ==
    \A message \in CheckedRfqAuditMessage :
        LET read == DecodeRfqAuditMessage(EncodeRfqAuditMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wave For Liquidity Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWaveForLiquidityMessage ==
    \A message \in CheckedWaveForLiquidityMessage :
        LET read == DecodeWaveForLiquidityMessage(EncodeWaveForLiquidityMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wave For Liquidity Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWaveForLiquidityNotificationMessage ==
    \A message \in CheckedWaveForLiquidityNotificationMessage :
        LET read == DecodeWaveForLiquidityNotificationMessage(EncodeWaveForLiquidityNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clear Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripClearBookMessage ==
    \A message \in CheckedClearBookMessage :
        LET read == DecodeClearBookMessage(EncodeClearBookMessage(message))
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

(* Every Logon Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonAckMessage ==
    \A message \in CheckedLogonAckMessage :
        LET read == DecodeLogonAckMessage(EncodeLogonAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonRejectMessage ==
    \A message \in CheckedLogonRejectMessage :
        LET read == DecodeLogonRejectMessage(EncodeLogonRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logout Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutMessage ==
    \A message \in CheckedLogoutMessage :
        LET read == DecodeLogoutMessage(EncodeLogoutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Technical Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTechnicalRejectMessage ==
    \A message \in CheckedTechnicalRejectMessage :
        LET read == DecodeTechnicalRejectMessage(EncodeTechnicalRejectMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNotUsedGroups6 ==
    \A message \in CheckedNotUsedGroups6 :
        LET read == DecodeNotUsedGroups6(EncodeNotUsedGroups6(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Declaration Entry Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeclarationEntryMessage ==
    \A message \in CheckedDeclarationEntryMessage :
        LET read == DecodeDeclarationEntryMessage(EncodeDeclarationEntryMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNotUsedGroups7 ==
    \A message \in CheckedNotUsedGroups7 :
        LET read == DecodeNotUsedGroups7(EncodeNotUsedGroups7(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Declaration Entry Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeclarationEntryAckMessage ==
    \A message \in CheckedDeclarationEntryAckMessage :
        LET read == DecodeDeclarationEntryAckMessage(EncodeDeclarationEntryAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNotUsedGroups8 ==
    \A message \in CheckedNotUsedGroups8 :
        LET read == DecodeNotUsedGroups8(EncodeNotUsedGroups8(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Other Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripOtherNotUsedGroups5 ==
    \A message \in CheckedOtherNotUsedGroups5 :
        LET read == DecodeOtherNotUsedGroups5(EncodeOtherNotUsedGroups5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Declaration Notice Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeclarationNoticeMessage ==
    \A message \in CheckedDeclarationNoticeMessage :
        LET read == DecodeDeclarationNoticeMessage(EncodeDeclarationNoticeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Declaration Cancel And Refusal Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeclarationCancelAndRefusalMessage ==
    \A message \in CheckedDeclarationCancelAndRefusalMessage :
        LET read == DecodeDeclarationCancelAndRefusalMessage(EncodeDeclarationCancelAndRefusalMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fund Price Input Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFundPriceInputMessage ==
    \A message \in CheckedFundPriceInputMessage :
        LET read == DecodeFundPriceInputMessage(EncodeFundPriceInputMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Fund Price Input Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripFundPriceInputAckMessage ==
    \A message \in CheckedFundPriceInputAckMessage :
        LET read == DecodeFundPriceInputAckMessage(EncodeFundPriceInputAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Not Used Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripNotUsedGroups9 ==
    \A message \in CheckedNotUsedGroups9 :
        LET read == DecodeNotUsedGroups9(EncodeNotUsedGroups9(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Declaration Entry Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDeclarationEntryRejectMessage ==
    \A message \in CheckedDeclarationEntryRejectMessage :
        LET read == DecodeDeclarationEntryRejectMessage(EncodeDeclarationEntryRejectMessage(message))
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

(* A Payload is selected by the Template Id it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET read == DecodePayload(message.tag, EncodePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Frame is written from the bytes it frames *)
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
