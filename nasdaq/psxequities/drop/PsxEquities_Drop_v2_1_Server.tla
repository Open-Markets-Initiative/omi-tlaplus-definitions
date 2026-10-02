------------------- MODULE PsxEquities_Drop_v2_1_Server --------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Drop v2.1                                                      *)
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
(* Debug Packet: 1 bytes                                                   *)
(***************************************************************************)

DebugPacket ==
    [ text : Sample(1) ]

EncodeDebugPacket(message) ==
    message.text

DecodeDebugPacket(bytes) ==
    LET text == ReadBytes(bytes, 1) IN IF ~text.ok THEN Fail ELSE
    Ok([ text |-> text.value ], text.rest)

ZeroDebugPacket ==
    [ text |-> [i \in 1 .. 1 |-> 0] ]

(* Debug Packet at zero, then each field in turn at the values it is checked at *)
CheckedDebugPacket ==
    { ZeroDebugPacket }
        \cup { [ZeroDebugPacket EXCEPT !.text = one] : one \in Sample(1) }

(***************************************************************************)
(* Login Accepted Packet: 30 bytes                                         *)
(***************************************************************************)

LoginAcceptedPacket ==
    [ session        : Sample(10),
      sequenceNumber : Sample(20) ]

EncodeLoginAcceptedPacket(message) ==
    message.session
        \o message.sequenceNumber

DecodeLoginAcceptedPacket(bytes) ==
    LET session == ReadBytes(bytes, 10) IN IF ~session.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(session.rest, 20) IN IF ~sequenceNumber.ok THEN Fail ELSE
    Ok([ session        |-> session.value,
         sequenceNumber |-> sequenceNumber.value ], sequenceNumber.rest)

ZeroLoginAcceptedPacket ==
    [ session        |-> [i \in 1 .. 10 |-> 0],
      sequenceNumber |-> [i \in 1 .. 20 |-> 0] ]

(* Login Accepted Packet at zero, then each field in turn at the values it is checked at *)
CheckedLoginAcceptedPacket ==
    { ZeroLoginAcceptedPacket }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.session = one] : one \in Sample(10) }
        \cup { [ZeroLoginAcceptedPacket EXCEPT !.sequenceNumber = one] : one \in Sample(20) }

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
(* New Order Accepted Message: 99 bytes                                    *)
(***************************************************************************)

NewOrderAcceptedMessage ==
    [ separator1    : Sample(1),
      source        : Sample(6),
      separator2    : Sample(1),
      user          : Sample(4),
      separator3    : Sample(1),
      token         : Sample(10),
      separator4    : Sample(1),
      replacedToken : Sample(10),
      separator5    : Sample(1),
      buySell       : Sample(1),
      separator6    : Sample(1),
      shares        : Sample(6),
      separator7    : Sample(1),
      stock         : Sample(6),
      separator8    : Sample(1),
      price         : Sample(11),
      separator9    : Sample(1),
      firm          : Sample(4),
      separator10   : Sample(1),
      reference     : Sample(12),
      separator11   : Sample(1),
      timeInForce   : Sample(12),
      separator12   : Sample(1),
      capacity      : Sample(1),
      separator13   : Sample(1),
      liquidityFlag : Sample(1),
      separator14   : Sample(1),
      clearingCode  : Sample(1) ]

EncodeNewOrderAcceptedMessage(message) ==
    message.separator1
        \o message.source
        \o message.separator2
        \o message.user
        \o message.separator3
        \o message.token
        \o message.separator4
        \o message.replacedToken
        \o message.separator5
        \o message.buySell
        \o message.separator6
        \o message.shares
        \o message.separator7
        \o message.stock
        \o message.separator8
        \o message.price
        \o message.separator9
        \o message.firm
        \o message.separator10
        \o message.reference
        \o message.separator11
        \o message.timeInForce
        \o message.separator12
        \o message.capacity
        \o message.separator13
        \o message.liquidityFlag
        \o message.separator14
        \o message.clearingCode

