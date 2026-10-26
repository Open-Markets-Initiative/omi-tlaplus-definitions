------------------ MODULE Cme_Globex_Mdp3_v1_8_ClientTcp -------------------
(***************************************************************************)
(* CME Group Market Data Platform 3 v1.8                                   *)
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
(* Client Technical Header: 14 bytes                                       *)
(***************************************************************************)

ClientTechnicalHeader ==
    [ encodingType          : Sample(2),
      messageSequenceNumber : Sample(4),
      tcpSendingTime        : Sample(8) ]

EncodeClientTechnicalHeader(message) ==
    message.encodingType
        \o message.messageSequenceNumber
        \o message.tcpSendingTime

DecodeClientTechnicalHeader(bytes) ==
    LET encodingType == ReadBytes(bytes, 2) IN IF ~encodingType.ok THEN Fail ELSE
    LET messageSequenceNumber == ReadBytes(encodingType.rest, 4) IN IF ~messageSequenceNumber.ok THEN Fail ELSE
    LET tcpSendingTime == ReadBytes(messageSequenceNumber.rest, 8) IN IF ~tcpSendingTime.ok THEN Fail ELSE
    Ok([ encodingType          |-> encodingType.value,
         messageSequenceNumber |-> messageSequenceNumber.value,
         tcpSendingTime        |-> tcpSendingTime.value ], tcpSendingTime.rest)

ZeroClientTechnicalHeader ==
    [ encodingType          |-> [i \in 1 .. 2 |-> 0],
      messageSequenceNumber |-> [i \in 1 .. 4 |-> 0],
      tcpSendingTime        |-> [i \in 1 .. 8 |-> 0] ]

(* Client Technical Header at zero, then each field in turn at the values it is checked at *)
CheckedClientTechnicalHeader ==
    { ZeroClientTechnicalHeader }
        \cup { [ZeroClientTechnicalHeader EXCEPT !.encodingType = one] : one \in Sample(2) }
        \cup { [ZeroClientTechnicalHeader EXCEPT !.messageSequenceNumber = one] : one \in Sample(4) }
        \cup { [ZeroClientTechnicalHeader EXCEPT !.tcpSendingTime = one] : one \in Sample(8) }

(***************************************************************************)
(* Negotiate: 78 bytes                                                     *)
(***************************************************************************)

Negotiate ==
    [ hmacSignature    : Sample(32),
      accessKeyId      : Sample(20),
      uuid             : Sample(8),
      requestTimestamp : Sample(8),
      session          : Sample(5),
      firm             : Sample(5) ]

EncodeNegotiate(message) ==
    message.hmacSignature
        \o message.accessKeyId
        \o message.uuid
        \o message.requestTimestamp
        \o message.session
        \o message.firm

