----------------------- MODULE NsmEquities_Drop_v1_0 -----------------------
(***************************************************************************)
(* National Association of Securities Dealers Automated Quotations         *)
(* (Nasdaq) Drop v1.0                                                      *)
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
(* New Order Accepted Message: 93 bytes                                    *)
(***************************************************************************)

NewOrderAcceptedMessage ==
    [ source        : Sample(6),
      separator1    : Sample(1),
      user          : Sample(4),
      separator2    : Sample(1),
      token         : Sample(10),
      separator3    : Sample(1),
      buySell       : Sample(1),
      separator4    : Sample(1),
      shares        : Sample(9),
      separator5    : Sample(1),
      stock         : Sample(6),
      separator6    : Sample(1),
      price         : Sample(20),
      separator7    : Sample(1),
      firm          : Sample(4),
      separator8    : Sample(1),
      reference     : Sample(9),
      separator9    : Sample(1),
      timeInForce   : Sample(9),
      separator10   : Sample(1),
      capacity      : Sample(1),
      separator11   : Sample(1),
      liquidityCode : Sample(1),
      separator12   : Sample(1),
      clearingCode  : Sample(1) ]

EncodeNewOrderAcceptedMessage(message) ==
    message.source
        \o message.separator1
        \o message.user
        \o message.separator2
        \o message.token
        \o message.separator3
        \o message.buySell
        \o message.separator4
        \o message.shares
        \o message.separator5
        \o message.stock
        \o message.separator6
        \o message.price
        \o message.separator7
        \o message.firm
        \o message.separator8
        \o message.reference
        \o message.separator9
        \o message.timeInForce
        \o message.separator10
        \o message.capacity
        \o message.separator11
        \o message.liquidityCode
        \o message.separator12
        \o message.clearingCode