DecodeNewOrderAcceptedMessage(bytes) ==
    LET separator1 == ReadBytes(bytes, 1) IN IF ~separator1.ok THEN Fail ELSE
    LET source == ReadBytes(separator1.rest, 6) IN IF ~source.ok THEN Fail ELSE
    LET separator2 == ReadBytes(source.rest, 1) IN IF ~separator2.ok THEN Fail ELSE
    LET user == ReadBytes(separator2.rest, 4) IN IF ~user.ok THEN Fail ELSE
    LET separator3 == ReadBytes(user.rest, 1) IN IF ~separator3.ok THEN Fail ELSE
    LET token == ReadBytes(separator3.rest, 10) IN IF ~token.ok THEN Fail ELSE
    LET separator4 == ReadBytes(token.rest, 1) IN IF ~separator4.ok THEN Fail ELSE
    LET replacedToken == ReadBytes(separator4.rest, 10) IN IF ~replacedToken.ok THEN Fail ELSE
    LET separator5 == ReadBytes(replacedToken.rest, 1) IN IF ~separator5.ok THEN Fail ELSE
    LET buySell == ReadBytes(separator5.rest, 1) IN IF ~buySell.ok THEN Fail ELSE
    LET separator6 == ReadBytes(buySell.rest, 1) IN IF ~separator6.ok THEN Fail ELSE
    LET shares == ReadBytes(separator6.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    LET separator7 == ReadBytes(shares.rest, 1) IN IF ~separator7.ok THEN Fail ELSE
    LET stock == ReadBytes(separator7.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET separator8 == ReadBytes(stock.rest, 1) IN IF ~separator8.ok THEN Fail ELSE
    LET price == ReadBytes(separator8.rest, 11) IN IF ~price.ok THEN Fail ELSE
    LET separator9 == ReadBytes(price.rest, 1) IN IF ~separator9.ok THEN Fail ELSE
    LET firm == ReadBytes(separator9.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET separator10 == ReadBytes(firm.rest, 1) IN IF ~separator10.ok THEN Fail ELSE
    LET reference == ReadBytes(separator10.rest, 12) IN IF ~reference.ok THEN Fail ELSE
    LET separator11 == ReadBytes(reference.rest, 1) IN IF ~separator11.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(separator11.rest, 12) IN IF ~timeInForce.ok THEN Fail ELSE
    LET separator12 == ReadBytes(timeInForce.rest, 1) IN IF ~separator12.ok THEN Fail ELSE
    LET capacity == ReadBytes(separator12.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET separator13 == ReadBytes(capacity.rest, 1) IN IF ~separator13.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(separator13.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET separator14 == ReadBytes(liquidityFlag.rest, 1) IN IF ~separator14.ok THEN Fail ELSE
    LET clearingCode == ReadBytes(separator14.rest, 1) IN IF ~clearingCode.ok THEN Fail ELSE
    Ok([ separator1    |-> separator1.value,
         source        |-> source.value,
         separator2    |-> separator2.value,
         user          |-> user.value,
         separator3    |-> separator3.value,
         token         |-> token.value,
         separator4    |-> separator4.value,
         replacedToken |-> replacedToken.value,
         separator5    |-> separator5.value,
         buySell       |-> buySell.value,
         separator6    |-> separator6.value,
         shares        |-> shares.value,
         separator7    |-> separator7.value,
         stock         |-> stock.value,
         separator8    |-> separator8.value,
         price         |-> price.value,
         separator9    |-> separator9.value,
         firm          |-> firm.value,
         separator10   |-> separator10.value,
         reference     |-> reference.value,
         separator11   |-> separator11.value,
         timeInForce   |-> timeInForce.value,
         separator12   |-> separator12.value,
         capacity      |-> capacity.value,
         separator13   |-> separator13.value,
         liquidityFlag |-> liquidityFlag.value,
         separator14   |-> separator14.value,
         clearingCode  |-> clearingCode.value ], clearingCode.rest)

ZeroNewOrderAcceptedMessage ==
    [ separator1    |-> [i \in 1 .. 1 |-> 0],
      source        |-> [i \in 1 .. 6 |-> 0],
      separator2    |-> [i \in 1 .. 1 |-> 0],
      user          |-> [i \in 1 .. 4 |-> 0],
      separator3    |-> [i \in 1 .. 1 |-> 0],
      token         |-> [i \in 1 .. 10 |-> 0],
      separator4    |-> [i \in 1 .. 1 |-> 0],
      replacedToken |-> [i \in 1 .. 10 |-> 0],
      separator5    |-> [i \in 1 .. 1 |-> 0],
      buySell       |-> [i \in 1 .. 1 |-> 0],
      separator6    |-> [i \in 1 .. 1 |-> 0],
      shares        |-> [i \in 1 .. 6 |-> 0],
      separator7    |-> [i \in 1 .. 1 |-> 0],
      stock         |-> [i \in 1 .. 6 |-> 0],
      separator8    |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 11 |-> 0],
      separator9    |-> [i \in 1 .. 1 |-> 0],
      firm          |-> [i \in 1 .. 4 |-> 0],
      separator10   |-> [i \in 1 .. 1 |-> 0],
      reference     |-> [i \in 1 .. 12 |-> 0],
      separator11   |-> [i \in 1 .. 1 |-> 0],
      timeInForce   |-> [i \in 1 .. 12 |-> 0],
      separator12   |-> [i \in 1 .. 1 |-> 0],
      capacity      |-> [i \in 1 .. 1 |-> 0],
      separator13   |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag |-> [i \in 1 .. 1 |-> 0],
      separator14   |-> [i \in 1 .. 1 |-> 0],
      clearingCode  |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderAcceptedMessage ==
    { ZeroNewOrderAcceptedMessage }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator1 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.source = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator2 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.user = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator3 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.token = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator4 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.replacedToken = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator5 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.buySell = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator6 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.shares = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator7 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator8 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.price = one] : one \in Sample(11) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator9 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator10 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.reference = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator11 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.timeInForce = one] : one \in Sample(12) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator12 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator13 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator14 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.clearingCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Existing Order Executed Message: 99 bytes                               *)
(***************************************************************************)

ExistingOrderExecutedMessage ==
    [ separator1    : Sample(1),
      source        : Sample(6),
      separator2    : Sample(1),
      user          : Sample(4),
      separator3    : Sample(1),
      token         : Sample(10),
      separator4    : Sample(1),
      replacedToken : Sample(10),
      separator5    : Sample(1),
      buySell       : Sample(1),
      separator6    : Sample(1),
      shares        : Sample(6),
      separator7    : Sample(1),
      stock         : Sample(6),
      separator8    : Sample(1),
      price         : Sample(11),
      separator9    : Sample(1),
      firm          : Sample(4),
      separator10   : Sample(1),
      reference     : Sample(12),
      separator11   : Sample(1),
      matchNumber   : Sample(12),
      separator12   : Sample(1),
      capacity      : Sample(1),
      separator13   : Sample(1),
      liquidityFlag : Sample(1),
      separator14   : Sample(1),
      clearingCode  : Sample(1) ]

EncodeExistingOrderExecutedMessage(message) ==
    message.separator1
        \o message.source
        \o message.separator2
        \o message.user
        \o message.separator3
        \o message.token
        \o message.separator4
        \o message.replacedToken
        \o message.separator5
        \o message.buySell
        \o message.separator6
        \o message.shares
        \o message.separator7
        \o message.stock
        \o message.separator8
        \o message.price
        \o message.separator9
        \o message.firm
        \o message.separator10
        \o message.reference
        \o message.separator11
        \o message.matchNumber
        \o message.separator12
        \o message.capacity
        \o message.separator13
        \o message.liquidityFlag
        \o message.separator14
        \o message.clearingCode

DecodeExistingOrderExecutedMessage(bytes) ==
    LET separator1 == ReadBytes(bytes, 1) IN IF ~separator1.ok THEN Fail ELSE
    LET source == ReadBytes(separator1.rest, 6) IN IF ~source.ok THEN Fail ELSE
    LET separator2 == ReadBytes(source.rest, 1) IN IF ~separator2.ok THEN Fail ELSE
    LET user == ReadBytes(separator2.rest, 4) IN IF ~user.ok THEN Fail ELSE
    LET separator3 == ReadBytes(user.rest, 1) IN IF ~separator3.ok THEN Fail ELSE
    LET token == ReadBytes(separator3.rest, 10) IN IF ~token.ok THEN Fail ELSE
    LET separator4 == ReadBytes(token.rest, 1) IN IF ~separator4.ok THEN Fail ELSE
    LET replacedToken == ReadBytes(separator4.rest, 10) IN IF ~replacedToken.ok THEN Fail ELSE
    LET separator5 == ReadBytes(replacedToken.rest, 1) IN IF ~separator5.ok THEN Fail ELSE
    LET buySell == ReadBytes(separator5.rest, 1) IN IF ~buySell.ok THEN Fail ELSE
    LET separator6 == ReadBytes(buySell.rest, 1) IN IF ~separator6.ok THEN Fail ELSE
    LET shares == ReadBytes(separator6.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    LET separator7 == ReadBytes(shares.rest, 1) IN IF ~separator7.ok THEN Fail ELSE
    LET stock == ReadBytes(separator7.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET separator8 == ReadBytes(stock.rest, 1) IN IF ~separator8.ok THEN Fail ELSE
    LET price == ReadBytes(separator8.rest, 11) IN IF ~price.ok THEN Fail ELSE
    LET separator9 == ReadBytes(price.rest, 1) IN IF ~separator9.ok THEN Fail ELSE
    LET firm == ReadBytes(separator9.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET separator10 == ReadBytes(firm.rest, 1) IN IF ~separator10.ok THEN Fail ELSE
    LET reference == ReadBytes(separator10.rest, 12) IN IF ~reference.ok THEN Fail ELSE
    LET separator11 == ReadBytes(reference.rest, 1) IN IF ~separator11.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(separator11.rest, 12) IN IF ~matchNumber.ok THEN Fail ELSE
    LET separator12 == ReadBytes(matchNumber.rest, 1) IN IF ~separator12.ok THEN Fail ELSE
    LET capacity == ReadBytes(separator12.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET separator13 == ReadBytes(capacity.rest, 1) IN IF ~separator13.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(separator13.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET separator14 == ReadBytes(liquidityFlag.rest, 1) IN IF ~separator14.ok THEN Fail ELSE
    LET clearingCode == ReadBytes(separator14.rest, 1) IN IF ~clearingCode.ok THEN Fail ELSE
    Ok([ separator1    |-> separator1.value,
         source        |-> source.value,
         separator2    |-> separator2.value,
         user          |-> user.value,
         separator3    |-> separator3.value,
         token         |-> token.value,
         separator4    |-> separator4.value,
         replacedToken |-> replacedToken.value,
         separator5    |-> separator5.value,
         buySell       |-> buySell.value,
         separator6    |-> separator6.value,
         shares        |-> shares.value,
         separator7    |-> separator7.value,
         stock         |-> stock.value,
         separator8    |-> separator8.value,
         price         |-> price.value,
         separator9    |-> separator9.value,
         firm          |-> firm.value,
         separator10   |-> separator10.value,
         reference     |-> reference.value,
         separator11   |-> separator11.value,
         matchNumber   |-> matchNumber.value,
         separator12   |-> separator12.value,
         capacity      |-> capacity.value,
         separator13   |-> separator13.value,
         liquidityFlag |-> liquidityFlag.value,
         separator14   |-> separator14.value,
         clearingCode  |-> clearingCode.value ], clearingCode.rest)

ZeroExistingOrderExecutedMessage ==
    [ separator1    |-> [i \in 1 .. 1 |-> 0],
      source        |-> [i \in 1 .. 6 |-> 0],
      separator2    |-> [i \in 1 .. 1 |-> 0],
      user          |-> [i \in 1 .. 4 |-> 0],
      separator3    |-> [i \in 1 .. 1 |-> 0],
      token         |-> [i \in 1 .. 10 |-> 0],
      separator4    |-> [i \in 1 .. 1 |-> 0],
      replacedToken |-> [i \in 1 .. 10 |-> 0],
      separator5    |-> [i \in 1 .. 1 |-> 0],
      buySell       |-> [i \in 1 .. 1 |-> 0],
      separator6    |-> [i \in 1 .. 1 |-> 0],
      shares        |-> [i \in 1 .. 6 |-> 0],
      separator7    |-> [i \in 1 .. 1 |-> 0],
      stock         |-> [i \in 1 .. 6 |-> 0],
      separator8    |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 11 |-> 0],
      separator9    |-> [i \in 1 .. 1 |-> 0],
      firm          |-> [i \in 1 .. 4 |-> 0],
      separator10   |-> [i \in 1 .. 1 |-> 0],
      reference     |-> [i \in 1 .. 12 |-> 0],
      separator11   |-> [i \in 1 .. 1 |-> 0],
      matchNumber   |-> [i \in 1 .. 12 |-> 0],
      separator12   |-> [i \in 1 .. 1 |-> 0],
      capacity      |-> [i \in 1 .. 1 |-> 0],
      separator13   |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag |-> [i \in 1 .. 1 |-> 0],
      separator14   |-> [i \in 1 .. 1 |-> 0],
      clearingCode  |-> [i \in 1 .. 1 |-> 0] ]

(* Existing Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedExistingOrderExecutedMessage ==
    { ZeroExistingOrderExecutedMessage }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator1 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.source = one] : one \in Sample(6) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator2 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.user = one] : one \in Sample(4) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator3 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.token = one] : one \in Sample(10) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator4 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.replacedToken = one] : one \in Sample(10) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator5 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.buySell = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator6 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.shares = one] : one \in Sample(6) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator7 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator8 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.price = one] : one \in Sample(11) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator9 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator10 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.reference = one] : one \in Sample(12) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator11 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(12) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator12 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator13 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator14 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.clearingCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Existing Order Canceled Message: 99 bytes                               *)