DecodeNegotiate(bytes) ==
    LET hmacSignature == ReadBytes(bytes, 32) IN IF ~hmacSignature.ok THEN Fail ELSE
    LET accessKeyId == ReadBytes(hmacSignature.rest, 20) IN IF ~accessKeyId.ok THEN Fail ELSE
    LET uuid == ReadBytes(accessKeyId.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET session == ReadBytes(requestTimestamp.rest, 5) IN IF ~session.ok THEN Fail ELSE
    LET firm == ReadBytes(session.rest, 5) IN IF ~firm.ok THEN Fail ELSE
    Ok([ hmacSignature    |-> hmacSignature.value,
         accessKeyId      |-> accessKeyId.value,
         uuid             |-> uuid.value,
         requestTimestamp |-> requestTimestamp.value,
         session          |-> session.value,
         firm             |-> firm.value ], firm.rest)

ZeroNegotiate ==
    [ hmacSignature    |-> [i \in 1 .. 32 |-> 0],
      accessKeyId      |-> [i \in 1 .. 20 |-> 0],
      uuid             |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      session          |-> [i \in 1 .. 5 |-> 0],
      firm             |-> [i \in 1 .. 5 |-> 0] ]

(* Negotiate at zero, then each field in turn at the values it is checked at *)
CheckedNegotiate ==
    { ZeroNegotiate }
        \cup { [ZeroNegotiate EXCEPT !.hmacSignature = one] : one \in Sample(32) }
        \cup { [ZeroNegotiate EXCEPT !.accessKeyId = one] : one \in Sample(20) }
        \cup { [ZeroNegotiate EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroNegotiate EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroNegotiate EXCEPT !.session = one] : one \in Sample(5) }
        \cup { [ZeroNegotiate EXCEPT !.firm = one] : one \in Sample(5) }

(***************************************************************************)
(* Terminate: 70 bytes                                                     *)
(***************************************************************************)

Terminate ==
    [ reason           : Sample(48),
      uuid             : Sample(8),
      requestTimestamp : Sample(8),
      errorCodes       : Sample(1),
      padding5         : Sample(5) ]

EncodeTerminate(message) ==
    message.reason
        \o message.uuid
        \o message.requestTimestamp
        \o message.errorCodes
        \o message.padding5

DecodeTerminate(bytes) ==
    LET reason == ReadBytes(bytes, 48) IN IF ~reason.ok THEN Fail ELSE
    LET uuid == ReadBytes(reason.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET errorCodes == ReadBytes(requestTimestamp.rest, 1) IN IF ~errorCodes.ok THEN Fail ELSE
    LET padding5 == ReadBytes(errorCodes.rest, 5) IN IF ~padding5.ok THEN Fail ELSE
    Ok([ reason           |-> reason.value,
         uuid             |-> uuid.value,
         requestTimestamp |-> requestTimestamp.value,
         errorCodes       |-> errorCodes.value,
         padding5         |-> padding5.value ], padding5.rest)

ZeroTerminate ==
    [ reason           |-> [i \in 1 .. 48 |-> 0],
      uuid             |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      errorCodes       |-> [i \in 1 .. 1 |-> 0],
      padding5         |-> [i \in 1 .. 5 |-> 0] ]

(* Terminate at zero, then each field in turn at the values it is checked at *)
CheckedTerminate ==
    { ZeroTerminate }
        \cup { [ZeroTerminate EXCEPT !.reason = one] : one \in Sample(48) }
        \cup { [ZeroTerminate EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroTerminate EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTerminate EXCEPT !.errorCodes = one] : one \in Sample(1) }
        \cup { [ZeroTerminate EXCEPT !.padding5 = one] : one \in Sample(5) }

(***************************************************************************)
(* Market Data Request Security Group: 6 bytes                             *)
(***************************************************************************)

MarketDataRequestSecurityGroup ==
    [ securityGroup : Sample(6) ]

EncodeMarketDataRequestSecurityGroup(message) ==
    message.securityGroup

DecodeMarketDataRequestSecurityGroup(bytes) ==
    LET securityGroup == ReadBytes(bytes, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    Ok([ securityGroup |-> securityGroup.value ], securityGroup.rest)

ZeroMarketDataRequestSecurityGroup ==
    [ securityGroup |-> [i \in 1 .. 6 |-> 0] ]

(* Market Data Request Security Group at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataRequestSecurityGroup ==
    { ZeroMarketDataRequestSecurityGroup }
        \cup { [ZeroMarketDataRequestSecurityGroup EXCEPT !.securityGroup = one] : one \in Sample(6) }

(* A run of Market Data Request Security Group, written one after another *)
RECURSIVE EncodeMarketDataRequestSecurityGroupList(_)
EncodeMarketDataRequestSecurityGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketDataRequestSecurityGroup(Head(messages)) \o EncodeMarketDataRequestSecurityGroupList(Tail(messages))

(* As many Market Data Request Security Group as the field that counts them says *)
RECURSIVE ReadMarketDataRequestSecurityGroupList(_, _)
ReadMarketDataRequestSecurityGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketDataRequestSecurityGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketDataRequestSecurityGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Data Request Security Group of each kind, for the lists that carry them *)
OneMarketDataRequestSecurityGroup == { ZeroMarketDataRequestSecurityGroup }

(***************************************************************************)
(* Market Data Request Security Groups                                     *)
(***************************************************************************)

MarketDataRequestSecurityGroups ==
    [ blockLength                    : Sample(2),
      marketDataRequestSecurityGroup : SampleLists(OneMarketDataRequestSecurityGroup) ]

EncodeMarketDataRequestSecurityGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.marketDataRequestSecurityGroup), 1)
        \o EncodeMarketDataRequestSecurityGroupList(message.marketDataRequestSecurityGroup)

DecodeMarketDataRequestSecurityGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET marketDataRequestSecurityGroup == ReadMarketDataRequestSecurityGroupList(numInGroup.rest, numInGroup.value) IN IF ~marketDataRequestSecurityGroup.ok THEN Fail ELSE
    Ok([ blockLength                    |-> blockLength.value,
         marketDataRequestSecurityGroup |-> marketDataRequestSecurityGroup.value ], marketDataRequestSecurityGroup.rest)

ZeroMarketDataRequestSecurityGroups ==
    [ blockLength                    |-> [i \in 1 .. 2 |-> 0],
      marketDataRequestSecurityGroup |-> << >> ]

(* Market Data Request Security Groups at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataRequestSecurityGroups ==
    { ZeroMarketDataRequestSecurityGroups }
        \cup { [ZeroMarketDataRequestSecurityGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMarketDataRequestSecurityGroups EXCEPT !.marketDataRequestSecurityGroup = one] : one \in SampleLists(OneMarketDataRequestSecurityGroup) }

(***************************************************************************)
(* Market Data Request Related Symbol Group: 4 bytes                       *)
(***************************************************************************)

MarketDataRequestRelatedSymbolGroup ==
    [ securityId : Sample(4) ]

EncodeMarketDataRequestRelatedSymbolGroup(message) ==
    message.securityId

DecodeMarketDataRequestRelatedSymbolGroup(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value ], securityId.rest)

ZeroMarketDataRequestRelatedSymbolGroup ==
    [ securityId |-> [i \in 1 .. 4 |-> 0] ]

(* Market Data Request Related Symbol Group at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataRequestRelatedSymbolGroup ==
    { ZeroMarketDataRequestRelatedSymbolGroup }
        \cup { [ZeroMarketDataRequestRelatedSymbolGroup EXCEPT !.securityId = one] : one \in Sample(4) }

(* A run of Market Data Request Related Symbol Group, written one after another *)
RECURSIVE EncodeMarketDataRequestRelatedSymbolGroupList(_)
EncodeMarketDataRequestRelatedSymbolGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeMarketDataRequestRelatedSymbolGroup(Head(messages)) \o EncodeMarketDataRequestRelatedSymbolGroupList(Tail(messages))

(* As many Market Data Request Related Symbol Group as the field that counts them says *)
RECURSIVE ReadMarketDataRequestRelatedSymbolGroupList(_, _)
ReadMarketDataRequestRelatedSymbolGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeMarketDataRequestRelatedSymbolGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadMarketDataRequestRelatedSymbolGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Market Data Request Related Symbol Group of each kind, for the lists that carry them *)
OneMarketDataRequestRelatedSymbolGroup == { ZeroMarketDataRequestRelatedSymbolGroup }

(***************************************************************************)
(* Market Data Request Related Symbol Groups                               *)
(***************************************************************************)

MarketDataRequestRelatedSymbolGroups ==
    [ blockLength                         : Sample(2),
      marketDataRequestRelatedSymbolGroup : SampleLists(OneMarketDataRequestRelatedSymbolGroup) ]

EncodeMarketDataRequestRelatedSymbolGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.marketDataRequestRelatedSymbolGroup), 1)
        \o EncodeMarketDataRequestRelatedSymbolGroupList(message.marketDataRequestRelatedSymbolGroup)

DecodeMarketDataRequestRelatedSymbolGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET marketDataRequestRelatedSymbolGroup == ReadMarketDataRequestRelatedSymbolGroupList(numInGroup.rest, numInGroup.value) IN IF ~marketDataRequestRelatedSymbolGroup.ok THEN Fail ELSE
    Ok([ blockLength                         |-> blockLength.value,
         marketDataRequestRelatedSymbolGroup |-> marketDataRequestRelatedSymbolGroup.value ], marketDataRequestRelatedSymbolGroup.rest)

ZeroMarketDataRequestRelatedSymbolGroups ==
    [ blockLength                         |-> [i \in 1 .. 2 |-> 0],
      marketDataRequestRelatedSymbolGroup |-> << >> ]

(* Market Data Request Related Symbol Groups at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataRequestRelatedSymbolGroups ==
    { ZeroMarketDataRequestRelatedSymbolGroups }
        \cup { [ZeroMarketDataRequestRelatedSymbolGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroMarketDataRequestRelatedSymbolGroups EXCEPT !.marketDataRequestRelatedSymbolGroup = one] : one \in SampleLists(OneMarketDataRequestRelatedSymbolGroup) }

(***************************************************************************)
(* Market Data Request                                                     *)
(***************************************************************************)

MarketDataRequest ==
    [ mdReqId                              : Sample(4),
      subscriptionReqType                  : Sample(1),
      marketDataRequestSecurityGroups      : MarketDataRequestSecurityGroups,
      marketDataRequestRelatedSymbolGroups : MarketDataRequestRelatedSymbolGroups ]

EncodeMarketDataRequest(message) ==
    message.mdReqId
        \o message.subscriptionReqType
        \o EncodeMarketDataRequestSecurityGroups(message.marketDataRequestSecurityGroups)
        \o EncodeMarketDataRequestRelatedSymbolGroups(message.marketDataRequestRelatedSymbolGroups)

DecodeMarketDataRequest(bytes) ==
    LET mdReqId == ReadBytes(bytes, 4) IN IF ~mdReqId.ok THEN Fail ELSE
    LET subscriptionReqType == ReadBytes(mdReqId.rest, 1) IN IF ~subscriptionReqType.ok THEN Fail ELSE
    LET marketDataRequestSecurityGroups == DecodeMarketDataRequestSecurityGroups(subscriptionReqType.rest) IN IF ~marketDataRequestSecurityGroups.ok THEN Fail ELSE
    LET marketDataRequestRelatedSymbolGroups == DecodeMarketDataRequestRelatedSymbolGroups(marketDataRequestSecurityGroups.rest) IN IF ~marketDataRequestRelatedSymbolGroups.ok THEN Fail ELSE
    Ok([ mdReqId                              |-> mdReqId.value,
         subscriptionReqType                  |-> subscriptionReqType.value,
         marketDataRequestSecurityGroups      |-> marketDataRequestSecurityGroups.value,
         marketDataRequestRelatedSymbolGroups |-> marketDataRequestRelatedSymbolGroups.value ], marketDataRequestRelatedSymbolGroups.rest)

ZeroMarketDataRequest ==
    [ mdReqId                              |-> [i \in 1 .. 4 |-> 0],
      subscriptionReqType                  |-> [i \in 1 .. 1 |-> 0],
      marketDataRequestSecurityGroups      |-> ZeroMarketDataRequestSecurityGroups,
      marketDataRequestRelatedSymbolGroups |-> ZeroMarketDataRequestRelatedSymbolGroups ]

(* Market Data Request at zero, then each field in turn at the values it is checked at *)
CheckedMarketDataRequest ==
    { ZeroMarketDataRequest }
        \cup { [ZeroMarketDataRequest EXCEPT !.mdReqId = one] : one \in Sample(4) }
        \cup { [ZeroMarketDataRequest EXCEPT !.subscriptionReqType = one] : one \in Sample(1) }
        \cup { [ZeroMarketDataRequest EXCEPT !.marketDataRequestSecurityGroups = one] : one \in CheckedMarketDataRequestSecurityGroups }
        \cup { [ZeroMarketDataRequest EXCEPT !.marketDataRequestRelatedSymbolGroups = one] : one \in CheckedMarketDataRequestRelatedSymbolGroups }

(***************************************************************************)
(* Security List Request Security Group: 6 bytes                           *)
(***************************************************************************)

SecurityListRequestSecurityGroup ==
    [ securityGroup : Sample(6) ]

EncodeSecurityListRequestSecurityGroup(message) ==
    message.securityGroup

DecodeSecurityListRequestSecurityGroup(bytes) ==
    LET securityGroup == ReadBytes(bytes, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    Ok([ securityGroup |-> securityGroup.value ], securityGroup.rest)

ZeroSecurityListRequestSecurityGroup ==
    [ securityGroup |-> [i \in 1 .. 6 |-> 0] ]

(* Security List Request Security Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityListRequestSecurityGroup ==
    { ZeroSecurityListRequestSecurityGroup }
        \cup { [ZeroSecurityListRequestSecurityGroup EXCEPT !.securityGroup = one] : one \in Sample(6) }

(* A run of Security List Request Security Group, written one after another *)
RECURSIVE EncodeSecurityListRequestSecurityGroupList(_)
EncodeSecurityListRequestSecurityGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityListRequestSecurityGroup(Head(messages)) \o EncodeSecurityListRequestSecurityGroupList(Tail(messages))

(* As many Security List Request Security Group as the field that counts them says *)
RECURSIVE ReadSecurityListRequestSecurityGroupList(_, _)
ReadSecurityListRequestSecurityGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityListRequestSecurityGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityListRequestSecurityGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security List Request Security Group of each kind, for the lists that carry them *)
OneSecurityListRequestSecurityGroup == { ZeroSecurityListRequestSecurityGroup }

(***************************************************************************)
(* Security List Request Security Groups                                   *)
(***************************************************************************)

SecurityListRequestSecurityGroups ==
    [ blockLength                      : Sample(2),
      securityListRequestSecurityGroup : SampleLists(OneSecurityListRequestSecurityGroup) ]

EncodeSecurityListRequestSecurityGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.securityListRequestSecurityGroup), 1)
        \o EncodeSecurityListRequestSecurityGroupList(message.securityListRequestSecurityGroup)

DecodeSecurityListRequestSecurityGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityListRequestSecurityGroup == ReadSecurityListRequestSecurityGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityListRequestSecurityGroup.ok THEN Fail ELSE
    Ok([ blockLength                      |-> blockLength.value,
         securityListRequestSecurityGroup |-> securityListRequestSecurityGroup.value ], securityListRequestSecurityGroup.rest)

ZeroSecurityListRequestSecurityGroups ==
    [ blockLength                      |-> [i \in 1 .. 2 |-> 0],
      securityListRequestSecurityGroup |-> << >> ]

(* Security List Request Security Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityListRequestSecurityGroups ==
    { ZeroSecurityListRequestSecurityGroups }
        \cup { [ZeroSecurityListRequestSecurityGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityListRequestSecurityGroups EXCEPT !.securityListRequestSecurityGroup = one] : one \in SampleLists(OneSecurityListRequestSecurityGroup) }

(***************************************************************************)
(* Security List Request Related Symbol Group: 4 bytes                     *)
(***************************************************************************)

SecurityListRequestRelatedSymbolGroup ==
    [ securityId : Sample(4) ]

EncodeSecurityListRequestRelatedSymbolGroup(message) ==
    message.securityId

DecodeSecurityListRequestRelatedSymbolGroup(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value ], securityId.rest)

ZeroSecurityListRequestRelatedSymbolGroup ==
    [ securityId |-> [i \in 1 .. 4 |-> 0] ]

(* Security List Request Related Symbol Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityListRequestRelatedSymbolGroup ==
    { ZeroSecurityListRequestRelatedSymbolGroup }
        \cup { [ZeroSecurityListRequestRelatedSymbolGroup EXCEPT !.securityId = one] : one \in Sample(4) }

(* A run of Security List Request Related Symbol Group, written one after another *)
RECURSIVE EncodeSecurityListRequestRelatedSymbolGroupList(_)
EncodeSecurityListRequestRelatedSymbolGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityListRequestRelatedSymbolGroup(Head(messages)) \o EncodeSecurityListRequestRelatedSymbolGroupList(Tail(messages))

(* As many Security List Request Related Symbol Group as the field that counts them says *)
RECURSIVE ReadSecurityListRequestRelatedSymbolGroupList(_, _)
ReadSecurityListRequestRelatedSymbolGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityListRequestRelatedSymbolGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityListRequestRelatedSymbolGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security List Request Related Symbol Group of each kind, for the lists that carry them *)
OneSecurityListRequestRelatedSymbolGroup == { ZeroSecurityListRequestRelatedSymbolGroup }

(***************************************************************************)
(* Security List Request Related Symbol Groups                             *)
(***************************************************************************)

SecurityListRequestRelatedSymbolGroups ==
    [ blockLength                           : Sample(2),
      securityListRequestRelatedSymbolGroup : SampleLists(OneSecurityListRequestRelatedSymbolGroup) ]

EncodeSecurityListRequestRelatedSymbolGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.securityListRequestRelatedSymbolGroup), 1)
        \o EncodeSecurityListRequestRelatedSymbolGroupList(message.securityListRequestRelatedSymbolGroup)

DecodeSecurityListRequestRelatedSymbolGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityListRequestRelatedSymbolGroup == ReadSecurityListRequestRelatedSymbolGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityListRequestRelatedSymbolGroup.ok THEN Fail ELSE
    Ok([ blockLength                           |-> blockLength.value,
         securityListRequestRelatedSymbolGroup |-> securityListRequestRelatedSymbolGroup.value ], securityListRequestRelatedSymbolGroup.rest)

ZeroSecurityListRequestRelatedSymbolGroups ==
    [ blockLength                           |-> [i \in 1 .. 2 |-> 0],
      securityListRequestRelatedSymbolGroup |-> << >> ]