DecodeNewOrderAcceptedMessage(bytes) ==
    LET source == ReadBytes(bytes, 6) IN IF ~source.ok THEN Fail ELSE
    LET separator1 == ReadBytes(source.rest, 1) IN IF ~separator1.ok THEN Fail ELSE
    LET user == ReadBytes(separator1.rest, 4) IN IF ~user.ok THEN Fail ELSE
    LET separator2 == ReadBytes(user.rest, 1) IN IF ~separator2.ok THEN Fail ELSE
    LET token == ReadBytes(separator2.rest, 10) IN IF ~token.ok THEN Fail ELSE
    LET separator3 == ReadBytes(token.rest, 1) IN IF ~separator3.ok THEN Fail ELSE
    LET buySell == ReadBytes(separator3.rest, 1) IN IF ~buySell.ok THEN Fail ELSE
    LET separator4 == ReadBytes(buySell.rest, 1) IN IF ~separator4.ok THEN Fail ELSE
    LET shares == ReadBytes(separator4.rest, 9) IN IF ~shares.ok THEN Fail ELSE
    LET separator5 == ReadBytes(shares.rest, 1) IN IF ~separator5.ok THEN Fail ELSE
    LET stock == ReadBytes(separator5.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET separator6 == ReadBytes(stock.rest, 1) IN IF ~separator6.ok THEN Fail ELSE
    LET price == ReadBytes(separator6.rest, 20) IN IF ~price.ok THEN Fail ELSE
    LET separator7 == ReadBytes(price.rest, 1) IN IF ~separator7.ok THEN Fail ELSE
    LET firm == ReadBytes(separator7.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET separator8 == ReadBytes(firm.rest, 1) IN IF ~separator8.ok THEN Fail ELSE
    LET reference == ReadBytes(separator8.rest, 9) IN IF ~reference.ok THEN Fail ELSE
    LET separator9 == ReadBytes(reference.rest, 1) IN IF ~separator9.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(separator9.rest, 9) IN IF ~timeInForce.ok THEN Fail ELSE
    LET separator10 == ReadBytes(timeInForce.rest, 1) IN IF ~separator10.ok THEN Fail ELSE
    LET capacity == ReadBytes(separator10.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET separator11 == ReadBytes(capacity.rest, 1) IN IF ~separator11.ok THEN Fail ELSE
    LET liquidityCode == ReadBytes(separator11.rest, 1) IN IF ~liquidityCode.ok THEN Fail ELSE
    LET separator12 == ReadBytes(liquidityCode.rest, 1) IN IF ~separator12.ok THEN Fail ELSE
    LET clearingCode == ReadBytes(separator12.rest, 1) IN IF ~clearingCode.ok THEN Fail ELSE
    Ok([ source        |-> source.value,
         separator1    |-> separator1.value,
         user          |-> user.value,
         separator2    |-> separator2.value,
         token         |-> token.value,
         separator3    |-> separator3.value,
         buySell       |-> buySell.value,
         separator4    |-> separator4.value,
         shares        |-> shares.value,
         separator5    |-> separator5.value,
         stock         |-> stock.value,
         separator6    |-> separator6.value,
         price         |-> price.value,
         separator7    |-> separator7.value,
         firm          |-> firm.value,
         separator8    |-> separator8.value,
         reference     |-> reference.value,
         separator9    |-> separator9.value,
         timeInForce   |-> timeInForce.value,
         separator10   |-> separator10.value,
         capacity      |-> capacity.value,
         separator11   |-> separator11.value,
         liquidityCode |-> liquidityCode.value,
         separator12   |-> separator12.value,
         clearingCode  |-> clearingCode.value ], clearingCode.rest)

ZeroNewOrderAcceptedMessage ==
    [ source        |-> [i \in 1 .. 6 |-> 0],
      separator1    |-> [i \in 1 .. 1 |-> 0],
      user          |-> [i \in 1 .. 4 |-> 0],
      separator2    |-> [i \in 1 .. 1 |-> 0],
      token         |-> [i \in 1 .. 10 |-> 0],
      separator3    |-> [i \in 1 .. 1 |-> 0],
      buySell       |-> [i \in 1 .. 1 |-> 0],
      separator4    |-> [i \in 1 .. 1 |-> 0],
      shares        |-> [i \in 1 .. 9 |-> 0],
      separator5    |-> [i \in 1 .. 1 |-> 0],
      stock         |-> [i \in 1 .. 6 |-> 0],
      separator6    |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 20 |-> 0],
      separator7    |-> [i \in 1 .. 1 |-> 0],
      firm          |-> [i \in 1 .. 4 |-> 0],
      separator8    |-> [i \in 1 .. 1 |-> 0],
      reference     |-> [i \in 1 .. 9 |-> 0],
      separator9    |-> [i \in 1 .. 1 |-> 0],
      timeInForce   |-> [i \in 1 .. 9 |-> 0],
      separator10   |-> [i \in 1 .. 1 |-> 0],
      capacity      |-> [i \in 1 .. 1 |-> 0],
      separator11   |-> [i \in 1 .. 1 |-> 0],
      liquidityCode |-> [i \in 1 .. 1 |-> 0],
      separator12   |-> [i \in 1 .. 1 |-> 0],
      clearingCode  |-> [i \in 1 .. 1 |-> 0] ]

(* New Order Accepted Message at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderAcceptedMessage ==
    { ZeroNewOrderAcceptedMessage }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.source = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator1 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.user = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator2 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.token = one] : one \in Sample(10) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator3 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.buySell = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator4 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.shares = one] : one \in Sample(9) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator5 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator6 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.price = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator7 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator8 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.reference = one] : one \in Sample(9) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator9 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.timeInForce = one] : one \in Sample(9) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator10 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator11 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.liquidityCode = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.separator12 = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderAcceptedMessage EXCEPT !.clearingCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Existing Order Executed Message: 93 bytes                               *)
(***************************************************************************)

ExistingOrderExecutedMessage ==
    [ source        : Sample(6),
      separator1    : Sample(1),
      user          : Sample(4),
      separator2    : Sample(1),
      token         : Sample(10),
      separator3    : Sample(1),
      buySell       : Sample(1),
      separator4    : Sample(1),
      shares        : Sample(9),
      separator5    : Sample(1),
      stock         : Sample(6),
      separator6    : Sample(1),
      price         : Sample(20),
      separator7    : Sample(1),
      firm          : Sample(4),
      separator8    : Sample(1),
      reference     : Sample(9),
      separator9    : Sample(1),
      matchNumber   : Sample(9),
      separator10   : Sample(1),
      capacity      : Sample(1),
      separator11   : Sample(1),
      liquidityCode : Sample(1),
      separator12   : Sample(1),
      clearingCode  : Sample(1) ]

EncodeExistingOrderExecutedMessage(message) ==
    message.source
        \o message.separator1
        \o message.user
        \o message.separator2
        \o message.token
        \o message.separator3
        \o message.buySell
        \o message.separator4
        \o message.shares
        \o message.separator5
        \o message.stock
        \o message.separator6
        \o message.price
        \o message.separator7
        \o message.firm
        \o message.separator8
        \o message.reference
        \o message.separator9
        \o message.matchNumber
        \o message.separator10
        \o message.capacity
        \o message.separator11
        \o message.liquidityCode
        \o message.separator12
        \o message.clearingCode

