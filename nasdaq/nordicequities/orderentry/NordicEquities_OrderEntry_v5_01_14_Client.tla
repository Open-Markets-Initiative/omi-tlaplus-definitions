------------- MODULE NordicEquities_OrderEntry_v5_01_14_Client -------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Nordic Ouch 5 Order Entry v5.01.14                             *)
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
(* Note: Unsequenced Data Packet fills what is left of the frame Packet    *)
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
(* Login Request Packet: 46 bytes                                          *)
(***************************************************************************)

LoginRequestPacket ==
    [ username                : Sample(6),
      password                : Sample(10),
      requestedSession        : Sample(10),
      requestedSequenceNumber : Sample(20) ]

EncodeLoginRequestPacket(message) ==
    message.username
        \o message.password
        \o message.requestedSession
        \o message.requestedSequenceNumber

DecodeLoginRequestPacket(bytes) ==
    LET username == ReadBytes(bytes, 6) IN IF ~username.ok THEN Fail ELSE
    LET password == ReadBytes(username.rest, 10) IN IF ~password.ok THEN Fail ELSE
    LET requestedSession == ReadBytes(password.rest, 10) IN IF ~requestedSession.ok THEN Fail ELSE
    LET requestedSequenceNumber == ReadBytes(requestedSession.rest, 20) IN IF ~requestedSequenceNumber.ok THEN Fail ELSE
    Ok([ username                |-> username.value,
         password                |-> password.value,
         requestedSession        |-> requestedSession.value,
         requestedSequenceNumber |-> requestedSequenceNumber.value ], requestedSequenceNumber.rest)

ZeroLoginRequestPacket ==
    [ username                |-> [i \in 1 .. 6 |-> 0],
      password                |-> [i \in 1 .. 10 |-> 0],
      requestedSession        |-> [i \in 1 .. 10 |-> 0],
      requestedSequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Request Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginRequestPacket ==
    { ZeroLoginRequestPacket }
        \cup { [ZeroLoginRequestPacket EXCEPT !.username = one] : one \in Sample(6) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.password = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSession = one] : one \in Sample(10) }
        \cup { [ZeroLoginRequestPacket EXCEPT !.requestedSequenceNumber = one] : one \in Sample(20) }

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
      [ZeroTagvalue EXCEPT !.valuePayload = [tag |-> CustomerOrderCapacityCode, body |-> ZeroCustomerOrderCapacity]] }

(***************************************************************************)
(* Enter Order Message                                                     *)
(***************************************************************************)

EnterOrderMessage ==
    [ userRefNum                            : Sample(4),
      buySellIndicator                      : Sample(1),
      quantity                              : Sample(4),
      orderBook                             : Sample(4),
      price                                 : Sample(4),
      user                                  : Sample(6),
      executionWithinFirm                   : Sample(4),
      investmentDecisionWithinFirmShortCode : Sample(4),
      clientIdentifier                      : Sample(4),
      partyRoleQualifier                    : Sample(1),
      capacity                              : Sample(1),
      algoIndicator                         : Sample(1),
      tagvalue                              : SampleLists(OneTagvalue) ]

