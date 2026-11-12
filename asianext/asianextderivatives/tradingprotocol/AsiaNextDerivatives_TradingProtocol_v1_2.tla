------------- MODULE AsiaNextDerivatives_TradingProtocol_v1_2 --------------
(***************************************************************************)
(* AsiaNext Aquis Trading Protocol v1.2                                    *)
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
(* Login Message: 44 bytes                                                 *)
(***************************************************************************)

LoginMessage ==
    [ protocolVersion   : Sample(2),
      senderId          : Sample(16),
      password          : Sample(16),
      inactivityTimeout : Sample(2),
      atpSeqNo          : Sample(8) ]

EncodeLoginMessage(message) ==
    message.protocolVersion
        \o message.senderId
        \o message.password
        \o message.inactivityTimeout
        \o message.atpSeqNo

DecodeLoginMessage(bytes) ==
    LET protocolVersion == ReadBytes(bytes, 2) IN IF ~protocolVersion.ok THEN Fail ELSE
    LET senderId == ReadBytes(protocolVersion.rest, 16) IN IF ~senderId.ok THEN Fail ELSE
    LET password == ReadBytes(senderId.rest, 16) IN IF ~password.ok THEN Fail ELSE
    LET inactivityTimeout == ReadBytes(password.rest, 2) IN IF ~inactivityTimeout.ok THEN Fail ELSE
    LET atpSeqNo == ReadBytes(inactivityTimeout.rest, 8) IN IF ~atpSeqNo.ok THEN Fail ELSE
    Ok([ protocolVersion   |-> protocolVersion.value,
         senderId          |-> senderId.value,
         password          |-> password.value,
         inactivityTimeout |-> inactivityTimeout.value,
         atpSeqNo          |-> atpSeqNo.value ], atpSeqNo.rest)

ZeroLoginMessage ==
    [ protocolVersion   |-> [i \in 1 .. 2 |-> 0],
      senderId          |-> [i \in 1 .. 16 |-> 0],
      password          |-> [i \in 1 .. 16 |-> 0],
      inactivityTimeout |-> [i \in 1 .. 2 |-> 0],
      atpSeqNo          |-> [i \in 1 .. 8 |-> 0] ]

(* Login Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginMessage ==
    { ZeroLoginMessage }
        \cup { [ZeroLoginMessage EXCEPT !.protocolVersion = one] : one \in Sample(2) }
        \cup { [ZeroLoginMessage EXCEPT !.senderId = one] : one \in Sample(16) }
        \cup { [ZeroLoginMessage EXCEPT !.password = one] : one \in Sample(16) }
        \cup { [ZeroLoginMessage EXCEPT !.inactivityTimeout = one] : one \in Sample(2) }
        \cup { [ZeroLoginMessage EXCEPT !.atpSeqNo = one] : one \in Sample(8) }

(***************************************************************************)
(* Login Response Message: 9 bytes                                         *)
(***************************************************************************)

LoginResponseMessage ==
    [ resultCode  : Sample(1),
      clientSeqNo : Sample(8) ]

EncodeLoginResponseMessage(message) ==
    message.resultCode
        \o message.clientSeqNo

DecodeLoginResponseMessage(bytes) ==
    LET resultCode == ReadBytes(bytes, 1) IN IF ~resultCode.ok THEN Fail ELSE
    LET clientSeqNo == ReadBytes(resultCode.rest, 8) IN IF ~clientSeqNo.ok THEN Fail ELSE
    Ok([ resultCode  |-> resultCode.value,
         clientSeqNo |-> clientSeqNo.value ], clientSeqNo.rest)

ZeroLoginResponseMessage ==
    [ resultCode  |-> [i \in 1 .. 1 |-> 0],
      clientSeqNo |-> [i \in 1 .. 8 |-> 0] ]

(* Login Response Message at zero, then each field in turn at the values it is checked at *)
CheckedLoginResponseMessage ==
    { ZeroLoginResponseMessage }
        \cup { [ZeroLoginResponseMessage EXCEPT !.resultCode = one] : one \in Sample(1) }
        \cup { [ZeroLoginResponseMessage EXCEPT !.clientSeqNo = one] : one \in Sample(8) }

(***************************************************************************)
(* Logout Message: 33 bytes                                                *)
(***************************************************************************)

LogoutMessage ==
    [ logoutReasonCode : Sample(1),
      reasonText       : Sample(32) ]

EncodeLogoutMessage(message) ==
    message.logoutReasonCode
        \o message.reasonText

DecodeLogoutMessage(bytes) ==
    LET logoutReasonCode == ReadBytes(bytes, 1) IN IF ~logoutReasonCode.ok THEN Fail ELSE
    LET reasonText == ReadBytes(logoutReasonCode.rest, 32) IN IF ~reasonText.ok THEN Fail ELSE
    Ok([ logoutReasonCode |-> logoutReasonCode.value,
         reasonText       |-> reasonText.value ], reasonText.rest)

ZeroLogoutMessage ==
    [ logoutReasonCode |-> [i \in 1 .. 1 |-> 0],
      reasonText       |-> [i \in 1 .. 32 |-> 0] ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.logoutReasonCode = one] : one \in Sample(1) }
        \cup { [ZeroLogoutMessage EXCEPT !.reasonText = one] : one \in Sample(32) }

(***************************************************************************)
(* Order Add Message: 46 bytes                                             *)
(***************************************************************************)

OrderAddMessage ==
    [ securityIdLong : Sample(4),
      orderType      : Sample(1),
      timeInForce    : Sample(1),
      side           : Sample(1),
      quantity       : Sample(4),
      price          : Sample(8),
      orderCapacity  : Sample(1),
      account        : Sample(2),
      userTag        : Sample(8),
      flags          : Sample(1),
      tableSelect1   : Sample(1),
      shortCode1     : Sample(4),
      tableSelect2   : Sample(1),
      shortCode2     : Sample(4),
      tableSelect3   : Sample(1),
      shortCode3     : Sample(4) ]

EncodeOrderAddMessage(message) ==
    message.securityIdLong
        \o message.orderType
        \o message.timeInForce
        \o message.side
        \o message.quantity
        \o message.price
        \o message.orderCapacity
        \o message.account
        \o message.userTag
        \o message.flags
        \o message.tableSelect1
        \o message.shortCode1
        \o message.tableSelect2
        \o message.shortCode2
        \o message.tableSelect3
        \o message.shortCode3