DecodeExistingOrderExecutedMessage(bytes) ==
    LET source == ReadBytes(bytes, 6) IN IF ~source.ok THEN Fail ELSE
    LET separator1 == ReadBytes(source.rest, 1) IN IF ~separator1.ok THEN Fail ELSE
    LET user == ReadBytes(separator1.rest, 4) IN IF ~user.ok THEN Fail ELSE
    LET separator2 == ReadBytes(user.rest, 1) IN IF ~separator2.ok THEN Fail ELSE
    LET token == ReadBytes(separator2.rest, 10) IN IF ~token.ok THEN Fail ELSE
    LET separator3 == ReadBytes(token.rest, 1) IN IF ~separator3.ok THEN Fail ELSE
    LET buySell == ReadBytes(separator3.rest, 1) IN IF ~buySell.ok THEN Fail ELSE
    LET separator4 == ReadBytes(buySell.rest, 1) IN IF ~separator4.ok THEN Fail ELSE
    LET shares == ReadBytes(separator4.rest, 9) IN IF ~shares.ok THEN Fail ELSE
    LET separator5 == ReadBytes(shares.rest, 1) IN IF ~separator5.ok THEN Fail ELSE
    LET stock == ReadBytes(separator5.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET separator6 == ReadBytes(stock.rest, 1) IN IF ~separator6.ok THEN Fail ELSE
    LET price == ReadBytes(separator6.rest, 20) IN IF ~price.ok THEN Fail ELSE
    LET separator7 == ReadBytes(price.rest, 1) IN IF ~separator7.ok THEN Fail ELSE
    LET firm == ReadBytes(separator7.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET separator8 == ReadBytes(firm.rest, 1) IN IF ~separator8.ok THEN Fail ELSE
    LET reference == ReadBytes(separator8.rest, 9) IN IF ~reference.ok THEN Fail ELSE
    LET separator9 == ReadBytes(reference.rest, 1) IN IF ~separator9.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(separator9.rest, 9) IN IF ~matchNumber.ok THEN Fail ELSE
    LET separator10 == ReadBytes(matchNumber.rest, 1) IN IF ~separator10.ok THEN Fail ELSE
    LET capacity == ReadBytes(separator10.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET separator11 == ReadBytes(capacity.rest, 1) IN IF ~separator11.ok THEN Fail ELSE
    LET liquidityCode == ReadBytes(separator11.rest, 1) IN IF ~liquidityCode.ok THEN Fail ELSE
    LET separator12 == ReadBytes(liquidityCode.rest, 1) IN IF ~separator12.ok THEN Fail ELSE
    LET clearingCode == ReadBytes(separator12.rest, 1) IN IF ~clearingCode.ok THEN Fail ELSE
    Ok([ source        |-> source.value,
         separator1    |-> separator1.value,
         user          |-> user.value,
         separator2    |-> separator2.value,
         token         |-> token.value,
         separator3    |-> separator3.value,
         buySell       |-> buySell.value,
         separator4    |-> separator4.value,
         shares        |-> shares.value,
         separator5    |-> separator5.value,
         stock         |-> stock.value,
         separator6    |-> separator6.value,
         price         |-> price.value,
         separator7    |-> separator7.value,
         firm          |-> firm.value,
         separator8    |-> separator8.value,
         reference     |-> reference.value,
         separator9    |-> separator9.value,
         matchNumber   |-> matchNumber.value,
         separator10   |-> separator10.value,
         capacity      |-> capacity.value,
         separator11   |-> separator11.value,
         liquidityCode |-> liquidityCode.value,
         separator12   |-> separator12.value,
         clearingCode  |-> clearingCode.value ], clearingCode.rest)

ZeroExistingOrderExecutedMessage ==
    [ source        |-> [i \in 1 .. 6 |-> 0],
      separator1    |-> [i \in 1 .. 1 |-> 0],
      user          |-> [i \in 1 .. 4 |-> 0],
      separator2    |-> [i \in 1 .. 1 |-> 0],
      token         |-> [i \in 1 .. 10 |-> 0],
      separator3    |-> [i \in 1 .. 1 |-> 0],
      buySell       |-> [i \in 1 .. 1 |-> 0],
      separator4    |-> [i \in 1 .. 1 |-> 0],
      shares        |-> [i \in 1 .. 9 |-> 0],
      separator5    |-> [i \in 1 .. 1 |-> 0],
      stock         |-> [i \in 1 .. 6 |-> 0],
      separator6    |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 20 |-> 0],
      separator7    |-> [i \in 1 .. 1 |-> 0],
      firm          |-> [i \in 1 .. 4 |-> 0],
      separator8    |-> [i \in 1 .. 1 |-> 0],
      reference     |-> [i \in 1 .. 9 |-> 0],
      separator9    |-> [i \in 1 .. 1 |-> 0],
      matchNumber   |-> [i \in 1 .. 9 |-> 0],
      separator10   |-> [i \in 1 .. 1 |-> 0],
      capacity      |-> [i \in 1 .. 1 |-> 0],
      separator11   |-> [i \in 1 .. 1 |-> 0],
      liquidityCode |-> [i \in 1 .. 1 |-> 0],
      separator12   |-> [i \in 1 .. 1 |-> 0],
      clearingCode  |-> [i \in 1 .. 1 |-> 0] ]

(* Existing Order Executed Message at zero, then each field in turn at the values it is checked at *)
CheckedExistingOrderExecutedMessage ==
    { ZeroExistingOrderExecutedMessage }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.source = one] : one \in Sample(6) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator1 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.user = one] : one \in Sample(4) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator2 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.token = one] : one \in Sample(10) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator3 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.buySell = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator4 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.shares = one] : one \in Sample(9) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator5 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator6 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.price = one] : one \in Sample(20) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator7 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator8 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.reference = one] : one \in Sample(9) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator9 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.matchNumber = one] : one \in Sample(9) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator10 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator11 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.liquidityCode = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.separator12 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderExecutedMessage EXCEPT !.clearingCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Existing Order Canceled Message: 93 bytes                               *)
