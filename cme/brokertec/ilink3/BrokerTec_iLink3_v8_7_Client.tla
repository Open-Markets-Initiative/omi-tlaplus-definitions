------------------- MODULE BrokerTec_iLink3_v8_7_Client --------------------
(***************************************************************************)
(* CME Group iLink 3 v8.7                                                  *)
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
(* Note: Exec Inst is a bit field set, checked as its 1 byte rather than   *)
(* bit by bit.                                                             *)
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
(* Credentials                                                             *)
(***************************************************************************)

Credentials ==
    [ credentialsData : SampleBytes ]

EncodeCredentials(message) ==
    EncodeUIntLE(Len(message.credentialsData), 2)
        \o message.credentialsData

DecodeCredentials(bytes) ==
    LET credentialsLength == ReadUIntLE(bytes, 2) IN IF ~credentialsLength.ok THEN Fail ELSE
    LET credentialsData == ReadBytes(credentialsLength.rest, credentialsLength.value) IN IF ~credentialsData.ok THEN Fail ELSE
    Ok([ credentialsData |-> credentialsData.value ], credentialsData.rest)

ZeroCredentials ==
    [ credentialsData |-> << >> ]

(* Credentials at zero, then each field in turn at the values it is checked at *)
CheckedCredentials ==
    { ZeroCredentials }
        \cup { [ZeroCredentials EXCEPT !.credentialsData = one] : one \in SampleBytes }

(***************************************************************************)
(* Negotiate                                                               *)
(***************************************************************************)

Negotiate ==
    [ hmacSignature    : Sample(32),
      accessKeyId      : Sample(20),
      uuid             : Sample(8),
      requestTimestamp : Sample(8),
      session          : Sample(3),
      firm             : Sample(5),
      credentials      : Credentials ]

EncodeNegotiate(message) ==
    message.hmacSignature
        \o message.accessKeyId
        \o message.uuid
        \o message.requestTimestamp
        \o message.session
        \o message.firm
        \o EncodeCredentials(message.credentials)