(***************************************************************************)

ExistingOrderCanceledMessage ==
    [ separator1    : Sample(1),
      source        : Sample(6),
      separator2    : Sample(1),
      user          : Sample(4),
      separator3    : Sample(1),
      token         : Sample(10),
      separator4    : Sample(1),
      replacedToken : Sample(10),
      separator5    : Sample(1),
      buySell       : Sample(1),
      separator6    : Sample(1),
      shares        : Sample(6),
      separator7    : Sample(1),
      stock         : Sample(6),
      separator8    : Sample(1),
      price         : Sample(11),
      separator9    : Sample(1),
      firm          : Sample(4),
      separator10   : Sample(1),
      reference     : Sample(12),
      separator11   : Sample(1),
      timeInForce   : Sample(12),
      separator12   : Sample(1),
      capacity      : Sample(1),
      separator13   : Sample(1),
      liquidityFlag : Sample(1),
      separator14   : Sample(1),
      clearingCode  : Sample(1) ]

EncodeExistingOrderCanceledMessage(message) ==
    message.separator1
        \o message.source
        \o message.separator2
        \o message.user
        \o message.separator3
        \o message.token
        \o message.separator4
        \o message.replacedToken
        \o message.separator5
        \o message.buySell
        \o message.separator6
        \o message.shares
        \o message.separator7
        \o message.stock
        \o message.separator8
        \o message.price
        \o message.separator9
        \o message.firm
        \o message.separator10
        \o message.reference
        \o message.separator11
        \o message.timeInForce
        \o message.separator12
        \o message.capacity
        \o message.separator13
        \o message.liquidityFlag
        \o message.separator14
        \o message.clearingCode

