------------- MODULE BoxOptions_SolaTradeReporting_v4_5_Server -------------
(***************************************************************************)
(* Box Options Market Sola Trade Reporting v4.5                            *)
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
(*                                                                         *)
(* Note: Server Sola Frame is of no one width: each is read by its own     *)
(* fields, and since every reading of it takes at least 29 bytes off the   *)
(* reader the run ends where the data does.                                *)
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

(* The integer a text protocol writes as the characters of itself: a count of one is *)
(* the character "1", which is the byte 49. Read by its digits, and written back *)
(* zero filled to the width the field states, which is how such a field is filled. *)
Digit == 48 .. 57

RECURSIVE DecodeDigits(_)
DecodeDigits(bytes) ==
    IF bytes = << >>
    THEN 0
    ELSE DecodeDigits(SubSeq(bytes, 1, Len(bytes) - 1)) * 10 + (bytes[Len(bytes)] - 48)

RECURSIVE EncodeDigits(_, _)
EncodeDigits(value, width) ==
    IF width = 0
    THEN << >>
    ELSE EncodeDigits(value \div 10, width - 1) \o <<48 + (value % 10)>>

(* A field written as digits that holds anything else is no number, so it is not read: *)
(* the value would not be what the bytes say, and would not write back as them. *)
ReadDigits(bytes, width) ==
    IF Len(bytes) < width \/ \E i \in 1 .. width : bytes[i] \notin Digit
    THEN Fail
    ELSE Ok(DecodeDigits(SubSeq(bytes, 1, width)), SubSeq(bytes, width + 1, Len(bytes)))

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
(* Client Signon Acknowledgment: 8 bytes                                   *)
(***************************************************************************)

ClientSignonAcknowledgment ==
    [ lastUserSequenceNumber : Sample(8) ]

EncodeClientSignonAcknowledgment(message) ==
    message.lastUserSequenceNumber

DecodeClientSignonAcknowledgment(bytes) ==
    LET lastUserSequenceNumber == ReadBytes(bytes, 8) IN IF ~lastUserSequenceNumber.ok THEN Fail ELSE
    Ok([ lastUserSequenceNumber |-> lastUserSequenceNumber.value ], lastUserSequenceNumber.rest)

ZeroClientSignonAcknowledgment ==
    [ lastUserSequenceNumber |-> [i \in 1 .. 8 |-> 0] ]

(* Client Signon Acknowledgment at zero, then each field in turn at the values it is checked at *)
CheckedClientSignonAcknowledgment ==
    { ZeroClientSignonAcknowledgment }
        \cup { [ZeroClientSignonAcknowledgment EXCEPT !.lastUserSequenceNumber = one] : one \in Sample(8) }

(***************************************************************************)
(* Trade: 200 bytes                                                        *)
(***************************************************************************)

Trade ==
    [ tradeNumber                  : Sample(15),
      transactionType              : Sample(1),
      timestamp                    : Sample(6),
      symbol                       : Sample(30),
      expirationDate               : Sample(6),
      strikePrice                  : Sample(8),
      strikePriceFractionIndicator : Sample(1),
      optionType                   : Sample(1),
      volume                       : Sample(8),
      price                        : Sample(8),
      cmtaBroker                   : Sample(4),
      accountType                  : Sample(1),
      subTraderId                  : Sample(3),
      openClose                    : Sample(1),
      executingBroker              : Sample(4),
      clientAccountNumber          : Sample(12),
      clientOrderId                : Sample(20),
      clientMemo                   : Sample(16),
      liquidityStatus              : Sample(1),
      tradeType                    : Sample(1),
      oppositeAccountType          : Sample(1),
      participantSessionName       : Sample(12),
      uniqueTransactionId          : Sample(10),
      parentTransactionId          : Sample(10),
      oppositeExecutingBroker      : Sample(4),
      additionalClientMemo         : Sample(16) ]

EncodeTrade(message) ==
    message.tradeNumber
        \o message.transactionType
        \o message.timestamp
        \o message.symbol
        \o message.expirationDate
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.optionType
        \o message.volume
        \o message.price
        \o message.cmtaBroker
        \o message.accountType
        \o message.subTraderId
        \o message.openClose
        \o message.executingBroker
        \o message.clientAccountNumber
        \o message.clientOrderId
        \o message.clientMemo
        \o message.liquidityStatus
        \o message.tradeType
        \o message.oppositeAccountType
        \o message.participantSessionName
        \o message.uniqueTransactionId
        \o message.parentTransactionId
        \o message.oppositeExecutingBroker
        \o message.additionalClientMemo

