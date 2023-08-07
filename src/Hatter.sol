// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import { console2 } from "forge-std/Test.sol"; // remove before deploy
import { HatterBase } from "./HatterBase.sol";

contract Hatter is HatterBase {
  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  constructor(uint256 facilitatorHat, address facilitator) HatterBase(facilitatorHat, facilitator) { }

  /*//////////////////////////////////////////////////////////////
                          PUBLIC FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function register(
    string calldata delegateName,
    string calldata ecosystemActorMessage,
    bytes calldata ecosystemActorSig,
    address delegationContract1,
    address delegationContractDelegate1,
    string calldata adRecognition1,
    bytes calldata adRecognitionSig1,
    address delegationContract2,
    address delegationContractDelegate2,
    string calldata adRecognition2,
    bytes calldata adRecognitionSig2
  ) external returns (uint256 delegateHatId) {
    // caller and both contract delegate addresses must all be unique
    if (
      msg.sender == delegationContractDelegate1 || msg.sender == delegationContractDelegate2
        || delegationContractDelegate1 == delegationContractDelegate2
    ) {
      revert InvalidDelegateAddresses();
    }

    // delegation contracts must be different
    if (delegationContract1 == delegationContract2) {
      revert InvalidDelegationContracts();
    }

    // caller must be the signer of the ecosystem actor message
    if (!_isValidSignature(ecosystemActorMessage, ecosystemActorSig, msg.sender)) {
      revert InvalidEcosystemActorSignature();
    }

    // delegation contract data must be valid
    _validateDelegationContractData(delegationContract1, delegationContractDelegate1, adRecognition1, adRecognitionSig1);

    _validateDelegationContractData(delegationContract2, delegationContractDelegate2, adRecognition2, adRecognitionSig2);

    // create and mint delegate hat to the caller
    delegateHatId = _createAndMintDelegateHat(delegateName, msg.sender);

    // emit Registered event
    emit Registered(
      msg.sender,
      delegateName,
      delegateHatId,
      ecosystemActorMessage,
      delegationContract1,
      delegationContractDelegate1,
      adRecognition1,
      delegationContract2,
      delegationContractDelegate2,
      adRecognition2
    );
  }
}