(***************************************************************************)

ExistingOrderCanceledMessage ==
    [ source       : Sample(6),
      separator1   : Sample(1),
      user         : Sample(4),
      separator2   : Sample(1),
      token        : Sample(10),
      separator3   : Sample(1),
      buySell      : Sample(1),
      separator4   : Sample(1),
      shares       : Sample(9),
      separator5   : Sample(1),
      stock        : Sample(6),
      separator6   : Sample(1),
      price        : Sample(20),
      separator7   : Sample(1),
      firm         : Sample(4),
      separator8   : Sample(1),
      reference    : Sample(9),
      separator9   : Sample(1),
      timeInForce  : Sample(9),
      separator10  : Sample(1),
      capacity     : Sample(1),
      separator11  : Sample(1),
      cancelReason : Sample(1),
      separator12  : Sample(1),
      clearingCode : Sample(1) ]

EncodeExistingOrderCanceledMessage(message) ==
    message.source
        \o message.separator1
        \o message.user
        \o message.separator2
        \o message.token
        \o message.separator3
        \o message.buySell
        \o message.separator4
        \o message.shares
        \o message.separator5
        \o message.stock
        \o message.separator6
        \o message.price
        \o message.separator7
        \o message.firm
        \o message.separator8
        \o message.reference
        \o message.separator9
        \o message.timeInForce
        \o message.separator10
        \o message.capacity
        \o message.separator11
        \o message.cancelReason
        \o message.separator12
        \o message.clearingCode