DecodeTrade(bytes) ==
    LET tradeNumber == ReadBytes(bytes, 15) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET transactionType == ReadBytes(tradeNumber.rest, 1) IN IF ~transactionType.ok THEN Fail ELSE
    LET timestamp == ReadBytes(transactionType.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(symbol.rest, 6) IN IF ~expirationDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expirationDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePriceFractionIndicator.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET volume == ReadBytes(optionType.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET cmtaBroker == ReadBytes(price.rest, 4) IN IF ~cmtaBroker.ok THEN Fail ELSE
    LET accountType == ReadBytes(cmtaBroker.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET subTraderId == ReadBytes(accountType.rest, 3) IN IF ~subTraderId.ok THEN Fail ELSE
    LET openClose == ReadBytes(subTraderId.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET executingBroker == ReadBytes(openClose.rest, 4) IN IF ~executingBroker.ok THEN Fail ELSE
    LET clientAccountNumber == ReadBytes(executingBroker.rest, 12) IN IF ~clientAccountNumber.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientAccountNumber.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET clientMemo == ReadBytes(clientOrderId.rest, 16) IN IF ~clientMemo.ok THEN Fail ELSE
    LET liquidityStatus == ReadBytes(clientMemo.rest, 1) IN IF ~liquidityStatus.ok THEN Fail ELSE
    LET tradeType == ReadBytes(liquidityStatus.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET oppositeAccountType == ReadBytes(tradeType.rest, 1) IN IF ~oppositeAccountType.ok THEN Fail ELSE
    LET participantSessionName == ReadBytes(oppositeAccountType.rest, 12) IN IF ~participantSessionName.ok THEN Fail ELSE
    LET uniqueTransactionId == ReadBytes(participantSessionName.rest, 10) IN IF ~uniqueTransactionId.ok THEN Fail ELSE
    LET parentTransactionId == ReadBytes(uniqueTransactionId.rest, 10) IN IF ~parentTransactionId.ok THEN Fail ELSE
    LET oppositeExecutingBroker == ReadBytes(parentTransactionId.rest, 4) IN IF ~oppositeExecutingBroker.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(oppositeExecutingBroker.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    Ok([ tradeNumber                  |-> tradeNumber.value,
         transactionType              |-> transactionType.value,
         timestamp                    |-> timestamp.value,
         symbol                       |-> symbol.value,
         expirationDate               |-> expirationDate.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         optionType                   |-> optionType.value,
         volume                       |-> volume.value,
         price                        |-> price.value,
         cmtaBroker                   |-> cmtaBroker.value,
         accountType                  |-> accountType.value,
         subTraderId                  |-> subTraderId.value,
         openClose                    |-> openClose.value,
         executingBroker              |-> executingBroker.value,
         clientAccountNumber          |-> clientAccountNumber.value,
         clientOrderId                |-> clientOrderId.value,
         clientMemo                   |-> clientMemo.value,
         liquidityStatus              |-> liquidityStatus.value,
         tradeType                    |-> tradeType.value,
         oppositeAccountType          |-> oppositeAccountType.value,
         participantSessionName       |-> participantSessionName.value,
         uniqueTransactionId          |-> uniqueTransactionId.value,
         parentTransactionId          |-> parentTransactionId.value,
         oppositeExecutingBroker      |-> oppositeExecutingBroker.value,
         additionalClientMemo         |-> additionalClientMemo.value ], additionalClientMemo.rest)

ZeroTrade ==
    [ tradeNumber                  |-> [i \in 1 .. 15 |-> 0],
      transactionType              |-> [i \in 1 .. 1 |-> 0],
      timestamp                    |-> [i \in 1 .. 6 |-> 0],
      symbol                       |-> [i \in 1 .. 30 |-> 0],
      expirationDate               |-> [i \in 1 .. 6 |-> 0],
      strikePrice                  |-> [i \in 1 .. 8 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      optionType                   |-> [i \in 1 .. 1 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0],
      price                        |-> [i \in 1 .. 8 |-> 0],
      cmtaBroker                   |-> [i \in 1 .. 4 |-> 0],
      accountType                  |-> [i \in 1 .. 1 |-> 0],
      subTraderId                  |-> [i \in 1 .. 3 |-> 0],
      openClose                    |-> [i \in 1 .. 1 |-> 0],
      executingBroker              |-> [i \in 1 .. 4 |-> 0],
      clientAccountNumber          |-> [i \in 1 .. 12 |-> 0],
      clientOrderId                |-> [i \in 1 .. 20 |-> 0],
      clientMemo                   |-> [i \in 1 .. 16 |-> 0],
      liquidityStatus              |-> [i \in 1 .. 1 |-> 0],
      tradeType                    |-> [i \in 1 .. 1 |-> 0],
      oppositeAccountType          |-> [i \in 1 .. 1 |-> 0],
      participantSessionName       |-> [i \in 1 .. 12 |-> 0],
      uniqueTransactionId          |-> [i \in 1 .. 10 |-> 0],
      parentTransactionId          |-> [i \in 1 .. 10 |-> 0],
      oppositeExecutingBroker      |-> [i \in 1 .. 4 |-> 0],
      additionalClientMemo         |-> [i \in 1 .. 16 |-> 0] ]

(* Trade at zero, then each field in turn at the values it is checked at *)
CheckedTrade ==
    { ZeroTrade }
        \cup { [ZeroTrade EXCEPT !.tradeNumber = one] : one \in Sample(15) }
        \cup { [ZeroTrade EXCEPT !.transactionType = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroTrade EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroTrade EXCEPT !.expirationDate = one] : one \in Sample(6) }
        \cup { [ZeroTrade EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTrade EXCEPT !.cmtaBroker = one] : one \in Sample(4) }
        \cup { [ZeroTrade EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.subTraderId = one] : one \in Sample(3) }
        \cup { [ZeroTrade EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.executingBroker = one] : one \in Sample(4) }
        \cup { [ZeroTrade EXCEPT !.clientAccountNumber = one] : one \in Sample(12) }
        \cup { [ZeroTrade EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroTrade EXCEPT !.clientMemo = one] : one \in Sample(16) }
        \cup { [ZeroTrade EXCEPT !.liquidityStatus = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.oppositeAccountType = one] : one \in Sample(1) }
        \cup { [ZeroTrade EXCEPT !.participantSessionName = one] : one \in Sample(12) }
        \cup { [ZeroTrade EXCEPT !.uniqueTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroTrade EXCEPT !.parentTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroTrade EXCEPT !.oppositeExecutingBroker = one] : one \in Sample(4) }
        \cup { [ZeroTrade EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }

(***************************************************************************)
(* Trade Cancel: 200 bytes                                                 *)
(***************************************************************************)

TradeCancel ==
    [ tradeNumber                  : Sample(15),
      transactionType              : Sample(1),
      timestamp                    : Sample(6),
      symbol                       : Sample(30),
      expirationDate               : Sample(6),
      strikePrice                  : Sample(8),
      strikePriceFractionIndicator : Sample(1),
      optionType                   : Sample(1),
      volume                       : Sample(8),
      price                        : Sample(8),
      cmtaBroker                   : Sample(4),
      accountType                  : Sample(1),
      subTraderId                  : Sample(3),
      openClose                    : Sample(1),
      executingBroker              : Sample(4),
      clientAccountNumber          : Sample(12),
      clientOrderId                : Sample(20),
      clientMemo                   : Sample(16),
      liquidityStatus              : Sample(1),
      tradeType                    : Sample(1),
      oppositeAccountType          : Sample(1),
      participantSessionName       : Sample(12),
      uniqueTransactionId          : Sample(10),
      parentTransactionId          : Sample(10),
      oppositeExecutingBroker      : Sample(4),
      additionalClientMemo         : Sample(16) ]

EncodeTradeCancel(message) ==
    message.tradeNumber
        \o message.transactionType
        \o message.timestamp
        \o message.symbol
        \o message.expirationDate
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.optionType
        \o message.volume
        \o message.price
        \o message.cmtaBroker
        \o message.accountType
        \o message.subTraderId
        \o message.openClose
        \o message.executingBroker
        \o message.clientAccountNumber
        \o message.clientOrderId
        \o message.clientMemo
        \o message.liquidityStatus
        \o message.tradeType
        \o message.oppositeAccountType
        \o message.participantSessionName
        \o message.uniqueTransactionId
        \o message.parentTransactionId
        \o message.oppositeExecutingBroker
        \o message.additionalClientMemo

DecodeTradeCancel(bytes) ==
    LET tradeNumber == ReadBytes(bytes, 15) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET transactionType == ReadBytes(tradeNumber.rest, 1) IN IF ~transactionType.ok THEN Fail ELSE
    LET timestamp == ReadBytes(transactionType.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(symbol.rest, 6) IN IF ~expirationDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expirationDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePriceFractionIndicator.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET volume == ReadBytes(optionType.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET cmtaBroker == ReadBytes(price.rest, 4) IN IF ~cmtaBroker.ok THEN Fail ELSE
    LET accountType == ReadBytes(cmtaBroker.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET subTraderId == ReadBytes(accountType.rest, 3) IN IF ~subTraderId.ok THEN Fail ELSE
    LET openClose == ReadBytes(subTraderId.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET executingBroker == ReadBytes(openClose.rest, 4) IN IF ~executingBroker.ok THEN Fail ELSE
    LET clientAccountNumber == ReadBytes(executingBroker.rest, 12) IN IF ~clientAccountNumber.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientAccountNumber.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET clientMemo == ReadBytes(clientOrderId.rest, 16) IN IF ~clientMemo.ok THEN Fail ELSE
    LET liquidityStatus == ReadBytes(clientMemo.rest, 1) IN IF ~liquidityStatus.ok THEN Fail ELSE
    LET tradeType == ReadBytes(liquidityStatus.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET oppositeAccountType == ReadBytes(tradeType.rest, 1) IN IF ~oppositeAccountType.ok THEN Fail ELSE
    LET participantSessionName == ReadBytes(oppositeAccountType.rest, 12) IN IF ~participantSessionName.ok THEN Fail ELSE
    LET uniqueTransactionId == ReadBytes(participantSessionName.rest, 10) IN IF ~uniqueTransactionId.ok THEN Fail ELSE
    LET parentTransactionId == ReadBytes(uniqueTransactionId.rest, 10) IN IF ~parentTransactionId.ok THEN Fail ELSE
    LET oppositeExecutingBroker == ReadBytes(parentTransactionId.rest, 4) IN IF ~oppositeExecutingBroker.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(oppositeExecutingBroker.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    Ok([ tradeNumber                  |-> tradeNumber.value,
         transactionType              |-> transactionType.value,
         timestamp                    |-> timestamp.value,
         symbol                       |-> symbol.value,
         expirationDate               |-> expirationDate.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         optionType                   |-> optionType.value,
         volume                       |-> volume.value,
         price                        |-> price.value,
         cmtaBroker                   |-> cmtaBroker.value,
         accountType                  |-> accountType.value,
         subTraderId                  |-> subTraderId.value,
         openClose                    |-> openClose.value,
         executingBroker              |-> executingBroker.value,
         clientAccountNumber          |-> clientAccountNumber.value,
         clientOrderId                |-> clientOrderId.value,
         clientMemo                   |-> clientMemo.value,
         liquidityStatus              |-> liquidityStatus.value,
         tradeType                    |-> tradeType.value,
         oppositeAccountType          |-> oppositeAccountType.value,
         participantSessionName       |-> participantSessionName.value,
         uniqueTransactionId          |-> uniqueTransactionId.value,
         parentTransactionId          |-> parentTransactionId.value,
         oppositeExecutingBroker      |-> oppositeExecutingBroker.value,
         additionalClientMemo         |-> additionalClientMemo.value ], additionalClientMemo.rest)

ZeroTradeCancel ==
    [ tradeNumber                  |-> [i \in 1 .. 15 |-> 0],
      transactionType              |-> [i \in 1 .. 1 |-> 0],
      timestamp                    |-> [i \in 1 .. 6 |-> 0],
      symbol                       |-> [i \in 1 .. 30 |-> 0],
      expirationDate               |-> [i \in 1 .. 6 |-> 0],
      strikePrice                  |-> [i \in 1 .. 8 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      optionType                   |-> [i \in 1 .. 1 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0],
      price                        |-> [i \in 1 .. 8 |-> 0],
      cmtaBroker                   |-> [i \in 1 .. 4 |-> 0],
      accountType                  |-> [i \in 1 .. 1 |-> 0],
      subTraderId                  |-> [i \in 1 .. 3 |-> 0],
      openClose                    |-> [i \in 1 .. 1 |-> 0],
      executingBroker              |-> [i \in 1 .. 4 |-> 0],
      clientAccountNumber          |-> [i \in 1 .. 12 |-> 0],
      clientOrderId                |-> [i \in 1 .. 20 |-> 0],
      clientMemo                   |-> [i \in 1 .. 16 |-> 0],
      liquidityStatus              |-> [i \in 1 .. 1 |-> 0],
      tradeType                    |-> [i \in 1 .. 1 |-> 0],
      oppositeAccountType          |-> [i \in 1 .. 1 |-> 0],
      participantSessionName       |-> [i \in 1 .. 12 |-> 0],
      uniqueTransactionId          |-> [i \in 1 .. 10 |-> 0],
      parentTransactionId          |-> [i \in 1 .. 10 |-> 0],
      oppositeExecutingBroker      |-> [i \in 1 .. 4 |-> 0],
      additionalClientMemo         |-> [i \in 1 .. 16 |-> 0] ]

(* Trade Cancel at zero, then each field in turn at the values it is checked at *)
CheckedTradeCancel ==
    { ZeroTradeCancel }
        \cup { [ZeroTradeCancel EXCEPT !.tradeNumber = one] : one \in Sample(15) }
        \cup { [ZeroTradeCancel EXCEPT !.transactionType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancel EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroTradeCancel EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroTradeCancel EXCEPT !.expirationDate = one] : one \in Sample(6) }
        \cup { [ZeroTradeCancel EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancel EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancel EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancel EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancel EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroTradeCancel EXCEPT !.cmtaBroker = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancel EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancel EXCEPT !.subTraderId = one] : one \in Sample(3) }
        \cup { [ZeroTradeCancel EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancel EXCEPT !.executingBroker = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancel EXCEPT !.clientAccountNumber = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancel EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroTradeCancel EXCEPT !.clientMemo = one] : one \in Sample(16) }
        \cup { [ZeroTradeCancel EXCEPT !.liquidityStatus = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancel EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancel EXCEPT !.oppositeAccountType = one] : one \in Sample(1) }
        \cup { [ZeroTradeCancel EXCEPT !.participantSessionName = one] : one \in Sample(12) }
        \cup { [ZeroTradeCancel EXCEPT !.uniqueTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancel EXCEPT !.parentTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroTradeCancel EXCEPT !.oppositeExecutingBroker = one] : one \in Sample(4) }
        \cup { [ZeroTradeCancel EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }

(***************************************************************************)
(* Allocation: 200 bytes                                                   *)
(***************************************************************************)

Allocation ==
    [ tradeNumber                  : Sample(15),
      transactionType              : Sample(1),
      timestamp                    : Sample(6),
      symbol                       : Sample(30),
      expirationDate               : Sample(6),
      strikePrice                  : Sample(8),
      strikePriceFractionIndicator : Sample(1),
      optionType                   : Sample(1),
      volume                       : Sample(8),
      price                        : Sample(8),
      cmtaBroker                   : Sample(4),
      accountType                  : Sample(1),
      subTraderId                  : Sample(3),
      openClose                    : Sample(1),
      executingBroker              : Sample(4),
      clientAccountNumber          : Sample(12),
      clientOrderId                : Sample(20),
      clientMemo                   : Sample(16),
      liquidityStatus              : Sample(1),
      tradeType                    : Sample(1),
      oppositeAccountType          : Sample(1),
      participantSessionName       : Sample(12),
      uniqueTransactionId          : Sample(10),
      parentTransactionId          : Sample(10),
      oppositeExecutingBroker      : Sample(4),
      additionalClientMemo         : Sample(16) ]

EncodeAllocation(message) ==
    message.tradeNumber
        \o message.transactionType
        \o message.timestamp
        \o message.symbol
        \o message.expirationDate
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.optionType
        \o message.volume
        \o message.price
        \o message.cmtaBroker
        \o message.accountType
        \o message.subTraderId
        \o message.openClose
        \o message.executingBroker
        \o message.clientAccountNumber
        \o message.clientOrderId
        \o message.clientMemo
        \o message.liquidityStatus
        \o message.tradeType
        \o message.oppositeAccountType
        \o message.participantSessionName
        \o message.uniqueTransactionId
        \o message.parentTransactionId
        \o message.oppositeExecutingBroker
        \o message.additionalClientMemo

DecodeAllocation(bytes) ==
    LET tradeNumber == ReadBytes(bytes, 15) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET transactionType == ReadBytes(tradeNumber.rest, 1) IN IF ~transactionType.ok THEN Fail ELSE
    LET timestamp == ReadBytes(transactionType.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(symbol.rest, 6) IN IF ~expirationDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expirationDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePriceFractionIndicator.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET volume == ReadBytes(optionType.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET cmtaBroker == ReadBytes(price.rest, 4) IN IF ~cmtaBroker.ok THEN Fail ELSE
    LET accountType == ReadBytes(cmtaBroker.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET subTraderId == ReadBytes(accountType.rest, 3) IN IF ~subTraderId.ok THEN Fail ELSE
    LET openClose == ReadBytes(subTraderId.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET executingBroker == ReadBytes(openClose.rest, 4) IN IF ~executingBroker.ok THEN Fail ELSE
    LET clientAccountNumber == ReadBytes(executingBroker.rest, 12) IN IF ~clientAccountNumber.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientAccountNumber.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET clientMemo == ReadBytes(clientOrderId.rest, 16) IN IF ~clientMemo.ok THEN Fail ELSE
    LET liquidityStatus == ReadBytes(clientMemo.rest, 1) IN IF ~liquidityStatus.ok THEN Fail ELSE
    LET tradeType == ReadBytes(liquidityStatus.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET oppositeAccountType == ReadBytes(tradeType.rest, 1) IN IF ~oppositeAccountType.ok THEN Fail ELSE
    LET participantSessionName == ReadBytes(oppositeAccountType.rest, 12) IN IF ~participantSessionName.ok THEN Fail ELSE
    LET uniqueTransactionId == ReadBytes(participantSessionName.rest, 10) IN IF ~uniqueTransactionId.ok THEN Fail ELSE
    LET parentTransactionId == ReadBytes(uniqueTransactionId.rest, 10) IN IF ~parentTransactionId.ok THEN Fail ELSE
    LET oppositeExecutingBroker == ReadBytes(parentTransactionId.rest, 4) IN IF ~oppositeExecutingBroker.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(oppositeExecutingBroker.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    Ok([ tradeNumber                  |-> tradeNumber.value,
         transactionType              |-> transactionType.value,
         timestamp                    |-> timestamp.value,
         symbol                       |-> symbol.value,
         expirationDate               |-> expirationDate.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         optionType                   |-> optionType.value,
         volume                       |-> volume.value,
         price                        |-> price.value,
         cmtaBroker                   |-> cmtaBroker.value,
         accountType                  |-> accountType.value,
         subTraderId                  |-> subTraderId.value,
         openClose                    |-> openClose.value,
         executingBroker              |-> executingBroker.value,
         clientAccountNumber          |-> clientAccountNumber.value,
         clientOrderId                |-> clientOrderId.value,
         clientMemo                   |-> clientMemo.value,
         liquidityStatus              |-> liquidityStatus.value,
         tradeType                    |-> tradeType.value,
         oppositeAccountType          |-> oppositeAccountType.value,
         participantSessionName       |-> participantSessionName.value,
         uniqueTransactionId          |-> uniqueTransactionId.value,
         parentTransactionId          |-> parentTransactionId.value,
         oppositeExecutingBroker      |-> oppositeExecutingBroker.value,
         additionalClientMemo         |-> additionalClientMemo.value ], additionalClientMemo.rest)

ZeroAllocation ==
    [ tradeNumber                  |-> [i \in 1 .. 15 |-> 0],
      transactionType              |-> [i \in 1 .. 1 |-> 0],
      timestamp                    |-> [i \in 1 .. 6 |-> 0],
      symbol                       |-> [i \in 1 .. 30 |-> 0],
      expirationDate               |-> [i \in 1 .. 6 |-> 0],
      strikePrice                  |-> [i \in 1 .. 8 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      optionType                   |-> [i \in 1 .. 1 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0],
      price                        |-> [i \in 1 .. 8 |-> 0],
      cmtaBroker                   |-> [i \in 1 .. 4 |-> 0],
      accountType                  |-> [i \in 1 .. 1 |-> 0],
      subTraderId                  |-> [i \in 1 .. 3 |-> 0],
      openClose                    |-> [i \in 1 .. 1 |-> 0],
      executingBroker              |-> [i \in 1 .. 4 |-> 0],
      clientAccountNumber          |-> [i \in 1 .. 12 |-> 0],
      clientOrderId                |-> [i \in 1 .. 20 |-> 0],
      clientMemo                   |-> [i \in 1 .. 16 |-> 0],
      liquidityStatus              |-> [i \in 1 .. 1 |-> 0],
      tradeType                    |-> [i \in 1 .. 1 |-> 0],
      oppositeAccountType          |-> [i \in 1 .. 1 |-> 0],
      participantSessionName       |-> [i \in 1 .. 12 |-> 0],
      uniqueTransactionId          |-> [i \in 1 .. 10 |-> 0],
      parentTransactionId          |-> [i \in 1 .. 10 |-> 0],
      oppositeExecutingBroker      |-> [i \in 1 .. 4 |-> 0],
      additionalClientMemo         |-> [i \in 1 .. 16 |-> 0] ]

(* Allocation at zero, then each field in turn at the values it is checked at *)
CheckedAllocation ==
    { ZeroAllocation }
        \cup { [ZeroAllocation EXCEPT !.tradeNumber = one] : one \in Sample(15) }
        \cup { [ZeroAllocation EXCEPT !.transactionType = one] : one \in Sample(1) }
        \cup { [ZeroAllocation EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroAllocation EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroAllocation EXCEPT !.expirationDate = one] : one \in Sample(6) }
        \cup { [ZeroAllocation EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroAllocation EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAllocation EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroAllocation EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroAllocation EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAllocation EXCEPT !.cmtaBroker = one] : one \in Sample(4) }
        \cup { [ZeroAllocation EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroAllocation EXCEPT !.subTraderId = one] : one \in Sample(3) }
        \cup { [ZeroAllocation EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroAllocation EXCEPT !.executingBroker = one] : one \in Sample(4) }
        \cup { [ZeroAllocation EXCEPT !.clientAccountNumber = one] : one \in Sample(12) }
        \cup { [ZeroAllocation EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroAllocation EXCEPT !.clientMemo = one] : one \in Sample(16) }
        \cup { [ZeroAllocation EXCEPT !.liquidityStatus = one] : one \in Sample(1) }
        \cup { [ZeroAllocation EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroAllocation EXCEPT !.oppositeAccountType = one] : one \in Sample(1) }
        \cup { [ZeroAllocation EXCEPT !.participantSessionName = one] : one \in Sample(12) }
        \cup { [ZeroAllocation EXCEPT !.uniqueTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroAllocation EXCEPT !.parentTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroAllocation EXCEPT !.oppositeExecutingBroker = one] : one \in Sample(4) }
        \cup { [ZeroAllocation EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }

(***************************************************************************)
(* Allocation Cancel: 200 bytes                                            *)
(***************************************************************************)

AllocationCancel ==
    [ tradeNumber                  : Sample(15),
      transactionType              : Sample(1),
      timestamp                    : Sample(6),
      symbol                       : Sample(30),
      expirationDate               : Sample(6),
      strikePrice                  : Sample(8),
      strikePriceFractionIndicator : Sample(1),
      optionType                   : Sample(1),
      volume                       : Sample(8),
      price                        : Sample(8),
      cmtaBroker                   : Sample(4),
      accountType                  : Sample(1),
      subTraderId                  : Sample(3),
      openClose                    : Sample(1),
      executingBroker              : Sample(4),
      clientAccountNumber          : Sample(12),
      clientOrderId                : Sample(20),
      clientMemo                   : Sample(16),
      liquidityStatus              : Sample(1),
      tradeType                    : Sample(1),
      oppositeAccountType          : Sample(1),
      participantSessionName       : Sample(12),
      uniqueTransactionId          : Sample(10),
      parentTransactionId          : Sample(10),
      oppositeExecutingBroker      : Sample(4),
      additionalClientMemo         : Sample(16) ]

EncodeAllocationCancel(message) ==
    message.tradeNumber
        \o message.transactionType
        \o message.timestamp
        \o message.symbol
        \o message.expirationDate
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.optionType
        \o message.volume
        \o message.price
        \o message.cmtaBroker
        \o message.accountType
        \o message.subTraderId
        \o message.openClose
        \o message.executingBroker
        \o message.clientAccountNumber
        \o message.clientOrderId
        \o message.clientMemo
        \o message.liquidityStatus
        \o message.tradeType
        \o message.oppositeAccountType
        \o message.participantSessionName
        \o message.uniqueTransactionId
        \o message.parentTransactionId
        \o message.oppositeExecutingBroker
        \o message.additionalClientMemo

DecodeAllocationCancel(bytes) ==
    LET tradeNumber == ReadBytes(bytes, 15) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET transactionType == ReadBytes(tradeNumber.rest, 1) IN IF ~transactionType.ok THEN Fail ELSE
    LET timestamp == ReadBytes(transactionType.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(symbol.rest, 6) IN IF ~expirationDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expirationDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePriceFractionIndicator.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET volume == ReadBytes(optionType.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET cmtaBroker == ReadBytes(price.rest, 4) IN IF ~cmtaBroker.ok THEN Fail ELSE
    LET accountType == ReadBytes(cmtaBroker.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET subTraderId == ReadBytes(accountType.rest, 3) IN IF ~subTraderId.ok THEN Fail ELSE
    LET openClose == ReadBytes(subTraderId.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET executingBroker == ReadBytes(openClose.rest, 4) IN IF ~executingBroker.ok THEN Fail ELSE
    LET clientAccountNumber == ReadBytes(executingBroker.rest, 12) IN IF ~clientAccountNumber.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientAccountNumber.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET clientMemo == ReadBytes(clientOrderId.rest, 16) IN IF ~clientMemo.ok THEN Fail ELSE
    LET liquidityStatus == ReadBytes(clientMemo.rest, 1) IN IF ~liquidityStatus.ok THEN Fail ELSE
    LET tradeType == ReadBytes(liquidityStatus.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET oppositeAccountType == ReadBytes(tradeType.rest, 1) IN IF ~oppositeAccountType.ok THEN Fail ELSE
    LET participantSessionName == ReadBytes(oppositeAccountType.rest, 12) IN IF ~participantSessionName.ok THEN Fail ELSE
    LET uniqueTransactionId == ReadBytes(participantSessionName.rest, 10) IN IF ~uniqueTransactionId.ok THEN Fail ELSE
    LET parentTransactionId == ReadBytes(uniqueTransactionId.rest, 10) IN IF ~parentTransactionId.ok THEN Fail ELSE
    LET oppositeExecutingBroker == ReadBytes(parentTransactionId.rest, 4) IN IF ~oppositeExecutingBroker.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(oppositeExecutingBroker.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    Ok([ tradeNumber                  |-> tradeNumber.value,
         transactionType              |-> transactionType.value,
         timestamp                    |-> timestamp.value,
         symbol                       |-> symbol.value,
         expirationDate               |-> expirationDate.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         optionType                   |-> optionType.value,
         volume                       |-> volume.value,
         price                        |-> price.value,
         cmtaBroker                   |-> cmtaBroker.value,
         accountType                  |-> accountType.value,
         subTraderId                  |-> subTraderId.value,
         openClose                    |-> openClose.value,
         executingBroker              |-> executingBroker.value,
         clientAccountNumber          |-> clientAccountNumber.value,
         clientOrderId                |-> clientOrderId.value,
         clientMemo                   |-> clientMemo.value,
         liquidityStatus              |-> liquidityStatus.value,
         tradeType                    |-> tradeType.value,
         oppositeAccountType          |-> oppositeAccountType.value,
         participantSessionName       |-> participantSessionName.value,
         uniqueTransactionId          |-> uniqueTransactionId.value,
         parentTransactionId          |-> parentTransactionId.value,
         oppositeExecutingBroker      |-> oppositeExecutingBroker.value,
         additionalClientMemo         |-> additionalClientMemo.value ], additionalClientMemo.rest)

ZeroAllocationCancel ==
    [ tradeNumber                  |-> [i \in 1 .. 15 |-> 0],
      transactionType              |-> [i \in 1 .. 1 |-> 0],
      timestamp                    |-> [i \in 1 .. 6 |-> 0],
      symbol                       |-> [i \in 1 .. 30 |-> 0],
      expirationDate               |-> [i \in 1 .. 6 |-> 0],
      strikePrice                  |-> [i \in 1 .. 8 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      optionType                   |-> [i \in 1 .. 1 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0],
      price                        |-> [i \in 1 .. 8 |-> 0],
      cmtaBroker                   |-> [i \in 1 .. 4 |-> 0],
      accountType                  |-> [i \in 1 .. 1 |-> 0],
      subTraderId                  |-> [i \in 1 .. 3 |-> 0],
      openClose                    |-> [i \in 1 .. 1 |-> 0],
      executingBroker              |-> [i \in 1 .. 4 |-> 0],
      clientAccountNumber          |-> [i \in 1 .. 12 |-> 0],
      clientOrderId                |-> [i \in 1 .. 20 |-> 0],
      clientMemo                   |-> [i \in 1 .. 16 |-> 0],
      liquidityStatus              |-> [i \in 1 .. 1 |-> 0],
      tradeType                    |-> [i \in 1 .. 1 |-> 0],
      oppositeAccountType          |-> [i \in 1 .. 1 |-> 0],
      participantSessionName       |-> [i \in 1 .. 12 |-> 0],
      uniqueTransactionId          |-> [i \in 1 .. 10 |-> 0],
      parentTransactionId          |-> [i \in 1 .. 10 |-> 0],
      oppositeExecutingBroker      |-> [i \in 1 .. 4 |-> 0],
      additionalClientMemo         |-> [i \in 1 .. 16 |-> 0] ]

(* Allocation Cancel at zero, then each field in turn at the values it is checked at *)
CheckedAllocationCancel ==
    { ZeroAllocationCancel }
        \cup { [ZeroAllocationCancel EXCEPT !.tradeNumber = one] : one \in Sample(15) }
        \cup { [ZeroAllocationCancel EXCEPT !.transactionType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationCancel EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroAllocationCancel EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroAllocationCancel EXCEPT !.expirationDate = one] : one \in Sample(6) }
        \cup { [ZeroAllocationCancel EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroAllocationCancel EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroAllocationCancel EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationCancel EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroAllocationCancel EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroAllocationCancel EXCEPT !.cmtaBroker = one] : one \in Sample(4) }
        \cup { [ZeroAllocationCancel EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationCancel EXCEPT !.subTraderId = one] : one \in Sample(3) }
        \cup { [ZeroAllocationCancel EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroAllocationCancel EXCEPT !.executingBroker = one] : one \in Sample(4) }
        \cup { [ZeroAllocationCancel EXCEPT !.clientAccountNumber = one] : one \in Sample(12) }
        \cup { [ZeroAllocationCancel EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroAllocationCancel EXCEPT !.clientMemo = one] : one \in Sample(16) }
        \cup { [ZeroAllocationCancel EXCEPT !.liquidityStatus = one] : one \in Sample(1) }
        \cup { [ZeroAllocationCancel EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationCancel EXCEPT !.oppositeAccountType = one] : one \in Sample(1) }
        \cup { [ZeroAllocationCancel EXCEPT !.participantSessionName = one] : one \in Sample(12) }
        \cup { [ZeroAllocationCancel EXCEPT !.uniqueTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroAllocationCancel EXCEPT !.parentTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroAllocationCancel EXCEPT !.oppositeExecutingBroker = one] : one \in Sample(4) }
        \cup { [ZeroAllocationCancel EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }

(***************************************************************************)
(* Give Up: 208 bytes                                                      *)
(***************************************************************************)

GiveUp ==
    [ tradeNumber                  : Sample(15),
      transactionType              : Sample(1),
      timestamp                    : Sample(6),
      symbol                       : Sample(30),
      expirationDate               : Sample(6),
      strikePrice                  : Sample(8),
      strikePriceFractionIndicator : Sample(1),
      optionType                   : Sample(1),
      volume                       : Sample(8),
      price                        : Sample(8),
      cmtaBroker                   : Sample(4),
      accountType                  : Sample(1),
      subTraderId                  : Sample(3),
      openClose                    : Sample(1),
      executingBroker              : Sample(4),
      clientAccountNumber          : Sample(12),
      clientOrderId                : Sample(20),
      clientMemo                   : Sample(16),
      liquidityStatus              : Sample(1),
      tradeType                    : Sample(1),
      oppositeAccountType          : Sample(1),
      giveUpSource                 : Sample(4),
      giveUpDestination            : Sample(4),
      participantSessionName       : Sample(12),
      uniqueTransactionId          : Sample(10),
      parentTransactionId          : Sample(10),
      oppositeExecutingBroker      : Sample(4),
      additionalClientMemo         : Sample(16) ]

EncodeGiveUp(message) ==
    message.tradeNumber
        \o message.transactionType
        \o message.timestamp
        \o message.symbol
        \o message.expirationDate
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.optionType
        \o message.volume
        \o message.price
        \o message.cmtaBroker
        \o message.accountType
        \o message.subTraderId
        \o message.openClose
        \o message.executingBroker
        \o message.clientAccountNumber
        \o message.clientOrderId
        \o message.clientMemo
        \o message.liquidityStatus
        \o message.tradeType
        \o message.oppositeAccountType
        \o message.giveUpSource
        \o message.giveUpDestination
        \o message.participantSessionName
        \o message.uniqueTransactionId
        \o message.parentTransactionId
        \o message.oppositeExecutingBroker
        \o message.additionalClientMemo

DecodeGiveUp(bytes) ==
    LET tradeNumber == ReadBytes(bytes, 15) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET transactionType == ReadBytes(tradeNumber.rest, 1) IN IF ~transactionType.ok THEN Fail ELSE
    LET timestamp == ReadBytes(transactionType.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(symbol.rest, 6) IN IF ~expirationDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expirationDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePriceFractionIndicator.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET volume == ReadBytes(optionType.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET cmtaBroker == ReadBytes(price.rest, 4) IN IF ~cmtaBroker.ok THEN Fail ELSE
    LET accountType == ReadBytes(cmtaBroker.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET subTraderId == ReadBytes(accountType.rest, 3) IN IF ~subTraderId.ok THEN Fail ELSE
    LET openClose == ReadBytes(subTraderId.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET executingBroker == ReadBytes(openClose.rest, 4) IN IF ~executingBroker.ok THEN Fail ELSE
    LET clientAccountNumber == ReadBytes(executingBroker.rest, 12) IN IF ~clientAccountNumber.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientAccountNumber.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET clientMemo == ReadBytes(clientOrderId.rest, 16) IN IF ~clientMemo.ok THEN Fail ELSE
    LET liquidityStatus == ReadBytes(clientMemo.rest, 1) IN IF ~liquidityStatus.ok THEN Fail ELSE
    LET tradeType == ReadBytes(liquidityStatus.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET oppositeAccountType == ReadBytes(tradeType.rest, 1) IN IF ~oppositeAccountType.ok THEN Fail ELSE
    LET giveUpSource == ReadBytes(oppositeAccountType.rest, 4) IN IF ~giveUpSource.ok THEN Fail ELSE
    LET giveUpDestination == ReadBytes(giveUpSource.rest, 4) IN IF ~giveUpDestination.ok THEN Fail ELSE
    LET participantSessionName == ReadBytes(giveUpDestination.rest, 12) IN IF ~participantSessionName.ok THEN Fail ELSE
    LET uniqueTransactionId == ReadBytes(participantSessionName.rest, 10) IN IF ~uniqueTransactionId.ok THEN Fail ELSE
    LET parentTransactionId == ReadBytes(uniqueTransactionId.rest, 10) IN IF ~parentTransactionId.ok THEN Fail ELSE
    LET oppositeExecutingBroker == ReadBytes(parentTransactionId.rest, 4) IN IF ~oppositeExecutingBroker.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(oppositeExecutingBroker.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    Ok([ tradeNumber                  |-> tradeNumber.value,
         transactionType              |-> transactionType.value,
         timestamp                    |-> timestamp.value,
         symbol                       |-> symbol.value,
         expirationDate               |-> expirationDate.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         optionType                   |-> optionType.value,
         volume                       |-> volume.value,
         price                        |-> price.value,
         cmtaBroker                   |-> cmtaBroker.value,
         accountType                  |-> accountType.value,
         subTraderId                  |-> subTraderId.value,
         openClose                    |-> openClose.value,
         executingBroker              |-> executingBroker.value,
         clientAccountNumber          |-> clientAccountNumber.value,
         clientOrderId                |-> clientOrderId.value,
         clientMemo                   |-> clientMemo.value,
         liquidityStatus              |-> liquidityStatus.value,
         tradeType                    |-> tradeType.value,
         oppositeAccountType          |-> oppositeAccountType.value,
         giveUpSource                 |-> giveUpSource.value,
         giveUpDestination            |-> giveUpDestination.value,
         participantSessionName       |-> participantSessionName.value,
         uniqueTransactionId          |-> uniqueTransactionId.value,
         parentTransactionId          |-> parentTransactionId.value,
         oppositeExecutingBroker      |-> oppositeExecutingBroker.value,
         additionalClientMemo         |-> additionalClientMemo.value ], additionalClientMemo.rest)

ZeroGiveUp ==
    [ tradeNumber                  |-> [i \in 1 .. 15 |-> 0],
      transactionType              |-> [i \in 1 .. 1 |-> 0],
      timestamp                    |-> [i \in 1 .. 6 |-> 0],
      symbol                       |-> [i \in 1 .. 30 |-> 0],
      expirationDate               |-> [i \in 1 .. 6 |-> 0],
      strikePrice                  |-> [i \in 1 .. 8 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      optionType                   |-> [i \in 1 .. 1 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0],
      price                        |-> [i \in 1 .. 8 |-> 0],
      cmtaBroker                   |-> [i \in 1 .. 4 |-> 0],
      accountType                  |-> [i \in 1 .. 1 |-> 0],
      subTraderId                  |-> [i \in 1 .. 3 |-> 0],
      openClose                    |-> [i \in 1 .. 1 |-> 0],
      executingBroker              |-> [i \in 1 .. 4 |-> 0],
      clientAccountNumber          |-> [i \in 1 .. 12 |-> 0],
      clientOrderId                |-> [i \in 1 .. 20 |-> 0],
      clientMemo                   |-> [i \in 1 .. 16 |-> 0],
      liquidityStatus              |-> [i \in 1 .. 1 |-> 0],
      tradeType                    |-> [i \in 1 .. 1 |-> 0],
      oppositeAccountType          |-> [i \in 1 .. 1 |-> 0],
      giveUpSource                 |-> [i \in 1 .. 4 |-> 0],
      giveUpDestination            |-> [i \in 1 .. 4 |-> 0],
      participantSessionName       |-> [i \in 1 .. 12 |-> 0],
      uniqueTransactionId          |-> [i \in 1 .. 10 |-> 0],
      parentTransactionId          |-> [i \in 1 .. 10 |-> 0],
      oppositeExecutingBroker      |-> [i \in 1 .. 4 |-> 0],
      additionalClientMemo         |-> [i \in 1 .. 16 |-> 0] ]

(* Give Up at zero, then each field in turn at the values it is checked at *)
CheckedGiveUp ==
    { ZeroGiveUp }
        \cup { [ZeroGiveUp EXCEPT !.tradeNumber = one] : one \in Sample(15) }
        \cup { [ZeroGiveUp EXCEPT !.transactionType = one] : one \in Sample(1) }
        \cup { [ZeroGiveUp EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroGiveUp EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroGiveUp EXCEPT !.expirationDate = one] : one \in Sample(6) }
        \cup { [ZeroGiveUp EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroGiveUp EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroGiveUp EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroGiveUp EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroGiveUp EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroGiveUp EXCEPT !.cmtaBroker = one] : one \in Sample(4) }
        \cup { [ZeroGiveUp EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroGiveUp EXCEPT !.subTraderId = one] : one \in Sample(3) }
        \cup { [ZeroGiveUp EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroGiveUp EXCEPT !.executingBroker = one] : one \in Sample(4) }
        \cup { [ZeroGiveUp EXCEPT !.clientAccountNumber = one] : one \in Sample(12) }
        \cup { [ZeroGiveUp EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroGiveUp EXCEPT !.clientMemo = one] : one \in Sample(16) }
        \cup { [ZeroGiveUp EXCEPT !.liquidityStatus = one] : one \in Sample(1) }
        \cup { [ZeroGiveUp EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroGiveUp EXCEPT !.oppositeAccountType = one] : one \in Sample(1) }
        \cup { [ZeroGiveUp EXCEPT !.giveUpSource = one] : one \in Sample(4) }
        \cup { [ZeroGiveUp EXCEPT !.giveUpDestination = one] : one \in Sample(4) }
        \cup { [ZeroGiveUp EXCEPT !.participantSessionName = one] : one \in Sample(12) }
        \cup { [ZeroGiveUp EXCEPT !.uniqueTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroGiveUp EXCEPT !.parentTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroGiveUp EXCEPT !.oppositeExecutingBroker = one] : one \in Sample(4) }
        \cup { [ZeroGiveUp EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }

(***************************************************************************)
(* Give Up Cancel: 208 bytes                                               *)
(***************************************************************************)

GiveUpCancel ==
    [ tradeNumber                  : Sample(15),
      transactionType              : Sample(1),
      timestamp                    : Sample(6),
      symbol                       : Sample(30),
      expirationDate               : Sample(6),
      strikePrice                  : Sample(8),
      strikePriceFractionIndicator : Sample(1),
      optionType                   : Sample(1),
      volume                       : Sample(8),
      price                        : Sample(8),
      cmtaBroker                   : Sample(4),
      accountType                  : Sample(1),
      subTraderId                  : Sample(3),
      openClose                    : Sample(1),
      executingBroker              : Sample(4),
      clientAccountNumber          : Sample(12),
      clientOrderId                : Sample(20),
      clientMemo                   : Sample(16),
      liquidityStatus              : Sample(1),
      tradeType                    : Sample(1),
      oppositeAccountType          : Sample(1),
      giveUpSource                 : Sample(4),
      giveUpDestination            : Sample(4),
      participantSessionName       : Sample(12),
      uniqueTransactionId          : Sample(10),
      parentTransactionId          : Sample(10),
      oppositeExecutingBroker      : Sample(4),
      additionalClientMemo         : Sample(16) ]

EncodeGiveUpCancel(message) ==
    message.tradeNumber
        \o message.transactionType
        \o message.timestamp
        \o message.symbol
        \o message.expirationDate
        \o message.strikePrice
        \o message.strikePriceFractionIndicator
        \o message.optionType
        \o message.volume
        \o message.price
        \o message.cmtaBroker
        \o message.accountType
        \o message.subTraderId
        \o message.openClose
        \o message.executingBroker
        \o message.clientAccountNumber
        \o message.clientOrderId
        \o message.clientMemo
        \o message.liquidityStatus
        \o message.tradeType
        \o message.oppositeAccountType
        \o message.giveUpSource
        \o message.giveUpDestination
        \o message.participantSessionName
        \o message.uniqueTransactionId
        \o message.parentTransactionId
        \o message.oppositeExecutingBroker
        \o message.additionalClientMemo

DecodeGiveUpCancel(bytes) ==
    LET tradeNumber == ReadBytes(bytes, 15) IN IF ~tradeNumber.ok THEN Fail ELSE
    LET transactionType == ReadBytes(tradeNumber.rest, 1) IN IF ~transactionType.ok THEN Fail ELSE
    LET timestamp == ReadBytes(transactionType.rest, 6) IN IF ~timestamp.ok THEN Fail ELSE
    LET symbol == ReadBytes(timestamp.rest, 30) IN IF ~symbol.ok THEN Fail ELSE
    LET expirationDate == ReadBytes(symbol.rest, 6) IN IF ~expirationDate.ok THEN Fail ELSE
    LET strikePrice == ReadBytes(expirationDate.rest, 8) IN IF ~strikePrice.ok THEN Fail ELSE
    LET strikePriceFractionIndicator == ReadBytes(strikePrice.rest, 1) IN IF ~strikePriceFractionIndicator.ok THEN Fail ELSE
    LET optionType == ReadBytes(strikePriceFractionIndicator.rest, 1) IN IF ~optionType.ok THEN Fail ELSE
    LET volume == ReadBytes(optionType.rest, 8) IN IF ~volume.ok THEN Fail ELSE
    LET price == ReadBytes(volume.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET cmtaBroker == ReadBytes(price.rest, 4) IN IF ~cmtaBroker.ok THEN Fail ELSE
    LET accountType == ReadBytes(cmtaBroker.rest, 1) IN IF ~accountType.ok THEN Fail ELSE
    LET subTraderId == ReadBytes(accountType.rest, 3) IN IF ~subTraderId.ok THEN Fail ELSE
    LET openClose == ReadBytes(subTraderId.rest, 1) IN IF ~openClose.ok THEN Fail ELSE
    LET executingBroker == ReadBytes(openClose.rest, 4) IN IF ~executingBroker.ok THEN Fail ELSE
    LET clientAccountNumber == ReadBytes(executingBroker.rest, 12) IN IF ~clientAccountNumber.ok THEN Fail ELSE
    LET clientOrderId == ReadBytes(clientAccountNumber.rest, 20) IN IF ~clientOrderId.ok THEN Fail ELSE
    LET clientMemo == ReadBytes(clientOrderId.rest, 16) IN IF ~clientMemo.ok THEN Fail ELSE
    LET liquidityStatus == ReadBytes(clientMemo.rest, 1) IN IF ~liquidityStatus.ok THEN Fail ELSE
    LET tradeType == ReadBytes(liquidityStatus.rest, 1) IN IF ~tradeType.ok THEN Fail ELSE
    LET oppositeAccountType == ReadBytes(tradeType.rest, 1) IN IF ~oppositeAccountType.ok THEN Fail ELSE
    LET giveUpSource == ReadBytes(oppositeAccountType.rest, 4) IN IF ~giveUpSource.ok THEN Fail ELSE
    LET giveUpDestination == ReadBytes(giveUpSource.rest, 4) IN IF ~giveUpDestination.ok THEN Fail ELSE
    LET participantSessionName == ReadBytes(giveUpDestination.rest, 12) IN IF ~participantSessionName.ok THEN Fail ELSE
    LET uniqueTransactionId == ReadBytes(participantSessionName.rest, 10) IN IF ~uniqueTransactionId.ok THEN Fail ELSE
    LET parentTransactionId == ReadBytes(uniqueTransactionId.rest, 10) IN IF ~parentTransactionId.ok THEN Fail ELSE
    LET oppositeExecutingBroker == ReadBytes(parentTransactionId.rest, 4) IN IF ~oppositeExecutingBroker.ok THEN Fail ELSE
    LET additionalClientMemo == ReadBytes(oppositeExecutingBroker.rest, 16) IN IF ~additionalClientMemo.ok THEN Fail ELSE
    Ok([ tradeNumber                  |-> tradeNumber.value,
         transactionType              |-> transactionType.value,
         timestamp                    |-> timestamp.value,
         symbol                       |-> symbol.value,
         expirationDate               |-> expirationDate.value,
         strikePrice                  |-> strikePrice.value,
         strikePriceFractionIndicator |-> strikePriceFractionIndicator.value,
         optionType                   |-> optionType.value,
         volume                       |-> volume.value,
         price                        |-> price.value,
         cmtaBroker                   |-> cmtaBroker.value,
         accountType                  |-> accountType.value,
         subTraderId                  |-> subTraderId.value,
         openClose                    |-> openClose.value,
         executingBroker              |-> executingBroker.value,
         clientAccountNumber          |-> clientAccountNumber.value,
         clientOrderId                |-> clientOrderId.value,
         clientMemo                   |-> clientMemo.value,
         liquidityStatus              |-> liquidityStatus.value,
         tradeType                    |-> tradeType.value,
         oppositeAccountType          |-> oppositeAccountType.value,
         giveUpSource                 |-> giveUpSource.value,
         giveUpDestination            |-> giveUpDestination.value,
         participantSessionName       |-> participantSessionName.value,
         uniqueTransactionId          |-> uniqueTransactionId.value,
         parentTransactionId          |-> parentTransactionId.value,
         oppositeExecutingBroker      |-> oppositeExecutingBroker.value,
         additionalClientMemo         |-> additionalClientMemo.value ], additionalClientMemo.rest)

ZeroGiveUpCancel ==
    [ tradeNumber                  |-> [i \in 1 .. 15 |-> 0],
      transactionType              |-> [i \in 1 .. 1 |-> 0],
      timestamp                    |-> [i \in 1 .. 6 |-> 0],
      symbol                       |-> [i \in 1 .. 30 |-> 0],
      expirationDate               |-> [i \in 1 .. 6 |-> 0],
      strikePrice                  |-> [i \in 1 .. 8 |-> 0],
      strikePriceFractionIndicator |-> [i \in 1 .. 1 |-> 0],
      optionType                   |-> [i \in 1 .. 1 |-> 0],
      volume                       |-> [i \in 1 .. 8 |-> 0],
      price                        |-> [i \in 1 .. 8 |-> 0],
      cmtaBroker                   |-> [i \in 1 .. 4 |-> 0],
      accountType                  |-> [i \in 1 .. 1 |-> 0],
      subTraderId                  |-> [i \in 1 .. 3 |-> 0],
      openClose                    |-> [i \in 1 .. 1 |-> 0],
      executingBroker              |-> [i \in 1 .. 4 |-> 0],
      clientAccountNumber          |-> [i \in 1 .. 12 |-> 0],
      clientOrderId                |-> [i \in 1 .. 20 |-> 0],
      clientMemo                   |-> [i \in 1 .. 16 |-> 0],
      liquidityStatus              |-> [i \in 1 .. 1 |-> 0],
      tradeType                    |-> [i \in 1 .. 1 |-> 0],
      oppositeAccountType          |-> [i \in 1 .. 1 |-> 0],
      giveUpSource                 |-> [i \in 1 .. 4 |-> 0],
      giveUpDestination            |-> [i \in 1 .. 4 |-> 0],
      participantSessionName       |-> [i \in 1 .. 12 |-> 0],
      uniqueTransactionId          |-> [i \in 1 .. 10 |-> 0],
      parentTransactionId          |-> [i \in 1 .. 10 |-> 0],
      oppositeExecutingBroker      |-> [i \in 1 .. 4 |-> 0],
      additionalClientMemo         |-> [i \in 1 .. 16 |-> 0] ]

(* Give Up Cancel at zero, then each field in turn at the values it is checked at *)
CheckedGiveUpCancel ==
    { ZeroGiveUpCancel }
        \cup { [ZeroGiveUpCancel EXCEPT !.tradeNumber = one] : one \in Sample(15) }
        \cup { [ZeroGiveUpCancel EXCEPT !.transactionType = one] : one \in Sample(1) }
        \cup { [ZeroGiveUpCancel EXCEPT !.timestamp = one] : one \in Sample(6) }
        \cup { [ZeroGiveUpCancel EXCEPT !.symbol = one] : one \in Sample(30) }
        \cup { [ZeroGiveUpCancel EXCEPT !.expirationDate = one] : one \in Sample(6) }
        \cup { [ZeroGiveUpCancel EXCEPT !.strikePrice = one] : one \in Sample(8) }
        \cup { [ZeroGiveUpCancel EXCEPT !.strikePriceFractionIndicator = one] : one \in Sample(1) }
        \cup { [ZeroGiveUpCancel EXCEPT !.optionType = one] : one \in Sample(1) }
        \cup { [ZeroGiveUpCancel EXCEPT !.volume = one] : one \in Sample(8) }
        \cup { [ZeroGiveUpCancel EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroGiveUpCancel EXCEPT !.cmtaBroker = one] : one \in Sample(4) }
        \cup { [ZeroGiveUpCancel EXCEPT !.accountType = one] : one \in Sample(1) }
        \cup { [ZeroGiveUpCancel EXCEPT !.subTraderId = one] : one \in Sample(3) }
        \cup { [ZeroGiveUpCancel EXCEPT !.openClose = one] : one \in Sample(1) }
        \cup { [ZeroGiveUpCancel EXCEPT !.executingBroker = one] : one \in Sample(4) }
        \cup { [ZeroGiveUpCancel EXCEPT !.clientAccountNumber = one] : one \in Sample(12) }
        \cup { [ZeroGiveUpCancel EXCEPT !.clientOrderId = one] : one \in Sample(20) }
        \cup { [ZeroGiveUpCancel EXCEPT !.clientMemo = one] : one \in Sample(16) }
        \cup { [ZeroGiveUpCancel EXCEPT !.liquidityStatus = one] : one \in Sample(1) }
        \cup { [ZeroGiveUpCancel EXCEPT !.tradeType = one] : one \in Sample(1) }
        \cup { [ZeroGiveUpCancel EXCEPT !.oppositeAccountType = one] : one \in Sample(1) }
        \cup { [ZeroGiveUpCancel EXCEPT !.giveUpSource = one] : one \in Sample(4) }
        \cup { [ZeroGiveUpCancel EXCEPT !.giveUpDestination = one] : one \in Sample(4) }
        \cup { [ZeroGiveUpCancel EXCEPT !.participantSessionName = one] : one \in Sample(12) }
        \cup { [ZeroGiveUpCancel EXCEPT !.uniqueTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroGiveUpCancel EXCEPT !.parentTransactionId = one] : one \in Sample(10) }
        \cup { [ZeroGiveUpCancel EXCEPT !.oppositeExecutingBroker = one] : one \in Sample(4) }
        \cup { [ZeroGiveUpCancel EXCEPT !.additionalClientMemo = one] : one \in Sample(16) }

(***************************************************************************)
(* Error Message: 86 bytes                                                 *)
(***************************************************************************)

ErrorMessage ==
    [ referenceMessageType : Sample(2),
      errorCode            : Sample(4),
      errorText            : Sample(80) ]

EncodeErrorMessage(message) ==
    message.referenceMessageType
        \o message.errorCode
        \o message.errorText

DecodeErrorMessage(bytes) ==
    LET referenceMessageType == ReadBytes(bytes, 2) IN IF ~referenceMessageType.ok THEN Fail ELSE
    LET errorCode == ReadBytes(referenceMessageType.rest, 4) IN IF ~errorCode.ok THEN Fail ELSE
    LET errorText == ReadBytes(errorCode.rest, 80) IN IF ~errorText.ok THEN Fail ELSE
    Ok([ referenceMessageType |-> referenceMessageType.value,
         errorCode            |-> errorCode.value,
         errorText            |-> errorText.value ], errorText.rest)

ZeroErrorMessage ==
    [ referenceMessageType |-> [i \in 1 .. 2 |-> 0],
      errorCode            |-> [i \in 1 .. 4 |-> 0],
      errorText            |-> [i \in 1 .. 80 |-> 0] ]

(* Error Message at zero, then each field in turn at the values it is checked at *)
CheckedErrorMessage ==
    { ZeroErrorMessage }
        \cup { [ZeroErrorMessage EXCEPT !.referenceMessageType = one] : one \in Sample(2) }
        \cup { [ZeroErrorMessage EXCEPT !.errorCode = one] : one \in Sample(4) }
        \cup { [ZeroErrorMessage EXCEPT !.errorText = one] : one \in Sample(80) }

(***************************************************************************)
(* Server Message, selected by Message Type                                *)
(***************************************************************************)

StartOfDayCode == 12336  \* "00"
CircuitAssuranceCode == 12338  \* "02"
RestartAcceptedCode == 12341  \* "05"
EndOfTradingCode == 12344  \* "08"
ClientSignonAcknowledgmentCode == 12592  \* "10"
TradeCode == 13104  \* "30"
TradeCancelCode == 13105  \* "31"
AllocationCode == 13360  \* "40"
AllocationCancelCode == 13361  \* "41"
GiveUpCode == 13616  \* "50"
GiveUpCancelCode == 13617  \* "51"
AcknowledgementMessageCode == 14648  \* "98"
ErrorMessageCode == 14649  \* "99"

ServerMessage ==
    [ tag : {StartOfDayCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {CircuitAssuranceCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {RestartAcceptedCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {EndOfTradingCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ClientSignonAcknowledgmentCode}, body : ClientSignonAcknowledgment ]
        \cup [ tag : {TradeCode}, body : Trade ]
        \cup [ tag : {TradeCancelCode}, body : TradeCancel ]
        \cup [ tag : {AllocationCode}, body : Allocation ]
        \cup [ tag : {AllocationCancelCode}, body : AllocationCancel ]
        \cup [ tag : {GiveUpCode}, body : GiveUp ]
        \cup [ tag : {GiveUpCancelCode}, body : GiveUpCancel ]
        \cup [ tag : {AcknowledgementMessageCode}, body : {[empty |-> 0]} ]
        \cup [ tag : {ErrorMessageCode}, body : ErrorMessage ]

EncodeServerMessage(message) ==
    CASE message.tag = StartOfDayCode -> << >>
      [] message.tag = CircuitAssuranceCode -> << >>
      [] message.tag = RestartAcceptedCode -> << >>
      [] message.tag = EndOfTradingCode -> << >>
      [] message.tag = ClientSignonAcknowledgmentCode -> EncodeClientSignonAcknowledgment(message.body)
      [] message.tag = TradeCode -> EncodeTrade(message.body)
      [] message.tag = TradeCancelCode -> EncodeTradeCancel(message.body)
      [] message.tag = AllocationCode -> EncodeAllocation(message.body)
      [] message.tag = AllocationCancelCode -> EncodeAllocationCancel(message.body)
      [] message.tag = GiveUpCode -> EncodeGiveUp(message.body)
      [] message.tag = GiveUpCancelCode -> EncodeGiveUpCancel(message.body)
      [] message.tag = AcknowledgementMessageCode -> << >>
      [] message.tag = ErrorMessageCode -> EncodeErrorMessage(message.body)

DecodeServerMessage(tag, bytes) ==
    LET read ==
            CASE tag = StartOfDayCode -> Ok([empty |-> 0], bytes)
              [] tag = CircuitAssuranceCode -> Ok([empty |-> 0], bytes)
              [] tag = RestartAcceptedCode -> Ok([empty |-> 0], bytes)
              [] tag = EndOfTradingCode -> Ok([empty |-> 0], bytes)
              [] tag = ClientSignonAcknowledgmentCode -> DecodeClientSignonAcknowledgment(bytes)
              [] tag = TradeCode -> DecodeTrade(bytes)
              [] tag = TradeCancelCode -> DecodeTradeCancel(bytes)
              [] tag = AllocationCode -> DecodeAllocation(bytes)
              [] tag = AllocationCancelCode -> DecodeAllocationCancel(bytes)
              [] tag = GiveUpCode -> DecodeGiveUp(bytes)
              [] tag = GiveUpCancelCode -> DecodeGiveUpCancel(bytes)
              [] tag = AcknowledgementMessageCode -> Ok([empty |-> 0], bytes)
              [] tag = ErrorMessageCode -> DecodeErrorMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroServerMessage == [tag |-> StartOfDayCode, body |-> [empty |-> 0]]

(* Each Server Message in turn, at the values the message it names is checked at *)
CheckedServerMessage ==
    { [tag |-> StartOfDayCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> CircuitAssuranceCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> RestartAcceptedCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> EndOfTradingCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ClientSignonAcknowledgmentCode, body |-> one] : one \in CheckedClientSignonAcknowledgment }
        \cup { [tag |-> TradeCode, body |-> one] : one \in CheckedTrade }
        \cup { [tag |-> TradeCancelCode, body |-> one] : one \in CheckedTradeCancel }
        \cup { [tag |-> AllocationCode, body |-> one] : one \in CheckedAllocation }
        \cup { [tag |-> AllocationCancelCode, body |-> one] : one \in CheckedAllocationCancel }
        \cup { [tag |-> GiveUpCode, body |-> one] : one \in CheckedGiveUp }
        \cup { [tag |-> GiveUpCancelCode, body |-> one] : one \in CheckedGiveUpCancel }
        \cup { [tag |-> AcknowledgementMessageCode, body |-> [empty |-> 0]] }
        \cup { [tag |-> ErrorMessageCode, body |-> one] : one \in CheckedErrorMessage }

(***************************************************************************)
(* Server Sola Frame                                                       *)
(***************************************************************************)

ServerSolaFrame ==
    [ source                        : Sample(4),
      destination                   : Sample(4),
      messageFlag                   : Sample(1),
      controlByte                   : Sample(1),
      sequenceNumber                : Sample(8),
      acknowledgementSequenceNumber : Sample(8),
      serverMessage                 : ServerMessage,
      solaMessageEnd                : Sample(1) ]

EncodeServerSolaFrame(message) ==
    message.source
        \o message.destination
        \o EncodeUIntBE(message.serverMessage.tag, 2)
        \o message.messageFlag
        \o message.controlByte
        \o message.sequenceNumber
        \o message.acknowledgementSequenceNumber
        \o EncodeServerMessage(message.serverMessage)
        \o message.solaMessageEnd

DecodeServerSolaFrame(bytes) ==
    LET source == ReadBytes(bytes, 4) IN IF ~source.ok THEN Fail ELSE
    LET destination == ReadBytes(source.rest, 4) IN IF ~destination.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(destination.rest, 2) IN IF ~messageType.ok THEN Fail ELSE
    LET messageFlag == ReadBytes(messageType.rest, 1) IN IF ~messageFlag.ok THEN Fail ELSE
    LET controlByte == ReadBytes(messageFlag.rest, 1) IN IF ~controlByte.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(controlByte.rest, 8) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET acknowledgementSequenceNumber == ReadBytes(sequenceNumber.rest, 8) IN IF ~acknowledgementSequenceNumber.ok THEN Fail ELSE
    LET serverMessage == DecodeServerMessage(messageType.value, acknowledgementSequenceNumber.rest) IN IF ~serverMessage.ok THEN Fail ELSE
    LET solaMessageEnd == ReadBytes(serverMessage.rest, 1) IN IF ~solaMessageEnd.ok THEN Fail ELSE
    Ok([ source                        |-> source.value,
         destination                   |-> destination.value,
         messageFlag                   |-> messageFlag.value,
         controlByte                   |-> controlByte.value,
         sequenceNumber                |-> sequenceNumber.value,
         acknowledgementSequenceNumber |-> acknowledgementSequenceNumber.value,
         serverMessage                 |-> serverMessage.value,
         solaMessageEnd                |-> solaMessageEnd.value ], solaMessageEnd.rest)

ZeroServerSolaFrame ==
    [ source                        |-> [i \in 1 .. 4 |-> 0],
      destination                   |-> [i \in 1 .. 4 |-> 0],
      messageFlag                   |-> [i \in 1 .. 1 |-> 0],
      controlByte                   |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber                |-> [i \in 1 .. 8 |-> 0],
      acknowledgementSequenceNumber |-> [i \in 1 .. 8 |-> 0],
      serverMessage                 |-> ZeroServerMessage,
      solaMessageEnd                |-> [i \in 1 .. 1 |-> 0] ]

(* Server Sola Frame at zero, then each field in turn at the values it is checked at *)
CheckedServerSolaFrame ==
    { ZeroServerSolaFrame }
        \cup { [ZeroServerSolaFrame EXCEPT !.source = one] : one \in Sample(4) }
        \cup { [ZeroServerSolaFrame EXCEPT !.destination = one] : one \in Sample(4) }
        \cup { [ZeroServerSolaFrame EXCEPT !.messageFlag = one] : one \in Sample(1) }
        \cup { [ZeroServerSolaFrame EXCEPT !.controlByte = one] : one \in Sample(1) }
        \cup { [ZeroServerSolaFrame EXCEPT !.sequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroServerSolaFrame EXCEPT !.acknowledgementSequenceNumber = one] : one \in Sample(8) }
        \cup { [ZeroServerSolaFrame EXCEPT !.serverMessage = one] : one \in CheckedServerMessage }
        \cup { [ZeroServerSolaFrame EXCEPT !.solaMessageEnd = one] : one \in Sample(1) }

(* A run of Server Sola Frame, written one after another *)
RECURSIVE EncodeServerSolaFrameList(_)
EncodeServerSolaFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeServerSolaFrame(Head(messages)) \o EncodeServerSolaFrameList(Tail(messages))

(* As many Server Sola Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadServerSolaFrameAll(_)
ReadServerSolaFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeServerSolaFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadServerSolaFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Server Sola Frame of each kind, for the lists that carry them *)
OneServerSolaFrame ==
    { [ZeroServerSolaFrame EXCEPT !.serverMessage = [tag |-> StartOfDayCode, body |-> [empty |-> 0]]],
      [ZeroServerSolaFrame EXCEPT !.serverMessage = [tag |-> CircuitAssuranceCode, body |-> [empty |-> 0]]],
      [ZeroServerSolaFrame EXCEPT !.serverMessage = [tag |-> RestartAcceptedCode, body |-> [empty |-> 0]]],
      [ZeroServerSolaFrame EXCEPT !.serverMessage = [tag |-> EndOfTradingCode, body |-> [empty |-> 0]]],
      [ZeroServerSolaFrame EXCEPT !.serverMessage = [tag |-> ClientSignonAcknowledgmentCode, body |-> ZeroClientSignonAcknowledgment]],
      [ZeroServerSolaFrame EXCEPT !.serverMessage = [tag |-> TradeCode, body |-> ZeroTrade]],
      [ZeroServerSolaFrame EXCEPT !.serverMessage = [tag |-> TradeCancelCode, body |-> ZeroTradeCancel]],
      [ZeroServerSolaFrame EXCEPT !.serverMessage = [tag |-> AllocationCode, body |-> ZeroAllocation]],
      [ZeroServerSolaFrame EXCEPT !.serverMessage = [tag |-> AllocationCancelCode, body |-> ZeroAllocationCancel]],
      [ZeroServerSolaFrame EXCEPT !.serverMessage = [tag |-> GiveUpCode, body |-> ZeroGiveUp]],
      [ZeroServerSolaFrame EXCEPT !.serverMessage = [tag |-> GiveUpCancelCode, body |-> ZeroGiveUpCancel]],
      [ZeroServerSolaFrame EXCEPT !.serverMessage = [tag |-> AcknowledgementMessageCode, body |-> [empty |-> 0]]],
      [ZeroServerSolaFrame EXCEPT !.serverMessage = [tag |-> ErrorMessageCode, body |-> ZeroErrorMessage]] }

(***************************************************************************)
(* Server Packet                                                           *)
(***************************************************************************)

ServerPacket ==
    [ serverSolaFrame : SampleLists(OneServerSolaFrame) ]

EncodeServerPacket(message) ==
    EncodeServerSolaFrameList(message.serverSolaFrame)

DecodeServerPacket(bytes) ==
    LET serverSolaFrame == ReadServerSolaFrameAll(bytes) IN IF ~serverSolaFrame.ok THEN Fail ELSE
    Ok([ serverSolaFrame |-> serverSolaFrame.value ], serverSolaFrame.rest)

ZeroServerPacket ==
    [ serverSolaFrame |-> << >> ]

(* Server Packet at zero, then each field in turn at the values it is checked at *)
CheckedServerPacket ==
    { ZeroServerPacket }
        \cup { [ZeroServerPacket EXCEPT !.serverSolaFrame = one] : one \in SampleLists(OneServerSolaFrame) }

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

(* Every Client Signon Acknowledgment decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSignonAcknowledgment ==
    \A message \in CheckedClientSignonAcknowledgment :
        LET read == DecodeClientSignonAcknowledgment(EncodeClientSignonAcknowledgment(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade decodes back to what was encoded, and leaves nothing over *)
RoundTripTrade ==
    \A message \in CheckedTrade :
        LET read == DecodeTrade(EncodeTrade(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trade Cancel decodes back to what was encoded, and leaves nothing over *)
RoundTripTradeCancel ==
    \A message \in CheckedTradeCancel :
        LET read == DecodeTradeCancel(EncodeTradeCancel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Allocation decodes back to what was encoded, and leaves nothing over *)
RoundTripAllocation ==
    \A message \in CheckedAllocation :
        LET read == DecodeAllocation(EncodeAllocation(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Allocation Cancel decodes back to what was encoded, and leaves nothing over *)
RoundTripAllocationCancel ==
    \A message \in CheckedAllocationCancel :
        LET read == DecodeAllocationCancel(EncodeAllocationCancel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Give Up decodes back to what was encoded, and leaves nothing over *)
RoundTripGiveUp ==
    \A message \in CheckedGiveUp :
        LET read == DecodeGiveUp(EncodeGiveUp(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Give Up Cancel decodes back to what was encoded, and leaves nothing over *)
RoundTripGiveUpCancel ==
    \A message \in CheckedGiveUpCancel :
        LET read == DecodeGiveUpCancel(EncodeGiveUpCancel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Error Message decodes back to what was encoded, and leaves nothing over *)
RoundTripErrorMessage ==
    \A message \in CheckedErrorMessage :
        LET read == DecodeErrorMessage(EncodeErrorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Server Sola Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripServerSolaFrame ==
    \A message \in CheckedServerSolaFrame :
        LET read == DecodeServerSolaFrame(EncodeServerSolaFrame(message))
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

(* A Server Message is selected by the Message Type it is written under *)
SelectsServerMessage ==
    \A message \in CheckedServerMessage :
        LET sent == EncodeServerMessage(message)
            read == DecodeServerMessage(message.tag, sent)
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
