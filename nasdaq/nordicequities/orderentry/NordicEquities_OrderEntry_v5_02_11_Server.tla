------------- MODULE NordicEquities_OrderEntry_v5_02_11_Server -------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Nordic Ouch 5 Order Entry v5.02.11                             *)
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
(* Note: Party Role Qualifier is a bit field set, checked as its 1 byte    *)
(* rather than bit by bit.                                                 *)
(*                                                                         *)
(* Note: Liquidity Attributes is a bit field set, checked as its 1 byte    *)
(* rather than bit by bit.                                                 *)
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
(* System Event Message: 9 bytes                                           *)
(***************************************************************************)

SystemEventMessage ==
    [ timestamp : Sample(8),
      eventCode : Sample(1) ]

EncodeSystemEventMessage(message) ==
    message.timestamp
        \o message.eventCode

DecodeSystemEventMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET eventCode == ReadBytes(timestamp.rest, 1) IN IF ~eventCode.ok THEN Fail ELSE
    Ok([ timestamp |-> timestamp.value,
         eventCode |-> eventCode.value ], eventCode.rest)

ZeroSystemEventMessage ==
    [ timestamp |-> [i \in 1 .. 8 |-> 0],
      eventCode |-> [i \in 1 .. 1 |-> 0] ]

(* System Event Message at zero, then each field in turn at the values it is checked at *)
CheckedSystemEventMessage ==
    { ZeroSystemEventMessage }
        \cup { [ZeroSystemEventMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroSystemEventMessage EXCEPT !.eventCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Clearing Account: 12 bytes                                              *)
(***************************************************************************)

ClearingAccount ==
    [ clearingAccountValue : Sample(12) ]

EncodeClearingAccount(message) ==
    message.clearingAccountValue

DecodeClearingAccount(bytes) ==
    LET clearingAccountValue == ReadBytes(bytes, 12) IN IF ~clearingAccountValue.ok THEN Fail ELSE
    Ok([ clearingAccountValue |-> clearingAccountValue.value ], clearingAccountValue.rest)

ZeroClearingAccount ==
    [ clearingAccountValue |-> [i \in 1 .. 12 |-> 0] ]

(* Clearing Account at zero, then each field in turn at the values it is checked at *)
CheckedClearingAccount ==
    { ZeroClearingAccount }
        \cup { [ZeroClearingAccount EXCEPT !.clearingAccountValue = one] : one \in Sample(12) }

(***************************************************************************)
(* Clearing Account Type: 1 bytes                                          *)
(***************************************************************************)

ClearingAccountType ==
    [ clearingAccountTypeValue : Sample(1) ]

EncodeClearingAccountType(message) ==
    message.clearingAccountTypeValue

DecodeClearingAccountType(bytes) ==
    LET clearingAccountTypeValue == ReadBytes(bytes, 1) IN IF ~clearingAccountTypeValue.ok THEN Fail ELSE
    Ok([ clearingAccountTypeValue |-> clearingAccountTypeValue.value ], clearingAccountTypeValue.rest)

ZeroClearingAccountType ==
    [ clearingAccountTypeValue |-> [i \in 1 .. 1 |-> 0] ]

(* Clearing Account Type at zero, then each field in turn at the values it is checked at *)
CheckedClearingAccountType ==
    { ZeroClearingAccountType }
        \cup { [ZeroClearingAccountType EXCEPT !.clearingAccountTypeValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Clearing Firm: 4 bytes                                                  *)
(***************************************************************************)

ClearingFirm ==
    [ clearingFirmValue : Sample(4) ]

EncodeClearingFirm(message) ==
    message.clearingFirmValue

DecodeClearingFirm(bytes) ==
    LET clearingFirmValue == ReadBytes(bytes, 4) IN IF ~clearingFirmValue.ok THEN Fail ELSE
    Ok([ clearingFirmValue |-> clearingFirmValue.value ], clearingFirmValue.rest)

ZeroClearingFirm ==
    [ clearingFirmValue |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Firm at zero, then each field in turn at the values it is checked at *)
CheckedClearingFirm ==
    { ZeroClearingFirm }
        \cup { [ZeroClearingFirm EXCEPT !.clearingFirmValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Client Reference: 15 bytes                                              *)
(***************************************************************************)

ClientReference ==
    [ clientReferenceValue : Sample(15) ]

EncodeClientReference(message) ==
    message.clientReferenceValue

DecodeClientReference(bytes) ==
    LET clientReferenceValue == ReadBytes(bytes, 15) IN IF ~clientReferenceValue.ok THEN Fail ELSE
    Ok([ clientReferenceValue |-> clientReferenceValue.value ], clientReferenceValue.rest)

ZeroClientReference ==
    [ clientReferenceValue |-> [i \in 1 .. 15 |-> 0] ]

(* Client Reference at zero, then each field in turn at the values it is checked at *)
CheckedClientReference ==
    { ZeroClientReference }
        \cup { [ZeroClientReference EXCEPT !.clientReferenceValue = one] : one \in Sample(15) }

(***************************************************************************)
(* Cross Type: 1 bytes                                                     *)
(***************************************************************************)

CrossType ==
    [ crossTypeValue : Sample(1) ]

EncodeCrossType(message) ==
    message.crossTypeValue

DecodeCrossType(bytes) ==
    LET crossTypeValue == ReadBytes(bytes, 1) IN IF ~crossTypeValue.ok THEN Fail ELSE
    Ok([ crossTypeValue |-> crossTypeValue.value ], crossTypeValue.rest)

ZeroCrossType ==
    [ crossTypeValue |-> [i \in 1 .. 1 |-> 0] ]

(* Cross Type at zero, then each field in turn at the values it is checked at *)
CheckedCrossType ==
    { ZeroCrossType }
        \cup { [ZeroCrossType EXCEPT !.crossTypeValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Dea Indicator: 1 bytes                                                  *)
(***************************************************************************)

DeaIndicator ==
    [ deaIndicatorValue : Sample(1) ]

EncodeDeaIndicator(message) ==
    message.deaIndicatorValue

DecodeDeaIndicator(bytes) ==
    LET deaIndicatorValue == ReadBytes(bytes, 1) IN IF ~deaIndicatorValue.ok THEN Fail ELSE
    Ok([ deaIndicatorValue |-> deaIndicatorValue.value ], deaIndicatorValue.rest)

ZeroDeaIndicator ==
    [ deaIndicatorValue |-> [i \in 1 .. 1 |-> 0] ]

(* Dea Indicator at zero, then each field in turn at the values it is checked at *)
CheckedDeaIndicator ==
    { ZeroDeaIndicator }
        \cup { [ZeroDeaIndicator EXCEPT !.deaIndicatorValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Display: 1 bytes                                                        *)
(***************************************************************************)

Display ==
    [ displayValue : Sample(1) ]

EncodeDisplay(message) ==
    message.displayValue

DecodeDisplay(bytes) ==
    LET displayValue == ReadBytes(bytes, 1) IN IF ~displayValue.ok THEN Fail ELSE
    Ok([ displayValue |-> displayValue.value ], displayValue.rest)

ZeroDisplay ==
    [ displayValue |-> [i \in 1 .. 1 |-> 0] ]

(* Display at zero, then each field in turn at the values it is checked at *)
CheckedDisplay ==
    { ZeroDisplay }
        \cup { [ZeroDisplay EXCEPT !.displayValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Display Price: 4 bytes                                                  *)
(***************************************************************************)

DisplayPrice ==
    [ displayPriceValue : Sample(4) ]

EncodeDisplayPrice(message) ==
    message.displayPriceValue

DecodeDisplayPrice(bytes) ==
    LET displayPriceValue == ReadBytes(bytes, 4) IN IF ~displayPriceValue.ok THEN Fail ELSE
    Ok([ displayPriceValue |-> displayPriceValue.value ], displayPriceValue.rest)

ZeroDisplayPrice ==
    [ displayPriceValue |-> [i \in 1 .. 4 |-> 0] ]

(* Display Price at zero, then each field in turn at the values it is checked at *)
CheckedDisplayPrice ==
    { ZeroDisplayPrice }
        \cup { [ZeroDisplayPrice EXCEPT !.displayPriceValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Display Quantity: 4 bytes                                               *)
(***************************************************************************)

DisplayQuantity ==
    [ displayQuantityValue : Sample(4) ]

EncodeDisplayQuantity(message) ==
    message.displayQuantityValue

DecodeDisplayQuantity(bytes) ==
    LET displayQuantityValue == ReadBytes(bytes, 4) IN IF ~displayQuantityValue.ok THEN Fail ELSE
    Ok([ displayQuantityValue |-> displayQuantityValue.value ], displayQuantityValue.rest)

ZeroDisplayQuantity ==
    [ displayQuantityValue |-> [i \in 1 .. 4 |-> 0] ]

(* Display Quantity at zero, then each field in turn at the values it is checked at *)
CheckedDisplayQuantity ==
    { ZeroDisplayQuantity }
        \cup { [ZeroDisplayQuantity EXCEPT !.displayQuantityValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Expire Time: 2 bytes                                                    *)
(***************************************************************************)

ExpireTime ==
    [ expireTimeValue : Sample(2) ]

EncodeExpireTime(message) ==
    message.expireTimeValue

DecodeExpireTime(bytes) ==
    LET expireTimeValue == ReadBytes(bytes, 2) IN IF ~expireTimeValue.ok THEN Fail ELSE
    Ok([ expireTimeValue |-> expireTimeValue.value ], expireTimeValue.rest)

ZeroExpireTime ==
    [ expireTimeValue |-> [i \in 1 .. 2 |-> 0] ]

(* Expire Time at zero, then each field in turn at the values it is checked at *)
CheckedExpireTime ==
    { ZeroExpireTime }
        \cup { [ZeroExpireTime EXCEPT !.expireTimeValue = one] : one \in Sample(2) }

(***************************************************************************)
(* Firm: 4 bytes                                                           *)
(***************************************************************************)

Firm ==
    [ firmValue : Sample(4) ]

EncodeFirm(message) ==
    message.firmValue

DecodeFirm(bytes) ==
    LET firmValue == ReadBytes(bytes, 4) IN IF ~firmValue.ok THEN Fail ELSE
    Ok([ firmValue |-> firmValue.value ], firmValue.rest)

ZeroFirm ==
    [ firmValue |-> [i \in 1 .. 4 |-> 0] ]

(* Firm at zero, then each field in turn at the values it is checked at *)
CheckedFirm ==
    { ZeroFirm }
        \cup { [ZeroFirm EXCEPT !.firmValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Liquidity Provision Indicator: 1 bytes                                  *)
(***************************************************************************)

LiquidityProvisionIndicator ==
    [ liquidityProvisionIndicatorValue : Sample(1) ]

EncodeLiquidityProvisionIndicator(message) ==
    message.liquidityProvisionIndicatorValue

DecodeLiquidityProvisionIndicator(bytes) ==
    LET liquidityProvisionIndicatorValue == ReadBytes(bytes, 1) IN IF ~liquidityProvisionIndicatorValue.ok THEN Fail ELSE
    Ok([ liquidityProvisionIndicatorValue |-> liquidityProvisionIndicatorValue.value ], liquidityProvisionIndicatorValue.rest)

ZeroLiquidityProvisionIndicator ==
    [ liquidityProvisionIndicatorValue |-> [i \in 1 .. 1 |-> 0] ]

(* Liquidity Provision Indicator at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityProvisionIndicator ==
    { ZeroLiquidityProvisionIndicator }
        \cup { [ZeroLiquidityProvisionIndicator EXCEPT !.liquidityProvisionIndicatorValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Max Floor: 4 bytes                                                      *)
(***************************************************************************)

MaxFloor ==
    [ maxFloorValue : Sample(4) ]

EncodeMaxFloor(message) ==
    message.maxFloorValue

DecodeMaxFloor(bytes) ==
    LET maxFloorValue == ReadBytes(bytes, 4) IN IF ~maxFloorValue.ok THEN Fail ELSE
    Ok([ maxFloorValue |-> maxFloorValue.value ], maxFloorValue.rest)

ZeroMaxFloor ==
    [ maxFloorValue |-> [i \in 1 .. 4 |-> 0] ]

(* Max Floor at zero, then each field in turn at the values it is checked at *)
CheckedMaxFloor ==
    { ZeroMaxFloor }
        \cup { [ZeroMaxFloor EXCEPT !.maxFloorValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Minimum Quantity: 4 bytes                                               *)
(***************************************************************************)

MinimumQuantity ==
    [ minimumQuantityValue : Sample(4) ]

EncodeMinimumQuantity(message) ==
    message.minimumQuantityValue

DecodeMinimumQuantity(bytes) ==
    LET minimumQuantityValue == ReadBytes(bytes, 4) IN IF ~minimumQuantityValue.ok THEN Fail ELSE
    Ok([ minimumQuantityValue |-> minimumQuantityValue.value ], minimumQuantityValue.rest)

ZeroMinimumQuantity ==
    [ minimumQuantityValue |-> [i \in 1 .. 4 |-> 0] ]

(* Minimum Quantity at zero, then each field in turn at the values it is checked at *)
CheckedMinimumQuantity ==
    { ZeroMinimumQuantity }
        \cup { [ZeroMinimumQuantity EXCEPT !.minimumQuantityValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Reference: 10 bytes                                               *)
(***************************************************************************)

OrderReference ==
    [ orderReferenceValue : Sample(10) ]

EncodeOrderReference(message) ==
    message.orderReferenceValue

DecodeOrderReference(bytes) ==
    LET orderReferenceValue == ReadBytes(bytes, 10) IN IF ~orderReferenceValue.ok THEN Fail ELSE
    Ok([ orderReferenceValue |-> orderReferenceValue.value ], orderReferenceValue.rest)

ZeroOrderReference ==
    [ orderReferenceValue |-> [i \in 1 .. 10 |-> 0] ]

(* Order Reference at zero, then each field in turn at the values it is checked at *)
CheckedOrderReference ==
    { ZeroOrderReference }
        \cup { [ZeroOrderReference EXCEPT !.orderReferenceValue = one] : one \in Sample(10) }

(***************************************************************************)
(* Original Order Entry Date: 4 bytes                                      *)
(***************************************************************************)

OriginalOrderEntryDate ==
    [ originalOrderEntryDateValue : Sample(4) ]

EncodeOriginalOrderEntryDate(message) ==
    message.originalOrderEntryDateValue

DecodeOriginalOrderEntryDate(bytes) ==
    LET originalOrderEntryDateValue == ReadBytes(bytes, 4) IN IF ~originalOrderEntryDateValue.ok THEN Fail ELSE
    Ok([ originalOrderEntryDateValue |-> originalOrderEntryDateValue.value ], originalOrderEntryDateValue.rest)

ZeroOriginalOrderEntryDate ==
    [ originalOrderEntryDateValue |-> [i \in 1 .. 4 |-> 0] ]

(* Original Order Entry Date at zero, then each field in turn at the values it is checked at *)
CheckedOriginalOrderEntryDate ==
    { ZeroOriginalOrderEntryDate }
        \cup { [ZeroOriginalOrderEntryDate EXCEPT !.originalOrderEntryDateValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Original Order Reference Number: 8 bytes                                *)
(***************************************************************************)

OriginalOrderReferenceNumber ==
    [ originalOrderReferenceNumberValue : Sample(8) ]

EncodeOriginalOrderReferenceNumber(message) ==
    message.originalOrderReferenceNumberValue

DecodeOriginalOrderReferenceNumber(bytes) ==
    LET originalOrderReferenceNumberValue == ReadBytes(bytes, 8) IN IF ~originalOrderReferenceNumberValue.ok THEN Fail ELSE
    Ok([ originalOrderReferenceNumberValue |-> originalOrderReferenceNumberValue.value ], originalOrderReferenceNumberValue.rest)

ZeroOriginalOrderReferenceNumber ==
    [ originalOrderReferenceNumberValue |-> [i \in 1 .. 8 |-> 0] ]

(* Original Order Reference Number at zero, then each field in turn at the values it is checked at *)
CheckedOriginalOrderReferenceNumber ==
    { ZeroOriginalOrderReferenceNumber }
        \cup { [ZeroOriginalOrderReferenceNumber EXCEPT !.originalOrderReferenceNumberValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Peg Difference: 4 bytes                                                 *)
(***************************************************************************)

PegDifference ==
    [ pegDifferenceValue : Sample(4) ]

EncodePegDifference(message) ==
    message.pegDifferenceValue

DecodePegDifference(bytes) ==
    LET pegDifferenceValue == ReadBytes(bytes, 4) IN IF ~pegDifferenceValue.ok THEN Fail ELSE
    Ok([ pegDifferenceValue |-> pegDifferenceValue.value ], pegDifferenceValue.rest)

ZeroPegDifference ==
    [ pegDifferenceValue |-> [i \in 1 .. 4 |-> 0] ]

(* Peg Difference at zero, then each field in turn at the values it is checked at *)
CheckedPegDifference ==
    { ZeroPegDifference }
        \cup { [ZeroPegDifference EXCEPT !.pegDifferenceValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Peg Type: 1 bytes                                                       *)
(***************************************************************************)

PegType ==
    [ pegTypeValue : Sample(1) ]

EncodePegType(message) ==
    message.pegTypeValue

DecodePegType(bytes) ==
    LET pegTypeValue == ReadBytes(bytes, 1) IN IF ~pegTypeValue.ok THEN Fail ELSE
    Ok([ pegTypeValue |-> pegTypeValue.value ], pegTypeValue.rest)

ZeroPegType ==
    [ pegTypeValue |-> [i \in 1 .. 1 |-> 0] ]

(* Peg Type at zero, then each field in turn at the values it is checked at *)
CheckedPegType ==
    { ZeroPegType }
        \cup { [ZeroPegType EXCEPT !.pegTypeValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Random Reserve: 4 bytes                                                 *)
(***************************************************************************)

RandomReserve ==
    [ randomReserveValue : Sample(4) ]

EncodeRandomReserve(message) ==
    message.randomReserveValue

DecodeRandomReserve(bytes) ==
    LET randomReserveValue == ReadBytes(bytes, 4) IN IF ~randomReserveValue.ok THEN Fail ELSE
    Ok([ randomReserveValue |-> randomReserveValue.value ], randomReserveValue.rest)

ZeroRandomReserve ==
    [ randomReserveValue |-> [i \in 1 .. 4 |-> 0] ]

(* Random Reserve at zero, then each field in turn at the values it is checked at *)
CheckedRandomReserve ==
    { ZeroRandomReserve }
        \cup { [ZeroRandomReserve EXCEPT !.randomReserveValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Secondary Order Reference Number: 8 bytes                               *)
(***************************************************************************)

SecondaryOrderReferenceNumber ==
    [ secondaryOrderReferenceNumberValue : Sample(8) ]

EncodeSecondaryOrderReferenceNumber(message) ==
    message.secondaryOrderReferenceNumberValue

DecodeSecondaryOrderReferenceNumber(bytes) ==
    LET secondaryOrderReferenceNumberValue == ReadBytes(bytes, 8) IN IF ~secondaryOrderReferenceNumberValue.ok THEN Fail ELSE
    Ok([ secondaryOrderReferenceNumberValue |-> secondaryOrderReferenceNumberValue.value ], secondaryOrderReferenceNumberValue.rest)

ZeroSecondaryOrderReferenceNumber ==
    [ secondaryOrderReferenceNumberValue |-> [i \in 1 .. 8 |-> 0] ]

(* Secondary Order Reference Number at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryOrderReferenceNumber ==
    { ZeroSecondaryOrderReferenceNumber }
        \cup { [ZeroSecondaryOrderReferenceNumber EXCEPT !.secondaryOrderReferenceNumberValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Stp Action: 1 bytes                                                     *)
(***************************************************************************)

StpAction ==
    [ stpActionValue : Sample(1) ]

EncodeStpAction(message) ==
    message.stpActionValue

DecodeStpAction(bytes) ==
    LET stpActionValue == ReadBytes(bytes, 1) IN IF ~stpActionValue.ok THEN Fail ELSE
    Ok([ stpActionValue |-> stpActionValue.value ], stpActionValue.rest)

ZeroStpAction ==
    [ stpActionValue |-> [i \in 1 .. 1 |-> 0] ]

(* Stp Action at zero, then each field in turn at the values it is checked at *)
CheckedStpAction ==
    { ZeroStpAction }
        \cup { [ZeroStpAction EXCEPT !.stpActionValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Stp Level: 1 bytes                                                      *)
(***************************************************************************)

StpLevel ==
    [ stpLevelValue : Sample(1) ]

EncodeStpLevel(message) ==
    message.stpLevelValue

DecodeStpLevel(bytes) ==
    LET stpLevelValue == ReadBytes(bytes, 1) IN IF ~stpLevelValue.ok THEN Fail ELSE
    Ok([ stpLevelValue |-> stpLevelValue.value ], stpLevelValue.rest)

ZeroStpLevel ==
    [ stpLevelValue |-> [i \in 1 .. 1 |-> 0] ]

(* Stp Level at zero, then each field in turn at the values it is checked at *)
CheckedStpLevel ==
    { ZeroStpLevel }
        \cup { [ZeroStpLevel EXCEPT !.stpLevelValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Stp Trader Group: 2 bytes                                               *)
(***************************************************************************)

StpTraderGroup ==
    [ stpTraderGroupValue : Sample(2) ]

EncodeStpTraderGroup(message) ==
    message.stpTraderGroupValue

DecodeStpTraderGroup(bytes) ==
    LET stpTraderGroupValue == ReadBytes(bytes, 2) IN IF ~stpTraderGroupValue.ok THEN Fail ELSE
    Ok([ stpTraderGroupValue |-> stpTraderGroupValue.value ], stpTraderGroupValue.rest)

ZeroStpTraderGroup ==
    [ stpTraderGroupValue |-> [i \in 1 .. 2 |-> 0] ]

(* Stp Trader Group at zero, then each field in turn at the values it is checked at *)
CheckedStpTraderGroup ==
    { ZeroStpTraderGroup }
        \cup { [ZeroStpTraderGroup EXCEPT !.stpTraderGroupValue = one] : one \in Sample(2) }

(***************************************************************************)
(* Time In Force: 1 bytes                                                  *)
(***************************************************************************)

TimeInForce ==
    [ timeInForceValue : Sample(1) ]

EncodeTimeInForce(message) ==
    message.timeInForceValue

DecodeTimeInForce(bytes) ==
    LET timeInForceValue == ReadBytes(bytes, 1) IN IF ~timeInForceValue.ok THEN Fail ELSE
    Ok([ timeInForceValue |-> timeInForceValue.value ], timeInForceValue.rest)

ZeroTimeInForce ==
    [ timeInForceValue |-> [i \in 1 .. 1 |-> 0] ]

(* Time In Force at zero, then each field in turn at the values it is checked at *)
CheckedTimeInForce ==
    { ZeroTimeInForce }
        \cup { [ZeroTimeInForce EXCEPT !.timeInForceValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading At Closing Price: 1 bytes                                       *)
(***************************************************************************)

TradingAtClosingPrice ==
    [ tradingAtClosingPriceValue : Sample(1) ]

EncodeTradingAtClosingPrice(message) ==
    message.tradingAtClosingPriceValue

DecodeTradingAtClosingPrice(bytes) ==
    LET tradingAtClosingPriceValue == ReadBytes(bytes, 1) IN IF ~tradingAtClosingPriceValue.ok THEN Fail ELSE
    Ok([ tradingAtClosingPriceValue |-> tradingAtClosingPriceValue.value ], tradingAtClosingPriceValue.rest)

ZeroTradingAtClosingPrice ==
    [ tradingAtClosingPriceValue |-> [i \in 1 .. 1 |-> 0] ]

(* Trading At Closing Price at zero, then each field in turn at the values it is checked at *)
CheckedTradingAtClosingPrice ==
    { ZeroTradingAtClosingPrice }
        \cup { [ZeroTradingAtClosingPrice EXCEPT !.tradingAtClosingPriceValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Condition: 1 bytes                                                *)
(***************************************************************************)

OrderCondition ==
    [ orderConditionValue : Sample(1) ]

EncodeOrderCondition(message) ==
    message.orderConditionValue

DecodeOrderCondition(bytes) ==
    LET orderConditionValue == ReadBytes(bytes, 1) IN IF ~orderConditionValue.ok THEN Fail ELSE
    Ok([ orderConditionValue |-> orderConditionValue.value ], orderConditionValue.rest)

ZeroOrderCondition ==
    [ orderConditionValue |-> [i \in 1 .. 1 |-> 0] ]

(* Order Condition at zero, then each field in turn at the values it is checked at *)
CheckedOrderCondition ==
    { ZeroOrderCondition }
        \cup { [ZeroOrderCondition EXCEPT !.orderConditionValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Cumulative Quantity: 4 bytes                                            *)
(***************************************************************************)

CumulativeQuantity ==
    [ cumulativeQuantityValue : Sample(4) ]

EncodeCumulativeQuantity(message) ==
    message.cumulativeQuantityValue

DecodeCumulativeQuantity(bytes) ==
    LET cumulativeQuantityValue == ReadBytes(bytes, 4) IN IF ~cumulativeQuantityValue.ok THEN Fail ELSE
    Ok([ cumulativeQuantityValue |-> cumulativeQuantityValue.value ], cumulativeQuantityValue.rest)

ZeroCumulativeQuantity ==
    [ cumulativeQuantityValue |-> [i \in 1 .. 4 |-> 0] ]

(* Cumulative Quantity at zero, then each field in turn at the values it is checked at *)
CheckedCumulativeQuantity ==
    { ZeroCumulativeQuantity }
        \cup { [ZeroCumulativeQuantity EXCEPT !.cumulativeQuantityValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Customer Order Capacity: 1 bytes                                        *)
(***************************************************************************)

CustomerOrderCapacity ==
    [ customerOrderCapacityValue : Sample(1) ]

EncodeCustomerOrderCapacity(message) ==
    message.customerOrderCapacityValue

DecodeCustomerOrderCapacity(bytes) ==
    LET customerOrderCapacityValue == ReadBytes(bytes, 1) IN IF ~customerOrderCapacityValue.ok THEN Fail ELSE
    Ok([ customerOrderCapacityValue |-> customerOrderCapacityValue.value ], customerOrderCapacityValue.rest)

ZeroCustomerOrderCapacity ==
    [ customerOrderCapacityValue |-> [i \in 1 .. 1 |-> 0] ]

(* Customer Order Capacity at zero, then each field in turn at the values it is checked at *)
CheckedCustomerOrderCapacity ==
    { ZeroCustomerOrderCapacity }
        \cup { [ZeroCustomerOrderCapacity EXCEPT !.customerOrderCapacityValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Target Strategy: 1 bytes                                                *)
(***************************************************************************)

TargetStrategy ==
    [ targetStrategyValue : Sample(1) ]

EncodeTargetStrategy(message) ==
    message.targetStrategyValue

DecodeTargetStrategy(bytes) ==
    LET targetStrategyValue == ReadBytes(bytes, 1) IN IF ~targetStrategyValue.ok THEN Fail ELSE
    Ok([ targetStrategyValue |-> targetStrategyValue.value ], targetStrategyValue.rest)

ZeroTargetStrategy ==
    [ targetStrategyValue |-> [i \in 1 .. 1 |-> 0] ]

(* Target Strategy at zero, then each field in turn at the values it is checked at *)
CheckedTargetStrategy ==
    { ZeroTargetStrategy }
        \cup { [ZeroTargetStrategy EXCEPT !.targetStrategyValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Min Rate: 2 bytes                                                       *)
(***************************************************************************)

MinRate ==
    [ minRateValue : Sample(2) ]

EncodeMinRate(message) ==
    message.minRateValue

DecodeMinRate(bytes) ==
    LET minRateValue == ReadBytes(bytes, 2) IN IF ~minRateValue.ok THEN Fail ELSE
    Ok([ minRateValue |-> minRateValue.value ], minRateValue.rest)

ZeroMinRate ==
    [ minRateValue |-> [i \in 1 .. 2 |-> 0] ]

(* Min Rate at zero, then each field in turn at the values it is checked at *)
CheckedMinRate ==
    { ZeroMinRate }
        \cup { [ZeroMinRate EXCEPT !.minRateValue = one] : one \in Sample(2) }

(***************************************************************************)
(* Max Rate: 2 bytes                                                       *)
(***************************************************************************)

MaxRate ==
    [ maxRateValue : Sample(2) ]

EncodeMaxRate(message) ==
    message.maxRateValue

DecodeMaxRate(bytes) ==
    LET maxRateValue == ReadBytes(bytes, 2) IN IF ~maxRateValue.ok THEN Fail ELSE
    Ok([ maxRateValue |-> maxRateValue.value ], maxRateValue.rest)

ZeroMaxRate ==
    [ maxRateValue |-> [i \in 1 .. 2 |-> 0] ]

(* Max Rate at zero, then each field in turn at the values it is checked at *)
CheckedMaxRate ==
    { ZeroMaxRate }
        \cup { [ZeroMaxRate EXCEPT !.maxRateValue = one] : one \in Sample(2) }

(***************************************************************************)
(* Conditional Type: 1 bytes                                               *)
(***************************************************************************)

ConditionalType ==
    [ conditionalTypeValue : Sample(1) ]

EncodeConditionalType(message) ==
    message.conditionalTypeValue

DecodeConditionalType(bytes) ==
    LET conditionalTypeValue == ReadBytes(bytes, 1) IN IF ~conditionalTypeValue.ok THEN Fail ELSE
    Ok([ conditionalTypeValue |-> conditionalTypeValue.value ], conditionalTypeValue.rest)

ZeroConditionalType ==
    [ conditionalTypeValue |-> [i \in 1 .. 1 |-> 0] ]

(* Conditional Type at zero, then each field in turn at the values it is checked at *)
CheckedConditionalType ==
    { ZeroConditionalType }
        \cup { [ZeroConditionalType EXCEPT !.conditionalTypeValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Firm Up Id: 4 bytes                                                     *)
(***************************************************************************)

FirmUpId ==
    [ firmUpIdValue : Sample(4) ]

EncodeFirmUpId(message) ==
    message.firmUpIdValue

DecodeFirmUpId(bytes) ==
    LET firmUpIdValue == ReadBytes(bytes, 4) IN IF ~firmUpIdValue.ok THEN Fail ELSE
    Ok([ firmUpIdValue |-> firmUpIdValue.value ], firmUpIdValue.rest)

ZeroFirmUpId ==
    [ firmUpIdValue |-> [i \in 1 .. 4 |-> 0] ]

(* Firm Up Id at zero, then each field in turn at the values it is checked at *)
CheckedFirmUpId ==
    { ZeroFirmUpId }
        \cup { [ZeroFirmUpId EXCEPT !.firmUpIdValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Value Payload, selected by Tag                                          *)
(***************************************************************************)

ClearingAccountCode == 1  \* 0x01
ClearingAccountTypeCode == 2  \* 0x02
ClearingFirmCode == 3  \* 0x03
ClientReferenceCode == 4  \* 0x04
CrossTypeCode == 5  \* 0x05
DeaIndicatorCode == 6  \* 0x06
DisplayCode == 7  \* 0x07
DisplayPriceCode == 8  \* 0x08
DisplayQuantityCode == 9  \* 0x09
ExpireTimeCode == 10  \* 0x0a
FirmCode == 11  \* 0x0b
LiquidityProvisionIndicatorCode == 12  \* 0x0c
MaxFloorCode == 13  \* 0x0d
MinimumQuantityCode == 14  \* 0x0e
OrderReferenceCode == 15  \* 0x0f
OriginalOrderEntryDateCode == 16  \* 0x10
OriginalOrderReferenceNumberCode == 17  \* 0x11
PegDifferenceCode == 18  \* 0x12
PegTypeCode == 19  \* 0x13
RandomReserveCode == 20  \* 0x14
SecondaryOrderReferenceNumberCode == 21  \* 0x15
StpActionCode == 22  \* 0x16
StpLevelCode == 23  \* 0x17
StpTraderGroupCode == 24  \* 0x18
TimeInForceCode == 25  \* 0x19
TradingAtClosingPriceCode == 26  \* 0x1a
OrderConditionCode == 27  \* 0x1b
CumulativeQuantityCode == 28  \* 0x1c
CustomerOrderCapacityCode == 29  \* 0x1d
TargetStrategyCode == 30  \* 0x1e
MinRateCode == 31  \* 0x1f
MaxRateCode == 32  \* 0x20
ConditionalTypeCode == 33  \* 0x21
FirmUpIdCode == 34  \* 0x22

ValuePayload ==
    [ tag : {ClearingAccountCode}, body : ClearingAccount ]
        \cup [ tag : {ClearingAccountTypeCode}, body : ClearingAccountType ]
        \cup [ tag : {ClearingFirmCode}, body : ClearingFirm ]
        \cup [ tag : {ClientReferenceCode}, body : ClientReference ]
        \cup [ tag : {CrossTypeCode}, body : CrossType ]
        \cup [ tag : {DeaIndicatorCode}, body : DeaIndicator ]
        \cup [ tag : {DisplayCode}, body : Display ]
        \cup [ tag : {DisplayPriceCode}, body : DisplayPrice ]
        \cup [ tag : {DisplayQuantityCode}, body : DisplayQuantity ]
        \cup [ tag : {ExpireTimeCode}, body : ExpireTime ]
        \cup [ tag : {FirmCode}, body : Firm ]
        \cup [ tag : {LiquidityProvisionIndicatorCode}, body : LiquidityProvisionIndicator ]
        \cup [ tag : {MaxFloorCode}, body : MaxFloor ]
        \cup [ tag : {MinimumQuantityCode}, body : MinimumQuantity ]
        \cup [ tag : {OrderReferenceCode}, body : OrderReference ]
        \cup [ tag : {OriginalOrderEntryDateCode}, body : OriginalOrderEntryDate ]
        \cup [ tag : {OriginalOrderReferenceNumberCode}, body : OriginalOrderReferenceNumber ]
        \cup [ tag : {PegDifferenceCode}, body : PegDifference ]
        \cup [ tag : {PegTypeCode}, body : PegType ]
        \cup [ tag : {RandomReserveCode}, body : RandomReserve ]
        \cup [ tag : {SecondaryOrderReferenceNumberCode}, body : SecondaryOrderReferenceNumber ]
        \cup [ tag : {StpActionCode}, body : StpAction ]
        \cup [ tag : {StpLevelCode}, body : StpLevel ]
        \cup [ tag : {StpTraderGroupCode}, body : StpTraderGroup ]
        \cup [ tag : {TimeInForceCode}, body : TimeInForce ]
        \cup [ tag : {TradingAtClosingPriceCode}, body : TradingAtClosingPrice ]
        \cup [ tag : {OrderConditionCode}, body : OrderCondition ]
        \cup [ tag : {CumulativeQuantityCode}, body : CumulativeQuantity ]
        \cup [ tag : {CustomerOrderCapacityCode}, body : CustomerOrderCapacity ]
        \cup [ tag : {TargetStrategyCode}, body : TargetStrategy ]
        \cup [ tag : {MinRateCode}, body : MinRate ]
        \cup [ tag : {MaxRateCode}, body : MaxRate ]
        \cup [ tag : {ConditionalTypeCode}, body : ConditionalType ]
        \cup [ tag : {FirmUpIdCode}, body : FirmUpId ]

EncodeValuePayload(message) ==
    CASE message.tag = ClearingAccountCode -> EncodeClearingAccount(message.body)
      [] message.tag = ClearingAccountTypeCode -> EncodeClearingAccountType(message.body)
      [] message.tag = ClearingFirmCode -> EncodeClearingFirm(message.body)
      [] message.tag = ClientReferenceCode -> EncodeClientReference(message.body)
      [] message.tag = CrossTypeCode -> EncodeCrossType(message.body)
      [] message.tag = DeaIndicatorCode -> EncodeDeaIndicator(message.body)
      [] message.tag = DisplayCode -> EncodeDisplay(message.body)
      [] message.tag = DisplayPriceCode -> EncodeDisplayPrice(message.body)
      [] message.tag = DisplayQuantityCode -> EncodeDisplayQuantity(message.body)
      [] message.tag = ExpireTimeCode -> EncodeExpireTime(message.body)
      [] message.tag = FirmCode -> EncodeFirm(message.body)
      [] message.tag = LiquidityProvisionIndicatorCode -> EncodeLiquidityProvisionIndicator(message.body)
      [] message.tag = MaxFloorCode -> EncodeMaxFloor(message.body)
      [] message.tag = MinimumQuantityCode -> EncodeMinimumQuantity(message.body)
      [] message.tag = OrderReferenceCode -> EncodeOrderReference(message.body)
      [] message.tag = OriginalOrderEntryDateCode -> EncodeOriginalOrderEntryDate(message.body)
      [] message.tag = OriginalOrderReferenceNumberCode -> EncodeOriginalOrderReferenceNumber(message.body)
      [] message.tag = PegDifferenceCode -> EncodePegDifference(message.body)
      [] message.tag = PegTypeCode -> EncodePegType(message.body)
      [] message.tag = RandomReserveCode -> EncodeRandomReserve(message.body)
      [] message.tag = SecondaryOrderReferenceNumberCode -> EncodeSecondaryOrderReferenceNumber(message.body)
      [] message.tag = StpActionCode -> EncodeStpAction(message.body)
      [] message.tag = StpLevelCode -> EncodeStpLevel(message.body)
      [] message.tag = StpTraderGroupCode -> EncodeStpTraderGroup(message.body)
      [] message.tag = TimeInForceCode -> EncodeTimeInForce(message.body)
      [] message.tag = TradingAtClosingPriceCode -> EncodeTradingAtClosingPrice(message.body)
      [] message.tag = OrderConditionCode -> EncodeOrderCondition(message.body)
      [] message.tag = CumulativeQuantityCode -> EncodeCumulativeQuantity(message.body)
      [] message.tag = CustomerOrderCapacityCode -> EncodeCustomerOrderCapacity(message.body)
      [] message.tag = TargetStrategyCode -> EncodeTargetStrategy(message.body)
      [] message.tag = MinRateCode -> EncodeMinRate(message.body)
      [] message.tag = MaxRateCode -> EncodeMaxRate(message.body)
      [] message.tag = ConditionalTypeCode -> EncodeConditionalType(message.body)
      [] message.tag = FirmUpIdCode -> EncodeFirmUpId(message.body)

DecodeValuePayload(tag, bytes) ==
    LET read ==
            CASE tag = ClearingAccountCode -> DecodeClearingAccount(bytes)
              [] tag = ClearingAccountTypeCode -> DecodeClearingAccountType(bytes)
              [] tag = ClearingFirmCode -> DecodeClearingFirm(bytes)
              [] tag = ClientReferenceCode -> DecodeClientReference(bytes)
              [] tag = CrossTypeCode -> DecodeCrossType(bytes)
              [] tag = DeaIndicatorCode -> DecodeDeaIndicator(bytes)
              [] tag = DisplayCode -> DecodeDisplay(bytes)
              [] tag = DisplayPriceCode -> DecodeDisplayPrice(bytes)
              [] tag = DisplayQuantityCode -> DecodeDisplayQuantity(bytes)
              [] tag = ExpireTimeCode -> DecodeExpireTime(bytes)
              [] tag = FirmCode -> DecodeFirm(bytes)
              [] tag = LiquidityProvisionIndicatorCode -> DecodeLiquidityProvisionIndicator(bytes)
              [] tag = MaxFloorCode -> DecodeMaxFloor(bytes)
              [] tag = MinimumQuantityCode -> DecodeMinimumQuantity(bytes)
              [] tag = OrderReferenceCode -> DecodeOrderReference(bytes)
              [] tag = OriginalOrderEntryDateCode -> DecodeOriginalOrderEntryDate(bytes)
              [] tag = OriginalOrderReferenceNumberCode -> DecodeOriginalOrderReferenceNumber(bytes)
              [] tag = PegDifferenceCode -> DecodePegDifference(bytes)
              [] tag = PegTypeCode -> DecodePegType(bytes)
              [] tag = RandomReserveCode -> DecodeRandomReserve(bytes)
              [] tag = SecondaryOrderReferenceNumberCode -> DecodeSecondaryOrderReferenceNumber(bytes)
              [] tag = StpActionCode -> DecodeStpAction(bytes)
              [] tag = StpLevelCode -> DecodeStpLevel(bytes)
              [] tag = StpTraderGroupCode -> DecodeStpTraderGroup(bytes)
              [] tag = TimeInForceCode -> DecodeTimeInForce(bytes)
              [] tag = TradingAtClosingPriceCode -> DecodeTradingAtClosingPrice(bytes)
              [] tag = OrderConditionCode -> DecodeOrderCondition(bytes)
              [] tag = CumulativeQuantityCode -> DecodeCumulativeQuantity(bytes)
              [] tag = CustomerOrderCapacityCode -> DecodeCustomerOrderCapacity(bytes)
              [] tag = TargetStrategyCode -> DecodeTargetStrategy(bytes)
              [] tag = MinRateCode -> DecodeMinRate(bytes)
              [] tag = MaxRateCode -> DecodeMaxRate(bytes)
              [] tag = ConditionalTypeCode -> DecodeConditionalType(bytes)
              [] tag = FirmUpIdCode -> DecodeFirmUpId(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroValuePayload == [tag |-> ClearingAccountCode, body |-> ZeroClearingAccount]

(* Each Value Payload in turn, at the values the message it names is checked at *)
CheckedValuePayload ==
    { [tag |-> ClearingAccountCode, body |-> one] : one \in CheckedClearingAccount }
        \cup { [tag |-> ClearingAccountTypeCode, body |-> one] : one \in CheckedClearingAccountType }
        \cup { [tag |-> ClearingFirmCode, body |-> one] : one \in CheckedClearingFirm }
        \cup { [tag |-> ClientReferenceCode, body |-> one] : one \in CheckedClientReference }
        \cup { [tag |-> CrossTypeCode, body |-> one] : one \in CheckedCrossType }
        \cup { [tag |-> DeaIndicatorCode, body |-> one] : one \in CheckedDeaIndicator }
        \cup { [tag |-> DisplayCode, body |-> one] : one \in CheckedDisplay }
        \cup { [tag |-> DisplayPriceCode, body |-> one] : one \in CheckedDisplayPrice }
        \cup { [tag |-> DisplayQuantityCode, body |-> one] : one \in CheckedDisplayQuantity }
        \cup { [tag |-> ExpireTimeCode, body |-> one] : one \in CheckedExpireTime }
        \cup { [tag |-> FirmCode, body |-> one] : one \in CheckedFirm }
        \cup { [tag |-> LiquidityProvisionIndicatorCode, body |-> one] : one \in CheckedLiquidityProvisionIndicator }
        \cup { [tag |-> MaxFloorCode, body |-> one] : one \in CheckedMaxFloor }
        \cup { [tag |-> MinimumQuantityCode, body |-> one] : one \in CheckedMinimumQuantity }
        \cup { [tag |-> OrderReferenceCode, body |-> one] : one \in CheckedOrderReference }
        \cup { [tag |-> OriginalOrderEntryDateCode, body |-> one] : one \in CheckedOriginalOrderEntryDate }
        \cup { [tag |-> OriginalOrderReferenceNumberCode, body |-> one] : one \in CheckedOriginalOrderReferenceNumber }
        \cup { [tag |-> PegDifferenceCode, body |-> one] : one \in CheckedPegDifference }
        \cup { [tag |-> PegTypeCode, body |-> one] : one \in CheckedPegType }
        \cup { [tag |-> RandomReserveCode, body |-> one] : one \in CheckedRandomReserve }
        \cup { [tag |-> SecondaryOrderReferenceNumberCode, body |-> one] : one \in CheckedSecondaryOrderReferenceNumber }
        \cup { [tag |-> StpActionCode, body |-> one] : one \in CheckedStpAction }
        \cup { [tag |-> StpLevelCode, body |-> one] : one \in CheckedStpLevel }
        \cup { [tag |-> StpTraderGroupCode, body |-> one] : one \in CheckedStpTraderGroup }
        \cup { [tag |-> TimeInForceCode, body |-> one] : one \in CheckedTimeInForce }
        \cup { [tag |-> TradingAtClosingPriceCode, body |-> one] : one \in CheckedTradingAtClosingPrice }
        \cup { [tag |-> OrderConditionCode, body |-> one] : one \in CheckedOrderCondition }
        \cup { [tag |-> CumulativeQuantityCode, body |-> one] : one \in CheckedCumulativeQuantity }
        \cup { [tag |-> CustomerOrderCapacityCode, body |-> one] : one \in CheckedCustomerOrderCapacity }
        \cup { [tag |-> TargetStrategyCode, body |-> one] : one \in CheckedTargetStrategy }
        \cup { [tag |-> MinRateCode, body |-> one] : one \in CheckedMinRate }
        \cup { [tag |-> MaxRateCode, body |-> one] : one \in CheckedMaxRate }
        \cup { [tag |-> ConditionalTypeCode, body |-> one] : one \in CheckedConditionalType }
        \cup { [tag |-> FirmUpIdCode, body |-> one] : one \in CheckedFirmUpId }

(***************************************************************************)
(* TagValue, framed by Length                                              *)
(***************************************************************************)

Tagvalue ==
    [ valuePayload : ValuePayload ]

EncodeTagvalueBody(message) ==
    EncodeUIntBE(message.valuePayload.tag, 1)
        \o EncodeValuePayload(message.valuePayload)

(* Length counts the bytes it frames, so it is written from them *)
EncodeTagvalue(message) ==
    LET body == EncodeTagvalueBody(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeTagvalueBody(bytes) ==
    LET tag == ReadUIntBE(bytes, 1) IN IF ~tag.ok THEN Fail ELSE
    LET valuePayload == DecodeValuePayload(tag.value, tag.rest) IN IF ~valuePayload.ok THEN Fail ELSE
    Ok([ valuePayload |-> valuePayload.value ], valuePayload.rest)

DecodeTagvalue(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeTagvalueBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroTagvalue ==
    [ valuePayload |-> ZeroValuePayload ]

(* TagValue at zero, then each field in turn at the values it is checked at *)
CheckedTagvalue ==
    { ZeroTagvalue }
        \cup { [ZeroTagvalue EXCEPT !.valuePayload = one] : one \in CheckedValuePayload }

(* A run of TagValue, written one after another *)
RECURSIVE EncodeTagvalueList(_)
EncodeTagvalueList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTagvalue(Head(messages)) \o EncodeTagvalueList(Tail(messages))

(* As many TagValue as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadTagvalueAll(_)
ReadTagvalueAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeTagvalue(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTagvalueAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One TagValue of each kind, for the lists that carry them *)
OneTagvalue ==
    { [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> ClearingAccountCode, body |-> ZeroClearingAccount]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> ClearingAccountTypeCode, body |-> ZeroClearingAccountType]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> ClearingFirmCode, body |-> ZeroClearingFirm]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> ClientReferenceCode, body |-> ZeroClientReference]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> CrossTypeCode, body |-> ZeroCrossType]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> DeaIndicatorCode, body |-> ZeroDeaIndicator]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> DisplayCode, body |-> ZeroDisplay]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> DisplayPriceCode, body |-> ZeroDisplayPrice]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> DisplayQuantityCode, body |-> ZeroDisplayQuantity]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> ExpireTimeCode, body |-> ZeroExpireTime]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> FirmCode, body |-> ZeroFirm]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> LiquidityProvisionIndicatorCode, body |-> ZeroLiquidityProvisionIndicator]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> MaxFloorCode, body |-> ZeroMaxFloor]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> MinimumQuantityCode, body |-> ZeroMinimumQuantity]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> OrderReferenceCode, body |-> ZeroOrderReference]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> OriginalOrderEntryDateCode, body |-> ZeroOriginalOrderEntryDate]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> OriginalOrderReferenceNumberCode, body |-> ZeroOriginalOrderReferenceNumber]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> PegDifferenceCode, body |-> ZeroPegDifference]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> PegTypeCode, body |-> ZeroPegType]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> RandomReserveCode, body |-> ZeroRandomReserve]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> SecondaryOrderReferenceNumberCode, body |-> ZeroSecondaryOrderReferenceNumber]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> StpActionCode, body |-> ZeroStpAction]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> StpLevelCode, body |-> ZeroStpLevel]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> StpTraderGroupCode, body |-> ZeroStpTraderGroup]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> TimeInForceCode, body |-> ZeroTimeInForce]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> TradingAtClosingPriceCode, body |-> ZeroTradingAtClosingPrice]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> OrderConditionCode, body |-> ZeroOrderCondition]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> CumulativeQuantityCode, body |-> ZeroCumulativeQuantity]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> CustomerOrderCapacityCode, body |-> ZeroCustomerOrderCapacity]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> TargetStrategyCode, body |-> ZeroTargetStrategy]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> MinRateCode, body |-> ZeroMinRate]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> MaxRateCode, body |-> ZeroMaxRate]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> ConditionalTypeCode, body |-> ZeroConditionalType]],
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> FirmUpIdCode, body |-> ZeroFirmUpId]] }