DecodeOrderAddMessage(bytes) ==
    LET securityIdLong == ReadBytes(bytes, 4) IN IF ~securityIdLong.ok THEN Fail ELSE
    LET orderType == ReadBytes(securityIdLong.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(orderType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET side == ReadBytes(timeInForce.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(price.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET account == ReadBytes(orderCapacity.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET userTag == ReadBytes(account.rest, 8) IN IF ~userTag.ok THEN Fail ELSE
    LET flags == ReadBytes(userTag.rest, 1) IN IF ~flags.ok THEN Fail ELSE
    LET tableSelect1 == ReadBytes(flags.rest, 1) IN IF ~tableSelect1.ok THEN Fail ELSE
    LET shortCode1 == ReadBytes(tableSelect1.rest, 4) IN IF ~shortCode1.ok THEN Fail ELSE
    LET tableSelect2 == ReadBytes(shortCode1.rest, 1) IN IF ~tableSelect2.ok THEN Fail ELSE
    LET shortCode2 == ReadBytes(tableSelect2.rest, 4) IN IF ~shortCode2.ok THEN Fail ELSE
    LET tableSelect3 == ReadBytes(shortCode2.rest, 1) IN IF ~tableSelect3.ok THEN Fail ELSE
    LET shortCode3 == ReadBytes(tableSelect3.rest, 4) IN IF ~shortCode3.ok THEN Fail ELSE
    Ok([ securityIdLong |-> securityIdLong.value,
         orderType      |-> orderType.value,
         timeInForce    |-> timeInForce.value,
         side           |-> side.value,
         quantity       |-> quantity.value,
         price          |-> price.value,
         orderCapacity  |-> orderCapacity.value,
         account        |-> account.value,
         userTag        |-> userTag.value,
         flags          |-> flags.value,
         tableSelect1   |-> tableSelect1.value,
         shortCode1     |-> shortCode1.value,
         tableSelect2   |-> tableSelect2.value,
         shortCode2     |-> shortCode2.value,
         tableSelect3   |-> tableSelect3.value,
         shortCode3     |-> shortCode3.value ], shortCode3.rest)

ZeroOrderAddMessage ==
    [ securityIdLong |-> [i \in 1 .. 4 |-> 0],
      orderType      |-> [i \in 1 .. 1 |-> 0],
      timeInForce    |-> [i \in 1 .. 1 |-> 0],
      side           |-> [i \in 1 .. 1 |-> 0],
      quantity       |-> [i \in 1 .. 4 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      orderCapacity  |-> [i \in 1 .. 1 |-> 0],
      account        |-> [i \in 1 .. 2 |-> 0],
      userTag        |-> [i \in 1 .. 8 |-> 0],
      flags          |-> [i \in 1 .. 1 |-> 0],
      tableSelect1   |-> [i \in 1 .. 1 |-> 0],
      shortCode1     |-> [i \in 1 .. 4 |-> 0],
      tableSelect2   |-> [i \in 1 .. 1 |-> 0],
      shortCode2     |-> [i \in 1 .. 4 |-> 0],
      tableSelect3   |-> [i \in 1 .. 1 |-> 0],
      shortCode3     |-> [i \in 1 .. 4 |-> 0] ]

(* Order Add Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddMessage ==
    { ZeroOrderAddMessage }
        \cup { [ZeroOrderAddMessage EXCEPT !.securityIdLong = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddMessage EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroOrderAddMessage EXCEPT !.userTag = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddMessage EXCEPT !.flags = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddMessage EXCEPT !.tableSelect1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddMessage EXCEPT !.shortCode1 = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddMessage EXCEPT !.tableSelect2 = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddMessage EXCEPT !.shortCode2 = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddMessage EXCEPT !.tableSelect3 = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddMessage EXCEPT !.shortCode3 = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Add Extended Message: 71 bytes                                    *)
(***************************************************************************)

OrderAddExtendedMessage ==
    [ securityIdLong     : Sample(4),
      orderType          : Sample(1),
      timeInForce        : Sample(1),
      side               : Sample(1),
      quantity           : Sample(4),
      price              : Sample(8),
      orderCapacity      : Sample(1),
      account            : Sample(2),
      userTag            : Sample(8),
      flags              : Sample(1),
      tableSelect1       : Sample(1),
      shortCode1         : Sample(4),
      tableSelect2       : Sample(1),
      shortCode2         : Sample(4),
      tableSelect3       : Sample(1),
      shortCode3         : Sample(4),
      displayQuantity    : Sample(4),
      minQty             : Sample(4),
      extendedOrderFlags : Sample(1),
      expireTime         : Sample(8),
      rfqSessionId       : Sample(8) ]

EncodeOrderAddExtendedMessage(message) ==
    message.securityIdLong
        \o message.orderType
        \o message.timeInForce
        \o message.side
        \o message.quantity
        \o message.price
        \o message.orderCapacity
        \o message.account
        \o message.userTag
        \o message.flags
        \o message.tableSelect1
        \o message.shortCode1
        \o message.tableSelect2
        \o message.shortCode2
        \o message.tableSelect3
        \o message.shortCode3
        \o message.displayQuantity
        \o message.minQty
        \o message.extendedOrderFlags
        \o message.expireTime
        \o message.rfqSessionId

DecodeOrderAddExtendedMessage(bytes) ==
    LET securityIdLong == ReadBytes(bytes, 4) IN IF ~securityIdLong.ok THEN Fail ELSE
    LET orderType == ReadBytes(securityIdLong.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(orderType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET side == ReadBytes(timeInForce.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(price.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET account == ReadBytes(orderCapacity.rest, 2) IN IF ~account.ok THEN Fail ELSE
    LET userTag == ReadBytes(account.rest, 8) IN IF ~userTag.ok THEN Fail ELSE
    LET flags == ReadBytes(userTag.rest, 1) IN IF ~flags.ok THEN Fail ELSE
    LET tableSelect1 == ReadBytes(flags.rest, 1) IN IF ~tableSelect1.ok THEN Fail ELSE
    LET shortCode1 == ReadBytes(tableSelect1.rest, 4) IN IF ~shortCode1.ok THEN Fail ELSE
    LET tableSelect2 == ReadBytes(shortCode1.rest, 1) IN IF ~tableSelect2.ok THEN Fail ELSE
    LET shortCode2 == ReadBytes(tableSelect2.rest, 4) IN IF ~shortCode2.ok THEN Fail ELSE
    LET tableSelect3 == ReadBytes(shortCode2.rest, 1) IN IF ~tableSelect3.ok THEN Fail ELSE
    LET shortCode3 == ReadBytes(tableSelect3.rest, 4) IN IF ~shortCode3.ok THEN Fail ELSE
    LET displayQuantity == ReadBytes(shortCode3.rest, 4) IN IF ~displayQuantity.ok THEN Fail ELSE
    LET minQty == ReadBytes(displayQuantity.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET extendedOrderFlags == ReadBytes(minQty.rest, 1) IN IF ~extendedOrderFlags.ok THEN Fail ELSE
    LET expireTime == ReadBytes(extendedOrderFlags.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    LET rfqSessionId == ReadBytes(expireTime.rest, 8) IN IF ~rfqSessionId.ok THEN Fail ELSE
    Ok([ securityIdLong     |-> securityIdLong.value,
         orderType          |-> orderType.value,
         timeInForce        |-> timeInForce.value,
         side               |-> side.value,
         quantity           |-> quantity.value,
         price              |-> price.value,
         orderCapacity      |-> orderCapacity.value,
         account            |-> account.value,
         userTag            |-> userTag.value,
         flags              |-> flags.value,
         tableSelect1       |-> tableSelect1.value,
         shortCode1         |-> shortCode1.value,
         tableSelect2       |-> tableSelect2.value,
         shortCode2         |-> shortCode2.value,
         tableSelect3       |-> tableSelect3.value,
         shortCode3         |-> shortCode3.value,
         displayQuantity    |-> displayQuantity.value,
         minQty             |-> minQty.value,
         extendedOrderFlags |-> extendedOrderFlags.value,
         expireTime         |-> expireTime.value,
         rfqSessionId       |-> rfqSessionId.value ], rfqSessionId.rest)

ZeroOrderAddExtendedMessage ==
    [ securityIdLong     |-> [i \in 1 .. 4 |-> 0],
      orderType          |-> [i \in 1 .. 1 |-> 0],
      timeInForce        |-> [i \in 1 .. 1 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      quantity           |-> [i \in 1 .. 4 |-> 0],
      price              |-> [i \in 1 .. 8 |-> 0],
      orderCapacity      |-> [i \in 1 .. 1 |-> 0],
      account            |-> [i \in 1 .. 2 |-> 0],
      userTag            |-> [i \in 1 .. 8 |-> 0],
      flags              |-> [i \in 1 .. 1 |-> 0],
      tableSelect1       |-> [i \in 1 .. 1 |-> 0],
      shortCode1         |-> [i \in 1 .. 4 |-> 0],
      tableSelect2       |-> [i \in 1 .. 1 |-> 0],
      shortCode2         |-> [i \in 1 .. 4 |-> 0],
      tableSelect3       |-> [i \in 1 .. 1 |-> 0],
      shortCode3         |-> [i \in 1 .. 4 |-> 0],
      displayQuantity    |-> [i \in 1 .. 4 |-> 0],
      minQty             |-> [i \in 1 .. 4 |-> 0],
      extendedOrderFlags |-> [i \in 1 .. 1 |-> 0],
      expireTime         |-> [i \in 1 .. 8 |-> 0],
      rfqSessionId       |-> [i \in 1 .. 8 |-> 0] ]

(* Order Add Extended Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddExtendedMessage ==
    { ZeroOrderAddExtendedMessage }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.securityIdLong = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.account = one] : one \in Sample(2) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.userTag = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.flags = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.tableSelect1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.shortCode1 = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.tableSelect2 = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.shortCode2 = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.tableSelect3 = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.shortCode3 = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.displayQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.extendedOrderFlags = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.expireTime = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddExtendedMessage EXCEPT !.rfqSessionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancel Message: 32 bytes                                          *)
(***************************************************************************)

OrderCancelMessage ==
    [ orderRef     : Sample(8),
      userTag      : Sample(8),
      flags        : Sample(1),
      tableSelect1 : Sample(1),
      shortCode1   : Sample(4),
      tableSelect2 : Sample(1),
      shortCode2   : Sample(4),
      tableSelect3 : Sample(1),
      shortCode3   : Sample(4) ]

EncodeOrderCancelMessage(message) ==
    message.orderRef
        \o message.userTag
        \o message.flags
        \o message.tableSelect1
        \o message.shortCode1
        \o message.tableSelect2
        \o message.shortCode2
        \o message.tableSelect3
        \o message.shortCode3

DecodeOrderCancelMessage(bytes) ==
    LET orderRef == ReadBytes(bytes, 8) IN IF ~orderRef.ok THEN Fail ELSE
    LET userTag == ReadBytes(orderRef.rest, 8) IN IF ~userTag.ok THEN Fail ELSE
    LET flags == ReadBytes(userTag.rest, 1) IN IF ~flags.ok THEN Fail ELSE
    LET tableSelect1 == ReadBytes(flags.rest, 1) IN IF ~tableSelect1.ok THEN Fail ELSE
    LET shortCode1 == ReadBytes(tableSelect1.rest, 4) IN IF ~shortCode1.ok THEN Fail ELSE
    LET tableSelect2 == ReadBytes(shortCode1.rest, 1) IN IF ~tableSelect2.ok THEN Fail ELSE
    LET shortCode2 == ReadBytes(tableSelect2.rest, 4) IN IF ~shortCode2.ok THEN Fail ELSE
    LET tableSelect3 == ReadBytes(shortCode2.rest, 1) IN IF ~tableSelect3.ok THEN Fail ELSE
    LET shortCode3 == ReadBytes(tableSelect3.rest, 4) IN IF ~shortCode3.ok THEN Fail ELSE
    Ok([ orderRef     |-> orderRef.value,
         userTag      |-> userTag.value,
         flags        |-> flags.value,
         tableSelect1 |-> tableSelect1.value,
         shortCode1   |-> shortCode1.value,
         tableSelect2 |-> tableSelect2.value,
         shortCode2   |-> shortCode2.value,
         tableSelect3 |-> tableSelect3.value,
         shortCode3   |-> shortCode3.value ], shortCode3.rest)

ZeroOrderCancelMessage ==
    [ orderRef     |-> [i \in 1 .. 8 |-> 0],
      userTag      |-> [i \in 1 .. 8 |-> 0],
      flags        |-> [i \in 1 .. 1 |-> 0],
      tableSelect1 |-> [i \in 1 .. 1 |-> 0],
      shortCode1   |-> [i \in 1 .. 4 |-> 0],
      tableSelect2 |-> [i \in 1 .. 1 |-> 0],
      shortCode2   |-> [i \in 1 .. 4 |-> 0],
      tableSelect3 |-> [i \in 1 .. 1 |-> 0],
      shortCode3   |-> [i \in 1 .. 4 |-> 0] ]

(* Order Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelMessage ==
    { ZeroOrderCancelMessage }
        \cup { [ZeroOrderCancelMessage EXCEPT !.orderRef = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.userTag = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.flags = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.tableSelect1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.shortCode1 = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.tableSelect2 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.shortCode2 = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.tableSelect3 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelMessage EXCEPT !.shortCode3 = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Modify Message: 45 bytes                                          *)
(***************************************************************************)

OrderModifyMessage ==
    [ orderRef      : Sample(8),
      price         : Sample(8),
      quantity      : Sample(4),
      userTag       : Sample(8),
      flags         : Sample(1),
      tableSelect1  : Sample(1),
      shortCode1    : Sample(4),
      tableSelect2  : Sample(1),
      shortCode2    : Sample(4),
      tableSelect3  : Sample(1),
      shortCode3    : Sample(4),
      orderCapacity : Sample(1) ]

EncodeOrderModifyMessage(message) ==
    message.orderRef
        \o message.price
        \o message.quantity
        \o message.userTag
        \o message.flags
        \o message.tableSelect1
        \o message.shortCode1
        \o message.tableSelect2
        \o message.shortCode2
        \o message.tableSelect3
        \o message.shortCode3
        \o message.orderCapacity

DecodeOrderModifyMessage(bytes) ==
    LET orderRef == ReadBytes(bytes, 8) IN IF ~orderRef.ok THEN Fail ELSE
    LET price == ReadBytes(orderRef.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET userTag == ReadBytes(quantity.rest, 8) IN IF ~userTag.ok THEN Fail ELSE
    LET flags == ReadBytes(userTag.rest, 1) IN IF ~flags.ok THEN Fail ELSE
    LET tableSelect1 == ReadBytes(flags.rest, 1) IN IF ~tableSelect1.ok THEN Fail ELSE
    LET shortCode1 == ReadBytes(tableSelect1.rest, 4) IN IF ~shortCode1.ok THEN Fail ELSE
    LET tableSelect2 == ReadBytes(shortCode1.rest, 1) IN IF ~tableSelect2.ok THEN Fail ELSE
    LET shortCode2 == ReadBytes(tableSelect2.rest, 4) IN IF ~shortCode2.ok THEN Fail ELSE
    LET tableSelect3 == ReadBytes(shortCode2.rest, 1) IN IF ~tableSelect3.ok THEN Fail ELSE
    LET shortCode3 == ReadBytes(tableSelect3.rest, 4) IN IF ~shortCode3.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(shortCode3.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    Ok([ orderRef      |-> orderRef.value,
         price         |-> price.value,
         quantity      |-> quantity.value,
         userTag       |-> userTag.value,
         flags         |-> flags.value,
         tableSelect1  |-> tableSelect1.value,
         shortCode1    |-> shortCode1.value,
         tableSelect2  |-> tableSelect2.value,
         shortCode2    |-> shortCode2.value,
         tableSelect3  |-> tableSelect3.value,
         shortCode3    |-> shortCode3.value,
         orderCapacity |-> orderCapacity.value ], orderCapacity.rest)

ZeroOrderModifyMessage ==
    [ orderRef      |-> [i \in 1 .. 8 |-> 0],
      price         |-> [i \in 1 .. 8 |-> 0],
      quantity      |-> [i \in 1 .. 4 |-> 0],
      userTag       |-> [i \in 1 .. 8 |-> 0],
      flags         |-> [i \in 1 .. 1 |-> 0],
      tableSelect1  |-> [i \in 1 .. 1 |-> 0],
      shortCode1    |-> [i \in 1 .. 4 |-> 0],
      tableSelect2  |-> [i \in 1 .. 1 |-> 0],
      shortCode2    |-> [i \in 1 .. 4 |-> 0],
      tableSelect3  |-> [i \in 1 .. 1 |-> 0],
      shortCode3    |-> [i \in 1 .. 4 |-> 0],
      orderCapacity |-> [i \in 1 .. 1 |-> 0] ]

(* Order Modify Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyMessage ==
    { ZeroOrderModifyMessage }
        \cup { [ZeroOrderModifyMessage EXCEPT !.orderRef = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.userTag = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.flags = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.tableSelect1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.shortCode1 = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.tableSelect2 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.shortCode2 = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.tableSelect3 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.shortCode3 = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Modify Extended Message: 61 bytes                                 *)
(***************************************************************************)

OrderModifyExtendedMessage ==
    [ orderRef        : Sample(8),
      price           : Sample(8),
      quantity        : Sample(4),
      userTag         : Sample(8),
      flags           : Sample(1),
      tableSelect1    : Sample(1),
      shortCode1      : Sample(4),
      tableSelect2    : Sample(1),
      shortCode2      : Sample(4),
      tableSelect3    : Sample(1),
      shortCode3      : Sample(4),
      orderCapacity   : Sample(1),
      displayQuantity : Sample(4),
      minQty          : Sample(4),
      expireTime      : Sample(8) ]

EncodeOrderModifyExtendedMessage(message) ==
    message.orderRef
        \o message.price
        \o message.quantity
        \o message.userTag
        \o message.flags
        \o message.tableSelect1
        \o message.shortCode1
        \o message.tableSelect2
        \o message.shortCode2
        \o message.tableSelect3
        \o message.shortCode3
        \o message.orderCapacity
        \o message.displayQuantity
        \o message.minQty
        \o message.expireTime

DecodeOrderModifyExtendedMessage(bytes) ==
    LET orderRef == ReadBytes(bytes, 8) IN IF ~orderRef.ok THEN Fail ELSE
    LET price == ReadBytes(orderRef.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET quantity == ReadBytes(price.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET userTag == ReadBytes(quantity.rest, 8) IN IF ~userTag.ok THEN Fail ELSE
    LET flags == ReadBytes(userTag.rest, 1) IN IF ~flags.ok THEN Fail ELSE
    LET tableSelect1 == ReadBytes(flags.rest, 1) IN IF ~tableSelect1.ok THEN Fail ELSE
    LET shortCode1 == ReadBytes(tableSelect1.rest, 4) IN IF ~shortCode1.ok THEN Fail ELSE
    LET tableSelect2 == ReadBytes(shortCode1.rest, 1) IN IF ~tableSelect2.ok THEN Fail ELSE
    LET shortCode2 == ReadBytes(tableSelect2.rest, 4) IN IF ~shortCode2.ok THEN Fail ELSE
    LET tableSelect3 == ReadBytes(shortCode2.rest, 1) IN IF ~tableSelect3.ok THEN Fail ELSE
    LET shortCode3 == ReadBytes(tableSelect3.rest, 4) IN IF ~shortCode3.ok THEN Fail ELSE
    LET orderCapacity == ReadBytes(shortCode3.rest, 1) IN IF ~orderCapacity.ok THEN Fail ELSE
    LET displayQuantity == ReadBytes(orderCapacity.rest, 4) IN IF ~displayQuantity.ok THEN Fail ELSE
    LET minQty == ReadBytes(displayQuantity.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET expireTime == ReadBytes(minQty.rest, 8) IN IF ~expireTime.ok THEN Fail ELSE
    Ok([ orderRef        |-> orderRef.value,
         price           |-> price.value,
         quantity        |-> quantity.value,
         userTag         |-> userTag.value,
         flags           |-> flags.value,
         tableSelect1    |-> tableSelect1.value,
         shortCode1      |-> shortCode1.value,
         tableSelect2    |-> tableSelect2.value,
         shortCode2      |-> shortCode2.value,
         tableSelect3    |-> tableSelect3.value,
         shortCode3      |-> shortCode3.value,
         orderCapacity   |-> orderCapacity.value,
         displayQuantity |-> displayQuantity.value,
         minQty          |-> minQty.value,
         expireTime      |-> expireTime.value ], expireTime.rest)

ZeroOrderModifyExtendedMessage ==
    [ orderRef        |-> [i \in 1 .. 8 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0],
      quantity        |-> [i \in 1 .. 4 |-> 0],
      userTag         |-> [i \in 1 .. 8 |-> 0],
      flags           |-> [i \in 1 .. 1 |-> 0],
      tableSelect1    |-> [i \in 1 .. 1 |-> 0],
      shortCode1      |-> [i \in 1 .. 4 |-> 0],
      tableSelect2    |-> [i \in 1 .. 1 |-> 0],
      shortCode2      |-> [i \in 1 .. 4 |-> 0],
      tableSelect3    |-> [i \in 1 .. 1 |-> 0],
      shortCode3      |-> [i \in 1 .. 4 |-> 0],
      orderCapacity   |-> [i \in 1 .. 1 |-> 0],
      displayQuantity |-> [i \in 1 .. 4 |-> 0],
      minQty          |-> [i \in 1 .. 4 |-> 0],
      expireTime      |-> [i \in 1 .. 8 |-> 0] ]

(* Order Modify Extended Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyExtendedMessage ==
    { ZeroOrderModifyExtendedMessage }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.orderRef = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.userTag = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.flags = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.tableSelect1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.shortCode1 = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.tableSelect2 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.shortCode2 = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.tableSelect3 = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.shortCode3 = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.orderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.displayQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderModifyExtendedMessage EXCEPT !.expireTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Add Response Message: 38 bytes                                    *)
(***************************************************************************)

OrderAddResponseMessage ==
    [ orderRef               : Sample(8),
      marketDataId           : Sample(8),
      orderAddResponseStatus : Sample(1),
      tradedQuantity         : Sample(4),
      timestamp              : Sample(8),
      userTag                : Sample(8),
      orderAddResponseFlags  : Sample(1) ]

EncodeOrderAddResponseMessage(message) ==
    message.orderRef
        \o message.marketDataId
        \o message.orderAddResponseStatus
        \o message.tradedQuantity
        \o message.timestamp
        \o message.userTag
        \o message.orderAddResponseFlags

DecodeOrderAddResponseMessage(bytes) ==
    LET orderRef == ReadBytes(bytes, 8) IN IF ~orderRef.ok THEN Fail ELSE
    LET marketDataId == ReadBytes(orderRef.rest, 8) IN IF ~marketDataId.ok THEN Fail ELSE
    LET orderAddResponseStatus == ReadBytes(marketDataId.rest, 1) IN IF ~orderAddResponseStatus.ok THEN Fail ELSE
    LET tradedQuantity == ReadBytes(orderAddResponseStatus.rest, 4) IN IF ~tradedQuantity.ok THEN Fail ELSE
    LET timestamp == ReadBytes(tradedQuantity.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userTag == ReadBytes(timestamp.rest, 8) IN IF ~userTag.ok THEN Fail ELSE
    LET orderAddResponseFlags == ReadBytes(userTag.rest, 1) IN IF ~orderAddResponseFlags.ok THEN Fail ELSE
    Ok([ orderRef               |-> orderRef.value,
         marketDataId           |-> marketDataId.value,
         orderAddResponseStatus |-> orderAddResponseStatus.value,
         tradedQuantity         |-> tradedQuantity.value,
         timestamp              |-> timestamp.value,
         userTag                |-> userTag.value,
         orderAddResponseFlags  |-> orderAddResponseFlags.value ], orderAddResponseFlags.rest)

ZeroOrderAddResponseMessage ==
    [ orderRef               |-> [i \in 1 .. 8 |-> 0],
      marketDataId           |-> [i \in 1 .. 8 |-> 0],
      orderAddResponseStatus |-> [i \in 1 .. 1 |-> 0],
      tradedQuantity         |-> [i \in 1 .. 4 |-> 0],
      timestamp              |-> [i \in 1 .. 8 |-> 0],
      userTag                |-> [i \in 1 .. 8 |-> 0],
      orderAddResponseFlags  |-> [i \in 1 .. 1 |-> 0] ]

(* Order Add Response Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderAddResponseMessage ==
    { ZeroOrderAddResponseMessage }
        \cup { [ZeroOrderAddResponseMessage EXCEPT !.orderRef = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddResponseMessage EXCEPT !.marketDataId = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddResponseMessage EXCEPT !.orderAddResponseStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderAddResponseMessage EXCEPT !.tradedQuantity = one] : one \in Sample(4) }
        \cup { [ZeroOrderAddResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddResponseMessage EXCEPT !.userTag = one] : one \in Sample(8) }
        \cup { [ZeroOrderAddResponseMessage EXCEPT !.orderAddResponseFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Cancel Response Message: 33 bytes                                 *)
(***************************************************************************)

OrderCancelResponseMessage ==
    [ orderRef                  : Sample(8),
      requestRef                : Sample(8),
      orderCancelResponseStatus : Sample(1),
      timestamp                 : Sample(8),
      userTag                   : Sample(8) ]

EncodeOrderCancelResponseMessage(message) ==
    message.orderRef
        \o message.requestRef
        \o message.orderCancelResponseStatus
        \o message.timestamp
        \o message.userTag

DecodeOrderCancelResponseMessage(bytes) ==
    LET orderRef == ReadBytes(bytes, 8) IN IF ~orderRef.ok THEN Fail ELSE
    LET requestRef == ReadBytes(orderRef.rest, 8) IN IF ~requestRef.ok THEN Fail ELSE
    LET orderCancelResponseStatus == ReadBytes(requestRef.rest, 1) IN IF ~orderCancelResponseStatus.ok THEN Fail ELSE
    LET timestamp == ReadBytes(orderCancelResponseStatus.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userTag == ReadBytes(timestamp.rest, 8) IN IF ~userTag.ok THEN Fail ELSE
    Ok([ orderRef                  |-> orderRef.value,
         requestRef                |-> requestRef.value,
         orderCancelResponseStatus |-> orderCancelResponseStatus.value,
         timestamp                 |-> timestamp.value,
         userTag                   |-> userTag.value ], userTag.rest)

ZeroOrderCancelResponseMessage ==
    [ orderRef                  |-> [i \in 1 .. 8 |-> 0],
      requestRef                |-> [i \in 1 .. 8 |-> 0],
      orderCancelResponseStatus |-> [i \in 1 .. 1 |-> 0],
      timestamp                 |-> [i \in 1 .. 8 |-> 0],
      userTag                   |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancel Response Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelResponseMessage ==
    { ZeroOrderCancelResponseMessage }
        \cup { [ZeroOrderCancelResponseMessage EXCEPT !.orderRef = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelResponseMessage EXCEPT !.requestRef = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelResponseMessage EXCEPT !.orderCancelResponseStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelResponseMessage EXCEPT !.userTag = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Modify Response Message: 34 bytes                                 *)
(***************************************************************************)

OrderModifyResponseMessage ==
    [ orderRef                  : Sample(8),
      requestRef                : Sample(8),
      orderModifyResponseStatus : Sample(1),
      timestamp                 : Sample(8),
      userTag                   : Sample(8),
      orderModifyResponseFlags  : Sample(1) ]

EncodeOrderModifyResponseMessage(message) ==
    message.orderRef
        \o message.requestRef
        \o message.orderModifyResponseStatus
        \o message.timestamp
        \o message.userTag
        \o message.orderModifyResponseFlags

DecodeOrderModifyResponseMessage(bytes) ==
    LET orderRef == ReadBytes(bytes, 8) IN IF ~orderRef.ok THEN Fail ELSE
    LET requestRef == ReadBytes(orderRef.rest, 8) IN IF ~requestRef.ok THEN Fail ELSE
    LET orderModifyResponseStatus == ReadBytes(requestRef.rest, 1) IN IF ~orderModifyResponseStatus.ok THEN Fail ELSE
    LET timestamp == ReadBytes(orderModifyResponseStatus.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userTag == ReadBytes(timestamp.rest, 8) IN IF ~userTag.ok THEN Fail ELSE
    LET orderModifyResponseFlags == ReadBytes(userTag.rest, 1) IN IF ~orderModifyResponseFlags.ok THEN Fail ELSE
    Ok([ orderRef                  |-> orderRef.value,
         requestRef                |-> requestRef.value,
         orderModifyResponseStatus |-> orderModifyResponseStatus.value,
         timestamp                 |-> timestamp.value,
         userTag                   |-> userTag.value,
         orderModifyResponseFlags  |-> orderModifyResponseFlags.value ], orderModifyResponseFlags.rest)

ZeroOrderModifyResponseMessage ==
    [ orderRef                  |-> [i \in 1 .. 8 |-> 0],
      requestRef                |-> [i \in 1 .. 8 |-> 0],
      orderModifyResponseStatus |-> [i \in 1 .. 1 |-> 0],
      timestamp                 |-> [i \in 1 .. 8 |-> 0],
      userTag                   |-> [i \in 1 .. 8 |-> 0],
      orderModifyResponseFlags  |-> [i \in 1 .. 1 |-> 0] ]

(* Order Modify Response Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderModifyResponseMessage ==
    { ZeroOrderModifyResponseMessage }
        \cup { [ZeroOrderModifyResponseMessage EXCEPT !.orderRef = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyResponseMessage EXCEPT !.requestRef = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyResponseMessage EXCEPT !.orderModifyResponseStatus = one] : one \in Sample(1) }
        \cup { [ZeroOrderModifyResponseMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyResponseMessage EXCEPT !.userTag = one] : one \in Sample(8) }
        \cup { [ZeroOrderModifyResponseMessage EXCEPT !.orderModifyResponseFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Request Message: 37 bytes                                         *)
(***************************************************************************)

QuoteRequestMessage ==
    [ securityIdLong   : Sample(4),
      quantity         : Sample(4),
      side             : Sample(1),
      userTag          : Sample(8),
      marketMakerCode1 : Sample(4),
      marketMakerCode2 : Sample(4),
      marketMakerCode3 : Sample(4),
      marketMakerCode4 : Sample(4),
      marketMakerCode5 : Sample(4) ]

EncodeQuoteRequestMessage(message) ==
    message.securityIdLong
        \o message.quantity
        \o message.side
        \o message.userTag
        \o message.marketMakerCode1
        \o message.marketMakerCode2
        \o message.marketMakerCode3
        \o message.marketMakerCode4
        \o message.marketMakerCode5

DecodeQuoteRequestMessage(bytes) ==
    LET securityIdLong == ReadBytes(bytes, 4) IN IF ~securityIdLong.ok THEN Fail ELSE
    LET quantity == ReadBytes(securityIdLong.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET side == ReadBytes(quantity.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET userTag == ReadBytes(side.rest, 8) IN IF ~userTag.ok THEN Fail ELSE
    LET marketMakerCode1 == ReadBytes(userTag.rest, 4) IN IF ~marketMakerCode1.ok THEN Fail ELSE
    LET marketMakerCode2 == ReadBytes(marketMakerCode1.rest, 4) IN IF ~marketMakerCode2.ok THEN Fail ELSE
    LET marketMakerCode3 == ReadBytes(marketMakerCode2.rest, 4) IN IF ~marketMakerCode3.ok THEN Fail ELSE
    LET marketMakerCode4 == ReadBytes(marketMakerCode3.rest, 4) IN IF ~marketMakerCode4.ok THEN Fail ELSE
    LET marketMakerCode5 == ReadBytes(marketMakerCode4.rest, 4) IN IF ~marketMakerCode5.ok THEN Fail ELSE
    Ok([ securityIdLong   |-> securityIdLong.value,
         quantity         |-> quantity.value,
         side             |-> side.value,
         userTag          |-> userTag.value,
         marketMakerCode1 |-> marketMakerCode1.value,
         marketMakerCode2 |-> marketMakerCode2.value,
         marketMakerCode3 |-> marketMakerCode3.value,
         marketMakerCode4 |-> marketMakerCode4.value,
         marketMakerCode5 |-> marketMakerCode5.value ], marketMakerCode5.rest)

ZeroQuoteRequestMessage ==
    [ securityIdLong   |-> [i \in 1 .. 4 |-> 0],
      quantity         |-> [i \in 1 .. 4 |-> 0],
      side             |-> [i \in 1 .. 1 |-> 0],
      userTag          |-> [i \in 1 .. 8 |-> 0],
      marketMakerCode1 |-> [i \in 1 .. 4 |-> 0],
      marketMakerCode2 |-> [i \in 1 .. 4 |-> 0],
      marketMakerCode3 |-> [i \in 1 .. 4 |-> 0],
      marketMakerCode4 |-> [i \in 1 .. 4 |-> 0],
      marketMakerCode5 |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Request Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestMessage ==
    { ZeroQuoteRequestMessage }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.securityIdLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.userTag = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.marketMakerCode1 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.marketMakerCode2 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.marketMakerCode3 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.marketMakerCode4 = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestMessage EXCEPT !.marketMakerCode5 = one] : one \in Sample(4) }

(***************************************************************************)
(* Quote Request Notification Message: 35 bytes                            *)
(***************************************************************************)

QuoteRequestNotificationMessage ==
    [ rfqSessionId       : Sample(8),
      securityIdLong     : Sample(4),
      quantity           : Sample(4),
      side               : Sample(1),
      quoteRequestStatus : Sample(1),
      statusDetails      : Sample(1),
      msgRef             : Sample(8),
      userTag            : Sample(8) ]

EncodeQuoteRequestNotificationMessage(message) ==
    message.rfqSessionId
        \o message.securityIdLong
        \o message.quantity
        \o message.side
        \o message.quoteRequestStatus
        \o message.statusDetails
        \o message.msgRef
        \o message.userTag

DecodeQuoteRequestNotificationMessage(bytes) ==
    LET rfqSessionId == ReadBytes(bytes, 8) IN IF ~rfqSessionId.ok THEN Fail ELSE
    LET securityIdLong == ReadBytes(rfqSessionId.rest, 4) IN IF ~securityIdLong.ok THEN Fail ELSE
    LET quantity == ReadBytes(securityIdLong.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET side == ReadBytes(quantity.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quoteRequestStatus == ReadBytes(side.rest, 1) IN IF ~quoteRequestStatus.ok THEN Fail ELSE
    LET statusDetails == ReadBytes(quoteRequestStatus.rest, 1) IN IF ~statusDetails.ok THEN Fail ELSE
    LET msgRef == ReadBytes(statusDetails.rest, 8) IN IF ~msgRef.ok THEN Fail ELSE
    LET userTag == ReadBytes(msgRef.rest, 8) IN IF ~userTag.ok THEN Fail ELSE
    Ok([ rfqSessionId       |-> rfqSessionId.value,
         securityIdLong     |-> securityIdLong.value,
         quantity           |-> quantity.value,
         side               |-> side.value,
         quoteRequestStatus |-> quoteRequestStatus.value,
         statusDetails      |-> statusDetails.value,
         msgRef             |-> msgRef.value,
         userTag            |-> userTag.value ], userTag.rest)

ZeroQuoteRequestNotificationMessage ==
    [ rfqSessionId       |-> [i \in 1 .. 8 |-> 0],
      securityIdLong     |-> [i \in 1 .. 4 |-> 0],
      quantity           |-> [i \in 1 .. 4 |-> 0],
      side               |-> [i \in 1 .. 1 |-> 0],
      quoteRequestStatus |-> [i \in 1 .. 1 |-> 0],
      statusDetails      |-> [i \in 1 .. 1 |-> 0],
      msgRef             |-> [i \in 1 .. 8 |-> 0],
      userTag            |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Request Notification Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteRequestNotificationMessage ==
    { ZeroQuoteRequestNotificationMessage }
        \cup { [ZeroQuoteRequestNotificationMessage EXCEPT !.rfqSessionId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestNotificationMessage EXCEPT !.securityIdLong = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestNotificationMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroQuoteRequestNotificationMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestNotificationMessage EXCEPT !.quoteRequestStatus = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestNotificationMessage EXCEPT !.statusDetails = one] : one \in Sample(1) }
        \cup { [ZeroQuoteRequestNotificationMessage EXCEPT !.msgRef = one] : one \in Sample(8) }
        \cup { [ZeroQuoteRequestNotificationMessage EXCEPT !.userTag = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Add Message: 31 bytes                                             *)
(***************************************************************************)

QuoteAddMessage ==
    [ aqxOrderId      : Sample(8),
      securityIdShort : Sample(2),
      side            : Sample(1),
      quantity        : Sample(4),
      price           : Sample(8),
      rfqSessionId    : Sample(8) ]

EncodeQuoteAddMessage(message) ==
    message.aqxOrderId
        \o message.securityIdShort
        \o message.side
        \o message.quantity
        \o message.price
        \o message.rfqSessionId

DecodeQuoteAddMessage(bytes) ==
    LET aqxOrderId == ReadBytes(bytes, 8) IN IF ~aqxOrderId.ok THEN Fail ELSE
    LET securityIdShort == ReadBytes(aqxOrderId.rest, 2) IN IF ~securityIdShort.ok THEN Fail ELSE
    LET side == ReadBytes(securityIdShort.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET quantity == ReadBytes(side.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET rfqSessionId == ReadBytes(price.rest, 8) IN IF ~rfqSessionId.ok THEN Fail ELSE
    Ok([ aqxOrderId      |-> aqxOrderId.value,
         securityIdShort |-> securityIdShort.value,
         side            |-> side.value,
         quantity        |-> quantity.value,
         price           |-> price.value,
         rfqSessionId    |-> rfqSessionId.value ], rfqSessionId.rest)

ZeroQuoteAddMessage ==
    [ aqxOrderId      |-> [i \in 1 .. 8 |-> 0],
      securityIdShort |-> [i \in 1 .. 2 |-> 0],
      side            |-> [i \in 1 .. 1 |-> 0],
      quantity        |-> [i \in 1 .. 4 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0],
      rfqSessionId    |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Add Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteAddMessage ==
    { ZeroQuoteAddMessage }
        \cup { [ZeroQuoteAddMessage EXCEPT !.aqxOrderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAddMessage EXCEPT !.securityIdShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteAddMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroQuoteAddMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroQuoteAddMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroQuoteAddMessage EXCEPT !.rfqSessionId = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Modify Message: 22 bytes                                          *)
(***************************************************************************)

QuoteModifyMessage ==
    [ aqxOrderId      : Sample(8),
      securityIdShort : Sample(2),
      quantity        : Sample(4),
      price           : Sample(8) ]

EncodeQuoteModifyMessage(message) ==
    message.aqxOrderId
        \o message.securityIdShort
        \o message.quantity
        \o message.price

DecodeQuoteModifyMessage(bytes) ==
    LET aqxOrderId == ReadBytes(bytes, 8) IN IF ~aqxOrderId.ok THEN Fail ELSE
    LET securityIdShort == ReadBytes(aqxOrderId.rest, 2) IN IF ~securityIdShort.ok THEN Fail ELSE
    LET quantity == ReadBytes(securityIdShort.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    Ok([ aqxOrderId      |-> aqxOrderId.value,
         securityIdShort |-> securityIdShort.value,
         quantity        |-> quantity.value,
         price           |-> price.value ], price.rest)

ZeroQuoteModifyMessage ==
    [ aqxOrderId      |-> [i \in 1 .. 8 |-> 0],
      securityIdShort |-> [i \in 1 .. 2 |-> 0],
      quantity        |-> [i \in 1 .. 4 |-> 0],
      price           |-> [i \in 1 .. 8 |-> 0] ]

(* Quote Modify Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteModifyMessage ==
    { ZeroQuoteModifyMessage }
        \cup { [ZeroQuoteModifyMessage EXCEPT !.aqxOrderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteModifyMessage EXCEPT !.securityIdShort = one] : one \in Sample(2) }
        \cup { [ZeroQuoteModifyMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroQuoteModifyMessage EXCEPT !.price = one] : one \in Sample(8) }

(***************************************************************************)
(* Quote Cancel Message: 10 bytes                                          *)
(***************************************************************************)

QuoteCancelMessage ==
    [ aqxOrderId      : Sample(8),
      securityIdShort : Sample(2) ]

EncodeQuoteCancelMessage(message) ==
    message.aqxOrderId
        \o message.securityIdShort

DecodeQuoteCancelMessage(bytes) ==
    LET aqxOrderId == ReadBytes(bytes, 8) IN IF ~aqxOrderId.ok THEN Fail ELSE
    LET securityIdShort == ReadBytes(aqxOrderId.rest, 2) IN IF ~securityIdShort.ok THEN Fail ELSE
    Ok([ aqxOrderId      |-> aqxOrderId.value,
         securityIdShort |-> securityIdShort.value ], securityIdShort.rest)

ZeroQuoteCancelMessage ==
    [ aqxOrderId      |-> [i \in 1 .. 8 |-> 0],
      securityIdShort |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Cancel Message at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelMessage ==
    { ZeroQuoteCancelMessage }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.aqxOrderId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancelMessage EXCEPT !.securityIdShort = one] : one \in Sample(2) }

(***************************************************************************)
(* Trade Message: 52 bytes                                                 *)
(***************************************************************************)

TradeMessage ==
    [ orderRef       : Sample(8),
      quantity       : Sample(4),
      price          : Sample(8),
      side           : Sample(1),
      tradeRef       : Sample(8),
      ccpCode        : Sample(1),
      liqIndicator   : Sample(1),
      securityIdLong : Sample(4),
      timestamp      : Sample(8),
      userTag        : Sample(8),
      tradeFlags     : Sample(1) ]

EncodeTradeMessage(message) ==
    message.orderRef
        \o message.quantity
        \o message.price
        \o message.side
        \o message.tradeRef
        \o message.ccpCode
        \o message.liqIndicator
        \o message.securityIdLong
        \o message.timestamp
        \o message.userTag
        \o message.tradeFlags

DecodeTradeMessage(bytes) ==
    LET orderRef == ReadBytes(bytes, 8) IN IF ~orderRef.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderRef.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET tradeRef == ReadBytes(side.rest, 8) IN IF ~tradeRef.ok THEN Fail ELSE
    LET ccpCode == ReadBytes(tradeRef.rest, 1) IN IF ~ccpCode.ok THEN Fail ELSE
    LET liqIndicator == ReadBytes(ccpCode.rest, 1) IN IF ~liqIndicator.ok THEN Fail ELSE
    LET securityIdLong == ReadBytes(liqIndicator.rest, 4) IN IF ~securityIdLong.ok THEN Fail ELSE
    LET timestamp == ReadBytes(securityIdLong.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET userTag == ReadBytes(timestamp.rest, 8) IN IF ~userTag.ok THEN Fail ELSE
    LET tradeFlags == ReadBytes(userTag.rest, 1) IN IF ~tradeFlags.ok THEN Fail ELSE
    Ok([ orderRef       |-> orderRef.value,
         quantity       |-> quantity.value,
         price          |-> price.value,
         side           |-> side.value,
         tradeRef       |-> tradeRef.value,
         ccpCode        |-> ccpCode.value,
         liqIndicator   |-> liqIndicator.value,
         securityIdLong |-> securityIdLong.value,
         timestamp      |-> timestamp.value,
         userTag        |-> userTag.value,
         tradeFlags     |-> tradeFlags.value ], tradeFlags.rest)

ZeroTradeMessage ==
    [ orderRef       |-> [i \in 1 .. 8 |-> 0],
      quantity       |-> [i \in 1 .. 4 |-> 0],
      price          |-> [i \in 1 .. 8 |-> 0],
      side           |-> [i \in 1 .. 1 |-> 0],
      tradeRef       |-> [i \in 1 .. 8 |-> 0],
      ccpCode        |-> [i \in 1 .. 1 |-> 0],
      liqIndicator   |-> [i \in 1 .. 1 |-> 0],
      securityIdLong |-> [i \in 1 .. 4 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      userTag        |-> [i \in 1 .. 8 |-> 0],
      tradeFlags     |-> [i \in 1 .. 1 |-> 0] ]

(* Trade Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeMessage ==
    { ZeroTradeMessage }
        \cup { [ZeroTradeMessage EXCEPT !.orderRef = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeRef = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.ccpCode = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.liqIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeMessage EXCEPT !.securityIdLong = one] : one \in Sample(4) }
        \cup { [ZeroTradeMessage EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.userTag = one] : one \in Sample(8) }
        \cup { [ZeroTradeMessage EXCEPT !.tradeFlags = one] : one \in Sample(1) }

(***************************************************************************)
(* Trade Bust Message: 37 bytes                                            *)
(***************************************************************************)

TradeBustMessage ==
    [ orderRef  : Sample(8),
      quantity  : Sample(4),
      price     : Sample(8),
      side      : Sample(1),
      tradeRef  : Sample(8),
      timestamp : Sample(8) ]

EncodeTradeBustMessage(message) ==
    message.orderRef
        \o message.quantity
        \o message.price
        \o message.side
        \o message.tradeRef
        \o message.timestamp

DecodeTradeBustMessage(bytes) ==
    LET orderRef == ReadBytes(bytes, 8) IN IF ~orderRef.ok THEN Fail ELSE
    LET quantity == ReadBytes(orderRef.rest, 4) IN IF ~quantity.ok THEN Fail ELSE
    LET price == ReadBytes(quantity.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET side == ReadBytes(price.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET tradeRef == ReadBytes(side.rest, 8) IN IF ~tradeRef.ok THEN Fail ELSE
    LET timestamp == ReadBytes(tradeRef.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ orderRef  |-> orderRef.value,
         quantity  |-> quantity.value,
         price     |-> price.value,
         side      |-> side.value,
         tradeRef  |-> tradeRef.value,
         timestamp |-> timestamp.value ], timestamp.rest)

ZeroTradeBustMessage ==
    [ orderRef  |-> [i \in 1 .. 8 |-> 0],
      quantity  |-> [i \in 1 .. 4 |-> 0],
      price     |-> [i \in 1 .. 8 |-> 0],
      side      |-> [i \in 1 .. 1 |-> 0],
      tradeRef  |-> [i \in 1 .. 8 |-> 0],
      timestamp |-> [i \in 1 .. 8 |-> 0] ]

(* Trade Bust Message at zero, then each field in turn at the values it is checked at *)
CheckedTradeBustMessage ==
    { ZeroTradeBustMessage }
        \cup { [ZeroTradeBustMessage EXCEPT !.orderRef = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.quantity = one] : one \in Sample(4) }
        \cup { [ZeroTradeBustMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroTradeBustMessage EXCEPT !.tradeRef = one] : one \in Sample(8) }
        \cup { [ZeroTradeBustMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Payload, selected by Msg Type                                           *)
(***************************************************************************)

LoginMessageCode == 1  \* 0x01
LoginResponseMessageCode == 2  \* 0x02
HeartbeatMessageCode == 0  \* 0x00
LogoutRequestMessageCode == 3  \* 0x03
LogoutMessageCode == 4  \* 0x04
OrderAddMessageCode == 5  \* 0x05
OrderAddExtendedMessageCode == 21  \* 0x15
OrderCancelMessageCode == 7  \* 0x07
OrderModifyMessageCode == 9  \* 0x09
OrderModifyExtendedMessageCode == 22  \* 0x16
OrderAddResponseMessageCode == 6  \* 0x06
OrderCancelResponseMessageCode == 8  \* 0x08
OrderModifyResponseMessageCode == 10  \* 0x0a
QuoteRequestMessageCode == 30  \* 0x1e
QuoteRequestNotificationMessageCode == 31  \* 0x1f
QuoteAddMessageCode == 13  \* 0x0d
QuoteModifyMessageCode == 14  \* 0x0e
QuoteCancelMessageCode == 15  \* 0x0f
TradeMessageCode == 11  \* 0x0b
TradeBustMessageCode == 12  \* 0x0c

Payload ==
    [ tag : {LoginMessageCode}, body : LoginMessage ]
        \cup [ tag : {LoginResponseMessageCode}, body : LoginResponseMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutRequestMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {OrderAddMessageCode}, body : OrderAddMessage ]
        \cup [ tag : {OrderAddExtendedMessageCode}, body : OrderAddExtendedMessage ]
        \cup [ tag : {OrderCancelMessageCode}, body : OrderCancelMessage ]
        \cup [ tag : {OrderModifyMessageCode}, body : OrderModifyMessage ]
        \cup [ tag : {OrderModifyExtendedMessageCode}, body : OrderModifyExtendedMessage ]
        \cup [ tag : {OrderAddResponseMessageCode}, body : OrderAddResponseMessage ]
        \cup [ tag : {OrderCancelResponseMessageCode}, body : OrderCancelResponseMessage ]
        \cup [ tag : {OrderModifyResponseMessageCode}, body : OrderModifyResponseMessage ]
        \cup [ tag : {QuoteRequestMessageCode}, body : QuoteRequestMessage ]
        \cup [ tag : {QuoteRequestNotificationMessageCode}, body : QuoteRequestNotificationMessage ]
        \cup [ tag : {QuoteAddMessageCode}, body : QuoteAddMessage ]
        \cup [ tag : {QuoteModifyMessageCode}, body : QuoteModifyMessage ]
        \cup [ tag : {QuoteCancelMessageCode}, body : QuoteCancelMessage ]
        \cup [ tag : {TradeMessageCode}, body : TradeMessage ]
        \cup [ tag : {TradeBustMessageCode}, body : TradeBustMessage ]

EncodePayload(message) ==
    CASE message.tag = LoginMessageCode -> EncodeLoginMessage(message.body)
      [] message.tag = LoginResponseMessageCode -> EncodeLoginResponseMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = LogoutRequestMessageCode -> << >>
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = OrderAddMessageCode -> EncodeOrderAddMessage(message.body)
      [] message.tag = OrderAddExtendedMessageCode -> EncodeOrderAddExtendedMessage(message.body)
      [] message.tag = OrderCancelMessageCode -> EncodeOrderCancelMessage(message.body)
      [] message.tag = OrderModifyMessageCode -> EncodeOrderModifyMessage(message.body)
      [] message.tag = OrderModifyExtendedMessageCode -> EncodeOrderModifyExtendedMessage(message.body)
      [] message.tag = OrderAddResponseMessageCode -> EncodeOrderAddResponseMessage(message.body)
      [] message.tag = OrderCancelResponseMessageCode -> EncodeOrderCancelResponseMessage(message.body)
      [] message.tag = OrderModifyResponseMessageCode -> EncodeOrderModifyResponseMessage(message.body)
      [] message.tag = QuoteRequestMessageCode -> EncodeQuoteRequestMessage(message.body)
      [] message.tag = QuoteRequestNotificationMessageCode -> EncodeQuoteRequestNotificationMessage(message.body)
      [] message.tag = QuoteAddMessageCode -> EncodeQuoteAddMessage(message.body)
      [] message.tag = QuoteModifyMessageCode -> EncodeQuoteModifyMessage(message.body)
      [] message.tag = QuoteCancelMessageCode -> EncodeQuoteCancelMessage(message.body)
      [] message.tag = TradeMessageCode -> EncodeTradeMessage(message.body)
      [] message.tag = TradeBustMessageCode -> EncodeTradeBustMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LoginMessageCode -> DecodeLoginMessage(bytes)
              [] tag = LoginResponseMessageCode -> DecodeLoginResponseMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutRequestMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = OrderAddMessageCode -> DecodeOrderAddMessage(bytes)
              [] tag = OrderAddExtendedMessageCode -> DecodeOrderAddExtendedMessage(bytes)
              [] tag = OrderCancelMessageCode -> DecodeOrderCancelMessage(bytes)
              [] tag = OrderModifyMessageCode -> DecodeOrderModifyMessage(bytes)
              [] tag = OrderModifyExtendedMessageCode -> DecodeOrderModifyExtendedMessage(bytes)
              [] tag = OrderAddResponseMessageCode -> DecodeOrderAddResponseMessage(bytes)
              [] tag = OrderCancelResponseMessageCode -> DecodeOrderCancelResponseMessage(bytes)
              [] tag = OrderModifyResponseMessageCode -> DecodeOrderModifyResponseMessage(bytes)
              [] tag = QuoteRequestMessageCode -> DecodeQuoteRequestMessage(bytes)
              [] tag = QuoteRequestNotificationMessageCode -> DecodeQuoteRequestNotificationMessage(bytes)
              [] tag = QuoteAddMessageCode -> DecodeQuoteAddMessage(bytes)
              [] tag = QuoteModifyMessageCode -> DecodeQuoteModifyMessage(bytes)
              [] tag = QuoteCancelMessageCode -> DecodeQuoteCancelMessage(bytes)
              [] tag = TradeMessageCode -> DecodeTradeMessage(bytes)
              [] tag = TradeBustMessageCode -> DecodeTradeBustMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LoginMessageCode, body |-> one] : one \in CheckedLoginMessage }
        \cup { [tag |-> LoginResponseMessageCode, body |-> one] : one \in CheckedLoginResponseMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutRequestMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> OrderAddMessageCode, body |-> one] : one \in CheckedOrderAddMessage }
        \cup { [tag |-> OrderAddExtendedMessageCode, body |-> one] : one \in CheckedOrderAddExtendedMessage }
        \cup { [tag |-> OrderCancelMessageCode, body |-> one] : one \in CheckedOrderCancelMessage }
        \cup { [tag |-> OrderModifyMessageCode, body |-> one] : one \in CheckedOrderModifyMessage }
        \cup { [tag |-> OrderModifyExtendedMessageCode, body |-> one] : one \in CheckedOrderModifyExtendedMessage }
        \cup { [tag |-> OrderAddResponseMessageCode, body |-> one] : one \in CheckedOrderAddResponseMessage }
        \cup { [tag |-> OrderCancelResponseMessageCode, body |-> one] : one \in CheckedOrderCancelResponseMessage }
        \cup { [tag |-> OrderModifyResponseMessageCode, body |-> one] : one \in CheckedOrderModifyResponseMessage }
        \cup { [tag |-> QuoteRequestMessageCode, body |-> one] : one \in CheckedQuoteRequestMessage }
        \cup { [tag |-> QuoteRequestNotificationMessageCode, body |-> one] : one \in CheckedQuoteRequestNotificationMessage }
        \cup { [tag |-> QuoteAddMessageCode, body |-> one] : one \in CheckedQuoteAddMessage }
        \cup { [tag |-> QuoteModifyMessageCode, body |-> one] : one \in CheckedQuoteModifyMessage }
        \cup { [tag |-> QuoteCancelMessageCode, body |-> one] : one \in CheckedQuoteCancelMessage }
        \cup { [tag |-> TradeMessageCode, body |-> one] : one \in CheckedTradeMessage }
        \cup { [tag |-> TradeBustMessageCode, body |-> one] : one \in CheckedTradeBustMessage }

(***************************************************************************)
(* Message, framed by Msg Length                                           *)
(***************************************************************************)

Message ==
    [ msgSeqNo : Sample(8),
      payload  : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o message.msgSeqNo
        \o EncodePayload(message.payload)

(* Msg Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeMessageBody(bytes) ==
    LET msgType == ReadUIntBE(bytes, 1) IN IF ~msgType.ok THEN Fail ELSE
    LET msgSeqNo == ReadBytes(msgType.rest, 8) IN IF ~msgSeqNo.ok THEN Fail ELSE
    LET payload == DecodePayload(msgType.value, msgSeqNo.rest) IN IF ~payload.ok THEN Fail ELSE
    Ok([ msgSeqNo |-> msgSeqNo.value,
         payload  |-> payload.value ], payload.rest)

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
    [ msgSeqNo |-> [i \in 1 .. 8 |-> 0],
      payload  |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.msgSeqNo = one] : one \in Sample(8) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> LoginMessageCode, body |-> ZeroLoginMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LoginResponseMessageCode, body |-> ZeroLoginResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogoutRequestMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogoutMessageCode, body |-> ZeroLogoutMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAddMessageCode, body |-> ZeroOrderAddMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAddExtendedMessageCode, body |-> ZeroOrderAddExtendedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelMessageCode, body |-> ZeroOrderCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifyMessageCode, body |-> ZeroOrderModifyMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifyExtendedMessageCode, body |-> ZeroOrderModifyExtendedMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderAddResponseMessageCode, body |-> ZeroOrderAddResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelResponseMessageCode, body |-> ZeroOrderCancelResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderModifyResponseMessageCode, body |-> ZeroOrderModifyResponseMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteRequestMessageCode, body |-> ZeroQuoteRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteRequestNotificationMessageCode, body |-> ZeroQuoteRequestNotificationMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteAddMessageCode, body |-> ZeroQuoteAddMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteModifyMessageCode, body |-> ZeroQuoteModifyMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> QuoteCancelMessageCode, body |-> ZeroQuoteCancelMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeMessageCode, body |-> ZeroTradeMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> TradeBustMessageCode, body |-> ZeroTradeBustMessage]] }

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

(* Every Login Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginMessage ==
    \A message \in CheckedLoginMessage :
        LET read == DecodeLoginMessage(EncodeLoginMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Login Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLoginResponseMessage ==
    \A message \in CheckedLoginResponseMessage :
        LET read == DecodeLoginResponseMessage(EncodeLoginResponseMessage(message))
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

(* Every Order Add Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddMessage ==
    \A message \in CheckedOrderAddMessage :
        LET read == DecodeOrderAddMessage(EncodeOrderAddMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Add Extended Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddExtendedMessage ==
    \A message \in CheckedOrderAddExtendedMessage :
        LET read == DecodeOrderAddExtendedMessage(EncodeOrderAddExtendedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelMessage ==
    \A message \in CheckedOrderCancelMessage :
        LET read == DecodeOrderCancelMessage(EncodeOrderCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifyMessage ==
    \A message \in CheckedOrderModifyMessage :
        LET read == DecodeOrderModifyMessage(EncodeOrderModifyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify Extended Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifyExtendedMessage ==
    \A message \in CheckedOrderModifyExtendedMessage :
        LET read == DecodeOrderModifyExtendedMessage(EncodeOrderModifyExtendedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Add Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderAddResponseMessage ==
    \A message \in CheckedOrderAddResponseMessage :
        LET read == DecodeOrderAddResponseMessage(EncodeOrderAddResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelResponseMessage ==
    \A message \in CheckedOrderCancelResponseMessage :
        LET read == DecodeOrderCancelResponseMessage(EncodeOrderCancelResponseMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Modify Response Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderModifyResponseMessage ==
    \A message \in CheckedOrderModifyResponseMessage :
        LET read == DecodeOrderModifyResponseMessage(EncodeOrderModifyResponseMessage(message))
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

(* Every Quote Request Notification Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteRequestNotificationMessage ==
    \A message \in CheckedQuoteRequestNotificationMessage :
        LET read == DecodeQuoteRequestNotificationMessage(EncodeQuoteRequestNotificationMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Add Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteAddMessage ==
    \A message \in CheckedQuoteAddMessage :
        LET read == DecodeQuoteAddMessage(EncodeQuoteAddMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Modify Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteModifyMessage ==
    \A message \in CheckedQuoteModifyMessage :
        LET read == DecodeQuoteModifyMessage(EncodeQuoteModifyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Message decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelMessage ==
    \A message \in CheckedQuoteCancelMessage :
        LET read == DecodeQuoteCancelMessage(EncodeQuoteCancelMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeMessage ==
    \A message \in CheckedTradeMessage :
        LET read == DecodeTradeMessage(EncodeTradeMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Bust Message decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeBustMessage ==
    \A message \in CheckedTradeBustMessage :
        LET read == DecodeTradeBustMessage(EncodeTradeBustMessage(message))
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

(* A Payload is selected by the Msg Type it is written under *)
SelectsPayload ==
    \A message \in CheckedPayload :
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Msg Length is written from the bytes it frames *)
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
