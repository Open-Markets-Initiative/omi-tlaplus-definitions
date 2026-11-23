--------------- MODULE Turquoise_NativeTradingGateway_v6_1_2 ---------------
(***************************************************************************)
(* London Stock Exchange Native Trading Gateway v6.1.2                     *)
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
(* Logon Message: 76 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ compId         : Sample(25),
      password       : Sample(25),
      newPassword    : Sample(25),
      messageVersion : Sample(1) ]

EncodeLogonMessage(message) ==
    message.compId
        \o message.password
        \o message.newPassword
        \o message.messageVersion

DecodeLogonMessage(bytes) ==
    LET compId == ReadBytes(bytes, 25) IN IF ~compId.ok THEN Fail ELSE
    LET password == ReadBytes(compId.rest, 25) IN IF ~password.ok THEN Fail ELSE
    LET newPassword == ReadBytes(password.rest, 25) IN IF ~newPassword.ok THEN Fail ELSE
    LET messageVersion == ReadBytes(newPassword.rest, 1) IN IF ~messageVersion.ok THEN Fail ELSE
    Ok([ compId         |-> compId.value,
         password       |-> password.value,
         newPassword    |-> newPassword.value,
         messageVersion |-> messageVersion.value ], messageVersion.rest)

ZeroLogonMessage ==
    [ compId         |-> [i \in 1 .. 25 |-> 0],
      password       |-> [i \in 1 .. 25 |-> 0],
      newPassword    |-> [i \in 1 .. 25 |-> 0],
      messageVersion |-> [i \in 1 .. 1 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.compId = one] : one \in Sample(25) }
        \cup { [ZeroLogonMessage EXCEPT !.password = one] : one \in Sample(25) }
        \cup { [ZeroLogonMessage EXCEPT !.newPassword = one] : one \in Sample(25) }
        \cup { [ZeroLogonMessage EXCEPT !.messageVersion = one] : one \in Sample(1) }

(***************************************************************************)
(* Logon Reply Message: 34 bytes                                           *)
(***************************************************************************)

LogonReplyMessage ==
    [ rejectCode             : Sample(4),
      passwordExpiryDayCount : Sample(30) ]

EncodeLogonReplyMessage(message) ==
    message.rejectCode
        \o message.passwordExpiryDayCount