DecodeNegotiate(bytes) ==
    LET hmacSignature == ReadBytes(bytes, 32) IN IF ~hmacSignature.ok THEN Fail ELSE
    LET accessKeyId == ReadBytes(hmacSignature.rest, 20) IN IF ~accessKeyId.ok THEN Fail ELSE
    LET uuid == ReadBytes(accessKeyId.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET session == ReadBytes(requestTimestamp.rest, 3) IN IF ~session.ok THEN Fail ELSE
    LET firm == ReadBytes(session.rest, 5) IN IF ~firm.ok THEN Fail ELSE
    LET credentials == DecodeCredentials(firm.rest) IN IF ~credentials.ok THEN Fail ELSE
    Ok([ hmacSignature    |-> hmacSignature.value,
         accessKeyId      |-> accessKeyId.value,
         uuid             |-> uuid.value,
         requestTimestamp |-> requestTimestamp.value,
         session          |-> session.value,
         firm             |-> firm.value,
         credentials      |-> credentials.value ], credentials.rest)

ZeroNegotiate ==
    [ hmacSignature    |-> [i \in 1 .. 32 |-> 0],
      accessKeyId      |-> [i \in 1 .. 20 |-> 0],
      uuid             |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      session          |-> [i \in 1 .. 3 |-> 0],
      firm             |-> [i \in 1 .. 5 |-> 0],
      credentials      |-> ZeroCredentials ]

(* Negotiate at zero, then each field in turn at the values it is checked at *)
CheckedNegotiate ==
    { ZeroNegotiate }
        \cup { [ZeroNegotiate EXCEPT !.hmacSignature = one] : one \in Sample(32) }
        \cup { [ZeroNegotiate EXCEPT !.accessKeyId = one] : one \in Sample(20) }
        \cup { [ZeroNegotiate EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroNegotiate EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroNegotiate EXCEPT !.session = one] : one \in Sample(3) }
        \cup { [ZeroNegotiate EXCEPT !.firm = one] : one \in Sample(5) }
        \cup { [ZeroNegotiate EXCEPT !.credentials = one] : one \in CheckedCredentials }

(***************************************************************************)
(* Credentials                                                             *)
(***************************************************************************)

Credentials2 ==
    [ credentialsData : SampleBytes ]

EncodeCredentials2(message) ==
    EncodeUIntLE(Len(message.credentialsData), 2)
        \o message.credentialsData

DecodeCredentials2(bytes) ==
    LET credentialsLength == ReadUIntLE(bytes, 2) IN IF ~credentialsLength.ok THEN Fail ELSE
    LET credentialsData == ReadBytes(credentialsLength.rest, credentialsLength.value) IN IF ~credentialsData.ok THEN Fail ELSE
    Ok([ credentialsData |-> credentialsData.value ], credentialsData.rest)

ZeroCredentials2 ==
    [ credentialsData |-> << >> ]

(* Credentials at zero, then each field in turn at the values it is checked at *)
CheckedCredentials2 ==
    { ZeroCredentials2 }
        \cup { [ZeroCredentials2 EXCEPT !.credentialsData = one] : one \in SampleBytes }

(***************************************************************************)
(* Establish                                                               *)
(***************************************************************************)

Establish ==
    [ hmacSignature        : Sample(32),
      accessKeyId          : Sample(20),
      tradingSystemName    : Sample(30),
      tradingSystemVersion : Sample(10),
      tradingSystemVendor  : Sample(10),
      uuid                 : Sample(8),
      requestTimestamp     : Sample(8),
      nextSeqNo            : Sample(4),
      session              : Sample(3),
      firm                 : Sample(5),
      keepAliveInterval    : Sample(2),
      credentials          : Credentials2 ]

EncodeEstablish(message) ==
    message.hmacSignature
        \o message.accessKeyId
        \o message.tradingSystemName
        \o message.tradingSystemVersion
        \o message.tradingSystemVendor
        \o message.uuid
        \o message.requestTimestamp
        \o message.nextSeqNo
        \o message.session
        \o message.firm
        \o message.keepAliveInterval
        \o EncodeCredentials2(message.credentials)

DecodeEstablish(bytes) ==
    LET hmacSignature == ReadBytes(bytes, 32) IN IF ~hmacSignature.ok THEN Fail ELSE
    LET accessKeyId == ReadBytes(hmacSignature.rest, 20) IN IF ~accessKeyId.ok THEN Fail ELSE
    LET tradingSystemName == ReadBytes(accessKeyId.rest, 30) IN IF ~tradingSystemName.ok THEN Fail ELSE
    LET tradingSystemVersion == ReadBytes(tradingSystemName.rest, 10) IN IF ~tradingSystemVersion.ok THEN Fail ELSE
    LET tradingSystemVendor == ReadBytes(tradingSystemVersion.rest, 10) IN IF ~tradingSystemVendor.ok THEN Fail ELSE
    LET uuid == ReadBytes(tradingSystemVendor.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET nextSeqNo == ReadBytes(requestTimestamp.rest, 4) IN IF ~nextSeqNo.ok THEN Fail ELSE
    LET session == ReadBytes(nextSeqNo.rest, 3) IN IF ~session.ok THEN Fail ELSE
    LET firm == ReadBytes(session.rest, 5) IN IF ~firm.ok THEN Fail ELSE
    LET keepAliveInterval == ReadBytes(firm.rest, 2) IN IF ~keepAliveInterval.ok THEN Fail ELSE
    LET credentials == DecodeCredentials2(keepAliveInterval.rest) IN IF ~credentials.ok THEN Fail ELSE
    Ok([ hmacSignature        |-> hmacSignature.value,
         accessKeyId          |-> accessKeyId.value,
         tradingSystemName    |-> tradingSystemName.value,
         tradingSystemVersion |-> tradingSystemVersion.value,
         tradingSystemVendor  |-> tradingSystemVendor.value,
         uuid                 |-> uuid.value,
         requestTimestamp     |-> requestTimestamp.value,
         nextSeqNo            |-> nextSeqNo.value,
         session              |-> session.value,
         firm                 |-> firm.value,
         keepAliveInterval    |-> keepAliveInterval.value,
         credentials          |-> credentials.value ], credentials.rest)

ZeroEstablish ==
    [ hmacSignature        |-> [i \in 1 .. 32 |-> 0],
      accessKeyId          |-> [i \in 1 .. 20 |-> 0],
      tradingSystemName    |-> [i \in 1 .. 30 |-> 0],
      tradingSystemVersion |-> [i \in 1 .. 10 |-> 0],
      tradingSystemVendor  |-> [i \in 1 .. 10 |-> 0],
      uuid                 |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp     |-> [i \in 1 .. 8 |-> 0],
      nextSeqNo            |-> [i \in 1 .. 4 |-> 0],
      session              |-> [i \in 1 .. 3 |-> 0],
      firm                 |-> [i \in 1 .. 5 |-> 0],
      keepAliveInterval    |-> [i \in 1 .. 2 |-> 0],
      credentials          |-> ZeroCredentials2 ]

(* Establish at zero, then each field in turn at the values it is checked at *)
CheckedEstablish ==
    { ZeroEstablish }
        \cup { [ZeroEstablish EXCEPT !.hmacSignature = one] : one \in Sample(32) }
        \cup { [ZeroEstablish EXCEPT !.accessKeyId = one] : one \in Sample(20) }
        \cup { [ZeroEstablish EXCEPT !.tradingSystemName = one] : one \in Sample(30) }
        \cup { [ZeroEstablish EXCEPT !.tradingSystemVersion = one] : one \in Sample(10) }
        \cup { [ZeroEstablish EXCEPT !.tradingSystemVendor = one] : one \in Sample(10) }
        \cup { [ZeroEstablish EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroEstablish EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroEstablish EXCEPT !.nextSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroEstablish EXCEPT !.session = one] : one \in Sample(3) }
        \cup { [ZeroEstablish EXCEPT !.firm = one] : one \in Sample(5) }
        \cup { [ZeroEstablish EXCEPT !.keepAliveInterval = one] : one \in Sample(2) }
        \cup { [ZeroEstablish EXCEPT !.credentials = one] : one \in CheckedCredentials2 }

(***************************************************************************)
(* Sequence: 14 bytes                                                      *)
(***************************************************************************)

Sequence ==
    [ uuid                    : Sample(8),
      nextSeqNo               : Sample(4),
      faultToleranceIndicator : Sample(1),
      keepAliveIntervalLapsed : Sample(1) ]

EncodeSequence(message) ==
    message.uuid
        \o message.nextSeqNo
        \o message.faultToleranceIndicator
        \o message.keepAliveIntervalLapsed

DecodeSequence(bytes) ==
    LET uuid == ReadBytes(bytes, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET nextSeqNo == ReadBytes(uuid.rest, 4) IN IF ~nextSeqNo.ok THEN Fail ELSE
    LET faultToleranceIndicator == ReadBytes(nextSeqNo.rest, 1) IN IF ~faultToleranceIndicator.ok THEN Fail ELSE
    LET keepAliveIntervalLapsed == ReadBytes(faultToleranceIndicator.rest, 1) IN IF ~keepAliveIntervalLapsed.ok THEN Fail ELSE
    Ok([ uuid                    |-> uuid.value,
         nextSeqNo               |-> nextSeqNo.value,
         faultToleranceIndicator |-> faultToleranceIndicator.value,
         keepAliveIntervalLapsed |-> keepAliveIntervalLapsed.value ], keepAliveIntervalLapsed.rest)

ZeroSequence ==
    [ uuid                    |-> [i \in 1 .. 8 |-> 0],
      nextSeqNo               |-> [i \in 1 .. 4 |-> 0],
      faultToleranceIndicator |-> [i \in 1 .. 1 |-> 0],
      keepAliveIntervalLapsed |-> [i \in 1 .. 1 |-> 0] ]

(* Sequence at zero, then each field in turn at the values it is checked at *)
CheckedSequence ==
    { ZeroSequence }
        \cup { [ZeroSequence EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroSequence EXCEPT !.nextSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroSequence EXCEPT !.faultToleranceIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSequence EXCEPT !.keepAliveIntervalLapsed = one] : one \in Sample(1) }

(***************************************************************************)
(* Terminate: 67 bytes                                                     *)
(***************************************************************************)

Terminate ==
    [ reason           : Sample(48),
      uuid             : Sample(8),
      requestTimestamp : Sample(8),
      errorCodes       : Sample(2),
      splitMsg         : Sample(1) ]

EncodeTerminate(message) ==
    message.reason
        \o message.uuid
        \o message.requestTimestamp
        \o message.errorCodes
        \o message.splitMsg

DecodeTerminate(bytes) ==
    LET reason == ReadBytes(bytes, 48) IN IF ~reason.ok THEN Fail ELSE
    LET uuid == ReadBytes(reason.rest, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(uuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET errorCodes == ReadBytes(requestTimestamp.rest, 2) IN IF ~errorCodes.ok THEN Fail ELSE
    LET splitMsg == ReadBytes(errorCodes.rest, 1) IN IF ~splitMsg.ok THEN Fail ELSE
    Ok([ reason           |-> reason.value,
         uuid             |-> uuid.value,
         requestTimestamp |-> requestTimestamp.value,
         errorCodes       |-> errorCodes.value,
         splitMsg         |-> splitMsg.value ], splitMsg.rest)

ZeroTerminate ==
    [ reason           |-> [i \in 1 .. 48 |-> 0],
      uuid             |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      errorCodes       |-> [i \in 1 .. 2 |-> 0],
      splitMsg         |-> [i \in 1 .. 1 |-> 0] ]

(* Terminate at zero, then each field in turn at the values it is checked at *)
CheckedTerminate ==
    { ZeroTerminate }
        \cup { [ZeroTerminate EXCEPT !.reason = one] : one \in Sample(48) }
        \cup { [ZeroTerminate EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroTerminate EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroTerminate EXCEPT !.errorCodes = one] : one \in Sample(2) }
        \cup { [ZeroTerminate EXCEPT !.splitMsg = one] : one \in Sample(1) }

(***************************************************************************)
(* Retransmit Request: 30 bytes                                            *)
(***************************************************************************)

RetransmitRequest ==
    [ uuid             : Sample(8),
      lastUuid         : Sample(8),
      requestTimestamp : Sample(8),
      fromSeqNo        : Sample(4),
      msgCount16       : Sample(2) ]

EncodeRetransmitRequest(message) ==
    message.uuid
        \o message.lastUuid
        \o message.requestTimestamp
        \o message.fromSeqNo
        \o message.msgCount16

DecodeRetransmitRequest(bytes) ==
    LET uuid == ReadBytes(bytes, 8) IN IF ~uuid.ok THEN Fail ELSE
    LET lastUuid == ReadBytes(uuid.rest, 8) IN IF ~lastUuid.ok THEN Fail ELSE
    LET requestTimestamp == ReadBytes(lastUuid.rest, 8) IN IF ~requestTimestamp.ok THEN Fail ELSE
    LET fromSeqNo == ReadBytes(requestTimestamp.rest, 4) IN IF ~fromSeqNo.ok THEN Fail ELSE
    LET msgCount16 == ReadBytes(fromSeqNo.rest, 2) IN IF ~msgCount16.ok THEN Fail ELSE
    Ok([ uuid             |-> uuid.value,
         lastUuid         |-> lastUuid.value,
         requestTimestamp |-> requestTimestamp.value,
         fromSeqNo        |-> fromSeqNo.value,
         msgCount16       |-> msgCount16.value ], msgCount16.rest)

ZeroRetransmitRequest ==
    [ uuid             |-> [i \in 1 .. 8 |-> 0],
      lastUuid         |-> [i \in 1 .. 8 |-> 0],
      requestTimestamp |-> [i \in 1 .. 8 |-> 0],
      fromSeqNo        |-> [i \in 1 .. 4 |-> 0],
      msgCount16       |-> [i \in 1 .. 2 |-> 0] ]

(* Retransmit Request at zero, then each field in turn at the values it is checked at *)
CheckedRetransmitRequest ==
    { ZeroRetransmitRequest }
        \cup { [ZeroRetransmitRequest EXCEPT !.uuid = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequest EXCEPT !.lastUuid = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequest EXCEPT !.requestTimestamp = one] : one \in Sample(8) }
        \cup { [ZeroRetransmitRequest EXCEPT !.fromSeqNo = one] : one \in Sample(4) }
        \cup { [ZeroRetransmitRequest EXCEPT !.msgCount16 = one] : one \in Sample(2) }

(***************************************************************************)
(* New Order Single: 124 bytes                                             *)
(***************************************************************************)

NewOrderSingle ==
    [ priceOptional         : Sample(8),
      orderQty              : Sample(4),
      securityId            : Sample(4),
      side                  : Sample(1),
      seqNum                : Sample(4),
      senderId              : Sample(20),
      clordid               : Sample(20),
      partyDetailsListReqId : Sample(8),
      orderRequestId        : Sample(8),
      sendingTimeEpoch      : Sample(8),
      stopPx                : Sample(8),
      location              : Sample(5),
      minQty                : Sample(4),
      displayQty            : Sample(4),
      expireDate            : Sample(2),
      ordType               : Sample(1),
      timeInForce           : Sample(1),
      manualOrderIndicator  : Sample(1),
      execInst              : Sample(1),
      executionMode         : Sample(1),
      liquidityFlag         : Sample(1),
      managedOrder          : Sample(1),
      shortSaleType         : Sample(1),
      discretionPrice       : Sample(8) ]

EncodeNewOrderSingle(message) ==
    message.priceOptional
        \o message.orderQty
        \o message.securityId
        \o message.side
        \o message.seqNum
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.orderRequestId
        \o message.sendingTimeEpoch
        \o message.stopPx
        \o message.location
        \o message.minQty
        \o message.displayQty
        \o message.expireDate
        \o message.ordType
        \o message.timeInForce
        \o message.manualOrderIndicator
        \o message.execInst
        \o message.executionMode
        \o message.liquidityFlag
        \o message.managedOrder
        \o message.shortSaleType
        \o message.discretionPrice

DecodeNewOrderSingle(bytes) ==
    LET priceOptional == ReadBytes(bytes, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET orderQty == ReadBytes(priceOptional.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET securityId == ReadBytes(orderQty.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET seqNum == ReadBytes(side.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET senderId == ReadBytes(seqNum.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(orderRequestId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET stopPx == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET location == ReadBytes(stopPx.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET minQty == ReadBytes(location.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(minQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(displayQty.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET ordType == ReadBytes(expireDate.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET execInst == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET executionMode == ReadBytes(execInst.rest, 1) IN IF ~executionMode.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionMode.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET managedOrder == ReadBytes(liquidityFlag.rest, 1) IN IF ~managedOrder.ok THEN Fail ELSE
    LET shortSaleType == ReadBytes(managedOrder.rest, 1) IN IF ~shortSaleType.ok THEN Fail ELSE
    LET discretionPrice == ReadBytes(shortSaleType.rest, 8) IN IF ~discretionPrice.ok THEN Fail ELSE
    Ok([ priceOptional         |-> priceOptional.value,
         orderQty              |-> orderQty.value,
         securityId            |-> securityId.value,
         side                  |-> side.value,
         seqNum                |-> seqNum.value,
         senderId              |-> senderId.value,
         clordid               |-> clordid.value,
         partyDetailsListReqId |-> partyDetailsListReqId.value,
         orderRequestId        |-> orderRequestId.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         stopPx                |-> stopPx.value,
         location              |-> location.value,
         minQty                |-> minQty.value,
         displayQty            |-> displayQty.value,
         expireDate            |-> expireDate.value,
         ordType               |-> ordType.value,
         timeInForce           |-> timeInForce.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         execInst              |-> execInst.value,
         executionMode         |-> executionMode.value,
         liquidityFlag         |-> liquidityFlag.value,
         managedOrder          |-> managedOrder.value,
         shortSaleType         |-> shortSaleType.value,
         discretionPrice       |-> discretionPrice.value ], discretionPrice.rest)

ZeroNewOrderSingle ==
    [ priceOptional         |-> [i \in 1 .. 8 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      seqNum                |-> [i \in 1 .. 4 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      clordid               |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      orderRequestId        |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      stopPx                |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      minQty                |-> [i \in 1 .. 4 |-> 0],
      displayQty            |-> [i \in 1 .. 4 |-> 0],
      expireDate            |-> [i \in 1 .. 2 |-> 0],
      ordType               |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      execInst              |-> [i \in 1 .. 1 |-> 0],
      executionMode         |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0],
      managedOrder          |-> [i \in 1 .. 1 |-> 0],
      shortSaleType         |-> [i \in 1 .. 1 |-> 0],
      discretionPrice       |-> [i \in 1 .. 8 |-> 0] ]

(* New Order Single at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderSingle ==
    { ZeroNewOrderSingle }
        \cup { [ZeroNewOrderSingle EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingle EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingle EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingle EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingle EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingle EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderSingle EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderSingle EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingle EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingle EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingle EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderSingle EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderSingle EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingle EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderSingle EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroNewOrderSingle EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingle EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingle EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingle EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingle EXCEPT !.executionMode = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingle EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingle EXCEPT !.managedOrder = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingle EXCEPT !.shortSaleType = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderSingle EXCEPT !.discretionPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancel Replace Request: 133 bytes                                 *)
(***************************************************************************)

OrderCancelReplaceRequest ==
    [ priceOptional         : Sample(8),
      orderQty              : Sample(4),
      securityId            : Sample(4),
      side                  : Sample(1),
      seqNum                : Sample(4),
      senderId              : Sample(20),
      clordid               : Sample(20),
      partyDetailsListReqId : Sample(8),
      orderIdOptional       : Sample(8),
      stopPx                : Sample(8),
      orderRequestId        : Sample(8),
      sendingTimeEpoch      : Sample(8),
      location              : Sample(5),
      minQty                : Sample(4),
      displayQty            : Sample(4),
      expireDate            : Sample(2),
      ordType               : Sample(1),
      timeInForce           : Sample(1),
      manualOrderIndicator  : Sample(1),
      ofmOverride           : Sample(1),
      execInst              : Sample(1),
      executionMode         : Sample(1),
      liquidityFlag         : Sample(1),
      managedOrder          : Sample(1),
      shortSaleType         : Sample(1),
      discretionPrice       : Sample(8) ]

EncodeOrderCancelReplaceRequest(message) ==
    message.priceOptional
        \o message.orderQty
        \o message.securityId
        \o message.side
        \o message.seqNum
        \o message.senderId
        \o message.clordid
        \o message.partyDetailsListReqId
        \o message.orderIdOptional
        \o message.stopPx
        \o message.orderRequestId
        \o message.sendingTimeEpoch
        \o message.location
        \o message.minQty
        \o message.displayQty
        \o message.expireDate
        \o message.ordType
        \o message.timeInForce
        \o message.manualOrderIndicator
        \o message.ofmOverride
        \o message.execInst
        \o message.executionMode
        \o message.liquidityFlag
        \o message.managedOrder
        \o message.shortSaleType
        \o message.discretionPrice

DecodeOrderCancelReplaceRequest(bytes) ==
    LET priceOptional == ReadBytes(bytes, 8) IN IF ~priceOptional.ok THEN Fail ELSE
    LET orderQty == ReadBytes(priceOptional.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET securityId == ReadBytes(orderQty.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET seqNum == ReadBytes(side.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET senderId == ReadBytes(seqNum.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderIdOptional == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET stopPx == ReadBytes(orderIdOptional.rest, 8) IN IF ~stopPx.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(stopPx.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(orderRequestId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET location == ReadBytes(sendingTimeEpoch.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET minQty == ReadBytes(location.rest, 4) IN IF ~minQty.ok THEN Fail ELSE
    LET displayQty == ReadBytes(minQty.rest, 4) IN IF ~displayQty.ok THEN Fail ELSE
    LET expireDate == ReadBytes(displayQty.rest, 2) IN IF ~expireDate.ok THEN Fail ELSE
    LET ordType == ReadBytes(expireDate.rest, 1) IN IF ~ordType.ok THEN Fail ELSE
    LET timeInForce == ReadBytes(ordType.rest, 1) IN IF ~timeInForce.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(timeInForce.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET ofmOverride == ReadBytes(manualOrderIndicator.rest, 1) IN IF ~ofmOverride.ok THEN Fail ELSE
    LET execInst == ReadBytes(ofmOverride.rest, 1) IN IF ~execInst.ok THEN Fail ELSE
    LET executionMode == ReadBytes(execInst.rest, 1) IN IF ~executionMode.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(executionMode.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET managedOrder == ReadBytes(liquidityFlag.rest, 1) IN IF ~managedOrder.ok THEN Fail ELSE
    LET shortSaleType == ReadBytes(managedOrder.rest, 1) IN IF ~shortSaleType.ok THEN Fail ELSE
    LET discretionPrice == ReadBytes(shortSaleType.rest, 8) IN IF ~discretionPrice.ok THEN Fail ELSE
    Ok([ priceOptional         |-> priceOptional.value,
         orderQty              |-> orderQty.value,
         securityId            |-> securityId.value,
         side                  |-> side.value,
         seqNum                |-> seqNum.value,
         senderId              |-> senderId.value,
         clordid               |-> clordid.value,
         partyDetailsListReqId |-> partyDetailsListReqId.value,
         orderIdOptional       |-> orderIdOptional.value,
         stopPx                |-> stopPx.value,
         orderRequestId        |-> orderRequestId.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         location              |-> location.value,
         minQty                |-> minQty.value,
         displayQty            |-> displayQty.value,
         expireDate            |-> expireDate.value,
         ordType               |-> ordType.value,
         timeInForce           |-> timeInForce.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         ofmOverride           |-> ofmOverride.value,
         execInst              |-> execInst.value,
         executionMode         |-> executionMode.value,
         liquidityFlag         |-> liquidityFlag.value,
         managedOrder          |-> managedOrder.value,
         shortSaleType         |-> shortSaleType.value,
         discretionPrice       |-> discretionPrice.value ], discretionPrice.rest)

ZeroOrderCancelReplaceRequest ==
    [ priceOptional         |-> [i \in 1 .. 8 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      seqNum                |-> [i \in 1 .. 4 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      clordid               |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      orderIdOptional       |-> [i \in 1 .. 8 |-> 0],
      stopPx                |-> [i \in 1 .. 8 |-> 0],
      orderRequestId        |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      minQty                |-> [i \in 1 .. 4 |-> 0],
      displayQty            |-> [i \in 1 .. 4 |-> 0],
      expireDate            |-> [i \in 1 .. 2 |-> 0],
      ordType               |-> [i \in 1 .. 1 |-> 0],
      timeInForce           |-> [i \in 1 .. 1 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      ofmOverride           |-> [i \in 1 .. 1 |-> 0],
      execInst              |-> [i \in 1 .. 1 |-> 0],
      executionMode         |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0],
      managedOrder          |-> [i \in 1 .. 1 |-> 0],
      shortSaleType         |-> [i \in 1 .. 1 |-> 0],
      discretionPrice       |-> [i \in 1 .. 8 |-> 0] ]

(* Order Cancel Replace Request at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelReplaceRequest ==
    { ZeroOrderCancelReplaceRequest }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.priceOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.stopPx = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.minQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.displayQty = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.expireDate = one] : one \in Sample(2) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.ordType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.timeInForce = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.ofmOverride = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.execInst = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.executionMode = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.managedOrder = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.shortSaleType = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelReplaceRequest EXCEPT !.discretionPrice = one] : one \in Sample(8) }

(***************************************************************************)
(* Order Cancel Request: 88 bytes                                          *)
(***************************************************************************)

OrderCancelRequest ==
    [ orderIdOptional       : Sample(8),
      partyDetailsListReqId : Sample(8),
      manualOrderIndicator  : Sample(1),
      seqNum                : Sample(4),
      senderId              : Sample(20),
      clordid               : Sample(20),
      orderRequestId        : Sample(8),
      sendingTimeEpoch      : Sample(8),
      location              : Sample(5),
      securityId            : Sample(4),
      side                  : Sample(1),
      liquidityFlag         : Sample(1) ]

EncodeOrderCancelRequest(message) ==
    message.orderIdOptional
        \o message.partyDetailsListReqId
        \o message.manualOrderIndicator
        \o message.seqNum
        \o message.senderId
        \o message.clordid
        \o message.orderRequestId
        \o message.sendingTimeEpoch
        \o message.location
        \o message.securityId
        \o message.side
        \o message.liquidityFlag

DecodeOrderCancelRequest(bytes) ==
    LET orderIdOptional == ReadBytes(bytes, 8) IN IF ~orderIdOptional.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(orderIdOptional.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(partyDetailsListReqId.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET seqNum == ReadBytes(manualOrderIndicator.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET senderId == ReadBytes(seqNum.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET clordid == ReadBytes(senderId.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(clordid.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(orderRequestId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET location == ReadBytes(sendingTimeEpoch.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET side == ReadBytes(securityId.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(side.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    Ok([ orderIdOptional       |-> orderIdOptional.value,
         partyDetailsListReqId |-> partyDetailsListReqId.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         seqNum                |-> seqNum.value,
         senderId              |-> senderId.value,
         clordid               |-> clordid.value,
         orderRequestId        |-> orderRequestId.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         location              |-> location.value,
         securityId            |-> securityId.value,
         side                  |-> side.value,
         liquidityFlag         |-> liquidityFlag.value ], liquidityFlag.rest)

ZeroOrderCancelRequest ==
    [ orderIdOptional       |-> [i \in 1 .. 8 |-> 0],
      partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      seqNum                |-> [i \in 1 .. 4 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      clordid               |-> [i \in 1 .. 20 |-> 0],
      orderRequestId        |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0] ]

(* Order Cancel Request at zero, then each field in turn at the values it is checked at *)
CheckedOrderCancelRequest ==
    { ZeroOrderCancelRequest }
        \cup { [ZeroOrderCancelRequest EXCEPT !.orderIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequest EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequest EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRequest EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRequest EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelRequest EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroOrderCancelRequest EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequest EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroOrderCancelRequest EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroOrderCancelRequest EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroOrderCancelRequest EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroOrderCancelRequest EXCEPT !.liquidityFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Quote Entries Group: 38 bytes                                           *)
(***************************************************************************)

QuoteEntriesGroup ==
    [ bidPx                : Sample(8),
      offerPx              : Sample(8),
      quoteEntryId         : Sample(4),
      securityId           : Sample(4),
      bidSize              : Sample(4),
      offerSize            : Sample(4),
      underlyingSecurityId : Sample(4),
      quoteSetId           : Sample(2) ]

EncodeQuoteEntriesGroup(message) ==
    message.bidPx
        \o message.offerPx
        \o message.quoteEntryId
        \o message.securityId
        \o message.bidSize
        \o message.offerSize
        \o message.underlyingSecurityId
        \o message.quoteSetId

DecodeQuoteEntriesGroup(bytes) ==
    LET bidPx == ReadBytes(bytes, 8) IN IF ~bidPx.ok THEN Fail ELSE
    LET offerPx == ReadBytes(bidPx.rest, 8) IN IF ~offerPx.ok THEN Fail ELSE
    LET quoteEntryId == ReadBytes(offerPx.rest, 4) IN IF ~quoteEntryId.ok THEN Fail ELSE
    LET securityId == ReadBytes(quoteEntryId.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET bidSize == ReadBytes(securityId.rest, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidSize.rest, 4) IN IF ~offerSize.ok THEN Fail ELSE
    LET underlyingSecurityId == ReadBytes(offerSize.rest, 4) IN IF ~underlyingSecurityId.ok THEN Fail ELSE
    LET quoteSetId == ReadBytes(underlyingSecurityId.rest, 2) IN IF ~quoteSetId.ok THEN Fail ELSE
    Ok([ bidPx                |-> bidPx.value,
         offerPx              |-> offerPx.value,
         quoteEntryId         |-> quoteEntryId.value,
         securityId           |-> securityId.value,
         bidSize              |-> bidSize.value,
         offerSize            |-> offerSize.value,
         underlyingSecurityId |-> underlyingSecurityId.value,
         quoteSetId           |-> quoteSetId.value ], quoteSetId.rest)

ZeroQuoteEntriesGroup ==
    [ bidPx                |-> [i \in 1 .. 8 |-> 0],
      offerPx              |-> [i \in 1 .. 8 |-> 0],
      quoteEntryId         |-> [i \in 1 .. 4 |-> 0],
      securityId           |-> [i \in 1 .. 4 |-> 0],
      bidSize              |-> [i \in 1 .. 4 |-> 0],
      offerSize            |-> [i \in 1 .. 4 |-> 0],
      underlyingSecurityId |-> [i \in 1 .. 4 |-> 0],
      quoteSetId           |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Entries Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteEntriesGroup ==
    { ZeroQuoteEntriesGroup }
        \cup { [ZeroQuoteEntriesGroup EXCEPT !.bidPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntriesGroup EXCEPT !.offerPx = one] : one \in Sample(8) }
        \cup { [ZeroQuoteEntriesGroup EXCEPT !.quoteEntryId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEntriesGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEntriesGroup EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEntriesGroup EXCEPT !.offerSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEntriesGroup EXCEPT !.underlyingSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteEntriesGroup EXCEPT !.quoteSetId = one] : one \in Sample(2) }

(* A run of Quote Entries Group, written one after another *)
RECURSIVE EncodeQuoteEntriesGroupList(_)
EncodeQuoteEntriesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteEntriesGroup(Head(messages)) \o EncodeQuoteEntriesGroupList(Tail(messages))

(* As many Quote Entries Group as the field that counts them says *)
RECURSIVE ReadQuoteEntriesGroupList(_, _)
ReadQuoteEntriesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteEntriesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteEntriesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Entries Group of each kind, for the lists that carry them *)
OneQuoteEntriesGroup == { ZeroQuoteEntriesGroup }

(***************************************************************************)
(* Quote Entries Groups                                                    *)
(***************************************************************************)

QuoteEntriesGroups ==
    [ blockLength       : Sample(2),
      quoteEntriesGroup : SampleLists(OneQuoteEntriesGroup) ]

EncodeQuoteEntriesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.quoteEntriesGroup), 1)
        \o EncodeQuoteEntriesGroupList(message.quoteEntriesGroup)

DecodeQuoteEntriesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET quoteEntriesGroup == ReadQuoteEntriesGroupList(numInGroup.rest, numInGroup.value) IN IF ~quoteEntriesGroup.ok THEN Fail ELSE
    Ok([ blockLength       |-> blockLength.value,
         quoteEntriesGroup |-> quoteEntriesGroup.value ], quoteEntriesGroup.rest)

ZeroQuoteEntriesGroups ==
    [ blockLength       |-> [i \in 1 .. 2 |-> 0],
      quoteEntriesGroup |-> << >> ]

(* Quote Entries Groups at zero, then each field in turn at the values it is checked at *)
CheckedQuoteEntriesGroups ==
    { ZeroQuoteEntriesGroups }
        \cup { [ZeroQuoteEntriesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroQuoteEntriesGroups EXCEPT !.quoteEntriesGroup = one] : one \in SampleLists(OneQuoteEntriesGroup) }

(***************************************************************************)
(* Mass Quote                                                              *)
(***************************************************************************)

MassQuote ==
    [ partyDetailsListReqId : Sample(8),
      sendingTimeEpoch      : Sample(8),
      manualOrderIndicator  : Sample(1),
      seqNum                : Sample(4),
      senderId              : Sample(20),
      quoteReqIdOptional    : Sample(8),
      location              : Sample(5),
      quoteId               : Sample(4),
      totNoQuoteEntries     : Sample(1),
      mmProtectionReset     : Sample(1),
      liquidityFlag         : Sample(1),
      shortSaleType         : Sample(1),
      reserved              : Sample(30),
      quoteEntriesGroups    : QuoteEntriesGroups ]

EncodeMassQuote(message) ==
    message.partyDetailsListReqId
        \o message.sendingTimeEpoch
        \o message.manualOrderIndicator
        \o message.seqNum
        \o message.senderId
        \o message.quoteReqIdOptional
        \o message.location
        \o message.quoteId
        \o message.totNoQuoteEntries
        \o message.mmProtectionReset
        \o message.liquidityFlag
        \o message.shortSaleType
        \o message.reserved
        \o EncodeQuoteEntriesGroups(message.quoteEntriesGroups)

DecodeMassQuote(bytes) ==
    LET partyDetailsListReqId == ReadBytes(bytes, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(sendingTimeEpoch.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET seqNum == ReadBytes(manualOrderIndicator.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET senderId == ReadBytes(seqNum.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET quoteReqIdOptional == ReadBytes(senderId.rest, 8) IN IF ~quoteReqIdOptional.ok THEN Fail ELSE
    LET location == ReadBytes(quoteReqIdOptional.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET quoteId == ReadBytes(location.rest, 4) IN IF ~quoteId.ok THEN Fail ELSE
    LET totNoQuoteEntries == ReadBytes(quoteId.rest, 1) IN IF ~totNoQuoteEntries.ok THEN Fail ELSE
    LET mmProtectionReset == ReadBytes(totNoQuoteEntries.rest, 1) IN IF ~mmProtectionReset.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(mmProtectionReset.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET shortSaleType == ReadBytes(liquidityFlag.rest, 1) IN IF ~shortSaleType.ok THEN Fail ELSE
    LET reserved == ReadBytes(shortSaleType.rest, 30) IN IF ~reserved.ok THEN Fail ELSE
    LET quoteEntriesGroups == DecodeQuoteEntriesGroups(reserved.rest) IN IF ~quoteEntriesGroups.ok THEN Fail ELSE
    Ok([ partyDetailsListReqId |-> partyDetailsListReqId.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         seqNum                |-> seqNum.value,
         senderId              |-> senderId.value,
         quoteReqIdOptional    |-> quoteReqIdOptional.value,
         location              |-> location.value,
         quoteId               |-> quoteId.value,
         totNoQuoteEntries     |-> totNoQuoteEntries.value,
         mmProtectionReset     |-> mmProtectionReset.value,
         liquidityFlag         |-> liquidityFlag.value,
         shortSaleType         |-> shortSaleType.value,
         reserved              |-> reserved.value,
         quoteEntriesGroups    |-> quoteEntriesGroups.value ], quoteEntriesGroups.rest)

ZeroMassQuote ==
    [ partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      seqNum                |-> [i \in 1 .. 4 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      quoteReqIdOptional    |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      quoteId               |-> [i \in 1 .. 4 |-> 0],
      totNoQuoteEntries     |-> [i \in 1 .. 1 |-> 0],
      mmProtectionReset     |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0],
      shortSaleType         |-> [i \in 1 .. 1 |-> 0],
      reserved              |-> [i \in 1 .. 30 |-> 0],
      quoteEntriesGroups    |-> ZeroQuoteEntriesGroups ]

(* Mass Quote at zero, then each field in turn at the values it is checked at *)
CheckedMassQuote ==
    { ZeroMassQuote }
        \cup { [ZeroMassQuote EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroMassQuote EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroMassQuote EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroMassQuote EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroMassQuote EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroMassQuote EXCEPT !.quoteReqIdOptional = one] : one \in Sample(8) }
        \cup { [ZeroMassQuote EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroMassQuote EXCEPT !.quoteId = one] : one \in Sample(4) }
        \cup { [ZeroMassQuote EXCEPT !.totNoQuoteEntries = one] : one \in Sample(1) }
        \cup { [ZeroMassQuote EXCEPT !.mmProtectionReset = one] : one \in Sample(1) }
        \cup { [ZeroMassQuote EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroMassQuote EXCEPT !.shortSaleType = one] : one \in Sample(1) }
        \cup { [ZeroMassQuote EXCEPT !.reserved = one] : one \in Sample(30) }
        \cup { [ZeroMassQuote EXCEPT !.quoteEntriesGroups = one] : one \in CheckedQuoteEntriesGroups }

(***************************************************************************)
(* Party Details Group: 22 bytes                                           *)
(***************************************************************************)

PartyDetailsGroup ==
    [ partyDetailId   : Sample(20),
      partyDetailRole : Sample(2) ]

EncodePartyDetailsGroup(message) ==
    message.partyDetailId
        \o message.partyDetailRole

DecodePartyDetailsGroup(bytes) ==
    LET partyDetailId == ReadBytes(bytes, 20) IN IF ~partyDetailId.ok THEN Fail ELSE
    LET partyDetailRole == ReadBytes(partyDetailId.rest, 2) IN IF ~partyDetailRole.ok THEN Fail ELSE
    Ok([ partyDetailId   |-> partyDetailId.value,
         partyDetailRole |-> partyDetailRole.value ], partyDetailRole.rest)

ZeroPartyDetailsGroup ==
    [ partyDetailId   |-> [i \in 1 .. 20 |-> 0],
      partyDetailRole |-> [i \in 1 .. 2 |-> 0] ]

(* Party Details Group at zero, then each field in turn at the values it is checked at *)
CheckedPartyDetailsGroup ==
    { ZeroPartyDetailsGroup }
        \cup { [ZeroPartyDetailsGroup EXCEPT !.partyDetailId = one] : one \in Sample(20) }
        \cup { [ZeroPartyDetailsGroup EXCEPT !.partyDetailRole = one] : one \in Sample(2) }

(* A run of Party Details Group, written one after another *)
RECURSIVE EncodePartyDetailsGroupList(_)
EncodePartyDetailsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartyDetailsGroup(Head(messages)) \o EncodePartyDetailsGroupList(Tail(messages))

(* As many Party Details Group as the field that counts them says *)
RECURSIVE ReadPartyDetailsGroupList(_, _)
ReadPartyDetailsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartyDetailsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartyDetailsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Party Details Group of each kind, for the lists that carry them *)
OnePartyDetailsGroup == { ZeroPartyDetailsGroup }

(***************************************************************************)
(* Party Details Groups                                                    *)
(***************************************************************************)

PartyDetailsGroups ==
    [ blockLength       : Sample(2),
      partyDetailsGroup : SampleLists(OnePartyDetailsGroup) ]

EncodePartyDetailsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.partyDetailsGroup), 1)
        \o EncodePartyDetailsGroupList(message.partyDetailsGroup)

DecodePartyDetailsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partyDetailsGroup == ReadPartyDetailsGroupList(numInGroup.rest, numInGroup.value) IN IF ~partyDetailsGroup.ok THEN Fail ELSE
    Ok([ blockLength       |-> blockLength.value,
         partyDetailsGroup |-> partyDetailsGroup.value ], partyDetailsGroup.rest)

ZeroPartyDetailsGroups ==
    [ blockLength       |-> [i \in 1 .. 2 |-> 0],
      partyDetailsGroup |-> << >> ]

(* Party Details Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartyDetailsGroups ==
    { ZeroPartyDetailsGroups }
        \cup { [ZeroPartyDetailsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroPartyDetailsGroups EXCEPT !.partyDetailsGroup = one] : one \in SampleLists(OnePartyDetailsGroup) }

(***************************************************************************)
(* Trd Reg Publications Group: 2 bytes                                     *)
(***************************************************************************)

TrdRegPublicationsGroup ==
    [ trdRegPublicationType   : Sample(1),
      trdRegPublicationReason : Sample(1) ]

EncodeTrdRegPublicationsGroup(message) ==
    message.trdRegPublicationType
        \o message.trdRegPublicationReason

DecodeTrdRegPublicationsGroup(bytes) ==
    LET trdRegPublicationType == ReadBytes(bytes, 1) IN IF ~trdRegPublicationType.ok THEN Fail ELSE
    LET trdRegPublicationReason == ReadBytes(trdRegPublicationType.rest, 1) IN IF ~trdRegPublicationReason.ok THEN Fail ELSE
    Ok([ trdRegPublicationType   |-> trdRegPublicationType.value,
         trdRegPublicationReason |-> trdRegPublicationReason.value ], trdRegPublicationReason.rest)

ZeroTrdRegPublicationsGroup ==
    [ trdRegPublicationType   |-> [i \in 1 .. 1 |-> 0],
      trdRegPublicationReason |-> [i \in 1 .. 1 |-> 0] ]

(* Trd Reg Publications Group at zero, then each field in turn at the values it is checked at *)
CheckedTrdRegPublicationsGroup ==
    { ZeroTrdRegPublicationsGroup }
        \cup { [ZeroTrdRegPublicationsGroup EXCEPT !.trdRegPublicationType = one] : one \in Sample(1) }
        \cup { [ZeroTrdRegPublicationsGroup EXCEPT !.trdRegPublicationReason = one] : one \in Sample(1) }

(* A run of Trd Reg Publications Group, written one after another *)
RECURSIVE EncodeTrdRegPublicationsGroupList(_)
EncodeTrdRegPublicationsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeTrdRegPublicationsGroup(Head(messages)) \o EncodeTrdRegPublicationsGroupList(Tail(messages))

(* As many Trd Reg Publications Group as the field that counts them says *)
RECURSIVE ReadTrdRegPublicationsGroupList(_, _)
ReadTrdRegPublicationsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeTrdRegPublicationsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadTrdRegPublicationsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Trd Reg Publications Group of each kind, for the lists that carry them *)
OneTrdRegPublicationsGroup == { ZeroTrdRegPublicationsGroup }

(***************************************************************************)
(* Trd Reg Publications Groups                                             *)
(***************************************************************************)

TrdRegPublicationsGroups ==
    [ blockLength             : Sample(2),
      trdRegPublicationsGroup : SampleLists(OneTrdRegPublicationsGroup) ]

EncodeTrdRegPublicationsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.trdRegPublicationsGroup), 1)
        \o EncodeTrdRegPublicationsGroupList(message.trdRegPublicationsGroup)

DecodeTrdRegPublicationsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET trdRegPublicationsGroup == ReadTrdRegPublicationsGroupList(numInGroup.rest, numInGroup.value) IN IF ~trdRegPublicationsGroup.ok THEN Fail ELSE
    Ok([ blockLength             |-> blockLength.value,
         trdRegPublicationsGroup |-> trdRegPublicationsGroup.value ], trdRegPublicationsGroup.rest)

ZeroTrdRegPublicationsGroups ==
    [ blockLength             |-> [i \in 1 .. 2 |-> 0],
      trdRegPublicationsGroup |-> << >> ]

(* Trd Reg Publications Groups at zero, then each field in turn at the values it is checked at *)
CheckedTrdRegPublicationsGroups ==
    { ZeroTrdRegPublicationsGroups }
        \cup { [ZeroTrdRegPublicationsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroTrdRegPublicationsGroups EXCEPT !.trdRegPublicationsGroup = one] : one \in SampleLists(OneTrdRegPublicationsGroup) }

(***************************************************************************)
(* Party Details Definition Request                                        *)
(***************************************************************************)

PartyDetailsDefinitionRequest ==
    [ partyDetailsListReqId          : Sample(8),
      sendingTimeEpoch               : Sample(8),
      listUpdateAction               : Sample(1),
      seqNum                         : Sample(4),
      memo                           : Sample(75),
      avgPxGroupId                   : Sample(20),
      selfMatchPreventionId          : Sample(8),
      cmtaGiveupCd                   : Sample(1),
      custOrderCapacity              : Sample(1),
      clearingAccountType            : Sample(1),
      selfMatchPreventionInstruction : Sample(1),
      avgPxIndicator                 : Sample(1),
      clearingTradePriceType         : Sample(1),
      custOrderHandlingInst          : Sample(1),
      executor                       : Sample(8),
      idmShortCode                   : Sample(8),
      partyDetailsGroups             : PartyDetailsGroups,
      trdRegPublicationsGroups       : TrdRegPublicationsGroups ]

EncodePartyDetailsDefinitionRequest(message) ==
    message.partyDetailsListReqId
        \o message.sendingTimeEpoch
        \o message.listUpdateAction
        \o message.seqNum
        \o message.memo
        \o message.avgPxGroupId
        \o message.selfMatchPreventionId
        \o message.cmtaGiveupCd
        \o message.custOrderCapacity
        \o message.clearingAccountType
        \o message.selfMatchPreventionInstruction
        \o message.avgPxIndicator
        \o message.clearingTradePriceType
        \o message.custOrderHandlingInst
        \o message.executor
        \o message.idmShortCode
        \o EncodePartyDetailsGroups(message.partyDetailsGroups)
        \o EncodeTrdRegPublicationsGroups(message.trdRegPublicationsGroups)

DecodePartyDetailsDefinitionRequest(bytes) ==
    LET partyDetailsListReqId == ReadBytes(bytes, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET listUpdateAction == ReadBytes(sendingTimeEpoch.rest, 1) IN IF ~listUpdateAction.ok THEN Fail ELSE
    LET seqNum == ReadBytes(listUpdateAction.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET memo == ReadBytes(seqNum.rest, 75) IN IF ~memo.ok THEN Fail ELSE
    LET avgPxGroupId == ReadBytes(memo.rest, 20) IN IF ~avgPxGroupId.ok THEN Fail ELSE
    LET selfMatchPreventionId == ReadBytes(avgPxGroupId.rest, 8) IN IF ~selfMatchPreventionId.ok THEN Fail ELSE
    LET cmtaGiveupCd == ReadBytes(selfMatchPreventionId.rest, 1) IN IF ~cmtaGiveupCd.ok THEN Fail ELSE
    LET custOrderCapacity == ReadBytes(cmtaGiveupCd.rest, 1) IN IF ~custOrderCapacity.ok THEN Fail ELSE
    LET clearingAccountType == ReadBytes(custOrderCapacity.rest, 1) IN IF ~clearingAccountType.ok THEN Fail ELSE
    LET selfMatchPreventionInstruction == ReadBytes(clearingAccountType.rest, 1) IN IF ~selfMatchPreventionInstruction.ok THEN Fail ELSE
    LET avgPxIndicator == ReadBytes(selfMatchPreventionInstruction.rest, 1) IN IF ~avgPxIndicator.ok THEN Fail ELSE
    LET clearingTradePriceType == ReadBytes(avgPxIndicator.rest, 1) IN IF ~clearingTradePriceType.ok THEN Fail ELSE
    LET custOrderHandlingInst == ReadBytes(clearingTradePriceType.rest, 1) IN IF ~custOrderHandlingInst.ok THEN Fail ELSE
    LET executor == ReadBytes(custOrderHandlingInst.rest, 8) IN IF ~executor.ok THEN Fail ELSE
    LET idmShortCode == ReadBytes(executor.rest, 8) IN IF ~idmShortCode.ok THEN Fail ELSE
    LET partyDetailsGroups == DecodePartyDetailsGroups(idmShortCode.rest) IN IF ~partyDetailsGroups.ok THEN Fail ELSE
    LET trdRegPublicationsGroups == DecodeTrdRegPublicationsGroups(partyDetailsGroups.rest) IN IF ~trdRegPublicationsGroups.ok THEN Fail ELSE
    Ok([ partyDetailsListReqId          |-> partyDetailsListReqId.value,
         sendingTimeEpoch               |-> sendingTimeEpoch.value,
         listUpdateAction               |-> listUpdateAction.value,
         seqNum                         |-> seqNum.value,
         memo                           |-> memo.value,
         avgPxGroupId                   |-> avgPxGroupId.value,
         selfMatchPreventionId          |-> selfMatchPreventionId.value,
         cmtaGiveupCd                   |-> cmtaGiveupCd.value,
         custOrderCapacity              |-> custOrderCapacity.value,
         clearingAccountType            |-> clearingAccountType.value,
         selfMatchPreventionInstruction |-> selfMatchPreventionInstruction.value,
         avgPxIndicator                 |-> avgPxIndicator.value,
         clearingTradePriceType         |-> clearingTradePriceType.value,
         custOrderHandlingInst          |-> custOrderHandlingInst.value,
         executor                       |-> executor.value,
         idmShortCode                   |-> idmShortCode.value,
         partyDetailsGroups             |-> partyDetailsGroups.value,
         trdRegPublicationsGroups       |-> trdRegPublicationsGroups.value ], trdRegPublicationsGroups.rest)

ZeroPartyDetailsDefinitionRequest ==
    [ partyDetailsListReqId          |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch               |-> [i \in 1 .. 8 |-> 0],
      listUpdateAction               |-> [i \in 1 .. 1 |-> 0],
      seqNum                         |-> [i \in 1 .. 4 |-> 0],
      memo                           |-> [i \in 1 .. 75 |-> 0],
      avgPxGroupId                   |-> [i \in 1 .. 20 |-> 0],
      selfMatchPreventionId          |-> [i \in 1 .. 8 |-> 0],
      cmtaGiveupCd                   |-> [i \in 1 .. 1 |-> 0],
      custOrderCapacity              |-> [i \in 1 .. 1 |-> 0],
      clearingAccountType            |-> [i \in 1 .. 1 |-> 0],
      selfMatchPreventionInstruction |-> [i \in 1 .. 1 |-> 0],
      avgPxIndicator                 |-> [i \in 1 .. 1 |-> 0],
      clearingTradePriceType         |-> [i \in 1 .. 1 |-> 0],
      custOrderHandlingInst          |-> [i \in 1 .. 1 |-> 0],
      executor                       |-> [i \in 1 .. 8 |-> 0],
      idmShortCode                   |-> [i \in 1 .. 8 |-> 0],
      partyDetailsGroups             |-> ZeroPartyDetailsGroups,
      trdRegPublicationsGroups       |-> ZeroTrdRegPublicationsGroups ]

(* Party Details Definition Request at zero, then each field in turn at the values it is checked at *)
CheckedPartyDetailsDefinitionRequest ==
    { ZeroPartyDetailsDefinitionRequest }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.listUpdateAction = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.memo = one] : one \in Sample(75) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.avgPxGroupId = one] : one \in Sample(20) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.selfMatchPreventionId = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.cmtaGiveupCd = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.custOrderCapacity = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.clearingAccountType = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.selfMatchPreventionInstruction = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.avgPxIndicator = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.clearingTradePriceType = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.custOrderHandlingInst = one] : one \in Sample(1) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.executor = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.idmShortCode = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.partyDetailsGroups = one] : one \in CheckedPartyDetailsGroups }
        \cup { [ZeroPartyDetailsDefinitionRequest EXCEPT !.trdRegPublicationsGroups = one] : one \in CheckedTrdRegPublicationsGroups }

(***************************************************************************)
(* Quote Cancel Entries Group: 10 bytes                                    *)
(***************************************************************************)

QuoteCancelEntriesGroup ==
    [ securityGroup      : Sample(6),
      securityIdOptional : Sample(4) ]

EncodeQuoteCancelEntriesGroup(message) ==
    message.securityGroup
        \o message.securityIdOptional

DecodeQuoteCancelEntriesGroup(bytes) ==
    LET securityGroup == ReadBytes(bytes, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    LET securityIdOptional == ReadBytes(securityGroup.rest, 4) IN IF ~securityIdOptional.ok THEN Fail ELSE
    Ok([ securityGroup      |-> securityGroup.value,
         securityIdOptional |-> securityIdOptional.value ], securityIdOptional.rest)

ZeroQuoteCancelEntriesGroup ==
    [ securityGroup      |-> [i \in 1 .. 6 |-> 0],
      securityIdOptional |-> [i \in 1 .. 4 |-> 0] ]

(* Quote Cancel Entries Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelEntriesGroup ==
    { ZeroQuoteCancelEntriesGroup }
        \cup { [ZeroQuoteCancelEntriesGroup EXCEPT !.securityGroup = one] : one \in Sample(6) }
        \cup { [ZeroQuoteCancelEntriesGroup EXCEPT !.securityIdOptional = one] : one \in Sample(4) }

(* A run of Quote Cancel Entries Group, written one after another *)
RECURSIVE EncodeQuoteCancelEntriesGroupList(_)
EncodeQuoteCancelEntriesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteCancelEntriesGroup(Head(messages)) \o EncodeQuoteCancelEntriesGroupList(Tail(messages))

(* As many Quote Cancel Entries Group as the field that counts them says *)
RECURSIVE ReadQuoteCancelEntriesGroupList(_, _)
ReadQuoteCancelEntriesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteCancelEntriesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteCancelEntriesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Cancel Entries Group of each kind, for the lists that carry them *)
OneQuoteCancelEntriesGroup == { ZeroQuoteCancelEntriesGroup }

(***************************************************************************)
(* Quote Cancel Entries Groups                                             *)
(***************************************************************************)

QuoteCancelEntriesGroups ==
    [ blockLength             : Sample(2),
      quoteCancelEntriesGroup : SampleLists(OneQuoteCancelEntriesGroup) ]

EncodeQuoteCancelEntriesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.quoteCancelEntriesGroup), 1)
        \o EncodeQuoteCancelEntriesGroupList(message.quoteCancelEntriesGroup)

DecodeQuoteCancelEntriesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET quoteCancelEntriesGroup == ReadQuoteCancelEntriesGroupList(numInGroup.rest, numInGroup.value) IN IF ~quoteCancelEntriesGroup.ok THEN Fail ELSE
    Ok([ blockLength             |-> blockLength.value,
         quoteCancelEntriesGroup |-> quoteCancelEntriesGroup.value ], quoteCancelEntriesGroup.rest)

ZeroQuoteCancelEntriesGroups ==
    [ blockLength             |-> [i \in 1 .. 2 |-> 0],
      quoteCancelEntriesGroup |-> << >> ]

(* Quote Cancel Entries Groups at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelEntriesGroups ==
    { ZeroQuoteCancelEntriesGroups }
        \cup { [ZeroQuoteCancelEntriesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroQuoteCancelEntriesGroups EXCEPT !.quoteCancelEntriesGroup = one] : one \in SampleLists(OneQuoteCancelEntriesGroup) }

(***************************************************************************)
(* Quote Cancel Sets Group: 10 bytes                                       *)
(***************************************************************************)

QuoteCancelSetsGroup ==
    [ bidSize    : Sample(4),
      offerSize  : Sample(4),
      quoteSetId : Sample(2) ]

EncodeQuoteCancelSetsGroup(message) ==
    message.bidSize
        \o message.offerSize
        \o message.quoteSetId

DecodeQuoteCancelSetsGroup(bytes) ==
    LET bidSize == ReadBytes(bytes, 4) IN IF ~bidSize.ok THEN Fail ELSE
    LET offerSize == ReadBytes(bidSize.rest, 4) IN IF ~offerSize.ok THEN Fail ELSE
    LET quoteSetId == ReadBytes(offerSize.rest, 2) IN IF ~quoteSetId.ok THEN Fail ELSE
    Ok([ bidSize    |-> bidSize.value,
         offerSize  |-> offerSize.value,
         quoteSetId |-> quoteSetId.value ], quoteSetId.rest)

ZeroQuoteCancelSetsGroup ==
    [ bidSize    |-> [i \in 1 .. 4 |-> 0],
      offerSize  |-> [i \in 1 .. 4 |-> 0],
      quoteSetId |-> [i \in 1 .. 2 |-> 0] ]

(* Quote Cancel Sets Group at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelSetsGroup ==
    { ZeroQuoteCancelSetsGroup }
        \cup { [ZeroQuoteCancelSetsGroup EXCEPT !.bidSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancelSetsGroup EXCEPT !.offerSize = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancelSetsGroup EXCEPT !.quoteSetId = one] : one \in Sample(2) }

(* A run of Quote Cancel Sets Group, written one after another *)
RECURSIVE EncodeQuoteCancelSetsGroupList(_)
EncodeQuoteCancelSetsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeQuoteCancelSetsGroup(Head(messages)) \o EncodeQuoteCancelSetsGroupList(Tail(messages))

(* As many Quote Cancel Sets Group as the field that counts them says *)
RECURSIVE ReadQuoteCancelSetsGroupList(_, _)
ReadQuoteCancelSetsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeQuoteCancelSetsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadQuoteCancelSetsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Quote Cancel Sets Group of each kind, for the lists that carry them *)
OneQuoteCancelSetsGroup == { ZeroQuoteCancelSetsGroup }

(***************************************************************************)
(* Quote Cancel Sets Groups                                                *)
(***************************************************************************)

QuoteCancelSetsGroups ==
    [ blockLength          : Sample(2),
      quoteCancelSetsGroup : SampleLists(OneQuoteCancelSetsGroup) ]

EncodeQuoteCancelSetsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.quoteCancelSetsGroup), 1)
        \o EncodeQuoteCancelSetsGroupList(message.quoteCancelSetsGroup)

DecodeQuoteCancelSetsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET quoteCancelSetsGroup == ReadQuoteCancelSetsGroupList(numInGroup.rest, numInGroup.value) IN IF ~quoteCancelSetsGroup.ok THEN Fail ELSE
    Ok([ blockLength          |-> blockLength.value,
         quoteCancelSetsGroup |-> quoteCancelSetsGroup.value ], quoteCancelSetsGroup.rest)

ZeroQuoteCancelSetsGroups ==
    [ blockLength          |-> [i \in 1 .. 2 |-> 0],
      quoteCancelSetsGroup |-> << >> ]

(* Quote Cancel Sets Groups at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancelSetsGroups ==
    { ZeroQuoteCancelSetsGroups }
        \cup { [ZeroQuoteCancelSetsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroQuoteCancelSetsGroups EXCEPT !.quoteCancelSetsGroup = one] : one \in SampleLists(OneQuoteCancelSetsGroup) }

(***************************************************************************)
(* Quote Cancel                                                            *)
(***************************************************************************)

QuoteCancel ==
    [ partyDetailsListReqId    : Sample(8),
      sendingTimeEpoch         : Sample(8),
      manualOrderIndicator     : Sample(1),
      seqNum                   : Sample(4),
      senderId                 : Sample(20),
      location                 : Sample(5),
      quoteId                  : Sample(4),
      quoteCancelType          : Sample(1),
      liquidityFlag            : Sample(1),
      quoteCancelEntriesGroups : QuoteCancelEntriesGroups,
      quoteCancelSetsGroups    : QuoteCancelSetsGroups ]

EncodeQuoteCancel(message) ==
    message.partyDetailsListReqId
        \o message.sendingTimeEpoch
        \o message.manualOrderIndicator
        \o message.seqNum
        \o message.senderId
        \o message.location
        \o message.quoteId
        \o message.quoteCancelType
        \o message.liquidityFlag
        \o EncodeQuoteCancelEntriesGroups(message.quoteCancelEntriesGroups)
        \o EncodeQuoteCancelSetsGroups(message.quoteCancelSetsGroups)

DecodeQuoteCancel(bytes) ==
    LET partyDetailsListReqId == ReadBytes(bytes, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(sendingTimeEpoch.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET seqNum == ReadBytes(manualOrderIndicator.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET senderId == ReadBytes(seqNum.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET location == ReadBytes(senderId.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET quoteId == ReadBytes(location.rest, 4) IN IF ~quoteId.ok THEN Fail ELSE
    LET quoteCancelType == ReadBytes(quoteId.rest, 1) IN IF ~quoteCancelType.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(quoteCancelType.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    LET quoteCancelEntriesGroups == DecodeQuoteCancelEntriesGroups(liquidityFlag.rest) IN IF ~quoteCancelEntriesGroups.ok THEN Fail ELSE
    LET quoteCancelSetsGroups == DecodeQuoteCancelSetsGroups(quoteCancelEntriesGroups.rest) IN IF ~quoteCancelSetsGroups.ok THEN Fail ELSE
    Ok([ partyDetailsListReqId    |-> partyDetailsListReqId.value,
         sendingTimeEpoch         |-> sendingTimeEpoch.value,
         manualOrderIndicator     |-> manualOrderIndicator.value,
         seqNum                   |-> seqNum.value,
         senderId                 |-> senderId.value,
         location                 |-> location.value,
         quoteId                  |-> quoteId.value,
         quoteCancelType          |-> quoteCancelType.value,
         liquidityFlag            |-> liquidityFlag.value,
         quoteCancelEntriesGroups |-> quoteCancelEntriesGroups.value,
         quoteCancelSetsGroups    |-> quoteCancelSetsGroups.value ], quoteCancelSetsGroups.rest)

ZeroQuoteCancel ==
    [ partyDetailsListReqId    |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch         |-> [i \in 1 .. 8 |-> 0],
      manualOrderIndicator     |-> [i \in 1 .. 1 |-> 0],
      seqNum                   |-> [i \in 1 .. 4 |-> 0],
      senderId                 |-> [i \in 1 .. 20 |-> 0],
      location                 |-> [i \in 1 .. 5 |-> 0],
      quoteId                  |-> [i \in 1 .. 4 |-> 0],
      quoteCancelType          |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag            |-> [i \in 1 .. 1 |-> 0],
      quoteCancelEntriesGroups |-> ZeroQuoteCancelEntriesGroups,
      quoteCancelSetsGroups    |-> ZeroQuoteCancelSetsGroups ]

(* Quote Cancel at zero, then each field in turn at the values it is checked at *)
CheckedQuoteCancel ==
    { ZeroQuoteCancel }
        \cup { [ZeroQuoteCancel EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancel EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroQuoteCancel EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancel EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancel EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroQuoteCancel EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroQuoteCancel EXCEPT !.quoteId = one] : one \in Sample(4) }
        \cup { [ZeroQuoteCancel EXCEPT !.quoteCancelType = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancel EXCEPT !.liquidityFlag = one] : one \in Sample(1) }
        \cup { [ZeroQuoteCancel EXCEPT !.quoteCancelEntriesGroups = one] : one \in CheckedQuoteCancelEntriesGroups }
        \cup { [ZeroQuoteCancel EXCEPT !.quoteCancelSetsGroups = one] : one \in CheckedQuoteCancelSetsGroups }

(***************************************************************************)
(* Order Mass Action Request: 71 bytes                                     *)
(***************************************************************************)

OrderMassActionRequest ==
    [ partyDetailsListReqId : Sample(8),
      orderRequestId        : Sample(8),
      manualOrderIndicator  : Sample(1),
      seqNum                : Sample(4),
      senderId              : Sample(20),
      sendingTimeEpoch      : Sample(8),
      securityGroup         : Sample(6),
      location              : Sample(5),
      securityIdOptional    : Sample(4),
      massActionScope       : Sample(1),
      marketSegmentId       : Sample(1),
      massCancelRequestType : Sample(1),
      sideOptional          : Sample(1),
      massActionOrdTyp      : Sample(1),
      massCancelTif         : Sample(1),
      liquidityFlag         : Sample(1) ]

EncodeOrderMassActionRequest(message) ==
    message.partyDetailsListReqId
        \o message.orderRequestId
        \o message.manualOrderIndicator
        \o message.seqNum
        \o message.senderId
        \o message.sendingTimeEpoch
        \o message.securityGroup
        \o message.location
        \o message.securityIdOptional
        \o message.massActionScope
        \o message.marketSegmentId
        \o message.massCancelRequestType
        \o message.sideOptional
        \o message.massActionOrdTyp
        \o message.massCancelTif
        \o message.liquidityFlag

DecodeOrderMassActionRequest(bytes) ==
    LET partyDetailsListReqId == ReadBytes(bytes, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(orderRequestId.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET seqNum == ReadBytes(manualOrderIndicator.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET senderId == ReadBytes(seqNum.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(senderId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(sendingTimeEpoch.rest, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    LET location == ReadBytes(securityGroup.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityIdOptional == ReadBytes(location.rest, 4) IN IF ~securityIdOptional.ok THEN Fail ELSE
    LET massActionScope == ReadBytes(securityIdOptional.rest, 1) IN IF ~massActionScope.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(massActionScope.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    LET massCancelRequestType == ReadBytes(marketSegmentId.rest, 1) IN IF ~massCancelRequestType.ok THEN Fail ELSE
    LET sideOptional == ReadBytes(massCancelRequestType.rest, 1) IN IF ~sideOptional.ok THEN Fail ELSE
    LET massActionOrdTyp == ReadBytes(sideOptional.rest, 1) IN IF ~massActionOrdTyp.ok THEN Fail ELSE
    LET massCancelTif == ReadBytes(massActionOrdTyp.rest, 1) IN IF ~massCancelTif.ok THEN Fail ELSE
    LET liquidityFlag == ReadBytes(massCancelTif.rest, 1) IN IF ~liquidityFlag.ok THEN Fail ELSE
    Ok([ partyDetailsListReqId |-> partyDetailsListReqId.value,
         orderRequestId        |-> orderRequestId.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         seqNum                |-> seqNum.value,
         senderId              |-> senderId.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         securityGroup         |-> securityGroup.value,
         location              |-> location.value,
         securityIdOptional    |-> securityIdOptional.value,
         massActionScope       |-> massActionScope.value,
         marketSegmentId       |-> marketSegmentId.value,
         massCancelRequestType |-> massCancelRequestType.value,
         sideOptional          |-> sideOptional.value,
         massActionOrdTyp      |-> massActionOrdTyp.value,
         massCancelTif         |-> massCancelTif.value,
         liquidityFlag         |-> liquidityFlag.value ], liquidityFlag.rest)

ZeroOrderMassActionRequest ==
    [ partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      orderRequestId        |-> [i \in 1 .. 8 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      seqNum                |-> [i \in 1 .. 4 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      securityGroup         |-> [i \in 1 .. 6 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      securityIdOptional    |-> [i \in 1 .. 4 |-> 0],
      massActionScope       |-> [i \in 1 .. 1 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 1 |-> 0],
      massCancelRequestType |-> [i \in 1 .. 1 |-> 0],
      sideOptional          |-> [i \in 1 .. 1 |-> 0],
      massActionOrdTyp      |-> [i \in 1 .. 1 |-> 0],
      massCancelTif         |-> [i \in 1 .. 1 |-> 0],
      liquidityFlag         |-> [i \in 1 .. 1 |-> 0] ]

(* Order Mass Action Request at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassActionRequest ==
    { ZeroOrderMassActionRequest }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.securityGroup = one] : one \in Sample(6) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.securityIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.massActionScope = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.marketSegmentId = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.massCancelRequestType = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.sideOptional = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.massActionOrdTyp = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.massCancelTif = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassActionRequest EXCEPT !.liquidityFlag = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Mass Status Request: 68 bytes                                     *)
(***************************************************************************)

OrderMassStatusRequest ==
    [ partyDetailsListReqId : Sample(8),
      massStatusReqId       : Sample(8),
      manualOrderIndicator  : Sample(1),
      seqNum                : Sample(4),
      senderId              : Sample(20),
      sendingTimeEpoch      : Sample(8),
      securityGroup         : Sample(6),
      location              : Sample(5),
      securityIdOptional    : Sample(4),
      massStatusReqType     : Sample(1),
      ordStatusReqType      : Sample(1),
      massStatusTif         : Sample(1),
      marketSegmentId       : Sample(1) ]

EncodeOrderMassStatusRequest(message) ==
    message.partyDetailsListReqId
        \o message.massStatusReqId
        \o message.manualOrderIndicator
        \o message.seqNum
        \o message.senderId
        \o message.sendingTimeEpoch
        \o message.securityGroup
        \o message.location
        \o message.securityIdOptional
        \o message.massStatusReqType
        \o message.ordStatusReqType
        \o message.massStatusTif
        \o message.marketSegmentId

DecodeOrderMassStatusRequest(bytes) ==
    LET partyDetailsListReqId == ReadBytes(bytes, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET massStatusReqId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~massStatusReqId.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(massStatusReqId.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET seqNum == ReadBytes(manualOrderIndicator.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET senderId == ReadBytes(seqNum.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(senderId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET securityGroup == ReadBytes(sendingTimeEpoch.rest, 6) IN IF ~securityGroup.ok THEN Fail ELSE
    LET location == ReadBytes(securityGroup.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityIdOptional == ReadBytes(location.rest, 4) IN IF ~securityIdOptional.ok THEN Fail ELSE
    LET massStatusReqType == ReadBytes(securityIdOptional.rest, 1) IN IF ~massStatusReqType.ok THEN Fail ELSE
    LET ordStatusReqType == ReadBytes(massStatusReqType.rest, 1) IN IF ~ordStatusReqType.ok THEN Fail ELSE
    LET massStatusTif == ReadBytes(ordStatusReqType.rest, 1) IN IF ~massStatusTif.ok THEN Fail ELSE
    LET marketSegmentId == ReadBytes(massStatusTif.rest, 1) IN IF ~marketSegmentId.ok THEN Fail ELSE
    Ok([ partyDetailsListReqId |-> partyDetailsListReqId.value,
         massStatusReqId       |-> massStatusReqId.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         seqNum                |-> seqNum.value,
         senderId              |-> senderId.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         securityGroup         |-> securityGroup.value,
         location              |-> location.value,
         securityIdOptional    |-> securityIdOptional.value,
         massStatusReqType     |-> massStatusReqType.value,
         ordStatusReqType      |-> ordStatusReqType.value,
         massStatusTif         |-> massStatusTif.value,
         marketSegmentId       |-> marketSegmentId.value ], marketSegmentId.rest)

ZeroOrderMassStatusRequest ==
    [ partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      massStatusReqId       |-> [i \in 1 .. 8 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      seqNum                |-> [i \in 1 .. 4 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      securityGroup         |-> [i \in 1 .. 6 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      securityIdOptional    |-> [i \in 1 .. 4 |-> 0],
      massStatusReqType     |-> [i \in 1 .. 1 |-> 0],
      ordStatusReqType      |-> [i \in 1 .. 1 |-> 0],
      massStatusTif         |-> [i \in 1 .. 1 |-> 0],
      marketSegmentId       |-> [i \in 1 .. 1 |-> 0] ]

(* Order Mass Status Request at zero, then each field in turn at the values it is checked at *)
CheckedOrderMassStatusRequest ==
    { ZeroOrderMassStatusRequest }
        \cup { [ZeroOrderMassStatusRequest EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassStatusRequest EXCEPT !.massStatusReqId = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassStatusRequest EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassStatusRequest EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassStatusRequest EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderMassStatusRequest EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroOrderMassStatusRequest EXCEPT !.securityGroup = one] : one \in Sample(6) }
        \cup { [ZeroOrderMassStatusRequest EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroOrderMassStatusRequest EXCEPT !.securityIdOptional = one] : one \in Sample(4) }
        \cup { [ZeroOrderMassStatusRequest EXCEPT !.massStatusReqType = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassStatusRequest EXCEPT !.ordStatusReqType = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassStatusRequest EXCEPT !.massStatusTif = one] : one \in Sample(1) }
        \cup { [ZeroOrderMassStatusRequest EXCEPT !.marketSegmentId = one] : one \in Sample(1) }

(***************************************************************************)
(* Order Status Request: 62 bytes                                          *)
(***************************************************************************)

OrderStatusRequest ==
    [ partyDetailsListReqId : Sample(8),
      ordStatusReqId        : Sample(8),
      manualOrderIndicator  : Sample(1),
      seqNum                : Sample(4),
      senderId              : Sample(20),
      orderId               : Sample(8),
      sendingTimeEpoch      : Sample(8),
      location              : Sample(5) ]

EncodeOrderStatusRequest(message) ==
    message.partyDetailsListReqId
        \o message.ordStatusReqId
        \o message.manualOrderIndicator
        \o message.seqNum
        \o message.senderId
        \o message.orderId
        \o message.sendingTimeEpoch
        \o message.location

DecodeOrderStatusRequest(bytes) ==
    LET partyDetailsListReqId == ReadBytes(bytes, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET ordStatusReqId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~ordStatusReqId.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(ordStatusReqId.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET seqNum == ReadBytes(manualOrderIndicator.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET senderId == ReadBytes(seqNum.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET orderId == ReadBytes(senderId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(orderId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET location == ReadBytes(sendingTimeEpoch.rest, 5) IN IF ~location.ok THEN Fail ELSE
    Ok([ partyDetailsListReqId |-> partyDetailsListReqId.value,
         ordStatusReqId        |-> ordStatusReqId.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         seqNum                |-> seqNum.value,
         senderId              |-> senderId.value,
         orderId               |-> orderId.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         location              |-> location.value ], location.rest)

ZeroOrderStatusRequest ==
    [ partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      ordStatusReqId        |-> [i \in 1 .. 8 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      seqNum                |-> [i \in 1 .. 4 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0] ]

(* Order Status Request at zero, then each field in turn at the values it is checked at *)
CheckedOrderStatusRequest ==
    { ZeroOrderStatusRequest }
        \cup { [ZeroOrderStatusRequest EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusRequest EXCEPT !.ordStatusReqId = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusRequest EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroOrderStatusRequest EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroOrderStatusRequest EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroOrderStatusRequest EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusRequest EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroOrderStatusRequest EXCEPT !.location = one] : one \in Sample(5) }

(***************************************************************************)
(* Requesting Party Ids Group: 7 bytes                                     *)
(***************************************************************************)

RequestingPartyIdsGroup ==
    [ requestingPartyId       : Sample(5),
      requestingPartyIdSource : Sample(1),
      requestingPartyRole     : Sample(1) ]

EncodeRequestingPartyIdsGroup(message) ==
    message.requestingPartyId
        \o message.requestingPartyIdSource
        \o message.requestingPartyRole

DecodeRequestingPartyIdsGroup(bytes) ==
    LET requestingPartyId == ReadBytes(bytes, 5) IN IF ~requestingPartyId.ok THEN Fail ELSE
    LET requestingPartyIdSource == ReadBytes(requestingPartyId.rest, 1) IN IF ~requestingPartyIdSource.ok THEN Fail ELSE
    LET requestingPartyRole == ReadBytes(requestingPartyIdSource.rest, 1) IN IF ~requestingPartyRole.ok THEN Fail ELSE
    Ok([ requestingPartyId       |-> requestingPartyId.value,
         requestingPartyIdSource |-> requestingPartyIdSource.value,
         requestingPartyRole     |-> requestingPartyRole.value ], requestingPartyRole.rest)

ZeroRequestingPartyIdsGroup ==
    [ requestingPartyId       |-> [i \in 1 .. 5 |-> 0],
      requestingPartyIdSource |-> [i \in 1 .. 1 |-> 0],
      requestingPartyRole     |-> [i \in 1 .. 1 |-> 0] ]

(* Requesting Party Ids Group at zero, then each field in turn at the values it is checked at *)
CheckedRequestingPartyIdsGroup ==
    { ZeroRequestingPartyIdsGroup }
        \cup { [ZeroRequestingPartyIdsGroup EXCEPT !.requestingPartyId = one] : one \in Sample(5) }
        \cup { [ZeroRequestingPartyIdsGroup EXCEPT !.requestingPartyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroRequestingPartyIdsGroup EXCEPT !.requestingPartyRole = one] : one \in Sample(1) }

(* A run of Requesting Party Ids Group, written one after another *)
RECURSIVE EncodeRequestingPartyIdsGroupList(_)
EncodeRequestingPartyIdsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRequestingPartyIdsGroup(Head(messages)) \o EncodeRequestingPartyIdsGroupList(Tail(messages))

(* As many Requesting Party Ids Group as the field that counts them says *)
RECURSIVE ReadRequestingPartyIdsGroupList(_, _)
ReadRequestingPartyIdsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRequestingPartyIdsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRequestingPartyIdsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Requesting Party Ids Group of each kind, for the lists that carry them *)
OneRequestingPartyIdsGroup == { ZeroRequestingPartyIdsGroup }

(***************************************************************************)
(* Requesting Party Ids Groups                                             *)
(***************************************************************************)

RequestingPartyIdsGroups ==
    [ blockLength             : Sample(2),
      requestingPartyIdsGroup : SampleLists(OneRequestingPartyIdsGroup) ]

EncodeRequestingPartyIdsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.requestingPartyIdsGroup), 1)
        \o EncodeRequestingPartyIdsGroupList(message.requestingPartyIdsGroup)

DecodeRequestingPartyIdsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET requestingPartyIdsGroup == ReadRequestingPartyIdsGroupList(numInGroup.rest, numInGroup.value) IN IF ~requestingPartyIdsGroup.ok THEN Fail ELSE
    Ok([ blockLength             |-> blockLength.value,
         requestingPartyIdsGroup |-> requestingPartyIdsGroup.value ], requestingPartyIdsGroup.rest)

ZeroRequestingPartyIdsGroups ==
    [ blockLength             |-> [i \in 1 .. 2 |-> 0],
      requestingPartyIdsGroup |-> << >> ]

(* Requesting Party Ids Groups at zero, then each field in turn at the values it is checked at *)
CheckedRequestingPartyIdsGroups ==
    { ZeroRequestingPartyIdsGroups }
        \cup { [ZeroRequestingPartyIdsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroRequestingPartyIdsGroups EXCEPT !.requestingPartyIdsGroup = one] : one \in SampleLists(OneRequestingPartyIdsGroup) }

(***************************************************************************)
(* Party Ids Group: 11 bytes                                               *)
(***************************************************************************)

PartyIdsGroup ==
    [ partyId       : Sample(8),
      partyIdSource : Sample(1),
      partyRole     : Sample(2) ]

EncodePartyIdsGroup(message) ==
    message.partyId
        \o message.partyIdSource
        \o message.partyRole

DecodePartyIdsGroup(bytes) ==
    LET partyId == ReadBytes(bytes, 8) IN IF ~partyId.ok THEN Fail ELSE
    LET partyIdSource == ReadBytes(partyId.rest, 1) IN IF ~partyIdSource.ok THEN Fail ELSE
    LET partyRole == ReadBytes(partyIdSource.rest, 2) IN IF ~partyRole.ok THEN Fail ELSE
    Ok([ partyId       |-> partyId.value,
         partyIdSource |-> partyIdSource.value,
         partyRole     |-> partyRole.value ], partyRole.rest)

ZeroPartyIdsGroup ==
    [ partyId       |-> [i \in 1 .. 8 |-> 0],
      partyIdSource |-> [i \in 1 .. 1 |-> 0],
      partyRole     |-> [i \in 1 .. 2 |-> 0] ]

(* Party Ids Group at zero, then each field in turn at the values it is checked at *)
CheckedPartyIdsGroup ==
    { ZeroPartyIdsGroup }
        \cup { [ZeroPartyIdsGroup EXCEPT !.partyId = one] : one \in Sample(8) }
        \cup { [ZeroPartyIdsGroup EXCEPT !.partyIdSource = one] : one \in Sample(1) }
        \cup { [ZeroPartyIdsGroup EXCEPT !.partyRole = one] : one \in Sample(2) }

(* A run of Party Ids Group, written one after another *)
RECURSIVE EncodePartyIdsGroupList(_)
EncodePartyIdsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodePartyIdsGroup(Head(messages)) \o EncodePartyIdsGroupList(Tail(messages))

(* As many Party Ids Group as the field that counts them says *)
RECURSIVE ReadPartyIdsGroupList(_, _)
ReadPartyIdsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodePartyIdsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadPartyIdsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Party Ids Group of each kind, for the lists that carry them *)
OnePartyIdsGroup == { ZeroPartyIdsGroup }

(***************************************************************************)
(* Party Ids Groups                                                        *)
(***************************************************************************)

PartyIdsGroups ==
    [ blockLength   : Sample(2),
      partyIdsGroup : SampleLists(OnePartyIdsGroup) ]

EncodePartyIdsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.partyIdsGroup), 1)
        \o EncodePartyIdsGroupList(message.partyIdsGroup)

DecodePartyIdsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET partyIdsGroup == ReadPartyIdsGroupList(numInGroup.rest, numInGroup.value) IN IF ~partyIdsGroup.ok THEN Fail ELSE
    Ok([ blockLength   |-> blockLength.value,
         partyIdsGroup |-> partyIdsGroup.value ], partyIdsGroup.rest)

ZeroPartyIdsGroups ==
    [ blockLength   |-> [i \in 1 .. 2 |-> 0],
      partyIdsGroup |-> << >> ]

(* Party Ids Groups at zero, then each field in turn at the values it is checked at *)
CheckedPartyIdsGroups ==
    { ZeroPartyIdsGroups }
        \cup { [ZeroPartyIdsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroPartyIdsGroups EXCEPT !.partyIdsGroup = one] : one \in SampleLists(OnePartyIdsGroup) }

(***************************************************************************)
(* Party Details List Request                                              *)
(***************************************************************************)

PartyDetailsListRequest ==
    [ partyDetailsListReqId    : Sample(8),
      sendingTimeEpoch         : Sample(8),
      seqNum                   : Sample(4),
      requestingPartyIdsGroups : RequestingPartyIdsGroups,
      partyIdsGroups           : PartyIdsGroups ]

EncodePartyDetailsListRequest(message) ==
    message.partyDetailsListReqId
        \o message.sendingTimeEpoch
        \o message.seqNum
        \o EncodeRequestingPartyIdsGroups(message.requestingPartyIdsGroups)
        \o EncodePartyIdsGroups(message.partyIdsGroups)

DecodePartyDetailsListRequest(bytes) ==
    LET partyDetailsListReqId == ReadBytes(bytes, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET seqNum == ReadBytes(sendingTimeEpoch.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET requestingPartyIdsGroups == DecodeRequestingPartyIdsGroups(seqNum.rest) IN IF ~requestingPartyIdsGroups.ok THEN Fail ELSE
    LET partyIdsGroups == DecodePartyIdsGroups(requestingPartyIdsGroups.rest) IN IF ~partyIdsGroups.ok THEN Fail ELSE
    Ok([ partyDetailsListReqId    |-> partyDetailsListReqId.value,
         sendingTimeEpoch         |-> sendingTimeEpoch.value,
         seqNum                   |-> seqNum.value,
         requestingPartyIdsGroups |-> requestingPartyIdsGroups.value,
         partyIdsGroups           |-> partyIdsGroups.value ], partyIdsGroups.rest)

ZeroPartyDetailsListRequest ==
    [ partyDetailsListReqId    |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch         |-> [i \in 1 .. 8 |-> 0],
      seqNum                   |-> [i \in 1 .. 4 |-> 0],
      requestingPartyIdsGroups |-> ZeroRequestingPartyIdsGroups,
      partyIdsGroups           |-> ZeroPartyIdsGroups ]

(* Party Details List Request at zero, then each field in turn at the values it is checked at *)
CheckedPartyDetailsListRequest ==
    { ZeroPartyDetailsListRequest }
        \cup { [ZeroPartyDetailsListRequest EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsListRequest EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroPartyDetailsListRequest EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroPartyDetailsListRequest EXCEPT !.requestingPartyIdsGroups = one] : one \in CheckedRequestingPartyIdsGroups }
        \cup { [ZeroPartyDetailsListRequest EXCEPT !.partyIdsGroups = one] : one \in CheckedPartyIdsGroups }

(***************************************************************************)
(* Execution Ack: 101 bytes                                                *)
(***************************************************************************)

ExecutionAck ==
    [ partyDetailsListReqId : Sample(8),
      orderId               : Sample(8),
      execAckStatus         : Sample(1),
      seqNum                : Sample(4),
      clordid               : Sample(20),
      secExecId             : Sample(8),
      lastPx                : Sample(8),
      securityId            : Sample(4),
      lastQty               : Sample(4),
      dkReason              : Sample(1),
      side                  : Sample(1),
      senderId              : Sample(20),
      sendingTimeEpoch      : Sample(8),
      location              : Sample(5),
      manualOrderIndicator  : Sample(1) ]

EncodeExecutionAck(message) ==
    message.partyDetailsListReqId
        \o message.orderId
        \o message.execAckStatus
        \o message.seqNum
        \o message.clordid
        \o message.secExecId
        \o message.lastPx
        \o message.securityId
        \o message.lastQty
        \o message.dkReason
        \o message.side
        \o message.senderId
        \o message.sendingTimeEpoch
        \o message.location
        \o message.manualOrderIndicator

DecodeExecutionAck(bytes) ==
    LET partyDetailsListReqId == ReadBytes(bytes, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~orderId.ok THEN Fail ELSE
    LET execAckStatus == ReadBytes(orderId.rest, 1) IN IF ~execAckStatus.ok THEN Fail ELSE
    LET seqNum == ReadBytes(execAckStatus.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET clordid == ReadBytes(seqNum.rest, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET secExecId == ReadBytes(clordid.rest, 8) IN IF ~secExecId.ok THEN Fail ELSE
    LET lastPx == ReadBytes(secExecId.rest, 8) IN IF ~lastPx.ok THEN Fail ELSE
    LET securityId == ReadBytes(lastPx.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET lastQty == ReadBytes(securityId.rest, 4) IN IF ~lastQty.ok THEN Fail ELSE
    LET dkReason == ReadBytes(lastQty.rest, 1) IN IF ~dkReason.ok THEN Fail ELSE
    LET side == ReadBytes(dkReason.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET senderId == ReadBytes(side.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(senderId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET location == ReadBytes(sendingTimeEpoch.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(location.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    Ok([ partyDetailsListReqId |-> partyDetailsListReqId.value,
         orderId               |-> orderId.value,
         execAckStatus         |-> execAckStatus.value,
         seqNum                |-> seqNum.value,
         clordid               |-> clordid.value,
         secExecId             |-> secExecId.value,
         lastPx                |-> lastPx.value,
         securityId            |-> securityId.value,
         lastQty               |-> lastQty.value,
         dkReason              |-> dkReason.value,
         side                  |-> side.value,
         senderId              |-> senderId.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         location              |-> location.value,
         manualOrderIndicator  |-> manualOrderIndicator.value ], manualOrderIndicator.rest)

ZeroExecutionAck ==
    [ partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      orderId               |-> [i \in 1 .. 8 |-> 0],
      execAckStatus         |-> [i \in 1 .. 1 |-> 0],
      seqNum                |-> [i \in 1 .. 4 |-> 0],
      clordid               |-> [i \in 1 .. 20 |-> 0],
      secExecId             |-> [i \in 1 .. 8 |-> 0],
      lastPx                |-> [i \in 1 .. 8 |-> 0],
      securityId            |-> [i \in 1 .. 4 |-> 0],
      lastQty               |-> [i \in 1 .. 4 |-> 0],
      dkReason              |-> [i \in 1 .. 1 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0] ]

(* Execution Ack at zero, then each field in turn at the values it is checked at *)
CheckedExecutionAck ==
    { ZeroExecutionAck }
        \cup { [ZeroExecutionAck EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionAck EXCEPT !.orderId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionAck EXCEPT !.execAckStatus = one] : one \in Sample(1) }
        \cup { [ZeroExecutionAck EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroExecutionAck EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroExecutionAck EXCEPT !.secExecId = one] : one \in Sample(8) }
        \cup { [ZeroExecutionAck EXCEPT !.lastPx = one] : one \in Sample(8) }
        \cup { [ZeroExecutionAck EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroExecutionAck EXCEPT !.lastQty = one] : one \in Sample(4) }
        \cup { [ZeroExecutionAck EXCEPT !.dkReason = one] : one \in Sample(1) }
        \cup { [ZeroExecutionAck EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroExecutionAck EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroExecutionAck EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroExecutionAck EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroExecutionAck EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }

(***************************************************************************)
(* Related Sym Group: 9 bytes                                              *)
(***************************************************************************)

RelatedSymGroup ==
    [ securityId       : Sample(4),
      orderQtyOptional : Sample(4),
      rfqSide          : Sample(1) ]

EncodeRelatedSymGroup(message) ==
    message.securityId
        \o message.orderQtyOptional
        \o message.rfqSide

DecodeRelatedSymGroup(bytes) ==
    LET securityId == ReadBytes(bytes, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET orderQtyOptional == ReadBytes(securityId.rest, 4) IN IF ~orderQtyOptional.ok THEN Fail ELSE
    LET rfqSide == ReadBytes(orderQtyOptional.rest, 1) IN IF ~rfqSide.ok THEN Fail ELSE
    Ok([ securityId       |-> securityId.value,
         orderQtyOptional |-> orderQtyOptional.value,
         rfqSide          |-> rfqSide.value ], rfqSide.rest)

ZeroRelatedSymGroup ==
    [ securityId       |-> [i \in 1 .. 4 |-> 0],
      orderQtyOptional |-> [i \in 1 .. 4 |-> 0],
      rfqSide          |-> [i \in 1 .. 1 |-> 0] ]

(* Related Sym Group at zero, then each field in turn at the values it is checked at *)
CheckedRelatedSymGroup ==
    { ZeroRelatedSymGroup }
        \cup { [ZeroRelatedSymGroup EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroRelatedSymGroup EXCEPT !.orderQtyOptional = one] : one \in Sample(4) }
        \cup { [ZeroRelatedSymGroup EXCEPT !.rfqSide = one] : one \in Sample(1) }

(* A run of Related Sym Group, written one after another *)
RECURSIVE EncodeRelatedSymGroupList(_)
EncodeRelatedSymGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRelatedSymGroup(Head(messages)) \o EncodeRelatedSymGroupList(Tail(messages))

(* As many Related Sym Group as the field that counts them says *)
RECURSIVE ReadRelatedSymGroupList(_, _)
ReadRelatedSymGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRelatedSymGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRelatedSymGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Related Sym Group of each kind, for the lists that carry them *)
OneRelatedSymGroup == { ZeroRelatedSymGroup }

(***************************************************************************)
(* Related Sym Groups                                                      *)
(***************************************************************************)

RelatedSymGroups ==
    [ blockLength     : Sample(2),
      relatedSymGroup : SampleLists(OneRelatedSymGroup) ]

EncodeRelatedSymGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.relatedSymGroup), 1)
        \o EncodeRelatedSymGroupList(message.relatedSymGroup)

DecodeRelatedSymGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET relatedSymGroup == ReadRelatedSymGroupList(numInGroup.rest, numInGroup.value) IN IF ~relatedSymGroup.ok THEN Fail ELSE
    Ok([ blockLength     |-> blockLength.value,
         relatedSymGroup |-> relatedSymGroup.value ], relatedSymGroup.rest)

ZeroRelatedSymGroups ==
    [ blockLength     |-> [i \in 1 .. 2 |-> 0],
      relatedSymGroup |-> << >> ]

(* Related Sym Groups at zero, then each field in turn at the values it is checked at *)
CheckedRelatedSymGroups ==
    { ZeroRelatedSymGroups }
        \cup { [ZeroRelatedSymGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroRelatedSymGroups EXCEPT !.relatedSymGroup = one] : one \in SampleLists(OneRelatedSymGroup) }

(***************************************************************************)
(* Request For Quote                                                       *)
(***************************************************************************)

RequestForQuote ==
    [ partyDetailsListReqId : Sample(8),
      quoteReqId            : Sample(8),
      manualOrderIndicator  : Sample(1),
      seqNum                : Sample(4),
      senderId              : Sample(20),
      sendingTimeEpoch      : Sample(8),
      location              : Sample(5),
      quoteType             : Sample(1),
      relatedSymGroups      : RelatedSymGroups ]

EncodeRequestForQuote(message) ==
    message.partyDetailsListReqId
        \o message.quoteReqId
        \o message.manualOrderIndicator
        \o message.seqNum
        \o message.senderId
        \o message.sendingTimeEpoch
        \o message.location
        \o message.quoteType
        \o EncodeRelatedSymGroups(message.relatedSymGroups)

DecodeRequestForQuote(bytes) ==
    LET partyDetailsListReqId == ReadBytes(bytes, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET quoteReqId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~quoteReqId.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(quoteReqId.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET seqNum == ReadBytes(manualOrderIndicator.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET senderId == ReadBytes(seqNum.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(senderId.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET location == ReadBytes(sendingTimeEpoch.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET quoteType == ReadBytes(location.rest, 1) IN IF ~quoteType.ok THEN Fail ELSE
    LET relatedSymGroups == DecodeRelatedSymGroups(quoteType.rest) IN IF ~relatedSymGroups.ok THEN Fail ELSE
    Ok([ partyDetailsListReqId |-> partyDetailsListReqId.value,
         quoteReqId            |-> quoteReqId.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         seqNum                |-> seqNum.value,
         senderId              |-> senderId.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         location              |-> location.value,
         quoteType             |-> quoteType.value,
         relatedSymGroups      |-> relatedSymGroups.value ], relatedSymGroups.rest)

ZeroRequestForQuote ==
    [ partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      quoteReqId            |-> [i \in 1 .. 8 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      seqNum                |-> [i \in 1 .. 4 |-> 0],
      senderId              |-> [i \in 1 .. 20 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      quoteType             |-> [i \in 1 .. 1 |-> 0],
      relatedSymGroups      |-> ZeroRelatedSymGroups ]

(* Request For Quote at zero, then each field in turn at the values it is checked at *)
CheckedRequestForQuote ==
    { ZeroRequestForQuote }
        \cup { [ZeroRequestForQuote EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroRequestForQuote EXCEPT !.quoteReqId = one] : one \in Sample(8) }
        \cup { [ZeroRequestForQuote EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroRequestForQuote EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroRequestForQuote EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroRequestForQuote EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroRequestForQuote EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroRequestForQuote EXCEPT !.quoteType = one] : one \in Sample(1) }
        \cup { [ZeroRequestForQuote EXCEPT !.relatedSymGroups = one] : one \in CheckedRelatedSymGroups }

(***************************************************************************)
(* Sides Group: 34 bytes                                                   *)
(***************************************************************************)

SidesGroup ==
    [ clordid               : Sample(20),
      partyDetailsListReqId : Sample(8),
      orderQty              : Sample(4),
      side                  : Sample(1),
      sideTimeInForce       : Sample(1) ]

EncodeSidesGroup(message) ==
    message.clordid
        \o message.partyDetailsListReqId
        \o message.orderQty
        \o message.side
        \o message.sideTimeInForce

DecodeSidesGroup(bytes) ==
    LET clordid == ReadBytes(bytes, 20) IN IF ~clordid.ok THEN Fail ELSE
    LET partyDetailsListReqId == ReadBytes(clordid.rest, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET orderQty == ReadBytes(partyDetailsListReqId.rest, 4) IN IF ~orderQty.ok THEN Fail ELSE
    LET side == ReadBytes(orderQty.rest, 1) IN IF ~side.ok THEN Fail ELSE
    LET sideTimeInForce == ReadBytes(side.rest, 1) IN IF ~sideTimeInForce.ok THEN Fail ELSE
    Ok([ clordid               |-> clordid.value,
         partyDetailsListReqId |-> partyDetailsListReqId.value,
         orderQty              |-> orderQty.value,
         side                  |-> side.value,
         sideTimeInForce       |-> sideTimeInForce.value ], sideTimeInForce.rest)

ZeroSidesGroup ==
    [ clordid               |-> [i \in 1 .. 20 |-> 0],
      partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      orderQty              |-> [i \in 1 .. 4 |-> 0],
      side                  |-> [i \in 1 .. 1 |-> 0],
      sideTimeInForce       |-> [i \in 1 .. 1 |-> 0] ]

(* Sides Group at zero, then each field in turn at the values it is checked at *)
CheckedSidesGroup ==
    { ZeroSidesGroup }
        \cup { [ZeroSidesGroup EXCEPT !.clordid = one] : one \in Sample(20) }
        \cup { [ZeroSidesGroup EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroSidesGroup EXCEPT !.orderQty = one] : one \in Sample(4) }
        \cup { [ZeroSidesGroup EXCEPT !.side = one] : one \in Sample(1) }
        \cup { [ZeroSidesGroup EXCEPT !.sideTimeInForce = one] : one \in Sample(1) }

(* A run of Sides Group, written one after another *)
RECURSIVE EncodeSidesGroupList(_)
EncodeSidesGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeSidesGroup(Head(messages)) \o EncodeSidesGroupList(Tail(messages))

(* As many Sides Group as the field that counts them says *)
RECURSIVE ReadSidesGroupList(_, _)
ReadSidesGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeSidesGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadSidesGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Sides Group of each kind, for the lists that carry them *)
OneSidesGroup == { ZeroSidesGroup }

(***************************************************************************)
(* Sides Groups                                                            *)
(***************************************************************************)

SidesGroups ==
    [ blockLength : Sample(2),
      sidesGroup  : SampleLists(OneSidesGroup) ]

EncodeSidesGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.sidesGroup), 1)
        \o EncodeSidesGroupList(message.sidesGroup)

DecodeSidesGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET sidesGroup == ReadSidesGroupList(numInGroup.rest, numInGroup.value) IN IF ~sidesGroup.ok THEN Fail ELSE
    Ok([ blockLength |-> blockLength.value,
         sidesGroup  |-> sidesGroup.value ], sidesGroup.rest)

ZeroSidesGroups ==
    [ blockLength |-> [i \in 1 .. 2 |-> 0],
      sidesGroup  |-> << >> ]

(* Sides Groups at zero, then each field in turn at the values it is checked at *)
CheckedSidesGroups ==
    { ZeroSidesGroups }
        \cup { [ZeroSidesGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroSidesGroups EXCEPT !.sidesGroup = one] : one \in SampleLists(OneSidesGroup) }

(***************************************************************************)
(* New Order Cross                                                         *)
(***************************************************************************)

NewOrderCross ==
    [ crossId              : Sample(8),
      orderRequestId       : Sample(8),
      manualOrderIndicator : Sample(1),
      seqNum               : Sample(4),
      senderId             : Sample(20),
      price                : Sample(8),
      transBkdTime         : Sample(8),
      sendingTimeEpoch     : Sample(8),
      location             : Sample(5),
      securityId           : Sample(4),
      sidesGroups          : SidesGroups ]

EncodeNewOrderCross(message) ==
    message.crossId
        \o message.orderRequestId
        \o message.manualOrderIndicator
        \o message.seqNum
        \o message.senderId
        \o message.price
        \o message.transBkdTime
        \o message.sendingTimeEpoch
        \o message.location
        \o message.securityId
        \o EncodeSidesGroups(message.sidesGroups)

DecodeNewOrderCross(bytes) ==
    LET crossId == ReadBytes(bytes, 8) IN IF ~crossId.ok THEN Fail ELSE
    LET orderRequestId == ReadBytes(crossId.rest, 8) IN IF ~orderRequestId.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(orderRequestId.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET seqNum == ReadBytes(manualOrderIndicator.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET senderId == ReadBytes(seqNum.rest, 20) IN IF ~senderId.ok THEN Fail ELSE
    LET price == ReadBytes(senderId.rest, 8) IN IF ~price.ok THEN Fail ELSE
    LET transBkdTime == ReadBytes(price.rest, 8) IN IF ~transBkdTime.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(transBkdTime.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET location == ReadBytes(sendingTimeEpoch.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET securityId == ReadBytes(location.rest, 4) IN IF ~securityId.ok THEN Fail ELSE
    LET sidesGroups == DecodeSidesGroups(securityId.rest) IN IF ~sidesGroups.ok THEN Fail ELSE
    Ok([ crossId              |-> crossId.value,
         orderRequestId       |-> orderRequestId.value,
         manualOrderIndicator |-> manualOrderIndicator.value,
         seqNum               |-> seqNum.value,
         senderId             |-> senderId.value,
         price                |-> price.value,
         transBkdTime         |-> transBkdTime.value,
         sendingTimeEpoch     |-> sendingTimeEpoch.value,
         location             |-> location.value,
         securityId           |-> securityId.value,
         sidesGroups          |-> sidesGroups.value ], sidesGroups.rest)

ZeroNewOrderCross ==
    [ crossId              |-> [i \in 1 .. 8 |-> 0],
      orderRequestId       |-> [i \in 1 .. 8 |-> 0],
      manualOrderIndicator |-> [i \in 1 .. 1 |-> 0],
      seqNum               |-> [i \in 1 .. 4 |-> 0],
      senderId             |-> [i \in 1 .. 20 |-> 0],
      price                |-> [i \in 1 .. 8 |-> 0],
      transBkdTime         |-> [i \in 1 .. 8 |-> 0],
      sendingTimeEpoch     |-> [i \in 1 .. 8 |-> 0],
      location             |-> [i \in 1 .. 5 |-> 0],
      securityId           |-> [i \in 1 .. 4 |-> 0],
      sidesGroups          |-> ZeroSidesGroups ]

(* New Order Cross at zero, then each field in turn at the values it is checked at *)
CheckedNewOrderCross ==
    { ZeroNewOrderCross }
        \cup { [ZeroNewOrderCross EXCEPT !.crossId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCross EXCEPT !.orderRequestId = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCross EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroNewOrderCross EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCross EXCEPT !.senderId = one] : one \in Sample(20) }
        \cup { [ZeroNewOrderCross EXCEPT !.price = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCross EXCEPT !.transBkdTime = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCross EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroNewOrderCross EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroNewOrderCross EXCEPT !.securityId = one] : one \in Sample(4) }
        \cup { [ZeroNewOrderCross EXCEPT !.sidesGroups = one] : one \in CheckedSidesGroups }

(***************************************************************************)
(* Leg Option Delta: 5 bytes                                               *)
(***************************************************************************)

LegOptionDelta ==
    [ mantissa32 : Sample(4),
      exponent   : Sample(1) ]

EncodeLegOptionDelta(message) ==
    message.mantissa32
        \o message.exponent

DecodeLegOptionDelta(bytes) ==
    LET mantissa32 == ReadBytes(bytes, 4) IN IF ~mantissa32.ok THEN Fail ELSE
    LET exponent == ReadBytes(mantissa32.rest, 1) IN IF ~exponent.ok THEN Fail ELSE
    Ok([ mantissa32 |-> mantissa32.value,
         exponent   |-> exponent.value ], exponent.rest)

ZeroLegOptionDelta ==
    [ mantissa32 |-> [i \in 1 .. 4 |-> 0],
      exponent   |-> [i \in 1 .. 1 |-> 0] ]

(* Leg Option Delta at zero, then each field in turn at the values it is checked at *)
CheckedLegOptionDelta ==
    { ZeroLegOptionDelta }
        \cup { [ZeroLegOptionDelta EXCEPT !.mantissa32 = one] : one \in Sample(4) }
        \cup { [ZeroLegOptionDelta EXCEPT !.exponent = one] : one \in Sample(1) }

(***************************************************************************)
(* Request Legs Group: 19 bytes                                            *)
(***************************************************************************)

RequestLegsGroup ==
    [ legPrice       : Sample(8),
      legSecurityId  : Sample(4),
      legOptionDelta : LegOptionDelta,
      legSide        : Sample(1),
      legRatioQty    : Sample(1) ]

EncodeRequestLegsGroup(message) ==
    message.legPrice
        \o message.legSecurityId
        \o EncodeLegOptionDelta(message.legOptionDelta)
        \o message.legSide
        \o message.legRatioQty

DecodeRequestLegsGroup(bytes) ==
    LET legPrice == ReadBytes(bytes, 8) IN IF ~legPrice.ok THEN Fail ELSE
    LET legSecurityId == ReadBytes(legPrice.rest, 4) IN IF ~legSecurityId.ok THEN Fail ELSE
    LET legOptionDelta == DecodeLegOptionDelta(legSecurityId.rest) IN IF ~legOptionDelta.ok THEN Fail ELSE
    LET legSide == ReadBytes(legOptionDelta.rest, 1) IN IF ~legSide.ok THEN Fail ELSE
    LET legRatioQty == ReadBytes(legSide.rest, 1) IN IF ~legRatioQty.ok THEN Fail ELSE
    Ok([ legPrice       |-> legPrice.value,
         legSecurityId  |-> legSecurityId.value,
         legOptionDelta |-> legOptionDelta.value,
         legSide        |-> legSide.value,
         legRatioQty    |-> legRatioQty.value ], legRatioQty.rest)

ZeroRequestLegsGroup ==
    [ legPrice       |-> [i \in 1 .. 8 |-> 0],
      legSecurityId  |-> [i \in 1 .. 4 |-> 0],
      legOptionDelta |-> ZeroLegOptionDelta,
      legSide        |-> [i \in 1 .. 1 |-> 0],
      legRatioQty    |-> [i \in 1 .. 1 |-> 0] ]

(* Request Legs Group at zero, then each field in turn at the values it is checked at *)
CheckedRequestLegsGroup ==
    { ZeroRequestLegsGroup }
        \cup { [ZeroRequestLegsGroup EXCEPT !.legPrice = one] : one \in Sample(8) }
        \cup { [ZeroRequestLegsGroup EXCEPT !.legSecurityId = one] : one \in Sample(4) }
        \cup { [ZeroRequestLegsGroup EXCEPT !.legOptionDelta = one] : one \in CheckedLegOptionDelta }
        \cup { [ZeroRequestLegsGroup EXCEPT !.legSide = one] : one \in Sample(1) }
        \cup { [ZeroRequestLegsGroup EXCEPT !.legRatioQty = one] : one \in Sample(1) }

(* A run of Request Legs Group, written one after another *)
RECURSIVE EncodeRequestLegsGroupList(_)
EncodeRequestLegsGroupList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeRequestLegsGroup(Head(messages)) \o EncodeRequestLegsGroupList(Tail(messages))

(* As many Request Legs Group as the field that counts them says *)
RECURSIVE ReadRequestLegsGroupList(_, _)
ReadRequestLegsGroupList(bytes, count) ==
    IF count = 0
    THEN Ok(<< >>, bytes)
    ELSE LET one == DecodeRequestLegsGroup(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadRequestLegsGroupList(one.rest, count - 1)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Request Legs Group of each kind, for the lists that carry them *)
OneRequestLegsGroup == { ZeroRequestLegsGroup }

(***************************************************************************)
(* Request Legs Groups                                                     *)
(***************************************************************************)

RequestLegsGroups ==
    [ blockLength      : Sample(2),
      requestLegsGroup : SampleLists(OneRequestLegsGroup) ]

EncodeRequestLegsGroups(message) ==
    message.blockLength
        \o EncodeUIntBE(Len(message.requestLegsGroup), 1)
        \o EncodeRequestLegsGroupList(message.requestLegsGroup)

DecodeRequestLegsGroups(bytes) ==
    LET blockLength == ReadBytes(bytes, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET numInGroup == ReadUIntBE(blockLength.rest, 1) IN IF ~numInGroup.ok THEN Fail ELSE
    LET requestLegsGroup == ReadRequestLegsGroupList(numInGroup.rest, numInGroup.value) IN IF ~requestLegsGroup.ok THEN Fail ELSE
    Ok([ blockLength      |-> blockLength.value,
         requestLegsGroup |-> requestLegsGroup.value ], requestLegsGroup.rest)

ZeroRequestLegsGroups ==
    [ blockLength      |-> [i \in 1 .. 2 |-> 0],
      requestLegsGroup |-> << >> ]

(* Request Legs Groups at zero, then each field in turn at the values it is checked at *)
CheckedRequestLegsGroups ==
    { ZeroRequestLegsGroups }
        \cup { [ZeroRequestLegsGroups EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroRequestLegsGroups EXCEPT !.requestLegsGroup = one] : one \in SampleLists(OneRequestLegsGroup) }

(***************************************************************************)
(* Security Definition Request                                             *)
(***************************************************************************)

SecurityDefinitionRequest ==
    [ partyDetailsListReqId : Sample(8),
      securityReqId         : Sample(8),
      manualOrderIndicator  : Sample(1),
      seqNum                : Sample(4),
      senderIdOptional      : Sample(20),
      sendingTimeEpoch      : Sample(8),
      securitySubType       : Sample(8),
      location              : Sample(5),
      startDate             : Sample(2),
      endDate               : Sample(2),
      maxNoOfSubstitutions  : Sample(1),
      sourceRepoId          : Sample(4),
      requestLegsGroups     : RequestLegsGroups ]

EncodeSecurityDefinitionRequest(message) ==
    message.partyDetailsListReqId
        \o message.securityReqId
        \o message.manualOrderIndicator
        \o message.seqNum
        \o message.senderIdOptional
        \o message.sendingTimeEpoch
        \o message.securitySubType
        \o message.location
        \o message.startDate
        \o message.endDate
        \o message.maxNoOfSubstitutions
        \o message.sourceRepoId
        \o EncodeRequestLegsGroups(message.requestLegsGroups)

DecodeSecurityDefinitionRequest(bytes) ==
    LET partyDetailsListReqId == ReadBytes(bytes, 8) IN IF ~partyDetailsListReqId.ok THEN Fail ELSE
    LET securityReqId == ReadBytes(partyDetailsListReqId.rest, 8) IN IF ~securityReqId.ok THEN Fail ELSE
    LET manualOrderIndicator == ReadBytes(securityReqId.rest, 1) IN IF ~manualOrderIndicator.ok THEN Fail ELSE
    LET seqNum == ReadBytes(manualOrderIndicator.rest, 4) IN IF ~seqNum.ok THEN Fail ELSE
    LET senderIdOptional == ReadBytes(seqNum.rest, 20) IN IF ~senderIdOptional.ok THEN Fail ELSE
    LET sendingTimeEpoch == ReadBytes(senderIdOptional.rest, 8) IN IF ~sendingTimeEpoch.ok THEN Fail ELSE
    LET securitySubType == ReadBytes(sendingTimeEpoch.rest, 8) IN IF ~securitySubType.ok THEN Fail ELSE
    LET location == ReadBytes(securitySubType.rest, 5) IN IF ~location.ok THEN Fail ELSE
    LET startDate == ReadBytes(location.rest, 2) IN IF ~startDate.ok THEN Fail ELSE
    LET endDate == ReadBytes(startDate.rest, 2) IN IF ~endDate.ok THEN Fail ELSE
    LET maxNoOfSubstitutions == ReadBytes(endDate.rest, 1) IN IF ~maxNoOfSubstitutions.ok THEN Fail ELSE
    LET sourceRepoId == ReadBytes(maxNoOfSubstitutions.rest, 4) IN IF ~sourceRepoId.ok THEN Fail ELSE
    LET requestLegsGroups == DecodeRequestLegsGroups(sourceRepoId.rest) IN IF ~requestLegsGroups.ok THEN Fail ELSE
    Ok([ partyDetailsListReqId |-> partyDetailsListReqId.value,
         securityReqId         |-> securityReqId.value,
         manualOrderIndicator  |-> manualOrderIndicator.value,
         seqNum                |-> seqNum.value,
         senderIdOptional      |-> senderIdOptional.value,
         sendingTimeEpoch      |-> sendingTimeEpoch.value,
         securitySubType       |-> securitySubType.value,
         location              |-> location.value,
         startDate             |-> startDate.value,
         endDate               |-> endDate.value,
         maxNoOfSubstitutions  |-> maxNoOfSubstitutions.value,
         sourceRepoId          |-> sourceRepoId.value,
         requestLegsGroups     |-> requestLegsGroups.value ], requestLegsGroups.rest)

ZeroSecurityDefinitionRequest ==
    [ partyDetailsListReqId |-> [i \in 1 .. 8 |-> 0],
      securityReqId         |-> [i \in 1 .. 8 |-> 0],
      manualOrderIndicator  |-> [i \in 1 .. 1 |-> 0],
      seqNum                |-> [i \in 1 .. 4 |-> 0],
      senderIdOptional      |-> [i \in 1 .. 20 |-> 0],
      sendingTimeEpoch      |-> [i \in 1 .. 8 |-> 0],
      securitySubType       |-> [i \in 1 .. 8 |-> 0],
      location              |-> [i \in 1 .. 5 |-> 0],
      startDate             |-> [i \in 1 .. 2 |-> 0],
      endDate               |-> [i \in 1 .. 2 |-> 0],
      maxNoOfSubstitutions  |-> [i \in 1 .. 1 |-> 0],
      sourceRepoId          |-> [i \in 1 .. 4 |-> 0],
      requestLegsGroups     |-> ZeroRequestLegsGroups ]

(* Security Definition Request at zero, then each field in turn at the values it is checked at *)
CheckedSecurityDefinitionRequest ==
    { ZeroSecurityDefinitionRequest }
        \cup { [ZeroSecurityDefinitionRequest EXCEPT !.partyDetailsListReqId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionRequest EXCEPT !.securityReqId = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionRequest EXCEPT !.manualOrderIndicator = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionRequest EXCEPT !.seqNum = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRequest EXCEPT !.senderIdOptional = one] : one \in Sample(20) }
        \cup { [ZeroSecurityDefinitionRequest EXCEPT !.sendingTimeEpoch = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionRequest EXCEPT !.securitySubType = one] : one \in Sample(8) }
        \cup { [ZeroSecurityDefinitionRequest EXCEPT !.location = one] : one \in Sample(5) }
        \cup { [ZeroSecurityDefinitionRequest EXCEPT !.startDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionRequest EXCEPT !.endDate = one] : one \in Sample(2) }
        \cup { [ZeroSecurityDefinitionRequest EXCEPT !.maxNoOfSubstitutions = one] : one \in Sample(1) }
        \cup { [ZeroSecurityDefinitionRequest EXCEPT !.sourceRepoId = one] : one \in Sample(4) }
        \cup { [ZeroSecurityDefinitionRequest EXCEPT !.requestLegsGroups = one] : one \in CheckedRequestLegsGroups }

(***************************************************************************)
(* Client Payload, selected by Template Id                                 *)
(***************************************************************************)

NegotiateCode == 500  \* 0x1f4
EstablishCode == 503  \* 0x1f7
SequenceCode == 506  \* 0x1fa
TerminateCode == 507  \* 0x1fb
RetransmitRequestCode == 508  \* 0x1fc
NewOrderSingleCode == 514  \* 0x202
OrderCancelReplaceRequestCode == 515  \* 0x203
OrderCancelRequestCode == 516  \* 0x204
MassQuoteCode == 517  \* 0x205
PartyDetailsDefinitionRequestCode == 518  \* 0x206
QuoteCancelCode == 528  \* 0x210
OrderMassActionRequestCode == 529  \* 0x211
OrderMassStatusRequestCode == 530  \* 0x212
OrderStatusRequestCode == 533  \* 0x215
PartyDetailsListRequestCode == 537  \* 0x219
ExecutionAckCode == 539  \* 0x21b
RequestForQuoteCode == 543  \* 0x21f
NewOrderCrossCode == 544  \* 0x220
SecurityDefinitionRequestCode == 560  \* 0x230

ClientPayload ==
    [ tag : {NegotiateCode}, body : Negotiate ]
        \cup [ tag : {EstablishCode}, body : Establish ]
        \cup [ tag : {SequenceCode}, body : Sequence ]
        \cup [ tag : {TerminateCode}, body : Terminate ]
        \cup [ tag : {RetransmitRequestCode}, body : RetransmitRequest ]
        \cup [ tag : {NewOrderSingleCode}, body : NewOrderSingle ]
        \cup [ tag : {OrderCancelReplaceRequestCode}, body : OrderCancelReplaceRequest ]
        \cup [ tag : {OrderCancelRequestCode}, body : OrderCancelRequest ]
        \cup [ tag : {MassQuoteCode}, body : MassQuote ]
        \cup [ tag : {PartyDetailsDefinitionRequestCode}, body : PartyDetailsDefinitionRequest ]
        \cup [ tag : {QuoteCancelCode}, body : QuoteCancel ]
        \cup [ tag : {OrderMassActionRequestCode}, body : OrderMassActionRequest ]
        \cup [ tag : {OrderMassStatusRequestCode}, body : OrderMassStatusRequest ]
        \cup [ tag : {OrderStatusRequestCode}, body : OrderStatusRequest ]
        \cup [ tag : {PartyDetailsListRequestCode}, body : PartyDetailsListRequest ]
        \cup [ tag : {ExecutionAckCode}, body : ExecutionAck ]
        \cup [ tag : {RequestForQuoteCode}, body : RequestForQuote ]
        \cup [ tag : {NewOrderCrossCode}, body : NewOrderCross ]
        \cup [ tag : {SecurityDefinitionRequestCode}, body : SecurityDefinitionRequest ]

EncodeClientPayload(message) ==
    CASE message.tag = NegotiateCode -> EncodeNegotiate(message.body)
      [] message.tag = EstablishCode -> EncodeEstablish(message.body)
      [] message.tag = SequenceCode -> EncodeSequence(message.body)
      [] message.tag = TerminateCode -> EncodeTerminate(message.body)
      [] message.tag = RetransmitRequestCode -> EncodeRetransmitRequest(message.body)
      [] message.tag = NewOrderSingleCode -> EncodeNewOrderSingle(message.body)
      [] message.tag = OrderCancelReplaceRequestCode -> EncodeOrderCancelReplaceRequest(message.body)
      [] message.tag = OrderCancelRequestCode -> EncodeOrderCancelRequest(message.body)
      [] message.tag = MassQuoteCode -> EncodeMassQuote(message.body)
      [] message.tag = PartyDetailsDefinitionRequestCode -> EncodePartyDetailsDefinitionRequest(message.body)
      [] message.tag = QuoteCancelCode -> EncodeQuoteCancel(message.body)
      [] message.tag = OrderMassActionRequestCode -> EncodeOrderMassActionRequest(message.body)
      [] message.tag = OrderMassStatusRequestCode -> EncodeOrderMassStatusRequest(message.body)
      [] message.tag = OrderStatusRequestCode -> EncodeOrderStatusRequest(message.body)
      [] message.tag = PartyDetailsListRequestCode -> EncodePartyDetailsListRequest(message.body)
      [] message.tag = ExecutionAckCode -> EncodeExecutionAck(message.body)
      [] message.tag = RequestForQuoteCode -> EncodeRequestForQuote(message.body)
      [] message.tag = NewOrderCrossCode -> EncodeNewOrderCross(message.body)
      [] message.tag = SecurityDefinitionRequestCode -> EncodeSecurityDefinitionRequest(message.body)

DecodeClientPayload(tag, bytes) ==
    LET read ==
            CASE tag = NegotiateCode -> DecodeNegotiate(bytes)
              [] tag = EstablishCode -> DecodeEstablish(bytes)
              [] tag = SequenceCode -> DecodeSequence(bytes)
              [] tag = TerminateCode -> DecodeTerminate(bytes)
              [] tag = RetransmitRequestCode -> DecodeRetransmitRequest(bytes)
              [] tag = NewOrderSingleCode -> DecodeNewOrderSingle(bytes)
              [] tag = OrderCancelReplaceRequestCode -> DecodeOrderCancelReplaceRequest(bytes)
              [] tag = OrderCancelRequestCode -> DecodeOrderCancelRequest(bytes)
              [] tag = MassQuoteCode -> DecodeMassQuote(bytes)
              [] tag = PartyDetailsDefinitionRequestCode -> DecodePartyDetailsDefinitionRequest(bytes)
              [] tag = QuoteCancelCode -> DecodeQuoteCancel(bytes)
              [] tag = OrderMassActionRequestCode -> DecodeOrderMassActionRequest(bytes)
              [] tag = OrderMassStatusRequestCode -> DecodeOrderMassStatusRequest(bytes)
              [] tag = OrderStatusRequestCode -> DecodeOrderStatusRequest(bytes)
              [] tag = PartyDetailsListRequestCode -> DecodePartyDetailsListRequest(bytes)
              [] tag = ExecutionAckCode -> DecodeExecutionAck(bytes)
              [] tag = RequestForQuoteCode -> DecodeRequestForQuote(bytes)
              [] tag = NewOrderCrossCode -> DecodeNewOrderCross(bytes)
              [] tag = SecurityDefinitionRequestCode -> DecodeSecurityDefinitionRequest(bytes)
              [] OTHER -> Fail
    IN  IF ~read.ok THEN Fail ELSE Ok([tag |-> tag, body |-> read.value], read.rest)

ZeroClientPayload == [tag |-> NegotiateCode, body |-> ZeroNegotiate]

(* Each Client Payload in turn, at the values the message it names is checked at *)
CheckedClientPayload ==
    { [tag |-> NegotiateCode, body |-> one] : one \in CheckedNegotiate }
        \cup { [tag |-> EstablishCode, body |-> one] : one \in CheckedEstablish }
        \cup { [tag |-> SequenceCode, body |-> one] : one \in CheckedSequence }
        \cup { [tag |-> TerminateCode, body |-> one] : one \in CheckedTerminate }
        \cup { [tag |-> RetransmitRequestCode, body |-> one] : one \in CheckedRetransmitRequest }
        \cup { [tag |-> NewOrderSingleCode, body |-> one] : one \in CheckedNewOrderSingle }
        \cup { [tag |-> OrderCancelReplaceRequestCode, body |-> one] : one \in CheckedOrderCancelReplaceRequest }
        \cup { [tag |-> OrderCancelRequestCode, body |-> one] : one \in CheckedOrderCancelRequest }
        \cup { [tag |-> MassQuoteCode, body |-> one] : one \in CheckedMassQuote }
        \cup { [tag |-> PartyDetailsDefinitionRequestCode, body |-> one] : one \in CheckedPartyDetailsDefinitionRequest }
        \cup { [tag |-> QuoteCancelCode, body |-> one] : one \in CheckedQuoteCancel }
        \cup { [tag |-> OrderMassActionRequestCode, body |-> one] : one \in CheckedOrderMassActionRequest }
        \cup { [tag |-> OrderMassStatusRequestCode, body |-> one] : one \in CheckedOrderMassStatusRequest }
        \cup { [tag |-> OrderStatusRequestCode, body |-> one] : one \in CheckedOrderStatusRequest }
        \cup { [tag |-> PartyDetailsListRequestCode, body |-> one] : one \in CheckedPartyDetailsListRequest }
        \cup { [tag |-> ExecutionAckCode, body |-> one] : one \in CheckedExecutionAck }
        \cup { [tag |-> RequestForQuoteCode, body |-> one] : one \in CheckedRequestForQuote }
        \cup { [tag |-> NewOrderCrossCode, body |-> one] : one \in CheckedNewOrderCross }
        \cup { [tag |-> SecurityDefinitionRequestCode, body |-> one] : one \in CheckedSecurityDefinitionRequest }

(***************************************************************************)
(* Client Simple Open Frame, framed by Message Length                      *)
(***************************************************************************)

ClientSimpleOpenFrame ==
    [ encodingType  : Sample(2),
      blockLength   : Sample(2),
      schemaId      : Sample(2),
      version       : Sample(2),
      clientPayload : ClientPayload ]

EncodeClientSimpleOpenFrameBody(message) ==
    message.encodingType
        \o message.blockLength
        \o EncodeUIntLE(message.clientPayload.tag, 2)
        \o message.schemaId
        \o message.version
        \o EncodeClientPayload(message.clientPayload)

(* Message Length counts the bytes it frames, so it is written from them *)
EncodeClientSimpleOpenFrame(message) ==
    LET body == EncodeClientSimpleOpenFrameBody(message)
    IN  EncodeUIntLE(Len(body) + 2, 2) \o body

DecodeClientSimpleOpenFrameBody(bytes) ==
    LET encodingType == ReadBytes(bytes, 2) IN IF ~encodingType.ok THEN Fail ELSE
    LET blockLength == ReadBytes(encodingType.rest, 2) IN IF ~blockLength.ok THEN Fail ELSE
    LET templateId == ReadUIntLE(blockLength.rest, 2) IN IF ~templateId.ok THEN Fail ELSE
    LET schemaId == ReadBytes(templateId.rest, 2) IN IF ~schemaId.ok THEN Fail ELSE
    LET version == ReadBytes(schemaId.rest, 2) IN IF ~version.ok THEN Fail ELSE
    LET clientPayload == DecodeClientPayload(templateId.value, version.rest) IN IF ~clientPayload.ok THEN Fail ELSE
    Ok([ encodingType  |-> encodingType.value,
         blockLength   |-> blockLength.value,
         schemaId      |-> schemaId.value,
         version       |-> version.value,
         clientPayload |-> clientPayload.value ], clientPayload.rest)

DecodeClientSimpleOpenFrame(bytes) ==
    LET length == ReadUIntLE(bytes, 2) IN IF ~length.ok THEN Fail ELSE
    LET size == length.value - 2 IN
    IF size < 0 \/ Len(length.rest) < size THEN Fail ELSE
    LET framed == SubSeq(length.rest, 1, size)
        beyond == SubSeq(length.rest, size + 1, Len(length.rest))
        body   == DecodeClientSimpleOpenFrameBody(framed)
    IN  IF ~body.ok \/ body.rest # << >> THEN Fail ELSE
    Ok(body.value, beyond)

ZeroClientSimpleOpenFrame ==
    [ encodingType  |-> [i \in 1 .. 2 |-> 0],
      blockLength   |-> [i \in 1 .. 2 |-> 0],
      schemaId      |-> [i \in 1 .. 2 |-> 0],
      version       |-> [i \in 1 .. 2 |-> 0],
      clientPayload |-> ZeroClientPayload ]

(* Client Simple Open Frame at zero, then each field in turn at the values it is checked at *)
CheckedClientSimpleOpenFrame ==
    { ZeroClientSimpleOpenFrame }
        \cup { [ZeroClientSimpleOpenFrame EXCEPT !.encodingType = one] : one \in Sample(2) }
        \cup { [ZeroClientSimpleOpenFrame EXCEPT !.blockLength = one] : one \in Sample(2) }
        \cup { [ZeroClientSimpleOpenFrame EXCEPT !.schemaId = one] : one \in Sample(2) }
        \cup { [ZeroClientSimpleOpenFrame EXCEPT !.version = one] : one \in Sample(2) }
        \cup { [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = one] : one \in CheckedClientPayload }

(* A run of Client Simple Open Frame, written one after another *)
RECURSIVE EncodeClientSimpleOpenFrameList(_)
EncodeClientSimpleOpenFrameList(messages) ==
    IF messages = << >>
    THEN << >>
    ELSE EncodeClientSimpleOpenFrame(Head(messages)) \o EncodeClientSimpleOpenFrameList(Tail(messages))

(* As many Client Simple Open Frame as the bytes hold, which is what its payload rule states. *)
(* Each one takes bytes off the reader, so the run ends where the data does. *)
RECURSIVE ReadClientSimpleOpenFrameAll(_)
ReadClientSimpleOpenFrameAll(bytes) ==
    IF bytes = << >>
    THEN Ok(<< >>, << >>)
    ELSE LET one == DecodeClientSimpleOpenFrame(bytes)
         IN  IF ~one.ok THEN Fail
             ELSE LET more == ReadClientSimpleOpenFrameAll(one.rest)
                  IN  IF ~more.ok THEN Fail
                      ELSE Ok(<<one.value>> \o more.value, more.rest)

(* One Client Simple Open Frame of each kind, for the lists that carry them *)
OneClientSimpleOpenFrame ==
    { [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> NegotiateCode, body |-> ZeroNegotiate]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> EstablishCode, body |-> ZeroEstablish]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> SequenceCode, body |-> ZeroSequence]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> TerminateCode, body |-> ZeroTerminate]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> RetransmitRequestCode, body |-> ZeroRetransmitRequest]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> NewOrderSingleCode, body |-> ZeroNewOrderSingle]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> OrderCancelReplaceRequestCode, body |-> ZeroOrderCancelReplaceRequest]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> OrderCancelRequestCode, body |-> ZeroOrderCancelRequest]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> MassQuoteCode, body |-> ZeroMassQuote]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> PartyDetailsDefinitionRequestCode, body |-> ZeroPartyDetailsDefinitionRequest]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> QuoteCancelCode, body |-> ZeroQuoteCancel]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> OrderMassActionRequestCode, body |-> ZeroOrderMassActionRequest]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> OrderMassStatusRequestCode, body |-> ZeroOrderMassStatusRequest]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> OrderStatusRequestCode, body |-> ZeroOrderStatusRequest]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> PartyDetailsListRequestCode, body |-> ZeroPartyDetailsListRequest]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> ExecutionAckCode, body |-> ZeroExecutionAck]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> RequestForQuoteCode, body |-> ZeroRequestForQuote]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> NewOrderCrossCode, body |-> ZeroNewOrderCross]],
      [ZeroClientSimpleOpenFrame EXCEPT !.clientPayload = [tag |-> SecurityDefinitionRequestCode, body |-> ZeroSecurityDefinitionRequest]] }

(***************************************************************************)
(* Client Packet                                                           *)
(***************************************************************************)

ClientPacket ==
    [ clientSimpleOpenFrame : SampleLists(OneClientSimpleOpenFrame) ]

EncodeClientPacket(message) ==
    EncodeClientSimpleOpenFrameList(message.clientSimpleOpenFrame)

DecodeClientPacket(bytes) ==
    LET clientSimpleOpenFrame == ReadClientSimpleOpenFrameAll(bytes) IN IF ~clientSimpleOpenFrame.ok THEN Fail ELSE
    Ok([ clientSimpleOpenFrame |-> clientSimpleOpenFrame.value ], clientSimpleOpenFrame.rest)

ZeroClientPacket ==
    [ clientSimpleOpenFrame |-> << >> ]

(* Client Packet at zero, then each field in turn at the values it is checked at *)
CheckedClientPacket ==
    { ZeroClientPacket }
        \cup { [ZeroClientPacket EXCEPT !.clientSimpleOpenFrame = one] : one \in SampleLists(OneClientSimpleOpenFrame) }

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

(* Every Credentials decodes back to what was encoded, and leaves nothing over *)
RoundTripCredentials ==
    \A message \in CheckedCredentials :
        LET read == DecodeCredentials(EncodeCredentials(message))
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

(* Every Credentials decodes back to what was encoded, and leaves nothing over *)
RoundTripCredentials2 ==
    \A message \in CheckedCredentials2 :
        LET read == DecodeCredentials2(EncodeCredentials2(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Establish decodes back to what was encoded, and leaves nothing over *)
RoundTripEstablish ==
    \A message \in CheckedEstablish :
        LET read == DecodeEstablish(EncodeEstablish(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sequence decodes back to what was encoded, and leaves nothing over *)
RoundTripSequence ==
    \A message \in CheckedSequence :
        LET read == DecodeSequence(EncodeSequence(message))
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

(* Every Retransmit Request decodes back to what was encoded, and leaves nothing over *)
RoundTripRetransmitRequest ==
    \A message \in CheckedRetransmitRequest :
        LET read == DecodeRetransmitRequest(EncodeRetransmitRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Single decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderSingle ==
    \A message \in CheckedNewOrderSingle :
        LET read == DecodeNewOrderSingle(EncodeNewOrderSingle(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Replace Request decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelReplaceRequest ==
    \A message \in CheckedOrderCancelReplaceRequest :
        LET read == DecodeOrderCancelReplaceRequest(EncodeOrderCancelReplaceRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Cancel Request decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderCancelRequest ==
    \A message \in CheckedOrderCancelRequest :
        LET read == DecodeOrderCancelRequest(EncodeOrderCancelRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Entries Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteEntriesGroup ==
    \A message \in CheckedQuoteEntriesGroup :
        LET read == DecodeQuoteEntriesGroup(EncodeQuoteEntriesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Entries Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteEntriesGroups ==
    \A message \in CheckedQuoteEntriesGroups :
        LET read == DecodeQuoteEntriesGroups(EncodeQuoteEntriesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Mass Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripMassQuote ==
    \A message \in CheckedMassQuote :
        LET read == DecodeMassQuote(EncodeMassQuote(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Party Details Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyDetailsGroup ==
    \A message \in CheckedPartyDetailsGroup :
        LET read == DecodePartyDetailsGroup(EncodePartyDetailsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Party Details Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyDetailsGroups ==
    \A message \in CheckedPartyDetailsGroups :
        LET read == DecodePartyDetailsGroups(EncodePartyDetailsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trd Reg Publications Group decodes back to what was encoded, and leaves nothing over *)
RoundTripTrdRegPublicationsGroup ==
    \A message \in CheckedTrdRegPublicationsGroup :
        LET read == DecodeTrdRegPublicationsGroup(EncodeTrdRegPublicationsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Trd Reg Publications Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripTrdRegPublicationsGroups ==
    \A message \in CheckedTrdRegPublicationsGroups :
        LET read == DecodeTrdRegPublicationsGroups(EncodeTrdRegPublicationsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Party Details Definition Request decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyDetailsDefinitionRequest ==
    \A message \in CheckedPartyDetailsDefinitionRequest :
        LET read == DecodePartyDetailsDefinitionRequest(EncodePartyDetailsDefinitionRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Entries Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelEntriesGroup ==
    \A message \in CheckedQuoteCancelEntriesGroup :
        LET read == DecodeQuoteCancelEntriesGroup(EncodeQuoteCancelEntriesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Entries Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelEntriesGroups ==
    \A message \in CheckedQuoteCancelEntriesGroups :
        LET read == DecodeQuoteCancelEntriesGroups(EncodeQuoteCancelEntriesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Sets Group decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelSetsGroup ==
    \A message \in CheckedQuoteCancelSetsGroup :
        LET read == DecodeQuoteCancelSetsGroup(EncodeQuoteCancelSetsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel Sets Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancelSetsGroups ==
    \A message \in CheckedQuoteCancelSetsGroups :
        LET read == DecodeQuoteCancelSetsGroups(EncodeQuoteCancelSetsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Quote Cancel decodes back to what was encoded, and leaves nothing over *)
RoundTripQuoteCancel ==
    \A message \in CheckedQuoteCancel :
        LET read == DecodeQuoteCancel(EncodeQuoteCancel(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Action Request decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassActionRequest ==
    \A message \in CheckedOrderMassActionRequest :
        LET read == DecodeOrderMassActionRequest(EncodeOrderMassActionRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Mass Status Request decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderMassStatusRequest ==
    \A message \in CheckedOrderMassStatusRequest :
        LET read == DecodeOrderMassStatusRequest(EncodeOrderMassStatusRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Order Status Request decodes back to what was encoded, and leaves nothing over *)
RoundTripOrderStatusRequest ==
    \A message \in CheckedOrderStatusRequest :
        LET read == DecodeOrderStatusRequest(EncodeOrderStatusRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Requesting Party Ids Group decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestingPartyIdsGroup ==
    \A message \in CheckedRequestingPartyIdsGroup :
        LET read == DecodeRequestingPartyIdsGroup(EncodeRequestingPartyIdsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Requesting Party Ids Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestingPartyIdsGroups ==
    \A message \in CheckedRequestingPartyIdsGroups :
        LET read == DecodeRequestingPartyIdsGroups(EncodeRequestingPartyIdsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Party Ids Group decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyIdsGroup ==
    \A message \in CheckedPartyIdsGroup :
        LET read == DecodePartyIdsGroup(EncodePartyIdsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Party Ids Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyIdsGroups ==
    \A message \in CheckedPartyIdsGroups :
        LET read == DecodePartyIdsGroups(EncodePartyIdsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Party Details List Request decodes back to what was encoded, and leaves nothing over *)
RoundTripPartyDetailsListRequest ==
    \A message \in CheckedPartyDetailsListRequest :
        LET read == DecodePartyDetailsListRequest(EncodePartyDetailsListRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Execution Ack decodes back to what was encoded, and leaves nothing over *)
RoundTripExecutionAck ==
    \A message \in CheckedExecutionAck :
        LET read == DecodeExecutionAck(EncodeExecutionAck(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Related Sym Group decodes back to what was encoded, and leaves nothing over *)
RoundTripRelatedSymGroup ==
    \A message \in CheckedRelatedSymGroup :
        LET read == DecodeRelatedSymGroup(EncodeRelatedSymGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Related Sym Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripRelatedSymGroups ==
    \A message \in CheckedRelatedSymGroups :
        LET read == DecodeRelatedSymGroups(EncodeRelatedSymGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request For Quote decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestForQuote ==
    \A message \in CheckedRequestForQuote :
        LET read == DecodeRequestForQuote(EncodeRequestForQuote(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sides Group decodes back to what was encoded, and leaves nothing over *)
RoundTripSidesGroup ==
    \A message \in CheckedSidesGroup :
        LET read == DecodeSidesGroup(EncodeSidesGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Sides Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripSidesGroups ==
    \A message \in CheckedSidesGroups :
        LET read == DecodeSidesGroups(EncodeSidesGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every New Order Cross decodes back to what was encoded, and leaves nothing over *)
RoundTripNewOrderCross ==
    \A message \in CheckedNewOrderCross :
        LET read == DecodeNewOrderCross(EncodeNewOrderCross(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Leg Option Delta decodes back to what was encoded, and leaves nothing over *)
RoundTripLegOptionDelta ==
    \A message \in CheckedLegOptionDelta :
        LET read == DecodeLegOptionDelta(EncodeLegOptionDelta(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Legs Group decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestLegsGroup ==
    \A message \in CheckedRequestLegsGroup :
        LET read == DecodeRequestLegsGroup(EncodeRequestLegsGroup(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Request Legs Groups decodes back to what was encoded, and leaves nothing over *)
RoundTripRequestLegsGroups ==
    \A message \in CheckedRequestLegsGroups :
        LET read == DecodeRequestLegsGroups(EncodeRequestLegsGroups(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Security Definition Request decodes back to what was encoded, and leaves nothing over *)
RoundTripSecurityDefinitionRequest ==
    \A message \in CheckedSecurityDefinitionRequest :
        LET read == DecodeSecurityDefinitionRequest(EncodeSecurityDefinitionRequest(message))
        IN  /\ read.ok
            /\ read.value = message
            /\ read.rest = << >>

(* Every Client Simple Open Frame decodes back to what was encoded, and leaves nothing over *)
RoundTripClientSimpleOpenFrame ==
    \A message \in CheckedClientSimpleOpenFrame :
        LET read == DecodeClientSimpleOpenFrame(EncodeClientSimpleOpenFrame(message))
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

(* A Client Payload is selected by the Template Id it is written under *)
SelectsClientPayload ==
    \A message \in CheckedClientPayload :
        LET read == DecodeClientPayload(message.tag, EncodeClientPayload(message))
        IN  read.ok /\ read.value.tag = message.tag

(* Message Length is written from the bytes it frames *)
FramesClientSimpleOpenFrame ==
    \A message \in CheckedClientSimpleOpenFrame :
        LET bytes == EncodeClientSimpleOpenFrame(message)
        IN  DecodeUIntLE(SubSeq(bytes, 1, 2)) = Len(bytes) - 0

-----------------------------------------------------------------------------
(* The state the session machine will run over. It stands still until there are *)
(* transitions to take. *)

VARIABLE parsed

Init == parsed = << >>
Next == UNCHANGED parsed
Spec == Init /\ [][Next]_parsed

=============================================================================