(* Security List Request Related Symbol Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityListRequestRelatedSymbolGroups ==
    { ZeroSecurityListRequestRelatedSymbolGroups }
        \cup { [ZeroSecurityListRequestRelatedSymbolGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityListRequestRelatedSymbolGroups EXCEPT !.securityListRequestRelatedSymbolGroup = one] : one \in SampleLists(OneSecurityListRequestRelatedSymbolGroup) }

(***************************************************************************)
(* Security List Request                                                   *)
(***************************************************************************)

SecurityListRequest ==
    [ mdReqId                                : Sample(4),
      subscriptionReqType                    : Sample(1),
      securityListRequestSecurityGroups      : SecurityListRequestSecurityGroups,
      securityListRequestRelatedSymbolGroups : SecurityListRequestRelatedSymbolGroups ]

EncodeSecurityListRequest(message) ==
    message.mdReqId
        \o message.subscriptionReqType
        \o EncodeSecurityListRequestSecurityGroups(message.securityListRequestSecurityGroups)
        \o EncodeSecurityListRequestRelatedSymbolGroups(message.securityListRequestRelatedSymbolGroups)

DecodeSecurityListRequest(bytes) ==
    LET mdReqId == ReadBytes(bytes, 4) IN IF ~mdReqId.ok THEN Fail ELSE
    LET subscriptionReqType == ReadBytes(mdReqId.rest, 1) IN IF ~subscriptionReqType.ok THEN Fail ELSE
    LET securityListRequestSecurityGroups == DecodeSecurityListRequestSecurityGroups(subscriptionReqType.rest) IN IF ~securityListRequestSecurityGroups.ok THEN Fail ELSE
    LET securityListRequestRelatedSymbolGroups == DecodeSecurityListRequestRelatedSymbolGroups(securityListRequestSecurityGroups.rest) IN IF ~securityListRequestRelatedSymbolGroups.ok THEN Fail ELSE
    Ok([ mdReqId                                |-> mdReqId.value,
         subscriptionReqType                    |-> subscriptionReqType.value,
         securityListRequestSecurityGroups      |-> securityListRequestSecurityGroups.value,
         securityListRequestRelatedSymbolGroups |-> securityListRequestRelatedSymbolGroups.value ], securityListRequestRelatedSymbolGroups.rest)

ZeroSecurityListRequest ==
    [ mdReqId                                |-> [i \in 1 .. 4 |-> 0],
      subscriptionReqType                    |-> [i \in 1 .. 1 |-> 0],
      securityListRequestSecurityGroups      |-> ZeroSecurityListRequestSecurityGroups,
      securityListRequestRelatedSymbolGroups |-> ZeroSecurityListRequestRelatedSymbolGroups ]

(* Security List Request at zero, then each field in turn at the values it is checked at *)
CheckedSecurityListRequest ==
    { ZeroSecurityListRequest }
        \cup { [ZeroSecurityListRequest EXCEPT !.mdReqId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityListRequest EXCEPT !.subscriptionReqType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityListRequest EXCEPT !.securityListRequestSecurityGroups = one] : one \in CheckedSecurityListRequestSecurityGroups }
        \cup { [ZeroSecurityListRequest EXCEPT !.securityListRequestRelatedSymbolGroups = one] : one \in CheckedSecurityListRequestRelatedSymbolGroups }

(***************************************************************************)
(* Security Status Request Security Group: 6 bytes                         *)
(***************************************************************************)

SecurityStatusRequestSecurityGroup ==
    [ securityGroup : Sample(6) ]

EncodeSecurityStatusRequestSecurityGroup(message) ==
    message.securityGroup

DecodeSecurityStatusRequestSecurityGroup(bytes) ==
    LET securityGroup == ReadBytes(bytes, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    Ok([ securityGroup |-> securityGroup.value ], securityGroup.rest)

ZeroSecurityStatusRequestSecurityGroup ==
    [ securityGroup |-> [i \in 1 .. 6 |-> 0] ]

(* Security Status Request Security Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusRequestSecurityGroup ==
    { ZeroSecurityStatusRequestSecurityGroup }
        \cup { [ZeroSecurityStatusRequestSecurityGroup EXCEPT !.securityGroup = one] : one \in Sample(6) }

(* A run of Security Status Request Security Group, written one after another *)
RECURSIVE EncodeSecurityStatusRequestSecurityGroupList(_)
EncodeSecurityStatusRequestSecurityGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityStatusRequestSecurityGroup(Head(messages)) \o EncodeSecurityStatusRequestSecurityGroupList(Tail(messages))

(* As many Security Status Request Security Group as the field that counts them says *)
RECURSIVE ReadSecurityStatusRequestSecurityGroupList(_, _)
ReadSecurityStatusRequestSecurityGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityStatusRequestSecurityGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityStatusRequestSecurityGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Status Request Security Group of each kind, for the lists that carry them *)
OneSecurityStatusRequestSecurityGroup == { ZeroSecurityStatusRequestSecurityGroup }

(***************************************************************************)
(* Security Status Request Security Groups                                 *)
(***************************************************************************)

SecurityStatusRequestSecurityGroups ==
    [ blockLength                        : Sample(2),
      securityStatusRequestSecurityGroup : SampleLists(OneSecurityStatusRequestSecurityGroup) ]

EncodeSecurityStatusRequestSecurityGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.securityStatusRequestSecurityGroup), 1)
        \o EncodeSecurityStatusRequestSecurityGroupList(message.securityStatusRequestSecurityGroup)

DecodeSecurityStatusRequestSecurityGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityStatusRequestSecurityGroup == ReadSecurityStatusRequestSecurityGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityStatusRequestSecurityGroup.ok THEN Fail ELSE
    Ok([ blockLength                        |-> blockLength.value,
         securityStatusRequestSecurityGroup |-> securityStatusRequestSecurityGroup.value ], securityStatusRequestSecurityGroup.rest)

ZeroSecurityStatusRequestSecurityGroups ==
    [ blockLength                        |-> [i \in 1 .. 2 |-> 0],
      securityStatusRequestSecurityGroup |-> << >> ]

(* Security Status Request Security Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusRequestSecurityGroups ==
    { ZeroSecurityStatusRequestSecurityGroups }
        \cup { [ZeroSecurityStatusRequestSecurityGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatusRequestSecurityGroups EXCEPT !.securityStatusRequestSecurityGroup = one] : one \in SampleLists(OneSecurityStatusRequestSecurityGroup) }

(***************************************************************************)
(* Security Status Request Related Symbol Group: 4 bytes                   *)
(***************************************************************************)

SecurityStatusRequestRelatedSymbolGroup ==
    [ securityId : Sample(4) ]

EncodeSecurityStatusRequestRelatedSymbolGroup(message) ==
    message.securityId

DecodeSecurityStatusRequestRelatedSymbolGroup(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    Ok([ securityId |-> securityId.value ], securityId.rest)

ZeroSecurityStatusRequestRelatedSymbolGroup ==
    [ securityId |-> [i \in 1 .. 4 |-> 0] ]

(* Security Status Request Related Symbol Group at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusRequestRelatedSymbolGroup ==
    { ZeroSecurityStatusRequestRelatedSymbolGroup }
        \cup { [ZeroSecurityStatusRequestRelatedSymbolGroup EXCEPT !.securityId = one] : one \in Sample(4) }

(* A run of Security Status Request Related Symbol Group, written one after another *)
RECURSIVE EncodeSecurityStatusRequestRelatedSymbolGroupList(_)
EncodeSecurityStatusRequestRelatedSymbolGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSecurityStatusRequestRelatedSymbolGroup(Head(messages)) \o EncodeSecurityStatusRequestRelatedSymbolGroupList(Tail(messages))

(* As many Security Status Request Related Symbol Group as the field that counts them says *)
RECURSIVE ReadSecurityStatusRequestRelatedSymbolGroupList(_, _)
ReadSecurityStatusRequestRelatedSymbolGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSecurityStatusRequestRelatedSymbolGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSecurityStatusRequestRelatedSymbolGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Security Status Request Related Symbol Group of each kind, for the lists that carry them *)
OneSecurityStatusRequestRelatedSymbolGroup == { ZeroSecurityStatusRequestRelatedSymbolGroup }

(***************************************************************************)
(* Security Status Request Related Symbol Groups                           *)
(***************************************************************************)

SecurityStatusRequestRelatedSymbolGroups ==
    [ blockLength                             : Sample(2),
      securityStatusRequestRelatedSymbolGroup : SampleLists(OneSecurityStatusRequestRelatedSymbolGroup) ]

EncodeSecurityStatusRequestRelatedSymbolGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.securityStatusRequestRelatedSymbolGroup), 1)
        \o EncodeSecurityStatusRequestRelatedSymbolGroupList(message.securityStatusRequestRelatedSymbolGroup)