(***************************************************************************)
(* Order Accepted Message                                                  *)
(***************************************************************************)

OrderAcceptedMessage ==
    [ timestamp                             : Sample(8),
      userRefNum                            : Sample(4),
      price                                 : Sample(4),
      orderReferenceNumber                  : Sample(8),
      buySellIndicator                      : Sample(1),
      orderBook                             : Sample(4),
      quantity                              : Sample(4),
      user                                  : Sample(6),
      executionWithinFirm                   : Sample(4),
      investmentDecisionWithinFirmShortCode : Sample(4),
      clientIdentifier                      : Sample(4),
      partyRoleQualifier                    : Sample(1),
      capacity                              : Sample(1),
      algoIndicator                         : Sample(1),
      tagvalue                              : SampleLists(OneTagvalue) ]

EncodeOrderAcceptedMessage(message) ==
    LET payload == EncodeTagvalueList(message.tagvalue)
    IN  message.timestamp
            \o message.userRefNum
            \o message.price
            \o message.orderReferenceNumber
            \o message.buySellIndicator
            \o message.orderBook
            \o message.quantity
            \o message.user
            \o message.executionWithinFirm
            \o message.investmentDecisionWithinFirmShortCode
            \o message.clientIdentifier
            \o message.partyRoleQualifier
            \o message.capacity
            \o message.algoIndicator
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeOrderAcceptedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET price == ReadBytes(userRefNum.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(price.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET orderBook == ReadBytes(buySellIndicator.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBook.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET user == ReadBytes(quantity.rest, 6) IN IF ~user.ok THEN Fail ELSE
    LET executionWithinFirm == ReadBytes(user.rest, 4) IN IF ~executionWithinFirm.ok THEN Fail ELSE
    LET investmentDecisionWithinFirmShortCode == ReadBytes(executionWithinFirm.rest, 4) IN IF ~investmentDecisionWithinFirmShortCode.ok THEN Fail ELSE
    LET clientIdentifier == ReadBytes(investmentDecisionWithinFirmShortCode.rest, 4) IN IF ~clientIdentifier.ok THEN Fail ELSE
    LET partyRoleQualifier == ReadBytes(clientIdentifier.rest, 1) IN IF ~partyRoleQualifier.ok THEN Fail ELSE
    LET capacity == ReadBytes(partyRoleQualifier.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET algoIndicator == ReadBytes(capacity.rest, 1) IN IF ~algoIndicator.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(algoIndicator.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        tagvalue == ReadTagvalueAll(framed)
    IN  IF ~tagvalue.ok \/ tagvalue.rest # << >> THEN Fail ELSE
    Ok([ timestamp                             |-> timestamp.value,
         userRefNum                            |-> userRefNum.value,
         price                                 |-> price.value,
         orderReferenceNumber                  |-> orderReferenceNumber.value,
         buySellIndicator                      |-> buySellIndicator.value,
         orderBook                             |-> orderBook.value,
         quantity                              |-> quantity.value,
         user                                  |-> user.value,
         executionWithinFirm                   |-> executionWithinFirm.value,
         investmentDecisionWithinFirmShortCode |-> investmentDecisionWithinFirmShortCode.value,
         clientIdentifier                      |-> clientIdentifier.value,
         partyRoleQualifier                    |-> partyRoleQualifier.value,
         capacity                              |-> capacity.value,
         algoIndicator                         |-> algoIndicator.value,
         tagvalue                              |-> tagvalue.value ], beyond)

ZeroOrderAcceptedMessage ==
    [ timestamp                             |-> [i \in 1 .. 8 |-> 0],
      userRefNum                            |-> [i \in 1 .. 4 |-> 0],
      price                                 |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber                  |-> [i \in 1 .. 8 |-> 0],
      buySellIndicator                      |-> [i \in 1 .. 1 |-> 0],
      orderBook                             |-> [i \in 1 .. 4 |-> 0],
      quantity                              |-> [i \in 1 .. 4 |-> 0],
      user                                  |-> [i \in 1 .. 6 |-> 0],
      executionWithinFirm                   |-> [i \in 1 .. 4 |-> 0],
      investmentDecisionWithinFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      clientIdentifier                      |-> [i \in 1 .. 4 |-> 0],
      partyRoleQualifier                    |-> [i \in 1 .. 1 |-> 0],
      capacity                              |-> [i \in 1 .. 1 |-> 0],
      algoIndicator                         |-> [i \in 1 .. 1 |-> 0],
      tagvalue                              |-> << >> ]

(* Order Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAcceptedMessage ==
    { ZeroOrderAcceptedMessage }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.user = one] : one \in Sample(6) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.executionWithinFirm = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.investmentDecisionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.clientIdentifier = one] : one \in Sample(4) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.partyRoleQualifier = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.algoIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderAcceptedMessage EXCEPT !.tagvalue = one] : one \in SampleLists(OneTagvalue) }

(***************************************************************************)
(* Clearing Account: 12 bytes                                              *)
(***************************************************************************)

ClearingAccount2 ==
    [ clearingAccountValue : Sample(12) ]

EncodeClearingAccount2(message) ==
    message.clearingAccountValue

DecodeClearingAccount2(bytes) ==
    LET clearingAccountValue == ReadBytes(bytes, 12) IN IF ~clearingAccountValue.ok THEN Fail ELSE
    Ok([ clearingAccountValue |-> clearingAccountValue.value ], clearingAccountValue.rest)

ZeroClearingAccount2 ==
    [ clearingAccountValue |-> [i \in 1 .. 12 |-> 0] ]

(* Clearing Account at zero, then each field in turn at the values it is checked at *)
CheckedClearingAccount2 ==
    { ZeroClearingAccount2 }
        \cup { [ZeroClearingAccount2 EXCEPT !.clearingAccountValue = one] : one \in Sample(12) }

(***************************************************************************)
(* Clearing Account Type: 1 bytes                                          *)
(***************************************************************************)

ClearingAccountType2 ==
    [ clearingAccountTypeValue : Sample(1) ]

EncodeClearingAccountType2(message) ==
    message.clearingAccountTypeValue

DecodeClearingAccountType2(bytes) ==
    LET clearingAccountTypeValue == ReadBytes(bytes, 1) IN IF ~clearingAccountTypeValue.ok THEN Fail ELSE
    Ok([ clearingAccountTypeValue |-> clearingAccountTypeValue.value ], clearingAccountTypeValue.rest)

ZeroClearingAccountType2 ==
    [ clearingAccountTypeValue |-> [i \in 1 .. 1 |-> 0] ]

(* Clearing Account Type at zero, then each field in turn at the values it is checked at *)
CheckedClearingAccountType2 ==
    { ZeroClearingAccountType2 }
        \cup { [ZeroClearingAccountType2 EXCEPT !.clearingAccountTypeValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Clearing Firm: 4 bytes                                                  *)
(***************************************************************************)

ClearingFirm2 ==
    [ clearingFirmValue : Sample(4) ]

EncodeClearingFirm2(message) ==
    message.clearingFirmValue

DecodeClearingFirm2(bytes) ==
    LET clearingFirmValue == ReadBytes(bytes, 4) IN IF ~clearingFirmValue.ok THEN Fail ELSE
    Ok([ clearingFirmValue |-> clearingFirmValue.value ], clearingFirmValue.rest)

ZeroClearingFirm2 ==
    [ clearingFirmValue |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Firm at zero, then each field in turn at the values it is checked at *)
CheckedClearingFirm2 ==
    { ZeroClearingFirm2 }
        \cup { [ZeroClearingFirm2 EXCEPT !.clearingFirmValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Client Reference: 15 bytes                                              *)
(***************************************************************************)

ClientReference2 ==
    [ clientReferenceValue : Sample(15) ]

EncodeClientReference2(message) ==
    message.clientReferenceValue

DecodeClientReference2(bytes) ==
    LET clientReferenceValue == ReadBytes(bytes, 15) IN IF ~clientReferenceValue.ok THEN Fail ELSE
    Ok([ clientReferenceValue |-> clientReferenceValue.value ], clientReferenceValue.rest)

ZeroClientReference2 ==
    [ clientReferenceValue |-> [i \in 1 .. 15 |-> 0] ]

(* Client Reference at zero, then each field in turn at the values it is checked at *)
CheckedClientReference2 ==
    { ZeroClientReference2 }
        \cup { [ZeroClientReference2 EXCEPT !.clientReferenceValue = one] : one \in Sample(15) }

(***************************************************************************)
(* Cross Type: 1 bytes                                                     *)
(***************************************************************************)

CrossType2 ==
    [ crossTypeValue : Sample(1) ]

EncodeCrossType2(message) ==
    message.crossTypeValue

DecodeCrossType2(bytes) ==
    LET crossTypeValue == ReadBytes(bytes, 1) IN IF ~crossTypeValue.ok THEN Fail ELSE
    Ok([ crossTypeValue |-> crossTypeValue.value ], crossTypeValue.rest)

ZeroCrossType2 ==
    [ crossTypeValue |-> [i \in 1 .. 1 |-> 0] ]

(* Cross Type at zero, then each field in turn at the values it is checked at *)
CheckedCrossType2 ==
    { ZeroCrossType2 }
        \cup { [ZeroCrossType2 EXCEPT !.crossTypeValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Dea Indicator: 1 bytes                                                  *)
(***************************************************************************)

DeaIndicator2 ==
    [ deaIndicatorValue : Sample(1) ]

EncodeDeaIndicator2(message) ==
    message.deaIndicatorValue

DecodeDeaIndicator2(bytes) ==
    LET deaIndicatorValue == ReadBytes(bytes, 1) IN IF ~deaIndicatorValue.ok THEN Fail ELSE
    Ok([ deaIndicatorValue |-> deaIndicatorValue.value ], deaIndicatorValue.rest)

ZeroDeaIndicator2 ==
    [ deaIndicatorValue |-> [i \in 1 .. 1 |-> 0] ]

(* Dea Indicator at zero, then each field in turn at the values it is checked at *)
CheckedDeaIndicator2 ==
    { ZeroDeaIndicator2 }
        \cup { [ZeroDeaIndicator2 EXCEPT !.deaIndicatorValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Display: 1 bytes                                                        *)
(***************************************************************************)

Display2 ==
    [ displayValue : Sample(1) ]

EncodeDisplay2(message) ==
    message.displayValue

DecodeDisplay2(bytes) ==
    LET displayValue == ReadBytes(bytes, 1) IN IF ~displayValue.ok THEN Fail ELSE
    Ok([ displayValue |-> displayValue.value ], displayValue.rest)

ZeroDisplay2 ==
    [ displayValue |-> [i \in 1 .. 1 |-> 0] ]

(* Display at zero, then each field in turn at the values it is checked at *)
CheckedDisplay2 ==
    { ZeroDisplay2 }
        \cup { [ZeroDisplay2 EXCEPT !.displayValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Display Price: 4 bytes                                                  *)
(***************************************************************************)

DisplayPrice2 ==
    [ displayPriceValue : Sample(4) ]

EncodeDisplayPrice2(message) ==
    message.displayPriceValue

DecodeDisplayPrice2(bytes) ==
    LET displayPriceValue == ReadBytes(bytes, 4) IN IF ~displayPriceValue.ok THEN Fail ELSE
    Ok([ displayPriceValue |-> displayPriceValue.value ], displayPriceValue.rest)

ZeroDisplayPrice2 ==
    [ displayPriceValue |-> [i \in 1 .. 4 |-> 0] ]

(* Display Price at zero, then each field in turn at the values it is checked at *)
CheckedDisplayPrice2 ==
    { ZeroDisplayPrice2 }
        \cup { [ZeroDisplayPrice2 EXCEPT !.displayPriceValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Display Quantity: 4 bytes                                               *)
(***************************************************************************)

DisplayQuantity2 ==
    [ displayQuantityValue : Sample(4) ]

EncodeDisplayQuantity2(message) ==
    message.displayQuantityValue

DecodeDisplayQuantity2(bytes) ==
    LET displayQuantityValue == ReadBytes(bytes, 4) IN IF ~displayQuantityValue.ok THEN Fail ELSE
    Ok([ displayQuantityValue |-> displayQuantityValue.value ], displayQuantityValue.rest)

ZeroDisplayQuantity2 ==
    [ displayQuantityValue |-> [i \in 1 .. 4 |-> 0] ]

(* Display Quantity at zero, then each field in turn at the values it is checked at *)
CheckedDisplayQuantity2 ==
    { ZeroDisplayQuantity2 }
        \cup { [ZeroDisplayQuantity2 EXCEPT !.displayQuantityValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Expire Time: 2 bytes                                                    *)
(***************************************************************************)

ExpireTime2 ==
    [ expireTimeValue : Sample(2) ]

EncodeExpireTime2(message) ==
    message.expireTimeValue

DecodeExpireTime2(bytes) ==
    LET expireTimeValue == ReadBytes(bytes, 2) IN IF ~expireTimeValue.ok THEN Fail ELSE
    Ok([ expireTimeValue |-> expireTimeValue.value ], expireTimeValue.rest)

ZeroExpireTime2 ==
    [ expireTimeValue |-> [i \in 1 .. 2 |-> 0] ]

(* Expire Time at zero, then each field in turn at the values it is checked at *)
CheckedExpireTime2 ==
    { ZeroExpireTime2 }
        \cup { [ZeroExpireTime2 EXCEPT !.expireTimeValue = one] : one \in Sample(2) }

(***************************************************************************)
(* Firm: 4 bytes                                                           *)
(***************************************************************************)

Firm2 ==
    [ firmValue : Sample(4) ]

EncodeFirm2(message) ==
    message.firmValue

DecodeFirm2(bytes) ==
    LET firmValue == ReadBytes(bytes, 4) IN IF ~firmValue.ok THEN Fail ELSE
    Ok([ firmValue |-> firmValue.value ], firmValue.rest)

ZeroFirm2 ==
    [ firmValue |-> [i \in 1 .. 4 |-> 0] ]

(* Firm at zero, then each field in turn at the values it is checked at *)
CheckedFirm2 ==
    { ZeroFirm2 }
        \cup { [ZeroFirm2 EXCEPT !.firmValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Liquidity Provision Indicator: 1 bytes                                  *)
(***************************************************************************)

LiquidityProvisionIndicator2 ==
    [ liquidityProvisionIndicatorValue : Sample(1) ]

EncodeLiquidityProvisionIndicator2(message) ==
    message.liquidityProvisionIndicatorValue

DecodeLiquidityProvisionIndicator2(bytes) ==
    LET liquidityProvisionIndicatorValue == ReadBytes(bytes, 1) IN IF ~liquidityProvisionIndicatorValue.ok THEN Fail ELSE
    Ok([ liquidityProvisionIndicatorValue |-> liquidityProvisionIndicatorValue.value ], liquidityProvisionIndicatorValue.rest)

ZeroLiquidityProvisionIndicator2 ==
    [ liquidityProvisionIndicatorValue |-> [i \in 1 .. 1 |-> 0] ]

(* Liquidity Provision Indicator at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityProvisionIndicator2 ==
    { ZeroLiquidityProvisionIndicator2 }
        \cup { [ZeroLiquidityProvisionIndicator2 EXCEPT !.liquidityProvisionIndicatorValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Max Floor: 4 bytes                                                      *)
(***************************************************************************)

MaxFloor2 ==
    [ maxFloorValue : Sample(4) ]

EncodeMaxFloor2(message) ==
    message.maxFloorValue

DecodeMaxFloor2(bytes) ==
    LET maxFloorValue == ReadBytes(bytes, 4) IN IF ~maxFloorValue.ok THEN Fail ELSE
    Ok([ maxFloorValue |-> maxFloorValue.value ], maxFloorValue.rest)

ZeroMaxFloor2 ==
    [ maxFloorValue |-> [i \in 1 .. 4 |-> 0] ]

(* Max Floor at zero, then each field in turn at the values it is checked at *)
CheckedMaxFloor2 ==
    { ZeroMaxFloor2 }
        \cup { [ZeroMaxFloor2 EXCEPT !.maxFloorValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Minimum Quantity: 4 bytes                                               *)
(***************************************************************************)

MinimumQuantity2 ==
    [ minimumQuantityValue : Sample(4) ]

EncodeMinimumQuantity2(message) ==
    message.minimumQuantityValue

DecodeMinimumQuantity2(bytes) ==
    LET minimumQuantityValue == ReadBytes(bytes, 4) IN IF ~minimumQuantityValue.ok THEN Fail ELSE
    Ok([ minimumQuantityValue |-> minimumQuantityValue.value ], minimumQuantityValue.rest)

ZeroMinimumQuantity2 ==
    [ minimumQuantityValue |-> [i \in 1 .. 4 |-> 0] ]

(* Minimum Quantity at zero, then each field in turn at the values it is checked at *)
CheckedMinimumQuantity2 ==
    { ZeroMinimumQuantity2 }
        \cup { [ZeroMinimumQuantity2 EXCEPT !.minimumQuantityValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Reference: 10 bytes                                               *)
(***************************************************************************)

OrderReference2 ==
    [ orderReferenceValue : Sample(10) ]

EncodeOrderReference2(message) ==
    message.orderReferenceValue

DecodeOrderReference2(bytes) ==
    LET orderReferenceValue == ReadBytes(bytes, 10) IN IF ~orderReferenceValue.ok THEN Fail ELSE
    Ok([ orderReferenceValue |-> orderReferenceValue.value ], orderReferenceValue.rest)

ZeroOrderReference2 ==
    [ orderReferenceValue |-> [i \in 1 .. 10 |-> 0] ]

(* Order Reference at zero, then each field in turn at the values it is checked at *)
CheckedOrderReference2 ==
    { ZeroOrderReference2 }
        \cup { [ZeroOrderReference2 EXCEPT !.orderReferenceValue = one] : one \in Sample(10) }

(***************************************************************************)
(* Original Order Entry Date: 4 bytes                                      *)
(***************************************************************************)

OriginalOrderEntryDate2 ==
    [ originalOrderEntryDateValue : Sample(4) ]

EncodeOriginalOrderEntryDate2(message) ==
    message.originalOrderEntryDateValue

DecodeOriginalOrderEntryDate2(bytes) ==
    LET originalOrderEntryDateValue == ReadBytes(bytes, 4) IN IF ~originalOrderEntryDateValue.ok THEN Fail ELSE
    Ok([ originalOrderEntryDateValue |-> originalOrderEntryDateValue.value ], originalOrderEntryDateValue.rest)

ZeroOriginalOrderEntryDate2 ==
    [ originalOrderEntryDateValue |-> [i \in 1 .. 4 |-> 0] ]

(* Original Order Entry Date at zero, then each field in turn at the values it is checked at *)
CheckedOriginalOrderEntryDate2 ==
    { ZeroOriginalOrderEntryDate2 }
        \cup { [ZeroOriginalOrderEntryDate2 EXCEPT !.originalOrderEntryDateValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Original Order Reference Number: 8 bytes                                *)
(***************************************************************************)

OriginalOrderReferenceNumber2 ==
    [ originalOrderReferenceNumberValue : Sample(8) ]

EncodeOriginalOrderReferenceNumber2(message) ==
    message.originalOrderReferenceNumberValue

DecodeOriginalOrderReferenceNumber2(bytes) ==
    LET originalOrderReferenceNumberValue == ReadBytes(bytes, 8) IN IF ~originalOrderReferenceNumberValue.ok THEN Fail ELSE
    Ok([ originalOrderReferenceNumberValue |-> originalOrderReferenceNumberValue.value ], originalOrderReferenceNumberValue.rest)

ZeroOriginalOrderReferenceNumber2 ==
    [ originalOrderReferenceNumberValue |-> [i \in 1 .. 8 |-> 0] ]

(* Original Order Reference Number at zero, then each field in turn at the values it is checked at *)
CheckedOriginalOrderReferenceNumber2 ==
    { ZeroOriginalOrderReferenceNumber2 }
        \cup { [ZeroOriginalOrderReferenceNumber2 EXCEPT !.originalOrderReferenceNumberValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Peg Difference: 4 bytes                                                 *)
(***************************************************************************)

PegDifference2 ==
    [ pegDifferenceValue : Sample(4) ]

EncodePegDifference2(message) ==
    message.pegDifferenceValue

DecodePegDifference2(bytes) ==
    LET pegDifferenceValue == ReadBytes(bytes, 4) IN IF ~pegDifferenceValue.ok THEN Fail ELSE
    Ok([ pegDifferenceValue |-> pegDifferenceValue.value ], pegDifferenceValue.rest)

ZeroPegDifference2 ==
    [ pegDifferenceValue |-> [i \in 1 .. 4 |-> 0] ]

(* Peg Difference at zero, then each field in turn at the values it is checked at *)
CheckedPegDifference2 ==
    { ZeroPegDifference2 }
        \cup { [ZeroPegDifference2 EXCEPT !.pegDifferenceValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Peg Type: 1 bytes                                                       *)
(***************************************************************************)

PegType2 ==
    [ pegTypeValue : Sample(1) ]

EncodePegType2(message) ==
    message.pegTypeValue

DecodePegType2(bytes) ==
    LET pegTypeValue == ReadBytes(bytes, 1) IN IF ~pegTypeValue.ok THEN Fail ELSE
    Ok([ pegTypeValue |-> pegTypeValue.value ], pegTypeValue.rest)

ZeroPegType2 ==
    [ pegTypeValue |-> [i \in 1 .. 1 |-> 0] ]

(* Peg Type at zero, then each field in turn at the values it is checked at *)
CheckedPegType2 ==
    { ZeroPegType2 }
        \cup { [ZeroPegType2 EXCEPT !.pegTypeValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Random Reserve: 4 bytes                                                 *)
(***************************************************************************)

RandomReserve2 ==
    [ randomReserveValue : Sample(4) ]

EncodeRandomReserve2(message) ==
    message.randomReserveValue

DecodeRandomReserve2(bytes) ==
    LET randomReserveValue == ReadBytes(bytes, 4) IN IF ~randomReserveValue.ok THEN Fail ELSE
    Ok([ randomReserveValue |-> randomReserveValue.value ], randomReserveValue.rest)

ZeroRandomReserve2 ==
    [ randomReserveValue |-> [i \in 1 .. 4 |-> 0] ]

(* Random Reserve at zero, then each field in turn at the values it is checked at *)
CheckedRandomReserve2 ==
    { ZeroRandomReserve2 }
        \cup { [ZeroRandomReserve2 EXCEPT !.randomReserveValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Secondary Order Reference Number: 8 bytes                               *)
(***************************************************************************)

SecondaryOrderReferenceNumber2 ==
    [ secondaryOrderReferenceNumberValue : Sample(8) ]

EncodeSecondaryOrderReferenceNumber2(message) ==
    message.secondaryOrderReferenceNumberValue

DecodeSecondaryOrderReferenceNumber2(bytes) ==
    LET secondaryOrderReferenceNumberValue == ReadBytes(bytes, 8) IN IF ~secondaryOrderReferenceNumberValue.ok THEN Fail ELSE
    Ok([ secondaryOrderReferenceNumberValue |-> secondaryOrderReferenceNumberValue.value ], secondaryOrderReferenceNumberValue.rest)

ZeroSecondaryOrderReferenceNumber2 ==
    [ secondaryOrderReferenceNumberValue |-> [i \in 1 .. 8 |-> 0] ]

(* Secondary Order Reference Number at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryOrderReferenceNumber2 ==
    { ZeroSecondaryOrderReferenceNumber2 }
        \cup { [ZeroSecondaryOrderReferenceNumber2 EXCEPT !.secondaryOrderReferenceNumberValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Stp Action: 1 bytes                                                     *)
(***************************************************************************)

StpAction2 ==
    [ stpActionValue : Sample(1) ]

EncodeStpAction2(message) ==
    message.stpActionValue

DecodeStpAction2(bytes) ==
    LET stpActionValue == ReadBytes(bytes, 1) IN IF ~stpActionValue.ok THEN Fail ELSE
    Ok([ stpActionValue |-> stpActionValue.value ], stpActionValue.rest)

ZeroStpAction2 ==
    [ stpActionValue |-> [i \in 1 .. 1 |-> 0] ]

(* Stp Action at zero, then each field in turn at the values it is checked at *)
CheckedStpAction2 ==
    { ZeroStpAction2 }
        \cup { [ZeroStpAction2 EXCEPT !.stpActionValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Stp Level: 1 bytes                                                      *)
(***************************************************************************)

StpLevel2 ==
    [ stpLevelValue : Sample(1) ]

EncodeStpLevel2(message) ==
    message.stpLevelValue

DecodeStpLevel2(bytes) ==
    LET stpLevelValue == ReadBytes(bytes, 1) IN IF ~stpLevelValue.ok THEN Fail ELSE
    Ok([ stpLevelValue |-> stpLevelValue.value ], stpLevelValue.rest)

ZeroStpLevel2 ==
    [ stpLevelValue |-> [i \in 1 .. 1 |-> 0] ]

(* Stp Level at zero, then each field in turn at the values it is checked at *)
CheckedStpLevel2 ==
    { ZeroStpLevel2 }
        \cup { [ZeroStpLevel2 EXCEPT !.stpLevelValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Stp Trader Group: 2 bytes                                               *)
(***************************************************************************)

StpTraderGroup2 ==
    [ stpTraderGroupValue : Sample(2) ]

EncodeStpTraderGroup2(message) ==
    message.stpTraderGroupValue

DecodeStpTraderGroup2(bytes) ==
    LET stpTraderGroupValue == ReadBytes(bytes, 2) IN IF ~stpTraderGroupValue.ok THEN Fail ELSE
    Ok([ stpTraderGroupValue |-> stpTraderGroupValue.value ], stpTraderGroupValue.rest)

ZeroStpTraderGroup2 ==
    [ stpTraderGroupValue |-> [i \in 1 .. 2 |-> 0] ]

(* Stp Trader Group at zero, then each field in turn at the values it is checked at *)
CheckedStpTraderGroup2 ==
    { ZeroStpTraderGroup2 }
        \cup { [ZeroStpTraderGroup2 EXCEPT !.stpTraderGroupValue = one] : one \in Sample(2) }

(***************************************************************************)
(* Time In Force: 1 bytes                                                  *)
(***************************************************************************)

TimeInForce2 ==
    [ timeInForceValue : Sample(1) ]

EncodeTimeInForce2(message) ==
    message.timeInForceValue

DecodeTimeInForce2(bytes) ==
    LET timeInForceValue == ReadBytes(bytes, 1) IN IF ~timeInForceValue.ok THEN Fail ELSE
    Ok([ timeInForceValue |-> timeInForceValue.value ], timeInForceValue.rest)

ZeroTimeInForce2 ==
    [ timeInForceValue |-> [i \in 1 .. 1 |-> 0] ]

(* Time In Force at zero, then each field in turn at the values it is checked at *)
CheckedTimeInForce2 ==
    { ZeroTimeInForce2 }
        \cup { [ZeroTimeInForce2 EXCEPT !.timeInForceValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading At Closing Price: 1 bytes                                       *)
(***************************************************************************)

TradingAtClosingPrice2 ==
    [ tradingAtClosingPriceValue : Sample(1) ]

EncodeTradingAtClosingPrice2(message) ==
    message.tradingAtClosingPriceValue

DecodeTradingAtClosingPrice2(bytes) ==
    LET tradingAtClosingPriceValue == ReadBytes(bytes, 1) IN IF ~tradingAtClosingPriceValue.ok THEN Fail ELSE
    Ok([ tradingAtClosingPriceValue |-> tradingAtClosingPriceValue.value ], tradingAtClosingPriceValue.rest)

ZeroTradingAtClosingPrice2 ==
    [ tradingAtClosingPriceValue |-> [i \in 1 .. 1 |-> 0] ]

(* Trading At Closing Price at zero, then each field in turn at the values it is checked at *)
CheckedTradingAtClosingPrice2 ==
    { ZeroTradingAtClosingPrice2 }
        \cup { [ZeroTradingAtClosingPrice2 EXCEPT !.tradingAtClosingPriceValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Condition: 1 bytes                                                *)
(***************************************************************************)

OrderCondition2 ==
    [ orderConditionValue : Sample(1) ]

EncodeOrderCondition2(message) ==
    message.orderConditionValue

DecodeOrderCondition2(bytes) ==
    LET orderConditionValue == ReadBytes(bytes, 1) IN IF ~orderConditionValue.ok THEN Fail ELSE
    Ok([ orderConditionValue |-> orderConditionValue.value ], orderConditionValue.rest)

ZeroOrderCondition2 ==
    [ orderConditionValue |-> [i \in 1 .. 1 |-> 0] ]

(* Order Condition at zero, then each field in turn at the values it is checked at *)
CheckedOrderCondition2 ==
    { ZeroOrderCondition2 }
        \cup { [ZeroOrderCondition2 EXCEPT !.orderConditionValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Cumulative Quantity: 4 bytes                                            *)
(***************************************************************************)

CumulativeQuantity2 ==
    [ cumulativeQuantityValue : Sample(4) ]

EncodeCumulativeQuantity2(message) ==
    message.cumulativeQuantityValue

DecodeCumulativeQuantity2(bytes) ==
    LET cumulativeQuantityValue == ReadBytes(bytes, 4) IN IF ~cumulativeQuantityValue.ok THEN Fail ELSE
    Ok([ cumulativeQuantityValue |-> cumulativeQuantityValue.value ], cumulativeQuantityValue.rest)

ZeroCumulativeQuantity2 ==
    [ cumulativeQuantityValue |-> [i \in 1 .. 4 |-> 0] ]

(* Cumulative Quantity at zero, then each field in turn at the values it is checked at *)
CheckedCumulativeQuantity2 ==
    { ZeroCumulativeQuantity2 }
        \cup { [ZeroCumulativeQuantity2 EXCEPT !.cumulativeQuantityValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Customer Order Capacity: 1 bytes                                        *)
(***************************************************************************)

CustomerOrderCapacity2 ==
    [ customerOrderCapacityValue : Sample(1) ]

EncodeCustomerOrderCapacity2(message) ==
    message.customerOrderCapacityValue

DecodeCustomerOrderCapacity2(bytes) ==
    LET customerOrderCapacityValue == ReadBytes(bytes, 1) IN IF ~customerOrderCapacityValue.ok THEN Fail ELSE
    Ok([ customerOrderCapacityValue |-> customerOrderCapacityValue.value ], customerOrderCapacityValue.rest)

ZeroCustomerOrderCapacity2 ==
    [ customerOrderCapacityValue |-> [i \in 1 .. 1 |-> 0] ]

(* Customer Order Capacity at zero, then each field in turn at the values it is checked at *)
CheckedCustomerOrderCapacity2 ==
    { ZeroCustomerOrderCapacity2 }
        \cup { [ZeroCustomerOrderCapacity2 EXCEPT !.customerOrderCapacityValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Target Strategy: 1 bytes                                                *)
(***************************************************************************)

TargetStrategy2 ==
    [ targetStrategyValue : Sample(1) ]

EncodeTargetStrategy2(message) ==
    message.targetStrategyValue

DecodeTargetStrategy2(bytes) ==
    LET targetStrategyValue == ReadBytes(bytes, 1) IN IF ~targetStrategyValue.ok THEN Fail ELSE
    Ok([ targetStrategyValue |-> targetStrategyValue.value ], targetStrategyValue.rest)

ZeroTargetStrategy2 ==
    [ targetStrategyValue |-> [i \in 1 .. 1 |-> 0] ]

(* Target Strategy at zero, then each field in turn at the values it is checked at *)
CheckedTargetStrategy2 ==
    { ZeroTargetStrategy2 }
        \cup { [ZeroTargetStrategy2 EXCEPT !.targetStrategyValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Min Rate: 2 bytes                                                       *)
(***************************************************************************)

MinRate2 ==
    [ minRateValue : Sample(2) ]

EncodeMinRate2(message) ==
    message.minRateValue

DecodeMinRate2(bytes) ==
    LET minRateValue == ReadBytes(bytes, 2) IN IF ~minRateValue.ok THEN Fail ELSE
    Ok([ minRateValue |-> minRateValue.value ], minRateValue.rest)

ZeroMinRate2 ==
    [ minRateValue |-> [i \in 1 .. 2 |-> 0] ]

(* Min Rate at zero, then each field in turn at the values it is checked at *)
CheckedMinRate2 ==
    { ZeroMinRate2 }
        \cup { [ZeroMinRate2 EXCEPT !.minRateValue = one] : one \in Sample(2) }

(***************************************************************************)
(* Max Rate: 2 bytes                                                       *)
(***************************************************************************)

MaxRate2 ==
    [ maxRateValue : Sample(2) ]

EncodeMaxRate2(message) ==
    message.maxRateValue

DecodeMaxRate2(bytes) ==
    LET maxRateValue == ReadBytes(bytes, 2) IN IF ~maxRateValue.ok THEN Fail ELSE
    Ok([ maxRateValue |-> maxRateValue.value ], maxRateValue.rest)

ZeroMaxRate2 ==
    [ maxRateValue |-> [i \in 1 .. 2 |-> 0] ]

(* Max Rate at zero, then each field in turn at the values it is checked at *)
CheckedMaxRate2 ==
    { ZeroMaxRate2 }
        \cup { [ZeroMaxRate2 EXCEPT !.maxRateValue = one] : one \in Sample(2) }

(***************************************************************************)
(* Conditional Type: 1 bytes                                               *)
(***************************************************************************)

ConditionalType2 ==
    [ conditionalTypeValue : Sample(1) ]

EncodeConditionalType2(message) ==
    message.conditionalTypeValue

DecodeConditionalType2(bytes) ==
    LET conditionalTypeValue == ReadBytes(bytes, 1) IN IF ~conditionalTypeValue.ok THEN Fail ELSE
    Ok([ conditionalTypeValue |-> conditionalTypeValue.value ], conditionalTypeValue.rest)

ZeroConditionalType2 ==
    [ conditionalTypeValue |-> [i \in 1 .. 1 |-> 0] ]

(* Conditional Type at zero, then each field in turn at the values it is checked at *)
CheckedConditionalType2 ==
    { ZeroConditionalType2 }
        \cup { [ZeroConditionalType2 EXCEPT !.conditionalTypeValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Firm Up Id: 4 bytes                                                     *)
(***************************************************************************)

FirmUpId2 ==
    [ firmUpIdValue : Sample(4) ]

EncodeFirmUpId2(message) ==
    message.firmUpIdValue

DecodeFirmUpId2(bytes) ==
    LET firmUpIdValue == ReadBytes(bytes, 4) IN IF ~firmUpIdValue.ok THEN Fail ELSE
    Ok([ firmUpIdValue |-> firmUpIdValue.value ], firmUpIdValue.rest)

ZeroFirmUpId2 ==
    [ firmUpIdValue |-> [i \in 1 .. 4 |-> 0] ]

(* Firm Up Id at zero, then each field in turn at the values it is checked at *)
CheckedFirmUpId2 ==
    { ZeroFirmUpId2 }
        \cup { [ZeroFirmUpId2 EXCEPT !.firmUpIdValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Value Payload, selected by Tag                                          *)
(***************************************************************************)

ClearingAccountCode2 == 1  \* 0x01
ClearingAccountTypeCode2 == 2  \* 0x02
ClearingFirmCode2 == 3  \* 0x03
ClientReferenceCode2 == 4  \* 0x04
CrossTypeCode2 == 5  \* 0x05
DeaIndicatorCode2 == 6  \* 0x06
DisplayCode2 == 7  \* 0x07
DisplayPriceCode2 == 8  \* 0x08
DisplayQuantityCode2 == 9  \* 0x09
ExpireTimeCode2 == 10  \* 0x0a
FirmCode2 == 11  \* 0x0b
LiquidityProvisionIndicatorCode2 == 12  \* 0x0c
MaxFloorCode2 == 13  \* 0x0d
MinimumQuantityCode2 == 14  \* 0x0e
OrderReferenceCode2 == 15  \* 0x0f
OriginalOrderEntryDateCode2 == 16  \* 0x10
OriginalOrderReferenceNumberCode2 == 17  \* 0x11
PegDifferenceCode2 == 18  \* 0x12
PegTypeCode2 == 19  \* 0x13
RandomReserveCode2 == 20  \* 0x14
SecondaryOrderReferenceNumberCode2 == 21  \* 0x15
StpActionCode2 == 22  \* 0x16
StpLevelCode2 == 23  \* 0x17
StpTraderGroupCode2 == 24  \* 0x18
TimeInForceCode2 == 25  \* 0x19
TradingAtClosingPriceCode2 == 26  \* 0x1a
OrderConditionCode2 == 27  \* 0x1b
CumulativeQuantityCode2 == 28  \* 0x1c
CustomerOrderCapacityCode2 == 29  \* 0x1d
TargetStrategyCode2 == 30  \* 0x1e
MinRateCode2 == 31  \* 0x1f
MaxRateCode2 == 32  \* 0x20
ConditionalTypeCode2 == 33  \* 0x21
FirmUpIdCode2 == 34  \* 0x22

ValuePayload2 ==
    [ tag : {ClearingAccountCode2}, body : ClearingAccount2 ]
        \cup [ tag : {ClearingAccountTypeCode2}, body : ClearingAccountType2 ]
        \cup [ tag : {ClearingFirmCode2}, body : ClearingFirm2 ]
        \cup [ tag : {ClientReferenceCode2}, body : ClientReference2 ]
        \cup [ tag : {CrossTypeCode2}, body : CrossType2 ]
        \cup [ tag : {DeaIndicatorCode2}, body : DeaIndicator2 ]
        \cup [ tag : {DisplayCode2}, body : Display2 ]
        \cup [ tag : {DisplayPriceCode2}, body : DisplayPrice2 ]
        \cup [ tag : {DisplayQuantityCode2}, body : DisplayQuantity2 ]
        \cup [ tag : {ExpireTimeCode2}, body : ExpireTime2 ]
        \cup [ tag : {FirmCode2}, body : Firm2 ]
        \cup [ tag : {LiquidityProvisionIndicatorCode2}, body : LiquidityProvisionIndicator2 ]
        \cup [ tag : {MaxFloorCode2}, body : MaxFloor2 ]
        \cup [ tag : {MinimumQuantityCode2}, body : MinimumQuantity2 ]
        \cup [ tag : {OrderReferenceCode2}, body : OrderReference2 ]
        \cup [ tag : {OriginalOrderEntryDateCode2}, body : OriginalOrderEntryDate2 ]
        \cup [ tag : {OriginalOrderReferenceNumberCode2}, body : OriginalOrderReferenceNumber2 ]
        \cup [ tag : {PegDifferenceCode2}, body : PegDifference2 ]
        \cup [ tag : {PegTypeCode2}, body : PegType2 ]
        \cup [ tag : {RandomReserveCode2}, body : RandomReserve2 ]
        \cup [ tag : {SecondaryOrderReferenceNumberCode2}, body : SecondaryOrderReferenceNumber2 ]
        \cup [ tag : {StpActionCode2}, body : StpAction2 ]
        \cup [ tag : {StpLevelCode2}, body : StpLevel2 ]
        \cup [ tag : {StpTraderGroupCode2}, body : StpTraderGroup2 ]
        \cup [ tag : {TimeInForceCode2}, body : TimeInForce2 ]
        \cup [ tag : {TradingAtClosingPriceCode2}, body : TradingAtClosingPrice2 ]
        \cup [ tag : {OrderConditionCode2}, body : OrderCondition2 ]
        \cup [ tag : {CumulativeQuantityCode2}, body : CumulativeQuantity2 ]
        \cup [ tag : {CustomerOrderCapacityCode2}, body : CustomerOrderCapacity2 ]
        \cup [ tag : {TargetStrategyCode2}, body : TargetStrategy2 ]
        \cup [ tag : {MinRateCode2}, body : MinRate2 ]
        \cup [ tag : {MaxRateCode2}, body : MaxRate2 ]
        \cup [ tag : {ConditionalTypeCode2}, body : ConditionalType2 ]
        \cup [ tag : {FirmUpIdCode2}, body : FirmUpId2 ]

EncodeValuePayload2(message) ==
    CASE message.tag = ClearingAccountCode2 -> EncodeClearingAccount2(message.body)
      [] message.tag = ClearingAccountTypeCode2 -> EncodeClearingAccountType2(message.body)
      [] message.tag = ClearingFirmCode2 -> EncodeClearingFirm2(message.body)
      [] message.tag = ClientReferenceCode2 -> EncodeClientReference2(message.body)
      [] message.tag = CrossTypeCode2 -> EncodeCrossType2(message.body)
      [] message.tag = DeaIndicatorCode2 -> EncodeDeaIndicator2(message.body)
      [] message.tag = DisplayCode2 -> EncodeDisplay2(message.body)
      [] message.tag = DisplayPriceCode2 -> EncodeDisplayPrice2(message.body)
      [] message.tag = DisplayQuantityCode2 -> EncodeDisplayQuantity2(message.body)
      [] message.tag = ExpireTimeCode2 -> EncodeExpireTime2(message.body)
      [] message.tag = FirmCode2 -> EncodeFirm2(message.body)
      [] message.tag = LiquidityProvisionIndicatorCode2 -> EncodeLiquidityProvisionIndicator2(message.body)
      [] message.tag = MaxFloorCode2 -> EncodeMaxFloor2(message.body)
      [] message.tag = MinimumQuantityCode2 -> EncodeMinimumQuantity2(message.body)
      [] message.tag = OrderReferenceCode2 -> EncodeOrderReference2(message.body)
      [] message.tag = OriginalOrderEntryDateCode2 -> EncodeOriginalOrderEntryDate2(message.body)
      [] message.tag = OriginalOrderReferenceNumberCode2 -> EncodeOriginalOrderReferenceNumber2(message.body)
      [] message.tag = PegDifferenceCode2 -> EncodePegDifference2(message.body)
      [] message.tag = PegTypeCode2 -> EncodePegType2(message.body)
      [] message.tag = RandomReserveCode2 -> EncodeRandomReserve2(message.body)
      [] message.tag = SecondaryOrderReferenceNumberCode2 -> EncodeSecondaryOrderReferenceNumber2(message.body)
      [] message.tag = StpActionCode2 -> EncodeStpAction2(message.body)
      [] message.tag = StpLevelCode2 -> EncodeStpLevel2(message.body)
      [] message.tag = StpTraderGroupCode2 -> EncodeStpTraderGroup2(message.body)
      [] message.tag = TimeInForceCode2 -> EncodeTimeInForce2(message.body)
      [] message.tag = TradingAtClosingPriceCode2 -> EncodeTradingAtClosingPrice2(message.body)
      [] message.tag = OrderConditionCode2 -> EncodeOrderCondition2(message.body)
      [] message.tag = CumulativeQuantityCode2 -> EncodeCumulativeQuantity2(message.body)
      [] message.tag = CustomerOrderCapacityCode2 -> EncodeCustomerOrderCapacity2(message.body)
      [] message.tag = TargetStrategyCode2 -> EncodeTargetStrategy2(message.body)
      [] message.tag = MinRateCode2 -> EncodeMinRate2(message.body)
      [] message.tag = MaxRateCode2 -> EncodeMaxRate2(message.body)
      [] message.tag = ConditionalTypeCode2 -> EncodeConditionalType2(message.body)
      [] message.tag = FirmUpIdCode2 -> EncodeFirmUpId2(message.body)

DecodeValuePayload2(tag, bytes) ==
    LET read ==
            CASE tag = ClearingAccountCode2 -> DecodeClearingAccount2(bytes)
              [] tag = ClearingAccountTypeCode2 -> DecodeClearingAccountType2(bytes)
              [] tag = ClearingFirmCode2 -> DecodeClearingFirm2(bytes)
              [] tag = ClientReferenceCode2 -> DecodeClientReference2(bytes)
              [] tag = CrossTypeCode2 -> DecodeCrossType2(bytes)
              [] tag = DeaIndicatorCode2 -> DecodeDeaIndicator2(bytes)
              [] tag = DisplayCode2 -> DecodeDisplay2(bytes)
              [] tag = DisplayPriceCode2 -> DecodeDisplayPrice2(bytes)
              [] tag = DisplayQuantityCode2 -> DecodeDisplayQuantity2(bytes)
              [] tag = ExpireTimeCode2 -> DecodeExpireTime2(bytes)
              [] tag = FirmCode2 -> DecodeFirm2(bytes)
              [] tag = LiquidityProvisionIndicatorCode2 -> DecodeLiquidityProvisionIndicator2(bytes)
              [] tag = MaxFloorCode2 -> DecodeMaxFloor2(bytes)
              [] tag = MinimumQuantityCode2 -> DecodeMinimumQuantity2(bytes)
              [] tag = OrderReferenceCode2 -> DecodeOrderReference2(bytes)
              [] tag = OriginalOrderEntryDateCode2 -> DecodeOriginalOrderEntryDate2(bytes)
              [] tag = OriginalOrderReferenceNumberCode2 -> DecodeOriginalOrderReferenceNumber2(bytes)
              [] tag = PegDifferenceCode2 -> DecodePegDifference2(bytes)
              [] tag = PegTypeCode2 -> DecodePegType2(bytes)
              [] tag = RandomReserveCode2 -> DecodeRandomReserve2(bytes)
              [] tag = SecondaryOrderReferenceNumberCode2 -> DecodeSecondaryOrderReferenceNumber2(bytes)
              [] tag = StpActionCode2 -> DecodeStpAction2(bytes)
              [] tag = StpLevelCode2 -> DecodeStpLevel2(bytes)
              [] tag = StpTraderGroupCode2 -> DecodeStpTraderGroup2(bytes)
              [] tag = TimeInForceCode2 -> DecodeTimeInForce2(bytes)
              [] tag = TradingAtClosingPriceCode2 -> DecodeTradingAtClosingPrice2(bytes)
              [] tag = OrderConditionCode2 -> DecodeOrderCondition2(bytes)
              [] tag = CumulativeQuantityCode2 -> DecodeCumulativeQuantity2(bytes)
              [] tag = CustomerOrderCapacityCode2 -> DecodeCustomerOrderCapacity2(bytes)
              [] tag = TargetStrategyCode2 -> DecodeTargetStrategy2(bytes)
              [] tag = MinRateCode2 -> DecodeMinRate2(bytes)
              [] tag = MaxRateCode2 -> DecodeMaxRate2(bytes)
              [] tag = ConditionalTypeCode2 -> DecodeConditionalType2(bytes)
              [] tag = FirmUpIdCode2 -> DecodeFirmUpId2(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroValuePayload2 == [tag |-> ClearingAccountCode2, body |-> ZeroClearingAccount2]

(* Each Value Payload in turn, at the values the message it names is checked at *)
CheckedValuePayload2 ==
    { [tag |-> ClearingAccountCode2, body |-> one] : one \in CheckedClearingAccount2 }
        \cup { [tag |-> ClearingAccountTypeCode2, body |-> one] : one \in CheckedClearingAccountType2 }
        \cup { [tag |-> ClearingFirmCode2, body |-> one] : one \in CheckedClearingFirm2 }
        \cup { [tag |-> ClientReferenceCode2, body |-> one] : one \in CheckedClientReference2 }
        \cup { [tag |-> CrossTypeCode2, body |-> one] : one \in CheckedCrossType2 }
        \cup { [tag |-> DeaIndicatorCode2, body |-> one] : one \in CheckedDeaIndicator2 }
        \cup { [tag |-> DisplayCode2, body |-> one] : one \in CheckedDisplay2 }
        \cup { [tag |-> DisplayPriceCode2, body |-> one] : one \in CheckedDisplayPrice2 }
        \cup { [tag |-> DisplayQuantityCode2, body |-> one] : one \in CheckedDisplayQuantity2 }
        \cup { [tag |-> ExpireTimeCode2, body |-> one] : one \in CheckedExpireTime2 }
        \cup { [tag |-> FirmCode2, body |-> one] : one \in CheckedFirm2 }
        \cup { [tag |-> LiquidityProvisionIndicatorCode2, body |-> one] : one \in CheckedLiquidityProvisionIndicator2 }
        \cup { [tag |-> MaxFloorCode2, body |-> one] : one \in CheckedMaxFloor2 }
        \cup { [tag |-> MinimumQuantityCode2, body |-> one] : one \in CheckedMinimumQuantity2 }
        \cup { [tag |-> OrderReferenceCode2, body |-> one] : one \in CheckedOrderReference2 }
        \cup { [tag |-> OriginalOrderEntryDateCode2, body |-> one] : one \in CheckedOriginalOrderEntryDate2 }
        \cup { [tag |-> OriginalOrderReferenceNumberCode2, body |-> one] : one \in CheckedOriginalOrderReferenceNumber2 }
        \cup { [tag |-> PegDifferenceCode2, body |-> one] : one \in CheckedPegDifference2 }
        \cup { [tag |-> PegTypeCode2, body |-> one] : one \in CheckedPegType2 }
        \cup { [tag |-> RandomReserveCode2, body |-> one] : one \in CheckedRandomReserve2 }
        \cup { [tag |-> SecondaryOrderReferenceNumberCode2, body |-> one] : one \in CheckedSecondaryOrderReferenceNumber2 }
        \cup { [tag |-> StpActionCode2, body |-> one] : one \in CheckedStpAction2 }
        \cup { [tag |-> StpLevelCode2, body |-> one] : one \in CheckedStpLevel2 }
        \cup { [tag |-> StpTraderGroupCode2, body |-> one] : one \in CheckedStpTraderGroup2 }
        \cup { [tag |-> TimeInForceCode2, body |-> one] : one \in CheckedTimeInForce2 }
        \cup { [tag |-> TradingAtClosingPriceCode2, body |-> one] : one \in CheckedTradingAtClosingPrice2 }
        \cup { [tag |-> OrderConditionCode2, body |-> one] : one \in CheckedOrderCondition2 }
        \cup { [tag |-> CumulativeQuantityCode2, body |-> one] : one \in CheckedCumulativeQuantity2 }
        \cup { [tag |-> CustomerOrderCapacityCode2, body |-> one] : one \in CheckedCustomerOrderCapacity2 }
        \cup { [tag |-> TargetStrategyCode2, body |-> one] : one \in CheckedTargetStrategy2 }
        \cup { [tag |-> MinRateCode2, body |-> one] : one \in CheckedMinRate2 }
        \cup { [tag |-> MaxRateCode2, body |-> one] : one \in CheckedMaxRate2 }
        \cup { [tag |-> ConditionalTypeCode2, body |-> one] : one \in CheckedConditionalType2 }
        \cup { [tag |-> FirmUpIdCode2, body |-> one] : one \in CheckedFirmUpId2 }

(***************************************************************************)
(* TagValue, framed by Length                                              *)
(***************************************************************************)

Tagvalue2 ==
    [ valuePayload : ValuePayload2 ]

EncodeTagvalue2Body(message) ==
    EncodeUIntBE(message.valuePayload.tag, 1)
        \o EncodeValuePayload2(message.valuePayload)

(* Length counts the bytes it frames, so it is written from them *)
EncodeTagvalue2(message) ==
    LET body == EncodeTagvalue2Body(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeTagvalue2Body(bytes) ==
    LET tag == ReadUIntBE(bytes, 1) IN IF ~tag.ok THEN Fail ELSE
    LET valuePayload == DecodeValuePayload2(tag.value, tag.rest) IN IF ~valuePayload.ok THEN Fail ELSE
    Ok([ valuePayload |-> valuePayload.value ], valuePayload.rest)

DecodeTagvalue2(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeTagvalue2Body(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroTagvalue2 ==
    [ valuePayload |-> ZeroValuePayload2 ]

(* TagValue at zero, then each field in turn at the values it is checked at *)
CheckedTagvalue2 ==
    { ZeroTagvalue2 }
        \cup { [ZeroTagvalue2 EXCEPT !.valuePayload = one] : one \in CheckedValuePayload2 }

(* A run of TagValue, written one after another *)
RECURSIVE EncodeTagvalue2List(_)
EncodeTagvalue2List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTagvalue2(Head(messages)) \o EncodeTagvalue2List(Tail(messages))

(* As many TagValue as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadTagvalue2All(_)
ReadTagvalue2All(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeTagvalue2(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTagvalue2All(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One TagValue of each kind, for the lists that carry them *)
OneTagvalue2 ==
    { [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> ClearingAccountCode2, body |-> ZeroClearingAccount2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> ClearingAccountTypeCode2, body |-> ZeroClearingAccountType2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> ClearingFirmCode2, body |-> ZeroClearingFirm2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> ClientReferenceCode2, body |-> ZeroClientReference2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> CrossTypeCode2, body |-> ZeroCrossType2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> DeaIndicatorCode2, body |-> ZeroDeaIndicator2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> DisplayCode2, body |-> ZeroDisplay2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> DisplayPriceCode2, body |-> ZeroDisplayPrice2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> DisplayQuantityCode2, body |-> ZeroDisplayQuantity2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> ExpireTimeCode2, body |-> ZeroExpireTime2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> FirmCode2, body |-> ZeroFirm2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> LiquidityProvisionIndicatorCode2, body |-> ZeroLiquidityProvisionIndicator2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> MaxFloorCode2, body |-> ZeroMaxFloor2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> MinimumQuantityCode2, body |-> ZeroMinimumQuantity2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> OrderReferenceCode2, body |-> ZeroOrderReference2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> OriginalOrderEntryDateCode2, body |-> ZeroOriginalOrderEntryDate2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> OriginalOrderReferenceNumberCode2, body |-> ZeroOriginalOrderReferenceNumber2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> PegDifferenceCode2, body |-> ZeroPegDifference2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> PegTypeCode2, body |-> ZeroPegType2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> RandomReserveCode2, body |-> ZeroRandomReserve2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> SecondaryOrderReferenceNumberCode2, body |-> ZeroSecondaryOrderReferenceNumber2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> StpActionCode2, body |-> ZeroStpAction2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> StpLevelCode2, body |-> ZeroStpLevel2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> StpTraderGroupCode2, body |-> ZeroStpTraderGroup2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> TimeInForceCode2, body |-> ZeroTimeInForce2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> TradingAtClosingPriceCode2, body |-> ZeroTradingAtClosingPrice2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> OrderConditionCode2, body |-> ZeroOrderCondition2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> CumulativeQuantityCode2, body |-> ZeroCumulativeQuantity2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> CustomerOrderCapacityCode2, body |-> ZeroCustomerOrderCapacity2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> TargetStrategyCode2, body |-> ZeroTargetStrategy2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> MinRateCode2, body |-> ZeroMinRate2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> MaxRateCode2, body |-> ZeroMaxRate2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> ConditionalTypeCode2, body |-> ZeroConditionalType2]],
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> FirmUpIdCode2, body |-> ZeroFirmUpId2]] }

(***************************************************************************)
(* Order Replaced Message                                                  *)
(***************************************************************************)

OrderReplacedMessage ==
    [ timestamp            : Sample(8),
      origUserRefNum       : Sample(4),
      newUserRefNum        : Sample(4),
      price                : Sample(4),
      orderReferenceNumber : Sample(8),
      buySellIndicator     : Sample(1),
      orderBook            : Sample(4),
      quantity             : Sample(4),
      user                 : Sample(6),
      tagvalue             : SampleLists(OneTagvalue2) ]

EncodeOrderReplacedMessage(message) ==
    LET payload == EncodeTagvalue2List(message.tagvalue)
    IN  message.timestamp
            \o message.origUserRefNum
            \o message.newUserRefNum
            \o message.price
            \o message.orderReferenceNumber
            \o message.buySellIndicator
            \o message.orderBook
            \o message.quantity
            \o message.user
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeOrderReplacedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET origUserRefNum == ReadBytes(timestamp.rest, 4) IN IF ~origUserRefNum.ok THEN Fail ELSE
    LET newUserRefNum == ReadBytes(origUserRefNum.rest, 4) IN IF ~newUserRefNum.ok THEN Fail ELSE
    LET price == ReadBytes(newUserRefNum.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET orderReferenceNumber == ReadBytes(price.rest, 8) IN IF ~orderReferenceNumber.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(orderReferenceNumber.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET orderBook == ReadBytes(buySellIndicator.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderBook.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET user == ReadBytes(quantity.rest, 6) IN IF ~user.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(user.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        tagvalue == ReadTagvalue2All(framed)
    IN  IF ~tagvalue.ok \/ tagvalue.rest # << >> THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         origUserRefNum       |-> origUserRefNum.value,
         newUserRefNum        |-> newUserRefNum.value,
         price                |-> price.value,
         orderReferenceNumber |-> orderReferenceNumber.value,
         buySellIndicator     |-> buySellIndicator.value,
         orderBook            |-> orderBook.value,
         quantity             |-> quantity.value,
         user                 |-> user.value,
         tagvalue             |-> tagvalue.value ], beyond)

ZeroOrderReplacedMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      origUserRefNum       |-> [i \in 1 .. 4 |-> 0],
      newUserRefNum        |-> [i \in 1 .. 4 |-> 0],
      price                |-> [i \in 1 .. 4 |-> 0],
      orderReferenceNumber |-> [i \in 1 .. 8 |-> 0],
      buySellIndicator     |-> [i \in 1 .. 1 |-> 0],
      orderBook            |-> [i \in 1 .. 4 |-> 0],
      quantity             |-> [i \in 1 .. 4 |-> 0],
      user                 |-> [i \in 1 .. 6 |-> 0],
      tagvalue             |-> << >> ]

(* Order Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderReplacedMessage ==
    { ZeroOrderReplacedMessage }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.origUserRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.newUserRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderReferenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.user = one] : one \in Sample(6) }
        \cup { [ZeroOrderReplacedMessage EXCEPT !.tagvalue = one] : one \in SampleLists(OneTagvalue2) }

(***************************************************************************)
(* Cancelled Order Message: 17 bytes                                       *)
(***************************************************************************)

CancelledOrderMessage ==
    [ timestamp         : Sample(8),
      userRefNum        : Sample(4),
      decrementQuantity : Sample(4),
      cancelReason      : Sample(1) ]

EncodeCancelledOrderMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.decrementQuantity
        \o message.cancelReason

DecodeCancelledOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET decrementQuantity == ReadBytes(userRefNum.rest, 4) IN IF ~decrementQuantity.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(decrementQuantity.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         userRefNum        |-> userRefNum.value,
         decrementQuantity |-> decrementQuantity.value,
         cancelReason      |-> cancelReason.value ], cancelReason.rest)

ZeroCancelledOrderMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      userRefNum        |-> [i \in 1 .. 4 |-> 0],
      decrementQuantity |-> [i \in 1 .. 4 |-> 0],
      cancelReason      |-> [i \in 1 .. 1 |-> 0] ]

(* Cancelled Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelledOrderMessage ==
    { ZeroCancelledOrderMessage }
        \cup { [ZeroCancelledOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCancelledOrderMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroCancelledOrderMessage EXCEPT !.decrementQuantity = one] : one \in Sample(4) }
        \cup { [ZeroCancelledOrderMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Cancel Pending Message: 13 bytes                                        *)
(***************************************************************************)

CancelPendingMessage ==
    [ timestamp           : Sample(8),
      userRefNum          : Sample(4),
      cancelPendingReason : Sample(1) ]

EncodeCancelPendingMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.cancelPendingReason

DecodeCancelPendingMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET cancelPendingReason == ReadBytes(userRefNum.rest, 1) IN IF ~cancelPendingReason.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         userRefNum          |-> userRefNum.value,
         cancelPendingReason |-> cancelPendingReason.value ], cancelPendingReason.rest)

ZeroCancelPendingMessage ==
    [ timestamp           |-> [i \in 1 .. 8 |-> 0],
      userRefNum          |-> [i \in 1 .. 4 |-> 0],
      cancelPendingReason |-> [i \in 1 .. 1 |-> 0] ]

(* Cancel Pending Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelPendingMessage ==
    { ZeroCancelPendingMessage }
        \cup { [ZeroCancelPendingMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCancelPendingMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroCancelPendingMessage EXCEPT !.cancelPendingReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Replace Pending Message: 17 bytes                                       *)
(***************************************************************************)

ReplacePendingMessage ==
    [ timestamp            : Sample(8),
      origUserRefNum       : Sample(4),
      userRefNum           : Sample(4),
      replacePendingReason : Sample(1) ]

EncodeReplacePendingMessage(message) ==
    message.timestamp
        \o message.origUserRefNum
        \o message.userRefNum
        \o message.replacePendingReason

DecodeReplacePendingMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET origUserRefNum == ReadBytes(timestamp.rest, 4) IN IF ~origUserRefNum.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(origUserRefNum.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET replacePendingReason == ReadBytes(userRefNum.rest, 1) IN IF ~replacePendingReason.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         origUserRefNum       |-> origUserRefNum.value,
         userRefNum           |-> userRefNum.value,
         replacePendingReason |-> replacePendingReason.value ], replacePendingReason.rest)

ZeroReplacePendingMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      origUserRefNum       |-> [i \in 1 .. 4 |-> 0],
      userRefNum           |-> [i \in 1 .. 4 |-> 0],
      replacePendingReason |-> [i \in 1 .. 1 |-> 0] ]

(* Replace Pending Message at zero, then each field in turn at the values it is checked at *)
CheckedReplacePendingMessage ==
    { ZeroReplacePendingMessage }
        \cup { [ZeroReplacePendingMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroReplacePendingMessage EXCEPT !.origUserRefNum = one] : one \in Sample(4) }
        \cup { [ZeroReplacePendingMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroReplacePendingMessage EXCEPT !.replacePendingReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Executed Order Message: 35 bytes                                        *)
(***************************************************************************)

ExecutedOrderMessage ==
    [ timestamp                                         : Sample(8),
      userRefNum                                        : Sample(4),
      executedQuantity                                  : Sample(4),
      executionPrice                                    : Sample(4),
      liquidityFlag                                     : Sample(1),
      matchNumber                                       : Sample(4),
      contraFirm                                        : Sample(4),
      tradingMode                                       : Sample(1),
      transactionCategory                               : Sample(1),
      transactionTypeAlgoIndicator                      : Sample(1),
      liquidityAttributes                               : Sample(1),
      lastMarket                                        : Sample(1),
      transactionTypeBenchmarkOrReferencePriceIndicator : Sample(1) ]

EncodeExecutedOrderMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.executedQuantity
        \o message.executionPrice
        \o message.liquidityFlag
        \o message.matchNumber
        \o message.contraFirm
        \o message.tradingMode
        \o message.transactionCategory
        \o message.transactionTypeAlgoIndicator
        \o message.liquidityAttributes
        \o message.lastMarket
        \o message.transactionTypeBenchmarkOrReferencePriceIndicator

DecodeExecutedOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET executedQuantity == ReadBytes(userRefNum.rest, 4) IN IF ~executedQuantity.ok THEN Fail ELSE
    LET executionPrice == ReadBytes(executedQuantity.rest, 4) IN IF ~executionPrice.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionPrice.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(liquidityFlag.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET contraFirm == ReadBytes(matchNumber.rest, 4) IN IF ~contraFirm.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(contraFirm.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET transactionCategory == ReadBytes(tradingMode.rest, 1) IN IF ~transactionCategory.ok THEN Fail ELSE
    LET transactionTypeAlgoIndicator == ReadBytes(transactionCategory.rest, 1) IN IF ~transactionTypeAlgoIndicator.ok THEN Fail ELSE
    LET liquidityAttributes == ReadBytes(transactionTypeAlgoIndicator.rest, 1) IN IF ~liquidityAttributes.ok THEN Fail ELSE
    LET lastMarket == ReadBytes(liquidityAttributes.rest, 1) IN IF ~lastMarket.ok THEN Fail ELSE
    LET transactionTypeBenchmarkOrReferencePriceIndicator == ReadBytes(lastMarket.rest, 1) IN IF ~transactionTypeBenchmarkOrReferencePriceIndicator.ok THEN Fail ELSE
    Ok([ timestamp                                         |-> timestamp.value,
         userRefNum                                        |-> userRefNum.value,
         executedQuantity                                  |-> executedQuantity.value,
         executionPrice                                    |-> executionPrice.value,
         liquidityFlag                                     |-> liquidityFlag.value,
         matchNumber                                       |-> matchNumber.value,
         contraFirm                                        |-> contraFirm.value,
         tradingMode                                       |-> tradingMode.value,
         transactionCategory                               |-> transactionCategory.value,
         transactionTypeAlgoIndicator                      |-> transactionTypeAlgoIndicator.value,
         liquidityAttributes                               |-> liquidityAttributes.value,
         lastMarket                                        |-> lastMarket.value,
         transactionTypeBenchmarkOrReferencePriceIndicator |-> transactionTypeBenchmarkOrReferencePriceIndicator.value ], transactionTypeBenchmarkOrReferencePriceIndicator.rest)

ZeroExecutedOrderMessage ==
    [ timestamp                                         |-> [i \in 1 .. 8 |-> 0],
      userRefNum                                        |-> [i \in 1 .. 4 |-> 0],
      executedQuantity                                  |-> [i \in 1 .. 4 |-> 0],
      executionPrice                                    |-> [i \in 1 .. 4 |-> 0],
      liquidityFlag                                     |-> [i \in 1 .. 1 |-> 0],
      matchNumber                                       |-> [i \in 1 .. 4 |-> 0],
      contraFirm                                        |-> [i \in 1 .. 4 |-> 0],
      tradingMode                                       |-> [i \in 1 .. 1 |-> 0],
      transactionCategory                               |-> [i \in 1 .. 1 |-> 0],
      transactionTypeAlgoIndicator                      |-> [i \in 1 .. 1 |-> 0],
      liquidityAttributes                               |-> [i \in 1 .. 1 |-> 0],
      lastMarket                                        |-> [i \in 1 .. 1 |-> 0],
      transactionTypeBenchmarkOrReferencePriceIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Executed Order Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutedOrderMessage ==
    { ZeroExecutedOrderMessage }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.executedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.executionPrice = one] : one \in Sample(4) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.contraFirm = one] : one \in Sample(4) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.transactionTypeAlgoIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.liquidityAttributes = one] : one \in Sample(1) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.lastMarket = one] : one \in Sample(1) }
        \cup { [ZeroExecutedOrderMessage EXCEPT !.transactionTypeBenchmarkOrReferencePriceIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Broken Trade Message: 20 bytes                                          *)
(***************************************************************************)

BrokenTradeMessage ==
    [ timestamp                    : Sample(8),
      userRefNum                   : Sample(4),
      matchNumber                  : Sample(4),
      brokenTradeReason            : Sample(1),
      tradingMode                  : Sample(1),
      transactionCategory          : Sample(1),
      transactionTypeAlgoIndicator : Sample(1) ]

EncodeBrokenTradeMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.matchNumber
        \o message.brokenTradeReason
        \o message.tradingMode
        \o message.transactionCategory
        \o message.transactionTypeAlgoIndicator

DecodeBrokenTradeMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(userRefNum.rest, 4) IN IF ~matchNumber.ok THEN Fail ELSE
    LET brokenTradeReason == ReadBytes(matchNumber.rest, 1) IN IF ~brokenTradeReason.ok THEN Fail ELSE
    LET tradingMode == ReadBytes(brokenTradeReason.rest, 1) IN IF ~tradingMode.ok THEN Fail ELSE
    LET transactionCategory == ReadBytes(tradingMode.rest, 1) IN IF ~transactionCategory.ok THEN Fail ELSE
    LET transactionTypeAlgoIndicator == ReadBytes(transactionCategory.rest, 1) IN IF ~transactionTypeAlgoIndicator.ok THEN Fail ELSE
    Ok([ timestamp                    |-> timestamp.value,
         userRefNum                   |-> userRefNum.value,
         matchNumber                  |-> matchNumber.value,
         brokenTradeReason            |-> brokenTradeReason.value,
         tradingMode                  |-> tradingMode.value,
         transactionCategory          |-> transactionCategory.value,
         transactionTypeAlgoIndicator |-> transactionTypeAlgoIndicator.value ], transactionTypeAlgoIndicator.rest)

ZeroBrokenTradeMessage ==
    [ timestamp                    |-> [i \in 1 .. 8 |-> 0],
      userRefNum                   |-> [i \in 1 .. 4 |-> 0],
      matchNumber                  |-> [i \in 1 .. 4 |-> 0],
      brokenTradeReason            |-> [i \in 1 .. 1 |-> 0],
      tradingMode                  |-> [i \in 1 .. 1 |-> 0],
      transactionCategory          |-> [i \in 1 .. 1 |-> 0],
      transactionTypeAlgoIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Broken Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedBrokenTradeMessage ==
    { ZeroBrokenTradeMessage }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.matchNumber = one] : one \in Sample(4) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.brokenTradeReason = one] : one \in Sample(1) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.tradingMode = one] : one \in Sample(1) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.transactionCategory = one] : one \in Sample(1) }
        \cup { [ZeroBrokenTradeMessage EXCEPT !.transactionTypeAlgoIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Rejected Order Message: 14 bytes                                        *)
(***************************************************************************)

RejectedOrderMessage ==
    [ timestamp           : Sample(8),
      userRefNum          : Sample(4),
      rejectedOrderReason : Sample(2) ]

EncodeRejectedOrderMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.rejectedOrderReason

DecodeRejectedOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET rejectedOrderReason == ReadBytes(userRefNum.rest, 2) IN IF ~rejectedOrderReason.ok THEN Fail ELSE
    Ok([ timestamp           |-> timestamp.value,
         userRefNum          |-> userRefNum.value,
         rejectedOrderReason |-> rejectedOrderReason.value ], rejectedOrderReason.rest)

ZeroRejectedOrderMessage ==
    [ timestamp           |-> [i \in 1 .. 8 |-> 0],
      userRefNum          |-> [i \in 1 .. 4 |-> 0],
      rejectedOrderReason |-> [i \in 1 .. 2 |-> 0] ]

(* Rejected Order Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectedOrderMessage ==
    { ZeroRejectedOrderMessage }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroRejectedOrderMessage EXCEPT !.rejectedOrderReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Cancel Rejected Message: 14 bytes                                       *)
(***************************************************************************)

CancelRejectedMessage ==
    [ timestamp            : Sample(8),
      userRefNum           : Sample(4),
      cancelRejectedReason : Sample(2) ]

EncodeCancelRejectedMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.cancelRejectedReason

DecodeCancelRejectedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET cancelRejectedReason == ReadBytes(userRefNum.rest, 2) IN IF ~cancelRejectedReason.ok THEN Fail ELSE
    Ok([ timestamp            |-> timestamp.value,
         userRefNum           |-> userRefNum.value,
         cancelRejectedReason |-> cancelRejectedReason.value ], cancelRejectedReason.rest)

ZeroCancelRejectedMessage ==
    [ timestamp            |-> [i \in 1 .. 8 |-> 0],
      userRefNum           |-> [i \in 1 .. 4 |-> 0],
      cancelRejectedReason |-> [i \in 1 .. 2 |-> 0] ]

(* Cancel Rejected Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelRejectedMessage ==
    { ZeroCancelRejectedMessage }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroCancelRejectedMessage EXCEPT !.cancelRejectedReason = one] : one \in Sample(2) }

(***************************************************************************)
(* Clearing Account: 12 bytes                                              *)
(***************************************************************************)

ClearingAccount3 ==
    [ clearingAccountValue : Sample(12) ]

EncodeClearingAccount3(message) ==
    message.clearingAccountValue

DecodeClearingAccount3(bytes) ==
    LET clearingAccountValue == ReadBytes(bytes, 12) IN IF ~clearingAccountValue.ok THEN Fail ELSE
    Ok([ clearingAccountValue |-> clearingAccountValue.value ], clearingAccountValue.rest)

ZeroClearingAccount3 ==
    [ clearingAccountValue |-> [i \in 1 .. 12 |-> 0] ]

(* Clearing Account at zero, then each field in turn at the values it is checked at *)
CheckedClearingAccount3 ==
    { ZeroClearingAccount3 }
        \cup { [ZeroClearingAccount3 EXCEPT !.clearingAccountValue = one] : one \in Sample(12) }

(***************************************************************************)
(* Clearing Account Type: 1 bytes                                          *)
(***************************************************************************)

ClearingAccountType3 ==
    [ clearingAccountTypeValue : Sample(1) ]

EncodeClearingAccountType3(message) ==
    message.clearingAccountTypeValue

DecodeClearingAccountType3(bytes) ==
    LET clearingAccountTypeValue == ReadBytes(bytes, 1) IN IF ~clearingAccountTypeValue.ok THEN Fail ELSE
    Ok([ clearingAccountTypeValue |-> clearingAccountTypeValue.value ], clearingAccountTypeValue.rest)

ZeroClearingAccountType3 ==
    [ clearingAccountTypeValue |-> [i \in 1 .. 1 |-> 0] ]

(* Clearing Account Type at zero, then each field in turn at the values it is checked at *)
CheckedClearingAccountType3 ==
    { ZeroClearingAccountType3 }
        \cup { [ZeroClearingAccountType3 EXCEPT !.clearingAccountTypeValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Clearing Firm: 4 bytes                                                  *)
(***************************************************************************)

ClearingFirm3 ==
    [ clearingFirmValue : Sample(4) ]

EncodeClearingFirm3(message) ==
    message.clearingFirmValue

DecodeClearingFirm3(bytes) ==
    LET clearingFirmValue == ReadBytes(bytes, 4) IN IF ~clearingFirmValue.ok THEN Fail ELSE
    Ok([ clearingFirmValue |-> clearingFirmValue.value ], clearingFirmValue.rest)

ZeroClearingFirm3 ==
    [ clearingFirmValue |-> [i \in 1 .. 4 |-> 0] ]

(* Clearing Firm at zero, then each field in turn at the values it is checked at *)
CheckedClearingFirm3 ==
    { ZeroClearingFirm3 }
        \cup { [ZeroClearingFirm3 EXCEPT !.clearingFirmValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Client Reference: 15 bytes                                              *)
(***************************************************************************)

ClientReference3 ==
    [ clientReferenceValue : Sample(15) ]

EncodeClientReference3(message) ==
    message.clientReferenceValue

DecodeClientReference3(bytes) ==
    LET clientReferenceValue == ReadBytes(bytes, 15) IN IF ~clientReferenceValue.ok THEN Fail ELSE
    Ok([ clientReferenceValue |-> clientReferenceValue.value ], clientReferenceValue.rest)

ZeroClientReference3 ==
    [ clientReferenceValue |-> [i \in 1 .. 15 |-> 0] ]

(* Client Reference at zero, then each field in turn at the values it is checked at *)
CheckedClientReference3 ==
    { ZeroClientReference3 }
        \cup { [ZeroClientReference3 EXCEPT !.clientReferenceValue = one] : one \in Sample(15) }

(***************************************************************************)
(* Cross Type: 1 bytes                                                     *)
(***************************************************************************)

CrossType3 ==
    [ crossTypeValue : Sample(1) ]

EncodeCrossType3(message) ==
    message.crossTypeValue

DecodeCrossType3(bytes) ==
    LET crossTypeValue == ReadBytes(bytes, 1) IN IF ~crossTypeValue.ok THEN Fail ELSE
    Ok([ crossTypeValue |-> crossTypeValue.value ], crossTypeValue.rest)

ZeroCrossType3 ==
    [ crossTypeValue |-> [i \in 1 .. 1 |-> 0] ]

(* Cross Type at zero, then each field in turn at the values it is checked at *)
CheckedCrossType3 ==
    { ZeroCrossType3 }
        \cup { [ZeroCrossType3 EXCEPT !.crossTypeValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Dea Indicator: 1 bytes                                                  *)
(***************************************************************************)

DeaIndicator3 ==
    [ deaIndicatorValue : Sample(1) ]

EncodeDeaIndicator3(message) ==
    message.deaIndicatorValue

DecodeDeaIndicator3(bytes) ==
    LET deaIndicatorValue == ReadBytes(bytes, 1) IN IF ~deaIndicatorValue.ok THEN Fail ELSE
    Ok([ deaIndicatorValue |-> deaIndicatorValue.value ], deaIndicatorValue.rest)

ZeroDeaIndicator3 ==
    [ deaIndicatorValue |-> [i \in 1 .. 1 |-> 0] ]

(* Dea Indicator at zero, then each field in turn at the values it is checked at *)
CheckedDeaIndicator3 ==
    { ZeroDeaIndicator3 }
        \cup { [ZeroDeaIndicator3 EXCEPT !.deaIndicatorValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Display: 1 bytes                                                        *)
(***************************************************************************)

Display3 ==
    [ displayValue : Sample(1) ]

EncodeDisplay3(message) ==
    message.displayValue

DecodeDisplay3(bytes) ==
    LET displayValue == ReadBytes(bytes, 1) IN IF ~displayValue.ok THEN Fail ELSE
    Ok([ displayValue |-> displayValue.value ], displayValue.rest)

ZeroDisplay3 ==
    [ displayValue |-> [i \in 1 .. 1 |-> 0] ]

(* Display at zero, then each field in turn at the values it is checked at *)
CheckedDisplay3 ==
    { ZeroDisplay3 }
        \cup { [ZeroDisplay3 EXCEPT !.displayValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Display Price: 4 bytes                                                  *)
(***************************************************************************)

DisplayPrice3 ==
    [ displayPriceValue : Sample(4) ]

EncodeDisplayPrice3(message) ==
    message.displayPriceValue

DecodeDisplayPrice3(bytes) ==
    LET displayPriceValue == ReadBytes(bytes, 4) IN IF ~displayPriceValue.ok THEN Fail ELSE
    Ok([ displayPriceValue |-> displayPriceValue.value ], displayPriceValue.rest)

ZeroDisplayPrice3 ==
    [ displayPriceValue |-> [i \in 1 .. 4 |-> 0] ]

(* Display Price at zero, then each field in turn at the values it is checked at *)
CheckedDisplayPrice3 ==
    { ZeroDisplayPrice3 }
        \cup { [ZeroDisplayPrice3 EXCEPT !.displayPriceValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Display Quantity: 4 bytes                                               *)
(***************************************************************************)

DisplayQuantity3 ==
    [ displayQuantityValue : Sample(4) ]

EncodeDisplayQuantity3(message) ==
    message.displayQuantityValue

DecodeDisplayQuantity3(bytes) ==
    LET displayQuantityValue == ReadBytes(bytes, 4) IN IF ~displayQuantityValue.ok THEN Fail ELSE
    Ok([ displayQuantityValue |-> displayQuantityValue.value ], displayQuantityValue.rest)

ZeroDisplayQuantity3 ==
    [ displayQuantityValue |-> [i \in 1 .. 4 |-> 0] ]

(* Display Quantity at zero, then each field in turn at the values it is checked at *)
CheckedDisplayQuantity3 ==
    { ZeroDisplayQuantity3 }
        \cup { [ZeroDisplayQuantity3 EXCEPT !.displayQuantityValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Expire Time: 2 bytes                                                    *)
(***************************************************************************)

ExpireTime3 ==
    [ expireTimeValue : Sample(2) ]

EncodeExpireTime3(message) ==
    message.expireTimeValue

DecodeExpireTime3(bytes) ==
    LET expireTimeValue == ReadBytes(bytes, 2) IN IF ~expireTimeValue.ok THEN Fail ELSE
    Ok([ expireTimeValue |-> expireTimeValue.value ], expireTimeValue.rest)

ZeroExpireTime3 ==
    [ expireTimeValue |-> [i \in 1 .. 2 |-> 0] ]

(* Expire Time at zero, then each field in turn at the values it is checked at *)
CheckedExpireTime3 ==
    { ZeroExpireTime3 }
        \cup { [ZeroExpireTime3 EXCEPT !.expireTimeValue = one] : one \in Sample(2) }

(***************************************************************************)
(* Firm: 4 bytes                                                           *)
(***************************************************************************)

Firm3 ==
    [ firmValue : Sample(4) ]

EncodeFirm3(message) ==
    message.firmValue

DecodeFirm3(bytes) ==
    LET firmValue == ReadBytes(bytes, 4) IN IF ~firmValue.ok THEN Fail ELSE
    Ok([ firmValue |-> firmValue.value ], firmValue.rest)

ZeroFirm3 ==
    [ firmValue |-> [i \in 1 .. 4 |-> 0] ]

(* Firm at zero, then each field in turn at the values it is checked at *)
CheckedFirm3 ==
    { ZeroFirm3 }
        \cup { [ZeroFirm3 EXCEPT !.firmValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Liquidity Provision Indicator: 1 bytes                                  *)
(***************************************************************************)

LiquidityProvisionIndicator3 ==
    [ liquidityProvisionIndicatorValue : Sample(1) ]

EncodeLiquidityProvisionIndicator3(message) ==
    message.liquidityProvisionIndicatorValue

DecodeLiquidityProvisionIndicator3(bytes) ==
    LET liquidityProvisionIndicatorValue == ReadBytes(bytes, 1) IN IF ~liquidityProvisionIndicatorValue.ok THEN Fail ELSE
    Ok([ liquidityProvisionIndicatorValue |-> liquidityProvisionIndicatorValue.value ], liquidityProvisionIndicatorValue.rest)

ZeroLiquidityProvisionIndicator3 ==
    [ liquidityProvisionIndicatorValue |-> [i \in 1 .. 1 |-> 0] ]

(* Liquidity Provision Indicator at zero, then each field in turn at the values it is checked at *)
CheckedLiquidityProvisionIndicator3 ==
    { ZeroLiquidityProvisionIndicator3 }
        \cup { [ZeroLiquidityProvisionIndicator3 EXCEPT !.liquidityProvisionIndicatorValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Max Floor: 4 bytes                                                      *)
(***************************************************************************)

MaxFloor3 ==
    [ maxFloorValue : Sample(4) ]

EncodeMaxFloor3(message) ==
    message.maxFloorValue

DecodeMaxFloor3(bytes) ==
    LET maxFloorValue == ReadBytes(bytes, 4) IN IF ~maxFloorValue.ok THEN Fail ELSE
    Ok([ maxFloorValue |-> maxFloorValue.value ], maxFloorValue.rest)

ZeroMaxFloor3 ==
    [ maxFloorValue |-> [i \in 1 .. 4 |-> 0] ]

(* Max Floor at zero, then each field in turn at the values it is checked at *)
CheckedMaxFloor3 ==
    { ZeroMaxFloor3 }
        \cup { [ZeroMaxFloor3 EXCEPT !.maxFloorValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Minimum Quantity: 4 bytes                                               *)
(***************************************************************************)

MinimumQuantity3 ==
    [ minimumQuantityValue : Sample(4) ]

EncodeMinimumQuantity3(message) ==
    message.minimumQuantityValue

DecodeMinimumQuantity3(bytes) ==
    LET minimumQuantityValue == ReadBytes(bytes, 4) IN IF ~minimumQuantityValue.ok THEN Fail ELSE
    Ok([ minimumQuantityValue |-> minimumQuantityValue.value ], minimumQuantityValue.rest)

ZeroMinimumQuantity3 ==
    [ minimumQuantityValue |-> [i \in 1 .. 4 |-> 0] ]

(* Minimum Quantity at zero, then each field in turn at the values it is checked at *)
CheckedMinimumQuantity3 ==
    { ZeroMinimumQuantity3 }
        \cup { [ZeroMinimumQuantity3 EXCEPT !.minimumQuantityValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Reference: 10 bytes                                               *)
(***************************************************************************)

OrderReference3 ==
    [ orderReferenceValue : Sample(10) ]

EncodeOrderReference3(message) ==
    message.orderReferenceValue

DecodeOrderReference3(bytes) ==
    LET orderReferenceValue == ReadBytes(bytes, 10) IN IF ~orderReferenceValue.ok THEN Fail ELSE
    Ok([ orderReferenceValue |-> orderReferenceValue.value ], orderReferenceValue.rest)

ZeroOrderReference3 ==
    [ orderReferenceValue |-> [i \in 1 .. 10 |-> 0] ]

(* Order Reference at zero, then each field in turn at the values it is checked at *)
CheckedOrderReference3 ==
    { ZeroOrderReference3 }
        \cup { [ZeroOrderReference3 EXCEPT !.orderReferenceValue = one] : one \in Sample(10) }

(***************************************************************************)
(* Original Order Entry Date: 4 bytes                                      *)
(***************************************************************************)

OriginalOrderEntryDate3 ==
    [ originalOrderEntryDateValue : Sample(4) ]

EncodeOriginalOrderEntryDate3(message) ==
    message.originalOrderEntryDateValue

DecodeOriginalOrderEntryDate3(bytes) ==
    LET originalOrderEntryDateValue == ReadBytes(bytes, 4) IN IF ~originalOrderEntryDateValue.ok THEN Fail ELSE
    Ok([ originalOrderEntryDateValue |-> originalOrderEntryDateValue.value ], originalOrderEntryDateValue.rest)

ZeroOriginalOrderEntryDate3 ==
    [ originalOrderEntryDateValue |-> [i \in 1 .. 4 |-> 0] ]

(* Original Order Entry Date at zero, then each field in turn at the values it is checked at *)
CheckedOriginalOrderEntryDate3 ==
    { ZeroOriginalOrderEntryDate3 }
        \cup { [ZeroOriginalOrderEntryDate3 EXCEPT !.originalOrderEntryDateValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Original Order Reference Number: 8 bytes                                *)
(***************************************************************************)

OriginalOrderReferenceNumber3 ==
    [ originalOrderReferenceNumberValue : Sample(8) ]

EncodeOriginalOrderReferenceNumber3(message) ==
    message.originalOrderReferenceNumberValue

DecodeOriginalOrderReferenceNumber3(bytes) ==
    LET originalOrderReferenceNumberValue == ReadBytes(bytes, 8) IN IF ~originalOrderReferenceNumberValue.ok THEN Fail ELSE
    Ok([ originalOrderReferenceNumberValue |-> originalOrderReferenceNumberValue.value ], originalOrderReferenceNumberValue.rest)

ZeroOriginalOrderReferenceNumber3 ==
    [ originalOrderReferenceNumberValue |-> [i \in 1 .. 8 |-> 0] ]

(* Original Order Reference Number at zero, then each field in turn at the values it is checked at *)
CheckedOriginalOrderReferenceNumber3 ==
    { ZeroOriginalOrderReferenceNumber3 }
        \cup { [ZeroOriginalOrderReferenceNumber3 EXCEPT !.originalOrderReferenceNumberValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Peg Difference: 4 bytes                                                 *)
(***************************************************************************)

PegDifference3 ==
    [ pegDifferenceValue : Sample(4) ]

EncodePegDifference3(message) ==
    message.pegDifferenceValue

DecodePegDifference3(bytes) ==
    LET pegDifferenceValue == ReadBytes(bytes, 4) IN IF ~pegDifferenceValue.ok THEN Fail ELSE
    Ok([ pegDifferenceValue |-> pegDifferenceValue.value ], pegDifferenceValue.rest)

ZeroPegDifference3 ==
    [ pegDifferenceValue |-> [i \in 1 .. 4 |-> 0] ]

(* Peg Difference at zero, then each field in turn at the values it is checked at *)
CheckedPegDifference3 ==
    { ZeroPegDifference3 }
        \cup { [ZeroPegDifference3 EXCEPT !.pegDifferenceValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Peg Type: 1 bytes                                                       *)
(***************************************************************************)

PegType3 ==
    [ pegTypeValue : Sample(1) ]

EncodePegType3(message) ==
    message.pegTypeValue

DecodePegType3(bytes) ==
    LET pegTypeValue == ReadBytes(bytes, 1) IN IF ~pegTypeValue.ok THEN Fail ELSE
    Ok([ pegTypeValue |-> pegTypeValue.value ], pegTypeValue.rest)

ZeroPegType3 ==
    [ pegTypeValue |-> [i \in 1 .. 1 |-> 0] ]

(* Peg Type at zero, then each field in turn at the values it is checked at *)
CheckedPegType3 ==
    { ZeroPegType3 }
        \cup { [ZeroPegType3 EXCEPT !.pegTypeValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Random Reserve: 4 bytes                                                 *)
(***************************************************************************)

RandomReserve3 ==
    [ randomReserveValue : Sample(4) ]

EncodeRandomReserve3(message) ==
    message.randomReserveValue

DecodeRandomReserve3(bytes) ==
    LET randomReserveValue == ReadBytes(bytes, 4) IN IF ~randomReserveValue.ok THEN Fail ELSE
    Ok([ randomReserveValue |-> randomReserveValue.value ], randomReserveValue.rest)

ZeroRandomReserve3 ==
    [ randomReserveValue |-> [i \in 1 .. 4 |-> 0] ]

(* Random Reserve at zero, then each field in turn at the values it is checked at *)
CheckedRandomReserve3 ==
    { ZeroRandomReserve3 }
        \cup { [ZeroRandomReserve3 EXCEPT !.randomReserveValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Secondary Order Reference Number: 8 bytes                               *)
(***************************************************************************)

SecondaryOrderReferenceNumber3 ==
    [ secondaryOrderReferenceNumberValue : Sample(8) ]

EncodeSecondaryOrderReferenceNumber3(message) ==
    message.secondaryOrderReferenceNumberValue

DecodeSecondaryOrderReferenceNumber3(bytes) ==
    LET secondaryOrderReferenceNumberValue == ReadBytes(bytes, 8) IN IF ~secondaryOrderReferenceNumberValue.ok THEN Fail ELSE
    Ok([ secondaryOrderReferenceNumberValue |-> secondaryOrderReferenceNumberValue.value ], secondaryOrderReferenceNumberValue.rest)

ZeroSecondaryOrderReferenceNumber3 ==
    [ secondaryOrderReferenceNumberValue |-> [i \in 1 .. 8 |-> 0] ]

(* Secondary Order Reference Number at zero, then each field in turn at the values it is checked at *)
CheckedSecondaryOrderReferenceNumber3 ==
    { ZeroSecondaryOrderReferenceNumber3 }
        \cup { [ZeroSecondaryOrderReferenceNumber3 EXCEPT !.secondaryOrderReferenceNumberValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Stp Action: 1 bytes                                                     *)
(***************************************************************************)

StpAction3 ==
    [ stpActionValue : Sample(1) ]

EncodeStpAction3(message) ==
    message.stpActionValue

DecodeStpAction3(bytes) ==
    LET stpActionValue == ReadBytes(bytes, 1) IN IF ~stpActionValue.ok THEN Fail ELSE
    Ok([ stpActionValue |-> stpActionValue.value ], stpActionValue.rest)

ZeroStpAction3 ==
    [ stpActionValue |-> [i \in 1 .. 1 |-> 0] ]

(* Stp Action at zero, then each field in turn at the values it is checked at *)
CheckedStpAction3 ==
    { ZeroStpAction3 }
        \cup { [ZeroStpAction3 EXCEPT !.stpActionValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Stp Level: 1 bytes                                                      *)
(***************************************************************************)

StpLevel3 ==
    [ stpLevelValue : Sample(1) ]

EncodeStpLevel3(message) ==
    message.stpLevelValue

DecodeStpLevel3(bytes) ==
    LET stpLevelValue == ReadBytes(bytes, 1) IN IF ~stpLevelValue.ok THEN Fail ELSE
    Ok([ stpLevelValue |-> stpLevelValue.value ], stpLevelValue.rest)

ZeroStpLevel3 ==
    [ stpLevelValue |-> [i \in 1 .. 1 |-> 0] ]

(* Stp Level at zero, then each field in turn at the values it is checked at *)
CheckedStpLevel3 ==
    { ZeroStpLevel3 }
        \cup { [ZeroStpLevel3 EXCEPT !.stpLevelValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Stp Trader Group: 2 bytes                                               *)
(***************************************************************************)

StpTraderGroup3 ==
    [ stpTraderGroupValue : Sample(2) ]

EncodeStpTraderGroup3(message) ==
    message.stpTraderGroupValue

DecodeStpTraderGroup3(bytes) ==
    LET stpTraderGroupValue == ReadBytes(bytes, 2) IN IF ~stpTraderGroupValue.ok THEN Fail ELSE
    Ok([ stpTraderGroupValue |-> stpTraderGroupValue.value ], stpTraderGroupValue.rest)

ZeroStpTraderGroup3 ==
    [ stpTraderGroupValue |-> [i \in 1 .. 2 |-> 0] ]

(* Stp Trader Group at zero, then each field in turn at the values it is checked at *)
CheckedStpTraderGroup3 ==
    { ZeroStpTraderGroup3 }
        \cup { [ZeroStpTraderGroup3 EXCEPT !.stpTraderGroupValue = one] : one \in Sample(2) }

(***************************************************************************)
(* Time In Force: 1 bytes                                                  *)
(***************************************************************************)

TimeInForce3 ==
    [ timeInForceValue : Sample(1) ]

EncodeTimeInForce3(message) ==
    message.timeInForceValue

DecodeTimeInForce3(bytes) ==
    LET timeInForceValue == ReadBytes(bytes, 1) IN IF ~timeInForceValue.ok THEN Fail ELSE
    Ok([ timeInForceValue |-> timeInForceValue.value ], timeInForceValue.rest)

ZeroTimeInForce3 ==
    [ timeInForceValue |-> [i \in 1 .. 1 |-> 0] ]

(* Time In Force at zero, then each field in turn at the values it is checked at *)
CheckedTimeInForce3 ==
    { ZeroTimeInForce3 }
        \cup { [ZeroTimeInForce3 EXCEPT !.timeInForceValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Trading At Closing Price: 1 bytes                                       *)
(***************************************************************************)

TradingAtClosingPrice3 ==
    [ tradingAtClosingPriceValue : Sample(1) ]

EncodeTradingAtClosingPrice3(message) ==
    message.tradingAtClosingPriceValue

DecodeTradingAtClosingPrice3(bytes) ==
    LET tradingAtClosingPriceValue == ReadBytes(bytes, 1) IN IF ~tradingAtClosingPriceValue.ok THEN Fail ELSE
    Ok([ tradingAtClosingPriceValue |-> tradingAtClosingPriceValue.value ], tradingAtClosingPriceValue.rest)

ZeroTradingAtClosingPrice3 ==
    [ tradingAtClosingPriceValue |-> [i \in 1 .. 1 |-> 0] ]

(* Trading At Closing Price at zero, then each field in turn at the values it is checked at *)
CheckedTradingAtClosingPrice3 ==
    { ZeroTradingAtClosingPrice3 }
        \cup { [ZeroTradingAtClosingPrice3 EXCEPT !.tradingAtClosingPriceValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Condition: 1 bytes                                                *)
(***************************************************************************)

OrderCondition3 ==
    [ orderConditionValue : Sample(1) ]

EncodeOrderCondition3(message) ==
    message.orderConditionValue

DecodeOrderCondition3(bytes) ==
    LET orderConditionValue == ReadBytes(bytes, 1) IN IF ~orderConditionValue.ok THEN Fail ELSE
    Ok([ orderConditionValue |-> orderConditionValue.value ], orderConditionValue.rest)

ZeroOrderCondition3 ==
    [ orderConditionValue |-> [i \in 1 .. 1 |-> 0] ]

(* Order Condition at zero, then each field in turn at the values it is checked at *)
CheckedOrderCondition3 ==
    { ZeroOrderCondition3 }
        \cup { [ZeroOrderCondition3 EXCEPT !.orderConditionValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Cumulative Quantity: 4 bytes                                            *)
(***************************************************************************)

CumulativeQuantity3 ==
    [ cumulativeQuantityValue : Sample(4) ]

EncodeCumulativeQuantity3(message) ==
    message.cumulativeQuantityValue

DecodeCumulativeQuantity3(bytes) ==
    LET cumulativeQuantityValue == ReadBytes(bytes, 4) IN IF ~cumulativeQuantityValue.ok THEN Fail ELSE
    Ok([ cumulativeQuantityValue |-> cumulativeQuantityValue.value ], cumulativeQuantityValue.rest)

ZeroCumulativeQuantity3 ==
    [ cumulativeQuantityValue |-> [i \in 1 .. 4 |-> 0] ]

(* Cumulative Quantity at zero, then each field in turn at the values it is checked at *)
CheckedCumulativeQuantity3 ==
    { ZeroCumulativeQuantity3 }
        \cup { [ZeroCumulativeQuantity3 EXCEPT !.cumulativeQuantityValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Customer Order Capacity: 1 bytes                                        *)
(***************************************************************************)

CustomerOrderCapacity3 ==
    [ customerOrderCapacityValue : Sample(1) ]

EncodeCustomerOrderCapacity3(message) ==
    message.customerOrderCapacityValue

DecodeCustomerOrderCapacity3(bytes) ==
    LET customerOrderCapacityValue == ReadBytes(bytes, 1) IN IF ~customerOrderCapacityValue.ok THEN Fail ELSE
    Ok([ customerOrderCapacityValue |-> customerOrderCapacityValue.value ], customerOrderCapacityValue.rest)

ZeroCustomerOrderCapacity3 ==
    [ customerOrderCapacityValue |-> [i \in 1 .. 1 |-> 0] ]

(* Customer Order Capacity at zero, then each field in turn at the values it is checked at *)
CheckedCustomerOrderCapacity3 ==
    { ZeroCustomerOrderCapacity3 }
        \cup { [ZeroCustomerOrderCapacity3 EXCEPT !.customerOrderCapacityValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Target Strategy: 1 bytes                                                *)
(***************************************************************************)

TargetStrategy3 ==
    [ targetStrategyValue : Sample(1) ]

EncodeTargetStrategy3(message) ==
    message.targetStrategyValue

DecodeTargetStrategy3(bytes) ==
    LET targetStrategyValue == ReadBytes(bytes, 1) IN IF ~targetStrategyValue.ok THEN Fail ELSE
    Ok([ targetStrategyValue |-> targetStrategyValue.value ], targetStrategyValue.rest)

ZeroTargetStrategy3 ==
    [ targetStrategyValue |-> [i \in 1 .. 1 |-> 0] ]

(* Target Strategy at zero, then each field in turn at the values it is checked at *)
CheckedTargetStrategy3 ==
    { ZeroTargetStrategy3 }
        \cup { [ZeroTargetStrategy3 EXCEPT !.targetStrategyValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Min Rate: 2 bytes                                                       *)
(***************************************************************************)

MinRate3 ==
    [ minRateValue : Sample(2) ]

EncodeMinRate3(message) ==
    message.minRateValue

DecodeMinRate3(bytes) ==
    LET minRateValue == ReadBytes(bytes, 2) IN IF ~minRateValue.ok THEN Fail ELSE
    Ok([ minRateValue |-> minRateValue.value ], minRateValue.rest)

ZeroMinRate3 ==
    [ minRateValue |-> [i \in 1 .. 2 |-> 0] ]

(* Min Rate at zero, then each field in turn at the values it is checked at *)
CheckedMinRate3 ==
    { ZeroMinRate3 }
        \cup { [ZeroMinRate3 EXCEPT !.minRateValue = one] : one \in Sample(2) }

(***************************************************************************)
(* Max Rate: 2 bytes                                                       *)
(***************************************************************************)

MaxRate3 ==
    [ maxRateValue : Sample(2) ]

EncodeMaxRate3(message) ==
    message.maxRateValue

DecodeMaxRate3(bytes) ==
    LET maxRateValue == ReadBytes(bytes, 2) IN IF ~maxRateValue.ok THEN Fail ELSE
    Ok([ maxRateValue |-> maxRateValue.value ], maxRateValue.rest)

ZeroMaxRate3 ==
    [ maxRateValue |-> [i \in 1 .. 2 |-> 0] ]

(* Max Rate at zero, then each field in turn at the values it is checked at *)
CheckedMaxRate3 ==
    { ZeroMaxRate3 }
        \cup { [ZeroMaxRate3 EXCEPT !.maxRateValue = one] : one \in Sample(2) }

(***************************************************************************)
(* Conditional Type: 1 bytes                                               *)
(***************************************************************************)

ConditionalType3 ==
    [ conditionalTypeValue : Sample(1) ]

EncodeConditionalType3(message) ==
    message.conditionalTypeValue

DecodeConditionalType3(bytes) ==
    LET conditionalTypeValue == ReadBytes(bytes, 1) IN IF ~conditionalTypeValue.ok THEN Fail ELSE
    Ok([ conditionalTypeValue |-> conditionalTypeValue.value ], conditionalTypeValue.rest)

ZeroConditionalType3 ==
    [ conditionalTypeValue |-> [i \in 1 .. 1 |-> 0] ]

(* Conditional Type at zero, then each field in turn at the values it is checked at *)
CheckedConditionalType3 ==
    { ZeroConditionalType3 }
        \cup { [ZeroConditionalType3 EXCEPT !.conditionalTypeValue = one] : one \in Sample(1) }

(***************************************************************************)
(* Firm Up Id: 4 bytes                                                     *)
(***************************************************************************)

FirmUpId3 ==
    [ firmUpIdValue : Sample(4) ]

EncodeFirmUpId3(message) ==
    message.firmUpIdValue

DecodeFirmUpId3(bytes) ==
    LET firmUpIdValue == ReadBytes(bytes, 4) IN IF ~firmUpIdValue.ok THEN Fail ELSE
    Ok([ firmUpIdValue |-> firmUpIdValue.value ], firmUpIdValue.rest)

ZeroFirmUpId3 ==
    [ firmUpIdValue |-> [i \in 1 .. 4 |-> 0] ]

(* Firm Up Id at zero, then each field in turn at the values it is checked at *)
CheckedFirmUpId3 ==
    { ZeroFirmUpId3 }
        \cup { [ZeroFirmUpId3 EXCEPT !.firmUpIdValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Value Payload, selected by Tag                                          *)
(***************************************************************************)

ClearingAccountCode3 == 1  \* 0x01
ClearingAccountTypeCode3 == 2  \* 0x02
ClearingFirmCode3 == 3  \* 0x03
ClientReferenceCode3 == 4  \* 0x04
CrossTypeCode3 == 5  \* 0x05
DeaIndicatorCode3 == 6  \* 0x06
DisplayCode3 == 7  \* 0x07
DisplayPriceCode3 == 8  \* 0x08
DisplayQuantityCode3 == 9  \* 0x09
ExpireTimeCode3 == 10  \* 0x0a
FirmCode3 == 11  \* 0x0b
LiquidityProvisionIndicatorCode3 == 12  \* 0x0c
MaxFloorCode3 == 13  \* 0x0d
MinimumQuantityCode3 == 14  \* 0x0e
OrderReferenceCode3 == 15  \* 0x0f
OriginalOrderEntryDateCode3 == 16  \* 0x10
OriginalOrderReferenceNumberCode3 == 17  \* 0x11
PegDifferenceCode3 == 18  \* 0x12
PegTypeCode3 == 19  \* 0x13
RandomReserveCode3 == 20  \* 0x14
SecondaryOrderReferenceNumberCode3 == 21  \* 0x15
StpActionCode3 == 22  \* 0x16
StpLevelCode3 == 23  \* 0x17
StpTraderGroupCode3 == 24  \* 0x18
TimeInForceCode3 == 25  \* 0x19
TradingAtClosingPriceCode3 == 26  \* 0x1a
OrderConditionCode3 == 27  \* 0x1b
CumulativeQuantityCode3 == 28  \* 0x1c
CustomerOrderCapacityCode3 == 29  \* 0x1d
TargetStrategyCode3 == 30  \* 0x1e
MinRateCode3 == 31  \* 0x1f
MaxRateCode3 == 32  \* 0x20
ConditionalTypeCode3 == 33  \* 0x21
FirmUpIdCode3 == 34  \* 0x22

ValuePayload3 ==
    [ tag : {ClearingAccountCode3}, body : ClearingAccount3 ]
        \cup [ tag : {ClearingAccountTypeCode3}, body : ClearingAccountType3 ]
        \cup [ tag : {ClearingFirmCode3}, body : ClearingFirm3 ]
        \cup [ tag : {ClientReferenceCode3}, body : ClientReference3 ]
        \cup [ tag : {CrossTypeCode3}, body : CrossType3 ]
        \cup [ tag : {DeaIndicatorCode3}, body : DeaIndicator3 ]
        \cup [ tag : {DisplayCode3}, body : Display3 ]
        \cup [ tag : {DisplayPriceCode3}, body : DisplayPrice3 ]
        \cup [ tag : {DisplayQuantityCode3}, body : DisplayQuantity3 ]
        \cup [ tag : {ExpireTimeCode3}, body : ExpireTime3 ]
        \cup [ tag : {FirmCode3}, body : Firm3 ]
        \cup [ tag : {LiquidityProvisionIndicatorCode3}, body : LiquidityProvisionIndicator3 ]
        \cup [ tag : {MaxFloorCode3}, body : MaxFloor3 ]
        \cup [ tag : {MinimumQuantityCode3}, body : MinimumQuantity3 ]
        \cup [ tag : {OrderReferenceCode3}, body : OrderReference3 ]
        \cup [ tag : {OriginalOrderEntryDateCode3}, body : OriginalOrderEntryDate3 ]
        \cup [ tag : {OriginalOrderReferenceNumberCode3}, body : OriginalOrderReferenceNumber3 ]
        \cup [ tag : {PegDifferenceCode3}, body : PegDifference3 ]
        \cup [ tag : {PegTypeCode3}, body : PegType3 ]
        \cup [ tag : {RandomReserveCode3}, body : RandomReserve3 ]
        \cup [ tag : {SecondaryOrderReferenceNumberCode3}, body : SecondaryOrderReferenceNumber3 ]
        \cup [ tag : {StpActionCode3}, body : StpAction3 ]
        \cup [ tag : {StpLevelCode3}, body : StpLevel3 ]
        \cup [ tag : {StpTraderGroupCode3}, body : StpTraderGroup3 ]
        \cup [ tag : {TimeInForceCode3}, body : TimeInForce3 ]
        \cup [ tag : {TradingAtClosingPriceCode3}, body : TradingAtClosingPrice3 ]
        \cup [ tag : {OrderConditionCode3}, body : OrderCondition3 ]
        \cup [ tag : {CumulativeQuantityCode3}, body : CumulativeQuantity3 ]
        \cup [ tag : {CustomerOrderCapacityCode3}, body : CustomerOrderCapacity3 ]
        \cup [ tag : {TargetStrategyCode3}, body : TargetStrategy3 ]
        \cup [ tag : {MinRateCode3}, body : MinRate3 ]
        \cup [ tag : {MaxRateCode3}, body : MaxRate3 ]
        \cup [ tag : {ConditionalTypeCode3}, body : ConditionalType3 ]
        \cup [ tag : {FirmUpIdCode3}, body : FirmUpId3 ]

EncodeValuePayload3(message) ==
    CASE message.tag = ClearingAccountCode3 -> EncodeClearingAccount3(message.body)
      [] message.tag = ClearingAccountTypeCode3 -> EncodeClearingAccountType3(message.body)
      [] message.tag = ClearingFirmCode3 -> EncodeClearingFirm3(message.body)
      [] message.tag = ClientReferenceCode3 -> EncodeClientReference3(message.body)
      [] message.tag = CrossTypeCode3 -> EncodeCrossType3(message.body)
      [] message.tag = DeaIndicatorCode3 -> EncodeDeaIndicator3(message.body)
      [] message.tag = DisplayCode3 -> EncodeDisplay3(message.body)
      [] message.tag = DisplayPriceCode3 -> EncodeDisplayPrice3(message.body)
      [] message.tag = DisplayQuantityCode3 -> EncodeDisplayQuantity3(message.body)
      [] message.tag = ExpireTimeCode3 -> EncodeExpireTime3(message.body)
      [] message.tag = FirmCode3 -> EncodeFirm3(message.body)
      [] message.tag = LiquidityProvisionIndicatorCode3 -> EncodeLiquidityProvisionIndicator3(message.body)
      [] message.tag = MaxFloorCode3 -> EncodeMaxFloor3(message.body)
      [] message.tag = MinimumQuantityCode3 -> EncodeMinimumQuantity3(message.body)
      [] message.tag = OrderReferenceCode3 -> EncodeOrderReference3(message.body)
      [] message.tag = OriginalOrderEntryDateCode3 -> EncodeOriginalOrderEntryDate3(message.body)
      [] message.tag = OriginalOrderReferenceNumberCode3 -> EncodeOriginalOrderReferenceNumber3(message.body)
      [] message.tag = PegDifferenceCode3 -> EncodePegDifference3(message.body)
      [] message.tag = PegTypeCode3 -> EncodePegType3(message.body)
      [] message.tag = RandomReserveCode3 -> EncodeRandomReserve3(message.body)
      [] message.tag = SecondaryOrderReferenceNumberCode3 -> EncodeSecondaryOrderReferenceNumber3(message.body)
      [] message.tag = StpActionCode3 -> EncodeStpAction3(message.body)
      [] message.tag = StpLevelCode3 -> EncodeStpLevel3(message.body)
      [] message.tag = StpTraderGroupCode3 -> EncodeStpTraderGroup3(message.body)
      [] message.tag = TimeInForceCode3 -> EncodeTimeInForce3(message.body)
      [] message.tag = TradingAtClosingPriceCode3 -> EncodeTradingAtClosingPrice3(message.body)
      [] message.tag = OrderConditionCode3 -> EncodeOrderCondition3(message.body)
      [] message.tag = CumulativeQuantityCode3 -> EncodeCumulativeQuantity3(message.body)
      [] message.tag = CustomerOrderCapacityCode3 -> EncodeCustomerOrderCapacity3(message.body)
      [] message.tag = TargetStrategyCode3 -> EncodeTargetStrategy3(message.body)
      [] message.tag = MinRateCode3 -> EncodeMinRate3(message.body)
      [] message.tag = MaxRateCode3 -> EncodeMaxRate3(message.body)
      [] message.tag = ConditionalTypeCode3 -> EncodeConditionalType3(message.body)
      [] message.tag = FirmUpIdCode3 -> EncodeFirmUpId3(message.body)

DecodeValuePayload3(tag, bytes) ==
    LET read ==
            CASE tag = ClearingAccountCode3 -> DecodeClearingAccount3(bytes)
              [] tag = ClearingAccountTypeCode3 -> DecodeClearingAccountType3(bytes)
              [] tag = ClearingFirmCode3 -> DecodeClearingFirm3(bytes)
              [] tag = ClientReferenceCode3 -> DecodeClientReference3(bytes)
              [] tag = CrossTypeCode3 -> DecodeCrossType3(bytes)
              [] tag = DeaIndicatorCode3 -> DecodeDeaIndicator3(bytes)
              [] tag = DisplayCode3 -> DecodeDisplay3(bytes)
              [] tag = DisplayPriceCode3 -> DecodeDisplayPrice3(bytes)
              [] tag = DisplayQuantityCode3 -> DecodeDisplayQuantity3(bytes)
              [] tag = ExpireTimeCode3 -> DecodeExpireTime3(bytes)
              [] tag = FirmCode3 -> DecodeFirm3(bytes)
              [] tag = LiquidityProvisionIndicatorCode3 -> DecodeLiquidityProvisionIndicator3(bytes)
              [] tag = MaxFloorCode3 -> DecodeMaxFloor3(bytes)
              [] tag = MinimumQuantityCode3 -> DecodeMinimumQuantity3(bytes)
              [] tag = OrderReferenceCode3 -> DecodeOrderReference3(bytes)
              [] tag = OriginalOrderEntryDateCode3 -> DecodeOriginalOrderEntryDate3(bytes)
              [] tag = OriginalOrderReferenceNumberCode3 -> DecodeOriginalOrderReferenceNumber3(bytes)
              [] tag = PegDifferenceCode3 -> DecodePegDifference3(bytes)
              [] tag = PegTypeCode3 -> DecodePegType3(bytes)
              [] tag = RandomReserveCode3 -> DecodeRandomReserve3(bytes)
              [] tag = SecondaryOrderReferenceNumberCode3 -> DecodeSecondaryOrderReferenceNumber3(bytes)
              [] tag = StpActionCode3 -> DecodeStpAction3(bytes)
              [] tag = StpLevelCode3 -> DecodeStpLevel3(bytes)
              [] tag = StpTraderGroupCode3 -> DecodeStpTraderGroup3(bytes)
              [] tag = TimeInForceCode3 -> DecodeTimeInForce3(bytes)
              [] tag = TradingAtClosingPriceCode3 -> DecodeTradingAtClosingPrice3(bytes)
              [] tag = OrderConditionCode3 -> DecodeOrderCondition3(bytes)
              [] tag = CumulativeQuantityCode3 -> DecodeCumulativeQuantity3(bytes)
              [] tag = CustomerOrderCapacityCode3 -> DecodeCustomerOrderCapacity3(bytes)
              [] tag = TargetStrategyCode3 -> DecodeTargetStrategy3(bytes)
              [] tag = MinRateCode3 -> DecodeMinRate3(bytes)
              [] tag = MaxRateCode3 -> DecodeMaxRate3(bytes)
              [] tag = ConditionalTypeCode3 -> DecodeConditionalType3(bytes)
              [] tag = FirmUpIdCode3 -> DecodeFirmUpId3(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroValuePayload3 == [tag |-> ClearingAccountCode3, body |-> ZeroClearingAccount3]

(* Each Value Payload in turn, at the values the message it names is checked at *)
CheckedValuePayload3 ==
    { [tag |-> ClearingAccountCode3, body |-> one] : one \in CheckedClearingAccount3 }
        \cup { [tag |-> ClearingAccountTypeCode3, body |-> one] : one \in CheckedClearingAccountType3 }
        \cup { [tag |-> ClearingFirmCode3, body |-> one] : one \in CheckedClearingFirm3 }
        \cup { [tag |-> ClientReferenceCode3, body |-> one] : one \in CheckedClientReference3 }
        \cup { [tag |-> CrossTypeCode3, body |-> one] : one \in CheckedCrossType3 }
        \cup { [tag |-> DeaIndicatorCode3, body |-> one] : one \in CheckedDeaIndicator3 }
        \cup { [tag |-> DisplayCode3, body |-> one] : one \in CheckedDisplay3 }
        \cup { [tag |-> DisplayPriceCode3, body |-> one] : one \in CheckedDisplayPrice3 }
        \cup { [tag |-> DisplayQuantityCode3, body |-> one] : one \in CheckedDisplayQuantity3 }
        \cup { [tag |-> ExpireTimeCode3, body |-> one] : one \in CheckedExpireTime3 }
        \cup { [tag |-> FirmCode3, body |-> one] : one \in CheckedFirm3 }
        \cup { [tag |-> LiquidityProvisionIndicatorCode3, body |-> one] : one \in CheckedLiquidityProvisionIndicator3 }
        \cup { [tag |-> MaxFloorCode3, body |-> one] : one \in CheckedMaxFloor3 }
        \cup { [tag |-> MinimumQuantityCode3, body |-> one] : one \in CheckedMinimumQuantity3 }
        \cup { [tag |-> OrderReferenceCode3, body |-> one] : one \in CheckedOrderReference3 }
        \cup { [tag |-> OriginalOrderEntryDateCode3, body |-> one] : one \in CheckedOriginalOrderEntryDate3 }
        \cup { [tag |-> OriginalOrderReferenceNumberCode3, body |-> one] : one \in CheckedOriginalOrderReferenceNumber3 }
        \cup { [tag |-> PegDifferenceCode3, body |-> one] : one \in CheckedPegDifference3 }
        \cup { [tag |-> PegTypeCode3, body |-> one] : one \in CheckedPegType3 }
        \cup { [tag |-> RandomReserveCode3, body |-> one] : one \in CheckedRandomReserve3 }
        \cup { [tag |-> SecondaryOrderReferenceNumberCode3, body |-> one] : one \in CheckedSecondaryOrderReferenceNumber3 }
        \cup { [tag |-> StpActionCode3, body |-> one] : one \in CheckedStpAction3 }
        \cup { [tag |-> StpLevelCode3, body |-> one] : one \in CheckedStpLevel3 }
        \cup { [tag |-> StpTraderGroupCode3, body |-> one] : one \in CheckedStpTraderGroup3 }
        \cup { [tag |-> TimeInForceCode3, body |-> one] : one \in CheckedTimeInForce3 }
        \cup { [tag |-> TradingAtClosingPriceCode3, body |-> one] : one \in CheckedTradingAtClosingPrice3 }
        \cup { [tag |-> OrderConditionCode3, body |-> one] : one \in CheckedOrderCondition3 }
        \cup { [tag |-> CumulativeQuantityCode3, body |-> one] : one \in CheckedCumulativeQuantity3 }
        \cup { [tag |-> CustomerOrderCapacityCode3, body |-> one] : one \in CheckedCustomerOrderCapacity3 }
        \cup { [tag |-> TargetStrategyCode3, body |-> one] : one \in CheckedTargetStrategy3 }
        \cup { [tag |-> MinRateCode3, body |-> one] : one \in CheckedMinRate3 }
        \cup { [tag |-> MaxRateCode3, body |-> one] : one \in CheckedMaxRate3 }
        \cup { [tag |-> ConditionalTypeCode3, body |-> one] : one \in CheckedConditionalType3 }
        \cup { [tag |-> FirmUpIdCode3, body |-> one] : one \in CheckedFirmUpId3 }

(***************************************************************************)
(* TagValue, framed by Length                                              *)
(***************************************************************************)

Tagvalue3 ==
    [ valuePayload : ValuePayload3 ]

EncodeTagvalue3Body(message) ==
    EncodeUIntBE(message.valuePayload.tag, 1)
        \o EncodeValuePayload3(message.valuePayload)

(* Length counts the bytes it frames, so it is written from them *)
EncodeTagvalue3(message) ==
    LET body == EncodeTagvalue3Body(message)
    IN  EncodeUIntBE(Len(body), 1) \o body

DecodeTagvalue3Body(bytes) ==
    LET tag == ReadUIntBE(bytes, 1) IN IF ~tag.ok THEN Fail ELSE
    LET valuePayload == DecodeValuePayload3(tag.value, tag.rest) IN IF ~valuePayload.ok THEN Fail ELSE
    Ok([ valuePayload |-> valuePayload.value ], valuePayload.rest)

DecodeTagvalue3(bytes) ==
    LET length == ReadUIntBE(bytes, 1) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeTagvalue3Body(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroTagvalue3 ==
    [ valuePayload |-> ZeroValuePayload3 ]

(* TagValue at zero, then each field in turn at the values it is checked at *)
CheckedTagvalue3 ==
    { ZeroTagvalue3 }
        \cup { [ZeroTagvalue3 EXCEPT !.valuePayload = one] : one \in CheckedValuePayload3 }

(* A run of TagValue, written one after another *)
RECURSIVE EncodeTagvalue3List(_)
EncodeTagvalue3List(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTagvalue3(Head(messages)) \o EncodeTagvalue3List(Tail(messages))

(* As many TagValue as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadTagvalue3All(_)
ReadTagvalue3All(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeTagvalue3(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTagvalue3All(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One TagValue of each kind, for the lists that carry them *)
OneTagvalue3 ==
    { [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> ClearingAccountCode3, body |-> ZeroClearingAccount3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> ClearingAccountTypeCode3, body |-> ZeroClearingAccountType3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> ClearingFirmCode3, body |-> ZeroClearingFirm3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> ClientReferenceCode3, body |-> ZeroClientReference3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> CrossTypeCode3, body |-> ZeroCrossType3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> DeaIndicatorCode3, body |-> ZeroDeaIndicator3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> DisplayCode3, body |-> ZeroDisplay3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> DisplayPriceCode3, body |-> ZeroDisplayPrice3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> DisplayQuantityCode3, body |-> ZeroDisplayQuantity3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> ExpireTimeCode3, body |-> ZeroExpireTime3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> FirmCode3, body |-> ZeroFirm3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> LiquidityProvisionIndicatorCode3, body |-> ZeroLiquidityProvisionIndicator3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> MaxFloorCode3, body |-> ZeroMaxFloor3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> MinimumQuantityCode3, body |-> ZeroMinimumQuantity3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> OrderReferenceCode3, body |-> ZeroOrderReference3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> OriginalOrderEntryDateCode3, body |-> ZeroOriginalOrderEntryDate3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> OriginalOrderReferenceNumberCode3, body |-> ZeroOriginalOrderReferenceNumber3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> PegDifferenceCode3, body |-> ZeroPegDifference3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> PegTypeCode3, body |-> ZeroPegType3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> RandomReserveCode3, body |-> ZeroRandomReserve3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> SecondaryOrderReferenceNumberCode3, body |-> ZeroSecondaryOrderReferenceNumber3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> StpActionCode3, body |-> ZeroStpAction3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> StpLevelCode3, body |-> ZeroStpLevel3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> StpTraderGroupCode3, body |-> ZeroStpTraderGroup3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> TimeInForceCode3, body |-> ZeroTimeInForce3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> TradingAtClosingPriceCode3, body |-> ZeroTradingAtClosingPrice3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> OrderConditionCode3, body |-> ZeroOrderCondition3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> CumulativeQuantityCode3, body |-> ZeroCumulativeQuantity3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> CustomerOrderCapacityCode3, body |-> ZeroCustomerOrderCapacity3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> TargetStrategyCode3, body |-> ZeroTargetStrategy3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> MinRateCode3, body |-> ZeroMinRate3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> MaxRateCode3, body |-> ZeroMaxRate3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> ConditionalTypeCode3, body |-> ZeroConditionalType3]],
      [ZeroTagvalue3 EXCEPT !.valuePayload = [tag |-> FirmUpIdCode3, body |-> ZeroFirmUpId3]] }

(***************************************************************************)
(* Order Restated Message                                                  *)
(***************************************************************************)

OrderRestatedMessage ==
    [ timestamp     : Sample(8),
      userRefNum    : Sample(4),
      restateReason : Sample(1),
      tagvalue      : SampleLists(OneTagvalue3) ]

EncodeOrderRestatedMessage(message) ==
    LET payload == EncodeTagvalue3List(message.tagvalue)
    IN  message.timestamp
            \o message.userRefNum
            \o message.restateReason
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeOrderRestatedMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET restateReason == ReadBytes(userRefNum.rest, 1) IN IF ~restateReason.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(restateReason.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        tagvalue == ReadTagvalue3All(framed)
    IN  IF ~tagvalue.ok \/ tagvalue.rest # << >> THEN Fail ELSE
    Ok([ timestamp     |-> timestamp.value,
         userRefNum    |-> userRefNum.value,
         restateReason |-> restateReason.value,
         tagvalue      |-> tagvalue.value ], beyond)

ZeroOrderRestatedMessage ==
    [ timestamp     |-> [i \in 1 .. 8 |-> 0],
      userRefNum    |-> [i \in 1 .. 4 |-> 0],
      restateReason |-> [i \in 1 .. 1 |-> 0],
      tagvalue      |-> << >> ]

(* Order Restated Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderRestatedMessage ==
    { ZeroOrderRestatedMessage }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.restateReason = one] : one \in Sample(1) }
        \cup { [ZeroOrderRestatedMessage EXCEPT !.tagvalue = one] : one \in SampleLists(OneTagvalue3) }

(***************************************************************************)
(* Firm: 4 bytes                                                           *)
(***************************************************************************)

Firm4 ==
    [ firmValue : Sample(4) ]

EncodeFirm4(message) ==
    message.firmValue

DecodeFirm4(bytes) ==
    LET firmValue == ReadBytes(bytes, 4) IN IF ~firmValue.ok THEN Fail ELSE
    Ok([ firmValue |-> firmValue.value ], firmValue.rest)

ZeroFirm4 ==
    [ firmValue |-> [i \in 1 .. 4 |-> 0] ]

(* Firm at zero, then each field in turn at the values it is checked at *)
CheckedFirm4 ==
    { ZeroFirm4 }
        \cup { [ZeroFirm4 EXCEPT !.firmValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Mmo Refresh Request Message: 17 bytes                                   *)
(***************************************************************************)

MmoRefreshRequestMessage ==
    [ timestamp        : Sample(8),
      firm             : Firm4,
      orderBook        : Sample(4),
      mmoRefreshReason : Sample(1) ]

EncodeMmoRefreshRequestMessage(message) ==
    message.timestamp
        \o EncodeFirm4(message.firm)
        \o message.orderBook
        \o message.mmoRefreshReason

DecodeMmoRefreshRequestMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET firm == DecodeFirm4(timestamp.rest) IN IF ~firm.ok THEN Fail ELSE
    LET orderBook == ReadBytes(firm.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET mmoRefreshReason == ReadBytes(orderBook.rest, 1) IN IF ~mmoRefreshReason.ok THEN Fail ELSE
    Ok([ timestamp        |-> timestamp.value,
         firm             |-> firm.value,
         orderBook        |-> orderBook.value,
         mmoRefreshReason |-> mmoRefreshReason.value ], mmoRefreshReason.rest)

ZeroMmoRefreshRequestMessage ==
    [ timestamp        |-> [i \in 1 .. 8 |-> 0],
      firm             |-> ZeroFirm4,
      orderBook        |-> [i \in 1 .. 4 |-> 0],
      mmoRefreshReason |-> [i \in 1 .. 1 |-> 0] ]

(* Mmo Refresh Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMmoRefreshRequestMessage ==
    { ZeroMmoRefreshRequestMessage }
        \cup { [ZeroMmoRefreshRequestMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroMmoRefreshRequestMessage EXCEPT !.firm = one] : one \in CheckedFirm4 }
        \cup { [ZeroMmoRefreshRequestMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroMmoRefreshRequestMessage EXCEPT !.mmoRefreshReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Account Query Response Message: 12 bytes                                *)
(***************************************************************************)

AccountQueryResponseMessage ==
    [ timestamp      : Sample(8),
      nextUserRefNum : Sample(4) ]

EncodeAccountQueryResponseMessage(message) ==
    message.timestamp
        \o message.nextUserRefNum

DecodeAccountQueryResponseMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET nextUserRefNum == ReadBytes(timestamp.rest, 4) IN IF ~nextUserRefNum.ok THEN Fail ELSE
    Ok([ timestamp      |-> timestamp.value,
         nextUserRefNum |-> nextUserRefNum.value ], nextUserRefNum.rest)

ZeroAccountQueryResponseMessage ==
    [ timestamp      |-> [i \in 1 .. 8 |-> 0],
      nextUserRefNum |-> [i \in 1 .. 4 |-> 0] ]

(* Account Query Response Message at zero, then each field in turn at the values it is checked at *)
CheckedAccountQueryResponseMessage ==
    { ZeroAccountQueryResponseMessage }
        \cup { [ZeroAccountQueryResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroAccountQueryResponseMessage EXCEPT !.nextUserRefNum = one] : one \in Sample(4) }

(***************************************************************************)
(* Original Order Entry Date: 4 bytes                                      *)
(***************************************************************************)

OriginalOrderEntryDate4 ==
    [ originalOrderEntryDateValue : Sample(4) ]

EncodeOriginalOrderEntryDate4(message) ==
    message.originalOrderEntryDateValue

DecodeOriginalOrderEntryDate4(bytes) ==
    LET originalOrderEntryDateValue == ReadBytes(bytes, 4) IN IF ~originalOrderEntryDateValue.ok THEN Fail ELSE
    Ok([ originalOrderEntryDateValue |-> originalOrderEntryDateValue.value ], originalOrderEntryDateValue.rest)

ZeroOriginalOrderEntryDate4 ==
    [ originalOrderEntryDateValue |-> [i \in 1 .. 4 |-> 0] ]

(* Original Order Entry Date at zero, then each field in turn at the values it is checked at *)
CheckedOriginalOrderEntryDate4 ==
    { ZeroOriginalOrderEntryDate4 }
        \cup { [ZeroOriginalOrderEntryDate4 EXCEPT !.originalOrderEntryDateValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Original Order Reference Number: 8 bytes                                *)
(***************************************************************************)

OriginalOrderReferenceNumber4 ==
    [ originalOrderReferenceNumberValue : Sample(8) ]

EncodeOriginalOrderReferenceNumber4(message) ==
    message.originalOrderReferenceNumberValue

DecodeOriginalOrderReferenceNumber4(bytes) ==
    LET originalOrderReferenceNumberValue == ReadBytes(bytes, 8) IN IF ~originalOrderReferenceNumberValue.ok THEN Fail ELSE
    Ok([ originalOrderReferenceNumberValue |-> originalOrderReferenceNumberValue.value ], originalOrderReferenceNumberValue.rest)

ZeroOriginalOrderReferenceNumber4 ==
    [ originalOrderReferenceNumberValue |-> [i \in 1 .. 8 |-> 0] ]

(* Original Order Reference Number at zero, then each field in turn at the values it is checked at *)
CheckedOriginalOrderReferenceNumber4 ==
    { ZeroOriginalOrderReferenceNumber4 }
        \cup { [ZeroOriginalOrderReferenceNumber4 EXCEPT !.originalOrderReferenceNumberValue = one] : one \in Sample(8) }

(***************************************************************************)
(* Gtc Cancelled Message: 22 bytes                                         *)
(***************************************************************************)

GtcCancelledMessage ==
    [ timestamp                    : Sample(8),
      originalOrderEntryDate       : OriginalOrderEntryDate4,
      originalOrderReferenceNumber : OriginalOrderReferenceNumber4,
      reason                       : Sample(2) ]

EncodeGtcCancelledMessage(message) ==
    message.timestamp
        \o EncodeOriginalOrderEntryDate4(message.originalOrderEntryDate)
        \o EncodeOriginalOrderReferenceNumber4(message.originalOrderReferenceNumber)
        \o message.reason

DecodeGtcCancelledMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET originalOrderEntryDate == DecodeOriginalOrderEntryDate4(timestamp.rest) IN IF ~originalOrderEntryDate.ok THEN Fail ELSE
    LET originalOrderReferenceNumber == DecodeOriginalOrderReferenceNumber4(originalOrderEntryDate.rest) IN IF ~originalOrderReferenceNumber.ok THEN Fail ELSE
    LET reason == ReadBytes(originalOrderReferenceNumber.rest, 2) IN IF ~reason.ok THEN Fail ELSE
    Ok([ timestamp                    |-> timestamp.value,
         originalOrderEntryDate       |-> originalOrderEntryDate.value,
         originalOrderReferenceNumber |-> originalOrderReferenceNumber.value,
         reason                       |-> reason.value ], reason.rest)

ZeroGtcCancelledMessage ==
    [ timestamp                    |-> [i \in 1 .. 8 |-> 0],
      originalOrderEntryDate       |-> ZeroOriginalOrderEntryDate4,
      originalOrderReferenceNumber |-> ZeroOriginalOrderReferenceNumber4,
      reason                       |-> [i \in 1 .. 2 |-> 0] ]

(* Gtc Cancelled Message at zero, then each field in turn at the values it is checked at *)
CheckedGtcCancelledMessage ==
    { ZeroGtcCancelledMessage }
        \cup { [ZeroGtcCancelledMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroGtcCancelledMessage EXCEPT !.originalOrderEntryDate = one] : one \in CheckedOriginalOrderEntryDate4 }
        \cup { [ZeroGtcCancelledMessage EXCEPT !.originalOrderReferenceNumber = one] : one \in CheckedOriginalOrderReferenceNumber4 }
        \cup { [ZeroGtcCancelledMessage EXCEPT !.reason = one] : one \in Sample(2) }

(***************************************************************************)
(* Firm: 4 bytes                                                           *)
(***************************************************************************)

Firm5 ==
    [ firmValue : Sample(4) ]

EncodeFirm5(message) ==
    message.firmValue

DecodeFirm5(bytes) ==
    LET firmValue == ReadBytes(bytes, 4) IN IF ~firmValue.ok THEN Fail ELSE
    Ok([ firmValue |-> firmValue.value ], firmValue.rest)

ZeroFirm5 ==
    [ firmValue |-> [i \in 1 .. 4 |-> 0] ]

(* Firm at zero, then each field in turn at the values it is checked at *)
CheckedFirm5 ==
    { ZeroFirm5 }
        \cup { [ZeroFirm5 EXCEPT !.firmValue = one] : one \in Sample(4) }

(***************************************************************************)
(* Response To Mmi Notification Message: 29 bytes                          *)
(***************************************************************************)

ResponseToMmiNotificationMessage ==
    [ timestamp         : Sample(8),
      userRefNum        : Sample(4),
      orderBook         : Sample(4),
      instruction       : Sample(1),
      addOrRemove       : Sample(1),
      firm              : Firm5,
      user              : Sample(6),
      instructionStatus : Sample(1) ]

EncodeResponseToMmiNotificationMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.orderBook
        \o message.instruction
        \o message.addOrRemove
        \o EncodeFirm5(message.firm)
        \o message.user
        \o message.instructionStatus

DecodeResponseToMmiNotificationMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET orderBook == ReadBytes(userRefNum.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET instruction == ReadBytes(orderBook.rest, 1) IN IF ~instruction.ok THEN Fail ELSE
    LET addOrRemove == ReadBytes(instruction.rest, 1) IN IF ~addOrRemove.ok THEN Fail ELSE
    LET firm == DecodeFirm5(addOrRemove.rest) IN IF ~firm.ok THEN Fail ELSE
    LET user == ReadBytes(firm.rest, 6) IN IF ~user.ok THEN Fail ELSE
    LET instructionStatus == ReadBytes(user.rest, 1) IN IF ~instructionStatus.ok THEN Fail ELSE
    Ok([ timestamp         |-> timestamp.value,
         userRefNum        |-> userRefNum.value,
         orderBook         |-> orderBook.value,
         instruction       |-> instruction.value,
         addOrRemove       |-> addOrRemove.value,
         firm              |-> firm.value,
         user              |-> user.value,
         instructionStatus |-> instructionStatus.value ], instructionStatus.rest)

ZeroResponseToMmiNotificationMessage ==
    [ timestamp         |-> [i \in 1 .. 8 |-> 0],
      userRefNum        |-> [i \in 1 .. 4 |-> 0],
      orderBook         |-> [i \in 1 .. 4 |-> 0],
      instruction       |-> [i \in 1 .. 1 |-> 0],
      addOrRemove       |-> [i \in 1 .. 1 |-> 0],
      firm              |-> ZeroFirm5,
      user              |-> [i \in 1 .. 6 |-> 0],
      instructionStatus |-> [i \in 1 .. 1 |-> 0] ]

(* Response To Mmi Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedResponseToMmiNotificationMessage ==
    { ZeroResponseToMmiNotificationMessage }
        \cup { [ZeroResponseToMmiNotificationMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroResponseToMmiNotificationMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroResponseToMmiNotificationMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroResponseToMmiNotificationMessage EXCEPT !.instruction = one] : one \in Sample(1) }
        \cup { [ZeroResponseToMmiNotificationMessage EXCEPT !.addOrRemove = one] : one \in Sample(1) }
        \cup { [ZeroResponseToMmiNotificationMessage EXCEPT !.firm = one] : one \in CheckedFirm5 }
        \cup { [ZeroResponseToMmiNotificationMessage EXCEPT !.user = one] : one \in Sample(6) }
        \cup { [ZeroResponseToMmiNotificationMessage EXCEPT !.instructionStatus = one] : one \in Sample(1) }

(***************************************************************************)
(* Pending Order Message: 13 bytes                                         *)
(***************************************************************************)

PendingOrderMessage ==
    [ timestamp          : Sample(8),
      userRefNum         : Sample(4),
      pendingOrderReason : Sample(1) ]

EncodePendingOrderMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.pendingOrderReason

DecodePendingOrderMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET pendingOrderReason == ReadBytes(userRefNum.rest, 1) IN IF ~pendingOrderReason.ok THEN Fail ELSE
    Ok([ timestamp          |-> timestamp.value,
         userRefNum         |-> userRefNum.value,
         pendingOrderReason |-> pendingOrderReason.value ], pendingOrderReason.rest)

ZeroPendingOrderMessage ==
    [ timestamp          |-> [i \in 1 .. 8 |-> 0],
      userRefNum         |-> [i \in 1 .. 4 |-> 0],
      pendingOrderReason |-> [i \in 1 .. 1 |-> 0] ]

(* Pending Order Message at zero, then each field in turn at the values it is checked at *)
CheckedPendingOrderMessage ==
    { ZeroPendingOrderMessage }
        \cup { [ZeroPendingOrderMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroPendingOrderMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroPendingOrderMessage EXCEPT !.pendingOrderReason = one] : one \in Sample(1) }

(***************************************************************************)
(* Stream Status Message: 15 bytes                                         *)
(***************************************************************************)

StreamStatusMessage ==
    [ timestamp  : Sample(8),
      userRefNum : Sample(4),
      cumRate    : Sample(2),
      status     : Sample(1) ]

EncodeStreamStatusMessage(message) ==
    message.timestamp
        \o message.userRefNum
        \o message.cumRate
        \o message.status

DecodeStreamStatusMessage(bytes) ==
    LET timestamp == ReadBytes(bytes, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userRefNum == ReadBytes(timestamp.rest, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET cumRate == ReadBytes(userRefNum.rest, 2) IN IF ~cumRate.ok THEN Fail ELSE
    LET status == ReadBytes(cumRate.rest, 1) IN IF ~status.ok THEN Fail ELSE
    Ok([ timestamp  |-> timestamp.value,
         userRefNum |-> userRefNum.value,
         cumRate    |-> cumRate.value,
         status     |-> status.value ], status.rest)

ZeroStreamStatusMessage ==
    [ timestamp  |-> [i \in 1 .. 8 |-> 0],
      userRefNum |-> [i \in 1 .. 4 |-> 0],
      cumRate    |-> [i \in 1 .. 2 |-> 0],
      status     |-> [i \in 1 .. 1 |-> 0] ]

(* Stream Status Message at zero, then each field in turn at the values it is checked at *)
CheckedStreamStatusMessage ==
    { ZeroStreamStatusMessage }
        \cup { [ZeroStreamStatusMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroStreamStatusMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroStreamStatusMessage EXCEPT !.cumRate = one] : one \in Sample(2) }
        \cup { [ZeroStreamStatusMessage EXCEPT !.status = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message, selected by Sequenced Message Type                   *)
(***************************************************************************)

SystemEventMessageCode == 83  \* "S"
OrderAcceptedMessageCode == 65  \* "A"
OrderReplacedMessageCode == 85  \* "U"
CancelledOrderMessageCode == 67  \* "C"
CancelPendingMessageCode == 80  \* "P"
ReplacePendingMessageCode == 78  \* "N"
ExecutedOrderMessageCode == 69  \* "E"
BrokenTradeMessageCode == 66  \* "B"
RejectedOrderMessageCode == 74  \* "J"
CancelRejectedMessageCode == 73  \* "I"
OrderRestatedMessageCode == 84  \* "T"
MmoRefreshRequestMessageCode == 87  \* "W"
AccountQueryResponseMessageCode == 81  \* "Q"
GtcCancelledMessageCode == 71  \* "G"
ResponseToMmiNotificationMessageCode == 82  \* "R"
PendingOrderMessageCode == 77  \* "M"
StreamStatusMessageCode == 68  \* "D"

SequencedMessage ==
    [ tag : {SystemEventMessageCode}, body : SystemEventMessage ]
        \cup [ tag : {OrderAcceptedMessageCode}, body : OrderAcceptedMessage ]
        \cup [ tag : {OrderReplacedMessageCode}, body : OrderReplacedMessage ]
        \cup [ tag : {CancelledOrderMessageCode}, body : CancelledOrderMessage ]
        \cup [ tag : {CancelPendingMessageCode}, body : CancelPendingMessage ]
        \cup [ tag : {ReplacePendingMessageCode}, body : ReplacePendingMessage ]
        \cup [ tag : {ExecutedOrderMessageCode}, body : ExecutedOrderMessage ]
        \cup [ tag : {BrokenTradeMessageCode}, body : BrokenTradeMessage ]
        \cup [ tag : {RejectedOrderMessageCode}, body : RejectedOrderMessage ]
        \cup [ tag : {CancelRejectedMessageCode}, body : CancelRejectedMessage ]
        \cup [ tag : {OrderRestatedMessageCode}, body : OrderRestatedMessage ]
        \cup [ tag : {MmoRefreshRequestMessageCode}, body : MmoRefreshRequestMessage ]
        \cup [ tag : {AccountQueryResponseMessageCode}, body : AccountQueryResponseMessage ]
        \cup [ tag : {GtcCancelledMessageCode}, body : GtcCancelledMessage ]
        \cup [ tag : {ResponseToMmiNotificationMessageCode}, body : ResponseToMmiNotificationMessage ]
        \cup [ tag : {PendingOrderMessageCode}, body : PendingOrderMessage ]
        \cup [ tag : {StreamStatusMessageCode}, body : StreamStatusMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = SystemEventMessageCode -> EncodeSystemEventMessage(message.body)
      [] message.tag = OrderAcceptedMessageCode -> EncodeOrderAcceptedMessage(message.body)
      [] message.tag = OrderReplacedMessageCode -> EncodeOrderReplacedMessage(message.body)
      [] message.tag = CancelledOrderMessageCode -> EncodeCancelledOrderMessage(message.body)
      [] message.tag = CancelPendingMessageCode -> EncodeCancelPendingMessage(message.body)
      [] message.tag = ReplacePendingMessageCode -> EncodeReplacePendingMessage(message.body)
      [] message.tag = ExecutedOrderMessageCode -> EncodeExecutedOrderMessage(message.body)
      [] message.tag = BrokenTradeMessageCode -> EncodeBrokenTradeMessage(message.body)
      [] message.tag = RejectedOrderMessageCode -> EncodeRejectedOrderMessage(message.body)
      [] message.tag = CancelRejectedMessageCode -> EncodeCancelRejectedMessage(message.body)
      [] message.tag = OrderRestatedMessageCode -> EncodeOrderRestatedMessage(message.body)
      [] message.tag = MmoRefreshRequestMessageCode -> EncodeMmoRefreshRequestMessage(message.body)
      [] message.tag = AccountQueryResponseMessageCode -> EncodeAccountQueryResponseMessage(message.body)
      [] message.tag = GtcCancelledMessageCode -> EncodeGtcCancelledMessage(message.body)
      [] message.tag = ResponseToMmiNotificationMessageCode -> EncodeResponseToMmiNotificationMessage(message.body)
      [] message.tag = PendingOrderMessageCode -> EncodePendingOrderMessage(message.body)
      [] message.tag = StreamStatusMessageCode -> EncodeStreamStatusMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = SystemEventMessageCode -> DecodeSystemEventMessage(bytes)
              [] tag = OrderAcceptedMessageCode -> DecodeOrderAcceptedMessage(bytes)
              [] tag = OrderReplacedMessageCode -> DecodeOrderReplacedMessage(bytes)
              [] tag = CancelledOrderMessageCode -> DecodeCancelledOrderMessage(bytes)
              [] tag = CancelPendingMessageCode -> DecodeCancelPendingMessage(bytes)
              [] tag = ReplacePendingMessageCode -> DecodeReplacePendingMessage(bytes)
              [] tag = ExecutedOrderMessageCode -> DecodeExecutedOrderMessage(bytes)
              [] tag = BrokenTradeMessageCode -> DecodeBrokenTradeMessage(bytes)
              [] tag = RejectedOrderMessageCode -> DecodeRejectedOrderMessage(bytes)
              [] tag = CancelRejectedMessageCode -> DecodeCancelRejectedMessage(bytes)
              [] tag = OrderRestatedMessageCode -> DecodeOrderRestatedMessage(bytes)
              [] tag = MmoRefreshRequestMessageCode -> DecodeMmoRefreshRequestMessage(bytes)
              [] tag = AccountQueryResponseMessageCode -> DecodeAccountQueryResponseMessage(bytes)
              [] tag = GtcCancelledMessageCode -> DecodeGtcCancelledMessage(bytes)
              [] tag = ResponseToMmiNotificationMessageCode -> DecodeResponseToMmiNotificationMessage(bytes)
              [] tag = PendingOrderMessageCode -> DecodePendingOrderMessage(bytes)
              [] tag = StreamStatusMessageCode -> DecodeStreamStatusMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> SystemEventMessageCode, body |-> ZeroSystemEventMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> SystemEventMessageCode, body |-> one] : one \in CheckedSystemEventMessage }
        \cup { [tag |-> OrderAcceptedMessageCode, body |-> one] : one \in CheckedOrderAcceptedMessage }
        \cup { [tag |-> OrderReplacedMessageCode, body |-> one] : one \in CheckedOrderReplacedMessage }
        \cup { [tag |-> CancelledOrderMessageCode, body |-> one] : one \in CheckedCancelledOrderMessage }
        \cup { [tag |-> CancelPendingMessageCode, body |-> one] : one \in CheckedCancelPendingMessage }
        \cup { [tag |-> ReplacePendingMessageCode, body |-> one] : one \in CheckedReplacePendingMessage }
        \cup { [tag |-> ExecutedOrderMessageCode, body |-> one] : one \in CheckedExecutedOrderMessage }
        \cup { [tag |-> BrokenTradeMessageCode, body |-> one] : one \in CheckedBrokenTradeMessage }
        \cup { [tag |-> RejectedOrderMessageCode, body |-> one] : one \in CheckedRejectedOrderMessage }
        \cup { [tag |-> CancelRejectedMessageCode, body |-> one] : one \in CheckedCancelRejectedMessage }
        \cup { [tag |-> OrderRestatedMessageCode, body |-> one] : one \in CheckedOrderRestatedMessage }
        \cup { [tag |-> MmoRefreshRequestMessageCode, body |-> one] : one \in CheckedMmoRefreshRequestMessage }
        \cup { [tag |-> AccountQueryResponseMessageCode, body |-> one] : one \in CheckedAccountQueryResponseMessage }
        \cup { [tag |-> GtcCancelledMessageCode, body |-> one] : one \in CheckedGtcCancelledMessage }
        \cup { [tag |-> ResponseToMmiNotificationMessageCode, body |-> one] : one \in CheckedResponseToMmiNotificationMessage }
        \cup { [tag |-> PendingOrderMessageCode, body |-> one] : one \in CheckedPendingOrderMessage }
        \cup { [tag |-> StreamStatusMessageCode, body |-> one] : one \in CheckedStreamStatusMessage }

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

(* Every Clearing Account decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingAccount ==
    \A message \in CheckedClearingAccount :
        LET read == DecodeClearingAccount(EncodeClearingAccount(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Account Type decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingAccountType ==
    \A message \in CheckedClearingAccountType :
        LET read == DecodeClearingAccountType(EncodeClearingAccountType(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Firm decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingFirm ==
    \A message \in CheckedClearingFirm :
        LET read == DecodeClearingFirm(EncodeClearingFirm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Reference decodes back to what was encoded, and leaves nothing over *)
RoundTripClientReference ==
    \A message \in CheckedClientReference :
        LET read == DecodeClientReference(EncodeClientReference(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Type decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossType ==
    \A message \in CheckedCrossType :
        LET read == DecodeCrossType(EncodeCrossType(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dea Indicator decodes back to what was encoded, and leaves nothing over *)
RoundTripDeaIndicator ==
    \A message \in CheckedDeaIndicator :
        LET read == DecodeDeaIndicator(EncodeDeaIndicator(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Display decodes back to what was encoded, and leaves nothing over *)
RoundTripDisplay ==
    \A message \in CheckedDisplay :
        LET read == DecodeDisplay(EncodeDisplay(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Display Price decodes back to what was encoded, and leaves nothing over *)
RoundTripDisplayPrice ==
    \A message \in CheckedDisplayPrice :
        LET read == DecodeDisplayPrice(EncodeDisplayPrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Display Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripDisplayQuantity ==
    \A message \in CheckedDisplayQuantity :
        LET read == DecodeDisplayQuantity(EncodeDisplayQuantity(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expire Time decodes back to what was encoded, and leaves nothing over *)
RoundTripExpireTime ==
    \A message \in CheckedExpireTime :
        LET read == DecodeExpireTime(EncodeExpireTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm decodes back to what was encoded, and leaves nothing over *)
RoundTripFirm ==
    \A message \in CheckedFirm :
        LET read == DecodeFirm(EncodeFirm(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Provision Indicator decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityProvisionIndicator ==
    \A message \in CheckedLiquidityProvisionIndicator :
        LET read == DecodeLiquidityProvisionIndicator(EncodeLiquidityProvisionIndicator(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Max Floor decodes back to what was encoded, and leaves nothing over *)
RoundTripMaxFloor ==
    \A message \in CheckedMaxFloor :
        LET read == DecodeMaxFloor(EncodeMaxFloor(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Minimum Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripMinimumQuantity ==
    \A message \in CheckedMinimumQuantity :
        LET read == DecodeMinimumQuantity(EncodeMinimumQuantity(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Reference decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReference ==
    \A message \in CheckedOrderReference :
        LET read == DecodeOrderReference(EncodeOrderReference(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Order Entry Date decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalOrderEntryDate ==
    \A message \in CheckedOriginalOrderEntryDate :
        LET read == DecodeOriginalOrderEntryDate(EncodeOriginalOrderEntryDate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Order Reference Number decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalOrderReferenceNumber ==
    \A message \in CheckedOriginalOrderReferenceNumber :
        LET read == DecodeOriginalOrderReferenceNumber(EncodeOriginalOrderReferenceNumber(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Peg Difference decodes back to what was encoded, and leaves nothing over *)
RoundTripPegDifference ==
    \A message \in CheckedPegDifference :
        LET read == DecodePegDifference(EncodePegDifference(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Peg Type decodes back to what was encoded, and leaves nothing over *)
RoundTripPegType ==
    \A message \in CheckedPegType :
        LET read == DecodePegType(EncodePegType(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Random Reserve decodes back to what was encoded, and leaves nothing over *)
RoundTripRandomReserve ==
    \A message \in CheckedRandomReserve :
        LET read == DecodeRandomReserve(EncodeRandomReserve(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Order Reference Number decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryOrderReferenceNumber ==
    \A message \in CheckedSecondaryOrderReferenceNumber :
        LET read == DecodeSecondaryOrderReferenceNumber(EncodeSecondaryOrderReferenceNumber(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stp Action decodes back to what was encoded, and leaves nothing over *)
RoundTripStpAction ==
    \A message \in CheckedStpAction :
        LET read == DecodeStpAction(EncodeStpAction(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stp Level decodes back to what was encoded, and leaves nothing over *)
RoundTripStpLevel ==
    \A message \in CheckedStpLevel :
        LET read == DecodeStpLevel(EncodeStpLevel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stp Trader Group decodes back to what was encoded, and leaves nothing over *)
RoundTripStpTraderGroup ==
    \A message \in CheckedStpTraderGroup :
        LET read == DecodeStpTraderGroup(EncodeStpTraderGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Time In Force decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeInForce ==
    \A message \in CheckedTimeInForce :
        LET read == DecodeTimeInForce(EncodeTimeInForce(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading At Closing Price decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingAtClosingPrice ==
    \A message \in CheckedTradingAtClosingPrice :
        LET read == DecodeTradingAtClosingPrice(EncodeTradingAtClosingPrice(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Condition decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCondition ==
    \A message \in CheckedOrderCondition :
        LET read == DecodeOrderCondition(EncodeOrderCondition(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cumulative Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripCumulativeQuantity ==
    \A message \in CheckedCumulativeQuantity :
        LET read == DecodeCumulativeQuantity(EncodeCumulativeQuantity(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Customer Order Capacity decodes back to what was encoded, and leaves nothing over *)
RoundTripCustomerOrderCapacity ==
    \A message \in CheckedCustomerOrderCapacity :
        LET read == DecodeCustomerOrderCapacity(EncodeCustomerOrderCapacity(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Target Strategy decodes back to what was encoded, and leaves nothing over *)
RoundTripTargetStrategy ==
    \A message \in CheckedTargetStrategy :
        LET read == DecodeTargetStrategy(EncodeTargetStrategy(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Min Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripMinRate ==
    \A message \in CheckedMinRate :
        LET read == DecodeMinRate(EncodeMinRate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Max Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripMaxRate ==
    \A message \in CheckedMaxRate :
        LET read == DecodeMaxRate(EncodeMaxRate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Conditional Type decodes back to what was encoded, and leaves nothing over *)
RoundTripConditionalType ==
    \A message \in CheckedConditionalType :
        LET read == DecodeConditionalType(EncodeConditionalType(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm Up Id decodes back to what was encoded, and leaves nothing over *)
RoundTripFirmUpId ==
    \A message \in CheckedFirmUpId :
        LET read == DecodeFirmUpId(EncodeFirmUpId(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every TagValue decodes back to what was encoded, and leaves nothing over *)
RoundTripTagvalue ==
    \A message \in CheckedTagvalue :
        LET read == DecodeTagvalue(EncodeTagvalue(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAcceptedMessage ==
    \A message \in CheckedOrderAcceptedMessage :
        LET read == DecodeOrderAcceptedMessage(EncodeOrderAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Account decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingAccount2 ==
    \A message \in CheckedClearingAccount2 :
        LET read == DecodeClearingAccount2(EncodeClearingAccount2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Account Type decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingAccountType2 ==
    \A message \in CheckedClearingAccountType2 :
        LET read == DecodeClearingAccountType2(EncodeClearingAccountType2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Firm decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingFirm2 ==
    \A message \in CheckedClearingFirm2 :
        LET read == DecodeClearingFirm2(EncodeClearingFirm2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Reference decodes back to what was encoded, and leaves nothing over *)
RoundTripClientReference2 ==
    \A message \in CheckedClientReference2 :
        LET read == DecodeClientReference2(EncodeClientReference2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Type decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossType2 ==
    \A message \in CheckedCrossType2 :
        LET read == DecodeCrossType2(EncodeCrossType2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dea Indicator decodes back to what was encoded, and leaves nothing over *)
RoundTripDeaIndicator2 ==
    \A message \in CheckedDeaIndicator2 :
        LET read == DecodeDeaIndicator2(EncodeDeaIndicator2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Display decodes back to what was encoded, and leaves nothing over *)
RoundTripDisplay2 ==
    \A message \in CheckedDisplay2 :
        LET read == DecodeDisplay2(EncodeDisplay2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Display Price decodes back to what was encoded, and leaves nothing over *)
RoundTripDisplayPrice2 ==
    \A message \in CheckedDisplayPrice2 :
        LET read == DecodeDisplayPrice2(EncodeDisplayPrice2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Display Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripDisplayQuantity2 ==
    \A message \in CheckedDisplayQuantity2 :
        LET read == DecodeDisplayQuantity2(EncodeDisplayQuantity2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expire Time decodes back to what was encoded, and leaves nothing over *)
RoundTripExpireTime2 ==
    \A message \in CheckedExpireTime2 :
        LET read == DecodeExpireTime2(EncodeExpireTime2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm decodes back to what was encoded, and leaves nothing over *)
RoundTripFirm2 ==
    \A message \in CheckedFirm2 :
        LET read == DecodeFirm2(EncodeFirm2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Provision Indicator decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityProvisionIndicator2 ==
    \A message \in CheckedLiquidityProvisionIndicator2 :
        LET read == DecodeLiquidityProvisionIndicator2(EncodeLiquidityProvisionIndicator2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Max Floor decodes back to what was encoded, and leaves nothing over *)
RoundTripMaxFloor2 ==
    \A message \in CheckedMaxFloor2 :
        LET read == DecodeMaxFloor2(EncodeMaxFloor2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Minimum Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripMinimumQuantity2 ==
    \A message \in CheckedMinimumQuantity2 :
        LET read == DecodeMinimumQuantity2(EncodeMinimumQuantity2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Reference decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReference2 ==
    \A message \in CheckedOrderReference2 :
        LET read == DecodeOrderReference2(EncodeOrderReference2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Order Entry Date decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalOrderEntryDate2 ==
    \A message \in CheckedOriginalOrderEntryDate2 :
        LET read == DecodeOriginalOrderEntryDate2(EncodeOriginalOrderEntryDate2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Order Reference Number decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalOrderReferenceNumber2 ==
    \A message \in CheckedOriginalOrderReferenceNumber2 :
        LET read == DecodeOriginalOrderReferenceNumber2(EncodeOriginalOrderReferenceNumber2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Peg Difference decodes back to what was encoded, and leaves nothing over *)
RoundTripPegDifference2 ==
    \A message \in CheckedPegDifference2 :
        LET read == DecodePegDifference2(EncodePegDifference2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Peg Type decodes back to what was encoded, and leaves nothing over *)
RoundTripPegType2 ==
    \A message \in CheckedPegType2 :
        LET read == DecodePegType2(EncodePegType2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Random Reserve decodes back to what was encoded, and leaves nothing over *)
RoundTripRandomReserve2 ==
    \A message \in CheckedRandomReserve2 :
        LET read == DecodeRandomReserve2(EncodeRandomReserve2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Order Reference Number decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryOrderReferenceNumber2 ==
    \A message \in CheckedSecondaryOrderReferenceNumber2 :
        LET read == DecodeSecondaryOrderReferenceNumber2(EncodeSecondaryOrderReferenceNumber2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stp Action decodes back to what was encoded, and leaves nothing over *)
RoundTripStpAction2 ==
    \A message \in CheckedStpAction2 :
        LET read == DecodeStpAction2(EncodeStpAction2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stp Level decodes back to what was encoded, and leaves nothing over *)
RoundTripStpLevel2 ==
    \A message \in CheckedStpLevel2 :
        LET read == DecodeStpLevel2(EncodeStpLevel2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stp Trader Group decodes back to what was encoded, and leaves nothing over *)
RoundTripStpTraderGroup2 ==
    \A message \in CheckedStpTraderGroup2 :
        LET read == DecodeStpTraderGroup2(EncodeStpTraderGroup2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Time In Force decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeInForce2 ==
    \A message \in CheckedTimeInForce2 :
        LET read == DecodeTimeInForce2(EncodeTimeInForce2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading At Closing Price decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingAtClosingPrice2 ==
    \A message \in CheckedTradingAtClosingPrice2 :
        LET read == DecodeTradingAtClosingPrice2(EncodeTradingAtClosingPrice2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Condition decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCondition2 ==
    \A message \in CheckedOrderCondition2 :
        LET read == DecodeOrderCondition2(EncodeOrderCondition2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cumulative Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripCumulativeQuantity2 ==
    \A message \in CheckedCumulativeQuantity2 :
        LET read == DecodeCumulativeQuantity2(EncodeCumulativeQuantity2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Customer Order Capacity decodes back to what was encoded, and leaves nothing over *)
RoundTripCustomerOrderCapacity2 ==
    \A message \in CheckedCustomerOrderCapacity2 :
        LET read == DecodeCustomerOrderCapacity2(EncodeCustomerOrderCapacity2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Target Strategy decodes back to what was encoded, and leaves nothing over *)
RoundTripTargetStrategy2 ==
    \A message \in CheckedTargetStrategy2 :
        LET read == DecodeTargetStrategy2(EncodeTargetStrategy2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Min Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripMinRate2 ==
    \A message \in CheckedMinRate2 :
        LET read == DecodeMinRate2(EncodeMinRate2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Max Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripMaxRate2 ==
    \A message \in CheckedMaxRate2 :
        LET read == DecodeMaxRate2(EncodeMaxRate2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Conditional Type decodes back to what was encoded, and leaves nothing over *)
RoundTripConditionalType2 ==
    \A message \in CheckedConditionalType2 :
        LET read == DecodeConditionalType2(EncodeConditionalType2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm Up Id decodes back to what was encoded, and leaves nothing over *)
RoundTripFirmUpId2 ==
    \A message \in CheckedFirmUpId2 :
        LET read == DecodeFirmUpId2(EncodeFirmUpId2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every TagValue decodes back to what was encoded, and leaves nothing over *)
RoundTripTagvalue2 ==
    \A message \in CheckedTagvalue2 :
        LET read == DecodeTagvalue2(EncodeTagvalue2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Replaced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReplacedMessage ==
    \A message \in CheckedOrderReplacedMessage :
        LET read == DecodeOrderReplacedMessage(EncodeOrderReplacedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancelled Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelledOrderMessage ==
    \A message \in CheckedCancelledOrderMessage :
        LET read == DecodeCancelledOrderMessage(EncodeCancelledOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Pending Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelPendingMessage ==
    \A message \in CheckedCancelPendingMessage :
        LET read == DecodeCancelPendingMessage(EncodeCancelPendingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replace Pending Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplacePendingMessage ==
    \A message \in CheckedReplacePendingMessage :
        LET read == DecodeReplacePendingMessage(EncodeReplacePendingMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Executed Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutedOrderMessage ==
    \A message \in CheckedExecutedOrderMessage :
        LET read == DecodeExecutedOrderMessage(EncodeExecutedOrderMessage(message))
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

(* Every Rejected Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectedOrderMessage ==
    \A message \in CheckedRejectedOrderMessage :
        LET read == DecodeRejectedOrderMessage(EncodeRejectedOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Rejected Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelRejectedMessage ==
    \A message \in CheckedCancelRejectedMessage :
        LET read == DecodeCancelRejectedMessage(EncodeCancelRejectedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Account decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingAccount3 ==
    \A message \in CheckedClearingAccount3 :
        LET read == DecodeClearingAccount3(EncodeClearingAccount3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Account Type decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingAccountType3 ==
    \A message \in CheckedClearingAccountType3 :
        LET read == DecodeClearingAccountType3(EncodeClearingAccountType3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Clearing Firm decodes back to what was encoded, and leaves nothing over *)
RoundTripClearingFirm3 ==
    \A message \in CheckedClearingFirm3 :
        LET read == DecodeClearingFirm3(EncodeClearingFirm3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Reference decodes back to what was encoded, and leaves nothing over *)
RoundTripClientReference3 ==
    \A message \in CheckedClientReference3 :
        LET read == DecodeClientReference3(EncodeClientReference3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Type decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossType3 ==
    \A message \in CheckedCrossType3 :
        LET read == DecodeCrossType3(EncodeCrossType3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Dea Indicator decodes back to what was encoded, and leaves nothing over *)
RoundTripDeaIndicator3 ==
    \A message \in CheckedDeaIndicator3 :
        LET read == DecodeDeaIndicator3(EncodeDeaIndicator3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Display decodes back to what was encoded, and leaves nothing over *)
RoundTripDisplay3 ==
    \A message \in CheckedDisplay3 :
        LET read == DecodeDisplay3(EncodeDisplay3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Display Price decodes back to what was encoded, and leaves nothing over *)
RoundTripDisplayPrice3 ==
    \A message \in CheckedDisplayPrice3 :
        LET read == DecodeDisplayPrice3(EncodeDisplayPrice3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Display Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripDisplayQuantity3 ==
    \A message \in CheckedDisplayQuantity3 :
        LET read == DecodeDisplayQuantity3(EncodeDisplayQuantity3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Expire Time decodes back to what was encoded, and leaves nothing over *)
RoundTripExpireTime3 ==
    \A message \in CheckedExpireTime3 :
        LET read == DecodeExpireTime3(EncodeExpireTime3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm decodes back to what was encoded, and leaves nothing over *)
RoundTripFirm3 ==
    \A message \in CheckedFirm3 :
        LET read == DecodeFirm3(EncodeFirm3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Liquidity Provision Indicator decodes back to what was encoded, and leaves nothing over *)
RoundTripLiquidityProvisionIndicator3 ==
    \A message \in CheckedLiquidityProvisionIndicator3 :
        LET read == DecodeLiquidityProvisionIndicator3(EncodeLiquidityProvisionIndicator3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Max Floor decodes back to what was encoded, and leaves nothing over *)
RoundTripMaxFloor3 ==
    \A message \in CheckedMaxFloor3 :
        LET read == DecodeMaxFloor3(EncodeMaxFloor3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Minimum Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripMinimumQuantity3 ==
    \A message \in CheckedMinimumQuantity3 :
        LET read == DecodeMinimumQuantity3(EncodeMinimumQuantity3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Reference decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderReference3 ==
    \A message \in CheckedOrderReference3 :
        LET read == DecodeOrderReference3(EncodeOrderReference3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Order Entry Date decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalOrderEntryDate3 ==
    \A message \in CheckedOriginalOrderEntryDate3 :
        LET read == DecodeOriginalOrderEntryDate3(EncodeOriginalOrderEntryDate3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Order Reference Number decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalOrderReferenceNumber3 ==
    \A message \in CheckedOriginalOrderReferenceNumber3 :
        LET read == DecodeOriginalOrderReferenceNumber3(EncodeOriginalOrderReferenceNumber3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Peg Difference decodes back to what was encoded, and leaves nothing over *)
RoundTripPegDifference3 ==
    \A message \in CheckedPegDifference3 :
        LET read == DecodePegDifference3(EncodePegDifference3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Peg Type decodes back to what was encoded, and leaves nothing over *)
RoundTripPegType3 ==
    \A message \in CheckedPegType3 :
        LET read == DecodePegType3(EncodePegType3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Random Reserve decodes back to what was encoded, and leaves nothing over *)
RoundTripRandomReserve3 ==
    \A message \in CheckedRandomReserve3 :
        LET read == DecodeRandomReserve3(EncodeRandomReserve3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Secondary Order Reference Number decodes back to what was encoded, and leaves nothing over *)
RoundTripSecondaryOrderReferenceNumber3 ==
    \A message \in CheckedSecondaryOrderReferenceNumber3 :
        LET read == DecodeSecondaryOrderReferenceNumber3(EncodeSecondaryOrderReferenceNumber3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stp Action decodes back to what was encoded, and leaves nothing over *)
RoundTripStpAction3 ==
    \A message \in CheckedStpAction3 :
        LET read == DecodeStpAction3(EncodeStpAction3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stp Level decodes back to what was encoded, and leaves nothing over *)
RoundTripStpLevel3 ==
    \A message \in CheckedStpLevel3 :
        LET read == DecodeStpLevel3(EncodeStpLevel3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stp Trader Group decodes back to what was encoded, and leaves nothing over *)
RoundTripStpTraderGroup3 ==
    \A message \in CheckedStpTraderGroup3 :
        LET read == DecodeStpTraderGroup3(EncodeStpTraderGroup3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Time In Force decodes back to what was encoded, and leaves nothing over *)
RoundTripTimeInForce3 ==
    \A message \in CheckedTimeInForce3 :
        LET read == DecodeTimeInForce3(EncodeTimeInForce3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trading At Closing Price decodes back to what was encoded, and leaves nothing over *)
RoundTripTradingAtClosingPrice3 ==
    \A message \in CheckedTradingAtClosingPrice3 :
        LET read == DecodeTradingAtClosingPrice3(EncodeTradingAtClosingPrice3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Condition decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCondition3 ==
    \A message \in CheckedOrderCondition3 :
        LET read == DecodeOrderCondition3(EncodeOrderCondition3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cumulative Quantity decodes back to what was encoded, and leaves nothing over *)
RoundTripCumulativeQuantity3 ==
    \A message \in CheckedCumulativeQuantity3 :
        LET read == DecodeCumulativeQuantity3(EncodeCumulativeQuantity3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Customer Order Capacity decodes back to what was encoded, and leaves nothing over *)
RoundTripCustomerOrderCapacity3 ==
    \A message \in CheckedCustomerOrderCapacity3 :
        LET read == DecodeCustomerOrderCapacity3(EncodeCustomerOrderCapacity3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Target Strategy decodes back to what was encoded, and leaves nothing over *)
RoundTripTargetStrategy3 ==
    \A message \in CheckedTargetStrategy3 :
        LET read == DecodeTargetStrategy3(EncodeTargetStrategy3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Min Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripMinRate3 ==
    \A message \in CheckedMinRate3 :
        LET read == DecodeMinRate3(EncodeMinRate3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Max Rate decodes back to what was encoded, and leaves nothing over *)
RoundTripMaxRate3 ==
    \A message \in CheckedMaxRate3 :
        LET read == DecodeMaxRate3(EncodeMaxRate3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Conditional Type decodes back to what was encoded, and leaves nothing over *)
RoundTripConditionalType3 ==
    \A message \in CheckedConditionalType3 :
        LET read == DecodeConditionalType3(EncodeConditionalType3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm Up Id decodes back to what was encoded, and leaves nothing over *)
RoundTripFirmUpId3 ==
    \A message \in CheckedFirmUpId3 :
        LET read == DecodeFirmUpId3(EncodeFirmUpId3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every TagValue decodes back to what was encoded, and leaves nothing over *)
RoundTripTagvalue3 ==
    \A message \in CheckedTagvalue3 :
        LET read == DecodeTagvalue3(EncodeTagvalue3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Restated Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderRestatedMessage ==
    \A message \in CheckedOrderRestatedMessage :
        LET read == DecodeOrderRestatedMessage(EncodeOrderRestatedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm decodes back to what was encoded, and leaves nothing over *)
RoundTripFirm4 ==
    \A message \in CheckedFirm4 :
        LET read == DecodeFirm4(EncodeFirm4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mmo Refresh Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMmoRefreshRequestMessage ==
    \A message \in CheckedMmoRefreshRequestMessage :
        LET read == DecodeMmoRefreshRequestMessage(EncodeMmoRefreshRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Account Query Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripAccountQueryResponseMessage ==
    \A message \in CheckedAccountQueryResponseMessage :
        LET read == DecodeAccountQueryResponseMessage(EncodeAccountQueryResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Order Entry Date decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalOrderEntryDate4 ==
    \A message \in CheckedOriginalOrderEntryDate4 :
        LET read == DecodeOriginalOrderEntryDate4(EncodeOriginalOrderEntryDate4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Original Order Reference Number decodes back to what was encoded, and leaves nothing over *)
RoundTripOriginalOrderReferenceNumber4 ==
    \A message \in CheckedOriginalOrderReferenceNumber4 :
        LET read == DecodeOriginalOrderReferenceNumber4(EncodeOriginalOrderReferenceNumber4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Gtc Cancelled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripGtcCancelledMessage ==
    \A message \in CheckedGtcCancelledMessage :
        LET read == DecodeGtcCancelledMessage(EncodeGtcCancelledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Firm decodes back to what was encoded, and leaves nothing over *)
RoundTripFirm5 ==
    \A message \in CheckedFirm5 :
        LET read == DecodeFirm5(EncodeFirm5(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Response To Mmi Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripResponseToMmiNotificationMessage ==
    \A message \in CheckedResponseToMmiNotificationMessage :
        LET read == DecodeResponseToMmiNotificationMessage(EncodeResponseToMmiNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Pending Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPendingOrderMessage ==
    \A message \in CheckedPendingOrderMessage :
        LET read == DecodePendingOrderMessage(EncodePendingOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Stream Status Message decodes back to what was encoded, and leaves nothing over *)
RoundTripStreamStatusMessage ==
    \A message \in CheckedStreamStatusMessage :
        LET read == DecodeStreamStatusMessage(EncodeStreamStatusMessage(message))
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

(* A Value Payload is selected by the Tag it is written under *)
SelectsValuePayload ==
    \A message \in CheckedValuePayload :
        LET read == DecodeValuePayload(message.tag, EncodeValuePayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Value Payload is selected by the Tag it is written under *)
SelectsValuePayload2 ==
    \A message \in CheckedValuePayload2 :
        LET read == DecodeValuePayload2(message.tag, EncodeValuePayload2(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Value Payload is selected by the Tag it is written under *)
SelectsValuePayload3 ==
    \A message \in CheckedValuePayload3 :
        LET read == DecodeValuePayload3(message.tag, EncodeValuePayload3(message))
        IN  read.ok /\ read.value.tag = message.tag

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

(* Length is written from the bytes it frames *)
FramesTagvalue ==
    \A message \in CheckedTagvalue :
        LET bytes == EncodeTagvalue(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Length is written from the bytes it frames *)
FramesTagvalue2 ==
    \A message \in CheckedTagvalue2 :
        LET bytes == EncodeTagvalue2(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

(* Length is written from the bytes it frames *)
FramesTagvalue3 ==
    \A message \in CheckedTagvalue3 :
        LET bytes == EncodeTagvalue3(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 1)) = Len(bytes) - 1

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