DecodeExistingOrderCanceledMessage(bytes) ==
    LET source == ReadBytes(bytes, 6) IN IF ~source.ok THEN Fail ELSE
    LET separator1 == ReadBytes(source.rest, 1) IN IF ~separator1.ok THEN Fail ELSE
    LET user == ReadBytes(separator1.rest, 4) IN IF ~user.ok THEN Fail ELSE
    LET separator2 == ReadBytes(user.rest, 1) IN IF ~separator2.ok THEN Fail ELSE
    LET token == ReadBytes(separator2.rest, 10) IN IF ~token.ok THEN Fail ELSE
    LET separator3 == ReadBytes(token.rest, 1) IN IF ~separator3.ok THEN Fail ELSE
    LET buySell == ReadBytes(separator3.rest, 1) IN IF ~buySell.ok THEN Fail ELSE
    LET separator4 == ReadBytes(buySell.rest, 1) IN IF ~separator4.ok THEN Fail ELSE
    LET shares == ReadBytes(separator4.rest, 9) IN IF ~shares.ok THEN Fail ELSE
    LET separator5 == ReadBytes(shares.rest, 1) IN IF ~separator5.ok THEN Fail ELSE
    LET stock == ReadBytes(separator5.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET separator6 == ReadBytes(stock.rest, 1) IN IF ~separator6.ok THEN Fail ELSE
    LET price == ReadBytes(separator6.rest, 20) IN IF ~price.ok THEN Fail ELSE
    LET separator7 == ReadBytes(price.rest, 1) IN IF ~separator7.ok THEN Fail ELSE
    LET firm == ReadBytes(separator7.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET separator8 == ReadBytes(firm.rest, 1) IN IF ~separator8.ok THEN Fail ELSE
    LET reference == ReadBytes(separator8.rest, 9) IN IF ~reference.ok THEN Fail ELSE
    LET separator9 == ReadBytes(reference.rest, 1) IN IF ~separator9.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(separator9.rest, 9) IN IF ~timeInForce.ok THEN Fail ELSE
    LET separator10 == ReadBytes(timeInForce.rest, 1) IN IF ~separator10.ok THEN Fail ELSE
    LET capacity == ReadBytes(separator10.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET separator11 == ReadBytes(capacity.rest, 1) IN IF ~separator11.ok THEN Fail ELSE
    LET cancelReason == ReadBytes(separator11.rest, 1) IN IF ~cancelReason.ok THEN Fail ELSE
    LET separator12 == ReadBytes(cancelReason.rest, 1) IN IF ~separator12.ok THEN Fail ELSE
    LET clearingCode == ReadBytes(separator12.rest, 1) IN IF ~clearingCode.ok THEN Fail ELSE
    Ok([ source       |-> source.value,
         separator1   |-> separator1.value,
         user         |-> user.value,
         separator2   |-> separator2.value,
         token        |-> token.value,
         separator3   |-> separator3.value,
         buySell      |-> buySell.value,
         separator4   |-> separator4.value,
         shares       |-> shares.value,
         separator5   |-> separator5.value,
         stock        |-> stock.value,
         separator6   |-> separator6.value,
         price        |-> price.value,
         separator7   |-> separator7.value,
         firm         |-> firm.value,
         separator8   |-> separator8.value,
         reference    |-> reference.value,
         separator9   |-> separator9.value,
         timeInForce  |-> timeInForce.value,
         separator10  |-> separator10.value,
         capacity     |-> capacity.value,
         separator11  |-> separator11.value,
         cancelReason |-> cancelReason.value,
         separator12  |-> separator12.value,
         clearingCode |-> clearingCode.value ], clearingCode.rest)

ZeroExistingOrderCanceledMessage ==
    [ source       |-> [i \in 1 .. 6 |-> 0],
      separator1   |-> [i \in 1 .. 1 |-> 0],
      user         |-> [i \in 1 .. 4 |-> 0],
      separator2   |-> [i \in 1 .. 1 |-> 0],
      token        |-> [i \in 1 .. 10 |-> 0],
      separator3   |-> [i \in 1 .. 1 |-> 0],
      buySell      |-> [i \in 1 .. 1 |-> 0],
      separator4   |-> [i \in 1 .. 1 |-> 0],
      shares       |-> [i \in 1 .. 9 |-> 0],
      separator5   |-> [i \in 1 .. 1 |-> 0],
      stock        |-> [i \in 1 .. 6 |-> 0],
      separator6   |-> [i \in 1 .. 1 |-> 0],
      price        |-> [i \in 1 .. 20 |-> 0],
      separator7   |-> [i \in 1 .. 1 |-> 0],
      firm         |-> [i \in 1 .. 4 |-> 0],
      separator8   |-> [i \in 1 .. 1 |-> 0],
      reference    |-> [i \in 1 .. 9 |-> 0],
      separator9   |-> [i \in 1 .. 1 |-> 0],
      timeInForce  |-> [i \in 1 .. 9 |-> 0],
      separator10  |-> [i \in 1 .. 1 |-> 0],
      capacity     |-> [i \in 1 .. 1 |-> 0],
      separator11  |-> [i \in 1 .. 1 |-> 0],
      cancelReason |-> [i \in 1 .. 1 |-> 0],
      separator12  |-> [i \in 1 .. 1 |-> 0],
      clearingCode |-> [i \in 1 .. 1 |-> 0] ]

(* Existing Order Canceled Message at zero, then each field in turn at the values it is checked at *)
CheckedExistingOrderCanceledMessage ==
    { ZeroExistingOrderCanceledMessage }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.source = one] : one \in Sample(6) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator1 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.user = one] : one \in Sample(4) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator2 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.token = one] : one \in Sample(10) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator3 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.buySell = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator4 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.shares = one] : one \in Sample(9) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator5 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator6 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.price = one] : one \in Sample(20) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator7 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator8 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.reference = one] : one \in Sample(9) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator9 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.timeInForce = one] : one \in Sample(9) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator10 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator11 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.cancelReason = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.separator12 = one] : one \in Sample(1) }
        \cup { [ZeroExistingOrderCanceledMessage EXCEPT !.clearingCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Previous Execution Broken Message: 93 bytes                             *)
(***************************************************************************)

PreviousExecutionBrokenMessage ==
    [ source        : Sample(6),
      separator1    : Sample(1),
      user          : Sample(4),
      separator2    : Sample(1),
      token         : Sample(10),
      separator3    : Sample(1),
      buySell       : Sample(1),
      separator4    : Sample(1),
      shares        : Sample(9),
      separator5    : Sample(1),
      stock         : Sample(6),
      separator6    : Sample(1),
      price         : Sample(20),
      separator7    : Sample(1),
      firm          : Sample(4),
      separator8    : Sample(1),
      reference     : Sample(9),
      separator9    : Sample(1),
      matchNumber   : Sample(9),
      separator10   : Sample(1),
      capacity      : Sample(1),
      separator11   : Sample(1),
      liquidityCode : Sample(1),
      separator12   : Sample(1),
      clearingCode  : Sample(1) ]

EncodePreviousExecutionBrokenMessage(message) ==
    message.source
        \o message.separator1
        \o message.user
        \o message.separator2
        \o message.token
        \o message.separator3
        \o message.buySell
        \o message.separator4
        \o message.shares
        \o message.separator5
        \o message.stock
        \o message.separator6
        \o message.price
        \o message.separator7
        \o message.firm
        \o message.separator8
        \o message.reference
        \o message.separator9
        \o message.matchNumber
        \o message.separator10
        \o message.capacity
        \o message.separator11
        \o message.liquidityCode
        \o message.separator12
        \o message.clearingCode

DecodePreviousExecutionBrokenMessage(bytes) ==
    LET source == ReadBytes(bytes, 6) IN IF ~source.ok THEN Fail ELSE
    LET separator1 == ReadBytes(source.rest, 1) IN IF ~separator1.ok THEN Fail ELSE
    LET user == ReadBytes(separator1.rest, 4) IN IF ~user.ok THEN Fail ELSE
    LET separator2 == ReadBytes(user.rest, 1) IN IF ~separator2.ok THEN Fail ELSE
    LET token == ReadBytes(separator2.rest, 10) IN IF ~token.ok THEN Fail ELSE
    LET separator3 == ReadBytes(token.rest, 1) IN IF ~separator3.ok THEN Fail ELSE
    LET buySell == ReadBytes(separator3.rest, 1) IN IF ~buySell.ok THEN Fail ELSE
    LET separator4 == ReadBytes(buySell.rest, 1) IN IF ~separator4.ok THEN Fail ELSE
    LET shares == ReadBytes(separator4.rest, 9) IN IF ~shares.ok THEN Fail ELSE
    LET separator5 == ReadBytes(shares.rest, 1) IN IF ~separator5.ok THEN Fail ELSE
    LET stock == ReadBytes(separator5.rest, 6) IN IF ~stock.ok THEN Fail ELSE
    LET separator6 == ReadBytes(stock.rest, 1) IN IF ~separator6.ok THEN Fail ELSE
    LET price == ReadBytes(separator6.rest, 20) IN IF ~price.ok THEN Fail ELSE
    LET separator7 == ReadBytes(price.rest, 1) IN IF ~separator7.ok THEN Fail ELSE
    LET firm == ReadBytes(separator7.rest, 4) IN IF ~firm.ok THEN Fail ELSE
    LET separator8 == ReadBytes(firm.rest, 1) IN IF ~separator8.ok THEN Fail ELSE
    LET reference == ReadBytes(separator8.rest, 9) IN IF ~reference.ok THEN Fail ELSE
    LET separator9 == ReadBytes(reference.rest, 1) IN IF ~separator9.ok THEN Fail ELSE
    LET matchNumber == ReadBytes(separator9.rest, 9) IN IF ~matchNumber.ok THEN Fail ELSE
    LET separator10 == ReadBytes(matchNumber.rest, 1) IN IF ~separator10.ok THEN Fail ELSE
    LET capacity == ReadBytes(separator10.rest, 1) IN IF ~capacity.ok THEN Fail ELSE
    LET separator11 == ReadBytes(capacity.rest, 1) IN IF ~separator11.ok THEN Fail ELSE
    LET liquidityCode == ReadBytes(separator11.rest, 1) IN IF ~liquidityCode.ok THEN Fail ELSE
    LET separator12 == ReadBytes(liquidityCode.rest, 1) IN IF ~separator12.ok THEN Fail ELSE
    LET clearingCode == ReadBytes(separator12.rest, 1) IN IF ~clearingCode.ok THEN Fail ELSE
    Ok([ source        |-> source.value,
         separator1    |-> separator1.value,
         user          |-> user.value,
         separator2    |-> separator2.value,
         token         |-> token.value,
         separator3    |-> separator3.value,
         buySell       |-> buySell.value,
         separator4    |-> separator4.value,
         shares        |-> shares.value,
         separator5    |-> separator5.value,
         stock         |-> stock.value,
         separator6    |-> separator6.value,
         price         |-> price.value,
         separator7    |-> separator7.value,
         firm          |-> firm.value,
         separator8    |-> separator8.value,
         reference     |-> reference.value,
         separator9    |-> separator9.value,
         matchNumber   |-> matchNumber.value,
         separator10   |-> separator10.value,
         capacity      |-> capacity.value,
         separator11   |-> separator11.value,
         liquidityCode |-> liquidityCode.value,
         separator12   |-> separator12.value,
         clearingCode  |-> clearingCode.value ], clearingCode.rest)

ZeroPreviousExecutionBrokenMessage ==
    [ source        |-> [i \in 1 .. 6 |-> 0],
      separator1    |-> [i \in 1 .. 1 |-> 0],
      user          |-> [i \in 1 .. 4 |-> 0],
      separator2    |-> [i \in 1 .. 1 |-> 0],
      token         |-> [i \in 1 .. 10 |-> 0],
      separator3    |-> [i \in 1 .. 1 |-> 0],
      buySell       |-> [i \in 1 .. 1 |-> 0],
      separator4    |-> [i \in 1 .. 1 |-> 0],
      shares        |-> [i \in 1 .. 9 |-> 0],
      separator5    |-> [i \in 1 .. 1 |-> 0],
      stock         |-> [i \in 1 .. 6 |-> 0],
      separator6    |-> [i \in 1 .. 1 |-> 0],
      price         |-> [i \in 1 .. 20 |-> 0],
      separator7    |-> [i \in 1 .. 1 |-> 0],
      firm          |-> [i \in 1 .. 4 |-> 0],
      separator8    |-> [i \in 1 .. 1 |-> 0],
      reference     |-> [i \in 1 .. 9 |-> 0],
      separator9    |-> [i \in 1 .. 1 |-> 0],
      matchNumber   |-> [i \in 1 .. 9 |-> 0],
      separator10   |-> [i \in 1 .. 1 |-> 0],
      capacity      |-> [i \in 1 .. 1 |-> 0],
      separator11   |-> [i \in 1 .. 1 |-> 0],
      liquidityCode |-> [i \in 1 .. 1 |-> 0],
      separator12   |-> [i \in 1 .. 1 |-> 0],
      clearingCode  |-> [i \in 1 .. 1 |-> 0] ]

(* Previous Execution Broken Message at zero, then each field in turn at the values it is checked at *)
CheckedPreviousExecutionBrokenMessage ==
    { ZeroPreviousExecutionBrokenMessage }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.source = one] : one \in Sample(6) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator1 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.user = one] : one \in Sample(4) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator2 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.token = one] : one \in Sample(10) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator3 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.buySell = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator4 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.shares = one] : one \in Sample(9) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator5 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.stock = one] : one \in Sample(6) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator6 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.price = one] : one \in Sample(20) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator7 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.firm = one] : one \in Sample(4) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator8 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.reference = one] : one \in Sample(9) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator9 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.matchNumber = one] : one \in Sample(9) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator10 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.capacity = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator11 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.liquidityCode = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.separator12 = one] : one \in Sample(1) }
        \cup { [ZeroPreviousExecutionBrokenMessage EXCEPT !.clearingCode = one] : one \in Sample(1) }