DecodeSecurityStatusRequestRelatedSymbolGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET securityStatusRequestRelatedSymbolGroup == ReadSecurityStatusRequestRelatedSymbolGroupList(numInGroup.rest, numInGroup.value) IN IF ~securityStatusRequestRelatedSymbolGroup.ok THEN Fail ELSE
    Ok([ blockLength                             |-> blockLength.value,
         securityStatusRequestRelatedSymbolGroup |-> securityStatusRequestRelatedSymbolGroup.value ], securityStatusRequestRelatedSymbolGroup.rest)

ZeroSecurityStatusRequestRelatedSymbolGroups ==
    [ blockLength                             |-> [i \in 1 .. 2 |-> 0],
      securityStatusRequestRelatedSymbolGroup |-> << >> ]

(* Security Status Request Related Symbol Groups at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusRequestRelatedSymbolGroups ==
    { ZeroSecurityStatusRequestRelatedSymbolGroups }
        \cup { [ZeroSecurityStatusRequestRelatedSymbolGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSecurityStatusRequestRelatedSymbolGroups EXCEPT !.securityStatusRequestRelatedSymbolGroup = one] : one \in SampleLists(OneSecurityStatusRequestRelatedSymbolGroup) }

(***************************************************************************)
(* Security Status Request                                                 *)
(***************************************************************************)

SecurityStatusRequest ==
    [ mdReqId                                  : Sample(4),
      subscriptionReqType                      : Sample(1),
      securityStatusRequestSecurityGroups      : SecurityStatusRequestSecurityGroups,
      securityStatusRequestRelatedSymbolGroups : SecurityStatusRequestRelatedSymbolGroups ]

EncodeSecurityStatusRequest(message) ==
    message.mdReqId
        \o message.subscriptionReqType
        \o EncodeSecurityStatusRequestSecurityGroups(message.securityStatusRequestSecurityGroups)
        \o EncodeSecurityStatusRequestRelatedSymbolGroups(message.securityStatusRequestRelatedSymbolGroups)

DecodeSecurityStatusRequest(bytes) ==
    LET mdReqId == ReadBytes(bytes, 4) IN IF ~mdReqId.ok THEN Fail ELSE
    LET subscriptionReqType == ReadBytes(mdReqId.rest, 1) IN IF ~subscriptionReqType.ok THEN Fail ELSE
    LET securityStatusRequestSecurityGroups == DecodeSecurityStatusRequestSecurityGroups(subscriptionReqType.rest) IN IF ~securityStatusRequestSecurityGroups.ok THEN Fail ELSE
    LET securityStatusRequestRelatedSymbolGroups == DecodeSecurityStatusRequestRelatedSymbolGroups(securityStatusRequestSecurityGroups.rest) IN IF ~securityStatusRequestRelatedSymbolGroups.ok THEN Fail ELSE
    Ok([ mdReqId                                  |-> mdReqId.value,
         subscriptionReqType                      |-> subscriptionReqType.value,
         securityStatusRequestSecurityGroups      |-> securityStatusRequestSecurityGroups.value,
         securityStatusRequestRelatedSymbolGroups |-> securityStatusRequestRelatedSymbolGroups.value ], securityStatusRequestRelatedSymbolGroups.rest)

ZeroSecurityStatusRequest ==
    [ mdReqId                                  |-> [i \in 1 .. 4 |-> 0],
      subscriptionReqType                      |-> [i \in 1 .. 1 |-> 0],
      securityStatusRequestSecurityGroups      |-> ZeroSecurityStatusRequestSecurityGroups,
      securityStatusRequestRelatedSymbolGroups |-> ZeroSecurityStatusRequestRelatedSymbolGroups ]

(* Security Status Request at zero, then each field in turn at the values it is checked at *)
CheckedSecurityStatusRequest ==
    { ZeroSecurityStatusRequest }
        \cup { [ZeroSecurityStatusRequest EXCEPT !.mdReqId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityStatusRequest EXCEPT !.subscriptionReqType = one] : one \in Sample(1) }
        \cup { [ZeroSecurityStatusRequest EXCEPT !.securityStatusRequestSecurityGroups = one] : one \in CheckedSecurityStatusRequestSecurityGroups }
        \cup { [ZeroSecurityStatusRequest EXCEPT !.securityStatusRequestRelatedSymbolGroups = one] : one \in CheckedSecurityStatusRequestRelatedSymbolGroups }

(***************************************************************************)
(* Client Payload, selected by Template Id                                 *)
(***************************************************************************)

NegotiateCode == 200  \* 0xc8
TerminateCode == 203  \* 0xcb
MarketDataRequestCode == 205  \* 0xcd
SecurityListRequestCode == 208  \* 0xd0
SecurityStatusRequestCode == 209  \* 0xd1
SubscriberHeartbeatCode == 210  \* 0xd2

ClientPayload ==
    [ tag : {NegotiateCode}, body : Negotiate ]
        \cup [ tag : {TerminateCode}, body : Terminate ]
        \cup [ tag : {MarketDataRequestCode}, body : MarketDataRequest ]
        \cup [ tag : {SecurityListRequestCode}, body : SecurityListRequest ]
        \cup [ tag : {SecurityStatusRequestCode}, body : SecurityStatusRequest ]
        \cup [ tag : {SubscriberHeartbeatCode}, body : {[empty |-> 0]} ]

EncodeClientPayload(message) ==
    CASE message.tag = NegotiateCode -> EncodeNegotiate(message.body)
      [] message.tag = TerminateCode -> EncodeTerminate(message.body)
      [] message.tag = MarketDataRequestCode -> EncodeMarketDataRequest(message.body)
      [] message.tag = SecurityListRequestCode -> EncodeSecurityListRequest(message.body)
      [] message.tag = SecurityStatusRequestCode -> EncodeSecurityStatusRequest(message.body)
      [] message.tag = SubscriberHeartbeatCode -> << >>

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = NegotiateCode -> DecodeNegotiate(bytes)
              [] tag = TerminateCode -> DecodeTerminate(bytes)
              [] tag = MarketDataRequestCode -> DecodeMarketDataRequest(bytes)
              [] tag = SecurityListRequestCode -> DecodeSecurityListRequest(bytes)
              [] tag = SecurityStatusRequestCode -> DecodeSecurityStatusRequest(bytes)
              [] tag = SubscriberHeartbeatCode -> Ok([empty |-> 0], bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> NegotiateCode, body |-> ZeroNegotiate]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> NegotiateCode, body |-> one] : one \in CheckedNegotiate }
        \cup { [tag |-> TerminateCode, body |-> one] : one \in CheckedTerminate }
        \cup { [tag |-> MarketDataRequestCode, body |-> one] : one \in CheckedMarketDataRequest }
        \cup { [tag |-> SecurityListRequestCode, body |-> one] : one \in CheckedSecurityListRequest }
        \cup { [tag |-> SecurityStatusRequestCode, body |-> one] : one \in CheckedSecurityStatusRequest }
        \cup { [tag |-> SubscriberHeartbeatCode, body |-> [empty |-> 0]] }

