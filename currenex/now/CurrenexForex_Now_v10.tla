----------------------- MODULE CurrenexForex_Now_v10 -----------------------
(***************************************************************************)
(* Currenex Now Forex Market Data v10                                      *)
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
(* Note: Level is written as 20 slots, however many of them the count      *)
(* beside it says are in use.                                              *)
(*                                                                         *)
(* Note: Packet fills its datagram with as many messages as the bytes      *)
(* hold, so it is read as a run of them.                                   *)
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
(* Logon Message: 44 bytes                                                 *)
(***************************************************************************)

LogonMessage ==
    [ userId    : Sample(20),
      password  : Sample(20),
      sessionId : Sample(4) ]

EncodeLogonMessage(message) ==
    message.userId
        \o message.password
        \o message.sessionId

DecodeLogonMessage(bytes) ==
    LET userId == ReadBytes(bytes, 20) IN IF ~userId.ok THEN Fail ELSE
    LET password == ReadBytes(userId.rest, 20) IN IF ~password.ok THEN Fail ELSE
    LET sessionId == ReadBytes(password.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ userId    |-> userId.value,
         password  |-> password.value,
         sessionId |-> sessionId.value ], sessionId.rest)

ZeroLogonMessage ==
    [ userId    |-> [i \in 1 .. 20 |-> 0],
      password  |-> [i \in 1 .. 20 |-> 0],
      sessionId |-> [i \in 1 .. 4 |-> 0] ]

(* Logon Message at zero, then each field in turn at the values it is checked at *)
CheckedLogonMessage ==
    { ZeroLogonMessage }
        \cup { [ZeroLogonMessage EXCEPT !.userId = one] : one \in Sample(20) }
        \cup { [ZeroLogonMessage EXCEPT !.password = one] : one \in Sample(20) }
        \cup { [ZeroLogonMessage EXCEPT !.sessionId = one] : one \in Sample(4) }

(***************************************************************************)
(* Logout Message: 27 bytes                                                *)
(***************************************************************************)

LogoutMessage ==
    [ userId       : Sample(20),
      sessionId    : Sample(4),
      reasonAlpha3 : Sample(3) ]

EncodeLogoutMessage(message) ==
    message.userId
        \o message.sessionId
        \o message.reasonAlpha3

DecodeLogoutMessage(bytes) ==
    LET userId == ReadBytes(bytes, 20) IN IF ~userId.ok THEN Fail ELSE
    LET sessionId == ReadBytes(userId.rest, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET reasonAlpha3 == ReadBytes(sessionId.rest, 3) IN IF ~reasonAlpha3.ok THEN Fail ELSE
    Ok([ userId       |-> userId.value,
         sessionId    |-> sessionId.value,
         reasonAlpha3 |-> reasonAlpha3.value ], reasonAlpha3.rest)

ZeroLogoutMessage ==
    [ userId       |-> [i \in 1 .. 20 |-> 0],
      sessionId    |-> [i \in 1 .. 4 |-> 0],
      reasonAlpha3 |-> [i \in 1 .. 3 |-> 0] ]

(* Logout Message at zero, then each field in turn at the values it is checked at *)
CheckedLogoutMessage ==
    { ZeroLogoutMessage }
        \cup { [ZeroLogoutMessage EXCEPT !.userId = one] : one \in Sample(20) }
        \cup { [ZeroLogoutMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroLogoutMessage EXCEPT !.reasonAlpha3 = one] : one \in Sample(3) }

(***************************************************************************)
(* Heart Beat Message: 4 bytes                                             *)
(***************************************************************************)

HeartBeatMessage ==
    [ sessionId : Sample(4) ]

EncodeHeartBeatMessage(message) ==
    message.sessionId

DecodeHeartBeatMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    Ok([ sessionId |-> sessionId.value ], sessionId.rest)

ZeroHeartBeatMessage ==
    [ sessionId |-> [i \in 1 .. 4 |-> 0] ]

(* Heart Beat Message at zero, then each field in turn at the values it is checked at *)
CheckedHeartBeatMessage ==
    { ZeroHeartBeatMessage }
        \cup { [ZeroHeartBeatMessage EXCEPT !.sessionId = one] : one \in Sample(4) }

(***************************************************************************)
(* Instrument Info: 35 bytes                                               *)
(***************************************************************************)

InstrumentInfo ==
    [ sessionId       : Sample(4),
      instrumentIndex : Sample(2),
      instrumentType  : Sample(1),
      instrumentId    : Sample(20),
      settlementDate  : Sample(8) ]

EncodeInstrumentInfo(message) ==
    message.sessionId
        \o message.instrumentIndex
        \o message.instrumentType
        \o message.instrumentId
        \o message.settlementDate

DecodeInstrumentInfo(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET instrumentIndex == ReadBytes(sessionId.rest, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET instrumentType == ReadBytes(instrumentIndex.rest, 1) IN IF ~instrumentType.ok THEN Fail ELSE
    LET instrumentId == ReadBytes(instrumentType.rest, 20) IN IF ~instrumentId.ok THEN Fail ELSE
    LET settlementDate == ReadBytes(instrumentId.rest, 8) IN IF ~settlementDate.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         instrumentIndex |-> instrumentIndex.value,
         instrumentType  |-> instrumentType.value,
         instrumentId    |-> instrumentId.value,
         settlementDate  |-> settlementDate.value ], settlementDate.rest)

ZeroInstrumentInfo ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      instrumentIndex |-> [i \in 1 .. 2 |-> 0],
      instrumentType  |-> [i \in 1 .. 1 |-> 0],
      instrumentId    |-> [i \in 1 .. 20 |-> 0],
      settlementDate  |-> [i \in 1 .. 8 |-> 0] ]

(* Instrument Info at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentInfo ==
    { ZeroInstrumentInfo }
        \cup { [ZeroInstrumentInfo EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentInfo EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroInstrumentInfo EXCEPT !.instrumentType = one] : one \in Sample(1) }
        \cup { [ZeroInstrumentInfo EXCEPT !.instrumentId = one] : one \in Sample(20) }
        \cup { [ZeroInstrumentInfo EXCEPT !.settlementDate = one] : one \in Sample(8) }

(***************************************************************************)
(* Instrument Info Ack Message: 6 bytes                                    *)
(***************************************************************************)

InstrumentInfoAckMessage ==
    [ sessionId       : Sample(4),
      instrumentIndex : Sample(2) ]

EncodeInstrumentInfoAckMessage(message) ==
    message.sessionId
        \o message.instrumentIndex

DecodeInstrumentInfoAckMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET instrumentIndex == ReadBytes(sessionId.rest, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         instrumentIndex |-> instrumentIndex.value ], instrumentIndex.rest)