(***************************************************************************)
(* Message, selected by Message Type                                       *)
(***************************************************************************)

NewOrderAcceptedMessageCode == 65  \* "A"
ExistingOrderExecutedMessageCode == 69  \* "E"
ExistingOrderCanceledMessageCode == 88  \* "X"
PreviousExecutionBrokenMessageCode == 66  \* "B"

Message ==
    [ tag : {NewOrderAcceptedMessageCode}, body : NewOrderAcceptedMessage ]
        \cup [ tag : {ExistingOrderExecutedMessageCode}, body : ExistingOrderExecutedMessage ]
        \cup [ tag : {ExistingOrderCanceledMessageCode}, body : ExistingOrderCanceledMessage ]
        \cup [ tag : {PreviousExecutionBrokenMessageCode}, body : PreviousExecutionBrokenMessage ]

EncodeMessage(message) ==
    CASE message.tag = NewOrderAcceptedMessageCode -> EncodeNewOrderAcceptedMessage(message.body)
      [] message.tag = ExistingOrderExecutedMessageCode -> EncodeExistingOrderExecutedMessage(message.body)
      [] message.tag = ExistingOrderCanceledMessageCode -> EncodeExistingOrderCanceledMessage(message.body)
      [] message.tag = PreviousExecutionBrokenMessageCode -> EncodePreviousExecutionBrokenMessage(message.body)