DecodeExistingOrderCanceledMessage(bytes) ==
    LET separator1 == ReadBytes(bytes, 1) IN IF ~separator1.ok THEN Fail ELSE
    LET source == ReadBytes(separator1.rest, 6) IN IF ~source.ok THEN Fail ELSE
    LET separator2 == ReadBytes(source.rest, 1) IN IF ~separator2.ok THEN Fail ELSE
    LET user == ReadBytes(separator2.rest, 4) IN IF ~user.ok THEN Fail ELSE
    LET separator3 == ReadBytes(user.rest, 1) IN IF ~separator3.ok THEN Fail ELSE
    LET token == ReadBytes(separator3.rest, 10) IN IF ~token.ok THEN Fail ELSE
    LET separator4 == ReadBytes(token.rest, 1) IN IF ~separator4.ok THEN Fail ELSE
    LET replacedToken == ReadBytes(separator4.rest, 10) IN IF ~replacedToken.ok THEN Fail ELSE
    LET separator5 == ReadBytes(replacedToken.rest, 1) IN IF ~separator5.ok THEN Fail ELSE
    LET buySell == ReadBytes(separator5.rest, 1) IN IF ~buySell.ok THEN Fail ELSE
    LET separator6 == ReadBytes(buySell.rest, 1) IN IF ~separator6.ok THEN Fail ELSE
    LET shares == ReadBytes(separator6.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    LET separator7 == ReadBytes(shares.rest, 1) IN IF ~separator7.ok THEN Fail ELSE
    LET stock == ReadBytes(separator7.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET separator8 == ReadBytes(stock.rest, 1) IN IF ~separator8.ok THEN Fail ELSE
    LET price == ReadBytes(separator8.rest, 11) IN IF ~price.ok THEN Fail ELSE
    LET separator9 == ReadBytes(price.rest, 1) IN IF ~separator9.ok THEN Fail ELSE
    LET firm == ReadBytes(separator9.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET separator10 == ReadBytes(firm.rest, 1) IN IF ~separator10.ok THEN Fail ELSE
    LET reference == ReadBytes(separator10.rest, 12) IN IF ~reference.ok THEN Fail ELSE
    LET separator11 == ReadBytes(reference.rest, 1) IN IF ~separator11.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(separator11.rest, 12) IN IF ~timeInForce.ok THEN Fail ELSE
    LET separator12 == ReadBytes(timeInForce.rest, 1) IN IF ~separator12.ok THEN Fail ELSE
    LET capacity == ReadBytes(separator12.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET separator13 == ReadBytes(capacity.rest, 1) IN IF ~separator13.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(separator13.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET separator14 == ReadBytes(liquidityFlag.rest, 1) IN IF ~separator14.ok THEN Fail ELSE
    LET clearingCode == ReadBytes(separator14.rest, 1) IN IF ~clearingCode.ok THEN Fail ELSE
    Ok([ separator1    |-> separator1.value,
         source        |-> source.value,
         separator2    |-> separator2.value,
         user          |-> user.value,
         separator3    |-> separator3.value,
         token         |-> token.value,
         separator4    |-> separator4.value,
         replacedToken |-> replacedToken.value,
         separator5    |-> separator5.value,
         buySell       |-> buySell.value,
         separator6    |-> separator6.value,
         shares        |-> shares.value,
         separator7    |-> separator7.value,
         stock         |-> stock.value,
         separator8    |-> separator8.value,
         price         |-> price.value,
         separator9    |-> separator9.value,
         firm          |-> firm.value,
         separator10   |-> separator10.value,
         reference     |-> reference.value,
         separator11   |-> separator11.value,
         timeInForce   |-> timeInForce.value,
         separator12   |-> separator12.value,
         capacity      |-> capacity.value,
         separator13   |-> separator13.value,
         liquidityFlag |-> liquidityFlag.value,
         separator14   |-> separator14.value,
         clearingCode  |-> clearingCode.value ], clearingCode.rest)

ZeroExistingOrderCanceledMessage ==
    [ separator1    |-> [i \in 1 .. 1 |-> 0],
      source        |-> [i \in 1 .. 6 |-> 0],
      separator2    |-> [i \in 1 .. 1 |-> 0],
      user          |-> [i \in 1 .. 4 |-> 0],
      separator3    |-> [i \in 1 .. 1 |-> 0],
      token         |-> [i \in 1 .. 10 |-> 0],
      separator4    |-> [i \in 1 .. 1 |-> 0],
      replacedToken |-> [i \in 1 .. 10 |-> 0],
      separator5    |-> [i \in 1 .. 1 |-> 0],
      buySell       |-> [i \in 1 .. 1 |-> 0],
      separator6    |-> [i \in 1 .. 1 |-> 0],
      shares        |-> [i \in 1 .. 6 |-> 0],
      separator7    |-> [i \in 1 .. 1 |-> 0],
      stock         |-> [i \in 1 .. 6 |-> 0],
      separator8    |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 11 |-> 0],
      separator9    |-> [i \in 1 .. 1 |-> 0],
      firm          |-> [i \in 1 .. 4 |-> 0],
      separator10   |-> [i \in 1 .. 1 |-> 0],
      reference     |-> [i \in 1 .. 12 |-> 0],
      separator11   |-> [i \in 1 .. 1 |-> 0],
      timeInForce   |-> [i \in 1 .. 12 |-> 0],
      separator12   |-> [i \in 1 .. 1 |-> 0],
      capacity      |-> [i \in 1 .. 1 |-> 0],
      separator13   |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag |-> [i \in 1 .. 1 |-> 0],
      separator14   |-> [i \in 1 .. 1 |-> 0],
      clearingCode  |-> [i \in 1 .. 1 |-> 0] ]

(* Existing Order Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedExistingOrderCanceledMessage ==
    { ZeroExistingOrderCanceledMessage }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator1 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.source = one] : one \in Sample(6) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator2 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.user = one] : one \in Sample(4) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator3 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.token = one] : one \in Sample(10) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator4 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.replacedToken = one] : one \in Sample(10) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator5 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.buySell = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator6 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.shares = one] : one \in Sample(6) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator7 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator8 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.price = one] : one \in Sample(11) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator9 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator10 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.reference = one] : one \in Sample(12) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator11 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.timeInForce = one] : one \in Sample(12) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator12 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator13 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator14 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.clearingCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Previous Execution Broken Message: 99 bytes                             *)
(***************************************************************************)