EncodeEnterOrderMessage(message) ==
    LET payload == EncodeTagvalueList(message.tagvalue)
    IN  message.userRefNum
            \o message.buySellIndicator
            \o message.quantity
            \o message.orderBook
            \o message.price
            \o message.user
            \o message.executionWithinFirm
            \o message.investmentDecisionWithinFirmShortCode
            \o message.clientIdentifier
            \o message.partyRoleQualifier
            \o message.capacity
            \o message.algoIndicator
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeEnterOrderMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET buySellIndicator == ReadBytes(userRefNum.rest, 1) IN IF ~buySellIndicator.ok THEN Fail ELSE
    LET quantity == ReadBytes(buySellIndicator.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET orderBook == ReadBytes(quantity.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET price == ReadBytes(orderBook.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET user == ReadBytes(price.rest, 6) IN IF ~user.ok THEN Fail ELSE
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
    Ok([ userRefNum                            |-> userRefNum.value,
         buySellIndicator                      |-> buySellIndicator.value,
         quantity                              |-> quantity.value,
         orderBook                             |-> orderBook.value,
         price                                 |-> price.value,
         user                                  |-> user.value,
         executionWithinFirm                   |-> executionWithinFirm.value,
         investmentDecisionWithinFirmShortCode |-> investmentDecisionWithinFirmShortCode.value,
         clientIdentifier                      |-> clientIdentifier.value,
         partyRoleQualifier                    |-> partyRoleQualifier.value,
         capacity                              |-> capacity.value,
         algoIndicator                         |-> algoIndicator.value,
         tagvalue                              |-> tagvalue.value ], beyond)

ZeroEnterOrderMessage ==
    [ userRefNum                            |-> [i \in 1 .. 4 |-> 0],
      buySellIndicator                      |-> [i \in 1 .. 1 |-> 0],
      quantity                              |-> [i \in 1 .. 4 |-> 0],
      orderBook                             |-> [i \in 1 .. 4 |-> 0],
      price                                 |-> [i \in 1 .. 4 |-> 0],
      user                                  |-> [i \in 1 .. 6 |-> 0],
      executionWithinFirm                   |-> [i \in 1 .. 4 |-> 0],
      investmentDecisionWithinFirmShortCode |-> [i \in 1 .. 4 |-> 0],
      clientIdentifier                      |-> [i \in 1 .. 4 |-> 0],
      partyRoleQualifier                    |-> [i \in 1 .. 1 |-> 0],
      capacity                              |-> [i \in 1 .. 1 |-> 0],
      algoIndicator                         |-> [i \in 1 .. 1 |-> 0],
      tagvalue                              |-> << >> ]

(* Enter Order Message at zero, then each field in turn at the values it is checked at *)
CheckedEnterOrderMessage ==
    { ZeroEnterOrderMessage }
        \cup { [ZeroEnterOrderMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.buySellIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.user = one] : one \in Sample(6) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.executionWithinFirm = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.investmentDecisionWithinFirmShortCode = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.clientIdentifier = one] : one \in Sample(4) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.partyRoleQualifier = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.algoIndicator = one] : one \in Sample(1) }
        \cup { [ZeroEnterOrderMessage EXCEPT !.tagvalue = one] : one \in SampleLists(OneTagvalue) }

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
      [ZeroTagvalue2 EXCEPT !.valuePayload = [tag |-> CustomerOrderCapacityCode2, body |-> ZeroCustomerOrderCapacity2]] }

(***************************************************************************)
(* Replace Order Message                                                   *)
(***************************************************************************)

ReplaceOrderMessage ==
    [ origUserRefNum : Sample(4),
      newUserRefNum  : Sample(4),
      quantity       : Sample(4),
      price          : Sample(4),
      user           : Sample(6),
      tagvalue       : SampleLists(OneTagvalue2) ]

EncodeReplaceOrderMessage(message) ==
    LET payload == EncodeTagvalue2List(message.tagvalue)
    IN  message.origUserRefNum
            \o message.newUserRefNum
            \o message.quantity
            \o message.price
            \o message.user
            \o EncodeUIntBE(Len(payload), 2)
            \o payload