ZeroInstrumentInfoAckMessage ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      instrumentIndex |-> [i \in 1 .. 2 |-> 0] ]

(* Instrument Info Ack Message at zero, then each field in turn at the values it is checked at *)
CheckedInstrumentInfoAckMessage ==
    { ZeroInstrumentInfoAckMessage }
        \cup { [ZeroInstrumentInfoAckMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroInstrumentInfoAckMessage EXCEPT !.instrumentIndex = one] : one \in Sample(2) }

(***************************************************************************)
(* Subscription Request Message                                            *)
(***************************************************************************)

SubscriptionRequestMessage ==
    [ sessionId                               : Sample(4),
      subscriptionType                        : Sample(1),
      instrumentIndex                         : Sample(2),
      subscribeToNowDepthOfBook               : Sample(1),
      subscribeToNowPaidGivenWithBucketedSize : SampleBytes,
      subscribeToNowWamrWithConfidenceFactor  : Sample(1),
      subscribeToNowMidActivityIndicator      : Sample(1) ]

EncodeSubscriptionRequestMessage(message) ==
    message.sessionId
        \o message.subscriptionType
        \o message.instrumentIndex
        \o message.subscribeToNowDepthOfBook
        \o message.subscribeToNowPaidGivenWithBucketedSize
        \o message.subscribeToNowWamrWithConfidenceFactor
        \o message.subscribeToNowMidActivityIndicator

DecodeSubscriptionRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET subscriptionType == ReadBytes(sessionId.rest, 1) IN IF ~subscriptionType.ok THEN Fail ELSE
    LET instrumentIndex == ReadBytes(subscriptionType.rest, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET subscribeToNowDepthOfBook == ReadBytes(instrumentIndex.rest, 1) IN IF ~subscribeToNowDepthOfBook.ok THEN Fail ELSE
    IF Len(subscribeToNowDepthOfBook.rest) < 2 THEN Fail ELSE
    LET kept == SubSeq(subscribeToNowDepthOfBook.rest, Len(subscribeToNowDepthOfBook.rest) - 1, Len(subscribeToNowDepthOfBook.rest))
        subscribeToNowPaidGivenWithBucketedSize == Ok(SubSeq(subscribeToNowDepthOfBook.rest, 1, Len(subscribeToNowDepthOfBook.rest) - 2), << >>)
    IN  IF ~subscribeToNowPaidGivenWithBucketedSize.ok \/ subscribeToNowPaidGivenWithBucketedSize.rest # << >> THEN Fail ELSE
    LET subscribeToNowWamrWithConfidenceFactor == ReadBytes(kept, 1) IN IF ~subscribeToNowWamrWithConfidenceFactor.ok THEN Fail ELSE
    LET subscribeToNowMidActivityIndicator == ReadBytes(subscribeToNowWamrWithConfidenceFactor.rest, 1) IN IF ~subscribeToNowMidActivityIndicator.ok THEN Fail ELSE
    Ok([ sessionId                               |-> sessionId.value,
         subscriptionType                        |-> subscriptionType.value,
         instrumentIndex                         |-> instrumentIndex.value,
         subscribeToNowDepthOfBook               |-> subscribeToNowDepthOfBook.value,
         subscribeToNowPaidGivenWithBucketedSize |-> subscribeToNowPaidGivenWithBucketedSize.value,
         subscribeToNowWamrWithConfidenceFactor  |-> subscribeToNowWamrWithConfidenceFactor.value,
         subscribeToNowMidActivityIndicator      |-> subscribeToNowMidActivityIndicator.value ], subscribeToNowMidActivityIndicator.rest)

ZeroSubscriptionRequestMessage ==
    [ sessionId                               |-> [i \in 1 .. 4 |-> 0],
      subscriptionType                        |-> [i \in 1 .. 1 |-> 0],
      instrumentIndex                         |-> [i \in 1 .. 2 |-> 0],
      subscribeToNowDepthOfBook               |-> [i \in 1 .. 1 |-> 0],
      subscribeToNowPaidGivenWithBucketedSize |-> << >>,
      subscribeToNowWamrWithConfidenceFactor  |-> [i \in 1 .. 1 |-> 0],
      subscribeToNowMidActivityIndicator      |-> [i \in 1 .. 1 |-> 0] ]

(* Subscription Request Message at zero, then each field in turn at the values it is checked at *)
CheckedSubscriptionRequestMessage ==
    { ZeroSubscriptionRequestMessage }
        \cup { [ZeroSubscriptionRequestMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroSubscriptionRequestMessage EXCEPT !.subscriptionType = one] : one \in Sample(1) }
        \cup { [ZeroSubscriptionRequestMessage EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroSubscriptionRequestMessage EXCEPT !.subscribeToNowDepthOfBook = one] : one \in Sample(1) }
        \cup { [ZeroSubscriptionRequestMessage EXCEPT !.subscribeToNowPaidGivenWithBucketedSize = one] : one \in SampleBytes }
        \cup { [ZeroSubscriptionRequestMessage EXCEPT !.subscribeToNowWamrWithConfidenceFactor = one] : one \in Sample(1) }
        \cup { [ZeroSubscriptionRequestMessage EXCEPT !.subscribeToNowMidActivityIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Mass Subscription Request Message                                       *)
(***************************************************************************)

MassSubscriptionRequestMessage ==
    [ sessionId                               : Sample(4),
      subscriptionType                        : Sample(1),
      subscribeToNowDepthOfBook               : Sample(1),
      subscribeToNowPaidGivenWithBucketedSize : SampleBytes,
      subscribeToNowWamrWithConfidenceFactor  : Sample(1),
      subscribeToNowMidActivityIndicator      : Sample(1) ]

EncodeMassSubscriptionRequestMessage(message) ==
    message.sessionId
        \o message.subscriptionType
        \o message.subscribeToNowDepthOfBook
        \o message.subscribeToNowPaidGivenWithBucketedSize
        \o message.subscribeToNowWamrWithConfidenceFactor
        \o message.subscribeToNowMidActivityIndicator

DecodeMassSubscriptionRequestMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET subscriptionType == ReadBytes(sessionId.rest, 1) IN IF ~subscriptionType.ok THEN Fail ELSE
    LET subscribeToNowDepthOfBook == ReadBytes(subscriptionType.rest, 1) IN IF ~subscribeToNowDepthOfBook.ok THEN Fail ELSE
    IF Len(subscribeToNowDepthOfBook.rest) < 2 THEN Fail ELSE
    LET kept == SubSeq(subscribeToNowDepthOfBook.rest, Len(subscribeToNowDepthOfBook.rest) - 1, Len(subscribeToNowDepthOfBook.rest))
        subscribeToNowPaidGivenWithBucketedSize == Ok(SubSeq(subscribeToNowDepthOfBook.rest, 1, Len(subscribeToNowDepthOfBook.rest) - 2), << >>)
    IN  IF ~subscribeToNowPaidGivenWithBucketedSize.ok \/ subscribeToNowPaidGivenWithBucketedSize.rest # << >> THEN Fail ELSE
    LET subscribeToNowWamrWithConfidenceFactor == ReadBytes(kept, 1) IN IF ~subscribeToNowWamrWithConfidenceFactor.ok THEN Fail ELSE
    LET subscribeToNowMidActivityIndicator == ReadBytes(subscribeToNowWamrWithConfidenceFactor.rest, 1) IN IF ~subscribeToNowMidActivityIndicator.ok THEN Fail ELSE
    Ok([ sessionId                               |-> sessionId.value,
         subscriptionType                        |-> subscriptionType.value,
         subscribeToNowDepthOfBook               |-> subscribeToNowDepthOfBook.value,
         subscribeToNowPaidGivenWithBucketedSize |-> subscribeToNowPaidGivenWithBucketedSize.value,
         subscribeToNowWamrWithConfidenceFactor  |-> subscribeToNowWamrWithConfidenceFactor.value,
         subscribeToNowMidActivityIndicator      |-> subscribeToNowMidActivityIndicator.value ], subscribeToNowMidActivityIndicator.rest)

ZeroMassSubscriptionRequestMessage ==
    [ sessionId                               |-> [i \in 1 .. 4 |-> 0],
      subscriptionType                        |-> [i \in 1 .. 1 |-> 0],
      subscribeToNowDepthOfBook               |-> [i \in 1 .. 1 |-> 0],
      subscribeToNowPaidGivenWithBucketedSize |-> << >>,
      subscribeToNowWamrWithConfidenceFactor  |-> [i \in 1 .. 1 |-> 0],
      subscribeToNowMidActivityIndicator      |-> [i \in 1 .. 1 |-> 0] ]

(* Mass Subscription Request Message at zero, then each field in turn at the values it is checked at *)
CheckedMassSubscriptionRequestMessage ==
    { ZeroMassSubscriptionRequestMessage }
        \cup { [ZeroMassSubscriptionRequestMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroMassSubscriptionRequestMessage EXCEPT !.subscriptionType = one] : one \in Sample(1) }
        \cup { [ZeroMassSubscriptionRequestMessage EXCEPT !.subscribeToNowDepthOfBook = one] : one \in Sample(1) }
        \cup { [ZeroMassSubscriptionRequestMessage EXCEPT !.subscribeToNowPaidGivenWithBucketedSize = one] : one \in SampleBytes }
        \cup { [ZeroMassSubscriptionRequestMessage EXCEPT !.subscribeToNowWamrWithConfidenceFactor = one] : one \in Sample(1) }
        \cup { [ZeroMassSubscriptionRequestMessage EXCEPT !.subscribeToNowMidActivityIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Subscription Reply Message: 57 bytes                                    *)
(***************************************************************************)

SubscriptionReplyMessage ==
    [ sessionId       : Sample(4),
      instrumentIndex : Sample(2),
      type            : Sample(1),
      reasonAlpha50   : Sample(50) ]

EncodeSubscriptionReplyMessage(message) ==
    message.sessionId
        \o message.instrumentIndex
        \o message.type
        \o message.reasonAlpha50

DecodeSubscriptionReplyMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET instrumentIndex == ReadBytes(sessionId.rest, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET type == ReadBytes(instrumentIndex.rest, 1) IN IF ~type.ok THEN Fail ELSE
    LET reasonAlpha50 == ReadBytes(type.rest, 50) IN IF ~reasonAlpha50.ok THEN Fail ELSE
    Ok([ sessionId       |-> sessionId.value,
         instrumentIndex |-> instrumentIndex.value,
         type            |-> type.value,
         reasonAlpha50   |-> reasonAlpha50.value ], reasonAlpha50.rest)

ZeroSubscriptionReplyMessage ==
    [ sessionId       |-> [i \in 1 .. 4 |-> 0],
      instrumentIndex |-> [i \in 1 .. 2 |-> 0],
      type            |-> [i \in 1 .. 1 |-> 0],
      reasonAlpha50   |-> [i \in 1 .. 50 |-> 0] ]

(* Subscription Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedSubscriptionReplyMessage ==
    { ZeroSubscriptionReplyMessage }
        \cup { [ZeroSubscriptionReplyMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroSubscriptionReplyMessage EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroSubscriptionReplyMessage EXCEPT !.type = one] : one \in Sample(1) }
        \cup { [ZeroSubscriptionReplyMessage EXCEPT !.reasonAlpha50 = one] : one \in Sample(50) }

(***************************************************************************)
(* Mass Subscription Reply Message: 55 bytes                               *)
(***************************************************************************)

MassSubscriptionReplyMessage ==
    [ sessionId     : Sample(4),
      type          : Sample(1),
      reasonAlpha50 : Sample(50) ]

EncodeMassSubscriptionReplyMessage(message) ==
    message.sessionId
        \o message.type
        \o message.reasonAlpha50

DecodeMassSubscriptionReplyMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET type == ReadBytes(sessionId.rest, 1) IN IF ~type.ok THEN Fail ELSE
    LET reasonAlpha50 == ReadBytes(type.rest, 50) IN IF ~reasonAlpha50.ok THEN Fail ELSE
    Ok([ sessionId     |-> sessionId.value,
         type          |-> type.value,
         reasonAlpha50 |-> reasonAlpha50.value ], reasonAlpha50.rest)

ZeroMassSubscriptionReplyMessage ==
    [ sessionId     |-> [i \in 1 .. 4 |-> 0],
      type          |-> [i \in 1 .. 1 |-> 0],
      reasonAlpha50 |-> [i \in 1 .. 50 |-> 0] ]

(* Mass Subscription Reply Message at zero, then each field in turn at the values it is checked at *)
CheckedMassSubscriptionReplyMessage ==
    { ZeroMassSubscriptionReplyMessage }
        \cup { [ZeroMassSubscriptionReplyMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroMassSubscriptionReplyMessage EXCEPT !.type = one] : one \in Sample(1) }
        \cup { [ZeroMassSubscriptionReplyMessage EXCEPT !.reasonAlpha50 = one] : one \in Sample(50) }

(***************************************************************************)
(* Bid: 12 bytes                                                           *)
(***************************************************************************)

Bid ==
    [ rate   : Sample(4),
      amount : Sample(8) ]

EncodeBid(message) ==
    message.rate
        \o message.amount

DecodeBid(bytes) ==
    LET rate == ReadBytes(bytes, 4) IN IF ~rate.ok THEN Fail ELSE
    LET amount == ReadBytes(rate.rest, 8) IN IF ~amount.ok THEN Fail ELSE
    Ok([ rate   |-> rate.value,
         amount |-> amount.value ], amount.rest)

ZeroBid ==
    [ rate   |-> [i \in 1 .. 4 |-> 0],
      amount |-> [i \in 1 .. 8 |-> 0] ]

(* Bid at zero, then each field in turn at the values it is checked at *)
CheckedBid ==
    { ZeroBid }
        \cup { [ZeroBid EXCEPT !.rate = one] : one \in Sample(4) }
        \cup { [ZeroBid EXCEPT !.amount = one] : one \in Sample(8) }

(***************************************************************************)
(* Offer: 12 bytes                                                         *)
(***************************************************************************)

Offer ==
    [ rate   : Sample(4),
      amount : Sample(8) ]

EncodeOffer(message) ==
    message.rate
        \o message.amount

DecodeOffer(bytes) ==
    LET rate == ReadBytes(bytes, 4) IN IF ~rate.ok THEN Fail ELSE
    LET amount == ReadBytes(rate.rest, 8) IN IF ~amount.ok THEN Fail ELSE
    Ok([ rate   |-> rate.value,
         amount |-> amount.value ], amount.rest)

ZeroOffer ==
    [ rate   |-> [i \in 1 .. 4 |-> 0],
      amount |-> [i \in 1 .. 8 |-> 0] ]

(* Offer at zero, then each field in turn at the values it is checked at *)
CheckedOffer ==
    { ZeroOffer }
        \cup { [ZeroOffer EXCEPT !.rate = one] : one \in Sample(4) }
        \cup { [ZeroOffer EXCEPT !.amount = one] : one \in Sample(8) }

(***************************************************************************)
(* Level: 24 bytes                                                         *)
(***************************************************************************)

Level ==
    [ bid   : Bid,
      offer : Offer ]

EncodeLevel(message) ==
    EncodeBid(message.bid)
        \o EncodeOffer(message.offer)

DecodeLevel(bytes) ==
    LET bid == DecodeBid(bytes) IN IF ~bid.ok THEN Fail ELSE
    LET offer == DecodeOffer(bid.rest) IN IF ~offer.ok THEN Fail ELSE
    Ok([ bid   |-> bid.value,
         offer |-> offer.value ], offer.rest)

ZeroLevel ==
    [ bid   |-> ZeroBid,
      offer |-> ZeroOffer ]

(* Level at zero, then each field in turn at the values it is checked at *)
CheckedLevel ==
    { ZeroLevel }
        \cup { [ZeroLevel EXCEPT !.bid = one] : one \in CheckedBid }
        \cup { [ZeroLevel EXCEPT !.offer = one] : one \in CheckedOffer }

(* A run of Level, written one after another *)
RECURSIVE EncodeLevelList(_)
EncodeLevelList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeLevel(Head(messages)) \o EncodeLevelList(Tail(messages))

(* As many Level as the field that counts them says *)
RECURSIVE ReadLevelList(_, _)
ReadLevelList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeLevel(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadLevelList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Level of each kind, for the lists that carry them *)
OneLevel == { ZeroLevel }

(* The 20 slots a run of Level is written as, whatever the field beside it says are in use *)
SlotsLevel == { [i \in 1 .. 20 |-> one] : one \in OneLevel }

(***************************************************************************)
(* Depth Of Book Message                                                   *)
(***************************************************************************)

DepthOfBookMessage ==
    [ instrumentIndex : Sample(2),
      level           : SlotsLevel ]

EncodeDepthOfBookMessage(message) ==
    message.instrumentIndex
        \o EncodeLevelList(message.level)

DecodeDepthOfBookMessage(bytes) ==
    LET instrumentIndex == ReadBytes(bytes, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET level == ReadLevelList(instrumentIndex.rest, 20) IN IF ~level.ok THEN Fail ELSE
    Ok([ instrumentIndex |-> instrumentIndex.value,
         level           |-> level.value ], level.rest)

ZeroDepthOfBookMessage ==
    [ instrumentIndex |-> [i \in 1 .. 2 |-> 0],
      level           |-> [i \in 1 .. 20 |-> ZeroLevel] ]

(* Depth Of Book Message at zero, then each field in turn at the values it is checked at *)
CheckedDepthOfBookMessage ==
    { ZeroDepthOfBookMessage }
        \cup { [ZeroDepthOfBookMessage EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroDepthOfBookMessage EXCEPT !.level = one] : one \in SlotsLevel }

(***************************************************************************)
(* Paid Given Message: 16 bytes                                            *)
(***************************************************************************)

PaidGivenMessage ==
    [ instrumentIndex    : Sample(2),
      rate               : Sample(4),
      sizeIndicator      : Sample(1),
      paidGivenIndicator : Sample(1),
      transactTime       : Sample(8) ]

EncodePaidGivenMessage(message) ==
    message.instrumentIndex
        \o message.rate
        \o message.sizeIndicator
        \o message.paidGivenIndicator
        \o message.transactTime

DecodePaidGivenMessage(bytes) ==
    LET instrumentIndex == ReadBytes(bytes, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET rate == ReadBytes(instrumentIndex.rest, 4) IN IF ~rate.ok THEN Fail ELSE
    LET sizeIndicator == ReadBytes(rate.rest, 1) IN IF ~sizeIndicator.ok THEN Fail ELSE
    LET paidGivenIndicator == ReadBytes(sizeIndicator.rest, 1) IN IF ~paidGivenIndicator.ok THEN Fail ELSE
    LET transactTime == ReadBytes(paidGivenIndicator.rest, 8) IN IF ~transactTime.ok THEN Fail ELSE
    Ok([ instrumentIndex    |-> instrumentIndex.value,
         rate               |-> rate.value,
         sizeIndicator      |-> sizeIndicator.value,
         paidGivenIndicator |-> paidGivenIndicator.value,
         transactTime       |-> transactTime.value ], transactTime.rest)

ZeroPaidGivenMessage ==
    [ instrumentIndex    |-> [i \in 1 .. 2 |-> 0],
      rate               |-> [i \in 1 .. 4 |-> 0],
      sizeIndicator      |-> [i \in 1 .. 1 |-> 0],
      paidGivenIndicator |-> [i \in 1 .. 1 |-> 0],
      transactTime       |-> [i \in 1 .. 8 |-> 0] ]

(* Paid Given Message at zero, then each field in turn at the values it is checked at *)
CheckedPaidGivenMessage ==
    { ZeroPaidGivenMessage }
        \cup { [ZeroPaidGivenMessage EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroPaidGivenMessage EXCEPT !.rate = one] : one \in Sample(4) }
        \cup { [ZeroPaidGivenMessage EXCEPT !.sizeIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPaidGivenMessage EXCEPT !.paidGivenIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPaidGivenMessage EXCEPT !.transactTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Conf Factor 75: 8 bytes                                                 *)
(***************************************************************************)

ConfFactor75 ==
    [ bidPrice   : Sample(4),
      offerPrice : Sample(4) ]

EncodeConfFactor75(message) ==
    message.bidPrice
        \o message.offerPrice

DecodeConfFactor75(bytes) ==
    LET bidPrice == ReadBytes(bytes, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(bidPrice.rest, 4) IN IF ~offerPrice.ok THEN Fail ELSE
    Ok([ bidPrice   |-> bidPrice.value,
         offerPrice |-> offerPrice.value ], offerPrice.rest)

ZeroConfFactor75 ==
    [ bidPrice   |-> [i \in 1 .. 4 |-> 0],
      offerPrice |-> [i \in 1 .. 4 |-> 0] ]

(* Conf Factor 75 at zero, then each field in turn at the values it is checked at *)
CheckedConfFactor75 ==
    { ZeroConfFactor75 }
        \cup { [ZeroConfFactor75 EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroConfFactor75 EXCEPT !.offerPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Conf Factor 50: 8 bytes                                                 *)
(***************************************************************************)

ConfFactor50 ==
    [ bidPrice   : Sample(4),
      offerPrice : Sample(4) ]

EncodeConfFactor50(message) ==
    message.bidPrice
        \o message.offerPrice

DecodeConfFactor50(bytes) ==
    LET bidPrice == ReadBytes(bytes, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(bidPrice.rest, 4) IN IF ~offerPrice.ok THEN Fail ELSE
    Ok([ bidPrice   |-> bidPrice.value,
         offerPrice |-> offerPrice.value ], offerPrice.rest)

ZeroConfFactor50 ==
    [ bidPrice   |-> [i \in 1 .. 4 |-> 0],
      offerPrice |-> [i \in 1 .. 4 |-> 0] ]

(* Conf Factor 50 at zero, then each field in turn at the values it is checked at *)
CheckedConfFactor50 ==
    { ZeroConfFactor50 }
        \cup { [ZeroConfFactor50 EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroConfFactor50 EXCEPT !.offerPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Conf Factor 25: 8 bytes                                                 *)
(***************************************************************************)

ConfFactor25 ==
    [ bidPrice   : Sample(4),
      offerPrice : Sample(4) ]

EncodeConfFactor25(message) ==
    message.bidPrice
        \o message.offerPrice

DecodeConfFactor25(bytes) ==
    LET bidPrice == ReadBytes(bytes, 4) IN IF ~bidPrice.ok THEN Fail ELSE
    LET offerPrice == ReadBytes(bidPrice.rest, 4) IN IF ~offerPrice.ok THEN Fail ELSE
    Ok([ bidPrice   |-> bidPrice.value,
         offerPrice |-> offerPrice.value ], offerPrice.rest)

ZeroConfFactor25 ==
    [ bidPrice   |-> [i \in 1 .. 4 |-> 0],
      offerPrice |-> [i \in 1 .. 4 |-> 0] ]

(* Conf Factor 25 at zero, then each field in turn at the values it is checked at *)
CheckedConfFactor25 ==
    { ZeroConfFactor25 }
        \cup { [ZeroConfFactor25 EXCEPT !.bidPrice = one] : one \in Sample(4) }
        \cup { [ZeroConfFactor25 EXCEPT !.offerPrice = one] : one \in Sample(4) }

(***************************************************************************)
(* Wamr With Confidence Factor Message: 38 bytes                           *)
(***************************************************************************)

WamrWithConfidenceFactorMessage ==
    [ instrumentIndex : Sample(2),
      price           : Sample(4),
      confFactor75    : ConfFactor75,
      confFactor50    : ConfFactor50,
      confFactor25    : ConfFactor25,
      timestamp       : Sample(8) ]

EncodeWamrWithConfidenceFactorMessage(message) ==
    message.instrumentIndex
        \o message.price
        \o EncodeConfFactor75(message.confFactor75)
        \o EncodeConfFactor50(message.confFactor50)
        \o EncodeConfFactor25(message.confFactor25)
        \o message.timestamp

DecodeWamrWithConfidenceFactorMessage(bytes) ==
    LET instrumentIndex == ReadBytes(bytes, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET price == ReadBytes(instrumentIndex.rest, 4) IN IF ~price.ok THEN Fail ELSE
    LET confFactor75 == DecodeConfFactor75(price.rest) IN IF ~confFactor75.ok THEN Fail ELSE
    LET confFactor50 == DecodeConfFactor50(confFactor75.rest) IN IF ~confFactor50.ok THEN Fail ELSE
    LET confFactor25 == DecodeConfFactor25(confFactor50.rest) IN IF ~confFactor25.ok THEN Fail ELSE
    LET timestamp == ReadBytes(confFactor25.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    Ok([ instrumentIndex |-> instrumentIndex.value,
         price           |-> price.value,
         confFactor75    |-> confFactor75.value,
         confFactor50    |-> confFactor50.value,
         confFactor25    |-> confFactor25.value,
         timestamp       |-> timestamp.value ], timestamp.rest)

ZeroWamrWithConfidenceFactorMessage ==
    [ instrumentIndex |-> [i \in 1 .. 2 |-> 0],
      price           |-> [i \in 1 .. 4 |-> 0],
      confFactor75    |-> ZeroConfFactor75,
      confFactor50    |-> ZeroConfFactor50,
      confFactor25    |-> ZeroConfFactor25,
      timestamp       |-> [i \in 1 .. 8 |-> 0] ]

(* Wamr With Confidence Factor Message at zero, then each field in turn at the values it is checked at *)
CheckedWamrWithConfidenceFactorMessage ==
    { ZeroWamrWithConfidenceFactorMessage }
        \cup { [ZeroWamrWithConfidenceFactorMessage EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroWamrWithConfidenceFactorMessage EXCEPT !.price = one] : one \in Sample(4) }
        \cup { [ZeroWamrWithConfidenceFactorMessage EXCEPT !.confFactor75 = one] : one \in CheckedConfFactor75 }
        \cup { [ZeroWamrWithConfidenceFactorMessage EXCEPT !.confFactor50 = one] : one \in CheckedConfFactor50 }
        \cup { [ZeroWamrWithConfidenceFactorMessage EXCEPT !.confFactor25 = one] : one \in CheckedConfFactor25 }
        \cup { [ZeroWamrWithConfidenceFactorMessage EXCEPT !.timestamp = one] : one \in Sample(8) }

(***************************************************************************)
(* Mid Activity Indicator Message: 3 bytes                                 *)
(***************************************************************************)

MidActivityIndicatorMessage ==
    [ instrumentIndex   : Sample(2),
      activityIndicator : Sample(1) ]

EncodeMidActivityIndicatorMessage(message) ==
    message.instrumentIndex
        \o message.activityIndicator

DecodeMidActivityIndicatorMessage(bytes) ==
    LET instrumentIndex == ReadBytes(bytes, 2) IN IF ~instrumentIndex.ok THEN Fail ELSE
    LET activityIndicator == ReadBytes(instrumentIndex.rest, 1) IN IF ~activityIndicator.ok THEN Fail ELSE
    Ok([ instrumentIndex   |-> instrumentIndex.value,
         activityIndicator |-> activityIndicator.value ], activityIndicator.rest)

ZeroMidActivityIndicatorMessage ==
    [ instrumentIndex   |-> [i \in 1 .. 2 |-> 0],
      activityIndicator |-> [i \in 1 .. 1 |-> 0] ]

(* Mid Activity Indicator Message at zero, then each field in turn at the values it is checked at *)
CheckedMidActivityIndicatorMessage ==
    { ZeroMidActivityIndicatorMessage }
        \cup { [ZeroMidActivityIndicatorMessage EXCEPT !.instrumentIndex = one] : one \in Sample(2) }
        \cup { [ZeroMidActivityIndicatorMessage EXCEPT !.activityIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Reject Message: 55 bytes                                                *)
(***************************************************************************)

RejectMessage ==
    [ sessionId     : Sample(4),
      rejectMsgType : Sample(1),
      reasonAlpha50 : Sample(50) ]

EncodeRejectMessage(message) ==
    message.sessionId
        \o message.rejectMsgType
        \o message.reasonAlpha50

DecodeRejectMessage(bytes) ==
    LET sessionId == ReadBytes(bytes, 4) IN IF ~sessionId.ok THEN Fail ELSE
    LET rejectMsgType == ReadBytes(sessionId.rest, 1) IN IF ~rejectMsgType.ok THEN Fail ELSE
    LET reasonAlpha50 == ReadBytes(rejectMsgType.rest, 50) IN IF ~reasonAlpha50.ok THEN Fail ELSE
    Ok([ sessionId     |-> sessionId.value,
         rejectMsgType |-> rejectMsgType.value,
         reasonAlpha50 |-> reasonAlpha50.value ], reasonAlpha50.rest)

ZeroRejectMessage ==
    [ sessionId     |-> [i \in 1 .. 4 |-> 0],
      rejectMsgType |-> [i \in 1 .. 1 |-> 0],
      reasonAlpha50 |-> [i \in 1 .. 50 |-> 0] ]

(* Reject Message at zero, then each field in turn at the values it is checked at *)
CheckedRejectMessage ==
    { ZeroRejectMessage }
        \cup { [ZeroRejectMessage EXCEPT !.sessionId = one] : one \in Sample(4) }
        \cup { [ZeroRejectMessage EXCEPT !.rejectMsgType = one] : one \in Sample(1) }
        \cup { [ZeroRejectMessage EXCEPT !.reasonAlpha50 = one] : one \in Sample(50) }

(***************************************************************************)
(* Message Body, selected by Message Type                                  *)
(***************************************************************************)

LogonMessageCode == 65  \* "A"
LogoutMessageCode == 66  \* "B"
HeartBeatMessageCode == 67  \* "C"
InstrumentInfoCode == 68  \* "D"
InstrumentInfoAckMessageCode == 69  \* "E"
SubscriptionRequestMessageCode == 88  \* "X"
MassSubscriptionRequestMessageCode == 89  \* "Y"
SubscriptionReplyMessageCode == 71  \* "G"
MassSubscriptionReplyMessageCode == 90  \* "Z"
DepthOfBookMessageCode == 100  \* "d"
PaidGivenMessageCode == 107  \* "k"
WamrWithConfidenceFactorMessageCode == 114  \* "r"
MidActivityIndicatorMessageCode == 120  \* "x"
RejectMessageCode == 75  \* "K"

MessageBody ==
    [ tag : {LogonMessageCode}, body : LogonMessage ]
        \cup [ tag : {LogoutMessageCode}, body : LogoutMessage ]
        \cup [ tag : {HeartBeatMessageCode}, body : HeartBeatMessage ]
        \cup [ tag : {InstrumentInfoCode}, body : InstrumentInfo ]
        \cup [ tag : {InstrumentInfoAckMessageCode}, body : InstrumentInfoAckMessage ]
        \cup [ tag : {SubscriptionRequestMessageCode}, body : SubscriptionRequestMessage ]
        \cup [ tag : {MassSubscriptionRequestMessageCode}, body : MassSubscriptionRequestMessage ]
        \cup [ tag : {SubscriptionReplyMessageCode}, body : SubscriptionReplyMessage ]
        \cup [ tag : {MassSubscriptionReplyMessageCode}, body : MassSubscriptionReplyMessage ]
        \cup [ tag : {DepthOfBookMessageCode}, body : DepthOfBookMessage ]
        \cup [ tag : {PaidGivenMessageCode}, body : PaidGivenMessage ]
        \cup [ tag : {WamrWithConfidenceFactorMessageCode}, body : WamrWithConfidenceFactorMessage ]
        \cup [ tag : {MidActivityIndicatorMessageCode}, body : MidActivityIndicatorMessage ]
        \cup [ tag : {RejectMessageCode}, body : RejectMessage ]

EncodeMessageBody(message) ==
    CASE message.tag = LogonMessageCode -> EncodeLogonMessage(message.body)
      [] message.tag = LogoutMessageCode -> EncodeLogoutMessage(message.body)
      [] message.tag = HeartBeatMessageCode -> EncodeHeartBeatMessage(message.body)
      [] message.tag = InstrumentInfoCode -> EncodeInstrumentInfo(message.body)
      [] message.tag = InstrumentInfoAckMessageCode -> EncodeInstrumentInfoAckMessage(message.body)
      [] message.tag = SubscriptionRequestMessageCode -> EncodeSubscriptionRequestMessage(message.body)
      [] message.tag = MassSubscriptionRequestMessageCode -> EncodeMassSubscriptionRequestMessage(message.body)
      [] message.tag = SubscriptionReplyMessageCode -> EncodeSubscriptionReplyMessage(message.body)
      [] message.tag = MassSubscriptionReplyMessageCode -> EncodeMassSubscriptionReplyMessage(message.body)
      [] message.tag = DepthOfBookMessageCode -> EncodeDepthOfBookMessage(message.body)
      [] message.tag = PaidGivenMessageCode -> EncodePaidGivenMessage(message.body)
      [] message.tag = WamrWithConfidenceFactorMessageCode -> EncodeWamrWithConfidenceFactorMessage(message.body)
      [] message.tag = MidActivityIndicatorMessageCode -> EncodeMidActivityIndicatorMessage(message.body)
      [] message.tag = RejectMessageCode -> EncodeRejectMessage(message.body)

DecodeMessageBody(tag, bytes) ==
    LET read ==
            CASE tag = LogonMessageCode -> DecodeLogonMessage(bytes)
              [] tag = LogoutMessageCode -> DecodeLogoutMessage(bytes)
              [] tag = HeartBeatMessageCode -> DecodeHeartBeatMessage(bytes)
              [] tag = InstrumentInfoCode -> DecodeInstrumentInfo(bytes)
              [] tag = InstrumentInfoAckMessageCode -> DecodeInstrumentInfoAckMessage(bytes)
              [] tag = SubscriptionRequestMessageCode -> DecodeSubscriptionRequestMessage(bytes)
              [] tag = MassSubscriptionRequestMessageCode -> DecodeMassSubscriptionRequestMessage(bytes)
              [] tag = SubscriptionReplyMessageCode -> DecodeSubscriptionReplyMessage(bytes)
              [] tag = MassSubscriptionReplyMessageCode -> DecodeMassSubscriptionReplyMessage(bytes)
              [] tag = DepthOfBookMessageCode -> DecodeDepthOfBookMessage(bytes)
              [] tag = PaidGivenMessageCode -> DecodePaidGivenMessage(bytes)
              [] tag = WamrWithConfidenceFactorMessageCode -> DecodeWamrWithConfidenceFactorMessage(bytes)
              [] tag = MidActivityIndicatorMessageCode -> DecodeMidActivityIndicatorMessage(bytes)
              [] tag = RejectMessageCode -> DecodeRejectMessage(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroMessageBody == [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]

(* Each Message Body in turn, at the values the message it names is checked at *)
CheckedMessageBody ==
    { [tag |-> LogonMessageCode, body |-> one] : one \in CheckedLogonMessage }
        \cup { [tag |-> LogoutMessageCode, body |-> one] : one \in CheckedLogoutMessage }
        \cup { [tag |-> HeartBeatMessageCode, body |-> one] : one \in CheckedHeartBeatMessage }
        \cup { [tag |-> InstrumentInfoCode, body |-> one] : one \in CheckedInstrumentInfo }
        \cup { [tag |-> InstrumentInfoAckMessageCode, body |-> one] : one \in CheckedInstrumentInfoAckMessage }
        \cup { [tag |-> SubscriptionRequestMessageCode, body |-> one] : one \in CheckedSubscriptionRequestMessage }
        \cup { [tag |-> MassSubscriptionRequestMessageCode, body |-> one] : one \in CheckedMassSubscriptionRequestMessage }
        \cup { [tag |-> SubscriptionReplyMessageCode, body |-> one] : one \in CheckedSubscriptionReplyMessage }
        \cup { [tag |-> MassSubscriptionReplyMessageCode, body |-> one] : one \in CheckedMassSubscriptionReplyMessage }
        \cup { [tag |-> DepthOfBookMessageCode, body |-> one] : one \in CheckedDepthOfBookMessage }
        \cup { [tag |-> PaidGivenMessageCode, body |-> one] : one \in CheckedPaidGivenMessage }
        \cup { [tag |-> WamrWithConfidenceFactorMessageCode, body |-> one] : one \in CheckedWamrWithConfidenceFactorMessage }
        \cup { [tag |-> MidActivityIndicatorMessageCode, body |-> one] : one \in CheckedMidActivityIndicatorMessage }
        \cup { [tag |-> RejectMessageCode, body |-> one] : one \in CheckedRejectMessage }

(***************************************************************************)
(* Packet                                                                  *)
(***************************************************************************)

Packet ==
    [ itchSoh        : Sample(1),
      sequenceNumber : Sample(4),
      timestamp      : Sample(8),
      messageBody    : MessageBody,
      itchEtx        : Sample(1) ]

EncodePacket(message) ==
    message.itchSoh
        \o message.sequenceNumber
        \o message.timestamp
        \o EncodeUIntBE(message.messageBody.tag, 1)
        \o EncodeMessageBody(message.messageBody)
        \o message.itchEtx

DecodePacket(bytes) ==
    LET itchSoh == ReadBytes(bytes, 1) IN IF ~itchSoh.ok THEN Fail ELSE
    LET sequenceNumber == ReadBytes(itchSoh.rest, 4) IN IF ~sequenceNumber.ok THEN Fail ELSE
    LET timestamp == ReadBytes(sequenceNumber.rest, 8) IN IF ~timestamp.ok THEN Fail ELSE
    LET messageType == ReadUIntBE(timestamp.rest, 1) IN IF ~messageType.ok THEN Fail ELSE
    IF Len(messageType.rest) < 1 THEN Fail ELSE
    LET kept == SubSeq(messageType.rest, Len(messageType.rest), Len(messageType.rest))
        messageBody == DecodeMessageBody(messageType.value, SubSeq(messageType.rest, 1, Len(messageType.rest) - 1))
    IN  IF ~messageBody.ok \/ messageBody.rest # << >> THEN Fail ELSE
    LET itchEtx == ReadBytes(kept, 1) IN IF ~itchEtx.ok THEN Fail ELSE
    Ok([ itchSoh        |-> itchSoh.value,
         sequenceNumber |-> sequenceNumber.value,
         timestamp      |-> timestamp.value,
         messageBody    |-> messageBody.value,
         itchEtx        |-> itchEtx.value ], itchEtx.rest)

ZeroPacket ==
    [ itchSoh        |-> [i \in 1 .. 1 |-> 0],
      sequenceNumber |-> [i \in 1 .. 4 |-> 0],
      timestamp      |-> [i \in 1 .. 8 |-> 0],
      messageBody    |-> ZeroMessageBody,
      itchEtx        |-> [i \in 1 .. 1 |-> 0] ]

(* Packet at zero, then each field in turn at the values it is checked at *)
CheckedPacket ==
    { ZeroPacket }
        \cup { [ZeroPacket EXCEPT !.itchSoh = one] : one \in Sample(1) }
        \cup { [ZeroPacket EXCEPT !.sequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroPacket EXCEPT !.timestamp = one] : one \in Sample(8) }
        \cup { [ZeroPacket EXCEPT !.messageBody = one] : one \in CheckedMessageBody }
        \cup { [ZeroPacket EXCEPT !.itchEtx = one] : one \in Sample(1) }

(* A run of Packet, written one after another *)
RECURSIVE EncodePacketList(_)
EncodePacketList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePacket(Head(messages)) \o EncodePacketList(Tail(messages))

(* As many Packet as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadPacketAll(_)
ReadPacketAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodePacket(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPacketAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Packet of each kind, for the lists that carry them *)
OnePacket ==
    { [ZeroPacket EXCEPT !.messageBody = [tag |-> LogonMessageCode, body |-> ZeroLogonMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> LogoutMessageCode, body |-> ZeroLogoutMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> HeartBeatMessageCode, body |-> ZeroHeartBeatMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> InstrumentInfoCode, body |-> ZeroInstrumentInfo]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> InstrumentInfoAckMessageCode, body |-> ZeroInstrumentInfoAckMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> SubscriptionRequestMessageCode, body |-> ZeroSubscriptionRequestMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> MassSubscriptionRequestMessageCode, body |-> ZeroMassSubscriptionRequestMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> SubscriptionReplyMessageCode, body |-> ZeroSubscriptionReplyMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> MassSubscriptionReplyMessageCode, body |-> ZeroMassSubscriptionReplyMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> DepthOfBookMessageCode, body |-> ZeroDepthOfBookMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> PaidGivenMessageCode, body |-> ZeroPaidGivenMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> WamrWithConfidenceFactorMessageCode, body |-> ZeroWamrWithConfidenceFactorMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> MidActivityIndicatorMessageCode, body |-> ZeroMidActivityIndicatorMessage]],
      [ZeroPacket EXCEPT !.messageBody = [tag |-> RejectMessageCode, body |-> ZeroRejectMessage]] }

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

(* Every Logout Message decodes back to what was encoded, and leaves nothing over *)
RoundTripLogoutMessage ==
    \A message \in CheckedLogoutMessage :
        LET read == DecodeLogoutMessage(EncodeLogoutMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Heart Beat Message decodes back to what was encoded, and leaves nothing over *)
RoundTripHeartBeatMessage ==
    \A message \in CheckedHeartBeatMessage :
        LET read == DecodeHeartBeatMessage(EncodeHeartBeatMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Info decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentInfo ==
    \A message \in CheckedInstrumentInfo :
        LET read == DecodeInstrumentInfo(EncodeInstrumentInfo(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Instrument Info Ack Message decodes back to what was encoded, and leaves nothing over *)
RoundTripInstrumentInfoAckMessage ==
    \A message \in CheckedInstrumentInfoAckMessage :
        LET read == DecodeInstrumentInfoAckMessage(EncodeInstrumentInfoAckMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subscription Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubscriptionRequestMessage ==
    \A message \in CheckedSubscriptionRequestMessage :
        LET read == DecodeSubscriptionRequestMessage(EncodeSubscriptionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Subscription Request Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassSubscriptionRequestMessage ==
    \A message \in CheckedMassSubscriptionRequestMessage :
        LET read == DecodeMassSubscriptionRequestMessage(EncodeMassSubscriptionRequestMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Subscription Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripSubscriptionReplyMessage ==
    \A message \in CheckedSubscriptionReplyMessage :
        LET read == DecodeSubscriptionReplyMessage(EncodeSubscriptionReplyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Subscription Reply Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMassSubscriptionReplyMessage ==
    \A message \in CheckedMassSubscriptionReplyMessage :
        LET read == DecodeMassSubscriptionReplyMessage(EncodeMassSubscriptionReplyMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Bid decodes back to what was encoded, and leaves nothing over *)
RoundTripBid ==
    \A message \in CheckedBid :
        LET read == DecodeBid(EncodeBid(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Offer decodes back to what was encoded, and leaves nothing over *)
RoundTripOffer ==
    \A message \in CheckedOffer :
        LET read == DecodeOffer(EncodeOffer(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Level decodes back to what was encoded, and leaves nothing over *)
RoundTripLevel ==
    \A message \in CheckedLevel :
        LET read == DecodeLevel(EncodeLevel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Depth Of Book Message decodes back to what was encoded, and leaves nothing over *)
RoundTripDepthOfBookMessage ==
    \A message \in CheckedDepthOfBookMessage :
        LET read == DecodeDepthOfBookMessage(EncodeDepthOfBookMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Paid Given Message decodes back to what was encoded, and leaves nothing over *)
RoundTripPaidGivenMessage ==
    \A message \in CheckedPaidGivenMessage :
        LET read == DecodePaidGivenMessage(EncodePaidGivenMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Conf Factor 75 decodes back to what was encoded, and leaves nothing over *)
RoundTripConfFactor75 ==
    \A message \in CheckedConfFactor75 :
        LET read == DecodeConfFactor75(EncodeConfFactor75(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Conf Factor 50 decodes back to what was encoded, and leaves nothing over *)
RoundTripConfFactor50 ==
    \A message \in CheckedConfFactor50 :
        LET read == DecodeConfFactor50(EncodeConfFactor50(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Conf Factor 25 decodes back to what was encoded, and leaves nothing over *)
RoundTripConfFactor25 ==
    \A message \in CheckedConfFactor25 :
        LET read == DecodeConfFactor25(EncodeConfFactor25(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Wamr With Confidence Factor Message decodes back to what was encoded, and leaves nothing over *)
RoundTripWamrWithConfidenceFactorMessage ==
    \A message \in CheckedWamrWithConfidenceFactorMessage :
        LET read == DecodeWamrWithConfidenceFactorMessage(EncodeWamrWithConfidenceFactorMessage(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mid Activity Indicator Message decodes back to what was encoded, and leaves nothing over *)
RoundTripMidActivityIndicatorMessage ==
    \A message \in CheckedMidActivityIndicatorMessage :
        LET read == DecodeMidActivityIndicatorMessage(EncodeMidActivityIndicatorMessage(message))
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

(* Every Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripPacket ==
    \A message \in CheckedPacket :
        LET read == DecodePacket(EncodePacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Message Body is selected by the Message Type it is written under *)
SelectsMessageBody ==
    \A message \in CheckedMessageBody :
        LET read == DecodeMessageBody(message.tag, EncodeMessageBody(message))
        IN  read.ok /\ read.value.tag = message.tag

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