PreviousExecutionBrokenMessage ==
    [ separator1    : Sample(1),
      source        : Sample(6),
      separator2    : Sample(1),
      user          : Sample(4),
      separator3    : Sample(1),
      token         : Sample(10),
      separator4    : Sample(1),
      replacedToken : Sample(10),
      separator5    : Sample(1),
      buySell       : Sample(1),
      separator6    : Sample(1),
      shares        : Sample(6),
      separator7    : Sample(1),
      stock         : Sample(6),
      separator8    : Sample(1),
      price         : Sample(11),
      separator9    : Sample(1),
      firm          : Sample(4),
      separator10   : Sample(1),
      reference     : Sample(12),
      separator11   : Sample(1),
      matchNumber   : Sample(12),
      separator12   : Sample(1),
      capacity      : Sample(1),
      separator13   : Sample(1),
      liquidityFlag : Sample(1),
      separator14   : Sample(1),
      clearingCode  : Sample(1) ]

EncodePreviousExecutionBrokenMessage(message) ==
    message.separator1
        \o message.source
        \o message.separator2
        \o message.user
        \o message.separator3
        \o message.token
        \o message.separator4
        \o message.replacedToken
        \o message.separator5
        \o message.buySell
        \o message.separator6
        \o message.shares
        \o message.separator7
        \o message.stock
        \o message.separator8
        \o message.price
        \o message.separator9
        \o message.firm
        \o message.separator10
        \o message.reference
        \o message.separator11
        \o message.matchNumber
        \o message.separator12
        \o message.capacity
        \o message.separator13
        \o message.liquidityFlag
        \o message.separator14
        \o message.clearingCode

DecodePreviousExecutionBrokenMessage(bytes) ==
    LET separator1 == ReadBytes(bytes, 1) IN IF ~separator1.ok THEN Fail ELSE
    LET source == ReadBytes(separator1.rest, 6) IN IF ~source.ok THEN Fail ELSE
    LET separator2 == ReadBytes(source.rest, 1) IN IF ~separator2.ok THEN Fail ELSE
    LET user == ReadBytes(separator2.rest, 4) IN IF ~user.ok THEN Fail ELSE
    LET separator3 == ReadBytes(user.rest, 1) IN IF ~separator3.ok THEN Fail ELSE
    LET token == ReadBytes(separator3.rest, 10) IN IF ~token.ok THEN Fail ELSE
    LET separator4 == ReadBytes(token.rest, 1) IN IF ~separator4.ok THEN Fail ELSE
    LET replacedToken == ReadBytes(separator4.rest, 10) IN IF ~replacedToken.ok THEN Fail ELSE
    LET separator5 == ReadBytes(replacedToken.rest, 1) IN IF ~separator5.ok THEN Fail ELSE
    LET buySell == ReadBytes(separator5.rest, 1) IN IF ~buySell.ok THEN Fail ELSE
    LET separator6 == ReadBytes(buySell.rest, 1) IN IF ~separator6.ok THEN Fail ELSE
    LET shares == ReadBytes(separator6.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    LET separator7 == ReadBytes(shares.rest, 1) IN IF ~separator7.ok THEN Fail ELSE
    LET stock == ReadBytes(separator7.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET separator8 == ReadBytes(stock.rest, 1) IN IF ~separator8.ok THEN Fail ELSE
    LET price == ReadBytes(separator8.rest, 11) IN IF ~price.ok THEN Fail ELSE
    LET separator9 == ReadBytes(price.rest, 1) IN IF ~separator9.ok THEN Fail ELSE
    LET firm == ReadBytes(separator9.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET separator10 == ReadBytes(firm.rest, 1) IN IF ~separator10.ok THEN Fail ELSE
    LET reference == ReadBytes(separator10.rest, 12) IN IF ~reference.ok THEN Fail ELSE
    LET separator11 == ReadBytes(reference.rest, 1) IN IF ~separator11.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(separator11.rest, 12) IN IF ~matchNumber.ok THEN Fail ELSE
    LET separator12 == ReadBytes(matchNumber.rest, 1) IN IF ~separator12.ok THEN Fail ELSE
    LET capacity == ReadBytes(separator12.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET separator13 == ReadBytes(capacity.rest, 1) IN IF ~separator13.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(separator13.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET separator14 == ReadBytes(liquidityFlag.rest, 1) IN IF ~separator14.ok THEN Fail ELSE
    LET clearingCode == ReadBytes(separator14.rest, 1) IN IF ~clearingCode.ok THEN Fail ELSE
    Ok([ separator1    |-> separator1.value,
         source        |-> source.value,
         separator2    |-> separator2.value,
         user          |-> user.value,
         separator3    |-> separator3.value,
         token         |-> token.value,
         separator4    |-> separator4.value,
         replacedToken |-> replacedToken.value,
         separator5    |-> separator5.value,
         buySell       |-> buySell.value,
         separator6    |-> separator6.value,
         shares        |-> shares.value,
         separator7    |-> separator7.value,
         stock         |-> stock.value,
         separator8    |-> separator8.value,
         price         |-> price.value,
         separator9    |-> separator9.value,
         firm          |-> firm.value,
         separator10   |-> separator10.value,
         reference     |-> reference.value,
         separator11   |-> separator11.value,
         matchNumber   |-> matchNumber.value,
         separator12   |-> separator12.value,
         capacity      |-> capacity.value,
         separator13   |-> separator13.value,
         liquidityFlag |-> liquidityFlag.value,
         separator14   |-> separator14.value,
         clearingCode  |-> clearingCode.value ], clearingCode.rest)

ZeroPreviousExecutionBrokenMessage ==
    [ separator1    |-> [i \in 1 .. 1 |-> 0],
      source        |-> [i \in 1 .. 6 |-> 0],
      separator2    |-> [i \in 1 .. 1 |-> 0],
      user          |-> [i \in 1 .. 4 |-> 0],
      separator3    |-> [i \in 1 .. 1 |-> 0],
      token         |-> [i \in 1 .. 10 |-> 0],
      separator4    |-> [i \in 1 .. 1 |-> 0],
      replacedToken |-> [i \in 1 .. 10 |-> 0],
      separator5    |-> [i \in 1 .. 1 |-> 0],
      buySell       |-> [i \in 1 .. 1 |-> 0],
      separator6    |-> [i \in 1 .. 1 |-> 0],
      shares        |-> [i \in 1 .. 6 |-> 0],
      separator7    |-> [i \in 1 .. 1 |-> 0],
      stock         |-> [i \in 1 .. 6 |-> 0],
      separator8    |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 11 |-> 0],
      separator9    |-> [i \in 1 .. 1 |-> 0],
      firm          |-> [i \in 1 .. 4 |-> 0],
      separator10   |-> [i \in 1 .. 1 |-> 0],
      reference     |-> [i \in 1 .. 12 |-> 0],
      separator11   |-> [i \in 1 .. 1 |-> 0],
      matchNumber   |-> [i \in 1 .. 12 |-> 0],
      separator12   |-> [i \in 1 .. 1 |-> 0],
      capacity      |-> [i \in 1 .. 1 |-> 0],
      separator13   |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag |-> [i \in 1 .. 1 |-> 0],
      separator14   |-> [i \in 1 .. 1 |-> 0],
      clearingCode  |-> [i \in 1 .. 1 |-> 0] ]

(* Previous Execution Broken Message at zero, then each field in turn at the values it is checked at *)
CheckedPreviousExecutionBrokenMessage ==
    { ZeroPreviousExecutionBrokenMessage }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator1 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.source = one] : one \in Sample(6) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator2 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.user = one] : one \in Sample(4) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator3 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.token = one] : one \in Sample(10) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator4 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.replacedToken = one] : one \in Sample(10) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator5 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.buySell = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator6 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.shares = one] : one \in Sample(6) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator7 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator8 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.price = one] : one \in Sample(11) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator9 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator10 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.reference = one] : one \in Sample(12) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator11 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.matchNumber = one] : one \in Sample(12) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator12 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator13 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator14 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.clearingCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Existing Order Replaced Message: 99 bytes                               *)