DecodeLogonReplyMessage(bytes) ==
    LET rejectCode == ReadBytes(bytes, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET passwordExpiryDayCount == ReadBytes(rejectCode.rest, 30) IN IF ~passwordExpiryDayCount.ok THEN Fail ELSE
    Ok([ rejectCode             |-> rejectCode.value,
         passwordExpiryDayCount |-> passwordExpiryDayCount.value ], passwordExpiryDayCount.rest)

ZeroLogonReplyMessage ==
    [ rejectCode             |-> [i \in 1 .. 4 |-> 0],
      passwordExpiryDayCount |-> [i \in 1 .. 30 |-> 0] ]

(* Logon Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonReplyMessage ==
    { ZeroLogonReplyMessage }
        \cup { [ZeroLogonReplyMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroLogonReplyMessage EXCEPT !.passwordExpiryDayCount = one] : one \in Sample(30) }

(***************************************************************************)
(* Logout Message: 20 bytes                                                *)
(***************************************************************************)

LogoutMessage ==
    [ logoutReason : Sample(20) ]

EncodeLogoutMessage(message) ==
    message.logoutReason

DecodeLogoutMessage(bytes) ==
    LET logoutReason == ReadBytes(bytes, 20) IN IF ~logoutReason.ok THEN Fail ELSE
    Ok([ logoutReason |-> logoutReason.value ], logoutReason.rest)

ZeroLogoutMessage ==
    [ logoutReason |-> [i \in 1 .. 20 |-> 0] ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.logoutReason = one] : one \in Sample(20) }

(***************************************************************************)
(* Reject Message: 55 bytes                                                *)
(***************************************************************************)

RejectMessage ==
    [ rejectCode          : Sample(4),
      rejectReason        : Sample(30),
      rejectedMessageType : Sample(1),
      clientOrderId       : Sample(20) ]

EncodeRejectMessage(message) ==
    message.rejectCode
        \o message.rejectReason
        \o message.rejectedMessageType
        \o message.clientOrderId

DecodeRejectMessage(bytes) ==
    LET rejectCode == ReadBytes(bytes, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET rejectReason == ReadBytes(rejectCode.rest, 30) IN IF ~rejectReason.ok THEN Fail ELSE
    LET rejectedMessageType == ReadBytes(rejectReason.rest, 1) IN IF ~rejectedMessageType.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(rejectedMessageType.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    Ok([ rejectCode          |-> rejectCode.value,
         rejectReason        |-> rejectReason.value,
         rejectedMessageType |-> rejectedMessageType.value,
         clientOrderId       |-> clientOrderId.value ], clientOrderId.rest)

ZeroRejectMessage ==
    [ rejectCode          |-> [i \in 1 .. 4 |-> 0],
      rejectReason        |-> [i \in 1 .. 30 |-> 0],
      rejectedMessageType |-> [i \in 1 .. 1 |-> 0],
      clientOrderId       |-> [i \in 1 .. 20 |-> 0] ]

(* Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectMessage ==
    { ZeroRejectMessage }
        \cup { [ZeroRejectMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroRejectMessage EXCEPT !.rejectReason = one] : one \in Sample(30) }
        \cup { [ZeroRejectMessage EXCEPT !.rejectedMessageType = one] : one \in Sample(1) }
        \cup { [ZeroRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }

(***************************************************************************)
(* New Order Message: 121 bytes                                            *)
(***************************************************************************)

NewOrderMessage ==
    [ clientOrderId           : Sample(20),
      traderId                : Sample(11),
      account                 : Sample(10),
      clearingAccount         : Sample(1),
      mtfCommonSymbol         : Sample(8),
      orderType               : Sample(1),
      tif                     : Sample(1),
      expireDateTime          : Sample(4),
      side                    : Sample(1),
      orderQty                : Sample(4),
      displayQty              : Sample(4),
      limitPrice              : Sample(8),
      capacity                : Sample(1),
      autoCancel              : Sample(1),
      orderSubType            : Sample(1),
      ownerType               : Sample(1),
      reserved8               : Sample(8),
      targetBook              : Sample(1),
      execInstruction         : Sample(1),
      minimumQuantity         : Sample(4),
      reserved1               : Sample(1),
      secondReserved1         : Sample(1),
      pegPriceType            : Sample(1),
      passiveOnlyOrder        : Sample(1),
      clOrdLinkId             : Sample(12),
      clientId                : Sample(4),
      investmentDecisionMaker : Sample(4),
      executingWithinFirm     : Sample(4),
      miFidFlags              : Sample(1),
      partyRoleQualifiers     : Sample(1) ]

EncodeNewOrderMessage(message) ==
    message.clientOrderId
        \o message.traderId
        \o message.account
        \o message.clearingAccount
        \o message.mtfCommonSymbol
        \o message.orderType
        \o message.tif
        \o message.expireDateTime
        \o message.side
        \o message.orderQty
        \o message.displayQty
        \o message.limitPrice
        \o message.capacity
        \o message.autoCancel
        \o message.orderSubType
        \o message.ownerType
        \o message.reserved8
        \o message.targetBook
        \o message.execInstruction
        \o message.minimumQuantity
        \o message.reserved1
        \o message.secondReserved1
        \o message.pegPriceType
        \o message.passiveOnlyOrder
        \o message.clOrdLinkId
        \o message.clientId
        \o message.investmentDecisionMaker
        \o message.executingWithinFirm
        \o message.miFidFlags
        \o message.partyRoleQualifiers

DecodeNewOrderMessage(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET traderId == ReadBytes(clientOrderId.rest, 11) IN IF ~traderId.ok THEN Fail ELSE
    LET account == ReadBytes(traderId.rest, 10) IN IF ~account.ok THEN Fail ELSE
    LET clearingAccount == ReadBytes(account.rest, 1) IN IF ~clearingAccount.ok THEN Fail ELSE
    LET mtfCommonSymbol == ReadBytes(clearingAccount.rest, 8) IN IF ~mtfCommonSymbol.ok THEN Fail ELSE
    LET orderType == ReadBytes(mtfCommonSymbol.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET tif == ReadBytes(orderType.rest, 1) IN IF ~tif.ok THEN Fail ELSE
    LET expireDateTime == ReadBytes(tif.rest, 4) IN IF ~expireDateTime.ok THEN Fail ELSE
    LET side == ReadBytes(expireDateTime.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET orderQty == ReadBytes(side.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(orderQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET limitPrice == ReadBytes(displayQty.rest, 8) IN IF ~limitPrice.ok THEN Fail ELSE
    LET capacity == ReadBytes(limitPrice.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET autoCancel == ReadBytes(capacity.rest, 1) IN IF ~autoCancel.ok THEN Fail ELSE
    LET orderSubType == ReadBytes(autoCancel.rest, 1) IN IF ~orderSubType.ok THEN Fail ELSE
    LET ownerType == ReadBytes(orderSubType.rest, 1) IN IF ~ownerType.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(ownerType.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET targetBook == ReadBytes(reserved8.rest, 1) IN IF ~targetBook.ok THEN Fail ELSE
    LET execInstruction == ReadBytes(targetBook.rest, 1) IN IF ~execInstruction.ok THEN Fail ELSE
    LET minimumQuantity == ReadBytes(execInstruction.rest, 4) IN IF ~minimumQuantity.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(minimumQuantity.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET secondReserved1 == ReadBytes(reserved1.rest, 1) IN IF ~secondReserved1.ok THEN Fail ELSE
    LET pegPriceType == ReadBytes(secondReserved1.rest, 1) IN IF ~pegPriceType.ok THEN Fail ELSE
    LET passiveOnlyOrder == ReadBytes(pegPriceType.rest, 1) IN IF ~passiveOnlyOrder.ok THEN Fail ELSE
    LET clOrdLinkId == ReadBytes(passiveOnlyOrder.rest, 12) IN IF ~clOrdLinkId.ok THEN Fail ELSE
    LET clientId == ReadBytes(clOrdLinkId.rest, 4) IN IF ~clientId.ok THEN Fail ELSE
    LET investmentDecisionMaker == ReadBytes(clientId.rest, 4) IN IF ~investmentDecisionMaker.ok THEN Fail ELSE
    LET executingWithinFirm == ReadBytes(investmentDecisionMaker.rest, 4) IN IF ~executingWithinFirm.ok THEN Fail ELSE
    LET miFidFlags == ReadBytes(executingWithinFirm.rest, 1) IN IF ~miFidFlags.ok THEN Fail ELSE
    LET partyRoleQualifiers == ReadBytes(miFidFlags.rest, 1) IN IF ~partyRoleQualifiers.ok THEN Fail ELSE
    Ok([ clientOrderId           |-> clientOrderId.value,
         traderId                |-> traderId.value,
         account                 |-> account.value,
         clearingAccount         |-> clearingAccount.value,
         mtfCommonSymbol         |-> mtfCommonSymbol.value,
         orderType               |-> orderType.value,
         tif                     |-> tif.value,
         expireDateTime          |-> expireDateTime.value,
         side                    |-> side.value,
         orderQty                |-> orderQty.value,
         displayQty              |-> displayQty.value,
         limitPrice              |-> limitPrice.value,
         capacity                |-> capacity.value,
         autoCancel              |-> autoCancel.value,
         orderSubType            |-> orderSubType.value,
         ownerType               |-> ownerType.value,
         reserved8               |-> reserved8.value,
         targetBook              |-> targetBook.value,
         execInstruction         |-> execInstruction.value,
         minimumQuantity         |-> minimumQuantity.value,
         reserved1               |-> reserved1.value,
         secondReserved1         |-> secondReserved1.value,
         pegPriceType            |-> pegPriceType.value,
         passiveOnlyOrder        |-> passiveOnlyOrder.value,
         clOrdLinkId             |-> clOrdLinkId.value,
         clientId                |-> clientId.value,
         investmentDecisionMaker |-> investmentDecisionMaker.value,
         executingWithinFirm     |-> executingWithinFirm.value,
         miFidFlags              |-> miFidFlags.value,
         partyRoleQualifiers     |-> partyRoleQualifiers.value ], partyRoleQualifiers.rest)

ZeroNewOrderMessage ==
    [ clientOrderId           |-> [i \in 1 .. 20 |-> 0],
      traderId                |-> [i \in 1 .. 11 |-> 0],
      account                 |-> [i \in 1 .. 10 |-> 0],
      clearingAccount         |-> [i \in 1 .. 1 |-> 0],
      mtfCommonSymbol         |-> [i \in 1 .. 8 |-> 0],
      orderType               |-> [i \in 1 .. 1 |-> 0],
      tif                     |-> [i \in 1 .. 1 |-> 0],
      expireDateTime          |-> [i \in 1 .. 4 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      orderQty                |-> [i \in 1 .. 4 |-> 0],
      displayQty              |-> [i \in 1 .. 4 |-> 0],
      limitPrice              |-> [i \in 1 .. 8 |-> 0],
      capacity                |-> [i \in 1 .. 1 |-> 0],
      autoCancel              |-> [i \in 1 .. 1 |-> 0],
      orderSubType            |-> [i \in 1 .. 1 |-> 0],
      ownerType               |-> [i \in 1 .. 1 |-> 0],
      reserved8               |-> [i \in 1 .. 8 |-> 0],
      targetBook              |-> [i \in 1 .. 1 |-> 0],
      execInstruction         |-> [i \in 1 .. 1 |-> 0],
      minimumQuantity         |-> [i \in 1 .. 4 |-> 0],
      reserved1               |-> [i \in 1 .. 1 |-> 0],
      secondReserved1         |-> [i \in 1 .. 1 |-> 0],
      pegPriceType            |-> [i \in 1 .. 1 |-> 0],
      passiveOnlyOrder        |-> [i \in 1 .. 1 |-> 0],
      clOrdLinkId             |-> [i \in 1 .. 12 |-> 0],
      clientId                |-> [i \in 1 .. 4 |-> 0],
      investmentDecisionMaker |-> [i \in 1 .. 4 |-> 0],
      executingWithinFirm     |-> [i \in 1 .. 4 |-> 0],
      miFidFlags              |-> [i \in 1 .. 1 |-> 0],
      partyRoleQualifiers     |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderMessage ==
    { ZeroNewOrderMessage }
        \cup { [ZeroNewOrderMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderMessage EXCEPT !.traderId = one] : one \in Sample(11) }
        \cup { [ZeroNewOrderMessage EXCEPT !.account = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderMessage EXCEPT !.clearingAccount = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.mtfCommonSymbol = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.tif = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.expireDateTime = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.limitPrice = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.autoCancel = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.orderSubType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.ownerType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderMessage EXCEPT !.targetBook = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.execInstruction = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.minimumQuantity = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.secondReserved1 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.pegPriceType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.passiveOnlyOrder = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.clOrdLinkId = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderMessage EXCEPT !.clientId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.investmentDecisionMaker = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.executingWithinFirm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderMessage EXCEPT !.miFidFlags = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderMessage EXCEPT !.partyRoleQualifiers = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Cancel Replace Request Message: 110 bytes                         *)
(***************************************************************************)

OrderCancelReplaceRequestMessage ==
    [ clientOrderId         : Sample(20),
      originalClientOrderId : Sample(20),
      orderId               : Sample(12),
      commonSymbol          : Sample(8),
      expireDateTime        : Sample(4),
      orderQty              : Sample(4),
      displayQty            : Sample(4),
      limitPrice            : Sample(8),
      account               : Sample(10),
      reserved1             : Sample(1),
      side                  : Sample(1),
      reserved8             : Sample(8),
      targetBook            : Sample(1),
      execInstruction       : Sample(1),
      minQty                : Sample(4),
      passiveOnlyOrder      : Sample(1),
      reserved3             : Sample(3) ]

EncodeOrderCancelReplaceRequestMessage(message) ==
    message.clientOrderId
        \o message.originalClientOrderId
        \o message.orderId
        \o message.commonSymbol
        \o message.expireDateTime
        \o message.orderQty
        \o message.displayQty
        \o message.limitPrice
        \o message.account
        \o message.reserved1
        \o message.side
        \o message.reserved8
        \o message.targetBook
        \o message.execInstruction
        \o message.minQty
        \o message.passiveOnlyOrder
        \o message.reserved3

DecodeOrderCancelReplaceRequestMessage(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrderId == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(originalClientOrderId.rest, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET commonSymbol == ReadBytes(orderId.rest, 8) IN IF ~commonSymbol.ok THEN Fail ELSE
    LET expireDateTime == ReadBytes(commonSymbol.rest, 4) IN IF ~expireDateTime.ok THEN Fail ELSE
    LET orderQty == ReadBytes(expireDateTime.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(orderQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET limitPrice == ReadBytes(displayQty.rest, 8) IN IF ~limitPrice.ok THEN Fail ELSE
    LET account == ReadBytes(limitPrice.rest, 10) IN IF ~account.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(account.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET side == ReadBytes(reserved1.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET reserved8 == ReadBytes(side.rest, 8) IN IF ~reserved8.ok THEN Fail ELSE
    LET targetBook == ReadBytes(reserved8.rest, 1) IN IF ~targetBook.ok THEN Fail ELSE
    LET execInstruction == ReadBytes(targetBook.rest, 1) IN IF ~execInstruction.ok THEN Fail ELSE
    LET minQty == ReadBytes(execInstruction.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET passiveOnlyOrder == ReadBytes(minQty.rest, 1) IN IF ~passiveOnlyOrder.ok THEN Fail ELSE
    LET reserved3 == ReadBytes(passiveOnlyOrder.rest, 3) IN IF ~reserved3.ok THEN Fail ELSE
    Ok([ clientOrderId         |-> clientOrderId.value,
         originalClientOrderId |-> originalClientOrderId.value,
         orderId               |-> orderId.value,
         commonSymbol          |-> commonSymbol.value,
         expireDateTime        |-> expireDateTime.value,
         orderQty              |-> orderQty.value,
         displayQty            |-> displayQty.value,
         limitPrice            |-> limitPrice.value,
         account               |-> account.value,
         reserved1             |-> reserved1.value,
         side                  |-> side.value,
         reserved8             |-> reserved8.value,
         targetBook            |-> targetBook.value,
         execInstruction       |-> execInstruction.value,
         minQty                |-> minQty.value,
         passiveOnlyOrder      |-> passiveOnlyOrder.value,
         reserved3             |-> reserved3.value ], reserved3.rest)

ZeroOrderCancelReplaceRequestMessage ==
    [ clientOrderId         |-> [i \in 1 .. 20 |-> 0],
      originalClientOrderId |-> [i \in 1 .. 20 |-> 0],
      orderId               |-> [i \in 1 .. 12 |-> 0],
      commonSymbol          |-> [i \in 1 .. 8 |-> 0],
      expireDateTime        |-> [i \in 1 .. 4 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      displayQty            |-> [i \in 1 .. 4 |-> 0],
      limitPrice            |-> [i \in 1 .. 8 |-> 0],
      account               |-> [i \in 1 .. 10 |-> 0],
      reserved1             |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      reserved8             |-> [i \in 1 .. 8 |-> 0],
      targetBook            |-> [i \in 1 .. 1 |-> 0],
      execInstruction       |-> [i \in 1 .. 1 |-> 0],
      minQty                |-> [i \in 1 .. 4 |-> 0],
      passiveOnlyOrder      |-> [i \in 1 .. 1 |-> 0],
      reserved3             |-> [i \in 1 .. 3 |-> 0] ]

(* Order Cancel Replace Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelReplaceRequestMessage ==
    { ZeroOrderCancelReplaceRequestMessage }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.originalClientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.commonSymbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.expireDateTime = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.limitPrice = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.account = one] : one \in Sample(10) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.reserved8 = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.targetBook = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.execInstruction = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.passiveOnlyOrder = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequestMessage EXCEPT !.reserved3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Order Cancel Request Message: 72 bytes                                  *)
(***************************************************************************)

OrderCancelRequestMessage ==
    [ clientOrderId         : Sample(20),
      originalClientOrderId : Sample(20),
      orderId               : Sample(12),
      commonSymbol          : Sample(8),
      side                  : Sample(1),
      targetBook            : Sample(1),
      reserved10            : Sample(10) ]

EncodeOrderCancelRequestMessage(message) ==
    message.clientOrderId
        \o message.originalClientOrderId
        \o message.orderId
        \o message.commonSymbol
        \o message.side
        \o message.targetBook
        \o message.reserved10

DecodeOrderCancelRequestMessage(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET originalClientOrderId == ReadBytes(clientOrderId.rest, 20) IN IF ~originalClientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(originalClientOrderId.rest, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET commonSymbol == ReadBytes(orderId.rest, 8) IN IF ~commonSymbol.ok THEN Fail ELSE
    LET side == ReadBytes(commonSymbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET targetBook == ReadBytes(side.rest, 1) IN IF ~targetBook.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(targetBook.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ clientOrderId         |-> clientOrderId.value,
         originalClientOrderId |-> originalClientOrderId.value,
         orderId               |-> orderId.value,
         commonSymbol          |-> commonSymbol.value,
         side                  |-> side.value,
         targetBook            |-> targetBook.value,
         reserved10            |-> reserved10.value ], reserved10.rest)

ZeroOrderCancelRequestMessage ==
    [ clientOrderId         |-> [i \in 1 .. 20 |-> 0],
      originalClientOrderId |-> [i \in 1 .. 20 |-> 0],
      orderId               |-> [i \in 1 .. 12 |-> 0],
      commonSymbol          |-> [i \in 1 .. 8 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      targetBook            |-> [i \in 1 .. 1 |-> 0],
      reserved10            |-> [i \in 1 .. 10 |-> 0] ]

(* Order Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRequestMessage ==
    { ZeroOrderCancelRequestMessage }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.originalClientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.commonSymbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.targetBook = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRequestMessage EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Order Mass Cancel Request Message: 44 bytes                             *)
(***************************************************************************)

OrderMassCancelRequestMessage ==
    [ clientOrderId  : Sample(20),
      massCancelType : Sample(1),
      commonSymbol   : Sample(8),
      segment        : Sample(4),
      reserved1      : Sample(1),
      targetBook     : Sample(1),
      reserved9      : Sample(9) ]

EncodeOrderMassCancelRequestMessage(message) ==
    message.clientOrderId
        \o message.massCancelType
        \o message.commonSymbol
        \o message.segment
        \o message.reserved1
        \o message.targetBook
        \o message.reserved9

DecodeOrderMassCancelRequestMessage(bytes) ==
    LET clientOrderId == ReadBytes(bytes, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET massCancelType == ReadBytes(clientOrderId.rest, 1) IN IF ~massCancelType.ok THEN Fail ELSE
    LET commonSymbol == ReadBytes(massCancelType.rest, 8) IN IF ~commonSymbol.ok THEN Fail ELSE
    LET segment == ReadBytes(commonSymbol.rest, 4) IN IF ~segment.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(segment.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET targetBook == ReadBytes(reserved1.rest, 1) IN IF ~targetBook.ok THEN Fail ELSE
    LET reserved9 == ReadBytes(targetBook.rest, 9) IN IF ~reserved9.ok THEN Fail ELSE
    Ok([ clientOrderId  |-> clientOrderId.value,
         massCancelType |-> massCancelType.value,
         commonSymbol   |-> commonSymbol.value,
         segment        |-> segment.value,
         reserved1      |-> reserved1.value,
         targetBook     |-> targetBook.value,
         reserved9      |-> reserved9.value ], reserved9.rest)

ZeroOrderMassCancelRequestMessage ==
    [ clientOrderId  |-> [i \in 1 .. 20 |-> 0],
      massCancelType |-> [i \in 1 .. 1 |-> 0],
      commonSymbol   |-> [i \in 1 .. 8 |-> 0],
      segment        |-> [i \in 1 .. 4 |-> 0],
      reserved1      |-> [i \in 1 .. 1 |-> 0],
      targetBook     |-> [i \in 1 .. 1 |-> 0],
      reserved9      |-> [i \in 1 .. 9 |-> 0] ]

(* Order Mass Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassCancelRequestMessage ==
    { ZeroOrderMassCancelRequestMessage }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.massCancelType = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.commonSymbol = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.segment = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.targetBook = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelRequestMessage EXCEPT !.reserved9 = one] : one \in Sample(9) }

(***************************************************************************)
(* Transact Time: 8 bytes                                                  *)
(***************************************************************************)

TransactTime ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTransactTime(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTransactTime(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTransactTime ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Transact Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTime ==
    { ZeroTransactTime }
        \cup { [ZeroTransactTime EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTransactTime EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Execution Report Message: 179 bytes                                     *)
(***************************************************************************)

ExecutionReportMessage ==
    [ appId                   : Sample(1),
      sequenceNo              : Sample(4),
      executionId             : Sample(12),
      clientOrderId           : Sample(20),
      orderId                 : Sample(12),
      execType                : Sample(1),
      executionReportRefId    : Sample(12),
      orderStatus             : Sample(1),
      orderRejectCode         : Sample(4),
      executedPrice           : Sample(8),
      executedQty             : Sample(4),
      leavesQty               : Sample(4),
      waiverFlags             : Sample(1),
      displayQty              : Sample(4),
      commonSymbol            : Sample(8),
      side                    : Sample(1),
      secondaryOrderId        : Sample(8),
      counterparty            : Sample(11),
      tradeLiquidityIndicator : Sample(1),
      tradeMatchId            : Sample(8),
      transactTime            : TransactTime,
      targetBook              : Sample(1),
      typeOfTrade             : Sample(1),
      capacity                : Sample(1),
      reserved1               : Sample(1),
      publicOrderId           : Sample(12),
      minimumQuantity         : Sample(4),
      reputationalScore       : Sample(1),
      lastMarket              : Sample(1),
      pegPriceType            : Sample(1),
      ownerType               : Sample(1),
      waiverFlags2            : Sample(1),
      reserved21              : Sample(21) ]

EncodeExecutionReportMessage(message) ==
    message.appId
        \o message.sequenceNo
        \o message.executionId
        \o message.clientOrderId
        \o message.orderId
        \o message.execType
        \o message.executionReportRefId
        \o message.orderStatus
        \o message.orderRejectCode
        \o message.executedPrice
        \o message.executedQty
        \o message.leavesQty
        \o message.waiverFlags
        \o message.displayQty
        \o message.commonSymbol
        \o message.side
        \o message.secondaryOrderId
        \o message.counterparty
        \o message.tradeLiquidityIndicator
        \o message.tradeMatchId
        \o EncodeTransactTime(message.transactTime)
        \o message.targetBook
        \o message.typeOfTrade
        \o message.capacity
        \o message.reserved1
        \o message.publicOrderId
        \o message.minimumQuantity
        \o message.reputationalScore
        \o message.lastMarket
        \o message.pegPriceType
        \o message.ownerType
        \o message.waiverFlags2
        \o message.reserved21

DecodeExecutionReportMessage(bytes) ==
    LET appId == ReadBytes(bytes, 1) IN IF ~appId.ok THEN Fail ELSE
    LET sequenceNo == ReadBytes(appId.rest, 4) IN IF ~sequenceNo.ok THEN Fail ELSE
    LET executionId == ReadBytes(sequenceNo.rest, 12) IN IF ~executionId.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(executionId.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clientOrderId.rest, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET execType == ReadBytes(orderId.rest, 1) IN IF ~execType.ok THEN Fail ELSE
    LET executionReportRefId == ReadBytes(execType.rest, 12) IN IF ~executionReportRefId.ok THEN Fail ELSE
    LET orderStatus == ReadBytes(executionReportRefId.rest, 1) IN IF ~orderStatus.ok THEN Fail ELSE
    LET orderRejectCode == ReadBytes(orderStatus.rest, 4) IN IF ~orderRejectCode.ok THEN Fail ELSE
    LET executedPrice == ReadBytes(orderRejectCode.rest, 8) IN IF ~executedPrice.ok THEN Fail ELSE
    LET executedQty == ReadBytes(executedPrice.rest, 4) IN IF ~executedQty.ok THEN Fail ELSE
    LET leavesQty == ReadBytes(executedQty.rest, 4) IN IF ~leavesQty.ok THEN Fail ELSE
    LET waiverFlags == ReadBytes(leavesQty.rest, 1) IN IF ~waiverFlags.ok THEN Fail ELSE
    LET displayQty == ReadBytes(waiverFlags.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET commonSymbol == ReadBytes(displayQty.rest, 8) IN IF ~commonSymbol.ok THEN Fail ELSE
    LET side == ReadBytes(commonSymbol.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET secondaryOrderId == ReadBytes(side.rest, 8) IN IF ~secondaryOrderId.ok THEN Fail ELSE
    LET counterparty == ReadBytes(secondaryOrderId.rest, 11) IN IF ~counterparty.ok THEN Fail ELSE
    LET tradeLiquidityIndicator == ReadBytes(counterparty.rest, 1) IN IF ~tradeLiquidityIndicator.ok THEN Fail ELSE
    LET tradeMatchId == ReadBytes(tradeLiquidityIndicator.rest, 8) IN IF ~tradeMatchId.ok THEN Fail ELSE
    LET transactTime == DecodeTransactTime(tradeMatchId.rest) IN IF ~transactTime.ok THEN Fail ELSE
    LET targetBook == ReadBytes(transactTime.rest, 1) IN IF ~targetBook.ok THEN Fail ELSE
    LET typeOfTrade == ReadBytes(targetBook.rest, 1) IN IF ~typeOfTrade.ok THEN Fail ELSE
    LET capacity == ReadBytes(typeOfTrade.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET reserved1 == ReadBytes(capacity.rest, 1) IN IF ~reserved1.ok THEN Fail ELSE
    LET publicOrderId == ReadBytes(reserved1.rest, 12) IN IF ~publicOrderId.ok THEN Fail ELSE
    LET minimumQuantity == ReadBytes(publicOrderId.rest, 4) IN IF ~minimumQuantity.ok THEN Fail ELSE
    LET reputationalScore == ReadBytes(minimumQuantity.rest, 1) IN IF ~reputationalScore.ok THEN Fail ELSE
    LET lastMarket == ReadBytes(reputationalScore.rest, 1) IN IF ~lastMarket.ok THEN Fail ELSE
    LET pegPriceType == ReadBytes(lastMarket.rest, 1) IN IF ~pegPriceType.ok THEN Fail ELSE
    LET ownerType == ReadBytes(pegPriceType.rest, 1) IN IF ~ownerType.ok THEN Fail ELSE
    LET waiverFlags2 == ReadBytes(ownerType.rest, 1) IN IF ~waiverFlags2.ok THEN Fail ELSE
    LET reserved21 == ReadBytes(waiverFlags2.rest, 21) IN IF ~reserved21.ok THEN Fail ELSE
    Ok([ appId                   |-> appId.value,
         sequenceNo              |-> sequenceNo.value,
         executionId             |-> executionId.value,
         clientOrderId           |-> clientOrderId.value,
         orderId                 |-> orderId.value,
         execType                |-> execType.value,
         executionReportRefId    |-> executionReportRefId.value,
         orderStatus             |-> orderStatus.value,
         orderRejectCode         |-> orderRejectCode.value,
         executedPrice           |-> executedPrice.value,
         executedQty             |-> executedQty.value,
         leavesQty               |-> leavesQty.value,
         waiverFlags             |-> waiverFlags.value,
         displayQty              |-> displayQty.value,
         commonSymbol            |-> commonSymbol.value,
         side                    |-> side.value,
         secondaryOrderId        |-> secondaryOrderId.value,
         counterparty            |-> counterparty.value,
         tradeLiquidityIndicator |-> tradeLiquidityIndicator.value,
         tradeMatchId            |-> tradeMatchId.value,
         transactTime            |-> transactTime.value,
         targetBook              |-> targetBook.value,
         typeOfTrade             |-> typeOfTrade.value,
         capacity                |-> capacity.value,
         reserved1               |-> reserved1.value,
         publicOrderId           |-> publicOrderId.value,
         minimumQuantity         |-> minimumQuantity.value,
         reputationalScore       |-> reputationalScore.value,
         lastMarket              |-> lastMarket.value,
         pegPriceType            |-> pegPriceType.value,
         ownerType               |-> ownerType.value,
         waiverFlags2            |-> waiverFlags2.value,
         reserved21              |-> reserved21.value ], reserved21.rest)

ZeroExecutionReportMessage ==
    [ appId                   |-> [i \in 1 .. 1 |-> 0],
      sequenceNo              |-> [i \in 1 .. 4 |-> 0],
      executionId             |-> [i \in 1 .. 12 |-> 0],
      clientOrderId           |-> [i \in 1 .. 20 |-> 0],
      orderId                 |-> [i \in 1 .. 12 |-> 0],
      execType                |-> [i \in 1 .. 1 |-> 0],
      executionReportRefId    |-> [i \in 1 .. 12 |-> 0],
      orderStatus             |-> [i \in 1 .. 1 |-> 0],
      orderRejectCode         |-> [i \in 1 .. 4 |-> 0],
      executedPrice           |-> [i \in 1 .. 8 |-> 0],
      executedQty             |-> [i \in 1 .. 4 |-> 0],
      leavesQty               |-> [i \in 1 .. 4 |-> 0],
      waiverFlags             |-> [i \in 1 .. 1 |-> 0],
      displayQty              |-> [i \in 1 .. 4 |-> 0],
      commonSymbol            |-> [i \in 1 .. 8 |-> 0],
      side                    |-> [i \in 1 .. 1 |-> 0],
      secondaryOrderId        |-> [i \in 1 .. 8 |-> 0],
      counterparty            |-> [i \in 1 .. 11 |-> 0],
      tradeLiquidityIndicator |-> [i \in 1 .. 1 |-> 0],
      tradeMatchId            |-> [i \in 1 .. 8 |-> 0],
      transactTime            |-> ZeroTransactTime,
      targetBook              |-> [i \in 1 .. 1 |-> 0],
      typeOfTrade             |-> [i \in 1 .. 1 |-> 0],
      capacity                |-> [i \in 1 .. 1 |-> 0],
      reserved1               |-> [i \in 1 .. 1 |-> 0],
      publicOrderId           |-> [i \in 1 .. 12 |-> 0],
      minimumQuantity         |-> [i \in 1 .. 4 |-> 0],
      reputationalScore       |-> [i \in 1 .. 1 |-> 0],
      lastMarket              |-> [i \in 1 .. 1 |-> 0],
      pegPriceType            |-> [i \in 1 .. 1 |-> 0],
      ownerType               |-> [i \in 1 .. 1 |-> 0],
      waiverFlags2            |-> [i \in 1 .. 1 |-> 0],
      reserved21              |-> [i \in 1 .. 21 |-> 0] ]

(* Execution Report Message at zero, then each field in turn at the values it is checked at *)
CheckedExecutionReportMessage ==
    { ZeroExecutionReportMessage }
        \cup { [ZeroExecutionReportMessage EXCEPT !.appId = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.sequenceNo = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executionId = one] : one \in Sample(12) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.execType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executionReportRefId = one] : one \in Sample(12) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.orderStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.orderRejectCode = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executedPrice = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.executedQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.leavesQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.waiverFlags = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.commonSymbol = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.secondaryOrderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.counterparty = one] : one \in Sample(11) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.tradeLiquidityIndicator = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.tradeMatchId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.transactTime = one] : one \in CheckedTransactTime }
        \cup { [ZeroExecutionReportMessage EXCEPT !.targetBook = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.typeOfTrade = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.reserved1 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.publicOrderId = one] : one \in Sample(12) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.minimumQuantity = one] : one \in Sample(4) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.reputationalScore = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.lastMarket = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.pegPriceType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.ownerType = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.waiverFlags2 = one] : one \in Sample(1) }
        \cup { [ZeroExecutionReportMessage EXCEPT !.reserved21 = one] : one \in Sample(21) }

(***************************************************************************)
(* Transact Time: 8 bytes                                                  *)
(***************************************************************************)

TransactTime2 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTransactTime2(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTransactTime2(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTransactTime2 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Transact Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTime2 ==
    { ZeroTransactTime2 }
        \cup { [ZeroTransactTime2 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTransactTime2 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Cancel Reject Message: 59 bytes                                   *)
(***************************************************************************)

OrderCancelRejectMessage ==
    [ appId              : Sample(1),
      sequenceNo         : Sample(4),
      clientOrderId      : Sample(20),
      orderId            : Sample(12),
      cancelRejectReason : Sample(4),
      transactTime       : TransactTime2,
      reserved10         : Sample(10) ]

EncodeOrderCancelRejectMessage(message) ==
    message.appId
        \o message.sequenceNo
        \o message.clientOrderId
        \o message.orderId
        \o message.cancelRejectReason
        \o EncodeTransactTime2(message.transactTime)
        \o message.reserved10

DecodeOrderCancelRejectMessage(bytes) ==
    LET appId == ReadBytes(bytes, 1) IN IF ~appId.ok THEN Fail ELSE
    LET sequenceNo == ReadBytes(appId.rest, 4) IN IF ~sequenceNo.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(sequenceNo.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clientOrderId.rest, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET cancelRejectReason == ReadBytes(orderId.rest, 4) IN IF ~cancelRejectReason.ok THEN Fail ELSE
    LET transactTime == DecodeTransactTime2(cancelRejectReason.rest) IN IF ~transactTime.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(transactTime.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ appId              |-> appId.value,
         sequenceNo         |-> sequenceNo.value,
         clientOrderId      |-> clientOrderId.value,
         orderId            |-> orderId.value,
         cancelRejectReason |-> cancelRejectReason.value,
         transactTime       |-> transactTime.value,
         reserved10         |-> reserved10.value ], reserved10.rest)

ZeroOrderCancelRejectMessage ==
    [ appId              |-> [i \in 1 .. 1 |-> 0],
      sequenceNo         |-> [i \in 1 .. 4 |-> 0],
      clientOrderId      |-> [i \in 1 .. 20 |-> 0],
      orderId            |-> [i \in 1 .. 12 |-> 0],
      cancelRejectReason |-> [i \in 1 .. 4 |-> 0],
      transactTime       |-> ZeroTransactTime2,
      reserved10         |-> [i \in 1 .. 10 |-> 0] ]

(* Order Cancel Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRejectMessage ==
    { ZeroOrderCancelRejectMessage }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.appId = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.sequenceNo = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.cancelRejectReason = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.transactTime = one] : one \in CheckedTransactTime2 }
        \cup { [ZeroOrderCancelRejectMessage EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Transact Time: 8 bytes                                                  *)
(***************************************************************************)

TransactTime3 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTransactTime3(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTransactTime3(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTransactTime3 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Transact Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTime3 ==
    { ZeroTransactTime3 }
        \cup { [ZeroTransactTime3 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTransactTime3 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Order Mass Cancel Report Message: 52 bytes                              *)
(***************************************************************************)

OrderMassCancelReportMessage ==
    [ appId                  : Sample(1),
      sequenceNo             : Sample(4),
      clientOrderId          : Sample(20),
      massCancelResponse     : Sample(1),
      massCancelRejectReason : Sample(4),
      reserved4              : Sample(4),
      transactTime           : TransactTime3,
      reserved10             : Sample(10) ]

EncodeOrderMassCancelReportMessage(message) ==
    message.appId
        \o message.sequenceNo
        \o message.clientOrderId
        \o message.massCancelResponse
        \o message.massCancelRejectReason
        \o message.reserved4
        \o EncodeTransactTime3(message.transactTime)
        \o message.reserved10

DecodeOrderMassCancelReportMessage(bytes) ==
    LET appId == ReadBytes(bytes, 1) IN IF ~appId.ok THEN Fail ELSE
    LET sequenceNo == ReadBytes(appId.rest, 4) IN IF ~sequenceNo.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(sequenceNo.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET massCancelResponse == ReadBytes(clientOrderId.rest, 1) IN IF ~massCancelResponse.ok THEN Fail ELSE
    LET massCancelRejectReason == ReadBytes(massCancelResponse.rest, 4) IN IF ~massCancelRejectReason.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(massCancelRejectReason.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET transactTime == DecodeTransactTime3(reserved4.rest) IN IF ~transactTime.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(transactTime.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ appId                  |-> appId.value,
         sequenceNo             |-> sequenceNo.value,
         clientOrderId          |-> clientOrderId.value,
         massCancelResponse     |-> massCancelResponse.value,
         massCancelRejectReason |-> massCancelRejectReason.value,
         reserved4              |-> reserved4.value,
         transactTime           |-> transactTime.value,
         reserved10             |-> reserved10.value ], reserved10.rest)

ZeroOrderMassCancelReportMessage ==
    [ appId                  |-> [i \in 1 .. 1 |-> 0],
      sequenceNo             |-> [i \in 1 .. 4 |-> 0],
      clientOrderId          |-> [i \in 1 .. 20 |-> 0],
      massCancelResponse     |-> [i \in 1 .. 1 |-> 0],
      massCancelRejectReason |-> [i \in 1 .. 4 |-> 0],
      reserved4              |-> [i \in 1 .. 4 |-> 0],
      transactTime           |-> ZeroTransactTime3,
      reserved10             |-> [i \in 1 .. 10 |-> 0] ]

(* Order Mass Cancel Report Message at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassCancelReportMessage ==
    { ZeroOrderMassCancelReportMessage }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.appId = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.sequenceNo = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.massCancelResponse = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.massCancelRejectReason = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.transactTime = one] : one \in CheckedTransactTime3 }
        \cup { [ZeroOrderMassCancelReportMessage EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* New Cross Btf Message: 151 bytes                                        *)
(***************************************************************************)

NewCrossBtfMessage ==
    [ crossId                     : Sample(20),
      crossType                   : Sample(1),
      buySideClOrdId              : Sample(20),
      buySideOrderCapacity        : Sample(1),
      buySideClearingAccount      : Sample(1),
      buySideOrderQuantity        : Sample(4),
      reserved4                   : Sample(4),
      buySideFirmId               : Sample(11),
      buySidePartyRole            : Sample(1),
      buyMiFidFlags               : Sample(1),
      buyClientId                 : Sample(4),
      buyInvestmentDecisionMaker  : Sample(4),
      buyExecutingTrader          : Sample(4),
      buyPartyRoleQualifiers      : Sample(1),
      sellSideClOrdId             : Sample(20),
      sellSideOrderCapacity       : Sample(1),
      sellSideClearingAccount     : Sample(1),
      sellSideOrderQuantity       : Sample(4),
      secondReserved4             : Sample(4),
      sellSideFirmId              : Sample(11),
      sellSidePartyRole           : Sample(1),
      sellMiFidFlags              : Sample(1),
      sellClientId                : Sample(4),
      sellInvestmentDecisionMaker : Sample(4),
      sellExecutingTrader         : Sample(4),
      sellPartyRoleQualifiers     : Sample(1),
      mtfCommonSymbol             : Sample(8),
      price                       : Sample(8),
      orderType                   : Sample(1),
      tif                         : Sample(1) ]

EncodeNewCrossBtfMessage(message) ==
    message.crossId
        \o message.crossType
        \o message.buySideClOrdId
        \o message.buySideOrderCapacity
        \o message.buySideClearingAccount
        \o message.buySideOrderQuantity
        \o message.reserved4
        \o message.buySideFirmId
        \o message.buySidePartyRole
        \o message.buyMiFidFlags
        \o message.buyClientId
        \o message.buyInvestmentDecisionMaker
        \o message.buyExecutingTrader
        \o message.buyPartyRoleQualifiers
        \o message.sellSideClOrdId
        \o message.sellSideOrderCapacity
        \o message.sellSideClearingAccount
        \o message.sellSideOrderQuantity
        \o message.secondReserved4
        \o message.sellSideFirmId
        \o message.sellSidePartyRole
        \o message.sellMiFidFlags
        \o message.sellClientId
        \o message.sellInvestmentDecisionMaker
        \o message.sellExecutingTrader
        \o message.sellPartyRoleQualifiers
        \o message.mtfCommonSymbol
        \o message.price
        \o message.orderType
        \o message.tif

DecodeNewCrossBtfMessage(bytes) ==
    LET crossId == ReadBytes(bytes, 20) IN IF ~crossId.ok THEN Fail ELSE
    LET crossType == ReadBytes(crossId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET buySideClOrdId == ReadBytes(crossType.rest, 20) IN IF ~buySideClOrdId.ok THEN Fail ELSE
    LET buySideOrderCapacity == ReadBytes(buySideClOrdId.rest, 1) IN IF ~buySideOrderCapacity.ok THEN Fail ELSE
    LET buySideClearingAccount == ReadBytes(buySideOrderCapacity.rest, 1) IN IF ~buySideClearingAccount.ok THEN Fail ELSE
    LET buySideOrderQuantity == ReadBytes(buySideClearingAccount.rest, 4) IN IF ~buySideOrderQuantity.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(buySideOrderQuantity.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET buySideFirmId == ReadBytes(reserved4.rest, 11) IN IF ~buySideFirmId.ok THEN Fail ELSE
    LET buySidePartyRole == ReadBytes(buySideFirmId.rest, 1) IN IF ~buySidePartyRole.ok THEN Fail ELSE
    LET buyMiFidFlags == ReadBytes(buySidePartyRole.rest, 1) IN IF ~buyMiFidFlags.ok THEN Fail ELSE
    LET buyClientId == ReadBytes(buyMiFidFlags.rest, 4) IN IF ~buyClientId.ok THEN Fail ELSE
    LET buyInvestmentDecisionMaker == ReadBytes(buyClientId.rest, 4) IN IF ~buyInvestmentDecisionMaker.ok THEN Fail ELSE
    LET buyExecutingTrader == ReadBytes(buyInvestmentDecisionMaker.rest, 4) IN IF ~buyExecutingTrader.ok THEN Fail ELSE
    LET buyPartyRoleQualifiers == ReadBytes(buyExecutingTrader.rest, 1) IN IF ~buyPartyRoleQualifiers.ok THEN Fail ELSE
    LET sellSideClOrdId == ReadBytes(buyPartyRoleQualifiers.rest, 20) IN IF ~sellSideClOrdId.ok THEN Fail ELSE
    LET sellSideOrderCapacity == ReadBytes(sellSideClOrdId.rest, 1) IN IF ~sellSideOrderCapacity.ok THEN Fail ELSE
    LET sellSideClearingAccount == ReadBytes(sellSideOrderCapacity.rest, 1) IN IF ~sellSideClearingAccount.ok THEN Fail ELSE
    LET sellSideOrderQuantity == ReadBytes(sellSideClearingAccount.rest, 4) IN IF ~sellSideOrderQuantity.ok THEN Fail ELSE
    LET secondReserved4 == ReadBytes(sellSideOrderQuantity.rest, 4) IN IF ~secondReserved4.ok THEN Fail ELSE
    LET sellSideFirmId == ReadBytes(secondReserved4.rest, 11) IN IF ~sellSideFirmId.ok THEN Fail ELSE
    LET sellSidePartyRole == ReadBytes(sellSideFirmId.rest, 1) IN IF ~sellSidePartyRole.ok THEN Fail ELSE
    LET sellMiFidFlags == ReadBytes(sellSidePartyRole.rest, 1) IN IF ~sellMiFidFlags.ok THEN Fail ELSE
    LET sellClientId == ReadBytes(sellMiFidFlags.rest, 4) IN IF ~sellClientId.ok THEN Fail ELSE
    LET sellInvestmentDecisionMaker == ReadBytes(sellClientId.rest, 4) IN IF ~sellInvestmentDecisionMaker.ok THEN Fail ELSE
    LET sellExecutingTrader == ReadBytes(sellInvestmentDecisionMaker.rest, 4) IN IF ~sellExecutingTrader.ok THEN Fail ELSE
    LET sellPartyRoleQualifiers == ReadBytes(sellExecutingTrader.rest, 1) IN IF ~sellPartyRoleQualifiers.ok THEN Fail ELSE
    LET mtfCommonSymbol == ReadBytes(sellPartyRoleQualifiers.rest, 8) IN IF ~mtfCommonSymbol.ok THEN Fail ELSE
    LET price == ReadBytes(mtfCommonSymbol.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET orderType == ReadBytes(price.rest, 1) IN IF ~orderType.ok THEN Fail ELSE
    LET tif == ReadBytes(orderType.rest, 1) IN IF ~tif.ok THEN Fail ELSE
    Ok([ crossId                     |-> crossId.value,
         crossType                   |-> crossType.value,
         buySideClOrdId              |-> buySideClOrdId.value,
         buySideOrderCapacity        |-> buySideOrderCapacity.value,
         buySideClearingAccount      |-> buySideClearingAccount.value,
         buySideOrderQuantity        |-> buySideOrderQuantity.value,
         reserved4                   |-> reserved4.value,
         buySideFirmId               |-> buySideFirmId.value,
         buySidePartyRole            |-> buySidePartyRole.value,
         buyMiFidFlags               |-> buyMiFidFlags.value,
         buyClientId                 |-> buyClientId.value,
         buyInvestmentDecisionMaker  |-> buyInvestmentDecisionMaker.value,
         buyExecutingTrader          |-> buyExecutingTrader.value,
         buyPartyRoleQualifiers      |-> buyPartyRoleQualifiers.value,
         sellSideClOrdId             |-> sellSideClOrdId.value,
         sellSideOrderCapacity       |-> sellSideOrderCapacity.value,
         sellSideClearingAccount     |-> sellSideClearingAccount.value,
         sellSideOrderQuantity       |-> sellSideOrderQuantity.value,
         secondReserved4             |-> secondReserved4.value,
         sellSideFirmId              |-> sellSideFirmId.value,
         sellSidePartyRole           |-> sellSidePartyRole.value,
         sellMiFidFlags              |-> sellMiFidFlags.value,
         sellClientId                |-> sellClientId.value,
         sellInvestmentDecisionMaker |-> sellInvestmentDecisionMaker.value,
         sellExecutingTrader         |-> sellExecutingTrader.value,
         sellPartyRoleQualifiers     |-> sellPartyRoleQualifiers.value,
         mtfCommonSymbol             |-> mtfCommonSymbol.value,
         price                       |-> price.value,
         orderType                   |-> orderType.value,
         tif                         |-> tif.value ], tif.rest)

ZeroNewCrossBtfMessage ==
    [ crossId                     |-> [i \in 1 .. 20 |-> 0],
      crossType                   |-> [i \in 1 .. 1 |-> 0],
      buySideClOrdId              |-> [i \in 1 .. 20 |-> 0],
      buySideOrderCapacity        |-> [i \in 1 .. 1 |-> 0],
      buySideClearingAccount      |-> [i \in 1 .. 1 |-> 0],
      buySideOrderQuantity        |-> [i \in 1 .. 4 |-> 0],
      reserved4                   |-> [i \in 1 .. 4 |-> 0],
      buySideFirmId               |-> [i \in 1 .. 11 |-> 0],
      buySidePartyRole            |-> [i \in 1 .. 1 |-> 0],
      buyMiFidFlags               |-> [i \in 1 .. 1 |-> 0],
      buyClientId                 |-> [i \in 1 .. 4 |-> 0],
      buyInvestmentDecisionMaker  |-> [i \in 1 .. 4 |-> 0],
      buyExecutingTrader          |-> [i \in 1 .. 4 |-> 0],
      buyPartyRoleQualifiers      |-> [i \in 1 .. 1 |-> 0],
      sellSideClOrdId             |-> [i \in 1 .. 20 |-> 0],
      sellSideOrderCapacity       |-> [i \in 1 .. 1 |-> 0],
      sellSideClearingAccount     |-> [i \in 1 .. 1 |-> 0],
      sellSideOrderQuantity       |-> [i \in 1 .. 4 |-> 0],
      secondReserved4             |-> [i \in 1 .. 4 |-> 0],
      sellSideFirmId              |-> [i \in 1 .. 11 |-> 0],
      sellSidePartyRole           |-> [i \in 1 .. 1 |-> 0],
      sellMiFidFlags              |-> [i \in 1 .. 1 |-> 0],
      sellClientId                |-> [i \in 1 .. 4 |-> 0],
      sellInvestmentDecisionMaker |-> [i \in 1 .. 4 |-> 0],
      sellExecutingTrader         |-> [i \in 1 .. 4 |-> 0],
      sellPartyRoleQualifiers     |-> [i \in 1 .. 1 |-> 0],
      mtfCommonSymbol             |-> [i \in 1 .. 8 |-> 0],
      price                       |-> [i \in 1 .. 8 |-> 0],
      orderType                   |-> [i \in 1 .. 1 |-> 0],
      tif                         |-> [i \in 1 .. 1 |-> 0] ]

(* New Cross Btf Message at zero, then each field in turn at the values it is checked at *)
CheckedNewCrossBtfMessage ==
    { ZeroNewCrossBtfMessage }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.crossId = one] : one \in Sample(20) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.buySideClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.buySideOrderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.buySideClearingAccount = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.buySideOrderQuantity = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.buySideFirmId = one] : one \in Sample(11) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.buySidePartyRole = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.buyMiFidFlags = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.buyClientId = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.buyInvestmentDecisionMaker = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.buyExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.buyPartyRoleQualifiers = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.sellSideClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.sellSideOrderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.sellSideClearingAccount = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.sellSideOrderQuantity = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.secondReserved4 = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.sellSideFirmId = one] : one \in Sample(11) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.sellSidePartyRole = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.sellMiFidFlags = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.sellClientId = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.sellInvestmentDecisionMaker = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.sellExecutingTrader = one] : one \in Sample(4) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.sellPartyRoleQualifiers = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.mtfCommonSymbol = one] : one \in Sample(8) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.orderType = one] : one \in Sample(1) }
        \cup { [ZeroNewCrossBtfMessage EXCEPT !.tif = one] : one \in Sample(1) }

(***************************************************************************)
(* Cross Btf Cancel Request Message: 125 bytes                             *)
(***************************************************************************)

CrossBtfCancelRequestMessage ==
    [ crossId                 : Sample(20),
      originalCrossId         : Sample(20),
      crossType               : Sample(1),
      buySideOriginalClOrdId  : Sample(20),
      buySideOrderQuantity    : Sample(4),
      reserved4               : Sample(4),
      sellSideOriginalClOrdId : Sample(20),
      sellSideOrderQuantity   : Sample(4),
      secondReserved4         : Sample(4),
      mtfCommonSymbol         : Sample(8),
      clientOrderId           : Sample(20) ]

EncodeCrossBtfCancelRequestMessage(message) ==
    message.crossId
        \o message.originalCrossId
        \o message.crossType
        \o message.buySideOriginalClOrdId
        \o message.buySideOrderQuantity
        \o message.reserved4
        \o message.sellSideOriginalClOrdId
        \o message.sellSideOrderQuantity
        \o message.secondReserved4
        \o message.mtfCommonSymbol
        \o message.clientOrderId

DecodeCrossBtfCancelRequestMessage(bytes) ==
    LET crossId == ReadBytes(bytes, 20) IN IF ~crossId.ok THEN Fail ELSE
    LET originalCrossId == ReadBytes(crossId.rest, 20) IN IF ~originalCrossId.ok THEN Fail ELSE
    LET crossType == ReadBytes(originalCrossId.rest, 1) IN IF ~crossType.ok THEN Fail ELSE
    LET buySideOriginalClOrdId == ReadBytes(crossType.rest, 20) IN IF ~buySideOriginalClOrdId.ok THEN Fail ELSE
    LET buySideOrderQuantity == ReadBytes(buySideOriginalClOrdId.rest, 4) IN IF ~buySideOrderQuantity.ok THEN Fail ELSE
    LET reserved4 == ReadBytes(buySideOrderQuantity.rest, 4) IN IF ~reserved4.ok THEN Fail ELSE
    LET sellSideOriginalClOrdId == ReadBytes(reserved4.rest, 20) IN IF ~sellSideOriginalClOrdId.ok THEN Fail ELSE
    LET sellSideOrderQuantity == ReadBytes(sellSideOriginalClOrdId.rest, 4) IN IF ~sellSideOrderQuantity.ok THEN Fail ELSE
    LET secondReserved4 == ReadBytes(sellSideOrderQuantity.rest, 4) IN IF ~secondReserved4.ok THEN Fail ELSE
    LET mtfCommonSymbol == ReadBytes(secondReserved4.rest, 8) IN IF ~mtfCommonSymbol.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(mtfCommonSymbol.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    Ok([ crossId                 |-> crossId.value,
         originalCrossId         |-> originalCrossId.value,
         crossType               |-> crossType.value,
         buySideOriginalClOrdId  |-> buySideOriginalClOrdId.value,
         buySideOrderQuantity    |-> buySideOrderQuantity.value,
         reserved4               |-> reserved4.value,
         sellSideOriginalClOrdId |-> sellSideOriginalClOrdId.value,
         sellSideOrderQuantity   |-> sellSideOrderQuantity.value,
         secondReserved4         |-> secondReserved4.value,
         mtfCommonSymbol         |-> mtfCommonSymbol.value,
         clientOrderId           |-> clientOrderId.value ], clientOrderId.rest)

ZeroCrossBtfCancelRequestMessage ==
    [ crossId                 |-> [i \in 1 .. 20 |-> 0],
      originalCrossId         |-> [i \in 1 .. 20 |-> 0],
      crossType               |-> [i \in 1 .. 1 |-> 0],
      buySideOriginalClOrdId  |-> [i \in 1 .. 20 |-> 0],
      buySideOrderQuantity    |-> [i \in 1 .. 4 |-> 0],
      reserved4               |-> [i \in 1 .. 4 |-> 0],
      sellSideOriginalClOrdId |-> [i \in 1 .. 20 |-> 0],
      sellSideOrderQuantity   |-> [i \in 1 .. 4 |-> 0],
      secondReserved4         |-> [i \in 1 .. 4 |-> 0],
      mtfCommonSymbol         |-> [i \in 1 .. 8 |-> 0],
      clientOrderId           |-> [i \in 1 .. 20 |-> 0] ]

(* Cross Btf Cancel Request Message at zero, then each field in turn at the values it is checked at *)
CheckedCrossBtfCancelRequestMessage ==
    { ZeroCrossBtfCancelRequestMessage }
        \cup { [ZeroCrossBtfCancelRequestMessage EXCEPT !.crossId = one] : one \in Sample(20) }
        \cup { [ZeroCrossBtfCancelRequestMessage EXCEPT !.originalCrossId = one] : one \in Sample(20) }
        \cup { [ZeroCrossBtfCancelRequestMessage EXCEPT !.crossType = one] : one \in Sample(1) }
        \cup { [ZeroCrossBtfCancelRequestMessage EXCEPT !.buySideOriginalClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCrossBtfCancelRequestMessage EXCEPT !.buySideOrderQuantity = one] : one \in Sample(4) }
        \cup { [ZeroCrossBtfCancelRequestMessage EXCEPT !.reserved4 = one] : one \in Sample(4) }
        \cup { [ZeroCrossBtfCancelRequestMessage EXCEPT !.sellSideOriginalClOrdId = one] : one \in Sample(20) }
        \cup { [ZeroCrossBtfCancelRequestMessage EXCEPT !.sellSideOrderQuantity = one] : one \in Sample(4) }
        \cup { [ZeroCrossBtfCancelRequestMessage EXCEPT !.secondReserved4 = one] : one \in Sample(4) }
        \cup { [ZeroCrossBtfCancelRequestMessage EXCEPT !.mtfCommonSymbol = one] : one \in Sample(8) }
        \cup { [ZeroCrossBtfCancelRequestMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }

(***************************************************************************)
(* Transact Time: 8 bytes                                                  *)
(***************************************************************************)

TransactTime4 ==
    [ seconds     : Sample(4),
      nanoseconds : Sample(4) ]

EncodeTransactTime4(message) ==
    message.seconds
        \o message.nanoseconds

DecodeTransactTime4(bytes) ==
    LET seconds == ReadBytes(bytes, 4) IN IF ~seconds.ok THEN Fail ELSE
    LET nanoseconds == ReadBytes(seconds.rest, 4) IN IF ~nanoseconds.ok THEN Fail ELSE
    Ok([ seconds     |-> seconds.value,
         nanoseconds |-> nanoseconds.value ], nanoseconds.rest)

ZeroTransactTime4 ==
    [ seconds     |-> [i \in 1 .. 4 |-> 0],
      nanoseconds |-> [i \in 1 .. 4 |-> 0] ]

(* Transact Time at zero, then each field in turn at the values it is checked at *)
CheckedTransactTime4 ==
    { ZeroTransactTime4 }
        \cup { [ZeroTransactTime4 EXCEPT !.seconds = one] : one \in Sample(4) }
        \cup { [ZeroTransactTime4 EXCEPT !.nanoseconds = one] : one \in Sample(4) }

(***************************************************************************)
(* Business Reject Message: 59 bytes                                       *)
(***************************************************************************)

BusinessRejectMessage ==
    [ appId         : Sample(1),
      sequenceNo    : Sample(4),
      rejectCode    : Sample(4),
      clientOrderId : Sample(20),
      orderId       : Sample(12),
      transactTime  : TransactTime4,
      reserved10    : Sample(10) ]

EncodeBusinessRejectMessage(message) ==
    message.appId
        \o message.sequenceNo
        \o message.rejectCode
        \o message.clientOrderId
        \o message.orderId
        \o EncodeTransactTime4(message.transactTime)
        \o message.reserved10

DecodeBusinessRejectMessage(bytes) ==
    LET appId == ReadBytes(bytes, 1) IN IF ~appId.ok THEN Fail ELSE
    LET sequenceNo == ReadBytes(appId.rest, 4) IN IF ~sequenceNo.ok THEN Fail ELSE
    LET rejectCode == ReadBytes(sequenceNo.rest, 4) IN IF ~rejectCode.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(rejectCode.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(clientOrderId.rest, 12) IN IF ~orderId.ok THEN Fail ELSE
    LET transactTime == DecodeTransactTime4(orderId.rest) IN IF ~transactTime.ok THEN Fail ELSE
    LET reserved10 == ReadBytes(transactTime.rest, 10) IN IF ~reserved10.ok THEN Fail ELSE
    Ok([ appId         |-> appId.value,
         sequenceNo    |-> sequenceNo.value,
         rejectCode    |-> rejectCode.value,
         clientOrderId |-> clientOrderId.value,
         orderId       |-> orderId.value,
         transactTime  |-> transactTime.value,
         reserved10    |-> reserved10.value ], reserved10.rest)

ZeroBusinessRejectMessage ==
    [ appId         |-> [i \in 1 .. 1 |-> 0],
      sequenceNo    |-> [i \in 1 .. 4 |-> 0],
      rejectCode    |-> [i \in 1 .. 4 |-> 0],
      clientOrderId |-> [i \in 1 .. 20 |-> 0],
      orderId       |-> [i \in 1 .. 12 |-> 0],
      transactTime  |-> ZeroTransactTime4,
      reserved10    |-> [i \in 1 .. 10 |-> 0] ]

(* Business Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedBusinessRejectMessage ==
    { ZeroBusinessRejectMessage }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.appId = one] : one \in Sample(1) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.sequenceNo = one] : one \in Sample(4) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.rejectCode = one] : one \in Sample(4) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.orderId = one] : one \in Sample(12) }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.transactTime = one] : one \in CheckedTransactTime4 }
        \cup { [ZeroBusinessRejectMessage EXCEPT !.reserved10 = one] : one \in Sample(10) }

(***************************************************************************)
(* Payload, selected by Message Type                                       *)
(***************************************************************************)

LogonMessageCode == 65  \* "A"
LogonReplyMessageCode == 66  \* "B"
LogoutMessageCode == 53  \* "5"
HeartbeatMessageCode == 48  \* "0"
RejectMessageCode == 51  \* "3"
NewOrderMessageCode == 68  \* "D"
OrderCancelReplaceRequestMessageCode == 71  \* "G"
OrderCancelRequestMessageCode == 70  \* "F"
OrderMassCancelRequestMessageCode == 113  \* "q"
ExecutionReportMessageCode == 56  \* "8"
OrderCancelRejectMessageCode == 57  \* "9"
OrderMassCancelReportMessageCode == 114  \* "r"
NewCrossBtfMessageCode == 67  \* "C"
CrossBtfCancelRequestMessageCode == 72  \* "H"
BusinessRejectMessageCode == 106  \* "j"

Payload ==
    [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogonReplyMessageCode}, body : LogonReplyMessage ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {HeartbeatMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RejectMessageCode}, body : RejectMessage ]
        \cup [ tag : {NewOrderMessageCode}, body : NewOrderMessage ]
        \cup [ tag : {OrderCancelReplaceRequestMessageCode}, body : OrderCancelReplaceRequestMessage ]
        \cup [ tag : {OrderCancelRequestMessageCode}, body : OrderCancelRequestMessage ]
        \cup [ tag : {OrderMassCancelRequestMessageCode}, body : OrderMassCancelRequestMessage ]
        \cup [ tag : {ExecutionReportMessageCode}, body : ExecutionReportMessage ]
        \cup [ tag : {OrderCancelRejectMessageCode}, body : OrderCancelRejectMessage ]
        \cup [ tag : {OrderMassCancelReportMessageCode}, body : OrderMassCancelReportMessage ]
        \cup [ tag : {NewCrossBtfMessageCode}, body : NewCrossBtfMessage ]
        \cup [ tag : {CrossBtfCancelRequestMessageCode}, body : CrossBtfCancelRequestMessage ]
        \cup [ tag : {BusinessRejectMessageCode}, body : BusinessRejectMessage ]

EncodePayload(message) ==
    CASE message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogonReplyMessageCode -> EncodeLogonReplyMessage(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = HeartbeatMessageCode -> << >>
      [] message.tag = RejectMessageCode -> EncodeRejectMessage(message.body)
      [] message.tag = NewOrderMessageCode -> EncodeNewOrderMessage(message.body)
      [] message.tag = OrderCancelReplaceRequestMessageCode -> EncodeOrderCancelReplaceRequestMessage(message.body)
      [] message.tag = OrderCancelRequestMessageCode -> EncodeOrderCancelRequestMessage(message.body)
      [] message.tag = OrderMassCancelRequestMessageCode -> EncodeOrderMassCancelRequestMessage(message.body)
      [] message.tag = ExecutionReportMessageCode -> EncodeExecutionReportMessage(message.body)
      [] message.tag = OrderCancelRejectMessageCode -> EncodeOrderCancelRejectMessage(message.body)
      [] message.tag = OrderMassCancelReportMessageCode -> EncodeOrderMassCancelReportMessage(message.body)
      [] message.tag = NewCrossBtfMessageCode -> EncodeNewCrossBtfMessage(message.body)
      [] message.tag = CrossBtfCancelRequestMessageCode -> EncodeCrossBtfCancelRequestMessage(message.body)
      [] message.tag = BusinessRejectMessageCode -> EncodeBusinessRejectMessage(message.body)

DecodePayload(tag, bytes) ==
    LET read ==
            CASE tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogonReplyMessageCode -> DecodeLogonReplyMessage(bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = HeartbeatMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = RejectMessageCode -> DecodeRejectMessage(bytes)
              [] tag = NewOrderMessageCode -> DecodeNewOrderMessage(bytes)
              [] tag = OrderCancelReplaceRequestMessageCode -> DecodeOrderCancelReplaceRequestMessage(bytes)
              [] tag = OrderCancelRequestMessageCode -> DecodeOrderCancelRequestMessage(bytes)
              [] tag = OrderMassCancelRequestMessageCode -> DecodeOrderMassCancelRequestMessage(bytes)
              [] tag = ExecutionReportMessageCode -> DecodeExecutionReportMessage(bytes)
              [] tag = OrderCancelRejectMessageCode -> DecodeOrderCancelRejectMessage(bytes)
              [] tag = OrderMassCancelReportMessageCode -> DecodeOrderMassCancelReportMessage(bytes)
              [] tag = NewCrossBtfMessageCode -> DecodeNewCrossBtfMessage(bytes)
              [] tag = CrossBtfCancelRequestMessageCode -> DecodeCrossBtfCancelRequestMessage(bytes)
              [] tag = BusinessRejectMessageCode -> DecodeBusinessRejectMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroPayload == [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]

(* Each Payload in turn, at the values the message it names is checked at *)
CheckedPayload ==
    { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogonReplyMessageCode, body |-> one] : one \in CheckedLogonReplyMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RejectMessageCode, body |-> one] : one \in CheckedRejectMessage }
        \cup { [tag |-> NewOrderMessageCode, body |-> one] : one \in CheckedNewOrderMessage }
        \cup { [tag |-> OrderCancelReplaceRequestMessageCode, body |-> one] : one \in CheckedOrderCancelReplaceRequestMessage }
        \cup { [tag |-> OrderCancelRequestMessageCode, body |-> one] : one \in CheckedOrderCancelRequestMessage }
        \cup { [tag |-> OrderMassCancelRequestMessageCode, body |-> one] : one \in CheckedOrderMassCancelRequestMessage }
        \cup { [tag |-> ExecutionReportMessageCode, body |-> one] : one \in CheckedExecutionReportMessage }
        \cup { [tag |-> OrderCancelRejectMessageCode, body |-> one] : one \in CheckedOrderCancelRejectMessage }
        \cup { [tag |-> OrderMassCancelReportMessageCode, body |-> one] : one \in CheckedOrderMassCancelReportMessage }
        \cup { [tag |-> NewCrossBtfMessageCode, body |-> one] : one \in CheckedNewCrossBtfMessage }
        \cup { [tag |-> CrossBtfCancelRequestMessageCode, body |-> one] : one \in CheckedCrossBtfCancelRequestMessage }
        \cup { [tag |-> BusinessRejectMessageCode, body |-> one] : one \in CheckedBusinessRejectMessage }

(***************************************************************************)
(* Message, framed by Message Length                                       *)
(***************************************************************************)

Message ==
    [ startOfMessage : Sample(1),
      payload        : Payload ]

EncodeMessageBody(message) ==
    EncodeUIntBE(message.payload.tag, 1)
        \o EncodePayload(message.payload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeMessage(message) ==
    LET body == EncodeMessageBody(message)
    IN  message.startOfMessage \o EncodeUIntLE(Len(body), 2) \o body

DecodeMessage(bytes) ==
    LET startOfMessage == ReadBytes(bytes, 1) IN IF ~startOfMessage.ok THEN Fail ELSE
    LET length == ReadUIntLE(startOfMessage.rest, 2) IN IF ~length.ok THEN Fail ELSE
    IF Len(length.rest) < length.value THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, length.value)
        beyond == SubSeq(length.rest, length.value + 1, Len(length.rest))
    IN
    LET messageType == ReadUIntBE(framed, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET payload == DecodePayload(messageType.value, messageType.rest) IN IF ~payload.ok THEN Fail ELSE
    IF payload.rest # << >> THEN Fail ELSE
    Ok([ startOfMessage |-> startOfMessage.value,
         payload        |-> payload.value ], beyond)

ZeroMessage ==
    [ startOfMessage |-> [i \in 1 .. 1 |-> 0],
      payload        |-> ZeroPayload ]

(* Message at zero, then each field in turn at the values it is checked at *)
CheckedMessage ==
    { ZeroMessage }
        \cup { [ZeroMessage EXCEPT !.startOfMessage = one] : one \in Sample(1) }
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
    { [ZeroMessage EXCEPT !.payload = [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogonReplyMessageCode, body |-> ZeroLogonReplyMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> LogoutMessageCode, body |-> ZeroLogoutMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> HeartbeatMessageCode, body |-> [empty |-> 0]]],
      [ZeroMessage EXCEPT !.payload = [tag |-> RejectMessageCode, body |-> ZeroRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewOrderMessageCode, body |-> ZeroNewOrderMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelReplaceRequestMessageCode, body |-> ZeroOrderCancelReplaceRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelRequestMessageCode, body |-> ZeroOrderCancelRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderMassCancelRequestMessageCode, body |-> ZeroOrderMassCancelRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> ExecutionReportMessageCode, body |-> ZeroExecutionReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderCancelRejectMessageCode, body |-> ZeroOrderCancelRejectMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> OrderMassCancelReportMessageCode, body |-> ZeroOrderMassCancelReportMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> NewCrossBtfMessageCode, body |-> ZeroNewCrossBtfMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> CrossBtfCancelRequestMessageCode, body |-> ZeroCrossBtfCancelRequestMessage]],
      [ZeroMessage EXCEPT !.payload = [tag |-> BusinessRejectMessageCode, body |-> ZeroBusinessRejectMessage]] }

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

(* Every Logon Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonMessage ==
    \A message \in CheckedLogonMessage :
        LET read == DecodeLogonMessage(EncodeLogonMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Logon Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogonReplyMessage ==
    \A message \in CheckedLogonReplyMessage :
        LET read == DecodeLogonReplyMessage(EncodeLogonReplyMessage(message))
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

(* Every Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripRejectMessage ==
    \A message \in CheckedRejectMessage :
        LET read == DecodeRejectMessage(EncodeRejectMessage(message))
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

(* Every Order Cancel Replace Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelReplaceRequestMessage ==
    \A message \in CheckedOrderCancelReplaceRequestMessage :
        LET read == DecodeOrderCancelReplaceRequestMessage(EncodeOrderCancelReplaceRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelRequestMessage ==
    \A message \in CheckedOrderCancelRequestMessage :
        LET read == DecodeOrderCancelRequestMessage(EncodeOrderCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassCancelRequestMessage ==
    \A message \in CheckedOrderMassCancelRequestMessage :
        LET read == DecodeOrderMassCancelRequestMessage(EncodeOrderMassCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTime ==
    \A message \in CheckedTransactTime :
        LET read == DecodeTransactTime(EncodeTransactTime(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionReportMessage ==
    \A message \in CheckedExecutionReportMessage :
        LET read == DecodeExecutionReportMessage(EncodeExecutionReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTime2 ==
    \A message \in CheckedTransactTime2 :
        LET read == DecodeTransactTime2(EncodeTransactTime2(message))
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

(* Every Transact Time decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTime3 ==
    \A message \in CheckedTransactTime3 :
        LET read == DecodeTransactTime3(EncodeTransactTime3(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Cancel Report Message decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassCancelReportMessage ==
    \A message \in CheckedOrderMassCancelReportMessage :
        LET read == DecodeOrderMassCancelReportMessage(EncodeOrderMassCancelReportMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Cross Btf Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewCrossBtfMessage ==
    \A message \in CheckedNewCrossBtfMessage :
        LET read == DecodeNewCrossBtfMessage(EncodeNewCrossBtfMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Cross Btf Cancel Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripCrossBtfCancelRequestMessage ==
    \A message \in CheckedCrossBtfCancelRequestMessage :
        LET read == DecodeCrossBtfCancelRequestMessage(EncodeCrossBtfCancelRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Transact Time decodes back to what was encoded, and leaves nothing over *)
RoundTripTransactTime4 ==
    \A message \in CheckedTransactTime4 :
        LET read == DecodeTransactTime4(EncodeTransactTime4(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Business Reject Message decodes back to what was encoded, and leaves nothing over *)
RoundTripBusinessRejectMessage ==
    \A message \in CheckedBusinessRejectMessage :
        LET read == DecodeBusinessRejectMessage(EncodeBusinessRejectMessage(message))
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
        LET sent == EncodePayload(message)
            read == DecodePayload(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesMessage ==
    \A message \in CheckedMessage :
        LET bytes == EncodeMessage(message)
        IN  DecodeUIntLE(SubSeq(bytes, 2, 3)) = Len(bytes) - 3

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