(***************************************************************************)
(* Client Tcp Frame, framed by Message Size                                *)
(***************************************************************************)

ClientTcpFrame ==
    [ clientTechnicalHeader : ClientTechnicalHeader,
      blockLength           : Sample(2),
      schemaId              : Sample(2),
      version               : Sample(2),
      clientPayload         : ClientPayload ]

EncodeClientTcpFrameBody(message) ==
    message.blockLength
        \o EncodeUIntLE(message.clientPayload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodeClientPayload(message.clientPayload)

(* Message Size counts the bytes it frames, so it is written from them *)
EncodeClientTcpFrame(message) ==
    LET body == EncodeClientTcpFrameBody(message)
    IN  EncodeClientTechnicalHeader(message.clientTechnicalHeader) \o EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeClientTcpFrame(bytes) ==
    LET clientTechnicalHeader == DecodeClientTechnicalHeader(bytes) IN IF ~clientTechnicalHeader.ok THEN Fail ELSE
    LET length == ReadUIntLE(clientTechnicalHeader.rest, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
    IN
    LET blockLength == ReadBytes(framed, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(templateId.value, version.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    IF clientPayload.rest # << >> THEN Fail ELSE
    Ok([ clientTechnicalHeader |-> clientTechnicalHeader.value,
         blockLength           |-> blockLength.value,
         schemaId              |-> schemaId.value,
         version               |-> version.value,
         clientPayload         |-> clientPayload.value ], beyond)

ZeroClientTcpFrame ==
    [ clientTechnicalHeader |-> ZeroClientTechnicalHeader,
      blockLength           |-> [i \in 1 .. 2 |-> 0],
      schemaId              |-> [i \in 1 .. 2 |-> 0],
      version               |-> [i \in 1 .. 2 |-> 0],
      clientPayload         |-> ZeroClientPayload ]

(* Client Tcp Frame at zero, then each field in turn at the values it is checked at *)
CheckedClientTcpFrame ==
    { ZeroClientTcpFrame }
        \cup { [ZeroClientTcpFrame EXCEPT !.clientTechnicalHeader = one] : one \in CheckedClientTechnicalHeader }
        \cup { [ZeroClientTcpFrame EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroClientTcpFrame EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroClientTcpFrame EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroClientTcpFrame EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Tcp Frame, written one after another *)
RECURSIVE EncodeClientTcpFrameList(_)
EncodeClientTcpFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientTcpFrame(Head(messages)) \o EncodeClientTcpFrameList(Tail(messages))

(* As many Client Tcp Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientTcpFrameAll(_)
ReadClientTcpFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientTcpFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientTcpFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Tcp Frame of each kind, for the lists that carry them *)
OneClientTcpFrame ==
    { [ZeroClientTcpFrame EXCEPT !.clientPayload = [tag |-> NegotiateCode, body |-> ZeroNegotiate]],
      [ZeroClientTcpFrame EXCEPT !.clientPayload = [tag |-> TerminateCode, body |-> ZeroTerminate]],
      [ZeroClientTcpFrame EXCEPT !.clientPayload = [tag |-> MarketDataRequestCode, body |-> ZeroMarketDataRequest]],
      [ZeroClientTcpFrame EXCEPT !.clientPayload = [tag |-> SecurityListRequestCode, body |-> ZeroSecurityListRequest]],
      [ZeroClientTcpFrame EXCEPT !.clientPayload = [tag |-> SecurityStatusRequestCode, body |-> ZeroSecurityStatusRequest]],
      [ZeroClientTcpFrame EXCEPT !.clientPayload = [tag |-> SubscriberHeartbeatCode, body |-> [empty |-> 0]]] }

(***************************************************************************)
(* Client Tcp Packet                                                       *)
(***************************************************************************)

ClientTcpPacket ==
    [ clientTcpFrame : SampleLists(OneClientTcpFrame) ]

EncodeClientTcpPacket(message) ==
    EncodeClientTcpFrameList(message.clientTcpFrame)

DecodeClientTcpPacket(bytes) ==
    LET clientTcpFrame == ReadClientTcpFrameAll(bytes) IN IF ~clientTcpFrame.ok THEN Fail ELSE
    Ok([ clientTcpFrame |-> clientTcpFrame.value ], clientTcpFrame.rest)

ZeroClientTcpPacket ==
    [ clientTcpFrame |-> << >> ]

(* Client Tcp Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientTcpPacket ==
    { ZeroClientTcpPacket }
        \cup { [ZeroClientTcpPacket EXCEPT !.clientTcpFrame = one] : one \in SampleLists(OneClientTcpFrame) }

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

(* Every Client Technical Header decodes back to what was encoded, and leaves nothing over *)
RoundTripClientTechnicalHeader ==
    \A message \in CheckedClientTechnicalHeader :
        LET read == DecodeClientTechnicalHeader(EncodeClientTechnicalHeader(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Negotiate decodes back to what was encoded, and leaves nothing over *)
RoundTripNegotiate ==
    \A message \in CheckedNegotiate :
        LET read == DecodeNegotiate(EncodeNegotiate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Terminate decodes back to what was encoded, and leaves nothing over *)
RoundTripTerminate ==
    \A message \in CheckedTerminate :
        LET read == DecodeTerminate(EncodeTerminate(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Request Security Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataRequestSecurityGroup ==
    \A message \in CheckedMarketDataRequestSecurityGroup :
        LET read == DecodeMarketDataRequestSecurityGroup(EncodeMarketDataRequestSecurityGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Request Security Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataRequestSecurityGroups ==
    \A message \in CheckedMarketDataRequestSecurityGroups :
        LET read == DecodeMarketDataRequestSecurityGroups(EncodeMarketDataRequestSecurityGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Request Related Symbol Group decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataRequestRelatedSymbolGroup ==
    \A message \in CheckedMarketDataRequestRelatedSymbolGroup :
        LET read == DecodeMarketDataRequestRelatedSymbolGroup(EncodeMarketDataRequestRelatedSymbolGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Request Related Symbol Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataRequestRelatedSymbolGroups ==
    \A message \in CheckedMarketDataRequestRelatedSymbolGroups :
        LET read == DecodeMarketDataRequestRelatedSymbolGroups(EncodeMarketDataRequestRelatedSymbolGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Market Data Request decodes back to what was encoded, and leaves nothing over *)
RoundTripMarketDataRequest ==
    \A message \in CheckedMarketDataRequest :
        LET read == DecodeMarketDataRequest(EncodeMarketDataRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security List Request Security Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityListRequestSecurityGroup ==
    \A message \in CheckedSecurityListRequestSecurityGroup :
        LET read == DecodeSecurityListRequestSecurityGroup(EncodeSecurityListRequestSecurityGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security List Request Security Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityListRequestSecurityGroups ==
    \A message \in CheckedSecurityListRequestSecurityGroups :
        LET read == DecodeSecurityListRequestSecurityGroups(EncodeSecurityListRequestSecurityGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security List Request Related Symbol Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityListRequestRelatedSymbolGroup ==
    \A message \in CheckedSecurityListRequestRelatedSymbolGroup :
        LET read == DecodeSecurityListRequestRelatedSymbolGroup(EncodeSecurityListRequestRelatedSymbolGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security List Request Related Symbol Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityListRequestRelatedSymbolGroups ==
    \A message \in CheckedSecurityListRequestRelatedSymbolGroups :
        LET read == DecodeSecurityListRequestRelatedSymbolGroups(EncodeSecurityListRequestRelatedSymbolGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security List Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityListRequest ==
    \A message \in CheckedSecurityListRequest :
        LET read == DecodeSecurityListRequest(EncodeSecurityListRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Request Security Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusRequestSecurityGroup ==
    \A message \in CheckedSecurityStatusRequestSecurityGroup :
        LET read == DecodeSecurityStatusRequestSecurityGroup(EncodeSecurityStatusRequestSecurityGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Request Security Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusRequestSecurityGroups ==
    \A message \in CheckedSecurityStatusRequestSecurityGroups :
        LET read == DecodeSecurityStatusRequestSecurityGroups(EncodeSecurityStatusRequestSecurityGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Request Related Symbol Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusRequestRelatedSymbolGroup ==
    \A message \in CheckedSecurityStatusRequestRelatedSymbolGroup :
        LET read == DecodeSecurityStatusRequestRelatedSymbolGroup(EncodeSecurityStatusRequestRelatedSymbolGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Request Related Symbol Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusRequestRelatedSymbolGroups ==
    \A message \in CheckedSecurityStatusRequestRelatedSymbolGroups :
        LET read == DecodeSecurityStatusRequestRelatedSymbolGroups(EncodeSecurityStatusRequestRelatedSymbolGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Status Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityStatusRequest ==
    \A message \in CheckedSecurityStatusRequest :
        LET read == DecodeSecurityStatusRequest(EncodeSecurityStatusRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Tcp Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripClientTcpFrame ==
    \A message \in CheckedClientTcpFrame :
        LET read == DecodeClientTcpFrame(EncodeClientTcpFrame(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Tcp Packet decodes back to what was encoded, and leaves nothing over *)
RoundTripClientTcpPacket ==
    \A message \in CheckedClientTcpPacket :
        LET read == DecodeClientTcpPacket(EncodeClientTcpPacket(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* A Client Payload is selected by the Template Id it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Size is written from the bytes it frames *)
FramesClientTcpFrame ==
    \A message \in CheckedClientTcpFrame :
        LET bytes == EncodeClientTcpFrame(message)
        IN  DecodeUIntLE(SubSeq(bytes, 15, 16)) = Len(bytes) - 14

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
