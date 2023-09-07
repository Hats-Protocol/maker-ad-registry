# MakerDAO Aligned Delegate Registrar Hatter

Automated registration and verification of MakerDAO governance Aligned Delegates (ADs).

## Overview and Usage

This contract streamlines the Aligned Delegate registration process by automating verification of several of the requirements from [MIP 6.2.1](https://mips.makerdao.com/mips/details/MIP113#6-2-1):

1. That the registrant's AD Recognition Submission message is signed by the registrant's Ecosystem Actor address (this message is also know as the "Ecosystem Actor Message")

2. For each of the registrant's Delegation Contracts...

    i) That there is a valid signature of the AD Recognition Submission for that Delegation Contract

    ii) That the signer of 2i is the address controlling that Delegation Contract

    iii) That the registrant's Ecosystem Actor address is not equal to the signer from 2ii

Once an AD's registration is verified, this contract creates and mints a new [Hats Protocol hat](https://app.hatsprotocol.xyz/trees/5/66) representing the registrant's status as an Aligned Delegate.

An event is also emitted as a full record of the submission.

> [!IMPORTANT]
> This contract cannot verify the following information. It is the responsibility of the AD Facilitator to verify this information after submission, and revoke the AD's hat if any of the following are invalid:
>
> - The Ecosystem Actor Message content is valid (see [MIP 6.2.1.4](https://mips.makerdao.com/mips/details/MIP113#6-2-1-4))
> - The AD Recognition Submission messages for each of the registrant's Delegation Contracts are valid (see [MIP 6.2.1.2](https://mips.makerdao.com/mips/details/MIP113#6-2-1-2))

### How to register as an Aligned Delegate

Prospective Aligned Delegates should following the steps below to register:

#### Setup and Pre-requisites

These steps are the same as those registrants take today.

A. Deploy two Delegation Contracts, each controlled by separate "delegate" addresses ("Delegation Contract 1" and "Delegation Contract 2")
B. Draft a valid Ecosystem Actor Message
C. Sign the message from (B) with your Ecosystem Actor address, using an [EIP-191](https://eips.ethereum.org/EIPS/eip-191)-compatible signing method such as [Etherscan verified signatures](https://etherscan.io/verifiedSignatures) or [MyCrypto](https://app.mycrypto.com/sign-message)
D. Draft two valid AD Recognition Submission messages, one for each of the Delegation Contracts from (A)

#### Registration

E. Call the `register()` function — eg via Etherscan — on this contract with the following parameters:

- `delegateName`: Your Aligned Delegate name
- `ecosystemActorMessage`: The message from (B)
- `ecosystemActorSig`: The signature from (C)
- `delegationContract1`: The address of Delegation Contract 1, from (A)
- `delegationContractDelegate1`: The address of the delegate for Delegation Contract 1, from (A)
- `adRecognition1`: The AD Recognition Submission message for Delegation Contract 1, from (D)
- `adRecognitionSig1`: The signature of the AD Recognition Submission message for Delegation Contract 1, from (D)
- `delegationContract2`: The address of Delegation Contract 2, from (A)
- `delegationContractDelegate2`: The address of the delegate for Delegation Contract 2, from (A)
- `calldata` adRecognition2: The AD Recognition Submission message for Delegation Contract 2, from (D)
- `adRecognitionSig2`: The signature of the AD Recognition Submission message for Delegation Contract 2, from (D)

F. Once the transaction has been confirmed, post the transaction hash from (E) in the MakerDAO forum to notify the community — including the AD Facilitator — of your submission.

G. The AD Facilitator will verify the content of your submission messages. If it is invalid, they will revoke your AD hat and you will need to submit again.

## Development

This repo uses Foundry for development and testing. To get started:

1. Fork the project
2. Install [Foundry](https://book.getfoundry.sh/getting-started/installation)
3. To compile the contracts, run `forge build`
4. To test, run `forge test`