DecodeMessage(tag, bytes) ==
    LET read ==
            CASE tag = NewOrderAcceptedMessageCode -> DecodeNewOrderAcceptedMessage(bytes)
              [] tag = ExistingOrderExecutedMessageCode -> DecodeExistingOrderExecutedMessage(bytes)
              [] tag = ExistingOrderCanceledMessageCode -> DecodeExistingOrderCanceledMessage(bytes)
              [] tag = PreviousExecutionBrokenMessageCode -> DecodePreviousExecutionBrokenMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessage == [tag |-> NewOrderAcceptedMessageCode, body |-> ZeroNewOrderAcceptedMessage]

(* Each Message in turn, at the values the message it names is checked at *)
CheckedMessage ==
    { [tag |-> NewOrderAcceptedMessageCode, body |-> one] : one \in CheckedNewOrderAcceptedMessage }
        \cup { [tag |-> ExistingOrderExecutedMessageCode, body |-> one] : one \in CheckedExistingOrderExecutedMessage }
        \cup { [tag |-> ExistingOrderCanceledMessageCode, body |-> one] : one \in CheckedExistingOrderCanceledMessage }
        \cup { [tag |-> PreviousExecutionBrokenMessageCode, body |-> one] : one \in CheckedPreviousExecutionBrokenMessage }