(***************************************************************************)

ExistingOrderReplacedMessage ==
    [ separator1    : Sample(1),
      source        : Sample(6),
      separator2    : Sample(1),
      user          : Sample(4),
      separator3    : Sample(1),
      token         : Sample(10),
      separator4    : Sample(1),
      replacedToken : Sample(10),
      separator5    : Sample(1),
      buySell       : Sample(1),
      separator6    : Sample(1),
      shares        : Sample(6),
      separator7    : Sample(1),
      stock         : Sample(6),
      separator8    : Sample(1),
      price         : Sample(11),
      separator9    : Sample(1),
      firm          : Sample(4),
      separator10   : Sample(1),
      reference     : Sample(12),
      separator11   : Sample(1),
      timeInForce   : Sample(12),
      separator12   : Sample(1),
      capacity      : Sample(1),
      separator13   : Sample(1),
      liquidityFlag : Sample(1),
      separator14   : Sample(1),
      clearingCode  : Sample(1) ]

EncodeExistingOrderReplacedMessage(message) ==
    message.separator1
        \o message.source
        \o message.separator2
        \o message.user
        \o message.separator3
        \o message.token
        \o message.separator4
        \o message.replacedToken
        \o message.separator5
        \o message.buySell
        \o message.separator6
        \o message.shares
        \o message.separator7
        \o message.stock
        \o message.separator8
        \o message.price
        \o message.separator9
        \o message.firm
        \o message.separator10
        \o message.reference
        \o message.separator11
        \o message.timeInForce
        \o message.separator12
        \o message.capacity
        \o message.separator13
        \o message.liquidityFlag
        \o message.separator14
        \o message.clearingCode

DecodeExistingOrderReplacedMessage(bytes) ==
    LET separator1 == ReadBytes(bytes, 1) IN IF ~separator1.ok THEN Fail ELSE
    LET source == ReadBytes(separator1.rest, 6) IN IF ~source.ok THEN Fail ELSE
    LET separator2 == ReadBytes(source.rest, 1) IN IF ~separator2.ok THEN Fail ELSE
    LET user == ReadBytes(separator2.rest, 4) IN IF ~user.ok THEN Fail ELSE
    LET separator3 == ReadBytes(user.rest, 1) IN IF ~separator3.ok THEN Fail ELSE
    LET token == ReadBytes(separator3.rest, 10) IN IF ~token.ok THEN Fail ELSE
    LET separator4 == ReadBytes(token.rest, 1) IN IF ~separator4.ok THEN Fail ELSE
    LET replacedToken == ReadBytes(separator4.rest, 10) IN IF ~replacedToken.ok THEN Fail ELSE
    LET separator5 == ReadBytes(replacedToken.rest, 1) IN IF ~separator5.ok THEN Fail ELSE
    LET buySell == ReadBytes(separator5.rest, 1) IN IF ~buySell.ok THEN Fail ELSE
    LET separator6 == ReadBytes(buySell.rest, 1) IN IF ~separator6.ok THEN Fail ELSE
    LET shares == ReadBytes(separator6.rest, 6) IN IF ~shares.ok THEN Fail ELSE
    LET separator7 == ReadBytes(shares.rest, 1) IN IF ~separator7.ok THEN Fail ELSE
    LET stock == ReadBytes(separator7.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET separator8 == ReadBytes(stock.rest, 1) IN IF ~separator8.ok THEN Fail ELSE
    LET price == ReadBytes(separator8.rest, 11) IN IF ~price.ok THEN Fail ELSE
    LET separator9 == ReadBytes(price.rest, 1) IN IF ~separator9.ok THEN Fail ELSE
    LET firm == ReadBytes(separator9.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET separator10 == ReadBytes(firm.rest, 1) IN IF ~separator10.ok THEN Fail ELSE
    LET reference == ReadBytes(separator10.rest, 12) IN IF ~reference.ok THEN Fail ELSE
    LET separator11 == ReadBytes(reference.rest, 1) IN IF ~separator11.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(separator11.rest, 12) IN IF ~timeInForce.ok THEN Fail ELSE
    LET separator12 == ReadBytes(timeInForce.rest, 1) IN IF ~separator12.ok THEN Fail ELSE
    LET capacity == ReadBytes(separator12.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET separator13 == ReadBytes(capacity.rest, 1) IN IF ~separator13.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(separator13.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET separator14 == ReadBytes(liquidityFlag.rest, 1) IN IF ~separator14.ok THEN Fail ELSE
    LET clearingCode == ReadBytes(separator14.rest, 1) IN IF ~clearingCode.ok THEN Fail ELSE
    Ok([ separator1    |-> separator1.value,
         source        |-> source.value,
         separator2    |-> separator2.value,
         user          |-> user.value,
         separator3    |-> separator3.value,
         token         |-> token.value,
         separator4    |-> separator4.value,
         replacedToken |-> replacedToken.value,
         separator5    |-> separator5.value,
         buySell       |-> buySell.value,
         separator6    |-> separator6.value,
         shares        |-> shares.value,
         separator7    |-> separator7.value,
         stock         |-> stock.value,
         separator8    |-> separator8.value,
         price         |-> price.value,
         separator9    |-> separator9.value,
         firm          |-> firm.value,
         separator10   |-> separator10.value,
         reference     |-> reference.value,
         separator11   |-> separator11.value,
         timeInForce   |-> timeInForce.value,
         separator12   |-> separator12.value,
         capacity      |-> capacity.value,
         separator13   |-> separator13.value,
         liquidityFlag |-> liquidityFlag.value,
         separator14   |-> separator14.value,
         clearingCode  |-> clearingCode.value ], clearingCode.rest)

ZeroExistingOrderReplacedMessage ==
    [ separator1    |-> [i \in 1 .. 1 |-> 0],
      source        |-> [i \in 1 .. 6 |-> 0],
      separator2    |-> [i \in 1 .. 1 |-> 0],
      user          |-> [i \in 1 .. 4 |-> 0],
      separator3    |-> [i \in 1 .. 1 |-> 0],
      token         |-> [i \in 1 .. 10 |-> 0],
      separator4    |-> [i \in 1 .. 1 |-> 0],
      replacedToken |-> [i \in 1 .. 10 |-> 0],
      separator5    |-> [i \in 1 .. 1 |-> 0],
      buySell       |-> [i \in 1 .. 1 |-> 0],
      separator6    |-> [i \in 1 .. 1 |-> 0],
      shares        |-> [i \in 1 .. 6 |-> 0],
      separator7    |-> [i \in 1 .. 1 |-> 0],
      stock         |-> [i \in 1 .. 6 |-> 0],
      separator8    |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 11 |-> 0],
      separator9    |-> [i \in 1 .. 1 |-> 0],
      firm          |-> [i \in 1 .. 4 |-> 0],
      separator10   |-> [i \in 1 .. 1 |-> 0],
      reference     |-> [i \in 1 .. 12 |-> 0],
      separator11   |-> [i \in 1 .. 1 |-> 0],
      timeInForce   |-> [i \in 1 .. 12 |-> 0],
      separator12   |-> [i \in 1 .. 1 |-> 0],
      capacity      |-> [i \in 1 .. 1 |-> 0],
      separator13   |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag |-> [i \in 1 .. 1 |-> 0],
      separator14   |-> [i \in 1 .. 1 |-> 0],
      clearingCode  |-> [i \in 1 .. 1 |-> 0] ]

(* Existing Order Replaced Message at zero, then each field in turn at the values it is checked at *)
CheckedExistingOrderReplacedMessage ==
    { ZeroExistingOrderReplacedMessage }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.separator1 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.source = one] : one \in Sample(6) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.separator2 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.user = one] : one \in Sample(4) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.separator3 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.token = one] : one \in Sample(10) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.separator4 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.replacedToken = one] : one \in Sample(10) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.separator5 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.buySell = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.separator6 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.shares = one] : one \in Sample(6) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.separator7 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.separator8 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.price = one] : one \in Sample(11) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.separator9 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.separator10 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.reference = one] : one \in Sample(12) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.separator11 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.timeInForce = one] : one \in Sample(12) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.separator12 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.separator13 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.separator14 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderReplacedMessage EXCEPT !.clearingCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Sequenced Message, selected by Message Type                             *)