DecodeReplaceOrderMessage(bytes) ==
    LET origUserRefNum == ReadBytes(bytes, 4) IN IF ~origUserRefNum.ok THEN Fail ELSE
    LET newUserRefNum == ReadBytes(origUserRefNum.rest, 4) IN IF ~newUserRefNum.ok THEN Fail ELSE
    LET quantity == ReadBytes(newUserRefNum.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET user == ReadBytes(price.rest, 6) IN IF ~user.ok THEN Fail ELSE
    LET appendageLength == ReadUIntBE(user.rest, 2) IN IF ~appendageLength.ok THEN Fail ELSE
    IF Len(appendageLength.rest) < appendageLength.value THEN Fail ELSE
    LET framed == SubSeq(appendageLength.rest, 1, appendageLength.value)
        beyond == SubSeq(appendageLength.rest, appendageLength.value + 1, Len(appendageLength.rest))
        tagvalue == ReadTagvalue2All(framed)
    IN  IF ~tagvalue.ok \/ tagvalue.rest # << >> THEN Fail ELSE
    Ok([ origUserRefNum |-> origUserRefNum.value,
         newUserRefNum  |-> newUserRefNum.value,
         quantity       |-> quantity.value,
         price          |-> price.value,
         user           |-> user.value,
         tagvalue       |-> tagvalue.value ], beyond)

ZeroReplaceOrderMessage ==
    [ origUserRefNum |-> [i \in 1 .. 4 |-> 0],
      newUserRefNum  |-> [i \in 1 .. 4 |-> 0],
      quantity       |-> [i \in 1 .. 4 |-> 0],
      price          |-> [i \in 1 .. 4 |-> 0],
      user           |-> [i \in 1 .. 6 |-> 0],
      tagvalue       |-> << >> ]

(* Replace Order Message at zero, then each field in turn at the values it is checked at *)
CheckedReplaceOrderMessage ==
    { ZeroReplaceOrderMessage }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.origUserRefNum = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.newUserRefNum = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.user = one] : one \in Sample(6) }
        \cup { [ZeroReplaceOrderMessage EXCEPT !.tagvalue = one] : one \in SampleLists(OneTagvalue2) }

(***************************************************************************)
(* Cancel Order Message: 14 bytes                                          *)
(***************************************************************************)

CancelOrderMessage ==
    [ userRefNum : Sample(4),
      quantity   : Sample(4),
      user       : Sample(6) ]

EncodeCancelOrderMessage(message) ==
    message.userRefNum
        \o message.quantity
        \o message.user

DecodeCancelOrderMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET quantity == ReadBytes(userRefNum.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET user == ReadBytes(quantity.rest, 6) IN IF ~user.ok THEN Fail ELSE
    Ok([ userRefNum |-> userRefNum.value,
         quantity   |-> quantity.value,
         user       |-> user.value ], user.rest)

ZeroCancelOrderMessage ==
    [ userRefNum |-> [i \in 1 .. 4 |-> 0],
      quantity   |-> [i \in 1 .. 4 |-> 0],
      user       |-> [i \in 1 .. 6 |-> 0] ]

(* Cancel Order Message at zero, then each field in turn at the values it is checked at *)
CheckedCancelOrderMessage ==
    { ZeroCancelOrderMessage }
        \cup { [ZeroCancelOrderMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroCancelOrderMessage EXCEPT !.user = one] : one \in Sample(6) }

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
(* Mmi Notification Request Message: 20 bytes                              *)
(***************************************************************************)

MmiNotificationRequestMessage ==
    [ userRefNum  : Sample(4),
      orderBook   : Sample(4),
      instruction : Sample(1),
      addOrRemove : Sample(1),
      firm        : Firm3,
      user        : Sample(6) ]

EncodeMmiNotificationRequestMessage(message) ==
    message.userRefNum
        \o message.orderBook
        \o message.instruction
        \o message.addOrRemove
        \o EncodeFirm3(message.firm)
        \o message.user

DecodeMmiNotificationRequestMessage(bytes) ==
    LET userRefNum == ReadBytes(bytes, 4) IN IF ~userRefNum.ok THEN Fail ELSE
    LET orderBook == ReadBytes(userRefNum.rest, 4) IN IF ~orderBook.ok THEN Fail ELSE
    LET instruction == ReadBytes(orderBook.rest, 1) IN IF ~instruction.ok THEN Fail ELSE
    LET addOrRemove == ReadBytes(instruction.rest, 1) IN IF ~addOrRemove.ok THEN Fail ELSE
    LET firm == DecodeFirm3(addOrRemove.rest) IN IF ~firm.ok THEN Fail ELSE
    LET user == ReadBytes(firm.rest, 6) IN IF ~user.ok THEN Fail ELSE
    Ok([ userRefNum  |-> userRefNum.value,
         orderBook   |-> orderBook.value,
         instruction |-> instruction.value,
         addOrRemove |-> addOrRemove.value,
         firm        |-> firm.value,
         user        |-> user.value ], user.rest)

ZeroMmiNotificationRequestMessage ==
    [ userRefNum  |-> [i \in 1 .. 4 |-> 0],
      orderBook   |-> [i \in 1 .. 4 |-> 0],
      instruction |-> [i \in 1 .. 1 |-> 0],
      addOrRemove |-> [i \in 1 .. 1 |-> 0],
      firm        |-> ZeroFirm3,
      user        |-> [i \in 1 .. 6 |-> 0] ]

(* Mmi Notification Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMmiNotificationRequestMessage ==
    { ZeroMmiNotificationRequestMessage }
        \cup { [ZeroMmiNotificationRequestMessage EXCEPT !.userRefNum = one] : one \in Sample(4) }
        \cup { [ZeroMmiNotificationRequestMessage EXCEPT !.orderBook = one] : one \in Sample(4) }
        \cup { [ZeroMmiNotificationRequestMessage EXCEPT !.instruction = one] : one \in Sample(1) }
        \cup { [ZeroMmiNotificationRequestMessage EXCEPT !.addOrRemove = one] : one \in Sample(1) }
        \cup { [ZeroMmiNotificationRequestMessage EXCEPT !.firm = one] : one \in CheckedFirm3 }
        \cup { [ZeroMmiNotificationRequestMessage EXCEPT !.user = one] : one \in Sample(6) }

(***************************************************************************)
(* Unsequenced Message, selected by Unsequenced Message Type               *)
(***************************************************************************)

EnterOrderMessageCode == 79  \* "O"
ReplaceOrderMessageCode == 85  \* "U"
CancelOrderMessageCode == 88  \* "X"
AccountQueryMessageCode == 81  \* "Q"
MmiNotificationRequestMessageCode == 77  \* "M"

UnsequencedMessage ==
    [ tag : {EnterOrderMessageCode}, body : EnterOrderMessage ]
        \cup [ tag : {ReplaceOrderMessageCode}, body : ReplaceOrderMessage ]
        \cup [ tag : {CancelOrderMessageCode}, body : CancelOrderMessage ]
        \cup [ tag : {AccountQueryMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {MmiNotificationRequestMessageCode}, body : MmiNotificationRequestMessage ]

EncodeUnsequencedMessage(message) ==
    CASE message.tag = EnterOrderMessageCode -> EncodeEnterOrderMessage(message.body)
      [] message.tag = ReplaceOrderMessageCode -> EncodeReplaceOrderMessage(message.body)
      [] message.tag = CancelOrderMessageCode -> EncodeCancelOrderMessage(message.body)
      [] message.tag = AccountQueryMessageCode -> << >>
      [] message.tag = MmiNotificationRequestMessageCode -> EncodeMmiNotificationRequestMessage(message.body)

DecodeUnsequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = EnterOrderMessageCode -> DecodeEnterOrderMessage(bytes)
              [] tag = ReplaceOrderMessageCode -> DecodeReplaceOrderMessage(bytes)
              [] tag = CancelOrderMessageCode -> DecodeCancelOrderMessage(bytes)
              [] tag = AccountQueryMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = MmiNotificationRequestMessageCode -> DecodeMmiNotificationRequestMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroUnsequencedMessage == [tag |-> EnterOrderMessageCode, body |-> ZeroEnterOrderMessage]

(* Each Unsequenced Message in turn, at the values the message it names is checked at *)
CheckedUnsequencedMessage ==
    { [tag |-> EnterOrderMessageCode, body |-> one] : one \in CheckedEnterOrderMessage }
        \cup { [tag |-> ReplaceOrderMessageCode, body |-> one] : one \in CheckedReplaceOrderMessage }
        \cup { [tag |-> CancelOrderMessageCode, body |-> one] : one \in CheckedCancelOrderMessage }
        \cup { [tag |-> AccountQueryMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> MmiNotificationRequestMessageCode, body |-> one] : one \in CheckedMmiNotificationRequestMessage }

(***************************************************************************)
(* Unsequenced Data Packet                                                 *)
(***************************************************************************)

UnsequencedDataPacket ==
    [ unsequencedMessage : UnsequencedMessage ]

EncodeUnsequencedDataPacket(message) ==
    EncodeUIntBE(message.unsequencedMessage.tag, 1)
        \o EncodeUnsequencedMessage(message.unsequencedMessage)

DecodeUnsequencedDataPacket(bytes) ==
    LET unsequencedMessageType == ReadUIntBE(bytes, 1) IN IF ~unsequencedMessageType.ok THEN Fail ELSE
    LET unsequencedMessage == DecodeUnsequencedMessage(unsequencedMessageType.value, unsequencedMessageType.rest) IN IF ~unsequencedMessage.ok THEN Fail ELSE
    Ok([ unsequencedMessage |-> unsequencedMessage.value ], unsequencedMessage.rest)

ZeroUnsequencedDataPacket ==
    [ unsequencedMessage |-> ZeroUnsequencedMessage ]

(* Unsequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedUnsequencedDataPacket ==
    { ZeroUnsequencedDataPacket }
        \cup { [ZeroUnsequencedDataPacket EXCEPT !.unsequencedMessage = one] : one \in CheckedUnsequencedMessage }

(***************************************************************************)
(* Client Payload, selected by Client Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginRequestPacketCode == 76  \* "L"
UnsequencedDataPacketCode == 85  \* "U"
ClientHeartbeatCode == 82  \* "R"
LogoutRequestCode == 79  \* "O"

ClientPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginRequestPacketCode}, body : LoginRequestPacket ]
        \cup [ tag : {UnsequencedDataPacketCode}, body : UnsequencedDataPacket ]
        \cup [ tag : {ClientHeartbeatCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutRequestCode}, body : {[empty |-> 0]} ]

EncodeClientPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginRequestPacketCode -> EncodeLoginRequestPacket(message.body)
      [] message.tag = UnsequencedDataPacketCode -> EncodeUnsequencedDataPacket(message.body)
      [] message.tag = ClientHeartbeatCode -> << >>
      [] message.tag = LogoutRequestCode -> << >>

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginRequestPacketCode -> DecodeLoginRequestPacket(bytes)
              [] tag = UnsequencedDataPacketCode -> DecodeUnsequencedDataPacket(bytes)
              [] tag = ClientHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutRequestCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginRequestPacketCode, body |-> one] : one \in CheckedLoginRequestPacket }
        \cup { [tag |-> UnsequencedDataPacketCode, body |-> one] : one \in CheckedUnsequencedDataPacket }
        \cup { [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutRequestCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Client Soup Bin Tcp Packet, framed by Packet Length                     *)
(***************************************************************************)

ClientSoupBinTcpPacket ==
    [ clientPayload : ClientPayload ]

EncodeClientSoupBinTcpPacketBody(message) ==
    EncodeUIntBE(message.clientPayload.tag, 1)
        \o EncodeClientPayload(message.clientPayload)

(* Packet Length counts the bytes it frames, so it is written from them *)
EncodeClientSoupBinTcpPacket(message) ==
    LET body == EncodeClientSoupBinTcpPacketBody(message)
    IN  EncodeUIntBE(Len(body), 2) \o body

DecodeClientSoupBinTcpPacketBody(bytes) ==
    LET clientPacketType == ReadUIntBE(bytes, 1) IN IF ~clientPacketType.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(clientPacketType.value, clientPacketType.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientSoupBinTcpPacket(bytes) ==
    LET length == ReadUIntBE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
        body   == DecodeClientSoupBinTcpPacketBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientSoupBinTcpPacket ==
    [ clientPayload |-> ZeroClientPayload ]

(* Client Soup Bin Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientSoupBinTcpPacket ==
    { ZeroClientSoupBinTcpPacket }
        \cup { [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Soup Bin Tcp Packet, written one after another *)
RECURSIVE EncodeClientSoupBinTcpPacketList(_)
EncodeClientSoupBinTcpPacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientSoupBinTcpPacket(Head(messages)) \o EncodeClientSoupBinTcpPacketList(Tail(messages))

(* As many Client Soup Bin Tcp Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientSoupBinTcpPacketAll(_)
ReadClientSoupBinTcpPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientSoupBinTcpPacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientSoupBinTcpPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Soup Bin Tcp Packet of each kind, for the lists that carry them *)
OneClientSoupBinTcpPacket ==
    { [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LoginRequestPacketCode, body |-> ZeroLoginRequestPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> UnsequencedDataPacketCode, body |-> ZeroUnsequencedDataPacket]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> ClientHeartbeatCode, body |-> [empty |-> 0]]],
      [ZeroClientSoupBinTcpPacket EXCEPT !.clientPayload = [tag |-> LogoutRequestCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientSoupBinTcpPacket : SampleLists(OneClientSoupBinTcpPacket) ]

EncodeClientPacket(message) ==
    EncodeClientSoupBinTcpPacketList(message.clientSoupBinTcpPacket)

DecodeClientPacket(bytes) ==
    LET clientSoupBinTcpPacket == ReadClientSoupBinTcpPacketAll(bytes) IN IF ~clientSoupBinTcpPacket.ok THEN Fail ELSE
    Ok([ clientSoupBinTcpPacket |-> clientSoupBinTcpPacket.value ], clientSoupBinTcpPacket.rest)

ZeroClientPacket ==
    [ clientSoupBinTcpPacket |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientSoupBinTcpPacket = one] : one \in SampleLists(OneClientSoupBinTcpPacket) }

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

(* Every Login Request Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginRequestPacket ==
    \A message \in CheckedLoginRequestPacket :
        LET read == DecodeLoginRequestPacket(EncodeLoginRequestPacket(message))
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

(* Every TagValue decodes back to what was encoded, and leaves nothing over *)
RoundTripTagvalue ==
    \A message \in CheckedTagvalue :
        LET read == DecodeTagvalue(EncodeTagvalue(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Enter Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripEnterOrderMessage ==
    \A message \in CheckedEnterOrderMessage :
        LET read == DecodeEnterOrderMessage(EncodeEnterOrderMessage(message))
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

(* Every TagValue decodes back to what was encoded, and leaves nothing over *)
RoundTripTagvalue2 ==
    \A message \in CheckedTagvalue2 :
        LET read == DecodeTagvalue2(EncodeTagvalue2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Replace Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripReplaceOrderMessage ==
    \A message \in CheckedReplaceOrderMessage :
        LET read == DecodeReplaceOrderMessage(EncodeReplaceOrderMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cancel Order Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCancelOrderMessage ==
    \A message \in CheckedCancelOrderMessage :
        LET read == DecodeCancelOrderMessage(EncodeCancelOrderMessage(message))
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

(* Every Mmi Notification Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMmiNotificationRequestMessage ==
    \A message \in CheckedMmiNotificationRequestMessage :
        LET read == DecodeMmiNotificationRequestMessage(EncodeMmiNotificationRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Unsequenced Data Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripUnsequencedDataPacket ==
    \A message \in CheckedUnsequencedDataPacket :
        LET read == DecodeUnsequencedDataPacket(EncodeUnsequencedDataPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Soup Bin Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSoupBinTcpPacket ==
    \A message \in CheckedClientSoupBinTcpPacket :
        LET read == DecodeClientSoupBinTcpPacket(EncodeClientSoupBinTcpPacket(message))
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

(* A Unsequenced Message is selected by the Unsequenced Message Type it is written under *)
SelectsUnsequencedMessage ==
    \A message \in CheckedUnsequencedMessage :
        LET read == DecodeUnsequencedMessage(message.tag, EncodeUnsequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Client Payload is selected by the Client Packet Type it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
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

(* Packet Length is written from the bytes it frames *)
FramesClientSoupBinTcpPacket ==
    \A message \in CheckedClientSoupBinTcpPacket :
        LET bytes == EncodeClientSoupBinTcpPacket(message)
        IN  DecodeUIntBE(SubSeq(bytes, 1, 2)) = Len(bytes) - 2

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