(***************************************************************************)
(* Line                                                                    *)
(***************************************************************************)

Line ==
    [ timeStamp : Sample(9),
      comma     : Sample(1),
      message   : Message,
      cr        : Sample(1),
      lf        : Sample(1) ]

EncodeLine(message) ==
    message.timeStamp
        \o message.comma
        \o EncodeUIntBE(message.message.tag, 1)
        \o EncodeMessage(message.message)
        \o message.cr
        \o message.lf

DecodeLine(bytes) ==
    LET timeStamp == ReadBytes(bytes, 9) IN IF ~timeStamp.ok THEN Fail ELSE
    LET comma == ReadBytes(timeStamp.rest, 1) IN IF ~comma.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(comma.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    LET message == DecodeMessage(messageType.value, messageType.rest) IN IF ~message.ok THEN Fail ELSE
    LET cr == ReadBytes(message.rest, 1) IN IF ~cr.ok THEN Fail ELSE
    LET lf == ReadBytes(cr.rest, 1) IN IF ~lf.ok THEN Fail ELSE
    Ok([ timeStamp |-> timeStamp.value,
         comma     |-> comma.value,
         message   |-> message.value,
         cr        |-> cr.value,
         lf        |-> lf.value ], lf.rest)

ZeroLine ==
    [ timeStamp |-> [i \in 1 .. 9 |-> 0],
      comma     |-> [i \in 1 .. 1 |-> 0],
      message   |-> ZeroMessage,
      cr        |-> [i \in 1 .. 1 |-> 0],
      lf        |-> [i \in 1 .. 1 |-> 0] ]

(* Line at zero, then each field in turn at the values it is checked at *)
CheckedLine ==
    { ZeroLine }
        \cup { [ZeroLine EXCEPT !.timeStamp = one] : one \in Sample(9) }
        \cup { [ZeroLine EXCEPT !.comma = one] : one \in Sample(1) }
        \cup { [ZeroLine EXCEPT !.message = one] : one \in CheckedMessage }
        \cup { [ZeroLine EXCEPT !.cr = one] : one \in Sample(1) }
        \cup { [ZeroLine EXCEPT !.lf = one] : one \in Sample(1) }

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

(* Every Line decodes back to what was encoded, and leaves nothing over *)
RoundTripLine ==
    \A message \in CheckedLine :
        LET read == DecodeLine(EncodeLine(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Message is selected by the Message Type it is written under *)
SelectsMessage ==
    \A message \in CheckedMessage :
        LET read == DecodeMessage(message.tag, EncodeMessage(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
