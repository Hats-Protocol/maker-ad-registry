// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import { console2 } from "forge-std/Test.sol"; // remove before deploy
import { IHats } from "hats-protocol/Interfaces/IHats.sol";
import { SignatureCheckerLib } from "solady/utils/SignatureCheckerLib.sol";
import { ECDSA } from "solady/utils/ECDSA.sol";

interface DelegationContractLike {
  function delegate() external view returns (address);
}

contract HatterBase {
  /*//////////////////////////////////////////////////////////////
                            CUSTOM ERRORS
  //////////////////////////////////////////////////////////////*/

  error InvalidEcosystemActorSignature();
  error InvalidADRecognitionSignature();
  error InvalidDelegationContracts();
  error InvalidDelegateAddresses();
  error InvalidContractDelegate();

  /*//////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  event Registered(
    address delegate,
    string delegateName,
    uint256 delegateHatId,
    string ecosystemActorMessage,
    address delegationContract1,
    address delegationContractDelegate1,
    string adRecognition1,
    address delegationContract2,
    address delegationContractDelegate2,
    string adRecognition2
  );

  /*//////////////////////////////////////////////////////////////
                              CONSTANTS
  //////////////////////////////////////////////////////////////*/

  // Hats protocol contract address: v1.hatsprotocol.eth
  IHats public constant HATS = IHats(0x3bc1A0Ad72417f2d411118085256fC53CBdDd137);

  // AD Facilitator hat: the admin of the delegate hats this contract will create
  uint256 public immutable FACILITATOR_HAT;

  // Facilitator address
  address public immutable FACILITATOR;

  /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR
  //////////////////////////////////////////////////////////////*/

  constructor(uint256 facilitatorHat, address facilitator) {
    FACILITATOR_HAT = facilitatorHat;
    FACILITATOR = facilitator;
  }

  /*//////////////////////////////////////////////////////////////
                          INTERNAL FUNCTIONS
  //////////////////////////////////////////////////////////////*/

  function _isValidSignature(string calldata message, bytes calldata signature, address signer)
    internal
    view
    returns (bool)
  {
    // encode the message as bytes and convert it to an eth signed message hash
    bytes32 messageHash = ECDSA.toEthSignedMessageHash(abi.encodePacked(message));

    // check signature validity using recover for EOA and ERC1271 for contract
    return SignatureCheckerLib.isValidSignatureNowCalldata(signer, messageHash, signature);
  }

  function _validateDelegationContractData(
    address delegationContract,
    address delegationContractDelegate,
    string calldata adRecognition,
    bytes calldata adRecognitionSig
  ) internal view {
    // a. adRecognitionSig must be a valid signature of adRecognition by delegationContractDelegate
    if (!_isValidSignature(adRecognition, adRecognitionSig, delegationContractDelegate)) {
      revert InvalidADRecognitionSignature();
    }

    // b. delegationContractDelegate must be the delegate of delegationContract
    if (delegationContractDelegate != DelegationContractLike(delegationContract).delegate()) {
      revert InvalidContractDelegate();
    }
  }

  function _createAndMintDelegateHat(string calldata delegateName, address delegate)
    internal
    returns (uint256 delegateHatId)
  {
    {
      // create new delegate hat
      delegateHatId = HATS.createHat(
        FACILITATOR_HAT, // admin
        string.concat("Aligned Delegate: ", delegateName), // details
        1, // max supply
        FACILITATOR, // eligibility
        FACILITATOR, // toggle
        true, // mutable
        "" // image; will be inherited from parent hat if empty
      );
    }

    // mint delegate hat to delegate
    HATS.mintHat(delegateHatId, delegate);
  }
}