(***************************************************************************)

NewOrderAcceptedMessageCode == 65  \* "A"
ExistingOrderExecutedMessageCode == 69  \* "E"
ExistingOrderCanceledMessageCode == 88  \* "X"
PreviousExecutionBrokenMessageCode == 66  \* "B"
ExistingOrderReplacedMessageCode == 85  \* "U"

SequencedMessage ==
    [ tag : {NewOrderAcceptedMessageCode}, body : NewOrderAcceptedMessage ]
        \cup [ tag : {ExistingOrderExecutedMessageCode}, body : ExistingOrderExecutedMessage ]
        \cup [ tag : {ExistingOrderCanceledMessageCode}, body : ExistingOrderCanceledMessage ]
        \cup [ tag : {PreviousExecutionBrokenMessageCode}, body : PreviousExecutionBrokenMessage ]
        \cup [ tag : {ExistingOrderReplacedMessageCode}, body : ExistingOrderReplacedMessage ]

EncodeSequencedMessage(message) ==
    CASE message.tag = NewOrderAcceptedMessageCode -> EncodeNewOrderAcceptedMessage(message.body)
      [] message.tag = ExistingOrderExecutedMessageCode -> EncodeExistingOrderExecutedMessage(message.body)
      [] message.tag = ExistingOrderCanceledMessageCode -> EncodeExistingOrderCanceledMessage(message.body)
      [] message.tag = PreviousExecutionBrokenMessageCode -> EncodePreviousExecutionBrokenMessage(message.body)
      [] message.tag = ExistingOrderReplacedMessageCode -> EncodeExistingOrderReplacedMessage(message.body)

DecodeSequencedMessage(tag, bytes) ==
    LET read ==
            CASE tag = NewOrderAcceptedMessageCode -> DecodeNewOrderAcceptedMessage(bytes)
              [] tag = ExistingOrderExecutedMessageCode -> DecodeExistingOrderExecutedMessage(bytes)
              [] tag = ExistingOrderCanceledMessageCode -> DecodeExistingOrderCanceledMessage(bytes)
              [] tag = PreviousExecutionBrokenMessageCode -> DecodePreviousExecutionBrokenMessage(bytes)
              [] tag = ExistingOrderReplacedMessageCode -> DecodeExistingOrderReplacedMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroSequencedMessage == [tag |-> NewOrderAcceptedMessageCode, body |-> ZeroNewOrderAcceptedMessage]

(* Each Sequenced Message in turn, at the values the message it names is checked at *)
CheckedSequencedMessage ==
    { [tag |-> NewOrderAcceptedMessageCode, body |-> one] : one \in CheckedNewOrderAcceptedMessage }
        \cup { [tag |-> ExistingOrderExecutedMessageCode, body |-> one] : one \in CheckedExistingOrderExecutedMessage }
        \cup { [tag |-> ExistingOrderCanceledMessageCode, body |-> one] : one \in CheckedExistingOrderCanceledMessage }
        \cup { [tag |-> PreviousExecutionBrokenMessageCode, body |-> one] : one \in CheckedPreviousExecutionBrokenMessage }
        \cup { [tag |-> ExistingOrderReplacedMessageCode, body |-> one] : one \in CheckedExistingOrderReplacedMessage }

(***************************************************************************)
(* Sequenced Data Packet                                                   *)
(***************************************************************************)

SequencedDataPacket ==
    [ timeStamp        : Sample(9),
      comma            : Sample(1),
      sequencedMessage : SequencedMessage ]

EncodeSequencedDataPacket(message) ==
    message.timeStamp
        \o message.comma
        \o EncodeUIntBE(message.sequencedMessage.tag, 1)
        \o EncodeSequencedMessage(message.sequencedMessage)

DecodeSequencedDataPacket(bytes) ==
    LET timeStamp == ReadBytes(bytes, 9) IN IF ~timeStamp.ok THEN Fail ELSE
    LET comma == ReadBytes(timeStamp.rest, 1) IN IF ~comma.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(comma.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET sequencedMessage == DecodeSequencedMessage(messageType.value, messageType.rest) IN IF ~sequencedMessage.ok THEN Fail ELSE
    Ok([ timeStamp        |-> timeStamp.value,
         comma            |-> comma.value,
         sequencedMessage |-> sequencedMessage.value ], sequencedMessage.rest)

ZeroSequencedDataPacket ==
    [ timeStamp        |-> [i \in 1 .. 9 |-> 0],
      comma            |-> [i \in 1 .. 1 |-> 0],
      sequencedMessage |-> ZeroSequencedMessage ]

(* Sequenced Data Packet at zero, then each field in turn at the values it is checked at *)
CheckedSequencedDataPacket ==
    { ZeroSequencedDataPacket }
        \cup { [ZeroSequencedDataPacket EXCEPT !.timeStamp = one] : one \in Sample(9) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.comma = one] : one \in Sample(1) }
        \cup { [ZeroSequencedDataPacket EXCEPT !.sequencedMessage = one] : one \in CheckedSequencedMessage }

(***************************************************************************)
(* Server Payload, selected by Server Packet Type                          *)
(***************************************************************************)

DebugPacketCode == 43  \* "+"
LoginAcceptedPacketCode == 65  \* "A"
LoginRejectedPacketCode == 74  \* "J"
SequencedDataPacketCode == 83  \* "S"

ServerPayload ==
    [ tag : {DebugPacketCode}, body : DebugPacket ]
        \cup [ tag : {LoginAcceptedPacketCode}, body : LoginAcceptedPacket ]
        \cup [ tag : {LoginRejectedPacketCode}, body : LoginRejectedPacket ]
        \cup [ tag : {SequencedDataPacketCode}, body : SequencedDataPacket ]

EncodeServerPayload(message) ==
    CASE message.tag = DebugPacketCode -> EncodeDebugPacket(message.body)
      [] message.tag = LoginAcceptedPacketCode -> EncodeLoginAcceptedPacket(message.body)
      [] message.tag = LoginRejectedPacketCode -> EncodeLoginRejectedPacket(message.body)
      [] message.tag = SequencedDataPacketCode -> EncodeSequencedDataPacket(message.body)

DecodeServerPayload(tag, bytes) ==
    LET read ==
            CASE tag = DebugPacketCode -> DecodeDebugPacket(bytes)
              [] tag = LoginAcceptedPacketCode -> DecodeLoginAcceptedPacket(bytes)
              [] tag = LoginRejectedPacketCode -> DecodeLoginRejectedPacket(bytes)
              [] tag = SequencedDataPacketCode -> DecodeSequencedDataPacket(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerPayload == [tag |-> DebugPacketCode, body |-> ZeroDebugPacket]

(* Each Server Payload in turn, at the values the message it names is checked at *)
CheckedServerPayload ==
    { [tag |-> DebugPacketCode, body |-> one] : one \in CheckedDebugPacket }
        \cup { [tag |-> LoginAcceptedPacketCode, body |-> one] : one \in CheckedLoginAcceptedPacket }
        \cup { [tag |-> LoginRejectedPacketCode, body |-> one] : one \in CheckedLoginRejectedPacket }
        \cup { [tag |-> SequencedDataPacketCode, body |-> one] : one \in CheckedSequencedDataPacket }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverPayload : ServerPayload,
      soupLf        : Sample(1) ]

EncodeServerPacket(message) ==
    EncodeUIntBE(message.serverPayload.tag, 1)
        \o EncodeServerPayload(message.serverPayload)
        \o message.soupLf

DecodeServerPacket(bytes) ==
    LET serverPacketType == ReadUIntBE(bytes, 1) IN IF ~serverPacketType.ok THEN Fail ELSE
    LET serverPayload == DecodeServerPayload(serverPacketType.value, serverPacketType.rest) IN IF ~serverPayload.ok THEN Fail ELSE
    LET soupLf == ReadBytes(serverPayload.rest, 1) IN IF ~soupLf.ok THEN Fail ELSE
    Ok([ serverPayload |-> serverPayload.value,
         soupLf        |-> soupLf.value ], soupLf.rest)

ZeroServerPacket ==
    [ serverPayload |-> ZeroServerPayload,
      soupLf        |-> [i \in 1 .. 1 |-> 0] ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverPayload = one] : one \in CheckedServerPayload }
        \cup { [ZeroServerPacket EXCEPT !.soupLf = one] : one \in Sample(1) }

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

(* Every New Order Accepted Message decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderAcceptedMessage ==
    \A message \in CheckedNewOrderAcceptedMessage :
        LET read == DecodeNewOrderAcceptedMessage(EncodeNewOrderAcceptedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Existing Order Executed Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExistingOrderExecutedMessage ==
    \A message \in CheckedExistingOrderExecutedMessage :
        LET read == DecodeExistingOrderExecutedMessage(EncodeExistingOrderExecutedMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Existing Order Canceled Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExistingOrderCanceledMessage ==
    \A message \in CheckedExistingOrderCanceledMessage :
        LET read == DecodeExistingOrderCanceledMessage(EncodeExistingOrderCanceledMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Previous Execution Broken Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPreviousExecutionBrokenMessage ==
    \A message \in CheckedPreviousExecutionBrokenMessage :
        LET read == DecodePreviousExecutionBrokenMessage(EncodePreviousExecutionBrokenMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Existing Order Replaced Message decodes back to what was encoded, and leaves nothing over *)
RoundTripExistingOrderReplacedMessage ==
    \A message \in CheckedExistingOrderReplacedMessage :
        LET read == DecodeExistingOrderReplacedMessage(EncodeExistingOrderReplacedMessage(message))
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

(* Every Server Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripServerPacket ==
    \A message \in CheckedServerPacket :
        LET read == DecodeServerPacket(EncodeServerPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Sequenced Message is selected by the Message Type it is written under *)
SelectsSequencedMessage ==
    \A message \in CheckedSequencedMessage :
        LET read == DecodeSequencedMessage(message.tag, EncodeSequencedMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

(* A Server Payload is selected by the Server Packet Type it is written under *)
SelectsServerPayload ==
    \A message \in CheckedServerPayload :
        LET read == DecodeServerPayload(message.tag, EncodeServerPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
